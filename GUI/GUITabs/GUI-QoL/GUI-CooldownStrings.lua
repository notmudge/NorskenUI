-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

-- Localization
local table_insert = table.insert
local pairs, ipairs = pairs, ipairs
local CreateFrame = CreateFrame
local time = time

-- Get module reference
local function GetModule()
    if NorskenUI then
        return NorskenUI:GetModule("CooldownStrings", true)
    end
    return nil
end

-- Persistent selected profile across refreshes
local selectedProfileName = nil

-- Register CooldownStrings tab content
GUIFrame:RegisterContent("CooldownStrings", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile.Miscellaneous.CooldownStrings
    if not db then
        local errorCard = GUIFrame:CreateCard(scrollChild, "Error", yOffset)
        errorCard:AddLabel("Database not available")
        return yOffset + errorCard:GetContentHeight() + Theme.paddingMedium
    end

    -- Ensure Profiles table exists
    if not db.Profiles then db.Profiles = {} end

    local allWidgets = {}

    local function ApplyModuleState(enabled)
        local mod = GetModule()
        if not mod then return end
        mod.db.Enabled = enabled
        if enabled then
            NorskenUI:EnableModule("CooldownStrings")
        else
            NorskenUI:DisableModule("CooldownStrings")
        end
    end

    local function RefreshContent()
        C_Timer.After(0.1, function()
            GUIFrame:RefreshContent()
        end)
    end

    local function SyncWithModule()
        local mod = GetModule()
        if mod and mod.RefreshPanel then
            mod:RefreshPanel()
        end
    end

    local function UpdateAllWidgetStates()
        local mainEnabled = db.Enabled ~= false
        for _, widget in ipairs(allWidgets) do
            if widget.SetEnabled then
                widget:SetEnabled(mainEnabled)
            end
        end
    end

    -- Build profile dropdown list
    local function GetProfileList()
        local list = {}
        for name, data in pairs(db.Profiles) do
            table_insert(list, {
                key = name,
                text = name,
            })
        end
        -- Sort alphabetically
        table.sort(list, function(a, b) return a.text < b.text end)
        return list
    end

    -- Validate selected profile still exists
    if selectedProfileName then
        if not db.Profiles[selectedProfileName] then
            selectedProfileName = nil
        end
    end

    -- Get selected profile data
    local selectedProfile = selectedProfileName and db.Profiles[selectedProfileName] or nil

    ----------------------------------------------------------------
    -- Card 1: Enable CDM Profile Strings
    ----------------------------------------------------------------
    local card1 = GUIFrame:CreateCard(scrollChild, "CDM Profile Strings", yOffset)

    local row1 = GUIFrame:CreateRow(card1.content, 36)
    local enableCheck = GUIFrame:CreateCheckbox(row1, "Enable CDM Profile Strings", db.Enabled ~= false,
        function(checked)
            db.Enabled = checked
            ApplyModuleState(checked)
            UpdateAllWidgetStates()
        end,
        true, "CDM Profile Strings", "On", "Off"
    )
    row1:AddWidget(enableCheck, 1)
    card1:AddRow(row1, 36)

    -- Separator
    local row4asep = GUIFrame:CreateRow(card1.content, 8)
    local seprow4aCard = GUIFrame:CreateSeparator(row4asep)
    row4asep:AddWidget(seprow4aCard, 1)
    card1:AddRow(row4asep, 8)

    -- Description text
    local textRowSize = 50
    local rowDesc = GUIFrame:CreateRow(card1.content, textRowSize)
    local descText = GUIFrame:CreateText(rowDesc,
        NRSKNUI:ColorTextByTheme("How It Works"),
        (NRSKNUI:ColorTextByTheme("• ") .. "Opens automatically when Blizzard's Cooldown Manager settings open\n" ..
            NRSKNUI:ColorTextByTheme("• ") .. "Save and backup your CDM profile strings in savedVariables"),
        textRowSize, "hide")
    rowDesc:AddWidget(descText, 1)
    table_insert(allWidgets, descText)
    card1:AddRow(rowDesc, textRowSize)

    yOffset = yOffset + card1:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 2: Profile Management (Create + Dropdown)
    ----------------------------------------------------------------
    local card2 = GUIFrame:CreateCard(scrollChild, "Profile Management", yOffset)
    table_insert(allWidgets, card2)

    local row2a = GUIFrame:CreateRow(card2.content, 36)

    -- Create New Profile button
    local createBtn = GUIFrame:CreateButton(row2a, "Create New", {
        width = 120,
        callback = function()
            NRSKNUI:CreatePrompt(
                "New CDM Profile",
                "Enter a name for this profile:",
                true,
                nil,
                false,
                nil, nil, nil, nil,
                function(inputText)
                    if inputText and inputText ~= "" then
                        -- Check if profile already exists
                        if db.Profiles[inputText] then
                            NRSKNUI:Print("A profile named '" .. inputText .. "' already exists.")
                            return
                        end

                        -- Create new profile
                        db.Profiles[inputText] = {
                            String = "",
                            Created = time(),
                        }
                        selectedProfileName = inputText
                        NRSKNUI:Print("Created new CDM profile: " .. inputText)

                        -- Sync with attached panel
                        SyncWithModule()
                        RefreshContent()
                    end
                end,
                nil,
                "Create",
                "Cancel"
            )
        end,
    })
    row2a:AddWidget(createBtn, 0.4, nil, 0, -2)
    table_insert(allWidgets, createBtn)

    -- Profile dropdown
    local profileList = GetProfileList()
    if #profileList > 0 then
        local currentSelection = selectedProfileName or profileList[1].key
        if not selectedProfileName then
            selectedProfileName = profileList[1].key
            selectedProfile = db.Profiles[selectedProfileName]
        end

        local profileDropdown = GUIFrame:CreateDropdown(row2a, "Edit Profile", profileList, currentSelection, 70,
            function(key)
                selectedProfileName = key
                RefreshContent()
            end)
        row2a:AddWidget(profileDropdown, 0.6)
        table_insert(allWidgets, profileDropdown)
    end

    card2:AddRow(row2a, 36)

    yOffset = yOffset + card2:GetContentHeight() + Theme.paddingSmall

    ----------------------------------------------------------------
    -- Card 3: Selected Profile Editor
    ----------------------------------------------------------------
    if selectedProfile then
        local card3 = GUIFrame:CreateCard(scrollChild, "Profile Settings", yOffset)
        table_insert(allWidgets, card3)

        -- Row 1: Profile name + Delete button
        local row3a = GUIFrame:CreateRow(card3.content, 42)

        -- Profile name label
        local nameLabel = row3a:CreateFontString(nil, "OVERLAY")
        nameLabel:SetPoint("LEFT", row3a, "LEFT", 4, 0)
        nameLabel:SetFont(STANDARD_TEXT_FONT, Theme.fontSizeLarge or 12, "OUTLINE")
        nameLabel:SetText("Editing: |cFFFFFFFF" .. selectedProfileName .. "|r")
        nameLabel:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
        nameLabel:SetShadowOffset(0, 0)

        -- Container for label
        local nameLabelContainer = CreateFrame("Frame", nil, row3a)
        nameLabelContainer:SetHeight(36)
        nameLabel:SetParent(nameLabelContainer)
        nameLabel:ClearAllPoints()
        nameLabel:SetPoint("LEFT", nameLabelContainer, "LEFT", 0, 8)

        row3a:AddWidget(nameLabelContainer, 0.7)

        -- Delete button
        local deleteBtn = GUIFrame:CreateButton(row3a, "Delete", {
            width = 80,
            callback = function()
                NRSKNUI:CreatePrompt(
                    "Delete Profile",
                    "Are you sure you want to delete '" .. selectedProfileName .. "'?\n\nThis cannot be undone.",
                    false, nil, false, nil, nil, nil, nil,
                    function()
                        local deletedName = selectedProfileName
                        if deletedName then
                            db.Profiles[deletedName] = nil
                        end
                        deletedName = nil

                        -- Select next available profile
                        for profileName, _ in pairs(db.Profiles) do
                            deletedName = profileName
                            break
                        end

                        NRSKNUI:Print("Deleted CDM profile: " .. deletedName)
                        SyncWithModule()
                        RefreshContent()
                    end,
                    nil,
                    "Delete",
                    "Cancel"
                )
            end,
        })
        row3a:AddWidget(deleteBtn, 0.3)
        table_insert(allWidgets, deleteBtn)

        card3:AddRow(row3a, 42)

        -- Row 2: Profile String EditBox (multiline)
        local row3b = GUIFrame:CreateRow(card3.content, 134)
        local profileStringEditor = GUIFrame:CreateMultiLineEditBox(row3b, {
            label = "Profile String (paste your CDM export here)",
            value = selectedProfile.String or "",
            height = 120,
            tooltip = "CTRL+C to copy, CTRL+V to paste, CTRL+A to select all",
            onTextChanged = function(text)
                if selectedProfileName and db.Profiles[selectedProfileName] then
                    db.Profiles[selectedProfileName].String = text
                    SyncWithModule()
                end
            end,
        })
        row3b:AddWidget(profileStringEditor, 1)
        table_insert(allWidgets, profileStringEditor)
        card3:AddRow(row3b, 134)

        yOffset = yOffset + card3:GetContentHeight() + Theme.paddingSmall
    else
        -- No profile selected message
        local card3 = GUIFrame:CreateCard(scrollChild, "Profile Editor", yOffset)
        table_insert(allWidgets, card3)
        card3:AddLabel("No profiles configured. Click 'Create New' to create one.")
        yOffset = yOffset + card3:GetContentHeight() + Theme.paddingSmall
    end

    UpdateAllWidgetStates()
    yOffset = yOffset - (Theme.paddingSmall * 3)
    return yOffset
end)
