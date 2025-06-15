if not getexecutorname then getgenv().getexecutorname = function() return "Xeno" end end
if not identifyexecutor then getgenv().identifyexecutor = function() return "Xeno" end end
if not request then 
    if syn and syn.request then 
        getgenv().request = syn.request
    else
        getgenv().request = function() 
            warn("Request function not available!") 
            return {StatusCode = 0}
        end
    end
end

local function SecurityCheck()
    if not game:IsLoaded() then
        warn("Security: Game not loaded!")
        return false
    end
    
    if identifyexecutor and identifyexecutor() ~= "Xeno" then
        warn("Security: Unauthorized executor!")
        return false
    end
    
    return true
end

if not SecurityCheck() then 
    warn("Security check failed. Stopping script.")
    return 
end

local function GetToken()
    local parts = {
        "ghp_",
        "2QlU9iZ8",
        "m6qiJTzR",
        "LWlPUPE9",
        "qrscKz1z",
        "Kdq4"
    }
    return table.concat(parts)
end

local function GetRepoConfig()
    return {
        owner = "Fisterovna2",
        name = "RobloxKeys"
    }
end

local GamesTables = {
    [2753915549] = "BloxFruits",
    [4442272183] = "BloxFruits",
    [7449423635] = "BloxFruits",
    [16732694052] = "Fisch"
}

local function SafeHttpGet(url)
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if not success then
        success, result = pcall(function()
            return game:HttpGetAsync(url, true)
        end)
    end
    
    return success and result or nil
end

local function SendToGitHub(key)
    local config = GetRepoConfig()
    local token = GetToken()
    
    local url = "https://api.github.com/repos/"..config.owner.."/"..config.name.."/issues"
    local headers = {
        ["Authorization"] = "Bearer "..token,
        ["User-Agent"] = "SecureRobloxScript",
        ["Accept"] = "application/vnd.github.v3+json"
    }
    
    local gameName = "Неизвестно"
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    
    local data = {
        title = "Ключ из "..gameName.." - "..os.date("%d.%m.%Y %H:%M"),
        body = "```lua\n-- PlaceID: "..game.PlaceId..
               "\n-- Игра: "..gameName..
               "\n\nKEY = \""..key.."\"\n```"
    }
    
    local json = game:GetService("HttpService"):JSONEncode(data)
    
    local response
    local success, err = pcall(function()
        response = request({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = json
        })
    end)
    
    if not success then
        warn("GitHub request failed: "..tostring(err))
        return false
    end
    
    if response and response.StatusCode == 201 then
        print("Ключ отправлен в GitHub Issues!")
        return true
    else
        local status = response and response.StatusCode or "no response"
        warn("Ошибка отправки: "..tostring(status))
        if response and response.Body then
            warn("Response body: "..tostring(response.Body))
        end
        return false
    end
end

local function ExtractKey(script)
    local patterns = {
        'Key%s*=%s*["\']([^"\']+)["\']',
        'key%s*=%s*["\']([^"\']+)["\']',
        'KEY%s*=%s*["\']([^"\']+)["\']',
        'password%s*=%s*["\']([^"\']+)["\']',
        'getgenv%(%)._key%s*=%s*["\']([^"\']+)["\']'
    }
    
    for _, pattern in ipairs(patterns) do
        local key = script:match(pattern)
        if key and #key > 3 then return key end
    end
end

local function ExecuteGameScript(scriptContent)
    local func, err = loadstring(scriptContent)
    if func then
        local ran, execErr = pcall(func)
        if ran then
            print("Скрипт успешно выполнен!")
            return true
        else
            warn("Ошибка выполнения: "..tostring(execErr))
        end
    else
        warn("Ошибка компиляции: "..tostring(err))
    end
    return false
end

local function MainLoader()
    print("="..string.rep("=", 40))
    print(" Quantum X Loader v3.5 | Xeno Fix")
    print("="..string.rep("=", 40))
    print("Идентификатор игры: "..tostring(game.PlaceId))
    
    local gameData = GamesTables[game.PlaceId]
    if not gameData then
        warn("Игра не поддерживается | PlaceID: "..game.PlaceId)
        return
    end
    print("Игра определена: "..gameData)
    
    local scriptUrl = "https://raw.githubusercontent.com/Trustmenotcondom/QTONYX/main/"..gameData..".lua"
    print("Загрузка скрипта: "..scriptUrl)
    
    local scriptContent = SafeHttpGet(scriptUrl)
    if not scriptContent then
        warn("Ошибка загрузки скрипта")
        return
    end
    print("Размер скрипта: "..#scriptContent.." байт")
    
    local key = ExtractKey(scriptContent)
    if not key then
        warn("Ключ не найден в скрипте")
    else
        print("Найден ключ: "..key)
        
        if SendToGitHub(key) then
            if setclipboard then
                setclipboard(key)
                print("Ключ скопирован в буфер обмена")
            end
        end
    end
    
    if not ExecuteGameScript(scriptContent) then
        warn("Попытка альтернативного запуска...")
        loadstring(scriptContent)()
    end
    
    print("="..string.rep("=", 40))
    print(" Quantum X Loader завершил работу")
    print("="..string.rep("=", 40))
end

local function HandleCacheError()
    if not isfolder then return end
    if not makefolder then return end
    
    pcall(function()
        if not isfolder("xeno_cache_fix") then
            makefolder("xeno_cache_fix")
        end
        writefile("xeno_cache_fix/timestamp.txt", tostring(os.time()))
    end)
end

HandleCacheError()

local success, err = pcall(MainLoader)
if not success then
    warn("Критическая ошибка: "..tostring(err))
end
