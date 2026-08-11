local coroutine_test_source = "CoroutineTests.m"

local function discover_objfw_tests(source, sourcefile)
    local tests = {}
    local seen = {}

    for test in source:gmatch("%-%s*%(%s*void%s*%)%s*(test[%w_]+)%s*%{") do
        if not seen[test] then
            table.insert(tests, test)
            seen[test] = true
        end
    end

    if #tests == 0 then
        raise("no ObjFWTest methods discovered in " .. sourcefile)
    end
    return tests
end

target("AsyncRT.Tests.Core.Coroutine", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/core")
    add_deps("AsyncRT.Core", "AsyncRT.Common")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files(coroutine_test_source, {
        mflags = { "-fno-objc-arc" }
    })

    on_load(function (target)
        local sourcefile = path.join(os.scriptdir(), coroutine_test_source)
        local source = io.readfile(sourcefile)
        for _, test in ipairs(discover_objfw_tests(source, sourcefile)) do
            target:add("tests", test, {
                group = "core/coroutine",
                runargs = { test },
                run_timeout = 5000
            })
        end
    end)
end)

target("AsyncRT.Tests.Core.AsyncTask", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/core")
    add_deps("AsyncRT.Core", "AsyncRT.Common")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("AsyncTaskTests.m", {
        mflags = { "-fno-objc-arc" }
    })

    on_load(function (target)
        target:add("tests", "AsyncTaskTests", {
            group = "core/asynctask",
            run_timeout = 5000
        })
    end)
end)

target("AsyncRT.Tests.Core.AsyncExecutor", function ()
    set_kind("binary")
    set_default(false)
    set_group("tests/core")
    add_deps("AsyncRT.Core", "AsyncRT.Common")
    add_packages("objfw")
    add_links("objfwtest")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    add_files("AsyncExecutorTests.m")

    on_load(function (target)
        target:add("tests", "AsyncExecutorTests", {
            group = "core/executor",
            run_timeout = 5000
        })
    end)
end)
