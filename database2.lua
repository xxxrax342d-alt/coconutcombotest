-- ==============================================
--   ЛОКАЛЬНАЯ ОЧЕРЕДЬ КОМБО 1→2→3→4→5→1
--   БЕЗ FIREBASE, БЕЗ ГОНКОВ, БЕЗ ОДНОВРЕМЕННЫХ СПАВНОВ
-- ==============================================

local ACCOUNT_ID = 2   -- <--- УСТАНОВИТЬ 1..5 ДЛЯ КАЖДОГО АККАУНТА

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

-- ==============================================
-- ПЕРЕМЕННЫЕ
-- ==============================================
local comboActive = false
local comboLostTime = nil
local localComboValue = 0
local cycleCounter = 0     -- локальный номер цикла (1..5)
local spawnValues = {5, 11, 17, 23}

local currentAccessory = "none"
local hasCanister = false
local hasPorcelain = false
local hasSpawnedCombo = false

-- ==============================================
-- ФУНКЦИИ ИГРЫ
-- ==============================================
local function EquipCanister()
    local args = {{"Equip",{Category="Accessory",Type="Coconut Canister"}}}
    ReplicatedStorage.Events.ItemPackageEvent:InvokeServer(unpack(args[1]))
    currentAccessory = "canister"
    hasCanister = true
    hasPorcelain = false
    print("🥥 ["..ACCOUNT_ID.."] Coconut Canister")
end

local function EquipPorcelain()
    local args = {{"Equip",{Category="Accessory",Type="Porcelain Port-O-Hive"}}}
    ReplicatedStorage.Events.ItemPackageEvent:InvokeServer(unpack(args[1]))
    currentAccessory = "porcelain"
    hasPorcelain = true
    hasCanister = false
    print("🍶 ["..ACCOUNT_ID.."] Porcelain Port-O-Hive")
end

local function SpawnCoconut(isCombo)
    local args = {{{Name="Coconut"}}}
    ReplicatedStorage.Events.PlayerActivesCommand:FireServer(unpack(args[1]))
    if isCombo then
        print("🔥 ["..ACCOUNT_ID.."] ЗАПУСКАЮ КОМБО!")
    else
        print("🥥 ["..ACCOUNT_ID.."] обычный кокос")
    end
end

local function IsComboCoconutPresent()
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return false end
    for _, obj in ipairs(particles:GetChildren()) do
        if obj.Name == "ComboCoconut" and obj.ClassName == "UnionOperation" then
            return true
        end
    end
    return false
end

-- ==============================================
-- ОТСЛЕЖИВАНИЕ ПОЯВЛЕНИЯ / ИСЧЕЗНОВЕНИЯ КОМБО
-- ==============================================
spawn(function()
    while true do
        local present = IsComboCoconutPresent()

        if present and not comboActive then
            comboActive = true
            comboLostTime = nil
            print("✨ ["..ACCOUNT_ID.."] Комбо появилось")

        elseif not present and comboActive then
            comboActive = false
            comboLostTime = tick()
            print("💨 ["..ACCOUNT_ID.."] Комбо исчезло")

            -- Увеличиваем локальный цикл
            cycleCounter = cycleCounter + 1
            if cycleCounter > 5 then cycleCounter = 1 end

            print("🔄 ["..ACCOUNT_ID.."] Новый цикл: "..cycleCounter)

            hasSpawnedCombo = false
        end

        task.wait(0.5)
    end
end)

-- ==============================================
-- 15 СЕКУНД ПОСЛЕ КОНЦА КОМБО → 1 кокос + Canister
-- ==============================================
spawn(function()
    while true do
        if comboLostTime and not comboActive and tick() - comboLostTime >= 15 then
            if currentAccessory ~= "canister" then
                EquipCanister()
            end
            SpawnCoconut(false) -- первый кокос нового цикла
            comboLostTime = nil
        end
        task.wait(1)
    end
end)

-- ==============================================
-- СТРАХОВКА КАНИСТРЫ
-- ==============================================
spawn(function()
    while true do
        if localComboValue < 39 and currentAccessory ~= "canister" then
            EquipCanister()
        end
        task.wait(5)
    end
end)

-- ==============================================
-- ОСНОВНАЯ ЛОГИКА ОЧЕРЕДИ
-- ==============================================
spawn(function()
    while true do
        -- Условие запуска combo:
        -- 1) мой номер цикла
        -- 2) comboValue = 39
        -- 3) combo сейчас нет
        -- 4) я ещё не запускал combo в этом цикле
        if cycleCounter == ACCOUNT_ID
        and localComboValue == 39
        and not comboActive
        and not hasSpawnedCombo then

            print("🎯 ["..ACCOUNT_ID.."] МОЙ ХОД! Запускаю combo.")
            SpawnCoconut(true)
            hasSpawnedCombo = true
        end

        task.wait(1)
    end
end)

-- ==============================================
-- ОТСЛЕЖИВАНИЕ comboValue (локально)
-- ==============================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if (tag == "Combo Coconuts" or tag == "ComboCoconuts")
        and info.Action == "Update" then

            local value = info.Values and info.Values[1] or 0
            localComboValue = value

            -- На 39 → надеваем Porcelain
            if value == 39 and not hasPorcelain then
                EquipPorcelain()
            end

            -- На 5 / 11 / 17 / 23 → бросаем кокос
            for _, v in ipairs(spawnValues) do
                if value == v then
                    SpawnCoconut(false)
                    break
                end
            end
        end
    end
end)

print("========================================")
print("  ЛОКАЛЬНАЯ ОЧЕРЕДЬ КОМБО — АККАУНТ "..ACCOUNT_ID)
print("========================================")
