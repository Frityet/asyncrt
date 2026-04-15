asyncrt_build = asyncrt_build or {}

function asyncrt_build.append_all(dst, src)
    for _, value in ipairs(src) do
        table.insert(dst, value)
    end
end

function asyncrt_build.conservative_async_mflags(extra_flags)
    local flags = {}

    if extra_flags ~= nil then
        asyncrt_build.append_all(flags, extra_flags)
    end

    -- Stack-switching and task unwinding stay stable under optimized builds
    -- only when these runtime TUs keep conservative frames and avoid LTO.
    if is_mode("release") then
        asyncrt_build.append_all(flags, {
            "-O0",
            "-fno-omit-frame-pointer",
            "-fno-optimize-sibling-calls",
            "-fno-lto"
        })
    elseif is_mode("minsizerel") then
        asyncrt_build.append_all(flags, {
            "-Oz",
            "-fno-omit-frame-pointer",
            "-fno-optimize-sibling-calls",
            "-fno-lto",
            "-fvisibility=hidden",
            "-Wl,-dead_strip" 
        })
    end

    return flags
end

function asyncrt_build.coroutine_mflags()
    return asyncrt_build.conservative_async_mflags({"-fno-objc-arc"})
end

function asyncrt_build.internal_test_access_enabled()
    return is_mode("test") or has_config("asyncrt-test-access")
end

function asyncrt_build.direct_dispatch_enabled()
    return has_config("asyncrt-direct-enabled")
end

function asyncrt_build.direct_dispatch_disabled()
    return (not asyncrt_build.direct_dispatch_enabled()) or asyncrt_build.internal_test_access_enabled()
end

function asyncrt_build.ui_uses_cairo_x11_backend()
    return (not is_plat("macosx")) or has_config("asyncrt-ui-x11")
end

function asyncrt_build.add_direct_dispatch_flags()
    if asyncrt_build.direct_dispatch_disabled() then
        add_mflags("-fobjc-disable-direct-methods-for-testing", {force = true})
    end
end

function asyncrt_build.add_internal_test_access_define()
    if asyncrt_build.internal_test_access_enabled() then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end
end

function asyncrt_build.add_macos_x11_search_paths()
    local x11_root = "/opt/X11"

    if not is_plat("macosx") then
        return
    end

    if not os.isdir(path.join(x11_root, "include", "X11")) or not os.isdir(path.join(x11_root, "lib")) then
        raise("asyncrt_ui_x11 requires XQuartz headers and libraries in /opt/X11")
    end

    add_includedirs(path.join(x11_root, "include"))
    add_linkdirs(path.join(x11_root, "lib"), { public = true })
end

function asyncrt_build.strip_default_macos_frameworks(target, ...)
    local extra_frameworks = {...}
    local function framework_should_drop(name)
        if name == "Foundation" then
            return true
        end

        for _, framework in ipairs(extra_frameworks) do
            if framework == name then
                return true
            end
        end

        return false
    end

    if not target:is_plat("macosx") then
        return
    end

    local filtered_frameworks = {}
    local frameworks = table.wrap(target:get("frameworks"))
    for _, framework in ipairs(frameworks) do
        local should_drop = framework_should_drop(framework)
        if not should_drop then
            table.insert(filtered_frameworks, framework)
        end
    end

    target:set("frameworks", filtered_frameworks)
end
