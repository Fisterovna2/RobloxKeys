repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Очистим предыдущие GUI
if CoreGui:FindFirstChild("HyperFarmUI") then
    CoreGui:FindFirstChild("HyperFarmUI"):Destroy()
end

-- Создаём ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "HyperFarmUI"
gui.Parent = CoreGui
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false

-- Основной фрейм
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 700, 0, 450)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui
mainFrame.Active = true
mainFrame.Draggable = true

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
title.Text = "☠ Hyper Blox Fruits — Ultimate Farm GUI"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = mainFrame

-- Левая панель (навигация)
local navPanel = Instance.new("Frame")
navPanel.Size = UDim2.new(0, 150, 1, -40)
navPanel.Position = UDim2.new(0, 0, 0, 40)
navPanel.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
navPanel.Parent = mainFrame

-- Правая панель (контент)
local contentPanel = Instance.new("Frame")
contentPanel.Size = UDim2.new(1, -150, 1, -40)
contentPanel.Position = UDim2.new(0, 150, 0, 40)
contentPanel.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
contentPanel.Name = "ContentPanel"
contentPanel.ClipsDescendants = true
contentPanel.Parent = mainFrame

-- Функция для создания кнопок навигации
local function createNavButton(name, text, order)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, (order - 1) * 36)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Parent = navPanel
    return btn
end

-- Таб-лист
local tabNames = { "Main", "Sea", "Stats", "Teleport", "Visual" }
local tabButtons = {}
for i, name in ipairs(tabNames) do
    tabButtons[name] = createNavButton(name, name, i)
end
-- Текущая активная вкладка
local currentTab = nil
local tabFrames = {}

-- Функция переключения вкладок
local function switchTab(tabName)
    for name, frame in pairs(tabFrames) do
        frame.Visible = (name == tabName)
    end
    currentTab = tabName
end

-- Создание вкладки
local function createTab(name)
    local tab = Instance.new("Frame")
    tab.Name = name
    tab.Size = UDim2.new(1, 0, 1, 0)
    tab.BackgroundTransparency = 1
    tab.Visible = false
    tab.Parent = contentPanel
    tabFrames[name] = tab
    return tab
end

-- Привязка кнопок
for name, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

-- Активировать первую вкладку
switchTab("Main")

-----------------------------------------------------------------------
-- 🌟 MAIN TAB
-----------------------------------------------------------------------
local mainTab = createTab("Main")

-- Название секции
local sectionTitle = Instance.new("TextLabel", mainTab)
sectionTitle.Size = UDim2.new(1, -20, 0, 30)
sectionTitle.Position = UDim2.new(0, 10, 0, 10)
sectionTitle.Text = "Mastery Farming"
sectionTitle.TextColor3 = Color3.new(1, 1, 1)
sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
sectionTitle.Font = Enum.Font.GothamBold
sectionTitle.TextSize = 16
sectionTitle.BackgroundTransparency = 1

-- Компонент переключателя
local function createToggle(name, yOffset, defaultState, callback)
    local holder = Instance.new("Frame", mainTab)
    holder.Size = UDim2.new(1, -20, 0, 40)
    holder.Position = UDim2.new(0, 10, 0, yOffset)
    holder.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", holder)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Text = name
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.BackgroundTransparency = 1

    local toggle = Instance.new("TextButton", holder)
    toggle.Size = UDim2.new(0.25, 0, 0.7, 0)
    toggle.Position = UDim2.new(0.75, 0, 0.15, 0)
    toggle.Text = defaultState and "ON" or "OFF"
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 12
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)

    local state = defaultState

    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.Text = state and "ON" or "OFF"
        toggle.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        if callback then callback(state) end
    end)

    return toggle
end

-- Функция-переключатели
createToggle("Auto Farm Mastery", 50, false, function(state)
    farmingModules.mastery = state
    if state then
        task.spawn(startMastery)
    end
end)

createToggle("Auto Store Fruits", 95, false, function(state)
    farmingModules.fruits = state
    if state then
        task.spawn(function()
            while farmingModules.fruits do
                storeFruit()
                task.wait(10)
            end
        end)
    end
end)

createToggle("Auto Collect Chests", 140, false, function(state)
    farmingModules.chests = state
    -- TODO: реализовать
end)

createToggle("Auto Collect Bones", 185, false, function(state)
    farmingModules.bones = state
    -- TODO: реализовать
end)
-----------------------------------------------------------------------
-- 🌊 SEA TAB
-----------------------------------------------------------------------
local seaTab = createTab("Sea")

-- Заголовок
local title = Instance.new("TextLabel", seaTab)
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 10)
title.Text = "Teleport Zones & Seas"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1

-- Кнопка телепорта в море
local function createSeaButton(name, seaPos, yOffset)
    local btn = Instance.new("TextButton", seaTab)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, yOffset)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.fromRGB(60, 100, 130)

    btn.MouseButton1Click:Connect(function()
        teleportTo(seaPos)
    end)
end

-- Примерные координаты (замени при необходимости на реальные)
createSeaButton("🌊 Первая Море", Vector3.new(0, 10, 0), 50)
createSeaButton("🌌 Второе Море", Vector3.new(1000, 10, 0), 90)
createSeaButton("🌌 Третье Море", Vector3.new(2000, 10, 0), 130)

-----------------------------------------------------------------------
-- 👾 МЕНЮ МОБОВ (scrollable)
-----------------------------------------------------------------------
local mobGui = createTab("Mobs")

local titleMobs = Instance.new("TextLabel", mobGui)
titleMobs.Size = UDim2.new(1, -20, 0, 30)
titleMobs.Position = UDim2.new(0, 10, 0, 10)
titleMobs.Text = "Список всех мобов"
titleMobs.TextColor3 = Color3.new(1, 1, 1)
titleMobs.Font = Enum.Font.GothamBold
titleMobs.TextSize = 16
titleMobs.TextXAlignment = Enum.TextXAlignment.Left
titleMobs.BackgroundTransparency = 1

local scrollingFrame = Instance.new("ScrollingFrame", mobGui)
scrollingFrame.Position = UDim2.new(0.05, 0, 0, 50)
scrollingFrame.Size = UDim2.new(0.9, 0, 1, -60)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 5, 0)
scrollingFrame.ScrollBarThickness = 8
scrollingFrame.BackgroundColor3 = Color3.fromRGB(30,30,40)
scrollingFrame.BorderSizePixel = 0

local allMobs = {
    -- 🌍 First Sea
    "Bandit", "Monkey", "Gorilla", "Pirate", "Brute",
    "Desert Bandit", "Desert Officer", "Snow Bandit", "Snowman",
    "Chief Petty Officer", "Yeti", "Dark Master", "Sky Bandit",
    "Royal Squad", "Royal Soldier", "Galley Pirate", "Galley Captain",

    -- 🌌 Second Sea
    "Raider", "Mercenary", "Swan Pirate", "Factory Staff",
    "Marine Captain", "Zombie", "Vampire", "Ship Engineer",

    -- 🌠 Third Sea
    "Elite Pirate", "Arctic Warrior", "Living Zombie", "Fishman Raider",
    "Forest Pirate", "Captain Elephant", "Island Empress",
    "Forest Beast", "Sea Soldier", "Water Fighter", "Dragon Crew Archer",
    "Dragon Crew Warrior"
}

-- Создание списка
for i, mobName in ipairs(allMobs) do
    local mobLabel = Instance.new("TextLabel", scrollingFrame)
    mobLabel.Size = UDim2.new(1, -10, 0, 25)
    mobLabel.Position = UDim2.new(0, 5, 0, (i - 1) * 30)
    mobLabel.Text = mobName
    mobLabel.TextColor3 = Color3.new(1, 1, 1)
    mobLabel.Font = Enum.Font.Gotham
    mobLabel.TextSize = 14
    mobLabel.BackgroundTransparency = 1
end
-----------------------------------------------------------------------
-- 📈 STATS TAB (прокачка характеристик)
-----------------------------------------------------------------------
local statsTab = createTab("Stats")

local statNames = { "Melee", "Defense", "Sword", "Gun", "Blox Fruit" }

for i, stat in ipairs(statNames) do
    local btn = Instance.new("TextButton", statsTab)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, 10 + (i-1) * 40)
    btn.Text = "Прокачать " .. stat
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.fromRGB(50, 100, 60)

    btn.MouseButton1Click:Connect(function()
        upgradeStat(stat)
    end)
end

-----------------------------------------------------------------------
-- 🚀 TELEPORT TAB
-----------------------------------------------------------------------
local teleportTab = createTab("Teleport")

local teleportSpots = {
    {name = "Начальная зона", pos = Vector3.new(0, 10, 0)},
    {name = "Sky Island", pos = Vector3.new(500, 200, 100)},
    {name = "Marine Fortress", pos = Vector3.new(-400, 20, -100)},
    {name = "Middle Town", pos = Vector3.new(100, 20, 300)},
    {name = "Jungle", pos = Vector3.new(-200, 20, 400)},
    {name = "Pirate Village", pos = Vector3.new(300, 20, -200)},
}

for i, tp in ipairs(teleportSpots) do
    local btn = Instance.new("TextButton", teleportTab)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, 10 + (i-1) * 40)
    btn.Text = tp.name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BackgroundColor3 = Color3.fromRGB(90, 70, 140)

    btn.MouseButton1Click:Connect(function()
        teleportTo(tp.pos)
    end)
end
-----------------------------------------------------------------------
-- 👁️ VISUAL TAB (FPS Boost, удаление эффектов)
-----------------------------------------------------------------------
local visualTab = createTab("Visual")

local btnFps = Instance.new("TextButton", visualTab)
btnFps.Size = UDim2.new(0.9, 0, 0, 35)
btnFps.Position = UDim2.new(0.05, 0, 0, 10)
btnFps.Text = "FPS Boost (Удалить эффекты)"
btnFps.Font = Enum.Font.GothamBold
btnFps.TextSize = 14
btnFps.TextColor3 = Color3.new(1, 1, 1)
btnFps.BackgroundColor3 = Color3.fromRGB(120, 120, 40)

btnFps.MouseButton1Click:Connect(function()
    applyFpsBoost()
    log("FPS Boost активирован")
end)

-----------------------------------------------------------------------
-- 🍍 ITEMS TAB (фрукты, гача и хранилище)
-----------------------------------------------------------------------
local itemsTab = createTab("Items")

local btnStoreFruit = Instance.new("TextButton", itemsTab)
btnStoreFruit.Size = UDim2.new(0.9, 0, 0, 35)
btnStoreFruit.Position = UDim2.new(0.05, 0, 0, 10)
btnStoreFruit.Text = "📦 Сохранить фрукт"
btnStoreFruit.Font = Enum.Font.GothamBold
btnStoreFruit.TextSize = 14
btnStoreFruit.TextColor3 = Color3.new(1, 1, 1)
btnStoreFruit.BackgroundColor3 = Color3.fromRGB(70, 130, 100)
btnStoreFruit.MouseButton1Click:Connect(storeFruit)

local btnGacha = Instance.new("TextButton", itemsTab)
btnGacha.Size = UDim2.new(0.9, 0, 0, 35)
btnGacha.Position = UDim2.new(0.05, 0, 0, 55)
btnGacha.Text = "🎲 Гача (рандом фрукт)"
btnGacha.Font = Enum.Font.GothamBold
btnGacha.TextSize = 14
btnGacha.TextColor3 = Color3.new(1, 1, 1)
btnGacha.BackgroundColor3 = Color3.fromRGB(100, 80, 150)
btnGacha.MouseButton1Click:Connect(buyGacha)

-- Пример кнопки на покупку конкретного фрукта:
local btnBuyFlame = Instance.new("TextButton", itemsTab)
btnBuyFlame.Size = UDim2.new(0.9, 0, 0, 35)
btnBuyFlame.Position = UDim2.new(0.05, 0, 0, 100)
btnBuyFlame.Text = "🔥 Купить Flame Fruit"
btnBuyFlame.Font = Enum.Font.GothamBold
btnBuyFlame.TextSize = 14
btnBuyFlame.TextColor3 = Color3.new(1, 1, 1)
btnBuyFlame.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
btnBuyFlame.MouseButton1Click:Connect(function()
    buyFruit("Flame-Flame")
end)
-----------------------------------------------------------------------
-- 🌀 RAIDS TAB
-----------------------------------------------------------------------
local raidsTab = createTab("Raids")

local btnRaidFarm = Instance.new("TextButton", raidsTab)
btnRaidFarm.Size = UDim2.new(0.9, 0, 0, 35)
btnRaidFarm.Position = UDim2.new(0.05, 0, 0, 10)
btnRaidFarm.Text = "🔥 Фарм Рейдов (заглушка)"
btnRaidFarm.Font = Enum.Font.GothamBold
btnRaidFarm.TextSize = 14
btnRaidFarm.TextColor3 = Color3.new(1, 1, 1)
btnRaidFarm.BackgroundColor3 = Color3.fromRGB(140, 60, 120)
btnRaidFarm.MouseButton1Click:Connect(function()
    log("Рейды еще не реализованы. Обновление позже.")
end)

-----------------------------------------------------------------------
-- 🎉 EVENTS TAB
-----------------------------------------------------------------------
local eventsTab = createTab("Events")

local btnBones = Instance.new("TextButton", eventsTab)
btnBones.Size = UDim2.new(0.9, 0, 0, 35)
btnBones.Position = UDim2.new(0.05, 0, 0, 10)
btnBones.Text = "💀 Фарм Костей (заглушка)"
btnBones.Font = Enum.Font.GothamBold
btnBones.TextSize = 14
btnBones.TextColor3 = Color3.new(1, 1, 1)
btnBones.BackgroundColor3 = Color3.fromRGB(110, 70, 90)
btnBones.MouseButton1Click:Connect(function()
    log("Фарм костей скоро будет добавлен.")
end)

local btnSeaEvent = Instance.new("TextButton", eventsTab)
btnSeaEvent.Size = UDim2.new(0.9, 0, 0, 35)
btnSeaEvent.Position = UDim2.new(0.05, 0, 0, 55)
btnSeaEvent.Text = "🌊 Sea Event (заглушка)"
btnSeaEvent.Font = Enum.Font.GothamBold
btnSeaEvent.TextSize = 14
btnSeaEvent.TextColor3 = Color3.new(1, 1, 1)
btnSeaEvent.BackgroundColor3 = Color3.fromRGB(90, 60, 120)
btnSeaEvent.MouseButton1Click:Connect(function()
    log("Sea Events еще в разработке.")
end)
-- Создание основного окна с вкладками
function createAdvancedMenu()
    if farmingGui then farmingGui:Destroy() end
    farmingGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    farmingGui.Name = "FarmingHubV2"

    local mainFrame = Instance.new("Frame", farmingGui)
    mainFrame.Size = UDim2.new(0, 600, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Name = "MainFrame"

    local sideBar = Instance.new("Frame", mainFrame)
    sideBar.Size = UDim2.new(0, 120, 1, 0)
    sideBar.Position = UDim2.new(0, 0, 0, 0)
    sideBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)

    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, -120, 1, 0)
    contentFrame.Position = UDim2.new(0, 120, 0, 0)
    contentFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    contentFrame.Name = "Content"

    local tabs = {}
    local function switchTab(tabName)
        for name, frame in pairs(tabs) do
            frame.Visible = (name == tabName)
        end
    end

    function createTab(name)
        local btn = Instance.new("TextButton", sideBar)
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.Position = UDim2.new(0, 0, 0, (#sideBar:GetChildren()-1) * 40)
        btn.Text = name
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = Color3.new(1,1,1)
        btn.TextSize = 14
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        btn.AutoButtonColor = false

        local tab = Instance.new("ScrollingFrame", contentFrame)
        tab.Size = UDim2.new(1, 0, 1, 0)
        tab.CanvasSize = UDim2.new(0, 0, 2, 0)
        tab.ScrollBarThickness = 6
        tab.BackgroundTransparency = 1
        tab.Visible = false
        tab.Name = name
        tab.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tab.ScrollingDirection = Enum.ScrollingDirection.Y

        btn.MouseButton1Click:Connect(function()
            switchTab(name)
        end)

        tabs[name] = tab
        if #sideBar:GetChildren() == 2 then tab.Visible = true end
        return tab
    end

    -- Вызываем генерацию вкладок (это то, что ты видел в прошлых частях)
    -- Например:
    -- local mainTab = createTab("Main")
    -- local statsTab = createTab("Stats")
    -- ... (остальные Tabs)
end

-- Перехват клавиши M
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.M then
        if farmingGui then
            farmingGui.Enabled = not farmingGui.Enabled
        else
            createAdvancedMenu()
        end
    end
end)
function createMobSelectionMenu()
    if mobSelectionGui then mobSelectionGui:Destroy() end

    mobSelectionGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    mobSelectionGui.Name = "MobSelectionGUI"

    local frame = Instance.new("Frame", mobSelectionGui)
    frame.Size = UDim2.new(0, 400, 0, 500)
    frame.Position = UDim2.new(0.5, -200, 0.5, -250)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    title.Text = "📜 Выбор мобов (все моря)"
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18

    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1, -20, 1, -80)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 8
    scroll.BackgroundTransparency = 1
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y

    local UIListLayout = Instance.new("UIListLayout", scroll)
    UIListLayout.Padding = UDim.new(0, 5)

    local mobs = {
        -- 1st Sea
        "Bandit", "Monkey", "Gorilla", "Pirate", "Brute", "Desert Bandit", "Desert Officer",
        "Snow Bandit", "Snowman", "Yeti", "Dark Master", "Sky Bandit", "Sky Warrior",
        "Toga Warrior", "Gladiator", "Military Soldier", "Swan Pirate", "Galley Pirate", "Galley Captain",

        -- 2nd Sea
        "Raider", "Mercenary", "Swan Pirate", "Marine Captain", "Zombie", "Vampire", "Ghost Ship Pirate",
        "Ship Engineer", "Factory Staff", "Magma Admiral", "Warden", "Chief Warden",

        -- 3rd Sea
        "Water Fighter", "Dragon Crew Warrior", "Dragon Crew Archer", "Island Empress Guard",
        "Forest Pirate", "Sea Soldier", "Fishman Raider", "Pirate Millionaire", "Reborn Skeleton"
    }

    local toggled = {}

    for _, name in ipairs(mobs) do
        local line = Instance.new("Frame", scroll)
        line.Size = UDim2.new(1, 0, 0, 30)
        line.BackgroundTransparency = 1

        local label = Instance.new("TextLabel", line)
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Text = name
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.BackgroundTransparency = 1

        local toggle = Instance.new("TextButton", line)
        toggle.Size = UDim2.new(0.25, 0, 1, 0)
        toggle.Position = UDim2.new(0.75, 0, 0, 0)
        toggle.Text = "ВКЛ"
        toggle.TextColor3 = Color3.new(1, 1, 1)
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 12
        toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        toggled[name] = true

        toggle.MouseButton1Click:Connect(function()
            toggled[name] = not toggled[name]
            toggle.Text = toggled[name] and "ВКЛ" or "ВЫКЛ"
            toggle.BackgroundColor3 = toggled[name] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        end)
    end

    local close = Instance.new("TextButton", frame)
    close.Size = UDim2.new(0.9, 0, 0, 35)
    close.Position = UDim2.new(0.05, 0, 1, -40)
    close.Text = "❌ ЗАКРЫТЬ (N)"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.TextColor3 = Color3.new(1,1,1)
    close.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    close.MouseButton1Click:Connect(function()
        mobSelectionGui:Destroy()
    end)
end
