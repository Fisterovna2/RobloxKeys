repeat task.wait() until game:IsLoaded()

-- Глобальные переменные
local farmingGui = nil
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

-- Состояния фарма
local farmingModules = {
    mastery = { enabled = false, thread = nil },
    fruits = { enabled = false, thread = nil },
    chests = { enabled = false, thread = nil },
    bones = { enabled = false, thread = nil }
}

-- Визуальные темы для переключателей
local colorThemes = {
    mastery = { on = Color3.fromRGB(0, 255, 170), off = Color3.fromRGB(100, 100, 100) },
    fruits = { on = Color3.fromRGB(255, 125, 0), off = Color3.fromRGB(100, 100, 100) },
    chests = { on = Color3.fromRGB(255, 255, 0), off = Color3.fromRGB(100, 100, 100) },
    bones = { on = Color3.fromRGB(180, 0, 255), off = Color3.fromRGB(100, 100, 100) }
}

-- ======================= РЕАЛЬНЫЕ ФУНКЦИИ ФАРМА =======================

-- Функция фарма мастери (адаптирована из популярных скриптов)
local function startMasteryFarm()
    while farmingModules.mastery.enabled and task.wait(0.1) do
        pcall(function()
            local closest
            local dist = math.huge
            
            for _, v in ipairs(workspace.Enemies:GetChildren()) do
                if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    local d = (LocalPlayer.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                    if d < dist then
                        closest = v
                        dist = d
                    end
                end
            end
            
            if closest then
                LocalPlayer.Character.HumanoidRootPart.CFrame = closest.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
        end)
    end
end

-- Функция фарма фруктов (стандартная реализация)
local function startFruitFarm()
    while farmingModules.fruits.enabled and task.wait(1) do
        pcall(function()
            for _, v in ipairs(workspace:GetChildren()) do
                if string.find(v.Name, "Fruit") and v:FindFirstChild("Handle") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = v.Handle.CFrame
                    fireproximityprompt(v.Handle.ProximityPrompt)
                end
            end
        end)
    end
end

-- Функция фарма сундуков (оптимизированная версия)
local function startChestFarm()
    while farmingModules.chests.enabled and task.wait(1) do
        pcall(function()
            for _, v in ipairs(workspace:GetChildren()) do
                if string.find(v.Name, "Chest") and v:FindFirstChild("ClickDetector") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = v.CFrame * CFrame.new(0, 3, 0)
                    fireclickdetector(v.ClickDetector)
                end
            end
        end)
    end
end

-- Функция фарма костей (для Cemetery)
local function startBonesFarm()
    while farmingModules.bones.enabled and task.wait(0.5) do
        pcall(function()
            local target = workspace.Enemies:FindFirstChild("Skeleton Boss") or
                           workspace.Enemies:FindFirstChild("Skeleton")
            
            if target then
                LocalPlayer.Character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
        end)
    end
end

-- ======================= ВИЗУАЛЬНЫЙ ИНТЕРФЕЙС =======================

-- Анимация переключателей
local function animateToggle(module, key)
    if module.toggle and module.light then
        local targetColor = module.enabled and colorThemes[key].on or colorThemes[key].off
        
        TweenService:Create(
            module.light,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = targetColor }
        ):Play()
        
        module.toggle.Text = module.enabled and "ВКЛ" or "ВЫКЛ"
    end
end

-- Создание меню
local function createFarmingMenu()
    if farmingGui then farmingGui:Destroy() end
    
    farmingGui = Instance.new("ScreenGui")
    farmingGui.Name = "FarmingMenuGUI"
    farmingGui.Parent = game.CoreGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 380, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = farmingGui
    
    -- Список функций
    local features = {
        { name = "ФАРМ МАСТЕРИ", key = "mastery", icon = "🔫" },
        { name = "ФАРМ ФРУКТОВ", key = "fruits", icon = "🍎" },
        { name = "ФАРМ СУНДУКОВ", key = "chests", icon = "📦" },
        { name = "ФАРМ КОСТЕЙ", key = "bones", icon = "💀" }
    }
    
    for i, feature in ipairs(features) do
        local yPos = 60 + (i-1)*85
        
        -- Контейнер функции
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0.9, 0, 0, 70)
        container.Position = UDim2.new(0.05, 0, 0, yPos)
        container.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        container.BackgroundTransparency = 0.3
        container.Parent = mainFrame
        
        -- Иконка
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Text = feature.icon
        iconLabel.Size = UDim2.new(0, 50, 0, 50)
        iconLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
        iconLabel.TextSize = 30
        iconLabel.BackgroundTransparency = 1
        iconLabel.TextColor3 = colorThemes[feature.key].off
        iconLabel.Parent = container
        
        -- Название
        local label = Instance.new("TextLabel")
        label.Text = feature.name
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0.2, 0, 0, 0)
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        label.Parent = container
        
        -- Переключатель
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(0, 80, 0, 30)
        toggleFrame.Position = UDim2.new(0.7, 0, 0.3, 0)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        toggleFrame.BorderSizePixel = 0
        toggleFrame.Parent = container
        
        -- Индикатор
        local light = Instance.new("Frame")
        light.Size = UDim2.new(0, 12, 0, 12)
        light.Position = UDim2.new(0.1, 0, 0.3, 0)
        light.BackgroundColor3 = colorThemes[feature.key].off
        light.BorderSizePixel = 0
        light.ZIndex = 2
        light.Parent = toggleFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = light
        
        -- Текст статуса
        local statusText = Instance.new("TextLabel")
        statusText.Size = UDim2.new(0.6, 0, 1, 0)
        statusText.Position = UDim2.new(0.3, 0, 0, 0)
        statusText.Text = "ВЫКЛ"
        statusText.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        statusText.Font = Enum.Font.GothamBold
        statusText.TextSize = 14
        statusText.BackgroundTransparency = 1
        statusText.Parent = toggleFrame
        
        -- Сохраняем ссылки
        farmingModules[feature.key].toggle = statusText
        farmingModules[feature.key].light = light
        animateToggle(farmingModules[feature.key], feature.key)
        
        -- Кликабельная область
        local clickArea = Instance.new("TextButton")
        clickArea.Size = UDim2.new(1, 0, 1, 0)
        clickArea.BackgroundTransparency = 1
        clickArea.Text = ""
        clickArea.ZIndex = 5
        clickArea.Parent = toggleFrame
        
        -- Обработчик клика
        clickArea.MouseButton1Click:Connect(function()
            farmingModules[feature.key].enabled = not farmingModules[feature.key].enabled
            animateToggle(farmingModules[feature.key], feature.key)
            
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
    end
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "ЗАКРЫТЬ (M)"
    closeBtn.Size = UDim2.new(0.9, 0, 0, 40)
    closeBtn.Position = UDim2.new(0.05, 0, 0, 360)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.BackgroundTransparency = 0.3
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = mainFrame
    
    closeBtn.MouseButton1Click:Connect(function()
        farmingGui:Destroy()
    end)
end

-- Обработчик клавиши M
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.M and not gameProcessed then
        if farmingGui and farmingGui.Parent then
            farmingGui:Destroy()
        else
            createFarmingMenu()
        end
    end
end)

-- Уведомление
game.StarterGui:SetCore("SendNotification", {
    Title = "ФАРМ МЕНЮ",
    Text = "Нажмите M для открытия/закрытия меню",
    Icon = "rbxassetid://6726578090",
    Duration = 5
})

print("Меню фарма готово! Нажмите M для открытия.")
