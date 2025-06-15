-- [Основной скрипт для Blox Fruits]
repeat task.wait() until game:IsLoaded()

-- [Глобальные переменные]
local farmingGui = nil
local menuVisible = false
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- [Состояния фарма]
local farmingModules = {
    mastery = { enabled = false, thread = nil },
    fruits = { enabled = false, thread = nil },
    chests = { enabled = false, thread = nil },
    bones = { enabled = false, thread = nil }
}

-- [Функция фарма мастери]
local function startMasteryFarm()
    while farmingModules.mastery.enabled and task.wait(0.5) do
        -- Пример: атака ближайших NPC
        local closestNPC
        local minDistance = math.huge
        for _, npc in ipairs(workspace.Enemies:GetChildren()) do
            if npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
                if distance < minDistance then
                    closestNPC = npc
                    minDistance = distance
                end
            end
        end
        
        if closestNPC then
            LocalPlayer.Character.HumanoidRootPart.CFrame = closestNPC.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
            mouse1click() -- Активация атаки
        end
    end
end

-- [Функция фарма фруктов]
local function startFruitFarm()
    while farmingModules.fruits.enabled and task.wait(1) do
        -- Пример: поиск фруктов на карте
        for _, fruit in ipairs(workspace:GetChildren()) do
            if fruit.Name:find("Fruit") and fruit:FindFirstChild("Handle") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = fruit.Handle.CFrame
                task.wait(0.5)
                fireproximityprompt(fruit.Handle.ProximityPrompt)
            end
        end
    end
end

-- [Функция фарма сундуков]
local function startChestFarm()
    while farmingModules.chests.enabled and task.wait(1) do
        -- Пример: поиск сундуков
        for _, chest in ipairs(workspace:GetChildren()) do
            if chest.Name:find("Chest") and chest:FindFirstChild("ClickDetector") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = chest.CFrame * CFrame.new(0, 0, -2)
                task.wait(0.5)
                fireclickdetector(chest.ClickDetector)
            end
        end
    end
end

-- [Функция фарма костей]
local function startBonesFarm()
    while farmingModules.bones.enabled and task.wait(0.7) do
        -- Пример: фарм у Cemetery NPC
        local targetNPC = workspace.Enemies:FindFirstChild("Skeleton Boss")
        if targetNPC then
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetNPC.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8)
            mouse1click()
        end
    end
end

-- [Создание меню]
local function createFarmingMenu()
    if farmingGui then farmingGui:Destroy() end

    farmingGui = Instance.new("ScreenGui")
    farmingGui.Parent = game.CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 400)
    frame.Position = UDim2.new(0.5, -175, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = farmingGui

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Text = "BLOCK FRUITS FARM MENU"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = frame

    -- Функции
    local features = {
        { name = "Фарм мастери", key = "mastery", color = Color3.fromRGB(0, 150, 255) },
        { name = "Фарм фруктов", key = "fruits", color = Color3.fromRGB(255, 100, 0) },
        { name = "Фарм сундуков", key = "chests", color = Color3.fromRGB(255, 255, 0) },
        { name = "Фарм костей", key = "bones", color = Color3.fromRGB(180, 0, 180) }
    }

    for i, feature in ipairs(features) do
        local yPos = 50 + (i-1)*80
        
        -- Контейнер
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0.9, 0, 0, 70)
        container.Position = UDim2.new(0.05, 0, 0, yPos)
        container.BackgroundColor3 = feature.color
        container.BackgroundTransparency = 0.7
        container.Parent = frame

        -- Название
        local label = Instance.new("TextLabel")
        label.Text = feature.name
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.Gotham
        label.TextSize = 16
        label.Parent = container

        -- Переключатель
        local toggle = Instance.new("TextButton")
        toggle.Text = farmingModules[feature.key].enabled and "ВКЛ" or "ВЫКЛ"
        toggle.Size = UDim2.new(0.25, 0, 0.6, 0)
        toggle.Position = UDim2.new(0.72, 0, 0.2, 0)
        toggle.BackgroundColor3 = farmingModules[feature.key].enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        toggle.TextColor3 = Color3.new(1, 1, 1)
        toggle.Font = Enum.Font.GothamBold
        toggle.Parent = container

        -- Обработчик
        toggle.MouseButton1Click:Connect(function()
            farmingModules[feature.key].enabled = not farmingModules[feature.key].enabled
            toggle.Text = farmingModules[feature.key].enabled and "ВКЛ" or "ВЫКЛ"
            toggle.BackgroundColor3 = farmingModules[feature.key].enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
            
            -- Управление функциями
            if feature.key == "mastery" then
                if farmingModules.mastery.enabled then
                    farmingModules.mastery.thread = task.spawn(startMasteryFarm)
                elseif farmingModules.mastery.thread then
                    task.cancel(farmingModules.mastery.thread)
                end
            -- Аналогично для других функций
            end
        end)
    end

    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "ЗАКРЫТЬ (M)"
    closeBtn.Size = UDim2.new(0.9, 0, 0, 40)
    closeBtn.Position = UDim2.new(0.05, 0, 0, 340)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = frame
    
    closeBtn.MouseButton1Click:Connect(function()
        farmingGui:Destroy()
        menuVisible = false
    end)
end

-- [Обработчик клавиши M]
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        menuVisible = not menuVisible
        if menuVisible then
            createFarmingMenu()
        elseif farmingGui then
            farmingGui:Destroy()
        end
    end
end)

-- [Уведомление]
game.StarterGui:SetCore("SendNotification", {
    Title = "Фарм меню",
    Text = "Нажмите M для открытия меню",
    Duration = 5
})
