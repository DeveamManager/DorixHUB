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
local guiHidden = false
local espColor = Color3.fromRGB(255, 0, 0)
local wallbangEnabled = false

-- Создание индикатора "Dorix GUI" для скрытого состояния
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.IgnoreGuiInset = true
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 200, 0, 50)
StatusLabel.Position = UDim2.new(1, -210, 0, 10)
StatusLabel.Text = "Dorix GUI"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextSize = 20
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.Visible = false
StatusLabel.Parent = ScreenGui

local function getClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(targetPart) and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
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
    wallbangEnabled = false
    guiHidden = false
    StatusLabel.Visible = false
    Library:ToggleUI()
    for _, connection in pairs(getconnections(UserInputService.InputBegan)) do
        connection:Disconnect()
    end
    for _, connection in pairs(getconnections(RunService.Heartbeat)) do
        connection:Disconnect()
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local billboard = player.Character:FindFirstChild("ESPBillboard")
            if billboard then billboard:Destroy() end
            local highlight = player.Character:FindFirstChild("Highlight")
            if highlight then highlight:Destroy() end
        end
    end
    ScreenGui:Destroy()
    StarterGui:SetCore("SendNotification", {
        Title = "Dorix GUI",
        Text = "GUI выгружен!",
        Duration = 3
    })
end

local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local head = player.Character:FindFirstChild("Head")
            local billboard = player.Character:FindFirstChild("ESPBillboard")
            local highlight = player.Character:FindFirstChild("Highlight")
            
            if _G.ESP then
                -- Создание Highlight
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Parent = player.Character
                    highlight.FillColor = espColor
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                end
                
                -- Создание BillboardGui для отображения имени
                if head and not billboard then
                    billboard = Instance.new("BillboardGui")
                    billboard.Name = "ESPBillboard"
                    billboard.Adornee = head
                    billboard.Size = UDim2.new(0, 200, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = player.Character
                    
                    local displayNameLabel = Instance.new("TextLabel")
                    displayNameLabel.Size = UDim2.new(1, 0, 0, 25)
                    displayNameLabel.Position = UDim2.new(0, 0, 0, 0)
                    displayNameLabel.Text = player.DisplayName
                    displayNameLabel.TextColor3 = espColor
                    displayNameLabel.BackgroundTransparency = 1
                    displayNameLabel.TextSize = 14
                    displayNameLabel.Font = Enum.Font.SourceSansBold
                    displayNameLabel.Parent = billboard
                    
                    local usernameLabel = Instance.new("TextLabel")
                    usernameLabel.Size = UDim2.new(1, 0, 0, 25)
                    usernameLabel.Position = UDim2.new(0, 0, 0, 25)
                    usernameLabel.Text = "@" .. player.Name
                    usernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    usernameLabel.BackgroundTransparency = 1
                    usernameLabel.TextSize = 12
                    usernameLabel.Font = Enum.Font.SourceSans
                    usernameLabel.Parent = billboard
                end
            else
                if billboard then billboard:Destroy() end
                if highlight then highlight:Destroy() end
            end
        elseif player.Character then
            local billboard = player.Character:FindFirstChild("ESPBillboard")
            if billboard then billboard:Destroy() end
            local highlight = player.Character:FindFirstChild("Highlight")
            if highlight then highlight:Destroy() end
        end
    end
end

-- Wallbang (стрельба через стены)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    if wallbangEnabled and getnamecallmethod() == "FindPartOnRayWithIgnoreList" then
        local ignoreList = args[2]
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide and part ~= LocalPlayer.Character then
                table.insert(ignoreList, part)
            end
        end
        return oldNamecall(self, args[1], ignoreList, unpack(args, 3))
    end
    return oldNamecall(self, ...)
end)

local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Основные функции")

MainSection:NewButton("Активировать GUI", "Открывает стильный интерфейс", function()
    Library:ToggleUI()
    guiHidden = not guiHidden
    StatusLabel.Visible = guiHidden
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
AimSection:NewToggle("Стрельба через стены", "Игнорирует стены при стрельбе", function(state)
    wallbangEnabled = state
    if state then
        print("Стрельба через стены включена")
    else
        print("Стрельба через стены выключена")
    end
end)

local VisualsTab = Window:NewTab("Визуалы")
local VisualsSection = VisualsTab:NewSection("ESP и визуальные эффекты")
VisualsSection:NewToggle("ESP для игроков", "Подсвечивает игроков и показывает имена", function(state)
    _G.ESP = state
    if not state then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local billboard = player.Character:FindFirstChild("ESPBillboard")
                if billboard then billboard:Destroy() end
                local highlight = player.Character:FindFirstChild("Highlight")
                if highlight then highlight:Destroy() end
            end
        end
    end
end)
VisualsSection:NewColorPicker("Цвет ESP", "Изменить цвет подсветки и имени", Color3.fromRGB(255, 0, 0), function(color)
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
        elseif input.KeyCode == Enum.KeyCode.RightShift then
            guiHidden = not guiHidden
            Library:ToggleUI()
            StatusLabel.Visible = guiHidden
        end
    end
end)

RunService.Heartbeat:Connect(aimAtTarget)
RunService.RenderStepped:Connect(updateESP)

StarterGui:SetCore("SendNotification", {
    Title = "Dorix GUI",
    Text = "Dorix GUI с улучшенным ESP (имена) и wallbang загружен!",
    Duration = 3
})
