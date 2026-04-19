-- NorskenUI namespace
---@class NRSKNUI
local NRSKNUI = select(2, ...)

-- Check for addon object
if not NorskenUI then
    error("Tooltips: Addon object not initialized. Check file load order!")
    return
end

-- Create module
---@class Tooltips: AceModule, AceEvent-3.0
local TT = NorskenUI:NewModule("Tooltips", "AceEvent-3.0")

-- Localization
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local pairs = pairs
local unpack = unpack
local GetActionInfo = GetActionInfo
local GetMacroItem = GetMacroItem
local _G = _G
local GetCoinTextureString = GetCoinTextureString
local issecretvalue = issecretvalue
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitTreatAsPlayerForDisplay = UnitTreatAsPlayerForDisplay
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local UnitNameFromGUID = UnitNameFromGUID
local C_ClassColor = C_ClassColor
local IsShiftKeyDown = IsShiftKeyDown
local UnitName = UnitName
local InCombatLockdown = InCombatLockdown
local UnitIsMinion = UnitIsMinion
local UnitSelectionColor = UnitSelectionColor
local CreateColor = CreateColor

-- Module state
local isInitialized = false
local tooltipBackdrops = {}

-- Tooltips to skin
local TOOLTIPS_TO_SKIN = {
    "GameTooltip",
    "ItemRefTooltip",
    "ItemRefShoppingTooltip1",
    "ItemRefShoppingTooltip2",
    "ShoppingTooltip1",
    "ShoppingTooltip2",
    "EmbeddedItemTooltip",
    "FriendsTooltip",
    "GameSmallHeaderTooltip",
    "QuickKeybindTooltip",
    "ReputationParagonTooltip",
    "WarCampaignTooltip",
    "LibDBIconTooltip",
    "SettingsTooltip",
}

-- Custom backdrop mixin
-- This prevents errors when frame width/height become secret values
local backdropMixin = {}
function backdropMixin:SetBackgroundColor(r, g, b, a)
    if self.backdropBackground then
        self.backdropBackground:SetColorTexture(r, g, b, a)
    end
end

function backdropMixin:SetBorderColor(r, g, b, a)
    if self.backdropEdges then
        for _, edge in pairs(self.backdropEdges) do
            edge:SetColorTexture(r, g, b, a or 1)
        end
    end
end

function TT:UpdateDB()
    self.db = NRSKNUI.db.profile.Skinning.Tooltips
end

function TT:OnInitialize()
    self:UpdateDB()
    self:SetEnabledState(false)
end

-- Cached color for status bar
local cachedColor

-- Create custom backdrop for tooltip using textures
local function GetOrCreateBackdrop(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end

    if tooltipBackdrops[tooltip] then
        return tooltipBackdrops[tooltip]
    end

    -- Mixin custom backdrop methods
    Mixin(tooltip, backdropMixin)
    tooltip.backdropEdges = {}

    -- Create border textures using point-based positioning
    local borderLeft = tooltip:CreateTexture(nil, "BORDER")
    borderLeft:SetPoint("TOPLEFT", tooltip, "TOPLEFT", -1, 1)
    borderLeft:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", -1, -1)
    borderLeft:SetWidth(1)
    tooltip.backdropEdges.left = borderLeft
    NRSKNUI:PixelPerfect(borderLeft)

    local borderTop = tooltip:CreateTexture(nil, "BORDER")
    borderTop:SetPoint("TOPLEFT", tooltip, "TOPLEFT", -1, 1)
    borderTop:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", 1, 1)
    borderTop:SetHeight(1)
    tooltip.backdropEdges.top = borderTop
    NRSKNUI:PixelPerfect(borderTop)

    local borderRight = tooltip:CreateTexture(nil, "BORDER")
    borderRight:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", 1, 1)
    borderRight:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 1, -1)
    borderRight:SetWidth(1)
    tooltip.backdropEdges.right = borderRight
    NRSKNUI:PixelPerfect(borderRight)

    local borderBottom = tooltip:CreateTexture(nil, "BORDER")
    borderBottom:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", -1, -1)
    borderBottom:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 1, -1)
    borderBottom:SetHeight(1)
    tooltip.backdropEdges.bottom = borderBottom
    NRSKNUI:PixelPerfect(borderBottom)

    -- Create background texture
    local background = tooltip:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(tooltip)
    tooltip.backdropBackground = background
    NRSKNUI:PixelPerfect(background)

    -- Set default colors
    tooltip:SetBackgroundColor(0, 0, 0, 0.8)
    tooltip:SetBorderColor(0, 0, 0, 1)

    tooltipBackdrops[tooltip] = tooltip
    return tooltip
end

-- Hide default NineSlice border
local function HideNineSlice(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end

    if tooltip.NineSlice then
        tooltip.NineSlice:SetAlpha(0)
        tooltip.NineSlice:Hide()
    end

    if tooltip.SetBackdrop then
        tooltip:SetBackdrop(nil)
    end
    if tooltip.SetBackdropColor then
        tooltip:SetBackdropColor(0, 0, 0, 0)
    end
    if tooltip.SetBackdropBorderColor then
        tooltip:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

-- Hide status bar
local hookedStatusBars = {}
local function HideStatusBar(statusBar)
    if not statusBar or hookedStatusBars[statusBar] then return end

    statusBar:Hide()
    statusBar:SetAlpha(0)
    hooksecurefunc(statusBar, "Show", function(self)
        self:Hide()
    end)
    hookedStatusBars[statusBar] = true
end

-- Style a tooltip
local function StyleTooltip(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end

    HideNineSlice(tooltip)
    GetOrCreateBackdrop(tooltip)

    -- Hide status bar
    if tooltip.StatusBar then
        HideStatusBar(tooltip.StatusBar)
    end
end

-- Hook tooltip OnShow
local hookedTooltips = {}
local function HookTooltip(tooltip)
    if not tooltip or tooltip:IsForbidden() or hookedTooltips[tooltip] then return end

    tooltip:HookScript("OnShow", function(self)
        if self:IsForbidden() then return end
        HideNineSlice(self)
        GetOrCreateBackdrop(self)
    end)

    hookedTooltips[tooltip] = true
end

-- Register line processors for unit tooltips
local function RegisterTooltipProcessors()
    local NAME_REALM_FORMAT = "%s |cff777777(%s)|r"

    -- Unit name line, class color and realm handling
    TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.UnitName, function(tooltip, data)
        if tooltip:IsForbidden() or not tooltip:IsTooltipType(Enum.TooltipDataType.Unit) then
            return
        end

        local _, unit, guid = tooltip:GetUnit()
        if not guid then
            return
        end

        local name, realm

        if issecretvalue(unit) then
            local _, classToken = GetPlayerInfoByGUID(guid)
            name, realm = UnitNameFromGUID(guid)

            if classToken ~= nil then
                cachedColor = C_ClassColor.GetClassColor(classToken)
            else
                cachedColor = data.leftColor
            end
        elseif unit ~= nil then
            if UnitIsPlayer(unit) or UnitTreatAsPlayerForDisplay(unit) then
                local _, classToken = UnitClass(unit)
                cachedColor = C_ClassColor.GetClassColor(classToken)
                name, realm = UnitNameFromGUID(guid)
            elseif UnitIsMinion(unit) then
                cachedColor = CreateColor(UnitSelectionColor(unit, true))
            else
                cachedColor = data.leftColor
            end
        end

        -- Add the name line with proper color
        if realm ~= nil then
            tooltip:AddLine(NAME_REALM_FORMAT:format(name, realm), cachedColor:GetRGB())
        elseif name ~= nil then
            tooltip:AddLine(name, cachedColor:GetRGB())
        else
            tooltip:AddLine(data.leftText, (cachedColor or data.leftColor):GetRGB())
        end

        return true -- Replace the original line
    end)

    TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.UnitOwner, function(tooltip, data)
        if tooltip:IsForbidden() or not tooltip:IsTooltipType(Enum.TooltipDataType.Unit) then
            return
        end

        tooltip:AddLine(data.leftText, 0.5, 0.5, 0.5)
        return true
    end)

    TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.UnitThreat, function(tooltip)
        if not tooltip:IsForbidden() then
            return true
        end
    end)
end

-- Set custom fonts
local function SetTooltipFonts()
    local font = NRSKNUI.FONT or "Fonts\\FRIZQT__.TTF"

    for _, fontStringName in pairs({
        "GameTooltipHeaderText",
        "GameTooltipText",
        "GameTooltipTextSmall",
    }) do
        local fontString = _G[fontStringName]
        if fontString then
            fontString:SetShadowOffset(0, 0)

            if fontStringName ~= "GameTooltipHeaderText" then
                fontString:SetFont(font, 13, "OUTLINE")
            else
                fontString:SetFont(font, 16, "OUTLINE")
            end
        end
    end
end

-- Tooltip IDs (shown when holding shift)
local PREFIXES = {
    item = ENCOUNTER_JOURNAL_ITEM,
    spell = STAT_CATEGORY_SPELL,
    currency = CURRENCY,
    mount = MOUNT,
    macro = MACRO,
    npc = PROF_CRAFTING_ORDER_TYPE_NPC:upper(),
    age = "Age",
    quest = TRANSMOG_SOURCE_2,
    caster = SPELL_TARGET_CENTER_CASTER:gsub("^%l", string.upper),
}

local SUFFIXES = {
    item = ID,
    spell = ID,
    currency = ID,
    mount = ID,
    macro = NAME,
    npc = ID,
    quest = ID,
}

local LINE_FORMAT = "%s: |cff93ccea%s|r"
local function addTooltipLine(tooltip, kind, value, forced)
    if tooltip:IsForbidden() or not (forced or IsShiftKeyDown()) then
        return
    end

    local prefix = PREFIXES[kind] or ID
    local suffix = SUFFIXES[kind]
    if suffix then
        tooltip:AddLine(LINE_FORMAT:format(prefix .. " " .. suffix, value or UNKNOWN))
    else
        tooltip:AddLine(LINE_FORMAT:format(prefix, value or UNKNOWN))
    end

    return true
end

local dataTypeHandlers = {}

function dataTypeHandlers:Item(data)
    addTooltipLine(self, "item", data.id)
end

function dataTypeHandlers:Spell(data)
    addTooltipLine(self, "spell", data.id)
end

function dataTypeHandlers:Currency(data)
    addTooltipLine(self, "currency", data.id)
end

function dataTypeHandlers:Mount(data)
    if data.id then
        local _, spellID = C_MountJournal.GetMountInfoByID(data.id)
        if spellID then
            addTooltipLine(self, "mount", data.id)
            addTooltipLine(self, "spell", spellID)
        end
    end
end

function dataTypeHandlers:PetAction(data)
    for _, line in pairs(data.lines) do
        if line.tooltipID then
            addTooltipLine(self, "spell", line.tooltipID)
            break
        end
    end
end

function dataTypeHandlers:Macro()
    if self.processingInfo and self.processingInfo.getterName == "GetAction" then
        local actionID = unpack(self.processingInfo.getterArgs)
        local actionText = C_ActionBar.GetActionText(actionID)
        addTooltipLine(self, "macro", actionText)

        local _, macroActionID, macroActionType = GetActionInfo(actionID)
        if macroActionType == "spell" then
            addTooltipLine(self, macroActionType, macroActionID)
        elseif macroActionType == "" then
            if C_Macro.GetMacroName(macroActionID) == actionText then
                local _, itemLink = GetMacroItem(macroActionID)
                if itemLink then
                    addTooltipLine(self, "item", C_Item.GetItemIDForItemInfo(itemLink))
                end
            end
        end
    end
end

dataTypeHandlers.Corpse = dataTypeHandlers.Unit
dataTypeHandlers.Toy = dataTypeHandlers.Item

do
    local getters = {
        GetUnitAura = C_UnitAuras.GetAuraDataByIndex,
        GetUnitAuraByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID,
        GetUnitBuff = C_UnitAuras.GetBuffDataByIndex,
        GetUnitBuffByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID,
        GetUnitDebuff = C_UnitAuras.GetDebuffDataByIndex,
        GetUnitDebuffByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID,
    }

    function dataTypeHandlers:UnitAura(data)
        if data.id then
            local getter = getters[self.processingInfo.getterName]
            if getter then
                local auraInfo = getter(unpack(self.processingInfo.getterArgs))
                if auraInfo and auraInfo.sourceUnit then
                    local name = UnitName(auraInfo.sourceUnit)

                    if not issecretvalue(auraInfo.sourceUnit) then
                        local _, classToken = UnitClass(auraInfo.sourceUnit)
                        if classToken then
                            name = C_ClassColor.GetClassColor(classToken):WrapTextInColorCode(name)
                        end
                    end

                    self:AddLine(" ")
                    addTooltipLine(self, "caster", name, true)
                end
            end

            addTooltipLine(self, "spell", data.id)
        end
    end
end

local function RegisterIDProcessors()
    for dataType, key in pairs(Enum.TooltipDataType) do
        if dataTypeHandlers[dataType] then
            TooltipDataProcessor.AddTooltipPostCall(key, dataTypeHandlers[dataType])
        end
    end
end

-- Shift key handler to refresh tooltip
local function OnModifierStateChanged(_, key)
    if InCombatLockdown() then return end
    if key ~= "LSHIFT" and key ~= "RSHIFT" then return end

    if GameTooltip:IsShown() and not GameTooltip:IsForbidden() then
        local _, unit = GameTooltip:GetUnit()
        if not unit or not issecretvalue(unit) then
            GameTooltip:RefreshData()
        end
    end
end

-- Create anchor frame
function TT:CreateTooltipAnchorFrame()
    local TTAnchor = CreateFrame("Frame", "NRSKNUI_ToolTipAnchorFrame", UIParent)
    TTAnchor:SetSize(170, 60)
    TTAnchor:ClearAllPoints()
    TTAnchor:SetPoint(
        self.db.Position.AnchorFrom,
        UIParent,
        self.db.Position.AnchorTo,
        self.db.Position.XOffset,
        self.db.Position.YOffset
    )
    TTAnchor:SetClampedToScreen(true)

    self.TTAnchor = TTAnchor
    return TTAnchor
end

-- Anchor tooltip to our frame
function TT:AnchorTooltip(tooltip)
    if not tooltip or tooltip:IsForbidden() then return end
    tooltip:ClearAllPoints()
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetPoint("BOTTOMRIGHT", self.TTAnchor, "BOTTOMRIGHT", 0, 0)
end

-- Disable edit mode for tooltips
local function DisableTooltipEditMode()
    if GameTooltipDefaultContainer then
        GameTooltipDefaultContainer.SetIsInEditMode = nop
        GameTooltipDefaultContainer.OnEditModeEnter = nop
        GameTooltipDefaultContainer.OnEditModeExit = nop
        GameTooltipDefaultContainer.HasActiveChanges = nop
        GameTooltipDefaultContainer.HighlightSystem = nop
        GameTooltipDefaultContainer.SelectSystem = nop
        GameTooltipDefaultContainer.system = nil
    end
end

-- Skin QueueStatusFrame
local function SkinQueueStatus()
    local frame = QueueStatusFrame
    if not frame then return end

    local children = { frame:GetChildren() }
    local borderFrame = children[1]

    if borderFrame then
        for _, region in pairs({ borderFrame:GetRegions() }) do
            region:SetAlpha(0)
            region:Hide()
        end
        hooksecurefunc(borderFrame, "Show", function(self)
            for _, region in pairs({ self:GetRegions() }) do
                region:SetAlpha(0)
                region:Hide()
            end
        end)
    end

    GetOrCreateBackdrop(frame)

    frame:HookScript("OnShow", function(self)
        if borderFrame then
            for _, region in pairs({ borderFrame:GetRegions() }) do
                region:SetAlpha(0)
                region:Hide()
            end
        end
        GetOrCreateBackdrop(self)
    end)
end

function TT:Refresh()
    for _, tooltipName in pairs(TOOLTIPS_TO_SKIN) do
        local tooltip = _G[tooltipName]
        if tooltip then
            HookTooltip(tooltip)
            StyleTooltip(tooltip)
        end
    end
end

function TT:ApplySettings()
    if NRSKNUI:ShouldNotLoadModule() then return end
    self:Refresh()
end

function TT:OnEnable()
    if NRSKNUI:ShouldNotLoadModule() then return end
    if not self.db.Enabled then return end
    if isInitialized then return end

    -- Override SetTooltipMoney to fix frame errors
    function SetTooltipMoney(frame, money, type, prefixText, suffixText)
        frame:AddLine((prefixText or "") .. "  " .. GetCoinTextureString(money) .. " " .. (suffixText or ""), 0, 1, 1)
    end

    TT:CreateTooltipAnchorFrame()
    TT:Refresh()
    SkinQueueStatus()
    RegisterTooltipProcessors()
    RegisterIDProcessors()
    SetTooltipFonts()

    -- Register shift key handler
    self:RegisterEvent("MODIFIER_STATE_CHANGED", OnModifierStateChanged)

    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip)
        TT:AnchorTooltip(tooltip)
    end)

    C_Timer.After(0.5, DisableTooltipEditMode)

    -- Register with edit mode
    local config = {
        key = "TooltipModule",
        displayName = "Tooltip Anchor",
        frame = self.TTAnchor,
        getPosition = function()
            return self.db.Position
        end,
        setPosition = function(pos)
            self.db.Position.AnchorFrom = pos.AnchorFrom
            self.db.Position.AnchorTo = pos.AnchorTo
            self.db.Position.XOffset = pos.XOffset
            self.db.Position.YOffset = pos.YOffset

            self.TTAnchor:ClearAllPoints()
            self.TTAnchor:SetPoint(pos.AnchorFrom, UIParent, pos.AnchorTo, pos.XOffset, pos.YOffset)
        end,
        getParentFrame = function()
            return UIParent
        end,
        guiPath = "tooltips",
    }
    NRSKNUI.EditMode:RegisterElement(config)

    isInitialized = true
end
