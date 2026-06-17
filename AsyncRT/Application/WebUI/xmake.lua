add_requires("webview")

target("AsyncRTWebUI", function ()
    set_kind(get_config("kind") == "shared" and "shared" or "static")

    add_deps("AsyncRTApplicationCore", "AsyncRTNetworkingHTTP", { public = true })
    add_includedirs("../../..", { public = true })

    add_headerfiles("../../(WebUI.h)")
    add_headerfiles("**.h", { prefixdir = "AsyncRT/Application/WebUI" })
    add_files("**.m")

    add_packages("webview")
end)