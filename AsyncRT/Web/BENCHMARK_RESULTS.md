# Wire codec benchmark checkpoint

Measured locally on 2026-09-01 on Apple Silicon macOS with Homebrew Clang
23.1.0, ObjFW 1.5.7, and the release configuration. The benchmark source is
`Benchmarks/Web/Protocol/src/OWebWireProtocolBenchmark.m`.

The fixture is one patch with 25 top-level operations and three operations in
a nested batch. Each process warms every path for 512 iterations and then runs
20,000 iterations per path. Five fresh process samples produced:

| Sample | Binary encode ns/op | Binary decode ns/op | JSON encode ns/op | JSON decode ns/op |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 9,481.33 | 11,908.8 | 170,856 | 40,618.6 |
| 2 | 9,781.38 | 12,413.2 | 176,906 | 39,045.8 |
| 3 | 9,615.54 | 11,899.3 | 173,608 | 39,742.6 |
| 4 | 9,410.61 | 11,722.5 | 175,810 | 40,654.2 |
| 5 | 9,613.85 | 12,065.6 | 173,663 | 39,815.0 |
| Median | **9,613.85** | **11,908.8** | **173,663** | **39,815.0** |

The canonical binary payload is 301 bytes. ObjFW's sorted, compact JSON for
the equivalent explicit operation structure is 1,710 UTF-8 bytes. Binary is
17.6023% of that JSON size for this fixture. At the medians above, binary
encoding took 5.54% of the JSON time and binary decoding took 29.91% of the
JSON time.

These figures are a narrow implementation checkpoint, not a browser or
end-to-end transport claim. JSON uses descriptive keys while the protocol uses
numeric opcodes, so the size advantage is expected. Binary decode constructs
typed immutable frame/operation objects; JSON decode returns generic ObjFW
containers. The benchmark does not include JavaScript decoding, HTTP framing,
compression, network latency, session authorization, DOM work, or a string
table. Re-run it after any format, ObjFW, compiler, or runtime change.
