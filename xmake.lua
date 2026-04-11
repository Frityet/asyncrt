add_rules("mode.debug", "mode.release", "mode.asan", "mode.tsan")
set_allowedmodes("debug", "release", "asan", "tsan")

set_languages("gnulatest")
set_toolchains("clang")


local function add_flags(...)
    add_cxflags(...)
    return add_mflags(...)
end

add_requires("objfw", {
    configs = {
        shared = false,
        debug = is_mode("debug"),
        --tls = "openssl"
    }
})

add_packages("objfw")

set_warnings("all", "error")

if is_mode("asan") then
    set_policy("build.sanitizer.address", true)
    set_policy("build.sanitizer.undefined", true)
end

if is_mode("tsan") then
    set_policy("build.sanitizer.thread", true)
end

add_flags("-Wall", "-Wextra")
add_flags("-xobjective-c")
add_flags("-fms-extensions", "-Wno-microsoft")


add_flags("-Wno-unused-function")
add_flags (
    "-Wanon-enum-enum-conversion",
    "-Wassign-enum",
    "-Wenum-conversion",
    "-Wenum-enum-conversion"
)
add_flags (
    "-Wnull-dereference",
    "-Wnull-conversion",
    "-Wnullability-completeness",
    "-Wnullable-to-nonnull-conversion",
    "-Wno-auto-var-id",
    "-Wno-compare-distinct-pointer-types" --why the fuck is this a diagnostic?
)
add_flags("-Wno-missing-braces")
if is_plat("linux") then
    add_ldflags("-rdynamic")
    add_flags("-fno-omit-frame-pointer")
end

add_includedirs("src")


target("Utilities")
    set_kind("static")
    set_pmheader("src/Utilities/common.h")
    add_files("src/Utilities/**.m")

target("Async")
    set_kind("static")
    add_deps("Utilities", { public = true })
    add_files("src/Async/Coroutine.m", {mflags = {"-fno-objc-arc"}})
    add_files("src/Async/**.m|src/Async/Coroutine.m")

target("App")
    set_kind("binary")
    add_deps("Async")
    set_pmheader("src/Utilities/common.h")
    add_files("src/App/**.m")

local async_runtime_test_cases = {
    {name = "default_scheduler_lifecycle", group = "sync/scheduler"},
    {name = "coroutine_roundtrip_states", group = "sync/coroutine"},
    {name = "coroutine_return_short_circuits", group = "sync/coroutine"},
    {name = "coroutine_exception_propagation", group = "sync/coroutine"},
    {name = "coroutine_fast_enumeration", group = "sync/coroutine"},
    {name = "coroutine_default_stack_size", group = "sync/coroutine"},
    {name = "future_await_outside_task", group = "sync/future"},
    {name = "future_resolution_guards", group = "sync/future"},
    {name = "future_state_access_guards", group = "sync/future"},
    {name = "future_nil_resolution_and_rejection", group = "sync/future"},
    {name = "async_unit_singleton", group = "sync/runtime"},
    {name = "async_scheduler_invalid_initialization", group = "sync/scheduler"},
    {name = "signal_change_notifications", group = "utilities/signal"},
    {name = "signal_equal_objects_suppress_notifications", group = "utilities/signal"},
    {name = "computed_recomputes_each_access", group = "utilities/signal"},
    {name = "mutex_scoped_lock_unlocks_on_exception", group = "utilities/common"},
    {name = "pointer_basic_data_view", group = "utilities/pointer"},
    {name = "pointer_nullptr_roundtrip", group = "utilities/pointer"},
    {name = "pointer_ordering_and_copying", group = "utilities/pointer"},
    {name = "pointer_compare_against_plain_data", group = "utilities/pointer"},
    {name = "pointer_string_encoding_and_description", group = "utilities/pointer"},
    {name = "optional_from_nillable_nil_is_none", group = "utilities/optional"},
    {name = "optional_roundtrip_equality_and_description", group = "utilities/optional"},
    {name = "optional_some_retains_payload_across_autorelease_pool", group = "utilities/optional"},
    {name = "optional_some_accepts_tagged_payloads", group = "utilities/optional"},
    {name = "argument_parser_binds_nested_command_instances", group = "utilities/argument-parser"},
    {name = "argument_parser_renders_help_text", group = "utilities/argument-parser"},
    {name = "argument_parser_reports_missing_required_positional", group = "utilities/argument-parser"},
    {name = "argument_parser_requires_initialized_cli_nodes", group = "utilities/argument-parser"},
    {name = "future_await_and_protocol", group = "async/future"},
    {name = "future_rejection_paths", group = "async/future"},
    {name = "task_metadata_and_resolution", group = "async/task"},
    {name = "task_returned_nil_exception", group = "async/task"},
    {name = "cross_thread_future_resolution", group = "async/future"},
    {name = "self_await_rejected", group = "async/task"},
    {name = "scope_waits_for_children", group = "async/scope"},
    {name = "scope_failure_cancels_siblings", group = "async/scope"},
    {name = "task_cancellation_checkpoint", group = "async/task"},
    {name = "timeout_cancels_children", group = "async/scope"},
    {name = "past_deadline_fails_immediately", group = "async/scope"},
    {name = "parent_scope_cancellation_propagates", group = "async/scope"},
    {name = "scheduler_offload_roundtrip", group = "async/scheduler"},
    {name = "scheduler_snapshot_waiting_task", group = "async/scheduler"},
    {name = "scheduler_shutdown_rejects_offload", group = "async/scheduler"},
    {name = "scheduler_cancellation_counter", group = "async/scheduler"},
    {name = "scheduler_offload_failure_paths", group = "async/scheduler"},
    {name = "scheduler_sleep_shortcuts", group = "async/scheduler"},
    {name = "channel_rendezvous", group = "async/channel"},
    {name = "channel_buffer_backpressure_and_snapshot", group = "async/channel"},
    {name = "channel_close_semantics", group = "async/channel"},
    {name = "channel_close_unblocks_waiters", group = "async/channel"},
    {name = "channel_send_cancellation", group = "async/channel"},
    {name = "channel_receive_cancellation", group = "async/channel"},
    {name = "channel_multi_producer_consumer", group = "async/channel"},
    {name = "objfw_tcp_stream_wrappers", group = "async/objfw"},
    {name = "objfw_stream_eof_optionals", group = "async/objfw"},
    {name = "objfw_datagram_send_receive", group = "async/objfw"},
    {name = "objfw_stream_buffer_selector_coverage", group = "async/objfw"},
    {name = "objfw_stream_string_cancel_selector_coverage", group = "async/objfw"},
    {name = "objfw_stream_string_encoding_selector_coverage", group = "async/objfw"},
    {name = "objfw_stream_string_encoding_cancel_selector_coverage", group = "async/objfw"},
    {name = "objfw_stream_line_selector_coverage", group = "async/objfw"},
    {name = "objfw_iri_handler_wrappers", group = "async/objfw"},
    {name = "objfw_dns_static_host_resolution", group = "async/objfw"},
    {name = "objfw_tls_client_handshake_failure", group = "async/objfw"},
    {name = "objfw_tls_server_handshake_failure", group = "async/objfw"},
    {name = "objfw_unix_sequenced_packet_wrappers", group = "async/objfw"},
    {name = "objfw_unix_sequenced_packet_cancel_overloads", group = "async/objfw"},
    {name = "objfw_dns_query_local_stub", group = "async/objfw"},
    {name = "objfw_spx_socket_connect_wrappers", group = "async/objfw"},
    {name = "objfw_spx_stream_socket_connect_wrappers", group = "async/objfw"},
    {name = "objfw_sctp_wrapper_methods", group = "async/objfw"},
    {name = "http_concurrent_requests", group = "async/http", timeout = 10},
    {name = "http_timeout_cancellation_and_reuse", group = "async/http", timeout = 10},
    {name = "stress_timeout_repetitions", group = "stress", timeout = 10},
    {name = "stress_channel_repetitions", group = "stress", timeout = 10}
}

target("async-runtime-tests")
    set_kind("binary")
    set_group("tests")
    add_deps("Async")
    set_pmheader("src/Utilities/common.h")
    add_flags(
        "-Wno-nonnull",
        "-Wno-nullability-completeness",
        "-Wno-nullable-to-nonnull-conversion"
    )
    add_links("objfwtest", "objfwhid")
    add_files("src/App/ArgumentParser.m")
    add_files("tests/*.m")
    for _, test_case in ipairs(async_runtime_test_cases) do
        add_tests(test_case.name, {
            group = test_case.group,
            runargs = {"test_" .. test_case.name},
            timeout = test_case.timeout or 5
        })
    end
