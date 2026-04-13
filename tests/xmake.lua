local async_runtime_test_cases = {
    {name = "default_scheduler_lifecycle", group = "sync/scheduler"},
    {name = "coroutine_roundtrip_states", group = "sync/coroutine"},
    {name = "coroutine_return_short_circuits", group = "sync/coroutine"},
    {name = "coroutine_exception_propagation", group = "sync/coroutine"},
    {name = "coroutine_fast_enumeration", group = "sync/coroutine"},
    {name = "coroutine_default_stack_size", group = "sync/coroutine"},
    {name = "coroutine_guard_and_common_coverage", group = "sync/coroutine"},
    {name = "runtime_internal_description_coverage", group = "sync/runtime"},
    {name = "scheduler_channel_private_branches", group = "sync/runtime"},
    {name = "utility_internal_branch_coverage", group = "sync/runtime"},
    {name = "task_await_outside_task", group = "sync/task"},
    {name = "task_resolution_guards", group = "sync/task"},
    {name = "task_state_access_guards", group = "sync/task"},
    {name = "task_nil_resolution_and_rejection", group = "sync/task"},
    {name = "task_continuation_scheduler_requirements", group = "sync/task"},
    {name = "async_unit_singleton", group = "sync/runtime"},
    {name = "async_scheduler_invalid_initialization", group = "sync/scheduler"},
    {name = "pointer_basic_data_view", group = "utilities/pointer"},
    {name = "pointer_nullptr_roundtrip", group = "utilities/pointer"},
    {name = "pointer_ordering_and_copying", group = "utilities/pointer"},
    {name = "pointer_compare_against_plain_data", group = "utilities/pointer"},
    {name = "pointer_string_encoding_and_description", group = "utilities/pointer"},
    {name = "optional_from_nillable_nil_is_none", group = "utilities/optional"},
    {name = "optional_roundtrip_equality_and_description", group = "utilities/optional"},
    {name = "optional_some_retains_payload_across_autorelease_pool", group = "utilities/optional"},
    {name = "optional_some_accepts_tagged_payloads", group = "utilities/optional"},
    {name = "hook_state_updates_request_render_only_on_change", group = "ui"},
    {name = "keyed_child_components_retain_state_across_reorder", group = "ui"},
    {name = "editable_text_focus_persists_across_conditional_insertion", group = "ui"},
    {name = "effect_cleanup_runs_on_dependency_change_and_unmount", group = "ui"},
    {name = "context_menu_attachment_opens_and_activates", group = "ui"},
    {name = "argument_parser_binds_nested_command_instances", group = "utilities/argument-parser"},
    {name = "argument_parser_renders_help_text", group = "utilities/argument-parser"},
    {name = "argument_parser_reports_missing_required_positional", group = "utilities/argument-parser"},
    {name = "argument_parser_requires_initialized_cli_nodes", group = "utilities/argument-parser"},
    {name = "argument_parser_internal_helpers", group = "utilities/argument-parser"},
    {name = "argument_parser_error_branches", group = "utilities/argument-parser"},
    {name = "argument_parser_schema_validation", group = "utilities/argument-parser"},
    {name = "calculator_evaluator_scientific_ops", group = "app/calculator"},
    {name = "calculator_model_memory_and_history", group = "app/calculator"},
    {name = "task_await_and_awaitable", group = "async/task"},
    {name = "task_rejection_paths", group = "async/task"},
    {name = "task_combinators", group = "async/task"},
    {name = "task_continuation_scheduler_capture", group = "async/task"},
    {name = "task_collection_helpers", group = "async/task"},
    {name = "task_continuation_and_scope_internal_branches", group = "async/task"},
    {name = "task_metadata_and_resolution", group = "async/task"},
    {name = "task_returned_nil_exception", group = "async/task"},
    {name = "cross_thread_task_resolution", group = "async/task"},
    {name = "self_await_rejected", group = "async/task"},
    {name = "scope_waits_for_children", group = "async/scope"},
    {name = "scope_failure_cancels_siblings", group = "async/scope"},
    {name = "scope_spawn_all", group = "async/scope"},
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
    {name = "http_concurrent_requests", group = "async/http", timeout = 10},
    {name = "http_timeout_cancellation_and_reuse", group = "async/http", timeout = 10},
    {name = "stress_timeout_repetitions", group = "stress", timeout = 10},
    {name = "stress_channel_repetitions", group = "stress", timeout = 10}
}

target("async-runtime-tests")
    set_kind("binary")
    set_group("tests")
    add_deps("AsyncRTUITest")
    set_pmheader("../src/Utilities/common.h")
    add_defines("ASYNC_RUNTIME_TEST_BUILD")
    if is_plat("macosx") then
        add_ldflags("-ObjC", {force = true})
    end
    add_cxflags(
        "-Wno-nonnull",
        "-Wno-nullability-completeness",
        "-Wno-nullable-to-nonnull-conversion"
    )
    add_mflags(
        "-Wno-nonnull",
        "-Wno-nullability-completeness",
        "-Wno-nullable-to-nonnull-conversion"
    )
    add_links("objfwtest", "objfwhid")
    add_files(
        "../src/App/ArgumentParser.m",
        "../src/App/CalculatorEvaluator.m",
        "../src/App/CalculatorModel.m"
    )
    add_files("*.m")
    for _, test_case in ipairs(async_runtime_test_cases) do
        add_tests(test_case.name, {
            group = test_case.group,
            runargs = {"test_" .. test_case.name},
            timeout = test_case.timeout or 5
        })
    end
