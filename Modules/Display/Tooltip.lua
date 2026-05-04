--[[
    Copyright (C) 2008-2016 Atli Þór
    Copyright (C) 2020-2021 R4d1o4ct1v3_
    Copyright (C) 2022-2026 GurliGebis

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
]]

---
-- Tooltip subsystem for DisplayModule.
-- Handles GameTooltip display for LDB, Average frames, and NPC tooltips.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local DisplayModule = XToLevel:GetModule("DisplayModule")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Helpers = _XToLevel.Helpers

-- Tooltip state
DisplayModule.Tooltip = {
    initialized = false,
    labelColor = {},
    dataColor = {},
    footerColor = {},
    verticalMargin = 2,
    horizontalMargin = 20,
}

function DisplayModule:InitializeTooltip()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.ldb.allowTextColor then
        self.Tooltip.labelColor = { r=0.75, g=0.75, b=0.75 }
        self.Tooltip.dataColor = { r=0.9, g=1, b=0.9 }
        self.Tooltip.footerColor = { r=0.6, g=0.6, b=0.6 }
    end
    self.Tooltip.initialized = true

    if TooltipDataProcessor then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(...)
            DisplayModule:OnTooltipSetUnit(...)
        end)
    end
end

function DisplayModule:ResizeTooltip()
    local str = _G[GameTooltip:GetName() .. "TextLeft" .. GameTooltip:NumLines()]
    if str ~= nil then
        local strWidth = str:GetStringWidth()
        if issecretvalue and issecretvalue(strWidth) then
            GameTooltip:Show()
            return
        end
        local width = strWidth + self.Tooltip.horizontalMargin
        GameTooltip:SetHeight(GameTooltip:GetHeight() + str:GetStringHeight() + self.Tooltip.verticalMargin)
        if (GameTooltip:GetWidth() < width) then
            GameTooltip:SetWidth(width)
        end
    else
        GameTooltip:Show()
        console:log("DisplayModule:ResizeTooltip - Primary resize method failed, falling back on GameTooltip:Show")
    end
end

function DisplayModule:OnTooltipSetUnit(...)
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()

    if db.profile.general.showNpcTooltipData and PlayerModule.level < PlayerModule.maxLevel then
        local name, unit = GameTooltip:GetUnit()

        if issecretvalue and unit and (issecretvalue(unit) or C_Secrets.ShouldUnitHealthMaxBeSecret(unit)) then
            return nil
        end

        if unit and not UnitIsPlayer(unit) and not UnitIsFriend("player", unit) and UnitLevel(unit) > 0 and UnitLevel(unit) >= UnitLevel("player") - 5 and UnitClassification(unit) == "normal" and UnitHealthMax(unit) > -1 then
            local level = UnitLevel(unit)
            if level < PlayerModule.level - 5 or level > PlayerModule.level + 5 then
                return nil
            end

            local thexp, valueType = Helpers:MobXP(name, level)

            if thexp > 0 then
                local killsRequired = PlayerModule:GetKillsRequired(thexp)
                if killsRequired > 0 then
                    local output = killsRequired
                    local color = "888888"
                    local diff = PlayerModule.level - level
                    local percent = 50 + (diff * 10)
                    if percent <= 100 then
                        if percent < 0 then percent = 0 end
                        color = Helpers:GetProgressColor(percent)
                    end

                    if valueType == "estimate" and not Helpers:IsMopClassic() then
                        GameTooltip:AddLine("|cFFAAAAAA" .. L['Kills to level'] ..": |r |cFF" .. color .. output .. "*|r", 0.75, 0.75, 0.75)
                    else
                        GameTooltip:AddLine("|cFFAAAAAA" .. L['Kills to level'] ..": |r |cFF" .. color .. output .. "|r", 0.75, 0.75, 0.75)
                    end
                    self:ResizeTooltip()
                end
            end
        end
    end
end

function DisplayModule:TooltipShow(frame, anchorPoint, relativeFrame, relativePoint, footerText, mode)
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()

    if not self.Tooltip.initialized then
        self:InitializeTooltip()
    end

    local lc = self.Tooltip.labelColor
    local dc = self.Tooltip.dataColor
    local fc = self.Tooltip.footerColor

    GameTooltip:Hide()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    if anchorPoint ~= nil or relativeFrame ~= nil or relativePoint ~= nil then
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint(anchorPoint, relativeFrame, relativePoint)
    end
    GameTooltip:ClearLines()

    if mode == "bg" then
        GameTooltip:AddLine(L["Battlegrounds"])
        self:TooltipAddBattlegroundInfo()
        GameTooltip:AddLine(" ")
        self:TooltipAddBattles()
        GameTooltip:AddLine(" ")
    elseif mode == "kills" then
        GameTooltip:AddLine(L['Kills'])
        self:TooltipAddKillRange()
        GameTooltip:AddLine(" ")
    elseif mode == "quests" then
        GameTooltip:AddLine(L['Quests'])
        self:TooltipAddQuestRange()
        GameTooltip:AddLine(" ")
    elseif mode == "petBattles" then
        GameTooltip:AddLine(L['Pet Battles'])
        self:TooltipAddPetBattleRange()
        GameTooltip:AddLine(" ")
    elseif mode == "dungeons" then
        GameTooltip:AddLine(L['Dungeons'])
        self:TooltipAddDungeonInfo()
        GameTooltip:AddLine(" ")
        self:TooltipAddDungeons()
        GameTooltip:AddLine(" ")
    elseif mode == "gathering" then
        GameTooltip:AddLine(L['Gathering'] or "Gathering")
        self:TooltipAddGathering()
        GameTooltip:AddLine(" ")
    elseif mode == "archaeology" then
        GameTooltip:AddLine(L['Archaeology'] or "Archaeology")
        self:TooltipAddArchaeology()
        GameTooltip:AddLine(" ")
    elseif mode == "experience" then
        GameTooltip:AddLine(L['Experience'])
        self:TooltipAddExperience()
        GameTooltip:AddLine(" ")
    elseif mode == "timer" then
        GameTooltip:AddLine("Time to level")
        self:TooltipAddTimerDetails(false)
        GameTooltip:AddLine(" ")
    elseif mode == "guild" then
        GameTooltip:AddLine(L['Guild'] .. ": ")
        self:TooltipAddGuildInfo()
        GameTooltip:AddLine(" ")
    else
        -- Overall tooltip
        GameTooltip:AddLine(L["XToLevel"])
        if PlayerModule.level < PlayerModule:GetMaxLevel() then
            if db.profile.ldb.tooltip.showDetails then
                self:TooltipAddKills()
                self:TooltipAddQuests()
            end
            if Helpers:ShowDungeonData() then
                self:TooltipAddDungeonInfo()
            end
            if Helpers:ShowBattlegroundData() then
                self:TooltipAddBattlegroundInfo()
            end
            GameTooltip:AddLine(" ")
            if db.profile.ldb.tooltip.showExperience then
                GameTooltip:AddLine(L["Experience"] .. ": ")
                self:TooltipAddExperience()
                GameTooltip:AddLine(" ")
            end
            if db.profile.ldb.tooltip.showGatheringInfo and not Helpers:IsClassicEra() then
                GameTooltip:AddLine((L["Gathering"] or "Gathering") .. ": ")
                self:TooltipAddGathering()
                GameTooltip:AddLine(" ")
            end
            if db.profile.ldb.tooltip.showArchaeologyInfo and not Helpers:IsClassicEra() then
                GameTooltip:AddLine((L["Archaeology"] or "Archaeology") .. ": ")
                self:TooltipAddArchaeology()
                GameTooltip:AddLine(" ")
            end
            if Helpers:ShowDungeonData() then
                self:TooltipAddDungeons()
                GameTooltip:AddLine(" ")
            end
            if Helpers:ShowBattlegroundData() then
                self:TooltipAddBattles()
                GameTooltip:AddLine(" ")
            end
            if db.profile.timer.enabled and db.profile.ldb.tooltip.showTimerInfo then
                GameTooltip:AddLine(L["Timer"] .. ":")
                self:TooltipAddTimerDetails(true)
                GameTooltip:AddLine(" ")
            end
        else
            GameTooltip:AddLine(L['Max Level LDB Message'], 255, 255, 255)
        end
    end

    if footerText ~= nil then
        GameTooltip:AddLine(tostring(footerText), fc.r, fc.g, fc.b)
    end

    GameTooltip:Show()
end

function DisplayModule:TooltipHide()
    GameTooltip:Hide()
end

-- Helper tooltip add functions
function DisplayModule:TooltipAddKills()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor
    GameTooltip:AddDoubleLine(" " .. L["Kills"] .. ":", Helpers:NumberFormat(PlayerModule:GetAverageKillsRemaining()) .." @ ".. Helpers:NumberFormat(Helpers:round(PlayerModule:GetAverageKillXP(), 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
end

function DisplayModule:TooltipAddKillRange()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor
    local range = PlayerModule:GetKillXpRange()
    GameTooltip:AddDoubleLine(" " .. L["Average"] .. ":", Helpers:NumberFormat(PlayerModule:GetKillsRequired(range.average)) .." @ ".. Helpers:NumberFormat(Helpers:round(range.average, 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["Min"] .. ":", Helpers:NumberFormat(PlayerModule:GetKillsRequired(range.high)) .." @ ".. Helpers:NumberFormat(Helpers:round(range.high, 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["Max"] .. ":", Helpers:NumberFormat(PlayerModule:GetKillsRequired(range.low)) .." @ ".. Helpers:NumberFormat(Helpers:round(range.low, 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" ", " ", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["XP Rested"] .. ": ", Helpers:NumberFormat(PlayerModule:IsRested() or 0) .. " xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
end

function DisplayModule:TooltipAddQuests()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor
    GameTooltip:AddDoubleLine(" " .. L["Quests"] .. ":", Helpers:NumberFormat(PlayerModule:GetAverageQuestsRemaining()) .." @ ".. Helpers:NumberFormat(Helpers:round(PlayerModule:GetAverageQuestXP(), 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
end

function DisplayModule:TooltipAddQuestRange()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor
    local range = PlayerModule:GetQuestXpRange()
    GameTooltip:AddDoubleLine(" " .. L["Average"] .. ":", Helpers:NumberFormat(PlayerModule:GetQuestsRequired(range.average)) .." @ ".. Helpers:NumberFormat(Helpers:round(range.average, 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["Min"] .. ":", Helpers:NumberFormat(PlayerModule:GetQuestsRequired(range.high)) .." @ ".. Helpers:NumberFormat(Helpers:round(range.high, 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["Max"] .. ":", Helpers:NumberFormat(PlayerModule:GetQuestsRequired(range.low)) .." @ ".. Helpers:NumberFormat(Helpers:round(range.low, 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
end

function DisplayModule:TooltipAddPetBattleRange()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor
    local range = PlayerModule:GetPetBattleXpRange()
    GameTooltip:AddDoubleLine(" " .. L["Average"] .. ":", Helpers:NumberFormat(PlayerModule:GetPetBattlesRequired(range.average)) .." @ ".. Helpers:NumberFormat(Helpers:round(range.average, 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["Min"] .. ":", Helpers:NumberFormat(PlayerModule:GetPetBattlesRequired(range.high)) .." @ ".. Helpers:NumberFormat(Helpers:round(range.high, 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["Max"] .. ":", Helpers:NumberFormat(PlayerModule:GetPetBattlesRequired(range.low)) .." @ ".. Helpers:NumberFormat(Helpers:round(range.low, 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
end

function DisplayModule:TooltipAddDungeonInfo()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor
    GameTooltip:AddDoubleLine(" " .. L['Dungeons'] .. ":", Helpers:NumberFormat(PlayerModule:GetAverageDungeonsRemaining()) .." @ ".. Helpers:NumberFormat(Helpers:round(PlayerModule:GetAverageDungeonXP(), 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
end

function DisplayModule:TooltipAddDungeons()
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor

    if (#db.char.data.dungeonList) > 0 then
        local dungeons = PlayerModule:GetDungeonsListed()
        local latestData = PlayerModule:GetLatestDungeonDetails()

        if dungeons ~= nil then
            GameTooltip:AddLine(L['Dungeons Required'] .. ":")
            for name, count in pairs(dungeons) do
                if name == false then name = "Unknown" end
                local averageRaw = PlayerModule:GetDungeonAverage(name)
                if averageRaw > 0 then
                    local averageFormatted = Helpers:NumberFormat(Helpers:round(averageRaw, 0))
                    local needed = PlayerModule:GetKillsRequired(tonumber(averageRaw))
                    GameTooltip:AddDoubleLine(" ".. name .. ": ", needed .. " @ ".. averageFormatted .. " xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
                end
            end
            GameTooltip:AddLine(" ")
        end

        if db.char.data.dungeonList[1].inProgress then
            GameTooltip:AddLine(L['Current Dungeon'] .. ":")
        else
            GameTooltip:AddLine(L['Last Dungeon'] .. ":")
        end

        local dungeonName = db.char.data.dungeonList[1].name
        if type(dungeonName) ~= "string" then
            if GetRealZoneText() ~= nil then
                db.char.data.dungeonList[1].name = GetRealZoneText()
                dungeonName = db.char.data.dungeonList[1].name
            else
                dungeonName = "Unknown"
            end
        end

        GameTooltip:AddDoubleLine(" ".. L['Name'] ..": ", dungeonName, lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        GameTooltip:AddDoubleLine(" ".. L['Kills'] ..": ", Helpers:NumberFormat(latestData.killCount) .." @ ".. Helpers:NumberFormat(latestData.xpPerKill) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)

        if latestData.rested > 0 then
            local total = latestData.totalXP + latestData.rested
            GameTooltip:AddDoubleLine(" ".. L['Total XP'] ..": ", Helpers:NumberFormat(total) .. " (" .. Helpers:NumberFormat(latestData.rested) .. " " .. L['XP Rested'] ..")", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        else
            GameTooltip:AddDoubleLine(" ".. L['Total XP'] ..": ", Helpers:NumberFormat(latestData.totalXP), lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        end
    else
        GameTooltip:AddLine(L['Dungeons Required'] .. ":")
        GameTooltip:AddLine(" " .. L['No Dungeons Completed'], lc.r, lc.g, lc.b)
    end
end

function DisplayModule:TooltipAddExperience()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor

    local xpProgress = PlayerModule:GetProgressAsPercentage()
    local xpProgressBars = PlayerModule:GetProgressAsBars()
    local xpNeededTotal = PlayerModule.maxXP - PlayerModule.currentXP
    local xpNeededActual = PlayerModule:GetKillsRequired(1) or "~"

    GameTooltip:AddDoubleLine(" " .. L["XP Progress"] .. ": ", Helpers:ShrinkNumber(UnitXP("player")) .. " / " .. Helpers:ShrinkNumber(UnitXPMax("player")) .. " [" .. tostring(xpProgress) .. "%" .. "]", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["XP Bars Remaining"] .. ": ", xpProgressBars .. " bars", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["XP Rested"] .. ": ", Helpers:ShrinkNumber(PlayerModule:IsRested() or 0) .. " [" .. Helpers:round(PlayerModule:GetRestedPercentage(1)) .. "%]", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["Quest XP Required"] .. ": ", Helpers:NumberFormat(xpNeededTotal) .. " xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["Kill XP Required"] .. ": ", Helpers:NumberFormat(xpNeededActual) .. " xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
end

function DisplayModule:TooltipAddGuildInfo()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor

    if PlayerModule.guildLevel ~= nil and PlayerModule.guildXP ~= nil then
        GameTooltip:AddDoubleLine(" Level:", PlayerModule.guildLevel .. ' / 25', lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        local xpGained = tostring(Helpers:ShrinkNumber(PlayerModule.guildXP))
        local xpTotal = tostring(Helpers:ShrinkNumber(PlayerModule.guildXPMax))
        local xpProgress = tostring(PlayerModule:GetGuildProgressAsPercentage(1))
        GameTooltip:AddDoubleLine(" " .. L["XP Progress"] .. ": ", xpGained .. ' / ' .. xpTotal .. ' [' .. xpProgress .. '%]', lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)

        local dailyGained = tostring(Helpers:ShrinkNumber(PlayerModule.guildXPDaily))
        local dailyTotal = tostring(Helpers:ShrinkNumber(PlayerModule.guildXPDailyMax))
        local dailyProgress = tostring(PlayerModule:GetGuildDailyProgressAsPercentage(1))
        GameTooltip:AddDoubleLine(" " .. L['Daily Progress'] .. ": ", dailyGained .. ' / ' .. dailyTotal .. ' [' .. dailyProgress .. '%]', lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    else
        GameTooltip:AddLine(" No guild leveling info found.", lc.r, lc.g, lc.b)
    end
end

function DisplayModule:TooltipAddBattlegroundInfo()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor
    GameTooltip:AddDoubleLine(" " .. L["Battles"] .. ":", Helpers:NumberFormat(PlayerModule:GetAverageBGsRemaining() or 0) .." @ ".. Helpers:NumberFormat(Helpers:round(PlayerModule:GetAverageBGXP(), 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
    GameTooltip:AddDoubleLine(" " .. L["Objectives"] .. ":", Helpers:NumberFormat(PlayerModule:GetAverageBGObjectivesRemaining() or 0) .." @ ".. Helpers:NumberFormat(Helpers:round(PlayerModule:GetAverageBGObjectiveXP(), 0)) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
end

function DisplayModule:TooltipAddBattles()
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor

    local bgs = PlayerModule:GetBattlegroundsListed()
    if bgs ~= nil and (#db.char.data.bgList) > 0 then
        local latestData = PlayerModule:GetLatestBattlegroundDetails()

        GameTooltip:AddLine(L['Battlegrounds Required'] .. ":")
        for name, count in pairs(bgs) do
            if name == false then name = "Unknown" end
            local averageRaw = PlayerModule:GetBattlegroundAverage(name)
            if averageRaw == 0 then
                averageRaw = latestData.totalXP
            end
            local averageFormatted = Helpers:NumberFormat(Helpers:round(averageRaw, 0))
            local needed = PlayerModule:GetQuestsRequired(tonumber(averageRaw))
            GameTooltip:AddDoubleLine(" ".. name .. ": ", needed .. " @ ".. averageFormatted .. " xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        end
        GameTooltip:AddLine(" ")

        if latestData ~= nil then
            if latestData.inProgress then
                GameTooltip:AddLine(L['Current Battleground'] .. ":")
            else
                GameTooltip:AddLine(L['Last Battleground'] .. ":")
            end
            if type(latestData.name) ~= "string" then
                latestData.name = "Unknown"
            end
            GameTooltip:AddDoubleLine(" ".. L['Name'] ..": ", latestData.name, lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
            GameTooltip:AddDoubleLine(" ".. L['Total XP'] ..": ", Helpers:NumberFormat(latestData.totalXP), lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
            GameTooltip:AddDoubleLine(" ".. L['Objectives'] ..": ", Helpers:NumberFormat(latestData.objCount) .." @ ".. Helpers:NumberFormat(latestData.xpPerObj) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
            GameTooltip:AddDoubleLine(" ".. L['NPC Kills'] ..": ", Helpers:NumberFormat(latestData.killCount) .." @ ".. Helpers:NumberFormat(latestData.xpPerKill) .." xp", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        end
    else
        GameTooltip:AddLine(L['Battlegrounds Required'] .. ":")
        GameTooltip:AddLine(" " .. L['No Battles Fought'], lc.r, lc.g, lc.b)
    end
end

function DisplayModule:TooltipAddTimerDetails(minimal)
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor

    if db.profile.timer.enabled and PlayerModule.level < PlayerModule:GetMaxLevel() then
        local mode, timeToLevel, timePlayed, xpPerHour, totalXP, warning = PlayerModule:GetTimerData()

        if mode == nil then
            mode = L["Updating..."]
            timeToLevel = 0
            if timePlayed == nil then timePlayed = "N/A" end
            xpPerHour = "N/A"
            totalXP = "N/A"
        else
            mode = mode == 1 and L["Session"] or L["Level"]
        end

        timeToLevel = Helpers:TimeFormat(timeToLevel)
        if timeToLevel == "NaN" then
            timeToLevel = "Waiting for data..."
        end

        if warning == 2 then
            GameTooltip:AddDoubleLine(" " .. L["Data"] .. ": ", mode, lc.r, lc.g, lc.b, 1.0, 0.0, 0.0)
        else
            GameTooltip:AddDoubleLine(" " .. L["Data"] .. ": ", mode, lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        end
        GameTooltip:AddDoubleLine(" " .. L["Time to level"] .. ": ", timeToLevel, lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        if not minimal then
            GameTooltip:AddLine(" ")
        end

        local fTimePlayed = Helpers:TimeFormat(timePlayed)
        if fTimePlayed == "NaN" then fTimePlayed = "N/A" end

        GameTooltip:AddDoubleLine(" " ..L["Time elapsed"].. ": ", fTimePlayed, lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        GameTooltip:AddDoubleLine(" " ..L["Total XP"] .. ": ", Helpers:NumberFormat(totalXP), lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        GameTooltip:AddDoubleLine(" " ..L["XP per hour"] .. ": ", Helpers:NumberFormat(xpPerHour), lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        GameTooltip:AddDoubleLine(" " ..L["XP Needed"] .. ": ", Helpers:NumberFormat(PlayerModule.maxXP - PlayerModule.currentXP), lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)

        if warning == 2 and not minimal then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["No Kills Recorded. Using Level"], 1.0, 0.0, 0.0, true)
        elseif warning == 1 and not minimal then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["No Kills Recorded. Using Old"], 1.0, 0.0, 0.0, true)
        end
    else
        GameTooltip:AddDoubleLine(" Mode", "Disabled", self.Tooltip.labelColor.r, self.Tooltip.labelColor.g, self.Tooltip.labelColor.b, 1.0, 0.0, 0.0)
    end
end

function DisplayModule:TooltipAddGathering()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local lc, dc = self.Tooltip.labelColor, self.Tooltip.dataColor

    local nodesRequired, xpPerNode, restedXP = PlayerModule:GetGatheringRequired()
    if nodesRequired ~= nil then
        local xpShown = Helpers:NumberFormat(Helpers:round(restedXP, 0)) .. " xp"
        GameTooltip:AddDoubleLine(L["Average"] .. ": ", nodesRequired.. " @ " .. xpShown, lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        if restedXP > xpPerNode then
            local addedRested = Helpers:NumberFormat(Helpers:round(restedXP - xpPerNode, 0)) .. " xp"
            GameTooltip:AddDoubleLine("   ", " (" .. addedRested .. " " .. L["XP Rested"] .. ")", lc.r, lc.g, lc.b, dc.r, dc.b, dc.b)
        end
    else
        GameTooltip:AddLine(" " .. L['No Battles Fought'], lc.r, lc.g, lc.b)
    end
end

function DisplayModule:TooltipAddArchaeology()
    -- Placeholder - original was mostly commented out
end
