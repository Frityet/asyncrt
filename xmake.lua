add_rules("mode.debug", "mode.release", "mode.minsizerel", "mode.coverage", "mode.asan", "mode.tsan")
set_allowedmodes("debug", "release", "minsizerel", "coverage", "asan", "tsan")

set_languages("gnulatest")
set_toolchains("clang")

local mode_uses_lto = is_mode("release") or is_mode("minsizerel")

includes("xmake/common.lua")
includes("xmake/rules.lua")

add_requires("objfw", {
    configs = {
        shared = false,
        debug = is_mode("debug"),
        --tls = "openssl"
    }
})
add_requires("cairo")

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
    set_policy("build.optimization.lto", true)
end

if is_mode("coverage") then
    -- Coverage needs unoptimized frames for reliable source mapping and the
    -- coroutine path still needs conservative stack metadata.
    set_optimize("none")
    add_cxflags("-O0", "-fno-omit-frame-pointer", "-fno-optimize-sibling-calls")
    add_mflags("-O0", "-fno-omit-frame-pointer", "-fno-optimize-sibling-calls")
end

if is_mode("coverage") then
    set_symbols("debug")
    add_cxflags("-fprofile-instr-generate", "-fcoverage-mapping")
    add_mflags("-fprofile-instr-generate", "-fcoverage-mapping")
    add_ldflags("-fprofile-instr-generate", "-fcoverage-mapping", {force = true})
end

add_cxflags("-Wall", "-Wextra")
add_mflags("-Wall", "-Wextra")
add_cxflags("-xobjective-c", "-fms-extensions", "-Wno-microsoft")
add_mflags("-xobjective-c", "-fms-extensions", "-Wno-microsoft")
add_cxflags("-Wno-unused-function")
add_mflags("-Wno-unused-function")
add_cxflags(
    "-Wanon-enum-enum-conversion",
    "-Wassign-enum",
    "-Wenum-conversion",
    "-Wenum-enum-conversion"
)
add_mflags(
    "-Wanon-enum-enum-conversion",
    "-Wassign-enum",
    "-Wenum-conversion",
    "-Wenum-enum-conversion"
)
add_cxflags(
    "-Wnull-dereference",
    "-Wnull-conversion",
    "-Wnullability-completeness",
    "-Wnullable-to-nonnull-conversion",
    "-Wno-auto-var-id",
    "-Wno-compare-distinct-pointer-types" --why the fuck is this a diagnostic?
)
add_mflags(
    "-Wnull-dereference",
    "-Wnull-conversion",
    "-Wnullability-completeness",
    "-Wnullable-to-nonnull-conversion",
    "-Wno-auto-var-id",
    "-Wno-compare-distinct-pointer-types" --why the fuck is this a diagnostic?
)
add_cxflags("-Wno-missing-braces")
add_mflags("-Wno-missing-braces")

if is_plat("linux") then
    add_ldflags("-rdynamic")
    add_cxflags("-fno-omit-frame-pointer")
    add_mflags("-fno-omit-frame-pointer")
end

add_includedirs("src")

includes("src/Utilities", "src/Async", "src/UI", "src/App", "tools", "tests")
