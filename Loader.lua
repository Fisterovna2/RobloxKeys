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
-- [6] Удаление старого GUI
pcall(function()
	if CoreGui:FindFirstChild("BloxHubGui") then
		CoreGui.BloxHubGui:Destroy()
	end
end)

-- [7] Создание главного GUI
local BloxHubGui = Instance.new("ScreenGui", CoreGui)
BloxHubGui.Name = "BloxHubGui"
BloxHubGui.ResetOnSpawn = false

-- [8] Главный UI-фрейм
local mainFrame = Instance.new("Frame", BloxHubGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 720, 0, 480)
mainFrame.Position = UDim2.new(0.5, -360, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

-- [9] Левая панель (навигация)
local navFrame = Instance.new("Frame", mainFrame)
navFrame.Name = "NavPanel"
navFrame.Size = UDim2.new(0, 150, 1, 0)
navFrame.Position = UDim2.new(0, 0, 0, 0)
navFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)

local navLabel = Instance.new("TextLabel", navFrame)
navLabel.Size = UDim2.new(1, 0, 0, 50)
navLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
navLabel.Text = "🔧 BloxFarm GUI"
navLabel.Font = Enum.Font.GothamBold
navLabel.TextSize = 16
navLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
navLabel.BorderSizePixel = 0

-- [10] Таблицы с вкладками
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
-- [11] Контейнер вкладок
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Name = "TabContainer"
tabContainer.Position = UDim2.new(0, 150, 0, 0)
tabContainer.Size = UDim2.new(1, -150, 1, 0)
tabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
tabContainer.BorderSizePixel = 0

-- [12] Скрытие всех вкладок
local function hideAllTabs()
	for _, tab in pairs(tabContainer:GetChildren()) do
		if tab:IsA("Frame") then
			tab.Visible = false
		end
	end
end

-- [13] Создание вкладки
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

-- [14] Кнопки вкладок
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

-- [15] По умолчанию активируем первую вкладку
task.delay(0.3, function()
	if tabButtons["Main"] then
		tabButtons["Main"]:MouseButton1Click()
	end
end)
-- [16] Вкладка Main — визуальные переключатели функций
local mainTab = createTab("Main")
mainTab.Visible = true

local toggleData = {
	{Label = "🗡️ Мастерка", Key = "mastery"},
	{Label = "🍇 Фрукты", Key = "fruits"},
	{Label = "💰 Сундуки", Key = "chests"},
	{Label = "💀 Кости", Key = "bones"},
	{Label = "🔥 Рейды", Key = "raids"},
	{Label = "⚙️ Агент", Key = "agent"} -- Новая функция: агент
}

local toggleButtons = {}

local function toggleModule(moduleKey, startFunc)
	local state = not farmingModules[moduleKey]
	farmingModules[moduleKey] = state

	local btn = toggleButtons[moduleKey]
	if btn then
		btn.Text = (state and "✅ " or "❌ ") .. btn.OriginalLabel
		btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
	end

	if state and startFunc then
		task.spawn(startFunc)
	end
end

for i, item in ipairs(toggleData) do
	local btn = Instance.new("TextButton", mainTab)
	btn.Size = UDim2.new(0, 210, 0, 35)
	btn.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 45)
	btn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	btn.Text = "❌ " .. item.Label
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true

	btn.OriginalLabel = item.Label
	toggleButtons[item.Key] = btn

	btn.MouseButton1Click:Connect(function()
		if item.Key == "agent" then
			toggleModule("agent", startAgentLogic)
		else
			toggleModule(item.Key)
		end
	end)
end
-- [17] Вкладка Sea — телепорт между морями
local seaTab = createTab("Sea")

local seaButtons = {
	{"🌊 Перейти в 1 Море", Vector3.new(1037, 122, 1421)},
	{"🌋 Перейти в 2 Море", Vector3.new(5784, 150, 202)},
	{"❄️ Перейти в 3 Море", Vector3.new(-12000, 200, 5100)},
}

for i, info in ipairs(seaButtons) do
	local btn = Instance.new("TextButton", seaTab)
	btn.Size = UDim2.new(0, 220, 0, 35)
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

-- [18] Вкладка Stats — прокачка характеристик
local statsTab = createTab("Stats")
local statList = {"Melee", "Defense", "Sword", "Gun", "Blox Fruit"}

for i, name in ipairs(statList) do
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

-- [19] Вкладка Teleport — избранные точки
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

-- [20] Вкладка Visual — FPS Boost
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
-- [21] Вкладка выбора мобов (по клавише N)
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

-- [22] Кнопки M и N — открытие меню
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
-- [23] Умный Агент (AI) для принятия решений
local function SmartAgent()
	log("🤖 Умный агент запущен.")

	while true do
		task.wait(1)

		-- Если активен фарм мастерки — ищем ближайшего включенного моба
		if farmingModules.mastery then
			local closestMob, shortestDist = nil, math.huge
			for _, mob in ipairs(Workspace:GetDescendants()) do
				if mob:IsA("Model") and mob:FindFirstChildOfClass("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
					if toggledMobs[mob.Name] and mob:FindFirstChildOfClass("Humanoid").Health > 0 then
						local dist = (LocalPlayer.Character.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
						if dist < shortestDist then
							shortestDist = dist
							closestMob = mob
						end
					end
				end
			end

			if closestMob then
				-- Парим над мобом + расширение хитбокса
				local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = closestMob.HumanoidRootPart.CFrame + Vector3.new(0, 15, 0)
					pcall(function()
						hrp.Size = Vector3.new(30, 30, 30)
						hrp.Transparency = 0.5
					end)
				end

				-- Удар без задержки (эмуляция удара)
				local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
				if tool and tool:FindFirstChild("RemoteFunction") then
					tool.RemoteFunction:InvokeServer("Hit", closestMob.HumanoidRootPart.Position)
				end
			end
		end

		-- В дальнейшем сюда можно подключить аналитику других модулей
	end
end

-- [24] Авто-запуск AI агента
task.spawn(function()
	SmartAgent()
end)

-- [25] Уведомление о запуске
task.spawn(function()
	task.wait(2)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = "⚙️ Blox Fruits GUI",
			Text = "Нажмите M — Меню, N — Мобы | Агент активен",
			Duration = 6,
			Icon = "rbxassetid://6726578090"
		})
	end)
	log("GUI и SmartAgent успешно запущены.")
end)
-- [26] Завершение GUI и завершение инициализации
log("📦 Инициализация GUI завершена.")

-- [27] Возможное исправление для GUI клавиш M/N (если они не срабатывают)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.M then
		if mainFrame and mainFrame.Parent then
			mainFrame.Visible = not mainFrame.Visible
		end
	elseif input.KeyCode == Enum.KeyCode.N then
		if mobSelectionGui and mobSelectionGui.Parent then
			mobSelectionGui.Enabled = not mobSelectionGui.Enabled
		else
			createMobSelectionMenu()
		end
	end
end)

-- [28] Безопасность от двойного запуска
if _G.BloxHubLoaded then
	warn("BloxHub уже был запущен.")
	return
end
_G.BloxHubLoaded = true

log("✅ Скрипт полностью загружен и готов к использованию.")
