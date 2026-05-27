add_rules("mode.debug", "mode.release", "mode.minsizerel", "mode.coverage", "mode.asan", "mode.tsan")
set_allowedmodes("debug", "release", "minsizerel", "coverage", "asan", "tsan", "test")

set_languages("gnu23")
set_toolchains("clang")

add_rules("plugin.compile_commands.autoupdate", { lsp = "clangd" })

add_repositories("asyncrt-xrepo xrepo", {rootdir = os.scriptdir()})

option("asyncrt-test-access", {
    default = false,
    showmenu = true,
    description = "Enable white-box test access outside test mode."
})

option("asyncrt-direct-enabled", {
    default = true,
    showmenu = true,
    description = "Enable Clang direct ObjC dispatch in non-test static builds. Shared and test-access builds still disable it."
})

option("asyncrt-ui-x11", {
    default = false,
    showmenu = true,
    description = "Build AsyncRT Application UI against the Cairo/X11 backend on macOS. Non-macOS targets already use Cairo/X11 by default."
})

option("asyncrt-ui", {
    default = false,
    showmenu = true,
    description = "Build the AsyncRT UI module. This pulls in Cairo/X11 on non-macOS targets."
})

option("asyncrt-db", {
    default = true,
    showmenu = true,
    description = "Build the AsyncRT database module and providers."
})

option("asyncrt-app", {
    default = true,
    showmenu = true,
    description = "Build AsyncRT example targets."
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
        shared = get_config("kind") == "shared",
        rpath = true,
        debug = is_mode("debug")
    }
})

if asyncrt_ui_enabled and (ui_uses_cairo_x11_backend or internal_test_access_enabled) then
    add_requires("cairo", {
        configs = {
            shared = get_config("kind") == "shared"
        }
    })
end

add_packages("objfw")

if is_plat("linux") then
    -- ObjFW is linked statically in the local test/default configs. Keep the
    -- ObjFW libraries late as system links so symbols referenced from our
    -- static AsyncRT archives are still resolved.
    add_syslinks("objfw", "objfwrt", "objfwtls", "ssl", "crypto", "pthread", "dl")
end

rule("asyncrt.package.rpaths")
    after_load(function (target)
        if get_config("kind") ~= "shared" or (target:kind() ~= "binary" and target:kind() ~= "shared") then
            return
        end

        local rpathdirs = {}
        local function add_rpathdir(rpathdir)
            if rpathdir == nil or rpathdirs[rpathdir] then
                return
            end

            rpathdirs[rpathdir] = true
            target:add("rpathdirs", rpathdir)
            if target:kind() == "shared" then
                local shared_rpathdir = rpathdir:gsub("@loader_path", "$ORIGIN"):gsub("@executable_path", "$ORIGIN")
                target:add("shflags", "-Wl,-rpath=" .. shared_rpathdir)
            end
        end

        local function add_package_rpaths(pkg)
            local installdir = pkg:installdir()
            for _, linkdir in ipairs(table.wrap(pkg:get("linkdirs") or "lib")) do
                if not path.is_absolute(linkdir) and installdir ~= nil then
                    linkdir = path.join(installdir, linkdir)
                end

                if os.isdir(linkdir) then
                    add_rpathdir(linkdir)
                end
            end
        end

        local function add_target_package_rpaths(package_target)
            for _, pkg in ipairs(package_target:orderpkgs()) do
                add_package_rpaths(pkg)
            end
        end

        add_rpathdir("@loader_path")
        add_target_package_rpaths(target)

        for _, dep in ipairs(target:orderdeps({inherit = true})) do
            add_target_package_rpaths(dep)
        end
    end)
rule_end()

rule("asyncrt.objc.static-deps")
    after_load(function (target)
        if target:kind() ~= "binary" or target:is_plat("macosx") then
            return
        end

        for _, dep in ipairs(target:orderdeps({inherit = true})) do
            if dep:kind() == "static" then
                target:add("linkgroups", dep:name(), {whole = true})
            end
        end
    end)
rule_end()

add_rules("asyncrt.package.rpaths", "asyncrt.objc.static-deps")

set_warnings("all", "error")

if get_config("kind") == "shared" or not has_config("asyncrt-direct-enabled") or internal_test_access_enabled then
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
    add_cxflags(coverage_flags)
    add_mflags(coverage_flags)
    add_ldflags("-fprofile-instr-generate", "-fcoverage-mapping", {force = true})
end

if is_mode("test") then
    set_symbols("debug")
    set_optimize("none")
end

if get_config("kind") == "shared" then
    add_cxflags("-fPIC")
    add_mflags("-fPIC")
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
    "-Wno-nullability-inferred-on-nested-type",
    "-Wnullable-to-nonnull-conversion",
    "-Wno-auto-var-id",
    "-Wno-compare-distinct-pointer-types",
    "-Wno-missing-braces"
}

add_cxflags(c_and_objc_flags)
add_mflags(c_and_objc_flags)
add_mflags("-include", "ObjFW/ObjFW.h", {force = true})

if is_plat("linux") and is_mode("debug") then
    add_ldflags("-rdynamic")
    add_cxflags("-fno-omit-frame-pointer")
    add_mflags("-fno-omit-frame-pointer")
end

includes("AsyncRT")

if has_config("asyncrt-test-support") then
    includes("TestSupport")
end

if has_config("asyncrt-app") then
    if has_config("asyncrt-ui") then
        includes("Examples/UI")
    end

    if has_config("asyncrt-db") then
        includes("Examples/DB")
    end
end

if has_config("asyncrt-tools") then
    includes("tools")
end

task("check-objfw-async-boundary")
    set_menu {
        usage = "xmake check-objfw-async-boundary",
        description = "Fail if direct ObjFW async selectors appear outside AsyncRT adapter implementations."
    }
    on_run(function ()
        os.execv(os.scriptdir() .. "/tools/check-objfw-async-boundary.sh")
    end)
