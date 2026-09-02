
target("AsyncRT.Example", function ()
    set_kind("binary")
    add_packages("objfw")
    add_files("src/*.m")
    add_deps("AsyncRT.Core", "AsyncRT.Common")
end)
