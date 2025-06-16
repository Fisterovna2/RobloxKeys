repeat task.wait() until game:IsLoaded()

-- Глобальные переменные
local farmingGui = nil
local menuVisible = false
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Состояния фарма с визуальными индикаторами
local farmingModules = {
    mastery = { enabled = false, thread = nil, toggle = nil, light = nil },
    fruits = { enabled = false, thread = nil, toggle = nil, light = nil },
    chests = { enabled = false, thread = nil, toggle = nil, light = nil },
    bones = { enabled = false, thread = nil, toggle = nil, light = nil }
}

-- Цвета для визуальной индикации
local colorThemes = {
    mastery = { on = Color3.fromRGB(0, 255, 170), off = Color3.fromRGB(100, 100, 100) },
    fruits = { on = Color3.fromRGB(255, 125, 0), off = Color3.fromRGB(100, 100, 100) },
    chests = { on = Color3.fromRGB(255, 255, 0), off = Color3.fromRGB(100, 100, 100) },
    bones = { on = Color3.fromRGB(180, 0, 255), off = Color3.fromRGB(100, 100, 100) }
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

-- Переменные для полета
local flying = false
local flySpeed = 100
local bodyVelocity = nil
local bodyGyro = nil
local noclipConnection = nil

-- Анимация переключения
local function animateToggle(module, key)
    if module.toggle and module.light then
        local targetColor = module.enabled and colorThemes[key].on or colorThemes[key].off
        
        -- Анимация фона
        TweenService:Create(
            module.toggle,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = targetColor }
        ):Play()
        
        -- Анимация "светодиода"
        TweenService:Create(
            module.light,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundColor3 = targetColor }
        ):Play()
        
        -- Анимация текста
        module.toggle.Text = module.enabled and "ВКЛ" or "ВЫКЛ"
    end
end

-- Функция включения/выключения полета
local function toggleFlight(enabled)
    flying = enabled
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    if enabled then
        -- Создаем инструменты для полета
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
        bodyVelocity.P = 1000
        bodyVelocity.Parent = humanoidRootPart
        
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(10000, 10000, 10000)
        bodyGyro.P = 1000
        bodyGyro.D = 100
        bodyGyro.Parent = humanoidRootPart
        
        -- Включаем ноклип
        noclipConnection = RunService.Stepped:Connect(function()
            if flying then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        -- Отключаем полет
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        if bodyGyro then
            bodyGyro:Destroy()
            bodyGyro = nil
        end
        
        -- Отключаем ноклип
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end

-- Функция для полета к цели
local function flyTo(targetPosition, heightOffset)
    if not flying then toggleFlight(true) end
    
    local character = LocalPlayer.Character
    if not character then return 9999 end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return 9999 end
    
    -- Добавляем смещение по высоте
    local target = targetPosition + Vector3.new(0, heightOffset or 10, 0)
    
    -- Рассчитываем направление
    local direction = (target - humanoidRootPart.Position).Unit
    
    -- Устанавливаем скорость
    bodyVelocity.Velocity = direction * flySpeed
    
    -- Устанавливаем ориентацию
    bodyGyro.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + direction)
    
    -- Возвращаем расстояние до цели
    return (target - humanoidRootPart.Position).Magnitude
end

-- Функция для атаки врагов
local function attackEnemy()
    -- Эмуляция атаки
    if not LocalPlayer.Character then return end
    
    -- Проверяем, есть ли оружие в руках
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    
    if tool then
        -- Используем оружие
        for i = 1, 3 do
            tool:Activate()
            task.wait(0.1)
        end
    else
        -- Эмуляция кликов мыши
        mouse1press()
        task.wait(0.2)
        mouse1release()
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
            local world = nil
            
            -- Определяем мир врага по его имени
            if mobSelection.world1[enemyName] then
                isSelected = mobSelection.world1[enemyName]
                world = 1
            elseif mobSelection.world2[enemyName] then
                isSelected = mobSelection.world2[enemyName]
                world = 2
            elseif mobSelection.world3[enemyName] then
                isSelected = mobSelection.world3[enemyName]
                world = 3
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

-- Функция фарма мастери (с полетом и атакой сверху)
local function startMasteryFarm()
    while farmingModules.mastery.enabled and task.wait(0.1) do
        -- Проверка на смерть
        if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
            task.wait(2)
            continue
        end
        
        -- Поиск лучшего врага по приоритету
        local bestEnemy = findBestEnemy()
        
        if bestEnemy then
            -- Летим к врагу и позиционируемся над ним
            local distance = flyTo(bestEnemy.HumanoidRootPart.Position, 15)
            
            -- Атака, если враг близко
            if distance < 50 then
                attackEnemy()
            end
        else
            print("Подходящие враги не найдены. Проверьте настройки выбора мобов.")
        end
    end
    
    -- Отключаем полет при остановке фарма
    if flying then toggleFlight(false) end
end

-- Функция фарма фруктов (с полетом)
local function startFruitFarm()
    while farmingModules.fruits.enabled and task.wait(0.1) do
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
            
            flyTo(fruits[1].Handle.Position, 5)
        end
    end
    
    -- Отключаем полет при остановке фарма
    if flying then toggleFlight(false) end
end

-- Функция фарма сундуков (с полетом)
local function startChestFarm()
    while farmingModules.chests.enabled and task.wait(0.1) do
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
            
            flyTo(chests[1].Position, 5)
        end
    end
    
    -- Отключаем полет при остановке фарма
    if flying then toggleFlight(false) end
end

-- Функция фарма костей (с полетом)
local function startBonesFarm()
    while farmingModules.bones.enabled and task.wait(0.1) do
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
            
            flyTo(bones[1].Position, 5)
        end
    end
    
    -- Отключаем полет при остановке фарма
    if flying then toggleFlight(false) end
end

-- Создание меню с визуальными переключателями
local function createFarmingMenu()
    if farmingGui then farmingGui:Destroy() end
    
    farmingGui = Instance.new("ScreenGui")
    farmingGui.Name = "FarmingMenuGUI"
    farmingGui.Parent = game:GetService("CoreGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 380, 0, 500) -- Увеличили высоту для настроек
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
    title.Text = "BLOCK FRUITS FARM MENU (FLY)"
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
    
    -- Настройки выбора мобов
    local mobsTitle = Instance.new("TextLabel")
    mobsTitle.Text = "ВЫБОР МОБОВ:"
    mobsTitle.Size = UDim2.new(0.9, 0, 0, 20)
    mobsTitle.Position = UDim2.new(0.05, 0, 0, 380)
    mobsTitle.TextColor3 = Color3.new(1, 1, 1)
    mobsTitle.Font = Enum.Font.GothamBold
    mobsTitle.TextSize = 16
    mobsTitle.BackgroundTransparency = 1
    mobsTitle.TextXAlignment = Enum.TextXAlignment.Left
    mobsTitle.Parent = mainFrame
    
    -- Создаем контейнеры для миров
    local worldFrames = {}
    local worldToggles = {}
    
    for worldIndex = 1, 3 do
        local worldFrame = Instance.new("Frame")
        worldFrame.Size = UDim2.new(0.28, 0, 0, 30)
        worldFrame.Position = UDim2.new(0.05 + (worldIndex-1)*0.31, 0, 0, 400)
        worldFrame.BackgroundTransparency = 1
        worldFrame.Parent = mainFrame
        
        local worldLabel = Instance.new("TextLabel")
        worldLabel.Text = "МИР " .. worldIndex
        worldLabel.Size = UDim2.new(0.4, 0, 1, 0)
        worldLabel.Position = UDim2.new(0, 0, 0, 0)
        worldLabel.TextColor3 = Color3.new(1, 1, 1)
        worldLabel.Font = Enum.Font.Gotham
        worldLabel.TextSize = 14
        worldLabel.BackgroundTransparency = 1
        worldLabel.TextXAlignment = Enum.TextXAlignment.Left
        worldLabel.Parent = worldFrame
        
        local worldToggle = Instance.new("TextButton")
        worldToggle.Size = UDim2.new(0.55, 0, 1, 0)
        worldToggle.Position = UDim2.new(0.45, 0, 0, 0)
        worldToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        worldToggle.Text = "ВЫКЛ"
        worldToggle.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        worldToggle.Font = Enum.Font.GothamBold
        worldToggle.TextSize = 12
        worldToggle.Parent = worldFrame
        
        worldToggles[worldIndex] = worldToggle
        worldFrames[worldIndex] = worldFrame
        
        -- Обновляем состояние переключателя мира
        local anyMobSelected = false
        for mobName, selected in pairs(mobSelection["world"..worldIndex]) do
            if selected then
                anyMobSelected = true
                break
            end
        end
        
        if anyMobSelected then
            worldToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            worldToggle.Text = "ВКЛ"
        end
        
        -- Обработчик клика для переключателя мира
        worldToggle.MouseButton1Click:Connect(function()
            local worldKey = "world"..worldIndex
            local newState = worldToggle.Text == "ВЫКЛ"
            
            -- Переключаем все мобы в этом мире
            for mobName, _ in pairs(mobSelection[worldKey]) do
                mobSelection[worldKey][mobName] = newState
            end
            
            -- Обновляем визуальное состояние
            if newState then
                worldToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                worldToggle.Text = "ВКЛ"
            else
                worldToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                worldToggle.Text = "ВЫКЛ"
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
        menuVisible = false
    end)
    
    -- Скругление углов главного окна
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    return farmingGui
end

-- Обработчик клавиши M
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.M and not gameProcessed then
        menuVisible = not menuVisible
        
        if menuVisible then
            createFarmingMenu()
            print("Меню открыто")
        else
            if farmingGui then
                farmingGui:Destroy()
                farmingGui = nil
                print("Меню закрыто")
            end
        end
    end
end)

-- Загрузка скрипта Blox Fruits (если нужно)
if game.PlaceId == 2753915549 then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Fisterovna2/RobloxKeys/main/Loader.lua"))()
    end)
end

-- Уведомление
task.spawn(function()
    task.wait(3) -- Ждем загрузки
    game.StarterGui:SetCore("SendNotification", {
        Title = "ФАРМ МЕНЮ (ПОЛЕТ)",
        Text = "Нажмите M для открытия/закрытия меню",
        Icon = "rbxassetid://6726578090",
        Duration = 5
    })
    print("Меню фарма готово! Нажмите M для открытия.")
end)

-- Диагностика
task.spawn(function()
    while true do
        task.wait(5)
        print("Скрипт активен. Меню:", menuVisible and "открыто" or "закрыто")
    end
end)
