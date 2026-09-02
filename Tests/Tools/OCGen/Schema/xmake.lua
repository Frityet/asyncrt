target("AsyncRT.Tests.OCGen.Schema", function()
    set_kind("binary")
    set_default(false)
    set_group("tests/tools/ocgen")
    add_deps("AsyncRT.Common", "AsyncRT.Core", "AsyncRT.IO",
        "AsyncRT.Tools.OCGen.Schema")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("src/SchemaTests.m", {
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
