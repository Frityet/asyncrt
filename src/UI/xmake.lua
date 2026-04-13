local common = asyncrt_build
local macos_x11 = common.macos_x11

local function configure_ui_target(async_target)
    add_deps(async_target, { public = true })
    add_packages("cairo", { public = true })

    add_files("*.m")
    add_files("Backend/AUIWindow.m", "Backend/AUIWindowOptions.m", "Backend/AUICairoRenderSupport.m")
    add_files("Backend/Window/AUIHeadlessWindow.m")
    add_files("Components/**.m")

    if is_plat("macosx") then
        add_defines("AUI_HAS_CORE_GRAPHICS_WINDOW=0", { public = true })
        add_defines("AUI_HAS_CAIRO_X11_WINDOW=" .. (macos_x11 ~= nil and "1" or "0"), { public = true })
        add_frameworks("CoreFoundation")

        if macos_x11 ~= nil then
            add_sysincludedirs(macos_x11.includedir)
            add_linkdirs(macos_x11.libdir)
            add_syslinks("X11")
            add_files("Backend/Window/AUICairoX11Window.m")
        end
    end

    if is_plat("linux") then
        add_defines("AUI_HAS_CAIRO_X11_WINDOW=1", { public = true })
        add_syslinks("X11")
        add_files("Backend/Window/AUICairoX11Window.m")
    end

    add_files("ClayRuntime.c")
end

target("AsyncRTUI")
    set_kind("static")
    configure_ui_target("AsyncRT")
    after_config(function (target)
        common.strip_default_macos_frameworks(target)
    end)

target("AsyncRTUITest")
    set_default(false)
    set_kind("static")
    add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    configure_ui_target("AsyncRTTest")
    after_config(function (target)
        common.strip_default_macos_frameworks(target)
    end)
