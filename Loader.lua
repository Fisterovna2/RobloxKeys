repeat task.wait(1) until game:IsLoaded() and game:GetService("CoreGui")

-- Глобальные переменные
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

-- Ожидаем появления персонажа
repeat task.wait(1) until LocalPlayer.Character

-- Инициализация PhysicsService для Noclip
if not PhysicsService:GetCollisionGroups()[1] then
    PhysicsService:CreateCollisionGroup("NoclipGroup")
    PhysicsService:CollisionGroupSetCollidable("NoclipGroup", "Default", false)
end

-- Упрощенная система фарма
local farmingModules = {
    mastery = { enabled = false },
    fruits = { enabled = false },
    chests = { enabled = false },
    bones = { enabled = false }
}

-- Система Noclip и Fly
local function setupNoclip()
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, "NoclipGroup")
            part.CanCollide = false
        end
    end
end

local function flyTo(target)
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local direction = (target - hrp.Position).Unit
    hrp.AssemblyLinearVelocity = direction * 100
end

-- Автоатака
local function autoAttack()
    mouse1press()
    task.wait(0.1)
    mouse1release()
end

-- Основной цикл фарма
task.spawn(function()
    while task.wait(0.1) do
        if farmingModules.mastery.enabled then
            setupNoclip()
            
            -- Поиск врагов
            for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
                if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                    flyTo(enemy.HumanoidRootPart.Position + Vector3.new(0, 15, 0))
                    
                    -- Атака при близком расстоянии
                    if (enemy.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 50 then
                        autoAttack()
                    end
                    break
                end
            end
        end
    end
end)

-- Простое меню
local function createMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.Name = "FarmMenu"
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 300)
    frame.Position = UDim2.new(0.5, -100, 0.5, -150)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.2)
    frame.Parent = screenGui
    
    local function createButton(text, ypos, callback)
        local btn = Instance.new("TextButton")
        btn.Text = text
        btn.Size = UDim2.new(0.8, 0, 0, 40)
        btn.Position = UDim2.new(0.1, 0, 0, ypos)
        btn.Parent = frame
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    createButton("ФАРМ МАСТЕРИ", 50, function()
        farmingModules.mastery.enabled = not farmingModules.mastery.enabled
        btn.Text = farmingModules.mastery.enabled and "ВКЛ" or "ВЫКЛ"
    end)
    
    createButton("ЗАКРЫТЬ (M)", 250, function()
        screenGui:Destroy()
    end)
end

-- Обработчик клавиши M
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        createMenu()
    end
end)

-- Уведомление
game.StarterGui:SetCore("SendNotification", {
    Title = "АВТОФАРМ",
    Text = "Нажмите M для открытия меню",
    Duration = 5
})

print("Скрипт успешно загружен! Noclip и Fly активированы при фарме")
