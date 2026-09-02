target("AsyncRT.Tools.CodeGen", function()
    set_kind("binary")
    set_filename("codegen")
    add_packages("objfw")
    add_deps("AsyncRT.Core", "AsyncRT.Common", "AsyncRT.IO")
    add_deps("AsyncRT.Tools.CodeGen.Clang")
    add_files("src/*.m")

    on_load(function(target)
        target:add("runenvs", "ASYNC_RUNTIME_PROJECT_DIR", os.projectdir())
    end)
end)

includes("Clang")
