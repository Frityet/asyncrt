
target("AsyncRT.Tools.OCGen", function()
    set_kind("binary")
    set_filename("ocgen")
    add_deps("AsyncRT.Core", "AsyncRT.Common", "AsyncRT.IO")
    add_files("src/**.m")

    on_load(function(target)
        target:add("runenvs", "ASYNC_RUNTIME_PROJECT_DIR", os.projectdir())
    end)
end)

target("AsyncRT.Tests.OCGen.Schema", function()
    set_kind("binary")
    set_default(false)
    set_group("tests/tools/ocgen")
    add_deps("AsyncRT.Common", "AsyncRT.Core", "AsyncRT.IO")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("src/Schema.m")
    add_files("src/Schema+ObjectiveCGeneration.m")
    add_files("../../Tests/Tools/OCGen/SchemaTests.m", {
        mflags = { "-fno-objc-arc" }
    })

    on_load(function(target)
        target:add("runenvs", "ASYNC_RUNTIME_PROJECT_DIR", os.projectdir())
        target:add("tests", "SchemaTests", {
            group = "tools/ocgen/schema",
            run_timeout = 60000
        })
    end)
end)
