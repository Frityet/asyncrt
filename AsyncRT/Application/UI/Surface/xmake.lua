target("AsyncRTApplicationUIBase", function ()
    set_kind(get_config("kind") == "shared" and "shared" or "static")

    add_deps("AsyncRTApplicationCore", { public = true })
    add_includedirs("../../..", { public = true })
    add_headerfiles("../*.h", { prefixdir = "AsyncRT/Application/UI" })
    add_headerfiles("../Window/(Configuration.h)", { prefixdir = "AsyncRT/Application/UI/Window" })
    add_files("../Application.m", "../Window/Configuration.m")
end)

if has_config("asyncrt-ui") then
    includes("Immediate")
end

if has_config("asyncrt-webui") then
    includes("Web")
end
