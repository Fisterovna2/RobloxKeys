repeat task.wait() until game:IsLoaded()

-- Глобальные переменные
local farmingGui = nil
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

-- Инициализация PhysicsService
PhysicsService:CreateCollisionGroup("NoclipGroup")
PhysicsService:CollisionGroupSetCollidable("NoclipGroup", "Default", false)

-- Состояния фарма
local farmingModules = {
    mastery = { enabled = false },
    fruits = { enabled = false },
    chests = { enabled = false },
    bones = { enabled = false }
}

-- Настройки выбора мобов
local mobSelection = {
    world1 = { ["Bandit"] = true, ["Monkey"] = true },
    world2 = { ["Desert Bandit"] = true, ["Snowman"] = true },
    world3 = { ["Galley Pirate"] = true, ["Forest Pirate"] = true }
}

-- Система Noclip :cite[4]
local function toggleNoclip(state)
    local character = LocalPlayer.Character
    if not character then return end
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, state and "NoclipGroup" or "Default")
        end
    end
end

-- Система полета :cite[2]:cite[7]
local flySpeed = 50
local bodyVelocity, bodyGyro

local function startFlying()
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Создаем элементы управления полетом
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.P = 10000
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.D = 500
    
    bodyVelocity.Parent = hrp
    bodyGyro.Parent = hrp
    toggleNoclip(true)
end

local function stopFlying()
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    toggleNoclip(false)
end

local function flyTo(target, height)
    if not bodyVelocity or not bodyGyro then startFlying() end
    
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local camera = workspace.CurrentCamera
    local offset = Vector3.new(0, height or 15, 0)
    local targetPos = target.Position + offset
    
    -- Расчет направления
    local direction = (targetPos - hrp.Position).Unit
    bodyVelocity.Velocity = direction * flySpeed
    bodyGyro.CFrame = CFrame.new(hrp.Position, targetPos)
end

-- Интеллектуальный выбор цели :cite[6]
local function findOptimalTarget()
    local bestTarget
    local highestPriority = -math.huge
    
    for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
        if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
            local enemyName = enemy.Name
            local world = enemyName:match("Galley") and 3 or enemyName:match("Desert") and 2 or 1
            
            -- Приоритет: здоровье + уровень + выбранность
            local priority = enemy.Humanoid.MaxHealth * 0.7 + 
                            (enemy:FindFirstChild("Level") and enemy.Level.Value or 0) * 0.3
            
            if mobSelection["world"..world][enemyName] and priority > highestPriority then
                highestPriority = priority
                bestTarget = enemy
            end
        end
    end
    
    return bestTarget
end

-- Авто-атака :cite[7]
local function autoAttack(target)
    if not target then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Используем лучшее доступное оружие
    local tool
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") and child:FindFirstChild("Handle") then
            tool = child
            break
        end
    end
    
    if tool then
        for i = 1, 3 do
            tool:Activate()
            task.wait(0.1)
        end
    else
        mouse1press()
        task.wait(0.2)
        mouse1release()
    end
end

-- Функция фарма мастери
local function masteryFarm()
    while farmingModules.mastery.enabled and task.wait(0.1) do
        local target = findOptimalTarget()
        if target then
            flyTo(target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart, 15)
            if (target.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 50 then
                autoAttack(target)
            end
        end
    end
    stopFlying()
end

-- Единый обработчик GUI
local function toggleMenu()
    if farmingGui and farmingGui.Parent then
        farmingGui:Destroy()
        return
    end
    
    -- Создание GUI (ваш существующий код)
    -- ... 

    -- Добавляем переключатель noclip
    local noclipToggle = Instance.new("TextButton")
    noclipToggle.Text = "NOCLIP: ВЫКЛ"
    noclipToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    -- ... обработчик клика для noclip ...

    farmingGui.Parent = game:GetService("CoreGui")
end

-- Обработчик клавиши M
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        toggleMenu()
    end
end)

-- Автозапуск фарма
local function autoFarm()
    while task.wait(1) do
        if farmingModules.mastery.enabled then
            masteryFarm()
        -- ... другие режимы фарма ...
        end
    end
end
task.spawn(autoFarm)

-- Уведомление
game.StarterGui:SetCore("SendNotification", {
    Title = "AUTO FARM v3.0",
    Text = "Нажмите M для открытия меню\nNoclip автоматически включен при фарме",
    Duration = 10
})
