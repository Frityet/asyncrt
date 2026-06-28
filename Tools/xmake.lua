
target("AsyncRT.Tools.ClassDump", function ()
    set_kind("binary")
    set_basename("classdump")
    add_deps("AsyncRT.Core", "AsyncRT.Common")
    add_packages("objfw")
    add_files("ClassDump/**.m")
end)
