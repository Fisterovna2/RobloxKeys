repeat task.wait(1) until game:IsLoaded() and game:GetService("CoreGui")

-- Глобальные переменные
local farmingGui = nil
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

-- Ожидаем появления персонажа
repeat task.wait(1) until LocalPlayer.Character

-- Инициализация PhysicsService для Noclip
if not PhysicsService:GetCollisionGroups()[1] then
    PhysicsService:CreateCollisionGroup("NoclipGroup")
    PhysicsService:CollisionGroupSetCollidable("NoclipGroup", "Default", false)
end

-- Состояния фарма
local farmingModules = {
    mastery = { enabled = false, thread = nil, toggle = nil, light = nil },
    fruits = { enabled = false, thread = nil, toggle = nil, light = nil },
    chests = { enabled = false, thread = nil, toggle = nil, light = nil },
    bones = { enabled = false, thread = nil, toggle = nil, light = nil }
}

-- Настройки выбора мобов
local mobSelection = {
    world1 = {
        ["Bandit"] = true,
        ["Monkey"] = true,
        ["Pirate"] = true
    },
    world2 = {
        ["Desert Bandit"] = true,
        ["Desert Officer"] = true,
        ["Snow Bandit"] = true,
        ["Snowman"] = true
    },
    world3 = {
        ["Galley Pirate"] = true,
        ["Galley Captain"] = true,
        ["Forest Pirate"] = true
    }
}

-- Цвета для визуальной индикации
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

-- Включение Noclip
local function enableNoclip()
    local character = LocalPlayer.Character
    if not character then return end
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, "NoclipGroup")
            part.CanCollide = false
        end
    end
end

-- Функция для полета к цели
local function flyTo(targetPosition, heightOffset)
    local character = LocalPlayer.Character
    if not character then return 9999 end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return 9999 end
    
    -- Добавляем смещение по высоте
    local target = targetPosition + Vector3.new(0, heightOffset or 10, 0)
    
    -- Рассчитываем направление
    local direction = (target - humanoidRootPart.Position).Unit
    
    -- Устанавливаем скорость
    humanoidRootPart.AssemblyLinearVelocity = direction * 100
    
    -- Возвращаем расстояние до цели
    return (target - humanoidRootPart.Position).Magnitude
end

-- Улучшенная функция для атаки врагов
local function attackEnemy()
    if not LocalPlayer.Character then return end
    
    -- Эмуляция атаки
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    
    if tool then
        -- Используем оружие
        for i = 1, 3 do
            tool:Activate()
            task.wait(0.1)
        end
    else
        -- Эмуляция кликов мыши (более надежная)
        local VU = game:GetService("VirtualUser")
        VU:CaptureController()
        VU:ClickButton1(Vector2.new(0,0), CFrame.new())
    end
end

-- Поиск лучшего врага по приоритету
local function findBestEnemy()
    if not LocalPlayer.Character then return nil end
    
    local bestEnemy = nil
    local highestPriority = -math.huge
    local characterPosition = LocalPlayer.Character.HumanoidRootPart.Position
    
    -- Приоритеты для разных типов врагов
    local enemyPriority = {
        ["Galley Captain"] = 100,
        ["Desert Officer"] = 90,
        ["Military Soldier"] = 80,
        ["Pirate"] = 70,
        ["Bandit"] = 60,
        ["Monkey"] = 50
    }
    
    for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
        if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
            local enemyName = enemy.Name
            
            -- Проверяем, выбран ли этот тип врага в настройках
            local isSelected = false
            
            if mobSelection.world1[enemyName] then
                isSelected = mobSelection.world1[enemyName]
            elseif mobSelection.world2[enemyName] then
                isSelected = mobSelection.world2[enemyName]
            elseif mobSelection.world3[enemyName] then
                isSelected = mobSelection.world3[enemyName]
            end
            
            if isSelected then
                -- Рассчитываем приоритет: базовый приоритет + здоровье + близость
                local priority = enemyPriority[enemyName] or 50
                priority = priority + enemy.Humanoid.Health * 0.1
                
                -- Учитываем расстояние (чем ближе, тем лучше)
                local distance = (characterPosition - enemy.HumanoidRootPart.Position).Magnitude
                priority = priority + (100 / math.max(1, distance))
                
                if priority > highestPriority then
                    highestPriority = priority
                    bestEnemy = enemy
                end
            end
        end
    end
    
    return bestEnemy
end

-- Улучшенная функция фарма мастери с атакой
local function startMasteryFarm()
    while farmingModules.mastery.enabled and task.wait(0.1) do
        -- Проверка на смерть
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
            task.wait(2)
            continue
        end
        
        -- Включаем noclip
        enableNoclip()
        
        -- Поиск лучшего врага по приоритету
        local bestEnemy = findBestEnemy()
        
        if bestEnemy then
            -- Летим к врагу и позиционируемся над ним
            flyTo(bestEnemy.HumanoidRootPart.Position, 15)
            
            -- Атака врага (даже если мы не очень близко)
            attackEnemy()
        else
            print("Подходящие враги не найдены. Проверьте настройки выбора мобов.")
        end
    end
end

-- Остальные функции фарма остаются без изменений
-- ...

-- Создание меню (ваш оригинальный код с небольшими улучшениями)
-- ... [ваш код создания меню без изменений] ...

-- Обработчик клавиши M
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.M and not gameProcessed then
        if not farmingGui then
            createFarmingMenu()
        else
            farmingGui.Enabled = not farmingGui.Enabled
        end
    end
end)

-- Уведомление
task.spawn(function()
    task.wait(3) -- Ждем загрузки
    game.StarterGui:SetCore("SendNotification", {
        Title = "ФАРМ МЕНЮ АКТИВИРОВАН",
        Text = "Нажмите M для открытия меню\nАвтоатака включена",
        Icon = "rbxassetid://6726578090",
        Duration = 10
    })
    print("Фарм-меню готово! Нажмите M для открытия.")
end)

-- Автоматическое отключение фарма при смерти
LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid").Died:Connect(function()
        for key, module in pairs(farmingModules) do
            if module.enabled and module.thread then
                task.cancel(module.thread)
                module.thread = nil
                module.enabled = false
                
                -- Обновляем визуальное состояние
                if module.toggle and module.light then
                    animateToggle(module, key)
                end
            end
        end
    end)
end)

-- Автоматическая атака при приближении к врагу
task.spawn(function()
    while task.wait(0.1) do
        if farmingModules.mastery.enabled and LocalPlayer.Character then
            -- Постоянная атака при включенном фарме
            attackEnemy()
        end
    end
end)

print("Фарм-скрипт успешно загружен! Автоатака активирована")
