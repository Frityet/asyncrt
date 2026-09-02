target("AsyncRT.Web", function ()
    set_kind("static")
    add_deps("AsyncRT.Common", "AsyncRT.Core", "AsyncRT.IO")
    add_packages("objfw")
    add_includedirs("src", { public = true })
    add_headerfiles(
        "src/(Web.h)",
        "src/(OWebComponent.h)",
        "src/(OWebHTTP.h)",
        "src/(OWebObjFWHTTPServer.h)",
        "src/(OWebReflection.h)",
        "src/(OWebSession.h)",
        "src/(OWebTemplate.h)",
        "src/(OWebWireProtocol.h)"
    )
    add_files("src/*.m")
    add_installfiles("src/*.mjs", {
        prefixdir = "share/asyncrt/web/browser"
    })
    add_extrafiles("src/*.mjs")

    if is_plat("macosx") then
        add_ldflags("-ObjC", { public = true })
    end
end)
