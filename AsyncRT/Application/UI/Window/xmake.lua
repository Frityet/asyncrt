local window_dir = os.scriptdir()

function asyncrt_application_ui_add_window_backend(include_headless, use_cairo_x11)
    add_headerfiles(path.join(window_dir, "(Input.h)"), { prefixdir = "AsyncRT/Application/UI/Window" })
    add_headerfiles(path.join(window_dir, "(Window.h)"), { prefixdir = "AsyncRT/Application/UI/Window" })
    add_headerfiles(path.join(window_dir, "(Windowing.h)"), { prefixdir = "AsyncRT/Application/UI/Window" })
    add_headerfiles(path.join(window_dir, "Platform/Headless/(Window.h)"), { prefixdir = "AsyncRT/Application/UI/Window/Platform/Headless" })
    add_files(path.join(window_dir, "Window.m"))

    if use_cairo_x11 or include_headless then
        add_packages("cairo", { public = true })
        add_files(path.join(window_dir, "Platform/Headless/Window.m"))
    end

    if use_cairo_x11 then
        add_packages("libx11", { public = true })
        add_defines(
            "AsyncUI_HAS_COCOA_WINDOW=0",
            "AsyncUI_HAS_X11_WINDOW=1",
            { public = true }
        )
        add_headerfiles(path.join(window_dir, "Platform/X11/(Window.h)"), { prefixdir = "AsyncRT/Application/UI/Window/Platform/X11" })
        add_files(path.join(window_dir, "Platform/X11/Window.m"))
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
        add_headerfiles(path.join(window_dir, "Platform/Cocoa/(Window.h)"), { prefixdir = "AsyncRT/Application/UI/Window/Platform/Cocoa" })
        add_files(path.join(window_dir, "Platform/Cocoa/Window.m"))
    end
end
