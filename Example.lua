--[[
    ObsidianUltra — Example / feature showcase
    Based on LinoriaLib's example (mstudio45), reworked for ObsidianUltra.

    Layout of this file:
        1.  Bootstrap ......... load the library + addons, shared locals
        2.  Window ............ window options and tab definitions
        3.  Home tab .......... player card + a realistic feature set
        4.  Elements tab ...... a tidy catalogue of every element type
        5.  Single Column tab . one full-width centered column
        6.  Sub Tabs tab ...... tabs nested inside a tab
        7.  Key System tab .... the key-gate tab
        8.  Overlays .......... watermark + draggable widgets (not tab-bound)
        9.  UI Settings tab ... menu controls, theme + config managers

    Tip: build UI first, wire logic later. Prefer Options/Toggles.INDEX:OnChanged
    over inline Callback for anything non-trivial — it keeps UI and logic separate.
]]

--// 1. Bootstrap \\--

local Repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

-- getgenv() tables the library populates; index them by the string Idx you pass to each element.
local Options = Library.Options
local Toggles = Library.Toggles

-- Small helper so demo callbacks stay one-liners instead of scattered prints.
local function Log(...)
    print("[example]", ...)
end

Library.ForceCheckbox = false -- Force every AddToggle to render as a checkbox
Library.ShowToggleFrameInKeybinds = true -- Toggle keybinds appear in the keybind list (nice for mobile)

--// 2. Window \\--

local Window = Library:CreateWindow({
    Title = "mspaint",
    Icon = 95816097006870,
    ShowCustomCursor = true,
    NotifySide = "Right",

    -- Footer: bare strings are plain text; a segment is copyable only when it says so,
    -- and CopyText overrides what actually lands on the clipboard.
    Footer = {
        "version: example |",
        { Text = "discord.gg/mspaint", Copyable = true },
        "|",
        { Text = "user id", Copyable = true, CopyText = tostring(LocalPlayer.UserId) },
    },
    CopyableFooter = true,

    -- Search (Ctrl+F focuses, Esc clears). Both on by default.
    FuzzySearch = true,
    SearchValues = true,
    SearchKeybind = Enum.KeyCode.F,

    -- Minimize collapses the window to a small card (title / active tab / footer).
    Minimizable = true,
    MinimizeKeybind = Enum.KeyCode.RightBracket,
    MinimizedWidth = 300,

    -- Optional animations (all off by default except SubTabUnderline).
    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
        KeyPicker = true,
        SubTabUnderline = true,
    },
    TabTransitionTime = 0.22, -- only used when Animations.TabSwitch is on
    TabSwipeOffset = 26,
    TabSwipeFrom = "right", -- edge new tab content slides in from: left/right/top/bottom
})

local Tabs = {
    Home = Window:AddTab({ Name = "Home", Icon = "user", Description = "Overview & main features" }),
    Elements = Window:AddTab({ Name = "Elements", Icon = "layout-grid", Description = "Every element type" }),
    -- SingleColumn = true collapses the tab to one centered column instead of the
    -- default left/right split (Layout = "Single"/"Center" also works).
    Single = Window:AddTab({ Name = "Single Column", Icon = "square", Description = "One centered column", SingleColumn = true }),
    SubTabs = Window:AddTab({ Name = "Sub Tabs", Icon = "layers", Description = "Tabs inside a tab" }),
    Key = Window:AddKeyTab("Key System"),
    Settings = Window:AddTab({ Name = "UI Settings", Icon = "settings", Description = "Configure the menu" }),
}

--// 3. Home tab \\--
-- A realistic layout: a player banner, a profile card, and two feature groupboxes.
do
    -- On a TAB, AddPlayerInfo is a full-width banner above both columns.
    Tabs.Home:AddPlayerInfo("HomeBanner", {
        -- Defaults to the local player; pass Player = <Player> or UserId = <id> for someone else.
        Title = "Welcome to the <b>ObsidianUltra</b> example",
        Description = {
            '<font color="#8f6bff">Home</font> — this player card + a Combat & Visuals set',
            '<font color="#8f6bff">Elements</font> — a catalogue of every element type',
            '<font color="#8f6bff">Single Column</font> — one full-width column layout',
            '<font color="#8f6bff">Sub Tabs, Key, Settings</font> — nesting, key gate, config',
        },
        ThumbnailType = "HeadShot", -- "HeadShot" | "Bust" | "Avatar"
        Height = 84,
    })

    -- On a GROUPBOX it is the compact form: just the avatar box.
    Tabs.Home:AddRightGroupbox("Profile", "user"):AddPlayerInfo("HomeProfile", {
        ThumbnailType = "Bust",
        Height = 190,
    })

    -- Combat groupbox: toggle + synced keybind + colorpicker, a slider, and a dropdown.
    local Combat = Tabs.Home:AddLeftGroupbox("Combat", "swords")

    Combat:AddToggle("SilentAim", {
        Text = "Silent Aim",
        Tooltip = "Snap shots to the selected hit part",
        Default = false,
    }):AddKeyPicker("SilentAimKey", {
        Default = "MB2",
        Mode = "Hold",
        Text = "Silent Aim",
        SyncToggleState = false,
    })

    Combat:AddSlider("SilentAimFov", {
        Text = "FOV",
        Default = 90, Min = 0, Max = 360, Rounding = 0, Suffix = "°",
    })

    Combat:AddDropdown("SilentAimPart", {
        Text = "Hit Part",
        Values = { "Head", "HumanoidRootPart", "Torso" },
        Default = 1,
    })

    -- Visuals groupbox: a toggle with a colorpicker, a slider, and a multi dropdown.
    local Visuals = Tabs.Home:AddRightGroupbox("Visuals", "eye")

    Visuals:AddToggle("EspEnabled", { Text = "Player ESP", Default = true })
        :AddColorPicker("EspColor", { Default = Color3.fromRGB(0, 255, 140), Title = "ESP Color" })

    Visuals:AddSlider("EspDistance", {
        Text = "Max Distance",
        Default = 500, Min = 50, Max = 2000, Rounding = 0, Suffix = " studs",
    })

    Visuals:AddDropdown("EspParts", {
        Text = "ESP Features",
        Values = { "Box", "Name", "Distance", "Health", "Tracer" },
        Default = 1,
        Multi = true,
    })

    -- Logic wired after the UI exists (the recommended pattern).
    Toggles.SilentAim:OnChanged(function()
        Log("SilentAim:", Toggles.SilentAim.Value)
    end)
    Toggles.EspEnabled:OnChanged(function()
        Log("EspEnabled:", Toggles.EspEnabled.Value)
    end)
    Options.EspColor:OnChanged(function()
        Log("EspColor:", Options.EspColor.Value)
    end)
end

--// 4. Elements tab \\--
-- One box per element family, so it doubles as an API reference.
do
    -- Buttons: main button, chained sub button, and a disabled button.
    local Buttons = Tabs.Elements:AddLeftGroupbox("Buttons", "mouse-pointer-click")

    Buttons:AddButton({
        Text = "Button",
        Tooltip = "A normal button",
        Func = function() Log("Button clicked") end,
    }):AddButton({ -- chain :AddButton to add a sub button underneath
        Text = "Sub button",
        Tooltip = "Requires a double click",
        DoubleClick = true,
        Func = function() Log("Sub button clicked") end,
    })

    Buttons:AddButton({
        Text = "Disabled button",
        Disabled = true,
        DisabledTooltip = "I am disabled!",
        Func = function() Log("unreachable") end,
    })

    -- Toggles & checkboxes.
    local Toggle = Tabs.Elements:AddLeftGroupbox("Toggles", "toggle-left")

    Toggle:AddToggle("DemoToggle", {
        Text = "A toggle",
        Tooltip = "Hover tooltip",
        Default = true,
    })
    Toggle:AddCheckbox("DemoCheckbox", {
        Text = "A checkbox",
        Default = false,
    })
    Toggle:AddToggle("RiskyToggle", {
        Text = "A risky toggle",
        Risky = true, -- red text; colour comes from Library.Scheme.Red
        Default = false,
    })

    Toggles.DemoToggle:OnChanged(function()
        Log("DemoToggle:", Toggles.DemoToggle.Value)
    end)

    -- Labels & dividers.
    local Labels = Tabs.Elements:AddLeftGroupbox("Labels", "text")
    Labels:AddLabel("A plain label")
    Labels:AddLabel("A label that wraps its own text across multiple lines.", true)
    Labels:AddDivider()
    Labels:AddLabel("LabelWithIdx", { Text = "A label with an index (Options.LabelWithIdx:SetText)", DoesWrap = true })

    -- Sliders: a basic one and one with a custom display formatter.
    local Sliders = Tabs.Elements:AddLeftGroupbox("Sliders", "sliders-horizontal")

    Sliders:AddSlider("DemoSlider", {
        Text = "A slider",
        Default = 2, Min = 0, Max = 5, Rounding = 1,
    })
    Sliders:AddSlider("FormattedSlider", {
        Text = "A formatted slider",
        Default = 3, Min = 0, Max = 5, Rounding = 0,
        FormatDisplayValue = function(Slider, Value)
            if Value == Slider.Max then return "Everything" end
            if Value == Slider.Min then return "Nothing" end
            -- returning nil falls back to the default formatting
        end,
    })

    Options.DemoSlider:OnChanged(function()
        Log("DemoSlider:", Options.DemoSlider.Value)
    end)

    -- Inputs.
    local Inputs = Tabs.Elements:AddLeftGroupbox("Inputs", "keyboard")
    Inputs:AddInput("DemoInput", {
        Text = "A textbox",
        Default = "type here",
        Placeholder = "Placeholder text",
        ClearTextOnFocus = true,
        Finished = false, -- fire callback only on Enter
        Numeric = false, -- allow only numbers
    })
    Options.DemoInput:OnChanged(function()
        Log("DemoInput:", Options.DemoInput.Value)
    end)

    -- Colour & key pickers (attach to a label, toggle, or each other).
    local Pickers = Tabs.Elements:AddLeftGroupbox("Pickers", "palette")

    Pickers:AddLabel("Colour"):AddColorPicker("DemoColor", {
        Default = Color3.fromRGB(0, 255, 0),
        Title = "A colour",
        Transparency = 0, -- omit to disable the transparency slider
    })
    Options.DemoColor:OnChanged(function()
        Log("DemoColor:", Options.DemoColor.Value, "alpha", Options.DemoColor.Transparency)
    end)

    Pickers:AddLabel("Toggle keybind"):AddKeyPicker("DemoKey", {
        Default = "MB2",
        Mode = "Toggle", -- Always | Toggle | Hold | Press
        Text = "A toggle keybind",
    })
    Options.DemoKey:OnClick(function() -- only fires in Toggle mode
        Log("DemoKey toggled:", Options.DemoKey:GetState())
    end)

    -- Press keybind: runs its callback on each press.
    local Pressed = 0
    Pickers:AddLabel("Press keybind"):AddKeyPicker("DemoPressKey", {
        Default = "X",
        Mode = "Press",
        Text = "A press keybind",
        Callback = function()
            Pressed += 1
            Log("DemoPressKey pressed x" .. Pressed)
        end,
    })

    -- Poll a keybind's held state from a loop (stops when the library unloads).
    task.spawn(function()
        while task.wait(1) do
            if Library.Unloaded then break end
            if Options.DemoKey:GetState() then
                Log("DemoKey is held down")
            end
        end
    end)

    -- Dropdowns get their own column so the variants read cleanly.
    local Dropdowns = Tabs.Elements:AddRightGroupbox("Dropdowns", "chevron-down")

    Dropdowns:AddDropdown("BasicDropdown", {
        Text = "Basic",
        Values = { "This", "is", "a", "dropdown" },
        Default = 1,
        -- Every dropdown gets an expand button that opens the values in a panel.
        Expandable = true,
        ExpandColumns = 2,
    })
    Options.BasicDropdown:OnChanged(function()
        Log("BasicDropdown:", Options.BasicDropdown.Value)
    end)

    Dropdowns:AddDropdown("SearchableDropdown", {
        Text = "Searchable",
        Values = { "This", "is", "a", "searchable", "dropdown" },
        Default = 1,
        Searchable = true, -- great for long value lists
    })

    Dropdowns:AddDropdown("MultiDropdown", {
        Text = "Multi select",
        Values = { "This", "is", "a", "dropdown" },
        Default = 1,
        Multi = true,
        -- Built-in Select All / Deselect All row (also :SelectAll() / :DeselectAll()).
        SelectAllButtons = true,
    })
    Options.MultiDropdown:SetValue({ This = true, is = true })

    -- Dictionary values: keys are the identity in .Value, values are display labels.
    Dropdowns:AddDropdown("DictionaryDropdown", {
        Text = "Dictionary",
        Values = { item01 = "Excalibur", item05 = "Aegis Shield", item06 = "Wooden Club" },
        Default = "item01", -- a key, not a label
        Multi = true,
        DisabledValues = { "item05" }, -- key or label both work here
    })

    -- Long list: MaxVisibleDropdownItems controls how many rows show before scrolling.
    Dropdowns:AddDropdown("LongDropdown", {
        Text = "Long list",
        Values = (function()
            local Names = {}
            for _, Material in Enum.Material:GetEnumItems() do
                table.insert(Names, Material.Name)
            end
            return Names
        end)(),
        Default = 1,
        Multi = true,
        Searchable = true,
        MaxVisibleDropdownItems = 10,
        ExpandColumns = 3,
    })

    -- Special dropdowns that populate themselves from the game.
    Dropdowns:AddDropdown("PlayerDropdown", {
        Text = "Players",
        SpecialType = "Player",
        ExcludeLocalPlayer = true,
    })
    Dropdowns:AddDropdown("TeamDropdown", {
        Text = "Teams",
        SpecialType = "Team",
    })

    Dropdowns:AddDropdown("DisabledDropdown", {
        Text = "Disabled",
        Values = { "This", "is", "a", "dropdown" },
        Default = 1,
        Disabled = true,
        DisabledTooltip = "I am disabled!",
    })

    -- Tabbox: a groupbox split into its own tabs. Anything a groupbox does, a tab does.
    local TabBox = Tabs.Elements:AddRightTabbox("Tabbox")
    local TabOne = TabBox:AddTab("Tab 1")
    TabOne:AddToggle("TabboxToggle1", { Text = "Tab 1 toggle" })
    local TabTwo = TabBox:AddTab("Tab 2")
    TabTwo:AddToggle("TabboxToggle2", { Text = "Tab 2 toggle" })
end

--// 5. Single Column tab \\--
-- With SingleColumn the Side option is ignored and groupboxes stack full-width
-- down one centered column, which suits long lists or a focused single feature.
do
    local Farm = Tabs.Single:AddGroupbox({ Name = "Auto Farm", IconName = "sprout" })
    Farm:AddToggle("SingleFarmEnabled", { Text = "Enable Auto Farm", Default = false })
    Farm:AddDropdown("SingleFarmMode", {
        Text = "Mode",
        Values = { "Nearest", "Strongest", "Fastest" },
        Default = 1,
    })
    Farm:AddSlider("SingleFarmDelay", {
        Text = "Loop Delay",
        Default = 250, Min = 0, Max = 1000, Rounding = 0, Suffix = "ms",
    })

    local Info = Tabs.Single:AddGroupbox({ Name = "Notes", IconName = "info" })
    Info:AddLabel("Both groupboxes span the full width because this tab is single column.", true)
    Info:AddButton({ Text = "A full-width button", Func = function() Log("Single-column button clicked") end })
end

--// 6. Sub Tabs tab \\--
-- Sub tabs are a button row above the content. Each sub tab is a mini tab with its
-- own left/right columns, so it holds everything a normal tab does. These three
-- examples exist only to show that off.
do
    Tabs.SubTabs:SetSubTabAlignment("Center") -- "Left" | "Center" | "Right"

    local Overview = Tabs.SubTabs:AddSubTab({ Name = "Overview", Icon = "info" })
    local Layout = Tabs.SubTabs:AddSubTab({ Name = "Layout", Icon = "columns-2" })
    local Nested = Tabs.SubTabs:AddSubTab({ Name = "Nested", Icon = "layers" })

    -- Overview: what a sub tab is, plus a couple of live controls.
    local About = Overview:AddLeftGroupbox("About Sub Tabs", "info")
    About:AddLabel("Click the buttons above to switch sub tab.", true)
    About:AddLabel("Each one keeps its own scroll position and controls.", true)
    About:AddToggle("SubOverviewToggle", { Text = "A toggle lives here", Default = true })

    local Actions = Overview:AddRightGroupbox("Actions", "zap")
    Actions:AddButton({
        Text = "Send a notification",
        Func = function()
            Library:Notify({ Title = "Sub Tabs", Description = "Hello from the Overview sub tab!", Time = 3 })
        end,
    })

    -- Layout: proof that a sub tab has both a left and a right column.
    local Left = Layout:AddLeftGroupbox("Left column", "align-left")
    Left:AddSlider("SubLayoutSlider", { Text = "A slider", Default = 40, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
    Left:AddDropdown("SubLayoutDropdown", {
        Text = "A dropdown",
        Values = { "Option A", "Option B", "Option C" },
        Default = 1,
    })

    local Right = Layout:AddRightGroupbox("Right column", "align-right")
    Right:AddInput("SubLayoutInput", { Text = "A textbox", Placeholder = "type here" })
    Right:AddToggle("SubLayoutToggle", { Text = "A toggle", Default = false })

    -- Nested: a tabbox (tabs inside a groupbox) sitting inside a sub tab.
    local Box = Nested:AddLeftTabbox("A Tabbox")
    local TabA = Box:AddTab("Tab A")
    TabA:AddToggle("SubNestedToggleA", { Text = "Tab A toggle" })
    TabA:AddButton({ Text = "Tab A button", Func = function() Log("Nested Tab A button") end })
    local TabB = Box:AddTab("Tab B")
    TabB:AddSlider("SubNestedSlider", { Text = "Tab B slider", Default = 5, Min = 0, Max = 10, Rounding = 0 })

    Nested:AddRightGroupbox("Notes", "scroll-text")
        :AddLabel("A tabbox can nest inside a sub tab, a groupbox, anywhere.", true)
end

--// 7. Key System tab \\--
do
    Tabs.Key:AddLabel({ Text = "Key: Banana", DoesWrap = true, Size = 16 })

    Tabs.Key:AddKeyBox(function(ReceivedKey)
        local Success = ReceivedKey == "Banana" -- implement your own key check here
        Log("Key check —", ReceivedKey, "| success:", Success)
        Library:Notify({
            Title = "Key System",
            Description = "Received: " .. ReceivedKey .. "\nSuccess: " .. tostring(Success),
            Time = 4,
        })
    end)
end

--// 8. Overlays \\--
-- Widgets that float over the game, independent of any tab.
do
    Library:AddDraggableLabel("This is a Draggable Label")

    -- Watermark: a segmented status bar. A segment's Text can be a string or a
    -- function; function segments auto-refresh every Watermark.RefreshRate seconds.
    -- A segment with Player (or PlayerCard = true) renders an avatar player card.
    local Watermark = Library:AddWatermark({
        { Player = LocalPlayer }, -- avatar + display name; NameType = "Username" for the account name
        { Icon = "flame", Text = "mspaint", Accent = true },
        { Icon = "cpu", Text = function()
            return (identifyexecutor and identifyexecutor()) or "Unknown"
        end },
        { Icon = "wifi", Text = function()
            local Ping = 0
            pcall(function()
                Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
            end)
            return string.format("%d ms", Ping)
        end },
        { Icon = "clock", Text = function() return os.date("%H:%M") end },
    })
    Watermark.RefreshRate = 1
end

--// 9. UI Settings tab \\--
do
    local Menu = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

    Menu:AddToggle("KeybindMenuOpen", {
        Text = "Open Keybind Menu",
        Default = Library.KeybindFrame.Visible,
        Callback = function(Value) Library.KeybindFrame.Visible = Value end,
    })
    Menu:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor",
        Default = Library.ShowCustomCursor,
        Callback = function(Value) Library.ShowCustomCursor = Value end,
    })
    Menu:AddToggle("AlwaysOnTop", {
        Text = "Always On Top",
        Default = Window.AlwaysOnTop,
        Callback = function(Value) Window:SetAlwaysOnTop(Value) end,
    })
    Menu:AddDropdown("NotificationSide", {
        Text = "Notification Side",
        Values = { "Left", "Right" },
        Default = "Right",
        Callback = function(Value) Library:SetNotifySide(Value) end,
    })
    Menu:AddDropdown("DPIScale", {
        Text = "DPI Scale",
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%",
        Callback = function(Value)
            Library:SetDPIScale(tonumber((Value:gsub("%%", ""))))
        end,
    })
    Menu:AddSlider("CornerRadius", {
        Text = "Corner Radius",
        Default = Library.CornerRadius, Min = 0, Max = 20, Rounding = 0,
        Callback = function(Value) Window:SetCornerRadius(Value) end,
    })

    Menu:AddDivider()

    Menu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = true,
        Text = "Menu keybind",
    })
    Menu:AddButton("Unload", function() Library:Unload() end)

    Library.ToggleKeybind = Options.MenuKeybind -- custom keybind to toggle the menu

    -- Addons: ThemeManager (menu themes) and SaveManager (config system).
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    SaveManager:IgnoreThemeSettings() -- configs shouldn't save themes
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" }) -- and shouldn't fight over the menu key

    -- A hub might keep themes in a global folder and configs per game.
    ThemeManager:SetFolder("MyScriptHub")
    SaveManager:SetFolder("MyScriptHub/specific-game")
    SaveManager:SetSubFolder("specific-place") -- optional: separate configs per place in a game

    SaveManager:BuildConfigSection(Tabs.Settings) -- config UI on the right column
    ThemeManager:ApplyToTab(Tabs.Settings) -- theme UI on the left column

    SaveManager:LoadAutoloadConfig() -- load the config flagged for autoload, if any
end

Library:OnUnload(function()
    Log("Unloaded!")
end)
