target("AsyncRT.Tools.OCGen", function()
    set_kind("binary")
    set_filename("ocgen")
    add_packages("objfw")
    add_deps("AsyncRT.Core", "AsyncRT.Common", "AsyncRT.IO",
        "AsyncRT.Tools.OCGen.Schema")
    add_files("src/*.m")

    on_load(function(target)
        target:add("runenvs", "ASYNC_RUNTIME_PROJECT_DIR", os.projectdir())
    end)
end)

includes("Schema")
