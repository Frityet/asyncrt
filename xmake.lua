add_rules("mode.debug", "mode.release", "mode.minsizerel", "mode.coverage", "mode.asan", "mode.tsan")
set_allowedmodes("debug", "release", "minsizerel", "coverage", "asan", "tsan", "test")

set_languages("gnu23")
set_toolchains("clang")

--autogen compile commands
add_rules("plugin.compile_commands.autoupdate")

add_repositories("asyncrt-xrepo xrepo", {rootdir = os.scriptdir()})

option("asyncrt-test-access", {
    default = false,
    showmenu = true,
    description = "Enable white-box test access outside test mode."
})

option("asyncrt-direct-enabled", {
    default = true,
    showmenu = true,
    description = "Enable Clang direct ObjC dispatch in non-test builds. Test-access builds still disable it."
})

option("asyncrt-ui-x11", {
    default = false,
    showmenu = true,
    description = "Build AsyncRTUI against the Cairo/X11 backend on macOS. Non-macOS targets already use Cairo/X11 by default."
})

option("asyncrt-ui", {
    default = true,
    showmenu = true,
    description = "Build the AsyncRT UI module."
})

option("asyncrt-db", {
    default = true,
    showmenu = true,
    description = "Build the ObjDB module and database providers."
})

option("asyncrt-app", {
    default = true,
    showmenu = true,
    description = "Build the example application support module."
})

option("asyncrt-test-support", {
    default = true,
    showmenu = true,
    description = "Build AsyncRT test support targets."
})

option("asyncrt-tools", {
    default = true,
    showmenu = true,
    description = "Build AsyncRT tool targets."
})

local internal_test_access_enabled = is_mode("test") or has_config("asyncrt-test-access")
local asyncrt_ui_enabled = has_config("asyncrt-ui")
local ui_uses_cairo_x11_backend = asyncrt_ui_enabled and ((not is_plat("macosx")) or has_config("asyncrt-ui-x11"))

add_requires("objfw", {
    configs = {
        shared = false,
        debug = is_mode("debug")
    }
})

if asyncrt_ui_enabled and (ui_uses_cairo_x11_backend or internal_test_access_enabled) then
    add_requires("cairo")
end

add_packages("objfw")

set_warnings("all", "error")

if not has_config("asyncrt-direct-enabled") or internal_test_access_enabled then
    add_mflags("-fobjc-disable-direct-methods-for-testing", {force = true})
end

if is_mode("asan") then
    set_policy("build.sanitizer.address", true)
    set_policy("build.sanitizer.undefined", true)
end

if is_mode("tsan") then
    set_policy("build.sanitizer.thread", true)
end

if is_mode("coverage") then
    -- Coverage needs unoptimized frames for reliable source mapping and the
    -- coroutine path still needs conservative stack metadata.
    local coverage_flags = {
        "-O0",
        "-fno-omit-frame-pointer",
        "-fno-optimize-sibling-calls",
        "-fprofile-instr-generate",
        "-fcoverage-mapping"
    }

    set_optimize("none")
    set_symbols("debug")
    add_cxflags(table.unpack(coverage_flags))
    add_mflags(table.unpack(coverage_flags))
    add_ldflags("-fprofile-instr-generate", "-fcoverage-mapping", {force = true})
end

if is_mode("test") then
    set_symbols("debug")
    set_optimize("none")
end

local c_and_objc_flags = {
    "-Wall",
    "-Wextra",
    "-xobjective-c",
    "-fms-extensions",
    "-Wno-microsoft",
    "-Wno-unused-function",
    "-Wassign-enum",
    "-Wenum-conversion",
    "-Wenum-enum-conversion",
    "-Wnull-dereference",
    "-Wnull-conversion",
    "-Wnullability-completeness",
    "-Wnullable-to-nonnull-conversion",
    "-Wno-auto-var-id",
    "-Wno-compare-distinct-pointer-types",
    "-Wno-missing-braces"
}

add_cxflags(table.unpack(c_and_objc_flags))
add_mflags(table.unpack(c_and_objc_flags))

if is_plat("linux") and is_mode("debug") then
    add_ldflags("-rdynamic")
    add_cxflags("-fno-omit-frame-pointer")
    add_mflags("-fno-omit-frame-pointer")
end

includes("AsyncRT")

if has_config("asyncrt-tools") then
    includes("tools")
end
