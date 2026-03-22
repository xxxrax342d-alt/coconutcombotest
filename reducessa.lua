-- Скрипт для переключения видимости RewardsPopUp по клавише V
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local isHidden = false  -- состояние: скрыты или видны
local savedStates = {}  -- таблица для хранения сохранённых состояний

-- Функция для рекурсивного поиска и сохранения/восстановления RewardsPopUp в GUI
local function processRewardsPopUpInGUI(guiObject, action)
    if not guiObject then return end
    
    -- Проверяем текущий объект
    if guiObject.Name and guiObject.Name:lower():find("rewards") and guiObject.Name:lower():find("popup") then
        if action == "hide" then
            -- Сохраняем состояние
            if not savedStates[guiObject] then
                savedStates[guiObject] = {
                    isScreenGui = guiObject:IsA("ScreenGui"),
                    enabled = guiObject.Enabled,
                    visible = guiObject.Visible
                }
            end
            -- Скрываем
            if guiObject:IsA("ScreenGui") then
                guiObject.Enabled = false
            else
                guiObject.Visible = false
            end
            print("🔒 Скрыт: " .. guiObject:GetFullName())
        elseif action == "show" then
            -- Восстанавливаем состояние
            if savedStates[guiObject] then
                if savedStates[guiObject].isScreenGui then
                    guiObject.Enabled = savedStates[guiObject].enabled
                else
                    guiObject.Visible = savedStates[guiObject].visible
                end
                print("🔓 Показан: " .. guiObject:GetFullName())
            end
        end
    end
    
    -- Обрабатываем дочерние объекты
    for _, child in ipairs(guiObject:GetChildren()) do
        if child:IsA("GuiObject") or child:IsA("ScreenGui") or child:IsA("Frame") then
            processRewardsPopUpInGUI(child, action)
        end
    end
end

-- Функция для скрытия/показа RewardsPopUp в PlayerGui
local function processRewardsPopUpInPlayerGui(action)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        processRewardsPopUpInGUI(playerGui, action)
        
        -- Также ищем напрямую по имени
        local rewardsPopUp = playerGui:FindFirstChild("RewardsPopUp")
        if rewardsPopUp then
            if action == "hide" then
                if not savedStates[rewardsPopUp] then
                    savedStates[rewardsPopUp] = {
                        isScreenGui = rewardsPopUp:IsA("ScreenGui"),
                        enabled = rewardsPopUp.Enabled,
                        visible = rewardsPopUp.Visible
                    }
                end
                if rewardsPopUp:IsA("ScreenGui") then
                    rewardsPopUp.Enabled = false
                else
                    rewardsPopUp.Visible = false
                end
                print("✅ RewardsPopUp скрыт из PlayerGui")
            elseif action == "show" then
                if savedStates[rewardsPopUp] then
                    if savedStates[rewardsPopUp].isScreenGui then
                        rewardsPopUp.Enabled = savedStates[rewardsPopUp].enabled
                    else
                        rewardsPopUp.Visible = savedStates[rewardsPopUp].visible
                    end
                    print("✅ RewardsPopUp показан в PlayerGui")
                end
            end
        end
        
        -- Ищем похожие названия
        for _, child in ipairs(playerGui:GetChildren()) do
            if child.Name and child.Name:lower():find("rewards") and child.Name:lower():find("popup") then
                if action == "hide" then
                    if not savedStates[child] then
                        savedStates[child] = {
                            isScreenGui = child:IsA("ScreenGui"),
                            enabled = child.Enabled,
                            visible = child.Visible
                        }
                    end
                    if child:IsA("ScreenGui") then
                        child.Enabled = false
                    else
                        child.Visible = false
                    end
                    print("✅ " .. child.Name .. " скрыт из PlayerGui")
                elseif action == "show" then
                    if savedStates[child] then
                        if savedStates[child].isScreenGui then
                            child.Enabled = savedStates[child].enabled
                        else
                            child.Visible = savedStates[child].visible
                        end
                        print("✅ " .. child.Name .. " показан в PlayerGui")
                    end
                end
            end
        end
    end
end

-- Функция для скрытия/показа RewardsPopUp в StarterGui
local function processRewardsPopUpInStarterGui(action)
    local starterGui = game:FindFirstChild("StarterGui")
    if starterGui then
        local rewardsPopUp = starterGui:FindFirstChild("RewardsPopUp")
        if rewardsPopUp then
            if action == "hide" then
                if not savedStates[rewardsPopUp] then
                    savedStates[rewardsPopUp] = {
                        isScreenGui = rewardsPopUp:IsA("ScreenGui"),
                        enabled = rewardsPopUp.Enabled,
                        visible = rewardsPopUp.Visible
                    }
                end
                if rewardsPopUp:IsA("ScreenGui") then
                    rewardsPopUp.Enabled = false
                else
                    rewardsPopUp.Visible = false
                end
                print("✅ RewardsPopUp скрыт из StarterGui")
            elseif action == "show" then
                if savedStates[rewardsPopUp] then
                    if savedStates[rewardsPopUp].isScreenGui then
                        rewardsPopUp.Enabled = savedStates[rewardsPopUp].enabled
                    else
                        rewardsPopUp.Visible = savedStates[rewardsPopUp].visible
                    end
                    print("✅ RewardsPopUp показан в StarterGui")
                end
            end
        end
        
        -- Ищем похожие названия
        for _, child in ipairs(starterGui:GetChildren()) do
            if child.Name and child.Name:lower():find("rewards") and child.Name:lower():find("popup") then
                if action == "hide" then
                    if not savedStates[child] then
                        savedStates[child] = {
                            isScreenGui = child:IsA("ScreenGui"),
                            enabled = child.Enabled,
                            visible = child.Visible
                        }
                    end
                    if child:IsA("ScreenGui") then
                        child.Enabled = false
                    else
                        child.Visible = false
                    end
                    print("✅ " .. child.Name .. " скрыт из StarterGui")
                elseif action == "show" then
                    if savedStates[child] then
                        if savedStates[child].isScreenGui then
                            child.Enabled = savedStates[child].enabled
                        else
                            child.Visible = savedStates[child].visible
                        end
                        print("✅ " .. child.Name .. " показан в StarterGui")
                    end
                end
            end
        end
    end
end

-- Функция для скрытия/показа RewardsPopUp в CoreGui
local function processRewardsPopUpInCoreGui(action)
    local coreGui = game:FindFirstChild("CoreGui")
    if coreGui then
        for _, gui in ipairs(coreGui:GetChildren()) do
            if gui.Name and gui.Name:lower():find("rewards") and gui.Name:lower():find("popup") then
                if gui:IsA("ScreenGui") then
                    if action == "hide" then
                        if not savedStates[gui] then
                            savedStates[gui] = {
                                isScreenGui = true,
                                enabled = gui.Enabled,
                                visible = gui.Visible
                            }
                        end
                        gui.Enabled = false
                        print("✅ " .. gui.Name .. " отключён в CoreGui")
                    elseif action == "show" then
                        if savedStates[gui] then
                            gui.Enabled = savedStates[gui].enabled
                            print("✅ " .. gui.Name .. " включён в CoreGui")
                        end
                    end
                end
            end
        end
    end
end

-- Функция для перехвата новых экземпляров RewardsPopUp
local function setupInterceptor()
    -- Перехват в PlayerGui
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    playerGui.ChildAdded:Connect(function(child)
        if child.Name and child.Name:lower():find("rewards") and child.Name:lower():find("popup") then
            if isHidden then
                if child:IsA("ScreenGui") then
                    child.Enabled = false
                else
                    child.Visible = false
                end
                print("🚫 Перехвачен и скрыт новый: " .. child.Name)
            end
            -- Сохраняем состояние
            if not savedStates[child] then
                savedStates[child] = {
                    isScreenGui = child:IsA("ScreenGui"),
                    enabled = child.Enabled,
                    visible = child.Visible
                }
            end
        end
    end)
    
    -- Перехват в StarterGui
    local starterGui = game:FindFirstChild("StarterGui")
    if starterGui then
        starterGui.ChildAdded:Connect(function(child)
            if child.Name and child.Name:lower():find("rewards") and child.Name:lower():find("popup") then
                if isHidden then
                    if child:IsA("ScreenGui") then
                        child.Enabled = false
                    else
                        child.Visible = false
                    end
                    print("🚫 Перехвачен и скрыт новый в StarterGui: " .. child.Name)
                end
                if not savedStates[child] then
                    savedStates[child] = {
                        isScreenGui = child:IsA("ScreenGui"),
                        enabled = child.Enabled,
                        visible = child.Visible
                    }
                end
            end
        end)
    end
    
    -- Перехват в CoreGui
    local coreGui = game:FindFirstChild("CoreGui")
    if coreGui then
        coreGui.ChildAdded:Connect(function(child)
            if child.Name and child.Name:lower():find("rewards") and child.Name:lower():find("popup") then
                if child:IsA("ScreenGui") and isHidden then
                    child.Enabled = false
                    print("🚫 Перехвачен и отключён новый в CoreGui: " .. child.Name)
                end
                if not savedStates[child] then
                    savedStates[child] = {
                        isScreenGui = true,
                        enabled = child.Enabled,
                        visible = child.Visible
                    }
                end
            end
        end)
    end
end

-- Функция для скрытия всех RewardsPopUp
local function hideAllRewardsPopUp()
    print("🔍 Скрываю все RewardsPopUp...")
    print("--------------------------------------------------")
    
    processRewardsPopUpInPlayerGui("hide")
    processRewardsPopUpInStarterGui("hide")
    processRewardsPopUpInCoreGui("hide")
    
    print("--------------------------------------------------")
    print("✅ Все RewardsPopUp скрыты")
end

-- Функция для показа всех RewardsPopUp
local function showAllRewardsPopUp()
    print("🔍 Показываю все RewardsPopUp...")
    print("--------------------------------------------------")
    
    processRewardsPopUpInPlayerGui("show")
    processRewardsPopUpInStarterGui("show")
    processRewardsPopUpInCoreGui("show")
    
    print("--------------------------------------------------")
    print("✅ Все RewardsPopUp показаны")
end

-- Функция для переключения видимости
local function toggleRewardsPopUp()
    if isHidden then
        showAllRewardsPopUp()
        isHidden = false
    else
        hideAllRewardsPopUp()
        isHidden = true
    end
end

-- Обработчик нажатия клавиши V
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then
        toggleRewardsPopUp()
    end
end)

-- Запускаем перехватчик
setupInterceptor()

print("✅ Скрипт управления RewardsPopUp загружен")
print("📌 Нажмите V, чтобы скрыть/показать все окна наград")
print("💡 Текущее состояние: ВИДНЫ")
