target("AsyncRT.Tests.Core.Coroutine", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/core")
    add_deps("AsyncRT.Core", "AsyncRT.Common")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("src/CoroutineTests.m", {
        mflags = { "-fno-objc-arc" }
    })

    on_load(function (target)
        target:add("tests", "CoroutineTests", {
            group = "core/coroutine",
            run_timeout = 5000
        })
    end)
end)
