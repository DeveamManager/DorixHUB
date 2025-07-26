local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Dorix GUI", "DarkTheme")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = game.Workspace.CurrentCamera
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local aimEnabled = false
local targetPart = "Head"
local lockedPlayer = nil
local aimFOV = 100
local aimSmoothness = 0.1
local flyEnabled = false
local flySpeed = 50
local guiVisible = false
local espColor = Color3.fromRGB(255, 0, 0)
local connections = {}

-- Функции
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
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        bodyVelocity.Velocity = moveDirection * flySpeed
        bodyGyro.CFrame = Camera.CFrame
        RunService.Heartbeat:Wait()
    end
    bodyVelocity:Destroy()
    bodyGyro:Destroy()
end

local function unloadGUI()
    _G.ESP = false
    _G.AutoFarm = false
    aimEnabled = false
    flyEnabled = false
    guiVisible = false
    
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("Highlight")
            if highlight then highlight:Destroy() end
        end
    end
    
    pcall(function() Library:Unload() end)
    pcall(function() Window:Destroy() end)
    
    StarterGui:SetCore("SendNotification", {
        Title = "Dorix GUI",
        Text = "GUI выгружен!",
        Duration = 3
    })
end

-- Вкладки
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Основные функции")
MainSection:NewButton("Активировать GUI", "Открывает стильный интерфейс", function()
    Library:ToggleUI()
end)
MainSection:NewButton("Выгрузить", "Выключает скрипт", function()
    unloadGUI()
end)
MainSection:NewToggle("Автофарм денег", "Автоматически собирает деньги", function(state)
    if state then
        _G.AutoFarm = true
        while _G.AutoFarm do
            for _, v in pairs(game:GetService("Workspace").Cashiers:GetChildren()) do
                if v:FindFirstChild("HumanoidRootPart") then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.HumanoidRootPart.CFrame
                    wait(0.5)
                    fireclickdetector(v.ClickDetector)
                end
            end
            wait(1)
        end
    else
        _G.AutoFarm = false
    end
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
                    highlight.FillColor = espColor
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
VisualsSection:NewColorPicker("Цвет ESP", "Изменить цвет подсветки", Color3.fromRGB(255, 0, 0), function(color)
    espColor = color
end)

local MovementTab = Window:NewTab("Движение")
local MovementSection = MovementTab:NewSection("Управление скоростью")
MovementSection:NewSlider("Скорость", "Изменить скорость передвижения", 100, 16, function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end)
MovementSection:NewSlider("Сила прыжка", "Изменить высоту прыжка", 100, 50, function(value)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = value
end)
MovementSection:NewToggle("Полёт", "WASD, Space, Ctrl", function(state)
    flyEnabled = state
    if state then fly() end
end)
MovementSection:NewSlider("Скорость полёта", "Настройка скорости полёта", 200, 10, function(value)
    flySpeed = value
end)

local UIAnimation = Window:NewTab("Настройки UI")
UIAnimation:NewSection("Кастомизация"):NewColorPicker("Цвет интерфейса", "Изменить цвет GUI", Color3.fromRGB(0, 255, 255), function(color)
    Library:ChangeThemeColor(color)
end)

-- Подключение событий
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.Q then
            aimEnabled = not aimEnabled
            if aimEnabled then
                lockedPlayer = getClosestPlayer()
                print("Аимбот включен, цель: " .. (lockedPlayer and lockedPlayer.Name or "Нет цели"))
            else
                lockedPlayer = nil
                print("Аимбот выключен")
            end
        elseif input.KeyCode == Enum.KeyCode.L then
            guiVisible = not guiVisible
            Library:ToggleUI()
        end
    end
end))
table.insert(connections, RunService.Heartbeat:Connect(aimAtTarget))

StarterGui:SetCore("SendNotification", {
    Title = "Dorix GUI",
    Text = "Dorix GUI Loaded successfully! Меню: L",
    Duration = 2
})
