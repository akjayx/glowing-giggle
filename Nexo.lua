local emu = 0.45126582 + math.pi
local hyperion = {
    0x1,
    0x2,
    0x3,
    0x482f68efe4653f067d1a2f6119ebd97ee3c2ffc5,
}

local byfron = task.spawn(function()
    local kernel = emu * 0x1337
    local integrity = hyperion[4] / hyperion[4]
    local packet = {}

    for i = 1, 12 do
        local quantum = ((i * kernel) / kernel) * integrity
        packet[i] = string.char(({72,101,108,108,111,32,87,111,114,108,100,33})[quantum])
    end

    local anticheat = table.concat(packet)

    if hyperion[1] + hyperion[2] == hyperion[3] then
        warn("emulating hyperion")
        warn("done")
        task.wait(0.04)
        print(anticheat)
    end
end)

if getgenv().__LilacSleepyCleanup then pcall(getgenv().__LilacSleepyCleanup) end

local Players           = cloneref and cloneref(game:GetService("Players"))           or game:GetService("Players")
local RunService        = cloneref and cloneref(game:GetService("RunService"))        or game:GetService("RunService")
local Workspace         = cloneref and cloneref(game:GetService("Workspace"))         or game:GetService("Workspace")
local UserInputService  = cloneref and cloneref(game:GetService("UserInputService"))  or game:GetService("UserInputService")
local TweenService      = cloneref and cloneref(game:GetService("TweenService"))      or game:GetService("TweenService")
local SoundService      = cloneref and cloneref(game:GetService("SoundService"))      or game:GetService("SoundService")
local Lighting          = cloneref and cloneref(game:GetService("Lighting"))          or game:GetService("Lighting")
local TeleportService   = cloneref and cloneref(game:GetService("TeleportService"))   or game:GetService("TeleportService")
local HttpService       = cloneref and cloneref(game:GetService("HttpService"))       or game:GetService("HttpService")
local CollectionService = cloneref and cloneref(game:GetService("CollectionService")) or game:GetService("CollectionService")
local GuiService        = cloneref and cloneref(game:GetService("GuiService"))        or game:GetService("GuiService")
local Stats             = cloneref and cloneref(game:GetService("Stats"))             or game:GetService("Stats")
local ContextActionSvc  = cloneref and cloneref(game:GetService("ContextActionService")) or game:GetService("ContextActionService")

local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")

-- ---------------------------------------------------------------------------
-- player / playergui guard (fixes Lilac error codes 1 and 2)
-- ---------------------------------------------------------------------------
local player
do
    local deadline = os.clock() + 15
    repeat
        player = Players.LocalPlayer
        if player then break end
        task.wait(0.1)
    until os.clock() > deadline
    if not player then
        warn("error: make a ticket error code: 1")
        return
    end
end

local playerGui
do
    local deadline = os.clock() + 15
    repeat
        playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then break end
        task.wait(0.1)
    until os.clock() > deadline
    if not playerGui then
        warn("error: make a ticket error code: 2")
        return
    end
end

-- clear leftovers from any prior run of either engine
for _, name in ipairs({ "LilacUI", "LilacHUD", "LilacCursor", "LilacSkinChangerGui", "_MeowCosmeticsHost", "_MeowTargetHUD", "_MeowMusicPlayerGui", "_MeowKeybindsWidget", "_MeowCosmeticPill", "LilacCfgName", "LilacTpUrlPrompt" }) do
    local s = playerGui:FindFirstChild(name)
    if s then s:Destroy() end
    local c = CoreGui:FindFirstChild(name)
    if c then c:Destroy() end
end

-- ---------------------------------------------------------------------------
-- lifecycle registry (shared by both engines)
-- ---------------------------------------------------------------------------
local connections, cleanups = {}, {}
local function connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(connections, c)
    return c
end
local function cleanup(fn) table.insert(cleanups, fn) end

getgenv().__LilacSleepyCleanup = function()
    for _, f in ipairs(cleanups) do pcall(f) end
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(cleanups); table.clear(connections)
    for _, n in ipairs({ "LilacUI", "LilacHUD", "LilacCursor", "LilacSkinChangerGui", "_MeowCosmeticsHost", "_MeowTargetHUD", "_MeowMusicPlayerGui", "_MeowKeybindsWidget", "_MeowCosmeticPill" }) do
        local s = playerGui:FindFirstChild(n); if s then s:Destroy() end
        local c = CoreGui:FindFirstChild(n); if c then c:Destroy() end
    end
    getgenv().__LilacSleepyCleanup = nil
    shared.LilacState = nil
    shared.SleepyState = nil
end

-- ---------------------------------------------------------------------------
-- platform detection (Lilac)
-- ---------------------------------------------------------------------------
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local platform = isMobile and "Mobile" or (UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled and not UserInputService.TouchEnabled and "Console" or "PC")
local activePlat = platform
local function inputClass()
    local n = UserInputService:GetLastInputType().Name
    if n == "Touch" then return "Mobile" end
    if n:sub(1, 7) == "Gamepad" then return "Console" end
    if n:sub(1, 5) == "Mouse" or n == "Keyboard" then return "PC" end
    return activePlat
end

-- ---------------------------------------------------------------------------
-- shared Settings registry
-- ---------------------------------------------------------------------------
local Settings, Defaults, Handlers = {}, {}, {}
local function reg(key, default)
    Settings[key] = default
    Defaults[key] = default
end
local function commit(key, v)
    Settings[key] = v
    if Handlers[key] then pcall(Handlers[key], v) end
end
local function applySetting(key, v)
    commit(key, v)
end

-- default values (Lilac)
reg("aim.enabled", false); reg("aim.mode", "Hold"); reg("aim.key", "MouseButton2")
reg("aim.method", "Mouse"); reg("aim.smooth", 35); reg("aim.xsmooth", 100); reg("aim.ysmooth", 100)
reg("aim.speed", 100); reg("aim.sync", "Early"); reg("aim.sticky", true)
reg("aim.bone", "Head"); reg("aim.priority", "Crosshair"); reg("aim.maxdist", 1000)
reg("aim.wall", true); reg("aim.team", true); reg("aim.hpcheck", true); reg("aim.minhp", 0)
reg("aim.pred", 0); reg("aim.deadzone", 0); reg("aim.humanize", 0); reg("aim.reaction", 0); reg("aim.forget", 150)
reg("silent.enabled", false); reg("silent.mode", "Hold"); reg("silent.key", "MouseButton2")
reg("silent.bone", "Head"); reg("silent.priority", "Crosshair"); reg("silent.maxdist", 900)
reg("silent.wall", true); reg("silent.team", true); reg("silent.fov", 140); reg("silent.smooth", 12)
reg("silent.headchance", 70); reg("silent.reaction", 40); reg("silent.forget", 200)
reg("silent.autofire", false); reg("silent.firerate", 90); reg("silent.drawfov", true)
reg("rage.enabled", false); reg("rage.mode", "Hold"); reg("rage.key", "Z"); reg("rage.fov", 180)
reg("rage.priority", "Crosshair"); reg("rage.maxdist", 2000); reg("rage.bone", "Hitscan")
reg("rage.wall", true); reg("rage.team", true); reg("rage.hpcheck", true); reg("rage.pred", 0)
reg("rage.autofire", true); reg("rage.firerate", 100); reg("rage.aa", "Off")
reg("rage.aaspeed", 720); reg("rage.aajit", 90)
reg("fov.size", 120); reg("fov.draw", true); reg("fov.color", Color3.fromRGB(240,130,200))
reg("fov.lockcolor", Color3.fromRGB(120,255,150)); reg("fov.fill", false)
reg("trig.enabled", false); reg("trig.mode", "Hold"); reg("trig.key", "E"); reg("trig.delay", 60)
reg("trig.wall", true); reg("trig.team", true); reg("trig.hpcheck", true)
reg("hb.enabled", false); reg("hb.size", 6); reg("hb.trans", 0.7); reg("hb.team", false)
reg("hit.enabled", true); reg("hit.color", Color3.fromRGB(255,80,100)); reg("hit.size", 8)
reg("live.esp", true); reg("esp.enabled", true); reg("esp.maxdist", 2500); reg("esp.highlight", false)
reg("esp.box", true); reg("esp.names", true); reg("esp.healthinfo", true); reg("esp.vhealth", true)
reg("esp.weapon", false); reg("esp.ammo", false); reg("esp.distance", false); reg("esp.look", false)
reg("esp.arrows", false); reg("esp.team", false)
reg("skel.enabled", true); reg("skel.thick", 1)
reg("skel.c1", Color3.fromRGB(255,255,255)); reg("skel.c2", Color3.fromRGB(160,100,255)); reg("skel.c3", Color3.fromRGB(90,160,255))
reg("head.enabled", true); reg("head.color", Color3.fromRGB(255,80,80)); reg("head.shape", "Cross")
reg("head.fill", false); reg("head.size", 5); reg("head.thick", 1)
reg("bars.width", 3); reg("bars.high", Color3.fromRGB(120,255,120)); reg("bars.low", Color3.fromRGB(255,80,100))
reg("bars.gradient", false); reg("bars.boxstyle", "Full"); reg("bars.boxcolor", Color3.fromRGB(255,255,255))
reg("bars.boxthick", 1); reg("bars.fillbox", false); reg("bars.fillcolor", Color3.fromRGB(160,100,255)); reg("bars.fillopacity", 20)
reg("tr.enabled", false); reg("tr.origin", "Bottom"); reg("tr.color", Color3.fromRGB(240,130,200)); reg("tr.thick", 1)
reg("cham.fill", Color3.fromRGB(160,100,255)); reg("cham.outline", Color3.fromRGB(255,255,255))
reg("cham.opacity", 45); reg("cham.pulse", false)
reg("fmt.size", 12); reg("fmt.color", Color3.fromRGB(255,255,255)); reg("fmt.font", "Gotham")
reg("fmt.outline", true); reg("fmt.unit", "Meters"); reg("fmt.hp", 75)
reg("char.skin", Color3.fromRGB(226,190,150)); reg("char.shirt", Color3.fromRGB(24,22,30))
reg("char.pants", Color3.fromRGB(70,76,66)); reg("char.hair", Color3.fromRGB(30,24,30))
reg("char.sway", true); reg("char.speed", 1.5); reg("char.scale", 100)
reg("world.env", "Default"); reg("world.brightness", 70); reg("world.grid", true)
reg("world.tint", Color3.fromRGB(255,255,255))
reg("mv.speed", false); reg("mv.speedval", 40); reg("mv.speedmode", "WalkSpeed")
reg("mv.float", false); reg("mv.jump", false); reg("mv.jumpval", 90); reg("mv.fly", false)
reg("mv.flyspeed", 50); reg("mv.infjump", false); reg("mv.bhop", false); reg("mv.noclip", false)
reg("fc.enabled", false); reg("fc.speed", 40)
reg("vis.glow", true); reg("vis.glowstr", 70); reg("vis.anim", true); reg("vis.petals", true)
reg("vis.petalcount", 14); reg("vis.opacity", 100); reg("vis.preset", "Lilac")
reg("vis.accent", Color3.fromRGB(240,130,200)); reg("vis.accent2", Color3.fromRGB(176,92,232))
reg("vis.watermark", true); reg("vis.keylist", true); reg("vis.targethud", true)
reg("vis.targetline", true); reg("vis.arraylist", true)
reg("set.menukey", "RightShift"); reg("set.scale", 100); reg("set.preview", platform == "PC")
reg("set.lock", false); reg("set.confirm", true); reg("set.cursor", true); reg("set.hints", true)
reg("misc.notify", true); reg("misc.loadnotify", true); reg("misc.silentload", false)
reg("misc.tips", true); reg("misc.antiafk", false); reg("misc.togglenotify", false)
reg("cfg.selected", "default"); reg("cfg.autoload", true); reg("cfg.autoloadname", "default")

-- default values (Sleepy additions)
reg("sy.aimbot_enabled", false); reg("sy.aimbot_active", false); reg("sy.aimbot_smooth_step", 6); reg("sy.aimbot_radius_smoothed", 90)
reg("sy.silent_aim_enabled", false); reg("sy.fov_radius_smoothed", 120); reg("sy.fov_color", Color3.fromRGB(0,162,255))
reg("sy.hit_chance", 100); reg("sy.riot_shield_check", false); reg("sy.avoid_katana", false)
reg("sy.antiaim_enabled", false); reg("sy.antiaim_preset", "Custom"); reg("sy.yaw_type", "Spin")
reg("sy.pitch_type", "Down"); reg("sy.rotation_speed", 20); reg("sy.jitter_range", 60)
reg("sy.esp_enabled", false); reg("sy.esp_box_style", "Corner"); reg("sy.esp_box_color", Color3.fromRGB(255,255,255))
reg("sy.esp_boxes", false); reg("sy.esp_box_fill", false); reg("sy.esp_fill_color", Color3.fromRGB(0,162,255))
reg("sy.esp_box_fit", "Dynamic"); reg("sy.esp_names", false); reg("sy.esp_name_color", Color3.fromRGB(240,240,240))
reg("sy.esp_health_bars", false); reg("sy.esp_health_color", Color3.fromRGB(0,255,120)); reg("sy.esp_health_mode", "Reactive")
reg("sy.esp_health_number", false); reg("sy.esp_hp_num_color", Color3.fromRGB(255,255,255))
reg("sy.esp_ammo_bar", false); reg("sy.esp_ammo_color", Color3.fromRGB(0,162,255))
reg("sy.esp_weapons", false); reg("sy.esp_weapon_color", Color3.fromRGB(220,220,220))
reg("sy.esp_distance", false); reg("sy.esp_dist_color", Color3.fromRGB(180,180,180))
reg("sy.esp_rank", false); reg("sy.esp_rank_color", Color3.fromRGB(255,215,0))
reg("sy.esp_streak", false); reg("sy.esp_streak_color", Color3.fromRGB(255,100,50))
reg("sy.esp_deflecting", false); reg("sy.esp_deflect_color", Color3.fromRGB(255,0,150))
reg("sy.esp_team_enabled", false); reg("sy.esp_team_check", false); reg("sy.esp_max_distance", 1500)
reg("sy.esp_display_names", false); reg("sy.esp_font_choice", "Code"); reg("sy.esp_font_size", 13)
reg("sy.esp_text_case", "lowercase"); reg("sy.esp_text_surround", "None")
reg("sy.esp_flag_size", 10); reg("sy.esp_flag_surround", "[]")
reg("sy.chams_enabled", false); reg("sy.chams_color", Color3.fromRGB(0,162,255))
reg("sy.chams_fill_transparency", 0.4); reg("sy.chams_outline_transparency", 0); reg("sy.chams_depth_mode", "AlwaysOnTop")
reg("sy.crosshair_enabled", false); reg("sy.crosshair_color", Color3.fromRGB(0,162,255))
reg("sy.crosshair_outline", false); reg("sy.crosshair_dot", false); reg("sy.crosshair_dot_color", Color3.fromRGB(0,162,255))
reg("sy.crosshair_dot_size", 2.5); reg("sy.crosshair_length", 14); reg("sy.crosshair_offset", 6)
reg("sy.crosshair_thickness", 2); reg("sy.crosshair_rainbow", false); reg("sy.crosshair_rainbow_speed", 2)
reg("sy.crosshair_t_shape", false); reg("sy.crosshair_rotation_speed", 0); reg("sy.crosshair_rotation", 0)
reg("sy.crosshair_bounce_speed", 0); reg("sy.crosshair_bounce_amp", 0); reg("sy.crosshair_hit_pulse", false)
reg("sy.hit_sound_enabled", false); reg("sy.hit_sound_preset", "Rust"); reg("sy.kill_sound_enabled", false)
reg("sy.kill_sound_preset", "Fatality"); reg("sy.sound_volume", 1.0); reg("sy.sound_pitch", 1.0)
reg("sy.world_marker_enabled", false); reg("sy.world_marker_color", Color3.fromRGB(0,162,255))
reg("sy.target_hud", false); reg("sy.target_hud_preview", false); reg("sy.target_hud_scale", 1.0)
reg("sy.walk_speed_enabled", false); reg("sy.walk_speed_mult", 1.5)
reg("sy.noclip_enabled", false); reg("sy.bhop_enabled", false)
reg("sy.flight_enabled", false); reg("sy.flight_speed", 100)
reg("sy.double_jump", false); reg("sy.double_jump_height", 1.0)
reg("sy.fake_position_enabled", false); reg("sy.fake_position_depth", 5.8)
reg("sy.auto_loadout_enabled", false); reg("sy.staff_detector", false)
reg("sy.world_skybox_enabled", false); reg("sy.skybox_preset", "Synthwave")
reg("sy.item_chams", false); reg("sy.item_wireframe", false); reg("sy.arm_appearance", false)
reg("sy.show_cosmetics_changer", true)
reg("sy.music_player_visible", false)
reg("sy.antiaim_spin_speed", 15); reg("sy.antiaim_jitter_range", 45)

-- ---------------------------------------------------------------------------
-- theme (merged: Lilac dark-violet base + Sleepy electric blue accents)
-- ---------------------------------------------------------------------------
local Theme = {
    Bg           = Color3.fromRGB(10, 6, 14),
    Sidebar      = Color3.fromRGB(14, 8, 18),
    Card         = Color3.fromRGB(22, 12, 28),
    CardHead     = Color3.fromRGB(32, 18, 40),
    Field        = Color3.fromRGB(12, 7, 16),
    Border       = Color3.fromRGB(78, 42, 78),
    Text         = Color3.fromRGB(250, 240, 250),
    Muted        = Color3.fromRGB(160, 130, 165),
    Off          = Color3.fromRGB(48, 32, 52),
    Accent       = Color3.fromRGB(0, 162, 255),
    Accent2      = Color3.fromRGB(176, 92, 232),
    Glow         = Color3.fromRGB(0, 162, 255),
}
local FontMap = { Gotham = Enum.Font.GothamMedium, Code = Enum.Font.Code, Merriweather = Enum.Font.Merriweather }
local BODY = Enum.Font.GothamMedium
local LIGHT = Enum.Font.Gotham
local BOLD = Enum.Font.GothamBold
local HEAD = Enum.Font.GothamBold

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
local function create(cls, props, parent)
    local o = Instance.new(cls)
    if props then for k, v in pairs(props) do o[k] = v end end
    if parent then o.Parent = parent end
    return o
end
local function corner(p, r) return create("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p) end
local function round(p) return create("UICorner", { CornerRadius = UDim.new(1, 0) }, p) end
local function stroke(p, c, t, tr)
    return create("UIStroke", { Color = c or Theme.Border, Thickness = t or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
end
local function pad(p, t, r, b, l)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or t or 0),
        PaddingBottom = UDim.new(0, b or t or 0), PaddingLeft = UDim.new(0, l or r or t or 0),
    }, p)
end
local function tween(o, props, dur, style, dir)
    local t = TweenService:Create(o, TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play(); return t
end
local function text(parent, str, size, color, font, align)
    return create("TextLabel", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = str, TextSize = size,
        TextColor3 = color or Theme.Text, Font = font or BODY,
        TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        Size = UDim2.new(1, 0, 0, size + 6),
    }, parent)
end
local function hex(c) return "#" .. c:ToHex():upper() end
local function contrast(c)
    local l = c.R * 0.299 + c.G * 0.587 + c.B * 0.114
    return l > 0.6 and Color3.fromRGB(20, 10, 24) or Color3.new(1, 1, 1)
end
local function prettyKey(n)
    n = tostring(n or "None")
    return n:gsub("MouseButton", "Mouse "):gsub("^Button", "Pad ")
end

-- ---------------------------------------------------------------------------
-- screen guis (menu, hud, cursor)
-- ---------------------------------------------------------------------------
local gui = create("ScreenGui", { Name = "LilacUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000 }, playerGui)
local hudGui = create("ScreenGui", { Name = "LilacHUD", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 500 }, playerGui)
local cursorGui = create("ScreenGui", { Name = "LilacCursor", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 2000 }, playerGui)
cleanup(function() gui:Destroy(); hudGui:Destroy(); cursorGui:Destroy() end)

-- ---------------------------------------------------------------------------
-- menu root
-- ---------------------------------------------------------------------------
local RW, RH = 1360, 650
local MAIN_W, SIDEBAR_W = 1080, 200
if isMobile then RW, RH, MAIN_W, SIDEBAR_W = 820, 400, 820, 150 end
local PREVIEW_W = 260
local CONTENT_W = MAIN_W - SIDEBAR_W

local root = create("Frame", {
    Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(RW, RH), BackgroundTransparency = 1,
}, gui)

local dim = create("TextButton", {
    Name = "Dim", Selectable = false, Text = "", AutoButtonColor = false,
    BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1), ZIndex = 0, Visible = false,
}, gui)

local uiScale = create("UIScale", {}, root)
local userScale = 1
local openAnim = 1
local function fit()
    local v = gui.AbsoluteSize
    local s = math.min(1, (v.X - 32) / RW, (v.Y - 32) / RH)
    uiScale.Scale = math.max(0.4, s) * userScale * openAnim
end
local animVal = create("NumberValue", { Value = 1 })
connect(animVal.Changed, function(v) openAnim = v; fit() end)
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), fit)
fit()

local glowOuter = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(-5, -5), Size = UDim2.fromOffset(MAIN_W + 10, RH + 10) }, root)
corner(glowOuter, 20)
local glowOuterStroke = stroke(glowOuter, Theme.Accent, 10, 0.78)

local glowInner = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(-2, -2), Size = UDim2.fromOffset(MAIN_W + 4, RH + 4) }, root)
corner(glowInner, 17)
local glowInnerStroke = stroke(glowInner, Theme.Accent, 4, 0.45)

local main = create("Frame", { Name = "Main", BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromOffset(MAIN_W, RH), BorderSizePixel = 0, ClipsDescendants = true }, root)
corner(main, 15)
create("UIGradient", {
    Rotation = 125,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 14, 34)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(16, 9, 20)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 4, 12)),
    }),
}, main)
local mainStroke = stroke(main, Theme.Accent, 1.5, 0.05)

-- sidebar
local sidebar = create("Frame", { Name = "Sidebar", BackgroundColor3 = Theme.Sidebar, BackgroundTransparency = 0.15, Size = UDim2.new(0, SIDEBAR_W, 1, 0), BorderSizePixel = 0 }, main)
create("Frame", { BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.4, BorderSizePixel = 0, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0) }, sidebar)

local logo = create("Frame", { BackgroundColor3 = Theme.CardHead, Position = UDim2.fromOffset(14, 13), Size = UDim2.fromOffset(38, 38), BorderSizePixel = 0 }, sidebar)
corner(logo, 11)
local logoStroke = stroke(logo, Theme.Accent, 1.2)
local logoText = text(logo, "L", 21, Theme.Accent, HEAD, Enum.TextXAlignment.Center)
logoText.Size = UDim2.fromScale(1, 1)

local brand = text(sidebar, "Lilac+Sleepy", 18, Theme.Text, HEAD)
brand.Position = UDim2.fromOffset(62, 12); brand.Size = UDim2.new(1, -70, 0, 24)
local brandSub = text(sidebar, "MERGED  ·  v5.0", 8, Theme.Muted, LIGHT)
brandSub.Position = UDim2.fromOffset(63, 36); brandSub.Size = UDim2.new(1, -70, 0, 14)

local navHolder = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, isMobile and 62 or 78), Size = UDim2.new(1, -24, 0, 420) }, sidebar)
create("UIListLayout", { Padding = UDim.new(0, isMobile and 4 or 6), SortOrder = Enum.SortOrder.LayoutOrder }, navHolder)

-- content area
local content = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(SIDEBAR_W, 0), Size = UDim2.fromOffset(CONTENT_W, RH) }, main)

local pageTitle = text(main, "Combat", 17, Theme.Text, HEAD)
pageTitle.Position = UDim2.fromOffset(SIDEBAR_W + 22, 0); pageTitle.Size = UDim2.fromOffset(120, 56)
local topLine = create("Frame", { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.6, BorderSizePixel = 0, Position = UDim2.fromOffset(SIDEBAR_W, 55), Size = UDim2.fromOffset(MAIN_W - SIDEBAR_W, 1) }, main)
create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.6, 0.7), NumberSequenceKeypoint.new(1, 1) }) }, topLine)

local fpsLabel = text(main, "", 10, Theme.Muted, BODY, Enum.TextXAlignment.Right)
fpsLabel.Position = UDim2.new(1, -250, 0, 0); fpsLabel.Size = UDim2.fromOffset(160, 56)

local searchBox = create("TextBox", {
    Name = "Search", Text = "", PlaceholderText = "Search settings...", ClearTextOnFocus = false,
    Font = LIGHT, TextSize = 12, TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted,
    TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = Theme.Field,
    Position = UDim2.fromOffset(SIDEBAR_W + 140, 12),
    Size = UDim2.fromOffset(isMobile and 330 or 440, 32), BorderSizePixel = 0,
}, main)
corner(searchBox, 10); stroke(searchBox, Theme.Border, 1); pad(searchBox, 0, 10, 0, 36)

-- window buttons
local function windowButton(offsetX, kind)
    local b = create("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.CardHead, BackgroundTransparency = 1,
        Position = UDim2.new(1, offsetX, 0, 13), Size = UDim2.fromOffset(30, 30), BorderSizePixel = 0,
    }, main)
    corner(b, 8)
    local bars = {}
    local function bar(rot)
        local f = create("Frame", { BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 1.6), Rotation = rot }, b)
        table.insert(bars, f)
    end
    if kind == "close" then bar(45); bar(-45) else bar(0) end
    b.MouseEnter:Connect(function() tween(b, { BackgroundTransparency = 0 }, 0.1); for _, f in ipairs(bars) do f.BackgroundColor3 = Theme.Text end end)
    b.MouseLeave:Connect(function() tween(b, { BackgroundTransparency = 1 }, 0.1); for _, f in ipairs(bars) do f.BackgroundColor3 = Theme.Muted end end)
    return b
end

local Menu = { open = false }
local minButton = windowButton(-76, "min")
local closeButton = windowButton(-42, "close")
closeButton.Activated:Connect(function() if Menu.setOpen then Menu.setOpen(false) end end)

-- drag
do
    local dragBar = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), Active = true }, main)
    local drag = { active = false }
    connect(dragBar.InputBegan, function(i)
        if Settings["set.lock"] then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag.active = true
            drag.start = Vector2.new(i.Position.X, i.Position.Y)
            drag.origin = root.Position
        end
    end)
    connect(UserInputService.InputChanged, function(i)
        if drag.active and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = Vector2.new(i.Position.X, i.Position.Y) - drag.start
            root.Position = UDim2.new(drag.origin.X.Scale, drag.origin.X.Offset + d.X, drag.origin.Y.Scale, drag.origin.Y.Offset + d.Y)
        end
    end)
    connect(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag.active = false end
    end)
end

-- ---------------------------------------------------------------------------
-- rows (card rows: toggle, slider, dropdown, color, keybind, button, config)
-- ---------------------------------------------------------------------------
local Controls = {}
local allRows = {}

local function makeRow(body, def)
    local height = def.type == "config" and 84 or 36
    local row = create("Frame", { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0 }, body)
    row:SetAttribute("Search", ((def.name or "") .. " " .. (def.tip or "")):lower())
    table.insert(allRows, { frame = row, base = height })
    create("Frame", { BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.7, BorderSizePixel = 0, Position = UDim2.new(0, 12, 1, -1), Size = UDim2.new(1, -24, 0, 1) }, row)
    row.MouseEnter:Connect(function() tween(row, { BackgroundTransparency = 0.93 }, 0.12) end)
    row.MouseLeave:Connect(function() tween(row, { BackgroundTransparency = 1 }, 0.12) end)
    if def.type ~= "config" then
        local lbl = text(row, def.name, 12, Theme.Text, BODY)
        lbl.Position = UDim2.fromOffset(14, 0); lbl.Size = UDim2.new(0.42, -14, 1, 0)
    end

    local key = def.key
    if def.type == "toggle" then
        local track = create("TextButton", { Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(40, 20), BorderSizePixel = 0, BackgroundColor3 = Theme.Off }, row)
        round(track)
        local glow = stroke(track, Theme.Accent, 3, 1)
        local knob = create("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0 }, track)
        round(knob)
        local function render(v)
            tween(track, { BackgroundColor3 = v and Theme.Accent or Theme.Off })
            tween(knob, { Position = v and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.22, Enum.EasingStyle.Back)
            tween(glow, { Transparency = v and 0.72 or 1 })
        end
        Controls[key] = { apply = render }
        track.Activated:Connect(function()
            local v = not Settings[key]
            render(v); commit(key, v)
        end)
    elseif def.type == "slider" then
        local mn, mx, step = def.min, def.max, def.step or 1
        local function fmt(v)
            if step >= 1 then return tostring(math.floor(v + 0.5)) end
            if step >= 0.1 then return string.format("%.1f", v) end
            return string.format("%.2f", v)
        end
        local box = create("TextBox", {
            Text = fmt(Settings[key]), ClearTextOnFocus = false, Font = BODY, TextSize = 11,
            TextColor3 = Theme.Text, BackgroundColor3 = Theme.Field,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(46, 24), BorderSizePixel = 0,
        }, row)
        corner(box, 7); stroke(box, Theme.Border, 1)
        local tPos = UDim2.new(0.42, 0, 0.5, 0)
        local track = create("Frame", { BackgroundColor3 = Theme.Off, AnchorPoint = Vector2.new(0, 0.5), Position = tPos, Size = UDim2.new(0.58, -84, 0, 6), BorderSizePixel = 0 }, row)
        round(track)
        local fill = create("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, track)
        round(fill)
        create("UIGradient", { Color = ColorSequence.new(Theme.Accent2, Theme.Accent) }, fill)
        local knob = create("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(13, 13), BorderSizePixel = 0 }, track)
        round(knob); stroke(knob, Theme.Accent, 3, 0.6)
        local hit = create("TextButton", { Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = tPos, Size = UDim2.new(0.58, -84, 0, 26) }, row)
        local function render(v)
            local frac = (v - mn) / (mx - mn)
            fill.Size = UDim2.fromScale(frac, 1)
            knob.Position = UDim2.fromScale(frac, 0.5)
            box.Text = fmt(v)
        end
        local function snap(v)
            v = mn + math.floor((v - mn) / step + 0.5) * step
            v = math.clamp(v, mn, mx)
            return math.floor(v * 1000 + 0.5) / 1000
        end
        Controls[key] = { apply = render }
        render(Settings[key])
        local active = false
        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                active = true
                local frac = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local v = snap(mn + frac * (mx - mn))
                render(v); commit(key, v)
            end
        end)
        connect(UserInputService.InputChanged, function(i)
            if active and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local frac = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local v = snap(mn + frac * (mx - mn))
                if v ~= Settings[key] then render(v); commit(key, v) end
            end
        end)
        connect(UserInputService.InputEnded, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then active = false end
        end)
        connect(box.FocusLost, function()
            local n = tonumber(box.Text)
            if n then n = snap(n); render(n); commit(key, n) else render(Settings[key]) end
        end)
    elseif def.type == "dropdown" then
        local opts = def.options
        local btn = create("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Field, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(128, 26), BorderSizePixel = 0 }, row)
        corner(btn, 8); stroke(btn, Theme.Border, 1)
        local lab = text(btn, Settings[key], 11, Theme.Text, BODY)
        lab.Position = UDim2.fromOffset(11, 0); lab.Size = UDim2.new(1, -30, 1, 0)
        Controls[key] = { apply = function(v) lab.Text = v end }
        btn.Activated:Connect(function()
            local list = create("Frame", { BackgroundColor3 = Theme.Card, Position = UDim2.fromOffset(SIDEBAR_W + 500, 260), Size = UDim2.fromOffset(140, #opts * 28 + 10), ZIndex = 60 }, root)
            corner(list, 11); stroke(list, Theme.Accent, 1, 0.4)
            local holder = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 1, -10) }, list)
            create("UIListLayout", {}, holder)
            for _, o in ipairs(opts) do
                local ob = create("TextButton", { Text = o, Font = BODY, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = (o == Settings[key]) and Theme.Accent or Theme.Text, AutoButtonColor = false, BackgroundColor3 = Theme.CardHead, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), BorderSizePixel = 0 }, holder)
                corner(ob, 7); pad(ob, 0, 8, 0, 10)
                ob.MouseEnter:Connect(function() tween(ob, { BackgroundTransparency = 0.2 }, 0.08) end)
                ob.MouseLeave:Connect(function() tween(ob, { BackgroundTransparency = 1 }, 0.08) end)
                ob.Activated:Connect(function()
                    lab.Text = o; commit(key, o); list:Destroy()
                end)
            end
            task.delay(3, function() if list.Parent then list:Destroy() end end)
        end)
    elseif def.type == "color" then
        local sw = create("TextButton", {
            Text = hex(Settings[key]), AutoButtonColor = false, Font = BOLD, TextSize = 10,
            BackgroundColor3 = Settings[key], TextColor3 = contrast(Settings[key]),
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(84, 24), BorderSizePixel = 0,
        }, row)
        corner(sw, 8); stroke(sw, Settings[key], 3, 0.75)
        Controls[key] = { apply = function(c) sw.BackgroundColor3 = c; sw.Text = hex(c); sw.TextColor3 = contrast(c) end }
        sw.Activated:Connect(function()
            local h, s, v = Settings[key]:ToHSV()
            local picker = create("Frame", { BackgroundColor3 = Theme.Card, Position = UDim2.fromOffset(SIDEBAR_W + 420, 180), Size = UDim2.fromOffset(220, 250), ZIndex = 60 }, root)
            corner(picker, 11); stroke(picker, Theme.Accent, 1, 0.4)
            local sv = create("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromHSV(h, 1, 1), Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(190, 120), BorderSizePixel = 0 }, picker)
            corner(sv, 8)
            create("UIGradient", { Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)) }) }, create("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Parent = sv }))
            local quick = { Color3.fromRGB(255,255,255), Color3.fromRGB(240,130,200), Color3.fromRGB(176,92,232), Color3.fromRGB(0,162,255), Color3.fromRGB(255,80,80), Color3.fromRGB(120,230,140), Color3.fromRGB(255,210,90), Color3.fromRGB(20,20,24) }
            for i, qc in ipairs(quick) do
                local q = create("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = qc, Position = UDim2.fromOffset(12 + (i - 1) * 24, 148), Size = UDim2.fromOffset(20, 20), BorderSizePixel = 0 }, picker)
                round(q); stroke(q, Theme.Border, 1)
                q.Activated:Connect(function()
                    local hh, ss, vv = qc:ToHSV()
                    Controls[key].apply(qc); commit(key, qc)
                    picker:Destroy()
                end)
            end
            local close = create("TextButton", { Text = "close", Font = BODY, TextSize = 11, TextColor3 = Theme.Text, BackgroundColor3 = Theme.CardHead, Position = UDim2.fromOffset(12, 180), Size = UDim2.fromOffset(190, 26), BorderSizePixel = 0 }, picker)
            corner(close, 7); close.Activated:Connect(function() picker:Destroy() end)
            task.delay(8, function() if picker.Parent then picker:Destroy() end end)
        end)
    elseif def.type == "keybind" then
        local btn = create("TextButton", {
            Text = prettyKey(Settings[key]), AutoButtonColor = false, Font = BODY, TextSize = 11,
            TextColor3 = Theme.Text, BackgroundColor3 = Theme.Field,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(128, 26), BorderSizePixel = 0,
        }, row)
        corner(btn, 8); stroke(btn, Theme.Border, 1)
        Controls[key] = { apply = function(v) btn.Text = prettyKey(v) end }
        local binding = false
        btn.Activated:Connect(function() binding = true; btn.Text = "press any key..." end)
        connect(UserInputService.InputBegan, function(i)
            if not binding then return end
            local name
            if i.UserInputType == Enum.UserInputType.Keyboard then name = i.KeyCode.Name
            elseif i.UserInputType.Name:sub(1, 11) == "MouseButton" then name = i.UserInputType.Name
            elseif i.UserInputType.Name:sub(1, 7) == "Gamepad" and i.KeyCode ~= Enum.KeyCode.Thumbstick1 and i.KeyCode ~= Enum.KeyCode.Thumbstick2 and i.KeyCode ~= Enum.KeyCode.Unknown then name = i.KeyCode.Name end
            if not name then return end
            binding = false
            if name == "Escape" or name == "ButtonB" then btn.Text = prettyKey(Settings[key])
            elseif name == "Backspace" then btn.Text = "None"; commit(key, "None")
            else btn.Text = prettyKey(name); commit(key, name) end
        end)
    elseif def.type == "button" then
        local b = create("TextButton", { Text = def.label or def.name, Font = BODY, TextSize = 11, TextColor3 = Theme.Text, AutoButtonColor = false, BackgroundColor3 = Theme.CardHead, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(128, 26), BorderSizePixel = 0 }, row)
        corner(b, 8); stroke(b, Theme.Border, 1)
        b.Activated:Connect(function() if def.fn then def.fn() end end)
    end
    return row
end

-- ---------------------------------------------------------------------------
-- pages
-- ---------------------------------------------------------------------------
local pages, currentTab, tabOrder = {}, "Combat", {}
local function buildCard(col, def)
    local card = create("Frame", { Name = def.title, BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0 }, col)
    corner(card, 12); stroke(card, Theme.Border, 1, 0.1)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, card)
    local header = create("Frame", { BackgroundColor3 = Theme.CardHead, Size = UDim2.new(1, 0, 0, 40), BorderSizePixel = 0, LayoutOrder = 1 }, card)
    corner(header, 12)
    local dia = create("Frame", { BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(20, 20), Size = UDim2.fromOffset(7, 7), Rotation = 45 }, header)
    corner(dia, 1)
    local title = text(header, def.title, 13, Theme.Text, HEAD)
    title.Position = UDim2.fromOffset(36, 0); title.Size = UDim2.new(1, -80, 1, 0)
    local body = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3 }, card)
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, body)
    pad(body, 4, 0, 6, 0)
    for _, r in ipairs(def.rows or {}) do makeRow(body, r) end
    return card
end
local function buildPage(name, cardDefs)
    tabOrder[#tabOrder + 1] = name
    local scroll = create("ScrollingFrame", {
        Name = name, BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.fromOffset(22, 84), Size = UDim2.new(1, -44, 1, -96),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Visible = false,
    }, content)
    local wrap = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, scroll)
    pad(wrap, 2, 0, 16, 0)
    local cols = {}
    for i = 1, 2 do
        cols[i] = create("Frame", { BackgroundTransparency = 1, Position = UDim2.new((i - 1) * 0.5, (i - 1) * 6, 0, 0), Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, wrap)
        create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, cols[i])
    end
    for _, cd in ipairs(cardDefs) do
        if not (cd.game == "full" and not game.PlaceId) then
            buildCard(cols[cd.col or 1], cd)
        end
    end
    pages[name] = scroll
end

-- page definitions
local function T(key, name, def, tip) return { type = "toggle", key = key, name = name, default = def, tip = tip } end
local function S(key, name, min, max, def, tip, step) return { type = "slider", key = key, name = name, min = min, max = max, default = def, tip = tip, step = step } end
local function C(key, name, def, tip) return { type = "color", key = key, name = name, default = def, tip = tip } end
local function D(key, name, opts, tip) return { type = "dropdown", key = key, name = name, options = opts, default = Settings[key], tip = tip } end
local function B(name, label, fn, tip) return { type = "button", name = name, label = label, fn = fn, tip = tip } end
local function K(key, name, def, tip) return { type = "keybind", key = key, name = name, default = def, tip = tip } end

local rgb = Color3.fromRGB
local MODES = { "Hold", "Toggle", "Always" }

buildPage("Combat", {
    { title = "Aimbot", col = 1, rows = {
        T("aim.enabled", "Aimbot", false), K("aim.key", "Aim Key", "MouseButton2"), D("aim.mode", "Activation", MODES), D("aim.method", "Method", { "Mouse", "Camera" }),
        S("aim.smooth", "Smoothness", 1, 100, 35), S("aim.speed", "Aim Speed %", 10, 200, 100),
        D("aim.bone", "Aim Part", { "Head", "Torso", "Closest" }), D("aim.priority", "Priority", { "Crosshair", "Distance", "Lowest HP" }),
        S("aim.maxdist", "Max Distance", 50, 2000, 1000), T("aim.wall", "Wall Check", true), T("aim.team", "Team Check", true),
        S("aim.pred", "Prediction", 0, 0.3, 0, nil, 0.01), S("aim.deadzone", "Deadzone", 0, 10, 0, nil, 0.5),
    } },
    { title = "Silent Aim", col = 1, rows = {
        T("silent.enabled", "Silent Aim", false), K("silent.key", "Silent Key", "MouseButton2"), D("silent.mode", "Activation", MODES),
        S("silent.fov", "Silent FOV", 20, 400, 140), S("silent.smooth", "Assist Strength", 0, 30, 12),
        S("silent.headchance", "Headshot %", 0, 100, 70), T("silent.autofire", "Auto Fire", false),
        S("silent.firerate", "Fire Rate (ms)", 40, 600, 90),
    } },
    { title = "Ragebot", col = 1, rows = {
        T("rage.enabled", "Ragebot", false), K("rage.key", "Rage Key", "Z"), D("rage.mode", "Activation", MODES),
        S("rage.fov", "Rage FOV", 5, 180, 180), D("rage.bone", "Hit Part", { "Hitscan", "Head", "Torso" }),
        T("rage.wall", "Wall Check", true), T("rage.team", "Team Check", true), T("rage.autofire", "Auto Fire", true),
        S("rage.firerate", "Fire Delay (ms)", 20, 1000, 100), D("rage.aa", "Anti-Aim", { "Off", "Spin", "Jitter", "Backwards" }),
        S("rage.aaspeed", "Spin Speed", 60, 2000, 720), S("rage.aajit", "Jitter Angle", 10, 180, 90),
    } },
    { title = "FOV", col = 2, rows = {
        S("fov.size", "FOV Radius", 20, 600, 120), T("fov.draw", "Draw FOV Circle", true),
        C("fov.color", "FOV Color", rgb(0,162,255)), C("fov.lockcolor", "Locked Color", rgb(120,255,150)),
        T("fov.fill", "Fill Circle", false),
    } },
    { title = "Triggerbot", col = 2, rows = {
        T("trig.enabled", "Triggerbot", false), K("trig.key", "Trigger Key", "E"), D("trig.mode", "Activation", MODES),
        S("trig.delay", "Delay (ms)", 0, 300, 60), T("trig.wall", "Wall Check", true), T("trig.team", "Team Check", true),
    } },
    { title = "Hitbox", col = 2, rows = {
        T("hb.enabled", "Hitbox Expander", false), S("hb.size", "Hitbox Size", 2, 20, 6, nil, 1),
        S("hb.trans", "Transparency", 0, 1, 0.7, nil, 0.05), T("hb.team", "Include Teammates", false),
    } },
    { title = "Sleepy · Legit Aimbot", col = 2, rows = {
        T("sy.aimbot_enabled", "Enable Legit Aimbot", false), S("sy.aimbot_smooth_step", "Smoothness", 1, 25, 6),
        S("sy.aimbot_radius_smoothed", "Aimbot FOV", 10, 500, 90, nil, 5),
    } },
    { title = "Sleepy · Silent Aim Suite", col = 1, rows = {
        T("sy.silent_aim_enabled", "Enable Silent Aim", false), S("sy.fov_radius_smoothed", "FOV Radius", 10, 800, 120, nil, 5),
        C("sy.fov_color", "FOV Color", rgb(0,162,255)), S("sy.hit_chance", "Hit Chance", 1, 100, 100),
        T("sy.riot_shield_check", "Riot Shield Check", false), T("sy.avoid_katana", "Avoid Katana Deflect", false),
    } },
    { title = "Sleepy · Anti-Aim", col = 2, rows = {
        T("sy.antiaim_enabled", "Enable Anti-Aim", false),
        D("sy.yaw_type", "Yaw Mode", { "None", "Backwards", "Left", "Right", "Spin", "Sway", "Jitter", "Random" }),
        D("sy.pitch_type", "Pitch Mode", { "None", "Up", "Down", "Up & Down", "Random", "Zero" }),
        S("sy.rotation_speed", "Rotation Speed", 1, 50, 20), S("sy.jitter_range", "Jitter Range", 5, 180, 60, nil, 5),
    } },
})

buildPage("ESP", {
    { title = "ESP Options", col = 1, rows = {
        T("live.esp", "In-Game ESP", true), T("esp.enabled", "ESP Enabled", true), S("esp.maxdist", "Max Distance", 100, 5000, 2500),
        T("esp.highlight", "Highlight", false), T("esp.box", "Box", true), T("esp.names", "Names", true),
        T("esp.healthinfo", "Health Info", true), T("esp.vhealth", "Vertical Health", true),
        T("esp.weapon", "Weapon Info", false), T("esp.ammo", "Ammo Text", false), T("esp.distance", "Distance", false),
        T("esp.look", "Look Direction", false), T("esp.arrows", "Arrows", false), T("esp.team", "Show Teammates", false),
    } },
    { title = "Extra ESP", col = 2, rows = {
        T("skel.enabled", "Skeleton", true), S("skel.thick", "Skeleton Thickness", 1, 5, 1),
        C("skel.c1", "Skeleton color 1", rgb(255,255,255)), C("skel.c2", "Skeleton color 2", rgb(160,100,255)), C("skel.c3", "Skeleton color 3", rgb(90,160,255)),
        T("head.enabled", "Head marker", true), C("head.color", "Head marker color", rgb(255,80,80)),
        D("head.shape", "Marker shape", { "Cross", "Circle", "Square" }), T("head.fill", "Fill marker", false),
        S("head.size", "Marker size", 1, 12, 5), S("head.thick", "Marker thickness", 1, 5, 1),
        T("tr.enabled", "Tracers", false), D("tr.origin", "Tracer origin", { "Bottom", "Center", "Top" }),
        C("tr.color", "Tracer color", rgb(240,130,200)), S("tr.thick", "Tracer thickness", 1, 4, 1),
        C("cham.fill", "Chams fill", rgb(160,100,255)), C("cham.outline", "Chams outline", rgb(255,255,255)),
        S("cham.opacity", "Chams opacity", 0, 100, 45), T("cham.pulse", "Chams pulse", false),
        S("fmt.size", "Text size", 9, 18, 12), C("fmt.color", "Text color", rgb(255,255,255)),
        D("fmt.font", "Font", { "Gotham", "Code", "Merriweather" }), T("fmt.outline", "Text outline", true),
        D("fmt.unit", "Distance unit", { "Meters", "Studs" }), S("fmt.hp", "Preview health", 0, 100, 75),
    } },
    { title = "Sleepy · Enemy ESP", col = 2, rows = {
        T("sy.esp_enabled", "Enable Enemy ESP", false),
        D("sy.esp_box_style", "Box Style", { "Corner", "Full", "3D Box" }),
        T("sy.esp_boxes", "Bounding Box", false), C("sy.esp_box_color", "Box Color", rgb(255,255,255)),
        T("sy.esp_box_fill", "Filled Box", false), C("sy.esp_fill_color", "Fill Color", rgb(0,162,255)),
        T("sy.esp_names", "Name Tags", false), C("sy.esp_name_color", "Name Color", rgb(240,240,240)),
        T("sy.esp_health_bars", "Health Bar", false), C("sy.esp_health_color", "Health Bar Color", rgb(0,255,120)),
        T("sy.esp_health_number", "Health Number", false), T("sy.esp_weapons", "Held Weapon", false),
        T("sy.esp_distance", "Distance", false), T("sy.esp_rank", "Rank Badge", false),
        T("sy.esp_streak", "Win Streak", false), T("sy.esp_deflecting", "Deflecting", false),
        T("sy.esp_team_enabled", "Teammates ESP", false), T("sy.esp_team_check", "Team Check", false),
        S("sy.esp_font_size", "ESP Font Size", 8, 32, 13), D("sy.esp_text_case", "Text Case", { "Standard", "UPPERCASE", "lowercase" }),
        S("sy.esp_max_distance", "Max Render Distance", 50, 2000, 1500, nil, 25),
    } },
    { title = "Sleepy · Chams & Skeleton", col = 1, rows = {
        T("sy.chams_enabled", "Enable Enemy Chams", false), C("sy.chams_color", "Chams Color", rgb(0,162,255)),
        S("sy.chams_fill_transparency", "Fill Transparency", 0, 1, 0.4, nil, 0.05),
        S("sy.chams_outline_transparency", "Outline Transparency", 0, 1, 0, nil, 0.05),
        D("sy.chams_depth_mode", "Depth Mode", { "AlwaysOnTop", "Occluded" }),
    } },
})

buildPage("Visuals", {
    { title = "Interface", col = 1, rows = {
        T("vis.glow", "Glow Effects", true), S("vis.glowstr", "Glow Strength", 0, 100, 70), T("vis.anim", "Animated Glow", true),
        T("vis.petals", "Falling Petals", true), S("vis.petalcount", "Petal Count", 1, 30, 14), S("vis.opacity", "UI Opacity", 40, 100, 100),
    } },
    { title = "Colors", col = 2, rows = {
        D("vis.preset", "Theme Preset", { "Lilac", "Rose", "Violet", "Ice", "Mint", "Amber" }),
        C("vis.accent", "Accent Color", rgb(0,162,255)), C("vis.accent2", "Secondary Accent", rgb(176,92,232)),
    } },
    { title = "HUD", col = 2, rows = {
        T("vis.watermark", "Watermark", true), T("vis.keylist", "Keybind List", true),
        T("vis.targethud", "Target Info", true), T("vis.targetline", "Target Line", true), T("vis.arraylist", "Array List", true),
    } },
    { title = "Sleepy · Crosshair", col = 1, rows = {
        T("sy.crosshair_enabled", "Custom Crosshair", false), C("sy.crosshair_color", "Crosshair Color", rgb(0,162,255)),
        T("sy.crosshair_rainbow", "Rainbow Crosshair", false), S("sy.crosshair_rainbow_speed", "Rainbow Speed", 1, 10, 2),
        T("sy.crosshair_outline", "Crosshair Outlines", false), T("sy.crosshair_dot", "Center Dot", false),
        S("sy.crosshair_dot_size", "Dot Size", 1, 8, 2.5, nil, 0.5), T("sy.crosshair_t_shape", "T-Shape", false),
        S("sy.crosshair_length", "Length", 1, 50, 14), S("sy.crosshair_offset", "Gap / Offset", 0, 30, 6),
        S("sy.crosshair_thickness", "Thickness", 1, 8, 2), S("sy.crosshair_rotation_speed", "Spin", 0, 10, 0, nil, 0.2),
        S("sy.crosshair_rotation", "Static Rotation", 0, 360, 0, nil, 5), S("sy.crosshair_bounce_speed", "Bounce Speed", 0, 15, 0, nil, 0.5),
        S("sy.crosshair_bounce_amp", "Bounce Amp", 0, 20, 0), T("sy.crosshair_hit_pulse", "Hitmarker Pulse", false),
    } },
    { title = "Sleepy · Hit Effects", col = 2, rows = {
        T("sy.hit_sound_enabled", "Hit Sound Enabled", false), D("sy.hit_sound_preset", "Hit Sound Preset", { "Rust", "Skeet", "Bell", "Bonk", "Neverlose", "Bubble" }),
        T("sy.kill_sound_enabled", "Kill Sound Enabled", false), D("sy.kill_sound_preset", "Kill Sound Preset", { "Fatality", "Headshot", "Skeet", "Oof" }),
        S("sy.sound_volume", "Sound Volume", 0.1, 2.0, 1.0, nil, 0.1), T("sy.world_marker_enabled", "3D World Hitmarker", false),
        C("sy.world_marker_color", "Marker Color", rgb(0,162,255)),
    } },
    { title = "Sleepy · Target HUD", col = 2, rows = {
        T("sy.target_hud", "Enable Target Info HUD", false), T("sy.target_hud_preview", "Preview While Menu Open", false),
        S("sy.target_hud_scale", "HUD Scale", 0.5, 2.0, 1.0, nil, 0.05),
    } },
})

buildPage("World", {
    { title = "Scene", col = 1, rows = {
        D("world.env", "Environment", { "Default", "Night", "Soft", "Neon" }), S("world.brightness", "Brightness", 20, 100, 70),
        T("world.grid", "Grid Floor", true), C("world.tint", "Ambient Tint", rgb(255,255,255)),
    } },
    { title = "Camera / Lighting", col = 1, rows = {
        T("world.fovon", "Camera FOV", false), S("world.fov", "Field of View", 30, 120, 70),
        T("world.fullbright", "Fullbright", false), T("world.nofog", "No Fog", false),
    } },
    { title = "Sleepy · Lighting", col = 2, rows = {
        T("sy.lighting_ambient_enabled", "Ambient Override", false), C("sy.lighting_ambient_color", "Ambient Color", rgb(150,150,150)),
        T("sy.lighting_brightness_enabled", "Override Brightness", false), S("sy.lighting_brightness_value", "Brightness", 0, 10, 2, nil, 0.1),
        T("sy.lighting_clocktime_enabled", "Override Time", false), S("sy.lighting_clocktime_value", "Time of Day", 0, 24, 14, nil, 0.5),
        T("sy.lighting_fog_enabled", "Custom Fog", false), C("sy.lighting_fog_color", "Fog Color", rgb(160,160,180)),
        S("sy.lighting_fog_start", "Fog Start", 0, 500, 0, nil, 10), S("sy.lighting_fog_end", "Fog End", 50, 3000, 1000, nil, 50),
        T("sy.lighting_shadows_enabled", "Global Shadows", false), S("sy.lighting_shadow_softness", "Shadow Softness", 0, 1, 0.5, nil, 0.05),
    } },
    { title = "Sleepy · Skybox", col = 2, rows = {
        T("sy.world_skybox_enabled", "Enable Skybox Override", false),
        D("sy.skybox_preset", "Skybox Preset", {
            "Synthwave","Purple Nebula","Vaporwave","Night Sky","Red Galaxy","Sunset","GreenHaze","Space2","PinkMountains","Valentines","PinkArt","PurplePlanet","Blizzard","Winter","FlamingSunset","Mountains","FPSBoost","AestheticMountains","BetterNight3","Galaxy2","Aesthetic3","PurpleSpace","Pink","PurpleNight","Flame","Galaxy3","Storm","Deep Space"
        }),
        T("sy.atmosphere_enabled", "Atmosphere Changer", false), C("sy.atmosphere_color", "Atmosphere Color", rgb(199,170,107)),
        S("sy.atmosphere_density", "Atmosphere Density", 0, 1, 0.3, nil, 0.05),
        S("sy.atmosphere_haze", "Atmosphere Haze", 0, 10, 1, nil, 0.5),
        T("sy.color_correction_enabled", "Color Correction", false), C("sy.cc_tint_color", "Tint Color", rgb(255,255,255)),
        S("sy.cc_saturation", "Saturation", -1, 2, 0, nil, 0.1), S("sy.cc_contrast", "Contrast", -1, 2, 0, nil, 0.1),
    } },
})

buildPage("Character", {
    { title = "Appearance", col = 1, rows = {
        C("char.skin", "Skin", rgb(226,190,150)), C("char.shirt", "Shirt", rgb(24,22,30)),
        C("char.pants", "Pants", rgb(70,76,66)), C("char.hair", "Hair", rgb(30,24,30)),
        T("char.sway", "Idle Sway", true), S("char.speed", "Sway Speed", 0.5, 4, 1.5, nil, 0.1), S("char.scale", "Model Scale", 60, 130, 100),
    } },
    { title = "Movement", col = 1, rows = {
        T("mv.speed", "Speed", false), S("mv.speedval", "Walk Speed", 16, 120, 40),
        D("mv.speedmode", "Speed Mode", { "WalkSpeed", "CFrame" }), T("mv.float", "Float", false),
        T("mv.jump", "Jump Power", false), S("mv.jumpval", "Jump Power Value", 50, 250, 90),
        T("mv.fly", "Fly", false), S("mv.flyspeed", "Fly Speed", 10, 150, 50),
        T("mv.infjump", "Infinite Jump", false), T("mv.bhop", "Bunny Hop", false), T("mv.noclip", "Noclip", false),
        T("fc.enabled", "Freecam", false), S("fc.speed", "Freecam Speed", 5, 200, 40),
    } },
    { title = "Sleepy · Movement", col = 2, rows = {
        T("sy.walk_speed_enabled", "WalkSpeed Multiplier", false), S("sy.walk_speed_mult", "Walk Speed Multiplier", 1.0, 10.0, 1.5, nil, 0.1),
        T("sy.noclip_enabled", "Noclip", false), T("sy.bhop_enabled", "Bhop", false),
        T("sy.flight_enabled", "Flight", false), S("sy.flight_speed", "Flight Speed", 25, 500, 100, nil, 25),
        T("sy.double_jump", "Infinite Double Jumps", false),
    } },
    { title = "Sleepy · Fake Position", col = 2, rows = {
        T("sy.fake_position_enabled", "Fake Position (Underground)", false),
        S("sy.fake_position_depth", "Underground Depth", 1.0, 25.0, 5.8, nil, 0.2),
    } },
})

buildPage("Misc", {
    { title = "Configs", col = 1, rows = {
        B("Save Config", "Save", function() saveNamedConfig(Settings["cfg.selected"] or "default"); notify("Configs", "Saved") end),
        B("Load Config", "Load", function() loadNamedConfig(Settings["cfg.selected"] or "default"); notify("Configs", "Loaded") end),
        T("cfg.autoload", "Auto Load Config", true),
        T("misc.notify", "Notifications", true), T("misc.loadnotify", "Load Toast", true),
        T("misc.silentload", "Silent Load", false), T("misc.antiafk", "Anti-AFK", false),
        T("misc.tips", "Tooltips", true), T("misc.togglenotify", "Module Toasts", false),
    } },
    { title = "Sleepy · Utilities", col = 2, rows = {
        T("sy.auto_loadout_enabled", "Auto Loadout (Pre-Round)", false),
        T("sy.staff_detector", "Detect Staff / Admins", false),
        B("Rejoin Server", "Rejoin", function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end) end),
        B("Server Hop", "Hop", function()
            pcall(function()
                local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
                for _, s in ipairs(servers.data or {}) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player); break end
                end
            end)
        end),
        B("Unload", "Unload", function() if getgenv().__LilacSleepyCleanup then getgenv().__LilacSleepyCleanup() end end),
    } },
    { title = "Sleepy · Cosmetics", col = 1, rows = {
        T("sy.show_cosmetics_changer", "Show Cosmetics Changer", true),
        B("Toggle Cosmetics Changer", "Toggle", function()
            if shared.SleepyState and shared.SleepyState.CosmeticChanger then
                shared.SleepyState.CosmeticChanger()
            else
                notify("Cosmetics", "Changer not ready")
            end
        end),
    } },
    { title = "Settings", col = 2, rows = {
        K("set.menukey", "Menu Key", "RightShift"), S("set.scale", "Interface Scale", 70, 120, 100),
        T("set.lock", "Lock Window", false), T("set.confirm", "Confirm Resets", true),
        T("set.cursor", "Custom Cursor", true), T("set.preview", "Show Live Preview", platform == "PC"),
    } },
})

-- nav buttons
local navButtons = {}
local function styleNav()
    for name, nb in pairs(navButtons) do
        local a = name == currentTab
        tween(nb.btn, { BackgroundTransparency = a and 0 or 1 }, 0.15)
        tween(nb.stroke, { Transparency = a and 0.05 or 1 }, 0.15)
        nb.label.TextColor3 = a and Theme.Text or Theme.Muted
    end
end
local function selectTab(name)
    currentTab = name
    pageTitle.Text = name
    searchBox.Text = ""
    for n, s in pairs(pages) do s.Visible = n == name end
    styleNav()
end
local function makeIcon(kind, parent)
    local holder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 20) }, parent)
    local f = create("Frame", { BackgroundColor3 = Theme.Muted, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(10, 10), Rotation = 45 }, holder)
    corner(f, 2)
    return holder, function(c) f.BackgroundColor3 = c end
end
for i, name in ipairs(tabOrder) do
    local btn = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.CardHead, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, isMobile and 34 or 42), LayoutOrder = i, BorderSizePixel = 0 }, navHolder)
    corner(btn, 12)
    local st = stroke(btn, Theme.Accent, 1.5, 1)
    local ic, setIc = makeIcon(name, btn)
    ic.Position = UDim2.new(0, 14, 0.5, -10)
    local lb = text(btn, name, 13, Theme.Muted, BODY)
    lb.Position = UDim2.fromOffset(46, 0); lb.Size = UDim2.new(1, -50, 1, 0)
    navButtons[name] = { btn = btn, stroke = st, label = lb, icon = setIc }
    btn.Activated:Connect(function() selectTab(name) end)
end
selectTab("Combat")

-- ---------------------------------------------------------------------------
-- search filter
-- ---------------------------------------------------------------------------
connect(searchBox:GetPropertyChangedSignal("Text"), function()
    local q = searchBox.Text:lower()
    for _, r in ipairs(allRows) do
        r.frame.Visible = q == "" or (r.frame:GetAttribute("Search") or ""):find(q, 1, true) ~= nil
    end
end)

-- ---------------------------------------------------------------------------
-- named configs
-- ---------------------------------------------------------------------------
local CFG_DIR = "LilacSleepy/configs"
local function ensureDir()
    if type(makefolder) ~= "function" then return end
    pcall(function()
        if type(isfolder) == "function" and not isfolder("LilacSleepy") then makefolder("LilacSleepy") end
        if type(isfolder) == "function" and not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
    end)
end
local function serialize()
    local out = {}
    for k, v in pairs(Settings) do
        if typeof(v) == "Color3" then out[k] = hex(v) else out[k] = v end
    end
    return HttpService:JSONEncode(out)
end
local function importConfig(str)
    local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
    if not ok or type(data) ~= "table" then return false end
    for k, v in pairs(data) do
        local cur = Settings[k]
        if cur ~= nil then
            local t = typeof(cur)
            if t == "Color3" and type(v) == "string" then
                local ok2, c = pcall(Color3.fromHex, v); if ok2 and c then applySetting(k, c) end
            elseif t == type(v) and (t == "boolean" or t == "number" or t == "string") then
                applySetting(k, v)
            end
        end
    end
    return true
end
function saveNamedConfig(name)
    ensureDir()
    name = tostring(name or "default"):gsub("[^%w%-_ ]", ""):sub(1, 32)
    if name == "" then name = "default" end
    if type(writefile) ~= "function" then return false end
    local ok = pcall(writefile, CFG_DIR .. "/" .. name .. ".json", serialize())
    return ok
end
function loadNamedConfig(name)
    ensureDir()
    name = tostring(name or "default"):gsub("[^%w%-_ ]", ""):sub(1, 32)
    if name == "" then name = "default" end
    local path = CFG_DIR .. "/" .. name .. ".json"
    if type(readfile) ~= "function" then return false end
    if type(isfile) == "function" and not isfile(path) then return false end
    local ok, body = pcall(readfile, path)
    if not ok or type(body) ~= "string" then return false end
    return importConfig(body)
end

-- ---------------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------------
local toastHolder = create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.fromOffset(300, 400), ZIndex = 50 }, hudGui)
create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, toastHolder)
local toastCount = 0
function notify(title, msg)
    if Settings["misc.notify"] == false then return end
    toastCount += 1
    local holder = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(290, 56), LayoutOrder = toastCount, ZIndex = 50 }, toastHolder)
    local card = create("Frame", { BackgroundColor3 = Theme.Card, Position = UDim2.fromOffset(320, 0), Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 51 }, holder)
    corner(card, 11); stroke(card, Theme.Border, 1)
    local bar = create("Frame", { BackgroundColor3 = Theme.Accent, Position = UDim2.fromOffset(8, 12), Size = UDim2.new(0, 3, 1, -24), BorderSizePixel = 0, ZIndex = 52 }, card)
    round(bar)
    local t = text(card, title, 12, Theme.Text, HEAD); t.Position = UDim2.fromOffset(22, 8); t.Size = UDim2.new(1, -30, 0, 18); t.ZIndex = 52
    local m = text(card, msg, 11, Theme.Muted, LIGHT); m.Position = UDim2.fromOffset(22, 28); m.Size = UDim2.new(1, -30, 0, 16); m.ZIndex = 52
    tween(card, { Position = UDim2.fromOffset(0, 0) }, 0.35, Enum.EasingStyle.Back)
    task.delay(3.2, function()
        if card.Parent then
            tween(card, { Position = UDim2.fromOffset(320, 0) }, 0.3)
            task.wait(0.32); holder:Destroy()
        end
    end)
end

-- ---------------------------------------------------------------------------
-- open / close
-- ---------------------------------------------------------------------------
local openToken = 0
function Menu.setOpen(open)
    if Menu.open == open then return end
    Menu.open = open
    openToken += 1
    local my = openToken
    dim.Modal = open
    if open then
        root.Visible = true; dim.Visible = true
        animVal.Value = 0.92; tween(animVal, { Value = 1 }, 0.32, Enum.EasingStyle.Back)
        dim.BackgroundTransparency = 1; tween(dim, { BackgroundTransparency = 0.45 }, 0.25)
    else
        tween(animVal, { Value = 0.94 }, 0.14); tween(dim, { BackgroundTransparency = 1 }, 0.14)
        task.delay(0.16, function() if my == openToken then root.Visible = false; dim.Visible = false; animVal.Value = 1 end end)
    end
end
connect(UserInputService.InputBegan, function(i)
    if UserInputService:GetFocusedTextBox() then return end
    if i.KeyCode.Name == Settings["set.menukey"] or i.KeyCode == Enum.KeyCode.ButtonSelect then
        Menu.setOpen(not Menu.open)
    end
end)
Menu.setOpen(true)

-- ---------------------------------------------------------------------------
-- shared combat state
-- ---------------------------------------------------------------------------
shared.LilacState = {
    Settings = Settings, Theme = Theme, gui = gui, hudGui = hudGui,
    track = { part = nil, plr = nil, mode = nil }, Menu = Menu,
    notify = notify, connections = connections, cleanups = cleanups,
}

-- ---------------------------------------------------------------------------
-- combat engine — targeting, aimbot, silent, ragebot, triggerbot
-- ---------------------------------------------------------------------------
do
    local lp = player
    local cam = workspace.CurrentCamera
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function() cam = workspace.CurrentCamera end)

    local function myChar() return lp.Character end
    local function myHum() local c = myChar(); return c and c:FindFirstChildOfClass("Humanoid") end
    local function myRoot() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end
    local function sameTeam(p) return lp.Team ~= nil and p.Team == lp.Team end
    local function alive(p)
        local c = p.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        return c, h, (h ~= nil and h.Health > 0)
    end
    local function typing() return UserInputService:GetFocusedTextBox() ~= nil end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true
    local filterT = 0
    local function refreshFilter()
        local now = os.clock(); if now - filterT < 0.2 then return end
        filterT = now
        local list = {}
        for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then list[#list+1] = pl.Character end end
        rayParams.FilterDescendantsInstances = list
    end
    local function visibleFrom(pos)
        local origin = cam.CFrame.Position
        return workspace:Raycast(origin, pos - origin, rayParams) == nil
    end

    local TORSO = { "UpperTorso", "Torso", "HumanoidRootPart" }
    local function firstOf(c, names) for _, n in ipairs(names) do local p = c:FindFirstChild(n); if p and p:IsA("BasePart") then return p end end end
    local function partList(c, mode)
        local out = {}
        local head = c:FindFirstChild("Head")
        local torso = firstOf(c, TORSO)
        if mode == "Head" then if head then out[1] = head end
        elseif mode == "Torso" then if torso then out[1] = torso end
        else
            if head then out[#out+1] = head end
            if torso then out[#out+1] = torso end
            if mode == "Hitscan" then
                for _, n in ipairs({ "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
                    local p = c:FindFirstChild(n); if p and p:IsA("BasePart") and p ~= torso then out[#out+1] = p end
                end
            end
        end
        return out
    end

    local function pxToDeg(px)
        local vs = cam.ViewportSize
        local focal = (vs.Y / 2) / math.tan(math.rad(cam.FieldOfView) / 2)
        return math.deg(math.atan(px / focal))
    end
    local function angleTo(ray, pos)
        local d = pos - cam.CFrame.Position
        if d.Magnitude < 0.01 then return 180 end
        return math.deg(math.acos(math.clamp(ray:Dot(d.Unit), -1, 1)))
    end
    local function aimRef()
        local vs = cam.ViewportSize
        local firstPerson = (cam.Focus.Position - cam.CFrame.Position).Magnitude < 1.5
        if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter or firstPerson or activePlat ~= "PC" then
            return Vector2.new(vs.X / 2, vs.Y / 2), true
        end
        return UserInputService:GetMouseLocation(), false
    end

    local function targetOk(plr, c, hum, p)
        if not hum or hum.Health <= 0 then return false end
        if Settings[p .. ".team"] and sameTeam(plr) then return false end
        if Settings[p .. ".hpcheck"] then
            if c:FindFirstChildOfClass("ForceField") then return false end
        end
        return true
    end

    local function findTarget(p, fovDeg)
        refreshFilter()
        local ref = aimRef()
        local ray = cam:ViewportPointToRay(ref.X, ref.Y).Direction.Unit
        local camPos = cam.CFrame.Position
        local maxD = Settings[p .. ".maxdist"] or 1000
        local pred = Settings[p .. ".pred"] or 0
        local mode = Settings[p .. ".bone"] or "Head"
        local prio = Settings[p .. ".priority"] or "Crosshair"
        if p == "silent" and mode == "Closest" then mode = "Hitscan" end
        local best, bestScore, bestPlr
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp then
                local c, hum, ok = alive(plr)
                if ok and targetOk(plr, c, hum, p) then
                    local chosen, chosenAng
                    for _, part in ipairs(partList(c, mode)) do
                        local pos = part.Position + part.AssemblyLinearVelocity * pred
                        local dist = (pos - camPos).Magnitude
                        if dist <= maxD then
                            local ang = angleTo(ray, pos)
                            if ang <= fovDeg and ((not Settings[p .. ".wall"]) or visibleFrom(part.Position)) then
                                if mode == "Hitscan" then chosen, chosenAng = part, ang; break end
                                if not chosenAng or ang < chosenAng then chosen, chosenAng = part, ang end
                            end
                        end
                    end
                    if chosen then
                        local score
                        if prio == "Distance" then score = (chosen.Position - camPos).Magnitude
                        elseif prio == "Lowest HP" then score = hum.Health
                        elseif prio == "Highest HP" then score = -hum.Health
                        else score = chosenAng end
                        if not bestScore or score < bestScore then best, bestScore, bestPlr = chosen, score, plr end
                    end
                end
            end
        end
        return best, bestPlr
    end

    local toggled = { aim = false, silent = false, trig = false, rage = false }
    local touchHeld = { aim = false, silent = false, trig = false, rage = false }
    local function modeActive(p)
        local mode = Settings[p .. ".mode"]
        if mode == "Always" then return true end
        if mode == "Toggle" then return toggled[p] end
        return UserInputService:IsKeyDown(pcall(function() return Enum.KeyCode[Settings[p .. ".key"]] end) and Enum.KeyCode[Settings[p .. ".key"]] or Enum.KeyCode.Unknown) or touchHeld[p]
    end
    connect(UserInputService.InputBegan, function(i)
        if typing() or Menu.open then return end
        for p in pairs(toggled) do
            if Settings[p .. ".mode"] == "Toggle" and i.KeyCode.Name == Settings[p .. ".key"] then
                toggled[p] = not toggled[p]
            end
        end
    end)

    local lastAim = 0
    local sticky, stickyPlr, prevTarget = nil, nil, nil
    local lastFire = 0
    local function fireTool(delay)
        local ch = myChar()
        local tool = ch and ch:FindFirstChildOfClass("Tool")
        if tool then
            lastFire = os.clock()
            tool:Activate()
            task.delay(0.04, function() if tool.Parent then tool:Deactivate() end end)
        end
    end
    local function aimStep(which)
        local now = os.clock()
        local dtA = math.min(now - lastAim, 0.1)
        lastAim = now
        local p
        if not Menu.open and not typing() then
            if Settings["rage.enabled"] and modeActive("rage") then p = "rage"
            elseif Settings["silent.enabled"] and modeActive("silent") then p = "silent"
            elseif Settings["aim.enabled"] and modeActive("aim") then p = "aim" end
        end
        if not p then
            sticky, stickyPlr, prevTarget = nil, nil, nil
            shared.LilacState.track.part, shared.LilacState.track.plr, shared.LilacState.track.mode = nil, nil, nil
            return
        end
        local fovDeg = p == "rage" and Settings["rage.fov"]
            or pxToDeg(p == "silent" and Settings["silent.fov"] or Settings["fov.size"])
        local target, plr
        if (p == "aim" or p == "silent") and Settings[p .. ".sticky"] and sticky and sticky.Parent then
            target, plr = sticky, stickyPlr
        else
            target, plr = findTarget(p, fovDeg)
        end
        if p == "aim" or p == "silent" then sticky, stickyPlr = target, plr end
        if target ~= prevTarget then prevTarget = target end
        shared.LilacState.track.part, shared.LilacState.track.plr, shared.LilacState.track.mode = target, plr, target and p or nil
        if not target then return end

        local cf = cam.CFrame
        local pred = Settings[p .. ".pred"] or 0
        local aimPos = target.Position + target.AssemblyLinearVelocity * pred
        local newDir = aimPos - cf.Position
        if newDir.Magnitude < 1e-4 then return end
        newDir = newDir.Unit
        local method = p == "rage" and "Camera" or Settings["aim.method"]
        local smooth = p == "rage" and 1 or math.max((Settings["aim.smooth"] or 35) / 10, 0.1)
        if p == "silent" then smooth = math.max((Settings["silent.smooth"] or 12) / 5, 0.15) end
        local alpha = smooth <= 0.15 and 1 or (1 - math.exp(-dtA * 40 / smooth))
        local under = cam.CFrame.LookVector
        local axis = under:Cross(newDir)
        local angle = math.acos(math.clamp(under:Dot(newDir), -1, 1))
        if axis.Magnitude > 1e-5 and angle > 1e-4 then
            local rot = CFrame.fromAxisAngle(axis.Unit, angle * alpha)
            cam.CFrame = CFrame.new(cf.Position) * rot * (cf - cf.Position)
        end
        if p == "silent" and Settings["silent.autofire"] and now - lastFire >= (Settings["silent.firerate"] or 90) / 1000 then fireTool() end
        if p == "rage" and Settings["rage.autofire"] and now - lastFire >= Settings["rage.firerate"] / 1000 then fireTool() end
    end
    RunService:BindToRenderStep("LilacSleepyAim", Enum.RenderPriority.Camera.Value + 1, function() aimStep("Early") end)
    cleanup(function() RunService:UnbindFromRenderStep("LilacSleepyAim") end)

    local trigBusy = false
    local function trigStep()
        if not Settings["trig.enabled"] or trigBusy or Menu.open or typing() or not modeActive("trig") then return end
        local ref = aimRef()
        local ray = cam:ViewportPointToRay(ref.X, ref.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { myChar() }
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if not hit then return end
        local model = hit.Instance:FindFirstAncestorOfClass("Model")
        local plr = model and Players:GetPlayerFromCharacter(model)
        if not plr or plr == lp then return end
        local c, hum, ok = alive(plr)
        local ch = myChar()
        local tool = ch and ch:FindFirstChildOfClass("Tool")
        if ok and tool and targetOk(plr, c, hum, "trig") then
            trigBusy = true
            task.delay(Settings["trig.delay"] / 1000, function()
                if tool.Parent then
                    tool:Activate(); task.wait(0.04); if tool.Parent then tool:Deactivate() end
                end
                task.wait(0.08); trigBusy = false
            end)
        end
    end
    RunService:BindToRenderStep("LilacSleepyTrig", Enum.RenderPriority.Last.Value, trigStep)
    cleanup(function() RunService:UnbindFromRenderStep("LilacSleepyTrig") end)
end

-- ---------------------------------------------------------------------------
-- ESP engine
-- ---------------------------------------------------------------------------
do
    local lp = player
    local cam = workspace.CurrentCamera
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function() cam = workspace.CurrentCamera end)
    local worldLayer = create("Frame", { Name = "World", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 1, Active = false }, hudGui)

    local function myChar() return lp.Character end
    local function sameTeam(p) return lp.Team ~= nil and p.Team == lp.Team end
    local function lineBetween(f, a, b, th, col)
        local d = b - a
        f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
        f.Size = UDim2.fromOffset(d.Magnitude, th)
        f.Rotation = math.deg(math.atan2(d.Y, d.X))
        if col then f.BackgroundColor3 = col end
    end

    local espObjs = {}
    local BONES_R15 = {
        { "Head", "UpperTorso", 1 }, { "UpperTorso", "LowerTorso", 1 },
        { "UpperTorso", "LeftUpperArm", 2 }, { "LeftUpperArm", "LeftLowerArm", 2 }, { "LeftLowerArm", "LeftHand", 2 },
        { "UpperTorso", "RightUpperArm", 2 }, { "RightUpperArm", "RightLowerArm", 2 }, { "RightLowerArm", "RightHand", 2 },
        { "LowerTorso", "LeftUpperLeg", 3 }, { "LeftUpperLeg", "LeftLowerLeg", 3 }, { "LeftLowerLeg", "LeftFoot", 3 },
        { "LowerTorso", "RightUpperLeg", 3 }, { "RightUpperLeg", "RightLowerLeg", 3 }, { "RightLowerLeg", "RightFoot", 3 },
    }
    local BONES_R6 = {
        { "Head", "Torso", 1 }, { "Torso", "Left Arm", 2 }, { "Torso", "Right Arm", 2 },
        { "Torso", "Left Leg", 3 }, { "Torso", "Right Leg", 3 },
    }

    local function destroyEsp(o)
        for _, k in ipairs({ "hl", "holder", "tracer", "lookLine", "lookDot", "arrow" }) do
            if o[k] then o[k]:Destroy() end
        end
        for _, f in pairs(o.headM) do if typeof(f) == "Instance" then f:Destroy() end end
        for _, f in ipairs(o.bones) do f:Destroy() end
    end
    local function buildEsp(plr, c)
        local rootPart = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not rootPart or not hum then return nil end
        local o = { char = c, root = rootPart, hum = hum, bones = {} }
        o.hl = create("Highlight", { Adornee = c, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false }, c)
        o.holder = create("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, worldLayer)
        o.box = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, o.holder)
        o.boxStroke = stroke(o.box, Color3.new(1, 1, 1), 1)
        o.corners = {}
        for _, a in ipairs({ {0,0}, {1,0}, {0,1}, {1,1} }) do
            for _, h in ipairs({ true, false }) do
                local f = create("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(a[1], a[2]), Position = UDim2.fromScale(a[1], a[2]), Visible = false }, o.holder)
                table.insert(o.corners, { f = f, h = h })
            end
        end
        o.hpBack = create("Frame", { BackgroundColor3 = Color3.fromRGB(10,8,12), BorderSizePixel = 0 }, o.holder)
        o.hpFill = create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, o.hpBack)
        o.hpGrad = create("UIGradient", { Rotation = 90, Enabled = false }, o.hpFill)
        local function lbl(p)
            return create("TextLabel", { BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(1,1,1), TextStrokeColor3 = Color3.new(0,0,0) }, p)
        end
        o.name = lbl(o.holder); o.name.AnchorPoint = Vector2.new(0.5, 1); o.name.Position = UDim2.new(0.5, 0, 0, -2)
        o.hpTxt = lbl(o.holder); o.hpTxt.AnchorPoint = Vector2.new(1, 0.5); o.hpTxt.TextXAlignment = Enum.TextXAlignment.Right
        o.info = create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 2), Size = UDim2.fromOffset(220, 0), AutomaticSize = Enum.AutomaticSize.Y }, o.holder)
        create("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, o.info)
        o.weapon, o.ammo, o.dist = lbl(o.info), lbl(o.info), lbl(o.info)
        o.weapon.LayoutOrder, o.ammo.LayoutOrder, o.dist.LayoutOrder = 1, 2, 3
        o.tracer = create("Frame", { BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false }, worldLayer)
        local function sq() return create("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false }, worldLayer) end
        o.headM = { h = sq(), v = sq(), circle = sq(), square = sq() }
        round(o.headM.circle); corner(o.headM.square, 1)
        o.headM.circleStroke = stroke(o.headM.circle, Color3.new(1,1,1), 1)
        o.headM.squareStroke = stroke(o.headM.square, Color3.new(1,1,1), 1)
        o.lookLine = sq(); o.lookDot = sq(); o.lookDot.Size = UDim2.fromOffset(6, 6); round(o.lookDot)
        return o
    end
    local function hideEsp(o)
        o.hl.Enabled = false
        o.holder.Visible = false
        o.tracer.Visible = false
        o.lookLine.Visible = false
        o.lookDot.Visible = false
        for _, f in pairs(o.headM) do if typeof(f) == "Instance" and f:IsA("GuiObject") then f.Visible = false end end
        for _, f in ipairs(o.bones) do f.Visible = false end
    end
    local function projectBox(o)
        local c, hum = o.char, o.hum
        local head = c:FindFirstChild("Head")
        local rp = o.root.Position
        local top = head and (head.Position + Vector3.new(0, head.Size.Y / 2 + 0.15, 0)) or (rp + Vector3.new(0, 2.7, 0))
        local feetOff = (hum.RigType == Enum.HumanoidRigType.R6) and 3 or (hum.HipHeight + o.root.Size.Y / 2)
        local bottom = rp - Vector3.new(0, feetOff, 0)
        local t = cam:WorldToViewportPoint(top)
        local b = cam:WorldToViewportPoint(bottom)
        if t.Z <= 0 or b.Z <= 0 then return nil end
        local h = math.max(math.abs(b.Y - t.Y), 6)
        local w = h * 0.55
        local cx = (t.X + b.X) / 2
        return cx - w / 2, math.min(t.Y, b.Y), w, h, Vector2.new(b.X, b.Y)
    end
    local function updateEsp(plr, o, t)
        local S = Settings
        local d = (cam.CFrame.Position - o.root.Position).Magnitude
        if d > S["esp.maxdist"] then hideEsp(o); return end
        o.hl.Enabled = S["esp.highlight"]
        o.hl.FillColor = S["cham.fill"]
        o.hl.FillTransparency = 1 - S["cham.opacity"] / 100
        o.hl.OutlineColor = S["cham.outline"]
        o.hl.OutlineTransparency = S["cham.pulse"] and (0.45 + 0.35 * math.sin(t * 3)) or 0
        local bx, by, bw, bh, feet = projectBox(o)
        if not bx then hideEsp(o); return end
        o.holder.Visible = true
        o.holder.Position = UDim2.fromOffset(bx, by)
        o.holder.Size = UDim2.fromOffset(bw, bh)
        local th = S["bars.boxthick"]
        local asCorners = S["bars.boxstyle"] == "Corners"
        local cl = math.clamp(bw * 0.28, 5, 22)
        o.box.Visible = S["esp.box"]
        o.boxStroke.Enabled = not asCorners
        o.boxStroke.Thickness = th
        o.boxStroke.Color = S["bars.boxcolor"]
        o.box.BackgroundColor3 = S["bars.fillcolor"]
        o.box.BackgroundTransparency = S["bars.fillbox"] and (1 - S["bars.fillopacity"] / 100) or 1
        for _, c in ipairs(o.corners) do
            c.f.Visible = S["esp.box"] and asCorners
            c.f.BackgroundColor3 = S["bars.boxcolor"]
            c.f.Size = c.h and UDim2.fromOffset(cl, th) or UDim2.fromOffset(th, cl)
        end
        local font, ts = FontMap[S["fmt.font"]] or BODY, S["fmt.size"]
        local tst = S["fmt.outline"] and 0.35 or 1
        for _, l in ipairs({ o.name, o.hpTxt, o.weapon, o.ammo, o.dist }) do
            l.Font, l.TextSize, l.TextColor3, l.TextStrokeTransparency = font, ts, S["fmt.color"], tst
        end
        o.name.Visible = S["esp.names"]
        o.name.Text = plr.DisplayName .. ((S["esp.team"] and sameTeam(plr)) and " [TEAM]" or "")
        o.name.Size = UDim2.fromOffset(220, ts + 6)
        local tool = o.char:FindFirstChildOfClass("Tool")
        o.weapon.Visible = S["esp.weapon"]; o.weapon.Text = tool and tool.Name or "None"
        o.ammo.Visible = S["esp.ammo"]; o.ammo.Text = tool and tostring(tool:GetAttribute("Ammo") or "-") or "-"
        o.dist.Visible = S["esp.distance"]
        o.dist.Text = S["fmt.unit"] == "Meters" and string.format("%d m", math.floor(d * 0.28 + 0.5)) or string.format("%d studs", math.floor(d + 0.5))
        for _, l in ipairs({ o.weapon, o.ammo, o.dist }) do l.Size = UDim2.new(1, 0, 0, ts + 4) end
        local hp = math.clamp(o.hum.Health / math.max(o.hum.MaxHealth, 1), 0, 1)
        local hw = S["bars.width"]
        local col = S["bars.low"]:Lerp(S["bars.high"], hp)
        o.hpBack.Visible = S["esp.vhealth"]
        o.hpBack.Size = UDim2.new(0, hw, 1, 0)
        o.hpBack.Position = UDim2.new(0, -4 - hw, 0, 0)
        o.hpFill.Size = UDim2.fromScale(1, hp)
        o.hpGrad.Enabled = S["bars.gradient"]
        o.hpGrad.Color = ColorSequence.new(S["bars.high"], S["bars.low"])
        o.hpFill.BackgroundColor3 = S["bars.gradient"] and Color3.new(1,1,1) or col
        o.hpTxt.Visible = S["esp.healthinfo"]
        o.hpTxt.Text = tostring(math.floor(o.hum.Health))
        o.hpTxt.TextColor3 = col
        o.hpTxt.Size = UDim2.fromOffset(34, ts + 2)
        o.hpTxt.Position = UDim2.new(0, -8 - (S["esp.vhealth"] and hw or 0), 1 - hp, 0)
        if S["tr.enabled"] then
            local vs = cam.ViewportSize
            local origin = Vector2.new(vs.X / 2, vs.Y)
            if S["tr.origin"] == "Center" then origin = vs / 2 elseif S["tr.origin"] == "Top" then origin = Vector2.new(vs.X / 2, 0) end
            o.tracer.Visible = true
            lineBetween(o.tracer, origin, feet, S["tr.thick"], S["tr.color"])
        else o.tracer.Visible = false end
        local sk = S["skel.enabled"]
        local list = o.char:FindFirstChild("UpperTorso") and BONES_R15 or BONES_R6
        local cols = { S["skel.c1"], S["skel.c2"], S["skel.c3"] }
        for idx, bn in ipairs(list) do
            local fr = o.bones[idx]
            if not fr then
                fr = create("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false }, worldLayer)
                o.bones[idx] = fr
            end
            local p1, p2 = o.char:FindFirstChild(bn[1]), o.char:FindFirstChild(bn[2])
            if sk and p1 and p2 then
                local a = cam:WorldToViewportPoint(p1.Position)
                local c2 = cam:WorldToViewportPoint(p2.Position)
                if a.Z > 0 and c2.Z > 0 then
                    lineBetween(fr, Vector2.new(a.X, a.Y), Vector2.new(c2.X, c2.Y), S["skel.thick"], cols[bn[3]])
                    fr.Visible = true
                else fr.Visible = false end
            else fr.Visible = false end
        end
        for idx = #list + 1, #o.bones do o.bones[idx].Visible = false end
        local M = o.headM
        local headPart = o.char:FindFirstChild("Head")
        local showHead = false
        if S["head.enabled"] and headPart then
            local v = cam:WorldToViewportPoint(headPart.Position)
            if v.Z > 0 then
                showHead = true
                local px = 4 + S["head.size"] * 2.2
                local ht, hc, shape, fillOn = S["head.thick"], S["head.color"], S["head.shape"], S["head.fill"]
                local pos = UDim2.fromOffset(v.X, v.Y)
                M.h.Position, M.v.Position, M.circle.Position, M.square.Position = pos, pos, pos, pos
                M.h.Visible, M.v.Visible = shape == "Cross", shape == "Cross"
                M.h.BackgroundColor3, M.v.BackgroundColor3 = hc, hc
                M.h.Size, M.v.Size = UDim2.fromOffset(px, ht), UDim2.fromOffset(ht, px)
                M.circle.Visible = shape == "Circle"
                M.circle.Size = UDim2.fromOffset(px, px)
                M.circle.BackgroundColor3 = hc
                M.circle.BackgroundTransparency = fillOn and 0 or 1
                M.circleStroke.Thickness, M.circleStroke.Color = ht, hc
                M.square.Visible = shape == "Square"
                M.square.Size = UDim2.fromOffset(px, px)
                M.square.BackgroundColor3 = hc
                M.square.BackgroundTransparency = fillOn and 0 or 1
                M.squareStroke.Thickness, M.squareStroke.Color = ht, hc
            end
        end
        if not showHead then
            M.h.Visible, M.v.Visible, M.circle.Visible, M.square.Visible = false, false, false, false
        end
        local lookShown = false
        if S["esp.look"] and headPart then
            local a = cam:WorldToViewportPoint(headPart.Position)
            local b = cam:WorldToViewportPoint(headPart.Position + headPart.CFrame.LookVector * 4)
            if a.Z > 0 and b.Z > 0 then
                lookShown = true
                lineBetween(o.lookLine, Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), 1.5, Theme.Accent)
                o.lookDot.Position = UDim2.fromOffset(b.X, b.Y)
                o.lookDot.BackgroundColor3 = Theme.Accent
            end
        end
        o.lookLine.Visible, o.lookDot.Visible = lookShown, lookShown
    end
    local function espStep()
        local S = Settings
        local t = os.clock()
        local want = S["live.esp"] and S["esp.enabled"]
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp then
                local o = espObjs[plr]
                local c, _, ok = alive(plr)
                if o and o.char ~= c then destroyEsp(o); o = nil; espObjs[plr] = nil end
                if want and c and ok then
                    if not o then o = buildEsp(plr, c); espObjs[plr] = o end
                    if o then
                        if sameTeam(plr) and not S["esp.team"] then hideEsp(o)
                        else pcall(updateEsp, plr, o, t) end
                    end
                elseif o then hideEsp(o) end
            end
        end
        for plr, o in pairs(espObjs) do if not plr.Parent then destroyEsp(o); espObjs[plr] = nil end end
    end
    cleanup(function() for _, o in pairs(espObjs) do destroyEsp(o) end; table.clear(espObjs) end)
    RunService:BindToRenderStep("LilacSleepyESP", Enum.RenderPriority.Last.Value + 1, espStep)
    cleanup(function() RunService:UnbindFromRenderStep("LilacSleepyESP") end)
end

-- ---------------------------------------------------------------------------
-- movement / world / hitbox / misc engine
-- ---------------------------------------------------------------------------
do
    local lp = player
    local cam = workspace.CurrentCamera
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function() cam = workspace.CurrentCamera end)
    local function myChar() return lp.Character end
    local function myHum() local c = myChar(); return c and c:FindFirstChildOfClass("Humanoid") end
    local function myRoot() local c = myChar(); return c and c:FindFirstChild("HumanoidRootPart") end

    local ovr = {}
    local function ovSet(group, inst, prop, val)
        local g = ovr[group]; if not g then g = {}; ovr[group] = g end
        local found
        for _, e in ipairs(g) do if e.inst == inst and e.prop == prop then found = e; break end end
        if not found then g[#g+1] = { inst = inst, prop = prop, orig = inst[prop] } end
        inst[prop] = val
    end
    local function ovRestore(group)
        local g = ovr[group]; if not g then return end
        for _, e in ipairs(g) do pcall(function() e.inst[e.prop] = e.orig end) end
        ovr[group] = nil
    end
    cleanup(function() for g in pairs(ovr) do ovRestore(g) end end)

    local origHB = {}
    local function restoreHB()
        for part, o in pairs(origHB) do if part.Parent then part.Size, part.Transparency, part.CanCollide = o.size, o.trans, o.collide end end
        table.clear(origHB)
    end
    cleanup(restoreHB)

    local noclipSaved = {}
    connect(RunService.Stepped, function()
        local c = myChar()
        if Settings["mv.noclip"] and c then
            for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then noclipSaved[p] = true; p.CanCollide = false end end
        elseif next(noclipSaved) then
            for p in pairs(noclipSaved) do if p.Parent then p.CanCollide = true end end
            table.clear(noclipSaved)
        end
    end)

    connect(UserInputService.JumpRequest, function()
        if Settings["mv.infjump"] then local h = myHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
    end)
    connect(lp.Idled, function()
        if Settings["misc.antiafk"] then
            local ok, vu = pcall(function() return game:GetService("VirtualUser") end)
            if ok and vu then vu:CaptureController(); vu:ClickButton2(Vector2.new()) end
        end
    end)

    -- lighting helpers
    local fxObjs = {}
    local function fxGet(cls, name)
        local o = fxObjs[name]
        if not o or not o.Parent then o = Instance.new(cls); o.Name = name; o.Parent = Lighting; fxObjs[name] = o end
        return o
    end
    local function fxDrop(name) local o = fxObjs[name]; if o then o:Destroy(); fxObjs[name] = nil end end
    cleanup(function() for n in pairs(fxObjs) do fxDrop(n) end end)

    local skyPresets = {
        Synthwave = { SkyboxUp = "rbxassetid://16642401907", SkyboxDn = "rbxassetid://16642397027", SkyboxBk = "rbxassetid://16642396302", SkyboxFt = "rbxassetid://16642398372", SkyboxLf = "rbxassetid://16642399309", SkyboxRt = "rbxassetid://16642400745" },
        ["Purple Nebula"] = { SkyboxUp = "rbxassetid://5084576400", SkyboxDn = "rbxassetid://5260653793", SkyboxFt = "rbxassetid://5260817288", SkyboxBk = "rbxassetid://5260808177", SkyboxLf = "rbxassetid://5260800833", SkyboxRt = "rbxassetid://5260800833" },
        Vaporwave = { SkyboxUp = "rbxassetid://14164405298", SkyboxDn = "rbxassetid://14164386126", SkyboxFt = "rbxassetid://14164389230", SkyboxBk = "rbxassetid://14164368678", SkyboxLf = "rbxassetid://14164398493", SkyboxRt = "rbxassetid://14164402782" },
        ["Night Sky"] = { SkyboxUp = "rbxassetid://2670644331", SkyboxDn = "rbxassetid://2670643365", SkyboxFt = "rbxassetid://2670643214", SkyboxBk = "rbxassetid://2670643994", SkyboxLf = "rbxassetid://2670643070", SkyboxRt = "rbxassetid://2670644173" },
        ["Red Galaxy"] = { SkyboxUp = "rbxassetid://14365019327", SkyboxDn = "rbxassetid://14365023350", SkyboxBk = "rbxassetid://14365019002", SkyboxFt = "rbxassetid://14365018399", SkyboxLf = "rbxassetid://14365018705", SkyboxRt = "rbxassetid://14365018143" },
        Sunset = { SkyboxUp = "rbxassetid://415688354", SkyboxDn = "rbxassetid://415688193", SkyboxBk = "rbxassetid://415688378", SkyboxFt = "rbxassetid://415688242", SkyboxLf = "rbxassetid://415688310", SkyboxRt = "rbxassetid://415688274" },
        GreenHaze = { SkyboxUp = "rbxassetid://160193458", SkyboxDn = "rbxassetid://160193466", SkyboxFt = "rbxassetid://160193461", SkyboxBk = "rbxassetid://160193404", SkyboxLf = "rbxassetid://160193469", SkyboxRt = "rbxassetid://160193463" },
        Space2 = { SkyboxUp = "rbxassetid://11844053742", SkyboxDn = "rbxassetid://11844069700", SkyboxFt = "rbxassetid://11844067209", SkyboxBk = "rbxassetid://11844076072", SkyboxLf = "rbxassetid://11844063543", SkyboxRt = "rbxassetid://11844058446" },
        PinkMountains = { SkyboxUp = "rbxassetid://160188588", SkyboxDn = "rbxassetid://160188614", SkyboxFt = "rbxassetid://160188609", SkyboxBk = "rbxassetid://160188495", SkyboxLf = "rbxassetid://160188589", SkyboxRt = "rbxassetid://160188597" },
    }
    local activeSky, origSky
    local function applySky(name)
        if not Settings["sy.world_skybox_enabled"] then
            if activeSky then activeSky:Destroy(); activeSky = nil end
            if origSky then origSky.Parent = Lighting; origSky = nil end
            return
        end
        local preset = skyPresets[name]
        if not preset then return end
        if not activeSky or not activeSky.Parent then
            local old = Lighting:FindFirstChildOfClass("Sky")
            if old and old.Name ~= "_LSky" then origSky = old; old.Parent = nil end
            activeSky = Instance.new("Sky"); activeSky.Name = "_LSky"; activeSky.Parent = Lighting
        end
        for prop, val in pairs(preset) do pcall(function() activeSky[prop] = val end) end
    end
    cleanup(function() if activeSky then activeSky:Destroy() end; if origSky then origSky.Parent = Lighting end end)

    local flyVel, fcState = nil, { on = false, yaw = 0, pitch = 0, pos = Vector3.zero, s1 = Vector2.zero, s2 = Vector2.zero, prevType = nil }
    local function stopFly() if flyVel then flyVel:Destroy(); flyVel = nil end end
    cleanup(stopFly)
    cleanup(function()
        if fcState.on then cam.CameraType = fcState.prevType or Enum.CameraType.Custom; ContextActionSvc:UnbindAction("LSAFreecam") end
    end)
    connect(UserInputService.InputChanged, function(i)
        if not fcState.on then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                fcState.yaw -= i.Delta.X * 0.0035
                fcState.pitch = math.clamp(fcState.pitch - i.Delta.Y * 0.0035, -1.5, 1.5)
            end
        elseif i.KeyCode == Enum.KeyCode.Thumbstick1 then fcState.s1 = Vector2.new(i.Position.X, i.Position.Y)
        elseif i.KeyCode == Enum.KeyCode.Thumbstick2 then fcState.s2 = Vector2.new(i.Position.X, i.Position.Y) end
    end)

    -- global anti-aim (Sleepy)
    local aaSaved, aaAng, aaFlip = nil, 0, false
    cleanup(function() local h = myHum(); if h and aaSaved ~= nil then h.AutoRotate = aaSaved end end)

    -- main loop
    connect(RunService.Heartbeat, function(dt)
        local S = Settings
        local hum, root = myHum(), myRoot()

        -- hitboxes
        if S["hb.enabled"] then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and (S["hb.team"] or not (lp.Team ~= nil and plr.Team == lp.Team)) then
                    local c = plr.Character
                    local r = c and c:FindFirstChild("HumanoidRootPart")
                    if r then
                        origHB[r] = origHB[r] or { size = r.Size, trans = r.Transparency, collide = r.CanCollide }
                        r.Size = Vector3.new(S["hb.size"], S["hb.size"], S["hb.size"])
                        r.Transparency, r.CanCollide = S["hb.trans"], false
                    end
                end
            end
        elseif next(origHB) then restoreHB() end

        if hum then
            if S["mv.speed"] and S["mv.speedmode"] == "WalkSpeed" then ovSet("speed", hum, "WalkSpeed", S["mv.speedval"])
            elseif ovr.speed then ovRestore("speed") end
            if S["mv.speed"] and S["mv.speedmode"] == "CFrame" and root then root.CFrame += hum.MoveDirection * math.max(S["mv.speedval"] - 16, 0) * dt end
            if S["mv.float"] and root then
                ovSet("float", workspace, "Gravity", 0)
                local v = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
            elseif ovr.float then ovRestore("float") end
            if S["mv.jump"] then
                ovSet("jump", hum, "UseJumpPower", true); ovSet("jump", hum, "JumpPower", S["mv.jumpval"])
            elseif ovr.jump then ovRestore("jump") end
            local jumpHeld = UserInputService:IsKeyDown(Enum.KeyCode.Space)
            if S["mv.bhop"] and jumpHeld then hum.Jump = true end
        end

        -- fly
        if S["mv.fly"] and root and hum then
            if not flyVel or flyVel.Parent ~= root then
                stopFly()
                flyVel = create("BodyVelocity", { MaxForce = Vector3.new(1e5, 1e5, 1e5), Velocity = Vector3.zero }, root)
            end
            local dir = hum.MoveDirection
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
            flyVel.Velocity = dir.Magnitude > 0.05 and dir.Unit * S["mv.flyspeed"] or Vector3.zero
        else stopFly() end

        -- sleepy movement
        if hum then
            if S["sy.walk_speed_enabled"] and S["sy.walk_speed_mult"] > 1.0 then
                hum.WalkSpeed = 16 * S["sy.walk_speed_mult"]
            end
            if S["sy.noclip_enabled"] then
                for _, p in ipairs(myChar():GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end
            end
        end
        if S["sy.flight_enabled"] and root then
            local mv = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mv -= Vector3.yAxis end
            root.Velocity = mv.Magnitude > 0 and mv.Unit * S["sy.flight_speed"] or Vector3.zero
        end
        if S["sy.double_jump"] then
            connect(UserInputService.JumpRequest, function()
                local h = myHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping); if root then root.Velocity = Vector3.new(root.Velocity.X, 50 * S["sy.double_jump_height"], root.Velocity.Z) end end
            end)
        end

        -- anti-aim
        local aaMode = S["rage.enabled"] and S["rage.aa"] or "Off"
        if aaMode ~= "Off" and root and hum and hum.Health > 0 then
            if aaSaved == nil then aaSaved = hum.AutoRotate end
            hum.AutoRotate = false
            local look = cam.CFrame.LookVector
            local base = math.atan2(-look.X, -look.Z)
            local yaw
            if aaMode == "Spin" then aaAng = (aaAng + dt * math.rad(S["rage.aaspeed"])) % (math.pi * 2); yaw = aaAng
            elseif aaMode == "Jitter" then aaFlip = not aaFlip; yaw = base + (aaFlip and 1 or -1) * math.rad(S["rage.aajit"])
            else yaw = base + math.pi end
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
        elseif aaSaved ~= nil then
            if hum then hum.AutoRotate = aaSaved end
            aaSaved = nil
        end

        -- sleepy yaw/pitch anti-aim
        if S["sy.antiaim_enabled"] and root then
            local yaw
            local yt = S["sy.yaw_type"]
            if yt == "Backwards" then yaw = 180
            elseif yt == "Left" then yaw = 90
            elseif yt == "Right" then yaw = -90
            elseif yt == "Spin" then aaAng = (aaAng + S["sy.rotation_speed"] * 10 * dt) % 360; yaw = aaAng
            elseif yt == "Sway" then aaAng = (aaAng + math.sin(os.clock()) * S["sy.rotation_speed"] * 4 * dt) % 360; yaw = 180 + aaAng
            elseif yt == "Jitter" then aaFlip = not aaFlip; yaw = aaFlip and (180 + S["sy.jitter_range"]) or (180 - S["sy.jitter_range"])
            elseif yt == "Random" then yaw = math.random(-180, 180)
            else yaw = 0 end
            if yt ~= "None" then
                local pitch = S["sy.pitch_type"]
                local pv = 0
                if pitch == "Down" then pv = -89
                elseif pitch == "Up" then pv = 89
                elseif pitch == "Up & Down" or pitch == "Random" then pv = math.random(-89, 89) end
                root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pv), 0, 0)
            end
        end

        -- fake position (underground)
        if S["sy.fake_position_enabled"] and root then
            local depth = S["sy.fake_position_depth"] or 5.8
            for _, p in ipairs(myChar():GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false; p.Transparency = 1 end end
            local camYaw = math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z)
            root.CFrame = CFrame.new(root.Position - Vector3.new(0, depth, 0)) * CFrame.Angles(0, camYaw, 0)
            root.AssemblyLinearVelocity = Vector3.zero
        end

        -- lighting
        if S["sy.lighting_ambient_enabled"] then ovSet("ambient", Lighting, "Ambient", S["sy.lighting_ambient_color"]) elseif ovr.ambient then ovRestore("ambient") end
        if S["sy.lighting_brightness_enabled"] then ovSet("brightness", Lighting, "Brightness", S["sy.lighting_brightness_value"]) elseif ovr.brightness then ovRestore("brightness") end
        if S["sy.lighting_clocktime_enabled"] then ovSet("clock", Lighting, "ClockTime", S["sy.lighting_clocktime_value"]) elseif ovr.clock then ovRestore("clock") end
        if S["sy.lighting_fog_enabled"] then
            ovSet("fog", Lighting, "FogColor", S["sy.lighting_fog_color"])
            ovSet("fog", Lighting, "FogStart", S["sy.lighting_fog_start"])
            ovSet("fog", Lighting, "FogEnd", S["sy.lighting_fog_end"])
        elseif ovr.fog then ovRestore("fog") end
        if S["sy.lighting_shadows_enabled"] ~= nil then
            ovSet("shadows", Lighting, "GlobalShadows", S["sy.lighting_shadows_enabled"])
            if S["sy.lighting_shadow_softness"] then ovSet("shadows", Lighting, "ShadowSoftness", S["sy.lighting_shadow_softness"]) end
        elseif ovr.shadows then ovRestore("shadows") end
        if S["sy.color_correction_enabled"] then
            local cc = fxGet("ColorCorrectionEffect", "LSCc")
            cc.TintColor = S["sy.cc_tint_color"]; cc.Saturation = S["sy.cc_saturation"]; cc.Contrast = S["sy.cc_contrast"]; cc.Enabled = true
        else fxDrop("LSCc") end
        if S["sy.atmosphere_enabled"] then
            local atm = Lighting:FindFirstChildOfClass("Atmosphere") or fxGet("Atmosphere", "LSAtmo")
            ovSet("atmo", atm, "Color", S["sy.atmosphere_color"]); ovSet("atmo", atm, "Density", S["sy.atmosphere_density"]); ovSet("atmo", atm, "Haze", S["sy.atmosphere_haze"])
        elseif ovr.atmo then ovRestore("atmo"); fxDrop("LSAtmo") end
        if S["sy.world_skybox_enabled"] then applySky(S["sy.skybox_preset"]) else applySky() end

        -- world (Lilac)
        if S["world.fullbright"] then
            ovSet("fb", Lighting, "Brightness", 2)
            ovSet("fb", Lighting, "Ambient", Color3.fromRGB(178,178,178))
            ovSet("fb", Lighting, "OutdoorAmbient", Color3.fromRGB(178,178,178))
            ovSet("fb", Lighting, "GlobalShadows", false)
        elseif ovr.fb then ovRestore("fb") end
        if S["world.nofog"] then
            ovSet("nofog", Lighting, "FogEnd", 1e6); ovSet("nofog", Lighting, "FogStart", 1e6 - 1)
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then ovSet("nofog", atm, "Density", 0) end
        elseif ovr.nofog then ovRestore("nofog") end
        if S["world.fovon"] then ovSet("fov", cam, "FieldOfView", S["world.fov"]) elseif ovr.fov then ovRestore("fov") end

        -- freecam
        if S["fc.enabled"] then
            if not fcState.on then
                fcState.on = true; fcState.prevType = cam.CameraType; fcState.pos = cam.CFrame.Position
                fcState.pitch, fcState.yaw = cam.CFrame:ToOrientation(); cam.CameraType = Enum.CameraType.Scriptable
                ContextActionSvc:BindActionAtPriority("LSAFreecam", function() return Enum.ContextActionResult.Sink end, false, 3000, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.Thumbstick1)
            end
            fcState.yaw -= fcState.s2.X * dt * 2.5
            fcState.pitch = math.clamp(fcState.pitch + fcState.s2.Y * dt * 2.5, -1.5, 1.5)
            local cf0 = CFrame.new(fcState.pos) * CFrame.Angles(0, fcState.yaw, 0) * CFrame.Angles(fcState.pitch, 0, 0)
            local mv = Vector3.zero
            if not Menu.open then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv += Vector3.new(0, 0, -1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv += Vector3.new(0, 0, 1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv += Vector3.new(-1, 0, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv += Vector3.new(1, 0, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then mv += Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then mv += Vector3.new(0, -1, 0) end
                mv += Vector3.new(fcState.s1.X, 0, -fcState.s1.Y)
            end
            if mv.Magnitude > 1 then mv = mv.Unit end
            local speed = S["fc.speed"] * (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)
            fcState.pos += (cf0:VectorToWorldSpace(Vector3.new(mv.X, 0, mv.Z)) + Vector3.new(0, mv.Y, 0)) * speed * dt
            cam.CFrame = CFrame.new(fcState.pos) * CFrame.Angles(0, fcState.yaw, 0) * CFrame.Angles(fcState.pitch, 0, 0)
        else
            if fcState.on then
                fcState.on = false
                cam.CameraType = fcState.prevType or Enum.CameraType.Custom
                ContextActionSvc:UnbindAction("LSAFreecam")
                fcState.s1, fcState.s2 = Vector2.zero, Vector2.zero
            end
        end
    end)
end

-- ---------------------------------------------------------------------------
-- HUD — watermark, target info, target line, array list
-- ---------------------------------------------------------------------------
do
    local cam = workspace.CurrentCamera
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function() cam = workspace.CurrentCamera end)
    local function fpsSmooth() return 60 end
    local wm = create("Frame", { BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.08, Position = UDim2.fromOffset(14, 56), AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), BorderSizePixel = 0, ZIndex = 20 }, hudGui)
    corner(wm, 9); stroke(wm, Theme.Accent, 1, 0.45); pad(wm, 6, 12, 6, 12)
    local wmLbl = create("TextLabel", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), Font = BODY, TextSize = 12, TextColor3 = Theme.Text, RichText = true, Text = "", ZIndex = 21 }, wm)

    local tp = create("Frame", { BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.08, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(240, 52), BorderSizePixel = 0, Visible = false, ZIndex = 20 }, hudGui)
    corner(tp, 10); stroke(tp, Theme.Accent, 1, 0.3)
    local tpName = text(tp, "", 12, Theme.Text, BODY); tpName.Position = UDim2.fromOffset(12, 5); tpName.Size = UDim2.new(1, -24, 0, 18); tpName.ZIndex = 21
    local tpInfo = text(tp, "", 10, Theme.Muted, LIGHT, Enum.TextXAlignment.Right); tpInfo.Position = UDim2.fromOffset(12, 5); tpInfo.Size = UDim2.new(1, -24, 0, 18); tpInfo.ZIndex = 21
    local tpBack = create("Frame", { BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -24, 0, 8), ZIndex = 21 }, tp)
    round(tpBack)
    local tpFill = create("Frame", { BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 22 }, tpBack)
    round(tpFill)

    local tline = create("Frame", { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.3, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 3 }, hudGui)

    local function lineBetween(f, a, b, th, col)
        local d = b - a
        f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
        f.Size = UDim2.fromOffset(d.Magnitude, th)
        f.Rotation = math.deg(math.atan2(d.Y, d.X))
        if col then f.BackgroundColor3 = col end
    end

    local last = 0
    connect(RunService.Heartbeat, function()
        local S = Settings
        local now = os.clock()
        wm.Visible = S["vis.watermark"]
        if now - last > 0.2 then
            last = now
            local ping = "-"
            pcall(function() local v = Stats.Network.ServerStatsItem["Data Ping"]:GetValue(); ping = tostring(math.floor(v + 0.5)) end)
            wmLbl.Text = string.format('<font color="%s">Lilac+Sleepy</font> | %s | %d fps | %s ms', hex(Theme.Accent), player.DisplayName, math.floor(fpsSmooth()), ping)
            tpFill.BackgroundColor3 = Theme.Accent
            tline.BackgroundColor3 = Theme.Accent
        end
        local track = shared.LilacState.track
        local part, plr = track.part, track.plr
        local showT = part and plr and plr.Parent and part.Parent
        tp.Visible = (showT and S["vis.targethud"]) and true or false
        tline.Visible = false
        if showT then
            local c = plr.Character
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if hum then
                local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                tpName.Text = plr.DisplayName
                tpInfo.Text = string.format("%s · %d HP · %d studs", string.upper(track.mode or ""), math.floor(hum.Health), math.floor((part.Position - cam.CFrame.Position).Magnitude))
                tpFill.Size = UDim2.fromScale(hp, 1)
                tpFill.BackgroundColor3 = S["bars.low"]:Lerp(S["bars.high"], hp)
            end
            if S["vis.targetline"] then
                local v = cam:WorldToViewportPoint(part.Position)
                if v.Z > 0 then
                    tline.Visible = true
                    lineBetween(tline, cam.ViewportSize / 2, Vector2.new(v.X, v.Y), 1.5)
                end
            end
        end
    end)
end

-- ---------------------------------------------------------------------------
-- FOV circle + crosshair (screen space, always drawn)
-- ---------------------------------------------------------------------------
do
    local cam = workspace.CurrentCamera
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function() cam = workspace.CurrentCamera end)

    local function drawing(s) local ok, d = pcall(function() return Drawing.new(s) end); return ok and d or nil end

    local fovCirc = drawing("Circle")
    local crossLines, crossOutlines, crossDot, crossDotOutline = {}, {}, nil, nil
    if fovCirc then fovCirc.Visible = false end
    for i = 1, 4 do
        local l = drawing("Line"); local o = drawing("Line")
        if l then table.insert(crossLines, l) end
        if o then table.insert(crossOutlines, o) end
    end
    crossDot = drawing("Circle"); crossDotOutline = drawing("Circle")
    cleanup(function()
        if fovCirc then pcall(function() fovCirc:Remove() end) end
        for _, l in ipairs(crossLines) do pcall(function() l:Remove() end) end
        for _, o in ipairs(crossOutlines) do pcall(function() o:Remove() end) end
        if crossDot then pcall(function() crossDot:Remove() end) end
        if crossDotOutline then pcall(function() crossDotOutline:Remove() end) end
    end)

    local rotAngle, fovSpin = 0, 0
    local function update()
        local S = Settings
        if not fovCirc then return end
        local center = cam.ViewportSize / 2
        -- FOV circle
        if S["fov.draw"] and (S["aim.enabled"] or S["silent.enabled"]) then
            fovCirc.Position = center
            local radius = S["silent.enabled"] and S["silent.fov"] or S["fov.size"]
            fovCirc.Radius = radius
            local locked = shared.LilacState.track.mode == "aim"
            fovCirc.Color = locked and S["fov.lockcolor"] or S["fov.color"]
            fovCirc.Thickness = 1.5
            fovCirc.NumSides = 64
            fovCirc.Filled = S["fov.fill"] == true
            fovCirc.Transparency = S["fov.fill"] and 0.25 or 1
            fovCirc.Visible = true
        else
            fovCirc.Visible = false
        end
        -- crosshair
        if S["sy.crosshair_enabled"] then
            local len = S["sy.crosshair_length"]
            local off = S["sy.crosshair_offset"]
            local th = S["sy.crosshair_thickness"]
            local col = S["sy.crosshair_color"]
            if S["sy.crosshair_rainbow"] then
                local spd = (S["sy.crosshair_rainbow_speed"] or 2) * 0.1
                col = Color3.fromHSV((tick() * spd) % 1, 0.85, 1)
            end
            if (S["sy.crosshair_rotation_speed"] or 0) > 0 then rotAngle = (rotAngle + (S["sy.crosshair_rotation_speed"] * 0.05)) % (math.pi * 2) end
            local baseAngle = rotAngle + math.rad(S["sy.crosshair_rotation"] or 0)
            if S["sy.crosshair_dot"] and crossDot then
                crossDot.Position = center; crossDot.Radius = S["sy.crosshair_dot_size"]; crossDot.Color = S["sy.crosshair_dot_color"]; crossDot.Filled = true; crossDot.Visible = true
                if S["sy.crosshair_outline"] and crossDotOutline then
                    crossDotOutline.Position = center; crossDotOutline.Radius = S["sy.crosshair_dot_size"] + 1.2; crossDotOutline.Thickness = 1.5; crossDotOutline.Color = Color3.new(0,0,0); crossDotOutline.Visible = true
                elseif crossDotOutline then crossDotOutline.Visible = false end
            else
                if crossDot then crossDot.Visible = false end
                if crossDotOutline then crossDotOutline.Visible = false end
            end
            for idx = 1, 4 do
                local l, o = crossLines[idx], crossOutlines[idx]
                if not l then continue end
                if S["sy.crosshair_t_shape"] and idx == 1 then
                    l.Visible = false; if o then o.Visible = false end
                else
                    local ang = baseAngle + ((idx - 1) * (math.pi / 2))
                    local dir = Vector2.new(math.cos(ang), math.sin(ang))
                    l.From = center + dir * off
                    l.To = center + dir * (off + len)
                    l.Thickness = th
                    l.Color = col
                    l.Visible = true
                    if o and S["sy.crosshair_outline"] then
                        o.From = center + dir * math.max(0, off - 1)
                        o.To = center + dir * (off + len + 1)
                        o.Thickness = th + 2
                        o.Color = Color3.new(0,0,0)
                        o.Visible = true
                    elseif o then o.Visible = false end
                end
            end
        else
            for _, l in ipairs(crossLines) do l.Visible = false end
            for _, o in ipairs(crossOutlines) do o.Visible = false end
            if crossDot then crossDot.Visible = false end
            if crossDotOutline then crossDotOutline.Visible = false end
        end
    end
    RunService:BindToRenderStep("LilacSleepyHUD2D", Enum.RenderPriority.Last.Value + 2, update)
    cleanup(function() RunService:UnbindFromRenderStep("LilacSleepyHUD2D") end)
end

-- ---------------------------------------------------------------------------
-- hit sounds + world hitmarkers
-- ---------------------------------------------------------------------------
do
    local cam = workspace.CurrentCamera
    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function() cam = workspace.CurrentCamera end)
    local HIT_SOUNDS = { Rust = "rbxassetid://1255040462", Skeet = "rbxassetid://5633695679", Bell = "rbxassetid://6534947240", Bonk = "rbxassetid://3997129949", Neverlose = "rbxassetid://6607204501", Bubble = "rbxassetid://6534947588" }
    local KILL_SOUNDS = { Fatality = "rbxassetid://6607204928", Headshot = "rbxassetid://6534948092", Skeet = "rbxassetid://5633695679", Oof = "rbxassetid://5143383166" }
    local function playSound(id, vol, pitch)
        if not id or id == "" then return end
        task.spawn(function()
            local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol or 1.0; s.PlaybackSpeed = pitch or 1.0; s.Parent = SoundService; s:Play()
            s.Ended:Connect(function() s:Destroy() end)
            task.delay(5, function() if s and s.Parent then s:Destroy() end end)
        end)
    end
    function playEventSound(t)
        local S = Settings
        local vol, pitch = S["sy.sound_volume"] or 1, S["sy.sound_pitch"] or 1
        if t == "hit" and S["sy.hit_sound_enabled"] then playSound(HIT_SOUNDS[S["sy.hit_sound_preset"] or "Rust"], vol, pitch)
        elseif t == "kill" and S["sy.kill_sound_enabled"] then playSound(KILL_SOUNDS[S["sy.kill_sound_preset"] or "Fatality"], vol, pitch) end
    end
    local function spawnWorldMarker(pos)
        if not Settings["sy.world_marker_enabled"] or not pos then return end
        task.spawn(function()
            local anchor = create("Part", { Name = "_LSMarker", Anchored = true, CanCollide = false, CanQuery = false, Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1), Position = pos }, Workspace)
            local bb = create("BillboardGui", { Adornee = anchor, AlwaysOnTop = true, Size = UDim2.fromOffset(25, 25) }, anchor)
            local col = Settings["sy.world_marker_color"]
            for _, rot in ipairs({ 45, -45 }) do
                create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 3, 0, 20), Rotation = rot, BackgroundColor3 = col, BorderSizePixel = 0 }, bb)
            end
            tween(bb, { Size = UDim2.fromOffset(37, 37) }, 0.6, Enum.EasingStyle.Quad)
            task.delay(0.6, function() if anchor.Parent then anchor:Destroy() end end)
        end)
    end
    getgenv()._LSTriggerHit = function(targetName, partName, damage, weapon, hitPos)
        playEventSound("hit")
        if hitPos then spawnWorldMarker(hitPos) end
    end
    cleanup(function() getgenv()._LSTriggerHit = nil end)

    -- watch for enemy damage (hit sounds)
    local hpLast = setmetatable({}, { __mode = "k" })
    connect(RunService.Heartbeat, function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                local c = plr.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if hum then
                    local prev = hpLast[hum]
                    if prev and hum.Health < prev - 0.5 then
                        local head = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
                        if head then spawnWorldMarker(head.Position) end
                        playEventSound(hum.Health <= 0 and "kill" or "hit")
                    end
                    hpLast[hum] = hum.Health
                end
            end
        end
    end)
end

-- ---------------------------------------------------------------------------
-- cosmetic changer (Lilac-style, adapted from both engines)
-- ---------------------------------------------------------------------------
local function tryRequire(m) local ok, r = pcall(require, m); return ok and r or nil end
local rep = game:GetService("ReplicatedStorage")
local lpScripts = player:FindFirstChild("PlayerScripts")
local ctrls = lpScripts and lpScripts:FindFirstChild("Controllers")
local rmods = rep:FindFirstChild("Modules")
local elib, clib, ilib, dctrl
if rmods and ctrls then
    elib = tryRequire(rmods:FindFirstChild("EnumLibrary"))
    clib = tryRequire(rmods:FindFirstChild("CosmeticLibrary"))
    ilib = tryRequire(rmods:FindFirstChild("ItemLibrary"))
    dctrl = tryRequire(ctrls:FindFirstChild("PlayerDataController"))
end

local equip, coss = {}, (clib and clib.Cosmetics) or {}
local function clonecos(name, ctype)
    local base = coss[name]; if not base then return nil end
    local d = table.clone(base)
    d.Name = name; d.Type = d.Type or ctype
    d.Owned, d.Unlocked, d.Locked = true, true, false
    return d
end
local function rebuildEquip()
    for k in pairs(equip) do equip[k] = nil end
end

local function applyCosmetic(weapon, name, ctype)
    if not weapon or not ctype then return end
    equip[weapon] = equip[weapon] or {}
    if not name or name == "" or name == "None" then
        equip[weapon][ctype] = nil
    else
        local c = clonecos(name, ctype)
        if c then equip[weapon][ctype] = c end
    end
end

local cosmeticGui
local function makeCosmeticGui()
    if cosmeticGui and cosmeticGui.Parent then return cosmeticGui end
    local sg = CoreGui:FindFirstChild("_LSCosmetics") or create("ScreenGui", { Name = "_LSCosmetics", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1500 }, CoreGui)
    local win = create("Frame", { BackgroundColor3 = Theme.Card, Position = UDim2.fromOffset(300, 200), Size = UDim2.fromOffset(600, 500), BorderSizePixel = 0, Visible = false }, sg)
    corner(win, 14); stroke(win, Theme.Accent, 1.5, 0.2)
    local title = text(win, "Lilac+Sleepy — Cosmetics", 14, Theme.Text, HEAD); title.Position = UDim2.fromOffset(14, 10); title.Size = UDim2.new(1, -100, 0, 22)
    local close = create("TextButton", { Text = "x", Font = BOLD, TextSize = 12, TextColor3 = Theme.Text, BackgroundColor3 = Theme.CardHead, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(26, 22), BorderSizePixel = 0 }, win)
    corner(close, 6); close.Activated:Connect(function() win.Visible = false end)
    local body = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 44), Size = UDim2.new(1, -28, 1, -58) }, win)
    local typeRow = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28) }, body)
    local types = { "Skin", "Wrap", "Charm", "Finisher" }
    local activeType = "Skin"
    local typeBtns = {}
    for i, t in ipairs(types) do
        local b = create("TextButton", { Text = t, Font = BODY, TextSize = 11, TextColor3 = Theme.Text, BackgroundColor3 = i == 1 and Theme.Accent or Theme.CardHead, Position = UDim2.fromOffset((i - 1) * 104, 0), Size = UDim2.fromOffset(100, 26), BorderSizePixel = 0 }, typeRow)
        corner(b, 7)
        typeBtns[t] = b
        b.Activated:Connect(function()
            activeType = t
            for k, bb in pairs(typeBtns) do bb.BackgroundColor3 = (k == t) and Theme.Accent or Theme.CardHead end
            if shared.SleepyState and shared.SleepyState.CosmeticRefresh then shared.SleepyState.CosmeticRefresh() end
        end)
    end
    local grid = create("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 1, -36), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3 }, body)
    create("UIGridLayout", { CellSize = UDim2.fromOffset(130, 90), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
    win.Visible = true
    local function refresh()
        for _, c in ipairs(grid:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
        if not coss then return end
        for name, data in pairs(coss) do
            if data.Type == activeType then
                local b = create("TextButton", { Text = "", BackgroundColor3 = Theme.CardHead, BorderSizePixel = 0, AutoButtonColor = false }, grid)
                corner(b, 8)
                local img = create("ImageLabel", { BackgroundTransparency = 1, Image = data.Image or "", ScaleType = Enum.ScaleType.Fit, Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(118, 60) }, b)
                local lbl = text(b, name, 10, Theme.Text, BODY, Enum.TextXAlignment.Center)
                lbl.Position = UDim2.fromOffset(4, 66); lbl.Size = UDim2.new(1, -8, 0, 20)
                lbl.TextTruncate = Enum.TextTruncate.AtEnd
                b.Activated:Connect(function()
                    applyCosmetic(Settings["cfg.selected"] or "default", name, activeType)
                    notify("Cosmetics", "Applied " .. name)
                end)
            end
        end
    end
    shared.SleepyState = shared.SleepyState or {}
    shared.SleepyState.CosmeticRefresh = refresh
    refresh()
    cosmeticGui = win
    return win
end

if clib and coss and next(coss) then
    shared.SleepyState = shared.SleepyState or {}
    shared.SleepyState.CosmeticChanger = function()
        local g = makeCosmeticGui()
        if g then g.Visible = not g.Visible end
    end
end

-- ---------------------------------------------------------------------------
-- Sleepy silent-aim redirect hook (if game exposes fighter remotes)
-- ---------------------------------------------------------------------------
do
    if not hookfunction or not newcclosure then return end
    local lp = player
    local mods = rep:FindFirstChild("Modules")
    local remotes = rep:FindFirstChild("Remotes")
    if not mods or not remotes then return end
    local fighter = remotes:FindFirstChild("Replication") and remotes.Replication:FindFirstChild("Fighter")
    local useItem = fighter and fighter:FindFirstChild("UseItem")
    if not useItem or typeof(useItem) ~= "Instance" or not useItem:IsA("RemoteEvent") then return end
    local old
    pcall(function()
        old = hookfunction(useItem.FireServer, newcclosure(function(self, ...)
            local args = { ... }
            if (Settings["silent.enabled"] or Settings["rage.enabled"]) and typeof(args[3]) == "table" then
                local track = shared.LilacState.track
                if track and track.part and track.part.Parent then
                    local origin = workspace.CurrentCamera.CFrame.Position
                    local dest = track.part.Position
                    local dir = dest - origin
                    if dir.Magnitude > 0.01 then
                        dir = dir.Unit
                        args[3].LookVector = dir; args[3].lookVector = dir
                        args[3].Origin = origin; args[3].Position = origin
                        local cf = CFrame.lookAt(origin, origin + dir)
                        args[3].CFrame = cf; args[3].CameraCFrame = cf
                    end
                end
            end
            return old(self, table.unpack(args))
        end))
    end)
    if old then
        cleanup(function() pcall(function() hookfunction(useItem.FireServer, old) end) end)
    end
end

-- ---------------------------------------------------------------------------
-- custom cursor
-- ---------------------------------------------------------------------------
do
    local cursor = create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(0, 0), Visible = false, ZIndex = 10 }, cursorGui)
    local ring = create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(18, 18), ZIndex = 10 }, cursor)
    round(ring); stroke(ring, Theme.Accent, 2, 0)
    local dot = create("Frame", { BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 4), ZIndex = 11 }, cursor)
    round(dot); stroke(dot, Color3.new(0,0,0), 1, 0.4)
    local prev = UserInputService.MouseIconEnabled
    local hidden = false
    RunService:BindToRenderStep("LSCursor", Enum.RenderPriority.Last.Value + 2, function()
        local on = Menu.open and activePlat == "PC"
        if on then UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
        local show = on and Settings["set.cursor"] ~= false
        cursor.Visible = show
        if show then
            local m = UserInputService:GetMouseLocation()
            cursor.Position = UDim2.fromOffset(m.X, m.Y)
            if not hidden then prev = UserInputService.MouseIconEnabled; UserInputService.MouseIconEnabled = false; hidden = true end
        elseif hidden then
            UserInputService.MouseIconEnabled = prev; hidden = false
        end
    end)
    cleanup(function()
        RunService:UnbindFromRenderStep("LSCursor")
        if hidden then UserInputService.MouseIconEnabled = prev end
    end)
end

-- ---------------------------------------------------------------------------
-- minimize
-- ---------------------------------------------------------------------------
minButton.Activated:Connect(function()
    local minimized = main.Size.Y.Offset > 100
    local h = minimized and 56 or RH
    tween(main, { Size = UDim2.fromOffset(MAIN_W, h) }, 0.28)
    tween(glowOuter, { Size = UDim2.fromOffset(MAIN_W + 10, h + 10) }, 0.28)
    tween(glowInner, { Size = UDim2.fromOffset(MAIN_W + 4, h + 4) }, 0.28)
end)

-- ---------------------------------------------------------------------------
-- accent / preview / scale handlers
-- ---------------------------------------------------------------------------
Handlers["vis.accent"] = function(c)
    Theme.Accent = c
    mainStroke.Color = c
    glowOuterStroke.Color = c
    glowInnerStroke.Color = c
    logoStroke.Color = c
    logoText.TextColor3 = c
    topLine.BackgroundColor3 = c
end
Handlers["vis.accent2"] = function(c) Theme.Accent2 = c end
Handlers["set.scale"] = function(v) userScale = v / 100; fit() end
Handlers["sy.show_cosmetics_changer"] = function(v)
    if v and shared.SleepyState and shared.SleepyState.CosmeticChanger then shared.SleepyState.CosmeticChanger() end
end

-- ---------------------------------------------------------------------------
-- apply defaults
-- ---------------------------------------------------------------------------
for k, v in pairs(Defaults) do
    if Controls[k] and Controls[k].apply then pcall(Controls[k].apply, v) end
    if Handlers[k] then pcall(Handlers[k], v) end
end

notify("Lilac+Sleepy", "Merged build loaded — " .. prettyKey(Settings["set.menukey"]) .. " toggles menu")
print("[Lilac+Sleepy] loaded")
