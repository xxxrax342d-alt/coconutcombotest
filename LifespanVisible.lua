-- УНИВЕРСАЛЬНЫЙ ТАЙМЕР С ДЕТЕКТОМ DUPED И ПРЕФИКСАМИ
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ===== НАСТРОЙКИ =====
local ABILITY_TOKEN_MULTIPLIER = 1.24        -- твой множитель способностей
local DIGITAL_BEE_LEVEL = 23                  -- уровень Digital Bee (если нет, поставь 1)
local DUPED_HEIGHT_THRESHOLD = 5              -- если токен выше игрока на это число студий, считаем дублированным
-- =====================

local function getPlayerRoot()
    if LocalPlayer and LocalPlayer.Character then
        return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- База данных токенов: id = { name, baseLifetime, normalColor, dupedColor, bgColor, prefix }
local tokens = {
    -- Медвежьи морфы (базовое время 15 сек)
    [1472532912] = { name = "Polar Bear", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [1472491940] = { name = "Black Bear", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [1472425802] = { name = "Brown Bear", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [2032949183] = { name = "Mother Bear", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [1472580249] = { name = "Panda", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    [1489734171] = { name = "Science Bear", base = 15, normalColor = Color3.new(0.9, 0.7, 0.5), dupedColor = Color3.new(0.6, 0.4, 0.2), bgColor = Color3.new(0,0,0), prefix = "MO " },
    -- Inspire (8 сек)
    [2000457501] = { name = "Inspire", base = 8, normalColor = Color3.new(1, 1, 0), dupedColor = Color3.new(1, 0.84, 0), bgColor = Color3.new(0,0,0), prefix = "IN " },
    -- Token link (4 сек) - игнорируем дублированные
    [1629547638] = { name = "Token Link", base = 4, normalColor = Color3.new(0,0,0), dupedColor = nil, bgColor = Color3.new(1,1,1), prefix = "TL " },
    -- Glitch (4 сек)
    [5877939956] = { name = "Glitch", base = 4, normalColor = Color3.new(1,1,1), dupedColor = Color3.new(1,1,1), bgColor = Color3.new(0,0,0), prefix = "SM " },
}

local activeTokens = {}

-- Функция получения числового ID из текстуры
local function getTextureId(texture)
    local id = texture:match("id=(%d+)") or texture:match("rbxassetid://(%d+)")
    return id and tonumber(id)
end

-- Проверка, является ли объект целевым токеном
local function isTargetToken(obj)
    if obj.Name ~= "C" or not obj:IsA("BasePart") then return false, nil end
    local front = obj:FindFirstChild("FrontDecal")
    if not front or not front:IsA("Decal") then return false, nil end
    local id = getTextureId(front.Texture)
    if id and tokens[id] then
        return true, id
    end
    return false, nil
end

-- Определение, дублированный ли токен (по высоте над игроком)
local function isDuped(part)
    local root = getPlayerRoot()
    if not root then return false end
    return (part.Position.Y - root.Position.Y) > DUPED_HEIGHT_THRESHOLD
end

-- Расчёт времени жизни с учётом дублирования (правильная формула)
local function calculateLifetime(base, duped)
    local normal = base * ABILITY_TOKEN_MULTIPLIER
    if not duped then return normal end
    local dupedMultiplier = 2 + 0.05 * (DIGITAL_BEE_LEVEL - 1)   -- например, 2 + 1.1 = 3.1 для 23 уровня
    return normal * dupedMultiplier
end

-- Создание таймера
local function createTimer(part, id)
    if activeTokens[part] then return end
    local data = tokens[id]
    local duped = isDuped(part)

    -- Игнорируем дублированный Token Link
    if duped and id == 1629547638 then
        return
    end

    local totalLifetime = calculateLifetime(data.base, duped)

    local gui = Instance.new("BillboardGui")
    gui.Adornee = part
    gui.Size = UDim2.new(0, 80, 0, 24)  -- чуть шире для префикса
    gui.StudsOffset = Vector3.new(0, 2, 0)
    gui.AlwaysOnTop = true
    gui.Parent = part

    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.2
    label.BackgroundColor3 = data.bgColor
    -- Выбираем цвет в зависимости от duped
    if duped then
        label.TextColor3 = data.dupedColor or data.normalColor
    else
        label.TextColor3 = data.normalColor
    end
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold

    local prefix = data.prefix or ""
    label.Text = prefix .. string.format("%.1f", totalLifetime)

    activeTokens[part] = {
        gui = gui,
        label = label,
        startTime = tick(),
        totalLifetime = totalLifetime,
        prefix = prefix,
        duped = duped,
        id = id
    }

    print("➕ Таймер для", data.name, (duped and "(DUPED)" or ""), "на позиции", part.Position)
end

-- Отслеживаем появление новых объектов
Workspace.DescendantAdded:Connect(function(obj)
    local ok, id = isTargetToken(obj)
    if ok then
        createTimer(obj, id)
    end
end)

-- Отслеживаем исчезновение объектов
game.DescendantRemoving:Connect(function(obj)
    if activeTokens[obj] then
        activeTokens[obj].gui:Destroy()
        activeTokens[obj] = nil
    end
end)

-- Обновление таймеров
RunService.Heartbeat:Connect(function()
    local now = tick()
    for part, data in pairs(activeTokens) do
        if part and part.Parent then
            local remaining = data.totalLifetime - (now - data.startTime)
            if remaining > 0 then
                data.label.Text = data.prefix .. string.format("%.1f", remaining)
            else
                data.label.Text = data.prefix .. "0.0"
            end
        else
            if data.gui then data.gui:Destroy() end
            activeTokens[part] = nil
        end
    end
end)

print("✅ Универсальный таймер с префиксами и детектом duped запущен.")
print("🐻 Морфы (MO): обычные - светло-коричневый, дублированные - тёмно-коричневый")
print("✨ Inspire (IN): обычные - жёлтый, дублированные - золотистый")
print("🔗 Token Link (TL): только обычные, белый фон, чёрный текст")
print("⚡ Glitch (SM): 4 сек, белый текст")
print("📈 Уровень Digital Bee:", DIGITAL_BEE_LEVEL, "порог высоты:", DUPED_HEIGHT_THRESHOLD)
print("👉 Дублированные токены (кроме TL) имеют особый цвет и увеличенное время.")
