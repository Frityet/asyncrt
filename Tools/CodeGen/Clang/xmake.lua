target("AsyncRT.Tools.CodeGen.Clang", function()
    set_kind("static")
    add_packages("objfw")
    add_deps("AsyncRT.Core", "AsyncRT.Common",
        "AsyncRT.Tools.OCGen.Schema")
    add_includedirs("src", { public = true })
    add_files("src/*.m")
end)
