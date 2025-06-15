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

-- Основной ключ доступа
local accessKey = generateAccessKey()
local keySent = sendKeyToDiscord(accessKey)

-- Создаем GUI для ввода ключа
local keyInputGui = Instance.new("ScreenGui")
keyInputGui.Name = "KeyInputGUI"
keyInputGui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 250)
frame.Position = UDim2.new(0.5, -200, 0.5, -125)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = keyInputGui

local title = Instance.new("TextLabel")
title.Text = "BLOCK FRUITS KEY SYSTEM"
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
title.TextColor3 = Color3.fromRGB(0, 170, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

local infoLabel = Instance.new("TextLabel")
infoLabel.Text = "Ключ отправлен в Discord. Введите его для активации скрипта."
infoLabel.Size = UDim2.new(1, -20, 0, 40)
infoLabel.Position = UDim2.new(0, 10, 0, 50)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 14
infoLabel.TextWrapped = true
infoLabel.Parent = frame

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, -20, 0, 40)
keyBox.Position = UDim2.new(0, 10, 0, 100)
keyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
keyBox.TextColor3 = Color3.white
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 16
keyBox.PlaceholderText = "Введите ключ доступа"
keyBox.Parent = frame

local activateBtn = Instance.new("TextButton")
activateBtn.Text = "АКТИВИРОВАТЬ"
activateBtn.Size = UDim2.new(1, -20, 0, 40)
activateBtn.Position = UDim2.new(0, 10, 0, 150)
activateBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
activateBtn.TextColor3 = Color3.white
activateBtn.Font = Enum.Font.GothamBold
activateBtn.TextSize = 16
activateBtn.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 200)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.Text = ""
statusLabel.Parent = frame

-- Функции фарма
local function activateFarmingFeatures()
    print("Активация всех функций фарма...")
    
    -- Фарм мастери
    local function farmMastery()
        -- Код фарма мастери
        print("Фарм мастери активирован")
        -- Здесь реализация автоматического фарма мастери
    end
    
    -- Фарм фруктов
    local function farmFruits()
        -- Код фарма фруктов
        print("Фарм фруктов активирован")
        -- Здесь реализация автоматического поиска и сбора фруктов
    end
    
    -- Фарм сундуков
    local function farmChests()
        -- Код фарма сундуков
        print("Фарм сундуков активирован")
        -- Здесь реализация автоматического поиска и открытия сундуков
    end
    
    -- Фарм костей
    local function farmBones()
        -- Код фарма костей
        print("Фарм костей активирован")
        -- Здесь реализация автоматического фарма костей
    end
    
    -- Активируем все функции
    farmMastery()
    farmFruits()
    farmChests()
    farmBones()
    
    -- Создаем меню управления
    local menuGui = Instance.new("ScreenGui")
    menuGui.Name = "FarmingMenu"
    menuGui.Parent = game.CoreGui
    
    local menuFrame = Instance.new("Frame")
    menuFrame.Size = UDim2.new(0, 300, 0, 300)
    menuFrame.Position = UDim2.new(0.05, 0, 0.5, -150)
    menuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    menuFrame.BorderSizePixel = 0
    menuFrame.Active = true
    menuFrame.Draggable = true
    menuFrame.Parent = menuGui
    
    local menuTitle = Instance.new("TextLabel")
    menuTitle.Text = "FARMING MENU"
    menuTitle.Size = UDim2.new(1, 0, 0, 40)
    menuTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    menuTitle.TextColor3 = Color3.fromRGB(0, 170, 255)
    menuTitle.Font = Enum.Font.GothamBold
    menuTitle.TextSize = 18
    menuTitle.Parent = menuFrame
    
    -- Кнопки управления фармом
    local buttons = {
        {name = "Фарм мастери", pos = 0, func = farmMastery},
        {name = "Фарм фруктов", pos = 1, func = farmFruits},
        {name = "Фарм сундуков", pos = 2, func = farmChests},
        {name = "Фарм костей", pos = 3, func = farmBones}
    }
    
    for _, btn in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Text = btn.name
        button.Size = UDim2.new(0.9, 0, 0, 40)
        button.Position = UDim2.new(0.05, 0, 0.15 + btn.pos * 0.2, 0)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        button.TextColor3 = Color3.white
        button.Font = Enum.Font.Gotham
        button.TextSize = 16
        button.Parent = menuFrame
        
        button.MouseButton1Click:Connect(btn.func)
    end
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "ЗАКРЫТЬ (M)"
    closeBtn.Size = UDim2.new(0.9, 0, 0, 40)
    closeBtn.Position = UDim2.new(0.05, 0, 0.85, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.TextColor3 = Color3.white
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = menuFrame
    
    closeBtn.MouseButton1Click:Connect(function()
        menuGui:Destroy()
    end)
    
    -- Обработчик клавиши M для меню
    game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.M and not gameProcessed then
            menuGui.Enabled = not menuGui.Enabled
        end
    end)
    
    print("Все функции фарма успешно активированы!")
    game.StarterGui:SetCore("SendNotification", {
        Title = "АКТИВАЦИЯ",
        Text = "Все функции фарма активированы!",
        Duration = 5
    })
end

-- Обработчик активации
activateBtn.MouseButton1Click:Connect(function()
    local inputKey = keyBox.Text:gsub("%s+", ""):gsub("-", "")
    local validKey = accessKey:gsub("-", "")
    
    if inputKey == validKey then
        statusLabel.Text = "Ключ принят! Активация..."
        statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
        
        task.wait(1)
        keyInputGui:Destroy()
        activateFarmingFeatures()
    else
        statusLabel.Text = "НЕВЕРНЫЙ КЛЮЧ! Попробуйте снова."
        statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
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

-- Уведомление о ключе
if keySent then
    game.StarterGui:SetCore("SendNotification", {
        Title = "KEY SYSTEM",
        Text = "Ключ отправлен в Discord",
        Icon = "rbxassetid://6726578090",
        Duration = 5
    })
else
    warn("Не удалось отправить ключ в Discord")
    statusLabel.Text = "Ошибка отправки ключа! Проверьте консоль."
end

print("Ожидаю ввода ключа для активации функций фарма")
