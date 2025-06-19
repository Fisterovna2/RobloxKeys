-- [1] Ожидание полной загрузки игры
repeat task.wait() until game:IsLoaded()

-- [2] Сервисы
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- [3] Локальные переменные
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Modules = {}
local MainGui

-- [4] Утилита логирования
local function log(msg)
    print("[BLOX-HUB] " .. tostring(msg))
end

-- [5] Сброс GUI при перезапуске
pcall(function()
    if CoreGui:FindFirstChild("BloxHubGui") then
        CoreGui.BloxHubGui:Destroy()
    end
end)

-- [6] Создание главного GUI-контейнера
MainGui = Instance.new("ScreenGui", CoreGui)
MainGui.Name = "BloxHubGui"
MainGui.ResetOnSpawn = false

-- [7] Главный UI-Frame
local mainFrame = Instance.new("Frame", MainGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 700, 0, 460)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -230)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = true
mainFrame.Active = true
mainFrame.Draggable = true
-- [8] Левая панель навигации
local navFrame = Instance.new("Frame", mainFrame)
navFrame.Name = "NavPanel"
navFrame.Size = UDim2.new(0, 150, 1, 0)
navFrame.Position = UDim2.new(0, 0, 0, 0)
navFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
navFrame.BorderSizePixel = 0

-- [9] Контейнер для заголовков
local navLabel = Instance.new("TextLabel", navFrame)
navLabel.Size = UDim2.new(1, 0, 0, 50)
navLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
navLabel.Text = "🔧 Setting Farm"
navLabel.Font = Enum.Font.GothamBold
navLabel.TextSize = 16
navLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
navLabel.BorderSizePixel = 0

-- [10] Вкладки навигации
local tabs = {
    {Name = "Main", Text = "Main"},
    {Name = "Sea", Text = "Sea"},
    {Name = "Items", Text = "Items"},
    {Name = "Status", Text = "Status"},
    {Name = "Stats", Text = "Stats"},
    {Name = "Player", Text = "Player"},
    {Name = "Teleport", Text = "Teleport"},
    {Name = "Visual", Text = "Visual"},
}

local tabButtons = {}
local selectedTab = nil

-- [11] Создание кнопок навигации
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
    tabButtons[tab.Name] = btn
end

-- [12] Контейнер для вкладок справа
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -150, 1, 0)
tabContainer.Position = UDim2.new(0, 150, 0, 0)
tabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
tabContainer.BorderSizePixel = 0
-- [13] Функция скрытия всех вкладок
local function hideAllTabs()
	for _, obj in ipairs(tabContainer:GetChildren()) do
		if obj:IsA("Frame") then
			obj.Visible = false
		end
	end
end

-- [14] Создание вкладок
local createdTabs = {}

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

-- [15] Подключение логики к кнопкам вкладок
for name, button in pairs(tabButtons) do
	button.MouseButton1Click:Connect(function()
		hideAllTabs()
		local tab = createTab(name)
		tab.Visible = true
	end)
end

-- [16] Вкладка Main с переключателями функций
local mainTab = createTab("Main")
mainTab.Visible = true

local toggleData = {
	{Label = "🗡️ Мастерка", Key = "mastery"},
	{Label = "🍇 Фрукты", Key = "fruits"},
	{Label = "💰 Сундуки", Key = "chests"},
	{Label = "💀 Кости", Key = "bones"},
}

local toggleButtons = {}

for i, item in ipairs(toggleData) do
	local btn = Instance.new("TextButton", mainTab)
	btn.Size = UDim2.new(0, 200, 0, 35)
	btn.Position = UDim2.new(0, 20, 0, 20 + (i - 1) * 45)
	btn.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
	btn.Text = item.Label .. " [OFF]"
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)

	toggleButtons[item.Key] = btn

	btn.MouseButton1Click:Connect(function()
		local state = not farmingModules[item.Key]
		farmingModules[item.Key] = state
		btn.Text = item.Label .. (state and " [ON]" or " [OFF]")
		btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
		if state then
			task.spawn(function()
				if item.Key == "mastery" then startMastery() end
				if item.Key == "fruits" then storeFruit() end
				-- другие функции можно подключить здесь
			end)
		end
	end)
end
-- [17] Вкладка SEA — телепорт по морям
local seaTab = createTab("Sea")

local seaButtons = {
	{"🌊 Переместиться в 1 Море", Vector3.new(1037, 122, 1421)},
	{"🌋 Переместиться в 2 Море", Vector3.new(5784, 150, 202)},
	{"❄️ Переместиться в 3 Море", Vector3.new(-12000, 200, 5100)},
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

-- [18] Вкладка Stats — прокачка статов
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

-- [19] Вкладка Teleport — дополнительные точки
local teleportTab = createTab("Teleport")

local locations = {
	{"🏝️ Spawn", Vector3.new(206, 18, 100)},
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

-- [20] Вкладка Visual — FPS буст
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

	mobSelectionGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
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

	-- Scrollable список
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
-- [22] Кнопки M/N — открытие меню
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.M then
		if farmingGui and farmingGui.Parent then
			farmingGui.Enabled = not farmingGui.Enabled
		else
			createMenu()
		end
	elseif input.KeyCode == Enum.KeyCode.N then
		if mobSelectionGui and mobSelectionGui.Parent then
			mobSelectionGui.Enabled = not mobSelectionGui.Enabled
		else
			createMobSelectionMenu()
		end
	end
end)

-- [23] Уведомление при загрузке
task.spawn(function()
	task.wait(3)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = "📦 Blox Fruits АвтоФарм",
			Text = "Нажмите M — Меню | N — Мобы",
			Icon = "rbxassetid://6726578090",
			Duration = 6
		})
	end)
	log("Фарм-меню загружено.")
end)
-- Авто Рейды (Доработанная реализация с выбором и ожиданием)
local function startRaids()
	log("Авто-рейды активированы")
	while farmingModules.raids do
		task.wait(3)

		local raidTable = Workspace:FindFirstChild("RaidSummon")
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

		if raidTable and hrp then
			-- Телепорт к столу рейдов
			teleportTo(raidTable.Position)
			task.wait(1)

			-- Подбор типа рейда (по умолчанию Flame)
			local raidType = "Flame"  -- Можно будет выбрать через GUI позже
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

			repeat
				task.wait(5)
			until not farmingModules.raids or not Workspace:FindFirstChild("Enemies")

			log("Рейд завершён или остановлен. Пауза перед новым циклом...")
			task.wait(10)
		else
			log("⚠️ Стол рейдов не найден или персонаж не готов")
			task.wait(5)
		end
	end
	log("Авто-рейды отключены")
end
