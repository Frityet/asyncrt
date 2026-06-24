target("AsyncRT.Core", function ()
    set_kind("static")
    add_includedirs("../..", { public = true })
    add_headerfiles("*.h", { prefixdir = "AsyncRT/Core" })
    add_pcmheader("Cores.h")
    add_files("*.m")
end)

