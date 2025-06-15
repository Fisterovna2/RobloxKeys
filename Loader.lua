repeat task.wait() until game:IsLoaded()

-- Ваш Discord Webhook
local WEBHOOK_URL = "https://discord.com/api/webhooks/1383438112591712277/7GmcmWLoXouzc7ly9IF01A_Ls9hHQJ7ek-Swoxa1SKQKexC9kYQzwuH75gg47_RG-ZG4"

-- Генерация ключа в формате LootLabs
local function generateAccessKey()
    local charset = "abcdef0123456789" -- Только hex символы
    local key = ""
    for i = 1, 32 do
        if i == 9 or i == 13 or i == 17 or i == 21 then
            key = key .. "-"
        else
            local rand = math.random(1, #charset)
            key = key .. charset:sub(rand, rand)
        end
    end
    return key
end

-- Отправка ключа в Discord
local function sendKeyToDiscord(key)
    local playerName = game.Players.LocalPlayer.Name
    local gameName = "Blox Fruits"
    
    local message = string.format(
        "**НОВЫЙ КЛЮЧ ДОСТУПА**\n"..
        "```diff\n"..
        "+ Игрок: %s\n"..
        "+ Игра: %s\n"..
        "+ Место ID: %d\n"..
        "------------------------\n"..
        "Ключ: ||%s||\n```",
        playerName, gameName, game.PlaceId, key
    )
    
    local success, response = pcall(function()
        return request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = game:GetService("HttpService"):JSONEncode({
                content = message,
                username = "Blox Fruits Key System",
                avatar_url = "https://tr.rbxcdn.com/0dac99e0e4cbc0b0e1e8c7b5c9a2d3b8/150/150/Image/Png"
            })
        })
    end)
    
    return success
end

-- Создаем GUI меню
local function createMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BFKeySystem"
    screenGui.Parent = game.CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 220)
    frame.Position = UDim2.new(0.5, -175, 0.5, -110)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Text = "BLOCK FRUITS KEY SYSTEM"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    title.TextColor3 = Color3.fromRGB(0, 170, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame
    
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Text = "Ключ отправлен в Discord"
    keyLabel.Size = UDim2.new(1, -20, 0, 60)
    keyLabel.Position = UDim2.new(0, 10, 0, 50)
    keyLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    keyLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextSize = 16
    keyLabel.TextWrapped = true
    keyLabel.Parent = frame
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Text = "Нажмите M в любое время, чтобы открыть/закрыть это меню"
    infoLabel.Size = UDim2.new(1, -20, 0, 30)
    infoLabel.Position = UDim2.new(0, 10, 0, 120)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 12
    infoLabel.Parent = frame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "ЗАКРЫТЬ (M)"
    closeBtn.Size = UDim2.new(1, -20, 0, 40)
    closeBtn.Position = UDim2.new(0, 10, 0, 160)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.TextColor3 = Color3.white
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = frame
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    return screenGui
end

-- Основной поток
local accessKey = generateAccessKey()
local keySent = sendKeyToDiscord(accessKey)

if keySent then
    print("Ключ отправлен в Discord: " .. accessKey)
    
    game.StarterGui:SetCore("SendNotification", {
        Title = "KEY SYSTEM",
        Text = "Ключ отправлен в Discord",
        Icon = "rbxassetid://6726578090",
        Duration = 5
    })
else
    warn("Не удалось отправить ключ в Discord")
end

-- Система меню
local menuGui = nil
local menuVisible = false

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.M and not gameProcessed then
        menuVisible = not menuVisible
        
        if menuVisible then
            if not menuGui or menuGui.Parent == nil then
                menuGui = createMenu()
            end
        else
            if menuGui then
                menuGui:Destroy()
                menuGui = nil
            end
        end
    end
end)

-- Блокировка нежелательных исполнителей
local executorname = "Unknown"
if getexecutorname then
    executorname = getexecutorname()
elseif identifyexecutor then
    executorname = identifyexecutor()
end

local FAKE_EXECUTOR = { "xeno", "jjsploit" }
for _, v in ipairs(FAKE_EXECUTOR) do
    if executorname:lower():find(v) then
        game.Players.LocalPlayer:Kick("\n\n" .. executorname .. " не поддерживается")
        return
    end
end

-- Загрузка скрипта Blox Fruits
if game.PlaceId == 2753915549 or game.GameId == 994732206 then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Fisterovna2/RobloxKeys/main/Loader.lua"))()
    end)
end

print("Система ключей активирована. Нажмите M для открытия меню.")
