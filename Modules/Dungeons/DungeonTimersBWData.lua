---@class NRSKNUI
local NRSKNUI = select(2, ...)

if not NorskenUI then return end

---@class DungeonTimers
local DT = NorskenUI:GetModule("DungeonTimers")
if not DT then return end

local GetTime = GetTime
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local type = type
local table_insert = table.insert
local C_Spell = C_Spell

function DT:RegisterBigWigsCallbacks()
    if not BigWigsLoader then return false end
    for _, event in ipairs(NRSKNUI.BIGWIGS_EVENTS) do
        BigWigsLoader.RegisterMessage(self, event, "EventCallback")
    end
    return true
end

function DT:UnregisterBigWigsCallbacks()
    if not BigWigsLoader then return end
    for _, event in ipairs(NRSKNUI.BIGWIGS_EVENTS) do
        BigWigsLoader.UnregisterMessage(self, event)
    end
end

function DT:GetBigWigsColors(addon, spellId)
    local barColor, textColor, bgColor

    if BigWigs and BigWigs.GetPlugin then
        local colorModule = BigWigs:GetPlugin("Colors")
        if colorModule and colorModule.GetColorTable then
            barColor = colorModule:GetColorTable("barColor", addon, spellId)
            textColor = colorModule:GetColorTable("barText", addon, spellId)
            bgColor = colorModule:GetColorTable("barBackground", addon, spellId)
        end
    end

    return barColor, textColor, bgColor
end

function DT:CreateBarData(addon, spellId, duration, text, count, icon)
    local barColor, textColor, bgColor = self:GetBigWigsColors(addon, spellId)

    local spellName, spellIcon
    local spellIdNum = tonumber(spellId)
    if spellIdNum and spellIdNum > 0 then
        local spellInfo = C_Spell.GetSpellInfo(spellIdNum)
        if spellInfo then
            spellName = spellInfo.name
            spellIcon = spellInfo.iconID
        end
    end

    return {
        addon = addon,
        spellId = tostring(spellId or ""),
        text = text or "",
        duration = duration or 0,
        expirationTime = GetTime() + (duration or 0),
        icon = icon or spellIcon,
        count = count or 0,
        paused = nil,
        pausedTime = nil,
        bwBarColor = barColor,
        bwTextColor = textColor,
        bwBgColor = bgColor,
        spellName = spellName,
    }
end

function DT:EventCallback(event, ...)
    if event == "BigWigs_Timer" or event == "BigWigs_TargetTimer" or event == "BigWigs_CastTimer" then
        local addon, spellId, duration, _, text, count, icon = ...
        local barData = self:CreateBarData(addon, spellId, duration, text, count, icon)
        self:ProcessTimerTriggers(barData)
    elseif event == "BigWigs_StartBreak" then
        local addon, duration, _, _, _, text, icon = ...
        local barData = self:CreateBarData(addon, -1, duration, text or "Break", 0, icon)
        self:ProcessTimerTriggers(barData)
    elseif event == "BigWigs_StartPull" then
        local addon, duration, _, text, icon = ...
        local barData = self:CreateBarData(addon, -2, duration, text or "Pull", 0, icon or 136116)
        self:ProcessTimerTriggers(barData)
    elseif event == "BigWigs_StopBar" then
        local _, text = ...
        self:StopBar(text)
    elseif event == "BigWigs_StopBars" or event == "BigWigs_OnBossDisable" then
        self:StopAllBars()
    elseif event == "BigWigs_PauseBar" then
        local _, text = ...
        self:PauseBar(text)
    elseif event == "BigWigs_ResumeBar" then
        local _, text = ...
        self:ResumeBar(text)
    end
end

function DT:GetBigWigsModulesForInstance(instanceId)
    local modules = {}
    if not BigWigs or not BigWigs.IterateBossModules then return modules end

    for _, module in BigWigs:IterateBossModules() do
        if module.instanceId == instanceId then
            table_insert(modules, module)
        end
    end

    return modules
end

function DT:GetSpellsForDungeon(dungeonKey, forceRefresh)
    self:UpdateDB()
    if not self.db or not self.db.Dungeons then return {} end

    local dungeonData = self.db.Dungeons[dungeonKey]
    if not dungeonData or not dungeonData.instanceId then return {} end

    if not forceRefresh and self.spellCache[dungeonKey] then
        return self.spellCache[dungeonKey]
    end

    if BigWigsLoader and BigWigsLoader.LoadZone then
        BigWigsLoader:LoadZone(dungeonData.instanceId)
    end

    local spells = {}
    local seenSpells = {}
    local modules = self:GetBigWigsModulesForInstance(dungeonData.instanceId)
    local bossOrder = {}

    for _, module in ipairs(modules) do
        if module.GetOptions then
            local sortKey = module.journalId or module.engageId or 999999
            table_insert(bossOrder, {
                module = module,
                sortKey = sortKey,
                name = module.displayName or module.moduleName,
            })
        end
    end
    table.sort(bossOrder, function(a, b) return a.sortKey < b.sortKey end)

    for i, boss in ipairs(bossOrder) do
        local options = boss.module:GetOptions()
        if options then
            for _, option in ipairs(options) do
                local spellId
                if type(option) == "number" then
                    spellId = option
                elseif type(option) == "table" and type(option[1]) == "number" then
                    spellId = option[1]
                end

                if spellId and spellId > 0 and not seenSpells[spellId] then
                    seenSpells[spellId] = true
                    local spellInfo = C_Spell.GetSpellInfo(spellId)
                    if spellInfo then
                        table_insert(spells, {
                            spellId = spellId,
                            name = spellInfo.name,
                            icon = spellInfo.iconID,
                            bossName = boss.name,
                            bossNum = i,
                            sortKey = boss.sortKey,
                        })
                    end
                end
            end
        end
    end

    table.sort(spells, function(a, b)
        if a.sortKey ~= b.sortKey then
            return a.sortKey < b.sortKey
        end
        return a.name < b.name
    end)

    if #spells > 0 then
        self.spellCache[dungeonKey] = spells
    end

    return spells
end
