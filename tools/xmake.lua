local common = asyncrt_build

target("async-runtime-benchmarks")
    set_kind("binary")
    set_group("tools")
    add_deps("AsyncRT")
    set_pmheader("../src/Utilities/common.h")
    set_symbols("debug")
    add_files("AsyncRuntimeBenchmarks.m")
    after_config(function (target)
        common.strip_default_macos_frameworks(target)
    end)

task("coverage")
    set_menu {
        usage = "xmake coverage [options]",
        description = "Build the coverage-mode test binary, run the full suite, and report scoped library coverage.",
        options = {
            {'o', "build-dir", "kv", "build-coverage", "Coverage build output directory."},
            {'m', "minimum", "kv", "90", "Minimum required total line coverage percentage."},
            {nil, "llvm-cov", "kv", nil, "Path to llvm-cov."},
            {nil, "llvm-profdata", "kv", nil, "Path to llvm-profdata."}
        }
    }
    on_run(function ()
        import("core.base.option")
        import("tools.coverage")

        coverage.main {
            build_dir = option.get("build-dir"),
            minimum = option.get("minimum"),
            llvm_cov = option.get("llvm-cov"),
            llvm_profdata = option.get("llvm-profdata")
        }
    end)
