-- --==================================================
-- TurtleJournal
--==================================================

-- setup namespace
local ADDON_NAME = "TurtleJournal"

TurtleJournal = CreateFrame("Frame", ADDON_NAME, UIParent)
TurtleJournal:RegisterEvent("VARIABLES_LOADED")

local TJ = TurtleJournal
TJ.addonInfo = {
    name    = GetAddOnMetadata(ADDON_NAME, "X-name")   or "TurtleJournal",
    version = GetAddOnMetadata(ADDON_NAME, "Version")  or "Unknown",
    url     = GetAddOnMetadata(ADDON_NAME, "X-url")    or "Turtle Forum > Addons",
}

-- debug functions
local debug = false

function TJ.print(msg)
    if type(msg) == "table" then
        local t = {}
        for k, v in pairs(msg) do
            if type(v) == "table" then
                table.insert(t, k .. "={title=" .. tostring(v.title) .. ", content=" .. tostring(v.content) .. "}")
            else
                table.insert(t, k .. "=" .. tostring(v))
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffff6060Journal|r: " .. table.concat(t, "\n"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff6060Journal|r: " .. (msg or "nil"))
    end
end

TJ.debugCount = 0
function TJ.debug(msg)
    if debug then
        TJ.debugCount = TJ.debugCount + 1
        local stack = debugstack(2, 1, 0)
        local start, finish = string.find(stack, "[^\\/:]+%.lua")
        local file = start and string.sub(stack, start, finish) or "unknown"
        TJ.print("[DEBUG][ " .. TJ.debugCount .. " ][|cff00ff00" .. file .. "|r]: " .. (msg or "nil"))
        -- TJ.print(debugstack(2, 3, 0)) -- can be enabled if needed
    end
end

function TJ.drawred(frame)
    if not frame or not frame.CreateTexture then return end

    if not debug then
        if frame.border then
            frame.border:Hide()
        end
        return
    end

    if frame.border then
        frame.border:Show()
        return
    end

    local border = CreateFrame("Frame", nil, frame)
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    border:SetAllPoints()

    border.tex = border:CreateTexture(nil, "OVERLAY")
    border.tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    border.tex:SetVertexColor(1, 0, 0, 1)

    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    border:SetBackdropBorderColor(1, 0, 0, 1)

    frame.border = border
end

-- boot
TJ.debug("booting...")

-- saved variables
TurtleJournal_Settings = {}
TurtleJournal_DB = {
    ["1991-03-03"] = {
        ["1"] = {
            ["title"] = "Hey there turtle...",
            ["content"] = "Thank you for using Turtle-Journal.\n\nTo get started:\n- Use Shift + Leftclick on your player portrait or use /tj in order to open the journal.\n- Use Shift + Mousewheel to resize the journal window.\n- Use Ctrl + Mousewheel to adjust transparency of the journal window.\n\nRemeber to backup your files in\nyour WTF/Server/Char/SavedVariables folder.\nAddon's can not back up your files.\n\nThis is an alpha version, report bugs please.\n\nTake care turtles...\n            ...Guzruul.",
        }
    },
}

-- event handler
TJ:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        TJ.debug("'VARIABLES_LOADED' event triggered.")

        TJ.InitializeSettings()
        TJ.CreateFrames()
        TJ.UpdateEntryList()
        TJ.SetupMainFrameOpener()
        -----------------------------------------
        -- will be gone after alpha v1.0
        TJ.drawred(TJ.frames.main)
        TJ.drawred(TJ.frames.entryList)
        TJ.drawred(TJ.frames.optionsPanel)
        TJ.drawred(TJ.frames.titleBox)
        TJ.drawred(TJ.frames.editBox)
        TJ.drawred(TJ.frames.savebtn)
        TJ.drawred(TJ.frames.saveDBbtn)
        TJ.drawred(TJ.frames.deletebtn)
        TJ.drawred(TJ.frames.optionsbtn)
        TJ.drawred(TJ.frames.slideButton)

        local debugbtn = CreateFrame("Button", "debugbtn", TJ.frames.optionsPanel, "UIPanelButtonTemplate")
        debugbtn:SetPoint("LEFT", TJ.frames.sitCheckbox, "RIGHT", 60, 0)
        debugbtn:SetHeight(15)
        debugbtn:SetWidth(50)
        debugbtn:SetText("debug")
        debugbtn:SetFrameStrata("DIALOG")

        debugbtn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Will be removed after alpha phase.")
            GameTooltip:Show()
        end)
        debugbtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        debugbtn:SetScript("OnClick", function()
            debug = not debug
            TJ.debug("debug: " .. tostring(debug))

            TJ.drawred(TJ.frames.main)
            TJ.drawred(TJ.frames.entryList)
            TJ.drawred(TJ.frames.optionsPanel)
            TJ.drawred(TJ.frames.titleBox)
            TJ.drawred(TJ.frames.editBox)
            TJ.drawred(TJ.frames.savebtn)
            TJ.drawred(TJ.frames.saveDBbtn)
            TJ.drawred(TJ.frames.deletebtn)
            TJ.drawred(TJ.frames.optionsbtn)
            TJ.drawred(TJ.frames.slideButton)
        end)

        -----------------------------------------

        TJ.debug("TurtleJournal initialized.")
        TJ:UnregisterEvent("VARIABLES_LOADED")
    end
end)

-- slash command
SLASH_TURTLEJOURNAL1 = "/tj"
SLASH_TURTLEJOURNAL2 = "/turtlejournal"
function SlashCmdList.TURTLEJOURNAL()
    if TJ.frames.main:IsVisible() then
        TJ.frames.main:Hide()
        TJ.debug("TurtleJournal closed")
        TJ.DoEmote("STAND")
        TJ.SwooshSound()
    else
        TJ.frames.main:Show()
        TJ.SwooshSound()
        TJ.debug("TurtleJournal opened")
        TJ.DoEmote("SIT")
    end
end