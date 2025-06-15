repeat task.wait() until game:IsLoaded()

-- Глобальные переменные
local farmingGui = nil
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

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

-- ======================= УЛУЧШЕННЫЕ ФУНКЦИИ ФАРМА =======================

-- Интеллектуальное перемещение к цели
local function moveToTarget(targetCFrame)
    local humanoid = LocalPlayer.Character.Humanoid
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    
    -- Активируем полет
    humanoid:ChangeState(Enum.HumanoidStateType.Flying)
    
    -- Рассчитываем направление
    local direction = (targetCFrame.Position - rootPart.Position).Unit
    local distance = (targetCFrame.Position - rootPart.Position).Magnitude
    
    -- Плавное перемещение
    local speed = 100 -- Скорость перемещения
    local steps = math.ceil(distance / speed)
    
    for i = 1, steps do
        if not farmingModules.chests.enabled and not farmingModules.fruits.enabled and not farmingModules.bones.enabled then
            break
        end
        
        local newPosition = rootPart.Position + (direction * math.min(speed, distance))
        rootPart.CFrame = CFrame.new(newPosition, newPosition + direction)
        task.wait(0.05)
    end
    
    -- Финишная позиция
    rootPart.CFrame = targetCFrame
end

-- Улучшенный фарм сундуков с перемещением по всей карте
local function startChestFarm()
    while farmingModules.chests.enabled and task.wait(1) do
        pcall(function()
            -- Ищем все сундуки на карте
            local allChests = {}
            for _, v in ipairs(workspace:GetDescendants()) do
                if v.Name:find("Chest") and v:FindFirstChild("ClickDetector") then
                    table.insert(allChests, v)
                end
            end
            
            -- Сортируем по расстоянию
            table.sort(allChests, function(a, b)
                return (LocalPlayer.Character.HumanoidRootPart.Position - a.Position).Magnitude <
                       (LocalPlayer.Character.HumanoidRootPart.Position - b.Position).Magnitude
            end)
            
            -- Перемещаемся к каждому сундуку
            for _, chest in ipairs(allChests) do
                if not farmingModules.chests.enabled then break end
                
                moveToTarget(chest.CFrame * CFrame.new(0, 3, 0))
                fireclickdetector(chest.ClickDetector)
                task.wait(0.5)
            end
        end)
    end
end

-- Улучшенный фарм фруктов с поиском по всей карте
local function startFruitFarm()
    while farmingModules.fruits.enabled and task.wait(1) do
        pcall(function()
            -- Ищем все фрукты на карте
            local allFruits = {}
            for _, v in ipairs(workspace:GetDescendants()) do
                if v.Name:find("Fruit") and v:FindFirstChild("Handle") then
                    table.insert(allFruits, v)
                end
            end
            
            -- Сортируем по расстоянию
            table.sort(allFruits, function(a, b)
                return (LocalPlayer.Character.HumanoidRootPart.Position - a.Handle.Position).Magnitude <
                       (LocalPlayer.Character.HumanoidRootPart.Position - b.Handle.Position).Magnitude
            end)
            
            -- Перемещаемся к каждому фрукту
            for _, fruit in ipairs(allFruits) do
                if not farmingModules.fruits.enabled then break end
                
                moveToTarget(fruit.Handle.CFrame)
                fireproximityprompt(fruit.Handle.ProximityPrompt)
                task.wait(0.5)
            end
        end)
    end
end

-- Улучшенный фарм костей с перемещением в нужные зоны
local function startBonesFarm()
    while farmingModules.bones.enabled and task.wait(0.5) do
        pcall(function()
            -- Определяем лучшую зону для фарма костей
            local targetZone
            if workspace:FindFirstChild("Graveyard") then
                targetZone = workspace.Graveyard
            elseif workspace:FindFirstChild("Haunted Castle") then
                targetZone = workspace["Haunted Castle"]
            else
                -- Если зоны не найдены, ищем обычных скелетов
                targetZone = workspace
            end
            
            -- Ищем цель в выбранной зоне
            local target
            for _, enemy in ipairs(targetZone:GetDescendants()) do
                if enemy:IsA("Model") and (enemy.Name:find("Skeleton") or enemy.Name:find("Ghost")) and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                    target = enemy
                    break
                end
            end
            
            if target then
                -- Перемещаемся к цели
                moveToTarget(target.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8))
                
                -- Атакуем
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
        end)
    end
end

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
                moveToTarget(closest.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5))
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end
        end)
    end
end

-- ======================= ВИЗУАЛЬНЫЙ ИНТЕРФЕЙС =======================
-- [Остальная часть кода с визуальным интерфейсом остается без изменений]
-- [Как в предыдущем скрипте - создание меню, анимация переключателей и т.д.]

-- Обработчик клавиши M
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.M and not gameProcessed then
        if farmingGui and farmingGui.Parent then
            farmingGui:Destroy()
        else
            -- Создаем меню (код создания меню из предыдущего скрипта)
        end
    end
end)

-- Уведомление
game.StarterGui:SetCore("SendNotification", {
    Title = "УЛУЧШЕННЫЙ ФАРМ",
    Text = "Нажмите M для открытия меню",
    Icon = "rbxassetid://6726578090",
    Duration = 5
})

print("Улучшенный фарм готов! Нажмите M для открытия меню.")
