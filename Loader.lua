repeat task.wait() until game:IsLoaded()

-- Глобальное состояние
local farmingGui = nil
local menuVisible = false

-- Функции фарма
local farmingModules = {
    mastery = {enabled = false, thread = nil},
    fruits = {enabled = false, thread = nil},
    chests = {enabled = false, thread = nil},
    bones = {enabled = false, thread = nil}
}

-- Реальные функции фарма
local function startMasteryFarm()
    while farmingModules.mastery.enabled and task.wait() do
        -- Реальный код фарма мастери
        print("Фарм мастери активен...")
        -- Ваш код здесь
    end
end

local function startFruitFarm()
    while farmingModules.fruits.enabled and task.wait() do
        -- Реальный код фарма фруктов
        print("Фарм фруктов активен...")
        -- Ваш код здесь
    end
end

local function startChestFarm()
    while farmingModules.chests.enabled and task.wait() do
        -- Реальный код фарма сундуков
        print("Фарм сундуков активен...")
        -- Ваш код здесь
    end
end

local function startBonesFarm()
    while farmingModules.bones.enabled and task.wait() do
        -- Реальный код фарма костей
        print("Фарм костей активен...")
        -- Ваш код здесь
    end
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
    title.Text = "BLOCK FRUITS FARMING MENU"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.ZIndex = 11
    title.Parent = frame
    
    -- Информация
    local info = Instance.new("TextLabel")
    info.Text = "Нажмите M для закрытия меню"
    info.Size = UDim2.new(1, 0, 0, 20)
    info.Position = UDim2.new(0, 0, 0, 40)
    info.BackgroundTransparency = 1
    info.TextColor3 = Color3.fromRGB(150, 150, 180)
    info.Font = Enum.Font.Gotham
    info.TextSize = 12
    info.ZIndex = 11
    info.Parent = frame
    
    -- Список функций
    local features = {
        {name = "Фарм мастери", key = "mastery", color = Color3.fromRGB(0, 170, 255), icon = "11327078478"},
        {name = "Фарм фруктов", key = "fruits", color = Color3.fromRGB(255, 85, 0), icon = "11327078478"},
        {name = "Фарм сундуков", key = "chests", color = Color3.fromRGB(255, 255, 0), icon = "11327078478"},
        {name = "Фарм костей", key = "bones", color = Color3.fromRGB(170, 0, 255), icon = "11327078478"}
    }
    
    -- Создаем переключатели для функций
    for i, feature in ipairs(features) do
        -- Контейнер для функции
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -20, 0, 80)
        container.Position = UDim2.new(0, 10, 0, 70 + (i-1)*90)
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
        nameLabel.PaddingLeft = UDim.new(0, 60)
        nameLabel.ZIndex = 12
        nameLabel.Parent = container
        
        -- Переключатель
        local toggle = Instance.new("TextButton")
        toggle.Text = farmingModules[feature.key].enabled and "ВКЛЮЧЕНО" or "ВЫКЛЮЧЕНО"
        toggle.Size = UDim2.new(0.25, 0, 0.6, 0)
        toggle.Position = UDim2.new(0.7, 0, 0.2, 0)
        toggle.BackgroundColor3 = farmingModules[feature.key].enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        toggle.TextColor3 = Color3.white
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 14
        toggle.ZIndex = 12
        toggle.Parent = container
        
        -- Обработчик переключения
        toggle.MouseButton1Click:Connect(function()
            farmingModules[feature.key].enabled = not farmingModules[feature.key].enabled
            toggle.Text = farmingModules[feature.key].enabled and "ВКЛЮЧЕНО" or "ВЫКЛЮЧЕНО"
            toggle.BackgroundColor3 = farmingModules[feature.key].enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
            
            -- Управление функциями
            if feature.key == "mastery" then
                if farmingModules.mastery.enabled then
                    farmingModules.mastery.thread = task.spawn(startMasteryFarm)
                elseif farmingModules.mastery.thread then
                    task.cancel(farmingModules.mastery.thread)
                end
                
            elseif feature.key == "fruits" then
                if farmingModules.fruits.enabled then
                    farmingModules.fruits.thread = task.spawn(startFruitFarm)
                elseif farmingModules.fruits.thread then
                    task.cancel(farmingModules.fruits.thread)
                end
                
            elseif feature.key == "chests" then
                if farmingModules.chests.enabled then
                    farmingModules.chests.thread = task.spawn(startChestFarm)
                elseif farmingModules.chests.thread then
                    task.cancel(farmingModules.chests.thread)
                end
                
            elseif feature.key == "bones" then
                if farmingModules.bones.enabled then
                    farmingModules.bones.thread = task.spawn(startBonesFarm)
                elseif farmingModules.bones.thread then
                    task.cancel(farmingModules.bones.thread)
                end
            end
        end)
        
        -- Иконка функции
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0.02, 0, 0.25, 0)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://" .. feature.icon
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
        menuVisible = false
    end)
    
    return farmingGui
end

-- Обработчик клавиши M
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.M and not gameProcessed then
        menuVisible = not menuVisible
        
        if menuVisible then
            if not farmingGui or not farmingGui.Parent then
                createFarmingMenu()
            else
                farmingGui.Enabled = true
            end
        else
            if farmingGui then
                farmingGui.Enabled = false
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

-- Уведомление о меню
game.StarterGui:SetCore("SendNotification", {
    Title = "FARMING MENU",
    Text = "Нажмите M для открытия меню фарма",
    Duration = 5
})

print("Меню фарма готово! Нажмите M для открытия.")
