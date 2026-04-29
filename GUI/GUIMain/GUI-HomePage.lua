---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

local UnitName = UnitName
local UnitClass = UnitClass

GUIFrame:RegisterContent("HomePage", function(scrollChild, yOffset)
    local db = NRSKNUI.db and NRSKNUI.db.profile
    if not db then return GUIFrame:ShowDBError(scrollChild, yOffset) end

    -- Card 1
    local welcomeCard = GUIFrame:CreateCard(scrollChild, "Welcome to NorskenUI", yOffset)
    local _, class = UnitClass("player")
    local playerName = UnitName("player")

    welcomeCard:AddLabel("Hello, " .. NRSKNUI:ColorTextByClass(playerName, class) .. "!", "normal")
    welcomeCard:AddSpacing(4)

    welcomeCard:AddLabel("Version: " .. NRSKNUI:ColorTextByTheme(NRSKNUI.Version), "normal")
    welcomeCard:AddSpacing(4)

    welcomeCard:AddLabel("Active Profile: " .. NRSKNUI:ColorTextByTheme(NRSKNUI.db:GetCurrentProfile()), "normal")

    local Sep = GUIFrame:CreateSeparator(welcomeCard.content)
    welcomeCard:AddRow(Sep, Theme.rowHeightSeparator)

    local mapIconRow = GUIFrame:CreateRow(welcomeCard.content, Theme.rowHeight)
    local mapIconCheck = GUIFrame:CreateCheckbox(mapIconRow, "Hide Minimap Icon", {
        value = db.Minimap.hide,
        callback = function(checked) db.Minimap.hide = checked end,
        msgPopup = true,
        msgText = "Hide Minimap Icon",
    })
    mapIconRow:AddWidget(mapIconCheck, 1)
    welcomeCard:AddRow(mapIconRow, Theme.rowHeight)

    local loginMsgRow = GUIFrame:CreateRow(welcomeCard.content, Theme.rowHeightLast)
    local loginMsgCheck = GUIFrame:CreateCheckbox(loginMsgRow, "Show Login Message", {
        value = db.Minimap.LoginMessage,
        callback = function(checked) db.Minimap.LoginMessage = checked end,
        msgPopup = true,
        msgText = "Login Message",
    })
    loginMsgRow:AddWidget(loginMsgCheck, 1)
    welcomeCard:AddRow(loginMsgRow, Theme.rowHeightLast, 0)

    yOffset = welcomeCard:GetNextOffset()

    -- Card 3
    local elvUICard = GUIFrame:CreateCard(scrollChild, "ElvUI Integration", yOffset)

    local elvUIRow = GUIFrame:CreateRow(elvUICard.content, Theme.rowHeight)
    local elvUICheck = GUIFrame:CreateCheckbox(elvUIRow, "Use ElvUI Skinning", {
        value = db.UseElvUI.Enabled,
        callback = function(checked)
            db.UseElvUI.Enabled = checked
            NRSKNUI:CreateReloadPrompt("Disabling/Enabling this requires a reload to take full effect.")
        end,
        msgPopup = true,
        msgText = "Use ElvUI",
    })
    elvUIRow:AddWidget(elvUICheck, 1)
    elvUICard:AddRow(elvUIRow, Theme.rowHeight)

    local elvUISep = GUIFrame:CreateSeparator(elvUICard.content)
    elvUICard:AddRow(elvUISep, Theme.rowHeightSeparator)

    local infoRow = GUIFrame:CreateRow(elvUICard.content, 60)
    local infoWidget = GUIFrame:CreateText(infoRow, NRSKNUI:ColorTextByTheme("Information"), {
        text = NRSKNUI:ColorTextByTheme("• ") ..
            "Disables all skinning modules when ElvUI is loaded.\n  This way you can still use the non skinning features of the addon without conflict.",
        height = 60,
        bgMode = "hide"
    })
    infoRow:AddWidget(infoWidget, 1)
    elvUICard:AddRow(infoRow, 60, 0)

    yOffset = elvUICard:GetNextOffset()

    -- Card 6
    local supportCard = GUIFrame:CreateCard(scrollChild, "Support", yOffset)

    supportCard:AddLabel("Found a bug or have a suggestion?")
    supportCard:AddSpacing(4)

    supportCard:AddLabel("Join the " .. NRSKNUI:ColorTextByTheme("Discord") .. " or open an issue on " .. NRSKNUI:ColorTextByTheme("GitHub"))

    yOffset = supportCard:GetNextOffset()

    return yOffset - Theme.paddingSmall
end)
