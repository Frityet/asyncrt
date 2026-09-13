target("AsyncRT.WebViewRenderer", function ()
    set_kind("binary")
    add_deps("AsyncRT.Common", "AsyncRT.Core", "AsyncRT.IO", "AsyncRT.Web")
    add_packages("objfw")
    add_includedirs("src", { public = true })
    add_headerfiles("src/(**.h)")
    add_files("src/**.m")
    
    if is_plat("macosx") then
        add_ldflags("-ObjC", { public = true })
    end
end)
