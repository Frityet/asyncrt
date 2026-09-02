import assert from "node:assert/strict";
import test from "node:test";

import {
  OWebLimits,
  OWebPatchOpcode,
  OWebProtocolError,
  decodePatchFrame,
  encodeDetachFrame,
  encodeEventFrame,
  encodeMountFrame,
} from "../../../../AsyncRT/Web/src/oweb-protocol.mjs";

function bytes(...values) {
  return Uint8Array.from(values.flat(Infinity));
}

function frame(type, body, encodedLength = null) {
  const flattened = body.flat(Infinity);
  return bytes(
    0x4f, 0x57, 0x45, 0x42, 0x01, type,
    encodedLength ?? [flattened.length],
    flattened,
  );
}

function hex(data) {
  return Buffer.from(data).toString("hex");
}

function protocolCode(code) {
  return (error) => error instanceof OWebProtocolError && error.code === code;
}

test("decodes the canonical patch bytecode fixture", () => {
  const fixture = bytes(
    0x4f, 0x57, 0x45, 0x42, 0x01, 0x01, 0x24,
    0x09, 0x05,
    0x01, 0x01, 0x02, 0x68, 0x69,
    0x02, 0x02, 0x05, 0x63, 0x6c, 0x61, 0x73, 0x73, 0x01, 0x78,
    0x04, 0x03, 0x07, 0x63, 0x68, 0x65, 0x63, 0x6b, 0x65, 0x64, 0x02,
    0x07, 0x04, 0x05, 0x06,
    0x09, 0x06, 0x05, 0x00,
  );
  const decoded = decodePatchFrame(fixture);
  assert.equal(decoded.instanceId, 9n);
  assert.equal(decoded.operations.length, 5);
  assert.deepEqual(decoded.operations[0], {
    opcode: OWebPatchOpcode.SET_TEXT,
    elementId: 1n,
    text: "hi",
  });
  assert.deepEqual(decoded.operations[1], {
    opcode: OWebPatchOpcode.SET_ATTRIBUTE,
    elementId: 2n,
    name: "class",
    value: "x",
  });
  assert.equal(decoded.operations[2].value, true);
  assert.deepEqual(decoded.operations[3], {
    opcode: OWebPatchOpcode.CLONE_TEMPLATE,
    templateId: 4n,
    parentId: 5n,
    nodeId: 6n,
  });
  assert.equal(decoded.operations[4].beforeId, 0n);
});

test("event, mount, and detach encoders are canonical and deterministic", () => {
  assert.equal(hex(encodeEventFrame({
    instanceId: 1n,
    actionId: 2n,
    targetId: 3n,
    fields: { key: "a", altKey: true },
  })), "4f5745420102130102030206616c744b657902036b6579060161");

  assert.equal(hex(encodeMountFrame({
    instanceId: 1n,
    componentTag: "x-a",
    attributes: { name: "Rei", disabled: "" },
  })), "4f5745420103190103782d61020864697361626c656400046e616d6503526569");

  assert.equal(
    hex(encodeDetachFrame({ instanceId: 300n })),
    "4f574542010402ac02",
  );
});

test("browser codec matches the Objective-C release fixtures byte for byte", () => {
  assert.equal(hex(encodeEventFrame({
    instanceId: 1n,
    actionId: 2n,
    targetId: 3n,
    fields: { altKey: false, value: "Rei" },
  })), "4f5745420102170102030206616c744b6579010576616c75650603526569");
  assert.equal(hex(encodeMountFrame({
    instanceId: 1n,
    componentTag: "my-component",
    attributes: { "data-mode": "live", name: "Rei" },
  })), "4f574542010327010c6d792d636f6d706f6e656e740209646174612d6d6f6465046c697665046e616d6503526569");
  assert.equal(hex(encodeDetachFrame({ instanceId: 1n })), "4f57454201040101");

  const text = decodePatchFrame(Buffer.from(
    "4f57454201010701010102024869",
    "hex",
  ));
  assert.deepEqual(text.operations, [{
    opcode: OWebPatchOpcode.SET_TEXT,
    elementId: 2n,
    text: "Hi",
  }]);
  const clone = decodePatchFrame(Buffer.from(
    "4f574542010106010107020304",
    "hex",
  ));
  assert.deepEqual(clone.operations, [{
    opcode: OWebPatchOpcode.CLONE_TEMPLATE,
    templateId: 2n,
    parentId: 3n,
    nodeId: 4n,
  }]);
});

test("encoder rejects unbounded and non-capability data", () => {
  assert.throws(() => encodeEventFrame({
    instanceId: 1n,
    actionId: 2n,
    targetId: 0n,
  }), RangeError);
  assert.throws(() => encodeEventFrame({
    instanceId: 1n,
    actionId: 2n,
  }), TypeError);
  assert.throws(() => encodeEventFrame({
    instanceId: 1n,
    actionId: 2n,
    targetId: 3n,
    fields: { constructor: "no" },
  }), protocolCode("disallowed-event-field"));
  assert.throws(() => encodeMountFrame({
    instanceId: 1n,
    componentTag: "nohyphen",
  }), protocolCode("invalid-component-tag"));
  assert.throws(() => encodeMountFrame({
    instanceId: 1n,
    componentTag: "x-a",
    attributes: { name: "x".repeat(OWebLimits.STRING_BYTES + 1) },
  }), protocolCode("string-limit"));
});

test("decoder rejects invalid header, version, direction, and trailing bytes", () => {
  assert.throws(
    () => decodePatchFrame(bytes(0, 0x57, 0x45, 0x42, 1, 1, 0)),
    protocolCode("invalid-magic"),
  );
  assert.throws(
    () => decodePatchFrame(bytes(0x4f, 0x57, 0x45, 0x42, 2, 1, 0)),
    protocolCode("unsupported-version"),
  );
  assert.throws(
    () => decodePatchFrame(bytes(0x4f, 0x57, 0x45, 0x42, 1, 2, 0)),
    protocolCode("unexpected-frame-type"),
  );
  assert.throws(
    () => decodePatchFrame(frame(1, [1, 0, 0], [2])),
    protocolCode("trailing-data"),
  );
});

test("decoder rejects noncanonical or overflowing varints", () => {
  assert.throws(
    () => decodePatchFrame(bytes(0x4f, 0x57, 0x45, 0x42, 1, 1, 0x80, 0)),
    protocolCode("noncanonical-varint"),
  );
  assert.throws(
    () => decodePatchFrame(bytes(
      0x4f, 0x57, 0x45, 0x42, 1, 1,
      0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x02,
    )),
    protocolCode("varint-overflow"),
  );
});

test("decoder rejects truncation, invalid UTF-8, and zero capability IDs", () => {
  assert.throws(
    () => decodePatchFrame(frame(1, [1, 1, 1, 1, 2, 0x61])),
    protocolCode("truncated"),
  );
  assert.throws(
    () => decodePatchFrame(frame(1, [1, 1, 1, 1, 1, 0xff])),
    protocolCode("invalid-utf8"),
  );
  assert.throws(
    () => decodePatchFrame(frame(1, [1, 1, 5, 0])),
    protocolCode("invalid-identifier"),
  );
});

test("decoder rejects unknown and reserved mutation bytecodes", () => {
  assert.throws(
    () => decodePatchFrame(frame(1, [1, 1, 0xff])),
    protocolCode("unknown-opcode"),
  );
  const reservedName = [...Buffer.from("data-oweb-id")];
  assert.throws(
    () => decodePatchFrame(frame(1, [
      1, 1, 2, 1, reservedName.length, reservedName, 1, 0x78,
    ])),
    protocolCode("disallowed-attribute"),
  );
});

test("decoder enforces recursive batch depth before interpreter use", () => {
  let operation = [5, 1];
  for (let index = 0; index < OWebLimits.BATCH_DEPTH + 1; index++)
    operation = [6, 1, operation];
  assert.throws(
    () => decodePatchFrame(frame(1, [1, 1, operation])),
    protocolCode("batch-depth-limit"),
  );
});

test("decoder rejects negative zero and non-finite property doubles", () => {
  const name = [...Buffer.from("value")];
  const prefix = [1, 1, 4, 1, name.length, name, 5];
  assert.throws(
    () => decodePatchFrame(frame(1, [prefix, 0x80, 0, 0, 0, 0, 0, 0, 0])),
    protocolCode("invalid-value"),
  );
  assert.throws(
    () => decodePatchFrame(frame(1, [prefix, 0x7f, 0xf0, 0, 0, 0, 0, 0, 0])),
    protocolCode("invalid-value"),
  );
});
