repeat task.wait() until game:IsLoaded()

-- Ваш Discord Webhook
local WEBHOOK_URL = "https://discord.com/api/webhooks/1383438112591712277/7GmcmWLoXouzc7ly9IF01A_Ls9hHQJ7ek-Swoxa1SKQKexC9kYQzwuH75gg47_RG-ZG4"

-- Генерация ключа в формате LootLabs
local function generateAccessKey()
    local charset = "abcdef0123456789"
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

-- Универсальная функция отправки запроса
local function sendHttpRequest(url, data)
    local requestFunc = syn and syn.request or http and http.request or http_request
    if requestFunc then
        return pcall(function()
            return requestFunc({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = game:GetService("HttpService"):JSONEncode(data)
            })
        end)
    end
    return false
end

-- Отправка ключа в Discord
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
    
    return sendHttpRequest(WEBHOOK_URL, {
        content = message,
        username = "Key System",
        avatar_url = "https://i.imgur.com/3Jf2ZqC.png"
    })
end

-- Глобальное состояние
local accessKey = generateAccessKey()
local keySent = sendKeyToDiscord(accessKey)
local activated = false
local activationGui = nil
local farmingGui = nil

-- Функции фарма (состояния)
local farmingModules = {
    mastery = false,
    fruits = false,
    chests = false,
    bones = false
}

-- Создаем GUI для активации
local function createActivationGui()
    if activationGui then activationGui:Destroy() end
    
    activationGui = Instance.new("ScreenGui")
    activationGui.Name = "ActivationGUI"
    activationGui.Parent = game:GetService("CoreGui")
    activationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Основной фрейм
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 250)
    frame.Position = UDim2.new(0.5, -200, 0.5, -125)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.ZIndex = 10
    frame.Parent = activationGui
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Text = "АКТИВАЦИЯ СИСТЕМЫ"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.ZIndex = 11
    title.Parent = frame
    
    -- Информационная метка
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Text = "Ключ отправлен в Discord. Введите его для активации системы:"
    infoLabel.Size = UDim2.new(1, -20, 0, 40)
    infoLabel.Position = UDim2.new(0, 10, 0, 50)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 14
    infoLabel.TextWrapped = true
    infoLabel.ZIndex = 11
    infoLabel.Parent = frame
    
    -- Поле для ввода ключа
    local keyBox = Instance.new("TextBox")
    keyBox.Name = "KeyInputBox"
    keyBox.Size = UDim2.new(1, -20, 0, 40)
    keyBox.Position = UDim2.new(0, 10, 0, 100)
    keyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    keyBox.TextColor3 = Color3.white
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 16
    keyBox.PlaceholderText = "Введите ключ доступа"
    keyBox.ZIndex = 11
    keyBox.Parent = frame
    
    -- Кнопка активации
    local activateBtn = Instance.new("TextButton")
    activateBtn.Text = "АКТИВИРОВАТЬ"
    activateBtn.Size = UDim2.new(1, -20, 0, 40)
    activateBtn.Position = UDim2.new(0, 10, 0, 150)
    activateBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    activateBtn.TextColor3 = Color3.white
    activateBtn.Font = Enum.Font.GothamBold
    activateBtn.TextSize = 16
    activateBtn.ZIndex = 11
    activateBtn.Parent = frame
    
    -- Кнопка "Продолжить без активации"
    local skipBtn = Instance.new("TextButton")
    skipBtn.Text = "ПРОДОЛЖИТЬ БЕЗ АКТИВАЦИИ"
    skipBtn.Size = UDim2.new(1, -20, 0, 40)
    skipBtn.Position = UDim2.new(0, 10, 0, 200)
    skipBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    skipBtn.TextColor3 = Color3.white
    skipBtn.Font = Enum.Font.Gotham
    skipBtn.TextSize = 14
    skipBtn.ZIndex = 11
    skipBtn.Parent = frame
    
    -- Метка статуса
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 30)
    statusLabel.Position = UDim2.new(0, 10, 0, 250)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    statusLabel.Text = ""
    statusLabel.ZIndex = 11
    statusLabel.Parent = frame
    
    -- Обработчик активации
    activateBtn.MouseButton1Click:Connect(function()
        local inputKey = keyBox.Text:gsub("%s+", ""):gsub("-", "")
        local validKey = accessKey:gsub("-", "")
        
        if inputKey == validKey then
            activated = true
            statusLabel.Text = "Активация успешна! Открываем меню через 3 секунды..."
            statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
            
            -- Автоматическое продолжение через 3 секунды
            task.wait(3)
            activationGui:Destroy()
            activationGui = nil
            createFarmingMenu()
        else
            statusLabel.Text = "НЕВЕРНЫЙ КЛЮЧ! Попробуйте снова."
            statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end)
    
    -- Обработчик пропуска активации
    skipBtn.MouseButton1Click:Connect(function()
        activationGui:Destroy()
        activationGui = nil
        createFarmingMenu()
    end)
    
    return activationGui
end

-- Создаем меню фарма
local function createFarmingMenu()
    if farmingGui then farmingGui:Destroy() end
    
    farmingGui = Instance.new("ScreenGui")
    farmingGui.Name = "FarmingMenuGUI"
    farmingGui.Parent = game:GetService("CoreGui")
    farmingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Основной фрейм
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 450)
    frame.Position = UDim2.new(0.5, -200, 0.5, -225)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.ZIndex = 10
    frame.Parent = farmingGui
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Text = "FARMING SYSTEM"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.ZIndex = 11
    title.Parent = frame
    
    -- Список функций
    local features = {
        {name = "Фарм мастери", key = "mastery", color = Color3.fromRGB(0, 170, 255)},
        {name = "Фарм фруктов", key = "fruits", color = Color3.fromRGB(255, 85, 0)},
        {name = "Фарм сундуков", key = "chests", color = Color3.fromRGB(255, 255, 0)},
        {name = "Фарм костей", key = "bones", color = Color3.fromRGB(170, 0, 255)}
    }
    
    -- Создаем переключатели для функций
    for i, feature in ipairs(features) do
        -- Контейнер для функции
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 0, 80)
        container.Position = UDim2.new(0, 10, 0, 50 + (i-1)*90)
        container.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        container.BackgroundTransparency = 0.5
        container.ZIndex = 11
        container.Parent = frame
        
        -- Название функции
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = feature.name
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.PaddingLeft = UDim.new(0, 10)
        nameLabel.ZIndex = 12
        nameLabel.Parent = container
        
        -- Переключатель
        local toggle = Instance.new("TextButton")
        toggle.Text = farmingModules[feature.key] and "ВКЛ" or "ВЫКЛ"
        toggle.Size = UDim2.new(0.25, 0, 0.6, 0)
        toggle.Position = UDim2.new(0.7, 0, 0.2, 0)
        toggle.BackgroundColor3 = farmingModules[feature.key] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        toggle.TextColor3 = Color3.white
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 14
        toggle.ZIndex = 12
        toggle.Parent = container
        
        -- Обработчик переключения
        toggle.MouseButton1Click:Connect(function()
            farmingModules[feature.key] = not farmingModules[feature.key]
            toggle.Text = farmingModules[feature.key] and "ВКЛ" or "ВЫКЛ"
            toggle.BackgroundColor3 = farmingModules[feature.key] and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
            
            -- Здесь будет код активации/деактивации функции
            print(feature.name .. " " .. (farmingModules[feature.key] and "активирован" or "деактивирован"))
        end)
        
        -- Иконка функции
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 50, 0, 50)
        icon.Position = UDim2.new(0.05, 0, 0.15, 0)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://" .. (farmingModules[feature.key] and "11327078478" or "11327078784")
        icon.ZIndex = 12
        icon.Parent = container
    end
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "ЗАКРЫТЬ (M)"
    closeBtn.Size = UDim2.new(1, -20, 0, 40)
    closeBtn.Position = UDim2.new(0, 10, 0, 380)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.TextColor3 = Color3.white
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.ZIndex = 11
    closeBtn.Parent = frame
    
    closeBtn.MouseButton1Click:Connect(function()
        farmingGui:Destroy()
        farmingGui = nil
    end)
    
    return farmingGui
end

-- Уведомление о ключе
if keySent then
    game.StarterGui:SetCore("SendNotification", {
        Title = "KEY SYSTEM",
        Text = "Ключ отправлен в Discord",
        Icon = "rbxassetid://6726578090",
        Duration = 5
    })
    
    -- Автоматическое открытие окна активации через 3 секунды
    task.wait(3)
    createActivationGui()
else
    warn("Не удалось отправить ключ в Discord")
    game.StarterGui:SetCore("SendNotification", {
        Title = "ОШИБКА",
        Text = "Не удалось отправить ключ",
        Icon = "rbxassetid://13423342148",
        Duration = 5
    })
end

-- Обработчик клавиши M для управления интерфейсами
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.M and not gameProcessed then
        -- Управление окном активации
        if activationGui and activationGui.Parent then
            activationGui:Destroy()
            activationGui = nil
        -- Управление меню фарма
        elseif farmingGui and farmingGui.Parent then
            farmingGui:Destroy()
            farmingGui = nil
        -- Открытие меню фарма если активировано
        elseif activated then
            createFarmingMenu()
        -- Открытие активации если не активировано
        elseif not activated then
            createActivationGui()
        end
    end
end)

-- Загрузка скрипта Blox Fruits после активации
spawn(function()
    while not activated do task.wait(1) end
    
    if game.PlaceId == 2753915549 then
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Fisterovna2/RobloxKeys/main/Loader.lua"))()
        end)
    end
end)

print("Система запущена. Нажмите M для управления.")
print("Сгенерированный ключ: " .. accessKey)
