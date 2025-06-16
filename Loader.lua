repeat task.wait() until game:IsLoaded()

-- Глобальные переменные
local farmingGui = nil
local menuVisible = false
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local VirtualUser = game:GetService("VirtualUser")

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
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    
    -- Рассчитываем путь
    path:ComputeAsync(rootPart.Position, targetPosition)
    if path.Status ~= Enum.PathStatus.Success then return false end
    
    -- Двигаемся по точкам пути
    local waypoints = path:GetWaypoints()
    for _, waypoint in ipairs(waypoints) do
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end
        
        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then break end
    end
    
    return true
end

-- Функция фарма мастери (с перемещением и атакой)
local function startMasteryFarm()
    while farmingModules.mastery.enabled and task.wait(0.1) do
        -- Проверка на смерть
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
            task.wait(2)
            continue
        end
        
        -- Поиск ближайшего врага
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
            -- Перемещение к врагу
            moveTo(nearestEnemy.HumanoidRootPart.Position)
            
            -- Авто-атака
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end
end

-- Функция фарма фруктов
local function startFruitFarm()
    while farmingModules.fruits.enabled and task.wait(1) do
        -- Поиск фруктов
        local fruits = {}
        for _, fruit in ipairs(workspace:GetChildren()) do
            if fruit.Name:find("Fruit") and fruit:FindFirstChild("Handle") then
                table.insert(fruits, fruit)
            end
        end
        
        if #fruits > 0 then
            -- Выбор ближайшего фрукта
            table.sort(fruits, function(a,b)
                return (a.Handle.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                       (b.Handle.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end)
            
            moveTo(fruits[1].Handle.Position)
        end
    end
end

-- Функция фарма сундуков
local function startChestFarm()
    while farmingModules.chests.enabled and task.wait(1) do
        -- Поиск сундуков
        local chests = {}
        for _, chest in ipairs(workspace:GetChildren()) do
            if chest.Name:find("Chest") and chest:FindFirstChild("Chest") then
                table.insert(chests, chest.Chest)
            end
        end
        
        if #chests > 0 then
            -- Выбор ближайшего сундука
            table.sort(chests, function(a,b)
                return (a.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                       (b.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end)
            
            moveTo(chests[1].Position)
        end
    end
end

-- Функция фарма костей
local function startBonesFarm()
    while farmingModules.bones.enabled and task.wait(0.7) do
        -- Поиск костей
        local bones = {}
        for _, bone in ipairs(workspace:GetChildren()) do
            if bone.Name == "Bone" and bone:IsA("MeshPart") then
                table.insert(bones, bone)
            end
        end
        
        if #bones > 0 then
            -- Выбор ближайшей кости
            table.sort(bones, function(a,b)
                return (a.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                       (b.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end)
            
            moveTo(bones[1].Position)
        end
    end
end

-- Создание меню (остается без изменений)
-- ... (ваш существующий код создания меню) ...

-- Обработчик клавиши M
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.M and not gameProcessed then
        menuVisible = not menuVisible
        
        if menuVisible then
            createFarmingMenu()
        elseif farmingGui then
            farmingGui:Destroy()
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
