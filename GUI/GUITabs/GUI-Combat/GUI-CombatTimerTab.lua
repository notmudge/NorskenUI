---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local table_insert = table.insert
local ipairs = ipairs

GUIFrame:RegisterContent("combatTimer", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.CombatTimer
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    ---@type CombatTimer?
    local CT = NorskenUI and NorskenUI:GetModule("CombatTimer", true)
    local manager = GUIFrame:CreateWidgetStateManager()
    local postUpdateCallbacks = {}
    local combatOnlyWidgets = {}
    local backdropSubWidgets = {}

    local function ApplySettings()
        if CT and CT.ApplySettings then CT:ApplySettings() end
    end

    local function UpdateCombatOnlyState()
        local enabled = not db.CombatOnly
        for _, widget in ipairs(combatOnlyWidgets) do
            if widget.SetEnabled then widget:SetEnabled(enabled) end
        end
    end

    local function UpdateBackdropState()
        local backdropEnabled = db.Backdrop.Enabled
        for _, widget in ipairs(backdropSubWidgets) do
            if widget.SetEnabled then widget:SetEnabled(backdropEnabled) end
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

    -- Card 1: Enable
    local card1 = GUIFrame:CreateCard(scrollChild, "Combat Timer", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, Theme.rowHeightLast)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable Combat Timer", {
        value = db.Enabled,
        callback = function(checked)
            db.Enabled = checked
            if CT then
                if checked then NorskenUI:EnableModule("CombatTimer") else NorskenUI:DisableModule("CombatTimer") end
            end
            UpdateAllWidgetStates()
        end,
        msgPopup = true,
        msgText = "Combat Timer",
    })
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, Theme.rowHeightLast, 0)

    yOffset = card1:GetNextOffset()

    -- Card 2: Options
    local card2 = GUIFrame:CreateCard(scrollChild, "Options", yOffset)
    manager:Register(card2, "all")

    local row2a = GUIFrame:CreateRow(card2.content, Theme.rowHeight)
    local combatOnlyCheck = GUIFrame:CreateCheckbox(row2a, "Combat Only", {
        value = db.CombatOnly,
        callback = function(checked)
            db.CombatOnly = checked
            if CT then
                if CT.frame then
                    if checked and not CT.running and not CT.isPreview then
                        CT.frame:Hide()
                    elseif not checked then
                        CT.frame:Show()
                    end
                end
            end
            ApplySettings()
            UpdateCombatOnlyState()
        end
    })
    row2a:AddWidget(combatOnlyCheck, 0.5)
    manager:Register(combatOnlyCheck, "all")

    local formatDropdown = GUIFrame:CreateDropdown(row2a, "Format", {
        options = { ["MM:SS"] = "MM:SS", ["MM:SS:MS"] = "MM:SS:MS" },
        value = db.Format,
        callback = function(key)
            db.Format = key
            ApplySettings()
        end
    })
    row2a:AddWidget(formatDropdown, 0.5)
    manager:Register(formatDropdown, "all")
    card2:AddRow(row2a, Theme.rowHeight)

    local row2b = GUIFrame:CreateRow(card2.content, Theme.rowHeightLast)
    local printCheck = GUIFrame:CreateCheckbox(row2b, "Print Duration to Chat", {
        value = db.PrintEnd,
        callback = function(checked)
            db.PrintEnd = checked
        end
    })
    row2b:AddWidget(printCheck, 1)
    manager:Register(printCheck, "all")
    card2:AddRow(row2b, Theme.rowHeightLast, 0)

    yOffset = card2:GetNextOffset()

    -- Card 3: Colors
    local card3 = GUIFrame:CreateCard(scrollChild, "Colors", yOffset)
    manager:Register(card3, "all")

    local row3a = GUIFrame:CreateRow(card3.content, Theme.rowHeightLast)
    local inCombatColor = GUIFrame:CreateColorPicker(row3a, "In Combat", {
        color = db.ColorInCombat,
        callback = function(r, g, b, a)
            db.ColorInCombat = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(inCombatColor, 0.5)
    manager:Register(inCombatColor, "all")

    local outCombatColor = GUIFrame:CreateColorPicker(row3a, "Out of Combat", {
        color = db.ColorOutOfCombat,
        callback = function(r, g, b, a)
            db.ColorOutOfCombat = { r, g, b, a }
            ApplySettings()
        end
    })
    row3a:AddWidget(outCombatColor, 0.5)
    manager:Register(outCombatColor, "all")
    table_insert(combatOnlyWidgets, outCombatColor)
    table_insert(postUpdateCallbacks, UpdateCombatOnlyState)
    card3:AddRow(row3a, Theme.rowHeightLast, 0)

    yOffset = card3:GetNextOffset()

    -- Card 4: Backdrop
    local card4 = GUIFrame:CreateCard(scrollChild, "Backdrop", yOffset)
    manager:Register(card4, "all")
    table_insert(postUpdateCallbacks, UpdateBackdropState)

    local row4a = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local backdropCheck = GUIFrame:CreateCheckbox(row4a, "Enable Backdrop", {
        value = db.Backdrop.Enabled,
        callback = function(checked)
            db.Backdrop.Enabled = checked
            ApplySettings()
            UpdateBackdropState()
        end
    })
    row4a:AddWidget(backdropCheck, 1)
    manager:Register(backdropCheck, "all")
    card4:AddRow(row4a, Theme.rowHeight)

    local separator = GUIFrame:CreateSeparator(card4.content)
    card4:AddRow(separator, Theme.rowHeightSeparator)

    local row4ab = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local bgColor = GUIFrame:CreateColorPicker(row4ab, "Background Color", {
        color = db.Backdrop.Color,
        callback = function(r, g, b, a)
            db.Backdrop.Color = { r, g, b, a }
            ApplySettings()
        end
    })
    row4ab:AddWidget(bgColor, 1)
    manager:Register(bgColor, "all")
    table_insert(backdropSubWidgets, bgColor)
    card4:AddRow(row4ab, Theme.rowHeight)

    local row4b = GUIFrame:CreateRow(card4.content, Theme.rowHeight)
    local bgWidth = GUIFrame:CreateSlider(row4b, "Background Width", {
        min = 1,
        max = 600,
        step = 1,
        value = db.Backdrop.bgWidth,
        callback = function(val)
            db.Backdrop.bgWidth = val
            ApplySettings()
        end
    })
    row4b:AddWidget(bgWidth, 0.5)
    manager:Register(bgWidth, "all")
    table_insert(backdropSubWidgets, bgWidth)

    local bgHeight = GUIFrame:CreateSlider(row4b, "Background Height", {
        min = 1,
        max = 600,
        step = 1,
        value = db.Backdrop.bgHeight,
        callback = function(val)
            db.Backdrop.bgHeight = val
            ApplySettings()
        end
    })
    row4b:AddWidget(bgHeight, 0.5)
    manager:Register(bgHeight, "all")
    table_insert(backdropSubWidgets, bgHeight)
    card4:AddRow(row4b, Theme.rowHeight)

    local separator2 = GUIFrame:CreateSeparator(card4.content)
    card4:AddRow(separator2, Theme.rowHeightSeparator)

    local row4bc = GUIFrame:CreateRow(card4.content, Theme.rowHeightLast)
    local borderColor = GUIFrame:CreateColorPicker(row4bc, "Border Color", {
        color = db.Backdrop.BorderColor,
        callback = function(r, g, b, a)
            db.Backdrop.BorderColor = { r, g, b, a }
            ApplySettings()
        end
    })
    row4bc:AddWidget(borderColor, 0.5)
    manager:Register(borderColor, "all")
    table_insert(backdropSubWidgets, borderColor)

    local borderSize = GUIFrame:CreateSlider(row4bc, "Border Size", {
        min = 1,
        max = 10,
        step = 1,
        value = db.Backdrop.BorderSize,
        callback = function(val)
            db.Backdrop.BorderSize = val
            ApplySettings()
        end
    })
    row4bc:AddWidget(borderSize, 0.5)
    manager:Register(borderSize, "all")
    table_insert(backdropSubWidgets, borderSize)
    card4:AddRow(row4bc, Theme.rowHeightLast, 0)

    yOffset = card4:GetNextOffset()

    -- Card 5: Font Settings
    local fontCard, fontOffset, fontWidgets = GUIFrame:CreateFontSettingsCard(scrollChild, yOffset, {
        db = db,
        includeSoftOutline = true,
        onChangeCallback = ApplySettings,
    })
    manager:Register(fontCard, "all")
    manager:RegisterGroup(fontWidgets, "all")
    if fontCard.UpdateShadowState then table_insert(postUpdateCallbacks, fontCard.UpdateShadowState) end

    yOffset = fontOffset

    -- Card 6: Position
    local posCard, posOffset = GUIFrame:CreatePositionCard(scrollChild, yOffset, {
        db = db,
        showAnchorFrameType = true,
        showStrata = true,
        onChangeCallback = function() if CT then CT:ApplyPosition() end end,
    })
    manager:Register(posCard, "all")
    if posCard.positionWidgets then manager:RegisterGroup(posCard.positionWidgets, "all") end

    yOffset = posOffset

    UpdateAllWidgetStates()

    return yOffset
end)
