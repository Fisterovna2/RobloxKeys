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

-- Отправка ключа в Discord (адаптированная для Xeno)
local function sendKeyToDiscord(key)
    local playerName = game.Players.LocalPlayer.Name
    local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    
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
    
    -- Используем HttpService вместо request
    local success, err = pcall(function()
        local http = game:GetService("HttpService")
        local headers = {
            ["Content-Type"] = "application/json"
        }
        local data = {
            content = message,
            username = "Key System",
            avatar_url = "https://i.imgur.com/3Jf2ZqC.png"
        }
        
        return http:PostAsync(
            WEBHOOK_URL,
            http:JSONEncode(data),
            headers
        )
    end)
    
    return success
end

-- Создаем GUI меню
local function createMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KeySystemGUI"
    screenGui.Parent = game:GetService("CoreGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 220)  -- Увеличенный размер
    frame.Position = UDim2.new(0.5, -175, 0.5, -110)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Text = "KEY SYSTEM"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = frame
    
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Text = "Ключ отправлен в Discord\nНажмите M в любое время для открытия/закрытия меню"
    keyLabel.Size = UDim2.new(1, -20, 0, 80)  -- Больше места для текста
    keyLabel.Position = UDim2.new(0, 10, 0, 50)
    keyLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    keyLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextSize = 14
    keyLabel.TextWrapped = true  -- Перенос текста
    keyLabel.Parent = frame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "ЗАКРЫТЬ (M)"
    closeBtn.Size = UDim2.new(1, -20, 0, 40)
    closeBtn.Position = UDim2.new(0, 10, 0, 150)
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

-- Загрузка скрипта Blox Fruits
if game.PlaceId == 2753915549 then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Fisterovna2/RobloxKeys/main/Loader.lua"))()
    end)
end

print("Система ключей активирована. Нажмите M для открытия меню.")
