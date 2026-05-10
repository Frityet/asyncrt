target("Utilities", function ()
    set_kind("static")
    add_includedirs("src", { public = true })
    add_headerfiles("src/*.h")
    add_files("src/*.m")

    if is_mode("test") or has_config("asyncrt-test-access") then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end
end)
