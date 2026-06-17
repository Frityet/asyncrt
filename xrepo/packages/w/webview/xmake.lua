package("webview")
    set_homepage("https://github.com/webview/webview")
    set_description("Tiny cross-platform webview library for C/C++.")
    set_license("MIT")

    add_urls("https://github.com/webview/webview.git")
    add_versions("0.12.0", "3ab4b5d722438fc8a13e6ca830c5e2372d19a01d")

    add_configs("webkitgtk", {
        description = "Linux WebKitGTK API/module.",
        default = "webkit2gtk-4.1",
        type = "string",
        values = {"webkit2gtk-4.1", "webkit2gtk-4.0", "webkitgtk-6.0"}
    })

    add_deps("cmake")
    if is_plat("linux") then
        add_deps("pkgconf")
    end

    local function _linux_webkitgtk_api(package)
        local webkitgtk = package:config("webkitgtk")
        if webkitgtk == "webkitgtk-6.0" then
            return "6.0", {"webkitgtk-6.0", "gtk4"}
        elseif webkitgtk == "webkit2gtk-4.1" then
            return "4.1", {"webkit2gtk-4.1", "gtk+-3.0"}
        elseif webkitgtk == "webkit2gtk-4.0" then
            return "4.0", {"webkit2gtk-4.0", "gtk+-3.0"}
        end
        raise("unsupported webview WebKitGTK module: %s", webkitgtk)
    end

    local function _add_pkgconfig_flags(package, modules)
        local function _append_modules(args)
            for _, module in ipairs(modules) do
                table.insert(args, module)
            end
            return args
        end

        local function _add_cflags(flags)
            for flag in flags:gmatch("%S+") do
                if flag:sub(1, 2) == "-I" then
                    package:add("includedirs", flag:sub(3))
                elseif flag:sub(1, 2) == "-D" then
                    package:add("defines", flag:sub(3))
                else
                    package:add("cxflags", flag)
                end
            end
        end

        local function _add_libs(flags)
            for flag in flags:gmatch("%S+") do
                if flag:sub(1, 2) == "-L" then
                    package:add("linkdirs", flag:sub(3))
                elseif flag:sub(1, 2) == "-l" then
                    -- Keep dependency libraries after libwebview for static links.
                    package:add("syslinks", flag:sub(3))
                else
                    package:add("ldflags", flag, {force = true})
                end
            end
        end

        _add_cflags(os.iorunv("pkg-config", _append_modules({"--cflags"})))
        _add_libs(os.iorunv("pkg-config", _append_modules({"--libs"})))
    end

    on_load(function (package)
        if package:config("shared") then
            package:add("defines", "WEBVIEW_SHARED")
        else
            package:add("defines", "WEBVIEW_STATIC")
        end

        if package:is_plat("windows") then
            package:add("syslinks", "advapi32", "ole32", "shell32", "shlwapi", "user32", "version")
        elseif package:is_plat("macosx") then
            package:add("frameworks", "WebKit")
            package:add("syslinks", "dl")
        elseif package:is_plat("linux") then
            local _, modules = _linux_webkitgtk_api(package)
            _add_pkgconfig_flags(package, modules)
            package:add("syslinks", "dl")
        end
    end)

    on_install("windows", "macosx", "linux", function (package)
        local configs = {
            "-DWEBVIEW_BUILD=ON",
            "-DWEBVIEW_BUILD_TESTS=OFF",
            "-DWEBVIEW_BUILD_EXAMPLES=OFF",
            "-DWEBVIEW_BUILD_DOCS=OFF",
            "-DWEBVIEW_ENABLE_CHECKS=OFF",
            "-DWEBVIEW_ENABLE_PACKAGING=OFF",
            "-DWEBVIEW_INSTALL_TARGETS=ON",
            "-DWEBVIEW_BUILD_AMALGAMATION=OFF",
            "-DWEBVIEW_BUILD_SHARED_LIBRARY=" .. (package:config("shared") and "ON" or "OFF"),
            "-DWEBVIEW_BUILD_STATIC_LIBRARY=" .. (package:config("shared") and "OFF" or "ON")
        }

        if package:is_plat("linux") then
            local api = _linux_webkitgtk_api(package)
            table.insert(configs, "-DWEBVIEW_WEBKITGTK_API=" .. api)
        elseif package:is_plat("windows") then
            table.insert(configs, "-DWEBVIEW_USE_BUILTIN_MSWEBVIEW2=ON")

            local vs_runtime = package:config("vs_runtime")
            if vs_runtime then
                table.insert(configs, "-DWEBVIEW_USE_STATIC_MSVC_RUNTIME=" ..
                    (vs_runtime:sub(1, 2) == "MT" and "ON" or "OFF"))
            end
        end

        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <webview/webview.h>
            void test() {
                (void)webview_version();
            }
        ]]}, {configs = {languages = "c++11"}}))
    end)
