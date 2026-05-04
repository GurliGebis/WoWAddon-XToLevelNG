---
-- A collection of globally available helper functions used throughout the addon.
-- Attached to the _XToLevel global table, loaded via Common/common.xml.
---

local Helpers = {}
_XToLevel.Helpers = Helpers

---
-- Debug logging utility. Must be set up after Messages module loads.
console = {}
function console:log(message)
    local XToLevel = LibStub("AceAddon-3.0"):GetAddon("XToLevel")
    local DisplayModule = XToLevel:GetModule("DisplayModule")
    if DisplayModule and DisplayModule.Debug then
        DisplayModule:Debug(message)
    end
end

function Helpers:IsClassic()
    local interfaceNumber = select(4, GetBuildInfo())
    return interfaceNumber < 80000
end

function Helpers:IsBattleground()
    if Helpers:IsClassic() then
        return Helpers:GetCurrentBattlegroundName() ~= nil
    else
        return C_PvP.IsBattleground()
    end
end

function Helpers:GetCurrentBattlegroundName()
    local bgName = nil
    for index = 1, GetMaxBattlefieldID() do
        local status, name = GetBattlefieldStatus(index)
        if status == "active" then
            bgName = name
        end
    end
    return bgName
end

function Helpers:strcount(needle, heystack)
    local index = 1
    local count = 0
    local startPos, endPos = strfind(heystack, needle)
    while endPos ~= nil and count < 10000 do
        count = count + 1
        index = index + endPos
        startPos, endPos = strfind(strsub(heystack, index), needle)
    end
    return count
end

function Helpers:ConvertGlobalToRegexp(input)
    local reg = string.gsub(input, "(%%d)", "(%%d+)")
    reg = string.gsub(reg, "(%%s)", "(.+)")
    return reg
end

function Helpers:GetFactionInfoByName(searchName)
    local factionIndex = 1
    while factionIndex <= GetNumFactions() do
        local name, description, standingId, bottomValue, topValue, earnedValue, atWarWith,
              canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild = GetFactionInfo(factionIndex)
        if isHeader == nil and name == searchName then
            local repAmountPerLevel = nil
            if bottomValue < 0 then
                repAmountPerLevel = math.abs(tonumber(bottomValue)) + tonumber(topValue)
            else
                repAmountPerLevel = tonumber(topValue) - tonumber(bottomValue)
            end
            return description, bottomValue, repAmountPerLevel, earnedValue, atWarWith, isWatched
        else
            ExpandFactionHeader(factionIndex)
        end
        factionIndex = factionIndex + 1
    end
end

function Helpers:GetRepLevelName(currentRep)
    for index, value in ipairs(REP_LEVELS) do
        if value[2] <= currentRep and (value[2] + value[3]) > currentRep then
            local currentName = value[1]
            local upName = nil
            local downName = nil
            if index > 1 then
                downName = REP_LEVELS[index - 1][1]
            end
            if index < #REP_LEVELS then
                upName = REP_LEVELS[index + 1][1]
            end
            return currentName, upName, downName
        end
    end
end

function Helpers:GetRepGainsToLevel(gain, lvlStart, lvlAmount, currentRep)
    return math.ceil(((lvlStart + lvlAmount) - currentRep) / gain)
end

function Helpers:GetRepGainsToTarget(gain, currentRep, targetName)
    local targetLower = nil
    for index, value in ipairs(REP_LEVELS) do
        if targetName == value[1] then
            targetLower = value[2]
        end
    end
    if not targetLower then
        return nil
    elseif gain > 0 and targetLower <= currentRep then
        return nil
    elseif gain < 0 and targetLower >= currentRep then
        return nil
    else
        return math.ceil((targetLower - currentRep) / gain)
    end
end

function Helpers:ZoneID()
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        local info = C_Map.GetMapInfo(mapID)
        if info then
            while info['mapType'] and info['mapType'] > 3 do
                info = C_Map.GetMapInfo(info['parentMapID'])
            end
            return info['mapID']
        end
    end
    return 1
end

function Helpers:ConvertClassification(classification)
    local classifications = _XToLevel.Constants.UNIT_CLASSIFICATIONS
    if type(classification) == "number" and classification > 0 and classification <= #classifications then
        return classifications[classification]
    elseif type(classification) == "string" then
        for i, v in ipairs(classifications) do
            if v == classification then
                return i
            end
        end
    end
    return nil
end

function Helpers:IsPlayerRafEligable()
    local numPartyMembers = GetNumSubgroupMembers()
    if numPartyMembers > 0 then
        local memberID = 1
        while memberID <= numPartyMembers do
            local member = "party" .. memberID
            if UnitInParty(member) then
                if UnitIsVisible(member) and IsReferAFriendLinked(member) then
                    return true
                end
            end
            memberID = memberID + 1
        end
    end
    return false
end

function Helpers:IsRafApplied()
    local XToLevel = LibStub("AceAddon-3.0"):GetAddon("XToLevel")
    local DBModule = XToLevel:GetModule("DBModule")
    return DBModule:GetProfile().general.rafEnabled and self:IsPlayerRafEligable()
end

function Helpers:IsInBattleground()
    local currentZone = GetRealZoneText()
    for key, val in ipairs(_XToLevel.Constants.BG_NAMES) do
        if val == currentZone then
            return true
        end
    end
    return false
end

function Helpers:ShowBattlegroundData()
    local XToLevel = LibStub("AceAddon-3.0"):GetAddon("XToLevel")
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()
    return ((db.profile.ldb.tooltip.showBGInfo and PlayerModule.level >= 10) and (PlayerModule.level < PlayerModule.maxLevel or (#db.char.data.bgList) > 0))
end

function Helpers:ShowDungeonData()
    local XToLevel = LibStub("AceAddon-3.0"):GetAddon("XToLevel")
    local DBModule = XToLevel:GetModule("DBModule")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    local db = DBModule:GetDB()
    return ((db.profile.ldb.tooltip.showDungeonInfo) and (PlayerModule.level < PlayerModule.maxLevel or (#db.char.data.dungeonList) > 0))
end

function Helpers:MobXP(mobName, mobLevel)
    if type(mobName) ~= "string" then
        mobName = nil
    end

    local XToLevel = LibStub("AceAddon-3.0"):GetAddon("XToLevel")
    local DBModule = XToLevel:GetModule("DBModule")
    local db = DBModule:GetDB()

    local charLevel = UnitLevel("player")
    if type(mobLevel) ~= "number" then mobLevel = charLevel end

    if mobName ~= nil then
        for _, mobData in pairs(db.char.data.npcXP) do
            if mobData.name == mobName and mobData.level == mobLevel then
                return mobData.xp, "exact"
            end
        end
    end

    if mobLevel >= charLevel - 5 then
        local baseXP = (charLevel * 5) + 15

        local levelDelta = mobLevel - charLevel
        if levelDelta ~= 0 then
            local modifier = 0.05
            if not self:IsClassic() then
                for _level, _deltas in ipairs(_XToLevel.RETAIL_XP_MATRIX) do
                    for _d, _xp in pairs(_deltas) do
                        if _level == charLevel and tonumber(_d) == levelDelta then
                            return floor(_xp + 0.5), "exact"
                        end
                    end
                end
                if levelDelta < 0 then
                    for _, loop in ipairs(_XToLevel.XP_MULTIPLIERS) do
                        if loop.level <= charLevel then
                            modifier = loop.modifier
                        else
                            break
                        end
                    end
                end
            else
                if levelDelta < 0 then
                    for _, loop in ipairs(_XToLevel.XP_CLASSIC_ZERO_DIFFERENCE) do
                        if loop.level <= charLevel then
                            modifier = 1 / loop.divider
                        else
                            break
                        end
                    end
                end
            end
            local multiplier = (modifier * levelDelta) + 1
            return floor((baseXP * multiplier) + 0.5), "estimate"
        else
            return floor(baseXP + 0.5), "exact"
        end
    else
        return 0, "exact"
    end
end

function Helpers:GatheringXP(playerLevel)
    if type(playerLevel) ~= "number" then
        playerLevel = UnitLevel("player")
    end
    return _XToLevel.GATHERING_XP[playerLevel]
end

local heirloom_slot_values = { [3] = 0.1, [5] = 0.1, [11] = 0.05, [12] = 0.05 }
function Helpers:GetHeirloomXpBonus()
    local sID, sQuality, sBlackhole
    local output = 0
    for slot, value in pairs(heirloom_slot_values) do
        sID = GetInventoryItemID("player", slot)
        if sID then
            sBlackhole, sBlackhole, sQuality = C_Item.GetItemInfo(sID)
            if sQuality == 7 then
                output = output + value
            end
        end
    end
    return output
end

function Helpers:GetChatXPRegexp(isQuest)
    local inInstance, itype = IsInInstance()
    local inGroup = GetNumSubgroupMembers() > 0
    local apiRegexp = nil
    local isRested = GetXPExhaustion()
    if not isQuest then
        if inInstance and isRested then
            if itype == "party" and inGroup then
                apiRegexp = COMBATLOG_XPGAIN_EXHAUSTION1_GROUP
            elseif itype == "raid" and inGroup then
                apiRegexp = COMBATLOG_XPGAIN_EXHAUSTION1_RAID
            else
                apiRegexp = COMBATLOG_XPGAIN_EXHAUSTION1
            end
        elseif inInstance and not isRested then
            if itype == "party" and inGroup then
                apiRegexp = COMBATLOG_XPGAIN_FIRSTPERSON_GROUP
            elseif itype == "raid" and inGroup then
                apiRegexp = COMBATLOG_XPGAIN_FIRSTPERSON_RAID
            else
                apiRegexp = COMBATLOG_XPGAIN_FIRSTPERSON
            end
        else
            if isRested then
                apiRegexp = COMBATLOG_XPGAIN_EXHAUSTION1
            else
                apiRegexp = COMBATLOG_XPGAIN_FIRSTPERSON
            end
        end
    else
        apiRegexp = COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED
    end
    apiRegexp = string.gsub(apiRegexp, "%(", "%%(")
    apiRegexp = string.gsub(apiRegexp, "%)", "%%)")
    apiRegexp = string.gsub(apiRegexp, "%+", "%%+")
    apiRegexp = string.gsub(apiRegexp, "%-", "%%-")
    apiRegexp = string.gsub(apiRegexp, "%%%d?%$?s", "(.+)")
    apiRegexp = string.gsub(apiRegexp, "%%%d?%$?d", "(%%d+)")
    return apiRegexp
end

function Helpers:ParseChatXPMessage(message, isQuest)
    local pattern = Helpers:GetChatXPRegexp(isQuest)
    local mob, xp = strmatch(message, pattern)

    if tonumber(mob) then
        xp = tonumber(mob)
        mob = nil
    end

    if not tonumber(xp) then
        xp = strmatch(message, "(%d+)")
    end

    return xp, mob
end

function Helpers:round(input, precision, roundDown)
    if input == nil then
        return nil
    end
    if precision == nil then
        precision = 0
    end

    precision = 10 ^ (precision or 2)
    local altered = input * precision
    if roundDown then
        return math.floor(altered) / precision
    else
        if altered - math.floor(altered) >= 0.5 then
            return math.ceil(altered) / precision
        else
            return math.floor(altered) / precision
        end
    end
end

function Helpers:NumberFormat(input)
    local strVersion = tostring(input)
    local strLength = strlen(strVersion)

    local numVersion = ""
    local fraction = nil

    local i = 0
    while i < strLength do
        i = i + 1
        local current = strsub(strVersion, i, i)
        if current == "." then
            fraction = strsub(strVersion, i + 1)
            break
        else
            numVersion = numVersion .. current
        end
    end

    local output = ""
    strLength = strlen(numVersion)
    i = 0
    while i < strLength do
        if i > 0 and mod(i, 3) == 0 then
            output = "," .. output
        end
        output = strsub(numVersion, (strLength - i), (strLength - i)) .. output
        i = i + 1
    end
    if fraction then
        return output .. "." .. fraction
    else
        return output
    end
end

local numberUnits = {"", "K", "M", "B"}
function Helpers:ShrinkNumber(input)
    input = tonumber(input)
    if input < 100000 then
        return Helpers:NumberFormat(input)
    else
        local index = 1
        local output = input
        while output > 1000 and index < #numberUnits do
            output = output / 1000
            index = index + 1
        end
        local precision = 2
        if output < 10 then
            precision = 2
        elseif output < 100 then
            precision = 1
        else
            precision = 0
        end
        return Helpers:NumberFormat(tostring(Helpers:round(output, precision, true))) .. numberUnits[index]
    end
end

function Helpers:DecToHex(IN, minChars)
    local B, K, OUT, I, D = 16, "0123456789ABCDEF", "", 0
    while IN > 0 do
        I = I + 1
        IN, D = math.floor(IN / B), mod(IN, B) + 1
        OUT = strsub(K, D, D) .. OUT
        if I > 1000 then
            break
        end
    end
    if minChars and tonumber(minChars) > 0 then
        I = 0
        while strlen(OUT) < tonumber(minChars) do
            OUT = "0" .. OUT
            if I > 1000 then
                break
            end
        end
    end
    return OUT
end

Helpers.progressColor = { pro = 0, hex = 0, rgb = { r = 0, g = 0, b = 0 } }
function Helpers:GetProgressColor(pro)
    if pro <= 0 then pro = 1 end
    if pro > 100 then pro = 100 end
    if self.progressColor.pro ~= pro then
        local lh = pro <= 50 and true or false
        self.progressColor.pro = pro
        self.progressColor.rgb.r = math.floor((lh and 255) or (255 - (((pro - 50) / 50) * 255)))
        self.progressColor.rgb.g = math.floor((lh and ((pro / 50) * 255)) or 255)
        self.progressColor.rgb.b = 0
        self.progressColor.hex = Helpers:DecToHex(self.progressColor.rgb.r, 2) .. Helpers:DecToHex(self.progressColor.rgb.g, 2) .. Helpers:DecToHex(self.progressColor.rgb.b, 2)
    end
    return self.progressColor.hex, self.progressColor.rgb
end

function Helpers:GetProgressColor_Soft(progress)
    local hex
    local rgb = { r = 0, g = 0, b = 0 }
    local pro = tonumber(progress)
    local proa = math.abs(progress - 50)
    rgb.r = math.floor((pro <= 66 and 255) or (255 - (153 * ((pro - 66) / 34))))
    rgb.g = math.floor((pro >= 50 and 255) or (255 - (153 * ((50 - pro) / 50))))
    rgb.b = math.floor((proa >= 16 and 102) or (102 * (proa / 16)))
    hex = Helpers:DecToHex(rgb.r, 2) .. Helpers:DecToHex(rgb.g, 2) .. Helpers:DecToHex(rgb.b, 2)
    return hex, rgb
end

function Helpers:GetBGObjectiveMinXP()
    local XToLevel = LibStub("AceAddon-3.0"):GetAddon("XToLevel")
    local PlayerModule = XToLevel:GetModule("PlayerModule")
    if PlayerModule.level > 10 then
        local bgMin = {
            ["Alterac Valley"] = 750,
            ["Isle of Conquest"] = 250,
            ["Strand of the Anchients"] = 500,
            ["Eye of the Storm"] = 500,
            ["Arathi Basin"] = 250,
            ["Warsong Gulch"] = 250,
        }
        local zone = GetRealZoneText()
        local zoneMin = 500

        for name, value in pairs(bgMin) do
            if name == zone then
                zoneMin = value
            end
        end

        local playerMultiplier = (PlayerModule.level - 10) / (PlayerModule.maxLevel - 10)

        return (Helpers:round(zoneMin * playerMultiplier, 0))
    else
        return 0
    end
end

function Helpers:FindAnchor(frame)
    local xcenter, ycenter = frame:GetCenter()
    if not xcenter or not ycenter then
        return "TOPLEFT", "BOTTOMLEFT"
    end
    local hor = (xcenter > UIParent:GetWidth() * 2 / 3) and "RIGHT" or (xcenter < UIParent:GetWidth() / 3) and "LEFT" or ""
    local ver = (ycenter > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
    return ver .. hor, frame, (ver == "BOTTOM" and "TOP" or "BOTTOM") .. hor
end

function Helpers:ReverseAnchor(anchor)
    if string.find(anchor, "TOP") ~= nil then
        anchor = string.gsub(anchor, "TOP", "BOTTOM")
    else
        anchor = string.gsub(anchor, "BOTTOM", "TOP")
    end
    if string.find(anchor, "LEFT") ~= nil then
        anchor = string.gsub(anchor, "LEFT", "RIGHT")
    else
        anchor = string.gsub(anchor, "RIGHT", "LEFT")
    end
    return anchor
end

function Helpers:Split(str, delim, maxNb)
    if maxNb == nil or maxNb < 1 then
        maxNb = 0
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    if #result == 0 then
        result[1] = str
    end
    return result
end

function Helpers:TimeFormat(timestamp)
    if type(timestamp) == "number" and timestamp > 0 then
        local day = floor(timestamp / 86400)
        local hour = floor((timestamp - (day * 86400)) / 3600)
        local minute = floor((timestamp - (day * 86400) - (hour * 3600)) / 60)
        local second = floor(mod(timestamp, 60))

        if day < 0 then
            return "NaN"
        else
            local output = ""
            if day > 0 then
                output = day .. "d "
            end
            if hour > 0 or output ~= "" then
                output = output .. hour .. "h "
            end
            if minute > 0 or output ~= "" then
                output = output .. minute .. "m "
            end
            if second > 0 or output ~= "" then
                output = output .. second .. "s"
            end
            return output
        end
    else
        return "NaN"
    end
end
