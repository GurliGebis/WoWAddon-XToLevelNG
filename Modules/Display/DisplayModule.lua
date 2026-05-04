---
-- Display module. Manages LDB, Tooltip, Messages, and Average frame displays.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local DisplayModule = XToLevel:NewModule("DisplayModule")

local L = addonTable.GetLocale()
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

function DisplayModule:OnEnable()
    -- LDB and Average frame initialization will be called here
    -- once those subsystems are migrated
end

--- Full update of all display elements
function DisplayModule:Update()
    -- TODO: Wire to LDB:BuildPattern(), LDB:Update(), Average:Update()
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
