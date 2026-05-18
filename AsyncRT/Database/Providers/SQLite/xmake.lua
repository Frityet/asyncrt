add_requires("sqlite3", {
    configs = {
        shared = get_config("kind") == "shared"
    }
})

target("AsyncRTDatabaseProviderSQLite", function ()
    set_default(false)
    set_kind(get_config("kind") == "shared" and "shared" or "static")
    add_deps("AsyncRTDatabase", { public = true })
    add_packages("sqlite3", { public = true })
    add_syslinks("sqlite3", { public = true })
    add_includedirs("../../../..", { public = true })
    add_headerfiles("../(SQLite.h)")
    add_headerfiles("*.h", {prefixdir = "AsyncRT/Database/Providers/SQLite"})
    add_files("*.m")
end)
