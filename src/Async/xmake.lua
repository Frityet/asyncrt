local common = asyncrt_build

local function configure_async_target(utilities_target)
    add_deps(utilities_target, { public = true })
    add_files("Coroutine.m", {mflags = common.coroutine_mflags()})
    add_files("**.m|Coroutine.m")
end

target("AsyncRT")
    set_kind("static")
    configure_async_target("Utilities")
    after_config(function (target)
        common.strip_default_macos_frameworks(target)
    end)

target("AsyncRTTest")
    set_default(false)
    set_kind("static")
    add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    configure_async_target("UtilitiesTest")
    after_config(function (target)
        common.strip_default_macos_frameworks(target)
    end)
