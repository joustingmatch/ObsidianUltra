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

    AutoloadConfig = nil,
    LoadedConfig = nil,

    --// Kept in manager.txt next to the profiles
    AutoloadPerAccount = false,
    Autosave = false,
}

function SaveManager:SetLibrary(Library)
    SaveManager.Library = Library
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
            if DataType == "table" then
                return UDim2.new(Data.X.Scale, Data.X.Offset, Data.Y.Scale, Data.Y.Offset)
            elseif DataType == "UDim2" then
                return Data
            end

            return nil
        end
    }
}

local ElementParser = {}; do
    local function CreateParser(
        ElementType: string, 
        LibaryIndex: string, 
        
        Save: (string, any, ...any) -> any, 
        Load: (any?, any) -> any,
        CustomElementFetcher: boolean?
    )
        ElementParser[ElementType] = { 
            Save = function(Index: string, Element: any, ...)
                local Data = Save(Index, Element, ...)
                Data.type = ElementType
                Data.idx = Index

                return Data
            end, 

            Load = function(Index: string?, Data: any)
                if CustomElementFetcher == true then
                    return Load(nil, Data)
                end

                local Elements = SaveManager.Library and SaveManager.Library[LibaryIndex]
                local Element = Elements and Elements[Index]
                return Load(Element, Data)
            end
        }
    end

    CreateParser(
        "Toggle", "Toggles",
        function(Index: string, Toggle: any)
            return { value = Toggle.Value }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if Element.Value == Data.value then
                Element:RunChanged()
                return
            end
            
            Element:SetValue(Data.value)
        end
    )

    CreateParser(
        "Slider", "Options",
        function(Index: string, Slider: any)
            return { value = tostring(Slider.Value) }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if Element.Value == Data.value then
                Element:RunChanged()
                return
            end

            Element:SetValue(Data.value)
        end
    )

    CreateParser(
        "Dropdown", "Options",
        function(Index: string, Dropdown: any)
            return { value = Dropdown.Value, multi = Dropdown.Multi }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if Element.Value == Data.value then
                Element:RunChanged()
                return
            end
            
            Element:SetValue(Data.value)
        end
    )

    CreateParser(
        "PriorityDropdown", "Options",
        function(Index: string, Priority: any)
            return { order = Priority:GetValue() }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if typeof(Data.order) ~= "table" then
                Element:RunChanged()
                return
            end

            Element:SetValue(Data.order)
        end
    )

    CreateParser(
        "ColorPicker", "Options",
        function(Index: string, ColorPicker: any)
            return { value = ColorPicker.Value:ToHex(), transparency = ColorPicker.Transparency }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            
            Element:SetValueRGB(Color3.fromHex(Data.value), Data.transparency)
        end
    )

    CreateParser(
        "KeyPicker", "Options",
        function(Index: string, KeyPicker: any)
            return { mode = KeyPicker.Mode, key = KeyPicker.Value, modifiers = KeyPicker.Modifiers, toggled = KeyPicker.Toggled }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            
            Element:SetValue({ Data.key, Data.mode, Data.modifiers })
            if Data.mode == "Toggle" and Data.toggled ~= nil then
                Element.Toggled = Data.toggled
                Element:Update()
            end
        end
    )

    CreateParser(
        "Input", "Options",
        function(Index: string, Input: any)
            return { text = Input.Value }
        end,
        function(Element: any?, Data: any)
            if not Element then return end
            if typeof(Data.text) ~= "string" then return end

            if Element.Value == Data.text then
                Element:RunChanged()
                return
            end

            Element:SetValue(Data.text)
        end
    )

    CreateParser(
        "Groupbox", "Tabs",
        function(Index: string, Groupbox: any, TabIndex: string)
            return {
                tabIdx = TabIndex,
                collapsed = Groupbox.Collapsed,
                poppedOut = Groupbox.PoppedOut == true,
                popoutPos = if Groupbox.PoppedOut and Groupbox.PopOutFloat then SpecialValueParser.UDim2.Encode(Groupbox.PopOutFloat.Position) else nil,
            }
        end,
        function(_, Data: any)
            local TabIndex, Index = Data.tabIdx, Data.idx
            if typeof(TabIndex) ~= "string" or typeof(Index) ~= "string" then return end

            local Tabs = SaveManager.Library and SaveManager.Library.Tabs
            local Tab = Tabs and Tabs[TabIndex]
            if not Tab then return end

            local Groupbox = Tab.Groupboxes[Index]
            if not Groupbox then return end

            --// Collapsed
            if Groupbox.Collapsed ~= Data.collapsed then
                Groupbox:SetCollapsed(Data.collapsed == true)
            end

            --// Popout
            if Groupbox.PopOutEnabled then
                if Data.poppedOut == true then
                    local Position = SpecialValueParser.UDim2.Decode(Data.popoutPos)
                    Groupbox:SetPoppedOut(true, Position)
                elseif Groupbox.PoppedOut then
                    Groupbox:SetPoppedOut(false)
                end
            end
        end,
        true
    )

    CreateParser(
        "Tabbox", "Tabs",
        function(Index: string, Tabbox: any, TabIndex: string)
            return {
                tabIdx = TabIndex,
                poppedOut = Tabbox.PoppedOut == true,
                popoutPos = if Tabbox.PoppedOut and Tabbox.PopOutFloat then SpecialValueParser.UDim2.Encode(Tabbox.PopOutFloat.Position) else nil,
            }
        end,
        function(_, Data: any)
            local TabIndex, Index = Data.tabIdx, Data.idx
            if typeof(TabIndex) ~= "string" or typeof(Index) ~= "string" then return end

            local Tabs = SaveManager.Library and SaveManager.Library.Tabs
            local Tab = Tabs and Tabs[TabIndex]
            if not Tab then return end

            local Tabbox = Tab.Tabboxes and Tab.Tabboxes[Index]
            if not Tabbox then return end

            --// Popout
            if Tabbox.PopOutEnabled then
                if Data.poppedOut == true then
                    local Position = SpecialValueParser.UDim2.Decode(Data.popoutPos)
                    Tabbox:SetPoppedOut(true, Position)
                elseif Tabbox.PoppedOut then
                    Tabbox:SetPoppedOut(false)
                end
            end
        end,
        true
    )
end

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

--// Share codes \\--
--// Raw config JSON runs to tens of KB, and mobile clipboards and text boxes cut it
--// short. Share codes are LZW packed into URL-safe base64 instead, a fraction the size.
local SHARE_PREFIX = "OU1:"
local SHARE_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

local ShareChars, ShareValues = {}, {}
for Index = 1, #SHARE_ALPHABET do
    local Char = SHARE_ALPHABET:sub(Index, Index)
    ShareChars[Index - 1] = Char
    ShareValues[Char] = Index - 1
end

--// Code width follows only from the code's position, so both sides agree without
--// tracking each other's dictionary: the i-th code can be at most 256 + i - 1.
local function CodeWidth(Position: number): number
    local Size, Width = 256 + Position, 0
    while Size > 0 do
        Size //= 2
        Width += 1
    end

    return Width
end

local function EncodeShareCode(Data: string): string
    local Dictionary, NextCode = {}, 256
    for Byte = 0, 255 do
        Dictionary[string.char(Byte)] = Byte
    end

    local Output = {}
    local Accumulator, Bits, Position = 0, 0, 0

    local function Emit(Code: number)
        local Width = CodeWidth(Position)
        Position += 1

        Accumulator = Accumulator * 2 ^ Width + Code
        Bits += Width

        while Bits >= 6 do
            Bits -= 6
            local Divisor = 2 ^ Bits
            table.insert(Output, ShareChars[math.floor(Accumulator / Divisor) % 64])
            Accumulator %= Divisor
        end
    end

    local Current = ""
    for Index = 1, #Data do
        local Char = Data:sub(Index, Index)
        local Joined = Current .. Char

        if Dictionary[Joined] then
            Current = Joined
        else
            Emit(Dictionary[Current])
            Dictionary[Joined] = NextCode
            NextCode += 1
            Current = Char
        end
    end

    if Current ~= "" then
        Emit(Dictionary[Current])
    end

    if Bits > 0 then
        table.insert(Output, ShareChars[(Accumulator * 2 ^ (6 - Bits)) % 64])
    end

    return SHARE_PREFIX .. table.concat(Output)
end

local function DecodeShareCode(Code: string): string?
    local Body = Code:sub(#SHARE_PREFIX + 1):gsub("%s", "")

    local Dictionary, NextCode = {}, 256
    for Byte = 0, 255 do
        Dictionary[Byte] = string.char(Byte)
    end

    local Output = {}
    local Accumulator, Bits, Position = 0, 0, 0
    local Previous = nil

    for Index = 1, #Body do
        local Value = ShareValues[Body:sub(Index, Index)]
        if Value == nil then
            return nil
        end

        Accumulator = Accumulator * 64 + Value
        Bits += 6

        local Width = CodeWidth(Position)
        while Bits >= Width do
            Bits -= Width
            local Divisor = 2 ^ Bits
            local Code = math.floor(Accumulator / Divisor)
            Accumulator %= Divisor
            Position += 1

            local Entry = Dictionary[Code]
            if Entry == nil then
                --// The one code a decoder can meet before defining it: previous + its own first byte
                if Code ~= NextCode or Previous == nil then
                    return nil
                end

                Entry = Previous .. Previous:sub(1, 1)
            end

            table.insert(Output, Entry)
            if Previous ~= nil then
                Dictionary[NextCode] = Previous .. Entry:sub(1, 1)
                NextCode += 1
            end

            Previous = Entry
            Width = CodeWidth(Position)
        end
    end

    return table.concat(Output)
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

--// Per account mode keys the file by UserId, so each account can load a different profile
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

function SaveManager:SaveJSON(ConfigName)
    local Library = SaveManager.Library
    local IgnoreIndexes = SaveManager.Ignore
    local CurrentData = {
        timestamp = os.date("%d.%m.%Y %H:%M:%S"),
        name = ConfigName or "",

        objects = {},
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

    --// Toggles
    for Index, Toggle in Library.Toggles do
        if not Toggle.Type then continue end
        if IgnoreIndexes[Index] then continue end

        local Parser = ElementParser[Toggle.Type]
        if not Parser then continue end

        table.insert(CurrentData.objects, Parser.Save(Index, Toggle))
    end

    --// Options
    for Index, Option in Library.Options do
        if not Option.Type then continue end
        if IgnoreIndexes[Index] then continue end

        local Parser = ElementParser[Option.Type]
        if not Parser then continue end

        table.insert(CurrentData.objects, Parser.Save(Index, Option))
    end

    --// Groupboxes, Tabboxes
    for TabIndex, Tab in Library.Tabs do
        if Tab.Groupboxes then
            for Index, Groupbox in Tab.Groupboxes do
                if typeof(Index) ~= "string" or IgnoreIndexes[Index] then continue end

                local Parser = ElementParser.Groupbox
                if not Parser then continue end

                table.insert(CurrentData.objects, Parser.Save(Index, Groupbox, TabIndex))
            end
        end

        if Tab.Tabboxes then
            for Index, Tabbox in Tab.Tabboxes do
                if typeof(Index) ~= "string" or IgnoreIndexes[Index] then continue end

                local Parser = ElementParser.Tabbox
                if not Parser then continue end

                table.insert(CurrentData.objects, Parser.Save(Index, Tabbox, TabIndex))
            end
        end
    end

    local SuccessEncode, EncodedData = pcall(HttpService.JSONEncode, HttpService, CurrentData)
    if not SuccessEncode then
        return "", false, "Failed to encode data"
    end

    return EncodedData, true
end

--// Settings only: window, keybind menu and groupbox layout are personal to the
--// sharer's screen, and dropping them keeps the code short enough for mobile.
function SaveManager:ExportShareCode(): (string, boolean, string?)
    local EncodedData, SuccessEncode, ErrorMessage = SaveManager:SaveJSON()
    if not SuccessEncode then
        return "", false, ErrorMessage
    end

    local Data = HttpService:JSONDecode(EncodedData)
    local Objects = {}
    for _, Object in Data.objects do
        if Object.type == "Groupbox" or Object.type == "Tabbox" then continue end
        table.insert(Objects, Object)
    end

    local SuccessShare, Share = pcall(HttpService.JSONEncode, HttpService, { objects = Objects })
    if not SuccessShare then
        return "", false, "Failed to encode data"
    end

    return EncodeShareCode(Share), true
end

function SaveManager:Save(ConfigName: string): (boolean, string?)
    if IsStringEmpty(ConfigName) then
        return false, "Invalid config name provided"
    end

    if string.lower(ConfigName) == "autoload" then
        return false, "Invalid config name provided"
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

function SaveManager:LoadJSON(Content: string)
    if IsStringEmpty(Content) then
        return false, "No JSON provided"
    end

    Content = Trim(Content)
    if Content:sub(1, #SHARE_PREFIX) == SHARE_PREFIX then
        local Decoded = DecodeShareCode(Content)
        if not Decoded then
            return false, "The code is incomplete or damaged"
        end

        Content = Decoded
    end

    local SuccessDecode, Decoded = pcall(HttpService.JSONDecode, HttpService, Content)
    if not SuccessDecode or typeof(Decoded) ~= "table" or typeof(Decoded.objects) ~= "table" then
        return false, "Failed to decode config data"
    end

    local Library = SaveManager.Library
    local LoadingOrder = SaveManager.LoadingOrder
    local IgnoreIndexes = SaveManager.Ignore

    if SaveManager.UseLoadingOrder == true and typeof(LoadingOrder) == "table" then
        table.sort(Decoded.objects, function(a, b)
            local aIndex = table.find(LoadingOrder, a.type) or math.huge
            local bIndex = table.find(LoadingOrder, b.type) or math.huge
            return aIndex < bIndex
        end)
    end

    --// Keybind Menu
    if Library.KeybindFrame and typeof(Decoded.keybindMenu) == "table" then
        local KeybindFrameData = Decoded.keybindMenu
        local IsVisible = KeybindFrameData.visible == true
        local Position = SpecialValueParser.UDim2.Decode(KeybindFrameData.position)

        Library.KeybindFrame.Visible = IsVisible
        Library.KeybindFrame.Position = Position or Library.KeybindFrame.Position
        
        local KeybindMenuToggle = Library.Options and Library.Options.KeybindMenuOpen
        if KeybindMenuToggle then
            KeybindMenuToggle:SetValue(IsVisible)
        end
    end

    --// Window size & position
    if not IgnoreIndexes["WindowLayout"]
        and Library.Window and Library.Window.SetSizePosition
        and typeof(Decoded.window) == "table"
    then
        local WindowData = Decoded.window
        local Size = SpecialValueParser.UDim2.Decode(WindowData.size)
        local Position = SpecialValueParser.UDim2.Decode(WindowData.position)

        Library.Window:SetSizePosition(Size, Position)
    end

    --// Elements
    for _, Option in Decoded.objects do
        if not Option.type then continue end
        if IgnoreIndexes[Option.idx] then continue end

        local Parser = ElementParser[Option.type]
        if not Parser then continue end

        task.defer(Parser.Load, Option.idx, Option)
    end

    return true
end

function SaveManager:Load(ConfigName: string): (boolean, string?)
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

    local Success, ErrorMessage = SaveManager:LoadJSON(Content)
    if Success then
        SaveManager.LoadedConfig = ConfigName
    end

    return Success, ErrorMessage
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
            SaveManager.Library:Notify(string.format("Couldn't load your start profile: %s", FetchErrorMessage))
        end

        return
    end

    local SuccessLoad, LoadErrorMessage = SaveManager:Load(ConfigName)
    if not SuccessLoad then
        SaveManager.Library:Notify(string.format("Couldn't load your start profile: %s", LoadErrorMessage))
        return
    end

    SaveManager.Library:Notify(string.format("Loaded profile %q", ConfigName))
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
--// the loaded profile only when they differ from the last snapshot.
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

        while SaveManager.Autosave do
            task.wait(AUTOSAVE_INTERVAL)

            local Library = SaveManager.Library
            if not Library or Library.Unloaded then break end

            local ConfigName = SaveManager.LoadedConfig
            if not ConfigName or not DoesConfigExist(ConfigName) then continue end

            local EncodedData, SuccessEncode = SaveManager:SaveJSON(ConfigName)
            if not SuccessEncode then continue end

            local Comparable = StripTimestamp(EncodedData)
            if ConfigName ~= LastConfig then
                --// First pass on a profile only takes a snapshot, so loading never writes
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
        Name = "Profiles",
        IconName = IconName or "folder-cog",
    })

    SaveManager:LoadManagerSettings()

    local ConfigNameInput, ConfigList, ConfigJSONInput, AutoloadConfigLabel
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

    local function GetSelectedProfile(): string?
        local ConfigName = ConfigList.Value
        if IsStringEmpty(ConfigName) then
            Notify("Pick a profile first.")
            return nil
        end

        return ConfigName
    end

    local function FormatProfile(Value: any)
        if Value == SaveManager.AutoloadConfig then
            return string.format("%s (on start)", Value)
        end

        return Value
    end

    --// New profile
    ConfigurationBox:AddInput("SaveManager_ConfigName", {
        Text = "Profile name",
        Placeholder = "name...",
    })

    ConfigurationBox:AddButton("Save as new profile", function()
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

    --// Saved profiles
    ConfigurationBox:AddDropdown("SaveManager_ConfigList", {
        Text = "Saved profiles",

        Values = SaveManager:RefreshConfigList(),
        AllowNull = true,
        Multi = false,

        FormatDisplayValue = FormatProfile,
        FormatListValue = FormatProfile,
    })

    ConfigurationBox:AddButton({
        Text = "Load",
        DoubleClick = false,

        Func = function()
            local ConfigName = GetSelectedProfile()
            if not ConfigName then return end

            ShowDialog(
                function(): boolean
                    return true --// Always show
                end,

                "SaveManager_LoadConfig",
                "Load profile",
                string.format("Switch to %q? Unsaved changes will be lost.", ConfigName),

                "Load",
                function()
                    local Success, ErrorMessage = SaveManager:Load(ConfigName)
                    if not Success then
                        Notify("Couldn't load %q: %s", ConfigName, tostring(ErrorMessage))
                        return
                    end

                    Notify("Loaded %q", ConfigName)
                end
            )
        end
    }):AddButton({
        Text = "Update",
        DoubleClick = false,
        Tooltip = "Save your current settings into this profile",

        Func = function()
            local ConfigName = GetSelectedProfile()
            if not ConfigName then return end

            ShowDialog(
                function(): boolean
                    return true --// Always show
                end,

                "SaveManager_OverwriteConfig",
                "Update profile",
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
        Tooltip = "Load this profile every time the script starts",

        Func = function()
            local ConfigName = GetSelectedProfile()
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
            local ConfigName = GetSelectedProfile()
            if not ConfigName then return end

            ShowDialog(
                function(): boolean
                    return true --// Always show
                end,

                "SaveManager_DeleteConfig",
                "Delete profile",
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

            Notify("No profile will load on start.")
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
        Tooltip = "Keeps the loaded profile updated as you change settings",
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

    ConfigurationBox:AddButton("Copy my code", function()
        local EncodedData, Success, ErrorMessage = SaveManager:ExportShareCode()
        if not Success then
            Notify("%s", tostring(ErrorMessage))
            return
        end

        ConfigJSONInput:SetValue(EncodedData)
        if setclipboard then
            setclipboard(EncodedData)
            Notify("Code copied")
        end
    end):AddButton("Use code", function()
        local ConfigJSON = ConfigJSONInput.Value
        if IsStringEmpty(ConfigJSON) then
            Notify("Paste a code first.")
            return
        end

        ShowDialog(
            function(): boolean
                return true --// Always show
            end,

            "SaveManager_ImportConfig",
            "Use share code",
            "Apply these settings? Unsaved changes will be lost.",

            "Apply",
            function()
                local Success, ErrorMessage = SaveManager:LoadJSON(ConfigJSON)
                if not Success then
                    Notify("That code didn't work: %s", tostring(ErrorMessage))
                    return
                end

                Notify("Settings applied")
            end
        )
    end)

    --// Set variables
    ConfigNameInput, ConfigList, ConfigJSONInput =
        SaveManager.Library.Options.SaveManager_ConfigName,
        SaveManager.Library.Options.SaveManager_ConfigList,
        SaveManager.Library.Options.SaveManager_JSON;

    --// Refresh
    RefreshAutoloadConfigLabel()
    SaveManager:SetIgnoreIndexes({
        "SaveManager_ConfigList", "SaveManager_ConfigName", "SaveManager_JSON",
        "SaveManager_AutoloadMode", "SaveManager_Autosave"
    })

    return ConfigurationBox
end

SaveManager:BuildFolderTree()
return SaveManager
