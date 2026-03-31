-- PetalPart Teleporter (лут по приоритету с порогами: Red<5, остальные<2)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========== КОНФИГУРАЦИЯ ==========
local UPDATE_INTERVAL = 1.0               -- частота проверки баффов (не используется напрямую)
local CONSTANT_TELEPORT_INTERVAL = 2.0    -- интервал между телепортами (теперь 2 секунды)
local PETAL_PART_NAME = "PetalPart"

-- Цвета лепестков
local PETAL_COLORS = {
    ["Blue Petal"]    = Color3.fromRGB(33, 66, 249),
    ["Black Petal"]   = Color3.fromRGB(11, 11, 11),
    ["White Petal"]   = Color3.fromRGB(249, 249, 249),
    ["Green Petal"]   = Color3.fromRGB(35, 232, 5),
    ["Cyan Petal"]    = Color3.fromRGB(29, 196, 222),
    ["Violet Petal"]  = Color3.fromRGB(94, 38, 177),
    ["Yellow Petal"]  = Color3.fromRGB(238, 204, 79),
    ["Scarlet Petal"] = Color3.fromRGB(171, 19, 19),
    ["Merigold Petal"]= Color3.fromRGB(218, 168, 28),
    ["Red Petal"]     = Color3.fromRGB(249, 34, 34),
    ["Grey Petal"]    = Color3.fromRGB(127, 127, 127),
    ["Pink Petal"]    = Color3.fromRGB(255, 130, 201),
    ["Periwinkle Petal"] = Color3.fromRGB(150, 156, 236),
}

-- Пороги для каждого цвета
local BUFF_THRESHOLDS = {
    ["Red Petal"] = 5,   -- красный < 5 сек
}
local DEFAULT_THRESHOLD = 2  -- остальные < 2 сек

-- Приоритет цветов (меньше = выше)
local COLOR_PRIORITY = {
    ["Red Petal"] = 1,
    ["Periwinkle Petal"] = 2,
    ["Pink Petal"] = 3,
    ["Scarlet Petal"] = 4,
    ["Violet Petal"] = 5,
    ["Merigold Petal"] = 6,
    ["Green Petal"] = 7,
    ["Yellow Petal"] = 8,
}

local isTeleporting = false
local enabled = true

-- ========== ВСПОМОГАТЕЛЬНЫЕ ==========
local function getColorName(color)
    for name, col in pairs(PETAL_COLORS) do
        if math.abs(col.R - color.R) < 0.01 and
           math.abs(col.G - color.G) < 0.01 and
           math.abs(col.B - color.B) < 0.01 then
            return name
        end
    end
    return "Unknown"
end

-- Поиск лепестка конкретного цвета (ближайший)
local function findNearestPetalByColor(targetColor, maxAttempts)
    maxAttempts = maxAttempts or 1
    for attempt = 1, maxAttempts do
        local particles = Workspace:FindFirstChild("Particles")
        if particles then
            local character = LocalPlayer.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local best, bestDist = nil, math.huge
                    for _, obj in ipairs(particles:GetChildren()) do
                        if obj.Name == PETAL_PART_NAME and obj:IsA("BasePart") then
                            local col = obj.Color
                            if math.abs(col.R - targetColor.R) < 0.01 and
                               math.abs(col.G - targetColor.G) < 0.01 and
                               math.abs(col.B - targetColor.B) < 0.01 then
                                local dist = (obj.Position - hrp.Position).Magnitude
                                if dist < bestDist then
                                    bestDist = dist
                                    best = obj
                                end
                            end
                        end
                    end
                    if best then return best end
                end
            end
        end
        if attempt < maxAttempts then task.wait(0.1) end
    end
    return nil
end

-- Получение всех уникальных цветов лепестков в мире (ближайший на цвет)
local function getAllUniquePetals()
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return {} end

    local character = LocalPlayer.Character
    if not character then return {} end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end

    local colorToPart = {}
    for _, obj in ipairs(particles:GetChildren()) do
        if obj.Name == PETAL_PART_NAME and obj:IsA("BasePart") then
            local color = obj.Color
            local dist = (obj.Position - hrp.Position).Magnitude
            local foundKey = nil
            for c, data in pairs(colorToPart) do
                if math.abs(c.R - color.R) < 0.01 and
                   math.abs(c.G - color.G) < 0.01 and
                   math.abs(c.B - color.B) < 0.01 then
                    foundKey = c
                    break
                end
            end
            if foundKey then
                if dist < colorToPart[foundKey].dist then
                    colorToPart[foundKey] = {part = obj, dist = dist}
                end
            else
                colorToPart[color] = {part = obj, dist = dist}
            end
        end
    end

    local result = {}
    for color, data in pairs(colorToPart) do
        table.insert(result, {color = color, name = getColorName(color), part = data.part, dist = data.dist})
    end
    return result
end

-- Сортировка кандидатов по приоритету
local function sortByPriority(candidates)
    table.sort(candidates, function(a, b)
        local priorityA = COLOR_PRIORITY[a.name] or 999
        local priorityB = COLOR_PRIORITY[b.name] or 999
        if priorityA ~= priorityB then
            return priorityA < priorityB
        else
            return math.random() < 0.5
        end
    end)
    return candidates
end

-- ========== ТЕЛЕПОРТ ==========
local function teleportToPetalAndBack(petal, reason)
    if not petal or isTeleporting then return end
    isTeleporting = true

    local character = LocalPlayer.Character
    if not character then isTeleporting = false; return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not hrp or not humanoid then isTeleporting = false; return end

    local originalPos = hrp.CFrame
    local colorName = getColorName(petal.Color) or "Unknown"

    local oldCameraType = Camera.CameraType
    local oldCameraCFrame = Camera.CFrame
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = oldCameraCFrame

    humanoid.AutoRotate = false
    humanoid.PlatformStand = true
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)

    hrp.CFrame = petal.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.1)

    hrp.CFrame = originalPos
    task.wait(0.05)
    hrp.CFrame = originalPos

    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)

    humanoid.PlatformStand = false
    humanoid.AutoRotate = true
    Camera.CameraType = oldCameraType

    hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.5, 0)
    task.wait(0.05)

    print(string.format("🔄 Телепорт к %s (%s) — %s", petal.Name, colorName, reason))
    isTeleporting = false
end

-- ========== ПОЛУЧЕНИЕ АКТИВНЫХ БАФФОВ С ОСТАТКОМ ==========
local function fetchPlayerStats()
    local event = ReplicatedStorage:FindFirstChild("Events")
    if not event then return nil end
    local func = event:FindFirstChild("RetrievePlayerStats")
    if not func then return nil end
    local success, result = pcall(function()
        return func:InvokeServer()
    end)
    return success and result or nil
end

local function collectBuffs(data, results)
    if type(data) ~= "table" then return end
    if data.Src and data.Start and data.Dur then
        if PETAL_COLORS[data.Src] then
            table.insert(results, data)
        end
    end
    for _, v in pairs(data) do
        if type(v) == "table" then
            collectBuffs(v, results)
        end
    end
end

-- Возвращает таблицу { [имя цвета] = оставшееся_время }
local function getActiveBuffRemaining()
    local stats = fetchPlayerStats()
    if not stats then return {} end
    local buffs = {}
    collectBuffs(stats, buffs)
    local active = {}
    for _, buff in ipairs(buffs) do
        local remaining = (buff.Start + buff.Dur) - os.time()
        if remaining > 0 then
            active[buff.Src] = remaining
        end
    end
    return active
end

-- ========== ВЫБОР ЦЕЛИ С УЧЁТОМ ПОРОГОВ ==========
local function selectTarget()
    local allPetals = getAllUniquePetals()
    if #allPetals == 0 then return nil end

    local activeBuffs = getActiveBuffRemaining()  -- таблица имя -> остаток
    local candidates = {}

    for _, petal in ipairs(allPetals) do
        local colorName = petal.name
        local remaining = activeBuffs[colorName]
        local threshold = BUFF_THRESHOLDS[colorName] or DEFAULT_THRESHOLD

        if remaining then
            -- Бафф активен
            if remaining < threshold then
                -- Осталось меньше порога → можно лутать (для продления)
                table.insert(candidates, petal)
            end
            -- Если осталось >= порога, не включаем
        else
            -- Баффа нет → можно лутать
            table.insert(candidates, petal)
        end
    end

    if #candidates == 0 then return nil end
    local sorted = sortByPriority(candidates)
    return sorted[1].part
end

-- ========== ОСНОВНОЙ ЦИКЛ ==========
task.spawn(function()
    while true do
        if enabled and not isTeleporting then
            local target = selectTarget()
            if target then
                teleportToPetalAndBack(target, "лут по приоритету (с порогами)")
            end
        end
        task.wait(CONSTANT_TELEPORT_INTERVAL)
    end
end)

-- ========== ПЕРЕКЛЮЧЕНИЕ ПО R ==========
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R then
        enabled = not enabled
        if enabled then
            print("🟢 Скрипт включен")
        else
            print("🔴 Скрипт выключен")
        end
    end
end)

print("✅ PetalPart Teleporter (лут по приоритету с порогами) загружен")
print("Нажмите R для вкл/выкл")
print("Телепорт каждые 2 секунды")
print("Пороги: Red Petal <5 сек, остальные <2 сек")
print("Если бафф активен и осталось >= порога, лепесток не лутается")
print("Приоритет: Red → Periwinkle → Pink → Scarlet → Violet → Merigold → Green → Yellow → остальные случайно")
