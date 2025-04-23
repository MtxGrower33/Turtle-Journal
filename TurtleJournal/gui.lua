-- --==================================================
-- -- gui
-- --==================================================

local TJ = TurtleJournal
TJ.debug("booting...")

function TJ.CreateFrames()
    -- mainframe
    local mainFrame = CreateFrame("Frame", "TurtleJournalFrame", UIParent)
    mainFrame:SetPoint("CENTER", 0, 0)
    mainFrame:SetWidth(500)
    mainFrame:SetHeight(500)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetToplevel(true)
    mainFrame:SetFrameLevel(5)
    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function() this:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

    local bgTexture = mainFrame:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetTexture("Interface\\AddOns\\TurtleJournal\\media\\tj_skin1.tga")
    bgTexture:SetAllPoints(mainFrame)
    -- bgTexture:SetVertexColor(0.8, 0.8, 0.8, 0.4) -- will keep this for later

    tinsert(UISpecialFrames, mainFrame:GetName())

    -- title editbox
    local titleBox = CreateFrame("EditBox", "TurtleJournalTitleBox", mainFrame)
    titleBox:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 100, -100)
    titleBox:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -100, -10)
    titleBox:SetHeight(40)
    titleBox:SetAutoFocus(false)
    titleBox:SetMaxLetters(20)
    titleBox:SetTextInsets(5, 5, 0, 0)
    titleBox:SetFont("Interface\\AddOns\\TurtleJournal\\media\\GreatVibes-Regular.ttf", 35, "")
    titleBox:SetTextColor(0.01, 0.01, 0.01, 1)
    titleBox:SetJustifyH("CENTER")

    titleBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    titleBox:SetScript("OnEnterPressed", function() TJ.frames.editBox:SetFocus() end)

    titleBox:SetScript("OnTabPressed", function ()
        if TJ.frames.editBox:IsVisible() then
            TJ.frames.editBox:SetFocus()
        else
            TJ.frames.titleBox:SetFocus()
        end
    end)

    -- main content editbox
    -- workaround for missing max line feature for editboxes
    -- keep our text inside our area no matter what
    local function CountLinesAndLastLength(text)
        local lines = 1
        local lastLineStart = 1
        local pos = string.find(text, "\n", 1)  -- initialize pos with first find result

        while pos do
            lines = lines + 1
            lastLineStart = pos + 1
            pos = string.find(text, "\n", pos + 1)  -- find next occurrence
        end

        -- get length of last line
        local lastLine = string.sub(text, lastLineStart)
        return lines, string.len(lastLine)
    end

    local editBox = CreateFrame("EditBox", "TurtleJournalContentBox", mainFrame)
    editBox:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 80, -140)
    editBox:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -80, 70)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(700)
    editBox:SetJustifyH("CENTER")
    editBox:SetTextInsets(10, 10, 10, 10)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    editBox:SetTextColor(0.01, 0.01, 0.01, 1)
    editBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)

    -- focus track for sound system
    editBox.isFocused = false

    editBox:SetScript("OnEditFocusGained", function()
        this.isFocused = true
    end)

    editBox:SetScript("OnEditFocusLost", function()
        this.isFocused = false
    end)

    editBox:SetScript("OnTextChanged", function()
        if this.isFocused then
            local text = this:GetText()
            local lines, lastLineLength = CountLinesAndLastLength(text)

            local maxLines = 15
            local maxCharsPerLine = 37

            if lines > maxLines or (lines == maxLines and lastLineLength >= maxCharsPerLine) then
                -- remove the last entered character or line break
                local newText = string.sub(text, 1, -2)
                this:SetText(newText)
            end

            TJ.debug("Text changed")
            TJ.StartTyping()
        end
    end)

    -- entry list frame (left side)
    local entryList = CreateFrame("ScrollFrame", "TJEntryList", mainFrame)
    entryList:SetPoint("LEFT", mainFrame, "LEFT", 50, -50)
    entryList:SetWidth(250)
    entryList:SetHeight(340)
    entryList:SetFrameStrata("DIALOG")
    entryList:SetFrameLevel(1)
    entryList:EnableMouse(true)
    entryList:EnableMouseWheel(true)
    entryList:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    entryList:SetScript("OnMouseWheel", function()
        local scrollStep = 10
        if arg1 > 0 then
            entryList:SetVerticalScroll(math.max(0, entryList:GetVerticalScroll() - scrollStep))
        else
            local maxScroll = entryList:GetVerticalScrollRange()
            entryList:SetVerticalScroll(math.min(maxScroll, entryList:GetVerticalScroll() + scrollStep))
        end
    end)
    entryList:Hide()

    local entryListContent = CreateFrame("Frame", nil, entryList)
    entryListContent:SetWidth(240)
    entryListContent:SetHeight(340)
    entryList:SetScrollChild(entryListContent)

    -- options panel frame (bot side)
    local optionsPanel = CreateFrame("Frame", "TJOptionsPanel", mainFrame)
    optionsPanel:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 15)
    optionsPanel:SetWidth(300)
    optionsPanel:SetHeight(90)
    optionsPanel:EnableMouse(true)
    optionsPanel:SetFrameStrata("DIALOG")
    optionsPanel:SetFrameLevel(1)
    optionsPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    optionsPanel:SetBackdropColor(0, 0, 0, 1)
    optionsPanel:Hide()

    --==================================================
    -- button section
    --==================================================

    -- slide-out-editframe button
    local visibleE = false
    local slideButton = CreateFrame("Button", "TJSlideButton", mainFrame, "UIPanelButtonTemplate")
    slideButton:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 100, 30)
    slideButton:SetWidth(15)
    slideButton:SetHeight(15)
    slideButton:SetText("<")
    slideButton:SetScript("OnClick", function()
        if visibleE then
            TJ.MoveFrame(entryList, "right", 250, 0.2, "hide")
            slideButton:SetText("<")
            visibleE = false
        else
            entryList:Show()
            TJ.MoveFrame(entryList, "left", 250, 0.2)
            slideButton:SetText(">")
            visibleE = true
        end
        TJ.debug("Slide button clicked")
    end)
    slideButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Toggle entry panel")
        GameTooltip:Show()
    end)
    slideButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- save button
    local savebtn = CreateFrame("Button", "TJButton1", mainFrame, "UIPanelButtonTemplate")
    savebtn:SetPoint("LEFT", slideButton, "RIGHT", 25, 0)
    savebtn:SetWidth(70)
    savebtn:SetHeight(20)
    savebtn:SetText("Save")
    savebtn:SetScript("OnClick", function()
        TJ.SaveEntry()
    end)
    savebtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Save current entry")
        GameTooltip:Show()
    end)
    savebtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- delete button
    local deletebtn = CreateFrame("Button", "TJButton3", mainFrame, "UIPanelButtonTemplate")
    deletebtn:SetPoint("LEFT", savebtn, "RIGHT", 10, 0)
    deletebtn:SetWidth(70)
    deletebtn:SetHeight(20)
    deletebtn:SetText("Delete")
    deletebtn:SetScript("OnClick", function()
        TJ.DeleteEntry()
    end)
    deletebtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Delete selected entry")
        GameTooltip:Show()
    end)
    deletebtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- save database button
    local saveDBbtn = CreateFrame("Button", "TJButton2", mainFrame, "UIPanelButtonTemplate")
    saveDBbtn:SetPoint("LEFT", deletebtn, "RIGHT", 10, 0)
    saveDBbtn:SetWidth(70)
    saveDBbtn:SetHeight(20)
    saveDBbtn:SetText("Save DB")
    saveDBbtn:SetScript("OnClick", function()
        ReloadUI()
    end)
    saveDBbtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Save database and reload UI")
        GameTooltip:Show()
    end)
    saveDBbtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- options menu button
    local visibleO = false
    local optionsbtn = CreateFrame("Button", "TJButton4", mainFrame, "UIPanelButtonTemplate")
    optionsbtn:SetPoint("LEFT", saveDBbtn, "RIGHT", 25, 0)
    optionsbtn:SetWidth(15)
    optionsbtn:SetHeight(15)
    optionsbtn:SetText("*")
    optionsbtn:SetScript("OnClick", function()
        if visibleO then
            TJ.MoveFrame(optionsPanel, "up", 70, 0.1, "hide")
            visibleO = false
        else
            optionsPanel:Show()
            TJ.MoveFrame(optionsPanel, "down", 70, 0.1)
            visibleO = true
        end
        TJ.debug("Options button clicked")
    end)
    optionsbtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Toggle options panel")
        GameTooltip:Show()
    end)
    optionsbtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- checkbox for sound
    local soundCheckbox = CreateFrame("CheckButton", "TJSoundCheckbox", optionsPanel, "UICheckButtonTemplate")
    soundCheckbox:SetPoint("LEFT", optionsPanel, "LEFT", 15, 0)
    soundCheckbox:SetWidth(20)
    soundCheckbox:SetHeight(20)
    getglobal(soundCheckbox:GetName().."Text"):SetText("Enable Sound")
    soundCheckbox:SetChecked(TurtleJournal_Settings.sound)
    soundCheckbox:SetScript("OnClick", function()
        TurtleJournal_Settings.sound = (this:GetChecked() == 1)
        TJ.debug("Sound setting changed to: "..tostring(TurtleJournal_Settings.sound))
    end)

    -- checkbox for sit
    local sitCheckbox = CreateFrame("CheckButton", "TJSitCheckbox", optionsPanel, "UICheckButtonTemplate")
    sitCheckbox:SetPoint("LEFT", soundCheckbox, "RIGHT", 80, 0)
    sitCheckbox:SetWidth(20)
    sitCheckbox:SetHeight(20)
    getglobal(sitCheckbox:GetName().."Text"):SetText("Auto Sit")
    sitCheckbox:SetChecked(TurtleJournal_Settings.sit)
    sitCheckbox:SetScript("OnClick", function()
        TurtleJournal_Settings.sit = (this:GetChecked() == 1)
        TJ.debug("Sit setting changed to: "..tostring(TurtleJournal_Settings.sit))
    end)

    -- close button
    local closebtn = CreateFrame("Button", "TJButton4", mainFrame, "UIPanelCloseButton")
    closebtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -65, -95)
    closebtn:SetWidth(25)
    closebtn:SetHeight(25)
    closebtn:SetScript("OnClick", function()
        mainFrame:Hide()
        TJ.SwooshSound()
        TJ.DoEmote("STAND")
        TJ.debug("closebtn clicked")
    end)

    --==================================================
    -- end section
    --==================================================

    -- versiontext
    local versionText = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionText:SetPoint("BOTTOM", optionsPanel, "BOTTOM", 0, 19)
    versionText:SetText("Version: |cffff6060" .. TJ.addonInfo.version.."|r")
    versionText:SetTextColor(0.8, 0.8, 0.8, 1)
    versionText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")

    -- store frames reference
    TJ.frames = {
        main = mainFrame,
        editBox = editBox,
        titleBox = titleBox,
        entryList = entryList,
        entryListContent = entryListContent,
        slideButton = slideButton,
        savebtn = savebtn,
        saveDBbtn = saveDBbtn,
        deletebtn = deletebtn,
        optionsPanel = optionsPanel,
        soundCheckbox = soundCheckbox,
        sitCheckbox = sitCheckbox,
        optionsbtn = optionsbtn,
    }

    -- setup scaling
    TJ.SetupFrameControls()

    -- hide by default
    TJ.frames.main:Hide()
end

function TJ.UpdateEntryList()
    local allEntries = {}

    -- gather all entries from all dates
    for date, dateEntries in pairs(TurtleJournal_DB) do
        for id, entry in pairs(dateEntries) do
            -- add to our consolidated list with a compound ID to keep entries unique
            local compoundId = date .. "_" .. id
            allEntries[compoundId] = {
                title = entry.title,
                dateStr = date,
                originalId = id
            }
        end
    end

    -- clear existing entries
    if TJ.frames.entryList.buttons then
        for _, button in pairs(TJ.frames.entryList.buttons) do
            button:Hide()
        end
    end

    -- if no entries, we're done
    if not next(allEntries) then
        TJ.frames.entryList.buttons = {}
        return
    end

    TJ.frames.entryList.buttons = TJ.frames.entryList.buttons or {}

    local buttonHeight = 25
    local offset = 15

    for compoundId, entry in pairs(allEntries) do
        local button = TJ.frames.entryList.buttons[compoundId] or
            CreateFrame("Button", "TJEntryButton"..compoundId, TJ.frames.entryListContent)

        button:SetPoint("TOP", TJ.frames.entryListContent, "TOP", 0, -offset)
        button:SetWidth(220)
        button:SetHeight(buttonHeight)
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        if not button.text then
            button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            button.text:SetPoint("CENTER", 0, 0)
            button.text:SetWidth(200)
        end
        -- add date to the display text
        button.text:SetText(entry.dateStr .. ": " .. entry.title)
        button:Show()

        button.entryData = {
            dateStr = entry.dateStr,
            id = tostring(entry.originalId)
        }

        -- track clicks for double-click detection
        button.lastClickTime = 0

        button:SetScript("OnClick", function()
            local data = this.entryData
            local currentTime = GetTime()
            local timeSinceLastClick = currentTime - this.lastClickTime

            -- double click (if clicks are within 0.4 seconds)
            if timeSinceLastClick < 0.4 then
                TJ.DisplayEntry(data.dateStr, data.id)
                TJ.debug("Double clicked on entry #" .. data.id .. " on " .. data.dateStr)
            else -- single click
                if TJ.selectedButton then
                    TJ.selectedButton:UnlockHighlight()
                end
                -- mark this button
                this:LockHighlight()
                TJ.selectedButton = this
                TJ.selectedEntry = data -- store selected entry data
                TJ.debug("Selected entry #" .. data.id .. " on " .. data.dateStr)
            end

            this.lastClickTime = currentTime
        end)

        TJ.frames.entryList.buttons[compoundId] = button
        offset = offset + buttonHeight + 2
    end

    TJ.frames.entryListContent:SetHeight(math.max(380, offset))
end

function TJ.DisplayEntry(dateStr, entryId)
    local entry = TJ.SelectEntry(dateStr, entryId)
    if not entry then return end

    TJ.frames.editBox:SetText(entry.content)
    TJ.frames.titleBox:SetText(entry.title)
end
