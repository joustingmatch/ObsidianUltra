local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local clonefunction = (clonefunction or copyfunction or function(func) 
    return func 
end)

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local Players: Players = cloneref(game:GetService("Players"))

--// Fix is_____ functions for shitsploits, those functions should never error, only return a boolean. (why is this still a problem in the big 2026)
local isfolder, isfile, listfiles = isfolder, isfile, listfiles
local isfolder_copy, isfile_copy, listfiles_copy = clonefunction(isfolder), clonefunction(isfile), clonefunction(listfiles)
local isfolder_success, isfolder_error = pcall(function() return isfolder_copy("test" .. tostring(math.random(1000000, 9999999))) end)

if isfolder_success == false or typeof(isfolder_error) ~= "boolean" then
    isfolder = function(folder)
        local success, data = pcall(isfolder_copy, folder)
        return (if success then data else false)
    end

    isfile = function(file)
        local success, data = pcall(isfile_copy, file)
        return (if success then data else false)
    end

    listfiles = function(folder)
        local success, data = pcall(listfiles_copy, folder)
        return (if success then data else {})
    end
end

--// Save Manager
local SaveManager = {
    Library = nil,

    Folder = "ObsidianLibSettings",
    SubFolder = "",

    Ignore = {},
    LoadingOrder = {},
    UseLoadingOrder = false,

    --// Kept out of share codes, still saved in private configs (SetShareExclusions)
    ShareExclude = {},
    ShareExcludeFilter = nil,
    --// Inputs holding a URL (webhooks, invites) are kept out of share codes too
    ShareExcludeURLs = true,

    --// Load behaviour, see "Load lifecycle" below
    DefaultLoadMode = "Snapshot",
    StrictLoad = false,
    SelectionResolver = nil,
    Loading = nil,
    LoadGeneration = 0,

    AutoloadConfig = nil,
    LoadedConfig = nil,

    --// Kept in manager.txt next to the configs
    AutoloadPerAccount = false,
    Autosave = false,
}

function SaveManager:SetLibrary(Library)
    SaveManager.Library = Library
end

--// Config format \\--
--// 1: the original format. No version field, slider values saved as text and
--//    multi dropdowns saved as { Value = true } sets.
--// 2: adds `version`, saves sliders as numbers and dropdowns as arrays of values,
--//    and writes options before toggles. Format 1 files still load and the load
--//    report lists what was read the old way.
local CONFIG_VERSION = 2

--// Types are applied in this order (unless SetLoadingOrder says otherwise), so all
--// values are in place before any toggle callback runs.
local DEFAULT_APPLY_ORDER = {
    "KeybindMenu", "Window", "Groupbox", "Tabbox",
    "Input", "Slider", "Dropdown", "PriorityDropdown", "ColorPicker", "KeyPicker",
    "Toggle",
}

local function IsArray(Table: any): boolean
    if typeof(Table) ~= "table" then
        return false
    end

    local Count = 0
    for Key in Table do
        if typeof(Key) ~= "number" or Key < 1 or Key % 1 ~= 0 then
            return false
        end

        Count += 1
    end

    return Count == #Table
end

local function IsFiniteNumber(Value: any): boolean
    return typeof(Value) == "number" and Value == Value and Value ~= math.huge and Value ~= -math.huge
end

local function SortedKeys(Table: { [any]: any }): { any }
    local Keys = {}
    for Key in Table do
        table.insert(Keys, Key)
    end

    table.sort(Keys, function(A, B)
        return tostring(A) < tostring(B)
    end)

    return Keys
end

--// Element Parser \\--
local SpecialValueParser = {
    UDim2 = {
        Encode = function(Value: UDim2)
            return {
                X = { Scale = Value.X.Scale, Offset = Value.X.Offset },
                Y = { Scale = Value.Y.Scale, Offset = Value.Y.Offset }
            }
        end,

        Decode = function(Data: any)
            local DataType = typeof(Data)
            if DataType == "UDim2" then
                return Data
            end

            if DataType ~= "table" or typeof(Data.X) ~= "table" or typeof(Data.Y) ~= "table" then
                return nil
            end

            local XScale, XOffset, YScale, YOffset = Data.X.Scale, Data.X.Offset, Data.Y.Scale, Data.Y.Offset
            if not (IsFiniteNumber(XScale) and IsFiniteNumber(XOffset) and IsFiniteNumber(YScale) and IsFiniteNumber(YOffset)) then
                return nil
            end

            return UDim2.new(XScale, XOffset, YScale, YOffset)
        end
    }
}

--// What each element goes back to when a snapshot load leaves it out, or on reset
local ElementResetters = {
    Toggle = function(Toggle) Toggle:SetValue(Toggle.Default) end,
    Slider = function(Slider) Slider:SetValue(Slider.Default) end,
    Input = function(Input) Input:SetValue(Input.Default) end,
    PriorityDropdown = function(Priority) Priority:SetValue(Priority.Default) end,

    Dropdown = function(Dropdown)
        local Default = Dropdown.Default or {}
        Dropdown:SetValue(if Dropdown.Multi then Default else Default[1])
    end,

    ColorPicker = function(ColorPicker)
        ColorPicker:SetValueRGB(ColorPicker.Default, ColorPicker.DefaultTransparency)
    end,

    KeyPicker = function(KeyPicker)
        KeyPicker:SetValue({ KeyPicker.Default, KeyPicker.DefaultMode or KeyPicker.Mode, KeyPicker.DefaultModifiers })
    end,
}

--// Each parser has:
--//   Category  "Toggles" / "Options" (the Library table the element lives in) or "Layout"
--//   Save(Element, TabIndex?) -> the entry's fields
--//   Check(Element, Data, Entry) -> payload, or (nil, "fatal" | "skip", reason).
--//     Runs before anything changes. Entry has Migrate(text), Adjust(text) and
--//     Resolve(available, unavailable) for unavailable dropdown values.
--//   Apply(Element, Payload) -> optional note when the element changed the value
--//   Find(Data) (Layout only) -> the groupbox / tabbox, or (nil, reason)
local ElementParser = {}

local function RunOrSet(Element: any, Same: boolean, Value: any)
    --// Loading the value it already has still runs the callbacks, same as before
    if Same then
        Element:RunChanged()
    else
        Element:SetValue(Value)
    end
end

ElementParser.Toggle = {
    Category = "Toggles",

    Save = function(Toggle)
        return { value = Toggle.Value == true }
    end,

    Check = function(_, Data)
        if typeof(Data.value) ~= "boolean" then
            return nil, "fatal", "value must be true or false"
        end

        return Data.value
    end,

    Apply = function(Toggle, Value)
        RunOrSet(Toggle, Toggle.Value == Value, Value)
    end,
}

ElementParser.Slider = {
    Category = "Options",

    Save = function(Slider)
        return { value = Slider.Value }
    end,

    Check = function(Slider, Data, Entry)
        local Value = Data.value
        if typeof(Value) == "string" then
            Value = tonumber(Value)
            Entry.Migrate("slider values saved as text")
        end

        if not IsFiniteNumber(Value) then
            return nil, "fatal", "value must be a number"
        end

        if IsFiniteNumber(Slider.Min) and IsFiniteNumber(Slider.Max) then
            local Clamped = math.clamp(Value, Slider.Min, Slider.Max)
            if Clamped ~= Value then
                Entry.Adjust(string.format("%s is outside %s to %s, using %s", tostring(Value), tostring(Slider.Min), tostring(Slider.Max), tostring(Clamped)))
                Value = Clamped
            end
        end

        return Value
    end,

    Apply = function(Slider, Value)
        RunOrSet(Slider, Slider.Value == Value, Value)
    end,
}

ElementParser.Input = {
    Category = "Options",

    Save = function(Input)
        return { text = Input.Value }
    end,

    Check = function(_, Data)
        if typeof(Data.text) ~= "string" then
            return nil, "fatal", "text must be a string"
        end

        return Data.text
    end,

    Apply = function(Input, Text)
        RunOrSet(Input, Input.Value == Text, Text)

        --// Numeric, MaxLength, VerifyValue and AllowEmpty can all rewrite the text
        if Input.Value ~= Text then
            return string.format("the input turned %q into %q", Text, tostring(Input.Value))
        end

        return nil
    end,
}

ElementParser.Dropdown = {
    Category = "Options",

    Save = function(Dropdown)
        if not Dropdown.Multi then
            return { value = Dropdown.Value, multi = false }
        end

        local Selection = {}
        for Value, Selected in Dropdown.Value or {} do
            if Selected then
                table.insert(Selection, Value)
            end
        end

        table.sort(Selection, function(A, B)
            return tostring(A) < tostring(B)
        end)

        return { value = Selection, multi = true }
    end,

    Check = function(Dropdown, Data, Entry)
        local Raw = Data.value
        if typeof(Raw) == "table" and next(Raw) ~= nil and not IsArray(Raw) then
            Entry.Migrate("dropdown selections saved as sets")
        end

        --// A Library without NormalizeValue gets the value the way it always did
        if typeof(Dropdown.NormalizeValue) ~= "function" then
            return { Legacy = true, Raw = Raw }
        end

        local Selection, Unavailable, Problem = Dropdown:NormalizeValue(Raw)
        if Problem then
            if typeof(Data.multi) == "boolean" and Data.multi ~= (Dropdown.Multi == true) then
                return nil, "skip", string.format("was saved as a %s select: %s", if Data.multi then "multi" else "single", Problem)
            end

            return nil, "fatal", Problem
        end

        if #Unavailable > 0 then
            Selection = Entry.Resolve(Selection, Unavailable)
        end

        return { Selection = Selection }
    end,

    Apply = function(Dropdown, Payload)
        if Payload.Legacy then
            Dropdown:SetValue(Payload.Raw)
            return nil
        end

        local Selection = Payload.Selection
        local Same
        if Dropdown.Multi then
            local Current = Dropdown.Value or {}
            local Count = 0
            for _, Selected in Current do
                if Selected then Count += 1 end
            end

            Same = Count == #Selection
            for _, Value in Selection do
                Same = Same and Current[Value] == true
            end

            RunOrSet(Dropdown, Same, Selection)
        else
            RunOrSet(Dropdown, Dropdown.Value == Selection[1], Selection[1])
        end

        return nil
    end,
}

ElementParser.PriorityDropdown = {
    Category = "Options",

    Save = function(Priority)
        return { order = Priority:GetValue() }
    end,

    Check = function(Priority, Data, Entry)
        local Order = Data.order
        if not IsArray(Order) then
            return nil, "fatal", "order must be a list"
        end

        local Kept, Unavailable = {}, {}
        for _, Value in Order do
            if typeof(Value) == "table" then
                return nil, "fatal", "order holds a nested table"
            end

            if typeof(Priority.Values) == "table" and not table.find(Priority.Values, Value) then
                table.insert(Unavailable, Value)
            else
                table.insert(Kept, Value)
            end
        end

        if #Unavailable > 0 then
            Entry.Unavailable(Unavailable, "left out, the rest keep their order", Kept)
        end

        return Kept
    end,

    Apply = function(Priority, Order)
        Priority:SetValue(Order)
    end,
}

ElementParser.ColorPicker = {
    Category = "Options",

    Save = function(ColorPicker)
        return { value = ColorPicker.Value:ToHex(), transparency = ColorPicker.Transparency }
    end,

    Check = function(_, Data)
        local Hex, Transparency = Data.value, Data.transparency
        if typeof(Hex) ~= "string" or not Hex:match("^#?%x%x%x%x%x%x$") then
            return nil, "fatal", "value must be a hex color"
        end

        local Success, Color = pcall(Color3.fromHex, Hex)
        if not Success then
            return nil, "fatal", "value must be a hex color"
        end

        if Transparency ~= nil and not (IsFiniteNumber(Transparency) and Transparency >= 0 and Transparency <= 1) then
            return nil, "fatal", "transparency must be a number from 0 to 1"
        end

        return { Color = Color, Transparency = Transparency }
    end,

    Apply = function(ColorPicker, Payload)
        ColorPicker:SetValueRGB(Payload.Color, Payload.Transparency)
    end,
}

ElementParser.KeyPicker = {
    Category = "Options",

    Save = function(KeyPicker)
        return { mode = KeyPicker.Mode, key = KeyPicker.Value, modifiers = KeyPicker.Modifiers, toggled = KeyPicker.Toggled }
    end,

    Check = function(_, Data)
        if typeof(Data.key) ~= "string" then
            return nil, "fatal", "key must be a string"
        end

        if Data.mode ~= nil and typeof(Data.mode) ~= "string" then
            return nil, "fatal", "mode must be a string"
        end

        if Data.toggled ~= nil and typeof(Data.toggled) ~= "boolean" then
            return nil, "fatal", "toggled must be true or false"
        end

        if Data.modifiers ~= nil then
            if not IsArray(Data.modifiers) then
                return nil, "fatal", "modifiers must be a list"
            end

            for _, Modifier in Data.modifiers do
                if typeof(Modifier) ~= "string" then
                    return nil, "fatal", "modifiers must be strings"
                end
            end
        end

        return { Key = Data.key, Mode = Data.mode, Modifiers = Data.modifiers, Toggled = Data.toggled }
    end,

    Apply = function(KeyPicker, Payload)
        KeyPicker:SetValue({ Payload.Key, Payload.Mode, Payload.Modifiers })
        if KeyPicker.Mode == "Toggle" and Payload.Toggled ~= nil then
            KeyPicker.Toggled = Payload.Toggled
            KeyPicker:Update()
        end

        local Notes = {}
        if Payload.Mode ~= nil and KeyPicker.Mode ~= Payload.Mode then
            table.insert(Notes, string.format("mode %q isn't offered, kept %q", Payload.Mode, tostring(KeyPicker.Mode)))
        end

        if KeyPicker.Value == "Unknown" and Payload.Key ~= "Unknown" then
            table.insert(Notes, string.format("key %q isn't recognised", Payload.Key))
        end

        return if #Notes > 0 then table.concat(Notes, "; ") else nil
    end,
}

--// Groupbox and tabbox layout. Personal to a screen, so share codes leave it out.
local function CreateLayoutParser(Type: string, Container: string, HasCollapse: boolean)
    ElementParser[Type] = {
        Category = "Layout",

        Save = function(Box, TabIndex)
            return {
                tabIdx = TabIndex,
                collapsed = if HasCollapse then Box.Collapsed else nil,
                poppedOut = Box.PoppedOut == true,
                popoutPos = if Box.PoppedOut and Box.PopOutFloat then SpecialValueParser.UDim2.Encode(Box.PopOutFloat.Position) else nil,
            }
        end,

        Find = function(Data)
            local Tabs = SaveManager.Library and SaveManager.Library.Tabs
            local Tab = Tabs and Tabs[Data.tabIdx]
            if not Tab then
                return nil, "no such tab in this script"
            end

            local Box = Tab[Container] and Tab[Container][Data.idx]
            if not Box then
                return nil, string.format("no such %s in this script", string.lower(Type))
            end

            return Box
        end,

        Check = function(_, Data)
            if Data.collapsed ~= nil and typeof(Data.collapsed) ~= "boolean" then
                return nil, "fatal", "collapsed must be true or false"
            end

            if Data.poppedOut ~= nil and typeof(Data.poppedOut) ~= "boolean" then
                return nil, "fatal", "poppedOut must be true or false"
            end

            local Position = nil
            if Data.popoutPos ~= nil then
                Position = SpecialValueParser.UDim2.Decode(Data.popoutPos)
                if Position == nil then
                    return nil, "fatal", "popoutPos is not a valid position"
                end
            end

            return { Collapsed = Data.collapsed, PoppedOut = Data.poppedOut == true, Position = Position }
        end,

        Apply = function(Box, Payload)
            if HasCollapse and Payload.Collapsed ~= nil and Box.Collapsed ~= Payload.Collapsed then
                Box:SetCollapsed(Payload.Collapsed)
            end

            if Box.PopOutEnabled then
                if Payload.PoppedOut then
                    Box:SetPoppedOut(true, Payload.Position)
                elseif Box.PoppedOut then
                    Box:SetPoppedOut(false)
                end
            end
        end,
    }
end

CreateLayoutParser("Groupbox", "Groupboxes", true)
CreateLayoutParser("Tabbox", "Tabboxes", false)

--// Helpers \\--
local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end

local function IsStringEmpty(String: string): boolean
    return if typeof(String) == "string" then Trim(String) == "" else true
end

local function IsValidFolderPath(Name: string): boolean
    return typeof(Name) == "string" and (
        Trim(Name) ~= "" and 
        not Name:match("^%s*$") and 
        not Name:find('[<>:"|%?%*%z]')
    )
end

--// Folder helper \\--
local function SplitPath(Path: string): {string}
    local Result = {}
    local Current = ""

    for Part in string.gmatch(Path, "[^/]+") do
        Current = if Current == "" then Part else (Current .. "/" .. Part)
        table.insert(Result, Current)
    end

    return Result
end

local function GetFolderPath(): false | string
    if IsStringEmpty(SaveManager.Folder) then
        return false
    end

    return string.format("%s/settings", SaveManager.Folder)
end

local function GetSubFolderPath(): false | string
    if IsStringEmpty(SaveManager.Folder) or IsStringEmpty(SaveManager.SubFolder) then
        return false
    end

    return string.format("%s/settings/%s", SaveManager.Folder, SaveManager.SubFolder)
end

local function GetCurrentSettingsPath(): false | string
    local SubFolderPath = GetSubFolderPath()
    return if SubFolderPath == false then GetFolderPath() else SubFolderPath
end

--// Files helper \\--
local function GetConfigPath(ConfigName: string): false | string
    local CurrentSettingsPath = GetCurrentSettingsPath()
    return if CurrentSettingsPath == false then false else string.format("%s/%s.json", CurrentSettingsPath, ConfigName)
end

local function DoesConfigExist(ConfigName: string): boolean
    local ConfigPath = GetConfigPath(ConfigName)
    return if ConfigPath == false then false else isfile(ConfigPath)
end

--// Per account mode keys the file by UserId, so each account can load a different config
local function GetAutoloadPath(): false | string
    local CurrentSettingsPath = GetCurrentSettingsPath()
    if CurrentSettingsPath == false then
        return false
    end

    local LocalPlayer = Players.LocalPlayer
    if SaveManager.AutoloadPerAccount and LocalPlayer then
        return string.format("%s/autoload_%d.txt", CurrentSettingsPath, LocalPlayer.UserId)
    end

    return string.format("%s/autoload.txt", CurrentSettingsPath)
end

local function GetManagerSettingsPath(): false | string
    local CurrentSettingsPath = GetCurrentSettingsPath()
    return if CurrentSettingsPath == false then false else string.format("%s/manager.txt", CurrentSettingsPath)
end

--// Indexes \\--
function SaveManager:SetLoadingOrder(Enabled: boolean, Order: {string}?)
    SaveManager.UseLoadingOrder = Enabled == true
    SaveManager.LoadingOrder = typeof(Order) == "table" and Order or SaveManager.LoadingOrder
end

function SaveManager:SetIgnoreIndexes(Indexes: {string}?)
    assert(typeof(Indexes) == "table", "Expected table, got " .. typeof(Indexes))

    for _, Index in Indexes do
        SaveManager.Ignore[Index] = true
    end
end

function SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({
        "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", "FontFace", "BackgroundImage",
        "ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName", "ThemeManager_ThemeJSON"
    })
end

--// Folders \\--
function SaveManager:GetPaths(): {string}
    local SubFolderPath = GetSubFolderPath()
    if SubFolderPath == false then
        local FolderPath = GetFolderPath()
        return if FolderPath == false then {} else SplitPath(FolderPath)
    end

    return SplitPath(SubFolderPath)
end

function SaveManager:BuildFolderTree(SkipWhenCreated: boolean?)
    local Paths = SaveManager:GetPaths()
    if #Paths == 0 then
        return false
    end

    if SkipWhenCreated == true then
        if isfolder(Paths[1]) then
            return true
        end
    end

    for _, Path in Paths do
        if isfolder(Path) then continue end
        
        makefolder(Path)
    end

    return true
end

function SaveManager:CheckFolderTree()
    return SaveManager:BuildFolderTree(true)
end

function SaveManager:CheckSubFolder(CreateFolder: boolean)
    local SubFolderPath = GetSubFolderPath()
    if SubFolderPath == false then
        return false
    end

    local FolderExists = isfolder(SubFolderPath)
    if not CreateFolder then
        return FolderExists
    end

    makefolder(SubFolderPath)
    return true
end

function SaveManager:SetFolder(Folder: string)
    assert(IsValidFolderPath(Folder), "Invalid path provided")

    SaveManager.Folder = Folder
    SaveManager:BuildFolderTree()
end

function SaveManager:SetSubFolder(SubFolder: string)
    assert(IsValidFolderPath(SubFolder), "Invalid path provided")

    SaveManager.SubFolder = SubFolder
    SaveManager:BuildFolderTree()
end

--// Config Management \\--
function SaveManager:RefreshConfigList()
    local SettingsPath = GetCurrentSettingsPath()
    if SettingsPath == false then
        return {}
    end

    pcall(makefolder, SettingsPath)
    local SuccessList, Files = pcall(listfiles, SettingsPath)
    if not (SuccessList and typeof(Files) == "table") then
        SaveManager.Library:Notify(string.format("Failed to load config list: %s", tostring(Files)))
        return {}
    end

    local FileNames = {}
    for _, FilePath in Files do
        local RawFileName = FilePath:match("(.+)%.json$")
        if not RawFileName then continue end

        local Position = RawFileName:gsub("\\", "/"):find("/[^/]*$")
        local FileName = Position and RawFileName:sub(Position + 1) or RawFileName
        if not FileName or FileName == "autoload" then continue end

        table.insert(FileNames, FileName)
    end

    return FileNames
end

--// Share exclusions \\--
--// Settings that stay out of share codes but are still saved in private configs:
--// personal URLs and the toggles that act on them. On import they are neither
--// taken from the code nor reset, so the recipient keeps their own.
function SaveManager:SetShareExclusions(Indexes: { string })
    assert(typeof(Indexes) == "table", "Expected table, got " .. typeof(Indexes))

    for _, Index in Indexes do
        SaveManager.ShareExclude[Index] = true
    end
end

--// Filter(Index, Element?, Data?) -> true to keep that setting out of shares.
--// Element is the local element (nil if it doesn't exist), Data the incoming entry
--// on import (nil on export).
function SaveManager:SetShareExcludeFilter(Filter: ((string, any?, any?) -> boolean)?)
    assert(Filter == nil or typeof(Filter) == "function", "Expected function, got " .. typeof(Filter))
    SaveManager.ShareExcludeFilter = Filter
end

local function LooksLikeURL(Text: any): boolean
    return typeof(Text) == "string" and Text:find("%a[%w+.-]*://%S") ~= nil
end

function SaveManager:IsShareExcluded(Index: string, Element: any?, Data: any?): boolean
    if SaveManager.ShareExclude[Index] then
        return true
    end

    local Filter = SaveManager.ShareExcludeFilter
    if typeof(Filter) == "function" then
        local Success, Excluded = pcall(Filter, Index, Element, Data)
        if Success and Excluded == true then
            return true
        end
    end

    --// On by default: an input holding a URL (a webhook, an invite) is personal
    if SaveManager.ShareExcludeURLs then
        if Element and Element.Type == "Input" and LooksLikeURL(Element.Value) then
            return true
        end

        if typeof(Data) == "table" and Data.type == "Input" and LooksLikeURL(Data.text) then
            return true
        end
    end

    return false
end

--// Saving \\--
--// Options first, then toggles, each sorted by index, so the file is stable and an
--// older loader that applies in file order still sets values before toggles.
local function CollectObjects(ForShare: boolean): ({ any }?, { string }, string?)
    local Library = SaveManager.Library
    local IgnoreIndexes = SaveManager.Ignore
    local Objects, Excluded = {}, {}

    for _, Category in { "Options", "Toggles" } do
        local Elements = Library[Category] or {}

        for _, Index in SortedKeys(Elements) do
            local Element = Elements[Index]
            if typeof(Index) ~= "string" or IgnoreIndexes[Index] then continue end

            local Parser = ElementParser[Element.Type]
            if not Parser or Parser.Category ~= Category then continue end

            if ForShare and SaveManager:IsShareExcluded(Index, Element, nil) then
                table.insert(Excluded, Index)
                continue
            end

            local Success, Data = pcall(Parser.Save, Element)
            if not Success then
                return nil, Excluded, string.format("Couldn't save %q: %s", Index, tostring(Data))
            end

            Data.type = Element.Type
            Data.idx = Index
            table.insert(Objects, Data)
        end
    end

    if ForShare then
        return Objects, Excluded, nil
    end

    for _, TabIndex in SortedKeys(Library.Tabs or {}) do
        local Tab = Library.Tabs[TabIndex]

        for _, Pair in { { "Groupbox", "Groupboxes" }, { "Tabbox", "Tabboxes" } } do
            local Type, Container = Pair[1], Pair[2]
            local Boxes = Tab[Container]
            if typeof(Boxes) ~= "table" then continue end

            for _, Index in SortedKeys(Boxes) do
                if typeof(Index) ~= "string" or IgnoreIndexes[Index] then continue end

                local Data = ElementParser[Type].Save(Boxes[Index], TabIndex)
                Data.type = Type
                Data.idx = Index
                table.insert(Objects, Data)
            end
        end
    end

    return Objects, Excluded, nil
end

function SaveManager:SaveJSON(ConfigName)
    local Library = SaveManager.Library
    local IgnoreIndexes = SaveManager.Ignore

    local Objects, _, ErrorMessage = CollectObjects(false)
    if not Objects then
        return "", false, ErrorMessage
    end

    local CurrentData = {
        version = CONFIG_VERSION,
        timestamp = os.date("%d.%m.%Y %H:%M:%S"),
        name = ConfigName or "",

        objects = Objects,
        keybindMenu = if Library.KeybindFrame then {
            visible = Library.KeybindFrame.Visible,
            position = SpecialValueParser.UDim2.Encode(Library.KeybindFrame.Position)
        } else nil,

        --// Window size & position. Ignored via SaveManager:SetIgnoreIndexes({ "WindowLayout" })
        window = if not IgnoreIndexes["WindowLayout"] and Library.Window and Library.Window.MainFrame then {
            size = SpecialValueParser.UDim2.Encode(Library.Window.MainFrame.Size),
            position = SpecialValueParser.UDim2.Encode(Library.Window.MainFrame.Position)
        } else nil
    }

    local SuccessEncode, EncodedData = pcall(HttpService.JSONEncode, HttpService, CurrentData)
    if not SuccessEncode then
        return "", false, "Failed to encode data"
    end

    return EncodedData, true
end

--// Settings only: window, keybind menu and groupbox layout are personal to the
--// sharer's screen, and share exclusions (see SetShareExclusions) are personal to
--// the sharer, so they all stay out. The fourth return lists the excluded indexes.
function SaveManager:ExportShareCode(): (string, boolean, string?, { Excluded: { string } }?)
    if SaveManager.Loading then
        return "", false, "A config is still loading"
    end

    local Objects, Excluded, ErrorMessage = CollectObjects(true)
    if not Objects then
        return "", false, ErrorMessage
    end

    local SuccessShare, Share = pcall(HttpService.JSONEncode, HttpService, {
        version = CONFIG_VERSION,
        kind = "share",
        objects = Objects,
    })
    if not SuccessShare then
        return "", false, "Failed to encode data"
    end

    return Share, true, nil, { Excluded = Excluded }
end

function SaveManager:Save(ConfigName: string): (boolean, string?)
    if IsStringEmpty(ConfigName) then
        return false, "Invalid config name provided"
    end

    if string.lower(ConfigName) == "autoload" then
        return false, "Invalid config name provided"
    end

    --// Mid-load the settings are half old, half new
    if SaveManager.Loading then
        return false, "A config is still loading"
    end

    local ConfigPath = GetConfigPath(ConfigName)
    if ConfigPath == false then
        return false, "Invalid config name provided"
    end

    SaveManager:CheckFolderTree()

    local EncodedData, SuccessEncode, EncodeErrorMessage = SaveManager:SaveJSON(ConfigName)
    if not SuccessEncode then
        return false, EncodeErrorMessage
    end

    local SuccessWrite, ErrorMessage = pcall(writefile, ConfigPath, EncodedData)
    if not SuccessWrite then
        return false, "Failed to write config file: " .. tostring(ErrorMessage)
    end

    SaveManager.LoadedConfig = ConfigName
    return true
end

--// Load lifecycle \\--
--[[
    Every load (Load, LoadJSON, ImportShareCode, LoadAutoloadConfig, ResetToDefaults)
    runs the same way:

      1. Validate. The whole config is checked against the live elements before
         anything changes: entry shapes, types, indexes, duplicates, values and
         compatibility. A broken config is rejected with nothing changed.
      2. OnLoadBegin(Context) listeners run.
      3. Settings apply in one pass, in the caller's thread: layout, then values,
         then toggles last. Callbacks may yield; the load waits for them.
      4. OnLoadFinish(Context, Report) listeners run, once, with the final report.
      5. The call returns (Success, ErrorMessage, Report).

    Begin and Finish always come in pairs and only for a config that passed
    validation. While they are between, SaveManager:IsLoading() is true.

    Context = {
        Source     = "Load" | "Autoload" | "Share" | "JSON" | "Reset",
        ConfigName = string?,          -- the file loaded, or the name a share saves as
        Mode       = "Snapshot" | "Merge",
    }

    Modes:
      Snapshot  settings the config leaves out go back to their defaults, so the
                result is the config and nothing else. Default for every source;
                share codes are always snapshots.
      Merge     settings the config leaves out keep their current values.
      Either way ignored indexes (SetIgnoreIndexes) are never touched, and on a
      share import the share exclusions are neither applied nor reset.

    Success is true only when every setting applied and no callback errored.
    There is no rollback: on failure the report says what applied and what didn't.

    Report = {
        Source, ConfigName, Mode, Version,  -- Version is the file's format
        Started, Completed, Success,
        Applied      = number,             -- settings set from the config
        Reset        = { index },          -- left out of a snapshot, set to default
        Problems     = { text },           -- why validation rejected the config
        Skipped      = { { Index, Type, Reason } },   -- entries this script can't use
        Excluded     = { index },          -- share exclusions left alone
        Ignored      = number,             -- entries for ignored indexes
        Unavailable  = { { Index, Values, Resolution, Selection } },
        Adjusted     = { { Index, Note } },            -- the element changed the value
        Migrations   = { text },           -- older formats that were read
        Warnings     = { text },
        Errors       = { { Index, Error } },           -- a setting failed to apply
        CallbackErrors = { { Index, Error } },         -- a callback errored while applying
    }
]]
local LoadListeners = { Begin = {}, Finish = {} }
local LoadBusy = false

local function Listen(Kind: string, Callback: (...any) -> ())
    assert(typeof(Callback) == "function", "Expected function, got " .. typeof(Callback))

    local List = LoadListeners[Kind]
    table.insert(List, Callback)

    return {
        Disconnect = function()
            local Position = table.find(List, Callback)
            if Position then
                table.remove(List, Position)
            end
        end,
    }
end

--// Before the first setting changes. Suspend gameplay activation here.
function SaveManager:OnLoadBegin(Callback: (Context: any) -> ())
    return Listen("Begin", Callback)
end

--// After the last setting applied (or failed). Reconcile gameplay once here.
function SaveManager:OnLoadFinish(Callback: (Context: any, Report: any) -> ())
    return Listen("Finish", Callback)
end

--// True between OnLoadBegin and the end of OnLoadFinish, plus the load's context
function SaveManager:IsLoading(): (boolean, any?)
    return SaveManager.Loading ~= nil, SaveManager.Loading
end

--// Resolver(Info) -> a selection, or nil to leave the unavailable values out.
--// Info = { Index, Element, Multi, Available, Unavailable, Source, ConfigName }.
--// Runs during validation, before anything changes. Whatever it returns is read
--// like any dropdown value and must be available.
function SaveManager:SetSelectionResolver(Resolver: ((any) -> any)?)
    assert(Resolver == nil or typeof(Resolver) == "function", "Expected function, got " .. typeof(Resolver))
    SaveManager.SelectionResolver = Resolver
end

local function NewReport(Context: any)
    return {
        Source = Context.Source,
        ConfigName = Context.ConfigName,
        Mode = Context.Mode,
        Version = nil,

        Started = false,
        Completed = false,
        Success = false,

        Applied = 0,
        Reset = {},
        Problems = {},
        Skipped = {},
        Excluded = {},
        Ignored = 0,
        Unavailable = {},
        Adjusted = {},
        Migrations = {},
        Warnings = {},
        Errors = {},
        CallbackErrors = {},
    }
end

local function ApplyOrderRank(Type: string): number
    local Custom = SaveManager.UseLoadingOrder == true and typeof(SaveManager.LoadingOrder) == "table" and SaveManager.LoadingOrder or nil
    local Default = table.find(DEFAULT_APPLY_ORDER, Type) or (#DEFAULT_APPLY_ORDER + 1)
    if Type == "KeybindMenu" or Type == "Window" then
        return 0
    end

    if not Custom then
        return Default
    end

    local Position = table.find(Custom, Type)
    return if Position then Position else #Custom + Default
end

--// Checks everything and builds the list of changes. Returns the plan, or nil when
--// the config is rejected (Report.Problems says why).
local function BuildPlan(Decoded: any, Context: any, Options: any)
    local Library = SaveManager.Library
    local Report = NewReport(Context)
    local IsShare = Context.Source == "Share"
    local Strict = Context.Strict
    local Plan = {}

    local function Problem(Where: string, Text: string)
        table.insert(Report.Problems, string.format("%s %s", Where, Text))
    end

    local function Migrate(Text: string)
        if not table.find(Report.Migrations, Text) then
            table.insert(Report.Migrations, Text)
        end
    end

    local function Incompatible(Index: string, Type: string, Where: string, Reason: string)
        if Strict then
            Problem(Where, Reason)
        else
            table.insert(Report.Skipped, { Index = Index, Type = Type, Reason = Reason })
        end
    end

    local function AddStep(Step)
        Step.Rank = ApplyOrderRank(Step.Type)
        table.insert(Plan, Step)
    end

    if typeof(Decoded) ~= "table" then
        Problem("config", "is not a JSON object")
        return nil, Report
    end

    --// Version
    local Version = Decoded.version
    if Version == nil then
        Version = 1
    elseif not (IsFiniteNumber(Version) and Version >= 1 and Version % 1 == 0) then
        Problem("version", "must be a whole number")
    end

    Report.Version = Version
    if Version == 1 then
        Migrate("format 1 config (no version field)")
    elseif IsFiniteNumber(Version) and Version > CONFIG_VERSION then
        local Text = string.format("was saved by a newer SaveManager (format %d, this is %d)", Version, CONFIG_VERSION)
        if Strict then
            Problem("config", Text)
        else
            table.insert(Report.Warnings, "Config " .. Text)
        end
    end

    --// Keybind menu and window. Personal to a screen, so a share never applies them.
    if Decoded.keybindMenu ~= nil and not IsShare then
        local Data = Decoded.keybindMenu
        local Position = typeof(Data) == "table" and Data.position ~= nil and SpecialValueParser.UDim2.Decode(Data.position) or nil

        if typeof(Data) ~= "table"
            or (Data.visible ~= nil and typeof(Data.visible) ~= "boolean")
            or (Data.position ~= nil and Position == nil)
        then
            Problem("keybindMenu", "is malformed")
        elseif Library.KeybindFrame then
            AddStep({
                Type = "KeybindMenu", Index = "KeybindMenu", Position = 0,
                Run = function()
                    local IsVisible = Data.visible == true
                    Library.KeybindFrame.Visible = IsVisible
                    Library.KeybindFrame.Position = Position or Library.KeybindFrame.Position

                    local KeybindMenuToggle = Library.Options and Library.Options.KeybindMenuOpen
                    if KeybindMenuToggle then
                        KeybindMenuToggle:SetValue(IsVisible)
                    end
                end,
            })
        end
    end

    if Decoded.window ~= nil and not IsShare and not SaveManager.Ignore["WindowLayout"] then
        local Data = Decoded.window
        local Size = typeof(Data) == "table" and Data.size ~= nil and SpecialValueParser.UDim2.Decode(Data.size) or nil
        local Position = typeof(Data) == "table" and Data.position ~= nil and SpecialValueParser.UDim2.Decode(Data.position) or nil

        if typeof(Data) ~= "table"
            or (Data.size ~= nil and Size == nil)
            or (Data.position ~= nil and Position == nil)
        then
            Problem("window", "is malformed")
        elseif Library.Window and Library.Window.SetSizePosition then
            AddStep({
                Type = "Window", Index = "WindowLayout", Position = 0,
                Run = function()
                    Library.Window:SetSizePosition(Size, Position)
                end,
            })
        end
    end

    --// Elements
    local Objects = Decoded.objects
    if not IsArray(Objects) then
        Problem("objects", "must be a list")
        return nil, Report
    end

    local Seen = {}
    local Planned = { Toggles = {}, Options = {} }

    for Position, Object in Objects do
        local Where = string.format("entry %d", Position)
        if typeof(Object) ~= "table" then
            Problem(Where, "is not an object")
            continue
        end

        local Type, Index = Object.type, Object.idx
        if typeof(Type) ~= "string" or Type == "" then
            Problem(Where, "has no type")
            continue
        end

        if typeof(Index) ~= "string" or Index == "" then
            Problem(Where, "has no idx")
            continue
        end

        Where = string.format("%s %q", Type, Index)

        local Parser = ElementParser[Type]
        if not Parser then
            Incompatible(Index, Type, Where, "is not a setting type this SaveManager knows")
            continue
        end

        local IsLayout = Parser.Category == "Layout"
        if IsLayout and typeof(Object.tabIdx) ~= "string" then
            Problem(Where, "has no tabIdx")
            continue
        end

        local Key = if IsLayout then string.format("%s\0%s\0%s", Type, Object.tabIdx, Index) else Parser.Category .. "\0" .. Index
        if Seen[Key] then
            Problem(Where, "appears more than once")
            continue
        end
        Seen[Key] = true

        if SaveManager.Ignore[Index] or (IsLayout and IsShare) then
            Report.Ignored += 1
            continue
        end

        local Element, MissingReason
        if IsLayout then
            Element, MissingReason = Parser.Find(Object)
        else
            local Elements = Library[Parser.Category]
            Element = Elements and Elements[Index]

            --// A share never sets or resets the recipient's personal settings
            if IsShare and SaveManager:IsShareExcluded(Index, Element, Object) then
                table.insert(Report.Excluded, Index)
                continue
            end

            if not Element then
                MissingReason = "is not a setting in this script"
            elseif Element.Type ~= Type then
                MissingReason = string.format("is a %s in this script", tostring(Element.Type))
                Element = nil
            end
        end

        if not Element then
            Incompatible(Index, Type, Where, MissingReason)
            continue
        end

        local Entry = {
            Migrate = Migrate,

            Adjust = function(Note: string)
                table.insert(Report.Adjusted, { Index = Index, Note = Note })
            end,

            Unavailable = function(Values: { any }, Resolution: string, Selection: any)
                table.insert(Report.Unavailable, { Index = Index, Values = Values, Resolution = Resolution, Selection = Selection })
            end,

            --// Unavailable dropdown values: the consumer's resolver decides, else they're left out
            Resolve = function(Available: { any }, Unavailable: { any })
                local Resolver = Options.ResolveUnavailable or SaveManager.SelectionResolver
                local Selection, Resolution = Available, "left out"

                if typeof(Resolver) == "function" then
                    local Success, Result = pcall(Resolver, {
                        Index = Index,
                        Element = Element,
                        Multi = Element.Multi == true,
                        Available = table.clone(Available),
                        Unavailable = table.clone(Unavailable),
                        Source = Context.Source,
                        ConfigName = Context.ConfigName,
                    })

                    if not Success then
                        Resolution = "left out (the resolver errored: " .. tostring(Result) .. ")"
                    elseif Result ~= nil then
                        local Resolved, StillUnavailable, ResolveProblem = Element:NormalizeValue(Result)
                        if ResolveProblem or #StillUnavailable > 0 then
                            Resolution = "left out (the resolver returned an unavailable selection)"
                        else
                            Selection, Resolution = Resolved, "resolved"
                        end
                    end
                end

                table.insert(Report.Unavailable, { Index = Index, Values = Unavailable, Resolution = Resolution, Selection = Selection })
                return Selection
            end,
        }

        local Success, Payload, Kind, Reason = pcall(Parser.Check, Element, Object, Entry)
        if not Success then
            Problem(Where, "could not be read: " .. tostring(Payload))
            continue
        end

        if Kind == "fatal" then
            Problem(Where, Reason)
            continue
        elseif Kind == "skip" then
            Incompatible(Index, Type, Where, Reason)
            continue
        end

        if not IsLayout then
            Planned[Parser.Category][Index] = true
        end

        AddStep({
            Type = Type, Index = Index, Position = Position,
            Run = function()
                return Parser.Apply(Element, Payload)
            end,
        })
    end

    if #Report.Problems > 0 then
        return nil, Report
    end

    --// Snapshot: whatever the config leaves out goes back to its default
    if Context.Mode == "Snapshot" then
        for _, Category in { "Options", "Toggles" } do
            local Elements = Library[Category] or {}

            for _, Index in SortedKeys(Elements) do
                local Element = Elements[Index]
                if typeof(Index) ~= "string" or Planned[Category][Index] or SaveManager.Ignore[Index] then continue end

                local Parser = ElementParser[Element.Type]
                if not Parser or Parser.Category ~= Category then continue end
                if IsShare and SaveManager:IsShareExcluded(Index, Element, nil) then continue end

                local Reset = ElementResetters[Element.Type]
                if not Reset or Element.Default == nil then
                    table.insert(Report.Warnings, string.format("%q is not in the config and has no default, so it kept its value", Index))
                    continue
                end

                AddStep({
                    Type = Element.Type, Index = Index, Position = math.huge, IsReset = true,
                    Run = function()
                        Reset(Element)
                    end,
                })
            end
        end
    end

    table.sort(Plan, function(A, B)
        if A.Rank ~= B.Rank then
            return A.Rank < B.Rank
        end

        if A.Position ~= B.Position then
            return A.Position < B.Position
        end

        return A.Index < B.Index
    end)

    return Plan, Report
end

local function FireListeners(Kind: string, Report: any, ...)
    for _, Callback in table.clone(LoadListeners[Kind]) do
        local Success, ErrorMessage = pcall(Callback, ...)
        if not Success then
            table.insert(Report.Errors, { Index = "OnLoad" .. Kind, Error = tostring(ErrorMessage) })
        end
    end
end

local function ApplyPlan(Plan: { any }, Context: any, Report: any)
    local Library = SaveManager.Library
    local Current = "OnLoadBegin"

    --// Count callback errors (SafeCallback swallows them) against the setting being applied
    local PreviousHook = Library.OnCallbackError
    Library.OnCallbackError = function(Error)
        table.insert(Report.CallbackErrors, { Index = Current, Error = tostring(Error) })

        if typeof(PreviousHook) == "function" then
            pcall(PreviousHook, Error)
        end
    end

    SaveManager.Loading = Context
    SaveManager.LoadGeneration += 1
    Report.Started = true

    local function UpdateSuccess()
        Report.Success = Report.Completed and #Report.Errors == 0 and #Report.CallbackErrors == 0
    end

    local SuccessRun, RunError = pcall(function()
        FireListeners("Begin", Report, Context)

        local Stopped = false
        for _, Step in Plan do
            if Library.Unloaded then
                Stopped = true
                table.insert(Report.Errors, { Index = Step.Index, Error = "the library unloaded before this setting applied" })
                break
            end

            Current = Step.Index
            local Success, Result = pcall(Step.Run)
            if not Success then
                table.insert(Report.Errors, { Index = Step.Index, Error = tostring(Result) })
                continue
            end

            if Step.IsReset then
                table.insert(Report.Reset, Step.Index)
            elseif Step.Type ~= "KeybindMenu" and Step.Type ~= "Window" then
                Report.Applied += 1
            end

            if typeof(Result) == "string" then
                table.insert(Report.Adjusted, { Index = Step.Index, Note = Result })
            end
        end

        Report.Completed = not Stopped
        UpdateSuccess()

        Current = "OnLoadFinish"
        FireListeners("Finish", Report, Context, Report)
    end)

    if not SuccessRun then
        table.insert(Report.Errors, { Index = Current, Error = tostring(RunError) })
    end

    UpdateSuccess()
    Library.OnCallbackError = PreviousHook
    SaveManager.Loading = nil
end

local function RejectMessage(Report: any): string
    local Count = #Report.Problems
    return string.format(
        "Config rejected, nothing was changed: %s%s",
        tostring(Report.Problems[1]),
        if Count > 1 then string.format(" (and %d more)", Count - 1) else ""
    )
end

local function FailureMessage(Report: any): string
    local Parts = {}

    if #Report.Errors > 0 then
        local First = Report.Errors[1]
        table.insert(Parts, string.format("%d setting(s) failed (%s: %s)", #Report.Errors, tostring(First.Index), First.Error))
    end

    if #Report.CallbackErrors > 0 then
        local First = Report.CallbackErrors[1]
        table.insert(Parts, string.format("%d callback error(s) (%s: %s)", #Report.CallbackErrors, tostring(First.Index), First.Error))
    end

    if not Report.Completed then
        table.insert(Parts, "the load stopped early")
    end

    return table.concat(Parts, ", ") .. ". The other settings were applied; nothing was rolled back."
end

local function DecodeConfig(Content: any): (any, string?)
    if typeof(Content) == "table" then
        return Content, nil
    end

    if IsStringEmpty(Content) then
        return nil, "No JSON provided"
    end

    local SuccessDecode, Decoded = pcall(HttpService.JSONDecode, HttpService, Trim(Content))
    if not SuccessDecode or typeof(Decoded) ~= "table" then
        return nil, "Failed to decode config data"
    end

    return Decoded, nil
end

local function MakeContext(Options: any): (any, string?)
    local Source = Options.Source or "JSON"
    local Mode = if Source == "Share" then "Snapshot" else (Options.Mode or SaveManager.DefaultLoadMode)
    if Mode ~= "Snapshot" and Mode ~= "Merge" then
        return nil, string.format("Unknown load mode %q", tostring(Mode))
    end

    return {
        Source = Source,
        ConfigName = Options.ConfigName,
        Mode = Mode,
        Strict = if Options.Strict ~= nil then Options.Strict == true else SaveManager.StrictLoad == true,
    }, nil
end

--// Checks a config against the live elements without changing anything.
--// Returns (valid, errorMessage, report). Takes the same options as LoadJSON.
function SaveManager:ValidateConfig(Content: string | { [string]: any }, Options: any?): (boolean, string?, any?)
    Options = Options or {}

    local Context, ContextError = MakeContext(Options)
    if not Context then
        return false, ContextError, nil
    end

    local Decoded, DecodeError = DecodeConfig(Content)
    if not Decoded then
        return false, DecodeError, nil
    end

    local Plan, Report = BuildPlan(Decoded, Context, Options)
    if not Plan then
        return false, RejectMessage(Report), Report
    end

    return true, nil, Report
end

--// Options = {
--//     Source = "JSON",            -- reported in the context
--//     ConfigName = nil,
--//     Mode = SaveManager.DefaultLoadMode,  -- "Snapshot" or "Merge"; shares are always snapshots
--//     Strict = SaveManager.StrictLoad,     -- reject instead of skipping entries this script can't use
--//     ResolveUnavailable = nil,   -- per-load SelectionResolver
--// }
--// Returns (Success, ErrorMessage, Report) once everything has applied.
function SaveManager:LoadJSON(Content: string | { [string]: any }, Options: any?): (boolean, string?, any?)
    Options = Options or {}

    if LoadBusy then
        return false, "Another config is still loading", nil
    end

    local Context, ContextError = MakeContext(Options)
    if not Context then
        return false, ContextError, nil
    end

    local Decoded, DecodeError = DecodeConfig(Content)
    if not Decoded then
        return false, DecodeError, nil
    end

    LoadBusy = true
    local SuccessRun, Plan, Report = pcall(BuildPlan, Decoded, Context, Options)
    if not SuccessRun then
        LoadBusy = false
        return false, "Couldn't check the config: " .. tostring(Plan), nil
    end

    if not Plan then
        LoadBusy = false
        return false, RejectMessage(Report), Report
    end

    ApplyPlan(Plan, Context, Report)
    LoadBusy = false

    if Report.Success then
        return true, nil, Report
    end

    return false, FailureMessage(Report), Report
end

function SaveManager:Load(ConfigName: string, Options: any?): (boolean, string?, any?)
    if IsStringEmpty(ConfigName) then
        return false, "No config is selected"
    end

    local ConfigPath = GetConfigPath(ConfigName)
    if ConfigPath == false or not isfile(ConfigPath) then
        return false, "Config file does not exist"
    end

    local SuccessRead, Content = pcall(readfile, ConfigPath)
    if not SuccessRead then
        return false, "Failed to read config file"
    end

    Options = table.clone(Options or {})
    Options.Source = Options.Source or "Load"
    Options.ConfigName = ConfigName

    local Success, ErrorMessage, Report = SaveManager:LoadJSON(Content, Options)
    if Success then
        SaveManager.LoadedConfig = ConfigName
    elseif Report and Report.Started then
        --// Settings are part applied: don't let autosave write them into any config
        SaveManager.LoadedConfig = nil
    end

    return Success, ErrorMessage, Report
end

--// Applies a share code as a snapshot and, only once every setting and callback
--// has finished without error, saves it as TargetConfig. Returns (Success,
--// ErrorMessage, Report). A code that fails validation changes nothing.
function SaveManager:ImportShareCode(Code: string, TargetConfig: string, Options: any?): (boolean, string?, any?)
    if IsStringEmpty(TargetConfig) or string.lower(Trim(TargetConfig)) == "autoload" or GetConfigPath(Trim(TargetConfig)) == false then
        return false, "Invalid config name provided"
    end

    TargetConfig = Trim(TargetConfig)
    Options = table.clone(Options or {})
    Options.Source = "Share"
    Options.ConfigName = TargetConfig

    --// Detach first so autosave can't write the code into the previous config
    local PreviousConfig = SaveManager.LoadedConfig
    SaveManager.LoadedConfig = nil

    local Success, ErrorMessage, Report = SaveManager:LoadJSON(Code, Options)
    if not Success then
        if not (Report and Report.Started) then
            SaveManager.LoadedConfig = PreviousConfig
        end

        return false, ErrorMessage, Report
    end

    local SuccessSave, SaveErrorMessage = SaveManager:Save(TargetConfig)
    if not SuccessSave then
        return false, string.format("Settings applied, but couldn't save %q: %s", TargetConfig, tostring(SaveErrorMessage)), Report
    end

    return true, nil, Report
end

--// One line for a notification: what a load skipped, reset, adjusted or migrated
function SaveManager:FormatReport(Report: any): string
    if typeof(Report) ~= "table" then
        return ""
    end

    local Parts = {}
    local function Add(Count: number, Text: string)
        if Count > 0 then
            table.insert(Parts, string.format(Text, Count))
        end
    end

    Add(#Report.Skipped, "%d skipped")
    Add(#Report.Unavailable, "%d unavailable selection(s)")
    Add(#Report.Adjusted, "%d adjusted")
    Add(#Report.Excluded, "%d personal kept")
    if Report.Mode == "Snapshot" and Report.Source ~= "Reset" then
        Add(#Report.Reset, "%d reset to default")
    end

    if #Report.Migrations > 0 then
        table.insert(Parts, "updated from an older format")
    end

    return table.concat(Parts, ", ")
end

--// Reads a saved config off disk as-is, for copying it out of the menu. This is
--// the stored file rather than a re-encode of the live settings, so what lands on
--// the clipboard is exactly what "Load config" would apply.
function SaveManager:CopyToClipboard(ConfigName: string): (boolean, string?)
    if IsStringEmpty(ConfigName) then
        return false, "No config is selected"
    end

    if not setclipboard then
        return false, "Your executor does not support setclipboard"
    end

    local ConfigPath = GetConfigPath(ConfigName)
    if ConfigPath == false or not isfile(ConfigPath) then
        return false, "Config file does not exist"
    end

    local SuccessRead, Content = pcall(readfile, ConfigPath)
    if not SuccessRead then
        return false, "Failed to read config file"
    end

    local SuccessCopy, ErrorMessage = pcall(setclipboard, Content)
    if not SuccessCopy then
        return false, "Failed to copy to clipboard: " .. tostring(ErrorMessage)
    end

    return true
end

function SaveManager:Delete(ConfigName: string): (boolean | string?)
    if IsStringEmpty(ConfigName) then
        return false, "No config is selected"
    end

    local ConfigPath = GetConfigPath(ConfigName)
    if ConfigPath == false or not isfile(ConfigPath) then
        return false, "Config file does not exist"
    end

    local SuccessDelete, ErrorMessage = pcall(delfile, ConfigPath)
    if not SuccessDelete then
        return false, "Failed to delete config file: " .. tostring(ErrorMessage)
    end

    if ConfigName == SaveManager.AutoloadConfig then
        SaveManager:DeleteAutoLoadConfig()
    end

    if ConfigName == SaveManager.LoadedConfig then
        SaveManager.LoadedConfig = nil
    end

    return true
end

--// Auto Load Config \\--
function SaveManager:GetAutoloadConfig(): (string, boolean, string?)
    SaveManager:CheckFolderTree()
    SaveManager.AutoloadConfig = nil

    local AutoloadPath = GetAutoloadPath()
    if AutoloadPath == false then
        return "none", false, "Invalid path provided"
    end

    if not isfile(AutoloadPath) then
        return "none", false, "Autoload config is not set"
    end

    local SuccessRead, AutoloadConfigName = pcall(readfile, AutoloadPath)
    if not (SuccessRead and typeof(AutoloadConfigName) == "string") then
        return "none", false, AutoloadConfigName
    end

    local ConfigExists = DoesConfigExist(AutoloadConfigName)
    if not ConfigExists then
        return "none", false, "Config file not found"
    end

    SaveManager.AutoloadConfig = AutoloadConfigName
    return AutoloadConfigName, true
end

function SaveManager:SaveAutoloadConfig(ConfigName: string): (boolean, string?)
    if IsStringEmpty(ConfigName) then
        return false, "No config is selected"
    end

    SaveManager:CheckFolderTree()

    local AutoloadPath = GetAutoloadPath()
    if AutoloadPath == false then
        return false, "Invalid path provided"
    end

    if not DoesConfigExist(ConfigName) then
        return false, "Config does not exist"
    end

    local SuccessWrite, ErrorMessage = pcall(writefile, AutoloadPath, ConfigName)
    if not SuccessWrite then
        return false, ErrorMessage
    end

    SaveManager.AutoloadConfig = ConfigName
    return true
end

function SaveManager:LoadAutoloadConfig()
    SaveManager:LoadManagerSettings()

    local ConfigName, Success, FetchErrorMessage = SaveManager:GetAutoloadConfig()
    if not Success or FetchErrorMessage then
        if FetchErrorMessage ~= "Autoload config is not set" then
            SaveManager.Library:Notify(string.format("Couldn't load your start config: %s", FetchErrorMessage))
        end

        return
    end

    local SuccessLoad, LoadErrorMessage, Report = SaveManager:Load(ConfigName, { Source = "Autoload" })
    if not SuccessLoad then
        SaveManager.Library:Notify(string.format("Couldn't load your start config: %s", LoadErrorMessage))
        return false, LoadErrorMessage, Report
    end

    local Summary = SaveManager:FormatReport(Report)
    SaveManager.Library:Notify(if Summary ~= ""
        then string.format("Loaded config %q (%s)", ConfigName, Summary)
        else string.format("Loaded config %q", ConfigName))

    return true, nil, Report
end

function SaveManager:DeleteAutoLoadConfig(): (boolean, string?)
    SaveManager:CheckFolderTree()

    local AutoloadPath = GetAutoloadPath()
    if AutoloadPath == false then
        return false, "Invalid path provided"
    end

    if not isfile(AutoloadPath) then
        return false, "Autoload config is not set"
    end

    local SuccessDelete, ErrorMessage = pcall(delfile, AutoloadPath)
    if not SuccessDelete then
        return false, ErrorMessage
    end

    SaveManager.AutoloadConfig = nil
    return true
end

--// Reset \\--
--// Puts every saved element back to the value it was created with, through the
--// load lifecycle (Source "Reset"). Ignored indexes are left alone, same as Save
--// and Load do. Returns (Success, ErrorMessage, Report) like LoadJSON.
function SaveManager:ResetToDefaults(): (boolean, string?, any?)
    return SaveManager:LoadJSON({ version = CONFIG_VERSION, objects = {} }, { Source = "Reset", Mode = "Snapshot" })
end

--// Empties a folder file by file, for executors without delfolder
local function DeleteFolderContents(FolderPath: string): number
    local Failed = 0

    local SuccessList, Entries = pcall(listfiles, FolderPath)
    if not SuccessList or typeof(Entries) ~= "table" then
        return 1
    end

    for _, EntryPath in Entries do
        if isfolder(EntryPath) then
            Failed += DeleteFolderContents(EntryPath)
        elseif not pcall(delfile, EntryPath) then
            Failed += 1
        end
    end

    return Failed
end

--// Deletes the whole workspace folder (configs, themes, everything this script saved),
--// then kicks the player so the script starts clean on rejoin.
function SaveManager:ResetAll(): (boolean, string?)
    SaveManager.Autosave = false
    SaveManager.AutoloadPerAccount = false
    SaveManager.AutoloadConfig = nil
    SaveManager.LoadedConfig = nil

    local Folder = SaveManager.Folder
    local ErrorMessage

    if not IsStringEmpty(Folder) and isfolder(Folder) then
        local Deleted = typeof(delfolder) == "function" and pcall(delfolder, Folder)
        if not Deleted or isfolder(Folder) then
            local Failed = DeleteFolderContents(Folder)
            pcall(delfolder, Folder)

            if Failed > 0 then
                ErrorMessage = string.format("%d file(s) could not be deleted", Failed)
            end
        end
    end

    local LocalPlayer = Players.LocalPlayer
    if LocalPlayer then
        LocalPlayer:Kick("Your settings were reset. Rejoin to start fresh.")
    end

    return ErrorMessage == nil, ErrorMessage
end

--// Manager Settings \\--
function SaveManager:LoadManagerSettings()
    local SettingsPath = GetManagerSettingsPath()
    if SettingsPath == false or not isfile(SettingsPath) then
        return
    end

    local SuccessRead, Content = pcall(readfile, SettingsPath)
    if not SuccessRead then return end

    local SuccessDecode, Decoded = pcall(HttpService.JSONDecode, HttpService, Content)
    if not SuccessDecode or typeof(Decoded) ~= "table" then return end

    SaveManager.AutoloadPerAccount = Decoded.AutoloadPerAccount == true
    SaveManager:SetAutosave(Decoded.Autosave == true)
end

function SaveManager:SaveManagerSettings(): (boolean, string?)
    SaveManager:CheckFolderTree()

    local SettingsPath = GetManagerSettingsPath()
    if SettingsPath == false then
        return false, "Invalid path provided"
    end

    local SuccessEncode, Encoded = pcall(HttpService.JSONEncode, HttpService, {
        AutoloadPerAccount = SaveManager.AutoloadPerAccount,
        Autosave = SaveManager.Autosave,
    })
    if not SuccessEncode then
        return false, "Failed to encode settings"
    end

    local SuccessWrite, ErrorMessage = pcall(writefile, SettingsPath, Encoded)
    if not SuccessWrite then
        return false, tostring(ErrorMessage)
    end

    return true
end

function SaveManager:SetAutoloadPerAccount(Enabled: boolean)
    SaveManager.AutoloadPerAccount = Enabled == true
    SaveManager:SaveManagerSettings()
end

--// Autosave \\--
--// No library-wide change signal exists, so poll: re-encode the settings and write
--// the loaded config only when they differ from the last snapshot.
local AUTOSAVE_INTERVAL = 2
local AutosaveRunning = false

local function StripTimestamp(Data: string): string
    return (Data:gsub('"timestamp":"[^"]*"', ""))
end

function SaveManager:SetAutosave(Enabled: boolean)
    SaveManager.Autosave = Enabled == true
    SaveManager:SaveManagerSettings()

    if not SaveManager.Autosave or AutosaveRunning then
        return
    end

    AutosaveRunning = true
    task.spawn(function()
        local LastConfig, LastData = nil, nil
        local LastGeneration = SaveManager.LoadGeneration

        while SaveManager.Autosave do
            task.wait(AUTOSAVE_INTERVAL)

            local Library = SaveManager.Library
            if not Library or Library.Unloaded then break end

            --// Never snapshot or write a half-applied load, and start over after one
            if SaveManager.Loading then continue end
            if SaveManager.LoadGeneration ~= LastGeneration then
                LastGeneration, LastConfig, LastData = SaveManager.LoadGeneration, nil, nil
            end

            local ConfigName = SaveManager.LoadedConfig
            if not ConfigName or not DoesConfigExist(ConfigName) then continue end

            local EncodedData, SuccessEncode = SaveManager:SaveJSON(ConfigName)
            if not SuccessEncode then continue end

            local Comparable = StripTimestamp(EncodedData)
            if ConfigName ~= LastConfig then
                --// First pass on a config only takes a snapshot, so loading never writes
                LastConfig, LastData = ConfigName, Comparable
                continue
            end

            if Comparable == LastData then continue end

            local ConfigPath = GetConfigPath(ConfigName)
            if ConfigPath and pcall(writefile, ConfigPath, EncodedData) then
                LastData = Comparable
            end
        end

        AutosaveRunning = false
    end)
end

--// GUI \\--
local function ShowDialog(
    Condition: () -> boolean,

    Index: string, 
    Title: string, 
    Description: string,

    DestructiveText: string,
    DestructiveAction: () -> nil
)
    if Condition() == false then
        return DestructiveAction()
    end

    return SaveManager.Library.Window:AddDialog(Index, {
        Title = Title,
        Description = Description,
        AutoDismiss = false,

        FooterButtons = {
            Cancel = {
                Title = "Cancel",
                Variant = "Ghost",
                Order = 1,
                Callback = function(Dialog)
                    Dialog:Dismiss()
                end
            },

            DestructiveAction = {
                Title = DestructiveText,
                Variant = "Destructive",
                Order = 2,
                Callback = function(Dialog)
                    Dialog:Dismiss()
                    DestructiveAction()
                end
            }
        }
    })
end

function SaveManager:BuildConfigSection(Tab: any, IconName: string)
    assert(SaveManager.Library, "Library is not set, call SaveManager:SetLibrary(Library) first.")
    local ConfigurationBox = Tab:AddGroupbox({
        Side = "Right",
        Name = "Configs",
        IconName = IconName or "folder-cog",
    })

    SaveManager:LoadManagerSettings()

    local ConfigNameInput, ConfigList, ConfigJSONInput, ShareNameInput, AutoloadConfigLabel
    local function Notify(Text: string, ...)
        SaveManager.Library:Notify(string.format(Text, ...))
    end

    local function RefreshList()
        ConfigList:SetValues(SaveManager:RefreshConfigList())
        ConfigList:SetValue(nil)
    end

    local function RefreshAutoloadConfigLabel()
        local AutoloadConfigName, _Success, _ErrorMessage = SaveManager:GetAutoloadConfig()

        AutoloadConfigLabel:SetText(string.format("Loads on start: %s", AutoloadConfigName))
        if ConfigList then RefreshList() end
    end

    local function GetSelectedConfig(): string?
        local ConfigName = ConfigList.Value
        if IsStringEmpty(ConfigName) then
            Notify("Pick a config first.")
            return nil
        end

        return ConfigName
    end

    local function FormatConfig(Value: any)
        if Value == SaveManager.AutoloadConfig then
            return string.format("%s (on start)", Value)
        end

        return Value
    end

    --// New config
    ConfigurationBox:AddInput("SaveManager_ConfigName", {
        Text = "Config name",
        Placeholder = "name...",
    })

    ConfigurationBox:AddButton("Save as new config", function()
        local ConfigName = ConfigNameInput.Value
        if IsStringEmpty(ConfigName) then
            Notify("Type a name first.")
            return
        end

        if string.lower(ConfigName) == "autoload" then
            Notify("That name is reserved, pick another.")
            return
        end

        ShowDialog(
            function(): boolean
                return DoesConfigExist(ConfigName)
            end,

            "SaveManager_CreateConfig",
            "Name taken",
            string.format("%q already exists. Replace it with your current settings?", ConfigName),

            "Replace",
            function()
                local Success, ErrorMessage = SaveManager:Save(ConfigName)
                if not Success then
                    Notify("Couldn't save %q: %s", ConfigName, tostring(ErrorMessage))
                    return
                end

                Notify("Saved %q", ConfigName)
                RefreshList()
            end
        )
    end)

    ConfigurationBox:AddDivider()

    --// Saved configs
    ConfigurationBox:AddDropdown("SaveManager_ConfigList", {
        Text = "Saved configs",

        Values = SaveManager:RefreshConfigList(),
        AllowNull = true,
        Multi = false,

        FormatDisplayValue = FormatConfig,
        FormatListValue = FormatConfig,
    })

    ConfigurationBox:AddButton({
        Text = "Load",
        DoubleClick = false,

        Func = function()
            local ConfigName = GetSelectedConfig()
            if not ConfigName then return end

            ShowDialog(
                function(): boolean
                    return true --// Always show
                end,

                "SaveManager_LoadConfig",
                "Load config",
                string.format("Switch to %q? Unsaved changes will be lost.", ConfigName),

                "Load",
                function()
                    local Success, ErrorMessage, Report = SaveManager:Load(ConfigName)
                    if not Success then
                        Notify("Couldn't load %q: %s", ConfigName, tostring(ErrorMessage))
                        return
                    end

                    local Summary = SaveManager:FormatReport(Report)
                    if Summary ~= "" then
                        Notify("Loaded %q (%s)", ConfigName, Summary)
                    else
                        Notify("Loaded %q", ConfigName)
                    end
                end
            )
        end
    }):AddButton({
        Text = "Update",
        DoubleClick = false,
        Tooltip = "Save your current settings into this config",

        Func = function()
            local ConfigName = GetSelectedConfig()
            if not ConfigName then return end

            ShowDialog(
                function(): boolean
                    return true --// Always show
                end,

                "SaveManager_OverwriteConfig",
                "Update config",
                string.format("Replace %q with your current settings?", ConfigName),

                "Update",
                function()
                    local Success, ErrorMessage = SaveManager:Save(ConfigName)
                    if not Success then
                        Notify("Couldn't update %q: %s", ConfigName, tostring(ErrorMessage))
                        return
                    end

                    Notify("Updated %q", ConfigName)
                end
            )
        end
    })

    ConfigurationBox:AddButton({
        Text = "Load on start",
        DoubleClick = false,
        Tooltip = "Load this config every time the script starts",

        Func = function()
            local ConfigName = GetSelectedConfig()
            if not ConfigName then return end

            local Success, ErrorMessage = SaveManager:SaveAutoloadConfig(ConfigName)
            if not Success then
                Notify("Couldn't set %q: %s", ConfigName, tostring(ErrorMessage))
                return
            end

            Notify("%q will load on start", ConfigName)
            RefreshAutoloadConfigLabel()
        end
    }):AddButton({
        Text = "Delete",
        DoubleClick = false,
        Risky = true,

        Func = function()
            local ConfigName = GetSelectedConfig()
            if not ConfigName then return end

            ShowDialog(
                function(): boolean
                    return true --// Always show
                end,

                "SaveManager_DeleteConfig",
                "Delete config",
                string.format("Delete %q for good?", ConfigName),

                "Delete",
                function()
                    local Success, ErrorMessage = SaveManager:Delete(ConfigName)
                    if not Success then
                        Notify("Couldn't delete %q: %s", ConfigName, tostring(ErrorMessage))
                        return
                    end

                    Notify("Deleted %q", ConfigName)
                    RefreshAutoloadConfigLabel()
                end
            )
        end
    })

    AutoloadConfigLabel = ConfigurationBox:AddLabel("Loads on start: ...", true)

    ConfigurationBox:AddButton({
        Text = "Don't load on start",
        DoubleClick = false,

        Func = function()
            local Success, ErrorMessage = SaveManager:DeleteAutoLoadConfig()
            if not Success then
                Notify("Couldn't change it: %s", tostring(ErrorMessage))
                return
            end

            Notify("No config will load on start.")
            RefreshAutoloadConfigLabel()
        end
    }):AddButton("Refresh", RefreshList)

    ConfigurationBox:AddDropdown("SaveManager_AutoloadMode", {
        Text = "Load on start for",
        Values = { "All accounts", "This account only" },
        Default = if SaveManager.AutoloadPerAccount then "This account only" else "All accounts",

        Callback = function(Value)
            SaveManager:SetAutoloadPerAccount(Value == "This account only")
            if AutoloadConfigLabel then RefreshAutoloadConfigLabel() end
        end
    })

    ConfigurationBox:AddToggle("SaveManager_Autosave", {
        Text = "Save changes automatically",
        Tooltip = "Keeps the loaded config updated as you change settings",
        Default = SaveManager.Autosave,

        Callback = function(Value)
            SaveManager:SetAutosave(Value)
        end
    })

    ConfigurationBox:AddDivider()

    --// Share
    ConfigurationBox:AddInput("SaveManager_JSON", {
        Text = "Share code",
        Placeholder = "paste a code...",
    })

    ConfigurationBox:AddInput("SaveManager_ShareName", {
        Text = "Save code as",
        Placeholder = "new config name...",
    })

    ConfigurationBox:AddButton("Copy my code", function()
        local EncodedData, Success, ErrorMessage, ShareReport = SaveManager:ExportShareCode()
        if not Success then
            Notify("%s", tostring(ErrorMessage))
            return
        end

        ConfigJSONInput:SetValue(EncodedData)

        local ExcludedCount = #ShareReport.Excluded
        local Kept = if ExcludedCount > 0 then string.format(" (%d personal setting(s) left out)", ExcludedCount) else ""
        if setclipboard then
            setclipboard(EncodedData)
            Notify("Code copied%s", Kept)
        elseif Kept ~= "" then
            Notify("Code ready%s", Kept)
        end
    end):AddButton("Use code", function()
        local ConfigJSON = ConfigJSONInput.Value
        if IsStringEmpty(ConfigJSON) then
            Notify("Paste a code first.")
            return
        end

        --// A code always lands in its own config, never over the loaded one
        local TargetConfig = Trim(ShareNameInput.Value or "")
        if IsStringEmpty(TargetConfig) then
            Notify("Name the new config first.")
            return
        end

        if string.lower(TargetConfig) == "autoload" or GetConfigPath(TargetConfig) == false then
            Notify("That name can't be used, pick another.")
            return
        end

        local Exists = DoesConfigExist(TargetConfig)
        ShowDialog(
            function(): boolean
                return true --// Always show
            end,

            "SaveManager_ImportConfig",
            if Exists then "Name taken" else "Use share code",
            if Exists
                then string.format("%q already exists. Replace it with this code's settings?", TargetConfig)
                else string.format("Apply these settings and save them as %q? Unsaved changes will be lost.", TargetConfig),

            if Exists then "Replace" else "Apply",
            function()
                --// Validates the whole code first, applies it as a snapshot, and saves
                --// only after every setting (and its callbacks) finished cleanly
                local Success, ErrorMessage, Report = SaveManager:ImportShareCode(ConfigJSON, TargetConfig)
                if not Success then
                    if Report and Report.Success then
                        Notify("%s", tostring(ErrorMessage)) --// Applied, the save itself failed
                    elseif Report and Report.Started then
                        Notify("Applied with errors, not saved as %q: %s", TargetConfig, tostring(ErrorMessage))
                    else
                        Notify("That code didn't work: %s", tostring(ErrorMessage))
                    end

                    return
                end

                ConfigJSONInput:SetValue("")
                ShareNameInput:SetValue("")

                local Summary = SaveManager:FormatReport(Report)
                if Summary ~= "" then
                    Notify("Saved the code as %q (%s)", TargetConfig, Summary)
                else
                    Notify("Saved the code as %q", TargetConfig)
                end

                RefreshList()
            end
        )
    end)

    ConfigurationBox:AddDivider()

    --// Reset
    ConfigurationBox:AddButton({
        Text = "Reset all settings",
        DoubleClick = false,
        Risky = true,

        Func = function()
            ShowDialog(
                function(): boolean
                    return true --// Always show
                end,

                "SaveManager_ResetAll",
                "Reset all settings",
                string.format(
                    "This deletes your whole %q folder: every config, theme and saved setting. You will be kicked from the game and need to rejoin. This cannot be undone.",
                    tostring(SaveManager.Folder)
                ),

                "Delete and kick",
                function()
                    local Success, ErrorMessage = SaveManager:ResetAll()

                    --// Only reached if the kick did not go through
                    if not Success then
                        Notify("Reset, but %s", tostring(ErrorMessage))
                    end
                end
            )
        end
    })

    --// Set variables
    ConfigNameInput, ConfigList, ConfigJSONInput, ShareNameInput =
        SaveManager.Library.Options.SaveManager_ConfigName,
        SaveManager.Library.Options.SaveManager_ConfigList,
        SaveManager.Library.Options.SaveManager_JSON,
        SaveManager.Library.Options.SaveManager_ShareName;

    --// Refresh
    RefreshAutoloadConfigLabel()
    SaveManager:SetIgnoreIndexes({
        "SaveManager_ConfigList", "SaveManager_ConfigName", "SaveManager_JSON", "SaveManager_ShareName",
        "SaveManager_AutoloadMode", "SaveManager_Autosave"
    })

    return ConfigurationBox
end

SaveManager:BuildFolderTree()
return SaveManager
