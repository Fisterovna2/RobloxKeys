repeat task.wait() until game:IsLoaded()

-- Определение имени исполнителя
local executorname = "Unknown"
if getexecutorname then
    executorname = getexecutorname()
elseif identifyexecutor then
    executorname = identifyexecutor()
end

-- Блокировка нежелательных исполнителей
local FAKE_EXECUTOR = { "xeno", "jjsploit" }
for _, v in ipairs(FAKE_EXECUTOR) do
    if executorname:lower():find(v) then
        game.Players.LocalPlayer:Kick("\n\n" .. executorname .. " is not supported")
        return
    end
end

-- Список игр и соответствующих скриптов
local GameScripts = {
    [5682590751] = "Lootify",
    [994732206] = "Blox%20Fruits/Loader.lua",
    [1451439645] = "King%20Legacy/Loader.lua",
    [6765805766] = "Block%20Spin/Loader.lua",
    [7095682825] = "Beaks/Default.lua",
    [7436755782] = "Grow%20a%20Garden/Default.lua"
}

-- Обработчик клавиши M
local UserInputService = game:GetService("UserInputService")
local MenuVisible = false

local function ToggleMenu()
    MenuVisible = not MenuVisible
    print("Меню " .. (MenuVisible and "открыто" or "закрыто"))
    -- Здесь добавьте код для показа/скрытия вашего GUI
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.M then
        ToggleMenu()
    end
end)

-- Загрузка игрового скрипта
local GameId = game.GameId
if GameScripts[GameId] then
    local scriptUrl = "https://raw.githubusercontent.com/xQuartyx/QuartyzScript/main/" .. GameScripts[GameId]
    local success, err = pcall(function()
        loadstring(game:HttpGet(scriptUrl))()
    end)
    
    if not success then
        warn("Ошибка загрузки скрипта: " .. err)
    end
else
    warn("Для этой игры нет специального скрипта (GameId: " .. GameId .. ")")
end

-- Отправка статистики (опционально)
if request then
    pcall(function()
        request({
            Url = "https://auth.quartyz.com/execute?game=" .. GameId .. 
                  (getgenv().Mode and "&mode=" .. getgenv().Mode or "") .. 
                  "&executor=" .. executorname
        })
    end)
end

print("Скрипт успешно запущен! Нажмите M для открытия меню.")
