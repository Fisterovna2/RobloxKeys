-- Загрузка библиотеки Rayfield для красивого UI
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- Ожидание загрузки игры
repeat task.wait() until game:IsLoaded()

-- Глобальная переменная для ключа
_G.QuantumKey = nil

-- Функция для загрузки скрипта игры
local function LoadGameScript()
    local GamesTable = {
        [2753915549] = "BloxFruits",
        [4442272183] = "BloxFruits",
        [7449423635] = "BloxFruits",
        [16732694052] = "Fisch"
    }
    
    local scriptName = GamesTable[game.PlaceId]
    if not scriptName then return end
    
    local scriptUrl = "https://raw.githubusercontent.com/Trustmenotcondom/QTONYX/main/"..scriptName..".lua"
    local scriptContent = game:HttpGet(scriptUrl, true)
    
    -- Извлекаем ключ из скрипта
    _G.QuantumKey = scriptContent:match('Key%s*=%s*["\']([^"\']+)["\']') or
                   scriptContent:match('key%s*=%s*["\']([^"\']+)["\']') or
                   scriptContent:match('KEY%s*=%s*["\']([^"\']+)["\']')
    
    -- Запускаем основной скрипт
    loadstring(scriptContent)()
end

-- Создаем основное меню
local Window = Rayfield:CreateWindow({
    Name = "Quantum X | Key System",
    LoadingTitle = "Quantum X Loader",
    LoadingSubtitle = "by TrustMeNot",
    ConfigurationSaving = {
        Enabled = false
    },
})

-- Вкладка для активации
local ActivationTab = Window:CreateTab("Activation", 4483362458)

ActivationTab:CreateInput({
    Name = "Enter Key",
    PlaceholderText = "Paste your key here",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        if Text == _G.QuantumKey then
            Rayfield:Notify({
                Title = "Activation Successful",
                Content = "All features unlocked!",
                Duration = 3,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Invalid Key",
                Content = "Please check your key and try again",
                Duration = 3,
                Image = 7733960981,
            })
        end
    end,
})

ActivationTab:CreateButton({
    Name = "Get Key from Clipboard",
    Callback = function()
        if setclipboard then
            setclipboard(_G.QuantumKey or "Key not found")
            Rayfield:Notify({
                Title = "Key Copied",
                Content = "Key has been copied to your clipboard",
                Duration = 3,
                Image = 7733765397,
            })
        end
    end,
})

-- Вкладка с функциями (только после активации)
local FeaturesTab = Window:CreateTab("Features", 7733925908)

-- Телепорт к игроку
FeaturesTab:CreateInput({
    Name = "Teleport to Player",
    PlaceholderText = "Enter player name",
    RemoveTextAfterFocusLost = false,
    Callback = function(PlayerName)
        for _, player in ipairs(game.Players:GetPlayers()) do
            if string.find(string.lower(player.Name), string.lower(PlayerName)) then
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                Rayfield:Notify({
                    Title = "Teleport Successful",
                    Content = "Teleported to "..player.Name,
                    Duration = 3,
                })
                return
            end
        end
        Rayfield:Notify({
            Title = "Player Not Found",
            Content = "Could not find player: "..PlayerName,
            Duration = 3,
        })
    end,
})

-- Авто-фарм
local AutoFarmToggle = FeaturesTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "Auto Farm Enabled",
                Content = "Starting farming process...",
                Duration = 3,
            })
            -- Здесь будет код авто-фарма
        else
            Rayfield:Notify({
                Title = "Auto Farm Disabled",
                Content = "Stopped farming",
                Duration = 3,
            })
        end
    end,
})

-- Управление скоростью
FeaturesTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end,
})

-- Кнопка для получения локации
FeaturesTab:CreateButton({
    Name = "Copy Current Location",
    Callback = function()
        local pos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
        local location = string.format("CFrame.new(%d, %d, %d)", pos.X, pos.Y, pos.Z)
        if setclipboard then
            setclipboard(location)
            Rayfield:Notify({
                Title = "Location Copied",
                Content = "Position copied to clipboard",
                Duration = 3,
            })
        end
    end,
})

-- Переключение видимости интерфейса
local MinimizeButton = Rayfield:CreateMinimizeButton({
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

-- Загружаем скрипт игры
pcall(LoadGameScript)

-- Уведомление о загрузке
Rayfield:Notify({
    Title = "Quantum X Loaded",
    Content = "Press M to open menu\nYour key: "..(_G.QuantumKey or "Not found"),
    Duration = 8,
    Image = 4483362458,
})
