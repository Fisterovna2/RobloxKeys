-- ПОЛНЫЙ СКРИПТ С МЕНЮШКОЙ И ОБНОВЛЁННЫМ ФАРМОМ
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
local Workspace = game:GetService("Workspace")

repeat task.wait(1) until LocalPlayer.Character

-- Инициализация PhysicsService для Noclip
if not pcall(function() PhysicsService:CreateCollisionGroup("NoclipGroup") end) then end
PhysicsService:CollisionGroupSetCollidable("NoclipGroup", "Default", false)

local farmingModules = {
    mastery = { enabled = false, thread = nil, toggle = nil, light = nil },
    fruits = { enabled = false, thread = nil, toggle = nil, light = nil },
    chests = { enabled = false, thread = nil, toggle = nil, light = nil },
    bones = { enabled = false, thread = nil, toggle = nil, light = nil }
}

local colorThemes = {
    mastery = { on = Color3.fromRGB(0, 255, 170), off = Color3.fromRGB(100, 100, 100) },
    fruits = { on = Color3.fromRGB(255, 125, 0), off = Color3.fromRGB(100, 100, 100) },
    chests = { on = Color3.fromRGB(255, 255, 0), off = Color3.fromRGB(100, 100, 100) },
    bones = { on = Color3.fromRGB(180, 0, 255), off = Color3.fromRGB(100, 100, 100) }
}

-- Noclip функция
local function enableNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, "NoclipGroup")
            part.CanCollide = false
        end
    end
end

-- Функция полёта
local function flyTo(pos, height)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    enableNoclip()
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, height or 15, 0))
end

-- Увеличить хитбокс врага
local function stretchHitbox(enemy)
    local root = enemy:FindFirstChild("HumanoidRootPart")
    if root then
        root.Size = Vector3.new(20, 20, 20)
        root.CanCollide = false
    end
end

-- Мгновенная атака
local function instantAttack(enemy)
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = enemy and enemy:FindFirstChild("HumanoidRootPart")
    if root and targetRoot then
        firetouchinterest(root, targetRoot, 0)
        firetouchinterest(root, targetRoot, 1)
    end
end

-- Поиск объектов
local function findObjects()
    local enemies, chests, fruits, bones = {}, {}, {}, {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            table.insert(enemies, obj)
        elseif obj:IsA("Tool") and obj.Parent == Workspace then
            table.insert(fruits, obj)
        elseif obj:IsA("ClickDetector") then
            table.insert(chests, obj.Parent)
        elseif obj.Name:lower():find("bone") and obj:IsA("MeshPart") then
            table.insert(bones, obj)
        end
    end
    return enemies, chests, fruits, bones
end

local function findGacha()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("gacha") then
            return obj
        end
    end
end

local function startMasteryFarm()
    while farmingModules.mastery.enabled and task.wait(0.1) do
        local char = LocalPlayer.Character
        if not char or char:FindFirstChild("Humanoid").Health <= 0 then continue end
        local enemies = select(1, findObjects())
        local best, dist = nil, math.huge
        for _, enemy in ipairs(enemies) do
            local hrp = enemy:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < dist then best, dist = enemy, d end
            end
        end
        if best then
            flyTo(best.HumanoidRootPart.Position, 15)
            stretchHitbox(best)
            instantAttack(best)
        end
    end
end

local function startFruitFarm()
    while farmingModules.fruits.enabled and task.wait(0.5) do
        local fruits = select(3, findObjects())
        if #fruits > 0 then
            flyTo(fruits[1].Handle.Position, 5)
        else
            local gacha = findGacha()
            if gacha and gacha:FindFirstChild("HumanoidRootPart") then
                flyTo(gacha.HumanoidRootPart.Position, 5)
            end
        end
    end
end

local function startChestFarm()
    while farmingModules.chests.enabled and task.wait(0.5) do
        local chests = select(2, findObjects())
        for _, chest in ipairs(chests) do
            local part = chest:IsA("BasePart") and chest or chest:FindFirstChildWhichIsA("BasePart")
            if part then
                flyTo(part.Position, 5)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 0)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 1)
            end
        end
    end
end

local function startBonesFarm()
    while farmingModules.bones.enabled and task.wait(0.5) do
        local bones = select(4, findObjects())
        for _, bone in ipairs(bones) do
            flyTo(bone.Position, 5)
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, bone, 0)
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, bone, 1)
        end
    end
end

-- Создание GUI как в оригинале
-- createFarmingMenu() и createMobSelectionMenu() остаются как у тебя
-- Просто в обработчике кнопок:

-- Пример включения функции:
-- farmingModules.mastery.thread = task.spawn(startMasteryFarm)
-- farmingModules.fruits.thread = task.spawn(startFruitFarm)
-- и т.д.

-- Обработчики клавиш
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        if farmingGui and farmingGui.Enabled then
            farmingGui.Enabled = false
        else
            if createFarmingMenu then createFarmingMenu() end
        end
    elseif input.KeyCode == Enum.KeyCode.N then
        if mobSelectionGui and mobSelectionGui.Enabled then
            mobSelectionGui.Enabled = false
        else
            if createMobSelectionMenu then createMobSelectionMenu() end
        end
    end
end)

-- Уведомление
pcall(function()
    task.wait(3)
    game.StarterGui:SetCore("SendNotification", {
        Title = "ФАРМ МЕНЮ АКТИВИРОВАН",
        Text = "M: Меню фарма\nN: Выбор мобов",
        Icon = "rbxassetid://6726578090",
        Duration = 10
    })
end)

print("Фарм-скрипт успешно загружен!")
