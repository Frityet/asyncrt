package("objsqlite3")
    set_kind("library")
    set_homepage("https://git.nila.im/ObjFW/ObjSQLite3")
    set_description("SQLite3 bindings for ObjFW.")
    set_license("ISC")

    -- Git-only sources allow versions to be pinned directly to commits.
    add_urls("https://git.nil.im/ObjFW/ObjSQLite3.git",
             "https://github.com/ObjFW/ObjSQLite3.git")

    -- 1.1.3-release
    add_versions("1.1.3", "63a60e0ae5832648b326b98113536abd06158a44")

    add_deps("objfw", "sqlite3")

    if is_host("linux", "macosx") then
        -- autogen.sh uses aclocal, autoconf and autoheader.
        add_deps("autoconf", "automake")
    end

    add_links("objsqlite3")

    on_install("linux", "macosx", function (package)
        local configs = {
            "--disable-shared",
            "--enable-static",
            "--with-sqlite3=" .. package:dep("sqlite3"):installdir()
        }

        import("package.tools.autoconf").install(package, configs, {
            packagedeps = {"sqlite3"}
        })
    end)

    on_test(function (package)
        assert(package:check_msnippets({test = [[
            void test(void) {
                @autoreleasepool {
                    (void)[SL3Connection class];
                }
            }
        ]]}, {
            includes = {"ObjSQLite3/ObjSQLite3.h"}
        }))
    end)
