target("AsyncRTExampleDB", function ()
    set_kind("binary")
    set_group("examples")
    add_deps("AsyncRTApplicationCore", "AsyncRTDatabaseProviderSQLite")
    add_includedirs("../..", { public = true })
    add_files("main.m")

    if is_plat("macosx") then
        add_ldflags("-ObjC", {force = true})
    end
end)
