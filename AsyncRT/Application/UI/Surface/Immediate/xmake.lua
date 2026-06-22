target("AsyncRTApplicationUI", function ()
    set_kind(get_config("kind") == "shared" and "shared" or "static")

    local include_headless = is_mode("test") or has_config("asyncrt-test-access")
    local use_cairo_x11 = (not is_plat("macosx")) or has_config("asyncrt-ui-x11")

    add_deps("AsyncRTApplicationUIBase", { public = true })
    add_includedirs("../../../..", { public = true })
    add_headerfiles("../../../(UI.h)")
    add_headerfiles("(**.h)", { prefixdir = "AsyncRT/Application/UI/Surface/Immediate" })
    add_files(
        "*.m",
        "Internal/*.m",
        "ClayRuntime.c"
    )

    if include_headless then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end

    if use_cairo_x11 or include_headless then
        add_files("Platform/Cairo/RenderSupport.m")
    else
        add_files("Platform/CoreGraphics/RenderSupport.m")
    end

    asyncrt_application_ui_add_window_backend(include_headless, use_cairo_x11)
end)
