target("AsyncRT.Core", function ()
    set_kind("static")
    add_deps("AsyncRT.Common")
    add_packages("objfw")
    add_includedirs("src", { public = true })
    add_headerfiles("src/(*.h)")
    add_files("src/*.m|src/Coroutine.m")
    add_files("src/Coroutine.m", {
        mflags = { "-fno-objc-arc" }
    })
end)
