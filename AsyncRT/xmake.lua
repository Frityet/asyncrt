includes("Utilities", "Async")

if has_config("asyncrt-db") then
    includes("ObjDB")
end

if has_config("asyncrt-ui") then
    includes("UI")
end

if has_config("asyncrt-app") and has_config("asyncrt-ui") then
    includes("App")
end

if has_config("asyncrt-test-support") then
    includes("TestSupport")
end
