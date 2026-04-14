local common = asyncrt_build

local function configure_async_target()
    add_deps("Utilities", { public = true })
    add_includedirs("src", { public = true })
    add_includedirs("../extern")
    add_files("src/Coroutine.m", {mflags = common.coroutine_mflags()})
    add_files("src/*.m|src/Coroutine.m")
    common.add_internal_test_access_define()

    after_config(function (target)
        common.strip_default_macos_frameworks(target)
    end)
end

target("AsyncRT")
    set_kind("static")
    configure_async_target()
