local common = asyncrt_build

local function add_cairo_backends(export_package)
    if export_package then
        add_packages("cairo", { public = true })
    else
        add_packages("cairo")
    end

    add_files("src/Backend/AUICairoRenderSupport.m")
    add_files("src/Backend/Window/AUIHeadlessWindow.m")
end

local function add_core_graphics_backend()
    add_defines("AUI_HAS_CORE_GRAPHICS_WINDOW=1", { public = true })
    add_defines("AUI_HAS_CAIRO_X11_WINDOW=0", { public = true })
    add_links("objfwbridge", { public = true })
    add_frameworks("Foundation", "AppKit", "Carbon", "CoreGraphics", "CoreText", "ImageIO", "QuartzCore", { public = true })
    add_files("src/Backend/AUICoreGraphicsRenderSupport.m")
    add_files("src/Backend/Window/AUICoreGraphicsWindow.m")
end

local function add_x11_backend()
    add_defines("AUI_HAS_CORE_GRAPHICS_WINDOW=0", { public = true })
    add_defines("AUI_HAS_CAIRO_X11_WINDOW=1", { public = true })
    add_syslinks("X11")
    add_files("src/Backend/Window/AUICairoX11Window.m")
end

local function configure_ui_target()
    local include_headless = common.internal_test_access_enabled()

    add_deps("AsyncRT", { public = true })
    add_includedirs("src", "../extern", { public = true })

    add_files("src/*.m")
    add_files("src/Backend/AUIWindow.m", "src/Backend/AUIWindowOptions.m")
    add_files("src/Components/**.m")
    add_files("src/ClayRuntime.c")
    common.add_internal_test_access_define()

    if is_plat("macosx") then
        add_core_graphics_backend()

        if include_headless then
            add_cairo_backends(true)
        end
        return
    end

    add_cairo_backends(true)
    add_x11_backend()
end

target("AsyncRTUI")
    set_kind("static")
    configure_ui_target()
