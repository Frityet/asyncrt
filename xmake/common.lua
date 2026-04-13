asyncrt_build = asyncrt_build or {}

function asyncrt_build.first_existing_dir(patterns)
    for _, pattern in ipairs(patterns) do
        local matches = {}

        if pattern:find("%*") ~= nil then
            matches = os.dirs(pattern)
            table.sort(matches)
        elseif os.isdir(pattern) then
            matches = {pattern}
        end

        if #matches > 0 then
            return matches[#matches]
        end
    end

    return nil
end

function asyncrt_build.detect_macos_x11()
    local includedir, libdir

    if not is_plat("macosx") then
        return nil
    end

    includedir = asyncrt_build.first_existing_dir({
        "/opt/X11/include",
        "/opt/homebrew/Cellar/libx11/*/include",
        "/usr/local/Cellar/libx11/*/include"
    })
    libdir = asyncrt_build.first_existing_dir({
        "/opt/X11/lib",
        "/opt/homebrew/Cellar/libx11/*/lib",
        "/usr/local/Cellar/libx11/*/lib"
    })

    if includedir ~= nil and libdir ~= nil and os.isfile(includedir .. "/X11/Xlib.h") then
        return {
            includedir = includedir,
            libdir = libdir
        }
    end

    return nil
end

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
            "-fno-lto"
        })
    end

    return flags
end

function asyncrt_build.coroutine_mflags()
    return asyncrt_build.conservative_async_mflags({"-fno-objc-arc"})
end

function asyncrt_build.strip_default_macos_frameworks(target, ...)
    local extra_frameworks = {...}
    local filtered_frameworks = {}
    local frameworks
    local should_drop
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

    frameworks = table.wrap(target:get("frameworks"))
    for _, framework in ipairs(frameworks) do
        should_drop = framework_should_drop(framework)
        if not should_drop then
            table.insert(filtered_frameworks, framework)
        end
    end

    target:set("frameworks", filtered_frameworks)
end

asyncrt_build.macos_x11 = asyncrt_build.detect_macos_x11()
