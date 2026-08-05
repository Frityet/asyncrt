target("AsyncRT.Tests.Common", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/common")
    add_deps("AsyncRT.Common")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("CommonTests.m")

    on_load(function (target)
        target:add("tests", "CommonTests", {
            group = "common",
            run_timeout = 5000
        })
    end)
end)

target("AsyncRT.Tests.Common.LINQ", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/common/linq")
    add_deps("AsyncRT.Common")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("OFArrayLINQTests.m")

    on_load(function (target)
        target:add("tests", "OFArrayLINQTests", {
            group = "common/linq",
            run_timeout = 5000
        })
    end)
end)
