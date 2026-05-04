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
-- Display module. Manages LDB, Tooltip, Messages, and Average frame displays.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local DisplayModule = XToLevel:NewModule("DisplayModule")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Helpers = _XToLevel.Helpers

-- Message styles
DisplayModule.printStyle = {
    white = { r = 1.0, g = 1.0, b = 1.0, group = 54, addToStart = false },
    gray = { r = 0.5, g = 0.5, b = 0.5, group = 53, addToStart = false },
}

DisplayModule.floatingStyle = {
    kill = { r = 0.5, g = 1.0, b = 0.7, group = 56, fade = 5 },
    quest = { r = 0.5, g = 1.0, b = 0.7, group = 56, fade = 5 },
    level = { r = 0.35, g = 1.0, b = 0.35, group = 56, fade = 6 },
    arch = { r = 1.0, g = 0.5, b = 0.15, group = 56, fade = 8 },
}

function DisplayModule:OnInitialize()
end

-- Average frame state
DisplayModule.Average = {
    activeAPI = "Blocky",
    knownAPIs = { [1] = "Blocky", [2] = "Classic" },
}

function DisplayModule:OnEnable()
    self:InitializeTooltip()
    self:InitializeLDB()
    self:InitializeAverage()
end

--- Full update of all display elements (LDB + Average frames)
function DisplayModule:Update()
    self:LDBBuildPattern()
    self:LDBUpdate()
    self:LDBUpdateTimer()
    self:UpdateAverage()
end

--- Initialize Average frame orchestration
function DisplayModule:InitializeAverage()
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    self.Average.activeAPI = self.Average.knownAPIs[db.profile.averageDisplay.mode]
    if XToLevel.AverageFrameAPI then
        for index, name in ipairs(self.Average.knownAPIs) do
            if XToLevel.AverageFrameAPI[name] then
                XToLevel.AverageFrameAPI[name]:Initialize()
            end
        end
    end
    self:UpdateAverage()
end

--- Update the active Average frame window
function DisplayModule:UpdateAverage()
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()

    if not XToLevel.AverageFrameAPI then return end

    if PlayerModule.level < PlayerModule:GetMaxLevel() then
        -- Handle mode switch
        if self.Average.activeAPI ~= self.Average.knownAPIs[db.profile.averageDisplay.mode] then
            for index, name in ipairs(self.Average.knownAPIs) do
                if XToLevel.AverageFrameAPI[name] then
                    XToLevel.AverageFrameAPI[name]:Update()
                end
            end
            if self.Average.knownAPIs[db.profile.averageDisplay.mode] ~= nil then
                self:AlignAverageBoxes(self.Average.activeAPI, self.Average.knownAPIs[db.profile.averageDisplay.mode])
                self.Average.activeAPI = self.Average.knownAPIs[db.profile.averageDisplay.mode]
            end
        end

        local api = XToLevel.AverageFrameAPI[self.Average.activeAPI]
        if api and self.Average.knownAPIs[db.profile.averageDisplay.mode] ~= nil then
            if PlayerModule.isActive then
                api:SetKills(PlayerModule:GetAverageKillsRemaining() or nil)
                api:SetQuests(PlayerModule:GetAverageQuestsRemaining() or nil)
                api:SetPetBattles(PlayerModule:GetAveragePetBattlesRemaining() or nil)
                api:SetDungeons(PlayerModule:GetAverageDungeonsRemaining() or nil)
                api:SetBattles(PlayerModule:GetAverageBGsRemaining() or nil)
                api:SetObjectives(PlayerModule:GetAverageBGObjectivesRemaining() or nil)
                api:SetProgress(Helpers:round((PlayerModule.currentXP or 0) / (PlayerModule.maxXP or 1) * 100, 1))
                api:SetGathering(PlayerModule:GetGatheringRequired())

                if db.profile.averageDisplay.archaeologyAsSites then
                    api:SetDigs(PlayerModule:GetDigsitesRequired() or nil)
                else
                    api:SetDigs(PlayerModule:GetDigsRequired() or nil)
                end

                if db.profile.averageDisplay.guildProgressType == 1 then
                    api:SetGuildProgress(PlayerModule:GetGuildProgressAsPercentage(1))
                else
                    api:SetGuildProgress(PlayerModule:GetGuildDailyProgressAsPercentage(1))
                end

                PlayerModule:UpdateTimer()
            end
            api:Update()
        end
    elseif XToLevel.AverageFrameAPI[self.Average.activeAPI] ~= nil then
        XToLevel.AverageFrameAPI[self.Average.activeAPI]:Hide()
    end
end

--- Update Average frame timer display
function DisplayModule:UpdateAverageTimer(secondsToLevel)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if not XToLevel.AverageFrameAPI then return end
    if self.Average.knownAPIs[db.profile.averageDisplay.mode] == nil then return end

    local api = XToLevel.AverageFrameAPI[self.Average.activeAPI]
    if not api then return end

    local short, long = "N/A", "N/A"
    if type(secondsToLevel) == "number" and secondsToLevel > 0 and secondsToLevel ~= math.huge then
        if secondsToLevel < 60 then
            short = ("%ds"):format(secondsToLevel)
            long = short
        elseif secondsToLevel < 3600 then
            short = ("%dm"):format(math.floor(secondsToLevel / 60 + 0.5))
            long = short.." "..("%ds"):format(math.fmod(secondsToLevel, 60))
        elseif secondsToLevel < 86400 then
            short = ("%dh"):format(math.floor(secondsToLevel / 3600 + 0.5))
            long = short.." "..("%dm"):format(math.fmod(secondsToLevel, 3600))
        else
            short = ("%dd"):format(math.floor(secondsToLevel / 86400 + 0.5))
            long = short.." "..("%dh"):format(math.fmod(secondsToLevel, 86400))
        end
    end
    api:SetTimer(short, long)
end

--- Align average frame boxes when switching modes
function DisplayModule:AlignAverageBoxes(parent, child)
    if parent ~= child and parent ~= nil and child ~= nil then
        local parentAPI = XToLevel.AverageFrameAPI[parent]
        local childAPI = XToLevel.AverageFrameAPI[child]
        if parentAPI and childAPI then
            childAPI:AlignTo(parentAPI)
        end
    end
end

--- Debug message
function DisplayModule:Debug(message)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    if db.profile.general.showDebug then
        if type(message) ~= "table" then
            self:Print(message, self.printStyle.gray, {0.5, 0.5, 0.5})
        end
    end
end

--- Print to chat
function DisplayModule:Print(message, style, color)
    local r, g, b = unpack(color or {style.r, style.g, style.b})
    if style == nil then
        style = self.printStyle.white
    end
    DEFAULT_CHAT_FRAME:AddMessage(message, r, g, b, style.group, style.addToStart)
end

--- Print floating message
function DisplayModule:PrintFloating(text, color, style)
    local r, g, b = unpack(color or {style.r, style.g, style.b})
    UIErrorsFrame:AddMessage(text, r, g, b)
end

-- Convenience message methods used by EventsModule
function DisplayModule:PrintKill(mobName, killsRequired)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.messages.playerFloating then
        local message = killsRequired .. " " .. mobName .. (L["Kills Needed"] or " kills needed")
        self:PrintFloating(message, db.profile.messages.colors.playerKill, self.floatingStyle.kill)
    end
    if db.profile.messages.playerChat then
        local message = killsRequired .. " " .. mobName .. (L["Kills Needed"] or " kills needed")
        self:Print(message, self.printStyle.white, db.profile.messages.colors.playerKill)
    end
end

function DisplayModule:PrintQuest(questsRequired)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.messages.playerFloating then
        local message = questsRequired .. (L["Quests Needed"] or " quests needed")
        self:PrintFloating(message, db.profile.messages.colors.playerQuest, self.floatingStyle.quest)
    end
    if db.profile.messages.playerChat then
        local message = questsRequired .. (L["Quests Needed"] or " quests needed")
        self:Print(message, self.printStyle.white, db.profile.messages.colors.playerQuest)
    end
end

function DisplayModule:PrintAnonymous(required)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.messages.playerFloating then
        local message = required .. (L["Anonymous Needed"] or " more like that needed")
        self:PrintFloating(message, db.profile.messages.colors.playerQuest, self.floatingStyle.quest)
    end
    if db.profile.messages.playerChat then
        local message = required .. (L["Anonymous Needed"] or " more like that needed")
        self:Print(message, self.printStyle.white, db.profile.messages.colors.playerQuest)
    end
end

function DisplayModule:PrintDig(digsRequired)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.messages.playerFloating then
        local message = digsRequired .. (L["Digs Needed"] or " digs needed")
        self:PrintFloating(message, db.profile.messages.colors.archaeology, self.floatingStyle.arch)
    end
    if db.profile.messages.playerChat then
        local message = digsRequired .. (L["Digs Needed"] or " digs needed")
        self:Print(message, self.printStyle.white, db.profile.messages.colors.archaeology)
    end
end

function DisplayModule:PrintDigsites(sitesRequired)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.messages.playerFloating then
        local message = sitesRequired .. (L["Digsites Needed"] or " digsites needed")
        self:PrintFloating(message, db.profile.messages.colors.archaeology, self.floatingStyle.arch)
    end
    if db.profile.messages.playerChat then
        local message = sitesRequired .. (L["Digsites Needed"] or " digsites needed")
        self:Print(message, self.printStyle.white, db.profile.messages.colors.archaeology)
    end
end

function DisplayModule:PrintBattleground(bgsRequired)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.messages.playerFloating then
        local message = bgsRequired .. (L["Battlegrounds Needed"] or " battlegrounds needed")
        self:PrintFloating(message, db.profile.messages.colors.playerBattleground, self.floatingStyle.quest)
    end
    if db.profile.messages.playerChat then
        local message = bgsRequired .. (L["Battlegrounds Needed"] or " battlegrounds needed")
        self:Print(message, self.printStyle.white, db.profile.messages.colors.playerBattleground)
    end
end

function DisplayModule:PrintBGObjective(bgsRequired)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.messages.bgObjectives then
        if db.profile.messages.playerFloating then
            local message = bgsRequired .. (L["Battleground Objectives Needed"] or " objectives needed")
            self:PrintFloating(message, db.profile.messages.colors.playerBattleground, self.floatingStyle.quest)
        end
        if db.profile.messages.playerChat then
            local message = bgsRequired .. (L["Battleground Objectives Needed"] or " objectives needed")
            self:Print(message, self.printStyle.white, db.profile.messages.colors.playerBattleground)
        end
    end
end

function DisplayModule:PrintDungeon(remaining)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.messages.playerFloating then
        local message = remaining .. (L["Dungeons Needed"] or " dungeons needed")
        self:PrintFloating(message, db.profile.messages.colors.playerDungeon, self.floatingStyle.quest)
    end
    if db.profile.messages.playerChat then
        local message = remaining .. (L["Dungeons Needed"] or " dungeons needed")
        self:Print(message, self.printStyle.white, db.profile.messages.colors.playerDungeon)
    end
end

function DisplayModule:PrintDelve(remaining)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if db.profile.messages.playerFloating then
        local message = remaining .. (L["Delves Needed"] or " delves needed")
        self:PrintFloating(message, db.profile.messages.colors.playerDelve, self.floatingStyle.quest)
    end
    if db.profile.messages.playerChat then
        local message = remaining .. (L["Delves Needed"] or " delves needed")
        self:Print(message, self.printStyle.white, db.profile.messages.colors.playerDelve)
    end
end
