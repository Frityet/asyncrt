/*
 * OWeb browser wire codec.
 *
 * This module intentionally has no DOM dependency. It mirrors the canonical,
 * bounded Objective-C codec so it can be fuzzed and tested under Node as well
 * as used by the browser runtime.
 */

export const OWEB_MIME_TYPE = "application/vnd.oweb.frame";

export const OWebFrameType = Object.freeze({
  PATCH: 1,
  EVENT: 2,
  MOUNT: 3,
  DETACH: 4,
});

export const OWebPatchOpcode = Object.freeze({
  SET_TEXT: 1,
  SET_ATTRIBUTE: 2,
  REMOVE_ATTRIBUTE: 3,
  SET_PROPERTY: 4,
  FOCUS: 5,
  BATCH: 6,
  CLONE_TEMPLATE: 7,
  REMOVE_NODE: 8,
  MOVE_NODE: 9,
});

export const OWebValueType = Object.freeze({
  NULL: 0,
  FALSE: 1,
  TRUE: 2,
  SIGNED_INTEGER: 3,
  UNSIGNED_INTEGER: 4,
  DOUBLE: 5,
  STRING: 6,
});

export const OWebLimits = Object.freeze({
  FRAME_BYTES: 1024 * 1024,
  STRING_BYTES: 64 * 1024,
  OPERATIONS: 4096,
  BATCH_DEPTH: 8,
  EVENT_FIELDS: 32,
  MOUNT_ATTRIBUTES: 64,
});

const MAGIC = Object.freeze([0x4f, 0x57, 0x45, 0x42]);
const VERSION = 1;
const UINT64_MAX = (1n << 64n) - 1n;
const decoder = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true });
const encoder = new TextEncoder();

const EVENT_FIELDS = new Set([
  "altKey", "button", "buttons", "clientX", "clientY", "code", "ctrlKey",
  "data", "deltaX", "deltaY", "detail", "inputType", "key", "metaKey",
  "offsetX", "offsetY", "pointerId", "repeat", "shiftKey", "value",
]);

const PATCH_ATTRIBUTES = new Set([
  "aria-hidden", "checked", "class", "disabled", "hidden", "id", "open",
  "placeholder", "role", "selected", "tabindex", "title", "value",
]);

const PATCH_PROPERTIES = new Set([
  "checked", "disabled", "hidden", "indeterminate", "open", "scrollLeft",
  "scrollTop", "selected", "value",
]);

export class OWebProtocolError extends Error {
  constructor(code, message = code) {
    super(message);
    this.name = "OWebProtocolError";
    this.code = code;
  }
}

function fail(code, message) {
  throw new OWebProtocolError(code, message);
}

function asBytes(input) {
  if (input instanceof Uint8Array)
    return input;
  if (input instanceof ArrayBuffer)
    return new Uint8Array(input);
  if (ArrayBuffer.isView(input))
    return new Uint8Array(input.buffer, input.byteOffset, input.byteLength);
  throw new TypeError("OWeb frames must be ArrayBuffer or Uint8Array values");
}

function asUInt64(value, label, { allowZero = true } = {}) {
  let converted;
  if (typeof value === "bigint") {
    converted = value;
  } else if (typeof value === "number" && Number.isSafeInteger(value)) {
    converted = BigInt(value);
  } else {
    throw new TypeError(`${label} must be a safe integer or bigint`);
  }
  if (converted < 0n || converted > UINT64_MAX || (!allowZero && converted === 0n))
    throw new RangeError(`${label} is outside the allowed uint64 range`);
  return converted;
}

function isASCIIAttributeName(name) {
  return typeof name === "string" && /^[a-z_:][a-z0-9_.:-]{0,127}$/.test(name);
}

export function isPatchAttributeAllowed(name) {
  if (!isASCIIAttributeName(name))
    return false;
  if (name.startsWith("data-oweb-"))
    return false;
  return PATCH_ATTRIBUTES.has(name) || name.startsWith("aria-") ||
    name.startsWith("data-");
}

export function isPatchPropertyAllowed(name) {
  return PATCH_PROPERTIES.has(name);
}

export function isEventFieldAllowed(name) {
  return EVENT_FIELDS.has(name);
}

export function isComponentTagValid(tag) {
  return typeof tag === "string" && tag.length >= 3 && tag.length <= 128 &&
    /^[a-z][a-z0-9._-]*$/.test(tag) && tag.includes("-");
}

export function isMountAttributeNameValid(name) {
  return isASCIIAttributeName(name) && !(name.length > 2 && name.startsWith("on"));
}

class ByteReader {
  constructor(input) {
    this.bytes = asBytes(input);
    this.offset = 0;
    this.operationCount = 0;
  }

  get remaining() {
    return this.bytes.length - this.offset;
  }

  readByte() {
    if (this.offset >= this.bytes.length)
      fail("truncated", "OWeb frame ended unexpectedly");
    return this.bytes[this.offset++];
  }

  readVarUInt() {
    let result = 0n;
    for (let index = 0; index < 10; index++) {
      const byte = this.readByte();
      const payload = byte & 0x7f;
      if (index === 9 && payload > 1)
        fail("varint-overflow", "OWeb uint64 varint overflowed");
      result |= BigInt(payload) << BigInt(index * 7);
      if ((byte & 0x80) === 0) {
        if (index > 0 && payload === 0)
          fail("noncanonical-varint", "OWeb varint used a longer encoding");
        return result;
      }
    }
    return fail("varint-overflow", "OWeb uint64 varint overflowed");
  }

  readCount(maximum, label) {
    const value = this.readVarUInt();
    if (value > BigInt(maximum))
      fail(`${label}-limit`, `${label} exceeded the OWeb protocol limit`);
    return Number(value);
  }

  readIdentifier(label, { allowZero = false } = {}) {
    const value = this.readVarUInt();
    if (!allowZero && value === 0n)
      fail("invalid-identifier", `${label} must not be zero`);
    return value;
  }

  readString() {
    const length = this.readCount(OWebLimits.STRING_BYTES, "string");
    if (length > this.remaining)
      fail("truncated", "OWeb string extends past the frame body");
    const bytes = this.bytes.subarray(this.offset, this.offset + length);
    this.offset += length;
    try {
      return decoder.decode(bytes);
    } catch {
      return fail("invalid-utf8", "OWeb string is not valid UTF-8");
    }
  }

  readValue() {
    switch (this.readByte()) {
      case OWebValueType.NULL:
        return null;
      case OWebValueType.FALSE:
        return false;
      case OWebValueType.TRUE:
        return true;
      case OWebValueType.SIGNED_INTEGER: {
        const encoded = this.readVarUInt();
        return (encoded >> 1n) ^ -(encoded & 1n);
      }
      case OWebValueType.UNSIGNED_INTEGER:
        return this.readVarUInt();
      case OWebValueType.DOUBLE: {
        if (this.remaining < 8)
          fail("truncated", "OWeb double extends past the frame body");
        const view = new DataView(
          this.bytes.buffer,
          this.bytes.byteOffset + this.offset,
          8,
        );
        const high = view.getUint32(0, false);
        const low = view.getUint32(4, false);
        this.offset += 8;
        if (high === 0x80000000 && low === 0)
          fail("invalid-value", "OWeb doubles must encode zero canonically");
        const value = view.getFloat64(0, false);
        if (!Number.isFinite(value))
          fail("invalid-value", "OWeb doubles must be finite");
        return value;
      }
      case OWebValueType.STRING:
        return this.readString();
      default:
        return fail("unknown-value-type", "OWeb value has an unknown tag");
    }
  }

  readPatchOperation(depth) {
    if (depth > OWebLimits.BATCH_DEPTH)
      fail("batch-depth-limit", "OWeb patch batch nesting is too deep");
    this.operationCount++;
    if (this.operationCount > OWebLimits.OPERATIONS)
      fail("operation-limit", "OWeb patch contains too many operations");

    const opcode = this.readByte();
    switch (opcode) {
      case OWebPatchOpcode.SET_TEXT:
        return Object.freeze({
          opcode,
          elementId: this.readIdentifier("element identifier"),
          text: this.readString(),
        });
      case OWebPatchOpcode.SET_ATTRIBUTE: {
        const elementId = this.readIdentifier("element identifier");
        const name = this.readString();
        if (!isPatchAttributeAllowed(name))
          fail("disallowed-attribute", "OWeb patch attribute is not allowlisted");
        return Object.freeze({ opcode, elementId, name, value: this.readString() });
      }
      case OWebPatchOpcode.REMOVE_ATTRIBUTE: {
        const elementId = this.readIdentifier("element identifier");
        const name = this.readString();
        if (!isPatchAttributeAllowed(name))
          fail("disallowed-attribute", "OWeb patch attribute is not allowlisted");
        return Object.freeze({ opcode, elementId, name });
      }
      case OWebPatchOpcode.SET_PROPERTY: {
        const elementId = this.readIdentifier("element identifier");
        const name = this.readString();
        if (!isPatchPropertyAllowed(name))
          fail("disallowed-property", "OWeb patch property is not allowlisted");
        return Object.freeze({ opcode, elementId, name, value: this.readValue() });
      }
      case OWebPatchOpcode.FOCUS:
        return Object.freeze({
          opcode,
          elementId: this.readIdentifier("element identifier"),
        });
      case OWebPatchOpcode.BATCH: {
        const count = this.readCount(OWebLimits.OPERATIONS, "operation");
        if (count > OWebLimits.OPERATIONS - this.operationCount)
          fail("operation-limit", "OWeb patch contains too many operations");
        const operations = [];
        for (let index = 0; index < count; index++)
          operations.push(this.readPatchOperation(depth + 1));
        return Object.freeze({ opcode, operations: Object.freeze(operations) });
      }
      case OWebPatchOpcode.CLONE_TEMPLATE:
        return Object.freeze({
          opcode,
          templateId: this.readIdentifier("template identifier"),
          parentId: this.readIdentifier("parent identifier"),
          nodeId: this.readIdentifier("node identifier"),
        });
      case OWebPatchOpcode.REMOVE_NODE:
        return Object.freeze({
          opcode,
          nodeId: this.readIdentifier("node identifier"),
        });
      case OWebPatchOpcode.MOVE_NODE:
        return Object.freeze({
          opcode,
          nodeId: this.readIdentifier("node identifier"),
          parentId: this.readIdentifier("parent identifier"),
          beforeId: this.readIdentifier("before identifier", { allowZero: true }),
        });
      default:
        return fail("unknown-opcode", "OWeb patch has an unknown opcode");
    }
  }
}

class ByteWriter {
  constructor(initialCapacity = 256) {
    this.bytes = new Uint8Array(initialCapacity);
    this.length = 0;
  }

  ensure(additional) {
    const needed = this.length + additional;
    if (needed > OWebLimits.FRAME_BYTES)
      fail("frame-too-large", "OWeb frame exceeds the byte limit");
    if (needed <= this.bytes.length)
      return;
    let capacity = this.bytes.length;
    while (capacity < needed)
      capacity = Math.min(OWebLimits.FRAME_BYTES, capacity * 2);
    const replacement = new Uint8Array(capacity);
    replacement.set(this.bytes.subarray(0, this.length));
    this.bytes = replacement;
  }

  writeByte(value) {
    this.ensure(1);
    this.bytes[this.length++] = value;
  }

  writeBytes(values) {
    this.ensure(values.length);
    this.bytes.set(values, this.length);
    this.length += values.length;
  }

  writeVarUInt(value, label = "value") {
    let remaining = asUInt64(value, label);
    do {
      let byte = Number(remaining & 0x7fn);
      remaining >>= 7n;
      if (remaining !== 0n)
        byte |= 0x80;
      this.writeByte(byte);
    } while (remaining !== 0n);
  }

  writeString(value) {
    if (typeof value !== "string")
      throw new TypeError("OWeb wire strings must be JavaScript strings");
    const bytes = encoder.encode(value);
    if (bytes.length > OWebLimits.STRING_BYTES)
      fail("string-limit", "OWeb string exceeds the byte limit");
    this.writeVarUInt(bytes.length, "string length");
    this.writeBytes(bytes);
  }

  writeDouble(value) {
    if (!Number.isFinite(value))
      fail("invalid-value", "OWeb doubles must be finite");
    const normalized = Object.is(value, -0) ? 0 : value;
    this.ensure(8);
    new DataView(this.bytes.buffer).setFloat64(this.length, normalized, false);
    this.length += 8;
  }

  writeValue(value, preferredIntegerKind = "signed") {
    if (value === null) {
      this.writeByte(OWebValueType.NULL);
    } else if (value === false) {
      this.writeByte(OWebValueType.FALSE);
    } else if (value === true) {
      this.writeByte(OWebValueType.TRUE);
    } else if (typeof value === "string") {
      this.writeByte(OWebValueType.STRING);
      this.writeString(value);
    } else if (typeof value === "bigint" || Number.isSafeInteger(value)) {
      const integer = typeof value === "bigint" ? value : BigInt(value);
      if (preferredIntegerKind === "unsigned" && integer >= 0n) {
        this.writeByte(OWebValueType.UNSIGNED_INTEGER);
        this.writeVarUInt(integer, "unsigned integer");
      } else {
        if (integer < -(1n << 63n) || integer > (1n << 63n) - 1n)
          fail("invalid-value", "OWeb signed integer is outside int64 range");
        this.writeByte(OWebValueType.SIGNED_INTEGER);
        const zigzag = (integer << 1n) ^ (integer >> 63n);
        this.writeVarUInt(zigzag, "signed integer");
      }
    } else if (typeof value === "number") {
      this.writeByte(OWebValueType.DOUBLE);
      this.writeDouble(value);
    } else {
      throw new TypeError("OWeb values must be null, boolean, number, bigint, or string");
    }
  }

  finish() {
    return this.bytes.slice(0, this.length);
  }
}

function encodeFrame(frameType, appendBody) {
  const body = new ByteWriter();
  appendBody(body);
  const bodyBytes = body.finish();
  const output = new ByteWriter(bodyBytes.length + 16);
  output.writeBytes(MAGIC);
  output.writeByte(VERSION);
  output.writeByte(frameType);
  output.writeVarUInt(bodyBytes.length, "body length");
  output.writeBytes(bodyBytes);
  return output.finish();
}

function sortedEntries(record) {
  const entries = record instanceof Map ? [...record.entries()] : Object.entries(record);
  entries.sort(([left], [right]) => left < right ? -1 : left > right ? 1 : 0);
  return entries;
}

const UNSIGNED_EVENT_FIELDS = new Set(["button", "buttons", "detail", "pointerId"]);

export function encodeEventFrame({ instanceId, actionId, targetId, fields = {} }) {
  const entries = sortedEntries(fields);
  if (entries.length > OWebLimits.EVENT_FIELDS)
    fail("event-field-limit", "OWeb event contains too many fields");
  return encodeFrame(OWebFrameType.EVENT, (body) => {
    body.writeVarUInt(asUInt64(instanceId, "instance identifier", { allowZero: false }));
    body.writeVarUInt(asUInt64(actionId, "action identifier", { allowZero: false }));
    body.writeVarUInt(asUInt64(targetId, "target identifier", { allowZero: false }));
    body.writeVarUInt(entries.length, "event field count");
    for (const [name, value] of entries) {
      if (!isEventFieldAllowed(name))
        fail("disallowed-event-field", "OWeb event field is not allowlisted");
      body.writeString(name);
      body.writeValue(value, UNSIGNED_EVENT_FIELDS.has(name) ? "unsigned" : "signed");
    }
  });
}

export function encodeMountFrame({ instanceId, componentTag, attributes = {} }) {
  if (!isComponentTagValid(componentTag))
    fail("invalid-component-tag", "OWeb component tag is invalid");
  const entries = sortedEntries(attributes);
  if (entries.length > OWebLimits.MOUNT_ATTRIBUTES)
    fail("mount-attribute-limit", "OWeb mount contains too many attributes");
  return encodeFrame(OWebFrameType.MOUNT, (body) => {
    body.writeVarUInt(asUInt64(instanceId, "instance identifier", { allowZero: false }));
    body.writeString(componentTag);
    body.writeVarUInt(entries.length, "mount attribute count");
    for (const [name, value] of entries) {
      if (!isMountAttributeNameValid(name))
        fail("invalid-attribute-name", "OWeb mount attribute name is invalid");
      body.writeString(name);
      body.writeString(value);
    }
  });
}

export function encodeDetachFrame({ instanceId }) {
  return encodeFrame(OWebFrameType.DETACH, (body) => {
    body.writeVarUInt(asUInt64(instanceId, "instance identifier", { allowZero: false }));
  });
}

export function decodePatchFrame(input) {
  const bytes = asBytes(input);
  if (bytes.length > OWebLimits.FRAME_BYTES)
    fail("frame-too-large", "OWeb frame exceeds the byte limit");
  if (bytes.length < 7)
    fail("truncated", "OWeb frame is shorter than its header");

  const reader = new ByteReader(bytes);
  for (const expected of MAGIC) {
    if (reader.readByte() !== expected)
      fail("invalid-magic", "OWeb frame magic does not match");
  }
  if (reader.readByte() !== VERSION)
    fail("unsupported-version", "OWeb wire version is unsupported");
  const frameType = reader.readByte();
  if (frameType !== OWebFrameType.PATCH)
    fail("unexpected-frame-type", "Browser expected an OWeb patch frame");
  const bodyLength = reader.readVarUInt();
  if (bodyLength > BigInt(reader.remaining))
    fail("truncated", "OWeb body length extends beyond the frame");
  if (bodyLength < BigInt(reader.remaining))
    fail("trailing-data", "OWeb frame contains trailing bytes");

  const instanceId = reader.readIdentifier("instance identifier");
  const count = reader.readCount(OWebLimits.OPERATIONS, "operation");
  const operations = [];
  for (let index = 0; index < count; index++)
    operations.push(reader.readPatchOperation(0));
  if (reader.remaining !== 0)
    fail("trailing-data", "OWeb patch body contains trailing bytes");
  return Object.freeze({
    type: frameType,
    instanceId,
    operations: Object.freeze(operations),
  });
}

export const OWebProtocolInternals = Object.freeze({
  ByteWriter,
  VERSION,
});
