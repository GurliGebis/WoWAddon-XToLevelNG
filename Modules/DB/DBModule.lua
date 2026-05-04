---
-- Database module. Wraps AceDB-3.0 initialization and provides access to the DB.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local DBModule = XToLevel:NewModule("DBModule")

local defaultOptions = {
    profile = {
        general = {
            allowDrag = true,
            allowSettingsClick = true,
            displayLocale = GetLocale(),
            showDebug = false,
            rafEnabled = false,
            showNpcTooltipData = true,
        },
        messages = {
            playerFloating = true,
            playerChat = false,
            bgObjectives = true,
            colors = {
                playerKill = {0.72, 1, 0.71, 1},
                playerQuest = {0.5, 1, 0.7, 1},
                playerBattleground = {1, 0.5, 0.5, 1},
                playerDungeon = {1, 0.75, 0.35, 1},
                playerDelve = {0.4, 0.85, 1.0, 1},
                playerLevel = {0.35, 1, 0.35, 1},
                archaeology = {1.0, 0.5, 0.15, 1},
            },
        },
        averageDisplay = {
            visible = true,
            mode = 1,
            scale = 1.0,
            backdrop = true,
            verbose = true,
            colorText = true,
            header = true,
            tooltip = true,
            combineTooltip = false,
            orientation = 'v',
            playerKills = true,
            playerQuests = true,
            playerPetBattles = true,
            playerDungeons = true,
            playerDelves = true,
            playerBGs = true,
            playerBGOs = false,
            playerGathering = true,
            playerDigs = true,
            playerProgress = true,
            playerTimer = true,
            progress = true,
            progressAsBars = false,
            archaeologyAsSites = false,
            playerKillListLength = 10,
            playerQuestListLength = 10,
            playerPetBattleListLength = 10,
            playerBGListLength = 15,
            playerBGOListLength = 15,
            playerDungeonListLength = 15,
            playerDelveListLength = 15,
            guildProgress = true,
            guildProgressType = 1,
        },
        ldb = {
            enabled = true,
            allowTextColor = true,
            showIcon = true,
            showLabel = false,
            showText = true,
            textPattern = "default",
            text = {
                kills = true,
                quests = true,
                dungeons = true,
                delves = true,
                bgs = true,
                bgo = false,
                gather = true,
                digs = true,
                xp = true,
                xpnum = true,
                xpnumFormat = true,
                xpAsBars = false,
                xpCountdown = false,
                timer = true,
                guildxp = true,
                guilddaily = true,
                colorValues = true,
                verbose = true,
                rested = true,
                restedp = true,
            },
            tooltip = {
                showDetails = true,
                showExperience = true,
                showBGInfo = true,
                showDungeonInfo = true,
                showDelveInfo = true,
                showTimerInfo = true,
                showGatheringInfo = true,
                showArchaeologyInfo = true,
                showGuildInfo = true,
            },
        },
        timer = {
            enabled = true,
            mode = 1,
            allowLevelFallback = true,
            sessionDataTimeout = 5.0,
        },
    },
    char = {
        data = {
            total = {
                startedRecording = time(),
                mobKills = 0,
                dungeonKills = 0,
                pvpKills = 0,
                quests = 0,
                objectives = 0,
            },
            killAverage = 0,
            questAverage = 0,
            killList = {},
            questList = {},
            bgList = {},
            dungeonList = {},
            delveList = {},
            petBattleList = {},
            timer = {
                start = nil,
                total = nil,
                xpPerSec = nil,
            },
            gathering = {},
            digs = {},
            npcXP = {},
        },
        customPattern = nil,
    },
}

function DBModule:OnInitialize()
    self.AceDB = LibStub("AceDB-3.0"):New("XToLevelDB", defaultOptions)
    self:MigrateOldData()
    self:VerifyData()
end

function DBModule:GetDB()
    return self.AceDB
end

function DBModule:GetProfile()
    return self.AceDB.profile
end

function DBModule:GetCharData()
    return self.AceDB.char.data
end

function DBModule:GetDefaults()
    return defaultOptions
end

--- Migrates old sData/sConfig saved variables into AceDB.
function DBModule:MigrateOldData()
    if sData and type(sData) == "table" then
        self.AceDB.char.customPattern = sData.customPattern
        self.AceDB.char.data = sData.player
        sData = nil
    end
    if sConfig and type(sConfig) == "table" then
        self.AceDB.profile.general = sConfig.general
        self.AceDB.profile.messages = sConfig.messages
        self.AceDB.profile.averageDisplay = sConfig.averageDisplay
        self.AceDB.profile.ldb = sConfig.ldb
        self.AceDB.profile.timer = sConfig.timer
        sConfig = nil
    end
end

--- Verifies data integrity after load.
function DBModule:VerifyData()
    local data = self.AceDB.char.data
    local profile = self.AceDB.profile

    -- Timer session validity
    if type(data.timer.lastUpdated) ~= "number"
        or GetTime() - data.timer.lastUpdated > (profile.timer.sessionDataTimeout * 60)
        or GetTime() - (data.timer.start or 0) <= 0 then
        data.timer.start = GetTime()
        data.timer.total = 0
        data.timer.lastUpdated = GetTime()
    end

    -- Dungeon rested field
    for index = 1, #data.dungeonList do
        if not data.dungeonList[index].rested then
            data.dungeonList[index].rested = 0
        end
    end

    -- Delve rested field
    for index = 1, #data.delveList do
        if not data.delveList[index].rested then
            data.delveList[index].rested = 0
        end
    end

    -- Clear old NPC XP structure
    if type(data.npcXP) == "table" and (data.npcXP[1] == nil or type(data.npcXP[1].name) ~= "string") then
        table.wipe(data.npcXP)
        data.npcXP = {}
    end
end
