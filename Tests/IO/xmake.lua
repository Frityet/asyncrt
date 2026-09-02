target("AsyncRT.Tests.IO", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/io")
    add_deps("AsyncRT.IO", "AsyncRT.Core", "AsyncRT.Common")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("src/OFDataAsyncIOTests.m", {
        mflags = { "-fno-objc-arc" }
    })

    on_load(function (target)
        target:add("tests", "OFDataAsyncIOTests", {
            group = "io/ofdata",
            run_timeout = 5000
        })
    end)
end)
