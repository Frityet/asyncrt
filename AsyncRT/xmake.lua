includes("Common", "Core", "Application/Core", "Application/Terminal", "Networking/HTTP")

if has_config("asyncrt-db") then
    includes("Database")
end

if has_config("asyncrt-ui") then
    includes("Application/UI")
end

if has_config("asyncrt-webui") then
    includes("Application/WebUI")
end

