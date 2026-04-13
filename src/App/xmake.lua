target("App")
    set_kind("binary")
    add_deps("AsyncRTUI")
    set_pmheader("../Utilities/common.h")
    if is_plat("macosx") then
        add_rules("xcode.application")
        add_rpathdirs("@loader_path")
        add_ldflags("-ObjC", {force = true})
        add_files("Info.plist")
        on_run(function (target)
            import("core.base.option")

            local bundledir = path.absolute(target:data("xcode.bundle.rootdir"))
            local argv = {"-W", "-n", bundledir}
            local arguments = option.get("arguments")

            if arguments then
                table.insert(argv, "--args")
                for _, argument in ipairs(arguments) do
                    table.insert(argv, argument)
                end
            end

            os.execv("open", argv)
        end)
    end
    add_files("**.m")
