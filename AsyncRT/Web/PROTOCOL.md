# OWeb binary wire protocol v1

`AsyncRT.Web` includes a transport-independent codec for OWeb's browser boundary. It
does not execute selectors, look up components, or authorize DOM identifiers.
Those checks belong to the session and compiled-layout layers. The codec does
enforce a canonical representation and hard allocation/count limits before
returning a frame.

## Envelope

Every frame is:

| Field | Encoding |
| --- | --- |
| Magic | bytes `4f 57 45 42` (`OWEB`) |
| Version | byte `01` |
| Frame type | one byte from the table below |
| Body length | canonical unsigned LEB128 |
| Body | exactly the declared number of bytes |

Unsigned integers use minimal unsigned LEB128, limited to ten bytes and
`uint64_t`. A string is a byte-length varint followed by strict UTF-8. Signed
integers use zigzag followed by unsigned LEB128. Doubles are finite IEEE-754
binary64 in network byte order; negative zero and non-finite encodings are
rejected so there is only one encoded zero.

The Objective-C codec treats an `OFData` input as its complete contiguous byte
buffer. All framing and size limits therefore use `count * itemSize`, not the
item count alone; grouped `OFData` values with `itemSize > 1` decode with the
same semantics as byte-sized data.

There is no transport sequence in this envelope. An HTTP transport may put a
sequence in `X-OWeb-Sequence`; other transports may choose an equivalent. It
must not change the canonical payload bytes.

## Frames and ownership

| Type | Name | Direction | Body |
| ---: | --- | --- | --- |
| 1 | Patch | server to browser | instance ID, operation count, operations |
| 2 | Event | browser to server | instance ID, opaque action ID, target ID, sorted fields |
| 3 | Mount | browser to server | instance ID, component tag, sorted full attribute snapshot |
| 4 | Detach | browser to server | instance ID |

All IDs are nonzero unsigned 64-bit integers. The browser generates an opaque
instance ID. The first Mount claims it within one authenticated server session.
A repeated Mount from the same session with the same instance ID and component
tag is an idempotent full attribute-snapshot replacement; this supports
batched `attributeChangedCallback` delivery and transient reconnects. The
session rejects the same ID with a different component tag. Detach releases an
instance only after final teardown. A browser runtime should defer Detach to a
microtask and cancel it if the element reconnects, because custom-element
connection callbacks may occur more than once.

Event action IDs are per-render capabilities. Objective-C selector names are
kept in the server's compiled definition and never sent to, or accepted from,
the browser.

## Patch bytecodes

| Opcode | Operation | Operands |
| ---: | --- | --- |
| 1 | SetText | element ID, string |
| 2 | SetAttribute | element ID, allowed name, string |
| 3 | RemoveAttribute | element ID, allowed name |
| 4 | SetProperty | element ID, allowed name, typed scalar |
| 5 | Focus | element ID |
| 6 | Batch | child count, recursively encoded operations |
| 7 | CloneTemplate | compiler template ID, parent ID, new keyed node ID |
| 8 | RemoveNode | keyed node ID |
| 9 | MoveNode | keyed node ID, parent ID, before-node ID (`0` appends) |

There is no raw HTML, script, style, URL, or generic property opcode. Clone is
limited by the session to templates declared by the compiled component layout.
The protocol rejects routing metadata under `data-oweb-*`, event attributes,
and unsafe properties such as `innerHTML`. The browser interpreter must repeat
these checks rather than trusting the peer.

Value tags are `0` null, `1` false, `2` true, `3` signed integer, `4` unsigned
integer, `5` double, and `6` string. Event fields are restricted to the
allowlist in `OWebWireCodec`; mount maps and event maps are strictly sorted and
cannot contain duplicate keys.

## Limits

- Frame: 1 MiB
- String: 64 KiB of UTF-8
- Patch operations: 4096 total, including nested operations
- Batch depth: 8
- Event fields: 32
- Mount attributes: 64

The decoder rejects bad magic/version/type, truncation, trailing bytes,
overflowing or non-minimal varints, invalid UTF-8, unknown opcodes/value tags,
noncanonical maps, zero capabilities, and all limit violations.
