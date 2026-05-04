---
-- Events module. Handles all game event routing and game logic.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local EventsModule = XToLevel:NewModule("EventsModule", "AceEvent-3.0", "AceTimer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Helpers = _XToLevel.Helpers

-- State
EventsModule.playerHasXpLossRequest = false
EventsModule.playerHasResurrectRequest = false
EventsModule.hasLfgProposalSucceeded = false
EventsModule.questCompleteDialogOpen = false
EventsModule.questCompleteDialogLastOpen = 0
EventsModule.gatheringAction = nil
EventsModule.gatheringTarget = nil
EventsModule.gatheringTime = nil
EventsModule.petBattleOver = nil
EventsModule.digsiteProgress = 0
EventsModule.surveyFoundComplete = nil

local targetList = {}
local regenEnabled = true
local targetUpdatePending = false

function EventsModule:OnInitialize()
end

function EventsModule:OnEnable()
    local PlayerModule = XToLevel:GetModule("PlayerModule")

    -- Only register events if below max level
    if PlayerModule.level >= PlayerModule:GetMaxLevel() then
        return
    end

    self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN", "OnChatXPGain")
    self:RegisterEvent("CHAT_MSG_OPENING", "OnChatMsgOpening")
    self:RegisterEvent("PLAYER_LEVEL_UP", "OnPlayerLevelUp")
    self:RegisterEvent("PLAYER_XP_UPDATE", "OnPlayerXPUpdate")
    self:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND", "OnPlayerEnteringBattleground")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "OnAreaChanged")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnAreaChanged")
    self:RegisterEvent("ZONE_CHANGED", "OnAreaChanged")
    self:RegisterEvent("PLAYER_UNGHOST", "OnPlayerUnghost")
    self:RegisterEvent("CONFIRM_XP_LOSS", "OnConfirmXpLoss")
    self:RegisterEvent("RESURRECT_REQUEST", "OnResurrectRequest")
    self:RegisterEvent("PLAYER_ALIVE", "OnPlayerAlive")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "OnEquipmentChanged")
    self:RegisterEvent("TIME_PLAYED_MSG", "OnTimePlayedMsg")
    self:RegisterEvent("QUEST_COMPLETE", "OnQuestComplete")
    self:RegisterEvent("QUEST_FINISHED", "OnQuestFinished")
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnPlayerTargetChanged")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerRegenEnabled")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnPlayerRegenDisabled")

    if issecretvalue then
        self:RegisterEvent("PARTY_KILL", "OnPartyKill")
    else
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEventUnfiltered")
    end

    if not Helpers:IsClassic() then
        self:RegisterEvent("LFG_PROPOSAL_SUCCEEDED", "OnLfgProposalSucceeded")
        self:RegisterEvent("PET_BATTLE_OVER", "OnPetBattleOver")
        self:RegisterEvent("ARCHAEOLOGY_FIND_COMPLETE", "OnArchaeologyFindComplete")
        self:RegisterEvent("ARTIFACT_DIGSITE_COMPLETE", "OnDigsiteComplete")
    end

    -- Register slash commands
    SLASH_XTOLEVEL1 = "/xtolevel"
    SLASH_XTOLEVEL2 = "/xtl"
    SlashCmdList["XTOLEVEL"] = function(arg1) EventsModule:OnSlashCommand(arg1) end

    -- Trigger time played request
    self:ScheduleTimer("TimePlayedTriggerCallback", 2)
end

function EventsModule:TimePlayedTriggerCallback()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    if PlayerModule.timePlayedTotal == nil or PlayerModule.timePlayedLevel == nil then
        RequestTimePlayed()
    end
end

function EventsModule:OnPlayerTargetChanged()
    if not regenEnabled then
        local target_guid = UnitGUID("target")
        if target_guid ~= nil and not issecretvalue(target_guid) then
            local target_name = UnitName("target")
            local target_level = UnitLevel("target")
            local target_classification = UnitClassification("target")
            local exists = false

            for i, data in ipairs(targetList) do
                if data.guid == target_guid then
                    exists = true
                    targetList[i].name = target_name
                    targetList[i].level = target_level
                    targetList[i].classification = target_classification
                end
            end

            if not exists then
                table.insert(targetList, {
                    guid = target_guid,
                    name = target_name,
                    level = target_level,
                    classification = target_classification,
                    dead = false,
                    xp = nil,
                })
            end
        end
    end
end

function EventsModule:OnCombatLogEventUnfiltered()
    local cl_event = select(2, CombatLogGetCurrentEventInfo())
    if cl_event == "UNIT_DIED" then
        local npc_guid = select(8, CombatLogGetCurrentEventInfo())
        self:MarkTargetDead(npc_guid)
    end
end

function EventsModule:OnPartyKill(event, attacker, target)
    if issecretvalue(attacker) or issecretvalue(target) then return end
    if attacker ~= UnitGUID("player") then return end
    self:MarkTargetDead(target)
end

function EventsModule:MarkTargetDead(npc_guid)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    for i, data in ipairs(targetList) do
        if data.guid == npc_guid then
            data.dead = true
            if type(targetUpdatePending) == "number" and targetUpdatePending > 0 then
                data.xp = targetUpdatePending
                targetUpdatePending = nil
                self:AddMobXpRecord(data.name, data.level, UnitLevel("player"), data.xp, data.classification)
            end
        end
    end
end

function EventsModule:OnPlayerRegenDisabled()
    regenEnabled = false
    self:OnPlayerTargetChanged()
end

function EventsModule:OnPlayerRegenEnabled()
    regenEnabled = true
    table.wipe(targetList)
end

function EventsModule:AddMobXpRecord(mobName, mobLevel, playerLevel, xp, mobClassification)
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if type(mobClassification) ~= "string" then
        mobClassification = "normal"
    end
    local mobClassIndex = Helpers:ConvertClassification(mobClassification)
    if mobClassIndex == nil then
        mobClassIndex = 1
    end

    if type(db.char.data.npcXP) ~= "table" then
        db.char.data.npcXP = {}
    end

    local existingIndex = -1
    for i, d in ipairs(db.char.data.npcXP) do
        if d.name == mobName and d.level == mobLevel then
            existingIndex = i
            break
        end
    end

    if existingIndex == -1 then
        table.insert(db.char.data.npcXP, {
            name = mobName,
            level = mobLevel,
            xp = xp,
        })
    elseif db.char.data.npcXP[existingIndex].xp ~= xp then
        db.char.data.npcXP[existingIndex].xp = xp
    end
end

function EventsModule:OnEquipmentChanged(event, slot, hasItem)
    -- Clear tooltip XP cache when equipment changes
end

function EventsModule:OnPlayerLevelUp(event, newLevel)
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")

    PlayerModule.level = newLevel
    PlayerModule.timePlayedLevel = 0
    PlayerModule.timePlayedUpdated = time()

    if newLevel >= PlayerModule:GetMaxLevel() then
        PlayerModule.isActive = false
        self:UnregisterAllEvents()
    end

    PlayerModule:ClearKills()
    PlayerModule:ClearQuests()

    DisplayModule:Update()
end

function EventsModule:OnChatMsgOpening(event, message)
    local regexp = string.gsub(OPEN_LOCK_SELF, "%%%d?%$?s", "(.+)")
    local action, target = strmatch(message, regexp)

    self.gatheringAction = action
    self.gatheringTarget = target
    self.gatheringTime = GetTime()
end

function EventsModule:OnChatXPGain(event, message)
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    local isQuest = self.questCompleteDialogOpen or (GetTime() - self.questCompleteDialogLastOpen) < 2
    local isArch = self.surveyFoundComplete ~= nil and self.surveyFoundComplete + 30 >= time()
    local xp, mobName = Helpers:ParseChatXPMessage(message, isQuest)
    xp = tonumber(xp)
    if not xp then
        console:log("Failed to parse XP Gain message: '" .. tostring(message) .. "'")
        return false
    end

    -- Update timer total
    if db.profile.timer.enabled then
        db.char.data.timer.total = db.char.data.timer.total + xp
    end

    if mobName ~= nil then
        if PlayerModule:IsBattlegroundInProgress() then
            PlayerModule:AddBattlegroundKill(xp, mobName)
        else
            local unrestedXP = PlayerModule:AddKill(xp, mobName)

            -- Update target list
            local found = false
            for i, data in ipairs(targetList) do
                if not issecretvalue(mobName) and data.name == mobName and data.dead and data.xp == nil then
                    targetList[i].xp = unrestedXP
                    found = true
                    self:AddMobXpRecord(data.name, data.level, UnitLevel("player"), data.xp, data.classification)
                end
            end
            if not found then
                targetUpdatePending = unrestedXP
            end

            -- Messages
            if db.profile.messages.playerFloating or db.profile.messages.playerChat then
                local killsRequired = PlayerModule:GetKillsRequired(unrestedXP)
                if killsRequired > 0 then
                    DisplayModule:PrintKill(mobName, killsRequired)
                end
            end

            -- Dungeon kill tracking
            if PlayerModule:IsDungeonInProgress() then
                PlayerModule:AddDungeonKill(unrestedXP, mobName, (xp - unrestedXP))
            end

            -- Delve kill tracking
            if PlayerModule:IsDelveInProgress() then
                PlayerModule:AddDelveKill(unrestedXP, mobName, (xp - unrestedXP))
            end
        end
    else
        if PlayerModule:IsBattlegroundInProgress() then
            local isObj = PlayerModule:AddBattlegroundObjective(xp)
            if isObj and PlayerModule.isActive then
                local objectivesRequired = PlayerModule:GetQuestsRequired(xp)
                if objectivesRequired > 0 then
                    DisplayModule:PrintBGObjective(objectivesRequired)
                end
            end
        else
            if isQuest then
                PlayerModule:AddQuest(xp)
                if db.profile.messages.playerFloating or db.profile.messages.playerChat then
                    local questsRequired = PlayerModule:GetQuestsRequired(xp)
                    if questsRequired > 0 then
                        DisplayModule:PrintQuest(questsRequired)
                    end
                end
            elseif isArch then
                self.surveyFoundComplete = nil
                PlayerModule:AddDig(xp)
                if db.profile.messages.playerFloating or db.profile.messages.playerChat then
                    local digsRequired = PlayerModule:GetQuestsRequired(xp)
                    if digsRequired > 0 then
                        DisplayModule:PrintDig(digsRequired)
                    end
                end
            else
                if self.gatheringTarget ~= nil and self.gatheringTime ~= nil and GetTime() - self.gatheringTime < 5 then
                    local unrestedXP = PlayerModule:AddGathering(xp)
                    local remaining = PlayerModule:GetKillsRequired(unrestedXP)
                    if type(remaining) == "number" and remaining > 0 then
                        DisplayModule:PrintKill(self.gatheringTarget, remaining)
                    end
                    self.gatheringTarget = nil
                    self.gatheringAction = nil
                    self.gatheringTime = nil
                elseif self.petBattleOver ~= nil and GetTime() - self.petBattleOver < 5 then
                    local remaining = PlayerModule:GetPetBattlesRequired(xp) - 1
                    if type(remaining) == "number" and remaining > 0 then
                        PlayerModule:AddPetBattle(xp)
                        DisplayModule:PrintKill(L["Battles Like That"], remaining)
                    end
                    self.petBattleOver = nil
                else
                    local remaining = PlayerModule:GetQuestsRequired(xp) - 1
                    if PlayerModule:IsDungeonInProgress() then
                        PlayerModule:AddDungeonKill(xp, "Bonus", 0)
                    end
                    if type(remaining) == "number" and remaining > 0 then
                        DisplayModule:PrintAnonymous(remaining)
                    end
                end
            end
        end
    end
end

function EventsModule:OnQuestComplete()
    self.questCompleteDialogOpen = true
end

function EventsModule:OnQuestFinished()
    self.questCompleteDialogOpen = false
    self.questCompleteDialogLastOpen = GetTime()
end

function EventsModule:OnPlayerXPUpdate()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    PlayerModule:SyncData()
    DisplayModule:Update()

    db.char.data.killAverage = PlayerModule:GetAverageKillXP()
    db.char.data.questAverage = PlayerModule:GetAverageQuestXP()
end

function EventsModule:OnPlayerEnteringBattleground()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    if PlayerModule.isActive then
        PlayerModule:BattlegroundStart(false)
    end
end

function EventsModule:OnLfgProposalSucceeded()
    self.hasLfgProposalSucceeded = true
end

function EventsModule:PlayerLeavingInstance(force)
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if force == true or (PlayerModule:IsDungeonInProgress() and (not UnitIsDeadOrGhost("player"))) then
        local zoneName = GetRealZoneText()
        local success = PlayerModule:DungeonEnd(zoneName)

        if success and PlayerModule.isActive then
            local lastTotalXP = db.char.data.dungeonList[1].totalXP
            local dungeonsRemaining = PlayerModule:GetKillsRequired(lastTotalXP)

            if dungeonsRemaining > 0 then
                DisplayModule:PrintDungeon(dungeonsRemaining)
                DisplayModule:Update()
            end
        end
    end
end

function EventsModule:PlayerLeavingDelve(force)
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if force == true or (PlayerModule:IsDelveInProgress() and (not UnitIsDeadOrGhost("player"))) then
        local zoneName = GetRealZoneText()
        local success = PlayerModule:DelveEnd(zoneName)

        if success and PlayerModule.isActive then
            local lastTotalXP = db.char.data.delveList[1].totalXP
            local delvesRemaining = PlayerModule:GetKillsRequired(lastTotalXP)

            if delvesRemaining > 0 then
                DisplayModule:PrintDelve(delvesRemaining)
                DisplayModule:Update()
            end
        end
    end
end

function EventsModule:OnPlayerEnteringWorld()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if self.hasLfgProposalSucceeded then
        local inInstance, itype = IsInInstance()
        if PlayerModule:IsDungeonInProgress() and inInstance and itype == "party" then
            self:PlayerLeavingInstance()
            PlayerModule:DungeonStart()
        end
        self.hasLfgProposalSucceeded = false
    end

    if GetRealZoneText() ~= "" then
        if PlayerModule:IsBattlegroundInProgress() then
            if Helpers:IsBattleground() then
                local latestBG = db.char.data.bgList[1] or nil
                if latestBG ~= nil and latestBG.name == nil then
                    db.char.data.bgList[1].name = Helpers:GetCurrentBattlegroundName() or GetRealZoneText()
                end
            else
                if PlayerModule.isActive then
                    local bgsRequired = PlayerModule:GetQuestsRequired(db.char.data.bgList[1].totalXP)
                    PlayerModule:BattlegroundEnd()
                    local DisplayModule = XToLevel:GetModule("DisplayModule")
                    DisplayModule:Update()
                    if bgsRequired > 0 then
                        DisplayModule:PrintBattleground(bgsRequired)
                    end
                end
            end
        else
            local inInstance, itype = IsInInstance()
            if not PlayerModule:IsDungeonInProgress() and inInstance and itype == "party" then
                PlayerModule:DungeonStart()
            elseif not inInstance and PlayerModule:IsDungeonInProgress() then
                self:PlayerLeavingInstance()
            end
        end

        -- Delve detection (Retail TWW+ only)
        if C_DelvesUI and C_DelvesUI.HasActiveDelve then
            if C_DelvesUI.HasActiveDelve() then
                if not PlayerModule:IsDelveInProgress() then
                    PlayerModule:DelveStart()
                end
            else
                if PlayerModule:IsDelveInProgress() then
                    self:PlayerLeavingDelve()
                end
            end
        end
    end
end

function EventsModule:OnPlayerUnghost()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    if self.playerHasXpLossRequest and not self.playerHasResurrectRequest then
        if PlayerModule:IsDungeonInProgress() then
            self:PlayerLeavingInstance(true)
        end
        self.playerHasXpLossRequest = false
    end
end

function EventsModule:OnConfirmXpLoss()
    self.playerHasXpLossRequest = true
end

function EventsModule:OnResurrectRequest()
    self.playerHasResurrectRequest = true
end

function EventsModule:OnPlayerAlive()
    self.playerHasXpLossRequest = false
    self.playerHasResurrectRequest = false
end

function EventsModule:OnAreaChanged()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    if PlayerModule:IsBattlegroundInProgress() and PlayerModule.isActive then
        local oldZone = db.char.data.bgList[1].name
        local newZone = GetRealZoneText()
        if oldZone == false then
            local bgName = Helpers:GetCurrentBattlegroundName()
            if bgName == nil then
                bgName = GetRealZoneText()
            end
            db.char.data.bgList[1].name = bgName
        else
            if oldZone ~= newZone and not Helpers:IsBattleground() then
                local bgsRequired = PlayerModule:GetQuestsRequired(db.char.data.bgList[1].totalXP)
                PlayerModule:BattlegroundEnd()
                DisplayModule:Update()
                if bgsRequired > 0 then
                    DisplayModule:PrintBattleground(bgsRequired)
                end
            end
        end
    end

    -- Delve zone change detection
    if C_DelvesUI and C_DelvesUI.HasActiveDelve then
        if C_DelvesUI.HasActiveDelve() then
            if not PlayerModule:IsDelveInProgress() then
                PlayerModule:DelveStart()
            end
            PlayerModule:UpdateDelveName()
        else
            if PlayerModule:IsDelveInProgress() then
                self:PlayerLeavingDelve()
            end
        end
    end
end

function EventsModule:OnTimePlayedMsg(event, total, level)
    if total < level then
        local tmp = level
        level = total
        total = tmp
    end
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    PlayerModule:UpdateTimePlayed(total, level)
end

function EventsModule:OnPetBattleOver()
    self.petBattleOver = GetTime()
end

function EventsModule:OnArchaeologyFindComplete(event, numFindsCompleted)
    self.digsiteProgress = tonumber(numFindsCompleted)
    self.surveyFoundComplete = time()
end

function EventsModule:OnDigsiteComplete()
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")

    self.digsiteProgress = 0
    local digSitesRequired = PlayerModule:GetDigsitesRequired(true)
    if digSitesRequired > 0 then
        DisplayModule:PrintDigsites(digSitesRequired)
    end
end

function EventsModule:OnSlashCommand(arg1)
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local DisplayModule = XToLevel:GetModule("DisplayModule")

    if arg1 == "clear kills" then
        PlayerModule:ClearKillList()
        PlayerModule.killAverage = nil
        print("XToLevel: Player kill records cleared.")
        DisplayModule:Update()
    elseif arg1 == "clear quests" then
        PlayerModule:ClearQuestList()
        PlayerModule.questAverage = nil
        print("XToLevel: Player quest records cleared.")
        DisplayModule:Update()
    elseif arg1 == "clear battles" then
        PlayerModule:ClearPetBattles()
        PlayerModule.petBattleAverage = nil
        print("XToLevel: Player pet battle records cleared.")
        DisplayModule:Update()
    elseif arg1 == "clear bg" then
        PlayerModule:ClearBattlegroundList()
        PlayerModule.bgAverage = nil
        PlayerModule.bgObjAverage = nil
        print("XToLevel: Player battleground records cleared.")
        DisplayModule:Update()
    elseif arg1 == "clear dungeons" then
        PlayerModule:ClearDungeonList()
        print("XToLevel: Player dungeon records cleared.")
        DisplayModule:Update()
    elseif arg1 == "clear delves" then
        PlayerModule:ClearDelveList()
        print("XToLevel: Player delve records cleared.")
        DisplayModule:Update()
    else
        local ConfigModule = XToLevel:GetModule("ConfigModule")
        ConfigModule:Open("Messages")
    end
end
