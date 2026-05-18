target("AsyncRTExampleUISupport", function ()
    set_kind(get_config("kind") == "shared" and "shared" or "static")
    add_deps("AsyncRTApplicationUI", "AsyncRTNetworkingHTTP", "AsyncRTApplicationTerminal", { public = true })
    add_includedirs("../..", "src", { public = true })
    add_headerfiles("src/*.h", {install = false})
    add_files("src/Booru.m", "src/Gelbooru.m", "src/Realbooru.m")

    if is_mode("test") or has_config("asyncrt-test-access") then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end
end)

target("AsyncRTExampleUI", function ()
    set_kind("binary")
    set_group("examples")
    add_deps("AsyncRTExampleUISupport")
    if is_plat("macosx") then
        add_ldflags("-ObjC", {force = true})
    end
    add_files("src/main.m",
              "src/ITerm2ImageGallery.m",
              "src/TerminalLoadingView.m")
end)
