import {
  OWebPatchOpcode,
  isPatchAttributeAllowed,
  isPatchPropertyAllowed,
} from "./oweb-protocol.mjs";

const ELEMENT_NODE = 1;
const TEXT_NODE = 3;
const VOID_TAGS = new Set([
  "AREA", "BASE", "BR", "COL", "EMBED", "HR", "IMG", "INPUT", "LINK",
  "META", "PARAM", "SOURCE", "TRACK", "WBR",
]);

export class OWebRuntimeError extends Error {
  constructor(code, message = code) {
    super(message);
    this.name = "OWebRuntimeError";
    this.code = code;
  }
}

function runtimeFail(code, message) {
  throw new OWebRuntimeError(code, message);
}

function childrenOf(node) {
  return node?.childNodes == null ? [] : Array.from(node.childNodes);
}

function visitRenderedTree(root, visitor) {
  for (const child of childrenOf(root)) {
    visitor(child);
    if (child?.content == null)
      visitRenderedTree(child, visitor);
  }
}

function attribute(node, name) {
  return typeof node?.getAttribute === "function" ? node.getAttribute(name) : null;
}

function parseDOMIdentifier(value, label) {
  if (typeof value !== "string" || !/^[1-9][0-9]*$/.test(value))
    return runtimeFail("invalid-dom-identifier", `${label} is not a canonical identifier`);
  const identifier = BigInt(value);
  if (identifier > (1n << 64n) - 1n)
    return runtimeFail("invalid-dom-identifier", `${label} exceeds uint64`);
  return identifier;
}

function key(identifier) {
  return identifier.toString();
}

function isReservedRuntimeAttribute(name) {
  return name.startsWith("data-oweb-");
}

function propertyValue(value) {
  if (typeof value !== "bigint")
    return value;
  const converted = Number(value);
  if (!Number.isSafeInteger(converted))
    return runtimeFail(
      "unsafe-property-integer",
      "OWeb refused to lose precision while assigning a DOM property",
    );
  return converted;
}

/**
 * Applies typed OWeb patches to one already-cloned component shadow tree.
 *
 * Lookups are map-based. No server value is ever interpolated into a selector.
 * A preflight pass validates the entire frame against a virtual structural
 * state before the first live DOM mutation, avoiding partial application of a
 * malformed frame.
 */
export class OWebPatchInterpreter {
  #root;
  #elements = new Map();
  #staticElementKeys = new Set();
  #templates = new Map();
  #nodes = new Map();
  #nodeIdentifiers = new WeakMap();
  #nodeParents = new Map();

  constructor(root) {
    if (root == null)
      throw new TypeError("OWebPatchInterpreter requires a shadow root");
    this.#root = root;
    this.#indexInitialTree();
    for (const template of this.#templates.values())
      this.#cloneRootForTemplate(template);
  }

  get elementCount() {
    return this.#elements.size;
  }

  get templateCount() {
    return this.#templates.size;
  }

  elementForIdentifier(identifier) {
    return this.#elements.get(key(identifier)) ?? null;
  }

  targetIdentifierFromPath(path) {
    for (const node of path) {
      if (node == null || node === this.#root)
        continue;
      const dynamic = this.#nodeIdentifiers.get(node);
      if (dynamic !== undefined)
        return dynamic;
      const encoded = attribute(node, "data-oweb-id");
      if (encoded !== null)
        return parseDOMIdentifier(encoded, "event target identifier");
    }
    return 0n;
  }

  apply(frame) {
    if (frame == null || !Array.isArray(frame.operations))
      throw new TypeError("OWebPatchInterpreter.apply requires a decoded patch frame");
    this.#preflight(frame.operations);
    this.#applyOperations(frame.operations);
  }

  #indexInitialTree() {
    visitRenderedTree(this.#root, (node) => {
      if (node?.nodeType !== ELEMENT_NODE)
        return;
      const elementID = attribute(node, "data-oweb-id");
      if (elementID !== null) {
        const identifier = parseDOMIdentifier(elementID, "element identifier");
        const identifierKey = key(identifier);
        if (this.#elements.has(identifierKey))
          runtimeFail("duplicate-element-identifier", "OWeb template repeats an element identifier");
        if (this.#templates.has(identifierKey))
          runtimeFail("duplicate-capability-identifier", "OWeb template repeats a capability identifier");
        this.#elements.set(identifierKey, node);
        this.#staticElementKeys.add(identifierKey);
      }

      const templateID = attribute(node, "data-oweb-template-id");
      if (templateID !== null) {
        if (node.content == null || typeof node.content.cloneNode !== "function")
          runtimeFail("invalid-template-node", "OWeb template capability is not a template element");
        const identifier = parseDOMIdentifier(templateID, "template identifier");
        const identifierKey = key(identifier);
        if (this.#templates.has(identifierKey) || this.#elements.has(identifierKey))
          runtimeFail("duplicate-template-identifier", "OWeb layout repeats a template identifier");
        this.#templates.set(identifierKey, node);
      }
    });
  }

  #preflight(operations) {
    const elements = new Set(this.#elements.keys());
    const elementNodes = new Map(this.#elements);
    const nodes = new Set(this.#nodes.keys());
    const parents = new Map(this.#nodeParents);

    const inspect = (list, depth) => {
      if (depth > 8)
        runtimeFail("batch-depth-limit", "OWeb patch batch nesting is too deep");
      for (const operation of list) {
        switch (operation.opcode) {
          case OWebPatchOpcode.SET_TEXT:
          case OWebPatchOpcode.SET_ATTRIBUTE:
          case OWebPatchOpcode.REMOVE_ATTRIBUTE:
          case OWebPatchOpcode.SET_PROPERTY:
          case OWebPatchOpcode.FOCUS:
            if (!elements.has(key(operation.elementId)))
              runtimeFail("unknown-element", "OWeb patch refers to an unknown element");
            if (operation.opcode === OWebPatchOpcode.SET_TEXT) {
              const targetKey = key(operation.elementId);
              if (this.#hasStaticCapabilityDescendant(targetKey))
                runtimeFail(
                  "text-replaces-capability",
                  "OWeb text patch cannot destroy a nested static capability",
                );
              for (const candidate of nodes) {
                for (let parent = parents.get(candidate); parent != null;
                     parent = parents.get(parent)) {
                  if (parent === targetKey)
                    runtimeFail(
                      "text-replaces-capability",
                      "OWeb text patch cannot destroy a nested dynamic capability",
                    );
                }
              }
            }
            if ((operation.opcode === OWebPatchOpcode.SET_ATTRIBUTE ||
                 operation.opcode === OWebPatchOpcode.REMOVE_ATTRIBUTE) &&
                (!isPatchAttributeAllowed(operation.name) ||
                 isReservedRuntimeAttribute(operation.name)))
              runtimeFail("disallowed-attribute", "OWeb patch attribute is not safe at runtime");
            if (operation.opcode === OWebPatchOpcode.SET_PROPERTY &&
                !isPatchPropertyAllowed(operation.name))
              runtimeFail("disallowed-property", "OWeb patch property is not safe at runtime");
            if (operation.opcode === OWebPatchOpcode.SET_PROPERTY)
              propertyValue(operation.value);
            break;
          case OWebPatchOpcode.BATCH:
            inspect(operation.operations, depth + 1);
            break;
          case OWebPatchOpcode.CLONE_TEMPLATE: {
            const templateKey = key(operation.templateId);
            const parentKey = key(operation.parentId);
            const nodeKey = key(operation.nodeId);
            if (!this.#templates.has(templateKey))
              runtimeFail("unknown-template", "OWeb patch refers to an unknown declared template");
            if (!elements.has(parentKey))
              runtimeFail("unknown-parent", "OWeb patch refers to an unknown parent element");
            if (elements.has(nodeKey) || nodes.has(nodeKey) ||
                this.#templates.has(nodeKey))
              runtimeFail("duplicate-node-identifier", "OWeb dynamic node identifier is already in use");
            if (!this.#canContainChildren(elementNodes.get(parentKey)))
              runtimeFail("invalid-parent", "OWeb structural parent cannot contain child nodes");
            const cloneRoot = this.#cloneRootForTemplate(this.#templates.get(templateKey));
            elements.add(nodeKey);
            elementNodes.set(nodeKey, cloneRoot);
            nodes.add(nodeKey);
            parents.set(nodeKey, parentKey);
            break;
          }
          case OWebPatchOpcode.REMOVE_NODE: {
            const nodeKey = key(operation.nodeId);
            if (!nodes.has(nodeKey))
              runtimeFail("unknown-node", "OWeb patch cannot remove an unknown dynamic node");
            const removed = [nodeKey];
            for (let index = 0; index < removed.length; index++) {
              const current = removed[index];
              for (const [candidate, parent] of parents) {
                if (parent === current && !removed.includes(candidate))
                  removed.push(candidate);
              }
            }
            for (const removedKey of removed) {
              nodes.delete(removedKey);
              elements.delete(removedKey);
              elementNodes.delete(removedKey);
              parents.delete(removedKey);
            }
            break;
          }
          case OWebPatchOpcode.MOVE_NODE: {
            const nodeKey = key(operation.nodeId);
            const parentKey = key(operation.parentId);
            const beforeKey = key(operation.beforeId);
            if (!nodes.has(nodeKey))
              runtimeFail("unknown-node", "OWeb patch cannot move an unknown dynamic node");
            if (!elements.has(parentKey))
              runtimeFail("unknown-parent", "OWeb patch refers to an unknown parent element");
            if (!this.#canContainChildren(elementNodes.get(parentKey)))
              runtimeFail("invalid-parent", "OWeb structural parent cannot contain child nodes");
            for (let ancestor = parentKey; parents.has(ancestor); ancestor = parents.get(ancestor)) {
              if (ancestor === nodeKey)
                runtimeFail("structural-cycle", "OWeb node cannot move inside its own subtree");
            }
            if (parentKey === nodeKey)
              runtimeFail("structural-cycle", "OWeb node cannot become its own parent");
            if (operation.beforeId !== 0n) {
              if (!nodes.has(beforeKey))
                runtimeFail("unknown-before-node", "OWeb patch refers to an unknown sibling node");
              if (parents.get(beforeKey) !== parentKey)
                runtimeFail("invalid-before-node", "OWeb sibling does not belong to the requested parent");
              if (beforeKey === nodeKey)
                runtimeFail("invalid-before-node", "OWeb node cannot move before itself");
            }
            parents.set(nodeKey, parentKey);
            break;
          }
          default:
            runtimeFail("unknown-opcode", "OWeb interpreter received an unknown opcode");
        }
      }
    };

    inspect(operations, 0);
  }

  #applyOperations(operations) {
    for (const operation of operations) {
      switch (operation.opcode) {
        case OWebPatchOpcode.SET_TEXT:
          this.#requireElement(operation.elementId).textContent = operation.text;
          break;
        case OWebPatchOpcode.SET_ATTRIBUTE:
          this.#requireElement(operation.elementId).setAttribute(operation.name, operation.value);
          break;
        case OWebPatchOpcode.REMOVE_ATTRIBUTE:
          this.#requireElement(operation.elementId).removeAttribute(operation.name);
          break;
        case OWebPatchOpcode.SET_PROPERTY:
          this.#requireElement(operation.elementId)[operation.name] = propertyValue(operation.value);
          break;
        case OWebPatchOpcode.FOCUS: {
          const element = this.#requireElement(operation.elementId);
          if (typeof element.focus !== "function")
            runtimeFail("element-not-focusable", "OWeb patch target has no focus operation");
          element.focus({ preventScroll: true });
          break;
        }
        case OWebPatchOpcode.BATCH:
          this.#applyOperations(operation.operations);
          break;
        case OWebPatchOpcode.CLONE_TEMPLATE:
          this.#clone(operation);
          break;
        case OWebPatchOpcode.REMOVE_NODE:
          this.#remove(operation.nodeId);
          break;
        case OWebPatchOpcode.MOVE_NODE:
          this.#move(operation);
          break;
        default:
          runtimeFail("unknown-opcode", "OWeb interpreter received an unknown opcode");
      }
    }
  }

  #requireElement(identifier) {
    const element = this.#elements.get(key(identifier));
    if (element == null)
      return runtimeFail("unknown-element", "OWeb patch refers to an unknown element");
    return element;
  }

  #canContainChildren(node) {
    return node != null && !VOID_TAGS.has(String(node.tagName ?? "").toUpperCase());
  }

  #isDescendant(node, possibleAncestor) {
    for (let parent = node?.parentNode; parent != null; parent = parent.parentNode) {
      if (parent === possibleAncestor)
        return true;
    }
    return false;
  }

  #hasStaticCapabilityDescendant(targetKey) {
    const target = this.#elements.get(targetKey);
    if (target == null)
      return false;
    for (const elementKey of this.#staticElementKeys) {
      if (elementKey !== targetKey &&
          this.#isDescendant(this.#elements.get(elementKey), target))
        return true;
    }
    for (const template of this.#templates.values()) {
      if (this.#isDescendant(template, target))
        return true;
    }
    return false;
  }

  #cloneRootForTemplate(template) {
    const fragment = template.content.cloneNode(true);
    const elements = [];
    for (const child of childrenOf(fragment)) {
      if (child?.nodeType === ELEMENT_NODE) {
        elements.push(child);
      } else if (child?.nodeType === TEXT_NODE && String(child.textContent ?? "").trim() === "") {
        continue;
      } else {
        runtimeFail(
          "invalid-clone-template",
          "OWeb clone templates must contain exactly one element root",
        );
      }
    }
    if (elements.length !== 1)
      runtimeFail("invalid-clone-template", "OWeb clone template needs one element root");
    const root = elements[0];
    const inspect = (node) => {
      if (typeof node?.getAttributeNames === "function") {
        for (const name of node.getAttributeNames()) {
          if (name.startsWith("data-oweb-"))
            runtimeFail(
              "nested-clone-capability",
              "OWeb v1 clone templates cannot declare nested capabilities",
            );
        }
      }
    };
    inspect(root);
    visitRenderedTree(root, inspect);
    return root;
  }

  #clone(operation) {
    const template = this.#templates.get(key(operation.templateId));
    const parent = this.#requireElement(operation.parentId);
    const root = this.#cloneRootForTemplate(template);
    const nodeKey = key(operation.nodeId);
    parent.appendChild(root);
    this.#nodes.set(nodeKey, root);
    this.#elements.set(nodeKey, root);
    this.#nodeIdentifiers.set(root, operation.nodeId);
    this.#nodeParents.set(nodeKey, key(operation.parentId));
  }

  #remove(identifier) {
    const nodeKey = key(identifier);
    const node = this.#nodes.get(nodeKey);
    if (node == null)
      runtimeFail("unknown-node", "OWeb patch cannot remove an unknown dynamic node");
    const removed = [nodeKey];
    for (let index = 0; index < removed.length; index++) {
      const current = removed[index];
      for (const [candidate, parent] of this.#nodeParents) {
        if (parent === current && !removed.includes(candidate))
          removed.push(candidate);
      }
    }
    if (typeof node.remove === "function")
      node.remove();
    else if (node.parentNode != null)
      node.parentNode.removeChild(node);
    for (const removedKey of removed) {
      const removedNode = this.#nodes.get(removedKey);
      this.#nodes.delete(removedKey);
      this.#elements.delete(removedKey);
      this.#nodeParents.delete(removedKey);
      if (removedNode != null)
        this.#nodeIdentifiers.delete(removedNode);
    }
  }

  #move(operation) {
    const node = this.#nodes.get(key(operation.nodeId));
    const parent = this.#requireElement(operation.parentId);
    const before = operation.beforeId === 0n ? null : this.#nodes.get(key(operation.beforeId));
    if (before == null)
      parent.appendChild(node);
    else
      parent.insertBefore(node, before);
    this.#nodeParents.set(key(operation.nodeId), key(operation.parentId));
  }
}
