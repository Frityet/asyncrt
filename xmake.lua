add_rules("mode.debug", "mode.release", "mode.minsizerel", "mode.coverage", "mode.asan", "mode.tsan")
set_allowedmodes("debug", "release", "minsizerel", "coverage", "asan", "tsan", "test")

set_languages("gnulatest")
set_toolchains("clang")

local mode_uses_lto = is_mode("release") or is_mode("minsizerel")

includes("xmake/common.lua")
local common = asyncrt_build

local function add_c_and_objc_flags(...)
    add_cxflags(...)
    add_mflags(...)
end

add_repositories("asyncrt-xrepo xrepo", {rootdir = os.scriptdir()})

option("asyncrt-test-access")
    set_default(false)
    set_showmenu(true)
    set_description("Relax objc_direct restrictions so white-box tests can call internal methods.")
option_end()

option("asyncrt-ui-x11")
    set_default(false)
    set_showmenu(true)
    set_description("Build AsyncRTUI against the Cairo/X11 backend on macOS. Non-macOS targets already use Cairo/X11 by default.")
option_end()

add_requires("objfw", {
    configs = {
        shared = false,
        debug = is_mode("debug")
    }
})

if common.ui_uses_cairo_x11_backend() or has_config("asyncrt-test-access") then
    add_requires("cairo")
end

add_packages("objfw")

set_warnings("all", "error")

if is_mode("asan") then
    set_policy("build.sanitizer.address", true)
    set_policy("build.sanitizer.undefined", true)
end

if is_mode("tsan") then
    set_policy("build.sanitizer.thread", true)
end

if mode_uses_lto then
--    set_policy("build.optimization.lto", true)
end

if is_mode("coverage") then
    -- Coverage needs unoptimized frames for reliable source mapping and the
    -- coroutine path still needs conservative stack metadata.
    set_optimize("none")
    add_c_and_objc_flags("-O0", "-fno-omit-frame-pointer", "-fno-optimize-sibling-calls")
    set_symbols("debug")
    add_c_and_objc_flags("-fprofile-instr-generate", "-fcoverage-mapping")
    add_ldflags("-fprofile-instr-generate", "-fcoverage-mapping", {force = true})
end

if is_mode("test") then
    set_symbols("debug")
    set_optimize("none")
end

add_c_and_objc_flags("-Wall", "-Wextra")
add_c_and_objc_flags("-xobjective-c", "-fms-extensions", "-Wno-microsoft")
add_c_and_objc_flags("-Wno-unused-function")
add_c_and_objc_flags(
    "-Wassign-enum",
    "-Wenum-conversion",
    "-Wenum-enum-conversion"
)
add_c_and_objc_flags(
    "-Wnull-dereference",
    "-Wnull-conversion",
    "-Wnullability-completeness",
    "-Wnullable-to-nonnull-conversion",
    "-Wno-auto-var-id",
    "-Wno-compare-distinct-pointer-types" --why the fuck is this a diagnostic?
)
add_c_and_objc_flags("-Wno-missing-braces")

if is_plat("linux") and is_mode("debug") then
    add_ldflags("-rdynamic")
    add_c_and_objc_flags("-fno-omit-frame-pointer")
end

includes("AsyncRT", "tools")
