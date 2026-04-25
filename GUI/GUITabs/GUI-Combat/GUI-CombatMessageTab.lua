---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs

GUIFrame:RegisterContent("combatMessage", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.CombatMessage
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type CombatMessage?
    local CM = NorskenUI and NorskenUI:GetModule("CombatMessage", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}
    local enterSubWidgets = {}
    local exitSubWidgets = {}
    local noTargetSubWidgets = {}
    local focusSubWidgets = {}
    local partyDeathSubWidgets = {}
    local allCards = {}

    local function ApplySettings()
        if CM then CM:ApplySettings() end
    end

    local function UpdateEnterState()
        for _, widget in ipairs(enterSubWidgets) do
            if widget.SetEnabled then widget:SetEnabled(db.EnterCombat.Enabled) end
        end
    end

    local function UpdateExitState()
        for _, widget in ipairs(exitSubWidgets) do
            if widget.SetEnabled then widget:SetEnabled(db.ExitCombat.Enabled) end
        end
    end

    local function UpdateNoTargetState()
        for _, widget in ipairs(noTargetSubWidgets) do
            if widget.SetEnabled then widget:SetEnabled(db.NoTarget.Enabled) end
        end
    end

    local function UpdateFocusState()
        for _, widget in ipairs(focusSubWidgets) do
            if widget.SetEnabled then widget:SetEnabled(db.FocusDeath.Enabled) end
        end
    end

    local function UpdatePartyDeathState()
        for _, widget in ipairs(partyDeathSubWidgets) do
            if widget.SetEnabled then widget:SetEnabled(db.PartyDeath.Enabled) end
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

    -- Card 1
    local card1 = GUIFrame:CreateCard(scrollChild, "Combat Messages", yOffset)
    table_insert(allCards, card1)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Combat Messages", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if CM then
                if checked then NorskenUI:EnableModule("CombatMessage") else NorskenUI:DisableModule("CombatMessage") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Combat Messages",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2
    local card2 = GUIFrame:CreateCard(scrollChild, "Message Types", yOffset)
    table_insert(allCards, card2)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local enterEnableCheck = GUIFrame:CreateCheckbox(row2a, "Enter Combat", {
        value = db.EnterCombat.Enabled,
        callback = function(checked)
            db.EnterCombat.Enabled = checked
            ApplySettings()
            UpdateEnterState()
        end
    })
    row2a:AddWidget(enterEnableCheck, 0.25)
    manager:Register(enterEnableCheck, "all")

    local enterColorPicker = GUIFrame:CreateColorPicker(row2a, "Color", {
        color = db.EnterCombat.Color,
        callback = function(r, g, b, a)
            db.EnterCombat.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row2a:AddWidget(enterColorPicker, 0.25)
    manager:Register(enterColorPicker, "all")
    table_insert(enterSubWidgets, enterColorPicker)

    local enterTextInput = GUIFrame:CreateEditBox(row2a, "Text", {
        value = db.EnterCombat.Text,
        callback = function(val)
            db.EnterCombat.Text = val
            ApplySettings()
        end
    })
    row2a:AddWidget(enterTextInput, 0.5)
    manager:Register(enterTextInput, "all")
    table_insert(enterSubWidgets, enterTextInput)
    card2:AddRow(row2a, Theme.rowHeight)
    table_insert(postUpdateCallbacks, UpdateEnterState)

    local sep1 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sep1, Theme.rowHeightSeparator)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local exitEnableCheck = GUIFrame:CreateCheckbox(row2b, "Exit Combat", {
        value = db.ExitCombat.Enabled,
        callback = function(checked)
            db.ExitCombat.Enabled = checked
            ApplySettings()
            UpdateExitState()
        end
    })
    row2b:AddWidget(exitEnableCheck, 0.25)
    manager:Register(exitEnableCheck, "all")

    local exitColorPicker = GUIFrame:CreateColorPicker(row2b, "Color", {
        color = db.ExitCombat.Color,
        callback = function(r, g, b, a)
            db.ExitCombat.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row2b:AddWidget(exitColorPicker, 0.25)
    manager:Register(exitColorPicker, "all")
    table_insert(exitSubWidgets, exitColorPicker)

    local exitTextInput = GUIFrame:CreateEditBox(row2b, "Text", {
        value = db.ExitCombat.Text,
        callback = function(val)
            db.ExitCombat.Text = val
            ApplySettings()
        end
    })
    row2b:AddWidget(exitTextInput, 0.5)
    manager:Register(exitTextInput, "all")
    table_insert(exitSubWidgets, exitTextInput)
    card2:AddRow(row2b, Theme.rowHeight)
    table_insert(postUpdateCallbacks, UpdateExitState)

    local sep2 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sep2, Theme.rowHeightSeparator)

    local row2c = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local noTargetEnableCheck = GUIFrame:CreateCheckbox(row2c, "No Target", {
        value = db.NoTarget.Enabled,
        callback = function(checked)
            db.NoTarget.Enabled = checked
            ApplySettings()
            UpdateNoTargetState()
            if CM then CM:CheckNoTarget() end
        end
    })
    row2c:AddWidget(noTargetEnableCheck, 0.25)
    manager:Register(noTargetEnableCheck, "all")

    local noTargetColorPicker = GUIFrame:CreateColorPicker(row2c, "Color", {
        color = db.NoTarget.Color,
        callback = function(r, g, b, a)
            db.NoTarget.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row2c:AddWidget(noTargetColorPicker, 0.25)
    manager:Register(noTargetColorPicker, "all")
    table_insert(noTargetSubWidgets, noTargetColorPicker)

    local noTargetTextInput = GUIFrame:CreateEditBox(row2c, "Text", {
        value = db.NoTarget.Text,
        callback = function(val)
            db.NoTarget.Text = val
            ApplySettings()
        end
    })
    row2c:AddWidget(noTargetTextInput, 0.5)
    manager:Register(noTargetTextInput, "all")
    table_insert(noTargetSubWidgets, noTargetTextInput)
    card2:AddRow(row2c, Theme.rowHeight)
    table_insert(postUpdateCallbacks, UpdateNoTargetState)

    local sep3 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sep3, Theme.rowHeightSeparator)

    local row2d = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local focusEnableCheck = GUIFrame:CreateCheckbox(row2d, "Focus Died", {
        value = db.FocusDeath.Enabled,
        callback = function(checked)
            db.FocusDeath.Enabled = checked
            ApplySettings()
            UpdateFocusState()
        end
    })
    row2d:AddWidget(focusEnableCheck, 0.25)
    manager:Register(focusEnableCheck, "all")

    local focusColorPicker = GUIFrame:CreateColorPicker(row2d, "Color", {
        color = db.FocusDeath.Color,
        callback = function(r, g, b, a)
            db.FocusDeath.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row2d:AddWidget(focusColorPicker, 0.25)
    manager:Register(focusColorPicker, "all")
    table_insert(focusSubWidgets, focusColorPicker)

    local focusTextInput = GUIFrame:CreateEditBox(row2d, "Text", {
        value = db.FocusDeath.Text,
        callback = function(val)
            db.FocusDeath.Text = val
            ApplySettings()
        end
    })
    row2d:AddWidget(focusTextInput, 0.5)
    manager:Register(focusTextInput, "all")
    table_insert(focusSubWidgets, focusTextInput)
    card2:AddRow(row2d, Theme.rowHeight)
    table_insert(postUpdateCallbacks, UpdateFocusState)

    local sep4 = GUIFrame:CreateSeparator(card2.content)
    card2:AddRow(sep4, Theme.rowHeightSeparator)

    local row2e = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local deathEnableCheck = GUIFrame:CreateCheckbox(row2e, "Player Died", {
        value = db.PartyDeath.Enabled,
        callback = function(checked)
            db.PartyDeath.Enabled = checked
            ApplySettings()
            UpdatePartyDeathState()
        end
    })
    row2e:AddWidget(deathEnableCheck, 0.25)
    manager:Register(deathEnableCheck, "all")

    local deathTextColor = GUIFrame:CreateColorPicker(row2e, "Text Color", {
        color = db.PartyDeath.TextColor,
        callback = function(r, g, b, a)
            db.PartyDeath.TextColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row2e:AddWidget(deathTextColor, 0.25)
    manager:Register(deathTextColor, "all")
    table_insert(partyDeathSubWidgets, deathTextColor)

    local deathFormatInput = GUIFrame:CreateEditBox(row2e, "Text Format (%name)", {
        value = db.PartyDeath.TextFormat,
        callback = function(val)
            db.PartyDeath.TextFormat = val
            ApplySettings()
        end
    })
    row2e:AddWidget(deathFormatInput, 0.5)
    manager:Register(deathFormatInput, "all")
    table_insert(partyDeathSubWidgets, deathFormatInput)
    card2:AddRow(row2e, Theme.rowHeight)

    local row2f = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local deathClassColorCheck = GUIFrame:CreateCheckbox(row2f, "Class Colored Name", {
        value = db.PartyDeath.UseClassColor,
        callback = function(checked)
            db.PartyDeath.UseClassColor = checked
            ApplySettings()
        end
    })
    row2f:AddWidget(deathClassColorCheck, 0.25)
    manager:Register(deathClassColorCheck, "all")
    table_insert(partyDeathSubWidgets, deathClassColorCheck)

    local deathCombatOnlyCheck = GUIFrame:CreateCheckbox(row2f, "Combat Only", {
        value = db.PartyDeath.CombatOnly,
        callback = function(checked)
            db.PartyDeath.CombatOnly = checked
            ApplySettings()
        end
    })
    row2f:AddWidget(deathCombatOnlyCheck, 0.25)
    manager:Register(deathCombatOnlyCheck, "all")
    table_insert(partyDeathSubWidgets, deathCombatOnlyCheck)

    local deathLoadDropdown = GUIFrame:CreateDropdown(row2f, "Load", {
        options = {
            { key = "ALWAYS",   text = "Always" },
            { key = "ANYGROUP", text = "Any Group" },
            { key = "PARTY",    text = "In Party" },
            { key = "RAID",     text = "In Raid" },
            { key = "NOGROUP",  text = "No Group" },
        },
        value = db.PartyDeath.LoadCondition,
        callback = function(key)
            db.PartyDeath.LoadCondition = key
            ApplySettings()
        end
    })
    row2f:AddWidget(deathLoadDropdown, 0.5)
    manager:Register(deathLoadDropdown, "all")
    table_insert(partyDeathSubWidgets, deathLoadDropdown)
    table_insert(postUpdateCallbacks, UpdatePartyDeathState)

    card2:AddRow(row2f, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3
    local card5 = GUIFrame:CreateCard(scrollChild, "Layout", yOffset)
    table_insert(allCards, card5)
    manager:Register(card5, "all")

    local row5a = GUIFrame:CreateRow(card5.content, Theme.rowHeight)
    local spacingSlider = GUIFrame:CreateSlider(row5a, "Spacing", {
        min = 0,
        max = 20,
        step = 1,
        value = db.Spacing,
        callback = function(val)
            db.Spacing = val
            ApplySettings()
        end
    })
    row5a:AddWidget(spacingSlider, 0.5)
    manager:Register(spacingSlider, "all")

    local growDropdown = GUIFrame:CreateDropdown(row5a, "Grow Direction", {
        options = {
            { key = "DOWN", text = "Down" },
            { key = "UP",   text = "Up" },
        },
        value = db.Grow,
        callback = function(val)
            db.Grow = val
            ApplySettings()
        end
    })
    row5a:AddWidget(growDropdown, 0.5)
    manager:Register(growDropdown, "all")
    card5:AddRow(row5a, Theme.rowHeight)

    local row5b = GUIFrame:CreateRow(card5.content, Theme.rowHeightLast)
    local durationSlider = GUIFrame:CreateSlider(row5b, "Message Duration", {
        min = 1,
        max = 10,
        step = 0.5,
        value = db.Duration,
        callback = function(val)
            db.Duration = val
            ApplySettings()
        end
    })
    row5b:AddWidget(durationSlider, 1)
    manager:Register(durationSlider, "all")
    card5:AddRow(row5b, Theme.rowHeightLast, 0)

    yOffset = card5:GetNextOffset()

    -- Card 6
    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        title = "Font Settings",
        db = db,
        dbKeys = { fontFace = "FontFace", fontOutline = "FontOutline", shadow = "FontShadow" },
        fontSizes = {
            { label = "Enter Combat", dbKey = "EnterCombat.FontSize" },
            { label = "Exit Combat", dbKey = "ExitCombat.FontSize" },
            { label = "No Target", dbKey = "NoTarget.FontSize" },
            { label = "Focus Died", dbKey = "FocusDeath.FontSize" },
            { label = "Player Died", dbKey = "PartyDeath.FontSize" },
        },
        includeSoftOutline = true,
        onChangeCallback = ApplySettings,
    })
    table_insert(allCards, fontCard)
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")
    if fontCard.UpdateShadowState then table_insert(postUpdateCallbacks, fontCard.UpdateShadowState) end

    yOffset = fontOffset

    -- Card 7
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = ApplySettings,
    })
    table_insert(allCards, posCard)
    manager:Register(posCard, "all")

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
