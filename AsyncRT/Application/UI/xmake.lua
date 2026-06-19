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

target("AsyncRTApplicationUIBase", function ()
    set_kind(get_config("kind") == "shared" and "shared" or "static")

    add_deps("AsyncRTApplicationCore", { public = true })
    add_includedirs("../../..", { public = true })
    add_headerfiles("*.h", { prefixdir = "AsyncRT/Application/UI" })
    add_headerfiles("Window/(Configuration.h)", { prefixdir = "AsyncRT/Application/UI/Window" })
    add_files("Application.m", "Window/Configuration.m")
end)

if has_config("asyncrt-ui") then
    target("AsyncRTApplicationUI", function ()
        set_kind(get_config("kind") == "shared" and "shared" or "static")

        local include_headless = is_mode("test") or has_config("asyncrt-test-access")
        local use_cairo_x11 = (not is_plat("macosx")) or has_config("asyncrt-ui-x11")

        add_deps("AsyncRTApplicationUIBase", { public = true })
        add_includedirs("../../..", { public = true })
        add_headerfiles("../../(UI.h)")
        add_headerfiles("Surface/Immediate/(**.h)", { prefixdir = "AsyncRT/Application/UI/Surface/Immediate" })
        add_headerfiles("Window/(Input.h)", { prefixdir = "AsyncRT/Application/UI/Window" })
        add_headerfiles("Window/(Window.h)", { prefixdir = "AsyncRT/Application/UI/Window" })
        add_headerfiles("Window/(Windowing.h)", { prefixdir = "AsyncRT/Application/UI/Window" })
        add_headerfiles("Window/Platform/Headless/(Window.h)", { prefixdir = "AsyncRT/Application/UI/Window/Platform/Headless" })

        add_files(
            "Surface/Immediate/*.m",
            "Surface/Immediate/Internal/*.m",
            "Surface/Immediate/ClayRuntime.c",
            "Window/Window.m"
        )

        if include_headless then
            add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
        end

        if use_cairo_x11 or include_headless then
            add_packages("cairo", { public = true })
            add_late_cairo_x11_links()
            add_files(
                "Surface/Immediate/Platform/Cairo/RenderSupport.m",
                "Window/Platform/Headless/Window.m"
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
                "AsyncUI_HAS_COCOA_WINDOW=0",
                "AsyncUI_HAS_X11_WINDOW=1",
                { public = true }
            )
            add_syslinks("X11", { public = true })
            add_headerfiles("Window/Platform/X11/(Window.h)", { prefixdir = "AsyncRT/Application/UI/Window/Platform/X11" })
            add_files("Window/Platform/X11/Window.m")
        else
            add_defines(
                "AsyncUI_HAS_COCOA_WINDOW=1",
                "AsyncUI_HAS_X11_WINDOW=0",
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
            add_headerfiles("Window/Platform/Cocoa/(Window.h)", { prefixdir = "AsyncRT/Application/UI/Window/Platform/Cocoa" })
            add_files(
                "Surface/Immediate/Platform/CoreGraphics/RenderSupport.m",
                "Window/Platform/Cocoa/Window.m"
            )
        end
    end)
end

if has_config("asyncrt-webui") then
    target("AsyncRTWebUI", function ()
        set_kind(get_config("kind") == "shared" and "shared" or "static")

        add_deps("AsyncRTApplicationUIBase", "AsyncRTNetworkingHTTP", { public = true })
        add_includedirs("../../..", { public = true })
        add_headerfiles("Surface/Web/(**.h)", { prefixdir = "AsyncRT/Application/UI/Surface/Web" })
        add_files("Surface/Web/*.m", "Surface/Web/Platform/WKWebKit/View.m")

        if is_plat("macosx") then
            add_links("objfwbridge", { public = true })
            add_frameworks("WebKit", "AppKit", "Foundation", { public = true })
        end
    end)
end
