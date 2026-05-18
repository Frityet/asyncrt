target("AsyncRTCore", function ()
    set_kind(get_config("kind") == "shared" and "shared" or "static")
    add_deps("AsyncRTCommon", { public = true })
    add_includedirs("../..", { public = true })
    add_headerfiles("../(Core.h)")
    add_headerfiles("*.h", {prefixdir = "AsyncRT/Core"})

    local coroutine_mflags = {"-fno-objc-arc"}
    if is_mode("release") then
        table.insert(coroutine_mflags, "-O0")
        table.insert(coroutine_mflags, "-fno-omit-frame-pointer")
        table.insert(coroutine_mflags, "-fno-optimize-sibling-calls")
        table.insert(coroutine_mflags, "-fno-lto")
    elseif is_mode("minsizerel") then
        table.insert(coroutine_mflags, "-Oz")
        table.insert(coroutine_mflags, "-fno-omit-frame-pointer")
        table.insert(coroutine_mflags, "-fno-optimize-sibling-calls")
        table.insert(coroutine_mflags, "-fno-lto")
        table.insert(coroutine_mflags, "-fvisibility=hidden")
        table.insert(coroutine_mflags, "-Wl,-dead_strip")
    end

    add_files("AsyncCoroutine.m", {mflags = coroutine_mflags})
    add_files("*.m|AsyncCoroutine.m")

    if is_mode("test") or has_config("asyncrt-test-access") then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end

    if is_plat("linux") then
        add_syslinks("pthread", { public = true })
    end
end)
