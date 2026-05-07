option("asyncrt-objdb-drivers", {
    default = false,
    showmenu = true,
    description = "Enable ObjDB tool database driver package dependencies."
})

if has_config("asyncrt-objdb-drivers") then
    add_requires("sqlite3", "postgresql")
end

target("ObjDB", function ()
    set_kind("static")
    add_deps("AsyncRT", { public = true })
    add_includedirs("src", { public = true })
    add_files("src/*.m")

    if is_mode("test") or has_config("asyncrt-test-access") then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end
end)

includes("DatabaseProviders/SQLite")

target("ObjDBExample", function ()
    set_default(false)
    set_kind("binary")
    set_group("examples")
    add_deps("ObjDBSQLite")
    add_files("Example/**.m")
    if is_plat("macosx") then
        add_ldflags("-ObjC", {force = true})
    end
end)

target("odb", function ()
    set_default(false)
    set_kind("binary")
    set_group("tools")
    add_deps("ObjDB")
    if has_config("asyncrt-objdb-drivers") then
        add_packages("sqlite3", "postgresql")
    end
    add_files("tool/**.m")
    if is_plat("macosx") then
        add_ldflags("-ObjC", {force = true})
    end
end)
