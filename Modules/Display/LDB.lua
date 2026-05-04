---
-- LDB (LibDataBroker) subsystem for DisplayModule.
-- Provides the data source text and timer objects.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local DisplayModule = XToLevel:GetModule("DisplayModule")

local L = addonTable.GetLocale()
local Helpers = _XToLevel.Helpers
local Constants = _XToLevel.Constants

-- LDB state
DisplayModule.LDB = {
    textPatterns = {
        default = "{kills}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/kills}{quests}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/quests}{dungeons}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/dungeons}{bgs}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/bgs}{bgo}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/bgo}{gather}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/gather}{digs}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/digs}{xp}{$seperator: }{progress}[{$value}]{/progress}{/xp}",
        minimal = "{kills}{progress}{$value}{/progress}{/kills}{quests}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/quests}{dungeons}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/dungeons}{bgs}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/bgs}{xp}{color=cfcfdf}{$seperator:/}{/color}{progress}{$value}{/progress}{/xp}",
        minimal_dashed = "{kills}{progress}{$value}{/progress}{/kills}{quests}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/quests}{dungeons}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/dungeons}{bgs}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/bgs}{xp}{color=cfcfdf}{$seperator:-}{/color}{progress}{$value}{/progress}{/xp}",
        brackets = "{kills}{progress}[{$value}]{/progress}{/kills}{quests}{progress}[{$value}]{/progress}{/quests}{dungeons}{progress}[{$value}]{/progress}{/dungeons}{bgs}{progress}[{$value}]{/progress}{/bgs}{xp}{progress}[{$value}]{/progress}{/xp}",
        countdown = "{xpnum}{color=cfcfdf}XP:{/color}{$seperator: }{progress}{$value}{/progress}{xp} {color=cfcfdf}({/color}{progress}{$value}{/progress}{color=cfcfdf}){/color}{/xp}{$seperator: }{/xpnum}{rested}{color=cfcfdf}R:{/color}{$seperator: }{progress}{$value}{/progress} {restedp}{color=cfcfdf}({/color}{progress}{$value}{/progress}{color=cfcfdf}){/color}{/restedp}{$seperator: }{/rested}",
    },
    textTags = {},
    dataObject = nil,
    mouseOver = false,
    currentPattern = nil,
    timerObject = nil,
    timerMouseOver = false,
    timerLabelShown = true,
}

function DisplayModule:InitializeLDB()
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()

    if not db.profile.ldb.enabled or (PlayerModule:GetMaxLevel() == PlayerModule.level and PlayerModule:GetClass() ~= "HUNTER") then
        return
    end

    -- Modify default patterns for Classic
    if Helpers:IsClassic() then
        self.LDB.textPatterns.default = "{kills}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/kills}{quests}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/quests}{dungeons}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/dungeons}{bgs}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/bgs}{bgo}{$seperator: }{color=cfcfdf}{$label}:{/color} {progress}{$value}{/progress}{/bgo}{xp}{$seperator: }{progress}[{$value}]{/progress}{/xp}"
    end

    self.LDB.timerLabelShown = db.profile.ldb.showLabel

    -- Initialize the data object
    local iconName = (UnitFactionGroup("player") == "Alliance") and "INV_Jewelry_TrinketPVP_01" or "INV_Jewelry_TrinketPVP_02"
    local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
    self.LDB.dataObject = ldb:NewDataObject("XToLevel", {
        type = "data source",
        icon = "Interface\\Icons\\" .. iconName,
        text = "XToLevel",
        label = db.profile.ldb.showLabel and L["XToLevel"] or nil,
        version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown",
        align = "right",
        ["X-Category"] = "Information"
    })

    local selfRef = self
    function self.LDB.dataObject:OnEnter()
        selfRef.LDB.mouseOver = true
        local a1, f1, a2 = Helpers:FindAnchor(self)
        selfRef:TooltipShow(self, a1, f1, a2, L['Click To Configure'])
    end
    function self.LDB.dataObject:OnLeave()
        selfRef.LDB.mouseOver = false
        selfRef:TooltipHide()
    end
    function self.LDB.dataObject:OnClick(button)
        local ConfigModule = XToLevel:GetModule("ConfigModule")
        ConfigModule:Open("LDB")
    end

    self:LDBBuildPattern()
    self:LDBUpdate()
    self:InitializeLDBTimer()
end

function DisplayModule:InitializeLDBTimer()
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()

    if not db.profile.ldb.enabled or (PlayerModule:GetMaxLevel() == PlayerModule.level and PlayerModule:GetClass() ~= "HUNTER") then
        return
    end

    local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
    self.LDB.timerObject = ldb:NewDataObject("TimeToLevel", {
        type = "data source",
        icon = "Interface\\Icons\\inv_misc_pocketwatch_01",
        text = L["Updating..."],
        label = db.profile.ldb.showLabel and L["TimeToLevel"] or nil,
        version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown",
        align = "right",
        ["X-Category"] = "Information"
    })

    local selfRef = self
    function self.LDB.timerObject:OnEnter()
        selfRef.LDB.timerMouseOver = true
        local a1, f1, a2 = Helpers:FindAnchor(self)
        selfRef:TooltipShow(self, a1, f1, a2, L['Click To Configure'], "timer")
    end
    function self.LDB.timerObject:OnLeave()
        selfRef.LDB.timerMouseOver = false
        selfRef:TooltipHide()
    end
    function self.LDB.timerObject:OnClick(button)
        local ConfigModule = XToLevel:GetModule("ConfigModule")
        ConfigModule:Open("Timer")
    end

    self:LDBUpdateTimer()
end

function DisplayModule:LDBBuildPattern()
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()

    if PlayerModule.level < PlayerModule.maxLevel then
        local showPlayer = PlayerModule.isActive and (PlayerModule.level < PlayerModule.maxLevel)
        local useColors = (db.profile.ldb.allowTextColor and db.profile.ldb.text.colorValues)

        -- Load the appropriate pattern
        local newText = self.LDB.textPatterns.default
        if db.profile.ldb.textPattern ~= nil then
            if db.profile.ldb.textPattern == "custom" then
                newText = db.char.customPattern or "Please choose a pattern."
                -- Parse html-like syntax
                newText = string.gsub(newText, '<(%w+) ?(.-)>', function(tag, attr)
                    local attributes = { label = false, post = false, seperator = false }
                    for key, _ in pairs(attributes) do
                        local sPos, ePos, value = string.find(attr, key ..'="([^"]-)"')
                        if value ~= nil then
                            attributes[key] = value
                        end
                    end
                    local out = "{".. tag .."}"
                    if attributes.seperator then
                        out = out .. "{$seperator:" .. attributes.seperator .."}"
                    end
                    if attributes.label then
                        out = out .. attributes.label ..": "
                    end
                    out = out .. "{progress}{$value}"
                    if attributes.post then
                        out = out .. attributes.post
                    end
                    out = out .. "{/progress}{/" .. tag .."}"
                    return out
                end)
            else
                newText = self.LDB.textPatterns[db.profile.ldb.textPattern] or newText
            end
        end

        -- Replace {color} tags
        if db.profile.ldb.allowTextColor then
            newText = string.gsub(newText, "{color=([0-9A-Fa-f]+)}(.-){/color}", "|cFF%1%2|r")
        else
            newText = string.gsub(newText, "{color=[0-9A-Fa-f]+}(.-){/color}", "%1")
        end

        -- Prepare tags
        self.LDB.textTags = {
            [1] = {
                tag = "kills",
                label = (db.profile.ldb.text.verbose and L["Kills"]) or L["Kills Short"],
                value = (showPlayer and '$$kills$$') or nil,
                color = (useColors and '$$playercolor$$') or nil,
            },
            [2] = {
                tag = "quests",
                label = (db.profile.ldb.text.verbose and L["Quests"]) or L["Quests Short"],
                value = (showPlayer and '$$quests$$') or nil,
                color = (useColors and '$$playercolor$$') or nil,
            },
            [3] = {
                tag = "dungeons",
                label = (db.profile.ldb.text.verbose and L["Dungeons"]) or L["Dungeons Short"],
                value = ((showPlayer and UnitLevel("Player") >= 15) and '$$dungeons$$') or nil,
                color = (useColors and '$$playercolor$$') or nil,
            },
            [4] = {
                tag = "bgs",
                label = (db.profile.ldb.text.verbose and L["Battles"]) or L["Battles Short"],
                value = ((showPlayer and UnitLevel("Player") >= 10) and '$$bgs$$') or nil,
                color = (useColors and '$$playercolor$$') or nil,
            },
            [5] = {
                tag = "bgo",
                label = (db.profile.ldb.text.verbose and L["Objectives"]) or L["Objectives Short"],
                value = ((showPlayer and UnitLevel("Player") >= 10) and '$$bgo$$') or nil,
                color = (useColors and '$$playercolor$$') or nil,
            },
            [6] = {
                tag = "gather",
                label = (db.profile.ldb.text.verbose and L["Gathering"]) or L["Gathering Short"],
                value = (showPlayer and '$$gather$$') or nil,
                color = (useColors and '$$playercolor$$') or nil,
            },
            [7] = {
                tag = "digs",
                label = (db.profile.ldb.text.verbose and L["Digs"]) or L["Digs Short"],
                value = (showPlayer and '$$digs$$') or nil,
                color = (useColors and '$$playercolor$$') or nil,
            },
            [8] = {
                tag = "xp",
                label = L["XP"],
                value = (showPlayer and '$$xp$$') or nil,
                color = (db.profile.ldb.allowTextColor and '$$playercolor$$') or nil,
            },
            [9] = {
                tag = "restedp",
                label = (db.profile.ldb.text.verbose and L["Rested"]) or L["Rested Short"],
                value = (showPlayer and '$$restedp$$') or nil,
                color = (db.profile.ldb.allowTextColor and '$$playercolor$$') or nil,
            },
            [10] = {
                tag = "rested",
                label = (db.profile.ldb.text.verbose and L["Rested"]) or L["Rested Short"],
                value = (showPlayer and '$$rested$$') or nil,
                color = (useColors and '$$playercolor$$') or nil,
            },
            [11] = {
                tag = "xpnum",
                label = (db.profile.ldb.text.verbose and L["XP"]) or L["XP"],
                value = (showPlayer and '$$xpnum$$') or nil,
                color = (useColors and '$$playercolor$$') or nil,
            },
            [12] = {
                tag = "guildxp",
                label = (db.profile.ldb.text.verbose and "Guild XP") or "GXP",
                value = (showPlayer and '$$guildxp$$') or nil,
                color = (useColors and '$$guildcolor$$') or nil,
            },
            [13] = {
                tag = "guilddaily",
                label = (db.profile.ldb.text.verbose and "Guild Daily") or "GDXP",
                value = (showPlayer and '$$guilddaily$$') or nil,
                color = (useColors and '$$guilddailycolor$$') or nil,
            },
        }

        -- Replace tag values
        local isFirst = true
        for i, object in ipairs(self.LDB.textTags) do
            if db.profile.ldb.text[object.tag] and object.value ~= nil then
                newText = string.gsub(newText, "{".. object.tag .."}(.-){/".. object.tag .."}", function(str)
                    str = string.gsub(str, "{$label}", object.label)
                    str = string.gsub(str, "{$value}", object.value)
                    if object.color ~= nil then
                        str = string.gsub(str, "{progress}(.-){/progress}", "|cFF".. object.color .."%1|r")
                    else
                        str = string.gsub(str, "{progress}(.-){/progress}", "%1")
                    end
                    if isFirst then
                        str = string.gsub(str, "{$seperator(.-)}", "")
                    else
                        str = string.gsub(str, "{$seperator:?(.-)}", "%1")
                    end
                    return str
                end)
                isFirst = false
            else
                newText = string.gsub(newText, "{".. object.tag .."}.-{/".. object.tag .."}", '')
            end
        end
        self.LDB.currentPattern = newText
    else
        if db.profile.ldb.customColors then
            self.LDB.currentPattern = "|cFFaaaaaaInactive|r"
        else
            self.LDB.currentPattern = "Inactive"
        end
    end
end

function DisplayModule:LDBUpdate()
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()

    if self.LDB.dataObject == nil then
        return false
    end

    if db.profile.ldb.showLabel then
        self.LDB.dataObject.label = L["XToLevel"]
    else
        self.LDB.dataObject.label = nil
    end

    if db.profile.ldb.showIcon then
        local iconName = (UnitFactionGroup("player") == "Alliance") and "INV_Jewelry_TrinketPVP_01" or "INV_Jewelry_TrinketPVP_02"
        self.LDB.dataObject.icon = "Interface\\Icons\\" .. iconName
    else
        self.LDB.dataObject.icon = nil
    end

    if db.profile.ldb.showText then
        local pattern = self.LDB.currentPattern
        if PlayerModule.level < PlayerModule:GetMaxLevel() then
            local playerProgress = PlayerModule:GetProgressAsPercentage(0)
            local playerProgressColor = Helpers:GetProgressColor_Soft(playerProgress)

            pattern = string.gsub(pattern, '%$%$playercolor%$%$', playerProgressColor)
            pattern = string.gsub(pattern, '%$%$kills%$%$', (Helpers:round(PlayerModule:GetAverageKillsRemaining()) or "~"))
            pattern = string.gsub(pattern, '%$%$quests%$%$', (Helpers:round(PlayerModule:GetAverageQuestsRemaining()) or "~"))
            pattern = string.gsub(pattern, '%$%$dungeons%$%$', (Helpers:round(PlayerModule:GetAverageDungeonsRemaining()) or "~"))

            if db.profile.ldb.text.xpAsBars then
                pattern = string.gsub(pattern, '%$%$xp%$%$', tostring(PlayerModule:GetProgressAsBars()) .. " " .. L['Bars'])
            else
                local progressDisplay = playerProgress
                if db.profile.ldb.text.xpCountdown then
                    progressDisplay = 100 - playerProgress
                    if progressDisplay < 1 then
                        progressDisplay = '<1'
                    end
                end
                pattern = string.gsub(pattern, '%$%$xp%$%$', progressDisplay .. "%%")
            end

            local xpnum = db.profile.ldb.text.xpCountdown and PlayerModule:GetXpRemaining() or PlayerModule.currentXP
            xpnum = db.profile.ldb.text.xpnumFormat and Helpers:ShrinkNumber(xpnum) or Helpers:round(xpnum)
            pattern = string.gsub(pattern, '%$%$xpnum%$%$', xpnum)

            pattern = string.gsub(pattern, '%$%$bgs%$%$', (Helpers:round(PlayerModule:GetAverageBGsRemaining()) or "~"))
            pattern = string.gsub(pattern, '%$%$bgo%$%$', (Helpers:round(PlayerModule:GetAverageBGObjectivesRemaining()) or "~"))

            local gathering = PlayerModule:GetGatheringRequired()
            local digs = PlayerModule:GetDigsRequired()
            pattern = string.gsub(pattern, '%$%$gather%$%$', (Helpers:round(gathering) or "~"))
            pattern = string.gsub(pattern, '%$%$digs%$%$', (Helpers:round(digs) or "~"))

            if db.profile.ldb.text.xpnumFormat then
                pattern = string.gsub(pattern, '%$%$rested%$%$', (Helpers:ShrinkNumber(PlayerModule.restedXP) or "~"))
            else
                pattern = string.gsub(pattern, '%$%$rested%$%$', (Helpers:round(PlayerModule.restedXP) or "~"))
            end
            if db.profile.ldb.text.xpAsBars then
                local restedbars = Helpers:round(Helpers:round(PlayerModule:GetRestedPercentage()) / 5, 0, false)
                pattern = string.gsub(pattern, '%$%$restedp%$%$', restedbars .. " " .. L['Bars'])
            else
                pattern = string.gsub(pattern, '%$%$restedp%$%$', (Helpers:round(PlayerModule:GetRestedPercentage(1)) .. "%%" or "~"))
            end

            if type(PlayerModule.guildXP) == 'number' then
                local guildProgress = Helpers:round(PlayerModule.guildXP / PlayerModule.guildXPMax * 100, 1)
                local guildProgressColor = Helpers:GetProgressColor_Soft(ceil(guildProgress))
                pattern = string.gsub(pattern, '%$%$guildcolor%$%$', guildProgressColor)
                pattern = string.gsub(pattern, '%$%$guildxp%$%$', tostring(guildProgress) .. "%%")

                local guildDailyProgress = PlayerModule:GetGuildDailyProgressAsPercentage(1)
                local guildDailyColor = Helpers:GetProgressColor_Soft(ceil(guildDailyProgress))
                pattern = string.gsub(pattern, '%$%$guilddailycolor%$%$', guildDailyColor)
                pattern = string.gsub(pattern, '%$%$guilddaily%$%$', tostring(guildDailyProgress) .. "%%")
            else
                pattern = string.gsub(pattern, '%$%$guildcolor%$%$', "AAAAAA")
                pattern = string.gsub(pattern, '%$%$guildxp%$%$', "N/A")
                pattern = string.gsub(pattern, '%$%$guilddailycolor%$%$', "AAAAAA")
                pattern = string.gsub(pattern, '%$%$guilddaily%$%$', "N/A")
            end
        else
            pattern = string.gsub(pattern, '%$%$playercolor%$%$', '')
            pattern = string.gsub(pattern, '%$%$kills%$%$', '')
            pattern = string.gsub(pattern, '%$%$quests%$%$', '')
            pattern = string.gsub(pattern, '%$%$dungeons%$%$', '')
            pattern = string.gsub(pattern, '%$%$xp%$%$', '')
            pattern = string.gsub(pattern, '%$%$xpnum%$%$', '')
            pattern = string.gsub(pattern, '%$%$bgs%$%$', '')
            pattern = string.gsub(pattern, '%$%$bgo%$%$', '')
            pattern = string.gsub(pattern, '%$%$gather%$%$', '')
            pattern = string.gsub(pattern, '%$%$digs%$%$', '')
            pattern = string.gsub(pattern, '%$%$rested%$%$', '')
            pattern = string.gsub(pattern, '%$%$restedp%$%$', '')
            pattern = string.gsub(pattern, '%$%$guildxp%$%$', "")
            pattern = string.gsub(pattern, '%$%$guilddaily%$%$', "")
        end
        self.LDB.dataObject.text = pattern
    else
        self.LDB.dataObject.text = nil
    end
end

function DisplayModule:LDBUpdateTimer()
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()

    if self.LDB.timerObject == nil then
        return false
    end
    if db.profile.ldb.showLabel ~= self.LDB.timerLabelShown then
        self.LDB.timerObject.label = db.profile.ldb.showLabel and L["XToLevel"] or nil
    end
    if db.profile.timer.enabled and PlayerModule.level < PlayerModule:GetMaxLevel() then
        local mode, timeToLevel = PlayerModule:GetTimerData()
        timeToLevel = Helpers:TimeFormat(timeToLevel)
        if timeToLevel == "NaN" then
            timeToLevel = "Waiting for data..."
        end
        self.LDB.timerObject.text = timeToLevel
    else
        if db.profile.ldb.customColors then
            self.LDB.timerObject.text = "|cFFFF0000Inactive|r"
        else
            self.LDB.timerObject.text = "Inactive"
        end
    end
end
