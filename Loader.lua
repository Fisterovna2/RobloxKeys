repeat task.wait(1) until game:IsLoaded()

-- Глобальные переменные
local farmingGui = nil
local mobSelectionGui = nil
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- Определение текущего мира
local function getCurrentWorld()
    local playerLevel = LocalPlayer.Data.Level.Value
    if playerLevel < 700 then
        return "world1"
    elseif playerLevel < 1500 then
        return "world2"
    else
        return "world3"
    end
end

-- Логирование с меткой времени
local function log(message)
    print("[FARM] [" .. os.date("%H:%M:%S") .. "] " .. message)
end

-- Эмуляция кликов мыши
local function mouse1press()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, false)
end

local function mouse1release()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, false)
end

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
    if not character then 
        log("Персонаж не найден для полета")
        return 9999 
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then 
        log("HumanoidRootPart не найден")
        return 9999 
    end
    
    -- Добавляем смещение по высоте
    local target = targetPosition + Vector3.new(0, heightOffset or 15, 0)
    
    -- Рассчитываем направление
    local direction = (target - humanoidRootPart.Position).Unit
    
    -- Устанавливаем скорость
    humanoidRootPart.AssemblyLinearVelocity = direction * 150
    
    -- Возвращаем расстояние до цели
    return (target - humanoidRootPart.Position).Magnitude
end

-- Увеличение хитбокса игрока
local function enlargePlayerHitbox()
    local character = LocalPlayer.Character
    if not character then return end
    
    local hitbox = character:FindFirstChild("BuddhaHitbox")
    if not hitbox then
        hitbox = Instance.new("Part")
        hitbox.Name = "BuddhaHitbox"
        hitbox.Size = Vector3.new(25, 25, 25)
        hitbox.Transparency = 1
        hitbox.CanCollide = false
        hitbox.Anchored = false
        hitbox.Parent = character
        
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = character.HumanoidRootPart
        weld.Part1 = hitbox
        weld.Parent = hitbox
        log("Создан увеличенный хитбокс")
    end
end

-- Улучшенная функция для атаки врагов
local function attackEnemy(enemy)
    if not LocalPlayer.Character or not enemy then 
        log("Невозможно атаковать: персонаж или враг отсутствует")
        return 
    end
    
    if not enemy:FindFirstChild("Humanoid") or enemy.Humanoid.Health <= 0 then
        log("Враг мертв или не имеет Humanoid")
        return
    end
    
    -- Увеличиваем хитбокс игрока
    enlargePlayerHitbox()
    
    -- Пробуем использовать сначала меч, потом оружие, потом стиль боя
    local sword = nil
    local gun = nil
    
    -- Проверяем инвентарь
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.Name:find("Sword") or tool.Name:find("Melee") then
                sword = tool
                break
            elseif tool.Name:find("Gun") or tool.Name:find("Weapon") then
                gun = tool
            end
        end
    end
    
    -- Экипируем оружие при необходимости
    if sword then
        sword.Parent = LocalPlayer.Character
        for i = 1, 3 do
            sword:Activate()
            task.wait(0.1)
        end
    elseif gun then
        gun.Parent = LocalPlayer.Character
        for i = 1, 3 do
            gun:Activate()
            task.wait(0.1)
        end
    else
        -- Эмуляция кликов мыши
        mouse1press()
        task.wait(0.1)
        mouse1release()
    end
end

-- Поиск лучшего врага по приоритету (оптимизированный)
local function findBestEnemy()
    if not LocalPlayer.Character then 
        log("Персонаж не найден для поиска врагов")
        return nil 
    end
    
    local bestEnemy = nil
    local highestPriority = -math.huge
    local characterPosition = LocalPlayer.Character.HumanoidRootPart.Position
    
    local currentWorld = getCurrentWorld()
    log("Текущий мир: " .. currentWorld)
    
    -- Возможные места поиска врагов
    local searchLocations = {
        workspace:FindFirstChild("Enemies"),
        workspace:FindFirstChild("Live"),
        workspace:FindFirstChild("NPCs"),
        workspace
    }
    
    for _, location in ipairs(searchLocations) do
        if location then
            for _, enemy in ipairs(location:GetChildren()) do
                if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                    local enemyName = enemy.Name
                    
                    -- Проверяем, выбран ли этот тип врага в настройках
                    local isSelected = mobSelection[currentWorld][enemyName]
                    
                    if isSelected then
                        -- Рассчитываем приоритет: здоровье + близость
                        local priority = enemy.Humanoid.Health * 0.1
                        local distance = (characterPosition - enemy.HumanoidRootPart.Position).Magnitude
                        priority = priority + (100 / math.max(1, distance))
                        
                        if priority > highestPriority then
                            highestPriority = priority
                            bestEnemy = enemy
                        end
                    end
                end
            end
        end
    end
    
    if bestEnemy then
        log("Найден враг: " .. bestEnemy.Name)
    else
        log("Подходящие враги не найдены")
    end
    
    return bestEnemy
end

-- Улучшенная функция фарма мастери с добиванием
local function startMasteryFarm()
    log("Фарм мастери запущен")
    while farmingModules.mastery.enabled and task.wait(0.1) do
        -- Проверка на смерть
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
            log("Персонаж мертв, ожидаем возрождения")
            task.wait(2)
            continue
        end
        
        -- Включаем noclip
        enableNoclip()
        
        -- Поиск лучшего врага по приоритету
        local bestEnemy = findBestEnemy()
        
        if bestEnemy then
            -- Летим к врагу и позиционируемся над ним
            local distance = flyTo(bestEnemy.HumanoidRootPart.Position, 15)
            
            -- Атака врага только если мы на безопасном расстоянии
            if distance < 100 then
                -- Добиваем врага до смерти
                while bestEnemy and bestEnemy:FindFirstChild("Humanoid") and bestEnemy.Humanoid.Health > 0 and farmingModules.mastery.enabled do
                    attackEnemy(bestEnemy)
                    task.wait(0.1)
                end
            end
        else
            task.wait(1)
        end
    end
    log("Фарм мастери остановлен")
end

-- Функция для поиска фруктов (оптимизированная)
local function findBestFruit()
    local bestFruit = nil
    local minDistance = math.huge
    local character = LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    -- Возможные места поиска фруктов
    local searchLocations = {
        workspace:FindFirstChild("Fruits"),
        workspace:FindFirstChild("Fruit"),
        workspace:FindFirstChild("SpawnedFruits"),
        workspace
    }
    
    for _, location in ipairs(searchLocations) do
        if location then
            for _, obj in ipairs(location:GetDescendants()) do
                if obj.Name == "Handle" and (obj.Parent.Name:find("Fruit") or obj.Parent.Name:find("Apple")) then
                    local distance = (rootPart.Position - obj.Position).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        bestFruit = obj.Parent
                    end
                end
            end
        end
    end
    
    if bestFruit then
        log("Найден фрукт: " .. bestFruit.Name)
    else
        log("Фрукты не найдены")
    end
    
    return bestFruit
end

-- Функция для поиска Blox Fruits Gacha
local function findGacha()
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then 
        log("Папка NPC не найдена")
        return nil 
    end
    
    for _, npc in ipairs(npcs:GetChildren()) do
        if npc.Name:find("Blox Fruits Gacha") and npc:FindFirstChild("HumanoidRootPart") then
            log("Найден Gacha: " .. npc.Name)
            return npc
        end
    end
    
    log("Gacha не найден")
    return nil
end

-- Функция фарма фруктов
local function startFruitFarm()
    log("Фарм фруктов запущен")
    while farmingModules.fruits.enabled and task.wait(0.1) do
        -- Проверка на смерть
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
            log("Персонаж мертв, ожидаем возрождения")
            task.wait(2)
            continue
        end
        
        -- Включаем noclip
        enableNoclip()
        
        -- Поиск фруктов
        local bestFruit = findBestFruit()
        
        if bestFruit then
            flyTo(bestFruit.Handle.Position, 5)
        else
            -- Если фруктов нет, летим к Gacha для крутки
            local gacha = findGacha()
            if gacha then
                flyTo(gacha.HumanoidRootPart.Position, 5)
            else
                task.wait(1)
            end
        end
    end
    log("Фарм фруктов остановлен")
end

-- Функция для поиска сундуков (оптимизированная)
local function findBestChest()
    local bestChest = nil
    local minDistance = math.huge
    local character = LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:find("Chest") and obj:IsA("Model") and obj:FindFirstChild("Chest") then
            local chestPart = obj.Chest
            if chestPart:IsA("BasePart") then
                local distance = (rootPart.Position - chestPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    bestChest = chestPart
                end
            end
        end
    end
    
    if bestChest then
        log("Найден сундук: " .. bestChest.Parent.Name)
    else
        log("Сундуки не найдены")
    end
    
    return bestChest
end

-- Функция фарма сундуков
local function startChestFarm()
    log("Фарм сундуков запущен")
    while farmingModules.chests.enabled and task.wait(0.2) do
        -- Проверка на смерть
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
            log("Персонаж мертв, ожидаем возрождения")
            task.wait(2)
            continue
        end
        
        -- Включаем noclip
        enableNoclip()
        
        -- Поиск сундуков
        local bestChest = findBestChest()
        
        if bestChest then
            flyTo(bestChest.Position, 5)
            
            -- Сбор сундука при близком расстоянии
            if (LocalPlayer.Character.HumanoidRootPart.Position - bestChest.Position).Magnitude < 10 then
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, bestChest, 0)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, bestChest, 1)
                log("Сундук собран: " .. bestChest.Parent.Name)
                task.wait(0.5)
            end
        else
            task.wait(1)
        end
    end
    log("Фарм сундуков остановлен")
end

-- Функция для поиска костей (полностью переработанная)
local function findBone()
    -- Возможные места поиска костей
    local searchLocations = {
        workspace:FindFirstChild("Bones"),
        workspace:FindFirstChild("Items"),
        workspace:FindFirstChild("World"),
        workspace
    }
    
    for _, location in ipairs(searchLocations) do
        if location then
            for _, obj in ipairs(location:GetDescendants()) do
                if obj:IsA("MeshPart") and obj.Name:lower():find("bone") and obj:FindFirstChild("ClickDetector") then
                    log("Найдена кость: " .. obj.Name)
                    return obj
                end
            end
        end
    end
    
    log("Кости не найдены")
    return nil
end

-- Функция фарма костей
local function startBonesFarm()
    log("Фарм костей запущен")
    while farmingModules.bones.enabled and task.wait(0.1) do
        -- Проверка на смерть
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
            log("Персонаж мертв, ожидаем возрождения")
            task.wait(2)
            continue
        end
        
        -- Включаем noclip
        enableNoclip()
        
        -- Поиск костей
        local bone = findBone()
        
        if bone then
            flyTo(bone.Position, 5)
            
            -- Сбор кости при близком расстоянии
            if (LocalPlayer.Character.HumanoidRootPart.Position - bone.Position).Magnitude < 10 then
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, bone, 0)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, bone, 1)
                log("Кость собрана: " .. bone.Name)
                task.wait(0.5)
            end
        else
            task.wait(1)
        end
    end
    log("Фарм костей остановлен")
end

-- Создание меню фарма
local function createFarmingMenu()
    if farmingGui then farmingGui:Destroy() end
    
    farmingGui = Instance.new("ScreenGui")
    farmingGui.Name = "FarmingMenuGUI"
    farmingGui.Parent = game:GetService("CoreGui")
    farmingGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 380, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = farmingGui
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Text = "BLOCK FRUITS FARM MENU"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.Parent = mainFrame
    
    -- Список функций
    local features = {
        { name = "ФАРМ МАСТЕРИ", key = "mastery", icon = "🔫" },
        { name = "ФАРМ ФРУКТОВ", key = "fruits", icon = "🍎" },
        { name = "ФАРМ СУНДУКОВ", key = "chests", icon = "📦" },
        { name = "ФАРМ КОСТЕЙ", key = "bones", icon = "💀" }
    }
    
    for i, feature in ipairs(features) do
        local yPos = 60 + (i-1)*85
        
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0.9, 0, 0, 70)
        container.Position = UDim2.new(0.05, 0, 0, yPos)
        container.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        container.BackgroundTransparency = 0.3
        container.Parent = mainFrame
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Text = feature.icon
        iconLabel.Size = UDim2.new(0, 50, 0, 50)
        iconLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
        iconLabel.TextSize = 30
        iconLabel.BackgroundTransparency = 1
        iconLabel.TextColor3 = colorThemes[feature.key].off
        iconLabel.Parent = container
        
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
        
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(0, 80, 0, 30)
        toggleFrame.Position = UDim2.new(0.7, 0, 0.3, 0)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        toggleFrame.Parent = container
        
        local light = Instance.new("Frame")
        light.Size = UDim2.new(0, 12, 0, 12)
        light.Position = UDim2.new(0.1, 0, 0.3, 0)
        light.BackgroundColor3 = colorThemes[feature.key].off
        light.ZIndex = 2
        light.Parent = toggleFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = light
        
        local statusText = Instance.new("TextLabel")
        statusText.Size = UDim2.new(0.6, 0, 1, 0)
        statusText.Position = UDim2.new(0.3, 0, 0, 0)
        statusText.Text = "ВЫКЛ"
        statusText.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        statusText.Font = Enum.Font.GothamBold
        statusText.TextSize = 14
        statusText.BackgroundTransparency = 1
        statusText.Parent = toggleFrame
        
        farmingModules[feature.key].toggle = statusText
        farmingModules[feature.key].light = light
        animateToggle(farmingModules[feature.key], feature.key)
        
        local clickArea = Instance.new("TextButton")
        clickArea.Size = UDim2.new(1, 0, 1, 0)
        clickArea.BackgroundTransparency = 1
        clickArea.Text = ""
        clickArea.ZIndex = 5
        clickArea.Parent = toggleFrame
        
        clickArea.MouseButton1Click:Connect(function()
            -- Выключаем все другие модули
            for key, module in pairs(farmingModules) do
                if key ~= feature.key and module.enabled then
                    module.enabled = false
                    animateToggle(module, key)
                    if module.thread then
                        task.cancel(module.thread)
                        module.thread = nil
                    end
                end
            end
            
            -- Включаем/выключаем текущий модуль
            farmingModules[feature.key].enabled = not farmingModules[feature.key].enabled
            animateToggle(farmingModules[feature.key], feature.key)
            
            if farmingModules[feature.key].enabled then
                if feature.key == "mastery" then
                    farmingModules.mastery.thread = task.spawn(startMasteryFarm)
                elseif feature.key == "fruits" then
                    farmingModules.fruits.thread = task.spawn(startFruitFarm)
                elseif feature.key == "chests" then
                    farmingModules.chests.thread = task.spawn(startChestFarm)
                elseif feature.key == "bones" then
                    farmingModules.bones.thread = task.spawn(startBonesFarm)
                end
            else
                if farmingModules[feature.key].thread then
                    task.cancel(farmingModules[feature.key].thread)
                    farmingModules[feature.key].thread = nil
                end
            end
        end)
    end
    
    -- Кнопка выбора мобов
    local mobsBtn = Instance.new("TextButton")
    mobsBtn.Text = "ВЫБОР МОБОВ (N)"
    mobsBtn.Size = UDim2.new(0.9, 0, 0, 40)
    mobsBtn.Position = UDim2.new(0.05, 0, 0, 440)
    mobsBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 180)
    mobsBtn.TextColor3 = Color3.new(1, 1, 1)
    mobsBtn.Font = Enum.Font.GothamBold
    mobsBtn.TextSize = 16
    mobsBtn.Parent = mainFrame
    
    mobsBtn.MouseButton1Click:Connect(function()
        createMobSelectionMenu()
    end)
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "ЗАКРЫТЬ МЕНЮ"
    closeBtn.Size = UDim2.new(0.9, 0, 0, 40)
    closeBtn.Position = UDim2.new(0.05, 0, 0, 490)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = mainFrame
    
    closeBtn.MouseButton1Click:Connect(function()
        farmingGui:Destroy()
        farmingGui = nil
    end)
    
    -- Скругление углов
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    return farmingGui
end

-- Создание меню выбора мобов
local function createMobSelectionMenu()
    if mobSelectionGui then mobSelectionGui:Destroy() end
    
    mobSelectionGui = Instance.new("ScreenGui")
    mobSelectionGui.Name = "MobSelectionGUI"
    mobSelectionGui.Parent = game:GetService("CoreGui")
    mobSelectionGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 380, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = mobSelectionGui
    
    local title = Instance.new("TextLabel")
    title.Text = "ВЫБОР МОБОВ"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.Parent = mainFrame
    
    local worlds = {
        { name = "МИР 1", key = "world1" },
        { name = "МИР 2", key = "world2" },
        { name = "МИР 3", key = "world3" }
    }
    
    local yOffset = 60
    for _, world in ipairs(worlds) do
        local worldTitle = Instance.new("TextLabel")
        worldTitle.Text = world.name
        worldTitle.Size = UDim2.new(0.9, 0, 0, 30)
        worldTitle.Position = UDim2.new(0.05, 0, 0, yOffset)
        worldTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
        worldTitle.Font = Enum.Font.GothamBold
        worldTitle.TextSize = 16
        worldTitle.BackgroundTransparency = 1
        worldTitle.TextXAlignment = Enum.TextXAlignment.Left
        worldTitle.Parent = mainFrame
        
        yOffset = yOffset + 35
        
        for mobName, selected in pairs(mobSelection[world.key]) do
            local mobFrame = Instance.new("Frame")
            mobFrame.Size = UDim2.new(0.9, 0, 0, 30)
            mobFrame.Position = UDim2.new(0.05, 0, 0, yOffset)
            mobFrame.BackgroundTransparency = 1
            mobFrame.Parent = mainFrame
            
            local mobLabel = Instance.new("TextLabel")
            mobLabel.Text = mobName
            mobLabel.Size = UDim2.new(0.7, 0, 1, 0)
            mobLabel.Position = UDim2.new(0, 0, 0, 0)
            mobLabel.TextColor3 = Color3.new(1, 1, 1)
            mobLabel.Font = Enum.Font.Gotham
            mobLabel.TextSize = 14
            mobLabel.BackgroundTransparency = 1
            mobLabel.TextXAlignment = Enum.TextXAlignment.Left
            mobLabel.Parent = mobFrame
            
            local mobToggle = Instance.new("TextButton")
            mobToggle.Size = UDim2.new(0.25, 0, 1, 0)
            mobToggle.Position = UDim2.new(0.75, 0, 0, 0)
            mobToggle.BackgroundColor3 = selected and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
            mobToggle.Text = selected and "ВКЛ" or "ВЫКЛ"
            mobToggle.TextColor3 = Color3.new(1, 1, 1)
            mobToggle.Font = Enum.Font.GothamBold
            mobToggle.TextSize = 12
            mobToggle.Parent = mobFrame
            
            mobToggle.MouseButton1Click:Connect(function()
                local newState = not mobSelection[world.key][mobName]
                mobSelection[world.key][mobName] = newState
                
                if newState then
                    mobToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                    mobToggle.Text = "ВКЛ"
                else
                    mobToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
                    mobToggle.Text = "ВЫКЛ"
                end
            end)
            
            yOffset = yOffset + 35
        end
        yOffset = yOffset + 15
    end
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "ЗАКРЫТЬ (N)"
    closeBtn.Size = UDim2.new(0.9, 0, 0, 40)
    closeBtn.Position = UDim2.new(0.05, 0, 0, yOffset + 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = mainFrame
    
    closeBtn.MouseButton1Click:Connect(function()
        mobSelectionGui:Destroy()
        mobSelectionGui = nil
    end)
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    return mobSelectionGui
end

-- Обработчики клавиш
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        if farmingGui and farmingGui.Enabled then
            farmingGui.Enabled = false
        else
            createFarmingMenu()
        end
    elseif input.KeyCode == Enum.KeyCode.N then
        if mobSelectionGui and mobSelectionGui.Enabled then
            mobSelectionGui.Enabled = false
        else
            createMobSelectionMenu()
        end
    end
end)

-- Уведомление
task.spawn(function()
    task.wait(3)
    game.StarterGui:SetCore("SendNotification", {
        Title = "ФАРМ МЕНЮ АКТИВИРОВАН",
        Text = "M: Меню фарма\nN: Выбор мобов",
        Icon = "rbxassetid://6726578090",
        Duration = 10
    })
    log("Фарм-меню готово! Нажмите M для открытия.")
end)

log("Фарм-скрипт успешно загружен!")
