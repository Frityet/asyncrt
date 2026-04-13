local function filtered_frameworks(target, frameworks_to_drop)
    local filtered = {}

    for _, framework in ipairs(table.wrap(target:get("frameworks"))) do
        local should_drop = false

        for _, dropped_framework in ipairs(frameworks_to_drop) do
            if framework == dropped_framework then
                should_drop = true
                break
            end
        end

        if not should_drop then
            table.insert(filtered, framework)
        end
    end

    target:set("frameworks", filtered)
end

rule("objc.build")
    set_sourcekinds("mm")
    add_deps("objc.build.pcheader")
    on_config(function (target)
        import("rules.objc++.config.main", {rootdir = os.programdir(), alias = "objc_config"})

        objc_config(target, "mm")

        if target:is_plat("macosx") then
            filtered_frameworks(target, {"Foundation"})
        end
    end)
    on_build_files("private.action.build.object", {jobgraph = true, batch = true, distcc = true})

rule("objc++.build")
    set_sourcekinds("mxx")
    add_deps("objc++.build.pcheader")
    on_config(function (target)
        import("rules.objc++.config.main", {rootdir = os.programdir(), alias = "objc_config"})

        objc_config(target, "mxx")

        if target:is_plat("macosx") then
            filtered_frameworks(target, {"Foundation"})
        end
    end)
    on_build_files("private.action.build.object", {jobgraph = true, batch = true, distcc = true})

rule("xcode.application")
    add_deps("xcode.info_plist", "xcode.storyboard", "xcode.xcassets", "xcode.metal")
    on_load(function (target)
        local targetdir = target:targetdir()
        local bundledir = path.join(targetdir, target:basename() .. ".app")
        local contentsdir = bundledir
        local resourcesdir = bundledir

        target:data_set("xcode.bundle.rootdir", bundledir)
        if target:is_plat("macosx") then
            contentsdir = path.join(bundledir, "Contents")
            resourcesdir = path.join(bundledir, "Contents", "Resources")
        end
        target:data_set("xcode.bundle.contentsdir", contentsdir)
        target:data_set("xcode.bundle.resourcesdir", resourcesdir)

        target:set("kind", "binary")
        target:set("filename", target:basename())

        if target:is_plat("macosx") and not target:get("installdir") then
            target:set("installdir", "/Applications")
        end

        target:add("cleanfiles", bundledir)
    end)
    after_build(function (target, opt)
        import("rules.xcode.application.build", {rootdir = os.programdir(), alias = "xcode_application_build"})
        xcode_application_build(target, opt or {})
    end)
    on_package(function (target, opt)
        import("rules.xcode.application.package", {rootdir = os.programdir(), alias = "xcode_application_package"})
        xcode_application_package(target, opt or {})
    end)
    on_install(function (target)
        import("rules.xcode.application.install", {rootdir = os.programdir(), alias = "xcode_application_install"})
        xcode_application_install(target)
    end)
    on_installcmd(function (target, batchcmds, opt)
        import("rules.xcode.application.installcmd", {rootdir = os.programdir(), alias = "xcode_application_installcmd"})
        xcode_application_installcmd(target, batchcmds, opt or {})
    end)
    on_uninstall(function (target)
        import("rules.xcode.application.uninstall", {rootdir = os.programdir(), alias = "xcode_application_uninstall"})
        xcode_application_uninstall(target)
    end)
    on_run(function (target, opt)
        import("rules.xcode.application.run", {rootdir = os.programdir(), alias = "xcode_application_run"})
        xcode_application_run(target, opt or {})
    end)
