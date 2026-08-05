target("AsyncRT.IO", function ()
    set_kind("static")
    add_includedirs("../..", { public = true })
    add_headerfiles("*.h", { prefixdir = "AsyncRT/IO" })
    add_packages("objfw")
    add_deps("AsyncRT.Common", "AsyncRT.Core")
    add_files("*.m")

    if is_plat("macosx") then
        add_ldflags("-ObjC", { public = true })
    end
end)
