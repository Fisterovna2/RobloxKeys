-- Loader.lua — полный скрипт для Xeno через loadstring(game:HttpGet(...))()

repeat task.wait(1) until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

-- Ожидание персонажа
repeat task.wait(1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- Настройка Noclip
if not pcall(function() PhysicsService:CreateCollisionGroup("NoclipGroup") end) then end
PhysicsService:CollisionGroupSetCollidable("NoclipGroup", "Default", false)

local farmingModules = {
    mastery = false,
    fruits = false,
    chests = false,
    bones = false
}

-- Подсказка: меню запускается кнопками M и N
local function sendNotification()
    StarterGui:SetCore("SendNotification", {
        Title = "Фарм-скрипт активирован",
        Text = "M — меню фарма | N — выбор мобов",
        Duration = 5
    })
end

task.defer(sendNotification)

-- Функция Noclip + подлет
local function enableNoclip()
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                PhysicsService:SetPartCollisionGroup(part, "NoclipGroup")
                part.CanCollide = false
            end
        end
    end
end

local function flyTo(pos, height)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        enableNoclip()
        char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, height or 15, 0))
    end
end

-- Хитбокс и атака
local function stretchHitbox(enemy)
    local root = enemy:FindFirstChild("HumanoidRootPart")
    if root then
        root.Size = Vector3.new(20, 20, 20)
        root.CanCollide = false
    end
end

local function instantAttack(enemy)
    local me = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local target = enemy and enemy:FindFirstChild("HumanoidRootPart")
    if me and target then
        firetouchinterest(me, target, 0)
        firetouchinterest(me, target, 1)
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
        elseif obj:IsA("ClickDetector") and obj.Parent:IsA("Model") then
            table.insert(chests, obj.Parent)
        elseif obj:IsA("MeshPart") and obj.Name:lower():find("bone") then
            table.insert(bones, obj)
        end
    end
    return enemies, chests, fruits, bones
end

-- Поиск Gacha, если нет фруктов
local function findGacha()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("gacha") then
            return obj
        end
    end
end

-- Запуск фарма
local function farmLoop(type)
    while farmingModules[type] do
        local enemies, chests, fruits, bones = findObjects()
        local char = LocalPlayer.Character
        if not char or char:FindFirstChild("Humanoid").Health <= 0 then break end

        if type == "mastery" then
            local best, dist = nil, math.huge
            for _, e in ipairs(enemies) do
                local hrp = e:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < dist then best, dist = e, d end
                end
            end
            if best then
                flyTo(best.HumanoidRootPart.Position, 15)
                stretchHitbox(best)
                instantAttack(best)
            end
        elseif type == "fruits" then
            if #fruits > 0 then
                flyTo(fruits[1].Handle.Position, 5)
            else
                local g = findGacha()
                if g and g:FindFirstChild("HumanoidRootPart") then
                    flyTo(g.HumanoidRootPart.Position, 5)
                end
            end
        elseif type == "chests" then
            for _, c in ipairs(chests) do
                local part = c:IsA("BasePart") and c or c:FindFirstChildWhichIsA("BasePart")
                if part then
                    flyTo(part.Position, 5)
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 0)
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 1)
                end
            end
        elseif type == "bones" then
            for _, b in ipairs(bones) do
                flyTo(b.Position, 5)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, b, 0)
                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, b, 1)
            end
        end

        task.wait(0.5)
    end
end

--Создание простого GUI
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
local frame = Instance.new("Frame", ScreenGui)
frame.Size = UDim2.new(0,200,0,200)
frame.Position = UDim2.new(0.5,-100,0.5,-100)

local titles = {"mastery","fruits","chests","bones"}
for i,type in ipairs(titles) do
    local btn = Instance.new("TextButton", frame)
    btn.Text = type:gsub("^%l", string.upper)
    btn.Size = UDim2.new(1, -10, 0, 40); btn.Position = UDim2.new(0,5, 0, (i-1)*45+5)
    btn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function()
        farmingModules[type] = not farmingModules[type]
        btn.BackgroundColor3 = farmingModules[type] and Color3.fromRGB(0,255,0) or Color3.fromRGB(100,100,100)
        if farmingModules[type] then
            task.spawn(function() farmLoop(type) end)
        end
    end)
end

-- Меню показывается/скрывается по M, выбор мобов пока просто экран (N)
ScreenGui.Enabled = false
UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.M then ScreenGui.Enabled = not ScreenGui.Enabled
    elseif i.KeyCode == Enum.KeyCode.N then
        StarterGui:SetCore("SendNotification", {
            Title="Mob Menu", Text="Здесь можно добавить выбор мобов", Duration=3
        })
    end
end)

print("Фарм-скрипт загружен!")
