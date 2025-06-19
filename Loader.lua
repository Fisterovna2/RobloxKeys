repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local farmingGui, mobSelectionGui
local farmingModules = {}
local modulesByKey = {}

local noclipExists = false
for _, name in ipairs(PhysicsService:GetCollisionGroups()) do
    if name.name == "NoclipGroup" then
        noclipExists = true
        break
    end
end

if not noclipExists then
    pcall(function()
        PhysicsService:CreateCollisionGroup("NoclipGroup")
    end)
end

pcall(function()
    PhysicsService:CollisionGroupSetCollidable("NoclipGroup", "Default", false)
end)

local function log(msg)
    print("[BF-FARM] " .. msg)
end

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

local function flyTo(pos, yOffset)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return math.huge end
    local root = char.HumanoidRootPart
    local target = pos + Vector3.new(0, yOffset or 15, 0)
    local dir = (target - root.Position).Unit
    root.AssemblyLinearVelocity = dir * 150
    return (target - root.Position).Magnitude
end
local function attackEnemy(enemy)
    local bp = LocalPlayer.Backpack
    local char = LocalPlayer.Character
    local sword, gun
    for _, tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.Name:find("Sword") or tool.Name:find("Melee") then
                sword = tool
            elseif tool.Name:find("Gun") then
                gun = tool
            end
        end
    end
    if sword then
        sword.Parent = char
        for i=1,3 do sword:Activate(); task.wait(0.1) end
    elseif gun then
        gun.Parent = char
        for i=1,3 do gun:Activate(); task.wait(0.1) end
    else
        VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,false)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,false)
    end
end

local function findEnemies()
    local found = {}
    for _, m in ipairs(Workspace:GetDescendants()) do
        if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") and m:FindFirstChild("HumanoidRootPart") then
            local h = m:FindFirstChildOfClass("Humanoid")
            if h.Health > 0 then table.insert(found, m) end
        end
    end
    return found
end

local function getNearestEnemy()
    local nearest, minDist = nil, 1e9
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return nil end
    myPos = myPos.Position
    for _, mob in ipairs(findEnemies()) do
        local dist = (mob.HumanoidRootPart.Position - myPos).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = mob
        end
    end
    return nearest
end
local function startMastery()
    log("Фарм мастерки запущен")
    while farmingModules.mastery do
        task.wait(0.2)
        enableNoclip()
        local enemy = getNearestEnemy()
        if enemy then
            local d = flyTo(enemy.HumanoidRootPart.Position)
            if d < 100 then
                while farmingModules.mastery and enemy do
                    if enemy:FindFirstChildOfClass("Humanoid") and enemy.Humanoid.Health > 0 then
                        attackEnemy(enemy)
                    else
                        break
                    end
                    task.wait(0.2)
                end
            end
        end
    end
    log("Фарм мастерки остановлен")
end

local function enableHaki()
    local args = { [1] = "Buso" }
    ReplicatedStorage.Remotes.Comm:InvokeServer(unpack(args))
    wait(0.5)
    local args2 = { [1] = "Ken" }
    ReplicatedStorage.Remotes.Comm:InvokeServer(unpack(args2))
end

local function autoEquip()
    local backpack = LocalPlayer.Backpack
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:find("Sword") or tool.Name:find("Gun") or tool.Name:find("Melee")) then
            tool.Parent = LocalPlayer.Character
            break
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if farmingModules.mastery then
        log("Респаун: продолжаем фарм")
        autoEquip()
        enableHaki()
    end
end)

local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
end)
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

local function storeFruit()
    local args = {
        [1] = "StoreFruit",
        [2] = "FruitName",
        [3] = LocalPlayer.Name
    }
    ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
end

local function buyGacha()
    local args = { [1] = "Cousin", [2] = "Buy" }
    ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
end

local function buyFruit(name)
    local args = { [1] = "BuyFruit", [2] = name }
    ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
end

local function upgradeStat(stat)
    local args = { [1] = "AddPoint", [2] = stat, [3] = 1 }
    ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
end

local function upgradeKenHaki()
    local args = { [1] = "UpgradeKenTalk" }
    ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
end

local function teleportTo(pos)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0,5,0))
    end
end

local function serverHop()
    local HttpService = game:GetService("HttpService")
    local response = game:HttpGet("https://games.roblox.com/v1/games/2753915549/servers/Public?sortOrder=Asc&limit=100")
    local servers = HttpService:JSONDecode(response)
    for _, v in pairs(servers.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            game:GetService("TeleportService"):TeleportToPlaceInstance(2753915549, v.id)
            break
        end
    end
end
farmingModules = {
    mastery = false,
    fruits = false,
    chests = false,
    bones = false,
}

local function toggleModule(name, func, button)
    farmingModules[name] = not farmingModules[name]
    if button then
        button.Text = farmingModules[name] and "ОТКЛ" or "ВКЛ"
        button.BackgroundColor3 = farmingModules[name] and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(0, 170, 0)
    end
    if farmingModules[name] then
        log("Включен: " .. name)
        task.spawn(func)
    else
        log("Отключен: " .. name)
    end
end

function createMenu()
    if farmingGui then farmingGui:Destroy() end
    farmingGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    farmingGui.Name = "FarmingMenu"

    local frm = Instance.new("Frame", farmingGui)
    frm.Size = UDim2.new(0, 300, 0, 350)
    frm.Position = UDim2.new(0.5, -150, 0.5, -175)
    frm.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frm.Active = true
    frm.Draggable = true

    local title = Instance.new("TextLabel", frm)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    title.Text = "⚙️ Blox Fruits Фарм Меню"
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18

    local features = {
        {"ФАРМ МАСТЕРИ", "mastery", startMastery},
        {"ФРУКТЫ", "fruits", storeFruit},
        {"СУНДУКИ", "chests", function() log("Нужна реализация") end},
        {"КОСТИ", "bones", function() log("Нужна реализация") end},
    }

    for i, feat in ipairs(features) do
        local btn = Instance.new("TextButton", frm)
        btn.Size = UDim2.new(0.9, 0, 0, 35)
        btn.Position = UDim2.new(0.05, 0, 0, 45 + (i-1)*40)
        btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        btn.Text = "ВКЛ"
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.MouseButton1Click:Connect(function()
            toggleModule(feat[2], feat[3], btn)
        end)

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Position = UDim2.new(0, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = feat[1]
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.new(1, 1, 1)
    end
    local mobBtn = Instance.new("TextButton", frm)
    mobBtn.Size = UDim2.new(0.9, 0, 0, 35)
    mobBtn.Position = UDim2.new(0.05, 0, 1, -80)
    mobBtn.Text = "👾 МОБЫ (N)"
    mobBtn.Font = Enum.Font.GothamBold
    mobBtn.TextSize = 14
    mobBtn.TextColor3 = Color3.new(1,1,1)
    mobBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    mobBtn.MouseButton1Click = function()
        if mobSelectionGui then
            mobSelectionGui.Enabled = not mobSelectionGui.Enabled
        else
            createMobSelectionMenu()
        end
    end

    local closeBtn = Instance.new("TextButton", frm)
    closeBtn.Size = UDim2.new(0.9, 0, 0, 35)
    closeBtn.Position = UDim2.new(0.05, 0, 1, -40)
    closeBtn.Text = "❌ ЗАКРЫТЬ"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.MouseButton1Click = function()
        farmingGui:Destroy()
        farmingGui = nil
    end
end

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.M then
        if farmingGui then
            farmingGui.Enabled = not farmingGui.Enabled
        else
            createMenu()
        end
    elseif inp.KeyCode == Enum.KeyCode.N then
        if mobSelectionGui then
            mobSelectionGui.Enabled = not mobSelectionGui.Enabled
        else
            createMobSelectionMenu()
        end
    end
end)

task.spawn(function()
    task.wait(3)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Blox Fruits Farm",
            Text = "Нажми M для меню, N для мобов",
            Icon = "rbxassetid://6726578090",
            Duration = 6
        })
    end)
    log("Фарм-меню загружено")
end)
function createMobSelectionMenu()
    if mobSelectionGui then mobSelectionGui:Destroy() end

    mobSelectionGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    mobSelectionGui.Name = "MobSelection"

    local frm = Instance.new("Frame", mobSelectionGui)
    frm.Size = UDim2.new(0, 350, 0, 400)
    frm.Position = UDim2.new(0.5, -175, 0.5, -200)
    frm.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frm.Active = true
    frm.Draggable = true

    local title = Instance.new("TextLabel", frm)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    title.Text = "⚙️ Выбор мобов (1-3 море)"
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18

    local mobs = {
        -- Первый мир
        "Bandit", "Monkey", "Pirate", "Brute", "Desert Bandit", "Desert Officer", "Snow Bandit", "Snowman",
        "Chief Petty Officer", "Sky Bandit", "Dark Master", "Toga Warrior", "Gladiator",
        -- Второй мир
        "Raid Boss", "Swan Pirate", "Factory Staff", "Marine Captain", "Shanda", "God's Guard",
        -- Третий мир
        "Pirate Millionaire", "Arctic Warrior", "Snow Lurker", "Island Empress", "Forest Pirate",
        "Mythological Pirate", "Sea Soldier", "Water Fighter"
    }

    local toggled = {}

    for i, name in ipairs(mobs) do
        local y = 40 + i * 35
        local line = Instance.new("Frame", frm)
        line.Size = UDim2.new(0.9, 0, 0, 30)
        line.Position = UDim2.new(0.05, 0, 0, y)
        line.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", line)
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Text = name
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.BackgroundTransparency = 1

        local btn = Instance.new("TextButton", line)
        btn.Size = UDim2.new(0.25, 0, 1, 0)
        btn.Position = UDim2.new(0.75, 0, 0, 0)
        btn.Text = "ВКЛ"
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        toggled[name] = true

        btn.MouseButton1Click:Connect(function()
            toggled[name] = not toggled[name]
            btn.Text = toggled[name] and "ВКЛ" or "ВЫКЛ"
            btn.BackgroundColor3 = toggled[name] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        end)
    end

    local closeBtn = Instance.new("TextButton", frm)
    closeBtn.Size = UDim2.new(0.9, 0, 0, 35)
    closeBtn.Position = UDim2.new(0.05, 0, 1, -45)
    closeBtn.Text = "❌ ЗАКРЫТЬ (N)"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.MouseButton1Click = function()
        mobSelectionGui:Destroy()
    end
end
