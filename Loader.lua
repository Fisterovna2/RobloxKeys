-- [1] Ожидание полной загрузки
repeat task.wait() until game:IsLoaded()

-- [2] Сервисы
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

-- [3] Переменные
local LocalPlayer = Players.LocalPlayer
local farmingModules = {
    mastery = false,
    fruits = false,
    chests = false,
    bones = false,
    raids = false,
}
local toggledMobs = {}
local mobSelectionGui
local BloxHubGui

-- [4] Утилита логов
local function log(msg)
    print("[BLOX-HUB] " .. tostring(msg))
end

-- [5] FPS Boost
local function applyFpsBoost()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Texture") or obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
        end
    end
end

-- [6] Телепорт к позиции
local function teleportTo(pos)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    end
end

-- [7] Прокачка статы
local function upgradeStat(stat)
    local args = {
        [1] = "AddPoint",
        [2] = stat,
        [3] = 1
    }
    ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
end

-- [8] Сохранение фрукта
local function storeFruit()
    local args = {
        [1] = "StoreFruit",
        [2] = "FruitName", -- Заменить на актуальный фрукт
        [3] = LocalPlayer.Name
    }
    ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
end
-- [9] Фарм мастерки
local function startMastery()
	log("Фарм мастерки начат")
	while farmingModules.mastery do
		task.wait(0.3)
		for _, mob in pairs(Workspace:GetDescendants()) do
			if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChildOfClass("Humanoid") then
				if toggledMobs[mob.Name] and mob:FindFirstChildOfClass("Humanoid").Health > 0 then
					teleportTo(mob.HumanoidRootPart.Position)
					task.wait(0.5)
				end
			end
		end
	end
	log("Фарм мастерки завершён")
end

-- [10] Фарм рейдов
local function startRaids()
	log("Авто-рейды включены")
	while farmingModules.raids do
		task.wait(3)

		local raidTable = Workspace:FindFirstChild("RaidSummon")
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

		if raidTable and hrp then
			teleportTo(raidTable.Position)
			task.wait(1)

			local raidType = "Flame" -- Позже заменить на выбор через GUI
			log("Выбран рейд: " .. raidType)

			local args = { "RaidsNpc", "Select", raidType }
			ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
			task.wait(0.5)

			local startArgs = { "RaidsNpc", "Start" }
			ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(startArgs))

			log("Рейд начат. Ожидаем...")

			repeat
				task.wait(5)
			until not farmingModules.raids or not Workspace:FindFirstChild("Enemies")

			log("Рейд завершён или остановлен. Пауза...")
			task.wait(10)
		else
			log("❌ Стол рейдов не найден")
			task.wait(5)
		end
	end
	log("Авто-рейды остановлены")
end

-- [11] Очистка старого GUI
pcall(function()
	if CoreGui:FindFirstChild("BloxHubGui") then
		CoreGui.BloxHubGui:Destroy()
	end
end)

-- [12] Создание главного GUI
BloxHubGui = Instance.new("ScreenGui", CoreGui)
BloxHubGui.Name = "BloxHubGui"
BloxHubGui.ResetOnSpawn = false
-- [13] Основная рамка GUI
local mainFrame = Instance.new("Frame", BloxHubGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 700, 0, 460)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -230)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = true

-- [14] Навигационная панель слева
local navFrame = Instance.new("Frame", mainFrame)
navFrame.Name = "NavPanel"
navFrame.Size = UDim2.new(0, 150, 1, 0)
navFrame.Position = UDim2.new(0, 0, 0, 0)
navFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
navFrame.BorderSizePixel = 0

local navLabel = Instance.new("TextLabel", navFrame)
navLabel.Size = UDim2.new(1, 0, 0, 50)
navLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
navLabel.Text = "⚙️ BloxFarm Menu"
navLabel.Font = Enum.Font.GothamBold
navLabel.TextSize = 16
navLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
navLabel.BorderSizePixel = 0

-- [15] Контейнер вкладок справа
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -150, 1, 0)
tabContainer.Position = UDim2.new(0, 150, 0, 0)
tabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
tabContainer.BorderSizePixel = 0

-- [16] Список вкладок
local tabs = {
    {Name = "Main", Text = "Главное"},
    {Name = "Sea", Text = "Моря"},
    {Name = "Stats", Text = "Статы"},
    {Name = "Teleport", Text = "Телепорт"},
    {Name = "Visual", Text = "FPS Boost"}
}

local createdTabs = {}
local tabButtons = {}

-- [17] Функция скрытия всех вкладок
local function hideAllTabs()
	for _, child in ipairs(tabContainer:GetChildren()) do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end
end

-- [18] Создание вкладки
local function createTab(name)
	if createdTabs[name] then return createdTabs[name] end
	local frame = Instance.new("Frame", tabContainer)
	frame.Name = name .. "Tab"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	frame.BorderSizePixel = 0
	frame.Visible = false
	createdTabs[name] = frame
	return frame
end
-- [19] Создание кнопок вкладок
for i, tab in ipairs(tabs) do
	local btn = Instance.new("TextButton", navFrame)
	btn.Size = UDim2.new(1, 0, 0, 35)
	btn.Position = UDim2.new(0, 0, 0, 50 + (i - 1) * 36)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	btn.Text = tab.Text
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true

	btn.MouseButton1Click:Connect(function()
		hideAllTabs()
		local tabFrame = createTab(tab.Name)
		tabFrame.Visible = true
	end)

	tabButtons[tab.Name] = btn
end

-- [20] Активируем первую вкладку
task.wait(0.2)
if tabButtons["Main"] then
	tabButtons["Main"]:MouseButton1Click()
end

-- [21] Функция переключения состояния
local function toggleModule(name, callback)
	farmingModules[name] = not farmingModules[name]
	if farmingModules[name] and callback then
		task.spawn(callback)
	end
end

-- [22] Главная вкладка с функциями
local mainTab = createTab("Main")
mainTab.Visible = true

local features = {
    {"🗡️ Мастерка", "mastery", startMastery},
    {"🍇 Фрукты", "fruits", storeFruit},
    {"💰 Сундуки", "chests", function() log("Фарм сундуков не реализован") end},
    {"💀 Кости", "bones", function() log("Фарм костей не реализован") end},
    {"🔥 Рейды", "raids", startRaids}
}

for i, feat in ipairs(features) do
	local btn = Instance.new("TextButton", mainTab)
	btn.Size = UDim2.new(0, 240, 0, 35)
	btn.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 45)
	btn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	btn.Text = feat[1] .. " [ВЫКЛ]"
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1, 1, 1)

	btn.MouseButton1Click:Connect(function()
		toggleModule(feat[2], feat[3])
		local isActive = farmingModules[feat[2]]
		btn.Text = feat[1] .. (isActive and " [ВКЛ]" or " [ВЫКЛ]")
		btn.BackgroundColor3 = isActive and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
	end)
end
-- [23] Вкладка Sea — телепорт в моря
local seaTab = createTab("Sea")

local seaLocations = {
    {"🌊 1-е Море", Vector3.new(1037, 122, 1421)},
    {"🌋 2-е Море", Vector3.new(5784, 150, 202)},
    {"❄️ 3-е Море", Vector3.new(-12000, 200, 5100)},
}

for i, sea in ipairs(seaLocations) do
	local btn = Instance.new("TextButton", seaTab)
	btn.Size = UDim2.new(0, 240, 0, 35)
	btn.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 45)
	btn.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
	btn.Text = sea[1]
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.MouseButton1Click:Connect(function()
		teleportTo(sea[2])
	end)
end

-- [24] Вкладка Stats — прокачка характеристик
local statsTab = createTab("Stats")
local stats = {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"}

for i, stat in ipairs(stats) do
	local btn = Instance.new("TextButton", statsTab)
	btn.Size = UDim2.new(0, 200, 0, 35)
	btn.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 45)
	btn.BackgroundColor3 = Color3.fromRGB(90, 70, 120)
	btn.Text = "🔼 Прокачать " .. stat
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.MouseButton1Click:Connect(function()
		upgradeStat(stat)
	end)
end

-- [25] Вкладка Teleport — популярные точки
local teleportTab = createTab("Teleport")
local teleportPoints = {
    {"🏝️ Спавн", Vector3.new(206, 18, 100)},
    {"🏯 Город", Vector3.new(-425, 70, 212)},
    {"⚔️ Арена", Vector3.new(1450, 80, 750)},
}

for i, point in ipairs(teleportPoints) do
	local btn = Instance.new("TextButton", teleportTab)
	btn.Size = UDim2.new(0, 240, 0, 35)
	btn.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 45)
	btn.BackgroundColor3 = Color3.fromRGB(80, 60, 100)
	btn.Text = point[1]
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.MouseButton1Click:Connect(function()
		teleportTo(point[2])
	end)
end
-- [26] Вкладка Visual — FPS Boost
local visualTab = createTab("Visual")

local fpsBtn = Instance.new("TextButton", visualTab)
fpsBtn.Size = UDim2.new(0, 200, 0, 35)
fpsBtn.Position = UDim2.new(0, 20, 0, 30)
fpsBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 80)
fpsBtn.Text = "⚙️ Включить FPS Boost"
fpsBtn.Font = Enum.Font.GothamBold
fpsBtn.TextSize = 14
fpsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

fpsBtn.MouseButton1Click:Connect(function()
	applyFpsBoost()
end)

-- [27] Меню выбора мобов (по клавише N)
function createMobSelectionMenu()
	if mobSelectionGui then mobSelectionGui:Destroy() end

	mobSelectionGui = Instance.new("ScreenGui", CoreGui)
	mobSelectionGui.Name = "MobSelection"

	local frm = Instance.new("Frame", mobSelectionGui)
	frm.Size = UDim2.new(0, 400, 0, 500)
	frm.Position = UDim2.new(0.5, -200, 0.5, -250)
	frm.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	frm.Active = true
	frm.Draggable = true

	local title = Instance.new("TextLabel", frm)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	title.Text = "👾 Выбор мобов (все моря)"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	-- Scroll
	local scroll = Instance.new("ScrollingFrame", frm)
	scroll.Size = UDim2.new(1, -20, 1, -80)
	scroll.Position = UDim2.new(0, 10, 0, 50)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 1500)
	scroll.ScrollBarThickness = 8
	scroll.BackgroundTransparency = 1

	local UIList = Instance.new("UIListLayout", scroll)
	UIList.SortOrder = Enum.SortOrder.LayoutOrder
	UIList.Padding = UDim.new(0, 5)

	local mobList = {
		-- 1 МОРЕ
		"Bandit", "Monkey", "Pirate", "Brute", "Desert Bandit", "Desert Officer", "Snow Bandit",
		"Yeti", "Dark Master", "Sky Bandit", "Sky Warrior", "Thunder God", "Galley Pirate", "Galley Captain",
		-- 2 МОРЕ
		"Raider", "Mercenary", "Swan Pirate", "Factory Staff", "Marine Captain", "Chief Petty Officer",
		"God's Guard", "Shanda", "Royal Squad", "Royal Soldier", "Zombie", "Vampire", "Ghost Ship Crew",
		-- 3 МОРЕ
		"Arctic Warrior", "Island Empress", "Reborn Skeleton", "Water Fighter", "Fishman Raider",
		"Fishman Captain", "Sea Soldier", "Mythological Pirate", "Dragon Crew Warrior", "Elite Pirate"
	}

	for _, mobName in ipairs(mobList) do
		local row = Instance.new("Frame", scroll)
		row.Size = UDim2.new(1, -10, 0, 30)
		row.BackgroundTransparency = 1

		local lbl = Instance.new("TextLabel", row)
		lbl.Size = UDim2.new(0.7, 0, 1, 0)
		lbl.Text = mobName
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 14
		lbl.BackgroundTransparency = 1
		local btn = Instance.new("TextButton", row)
		btn.Size = UDim2.new(0.3, 0, 1, 0)
		btn.Position = UDim2.new(0.7, 0, 0, 0)
		btn.Text = "ВКЛ"
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		toggledMobs[mobName] = true

		btn.MouseButton1Click:Connect(function()
			toggledMobs[mobName] = not toggledMobs[mobName]
			btn.Text = toggledMobs[mobName] and "ВКЛ" or "ВЫКЛ"
			btn.BackgroundColor3 = toggledMobs[mobName] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
		end)
	end

	local closeBtn = Instance.new("TextButton", frm)
	closeBtn.Size = UDim2.new(0.9, 0, 0, 35)
	closeBtn.Position = UDim2.new(0.05, 0, 1, -40)
	closeBtn.Text = "❌ ЗАКРЫТЬ (N)"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.MouseButton1Click = function()
		mobSelectionGui:Destroy()
	end
end
-- [28] Назначение клавиш M и N для открытия меню
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.M then
		mainFrame.Visible = not mainFrame.Visible
	elseif input.KeyCode == Enum.KeyCode.N then
		if mobSelectionGui and mobSelectionGui.Parent then
			mobSelectionGui.Enabled = not mobSelectionGui.Enabled
		else
			createMobSelectionMenu()
		end
	end
end)

-- [29] Уведомление о запуске GUI
task.spawn(function()
	task.wait(2)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = "⚙️ Blox Fruits GUI",
			Text = "Нажмите M — Меню, N — Мобы",
			Duration = 6,
			Icon = "rbxassetid://6726578090"
		})
	end)
	log("GUI успешно запущен.")
end)
-- [30] Реализация авто-рейдов
local function startRaids()
	log("Авто-рейды активированы")
	while farmingModules.raids do
		task.wait(3)

		local raidTable = Workspace:FindFirstChild("RaidSummon")
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

		if raidTable and hrp then
			teleportTo(raidTable.Position)
			task.wait(1)

			local raidType = "Flame" -- тип можно сделать настраиваемым позже
			log("Выбор рейда: " .. raidType)

			local args = {
				[1] = "RaidsNpc",
				[2] = "Select",
				[3] = raidType
			}
			ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
			task.wait(0.5)

			local startArgs = {
				[1] = "RaidsNpc",
				[2] = "Start"
			}
			ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(startArgs))

			log("Рейд запущен. Ожидаем окончания...")

			repeat task.wait(5)
			until not farmingModules.raids or not Workspace:FindFirstChild("Enemies")

			log("Рейд завершён или остановлен. Пауза...")
			task.wait(10)
		else
			log("⚠️ Стол рейдов не найден или персонаж не готов")
			task.wait(5)
		end
	end
	log("Авто-рейды отключены")
end
