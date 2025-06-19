-- [1] Ожидание загрузки игры
repeat task.wait() until game:IsLoaded()

-- [2] Сервисы
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")

-- [3] Локальные переменные
local LocalPlayer = Players.LocalPlayer
local Modules = {}
local BloxHubGui
local mobSelectionGui
local toggledMobs = {}
local farmingModules = {
	mastery = false,
	fruits = false,
	chests = false,
	bones = false,
	raids = false
}

-- [4] Логирование
local function log(msg)
	print("[BLOX-HUB] " .. tostring(msg))
end

-- [5] FPS Boost
local function applyFpsBoost()
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	for _, v in pairs(Workspace:GetDescendants()) do
		if v:IsA("Texture") or v:IsA("ParticleEmitter") or v:IsA("Trail") then
			v:Destroy()
		elseif v:IsA("BasePart") then
			v.Material = Enum.Material.Plastic
			v.Reflectance = 0
		end
	end
end

-- [6] Телепорт
local function teleportTo(pos)
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
	end
end

-- [7] Авто прокачка статов
local function upgradeStat(stat)
	local args = { [1] = "AddPoint", [2] = stat, [3] = 1 }
	ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
end

-- [8] Store Fruit
local function storeFruit()
	local args = {
		[1] = "StoreFruit",
		[2] = "FruitName",
		[3] = LocalPlayer.Name
	}
	ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
end

-- [9] Start Mastery
local function startMastery()
	log("Фарм мастерки запущен")
	while farmingModules.mastery do
		task.wait(0.2)
		local enemies = Workspace:GetDescendants()
		for _, m in ipairs(enemies) do
			if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and m:FindFirstChild("HumanoidRootPart") then
				if toggledMobs[m.Name] and m:FindFirstChildOfClass("Humanoid").Health > 0 then
					teleportTo(m.HumanoidRootPart.Position)
					task.wait(0.5)
				end
			end
		end
	end
	log("Фарм мастерки остановлен")
end
-- [10] Удаление старого GUI
pcall(function()
	if CoreGui:FindFirstChild("BloxHubGui") then
		CoreGui.BloxHubGui:Destroy()
	end
end)

-- [11] Создание GUI
BloxHubGui = Instance.new("ScreenGui", CoreGui)
BloxHubGui.Name = "BloxHubGui"
BloxHubGui.ResetOnSpawn = false

-- [12] Основной фрейм
local mainFrame = Instance.new("Frame", BloxHubGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 700, 0, 460)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -230)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

-- [13] Навигационная панель
local navFrame = Instance.new("Frame", mainFrame)
navFrame.Name = "NavPanel"
navFrame.Size = UDim2.new(0, 150, 1, 0)
navFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)

local navLabel = Instance.new("TextLabel", navFrame)
navLabel.Size = UDim2.new(1, 0, 0, 50)
navLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
navLabel.Text = "🔧 BloxFarm GUI"
navLabel.Font = Enum.Font.GothamBold
navLabel.TextSize = 16
navLabel.TextColor3 = Color3.fromRGB(0, 255, 255)

-- [14] Вкладки
local tabs = {
	{ Name = "Main", Text = "Главное" },
	{ Name = "Sea", Text = "Моря" },
	{ Name = "Stats", Text = "Статы" },
	{ Name = "Teleport", Text = "Телепорт" },
	{ Name = "Visual", Text = "FPS Boost" },
}

local tabButtons = {}
local createdTabs = {}
local selectedTab

-- [15] Контейнер вкладок
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Name = "TabContainer"
tabContainer.Position = UDim2.new(0, 150, 0, 0)
tabContainer.Size = UDim2.new(1, -150, 1, 0)
tabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 50)

-- [16] Скрытие всех вкладок
local function hideAllTabs()
	for _, tab in pairs(tabContainer:GetChildren()) do
		if tab:IsA("Frame") then
			tab.Visible = false
		end
	end
end

-- [17] Создание вкладки
local function createTab(name)
	if createdTabs[name] then return createdTabs[name] end
	local tab = Instance.new("Frame", tabContainer)
	tab.Name = name .. "Tab"
	tab.Size = UDim2.new(1, 0, 1, 0)
	tab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	tab.Visible = false
	createdTabs[name] = tab
	return tab
end

-- [18] Кнопки навигации
for i, tab in ipairs(tabs) do
	local btn = Instance.new("TextButton", navFrame)
	btn.Size = UDim2.new(1, 0, 0, 35)
	btn.Position = UDim2.new(0, 0, 0, 50 + (i - 1) * 36)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	btn.Text = tab.Text
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BorderSizePixel = 0
	btn.MouseButton1Click:Connect(function()
		hideAllTabs()
		local target = createTab(tab.Name)
		target.Visible = true
		selectedTab = target
	end)
	tabButtons[tab.Name] = btn
end

-- [19] Сделать первую вкладку активной
task.wait(0.2)
tabButtons["Main"]:MouseButton1Click()
-- [20] Вкладка Main — переключатели функций
local mainTab = createTab("Main")
mainTab.Visible = true

local toggleData = {
	{Label = "🗡️ Мастерка", Key = "mastery"},
	{Label = "🍇 Фрукты", Key = "fruits"},
	{Label = "💰 Сундуки", Key = "chests"},
	{Label = "💀 Кости", Key = "bones"},
	{Label = "🔥 Рейды", Key = "raids"},
}

local toggleButtons = {}

for i, item in ipairs(toggleData) do
	local btn = Instance.new("TextButton", mainTab)
	btn.Size = UDim2.new(0, 200, 0, 35)
	btn.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 45)
	btn.BackgroundColor3 = Color3.fromRGB(170, 0, 0) -- OFF
	btn.Text = item.Label .. " [ВЫКЛ]"
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)

	toggleButtons[item.Key] = btn

	btn.MouseButton1Click:Connect(function()
		local state = not farmingModules[item.Key]
		farmingModules[item.Key] = state
		btn.Text = item.Label .. (state and " [ВКЛ]" or " [ВЫКЛ]")
		btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)

		if state then
			task.spawn(function()
				if item.Key == "mastery" then startMastery() end
				if item.Key == "fruits" then storeFruit() end
				if item.Key == "raids" then startRaids() end
				-- остальные функции пока не реализованы
			end)
		end
	end)
end
-- [21] Вкладка Sea — телепорт между морями
local seaTab = createTab("Sea")

local seaButtons = {
	{"🌊 Перейти в 1 Море", Vector3.new(1037, 122, 1421)},
	{"🌋 Перейти в 2 Море", Vector3.new(5784, 150, 202)},
	{"❄️ Перейти в 3 Море", Vector3.new(-12000, 200, 5100)},
}

for i, info in ipairs(seaButtons) do
	local btn = Instance.new("TextButton", seaTab)
	btn.Size = UDim2.new(0, 240, 0, 35)
	btn.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 45)
	btn.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
	btn.Text = info[1]
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.MouseButton1Click:Connect(function()
		teleportTo(info[2])
	end)
end

-- [22] Вкладка Stats — прокачка характеристик
local statsTab = createTab("Stats")
local stats = {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"}
for i, name in ipairs(stats) do
	local btn = Instance.new("TextButton", statsTab)
	btn.Size = UDim2.new(0, 200, 0, 35)
	btn.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 45)
	btn.BackgroundColor3 = Color3.fromRGB(90, 70, 120)
	btn.Text = "🔼 Прокачать " .. name
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.MouseButton1Click:Connect(function()
		upgradeStat(name)
	end)
end

-- [23] Вкладка Teleport — популярные точки
local teleportTab = createTab("Teleport")

local locations = {
	{"🏝️ Спавн", Vector3.new(206, 18, 100)},
	{"🏯 Город", Vector3.new(-425, 70, 212)},
	{"⚔️ Арена", Vector3.new(1450, 80, 750)},
}

for i, info in ipairs(locations) do
	local btn = Instance.new("TextButton", teleportTab)
	btn.Size = UDim2.new(0, 240, 0, 35)
	btn.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 45)
	btn.BackgroundColor3 = Color3.fromRGB(80, 60, 100)
	btn.Text = info[1]
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.MouseButton1Click:Connect(function()
		teleportTo(info[2])
	end)
end

-- [24] Вкладка Visual — FPS Boost
local visualTab = createTab("Visual")
local btn = Instance.new("TextButton", visualTab)
btn.Size = UDim2.new(0, 200, 0, 35)
btn.Position = UDim2.new(0, 20, 0, 30)
btn.BackgroundColor3 = Color3.fromRGB(100, 60, 80)
btn.Text = "⚙️ Включить FPS Boost"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.MouseButton1Click:Connect(function()
	applyFpsBoost()
end)
-- [25] Вкладка выбора мобов (по клавише N)
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

	-- Прокручиваемый список
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

	local toggledMobs = {}

	for _, mobName in ipairs(mobList) do
		local row = Instance.new("Frame", scroll)
		row.Size = UDim2.new(1, -10, 0, 30)
		row.BackgroundTransparency = 1

		local lbl = Instance.new("TextLabel", row)
		lbl.Size = UDim2.new(0.7, 0, 1, 0)
		lbl.Text = mobName
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 14
		lbl.BackgroundTransparency = 1

		local btn = Instance.new("TextButton", row)
		btn.Size = UDim2.new(0.3, 0, 1, 0)
		btn.Position = UDim2.new(0.7, 0, 0, 0)
		btn.Text = "ВКЛ"
		btn.TextColor3 = Color3.new(1,1,1)
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
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.MouseButton1Click = function()
		mobSelectionGui:Destroy()
	end
end

-- [26] Назначение клавиш M и N
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

-- [27] Уведомление о запуске
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
