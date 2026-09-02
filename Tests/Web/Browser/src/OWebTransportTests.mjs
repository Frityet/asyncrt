import assert from "node:assert/strict";
import test from "node:test";

import { OWEB_MIME_TYPE, OWebLimits } from "../../../../AsyncRT/Web/src/oweb-protocol.mjs";
import {
  OWebHTTPTransport,
  collectEventFields,
} from "../../../../AsyncRT/Web/src/oweb-runtime.mjs";
import { OWebRuntimeError } from "../../../../AsyncRT/Web/src/oweb-interpreter.mjs";

const EMPTY_PATCH = Uint8Array.from([
  0x4f, 0x57, 0x45, 0x42, 0x01, 0x01, 0x02, 0x01, 0x00,
]);

function runtimeCode(code) {
  return (error) => error instanceof OWebRuntimeError && error.code === code;
}

test("HTTP transport sends a bounded same-origin binary exchange", async () => {
  let request;
  const timers = [];
  const transport = new OWebHTTPTransport("/_oweb", {
    baseURL: "https://rei.test/dashboard",
    setTimeout(callback, delay) {
      const timer = { callback, delay, cancelled: false };
      timers.push(timer);
      return timer;
    },
    clearTimeout(timer) {
      timer.cancelled = true;
    },
    fetch: async (url, options) => {
      request = { url, options };
      return new Response(EMPTY_PATCH, {
        status: 200,
        headers: {
          "content-type": `${OWEB_MIME_TYPE}; version=1`,
          "content-length": String(EMPTY_PATCH.length),
          "x-oweb-sequence": "7",
        },
      });
    },
  });

  const result = await transport.exchange(Uint8Array.of(1, 2, 3), { sequence: 7n });
  assert.deepEqual(result, EMPTY_PATCH);
  assert.equal(request.url, "https://rei.test/_oweb");
  assert.equal(request.options.method, "POST");
  assert.equal(request.options.credentials, "same-origin");
  assert.equal(request.options.mode, "same-origin");
  assert.equal(request.options.redirect, "error");
  assert.equal(request.options.cache, "no-store");
  assert.equal(request.options.referrerPolicy, "same-origin");
  assert.equal(request.options.headers.Accept, OWEB_MIME_TYPE);
  assert.equal(request.options.headers["Content-Type"], OWEB_MIME_TYPE);
  assert.equal(request.options.headers["X-OWeb-Sequence"], "7");
  assert.equal(timers.length, 1);
  assert.equal(timers[0].delay, 15_000);
  assert.equal(timers[0].cancelled, true,
    "the request deadline is cleared after a successful response");
});

test("HTTP transport accepts a sequenced no-content response", async () => {
  const transport = new OWebHTTPTransport("/_oweb", {
    baseURL: "https://rei.test/",
    fetch: async () => new Response(null, {
      status: 204,
      headers: { "x-oweb-sequence": "1" },
    }),
  });
  assert.equal(await transport.exchange(Uint8Array.of(1), { sequence: 1n }), null);
});

test("HTTP transport aborts a request at its bounded deadline", async () => {
  let requestSignal;
  const timers = [];
  const caller = new AbortController();
  const transport = new OWebHTTPTransport("/_oweb", {
    baseURL: "https://rei.test/",
    requestTimeoutMilliseconds: 25,
    setTimeout(callback, delay) {
      const timer = { callback, delay, cancelled: false };
      timers.push(timer);
      return timer;
    },
    clearTimeout(timer) {
      timer.cancelled = true;
    },
    fetch: async (_url, options) => {
      requestSignal = options.signal;
      return new Promise((_resolve, reject) => {
        options.signal.addEventListener("abort", () => {
          reject(options.signal.reason);
        }, { once: true });
      });
    },
  });

  const exchange = transport.exchange(Uint8Array.of(1), {
    sequence: 1n,
    signal: caller.signal,
  });
  await Promise.resolve();
  assert.equal(timers.length, 1);
  assert.equal(timers[0].delay, 25);
  assert.equal(requestSignal.aborted, false);
  timers[0].callback();

  await assert.rejects(exchange, runtimeCode("request-timeout"));
  assert.equal(requestSignal.aborted, true,
    "the request-scoped signal aborts the underlying fetch");
  assert.equal(caller.signal.aborted, false,
    "a transport timeout never aborts the caller-owned signal");
  assert.equal(timers[0].cancelled, true);
});

test("HTTP transport rejects cross-origin endpoints and response confusion", async () => {
  assert.throws(() => new OWebHTTPTransport("https://other.test/_oweb", {
    baseURL: "https://rei.test/",
    fetch: async () => undefined,
  }), runtimeCode("cross-origin-endpoint"));

  const wrongSequence = new OWebHTTPTransport("/_oweb", {
    baseURL: "https://rei.test/",
    fetch: async () => new Response(EMPTY_PATCH, {
      status: 200,
      headers: {
        "content-type": OWEB_MIME_TYPE,
        "x-oweb-sequence": "8",
      },
    }),
  });
  await assert.rejects(
    wrongSequence.exchange(Uint8Array.of(1), { sequence: 7n }),
    runtimeCode("sequence-mismatch"),
  );

  const wrongType = new OWebHTTPTransport("/_oweb", {
    baseURL: "https://rei.test/",
    fetch: async () => new Response(EMPTY_PATCH, {
      status: 200,
      headers: {
        "content-type": "application/octet-stream",
        "x-oweb-sequence": "1",
      },
    }),
  });
  await assert.rejects(
    wrongType.exchange(Uint8Array.of(1), { sequence: 1n }),
    runtimeCode("invalid-content-type"),
  );
});

test("HTTP transport enforces declared and streamed response caps", async () => {
  const declared = new OWebHTTPTransport("/_oweb", {
    baseURL: "https://rei.test/",
    fetch: async () => new Response(EMPTY_PATCH, {
      status: 200,
      headers: {
        "content-type": OWEB_MIME_TYPE,
        "content-length": String(OWebLimits.FRAME_BYTES + 1),
        "x-oweb-sequence": "1",
      },
    }),
  });
  await assert.rejects(
    declared.exchange(Uint8Array.of(1), { sequence: 1n }),
    runtimeCode("response-too-large"),
  );

  const stream = new ReadableStream({
    start(controller) {
      controller.enqueue(new Uint8Array(OWebLimits.FRAME_BYTES));
      controller.enqueue(Uint8Array.of(1));
      controller.close();
    },
  });
  const streamed = new OWebHTTPTransport("/_oweb", {
    baseURL: "https://rei.test/",
    fetch: async () => new Response(stream, {
      status: 200,
      headers: {
        "content-type": OWEB_MIME_TYPE,
        "x-oweb-sequence": "1",
      },
    }),
  });
  await assert.rejects(
    streamed.exchange(Uint8Array.of(1), { sequence: 1n }),
    runtimeCode("response-too-large"),
  );
});

test("event projection includes only finite scalar allowlisted values", () => {
  const target = { value: "hello" };
  assert.deepEqual(collectEventFields({
    target,
    altKey: false,
    clientX: 12.5,
    clientY: Number.NaN,
    code: "Enter",
    data: null,
    extra: "secret",
  }), {
    altKey: false,
    clientX: 12.5,
    code: "Enter",
    data: null,
    value: "hello",
  });
});
