add_rules("mode.debug", "mode.release", "mode.minsizerel", "mode.coverage", "mode.asan", "mode.tsan")

set_languages("gnu23")
set_toolchains("clang")

add_rules("plugin.compile_commands.autoupdate", { lsp = "clangd" })

add_requires("objfw", {
    configs = {
        shared = is_kind("shared"),
        rpath = true,
        debug = is_mode("debug")
    }
})
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

if is_kind("shared") then
    add_flags("-fPIC")
end

if is_plat("linux") and is_mode("debug") then
    add_ldflags("-rdynamic")
    add_cxflags("-fno-omit-frame-pointer")
    add_mflags("-fno-omit-frame-pointer")
end

includes("AsyncRT", "Examples")
