target("AsyncRT.Core", function ()
    set_kind("static")
    add_includedirs("../..", { public = true })
    add_headerfiles("*.h", { prefixdir = "AsyncRT/Core" })
    add_files("*.m|Coroutine.m")
    add_files("Coroutine.m", {
        mflags = { "-fno-objc-arc" }
    })
end)

