local function add_cairo_backends(export_package)
    if export_package then
        add_packages("cairo", { public = true })
    else
        add_packages("cairo")
    end

    add_files("Backend/AUICairoRenderSupport.m")
    add_files("Backend/Window/AUIHeadlessWindow.m")
end

local function add_core_graphics_backend()
    add_defines("AUI_HAS_CORE_GRAPHICS_WINDOW=1", { public = true })
    add_defines("AUI_HAS_CAIRO_X11_WINDOW=0", { public = true })
    add_links("objfwbridge", { public = true })
    add_frameworks("Foundation", "AppKit", "Carbon", "CoreGraphics", "CoreText", "ImageIO", "QuartzCore", { public = true })
    add_files("Backend/AUICoreGraphicsRenderSupport.m")
    add_files("Backend/Window/AUICoreGraphicsWindow.m")
end

local function add_x11_backend()
    add_defines("AUI_HAS_CORE_GRAPHICS_WINDOW=0", { public = true })
    add_defines("AUI_HAS_CAIRO_X11_WINDOW=1", { public = true })
    add_syslinks("X11")
    add_files("Backend/Window/AUICairoX11Window.m")
end

local function configure_ui_target(async_target, options)
    add_deps(async_target, { public = true })

    add_files("*.m")
    add_files("Backend/AUIWindow.m", "Backend/AUIWindowOptions.m")
    add_files("Components/**.m")
    add_files("ClayRuntime.c")

    if is_plat("macosx") then
        add_core_graphics_backend()

        if options.include_headless then
            add_cairo_backends(options.export_cairo)
        end
        return
    end

    add_cairo_backends(true)
    add_x11_backend()
end

target("AsyncRTUI")
    set_kind("static")
    configure_ui_target("AsyncRT", {
        include_headless = false,
        export_cairo = false
    })

target("AsyncRTUITest")
    set_default(false)
    set_kind("static")
    add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    configure_ui_target("AsyncRTTest", {
        include_headless = true,
        export_cairo = true
    })
