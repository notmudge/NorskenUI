---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme or {}

local table_insert = table.insert
local ipairs = ipairs
local pairs = pairs
local CreateFrame = CreateFrame

NRSKNUI.GUI = NRSKNUI.GUI or {}
NRSKNUI.GUI.DungeonTimers = NRSKNUI.GUI.DungeonTimers or {}

local settingsPreviewBarFrames = {}

local SETTINGS_BAR_PREVIEWS = {
    { name = "Tank Hit", time = 12.4, icon = 136116, color = { 0.2, 0.6, 1.0 } },
    { name = "Soak",     time = 8.7,  icon = 135994, color = { 1.0, 0.5, 0.0 } },
    { name = "Frontal",  time = 5.2,  icon = 132155, color = { 1.0, 0.2, 0.2 } },
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

local function CreateSettingsBarPreview(index, data)
    local db = GetSettingsDB()
    if not db then return nil end

    local barWidth = db.BarDisplay.barWidth or 200
    local barHeight = db.BarDisplay.barHeight or 20
    local fontSize = db.BarDisplay.fontSize or 12
    local fontOutline = db.BarDisplay.fontOutline or "OUTLINE"
    local fontFace = db.BarDisplay.fontFace or "Expressway"
    local barTexture = db.BarDisplay.barTexture or "NorskenUI"
    local showIcon = db.BarDisplay.iconEnabled ~= false
    local texturePath = NRSKNUI:GetStatusbarPath(barTexture) or "Interface\\Buttons\\WHITE8x8"
    local iconSize = showIcon and barHeight or 0

    local frame = settingsPreviewBarFrames[index]
    if not frame then
        frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        frame:SetFrameStrata("HIGH")
        settingsPreviewBarFrames[index] = frame

        frame.barContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.bar = CreateFrame("StatusBar", nil, frame.barContainer)
        frame.bar:SetPoint("TOPLEFT", 1, -1)
        frame.bar:SetPoint("BOTTOMRIGHT", -1, 1)

        frame.iconFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.iconFrame:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame.iconFrame:SetBackdropBorderColor(0, 0, 0, 1)
        frame.iconFrame.bg = frame.iconFrame:CreateTexture(nil, "BACKGROUND")
        frame.iconFrame.bg:SetAllPoints()
        frame.iconFrame.bg:SetColorTexture(0, 0, 0, 1)
        frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetPoint("TOPLEFT", 1, -1)
        frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        if NRSKNUI.ApplyZoom then NRSKNUI:ApplyZoom(frame.icon, 0.1) end

        frame.text1 = frame.bar:CreateFontString(nil, "OVERLAY")
        frame.text2 = frame.bar:CreateFontString(nil, "OVERLAY")
    end

    frame:SetSize(barWidth, barHeight)
    frame.iconFrame:SetSize(barHeight, barHeight)
    frame.iconFrame:ClearAllPoints()
    frame.iconFrame:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.iconFrame:SetShown(showIcon)
    frame.icon:SetTexture(data.icon)

    frame.barContainer:ClearAllPoints()
    frame.barContainer:SetPoint("TOPLEFT", iconSize, 0)
    frame.barContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.barContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.barContainer:SetBackdropColor(0, 0, 0, 0.8)
    frame.barContainer:SetBackdropBorderColor(0, 0, 0, 1)

    frame.bar:SetStatusBarTexture(texturePath)
    local barColor = data.color or { 0.2, 0.6, 1.0 }
    frame.bar:SetStatusBarColor(barColor[1], barColor[2], barColor[3], 1)
    frame.bar:SetMinMaxValues(0, 20)
    frame.bar:SetValue(data.time)

    frame.text1:ClearAllPoints()
    frame.text1:SetPoint("LEFT", frame.bar, "LEFT", 4, 0)
    frame.text1:SetJustifyH("LEFT")
    NRSKNUI:ApplyFontToText(frame.text1, fontFace, fontSize, fontOutline)
    frame.text1:SetTextColor(1, 1, 1, 1)
    frame.text1:SetText(data.name)

    frame.text2:ClearAllPoints()
    frame.text2:SetPoint("RIGHT", frame.bar, "RIGHT", -4, 0)
    frame.text2:SetJustifyH("RIGHT")
    NRSKNUI:ApplyFontToText(frame.text2, fontFace, fontSize, fontOutline)
    frame.text2:SetTextColor(1, 1, 1, 1)
    frame.text2:SetText(string.format("%.1f", data.time))

    return frame
end

local function HideBarPreviews()
    for _, frame in pairs(settingsPreviewBarFrames) do
        frame:Hide()
    end
end

local function ShowSettingsBarPreviews()
    HideBarPreviews()

    if not GUIFrame or not GUIFrame:IsShown() then return end
    if GUIFrame.selectedSidebarItem ~= "DT_Bars" then return end

    local db = GetSettingsDB()
    if not db then return end

    local barHeight = db.BarDisplay.barHeight or 20
    local barPos = db.BarGroup.Position or {}
    local barGrowth = db.BarGroup.GrowthDirection or "DOWN"
    local barSpacing = db.BarGroup.Spacing or 2
    local barGrowUp = barGrowth == "UP"

    for i, data in ipairs(SETTINGS_BAR_PREVIEWS) do
        local frame = CreateSettingsBarPreview(i, data)
        if frame then
            frame:ClearAllPoints()
            local offset = (i - 1) * (barHeight + barSpacing)
            if barGrowUp then
                frame:SetPoint(barPos.AnchorFrom or "CENTER", UIParent, barPos.AnchorTo or "CENTER",
                    barPos.XOffset or 0, (barPos.YOffset or 100) + offset)
            else
                frame:SetPoint(barPos.AnchorFrom or "CENTER", UIParent, barPos.AnchorTo or "CENTER",
                    barPos.XOffset or 0, (barPos.YOffset or 100) - offset)
            end
            frame:Show()
        end
    end
end

NRSKNUI.GUI.DungeonTimers.HideBarPreviews = HideBarPreviews
GUIFrame.onCloseCallbacks["DT_Bars"] = HideBarPreviews

GUIFrame:RegisterContent("DT_Bars", function(scrollChild, yOffset)
    local DT_GUI = NRSKNUI.GUI.DungeonTimers
    if DT_GUI.HideTextPreviews then DT_GUI.HideTextPreviews() end

    local db = GetSettingsDB()
    if not db then return yOffset end

    local isModuleDisabled = db.Enabled == false
    local manager = GUIFrame:CreateWidgetStateManager()

    local LSM = NRSKNUI.LSM
    local TEXTURE_OPTIONS = {}
    if LSM then
        local textures = LSM:List("statusbar")
        for _, name in ipairs(textures) do
            table_insert(TEXTURE_OPTIONS, { key = name, text = name })
        end
    else
        TEXTURE_OPTIONS = { { key = "NorskenUI", text = "NorskenUI" } }
    end

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
        ShowSettingsBarPreviews()
    end

    ShowSettingsBarPreviews()

    local displayCard = GUIFrame:CreateCard(scrollChild, "Bar Display Settings", yOffset)
    manager:Register(displayCard, "all")

    local row1 = GUIFrame:CreateRow(displayCard.content, Theme.rowHeight)
    local widthSlider = GUIFrame:CreateSlider(row1, "Bar Width", {
        min = 100,
        max = 400,
        step = 1,
        value = db.BarDisplay.barWidth or 200,
        labelWidth = 60,
        callback = function(val)
            db.BarDisplay.barWidth = val
            ApplyAndUpdate()
        end
    })
    row1:AddWidget(widthSlider, 0.5)

    local heightSlider = GUIFrame:CreateSlider(row1, "Bar Height", {
        min = 12,
        max = 40,
        step = 1,
        value = db.BarDisplay.barHeight or 20,
        labelWidth = 60,
        callback = function(val)
            db.BarDisplay.barHeight = val
            ApplyAndUpdate()
        end
    })
    row1:AddWidget(heightSlider, 0.5)
    displayCard:AddRow(row1, Theme.rowHeight)

    local row2 = GUIFrame:CreateRow(displayCard.content, Theme.rowHeight)
    local fontDropdown = GUIFrame:CreateDropdown(row2, "Font", {
        options = fontList,
        value = db.BarDisplay.fontFace or "Expressway",
        callback = function(key)
            db.BarDisplay.fontFace = key
            ApplyAndUpdate()
        end,
        searchable = true,
        isFontPreview = true
    })
    row2:AddWidget(fontDropdown, 0.5)

    local fontSizeSlider = GUIFrame:CreateSlider(row2, "Font Size", {
        min = 8,
        max = 24,
        step = 1,
        value = db.BarDisplay.fontSize or 12,
        labelWidth = 60,
        callback = function(val)
            db.BarDisplay.fontSize = val
            ApplyAndUpdate()
        end
    })
    row2:AddWidget(fontSizeSlider, 0.5)
    displayCard:AddRow(row2, Theme.rowHeight)

    local row3 = GUIFrame:CreateRow(displayCard.content, Theme.rowHeight)
    local outlineDropdown = GUIFrame:CreateDropdown(row3, "Font Outline", {
        options = SETTINGS_TEXT_OUTLINE_OPTIONS,
        value = db.BarDisplay.fontOutline or "OUTLINE",
        callback = function(key)
            db.BarDisplay.fontOutline = key
            ApplyAndUpdate()
        end
    })
    row3:AddWidget(outlineDropdown, 0.5)

    local textureDropdown = GUIFrame:CreateDropdown(row3, "Bar Texture", {
        options = TEXTURE_OPTIONS,
        value = db.BarDisplay.barTexture or "NorskenUI",
        callback = function(key)
            db.BarDisplay.barTexture = key
            ApplyAndUpdate()
        end,
        searchable = true
    })
    row3:AddWidget(textureDropdown, 0.5)
    displayCard:AddRow(row3, Theme.rowHeight)

    local row4 = GUIFrame:CreateRow(displayCard.content, Theme.rowHeightLast)
    local iconCheck = GUIFrame:CreateCheckbox(row4, "Show Icon", {
        value = db.BarDisplay.iconEnabled ~= false,
        callback = function(checked)
            db.BarDisplay.iconEnabled = checked
            ApplyAndUpdate()
        end
    })
    row4:AddWidget(iconCheck, 1)
    displayCard:AddRow(row4, Theme.rowHeightLast, 0)

    yOffset = displayCard:GetNextOffset()

    local barGroupCard = GUIFrame:CreateCard(scrollChild, "Bar Group", yOffset)
    manager:Register(barGroupCard, "all")

    local barRow1 = GUIFrame:CreateRow(barGroupCard.content, Theme.rowHeightLast)
    local barGrowthDropdown = GUIFrame:CreateDropdown(barRow1, "Growth Direction", {
        options = SETTINGS_GROWTH_OPTIONS,
        value = db.BarGroup.GrowthDirection or "DOWN",
        callback = function(key)
            db.BarGroup.GrowthDirection = key
            ApplyAndUpdate()
        end
    })
    barRow1:AddWidget(barGrowthDropdown, 0.5)

    local barSpacingSlider = GUIFrame:CreateSlider(barRow1, "Spacing", {
        min = 0,
        max = 20,
        step = 1,
        value = db.BarGroup.Spacing or 2,
        labelWidth = 50,
        callback = function(val)
            db.BarGroup.Spacing = val
            ApplyAndUpdate()
        end
    })
    barRow1:AddWidget(barSpacingSlider, 0.5)
    barGroupCard:AddRow(barRow1, Theme.rowHeightLast, 0)

    yOffset = barGroupCard:GetNextOffset()

    local barPosCard, barPosYOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        title = "Bar Group Position",
        db = db.BarGroup.Position,
        defaults = {
            xOffset = 0,
            yOffset = 100,
            selfPoint = "CENTER",
            anchorPoint = "CENTER",
        },
        showAnchorFrameType = false,
        showStrata = false,
        sliderRange = { -800, 800 },
        onChangeCallback = ApplyAndUpdate,
    })
    manager:Register(barPosCard, "all")
    yOffset = barPosYOffset

    manager:UpdateAll(not isModuleDisabled)

    return yOffset
end)
