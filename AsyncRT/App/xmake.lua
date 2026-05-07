target("AsyncRTAppSupport", function ()
    set_kind("static")
    add_deps("AsyncRTUI", { public = true })
    add_includedirs("src", { public = true })
    add_files("src/AsyncHTTPClientBridge.m", "src/Booru.m", "src/Gelbooru.m", "src/Realbooru.m")

    if is_mode("test") or has_config("asyncrt-test-access") then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end
end)

target("App", function ()
    set_kind("binary")
    add_deps("AsyncRTAppSupport")
    if is_plat("macosx") then
        add_ldflags("-ObjC", {force = true})
    end
    add_files("src/main.m",
              "src/ITerm2ImageGallery.m",
              "src/TerminalLoadingView.m")
end)
