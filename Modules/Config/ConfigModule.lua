---
-- Config module. Handles addon configuration GUI and options registration.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local ConfigModule = XToLevel:NewModule("ConfigModule")

local L = addonTable.GetLocale()

function ConfigModule:OnInitialize()
end

function ConfigModule:OnEnable()
    local DBModule = XToLevel:GetModule("DBModule")
    local LocaleModule = XToLevel:GetModule("LocaleModule")

    -- Set the display locale
    if not LocaleModule:SetLocale(DBModule:GetProfile().general.displayLocale) then
        console:log("Attempted to load unknown locale '" .. tostring(DBModule:GetProfile().general.displayLocale) .. "'. Falling back on 'enUS'.")
        DBModule:GetProfile().general.displayLocale = "enUS"
        if not LocaleModule:SetLocale("enUS") then
            print("|cFFaaaaaaXToLevel - |r|cFFFF5533Fatal error:|r Locale files not found. (Try re-installing the addon.)")
            return
        end
    end
    LocaleModule:WipeLocales()

    self:RegisterOptions()
    self:RegisterDialogs()
end

function ConfigModule:Open(section)
    LibStub("AceConfigDialog-3.0"):Open("XToLevel")
    if section then
        LibStub("AceConfigDialog-3.0"):SelectGroup("XToLevel", section)
    end
end

function ConfigModule:RegisterOptions()
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("XToLevel", function() return self:GetOptions() end)
end

function ConfigModule:RegisterDialogs()
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")

    StaticPopupDialogs['XToLevelConfig_MessageColorsReset'] = {
        text = L["Color Reset Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            local db = DBModule:GetDB()
            db.profile.messages.colors = {
                playerKill = {0.72, 1, 0.71, 1},
                playerQuest = {0.5, 1, 0.7, 1},
                playerBattleground = {1, 0.5, 0.5, 1},
                playerDungeon = {1, 0.75, 0.35, 1},
                playerDelve = {0.4, 0.85, 1.0, 1},
                playerLevel = {0.35, 1, 0.35, 1},
                archaeology = {1.0, 0.5, 0.15, 1},
            }
            ConfigModule:Open("Messages")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs['XToLevelConfig_ResetPlayerKills'] = {
        text = L["Reset Player Kill Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            PlayerModule:ClearKills()
            DisplayModule:Update()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs['XToLevelConfig_ResetPlayerQuests'] = {
        text = L["Reset Player Quest Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            PlayerModule:ClearQuests()
            DisplayModule:Update()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs['XToLevelConfig_ResetBattles'] = {
        text = L["Reset Battleground Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            PlayerModule:ClearBattlegrounds()
            DisplayModule:Update()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs['XToLevelConfig_ResetPetBattles'] = {
        text = L["Reset Pet Battles Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            PlayerModule:ClearPetBattles()
            DisplayModule:Update()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs['XToLevelConfig_ResetDungeons'] = {
        text = L["Reset Dungeon Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            PlayerModule:ClearDungeonList()
            DisplayModule:Update()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs['XToLevelConfig_ResetDelves'] = {
        text = L["Reset Delve Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            PlayerModule:ClearDelveList()
            DisplayModule:Update()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

function ConfigModule:GetOptions()
    -- TODO: Migrate full options table from old Config.lua
    -- For now return a minimal options table
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    return {
        type = "group",
        name = "XToLevel",
        args = {
            general = {
                type = "group",
                name = L["General"] or "General",
                order = 1,
                args = {},
            },
        },
    }
end
