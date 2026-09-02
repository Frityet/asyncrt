target("AsyncRT.Common", function ()
    set_kind("static")
    add_packages("objfw")
    add_includedirs("src", { public = true })
    add_headerfiles("src/(*.h)")
    set_pcheader("src/Common.h")
    add_files("src/*.m")

    if is_plat("macosx") then
        add_ldflags("-ObjC", { public = true })
    end
end)
