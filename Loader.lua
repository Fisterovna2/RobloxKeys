repeat task.wait() until game:IsLoaded()

-- Упрощенные глобальные переменные
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Проверка, что персонаж загружен
repeat task.wait() until LocalPlayer.Character

-- Состояния фарма
local farmingModules = {
    mastery = { enabled = false, active = false },
    fruits = { enabled = false, active = false },
    chests = { enabled = false, active = false },
    bones = { enabled = false, active = false }
}

-- Создаем GUI в CoreGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmMasterGUI"
screenGui.Parent = game:GetService("CoreGui")
screenGui.ResetOnSpawn = false

-- Основное окно (изначально скрыто)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 400)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Заголовок
local title = Instance.new("TextLabel")
title.Text = "BLOCK FRUITS FARM MASTER"
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = mainFrame

-- Список функций
local features = {
    { name = "ФАРМ МАСТЕРИ", key = "mastery", color = Color3.fromRGB(0, 255, 170) },
    { name = "ФАРМ ФРУКТОВ", key = "fruits", color = Color3.fromRGB(255, 125, 0) },
    { name = "ФАРМ СУНДУКОВ", key = "chests", color = Color3.fromRGB(255, 255, 0) },
    { name = "ФАРМ КОСТЕЙ", key = "bones", color = Color3.fromRGB(180, 0, 255) }
}

local toggles = {}

for i, feature in ipairs(features) do
    local yPos = 60 + (i-1)*80
    
    -- Контейнер функции
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.9, 0, 0, 70)
    container.Position = UDim2.new(0.05, 0, 0, yPos)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    container.BorderSizePixel = 0
    container.Parent = mainFrame
    
    -- Название функции
    local label = Instance.new("TextLabel")
    label.Text = feature.name
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = container
    
    -- Переключатель
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 80, 0, 30)
    toggle.Position = UDim2.new(0.7, 0, 0.3, 0)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggle.BorderSizePixel = 0
    toggle.Text = "ВЫКЛ"
    toggle.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 14
    toggle.Parent = container
    
    -- Сохраняем переключатель
    toggles[feature.key] = toggle
    
    -- Обработчик клика
    toggle.MouseButton1Click:Connect(function()
        farmingModules[feature.key].enabled = not farmingModules[feature.key].enabled
        
        -- Визуальное обновление
        if farmingModules[feature.key].enabled then
            toggle.BackgroundColor3 = feature.color
            toggle.Text = "ВКЛ"
        else
            toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            toggle.Text = "ВЫКЛ"
        end
    end)
end

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Text = "ЗАКРЫТЬ (M)"
closeBtn.Size = UDim2.new(0.9, 0, 0, 40)
closeBtn.Position = UDim2.new(0.05, 0, 0, 350)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = mainFrame

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Функция для перемещения к цели (упрощенная)
local function moveTo(position)
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if humanoid and rootPart then
        humanoid:MoveTo(position)
    end
end

-- Авто-атака
local function autoAttack(target)
    if not target then return end
    
    -- Эмулируем клик мыши
    mouse1press()
    task.wait(0.2)
    mouse1release()
end

-- Основной цикл фарма
RunService.Heartbeat:Connect(function()
    -- Фарм мастери
    if farmingModules.mastery.enabled then
        -- Поиск ближайшего врага
        local closestEnemy, minDist = nil, math.huge
        for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
            if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestEnemy = enemy
                end
            end
        end
        
        if closestEnemy then
            moveTo(closestEnemy.HumanoidRootPart.Position)
            autoAttack(closestEnemy)
        end
    end
    
    -- Фарм фруктов (пример)
    if farmingModules.fruits.enabled then
        for _, fruit in ipairs(workspace:GetChildren()) do
            if fruit.Name:find("Fruit") and fruit:FindFirstChild("Handle") then
                local dist = (LocalPlayer.Character.HumanoidRootPart.Position - fruit.Handle.Position).Magnitude
                if dist < 50 then
                    moveTo(fruit.Handle.Position)
                    break
                end
            end
        end
    end
end)

-- Обработчик клавиши M
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

-- Уведомление
local function showNotification()
    game.StarterGui:SetCore("SendNotification", {
        Title = "ФАРМ МЕНЮ АКТИВИРОВАНО",
        Text = "Нажмите M для открытия меню",
        Icon = "rbxassetid://6726578090",
        Duration = 5
    })
end

-- Запускаем уведомление после загрузки
task.delay(3, showNotification)

print("Farm Master активирован! Нажмите M для открытия меню")
