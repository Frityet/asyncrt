target("AsyncRT.Common", function ()
    set_kind("static")
    add_includedirs("../..", { public = true })
    add_headerfiles("*.h", { prefixdir = "AsyncRT/Common" })
    set_pcheader("Common.h")
    add_files("*.m")

    if is_plat("macosx") then
        add_ldflags("-ObjC", { public = true })
    end
end)
