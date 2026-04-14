import("core.base.task")
import("lib.detect.find_tool")

local function _coalesce(...)
    for _, value in ipairs({...}) do
        if value ~= nil and value ~= "" then
            return value
        end
    end
end

local function _resolve_tool(toolname, env_name, override, fallback_programs)
    local explicit = _coalesce(override, os.getenv(env_name))
    if explicit then
        return explicit
    end

    local tool = find_tool(toolname)
    if tool then
        return tool.program
    end

    for _, program in ipairs(fallback_programs or {}) do
        tool = find_tool(toolname, {program = program})
        if tool then
            return tool.program
        end
    end

    raise("Unable to find %s. Set %s or pass the matching xmake coverage option.", toolname, env_name)
end

local function _append_all(destination, values)
    for _, value in ipairs(values) do
        table.insert(destination, value)
    end
end

local function _source_files(projectdir)
    local files = {}
    local excluded_patterns = {
        "^AsyncRT/UI/src/Backend/",
        "^AsyncRT/Async/src/AsyncApplication%.m$",
        "^AsyncRT/UI/src/AUIExceptions%.m$"
    }

    local function is_excluded(relative)
        for _, pattern in ipairs(excluded_patterns) do
            if relative:match(pattern) then
                return true
            end
        end

        return false
    end

    for _, pattern in ipairs({
        path.join(projectdir, "AsyncRT", "Utilities", "src", "**.m"),
        path.join(projectdir, "AsyncRT", "Async", "src", "**.m"),
        path.join(projectdir, "AsyncRT", "UI", "src", "**.m"),
        path.join(projectdir, "AsyncRT", "App", "src", "**.m")
    }) do
        for _, file in ipairs(os.files(pattern)) do
            if path.filename(file) == "main.m" then
                goto continue
            end

            local relative = path.relative(file, projectdir)
            if is_excluded(relative) then
                goto continue
            end

            table.insert(files, relative)
            ::continue::
        end
    end
    table.sort(files)
    return files
end

local function _find_test_binary(builddir)
    local matches = os.files(path.join(builddir, "**", "async-runtime-tests"))
    assert(#matches > 0, ("Unable to locate async-runtime-tests under %s."):format(builddir))
    table.sort(matches)
    return matches[1]
end

local function _extract_total_line_coverage(report_output)
    for line in report_output:gmatch("[^\r\n]+") do
        local fields = {}

        for field in line:gmatch("%S+") do
            table.insert(fields, field)
        end

        if fields[1] == "TOTAL" and fields[10] ~= nil then
            local percentage = fields[10]:gsub("%%", "")
            return tonumber(percentage)
        end
    end
end

function main(options)
    options = options or {}

    local projectdir = os.projectdir()
    local builddir = path.absolute(_coalesce(options.build_dir, os.getenv("BUILD_DIR"), "build-coverage"), projectdir)
    local profilesdir = path.join(builddir, "profiles")
    local profdata = path.join(builddir, "coverage.profdata")
    local reportpath = path.join(builddir, "coverage-report.txt")
    local minimum = tonumber(_coalesce(options.minimum, os.getenv("MIN_LINE_COVERAGE"), "90"))
    local llvm_cov = _resolve_tool("llvm-cov", "LLVM_COV", options.llvm_cov, {
        "/usr/local/opt/llvm/bin/llvm-cov",
        "/opt/homebrew/opt/llvm/bin/llvm-cov"
    })
    local llvm_profdata = _resolve_tool("llvm-profdata", "LLVM_PROFDATA", options.llvm_profdata, {
        "/usr/local/opt/llvm/bin/llvm-profdata",
        "/opt/homebrew/opt/llvm/bin/llvm-profdata"
    })
    local source_files = _source_files(projectdir)
    local targetfile
    local profraw_files
    local merge_args
    local report_args
    local report_output
    local line_coverage

    assert(minimum ~= nil, "Minimum line coverage must be numeric.")

    print("Configuring coverage build in " .. builddir)
    os.rm(builddir)
    os.mkdir(profilesdir)

    task.run("config", {
        clean = true,
        mode = "coverage",
        builddir = builddir,
        asyncrt_test_access = true
    })
    task.run("build", {group = "tests"})

    targetfile = _find_test_binary(builddir)

    print("Running coverage-mode tests through xmake test")
    os.setenv("LLVM_PROFILE_FILE", path.join(profilesdir, "%p.profraw"))
    task.run("test")
    os.setenv("LLVM_PROFILE_FILE", nil)

    profraw_files = os.files(path.join(profilesdir, "*.profraw"))
    assert(#profraw_files > 0, "Coverage run completed without producing any .profraw files.")
    table.sort(profraw_files)

    merge_args = {"merge", "-sparse"}
    _append_all(merge_args, profraw_files)
    table.insert(merge_args, "-o")
    table.insert(merge_args, profdata)
    os.execv(llvm_profdata, merge_args, {curdir = projectdir})

    report_args = {"report", targetfile, "-instr-profile=" .. profdata}
    _append_all(report_args, source_files)
    report_output = os.iorunv(llvm_cov, report_args, {curdir = projectdir})
    io.writefile(reportpath, report_output)
    print(report_output)

    line_coverage = _extract_total_line_coverage(report_output)
    assert(line_coverage ~= nil, "Unable to parse total line coverage from llvm-cov output.")

    if line_coverage < minimum then
        raise("Line coverage %.2f%% is below required minimum %.2f%%.", line_coverage, minimum)
    end

    print(("Line coverage %.2f%% meets minimum %.2f%%. Report saved to %s"):format(line_coverage, minimum, reportpath))
end
