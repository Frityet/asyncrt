add_rules("mode.debug", "mode.release", "mode.minsizerel", "mode.asan", "mode.tsan")

set_languages("gnu23")

do
    local prefix = "/opt/homebrew/opt/llvm/bin/"

    toolchain("homebrew-llvm")
        set_kind("standalone")
        set_toolset("cc", prefix .. "clang")
        set_toolset("cxx", prefix .. "clang++")
        set_toolset("mm", prefix .. "clang")
        set_toolset("mxx", prefix .. "clang++")
        set_toolset("ld", prefix .. "clang++", prefix .. "clang")
        set_toolset("sh", prefix .. "clang++", prefix .. "clang")
        set_toolset("ar", prefix .. "llvm-ar")
        set_toolset("ranlib", prefix .. "llvm-ranlib")
        set_toolset("strip", prefix .. "llvm-strip")
        set_toolset("nm", prefix .. "llvm-nm")
    toolchain_end()
end

if is_plat("macosx") then
    set_toolchains("homebrew-llvm")
else
    set_toolchains("clang")
end

add_rules("plugin.compile_commands.autoupdate", { lsp = "clangd" })

add_repositories("local .")

add_requires("objfw main", {
    configs = {
        shared = is_kind("shared"),
        rpath = true,
        debug = is_mode("debug"),
        tls = "openssl"
    }
})
add_requires("objsqlite3")
add_packages("objfw")

function add_flags(...)
    add_mxflags(...)
    add_cxflags(...)
end

add_flags {
    "-Wall",
    "-Wextra",
    "-Werror",
    "-fms-extensions",
    "-Wno-microsoft",
    "-Wno-unused-function",
    "-Wassign-enum",
    "-Wenum-conversion",
    "-Wenum-enum-conversion",
    "-Wnull-dereference",
    "-Wnull-conversion",
    "-Wnullability-completeness",
    "-Wno-nullability-inferred-on-nested-type",
    "-Wnullable-to-nonnull-conversion",
    "-Wno-auto-var-id",
    "-Wno-compare-distinct-pointer-types",
    "-Wno-missing-braces"
}

if is_plat("macosx") then
    -- Clang 23 emits empty collection literals as Foundation-owned
    -- __NSDictionary0 / __NSArray0 singletons for modern Apple runtimes, even
    -- when constant collection literals are disabled. ObjFW provides the
    -- literal factory methods instead. Selecting the last Apple runtime
    -- profile without empty-collection symbols preserves the Apple ABI, ARC,
    -- weak references, and direct methods while routing every literal through
    -- ObjFW. This changes compile-time lowering only, not the deployment target.
    add_mxflags("-fobjc-runtime=macosx-10.10",
        "-fno-objc-constant-literals", { force = true })
    add_mxxflags("-fobjc-runtime=macosx-10.10",
        "-fno-objc-constant-literals", { force = true })
end

if is_mode("debug", "asan", "tsan") then
    add_flags("-fobjc-disable-direct-methods-for-testing")
end

if is_kind("shared") then
    add_flags("-fPIC")
end

if is_plat("linux") and is_mode("debug", "asan", "tsan") then
    add_ldflags("-rdynamic")
    add_cxflags("-fno-omit-frame-pointer")
    add_mflags("-fno-omit-frame-pointer")
end

includes("AsyncRT", "Benchmarks", "Examples", "Tests", "Tools")
