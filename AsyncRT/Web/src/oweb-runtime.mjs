import {
  OWEB_MIME_TYPE,
  OWebLimits,
  encodeDetachFrame,
  encodeEventFrame,
  encodeMountFrame,
  decodePatchFrame,
  isComponentTagValid,
  isMountAttributeNameValid,
} from "./oweb-protocol.mjs";
import { OWebPatchInterpreter, OWebRuntimeError } from "./oweb-interpreter.mjs";

const CONNECTION_ATTRIBUTE = "data-oweb-connection";
const COMPONENT_ATTRIBUTE = "data-oweb-component";
const OBSERVED_ATTRIBUTE = "data-oweb-observed-attributes";
const ENDPOINT_META_NAME = "oweb-endpoint";
const SEQUENCE_HEADER = "X-OWeb-Sequence";
const DEFAULT_REQUEST_TIMEOUT_MILLISECONDS = 15_000;
const MAXIMUM_REQUEST_TIMEOUT_MILLISECONDS = 120_000;

const EVENT_TYPES = new Set([
  "click", "dblclick", "input", "change", "submit", "keydown", "keyup",
  "keypress", "focus", "blur", "pointerdown", "pointerup", "pointermove",
  "pointercancel", "mousedown", "mouseup", "mousemove", "mouseenter",
  "mouseleave", "touchstart", "touchend", "touchmove", "dragstart",
  "dragend", "drop",
]);

const BOOLEAN_EVENT_FIELDS = new Set([
  "altKey", "ctrlKey", "metaKey", "repeat", "shiftKey",
]);
const NUMBER_EVENT_FIELDS = new Set([
  "button", "buttons", "clientX", "clientY", "deltaX", "deltaY", "detail",
  "offsetX", "offsetY", "pointerId",
]);
const STRING_EVENT_FIELDS = new Set(["code", "inputType", "key"]);

function runtimeFail(code, message) {
  throw new OWebRuntimeError(code, message);
}

function canonicalSequence(value) {
  if (typeof value !== "bigint" || value <= 0n)
    throw new TypeError("OWeb HTTP sequence must be a positive bigint");
  return value.toString();
}

async function boundedResponseBytes(response) {
  const lengthValue = response.headers.get("content-length");
  if (lengthValue !== null) {
    if (!/^(0|[1-9][0-9]*)$/.test(lengthValue))
      runtimeFail("invalid-content-length", "OWeb response has an invalid Content-Length");
    if (BigInt(lengthValue) > BigInt(OWebLimits.FRAME_BYTES))
      runtimeFail("response-too-large", "OWeb response exceeds the frame limit");
  }

  if (response.body != null && typeof response.body.getReader === "function") {
    const reader = response.body.getReader();
    const chunks = [];
    let length = 0;
    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done)
          break;
        const chunk = value instanceof Uint8Array ? value : new Uint8Array(value);
        length += chunk.length;
        if (length > OWebLimits.FRAME_BYTES) {
          await reader.cancel("OWeb response exceeded its bounded frame size");
          runtimeFail("response-too-large", "OWeb response exceeds the frame limit");
        }
        chunks.push(chunk);
      }
    } finally {
      reader.releaseLock();
    }
    const result = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) {
      result.set(chunk, offset);
      offset += chunk.length;
    }
    return result;
  }

  const result = new Uint8Array(await response.arrayBuffer());
  if (result.length > OWebLimits.FRAME_BYTES)
    runtimeFail("response-too-large", "OWeb response exceeds the frame limit");
  return result;
}

/** Binary same-origin request/response transport for the OWeb frame codec. */
export class OWebHTTPTransport {
  #endpoint;
  #fetch;
  #requestTimeoutMilliseconds;
  #scheduleTimeout;
  #cancelTimeout;

  constructor(endpoint, {
    fetch = globalThis.fetch,
    baseURL = globalThis.location?.href,
    requestTimeoutMilliseconds = DEFAULT_REQUEST_TIMEOUT_MILLISECONDS,
    setTimeout: scheduleTimeout = globalThis.setTimeout,
    clearTimeout: cancelTimeout = globalThis.clearTimeout,
  } = {}) {
    if (typeof fetch !== "function")
      throw new TypeError("OWebHTTPTransport requires fetch");
    if (baseURL == null)
      throw new TypeError("OWebHTTPTransport requires a browser base URL");
    if (!Number.isSafeInteger(requestTimeoutMilliseconds) ||
        requestTimeoutMilliseconds < 1 ||
        requestTimeoutMilliseconds > MAXIMUM_REQUEST_TIMEOUT_MILLISECONDS)
      throw new RangeError("OWeb request timeout must be between 1 and 120000 ms");
    if (typeof scheduleTimeout !== "function" || typeof cancelTimeout !== "function")
      throw new TypeError("OWebHTTPTransport requires timer functions");
    const base = new URL(baseURL);
    const resolved = new URL(endpoint, base);
    if (resolved.origin !== base.origin)
      runtimeFail("cross-origin-endpoint", "OWeb transport endpoint must be same-origin");
    if (resolved.protocol !== "http:" && resolved.protocol !== "https:")
      runtimeFail("invalid-endpoint-scheme", "OWeb transport requires HTTP or HTTPS");
    if (resolved.username !== "" || resolved.password !== "" || resolved.hash !== "")
      runtimeFail("invalid-endpoint", "OWeb endpoint cannot contain credentials or a fragment");
    this.#endpoint = resolved.href;
    this.#fetch = fetch;
    this.#requestTimeoutMilliseconds = requestTimeoutMilliseconds;
    this.#scheduleTimeout = scheduleTimeout;
    this.#cancelTimeout = cancelTimeout;
  }

  async exchange(frame, {
    sequence,
    signal,
    keepalive = false,
  } = {}) {
    let requestBody;
    if (frame instanceof ArrayBuffer) {
      requestBody = new Uint8Array(frame);
    } else if (ArrayBuffer.isView(frame)) {
      requestBody = new Uint8Array(frame.buffer, frame.byteOffset, frame.byteLength);
    } else {
      throw new TypeError("OWeb HTTP exchange requires a binary frame");
    }
    if (requestBody.length === 0 || requestBody.length > OWebLimits.FRAME_BYTES)
      runtimeFail("invalid-request-size", "OWeb request is empty or exceeds the frame limit");
    const encodedSequence = canonicalSequence(sequence);
    const timeoutController = new AbortController();
    const propagateAbort = () => timeoutController.abort(signal?.reason);
    if (signal?.aborted)
      propagateAbort();
    else
      signal?.addEventListener("abort", propagateAbort, { once: true });

    const operation = (async () => {
      const response = await this.#fetch(this.#endpoint, {
        method: "POST",
        body: requestBody,
        credentials: "same-origin",
        mode: "same-origin",
        cache: "no-store",
        redirect: "error",
        referrerPolicy: "same-origin",
        keepalive,
        signal: timeoutController.signal,
        headers: {
          "Accept": OWEB_MIME_TYPE,
          "Content-Type": OWEB_MIME_TYPE,
          [SEQUENCE_HEADER]: encodedSequence,
        },
      });

      if (!response.ok)
        runtimeFail("http-error", `OWeb endpoint returned HTTP ${response.status}`);
      if (response.headers.get(SEQUENCE_HEADER) !== encodedSequence)
        runtimeFail("sequence-mismatch", "OWeb response sequence does not match its request");
      if (response.status === 204)
        return null;

      const contentType = response.headers.get("content-type");
      const essence = contentType?.split(";", 1)[0].trim().toLowerCase();
      if (essence !== OWEB_MIME_TYPE)
        runtimeFail("invalid-content-type", "OWeb response has the wrong media type");
      const bytes = await boundedResponseBytes(response);
      if (bytes.length === 0)
        runtimeFail("empty-response", "OWeb response did not contain a patch frame");
      return bytes;
    })();
    let timeoutHandle;
    const timeout = new Promise((_resolve, reject) => {
      timeoutHandle = this.#scheduleTimeout(() => {
        const error = new OWebRuntimeError(
          "request-timeout",
          "OWeb request exceeded its bounded response deadline",
        );
        timeoutController.abort(error);
        reject(error);
      }, this.#requestTimeoutMilliseconds);
    });

    try {
      return await Promise.race([operation, timeout]);
    } finally {
      this.#cancelTimeout(timeoutHandle);
      signal?.removeEventListener("abort", propagateAbort);
    }
  }
}

function childNodes(node) {
  return node?.childNodes == null ? [] : Array.from(node.childNodes);
}

function walkIncludingTemplates(root, visitor) {
  for (const child of childNodes(root)) {
    visitor(child);
    if (child?.content != null)
      walkIncludingTemplates(child.content, visitor);
    else
      walkIncludingTemplates(child, visitor);
  }
}

function componentDefinition(template, ownerDocument) {
  if (template?.ownerDocument !== ownerDocument || template.content == null ||
      typeof template.content.cloneNode !== "function")
    runtimeFail("invalid-component-template", "OWeb definition must be a server-document template");
  const tag = template.getAttribute(COMPONENT_ATTRIBUTE);
  if (!isComponentTagValid(tag))
    runtimeFail("invalid-component-tag", "OWeb component definition has an invalid tag");

  const observed = (template.getAttribute(OBSERVED_ATTRIBUTE) ?? "")
    .split(/[\s,]+/u)
    .filter((name) => name.length > 0);
  if (new Set(observed).size !== observed.length)
    runtimeFail("duplicate-observed-attribute", "OWeb observed attribute list contains a duplicate");
  if (observed.length > OWebLimits.MOUNT_ATTRIBUTES)
    runtimeFail("observed-attribute-limit", "OWeb component observes too many attributes");
  for (const name of observed) {
    if (!isMountAttributeNameValid(name) || name.startsWith("data-oweb-") ||
        name.startsWith("on") || name === "style")
      runtimeFail("invalid-observed-attribute", "OWeb observed attribute is unsafe");
  }

  const eventTypes = new Set();
  const actionIdentifiers = new Set();
  let nodeCount = 0;
  walkIncludingTemplates(template.content, (node) => {
    nodeCount++;
    if (nodeCount > 4096)
      runtimeFail("template-node-limit", "OWeb component template contains too many nodes");
    if (typeof node?.getAttributeNames !== "function")
      return;
    const names = node.getAttributeNames();
    if (names.length > 64)
      runtimeFail("template-attribute-limit", "OWeb template node has too many attributes");
    for (const name of names) {
      if (!name.startsWith("data-oweb-on-"))
        continue;
      const eventType = name.slice("data-oweb-on-".length);
      if (!EVENT_TYPES.has(eventType))
        runtimeFail("invalid-event-type", "OWeb template declares an unsupported event type");
      const action = node.getAttribute(name);
      if (!/^[1-9][0-9]*$/.test(action ?? ""))
        runtimeFail("invalid-action-identifier", "OWeb template has a malformed action identifier");
      const numericAction = BigInt(action);
      if (numericAction > (1n << 64n) - 1n)
        runtimeFail("invalid-action-identifier", "OWeb action identifier exceeds uint64");
      if (actionIdentifiers.has(action))
        runtimeFail("duplicate-action-identifier", "OWeb template repeats an action identifier");
      actionIdentifiers.add(action);
      eventTypes.add(eventType);
    }
  });

  return Object.freeze({
    tag,
    template,
    observedAttributes: Object.freeze([...observed]),
    eventTypes: Object.freeze([...eventTypes]),
  });
}

function eventPath(event, root) {
  if (typeof event.composedPath === "function")
    return event.composedPath();
  const path = [];
  for (let node = event.target; node != null; node = node.parentNode) {
    path.push(node);
    if (node === root)
      break;
  }
  return path;
}

/** Creates the protocol's small, value-only event projection. */
export function collectEventFields(event) {
  const fields = {};
  for (const name of BOOLEAN_EVENT_FIELDS) {
    if (typeof event[name] === "boolean")
      fields[name] = event[name];
  }
  for (const name of NUMBER_EVENT_FIELDS) {
    if (typeof event[name] === "number" && Number.isFinite(event[name]))
      fields[name] = event[name];
  }
  for (const name of STRING_EVENT_FIELDS) {
    if (typeof event[name] === "string")
      fields[name] = event[name];
  }
  if (typeof event.data === "string" || event.data === null)
    fields.data = event.data;
  const targetValue = event.target?.value;
  if (typeof targetValue === "string")
    fields.value = targetValue;
  return fields;
}

function randomInstanceIdentifier(crypto) {
  if (crypto == null || typeof crypto.getRandomValues !== "function")
    runtimeFail("missing-crypto", "OWeb requires cryptographic browser randomness");
  const words = new Uint32Array(2);
  for (let attempt = 0; attempt < 16; attempt++) {
    crypto.getRandomValues(words);
    if (words[0] !== 0 || words[1] !== 0)
      return (BigInt(words[0]) << 32n) | BigInt(words[1]);
  }
  return runtimeFail("randomness-failure", "OWeb could not allocate a nonzero instance identifier");
}

function claimInstanceIdentifier(crypto, claimedIdentifiers, excludedIdentifierKey = null) {
  for (let attempt = 0; attempt < 64; attempt++) {
    const identifier = randomInstanceIdentifier(crypto);
    const identifierKey = identifier.toString();
    if (identifierKey !== excludedIdentifierKey && !claimedIdentifiers.has(identifierKey)) {
      claimedIdentifiers.add(identifierKey);
      return identifier;
    }
  }
  return runtimeFail(
    "randomness-failure",
    "OWeb could not allocate a unique component instance identifier",
  );
}

function connectionEvent(CustomEventClass, state, code = null) {
  return new CustomEventClass("owebconnectionstatechange", {
    bubbles: true,
    composed: true,
    detail: Object.freeze({ state, code }),
  });
}

function errorCode(error) {
  if (typeof error?.code === "string")
    return error.code;
  if (error?.name === "AbortError")
    return "aborted";
  return "runtime-error";
}

async function exchangeWithNetworkRetry(transport, frame, options) {
  try {
    return await transport.exchange(frame, options);
  } catch (error) {
    const isRetryable = error?.name === "TypeError" || error?.code === "request-timeout";
    if (!isRetryable || options.signal?.aborted)
      throw error;
    /*
     * Fetch reports a response-lost network failure as TypeError, while the
     * bounded transport reports request-timeout. Reuse the exact bytes and
     * sequence once; the server session replays the cached response without
     * dispatching the action twice.
     */
    return transport.exchange(frame, options);
  }
}

function makeComponentClass({
  definition,
  HTMLElementClass,
  transport,
  crypto,
  CustomEventClass,
  disconnectGraceMilliseconds,
  claimedIdentifiers,
  scheduleTimeout,
  cancelTimeout,
  scheduleMicrotask,
}) {
  return class OWebBrowserComponent extends HTMLElementClass {
    static get observedAttributes() {
      return definition.observedAttributes;
    }

    #instanceId;
    #retiredInstanceIdentifierKey = null;
    #shadow;
    #interpreter;
    #connected = false;
    #mounted = false;
    #generation = 1;
    #sequence = 0n;
    #appliedSequence = 0n;
    #tail = Promise.resolve();
    #abortController = new AbortController();
    #disconnectTimer = null;
    #attributeMicrotaskPending = false;

    constructor() {
      super();
      this.#instanceId = null;

      this.#shadow = this.shadowRoot ?? this.attachShadow({ mode: "open" });
      if (childNodes(this.#shadow).length !== 0)
        runtimeFail("nonempty-shadow-root", "OWeb component shadow root was already populated");
      this.#resetRenderedTree();
      for (const eventType of definition.eventTypes)
        this.#shadow.addEventListener(eventType, (event) => {
          try {
            this.#handleEvent(event);
          } catch (error) {
            this.#setConnectionState("error", errorCode(error));
          }
        }, true);
    }

    connectedCallback() {
      this.#connected = true;
      if (this.#disconnectTimer !== null) {
        cancelTimeout(this.#disconnectTimer);
        this.#disconnectTimer = null;
      }
      if (this.#abortController.signal.aborted)
        this.#abortController = new AbortController();
      if (this.#instanceId === null) {
        this.#instanceId = claimInstanceIdentifier(
          crypto,
          claimedIdentifiers,
          this.#retiredInstanceIdentifierKey,
        );
        this.#retiredInstanceIdentifierKey = null;
      }
      this.#setConnectionState(this.#mounted ? "reconnecting" : "connecting");
      this.#enqueueMountSnapshot();
    }

    disconnectedCallback() {
      this.#connected = false;
      this.#setConnectionState("disconnecting");
      const generation = this.#generation;
      if (this.#disconnectTimer !== null)
        cancelTimeout(this.#disconnectTimer);
      this.#disconnectTimer = scheduleTimeout(() => {
        this.#disconnectTimer = null;
        if (!this.#connected && generation === this.#generation)
          this.#finalDetach();
      }, disconnectGraceMilliseconds);
    }

    attributeChangedCallback(name, oldValue, newValue) {
      if (oldValue === newValue || !this.#connected ||
          this.#attributeMicrotaskPending)
        return;
      this.#attributeMicrotaskPending = true;
      scheduleMicrotask(() => {
        this.#attributeMicrotaskPending = false;
        if (this.#connected)
          this.#enqueueMountSnapshot();
      });
    }

    #attributesSnapshot() {
      const attributes = Object.create(null);
      for (const name of definition.observedAttributes) {
        if (this.hasAttribute(name))
          attributes[name] = this.getAttribute(name);
      }
      return attributes;
    }

    #enqueueMountSnapshot() {
      const attributes = this.#attributesSnapshot();
      this.#enqueue(() => encodeMountFrame({
        instanceId: this.#instanceId,
        componentTag: definition.tag,
        attributes,
      }), { marksMounted: true });
    }

    #enqueue(frameFactory, { marksMounted = false } = {}) {
      const generation = this.#generation;
      const sequence = ++this.#sequence;
      const prior = this.#tail.catch(() => undefined);
      const task = prior.then(async () => {
        if (!this.#connected || generation !== this.#generation)
          return;
        const frame = frameFactory();
        const response = await exchangeWithNetworkRetry(transport, frame, {
          sequence,
          signal: this.#abortController.signal,
        });
        if (!this.#connected || generation !== this.#generation ||
            sequence <= this.#appliedSequence)
          return;
        if (response !== null) {
          const patch = decodePatchFrame(response);
          if (patch.instanceId !== this.#instanceId)
            runtimeFail("instance-mismatch", "OWeb patch targets a different component instance");
          this.#interpreter.apply(patch);
        }
        this.#appliedSequence = sequence;
        if (marksMounted)
          this.#mounted = true;
        this.#setConnectionState("connected");
      });
      this.#tail = task.catch(() => undefined);
      task.catch((error) => {
        if (generation === this.#generation && this.#connected &&
            error?.name !== "AbortError")
          this.#setConnectionState("error", errorCode(error));
      });
    }

    #handleEvent(event) {
      if (!this.#connected || !this.#mounted)
        return;
      const path = eventPath(event, this.#shadow);
      const capabilityName = `data-oweb-on-${event.type}`;
      let actionId = null;
      let actionNode = null;
      for (const node of path) {
        if (node === this.#shadow)
          break;
        const encoded = typeof node?.getAttribute === "function" ?
          node.getAttribute(capabilityName) : null;
        if (encoded !== null) {
          if (!/^[1-9][0-9]*$/.test(encoded)) {
            this.#setConnectionState("error", "invalid-action-identifier");
            return;
          }
          actionId = BigInt(encoded);
          actionNode = node;
          break;
        }
      }
      if (actionId === null)
        return;
      const targetId = this.#interpreter.targetIdentifierFromPath([actionNode]);
      if (targetId === 0n) {
        this.#setConnectionState("error", "missing-event-target-identifier");
        return;
      }
      if (event.type === "submit" && typeof event.preventDefault === "function")
        event.preventDefault();
      const fields = collectEventFields(event);
      this.#enqueue(() => encodeEventFrame({
        instanceId: this.#instanceId,
        actionId,
        targetId,
        fields,
      }));
    }

    #finalDetach() {
      const previousController = this.#abortController;
      previousController.abort();
      this.#generation++;
      this.#mounted = false;
      this.#abortController = new AbortController();
      const sequence = ++this.#sequence;
      const detachedIdentifier = this.#instanceId;
      const detachedIdentifierKey = detachedIdentifier.toString();
      const frame = encodeDetachFrame({ instanceId: detachedIdentifier });

      /*
       * A final detach ends one browser/server instance lifetime. Retire the
       * opaque identifier and rebuild the static tree now; claim its fresh
       * replacement only if this custom element later reconnects. This keeps
       * disconnected elements out of the active identifier set while ensuring
       * released dynamic capabilities cannot survive a later connection.
       */
      this.#instanceId = null;
      this.#retiredInstanceIdentifierKey = detachedIdentifierKey;
      this.#sequence = 0n;
      this.#appliedSequence = 0n;
      this.#resetRenderedTree();

      const detach = exchangeWithNetworkRetry(transport, frame, {
        sequence,
        signal: this.#abortController.signal,
        keepalive: true,
      }).then((response) => {
        if (response !== null)
          runtimeFail("unexpected-detach-patch", "OWeb detach returned a patch frame");
      }).catch(() => undefined).finally(() => {
        claimedIdentifiers.delete(detachedIdentifierKey);
      });
      this.#tail = detach;
      this.#setConnectionState("disconnected");
    }

    #resetRenderedTree() {
      for (const child of childNodes(this.#shadow))
        this.#shadow.removeChild(child);
      this.#shadow.appendChild(definition.template.content.cloneNode(true));
      this.#interpreter = new OWebPatchInterpreter(this.#shadow);
    }

    #setConnectionState(state, code = null) {
      this.setAttribute(CONNECTION_ATTRIBUTE, state);
      if (typeof this.dispatchEvent === "function")
        this.dispatchEvent(connectionEvent(CustomEventClass, state, code));
    }
  };
}

function endpointFromDocument(document) {
  const meta = document.querySelector(`meta[name="${ENDPOINT_META_NAME}"]`);
  const endpoint = meta?.getAttribute("content");
  if (endpoint == null || endpoint.length === 0)
    runtimeFail("missing-endpoint", "OWeb document does not declare its binary endpoint");
  return endpoint;
}

/**
 * Registers every `<template data-oweb-component="…">` in the server document.
 * The function is explicit so applications control whether registration occurs
 * before or after their own boot diagnostics.
 */
export function registerOWebComponents({
  document = globalThis.document,
  customElements = globalThis.customElements,
  HTMLElement: HTMLElementClass = globalThis.HTMLElement,
  CustomEvent: CustomEventClass = globalThis.CustomEvent,
  crypto = globalThis.crypto,
  fetch = globalThis.fetch,
  endpoint = null,
  disconnectGraceMilliseconds = 250,
  requestTimeoutMilliseconds = DEFAULT_REQUEST_TIMEOUT_MILLISECONDS,
  setTimeout: scheduleTimeout = globalThis.setTimeout,
  clearTimeout: cancelTimeout = globalThis.clearTimeout,
  queueMicrotask: scheduleMicrotask = globalThis.queueMicrotask,
} = {}) {
  if (document == null || customElements == null || HTMLElementClass == null ||
      CustomEventClass == null)
    throw new TypeError("OWeb registration requires browser DOM globals");
  if (!Number.isSafeInteger(disconnectGraceMilliseconds) ||
      disconnectGraceMilliseconds < 0 || disconnectGraceMilliseconds > 10_000)
    throw new RangeError("OWeb disconnect grace must be between 0 and 10000 ms");

  const transport = new OWebHTTPTransport(endpoint ?? endpointFromDocument(document), {
    fetch,
    baseURL: document.baseURI,
    requestTimeoutMilliseconds,
    setTimeout: scheduleTimeout,
    clearTimeout: cancelTimeout,
  });
  const claimedIdentifiers = new Set();
  const registered = [];
  const templates = document.querySelectorAll("template[data-oweb-component]");
  const definitions = Array.from(templates, (template) =>
    componentDefinition(template, document));
  const definitionTags = new Set();
  for (const definition of definitions) {
    if (definitionTags.has(definition.tag))
      runtimeFail("duplicate-component-definition", `Component ${definition.tag} is declared twice`);
    definitionTags.add(definition.tag);
    if (customElements.get(definition.tag) !== undefined)
      runtimeFail("component-already-defined", `Custom element ${definition.tag} is already defined`);
  }
  for (const definition of definitions) {
    const componentClass = makeComponentClass({
      definition,
      HTMLElementClass,
      transport,
      crypto,
      CustomEventClass,
      disconnectGraceMilliseconds,
      claimedIdentifiers,
      scheduleTimeout,
      cancelTimeout,
      scheduleMicrotask,
    });
    customElements.define(definition.tag, componentClass);
    registered.push(definition.tag);
  }
  return Object.freeze(registered);
}

export const startOWeb = registerOWebComponents;
