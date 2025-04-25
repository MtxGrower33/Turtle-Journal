---@diagnostic disable: deprecated
--==================================================
-- VARIABLES
--==================================================
local tj = TurtleJournal
local d = tj.dt
local ADDON_NAME = "Turtlejournal"

-- debug
d:debug("booting...")

--==================================================
-- ADDON METADATA
--==================================================
tj.addonInfo = {
    name    = GetAddOnMetadata(ADDON_NAME, "X-name")   or "TurtleJournal",
    version = GetAddOnMetadata(ADDON_NAME, "Version")  or "Unknown",
    url     = GetAddOnMetadata(ADDON_NAME, "X-url")    or "Turtle Forum > Addons",
}

--==================================================
-- TABLES
--==================================================
TurtleJournal_Settings = {}
TurtleJournal_DB = {
    ["1991-03-03"] = {
        ["1"] = {
            ["title"] = "Hey there turtle...",
            ["content"] = "Thank you for using Turtle-Journal.\n\nTo unfurl your scroll of memories:\n-Shift+Click your player portrait\n or whisper /tj to call\n forth the journal.\n\n-Shift+Mousewheel to resize\n the journal window.\n\n-Ctrl+Mousewheel to adjust\n transparency of the journal window.\n\nGuard your lore well! Tread to:\n WTF/Server/<Realm>/<Character>/SavedVariables\n and copy the Turtle-Journal file\n ere disaster strikes\n—\nadd-ons heed not your backups.\n\nThis is but an Alpha edition\n of the journal.\n\n Should you discover any rips\n in the parchment (bugs),\n send word to your\n fellow turtles.\n\nTake care turtles...\n            ...Guzruul.",
        }
    },
}
tj.modules = {}
tj.env = {}

--==================================================
-- ERROR HANDLING -- needs inspect
--==================================================
tj.errorHandler = {
    errors = {},
    maxErrors = 50
}

function tj.errorHandler:Handle(err, source)
    DEFAULT_CHAT_FRAME:AddMessage(d.colors.red .."ERROR|r: ".. err.. "\n".. d.colors.red.. "SOURCE|r: [ ".. d.colors.red.. source.. d.colors.red .. "|r ]")  -- Basic print for testing

    -- format error msg
    local timestamp = date("%H:%M:%S")
    local errorMsg = string.format("%s: %s from %s", timestamp, tostring(err), tostring(source))

    -- store error
    table.insert(self.errors, errorMsg)

    -- max errors
    if table.getn(self.errors) > self.maxErrors then
        table.remove(self.errors, 1)
    end

    -- print error
    d:debug("Error: " .. d.colors.red .. errorMsg)

    -- stack trace
    -- d:debug(d.colors.red .. debugstack(2) .. "|r")
end

--==================================================
-- MODULE SYSTEM
--==================================================
function tj:RegisterModule(moduleName, moduleFunc)
    -- duplicate check
    if self.modules[moduleName] then
        d:debug("WARNING: Module: [ ".. d.colors.red .. moduleName .. "|r ] already registered")
        return end

    self.modules[moduleName] = moduleFunc
    d:debug("Module: [ ".. d.colors.red .. moduleName .. "|r ] registered")
end

function tj:GetEnvironment()
    local _G = getfenv(0)
    setmetatable(tj.env, {__index = _G})

    tj.env._G = getfenv(0)
    return tj.env
end

function tj:LoadModule(moduleName)
    if not self.modules[moduleName] then
        self.errorHandler:Handle("Module not found: " .. moduleName, "LoadModule")
        return false
    end

    local success, error = pcall(function()
        setfenv(self.modules[moduleName], self:GetEnvironment())
        d:debug("Module: [ ".. d.colors.red .. moduleName .. "|r ]" .. d.colors.red .. " booting...")
        self.modules[moduleName]()
        d:debug("Module: [ ".. d.colors.red .. moduleName .. "|r ]" .. d.colors.green .. " loaded...")
    end)

    if not success then
        self.errorHandler:Handle(error, "Module: " .. moduleName)
        return false
    end
    return true
end

--==================================================
-- EVENT HANDLING
--==================================================
tj:RegisterEvent("VARIABLES_LOADED")
tj:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        d:debug("VARIABLES_LOADED")

        tj:LoadModule("functions")
        tj:LoadModule("gui")
        tj.UpdateEntryList()

        d:print("TurtleJournal".. d.colors.green .. " loaded.")
        d:print("Type /".. d.colors.green .."tj|r or "..d.colors.green.."shift|r + ".. d.colors.green.."click|r your portrait.")

        tj:UnregisterEvent("VARIABLES_LOADED")
    end
end)

--==================================================
-- SLASH
--==================================================
SLASH_TURTLEJOURNAL1 = "/tj"
SLASH_TURTLEJOURNAL2 = "/turtlejournal"
function SlashCmdList.TURTLEJOURNAL()
    if tj.frames.main:IsVisible() then
        tj.frames.main:Hide()
        tj.frames.bottomOptionFrame2:Hide()
        d:debug("TurtleJournal closed")
        tj.DoEmote("STAND")
        tj.SwooshSound()
    else
        tj.frames.main:Show()
        if TurtleJournal_Settings.autoOpen then
            tj.frames.sideEntryList:Show()
            tj.frames.miniScrollPanel:Show()
        end
        tj.SwooshSound()
        d:debug("TurtleJournal opened")
        tj.DoEmote("SIT")
    end
end

SLASH_TJERRORS1 = "/tjerrors"
SlashCmdList["TJERRORS"] = function()
    if table.getn(tj.errorHandler.errors) == 0 then
        d:debug(d.colors.green .. "No errors recorded" .. "|r")
        return
    end

    d:debug("Last " .. table.getn(tj.errorHandler.errors) .. " errors:" .. "|r")
    for i = 1, table.getn(tj.errorHandler.errors) do
        d:debug(d.colors.red .. tj.errorHandler.errors[i] .. "|r")
    end
end
