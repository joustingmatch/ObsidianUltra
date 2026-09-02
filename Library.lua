local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local GuiService: GuiService = cloneref(game:GetService("GuiService"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local SetClipboard = setclipboard or toclipboard or (syn and syn.write_clipboard) or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = cloneref(LocalPlayer:GetMouse())

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {}
local Tooltips = {}

local BaseURL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local CustomImageManager = {}
local CustomImageManagerAssets = {
    TransparencyTexture = {
        RobloxId = 139785960036434,
        Path = "Obsidian/assets/TransparencyTexture.png",
        URL = BaseURL .. "assets/TransparencyTexture.png",

        Id = nil,
    },

    SaturationMap = {
        RobloxId = 4155801252,
        Path = "Obsidian/assets/SaturationMap.png",
        URL = BaseURL .. "assets/SaturationMap.png",

        Id = nil,
    },

    LoadingIcon = {
        RobloxId = 97544096941083,
        Path = "Obsidian/assets/LoadingIcon.png",
        URL = BaseURL .. "assets/LoadingIcon.png",

        Id = nil,
    },

    CheckIcon = {
        RobloxId = 97682394690683,
        Path = "Obsidian/assets/CheckIcon.png",
        URL = BaseURL .. "assets/CheckIcon.png",

        Id = nil,
    },
}
do
    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then
            return
        end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in ipairs(Segments) do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function CustomImageManager.AddAsset(
        AssetName: string,
        RobloxAssetId: number,
        URL: string,
        ForceRedownload: boolean?
    )
        if CustomImageManagerAssets[AssetName] ~= nil then
            error(string.format("Asset %q already exists", AssetName))
        end

        assert(typeof(RobloxAssetId) == "number", "RobloxAssetId must be a number")

        CustomImageManagerAssets[AssetName] = {
            RobloxId = RobloxAssetId,
            Path = string.format("Obsidian/custom_assets/%s", AssetName),
            URL = URL,

            Id = nil,
        }

        CustomImageManager.DownloadAsset(AssetName, ForceRedownload)
    end

    function CustomImageManager.GetAsset(AssetName: string)
        if not CustomImageManagerAssets[AssetName] then
            return nil
        end

        local AssetData = CustomImageManagerAssets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = string.format("rbxassetid://%s", AssetData.RobloxId)

        if getcustomasset then
            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID then
                AssetID = NewID
            end
        end

        AssetData.Id = AssetID
        return AssetID
    end

    function CustomImageManager.DownloadAsset(AssetName: string, ForceRedownload: boolean?)
        if not getcustomasset or not writefile or not isfile then
            return false, "missing functions"
        end

        local AssetData = CustomImageManagerAssets[AssetName]

        RecursiveCreatePath(AssetData.Path, true)

        if ForceRedownload ~= true and isfile(AssetData.Path) then
            return true, nil
        end

        local success, errorMessage = pcall(function()
            writefile(AssetData.Path, game:HttpGet(AssetData.URL))
        end)

        return success, errorMessage
    end

    for AssetName, _ in CustomImageManagerAssets do
        CustomImageManager.DownloadAsset(AssetName)
    end
end

local Library = {
    LocalPlayer = LocalPlayer,
    IsRobloxFocused = true,

    --// Device \\--
    DevicePlatform = nil,
    IsMobile = false,

    --// Obsidian Windows \\--
    ScreenGui = nil,
    Floats = nil,
    Overlay = nil,

    Window = nil,
    WindowContainer = nil,

    --// Search \\--
    SearchText = "",
    Searching = false,
    GlobalSearch = false,
    FuzzySearch = true,
    SearchValues = true,
    LastSearchTab = nil,

    --// Tabs \\--
    ActiveTab = nil,
    Tabs = {},
    TabButtons = {},

    --// Dependency Boxes \\--
    DependencyBoxes = {},

    --// Keybinds Frame \\--
    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    --// Notifications \\--
    Notifications = {},
    NotifySide = "Right",
    NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    --// Notification History (built-in) \\--
    NotificationHistory = {},
    NotificationHistoryLimit = 100,
    NotificationHistoryKeybind = Enum.KeyCode.RightAlt,
    NotificationHistoryFrame = nil,
    NotificationHistoryContainer = nil,
    NotificationHistoryOpen = false,
    NotificationHistoryRestPos = nil,
    NotificationUnreadCount = 0,
    NotificationBadge = nil,
    NotificationBadges = {},
    NotificationBell = nil,
    NotificationBellMini = nil,
    --// Primary-text color per notification type; customizable by the user
    NotificationTypeColors = {
        Error = Color3.fromRGB(255, 76, 76),
        Warning = Color3.fromRGB(255, 176, 32),
        Success = Color3.fromRGB(96, 216, 118),
        Info = Color3.fromRGB(96, 165, 255),
    },

    --// Dialogues \\--
    Dialogues = {},
    ActiveDialog = nil,
    MainFrame = nil,
    ActiveExpandedDropdown = nil,

    --// Loading Window \\--
    ActiveLoading = nil,

    --// Context Menu \\--
    ContextMenus = {}, 

    --// Corners \\--
    Corners = {},
    SpecificCorners = {},
    --// Stay fully rounded, but square off with everything else at radius 0
    PillCorners = {},

    --// Animations \\--
    TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    TabTransitionInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TabSwipeOffset = 26,
    TabSwipeFrom = "bottom",

    WindowAnimationInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    DropdownTransitionInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    KeyPickerTransitionInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    GroupboxTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    RotatingChevronTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),

    Animations = {
        ToggleWindow = false,
        TabSwitch = false,
        Groupbox = false,
        Dropdown = false,
        KeyPicker = false
    },

    --// States \\--
    Toggled = false,
    Unloaded = false,

    --// Elements \\--
    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    --// Options \\--
    ToggleKeybind = Enum.KeyCode.RightControl,
    ShowToggleFrameInKeybinds = true,

    NotifyOnError = false,
    ShowCustomCursor = true,
    ForceCheckbox = false,

    CantDragForced = false,
    DraggableElements = {},

    --// Pop Out \\--
    PopOutSnapDistance = 80,
    PopOutDragThreshold = 8,
    PopOutHoldTime = 0.15,

    --// Signals \\--
    Signals = {},
    UnloadSignals = {},

    OriginalMinSize = Vector2.new(480, 360),
    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 4,

    --// Scheme \\--
    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(15, 15, 15),
        MainColor = Color3.fromRGB(25, 25, 25),
        AccentColor = Color3.fromRGB(125, 85, 255),
        OutlineColor = Color3.fromRGB(40, 40, 40),
        FontColor = Color3.new(1, 1, 1),
        Font = Font.fromEnum(Enum.Font.Code),

        RedColor = Color3.fromRGB(255, 50, 50),
        BlueColor = Color3.fromRGB(80, 155, 255),
        DestructiveColor = Color3.fromRGB(220, 38, 38),
        DarkColor = Color3.new(0, 0, 0),
        WhiteColor = Color3.new(1, 1, 1),

        BackgroundImage = ""
    },

    --// Registry \\--
    Registry = {},
    Scales = {},
    ScalesOffset = {},

    --// Mouse \\--
    OriginalMouseIconEnabled = UserInputService.MouseIconEnabled,
    ShowCursorBinding = string.sub(tostring({}), 10),

    --// Image Manager \\--
    ImageManager = CustomImageManager,

    --// Misc \\--
    Notify = nil, Toggle = nil -- we love luau lsp
}

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.OriginalMinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.OriginalMinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)

    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.OriginalMinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local Templates = {
    --// UI \\--
    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = function()
            local H, S, V = Library.Scheme.FontColor:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end,
        Text = "",
        TextColor3 = "FontColor",
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    },

    --// Library \\--
    Window = {
        Title = "No Title",
        Footer = "No Footer",
        CopyableFooter = true,

        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 600),
        IconSize = UDim2.fromOffset(30, 30),

        AutoShow = true,
        Center = true,
        Resizable = true,
        AlwaysOnTop = false,

        --// Window Snapping \\--
        Snapping = false,
        SnapDistance = 28,
        SnapMargin = 8,
        SnapAvoidCoreGui = true,

        SearchbarSize = UDim2.fromScale(0.35, 1),
        GlobalSearch = false,
        FuzzySearch = true,
        SearchValues = true,
        SearchKeybind = Enum.KeyCode.F,
        DisableSearchKeybind = false,

        Minimizable = true,
        MinimizeKeybind = nil,
        MinimizedWidth = 300,
        MinimizedSubtitle = "",
        AutoMinimize = false,

        CornerRadius = 4,
        NotifySide = "Right",
        DisableNotificationBell = false,
        ShowCustomCursor = true,

        --// Glow \\--
        --// Off by default and never forced. The glow is a visible render effect,
        --// so the user opts in themselves via Window:SetGlow(true) (or this flag).
        Glow = false,

        Font = Enum.Font.Code,
        ToggleKeybind = Enum.KeyCode.RightControl,

        ShowMobileButtons = true,
        MobileButtonsSide = "Left",

        UnlockMouseWhileOpen = true,

        EnableSidebarResize = true,
        EnableCompacting = true,
        DisableCompactingSnap = false,
        SidebarCompacted = false,
        MinContainerWidth = 256,

        --// Snapping \\--
        MinSidebarWidth = 128,
        SidebarCompactWidth = 48,
        SidebarCollapseThreshold = 0.5,

        --// Dragging \\--
        CompactWidthActivation = 128,

        --// Background \\--
        BackgroundImage = "",

        --// Animations \\--
        Animations = {
            ToggleWindow = false,
            TabSwitch = false,
            Groupbox = false,
            Dropdown = false,
            KeyPicker = false,
            --// The sub tab bar slide; on by default, it is a small ornament
            SubTabUnderline = true
        },

        TabTransitionTime = 0.22,
        TabSwipeOffset = 26,
        TabSwipeFrom = "bottom"
    },
    Groupbox = {
        Side = 1,
        Name = "Groupbox",
        IconName = nil,
        Description = nil,
        Visible = true,
        Collapsed = false,
        DisableCollapsing = false,
        PopOut = true,
    },
    Tabbox = {
        Side = 1,
        Name = nil,
        PopOut = true,
    },
    Dialog = {
        Title = "Dialog",
        Description = "Description",
        AutoDismiss = true,
        OutsideClickDismiss = true,
        FooterButtons = {}
    },
    Loading = {
        Title = "mspaint",
        Icon = 95816097006870,
        IconSize = UDim2.fromOffset(30, 30),

        LoadingIcon = CustomImageManager.GetAsset("LoadingIcon"),
        LoadingIconColor = nil,
        LoadingIconTweenTime = 1,

        CurrentStep = 0,
        TotalSteps = 10,

        ShowSidebar = false,
        AutoResizeHeight = false,
        AlwaysOnTop = true,

        WindowWidth = 450,
        WindowHeight = 275,

        ContentWidth = 450,
        SidebarWidth = 250,
    },
    Toggle = {
        Text = "Toggle",
        Default = false,

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        ClearTextOnBlur = false,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",

        Callback = function() end,
        Changed = function() end,
        VerifyValue = nil,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,

        AllowRightClickInput = true
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        ValueImages = {},

        Multi = false,
        DragSelect = false,
        MaxVisibleDropdownItems = 8,

        --// Built in "Select All" / "Deselect All" row, multi dropdowns only
        SelectAllButtons = true,

        --// Opens the values in a large panel over the window
        Expandable = true,
        ExpandColumns = 2,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    PriorityDropdown = {
        Values = {},

        --// Initial priority order; defaults to the order of Values
        Default = {},

        MaxVisibleDropdownItems = 8,
        Searchable = true,

        --// Adds a button that opens the list in a large panel over the window
        Expandable = true,

        --// Optional per value display formatter
        FormatDisplayValue = nil,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        BackgroundTransparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },
    PlayerInfo = {
        Player = nil,
        UserId = nil,
        Title = "",
        Description = "",
        Thumbnail = nil,
        ThumbnailType = nil,
        Height = nil,
        Visible = true,
    },
    Video = {
        Video = "",
        Looped = false,
        Playing = false,
        Volume = 1,
        Height = 200,
        Visible = true,
    },
    UIPassthrough = {
        Instance = nil,
        Height = 24,
        Visible = true,
    },

    --// Addons \\-
    KeyPicker = {
        Text = "KeyPicker",

        Default = "None",
        DefaultModifiers = {},

        Blacklisted = {},
        BlacklistedModifiers = {},
        Whitelisted = {},
        WhitelistedModifiers = {},

        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Resizable = true,

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}
local SideIndex = {
    left = 1,
    right = 2,
}

--// Scheme Functions \\--
local SchemeReplaceAlias = {
    RedColor = "Red",
    WhiteColor = "White",
    DarkColor = "Dark"
}

local SchemeAlias = {
    Red = "RedColor",
    Blue = "BlueColor",
    White = "WhiteColor",
    Dark = "DarkColor"
}

local function GetSchemeValue(Index)
    if not Index then
        return nil
    end

    local ReplaceAliasIndex = SchemeReplaceAlias[Index]
    if ReplaceAliasIndex and Library.Scheme[ReplaceAliasIndex] ~= nil then
        Library.Scheme[Index] = Library.Scheme[ReplaceAliasIndex]
        Library.Scheme[ReplaceAliasIndex] = nil

        return Library.Scheme[Index]
    end

    local AliasIndex = SchemeAlias[Index]
    if AliasIndex and Library.Scheme[AliasIndex] ~= nil then
        warn(string.format("Scheme Value %q is deprecated, please use %q instead.", Index, AliasIndex))
        return Library.Scheme[AliasIndex]
    end

    return Library.Scheme[Index]
end

--// Basic Functions \\--
local function WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Connection = Event:Once(function(...)
        if not Condition or typeof(Condition) == "function" and Condition(...) then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        Connection:Disconnect()
        Bindable:Fire(false)
    end)

    local Result = Bindable.Event:Wait()
    Bindable:Destroy()

    return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
        and Library.IsRobloxFocused
end
local function IsMouseClickInput(Input: InputObject)
    return Input.UserInputType == Enum.UserInputType.MouseButton1 or
        Input.UserInputType == Enum.UserInputType.MouseButton2 or
        Input.UserInputType == Enum.UserInputType.MouseButton3
end
local function IsMovementInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Library.IsRobloxFocused
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0

    for _, _ in Table do
        Size += 1
    end

    return Size
end
local function IsSequentialArray(Table: { [any]: any })
    for Key in Table do
        if typeof(Key) ~= "number" or Key < 1 or Key % 1 ~= 0 then
            return false
        end
    end

    return true
end

local function StopTween(Tween: TweenBase, Destroy: boolean?)
    if not Tween then
        return
    end

    if Tween.PlaybackState == Enum.PlaybackState.Playing then
        Tween:Cancel()
    end

    if Destroy == true then
        pcall(Tween.Destroy, Tween)
    end
end

local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end
local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")

    if Rounding == 0 then
        return math.floor(Value)
    end

    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

--// Fuzzy Search \\--
local function FuzzyScore(Text: string, Search: string): (boolean, number)
    if Search == "" then
        return true, 0
    end
    if Text == "" then
        return false, 0
    end

    --// Fast path: literal substring match (also the best possible score) \\--
    local ExactIdx = Text:find(Search, 1, true)
    if ExactIdx then
        local PrevChar = ExactIdx > 1 and Text:sub(ExactIdx - 1, ExactIdx - 1) or ""
        local AtBoundary = ExactIdx == 1 or PrevChar:match("[%s%p_]") ~= nil

        return true, 1e5 - ExactIdx + (AtBoundary and 500 or 0) + (Search:len() * 5)
    end

    --// Fallback: fuzzy, in-order, non-consecutive character matching \\--
    local TextLen, SearchLen = Text:len(), Search:len()
    if SearchLen > TextLen then
        return false, 0
    end

    local SearchIdx = 1
    local Score = 0
    local RunLength = 0
    local LastMatchIdx = 0

    for TextIdx = 1, TextLen do
        if SearchIdx > SearchLen then
            break
        end

        if Text:sub(TextIdx, TextIdx) == Search:sub(SearchIdx, SearchIdx) then
            local PrevChar = TextIdx > 1 and Text:sub(TextIdx - 1, TextIdx - 1) or ""
            local AtBoundary = TextIdx == 1 or PrevChar:match("[%s%p_]") ~= nil

            RunLength = (LastMatchIdx == TextIdx - 1) and (RunLength + 1) or 1
            Score += 1 + (AtBoundary and 6 or 0) + math.min(RunLength - 1, 5) * 3

            LastMatchIdx = TextIdx
            SearchIdx += 1
        end
    end

    if SearchIdx <= SearchLen then
        return false, 0 --// Not every Search character was found, in order
    end

    Score -= (LastMatchIdx - SearchLen) * 0.05 --// Slightly favour tighter matches
    return true, Score
end

local function NormalizeSearch(Search: string): string
    return (Search:gsub("%s+", ""))
end

local function TryFuzzyMatch(Text: any, Search: string): boolean
    if typeof(Text) ~= "string" or Text == "" then
        return false
    end

    return (FuzzyScore(Text:lower(), Search))
end

local function MatchesSearch(ElementInfo, Search: string, ForceMatch: boolean?): boolean
    if not ElementInfo then
        return false
    end
    if ForceMatch then
        return true
    end

    if TryFuzzyMatch(ElementInfo.Text, Search) then
        return true
    end
    if TryFuzzyMatch(ElementInfo.Tooltip, Search) then
        return true
    end
    if TryFuzzyMatch(ElementInfo.DisabledTooltip, Search) then
        return true
    end

    --// Optional: search inside Dropdown value lists, so e.g. searching a
    --// specific option name reveals the Dropdown that contains it \\--
    if typeof(ElementInfo.Values) == "table" then
        local Checked = 0
        for Key, Value in ElementInfo.Values do
            Checked += 1
            if Checked > 200 then
                break
            end

            if TryFuzzyMatch(Value, Search) or (typeof(Value) ~= "string" and TryFuzzyMatch(tostring(Value), Search)) then
                return true
            end
            if typeof(Key) == "string" and TryFuzzyMatch(Key, Search) then
                return true
            end
        end
    end

    return false
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    return PlayerList
end
local function GetTeams()
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    return TeamList
end

--// Returns the scrolling sides currently on screen (Sub Tab aware)
function Library:GetActiveSides(): { ScrollingFrame }
    local Tab = Library.ActiveTab
    if not Tab then
        return {}
    end

    if Tab.ActiveSubTab then
        return Tab.ActiveSubTab.Sides
    end

    return Tab.Sides or {}
end

function Library:UpdateDependencyBoxes()
    for _, Depbox in Library.DependencyBoxes do
        Depbox:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

local function CheckDepbox(Box, Search, ForceVisible: boolean?)
    local VisibleElements = 0

    for _, ElementInfo in Box.Elements do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then
            --// Check if any of the Buttons Name matches with Search
            local Visible = false

            --// Check if Search matches Element's Name and if Element is Visible
            if MatchesSearch(ElementInfo, Search, ForceVisible) and ElementInfo.Visible then
                Visible = true
            else
                ElementInfo.Base.Visible = false
            end
            if MatchesSearch(ElementInfo.SubButton, Search, ForceVisible) and ElementInfo.SubButton.Visible then
                Visible = true
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        --// Check if Search matches Element's Name and if Element is Visible
        if ElementInfo.Text and MatchesSearch(ElementInfo, Search, ForceVisible) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
        else
            ElementInfo.Holder.Visible = false
        end
    end

    for _, Depbox in Box.DependencyBoxes do
        if not Depbox.Visible then
            continue
        end

        VisibleElements += CheckDepbox(Depbox, Search, ForceVisible)
    end

    Box.Holder.Visible = VisibleElements > 0
    return VisibleElements
end
local function RestoreDepbox(Box)
    for _, ElementInfo in Box.Elements do
        ElementInfo.Holder.Visible = ElementInfo.Visible ~= false

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    Box:Resize()
    Box.Holder.Visible = true

    for _, Depbox in Box.DependencyBoxes do
        if not Depbox.Visible then
            continue
        end

        RestoreDepbox(Depbox)
    end
end

--// Pop Out
function SyncPopOutVisibility(Box: any)
    if not Box.PopOutFloat then
        return
    end

    Box.PopOutFloat.Visible = Box.BoxHolder.Visible ~= false and Box.Visible ~= false
end

local function DimPopOutClone(Root: GuiObject)
    for _, Descendant in Root:QueryDescendants("TextLabel, TextButton, TextBox") do
        Descendant.TextTransparency = math.max(Descendant.TextTransparency, 0.45)
    end

    for _, Descendant in Root:QueryDescendants("ImageLabel, ImageButton") do
        Descendant.ImageTransparency = math.max(Descendant.ImageTransparency, 0.45)
    end

    for _, Descendant in Root:QueryDescendants("GuiButton") do
        Descendant.Active = false
        Descendant.AutoButtonColor = false
    end
end

local function IsScreenPointOutsideMain(Point: Vector2): boolean
    local MainFrame = Library.Window and Library.Window.MainFrame
    if not MainFrame or not Library.Toggled or not MainFrame.Visible then
        return true
    end

    return not Library:MouseIsOverFrame(MainFrame, Point)
end

local function GetTopFloatAt(Point: Vector2): GuiObject?
    local Best: GuiObject? = nil
    local BestOrder = -math.huge
    local Floats = Library.Floats

    for _, Surface in Library.DraggableElements do
        if not Surface or not Surface.Parent or not Surface.Visible then
            continue
        end
        if Floats and Surface.Parent ~= Floats then
            continue
        end
        if not Library:MouseIsOverFrame(Surface, Point) then
            continue
        end

        local SiblingIndex = tonumber(select(2, pcall(function() return Surface:GetSiblingIndex() end))) or 0
        local Order = Surface.ZIndex * 100000 + SiblingIndex
        if Order >= BestOrder then
            BestOrder = Order
            Best = Surface
        end
    end

    return Best
end

local function GetPopOutBodyMaxHeight(Box: any, Reserved: number): number
    local Float = Box.PopOutFloat
    local ScreenGui = Library.ScreenGui
    if not Float or not ScreenGui then
        return math.huge
    end

    local Gap = 12 * Library.DPIScale
    local MaxBottom = ScreenGui.AbsolutePosition.Y + ScreenGui.AbsoluteSize.Y - Gap
    local Available = math.min(MaxBottom - Float.AbsolutePosition.Y, ScreenGui.AbsoluteSize.Y * 0.9)

    return math.max(0, Available / Library.DPIScale - Reserved)
end

--// Search
local function ApplySearchToTab(Tab, Search)
    if not Tab then
        return
    end

    local HasVisible = false

    --// If the Tab itself matches Search (by name/description), don't filter out its contents -- pull everything in the Tab along with it \\--
    local TabMatches = TryFuzzyMatch(Tab.Name, Search) or TryFuzzyMatch(Tab.Description, Search)
    for _, Groupbox in Tab.Groupboxes do
        if Groupbox.Visible == false then
            continue
        end

        --// Optional: matching the Groupbox's own name/description reveals every element inside it, without needing each one to match too
        local GroupboxMatches = TabMatches or (TryFuzzyMatch(Groupbox.Name, Search) or TryFuzzyMatch(Groupbox.Description, Search))
        local VisibleElements = 0

        for _, ElementInfo in Groupbox.Elements do
            if ElementInfo.Type == "Divider" then
                ElementInfo.Holder.Visible = GroupboxMatches and ElementInfo.Visible ~= false
                continue
            elseif ElementInfo.SubButton then
                --// Check if any of the Buttons Name matches with Search
                local Visible = false
                if MatchesSearch(ElementInfo, Search, GroupboxMatches) and ElementInfo.Visible then
                    Visible = true
                else
                    ElementInfo.Base.Visible = false
                end

                if MatchesSearch(ElementInfo.SubButton, Search, GroupboxMatches) and ElementInfo.SubButton.Visible then
                    Visible = true
                else
                    ElementInfo.SubButton.Base.Visible = false
                end

                ElementInfo.Holder.Visible = Visible
                if Visible then
                    VisibleElements += 1
                end

                continue
            end

            --// Check if Search matches Element's Name and if Element is Visible
            if ElementInfo.Text and MatchesSearch(ElementInfo, Search, GroupboxMatches) and ElementInfo.Visible then
                ElementInfo.Holder.Visible = true
                VisibleElements += 1
            else
                ElementInfo.Holder.Visible = false
            end
        end

        for _, Depbox in Groupbox.DependencyBoxes do
            if not Depbox.Visible then
                continue
            end

            VisibleElements += CheckDepbox(Depbox, Search, GroupboxMatches)
        end

        --// Update Groupbox Size and Visibility if found any element
        if VisibleElements > 0 then
            Groupbox:Resize()
            HasVisible = true
        end
        Groupbox.BoxHolder.Visible = VisibleElements > 0
        SyncPopOutVisibility(Groupbox)
    end

    for _, Tabbox in Tab.Tabboxes do
        local VisibleTabs = 0
        local VisibleElements = {}

        for _, SubTab in Tabbox.Tabs do
            VisibleElements[SubTab] = 0

            --// Optional: matching a Tabbox sub-tab's own name reveals every element inside it, without needing each one to match too
            local SubTabMatches = TabMatches or TryFuzzyMatch(SubTab.Name, Search)

            for _, ElementInfo in SubTab.Elements do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = SubTabMatches and ElementInfo.Visible ~= false
                    continue
                elseif ElementInfo.SubButton then
                    --// Check if any of the Buttons Name matches with Search
                    local Visible = false
                    if MatchesSearch(ElementInfo, Search, SubTabMatches) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end

                    if MatchesSearch(ElementInfo.SubButton, Search, SubTabMatches) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end

                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements[SubTab] += 1
                    end

                    continue
                end

                --// Check if Search matches Element's Name and if Element is Visible
                if ElementInfo.Text and MatchesSearch(ElementInfo, Search, SubTabMatches) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements[SubTab] += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in SubTab.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements[SubTab] += CheckDepbox(Depbox, Search, SubTabMatches)
            end
        end

        for SubTab, Visible in VisibleElements do
            SubTab.ButtonHolder.Visible = Visible > 0
            if Visible > 0 then
                VisibleTabs += 1
                HasVisible = true

                if Tabbox.ActiveTab == SubTab then
                    SubTab:Resize()
                elseif Tabbox.ActiveTab and VisibleElements[Tabbox.ActiveTab] == 0 then
                    SubTab:Show()
                end
            end
        end

        --// Update Tabbox Visibility if any visible
        Tabbox.BoxHolder.Visible = VisibleTabs > 0
        SyncPopOutVisibility(Tabbox)
    end

    --// Recurse into Sub Tabs (they hold their own Groupboxes/Tabboxes)
    if Tab.SubTabs then
        local VisibleSubTabs = {}

        for _, SubTab in Tab.SubTabs do
            local SubVisible
            if TryFuzzyMatch(SubTab.Name, Search) then
                --// The Sub Tab itself is the hit, so show all of its contents
                ResetTab(SubTab)
                SubVisible = true
            else
                SubVisible = ApplySearchToTab(SubTab, Search)
            end
            VisibleSubTabs[SubTab] = SubVisible

            SubTab.Button.Visible = SubVisible
            if SubVisible then
                HasVisible = true
            end
        end

        --// Move off a Sub Tab that has nothing to show
        local Active = Tab.ActiveSubTab
        if Active and VisibleSubTabs[Active] == false then
            for SubTab, SubVisible in VisibleSubTabs do
                if SubVisible then
                    SubTab:Show()
                    break
                end
            end
        end
    end

    return HasVisible
end
function ResetTab(Tab)
    if not Tab then
        return
    end

    for _, Groupbox in Tab.Groupboxes do
        for _, ElementInfo in Groupbox.Elements do
            ElementInfo.Holder.Visible = ElementInfo.Visible ~= false

            if ElementInfo.SubButton then
                ElementInfo.Base.Visible = ElementInfo.Visible
                ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
            end
        end

        for _, Depbox in Groupbox.DependencyBoxes do
            if not Depbox.Visible then
                continue
            end

            RestoreDepbox(Depbox)
        end

        Groupbox:Resize()
        Groupbox.BoxHolder.Visible = Groupbox.Visible ~= false
        SyncPopOutVisibility(Groupbox)
    end

    for _, Tabbox in Tab.Tabboxes do
        for _, SubTab in Tabbox.Tabs do
            for _, ElementInfo in SubTab.Elements do
                ElementInfo.Holder.Visible = ElementInfo.Visible ~= false

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in SubTab.DependencyBoxes do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            SubTab.ButtonHolder.Visible = true
        end

        if Tabbox.ActiveTab then
            Tabbox.ActiveTab:Resize()
        end
        Tabbox.BoxHolder.Visible = true
        SyncPopOutVisibility(Tabbox)
    end

    if Tab.SubTabs then
        for _, SubTab in Tab.SubTabs do
            ResetTab(SubTab)
            SubTab.Button.Visible = true
        end
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    local TabsToReset = {}

    if Library.GlobalSearch then
        for _, Tab in Library.Tabs do
            if typeof(Tab) == "table" and not Tab.IsKeyTab then
                table.insert(TabsToReset, Tab)
            end
        end
    elseif Library.LastSearchTab and typeof(Library.LastSearchTab) == "table" then
        table.insert(TabsToReset, Library.LastSearchTab)
    end

    for _, Tab in ipairs(TabsToReset) do
        ResetTab(Tab)
    end

    local Search = NormalizeSearch(SearchText:lower())
    if Trim(Search) == "" then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end
    if not Library.GlobalSearch and Library.ActiveTab and Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end

    Library.Searching = true

    local TabsToSearch = {}

    if Library.GlobalSearch then
        TabsToSearch = TabsToReset
        if #TabsToSearch == 0 then
            for _, Tab in Library.Tabs do
                if typeof(Tab) == "table" and not Tab.IsKeyTab then
                    table.insert(TabsToSearch, Tab)
                end
            end
        end
    elseif Library.ActiveTab then
        table.insert(TabsToSearch, Library.ActiveTab)
    end

    local FirstVisibleTab = nil
    local ActiveHasVisible = false

    for _, Tab in ipairs(TabsToSearch) do
        local HasVisible = ApplySearchToTab(Tab, Search)
        if HasVisible then
            if not FirstVisibleTab then
                FirstVisibleTab = Tab
            end
            if Tab == Library.ActiveTab then
                ActiveHasVisible = true
            end
        end
    end

    if Library.GlobalSearch then
        if ActiveHasVisible and Library.ActiveTab then
            Library.ActiveTab:RefreshSides()
        elseif FirstVisibleTab then
            local SearchMarker = SearchText
            task.defer(function()
                if Library.SearchText ~= SearchMarker then
                    return
                end

                if Library.ActiveTab ~= FirstVisibleTab then
                    FirstVisibleTab:Show()
                end
            end)
        end
        Library.LastSearchTab = nil
    else
        Library.LastSearchTab = Library.ActiveTab
    end
end

function Library:AddToRegistry(Instance, Properties)
    Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in Library.Registry do
        for Property, Index in Properties do
            local SchemeValue = GetSchemeValue(Index)

            if SchemeValue or typeof(Index) == "function" then
                Instance[Property] = SchemeValue or Index()
            end
        end
    end
end

function Library:SetDPIScale(DPIScale: number)
    Library.DPIScale = DPIScale / 100
    Library.MinSize = Library.OriginalMinSize * Library.DPIScale

    for _, UIScale in Library.Scales do
        UIScale.Scale = Library.DPIScale - (tonumber(Library.ScalesOffset[UIScale]) or 0)
    end

    for _, Option in Options do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
            Option:RefreshPool()
        end
    end

    for _, Notification in Library.Notifications do
        Notification:Resize()
    end

    (Library :: any):UpdateNotificationPositions(true)
end

function Library:GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
    local ConnectionType = typeof(Connection)
    if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
        table.insert(Library.Signals, Connection)
    end

    return Connection
end

function IsValidCustomIcon(Icon: string)
    return typeof(Icon) == "string" and (Icon:match("^rbxasset://textures/") or Icon:match("roblox%.com/asset/%?id=") or Icon:match("rbxthumb://type="))
end

local function IsCustomAssetIcon(Icon: string, IncludeAssetId: boolean)
    return typeof(Icon) == "string" and (Icon:match("^content://") or (Icon:match("^rbxasset://%x+/") or Icon:match("^rbxasset://[^/]+/")) or (IncludeAssetId == true and Icon:match("^rbxassetid://")))
end

type Icon = {
    Url: string,
    Id: number,
    IconName: string,
    ImageRectOffset: Vector2,
    ImageRectSize: Vector2,
}

type IconModule = {
    Icons: { string },
    GetAsset: (Name: string) -> Icon?,
}

local FetchIcons = false
local Icons: IconModule | nil = nil

function Library:GetIcon(IconName: string)
    if not FetchIcons or not Icons then
        return
    end

    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then
        return
    end

    return Icon
end

function Library:GetCustomIcon(IconName: string): any
    if not IconName then
        return nil
    end

    if tonumber(IconName) then
        IconName = string.format("rbxassetid://%s", tostring(IconName))
    end

    if IsCustomAssetIcon(IconName, true) then
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
        }
    elseif IsValidCustomIcon(IconName) then
        return {
            Url = IconName,
            ImageRectOffset = Vector2.zero,
            ImageRectSize = Vector2.zero,
            Custom = true,
        }
    end

    local LucideIcon = Library:GetIcon(IconName)
    if LucideIcon then
        return LucideIcon
    end

    return nil
end

function Library:ApplyLucideIcon(ImageGui: any, Icon: any, Rotation: number?)
    if not ImageGui or not Icon then
        return
    end

    if not (ImageGui:IsA("ImageLabel") or ImageGui:IsA("ImageButton")) then
        return
    end

    ImageGui.Image = Icon.Url or ImageGui.Image
    ImageGui.ImageRectOffset = Icon.ImageRectOffset or ImageGui.ImageRectOffset 
    ImageGui.ImageRectSize = Icon.ImageRectSize or ImageGui.ImageRectSize
    ImageGui.Rotation = Rotation or ImageGui.Rotation
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in Template do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

--// Creator Functions \\--
local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
    local ThemeProperties = Library.Registry[Instance] or {}

    for key, value in Table do
        if key ~= "Text" then
            local SchemeValue = GetSchemeValue(value)

            if SchemeValue or typeof(value) == "function" then
                ThemeProperties[key] = value
                value = SchemeValue or value()
            else
                ThemeProperties[key] = nil
            end
        end

        Instance[key] = value
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Instance = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Instance)
    end
    FillInstance(Properties, Instance)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            Instance.ZIndex = Properties.Parent.ZIndex
        end)
    end

    return Instance
end

--// Main Instances \\-
local function SafeParentUI(Instance: Instance, Parent: Instance | () -> Instance)
    local success, _error = pcall(function()
        if not Parent then
            Parent = CoreGui
        end

        local DestinationParent
        if typeof(Parent) == "function" then
            DestinationParent = Parent()
        else
            DestinationParent = Parent
        end

        Instance.Parent = DestinationParent
    end)

    if not (success and Instance.Parent) then
        Instance.Parent = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)
    end
end

local function ParentUI(UI: Instance, SkipHiddenUI: boolean?)
    if SkipHiddenUI then
        SafeParentUI(UI, CoreGui)
        return
    end

    pcall(protectgui, UI)
    SafeParentUI(UI, gethui)
end

local function SetAlwaysOnTop(Gui: ScreenGui, Enabled: boolean)
    if not Gui then
        return
    end

    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(Gui, "OnTopOfCoreBlur", Enabled)
        elseif setscriptable then
            setscriptable(Gui, "OnTopOfCoreBlur", true)
            Gui.OnTopOfCoreBlur = Enabled
            setscriptable(Gui, "OnTopOfCoreBlur", false)
        end
    end)
end

local ScreenGui = New("ScreenGui", {
    Name = "Obsidian",
    DisplayOrder = 998,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui

ScreenGui.DescendantRemoving:Connect(function(Instance)
    task.defer(function()
        if Instance.Parent and Instance:IsDescendantOf(ScreenGui) then
            return
        end

        Library:RemoveFromRegistry(Instance)
    end)
end)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    AnchorPoint = Vector2.zero,
    Text = "",
    ZIndex = -999,
    Parent = ScreenGui,
})

--// Floats and Overlays
local Floats = New("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 10,
    Active = false,
    Parent = ScreenGui,
})

local Overlay = New("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 20,
    Active = false,
    Parent = ScreenGui,
})

Library.Floats = Floats
Library.Overlay = Overlay

--// Cursor
local Cursor, CursorCustomImage
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = 11000,
        Parent = ScreenGui,
    })

    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 1,
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
        Parent = Cursor,
    })

    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(3, 11),
        ZIndex = 1,
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "WhiteColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        ZIndex = 2,
        Parent = Cursor,
    })

    CursorCustomImage = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        ZIndex = 3,
        Visible = false,
        Parent = Cursor,
    })
end

local function RestoreMouseIcon()
    pcall(function() 
        RunService:UnbindFromRenderStep(Library.ShowCursorBinding)
        RunService.RenderStepped:Wait()
    end)

    UserInputService.MouseIconEnabled = Library.OriginalMouseIconEnabled
    if Cursor then Cursor.Visible = false end
end

--// Notification \\--
local NotificationArea
local NotifyOrder = {}
do
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -6, 0, 6),
        Size = UDim2.new(0, 300, 1, -6),
        ZIndex = 200,
        Parent = ScreenGui,
    })
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = NotificationArea,
        })
    )
end

--// Icons \\--
local CheckIcon, ArrowIcon, ResizeIcon, KeyIcon, MoveIcon, PopOutIcon
function Library:SetIconModule(module: IconModule)
    FetchIcons = true
    Icons = module

    CheckIcon = Library:GetIcon("check")
    ArrowIcon = Library:GetIcon("chevron-up")
    ResizeIcon = Library:GetIcon("move-diagonal-2")
    KeyIcon = Library:GetIcon("key")
    MoveIcon = Library:GetIcon("move")
    PopOutIcon = Library:GetIcon("square-arrow-down-left")
end

local OnlineFetchIcons, OnlineIcons = pcall(function()
    return (loadstring(
        game:HttpGet("https://raw.githubusercontent.com/mstudio45/lucide-roblox-direct/refs/heads/main/source.lua")
    ) :: () -> IconModule)()
end)
if OnlineFetchIcons and OnlineIcons then
    Library:SetIconModule(OnlineIcons)
end

--// Lib Functions \\--
function Library:ResetCursorIcon()
    CursorCustomImage.Visible = false
    CursorCustomImage.Size = UDim2.fromOffset(20, 20)
end

function Library:ChangeCursorIcon(ImageId: string)
    if not ImageId or ImageId == "" then
        Library:ResetCursorIcon()
        return
    end

    local Icon = Library:GetCustomIcon(ImageId)
    assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

    CursorCustomImage.Visible = true
    Library:ApplyLucideIcon(CursorCustomImage, Icon)
end

function Library:ChangeCursorIconSize(Size: UDim2)
    assert(typeof(Size) == "UDim2", "UDim2 expected.")
    CursorCustomImage.Size = Size
end

function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetLighterColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, math.max(0, S - 0.1), math.min(1, V + 0.1))
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end

    return KeyCode.Name
end

function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
    local Params = Instance.new("GetTextBoundsParams")
    Params.Text = Text
    Params.RichText = true
    Params.Font = Font
    Params.Size = Size
    Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    local Bounds = TextService:GetTextBoundsAsync(Params)
    return Bounds.X, Bounds.Y
end

function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:IsInsideFrame(ParentFrame: GuiObject, Frame: GuiObject)
    local GuiPos = Frame.AbsolutePosition
    local GuiSize = Frame.AbsoluteSize

    local FramePos = ParentFrame.AbsolutePosition
    local FrameSize = ParentFrame.AbsoluteSize

    return GuiPos.X >= FramePos.X
        and GuiPos.X + GuiSize.X <= FramePos.X + FrameSize.X
        and GuiPos.Y >= FramePos.Y
        and GuiPos.Y + GuiSize.Y <= FramePos.Y + FrameSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError and Library.Notify then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function GetOverlappingDraggable(UI: GuiObject, TargetPos: Vector2?)
    local Pos1 = TargetPos or UI.AbsolutePosition
    local Size1 = UI.AbsoluteSize

    for _, Other in ipairs(Library.DraggableElements) do
        if Other == UI or not Other.Visible or not Other.Parent then
            continue
        end

        local Pos2 = Other.AbsolutePosition
        local Size2 = Other.AbsoluteSize

        if Pos1.X < Pos2.X + Size2.X and
            Pos1.X + Size1.X > Pos2.X and
            Pos1.Y < Pos2.Y + Size2.Y and
            Pos1.Y + Size1.Y > Pos2.Y then
            return Other
        end
    end

    return nil
end

function GetNonOverlappingPosition(UI: GuiObject, StartPos: UDim2?)
    local ScreenSize = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)) - Vector2.new(100, 100)
    local Start = StartPos and Vector2.new(StartPos.X.Offset, StartPos.Y.Offset) or Vector2.new(6, 6)
    local Padding = 6

    local CurrentX = Start.X
    local CurrentY = Start.Y

    local Size = UI.AbsoluteSize
    if Size.X == 0 and Size.Y == 0 then
        RunService.RenderStepped:Wait()
        Size = UI.AbsoluteSize
    end

    if Size.X == 0 then Size = Vector2.new(150, 40) end

    local MaxXInColumn = Size.X

    while true do
        local Obstacle = GetOverlappingDraggable(UI, Vector2.new(CurrentX, CurrentY))
        if not Obstacle then
            break
        end

        if Obstacle.AbsoluteSize.X > MaxXInColumn then
            MaxXInColumn = Obstacle.AbsoluteSize.X
        end

        local NextY = Obstacle.AbsolutePosition.Y + Obstacle.AbsoluteSize.Y + Padding
        if NextY + Size.Y > ScreenSize.Y - Padding then
            local NextX = CurrentX + MaxXInColumn + Padding

            if NextX + Size.X > ScreenSize.X - Padding then
                break
            end

            CurrentY = Start.Y
            CurrentX = NextX
            MaxXInColumn = Size.X
        else
            CurrentY = NextY
        end
    end

    return UDim2.fromOffset(CurrentX, CurrentY)
end

function PositionDraggable(UI: GuiObject, StartPos: UDim2?)
    UI.Position = GetNonOverlappingPosition(UI, StartPos)
end

--// Window Snapping \\--
local function GetCoreGuiInset(): (Vector2, Vector2)
    local Success, TopLeft, BottomRight = pcall(function()
        return GuiService:GetGuiInset()
    end)

    if Success and TopLeft and BottomRight then
        return TopLeft, BottomRight
    end

    return Vector2.zero, Vector2.zero
end

local function GetSnapEdges(ElemSize: Vector2, ViewportSize: Vector2, Margin: number, AvoidCoreGui: boolean)
    local SafeMin, SafeMax = Vector2.zero, ViewportSize

    if AvoidCoreGui then
        local TopLeftInset, BottomRightInset = GetCoreGuiInset()
        SafeMin = TopLeftInset
        SafeMax = ViewportSize - BottomRightInset
    end

    local TargetsX = {
        LeftEdge = SafeMin.X + Margin,
        Center = SafeMin.X + (SafeMax.X - SafeMin.X - ElemSize.X) / 2,
        RightEdge = SafeMax.X - ElemSize.X - Margin,
    }
    local TargetsY = {
        TopEdge = SafeMin.Y + Margin,
        Center = SafeMin.Y + (SafeMax.Y - SafeMin.Y - ElemSize.Y) / 2,
        BottomEdge = SafeMax.Y - ElemSize.Y - Margin,
    }

    return TargetsX, TargetsY
end

local function GetClosestSnapTarget(Value: number, Targets: { [string]: number }, Distance: number): (number?, string?)
    local ClosestName, ClosestValue, ClosestDist = nil, nil, Distance

    for Name, Target in Targets do
        local Dist = math.abs(Value - Target)
        if Dist <= ClosestDist then
            ClosestDist = Dist
            ClosestName = Name
            ClosestValue = Target
        end
    end

    return ClosestValue, ClosestName
end

local function GetSnapGuideOffset(Name: string, SnappedValue: number, ElemDimension: number): number
    if Name == "RightEdge" or Name == "BottomEdge" then
        return SnappedValue + ElemDimension
    elseif Name == "Center" then
        return SnappedValue + ElemDimension / 2
    end

    return SnappedValue -- LeftEdge / TopEdge
end

function Library:MakeDraggable(
    UI: GuiObject,
    DragFrame: GuiObject,
    IgnoreToggled: boolean?,
    IsMainWindow: boolean?,
    SnapConfig: { Enabled: boolean, Distance: number?, Margin: number?, AvoidCoreGui: boolean? }?
)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed
    local InputBegan
    local InputChanged

    local SnapGuideX, SnapGuideY

    local function GetSnapGuides()
        if not SnapGuideX then
            SnapGuideX = New("Frame", {
                BackgroundColor3 = "AccentColor",
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(0, 2, 1, 0),
                Visible = false,
                ZIndex = 10000,
                Parent = ScreenGui,
            })
        end

        if not SnapGuideY then
            SnapGuideY = New("Frame", {
                BackgroundColor3 = "AccentColor",
                BackgroundTransparency = 0.25,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(1, 0, 0, 2),
                Visible = false,
                ZIndex = 10000,
                Parent = ScreenGui,
            })
        end

        return SnapGuideX, SnapGuideY
    end

    local function HideSnapGuides()
        if SnapGuideX then
            SnapGuideX.Visible = false
        end
        if SnapGuideY then
            SnapGuideY.Visible = false
        end
    end

    InputBegan = DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            HideSnapGuides()

            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    InputChanged = UserInputService.InputChanged:Connect(function(Input: InputObject)
        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (ScreenGui and ScreenGui.Parent)
        then
            Dragging = false
            HideSnapGuides()

            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            local NewX = FramePos.X.Offset + Delta.X
            local NewY = FramePos.Y.Offset + Delta.Y

            if SnapConfig and SnapConfig.Enabled then
                local ViewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
                local Distance = SnapConfig.Distance or 28
                local Margin = SnapConfig.Margin or 8

                local AbsX = FramePos.X.Scale * ViewportSize.X + NewX
                local AbsY = FramePos.Y.Scale * ViewportSize.Y + NewY

                local ElemSize = UI.AbsoluteSize
                local TargetsX, TargetsY = GetSnapEdges(ElemSize, ViewportSize, Margin, SnapConfig.AvoidCoreGui ~= false)
                local SnappedX, SnappedXName = GetClosestSnapTarget(AbsX, TargetsX, Distance)
                local SnappedY, SnappedYName = GetClosestSnapTarget(AbsY, TargetsY, Distance)

                if SnappedX then
                    NewX = SnappedX - FramePos.X.Scale * ViewportSize.X
                end
                if SnappedY then
                    NewY = SnappedY - FramePos.Y.Scale * ViewportSize.Y
                end

                local GuideX, GuideY = GetSnapGuides()
                GuideX.Visible = SnappedX ~= nil
                if SnappedX then
                    GuideX.Position = UDim2.fromOffset(GetSnapGuideOffset(SnappedXName, SnappedX, ElemSize.X), 0)
                end

                GuideY.Visible = SnappedY ~= nil
                if SnappedY then
                    GuideY.Position = UDim2.fromOffset(0, GetSnapGuideOffset(SnappedYName, SnappedY, ElemSize.Y))
                end
            end

            UI.Position = UDim2.new(FramePos.X.Scale, NewX, FramePos.Y.Scale, NewY)
        end
    end)

    Library:GiveSignal(InputChanged)
    Library:GiveSignal(InputBegan)

    UI.Destroying:Once(function()
        if InputChanged and InputChanged.Connected then
            InputChanged:Disconnect()
        end

        if InputBegan and InputBegan.Connected then
            InputBegan:Disconnect()
        end

        if Changed and Changed.Connected then
            Changed:Disconnect()
        end

        if SnapGuideX then
            SnapGuideX:Destroy()
        end
        if SnapGuideY then
            SnapGuideY:Destroy()
        end

        local IdxChanged = table.find(Library.Signals, InputChanged)
        if IdxChanged then
            table.remove(Library.Signals, IdxChanged)
        end

        local IdxBegan = table.find(Library.Signals, InputBegan)
        if IdxBegan then
            table.remove(Library.Signals, IdxBegan)
        end
    end)
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed
    local InputBegan
    local InputChanged

    InputBegan = DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    InputChanged = UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Size = UDim2.new(
                FrameSize.X.Scale,
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
            )
            if Callback then
                Library:SafeCallback(Callback)
            end
        end
    end)

    Library:GiveSignal(InputChanged)
    Library:GiveSignal(InputBegan)

    UI.Destroying:Once(function()
        if InputChanged and InputChanged.Connected then
            InputChanged:Disconnect()
        end

        if InputBegan and InputBegan.Connected then
            InputBegan:Disconnect()
        end

        if Changed and Changed.Connected then
            Changed:Disconnect()
        end

        local IdxChanged = table.find(Library.Signals, InputChanged)
        if IdxChanged then
            table.remove(Library.Signals, IdxChanged)
        end

        local IdxBegan = table.find(Library.Signals, InputBegan)
        if IdxBegan then
            table.remove(Library.Signals, IdxBegan)
        end
    end)
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Places[Place] or { 0, 0 }
    local Size = Sizes[Place] or { 1, 0.5 }

    local Cover = New("Frame", {
        AnchorPoint = Vector2.new(Pos[1], Pos[2]),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = UDim2.fromScale(Size[1], Size[2]),
        Parent = Holder,
    })

    return Cover
end

function Library:MakeLine(Frame: GuiObject, Info)
    local Line = New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = "OutlineColor",
        LayoutOrder = Info.LayoutOrder or 0,
        Position = Info.Position,
        Size = Info.Size,
        ZIndex = Info.ZIndex or Frame.ZIndex,
        Parent = Frame,
    })

    return Line
end

function Library:AddOutline(Frame: GuiObject)
    local OutlineStroke = New("UIStroke", {
        Color = "OutlineColor",
        Thickness = 1,
        ZIndex = 2,
        Parent = Frame,
    })
    local ShadowStroke = New("UIStroke", {
        Color = "DarkColor",
        Thickness = 1.5,
        ZIndex = 1,
        Parent = Frame,
    })
    return OutlineStroke, ShadowStroke
end

function Library:AddBlank(Frame: GuiObject, Size: UDim2)
    return New("Frame", {
        BackgroundTransparency = 1,
        Size = Size or UDim2.fromScale(0, 0),
        Parent = Frame,
    })
end

--// Animations \\--
local TransparencyCache = {}
local ActiveTabTweens = setmetatable({}, { __mode = "k" })
local SUBTAB_BAR_HEIGHT = 32
local SUBTAB_IDLE_TRANSPARENCY = 0.4
local SUBTAB_ICON_SIZE = 16
local SUBTAB_SLIDE_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
--// Fraction of the chip the underline spans, and its gap above the chip's bottom edge
local SUBTAB_UNDERLINE_WIDTH = 0.66
local SUBTAB_UNDERLINE_GAP = 3
--// Transparency per shadow layer, nearest the chip first
local SUBTAB_SHADOW_TRANSPARENCY = { 0.55, 0.75 }
--// Hover squashes the chip slightly; the button itself keeps its size so the row
--// never reflows, and the underline stays put
local SUBTAB_HOVER_SCALE = 0.94
local SUBTAB_HOVER_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
--// Left inset of a sub tab row nested in the sidebar, lining it up under the tab label
local SUBTAB_SIDEBAR_INDENT = 30
--// Reserved for the row's icon, kept even when it has none so labels stay aligned
local SUBTAB_SIDEBAR_ICON_COLUMN = 20

--// Expanded dropdown panel open and close
local DROPDOWN_EXPAND_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--// Toggle switch. The off track ramps between #505050 and #8A8A8A over a white
--// FontColor; the gradient multiplies, so these are those greys as factors.
local SWITCH_WIDTH = 38
local SWITCH_TRACK_HEIGHT = 20
local SWITCH_HEIGHT = 20
local SWITCH_OFF_GRADIENT_FROM = Color3.fromRGB(80, 80, 80)
local SWITCH_OFF_GRADIENT_TO = Color3.fromRGB(138, 138, 138)
--// On keeps a gentler ramp so the track still has some depth
local SWITCH_ON_GRADIENT_FROM = Color3.fromRGB(205, 205, 205)
local SWITCH_ON_GRADIENT_TO = Color3.new(1, 1, 1)
local SWITCH_BALL_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--// Slider ball: grows when hovered or dragged, on a smooth in-out curve. It is
--// wider than the bar in both states, so it sits proud of the track.
local SLIDER_BAR_HEIGHT = 16
local SLIDER_BALL_SIZE = 18
local SLIDER_BALL_SIZE_ACTIVE = 24
local SLIDER_BALL_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
--// Room above and below the bar for the ball to overflow into
local SLIDER_BALL_MARGIN = math.ceil((SLIDER_BALL_SIZE_ACTIVE - SLIDER_BAR_HEIGHT) / 2)
--// The track ramps the opposite way to the switch: lighter at the left, darker
--// to the right, so the filled part always reads brighter than what follows it
local SLIDER_TRACK_GRADIENT_FROM = Color3.fromRGB(138, 138, 138)
local SLIDER_TRACK_GRADIENT_TO = Color3.fromRGB(64, 64, 64)

--// Sub tab content always swipes from the bottom, independent of Library.TabSwipeFrom
local SUB_TAB_SWIPE_FROM = "bottom"

--// Left padding of the search box text, leaving room for the icon
local SEARCHBOX_TEXT_INSET = 38

--// SwipeFrom overrides Library.TabSwipeFrom for this canvas; sub tabs pass their
--// own value so the window-level setting only applies to normal tabs
function Library:PlayTabAnimation(TabCanvas: CanvasGroup, Showing: boolean, OnComplete: (() -> ())?, SwipeFrom: string?)
    if not TabCanvas then
        if OnComplete then
            OnComplete()
        end

        return
    end

    local Existing = ActiveTabTweens[TabCanvas]
    if Existing then
        StopTween(Existing, true)
        ActiveTabTweens[TabCanvas] = nil
    end

    local BaseZIndex = TabCanvas.ZIndex
    if not (Library.Animations and Library.Animations.TabSwitch) then
        TabCanvas.Visible = Showing
        TabCanvas.GroupTransparency = Showing and 0 or 1
        TabCanvas.Position = UDim2.fromScale(0, 0)
        TabCanvas.ZIndex = BaseZIndex

        if OnComplete then
            OnComplete()
        end

        return
    end

    if Showing then
        local TweenInfo = Library.TabTransitionInfo or TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local Offset = Library.TabSwipeOffset or 26
        local SwipeFrom = string.lower(SwipeFrom or Library.TabSwipeFrom or "bottom")
        local StartPosition

        if SwipeFrom == "left" then
            StartPosition = UDim2.fromOffset(-Offset, 0)
        elseif SwipeFrom == "top" then
            StartPosition = UDim2.fromOffset(0, -Offset)
        elseif SwipeFrom == "right" then
            StartPosition = UDim2.fromOffset(Offset, 0)
        else -- bottom (Default)
            StartPosition = UDim2.fromOffset(0, Offset)
        end

        TabCanvas.ZIndex = BaseZIndex + 1
        TabCanvas.GroupTransparency = 1
        TabCanvas.Position = StartPosition
        TabCanvas.Visible = true

        local Tween = TweenService:Create(TabCanvas, TweenInfo, {
            GroupTransparency = 0,
            Position = UDim2.fromScale(0, 0)
        })

        ActiveTabTweens[TabCanvas] = Tween
        Tween:Play()

        local Connection; Connection = Tween.Completed:Connect(function(PlaybackState)
            if Connection then
                Connection:Disconnect()
            end

            if ActiveTabTweens[TabCanvas] == Tween then
                ActiveTabTweens[TabCanvas] = nil
            end

            if PlaybackState == Enum.PlaybackState.Cancelled then
                return
            end

            TabCanvas.ZIndex = BaseZIndex
            if OnComplete then
                OnComplete()
            end
        end)
    else
        TabCanvas.GroupTransparency = 1
        TabCanvas.Visible = false
        TabCanvas.Position = UDim2.fromScale(0, 0)
        TabCanvas.ZIndex = BaseZIndex

        if OnComplete then
            OnComplete()
        end
    end
end

--// Pop Out \\--
function Library:MakeBoxPopOut(Box: any, Options: {
    Enabled: boolean?,
    Header: GuiObject?,
    Children: (() -> { GuiObject })?,
    Before: (() -> ())?,
    After: (() -> ())?,
})
    Box.PoppedOut = false
    Box.PopOutEnabled = Options.Enabled ~= false
    Box.PopOutFloat = nil
    Box.PopOutPlaceholder = nil

    if not Box.PopOutEnabled then
        function Box:SetPoppedOut(_Value: boolean, _SetPoppedOut: UDim2) end
        function Box:TogglePoppedOut() end
        function Box:RefreshPopOutPlaceholder() end
        return
    end

    local BoxHolder = Box.BoxHolder
    local Holder = Box.Holder
    local Header = Options.Header

    local Placeholder
    local PlaceholderHeader
    local Float
    local FloatScale

    local HandledChildren: { GuiObject } = {}
    local OriginalParents: { [GuiObject]: Instance? } = {}
    local OriginalLayoutOrders: { [GuiObject]: number } = {}

    local DragState: "Idle" | "Holding" | "Dragging" = "Idle"
    local DragInput: InputObject?
    local PressMouse: Vector2?

    local DragStartPos: UDim2?
    local DragChanged: RBXScriptConnection?
    local DragDidMove = false

    --// UI Handler
    local function RaiseFloat()
        if not Float or not Floats then
            return
        end

        local MaxZ = Float.ZIndex
        for _, Child in Floats:GetChildren() do
            if Child:IsA("GuiObject") and Child ~= Float then
                MaxZ = math.max(MaxZ, Child.ZIndex)
            end
        end

        Float.ZIndex = MaxZ + 1
        if Float.Parent == Floats then
            Float.Parent = Overlay
        end
        Float.Parent = Floats
    end

    local function CreatePlaceholder()
        local Frame = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            BackgroundTransparency = 0.12,
            ClipsDescendants = true,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = BoxHolder,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius),
                Parent = Frame,
            })
        )
        Library:AddOutline(Frame)

        PlaceholderHeader = Header:Clone()
        PlaceholderHeader.Parent = Frame
        DimPopOutClone(PlaceholderHeader)

        if PopOutIcon then
            local PlaceholderDockIcon = New("ImageButton", {
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                ImageColor3 = "WhiteColor",
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(22, 22),
                ZIndex = PlaceholderHeader.ZIndex + 1,
                Parent = Frame,
            })
            Library:ApplyLucideIcon(PlaceholderDockIcon, PopOutIcon)
            PlaceholderDockIcon.MouseButton1Click:Connect(function()
                Box:SetPoppedOut(false)
            end)
        end

        return Frame
    end

    function Box:RefreshPopOutPlaceholder()
        if not Box.PoppedOut or not Placeholder or not Header then
            return
        end

        if PlaceholderHeader then
            PlaceholderHeader:Destroy()
            PlaceholderHeader = nil
        end

        PlaceholderHeader = Header:Clone()
        PlaceholderHeader.Parent = Placeholder
        DimPopOutClone(PlaceholderHeader)
    end

    function Box:SetPoppedOut(Value: boolean, FloatPosition: UDim2?)
        if not Box.PopOutEnabled or Box.Destroyed then
            return
        end

        Value = Value == true
        if Box.PoppedOut == Value then
            if Value and FloatPosition and Float then
                Float.Position = FloatPosition
            end
            return
        end

        if Value then
            if Options.Before then
                Options.Before()
            end

            local BoxChildren = if Options.Children then Options.Children() else { Holder }
            HandledChildren = {}

            table.clear(OriginalParents)
            table.clear(OriginalLayoutOrders)

            for _, Child in BoxChildren do
                if not Child or not Child.Parent then
                    continue
                end

                table.insert(HandledChildren, Child)
                OriginalParents[Child] = Child.Parent
                OriginalLayoutOrders[Child] = Child.LayoutOrder
            end

            if #HandledChildren == 0 then
                return
            end

            local Width = Holder.AbsoluteSize.X / Library.DPIScale
            if Width < 50 then
                Width = 200
            end

            local AbsolutePosition = Holder.AbsolutePosition
            Placeholder = CreatePlaceholder()
            Box.PopOutPlaceholder = Placeholder

            Float = New("Frame", {
                Active = true,
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Position = FloatPosition or UDim2.fromOffset(
                    AbsolutePosition.X / Library.DPIScale,
                    AbsolutePosition.Y / Library.DPIScale
                ),
                Size = UDim2.fromOffset(Width, 0),
                ZIndex = 1,
                Parent = Floats,
            })
            FloatScale = New("UIScale", {
                Parent = Float,
            })
            table.insert(Library.Scales, FloatScale)
            FloatScale.Scale = Library.DPIScale - (tonumber(Library.ScalesOffset[FloatScale]) or 0)

            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = Float,
            })

            for _, Child in HandledChildren do
                Child.Parent = Float
            end

            if not table.find(Library.DraggableElements, Float) then
                table.insert(Library.DraggableElements, Float)
            end

            Box.PopOutFloat = Float
            Box.PoppedOut = true
            SyncPopOutVisibility(Box)
            RaiseFloat()

            Float:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                Box:Resize()
            end)

            if Options.After then
                Options.After()
            end

            return
        end

        if Float then
            local DraggableIndex = table.find(Library.DraggableElements, Float)
            if DraggableIndex then
                table.remove(Library.DraggableElements, DraggableIndex)
            end
        end

        if FloatScale then
            local ScaleIndex = table.find(Library.Scales, FloatScale)
            if ScaleIndex then
                table.remove(Library.Scales, ScaleIndex)
            end

            FloatScale = nil
        end

        for _, Child in HandledChildren do
            if not Child or not Child.Parent then
                continue
            end

            Child.Parent = OriginalParents[Child] or BoxHolder
            Child.LayoutOrder = OriginalLayoutOrders[Child] or 0
        end

        if Placeholder then
            Placeholder:Destroy()
            Placeholder = nil
        end
        
        PlaceholderHeader = nil

        if Float then
            Float:Destroy()
            Float = nil
        end

        Box.PopOutFloat = nil
        Box.PopOutPlaceholder = nil
        Box.PoppedOut = false
        table.clear(HandledChildren)
        table.clear(OriginalParents)
        table.clear(OriginalLayoutOrders)

        if Options.After then
            Options.After()
        end
    end

    function Box:TogglePoppedOut()
        Box:SetPoppedOut(not Box.PoppedOut)
    end

    --// Drag Handler
    local function StopDrag()
        if DragState == "Idle" then
            return
        end

        local WasDragging = DragState == "Dragging"
        local DidMove = DragDidMove
        DragState = "Idle"
        DragInput = nil
        PressMouse = nil
        DragStartPos = nil
        DragDidMove = false

        if DragChanged and DragChanged.Connected then
            DragChanged:Disconnect()
            DragChanged = nil
        end

        if not WasDragging or not Box.PoppedOut or not Float then
            return
        end

        local FloatCenter = Float.AbsolutePosition + (Float.AbsoluteSize * 0.5)
        local NearPlaceholder = false
        if Library.Toggled and Placeholder and Placeholder.Parent then
            local PlaceholderCenter = Placeholder.AbsolutePosition + (Placeholder.AbsoluteSize * 0.5)
            NearPlaceholder = (FloatCenter - PlaceholderCenter).Magnitude <= Library.PopOutSnapDistance
        end

        if NearPlaceholder or (DidMove and not IsScreenPointOutsideMain(FloatCenter)) then
            Box:SetPoppedOut(false)
        end
    end

    local function BeginDrag(Input: InputObject)
        if DragState ~= "Idle" or Box.Destroyed or not (ScreenGui and ScreenGui.Parent) then
            return
        end

        local Point = Vector2.new(Input.Position.X, Input.Position.Y)
        local Top = GetTopFloatAt(Point)
        if Box.PoppedOut then
            if not Float or Top ~= Float then
                return
            end
        elseif Top ~= nil and not Header:IsDescendantOf(Top) then
            return
        end

        DragState = "Holding"
        DragInput = Input
        PressMouse = Vector2.new(Input.Position.X, Input.Position.Y)
        DragStartPos = nil
        DragDidMove = false

        if Box.PoppedOut and Float then
            RaiseFloat()
        end

        DragChanged = Input.Changed:Connect(function()
            if Input.UserInputState == Enum.UserInputState.End then
                StopDrag()
            end
        end)

        task.delay(Library.PopOutHoldTime, function()
            if (DragState :: any) ~= "Holding" or DragInput ~= Input then
                return
            end

            DragState = "Dragging"
            if Box.PoppedOut and Float then
                RaiseFloat()
                DragStartPos = Float.Position
            end
        end)
    end

    local function UpdateDrag(Input: InputObject)
        if DragState ~= "Dragging" or not PressMouse then
            return
        end
        if not (ScreenGui and ScreenGui.Parent) then
            StopDrag()
            return
        end

        local MousePosition = Vector2.new(Input.Position.X, Input.Position.Y)
        local Delta = MousePosition - PressMouse

        if not Box.PoppedOut then
            if Delta.Magnitude < Library.PopOutDragThreshold then
                return
            end

            Box:SetPoppedOut(true)
            if not Float then
                return
            end

            RaiseFloat()
            DragStartPos = Float.Position
            DragDidMove = true
        elseif Delta.Magnitude >= Library.PopOutDragThreshold then
            DragDidMove = true
        end

        if Float and DragStartPos then
            Float.Position = UDim2.new(
                DragStartPos.X.Scale,
                DragStartPos.X.Offset + Delta.X,
                DragStartPos.Y.Scale,
                DragStartPos.Y.Offset + Delta.Y
            )
        end
    end

    local function BindDragSource(Gui: GuiObject)
        Library:GiveSignal(Gui.InputBegan:Connect(function(Input: InputObject)
            if IsClickInput(Input) then
                BeginDrag(Input)
            end
        end))
    end

    BindDragSource(Header)
    for _, Descendant in Header:QueryDescendants("GuiObject:not(ImageButton)") do
        BindDragSource(Descendant)
    end

    Library:GiveSignal(Header.DescendantAdded:Connect(function(Descendant)
        if Descendant:IsA("GuiObject") and not Descendant:IsA("ImageButton") then
            BindDragSource(Descendant)
        end
    end))

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if IsHoverInput(Input) then
            UpdateDrag(Input)
        end
    end))
end

--// Deprecated \\--
function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
    warn("Obsidian:MakeOutline is deprecated, please use Obsidian:AddOutline instead.")
    local Holder = New("Frame", {
        BackgroundColor3 = "DarkColor",
        Position = UDim2.fromOffset(-2, -2),
        Size = UDim2.new(1, 4, 1, 4),
        ZIndex = ZIndex,
        Parent = Frame,
    })

    local Outline = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = ZIndex,
        Parent = Holder,
    })

    if Corner and Corner > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 1),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner),
            Parent = Outline,
        })
    end

    return Holder, Outline
end

function Library:AddDraggableLabel(...)
    local Params = select(1, ...)
    local Text
    local Icon
    local IconPosition = "left"

    if typeof(Params) == "table" then
        Text = Params.Text
        Icon = Params.Icon
        IconPosition = Params.IconPosition or "left"
    elseif typeof(Params) == "string" then
        Text = Params
        Icon = select(2, ...)
        IconPosition = select(3, ...) or "left"
    end

    if typeof(IconPosition) ~= "string" then
        IconPosition = "left"
    end

    IconPosition = string.lower(IconPosition)
    assert(IconPosition == "left" or IconPosition == "right", "Icon Position needs to be either 'left' or 'right'.")

    local DraggableLabel = {
        Connections = {},
        Destroyed = false
    }

    local IconImage
    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(6, 6),
        Text = Text,
        TextSize = 15,
        ZIndex = 1,
        Parent = Floats,
    })

    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Label,
        })
    )

    local Padding = New("UIPadding", {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 6),
        Parent = Label,
    })
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Label,
        })
    )

    Library:AddOutline(Label)
    Library:MakeDraggable(Label, Label, true)

    function DraggableLabel:SetText(Text: string)
        Label.Text = Text
    end

    function DraggableLabel:SetIcon(NewIcon: string)
        Icon = NewIcon

        local IsNotEmpty = Icon and Trim(tostring(Icon)) ~= ""
        if IsNotEmpty then
            local CustomIcon = Library:GetCustomIcon(Icon)
            assert(CustomIcon, "Icon must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            IconImage = IconImage or New("ImageLabel", {
                BackgroundTransparency = 1,
                ImageColor3 = "FontColor",
                Size = UDim2.fromOffset(16, 16),
                ZIndex = 2,
                Parent = Label,
            })

            Library:ApplyLucideIcon(IconImage, CustomIcon)
        end

        if IconImage then IconImage.Visible = IsNotEmpty end
        DraggableLabel:SetIconPosition(IconPosition)
    end

    function DraggableLabel:SetIconPosition(NewPosition: string)
        IconPosition = string.lower(NewPosition)
        assert(IconPosition == "left" or IconPosition == "right", "Icon Position needs to be either 'left' or 'right'.")

        local IsNotEmpty = Icon and Trim(tostring(Icon)) ~= ""
        Padding.PaddingLeft = UDim.new(0, (IsNotEmpty and IconPosition == "left") and 34 or 12)
        Padding.PaddingRight = UDim.new(0, (IsNotEmpty and IconPosition == "right") and 34 or 12)

        if IconImage then
            if IconPosition == "left" then
                IconImage.AnchorPoint = Vector2.new(0, 0.5)
                IconImage.Position = UDim2.new(0, -22, 0.5, 0)
            else
                IconImage.AnchorPoint = Vector2.new(1, 0.5)
                IconImage.Position = UDim2.new(1, 22, 0.5, 0)
            end
        end
    end

    function DraggableLabel:SetVisible(Visible: boolean)
        Label.Visible = Visible
    end

    DraggableLabel:SetIcon(Icon)
    DraggableLabel.Label = Label

    if not table.find(Library.DraggableElements, Label) then
        table.insert(Library.DraggableElements, Label)
    end

    PositionDraggable(Label, Label.Position)

    function DraggableLabel:Destroy()
        DraggableLabel.Destroyed = true

        if DraggableLabel.Connections then
            for _, connection in DraggableLabel.Connections do
                connection:Disconnect()
            end
        end

        local ElemIdx = table.find(Library.DraggableElements, Label)
        if ElemIdx then
            table.remove(Library.DraggableElements, ElemIdx)
        end

        if Label then
            Label:Destroy()
        end
    end

    return DraggableLabel
end

function Library:AddDraggableButton(...)
    local Params = select(1, ...)

    local Text
    local Func
    local ExcludeScaling
    local ExcludeDragging

    if typeof(Params) == "table" then
        Text = Params.Text
        Func = Params.Callback or Params.Func
        ExcludeScaling = Params.ExcludeScaling
        ExcludeDragging = Params.ExcludeDragging
    elseif typeof(Params) == "string" then
        Text = Params
        Func = select(2, ...)
        ExcludeScaling = select(3, ...)
        ExcludeDragging = select(4, ...)
    end

    local DraggableButton = {
        Connections = {},
        Destroyed = false
    }

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = 1,
        Parent = Floats,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Button,
        })
    )
    if not ExcludeScaling then
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = Button,
            })
        )
    end
    Library:AddOutline(Button)

    local DragThreshold = if ExcludeDragging then 0.25 else math.huge
    Button.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        local Start = tick()

        local Changed
        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            local IsLikelyDragging = tick() - Start > DragThreshold
            if IsLikelyDragging then
                return
            end

            Library:SafeCallback(Func, DraggableButton)

            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    function DraggableButton:SetText(Text: string)
        local X, Y = Library:GetTextBounds(Text, Library.Scheme.Font, 16)

        Button.Text = Text
        Button.Size = UDim2.fromOffset(X * 2, Y * 2)
    end

    Library:MakeDraggable(Button, Button, true)
    DraggableButton:SetText(Text)
    DraggableButton.Button = Button

    if not table.find(Library.DraggableElements, Button) then
        table.insert(Library.DraggableElements, Button)
    end

    PositionDraggable(Button, Button.Position)

    function DraggableButton:Destroy()
        DraggableButton.Destroyed = true

        if DraggableButton.Connections then
            for _, connection in DraggableButton.Connections do
                connection:Disconnect()
            end
        end

        local ElemIdx = table.find(Library.DraggableElements, Button)
        if ElemIdx then
            table.remove(Library.DraggableElements, ElemIdx)
        end

        if Button then
            Button:Destroy()
        end
    end

    return DraggableButton
end

function Library:AddDraggableMenu(Name: string)
    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 1,
        Parent = Floats,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Holder,
        })
    )
    Library:AddOutline(Holder)

    Library:MakeLine(Holder, {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = Name,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Label,
    })

    local Container = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 35),
        Size = UDim2.new(1, 0, 1, -35),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        Parent = Container,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        PaddingTop = UDim.new(0, 7),
        Parent = Container,
    })

    Library:MakeDraggable(Holder, Label, true)

    if not table.find(Library.DraggableElements, Holder) then
        table.insert(Library.DraggableElements, Holder)
    end

    PositionDraggable(Holder, Holder.Position)

    return Holder, Container
end

function Library:AddDraggableImageButton(...)
    local Params = select(1, ...)

    local Icon
    local IconSize
    local Func
    local ExcludeScaling
    local ExcludeDragging

    if typeof(Params) == "table" then
        Icon = Params.Icon
        IconSize = Params.IconSize or 24
        Func = Params.Callback or Params.Func
        ExcludeScaling = Params.ExcludeScaling
        ExcludeDragging = Params.ExcludeDragging
    elseif typeof(Params) == "string" or typeof(Params) == "number" then
        Icon = Params
        IconSize = select(2, ...)
        Func = select(3, ...)
        ExcludeScaling = select(4, ...)
        ExcludeDragging = select(5, ...)
    end

    local DraggableImageButton = {}

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(IconSize + 12, IconSize + 12),
        Text = "",
        ZIndex = 1,
        Parent = Floats,
    })

    local IconImage = New("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(IconSize, IconSize),
        ImageColor3 = "FontColor",
        ZIndex = 2,
        Parent = Button,
    })

    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Button,
        })
    )
    if not ExcludeScaling then
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = Button,
            })
        )
    end
    Library:AddOutline(Button)

    local DragThreshold = if ExcludeDragging then 0.25 else math.huge
    Button.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        local Start = tick()

        local Changed
        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            local IsLikelyDragging = tick() - Start > DragThreshold
            if IsLikelyDragging then
                return
            end

            Library:SafeCallback(Func, DraggableImageButton)

            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)

    function DraggableImageButton:SetIcon(NewIcon: string)
        Icon = NewIcon or Icon

        local CustomIcon = Library:GetCustomIcon(Icon)
        assert(CustomIcon, "Icon must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        Library:ApplyLucideIcon(IconImage, CustomIcon)
    end

    function DraggableImageButton:SetIconSize(NewSize: number)
        IconSize = NewSize
        IconImage.Size = UDim2.fromOffset(IconSize, IconSize)
        Button.Size = UDim2.fromOffset(IconSize + 12, IconSize + 12)
    end

    Library:MakeDraggable(Button, Button, true)
    DraggableImageButton:SetIcon(Icon)
    DraggableImageButton.Button = Button

    if not table.find(Library.DraggableElements, Button) then
        table.insert(Library.DraggableElements, Button)
    end

    PositionDraggable(Button, Button.Position)

    return DraggableImageButton
end

--// Watermark \\--
function Library:AddWatermark(Segments: { any }?)
    local Watermark = {
        Connections = {},
        Destroyed = false,
        Cells = {},
    }

    local Holder = New("Frame", {
        AnchorPoint = Vector2.zero,
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 10,
        Parent = ScreenGui,
    })

    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Holder,
    })

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 3),
        PaddingRight = UDim.new(0, 3),
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        Parent = Holder,
    })

    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Holder,
        })
    )

    Library:AddOutline(Holder)
    Library:MakeDraggable(Holder, Holder, true)

    Watermark.Holder = Holder

    local function BuildCell(Data: any, Order: number)
        local Cell = {}

        if Order > 1 then
            New("Frame", {
                BackgroundColor3 = "OutlineColor",
                BorderSizePixel = 0,
                LayoutOrder = Order * 2 - 1,
                Size = UDim2.fromOffset(1, 14),
                ZIndex = 11,
                Parent = Holder,
            })
        end

        local Frame = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            LayoutOrder = Order * 2,
            Size = UDim2.fromOffset(0, 20),
            ZIndex = 11,
            Parent = Holder,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5),
            Parent = Frame,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = Frame,
        })

        local UseAccent = Data.Accent == true

        -- Player card: a rounded avatar bust rendered ahead of the label.
        -- Triggered by Data.Player (Player instance / UserId / username) or Data.PlayerCard = true.
        local PlayerUserId, PlayerObject
        if Data.Player ~= nil or Data.PlayerCard == true then
            local Value = Data.Player
            if typeof(Value) == "Instance" and Value:IsA("Player") then
                PlayerObject = Value
            elseif typeof(Value) == "number" then
                PlayerUserId = Value
            elseif typeof(Value) == "string" and Trim(Value) ~= "" then
                PlayerObject = Players:FindFirstChild(Value)
            else
                PlayerObject = LocalPlayer
            end

            if PlayerObject then
                PlayerUserId = PlayerObject.UserId
            end
        end

        if PlayerUserId then
            local Avatar = New("ImageLabel", {
                BackgroundColor3 = "OutlineColor",
                BackgroundTransparency = 0,
                Image = string.format(
                    "rbxthumb://type=AvatarBust&id=%s&w=48&h=48",
                    tostring(PlayerUserId)
                ),
                LayoutOrder = 0,
                Size = UDim2.fromOffset(18, 18),
                ZIndex = 12,
                Parent = Frame,
            })

            -- Follow the UI radius like other pills: fully round while radius > 0,
            -- square when it is dialled down to 0.
            table.insert(
                Library.PillCorners,
                New("UICorner", {
                    CornerRadius = Library.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0),
                    Parent = Avatar,
                })
            )

            New("UIStroke", {
                Color = UseAccent and "AccentColor" or "OutlineColor",
                Thickness = 1,
                Parent = Avatar,
            })

            -- Default the label to the player's name when no explicit text is given.
            -- Data.NameType selects which name: "Username"/"Name" uses the account
            -- name, anything else (default) uses the display name.
            if Data.Text == nil and PlayerObject then
                local UseUsername = typeof(Data.NameType) == "string"
                    and (string.lower(Data.NameType) == "username" or string.lower(Data.NameType) == "name")
                local Display = PlayerObject.DisplayName ~= "" and PlayerObject.DisplayName or PlayerObject.Name
                Data = table.clone(Data)
                Data.Text = UseUsername and PlayerObject.Name or Display
            end
        end

        local CustomIcon = Data.Icon and Trim(tostring(Data.Icon)) ~= "" and Library:GetCustomIcon(Data.Icon)
        if CustomIcon then
            New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = CustomIcon.Url,
                ImageColor3 = UseAccent and "AccentColor" or "FontColor",
                ImageRectOffset = CustomIcon.ImageRectOffset,
                ImageRectSize = CustomIcon.ImageRectSize,
                LayoutOrder = 1,
                Size = UDim2.fromOffset(15, 15),
                ZIndex = 12,
                Parent = Frame,
            })
        end

        local Getter = typeof(Data.Text) == "function" and Data.Text or nil
        local InitialText = Getter and select(2, pcall(Getter)) or Data.Text

        local TextLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            Size = UDim2.fromOffset(0, 20),
            Text = typeof(InitialText) == "string" and InitialText or "",
            TextColor3 = UseAccent and "AccentColor" or "FontColor",
            TextSize = 15,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 12,
            Parent = Frame,
        })

        Cell.Frame = Frame
        Cell.Label = TextLabel
        Cell.Getter = Getter
        return Cell
    end

    function Watermark:Refresh()
        for _, Cell in Watermark.Cells do
            if Cell.Getter and Cell.Label then
                local Ok, Value = pcall(Cell.Getter)
                if Ok and typeof(Value) == "string" then
                    Cell.Label.Text = Value
                end
            end
        end
    end

    function Watermark:SetSegments(NewSegments: { any })
        for _, Cell in Watermark.Cells do
            if Cell.Frame then Cell.Frame:Destroy() end
        end
        table.clear(Watermark.Cells)

        -- clear stray dividers left behind
        for _, Child in Holder:GetChildren() do
            if Child:IsA("Frame") and Child.Size == UDim2.fromOffset(1, 14) then
                Child:Destroy()
            end
        end

        for Index, Data in NewSegments do
            local Segment = typeof(Data) == "table" and Data or { Text = tostring(Data) }
            Watermark.Cells[Index] = BuildCell(Segment, Index)
        end
    end

    function Watermark:SetText(Index: number, Text: string)
        local Cell = Watermark.Cells[Index]
        if Cell and Cell.Label then
            Cell.Label.Text = Text
        end
    end

    function Watermark:SetVisible(Visible: boolean)
        Holder.Visible = Visible
    end

    function Watermark:Destroy()
        Watermark.Destroyed = true

        for _, connection in Watermark.Connections do
            connection:Disconnect()
        end

        local ElemIdx = table.find(Library.DraggableElements, Holder)
        if ElemIdx then
            table.remove(Library.DraggableElements, ElemIdx)
        end

        if Holder then
            Holder:Destroy()
        end
    end

    if not table.find(Library.DraggableElements, Holder) then
        table.insert(Library.DraggableElements, Holder)
    end

    Watermark:SetSegments(Segments or {})
    PositionDraggable(Holder, Holder.Position)

    -- Auto-refresh any function-valued segments every Watermark.RefreshRate seconds.
    Watermark.RefreshRate = 1
    local Accumulator = 0
    table.insert(
        Watermark.Connections,
        RunService.Heartbeat:Connect(function(DeltaTime)
            if Watermark.Destroyed or not Holder.Visible then
                return
            end

            Accumulator += DeltaTime
            if Accumulator >= Watermark.RefreshRate then
                Accumulator = 0
                Watermark:Refresh()
            end
        end)
    )

    return Watermark
end

--// Watermark - Backwards Compatibility \\--
do
    local DefaultWatermark = Library:AddWatermark()
    DefaultWatermark:SetVisible(false)
    Library.Watermark = DefaultWatermark

    function Library:SetWatermark(Text: string)
        DefaultWatermark:SetSegments({ { Text = Text } })
    end

    function Library:SetWatermarkVisibility(Visible: boolean)
        DefaultWatermark:SetVisible(Visible)
    end
end

--// Context Menu \\--
local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?,
    IgnoreCornerRadius: boolean?,
    SpecificCornersOnly: ("top" | "bottom" | "no_left" | "no_top_left")?, -- stupid way of doing this
    AnimationType: ("Dropdown" | "KeyPicker" | "none")?
)
    local Menu
    local HolderGui = Holder:FindFirstAncestorOfClass("ScreenGui")
    local ParentGui = Overlay
    if HolderGui and HolderGui ~= ScreenGui and Library.ActiveLoading and HolderGui == Library.ActiveLoading.ScreenGui then
        ParentGui = HolderGui
    end

    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "BackgroundColor",
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = List == 2 and 2 or 0,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = 1,
            Parent = ParentGui,
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = 1,
            Parent = ParentGui,
        })
    end
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Menu,
        })
    )

    New("UIStroke", {
        Color = "OutlineColor",
        Parent = Menu,
    })

    local Corner;
    if IgnoreCornerRadius ~= true then
        if SpecificCornersOnly == "top" then
            Corner = New("UICorner", {
                TopLeftRadius = UDim.new(0, Library.CornerRadius / 2),
                TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomRightRadius = UDim.new(0, 0),
                BottomLeftRadius = UDim.new(0, 0),
                Parent = Menu,
            }); table.insert(Library.SpecificCorners, Corner)
        elseif SpecificCornersOnly == "bottom" then
            Corner = New("UICorner", {
                TopLeftRadius = UDim.new(0, 0),
                TopRightRadius = UDim.new(0, 0),
                BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Menu,
            }); table.insert(Library.SpecificCorners, Corner)
        elseif SpecificCornersOnly == "no_left" then
            Corner = New("UICorner", {
                TopLeftRadius = UDim.new(0, 0),
                TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomLeftRadius = UDim.new(0, 0),
                Parent = Menu,
            }); table.insert(Library.SpecificCorners, Corner)
        elseif SpecificCornersOnly == "no_top_left" then
            Corner = New("UICorner", {
                TopLeftRadius = UDim.new(0, 0),
                TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Menu,
            }); table.insert(Library.SpecificCorners, Corner)
        else
            Corner = New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Menu,
            }); table.insert(Library.Corners, Corner)
        end
    end

    local Table = {
        Connections = {},
        Destroyed = false,

        Active = false,
        ActiveCallback = ActiveCallback,

        Holder = Holder,
        Menu = Menu,
        Corner = Corner,

        List = nil,
        Signal = nil,

        Size = Size,
        AutoSizeY = List == 1,

        OpenCloseTween = nil,
        Animated = function()
            if not AnimationType or AnimationType == "none" then
                return false
            end

            if not (Library.Animations and Library.Animations[AnimationType] == true) then
                return false
            end

            return true, Library[string.format("%sTransitionInfo", AnimationType)] or TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    }

    if List == 1 then
        Table.List = New("UIListLayout", {
            Parent = Menu,
        })
    end

    function Table:Open()
        if CurrentMenu == Table then
            return
        elseif CurrentMenu then
            CurrentMenu:Close()
        end

        CurrentMenu = Table
        Table.Active = true
        Menu.ZIndex = 1

        local TargetParent = if ParentGui == Overlay then Overlay else ParentGui
        Menu.Parent = nil
        Menu.Parent = TargetParent

        --// Menu.Position is relative to TargetParent, but Holder.AbsolutePosition
        --// is screen-absolute. Subtract the parent's own AbsolutePosition so the
        --// menu lands under the holder even when the parent is inset-shifted
        --// (e.g. the Overlay sits at a negative Y from the GUI inset).
        local ParentAbs = TargetParent.AbsolutePosition
        if typeof(Offset) == "function" then
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X - ParentAbs.X + Offset()[1]),
                math.floor(Holder.AbsolutePosition.Y - ParentAbs.Y + Offset()[2])
            )
        else
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X - ParentAbs.X + Offset[1]),
                math.floor(Holder.AbsolutePosition.Y - ParentAbs.Y + Offset[2])
            )
        end

        local TargetSize = typeof(Table.Size) == "function" and Table.Size() or Table.Size

        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, true)
        end

        if Table.OpenCloseTween then
            StopTween(Table.OpenCloseTween, true)
            Table.OpenCloseTween = nil
        end

        local IsAnimated, TweenInfo = Table.Animated()
        if IsAnimated == true then
            local OpenSize = TargetSize
            if Table.AutoSizeY then
                local FullHeight = Menu.AbsoluteSize.Y

                Menu.AutomaticSize = Enum.AutomaticSize.None
                OpenSize = UDim2.new(TargetSize.X.Scale, TargetSize.X.Offset, 0, FullHeight)
            end

            Menu.Size = UDim2.new(OpenSize.X.Scale, OpenSize.X.Offset, 0, 0)
            Menu.Visible = true

            local Tween = TweenService:Create(Menu, TweenInfo, { Size = OpenSize })
            Table.OpenCloseTween = Tween

            local Connection; Connection = Library:GiveSignal(Tween.Completed:Once(function()
                if Connection then
                    Connection:Disconnect()
                end

                if Table.OpenCloseTween == Tween then
                    StopTween(Table.OpenCloseTween, true)
                    Table.OpenCloseTween = nil

                    if Table.AutoSizeY then
                        Menu.AutomaticSize = Enum.AutomaticSize.Y
                    end
                end
            end))

            Tween:Play()
        else
            Menu.Size = TargetSize
            Menu.Visible = true
        end

        Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            local ParentAbs = TargetParent.AbsolutePosition
            if typeof(Offset) == "function" then
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X - ParentAbs.X + Offset()[1]),
                    math.floor(Holder.AbsolutePosition.Y - ParentAbs.Y + Offset()[2])
                )
            else
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X - ParentAbs.X + Offset[1]),
                    math.floor(Holder.AbsolutePosition.Y - ParentAbs.Y + Offset[2])
                )
            end

            local HolderAllowed = Library:IsInsideFrame(Library.WindowContainer, Holder)
            if not HolderAllowed then
                for _, Surface in Library.DraggableElements do
                    if not (Surface and Library:IsInsideFrame(Surface, Holder)) then
                        continue
                    end

                    HolderAllowed = true
                    break
                end
            end

            if not HolderAllowed and Table.Active then
                Table:Close()
            end
        end)
    end

    function Table:Close()
        if CurrentMenu ~= Table then
            return
        end

        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end

        Table.Active = false
        CurrentMenu = nil

        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, false)
        end

        if Table.OpenCloseTween then
            StopTween(Table.OpenCloseTween, true)
            Table.OpenCloseTween = nil
        end

        local IsAnimated, TweenInfo = Table.Animated()
        if IsAnimated == true then
            if Table.AutoSizeY then
                Menu.AutomaticSize = Enum.AutomaticSize.None
            end

            local CurrentSize = Menu.Size
            local CollapsedSize = UDim2.new(CurrentSize.X.Scale, CurrentSize.X.Offset, 0, 0)

            local Tween = TweenService:Create(Menu, TweenInfo, { Size = CollapsedSize })
            Table.OpenCloseTween = Tween

            local Connection; Connection = Library:GiveSignal(Tween.Completed:Once(function(PlaybackState)
                if Connection then
                    Connection:Disconnect()
                end

                if Table.OpenCloseTween == Tween then
                    StopTween(Table.OpenCloseTween, true)
                    Table.OpenCloseTween = nil

                    Menu.Visible = false
                    if Table.AutoSizeY then
                        Menu.AutomaticSize = Enum.AutomaticSize.Y
                    end
                end
            end))

            Tween:Play()
        else
            Menu.Visible = false
        end
    end

    function Table:Toggle()
        if Table.Active then
            Table:Close()
        else
            Table:Open()
        end
    end

    function Table:SetSize(Size)
        Table.Size = Size
        Menu.Size = typeof(Size) == "function" and Size() or Size
    end

    function Table:Destroy()
        Table.Destroyed = true

        if Table.Connections then
            for _, Connection in Table.Connections do
                Connection:Disconnect()
            end
        end

        if CurrentMenu == Table then
            Table:Close()
        end

        if Table.OpenCloseTween then
            StopTween(Table.OpenCloseTween, true)
            Table.OpenCloseTween = nil
        end

        local MenuIndex = table.find(Library.ContextMenus, Table)
        if MenuIndex then
            table.remove(Library.ContextMenus, MenuIndex)
        end

        if Menu then
            Menu:Destroy()
        end
    end

    table.insert(Library.ContextMenus, Table)
    return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
    if Library.Unloaded then
        return
    end

    if IsClickInput(Input, true) then
        local Location = Input.Position

        if
            CurrentMenu
            and not (
                Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
            )
        then
            CurrentMenu:Close()
        end
    end
end))

--// Tooltip \\--
local TooltipLabel = New("TextLabel", {
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = "BackgroundColor",
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = 30,
    Parent = ScreenGui,
})
New("UIPadding", {
    PaddingBottom = UDim.new(0, 2),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    PaddingTop = UDim.new(0, 2),
    Parent = TooltipLabel,
})
table.insert(
    Library.Scales,
    New("UIScale", {
        Parent = TooltipLabel,
    })
)
local TooltipStroke = New("UIStroke", {
    Color = "OutlineColor",
    Parent = TooltipLabel,
})
--// Drives the pop animation. Kept out of Library.Scales on purpose so the DPI
--// scaling pass doesn't overwrite the pop each time it runs.
local TooltipPopScale = New("UIScale", {
    Scale = 1,
    Parent = TooltipLabel,
})
table.insert(
    Library.Corners,
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
        Parent = TooltipLabel,
    })
)
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    if Library.Unloaded then
        return
    end

    local X, _ = Library:GetTextBounds(
        TooltipLabel.Text,
        TooltipLabel.FontFace,
        TooltipLabel.TextSize,
        (workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 8) / Library.DPIScale
    )

    TooltipLabel.Size = UDim2.fromOffset(X + 8, 0)
end)

--// Smooth pop animation \\--
--// A soft ease-out fade + subtle scale-up on show, and a quick fade + settle on
--// hide. A generation id makes the async hide safe when show/hide interleave as
--// the pointer moves between elements.
local TOOLTIP_SHOW_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TOOLTIP_HIDE_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TOOLTIP_START_SCALE = 0.85

local TooltipAnimId = 0
local TooltipTweens = {}

local function StopTooltipTweens()
    for Index = #TooltipTweens, 1, -1 do
        local Tween = table.remove(TooltipTweens, Index)
        Tween:Cancel()
    end
end

local function ShowTooltip()
    TooltipAnimId += 1
    StopTooltipTweens()

    --// Start from a slightly small, fully transparent state every time so the
    --// pop replays even when hopping straight from one element to the next
    TooltipPopScale.Scale = TOOLTIP_START_SCALE
    TooltipLabel.BackgroundTransparency = 1
    TooltipLabel.TextTransparency = 1
    TooltipStroke.Transparency = 1
    TooltipLabel.Visible = true

    local Scale = TweenService:Create(TooltipPopScale, TOOLTIP_SHOW_TWEEN, { Scale = 1 })
    local Body = TweenService:Create(TooltipLabel, TOOLTIP_SHOW_TWEEN, { BackgroundTransparency = 0, TextTransparency = 0 })
    local Stroke = TweenService:Create(TooltipStroke, TOOLTIP_SHOW_TWEEN, { Transparency = 0 })

    TooltipTweens = { Scale, Body, Stroke }
    Scale:Play()
    Body:Play()
    Stroke:Play()
end

local function HideTooltip()
    TooltipAnimId += 1
    local AnimId = TooltipAnimId
    StopTooltipTweens()

    if not TooltipLabel.Visible then
        return
    end

    local Scale = TweenService:Create(TooltipPopScale, TOOLTIP_HIDE_TWEEN, { Scale = TOOLTIP_START_SCALE })
    local Body = TweenService:Create(TooltipLabel, TOOLTIP_HIDE_TWEEN, { BackgroundTransparency = 1, TextTransparency = 1 })
    local Stroke = TweenService:Create(TooltipStroke, TOOLTIP_HIDE_TWEEN, { Transparency = 1 })

    TooltipTweens = { Scale, Body, Stroke }
    Body.Completed:Connect(function(State)
        --// A newer show/hide bumped the id (or cancelled this tween), so leave
        --// the shared label to whoever owns it now
        if State ~= Enum.PlaybackState.Completed or AnimId ~= TooltipAnimId then
            return
        end
        TooltipLabel.Visible = false
    end)
    Scale:Play()
    Body:Play()
    Stroke:Play()
end

local CurrentHoverInstance
function Library:AddTooltip(InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject, Variant: string?)
    local TooltipTable = {
        Disabled = false,
        Hovering = false,
        Signals = {},
        Variant = Variant,
    }

    local function DoHover()
        if
            CurrentHoverInstance == HoverInstance
            or Library.ActiveDialog
            or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
            or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
            or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
            --// Sidebar tab hints only earn their keep when the label is hidden,
            --// i.e. while the sidebar is compact
            or (TooltipTable.Variant == "Sidebar" and not Library.SidebarCompacted)
        then
            return
        end
        CurrentHoverInstance = HoverInstance

        local HolderGui = HoverInstance:FindFirstAncestorOfClass("ScreenGui")
        if HolderGui and HolderGui ~= ScreenGui and Library.ActiveLoading and HolderGui == Library.ActiveLoading.ScreenGui then
            TooltipLabel.Parent = HolderGui
        else
            TooltipLabel.Parent = ScreenGui
        end

        TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
        ShowTooltip()

        while
            (Library.Toggled or Library.ActiveLoading)
            and not Library.ActiveDialog
            and Library:MouseIsOverFrame(HoverInstance, Mouse)
            and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
        do
            TooltipLabel.Position = UDim2.fromOffset(
                Mouse.X + (Library.ShowCustomCursor and 8 or 14),
                Mouse.Y + (Library.ShowCustomCursor and 8 or 12)
            )

            RunService.RenderStepped:Wait()
        end

        HideTooltip()
        CurrentHoverInstance = nil
    end

    local function GiveSignal(Connection: RBXScriptConnection | RBXScriptSignal)
        local ConnectionType = typeof(Connection)
        if Connection and (ConnectionType == "RBXScriptConnection" or ConnectionType == "RBXScriptSignal") then
            table.insert(TooltipTable.Signals, Connection)
        end

        return Connection
    end

    GiveSignal(HoverInstance.MouseEnter:Connect(DoHover))
    GiveSignal(HoverInstance.MouseMoved:Connect(DoHover))
    GiveSignal(HoverInstance.MouseLeave:Connect(function()
        if CurrentHoverInstance ~= HoverInstance then
            return
        end

        HideTooltip()
        CurrentHoverInstance = nil
    end))

    function TooltipTable:Destroy()
        for Index = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Index)
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end

        if CurrentHoverInstance == HoverInstance then
            if TooltipLabel then
                HideTooltip()
            end

            CurrentHoverInstance = nil
        end
    end

    table.insert(Tooltips, TooltipLabel)
    return TooltipTable
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddKeyPicker(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.KeyPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        if ParentObj.Type == "Button" or ParentObj.Type == "SubButton" then
            assert(Info.Mode == "Press", "KeyPicker on Buttons can only be applied with the 'Press' mode.")

            ToggleLabel = ParentObj.Base
        end

        local KeyPicker = {
            Connections = {},

            Text = Info.Text,
            Value = Info.Default, -- Key
            Modifiers = Info.DefaultModifiers, -- Modifiers
            DisplayValue = Info.Default, -- Picker Text

            Blacklisted = Info.Blacklisted,
            BlacklistedModifiers = Info.BlacklistedModifiers,
            Whitelisted = Info.Whitelisted,
            WhitelistedModifiers = Info.WhitelistedModifiers,

            Toggled = false,
            Mode = Info.Mode,
            SyncToggleState = Info.SyncToggleState,

            Callback = Info.Callback,
            ChangedCallback = Info.ChangedCallback,
            Changed = Info.Changed,
            Clicked = Info.Clicked,

            Type = "KeyPicker",
        }

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label" or ParentObj.Type == "Button" or ParentObj.Type == "SubButton", "KeyPicker with the mode 'Press' can be only applied on Labels and Buttons.")

            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
            Info.Mode = "Press"
        end

        if KeyPicker.SyncToggleState then
            Info.Modes = { "Toggle", "Hold" }

            if not table.find(Info.Modes, Info.Mode) then
                Info.Mode = "Toggle"
            end
        end

        local Picking = false
        local IsForButton = ParentObj.Type == "Button" or ParentObj.Type == "SubButton"

        -- Special Keys
        local SpecialKeys = {
            ["MB1"] = Enum.UserInputType.MouseButton1,
            ["MB2"] = Enum.UserInputType.MouseButton2,
            ["MB3"] = Enum.UserInputType.MouseButton3,
        }

        local SpecialKeysInput = {
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3",
        }

        -- Modifiers
        local Modifiers = {
            ["LAlt"] = Enum.KeyCode.LeftAlt,
            ["RAlt"] = Enum.KeyCode.RightAlt,

            ["LCtrl"] = Enum.KeyCode.LeftControl,
            ["RCtrl"] = Enum.KeyCode.RightControl,

            ["LShift"] = Enum.KeyCode.LeftShift,
            ["RShift"] = Enum.KeyCode.RightShift,

            ["Tab"] = Enum.KeyCode.Tab,
            ["CapsLock"] = Enum.KeyCode.CapsLock,
        }

        local ModifiersInput = {
            [Enum.KeyCode.LeftAlt] = "LAlt",
            [Enum.KeyCode.RightAlt] = "RAlt",

            [Enum.KeyCode.LeftControl] = "LCtrl",
            [Enum.KeyCode.RightControl] = "RCtrl",

            [Enum.KeyCode.LeftShift] = "LShift",
            [Enum.KeyCode.RightShift] = "RShift",

            [Enum.KeyCode.Tab] = "Tab",
            [Enum.KeyCode.CapsLock] = "CapsLock",
        }

        local IsModifierInput = function(Input)
            return Input.UserInputType == Enum.UserInputType.Keyboard and ModifiersInput[Input.KeyCode] ~= nil
        end

        local GetActiveModifiers = function()
            local ActiveModifiers = {}

            for Name, Input in Modifiers do
                if table.find(ActiveModifiers, Name) then
                    continue
                end
                if not UserInputService:IsKeyDown(Input) then
                    continue
                end

                table.insert(ActiveModifiers, Name)
            end

            return ActiveModifiers
        end

        local AreModifiersHeld = function(Required)
            if not (typeof(Required) == "table" and GetTableSize(Required) > 0) then
                return true
            end

            local ActiveModifiers = GetActiveModifiers()
            local Holding = true

            for _, Name in Required do
                if table.find(ActiveModifiers, Name) then
                    continue
                end

                Holding = false
                break
            end

            return Holding
        end

        local IsInputDown = function(Input)
            if not Input then
                return false
            end

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                return UserInputService:IsMouseButtonPressed(Input.UserInputType)
                    and not UserInputService:GetFocusedTextBox()
            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                return UserInputService:IsKeyDown(Input.KeyCode) and not UserInputService:GetFocusedTextBox()
            else
                return false
            end
        end

        local ConvertToInputModifiers = function(CurrentModifiers)
            local InputModifiers = {}

            for _, name in CurrentModifiers do
                table.insert(InputModifiers, Modifiers[name])
            end

            return InputModifiers
        end

        local VerifyModifiers = function(CurrentModifiers)
            if typeof(CurrentModifiers) ~= "table" then
                return {}
            end

            local ValidModifiers = {}

            for _, name in CurrentModifiers do
                if not Modifiers[name] then
                    continue
                end

                table.insert(ValidModifiers, name)
            end

            return ValidModifiers
        end

        KeyPicker.Modifiers = VerifyModifiers(KeyPicker.Modifiers)

        local SlideOverflow = true
        local LastDisplayText = nil
        local MaxPickerWidth = 85
        local SlidingLabel

        local SlideForwardTween
        local SlideBackTween
        local HandleForwardTween = function(State)
            if State ~= Enum.PlaybackState.Completed then
                return
            end

            task.wait(1.5)
            if SlideBackTween then
                SlideBackTween:Play()
            end
        end

        local HandleBackTween = function(State)
            if State ~= Enum.PlaybackState.Completed then
                return
            end

            task.wait(1.5)
            if SlideForwardTween then
                SlideForwardTween:Play()
            end
        end

        local CancelSlidingTweens = function()
            if SlideForwardTween then
                StopTween(SlideForwardTween, true)
                SlideForwardTween = nil
            end

            if SlideBackTween then
                StopTween(SlideBackTween, true)
                SlideBackTween = nil
            end

            RunService.RenderStepped:Wait()
        end

        local Picker = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromOffset(18, 18),
            Text = (IsForButton and SlideOverflow) and "" or KeyPicker.Value,
            TextSize = 14,
            TextTransparency = 0.4,
            Parent = ToggleLabel,
        })

        if IsForButton and SlideOverflow then
            Picker.ClipsDescendants = true

            SlidingLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                Text = KeyPicker.Value,
                TextSize = 14,
                FontFace = Picker.FontFace,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = Picker,
            })

            Library:AddToRegistry(SlidingLabel, {
                TextColor3 = "FontColor",
            })
        end

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Picker,
        })

        local PickerCorner = New("UICorner", {
            TopLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Picker,
        }); table.insert(Library.SpecificCorners, PickerCorner)

        Picker.MouseEnter:Connect(function()
            TweenService:Create(Picker, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
        end)

        Picker.MouseLeave:Connect(function()
            TweenService:Create(Picker, Library.TweenInfo, {
                TextTransparency = 0.4,
            }):Play()
        end)

        if IsForButton then
            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 21),
                Parent = ToggleLabel.Parent,
            })

            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 9),
                Parent = Holder,
            })

            New("UIFlexItem", {
                FlexMode = Enum.UIFlexMode.Fill,
                Parent = ToggleLabel,
            })

            ToggleLabel.Parent = Holder
            Picker.Parent = Holder

            Picker.Size = UDim2.new(0, 18, 1, 0)
        end

        local KeybindsToggle = { Normal = KeyPicker.Mode ~= "Toggle" }
        do
            local Holder = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                Text = "",
                Visible = not Info.NoUI,
                Parent = Library.KeybindContainer,
            })

            local Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(0, 1),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = Holder,
            })

            local Checkbox = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(14, 14),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = Holder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Checkbox,
                })
            )
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Checkbox,
            })

            local CheckImage = New("ImageLabel", {
                ImageColor3 = "FontColor",
                ImageTransparency = 1,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Checkbox,
            })
            if CheckIcon then
                Library:ApplyLucideIcon(CheckImage, CheckIcon)
            end

            function KeybindsToggle:Display(State)
                Label.TextTransparency = State and 0 or 0.5
                CheckImage.ImageTransparency = State and 0 or 1
            end

            function KeybindsToggle:SetText(Text)
                Label.Text = Text
            end

            function KeybindsToggle:SetVisibility(Visibility)
                Holder.Visible = Visibility
            end

            function KeybindsToggle:SetNormal(Normal)
                KeybindsToggle.Normal = Normal

                Holder.Active = not Normal
                Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22, 0)
                Checkbox.Visible = not Normal
            end

            KeyPicker.DoClick = function(...) end --// make luau lsp shut up
            Holder.MouseButton1Click:Connect(function()
                if KeybindsToggle.Normal then
                    return
                end

                KeyPicker.Toggled = not KeyPicker.Toggled
                KeyPicker:DoClick()
            end)

            KeybindsToggle.Holder = Holder
            KeybindsToggle.Label = Label
            KeybindsToggle.Checkbox = Checkbox
            KeybindsToggle.Loaded = true
            table.insert(Library.KeybindToggles, KeybindsToggle)
        end

        local ModeButtons = {}
        local ModeCorners = {}
        local TotalModeButtons = GetTableSize(Info.Modes)
        local MenuCornersOnly = if TotalModeButtons == 1 then "no_left" else "no_top_left"

        local MenuTable
        MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
            return { Picker.AbsoluteSize.X + 1.5, 0.5 }
        end, 1, function(Active: boolean)
            local Half = UDim.new(0, Library.CornerRadius / 2)
            local Zero = UDim.new(0, 0)

            PickerCorner.TopLeftRadius = Half
            PickerCorner.BottomLeftRadius = Half
            PickerCorner.TopRightRadius = Active and Zero or Half
            PickerCorner.BottomRightRadius = Active and Zero or Half

            local MenuCorner = MenuTable and MenuTable.Corner
            if MenuCorner then
                if MenuCornersOnly == "no_left" then
                    MenuCorner.TopLeftRadius = Zero
                    MenuCorner.BottomLeftRadius = Zero
                    MenuCorner.TopRightRadius = Half
                    MenuCorner.BottomRightRadius = Half
                else
                    MenuCorner.TopLeftRadius = Zero
                    MenuCorner.TopRightRadius = Half
                    MenuCorner.BottomRightRadius = Half
                    MenuCorner.BottomLeftRadius = Half
                end
            end

            for _, Entry in ModeCorners do
                local Corner = Entry.Corner
                if Entry.Style == "single" then
                    Corner.TopLeftRadius = Zero
                    Corner.BottomLeftRadius = Zero
                    Corner.TopRightRadius = Half
                    Corner.BottomRightRadius = Half
                elseif Entry.Style == "first" then
                    Corner.TopLeftRadius = Zero
                    Corner.TopRightRadius = Half
                    Corner.BottomLeftRadius = Zero
                    Corner.BottomRightRadius = Zero
                elseif Entry.Style == "last" then
                    Corner.TopLeftRadius = Zero
                    Corner.TopRightRadius = Zero
                    Corner.BottomLeftRadius = Half
                    Corner.BottomRightRadius = Half
                end
            end
        end, false, MenuCornersOnly, "KeyPicker")
        KeyPicker.Menu = MenuTable

        for Index, Mode in Info.Modes do
            local ModeButton = {}

            local Button = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, IsForButton and 21 or (TotalModeButtons == 1 and 18 or 19)),
                Text = Mode,
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = MenuTable.Menu,
            })

            if Index == 1 and TotalModeButtons == 1 then
                local Corner = New("UICorner", {
                    TopLeftRadius = UDim.new(0, 0),
                    TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
                    BottomLeftRadius = UDim.new(0, 0),
                    BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Button,
                })
                table.insert(Library.SpecificCorners, Corner)
                table.insert(ModeCorners, { Corner = Corner, Style = "single" })
            elseif Index == 1 then
                local Corner = New("UICorner", {
                    TopLeftRadius = UDim.new(0, 0),
                    TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
                    BottomLeftRadius = UDim.new(0, 0),
                    BottomRightRadius = UDim.new(0, 0),
                    Parent = Button,
                })
                table.insert(Library.SpecificCorners, Corner)
                table.insert(ModeCorners, { Corner = Corner, Style = "first" })
            elseif Index == TotalModeButtons then
                local Corner = New("UICorner", {
                    TopLeftRadius = UDim.new(0, 0),
                    TopRightRadius = UDim.new(0, 0),
                    BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
                    BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Button,
                })
                table.insert(Library.SpecificCorners, Corner)
                table.insert(ModeCorners, { Corner = Corner, Style = "last" })
            end

            function ModeButton:Select()
                for _, Button in ModeButtons do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Button.BackgroundTransparency = 0
                Button.TextTransparency = 0

                MenuTable:Close()
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Button.BackgroundTransparency = 1
                Button.TextTransparency = 0.5
            end

            Button.MouseButton1Click:Connect(function()
                ModeButton:Select()
            end)

            Button.MouseEnter:Connect(function()
                if KeyPicker.Mode == Mode then
                    return
                end

                TweenService:Create(Button, Library.TweenInfo, {
                    BackgroundTransparency = 0.7,
                    TextTransparency = 0.1,
                }):Play()
            end)

            Button.MouseLeave:Connect(function()
                if KeyPicker.Mode == Mode then
                    return
                end

                TweenService:Create(Button, Library.TweenInfo, {
                    BackgroundTransparency = 1,
                    TextTransparency = 0.5,
                }):Play()
            end)

            if KeyPicker.Mode == Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Display(PickerText)
            if Library.Unloaded then
                return
            end

            local DisplayText = PickerText or KeyPicker.DisplayValue
            if IsForButton and SlideOverflow then
                local X, _Y = Library:GetTextBounds(
                    DisplayText,
                    Picker.FontFace,
                    Picker.TextSize,
                    10000
                )

                local OffsetScale = X + 9
                local TextChanged = LastDisplayText ~= DisplayText
                local LabelWidth

                SlidingLabel.Text = DisplayText
                LastDisplayText = DisplayText

                if Picking then
                    Picker.Size = UDim2.new(1, 0, 1, 0)
                    RunService.RenderStepped:Wait()
                    LabelWidth = Picker.AbsoluteSize.X

                    if LabelWidth <= 0 then
                        LabelWidth = MaxPickerWidth
                    end
                else
                    LabelWidth = math.min(OffsetScale, MaxPickerWidth)
                    Picker.Size = UDim2.new(0, LabelWidth, 1, 0)
                end

                if OffsetScale > LabelWidth then
                    SlidingLabel.TextXAlignment = Enum.TextXAlignment.Left
                    SlidingLabel.Size = UDim2.new(0, OffsetScale, 1, 0)

                    local OverflowDistance = OffsetScale - LabelWidth - 4.5
                    if OverflowDistance > 0 then
                        if TextChanged or not SlideForwardTween then
                            SlidingLabel.Position = UDim2.fromOffset(4.5, 0)
                            CancelSlidingTweens()

                            local Duration = math.max(OverflowDistance / 25, 0.35)
                            local TweenInfo = TweenInfo.new(
                                Duration,
                                Enum.EasingStyle.Linear,
                                Enum.EasingDirection.InOut
                            )

                            SlideForwardTween = TweenService:Create(SlidingLabel, TweenInfo, {
                                Position = UDim2.fromOffset(-OverflowDistance, 0),
                            })

                            SlideBackTween = TweenService:Create(SlidingLabel, TweenInfo, {
                                Position = UDim2.fromOffset(4.5, 0),
                            })

                            SlideForwardTween:Play()

                            SlideForwardTween.Completed:Connect(HandleForwardTween)
                            SlideBackTween.Completed:Connect(HandleBackTween)
                        end
                    else
                        CancelSlidingTweens()

                        SlidingLabel.TextXAlignment = Enum.TextXAlignment.Center
                        SlidingLabel.Size = UDim2.new(1, 0, 1, 0)
                        SlidingLabel.Position = UDim2.new(0, 0, 0, 0)
                    end
                else
                    CancelSlidingTweens()

                    SlidingLabel.TextXAlignment = Enum.TextXAlignment.Center
                    SlidingLabel.Size = UDim2.new(1, 0, 1, 0)
                    SlidingLabel.Position = UDim2.new(0, 0, 0, 0)
                end
            else
                local X, Y = Library:GetTextBounds(
                    DisplayText,
                    Picker.FontFace,
                    Picker.TextSize,
                    ToggleLabel.AbsoluteSize.X
                )
                Picker.Text = DisplayText
                Picker.Size = IsForButton and UDim2.new(0, X + 9, 1, 0) or UDim2.fromOffset((X + 9), (Y + 4))
            end
        end

        function KeyPicker:Update()
            KeyPicker:Display()

            if Info.NoUI then
                return
            end

            if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                KeybindsToggle:SetVisibility(false)
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeyPicker.SyncToggleState and ParentObj.Value ~= State then
                ParentObj:SetValue(State)
            end

            if KeybindsToggle.Loaded then
                if ShowToggle then
                    KeybindsToggle:SetNormal(false)
                else
                    KeybindsToggle:SetNormal(true)
                end

                KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.DisplayValue, KeyPicker.Text, KeyPicker.Mode))
                KeybindsToggle:SetVisibility(true)
                KeybindsToggle:Display(State)
            end
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if not AreModifiersHeld(KeyPicker.Modifiers) then
                    return false
                end

                if Picking then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    if Library.Toggled then
                        return false
                    end

                    return UserInputService:IsMouseButtonPressed(SpecialKeys[Key])
                        and not UserInputService:GetFocusedTextBox()
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Key] :: any) and not UserInputService:GetFocusedTextBox()
                end
            else
                return KeyPicker.Toggled
            end
        end

        function KeyPicker:OnChanged(Func)
            KeyPicker.Changed = Func
        end

        function KeyPicker:OnClick(Func)
            KeyPicker.Clicked = Func
        end

        function KeyPicker:DoClick()
            if Picking then
                return
            end

            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)

            if IsForButton then
                Library:SafeCallback(ParentObj.Func, KeyPicker.Toggled)
            end

            if Library.ToggleKeybind == KeyPicker and Library.Toggle then
                Library:Toggle()
            end

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:RunChanged(IsKeyValid, KeyCode)
            if IsKeyValid == nil or KeyCode == nil then
                IsKeyValid, KeyCode = pcall(function()
                    if KeyPicker.Value == "None" then
                        return nil
                    end

                    if SpecialKeys[KeyPicker.Value] == nil then
                        return Enum.KeyCode[KeyPicker.Value]
                    end

                    return SpecialKeys[KeyPicker.Value]
                end)
            end

            local NewModifiers = ConvertToInputModifiers(KeyPicker.Modifiers)
            Library:SafeCallback(KeyPicker.ChangedCallback, KeyCode, NewModifiers)
            Library:SafeCallback(KeyPicker.Changed, KeyCode, NewModifiers)
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode, Modifiers = Data[1], Data[2], Data[3]

            local IsKeyValid, KeyCode = pcall(function()
                if Key == "None" then
                    Key = nil
                    return nil
                end

                if SpecialKeys[Key] == nil then
                    return Enum.KeyCode[Key]
                end

                return SpecialKeys[Key]
            end)

            if Key == nil then
                KeyPicker.Value = "None"
            elseif IsKeyValid then
                KeyPicker.Value = Key
            else
                KeyPicker.Value = "Unknown"
            end

            KeyPicker.Modifiers =
                VerifyModifiers(if typeof(Modifiers) == "table" then Modifiers else KeyPicker.Modifiers)
            KeyPicker.DisplayValue = if GetTableSize(KeyPicker.Modifiers) > 0
                then (table.concat(KeyPicker.Modifiers, " + ") .. " + " .. KeyPicker.Value)
                else KeyPicker.Value

            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select()
            end

            KeyPicker:Update()
            KeyPicker:RunChanged(IsKeyValid, KeyCode)
        end

        function KeyPicker:SetText(Text)
            KeybindsToggle:SetText(Text)
            KeyPicker:Update()
        end

        local SetPickingState = function(State)
            Picking = State
            Library.IsPicking = State

            if ParentObj then
                ParentObj.AnyKeyPickerPicking = Picking
            end

            if IsForButton then
                ToggleLabel.Visible = not Picking
                LastDisplayText = nil
                RunService.RenderStepped:Wait()
            end

            KeyPicker:Update()
        end

        Picker.MouseButton1Click:Connect(function()
            if Picking or Library.IsPicking then
                return
            end

            SetPickingState(true)

            if IsForButton and SlideOverflow then
                KeyPicker:Display("...")
            else
                Picker.Text = "..."
                Picker.Size = IsForButton and UDim2.new(0, 29, 1, 0) or UDim2.fromOffset(29, 18)
            end

            -- Wait for any input --
            local ActiveModifiers = {}
            local CurrentInput = nil

            local IsValidInput = function(InputObj)
                if InputObj.KeyCode == Enum.KeyCode.Escape then
                    return true
                end

                local IsMod = IsModifierInput(InputObj)
                local KeyName
                if SpecialKeysInput[InputObj.UserInputType] ~= nil then
                    KeyName = SpecialKeysInput[InputObj.UserInputType]
                elseif InputObj.UserInputType == Enum.UserInputType.Keyboard then
                    if IsMod then
                        KeyName = ModifiersInput[InputObj.KeyCode]
                    else
                        KeyName = InputObj.KeyCode.Name
                    end
                end

                if KeyName then
                    if IsMod then
                        if KeyPicker.WhitelistedModifiers and #KeyPicker.WhitelistedModifiers > 0 and not table.find(KeyPicker.WhitelistedModifiers, KeyName) then
                            return false
                        end

                        if KeyPicker.BlacklistedModifiers and table.find(KeyPicker.BlacklistedModifiers, KeyName) then
                            return false
                        end
                    else
                        if KeyPicker.Whitelisted and #KeyPicker.Whitelisted > 0 and not table.find(KeyPicker.Whitelisted, KeyName) then
                            return false
                        end

                        if KeyPicker.Blacklisted and table.find(KeyPicker.Blacklisted, KeyName) then
                            return false
                        end
                    end
                end

                return true
            end

            -- Wait for the first valid InputBegan --
            while true do
                local InputObj = UserInputService.InputBegan:Wait()
                if UserInputService:GetFocusedTextBox() ~= nil then
                    SetPickingState(false)
                    return
                end

                if IsValidInput(InputObj) then
                    CurrentInput = InputObj
                    break
                end
            end

            -- If it's a modifier key, we wait for either its release or another input --
            while IsModifierInput(CurrentInput) do
                if CurrentInput.KeyCode == Enum.KeyCode.Escape then
                    break
                end

                -- Display the current state including the current modifier key --
                local ModName = ModifiersInput[CurrentInput.KeyCode]
                if ModName then
                    local text = if #ActiveModifiers > 0 then table.concat(ActiveModifiers, " + ") .. " + " .. ModName .. " + ..." else ModName .. " + ..."
                    KeyPicker:Display(text)
                end

                local NextInput = nil
                local Released = false

                local BeganConn
                local EndedConn

                BeganConn = UserInputService.InputBegan:Connect(function(InputObj)
                    if UserInputService:GetFocusedTextBox() ~= nil then
                        return
                    end
                    if IsValidInput(InputObj) then
                        NextInput = InputObj
                    end
                end)

                EndedConn = UserInputService.InputEnded:Connect(function(InputObj)
                    if InputObj.KeyCode == CurrentInput.KeyCode then
                        Released = true
                    end
                end)

                repeat
                    task.wait()
                until Released or NextInput or UserInputService:GetFocusedTextBox() ~= nil or Library.Unloaded

                if BeganConn then BeganConn:Disconnect() end
                if EndedConn then EndedConn:Disconnect() end

                if UserInputService:GetFocusedTextBox() ~= nil or Library.Unloaded then
                    SetPickingState(false)
                    return
                end

                if Released then
                    break -- Use modifier key as bind
                elseif NextInput then
                    -- Add another modifier or continue to normal key
                    local OldModName = ModifiersInput[CurrentInput.KeyCode]
                    if OldModName and not table.find(ActiveModifiers, OldModName) then
                        ActiveModifiers[#ActiveModifiers + 1] = OldModName
                    end

                    CurrentInput = NextInput
                    if CurrentInput.KeyCode == Enum.KeyCode.Escape then
                        break
                    end
                end
            end

            local Key = "Unknown"
            if SpecialKeysInput[CurrentInput.UserInputType] ~= nil then
                Key = SpecialKeysInput[CurrentInput.UserInputType]
            elseif CurrentInput.UserInputType == Enum.UserInputType.Keyboard then
                Key = CurrentInput.KeyCode == Enum.KeyCode.Escape and "None" or CurrentInput.KeyCode.Name
            end

            ActiveModifiers = if CurrentInput.KeyCode == Enum.KeyCode.Escape or Key == "Unknown" then {} else ActiveModifiers

            KeyPicker.Toggled = if ParentObj.Type == "Toggle" then ParentObj.Value else false
            KeyPicker:SetValue({ Key, KeyPicker.Mode, ActiveModifiers })

            repeat
                task.wait()
            until not IsInputDown(CurrentInput) or UserInputService:GetFocusedTextBox()

            SetPickingState(false)
        end)
        Picker.MouseButton2Click:Connect(MenuTable.Toggle)

        table.insert(KeyPicker.Connections, UserInputService.InputBegan:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end

            local IsMouse = IsMouseClickInput(Input)
            if
                KeyPicker.Mode == "Always"
                or KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or Library.IsPicking
                or UserInputService:GetFocusedTextBox()
                or (IsMouse and Library.Toggled)
            then
                return
            end

            local Key = KeyPicker.Value
            local HoldingModifiers = AreModifiersHeld(KeyPicker.Modifiers)
            local HoldingKey = false

            if
                Key
                and HoldingModifiers == true
                and (
                    SpecialKeysInput[Input.UserInputType] == Key
                    or (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
                )
            then
                HoldingKey = true
            end

            if KeyPicker.Mode == "Toggle" then
                if HoldingKey then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                end
            elseif KeyPicker.Mode == "Press" then
                if HoldingKey then
                    KeyPicker:DoClick()
                end
            end

            KeyPicker:Update()
        end))

        table.insert(KeyPicker.Connections, UserInputService.InputEnded:Connect(function(Input: InputObject)
            if Library.Unloaded then
                return
            end

            local IsMouse = IsMouseClickInput(Input)
            if
                KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or Library.IsPicking
                or UserInputService:GetFocusedTextBox()
                or (IsMouse and Library.Toggled)
            then
                return
            end

            KeyPicker:Update()
        end))

        KeyPicker:Update()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        KeyPicker.Default = KeyPicker.Value
        KeyPicker.DefaultModifiers = table.clone(KeyPicker.Modifiers or {})

        function KeyPicker:Destroy()
            KeyPicker.Destroyed = true

            if KeyPicker.Connections then
                for _, Connection in KeyPicker.Connections do
                    Connection:Disconnect()
                end
            end

            if KeybindsToggle and KeybindsToggle.Loaded then
                if KeybindsToggle.Holder then
                    KeybindsToggle.Holder:Destroy()
                end
                local KTIdx = table.find(Library.KeybindToggles, KeybindsToggle)
                if KTIdx then
                    table.remove(Library.KeybindToggles, KTIdx)
                end
            end

            if MenuTable then
                MenuTable:Destroy()
            end

            if IsForButton and SlideOverflow then
                if SlideForwardTween then
                    SlideForwardTween:Destroy()
                end

                if SlideBackTween then
                    SlideBackTween:Destroy()
                end
            end

            if Picker then
                Picker:Destroy()
            end

            if ParentObj and ParentObj.Addons then
                local AddonIdx = table.find(ParentObj.Addons, KeyPicker)

                if AddonIdx then
                    table.remove(ParentObj.Addons, AddonIdx)
                end
            end

            Options[Idx] = nil
        end

        Options[Idx] = KeyPicker

        return self
    end

    local HueSequenceTable = {}
    for Hue = 0, 1, 0.1 do
        table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
    end
    function Funcs:AddColorPicker(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.ColorPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local ColorPicker = {
            Connections = {},
            Destroyed = false,

            Value = Info.Default,

            Transparency = Info.Transparency or 0,
            Title = Info.Title,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Type = "ColorPicker",
        }
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

        local Holder = New("TextButton", {
            BackgroundColor3 = ColorPicker.Value,
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            Parent = ToggleLabel,
        })

        local HolderStroke = New("UIStroke", {
            Color = Library:GetDarkerColor(ColorPicker.Value),
            Parent = Holder,
        })

        local ColorPickerCorner = New("UICorner", {
            TopLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Holder,
        }); table.insert(Library.SpecificCorners, ColorPickerCorner)

        local HolderTransparency = New("ImageLabel", {
            Image = CustomImageManager.GetAsset("TransparencyTexture"),
            ImageTransparency = (1 - ColorPicker.Transparency),
            ScaleType = Enum.ScaleType.Tile,
            Position = UDim2.new(0, -1, 0, -1),
            Size = UDim2.new(1, 2, 1, 2),
            TileSize = UDim2.fromOffset(9, 9),
            Parent = Holder,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = HolderTransparency,
            })
        )

        --// Color Menu \\--
        local ColorMenu
        local FooterCorner
        ColorMenu = Library:AddContextMenu(
            Holder,
            UDim2.fromOffset(Info.Transparency and 256 or 234, 0),
            function()
                return { 0.5, Holder.AbsoluteSize.Y + 1.5 }
            end,
            1, function(Active: boolean)
                local Half = UDim.new(0, Library.CornerRadius / 2)
                local Zero = UDim.new(0, 0)

                ColorPickerCorner.TopLeftRadius = Half
                ColorPickerCorner.TopRightRadius = Half
                ColorPickerCorner.BottomRightRadius = Active and Zero or Half
                ColorPickerCorner.BottomLeftRadius = Active and Zero or Half

                local MenuCorner = ColorMenu and ColorMenu.Corner
                if MenuCorner then
                    MenuCorner.TopLeftRadius = Zero
                    MenuCorner.TopRightRadius = Half
                    MenuCorner.BottomRightRadius = Half
                    MenuCorner.BottomLeftRadius = Half
                end

                if FooterCorner then
                    FooterCorner.TopLeftRadius = Zero
                    FooterCorner.TopRightRadius = Zero
                    FooterCorner.BottomLeftRadius = Half
                    FooterCorner.BottomRightRadius = Half
                end
            end, false, "no_top_left")
        ColorMenu.List.Padding = UDim.new(0, 0)
        ColorPicker.ColorMenu = ColorMenu

        --// Content Holder \\--
        local ContentHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            Parent = ContentHolder,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            Parent = ContentHolder,
        })

        --// Footer \\--
        local FooterHeight = Library.IsMobile and 30 or 22

        local FooterBackground = New("Frame", {
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
            end,
            Size = UDim2.new(1, 0, 0, FooterHeight),
            Parent = ColorMenu.Menu,
        })
        FooterCorner = New("UICorner", {
            TopLeftRadius = UDim.new(0, 0),
            TopRightRadius = UDim.new(0, 0),
            BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = FooterBackground,
        })
        table.insert(Library.SpecificCorners, FooterCorner)
        Library:MakeLine(FooterBackground, {
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.new(1, 0, 0, 1),
        })

        local FooterBar = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = FooterBackground,
        })
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, Info.Resizable and (FooterHeight + 4) or 6),
            Parent = FooterBar,
        })

        local FooterInfoLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            TextTransparency = 0.5,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = FooterBar,
        })

        local function RefreshFooterInfo()
            FooterInfoLabel.Text = string.format(
                "#%s • %d, %d, %d",
                ColorPicker.Value:ToHex(),
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255)
            )
        end
        RefreshFooterInfo()

        if typeof(ColorPicker.Title) == "string" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 8),
                Text = ColorPicker.Title,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ContentHolder,
            })
        end

        local ColorHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 200),
            Parent = ContentHolder,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            Parent = ColorHolder,
        })

        --// Sat Map
        local SatVipMap = New("ImageButton", {
            BackgroundColor3 = ColorPicker.Value,
            Image = CustomImageManager.GetAsset("SaturationMap"),
            Size = UDim2.fromOffset(200, 200),
            Parent = ColorHolder,
        })

        local SatVibCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            Size = UDim2.fromOffset(6, 6),
            Parent = SatVipMap,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "DarkColor",
            Parent = SatVibCursor,
        })

        --// Hue
        local HueSelector = New("TextButton", {
            Size = UDim2.fromOffset(16, 200),
            Text = "",
            Parent = ColorHolder,
        })
        New("UIGradient", {
            Color = ColorSequence.new(HueSequenceTable),
            Rotation = 90,
            Parent = HueSelector,
        })

        local HueCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "WhiteColor",
            BorderColor3 = "DarkColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            Size = UDim2.new(1, 2, 0, 1),
            Parent = HueSelector,
        })

        --// Alpha
        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            TransparencySelector = New("ImageButton", {
                Image = CustomImageManager.GetAsset("TransparencyTexture"),
                ScaleType = Enum.ScaleType.Tile,
                Size = UDim2.fromOffset(16, 200),
                TileSize = UDim2.fromOffset(8, 8),
                Parent = ColorHolder,
            })

            TransparencyColor = New("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                Size = UDim2.fromScale(1, 1),
                Parent = TransparencySelector,
            })
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = TransparencyColor,
            })

            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "WhiteColor",
                BorderColor3 = "DarkColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                Size = UDim2.new(1, 2, 0, 1),
                Parent = TransparencySelector,
            })
        end

        --// Resizing \\--
        local ResizeGrabber
        if Info.Resizable then
            local BaseMapSize = 200
            local BaseBarWidth = 16
            local BasePadding = 6
            local MinMapSize = 140

            ColorPicker.MapWidth = BaseMapSize
            ColorPicker.MapHeight = BaseMapSize

            local function GetBarWidth(MapWidth)
                return math.clamp(math.floor((MapWidth / BaseMapSize) * BaseBarWidth + 0.5), 12, 24)
            end

            local function GetContentWidth(MapWidth)
                local BarWidth = GetBarWidth(MapWidth)
                local Width = MapWidth + BarWidth + BasePadding
                if Info.Transparency then
                    Width += (BarWidth + BasePadding)
                end

                return Width + 12
            end

            local FixedVerticalOverhead = 6 + 6 + 8 + 20 + 8 + 20 + FooterHeight
            if typeof(ColorPicker.Title) == "string" then
                FixedVerticalOverhead += 8 + 8
            end

            local function ClampToViewport(NewWidth, NewHeight)
                local Camera = workspace.CurrentCamera
                if not Camera then
                    return NewWidth, NewHeight
                end

                local ViewportSize = Camera.ViewportSize
                local ScreenMargin = 12

                local MaxWidth = ViewportSize.X - ColorMenu.Menu.AbsolutePosition.X - ScreenMargin
                local MaxHeight = ViewportSize.Y - ColorMenu.Menu.AbsolutePosition.Y - ScreenMargin - FixedVerticalOverhead

                while NewWidth > MinMapSize and GetContentWidth(NewWidth) > MaxWidth do
                    NewWidth -= 4
                end

                if NewHeight > MaxHeight then
                    NewHeight = math.max(MinMapSize, math.floor(MaxHeight))
                end

                return NewWidth, NewHeight
            end

            local function UpdateColorMenuSize(NewWidth, NewHeight)
                NewWidth = math.max(MinMapSize, math.floor(NewWidth + 0.5))
                NewHeight = math.max(MinMapSize, math.floor(NewHeight + 0.5))
                NewWidth, NewHeight = ClampToViewport(NewWidth, NewHeight)

                if NewWidth == ColorPicker.MapWidth and NewHeight == ColorPicker.MapHeight then
                    return
                end

                local BarWidth = GetBarWidth(NewWidth)
                local CursorSize = math.clamp(math.floor((math.min(NewWidth, NewHeight) / BaseMapSize) * 6 + 0.5), 4, 10)

                ColorHolder.Size = UDim2.new(1, 0, 0, NewHeight)
                SatVipMap.Size = UDim2.fromOffset(NewWidth, NewHeight)
                SatVibCursor.Size = UDim2.fromOffset(CursorSize, CursorSize)
                HueSelector.Size = UDim2.new(0, BarWidth, 0, NewHeight)

                if TransparencySelector then
                    TransparencySelector.Size = UDim2.new(0, BarWidth, 0, NewHeight)
                end

                ColorPicker.MapWidth = NewWidth
                ColorPicker.MapHeight = NewHeight
                ColorMenu:SetSize(UDim2.new(0, GetContentWidth(NewWidth), 0, 0))
            end

            ResizeGrabber = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -Library.CornerRadius / 4, 0, 0),
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Text = "",
                Parent = FooterBackground,
            })
            local ResizeGrabberIcon = New("ImageLabel", {
                ImageColor3 = "FontColor",
                ImageTransparency = 0.5,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = ResizeGrabber,
            })
            if ResizeIcon then
                Library:ApplyLucideIcon(ResizeGrabberIcon, ResizeIcon)
            end

            table.insert(ColorPicker.Connections, ResizeGrabber.InputBegan:Connect(function(Input: InputObject)
                Library.CantDragForced = true
                local StartMouse = Vector2.new(Mouse.X, Mouse.Y)
                local StartWidth = ColorPicker.MapWidth
                local StartHeight = ColorPicker.MapHeight

                while IsDragInput(Input) and not ColorPicker.Destroyed do
                    local Delta = Vector2.new(Mouse.X, Mouse.Y) - StartMouse
                    UpdateColorMenuSize(StartWidth + Delta.X, StartHeight + Delta.Y)

                    RunService.RenderStepped:Wait()
                end

                Library.CantDragForced = false
            end))
        end

        local InfoHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = ContentHolder,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = InfoHolder,
        })

        local HueBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
            TextSize = 14,
            Parent = InfoHolder,
        })

        local HueBoxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = HueBox,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = HueBox,
            })
        )

        local RgbBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
            TextSize = 14,
            Parent = InfoHolder,
        })

        local RgbBoxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = RgbBox,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = RgbBox,
            })
        )

        --// Context Menu \\--
        local ContextMenu
        ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
            return { Holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1, function(Active: boolean)
            local Half = UDim.new(0, Library.CornerRadius / 2)
            local Zero = UDim.new(0, 0)

            ColorPickerCorner.TopLeftRadius = Half
            ColorPickerCorner.BottomLeftRadius = Half
            ColorPickerCorner.TopRightRadius = Active and Zero or Half
            ColorPickerCorner.BottomRightRadius = Active and Zero or Half

            local MenuCorner = ContextMenu and ContextMenu.Corner
            if MenuCorner then
                MenuCorner.TopLeftRadius = Zero
                MenuCorner.TopRightRadius = Half
                MenuCorner.BottomRightRadius = Half
                MenuCorner.BottomLeftRadius = Half
            end
        end, false, "no_top_left")
        ColorPicker.ContextMenu = ContextMenu
        ContextMenu.List.Padding = UDim.new(0, 6)
        do
            local function CreateButton(Text, Func)
                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Text,
                    TextSize = 14,
                    Parent = ContextMenu.Menu,
                })

                Button.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Func)
                    ContextMenu:Close()
                end)

                Button.MouseEnter:Connect(function()
                    TweenService:Create(Button, Library.TweenInfo, {
                        BackgroundTransparency = 0.7,
                    }):Play()
                end)

                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, Library.TweenInfo, {
                        BackgroundTransparency = 1,
                    }):Play()
                end)
            end

            CreateButton("Copy color", function()
                Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
            end)

            ColorPicker.SetValueRGB = function(...) end --// make luau lsp shut up
            CreateButton("Paste color", function()
                if not Library.CopiedColor then
                    return
                end

                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
            end)

            if setclipboard then
                CreateButton("Copy Hex", function()
                    setclipboard(tostring(ColorPicker.Value:ToHex()))
                end)

                CreateButton("Copy RGB", function()
                    setclipboard(table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", "))
                end)
            end
        end

        --// Copy/Paste Buttons \\--
        local ActionHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = ContentHolder,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = ActionHolder,
        })

        local CopyColorButton = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            Text = "Copy color",
            TextSize = 14,
            Parent = ActionHolder,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = CopyColorButton,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = CopyColorButton,
            })
        )

        local PasteColorButton = New("TextButton", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            Text = "Paste color",
            TextSize = 14,
            Parent = ActionHolder,
        })
        New("UIStroke", {
            Color = "OutlineColor",
            Parent = PasteColorButton,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = PasteColorButton,
            })
        )

        local CopyColorOriginalText = CopyColorButton.Text
        local PasteColorOriginalText = PasteColorButton.Text
        local CopyColorResetId = 0
        local PasteColorResetId = 0

        table.insert(ColorPicker.Connections, CopyColorButton.MouseEnter:Connect(function()
            TweenService:Create(CopyColorButton, Library.TweenInfo, {
                BackgroundColor3 = Library:GetBetterColor(Library.Scheme.MainColor, 10),
            }):Play()
        end))

        table.insert(ColorPicker.Connections, CopyColorButton.MouseLeave:Connect(function()
            TweenService:Create(CopyColorButton, Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.MainColor,
            }):Play()
        end))

        table.insert(ColorPicker.Connections, PasteColorButton.MouseEnter:Connect(function()
            TweenService:Create(PasteColorButton, Library.TweenInfo, {
                BackgroundColor3 = Library:GetBetterColor(Library.Scheme.MainColor, 10),
            }):Play()
        end))

        table.insert(ColorPicker.Connections, PasteColorButton.MouseLeave:Connect(function()
            TweenService:Create(PasteColorButton, Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.MainColor,
            }):Play()
        end))

        table.insert(ColorPicker.Connections, CopyColorButton.MouseButton1Click:Connect(function()
            Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }

            CopyColorResetId += 1
            local ThisResetId = CopyColorResetId
            CopyColorButton.Text = "Copied color"

            task.delay(1, function()
                if ColorPicker.Destroyed or ThisResetId ~= CopyColorResetId then
                    return
                end

                CopyColorButton.Text = CopyColorOriginalText
            end)
        end))

        table.insert(ColorPicker.Connections, PasteColorButton.MouseButton1Click:Connect(function()
            PasteColorResetId += 1
            local ThisResetId = PasteColorResetId

            if not Library.CopiedColor then
                PasteColorButton.Text = "Nothing to paste"
            else
                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
                PasteColorButton.Text = "Pasted color"
            end

            task.delay(1, function()
                if ColorPicker.Destroyed or ThisResetId ~= PasteColorResetId then
                    return
                end

                PasteColorButton.Text = PasteColorOriginalText
            end)
        end))

        --// End \\--
        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
        end

        function ColorPicker:Display()
            if Library.Unloaded then
                return
            end

            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

            Holder.BackgroundColor3 = ColorPicker.Value
            HolderStroke.Color = Library:GetDarkerColor(ColorPicker.Value)
            HolderTransparency.ImageTransparency = (1 - ColorPicker.Transparency)

            SatVipMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            if TransparencyColor then
                TransparencyColor.BackgroundColor3 = ColorPicker.Value
            end

            SatVibCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
            HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)
            if TransparencyCursor then
                TransparencyCursor.Position = UDim2.fromScale(0.5, ColorPicker.Transparency)
            end

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255),
            }, ", ")

            RefreshFooterInfo()
        end

        function ColorPicker:RunChanged()
            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:Update()
            ColorPicker:Display()
            ColorPicker:RunChanged()
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        function ColorPicker:SetValue(HSV, Transparency)
            if typeof(HSV) == "Color3" then
                ColorPicker:SetValueRGB(HSV, Transparency)
                return
            end

            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        table.insert(ColorPicker.Connections, Holder.MouseButton1Click:Connect(ColorMenu.Toggle))
        table.insert(ColorPicker.Connections, Holder.MouseButton2Click:Connect(ContextMenu.Toggle))

        table.insert(ColorPicker.Connections, SatVipMap.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) and not ColorPicker.Destroyed do
                local MinX = SatVipMap.AbsolutePosition.X
                local MaxX = MinX + SatVipMap.AbsoluteSize.X
                local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                local MinY = SatVipMap.AbsolutePosition.Y
                local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                local OldSat = ColorPicker.Sat
                local OldVib = ColorPicker.Vib
                ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end))

        table.insert(ColorPicker.Connections, HueSelector.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) and not ColorPicker.Destroyed do
                local Min = HueSelector.AbsolutePosition.Y
                local Max = Min + HueSelector.AbsoluteSize.Y
                local Location = math.clamp(Mouse.Y, Min, Max)

                local OldHue = ColorPicker.Hue
                ColorPicker.Hue = (Location - Min) / (Max - Min)

                if ColorPicker.Hue ~= OldHue then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end))

        if TransparencySelector then
            table.insert(ColorPicker.Connections, TransparencySelector.InputBegan:Connect(function(Input: InputObject)
                while IsDragInput(Input) and not ColorPicker.Destroyed do
                    local Min = TransparencySelector.AbsolutePosition.Y
                    local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                    local Location = math.clamp(Mouse.Y, Min, Max)

                    local OldTransparency = ColorPicker.Transparency
                    ColorPicker.Transparency = (Location - Min) / (Max - Min)

                    if ColorPicker.Transparency ~= OldTransparency then
                        ColorPicker:Update()
                    end

                    RunService.RenderStepped:Wait()
                end
            end))
        end

        table.insert(ColorPicker.Connections, HueBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local Success, Color = pcall(Color3.fromHex, HueBox.Text)
            if Success and typeof(Color) == "Color3" then
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
            end

            ColorPicker:Update()
        end))

        table.insert(ColorPicker.Connections, RgbBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
            if R and G and B then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
            end

            ColorPicker:Update()
        end))

        for _, BoxPair in {
            { HueBox, HueBoxStroke },
            { RgbBox, RgbBoxStroke }
        } do
            local TextBoxInstance, Stroke = BoxPair[1], BoxPair[2]

            table.insert(ColorPicker.Connections, TextBoxInstance.Focused:Connect(function()
                Library.Registry[Stroke].Color = "AccentColor"
                TweenService:Create(Stroke, Library.TweenInfo, {
                    Color = Library.Scheme.AccentColor,
                }):Play()
            end))

            table.insert(ColorPicker.Connections, TextBoxInstance.FocusLost:Connect(function()
                Library.Registry[Stroke].Color = "OutlineColor"
                TweenService:Create(Stroke, Library.TweenInfo, {
                    Color = Library.Scheme.OutlineColor,
                }):Play()
            end))
        end

        ColorPicker:Display()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        ColorPicker.Default = ColorPicker.Value

        function ColorPicker:Destroy()
            ColorPicker.Destroyed = true

            if ColorPicker.Connections then
                for _, Connection in ColorPicker.Connections do
                    Connection:Disconnect()
                end
            end

            if ColorMenu then
                ColorMenu:Destroy()
            end

            if ResizeGrabber then
                ResizeGrabber:Destroy()
            end

            if ContextMenu then
                ContextMenu:Destroy()
            end

            if Holder then
                Holder:Destroy()
            end

            if ParentObj and ParentObj.Addons then
                local AddonIdx = table.find(ParentObj.Addons, ColorPicker)

                if AddonIdx then
                    table.remove(ParentObj.Addons, AddonIdx)
                end
            end

            Options[Idx] = nil
        end

        Options[Idx] = ColorPicker

        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

--// Player card: an avatar thumbnail paired with a title and description lines.
--// The full card spans a tab, above its columns; the compact card is an avatar
--// box for a groupbox, with no title or description of its own.
--// The full card spans a tab, above its columns; the compact card is a groupbox
--// element - a header row whose avatar collapses away when the header is clicked.
local PLAYER_THUMBNAIL_TYPES = {
    headshot = "AvatarHeadShot",
    head = "AvatarHeadShot",
    bust = "AvatarBust",
    avatar = "AvatarThumbnail",
    body = "AvatarThumbnail",
    full = "AvatarThumbnail",
}

local PLAYER_CARD_LINE_HEIGHT = 15
local PLAYER_CARD_LINE_PADDING = 2
local PLAYER_CARD_DIVIDER_HEIGHT = 7

--// A description entry is a divider when it is a run of dashes ("---") or a
--// table saying so ({ Divider = true }); anything else is a line of text
local function IsDescriptionDivider(Entry: any): boolean
    if typeof(Entry) == "table" then
        return Entry.Divider == true or Entry.Type == "Divider"
    end

    return typeof(Entry) == "string" and string.match(Entry, "^%s*%-%-%-+%s*$") ~= nil
end

local function GetDescriptionText(Entry: any): string
    if typeof(Entry) == "table" then
        return tostring(Entry.Text or "")
    end

    return tostring(Entry)
end

local function StripRichText(Text: string): string
    return (string.gsub(Text or "", "<[^<>]->", ""))
end

local function ResolvePlayerUserId(Player: any, UserId: number?): number
    if typeof(UserId) == "number" and UserId > 0 then
        return UserId
    end

    if typeof(Player) == "Instance" and Player:IsA("Player") then
        return Player.UserId
    end

    if typeof(Player) == "string" then
        local Found = Players:FindFirstChild(Player)
        if Found and Found:IsA("Player") then
            return Found.UserId
        end
    end

    return LocalPlayer.UserId
end

local function ResolvePlayerName(Player: any, UserId: number): string
    if typeof(Player) == "Instance" and Player:IsA("Player") then
        return Player.DisplayName
    end

    local Found = Players:GetPlayerByUserId(UserId)
    if Found then
        return Found.DisplayName
    end

    if typeof(Player) == "string" then
        return Player
    end

    return tostring(UserId)
end

local function GetPlayerThumbnail(UserId: number, ThumbnailType: string?, Compact: boolean): string
    --// Compact shows more of the character; full-body thumbnails do not load on
    --// every client, so the reliable bust is the default there
    local Type = PLAYER_THUMBNAIL_TYPES[string.lower(ThumbnailType or "")]
        or (Compact and "AvatarBust" or "AvatarHeadShot")
    local Size = Type == "AvatarThumbnail" and 420 or 150

    return string.format("rbxthumb://type=%s&id=%s&w=%d&h=%d", Type, tostring(UserId), Size, Size)
end

--// Builds the card itself. Inset shifts and narrows the holder (the tab banner
--// lines up with the warning box); OnResize runs whenever the height changes.
local function CreatePlayerCard(Info, Parent: Instance, IsCompact: boolean, Inset: { X: number, Width: number }, OnResize: () -> ())
    local PlayerInfo = {
        Connections = {},
        Destroyed = false,

        Style = IsCompact and "Compact" or "Full",
        Player = Info.Player,
        UserId = Info.UserId,
        Title = Info.Title,
        Description = Info.Description,
        Thumbnail = Info.Thumbnail,
        ThumbnailType = Info.ThumbnailType,
        Height = Info.Height or (IsCompact and 190 or 84),

        Visible = Info.Visible,
        Type = "PlayerInfo",
    }

    local ResolvedUserId = ResolvePlayerUserId(PlayerInfo.Player, PlayerInfo.UserId)
    local ResolvedName = ResolvePlayerName(PlayerInfo.Player, ResolvedUserId)

    --// Resolve the description up front: it drives the full banner's height
    local function GetDescriptionLines(): { string }
        local Description = PlayerInfo.Description

        if typeof(Description) == "table" then
            return Description
        elseif typeof(Description) == "string" and Description ~= "" then
            return { Description }
        end

        return {}
    end

    function PlayerInfo:GetTotalHeight(): number
        if IsCompact then
            return PlayerInfo.Height
        end

        --// The full banner grows to fit its description so lines never leak
        --// past the card. 42 = 20 box padding + a 22px title strip above the
        --// description rows; PlayerInfo.Height acts as the minimum.
        local DescriptionHeight = 0
        for Index, Entry in GetDescriptionLines() do
            DescriptionHeight += IsDescriptionDivider(Entry) and PLAYER_CARD_DIVIDER_HEIGHT or PLAYER_CARD_LINE_HEIGHT
            if Index > 1 then
                DescriptionHeight += PLAYER_CARD_LINE_PADDING
            end
        end

        return math.max(PlayerInfo.Height, 42 + DescriptionHeight)
    end

    local Holder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(Inset.X, 0),
        Size = UDim2.new(1, Inset.Width, 0, PlayerInfo:GetTotalHeight()),
        Visible = PlayerInfo.Visible,
        Parent = Parent,
    })

    local function RefreshHeight()
        Holder.Size = UDim2.new(1, Inset.Width, 0, PlayerInfo:GetTotalHeight())
        OnResize()
    end

    --// Fall back to the player's own name so an empty Info still reads well
    local function GetTitleText(): string
        if PlayerInfo.Title ~= "" then
            return PlayerInfo.Title
        end

        return string.format("Hello, %s", ResolvedName)
    end

    local AvatarImage
    local TitleLabel
    local DescriptionHolder
    local DescriptionElements = {}
    local Body

    local function UpdateThumbnail()
        if not AvatarImage then
            return
        end

        if PlayerInfo.Thumbnail and PlayerInfo.Thumbnail ~= "" then
            local Icon = Library:GetCustomIcon(PlayerInfo.Thumbnail)

            if Icon then
                AvatarImage.Image = Icon.Url
                AvatarImage.ImageRectOffset = Icon.ImageRectOffset
                AvatarImage.ImageRectSize = Icon.ImageRectSize
                return
            end
        end

        AvatarImage.Image = GetPlayerThumbnail(ResolvedUserId, PlayerInfo.ThumbnailType, IsCompact)
        AvatarImage.ImageRectOffset = Vector2.zero
        AvatarImage.ImageRectSize = Vector2.zero
    end

    local function UpdateText()
        local TitleText = GetTitleText()

        if TitleLabel then
            TitleLabel.Text = TitleText
        end

        PlayerInfo.Text = StripRichText(TitleText)

        if not DescriptionHolder then
            return
        end


        local Lines = GetDescriptionLines()

        --// Entries can change type between refreshes, so the rows are rebuilt
        --// rather than pooled
        for Index = #DescriptionElements, 1, -1 do
            table.remove(DescriptionElements, Index):Destroy()
        end

        for Index, Entry in Lines do
            if IsDescriptionDivider(Entry) then
                local DividerHolder = New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = Index,
                    Size = UDim2.new(1, 0, 0, PLAYER_CARD_DIVIDER_HEIGHT),
                    Parent = DescriptionHolder,
                })

                New("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = "OutlineColor",
                    Position = UDim2.fromScale(0, 0.5),
                    Size = UDim2.new(1, 0, 0, 1),
                    Parent = DividerHolder,
                })

                table.insert(DescriptionElements, DividerHolder)
            else
                local Text = GetDescriptionText(Entry)

                local Label = New("TextLabel", {
                    BackgroundTransparency = 1,
                    LayoutOrder = Index,
                    Size = UDim2.new(1, 0, 0, PLAYER_CARD_LINE_HEIGHT),
                    Text = Text,
                    TextSize = 13,
                    TextTransparency = 0.25,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = DescriptionHolder,
                })

                table.insert(DescriptionElements, Label)
                PlayerInfo.Text = PlayerInfo.Text .. " " .. StripRichText(Text)
            end
        end

        --// Line count may have changed, so re-fit the card to its content
        RefreshHeight()
    end

    if IsCompact then
        --// No header of its own: the groupbox it sits in provides the title and
        --// the collapse, so the card is just the avatar box
        Body = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.new(1, 0, 0, PlayerInfo.Height),
            Parent = Holder,
        })
        table.insert(Library.Corners, New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Body,
        }))
        Library:AddOutline(Body)

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            Parent = Body,
        })

        AvatarImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.fromScale(1, 1),
            Parent = Body,
        })
    else
        local Box = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })
        table.insert(Library.Corners, New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Box,
        }))
        Library:AddOutline(Box)

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 10),
            Parent = Box,
        })

        --// Square avatar tile on the left, sized off the card height
        local AvatarSize = PlayerInfo.Height - 20

        local AvatarHolder = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            --// Fixed square, top-aligned, so a taller (multi-line) card does not
            --// stretch the avatar into a rectangle
            Size = UDim2.fromOffset(AvatarSize, AvatarSize),
            Parent = Box,
        })
        table.insert(Library.Corners, New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = AvatarHolder,
        }))
        Library:AddOutline(AvatarHolder)

        AvatarImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.fromScale(1, 1),
            Parent = AvatarHolder,
        })

        local TextHolder = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(AvatarSize + 12, 0),
            Size = UDim2.new(1, -(AvatarSize + 12), 1, 0),
            Parent = Box,
        })

        TitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            TextSize = 15,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TextHolder,
        })

        DescriptionHolder = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 22),
            Size = UDim2.new(1, 0, 1, -22),
            Parent = TextHolder,
        })

        New("UIListLayout", {
            Padding = UDim.new(0, PLAYER_CARD_LINE_PADDING),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DescriptionHolder,
        })
    end

    UpdateThumbnail()
    UpdateText()

    function PlayerInfo:SetTitle(Title: string)
        PlayerInfo.Title = Title or ""
        UpdateText()
    end

    function PlayerInfo:SetDescription(Description: string | { string })
        PlayerInfo.Description = Description or ""
        UpdateText()
    end

    function PlayerInfo:SetPlayer(Player: Player | string)
        PlayerInfo.Player = Player
        PlayerInfo.UserId = nil

        ResolvedUserId = ResolvePlayerUserId(Player, nil)
        ResolvedName = ResolvePlayerName(Player, ResolvedUserId)

        UpdateThumbnail()
        UpdateText()
    end

    function PlayerInfo:SetUserId(UserId: number)
        PlayerInfo.UserId = UserId
        PlayerInfo.Player = nil

        ResolvedUserId = ResolvePlayerUserId(nil, UserId)
        ResolvedName = ResolvePlayerName(nil, ResolvedUserId)

        UpdateThumbnail()
        UpdateText()
    end

    function PlayerInfo:SetThumbnail(Thumbnail: string?)
        PlayerInfo.Thumbnail = Thumbnail
        UpdateThumbnail()
    end

    function PlayerInfo:SetHeight(Height: number)
        assert(Height > 0, "Height must be greater than 0.")

        PlayerInfo.Height = Height

        if Body then
            Body.Size = UDim2.new(1, 0, 0, Height)
        end

        RefreshHeight()
    end

    function PlayerInfo:SetVisible(Visible: boolean)
        PlayerInfo.Visible = Visible

        Holder.Visible = Visible
        OnResize()
    end

    PlayerInfo.Holder = Holder
    return PlayerInfo
end

local PLAYER_CARD_NO_INSET = { X = 0, Width = 0 }
local PLAYER_CARD_BANNER_INSET = { X = 2, Width = -5 }

local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddDivider(...)
        if self.Destroyed then return nil end

        local Params = select(1, ...)
        local Text
        local MarginTop = 0
        local MarginBottom = 0

        if typeof(Params) == "table" then
            Text = Params.Text
            MarginTop = Params.MarginTop or Params.Margin or 0
            MarginBottom = Params.MarginBottom or Params.Margin or 0
        elseif typeof(Params) == "string" then
            Text = Params
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 6 + MarginTop + MarginBottom),
            Parent = Container,
        })

        local InnerHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingTop = UDim.new(0, MarginTop),
            PaddingBottom = UDim.new(0, MarginBottom),
            Parent = Holder,
        })

        if Text then
            local TextLabel = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Text = Text,
                TextSize = 14,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = InnerHolder,
            })

            local X, _ = Library:GetTextBounds(Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            local SizeX = X // 2 + 10

            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(0.5, -SizeX, 0, 2),
                Parent = InnerHolder,
            })
            New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.new(0.5, -SizeX, 0, 2),
                Parent = InnerHolder,
            })
        else
            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(1, 0, 0, 2),
                Parent = InnerHolder,
            })
        end

        Groupbox:Resize()

        local Divider = {
            Connections = {},
            Destroyed = false,

            Holder = Holder,
            Text = Text,
            MarginTop = MarginTop,
            MarginBottom = MarginBottom,
            Type = "Divider",
        }

        function Divider:SetVisible(Value)
            Holder.Visible = Value == true
            Groupbox:Resize()
        end

        function Divider:Destroy()
            Divider.Destroyed = true

            if Divider.Connections then
                for _, Connection in Divider.Connections do
                    Connection:Disconnect()
                end
            end

            if Holder then
                Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Divider)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
        end

        table.insert(Groupbox.Elements, Divider)
        return Divider
    end

    function Funcs:AddLabel(...)
        if self.Destroyed then return nil end

        local Data = {}
        local Addons = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Size = Params.Size or 14
            Data.Visible = Params.Visible or true
            Data.Idx = typeof(Second) == "table" and First or nil
        else
            Data.Text = First or ""
            Data.DoesWrap = Second or false
            Data.Size = 14
            Data.Visible = true
            Data.Idx = select(3, ...) or nil
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Label = {
            Connections = {},
            Destroyed = false,

            Text = Data.Text,
            DoesWrap = Data.DoesWrap,

            Addons = Addons,

            Visible = Data.Visible,
            Type = "Label",
        }

        local TextLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = Label.Text,
            TextSize = Data.Size,
            TextWrapped = Label.DoesWrap,
            TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = Container,
        })

        function Label:Display()
            if not Label.DoesWrap then
                return
            end

            local Width = TextLabel.AbsoluteSize.X
            if Width <= 0 then return end

            local _, Y = Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, Width)
            TextLabel.Size = UDim2.new(1, 0, 0, Y + 4)
        end

        function Label:SetVisible(Visible: boolean)
            Label.Visible = Visible

            TextLabel.Visible = Label.Visible
            Groupbox:Resize()
        end

        function Label:SetText(Text: string)
            Label.Text = Text
            TextLabel.Text = Text

            Label:Display()
            Groupbox:Resize()
        end

        if Label.DoesWrap then
            Label:Display()

            local Last = TextLabel.AbsoluteSize
            TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if TextLabel.AbsoluteSize == Last then
                    return
                end

                Label:Display()
                Last = TextLabel.AbsoluteSize

                Groupbox:Resize()
            end)
        else
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = TextLabel,
            })
        end

        Groupbox:Resize()

        Label.TextLabel = TextLabel
        Label.Container = Container
        if not Data.DoesWrap then
            setmetatable(Label, BaseAddons)
        end

        Label.Holder = TextLabel
        table.insert(Groupbox.Elements, Label)

        if Data.Idx then
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        function Label:Destroy()
            Label.Destroyed = true

            if Label.Connections then
                for _, Connection in Label.Connections do
                    Connection:Disconnect()
                end
            end

            if Label.Addons then
                for Index = #Label.Addons, 1, -1 do
                    local Addon = table.remove(Label.Addons, Index)
                    if Addon and Addon.Destroy then
                        Addon:Destroy()
                    end
                end
            end

            if TextLabel then
                TextLabel:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Label)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()

            if Data.Idx then
                Labels[Data.Idx] = nil
            else
                local LblIdx = table.find(Labels, Label)

                if LblIdx then
                    table.remove(Labels, LblIdx)
                end
            end
        end

        return Label
    end

    function Funcs:AddButton(...)
        if self.Destroyed then return nil end

        local function GetInfo(...)
            local Info = {}

            local First = select(1, ...)
            local Second = select(2, ...)

            if typeof(First) == "table" or typeof(Second) == "table" then
                local Params = typeof(First) == "table" and First or Second

                Info.Text = Params.Text or ""
                Info.Func = Params.Func or Params.Callback or function() end
                Info.DoubleClick = Params.DoubleClick

                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip

                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = Params.Visible or true
                Info.Idx = typeof(Second) == "table" and First or nil
            else
                Info.Text = First or ""
                Info.Func = Second or function() end
                Info.DoubleClick = false

                Info.Tooltip = nil
                Info.DisabledTooltip = nil

                Info.Risky = false
                Info.Disabled = false
                Info.Visible = true
                Info.Idx = select(3, ...) or nil
            end

            return Info
        end
        local Info = GetInfo(...)

        local Groupbox = self
        local Container = Groupbox.Container

        local Button = {
            Connections = {},
            Destroyed = false,

            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Tween = nil,
            Type = "Button",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 21),
            Parent = Container,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 9),
            Parent = Holder,
        })

        local function CreateButton(Button)
            local Base = New("TextButton", {
                Active = not Button.Disabled,
                BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor",
                Size = UDim2.fromScale(1, 1),
                Text = Button.Text,
                TextSize = 14,
                TextTransparency = 0.4,
                Visible = Button.Visible,
                Parent = Holder,
            })

            local Stroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = Button.Disabled and 0.5 or 0,
                Parent = Base,
            })

            --// Pill shaped, matching the sliders and switches
            table.insert(
                Library.PillCorners,
                New("UICorner", {
                    CornerRadius = Library.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0),
                    Parent = Base,
                })
            )

            return Base, Stroke
        end

        local function InitEvents(Button)
            Button.Base.MouseEnter:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    TextTransparency = 0,
                })
                Button.Tween:Play()
            end)
            Button.Base.MouseLeave:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    TextTransparency = 0.4,
                })
                Button.Tween:Play()
            end)

            Button.Base.MouseButton1Click:Connect(function()
                if Button.Disabled or Button.Locked then
                    return
                end

                if Button.DoubleClick then
                    Button.Locked = true

                    Button.Base.Text = "Are you sure?"
                    Button.Base.TextColor3 = Library.Scheme.AccentColor
                    Library.Registry[Button.Base].TextColor3 = "AccentColor"

                    local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 0.5)

                    Button.Base.Text = Button.Text
                    Button.Base.TextColor3 = Button.Risky and Library.Scheme.RedColor or Library.Scheme.FontColor
                    Library.Registry[Button.Base].TextColor3 = Button.Risky and "RedColor" or "FontColor"

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    RunService.RenderStepped:Wait() --// Mouse Button fires without waiting (i hate roblox)
                    Button.Locked = false
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Base, Button.Stroke = CreateButton(Button)
        InitEvents(Button)

        function Button:AddButton(...)
            local Info = GetInfo(...)

            local SubButton = {
                Connections = {},
                Destroyed = false,

                Text = Info.Text,
                Func = Info.Func,
                DoubleClick = Info.DoubleClick,

                Tooltip = Info.Tooltip,
                DisabledTooltip = Info.DisabledTooltip,
                TooltipTable = nil,

                Risky = Info.Risky,
                Disabled = Info.Disabled,
                Visible = Info.Visible,

                Tween = nil,
                Type = "SubButton",
            }

            Button.SubButton = SubButton
            SubButton.Base, SubButton.Stroke = CreateButton(SubButton)
            InitEvents(SubButton)

            function SubButton:UpdateColors()
                if Library.Unloaded then
                    return
                end

                StopTween(SubButton.Tween)

                SubButton.Base.BackgroundColor3 = SubButton.Disabled and Library.Scheme.BackgroundColor
                    or Library.Scheme.MainColor
                SubButton.Base.TextTransparency = SubButton.Disabled and 0.8 or 0.4
                SubButton.Stroke.Transparency = SubButton.Disabled and 0.5 or 0

                Library.Registry[SubButton.Base].BackgroundColor3 = SubButton.Disabled and "BackgroundColor"
                    or "MainColor"
            end

            function SubButton:SetDisabled(Disabled: boolean)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                SubButton.Base.Active = not SubButton.Disabled
                SubButton:UpdateColors()
            end

            function SubButton:SetVisible(Visible: boolean)
                SubButton.Visible = Visible

                SubButton.Base.Visible = SubButton.Visible
                Groupbox:Resize()
            end

            function SubButton:SetText(Text: string)
                SubButton.Text = Text
                SubButton.Base.Text = Text
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable =
                    Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            if SubButton.Risky then
                SubButton.Base.TextColor3 = Library.Scheme.RedColor
                Library.Registry[SubButton.Base].TextColor3 = "RedColor"
            end

            SubButton:UpdateColors()

            if Info.Idx then
                Buttons[Info.Idx] = SubButton
            else
                table.insert(Buttons, SubButton)
            end

            SubButton.AddKeyPicker = BaseAddons.__index.AddKeyPicker

            function SubButton:Destroy()
                SubButton.Destroyed = true

                if SubButton.TooltipTable then
                    SubButton.TooltipTable:Destroy()
                end

                if SubButton.Tween then
                    SubButton.Tween:Destroy()
                end

                if SubButton.Base then
                    SubButton.Base:Destroy()
                end

                if Info.Idx then
                    Buttons[Info.Idx] = nil
                else
                    local BIdx = table.find(Buttons, SubButton)

                    if BIdx then
                        table.remove(Buttons, BIdx)
                    end
                end
            end

            return SubButton
        end

        function Button:UpdateColors()
            if Library.Unloaded then
                return
            end

            StopTween(Button.Tween)

            Button.Base.BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor
                or Library.Scheme.MainColor
            Button.Base.TextTransparency = Button.Disabled and 0.8 or 0.4
            Button.Stroke.Transparency = Button.Disabled and 0.5 or 0

            Library.Registry[Button.Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor"
        end

        function Button:SetDisabled(Disabled: boolean)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Button.Disabled
            end

            Button.Base.Active = not Button.Disabled
            Button:UpdateColors()
        end

        function Button:SetVisible(Visible: boolean)
            Button.Visible = Visible

            Holder.Visible = Button.Visible
            Groupbox:Resize()
        end

        function Button:SetText(Text: string)
            Button.Text = Text
            Button.Base.Text = Text
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        if Button.Risky then
            Button.Base.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Button.Base].TextColor3 = "RedColor"
        end

        Button:UpdateColors()
        Groupbox:Resize()

        Button.Holder = Holder
        table.insert(Groupbox.Elements, Button)

        if Info.Idx then
            Buttons[Info.Idx] = Button
        else
            table.insert(Buttons, Button)
        end

        Button.AddKeyPicker = BaseAddons.__index.AddKeyPicker

        function Button:Destroy()
            Button.Destroyed = true

            if Button.TooltipTable then
                Button.TooltipTable:Destroy()
            end

            if Button.Tween then
                Button.Tween:Destroy()
            end

            if Button.SubButton then
                Button.SubButton:Destroy()
            end

            if Holder then
                Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Button)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()

            if Info.Idx then
                Buttons[Info.Idx] = nil
            else
                local BIdx = table.find(Buttons, Button)

                if BIdx then
                    table.remove(Buttons, BIdx)
                end
            end
        end

        return Button
    end

    function Funcs:AddCheckbox(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Connections = {},
            Destroyed = false,

            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Addons = {},
            AnyKeyPickerPicking = false,

            Variant = "Checkbox",
            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(26, 0),
            Size = UDim2.new(1, -26, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Checkbox = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Button,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Checkbox,
            })
        )

        local CheckboxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Checkbox,
        })

        local CheckImage = New("ImageLabel", {
            ImageColor3 = "FontColor",
            ImageTransparency = 1,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = Checkbox,
        })
        if CheckIcon then
            Library:ApplyLucideIcon(CheckImage, CheckIcon)
        end

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            CheckboxStroke.Transparency = Toggle.Disabled and 0.5 or 0

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                CheckImage.ImageTransparency = Toggle.Value and 0.8 or 1

                Checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                Library.Registry[Checkbox].BackgroundColor3 = "BackgroundColor"

                return
            end

            TweenService:Create(Label, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(CheckImage, Library.TweenInfo, {
                ImageTransparency = Toggle.Value and 0 or 1,
            }):Play()

            Checkbox.BackgroundColor3 = Library.Scheme.MainColor
            Library.Registry[Checkbox].BackgroundColor3 = "MainColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:RunChanged()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:UpdateDependencyBoxes()

            if not Toggle.AnyKeyPickerPicking then
                Toggle:RunChanged()
            end
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        table.insert(Toggle.Connections, Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end))

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Label].TextColor3 = "RedColor"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        function Toggle:Destroy()
            Toggle.Destroyed = true

            if Toggle.Connections then
                for _, Connection in Toggle.Connections do
                    Connection:Disconnect()
                end
            end

            if Toggle.TooltipTable then
                Toggle.TooltipTable:Destroy()
            end

            if Button then
                Button:Destroy()
            end

            if Toggle.Addons then
                for Index = #Toggle.Addons, 1, -1 do
                    local Addon = table.remove(Toggle.Addons, Index)
                    if Addon and Addon.Destroy then
                        Addon:Destroy()
                    end
                end
            end

            local ElemIdx = table.find(Groupbox.Elements, Toggle)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Toggles[Idx] = nil
        end

        return Toggle
    end

    function Funcs:AddToggle(Idx, Info)
        if self.Destroyed then return nil end

        if Library.ForceCheckbox then
            return Funcs.AddCheckbox(self, Idx, Info)
        end

        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Connections = {},
            Destroyed = false,

            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Addons = {},
            AnyKeyPickerPicking = false,

            Variant = "Switch",
            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, SWITCH_HEIGHT),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -(SWITCH_WIDTH + 10), 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        --// Track/knob are pills at any radius, but go square when the radius is 0
        local SwitchPillRadius = Library.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0)

        local Switch = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = "FontColor",
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(SWITCH_WIDTH, SWITCH_TRACK_HEIGHT),
            Parent = Button,
        })
        table.insert(
            Library.PillCorners,
            New("UICorner", {
                CornerRadius = SwitchPillRadius,
                Parent = Switch,
            })
        )
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2),
            Parent = Switch,
        })
        local SwitchStroke = New("UIStroke", {
            Color = "OutlineColor",
            Transparency = 1,
            Parent = Switch,
        })

        --// The off track is a grey ramp rather than a flat fill. The gradient
        --// multiplies the track colour, so these factors land on #505050 -> #8A8A8A
        --// against a white FontColor, and follow the theme otherwise.
        local SwitchGradient = New("UIGradient", {
            Color = ColorSequence.new(SWITCH_OFF_GRADIENT_FROM, SWITCH_OFF_GRADIENT_TO),
            Parent = Switch,
        })

        --// Sits under the ball, so it has to be a sibling rather than a child
        local BallHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Switch,
        })

        local BallShadow = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "DarkColor",
            BackgroundTransparency = 0.6,
            Position = UDim2.new(0, 0, 0.5, 1),
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            ZIndex = 1,
            Parent = BallHolder,
        })
        table.insert(
            Library.PillCorners,
            New("UICorner", {
                CornerRadius = SwitchPillRadius,
                Parent = BallShadow,
            })
        )

        local Ball = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "FontColor",
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            ZIndex = 2,
            Parent = BallHolder,
        })
        table.insert(
            Library.PillCorners,
            New("UICorner", {
                CornerRadius = SwitchPillRadius,
                Parent = Ball,
            })
        )

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            --// The ball is anchored at its centre, so it travels between the two
            --// insets rather than 0 and 1
            local BallRadius = (SWITCH_TRACK_HEIGHT - 4) / 2
            local Offset = Toggle.Value and UDim2.new(1, -BallRadius, 0.5, 0) or UDim2.new(0, BallRadius, 0.5, 0)

            Switch.BackgroundTransparency = Toggle.Disabled and 0.6 or 0
            SwitchStroke.Transparency = Toggle.Value and 1 or 0.8

            --// On reads as the accent, off as the grey ramp over the track colour
            Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.FontColor
            Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "FontColor"

            SwitchStroke.Color = Library.Scheme.OutlineColor
            Library.Registry[SwitchStroke].Color = "OutlineColor"

            SwitchGradient.Color = Toggle.Value
                and ColorSequence.new(SWITCH_ON_GRADIENT_FROM, SWITCH_ON_GRADIENT_TO)
                or ColorSequence.new(SWITCH_OFF_GRADIENT_FROM, SWITCH_OFF_GRADIENT_TO)

            Ball.BackgroundColor3 = Library.Scheme.FontColor
            Library.Registry[Ball].BackgroundColor3 = "FontColor"

            BallShadow.BackgroundTransparency = Toggle.Disabled and 1 or 0.6

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                Ball.Position = Offset
                BallShadow.Position = Offset + UDim2.fromOffset(0, 1)

                Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                Library.Registry[Ball].BackgroundColor3 = function()
                    return Library:GetDarkerColor(Library.Scheme.FontColor)
                end

                return
            end

            TweenService:Create(Label, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(Ball, SWITCH_BALL_TWEEN, {
                Position = Offset,
            }):Play()
            TweenService:Create(BallShadow, SWITCH_BALL_TWEEN, {
                Position = Offset + UDim2.fromOffset(0, 1),
            }):Play()
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:RunChanged()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:UpdateDependencyBoxes()

            if not Toggle.AnyKeyPickerPicking then
                Toggle:RunChanged()
            end
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in Toggle.Addons do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        table.insert(Toggle.Connections, Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end))

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.RedColor
            Library.Registry[Label].TextColor3 = "RedColor"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggle.Default = Toggle.Value

        Toggles[Idx] = Toggle

        function Toggle:Destroy()
            Toggle.Destroyed = true

            if Toggle.Connections then
                for _, Connection in Toggle.Connections do
                    Connection:Disconnect()
                end
            end

            if Toggle.TooltipTable then
                Toggle.TooltipTable:Destroy()
            end

            if Button then
                Button:Destroy()
            end

            if Toggle.Addons then
                for Index = #Toggle.Addons, 1, -1 do
                    local Addon = table.remove(Toggle.Addons, Index)
                    if Addon and Addon.Destroy then
                        Addon:Destroy()
                    end
                end
            end

            local ElemIdx = table.find(Groupbox.Elements, Toggle)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Toggles[Idx] = nil
        end

        return Toggle
    end

    function Funcs:AddInput(Idx, Info)
        if self.Destroyed then return nil end

        if typeof(Info) == "table" and (typeof(Info.VerifyValue) == "function" and Info.Finished ~= true) then
            Info.Finished = true
        end

        Info = Library:Validate(Info, Templates.Input)

        local Groupbox = self
        local Container = Groupbox.Container

        local Input = {
            Connections = {},
            Destroyed = false,

            Text = Info.Text,
            Value = Info.Default,

            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            ClearTextOnBlur = Info.ClearTextOnBlur,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,
            VerifyValue = Info.VerifyValue,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Input",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 39),
            Visible = Input.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Input.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local Box = New("TextBox", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            PlaceholderText = Input.Placeholder,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local BoxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Box,
        })

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Box,
            })
        )

        function Input:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Input.Disabled and 0.8 or 0
            Box.TextTransparency = Input.Disabled and 0.8 or 0
        end

        function Input:OnChanged(Func)
            Input.Changed = Func
        end

        function Input:RunChanged()
            Library:SafeCallback(Input.Callback, Input.Value)
            Library:SafeCallback(Input.Changed, Input.Value)
        end

        function Input:SetValue(Text)
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Input.Numeric then
                if #tostring(Text) > 0 and not tonumber(Text) then
                    Text = Input.Value
                end
            end

            if typeof(Info.VerifyValue) == "function" and (Text ~= Input.EmptyReset and Info.VerifyValue(Text) ~= true) then
                Text = Input.EmptyReset
            end

            Input.Value = Text
            Box.Text = Text

            if not Input.Disabled then
                Input:RunChanged()
            end
        end

        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled

            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Input.Disabled
            end

            Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Input.Disabled
            Input:UpdateColors()
        end

        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible

            Holder.Visible = Input.Visible
            Groupbox:Resize()
        end

        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end

        if Input.Finished then
            table.insert(Input.Connections, Box.FocusLost:Connect(function(Enter)
                if not Enter then
                    if Input.ClearTextOnBlur then
                        Box.Text = Input.Value
                    end

                    return
                end

                Input:SetValue(Box.Text)
            end))
        else
            table.insert(Input.Connections, Box:GetPropertyChangedSignal("Text"):Connect(function()
                if Box.Text == Input.Value then return end

                Input:SetValue(Box.Text)
            end))
        end

        table.insert(Input.Connections, Box.Focused:Connect(function()
            if Input.Disabled then
                return
            end

            Library.Registry[BoxStroke].Color = "AccentColor"
            TweenService:Create(BoxStroke, Library.TweenInfo, {
                Color = Library.Scheme.AccentColor,
            }):Play()
        end))

        table.insert(Input.Connections, Box.FocusLost:Connect(function()
            Library.Registry[BoxStroke].Color = "OutlineColor"
            TweenService:Create(BoxStroke, Library.TweenInfo, {
                Color = Library.Scheme.OutlineColor,
            }):Play()
        end))

        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end

        Groupbox:Resize()

        Input.Holder = Holder
        table.insert(Groupbox.Elements, Input)

        Input.Default = Input.Value
        if typeof(Info.VerifyValue) == "function" and (Input.Default ~= Input.EmptyReset and Info.VerifyValue(Input.Default) ~= true) then
            Input:SetValue(Input.EmptyReset)
            Input.Default = Input.EmptyReset
        end

        Options[Idx] = Input

        function Input:Destroy()
            Input.Destroyed = true

            if Input.Connections then
                for _, Connection in Input.Connections do
                    Connection:Disconnect()
                end
            end

            if Input.TooltipTable then
                Input.TooltipTable:Destroy()
            end

            if Holder then
                Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Input)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Input
    end

    function Funcs:AddSlider(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Slider)

        local Groupbox = self
        local Container = Groupbox.Container

        local Slider = {
            Connections = {},
            Destroyed = false,

            Text = Info.Text,
            Value = Info.Default,

            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding,
            HideMax = Info.HideMax,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            AllowRightClickInput = Info.AllowRightClickInput,

            Type = "Slider",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(
                1,
                0,
                0,
                Info.Compact and 15 or (22 + SLIDER_BAR_HEIGHT + SLIDER_BALL_MARGIN)
            ),
            Visible = Slider.Visible,
            Parent = Container,
        })

        --// Label on the left and value on the right, both above the bar
        local SliderLabel
        local TopRow
        if not Info.Compact then
            TopRow = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Parent = Holder,
            })

            SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -70, 1, 0),
                Text = Slider.Text,
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = TopRow,
            })
        end

        local Bar = New("TextButton", {
            Active = not Slider.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            --// Same grey material as the switch track, rather than near black
            BackgroundColor3 = Info.Compact and "MainColor" or "FontColor",
            Position = Info.Compact and UDim2.fromScale(0, 1)
                or UDim2.new(0, 0, 1, -SLIDER_BALL_MARGIN),
            Size = UDim2.new(1, 0, 0, Info.Compact and 15 or SLIDER_BAR_HEIGHT),
            Text = "",
            Parent = Holder,
        })

        New("UIStroke", {
            Color = "OutlineColor",
            Parent = Bar,
        })

        if not Info.Compact then
            New("UIGradient", {
                Color = ColorSequence.new(SLIDER_TRACK_GRADIENT_FROM, SLIDER_TRACK_GRADIENT_TO),
                Parent = Bar,
            })
        end

        --// Compact keeps the value inside the bar; otherwise it sits top right
        local DisplayLabel = New("TextLabel", {
            AnchorPoint = Info.Compact and Vector2.new(0, 0) or Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = Info.Compact and UDim2.fromScale(0, 0) or UDim2.fromScale(1, 0),
            Size = Info.Compact and UDim2.fromScale(1, 1) or UDim2.new(0, 70, 1, 0),
            Text = "",
            TextSize = 14,
            TextTransparency = Info.Compact and 0 or 0.4,
            TextXAlignment = Info.Compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Right,
            ZIndex = Bar.ZIndex + 3,
            Parent = Info.Compact and Bar or TopRow,
        })
        if Info.Compact then
            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = "DarkColor",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = DisplayLabel,
            })
        end

        local InputTextBox
        local InputTextBoxStroke
        if Info.AllowRightClickInput then
            InputTextBox = New("TextBox", {
                AnchorPoint = DisplayLabel.AnchorPoint,
                BackgroundTransparency = 1,
                Position = DisplayLabel.Position,
                Size = DisplayLabel.Size,
                Text = "",
                TextSize = 14,
                TextXAlignment = DisplayLabel.TextXAlignment,
                ZIndex = Bar.ZIndex + 4,
                Visible = false,
                ClearTextOnFocus = false,
                Parent = DisplayLabel.Parent,
            })
            InputTextBoxStroke = New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = "DarkColor",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = InputTextBox,
            })
        end

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.fromScale(0.5, 1),
            ZIndex = Bar.ZIndex + 1,
            Parent = Bar,
        })

        --// Ball riding the fill edge. Not shown in compact, which has no room.
        local Ball
        local BallShadow
        local BallActive = false
        if not Info.Compact then
            --// Roblox strokes sit outside the border, so the inner outline is a
            --// ring inset by a pixel rather than a stroke on the bar itself
            local InnerOutline = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(1, -2, 1, -2),
                ZIndex = Bar.ZIndex + 2,
                Parent = Bar,
            })
            table.insert(
                Library.PillCorners,
                New("UICorner", {
                    CornerRadius = Library.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0),
                    Parent = InnerOutline,
                })
            )
            New("UIStroke", {
                Color = "DarkColor",
                Transparency = 0.7,
                Parent = InnerOutline,
            })

            BallShadow = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "DarkColor",
                BackgroundTransparency = 0.55,
                Position = UDim2.new(0, 0, 0.5, 1),
                Size = UDim2.fromOffset(SLIDER_BALL_SIZE, SLIDER_BALL_SIZE),
                ZIndex = Bar.ZIndex + 3,
                Parent = Bar,
            })
            table.insert(
                Library.PillCorners,
                New("UICorner", {
                    CornerRadius = Library.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0),
                    Parent = BallShadow,
                })
            )

            Ball = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "FontColor",
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(SLIDER_BALL_SIZE, SLIDER_BALL_SIZE),
                ZIndex = Bar.ZIndex + 4,
                Parent = Bar,
            })
            table.insert(
                Library.PillCorners,
                New("UICorner", {
                    CornerRadius = Library.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0),
                    Parent = Ball,
                })
            )
            New("UIStroke", {
                Color = "DarkColor",
                Transparency = 0.75,
                Parent = Ball,
            })
        end

        --// Pill shaped bar and fill, squaring off with everything else at radius 0
        table.insert(
            Library.PillCorners,
            New("UICorner", {
                CornerRadius = Library.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0),
                Parent = Bar,
            })
        )

        table.insert(
            Library.PillCorners,
            New("UICorner", {
                CornerRadius = Library.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0),
                Parent = Fill,
            })
        )

        --// Grows the ball while hovered or dragged, per the design note. The fill
        --// ends at the ball's centre, so it has to travel with it.
        local function SetBallActive(Active: boolean)
            if not Ball or BallActive == Active or Slider.Disabled then
                return
            end

            BallActive = Active

            local Diameter = Active and SLIDER_BALL_SIZE_ACTIVE or SLIDER_BALL_SIZE
            local Size = UDim2.fromOffset(Diameter, Diameter)

            local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            local Edge = UDim.new(X, (0.5 - X) * Diameter)
            local Position = UDim2.new(Edge.Scale, Edge.Offset, 0.5, 0)

            TweenService:Create(Ball, SLIDER_BALL_TWEEN, {
                Size = Size,
                Position = Position,
            }):Play()
            TweenService:Create(BallShadow, SLIDER_BALL_TWEEN, {
                Size = Size,
                Position = Position + UDim2.fromOffset(0, 1),
            }):Play()
            TweenService:Create(Fill, SLIDER_BALL_TWEEN, {
                Size = UDim2.new(Edge.Scale, Edge.Offset, 1, 0),
            }):Play()
        end

        function Slider:UpdateColors()
            if Library.Unloaded then
                return
            end

            if SliderLabel then
                SliderLabel.TextTransparency = Slider.Disabled and 0.8 or 0
            end
            DisplayLabel.TextTransparency = Slider.Disabled and 0.8 or 0

            if Info.AllowRightClickInput then
                InputTextBox.TextTransparency = Slider.Disabled and 0.8 or 0
            end

            Fill.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
            Library.Registry[Fill].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "AccentColor"
        end

        function Slider:Display()
            if Library.Unloaded then
                return
            end

            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                if Info.Compact then
                    DisplayLabel.Text =
                        string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, Slider.Value, Slider.Suffix)
                elseif Info.HideMax then
                    DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
                else
                    DisplayLabel.Text = string.format(
                        "%s%s%s/%s%s%s",
                        Slider.Prefix,
                        Slider.Value,
                        Slider.Suffix,
                        Slider.Prefix,
                        Slider.Max,
                        Slider.Suffix
                    )
                end
            end

            local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)

            if not Ball then
                Fill.Size = UDim2.fromScale(X, 1)
                return
            end

            --// Nudged inward at the ends so the ball never hangs off the bar
            local Size = BallActive and SLIDER_BALL_SIZE_ACTIVE or SLIDER_BALL_SIZE
            local Edge = UDim.new(X, (0.5 - X) * Size)

            --// The fill runs to the middle of the ball rather than to the raw
            --// value, so the ball always covers its rounded cap. Ending them at
            --// different places leaves a notch between the two at low values.
            Fill.Size = UDim2.new(Edge.Scale, Edge.Offset, 1, 0)

            local Position = UDim2.new(Edge.Scale, Edge.Offset, 0.5, 0)
            Ball.Position = Position
            BallShadow.Position = Position + UDim2.fromOffset(0, 1)
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")

            Slider:SetValue(math.clamp(Slider.Value, Slider.Min, Value))
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

            Slider:SetValue(math.clamp(Slider.Value, Value, Slider.Max))
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:RunChanged()
            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num or Num == Slider.Value then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            Slider:RunChanged()
        end

        function Slider:SetDisabled(Disabled: boolean)
            Slider.Disabled = Disabled

            if Slider.TooltipTable then
                Slider.TooltipTable.Disabled = Slider.Disabled
            end

            Bar.Active = not Slider.Disabled
            Slider:UpdateColors()
        end

        function Slider:SetVisible(Visible: boolean)
            Slider.Visible = Visible

            Holder.Visible = Slider.Visible
            Groupbox:Resize()
        end

        function Slider:SetText(Text: string)
            Slider.Text = Text
            if SliderLabel then
                SliderLabel.Text = Text
                return
            end
            Slider:Display()
        end

        function Slider:SetPrefix(Prefix: string)
            Slider.Prefix = Prefix
            Slider:Display()
        end

        function Slider:SetSuffix(Suffix: string)
            Slider.Suffix = Suffix
            Slider:Display()
        end

        if Info.AllowRightClickInput then
            local LastValidText = ""
            table.insert(Slider.Connections, InputTextBox:GetPropertyChangedSignal("Text"):Connect(function()
                local Text = InputTextBox.Text
                local AsNum = tonumber(Text)

                if #tostring(Text) > 0 and not AsNum and Text ~= "-" then
                    InputTextBox.Text = LastValidText
                else
                    if Slider.Rounding == 0 and Text:find("%.") then
                        InputTextBox.Text = LastValidText
                        return
                    end

                    local DecimalPos = Text:find("%.")
                    if DecimalPos and Slider.Rounding > 0 then
                        local Decimals = #Text - DecimalPos
                        if Decimals > Slider.Rounding then
                            InputTextBox.Text = LastValidText
                            return
                        end
                    end

                    LastValidText = Text

                    if AsNum then
                        if AsNum > Slider.Max then
                            InputTextBox.Text = tostring(Slider.Max)
                        elseif AsNum < Slider.Min then
                            InputTextBox.Text = tostring(Slider.Min)
                        end
                    end
                end
            end))

            table.insert(Slider.Connections, InputTextBox.FocusLost:Connect(function()
                InputTextBox.Visible = false
                DisplayLabel.Visible = true

                local Num = tonumber(InputTextBox.Text)
                if not Num then
                    return
                end

                Num = Round(Num, Slider.Rounding)
                Slider:SetValue(Num)
            end))

            table.insert(Slider.Connections, InputTextBox.Focused:Connect(function()
                Library.Registry[InputTextBoxStroke].Color = "AccentColor"
                TweenService:Create(InputTextBoxStroke, Library.TweenInfo, {
                    Color = Library.Scheme.AccentColor,
                }):Play()
            end))

            table.insert(Slider.Connections, InputTextBox.FocusLost:Connect(function()
                Library.Registry[InputTextBoxStroke].Color = "DarkColor"
                TweenService:Create(InputTextBoxStroke, Library.TweenInfo, {
                    Color = Library.Scheme.DarkColor,
                }):Play()
            end))
        end

        local LastTap = 0
        table.insert(Slider.Connections, Bar.InputBegan:Connect(function(Input: InputObject)
            local ValidInput = IsClickInput(Input) or Input.UserInputType == Enum.UserInputType.MouseButton2
            if not ValidInput or Slider.Disabled then
                return
            end

            if Info.AllowRightClickInput then
                local IsRightClick = Input.UserInputType == Enum.UserInputType.MouseButton2
                local IsDoubleTap = false

                if Library.IsMobile and Input.UserInputType == Enum.UserInputType.Touch then
                    if tick() - LastTap < 0.3 then
                        IsDoubleTap = true
                    end

                    LastTap = tick()
                end

                if IsRightClick or IsDoubleTap then
                    InputTextBox.Text = tostring(Slider.Value)
                    InputTextBox.Visible = true
                    DisplayLabel.Visible = false

                    task.spawn(InputTextBox.CaptureFocus, InputTextBox)
                    return
                end
            end

            if not IsClickInput(Input) then
                return
            end

            for _, Side in Library:GetActiveSides() do
                Side.ScrollingEnabled = false
            end

            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = false
            end

            SetBallActive(true)

            while IsDragInput(Input) and not Slider.Destroyed do
                local Location = Mouse.X
                local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)

                local OldValue = Slider.Value
                Slider.Value = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                Slider:Display()
                if Slider.Value ~= OldValue then
                    Slider:RunChanged()
                end

                RunService.RenderStepped:Wait()
            end

            for _, Side in Library:GetActiveSides() do
                Side.ScrollingEnabled = true
            end

            if Library.ActiveLoading and Library.ActiveLoading.Sidebar then
                Library.ActiveLoading.Sidebar.Container.ScrollingEnabled = true
            end

            --// Stay grown if the cursor is still over the bar after the drag
            SetBallActive(Library:MouseIsOverFrame(Bar, Mouse))
        end))

        if Ball then
            table.insert(
                Slider.Connections,
                Bar.MouseEnter:Connect(function()
                    SetBallActive(true)
                end)
            )
            table.insert(
                Slider.Connections,
                Bar.MouseLeave:Connect(function()
                    --// A drag that left the bar keeps it grown until the mouse is up
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        return
                    end

                    SetBallActive(false)
                end)
            )
        end

        if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
            Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
            Slider.TooltipTable.Disabled = Slider.Disabled
        end

        Slider:UpdateColors()
        Slider:Display()
        Groupbox:Resize()

        Slider.Holder = Holder
        table.insert(Groupbox.Elements, Slider)

        Slider.Default = Slider.Value

        Options[Idx] = Slider

        function Slider:Destroy()
            Slider.Destroyed = true

            if Slider.Connections then
                for _, Connection in Slider.Connections do
                    Connection:Disconnect()
                end
            end

            if Slider.TooltipTable then
                Slider.TooltipTable:Destroy()
            end

            if Holder then
                Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Slider)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Dropdown)

        local Groupbox = self
        local Container = Groupbox.Container

        if Info.SpecialType == "Player" then
            Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams()
            Info.AllowNull = true
        end

        local Dropdown = {
            Connections = {},
            Destroyed = false,

            Text = typeof(Info.Text) == "string" and Info.Text or nil,

            Value = Info.Multi and {} or nil,
            Values = Info.Values,
            DisabledValues = Info.DisabledValues,
            ValueImages = Info.ValueImages,

            Multi = Info.Multi,
            DragSelect = Info.Multi and not Library.IsMobile and Info.DragSelect == true,

            --// Kept on the table so search can read values the way the user sees them
            FormatListValue = Info.FormatListValue,
            FormatDisplayValue = Info.FormatDisplayValue,

            SpecialType = Info.SpecialType,
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer,
            EnablePlayerImages = Info.EnablePlayerImages,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Dropdown",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Dropdown.Text and 39 or 21),
            Visible = Dropdown.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Dropdown.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not not Info.Text,
            ZIndex = 3,
            Parent = Holder,
        })

        local DisplayContainer = New("TextButton", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = "",
            TextTransparency = 1,
            ZIndex = 2,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 4),
            Parent = DisplayContainer,
        })

        local DisplayStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = DisplayContainer,
        })

        local DropdownCorner = New("UICorner", {
            TopLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = DisplayContainer,
        }); table.insert(Library.SpecificCorners, DropdownCorner)

        local DisplayImage = New("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(-4, 3),
            Size = UDim2.fromOffset(16, 16),
            Image = "",
            ImageTransparency = 1,
            ZIndex = 2,
            Parent = DisplayContainer,
        })

        local DisplayButton = New("TextButton", {
            Active = not Dropdown.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 21),
            Text = "---",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
            Parent = DisplayContainer,
        })

        local ArrowImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            ImageColor3 = "FontColor",
            ImageTransparency = 0.5,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(16, 16),
            Parent = DisplayContainer,
        })
        if ArrowIcon then
            Library:ApplyLucideIcon(ArrowImage, ArrowIcon)
        end

        --// Opens every value in a panel over the window
        local ExpandButton
        local ExpandIconImage
        if Info.Expandable ~= false then
            local ExpandIcon = Library:GetIcon("maximize-2")

            ExpandButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -18, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Text = "",
                ZIndex = 3,
                Parent = DisplayContainer,
            })
            ExpandIconImage = New("ImageLabel", {
                Image = ExpandIcon and ExpandIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = ExpandIcon and ExpandIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = ExpandIcon and ExpandIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Fit,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 3,
                Parent = ExpandButton,
            })

            ExpandButton.MouseEnter:Connect(function()
                if Dropdown.Disabled then
                    return
                end

                TweenService:Create(ExpandIconImage, Library.TweenInfo, { ImageTransparency = 0 }):Play()
            end)
            ExpandButton.MouseLeave:Connect(function()
                if Dropdown.Disabled then
                    return
                end

                TweenService:Create(ExpandIconImage, Library.TweenInfo, { ImageTransparency = 0.5 }):Play()
            end)

            Library:AddTooltip("Expand", nil, ExpandButton)
        end

        local SearchBox
        if Info.Searchable then
            SearchBox = New("TextBox", {
                BackgroundTransparency = 1,
                PlaceholderText = "Search...",
                Position = UDim2.fromOffset(-8, 0),
                Size = UDim2.new(1, ExpandButton and -34 or -12, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = false,
                Parent = DisplayButton,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                Parent = SearchBox,
            })

            table.insert(Dropdown.Connections, SearchBox.Focused:Connect(function()
                Library.Registry[DisplayStroke].Color = "AccentColor"
                TweenService:Create(DisplayStroke, Library.TweenInfo, {
                    Color = Library.Scheme.AccentColor,
                }):Play()
            end))

            table.insert(Dropdown.Connections, SearchBox.FocusLost:Connect(function()
                Library.Registry[DisplayStroke].Color = "OutlineColor"
                TweenService:Create(DisplayStroke, Library.TweenInfo, {
                    Color = Library.Scheme.OutlineColor,
                }):Play()
            end))
        end

        local GetValueImage = function(Value, RawValue)
            if not Value then
                return nil
            end

            local ValueImage = nil
            if Dropdown.SpecialType == "Player" and Dropdown.EnablePlayerImages == true then
                local PlayerValue = Value
                if typeof(PlayerValue) ~= "Instance" and RawValue ~= nil then
                    PlayerValue = RawValue
                end

                if typeof(PlayerValue) == "Instance" and PlayerValue:IsA("Player") then
                    ValueImage = { Url = string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=48&h=48", tostring(PlayerValue.UserId)) }
                end
            end

            if Dropdown.ValueImages then
                local IconRef = Dropdown.ValueImages[Value]
                if IconRef == nil and RawValue ~= nil then
                    IconRef = Dropdown.ValueImages[RawValue]
                end

                if IconRef then
                    ValueImage = Library:GetCustomIcon(IconRef)
                end
            end

            return ValueImage
        end

        local MenuTable
        MenuTable = Library:AddContextMenu(
            DisplayContainer,
            function()
                return UDim2.fromOffset((DisplayContainer.AbsoluteSize.X / Library.DPIScale), 0)
            end,
            function()
                return { 0.5, DisplayContainer.AbsoluteSize.Y + 1.5 }
            end,
            2,
            function(Active: boolean)
                DisplayButton.TextTransparency = (Active and SearchBox) and 1 or 0

                ArrowImage.ImageTransparency = Active and 0 or 0.5
                ArrowImage.Rotation = Active and 180 or 0

                if SearchBox then
                    SearchBox.Text = ""
                    SearchBox.Visible = Active
                end

                local Half = UDim.new(0, Library.CornerRadius / 2)
                local Zero = UDim.new(0, 0)

                DropdownCorner.TopLeftRadius = Half
                DropdownCorner.TopRightRadius = Half
                DropdownCorner.BottomRightRadius = Active and Zero or Half
                DropdownCorner.BottomLeftRadius = Active and Zero or Half

                local MenuCorner = MenuTable and MenuTable.Corner
                if MenuCorner then
                    MenuCorner.TopLeftRadius = Zero
                    MenuCorner.TopRightRadius = Zero
                    MenuCorner.BottomRightRadius = Half
                    MenuCorner.BottomLeftRadius = Half
                end
            end,
            false,
            "bottom",
            "Dropdown"
        )
        Dropdown.Menu = MenuTable

        local ItemHeight = 21
        local PoolSize = math.max(1, Info.MaxVisibleDropdownItems + 2)
        local Pool = {}
        local FilteredEntries = {}

        --// Select All / Deselect All + expanded panel state (fork additions layered
        --// on top of upstream's pooled inline list)
        local UseSelectAll = Info.Multi and Info.SelectAllButtons ~= false
        --// Space reserved at the top of the virtualized canvas for the inline
        --// Select All / Deselect All row (scrolls with the values, like upstream)
        local HeaderOffset = UseSelectAll and ItemHeight or 0
        local ExpandedButtons = {}
        local RebuildExpandedList

        local function IsValueSelected(Value)
            if Info.Multi then
                return Dropdown.Value[Value] == true
            end

            return Dropdown.Value == Value
        end

        --// Repaint both views: upstream's pooled inline rows and our expanded panel
        local function RefreshButtons()
            for _, Row in Pool do
                Row:UpdateButton()
            end
            for _, Table in ExpandedButtons do
                Table:UpdateButton()
            end
        end

        --// Shared by the inline list and the expanded panel
        local function ToggleValue(Value)
            local Try = not IsValueSelected(Value)

            --// Refuse to clear the last value unless null is allowed
            if not (Dropdown:GetActiveValues(true) == 1 and not Try and not Info.AllowNull) then
                if Info.Multi then
                    Dropdown.Value[Value] = Try and true or nil
                else
                    Dropdown.Value = Try and Value or nil
                end
            end

            RefreshButtons()
            Dropdown:Display()

            Library:UpdateDependencyBoxes()
            Dropdown:RunChanged()
        end

        --// Every value the user could click right now, search filter included
        local function GetSelectableValues(Search)
            local Table = {}

            for _, Value in Dropdown.Values do
                if table.find(Dropdown.DisabledValues, Value) then
                    continue
                end

                if Search and Search ~= "" then
                    local FormattedValue = tostring(Info.FormatListValue and Info.FormatListValue(Value) or Value)
                    if not TryFuzzyMatch(FormattedValue, Search:lower()) then
                        continue
                    end
                end

                table.insert(Table, Value)
            end

            return Table
        end

        local function ApplyBulkSelection(State, Search)
            if not Info.Multi then
                return
            end

            local Values = GetSelectableValues(Search)
            if #Values == 0 then
                return
            end

            for _, Value in Values do
                Dropdown.Value[Value] = State or nil
            end

            --// Something has to stay picked when null is not allowed
            if not State and not Info.AllowNull and Dropdown:GetActiveValues(true) == 0 then
                Dropdown.Value[Values[1]] = true
            end

            RefreshButtons()
            Dropdown:Display()

            Library:UpdateDependencyBoxes()
            Dropdown:RunChanged()
        end

        function Dropdown:SelectAll(Search)
            ApplyBulkSelection(true, Search)
        end

        function Dropdown:DeselectAll(Search)
            ApplyBulkSelection(false, Search)
        end

        function Dropdown:RecalculateListSize(Count)
            local ItemCount = Count or #FilteredEntries
            local Y = math.clamp(ItemCount * ItemHeight + HeaderOffset, 0, Info.MaxVisibleDropdownItems * ItemHeight + HeaderOffset)

            MenuTable.Menu.CanvasSize = UDim2.fromOffset(0, ItemCount * ItemHeight + HeaderOffset)

            MenuTable:SetSize(function()
                return UDim2.fromOffset((DisplayContainer.AbsoluteSize.X / Library.DPIScale), Y)
            end)
        end

        function Dropdown:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
            DisplayButton.TextTransparency = Dropdown.Disabled and 0.8 or 0
            DisplayImage.ImageTransparency = Dropdown.Disabled and 0.8 or 0
            ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or MenuTable.Active and 0 or 0.5

            if ExpandIconImage then
                ExpandIconImage.ImageTransparency = Dropdown.Disabled and 0.8 or 0.5
            end
        end

        function Dropdown:Display()
            if Library.Unloaded then
                return
            end

            local Str = ""
            local ValueImage = nil
            local IsDictionary = not IsSequentialArray(Dropdown.Values)

            if Info.Multi then
                for Key, RawValue in Dropdown.Values do
                    local Value = IsDictionary and Key or RawValue

                    if Dropdown.Value[Value] then
                        if not ValueImage then
                            ValueImage = GetValueImage(Value, RawValue)
                        end

                        Str = Str
                            .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(RawValue)) or tostring(RawValue))
                            .. ", "
                    end
                end

                Str = Str:sub(1, #Str - 2)
            else
                local DisplayValue = Dropdown.Value
                if IsDictionary and Dropdown.Value ~= nil then
                    DisplayValue = Dropdown.Values[Dropdown.Value]
                end

                ValueImage = GetValueImage(Dropdown.Value, DisplayValue)
                Str = DisplayValue and tostring(DisplayValue) or ""

                if Str ~= "" and Info.FormatDisplayValue then
                    Str = tostring(Info.FormatDisplayValue(Str))
                end
            end

            if #Str > 25 then
                Str = Str:sub(1, 22) .. "..."
            end

            DisplayButton.Text = (Str == "" and "---" or Str)

            if ValueImage then
                Library:ApplyLucideIcon(DisplayImage, ValueImage)
                DisplayImage.ImageTransparency = 0
            else
                DisplayImage.Image = ""
                DisplayImage.ImageTransparency = 1
            end

            DisplayButton.Size = ValueImage and UDim2.new(1, -8, 0, 21) or UDim2.new(1, 0, 0, 21)
            DisplayButton.Position = ValueImage and UDim2.fromOffset(14, 0) or UDim2.fromOffset(0, 0)
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
        end

        function Dropdown:GetActiveValues(ReturnCount)
            local Table = {}

            if Info.Multi then
                for Value, _ in Dropdown.Value do
                    table.insert(Table, Value)
                end
            else
                if Dropdown.Value then
                    table.insert(Table, Dropdown.Value)
                end
            end

            return ReturnCount == true and GetTableSize(Table) or Table
        end

        local DragSelecting = false
        local DragStartIndex = nil
        local DragPrevMin = nil
        local DragPrevMax = nil
        local DragLastIndex = nil
        local DragInitialValues = {}
        local DragInputEndedConn = nil
        local DragInputChangedConn = nil

        local function RecomputeFilteredEntries()
            local Values = Dropdown.Values
            local DisabledValues = Dropdown.DisabledValues
            local IsDictionary = not IsSequentialArray(Values)

            --// Fuzzy-match dropdown values the same way the sidebar search
            --// does, so e.g. "clr" can find "Clear Inventory" in a list \\--
            local SearchQuery = SearchBox and NormalizeSearch(SearchBox.Text:lower()) or ""
            local IsSearching = SearchQuery ~= ""

            local EnabledList, DisabledList = {}, {}
            local Pending = {}

            for Key, RawValue in Values do
                local Value = IsDictionary and Key or RawValue

                local FormattedValue = tostring(Info.FormatListValue and Info.FormatListValue(RawValue) or RawValue)

                local MatchScore = 0
                if IsSearching then
                    local Matched, Score = FuzzyScore(FormattedValue:lower(), SearchQuery)
                    if not Matched then
                        continue
                    end
                    MatchScore = Score
                end

                local IsDisabled = table.find(DisabledValues, Value) ~= nil
                    or (RawValue ~= nil and RawValue ~= Value and table.find(DisabledValues, RawValue) ~= nil)

                local Entry = {
                    Value = Value,
                    RawValue = RawValue,
                    FormattedValue = FormattedValue,
                    IsDisabled = IsDisabled,
                    ValueImage = GetValueImage(Value, RawValue),
                    SortKey = Key,
                    MatchScore = MatchScore,
                    Order = #Pending + 1,
                }

                table.insert(Pending, Entry)
            end

            if IsSearching then
                --// Best matches first; ties fall back to original order \\--
                table.sort(Pending, function(A, B)
                    if A.MatchScore ~= B.MatchScore then
                        return A.MatchScore > B.MatchScore
                    end
                    return A.Order < B.Order
                end)
            elseif not IsDictionary then
                table.sort(Pending, function(A, B)
                    return A.SortKey < B.SortKey
                end)
            end

            for _, Entry in Pending do
                if Entry.IsDisabled then
                    table.insert(DisabledList, Entry)
                else
                    table.insert(EnabledList, Entry)
                end
            end

            table.clear(FilteredEntries)
            for _, Entry in EnabledList do
                table.insert(FilteredEntries, Entry)
            end
            for _, Entry in DisabledList do
                table.insert(FilteredEntries, Entry)
            end
        end

        local function GetFirstVisibleIndex()
            local Total = #FilteredEntries
            if Total <= PoolSize then
                return 1
            end

            local MaxFirst = Total - PoolSize + 1
            local ScrollY = MenuTable.Menu.CanvasPosition.Y / Library.DPIScale
            local Index = math.floor(math.max(0, ScrollY - HeaderOffset) / ItemHeight) + 1
            return math.clamp(Index, 1, MaxFirst)
        end

        function Dropdown:RefreshPool()
            local Total = #FilteredEntries
            local First = GetFirstVisibleIndex()

            for SlotIndex, Row in Pool do
                local DataIndex = First + SlotIndex - 1
                local Entry = FilteredEntries[DataIndex]

                Row.Entry = Entry
                Row.Index = Entry and DataIndex or nil

                if not Entry then
                    Row.Container.Visible = false
                    continue
                end

                Row.Container.Visible = true
                Row.Container.Position = UDim2.fromOffset(0, (DataIndex - 1) * ItemHeight + HeaderOffset)

                local IsLast = DataIndex == Total
                Row.Corner.BottomRightRadius = IsLast and UDim.new(0, Library.CornerRadius / 2) or UDim.new(0, 0)
                Row.Corner.BottomLeftRadius = IsLast and UDim.new(0, Library.CornerRadius / 2) or UDim.new(0, 0)

                Row.Button.Text = Entry.FormattedValue

                if Entry.ValueImage then
                    Row.Image.Visible = true
                    Library:ApplyLucideIcon(Row.Image, Entry.ValueImage)
                    Row.Button.Size = UDim2.new(1, -18, 0, ItemHeight)
                    Row.Button.Position = UDim2.fromOffset(18, 0)
                else
                    Row.Image.Visible = false
                    Row.Button.Size = UDim2.new(1, 0, 0, ItemHeight)
                    Row.Button.Position = UDim2.fromOffset(0, 0)
                end

                Row:UpdateButton()
            end
        end

        function Dropdown:RunChanged()
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        end

        local function StopDragSelect()
            DragSelecting = false
            DragStartIndex = nil
            DragPrevMin = nil
            DragPrevMax = nil
            DragLastIndex = nil
            table.clear(DragInitialValues)

            if DragInputEndedConn then
                DragInputEndedConn:Disconnect()
                DragInputEndedConn = nil
            end

            if DragInputChangedConn then
                DragInputChangedConn:Disconnect()
                DragInputChangedConn = nil
            end
        end

        local DragActiveCount = 0

        local function ApplyDragIndex(Index, InRange)
            local Entry = FilteredEntries[Index]
            if not Entry or Entry.IsDisabled then
                return
            end

            local Try = DragInitialValues[Entry.Value]
            if InRange then
                Try = not Try
            end

            local WantActive = Try and true or false
            local IsActive = Dropdown.Value[Entry.Value] and true or false
            if WantActive == IsActive then
                return
            end

            if not WantActive and DragActiveCount == 1 and not Info.AllowNull then
                return
            end

            Dropdown.Value[Entry.Value] = WantActive and true or nil
            DragActiveCount += WantActive and 1 or -1
        end

        local function ApplyDragRange(From, To, InRange)
            for Index = From, To do
                ApplyDragIndex(Index, InRange)
            end
        end

        local function UpdateDrag(CurrentIndex)
            if CurrentIndex == nil or CurrentIndex == DragLastIndex then
                return
            end

            DragLastIndex = CurrentIndex

            local Min = math.min(DragStartIndex, CurrentIndex)
            local Max = math.max(DragStartIndex, CurrentIndex)
            DragActiveCount = Dropdown:GetActiveValues(true)

            if DragPrevMin == nil then
                ApplyDragRange(Min, Max, true)
            else
                if DragPrevMin < Min then
                    ApplyDragRange(DragPrevMin, Min - 1, false)
                end
                if DragPrevMax > Max then
                    ApplyDragRange(Max + 1, DragPrevMax, false)
                end
                if Min < DragPrevMin then
                    ApplyDragRange(Min, DragPrevMin - 1, true)
                end
                if Max > DragPrevMax then
                    ApplyDragRange(DragPrevMax + 1, Max, true)
                end
            end

            DragPrevMin = Min
            DragPrevMax = Max

            for _, OtherRow in Pool do
                OtherRow:UpdateButton()
            end
        end

        local function CreatePoolRow()
            local Row = {
                Entry = nil,
                Index = nil
            }

            local Container = New("Frame", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, ItemHeight),
                Visible = false,
                Parent = MenuTable.Menu,
            })

            local Corner = New("UICorner", {
                TopLeftRadius = UDim.new(0, 0),
                TopRightRadius = UDim.new(0, 0),
                BottomRightRadius = UDim.new(0, 0),
                BottomLeftRadius = UDim.new(0, 0),
                Parent = Container,
            }); table.insert(Library.SpecificCorners, Corner)

            local Image = New("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "",
                ImageTransparency = 0.5,
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.fromOffset(4, 3),
                Visible = false,
                Parent = Container,
            })

            local Button = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, ItemHeight),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Container,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                Parent = Button,
            })

            Row.Container = Container
            Row.Corner = Corner
            Row.Image = Image
            Row.Button = Button

            function Row:UpdateButton()
                local Entry = Row.Entry
                if not Entry then
                    return
                end

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Entry.Value]
                else
                    Selected = Dropdown.Value == Entry.Value
                end

                Row.Selected = Selected and true or false

                Container.BackgroundTransparency = Selected and 0 or 1
                Button.TextTransparency = Entry.IsDisabled and 0.8 or Selected and 0 or 0.5

                if Entry.ValueImage then
                    Image.ImageTransparency = Entry.IsDisabled and 0.8 or Selected and 0 or 0.5
                end
            end

            Button.MouseButton1Click:Connect(function()
                local Entry = Row.Entry
                if not Entry or Entry.IsDisabled or DragSelecting then
                    return
                end

                local Selected
                if Info.Multi then
                    Selected = Dropdown.Value[Entry.Value]
                else
                    Selected = Dropdown.Value == Entry.Value
                end

                local Try = not Selected
                if not (Dropdown:GetActiveValues(true) == 1 and not Try and not Info.AllowNull) then
                    Selected = Try
                    if Info.Multi then
                        Dropdown.Value[Entry.Value] = Selected and true or nil
                    else
                        Dropdown.Value = Selected and Entry.Value or nil
                    end

                    for _, OtherRow in Pool do
                        OtherRow:UpdateButton()
                    end
                end

                Row:UpdateButton()
                Dropdown:Display()

                Library:UpdateDependencyBoxes()
                Dropdown:RunChanged()
            end)

            Button.MouseEnter:Connect(function()
                local Entry = Row.Entry
                if not Entry or Entry.IsDisabled then
                    return
                end

                if Row.Selected then
                    return
                end

                TweenService:Create(Container, Library.TweenInfo, {
                    BackgroundTransparency = 0.85,
                }):Play()
                TweenService:Create(Button, Library.TweenInfo, {
                    TextTransparency = 0.25,
                }):Play()

                if Image then
                    TweenService:Create(Image, Library.TweenInfo, {
                        ImageTransparency = 0.25,
                    }):Play()
                end
            end)

            Button.MouseLeave:Connect(function()
                local Entry = Row.Entry
                if not Entry or Entry.IsDisabled then
                    return
                end

                if Row.Selected then
                    return
                end

                TweenService:Create(Container, Library.TweenInfo, {
                    BackgroundTransparency = 1,
                }):Play()
                TweenService:Create(Button, Library.TweenInfo, {
                    TextTransparency = 0.5,
                }):Play()

                if Image then
                    TweenService:Create(Image, Library.TweenInfo, {
                        ImageTransparency = 0.5,
                    }):Play()
                end
            end)

            Button.InputBegan:Connect(function(StartInput)
                if not (Info.Multi and Dropdown.DragSelect and not Library.IsMobile) then
                    return
                end

                local Entry = Row.Entry
                if not Entry or Entry.IsDisabled then
                    return
                end

                if not IsMouseInput(StartInput) then
                    return
                end

                DragSelecting = true
                DragStartIndex = Row.Index
                table.clear(DragInitialValues)

                for _, FilteredEntry in FilteredEntries do
                    DragInitialValues[FilteredEntry.Value] = Dropdown.Value[FilteredEntry.Value]
                end

                UpdateDrag(Row.Index)

                if DragInputEndedConn then DragInputEndedConn:Disconnect() end
                if DragInputChangedConn then DragInputChangedConn:Disconnect() end

                DragInputChangedConn = Library:GiveSignal(UserInputService.InputChanged:Connect(function(ChangeInput)
                    if not IsMovementInput(ChangeInput) and ChangeInput ~= StartInput then
                        return
                    end

                    local Pos = ChangeInput.Position
                    for _, OtherRow in Pool do
                        if OtherRow.Entry and Library:MouseIsOverFrame(OtherRow.Button, Pos) then
                            UpdateDrag(OtherRow.Index)
                            break
                        end
                    end
                end))

                DragInputEndedConn = Library:GiveSignal(UserInputService.InputEnded:Connect(function(EndInput)
                    if EndInput ~= StartInput and not (IsMouseInput(EndInput) and EndInput.UserInputType == StartInput.UserInputType) then
                        return
                    end

                    Dropdown:Display()
                    Library:UpdateDependencyBoxes()
                    Dropdown:RunChanged()

                    StopDragSelect()
                end))

                table.insert(Dropdown.Connections, DragInputEndedConn)
                table.insert(Dropdown.Connections, DragInputChangedConn)
            end)

            return Row
        end

        function Dropdown:BuildDropdownList()
            StopDragSelect()

            RecomputeFilteredEntries()

            MenuTable.Menu.CanvasPosition = Vector2.new(0, 0)

            Dropdown:RefreshPool()
            Dropdown:RecalculateListSize(#FilteredEntries)
        end

        for _ = 1, PoolSize do
            table.insert(Pool, CreatePoolRow())
        end

        --// Inline "Select All" / "Deselect All" row, pinned at the top of the
        --// canvas so it scrolls with the values. Created once and reused.
        if UseSelectAll then
            local SelectAllRow = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, ItemHeight),
                Parent = MenuTable.Menu,
            })
            Library:MakeLine(SelectAllRow, {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 1),
            })

            local function MakeBulkButton(Text, Offset, State)
                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(Offset, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Text = Text,
                    TextSize = 14,
                    TextTransparency = 0.5,
                    Parent = SelectAllRow,
                })

                Button.MouseEnter:Connect(function()
                    TweenService:Create(Button, Library.TweenInfo, { TextTransparency = 0 }):Play()
                end)
                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, Library.TweenInfo, { TextTransparency = 0.5 }):Play()
                end)
                Button.MouseButton1Click:Connect(function()
                    ApplyBulkSelection(State, SearchBox and SearchBox.Text:lower() or nil)
                end)
            end

            MakeBulkButton("Select All", 0, true)
            MakeBulkButton("Deselect All", 0.5, false)
        end

        table.insert(Dropdown.Connections, MenuTable.Menu:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            Dropdown:RefreshPool()
        end))

        local function ValueExists(Val)
            if IsSequentialArray(Dropdown.Values) then
                for _, Existing in Dropdown.Values do
                    if Existing == Val then
                        return true
                    end
                end

                return false
            end

            return Dropdown.Values[Val] ~= nil
        end

        function Dropdown:SetValue(Value)
            if Info.Multi then
                local Table = {}

                for Val, Active in Value or {} do
                    if typeof(Active) ~= "boolean" then
                        Table[Active] = true
                    elseif Active and ValueExists(Val) then
                        Table[Val] = true
                    end
                end

                Dropdown.Value = Table
            else
                if ValueExists(Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end

            Dropdown:Display()
            for _, Row in Pool do
                Row:UpdateButton()
            end

            if not Dropdown.Disabled then
                Library:UpdateDependencyBoxes()
                Dropdown:RunChanged()
            end
        end

        function Dropdown:SetValues(Values)
            Dropdown.Values = Values

            local Changed = false
            if Info.Multi then
                for Val in Dropdown.Value do
                    if not ValueExists(Val) then
                        Dropdown.Value[Val] = nil
                        Changed = true
                    end
                end

            elseif Dropdown.Value ~= nil and not ValueExists(Dropdown.Value) then
                Dropdown.Value = nil
                Changed = true
            end

            Dropdown:BuildDropdownList()
            Dropdown:Display()

            if Changed and not Dropdown.Disabled then
                Library:UpdateDependencyBoxes()
                Dropdown:RunChanged()
            end
        end

        function Dropdown:AddValues(Values)
            if typeof(Values) ~= "table" and typeof(Values) ~= "string" then
                return
            end

            local IsDictionary = not IsSequentialArray(Dropdown.Values)
            if IsDictionary then
                if typeof(Values) == "string" then
                    Dropdown.Values[Values] = Values

                elseif IsSequentialArray(Values) then
                    for _, Val in Values do
                        Dropdown.Values[Val] = Val
                    end

                else
                    for Key, Val in Values do
                        Dropdown.Values[Key] = Val
                    end
                end
            else
                if typeof(Values) == "table" then
                    for _, Val in Values do
                        table.insert(Dropdown.Values, Val)
                    end
                else
                    table.insert(Dropdown.Values, Values)
                end
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabledValues(DisabledValues)
            Dropdown.DisabledValues = DisabledValues
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in DisabledValues do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetValueImages(ValueImages)
            if typeof(ValueImages) ~= "table" then
                return
            end

            Dropdown.ValueImages = ValueImages
            Dropdown:BuildDropdownList()
        end

        function Dropdown:AddValueImages(ValueImages)
            if typeof(ValueImages) ~= "table" then
                return
            end

            for key, val in ValueImages do
                Dropdown.ValueImages[key] = val
            end

            Dropdown:BuildDropdownList()
        end

        function Dropdown:SetDisabled(Disabled: boolean)
            Dropdown.Disabled = Disabled

            if Dropdown.TooltipTable then
                Dropdown.TooltipTable.Disabled = Dropdown.Disabled
            end

            MenuTable:Close()
            if Dropdown.Disabled then
                Dropdown:Collapse()
            end

            DisplayButton.Active = not Dropdown.Disabled
            Dropdown:UpdateColors()
        end

        function Dropdown:SetVisible(Visible: boolean)
            Dropdown.Visible = Visible

            Holder.Visible = Dropdown.Visible
            Groupbox:Resize()
        end

        function Dropdown:SetText(Text: string)
            Dropdown.Text = Text
            Holder.Size = UDim2.new(1, 0, 0, Text and 39 or 21)

            Label.Text = Text and Text or ""
            Label.Visible = not not Text
        end

        function Dropdown:SetDragSelect(Value: boolean)
            if not Info.Multi or Library.IsMobile then
                Value = false
            end

            Dropdown.DragSelect = Value == true
            Dropdown:BuildDropdownList()
        end

        --// Expanded Panel \\--
        local ExpandOverlay
        local ExpandFrame
        local ExpandScale
        local ExpandList
        local ExpandGrid
        local ExpandSearchBox
        local ExpandEmptyLabel

        local function BuildExpandedPanel()
            if ExpandOverlay then
                return
            end

            local Parent = Library.MainFrame
            if not Parent then
                return
            end

            ExpandOverlay = New("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = "DarkColor",
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Visible = false,
                ZIndex = 8000,
                Parent = Parent,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = ExpandOverlay,
                })
            )

            --// A TextButton so clicks on the panel do not fall through and close it
            ExpandFrame = New("TextButton", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(0.7, 0, 0.72, 0),
                Text = "",
                ZIndex = 8001,
                Parent = ExpandOverlay,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = ExpandFrame,
                })
            )
            Library:AddOutline(ExpandFrame)

            ExpandScale = New("UIScale", {
                Scale = 1,
                Parent = ExpandFrame,
            })

            --// Header \\--
            local Header = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 34),
                Parent = ExpandFrame,
            })
            Library:MakeLine(Header, {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 1),
            })

            New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -56, 1, 0),
                Text = Dropdown.Text or "Select a value",
                TextSize = 15,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Header,
            })

            local CloseIcon = Library:GetIcon("x")
            local CloseButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(22, 22),
                Text = "",
                Parent = Header,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = CloseButton,
                })
            )
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = CloseButton,
            })
            New("ImageLabel", {
                Image = CloseIcon and CloseIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = CloseIcon and CloseIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CloseIcon and CloseIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 0.4,
                ScaleType = Enum.ScaleType.Fit,
                Size = UDim2.fromScale(1, 1),
                Parent = CloseButton,
            })

            CloseButton.MouseEnter:Connect(function()
                TweenService:Create(CloseButton, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
            end)
            CloseButton.MouseLeave:Connect(function()
                TweenService:Create(CloseButton, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            end)
            CloseButton.MouseButton1Click:Connect(function()
                Dropdown:Collapse()
            end)

            --// Search \\--
            local ListTop = 34
            if Info.Searchable then
                ListTop = 34 + 38

                ExpandSearchBox = New("TextBox", {
                    BackgroundColor3 = "MainColor",
                    PlaceholderText = "Search...",
                    Position = UDim2.fromOffset(10, 42),
                    Size = UDim2.new(1, -20, 0, 26),
                    Text = "",
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ExpandFrame,
                })
                table.insert(
                    Library.PillCorners,
                    New("UICorner", {
                        CornerRadius = Library.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0),
                        Parent = ExpandSearchBox,
                    })
                )
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 32),
                    PaddingRight = UDim.new(0, 12),
                    Parent = ExpandSearchBox,
                })
                New("UIStroke", {
                    Color = "OutlineColor",
                    Parent = ExpandSearchBox,
                })

                local SearchIcon = Library:GetIcon("search")
                New("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Image = SearchIcon and SearchIcon.Url or "",
                    ImageColor3 = "FontColor",
                    ImageRectOffset = SearchIcon and SearchIcon.ImageRectOffset or Vector2.zero,
                    ImageRectSize = SearchIcon and SearchIcon.ImageRectSize or Vector2.zero,
                    ImageTransparency = 0.4,
                    Position = UDim2.new(0, -22, 0.5, 0),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(15, 15),
                    Parent = ExpandSearchBox,
                })

                table.insert(
                    Dropdown.Connections,
                    ExpandSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        RebuildExpandedList()
                    end)
                )
            end

            --// Values \\--
            ExpandList = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                Position = UDim2.fromOffset(0, ListTop),
                ScrollBarImageColor3 = "OutlineColor",
                ScrollBarThickness = 2,
                Size = UDim2.new(1, 0, 1, -ListTop),
                Parent = ExpandFrame,
            })
            ExpandGrid = New("UIGridLayout", {
                CellPadding = UDim2.fromOffset(6, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = ExpandList,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 10),
                Parent = ExpandList,
            })

            ExpandEmptyLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, ListTop + 14),
                Size = UDim2.new(1, 0, 0, 16),
                Text = "No matching values",
                TextSize = 14,
                TextTransparency = 0.5,
                Visible = false,
                Parent = ExpandFrame,
            })

            --// Clicking anywhere off the panel dismisses it
            ExpandOverlay.MouseButton1Click:Connect(function()
                Dropdown:Collapse()
            end)
        end

        function RebuildExpandedList()
            if not ExpandList then
                return
            end

            for Button in ExpandedButtons do
                if Button and Button.Parent then
                    Button.Parent:Destroy()
                end
            end
            table.clear(ExpandedButtons)

            local Columns = math.max(1, Info.ExpandColumns or 2)
            local Search = ExpandSearchBox and ExpandSearchBox.Text:lower() or ""
            local Count = 0

            if UseSelectAll then
                local function MakeBulkItem(Text, Order, State)
                    local Item = New("Frame", {
                        BackgroundColor3 = "MainColor",
                        BackgroundTransparency = 1,
                        LayoutOrder = Order,
                        Parent = ExpandList,
                    })
                    table.insert(
                        Library.Corners,
                        New("UICorner", {
                            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                            Parent = Item,
                        })
                    )
                    New("UIStroke", {
                        Color = "OutlineColor",
                        Transparency = 0.5,
                        Parent = Item,
                    })

                    local Button = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromScale(1, 1),
                        Text = Text,
                        TextSize = 14,
                        TextTransparency = 0.4,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = Item,
                    })

                    Button.MouseEnter:Connect(function()
                        TweenService:Create(Item, Library.TweenInfo, { BackgroundTransparency = 0.5 }):Play()
                    end)
                    Button.MouseLeave:Connect(function()
                        TweenService:Create(Item, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
                    end)
                    Button.MouseButton1Click:Connect(function()
                        ApplyBulkSelection(State, Search)
                    end)

                    --// Tracked so a rebuild cleans it up like any other item
                    ExpandedButtons[Button] = { UpdateButton = function() end }
                end

                MakeBulkItem("Select All", -2, true)
                MakeBulkItem("Deselect All", -1, false)
            end

            for _, Value in Dropdown.Values do
                local FormattedValue = tostring(Info.FormatListValue and Info.FormatListValue(Value) or Value)
                if Search ~= "" and not TryFuzzyMatch(FormattedValue, Search) then
                    continue
                end

                Count += 1

                local IsDisabled = table.find(Dropdown.DisabledValues, Value)
                local ValueImage = GetValueImage(Value)
                local Table = {}

                local Item = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 1,
                    LayoutOrder = IsDisabled and 1 or 0,
                    Parent = ExpandList,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                        Parent = Item,
                    })
                )
                local ItemStroke = New("UIStroke", {
                    Color = "OutlineColor",
                    Transparency = 0.5,
                    Parent = Item,
                })

                local Image = ValueImage
                    and New("ImageLabel", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        BackgroundTransparency = 1,
                        Image = ValueImage.Url,
                        ImageRectOffset = ValueImage.ImageRectOffset,
                        ImageRectSize = ValueImage.ImageRectSize,
                        ImageTransparency = 0.5,
                        Position = UDim2.new(0, 8, 0.5, 0),
                        Size = UDim2.fromOffset(18, 18),
                        Parent = Item,
                    })

                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Position = ValueImage and UDim2.fromOffset(30, 0) or UDim2.fromOffset(0, 0),
                    Size = ValueImage and UDim2.new(1, -30, 1, 0) or UDim2.fromScale(1, 1),
                    Text = FormattedValue,
                    TextSize = 14,
                    TextTransparency = 0.5,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = Item,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, ValueImage and 0 or 10),
                    PaddingRight = UDim.new(0, 10),
                    Parent = Button,
                })

                function Table:UpdateButton()
                    local Selected = IsValueSelected(Value)

                    Item.BackgroundTransparency = Selected and 0 or 1
                    ItemStroke.Transparency = Selected and 0.2 or 0.7
                    Button.TextTransparency = IsDisabled and 0.8 or Selected and 0 or 0.4

                    if Image then
                        Image.ImageTransparency = IsDisabled and 0.8 or Selected and 0 or 0.4
                    end
                end

                Table.Value = Value

                if not IsDisabled then
                    Button.MouseEnter:Connect(function()
                        if IsValueSelected(Value) then
                            return
                        end

                        TweenService:Create(Item, Library.TweenInfo, { BackgroundTransparency = 0.5 }):Play()
                    end)
                    Button.MouseLeave:Connect(function()
                        if IsValueSelected(Value) then
                            return
                        end

                        TweenService:Create(Item, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
                    end)
                    Button.MouseButton1Click:Connect(function()
                        ToggleValue(Value)

                        --// Picking one value is the whole job of a single select
                        if not Info.Multi then
                            Dropdown:Collapse()
                        end
                    end)
                end

                Table:UpdateButton()
                ExpandedButtons[Button] = Table
            end

            --// Scale based so the columns stay exact at any window size: each cell
            --// gives up its share of the padding between them
            ExpandGrid.CellSize = UDim2.new(1 / Columns, -6 * (Columns - 1) / Columns, 0, 28)

            ExpandEmptyLabel.Visible = Count == 0
        end

        --// Tracked rather than read off Visible, which stays true while fading out
        local Expanded = false
        local ExpandFadeTween
        local ExpandScaleTween

        local function StopExpandTweens()
            if ExpandFadeTween then
                StopTween(ExpandFadeTween, true)
                ExpandFadeTween = nil
            end
            if ExpandScaleTween then
                StopTween(ExpandScaleTween, true)
                ExpandScaleTween = nil
            end
        end

        function Dropdown:Expand()
            if Dropdown.Disabled or Info.Expandable == false or Expanded then
                return
            end

            BuildExpandedPanel()
            if not ExpandOverlay then
                return
            end

            --// Only one panel at a time
            if Library.ActiveExpandedDropdown and Library.ActiveExpandedDropdown ~= Dropdown then
                Library.ActiveExpandedDropdown:Collapse()
            end

            MenuTable:Close()

            if ExpandSearchBox then
                ExpandSearchBox.Text = ""
            end

            Expanded = true
            Library.ActiveExpandedDropdown = Dropdown

            RebuildExpandedList()

            StopExpandTweens()
            ExpandOverlay.BackgroundTransparency = 1
            ExpandScale.Scale = 0.94
            ExpandOverlay.Visible = true

            ExpandFadeTween = TweenService:Create(ExpandOverlay, DROPDOWN_EXPAND_TWEEN, {
                BackgroundTransparency = 0.5,
            })
            ExpandScaleTween = TweenService:Create(ExpandScale, DROPDOWN_EXPAND_TWEEN, {
                Scale = 1,
            })

            ExpandFadeTween:Play()
            ExpandScaleTween:Play()
        end

        function Dropdown:Collapse()
            if not Expanded or not ExpandOverlay then
                return
            end

            Expanded = false
            if Library.ActiveExpandedDropdown == Dropdown then
                Library.ActiveExpandedDropdown = nil
            end

            StopExpandTweens()

            ExpandFadeTween = TweenService:Create(ExpandOverlay, DROPDOWN_EXPAND_TWEEN, {
                BackgroundTransparency = 1,
            })
            ExpandScaleTween = TweenService:Create(ExpandScale, DROPDOWN_EXPAND_TWEEN, {
                Scale = 0.96,
            })

            ExpandFadeTween.Completed:Once(function(State)
                --// Cancelled means Expand took over mid fade
                if State == Enum.PlaybackState.Cancelled or Expanded then
                    return
                end

                ExpandOverlay.Visible = false
            end)

            ExpandFadeTween:Play()
            ExpandScaleTween:Play()
        end

        function Dropdown:IsExpanded()
            return Expanded
        end

        function Dropdown:ToggleExpanded()
            if Dropdown:IsExpanded() then
                Dropdown:Collapse()
            else
                Dropdown:Expand()
            end
        end

        local ToggleDropdown = function()
            if Dropdown.Disabled then
                return
            end

            MenuTable:Toggle()
        end

        table.insert(Dropdown.Connections, DisplayContainer.MouseButton1Click:Connect(ToggleDropdown))
        table.insert(Dropdown.Connections, DisplayButton.MouseButton1Click:Connect(ToggleDropdown))

        if ExpandButton then
            table.insert(
                Dropdown.Connections,
                ExpandButton.MouseButton1Click:Connect(function()
                    Dropdown:ToggleExpanded()
                end)
            )
        end

        if SearchBox then
            table.insert(Dropdown.Connections, SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                Dropdown:BuildDropdownList()
            end))
        end

        local Defaults = (function()
            local Resolved = {}
            local Default = Info.Default
            if Default == nil then
                return Resolved
            end

            local IsDictionary = not IsSequentialArray(Dropdown.Values)
            local function ResolveOne(Candidate)
                if IsDictionary then
                    return Dropdown.Values[Candidate] ~= nil and Candidate or nil
                end

                for _, Existing in Dropdown.Values do
                    if Existing == Candidate then
                        return Existing
                    end
                end

                return nil
            end

            local DefaultType = typeof(Default)
            if DefaultType == "string" then
                local Value = ResolveOne(Default)
                if Value ~= nil then
                    table.insert(Resolved, Value)
                end

            elseif DefaultType == "table" then
                for _, Candidate in Default do
                    local Value = ResolveOne(Candidate)
                    if Value ~= nil then
                        table.insert(Resolved, Value)
                    end
                end

            elseif Dropdown.Values[Default] ~= nil then
                table.insert(Resolved, IsDictionary and Default or Dropdown.Values[Default])
            end

            return Resolved
        end)()

        for _, SelectValue in Defaults do
            if Info.Multi then
                Dropdown.Value[SelectValue] = true
            else
                Dropdown.Value = SelectValue
                break
            end
        end

        if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
            Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, DisplayContainer)
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end

        Dropdown:UpdateColors()
        Dropdown:Display()
        Dropdown:BuildDropdownList()
        Groupbox:Resize()

        Dropdown.Holder = Holder
        table.insert(Groupbox.Elements, Dropdown)

        Dropdown.Default = Defaults
        Dropdown.DefaultValues = Dropdown.Values

        Options[Idx] = Dropdown

        function Dropdown:Destroy()
            Dropdown.Destroyed = true

            StopDragSelect()

            if Dropdown.Connections then
                for _, Connection in Dropdown.Connections do
                    Connection:Disconnect()
                end
            end

            if Dropdown.TooltipTable then
                Dropdown.TooltipTable:Destroy()
            end

            if MenuTable then
                MenuTable:Destroy()
            end

            if Holder then
                Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Dropdown)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Dropdown
    end

    --// A dropdown you don't select in — you drag values above and below each
    --// other to set their priority. The opened panel is a re-orderable list;
    --// Value is the ordered array (highest priority first). Searchable too.
    function Funcs:AddPriorityDropdown(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.PriorityDropdown)

        local Groupbox = self
        local Container = Groupbox.Container

        local Priority = {
            Connections = {},
            Destroyed = false,

            Text = typeof(Info.Text) == "string" and Info.Text or nil,

            --// Ordered array, highest priority first
            Value = {},
            Values = Info.Values,

            FormatDisplayValue = Info.FormatDisplayValue,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "PriorityDropdown",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Priority.Text and 39 or 21),
            Visible = Priority.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Priority.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not not Info.Text,
            ZIndex = 3,
            Parent = Holder,
        })

        local DisplayContainer = New("TextButton", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = "",
            TextTransparency = 1,
            ZIndex = 2,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 4),
            Parent = DisplayContainer,
        })

        local DisplayStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = DisplayContainer,
        })

        local DropdownCorner = New("UICorner", {
            TopLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            TopRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomRightRadius = UDim.new(0, Library.CornerRadius / 2),
            BottomLeftRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = DisplayContainer,
        }); table.insert(Library.SpecificCorners, DropdownCorner)

        local DisplayButton = New("TextButton", {
            Active = not Priority.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 21),
            Text = "---",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
            Parent = DisplayContainer,
        })

        local ArrowImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            ImageColor3 = "FontColor",
            ImageTransparency = 0.5,
            Position = UDim2.fromScale(1, 0.5),
            Size = UDim2.fromOffset(16, 16),
            Parent = DisplayContainer,
        })
        if ArrowIcon then
            Library:ApplyLucideIcon(ArrowImage, ArrowIcon)
        end

        --// Opens the whole list in a panel over the window for easier ranking
        local ExpandButton
        local ExpandIconImage
        if Info.Expandable ~= false then
            local ExpandIcon = Library:GetIcon("maximize-2")

            ExpandButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -18, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Text = "",
                ZIndex = 3,
                Parent = DisplayContainer,
            })
            ExpandIconImage = New("ImageLabel", {
                Image = ExpandIcon and ExpandIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = ExpandIcon and ExpandIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = ExpandIcon and ExpandIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 0.5,
                ScaleType = Enum.ScaleType.Fit,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 3,
                Parent = ExpandButton,
            })

            ExpandButton.MouseEnter:Connect(function()
                if Priority.Disabled then return end
                TweenService:Create(ExpandIconImage, Library.TweenInfo, { ImageTransparency = 0 }):Play()
            end)
            ExpandButton.MouseLeave:Connect(function()
                if Priority.Disabled then return end
                TweenService:Create(ExpandIconImage, Library.TweenInfo, { ImageTransparency = 0.5 }):Play()
            end)

            Library:AddTooltip("Expand", nil, ExpandButton)
        end

        local SearchBox
        if Info.Searchable then
            SearchBox = New("TextBox", {
                BackgroundTransparency = 1,
                PlaceholderText = "Search...",
                Position = UDim2.fromOffset(-8, 0),
                Size = UDim2.new(1, ExpandButton and -34 or -12, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = false,
                Parent = DisplayButton,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                Parent = SearchBox,
            })

            table.insert(Priority.Connections, SearchBox.Focused:Connect(function()
                Library.Registry[DisplayStroke].Color = "AccentColor"
                TweenService:Create(DisplayStroke, Library.TweenInfo, {
                    Color = Library.Scheme.AccentColor,
                }):Play()
            end))

            table.insert(Priority.Connections, SearchBox.FocusLost:Connect(function()
                Library.Registry[DisplayStroke].Color = "OutlineColor"
                TweenService:Create(DisplayStroke, Library.TweenInfo, {
                    Color = Library.Scheme.OutlineColor,
                }):Play()
            end))
        end

        local ItemHeight = 24

        local MenuTable
        MenuTable = Library:AddContextMenu(
            DisplayContainer,
            function()
                return UDim2.fromOffset((DisplayContainer.AbsoluteSize.X / Library.DPIScale), 0)
            end,
            function()
                return { 0.5, DisplayContainer.AbsoluteSize.Y + 1.5 }
            end,
            2,
            function(Active: boolean)
                DisplayButton.TextTransparency = (Active and SearchBox) and 1 or 0

                ArrowImage.ImageTransparency = Active and 0 or 0.5
                ArrowImage.Rotation = Active and 180 or 0

                if SearchBox then
                    SearchBox.Text = ""
                    SearchBox.Visible = Active
                end

                local Half = UDim.new(0, Library.CornerRadius / 2)
                local Zero = UDim.new(0, 0)

                DropdownCorner.BottomRightRadius = Active and Zero or Half
                DropdownCorner.BottomLeftRadius = Active and Zero or Half

                local MenuCorner = MenuTable and MenuTable.Corner
                if MenuCorner then
                    MenuCorner.TopLeftRadius = Zero
                    MenuCorner.TopRightRadius = Zero
                    MenuCorner.BottomRightRadius = Half
                    MenuCorner.BottomLeftRadius = Half
                end
            end,
            false,
            "bottom",
            "Dropdown"
        )
        Priority.Menu = MenuTable

        local GripIcon = Library:GetIcon("grip-vertical") or Library:GetIcon("menu")
        local RowByValue = {}
        local RowList = {}

        local function FormatValue(Value)
            return tostring(Info.FormatDisplayValue and Info.FormatDisplayValue(Value) or Value)
        end

        function Priority:RunChanged()
            Library:SafeCallback(Priority.Callback, Priority.Value)
            Library:SafeCallback(Priority.Changed, Priority.Value)
        end

        function Priority:GetValue()
            local Copy = {}
            for _, Value in Priority.Value do
                table.insert(Copy, Value)
            end
            return Copy
        end

        function Priority:Display()
            if Library.Unloaded then
                return
            end

            local Top = Priority.Value[1]
            local Str = Top ~= nil and FormatValue(Top) or ""

            if Str ~= "" and #Priority.Value > 1 then
                Str = Str .. string.format("  (+%d)", #Priority.Value - 1)
            end

            if #Str > 25 then
                Str = Str:sub(1, 22) .. "..."
            end

            DisplayButton.Text = (Str == "" and "---" or Str)
        end

        function Priority:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Priority.Disabled and 0.8 or 0
            DisplayButton.TextTransparency = Priority.Disabled and 0.8 or 0
            ArrowImage.ImageTransparency = Priority.Disabled and 0.8 or MenuTable.Active and 0 or 0.5

            if ExpandIconImage then
                ExpandIconImage.ImageTransparency = Priority.Disabled and 0.8 or 0.5
            end
        end

        function Priority:RecalculateListSize(Count)
            local ItemCount = Count or #Priority.Value
            local Y = math.clamp(ItemCount * ItemHeight, 0, Info.MaxVisibleDropdownItems * ItemHeight)

            MenuTable.Menu.CanvasSize = UDim2.fromOffset(0, ItemCount * ItemHeight)
            MenuTable:SetSize(function()
                return UDim2.fromOffset((DisplayContainer.AbsoluteSize.X / Library.DPIScale), Y)
            end)
        end

        local Dragging = false
        local DragValue = nil
        local DragConns = {}

        local function StopDrag()
            Dragging = false
            DragValue = nil

            for _, Conn in DragConns do
                Conn:Disconnect()
            end
            table.clear(DragConns)
        end

        --// Lay out every visible row by a running counter so a search filter
        --// packs the matches together; the number badge still shows the real
        --// priority. Pass a value to leave alone (the row being dragged).
        local function Relayout(SkipValue, Animate)
            local Search = (not Dragging) and SearchBox and NormalizeSearch(SearchBox.Text:lower()) or ""
            local Searching = Search ~= ""
            local VisibleCount = 0

            for Index, Value in Priority.Value do
                local Row = RowByValue[Value]
                if not Row then
                    continue
                end

                local Match = true
                if Searching then
                    Match = FuzzyScore(FormatValue(Value):lower(), Search)
                end

                Row.Index = Index
                Row.NumberLabel.Text = tostring(Index)
                Row.Container.Visible = Match
                Row.Button.Active = not Searching and not Priority.Disabled

                if not Match then
                    continue
                end

                VisibleCount += 1

                if Value ~= SkipValue then
                    local Target = UDim2.fromOffset(0, (VisibleCount - 1) * ItemHeight)
                    if Animate then
                        TweenService:Create(Row.Container, Library.TweenInfo, { Position = Target }):Play()
                    else
                        Row.Container.Position = Target
                    end
                end
            end

            Priority:RecalculateListSize(VisibleCount)
        end

        --// Shared drag-to-reorder core. `View` wires it to whichever list is on
        --// screen (the inline menu or the expanded panel): both mutate the same
        --// Priority.Value, so a drag in one is a drag in the other. Works with
        --// mouse or touch, follows the pointer, clamps to the canvas, and
        --// auto-scrolls when the pointer nears an edge.
        local function BeginDrag(View, StartInput, Value)
            if Priority.Disabled or Dragging or View.Searching() then
                return
            end
            if not IsMouseInput(StartInput) then
                return
            end

            local Row = View.RowByValue[Value]
            if not Row then
                return
            end

            Dragging = true
            DragValue = Value

            local Scroll = View.Scroll
            local ItemH = View.ItemH
            local Container = Row.Container
            local DPI = Library.DPIScale

            --// Lift the grabbed row above its siblings (ZIndex is Siblings mode,
            --// so its children need bumping too). Restored on release.
            local ZBump = {}
            local function Bump(Obj)
                ZBump[Obj] = Obj.ZIndex
                Obj.ZIndex = Obj.ZIndex + 60
            end
            Bump(Container)
            for _, D in ipairs(Container:GetDescendants()) do
                if D:IsA("GuiObject") then
                    Bump(D)
                end
            end
            TweenService:Create(Container, Library.TweenInfo, { BackgroundTransparency = 0.6 }):Play()

            --// Where inside the row the pointer grabbed it (real pixels)
            local GrabOffsetPx = StartInput.Position.Y - Container.AbsolutePosition.Y
            local PointerY = StartInput.Position.Y

            local function Update()
                local Top = Scroll.AbsolutePosition.Y
                --// Map the pointer into canvas space, honouring the scroll offset
                local VisY = ((PointerY - Top) + Scroll.CanvasPosition.Y - GrabOffsetPx) / DPI
                VisY = math.clamp(VisY, 0, math.max(0, (#Priority.Value - 1) * ItemH))
                Container.Position = UDim2.fromOffset(0, VisY)

                local Target = math.clamp(math.floor(VisY / ItemH + 0.5) + 1, 1, #Priority.Value)
                local Current = table.find(Priority.Value, DragValue)
                if Current and Current ~= Target then
                    table.remove(Priority.Value, Current)
                    table.insert(Priority.Value, Target, DragValue)
                    View.Relayout(DragValue, true)
                end
            end

            --// Keep the pointer inside the visible window by scrolling the canvas
            local function AutoScroll()
                local WindowH = Scroll.AbsoluteSize.Y
                local CanvasH = Scroll.AbsoluteCanvasSize.Y
                if CanvasH <= WindowH then
                    return
                end

                local Top = Scroll.AbsolutePosition.Y
                local Edge = 26 * DPI
                local Speed = 9 * DPI
                local Delta = 0

                if PointerY < Top + Edge then
                    Delta = -Speed
                elseif PointerY > Top + WindowH - Edge then
                    Delta = Speed
                end

                if Delta ~= 0 then
                    local NewY = math.clamp(Scroll.CanvasPosition.Y + Delta, 0, CanvasH - WindowH)
                    Scroll.CanvasPosition = Vector2.new(0, NewY)
                end
            end

            Update()

            table.insert(DragConns, Library:GiveSignal(UserInputService.InputChanged:Connect(function(ChangeInput)
                if not IsMovementInput(ChangeInput) and ChangeInput ~= StartInput then
                    return
                end
                PointerY = ChangeInput.Position.Y
            end)))

            --// A steady heartbeat drives edge scrolling even while the pointer
            --// is held still at the boundary
            table.insert(DragConns, Library:GiveSignal(RunService.RenderStepped:Connect(function()
                AutoScroll()
                Update()
            end)))

            table.insert(DragConns, Library:GiveSignal(UserInputService.InputEnded:Connect(function(EndInput)
                if EndInput ~= StartInput and not (IsMouseInput(EndInput) and EndInput.UserInputType == StartInput.UserInputType) then
                    return
                end

                for Obj, Z in ZBump do
                    Obj.ZIndex = Z
                end
                TweenService:Create(Container, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()

                StopDrag()
                View.Relayout(nil, true)
                Priority:Display()
                Priority:RunChanged()
            end)))
        end

        local InlineView = {
            RowByValue = RowByValue,
            Scroll = MenuTable.Menu,
            ItemH = ItemHeight,
            Relayout = Relayout,
            Searching = function()
                return SearchBox ~= nil and NormalizeSearch(SearchBox.Text:lower()) ~= ""
            end,
        }

        local function CreateRow(Value)
            local Row = { Value = Value, Index = 0 }

            local Container = New("Frame", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, ItemHeight),
                Parent = MenuTable.Menu,
            })

            --// The whole row is the drag surface (grab it anywhere). Sits behind
            --// the labels, which are plain TextLabels and never steal the input.
            local Button = New("TextButton", {
                Active = true,
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Parent = Container,
            })

            local GripImage = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageColor3 = "FontColor",
                ImageTransparency = 0.6,
                Position = UDim2.new(0, 12, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                Parent = Container,
            })
            if GripIcon then
                Library:ApplyLucideIcon(GripImage, GripIcon)
            else
                GripImage.Visible = false
            end

            local NumberLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(24, 0),
                Size = UDim2.fromOffset(20, ItemHeight),
                Text = "1",
                TextSize = 13,
                TextTransparency = 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Container,
            })

            local ValueLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(46, 0),
                Size = UDim2.new(1, -52, 0, ItemHeight),
                Text = FormatValue(Value),
                TextSize = 14,
                TextTransparency = 0.35,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Container,
            })

            Row.Container = Container
            Row.Button = Button
            Row.GripImage = GripImage
            Row.NumberLabel = NumberLabel
            Row.ValueLabel = ValueLabel

            Button.MouseEnter:Connect(function()
                if not Button.Active or (Dragging and DragValue == Row.Value) then return end
                TweenService:Create(GripImage, Library.TweenInfo, { ImageTransparency = 0.1 }):Play()
                TweenService:Create(Container, Library.TweenInfo, { BackgroundTransparency = 0.9 }):Play()
            end)
            Button.MouseLeave:Connect(function()
                if Dragging and DragValue == Row.Value then return end
                TweenService:Create(GripImage, Library.TweenInfo, { ImageTransparency = 0.6 }):Play()
                TweenService:Create(Container, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            end)

            Button.InputBegan:Connect(function(StartInput)
                BeginDrag(InlineView, StartInput, Row.Value)
            end)

            RowByValue[Value] = Row
            table.insert(RowList, Row)
            return Row
        end

        local function ClearRows()
            StopDrag()
            for _, Row in RowList do
                Row.Container:Destroy()
            end
            table.clear(RowList)
            table.clear(RowByValue)
        end

        function Priority:BuildList()
            ClearRows()

            for _, Value in Priority.Value do
                CreateRow(Value)
            end

            MenuTable.Menu.CanvasPosition = Vector2.new(0, 0)
            Relayout(nil, false)

            if Priority._RefreshExpanded then
                Priority._RefreshExpanded()
            end
        end

        --// Expanded Panel — the same ranked list in a big overlay for easier
        --// management (taller rows, easy to drag on mobile). Same Priority.Value
        --// underneath, so the inline menu and the panel are always in sync.
        local ExpandItemHeight = 34
        local ExpandRowByValue = {}
        local ExpandRowList = {}

        local ExpandOverlay
        local ExpandFrame
        local ExpandScale
        local ExpandList
        local ExpandSearchBox
        local ExpandEmptyLabel
        local Expanded = false
        local ExpandFadeTween, ExpandScaleTween

        local function RelayoutExpand(SkipValue, Animate)
            if not ExpandList then
                return
            end

            local Search = (not Dragging) and ExpandSearchBox and NormalizeSearch(ExpandSearchBox.Text:lower()) or ""
            local Searching = Search ~= ""
            local VisibleCount = 0

            for Index, Value in Priority.Value do
                local Row = ExpandRowByValue[Value]
                if not Row then
                    continue
                end

                local Match = true
                if Searching then
                    Match = FuzzyScore(FormatValue(Value):lower(), Search)
                end

                Row.Index = Index
                Row.NumberLabel.Text = tostring(Index)
                Row.Container.Visible = Match
                Row.Button.Active = not Searching and not Priority.Disabled

                if not Match then
                    continue
                end

                VisibleCount += 1

                if Value ~= SkipValue then
                    local Target = UDim2.fromOffset(0, (VisibleCount - 1) * ExpandItemHeight)
                    if Animate then
                        TweenService:Create(Row.Container, Library.TweenInfo, { Position = Target }):Play()
                    else
                        Row.Container.Position = Target
                    end
                end
            end

            ExpandList.CanvasSize = UDim2.fromOffset(0, VisibleCount * ExpandItemHeight)
            if ExpandEmptyLabel then
                ExpandEmptyLabel.Visible = VisibleCount == 0
            end
        end

        local ExpandView = {
            RowByValue = ExpandRowByValue,
            Scroll = nil, --// set once ExpandList exists
            ItemH = ExpandItemHeight,
            Relayout = RelayoutExpand,
            Searching = function()
                return ExpandSearchBox ~= nil and NormalizeSearch(ExpandSearchBox.Text:lower()) ~= ""
            end,
        }

        local function CreateExpandRow(Value)
            local Row = { Value = Value, Index = 0 }

            local Container = New("Frame", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, ExpandItemHeight - 4),
                Parent = ExpandList,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Container,
                })
            )
            local Stroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = 0.6,
                Parent = Container,
            })

            local Button = New("TextButton", {
                Active = true,
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Parent = Container,
            })

            local GripImage = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageColor3 = "FontColor",
                ImageTransparency = 0.55,
                Position = UDim2.new(0, 16, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Parent = Container,
            })
            if GripIcon then
                Library:ApplyLucideIcon(GripImage, GripIcon)
            else
                GripImage.Visible = false
            end

            local NumberLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(32, 0),
                Size = UDim2.new(0, 26, 1, 0),
                Text = "1",
                TextSize = 14,
                TextTransparency = 0.4,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Container,
            })

            local ValueLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(62, 0),
                Size = UDim2.new(1, -70, 1, 0),
                Text = FormatValue(Value),
                TextSize = 15,
                TextTransparency = 0.25,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Container,
            })

            Row.Container = Container
            Row.Button = Button
            Row.GripImage = GripImage
            Row.NumberLabel = NumberLabel
            Row.ValueLabel = ValueLabel
            Row.Stroke = Stroke

            Button.MouseEnter:Connect(function()
                if not Button.Active or (Dragging and DragValue == Row.Value) then return end
                TweenService:Create(Container, Library.TweenInfo, { BackgroundTransparency = 0.85 }):Play()
                TweenService:Create(GripImage, Library.TweenInfo, { ImageTransparency = 0.1 }):Play()
            end)
            Button.MouseLeave:Connect(function()
                if Dragging and DragValue == Row.Value then return end
                TweenService:Create(Container, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
                TweenService:Create(GripImage, Library.TweenInfo, { ImageTransparency = 0.55 }):Play()
            end)

            Button.InputBegan:Connect(function(StartInput)
                BeginDrag(ExpandView, StartInput, Row.Value)
            end)

            ExpandRowByValue[Value] = Row
            table.insert(ExpandRowList, Row)
            return Row
        end

        local function RebuildExpandedRows()
            if not ExpandList then
                return
            end

            for _, Row in ExpandRowList do
                Row.Container:Destroy()
            end
            table.clear(ExpandRowList)
            table.clear(ExpandRowByValue)

            for _, Value in Priority.Value do
                CreateExpandRow(Value)
            end

            RelayoutExpand(nil, false)
        end
        Priority._RefreshExpanded = RebuildExpandedRows

        local function BuildExpandedPanel()
            if ExpandOverlay then
                return
            end

            local Parent = Library.MainFrame
            if not Parent then
                return
            end

            ExpandOverlay = New("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = "DarkColor",
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Visible = false,
                ZIndex = 8000,
                Parent = Parent,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = ExpandOverlay,
                })
            )

            ExpandFrame = New("TextButton", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                AutoButtonColor = false,
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(0.6, 0, 0.68, 0),
                Text = "",
                ZIndex = 8001,
                Parent = ExpandOverlay,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = ExpandFrame,
                })
            )
            Library:AddOutline(ExpandFrame)

            ExpandScale = New("UIScale", { Scale = 1, Parent = ExpandFrame })

            --// Header
            local Header = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 34),
                Parent = ExpandFrame,
            })
            Library:MakeLine(Header, {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.fromScale(0, 1),
                Size = UDim2.new(1, 0, 0, 1),
            })
            New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -56, 1, 0),
                Text = (Priority.Text or "Priority") .. "  —  drag to rank",
                TextSize = 15,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Header,
            })

            local CloseIcon = Library:GetIcon("x")
            local CloseButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(24, 24),
                Text = "",
                Parent = Header,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = CloseButton,
                })
            )
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = CloseButton,
            })
            New("ImageLabel", {
                Image = CloseIcon and CloseIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = CloseIcon and CloseIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CloseIcon and CloseIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 0.4,
                ScaleType = Enum.ScaleType.Fit,
                Size = UDim2.fromScale(1, 1),
                Parent = CloseButton,
            })
            CloseButton.MouseEnter:Connect(function()
                TweenService:Create(CloseButton, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
            end)
            CloseButton.MouseLeave:Connect(function()
                TweenService:Create(CloseButton, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            end)
            CloseButton.MouseButton1Click:Connect(function()
                Priority:Collapse()
            end)

            --// Search
            local ListTop = 34
            if Info.Searchable then
                ListTop = 34 + 38

                ExpandSearchBox = New("TextBox", {
                    BackgroundColor3 = "MainColor",
                    PlaceholderText = "Search...",
                    Position = UDim2.fromOffset(10, 42),
                    Size = UDim2.new(1, -20, 0, 26),
                    Text = "",
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ExpandFrame,
                })
                table.insert(
                    Library.PillCorners,
                    New("UICorner", {
                        CornerRadius = Library.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0),
                        Parent = ExpandSearchBox,
                    })
                )
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 32),
                    PaddingRight = UDim.new(0, 12),
                    Parent = ExpandSearchBox,
                })
                New("UIStroke", { Color = "OutlineColor", Parent = ExpandSearchBox })

                local SearchIcon = Library:GetIcon("search")
                New("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    Image = SearchIcon and SearchIcon.Url or "",
                    ImageColor3 = "FontColor",
                    ImageRectOffset = SearchIcon and SearchIcon.ImageRectOffset or Vector2.zero,
                    ImageRectSize = SearchIcon and SearchIcon.ImageRectSize or Vector2.zero,
                    ImageTransparency = 0.4,
                    Position = UDim2.new(0, -22, 0.5, 0),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(15, 15),
                    Parent = ExpandSearchBox,
                })

                table.insert(
                    Priority.Connections,
                    ExpandSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        RelayoutExpand(nil, false)
                    end)
                )
            end

            ExpandList = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.None,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                Position = UDim2.fromOffset(10, ListTop),
                ScrollBarImageColor3 = "OutlineColor",
                ScrollBarThickness = 3,
                Size = UDim2.new(1, -20, 1, -ListTop - 10),
                Parent = ExpandFrame,
            })
            ExpandView.Scroll = ExpandList

            ExpandEmptyLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, ListTop + 14),
                Size = UDim2.new(1, 0, 0, 16),
                Text = "No matching values",
                TextSize = 14,
                TextTransparency = 0.5,
                Visible = false,
                Parent = ExpandFrame,
            })

            ExpandOverlay.MouseButton1Click:Connect(function()
                Priority:Collapse()
            end)
        end

        local function StopExpandTweens()
            if ExpandFadeTween then
                StopTween(ExpandFadeTween, true)
                ExpandFadeTween = nil
            end
            if ExpandScaleTween then
                StopTween(ExpandScaleTween, true)
                ExpandScaleTween = nil
            end
        end

        function Priority:Expand()
            if Priority.Disabled or Info.Expandable == false or Expanded then
                return
            end

            BuildExpandedPanel()
            if not ExpandOverlay then
                return
            end

            if Library.ActiveExpandedDropdown and Library.ActiveExpandedDropdown ~= Priority then
                Library.ActiveExpandedDropdown:Collapse()
            end

            MenuTable:Close()

            if ExpandSearchBox then
                ExpandSearchBox.Text = ""
            end

            Expanded = true
            Library.ActiveExpandedDropdown = Priority

            RebuildExpandedRows()

            StopExpandTweens()
            ExpandOverlay.BackgroundTransparency = 1
            ExpandScale.Scale = 0.94
            ExpandOverlay.Visible = true

            ExpandFadeTween = TweenService:Create(ExpandOverlay, DROPDOWN_EXPAND_TWEEN, { BackgroundTransparency = 0.5 })
            ExpandScaleTween = TweenService:Create(ExpandScale, DROPDOWN_EXPAND_TWEEN, { Scale = 1 })
            ExpandFadeTween:Play()
            ExpandScaleTween:Play()
        end

        function Priority:Collapse()
            if not Expanded or not ExpandOverlay then
                return
            end

            Expanded = false
            if Library.ActiveExpandedDropdown == Priority then
                Library.ActiveExpandedDropdown = nil
            end

            StopExpandTweens()

            ExpandFadeTween = TweenService:Create(ExpandOverlay, DROPDOWN_EXPAND_TWEEN, { BackgroundTransparency = 1 })
            ExpandScaleTween = TweenService:Create(ExpandScale, DROPDOWN_EXPAND_TWEEN, { Scale = 0.96 })

            ExpandFadeTween.Completed:Once(function(State)
                if State == Enum.PlaybackState.Cancelled or Expanded then
                    return
                end
                ExpandOverlay.Visible = false
            end)

            ExpandFadeTween:Play()
            ExpandScaleTween:Play()
        end

        function Priority:IsExpanded()
            return Expanded
        end

        function Priority:ToggleExpanded()
            if Expanded then
                Priority:Collapse()
            else
                Priority:Expand()
            end
        end

        --// Resolve the starting order: honour Default when it lists known
        --// values, then append any Values it left out so nothing is lost.
        local function ResolveOrder()
            local Order = {}
            local Seen = {}

            local function Push(Value)
                if Value == nil or Seen[Value] then
                    return
                end
                if table.find(Priority.Values, Value) then
                    Seen[Value] = true
                    table.insert(Order, Value)
                end
            end

            if typeof(Info.Default) == "table" then
                for _, Value in Info.Default do
                    Push(Value)
                end
            end
            for _, Value in Priority.Values do
                Push(Value)
            end

            return Order
        end

        function Priority:SetValue(Order)
            local Ordered = {}
            local Seen = {}

            if typeof(Order) == "table" then
                for _, Value in Order do
                    if not Seen[Value] and table.find(Priority.Values, Value) then
                        Seen[Value] = true
                        table.insert(Ordered, Value)
                    end
                end
            end

            --// Anything omitted keeps its place at the bottom
            for _, Value in Priority.Values do
                if not Seen[Value] then
                    table.insert(Ordered, Value)
                end
            end

            Priority.Value = Ordered
            Priority:BuildList()
            Priority:Display()

            if not Priority.Disabled then
                Priority:RunChanged()
            end
        end

        function Priority:SetValues(Values)
            Priority.Values = Values
            Priority:SetValue(Priority.Value)
        end

        function Priority:OnChanged(Func)
            Priority.Changed = Func
        end

        function Priority:SetDisabled(Disabled: boolean)
            Priority.Disabled = Disabled

            if Priority.TooltipTable then
                Priority.TooltipTable.Disabled = Priority.Disabled
            end

            MenuTable:Close()
            if Priority.Disabled then
                Priority:Collapse()
            end
            DisplayButton.Active = not Priority.Disabled
            Priority:UpdateColors()
            Relayout(nil, false)
            RelayoutExpand(nil, false)
        end

        function Priority:SetVisible(Visible: boolean)
            Priority.Visible = Visible
            Holder.Visible = Priority.Visible
            Groupbox:Resize()
        end

        function Priority:SetText(Text: string)
            Priority.Text = Text
            Holder.Size = UDim2.new(1, 0, 0, Text and 39 or 21)
            Label.Text = Text and Text or ""
            Label.Visible = not not Text
        end

        local ToggleDropdown = function()
            if Priority.Disabled then
                return
            end
            MenuTable:Toggle()
        end

        table.insert(Priority.Connections, DisplayContainer.MouseButton1Click:Connect(ToggleDropdown))
        table.insert(Priority.Connections, DisplayButton.MouseButton1Click:Connect(ToggleDropdown))

        if ExpandButton then
            table.insert(Priority.Connections, ExpandButton.MouseButton1Click:Connect(function()
                Priority:ToggleExpanded()
            end))
        end

        if SearchBox then
            table.insert(Priority.Connections, SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                Relayout(nil, false)
            end))
        end

        Priority.Value = ResolveOrder()

        if typeof(Priority.Tooltip) == "string" or typeof(Priority.DisabledTooltip) == "string" then
            Priority.TooltipTable = Library:AddTooltip(Priority.Tooltip, Priority.DisabledTooltip, DisplayContainer)
            Priority.TooltipTable.Disabled = Priority.Disabled
        end

        Priority:UpdateColors()
        Priority:Display()
        Priority:BuildList()
        Groupbox:Resize()

        Priority.Holder = Holder
        table.insert(Groupbox.Elements, Priority)

        Priority.Default = Priority:GetValue()
        Priority.DefaultValues = Priority.Values

        Options[Idx] = Priority

        function Priority:Destroy()
            Priority.Destroyed = true

            StopDrag()

            if Library.ActiveExpandedDropdown == Priority then
                Library.ActiveExpandedDropdown = nil
            end
            if ExpandOverlay then
                ExpandOverlay:Destroy()
            end

            if Priority.Connections then
                for _, Connection in Priority.Connections do
                    Connection:Disconnect()
                end
            end

            if Priority.TooltipTable then
                Priority.TooltipTable:Destroy()
            end

            if MenuTable then
                MenuTable:Destroy()
            end

            if Holder then
                Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Priority)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Priority
    end

    function Funcs:AddViewport(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Viewport)

        local Groupbox = self
        local Container = Groupbox.Container

        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0

        local ViewportObject = Info.Object
        if Info.Clone and typeof(Info.Object) == "Instance" then
            if Info.Object.Archivable then
                ViewportObject = ViewportObject:Clone()
            else
                Info.Object.Archivable = true
                ViewportObject = ViewportObject:Clone()
                Info.Object.Archivable = false
            end
        end

        local Viewport = {
            Connections = {},
            Destroyed = false,

            Object = ViewportObject :: PVInstance,
            Camera = if not Info.Camera then Instance.new("Camera") else Info.Camera,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelSize(model)
            if model:IsA("BasePart") then
                return model.Size
            end

            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local ModelSize = GetModelSize(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
            local CameraDistance = MaxExtent * 2
            local ModelPosition = (Viewport.Object :: PVInstance):GetPivot().Position

            Viewport.Camera.CFrame = CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = Viewport.Camera,
            Active = Viewport.Interactive,
        })

        table.insert(Viewport.Connections, ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in Groupbox.Tab.Sides do
                Side.ScrollingEnabled = false
            end
        end))

        table.insert(Viewport.Connections, ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in Groupbox.Tab.Sides do
                Side.ScrollingEnabled = true
            end
        end))

        table.insert(Viewport.Connections, ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
            end
        end))

        table.insert(Viewport.Connections, UserInputService.InputEnded:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end))

        table.insert(Viewport.Connections, UserInputService.InputChanged:Connect(function(input)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                local Position = (Viewport.Object :: PVInstance):GetPivot().Position
                local Camera = Viewport.Camera

                local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                if PitchedCFrame.UpVector.Y > 0.1 then
                    Camera.CFrame = PitchedCFrame
                end
            end
        end))

        table.insert(Viewport.Connections, ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = input.Position.Z * 2
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
            end
        end))

        table.insert(Viewport.Connections, UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if Library.Unloaded then
                return
            end

            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        ;(Viewport.Object :: PVInstance).Parent = ViewportFrame
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object then
                Viewport.Object:Destroy()
            end

            Viewport.Object = Object
            ;(Viewport.Object :: PVInstance).Parent = ViewportFrame

            Groupbox:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera()
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            Viewport.Camera = Camera
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Viewport.Holder = Holder
        table.insert(Groupbox.Elements, Viewport)

        Options[Idx] = Viewport

        function Viewport:Destroy()
            Viewport.Destroyed = true

            if Viewport.Connections then
                for _, Connection in Viewport.Connections do
                    Connection:Disconnect()
                end
            end

            if Holder then
                Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Viewport)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Viewport
    end

    function Funcs:AddImage(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Image)

        local Groupbox = self
        local Container = Groupbox.Container

        local Image = {
            Connections = {},
            Destroyed = false,

            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = Info.Height,
            ScaleType = Info.ScaleType,
            Transparency = Info.Transparency,
            BackgroundTransparency = Info.BackgroundTransparency,

            Visible = Info.Visible,
            Type = "Image",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BackgroundTransparency = Image.BackgroundTransparency,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ImageProperties = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ScaleType = Image.ScaleType,
            Parent = Box,
        }

        local Icon = Library:GetCustomIcon(Image.Image)
        assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        ImageProperties.Image = Icon.Url
        ImageProperties.ImageRectOffset = Icon.ImageRectOffset
        ImageProperties.ImageRectSize = Icon.ImageRectSize

        local ImageLabel = New("ImageLabel", ImageProperties)

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Image.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            local Icon = Library:GetCustomIcon(NewImage)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            Image.RectOffset = Icon.ImageRectOffset
            Image.RectSize = Icon.ImageRectSize

            Library:ApplyLucideIcon(ImageLabel, Icon)
            Image.Image = Icon.Url
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Image.Holder = Holder
        table.insert(Groupbox.Elements, Image)

        Options[Idx] = Image

        function Image:Destroy()
            Image.Destroyed = true

            if Holder then
                Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Image)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Image
    end

    --// Compact player card. The full-width version lives on the tab itself
    --// (Tab:AddPlayerInfo), since it spans both columns instead of sitting in a column.
    function Funcs:AddPlayerInfo(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.PlayerInfo)

        local Groupbox = self
        local PlayerInfo = CreatePlayerCard(Info, Groupbox.Container, true, PLAYER_CARD_NO_INSET, function()
            Groupbox:Resize()
        end)

        Groupbox:Resize()

        table.insert(Groupbox.Elements, PlayerInfo)
        Options[Idx] = PlayerInfo

        function PlayerInfo:Destroy()
            PlayerInfo.Destroyed = true

            for _, Connection in PlayerInfo.Connections do
                Connection:Disconnect()
            end

            if PlayerInfo.Holder then
                PlayerInfo.Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, PlayerInfo)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return PlayerInfo
    end

    function Funcs:AddVideo(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.Video)

        local Groupbox = self
        local Container = Groupbox.Container

        local Video = {
            Connections = {},
            Destroyed = false,

            Video = Info.Video,
            Looped = Info.Looped,
            Playing = Info.Playing,
            Volume = Info.Volume,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "Video",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Video.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local VideoFrameInstance = New("VideoFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Video = Video.Video,
            Looped = Video.Looped,
            Volume = Video.Volume,
            Parent = Box,
        })

        VideoFrameInstance.Playing = Video.Playing

        function Video:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Video.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Video:SetVideo(NewVideo: string)
            assert(typeof(NewVideo) == "string", "Video must be a string.")

            VideoFrameInstance.Video = NewVideo
            Video.Video = NewVideo
        end

        function Video:SetLooped(Looped: boolean)
            assert(typeof(Looped) == "boolean", "Looped must be a boolean.")

            VideoFrameInstance.Looped = Looped
            Video.Looped = Looped
        end

        function Video:SetVolume(Volume: number)
            assert(typeof(Volume) == "number", "Volume must be a number between 0 and 10.")

            VideoFrameInstance.Volume = Volume
            Video.Volume = Volume
        end

        function Video:SetPlaying(Playing: boolean)
            assert(typeof(Playing) == "boolean", "Playing must be a boolean.")

            VideoFrameInstance.Playing = Playing
            Video.Playing = Playing
        end

        function Video:Play()
            VideoFrameInstance.Playing = true
            Video.Playing = true
        end

        function Video:Pause()
            VideoFrameInstance.Playing = false
            Video.Playing = false
        end

        function Video:SetVisible(Visible: boolean)
            Video.Visible = Visible

            Holder.Visible = Video.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Video.Holder = Holder
        Video.VideoFrame = VideoFrameInstance
        table.insert(Groupbox.Elements, Video)

        Options[Idx] = Video

        function Video:Destroy()
            Video.Destroyed = true

            if Video.Connections then
                for _, Connection in Video.Connections do
                    Connection:Disconnect()
                end
            end

            if Holder then
                Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Video)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Video
    end

    function Funcs:AddUIPassthrough(Idx, Info)
        if self.Destroyed then return nil end

        Info = Library:Validate(Info, Templates.UIPassthrough)

        local Groupbox = self
        local Container = Groupbox.Container

        assert(Info.Instance, "Instance must be provided.")
        assert(
            typeof(Info.Instance) == "Instance" and Info.Instance:IsA("GuiBase2d"),
            "Instance must inherit from GuiBase2d."
        )
        assert(typeof(Info.Height) == "number" and Info.Height > 0, "Height must be a number greater than 0.")

        local Passthrough = {
            Connections = {},
            Destroyed = false,

            Instance = Info.Instance,
            Height = Info.Height,
            Visible = Info.Visible,

            Type = "UIPassthrough",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Passthrough.Visible,
            Parent = Container,
        })

        Passthrough.Instance.Parent = Holder

        Groupbox:Resize()

        function Passthrough:SetHeight(Height: number)
            assert(typeof(Height) == "number" and Height > 0, "Height must be a number greater than 0.")

            Passthrough.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Passthrough:SetInstance(Instance: Instance)
            assert(Instance, "Instance must be provided.")
            assert(
                typeof(Instance) == "Instance" and Instance:IsA("GuiBase2d"),
                "Instance must inherit from GuiBase2d."
            )

            if Passthrough.Instance then
                Passthrough.Instance.Parent = nil
            end

            Passthrough.Instance = Instance
            Passthrough.Instance.Parent = Holder
        end

        function Passthrough:SetVisible(Visible: boolean)
            Passthrough.Visible = Visible

            Holder.Visible = Passthrough.Visible
            Groupbox:Resize()
        end

        Passthrough.Holder = Holder
        table.insert(Groupbox.Elements, Passthrough)

        Options[Idx] = Passthrough

        function Passthrough:Destroy()
            Passthrough.Destroyed = true

            if Passthrough.Connections then
                for _, Connection in Passthrough.Connections do
                    Connection:Disconnect()
                end
            end

            if Holder then
                Holder:Destroy()
            end

            local ElemIdx = table.find(Groupbox.Elements, Passthrough)
            if ElemIdx then
                table.remove(Groupbox.Elements, ElemIdx)
            end

            Groupbox:Resize()
            Options[Idx] = nil
        end

        return Passthrough
    end

    function Funcs:AddDependencyBox()
        if self.Destroyed then return nil end

        local Groupbox = self
        local Container = Groupbox.Container

        local DepboxContainer
        local DepboxList

        do
            DepboxContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            DepboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepboxContainer,
            })
        end

        local Depbox = {
            Connections = {},
            Destroyed = false,

            Visible = false,
            Dependencies = {},

            Holder = DepboxContainer,
            Container = DepboxContainer,

            Elements = {},
            DependencyBoxes = {}
        }

        function Depbox:Resize()
            DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxList.AbsoluteContentSize.Y / Library.DPIScale)
            Groupbox:Resize()
        end

        function Depbox:Update(CancelSearch)
            for _, Dependency in Depbox.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepboxContainer.Visible = false
                    Depbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    end
                end
            end

            Depbox.Visible = true
            DepboxContainer.Visible = true
            if not Library.Searching then
                task.defer(function()
                    Depbox:Resize()
                end)
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        DepboxList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if not Depbox.Visible then
                return
            end

            Depbox:Resize()
        end)

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        DepboxContainer:GetPropertyChangedSignal("Visible"):Connect(function()
            Depbox:Resize()
        end)

        setmetatable(Depbox, BaseGroupbox)

        table.insert(Groupbox.DependencyBoxes, Depbox)
        table.insert(Library.DependencyBoxes, Depbox)

        function Depbox:Destroy()
            Depbox.Destroyed = true

            if Depbox.Connections then
                for _, Connection in Depbox.Connections do
                    Connection:Disconnect()
                end
            end

            for _, Element in Depbox.Elements do
                if Element.Destroy then
                    Element:Destroy()
                end
            end

            for _, SubDepbox in Depbox.DependencyBoxes do
                if SubDepbox.Destroy then
                    SubDepbox:Destroy()
                end
            end

            if DepboxContainer then
                DepboxContainer:Destroy()
            end

            local ElemIdx = table.find(Groupbox.DependencyBoxes, Depbox)
            if ElemIdx then
                table.remove(Groupbox.DependencyBoxes, ElemIdx)
            end

            local LibIdx = table.find(Library.DependencyBoxes, Depbox)
            if LibIdx then
                table.remove(Library.DependencyBoxes, LibIdx)
            end
        end

        return Depbox
    end

    function Funcs:AddDependencyGroupbox()
        if self.Destroyed then return nil end

        local Groupbox = self
        local Tab = Groupbox.Tab
        local BoxHolder = Groupbox.BoxHolder

        local DepGroupboxContainer
        local DepGroupboxList

        do
            DepGroupboxContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Size = UDim2.fromScale(1, 0),
                Visible = false,
                Parent = BoxHolder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = DepGroupboxContainer,
                })
            )
            Library:AddOutline(DepGroupboxContainer)

            DepGroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepGroupboxContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = DepGroupboxContainer,
            })
        end

        local DepGroupbox = {
            Connections = {},
            Destroyed = false,

            Visible = false,
            Dependencies = {},

            BoxHolder = BoxHolder,
            Holder = DepGroupboxContainer,
            Container = DepGroupboxContainer,

            Tab = Tab,
            Elements = {},
            DependencyBoxes = {},
        }

        function DepGroupbox:Resize()
            DepGroupboxContainer.Size = UDim2.new(1, 0, 0, (DepGroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 18)
        end

        function DepGroupbox:Update(CancelSearch)
            for _, Dependency in DepGroupbox.Dependencies do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepGroupboxContainer.Visible = false
                    DepGroupbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepGroupboxContainer.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    end
                end
            end

            DepGroupbox.Visible = true
            if not Library.Searching then
                DepGroupboxContainer.Visible = true
                DepGroupbox:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            for _, Dependency in Dependencies do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            DepGroupbox.Dependencies = Dependencies
            DepGroupbox:Update()
        end

        setmetatable(DepGroupbox, BaseGroupbox)

        table.insert(Tab.DependencyGroupboxes, DepGroupbox)
        table.insert(Library.DependencyBoxes, DepGroupbox :: any)

        function DepGroupbox:Destroy()
            DepGroupbox.Destroyed = true

            if DepGroupbox.Connections then
                for _, Connection in DepGroupbox.Connections do
                    Connection:Disconnect()
                end
            end

            for _, Element in DepGroupbox.Elements do
                if Element.Destroy then
                    Element:Destroy()
                end
            end

            for _, SubDepbox in DepGroupbox.DependencyBoxes do
                if SubDepbox.Destroy then
                    SubDepbox:Destroy()
                end
            end

            if DepGroupboxContainer then
                DepGroupboxContainer:Destroy()
            end

            local ElemIdx = table.find(Tab.DependencyGroupboxes, DepGroupbox)
            if ElemIdx then
                table.remove(Tab.DependencyGroupboxes, ElemIdx)
            end

            local LibIdx = table.find(Library.DependencyBoxes, DepGroupbox)
            if LibIdx then
                table.remove(Library.DependencyBoxes, LibIdx)
            end
        end

        return DepGroupbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

function Library:SetFont(FontFace)
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace :: any)
    end

    Library.Scheme.Font = FontFace
    Library:UpdateColorsUsingRegistry()
end

function Library:SetBackgroundImage(Image: string | number)
    assert(typeof(Image) == "string" or typeof(Image) == "number", "Expected string/number got " .. typeof(Image))

    Library.Scheme.BackgroundImage = Image
    if Library.Window then
        Library.Window:SetBackgroundImage(Image)
    end

    Library:UpdateColorsUsingRegistry()
end

function Library:UpdateNotificationPositions(Snap: boolean?)
    local IsLeft = Library.NotifySide:lower() == "left"
    local XScale = IsLeft and 0 or 1
    local RunningY = 0

    for _, FakeBackground in NotifyOrder do
        local Data = Library.Notifications[FakeBackground]
        if not (Data and FakeBackground.Parent) then continue end

        local Target = UDim2.new(XScale, 0, 0, RunningY)
        if Snap or not Data.PositionInitialized then
            FakeBackground.Position = Target
            Data.PositionInitialized = true

        elseif FakeBackground.Position ~= Target then
            TweenService:Create(FakeBackground, Library.NotifyTweenInfo, {
                Position = Target,
            }):Play()
        end

        RunningY = RunningY + FakeBackground.AbsoluteSize.Y + 8
    end
end

function Library:SetNotifySide(Side: string)
    Library.NotifySide = Side

    local IsLeft = Side:lower() == "left"
    if IsLeft then
        NotificationArea.AnchorPoint = Vector2.new(0, 0)
        NotificationArea.Position = UDim2.fromOffset(6, 6)
    else
        NotificationArea.AnchorPoint = Vector2.new(1, 0)
        NotificationArea.Position = UDim2.new(1, -6, 0, 6)
    end

    for FakeBackground in Library.Notifications do
        if not (FakeBackground and FakeBackground.Parent) then continue end
        FakeBackground.AnchorPoint = if IsLeft then Vector2.new(0, 0) else Vector2.new(1, 0)
    end

    if Library.UpdateNotificationPositions then
        Library:UpdateNotificationPositions(true)
    end
end

function Library:Notify(...)
    local Data = {}
    local Info = select(1, ...)

    if typeof(Info) == "table" then
        Data.Title = tostring(Info.Title)
        Data.TitleColor = Info.TitleColor

        Data.Description = tostring(Info.Description)
        Data.DescriptionColor = Info.DescriptionColor

        Data.Time = Info.Time or 5
        Data.SoundId = Info.SoundId
        Data.Steps = Info.Steps
        Data.Persist = Info.Persist

        Data.Icon = Info.Icon
        Data.BigIcon = Info.BigIcon
        Data.IconColor = Info.IconColor

        --// "Error" | "Warning" | "Success" | "Info" - colors the primary text
        Data.Type = Info.Type

        Data.Volume = tonumber(Info.Volume) or 3
    else
        Data.Description = tostring(Info)
        Data.Time = select(2, ...) or 5
        Data.SoundId = select(3, ...)
        Data.Volume = select(4, ...) or 3
    end
    Data.Destroyed = false

    --// Apply the type color to the primary text unless one was given explicitly
    local TypeColor = Data.Type and Library.NotificationTypeColors[Data.Type]
    if TypeColor then
        if Data.Title and Data.Title ~= "nil" then
            Data.TitleColor = Data.TitleColor or TypeColor
        else
            Data.DescriptionColor = Data.DescriptionColor or TypeColor
        end
    end

    local DeletedInstance = false
    local DeleteConnection = nil
    if typeof(Data.Time) == "Instance" then
        DeleteConnection = Data.Time.Destroying:Connect(function()
            DeletedInstance = true

            DeleteConnection:Disconnect()
            DeleteConnection = nil
        end)
    end

    local FakeBackground = New("Frame", {
        AnchorPoint = Library.NotifySide:lower() == "left" and Vector2.new(0, 0) or Vector2.new(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Visible = false,
        Parent = NotificationArea,
    })

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 5,
        Parent = FakeBackground,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = Holder,
    })
    Library:AddOutline(Holder)

    local ContentContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(1, 0),
        Parent = Holder,
    })

    if Data.BigIcon then
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = ContentContainer,
        })
    end

    local BigIconLabel
    if Data.BigIcon then
        local ParsedIcon = Library:GetCustomIcon(Data.BigIcon)
        if ParsedIcon then
            BigIconLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(24, 24),
                ImageColor3 = Data.IconColor or "AccentColor",
                Parent = ContentContainer,
            })
            Library:ApplyLucideIcon(BigIconLabel, ParsedIcon)
        end
    end

    local TextContainer = New("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromScale(0, 0),
        Parent = ContentContainer,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = TextContainer,
    })

    local TitleContainer
    if Data.Title then
        TitleContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0, 0),
            Parent = TextContainer,
        })
    end

    local IconLabel
    if Data.Icon and TitleContainer then
        local ParsedIcon = Library:GetCustomIcon(Data.Icon)
        if ParsedIcon then
            IconLabel = New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 1),
                Size = UDim2.fromOffset(15, 15),
                ImageColor3 = Data.IconColor or "FontColor",
                Parent = TitleContainer,
            })
            Library:ApplyLucideIcon(IconLabel, ParsedIcon)
        end
    end

    local Title
    local Desc
    local TitleX = 0
    local DescX = 0

    local TimerFill

    if Data.Title then
        Title = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, (Data.Icon and 21 or 0), 0.5, 0),
            Size = UDim2.fromScale(0, 0),
            Text = Data.Title,
            TextColor3 = Data.TitleColor or "FontColor",
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            Parent = TitleContainer,
        })
    end

    if Data.Description then
        Desc = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.None,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0, 0),
            Text = Data.Description,
            TextColor3 = Data.DescriptionColor or "FontColor",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = TextContainer,
        })
    end

    function Data:Resize()
        local ExtraWidth = BigIconLabel and 32 or 0
        local IconWidth = IconLabel and 21 or 0

        if Title then
            local X, Y =
                Library:GetTextBounds(Title.Text, Title.FontFace, Title.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - ExtraWidth - IconWidth)
            Title.Size = UDim2.fromOffset(X, Y)
            TitleX = X + IconWidth
            TitleContainer.Size = UDim2.fromOffset(TitleX, math.max(Y, IconLabel and 16 or 0))
        end

        if Desc then
            local X, Y =
                Library:GetTextBounds(Desc.Text, Desc.FontFace, Desc.TextSize, (NotificationArea.AbsoluteSize.X / Library.DPIScale) - 24 - ExtraWidth)
            Desc.Size = UDim2.fromOffset(X, Y)
            DescX = X
        end

        FakeBackground.Size = UDim2.fromOffset(math.max(TitleX, DescX) + 24 + ExtraWidth, 0)

        if Library.Notifications[FakeBackground] then
            Library:UpdateNotificationPositions()
        end
    end

    function Data:ChangeTitle(Text)
        if Title then
            Data.Title = tostring(Text)
            Title.Text = Data.Title
            Data:Resize()
        end
    end

    function Data:ChangeDescription(Text)
        if Desc then
            Data.Description = tostring(Text)
            Desc.Text = Data.Description
            Data:Resize()
        end
    end

    function Data:ChangeStep(NewStep)
        if TimerFill and Data.Steps then
            NewStep = math.clamp(NewStep or 0, 0, Data.Steps)
            TimerFill.Size = UDim2.fromScale(NewStep / Data.Steps, 1)
        end
    end

    function Data:Destroy()
        Data.Destroyed = true

        if typeof(Data.Time) == "Instance" then
            pcall(Data.Time.Destroy, Data.Time)
        end

        if DeleteConnection then
            DeleteConnection:Disconnect()
        end

        if FakeBackground then
            local Idx = table.find(NotifyOrder, FakeBackground)
            if Idx then
                table.remove(NotifyOrder, Idx)
            end
        end

        Library:UpdateNotificationPositions()

        TweenService
            :Create(Holder, Library.NotifyTweenInfo, {
                Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -8, 0, -2) or UDim2.new(1, 8, 0, -2),
            })
            :Play()

        task.delay(Library.NotifyTweenInfo.Time, function()
            Library.Notifications[FakeBackground] = nil
            FakeBackground:Destroy()
        end)
    end

    Data:Resize()

    local TimerHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 7),
        Visible = (Data.Persist ~= true and typeof(Data.Time) ~= "Instance") or typeof(Data.Steps) == "number",
        Parent = Holder,
    })
    local TimerBar = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromOffset(0, 3),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = TimerHolder,
    })
    TimerFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(1, 1),
        Parent = TimerBar,
    })

    if typeof(Data.Time) == "Instance" then
        TimerFill.Size = UDim2.fromScale(0, 1)
    end
    if Data.SoundId then
        local SoundId = Data.SoundId
        if typeof(SoundId) == "number" then
            SoundId = string.format("rbxassetid://%d", SoundId)
        end

        New("Sound", {
            SoundId = SoundId,
            Volume = tonumber(Data.Volume) or 3,
            PlayOnRemove = true,
            Parent = SoundService,
        }):Destroy()
    end

    Data.Holder = Holder

    table.insert(NotifyOrder, FakeBackground)
    Library.Notifications[FakeBackground] = Data

    Library:UpdateNotificationPositions()

    FakeBackground.Visible = true
    TweenService:Create(Holder, Library.NotifyTweenInfo, {
        Position = UDim2.fromOffset(0, 0),
    }):Play()

    task.delay(Library.NotifyTweenInfo.Time, function()
        if Data.Persist then
            return
        elseif typeof(Data.Time) == "Instance" then
            repeat
                task.wait()
            until DeletedInstance or Data.Destroyed
        else
            TweenService
                :Create(TimerFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                    Size = UDim2.fromScale(0, 1),
                })
                :Play()
            task.wait(Data.Time)
        end

        if not Data.Destroyed then
            Data:Destroy()
        end
    end)

    --// Record this notification into the built-in history log \\--
    Library:AddNotificationToHistory({
        Title = Data.Title,
        Description = Data.Description,
        TitleColor = Data.TitleColor,
        DescriptionColor = Data.DescriptionColor,
        Icon = Data.Icon,
        IconColor = Data.IconColor,
        Type = Data.Type,
    })

    return Data
end

--// Notification History \\--
function Library:AddNotificationToHistory(Entry)
    if typeof(Entry) ~= "table" then
        return
    end

    Entry.Timestamp = Entry.Timestamp or os.time()
    Entry.TimeString = Entry.TimeString or os.date("%H:%M:%S", Entry.Timestamp)

    table.insert(Library.NotificationHistory, 1, Entry)

    local Limit = tonumber(Library.NotificationHistoryLimit) or 100
    while #Library.NotificationHistory > Limit do
        table.remove(Library.NotificationHistory)
    end

    if Library.NotificationHistoryOpen then
        Library:RefreshNotificationHistory()
    else
        Library.NotificationUnreadCount = (Library.NotificationUnreadCount or 0) + 1
        Library:UpdateNotificationBadge()
    end
end

function Library:UpdateNotificationBadge()
    local Count = Library.NotificationUnreadCount or 0
    local Text = Count > 99 and "99+" or tostring(Count)

    --// There can be more than one bell (top bar + minimized card)
    for _, Badge in Library.NotificationBadges do
        if Badge.Holder and Badge.Holder.Parent then
            Badge.Holder.Visible = Count > 0
            Badge.Label.Text = Text
        end
    end
end

function Library:GetNotificationHistory()
    return Library.NotificationHistory
end

function Library:ClearNotificationHistory()
    table.clear(Library.NotificationHistory)
    if Library.NotificationHistoryFrame and Library.NotificationHistoryFrame.Visible then
        Library:RefreshNotificationHistory()
    end
end

--// The panel drops down from underneath the notification bell. The draggable
--// system uses top-left offset coordinates, so we compute an offset for it.
local NOTIFY_HISTORY_SIZE = Vector2.new(288, 328)
--// Slides up toward the bell as it fades, so it reads as retracting into it
local NOTIFY_HISTORY_SLIDE = UDim2.fromOffset(0, -22)
local NotifyHistoryOpenTween = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local NotifyHistoryCloseTween = TweenInfo.new(0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

--// Computes a top-left offset that drops a panel of the given size out from
--// underneath a top-bar button, right-aligned to it and clamped on-screen.
local function GetDropPanelPos(Button, Size)
    local Camera = workspace.CurrentCamera
    local Viewport = (Camera and Camera.ViewportSize) or Vector2.new(1280, 720)
    local MaxX = math.max(6, Viewport.X - Size.X - 6)
    local MaxY = math.max(6, Viewport.Y - Size.Y - 6)

    if Button and Button.Parent then
        local ButtonPos, ButtonSize = Button.AbsolutePosition, Button.AbsoluteSize
        local X = (ButtonPos.X + ButtonSize.X) - Size.X
        local Y = ButtonPos.Y + ButtonSize.Y + 10
        return UDim2.fromOffset(math.clamp(X, 6, MaxX), math.clamp(Y, 6, MaxY))
    end

    --// Fallback before a window exists: top-right corner
    return UDim2.fromOffset(MaxX, 56)
end

--// True only if a GuiObject and all its ancestors are visible (so a hidden
--// window's buttons are not treated as on-screen)
local function IsGuiEffectivelyVisible(Gui)
    local Current = Gui
    while Current and Current:IsA("GuiObject") do
        if not Current.Visible then
            return false
        end
        Current = Current.Parent
    end
    return true
end

--// Prefer the minimized-card button when it is the one on screen
local function PickVisibleButton(Main, Mini)
    if Mini and IsGuiEffectivelyVisible(Mini) then
        return Mini
    end
    return Main
end

local function GetNotifyHistoryDefaultPos()
    return GetDropPanelPos(PickVisibleButton(Library.NotificationBell, Library.NotificationBellMini), NOTIFY_HISTORY_SIZE)
end

function Library:_BuildNotificationHistory()
    if Library.NotificationHistoryFrame then
        return
    end

    local Holder = New("CanvasGroup", {
        AnchorPoint = Vector2.new(0, 0),
        BackgroundColor3 = "BackgroundColor",
        Position = GetNotifyHistoryDefaultPos(),
        Size = UDim2.fromOffset(NOTIFY_HISTORY_SIZE.X, NOTIFY_HISTORY_SIZE.Y),
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 10,
        Parent = ScreenGui,
    })
    table.insert(
        Library.Corners,
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Holder,
        })
    )
    table.insert(
        Library.Scales,
        New("UIScale", {
            Parent = Holder,
        })
    )
    Library:AddOutline(Holder)

    local TitleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = "Notification History",
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 36),
        Parent = TitleLabel,
    })

    Library:MakeLine(Holder, {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 1),
    })

    --// Close (X) button in the title bar
    local CloseIcon = Library:GetIcon("x")
    local CloseButton = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -8, 0, 17),
        Size = UDim2.fromOffset(20, 20),
        Text = CloseIcon and "" or "X",
        TextColor3 = "FontColor",
        TextSize = 14,
        TextTransparency = 0.35,
        ZIndex = 11,
        Parent = Holder,
    })
    local CloseImage
    if CloseIcon then
        CloseImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = CloseIcon.Url,
            ImageColor3 = "FontColor",
            ImageRectOffset = CloseIcon.ImageRectOffset,
            ImageRectSize = CloseIcon.ImageRectSize,
            ImageTransparency = 0.35,
            Position = UDim2.fromScale(0.5, 0.5),
            ScaleType = Enum.ScaleType.Fit,
            Size = UDim2.fromOffset(14, 14),
            ZIndex = 12,
            Parent = CloseButton,
        })
    end
    CloseButton.MouseEnter:Connect(function()
        TweenService:Create(CloseButton, Library.TweenInfo, { TextTransparency = 0 }):Play()
        if CloseImage then
            TweenService:Create(CloseImage, Library.TweenInfo, { ImageTransparency = 0 }):Play()
        end
    end)
    CloseButton.MouseLeave:Connect(function()
        TweenService:Create(CloseButton, Library.TweenInfo, { TextTransparency = 0.35 }):Play()
        if CloseImage then
            TweenService:Create(CloseImage, Library.TweenInfo, { ImageTransparency = 0.35 }):Play()
        end
    end)
    CloseButton.MouseButton1Click:Connect(function()
        Library:SetNotificationHistoryVisible(false)
    end)

    local Scroller = New("ScrollingFrame", {
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromScale(0, 0),
        Position = UDim2.fromOffset(0, 35),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = "AccentColor",
        Size = UDim2.new(1, 0, 1, -35),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 6),
        Parent = Scroller,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = Scroller,
    })

    Library:MakeDraggable(Holder, TitleLabel, true)
    if not table.find(Library.DraggableElements, Holder) then
        table.insert(Library.DraggableElements, Holder)
    end

    --// Clicking anywhere outside the panel (and not on the bell) closes it
    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if Library.Unloaded or not Library.NotificationHistoryOpen then
            return
        end
        if not IsClickInput(Input, true) then
            return
        end

        local Location = Input.Position
        if Library:MouseIsOverFrame(Holder, Location) then
            return
        end
        if Library.NotificationBell and Library:MouseIsOverFrame(Library.NotificationBell, Location) then
            return
        end
        if Library.NotificationBellMini and Library:MouseIsOverFrame(Library.NotificationBellMini, Location) then
            return
        end

        Library:SetNotificationHistoryVisible(false)
    end))

    Library.NotificationHistoryFrame = Holder
    Library.NotificationHistoryContainer = Scroller
    Library.NotificationHistoryRestPos = Holder.Position
end

function Library:RefreshNotificationHistory()
    Library:_BuildNotificationHistory()

    local Scroller = Library.NotificationHistoryContainer
    for _, Child in Scroller:GetChildren() do
        if not (Child:IsA("UIListLayout") or Child:IsA("UIPadding")) then
            Child:Destroy()
        end
    end

    if #Library.NotificationHistory == 0 then
        New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 24),
            Text = "No notifications yet.",
            TextColor3 = "FontColor",
            TextTransparency = 0.4,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Scroller,
        })
        return
    end

    --// "copy" is the two-page copy/paste glyph; success swaps to a checkmark
    local ClipboardIcon = Library:GetIcon("copy")
    local ClipboardCheckIcon = Library:GetIcon("clipboard-check") or Library:GetIcon("check")
    local SuccessColor = Library.NotificationTypeColors.Success or Color3.fromRGB(96, 216, 118)
    local Clipboard = (setclipboard or (typeof(toclipboard) == "function" and toclipboard) or (typeof(writeclipboard) == "function" and writeclipboard))

    for _, Entry in Library.NotificationHistory do
        local Card = New("TextButton", {
            AutomaticSize = Enum.AutomaticSize.Y,
            AutoButtonColor = false,
            BackgroundColor3 = "MainColor",
            Size = UDim2.new(1, 0, 0, 0),
            Text = "",
            Parent = Scroller,
        })
        --// Not registered in Library.Corners: cards are rebuilt on every refresh,
        --// so they simply adopt the current radius instead of leaking references
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Card,
        })
        Library:AddOutline(Card)

        --// Inner content holds the list; the copy icon overlays outside of it
        local Content = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = Card,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 2),
            Parent = Content,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 24),
            PaddingTop = UDim.new(0, 6),
            Parent = Content,
        })

        local CopyImage
        if ClipboardIcon then
            CopyImage = New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Image = ClipboardIcon.Url,
                ImageColor3 = "FontColor",
                ImageRectOffset = ClipboardIcon.ImageRectOffset,
                ImageRectSize = ClipboardIcon.ImageRectSize,
                ImageTransparency = 0.55,
                Position = UDim2.new(1, -7, 0, 7),
                Size = UDim2.fromOffset(13, 13),
                ZIndex = 6,
                Parent = Card,
            })
        end

        --// "Copied!" feedback, hidden until a copy happens
        local CopiedLabel = New("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -24, 0, 5),
            Size = UDim2.fromOffset(50, 14),
            Text = "Copied!",
            TextColor3 = SuccessColor,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTransparency = 1,
            ZIndex = 6,
            Parent = Card,
        })

        Library:AddTooltip("Click to copy", nil, Card)
        Card.MouseEnter:Connect(function()
            if CopyImage then
                TweenService:Create(CopyImage, Library.TweenInfo, { ImageTransparency = 0.1 }):Play()
            end
        end)
        Card.MouseLeave:Connect(function()
            if CopyImage then
                TweenService:Create(CopyImage, Library.TweenInfo, { ImageTransparency = 0.55 }):Play()
            end
        end)
        Card.MouseButton1Click:Connect(function()
            local Parts = {}
            if Entry.TimeString then
                table.insert(Parts, string.format("[%s]", tostring(Entry.TimeString)))
            end
            if Entry.Title and Entry.Title ~= "nil" then
                table.insert(Parts, tostring(Entry.Title))
            end
            if Entry.Description and Entry.Description ~= "nil" then
                table.insert(Parts, tostring(Entry.Description))
            end
            local Text = table.concat(Parts, "\n")

            local Ok = Clipboard ~= nil
            if Ok then
                Ok = pcall(Clipboard, Text)
            end

            --// Icon swaps to a checkmark and pops in with a little bounce
            if CopyImage then
                if Ok and ClipboardCheckIcon then
                    CopyImage.Image = ClipboardCheckIcon.Url
                    CopyImage.ImageRectOffset = ClipboardCheckIcon.ImageRectOffset
                    CopyImage.ImageRectSize = ClipboardCheckIcon.ImageRectSize
                end
                CopyImage.ImageColor3 = Ok and SuccessColor or (Library.NotificationTypeColors.Error or Color3.fromRGB(255, 76, 76))
                CopyImage.ImageTransparency = 0

                CopyImage.Size = UDim2.fromOffset(9, 9)
                TweenService:Create(CopyImage, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(13, 13),
                }):Play()
            end

            --// "Copied!" tag rises up while fading in then out
            CopiedLabel.Text = Ok and "Copied!" or "No clipboard"
            CopiedLabel.TextColor3 = Ok and SuccessColor or (Library.NotificationTypeColors.Error or Color3.fromRGB(255, 76, 76))
            CopiedLabel.TextTransparency = 0
            CopiedLabel.Position = UDim2.new(1, -24, 0, 9)
            TweenService:Create(CopiedLabel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -24, 0, 5),
            }):Play()
            TweenService:Create(CopiedLabel, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1,
            }):Play()

            task.delay(0.9, function()
                if CopyImage and CopyImage.Parent then
                    if ClipboardIcon then
                        CopyImage.Image = ClipboardIcon.Url
                        CopyImage.ImageRectOffset = ClipboardIcon.ImageRectOffset
                        CopyImage.ImageRectSize = ClipboardIcon.ImageRectSize
                    end
                    CopyImage.ImageColor3 = Library.Scheme.FontColor
                    TweenService:Create(CopyImage, Library.TweenInfo, { ImageTransparency = 0.55 }):Play()
                end
            end)
        end)

        local Header = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Parent = Content,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = Header,
        })
        New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, 0),
            Text = string.format("[%s]", tostring(Entry.TimeString or "")),
            TextColor3 = "AccentColor",
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Header,
        })
        if Entry.Type then
            New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0),
                Text = string.upper(tostring(Entry.Type)),
                TextColor3 = Library.NotificationTypeColors[Entry.Type] or "FontColor",
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Header,
            })
        end

        if Entry.Title and Entry.Title ~= "nil" then
            New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Text = tostring(Entry.Title),
                TextColor3 = Entry.TitleColor or "FontColor",
                TextSize = 15,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Content,
            })
        end

        if Entry.Description and Entry.Description ~= "nil" then
            New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Text = tostring(Entry.Description),
                TextColor3 = Entry.DescriptionColor or "FontColor",
                TextSize = 14,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Content,
            })
        end
    end
end

function Library:SetNotificationHistoryVisible(Visible: boolean)
    Library:_BuildNotificationHistory()

    local Frame = Library.NotificationHistoryFrame
    Visible = Visible and true or false

    if Library.NotificationHistoryOpen == Visible then
        return
    end
    Library.NotificationHistoryOpen = Visible

    Library._NotifHistoryAnim = (Library._NotifHistoryAnim or 0) + 1
    local AnimId = Library._NotifHistoryAnim

    if Visible then
        Library:RefreshNotificationHistory()
        --// Opening the panel marks everything as read
        Library.NotificationUnreadCount = 0
        Library:UpdateNotificationBadge()

        --// Always drop out from under the bell
        local RestPos = GetNotifyHistoryDefaultPos()
        Library.NotificationHistoryRestPos = RestPos
        Frame.Position = RestPos + NOTIFY_HISTORY_SLIDE
        Frame.GroupTransparency = 1
        Frame.Visible = true

        TweenService:Create(Frame, NotifyHistoryOpenTween, {
            Position = RestPos,
            GroupTransparency = 0,
        }):Play()
    else
        --// Retract up toward the bell from wherever it currently sits
        local RestPos = Frame.Position

        TweenService:Create(Frame, NotifyHistoryCloseTween, {
            Position = RestPos + NOTIFY_HISTORY_SLIDE,
            GroupTransparency = 1,
        }):Play()

        task.delay(NotifyHistoryCloseTween.Time, function()
            if Library._NotifHistoryAnim == AnimId and not Library.NotificationHistoryOpen and Frame and Frame.Parent then
                Frame.Visible = false
            end
        end)
    end
end

function Library:ToggleNotificationHistory()
    Library:_BuildNotificationHistory()
    Library:SetNotificationHistoryVisible(not Library.NotificationHistoryOpen)
end

function Library:CreateWindow(WindowInfo)
    WindowInfo = Library:Validate(WindowInfo, Templates.Window)
    local ViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        repeat
            ViewportSize = workspace.CurrentCamera.ViewportSize
            task.wait()
        until ViewportSize.X > 5 and ViewportSize.Y > 5
    end

    local MaxX = ViewportSize.X - 64
    local MaxY = ViewportSize.Y - 64

    Library.OriginalMinSize =
        Vector2.new(math.min(Library.OriginalMinSize.X, MaxX), math.min(Library.OriginalMinSize.Y, MaxY))
    Library.MinSize = Vector2.new(math.min(WindowInfo.MinContainerWidth, MaxX), Library.OriginalMinSize.Y)

    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
    )
    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font :: any)
    end
    WindowInfo.CornerRadius = math.min(WindowInfo.CornerRadius, 20)

    --// Old Naming \\--
    if WindowInfo.Compact ~= nil then
        WindowInfo.SidebarCompacted = WindowInfo.Compact
    end
    if WindowInfo.SidebarMinWidth ~= nil then
        WindowInfo.MinSidebarWidth = WindowInfo.SidebarMinWidth
    end
    WindowInfo.MinSidebarWidth = math.max(64, WindowInfo.MinSidebarWidth)
    WindowInfo.SidebarCompactWidth = math.max(48, WindowInfo.SidebarCompactWidth)
    WindowInfo.SidebarCollapseThreshold = math.clamp(WindowInfo.SidebarCollapseThreshold, 0.1, 0.9)
    WindowInfo.CompactWidthActivation = math.max(48, WindowInfo.CompactWidthActivation)
    WindowInfo.SnapDistance = math.max(0, WindowInfo.SnapDistance)
    WindowInfo.SnapMargin = math.max(0, WindowInfo.SnapMargin)

    Library.CornerRadius = WindowInfo.CornerRadius
    Library:SetNotifySide(WindowInfo.NotifySide)
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = WindowInfo.Font
    Library.ToggleKeybind = WindowInfo.ToggleKeybind
    Library.GlobalSearch = WindowInfo.GlobalSearch

    Library.Animations = WindowInfo.Animations
    Library.TabTransitionInfo = TweenInfo.new(
        math.max(0, WindowInfo.TabTransitionTime or 0.22),
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    Library.TabSwipeOffset = math.max(1, WindowInfo.TabSwipeOffset or 26)
    Library.TabSwipeFrom = WindowInfo.TabSwipeFrom or "right"

    local MainFrame
    local DividerLine
    local TitleHolder
    local WindowTitle
    local WindowIcon
    local RightWrapper
    local SearchBox
    local CurrentTabInfo
    local CurrentTabLabel
    local CurrentTabDescription
    local ResizeButton
    local GlowImage
    local GlowConfig = {
        Enabled = false,
        Transparency = 0.4,
        Radius = 18,
        UseAccent = true,
    }
    local Tabs
    local Container
    local BackgroundImage
    local HasBackgroundImage = false
    local BottomBackground
    local FooterSegments = {}
    local BuildFooter
    local BuildMiniFooter
    local TopBar
    local WindowSnapConfig = {
        Enabled = WindowInfo.Snapping,
        Distance = WindowInfo.SnapDistance,
        Margin = WindowInfo.SnapMargin,
        AvoidCoreGui = WindowInfo.SnapAvoidCoreGui,
    }

    local InitialLeftWidth = math.ceil(WindowInfo.Size.X.Offset * 0.3)
    local IsCompact = WindowInfo.SidebarCompacted
    local LastExpandedWidth = InitialLeftWidth
    local Minimized = false
    local ApplyWindowVisibility

    --// Minimized card state (fork addition). Forward-declared here so the card
    --// setup and the Window:AddMinimizedLabel/ClearMinimizedLabels methods share them.
    local MiniFrame
    local MiniSubtitle
    local MiniBody
    local MiniFooterHolder
    local MiniFooter
    local MiniLabels = {}
    local MiniSubtitleExplicit = (WindowInfo.MinimizedSubtitle or "") ~= ""
    --// Extra room reserved at the right of the top bar for the notification bell
    --// and (when enabled) the minimize button, which sit beside the move icon
    --// rather than in the search row
    local RightBarInset = (WindowInfo.Minimizable and 28 or 0) + 30

    do
        Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
        Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
        Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
        Library.KeybindFrame.Visible = false

        MainFrame = New("TextButton", {
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
            end,
            Name = "Main",
            Text = "",
            Position = WindowInfo.Position,
            Size = WindowInfo.Size,
            Visible = false,
            Parent = ScreenGui,
        })
        --// Elements defined outside CreateWindow need this to overlay the window
        Library.MainFrame = MainFrame
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = MainFrame,
            })
        )
        table.insert(
            Library.Scales,
            New("UIScale", {
                Parent = MainFrame,
            })
        )
        Library:AddOutline(MainFrame)
        Library:MakeLine(MainFrame, {
            Position = UDim2.fromOffset(0, 48),
            Size = UDim2.new(1, 0, 0, 1),
        })

        DividerLine = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            Position = UDim2.fromOffset(InitialLeftWidth, 0),
            Size = UDim2.new(0, 1, 1, -21),
            Parent = MainFrame,
            ZIndex = 2
        })

        local BackgroundIcon = Library:GetCustomIcon(WindowInfo.BackgroundImage)
        HasBackgroundImage = BackgroundIcon ~= nil
        BackgroundImage = New("ImageLabel", {
            Active = false,
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.fromScale(1, 1),
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = Overlay.ZIndex + 1,
            BackgroundTransparency = 1,
            ImageTransparency = 0.75,
            Visible = false,
            Parent = ScreenGui,
        })
        if BackgroundIcon then
            Library:ApplyLucideIcon(BackgroundImage, BackgroundIcon)
        end

        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = BackgroundImage,
            })
        )

        Library:GiveSignal(RunService.RenderStepped:Connect(function()
            if not (BackgroundImage and MainFrame) then
                return
            end

            local ShouldShow = HasBackgroundImage and MainFrame.Visible
            BackgroundImage.Visible = ShouldShow

            if not ShouldShow then
                return
            end

            BackgroundImage.Position = UDim2.fromOffset(
                MainFrame.AbsolutePosition.X,
                MainFrame.AbsolutePosition.Y
            )
            BackgroundImage.Size = UDim2.fromOffset(
                MainFrame.AbsoluteSize.X,
                MainFrame.AbsoluteSize.Y
            )
        end))

        if WindowInfo.Center then
            MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
        end

        --// Top Bar \\-
        TopBar = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 48),
            Parent = MainFrame,
        })
        Library:MakeDraggable(MainFrame, TopBar, false, true, WindowSnapConfig)

        --// Title \\--
        TitleHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, InitialLeftWidth, 1, 0),
            Parent = TopBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = TitleHolder,
        })

        if WindowInfo.Icon then
            local Icon = Library:GetCustomIcon(WindowInfo.Icon)
            WindowIcon = New("ImageLabel", {
                Size = WindowInfo.IconSize,
                Parent = TitleHolder,
            })
            if Icon then
                Library:ApplyLucideIcon(WindowIcon, Icon)
            end
        else
            WindowIcon = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = WindowInfo.IconSize,
                Text = WindowInfo.Title:sub(1, 1),
                TextScaled = true,
                Visible = false,
                Parent = TitleHolder,
            })
        end

        local X = Library:GetTextBounds(
            WindowInfo.Title,
            Library.Scheme.Font,
            20,
            TitleHolder.AbsoluteSize.X - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 6 or 0) - 12
        )
        WindowTitle = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, X, 1, 0),
            Text = WindowInfo.Title,
            TextSize = 20,
            Parent = TitleHolder,
        })

        --// Top Right Bar \\--
        RightWrapper = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -49 - RightBarInset, 0.5, 0),
            Size = UDim2.new(1, -InitialLeftWidth - 57 - RightBarInset - 1, 1, -16),
            Parent = TopBar,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = RightWrapper,
        })

        --// Current Tab: name stacked over its description \\--
        CurrentTabInfo = New("Frame", {
            Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 1),
            Visible = false,
            BackgroundTransparency = 1,
            Parent = RightWrapper,
        })

        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Grow,
            Parent = CurrentTabInfo,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = CurrentTabInfo,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            Parent = CurrentTabInfo,
        })

        CurrentTabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextSize = 17,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = CurrentTabInfo,
        })

        CurrentTabDescription = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextWrapped = true,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.45,
            Parent = CurrentTabInfo,
        })

        --// Search: a pill with the icon inside, on the right \\--
        SearchBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            PlaceholderText = "Search...",
            Size = WindowInfo.SearchbarSize,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not (WindowInfo.DisableSearch or false),
            Parent = RightWrapper,
        })
        New("UIFlexItem", {
            FlexMode = Enum.UIFlexMode.Shrink,
            Parent = SearchBox,
        })
        --// A pill at any radius, but square when the radius is 0
        table.insert(
            Library.PillCorners,
            New("UICorner", {
                CornerRadius = WindowInfo.CornerRadius > 0 and UDim.new(1, 0) or UDim.new(0, 0),
                Parent = SearchBox,
            })
        )
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, SEARCHBOX_TEXT_INSET),
            PaddingRight = UDim.new(0, 14),
            PaddingTop = UDim.new(0, 6),
            Parent = SearchBox,
        })
        local SearchBoxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = SearchBox,
        })

        Library:GiveSignal(SearchBox.Focused:Connect(function()
            Library.Registry[SearchBoxStroke].Color = "AccentColor"
            TweenService:Create(SearchBoxStroke, Library.TweenInfo, {
                Color = Library.Scheme.AccentColor,
            }):Play()
        end))

        Library:GiveSignal(SearchBox.FocusLost:Connect(function()
            Library.Registry[SearchBoxStroke].Color = "OutlineColor"
            TweenService:Create(SearchBoxStroke, Library.TweenInfo, {
                Color = Library.Scheme.OutlineColor,
            }):Play()
        end))

        local SearchIcon = Library:GetIcon("search")
        if SearchIcon then
            local SearchIconImage = New("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                ImageColor3 = "FontColor",
                ImageTransparency = 0.5,
                --// Sits in the padding the text was pushed out of, so it does not
                --// overlap the placeholder (the box's UIPadding also insets children)
                Position = UDim2.new(0, -(SEARCHBOX_TEXT_INSET - 14), 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Parent = SearchBox,
            })
            Library:ApplyLucideIcon(SearchIconImage, SearchIcon)
        end

        --// Ctrl+F focuses the searchbar, Escape clears and releases it \\--
        if not (WindowInfo.DisableSearch or WindowInfo.DisableSearchKeybind) then
            Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject, Processed: boolean)
                if Library.Unloaded or Input.UserInputType ~= Enum.UserInputType.Keyboard then
                    return
                end

                --// Checked before the Processed guard: keyboard input is reported as
                --// processed while a TextBox holds focus, which is exactly when this applies
                if Input.KeyCode == Enum.KeyCode.Escape then
                    if UserInputService:GetFocusedTextBox() == SearchBox then
                        SearchBox.Text = ""
                        SearchBox:ReleaseFocus()
                    end

                    return
                end

                if Processed or not Library.Toggled then
                    return
                end

                if Input.KeyCode ~= WindowInfo.SearchKeybind then
                    return
                end

                local CtrlHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                    or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
                if not CtrlHeld then
                    return
                end

                --// Never steal focus from a text box the user is already typing in
                local Focused = UserInputService:GetFocusedTextBox()
                if Focused and Focused ~= SearchBox then
                    return
                end

                SearchBox:CaptureFocus()
            end))
        end

        --// Minimize: collapses the window to a small card \\--
        if WindowInfo.Minimizable then
            local MinimizeIcon = Library:GetIcon("minus")

            --// Sits beside the move icon in the top right, not in the search row
            local MinimizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -44, 0.5, 0),
                Size = UDim2.fromOffset(24, 24),
                Text = MinimizeIcon and "" or "—",
                TextSize = 14,
                TextTransparency = 0.35,
                ZIndex = 3,
                Parent = TopBar,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = MinimizeButton,
                })
            )

            local MinimizeImage
            if MinimizeIcon then
                MinimizeImage = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = MinimizeIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = MinimizeIcon.ImageRectOffset,
                    ImageRectSize = MinimizeIcon.ImageRectSize,
                    ImageTransparency = 0.35,
                    Position = UDim2.fromScale(0.5, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(16, 16),
                    Parent = MinimizeButton,
                })
            end

            Library:AddTooltip("Minimize", nil, MinimizeButton)
            MinimizeButton.MouseEnter:Connect(function()
                TweenService:Create(MinimizeButton, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
                if MinimizeImage then
                    TweenService:Create(MinimizeImage, Library.TweenInfo, { ImageTransparency = 0 }):Play()
                end
            end)
            MinimizeButton.MouseLeave:Connect(function()
                TweenService:Create(MinimizeButton, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
                if MinimizeImage then
                    TweenService:Create(MinimizeImage, Library.TweenInfo, { ImageTransparency = 0.35 }):Play()
                end
            end)
            MinimizeButton.MouseButton1Click:Connect(function()
                Library.Window:SetMinimized(true)
            end)

            --// The minimized card: a header with the icon, title and subtitle, an
            --// optional body of labels, and the window footer along the bottom.
            MiniFrame = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = function()
                    return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
                end,
                Name = "Minimized",
                Position = WindowInfo.Position,
                Size = UDim2.fromOffset(WindowInfo.MinimizedWidth, 0),
                Visible = false,
                Parent = ScreenGui,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = MiniFrame,
                })
            )
            table.insert(
                Library.Scales,
                New("UIScale", {
                    Parent = MiniFrame,
                })
            )
            Library:AddOutline(MiniFrame)

            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = MiniFrame,
            })

            --// Header \\--
            local MiniHeader = New("Frame", {
                BackgroundTransparency = 1,
                LayoutOrder = 0,
                Size = UDim2.new(1, 0, 0, 46),
                Parent = MiniFrame,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 10),
                Parent = MiniHeader,
            })
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = MiniHeader,
            })

            local MiniIconData = WindowInfo.Icon and Library:GetCustomIcon(WindowInfo.Icon) or nil
            if MiniIconData then
                --// Rounded badge so the icon reads as an app mark
                local IconHolder = New("Frame", {
                    BackgroundColor3 = "MainColor",
                    LayoutOrder = 0,
                    Size = UDim2.fromOffset(26, 26),
                    Parent = MiniHeader,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, math.max(2, WindowInfo.CornerRadius)),
                        Parent = IconHolder,
                    })
                )

                New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = MiniIconData.Url,
                    ImageRectOffset = MiniIconData.ImageRectOffset,
                    ImageRectSize = MiniIconData.ImageRectSize,
                    Position = UDim2.fromScale(0.5, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(16, 16),
                    Parent = IconHolder,
                })
            end

            --// Title stacked over the subtitle
            local MiniTitleHolder = New("Frame", {
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Parent = MiniHeader,
            })
            New("UIFlexItem", {
                FlexMode = Enum.UIFlexMode.Shrink,
                Parent = MiniTitleHolder,
            })
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = MiniTitleHolder,
            })

            New("TextLabel", {
                BackgroundTransparency = 1,
                LayoutOrder = 0,
                Size = UDim2.new(1, 0, 0, 17),
                Text = `<b>{WindowInfo.Title}</b>`,
                TextSize = 15,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = MiniTitleHolder,
            })

            MiniSubtitle = New("TextLabel", {
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = WindowInfo.MinimizedSubtitle or "",
                TextSize = 12,
                TextTransparency = 0.55,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = (WindowInfo.MinimizedSubtitle or "") ~= "",
                Parent = MiniTitleHolder,
            })

            --// Mirror the Enabled Features + Notification bell into the minimized card
            local function MiniActionButton(Icon, Order, TooltipText, OnClick, FallbackText)
                local Btn = New("TextButton", {
                    BackgroundTransparency = 1,
                    LayoutOrder = Order,
                    Size = UDim2.fromOffset(22, 22),
                    Text = Icon and "" or (FallbackText or "?"),
                    TextColor3 = "FontColor",
                    TextSize = 15,
                    TextTransparency = 0.35,
                    Parent = MiniHeader,
                })
                local Img
                if Icon then
                    Img = New("ImageLabel", {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Image = Icon.Url,
                        ImageColor3 = "FontColor",
                        ImageRectOffset = Icon.ImageRectOffset,
                        ImageRectSize = Icon.ImageRectSize,
                        ImageTransparency = 0.35,
                        Position = UDim2.fromScale(0.5, 0.5),
                        ScaleType = Enum.ScaleType.Fit,
                        Size = UDim2.fromOffset(16, 16),
                        Parent = Btn,
                    })
                end
                Btn.MouseEnter:Connect(function()
                    TweenService:Create(Btn, Library.TweenInfo, { TextTransparency = 0 }):Play()
                    if Img then
                        TweenService:Create(Img, Library.TweenInfo, { ImageTransparency = 0 }):Play()
                    end
                end)
                Btn.MouseLeave:Connect(function()
                    TweenService:Create(Btn, Library.TweenInfo, { TextTransparency = 0.35 }):Play()
                    if Img then
                        TweenService:Create(Img, Library.TweenInfo, { ImageTransparency = 0.35 }):Play()
                    end
                end)
                if TooltipText then
                    Library:AddTooltip(TooltipText, nil, Btn)
                end
                Btn.MouseButton1Click:Connect(OnClick)
                return Btn
            end

            local MiniBell = MiniActionButton(
                Library:GetIcon("bell"),
                3,
                "Notification History",
                function() Library:ToggleNotificationHistory() end,
                "!"
            )
            Library.NotificationBellMini = MiniBell

            do
                --// Unread badge for the minimized bell
                local BadgeHolder = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = "AccentColor",
                    Position = UDim2.new(1, 2, 0, 0),
                    Size = UDim2.fromOffset(14, 14),
                    Visible = false,
                    ZIndex = 5,
                    Parent = MiniBell,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = BadgeHolder,
                })
                local BadgeLabel = New("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                    Text = "0",
                    TextColor3 = "BackgroundColor",
                    TextSize = 11,
                    ZIndex = 6,
                    Parent = BadgeHolder,
                })
                New("UIPadding", {
                    PaddingLeft = UDim.new(0, 2),
                    PaddingRight = UDim.new(0, 2),
                    Parent = BadgeLabel,
                })
                table.insert(Library.NotificationBadges, { Holder = BadgeHolder, Label = BadgeLabel })
                Library:UpdateNotificationBadge()
            end

            local RestoreIcon = Library:GetIcon("chevron-up")
            local RestoreButton = New("TextButton", {
                BackgroundTransparency = 1,
                LayoutOrder = 4,
                Size = UDim2.fromOffset(22, 22),
                Text = RestoreIcon and "" or "^",
                TextSize = 14,
                TextTransparency = 0.35,
                Parent = MiniHeader,
            })

            if RestoreIcon then
                New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = RestoreIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = RestoreIcon.ImageRectOffset,
                    ImageRectSize = RestoreIcon.ImageRectSize,
                    ImageTransparency = 0.35,
                    Position = UDim2.fromScale(0.5, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(16, 16),
                    Parent = RestoreButton,
                })
            end

            Library:AddTooltip("Restore", nil, RestoreButton)
            RestoreButton.MouseButton1Click:Connect(function()
                Library.Window:SetMinimized(false)
            end)

            --// Body: labels the script adds, hidden until there is one \\--
            MiniBody = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Visible = false,
                Parent = MiniFrame,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                Parent = MiniBody,
            })
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = MiniBody,
            })

            --// Footer \\--
            MiniFooterHolder = New("Frame", {
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                Size = UDim2.new(1, 0, 0, 26),
                Parent = MiniFrame,
            })
            Library:MakeLine(MiniFooterHolder, {
                Position = UDim2.fromOffset(0, 0),
                Size = UDim2.new(1, 0, 0, 1),
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                Parent = MiniFooterHolder,
            })

            MiniFooter = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                TextSize = 12,
                TextTransparency = 0.6,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = MiniFooterHolder,
            })

            --// Drag by the header, so clicks on the buttons still register
            Library:MakeDraggable(MiniFrame, MiniHeader, true)
        end

        if MoveIcon then
            local MoveIconImage = New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                ImageColor3 = "AccentColor",
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(28, 28),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = TopBar,
            })
            Library:ApplyLucideIcon(MoveIconImage, MoveIcon)
        end

        if not WindowInfo.DisableNotificationBell then
            --// Notification bell: sits left of the minimize/move cluster and
            --// opens the built-in Notification History, with an unread badge
            local BellIcon = Library:GetIcon("bell")
            local BellRightOffset = WindowInfo.Minimizable and 72 or 42

            local BellButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -BellRightOffset, 0.5, 0),
                Size = UDim2.fromOffset(24, 24),
                Text = BellIcon and "" or "!",
                TextSize = 14,
                TextTransparency = 0.35,
                ZIndex = 3,
                Parent = TopBar,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = BellButton,
                })
            )

            local BellImage
            if BellIcon then
                BellImage = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = BellIcon.Url,
                    ImageColor3 = "FontColor",
                    ImageRectOffset = BellIcon.ImageRectOffset,
                    ImageRectSize = BellIcon.ImageRectSize,
                    ImageTransparency = 0.35,
                    Position = UDim2.fromScale(0.5, 0.5),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(16, 16),
                    ZIndex = 4,
                    Parent = BellButton,
                })
            end

            --// Unread count badge, hidden until there is something unread
            local BadgeHolder = New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "AccentColor",
                Position = UDim2.new(1, 2, 0, -2),
                Size = UDim2.fromOffset(14, 14),
                Visible = false,
                ZIndex = 5,
                Parent = BellButton,
            })
            New("UICorner", {
                CornerRadius = UDim.new(1, 0),
                Parent = BadgeHolder,
            })
            local BadgeLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "0",
                TextColor3 = "BackgroundColor",
                TextSize = 11,
                ZIndex = 6,
                Parent = BadgeHolder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                Parent = BadgeHolder,
            })

            Library.NotificationBadge = { Holder = BadgeHolder, Label = BadgeLabel }
            table.insert(Library.NotificationBadges, Library.NotificationBadge)
            Library.NotificationBell = BellButton
            Library:UpdateNotificationBadge()

            Library:AddTooltip("Notification History", nil, BellButton)
            BellButton.MouseEnter:Connect(function()
                TweenService:Create(BellButton, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
                if BellImage then
                    TweenService:Create(BellImage, Library.TweenInfo, { ImageTransparency = 0 }):Play()
                end
            end)
            BellButton.MouseLeave:Connect(function()
                TweenService:Create(BellButton, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
                if BellImage then
                    TweenService:Create(BellImage, Library.TweenInfo, { ImageTransparency = 0.35 }):Play()
                end
            end)
            BellButton.MouseButton1Click:Connect(function()
                Library:ToggleNotificationHistory()
            end)
        end

        --// Bottom Bar \\--
        BottomBackground = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
            end,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 20 + WindowInfo.CornerRadius),
            Parent = MainFrame
        })
        Library:MakeLine(MainFrame, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, -20),
            Size = UDim2.new(1, 0, 0, 1),
        })

        local BottomBar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 20),
            Parent = MainFrame,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = BottomBackground,
            })
        )

        --// Footer \\-
        --// The footer is a row of segments; each one is plain or copyable
        local FooterHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = BottomBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = FooterHolder,
        })

        local function AddFooterSegment(Info)
            local Text = tostring(Info.Text or "")
            --// Copyable is opt in per segment, and impossible without a clipboard
            local Copyable = Info.Copyable == true and SetClipboard ~= nil

            local Label = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0),
                Text = Text,
                TextColor3 = Copyable and "BlueColor" or "FontColor",
                TextSize = 14,
                TextTransparency = Copyable and 0 or 0.5,
                Parent = FooterHolder,
            })
            table.insert(FooterSegments, Label)

            if not Copyable then
                return Label
            end

            local CopyValue = tostring(Info.CopyText or Text)
            local CopyIcon = Library:GetIcon("copy")
            local CopiedIcon = Library:GetIcon("check")

            local CopyButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(18, 18),
                Text = "",
                Parent = FooterHolder,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = CopyButton,
                })
            )
            --// Keeps the glyph off the button's edges no matter the icon set
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 3),
                PaddingLeft = UDim.new(0, 3),
                PaddingRight = UDim.new(0, 3),
                PaddingTop = UDim.new(0, 3),
                Parent = CopyButton,
            })

            local CopyImage = New("ImageLabel", {
                Image = CopyIcon and CopyIcon.Url or "",
                ImageColor3 = "BlueColor",
                ImageRectOffset = CopyIcon and CopyIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CopyIcon and CopyIcon.ImageRectSize or Vector2.zero,
                ScaleType = Enum.ScaleType.Fit,
                Size = UDim2.fromScale(1, 1),
                Parent = CopyButton,
            })

            Library:AddTooltip("Copy to clipboard", nil, CopyButton)

            local ResetThread
            local function Copy()
                local Success = pcall(SetClipboard, CopyValue)
                if not Success then
                    return
                end

                if CopiedIcon then
                    CopyImage.Image = CopiedIcon.Url
                    CopyImage.ImageRectOffset = CopiedIcon.ImageRectOffset
                    CopyImage.ImageRectSize = CopiedIcon.ImageRectSize
                end

                if ResetThread then
                    task.cancel(ResetThread)
                end

                ResetThread = task.delay(1.5, function()
                    ResetThread = nil

                    if CopyIcon then
                        CopyImage.Image = CopyIcon.Url
                        CopyImage.ImageRectOffset = CopyIcon.ImageRectOffset
                        CopyImage.ImageRectSize = CopyIcon.ImageRectSize
                    end
                end)
            end

            CopyButton.MouseButton1Click:Connect(Copy)
            CopyButton.MouseEnter:Connect(function()
                TweenService:Create(CopyButton, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
            end)
            CopyButton.MouseLeave:Connect(function()
                TweenService:Create(CopyButton, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            end)

            --// The text itself is a copy target too. This listens on the label instead
            --// of parenting a button to it, since a child sized relative to an
            --// AutomaticSize parent makes that parent grow without bound.
            Label.InputBegan:Connect(function(Input)
                if IsClickInput(Input) then
                    Copy()
                end
            end)

            table.insert(FooterSegments, CopyButton)
            return Label
        end

        --// Accepts a string, or a list of { Text, Copyable, CopyText } segments
        function BuildFooter(Footer)
            for _, Object in FooterSegments do
                Object:Destroy()
            end
            table.clear(FooterSegments)

            if typeof(Footer) == "string" then
                --// One string: CopyableFooter decides whether all of it is copyable
                AddFooterSegment({
                    Text = Footer,
                    Copyable = WindowInfo.CopyableFooter ~= false,
                })

                return
            end

            for _, Segment in Footer do
                --// Bare strings in a list are plain text; opt in with Copyable = true
                if typeof(Segment) == "string" then
                    Segment = { Text = Segment, Copyable = false }
                end

                AddFooterSegment(Segment)
            end
        end

        --// The minimized card shows the same footer, flattened to plain text since it
        --// has no room for per segment copy buttons
        function BuildMiniFooter(Footer)
            if not MiniFooter then
                return
            end

            if typeof(Footer) == "string" then
                MiniFooter.Text = Footer
            else
                local Parts = {}

                for _, Segment in Footer do
                    if typeof(Segment) == "string" then
                        table.insert(Parts, Segment)
                    elseif typeof(Segment) == "table" and Segment.Text ~= nil then
                        table.insert(Parts, tostring(Segment.Text))
                    end
                end

                MiniFooter.Text = table.concat(Parts, " ")
            end

            MiniFooterHolder.Visible = MiniFooter.Text ~= ""
        end

        BuildFooter(WindowInfo.Footer)
        BuildMiniFooter(WindowInfo.Footer)
        --// Remembered so standalone screens (e.g. the unsupported-executor gate)
        --// can default their footer to the window's
        Library.Footer = WindowInfo.Footer

        --// Resize Button \\--
        if WindowInfo.Resizable then
            ResizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -WindowInfo.CornerRadius / 4, 0, 0),
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Text = "",
                Parent = BottomBar,
            })

            Library:MakeResizable(MainFrame, ResizeButton, function()
                for _, Tab in Library.Tabs do
                    Tab:Resize(true)
                end
            end)
        end

        local WindowResizeIcon = New("ImageLabel", {
            ImageColor3 = "FontColor",
            ImageTransparency = 0.5,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = ResizeButton,
        })
        if ResizeIcon then
            Library:ApplyLucideIcon(WindowResizeIcon, ResizeIcon)
        end

        --// Tabs \\--
        Tabs = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            CanvasSize = UDim2.fromScale(0, 0),
            Position = UDim2.fromOffset(0, 49),
            ScrollBarThickness = 0,
            Size = UDim2.new(0, InitialLeftWidth, 1, -70),
            Parent = MainFrame,
        })
        New("UIListLayout", {
            Parent = Tabs,
        })

        --// Container \\--
        Container = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
            end,
            ClipsDescendants = true,
            Name = "Container",
            Position = UDim2.new(1, 0, 0, 49),
            Size = UDim2.new(1, -InitialLeftWidth - 1, 1, -70),
            Parent = MainFrame,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 0),
            Parent = Container,
        })

        Library.WindowContainer = Container
    end

    --// Window Table \\--
    local Window = {}
    local Fading = false

    local function SetUICorner(UICorner, Corner, HalfValue)
        local Current = UICorner[Corner]
        if Current.Offset == 0 and Current.Scale == 0 then
            return
        end

        UICorner[Corner] = HalfValue
    end

    function Window:ChangeTitle(title)
        assert(typeof(title) == "string", "Expected string for title got: " .. typeof(title))

        WindowTitle.Text = title
        WindowInfo.Title = title
    end

    function Window:SetBackgroundImage(Image: string)
        local ValidIcon = false

        if typeof(Image) == "string" then
            local BackgroundIcon = Library:GetCustomIcon(Image)

            if BackgroundIcon then
                ValidIcon = true

                Library:ApplyLucideIcon(BackgroundImage, BackgroundIcon)
            elseif Image:match("http://") or Image:match("https://") then
                local RawFileName = Image:match("(.+)%..+$")
                local _, Domain = Image:match("^(https?://)([^/]+)");

                if RawFileName and Domain then
                    local Extention = string.sub(Image, #RawFileName + 1, #Image)
                    local FileNamePos = RawFileName:gsub("\\", "/"):find("/[^/]*$")
                    local FileName = FileNamePos and Image:sub(FileNamePos + 1) or nil

                    if FileName then
                        ValidIcon = true

                        local AssetName = Domain .. FileName
                        if #AssetName > 255 then
                            local NewLength = 255 - #Domain - #Extention
                            if NewLength < 0 then
                                AssetName = Domain .. Extention
                            else
                                AssetName = Domain .. string.sub(FileName:sub(1, #FileName - #Extention), 1, NewLength) .. Extention
                            end
                        end

                        if CustomImageManagerAssets[FileName] == nil then
                            CustomImageManager.AddAsset(FileName, 0, Image)
                        else
                            CustomImageManager.DownloadAsset(FileName, true)
                        end

                        BackgroundImage.Image = CustomImageManager.GetAsset(FileName)
                        BackgroundImage.ImageRectOffset = Vector2.zero
                        BackgroundImage.ImageRectSize = Vector2.zero
                    end
                end
            end
        end

        if not ValidIcon then
            BackgroundImage.Image = ""
            BackgroundImage.ImageRectOffset = Vector2.zero
            BackgroundImage.ImageRectSize = Vector2.zero
        end

        HasBackgroundImage = ValidIcon
        WindowInfo.BackgroundImage = Image
    end

    --// Glow \\--
    --// Manual, opt-in soft glow drawn behind the window. It is never enabled or
    --// hidden automatically: some games run anticheats that can flag unusual
    --// rendering, so the user is the one who turns this on.
    local function SetGlowColor(Color: Color3?)
        if not GlowImage then
            return
        end

        if typeof(Color) == "Color3" then
            --// Detach from the theme so a custom color sticks across theme changes
            GlowConfig.UseAccent = false
            Library.Registry[GlowImage] = nil
            GlowImage.ImageColor3 = Color
        else
            --// Follow the accent color and keep updating with the theme
            GlowConfig.UseAccent = true
            Library.Registry[GlowImage] = { ImageColor3 = "AccentColor" }
            GlowImage.ImageColor3 = Library.Scheme.AccentColor
        end
    end

    --// Keep the glow soft. This is a feathered 9-slice shadow asset, so its
    --// SliceScale governs edge softness, not corner radius — shrinking it just
    --// collapses the halo into a hard squared box. A soft glow naturally reads
    --// fine behind any corner radius, so we hold it at the native slice scale.
    local function UpdateGlowShape()
        if not GlowImage then
            return
        end

        GlowImage.SliceScale = 1
    end

    local function EnsureGlow()
        if GlowImage then
            return
        end

        GlowImage = New("ImageLabel", {
            Active = false,
            BackgroundTransparency = 1,
            --// 9-slice soft shadow asset; tinted to act as a glow
            Image = "rbxassetid://6014261993",
            ImageColor3 = "AccentColor",
            ImageTransparency = GlowConfig.Transparency,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            Visible = false,
            ZIndex = 0,
            Parent = ScreenGui,
        })
        UpdateGlowShape()

        Library:GiveSignal(RunService.RenderStepped:Connect(function()
            if not (GlowImage and MainFrame) then
                return
            end

            --// Glow follows whichever frame is on screen — the main window, or the
            --// minimized pill when collapsed — so the accent glow stays with the UI.
            local Target = if (MiniFrame and MiniFrame.Visible) then MiniFrame else MainFrame

            local ShouldShow = GlowConfig.Enabled and Target.Visible
            GlowImage.Visible = ShouldShow
            if not ShouldShow then
                return
            end

            local Radius = GlowConfig.Radius
            GlowImage.Position = UDim2.fromOffset(
                Target.AbsolutePosition.X - Radius,
                Target.AbsolutePosition.Y - Radius
            )
            GlowImage.Size = UDim2.fromOffset(
                Target.AbsoluteSize.X + Radius * 2,
                Target.AbsoluteSize.Y + Radius * 2
            )
        end))
    end

    --// Enabled: turn the glow on/off. Options: { Color: Color3?, Transparency: number?, Radius: number? }
    --// Color defaults to (and follows) the accent color when omitted.
    function Window:SetGlow(Enabled: boolean, Options: { [string]: any }?)
        Options = typeof(Options) == "table" and Options or {}

        if typeof(Options.Transparency) == "number" then
            GlowConfig.Transparency = math.clamp(Options.Transparency, 0, 1)
        end
        if typeof(Options.Radius) == "number" then
            GlowConfig.Radius = math.max(0, Options.Radius)
        end

        GlowConfig.Enabled = Enabled == true
        WindowInfo.Glow = GlowConfig.Enabled

        if GlowConfig.Enabled then
            EnsureGlow()
            GlowImage.ImageTransparency = GlowConfig.Transparency
            UpdateGlowShape()

            if Options.Color ~= nil then
                SetGlowColor(typeof(Options.Color) == "Color3" and Options.Color or nil)
            end
        elseif GlowImage then
            GlowImage.Visible = false
            GlowImage.ImageTransparency = GlowConfig.Transparency
        end

        return Window
    end

    --// Current window size and position (offset UDim2s)
    function Window:GetSizePosition(): (UDim2, UDim2)
        return MainFrame.Size, MainFrame.Position
    end

    --// Apply a size and/or position, clamped to the viewport and min size, then
    --// relayout the tabs the same way a manual resize does.
    function Window:SetSizePosition(Size: UDim2?, Position: UDim2?)
        local Camera = workspace.CurrentCamera
        local ViewportSize = (Camera and Camera.ViewportSize) or Vector2.new(1920, 1080)

        if typeof(Size) == "UDim2" then
            local MaxX = math.max(Library.MinSize.X, ViewportSize.X - 64)
            local MaxY = math.max(Library.MinSize.Y, ViewportSize.Y - 64)

            MainFrame.Size = UDim2.new(
                Size.X.Scale,
                math.clamp(Size.X.Offset, Library.MinSize.X, MaxX),
                Size.Y.Scale,
                math.clamp(Size.Y.Offset, Library.MinSize.Y, MaxY)
            )

            for _, Tab in Library.Tabs do
                Tab:Resize(true)
            end
        end

        if typeof(Position) == "UDim2" then
            MainFrame.Position = Position
        end

        return Window
    end

    --// A string, or a list of segments: { Text, Copyable, CopyText }
    function Window:SetFooter(Footer: string | { any })
        assert(
            typeof(Footer) == "string" or typeof(Footer) == "table",
            "Expected string or table for footer got: " .. typeof(Footer)
        )

        BuildFooter(Footer)
        BuildMiniFooter(Footer)
        WindowInfo.Footer = Footer
        Library.Footer = Footer
    end

    function Window:SetAlwaysOnTop(Enabled: boolean)
        WindowInfo.AlwaysOnTop = Enabled == true
        SetAlwaysOnTop(Library.ScreenGui, WindowInfo.AlwaysOnTop)
    end

    function Window:SetSnapping(Enabled: boolean, Distance: number?, Margin: number?, AvoidCoreGui: boolean?)
        WindowInfo.Snapping = Enabled == true
        WindowSnapConfig.Enabled = WindowInfo.Snapping

        if Distance then
            WindowInfo.SnapDistance = math.max(0, Distance)
            WindowSnapConfig.Distance = WindowInfo.SnapDistance
        end

        if Margin then
            WindowInfo.SnapMargin = math.max(0, Margin)
            WindowSnapConfig.Margin = WindowInfo.SnapMargin
        end

        if AvoidCoreGui ~= nil then
            WindowInfo.SnapAvoidCoreGui = AvoidCoreGui == true
            WindowSnapConfig.AvoidCoreGui = WindowInfo.SnapAvoidCoreGui
        end
    end

    function Window:SetCornerRadius(Radius: number)
        assert(typeof(Radius) == "number", "Expected number for Radius got: " .. typeof(Radius))
        Radius = math.min(Radius, 20)

        local OldRadius = Library.CornerRadius
        local HalfCurrent = OldRadius / 2
        local RadiusHalf = UDim.new(0, Radius / 2)
        local RadiusUDim = UDim.new(0, Radius)

        for _, UICorner in Library.Corners do
            if math.abs(UICorner.CornerRadius.Offset - HalfCurrent) < 0.001 then
                UICorner.CornerRadius = RadiusHalf
            else
                UICorner.CornerRadius = RadiusUDim
            end
        end

        for _, UICorner in Library.SpecificCorners do
            SetUICorner(UICorner, "TopRightRadius", RadiusHalf)
            SetUICorner(UICorner, "TopLeftRadius", RadiusHalf)
            SetUICorner(UICorner, "BottomRightRadius", RadiusHalf)
            SetUICorner(UICorner, "BottomLeftRadius", RadiusHalf)
        end

        --// Pills stay fully rounded at any radius, but go square when it hits 0
        local PillUDim = Radius > 0 and UDim.new(1, 0) or UDim.new(0, 0)
        for _, UICorner in Library.PillCorners do
            UICorner.CornerRadius = PillUDim
        end

        Library.CornerRadius = Radius
        WindowInfo.CornerRadius = Radius

        --// Keep the glow's rounding in step with the window's
        UpdateGlowShape()

        ResizeButton.Position = UDim2.new(1, -Radius / 4, 0, 0)
        BottomBackground.Size = UDim2.new(1, 0, 0, 20 + Radius)

        for _, Menu in Library.ContextMenus do
            if Menu.Destroyed then
                continue
            end

            if typeof(Menu.ActiveCallback) ~= "function" then
                continue
            end

            if not Menu.Active then
                local HolderActive = false
                for _, Other in Library.ContextMenus do
                    if Other == Menu then 
                        continue
                    end
   
                    if Other.Active and Other.Holder == Menu.Holder then
                        HolderActive = true
                        break
                    end
                end

                if HolderActive then
                    continue
                end

                Menu.ActiveCallback(false)
                continue
            end

            Menu.ActiveCallback(true)
        end

        for _, Option in Options do
            if Option.Type == "Dropdown" and Option.RefreshPool then
                Option:RefreshPool()
            end
        end

        for _, Tab in Library.Tabs do
            if Tab.IsKeyTab then
                continue
            end

            for _, Tabbox in Tab.Tabboxes do
                Tabbox:UpdateCorners()
            end
        end
    end

    function Window:SetAnimations(Animations: { [string]: boolean }?, TabTransitionTime: number?, TabSwipeOffset: number?, TabSwipeFrom: ("left" | "right" | "top" | "bottom" | string)?)
        if typeof(Animations) == "table" then
            WindowInfo.Animations = Animations
            Library.Animations = Animations
        end

        if typeof(TabTransitionTime) == "number" then
            local TweenInfo = TweenInfo.new(
                math.max(0, TabTransitionTime or 0.22),
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )

            WindowInfo.TabTransitionInfo = TweenInfo
            Library.TabTransitionInfo = TweenInfo
        end

        if typeof(TabSwipeOffset) == "number" then
            TabSwipeOffset = math.max(1, TabSwipeOffset)

            WindowInfo.TabSwipeOffset = TabSwipeOffset
            Library.TabSwipeOffset = TabSwipeOffset
        end

        if typeof(TabSwipeFrom) == "string" then
            TabSwipeFrom = string.lower(TabSwipeFrom)

            WindowInfo.TabSwipeFrom = TabSwipeFrom
            Library.TabSwipeFrom = TabSwipeFrom
        end
    end

    local function ApplyCompact()
        IsCompact = Window:GetSidebarWidth() == WindowInfo.SidebarCompactWidth
        if WindowInfo.DisableCompactingSnap then
            IsCompact = Window:GetSidebarWidth() <= WindowInfo.CompactWidthActivation
        end

        --// Live flag the tooltip gate reads: sidebar hints only show when compact
        Library.SidebarCompacted = IsCompact

        WindowTitle.Visible = not IsCompact
        if not WindowInfo.Icon then
            WindowIcon.Visible = IsCompact
        end

        for _, Button in Library.TabButtons do
            if not Button.Icon then
                continue
            end

            Button.Label.Visible = not IsCompact
            Button.Padding.PaddingBottom = UDim.new(0, IsCompact and 6 or 11)
            Button.Padding.PaddingLeft = UDim.new(0, IsCompact and 6 or 12)
            Button.Padding.PaddingRight = UDim.new(0, IsCompact and 6 or 12)
            Button.Padding.PaddingTop = UDim.new(0, IsCompact and 6 or 11)
            Button.Icon.SizeConstraint = IsCompact and Enum.SizeConstraint.RelativeXY or Enum.SizeConstraint.RelativeYY

            --// The chevron has no room compact, but the sub tabs themselves stay:
            --// their entries flip to centered icon-only rows and the list re-fits
            if Button.Chevron then
                Button.Chevron.Visible = not IsCompact
            end
            if Button.SidebarEntries then
                for _, Entry in Button.SidebarEntries do
                    if Entry.SetCompact then
                        Entry:SetCompact(IsCompact)
                    end
                end
            end
            if Button.RefreshSidebarList then
                Button.RefreshSidebarList(false)
            end
        end

        --// Re-open the active tab's list once the sidebar has room again
        if not IsCompact and Library.ActiveTab and Library.ActiveTab.SetExpanded then
            Library.ActiveTab:SetExpanded(true)
        end
    end

    function Window:IsSidebarCompacted()
        return IsCompact
    end

    --// Minimized is the whole window collapsing to a pill, which is a different thing
    --// from SetCompact below: that only narrows the sidebar.
    function Window:IsMinimized()
        return Minimized
    end

    function Window:SetMinimized(Value: boolean?)
        if not MiniFrame then
            return
        end

        if Value == nil then
            Value = not Minimized
        end
        Value = Value and true or false

        if Value == Minimized then
            return
        end
        Minimized = Value

        if Minimized then
            --// Open the pill where the window was, so it does not jump across the screen
            MiniFrame.Position = MainFrame.Position
            MiniFrame.AnchorPoint = MainFrame.AnchorPoint
        else
            MainFrame.Position = MiniFrame.Position
            MainFrame.AnchorPoint = MiniFrame.AnchorPoint
        end

        ApplyWindowVisibility()
    end

    function Window:ToggleMinimized()
        Window:SetMinimized(not Minimized)
    end

    --// Passing nil or an empty string hands the line back to the automatic tab name
    function Window:SetMinimizedSubtitle(Text: string?)
        if not MiniSubtitle then
            return
        end

        Text = Text or ""
        MiniSubtitleExplicit = Text ~= ""

        if MiniSubtitleExplicit then
            MiniSubtitle.Text = Text
            MiniSubtitle.Visible = true
        elseif Library.ActiveTab then
            MiniSubtitle.Text = Library.ActiveTab.Name or ""
            MiniSubtitle.Visible = MiniSubtitle.Text ~= ""
        else
            MiniSubtitle.Visible = false
        end
    end

    --// A line of text on the minimized card, for status a script wants visible while
    --// the window is collapsed. Returns a handle so it can be updated or removed.
    function Window:AddMinimizedLabel(Text: string?)
        if not MiniBody then
            return
        end

        local Label = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = #MiniLabels,
            Size = UDim2.new(1, 0, 0, 0),
            Text = Text or "",
            TextSize = 13,
            TextTransparency = 0.25,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = MiniBody,
        })

        local Handle = {
            Label = Label,
            Type = "MinimizedLabel",
        }

        function Handle:SetText(Value: string?)
            Label.Text = Value or ""
        end

        function Handle:SetVisible(Value: boolean)
            Label.Visible = Value and true or false
        end

        function Handle:Destroy()
            local Index = table.find(MiniLabels, Handle)
            if Index then
                table.remove(MiniLabels, Index)
            end

            Label:Destroy()
            MiniBody.Visible = #MiniLabels > 0
        end

        table.insert(MiniLabels, Handle)
        MiniBody.Visible = true

        return Handle
    end

    function Window:ClearMinimizedLabels()
        for Index = #MiniLabels, 1, -1 do
            MiniLabels[Index]:Destroy()
        end
    end

    function Window:SetCompact(State)
        Window:SetSidebarWidth(State and WindowInfo.SidebarCompactWidth or LastExpandedWidth)
    end

    function Window:GetSidebarWidth()
        return Tabs.Size.X.Offset
    end

    function Window:SetSidebarWidth(Width)
        Width = math.clamp(Width, 48, MainFrame.Size.X.Offset - WindowInfo.MinContainerWidth - 1)

        DividerLine.Position = UDim2.fromOffset(Width, 0)

        TitleHolder.Size = UDim2.new(0, Width, 1, 0)
        RightWrapper.Size = UDim2.new(1, -Width - 57 - RightBarInset - 1, 1, -16)
        Tabs.Size = UDim2.new(0, Width, 1, -70)
        Container.Size = UDim2.new(1, -Width - 1, 1, -70)

        if WindowInfo.EnableCompacting then
            ApplyCompact()
        end
        if not IsCompact then
            LastExpandedWidth = Width
        end
    end

    function Window:ShowTabInfo(Name, Description)
        --// RichText is on by default, so the name can carry its own weight
        CurrentTabLabel.Text = `<b>{Name}</b>`

        Description = Description or ""
        CurrentTabDescription.Text = Description
        CurrentTabDescription.Visible = Description ~= ""

        CurrentTabInfo.Visible = true

        --// Keep the minimized card in step unless a subtitle was set explicitly
        if MiniSubtitle and not MiniSubtitleExplicit then
            Name = Name or ""
            MiniSubtitle.Text = Name
            MiniSubtitle.Visible = Name ~= ""
        end
    end

    function Window:HideTabInfo()
        CurrentTabInfo.Visible = false
    end

    function Window:AddTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil
        local Order = nil
        local Layout = nil
        local Tooltip = nil
        local DisabledTooltip = nil

        --// "Center"/"Single"/1 collapses the tab to one centered column; the
        --// default (nil/"Dual"/2) keeps the two-column split
        local function IsSingleLayout(Value): boolean
            if Value == 1 or Value == true then
                return true
            end
            if typeof(Value) == "string" then
                local Lowered = Value:lower()
                return Lowered == "single" or Lowered == "center" or Lowered == "centre" or Lowered == "one"
            end
            return false
        end

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
            Order = Info.Order
            Layout = Info.Layout
            if Info.SingleColumn ~= nil then
                Layout = Info.SingleColumn and "Single" or "Dual"
            end
            Tooltip = Info.Tooltip
            DisabledTooltip = Info.DisabledTooltip
        else
            Name = select(1, ...)
            Icon = select(2, ...)
            Description = select(3, ...)
            Order = select(4, ...)
        end

        if not tonumber(Order) then
            Order = #Tabs:GetChildren()
        end

        local SingleColumn = IsSingleLayout(Layout)

        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabContainer
        local TabCanvas
        local TabLeft
        local TabRight

        --// Sidebar sub tabs: the button and its nested list share a holder so the
        --// list can sit directly under the tab it belongs to
        local TabHolder
        local TabChevron
        local TabButtonInfo
        local SidebarList
        local SidebarListLayout
        local SidebarListTween
        local SidebarEntries = {}
        local Expanded = false

        Icon = Library:GetCustomIcon(Icon)
        do
            --// Per-tab wrapper: holds the tab button and, if sub tabs are added,
            --// their nested sidebar list. Order is applied here so the whole group
            --// (button + sub tabs) moves together and the list stays under its tab.
            TabHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = Order,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = Tabs,
            })
            New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TabHolder,
            })

            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                LayoutOrder = 0,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = TabHolder,
            })
            local ButtonPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, IsCompact and 6 or 11),
                PaddingLeft = UDim.new(0, IsCompact and 6 or 12),
                PaddingRight = UDim.new(0, IsCompact and 6 or 12),
                PaddingTop = UDim.new(0, IsCompact and 6 or 11),
                Parent = TabButton,
            })

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                    ImageTransparency = 0.5,
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = IsCompact and Enum.SizeConstraint.RelativeXY or Enum.SizeConstraint.RelativeYY,
                    Parent = TabButton,
                })
                Library:ApplyLucideIcon(TabIcon, Icon)
            end

            TabButtonInfo = {
                Label = TabLabel,
                Padding = ButtonPadding,
                Icon = TabIcon,
            }
            table.insert(Library.TabButtons, TabButtonInfo)

            --// Sidebar tooltip: defaults to the tab name and, via the "Sidebar"
            --// variant, only shows while the sidebar is compact (where the label is
            --// hidden), so it never redundantly repeats a label you can already read
            local TabTooltipText = typeof(Tooltip) == "string" and Tooltip or Name
            Library:AddTooltip(TabTooltipText, DisabledTooltip, TabButton, "Sidebar")

            --// Tab Canvas \\--
            TabCanvas = New("CanvasGroup", {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                GroupTransparency = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            --// Tab Container \\--
            TabContainer = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                Visible = true,
                Parent = TabCanvas,
            })

            TabLeft = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 0,
                Size = SingleColumn and UDim2.new(1, 0, 1, 0) or UDim2.new(0.5, -3, 1, 0),
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 2),
                Parent = TabLeft,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 2),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                Parent = TabLeft,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabLeft,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabLeft,
                })
            end

            TabRight = New("ScrollingFrame", {
                AnchorPoint = Vector2.new(1, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                Position = UDim2.fromScale(1, 0),
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 0,
                Size = UDim2.new(0.5, -3, 1, 0),
                Visible = not SingleColumn,
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 2),
                Parent = TabRight,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 2),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                Parent = TabRight,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabRight,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabRight,
                })
            end
        end

        --// Player banner: full-width cards stacked under the warning box and
        --// above the tab's two columns. Sibling of the scrolling columns, not a
        --// child, so it stays put while the tab's content scrolls under it.
        local PlayerBannerHolder = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 7),
            Size = UDim2.fromScale(1, 0),
            Visible = false,
            ZIndex = 3,
            Parent = TabContainer,
        })
        local PlayerBanners = {}

        --// Stacks the banner cards and reports how tall the whole banner is
        local function LayoutPlayerBanners(): number
            local Height = 0

            for _, Card in PlayerBanners do
                if not Card.Visible then
                    continue
                end

                Card.Holder.Position = UDim2.fromOffset(Card.Holder.Position.X.Offset, Height)
                Height += Card:GetTotalHeight() + 6
            end

            PlayerBannerHolder.Visible = Height > 0
            PlayerBannerHolder.Size = UDim2.new(1, 0, 0, math.max(0, Height - 6))

            return PlayerBannerHolder.Visible and PlayerBannerHolder.Size.Y.Offset or 0
        end

        --// Slots the banner in below whatever is already stacked above it
        local function ApplyPlayerBannerOffset(Offset: number): number
            local Height = LayoutPlayerBanners()
            if Height <= 0 then
                return Offset
            end

            PlayerBannerHolder.Position = UDim2.fromOffset(0, Offset + 7)
            return Offset + 7 + Height + 1
        end

        --// Tab Table \\--
        local Tab = {
            Name = Name,
            Description = Description,

            Connections = {},
            Destroyed = false,

            Window = Window,
            Canvas = TabCanvas,
            SingleColumn = SingleColumn,
            --// In single-column mode both "sides" point at the one column, so
            --// AddLeftGroupbox / AddRightGroupbox both land in it
            Sides = SingleColumn and {
                TabLeft,
                TabLeft,
            } or {
                TabLeft,
                TabRight,
            },
            WarningBox = {
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = "",
            },

            Groupboxes = {},
            Tabboxes = {},
            DependencyGroupboxes = {},

            Type = "Tab",
            SubTabs = {},
            ActiveSubTab = nil,
        }

        --// Warning Box \\--
        local WarningBoxHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 7),
            Size = UDim2.fromScale(1, 0),
            Visible = false,
            Parent = TabContainer,
        })

        local WarningBox
        local WarningBoxOutline
        local WarningBoxShadowOutline
        local WarningBoxScrollingFrame
        local WarningTitle
        local WarningStroke
        local WarningText
        do
            WarningBox = New("Frame", {
                BackgroundColor3 = Color3.fromRGB(127, 0, 0),
                Position = UDim2.fromOffset(2, 0),
                Size = UDim2.new(1, -5, 0, 0),
                Parent = WarningBoxHolder,
            })
            Library:AddToRegistry(WarningBox, {
                BackgroundColor3 = function()
                    return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
                end
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = WarningBox,
                })
            )
            WarningBoxOutline, WarningBoxShadowOutline = Library:AddOutline(WarningBox)
            Library:AddToRegistry(WarningBoxOutline, {
                Color = function()
                    return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
                end
            })
            Library:AddToRegistry(WarningBoxShadowOutline, {
                Color = function()
                    return Tab.WarningBox.IsNormal == true and Library.Scheme.DarkColor or Color3.fromRGB(85, 0, 0)
                end
            })

            WarningBoxScrollingFrame = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                Parent = WarningBox,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 4),
                Parent = WarningBoxScrollingFrame,
            })

            WarningTitle = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 14),
                Text = "",
                TextColor3 = Color3.fromRGB(255, 50, 50),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = WarningBoxScrollingFrame,
            })
            Library:AddToRegistry(WarningTitle, {
                TextColor3 = function()
                    return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
                end
            })

            WarningStroke = New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = Color3.fromRGB(169, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningTitle,
            })
            Library:AddToRegistry(WarningStroke, {
                Color = function()
                    return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)
                end
            })

            WarningText = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, -4, 0, 0),
                Text = "",
                TextSize = 14,
                TextWrapped = true,
                Parent = WarningBoxScrollingFrame,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
            })

            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = "DarkColor",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningText,
            })
        end

        --// Tab Handlers \\--
        function Tab:UpdateWarningBox(Info)
            if typeof(Info.IsNormal) == "boolean" then
                Tab.WarningBox.IsNormal = Info.IsNormal
            end
            if typeof(Info.LockSize) == "boolean" then
                Tab.WarningBox.LockSize = Info.LockSize
            end
            if typeof(Info.Visible) == "boolean" then
                Tab.WarningBox.Visible = Info.Visible
            end
            if typeof(Info.Title) == "string" then
                Tab.WarningBox.Title = Info.Title
            end
            if typeof(Info.Text) == "string" then
                Tab.WarningBox.Text = Info.Text
            end

            WarningBoxHolder.Visible = Tab.WarningBox.Visible
            WarningTitle.Text = Tab.WarningBox.Title
            WarningText.Text = Tab.WarningBox.Text
            Tab:Resize(true)

            WarningBox.BackgroundColor3 = Library.Registry[WarningBox].BackgroundColor3()
            WarningBoxShadowOutline.Color = Library.Registry[WarningBoxShadowOutline].Color()
            WarningBoxOutline.Color = Library.Registry[WarningBoxOutline].Color()
            WarningTitle.TextColor3 = Library.Registry[WarningTitle].TextColor3()
            WarningStroke.Color = Library.Registry[WarningStroke].Color()
        end

        function Tab:RefreshSides()
            local Offset = WarningBoxHolder.Visible and WarningBox.Size.Y.Offset + 8 or 0
            Offset = ApplyPlayerBannerOffset(Offset)

            for _, Side in Tab.Sides do
                Side.Position = UDim2.new(Side.Position.X.Scale, 0, 0, Offset)
                Side.Size = Tab.SingleColumn and UDim2.new(1, 0, 1, -Offset) or UDim2.new(0.5, -3, 1, -Offset)
            end

            for _, SubTab in Tab.SubTabs do
                SubTab:RefreshSides()
            end
        end

        function Tab:Resize(ResizeWarningBox: boolean?)
            if ResizeWarningBox then
                local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
                local _, YText = Library:GetTextBounds(
                    WarningText.Text,
                    Library.Scheme.Font,
                    WarningText.TextSize,
                    WarningText.AbsoluteSize.X
                )

                local YBox = 24 + YText
                if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
                    YBox = MaximumSize
                else
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
                end

                WarningText.Size = UDim2.new(1, -4, 0, YText)
                WarningBox.Size = UDim2.new(1, -5, 0, YBox + 4)
            end

            Tab:RefreshSides()
        end

        local function AddTabbox(self, Info)
            Info = Library:Validate(Info, Templates.Tabbox)
            local ParentObj = self
            --// Owner is the tab-like object holding this tabbox (Tab or SubTab)
            local Owner = if ParentObj.Type == "Groupbox" then ParentObj.Tab else ParentObj
            --// When the tabbox lives inside a groupbox, it renders flush (no inner
            --// card) so the tab strip reads as part of the groupbox header. Only a
            --// standalone tabbox (dropped straight onto a tab column) gets its own box.
            local InGroupbox = ParentObj.Type == "Groupbox"

            if typeof(Info.Side) == "string" then
                local lowerSide = string.lower(Info.Side)
                if not SideIndex[lowerSide] then
                    error(string.format("Invalid side: %s", Info.Side))
                end

                Info.Side = SideIndex[lowerSide]
            end

            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = if ParentObj.Type == "Groupbox"
                    then ParentObj.Container
                    else (Info.Side == 1 and Owner.Sides[1] or Owner.Sides[2]),
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = BoxHolder,
            })

            local TabboxHolder
            local TabboxButtons
            local TabboxUnderline

            do
                TabboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    --// Flush inside a groupbox; own card when standalone
                    BackgroundTransparency = InGroupbox and 1 or 0,
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                if not InGroupbox then
                    table.insert(
                        Library.Corners,
                        New("UICorner", {
                            CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                            Parent = TabboxHolder,
                        })
                    )
                    Library:AddOutline(TabboxHolder)
                end

                TabboxButtons = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                    ZIndex = 2,
                    Parent = TabboxHolder,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Parent = TabboxButtons,
                })

                --// Full-width separator under the tab row (header divider)
                Library:MakeLine(TabboxHolder, {
                    Position = UDim2.fromOffset(0, 34),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                --// Accent underline that slides to the active tab
                TabboxUnderline = New("Frame", {
                    AnchorPoint = Vector2.new(0, 1),
                    BackgroundColor3 = "AccentColor",
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.fromOffset(0, 2),
                    Visible = false,
                    ZIndex = 3,
                    Parent = TabboxHolder,
                })
            end

            local TotalTabs = 0
            local FirstTab
            local LastTab

            local Tabbox: any = {
                Type = "Tabbox",

                Connections = {},
                Destroyed = false,

                Visible = true,
                ActiveTab = nil,

                BoxHolder = BoxHolder,
                Holder = TabboxHolder,
                Tabs = {},

                ParentBox = if ParentObj.Type == "Groupbox" then ParentObj else nil,
            }

            --// Slide the accent underline under the given tab button. Uses the
            --// button's laid-out rect (flex-filled), so it stays correct for any
            --// number of tabs and any DPI scale.
            local function MoveUnderline(Button: GuiObject, Animate: boolean)
                if not (TabboxUnderline and Button) then
                    return
                end

                if TabboxButtons.AbsoluteSize.X <= 0 then
                    task.defer(MoveUnderline, Button, false)
                    return
                end

                local Scale = Library.DPIScale > 0 and Library.DPIScale or 1
                local RelX = (Button.AbsolutePosition.X - TabboxButtons.AbsolutePosition.X) / Scale
                local Width = Button.AbsoluteSize.X / Scale
                local Pad = 12

                local GoalPos = UDim2.fromOffset(math.floor(RelX + Pad), 35)
                local GoalSize = UDim2.fromOffset(math.max(0, math.floor(Width - Pad * 2)), 2)

                TabboxUnderline.Visible = true
                if Animate and Library.Animations and Library.Animations.SubTabUnderline ~= false then
                    TweenService:Create(TabboxUnderline, SUBTAB_SLIDE_TWEEN, {
                        Position = GoalPos,
                        Size = GoalSize,
                    }):Play()
                else
                    TabboxUnderline.Position = GoalPos
                    TabboxUnderline.Size = GoalSize
                end
            end

            --// Realign the underline when the row is resized (DPI, width, pop-out)
            table.insert(
                Tabbox.Connections,
                TabboxButtons:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    if Tabbox.ActiveTab then
                        MoveUnderline(Tabbox.ActiveTab.ButtonHolder, false)
                    end
                end)
            )

            function Tabbox:UpdateCorners()
                for _, Tab in Tabbox.Tabs do
                    Tab:UpdateCorners()
                end
            end

            function Tabbox:Resize()
                if Tabbox.ActiveTab then
                    Tabbox.ActiveTab:Resize()
                end
            end

            function Tabbox:AddTab(Name, IconName)
                TotalTabs = TotalTabs + 1
                local TabIndex = TotalTabs

                LastTab = TabIndex
                if not FirstTab then
                    FirstTab = TabIndex
                end

                local IsNameEmpty = Name == nil or Trim(tostring(Name)) == ""
                local TabStoringIndex = IsNameEmpty and tostring(TabIndex) or Name

                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(0, 34),
                    Text = "",
                    ZIndex = 2,
                    Parent = TabboxButtons,
                })

                local ButtonCorner = New("UICorner", {
                    TopLeftRadius = UDim.new(0, WindowInfo.CornerRadius),
                    TopRightRadius = UDim.new(0, WindowInfo.CornerRadius),
                    BottomRightRadius = UDim.new(0, 0),
                    BottomLeftRadius = UDim.new(0, 0),
                    Parent = Button,
                }); table.insert(Library.SpecificCorners, ButtonCorner)

                local ButtonContent = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(0, 16),
                    Parent = Button,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    Parent = ButtonContent,
                })

                local ButtonIcon
                local BoxIcon = Library:GetCustomIcon(IconName)
                if BoxIcon then
                    ButtonIcon = New("ImageLabel", {
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        ImageTransparency = 0.5,
                        Size = IsNameEmpty and UDim2.fromOffset(16, 16) or UDim2.fromOffset(18, 18),
                        Parent = ButtonContent,
                    })
                    Library:ApplyLucideIcon(ButtonIcon, BoxIcon)
                end

                local ButtonLabel
                if not IsNameEmpty then
                    ButtonLabel = New("TextLabel", {
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(0, 16),
                        Text = Name,
                        TextSize = 15,
                        TextTransparency = 0.5,
                        Parent = ButtonContent,
                    })
                end

                local Container = New("ScrollingFrame", {
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.fromScale(0, 0),
                    Position = UDim2.fromOffset(0, 35),
                    ScrollBarThickness = 0,
                    Size = UDim2.new(1, 0, 1, -35),
                    Visible = false,
                    Parent = TabboxHolder,
                })
                local List = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = Container,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = Container,
                })

                local Tab = {
                    Name = Name,

                    Connections = {},
                    Destroyed = false,

                    Name = Name,
                    ButtonHolder = Button,
                    Container = Container,
                    ButtonCorner = ButtonCorner,

                    Tab = Owner,
                    Elements = {},
                    DependencyBoxes = {},
                }

                function Tab:Show()
                    local PreviousActive = Tabbox.ActiveTab
                    if PreviousActive and PreviousActive ~= Tab then
                        PreviousActive:Hide()
                    end

                    if ButtonLabel then
                        ButtonLabel.TextTransparency = 0
                    end
                    if ButtonIcon then
                        ButtonIcon.ImageTransparency = 0
                    end

                    Container.Visible = true

                    Tabbox.ActiveTab = Tab
                    Tab:Resize()

                    --// Slide the underline to this tab
                    MoveUnderline(Button, true)

                    --// Smooth content switch: slide the container up into place.
                    --// Only on a real switch, so the initial build doesn't jump.
                    if PreviousActive and PreviousActive ~= Tab
                        and Library.Animations and Library.Animations.TabSwitch and not Tabbox.PoppedOut
                    then
                        Container.Position = UDim2.fromOffset(0, 45)
                        TweenService:Create(Container, Library.TabTransitionInfo, {
                            Position = UDim2.fromOffset(0, 35),
                        }):Play()
                    else
                        Container.Position = UDim2.fromOffset(0, 35)
                    end

                    Tabbox:RefreshPopOutPlaceholder()
                end

                function Tab:Hide()
                    if ButtonLabel then
                        ButtonLabel.TextTransparency = 0.5
                    end
                    if ButtonIcon then
                        ButtonIcon.ImageTransparency = 0.5
                    end
                    Container.Visible = false

                    if Tabbox.ActiveTab == Tab then
                        Tabbox.ActiveTab = nil
                    end
                end

                function Tab:Resize()
                    if Tabbox.ActiveTab ~= Tab then
                        return
                    end

                    local ContentSize = (List.AbsoluteContentSize.Y / Library.DPIScale) + 14
                    if Tabbox.PoppedOut then
                        ContentSize = math.min(ContentSize, GetPopOutBodyMaxHeight(Tabbox, 35))
                    end

                    TabboxHolder.Size = UDim2.new(1, 0, 0, ContentSize + 35)
                    if ParentObj.Type == "Groupbox" then
                        ParentObj:Resize()
                    end

                    --// Keep the underline aligned after reflows (e.g. search hides tabs)
                    MoveUnderline(Button, false)
                end

                function Tab:UpdateCorners()
                    local Radius = WindowInfo.CornerRadius

                    ButtonCorner.TopLeftRadius = UDim.new(0, TabIndex == FirstTab and Radius or 0)
                    ButtonCorner.TopRightRadius = UDim.new(0, TabIndex == LastTab and Radius or 0)
                end

                function Tab:Destroy()
                    Tab.Destroyed = true

                    if Tab.Connections then
                        for _, Connection in Tab.Connections do
                            Connection:Disconnect()
                        end
                    end

                    for _, Element in Tab.Elements do
                        if Element.Destroy then
                            Element:Destroy()
                        end
                    end

                    for _, SubDepbox in Tab.DependencyBoxes do
                        if SubDepbox.Destroy then
                            SubDepbox:Destroy()
                        end
                    end

                    if Container then
                        Container:Destroy()
                    end

                    if Button then
                        Button:Destroy()
                    end
                end

                --// Execution \\--
                if not Tabbox.ActiveTab then
                    Tab:Show()
                end

                Button.MouseButton1Click:Connect(Tab.Show)

                setmetatable(Tab, BaseGroupbox)

                Tabbox.Tabs[TabStoringIndex] = Tab
                Tabbox:UpdateCorners()

                return Tab, TabStoringIndex
            end

            Library:MakeBoxPopOut(Tabbox, {
                Enabled = Info.PopOut ~= false,

                Header = TabboxButtons,
                Children = function()
                    return { TabboxHolder }
                end,

                After = function()
                    if Tabbox.ActiveTab then
                        Tabbox.ActiveTab:Resize()
                    end
                    if ParentObj.Type == "Groupbox" then
                        ParentObj:Resize()
                    end
                end,
            })

            function Tabbox:Destroy()
                if Tabbox.PoppedOut then
                    Tabbox:SetPoppedOut(false)
                end

                Tabbox.Destroyed = true

                if Tabbox.Connections then
                    for _, Connection in Tabbox.Connections do
                        Connection:Disconnect()
                    end
                end

                for _, Tab in Tabbox.Tabs do
                    if Tab.Destroy then
                        Tab:Destroy()
                    end
                end

                if TabboxHolder then
                    TabboxHolder:Destroy()
                end

                if BoxHolder then
                    BoxHolder:Destroy()
                end
            end

            if Info.Name then
                Owner.Tabboxes[Info.Name] = Tabbox
            else
                table.insert(Owner.Tabboxes, Tabbox)
            end

            return Tabbox
        end

        Tab.AddTabbox = AddTabbox

        --// Deprecated - Use Tab:AddTabbox instead.
        function Tab:AddLeftTabbox(Name)
            return self:AddTabbox({ Side = 1, Name = Name })
        end

        --// Deprecated - Use Tab:AddTabbox instead.
        function Tab:AddRightTabbox(Name)
            return self:AddTabbox({ Side = 2, Name = Name })
        end

        function Tab:AddGroupbox(Info)
            Info = Library:Validate(Info, Templates.Groupbox)

            --// Owner is the tab-like object this groupbox belongs to (Tab or SubTab)
            local Owner = self or Tab

            if typeof(Info.Side) == "string" then
                local lowerSide = string.lower(Info.Side)
                if not SideIndex[lowerSide] then
                    error(string.format("Invalid side: %s", Info.Side))
                end

                Info.Side = SideIndex[lowerSide]
            end

            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                --// Owner.Sides routes to the tab's columns for a Tab, or the
                --// sub-tab's own columns for a SubTab (upstream hardcoded TabLeft/Right)
                Parent = (Info.Side == 1) and Owner.Sides[1] or Owner.Sides[2],
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                Parent = BoxHolder,
            })

            local GroupboxHolder

            local GroupboxTop
            local GroupboxLabel
            local GroupboxDescription

            local GroupboxContainer
            local GroupboxList

            local GroupboxCollapseArrow
            local GroupboxLine

            do
                GroupboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Size = UDim2.fromScale(1, 0),
                    Parent = BoxHolder,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = GroupboxHolder,
                    })
                )
                New("UIListLayout", {
                    Parent = GroupboxHolder,
                })
                Library:AddOutline(GroupboxHolder)

                GroupboxTop = New("Frame", {
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 0),
                    Parent = GroupboxHolder,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                    PaddingTop = UDim.new(0, 6),
                    Parent = GroupboxTop,
                })

                local BoxIcon = Library:GetCustomIcon(Info.IconName)
                if BoxIcon then
                    local GroupboxHeaderIcon = New("ImageLabel", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        ImageColor3 = BoxIcon.Custom and "WhiteColor" or "AccentColor",
                        Position = UDim2.fromScale(0, 0.5),
                        Size = UDim2.fromOffset(22, 22),
                        Parent = GroupboxTop,
                    })
                    Library:ApplyLucideIcon(GroupboxHeaderIcon, BoxIcon)
                end

                local RightInset = if Info.DisableCollapsing ~= true then 22 else 0
                local TextsFrame = New("Frame", {
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(BoxIcon and 24 or 0, 0),
                    Size = UDim2.new(1, -RightInset - (BoxIcon and 24 or 0), 0, 0),
                    Parent = GroupboxTop,
                })
                New("UIListLayout", {
                    Parent = TextsFrame,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                    PaddingTop = UDim.new(0, 3),
                    Parent = TextsFrame,
                })

                GroupboxLabel = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 0),
                    Text = Info.Name,
                    TextSize = 15,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = TextsFrame,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 1),
                    Parent = GroupboxLabel,
                })

                GroupboxDescription = New("TextLabel", {
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 0),
                    Text = Info.Description or "",
                    TextSize = 14,
                    TextTransparency = 0.5,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Visible = (Info.Description ~= nil),
                    Parent = TextsFrame,
                })

                GroupboxCollapseArrow = New("ImageButton", {
                    Visible = Info.DisableCollapsing ~= true,
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundTransparency = 1,
                    ImageColor3 = "WhiteColor",
                    Position = UDim2.fromScale(1, 0.5),
                    Size = UDim2.fromOffset(22, 22),
                    Parent = GroupboxTop,
                })
                if ArrowIcon then
                    Library:ApplyLucideIcon(GroupboxCollapseArrow, ArrowIcon, 180)
                end

                GroupboxLine = Library:MakeLine(GroupboxHolder, {
                    LayoutOrder = 1,
                    Size = UDim2.new(1, 0, 0, 1),
                })

                GroupboxContainer = New("ScrollingFrame", {
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.fromScale(0, 0),
                    LayoutOrder = 2,
                    ScrollBarThickness = 0,
                    Size = UDim2.fromScale(1, 0),
                    Parent = GroupboxHolder,
                })

                GroupboxList = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = GroupboxContainer,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = GroupboxContainer,
                })
            end

            local Groupbox: any = {
                Type = "Groupbox",
                Name = Info.Name,
                Description = Info.Description,

                Connections = {},
                Destroyed = false,

                Visible = true,
                Collapsed = false,

                BoxHolder = BoxHolder,
                Holder = GroupboxHolder,
                Container = GroupboxContainer,

                Tab = Owner,
                DependencyBoxes = {},
                Elements = {}
            }

            local ResizeTween
            local CollapseArrowTween

            function Groupbox:Resize()
                if ResizeTween then
                    StopTween(ResizeTween, true)
                    ResizeTween = nil
                end

                local TopSize = (GroupboxTop.AbsoluteSize.Y / Library.DPIScale)
                local ContainerSize = (GroupboxList.AbsoluteContentSize.Y / Library.DPIScale) + 14
                if Groupbox.PoppedOut then
                    ContainerSize = math.min(ContainerSize, GetPopOutBodyMaxHeight(Groupbox, TopSize + 1))
                end

                local TargetSize = UDim2.new(1, 0, 0, if Groupbox.Collapsed then TopSize else (TopSize + 1 + ContainerSize))
                GroupboxContainer.Size = UDim2.new(1, 0, 0, ContainerSize)
                GroupboxLine.Visible = not Groupbox.Collapsed

                if Library.Animations and Library.Animations.Groupbox then
                    local TweenInfo = Library.GroupboxTweenInfo or TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local Tween = TweenService:Create(GroupboxHolder, TweenInfo, { Size = TargetSize })
                    ResizeTween = Tween

                    local Connection; Connection = Library:GiveSignal(Tween.Completed:Once(function()
                        if Connection then
                            Connection:Disconnect()
                        end

                        if ResizeTween == Tween then
                            StopTween(ResizeTween, true)
                            ResizeTween = nil
                        end
                    end))

                    Tween:Play()
                else
                    GroupboxHolder.Size = TargetSize
                end
            end

            function Groupbox:SetDescription(Description: string | nil)
                GroupboxDescription.Text = Description or ""
                GroupboxDescription.Visible = (Description ~= nil)

                Groupbox:Resize()
            end

            function Groupbox:SetCollapsed(Collapsed: boolean)
                if Info.DisableCollapsing == true then return end
                Groupbox.Collapsed = Collapsed

                if CollapseArrowTween then
                    StopTween(CollapseArrowTween, true)
                    CollapseArrowTween = nil
                end

                local TargetRotation = if Collapsed then 0 else 180

                GroupboxContainer.Visible = not Collapsed
                if Library.Animations and Library.Animations.Groupbox then
                    local TweenInfo = Library.GroupboxTweenInfo or TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    local Tween = TweenService:Create(GroupboxCollapseArrow, TweenInfo, { Rotation = TargetRotation })
                    CollapseArrowTween = Tween

                    local Connection; Connection = Library:GiveSignal(Tween.Completed:Connect(function()
                        if Connection then
                            Connection:Disconnect()
                        end

                        if CollapseArrowTween == Tween then
                            StopTween(CollapseArrowTween, true)
                            CollapseArrowTween = nil
                        end
                    end))

                    Tween:Play()
                else
                    GroupboxCollapseArrow.Rotation = TargetRotation
                end

                Groupbox:Resize()
            end

            function Groupbox:ToggleCollapsed()
                if Info.DisableCollapsing == true then return end
                Groupbox:SetCollapsed(not Groupbox.Collapsed)
            end

            Library:MakeBoxPopOut(Groupbox, {
                Enabled = Info.PopOut ~= false,

                Header = GroupboxTop,
                Children = function()
                    local Children = {}
                    for _, Child in BoxHolder:GetChildren() do
                        if Child:IsA("GuiObject") and Child ~= Groupbox.PopOutPlaceholder then
                            table.insert(Children, Child)
                        end
                    end
                    return Children
                end,

                Before = function()
                    GroupboxCollapseArrow.Visible = false
                end,
                After = function()
                    GroupboxCollapseArrow.Visible = Info.DisableCollapsing ~= true
                    Groupbox:Resize()
                end
            })

            function Groupbox:Destroy()
                if Groupbox.PoppedOut then
                    Groupbox:SetPoppedOut(false)
                end

                Groupbox.Destroyed = true

                if ResizeTween then
                    StopTween(ResizeTween, true)
                    ResizeTween = nil
                end

                if CollapseArrowTween then
                    StopTween(CollapseArrowTween, true)
                    CollapseArrowTween = nil
                end

                if Groupbox.Connections then
                    for _, Connection in Groupbox.Connections do
                        Connection:Disconnect()
                    end
                end

                for _, Element in Groupbox.Elements do
                    if Element.Destroy then
                        Element:Destroy()
                    end
                end
                table.clear(Groupbox.Elements)

                for _, SubDepbox in Groupbox.DependencyBoxes do
                    if SubDepbox.Destroy then
                        SubDepbox:Destroy()
                    end
                end
                table.clear(Groupbox.DependencyBoxes)

                if GroupboxHolder then
                    GroupboxHolder:Destroy()
                end

                if BoxHolder then
                    BoxHolder:Destroy()
                end
            end

            function Groupbox:SetVisible(Visible: boolean)
                Groupbox.Visible = Visible
                BoxHolder.Visible = Visible
                SyncPopOutVisibility(Groupbox)

                if Visible == true and Library.Searching then
                    Library:UpdateSearch(Library.SearchText)
                end
            end

            function Groupbox:Show()
                Groupbox:SetVisible(true)
            end

            function Groupbox:Hide()
                Groupbox:SetVisible(false)
            end

            if Info.DisableCollapsing ~= true then
                GroupboxCollapseArrow.MouseButton1Click:Connect(function()
                    Groupbox:ToggleCollapsed()
                end)
            end

            Groupbox.AddTabbox = AddTabbox
            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:Resize()
            if Info.Name then
                Owner.Groupboxes[Info.Name] = Groupbox
            else
                table.insert(Owner.Groupboxes, Groupbox)
            end

            if Info.Visible == false then
                Groupbox:Hide()
            end

            if Info.DisableCollapsing ~= true and Info.Collapsed == true then
                Groupbox:SetCollapsed(true)
            end

            return Groupbox
        end

        --// Deprecated - Use Tab:AddGroupbox instead.
        function Tab:AddLeftGroupbox(Name, IconName, Visible, Collapsed, DisableCollapsing)
            return self:AddGroupbox({ Side = 1, Name = Name, IconName = IconName, Visible = Visible, Collapsed = Collapsed, DisableCollapsing = DisableCollapsing })
        end

        --// Deprecated - Use Tab:AddGroupbox instead.
        function Tab:AddRightGroupbox(Name, IconName, Visible, Collapsed, DisableCollapsing)
            return self:AddGroupbox({ Side = 2, Name = Name, IconName = IconName, Visible = Visible, Collapsed = Collapsed, DisableCollapsing = DisableCollapsing })
        end

        --// Sidebar sub tabs \\--
        --// Sub tabs are one feature: giving a tab sub tabs nests them under it in the
        --// sidebar as a collapsible list. The top row is still built underneath, since
        --// the buttons and the underline hang off it, but it is never shown.
        local function SidebarListHeight(): number
            return SidebarListLayout and SidebarListLayout.AbsoluteContentSize.Y or 0
        end

        local function ResizeSidebarList(Animate: boolean?)
            if not SidebarList then
                return
            end

            --// Stays open in a compact sidebar too; entries render as centered
            --// icon-only rows there instead of labelled ones
            local Open = Expanded
            local Target = Open and SidebarListHeight() or 0
            local Animated = Animate and Library.Animations and Library.Animations.SidebarSubTabs ~= false

            --// A toggle mid animation would otherwise leave two tweens fighting
            if SidebarListTween then
                StopTween(SidebarListTween, true)
                SidebarListTween = nil
            end

            --// Stays visible for the whole collapse: hiding it up front would play the
            --// tween on a frame nobody can see, which reads as the list snapping shut
            if Target > 0 then
                SidebarList.Visible = true
            end

            if Animated then
                SidebarListTween = TweenService:Create(SidebarList, Library.GroupboxTweenInfo, {
                    Size = UDim2.new(1, 0, 0, Target),
                })

                if Target == 0 then
                    local Connection
                    Connection = SidebarListTween.Completed:Connect(function(State: Enum.PlaybackState)
                        Connection:Disconnect()

                        --// Cancelled means something re-opened it on the way down
                        if State == Enum.PlaybackState.Completed and SidebarList.Size.Y.Offset == 0 then
                            SidebarList.Visible = false
                        end
                    end)
                end

                SidebarListTween:Play()
            else
                SidebarList.Size = UDim2.new(1, 0, 0, Target)
                SidebarList.Visible = Target > 0
            end

            if TabChevron then
                local Rotation = Open and 180 or 0

                if Animated then
                    TweenService:Create(TabChevron, Library.RotatingChevronTweenInfo, {
                        Rotation = Rotation,
                    }):Play()
                else
                    TabChevron.Rotation = Rotation
                end
            end
        end

        --// Built on the first AddSubTab, so tabs without sub tabs stay untouched
        local function EnsureSidebarList()
            if SidebarList then
                return
            end

            SidebarList = New("Frame", {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                LayoutOrder = 1,
                Size = UDim2.new(1, 0, 0, 0),
                Visible = false,
                Parent = TabHolder,
            })
            SidebarListLayout = New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = SidebarList,
            })

            --// Chevron doubles as a hit target, so it can expand without switching tabs
            local ChevronIcon = Library:GetIcon("chevron-down")
            TabChevron = New("ImageButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Image = ChevronIcon and ChevronIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = ChevronIcon and ChevronIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = ChevronIcon and ChevronIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 0.5,
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Visible = not IsCompact,
                ZIndex = 3,
                Parent = TabButton,
            })

            --// Give the chevron room so a long tab name cannot run under it
            TabLabel.Size = UDim2.new(1, -30 - 18, 1, 0)

            TabChevron.MouseButton1Click:Connect(function()
                Tab:SetExpanded(not Expanded)
            end)

            if TabButtonInfo then
                TabButtonInfo.Chevron = TabChevron
                TabButtonInfo.SidebarList = SidebarList
                --// ApplyCompact reaches the entries + reflow through these
                TabButtonInfo.SidebarEntries = SidebarEntries
                TabButtonInfo.RefreshSidebarList = ResizeSidebarList
            end

            --// The first tab is shown before it has any sub tabs, so if this is the
            --// open tab the list is born expanded rather than waiting for a switch
            if Library.ActiveTab == Tab then
                Expanded = true
            end

            --// The list height follows its contents while open
            Library:GiveSignal(SidebarListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if Expanded then
                    ResizeSidebarList(false)
                end
            end))
        end

        --// One row in the sidebar list, mirroring a sub tab
        local function CreateSidebarEntry(SubTab, SubName: string, SubIcon)
            EnsureSidebarList()

            if not SidebarList then
                return nil
            end

            local Entry = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                LayoutOrder = #SidebarEntries,
                Size = UDim2.new(1, 0, 0, 30),
                Text = "",
                Parent = SidebarList,
            })

            --// Accent bar marking the open sub tab
            local Marker = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = "AccentColor",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0.5, 0),
                Size = UDim2.fromOffset(2, 16),
                Parent = Entry,
            })
            table.insert(
                Library.PillCorners,
                New("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = Marker,
                })
            )

            --// The icon column is reserved whether or not this row has one, so every
            --// label starts at the same x. Indenting only the iconless rows made them
            --// read as a level shallower than their siblings.
            local TextOffset = SUBTAB_SIDEBAR_INDENT + SUBTAB_SIDEBAR_ICON_COLUMN

            local EntryIcon
            if SubIcon then
                EntryIcon = New("ImageLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    Image = SubIcon.Url,
                    ImageColor3 = SubIcon.Custom and "WhiteColor" or "FontColor",
                    ImageRectOffset = SubIcon.ImageRectOffset,
                    ImageRectSize = SubIcon.ImageRectSize,
                    ImageTransparency = SUBTAB_IDLE_TRANSPARENCY,
                    Position = UDim2.new(0, SUBTAB_SIDEBAR_INDENT, 0.5, 0),
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(14, 14),
                    Parent = Entry,
                })
            end

            local EntryLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(TextOffset, 0),
                Size = UDim2.new(1, -TextOffset - 10, 1, 0),
                Text = SubName,
                TextSize = 14,
                TextTransparency = SUBTAB_IDLE_TRANSPARENCY,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Entry,
            })

            local Handle = {
                Button = Entry,
                Label = EntryLabel,
                Active = false,
            }

            function Handle:SetActive(Value: boolean)
                Handle.Active = Value and true or false

                --// Registry keeps the colour right across theme changes
                Library:AddToRegistry(EntryLabel, { TextColor3 = Handle.Active and "AccentColor" or "FontColor" })
                EntryLabel.TextColor3 = Handle.Active and Library.Scheme.AccentColor or Library.Scheme.FontColor

                TweenService:Create(Entry, Library.TweenInfo, {
                    BackgroundTransparency = Handle.Active and 0.5 or 1,
                }):Play()
                TweenService:Create(Marker, Library.TweenInfo, {
                    BackgroundTransparency = Handle.Active and 0 or 1,
                }):Play()
                TweenService:Create(EntryLabel, Library.TweenInfo, {
                    TextTransparency = Handle.Active and 0 or SUBTAB_IDLE_TRANSPARENCY,
                }):Play()

                if EntryIcon then
                    TweenService:Create(EntryIcon, Library.TweenInfo, {
                        ImageTransparency = Handle.Active and 0 or SUBTAB_IDLE_TRANSPARENCY,
                    }):Play()
                end
            end

            --// Compact sidebar: center the icon and drop the label + indent marker
            --// so the sub tab still shows as a small icon under its parent
            function Handle:SetCompact(Compact: boolean)
                Handle.Compact = Compact and true or false

                if EntryIcon then
                    EntryIcon.AnchorPoint = Handle.Compact and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
                    EntryIcon.Position = Handle.Compact and UDim2.fromScale(0.5, 0.5)
                        or UDim2.new(0, SUBTAB_SIDEBAR_INDENT, 0.5, 0)
                    EntryIcon.Size = Handle.Compact and UDim2.fromOffset(15, 15) or UDim2.fromOffset(14, 14)
                    EntryLabel.Visible = not Handle.Compact
                else
                    --// Iconless row: keep the label but center it so it is not blank
                    EntryLabel.TextXAlignment = Handle.Compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
                    EntryLabel.Position = Handle.Compact and UDim2.fromOffset(0, 0) or UDim2.fromOffset(TextOffset, 0)
                    EntryLabel.Size = Handle.Compact and UDim2.new(1, 0, 1, 0) or UDim2.new(1, -TextOffset - 10, 1, 0)
                end

                Marker.Visible = not Handle.Compact
            end

            function Handle:SetVisible(Value: boolean)
                Entry.Visible = Value and true or false
                ResizeSidebarList(false)
            end

            function Handle:Destroy()
                local Index = table.find(SidebarEntries, Handle)
                if Index then
                    table.remove(SidebarEntries, Index)
                end

                Entry:Destroy()
                ResizeSidebarList(false)
            end

            Entry.MouseEnter:Connect(function()
                if Handle.Active then
                    return
                end

                TweenService:Create(EntryLabel, Library.TweenInfo, { TextTransparency = 0.2 }):Play()
            end)
            Entry.MouseLeave:Connect(function()
                if Handle.Active then
                    return
                end

                TweenService:Create(EntryLabel, Library.TweenInfo, {
                    TextTransparency = SUBTAB_IDLE_TRANSPARENCY,
                }):Play()
            end)

            Entry.MouseButton1Click:Connect(function()
                --// Selecting a sub tab implies opening the tab that owns it
                if Library.ActiveTab ~= Tab then
                    Tab:Show()
                end

                SubTab:Show()
            end)

            --// Sub tab hint; "Sidebar" variant shows only while compact, where
            --// only the icon is visible
            Library:AddTooltip(SubName, nil, Entry, "Sidebar")

            --// Match whatever mode the sidebar is currently in
            Handle:SetCompact(IsCompact)

            table.insert(SidebarEntries, Handle)
            ResizeSidebarList(false)

            return Handle
        end

        function Tab:IsExpanded(): boolean
            return Expanded
        end

        function Tab:SetExpanded(Value: boolean?)
            if Value == nil then
                Value = not Expanded
            end
            Expanded = Value and true or false

            ResizeSidebarList(true)
        end

        function Tab:ToggleExpanded()
            Tab:SetExpanded(not Expanded)
        end

        --// Sub Tabs \\--
        local SubTabBar
        local SubTabButtons
        local SubTabBarLayout
        local SubTabUnderline
        local SubTabUnderlineTween
        local SubTabUnderlineSettling = false
        local SubTabAlignment = "Center"
        --// Declared up here so CreateSubTabBar below can reach it
        local MoveSubTabUnderline

        local function CreateSubTabBar()
            if SubTabBar then
                return
            end

            SubTabBar = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, SUBTAB_BAR_HEIGHT),
                Position = UDim2.fromOffset(2, 0),
                ZIndex = 2,
                Parent = TabContainer,
            })
            --// The buttons get their own frame: a UIListLayout lays out every child,
            --// so the underline cannot live alongside them without being laid out too
            SubTabButtons = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Parent = SubTabBar,
            })
            SubTabBarLayout = New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment[SubTabAlignment],
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                Parent = SubTabButtons,
            })

            --// A single bar shared by every sub tab, so it can slide between them.
            --// Accent in the middle fading out at both ends, rather than a hard rule.
            SubTabUnderline = New("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                BackgroundColor3 = "AccentColor",
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.fromOffset(0, 1),
                Visible = false,
                Parent = SubTabBar,
            })
            New("UIGradient", {
                --// Font colour at the ends, accent in the middle
                Color = function()
                    return ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Library.Scheme.FontColor),
                        ColorSequenceKeypoint.new(0.5, Library.Scheme.AccentColor),
                        ColorSequenceKeypoint.new(1, Library.Scheme.FontColor),
                    })
                end,
                --// Extra keypoints either side of the middle round the falloff off,
                --// so the ends taper away instead of ramping linearly
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.2, 0.85),
                    NumberSequenceKeypoint.new(0.5, 0.1),
                    NumberSequenceKeypoint.new(0.8, 0.85),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = SubTabUnderline,
            })

            --// The buttons move when the window is resized, so follow them
            table.insert(
                Tab.Connections,
                SubTabBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    if Tab.ActiveSubTab then
                        SubTabUnderline.Visible = false
                        MoveSubTabUnderline(Tab.ActiveSubTab.Button)
                    end
                end)
            )

            --// The parent tab acts purely as a host once sub tabs exist
            TabLeft.Visible = false
            TabRight.Visible = false

            Tab:RefreshSides()
        end

        --// Slides the shared bar under Button; snaps when nothing was active yet
        function MoveSubTabUnderline(Button: GuiObject)
            if not SubTabUnderline then
                return
            end

            --// A button added this frame has not been laid out yet
            if Button.AbsoluteSize.X == 0 then
                task.defer(function()
                    if Tab.ActiveSubTab and Tab.ActiveSubTab.Button == Button then
                        MoveSubTabUnderline(Button)
                    end
                end)

                return
            end

            local Scale = Library.DPIScale
            local OffsetX = (Button.AbsolutePosition.X - SubTabBar.AbsolutePosition.X) / Scale
            local Width = Button.AbsoluteSize.X / Scale
            --// Sits inside the chip, a little above its bottom edge
            local Bottom = (Button.AbsolutePosition.Y + Button.AbsoluteSize.Y - SubTabBar.AbsolutePosition.Y) / Scale

            --// Inset to a fraction of the chip, centered under the text
            local LineWidth = math.floor(Width * SUBTAB_UNDERLINE_WIDTH)

            local Target = {
                Position = UDim2.fromOffset(
                    math.floor(OffsetX + (Width - LineWidth) / 2),
                    Bottom - SUBTAB_UNDERLINE_GAP
                ),
                Size = UDim2.fromOffset(LineWidth, 1),
            }

            if SubTabUnderlineTween then
                StopTween(SubTabUnderlineTween, true)
                SubTabUnderlineTween = nil
            end

            --// Nothing to slide from on the first show. On the very first load the
            --// buttons may not be laid out yet, so the geometry read above can be
            --// stale (the chip briefly reads as the whole bar's width), which drops
            --// the line wide and centered across every tab. Wait until the button's
            --// geometry holds steady for a frame before revealing, so it snaps into
            --// the right place instead of flashing in the middle.
            if not SubTabUnderline.Visible then
                if SubTabUnderlineSettling then
                    return
                end

                SubTabUnderlineSettling = true

                task.spawn(function()
                    local LastPos, LastSize
                    for _ = 1, 6 do
                        if not SubTabUnderline or not Tab.ActiveSubTab or Tab.ActiveSubTab.Button ~= Button then
                            SubTabUnderlineSettling = false
                            return
                        end

                        local Pos = Button.AbsolutePosition
                        local Sz = Button.AbsoluteSize
                        if Sz.X > 0 and LastPos and Pos == LastPos and Sz == LastSize then
                            break
                        end

                        LastPos, LastSize = Pos, Sz
                        RunService.RenderStepped:Wait()
                    end

                    SubTabUnderlineSettling = false

                    if not SubTabUnderline or SubTabUnderline.Visible or not Tab.ActiveSubTab or Tab.ActiveSubTab.Button ~= Button then
                        return
                    end

                    --// Recompute from the now-settled geometry and snap into place
                    local FinalOffsetX = (Button.AbsolutePosition.X - SubTabBar.AbsolutePosition.X) / Library.DPIScale
                    local FinalWidth = Button.AbsoluteSize.X / Library.DPIScale
                    local FinalBottom = (Button.AbsolutePosition.Y + Button.AbsoluteSize.Y - SubTabBar.AbsolutePosition.Y) / Library.DPIScale
                    local FinalLineWidth = math.floor(FinalWidth * SUBTAB_UNDERLINE_WIDTH)

                    SubTabUnderline.Position = UDim2.fromOffset(
                        math.floor(FinalOffsetX + (FinalWidth - FinalLineWidth) / 2),
                        FinalBottom - SUBTAB_UNDERLINE_GAP
                    )
                    SubTabUnderline.Size = UDim2.fromOffset(FinalLineWidth, 1)
                    SubTabUnderline.Visible = true
                end)

                return
            end

            if Library.Animations and Library.Animations.SubTabUnderline == false then
                SubTabUnderline.Position = Target.Position
                SubTabUnderline.Size = Target.Size

                return
            end

            SubTabUnderlineTween = TweenService:Create(SubTabUnderline, SUBTAB_SLIDE_TWEEN, Target)
            SubTabUnderlineTween:Play()
        end

        --// "Left" | "Center" | "Right"
        function Tab:SetSubTabAlignment(Alignment: string)
            assert(Enum.HorizontalAlignment[Alignment], "Alignment must be Left, Center or Right.")

            SubTabAlignment = Alignment
            if SubTabBarLayout then
                SubTabBarLayout.HorizontalAlignment = Enum.HorizontalAlignment[Alignment]
            end
        end

        function Tab:GetContentOffset()
            local Offset = WarningBoxHolder.Visible and WarningBox.Size.Y.Offset + 8 or 0
            Offset = ApplyPlayerBannerOffset(Offset)

            if SubTabBar and SubTabBar.Visible then
                SubTabBar.Position = UDim2.new(0, 2, 0, Offset)
                Offset += SUBTAB_BAR_HEIGHT + 6
            end

            return Offset
        end

        --// Full-width player card, spanning both columns at the top of the tab.
        --// The compact card is a groupbox element (Groupbox:AddPlayerInfo).
        function Tab:AddPlayerInfo(Idx, Info)
            if Tab.Destroyed then return nil end

            Info = Library:Validate(Info, Templates.PlayerInfo)

            local PlayerInfo = CreatePlayerCard(Info, PlayerBannerHolder, false, PLAYER_CARD_BANNER_INSET, function()
                Tab:RefreshSides()
            end)

            table.insert(PlayerBanners, PlayerInfo)
            Tab:RefreshSides()

            if Idx then
                Options[Idx] = PlayerInfo
            end

            function PlayerInfo:Destroy()
                PlayerInfo.Destroyed = true

                for _, Connection in PlayerInfo.Connections do
                    Connection:Disconnect()
                end

                if PlayerInfo.Holder then
                    PlayerInfo.Holder:Destroy()
                end

                local BannerIdx = table.find(PlayerBanners, PlayerInfo)
                if BannerIdx then
                    table.remove(PlayerBanners, BannerIdx)
                end

                Tab:RefreshSides()

                if Idx then
                    Options[Idx] = nil
                end
            end

            return PlayerInfo
        end

        function Tab:AddSubTab(...)
            local SubName = nil
            local SubIcon = nil

            if select("#", ...) == 1 and typeof(...) == "table" then
                local Info = select(1, ...)
                SubName = Info.Name or "SubTab"
                SubIcon = Info.Icon
            else
                SubName = select(1, ...) or "SubTab"
                SubIcon = select(2, ...)
            end

            CreateSubTabBar()

            SubIcon = Library:GetCustomIcon(SubIcon)

            --// Button \\--
            --// Measured rather than AutomaticSize: the button holds children sized
            --// relative to it (the underline), and auto sizing off those runs away.
            local IconWidth = SubIcon and SUBTAB_ICON_SIZE + 6 or 0
            local TextWidth = math.ceil(Library:GetTextBounds(SubName, Library.Scheme.Font, 15))

            --// The button itself is just the hit target and the layout item. The
            --// visible chip and its shadow are siblings inside it, because Roblox
            --// renders children above their parent, so a shadow cannot be a child
            --// of the thing it falls behind.
            local Button = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(TextWidth + IconWidth + 24, SUBTAB_BAR_HEIGHT - 8),
                Text = "",
                Parent = SubTabButtons,
            })

            --// Everything visible lives in here so hover can scale it as one piece,
            --// while the button keeps its size and the row never reflows
            local ButtonVisual = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1),
                Parent = Button,
            })
            --// Deliberately not in Library.Scales: that is the DPI scale, which would
            --// overwrite this every time SetDPIScale runs
            local ButtonScale = New("UIScale", {
                Scale = 1,
                Parent = ButtonVisual,
            })

            --// Two offset layers read as a soft shadow without needing an image
            local ButtonShadows = {}
            for Index = 1, 2 do
                local Shadow = New("Frame", {
                    BackgroundColor3 = "DarkColor",
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, Index),
                    Size = UDim2.fromScale(1, 1),
                    ZIndex = 1,
                    Parent = ButtonVisual,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                        Parent = Shadow,
                    })
                )

                table.insert(ButtonShadows, Shadow)
            end

            local Chip = New("Frame", {
                --// Lighter than MainColor so the active chip separates from the tab
                BackgroundColor3 = function()
                    return Library:GetBetterColor(Library.Scheme.MainColor, 10)
                end,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 2,
                Parent = ButtonVisual,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                    Parent = Chip,
                })
            )
            local ButtonStroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = 1,
                Parent = Chip,
            })

            --// Icon and label flow inside their own frame, so nothing else in the
            --// chip is swept into the row by the list layout
            local ButtonContent = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Parent = Chip,
            })
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 6),
                Parent = ButtonContent,
            })

            local ButtonIcon
            if SubIcon then
                ButtonIcon = New("ImageLabel", {
                    Image = SubIcon.Url,
                    ImageColor3 = SubIcon.Custom and "WhiteColor" or "AccentColor",
                    ImageRectOffset = SubIcon.ImageRectOffset,
                    ImageRectSize = SubIcon.ImageRectSize,
                    ImageTransparency = SUBTAB_IDLE_TRANSPARENCY,
                    ScaleType = Enum.ScaleType.Fit,
                    Size = UDim2.fromOffset(SUBTAB_ICON_SIZE, SUBTAB_ICON_SIZE),
                    Parent = ButtonContent,
                })
            end

            local ButtonLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(TextWidth, 16),
                Text = SubName,
                TextSize = 15,
                TextTransparency = SUBTAB_IDLE_TRANSPARENCY,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = ButtonContent,
            })

            --// Content \\--
            local SubCanvas = New("CanvasGroup", {
                BackgroundTransparency = 1,
                GroupTransparency = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = TabContainer,
            })

            local SubLeft = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 0,
                Size = SingleColumn and UDim2.new(1, 0, 1, 0) or UDim2.new(0.5, -3, 1, 0),
                Parent = SubCanvas,
            })
            local SubRight = New("ScrollingFrame", {
                AnchorPoint = Vector2.new(1, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                Position = UDim2.fromScale(1, 0),
                ScrollBarImageTransparency = 1,
                ScrollBarThickness = 0,
                Size = UDim2.new(0.5, -3, 1, 0),
                Visible = not SingleColumn,
                Parent = SubCanvas,
            })

            for _, Side in { SubLeft, SubRight } do
                New("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    Parent = Side,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 2),
                    PaddingLeft = UDim.new(0, 2),
                    PaddingRight = UDim.new(0, 2),
                    PaddingTop = UDim.new(0, 2),
                    Parent = Side,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = Side,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = Side,
                })
            end

            --// SubTab Table \\--
            local SubTab = {
                Type = "SubTab",
                Name = SubName,

                Connections = {},
                Destroyed = false,

                Window = Window,
                Tab = Tab,
                Canvas = SubCanvas,
                Button = Button,
                SingleColumn = SingleColumn,
                Sides = SingleColumn and {
                    SubLeft,
                    SubLeft,
                } or {
                    SubLeft,
                    SubRight,
                },

                Groupboxes = {},
                Tabboxes = {},
                DependencyGroupboxes = {},
            }

            SubTab.AddGroupbox = Tab.AddGroupbox
            SubTab.AddLeftGroupbox = Tab.AddLeftGroupbox
            SubTab.AddRightGroupbox = Tab.AddRightGroupbox
            SubTab.AddTabbox = AddTabbox
            SubTab.AddLeftTabbox = Tab.AddLeftTabbox
            SubTab.AddRightTabbox = Tab.AddRightTabbox

            function SubTab:RefreshSides()
                local Offset = Tab:GetContentOffset()

                for _, Side in SubTab.Sides do
                    Side.Position = UDim2.new(Side.Position.X.Scale, 0, 0, Offset)
                    Side.Size = SubTab.SingleColumn and UDim2.new(1, 0, 1, -Offset) or UDim2.new(0.5, -3, 1, -Offset)
                end
            end

            function SubTab:Resize()
                SubTab:RefreshSides()
            end

            function SubTab:Hover(Hovering)
                --// The squash applies to the active sub tab too: hovering the chip you
                --// are already on should still respond
                TweenService:Create(ButtonScale, SUBTAB_HOVER_TWEEN, {
                    Scale = Hovering and SUBTAB_HOVER_SCALE or 1,
                }):Play()

                if Tab.ActiveSubTab == SubTab then
                    return
                end

                TweenService:Create(Chip, Library.TweenInfo, {
                    BackgroundTransparency = Hovering and 0.45 or 1,
                }):Play()
                TweenService:Create(ButtonStroke, Library.TweenInfo, {
                    Transparency = Hovering and 0.7 or 1,
                }):Play()
                for Index, Shadow in ButtonShadows do
                    TweenService:Create(Shadow, Library.TweenInfo, {
                        BackgroundTransparency = Hovering and SUBTAB_SHADOW_TRANSPARENCY[Index] + 0.2 or 1,
                    }):Play()
                end
                TweenService:Create(ButtonLabel, Library.TweenInfo, {
                    TextTransparency = Hovering and 0.1 or SUBTAB_IDLE_TRANSPARENCY,
                }):Play()
                if ButtonIcon then
                    TweenService:Create(ButtonIcon, Library.TweenInfo, {
                        ImageTransparency = Hovering and 0.1 or SUBTAB_IDLE_TRANSPARENCY,
                    }):Play()
                end
            end

            function SubTab:Show()
                if Tab.ActiveSubTab == SubTab then
                    return
                end

                if Tab.ActiveSubTab then
                    Tab.ActiveSubTab:Hide()
                end

                Library:AddToRegistry(ButtonLabel, { TextColor3 = "AccentColor" })
                ButtonLabel.TextColor3 = Library.Scheme.AccentColor

                TweenService:Create(Chip, Library.TweenInfo, {
                    BackgroundTransparency = 0,
                }):Play()
                TweenService:Create(ButtonStroke, Library.TweenInfo, {
                    Transparency = 0.25,
                }):Play()
                for Index, Shadow in ButtonShadows do
                    TweenService:Create(Shadow, Library.TweenInfo, {
                        BackgroundTransparency = SUBTAB_SHADOW_TRANSPARENCY[Index],
                    }):Play()
                end
                TweenService:Create(ButtonLabel, Library.TweenInfo, {
                    TextTransparency = 0,
                }):Play()
                if ButtonIcon then
                    TweenService:Create(ButtonIcon, Library.TweenInfo, {
                        ImageTransparency = 0,
                    }):Play()
                end
                if SubTab.SidebarEntry then
                    SubTab.SidebarEntry:SetActive(true)
                end

                --// Set before moving the bar: a deferred move re-checks it
                Tab.ActiveSubTab = SubTab
                MoveSubTabUnderline(Button)

                SubTab:RefreshSides()
                Library:PlayTabAnimation(SubCanvas, true, nil, SUB_TAB_SWIPE_FROM)

                if Library.Searching then
                    Library:UpdateSearch(Library.SearchText)
                end
            end

            function SubTab:Hide()
                Library:AddToRegistry(ButtonLabel, { TextColor3 = "FontColor" })
                ButtonLabel.TextColor3 = Library.Scheme.FontColor

                TweenService:Create(Chip, Library.TweenInfo, {
                    BackgroundTransparency = 1,
                }):Play()
                TweenService:Create(ButtonStroke, Library.TweenInfo, {
                    Transparency = 1,
                }):Play()
                for _, Shadow in ButtonShadows do
                    TweenService:Create(Shadow, Library.TweenInfo, {
                        BackgroundTransparency = 1,
                    }):Play()
                end
                TweenService:Create(ButtonLabel, Library.TweenInfo, {
                    TextTransparency = SUBTAB_IDLE_TRANSPARENCY,
                }):Play()
                if ButtonIcon then
                    TweenService:Create(ButtonIcon, Library.TweenInfo, {
                        ImageTransparency = SUBTAB_IDLE_TRANSPARENCY,
                    }):Play()
                end

                if SubTab.SidebarEntry then
                    SubTab.SidebarEntry:SetActive(false)
                end

                Library:PlayTabAnimation(SubCanvas, false, nil, SUB_TAB_SWIPE_FROM)

                if Tab.ActiveSubTab == SubTab then
                    Tab.ActiveSubTab = nil
                end
            end

            function SubTab:SetVisible(Visible: boolean)
                Button.Visible = Visible

                if SubTab.SidebarEntry then
                    SubTab.SidebarEntry:SetVisible(Visible)
                end

                --// Hiding a hovered button never fires MouseLeave
                if not Visible then
                    ButtonScale.Scale = 1
                end

                if not Visible and Tab.ActiveSubTab == SubTab then
                    SubTab:Hide()

                    for _, Other in Tab.SubTabs do
                        if Other ~= SubTab and Other.Button.Visible then
                            Other:Show()
                            break
                        end
                    end

                    --// Hiding is only left unresolved when none are visible. The bar
                    --// has nothing to sit under, and the next Show snaps it back.
                    if not Tab.ActiveSubTab and SubTabUnderline then
                        SubTabUnderline.Visible = false
                    end
                end
            end

            function SubTab:Destroy()
                SubTab.Destroyed = true

                if SubTab.SidebarEntry then
                    SubTab.SidebarEntry:Destroy()
                    SubTab.SidebarEntry = nil
                end

                for _, Connection in SubTab.Connections do
                    Connection:Disconnect()
                end

                for _, Groupbox in SubTab.Groupboxes do
                    if Groupbox.Destroy then
                        Groupbox:Destroy()
                    end
                end
                table.clear(SubTab.Groupboxes)

                for _, Tabbox in SubTab.Tabboxes do
                    if Tabbox.Destroy then
                        Tabbox:Destroy()
                    end
                end
                table.clear(SubTab.Tabboxes)

                for _, DepGroupbox in SubTab.DependencyGroupboxes do
                    if DepGroupbox.Destroy then
                        DepGroupbox:Destroy()
                    end
                end

                Library:RemoveFromRegistry(ButtonLabel)
                SubCanvas:Destroy()
                Button:Destroy()

                if Tab.ActiveSubTab == SubTab then
                    Tab.ActiveSubTab = nil

                    --// The button it was sitting under is gone
                    if SubTabUnderline then
                        SubTabUnderline.Visible = false
                    end
                end
                Tab.SubTabs[SubName] = nil
            end

            --// Execution \\--
            Button.MouseEnter:Connect(function()
                SubTab:Hover(true)
            end)
            Button.MouseLeave:Connect(function()
                SubTab:Hover(false)
            end)
            Button.MouseButton1Click:Connect(function()
                SubTab:Show()
            end)

            Tab.SubTabs[SubName] = SubTab

            --// Mirror row in the sidebar, when the window asked for nested sub tabs
            SubTab.SidebarEntry = CreateSidebarEntry(SubTab, SubName, SubIcon)

            if not Tab.ActiveSubTab then
                SubTab:Show()
            else
                SubTab:RefreshSides()
            end

            return SubTab
        end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab == Tab then
                return
            end

            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 0,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end

            --// The header always names the open tab; the description is optional
            Window:ShowTabInfo(Name, Description)

            --// Opening a tab opens its list, so the sidebar shows one tab's sub tabs
            if SidebarList then
                Tab:SetExpanded(true)
            end

            Library:PlayTabAnimation(TabCanvas, true)
            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()

            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end

            --// Collapse on the way out so only the open tab's sub tabs are listed
            if SidebarList then
                Tab:SetExpanded(false)
            end

            Library:PlayTabAnimation(TabCanvas, false)
            Window:HideTabInfo()

            Library.ActiveTab = nil
        end

        function Tab:SetVisible(Visible: boolean)
            --// The holder carries the nested list, so hide that rather than the button
            TabHolder.Visible = Visible
            TabButton.Visible = Visible

            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        function Tab:SetOrder(NewOrder: number)
            Order = NewOrder
            --// Order lives on the wrapper so the tab's sub-tab list moves with it
            TabHolder.LayoutOrder = Order
        end

        function Tab:Destroy()
            Tab.Destroyed = true

            if Tab.Connections then
                for _, Connection in Tab.Connections do
                    Connection:Disconnect()
                end
            end

            for _, Groupbox in Tab.Groupboxes do
                if Groupbox.Destroy then
                    Groupbox:Destroy()
                end
            end
            table.clear(Tab.Groupboxes)

            for _, Tabbox in Tab.Tabboxes do
                if Tabbox.Destroy then
                    Tabbox:Destroy()
                end
            end
            table.clear(Tab.Tabboxes)

            for _, SubTab in Tab.SubTabs do
                if SubTab.Destroy then
                    SubTab:Destroy()
                end
            end
            table.clear(Tab.SubTabs)

            for _, DepGroupbox in Tab.DependencyGroupboxes do
                if DepGroupbox.Destroy then
                    DepGroupbox:Destroy()
                end
            end

            if TabCanvas then
                TabCanvas:Destroy()
            elseif TabContainer then
                TabContainer:Destroy()
            end

            if TabButton then
                for Index, Entry in Library.TabButtons do
                    if typeof(Entry) == "table" and Entry.Button == TabButton then
                        table.remove(Library.TabButtons, Index)
                        break
                    end
                end

                TabButton:Destroy()
            end

            Library.Tabs[Name] = nil
        end

        --// Execution \\--
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        --// Clicking the tab that is already open collapses its sub tab list, and
        --// expands it again. Tab:Show early returns on the open tab, so without this
        --// the row is dead once you are on it and only the small chevron closes it
        TabButton.MouseButton1Click:Connect(function()
            if Library.ActiveTab == Tab and next(Tab.SubTabs) ~= nil then
                Tab:ToggleExpanded()
                return
            end

            Tab:Show()
        end)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddKeyTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil
        local Order = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
            Order = Info.Order
        else
            Name = select(1, ...) or "Tab"
            Icon = select(2, ...)
            Description = select(3, ...)
            Order = select(4, ...)
        end

        if not tonumber(Order) then
            Order = #Tabs:GetChildren()
        end

        Icon = Icon or "key"

        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabCanvas
        local TabContainer

        Icon = if Icon == "key" then KeyIcon else Library:GetCustomIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                LayoutOrder = Order,
                Parent = Tabs,
            })
            local ButtonPadding = New("UIPadding", {
                PaddingBottom = UDim.new(0, IsCompact and 6 or 11),
                PaddingLeft = UDim.new(0, IsCompact and 6 or 12),
                PaddingRight = UDim.new(0, IsCompact and 6 or 12),
                PaddingTop = UDim.new(0, IsCompact and 6 or 11),
                Parent = TabButton,
            })

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = not IsCompact,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    ImageColor3 = Icon.Custom and "WhiteColor" or "AccentColor",
                    ImageTransparency = 0.5,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = IsCompact and Enum.SizeConstraint.RelativeXY or Enum.SizeConstraint.RelativeYY,
                    Parent = TabButton,
                })
                Library:ApplyLucideIcon(TabIcon, Icon)
            end

            table.insert(Library.TabButtons, {
                Label = TabLabel,
                Padding = ButtonPadding,
                Icon = TabIcon,
            })

            --// Tab Canvas \\--
            TabCanvas = New("CanvasGroup", {
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                GroupTransparency = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            --// Tab Container \\--
            TabContainer = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarThickness = 0,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                Visible = true,
                Parent = TabCanvas,
            })
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = TabContainer,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 1),
                Parent = TabContainer,
            })
        end

        --// Tab Table \\--
        local Tab = {
            Description = Description,
            IsKeyTab = true,

            Elements = {},

            Window = Window,
            Canvas = TabCanvas
        }

        function Tab:AddKeyBox(Callback)
            assert(typeof(Callback) == "function", "Callback must be a function")

            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0, 21),
                Parent = TabContainer,
            })

            local Box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                PlaceholderText = "Key",
                Size = UDim2.new(1, -71, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box,
            })
            local BoxStroke = New("UIStroke", {
                Color = "OutlineColor",
                Parent = Box,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Box,
                })
            )

            Box.Focused:Connect(function()
                Library.Registry[BoxStroke].Color = "AccentColor"
                TweenService:Create(BoxStroke, Library.TweenInfo, {
                    Color = Library.Scheme.AccentColor,
                }):Play()
            end)

            Box.FocusLost:Connect(function()
                Library.Registry[BoxStroke].Color = "OutlineColor"
                TweenService:Create(BoxStroke, Library.TweenInfo, {
                    Color = Library.Scheme.OutlineColor,
                }):Play()
            end)

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "MainColor",
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 63, 1, 0),
                Text = "Execute",
                TextSize = 14,
                TextTransparency = 0.4,
                Parent = Holder,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Button,
            })
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                    Parent = Button,
                })
            )

            Button.MouseEnter:Connect(function()
                TweenService:Create(Button, Library.TweenInfo, {
                    TextTransparency = 0,
                }):Play()
            end)

            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, Library.TweenInfo, {
                    TextTransparency = 0.4,
                }):Play()
            end)

            Button.InputBegan:Connect(function(Input)
                if not IsClickInput(Input) then
                    return
                end

                if not Library:MouseIsOverFrame(Button, Input.Position) then
                    return
                end

                Callback(Box.Text)
            end)
        end

        function Tab:Destroy()
            if TabCanvas then
                TabCanvas:Destroy()
            elseif TabContainer then
                TabContainer:Destroy()
            end

            if TabButton then
                for Index, Entry in Library.TabButtons do
                    if typeof(Entry) == "table" and Entry.Button == TabButton then
                        table.remove(Library.TabButtons, Index)
                        break
                    end
                end

                TabButton:Destroy()
            end

            Library.Tabs[Name] = nil
        end

        function Tab:SetOrder(NewOrder: number)
            Order = NewOrder
            TabButton.LayoutOrder = Order
        end

        function Tab:RefreshSides() end
        function Tab:Resize() end
        function Tab:UpdateCorners() end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab == Tab then
                return
            end

            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 0,
            }):Play()

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()

            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end

            Library:PlayTabAnimation(TabCanvas, true)

            --// The header always names the open tab; the description is optional
            Window:ShowTabInfo(Name, Description)

            Tab:RefreshSides()

            Library.ActiveTab = Tab

            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()

            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end

            Library:PlayTabAnimation(TabCanvas, false)
            Window:HideTabInfo()

            Library.ActiveTab = nil
        end

        function Tab:SetVisible(Visible: boolean)
            TabButton.Visible = Visible

            if not Visible and Library.ActiveTab == Tab then
                Tab:Hide()
            end
        end

        --// Execution \\--
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Tab.Container = TabContainer
        setmetatable(Tab, BaseGroupbox)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddDialog(Idx, Info)
        Info = Library:Validate(Info, Templates.Dialog)

        local DialogFrame
        local DialogOverlay
        local DialogContainer
        local ButtonsHolder
        local FooterButtonsList = {}

        DialogOverlay = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = "DarkColor",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Active = false,
            ZIndex = 9000,
            Visible = true,
            Parent = MainFrame,
        })
        TweenService:Create(DialogOverlay, Library.TweenInfo, {
            BackgroundTransparency = 0.5,
        }):Play()

        DialogFrame = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "BackgroundColor",
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(300, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 1,
            Parent = DialogOverlay,
        })
        table.insert(
            Library.Corners,
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius),
                Parent = DialogFrame,
            })
        )
        Library:AddOutline(DialogFrame)

        local InnerContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 2,
            Parent = DialogFrame,
        })
        local DialogScale = New("UIScale", {
            Scale = 0.95,
            Parent = DialogFrame,
        })
        TweenService:Create(DialogScale, Library.TweenInfo, {
            Scale = 1
        }):Play()
        local _InnerPadding = New("UIPadding", {
            PaddingBottom = UDim.new(0, 15),
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            Parent = InnerContainer,
        })
        local _InnerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = InnerContainer,
        })

        local HeaderContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 2,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = HeaderContainer,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            Parent = HeaderContainer,
        })

        local TitleRow = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 1,
            ZIndex = 2,
            Parent = HeaderContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TitleRow,
        })

        if Info.Icon then
            local ParsedIcon = Library:GetCustomIcon(Info.Icon)
            if ParsedIcon then
                local IconImg = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(16, 16),
                    ImageColor3 = Info.TitleColor or "FontColor",
                    LayoutOrder = 1,
                    ZIndex = 2,
                    Parent = TitleRow,
                })
                Library:ApplyLucideIcon(IconImg, ParsedIcon)
            end
        end

        local TitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Title,
            TextSize = 18,
            TextColor3 = Info.TitleColor or "FontColor",
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            ZIndex = 2,
            Parent = TitleRow,
        })

        local DescriptionLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = Info.Description,
            TextSize = 14,
            TextTransparency = Info.DescriptionColor and 0 or 0.2,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Info.DescriptionColor or "FontColor",
            TextWrapped = true,
            LayoutOrder = 2,
            ZIndex = 2,
            Parent = HeaderContainer,
        })

        DialogContainer = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 4,
            ZIndex = 2,
            Parent = InnerContainer,
        })
        local _DialogContainerLayout = New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DialogContainer,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            Parent = DialogContainer,
        })

        local _Sep2 = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            LayoutOrder = 5,
            ZIndex = 2,
            Parent = InnerContainer,
        })

        ButtonsHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 6,
            ZIndex = 2,
            Parent = InnerContainer,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Wraps = true,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ButtonsHolder,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            Parent = ButtonsHolder,
        })

        local Dialog = {
            Destroyed = false,
            Elements = {},
            Container = DialogContainer,
            OutsideClickDismiss = Info.OutsideClickDismiss,
        }

        function Dialog:Resize()
            local MaxWidth = MainFrame.AbsoluteSize.X * 0.75
            local MinWidth = 400

            local TotalButtonWidth = 0
            local ButtonCount = 0
            local HasButtons = false

            for _, BtnWrap in FooterButtonsList do
                HasButtons = true
                ButtonCount = ButtonCount + 1
                TotalButtonWidth = TotalButtonWidth + BtnWrap.Container.Size.X.Offset
            end

            local TargetWidth = MinWidth
            if HasButtons then
                local RequiredWidth = TotalButtonWidth + ((ButtonCount - 1) * 8) + 30
                TargetWidth = math.max(MinWidth, math.min(RequiredWidth, MaxWidth))
            end

            DialogFrame.Size = UDim2.fromOffset(TargetWidth, 0)

            local _DescX, DescY = Library:GetTextBounds(DescriptionLabel.Text, Library.Scheme.Font, 14, TargetWidth - 30)
            DescriptionLabel.Size = UDim2.new(1, 0, 0, DescY)

            local HasElements = false
            for _, v in DialogContainer:GetChildren() do
                if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
                    HasElements = true
                    break
                end
            end
            DialogContainer.Visible = HasElements

            ButtonsHolder.Visible = HasButtons
            _Sep2.Visible = HasButtons
        end

        function Dialog:SetTitle(Title)
            TitleLabel.Text = Title
            Dialog:Resize()
        end

        function Dialog:SetDescription(Description)
            DescriptionLabel.Text = Description
            Dialog:Resize()
        end

        function Dialog:Dismiss()
            if Dialog.Destroyed then
                return
            end

            Dialog.Destroyed = true

            if Library.ActiveDialog == Dialog then
                Library.ActiveDialog = nil
            end

            for Index = #Dialog.Elements, 1, -1 do
                local Element = Dialog.Elements[Index]
                if Element and Element.Destroy then
                    Element:Destroy()
                end
            end
            table.clear(Dialog.Elements)

            local CloseTween = TweenService:Create(DialogScale, Library.TweenInfo, { Scale = 0.95 })
            TweenService:Create(DialogOverlay, Library.TweenInfo, { BackgroundTransparency = 1 }):Play()
            CloseTween:Play()

            task.delay(Library.TweenInfo.Time, function()
                DialogOverlay:Destroy()
            end)
            Library.Dialogues[Idx] = nil
        end

        DialogOverlay.MouseButton1Click:Connect(function()
            if Info.OutsideClickDismiss then
                Dialog:Dismiss()
            end
        end)

        function Dialog:RemoveFooterButton(ButtonIdx)
            if FooterButtonsList[ButtonIdx] then
                FooterButtonsList[ButtonIdx].Container:Destroy()
                FooterButtonsList[ButtonIdx] = nil
            end
        end

        function Dialog:SetButtonDisabled(ButtonIdx, Disabled)
            if FooterButtonsList[ButtonIdx] and type(FooterButtonsList[ButtonIdx].SetDisabled) == "function" then
                FooterButtonsList[ButtonIdx]:SetDisabled(Disabled)
            end
        end

        function Dialog:SetButtonOrder(ButtonIdx, Order)
            if FooterButtonsList[ButtonIdx] and FooterButtonsList[ButtonIdx].Container then
                FooterButtonsList[ButtonIdx].Container.LayoutOrder = Order
            end
        end

        function Dialog:AddFooterButton(ButtonIdx, ButtonInfo)
            Dialog:RemoveFooterButton(ButtonIdx)

            local WaitTime = ButtonInfo.WaitTime or 0

            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                LayoutOrder = ButtonInfo.Order or 0,
                ZIndex = 2,
                Parent = ButtonsHolder,
            })

            local BtnColor = "MainColor"
            local BtnOutline = "OutlineColor"
            local Variant = ButtonInfo.Variant or "Primary"

            if Variant == "Primary" then
                BtnColor = "FontColor"
                BtnOutline = "FontColor"
            elseif Variant == "Secondary" then
                BtnColor = "MainColor"
                BtnOutline = "OutlineColor"
            elseif Variant == "Destructive" then
                BtnColor = "DestructiveColor"
                BtnOutline = "DestructiveColor"
            elseif Variant == "Ghost" then
                BtnColor = "BackgroundColor"
                BtnOutline = "BackgroundColor"
            end

            local TextBtn = New("TextButton", {
                BackgroundColor3 = BtnColor,
                BorderColor3 = BtnOutline,
                BackgroundTransparency = WaitTime > 0 and 0.5 or 0,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                ZIndex = 2,
                Parent = ButtonContainer,
            })
            Library:AddOutline(TextBtn)
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = TextBtn
                })
            )

            local _BtnPadding = New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = TextBtn,
            })

            local TextColor = Library.Scheme.FontColor
            if Variant == "Primary" then
                TextColor = Library.Scheme.BackgroundColor
            elseif Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end

            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or ButtonIdx,
                TextColor3 = TextColor,
                TextTransparency = WaitTime > 0 and 0.5 or 0,
                TextSize = 14,
                ZIndex = 2,
                Parent = TextBtn,
            })

            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local ProgressBar
            if WaitTime > 0 then
                ProgressBar = New("Frame", {
                    BackgroundColor3 = "AccentColor",
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 1, -2),
                    Size = UDim2.new(0, 0, 0, 2),
                    ZIndex = 2,
                    Parent = TextBtn,
                })
                table.insert(
                    Library.Corners,
                    New("UICorner", {
                        CornerRadius = UDim.new(0, Library.CornerRadius),
                        Parent = ProgressBar
                    })
                )
            end

            local IsActive = WaitTime <= 0

            local ButtonWrap = {
                Container = ButtonContainer,
                SetDisabled = function(self, Disabled)
                    IsActive = not Disabled
                    if Disabled then
                        TweenService:Create(TextBtn, Library.TweenInfo, { BackgroundTransparency = 0.5 }):Play()
                        TweenService:Create(BtnLabel, Library.TweenInfo, { TextTransparency = 0.5 }):Play()
                    else
                        TweenService:Create(TextBtn, Library.TweenInfo, { BackgroundTransparency = 0 }):Play()
                        TweenService:Create(BtnLabel, Library.TweenInfo, { TextTransparency = 0 }):Play()
                    end
                end
            }

            local ActiveColor = typeof(BtnColor) == "Color3" and BtnColor or Library.Scheme[BtnColor]
            local HoverColor = Variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(ActiveColor, 10)

            TextBtn.MouseEnter:Connect(function()
                if not IsActive then return end
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = HoverColor
                }):Play()
            end)
            TextBtn.MouseLeave:Connect(function()
                if not IsActive then return end
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = ActiveColor
                }):Play()
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if not IsActive then return end
                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Dialog)
                end
                if Info.AutoDismiss then
                    Dialog:Dismiss()
                end
            end)

            if WaitTime > 0 then
                TweenService:Create(ProgressBar, TweenInfo.new(WaitTime, Enum.EasingStyle.Linear), {
                    Size = UDim2.new(1, 0, 0, 2)
                }):Play()

                task.delay(WaitTime, function()
                    ButtonWrap:SetDisabled(false)
                    if ProgressBar then
                        TweenService:Create(ProgressBar, Library.TweenInfo, {
                            BackgroundTransparency = 1
                        }):Play()
                    end
                end)
            end

            FooterButtonsList[ButtonIdx] = ButtonWrap
        end

        for BIdx, BInfo in Info.FooterButtons do
            if type(BIdx) == "number" and BInfo.Id then BIdx = BInfo.Id end
            Dialog:AddFooterButton(BIdx, BInfo)
        end

        setmetatable(Dialog, BaseGroupbox)
        Library.Dialogues[Idx] = Dialog

        Dialog:Resize()

        Library.ActiveDialog = Dialog
        return Dialog
    end

    local GuiProperties = { "BackgroundTransparency" }
    local ImageProperties = { "BackgroundTransparency", "ImageTransparency" }
    local TextProperties = { "BackgroundTransparency", "TextTransparency" }
    local StrokeProperties = { "Transparency" }

    local function FadeInstance(Desc, Properties)
        local Cache = TransparencyCache[Desc]
        if not Cache then
            Cache = {}
            TransparencyCache[Desc] = Cache
        end

        for _, Prop in Properties do
            if not Library.Toggled then
                Cache[Prop] = Desc[Prop]
            end

            if Cache[Prop] ~= nil and Cache[Prop] ~= 1 then
                TweenService:Create(Desc, Library.WindowAnimationInfo, {
                    [Prop] = Library.Toggled and Cache[Prop] or 1,
                }):Play()
            end
        end
    end

    --// Which of the two shells is on screen depends on both the toggle and whether
    --// the window is currently minimized to its pill
    function ApplyWindowVisibility()
        MainFrame.Visible = Library.Toggled and not Minimized

        if MiniFrame then
            MiniFrame.Visible = Library.Toggled and Minimized
        end
    end

    function Window:Toggle(Value: boolean?)
        if Fading then
            return
        end

        if Library.ActiveLoading then
            if Value == true then
                return
            end

            if not Library.Toggled then
                return
            end
        end

        if typeof(Value) == "boolean" then
            Library.Toggled = Value
        else
            Library.Toggled = not Library.Toggled
        end

        if Library.Animations and Library.Animations.ToggleWindow == true then
            local FadeTime = Library.WindowAnimationInfo.Time
            Fading = true

            if Library.Toggled and not Minimized then
                MainFrame.Visible = true
            end

            if Library.Toggled then
                FadeInstance(MainFrame, { "BackgroundTransparency" })
                task.wait(FadeTime / 2)
            else
                task.delay(FadeTime / 2, FadeInstance, MainFrame, { "BackgroundTransparency" })
            end

            for _, Instance in MainFrame:GetDescendants() do
                if Instance == TopBar then
                    continue
                end

                if Instance:IsA("GuiObject") then
                    local ClassName = Instance.ClassName
                    if ClassName == "ImageLabel" or ClassName == "ImageButton" then
                        FadeInstance(Instance, ImageProperties)
                    elseif ClassName == "TextLabel" or ClassName == "TextBox" or ClassName == "TextButton" then
                        FadeInstance(Instance, TextProperties)
                    else
                        FadeInstance(Instance, GuiProperties)
                    end
                elseif Instance.ClassName == "UIStroke" then
                    FadeInstance(Instance, StrokeProperties)
                end
            end

            task.delay(FadeTime, function()
                ApplyWindowVisibility()
                Fading = false
            end)
        else
            ApplyWindowVisibility()
        end

        if WindowInfo.UnlockMouseWhileOpen then
            ModalElement.Modal = Library.Toggled
        end

        if Library.Toggled and not Library.IsMobile then
            local ShowCursorBinding = Library.ShowCursorBinding
            Library.OriginalMouseIconEnabled = UserInputService.MouseIconEnabled

            pcall(function() RunService:UnbindFromRenderStep(ShowCursorBinding) end)
            RunService:BindToRenderStep(ShowCursorBinding, Enum.RenderPriority.Last.Value, function()
                UserInputService.MouseIconEnabled = not Library.ShowCustomCursor

                Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                Cursor.Visible = Library.ShowCustomCursor

                if Library.Unloaded == true or not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
                    RestoreMouseIcon()
                end
            end)
        elseif not Library.Toggled then
            RestoreMouseIcon()
            TooltipLabel.Visible = false

            for _, Option in Library.Options do
                if Option.Type == "ColorPicker" then
                    Option.ColorMenu:Close()
                    Option.ContextMenu:Close()
                elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                    Option.Menu:Close()
                end
            end
        end
    end

    function Library:Toggle(Value: boolean?)
        return Window:Toggle(Value)
    end

    if WindowInfo.Minimizable and WindowInfo.MinimizeKeybind then
        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject, Processed: boolean)
            if Processed or Library.Unloaded or not Library.Toggled then
                return
            end
            if Input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end
            if Input.KeyCode ~= WindowInfo.MinimizeKeybind then
                return
            end
            --// Never fire while the user is typing somewhere
            if UserInputService:GetFocusedTextBox() then
                return
            end

            Window:ToggleMinimized()
        end))
    end

    if WindowInfo.EnableSidebarResize then
        local Threshold = (WindowInfo.MinSidebarWidth + WindowInfo.SidebarCompactWidth) * WindowInfo.SidebarCollapseThreshold
        local StartPos, StartWidth
        local Dragging = false
        local Changed

        local SidebarGrabber = New("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0, 8, 1, 0),
            Text = "",
            Parent = DividerLine,
        })
        SidebarGrabber.MouseEnter:Connect(function()
            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library:GetLighterColor(Library.Scheme.OutlineColor),
            }):Play()
        end)
        SidebarGrabber.MouseLeave:Connect(function()
            if Dragging then
                return
            end
            TweenService:Create(DividerLine, Library.TweenInfo, {
                BackgroundColor3 = Library.Scheme.OutlineColor,
            }):Play()
        end)

        SidebarGrabber.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) then
                return
            end

            Library.CantDragForced = true

            StartPos = Input.Position
            StartWidth = Window:GetSidebarWidth()
            Dragging = true

            Changed = Input.Changed:Connect(function()
                if Input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Library.CantDragForced = false
                TweenService:Create(DividerLine, Library.TweenInfo, {
                    BackgroundColor3 = Library.Scheme.OutlineColor,
                }):Play()

                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end
            end)
        end)

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
            if not Library.Toggled or not (ScreenGui and ScreenGui.Parent) then
                Dragging = false
                if Changed and Changed.Connected then
                    Changed:Disconnect()
                    Changed = nil
                end

                return
            end

            if Dragging and IsHoverInput(Input) then
                local Delta = Input.Position - StartPos
                local Width = StartWidth + Delta.X

                if WindowInfo.DisableCompactingSnap then
                    Window:SetSidebarWidth(Width)
                    return
                end

                if Width > Threshold then
                    Window:SetSidebarWidth(math.max(Width, WindowInfo.MinSidebarWidth))
                else
                    Window:SetSidebarWidth(WindowInfo.SidebarCompactWidth)
                end
            end
        end))
    end

    Window:SetAlwaysOnTop(WindowInfo.AlwaysOnTop)
    if WindowInfo.EnableCompacting and WindowInfo.SidebarCompacted then
        Window:SetSidebarWidth(WindowInfo.SidebarCompactWidth)
    end
    if WindowInfo.AutoShow and not Library.ActiveLoading then
        task.spawn(Library.Toggle)
    end

    if Library.IsMobile then
        local ToggleButton = Library:AddDraggableButton("Toggle", function()
            Library:Toggle()
        end, true, true)

        local LockButton = Library:AddDraggableButton("Lock", function(self)
            Library.CantDragForced = not Library.CantDragForced
            self:SetText(Library.CantDragForced and "Unlock" or "Lock")
        end, true, true)

        if WindowInfo.MobileButtonsSide == "Right" then
            ToggleButton.Button.AnchorPoint = Vector2.new(1, 0)
            ToggleButton.Button.Position = UDim2.new(1, -6, 0, 6)

            LockButton.Button.AnchorPoint = Vector2.new(1, 0)
            LockButton.Button.Position = UDim2.new(1, -(ToggleButton.Button.Size.X.Offset + 12), 0, 6)
        else
            ToggleButton.Button.AnchorPoint = Vector2.new(0, 0)
            ToggleButton.Button.Position = UDim2.fromOffset(6, 6)

            LockButton.Button.AnchorPoint = Vector2.new(0, 0)
            LockButton.Button.Position = UDim2.fromOffset(ToggleButton.Button.Size.X.Offset + 12, 6)
        end

        if WindowInfo.ShowMobileButtons == false then
            ToggleButton.Button.Visible = false
            LockButton.Button.Visible = false
        end
    end

    --// Execution \\--
    Library:GiveSignal(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Library:UpdateSearch(SearchBox.Text)
    end))

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if Library.Unloaded then
            return
        end

        if Input.KeyCode == Enum.KeyCode.Escape then
            -- Releasing focus from a text input takes priority and never toggles the window --
            local FocusedBox = UserInputService:GetFocusedTextBox()
            if FocusedBox then
                FocusedBox:ReleaseFocus()
                return
            end

            -- Dismiss the topmost dialog before closing any open menu --
            if Library.ActiveDialog and Library.ActiveDialog.OutsideClickDismiss ~= false then
                Library.ActiveDialog:Dismiss()
                return
            end

            if CurrentMenu then
                CurrentMenu:Close()
                return
            end

            return
        end

        if UserInputService:GetFocusedTextBox() then
            return
        end

        if Input.KeyCode == Library.ToggleKeybind then
            Library:Toggle()
        end

        if Library.NotificationHistoryKeybind and Input.KeyCode == Library.NotificationHistoryKeybind then
            Library:ToggleNotificationHistory()
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    Window.MainFrame = MainFrame
    Library.Window = Window

    --// AutoMinimize: collapse the window to its pill once, right after it is built,
    --// so a freshly executed script starts out of the way. Only meaningful when the
    --// window can actually minimize (MiniFrame exists).
    if WindowInfo.AutoMinimize and WindowInfo.Minimizable then
        Window:SetMinimized(true)
    end

    --// Glow stays opt-in: only build it when explicitly requested via config.
    if WindowInfo.Glow then
        Window:SetGlow(true)
    end

    return Window
end

function Library:CreateLoading(LoadingInfo)
    if Library.ActiveLoading then
        warn("Loading GUI already exists, you cannot create multiple Loading GUIs.")
        return Library.ActiveLoading
    end

    LoadingInfo = Library:Validate(LoadingInfo, Templates.Loading)

    local Loading = {
        CurrentStep = LoadingInfo.CurrentStep,
        TotalSteps = LoadingInfo.TotalSteps,

        ShowSidebar = LoadingInfo.ShowSidebar,
        AutoResizeHeight = LoadingInfo.AutoResizeHeight,
        AlwaysOnTop = LoadingInfo.AlwaysOnTop,

        IsError = false,
        Destroyed = false,

        WindowWidth = LoadingInfo.WindowWidth,
        WindowHeight = LoadingInfo.WindowHeight,
        BaseWindowHeight = LoadingInfo.WindowHeight,
        WindowErrorHeight = LoadingInfo.WindowHeight,

        ContentWidth = LoadingInfo.ContentWidth,
        SidebarWidth = LoadingInfo.SidebarWidth,
    }

    --// ScreenGui \\--
    local ScreenGui = New("ScreenGui", {
        Name = "ObsidianLoading",
        DisplayOrder = 999,
        ResetOnSpawn = false
    })
    ParentUI(ScreenGui)
    Loading.ScreenGui = ScreenGui
    SetAlwaysOnTop(ScreenGui, LoadingInfo.AlwaysOnTop)

    ScreenGui.DescendantRemoving:Connect(function(Instance)
        task.defer(function()
            if Instance.Parent and Instance:IsDescendantOf(ScreenGui) then
                return
            end

            Library:RemoveFromRegistry(Instance)
        end)
    end)

    --// Main Frame \\--
    local MainFrame = New("TextButton", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = function()
            return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
        end,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(Loading.ShowSidebar and (Loading.ContentWidth + Loading.SidebarWidth) or Loading.WindowWidth, Loading.WindowHeight),
        ClipsDescendants = true,
        Text = "",
        AutoButtonColor = false,
        Parent = ScreenGui,
    })
    Library:AddOutline(MainFrame)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = MainFrame }))

    local MainScale = New("UIScale", {
        Scale = Library.IsMobile and 0.8 or 1,
        Parent = MainFrame
    })
    table.insert(Library.Scales, MainScale)
    Library.ScalesOffset[MainScale] = Library.IsMobile and 0.2 or 0

    --// Layout Containers \\--
    local Container = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, Loading.ContentWidth, 1, 0),
        Parent = MainFrame,
    })

    local SideBar = New("Frame", {
        Name = "SideBar",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(Loading.ContentWidth, 0),
        Size = UDim2.new(0, Loading.ShowSidebar and Loading.SidebarWidth or 0, 1, 0),
        ClipsDescendants = true,
        Visible = Loading.ShowSidebar,
        Parent = MainFrame,
    })
    local SidebarCorner = New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius), Parent = SideBar })
    table.insert(Library.Corners, SidebarCorner)

    Library:AddOutline(SideBar)

    local SidebarDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Visible = Loading.ShowSidebar,
        Parent = SideBar,
    })

    --// Top Bar \\--
    local TopBar = New("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        ZIndex = 2,
        Parent = Container,
    })
    Library:MakeDraggable(MainFrame, TopBar, true, true)

    local TitleHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = TopBar,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = TitleHolder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        Parent = TitleHolder,
    })

    if LoadingInfo.Icon then
        local Icon = Library:GetCustomIcon(LoadingInfo.Icon)
        local _WindowIcon = New("ImageLabel", {
            Size = LoadingInfo.IconSize,
            Parent = TitleHolder,
        })
        if Icon then
            Library:ApplyLucideIcon(_WindowIcon, Icon)
        end
    else
        local _WindowIcon = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = LoadingInfo.IconSize,
            Text = LoadingInfo.Title:sub(1, 1),
            TextScaled = true,
            Visible = false,
            Parent = TitleHolder,
        })
    end

    local TitleX = Library:GetTextBounds(
        LoadingInfo.Title,
        Library.Scheme.Font,
        20,
        TitleHolder.AbsoluteSize.X - (LoadingInfo.Icon and (LoadingInfo.IconSize.X.Offset + 6) or 0) - 12
    )
    local _WindowTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, TitleX, 1, 0),
        Text = LoadingInfo.Title,
        TextSize = 20,
        Parent = TitleHolder,
    })

    Library:MakeLine(Container, {
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 0, 1),
    })

    --// Loading Content Elements \\--
    local InnerContent = New("Frame", {
        Name = "InnerContent",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 49),
        Size = UDim2.new(1, 0, 1, -49),
        Parent = Container,
    })

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 12),
        Parent = InnerContent,
    })

    local IconHolder = New("Frame", {
        Name = "IconHolder",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(64, 64),
        Parent = InnerContent,
    })

    local LoaderIcon = Library:GetCustomIcon(LoadingInfo.LoadingIcon)
    local LoadingIcon = New("ImageLabel", {
        Name = "LoaderIcon",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        ImageColor3 = LoadingInfo.LoadingIconColor or ((LoadingInfo.LoadingIcon == Templates.Loading.LoadingIcon) and "AccentColor" or "WhiteColor"),
        Parent = IconHolder,
    })
    if LoaderIcon then
        Library:ApplyLucideIcon(LoadingIcon, LoaderIcon)
    end

    local RotationTween
    if LoadingInfo.LoadingIconTweenTime > 0 then
        RotationTween = TweenService:Create(
            LoadingIcon,
            TweenInfo.new(LoadingInfo.LoadingIconTweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
            { Rotation = 360 }
        )
        RotationTween:Play()
    end

    local MessageLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = Loading.AutoResizeHeight and UDim2.new(1, -60, 0, 0) or UDim2.fromOffset(0, 0),
        Text = "",
        TextSize = 18,
        TextWrapped = Loading.AutoResizeHeight,
        Parent = InnerContent,
    })

    local DescriptionLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Loading.AutoResizeHeight and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
        Size = Loading.AutoResizeHeight and UDim2.new(1, -60, 0, 0) or UDim2.fromOffset(0, 0),
        Text = "",
        TextSize = 14,
        TextTransparency = 0.5,
        TextWrapped = Loading.AutoResizeHeight,
        Parent = InnerContent,
    })

    --// Progress Bar \\--
    local SliderBar = New("Frame", {
        BackgroundColor3 = "MainColor",
        Size = UDim2.new(0.7, 0, 0, 15),
        Parent = InnerContent,
    })
    Library:AddOutline(SliderBar)
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius / 2), Parent = SliderBar }))

    local SliderFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = SliderBar,
    })
    table.insert(Library.Corners, New("UICorner", { CornerRadius = UDim.new(0, Library.CornerRadius / 2), Parent = SliderFill }))

    local ProgressLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        TextSize = 14,
        ZIndex = 2,
        Parent = SliderBar,
    })
    New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        Color = "DarkColor",
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = ProgressLabel,
    })

    --// Sidebar Object \\--
    local SidebarScrolling = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = "OutlineColor",
        Parent = SideBar,
    })
    local SidebarList = New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = SidebarScrolling,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        Parent = SidebarScrolling,
    })

    local SidebarObject = {
        Elements = {},
        DependencyBoxes = {},
        Tabboxes = {},

        BoxHolder = SidebarScrolling,
        Container = SidebarScrolling,

        Resize = function(self)
            SidebarScrolling.CanvasSize = UDim2.fromOffset(0, SidebarList.AbsoluteContentSize.Y + 24)
        end,
        Tab = {
            Elements = {},
            DependencyBoxes = {},
            DependencyGroupboxes = {},
            Tabboxes = {},
        },
    }

    SidebarList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SidebarObject:Resize()
    end)

    setmetatable(SidebarObject, BaseGroupbox)
    Loading.Sidebar = SidebarObject

    --// Error Frame \\--
    local ErrorFrame = New("Frame", {
        Name = "Error",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 49),
        Size = UDim2.new(1, 0, 1, -49),
        ClipsDescendants = true,
        Visible = false,
        Parent = Container,
    })

    local _ErrorTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 15),
        Size = UDim2.new(1, -30, 0, 18),
        Text = "Error",
        TextColor3 = "RedColor",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ErrorFrame,
    })

    local ErrorLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(15, 39),
        Size = UDim2.new(1, -30, 1, -90),
        Text = "Error Message",
        TextSize = 14,
        TextTransparency = 0.2,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = ErrorFrame,
    })

    local ErrorButtonsDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, -48),
        Size = UDim2.new(1, -30, 0, 1),
        Visible = false,
        Parent = ErrorFrame,
    })

    local ErrorButtonsHolder = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 42),
        Visible = false,
        Parent = ErrorFrame,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = ErrorButtonsHolder,
    })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        Parent = ErrorButtonsHolder,
    })

    function Loading:UpdateLayout()
        if Loading.IsError then
            Loading:RecalculateErrorHeight()
        end

        local ShowSidebar = Loading.ShowSidebar
        local FinalWidth = ShowSidebar and (Loading.ContentWidth + Loading.SidebarWidth) or Loading.WindowWidth
        local FinalHeight = Loading.IsError and Loading.WindowErrorHeight or Loading.WindowHeight

        if ShowSidebar then
            SideBar.Visible = true
            SidebarDivider.Visible = true
        end

        TweenService:Create(MainFrame, Library.TweenInfo, { Size = UDim2.fromOffset(FinalWidth, FinalHeight) }):Play()
        TweenService:Create(SideBar, Library.TweenInfo, { Position = UDim2.fromOffset(Loading.ContentWidth, 0), Size = UDim2.new(0, ShowSidebar and Loading.SidebarWidth or 0, 1, 0) }):Play()
        TweenService:Create(Container, Library.TweenInfo, { Size = UDim2.new(0, ShowSidebar and Loading.ContentWidth or Loading.WindowWidth, 1, 0) }):Play()

        if not ShowSidebar then
            task.delay(Library.TweenInfo.Time, function()
                if not Loading.ShowSidebar then
                    SideBar.Visible = false
                    SidebarDivider.Visible = false
                end
            end)
        end
    end

    --// Content Page \\--
    function Loading:RecalculateLoadingHeight()
        if not Loading.AutoResizeHeight then
            return
        end

        local RequiredHeight =
              49 -- TopBar
            + 48 -- Padding
            + InnerContent.UIListLayout.AbsoluteContentSize.Y

        Loading.WindowHeight = math.max(Loading.BaseWindowHeight, RequiredHeight)
    end

    function Loading:SetMessage(Text)
        MessageLabel.Text = Text

        if Loading.AutoResizeHeight then
            Loading:RecalculateLoadingHeight()
            Loading:UpdateLayout()
        end
    end

    function Loading:SetDescription(Text)
        DescriptionLabel.Text = Text

        if Loading.AutoResizeHeight then
            Loading:RecalculateLoadingHeight()
            Loading:UpdateLayout()
        end
    end

    function Loading:SetLoadingIcon(Icon)
        local IconData = Library:GetCustomIcon(Icon)
        assert(IconData, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

        Library:ApplyLucideIcon(LoadingIcon, IconData)
    end

    function Loading:SetLoadingIconTweenTime(TweenTime)
        if RotationTween then
            StopTween(RotationTween, true)
            RotationTween = nil
        end

        if TweenTime > 0 then
            RotationTween = TweenService:Create(
                LoadingIcon,
                TweenInfo.new(TweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
                { Rotation = 360 }
            )
            RotationTween:Play()
        else
            LoadingIcon.Rotation = 0
        end
    end

    function Loading:SetLoadingIconColor(Color)
        LoadingIcon.ImageColor3 = Color
    end

    function Loading:SetCurrentStep(Step)
        Loading.CurrentStep = math.clamp(Step, 0, Loading.TotalSteps)

        local Progress = Loading.CurrentStep / Loading.TotalSteps
        TweenService:Create(SliderFill, Library.TweenInfo, { Size = UDim2.fromScale(Progress, 1) }):Play()

        ProgressLabel.Text = string.format("%d/%d", Loading.CurrentStep, Loading.TotalSteps)
    end

    function Loading:SetTotalSteps(Steps)
        Loading.TotalSteps = Steps
        Loading:SetCurrentStep(Loading.CurrentStep)
    end

    --// Size \\--
    function Loading:SetWindowHeight(Height)
        Loading.WindowHeight = Height
        Loading:UpdateLayout()
    end

    function Loading:SetWindowWidth(Width)
        Loading.WindowWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetContentWidth(Width)
        Loading.ContentWidth = Width
        Loading:UpdateLayout()
    end

    function Loading:SetSidebarWidth(Width)
        Loading.SidebarWidth = Width
        Loading:UpdateLayout()
    end

    --// Sidebar \\--
    function Loading:ShowSidebarPage(Bool)
        Loading.ShowSidebar = Bool
        Loading:UpdateLayout()
    end

    --// Error Page \\--
    function Loading:ShowErrorPage(Enabled)
        Loading.IsError = Enabled
        InnerContent.Visible = not Enabled
        ErrorFrame.Visible = Enabled

        if Loading.ShowSidebar then
            Loading:ShowSidebarPage(not Enabled)
        else
            Loading:UpdateLayout()
        end
    end

    function Loading:RecalculateErrorHeight()
        local TargetWidth = (Loading.ShowSidebar and Loading.ContentWidth or Loading.WindowWidth) - 30
        local _, ErrorY = Library:GetTextBounds(ErrorLabel.Text, Library.Scheme.Font, 14, TargetWidth)

        ErrorLabel.Size = UDim2.new(1, -30, 0, ErrorY)

        local HasButtons = ErrorButtonsHolder.Visible
        local RequiredHeight =
              49                        -- TopBar
            + 15                        -- Padding Top
            + 18                        -- Title Height
            + 6                         -- Padding between Title and Label
            + ErrorY                    -- Label Height
            + 15                        -- Padding between Label and Buttons
            + (HasButtons and 48 or 0)  -- Buttons Area

        Loading.WindowErrorHeight = RequiredHeight -- math.max(Loading.WindowHeight, RequiredHeight)
    end

    function Loading:SetErrorMessage(Text)
        ErrorLabel.Text = Text
        Loading:UpdateLayout()
    end

    function Loading:SetErrorButtons(Buttons)
        assert(typeof(Buttons) == "table", "Buttons must be a table")

        for _, button in ErrorButtonsHolder:GetChildren() do
            if button:IsA("Frame") then
                button:Destroy()
            end
        end

        local HasButtons = GetTableSize(Buttons) > 0
        ErrorButtonsHolder.Visible = HasButtons
        ErrorButtonsDivider.Visible = HasButtons

        for Idx, ButtonInfo in Buttons do
            local ButtonContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 26),
                Parent = ErrorButtonsHolder,
            })

            local BtnColor = "MainColor"
            local BtnOutline = "OutlineColor"
            local Variant = ButtonInfo.Variant or "Primary"

            if Variant == "Primary" then
                BtnColor = "FontColor"
                BtnOutline = "FontColor"
            elseif Variant == "Secondary" then
                BtnColor = "MainColor"
                BtnOutline = "OutlineColor"
            elseif Variant == "Destructive" then
                BtnColor = "DestructiveColor"
                BtnOutline = "DestructiveColor"
            elseif Variant == "Ghost" then
                BtnColor = "BackgroundColor"
                BtnOutline = "BackgroundColor"
            end

            local TextBtn = New("TextButton", {
                BackgroundColor3 = BtnColor,
                BorderColor3 = BtnOutline,
                Size = UDim2.fromOffset(0, 26),
                Text = "",
                AutoButtonColor = false,
                Parent = ButtonContainer,
            })
            Library:AddOutline(TextBtn)
            table.insert(
                Library.Corners,
                New("UICorner", {
                    CornerRadius = UDim.new(0, Library.CornerRadius),
                    Parent = TextBtn
                })
            )

            New("UIPadding", {
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
                Parent = TextBtn,
            })

            local TextColor = Library.Scheme.FontColor
            if Variant == "Primary" then
                TextColor = Library.Scheme.BackgroundColor
            elseif Variant == "Destructive" then
                TextColor = Color3.new(1, 1, 1)
            end

            local BtnLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = ButtonInfo.Title or Idx,
                TextColor3 = TextColor,
                TextSize = 14,
                Parent = TextBtn,
            })

            local LabelX, _ = Library:GetTextBounds(BtnLabel.Text, Library.Scheme.Font, 14, 250)
            ButtonContainer.Size = UDim2.fromOffset(LabelX + 30, 26)
            TextBtn.Size = UDim2.fromOffset(LabelX + 30, 26)

            local ActiveColor = typeof(BtnColor) == "Color3" and BtnColor or Library.Scheme[BtnColor]
            local HoverColor = Variant == "Ghost" and Library.Scheme.MainColor or Library:GetBetterColor(ActiveColor, 10)

            TextBtn.MouseEnter:Connect(function()
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = HoverColor
                }):Play()
            end)
            TextBtn.MouseLeave:Connect(function()
                TweenService:Create(TextBtn, Library.TweenInfo, {
                    BackgroundColor3 = ActiveColor
                }):Play()
            end)

            TextBtn.MouseButton1Click:Connect(function()
                if ButtonInfo.Callback then
                    ButtonInfo.Callback(Loading)
                end
            end)
        end

        Loading:UpdateLayout()
    end

    --// Destroy/Continue \\--
    function Loading:Destroy()
        if RotationTween then
            StopTween(RotationTween, true)
            RotationTween = nil
        end

        ScreenGui:Destroy()
        Loading.Destroyed = true
        Library.ActiveLoading = nil

        if Library.Toggle and Library.Toggled == false and Library.Unloaded ~= true then
            Library:Toggle(true)
        end
    end

    Loading.Continue = Loading.Destroy;

    if Library.Toggle and Library.Toggled and Library.Unloaded ~= true then
        Library:Toggle(false)
    end

    Loading:SetCurrentStep(Loading.CurrentStep)

    Library.ActiveLoading = Loading
    return Loading
end

--// A small, non-resizable window shown when the running executor is one your
--// script does not support. It names the detected executor, states it is
--// unsupported, and lists information/instructions. Detection is via
--// identifyexecutor; you choose which executors to gate.
--//
--// Returns the screen object (with :Destroy()) when the executor is unsupported,
--// or nil when it is supported (nothing is shown). The footer defaults to the
--// footer of your normal window (Library.Footer).
function Library:CreateUnsupportedScreen(Info)
    Info = Info or {}

    --// Resolve the running executor's name
    local Executor = Info.Executor
    if not Executor and identifyexecutor then
        local Ok, Name = pcall(identifyexecutor)
        if Ok and typeof(Name) == "string" and Name ~= "" then
            Executor = Name
        end
    end
    Executor = Executor or "Unknown"

    --// Decide if this executor is unsupported. A Supported whitelist wins; else an
    --// Unsupported blocklist; with neither list the screen always shows (the caller
    --// already decided to gate). Matching is a case-insensitive substring test.
    local function Matches(List): boolean
        local Lower = string.lower(Executor)
        for _, Entry in List do
            if string.find(Lower, string.lower(tostring(Entry)), 1, true) then
                return true
            end
        end
        return false
    end

    local IsUnsupported
    if typeof(Info.Supported) == "table" then
        IsUnsupported = not Matches(Info.Supported)
    elseif typeof(Info.Unsupported) == "table" then
        IsUnsupported = Matches(Info.Unsupported)
    else
        IsUnsupported = true
    end

    if not IsUnsupported then
        return nil
    end

    local Title = Info.Title or "Unsupported"

    --// Built-in localisation for the gate's own copy. Each entry translates the
    --// heading, the sub-line, the two default information points, and the
    --// language dropdown's own label. A caller-supplied Info.Information is shown
    --// verbatim (only the heading/sub-line re-translate on a language switch).
    local Languages = {
        {
            Name = "English",
            Heading = "%s is not supported",
            Subtitle = "This script does not support your current executor.",
            Language = "Language",
            Info = {
                "Your executor lacks the proper environment for support.",
                "Use another executor such as Potassium, Volt, Real, Opiumware, Delta, etc.",
            },
        },
        {
            Name = "Filipino",
            Heading = "Ang %s ay hindi suportado",
            Subtitle = "Hindi sinusuportahan ng script na ito ang iyong kasalukuyang executor.",
            Language = "Wika",
            Info = {
                "Ang iyong executor ay walang wastong kapaligiran para sa suporta.",
                "Gumamit ng ibang executor tulad ng Potassium, Volt, Real, Opiumware, Delta, atbp.",
            },
        },
        {
            Name = "Tiếng Việt",
            Heading = "%s không được hỗ trợ",
            Subtitle = "Tập lệnh này không hỗ trợ trình thực thi hiện tại của bạn.",
            Language = "Ngôn ngữ",
            Info = {
                "Trình thực thi của bạn thiếu môi trường phù hợp để được hỗ trợ.",
                "Hãy dùng trình thực thi khác như Potassium, Volt, Real, Opiumware, Delta, v.v.",
            },
        },
        {
            Name = "Bahasa Indonesia",
            Heading = "%s tidak didukung",
            Subtitle = "Skrip ini tidak mendukung executor Anda saat ini.",
            Language = "Bahasa",
            Info = {
                "Executor Anda tidak memiliki lingkungan yang tepat untuk didukung.",
                "Gunakan executor lain seperti Potassium, Volt, Real, Opiumware, Delta, dll.",
            },
        },
        {
            Name = "Русский",
            Heading = "%s не поддерживается",
            Subtitle = "Этот скрипт не поддерживает ваш текущий исполнитель.",
            Language = "Язык",
            Info = {
                "В вашем исполнителе отсутствует нужная среда для поддержки.",
                "Используйте другой исполнитель, например Potassium, Volt, Real, Opiumware, Delta и т. д.",
            },
        },
        {
            Name = "ไทย",
            Heading = "ไม่รองรับ %s",
            Subtitle = "สคริปต์นี้ไม่รองรับ executor ปัจจุบันของคุณ",
            Language = "ภาษา",
            Info = {
                "executor ของคุณไม่มีสภาพแวดล้อมที่เหมาะสมสำหรับการรองรับ",
                "ใช้ executor อื่น เช่น Potassium, Volt, Real, Opiumware, Delta ฯลฯ",
            },
        },
        {
            Name = "Deutsch",
            Heading = "%s wird nicht unterstützt",
            Subtitle = "Dieses Skript unterstützt deinen aktuellen Executor nicht.",
            Language = "Sprache",
            Info = {
                "Deinem Executor fehlt die passende Umgebung für Unterstützung.",
                "Verwende einen anderen Executor wie Potassium, Volt, Real, Opiumware, Delta usw.",
            },
        },
    }

    local LangByName = {}
    local LangNames = {}
    for _, Lang in Languages do
        LangByName[Lang.Name] = Lang
        table.insert(LangNames, Lang.Name)
    end

    --// A caller-supplied Information overrides the localised default points; the
    --// language switch then only re-translates the heading and sub-line.
    local CustomInformation = Info.Information

    --// Build a real, locked-down Obsidian window (fixed size, non-resizable,
    --// single-purpose) the same way the key-system window spawns, rather than a
    --// hand-built ScreenGui. Footer defaults to the normal UI's footer.
    local Window = Library:CreateWindow({
        Title = Title,
        Icon = Info.Icon,
        Footer = Info.Footer ~= nil and Info.Footer or Library.Footer,
        --// Chrome inherits from the real script so the gate matches its look;
        --// colours come from the active Library.Scheme (set the theme first).
        Font = Info.Font,
        CornerRadius = Info.CornerRadius,
        Size = UDim2.fromOffset(660, 320),
        Center = true,
        AutoShow = true,
        Resizable = false,
        EnableSidebarResize = false,
        Minimizable = false,
        DisableSearch = true,
        DisableNotificationBell = true,
        ShowCustomCursor = false,
        AlwaysOnTop = Info.AlwaysOnTop == true,
    })

    local Tab = Window:AddTab({ Name = "Unsupported", Icon = "shield-alert" })

    --// Heading: executor name + "not supported", plus the language picker
    local Heading = Tab:AddLeftGroupbox("Executor", "shield-alert")
    local HeadingLabel = Heading:AddLabel({ Text = "", DoesWrap = true })
    local SubtitleLabel = Heading:AddLabel({ Text = "", DoesWrap = true })
    local LanguageDropdown = Heading:AddDropdown("UnsupportedLanguage", {
        Text = "Language",
        Values = LangNames,
        Default = 1,
    })

    --// Information: the numbered points (localised default, or verbatim custom)
    local InfoBox = Tab:AddRightGroupbox("Information", "info")
    local DefaultInfoLabels = {}
    if CustomInformation then
        for Index, Entry in CustomInformation do
            local EntryTitle, EntryText
            if typeof(Entry) == "table" then
                EntryTitle, EntryText = Entry.Title, Entry.Text or ""
            else
                EntryText = tostring(Entry)
            end

            if EntryTitle and EntryTitle ~= "" then
                InfoBox:AddLabel({ Text = string.format("%d. %s", Index, EntryTitle), DoesWrap = true })
                InfoBox:AddLabel({ Text = EntryText, DoesWrap = true })
            else
                InfoBox:AddLabel({ Text = string.format("%d. %s", Index, EntryText), DoesWrap = true })
            end
        end
    else
        --// Two localised points, retranslated when the language changes
        for Index = 1, 2 do
            DefaultInfoLabels[Index] = InfoBox:AddLabel({ Text = "", DoesWrap = true })
        end
    end

    --// Apply a language to every localised string in the window
    local function ApplyLanguage(Name)
        local Lang = LangByName[Name] or Languages[1]
        HeadingLabel:SetText(string.format(Lang.Heading, Executor))
        SubtitleLabel:SetText(Lang.Subtitle)
        LanguageDropdown:SetText(Lang.Language)
        if not CustomInformation then
            for Index, Label in DefaultInfoLabels do
                Label:SetText(string.format("%d. %s", Index, Lang.Info[Index] or ""))
            end
        end
    end

    LanguageDropdown:OnChanged(function(Value)
        ApplyLanguage(Value)
    end)
    ApplyLanguage("English")

    local Screen = { Destroyed = false, Executor = Executor, Window = Window }

    function Screen:Destroy()
        if Screen.Destroyed then
            return
        end
        Screen.Destroyed = true
        if Library.Unload then
            Library:Unload()
        end
    end

    return Screen
end

local function OnPlayerChange()
    if Library.Unloaded then
        return
    end

    local PlayerList, ExcludedPlayerList = GetPlayers(), GetPlayers(true)
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
            Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
        end
    end
end

local function OnTeamChange()
    if Library.Unloaded then
        return
    end

    local TeamList = GetTeams()
    for _, Dropdown in Options do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
            Dropdown:SetValues(TeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

function Library:Unload()
    Library.Unloaded = true

    --// Disconnect connections
    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)

        if Connection and Connection.Connected then
            Connection:Disconnect()
        end
    end

    --// Run Unload Callbacks
    for _ = 1, #Library.UnloadSignals do
        local Callback = table.remove(Library.UnloadSignals, 1)

        if Callback then
            Library:SafeCallback(Callback)
        end
    end

    --// Destroy elements
    for Index = #Library.Tabs, 1, -1 do
        local Tab = table.remove(Library.Tabs, Index)

        if Tab and Tab.Destroy then
            Library:SafeCallback(Tab.Destroy, Tab)
        end
    end

    for Index = #Tooltips, 1, -1 do
        local Tooltip = table.remove(Tooltips, Index)

        if Tooltip and Tooltip.Destroy then
            Library:SafeCallback(Tooltip.Destroy, Tooltip)
        end
    end

    if Library.ActiveLoading then
        Library.ActiveLoading:Destroy()
    end

    if ScreenGui then
        ScreenGui:Destroy()
    end

    --// Clear tables
    table.clear(Library.Registry)

    table.clear(Options)
    table.clear(Toggles)
    table.clear(Buttons)
    table.clear(Labels)
    table.clear(Tooltips)

    table.clear(Library.Tabs)
    table.clear(Library.TabButtons)

    table.clear(Library.Scales)
    table.clear(Library.ScalesOffset)

    table.clear(Library.Corners)
    table.clear(Library.SpecificCorners)
    table.clear(Library.ContextMenus)

    table.clear(Library.Notifications)
    table.clear(Library.NotificationHistory)
    table.clear(Library.Dialogues)
    table.clear(Library.DraggableElements)
    table.clear(Library.KeybindToggles)
    table.clear(Library.DependencyBoxes)

    table.clear(TransparencyCache)
    table.clear(ActiveTabTweens)

    Library.Toggle = function(...) end
    Library.ScreenGui = nil
    Library.Floats = nil
    Library.Overlay = nil
    Library.WindowContainer = nil
    Library.KeybindFrame = nil
    Library.KeybindContainer = nil
    Library.NotificationHistoryFrame = nil
    Library.NotificationHistoryContainer = nil
    Library.NotificationHistoryOpen = false
    Library.NotificationHistoryRestPos = nil
    Library.NotificationBadge = nil
    table.clear(Library.NotificationBadges)
    Library.NotificationBell = nil
    Library.NotificationBellMini = nil
    Library.NotificationUnreadCount = 0

    getgenv().Library = nil
end

getgenv().Library = Library
return Library
