local async_runtime_test_suites = {
    {
        name = "utilities",
        class = "AsyncRuntimeUtilitiesTests",
        group = "utilities",
        files = {"tests/AsyncRuntimeTests.m", "../Utilities/tests/TestCasesUtilities.m"}
    },
    {
        name = "argument_parser",
        class = "AsyncRuntimeArgumentParserTests",
        group = "utilities/argument-parser",
        files = {"tests/AsyncRuntimeTests.m", "../Utilities/tests/TestCasesArgumentParser.m"}
    },
    {
        name = "sync",
        class = "AsyncRuntimeSyncTests",
        group = "sync",
        timeout = 20,
        files = {"tests/AsyncRuntimeTests.m", "../Async/tests/TestCasesSync.m"}
    },
    {
        name = "async_task",
        class = "AsyncRuntimeTaskTests",
        group = "async/task",
        timeout = 60,
        files = {"tests/AsyncRuntimeTests.m", "../Async/tests/TestCasesAsync.m"}
    },
    {
        name = "async_scope",
        class = "AsyncRuntimeScopeTests",
        group = "async/scope",
        timeout = 60,
        files = {"tests/AsyncRuntimeTests.m", "../Async/tests/TestCasesAsync.m"}
    },
    {
        name = "async_scheduler",
        class = "AsyncRuntimeSchedulerTests",
        group = "async/scheduler",
        timeout = 60,
        files = {"tests/AsyncRuntimeTests.m", "../Async/tests/TestCasesAsync.m"}
    },
    {
        name = "async_channel",
        class = "AsyncRuntimeChannelTests",
        group = "async/channel",
        timeout = 60,
        files = {"tests/AsyncRuntimeTests.m", "../Async/tests/TestCasesAsync.m"}
    },
    {
        name = "async_http",
        class = "AsyncRuntimeHTTPTests",
        group = "async/http",
        timeout = 30,
        files = {"tests/AsyncRuntimeTests.m", "../Async/tests/TestCasesAsync.m"}
    },
    {
        name = "stress",
        class = "AsyncRuntimeStressTests",
        group = "stress",
        timeout = 30,
        files = {"tests/AsyncRuntimeTests.m", "../Async/tests/TestCasesAsync.m"}
    },
    {
        name = "ui",
        class = "AsyncRuntimeUITests",
        group = "ui",
        timeout = 30,
        deps = {"AsyncRTUI"},
        files = {"tests/AsyncRuntimeTests.m", "../UI/tests/TestCasesUI.m"}
    },
    {
        name = "app",
        class = "AsyncRuntimeAppTests",
        group = "app",
        deps = {"AsyncRTAppSupport"},
        files = {"tests/AsyncRuntimeTests.m", "../App/tests/TestCasesApp.m"}
    },
    {
        name = "objdb",
        class = "AsyncRuntimeObjDBTests",
        group = "objdb",
        deps = {"ObjDB", "ObjDBSQLite"},
        files = {"tests/AsyncRuntimeTests.m", "../ObjDB/tests/TestCasesObjDB.m"}
    },
    {
        name = "coverage",
        class = "AsyncRuntimeCoverageTests",
        group = "coverage",
        timeout = 30,
        files = {"tests/AsyncRuntimeTests.m", "tests/TestCasesCoverage.m"}
    },
    {
        name = "coverage_extras",
        class = "AsyncRuntimeCoverageExtrasTests",
        group = "coverage/extras",
        timeout = 60,
        files = {"tests/AsyncRuntimeTests.m", "tests/TestCasesCoverageExtras.m"}
    }
}

local async_runtime_test_target_names = {}
local enabled_async_runtime_test_suites = {}

for _, test_suite in ipairs(async_runtime_test_suites) do
    local include_suite = true

    if test_suite.name == "ui" then
        include_suite = has_config("asyncrt-ui")
    elseif test_suite.name == "app" then
        include_suite = has_config("asyncrt-app") and has_config("asyncrt-ui")
    elseif test_suite.name == "objdb" then
        include_suite = has_config("asyncrt-db")
    end

    if include_suite then
        table.insert(enabled_async_runtime_test_suites, test_suite)
    end
end

async_runtime_test_suites = enabled_async_runtime_test_suites

target("AsyncRTTestSupport", function ()
    set_default(false)
    set_kind("static")
    add_deps("AsyncRT", { public = true })
    add_includedirs("src", { public = true })
    if is_mode("test") or has_config("asyncrt-test-access") then
        add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
    end
    add_files("src/*.m")
end)

for _, test_suite in ipairs(async_runtime_test_suites) do
    local test_target_name = "async-runtime-tests-" .. test_suite.name
    table.insert(async_runtime_test_target_names, test_target_name)

    target(test_target_name, function ()
        set_default(false)
        set_kind("binary")
        set_group("tests")
        add_deps("AsyncRTTestSupport")
        if is_mode("test") or has_config("asyncrt-test-access") then
            add_defines("ASYNC_RUNTIME_TEST_BUILD", { public = true })
        end
        before_build(function ()
            if is_mode("test") or has_config("asyncrt-test-access") then
                return
            end

            raise(test_target_name .. " requires xmake f -m test, xmake check, or explicit --asyncrt-test-access=y.")
        end)
        if is_plat("macosx") then
            add_ldflags("-ObjC", {force = true})
        end
        if test_suite.deps ~= nil then
            add_deps(table.unpack(test_suite.deps))
        end
        add_cxflags(
            "-Wno-nonnull",
            "-Wno-nullability-completeness",
            "-Wno-nullable-to-nonnull-conversion",
            {force = true}
        )
        add_mflags(
            "-Wno-nonnull",
            "-Wno-nullability-completeness",
            "-Wno-nullable-to-nonnull-conversion",
            {force = true}
        )
        add_links("objfwtest")
        add_files(table.unpack(test_suite.files))
        add_tests("default", {
            group = test_suite.group,
            runargs = {test_suite.class},
            timeout = test_suite.timeout or 5
        })
    end)
end

target("async-runtime-tests", function ()
    set_default(false)
    set_kind("phony")
    set_group("tests")
    add_deps(table.unpack(async_runtime_test_target_names))
end)
