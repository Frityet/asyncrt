local common = asyncrt_build

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
        files = {"tests/AsyncRuntimeTests.m", "../UI/tests/TestCasesUI.m"}
    },
    {
        name = "app_calculator",
        class = "AsyncRuntimeAppCalculatorTests",
        group = "app/calculator",
        files = {"tests/AsyncRuntimeTests.m", "../App/tests/TestCasesAppCalculator.m"}
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

local function configure_async_runtime_test_target(name, suite)
    target(name)
        set_default(false)
        set_kind("binary")
        set_group("tests")
        add_deps("AsyncRTTestSupport")
        common.add_internal_test_access_define()
        before_build(function ()
            if common.internal_test_access_enabled() then
                return
            end

            raise(name .. " requires xmake f -m test, xmake check, or explicit --asyncrt-test-access=y.")
        end)
        if is_plat("macosx") then
            add_ldflags("-ObjC", {force = true})
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
        add_links("objfwtest", "objfwhid")
        add_files(table.unpack(suite.files))
        add_tests("default", {
            group = suite.group,
            runargs = {suite.class},
            timeout = suite.timeout or 5
        })
end

target("AsyncRTTestSupport")
    set_default(false)
    set_kind("static")
    add_deps("AsyncRTAppSupport", { public = true })
    add_includedirs("src", { public = true })
    common.add_internal_test_access_define()
    add_files("src/*.m")

for _, test_suite in ipairs(async_runtime_test_suites) do
    local test_target_name = "async-runtime-tests-" .. test_suite.name
    table.insert(async_runtime_test_target_names, test_target_name)
    configure_async_runtime_test_target(test_target_name, test_suite)
end

target("async-runtime-tests")
    set_default(false)
    set_kind("phony")
    set_group("tests")
    add_deps(table.unpack(async_runtime_test_target_names))
