-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)
local GUIFrame = NRSKNUI.GUIFrame
local Theme = NRSKNUI.Theme

-- Localization Setup
local tostring = tostring
local type = type
local CreateFrame = CreateFrame

-- MultiLineEditBox widget
-- config: { label, value, height, onTextChanged, tooltip, syntaxHighlight }
function GUIFrame:CreateMultiLineEditBox(parent, config)
    local labelText = config.label
    local value = tostring(config.value or "")
    local callback = config.onTextChanged
    local tooltip = config.tooltip
    local containerHeight = config.height or 80
    local syntaxHighlight = config.syntaxHighlight

    -- Total row height: label (14) + container + some padding
    local rowHeight = 14 + containerHeight + 4
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(rowHeight)

    -- Label
    local label = row:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    label:SetJustifyH("LEFT")
    NRSKNUI:ApplyThemeFont(label, "small")
    label:SetText(labelText or "")
    label:SetTextColor(Theme.textSecondary[1], Theme.textSecondary[2], Theme.textSecondary[3], 1)
    row.label = label

    -- Container with backdrop
    local container = CreateFrame("Frame", nil, row, "BackdropTemplate")
    container:SetHeight(containerHeight)
    container:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -14)
    container:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -14)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(Theme.bgDark[1], Theme.bgDark[2], Theme.bgDark[3], 1)
    container:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)

    --- ANIMATION

    -- Border hover animation
    local animGroup = container:CreateAnimationGroup()
    local anim = animGroup:CreateAnimation("Animation")
    anim:SetDuration(0.18)

    local colorFrom = {}
    local colorTo = {}
    local borderR, borderG, borderB = Theme.border[1], Theme.border[2], Theme.border[3]

    local function AnimateBorder(toAccent)
        animGroup:Stop()
        colorFrom.r = borderR
        colorFrom.g = borderG
        colorFrom.b = borderB

        if toAccent then
            colorTo.r = Theme.accent[1]
            colorTo.g = Theme.accent[2]
            colorTo.b = Theme.accent[3]
        else
            colorTo.r = Theme.border[1]
            colorTo.g = Theme.border[2]
            colorTo.b = Theme.border[3]
        end
        animGroup:Play()
    end

    animGroup:SetScript("OnUpdate", function(self)
        local progress = self:GetProgress() or 0
        local r = colorFrom.r + (colorTo.r - colorFrom.r) * progress
        local g = colorFrom.g + (colorTo.g - colorFrom.g) * progress
        local b = colorFrom.b + (colorTo.b - colorFrom.b) * progress
        container:SetBackdropBorderColor(r, g, b, 1)
        borderR, borderG, borderB = r, g, b
    end)

    animGroup:SetScript("OnFinished", function()
        container:SetBackdropBorderColor(colorTo.r, colorTo.g, colorTo.b, 1)
        borderR, borderG, borderB = colorTo.r, colorTo.g, colorTo.b
    end)

    --------

    -- Scroll frame for multi-line content
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -20, 6)

    -- Style scrollbar
    if scrollFrame.ScrollBar then
        scrollFrame.ScrollBar:ClearAllPoints()
        scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
        scrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
        scrollFrame.ScrollBar:SetWidth(8)
    end

    -- EditBox (multi-line)
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetTextColor(1, 1, 1, 1)
    editBox:SetCountInvisibleLetters(false) -- Required for IndentationLib cursor handling
    editBox:EnableMouse(true)
    scrollFrame:SetScrollChild(editBox)

    -- Auto-scroll when cursor moves (keeps cursor visible)
    editBox:SetScript("OnCursorChanged", function(self, _, y, _, cursorHeight)
        local offset = scrollFrame:GetVerticalScroll()
        if -y < offset then
            scrollFrame:SetVerticalScroll(-y)
        else
            local scrollHeight = scrollFrame:GetHeight()
            y = -y + cursorHeight - scrollHeight
            if y > offset then
                scrollFrame:SetVerticalScroll(y)
            end
        end
    end)

    -- Enable syntax highlighting if requested
    if syntaxHighlight and IndentationLib and IndentationLib.enable then
        IndentationLib.enable(editBox, nil, 2) -- nil = default colors, 2 = tab width
    end

    -- Set editbox to fill scrollframe width
    editBox:SetWidth(scrollFrame:GetWidth() > 0 and scrollFrame:GetWidth() or 200)

    -- Update editbox width when scrollframe resizes
    scrollFrame:SetScript("OnSizeChanged", function(self, width, height)
        editBox:SetWidth(width)
    end)

    -- Set initial text (without syntax highlighting first)
    editBox:SetText(value)
    editBox:SetCursorPosition(0)

    -- Escape clears focus (which triggers save)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Save on focus lost
    editBox:SetScript("OnEditFocusLost", function(self)
        container:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
        borderR, borderG, borderB = Theme.border[1], Theme.border[2], Theme.border[3]
        if callback then
            callback(self:GetText())
        end
    end)

    -- Highlight border on focus
    editBox:SetScript("OnEditFocusGained", function()
        container:SetBackdropBorderColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
        borderR, borderG, borderB = Theme.accent[1], Theme.accent[2], Theme.accent[3]
    end)

    -- Hover animation on editbox
    editBox:SetScript("OnEnter", function(self)
        if not self:HasFocus() then
            AnimateBorder(true)
        end
        if tooltip then
            GameTooltip:SetOwner(container, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)

    editBox:SetScript("OnLeave", function(self)
        if not self:HasFocus() then
            AnimateBorder(false)
        end
        GameTooltip:Hide()
    end)

    -- Make entire container clickable to focus editbox
    container:EnableMouse(true)
    container:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)
    container:SetScript("OnEnter", function()
        if not editBox:HasFocus() then
            AnimateBorder(true)
        end
        if tooltip then
            GameTooltip:SetOwner(container, "ANCHOR_TOP")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    container:SetScript("OnLeave", function()
        if not editBox:HasFocus() then
            AnimateBorder(false)
        end
        GameTooltip:Hide()
    end)

    -- Make scroll frame clickable to focus editbox
    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseDown", function()
        editBox:SetFocus()
    end)

    -- Public methods
    function row:SetValue(val)
        editBox:SetText(val or "")
        editBox:SetCursorPosition(0)
    end

    function row:GetValue()
        return editBox:GetText()
    end

    function row:SetEnabled(enabled)
        if enabled then
            row:SetAlpha(1)
            editBox:EnableMouse(true)
            editBox:EnableKeyboard(true)
            container:EnableMouse(true)
        else
            row:SetAlpha(0.4)
            editBox:EnableMouse(false)
            editBox:EnableKeyboard(false)
            editBox:ClearFocus()
            container:EnableMouse(false)
        end
    end

    row.editBox = editBox
    row.container = container
    row.scrollFrame = scrollFrame

    return row
end
