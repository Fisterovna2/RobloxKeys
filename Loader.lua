repeat task.wait() until game:IsLoaded()

-- Глобальные переменные
local farmingGui = nil
local menuVisible = false
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

-- Оптимизация для Pathfinding
local path = PathfindingService:CreatePath({
    AgentRadius = 2,
    AgentHeight = 5,
    AgentCanJump = true,
    WaypointSpacing = 4
})

-- Состояния фарма
local farmingModules = {
    mastery = { enabled = false, thread = nil, toggle = nil, light = nil },
    fruits = { enabled = false, thread = nil, toggle = nil, light = nil },
    chests = { enabled = false, thread = nil, toggle = nil, light = nil },
    bones = { enabled = false, thread = nil, toggle = nil, light = nil }
}

-- Цвета
local colorThemes = {
    mastery = { on = Color3.fromRGB(0, 255, 170), off = Color3.fromRGB(100, 100, 100) },
    fruits = { on = Color3.fromRGB(255, 125, 0), off = Color3.fromRGB(100, 100, 100) },
    chests = { on = Color3.fromRGB(255, 255, 0), off = Color3.fromRGB(100, 100, 100) },
    bones = { on = Color3.fromRGB(180, 0, 255), off = Color3.fromRGB(100, 100, 100) }
}

-- Анимация переключения
local function animateToggle(module, key)
    if module.toggle and module.light then
        local targetColor = module.enabled and colorThemes[key].on or colorThemes[key].off
        
        TweenService:Create(
            module.toggle,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = targetColor }
        ):Play()
        
        TweenService:Create(
            module.light,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = targetColor }
        ):Play()
        
        module.toggle.Text = module.enabled and "ВКЛ" or "ВЫКЛ"
    end
end

-- Безопасное перемещение к цели
local function moveTo(targetPosition)
    if not LocalPlayer.Character then return false end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return false end
    
    -- Рассчитываем путь
    local success, result = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPosition)
        return path.Status == Enum.PathStatus.Success
    end)
    
    if not success or not result then return false end
    
    -- Двигаемся по точкам пути
    local waypoints = path:GetWaypoints()
    for _, waypoint in ipairs(waypoints) do
        if not farmingModules.mastery.enabled then break end
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end
        
        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait(1)
        if not reached then break end
    end
    
    return true
end

-- Функция фарма мастери
local function startMasteryFarm()
    while farmingModules.mastery.enabled and task.wait(0.1) do
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
            task.wait(2)
            continue
        end
        
        local nearestEnemy, minDistance = nil, math.huge
        for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
            if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    nearestEnemy = enemy
                end
            end
        end
        
        if nearestEnemy then
            moveTo(nearestEnemy.HumanoidRootPart.Position)
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end
end

-- Остальные функции фарма (fruits, chests, bones) остаются без изменений
-- ...

-- Создание меню (ИСПРАВЛЕННАЯ ВЕРСИЯ)
local function createFarmingMenu()
    -- Удаляем старое меню если есть
    if farmingGui then 
        farmingGui:Destroy() 
        farmingGui = nil
    end
    
    -- Создаем новое GUI
    farmingGui = Instance.new("ScreenGui")
    farmingGui.Name = "FarmingMenuGUI"
    farmingGui.Parent = game:GetService("CoreGui")
    farmingGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 380, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = farmingGui
    
    -- ... (остальной код создания меню без изменений) ...
    -- ВАЖНО: убедитесь что этот блок кода присутствует полностью
    -- он должен создавать все элементы интерфейса
    
    -- Кнопка закрытия (с исправленной анимацией)
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
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = closeBtn
    
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.1,
            TextColor3 = Color3.new(1, 0.8, 0.8)
        }):Play()
    end)
    
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.3,
            TextColor3 = Color3.new(1, 1, 1)
        }):Play()
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        farmingGui:Destroy()
        farmingGui = nil
        menuVisible = false
    end)
    
    return farmingGui
end

-- Обработчик клавиши M (ИСПРАВЛЕННЫЙ)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.M and not gameProcessed then
        menuVisible = not menuVisible
        
        if menuVisible then
            createFarmingMenu()
        else
            if farmingGui then
                farmingGui:Destroy()
                farmingGui = nil
            end
        end
    end
end)

-- Проверка что меню можно открыть
task.spawn(function()
    while true do
        task.wait(1)
        print("Скрипт работает. Меню видимое:", menuVisible)
        print("GUI существует:", farmingGui ~= nil)
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
