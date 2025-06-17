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
local Camera = workspace.CurrentCamera

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
    if not character then return 9999 end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return 9999 end
    
    -- Добавляем смещение по высоте
    local target = targetPosition + Vector3.new(0, heightOffset or 15, 0)
    
    -- Рассчитываем направление
    local direction = (target - humanoidRootPart.Position).Unit
    
    -- Устанавливаем скорость
    humanoidRootPart.AssemblyLinearVelocity = direction * 150
    
    -- Возвращаем расстояние до цели
    return (target - humanoidRootPart.Position).Magnitude
end

-- Улучшенная функция для атаки врагов
local function attackEnemy(enemy)
    if not LocalPlayer.Character or not enemy then return end
    if not enemy:FindFirstChild("Humanoid") or enemy.Humanoid.Health <= 0 then return end
    
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
    
    -- Расширяем хитбокс врага (увеличиваем размеры его коллизии)
    if enemy:FindFirstChild("HumanoidRootPart") then
        local hitbox = enemy:FindFirstChild("Hitbox") or Instance.new("Part", enemy)
        hitbox.Name = "Hitbox"
        hitbox.Size = Vector3.new(15, 15, 15)  -- Увеличенный хитбокс
        hitbox.Transparency = 1
        hitbox.CanCollide = false
        hitbox.Anchored = false
        hitbox.Position = enemy.HumanoidRootPart.Position
        local weld = Instance.new("WeldConstraint", hitbox)
        weld.Part0 = enemy.HumanoidRootPart
        weld.Part1 = hitbox
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
    
    -- Собираем всех врагов в радиусе 2000
    for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
        if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
            local enemyName = enemy.Name
            local distance = (characterPosition - enemy.HumanoidRootPart.Position).Magnitude
            
            -- Пропускаем слишком далеких врагов
            if distance > 2000 then continue end
            
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

-- Улучшенная функция фарма мастери с безопасной атакой
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
            local distance = flyTo(bestEnemy.HumanoidRootPart.Position, 15)
            
            -- Атака врага только если мы на безопасном расстоянии
            if distance < 100 then
                attackEnemy(bestEnemy)
                
                -- Добиваем врага
                while bestEnemy and bestEnemy:FindFirstChild("Humanoid") and bestEnemy.Humanoid.Health > 0 do
                    attackEnemy(bestEnemy)
                    task.wait(0.1)
                end
            end
        else
            print("Подходящие враги не найдены. Проверьте настройки выбора мобов.")
        end
    end
end

-- Функция для поиска фруктов
local function findBestFruit()
    local fruitsFolder = workspace:FindFirstChild("Fruits")
    if not fruitsFolder then return nil end
    
    local bestFruit = nil
    local minDistance = math.huge
    local character = LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    for _, fruit in ipairs(fruitsFolder:GetChildren()) do
        if fruit:FindFirstChild("Handle") then
            local distance = (rootPart.Position - fruit.Handle.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                bestFruit = fruit
            end
        end
    end
    
    return bestFruit
end

-- Функция для поиска Blox Fruits Gacha (исправленная)
local function findGacha()
    for _, npc in ipairs(workspace.NPCs:GetChildren()) do
        if (npc.Name:find("Blox Fruit Dealer") or npc.Name:find("Fruit Dealer")) and npc:FindFirstChild("HumanoidRootPart") then
            return npc
        end
    end
    return nil
end

-- Функция фарма фруктов (исправленная)
local function startFruitFarm()
    while farmingModules.fruits.enabled and task.wait(0.1) do
        -- Проверка на смерть
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
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
            -- Если фруктов нет, летим к Gacha
            local gacha = findGacha()
            if gacha then
                flyTo(gacha.HumanoidRootPart.Position, 5)
            else
                print("Фрукты и Gacha не найдены")
            end
        end
    end
end

-- Функция для поиска сундуков (исправленная)
local function findBestChest()
    local chests = {}
    
    -- Собираем все сундуки по надежным признакам
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:find("Chest") or obj.Name:find("Crate")) then
            if obj:FindFirstChild("Chest") or obj:FindFirstChild("ChestBox") then
                table.insert(chests, obj)
            end
        end
    end
    
    local bestChest = nil
    local minDistance = math.huge
    local character = LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    for _, chest in ipairs(chests) do
        local chestPart = chest:FindFirstChild("Chest") or chest:FindFirstChild("ChestBox") or chest.PrimaryPart
        if chestPart then
            local distance = (rootPart.Position - chestPart.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                bestChest = chestPart
            end
        end
    end
    
    return bestChest
end

-- Функция фарма сундуков (исправленная)
local function startChestFarm()
    while farmingModules.chests.enabled and task.wait(0.1) do
        -- Проверка на смерть
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
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
            end
        else
            print("Сундуки не найдены")
        end
    end
end

-- Функция для поиска костей
local function findBone()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:find("Bone") and obj:IsA("MeshPart") then
            return obj
        end
    end
    return nil
end

-- Функция фарма костей
local function startBonesFarm()
    while farmingModules.bones.enabled and task.wait(0.1) do
        -- Проверка на смерть
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
            task.wait(2)
            continue
        end
        
        -- Включаем noclip
        enableNoclip()
        
        -- Поиск костей
        local bone = findBone()
        
        if bone then
            flyTo(bone.Position, 5)
        else
            print("Кости не найдены")
        end
    end
end

-- Создание меню с визуальными переключателями
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
    mainFrame.Size = UDim2.new(0, 380, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = farmingGui
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    background.BorderSizePixel = 0
    background.ZIndex = 0
    background.Parent = mainFrame
    
    -- Тень
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.BackgroundTransparency = 1
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
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
        
        -- Контейнер функции
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0.9, 0, 0, 70)
        container.Position = UDim2.new(0.05, 0, 0, yPos)
        container.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        container.BackgroundTransparency = 0.3
        container.Parent = mainFrame
        
        -- Иконка функции
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Text = feature.icon
        iconLabel.Size = UDim2.new(0, 50, 0, 50)
        iconLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
        iconLabel.TextSize = 30
        iconLabel.BackgroundTransparency = 1
        iconLabel.TextColor3 = colorThemes[feature.key].off
        iconLabel.Parent = container
        
        -- Название функции
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
        
        -- Визуальный переключатель
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(0, 80, 0, 30)
        toggleFrame.Position = UDim2.new(0.7, 0, 0.3, 0)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        toggleFrame.BorderSizePixel = 0
        toggleFrame.Parent = container
        
        -- "Светодиод" индикатор
        local light = Instance.new("Frame")
        light.Size = UDim2.new(0, 12, 0, 12)
        light.Position = UDim2.new(0.1, 0, 0.3, 0)
        light.BackgroundColor3 = colorThemes[feature.key].off
        light.BorderSizePixel = 0
        light.ZIndex = 2
        light.Parent = toggleFrame
        
        -- Круглый индикатор
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
        
        -- Сохраняем элементы для анимации
        farmingModules[feature.key].toggle = statusText
        farmingModules[feature.key].light = light
        
        -- Обновляем визуальное состояние
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
            
            -- Анимация переключения
            animateToggle(farmingModules[feature.key], feature.key)
            
            -- Управление функциями
            if feature.key == "mastery" then
                if farmingModules.mastery.enabled then
                    farmingModules.mastery.thread = task.spawn(startMasteryFarm)
                elseif farmingModules.mastery.thread then
                    task.cancel(farmingModules.mastery.thread)
                    farmingModules.mastery.thread = nil
                end
                
            elseif feature.key == "fruits" then
                if farmingModules.fruits.enabled then
                    farmingModules.fruits.thread = task.spawn(startFruitFarm)
                elseif farmingModules.fruits.thread then
                    task.cancel(farmingModules.fruits.thread)
                    farmingModules.fruits.thread = nil
                end
                
            elseif feature.key == "chests" then
                if farmingModules.chests.enabled then
                    farmingModules.chests.thread = task.spawn(startChestFarm)
                elseif farmingModules.chests.thread then
                    task.cancel(farmingModules.chests.thread)
                    farmingModules.chests.thread = nil
                end
                
            elseif feature.key == "bones" then
                if farmingModules.bones.enabled then
                    farmingModules.bones.thread = task.spawn(startBonesFarm)
                elseif farmingModules.bones.thread then
                    task.cancel(farmingModules.bones.thread)
                    farmingModules.bones.thread = nil
                end
            end
        end)
    end
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "ЗАКРЫТЬ (M)"
    closeBtn.Size = UDim2.new(0.9, 0, 0, 40)
    closeBtn.Position = UDim2.new(0.05, 0, 0, 440)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.BackgroundTransparency = 0.3
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = mainFrame
    
    -- Скругление углов кнопки
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = closeBtn
    
    -- Эффект при наведении
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
    end)
    
    -- Скругление углов главного окна
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    return farmingGui
end

-- Создание меню выбора мобов
local function createMobSelectionMenu()
    -- Удаляем старое меню если есть
    if mobSelectionGui then 
        mobSelectionGui:Destroy() 
        mobSelectionGui = nil
    end
    
    -- Создаем новое GUI
    mobSelectionGui = Instance.new("ScreenGui")
    mobSelectionGui.Name = "MobSelectionGUI"
    mobSelectionGui.Parent = game:GetService("CoreGui")
    mobSelectionGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 380, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = mobSelectionGui
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Text = "ВЫБОР МОБОВ"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.Parent = mainFrame
    
    -- Создаем контейнеры для миров
    local worldToggles = {}
    local yOffset = 60
    
    for worldIndex = 1, 3 do
        -- Заголовок мира
        local worldTitle = Instance.new("TextLabel")
        worldTitle.Text = "МИР " .. worldIndex
        worldTitle.Size = UDim2.new(0.9, 0, 0, 30)
        worldTitle.Position = UDim2.new(0.05, 0, 0, yOffset)
        worldTitle.TextColor3 = Color3.fromRGB(0, 200, 255)
        worldTitle.Font = Enum.Font.GothamBold
        worldTitle.TextSize = 16
        worldTitle.BackgroundTransparency = 1
        worldTitle.TextXAlignment = Enum.TextXAlignment.Left
        worldTitle.Parent = mainFrame
        
        yOffset = yOffset + 35
        
        -- Переключатели для каждого моба в мире
        for mobName, selected in pairs(mobSelection["world"..worldIndex]) do
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
            
            -- Обработчик клика для переключателя моба
            mobToggle.MouseButton1Click:Connect(function()
                local newState = not mobSelection["world"..worldIndex][mobName]
                mobSelection["world"..worldIndex][mobName] = newState
                
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
        
        -- Добавляем отступ между мирами
        yOffset = yOffset + 15
    end
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text = "ЗАКРЫТЬ (N)"
    closeBtn.Size = UDim2.new(0.9, 0, 0, 40)
    closeBtn.Position = UDim2.new(0.05, 0, 0, yOffset + 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.BackgroundTransparency = 0.3
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = mainFrame
    
    -- Скругление углов кнопки
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        mobSelectionGui:Destroy()
        mobSelectionGui = nil
    end)
    
    -- Скругление углов главного окна
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    return mobSelectionGui
end

-- Обработчики клавиш
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        -- Переключаем видимость меню фарма
        if farmingGui then
            farmingGui.Enabled = not farmingGui.Enabled
        else
            createFarmingMenu()
        end
        
        print("Меню фарма переключено. Состояние:", farmingGui and farmingGui.Enabled or "не создано")
    elseif input.KeyCode == Enum.KeyCode.N then
        -- Переключаем видимость меню выбора мобов
        if mobSelectionGui then
            mobSelectionGui.Enabled = not mobSelectionGui.Enabled
        else
            createMobSelectionMenu()
        end
        
        print("Меню выбора мобов переключено. Состояние:", mobSelectionGui and mobSelectionGui.Enabled or "не создано")
    end
end)

-- Уведомление
task.spawn(function()
    task.wait(3) -- Ждем загрузки
    game.StarterGui:SetCore("SendNotification", {
        Title = "ФАРМ МЕНЮ АКТИВИРОВАН",
        Text = "Нажмите M для открытия меню фарма\nНажмите N для выбора мобов",
        Icon = "rbxassetid://6726578090",
        Duration = 10
    })
    print("Фарм-меню готово! Нажмите M для открытия.")
end)

-- Диагностика
task.spawn(function()
    while true do
        task.wait(10)
        print("Скрипт активен.")
        print("Меню фарма:", farmingGui and (farmingGui.Enabled and "открыто" or "закрыто") or "не создано")
        print("Меню мобов:", mobSelectionGui and (mobSelectionGui.Enabled and "открыто" or "закрыто") or "не создано")
    end
end)

print("Фарм-скрипт успешно загружен!")
