# Objective-C literal normalization

Starting commit: `4ee737f51b32082c907f7eeb9f5118748e6b80bc`

AsyncRT's project-owned Objective-C sources were audited for immutable ObjFW
factory calls that have exact literal equivalents. The sweep converted four
immutable array factories and eight `numberWithInt:` calls. Numeric expressions
retain explicit `int` casts so Clang selects the same ObjFW boxed-number factory.

The standalone build now applies the same macOS-only Clang 23 literal-lowering
policy as its Rei and OWeb consumers. Without it, constant and empty literals can
resolve to Foundation-owned objects rather than ObjFW factories; the resulting
mixed object graphs are observably incorrect even though they compile.

Intentional non-literal constructions remain where no exact literal exists,
including dynamic C-string conversion, formatted strings, immutable copies from
existing arrays, and all mutable collection factories.

Verification used Homebrew Clang 23.1.0:

- Release builds passed for `AsyncRT.Common` and
  `AsyncRT.Tests.Common.LINQ`.
- Release runtime tests passed: Common 3, LINQ 3, AsyncTask 10,
  AsyncExecutor 2, and IO 4 (22 ObjFWTest methods total).
- A Clang AST check confirmed every converted number expression has type
  `OFNumber *` and selector `numberWithInt:`, and every converted collection
  has type `OFArray *`.
- The eligible-factory audit is clean after the rewrite.

The pre-existing release OCGen generator direct-method override diagnostic
remains outside this literal sweep. The target-layout follow-up removed the
Coroutine test's redundant custom application delegate and now runs it through
the standard ObjFWTest entry point; all 21 Coroutine methods pass.
