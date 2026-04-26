---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme or {}

local ipairs = ipairs
local pairs = pairs
local CreateFrame = CreateFrame
local wipe = wipe

NRSKNUI.GUI = NRSKNUI.GUI or {}
NRSKNUI.GUI.DungeonTimers = NRSKNUI.GUI.DungeonTimers or {}

local settingsPreviewTextFrames = {}

local SETTINGS_TEXT_PREVIEWS = {
    { name = "Adds", time = 14.3, icon = 136116, color = { 1.0, 0.5, 0.2 } },
    { name = "Heal", time = 6.9,  icon = 135915, color = { 0.4, 0.8, 1.0 } },
    { name = "Kick", time = 2.1,  icon = 132219, color = { 0.9, 0.3, 0.9 } },
}

local SETTINGS_GROWTH_OPTIONS = {
    { key = "DOWN", text = "Down" },
    { key = "UP",   text = "Up" },
}

local SETTINGS_TEXT_OUTLINE_OPTIONS = {
    { key = "NONE",         text = "None" },
    { key = "OUTLINE",      text = "Outline" },
    { key = "THICKOUTLINE", text = "Thick" },
    { key = "SOFTOUTLINE",  text = "Soft" },
}

local SETTINGS_TEXT_ALIGN_OPTIONS = {
    { key = "LEFT",   text = "Left" },
    { key = "CENTER", text = "Center" },
    { key = "RIGHT",  text = "Right" },
}

local function GetSettingsDB()
    if not NRSKNUI.db or not NRSKNUI.db.profile then return nil end
    return NRSKNUI.db.profile.DungeonTimers
end

local function GetModule()
    if NorskenUI then
        return NorskenUI:GetModule("DungeonTimers", true)
    end
    return nil
end

local function ApplySettingsChanges()
    local mod = GetModule()
    if mod then
        if mod.Refresh then mod:Refresh() end
        if mod.ApplySettings then mod:ApplySettings() end
    end
end

local function CreateSettingsTextPreview(index, data)
    local db = GetSettingsDB()
    if not db then return nil end

    if not db.TextDisplay then db.TextDisplay = {} end

    local fontSize = db.TextDisplay.fontSize or 14
    local fontOutline = db.TextDisplay.fontOutline or "SOFTOUTLINE"
    local textAlign = db.TextDisplay.textAlign or "LEFT"
    local fontFace = db.TextDisplay.fontFace or "Expressway"
    local showIcon = false
    local iconSize = 0
    local lineHeight = fontSize + 6

    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("HIGH")
    frame:SetSize(200, lineHeight)
    settingsPreviewTextFrames[index] = frame

    frame.iconFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.iconFrame:SetSize(fontSize + 2, fontSize + 2)
    frame.iconFrame:SetPoint("LEFT", 0, 0)
    frame.iconFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame.iconFrame:SetBackdropBorderColor(0, 0, 0, 1)
    frame.iconFrame:SetShown(showIcon)

    frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 1, -1)
    frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.icon:SetTexture(data.icon)
    if NRSKNUI.ApplyZoom then NRSKNUI:ApplyZoom(frame.icon, 0.1) end

    local textWidth = 200 - iconSize - 4
    frame.displayText = frame:CreateFontString(nil, "OVERLAY")
    frame.displayText:SetJustifyH(textAlign)
    frame.displayText:SetPoint("LEFT", frame, "LEFT", iconSize + 4, 0)
    NRSKNUI:ApplyFontToText(frame.displayText, fontFace, fontSize, fontOutline)
    frame.displayText:SetWidth(textWidth)
    local textColor = data.color or { 1, 1, 1 }
    frame.displayText:SetTextColor(textColor[1], textColor[2], textColor[3], 1)
    frame.displayText:SetText(string.format("%s » %.1f", data.name, data.time))

    return frame
end

local function HideTextPreviews()
    for _, frame in pairs(settingsPreviewTextFrames) do
        if frame.displayText and frame.displayText._nrsknSoftOutline then
            frame.displayText._nrsknSoftOutline:Release()
        end
        frame:Hide()
    end
    wipe(settingsPreviewTextFrames)
end

local function ShowSettingsTextPreviews()
    HideTextPreviews()

    if not GUIFrame or not GUIFrame:IsShown() then return end
    if GUIFrame.selectedSidebarItem ~= "DT_Texts" then return end

    local db = GetSettingsDB()
    if not db then return end

    local fontSize = db.TextDisplay.fontSize or 14
    local textLineHeight = fontSize + 6
    local textPos = db.TextGroup.Position or {}
    local textGrowth = db.TextGroup.GrowthDirection or "DOWN"
    local textSpacing = db.TextGroup.Spacing or 2
    local textGrowUp = textGrowth == "UP"

    for i, data in ipairs(SETTINGS_TEXT_PREVIEWS) do
        local frame = CreateSettingsTextPreview(i, data)
        if frame then
            frame:ClearAllPoints()
            local offset = (i - 1) * (textLineHeight + textSpacing)
            if textGrowUp then
                frame:SetPoint(textPos.AnchorFrom or "CENTER", UIParent, textPos.AnchorTo or "CENTER",
                    textPos.XOffset or 0, (textPos.YOffset or -100) + offset)
            else
                frame:SetPoint(textPos.AnchorFrom or "CENTER", UIParent, textPos.AnchorTo or "CENTER",
                    textPos.XOffset or 0, (textPos.YOffset or -100) - offset)
            end
            frame:Show()
        end
    end
end

NRSKNUI.GUI.DungeonTimers.HideTextPreviews = HideTextPreviews
GUIFrame.onCloseCallbacks["DT_Texts"] = HideTextPreviews

GUIFrame:RegisterContent("DT_Texts", function(scrollChild, yOffset)
    local DT_GUI = NRSKNUI.GUI.DungeonTimers
    if DT_GUI.HideBarPreviews then DT_GUI.HideBarPreviews() end

    local db = GetSettingsDB()
    if not db then return yOffset end

    if not db.TextDisplay then db.TextDisplay = {} end

    local isModuleDisabled = db.Enabled == false
    local manager = GUIFrame:CreateWidgetStateManager()

    local LSM = NRSKNUI.LSM
    local fontList = {}
    if LSM then
        for name in pairs(LSM:HashTable("font")) do
            fontList[name] = name
        end
    else
        fontList["Expressway"] = "Expressway"
    end

    local function ApplyAndUpdate()
        ApplySettingsChanges()
        ShowSettingsTextPreviews()
    end

    ShowSettingsTextPreviews()

    local displayCard = GUIFrame:CreateCard(scrollChild, "Text Display Settings", yOffset)
    manager:Register(displayCard, "all")

    local row1 = GUIFrame:CreateRow(displayCard.content, Theme.rowHeight)
    local fontDropdown = GUIFrame:CreateDropdown(row1, "Font", {
        options = fontList,
        value = db.TextDisplay.fontFace or "Expressway",
        callback = function(key)
            db.TextDisplay.fontFace = key
            ApplyAndUpdate()
        end,
        searchable = true,
        isFontPreview = true
    })
    row1:AddWidget(fontDropdown, 0.5)

    local fontSizeSlider = GUIFrame:CreateSlider(row1, "Font Size", {
        min = 8,
        max = 32,
        step = 1,
        value = db.TextDisplay.fontSize or 14,
        labelWidth = 60,
        callback = function(val)
            db.TextDisplay.fontSize = val
            ApplyAndUpdate()
        end
    })
    row1:AddWidget(fontSizeSlider, 0.5)
    displayCard:AddRow(row1, Theme.rowHeight)

    local row2 = GUIFrame:CreateRow(displayCard.content, Theme.rowHeightLast)
    local outlineDropdown = GUIFrame:CreateDropdown(row2, "Font Outline", {
        options = SETTINGS_TEXT_OUTLINE_OPTIONS,
        value = db.TextDisplay.fontOutline or "SOFTOUTLINE",
        callback = function(key)
            db.TextDisplay.fontOutline = key
            ApplyAndUpdate()
        end
    })
    row2:AddWidget(outlineDropdown, 0.5)

    local alignDropdown = GUIFrame:CreateDropdown(row2, "Text Align", {
        options = SETTINGS_TEXT_ALIGN_OPTIONS,
        value = db.TextDisplay.textAlign or "LEFT",
        callback = function(key)
            local freshDb = GetSettingsDB()
            if freshDb and freshDb.TextDisplay then
                freshDb.TextDisplay.textAlign = key
            end
            ApplyAndUpdate()
        end
    })
    row2:AddWidget(alignDropdown, 0.5)
    displayCard:AddRow(row2, Theme.rowHeightLast, 0)

    yOffset = displayCard:GetNextOffset()

    local textGroupCard = GUIFrame:CreateCard(scrollChild, "Text Group", yOffset)
    manager:Register(textGroupCard, "all")

    local textRow1 = GUIFrame:CreateRow(textGroupCard.content, Theme.rowHeightLast)
    local textGrowthDropdown = GUIFrame:CreateDropdown(textRow1, "Growth Direction", {
        options = SETTINGS_GROWTH_OPTIONS,
        value = db.TextGroup.GrowthDirection or "DOWN",
        callback = function(key)
            db.TextGroup.GrowthDirection = key
            ApplyAndUpdate()
        end
    })
    textRow1:AddWidget(textGrowthDropdown, 0.5)

    local textSpacingSlider = GUIFrame:CreateSlider(textRow1, "Spacing", {
        min = 0,
        max = 20,
        step = 1,
        value = db.TextGroup.Spacing or 2,
        labelWidth = 50,
        callback = function(val)
            db.TextGroup.Spacing = val
            ApplyAndUpdate()
        end
    })
    textRow1:AddWidget(textSpacingSlider, 0.5)
    textGroupCard:AddRow(textRow1, Theme.rowHeightLast, 0)

    yOffset = textGroupCard:GetNextOffset()

    local textPosCard, textPosYOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        title = "Text Group Position",
        db = db.TextGroup.Position,
        defaults = {
            xOffset = 0,
            yOffset = -100,
            selfPoint = "CENTER",
            anchorPoint = "CENTER",
        },
        showAnchorFrameType = false,
        showStrata = false,
        sliderRange = { -800, 800 },
        onChangeCallback = ApplyAndUpdate,
    })
    manager:Register(textPosCard, "all")
    yOffset = textPosYOffset

    manager:UpdateAll(not isModuleDisabled)

    return yOffset
end)
