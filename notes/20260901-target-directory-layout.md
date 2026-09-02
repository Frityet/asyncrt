# Per-target source layout

Starting commit: `4ee737f51b32082c907f7eeb9f5118748e6b80bc`

Every AsyncRT library, executable, and test target now has one owning directory
with its `xmake.lua` and a `src/` directory. Files outside actual target
directories are aggregator build scripts or non-source inputs such as OCGen's
verification fixtures.

Public headers are flat within each target's `src/` include root. Consumer
imports identify the dependency through its target and use these spellings:

- `<Common.h>` and other Common headers
- `<AsyncTask.h>` and other Core headers
- `<OFData+AsyncIO.h>` and other IO headers
- `<Schema.h>` for the extracted schema support library

The install mapping strips the target-local `src/` prefix, installing these
headers flat in the include prefix. Core owns the vendored `<minicoro.h>` header
under its own source tree.

The standalone project selects the Homebrew LLVM toolchain on macOS and falls
back to the generic Clang toolchain elsewhere. Verification results and any
remaining exceptions are appended after the build and test pass.

## Verification

Homebrew Clang 23.1.0 built every target in debug mode, including all 1,083
generated CodeGen Clang implementation files, the extracted OCGen schema
library, both tool executables, the example, and every test binary.
`compile_commands.json` contains 1,108 entries; all invoke
`/opt/homebrew/opt/llvm/bin/clang`, all reference the new `src/` paths, and all
carry the ObjFW literal-compatibility flags. Installing Common, Core, IO, and
the schema library into a temporary prefix produced the expected flat headers
under `include/` and four archives under `lib/`.

The six primary test targets pass (43 ObjFWTest methods total): Common, LINQ,
AsyncTask, AsyncExecutor, Coroutine, and IO. The Coroutine test now uses the
ObjFWTest-provided application entry point instead of defining a conflicting
second `main`.

The OCGen schema suite runs nine methods: eight pass, including both live
Homebrew Clang AST-dump validation methods after replacing stale `clang-22`
lookups with `/opt/homebrew/opt/llvm/bin/clang`. Its one failing generation
assertion is demonstrably present at the starting commit and unrelated to this
layout: `Tools/OCGen/src/Schema+ObjectiveCGeneration.m:521-524` returns only
`readonly, nonatomic`, while
`Tests/Tools/OCGen/SchemaTests.m:228-234` expects generated `copy` and `retain`
attributes. Release mode also retains the starting commit's direct-method
override diagnostic because `Tools/OCGen/src/Schema.h:146` and `:245` both
declare `+fromJSONObject:` in direct-member class hierarchies. Debug mode
disables direct dispatch for tests and builds those targets successfully.
