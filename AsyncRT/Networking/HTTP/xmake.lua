target("AsyncRTNetworkingHTTP", function ()
    set_kind(get_config("kind") == "shared" and "shared" or "static")
    add_deps("AsyncRTCore", { public = true })
    add_includedirs("../../..", { public = true })
    add_headerfiles("../(HTTP.h)")
    add_headerfiles("*.h", {prefixdir = "AsyncRT/Networking/HTTP"})
    add_files("*.m")

    if is_mode("test") or has_config("asyncrt-test-access") then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end
end)
