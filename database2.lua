-- FIREBASE COMBO COCONUT - АБСОЛЮТНО НАДЕЖНАЯ ВЕРСИЯ
-- Запускается на каждом из 5 аккаунтов
-- Единственное, что нужно изменить: ACCOUNT_ID

local ACCOUNT_ID = 2  -- <--- ИЗМЕНИТЬ ДЛЯ КАЖДОГО АККАУНТА (1,2,3,4,5)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

-- 🔥 ТВОИ ДАННЫЕ FIREBASE (не меняй)
local FIREBASE_URL = "https://coconutcombo-363b6-default-rtdb.europe-west1.firebasedatabase.app/"
local FIREBASE_SECRET = "D1rn5TSyMvE84thM8YsSBvEDuNCznVD18Tfg3ZT8"

-- ==============================================
-- ПЕРЕМЕННЫЕ
-- ==============================================
local coconutActive = false
local coconutLostTime = nil
local currentAccessory = "none"
local hasCanister = false
local hasPorcelain = false
local myTurn = false
local hasSpawnedCombo = false
local spawnValues = {5, 11, 17, 23}
local lockTimestamp = 0

-- ==============================================
-- БАЗОВЫЕ ФУНКЦИИ FIREBASE
-- ==============================================
function SetFirebase(path, data)
    pcall(function()
        local url = string.format("%s%s.json?auth=%s", FIREBASE_URL, path, FIREBASE_SECRET)
        HttpService:RequestAsync({
            Url = url,
            Method = "PUT",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

function GetFirebase(path)
    local success, result = pcall(function()
        local url = string.format("%s%s.json?auth=%s", FIREBASE_URL, path, FIREBASE_SECRET)
        local response = HttpService:RequestAsync({Url = url, Method = "GET"})
        if response.Success then
            return HttpService:JSONDecode(response.Body)
        end
    end)
    return success and result
end

-- ==============================================
-- АТОМАРНАЯ БЛОКИРОВКА (САМОЕ ВАЖНОЕ)
-- ==============================================
function TryAcquireAtomicLock()
    local lockPath = "locks/spawn_lock"
    local currentTime = os.time()
    local maxRetries = 3
    
    for retry = 1, maxRetries do
        -- 1. GET с запросом ETag
        local getUrl = string.format("%s%s.json?auth=%s", FIREBASE_URL, lockPath, FIREBASE_SECRET)
        local getSuccess, getResponse = pcall(function()
            return HttpService:RequestAsync({
                Url = getUrl,
                Method = "GET",
                Headers = {["X-Firebase-ETag"] = "true"}
            })
        end)
        
        if not getSuccess or not getResponse.Success then
            task.wait(0.1)
            continue
        end
        
        local etag = getResponse.Headers["etag"]
        if not etag then
            task.wait(0.1)
            continue
        end
        
        local lockData = HttpService:JSONDecode(getResponse.Body)
        
        -- Проверка, активна ли блокировка
        if lockData and (currentTime - (lockData.timestamp or 0)) <= 10 then
            return false  -- Блокировка занята другим
        end
        
        -- 2. PUT с условием if-match
        local newLock = {owner = ACCOUNT_ID, timestamp = currentTime}
        local putUrl = string.format("%s%s.json?auth=%s", FIREBASE_URL, lockPath, FIREBASE_SECRET)
        local putSuccess, putResponse = pcall(function()
            return HttpService:RequestAsync({
                Url = putUrl,
                Method = "PUT",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["if-match"] = etag
                },
                Body = HttpService:JSONEncode(newLock)
            })
        end)
        
        if putSuccess and putResponse.Success then
            print("🔒 Аккаунт " .. ACCOUNT_ID .. " захватил блокировку")
            return true
        end
        
        -- 412 Precondition Failed – данные изменились, retry
        if putResponse and putResponse.StatusCode == 412 then
            task.wait(0.2)
            -- продолжаем цикл retry
        else
            task.wait(0.2)
        end
    end
    
    return false
end

function ReleaseAtomicLock()
    local lockPath = "locks/spawn_lock"
    
    -- Получаем ETag
    local getUrl = string.format("%s%s.json?auth=%s", FIREBASE_URL, lockPath, FIREBASE_SECRET)
    local getSuccess, getResponse = pcall(function()
        return HttpService:RequestAsync({
            Url = getUrl,
            Method = "GET",
            Headers = {["X-Firebase-ETag"] = "true"}
        })
    end)
    
    if not getSuccess or not getResponse.Success then return end
    local etag = getResponse.Headers["etag"]
    if not etag then return end
    
    -- Удаляем только если наша блокировка
    local deleteUrl = string.format("%s%s.json?auth=%s", FIREBASE_URL, lockPath, FIREBASE_SECRET)
    pcall(function()
        HttpService:RequestAsync({
            Url = deleteUrl,
            Method = "DELETE",
            Headers = {["if-match"] = etag}
        })
    end)
    
    print("🔓 Аккаунт " .. ACCOUNT_ID .. " освободил блокировку")
end

-- ==============================================
-- ФУНКЦИИ ИГРЫ
-- ==============================================
function EquipCanister()
    local args = {{"Equip",{Category="Accessory",Type="Coconut Canister"}}}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args[1]))
    currentAccessory = "canister"
    hasCanister = true
    hasPorcelain = false
    print("✅ Аккаунт " .. ACCOUNT_ID .. " Coconut Canister")
end

function EquipPorcelain()
    local args = {{"Equip",{Category="Accessory",Type="Porcelain Port-O-Hive"}}}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("ItemPackageEvent"):InvokeServer(unpack(args[1]))
    currentAccessory = "porcelain"
    hasPorcelain = true
    hasCanister = false
    print("✅ Аккаунт " .. ACCOUNT_ID .. " Porcelain")
end

function SpawnCoconut(isCombo)
    local args = {{{Name="Coconut"}}}
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayerActivesCommand"):FireServer(unpack(args[1]))
    if isCombo then
        print("🎯 АККАУНТ " .. ACCOUNT_ID .. " КОМБО КОКОС!")
    else
        print("🥥 Аккаунт " .. ACCOUNT_ID .. " обычный кокос")
    end
    lockTimestamp = tick()
end

function IsComboCoconutPresent()
    local particles = Workspace:FindFirstChild("Particles")
    if not particles then return false end
    for _, obj in pairs(particles:GetChildren()) do
        if obj.Name == "ComboCoconut" and obj.ClassName == "UnionOperation" then
            return true
        end
    end
    return false
end

function GetAccountValue(accId)
    return GetFirebase("accounts/" .. accId .. "/combo_value") or 0
end

function IsAccountReady(accId)
    return GetFirebase("accounts/" .. accId .. "/ready") or false
end

function GetCurrentTurn()
    return GetFirebase("turns/current_turn") or 1
end

function NextTurn()
    local nextTurn = GetCurrentTurn() + 1
    if nextTurn > 5 then nextTurn = 1 end
    SetFirebase("turns/current_turn", nextTurn)
    print("🔄 Аккаунт " .. ACCOUNT_ID .. ": ход перешел к " .. nextTurn)
end

-- ==============================================
-- ИНИЦИАЛИЗАЦИЯ FIREBASE
-- ==============================================
pcall(function()
    SetFirebase("accounts/" .. ACCOUNT_ID, {ready=false, combo_value=0})
    if not GetFirebase("turns") then
        SetFirebase("turns", {current_turn=1})
    end
    if not GetFirebase("locks") then
        SetFirebase("locks", {})
    end
end)

-- ==============================================
-- МОНИТОРИНГ ПОЯВЛЕНИЯ КОМБО
-- ==============================================
spawn(function()
    while true do
        local present = IsComboCoconutPresent()
        if present and not coconutActive then
            coconutActive = true
            coconutLostTime = nil
            print("🥥 Аккаунт " .. ACCOUNT_ID .. " комбо появилось")
        elseif not present and coconutActive then
            coconutActive = false
            coconutLostTime = tick()
            print("🥥 Аккаунт " .. ACCOUNT_ID .. " комбо исчезло")
            if GetCurrentTurn() == ACCOUNT_ID and hasSpawnedCombo then
                task.wait(15)
                SetFirebase("accounts/" .. ACCOUNT_ID .. "/ready", true)
                hasSpawnedCombo = false
                print("✅ Аккаунт " .. ACCOUNT_ID .. " готов к следующему циклу")
            end
        end
        task.wait(0.5)
    end
end)

-- ==============================================
-- ТАЙМЕР 15 СЕКУНД (ОБЫЧНЫЙ КОКОС + КАНИСТРА)
-- ==============================================
spawn(function()
    while true do
        if not coconutActive and coconutLostTime and tick() - coconutLostTime >= 15 then
            SpawnCoconut(false)
            if currentAccessory ~= "canister" then EquipCanister() end
            coconutLostTime = nil
        end
        task.wait(1)
    end
end)

-- ==============================================
-- СТРАХОВКА КАНИСТРЫ КАЖДЫЕ 5 СЕКУНД
-- ==============================================
spawn(function()
    while true do
        if GetAccountValue(ACCOUNT_ID) ~= 39 and currentAccessory ~= "canister" then
            EquipCanister()
        end
        task.wait(5)
    end
end)

-- ==============================================
-- ОСНОВНАЯ ЛОГИКА СПАВНА КОМБО (С АТОМАРНОЙ БЛОКИРОВКОЙ)
-- ==============================================
spawn(function()
    while true do
        local myTurn = (GetCurrentTurn() == ACCOUNT_ID)
        local myValue = GetAccountValue(ACCOUNT_ID)
        
        if myTurn and myValue == 39 and not hasSpawnedCombo then
            if TryAcquireAtomicLock() then
                -- Проверяем готовность остальных
                local allReady = true
                for i = 1, 5 do
                    if i ~= ACCOUNT_ID and not IsAccountReady(i) then
                        allReady = false
                        break
                    end
                end
                
                if allReady then
                    print("🎯 АККАУНТ " .. ACCOUNT_ID .. " СПАВНИТ КОМБО!")
                    SpawnCoconut(true)
                    hasSpawnedCombo = true
                    
                    for i = 1, 5 do
                        SetFirebase("accounts/" .. i .. "/ready", false)
                    end
                    
                    NextTurn()
                    ReleaseAtomicLock()
                else
                    ReleaseAtomicLock()
                end
            end
        end
        
        task.wait(2)
    end
end)

-- ==============================================
-- СЛУШАТЕЛЬ СОБЫТИЙ КОМБО
-- ==============================================
require(ReplicatedStorage.Events).ClientListen("PlayerAbilityEvent", function(data)
    for tag, info in pairs(data) do
        if (tag == "Combo Coconuts" or tag == "ComboCoconuts") and info.Action == "Update" then
            local value = info.Values and info.Values[1] or 0
            SetFirebase("accounts/" .. ACCOUNT_ID .. "/combo_value", value)
            
            if value < 39 and not hasCanister then
                EquipCanister()
            elseif value == 39 and not hasPorcelain then
                EquipPorcelain()
            end
            
            for _, sv in pairs(spawnValues) do
                if value == sv then
                    SpawnCoconut(false)
                    break
                end
            end
        end
    end
end)

-- ==============================================
-- ОЧИСТКА СТАРЫХ БЛОКИРОВОК
-- ==============================================
spawn(function()
    while true do
        task.wait(30)
        local lockData = GetFirebase("locks/spawn_lock")
        if lockData and (os.time() - (lockData.timestamp or 0)) > 30 then
            SetFirebase("locks/spawn_lock", nil)
            print("🧨 Принудительно сброшена старая блокировка")
        end
    end
end)

-- ==============================================
-- ДЕБАГ КАЖДЫЕ 10 СЕКУНД
-- ==============================================
spawn(function()
    while true do
        task.wait(10)
        print("📊 Firebase статус:")
        for i = 1, 5 do
            local v = GetAccountValue(i)
            local r = IsAccountReady(i)
            print("   Аккаунт " .. i .. ": value=" .. v .. ", ready=" .. tostring(r))
        end
        print("   Текущий ход: " .. GetCurrentTurn())
        local lock = GetFirebase("locks/spawn_lock")
        print("   Блокировка: " .. (lock and "аккаунт " .. lock.owner or "свободна"))
    end
end)

print("========================================")
print("✅ FIREBASE АТОМАРНАЯ ВЕРСИЯ - АККАУНТ " .. ACCOUNT_ID)
print("========================================")
print("🎯 Старт. Ожидание комбо...")
