local function add_late_cairo_x11_links()
    if not is_plat("linux") then
        return
    end

    -- The UI module is usually a static archive in local builds. Repeat Cairo
    -- and X11 package links from this UI target so dependents resolve backend
    -- symbols after the AsyncRTApplicationUI archive is seen by the linker.
    add_syslinks(
        "cairo",
        "cairo-script-interpreter",
        "png",
        "pixman-1",
        "fontconfig",
        "freetype",
        "z",
        "expat",
        "Xrender",
        "Xext",
        "X11-xcb",
        "xcb",
        "xcb-composite",
        "xcb-damage",
        "xcb-dbe",
        "xcb-dpms",
        "xcb-dri2",
        "xcb-dri3",
        "xcb-present",
        "xcb-glx",
        "xcb-randr",
        "xcb-record",
        "xcb-render",
        "xcb-res",
        "xcb-screensaver",
        "xcb-shape",
        "xcb-shm",
        "xcb-sync",
        "xcb-xevie",
        "xcb-xf86dri",
        "xcb-xfixes",
        "xcb-xinerama",
        "xcb-xinput",
        "xcb-xkb",
        "xcb-xtest",
        "xcb-xv",
        "xcb-xvmc",
        "xcb-ge",
        "Xau",
        "Xdmcp",
        "X11",
        "m",
        { public = true }
    )
end

target("AsyncRTApplicationUI", function ()
    set_kind(get_config("kind") == "shared" and "shared" or "static")

    local include_headless = is_mode("test") or has_config("asyncrt-test-access")
    local use_cairo_x11 = (not is_plat("macosx")) or has_config("asyncrt-ui-x11")

    add_deps("AsyncRTApplicationCore", { public = true })
    add_includedirs("../../..", { public = true })
    add_headerfiles("../../(UI.h)")
    add_headerfiles("*.h", {prefixdir = "AsyncRT/Application/UI"})
    add_headerfiles("Backend/*.h", {prefixdir = "AsyncRT/Application/UI/Backend"})
    add_headerfiles("Backend/Window/*.h", {prefixdir = "AsyncRT/Application/UI/Backend/Window"})
    add_headerfiles("Internal/*.h", {prefixdir = "AsyncRT/Application/UI/Internal"})

    add_files("*.m")
    add_files("Internal/*.m")
    add_files("Backend/AsyncUIWindow.m")
    add_files("ClayRuntime.c")

    if include_headless then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end

    if use_cairo_x11 or include_headless then
        add_packages("cairo", { public = true })
        add_late_cairo_x11_links()
        add_files(
            "Backend/AsyncUICairoRenderSupport.m",
            "Backend/Window/AsyncUIHeadlessWindow.m"
        )
    end

    if use_cairo_x11 then
        if is_plat("macosx") then
            local x11_root = "/opt/X11"

            if not os.isdir(path.join(x11_root, "include", "X11")) or not os.isdir(path.join(x11_root, "lib")) then
                raise("asyncrt_ui_x11 requires XQuartz headers and libraries in /opt/X11")
            end

            add_includedirs(path.join(x11_root, "include"))
            add_linkdirs(path.join(x11_root, "lib"), { public = true })
        end

        add_defines(
            "AsyncUI_HAS_CORE_GRAPHICS_WINDOW=0",
            "AsyncUI_HAS_CAIRO_X11_WINDOW=1",
            { public = true }
        )
        add_syslinks("X11", { public = true })
        add_files("Backend/Window/AsyncUICairoX11Window.m")
    else
        add_defines(
            "AsyncUI_HAS_CORE_GRAPHICS_WINDOW=1",
            "AsyncUI_HAS_CAIRO_X11_WINDOW=0",
            { public = true }
        )
        add_links("objfwbridge", { public = true })
        add_frameworks(
            "Foundation",
            "AppKit",
            "Carbon",
            "CoreGraphics",
            "CoreText",
            "ImageIO",
            "QuartzCore",
            { public = true }
        )
        add_files(
            "Backend/AsyncUICoreGraphicsRenderSupport.m",
            "Backend/Window/AsyncUICoreGraphicsWindow.m"
        )
    end
end)
