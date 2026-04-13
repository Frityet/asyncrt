local common = asyncrt_build

target("Utilities")
    set_kind("static")
    set_pmheader("common.h")
    add_files("**.m")
    after_config(function (target)
        common.strip_default_macos_frameworks(target)
    end)

target("UtilitiesTest")
    set_default(false)
    set_kind("static")
    add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    set_pmheader("common.h")
    add_files("**.m")
    after_config(function (target)
        common.strip_default_macos_frameworks(target)
    end)
