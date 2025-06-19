-- ПОЛНОСТЬЮ ПЕРЕРАБОТАННАЯ ФУНКЦИЯ ПОИСКА ОБЪЕКТОВ С ОТЛАДКОЙ
local function findObjects(objectType)
    local foundObjects = {}
    local startTime = os.clock()
    
    log("Начинаем поиск объектов типа: " .. objectType)
    
    -- Динамические пути поиска
    local searchLocations = {
        enemies = {
            Workspace.Enemies,
            Workspace.Live,
            Workspace.NPCs,
            Workspace.Mobs,
            Workspace["_ENEMIES"],
            Workspace
        },
        fruits = {
            Workspace.Fruits,
            Workspace.SpawnedFruits,
            Workspace.FruitSpawns,
            Workspace["_FRUITS"],
            Workspace
        },
        chests = {
            Workspace.Chests,
            Workspace.Treasures,
            Workspace.Loot,
            Workspace["_CHESTS"],
            Workspace.Islands,
            Workspace
        },
        bones = {
            Workspace.Bones,
            Workspace.Items,
            Workspace.Loot,
            Workspace["_BONES"],
            Workspace.Islands,
            Workspace
        }
    }
    
    -- Гибкие критерии поиска
    local searchCriteria = {
        enemies = function(obj)
            return obj:IsA("Model") and 
                   (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")) and
                   obj:FindFirstChildOfClass("Humanoid") and 
                   obj:GetAttribute("Health") ~= 0
        end,
        
        fruits = function(obj)
            return (obj:IsA("Model") or obj:IsA("MeshPart")) and 
                   obj.Name:match("[Ff]ruit") and 
                   obj:FindFirstChild("Handle")
        end,
        
        chests = function(obj)
            return obj:IsA("Model") and 
                   obj.Name:match("[Cc]hest") and 
                   (obj:FindFirstChild("Chest") or obj:FindFirstChild("Loot"))
        end,
        
        bones = function(obj)
            return (obj:IsA("MeshPart") or obj:IsA("Part")) and 
                   obj.Name:match("[Bb]one") and 
                   obj:FindFirstChild("ClickDetector")
        end
    }
    
    local paths = searchLocations[objectType]
    local criteria = searchCriteria[objectType]
    
    if not paths or not criteria then
        log("ОШИБКА: Неизвестный тип объекта - " .. objectType)
        return foundObjects
    end
    
    log("Пути поиска:")
    local validPaths = {}
    for _, path in ipairs(paths) do
        if path then
            log("  - " .. path:GetFullName())
            table.insert(validPaths, path)
        end
    end
    
    -- Расширенный поиск с отладкой
    for _, location in ipairs(validPaths) do
        local countBefore = #foundObjects
        
        for _, obj in ipairs(location:GetDescendants()) do
            if criteria(obj) then
                table.insert(foundObjects, obj)
            end
        end
        
        local countFound = #foundObjects - countBefore
        log("Найдено в " .. location.Name .. ": " .. countFound)
    end
    
    -- Альтернативный метод для врагов
    if objectType == "enemies" and #foundObjects == 0 then
        log("Пробуем альтернативный поиск врагов...")
        for _, npc in ipairs(Workspace:GetChildren()) do
            if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") then
                local humanoid = npc:FindFirstChildOfClass("Humanoid")
                if humanoid.Health > 0 then
                    table.insert(foundObjects, npc)
                end
            end
        end
        log("Альтернативный метод нашел: " .. #foundObjects)
    end
    
    log(string.format("Найдено объектов: %d (за %.3f сек)", #foundObjects, os.clock() - startTime))
    return foundObjects
end
