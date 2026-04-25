---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs

GUIFrame:RegisterContent("TimeSpiral", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.TimeSpiral
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type TimeSpiral?
    local TSP = NorskenUI and NorskenUI:GetModule("TimeSpiral", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}
    local textSubWidgets = {}
    local timerSubWidgets = {}
    local allCards = {}

    local function RelayoutCards()
        local y = allCards[1] and allCards[1]:GetNextOffset() or yOffset
        for i = 2, #allCards do
            local card = allCards[i]
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", Theme.paddingSmall, -y)
            card:SetPoint("RIGHT", scrollChild, "RIGHT", -Theme.paddingSmall, 0)
            card._yOffset = y
            y = card:GetNextOffset()
        end
    end

    local function ApplySettings()
        if TSP then TSP:ApplySettings() end
    end

    local function UpdateTextState()
        for _, widget in ipairs(textSubWidgets) do
            if widget.SetEnabled then widget:SetEnabled(db.ShowText) end
        end
    end

    local function UpdateTimerState()
        for _, widget in ipairs(timerSubWidgets) do
            if widget.SetEnabled then widget:SetEnabled(db.ShowTimer) end
        end
    end

    local function UpdateAllWidgetStates()
        manager:UpdateAll(db.Enabled)
        if db.Enabled then
            for _, callback in ipairs(postUpdateCallbacks) do
                callback()
            end
        end
    end

    local card1 = GUIFrame:CreateCard(scrollChild, "Time Spiral Tracker", yOffset)
    table_insert(allCards, card1)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Time Spiral Tracker", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if TSP then
                if checked then NorskenUI:EnableModule("TimeSpiral") else NorskenUI:DisableModule("TimeSpiral") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Time Spiral Tracker",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    local appearanceCard = GUIFrame:CreateCard(scrollChild, "Appearance", yOffset)
    table_insert(allCards, appearanceCard)
    manager:Register(appearanceCard, "all")

    local rowIcon = GUIFrame:CreateRow(appearanceCard.content, Theme.rowHeight)
    local iconSizeSlider = GUIFrame:CreateSlider(rowIcon, "Icon Size", {
        min = 20,
        max = 100,
        step = 1,
        value = db.IconSize,
        callback = function(val)
            db.IconSize = val
            ApplySettings()
        end
    })
    rowIcon:AddWidget(iconSizeSlider, 1)
    manager:Register(iconSizeSlider, "all")
    appearanceCard:AddRow(rowIcon, Theme.rowHeight)

    local sepRow1 = GUIFrame:CreateRow(appearanceCard.content, Theme.rowHeightSeparator)
    local sep1 = GUIFrame:CreateSeparator(sepRow1)
    sepRow1:AddWidget(sep1, 1)
    appearanceCard:AddRow(sepRow1, Theme.rowHeightSeparator)

    local rowText1 = GUIFrame:CreateRow(appearanceCard.content, Theme.rowHeight)
    local showTextCheck = GUIFrame:CreateCheckbox(rowText1, "Show Text Label", {
        value = db.ShowText,
        callback = function(checked)
            db.ShowText = checked
            ApplySettings()
            UpdateTextState()
        end
    })
    rowText1:AddWidget(showTextCheck, 0.5)
    manager:Register(showTextCheck, "all")

    local textColorPicker = GUIFrame:CreateColorPicker(rowText1, "Text Color", {
        color = db.TextColor,
        callback = function(r, g, b, a)
            db.TextColor = { r, g, b, a }
            ApplySettings()
        end
    })
    rowText1:AddWidget(textColorPicker, 0.5)
    manager:Register(textColorPicker, "all")
    table_insert(textSubWidgets, textColorPicker)
    appearanceCard:AddRow(rowText1, Theme.rowHeight)

    local rowText2 = GUIFrame:CreateRow(appearanceCard.content, Theme.rowHeight)
    local textLabelEdit = GUIFrame:CreateEditBox(rowText2, "Label Text", {
        value = db.TextLabel,
        callback = function(text)
            db.TextLabel = text
            ApplySettings()
        end
    })
    rowText2:AddWidget(textLabelEdit, 1)
    manager:Register(textLabelEdit, "all")
    table_insert(textSubWidgets, textLabelEdit)
    appearanceCard:AddRow(rowText2, Theme.rowHeight)
    table_insert(postUpdateCallbacks, UpdateTextState)

    local sepRow2 = GUIFrame:CreateRow(appearanceCard.content, Theme.rowHeightSeparator)
    local sep2 = GUIFrame:CreateSeparator(sepRow2)
    sepRow2:AddWidget(sep2, 1)
    appearanceCard:AddRow(sepRow2, Theme.rowHeightSeparator)

    local rowTimer1 = GUIFrame:CreateRow(appearanceCard.content, Theme.rowHeightLast)
    local showTimerCheck = GUIFrame:CreateCheckbox(rowTimer1, "Show Timer", {
        value = db.ShowTimer,
        callback = function(checked)
            db.ShowTimer = checked
            ApplySettings()
            UpdateTimerState()
        end
    })
    rowTimer1:AddWidget(showTimerCheck, 0.5)
    manager:Register(showTimerCheck, "all")

    local timerColorPicker = GUIFrame:CreateColorPicker(rowTimer1, "Timer Color", {
        color = db.TimerTextColor,
        callback = function(r, g, b, a)
            db.TimerTextColor = { r, g, b, a }
            ApplySettings()
        end
    })
    rowTimer1:AddWidget(timerColorPicker, 0.5)
    manager:Register(timerColorPicker, "all")
    table_insert(timerSubWidgets, timerColorPicker)
    appearanceCard:AddRow(rowTimer1, Theme.rowHeightLast, 0)
    table_insert(postUpdateCallbacks, UpdateTimerState)

    yOffset = appearanceCard:GetNextOffset()

    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        title = "Font Settings",
        db = db,
        dbKeys = { fontFace = "FontFace", fontOutline = "FontOutline" },
        fontSizes = {
            { label = "Label Size", dbKey = "FontSize" },
            { label = "Timer Size", dbKey = "TimerFontSize" },
        },
        includeSoftOutline = true,
        onChangeCallback = ApplySettings,
    })
    table_insert(allCards, fontCard)
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")
    if fontCard.UpdateShadowState then table_insert(postUpdateCallbacks, fontCard.UpdateShadowState) end

    yOffset = fontOffset

    local glowCard, glowOffset, glowWidgets = GUIFrame:CreateGlowSettingsCard(scrollChild, yOffset, {
        db = db,
        onChangeCallback = ApplySettings,
        onHeightChange = RelayoutCards,
    })
    table_insert(allCards, glowCard)
    manager:Register(glowCard, "all")
    manager:RegisterGroup(glowWidgets, "all")
    if glowCard.updateTypeVisibility then table_insert(postUpdateCallbacks, glowCard.updateTypeVisibility) end

    yOffset = glowOffset

    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = function() if TSP then TSP:ApplyPosition() end end,
    })
    table_insert(allCards, posCard)
    manager:Register(posCard, "all")

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
