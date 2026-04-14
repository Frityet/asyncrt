local common = asyncrt_build

local function configure_utilities_target()
    add_includedirs("src", { public = true })
    add_files("src/*.m")
    common.add_internal_test_access_define()

    after_config(function (target)
        common.strip_default_macos_frameworks(target)
    end)
end

target("Utilities")
    set_kind("static")
    configure_utilities_target()
