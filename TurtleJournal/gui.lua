---@diagnostic disable: deprecated
--==================================================
-- GUI
--==================================================
local tj = TurtleJournal
local d = tj.dt
d:debug("booting...")

tj:RegisterModule("gui", function ()

    function tj:CreateGUI()
        --==================================================
        -- MAINFRAME
        --==================================================
        local mainFrame = CreateFrame("Frame", "MyBasicFrame", UIParent)
        mainFrame:SetWidth(420)
        mainFrame:SetHeight(515)
        mainFrame:SetPoint("CENTER", 0, 0)
        mainFrame:SetFrameStrata("DIALOG")
        -- mainFrame:SetToplevel(true)
        mainFrame:SetClampedToScreen(true)
        mainFrame:EnableMouse(true)
        mainFrame:SetMovable(true)
        mainFrame:SetScript("OnMouseDown", function() this:StartMoving() end)
        mainFrame:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)
        mainFrame:SetScale(0.8)

        tinsert(UISpecialFrames, mainFrame:GetName())

        local bookTexture = mainFrame:CreateTexture(nil, "ARTWORK")
        bookTexture:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon")
        bookTexture:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -10)
        bookTexture:SetWidth(70)
        bookTexture:SetHeight(70)

        local titleText = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        titleText:SetPoint("TOP", mainFrame, "TOP", 0, -23)
        titleText:SetText(TurtleJournal_Settings.customName)
        titleText:SetTextColor(1, 1, 1)

        local frameTex = mainFrame:CreateTexture(nil, "BACKGROUND")
        frameTex:SetTexture("Interface\\AddOns\\Turtlejournal\\media\\QLmainframe2.tga")
        frameTex:SetPoint("CENTER", mainFrame, "CENTER", 0, 0)
        frameTex:SetWidth(512)
        frameTex:SetHeight(512)

        --==================================================
        -- MAIN EDITBOX
        --==================================================
        local editboxScrollframe = CreateFrame("ScrollFrame", "editboxScrollframe", mainFrame, "UIPanelScrollFrameTemplate")
        editboxScrollframe:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 50, -150)
        editboxScrollframe:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -48, 20)

        local editboxScrollChild = CreateFrame("Frame", "MyeditboxScrollChild", editboxScrollframe)
        editboxScrollChild:SetWidth(410)
        editboxScrollChild:SetHeight(2200)
        editboxScrollframe:SetScrollChild(editboxScrollChild)

        local editBox = CreateFrame("EditBox", nil, editboxScrollChild)
        editBox:SetWidth(280)
        editBox:SetHeight(1800)
        editBox:SetPoint("TOPLEFT", editboxScrollChild, "TOPLEFT", 15, -0)
        editBox:SetPoint("BOTTOMRIGHT", editboxScrollChild, "BOTTOMRIGHT", -110, 45)
        editBox:SetFontObject(QuestFont)
        editBox:SetMaxLetters(4000)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:EnableMouse(true)
        editBox:SetText("")
        editBox:SetFont("Fonts\\FRIZQT__.TTF", 15, "")
        if TurtleJournal_Settings.centerText then
            editBox:SetJustifyH("CENTER")
        else
            editBox:SetJustifyH("LEFT")
        end
        editBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        editBox:SetScript("OnTabPressed", function () tj.frames.titleEditBox:SetFocus() end)

        -- focus flag for sound system
        editBox.isFocused = false
        editBox:SetScript("OnEditFocusGained", function() this.isFocused = true end)
        editBox:SetScript("OnEditFocusLost", function() this.isFocused = false end)

        -- main content editbox
        -- EXPERIMENTAL FEATURES: attempt to limit lines so users cant do \n\n\n\n\n and go
        -- beyond the editbox boundaries. Also checks string lenght and limits last line (editbox bug).
        -- FocusCursor() will attempt to focus the cursor by counting lines.
        -- ScrollToTop() will scroll to the top of the editbox if the text is empty.
        local function CountLinesAndLastLength(text)
            local lines = 1
            local lastLineStart = 1
            local charsPerLine = 38
            local currentLineLength = 0

            -- split by explicit line breaks
            for i = 1, string.len(text) do
                local char = string.sub(text, i, i)

                if char == "\n" then
                    lines = lines + 1
                    lastLineStart = i + 1
                    currentLineLength = 0
                else
                    currentLineLength = currentLineLength + 1
                    -- if we exceed chars per line, count it as a new line
                    if currentLineLength > charsPerLine then
                        lines = lines + 1
                        currentLineLength = 1
                    end
                end
            end

            -- get length of last line
            local lastLine = string.sub(text, lastLineStart)
            return lines, string.len(lastLine)
        end

        local function CheckTextLimits(text)
            if TurtleJournal_Settings.limit then
                local lines, lastLineLength = CountLinesAndLastLength(text)
                local maxLines = 130
                local maxCharsPerLine = 5

                if lines > maxLines or (lines == maxLines and lastLineLength >= maxCharsPerLine) then
                    -- remove the last entered character or line break
                    local newText = string.sub(text, 1, -2)
                    editBox:SetText(newText)
                    d:debug("LIMIT TRIGGER: Text removed")
                end
            end
        end

        local function FocusCursor()
            if TurtleJournal_Settings.focus then
                local text = editBox:GetText()
                local lines, _ = CountLinesAndLastLength(text)
                local scrollFrame = editboxScrollframe

                -- only start scrolling after 12 lines
                if lines > 10 then
                    -- calculate how many "pages" of 4 lines we need to scroll
                    local linesAfter21 = lines - 10
                    local scrollSteps = math.floor(linesAfter21 / 4)

                    -- each mousewheel step is typically around 30-40 pixels
                    local scrollAmount = scrollSteps * 60
                    scrollFrame:SetVerticalScroll(scrollAmount)
                end

                d:debug("focus cursor")
            else
                d:debug("no focus cursor")
            end
        end

        local function ScrollToTop()
            local text = editBox:GetText()
            local scrollFrame = editboxScrollframe

            if text == "" or string.len(text) == 1 then
                scrollFrame:SetVerticalScroll(0)
                d:debug("scroll to top - empty text or single character")
            end
        end

        editBox:SetScript("OnTextChanged", function()
            if this.isFocused then
                local text = this:GetText()

                tj.frames.saveButton:Enable()

                CheckTextLimits(text)
                ScrollToTop()
                FocusCursor()
                tj.StartTyping()
                d:debug("typing...")
            end
        end)

        local titleEditBox = CreateFrame("EditBox", nil, mainFrame)
        titleEditBox:SetWidth(270)
        titleEditBox:SetHeight(37)
        titleEditBox:SetPoint("TOP", mainFrame, "TOP", 25, -85)
        titleEditBox:SetAutoFocus(false)
        titleEditBox:SetMaxLetters(20)
        titleEditBox:SetFontObject(GameFontNormal)
        titleEditBox:SetText("")
        titleEditBox:EnableMouse(true)
        titleEditBox:SetJustifyH("CENTER")
        titleEditBox:SetFont("Fonts\\MORPHEUS.TTF", 25, "NONE")
        titleEditBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        titleEditBox:SetScript("OnEnterPressed", function() tj.frames.editBox:SetFocus() end)
        titleEditBox:SetScript("OnTabPressed", function () tj.frames.editBox:SetFocus() end)
        titleEditBox:SetScript("OnTextChanged", function ()
            tj.frames.saveButton:Enable()
            tj.StartTyping()
            d:debug("typing...")
        end)

        --==================================================
        -- SIDE ENTRYLIST
        --==================================================
        local sideEntryList = CreateFrame("Frame", "MySideEntryList", mainFrame)
        sideEntryList:SetWidth(250)
        sideEntryList:SetHeight(380)
        sideEntryList:SetPoint("RIGHT", mainFrame, "LEFT", -19, -48)
        sideEntryList:SetFrameStrata("HIGH")
        sideEntryList:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        sideEntryList:Hide()

        local leftScrollFrame = CreateFrame("ScrollFrame", "MyLeftScrollFrame", sideEntryList, "UIPanelScrollFrameTemplate")
        leftScrollFrame:SetPoint("TOPLEFT", sideEntryList, "TOPLEFT", 5, -20)
        leftScrollFrame:SetPoint("BOTTOMRIGHT", sideEntryList, "BOTTOMRIGHT", -5, 15)

        local leftScrollChild = CreateFrame("Frame", "MyLeftScrollChild", leftScrollFrame)
        leftScrollChild:SetWidth(leftScrollFrame:GetWidth() - 20)
        leftScrollChild:SetHeight(5000)
        leftScrollFrame:SetScrollChild(leftScrollChild)

        function tj.UpdateEntryList()
            local allEntries = {}

            -- gather all entries from all dates
            for date, dateEntries in pairs(TurtleJournal_DB) do
                for id, entry in pairs(dateEntries) do
                    local compoundId = date .. "_" .. id
                    allEntries[compoundId] = {
                        title = entry.title,
                        dateStr = date,
                        originalId = id,
                    }
                end
            end

            -- clear existing entries
            if tj.frames.sideEntryList.buttons then
                for _, button in pairs(tj.frames.sideEntryList.buttons) do
                    button:Hide()
                end
            end

            -- if no entries, we're done
            if not next(allEntries) then
                tj.frames.sideEntryList.buttons = {}
                leftScrollChild:SetHeight(leftScrollFrame:GetHeight())
                return
            end

            -- convert to sorted array
            local sortedEntries = {}
            for compoundId, entry in pairs(allEntries) do
                table.insert(sortedEntries, {
                    compoundId = compoundId,
                    entry = entry
                })
            end

            -- sort entries by numeric ID (reversed - highest to lowest)
            table.sort(sortedEntries, function(a, b)
                return a.compoundId > b.compoundId
            end)


            tj.frames.sideEntryList.buttons = tj.frames.sideEntryList.buttons or {}

            local buttonHeight = 25
            local offset = 15

            -- create buttons using sorted entries
            for _, sortedEntry in ipairs(sortedEntries) do
                local compoundId = sortedEntry.compoundId
                local entry = sortedEntry.entry

                local button = tj.frames.sideEntryList.buttons[compoundId] or
                    CreateFrame("Button", "TJEntryButton"..compoundId, leftScrollChild)

                button:SetPoint("TOPLEFT", leftScrollChild, "TOPLEFT", 10, -offset)
                button:SetWidth(200)
                button:SetHeight(buttonHeight)
                button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

                if not button.text then
                    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    button.text:SetPoint("LEFT", 5, 0)
                    button.text:SetWidth(190)
                end

                if TurtleJournal_Settings.time then
                    button.text:SetText(entry.dateStr .. ": " .. entry.title)
                else
                    button.text:SetText(entry.title)
                end
                button:Show()

                button.entryData = {
                    dateStr = entry.dateStr,
                    id = tostring(entry.originalId)
                }

                button:SetScript("OnClick", function()
                    local data = this.entryData
                    editBox:ClearFocus()
                    titleEditBox:ClearFocus()
                    
                    if tj.selectedButton then
                        tj.selectedButton:UnlockHighlight()
                    end
                    this:LockHighlight()
                    tj.selectedButton = this
                    tj.selectedEntry = data
                    d:debug("Selected entry #" .. data.id .. " on " .. data.dateStr)
                
                    tj.DisplayEntry(data.dateStr, data.id)
                    editBox:ClearFocus()
                    titleEditBox:ClearFocus()
                    editboxScrollframe:SetVerticalScroll(0)
                end)

                tj.frames.sideEntryList.buttons[compoundId] = button
                offset = offset + buttonHeight + 2
            end
        end

        function tj.DisplayEntry(dateStr, entryId)
            local entry = tj.SelectEntry(dateStr, entryId)
            if not entry then return end

            tj.frames.editBox:SetText(entry.content)
            tj.frames.titleEditBox:SetText(entry.title)
        end

        -- deco
        local miniScrollPanel = CreateFrame("Frame", "MyMiniScrollPanel", mainFrame)
        miniScrollPanel:SetWidth(32)
        miniScrollPanel:SetHeight(sideEntryList:GetHeight() -19)
        miniScrollPanel:SetPoint("LEFT", sideEntryList, "RIGHT", -7, -2)
        miniScrollPanel:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 3,
            edgeSize = 15,
        })
        miniScrollPanel:Hide()

        --==================================================
        -- OPTIONS PANEL
        --==================================================
        local bottomOptionFrame = CreateFrame("Frame", "MyBottomOptionFrame", mainFrame)
        bottomOptionFrame:SetWidth(300)
        bottomOptionFrame:SetHeight(55)
        bottomOptionFrame:SetPoint("TOP", mainFrame, "BOTTOM", 0, 5)
        bottomOptionFrame:SetFrameStrata("HIGH")
        bottomOptionFrame:EnableMouse(true)
        bottomOptionFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })

        local bottomOptionFrame2 = CreateFrame("Frame", "MyBottomOptionFrame2", mainFrame)
        bottomOptionFrame2:SetWidth(300)
        bottomOptionFrame2:SetHeight(120)
        bottomOptionFrame2:SetPoint("TOP", bottomOptionFrame, "BOTTOM", 0, 5)
        bottomOptionFrame2:SetFrameStrata("HIGH")
        bottomOptionFrame2:EnableMouse(true)
        bottomOptionFrame2:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        bottomOptionFrame2:Hide()

        --==================================================
        -- BUTTONS
        --==================================================
        local entryButton = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
        entryButton:SetWidth(14)
        entryButton:SetHeight(14)
        entryButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 65, -97)
        -- entryButton:SetFrameStrata("DIALOG")
        -- entryButton:SetToplevel(true)
        entryButton:SetText("<")
        entryButton:SetScript("OnClick", function()
            if sideEntryList:IsVisible() then
                if TurtleJournal_Settings.sound then
                    PlaySound("igAbilityClose")
                end
                sideEntryList:Hide()
                miniScrollPanel:Hide()
            else
                if TurtleJournal_Settings.sound then
                    PlaySound("igAbilityOpen")
                end
                sideEntryList:Show()
                miniScrollPanel:Show()
            end
        end)
        entryButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Toggle entry panel")
            GameTooltip:Show()
        end)
        entryButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local optionsButton = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
        optionsButton:SetWidth(14)
        optionsButton:SetHeight(14)
        optionsButton:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 25, 21)
        optionsButton:SetText("*")
        optionsButton:SetScript("OnClick", function()
            if bottomOptionFrame2:IsVisible() then
                bottomOptionFrame2:Hide()
                if TurtleJournal_Settings.sound then
                    PlaySound("igAbilityClose")
                end
            else
                if TurtleJournal_Settings.sound then
                    PlaySound("igAbilityOpen")
                end
                bottomOptionFrame2:Show()
            end
        end)
        optionsButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Toggle options panel")
            GameTooltip:AddLine("SHIFT+CLICK your portrait to open.\n\nCTRL+MOUSEWHEEL to adjust alpha.\nSHIFT+MOUSEWHEEL to adjust scale.", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        optionsButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -13, -13)
        closeButton:SetScript("OnClick", function()
            mainFrame:Hide()
            tj.frames.bottomOptionFrame2:Hide()
            tj.SwooshSound()
            tj.DoEmote("STAND")
            d:debug("closebtn clicked")
        end)
        closeButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Close the journal")
            GameTooltip:Show()
        end)
        closeButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local newButton = CreateFrame("Button", nil, bottomOptionFrame, "UIPanelButtonTemplate")
        newButton:SetWidth(59)
        newButton:SetHeight(15)
        newButton:SetPoint("TOPLEFT", bottomOptionFrame, "TOPLEFT", 25, -20)
        newButton:SetText("New")
        newButton:SetScript("OnClick", function()
            if TurtleJournal_Settings.autoOpen then
                miniScrollPanel:Show()
                sideEntryList:Show()
            end
            editBox:SetText("")
            tj.currentViewingEntry = nil
            ScrollToTop()
            titleEditBox:SetText("Title")
            titleEditBox:SetFocus()
            tj.SaveEntry(true)
            tj.selectedEntry = nil
            if tj.selectedButton then
                tj.selectedButton:UnlockHighlight()
                tj.selectedButton = nil
            end
        end)
        newButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Clear entry")
            GameTooltip:Show()
        end)
        newButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local saveButton = CreateFrame("Button", nil, bottomOptionFrame, "UIPanelButtonTemplate")
        saveButton:SetWidth(59)
        saveButton:SetHeight(15)
        saveButton:SetPoint("LEFT", newButton, "RIGHT", 5, 0)
        saveButton:SetText("Save")
        saveButton:SetScript("OnClick", function()
            tj.SaveEntry(false)
            tj.frames.saveButton:Disable()
        end)
        saveButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Save current entry")
            GameTooltip:Show()
        end)
        saveButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local deleteButton = CreateFrame("Button", nil, bottomOptionFrame, "UIPanelButtonTemplate")
        deleteButton:SetWidth(59)
        deleteButton:SetHeight(15)
        deleteButton:SetPoint("LEFT", saveButton, "RIGHT", 5, 0)
        deleteButton:SetText("Delete")
        deleteButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        deleteButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        deleteButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        deleteButton:GetNormalTexture():SetVertexColor(0.5, 0, 0, 1)
        deleteButton:SetScript("OnClick", function()
            tj.frames.sideEntryList:Show()
            tj.frames.miniScrollPanel:Show()
            tj.DeleteEntry()
            ScrollToTop()
        end)
        deleteButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Delete selected entry")
            GameTooltip:Show()
        end)
        deleteButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local saveDbButton = CreateFrame("Button", nil, bottomOptionFrame, "UIPanelButtonTemplate")
        saveDbButton:SetWidth(59)
        saveDbButton:SetHeight(15)
        saveDbButton:SetPoint("LEFT", deleteButton, "RIGHT", 5, 0)
        saveDbButton:SetText("Save DB")
        saveDbButton:SetScript("OnClick", function()
            ReloadUI()
        end)
        saveDbButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Save database and reload UI")
            GameTooltip:Show()
        end)
        saveDbButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local soundCheckbox = CreateFrame("CheckButton", "TJSoundCheckbox", bottomOptionFrame2, "UICheckButtonTemplate")
        soundCheckbox:SetPoint("TOPLEFT", bottomOptionFrame2, "TOPLEFT", 25, -25)
        soundCheckbox:SetWidth(20)
        soundCheckbox:SetHeight(20)
        getglobal(soundCheckbox:GetName().."Text"):SetText("Enable Sound")
        soundCheckbox:SetChecked(TurtleJournal_Settings.sound)
        soundCheckbox:SetScript("OnClick", function()
            TurtleJournal_Settings.sound = (this:GetChecked() == 1)
            d:debug("Sound setting changed to: "..tostring(TurtleJournal_Settings.sound))
        end)
        soundCheckbox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Toggle sound effects")
            GameTooltip:Show()
        end)
        soundCheckbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local sitCheckbox = CreateFrame("CheckButton", "TJSitCheckbox", bottomOptionFrame2, "UICheckButtonTemplate")
        sitCheckbox:SetPoint("TOP", soundCheckbox, "BOTTOM", 0, 0)
        sitCheckbox:SetWidth(20)
        sitCheckbox:SetHeight(20)
        getglobal(sitCheckbox:GetName().."Text"):SetText("Auto-Sit")
        sitCheckbox:SetChecked(TurtleJournal_Settings.sit)
        sitCheckbox:SetScript("OnClick", function()
            TurtleJournal_Settings.sit = (this:GetChecked() == 1)
            d:debug("Sit setting changed to: "..tostring(TurtleJournal_Settings.sit))
        end)
        sitCheckbox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Toggle auto-sit")
            GameTooltip:Show()
        end)
        sitCheckbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local focusCheckbox = CreateFrame("CheckButton", "TJFocusCheckbox", bottomOptionFrame2, "UICheckButtonTemplate")
        focusCheckbox:SetPoint("TOP", sitCheckbox, "BOTTOM", 0, 0)
        focusCheckbox:SetWidth(20)
        focusCheckbox:SetHeight(20)
        getglobal(focusCheckbox:GetName().."Text"):SetText("Auto-Focus")
        getglobal(focusCheckbox:GetName().."Text"):SetTextColor(1, 0, 0)
        focusCheckbox:SetChecked(TurtleJournal_Settings.focus)
        focusCheckbox:SetScript("OnClick", function()
            TurtleJournal_Settings.focus = (this:GetChecked() == 1)
            d:debug("Focus setting changed to: "..tostring(TurtleJournal_Settings.focus))
        end)
        focusCheckbox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(d.colors.red.. "EXPERIMENTAL|r: Toggle cursor focus")
            GameTooltip:AddLine("Turtle Journal tries to keep the focus on your cursor\nby counting your characters and breaks.", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        focusCheckbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local limitCheckbox = CreateFrame("CheckButton", "TJLimitCheckbox", bottomOptionFrame2, "UICheckButtonTemplate")
        limitCheckbox:SetPoint("LEFT", focusCheckbox, "LEFT", 100, 0)
        limitCheckbox:SetWidth(20)
        limitCheckbox:SetHeight(20)
        getglobal(limitCheckbox:GetName().."Text"):SetText("Text Limiter")
        getglobal(limitCheckbox:GetName().."Text"):SetTextColor(1, 0, 0)
        limitCheckbox:SetChecked(TurtleJournal_Settings.limit)
        limitCheckbox:SetScript("OnClick", function()
            TurtleJournal_Settings.limit = (this:GetChecked() == 1)
            d:debug("Limit setting changed to: "..tostring(TurtleJournal_Settings.limit))
        end)
        limitCheckbox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(d.colors.red.. "EXPERIMENTAL|r: Toggle character limiter")
            GameTooltip:AddLine("Turtle Journal tries to keep your text limited to 130 lines,\nso that your text does not go beyond the textures.", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        limitCheckbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local autoOpenCheckbox = CreateFrame("CheckButton", "TJAutoOpenCheckbox", bottomOptionFrame2, "UICheckButtonTemplate")
        autoOpenCheckbox:SetPoint("LEFT", soundCheckbox, "LEFT", 100, 0)
        autoOpenCheckbox:SetWidth(20)
        autoOpenCheckbox:SetHeight(20)
        getglobal(autoOpenCheckbox:GetName().."Text"):SetText("Auto-Open")
        autoOpenCheckbox:SetChecked(TurtleJournal_Settings.autoOpen)
        autoOpenCheckbox:SetScript("OnClick", function()
            TurtleJournal_Settings.autoOpen = (this:GetChecked() == 1)
            d:debug("Auto Open setting changed to: "..tostring(TurtleJournal_Settings.autoOpen))
        end)
        autoOpenCheckbox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Toggle auto-opening the entry list when opening\nthe journal, creating a new note, or typing")
            GameTooltip:Show()
        end)
        autoOpenCheckbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local darkModeCheckbox = CreateFrame("CheckButton", "TJDarkModeCheckbox", bottomOptionFrame2, "UICheckButtonTemplate")
        darkModeCheckbox:SetPoint("TOP", autoOpenCheckbox, "BOTTOM", 0, 0)
        darkModeCheckbox:SetWidth(20)
        darkModeCheckbox:SetHeight(20)
        getglobal(darkModeCheckbox:GetName().."Text"):SetText("Dark Mode")
        darkModeCheckbox:SetChecked(TurtleJournal_Settings.darkMode)
        darkModeCheckbox:SetScript("OnClick", function()
            TurtleJournal_Settings.darkMode = (this:GetChecked() == 1)
            tj.SetBottomFrameColor()
            d:debug("Dark Mode setting changed to: "..tostring(TurtleJournal_Settings.darkMode))
        end)
        darkModeCheckbox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Toggle darkmode")
            GameTooltip:Show()
        end)
        darkModeCheckbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        local timeCheckbox = CreateFrame("CheckButton", "TJTimeCheckbox", bottomOptionFrame2, "UICheckButtonTemplate")
        timeCheckbox:SetPoint("LEFT", autoOpenCheckbox, "LEFT", 100, 0)
        timeCheckbox:SetWidth(20)
        timeCheckbox:SetHeight(20)
        getglobal(timeCheckbox:GetName().."Text"):SetText("Time")
        timeCheckbox:SetChecked(TurtleJournal_Settings.time)
        timeCheckbox:SetScript("OnClick", function()
            TurtleJournal_Settings.time = (this:GetChecked() == 1)
            tj.SetTimeFrame()
            -- refresh the entry list
            tj.UpdateEntryList()
            d:debug("Time setting changed to: "..tostring(TurtleJournal_Settings.time))
        end)
        timeCheckbox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Toggle time and date display")
            GameTooltip:Show()
        end)
        timeCheckbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        local centeringCheckbox = CreateFrame("CheckButton", "TJCenteringCheckbox", bottomOptionFrame2, "UICheckButtonTemplate")
        centeringCheckbox:SetPoint("TOP", timeCheckbox, "BOTTOM", 0, 0)
        centeringCheckbox:SetWidth(20)
        centeringCheckbox:SetHeight(20)
        getglobal(centeringCheckbox:GetName().."Text"):SetText("Center")
        centeringCheckbox:SetChecked(TurtleJournal_Settings.centerText)
        centeringCheckbox:SetScript("OnClick", function()
            TurtleJournal_Settings.centerText = (this:GetChecked() == 1)
            if TurtleJournal_Settings.centerText then
                editBox:SetJustifyH("CENTER")
            else
                editBox:SetJustifyH("LEFT")
            end
            d:debug("Center setting changed to: "..tostring(TurtleJournal_Settings.centerText))
        end)
        centeringCheckbox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Toggle text centering in journal entries")
            GameTooltip:Show()
        end)
        centeringCheckbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        local nameButton = CreateFrame("Button", nil, bottomOptionFrame2, "UIPanelButtonTemplate")
        nameButton:SetWidth(59)
        nameButton:SetHeight(15)
        nameButton:SetPoint("TOPLEFT", centeringCheckbox, "BOTTOMLEFT", -10, -5)
        nameButton:SetText("Name")
        nameButton:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        nameButton:SetScript("OnClick", function()
            tj.SetName()
        end)
        nameButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText("Set custom journal name")
            GameTooltip:Show()
        end)
        nameButton:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        --==================================================
        -- MISCELLANEOUS
        --==================================================
        local versionText = bottomOptionFrame2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        versionText:SetPoint("BOTTOMRIGHT", bottomOptionFrame2, "BOTTOMRIGHT", -25, 19)
        versionText:SetText("Version: |cffff6060" .. tj.addonInfo.version.."|r")
        versionText:SetTextColor(1, 1, 1, 1)
        versionText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")

        -- store frames reference
        tj.frames = {
            main = mainFrame,
            frameTex = frameTex,
            editBox = editBox,
            titleEditBox = titleEditBox,
            sideEntryList = sideEntryList,
            leftScrollFrame = leftScrollFrame,
            editboxScrollChild = editboxScrollChild,
            miniScrollPanel = miniScrollPanel,
            bottomOptionFrame = bottomOptionFrame,
            bottomOptionFrame2 = bottomOptionFrame2,
            optionsButton = optionsButton,
            entryButton = entryButton,
            closeButton = closeButton,
            newButton = newButton,
            saveButton = saveButton,
            deleteButton = deleteButton,
            saveDbButton = saveDbButton,
            titleText = titleText,
        }

        -- setup scaling
        tj.SetupMainFrameOpener()
        tj.SetupFrameControls()
        tj.SetTimeFrame()
        tj.SetBottomFrameColor()


        tj.frames.main:Hide()
    end

    tj:CreateGUI()
end)
