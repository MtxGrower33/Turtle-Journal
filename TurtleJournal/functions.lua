---@diagnostic disable: deprecated
--==================================================
-- FUNCTIONS
--==================================================
local tj = TurtleJournal
local d = tj.dt
d:debug("booting...")

tj:RegisterModule("functions", function()

    local defaults = {
        sound = true,
        autoOpen = false,
        darkMode = false,
        time = true,
        customName = "Turtle Journal",
        focus = true,
        limit = true,
        sit = true,
        centerText = true,
        autoSave = false,
        scale = 1,
        alpha = 1.0,
    }

    local typing = {
        lastSoundTime = 0,
        soundInterval = 5,
    }

    -- defaults init
    function tj:InitializeSettings()
        if not TurtleJournal_Settings then
            TurtleJournal_Settings = {}
            d:debug("ATTENTION: Created new database")
        end

        for setting, defaultValue in pairs(defaults) do
            if TurtleJournal_Settings[setting] == nil then
                TurtleJournal_Settings[setting] = defaultValue
                d:debug("Created new setting: " .. setting)
            end
        end
    end

    -- small funcs
    function tj.StartTyping()        local currentTime = GetTime()
        local db = TurtleJournal_Settings
        if tj.frames.editBox.isFocused and db.sound and (currentTime - typing.lastSoundTime) >= typing.soundInterval then
            typing.lastSoundTime = GetTime() -- reset timer
            PlaySound("WriteQuest")
            d:debug("Started typing, played sound")
        end
        if db.autoOpen then
            tj.frames.sideEntryList:Show()
            tj.frames.miniScrollPanel:Show()
            d:debug("Opened journal")
        end
    end
    
    function tj.CloseJournal()
        tj.frames.main:Hide()
        tj.frames.bottomOptionFrame2:Hide()
        tj.DoEmote("STAND")
        tj.SwooshSound()
        if TurtleJournal_Settings.autoSave and tj.selectedEntry then
            tj.SaveEntry(false)
        end
        d:debug("TurtleJournal closed")
    end

    function tj.SetName()
        StaticPopupDialogs["TURTLEJOURNAL_SET_NAME"] = {
            text = "Enter a new name for your journal:",
            button1 = "Accept",
            button2 = "Cancel",
            hasEditBox = true,
            maxLetters = 19,
            OnAccept = function()
                local editBox = getglobal(this:GetParent():GetName().."EditBox")
                local text = editBox:GetText()
                if text and text ~= "" then
                    TurtleJournal_Settings.customName = text
                    tj.frames.titleText:SetText(text)
                    d:debug("Journal name changed to: " .. text)
                end
            end,
            EditBoxOnEnterPressed = function()
                local text = this:GetText()
                if text and text ~= "" then
                    TurtleJournal_Settings.customName = text
                    tj.frames.titleText:SetText(text)
                    d:debug("Journal name changed to: " .. text)
                    this:GetParent():Hide()
                end
            end,
            EditBoxOnEscapePressed = function()
                this:GetParent():Hide()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }

        StaticPopup_Show("TURTLEJOURNAL_SET_NAME")
    end

    function tj.SetBottomFrameColor()
        local startTime = GetTime()
        local duration = 1.0
        local startColors = {}
        local endColors = {}

        -- set initial colors immediately without transition on first load
        if not tj.initialColorSet then
            tj.initialColorSet = true
            if TurtleJournal_Settings.darkMode then
                tj.frames.editBox:SetTextColor(1, 1, 1, 1)
                tj.frames.titleEditBox:SetTextColor(1, 1, 1, 1)
                tj.frames.frameTex:SetVertexColor(0.4, 0.4, 0.4, 1)
                tj.frames.bottomOptionFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                tj.frames.bottomOptionFrame2:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                tj.frames.sideEntryList:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                tj.frames.miniScrollPanel:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                return -- skip the transition on initial load
            end
        end

        -- store start and end colors based on dark mode
        if TurtleJournal_Settings.darkMode then
            startColors = {
                editBox = {tj.frames.editBox:GetTextColor()},
                titleEditBox = {tj.frames.titleEditBox:GetTextColor()},
                frameTex = {tj.frames.frameTex:GetVertexColor()},
                borders = {tj.frames.bottomOptionFrame:GetBackdropBorderColor()}
            }
            endColors = {
                editBox = {1, 1, 1, 1},
                titleEditBox = {1, 1, 1, 1},
                frameTex = {0.4, 0.4, 0.4, 1},
                borders = {0.4, 0.4, 0.4, 1}
            }
        else
            startColors = {
                editBox = {tj.frames.editBox:GetTextColor()},
                titleEditBox = {tj.frames.titleEditBox:GetTextColor()},
                frameTex = {tj.frames.frameTex:GetVertexColor()},
                borders = {tj.frames.bottomOptionFrame:GetBackdropBorderColor()}
            }
            endColors = {
                editBox = {0, 0, 0, 1},
                titleEditBox = {0, 0, 0, 1},
                frameTex = {1, 1, 1, 1},
                borders = {1, 1, 1, 1}
            }
        end

        local function lerp(start, end_, progress)
            return start + (end_ - start) * progress
        end

        local frame = CreateFrame("Frame")
        frame:SetScript("OnUpdate", function()
            local elapsed = GetTime() - startTime
            local progress = math.min(elapsed / duration, 1)

            -- update colors
            local r, g, b, a

            r = lerp(startColors.editBox[1], endColors.editBox[1], progress)
            g = lerp(startColors.editBox[2], endColors.editBox[2], progress)
            b = lerp(startColors.editBox[3], endColors.editBox[3], progress)
            a = lerp(startColors.editBox[4], endColors.editBox[4], progress)
            tj.frames.editBox:SetTextColor(r, g, b, a)
            tj.frames.titleEditBox:SetTextColor(r, g, b, a)

            r = lerp(startColors.frameTex[1], endColors.frameTex[1], progress)
            g = lerp(startColors.frameTex[2], endColors.frameTex[2], progress)
            b = lerp(startColors.frameTex[3], endColors.frameTex[3], progress)
            a = lerp(startColors.frameTex[4], endColors.frameTex[4], progress)
            tj.frames.frameTex:SetVertexColor(r, g, b, a)

            r = lerp(startColors.borders[1], endColors.borders[1], progress)
            g = lerp(startColors.borders[2], endColors.borders[2], progress)
            b = lerp(startColors.borders[3], endColors.borders[3], progress)
            a = lerp(startColors.borders[4], endColors.borders[4], progress)
            tj.frames.bottomOptionFrame:SetBackdropBorderColor(r, g, b, a)
            tj.frames.bottomOptionFrame2:SetBackdropBorderColor(r, g, b, a)
            tj.frames.sideEntryList:SetBackdropBorderColor(r, g, b, a)
            tj.frames.miniScrollPanel:SetBackdropBorderColor(r, g, b, a)

            -- stop
            if progress >= 1 then
                this:SetScript("OnUpdate", nil)
            end
        end)
    end

    function tj.SetTimeFrame()
        if TurtleJournal_Settings.time then
            if not tj.frames.timeFrame then
                local timeFrame = CreateFrame("Frame", nil, tj.frames.main)
                timeFrame:SetWidth(200)
                timeFrame:SetHeight(30)
                timeFrame:SetFrameStrata("DIALOG")
                timeFrame:SetPoint("TOP", tj.frames.main, "TOP", 0, -47)

                local texture = timeFrame:CreateTexture(nil, "BACKGROUND")
                texture:SetTexture("Interface\\AddOns\\Turtlejournal\\media\\QLgadgetframe.tga")
                texture:SetPoint("TOPLEFT", timeFrame, "TOPLEFT", -80, 20)
                texture:SetPoint("BOTTOMRIGHT", timeFrame, "BOTTOMRIGHT", 80, -20)

                local text = timeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                text:SetPoint("CENTER", timeFrame, "CENTER", 0, 0)

                local lastUpdate = 0
                local updateInterval = 1.0

                timeFrame:SetScript("OnUpdate", function()
                    local currentTime = GetTime()
                    if currentTime - lastUpdate >= updateInterval then
                        text:SetText(date("%H:%M:%S - %d/%m/%Y"))
                        lastUpdate = currentTime
                    end
                end)
                tj.frames.timeFrame = timeFrame
            else
                tj.frames.timeFrame:Show()
            end
        else
            if tj.frames.timeFrame then
                tj.frames.timeFrame:Hide()
            end
        end
    end

    function tj.SwooshSound()
        local db = TurtleJournal_Settings
        if db.sound then
            if tj.frames.main and tj.frames.main:IsVisible() then
                PlaySound("igQuestLogOpen")
            else
                PlaySound("igQuestLogClose")
            end
        end

        d:debug("Performed swoosh sound")
    end

    function tj.DoEmote(emoteName)
        local db = TurtleJournal_Settings

        if db.sit then
            DoEmote(emoteName)
            d:debug("Performed " .. emoteName .. " emote")
        end
    end

    function tj.SetupFrameControls()
        local frame = tj.frames.main

        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function()
            local delta = arg1

            -- handle scaling with SHIFT
            if IsShiftKeyDown() then
                local currentScale = frame:GetScale()
                local newScale = currentScale + (delta * 0.1)
                newScale = math.max(0.5, math.min(1.3, newScale))
                frame:SetScale(newScale)
                TurtleJournal_Settings.scale = newScale
                d:debug("Scale changed to: " .. newScale)

            -- handle alpha with CTRL
            elseif IsControlKeyDown() then
                local currentAlpha = frame:GetAlpha()
                local newAlpha = currentAlpha + (delta * 0.1)
                newAlpha = math.max(0.1, math.min(1.0, newAlpha))
                frame:SetAlpha(newAlpha)
                TurtleJournal_Settings.alpha = newAlpha
                d:debug("Alpha changed to: " .. newAlpha)
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

    function tj.SetupMainFrameOpener()
        local oldHandler = PlayerFrame:GetScript("OnMouseUp")

        PlayerFrame:SetScript("OnMouseUp", function()
            -- check if shift is held and right mouse button was clicked
            if IsShiftKeyDown() and arg1 == "LeftButton" then
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
                    d:debug("Opened journal")
                    tj.SwooshSound()
                    d:debug("TurtleJournal opened")
                    tj.DoEmote("SIT")
                end
            elseif oldHandler then
                -- call original handler if it exists
                oldHandler(this, arg1)
            end
        end)
    end

    function tj.UpdateSaveButtonState()
        local saveButton = tj.frames.saveButton
        if tj.currentViewingEntry then
            saveButton:Disable()
        else
            saveButton:Enable()
        end
    end

    -- main funcs
    tj.currentViewingEntry = nil  -- to check for currently viewed in order to disable savebtn

    function tj.GetEntries(dateStr)
        local db = TurtleJournal_DB
        dateStr = dateStr or date("%Y-%m-%d")

        if not db[dateStr] then
            d:debug("No entries found on date: " .. dateStr)
            return nil
        end

        return db[dateStr]
    end

    function tj.SelectEntry(dateStr, entryId)
        if not entryId then
            d:debug("Error: Missing parameters")
            return nil
        end

        dateStr = dateStr or date("%Y-%m-%d")
        local entries = tj.GetEntries(dateStr)
        if entries and entries[entryId] then
            tj.currentViewingEntry = {dateStr = dateStr, entryId = entryId}
            return entries[entryId]
        end
        tj.currentViewingEntry = nil
        return nil
    end

    function tj.SaveEntry(makeNew)
        -- get content from editboxes
        local content = tj.frames.editBox:GetText()
        local title = tj.frames.titleEditBox:GetText()

        -- input validation
        if not title or title == "" then
            d:debug("Error: Title cannot be empty")
            d:print("Title cannot be empty. Please enter a title.")
            tj.frames.titleEditBox:SetFocus()
            return false
        end

        -- content length check
        local MAX_CONTENT_LENGTH = 4000
        if string.len(content) > MAX_CONTENT_LENGTH then
            d:debug("Error: Content exceeds maximum length of " .. MAX_CONTENT_LENGTH)
            d:print("Content exceeds maximum length of " .. MAX_CONTENT_LENGTH.. " characters. Please shorten your entry.")
            return false
        end

        local db = TurtleJournal_DB
        local dateStr = nil
        local backup = nil
        
        if makeNew then
            -- create backup of current entries for this date
            dateStr = date("%Y-%m-%d")
            if db[dateStr] then
                backup = {}
                for k, v in pairs(db[dateStr]) do
                    backup[k] = v
                end
            end

            -- check if date exists in the database
            if not db[dateStr] then
                db[dateStr] = {}
                d:debug("Created new date entry: " .. dateStr)
            end
        else
            dateStr = tj.currentViewingEntry.dateStr
        end

        local noteIdx = nil
        if makeNew then
            -- find the next available index for the entry
            local maxIdx = 0
            for k, _ in pairs(db[dateStr]) do
                local num = tonumber(k)
                if num and num > maxIdx then
                    maxIdx = num
                end
            end
            noteIdx = maxIdx + 1;
        else
            noteIdx = tj.currentViewingEntry.entryId
        end
        
        -- create entry structure (removed timestamp for now)
        local entry = {
            title = title,
            content = content
        }

        -- try to add the new entry
        local success = true
        local function addEntry()
            db[dateStr][tostring(noteIdx)] = entry
        end
        success = pcall(addEntry)

        -- if the entry failed, restore the backup
        if not success and backup then
            db[dateStr] = backup
            d:debug("Error: Entry failed, restored from backup")
            d:print("Error: Entry failed, restored from backup.")
            return false
        end

        -- if both fails, sad day
        if not success and not backup then
            d:debug("Error: Entry failed, no backup available")
            d:print("Error: Entry failed, no backup available.")
            return false
        end

        -- hurray
        tj.frames.leftScrollFrame:SetVerticalScroll(0)
        d:print("Entry ".. d.colors.green .."saved|r.")

        -- refresh the entry list
        tj.UpdateEntryList()

        d:debug("Added entry #" .. noteIdx .. " on " .. dateStr)
        
        if makeNew then
            tj.currentViewingEntry = {dateStr = dateStr, entryId = noteIdx}
        end

        return true
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
            local dateStr = tj.selectedEntry.dateStr
            local entryId = tj.selectedEntry.id
            local db = TurtleJournal_DB

            -- check if entry exists
            if not db[dateStr] or
               not db[dateStr][entryId] then
                d:debug("Error: Entry not found")
                StaticPopup_Hide("TURTLEJOURNAL_DELETE_CONFIRM")
                return false
            end

            -- create backup
            local backup = db[dateStr][entryId]

            -- try to delete the entry
            local success = true
            local function removeEntry()
                db[dateStr][entryId] = nil
                d:print("Entry ".. d.colors.green .."deleted|r.")
                tj.currentViewingEntry = nil
                tj.frames.saveButton:Disable()
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
                d:debug("Error: Delete failed, restored from backup")
                StaticPopup_Hide("TURTLEJOURNAL_DELETE_CONFIRM")
                return false
            end

            -- clear selection
            tj.selectedEntry = nil
            if tj.selectedButton then
                tj.selectedButton:UnlockHighlight()
                tj.selectedButton = nil
            end

            -- refresh the entry list
            tj.UpdateEntryList(dateStr)
            tj.frames.editBox:SetText("")
            tj.frames.titleEditBox:SetText("")

            -- hide the entire popup after successful deletion
            StaticPopup_Hide("TURTLEJOURNAL_DELETE_CONFIRM")
            d:debug("Deleted entry #" .. entryId .. " on " .. dateStr)
            return true
        end,
    }

    function tj.DeleteEntry()
        if not tj.selectedEntry then
            d:debug("Error: No entry selected")
            d:print("No entry selected. Please select an entry to delete.")
            return false
        end

        -- show the confirmation dialog
        StaticPopup_Show("TURTLEJOURNAL_DELETE_CONFIRM")
    end

    -- run it
    tj:InitializeSettings()
end)
