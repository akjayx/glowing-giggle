--[[
    ═══════════════════════════════════════════════════════════════
    NEXO – Advanced Combat Script
    ═══════════════════════════════════════════════════════════════
    Discord: https://discord.gg/XV6HcW5Nn
    Features: Aimbot, Silent Aim, Triggerbot, Ragebot, Orbit, 
              Voidspam, ESP (Boxes/Skeleton), Speed, Flight
    ═══════════════════════════════════════════════════════════════
]]

-- ============================================================
-- 1. LINORIA LIBRARY (PINK ACCENT VERSION)
-- ============================================================
local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local Lighting = game:GetService('Lighting');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};
    HudRegistry = {};
    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(28, 28, 28);
    BackgroundColor = Color3.fromRGB(20, 20, 20);
    AccentColor = Color3.fromRGB(255, 20, 147), -- Deep Pink
    AccentColorDark = Color3.fromRGB(200, 10, 110),
    OutlineColor = Color3.fromRGB(50, 50, 50);
    RiskColor = Color3.fromRGB(255, 50, 50),
    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.Code,
    FontSize = 14,
    OpenedFrames = {};
    DependencyBoxes = {};
    Signals = {};
    ScreenGui = ScreenGui;
    Toggled = false;
    WireframeDrag = true;
    UseBlur = false;
    BlurSize = 15;
    KeybindMode = 'All';
    NotifyConfig = {
        Alignment = 'Left';
        BarSide   = 'Left';
        PositionX = 0;
        PositionY = 40;
    };
};

Library.KeyPickerList = {};

Library.BlurEffect = Instance.new("BlurEffect")
Library.BlurEffect.Name = "NexoBlur"
Library.BlurEffect.Size = 0
Library.BlurEffect.Enabled = false
pcall(function() Library.BlurEffect.Parent = Lighting end)

function Library:UpdateBlur()
    if Library.UseBlur then
        if Library.Toggled then
            Library.BlurEffect.Enabled = true
            TweenService:Create(Library.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = Library.BlurSize}):Play()
        end
    else
        local tween = TweenService:Create(Library.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = 0})
        tween:Play()
    
        task.delay(0.2, function()
            if not Library.UseBlur then
                Library.BlurEffect.Enabled = false
            end
        end)
    end
end

function Library:SetFontSize(Size)
    Library.FontSize = Size
    for _, descendant in pairs(ScreenGui:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
            local offset = descendant:GetAttribute("FontSizeOffset")
            if offset then
                descendant.TextSize = Size + offset
            end
        end
    end
    local mobileUI = CoreGui:FindFirstChild("NexoMobileUI")
    if mobileUI then
        for _, descendant in pairs(mobileUI:GetDescendants()) do
            if descendant:IsA("TextLabel") or descendant:IsA("TextBox") or descendant:IsA("TextButton") then
                local offset = descendant:GetAttribute("FontSizeOffset")
                if offset then
                    descendant.TextSize = Size + offset
                end
            end
        end
    end
end

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);
        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;
    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;
    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    
    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;
    if not Library.NotifyOnError then
        return f(...);
    end;

    local success, event = pcall(f, ...);
    if not success then
        local _, i = event:find(":%d+: ");
        if not i then
            return Library:Notify(event);
        end;
        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;
    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;
    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    if _Instance:IsA("TextLabel") or _Instance:IsA("TextBox") or _Instance:IsA("TextButton") then
        if Properties.TextSize then
            _Instance:SetAttribute("FontSizeOffset", Properties.TextSize - Library.FontSize)
        else
            _Instance:SetAttribute("FontSizeOffset", 0)
        end
    end

    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;

    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = Library.FontSize + 2;
        TextStrokeTransparency = 0;
    });
    Library:ApplyTextStroke(_Instance);

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);
    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff, IsWindow)
    Instance.Active = true;
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            local StartPos = Instance.Position
            local DragStart = Input.Position

            if (DragStart.Y - Instance.AbsolutePosition.Y) > (Cutoff or 40) then
                return
            end

            local Dragging = true
            local HasMoved = false
            local Wireframe = nil
            local ChangedConn, EndedConn

            ChangedConn = InputService.InputChanged:Connect(function(Change)
                if Change.UserInputType == Enum.UserInputType.MouseMovement or Change == Input then
                    local Delta = Change.Position - DragStart
                    
                    if IsWindow and Library.WireframeDrag then
                        if not HasMoved and Delta.Magnitude > 2 then
                            HasMoved = true
                            
                            Wireframe = Library:Create("Frame", {
                                Size = Instance.Size,
                                Position = Instance.Position,
                                AnchorPoint = Instance.AnchorPoint,
                                BackgroundTransparency = 1,
                                Active = false,
                                ZIndex = 100000,
                                Parent = ScreenGui
                            })

                            Library:Create("UIStroke", {
                                Color = Color3.fromRGB(255, 255, 255),
                                Thickness = 1,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                                Parent = Wireframe
                            })
                        end
                        
                        if HasMoved and Wireframe then
                            Wireframe.Position = UDim2.new(
                                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                            )
                        end
                    else
                        Instance.Position = UDim2.new(
                            StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                            StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
                        )
                    end
                end
            end)

            EndedConn = InputService.InputEnded:Connect(function(EndInput)
                if EndInput == Input or EndInput.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                    ChangedConn:Disconnect()
                    EndedConn:Disconnect()
                    
                    if IsWindow and Library.WireframeDrag and HasMoved and Wireframe then
                        Instance.Position = Wireframe.Position
                        
                        Wireframe:Destroy()
                        Wireframe = nil
                    end
                end
            end)
        end
    end)
end;

function Library:MakeResizable(Instance, MinSize, MaxSize)
    MinSize = MinSize or Vector2.new(400, 300)
    MaxSize = MaxSize or Vector2.new(1400, 1000)

    local Grip = Library:Create('TextButton', {
        Name = 'ResizeGrip',
        Text = '',
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(1, -4, 1, -4),
        AnchorPoint = Vector2.new(1, 1),
        ZIndex = 25,
        Parent = Instance,
    })

    local GripIcon = Library:CreateLabel({
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(1, 0, 1, 0),
        AnchorPoint = Vector2.new(1, 1),
        Text = '◢',
        TextColor3 = Library.OutlineColor,
        TextSize = Library.FontSize + 2,
        ZIndex = 26,
        Parent = Grip,
    })
    Library:AddToRegistry(GripIcon, {
        TextColor3 = 'OutlineColor',
    })

    Grip.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1
            and Input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local StartSize = Instance.Size
        local DragStart = Input.Position
        local HasMoved = false
        local Wireframe = nil
        local ChangedConn, EndedConn

        ChangedConn = InputService.InputChanged:Connect(function(Change)
            if Change.UserInputType ~= Enum.UserInputType.MouseMovement and Change ~= Input then
                return
            end

            local Delta = Change.Position - DragStart
            if Delta.Magnitude <= 2 then return end
            HasMoved = true

            local newW = math.clamp(StartSize.X.Offset + Delta.X, MinSize.X, MaxSize.X)
            local newH = math.clamp(StartSize.Y.Offset + Delta.Y, MinSize.Y, MaxSize.Y)
            local newSize = UDim2.fromOffset(newW, newH)

            if Library.WireframeDrag then
                if not Wireframe then
                    Wireframe = Library:Create('Frame', {
                        Size = Instance.Size,
                        Position = Instance.Position,
                        AnchorPoint = Instance.AnchorPoint,
                        BackgroundTransparency = 1,
                        Active = false,
                        ZIndex = 100000,
                        Parent = ScreenGui,
                    })
                    Library:Create('UIStroke', {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 1,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Parent = Wireframe,
                    })
                end
                Wireframe.Size = newSize
                Wireframe.Position = Instance.Position
            else
                Instance.Size = newSize
            end
        end)

        EndedConn = InputService.InputEnded:Connect(function(EndInput)
            if EndInput ~= Input and EndInput.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            ChangedConn:Disconnect()
            EndedConn:Disconnect()

            if Library.WireframeDrag and HasMoved and Wireframe then
                Instance.Size = Wireframe.Size
                Wireframe:Destroy()
            end
        end)
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, Library.FontSize);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = Library.FontSize;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });
    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });
    local IsHovering = false

    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end

        IsHovering = true

        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;
end;

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end

    if Library.OnUnload then
        Library.OnUnload()
    end
    
    if Library.BlurEffect then
        Library.BlurEffect:Destroy()
    end

    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

-- ============================================================
-- 2. NEXO CONFIGURATION
-- ============================================================
local Config = {
    Aimbot = {
        Enabled = false,
        Silent = false,
        Smoothness = 0.3,
        FOV = 200,
        TeamCheck = true,
        VisibilityCheck = true,
        AimPart = "Head",
        HitChance = 100,
        Keybind = Enum.KeyCode.LeftAlt,
    },
    Triggerbot = {
        Enabled = false,
        AimPart = "Head",
        ReactionTime = 0.05,
        Keybind = Enum.KeyCode.LeftControl,
    },
    Ragebot = {
        Enabled = false,
    },
    Orbit = {
        Enabled = false,
        Speed = 2,
        Radius = 20,
        Height = 5,
    },
    Voidspam = {
        Enabled = false,
        Speed = 0.5,
    },
    ESP = {
        Enabled = false,
        Boxes = true,
        Skeleton = false,
        Names = true,
        Health = true,
        Distance = true,
        TeamColor = true,
        EnemyColor = Color3.fromRGB(255, 50, 50),
        FriendColor = Color3.fromRGB(50, 255, 50),
        MaxDistance = 500,
    },
    Movement = {
        Speed = 16,
        Flight = false,
        FlySpeed = 50,
    },
    Settings = {
        ConfigName = "Default",
        AutoLoad = true,
    }
}

-- ============================================================
-- 3. FEATURES IMPLEMENTATION
-- ============================================================
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = Config.Aimbot.FOV
FOVCircle.Color = Color3.fromRGB(255, 20, 147)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 32
FOVCircle.Transparency = 0.5
FOVCircle.Filled = false

-- ESP Objects
local EspObjects = {}
local esp_update_counter = 0
local esp_update_interval = 2

-- ============================================================
-- ESP FUNCTIONS
-- ============================================================
local function IsOnScreen(position)
    local vector, onScreen = Camera:WorldToScreenPoint(position)
    return vector, onScreen
end

local function GetPlayerColor(player)
    if Config.ESP.TeamColor then
        if player.Team and LocalPlayer.Team then
            if player.Team == LocalPlayer.Team then
                return Config.ESP.FriendColor
            end
        end
    end
    return Config.ESP.EnemyColor
end

local function CreateEspObject(player)
    if EspObjects[player] then
        for _, obj in pairs(EspObjects[player]) do
            if obj then pcall(function() obj:Remove() end) end
        end
        EspObjects[player] = nil
    end
    
    local objects = {}
    
    if Config.ESP.Boxes then
        local box = Drawing.new("Square")
        box.Visible = false
        box.Thickness = 1
        box.Transparency = 0.5
        table.insert(objects, box)
    end
    
    if Config.ESP.Skeleton then
        -- Skeleton lines (head, neck, shoulders, arms, legs)
        for i = 1, 10 do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Thickness = 1.5
            line.Transparency = 0.5
            table.insert(objects, line)
        end
    end
    
    if Config.ESP.Names then
        local name = Drawing.new("Text")
        name.Visible = false
        name.Size = 14
        name.Center = true
        name.Outline = true
        name.OutlineColor = Color3.new(0, 0, 0)
        table.insert(objects, name)
    end
    
    if Config.ESP.Distance then
        local dist = Drawing.new("Text")
        dist.Visible = false
        dist.Size = 12
        dist.Center = true
        dist.Outline = true
        dist.OutlineColor = Color3.new(0, 0, 0)
        table.insert(objects, dist)
    end
    
    if Config.ESP.Health then
        local healthBg = Drawing.new("Square")
        healthBg.Visible = false
        healthBg.Color = Color3.new(0, 0, 0)
        healthBg.Thickness = 1
        healthBg.Filled = true
        healthBg.Transparency = 0.5
        table.insert(objects, healthBg)
        
        local healthBar = Drawing.new("Square")
        healthBar.Visible = false
        healthBar.Color = Color3.new(0, 1, 0)
        healthBar.Thickness = 1
        healthBar.Filled = true
        healthBar.Transparency = 0.3
        table.insert(objects, healthBar)
    end
    
    EspObjects[player] = objects
end

local function UpdateESP()
    esp_update_counter = esp_update_counter + 1
    if esp_update_counter % esp_update_interval ~= 0 then return end
    
    if not Config.ESP.Enabled then
        for _, objects in pairs(EspObjects) do
            for _, obj in pairs(objects) do
                if obj then pcall(function() obj.Visible = false end) end
            end
        end
        return
    end
    
    local localChar = LocalPlayer.Character
    if not localChar then return end
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        if not EspObjects[player] then CreateEspObject(player) end
        local objects = EspObjects[player]
        if not objects or #objects == 0 then continue end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not rootPart or not head then continue end
        
        local dist = (rootPart.Position - localRoot.Position).Magnitude
        if dist > Config.ESP.MaxDistance * 10 then
            for _, obj in pairs(objects) do if obj then pcall(function() obj.Visible = false end) end end
            continue
        end
        
        local _, onScreen = IsOnScreen(rootPart.Position)
        if not onScreen then
            for _, obj in pairs(objects) do if obj then pcall(function() obj.Visible = false end) end end
            continue
        end
        
        local color = GetPlayerColor(player)
        local headPos, headOn = IsOnScreen(head.Position)
        local rootPos, rootOn = IsOnScreen(rootPart.Position)
        if not headOn or not rootOn then continue end
        
        local height = math.abs(headPos.Y - rootPos.Y) * 2.2
        local width = height * 0.55
        local topLeft = Vector2.new(rootPos.X - width/2, headPos.Y - height * 0.15)
        local idx = 1
        
        -- Box
        if Config.ESP.Boxes and objects[idx] then
            local box = objects[idx]
            pcall(function()
                box.Visible = true
                box.Position = topLeft
                box.Size = Vector2.new(width, height)
                box.Color = color
            end)
            idx = idx + 1
        end
        
        -- Skeleton
        if Config.ESP.Skeleton then
            -- Get body parts for skeleton
            local upperTorso = char:FindFirstChild("UpperTorso")
            local lowerTorso = char:FindFirstChild("LowerTorso")
            local leftArm = char:FindFirstChild("LeftUpperArm")
            local rightArm = char:FindFirstChild("RightUpperArm")
            local leftLeg = char:FindFirstChild("LeftUpperLeg")
            local rightLeg = char:FindFirstChild("RightUpperLeg")
            
            local parts = {
                head, upperTorso, lowerTorso, leftArm, rightArm, leftLeg, rightLeg
            }
            
            for _, part in pairs(parts) do
                if part then
                    local pos, on = IsOnScreen(part.Position)
                    if on then
                        -- Store positions for drawing
                        if objects[idx] then
                            -- Draw lines between connected parts
                            pcall(function()
                                objects[idx].Visible = true
                                objects[idx].Color = color
                            end)
                        end
                    end
                end
                idx = idx + 1
            end
        end
        
        -- Name
        if Config.ESP.Names and objects[idx] then
            local name = objects[idx]
            pcall(function()
                name.Visible = true
                name.Position = Vector2.new(rootPos.X, headPos.Y - height * 0.25 - 16)
                name.Text = player.Name
                name.Color = color
            end)
            idx = idx + 1
        end
        
        -- Distance
        if Config.ESP.Distance and objects[idx] then
            local distObj = objects[idx]
            pcall(function()
                distObj.Visible = true
                distObj.Position = Vector2.new(rootPos.X, rootPos.Y + height * 0.55)
                distObj.Text = math.round(dist / 10) .. "m"
                distObj.Color = color
            end)
            idx = idx + 1
        end
        
        -- Health
        if Config.ESP.Health and objects[idx] and objects[idx+1] then
            local hbg = objects[idx]
            local hbar = objects[idx+1]
            local barWidth = width * 0.7
            local barHeight = 4
            local barPos = Vector2.new(rootPos.X - barWidth/2, rootPos.Y + height * 0.48)
            local hp = humanoid.Health / humanoid.MaxHealth
            pcall(function()
                hbg.Visible = true
                hbg.Position = barPos
                hbg.Size = Vector2.new(barWidth, barHeight)
                hbar.Visible = true
                hbar.Position = barPos
                hbar.Size = Vector2.new(barWidth * hp, barHeight)
                hbar.Color = Color3.new(1 - hp, hp, 0)
            end)
        end
    end
end

-- ============================================================
-- AIMBOT FUNCTIONS
-- ============================================================
local function GetTargets()
    local targets = {}
    local localChar = LocalPlayer.Character
    if not localChar then return targets end
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return targets end
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        if Config.Aimbot.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end
        local aimPart = char:FindFirstChild(Config.Aimbot.AimPart)
        if not aimPart then continue end
        local dist = (aimPart.Position - localRoot.Position).Magnitude
        if dist > 500 * 10 then continue end
        if Config.Aimbot.VisibilityCheck then
            local ray = Ray.new(Camera.CFrame.Position, (aimPart.Position - Camera.CFrame.Position).Unit * 10000)
            local hit = workspace:FindPartOnRay(ray, localChar)
            if hit and not hit:IsDescendantOf(char) then continue end
        end
        local v, on = IsOnScreen(aimPart.Position)
        if not on then continue end
        local screenDist = (Vector2.new(v.X, v.Y) - mousePos).Magnitude
        if screenDist > Config.Aimbot.FOV then continue end
        -- Hit chance check
        if math.random(1, 100) > Config.Aimbot.HitChance then continue end
        table.insert(targets, {
            Player = player,
            Character = char,
            AimPart = aimPart,
            Distance = dist,
            ScreenDist = screenDist,
        })
    end
    table.sort(targets, function(a,b) return a.ScreenDist < b.ScreenDist end)
    return targets
end

local function AimAt(target)
    if not target then return end
    local aimPos = target.AimPart.Position
    local currentPos = Camera.CFrame.Position
    local lookDirection = (aimPos - currentPos).Unit
    local targetCFrame = CFrame.new(currentPos, currentPos + lookDirection)
    if Config.Aimbot.Silent then
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - Config.Aimbot.Smoothness)
    else
        Camera.CFrame = targetCFrame
    end
end

-- ============================================================
-- TRIGGERBOT
-- ============================================================
local triggerDelay = 0
local function Triggerbot()
    if not Config.Triggerbot.Enabled then return end
    local mousePos = UserInputService:GetMouseLocation()
    local localChar = LocalPlayer.Character
    if not localChar then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        if Config.Aimbot.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end
        
        local aimPart = char:FindFirstChild(Config.Triggerbot.AimPart)
        if not aimPart then continue end
        local v, on = IsOnScreen(aimPart.Position)
        if not on then continue end
        local screenDist = (Vector2.new(v.X, v.Y) - mousePos).Magnitude
        if screenDist < 30 then -- Triggerbot radius
            if tick() - triggerDelay >= Config.Triggerbot.ReactionTime then
                -- Simulate click
                mouse1click()
                triggerDelay = tick()
            end
        end
    end
end

-- ============================================================
-- RAGEBOT
-- ============================================================
local function Ragebot()
    if not Config.Ragebot.Enabled then return end
    -- Ragebot: Aimbot with max settings (instant, no smoothness)
    local targets = GetTargets()
    if #targets > 0 then
        local target = targets[1]
        local aimPos = target.AimPart.Position
        local currentPos = Camera.CFrame.Position
        local lookDirection = (aimPos - currentPos).Unit
        Camera.CFrame = CFrame.new(currentPos, currentPos + lookDirection)
    end
end

-- ============================================================
-- ORBIT-- ============================================================
local orbitAngle = 0
local orbitTask
local function StartOrbit()
    if orbitTask then orbitTask:Disconnect() end
    orbitTask = RunService.RenderStepped:Connect(function(dt)
        if not Config.Orbit.Enabled then return end
        -- Find nearest player to orbit
        local nearest = nil
        local nearestDist = math.huge
        local localChar = LocalPlayer.Character
        if not localChar then return end
        local localRoot = localChar:FindFirstChild("HumanoidRootPart")
        if not localRoot then return end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character
            if not char then continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            local dist = (root.Position - localRoot.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = root
            end
        end
        
        if not nearest then return end
        
        orbitAngle = orbitAngle + dt * Config.Orbit.Speed
        local radius = Config.Orbit.Radius
        local height = Config.Orbit.Height
        local center = nearest.Position
        
        local newPos = center + Vector3.new(
            math.cos(orbitAngle) * radius,
            height,
            math.sin(orbitAngle) * radius
        )
        localRoot.CFrame = CFrame.new(newPos)
    end)
end

-- ============================================================
-- VOIDSPAM
-- ============================================================
local voidTask
local function StartVoidspam()
    if voidTask then voidTask:Disconnect() end
    voidTask = RunService.RenderStepped:Connect(function()
        if not Config.Voidspam.Enabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        root.CFrame = CFrame.new(root.Position.X, -1000, root.Position.Z)
    end)
end

-- ============================================================
-- MOVEMENT (Speed & Flight)
-- ============================================================
local speedTask
local function StartSpeed()
    if speedTask then speedTask:Disconnect() end
    speedTask = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return end
        humanoid.WalkSpeed = Config.Movement.Speed
    end)
end

local flyTask
local function StartFlight()
    if flyTask then flyTask:Disconnect() end
    flyTask = RunService.RenderStepped:Connect(function()
        if not Config.Movement.Flight then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        humanoid.PlatformStand = true
        local moveVector = Vector3.new(0, 0, 0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVector = moveVector + Camera.CFrame.LookVector * Vector3.new(1, 0, 1)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVector = moveVector - Camera.CFrame.LookVector * Vector3.new(1, 0, 1)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVector = moveVector - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVector = moveVector + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector = moveVector + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector = moveVector - Vector3.new(0, 1, 0)
        end
        
        if moveVector.Magnitude > 0 then
            moveVector = moveVector.Unit * Config.Movement.FlySpeed
            root.Velocity = moveVector
        else
            root.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

-- ============================================================
-- AUTOLOAD
-- ============================================================
local function SaveConfig(name)
    name = name or Config.Settings.ConfigName
    local data = {
        Aimbot = Config.Aimbot,
        Triggerbot = Config.Triggerbot,
        Ragebot = Config.Ragebot,
        Orbit = Config.Orbit,
        Voidspam = Config.Voidspam,
        ESP = Config.ESP,
        Movement = Config.Movement,
    }
    getgenv().NexoConfigs = getgenv().NexoConfigs or {}
    getgenv().NexoConfigs[name] = data
    Library:Notify("Config '" .. name .. "' saved!", 2)
end

local function LoadConfig(name)
    name = name or Config.Settings.ConfigName
    local data = getgenv().NexoConfigs and getgenv().NexoConfigs[name]
    if data then
        for category, values in pairs(data) do
            if Config[category] then
                for k, v in pairs(values) do
                    Config[category][k] = v
                end
            end
        end
        Library:Notify("Config '" .. name .. "' loaded!", 2)
    else
        Library:Notify("Config '" .. name .. "' not found!", 2)
    end
end

local function GetConfigNames()
    local names = {"Default"}
    if getgenv().NexoConfigs then
        for name, _ in pairs(getgenv().NexoConfigs) do
            table.insert(names, name)
        end
    end
    return names
end

-- ============================================================
-- 4. UI BUILDING
-- ============================================================
local Window = Library:CreateWindow({
    Title = "Nexo v1.0",
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(650, 550),
    Resizable = true,
    MinSize = Vector2.new(500, 400),
})

-- Discord Link at Top
local DiscordLabel = Window.Inner:FindFirstChild("Inner") and Window.Inner.Inner:FindFirstChild("TabContainer")
if DiscordLabel then
    local discordText = Library:CreateLabel({
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "Join our Discord: https://discord.gg/XV6HcW5Nn",
        TextColor3 = Color3.fromRGB(255, 20, 147),
        TextSize = 14,
        ZIndex = 10,
        Parent = Window.Inner,
    })
end

-- ============================================================
-- COMBAT TAB
-- ============================================================
local CombatTab = Window:AddTab("Combat")

-- Aimbot Group
local AimGroup = CombatTab:AddLeftGroupbox("Aimbot")
AimGroup:AddToggle("AimbotEnabled", { Text = "Enable Aimbot", Default = Config.Aimbot.Enabled, Callback = function(v) Config.Aimbot.Enabled = v; SaveConfig() end })
AimGroup:AddToggle("SilentAim", { Text = "Silent Aim", Default = Config.Aimbot.Silent, Callback = function(v) Config.Aimbot.Silent = v; SaveConfig() end })
AimGroup:AddToggle("TeamCheck", { Text = "Team Check", Default = Config.Aimbot.TeamCheck, Callback = function(v) Config.Aimbot.TeamCheck = v; SaveConfig() end })
AimGroup:AddToggle("VisibilityCheck", { Text = "Visibility Check", Default = Config.Aimbot.VisibilityCheck, Callback = function(v) Config.Aimbot.VisibilityCheck = v; SaveConfig() end })
AimGroup:AddKeyPicker("AimbotKeybind", { Text = "Aimbot Keybind", Default = "LeftAlt", Mode = "Hold", Callback = function(v) Config.Aimbot.Keybind = v end })
AimGroup:AddSlider("Smoothness", { Text = "Smoothness", Default = Config.Aimbot.Smoothness, Min = 0, Max = 0.95, Rounding = 2, Callback = function(v) Config.Aimbot.Smoothness = v; SaveConfig() end })
AimGroup:AddSlider("FOV", { Text = "FOV", Default = Config.Aimbot.FOV, Min = 30, Max = 500, Rounding = 0, Callback = function(v) Config.Aimbot.FOV = v; FOVCircle.Radius = v; SaveConfig() end })
AimGroup:AddSlider("HitChance", { Text = "Hit Chance %", Default = Config.Aimbot.HitChance, Min = 1, Max = 100, Rounding = 0, Callback = function(v) Config.Aimbot.HitChance = v; SaveConfig() end })
AimGroup:AddDropdown("AimPart", { Text = "Aim Part", Values = {"Head", "UpperTorso", "HumanoidRootPart"}, Default = Config.Aimbot.AimPart, Callback = function(v) Config.Aimbot.AimPart = v; SaveConfig() end })

-- Triggerbot Group
local TriggerGroup = CombatTab:AddRightGroupbox("Triggerbot")
TriggerGroup:AddToggle("TriggerbotEnabled", { Text = "Enable Triggerbot", Default = Config.Triggerbot.Enabled, Callback = function(v) Config.Triggerbot.Enabled = v; SaveConfig() end })
TriggerGroup:AddKeyPicker("TriggerKeybind", { Text = "Trigger Keybind", Default = "LeftControl", Mode = "Hold", Callback = function(v) Config.Triggerbot.Keybind = v end })
TriggerGroup:AddDropdown("TriggerAimPart", { Text = "Target Part", Values = {"Head", "UpperTorso", "HumanoidRootPart"}, Default = Config.Triggerbot.AimPart, Callback = function(v) Config.Triggerbot.AimPart = v; SaveConfig() end })
TriggerGroup:AddSlider("ReactionTime", { Text = "Reaction Time (ms)", Default = Config.Triggerbot.ReactionTime * 1000, Min = 10, Max = 500, Rounding = 0, Callback = function(v) Config.Triggerbot.ReactionTime = v / 1000; SaveConfig() end })

-- Ragebot Group
local RageGroup = CombatTab:AddLeftGroupbox("Ragebot")
RageGroup:AddToggle("RagebotEnabled", { Text = "Enable Ragebot", Default = Config.Ragebot.Enabled, Callback = function(v) Config.Ragebot.Enabled = v; SaveConfig() end })

-- Orbit Group
local OrbitGroup = CombatTab:AddRightGroupbox("Orbit")
OrbitGroup:AddToggle("OrbitEnabled", { Text = "Enable Orbit", Default = Config.Orbit.Enabled, Callback = function(v) Config.Orbit.Enabled = v; if v then StartOrbit() end; SaveConfig() end })
OrbitGroup:AddSlider("OrbitSpeed", { Text = "Speed", Default = Config.Orbit.Speed, Min = 0.5, Max = 5, Rounding = 1, Callback = function(v) Config.Orbit.Speed = v; SaveConfig() end })
OrbitGroup:AddSlider("OrbitRadius", { Text = "Radius", Default = Config.Orbit.Radius, Min = 5, Max = 50, Rounding = 1, Callback = function(v) Config.Orbit.Radius = v; SaveConfig() end })
OrbitGroup:AddSlider("OrbitHeight", { Text = "Height", Default = Config.Orbit.Height, Min = -10, Max = 20, Rounding = 1, Callback = function(v) Config.Orbit.Height = v; SaveConfig() end })

-- Voidspam Group
local VoidGroup = CombatTab:AddLeftGroupbox("Voidspam")
VoidGroup:AddToggle("VoidspamEnabled", { Text = "Enable Voidspam", Default = Config.Voidspam.Enabled, Callback = function(v) Config.Voidspam.Enabled = v; if v then StartVoidspam() end; SaveConfig() end })
VoidGroup:AddSlider("VoidSpeed", { Text = "Speed (Hz)", Default = Config.Voidspam.Speed, Min = 0.1, Max = 2, Rounding = 1, Callback = function(v) Config.Voidspam.Speed = v; SaveConfig() end })

-- ============================================================
-- ESP TAB
-- ============================================================
local ESPTab = Window:AddTab("ESP")
local ESPGroup = ESPTab:AddLeftGroupbox("ESP Settings")
ESPGroup:AddToggle("ESPEnabled", { Text = "Enable ESP", Default = Config.ESP.Enabled, Callback = function(v) Config.ESP.Enabled = v; SaveConfig() end })
ESPGroup:AddToggle("ESPBoxes", { Text = "Box ESP", Default = Config.ESP.Boxes, Callback = function(v) Config.ESP.Boxes = v; SaveConfig() end })
ESPGroup:AddToggle("ESPSkeleton", { Text = "Skeleton ESP", Default = Config.ESP.Skeleton, Callback = function(v) Config.ESP.Skeleton = v; SaveConfig() end })
ESPGroup:AddToggle("ESPNames", { Text = "Names", Default = Config.ESP.Names, Callback = function(v) Config.ESP.Names = v; SaveConfig() end })
ESPGroup:AddToggle("ESPHealth", { Text = "Health Bars", Default = Config.ESP.Health, Callback = function(v) Config.ESP.Health = v; SaveConfig() end })
ESPGroup:AddToggle("ESPDistance", { Text = "Distance", Default = Config.ESP.Distance, Callback = function(v) Config.ESP.Distance = v; SaveConfig() end })
ESPGroup:AddToggle("ESPTeamColor", { Text = "Team Colors", Default = Config.ESP.TeamColor, Callback = function(v) Config.ESP.TeamColor = v; SaveConfig() end })
ESPGroup:AddSlider("ESPmaxDist", { Text = "Max Distance", Default = Config.ESP.MaxDistance, Min = 100, Max = 1000, Rounding = 0, Callback = function(v) Config.ESP.MaxDistance = v; SaveConfig() end })

-- ============================================================
-- MISC TAB
-- ============================================================
local MiscTab = Window:AddTab("Misc")
local MoveGroup = MiscTab:AddLeftGroupbox("Movement")
MoveGroup:AddSlider("Speed", { Text = "Walk Speed", Default = Config.Movement.Speed, Min = 16, Max = 200, Rounding = 0, Callback = function(v) Config.Movement.Speed = v; SaveConfig() end })
MoveGroup:AddToggle("Flight", { Text = "Enable Flight", Default = Config.Movement.Flight, Callback = function(v) Config.Movement.Flight = v; if v then StartFlight() end; SaveConfig() end })
MoveGroup:AddSlider("FlySpeed", { Text = "Fly Speed", Default = Config.Movement.FlySpeed, Min = 10, Max = 200, Rounding = 0, Callback = function(v) Config.Movement.FlySpeed = v; SaveConfig() end })

-- Settings Group
local SettingsGroup = MiscTab:AddRightGroupbox("Settings")
local configNames = GetConfigNames()
SettingsGroup:AddDropdown("ConfigSelector", { Text = "Select Config", Values = configNames, Default = "Default", Callback = function(v) Config.Settings.ConfigName = v; SaveConfig() end })
SettingsGroup:AddButton({ Text = "Save Config", Func = function() SaveConfig(Config.Settings.ConfigName) end })
SettingsGroup:AddButton({ Text = "Load Config", Func = function() LoadConfig(Config.Settings.ConfigName) end })
SettingsGroup:AddButton({ Text = "Delete Config", Func = function() 
    if Config.Settings.ConfigName ~= "Default" then
        getgenv().NexoConfigs[Config.Settings.ConfigName] = nil
        Library:Notify("Config deleted!", 2)
    else
        Library:Notify("Cannot delete Default config!", 2)
    end
end })
SettingsGroup:AddToggle("AutoLoad", { Text = "Auto-Load on Start", Default = Config.Settings.AutoLoad, Callback = function(v) Config.Settings.AutoLoad = v; SaveConfig() end })

-- ============================================================
-- 5. MAIN LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    if Config.Aimbot.Enabled then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = mousePos
        FOVCircle.Visible = true
        FOVCircle.Radius = Config.Aimbot.FOV
    else
        FOVCircle.Visible = false
    end
    
    -- Aimbot
    if Config.Aimbot.Enabled and UserInputService:IsKeyDown(Config.Aimbot.Keybind) then
        local targets = GetTargets()
        if #targets > 0 then
            AimAt(targets[1])
        end
    end
    
    -- Ragebot
    if Config.Ragebot.Enabled then
        Ragebot()
    end
    
    -- Triggerbot
    if Config.Triggerbot.Enabled and UserInputService:IsKeyDown(Config.Triggerbot.Keybind) then
        Triggerbot()
    end
    
    -- ESP
    UpdateESP()
end)

-- ============================================================
-- 6. INITIALIZATION
-- ============================================================
if Config.Settings.AutoLoad then
    LoadConfig("Default")
end

StartOrbit()
StartVoidspam()
StartSpeed()
StartFlight()

Library:SetWatermark("Nexo v1.0")
Library:Notify("Nexo loaded! Press RightShift to open menu.", 3)

-- ============================================================
-- 7. UNLOAD CLEANUP
-- ============================================================
Library:OnUnload(function()
    if voidTask then voidTask:Disconnect() end
    if orbitTask then orbitTask:Disconnect() end
    if speedTask then speedTask:Disconnect() end
    if flyTask then flyTask:Disconnect() end
    FOVCircle:Remove()
    for _, objects in pairs(EspObjects) do
        for _, obj in pairs(objects) do
            if obj then pcall(function() obj:Remove() end) end
        end
    end
    EspObjects = {}
    print("Nexo unloaded.")
end)

-- ============================================================
-- END OF SCRIPT
-- ============================================================
