-- Загрузка библиотеки Rayfield для UI
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- Ожидание загрузки игры
repeat task.wait() until game:IsLoaded()

-- Основные переменные
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Состояния фарма
local ChestFarmEnabled = false
local MasteryFarmEnabled = false
local FruitFarmEnabled = false
local BoneFarmEnabled = false
local WhiteScreenEnabled = false

-- Создаем основное меню
local Window = Rayfield:CreateWindow({
    Name = "Quantum X | Blox Fruits",
    LoadingTitle = "Blox Fruits Cheats",
    LoadingSubtitle = "Auto Farm Mastery, Fruits & Bones",
    ConfigurationSaving = {
        Enabled = false
    },
})

-- Вкладка визуальных функций
local VisualTab = Window:CreateTab("Visual", 4483362458)

-- Функция белого экрана
VisualTab:CreateToggle({
    Name = "White Screen Mode",
    CurrentValue = false,
    Flag = "WhiteScreen",
    Callback = function(Value)
        WhiteScreenEnabled = Value
        if Value then
            -- Сохраняем оригинальные настройки
            if not _originalLighting then
                _originalLighting = {
                    Ambient = Lighting.Ambient,
                    Brightness = Lighting.Brightness,
                    ColorShift_Top = Lighting.ColorShift_Top,
                    OutdoorAmbient = Lighting.OutdoorAmbient
                }
            end
            
            -- Устанавливаем белый экран
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2
            Lighting.ColorShift_Top = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.FogEnd = 100000
            
            Rayfield:Notify({
                Title = "White Screen Enabled",
                Content = "Everything is now bright white",
                Duration = 3,
            })
        else
            -- Восстанавливаем оригинальные настройки
            if _originalLighting then
                Lighting.Ambient = _originalLighting.Ambient
                Lighting.Brightness = _originalLighting.Brightness
                Lighting.ColorShift_Top = _originalLighting.ColorShift_Top
                Lighting.OutdoorAmbient = _originalLighting.OutdoorAmbient
                Lighting.FogEnd = 10000
            end
            
            Rayfield:Notify({
                Title = "White Screen Disabled",
                Content = "Lighting restored to normal",
                Duration = 3,
            })
        end
    end,
})

-- Удаление листвы и декораций
VisualTab:CreateToggle({
    Name = "Remove Foliage",
    CurrentValue = false,
    Flag = "RemoveFoliage",
    Callback = function(Value)
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if Value then
                if obj:IsA("Part") and (obj.Name:find("Leaf") or obj.Name:find("Grass") or obj.Name:find("Bush")) then
                    obj.Transparency = 1
                elseif obj:IsA("Decal") then
                    obj.Transparency = 1
                end
            else
                if obj:IsA("Part") and (obj.Name:find("Leaf") or obj.Name:find("Grass") or obj.Name:find("Bush")) then
                    obj.Transparency = 0
                elseif obj:IsA("Decal") then
                    obj.Transparency = 0
                end
            end
        end
    end,
})

-- Вкладка функций фарма
local FarmTab = Window:CreateTab("Farming", 7733925908)

-- Авто-фарм сундуков
FarmTab:CreateToggle({
    Name = "Auto Chest Farm",
    CurrentValue = false,
    Flag = "ChestFarm",
    Callback = function(Value)
        ChestFarmEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Chest Farm Enabled",
                Content = "Starting chest farming...",
                Duration = 3,
            })
        else
            Rayfield:Notify({
                Title = "Chest Farm Disabled",
                Content = "Stopped farming chests",
                Duration = 3,
            })
        end
    end,
})

-- Фарм мастерства
FarmTab:CreateToggle({
    Name = "Auto Mastery Farm",
    CurrentValue = false,
    Flag = "MasteryFarm",
    Callback = function(Value)
        MasteryFarmEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Mastery Farm Enabled",
                Content = "Starting mastery farming...",
                Duration = 3,
            })
        else
            Rayfield:Notify({
                Title = "Mastery Farm Disabled",
                Content = "Stopped farming mastery",
                Duration = 3,
            })
        end
    end,
})

-- Фарм фруктов
FarmTab:CreateToggle({
    Name = "Auto Fruit Farm",
    CurrentValue = false,
    Flag = "FruitFarm",
    Callback = function(Value)
        FruitFarmEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Fruit Farm Enabled",
                Content = "Starting fruit farming...",
                Duration = 3,
            })
        else
            Rayfield:Notify({
                Title = "Fruit Farm Disabled",
                Content = "Stopped farming fruits",
                Duration = 3,
            })
        end
    end,
})

-- Фарм костей
FarmTab:CreateToggle({
    Name = "Auto Bone Farm",
    CurrentValue = false,
    Flag = "BoneFarm",
    Callback = function(Value)
        BoneFarmEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Bone Farm Enabled",
                Content = "Starting bone farming...",
                Duration = 3,
            })
        else
            Rayfield:Notify({
                Title = "Bone Farm Disabled",
                Content = "Stopped farming bones",
                Duration = 3,
            })
        end
    end,
})

-- Управление скоростью
FarmTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

-- Управление прыжком
FarmTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 200},
    Increment = 10,
    Suffix = "power",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end,
})

-- Функция для фарма сундуков
local function ChestFarmLoop()
    while ChestFarmEnabled do
        local chests = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name:find("Chest") and obj:IsA("Model") and obj:FindFirstChild("Chest") then
                table.insert(chests, obj)
            end
        end
        
        if #chests > 0 then
            -- Сортируем сундуки по расстоянию
            table.sort(chests, function(a, b)
                return (a.Chest.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                       (b.Chest.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end)
            
            -- Берем ближайший сундук
            local targetChest = chests[1]
            local chestPos = targetChest.Chest.Position
            
            -- Телепортируемся к сундуку
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(chestPos.X, chestPos.Y + 3, chestPos.Z)
            end
            
            -- Ждем перед проверкой следующего сундука
            task.wait(2)
        else
            task.wait(5)
        end
    end
end

-- Функция для фарма мастерства
local function MasteryFarmLoop()
    while MasteryFarmEnabled do
        local npcs = {}
        for _, npc in ipairs(Workspace.NPCs:GetChildren()) do
            if npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                table.insert(npcs, npc)
            end
        end
        
        if #npcs > 0 then
            -- Сортируем NPC по расстоянию
            table.sort(npcs, function(a, b)
                return (a.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                       (b.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end)
            
            -- Берем ближайшего NPC
            local targetNpc = npcs[1]
            local npcPos = targetNpc.HumanoidRootPart.Position
            
            -- Телепортируемся к NPC
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(npcPos.X, npcPos.Y, npcPos.Z) * CFrame.new(0, 0, 5)
                
                -- Атакуем NPC
                local args = {
                    [1] = targetNpc.Humanoid,
                    [2] = targetNpc.HumanoidRootPart.Position
                }
                game:GetService("Players").LocalPlayer.Character.Combat.RemoteEvent:FireServer(unpack(args))
            end
            
            -- Ждем перед следующей атакой
            task.wait(0.5)
        else
            task.wait(3)
        end
    end
end

-- Функция для фарма фруктов
local function FruitFarmLoop()
    while FruitFarmEnabled do
        local fruits = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "Fruit" and obj:IsA("Model") and obj:FindFirstChild("Handle") then
                table.insert(fruits, obj)
            end
        end
        
        if #fruits > 0 then
            -- Сортируем фрукты по расстоянию
            table.sort(fruits, function(a, b)
                return (a.Handle.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                       (b.Handle.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end)
            
            -- Берем ближайший фрукт
            local targetFruit = fruits[1]
            local fruitPos = targetFruit.Handle.Position
            
            -- Телепортируемся к фрукту
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(fruitPos.X, fruitPos.Y, fruitPos.Z)
            end
            
            -- Ждем перед проверкой следующего фрукта
            task.wait(2)
        else
            task.wait(5)
        end
    end
end

-- Функция для фарма костей
local function BoneFarmLoop()
    while BoneFarmEnabled do
        local enemies = {}
        for _, enemy in ipairs(Workspace.Enemies:GetChildren()) do
            if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and enemy.Name:find("Skeleton") then
                table.insert(enemies, enemy)
            end
        end
        
        if #enemies > 0 then
            -- Сортируем врагов по расстоянию
            table.sort(enemies, function(a, b)
                return (a.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                       (b.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end)
            
            -- Берем ближайшего врага
            local targetEnemy = enemies[1]
            local enemyPos = targetEnemy.HumanoidRootPart.Position
            
            -- Телепортируемся к врагу
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(enemyPos.X, enemyPos.Y, enemyPos.Z) * CFrame.new(0, 0, 5)
                
                -- Атакуем врага
                local args = {
                    [1] = targetEnemy.Humanoid,
                    [2] = targetEnemy.HumanoidRootPart.Position
                }
                game:GetService("Players").LocalPlayer.Character.Combat.RemoteEvent:FireServer(unpack(args))
            end
            
            -- Ждем перед следующей атакой
            task.wait(0.5)
        else
            task.wait(3)
        end
    end
end

-- Запуск потоков фарма
task.spawn(function()
    while true do
        if ChestFarmEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            ChestFarmLoop()
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if MasteryFarmEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            MasteryFarmLoop()
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if FruitFarmEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            FruitFarmLoop()
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if BoneFarmEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            BoneFarmLoop()
        end
        task.wait(0.1)
    end
end)

-- Переключение видимости интерфейса
Rayfield:CreateMinimizeButton({
    Name = "Minimize",
    Callback = function()
        print("UI minimized")
    end,
})

-- Обработчик клавиши M
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        Rayfield:ToggleUI()
    end
end)

-- Авто-сохранение позиции при смерти
LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid").Died:Connect(function()
        if LocalPlayer:FindFirstChild("LastSafePosition") then
            task.wait(5) -- Ждем респавна
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.LastSafePosition.Value
            end
        end
    end)
end)

-- Авто-обновление позиции
task.spawn(function()
    while true do
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if not LocalPlayer:FindFirstChild("LastSafePosition") then
                local value = Instance.new("CFrameValue")
                value.Name = "LastSafePosition"
                value.Value = LocalPlayer.Character.HumanoidRootPart.CFrame
                value.Parent = LocalPlayer
            else
                LocalPlayer.LastSafePosition.Value = LocalPlayer.Character.HumanoidRootPart.CFrame
            end
        end
        task.wait(1)
    end
end)

-- Уведомление о загрузке
Rayfield:Notify({
    Title = "Quantum X Loaded",
    Content = "Press M to open menu\nFeatures: Mastery, Fruit, Bone & Chest Farm!",
    Duration = 8,
    Image = 4483362458,
})
