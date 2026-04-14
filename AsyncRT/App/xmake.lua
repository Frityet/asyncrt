local common = asyncrt_build

local function configure_app_support_target()
    add_deps("AsyncRTUI", { public = true })
    add_includedirs("src", { public = true })
    add_files(
        "src/ArgumentParser.m",
        "src/CalculatorComponents.m",
        "src/CalculatorEvaluator.m",
        "src/CalculatorModel.m",
        "src/CalculatorTheme.m"
    )
    common.add_internal_test_access_define()
end

target("AsyncRTAppSupport")
    set_kind("static")
    configure_app_support_target()

target("App")
    set_kind("binary")
    add_deps("AsyncRTAppSupport")
    if is_plat("macosx") then
        add_rules("xcode.application")
        add_rpathdirs("@loader_path")
        add_ldflags("-ObjC", {force = true})
        add_files("src/Info.plist")
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
    add_files("src/main.m")
