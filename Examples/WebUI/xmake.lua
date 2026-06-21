target("AsyncRTExampleWebUI", function ()
    set_kind("binary")
    set_group("examples")
    add_deps("AsyncRTWebUI")
    add_includedirs("../..", { public = true })
    add_files("src/*.m")

    if is_plat("macosx") then
        add_ldflags("-ObjC", {force = true})
    end
end)
