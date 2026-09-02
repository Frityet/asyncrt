target("AsyncRT.Tests.Web.Protocol", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/web/protocol")
    add_deps("AsyncRT.Web")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("src/*.m")

    on_load(function (target)
        target:add("tests", "AsyncRTWebProtocolTests", {
            group = "web/protocol",
            run_timeout = 15000
        })
    end)
end)
