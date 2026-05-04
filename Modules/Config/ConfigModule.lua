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
-- Config module. Handles addon configuration GUI and options registration.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local ConfigModule = XToLevel:NewModule("ConfigModule")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Helpers = _XToLevel.Helpers
local Constants = _XToLevel.Constants

ConfigModule.frames = {}

function ConfigModule:OnInitialize()
end

function ConfigModule:OnEnable()
    self:RegisterOptions()
    self:RegisterDialogs()

    local head_frame_str = "XToLevel"
    local A3CFG = LibStub("AceConfigDialog-3.0")
    self.frames.Information = A3CFG:AddToBlizOptions("XToLevel", head_frame_str, nil, "Information")
    self.frames.General = A3CFG:AddToBlizOptions("XToLevel", L["General Tab"], head_frame_str, "General")
    self.frames.Messages = A3CFG:AddToBlizOptions("XToLevel", L["Messages Tab"], head_frame_str, "Messages")
    self.frames.Window = A3CFG:AddToBlizOptions("XToLevel", L["Window Tab"], head_frame_str, "Window")
    self.frames.LDB = A3CFG:AddToBlizOptions("XToLevel", L["LDB Tab"], head_frame_str, "LDB")
    self.frames.Data = A3CFG:AddToBlizOptions("XToLevel", L["Data Tab"], head_frame_str, "Data")
    self.frames.Tooltip = A3CFG:AddToBlizOptions("XToLevel", L["Tooltip"], head_frame_str, "Tooltip")
    self.frames.Timer = A3CFG:AddToBlizOptions("XToLevel", L["Timer"], head_frame_str, "Timer")
end

function ConfigModule:Open(frameName)
    if self.frames[frameName] then
        Settings.OpenToCategory(self.frames[frameName].name)
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

    StaticPopupDialogs['XToLevelConfig_ResetTimer'] = {
        text = L["Reset Timer Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            local db = DBModule:GetDB()
            db.char.data.timer.start = GetTime()
            db.char.data.timer.total = 0
            DisplayModule:Update()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs['XToLevelConfig_ResetGathering'] = {
        text = L["Reset Gathering Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            local db = DBModule:GetDB()
            db.char.data.gathering = {}
            DisplayModule:Update()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs['XToLevelConfig_LdbReload'] = {
        text = L["LDB Reload Dialog"],
        button1 = L["Yes"],
        button2 = L["No"],
        OnAccept = function()
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

end

-- ----------------------------------------------------------------------------
-- Config GUI callbacks (used as handler methods by AceConfig)
-- ----------------------------------------------------------------------------

function ConfigModule:SetActiveWindow(info, value)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    local DisplayModule = XToLevel:GetModule("DisplayModule")
    db.profile.averageDisplay.mode = value
    DisplayModule:Update()
end

function ConfigModule:GetActiveWindow(info)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    return db.profile.averageDisplay.mode
end

function ConfigModule:SetLdbPattern(info, value)
    local DBModule = XToLevel:GetModule("DBModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")
    local db = DBModule:GetDB()
    local thestr = nil
    for i, v in ipairs(Constants.LDB_PATTERNS) do
        if i == value then
            thestr = v
        end
    end
    if thestr then
        db.profile.ldb.textPattern = thestr
        DisplayModule:Update()
    else
        console:log("Could not switch pattern. Pattern not found...")
    end
end

function ConfigModule:GetLdbPattern(info)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()
    for i, v in ipairs(Constants.LDB_PATTERNS) do
        if db.profile.ldb.textPattern == v then
            return i
        end
    end
end

function ConfigModule:SetTimerEnabled(info, value)
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")
    local db = DBModule:GetDB()
    db.profile.timer.enabled = value
    if db.profile.timer.enabled then
        PlayerModule:StartTimerUpdate()
    else
        PlayerModule:StopTimerUpdate()
    end
    DisplayModule:Update()
end

-- ----------------------------------------------------------------------------
-- GetOptions - Full AceConfig options table
-- ----------------------------------------------------------------------------

function ConfigModule:GetOptions()
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")
    local db = DBModule:GetDB()

    local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown"
    local releaseDate = C_AddOns.GetAddOnMetadata(addonName, "X-ReleaseDate") or "unknown"

    local options = {
        name = "XToLevel",
        type = "group",
        handler = ConfigModule,
        args = {
            Information = {
                type = "group",
                name = "General",
                args = {
                    addonDescription = {
                        order = 0,
                        type = "description",
                        name = L["MainDescription"],
                    },
                    infoHeader = {
                        order = 1,
                        type = "header",
                        name = "AddOn Information",
                    },
                    infoVersion = {
                        order = 2,
                        type = "description",
                        name = "|cFFFFAA00" .. L["Version"] .. ":|r |cFF00FF00" .. tostring(version) .. "|r |cFFAAFFAA(" .. tostring(releaseDate) .. ")",
                    },
                    infoAuthor = {
                        order = 3,
                        type = "description",
                        name = "|cFFFFAA00" .. L["Author"] .. ":|r |cFFE07B02" .. "R4d1o4ct1v3_ (curseforge.com/members/r4d1o4ct1v3_)",
                    },
                    infoEmail = {
                        order = 4,
                        type = "description",
                        name = "|cFFFFAA00" .. L["Email"] .. ":|r |cFFFFFFFF" .. "r4d1o4ct1v3v3@gmail.com",
                    },
                    infoWebsite = {
                        order = 5,
                        type = "description",
                        name = "|cFFFFAA00" .. L["Website"] .. ":|r |cFFFFFFFF" .. "https://www.curseforge.com/wow/addons/xto-level",
                    },
                    infoCategory = {
                        order = 6,
                        type = "description",
                        name = "|cFFFFAA00" .. L["Category"] .. ":|r |cFFFFFFFF" .. "Quests & Leveling, Battlegrounds, Dungeons.",
                    },
                    infoLicense = {
                        order = 7,
                        type = "description",
                        name = "|cFFFFAA00" .. L["License"] .. ":|r |cFFFFFFFFMIT License (See LICENSE.txt)",
                    },
                }
            },
            General = {
                type = "group",
                name = "General",
                args = {
                    debugHeader = {
                        order = 0,
                        type = "header",
                        name = L["Misc Header"],
                    },
                    debugEnabled = {
                        order = 1,
                        type = "toggle",
                        name = L["Show Debug Info"],
                        desc = L["Debug Info Description"],
                        get = function(info) return db.profile.general.showDebug end,
                        set = function(info, value) db.profile.general.showDebug = value end,
                    },
                    rafEnabled = {
                        order = 2,
                        type = "toggle",
                        name = L["Recruit A Friend"],
                        desc = L["RAF Description"],
                        get = function(info) return db.profile.general.rafEnabled end,
                        set = function(info, value) db.profile.general.rafEnabled = value end,
                    },
                }
            },
            Messages = {
                type = "group",
                name = L["Messages Tab"],
                args = {
                    playerHeader = {
                        order = 0,
                        type = "header",
                        name = L["Player Messages"],
                    },
                    playerFloating = {
                        order = 1,
                        type = "toggle",
                        name = L["Show Floating"],
                        get = function(info) return db.profile.messages.playerFloating end,
                        set = function(info, value) db.profile.messages.playerFloating = value end,
                    },
                    playerChat = {
                        order = 2,
                        type = "toggle",
                        name = L["Show In Chat"],
                        get = function(info) return db.profile.messages.playerChat end,
                        set = function(info, value) db.profile.messages.playerChat = value end,
                    },
                    playerBG = {
                        order = 3,
                        type = "toggle",
                        name = L["Show BG Objectives"],
                        get = function(info) return db.profile.messages.bgObjectives end,
                        set = function(info, value) db.profile.messages.bgObjectives = value end,
                    },
                    colorsHeader = {
                        order = 4,
                        type = "header",
                        name = L["Message Colors"],
                    },
                    colorKills = {
                        order = 5,
                        type = "color",
                        name = L["Player Kills"],
                        hasAlpha = true,
                        get = function(info) return unpack(db.profile.messages.colors.playerKill) end,
                        set = function(info, r, g, b, a) db.profile.messages.colors.playerKill = {r, g, b, a} end,
                    },
                    colorQuests = {
                        order = 6,
                        type = "color",
                        name = L["Player Quests"],
                        hasAlpha = true,
                        get = function(info) return unpack(db.profile.messages.colors.playerQuest) end,
                        set = function(info, r, g, b, a) db.profile.messages.colors.playerQuest = {r, g, b, a} end,
                    },
                    colorDungeons = {
                        order = 7,
                        type = "color",
                        name = L["Player Dungeons"],
                        hasAlpha = true,
                        get = function(info) return unpack(db.profile.messages.colors.playerDungeon) end,
                        set = function(info, r, g, b, a) db.profile.messages.colors.playerDungeon = {r, g, b, a} end,
                    },
                    colorDelves = {
                        order = 8,
                        type = "color",
                        name = L["Player Delves"] or "Delves",
                        hasAlpha = true,
                        get = function(info) return unpack(db.profile.messages.colors.playerDelve) end,
                        set = function(info, r, g, b, a) db.profile.messages.colors.playerDelve = {r, g, b, a} end,
                    },
                    colorBattles = {
                        order = 9,
                        type = "color",
                        name = L["Player Battles"],
                        hasAlpha = true,
                        get = function(info) return unpack(db.profile.messages.colors.playerBattleground) end,
                        set = function(info, r, g, b, a) db.profile.messages.colors.playerBattleground = {r, g, b, a} end,
                    },
                    colorLevelup = {
                        order = 10,
                        type = "color",
                        name = L["Player Levelup"],
                        hasAlpha = true,
                        get = function(info) return unpack(db.profile.messages.colors.playerLevel) end,
                        set = function(info, r, g, b, a) db.profile.messages.colors.playerLevel = {r, g, b, a} end,
                    },
                    colorArchaeology = {
                        order = 11,
                        type = "color",
                        name = L["Archaeology"] or "Archaeology",
                        hasAlpha = true,
                        get = function(info) return unpack(db.profile.messages.colors.archaeology) end,
                        set = function(info, r, g, b, a) db.profile.messages.colors.archaeology = {r, g, b, a} end,
                    },
                    colorResetHeader = {
                        order = 12,
                        type = "header",
                        name = "",
                    },
                    colorResetBtn = {
                        order = 13,
                        type = "execute",
                        name = L["Color Reset"],
                        func = function() StaticPopup_Show("XToLevelConfig_MessageColorsReset") end,
                    },
                },
            },
            Window = {
                type = "group",
                name = L["Window Tab"],
                args = {
                    windowSelect = {
                        order = 0,
                        type = "select",
                        style = "dropdown",
                        name = L["Active Window Header"],
                        desc = L["Active Window Description"],
                        values = Constants.AVERAGE_WINDOWS,
                        get = "GetActiveWindow",
                        set = "SetActiveWindow",
                    },
                    windowScale = {
                        order = 1,
                        type = "range",
                        name = L["Window Size"] .. " (%)",
                        min = 0.5,
                        max = 2.0,
                        step = 0.05,
                        isPercent = true,
                        width = "full",
                        get = function(info) return db.profile.averageDisplay.scale end,
                        set = function(info, value)
                            db.profile.averageDisplay.scale = value
                            DisplayModule:Update()
                        end,
                    },
                    classicHeader = {
                        order = 2,
                        type = "header",
                        name = L["Classic Specific Options"],
                    },
                    classicShowBackdrop = {
                        order = 3,
                        type = "toggle",
                        name = L["Show Window Frame"],
                        get = function(info) return db.profile.averageDisplay.backdrop end,
                        set = function(info, value)
                            db.profile.averageDisplay.backdrop = value
                            DisplayModule:Update()
                        end,
                    },
                    classicShowHeader = {
                        order = 4,
                        type = "toggle",
                        name = L["Show XToLevel Header"],
                        get = function(info) return db.profile.averageDisplay.header end,
                        set = function(info, value)
                            db.profile.averageDisplay.header = value
                            DisplayModule:Update()
                        end,
                    },
                    classicShowVerbose = {
                        order = 5,
                        type = "toggle",
                        name = L["Show Verbose Text"],
                        get = function(info) return db.profile.averageDisplay.verbose end,
                        set = function(info, value)
                            db.profile.averageDisplay.verbose = value
                            DisplayModule:Update()
                        end,
                    },
                    classicShowColored = {
                        order = 6,
                        type = "toggle",
                        name = L["Show Colored Text"],
                        get = function(info) return db.profile.averageDisplay.colorText end,
                        set = function(info, value)
                            db.profile.averageDisplay.colorText = value
                            DisplayModule:Update()
                        end,
                    },
                    blockyHeader = {
                        order = 7,
                        type = "header",
                        name = L["Blocky Specific Options"],
                    },
                    blockyVerticalAlign = {
                        order = 8,
                        type = "toggle",
                        name = L["Vertical Align"],
                        get = function(info) return db.profile.averageDisplay.orientation == "v" end,
                        set = function(info, value)
                            db.profile.averageDisplay.orientation = value and "v" or "h"
                            DisplayModule:Update()
                        end,
                    },
                    behaviorHeader = {
                        order = 9,
                        type = "header",
                        name = L["Window Behavior Header"],
                    },
                    behaviorLocked = {
                        order = 10,
                        type = "toggle",
                        name = L["Lock Avarage Display"],
                        get = function(info) return not db.profile.general.allowDrag end,
                        set = function(info, value)
                            db.profile.general.allowDrag = not value
                        end,
                    },
                    behaviorAllowClick = {
                        order = 11,
                        type = "toggle",
                        name = L["Allow Average Click"],
                        get = function(info) return db.profile.general.allowSettingsClick end,
                        set = function(info, value)
                            db.profile.general.allowSettingsClick = value
                        end,
                    },
                    behaviorShowTooltip = {
                        order = 12,
                        type = "toggle",
                        name = L["Show Tooltip"],
                        get = function(info) return db.profile.averageDisplay.tooltip end,
                        set = function(info, value)
                            db.profile.averageDisplay.tooltip = value
                        end,
                    },
                    behaviorCombineTooltip = {
                        order = 13,
                        type = "toggle",
                        name = L["Combine Tooltip Data"],
                        get = function(info) return db.profile.averageDisplay.combineTooltip end,
                        set = function(info, value)
                            db.profile.averageDisplay.combineTooltip = value
                        end,
                    },
                    behaviorProgressAsBars = {
                        order = 14,
                        type = "toggle",
                        name = L["Progress As Bars"],
                        get = function(info) return db.profile.averageDisplay.progressAsBars end,
                        set = function(info, value)
                            db.profile.averageDisplay.progressAsBars = value
                            DisplayModule:Update()
                        end,
                    },
                    behaviourArchaeologyDataToggle = {
                        order = 15,
                        type = "toggle",
                        name = L["Archaeology as sites"],
                        get = function(info) return db.profile.averageDisplay.archaeologyAsSites end,
                        set = function(info, value)
                            db.profile.averageDisplay.archaeologyAsSites = value
                            DisplayModule:Update()
                        end,
                    },
                    dataHeader = {
                        order = 16,
                        type = "header",
                        name = L["LDB Player Data Header"],
                    },
                    dataKills = {
                        order = 17,
                        type = "toggle",
                        name = L["Kills"],
                        get = function(info) return db.profile.averageDisplay.playerKills end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerKills = value
                            DisplayModule:Update()
                        end,
                    },
                    dataQuests = {
                        order = 18,
                        type = "toggle",
                        name = L["Player Quests"],
                        get = function(info) return db.profile.averageDisplay.playerQuests end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerQuests = value
                            DisplayModule:Update()
                        end,
                    },
                    dataDungeons = {
                        order = 19,
                        type = "toggle",
                        name = L["Player Dungeons"],
                        get = function(info) return db.profile.averageDisplay.playerDungeons end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerDungeons = value
                            DisplayModule:Update()
                        end,
                    },
                    dataDelves = {
                        order = 20,
                        type = "toggle",
                        name = L["Player Delves"] or "Delves",
                        get = function(info) return db.profile.averageDisplay.playerDelves end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerDelves = value
                            DisplayModule:Update()
                        end,
                    },
                    dataBattles = {
                        order = 21,
                        type = "toggle",
                        name = L["Player Battles"],
                        get = function(info) return db.profile.averageDisplay.playerBGs end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerBGs = value
                            DisplayModule:Update()
                        end,
                    },
                    dataBattleObjectives = {
                        order = 22,
                        type = "toggle",
                        name = L["Player Objectives"],
                        get = function(info) return db.profile.averageDisplay.playerBGOs end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerBGOs = value
                            DisplayModule:Update()
                        end,
                    },
                    dataProgress = {
                        order = 23,
                        type = "toggle",
                        name = L["Player Progress"],
                        get = function(info) return db.profile.averageDisplay.playerProgress end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerProgress = value
                            DisplayModule:Update()
                        end,
                    },
                    dataTimer = {
                        order = 24,
                        type = "toggle",
                        name = L["Player Timer"],
                        get = function(info) return db.profile.averageDisplay.playerTimer end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerTimer = value
                            DisplayModule:Update()
                        end,
                    },
                    dataGathering = {
                        order = 25,
                        type = "toggle",
                        name = L["Gathering"] or "Gathering",
                        get = function(info) return db.profile.averageDisplay.playerGathering end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerGathering = value
                            DisplayModule:Update()
                        end,
                    },
                    dataPetBattle = {
                        order = 26,
                        type = "toggle",
                        name = L["Pet Battles"] or "Pet Battles",
                        get = function(info) return db.profile.averageDisplay.playerPetBattles end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerPetBattles = value
                            DisplayModule:Update()
                        end,
                    },
                    dataArchaeology = {
                        order = 27,
                        type = "toggle",
                        name = L["Archaeology"] or "Archaeology",
                        get = function(info) return db.profile.averageDisplay.playerDigs end,
                        set = function(info, value)
                            db.profile.averageDisplay.playerDigs = value
                            DisplayModule:Update()
                        end,
                    },
                }
            },
            LDB = {
                type = "group",
                name = L["LDB Tab"],
                args = {
                    ldbEnabled = {
                        order = 0,
                        type = "toggle",
                        name = L["LDB Enabled"],
                        desc = L["LDB Enabled Description"],
                        get = function(i) return db.profile.ldb.enabled end,
                        set = function(i, v)
                            db.profile.ldb.enabled = v
                            StaticPopup_Show("XToLevelConfig_LdbReload")
                        end
                    },
                    ldbPresetHeader = {
                        order = 1,
                        type = "header",
                        name = L["LDB Patterns Header"],
                    },
                    ldbPatternSelect = {
                        order = 2,
                        type = "select",
                        style = "dropdown",
                        name = L["LDB Pattern Select"],
                        values = Constants.LDB_PATTERNS,
                        get = "GetLdbPattern",
                        set = "SetLdbPattern",
                    },
                    ldbPatternInput = {
                        order = 3,
                        type = "input",
                        name = L["Custom Pattern Label"],
                        desc = L["Custom Pattern Description"],
                        width = "full",
                        multiline = true,
                        get = function(i) return db.char.customPattern end,
                        set = function(i, v)
                            db.char.customPattern = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbAppearenceHeader = {
                        order = 4,
                        type = "header",
                        name = L["LDB Appearence Header"],
                    },
                    ldbShowText = {
                        order = 5,
                        type = "toggle",
                        name = L["Show Text"],
                        get = function(i) return db.profile.ldb.showText end,
                        set = function(i, v)
                            db.profile.ldb.showText = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbShowLabel = {
                        order = 6,
                        type = "toggle",
                        name = L["Show Label"],
                        get = function(i) return db.profile.ldb.showLabel end,
                        set = function(i, v)
                            db.profile.ldb.showLabel = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbShowIcon = {
                        order = 7,
                        type = "toggle",
                        name = L["Show Icon"],
                        get = function(i) return db.profile.ldb.showIcon end,
                        set = function(i, v)
                            db.profile.ldb.showIcon = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbColoredText = {
                        order = 8,
                        type = "toggle",
                        name = L["Allow Colored Text"],
                        get = function(i) return db.profile.ldb.allowTextColor end,
                        set = function(i, v)
                            db.profile.ldb.allowTextColor = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbColorByXp = {
                        order = 9,
                        type = "toggle",
                        name = L["Color By XP"],
                        get = function(i) return db.profile.ldb.text.colorValues end,
                        set = function(i, v)
                            db.profile.ldb.text.colorValues = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbProgressAsBars = {
                        order = 10,
                        type = "toggle",
                        name = L["Show Progress As Bars"],
                        get = function(i) return db.profile.ldb.text.xpAsBars end,
                        set = function(i, v)
                            db.profile.ldb.text.xpAsBars = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbShowVerbose = {
                        order = 11,
                        type = "toggle",
                        name = L["Show Verbose"],
                        get = function(i) return db.profile.ldb.text.verbose end,
                        set = function(i, v)
                            db.profile.ldb.text.verbose = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbShowXpRemaining = {
                        order = 12,
                        type = "toggle",
                        name = L["Show XP remaining"],
                        get = function(i) return db.profile.ldb.text.xpCountdown end,
                        set = function(i, v)
                            db.profile.ldb.text.xpCountdown = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbShortenXP = {
                        order = 13,
                        type = "toggle",
                        name = L["Shorten XP values"],
                        get = function(i) return db.profile.ldb.text.xpnumFormat end,
                        set = function(i, v)
                            db.profile.ldb.text.xpnumFormat = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbDataHeader = {
                        order = 14,
                        type = "header",
                        name = L["LDB Player Data Header"],
                    },
                    ldbDataKills = {
                        order = 16,
                        type = "toggle",
                        name = L["Player Kills"],
                        get = function(i) return db.profile.ldb.text.kills end,
                        set = function(i, v)
                            db.profile.ldb.text.kills = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbDataQuests = {
                        order = 17,
                        type = "toggle",
                        name = L["Player Quests"],
                        get = function(i) return db.profile.ldb.text.quests end,
                        set = function(i, v)
                            db.profile.ldb.text.quests = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbDataDungeons = {
                        order = 18,
                        type = "toggle",
                        name = L["Player Dungeons"],
                        get = function(i) return db.profile.ldb.text.dungeons end,
                        set = function(i, v)
                            db.profile.ldb.text.dungeons = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbDataBattles = {
                        order = 19,
                        type = "toggle",
                        name = L["Player Battles"],
                        get = function(i) return db.profile.ldb.text.bgs end,
                        set = function(i, v)
                            db.profile.ldb.text.bgs = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbDataObjectives = {
                        order = 20,
                        type = "toggle",
                        name = L["Player Objectives"],
                        get = function(i) return db.profile.ldb.text.bgo end,
                        set = function(i, v)
                            db.profile.ldb.text.bgo = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbDataProgress = {
                        order = 21,
                        type = "toggle",
                        name = L["Player Progress"],
                        get = function(i) return db.profile.ldb.text.xp end,
                        set = function(i, v)
                            db.profile.ldb.text.xp = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbDataExperience = {
                        order = 22,
                        type = "toggle",
                        name = L["Player Experience"],
                        get = function(i) return db.profile.ldb.text.xpnum end,
                        set = function(i, v)
                            db.profile.ldb.text.xpnum = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbDataGathering = {
                        order = 23,
                        type = "toggle",
                        name = L["Gathering"],
                        get = function(i) return db.profile.ldb.text.gather end,
                        set = function(i, v)
                            db.profile.ldb.text.gather = v
                            DisplayModule:Update()
                        end,
                    },
                    ldbDataArchaeology = {
                        order = 24,
                        type = "toggle",
                        name = L["Archaeology"],
                        get = function(i) return db.profile.ldb.text.digs end,
                        set = function(i, v)
                            db.profile.ldb.text.digs = v
                            DisplayModule:Update()
                        end,
                    },
                }
            },
            Data = {
                type = "group",
                name = L["Data Tab"],
                args = {
                    dataRangeHeader = {
                        order = 0,
                        type = "header",
                        name = L["Data Range Header"],
                    },
                    dataRangeDescription = {
                        order = 1,
                        type = "description",
                        name = L["Data Range Subheader"],
                    },
                    dataRangeKills = {
                        order = 2,
                        type = "range",
                        name = L["Player Kills"],
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function() return db.profile.averageDisplay.playerKillListLength end,
                        set = function(i, v) PlayerModule:SetKillAverageLength(v) end,
                    },
                    dataRangeQuests = {
                        order = 3,
                        type = "range",
                        name = L["Player Quests"],
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function() return db.profile.averageDisplay.playerQuestListLength end,
                        set = function(i, v) PlayerModule:SetQuestAverageLength(v) end,
                    },
                    dataRangePetBattles = {
                        order = 4,
                        type = "range",
                        name = L["Pet Battles"],
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function() return db.profile.averageDisplay.playerPetBattleListLength end,
                        set = function(i, v) PlayerModule:SetPetBattleAverageLength(v) end,
                    },
                    dataRangeBattles = {
                        order = 5,
                        type = "range",
                        name = L["Player Battles"],
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function() return db.profile.averageDisplay.playerBGListLength end,
                        set = function(i, v) PlayerModule:SetBattleAverageLength(v) end,
                    },
                    dataRangeObjectives = {
                        order = 6,
                        type = "range",
                        name = L["Player Objectives"],
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function() return db.profile.averageDisplay.playerBGOListLength end,
                        set = function(i, v) PlayerModule:SetObjectiveAverageLength(v) end,
                    },
                    dataRangeDungeons = {
                        order = 7,
                        type = "range",
                        name = L["Player Dungeons"],
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function() return db.profile.averageDisplay.playerDungeonListLength end,
                        set = function(i, v) PlayerModule:SetDungeonAverageLength(v) end,
                    },
                    dataRangeDelves = {
                        order = 8,
                        type = "range",
                        name = L["Player Delves"] or "Delves",
                        min = 1,
                        max = 100,
                        step = 1,
                        get = function() return db.profile.averageDisplay.playerDelveListLength end,
                        set = function(i, v) PlayerModule:SetDelveAverageLength(v) end,
                    },
                    dataClearHeader = {
                        order = 9,
                        type = "header",
                        name = L["Clear Data Header"],
                    },
                    dataClearDescription = {
                        order = 10,
                        type = "description",
                        name = L["Clear Data Subheader"],
                    },
                    dataClearKills = {
                        order = 11,
                        type = "execute",
                        name = L["Reset Player Kills"],
                        func = function() StaticPopup_Show("XToLevelConfig_ResetPlayerKills") end,
                    },
                    dataClearQuests = {
                        order = 12,
                        type = "execute",
                        name = L["Reset Player Quests"],
                        func = function() StaticPopup_Show("XToLevelConfig_ResetPlayerQuests") end,
                    },
                    dataClearDungeons = {
                        order = 13,
                        type = "execute",
                        name = L["Reset Dungeons"],
                        func = function() StaticPopup_Show("XToLevelConfig_ResetDungeons") end,
                    },
                    dataClearDelves = {
                        order = 14,
                        type = "execute",
                        name = L["Reset Delves"] or "Reset Delves",
                        func = function() StaticPopup_Show("XToLevelConfig_ResetDelves") end,
                    },
                    dataClearBattles = {
                        order = 15,
                        type = "execute",
                        name = L["Reset Battlegrounds"],
                        func = function() StaticPopup_Show("XToLevelConfig_ResetBattles") end,
                    },
                    dataClearPetBattles = {
                        order = 16,
                        type = "execute",
                        name = L["Reset Pet Battles"],
                        func = function() StaticPopup_Show("XToLevelConfig_ResetPetBattles") end,
                    },
                    dataClearGathering = {
                        order = 17,
                        type = "execute",
                        name = L["Reset Gathering"],
                        func = function() StaticPopup_Show("XToLevelConfig_ResetGathering") end,
                    },
                }
            },
            Tooltip = {
                type = "group",
                name = L["Tooltip"],
                args = {
                    sectionsHeader = {
                        order = 1,
                        type = "header",
                        name = L["Tooltip Sections Header"],
                    },
                    playerDetails = {
                        order = 2,
                        type = "toggle",
                        name = L["Show Player Details"],
                        get = function(i) return db.profile.ldb.tooltip.showDetails end,
                        set = function(i, v) db.profile.ldb.tooltip.showDetails = v end,
                    },
                    playerExperience = {
                        order = 3,
                        type = "toggle",
                        name = L["Show Player Experience"],
                        get = function(i) return db.profile.ldb.tooltip.showExperience end,
                        set = function(i, v) db.profile.ldb.tooltip.showExperience = v end,
                    },
                    battleInfo = {
                        order = 4,
                        type = "toggle",
                        name = L["Show Battleground Info"],
                        get = function(i) return db.profile.ldb.tooltip.showBGInfo end,
                        set = function(i, v) db.profile.ldb.tooltip.showBGInfo = v end,
                    },
                    dungeonInfo = {
                        order = 5,
                        type = "toggle",
                        name = L["Show Dungeon Info"],
                        get = function(i) return db.profile.ldb.tooltip.showDungeonInfo end,
                        set = function(i, v) db.profile.ldb.tooltip.showDungeonInfo = v end,
                    },
                    gatheringInfo = {
                        order = 6,
                        type = "toggle",
                        name = L["Show Gathering Info"],
                        get = function(i) return db.profile.ldb.tooltip.showGatheringInfo end,
                        set = function(i, v) db.profile.ldb.tooltip.showGatheringInfo = v end,
                    },
                    archaeologyDetails = {
                        order = 7,
                        type = "toggle",
                        name = L["Show Archaeology Details"],
                        get = function(i) return db.profile.ldb.tooltip.showArchaeologyInfo end,
                        set = function(i, v) db.profile.ldb.tooltip.showArchaeologyInfo = v end,
                    },
                    timerDetails = {
                        order = 8,
                        type = "toggle",
                        name = L["Show Timer Details"],
                        get = function(i) return db.profile.ldb.tooltip.showTimerInfo end,
                        set = function(i, v) db.profile.ldb.tooltip.showTimerInfo = v end,
                    },
                    miscHeader = {
                        order = 9,
                        type = "header",
                        name = L["Misc Header"],
                    },
                    npcTooltipData = {
                        order = 10,
                        type = "toggle",
                        name = L["Show kills needed in NPC tooltips"],
                        get = function(i) return db.profile.general.showNpcTooltipData end,
                        set = function(i, v) db.profile.general.showNpcTooltipData = v end,
                    },
                }
            },
            Timer = {
                type = "group",
                name = L["Timer"],
                args = {
                    enableTimer = {
                        order = 0,
                        type = "toggle",
                        name = L["Enable Timer"],
                        get = function() return db.profile.timer.enabled end,
                        set = "SetTimerEnabled",
                    },
                    modeHeader = {
                        order = 1,
                        type = "header",
                        name = L["Mode"],
                    },
                    modeSelect = {
                        order = 2,
                        type = "select",
                        style = "dropdown",
                        values = Constants.TIMER_MODES,
                        name = L["Mode"],
                        desc = L["Timer mode description"],
                        get = function() return db.profile.timer.mode end,
                        set = function(i, v) db.profile.timer.mode = v end,
                    },
                    timerReset = {
                        order = 3,
                        type = "execute",
                        name = L["Timer Reset"],
                        desc = L["Timer Reset Description"],
                        func = function() StaticPopup_Show("XToLevelConfig_ResetTimer") end,
                    },
                    timeoutHeader = {
                        order = 4,
                        type = "header",
                        name = L["Session Timeout Header"],
                    },
                    timoutRange = {
                        order = 5,
                        type = "range",
                        name = L["Session Timeout Label"],
                        desc = L["Session Timeout Description"],
                        min = 0,
                        max = 60,
                        step = 1,
                        get = function() return db.profile.timer.sessionDataTimeout end,
                        set = function(i, v) db.profile.timer.sessionDataTimeout = v end,
                    },
                }
            },
        },
    }

    -- Remove Classic-incompatible options
    if Helpers:IsClassic() then
        options.args.Messages.args.colorArchaeology = nil
        options.args.Messages.args.colorDelves = nil
        options.args.Window.args.behaviourArchaeologyDataToggle = nil
        options.args.Window.args.dataGathering = nil
        options.args.Window.args.dataPetBattle = nil
        options.args.Window.args.dataArchaeology = nil
        options.args.Window.args.dataDelves = nil
        options.args.LDB.args.ldbDataGathering = nil
        options.args.LDB.args.ldbDataArchaeology = nil
        options.args.Data.args.dataRangePetBattles = nil
        options.args.Data.args.dataRangeDelves = nil
        options.args.Data.args.dataClearPetBattles = nil
        options.args.Data.args.dataClearGathering = nil
        options.args.Data.args.dataClearDelves = nil
        options.args.Tooltip.args.gatheringInfo = nil
        options.args.Tooltip.args.archaeologyDetails = nil
    end

    return options
end
