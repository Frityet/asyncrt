target("AsyncRT.Tests.Core.AsyncExecutor", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/core")
    add_deps("AsyncRT.Core", "AsyncRT.Common")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("src/AsyncExecutorTests.m")

    on_load(function (target)
        target:add("tests", "AsyncExecutorTests", {
            group = "core/executor",
            run_timeout = 5000
        })
    end)
end)
