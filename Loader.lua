-- **Loader.lua** — Автономный фарм-скрипт без ключей

repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

-- ✅ Глобальные состояния
local farmingGui, mobSelectionGui
local farmingModules = {
    mastery = { enabled = false, thread = nil, toggle = nil, light = nil },
    fruits = { enabled = false, thread = nil, toggle = nil, light = nil },
    chests = { enabled = false, thread = nil, toggle = nil, light = nil },
    bones = { enabled = false, thread = nil, toggle = nil, light = nil }
}

local mobSelection = {
    world1 = { ["Bandit"]=true, ["Monkey"]=true, ["Pirate"]=true },
    world2 = { ["Desert Bandit"]=true, ["Desert Officer"]=true, ["Snow Bandit"]=true, ["Snowman"]=true },
    world3 = { ["Galley Pirate"]=true, ["Galley Captain"]=true, ["Forest Pirate"]=true }
}

local colorThemes = {
    mastery = { on=Color3.fromRGB(0,255,170), off=Color3.fromRGB(100,100,100) },
    fruits  = { on=Color3.fromRGB(255,125,0),  off=Color3.fromRGB(100,100,100) },
    chests  = { on=Color3.fromRGB(255,255,0),  off=Color3.fromRGB(100,100,100) },
    bones   = { on=Color3.fromRGB(180,0,255),  off=Color3.fromRGB(100,100,100) }
}

local function log(msg) print("[FARM] "..msg) end

-- 🛠 Убедимся, что персонаж загружен
repeat task.wait(1) until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- 🧼 Настройка noclip (фикс)
if not PhysicsService:HasCollisionGroup("NoclipGroup") then
    PhysicsService:CreateCollisionGroup("NoclipGroup")
    PhysicsService:CollisionGroupSetCollidable("NoclipGroup","Default",false)
end

-- 🔄 Утилиты
local function pressMouse()
    VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,false)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,false)
end

local function animateToggle(module, key)
    local clr = module.enabled and colorThemes[key].on or colorThemes[key].off
    if module.light then
        TweenService:Create(module.light, TweenInfo.new(0.3), { BackgroundColor3 = clr }):Play()
        module.toggle.Text = module.enabled and "ВКЛ" or "ВЫКЛ"
    end
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

local function enlargeHitbox()
    local char = LocalPlayer.Character
    local torso = char and char:FindFirstChild("HumanoidRootPart")
    if not torso then return end
    if not char:FindFirstChild("BuddhaHitbox") then
        local hb = Instance.new("Part", char)
        hb.Name = "BuddhaHitbox"
        hb.Size = Vector3.new(25,25,25)
        hb.Transparency = 1; hb.CanCollide = false
        local weld = Instance.new("WeldConstraint", hb)
        weld.Part0 = torso; weld.Part1 = hb
        log("Создан хитбокс")
    end
end

local function attackEnemy(enemy)
    if not enemy or not enemy:FindFirstChildOfClass("Humanoid") then return end
    enlargeHitbox()
    local bp = LocalPlayer.Backpack
    local char = LocalPlayer.Character
    local sword, gun
    for _, tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.Name:find("Sword") or tool.Name:find("Melee") then sword=tool break
            elseif tool.Name:find("Gun") or tool.Name:find("Weapon") then gun=tool end
        end
    end
    if sword then
        sword.Parent = char
        for i=1,3 do sword:Activate(); task.wait(0.1) end
    elseif gun then
        gun.Parent = char
        for i=1,3 do gun:Activate(); task.wait(0.1) end
    else
        pressMouse()
    end
end

-- 🔍 Поиск объектов
local function findObjects(kind)
    local res = {}
    local paths = {
        enemies = {Workspace.Enemies,Workspace.Live,Workspace.NPCs,Workspace.Mobs,Workspace["_ENEMIES"],Workspace},
        fruits  = {Workspace.Fruits,Workspace.SpawnedFruits,Workspace.FruitSpawns,Workspace["_FRUITS"],Workspace},
        chests  = {Workspace.Chests,Workspace.Treasures,Workspace.Loot,Workspace["_CHESTS"],Workspace.Islands,Workspace},
        bones   = {Workspace.Bones,Workspace.Items,Workspace.Loot,Workspace["_BONES"],Workspace.Islands,Workspace}
    }[kind]
    local criteria = {
        enemies = function(o)
            local h=o:FindFirstChildOfClass("Humanoid")
            return o:IsA("Model") and h and h.Health>0 and (o:FindFirstChild("HumanoidRootPart") or o.PrimaryPart)
        end,
        fruits = function(o) return (o:IsA("Model") or o:IsA("MeshPart")) and o.Name:match("[Ff]ruit") and o:FindFirstChild("Handle") end,
        chests = function(o) return o:IsA("Model") and (o.Name:match("[Cc]hest") or o.Name:match("Treasure")) and (o:FindFirstChild("Chest") or o:FindFirstChild("Loot")) end,
        bones  = function(o) return (o:IsA("MeshPart") or o:IsA("Part")) and o.Name:match("[Bb]one") and o:FindFirstChild("ClickDetector") end
    }[kind]

    for _, parent in ipairs(paths) do
        if parent then
            for _, o in ipairs(parent:GetDescendants()) do
                if pcall(criteria, o) and criteria(o) then table.insert(res, o) end
            end
        end
    end
    if kind=="enemies" and #res==0 then
        for _, o in ipairs(Workspace:GetChildren()) do
            if o:IsA("Model") and o:FindFirstChildOfClass("Humanoid") and o.Humanoid.Health>0 then
                table.insert(res, o)
            end
        end
    end
    return res
end

local function getCurrentWorld()
    local lvl = LocalPlayer.Data.Level.Value
    if lvl<700 then return "world1" elseif lvl<1500 then return "world2" else return "world3" end
end

local function findBestEnemy()
    local en = findObjects("enemies")
    local best, score = nil, -1
    local cp = LocalPlayer.Character.HumanoidRootPart.Position
    local w = getCurrentWorld()
    for _, e in ipairs(en) do
        if mobSelection[w][e.Name] then
            local hir = e:FindFirstChildOfClass("Humanoid").Health or 0
            local rp = e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart
            if rp then
                local dist = (cp - rp.Position).Magnitude
                local pr = hir*0.1 + 100/math.max(1,dist)
                if pr>score then best, score = e, pr end
            end
        end
    end
    return best
end

-- 🧩 Функции фарма
local function startMastery()
    log("Старт фарм мастери")
    while farmingModules.mastery.enabled do
        task.wait(0.1); enableNoclip()
        if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health>0) then
            log("Жду возрождения"); task.wait(2)
        else
            local e = findBestEnemy()
            if e then
                local rp = e:FindFirstChild("HumanoidRootPart") or e.PrimaryPart
                local d = flyTo(rp.Position,15)
                if d<100 then while e and e:FindFirstChildOfClass("Humanoid") and e.Humanoid.Health>0 and farmingModules.mastery.enabled do
                    attackEnemy(e); task.wait(0.1)
                end end
            end
        end
    end
    log("Стоп фарм мастери")
end

-- аналогичные для fruits, chests, bones:
local function startFruits()
    log("Старт фарм фруктов")
    while farmingModules.fruits.enabled do
        task.wait(0.1); enableNoclip()
        if not(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health>0)then task.wait(2)
        else
            local fruits=findObjects("fruits"); local closest; local mind=1e9; local rp=LocalPlayer.Character.HumanoidRootPart.Position
            for _,f in ipairs(fruits) do local h=f:FindFirstChild("Handle") if h then local d=(rp-h.Position).Magnitude;if d<mind then mind=d;closest=h end end
            if closest then flyTo(closest.Position,5)
            else
                local gaga; for _,e in ipairs(findObjects("enemies")) do if e.Name:find("Gacha") then gaga=e break end end
                if gaga then flyTo(gaga.HumanoidRootPart.Position,5) else task.wait(1) end
            end
        end
    end
    log("Стоп фарм фруктов")
end

local function startChests()
    log("Старт фарм сундуков")
    while farmingModules.chests.enabled do
        task.wait(0.2); enableNoclip()
        if not(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health>0)then task.wait(2)
        else
            local chs=findObjects("chests"); local b; local mind=1e9; local rp=LocalPlayer.Character.HumanoidRootPart.Position
            for _,c in ipairs(chs) do local p=c:FindFirstChild("Chest") or c:FindFirstChild("Loot") if p then local d=(rp-p.Position).Magnitude;if d<mind then mind=d;b=p end end
            if b then local d=flyTo(b.Position,5); if d<10 then firetouchinterest(LocalPlayer.Character.HumanoidRootPart,b,0); firetouchinterest(LocalPlayer.Character.HumanoidRootPart,b,1); log("Сундук собран"); task.wait(0.5) end
            else task.wait(1)
            end
        end
    end
    log("Стоп фарм сундуков")
end

local function startBones()
    log("Старт фарм костей")
    while farmingModules.bones.enabled do
        task.wait(0.1); enableNoclip()
        if not(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health>0)then task.wait(2)
        else
            local bs=findObjects("bones"); local b=head
            if #bs>0 then local mind=1e9; local rp=LocalPlayer.Character.HumanoidRootPart.Position
                for _,c in ipairs(bs) do local d=(rp-c.Position).Magnitude if d<mind then mind=d; b=c end end
                local d=flyTo(b.Position,5); if d<10 then firetouchinterest(LocalPlayer.Character.HumanoidRootPart,b,0); firetouchinterest(LocalPlayer.Character.HumanoidRootPart,b,1); log("Кость собрана"); task.wait(0.5) end
            else task.wait(1) end
        end
    end
    log("Стоп фарм костей")
end

-- 🎛 UI
local function createMenu()
    if farmingGui then farmingGui:Destroy() end
    farmingGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    farmingGui.Name = "FarmingMenu"

    local frm = Instance.new("Frame", farmingGui)
    frm.Size = UDim2.new(0,380,0,500); frm.Position=UDim2.new(0.5,-190,0.5,-250)
    frm.BackgroundColor3=Color3.fromRGB(30,30,40); frm.Active=true; frm.Draggable=true

    local title = Instance.new("TextLabel", frm)
    title.Size=UDim2.new(1,0,0,50); title.BackgroundColor3=Color3.fromRGB(25,25,35)
    title.Text="BLOCK FRUITS FARM MENU"; title.TextColor3=Color3.fromRGB(0,255,255); title.Font=Enum.Font.GothamBold; title.TextSize=22

    local features={
        {name="ФАРМ МАСТЕРИ",key="mastery",func=startMastery},
        {name="ФАРМ ФРУКТОВ", key="fruits", func=startFruits},
        {name="ФАРМ СУНДУКОВ", key="chests", func=startChests},
        {name="ФАРМ КОСТЕЙ",   key="bones",  func=startBones}
    }

    for i,feat in ipairs(features) do
        local y=60 + (i-1)*85
        local cnt = Instance.new("Frame", frm)
        cnt.Position=UDim2.new(0.05,0,0,y); cnt.Size=UDim2.new(0.9,0,0,70)
        cnt.BackgroundColor3=Color3.fromRGB(40,40,50)
        local ic = Instance.new("TextLabel", cnt)
        ic.Text = feat.name:sub(1,1)=="Ф" and "🔫" or feat.name:find("ФРУК") and "🍎" or feat.name:find("СУНДУК") and "📦" or "💀"
        ic.Size=UDim2.new(0,50,0,50); ic.Position=UDim2.new(0.05,0,0.15,0); ic.TextSize=30; ic.BackgroundTransparency=1
        local lbl = Instance.new("TextLabel", cnt)
        lbl.Text=feat.name; lbl.Size=UDim2.new(0.5,0,1,0); lbl.Position=UDim2.new(0.2,0,0,0); lbl.Font=Enum.Font.GothamBold; lbl.TextSize=16; lbl.TextColor3=Color3.new(1,1,1)
        local tf = Instance.new("Frame", cnt)
        tf.Size=UDim2.new(0,80,0,30); tf.Position=UDim2.new(0.7,0,0.3,0); tf.BackgroundColor3=Color3.fromRGB(60,60,70)
        local light = Instance.new("Frame", tf)
        light.Size=UDim2.new(0,12,0,12); light.Position=UDim2.new(0.1,0,0.3,0); light.BackgroundColor3=colorThemes[feat.key].off; light.ZIndex=2
        farmingModules[feat.key].light = light
        local st = Instance.new("TextLabel", tf)
        st.Size=UDim2.new(0.6,0,1,0); st.Position=UDim2
        .new(0.3,0,0,0); st.Text="ВЫКЛ"; st.Font=Enum.Font.GothamBold; st.TextSize=14; st.TextColor3=Color3.new(0.8,0.8,0.8)
        farmingModules[feat.key].toggle = st
        local btn = Instance.new("TextButton", tf)
        btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
        btn.MouseButton1Click:Connect(function()
            for k,v in pairs(farmingModules) do
                if k~=feat.key and v.enabled then
                    v.enabled = false
                    animateToggle(v,k)
                    if v.thread then task.cancel(v.thread); v.thread=nil end
                end
            end
            local mod = farmingModules[feat.key]
            mod.enabled = not mod.enabled
            animateToggle(mod,feat.key)
            if mod.enabled then mod.thread = task.spawn(feat.func) end
        end)
    end

    local mobBtn = Instance.new("TextButton", frm)
    mobBtn.Size=UDim2.new(0.9,0,0,40); mobBtn.Position=UDim2.new(0.05,0,0,440)
    mobBtn.Text="ВЫБОР МОБОВ (N)"; mobBtn.Font=Enum.Font.GothamBold; mobBtn.TextSize=16; mobBtn.TextColor3=Color3.new(1,1,1); mobBtn.BackgroundColor3=Color3.fromRGB(70,70,180)
    mobBtn.MouseButton1Click = function() if mobSelectionGui then mobSelectionGui:Destroy() mobSelectionGui=nil else createMobSelectionMenu() end end

    local closeBtn = Instance.new("TextButton", frm)
    closeBtn.Size=UDim2.new(0.9,0,0,40); closeBtn.Position=UDim2.new(0.05,0,0,490)
    closeBtn.Text="ЗАКРЫТЬ МЕНЮ"; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=16; closeBtn.TextColor3=Color3.new(1,1,1); closeBtn.BackgroundColor3=Color3.fromRGB(180,50,50)
    closeBtn.MouseButton1Click = function() farmingGui:Destroy() farmingGui=nil end
end

function createMobSelectionMenu()
    if mobSelectionGui then mobSelectionGui:Destroy() mobSelectionGui=nil end
    mobSelectionGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    mobSelectionGui.Name="MobSelection"

    local frm = Instance.new("Frame", mobSelectionGui)
    frm.Size=UDim2.new(0,380,0,500); frm.Position=UDim2.new(0.5,-190,0.5,-250)
    frm.BackgroundColor3=Color3.fromRGB(30,30,40); frm.Active=true; frm.Draggable=true

    local title = Instance.new("TextLabel", frm)
    title.Size=UDim2.new(1,0,0,50); title.BackgroundColor3=Color3.fromRGB(25,25,35)
    title.Text="ВЫБОР МОБОВ"; title.TextColor3=Color3.fromRGB(0,255,255)
    title.Font=Enum.Font.GothamBold; title.TextSize=22

    local offset = 60
    for _,w in ipairs({{"МИР 1","world1"},{"МИР 2","world2"},{"МИР 3","world3"}}) do
        local lbl = Instance.new("TextLabel", frm)
        lbl.Size=UDim2.new(0.9,0,0,30); lbl.Position=UDim2.new(0.05,0,0,offset)
        lbl.Text=w[1]; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=16; lbl.TextColor3=Color3.fromRGB(0,200,255)
        lbl.BackgroundTransparency=1
        offset = offset + 35
        for mobName, state in pairs(mobSelection[w[2]]) do
            local line = Instance.new("Frame", frm)
            line.Size=UDim2.new(0.9,0,0,30); line.Position=UDim2.new(0.05,0,0,offset)
            offset = offset + 35
            local ml = Instance.new("TextLabel", line)
            ml.Size=UDim2.new(0.7,0,1,0); ml.Position=UDim2.new(0,0,0,0)
            ml.Text=mobName; ml.Font=Enum.Font.Gotham; ml.TextSize=14; ml.TextColor3=Color3.new(1,1,1); ml.BackgroundTransparency=1
            local tb = Instance.new("TextButton", line)
            tb.Size=UDim2.new(0.25,0,1,0); tb.Position=UDim2.new(0.75,0,0,0)
            tb.Text=state and "ВКЛ" or "ВЫКЛ"; tb.Font=Enum.Font.GothamBold; tb.TextSize=12; tb.TextColor3=Color3.new(1,1,1)
            tb.BackgroundColor3=state and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
            tb.MouseButton1Click:Connect(function()
                mobSelection[w[2]][mobName] = not mobSelection[w[2]][mobName]
                tb.Text = mobSelection[w[2]][mobName] and "ВКЛ" or "ВЫКЛ"
                tb.BackgroundColor3 = mobSelection[w[2]][mobName] and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
            end)
        end
    end

    local closeBtn = Instance.new("TextButton", frm)
    closeBtn.Size=UDim2.new(0.9,0,0,40); closeBtn.Position=UDim2.new(0.05,0,0,offset+10)
    closeBtn.Text="ЗАКРЫТЬ (N)"; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=16; closeBtn.TextColor3=Color3.new(1,1,1)
    closeBtn.BackgroundColor3=Color3.fromRGB(180,50,50)
    closeBtn.MouseButton1Click = function() mobSelectionGui:Destroy() mobSelectionGui=nil end
end

UserInputService.InputBegan:Connect(function(inp)
    if inp.KeyCode==Enum.KeyCode.M then
        if farmingGui then farmingGui.Enabled = not farmingGui.Enabled
        else createMenu()
        end
    elseif inp.KeyCode==Enum.KeyCode.N then
        if mobSelectionGui then mobSelectionGui.Enabled = not mobSelectionGui.Enabled
        else createMobSelectionMenu()
        end
    end
end)

-- 🔔 Запуск аннотации + готовим меню
task.spawn(function()
    task.wait(3)
    game.StarterGui:SetCore("SendNotification", {
        Title = "ФАРМ МЕНЮ АКТИВИРОВАН",
        Text = "M: меню фарма, N: выбор мобов",
        Icon = "rbxassetid://6726578090",
        Duration = 8
    })
    log("Меню готово — нажми M")
end)
