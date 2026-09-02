target("AsyncRT.Tests.Web", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/web")
    add_deps("AsyncRT.Web")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("src/*.m")

    on_load(function (target)
        target:add("tests", "AsyncRTWebTests", {
            group = "web",
            run_timeout = 20000
        })
    end)
end)
