---@diagnostic disable: deprecated
--==================================================
-- functions
--==================================================
-- todo : content lenght set at 2 points + checkbox lenght = bad. very bad.
-- ENTRYLIST MUST GET SORTED BY INDEX
-- backup reminder for the user
-- draw feature, change textures, custom journal title, other tools and perks
-- fonts, alpha, soundeffect, etc.
-- scrollframe instead of fixed editbox

local TJ = TurtleJournal
TJ.debug("booting...")

-- defaults
local defaults = {
    sound = true,
    scale = 1.0,
    alpha = 1.0,
    sit = true,
}

TJ.typing = {
    lastSoundTime = 0,
    soundInterval = 7,
    soundFiles = {
        "Interface\\AddOns\\TurtleJournal\\media\\writing-on-notebook-dan-barracuda-1-00-25.mp3",
        "Interface\\AddOns\\TurtleJournal\\media\\writing-on-notebook-dan-barracuda-1-00-25-2.mp3",
        "Interface\\AddOns\\TurtleJournal\\media\\writing-on-notebook-dan-barracuda-1-00-25-3.mp3"
    },
    soundFiles2 = {
        "Interface\\AddOns\\TurtleJournal\\media\\swoosh-sound-effect-for-fight-scenes-or-transitions-2-149890.mp3",
        "Interface\\AddOns\\TurtleJournal\\media\\swoosh-sound-effect-for-fight-scenes-or-transitions-4-149887.mp3",
    }
}

-- defaults init
function TJ.InitializeSettings()
    if not TurtleJournal_Settings then
        TurtleJournal_Settings = {}
        TJ.debug("ATTENTION: Created new database")
    end

    for setting, defaultValue in pairs(defaults) do
        if TurtleJournal_Settings[setting] == nil then
            TurtleJournal_Settings[setting] = defaultValue
            TJ.debug("Created new setting: " .. setting)
        end
    end
end

-- small funcs
function TJ.StartTyping()
    local currentTime = GetTime()
    local db = TurtleJournal_Settings
    if db.sound and (currentTime - TJ.typing.lastSoundTime) >= TJ.typing.soundInterval then
        TJ.typing.lastSoundTime = GetTime() -- reset timer
        local randomIndex = math.random(table.getn(TJ.typing.soundFiles))
        local selectedSound = TJ.typing.soundFiles[randomIndex]
        PlaySoundFile(selectedSound, "Master")
        TJ.debug("Started typing, played random sound #" .. randomIndex)
    end
end

function TJ.SwooshSound()
    local db = TurtleJournal_Settings
    if db.sound then
        if TJ.frames.main and TJ.frames.main:IsVisible() then
            PlaySoundFile(TJ.typing.soundFiles2[1])
        else
            PlaySoundFile(TJ.typing.soundFiles2[2])
        end
    end

    TJ.debug("Performed swoosh sound")
end

function TJ.MoveFrame(frame, direction, pixels, duration, visibility)
    if not frame or not direction or not pixels then return end
    duration = duration or 1

    local startTime = GetTime()
    local startPoint = { frame:GetPoint() }
    local xMod, yMod = 0, 0

    if direction == "up" then yMod = pixels
    elseif direction == "down" then yMod = -pixels
    elseif direction == "left" then xMod = -pixels
    elseif direction == "right" then xMod = pixels
    else return end

    local function OnUpdate()
        local elapsed = GetTime() - startTime
        local progress = elapsed / duration

        if progress >= 1 then
            frame:SetPoint(startPoint[1], startPoint[2], startPoint[3],
                startPoint[4] + xMod, startPoint[5] + yMod)
            frame:SetScript("OnUpdate", nil)

            -- handle visibility after movement completes
            if visibility then
                if visibility == "show" then
                    frame:Show()
                elseif visibility == "hide" then
                    frame:Hide()
                end
            end

            TJ.debug("Moved frame " .. direction .. " by " .. pixels .. " pixels over " .. duration .. "s")
            return
        end

        frame:SetPoint(startPoint[1], startPoint[2], startPoint[3],
            startPoint[4] + (xMod * progress), startPoint[5] + (yMod * progress))
    end

    frame:SetScript("OnUpdate", OnUpdate)
end

function TJ.DoEmote(emoteName)
    local db = TurtleJournal_Settings

    if db.sit then
        DoEmote(emoteName)
        TJ.debug("Performed " .. emoteName .. " emote")
    end
end

function TJ.SetupFrameControls()
    local frame = TJ.frames.main

    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function()
        local delta = arg1

        -- handle scaling with SHIFT
        if IsShiftKeyDown() then
            local currentScale = frame:GetScale()
            local newScale = currentScale + (delta * 0.1)
            newScale = math.max(0.5, math.min(2.0, newScale))
            frame:SetScale(newScale)
            TurtleJournal_Settings.scale = newScale
            TJ.debug("Scale changed to: " .. newScale)

        -- handle alpha with CTRL
        elseif IsControlKeyDown() then
            local currentAlpha = frame:GetAlpha()
            local newAlpha = currentAlpha + (delta * 0.1)
            newAlpha = math.max(0.2, math.min(1.0, newAlpha))
            frame:SetAlpha(newAlpha)
            TurtleJournal_Settings.alpha = newAlpha
            TJ.debug("Alpha changed to: " .. newAlpha)
        end
    end)

    -- apply saved settings on startup
    if TurtleJournal_Settings.scale then
        frame:SetScale(TurtleJournal_Settings.scale)
    end
    if TurtleJournal_Settings.alpha then
        frame:SetAlpha(TurtleJournal_Settings.alpha)
    end
end

function TJ.SetupMainFrameOpener()
    local oldHandler = PlayerFrame:GetScript("OnMouseUp")

    PlayerFrame:SetScript("OnMouseUp", function()
        -- check if shift is held and right mouse button was clicked
        if IsShiftKeyDown() and arg1 == "LeftButton" then
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
        elseif oldHandler then
            -- call original handler if it exists
            oldHandler(this, arg1)
        end
    end)
end

-- funcs
function TJ.GetEntries(dateStr)
    local db = TurtleJournal_DB
    dateStr = dateStr or date("%Y-%m-%d")

    if not db[dateStr] then
        TJ.debug("No entries found on date: " .. dateStr)
        return nil
    end

    return db[dateStr]
end

function TJ.SelectEntry(dateStr, entryId)
    if not entryId then
        TJ.debug("Error: Missing parameters")
        return nil
    end

    dateStr = dateStr or date("%Y-%m-%d")
    local entries = TJ.GetEntries(dateStr)
    if entries and entries[entryId] then
        return entries[entryId]
    end
    return nil
end

StaticPopupDialogs["TURTLEJOURNAL_DELETE_CONFIRM"] = {
    text = "Are you sure you want to delete this entry?",
    button1 = "Yes",
    button2 = "No",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnAccept = function()
        local dateStr = TJ.selectedEntry.dateStr
        local entryId = TJ.selectedEntry.id
        local db = TurtleJournal_DB

        -- check if entry exists
        if not db[dateStr] or
           not db[dateStr][entryId] then
            TJ.debug("Error: Entry not found")
            StaticPopup_Hide("TURTLEJOURNAL_DELETE_CONFIRM")
            return false
        end

        -- create backup
        local backup = db[dateStr][entryId]

        -- try to delete the entry
        local success = true
        local function removeEntry()
            db[dateStr][entryId] = nil

            -- cleanup empty tables
            if next(db[dateStr]) == nil then
                db[dateStr] = nil
            end
        end

        -- use pcall to catch any errors
        success = pcall(removeEntry)

        -- if deletion failed, restore from backup
        if not success then
            db[dateStr][entryId] = backup
            TJ.debug("Error: Delete failed, restored from backup")
            StaticPopup_Hide("TURTLEJOURNAL_DELETE_CONFIRM")
            return false
        end

        -- clear selection
        TJ.selectedEntry = nil
        if TJ.selectedButton then
            TJ.selectedButton:UnlockHighlight()
            TJ.selectedButton = nil
        end

        -- refresh the entry list
        TJ.UpdateEntryList(dateStr)
        TJ.frames.editBox:SetText("")
        TJ.frames.titleBox:SetText("")

        -- hide the entire popup after successful deletion
        StaticPopup_Hide("TURTLEJOURNAL_DELETE_CONFIRM")
        TJ.debug("Deleted entry #" .. entryId .. " on " .. dateStr)
        return true
    end,
}

function TJ.DeleteEntry()
    if not TJ.selectedEntry then
        TJ.debug("Error: No entry selected")
        TJ.print("No entry selected. Please select an entry to delete.")
        return false
    end

    -- show the confirmation dialog
    StaticPopup_Show("TURTLEJOURNAL_DELETE_CONFIRM")
end

function TJ.SaveEntry()
    -- get content from editboxes
    local content = TJ.frames.editBox:GetText()
    local title = TJ.frames.titleBox:GetText()

    -- input validation
    if not title or title == "" then
        TJ.debug("Error: Title cannot be empty")
        TJ.print("Title cannot be empty. Please enter a title.")
        TJ.frames.titleBox:SetFocus()
        return false
    end
    if not content or content == "" then
        TJ.debug("Error: Content cannot be empty")
        TJ.print("Content cannot be empty. Please enter some text.")
        TJ.frames.editBox:SetFocus()
        return false
    end

    -- content length check
    local MAX_CONTENT_LENGTH = 700
    if string.len(content) > MAX_CONTENT_LENGTH then
        TJ.debug("Error: Content exceeds maximum length of " .. MAX_CONTENT_LENGTH)
        TJ.print("Content exceeds maximum length of " .. MAX_CONTENT_LENGTH.. " characters. Please shorten your entry.")
        return false
    end

    local db = TurtleJournal_DB
    local dateStr = date("%Y-%m-%d")

    -- create backup of current entries for this date
    local backup = nil
    if db[dateStr] then
        backup = {}
        for k, v in pairs(db[dateStr]) do
            backup[k] = v
        end
    end

    -- check if date exists in the database
    if not db[dateStr] then
        db[dateStr] = {}
        TJ.debug("Created new date entry: " .. dateStr)
    end

    -- find the next available index for the entry
    local maxIdx = 0
    for k, _ in pairs(db[dateStr]) do
        local num = tonumber(k)
        if num and num > maxIdx then
            maxIdx = num
        end
    end

    -- increment the index for the new entry
    local nextIdx = maxIdx + 1

    -- create entry structure (removed timestamp for now)
    local entry = {
        title = title,
        content = content
    }

    -- try to add the new entry
    local success = true
    local function addEntry()
        db[dateStr][tostring(nextIdx)] = entry
    end

    -- use pcall to catch any errors
    success = pcall(addEntry)

    -- if the entry failed, restore the backup
    if not success and backup then
        db[dateStr] = backup
        TJ.debug("Error: Entry failed, restored from backup")
        return false
    end

    -- clear the input boxes
    TJ.frames.editBox:SetText("")
    TJ.frames.titleBox:SetText("")

    -- refresh the entry list
    TJ.UpdateEntryList(dateStr)

    TJ.debug("Added entry #" .. nextIdx .. " on " .. dateStr)
    return true
end
