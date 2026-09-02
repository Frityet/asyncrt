target("AsyncRT.IO", function ()
    set_kind("static")
    add_includedirs("src", { public = true })
    add_headerfiles("src/(*.h)")
    add_packages("objfw")
    add_deps("AsyncRT.Common", "AsyncRT.Core")
    add_files("src/*.m")

    if is_plat("macosx") then
        add_ldflags("-ObjC", { public = true })
    end
end)
