if is_plat("macosx") then
    target("AsyncRT.Tests.Common.ConstantStringImage", function ()
        set_kind("shared")
        set_default(false)
        set_group("tests/common/fixtures")
        set_filename("AsyncRT.Tests.Common.ConstantStringImage.dylib")
        add_packages("objfw", { links = {} })
        add_mxflags("-fconstant-string-class=OFConstantString",
            { force = true })
        add_shflags("-Wl,-undefined,dynamic_lookup", { force = true })
        add_files("src/ConstantStringImage.m")
    end)
end

target("AsyncRT.Tests.Common", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/common")
    add_deps("AsyncRT.Common")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("src/CommonTests.m")

    if is_plat("macosx") then
        add_deps("AsyncRT.Tests.Common.ConstantStringImage", {
            links = false
        })
        after_load(function (target)
            local image = target:dep(
                "AsyncRT.Tests.Common.ConstantStringImage")
            local image_path = path.absolute(image:targetfile(),
                os.projectdir())
            target:add("defines",
                "ASYNC_RT_CONSTANT_STRING_IMAGE_PATH=" ..
                    string.format("%q", image_path))
        end)
    end

    on_load(function (target)
        target:add("tests", "CommonTests", {
            group = "common",
            run_timeout = 5000
        })
    end)
end)

includes("LINQ")
