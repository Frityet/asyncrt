import assert from "node:assert/strict";
import test from "node:test";

import {
  OWEB_MIME_TYPE,
  encodeDetachFrame,
  encodeMountFrame,
} from "../../../../AsyncRT/Web/src/oweb-protocol.mjs";
import { registerOWebComponents } from "../../../../AsyncRT/Web/src/oweb-runtime.mjs";

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

  removeChild(node) {
    const index = this.childNodes.indexOf(node);
    this.childNodes.splice(index, 1);
    node.parentNode = null;
  }

  remove() {
    this.parentNode?.removeChild(this);
  }

  get textContent() {
    return this.childNodes.length === 0 ? this._text :
      this.childNodes.map((child) => child.textContent).join("");
  }

  set textContent(value) {
    this.childNodes = [];
    this._text = String(value);
  }
}

class FakeFragment extends FakeNode {
  constructor() {
    super(11);
    this.listeners = new Map();
  }

  cloneNode(deep) {
    const clone = new FakeFragment();
    if (deep) {
      for (const child of this.childNodes)
        clone.appendChild(child.cloneNode(true));
    }
    return clone;
  }

  addEventListener(type, listener) {
    const listeners = this.listeners.get(type) ?? [];
    listeners.push(listener);
    this.listeners.set(type, listeners);
  }

  emit(type, event) {
    for (const listener of this.listeners.get(type) ?? [])
      listener(event);
  }
}

class FakeElement extends FakeNode {
  constructor(tagName = "host", attributes = {}) {
    super(1);
    this.tagName = tagName.toUpperCase();
    this.attributes = new Map(Object.entries(attributes));
    this.shadowRoot = null;
    this.dispatchedEvents = [];
  }

  getAttribute(name) {
    return this.attributes.has(name) ? this.attributes.get(name) : null;
  }

  getAttributeNames() {
    return [...this.attributes.keys()];
  }

  hasAttribute(name) {
    return this.attributes.has(name);
  }

  setAttribute(name, value) {
    this.attributes.set(name, String(value));
  }

  removeAttribute(name) {
    this.attributes.delete(name);
  }

  attachShadow() {
    if (this.shadowRoot !== null)
      throw new Error("shadow root already attached");
    this.shadowRoot = new FakeFragment();
    return this.shadowRoot;
  }

  dispatchEvent(event) {
    this.dispatchedEvents.push(event);
    return true;
  }

  cloneNode(deep) {
    const clone = new FakeElement(this.tagName, Object.fromEntries(this.attributes));
    if (deep) {
      for (const child of this.childNodes)
        clone.appendChild(child.cloneNode(true));
    }
    return clone;
  }
}

class FakeTemplate extends FakeElement {
  constructor(attributes) {
    super("template", attributes);
    this.content = new FakeFragment();
    this.ownerDocument = null;
  }
}

class FakeCustomEvent {
  constructor(type, options) {
    this.type = type;
    Object.assign(this, options);
  }
}

class FakeRegistry {
  constructor() {
    this.classes = new Map();
  }

  define(tag, componentClass) {
    this.classes.set(tag, componentClass);
  }

  get(tag) {
    return this.classes.get(tag);
  }
}

function emptyPatch(instanceIdentifier) {
  return Uint8Array.of(
    0x4f, 0x57, 0x45, 0x42, 0x01, 0x01, 0x02,
    Number(instanceIdentifier), 0x00,
  );
}

async function settle() {
  await Promise.resolve();
  await new Promise((resolve) => setImmediate(resolve));
  await Promise.resolve();
}

test("custom element lifecycle is mount-scoped, batched, delegated, and reconnect-safe", async () => {
  const template = new FakeTemplate({
    "data-oweb-component": "my-component",
    "data-oweb-observed-attributes": "name tone",
  });
  const button = new FakeElement("button", {
    "data-oweb-id": "1",
    "data-oweb-on-click": "7",
  });
  const label = new FakeElement("span", { "data-oweb-id": "2" });
  button.appendChild(label);
  template.content.appendChild(button);
  const meta = new FakeElement("meta", { content: "/_oweb" });
  const document = {
    baseURI: "https://rei.test/dashboard",
    querySelector(selector) {
      assert.equal(selector, "meta[name=\"oweb-endpoint\"]");
      return meta;
    },
    querySelectorAll(selector) {
      assert.equal(selector, "template[data-oweb-component]");
      return [template];
    },
  };
  template.ownerDocument = document;

  const registry = new FakeRegistry();
  const timers = [];
  const sentTypes = [];
  const sequences = [];
  const eventFrames = [];
  const requestSignals = [];
  let timeoutFirstEventResponse = true;
  const fetch = async (_url, options) => {
    const sequence = options.headers["X-OWeb-Sequence"];
    const type = options.body[5];
    sentTypes.push(type);
    sequences.push(sequence);
    requestSignals.push(options.signal);
    if (type === 2)
      eventFrames.push(new Uint8Array(options.body));
    if (type === 2 && timeoutFirstEventResponse) {
      timeoutFirstEventResponse = false;
      return new Promise((_resolve, reject) => {
        options.signal.addEventListener("abort", () => {
          reject(options.signal.reason);
        }, { once: true });
      });
    }
    if (type === 4) {
      return new Response(null, {
        status: 204,
        headers: { "x-oweb-sequence": sequence },
      });
    }
    return new Response(emptyPatch(options.body[7]), {
      status: 200,
      headers: {
        "content-type": OWEB_MIME_TYPE,
        "x-oweb-sequence": sequence,
      },
    });
  };
  let nextIdentifier = 42;
  const crypto = {
    getRandomValues(words) {
      words[0] = 0;
      words[1] = nextIdentifier++;
      return words;
    },
  };
  const scheduleTimeout = (callback, delay) => {
    const timer = { callback, delay, cancelled: false };
    timers.push(timer);
    return timer;
  };
  const cancelTimeout = (timer) => {
    timer.cancelled = true;
  };

  assert.deepEqual(registerOWebComponents({
    document,
    customElements: registry,
    HTMLElement: FakeElement,
    CustomEvent: FakeCustomEvent,
    crypto,
    fetch,
    requestTimeoutMilliseconds: 25,
    setTimeout: scheduleTimeout,
    clearTimeout: cancelTimeout,
    queueMicrotask,
  }), ["my-component"]);

  const ComponentClass = registry.get("my-component");
  assert.deepEqual(ComponentClass.observedAttributes, ["name", "tone"]);
  const host = new ComponentClass();
  assert.equal(nextIdentifier, 42,
    "constructing a disconnected element does not claim an identifier");
  host.setAttribute("name", "Rei");
  const initialChild = host.shadowRoot.childNodes[0];
  host.connectedCallback();
  assert.equal(nextIdentifier, 43,
    "the first connected lifetime claims its identifier lazily");
  await settle();
  assert.deepEqual(sentTypes, [3]);
  assert.equal(host.getAttribute("data-oweb-connection"), "connected");

  host.setAttribute("name", "Rei 2");
  host.attributeChangedCallback("name", "Rei", "Rei 2");
  host.setAttribute("tone", "warm");
  host.attributeChangedCallback("tone", null, "warm");
  await settle();
  assert.deepEqual(sentTypes, [3, 3], "same-turn attributes share one full snapshot");

  let prevented = false;
  const liveButton = host.shadowRoot.childNodes[0];
  const liveLabel = liveButton.childNodes[0];
  host.shadowRoot.emit("click", {
    type: "click",
    target: liveLabel,
    clientX: 4,
    composedPath: () => [liveLabel, liveButton, host.shadowRoot],
    preventDefault: () => { prevented = true; },
  });
  await Promise.resolve();
  await Promise.resolve();
  const eventTimeout = timers.at(-1);
  assert.equal(eventTimeout.delay, 25);
  assert.equal(eventTimeout.cancelled, false);
  eventTimeout.callback();
  await settle();
  assert.deepEqual(sentTypes, [3, 3, 2, 2]);
  assert.equal(eventFrames[0][9], 1,
    "delegated events identify the action-owning element, not a nested target");
  assert.deepEqual(eventFrames[1], eventFrames[0],
    "timeout retry reuses the exact event frame");
  assert.equal(sequences[2], sequences[3],
    "timeout retry reuses the exact sequence");
  assert.equal(requestSignals[2].aborted, true);
  assert.equal(requestSignals[3].aborted, false,
    "the retry receives a fresh request-scoped abort signal");
  assert.equal(prevented, false, "only submit receives framework default prevention");

  host.disconnectedCallback();
  const transientTimer = timers.at(-1);
  host.connectedCallback();
  await settle();
  assert.equal(transientTimer.cancelled, true);
  assert.deepEqual(sentTypes, [3, 3, 2, 2, 3]);
  assert.equal(host.shadowRoot.childNodes.length, 1);
  assert.equal(host.shadowRoot.childNodes[0], initialChild);

  host.disconnectedCallback();
  const finalTimer = timers.at(-1);
  host.shadowRoot.appendChild(new FakeElement("li", { "data-stale-dynamic": "true" }));
  finalTimer.callback();
  await settle();
  assert.deepEqual(sentTypes, [3, 3, 2, 2, 3, 4]);
  assert.equal(host.getAttribute("data-oweb-connection"), "disconnected");
  assert.deepEqual(sequences, ["1", "2", "3", "3", "4", "5"]);
  assert.equal(host.shadowRoot.childNodes.length, 1,
    "final detach removes browser-owned dynamic state before a new mount lifetime");
  assert.notEqual(host.shadowRoot.childNodes[0], initialChild,
    "final detach reclones the immutable static definition");
  assert.equal(nextIdentifier, 43,
    "final detach does not retain an unused replacement identifier");

  host.connectedCallback();
  assert.equal(nextIdentifier, 44,
    "a replacement identifier is claimed only when the element reconnects");
  await settle();
  assert.deepEqual(sentTypes, [3, 3, 2, 2, 3, 4, 3]);
  assert.equal(sequences.at(-1), "1",
    "a new opaque instance lifetime restarts its independent sequence stream");
  assert.equal(host.getAttribute("data-oweb-connection"), "connected");
  assert.ok(host.dispatchedEvents.some((event) =>
    event.type === "owebconnectionstatechange" && event.detail.state === "connected"));
});

test("instance identifiers exist only for connected component lifetimes", async () => {
  const template = new FakeTemplate({
    "data-oweb-component": "lifetime-component",
  });
  template.content.appendChild(new FakeElement("span", { "data-oweb-id": "1" }));
  const meta = new FakeElement("meta", { content: "/_oweb" });
  const document = {
    baseURI: "https://rei.test/dashboard",
    querySelector: () => meta,
    querySelectorAll: () => [template],
  };
  template.ownerDocument = document;

  const registry = new FakeRegistry();
  const timers = [];
  const mountFrames = [];
  const detachFrames = [];
  const randomIdentifiers = [42, 42, 43, 42, 44];
  let randomDraws = 0;
  const crypto = {
    getRandomValues(words) {
      words[0] = 0;
      words[1] = randomIdentifiers[randomDraws++];
      return words;
    },
  };
  const fetch = async (_url, options) => {
    const frame = new Uint8Array(options.body);
    const type = frame[5];
    if (type === 3) {
      mountFrames.push(frame);
      return new Response(emptyPatch(frame[7]), {
        status: 200,
        headers: {
          "content-type": OWEB_MIME_TYPE,
          "x-oweb-sequence": options.headers["X-OWeb-Sequence"],
        },
      });
    }
    assert.equal(type, 4);
    detachFrames.push(frame);
    throw new TypeError("simulated detach response loss");
  };
  const scheduleTimeout = (callback, delay) => {
    const timer = { callback, delay, cancelled: false };
    timers.push(timer);
    return timer;
  };
  const cancelTimeout = (timer) => {
    timer.cancelled = true;
  };

  registerOWebComponents({
    document,
    customElements: registry,
    HTMLElement: FakeElement,
    CustomEvent: FakeCustomEvent,
    crypto,
    fetch,
    requestTimeoutMilliseconds: 25,
    setTimeout: scheduleTimeout,
    clearTimeout: cancelTimeout,
    queueMicrotask,
  });

  const ComponentClass = registry.get("lifetime-component");
  const first = new ComponentClass();
  const neverConnected = new ComponentClass();
  assert.ok(neverConnected);
  assert.equal(randomDraws, 0,
    "constructing disconnected elements does not reserve identifiers");

  first.connectedCallback();
  await settle();
  assert.equal(randomDraws, 1);
  assert.deepEqual(mountFrames[0], encodeMountFrame({
    instanceId: 42n,
    componentTag: "lifetime-component",
    attributes: {},
  }));

  first.disconnectedCallback();
  const graceTimer = [...timers].reverse().find((timer) =>
    timer.delay === 250 && !timer.cancelled);
  assert.ok(graceTimer);
  graceTimer.callback();
  await settle();
  assert.equal(randomDraws, 1,
    "even an uncertain final detach does not preallocate a replacement");
  assert.equal(detachFrames.length, 2,
    "response loss receives one exact-frame detach retry");
  const expectedDetach = encodeDetachFrame({ instanceId: 42n });
  assert.deepEqual(detachFrames[0], expectedDetach);
  assert.deepEqual(detachFrames[1], expectedDetach);

  first.connectedCallback();
  await settle();
  assert.equal(randomDraws, 3,
    "reconnect rejects the retired numeric identifier and claims a fresh one");
  assert.deepEqual(mountFrames[1], encodeMountFrame({
    instanceId: 43n,
    componentTag: "lifetime-component",
    attributes: {},
  }));

  const second = new ComponentClass();
  assert.equal(randomDraws, 3);
  second.connectedCallback();
  await settle();
  assert.equal(randomDraws, 4,
    "the failed detach claim was released from the active global set");
  assert.deepEqual(mountFrames[2], encodeMountFrame({
    instanceId: 42n,
    componentTag: "lifetime-component",
    attributes: {},
  }));
});
