target("AsyncRTUI", function ()
    set_kind("static")

    local include_headless = is_mode("test") or has_config("asyncrt-test-access")
    local use_cairo_x11 = (not is_plat("macosx")) or has_config("asyncrt-ui-x11")

    add_deps("AsyncRT", { public = true })
    add_includedirs("src", "../extern", { public = true })

    add_files("src/*.m")
    add_files("src/Internal/*.m")
    add_files("src/Backend/AUIWindow.m")
    add_files("src/ClayRuntime.c")

    if include_headless then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end

    if use_cairo_x11 or include_headless then
        add_packages("cairo", { public = true })
        add_files(
            "src/Backend/AUICairoRenderSupport.m",
            "src/Backend/Window/AUIHeadlessWindow.m"
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
            "AUI_HAS_CORE_GRAPHICS_WINDOW=0",
            "AUI_HAS_CAIRO_X11_WINDOW=1",
            { public = true }
        )
        add_syslinks("X11", { public = true })
        add_files("src/Backend/Window/AUICairoX11Window.m")
    else
        add_defines(
            "AUI_HAS_CORE_GRAPHICS_WINDOW=1",
            "AUI_HAS_CAIRO_X11_WINDOW=0",
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
            "src/Backend/AUICoreGraphicsRenderSupport.m",
            "src/Backend/Window/AUICoreGraphicsWindow.m"
        )
    end
end)
