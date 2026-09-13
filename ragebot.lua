local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

for _, obj in pairs(CoreGui:GetChildren()) do
    if obj.Name == "UnidentifiedClientEnhancement" then
        obj:Destroy()
    end
end

local Settings = {
    VoidSpam_Enabled = false,
    VoidSpam_MinBelow = -3,
    VoidSpam_MaxBelow = -2,
    VoidSpam_MinOffset = 1,
    VoidSpam_MaxOffset = 2,
    VoidSpam_ChangeRate = 0.01,
    VoidSpam_MinDelay = 0.053,
    VoidSpam_MaxDelay = 0.127,
    VoidSpam_CurrentDelay = 0.09,

    Teleport_Enabled = false,
    Teleport_Distance = 100,
    Teleport_Height = 10,
    Teleport_StayTime = 0.3,
}

local State = {
    MainPosition = nil,
    TargetName = "None",
    VoidTimer = 0,
    ChangeTimer = 0,
    TeleportTimer = 0,
    IsMenuVisible = true,
    CurrentOffset = Vector3.new(0,0,0),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UnidentifiedClientEnhancement"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Name = "TargetDisplay"
TargetLabel.Size = UDim2.new(0, 240, 0, 32)
TargetLabel.Position = UDim2.new(0.5, -120, 0.5, 45)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "Void Spam : None"
TargetLabel.TextColor3 = Color3.new(1, 1, 1)
TargetLabel.TextSize = 18
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextStrokeTransparency = 0.4
TargetLabel.Visible = false
TargetLabel.Parent = ScreenGui

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 100, 0, 30)
MinimizeButton.Position = UDim2.new(0.5, -50, 0, 10)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
MinimizeButton.Text = "MINIMIZE"
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
MinimizeButton.TextSize = 14
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = ScreenGui

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeButton

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 420)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, 0, 1, 0)
TitleText.BackgroundTransparency = 1
TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "UNIDENTIFIED CLIENT"
TitleText.TextColor3 = Color3.new(1, 1, 1)
TitleText.TextSize = 16
TitleText.Parent = TitleBar

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Position = UDim2.new(0, 8, 0, 54)
ScrollFrame.Size = UDim2.new(1, -16, 1, -58)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 750)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 140)
ScrollFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 14)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Parent = ScrollFrame

MinimizeButton.MouseButton1Click:Connect(function()
    State.IsMenuVisible = not State.IsMenuVisible
    MainFrame.Visible = State.IsMenuVisible
    MinimizeButton.Text = State.IsMenuVisible and "MINIMIZE" or "RESTORE"
end)

local function AddHeader(text, color)
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(0.9, 0, 0, 26)
    Header.BackgroundTransparency = 1
    Header.Font = Enum.Font.GothamBold
    Header.Text = "—— " .. text .. " ——"
    Header.TextColor3 = color
    Header.TextSize = 12
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.Parent = ScrollFrame
end

local function AddToggle(name, settingKey)
    local state = Settings[settingKey]

    local Back = Instance.new("Frame")
    Back.Size = UDim2.new(0.9, 0, 0, 38)
    Back.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Back.BorderSizePixel = 0
    Back.ZIndex = -1
    Back.Parent = ScrollFrame

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Back

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(1, 0, 1, 0)
    Toggle.Position = UDim2.new(0, 0, 0, 0)
    Toggle.BackgroundTransparency = 1
    Toggle.Font = Enum.Font.Gotham
    Toggle.Text = (state and "" or "") .. name
    Toggle.TextColor3 = Color3.new(1, 1, 1)
    Toggle.TextSize = 13
    Toggle.TextXAlignment = Enum.TextXAlignment.Left
    Toggle.Parent = Back

    Toggle.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]

        if settingKey == "VoidSpam_Enabled" then
            if Settings.VoidSpam_Enabled then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    State.MainPosition = char.HumanoidRootPart.Position
                end
                TargetLabel.Visible = true
            else
                State.MainPosition = nil
                State.VoidTimer = 0
                State.ChangeTimer = 0
                TargetLabel.Visible = false
                TargetLabel.Text = "Void Spam : None"
            end
        end

        Toggle.Text = (Settings[settingKey] and "" or "") .. name
    end)
end

local function AddInputField(label, description, settingKey, minVal, maxVal, step, unit)
    unit = unit or ""

    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(0.9, 0, 0, 20)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.Text = description
    DescLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    DescLabel.TextSize = 10
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.Parent = ScrollFrame

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0.9, 0, 0, 20)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Font = Enum.Font.Gotham
    ValueLabel.Text = label .. ": " .. tostring(Settings[settingKey]) .. unit
    ValueLabel.TextColor3 = Color3.new(1, 1, 1)
    ValueLabel.TextSize = 11
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    ValueLabel.Parent = ScrollFrame

    local Back = Instance.new("Frame")
    Back.Size = UDim2.new(0.9, 0, 0, 32)
    Back.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Back.BorderSizePixel = 0
    Back.ZIndex = -1
    Back.Parent = ScrollFrame

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Back

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, -12, 1, 0)
    Input.Position = UDim2.new(0, 6, 0, 0)
    Input.BackgroundTransparency = 1
    Input.Font = Enum.Font.Gotham
    Input.Text = tostring(Settings[settingKey])
    Input.TextColor3 = Color3.new(1, 1, 1)
    Input.TextSize = 13
    Input.TextXAlignment = Enum.TextXAlignment.Left
    Input.ClearTextOnFocus = false
    Input.Parent = Back

    Input.FocusLost:Connect(function()
        local value = tonumber(Input.Text)
        if value then
            value = math.clamp(value, minVal, maxVal)
            value = math.round(value / step) * step
            Settings[settingKey] = value
            ValueLabel.Text = label .. ": " .. tostring(value) .. unit
            Input.Text = tostring(value)
        else
            Input.Text = tostring(Settings[settingKey])
        end
    end)
end

local function GetClosestPlayer()
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil, "None" end

    local closestPlayer = nil
    local closestDistance = math.huge
    local playerName = "None"

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = player.Character:FindFirstChildOfClass("Humanoid")

            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                    playerName = player.Name
                end
            end
        end
    end

    return closestPlayer, playerName
end

local function GetRandomOffset(minDist, maxDist)
    local dist = minDist + math.random() * (maxDist - minDist)
    local angle = math.random() * math.pi * 2
    return Vector3.new(
        math.cos(angle) * dist,
        0,
        math.sin(angle) * dist
    )
end

local function GetBelowOffset(minY, maxY)
    return minY + math.random() * (maxY - minY)
end

local function TeleportToVoid(hrp, targetRoot)
    local belowY = GetBelowOffset(Settings.VoidSpam_MinBelow, Settings.VoidSpam_MaxBelow)
    
    local voidPosition = Vector3.new(
        targetRoot.Position.X + State.CurrentOffset.X,
        targetRoot.Position.Y + belowY,
        targetRoot.Position.Z + State.CurrentOffset.Z
    )

    hrp.CFrame = CFrame.new(voidPosition)
end

local function TeleportToMain(hrp)
    if not State.MainPosition then return end
    hrp.CFrame = CFrame.new(State.MainPosition)
end

local function TeleportToTarget(hrp)
    local targetPlayer, targetName = GetClosestPlayer()
    State.TargetName = targetName
    TargetLabel.Text = "Void Spam : " .. State.TargetName

    if not targetPlayer or not targetPlayer.Character then return end
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local targetPosition = Vector3.new(
        targetRoot.Position.X + State.CurrentOffset.X,
        targetRoot.Position.Y + 1,
        targetRoot.Position.Z + State.CurrentOffset.Z
    )

    hrp.CFrame = CFrame.new(targetPosition)
end

AddHeader("VOID SPAM", Color3.fromRGB(255, 80, 80))
AddToggle("Enable Void Spam", "VoidSpam_Enabled")

AddInputField(
    "Below Enemy (Min)",
    "Minimum studs below enemy when going to void (-3 = 3 studs under)",
    "VoidSpam_MinBelow",
    -5, -1, 0.5, " studs"
)

AddInputField(
    "Below Enemy (Max)",
    "Maximum studs below enemy when going to void (-2 = 2 studs under)",
    "VoidSpam_MaxBelow",
    -5, -1, 0.5, " studs"
)

AddInputField(
    "Horizontal Offset (Min)",
    "Minimum random distance from enemy side (1 stud)",
    "VoidSpam_MinOffset",
    0.5, 5, 0.1, " studs"
)

AddInputField(
    "Horizontal Offset (Max)",
    "Maximum random distance from enemy side (2 studs)",
    "VoidSpam_MaxOffset",
    0.5, 5, 0.1, " studs"
)

AddInputField(
    "Position Change Rate",
    "How often position updates (0.01 = every 10ms)",
    "VoidSpam_ChangeRate",
    0.001, 0.1, 0.001, "s"
)

AddInputField(
    "Loop Speed",
    "Time between each teleport sequence (random 53-127ms)",
    "VoidSpam_CurrentDelay",
    0.053, 0.127, 0.001, "s"
)

AddHeader("TELEPORT", Color3.fromRGB(80, 255, 160))
AddToggle("Enable Teleport", "Teleport_Enabled")

AddInputField(
    "Teleport Distance",
    "How far away from your position you teleport",
    "Teleport_Distance",
    50, 500, 10, " studs"
)

AddInputField(
    "Teleport Height",
    "Height above ground when teleporting",
    "Teleport_Height",
    0, 50, 1, " studs"
)

AddInputField(
    "Stay Time",
    "How long before teleporting again",
    "Teleport_StayTime",
    0.1, 2, 0.1, "s"
)

RunService.RenderStepped:Connect(function(deltaTime)
    local character = LocalPlayer.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not hrp or not humanoid or humanoid.Health <= 0 then return end

    if Settings.VoidSpam_Enabled and State.MainPosition then
        State.VoidTimer += deltaTime
        State.ChangeTimer += deltaTime

        if State.ChangeTimer >= Settings.VoidSpam_ChangeRate then
            State.ChangeTimer = 0
            State.CurrentOffset = GetRandomOffset(Settings.VoidSpam_MinOffset, Settings.VoidSpam_MaxOffset)
        end

        if State.VoidTimer >= Settings.VoidSpam_CurrentDelay then
            State.VoidTimer = 0
            Settings.VoidSpam_CurrentDelay = math.random() * (Settings.VoidSpam_MaxDelay - Settings.VoidSpam_MinDelay) + Settings.VoidSpam_MinDelay

            local targetPlayer = GetClosestPlayer()
            if targetPlayer and targetPlayer.Character then
                local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    TeleportToVoid(hrp, targetRoot)
                    task.wait(0.01)
                    TeleportToMain(hrp)
                    task.wait(0.01)
                    TeleportToTarget(hrp)
                end
            end
        end
    end

    if Settings.Teleport_Enabled then
        State.TeleportTimer += deltaTime
        if State.TeleportTimer >= Settings.Teleport_StayTime then
            State.TeleportTimer = 0

            local randomDir = Vector3.new(
                math.random(-100, 100) / 100,
                0,
                math.random(-100, 100) / 100
            ).Unit

            local newPosition = hrp.Position + randomDir * Settings.Teleport_Distance
            newPosition = Vector3.new(
                newPosition.X,
                newPosition.Y + Settings.Teleport_Height,
                newPosition.Z
            )

            hrp.CFrame = CFrame.new(newPosition)
        end
    end
end)
