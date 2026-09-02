import assert from "node:assert/strict";
import test from "node:test";

import { OWebPatchOpcode } from "../../../../AsyncRT/Web/src/oweb-protocol.mjs";
import {
  OWebPatchInterpreter,
  OWebRuntimeError,
} from "../../../../AsyncRT/Web/src/oweb-interpreter.mjs";

class FakeNode {
  constructor(nodeType) {
    this.nodeType = nodeType;
    this.childNodes = [];
    this.parentNode = null;
    this._text = "";
  }

  appendChild(node) {
    if (node.nodeType === 11) {
      for (const child of [...node.childNodes])
        this.appendChild(child);
      return node;
    }
    node.remove();
    this.childNodes.push(node);
    node.parentNode = this;
    return node;
  }

  insertBefore(node, before) {
    if (before == null)
      return this.appendChild(node);
    const index = this.childNodes.indexOf(before);
    if (index < 0)
      throw new Error("reference node is not a child");
    node.remove();
    this.childNodes.splice(index, 0, node);
    node.parentNode = this;
    return node;
  }

  removeChild(node) {
    const index = this.childNodes.indexOf(node);
    if (index < 0)
      throw new Error("node is not a child");
    this.childNodes.splice(index, 1);
    node.parentNode = null;
    return node;
  }

  remove() {
    if (this.parentNode != null)
      this.parentNode.removeChild(this);
  }

  get textContent() {
    if (this.childNodes.length === 0)
      return this._text;
    return this.childNodes.map((child) => child.textContent).join("");
  }

  set textContent(value) {
    for (const child of this.childNodes)
      child.parentNode = null;
    this.childNodes = [];
    this._text = String(value);
  }
}

class FakeFragment extends FakeNode {
  constructor() {
    super(11);
  }

  cloneNode(deep) {
    const clone = new FakeFragment();
    if (deep) {
      for (const child of this.childNodes)
        clone.appendChild(child.cloneNode(true));
    }
    return clone;
  }
}

class FakeText extends FakeNode {
  constructor(value) {
    super(3);
    this._text = value;
  }

  cloneNode() {
    return new FakeText(this._text);
  }
}

class FakeElement extends FakeNode {
  constructor(tagName, attributes = {}) {
    super(1);
    this.tagName = tagName.toUpperCase();
    this.attributes = new Map(Object.entries(attributes));
    this.focused = false;
  }

  getAttribute(name) {
    return this.attributes.has(name) ? this.attributes.get(name) : null;
  }

  getAttributeNames() {
    return [...this.attributes.keys()];
  }

  setAttribute(name, value) {
    this.attributes.set(name, String(value));
  }

  removeAttribute(name) {
    this.attributes.delete(name);
  }

  focus(options) {
    this.focused = true;
    this.focusOptions = options;
  }

  cloneNode(deep) {
    const clone = new FakeElement(this.tagName, Object.fromEntries(this.attributes));
    clone._text = this._text;
    if (deep) {
      for (const child of this.childNodes)
        clone.appendChild(child.cloneNode(true));
    }
    return clone;
  }
}

class FakeTemplate extends FakeElement {
  constructor(identifier) {
    super("template", { "data-oweb-template-id": String(identifier) });
    this.content = new FakeFragment();
  }

  cloneNode(deep) {
    const clone = new FakeTemplate(this.getAttribute("data-oweb-template-id"));
    if (deep)
      clone.content = this.content.cloneNode(true);
    return clone;
  }
}

function fixture() {
  const root = new FakeFragment();
  const list = new FakeElement("ul", { "data-oweb-id": "1" });
  const label = new FakeElement("span", { "data-oweb-id": "2" });
  const input = new FakeElement("input", { "data-oweb-id": "3", title: "old" });
  const template = new FakeTemplate(4);
  template.content.appendChild(new FakeText("\n  "));
  const item = new FakeElement("li");
  item.appendChild(new FakeElement("button", { title: "item" }));
  template.content.appendChild(item);
  template.content.appendChild(new FakeText("\n"));
  list.appendChild(label);
  list.appendChild(input);
  list.appendChild(template);
  root.appendChild(list);
  return { root, list, label, input, template };
}

function patch(...operations) {
  return { instanceId: 99n, operations };
}

function runtimeCode(code) {
  return (error) => error instanceof OWebRuntimeError && error.code === code;
}

test("interpreter applies every typed mutation and structural opcode", () => {
  const { root, list, label, input } = fixture();
  const interpreter = new OWebPatchInterpreter(root);
  assert.equal(interpreter.elementCount, 3);
  assert.equal(interpreter.templateCount, 1);

  interpreter.apply(patch({
    opcode: OWebPatchOpcode.BATCH,
    operations: [
      { opcode: OWebPatchOpcode.SET_TEXT, elementId: 2n, text: "Rei" },
      {
        opcode: OWebPatchOpcode.SET_ATTRIBUTE,
        elementId: 2n,
        name: "class",
        value: "awake",
      },
      { opcode: OWebPatchOpcode.REMOVE_ATTRIBUTE, elementId: 3n, name: "title" },
      {
        opcode: OWebPatchOpcode.SET_PROPERTY,
        elementId: 3n,
        name: "checked",
        value: true,
      },
      { opcode: OWebPatchOpcode.FOCUS, elementId: 3n },
      {
        opcode: OWebPatchOpcode.CLONE_TEMPLATE,
        templateId: 4n,
        parentId: 1n,
        nodeId: 10n,
      },
      {
        opcode: OWebPatchOpcode.CLONE_TEMPLATE,
        templateId: 4n,
        parentId: 1n,
        nodeId: 11n,
      },
      {
        opcode: OWebPatchOpcode.MOVE_NODE,
        nodeId: 11n,
        parentId: 1n,
        beforeId: 10n,
      },
      { opcode: OWebPatchOpcode.REMOVE_NODE, nodeId: 10n },
    ],
  }));

  assert.equal(label.textContent, "Rei");
  assert.equal(label.getAttribute("class"), "awake");
  assert.equal(input.getAttribute("title"), null);
  assert.equal(input.checked, true);
  assert.equal(input.focused, true);
  assert.deepEqual(input.focusOptions, { preventScroll: true });
  assert.equal(interpreter.elementForIdentifier(10n), null);
  const surviving = interpreter.elementForIdentifier(11n);
  assert.equal(surviving.tagName, "LI");
  assert.equal(list.childNodes.at(-1), surviving);
  assert.equal(interpreter.targetIdentifierFromPath([
    surviving.childNodes[0],
    surviving,
    list,
  ]), 11n);
});

test("preflight prevents a later invalid operation from partially mutating DOM", () => {
  const { root, label } = fixture();
  const interpreter = new OWebPatchInterpreter(root);
  label.textContent = "before";
  assert.throws(() => interpreter.apply(patch(
    { opcode: OWebPatchOpcode.SET_TEXT, elementId: 2n, text: "after" },
    {
      opcode: OWebPatchOpcode.SET_ATTRIBUTE,
      elementId: 2n,
      name: "data-oweb-on-click",
      value: "999",
    },
  )), runtimeCode("disallowed-attribute"));
  assert.equal(label.textContent, "before");
});

test("preflight rejects missing IDs, duplicate dynamic IDs, and lossy properties", () => {
  const { root } = fixture();
  const interpreter = new OWebPatchInterpreter(root);
  assert.throws(() => interpreter.apply(patch({
    opcode: OWebPatchOpcode.SET_TEXT,
    elementId: 404n,
    text: "no",
  })), runtimeCode("unknown-element"));

  assert.throws(() => interpreter.apply(patch({
    opcode: OWebPatchOpcode.CLONE_TEMPLATE,
    templateId: 4n,
    parentId: 1n,
    nodeId: 2n,
  })), runtimeCode("duplicate-node-identifier"));

  assert.throws(() => interpreter.apply(patch({
    opcode: OWebPatchOpcode.CLONE_TEMPLATE,
    templateId: 4n,
    parentId: 1n,
    nodeId: 4n,
  })), runtimeCode("duplicate-node-identifier"));

  assert.throws(() => interpreter.apply(patch({
    opcode: OWebPatchOpcode.SET_PROPERTY,
    elementId: 3n,
    name: "scrollTop",
    value: 1n << 62n,
  })), runtimeCode("unsafe-property-integer"));
});

test("text and structure operations cannot invalidate nested capabilities", () => {
  const { root, list } = fixture();
  const interpreter = new OWebPatchInterpreter(root);
  assert.throws(() => interpreter.apply(patch({
    opcode: OWebPatchOpcode.SET_TEXT,
    elementId: 1n,
    text: "would destroy IDs",
  })), runtimeCode("text-replaces-capability"));
  assert.notEqual(list.childNodes.length, 0);

  assert.throws(() => interpreter.apply(patch({
    opcode: OWebPatchOpcode.CLONE_TEMPLATE,
    templateId: 4n,
    parentId: 3n,
    nodeId: 10n,
  })), runtimeCode("invalid-parent"));
});

test("clone is restricted to a declared single-root template", () => {
  const { root, template } = fixture();
  template.content.appendChild(new FakeElement("li"));
  assert.throws(
    () => new OWebPatchInterpreter(root),
    runtimeCode("invalid-clone-template"),
  );

  const nested = fixture();
  nested.template.content.childNodes[1].setAttribute("data-oweb-id", "99");
  assert.throws(
    () => new OWebPatchInterpreter(nested.root),
    runtimeCode("nested-clone-capability"),
  );
});

test("initial indexing rejects duplicate static and template capabilities", () => {
  const { root, list } = fixture();
  list.appendChild(new FakeElement("b", { "data-oweb-id": "2" }));
  assert.throws(
    () => new OWebPatchInterpreter(root),
    runtimeCode("duplicate-element-identifier"),
  );

  const second = fixture();
  second.list.appendChild(new FakeTemplate(4));
  assert.throws(
    () => new OWebPatchInterpreter(second.root),
    runtimeCode("duplicate-template-identifier"),
  );
});

test("move validates sibling ownership before touching the live tree", () => {
  const { root, list } = fixture();
  const other = new FakeElement("ol", { "data-oweb-id": "5" });
  root.appendChild(other);
  const interpreter = new OWebPatchInterpreter(root);
  interpreter.apply(patch(
    {
      opcode: OWebPatchOpcode.CLONE_TEMPLATE,
      templateId: 4n,
      parentId: 1n,
      nodeId: 10n,
    },
    {
      opcode: OWebPatchOpcode.CLONE_TEMPLATE,
      templateId: 4n,
      parentId: 1n,
      nodeId: 11n,
    },
  ));
  assert.throws(() => interpreter.apply(patch({
    opcode: OWebPatchOpcode.MOVE_NODE,
    nodeId: 10n,
    parentId: 5n,
    beforeId: 11n,
  })), runtimeCode("invalid-before-node"));
  assert.equal(interpreter.elementForIdentifier(10n).parentNode, list);
});

test("structural preflight rejects cycles and removal retires nested capabilities", () => {
  const { root } = fixture();
  const interpreter = new OWebPatchInterpreter(root);
  interpreter.apply(patch(
    {
      opcode: OWebPatchOpcode.CLONE_TEMPLATE,
      templateId: 4n,
      parentId: 1n,
      nodeId: 10n,
    },
    {
      opcode: OWebPatchOpcode.CLONE_TEMPLATE,
      templateId: 4n,
      parentId: 10n,
      nodeId: 11n,
    },
  ));

  assert.throws(() => interpreter.apply(patch({
    opcode: OWebPatchOpcode.MOVE_NODE,
    nodeId: 10n,
    parentId: 11n,
    beforeId: 0n,
  })), runtimeCode("structural-cycle"));
  assert.notEqual(interpreter.elementForIdentifier(10n), null);
  assert.notEqual(interpreter.elementForIdentifier(11n), null);

  interpreter.apply(patch({
    opcode: OWebPatchOpcode.REMOVE_NODE,
    nodeId: 10n,
  }));
  assert.equal(interpreter.elementForIdentifier(10n), null);
  assert.equal(interpreter.elementForIdentifier(11n), null);
});
