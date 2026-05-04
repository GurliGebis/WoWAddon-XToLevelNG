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
-- Player module. Manages all player state, XP tracking, and average calculations.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local PlayerModule = XToLevel:NewModule("PlayerModule", "AceTimer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Helpers = _XToLevel.Helpers

-- Player state
PlayerModule.isActive = false
PlayerModule.level = nil
PlayerModule.maxLevel = nil
PlayerModule.class = nil
PlayerModule.currentXP = nil
PlayerModule.restedXP = 0
PlayerModule.maxXP = nil
PlayerModule.killAverage = nil
PlayerModule.killRange = { low = nil, high = nil, average = nil }
PlayerModule.questAverage = nil
PlayerModule.questRange = { low = nil, high = nil, average = nil }
PlayerModule.petBattleAverage = nil
PlayerModule.bgAverage = nil
PlayerModule.bgObjAverage = nil
PlayerModule.dungeonAverage = nil
PlayerModule.delveAverage = nil
PlayerModule.killListLength = 100
PlayerModule.questListLength = 100
PlayerModule.petBattleListLength = 50
PlayerModule.bgListLength = 300
PlayerModule.dungeonListLength = 100
PlayerModule.delveListLength = 100
PlayerModule.digListLength = 1
PlayerModule.hasEnteredBG = true

PlayerModule.guildLevel = nil
PlayerModule.guildXP = nil
PlayerModule.guildXPMax = nil
PlayerModule.guildXPDaily = nil
PlayerModule.guildXPDailyMax = nil
PlayerModule.guildHasQueried = false

PlayerModule.timePlayedTotal = nil
PlayerModule.timePlayedLevel = nil
PlayerModule.timePlayedUpdated = nil

PlayerModule.dungeonList = {}
PlayerModule.latestDungeonData = { totalXP = nil, killCount = nil, xpPerKill = nil, otherXP = nil }
PlayerModule.bgList = {}
PlayerModule.latestBgData = { totalXP = nil, objCount = nil, killCount = nil, xpPerObj = nil, xpPerKill = nil, otherXP = nil, inProgress = nil, name = nil }

PlayerModule.lastSync = time()
PlayerModule.lastXpPerHourUpdate = time() - 60
PlayerModule.xpPerSec = nil
PlayerModule.xpPerSecTimeout = 2
PlayerModule.timerHandler = nil

PlayerModule.percentage = nil
PlayerModule.lastKnownXP = nil

PlayerModule.guildPercentage = nil
PlayerModule.guildLastKnownXP = nil

PlayerModule.guildDailyPercentage = nil
PlayerModule.guildDailyLastKnownXP = nil

function PlayerModule:OnInitialize()
end

function PlayerModule:OnEnable()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    self:Initialize(db.char.data.killAverage, db.char.data.questAverage)
end

function PlayerModule:Initialize(killAverage, questAverage)
    self.isActive = true
    self.level = UnitLevel("player")
    self.maxLevel = self:GetMaxLevel()
    self.class = select(2, UnitClass("player"))
    self.currentXP = UnitXP("player")
    self.maxXP = UnitXPMax("player")
    self.restedXP = GetXPExhaustion() or 0
    self.lastKnownXP = self.currentXP
    self.killAverage = killAverage
    self.questAverage = questAverage
    self.percentage = nil
end

function PlayerModule:GetMaxLevel()
    if GetMaxLevelForPlayerExpansion then
        return GetMaxLevelForPlayerExpansion()
    else
        return GetMaxPlayerLevel and GetMaxPlayerLevel() or 70
    end
end

function PlayerModule:GetClass()
    return self.class or select(2, UnitClass("player"))
end

function PlayerModule:CreateBgDataArray()
    return {
        inProgress = false,
        level = UnitLevel("player"),
        name = false,
        totalXP = 0,
        objCount = 0,
        killCount = 0,
        killTotal = 0,
        objTotal = 0,
    }
end

function PlayerModule:CreateDungeonDataArray()
    return {
        inProgress = false,
        level = UnitLevel("player"),
        name = false,
        totalXP = 0,
        rested = 0,
        killCount = 0,
        killTotal = 0,
    }
end

function PlayerModule:CreateDelveDataArray()
    return {
        inProgress = false,
        level = UnitLevel("player"),
        name = false,
        totalXP = 0,
        rested = 0,
        killCount = 0,
        killTotal = 0,
    }
end

function PlayerModule:SyncData()
    self.level = UnitLevel("player")
    self.currentXP = UnitXP("player")
    self.maxXP = UnitXPMax("player")
    self.restedXP = GetXPExhaustion() or 0
    self.lastSync = time()

    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    db.char.data.timer.lastUpdated = GetTime()
end

function PlayerModule:SyncGuildData()
    if IsInGuild() then
        if GetGuildLevel then
            self.guildLevel = GetGuildLevel()
        end
        -- Guild XP API was removed in later expansions
        if GetGuildXPInfo then
            local currentXP, remainingXP, dailyXP, maxDailyXP = GetGuildXPInfo()
            if currentXP and remainingXP then
                self.guildXP = currentXP
                self.guildXPMax = currentXP + remainingXP
            end
            if dailyXP and maxDailyXP then
                self.guildXPDaily = dailyXP
                self.guildXPDailyMax = maxDailyXP
            end
        end
    end
end

function PlayerModule:UpdateTimePlayed(total, level)
    if total < level then
        local tmp = level
        level = total
        total = tmp
    end
    self.timePlayedTotal = total
    self.timePlayedLevel = level
    self.timePlayedUpdated = time()
end

function PlayerModule:TriggerTimerUpdate()
end

function PlayerModule:UpdateTimer()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.timer.enabled and self.level < self:GetMaxLevel() then
        local sessionTotal = db.char.data.timer.total or 0
        local sessionStart = db.char.data.timer.start or GetTime()
        local sessionTime = GetTime() - sessionStart

        if sessionTime > 0 and sessionTotal > 0 then
            self.xpPerSec = sessionTotal / sessionTime
        end
        self.lastXpPerHourUpdate = time()
    end
end

function PlayerModule:GetTimerData()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if not db.profile.timer.enabled then
        return nil, 0, 0, 0, 0, nil
    end

    local mode = db.profile.timer.mode
    local timePlayed, xpPerHour, totalXP, warning

    if mode == 1 then -- Session
        local sessionTotal = db.char.data.timer.total or 0
        local sessionStart = db.char.data.timer.start or GetTime()
        timePlayed = GetTime() - sessionStart
        totalXP = sessionTotal

        if timePlayed > 0 and sessionTotal > 0 then
            xpPerHour = math.floor(sessionTotal / timePlayed * 3600)
        else
            xpPerHour = 0
        end

        if sessionTotal == 0 then
            if db.profile.timer.allowLevelFallback and self.timePlayedLevel and self.timePlayedLevel > 0 then
                mode = 2
                warning = 2
            else
                warning = 1
            end
        end
    end

    if mode == 2 then -- Level
        timePlayed = self.timePlayedLevel or 0
        if self.timePlayedUpdated then
            timePlayed = timePlayed + (time() - self.timePlayedUpdated)
        end
        totalXP = self.currentXP or 0

        if timePlayed > 0 and totalXP > 0 then
            xpPerHour = math.floor(totalXP / timePlayed * 3600)
        else
            xpPerHour = 0
        end
    end

    local timeToLevel = 0
    if xpPerHour and xpPerHour > 0 then
        local xpRemaining = (self.maxXP or 1) - (self.currentXP or 0)
        timeToLevel = math.floor(xpRemaining / xpPerHour * 3600)
    end

    return mode, timeToLevel, timePlayed, xpPerHour, totalXP, warning
end

function PlayerModule:GetUnrestedXP(totalXP)
    if self.restedXP and self.restedXP > 0 then
        local rested = math.min(self.restedXP, totalXP / 2)
        return totalXP - rested
    end
    return totalXP
end

function PlayerModule:AddKill(xpGained, mobName)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    local unrestedXP = self:GetUnrestedXP(xpGained)

    table.insert(db.char.data.killList, 1, {mob = mobName, xp = unrestedXP})
    if #db.char.data.killList > self.killListLength then
        table.remove(db.char.data.killList)
    end

    self.killAverage = nil
    self.killRange = { low = nil, high = nil, average = nil }

    db.char.data.total.mobKills = (db.char.data.total.mobKills or 0) + 1

    return unrestedXP
end

function PlayerModule:AddQuest(xpGained)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    table.insert(db.char.data.questList, 1, xpGained)
    if #db.char.data.questList > self.questListLength then
        table.remove(db.char.data.questList)
    end
    self.questAverage = nil
    self.questRange = { low = nil, high = nil, average = nil }
    db.char.data.total.quests = (db.char.data.total.quests or 0) + 1
end

function PlayerModule:AddPetBattle(xpGained)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    table.insert(db.char.data.petBattleList, 1, xpGained)
    if #db.char.data.petBattleList > self.petBattleListLength then
        table.remove(db.char.data.petBattleList)
    end
    self.petBattleAverage = nil
end

function PlayerModule:AddGathering(xpGained)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local unrestedXP = self:GetUnrestedXP(xpGained)
    -- Store gathering data (simplified for now)
    return unrestedXP
end

function PlayerModule:AddDig(xpGained)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    table.insert(db.char.data.digs, 1, xpGained)
    if #db.char.data.digs > self.digListLength then
        table.remove(db.char.data.digs)
    end
end

-- Battleground methods
function PlayerModule:BattlegroundStart(bgName)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    local data = self:CreateBgDataArray()
    data.inProgress = true
    data.name = bgName or Helpers:GetCurrentBattlegroundName() or false
    table.insert(db.char.data.bgList, 1, data)
    if #db.char.data.bgList > self.bgListLength then
        table.remove(db.char.data.bgList)
    end
end

function PlayerModule:BattlegroundEnd()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if #db.char.data.bgList > 0 and db.char.data.bgList[1].inProgress then
        db.char.data.bgList[1].inProgress = false
    end
    self.bgAverage = nil
    self.bgObjAverage = nil
end

function PlayerModule:IsBattlegroundInProgress()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    return #db.char.data.bgList > 0 and db.char.data.bgList[1].inProgress
end

function PlayerModule:AddBattlegroundObjective(xpGained)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if self:IsBattlegroundInProgress() then
        local minXP = Helpers:GetBGObjectiveMinXP()
        if xpGained >= minXP then
            db.char.data.bgList[1].totalXP = db.char.data.bgList[1].totalXP + xpGained
            db.char.data.bgList[1].objCount = db.char.data.bgList[1].objCount + 1
            db.char.data.bgList[1].objTotal = (db.char.data.bgList[1].objTotal or 0) + xpGained
            self.bgObjAverage = nil
            db.char.data.total.objectives = (db.char.data.total.objectives or 0) + 1
            return true
        end
    end
    return false
end

function PlayerModule:AddBattlegroundKill(xpGained, name)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if self:IsBattlegroundInProgress() then
        db.char.data.bgList[1].totalXP = db.char.data.bgList[1].totalXP + xpGained
        db.char.data.bgList[1].killCount = db.char.data.bgList[1].killCount + 1
        db.char.data.bgList[1].killTotal = (db.char.data.bgList[1].killTotal or 0) + xpGained
        db.char.data.total.pvpKills = (db.char.data.total.pvpKills or 0) + 1
    end
end

-- Dungeon methods
function PlayerModule:DungeonStart()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    local data = self:CreateDungeonDataArray()
    data.inProgress = true
    data.name = GetRealZoneText() or false
    table.insert(db.char.data.dungeonList, 1, data)
    if #db.char.data.dungeonList > self.dungeonListLength then
        table.remove(db.char.data.dungeonList)
    end
end

function PlayerModule:DungeonEnd(zoneName)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if #db.char.data.dungeonList > 0 and db.char.data.dungeonList[1].inProgress then
        db.char.data.dungeonList[1].inProgress = false
        if zoneName and (db.char.data.dungeonList[1].name == false) then
            db.char.data.dungeonList[1].name = zoneName
        end
        self.dungeonAverage = nil
        return true
    end
    return false
end

function PlayerModule:IsDungeonInProgress()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    return #db.char.data.dungeonList > 0 and db.char.data.dungeonList[1].inProgress
end

function PlayerModule:UpdateDungeonName()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    if self:IsDungeonInProgress() and db.char.data.dungeonList[1].name == false then
        local zoneName = GetRealZoneText()
        if zoneName and zoneName ~= "" then
            db.char.data.dungeonList[1].name = zoneName
        end
    end
end

function PlayerModule:AddDungeonKill(xpGained, name, rested)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if self:IsDungeonInProgress() then
        db.char.data.dungeonList[1].totalXP = db.char.data.dungeonList[1].totalXP + xpGained
        db.char.data.dungeonList[1].killCount = db.char.data.dungeonList[1].killCount + 1
        db.char.data.dungeonList[1].killTotal = (db.char.data.dungeonList[1].killTotal or 0) + xpGained
        db.char.data.dungeonList[1].rested = (db.char.data.dungeonList[1].rested or 0) + (rested or 0)
        db.char.data.total.dungeonKills = (db.char.data.total.dungeonKills or 0) + 1
    end
end

-- Delve methods
function PlayerModule:DelveStart()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    local data = self:CreateDelveDataArray()
    data.inProgress = true
    data.name = GetRealZoneText() or false
    table.insert(db.char.data.delveList, 1, data)
    if #db.char.data.delveList > self.delveListLength then
        table.remove(db.char.data.delveList)
    end
end

function PlayerModule:DelveEnd(zoneName)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if #db.char.data.delveList > 0 and db.char.data.delveList[1].inProgress then
        db.char.data.delveList[1].inProgress = false
        if zoneName and (db.char.data.delveList[1].name == false) then
            db.char.data.delveList[1].name = zoneName
        end
        self.delveAverage = nil
        return true
    end
    return false
end

function PlayerModule:IsDelveInProgress()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    return #db.char.data.delveList > 0 and db.char.data.delveList[1].inProgress
end

function PlayerModule:UpdateDelveName()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    if self:IsDelveInProgress() and db.char.data.delveList[1].name == false then
        local zoneName = GetRealZoneText()
        if zoneName and zoneName ~= "" then
            db.char.data.delveList[1].name = zoneName
        end
    end
end

function PlayerModule:AddDelveKill(xpGained, name, rested)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if self:IsDelveInProgress() then
        db.char.data.delveList[1].totalXP = db.char.data.delveList[1].totalXP + xpGained
        db.char.data.delveList[1].killCount = db.char.data.delveList[1].killCount + 1
        db.char.data.delveList[1].killTotal = (db.char.data.delveList[1].killTotal or 0) + xpGained
        db.char.data.delveList[1].rested = (db.char.data.delveList[1].rested or 0) + (rested or 0)
    end
end

-- XP calculation methods
function PlayerModule:GetKillsRequired(xp)
    if not xp or xp <= 0 then return 0 end
    local remaining = (self.maxXP or 1) - (self.currentXP or 0)
    if remaining <= 0 then return 0 end
    return math.ceil(remaining / xp)
end

function PlayerModule:GetQuestsRequired(xp)
    if not xp or xp <= 0 then return 0 end
    local remaining = (self.maxXP or 1) - (self.currentXP or 0)
    if remaining <= 0 then return 0 end
    return math.ceil(remaining / xp)
end

function PlayerModule:GetPetBattlesRequired(xp)
    if not xp or xp <= 0 then return 0 end
    local remaining = (self.maxXP or 1) - (self.currentXP or 0)
    if remaining <= 0 then return 0 end
    return math.ceil(remaining / xp)
end

function PlayerModule:GetProgressAsPercentage(fractions)
    if not self.currentXP or not self.maxXP or self.maxXP == 0 then return 0 end
    return Helpers:round(self.currentXP / self.maxXP * 100, fractions or 1)
end

function PlayerModule:GetProgressAsBars(fractions)
    if not self.currentXP or not self.maxXP or self.maxXP == 0 then return 0 end
    local bars = 20 - Helpers:round((self.currentXP / self.maxXP) * 20, fractions or 0)
    return bars
end

function PlayerModule:GetXpRemaining()
    return (self.maxXP or 0) - (self.currentXP or 0)
end

function PlayerModule:GetRestedPercentage(fractions)
    if not self.maxXP or self.maxXP == 0 then return 0 end
    return Helpers:round((self.restedXP or 0) / self.maxXP * 100, fractions or 0)
end

function PlayerModule:GetGuildProgressAsPercentage(fractions)
    if not self.guildXP or not self.guildXPMax or self.guildXPMax == 0 then return 0 end
    return Helpers:round(self.guildXP / self.guildXPMax * 100, fractions or 1)
end

function PlayerModule:GetGuildXpRemaining()
    return (self.guildXPMax or 0) - (self.guildXP or 0)
end

function PlayerModule:GetGuildDailyProgressAsPercentage(fractions)
    if not self.guildXPDaily or not self.guildXPDailyMax or self.guildXPDailyMax == 0 then return 0 end
    return Helpers:round(self.guildXPDaily / self.guildXPDailyMax * 100, fractions or 1)
end

function PlayerModule:GetGuildDailyXpRemaining()
    return (self.guildXPDailyMax or 0) - (self.guildXPDaily or 0)
end

-- Average calculation methods
function PlayerModule:GetAverageKillXP()
    if self.killAverage then return self.killAverage end

    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local listLength = db.profile.averageDisplay.playerKillListLength or 10

    local total = 0
    local count = 0
    for i, data in ipairs(db.char.data.killList) do
        if i > listLength then break end
        total = total + data.xp
        count = count + 1
    end

    if count > 0 then
        self.killAverage = total / count
    else
        -- Estimate from mob XP
        local _, xp = Helpers:MobXP(nil, UnitLevel("player"))
        self.killAverage = xp or 0
    end
    return self.killAverage
end

function PlayerModule:GetKillXpRange()
    if self.killRange.average then return self.killRange end

    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local listLength = db.profile.averageDisplay.playerKillListLength or 10

    local low, high, total, count = nil, nil, 0, 0
    for i, data in ipairs(db.char.data.killList) do
        if i > listLength then break end
        if not low or data.xp < low then low = data.xp end
        if not high or data.xp > high then high = data.xp end
        total = total + data.xp
        count = count + 1
    end

    if count > 0 then
        self.killRange = { low = low, high = high, average = total / count }
    else
        local xp = self:GetAverageKillXP()
        self.killRange = { low = xp, high = xp, average = xp }
    end
    return self.killRange
end

function PlayerModule:GetAverageKillsRemaining()
    local avgXP = self:GetAverageKillXP()
    if avgXP and avgXP > 0 then
        return self:GetKillsRequired(avgXP)
    end
    return 0
end

function PlayerModule:GetAverageQuestXP()
    if self.questAverage then return self.questAverage end

    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local listLength = db.profile.averageDisplay.playerQuestListLength or 10

    local total = 0
    local count = 0
    for i, xp in ipairs(db.char.data.questList) do
        if i > listLength then break end
        total = total + xp
        count = count + 1
    end

    if count > 0 then
        self.questAverage = total / count
    else
        -- Estimate from quest XP table
        local level = UnitLevel("player")
        self.questAverage = _XToLevel.QUEST_XP[level] or 0
    end
    return self.questAverage
end

function PlayerModule:GetQuestXpRange()
    if self.questRange.average then return self.questRange end

    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local listLength = db.profile.averageDisplay.playerQuestListLength or 10

    local low, high, total, count = nil, nil, 0, 0
    for i, xp in ipairs(db.char.data.questList) do
        if i > listLength then break end
        if not low or xp < low then low = xp end
        if not high or xp > high then high = xp end
        total = total + xp
        count = count + 1
    end

    if count > 0 then
        self.questRange = { low = low, high = high, average = total / count }
    else
        local xp = self:GetAverageQuestXP()
        self.questRange = { low = xp, high = xp, average = xp }
    end
    return self.questRange
end

function PlayerModule:GetAverageQuestsRemaining()
    local avgXP = self:GetAverageQuestXP()
    if avgXP and avgXP > 0 then
        return self:GetQuestsRequired(avgXP)
    end
    return 0
end

function PlayerModule:GetAveragePetBattleXP()
    if self.petBattleAverage then return self.petBattleAverage end

    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local listLength = db.profile.averageDisplay.playerPetBattleListLength or 10

    local total = 0
    local count = 0
    for i, xp in ipairs(db.char.data.petBattleList) do
        if i > listLength then break end
        total = total + xp
        count = count + 1
    end

    self.petBattleAverage = count > 0 and (total / count) or 0
    return self.petBattleAverage
end

function PlayerModule:GetPetBattleXpRange()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local listLength = db.profile.averageDisplay.playerPetBattleListLength or 10

    local low, high, total, count = nil, nil, 0, 0
    for i, xp in ipairs(db.char.data.petBattleList) do
        if i > listLength then break end
        if not low or xp < low then low = xp end
        if not high or xp > high then high = xp end
        total = total + xp
        count = count + 1
    end

    if count > 0 then
        return { low = low, high = high, average = total / count }
    else
        return { low = 0, high = 0, average = 0 }
    end
end

function PlayerModule:GetAveragePetBattlesRemaining()
    local avgXP = self:GetAveragePetBattleXP()
    if avgXP and avgXP > 0 then
        return self:GetPetBattlesRequired(avgXP)
    end
    return 0
end

function PlayerModule:HasPetBattleInfo()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    return #db.char.data.petBattleList > 0
end

function PlayerModule:HasBattlegroundData()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    return #db.char.data.bgList > 0
end

function PlayerModule:GetAverageBGXP()
    if self.bgAverage then return self.bgAverage end

    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local listLength = db.profile.averageDisplay.playerBGListLength or 15

    local total = 0
    local count = 0
    for i, data in ipairs(db.char.data.bgList) do
        if i > listLength then break end
        if not data.inProgress and data.totalXP > 0 then
            total = total + data.totalXP
            count = count + 1
        end
    end

    self.bgAverage = count > 0 and (total / count) or 0
    return self.bgAverage
end

function PlayerModule:GetAverageBGsRemaining()
    local avgXP = self:GetAverageBGXP()
    if avgXP and avgXP > 0 then
        return self:GetQuestsRequired(avgXP)
    end
    return 0
end

function PlayerModule:GetAverageBGObjectiveXP()
    if self.bgObjAverage then return self.bgObjAverage end

    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local listLength = db.profile.averageDisplay.playerBGOListLength or 15

    local total = 0
    local count = 0
    for i, data in ipairs(db.char.data.bgList) do
        if i > listLength then break end
        if data.objCount and data.objCount > 0 and data.objTotal then
            total = total + data.objTotal
            count = count + data.objCount
        end
    end

    self.bgObjAverage = count > 0 and (total / count) or 0
    return self.bgObjAverage
end

function PlayerModule:GetAverageBGObjectivesRemaining()
    local avgXP = self:GetAverageBGObjectiveXP()
    if avgXP and avgXP > 0 then
        return self:GetQuestsRequired(avgXP)
    end
    return 0
end

function PlayerModule:GetBattlegroundsListed()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if #db.char.data.bgList == 0 then return nil end

    local list = {}
    for _, data in ipairs(db.char.data.bgList) do
        local name = data.name or false
        if name then
            list[name] = (list[name] or 0) + 1
        end
    end
    return next(list) and list or nil
end

function PlayerModule:GetBattlegroundAverage(name)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    local total = 0
    local count = 0
    for _, data in ipairs(db.char.data.bgList) do
        if data.name == name and not data.inProgress and data.totalXP > 0 then
            total = total + data.totalXP
            count = count + 1
        end
    end
    return count > 0 and (total / count) or 0
end

function PlayerModule:GetLatestBattlegroundDetails()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if #db.char.data.bgList == 0 then return nil end
    local data = db.char.data.bgList[1]
    return {
        name = data.name,
        totalXP = data.totalXP or 0,
        objCount = data.objCount or 0,
        killCount = data.killCount or 0,
        xpPerObj = data.objCount > 0 and math.floor((data.objTotal or 0) / data.objCount) or 0,
        xpPerKill = data.killCount > 0 and math.floor((data.killTotal or 0) / data.killCount) or 0,
        inProgress = data.inProgress,
    }
end

-- Dungeon average methods
function PlayerModule:HasDungeonData()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    return #db.char.data.dungeonList > 0
end

function PlayerModule:GetAverageDungeonXP()
    if self.dungeonAverage then return self.dungeonAverage end

    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local listLength = db.profile.averageDisplay.playerDungeonListLength or 15

    local total = 0
    local count = 0
    for i, data in ipairs(db.char.data.dungeonList) do
        if i > listLength then break end
        if not data.inProgress and data.totalXP > 0 then
            total = total + data.totalXP
            count = count + 1
        end
    end

    self.dungeonAverage = count > 0 and (total / count) or 0
    return self.dungeonAverage
end

function PlayerModule:GetAverageDungeonsRemaining()
    local avgXP = self:GetAverageDungeonXP()
    if avgXP and avgXP > 0 then
        return self:GetKillsRequired(avgXP)
    end
    return 0
end

function PlayerModule:GetDungeonsListed()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if #db.char.data.dungeonList == 0 then return nil end

    local list = {}
    for _, data in ipairs(db.char.data.dungeonList) do
        local name = data.name or false
        if name then
            list[name] = (list[name] or 0) + 1
        end
    end
    return next(list) and list or nil
end

function PlayerModule:GetDungeonAverage(name)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    local total = 0
    local count = 0
    for _, data in ipairs(db.char.data.dungeonList) do
        if data.name == name and not data.inProgress and data.totalXP > 0 then
            total = total + data.totalXP
            count = count + 1
        end
    end
    return count > 0 and (total / count) or 0
end

function PlayerModule:GetLatestDungeonDetails()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if #db.char.data.dungeonList == 0 then return nil end
    local data = db.char.data.dungeonList[1]
    return {
        name = data.name,
        totalXP = data.totalXP or 0,
        killCount = data.killCount or 0,
        xpPerKill = data.killCount > 0 and math.floor((data.killTotal or 0) / data.killCount) or 0,
        rested = data.rested or 0,
        inProgress = data.inProgress,
    }
end

-- Delve average methods
function PlayerModule:HasDelveData()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    return #db.char.data.delveList > 0
end

function PlayerModule:GetAverageDelveXP()
    if self.delveAverage then return self.delveAverage end

    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local listLength = db.profile.averageDisplay.playerDelveListLength or 15

    local total = 0
    local count = 0
    for i, data in ipairs(db.char.data.delveList) do
        if i > listLength then break end
        if not data.inProgress and data.totalXP > 0 then
            total = total + data.totalXP
            count = count + 1
        end
    end

    self.delveAverage = count > 0 and (total / count) or 0
    return self.delveAverage
end

function PlayerModule:GetAverageDelvesRemaining()
    local avgXP = self:GetAverageDelveXP()
    if avgXP and avgXP > 0 then
        return self:GetKillsRequired(avgXP)
    end
    return 0
end

function PlayerModule:GetDelvesListed()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if #db.char.data.delveList == 0 then return nil end

    local list = {}
    for _, data in ipairs(db.char.data.delveList) do
        local name = data.name or false
        if name then
            list[name] = (list[name] or 0) + 1
        end
    end
    return next(list) and list or nil
end

function PlayerModule:GetDelveAverage(name)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    local total = 0
    local count = 0
    for _, data in ipairs(db.char.data.delveList) do
        if data.name == name and not data.inProgress and data.totalXP > 0 then
            total = total + data.totalXP
            count = count + 1
        end
    end
    return count > 0 and (total / count) or 0
end

function PlayerModule:GetLatestDelveDetails()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if #db.char.data.delveList == 0 then return nil end
    local data = db.char.data.delveList[1]
    return {
        name = data.name,
        totalXP = data.totalXP or 0,
        killCount = data.killCount or 0,
        xpPerKill = data.killCount > 0 and math.floor((data.killTotal or 0) / data.killCount) or 0,
        rested = data.rested or 0,
        inProgress = data.inProgress,
    }
end

-- Gathering methods
function PlayerModule:GetGatheringRequired()
    local xpPerNode = Helpers:GatheringXP(self.level)
    if not xpPerNode or xpPerNode <= 0 then return nil end

    local restedBonus = 0
    if self.restedXP and self.restedXP > 0 then
        restedBonus = math.min(self.restedXP, xpPerNode / 2)
    end
    local totalXP = xpPerNode + restedBonus
    local remaining = (self.maxXP or 1) - (self.currentXP or 0)
    local nodesRequired = math.ceil(remaining / totalXP)
    return nodesRequired, xpPerNode, totalXP
end

function PlayerModule:HasDigInfo()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    return #db.char.data.digs > 0
end

function PlayerModule:GetHighestDigXP()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local highest = 0
    for _, xp in ipairs(db.char.data.digs) do
        if xp > highest then highest = xp end
    end
    return highest
end

function PlayerModule:GetDigsRequired()
    local xp = self:GetHighestDigXP()
    if xp <= 0 then return nil end
    return self:GetKillsRequired(xp)
end

function PlayerModule:GetDigsitesRequired(assumeOneDigIsLeft)
    -- Simplified - each digsite has ~3 digs
    local xp = self:GetHighestDigXP()
    if xp <= 0 then return 0 end
    local digsPerSite = 3
    local xpPerSite = xp * digsPerSite
    local remaining = (self.maxXP or 1) - (self.currentXP or 0)
    return math.ceil(remaining / xpPerSite)
end

-- Clear methods
function PlayerModule:ClearKills(initialValue)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    table.wipe(db.char.data.killList)
    self.killAverage = initialValue or nil
    self.killRange = { low = nil, high = nil, average = nil }
end

function PlayerModule:ClearQuests(initialValue)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    table.wipe(db.char.data.questList)
    self.questAverage = initialValue or nil
    self.questRange = { low = nil, high = nil, average = nil }
end

function PlayerModule:ClearPetBattles(initialValue)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    table.wipe(db.char.data.petBattleList)
    self.petBattleAverage = initialValue or nil
end

function PlayerModule:ClearBattlegrounds(initialValue)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    table.wipe(db.char.data.bgList)
    self.bgAverage = initialValue or nil
    self.bgObjAverage = initialValue or nil
end

function PlayerModule:ClearDungeonList(initialValue)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    table.wipe(db.char.data.dungeonList)
    self.dungeonAverage = initialValue or nil
end

function PlayerModule:ClearDelveList(initialValue)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    table.wipe(db.char.data.delveList)
    self.delveAverage = initialValue or nil
end

function PlayerModule:ClearKillList()
    self:ClearKills()
end

function PlayerModule:ClearQuestList()
    self:ClearQuests()
end

function PlayerModule:ClearBattlegroundList()
    self:ClearBattlegrounds()
end

function PlayerModule:IsRested()
    if self.restedXP and self.restedXP > 0 then
        return self.restedXP
    end
    return nil
end

function PlayerModule:SetKillAverageLength(newValue)
    -- Lengths are controlled by profile settings, this is a no-op now
end

function PlayerModule:SetQuestAverageLength(newValue)
end

function PlayerModule:SetPetBattleAverageLength(newValue)
end

function PlayerModule:SetBattleAverageLength(newValue)
end

function PlayerModule:SetObjectiveAverageLength(newValue)
end

function PlayerModule:SetDungeonAverageLength(newValue)
end

function PlayerModule:SetDelveAverageLength(newValue)
end
