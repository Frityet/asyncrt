# AsyncRT.Web integration

- Starting commit: `2ce64e1007d7eb26b8ec5cf6711b234bc2b38218`
- Source checkpoint: OWeb `5a7906ce3ed0c83b072b03753629748fa7ca05a0`
- Folded the reviewed OWeb framework into the first-class `AsyncRT.Web`
  target instead of retaining a nested project or submodule.
- Co-located public headers, implementations, and browser modules in
  `AsyncRT/Web/src`; the browser modules install together under
  `share/asyncrt/web/browser`.
- Rehomed Objective-C, protocol, browser, and benchmark coverage into the
  standard one-target-per-directory AsyncRT layout.
- Homebrew LLVM 23 release and strict leak-detecting ASan runs pass all 35 core and 14
  protocol assertions; Node passes all 26 browser tests.
- The installed target contains eight public headers, `libAsyncRT.Web.a`, and
  exactly four browser modules in `share/asyncrt/web/browser`; the private
  reflection header is not installed.
- The deterministic benchmark remains 301 bytes for the binary frame versus
  1,710 bytes for JSON (17.6%).
- The extra-strict macOS `ASAN_OPTIONS=detect_leaks=1` mutation corpus exposed
  an allocation-order bug in Detach decoding: Clang could allocate the frame
  before a truncated identifier threw. Reading and validating the identifier
  before allocation closed the leak. Per-iteration autorelease pools keep the
  corpus bounded, and the strict leak run now passes all 14 protocol tests.
- Public ObjFW byte boundaries now measure `OFData.count * itemSize`. This
  closes a cap bypass and truncated-prefix decode for grouped data, while the
  reader now points at its immutable copy rather than the caller's storage.
- Replay eviction protects every currently mounted instance from unrelated
  invalid-request churn. If the cache is fully occupied by live instances, a
  new unowned failure is left uncached instead of weakening response-loss
  recovery for state-changing component actions.
- Browser component identifiers are now claimed only on connection and released
  after final Detach settles, including failed delivery. A component-local
  retired-ID exclusion still guarantees a reconnect does not reuse its prior
  lifetime identifier without retaining a registration-wide tombstone.
- Browser exchanges have a configurable 15-second per-attempt response
  deadline. Timeout aborts only a derived request signal and receives the same
  single exact-frame/exact-sequence retry as response-loss failures, so the
  terminal bound is two configured timeout periods and session replay remains
  safe for state-changing actions.
- The ObjFW adapter rejects a canonical oversized `Content-Length` before body
  reads. It remains deliberately single-threaded: ObjFW 1.5.7's public
  multi-threaded server deadlocks during `stop`, and its public request-body
  stream exposes no reliable deadline. Non-loopback deployments therefore need
  trusted ingress for concurrency and connection/header/body deadlines.
- A clean Homebrew LLVM 23 debug build completed every AsyncRT target,
  including all generated Clang bindings. Common, LINQ, Core, IO, Web, and Web
  Protocol passed 92 tests in total. The OCGen schema suite remains 8/9 with
  its documented starting-commit generator expectation mismatch; release
  all-target mode likewise retains the documented pre-existing direct-method
  override diagnostic in the Schema hierarchy. Neither is in the Web change.
