target("async-runtime-benchmarks", function ()
    set_default(false)
    set_kind("binary")
    set_group("tools")
    add_deps("AsyncRTApplicationCore")
    set_symbols("debug")
    add_files("AsyncRuntimeBenchmarks.m")
end)

task("check")
    set_menu {
        usage = "xmake check [options]",
        description = "Configure a test-access build in a separate output directory, build the test targets, and run the suite.",
        options = {
            {'o', "build-dir", "kv", "build-test", "Test build output directory."}
        }
    }
    on_run(function ()
        import("core.base.option")
        import("core.base.task")

        local builddir = option.get("build-dir")

        task.run("config", {
            clean = true,
            mode = "test",
            builddir = builddir,
            ["asyncrt-test-access"] = true
        })
        task.run("build", {group = "tests"})
        task.run("test")
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
        import("coverage", {rootdir = os.scriptdir()})

        coverage.main {
            build_dir = option.get("build-dir"),
            minimum = option.get("minimum"),
            llvm_cov = option.get("llvm-cov"),
            llvm_profdata = option.get("llvm-profdata")
        }
    end)
