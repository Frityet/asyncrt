package("webkitgtk")
    set_homepage("https://webkitgtk.org/")
    set_description("WebKitGTK bindings for GTK 4 applications.")
    set_license("LGPL-2.1")

    if is_plat("linux") then
        add_extsources("pkgconfig::webkitgtk-6.0", "apt::libwebkitgtk-6.0-dev", "pacman::webkitgtk-6.0")
    end

    on_fetch("linux", function (package, opt)
        if opt.system then
            return package:find_package("pkgconfig::webkitgtk-6.0", opt)
        end
    end)

    on_test(function (package)
        assert(package:has_cfuncs("webkit_web_view_new", {includes = "webkit/webkit.h"}))
    end)
