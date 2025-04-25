--==================================================
-- SETTINGS
--==================================================
local d = {
    enabled = false,
    count = 0,
    timeTracker = {},
    colors = {
        red = "|cffff6060",
        green = "|cff88ff88",
    },
}

--==================================================
-- DEBUGTOOLS
--==================================================
function d:print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88[ Journal ]|r: " .. (msg or "nil"))
end

function d:debug(msg)
    if not self.enabled then return end

    self.count = self.count + 1
    local stack = debugstack(2, 1, 0)
    local start, finish = string.find(stack, "[^\\/:]+%.lua")
    local file = start and string.sub(stack, start, finish) or "unknown"
    DEFAULT_CHAT_FRAME:AddMessage("|cffff6060[ Debug ]|r:[ " .. self.count .. " ][|cff00ff00" .. file .. "|r]: " .. (msg or "nil"))
    -- print(debugstack(2, 3, 0)) -- can be enabled if needed
end

function d:dumpTable(t)
    if not self.enabled then return end
    if not t then return end

    local function dumpTableRecursive(t, visited, level)
        local indent = ">"
        local currentIndent = string.rep(indent, level)

        if visited[t] then
            self:debug(currentIndent .. "<circular reference>")
            return
        end
        visited[t] = true

        -- collect all keys
        local keys = {}
        for k in pairs(t) do
            table.insert(keys, k)
        end

        -- simpler sort - just convert everything to string
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)

        -- print sorted table
        for _, k in ipairs(keys) do
            local v = t[k]
            if type(v) == "table" and not visited[v] then
                self:debug(currentIndent .. "|cffff6060" .. tostring(k) .. ":|r")
                dumpTableRecursive(v, visited, level + 1)
            else
                self:debug(currentIndent .. "|cffff6060" .. tostring(k) .. ":|r " .. tostring(v))
            end
        end
    end

    dumpTableRecursive(t, {}, 0)
end

function d:checkGlobal(varName)
    if type(varName) ~= "string" then
        self:debug("checkGlobal requires a string parameter")
        return false
    end

    local globals = getfenv(0)
    local exists = globals[varName] ~= nil

    if exists then
        self:debug("Global var |cffff6060[|r " .. varName .. " |cffff6060]|r |cff88ff88exists")
    else
        self:debug("Global var |cffff6060[|r " .. varName .. " |cffff6060]|r |cffff6060does not exist")
    end

    return exists
end

function d:watchVar(value, name, interval)
    if not self.enabled then return end

    interval = interval or 0.1
    local lastValue = value()
    local f = CreateFrame("Frame")
    local lastCheck = 0

    f:SetScript("OnUpdate", function()
        if GetTime() - lastCheck > interval then
            local current = value()
            if current ~= lastValue then
                self:debug(string.format("%s:|cffff6060 %s |r->|cffff6060 %s |r",
                    name, tostring(lastValue), tostring(current)))
                lastValue = current
            end
            lastCheck = GetTime()
        end
    end)
    return f
end

function d:drawRedFrame(frame)
    if not self.enabled then return end
    if not frame then return end

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
end

function d:printFrameInfo(frame)
    if not self.enabled then return end
    if not frame then return end

    self:debug("Frame: |cffff6060" .. (frame:GetName() or "unnamed"))
    self:debug("Size: |cffff6060W:" .. frame:GetWidth() .. " H:" .. frame:GetHeight())
    self:debug("Position: |cffff6060X:" .. frame:GetLeft() .. " Y:" .. frame:GetTop())
    self:debug("Visible: |cffff6060" .. tostring(frame:IsVisible()))
    self:debug("Level: |cffff6060" .. frame:GetFrameLevel())
    self:debug("Strata: |cffff6060" .. frame:GetFrameStrata())
end

function d:printFrameTextures(frame)
    if not frame then return end

    -- Print the frame's name first
    local frameName = frame:GetName() or "unnamed frame"
    DEFAULT_CHAT_FRAME:AddMessage("Textures for " .. frameName .. ":")

    local textureCount = 0

    -- Get all regions of the frame (returns multiple values, not a table)
    local regions = {frame:GetRegions()}

    -- Loop through all regions
    for _, region in ipairs(regions) do
        if region and region:IsObjectType("Texture") then
            textureCount = textureCount + 1
            local textureName = region:GetName() or "unnamed texture"
            local texturePath = region:GetTexture() or "no path"
            DEFAULT_CHAT_FRAME:AddMessage("  " .. textureCount .. ". Name: " .. textureName .. ", Path: " .. texturePath)
        end
    end

    if textureCount == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("  No textures found")
    end
end

function d:getTextureSize(texturePath)
    local texture = CreateFrame("Frame"):CreateTexture()
    texture:SetTexture(texturePath)
    local width = texture:GetWidth()
    local height = texture:GetHeight()
    DEFAULT_CHAT_FRAME:AddMessage(width .. " x " .. height)
end

function d:showFrameStack()
    if not self.enabled then return end

    local stack = debugstack()
    self:debug("Frame Stack:")
    ---@diagnostic disable-next-line: undefined-field
    for line in string.gfind(stack, "[^\n]+") do
        self:debug("-|cffff6060" .. line .. "|r")
    end
end

function d:createEventLogger(event)
    if not self.enabled then return end

    local f = CreateFrame("Frame")
    f:RegisterEvent(event)

    f:SetScript("OnEvent", function()
        local argString = ""
        if arg1 then argString = argString .. tostring(arg1) .. ", " end
        if arg2 then argString = argString .. tostring(arg2) .. ", " end
        if arg3 then argString = argString .. tostring(arg3) .. ", " end
        if arg4 then argString = argString .. tostring(arg4) .. ", " end
        if arg5 then argString = argString .. tostring(arg5) .. ", " end
        self:debug("Event: |cffff6060" .. event .. "|r Args: |cffff6060" .. argString)
    end)
    return f
end

function d:createMouseTracker()
    if not self.enabled then return end

    local f = CreateFrame("Frame")
    local lastTick
    f:SetScript("OnUpdate", function()
        if GetTime() - (lastTick or 0) > 2 then
            lastTick = GetTime()
            local x, y = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            DEFAULT_CHAT_FRAME:AddMessage(string.format("Mouse Pos:|cffff6060 X: %.2f, Y: %.2f",
                x/scale, y/scale
            ))
        end
    end)
    return f
end

function d:timer(name)
    if not self.enabled then return end
    if self.timeTracker[name] then
        local elapsed = GetTime() - self.timeTracker[name]
        self:debug(name .. " took |cffff6060" .. elapsed .. "|r seconds")
        self.timeTracker[name] = nil
    else
        self.timeTracker[name] = GetTime()
    end
end

function d:profile(func, iterations)
    if not self.enabled then return end

    iterations = iterations or 1
    local start = GetTime()
    for i = 1, iterations do
        func()
    end
    local elapsed = GetTime() - start
    self:debug(string.format("Function took|cffff6060 %.4f |rseconds (avg|cffff6060 %.4f |rper call)",
        elapsed, elapsed/iterations))
end

-- -- some usage examples when im high and forget:
-- d:print("test")
-- d:debug("test")
-- d:dumpTable({a = 1, b = 2})
-- d:watchVar(function() return UnitHealth("player") end, "Player Health")
-- d:drawRedFrame(PlayerFrame)
-- d:printFrameInfo(PlayerFrame)
-- d:printFrameTextures(MerchantFrame)
-- d:getTextureSize("Interface\\QuestFrame\\UI-QuestLog-Left")
-- d:showFrameStack()
-- d:createEventLogger("PLAYER_ENTERING_WORLD")
-- d:createMouseTracker()
-- d:timer("test") -- must be called twice start/end
-- d:profile(function() return UnitHealth("player") end, 1000)

--==================================================
-- MAINFRAME
--==================================================
-- we setup mainframe here so that we dont expose 2 globals for our
-- debugtools while running debug.lua first. creating mainframe in init.lua
-- would "force" us to create another global for debugtools.
TurtleJournal = CreateFrame("Frame", nil, UIParent)
TurtleJournal.dt = d -- add debugtools to namespace

d:debug("debugtools ready...")