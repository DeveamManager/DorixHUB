local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Dorix GUI", "DarkTheme")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = game.Workspace.CurrentCamera
local RunService = game:GetService("RunService")
local aimEnabled = false
local targetPart = "Head"
local lockedPlayer = nil
local aimFOV = 100
local aimSmoothness = 0.1
local flyEnabled = false
local flySpeed = 50

local function getClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(targetPart) then
            local part = player.Character[targetPart]
            local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if distance < closestDistance and distance < aimFOV then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

local function aimAtTarget()
    if aimEnabled and lockedPlayer and lockedPlayer.Character and lockedPlayer.Character:FindFirstChild(targetPart) then
        local targetPos = lockedPlayer.Character[targetPart].Position
        local currentPos = Camera.CFrame.Position
        local newCFrame = CFrame.new(currentPos, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(newCFrame, aimSmoothness)
    end
end

local function fly()
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart

    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
    bodyGyro.Parent = LocalPlayer.Character.HumanoidRootPart

    while flyEnabled and LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart do
        local moveDirection = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        bodyVelocity.Velocity = moveDirection * flySpeed
        bodyGyro.CFrame = Camera.CFrame
        RunService.Heartbeat:Wait()
    end

    bodyVelocity:Destroy()
    bodyGyro:Destroy()
end

local function unloadGUI()
    _G.ESP = false
    aimEnabled = false
    flyEnabled = false
    Library:ToggleUI()
    for _, connection in pairs(getconnections(UserInputService.InputBegan)) do
        connection:Disconnect()
    end
    for _, connection in pairs(getconnections(RunService.Heartbeat)) do
        connection:Disconnect()
    end
    game.StarterGui:SetCore("SendNotification", {
        Title = "Dorix GUI",
        Text = "GUI выгружен!",
        Duration = 3
    })
end

local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Основные функции")

MainSection:NewButton("Активировать GUI", "Открывает стильный интерфейс", function()
    Library:ToggleUI()
end)

MainSection:NewButton("Выгрузить GUI", "Полностью выгружает скрипт", function()
    unloadGUI()
end)

local AimTab = Window:NewTab("Аимбот")
local AimSection = AimTab:NewSection("Настройки аимбота")
AimSection:NewToggle("Включить аимбот", "Активирует аимбот (клавиша Q)", function(state)
    aimEnabled = state
    if aimEnabled then
        lockedPlayer = getClosestPlayer()
        print("Аимбот включен, цель: " .. (lockedPlayer and lockedPlayer.Name or "Нет цели"))
    else
        lockedPlayer = nil
        print("Аимбот выключен")
    end
end)
AimSection:NewDropdown("Целевая часть", "Выберите часть тела для аима", {"Head", "Torso"}, function(selected)
    targetPart = selected
end)
AimSection:NewSlider("FOV аимбота", "Радиус захвата цели", 300, 50, function(value)
    aimFOV = value
end)
AimSection:NewSlider("Плавность аима", "Настройка плавности (0.1-1)", 1, 0.1, function(value)
    aimSmoothness = value
end)

local TeleportSection = MainTab:NewSection("Телепорты")
TeleportSection:NewDropdown("Выбрать локацию", "Телепорт к ключевым точкам", {"Банк", "Магазин оружия", "Казино"}, function(selected)
    local locations = {
        Bank = CFrame.new(-350, 20, -400),
        GunShop = CFrame.new(-600, 20, -200),
        Casino = CFrame.new(100, 20, 300)
    }
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = locations[selected]
end)

local VisualsTab = Window:NewTab("Визуалы")
local VisualsSection = VisualsTab:NewSection("ESP и визуальные эффекты")
VisualsSection:NewToggle("ESP для игроков", "Подсвечивает игроков", function(state)
    if state then
        _G.ESP = true
        while _G.ESP do
            for _, player in pairs(game.Players:GetPlayers()) do
                if player.Character and player ~= LocalPlayer then
                    local highlight = Instance.new("Highlight")
                    highlight.Parent = player.Character
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                end
            end
            wait(2)
        end
    else
        _G.ESP = false
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Character then
                local highlight = player.Character:FindFirstChild("Highlight")
                if highlight then highlight:Destroy() end
            end
        end
    end
end)

local MovementTab = Window:NewTab("Движение")
local MovementSection = MovementTab:NewSection("Управление скоростью")
MovementSection:NewSlider("Скорость", "Изменить скорость передвижения", 100, 16, function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end)
MovementSection:NewSlider("Сила прыжка", "Изменить высоту прыжка", 100, 50, function(value)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = value
end)
MovementSection:NewToggle("Полёт", "Активирует полёт (WASD, Space, Ctrl)", function(state)
    flyEnabled = state
    if state then
        fly()
    end
end)
MovementSection:NewSlider("Скорость полёта", "Изменить скорость полёта", 200, 10, function(value)
    flySpeed = value
end)

local UIAnimation = Window:NewTab("Настройки UI")
UIAnimation:NewSection("Кастомизация"):NewColorPicker("Цвет интерфейса", "Изменить цвет GUI", Color3.fromRGB(0, 255, 255), function(color)
    Library:ChangeThemeColor(color)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Q then
        aimEnabled = not aimEnabled
        if aimEnabled then
            lockedPlayer = getClosestPlayer()
            print("Аимбот включен, цель: " .. (lockedPlayer and lockedPlayer.Name or "Нет цели"))
        else
            lockedPlayer = nil
            print("Аимбот выключен")
        end
    end
end)

RunService.Heartbeat:Connect(aimAtTarget)

game.StarterGui:SetCore("SendNotification", {
    Title = "Dorix GUI",
    Text = "Dorix GUI с полётом и выгрузкой загружен!",
    Duration = 3
})
