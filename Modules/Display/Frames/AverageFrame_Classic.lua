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

local addonName, addonTable = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local Helpers = _XToLevel.Helpers

local backdrop2 = {
    bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 8,
    tileSize = 8,
    tile = true,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

if XToLevel.AverageFrameAPI == nil then
    XToLevel.AverageFrameAPI = { }
end

--- 
-- Control methods and members for the XToLevel_AvergeFrame_Classic window.
-- @class table
-- 
XToLevel.AverageFrameAPI["Classic"] = 
{
    isMoving = false,
    window = nil,
    lines = {},
    textMargin = 5,
    lineSpacing = 2,
    lastTooltip = nil,
    playerProgressColor = "0088ff",
    labelColor = "ffffff",

    Initialize = function(self)
        if XToLevel_AverageFrame_Classic ~= nil then
            self.window = XToLevel_AverageFrame_Classic
            self:CreateLines()
            self:Update()
        else
            console:log("The classic average window is not loaded!")
        end
    end,
    
    Hide = function(self)
        XToLevel_AverageFrame_Classic:Hide()
    end,
    
    GetPoint = function(self)
        return self.window:GetPoint()
    end,
    
    SetAnchor = function(self, point, relativeTo, relativePoint, xOfs, yOfs)
        self.window:ClearAllPoints()
        self.window:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
    end,
    
    AlignTo = function(self, anchorFrame)
        local point, relativeTo, relativePoint, xOfs, yOfs = anchorFrame:GetPoint()
        self.window:ClearAllPoints()
        self.window:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
        self:Update()
    end,
    
    ShowTooltip = function(self, mode)
        local DBModule = XToLevel:GetModule("DBModule")
        local DisplayModule = XToLevel:GetModule("DisplayModule")
        local db = DBModule:GetDB()

        if not self.isMoving and db.profile.averageDisplay.tooltip then
	        local footer = (db.profile.general.allowSettingsClick and L['Right Click To Configure']) or nil
	        local childPoint, parentFrame, parentPoint = Helpers:FindAnchor(self.window)
	        
            if parentPoint ~= "TOP" and parentPoint ~= "BOTTOM" then
				parentPoint = Helpers:ReverseAnchor(parentPoint)
	        end
	        if db.profile.averageDisplay.combineTooltip then
	            DisplayModule:TooltipShow(self.window, childPoint, parentFrame, parentPoint, footer)
            else
                DisplayModule:TooltipShow(self.window, childPoint, parentFrame, parentPoint, footer, mode)
                self.lastTooltip = mode
            end
	    end
    end,
    
    HideTooltip = function(self)
        local DisplayModule = XToLevel:GetModule("DisplayModule")
        DisplayModule:TooltipHide()
        if not self.isMoving then
            self.lastTooltip = nil
        end
    end,
    
    StartDrag = function(self)
        local DBModule = XToLevel:GetModule("DBModule")
        local db = DBModule:GetDB()

        if not self.isMoving and db.profile.general.allowDrag then
            self.window:StartMoving()
            self:HideTooltip()
            self.isMoving = true
        end
    end,
    
    StopDrag = function(self)
        if self.isMoving then
            self.window:StopMovingOrSizing()
            self:ShowTooltip(self.lastTooltip)
            self.isMoving = false
        end
    end,
    
    Update = function(self)
        local DBModule = XToLevel:GetModule("DBModule")
        local db = DBModule:GetDB()

        if db.profile.averageDisplay.mode == 2 then
            XToLevel_AverageFrame_Classic:Show()
            XToLevel_AverageFrame_Classic:SetScale(db.profile.averageDisplay.scale)
            self:UpdateLineVisibility()
            self:UpdateLinePositions()
            self:UpdateFrameSize()
        else
            XToLevel_AverageFrame_Classic:Hide()
        end
    end,
    
    UpdateLineVisibility = function(self)
        local DBModule = XToLevel:GetModule("DBModule")
        local PlayerModule = XToLevel:GetModule("PlayerModule")
        local db = DBModule:GetDB()

        if db.profile.averageDisplay.header then
            self.lines.header:Show()
        end
        
        if not PlayerModule.isActive then
            self.lines.playerKills:Hide()
            self.lines.playerQuests:Hide()
        else
            self.lines.playerKills:Show()
            self.lines.playerQuests:Show()
        end
        if not PlayerModule.isActive or (PlayerModule:GetAverageDungeonsRemaining() == nil or not Helpers:ShowDungeonData()) then
            self.lines.playerDungeons:Hide()
        else
            self.lines.playerDungeons:Show()
        end
        if not PlayerModule.isActive or not PlayerModule:HasPetBattleInfo() then
            self.lines.playerPetBattles:Hide()
        else
            self.lines.playerPetBattles:Show()
        end
        if not PlayerModule.isActive or (PlayerModule:GetAverageBGsRemaining() == nil or not Helpers:ShowBattlegroundData()) then
            self.lines.playerBGs:Hide()
        else
            self.lines.playerBGs:Show()
        end
        if not PlayerModule.isActive or (PlayerModule:GetAverageBGObjectivesRemaining() == nil or not Helpers:ShowBattlegroundData()) then
            self.lines.playerBGOs:Hide()
        else
            self.lines.playerBGOs:Show()
        end
        
        if PlayerModule.isActive and db.profile.averageDisplay.progress then
            self.lines.playerProgress:Show()
        else
            self.lines.playerProgress:Hide()
        end

        if PlayerModule.isActive and db.profile.averageDisplay.playerTimer then
            self.lines.playerTimer:Show()
        else
            self.lines.playerTimer:Hide()
        end

        if PlayerModule.isActive and db.profile.averageDisplay.playerGathering and not Helpers:IsClassic() then
            self.lines.playerGathering:Show()
        else
            self.lines.playerGathering:Hide()
        end
        
        if PlayerModule.isActive and db.profile.averageDisplay.playerDigs and PlayerModule:HasDigInfo() then
            self.lines.playerDigs:Show()
        else
            self.lines.playerDigs:Hide()
        end
    end,
    
    UpdateLinePositions = function(self)
        local DBModule = XToLevel:GetModule("DBModule")
        local db = DBModule:GetDB()

        local iLines = {}
        for eName, eElem in pairs(self.lines) do
            iLines[eElem.tabIndex] = { name=eName, elem=eElem }
        end
        
        local nextAnchor = self.window
        local nextMarginV = self.textMargin
        local nextMarginH = self.textMargin
        local nextPoint = "TOPLEFT"
        local currentIndent = -nextMarginH
        for index, value in ipairs(iLines) do
            local name = value.name
            local elem = value.elem
            
            elem:ClearAllPoints()
            if db.profile.averageDisplay[name] and elem:IsShown() then
                if nextAnchor.group == elem.group then
                    nextMarginH = 0
                else
                    currentIndent = currentIndent + nextMarginH
                end
                elem:SetPoint("TOPLEFT", nextAnchor, nextPoint, nextMarginH, -nextMarginV)
                elem.lineIndent = currentIndent
                
                nextAnchor = elem
                nextMarginV = self.lineSpacing
                nextPoint = "BOTTOMLEFT"
            else
                elem:Hide()
            end
        end
    end,
    
    UpdateFrameSize = function(self)
        local maxWidth = 0
        local totalHeight = self.textMargin * 2
        for name, value in pairs(self.lines) do
            if value:IsVisible() then
                local currentWidth = value.text:GetWidth() + (value.lineIndent or 0)
                if currentWidth > maxWidth then
                    maxWidth = currentWidth
                end
                totalHeight = totalHeight + value:GetHeight() + self.lineSpacing
            end
        end
        
        for name, value in pairs(self.lines) do
            value:SetWidth(maxWidth)
        end
        
        local totalWidth = maxWidth + (self.textMargin * 2)
        self.window:SetWidth(totalWidth)
        self.window:SetHeight(totalHeight)
    end,

    CreateLine = function(self, lineName, group, tabIndex, toolTip, initalValue, fontStringTemplate)
        local DBModule = XToLevel:GetModule("DBModule")
        local db = DBModule:GetDB()

        self.lines[lineName] = CreateFrame("Frame", "XToLevel_AverageFrame_Classic_" .. lineName, self.window)
        self.lines[lineName]:EnableMouse(true)
        self.lines[lineName]:RegisterForDrag("LeftButton")
        self.lines[lineName].group = group
        self.lines[lineName].tabIndex = tabIndex
        self.lines[lineName].backdrop = backdrop
        self.lines[lineName].text = self.lines[lineName]:CreateFontString(nil, 'OVERLAY', fontStringTemplate)
        self.lines[lineName].text:SetText(initalValue)
        self.lines[lineName].actualWidth = self.lines[lineName].text:GetWidth()
        self.lines[lineName]:SetHeight(self.lines[lineName].text:GetHeight())
        self.lines[lineName]:SetWidth(self.lines[lineName].text:GetWidth())
        if toolTip ~= nil then
            self.lines[lineName]:SetScript("OnEnter", function() self:ShowTooltip(toolTip) end)
            self.lines[lineName]:SetScript("OnLeave", function() self:HideTooltip() end)
        end
        self.lines[lineName]:SetScript("OnDragStart", function() self:StartDrag() end)
        self.lines[lineName]:SetScript("OnDragStop", function() self:StopDrag() end)
        self.lines[lineName]:SetScript("OnMouseUp", function(_, button)
            if button == "RightButton" and db.profile.general.allowSettingsClick then
                local ConfigModule = XToLevel:GetModule("ConfigModule")
                ConfigModule:Open("Window")
            end
        end)
    end,
    
    CreateLines = function(self)
        self:CreateLine('header', 'header', 1, nil, 'XToLevel', 'XToLevel_h1')
        self:CreateLine('playerKills', 'player', 2, 'kills', L["Kills"], 'XToLevel_span')
        self:CreateLine('playerQuests', 'player', 3, 'quests', L["Quests"], 'XToLevel_span')
        self:CreateLine('playerDungeons', 'player', 4, 'dungeons', L["Dungeons"], 'XToLevel_span')
        self:CreateLine('playerBGs', 'player', 5, 'bg', L["Battles"], 'XToLevel_span')
        self:CreateLine('playerBGOs', 'player', 6, 'bg', L["Objectives"], 'XToLevel_span')
        self:CreateLine('playerPetBattles', 'player', 7, 'petBattles', L["Pet Battles"], 'XToLevel_span')
        self:CreateLine('playerGathering', 'player', 8, 'gathering', L["Gathering"], 'XToLevel_span')
        self:CreateLine('playerDigs', 'player', 9, 'archaeology', L["Digs"], 'XToLevel_span')
        self:CreateLine('playerProgress', 'player', 10, 'experience', L["XP Percent"], 'XToLevel_span')
        self:CreateLine('playerTimer', 'player', 11, 'timer', L["Player Timer"], "XToLevel_span")
    end,
    
    WriteToLine = function(self, lineName, labelName, value, color)
        local DBModule = XToLevel:GetModule("DBModule")
        local db = DBModule:GetDB()

        if self.lines[lineName] ~= nil and type(self.lines[lineName].text) == "table" then
            if color ~= nil then
                self.lines[lineName].text:SetText("|cFF".. self.labelColor .. tostring((db.profile.averageDisplay.verbose and L[labelName]) or L[labelName .. " Short"]) .. ':|r |cFF'.. color .. tostring(value) .."|r")
            else
                self.lines[lineName].text:SetText(((db.profile.averageDisplay.verbose and L[labelName]) or L[labelName .. " Short"]) .. ': ' .. tostring(value))
            end
            self.lines[lineName]:SetHeight(self.lines[lineName].text:GetHeight())
            self.lines[lineName]:SetWidth(self.lines[lineName].text:GetWidth())
        else
            return false
        end
    end,
    
    OnEvent = function(self)
        return true
    end,
    
    GetTextColor = function(self, colorType)
        local DBModule = XToLevel:GetModule("DBModule")
        local PlayerModule = XToLevel:GetModule("PlayerModule")
        local db = DBModule:GetDB()

        if db.profile.averageDisplay.colorText then
            if colorType == "player" then
                return Helpers:GetProgressColor(PlayerModule:GetProgressAsPercentage())
            else
                console:log("Unable to determine the color to use. Type '" .. tostring(colorType) .."' is not valid")
                return nil
            end
        else
            return nil
        end
    end,

    SetKills = function(self, value)
        self:WriteToLine("playerKills", "Kills", value, self:GetTextColor("player"))
    end,
    
    SetQuests = function(self, value)
        self:WriteToLine("playerQuests", "Quests", value, self:GetTextColor("player"))
    end,
    
    SetPetBattles = function(self, value)
        self:WriteToLine("playerPetBattles", "Pet Battles", value, self:GetTextColor("player"))
    end,
    
    SetDungeons = function(self, value)
        self:WriteToLine("playerDungeons", "Dungeons", value, self:GetTextColor("player"))
    end,
    
    SetBattles = function(self, value)
        self:WriteToLine("playerBGs", "Battles", value, self:GetTextColor("player"))
    end,
    
    SetObjectives = function(self, value)
        self:WriteToLine("playerBGOs", "Objectives", value, self:GetTextColor("player"))
    end,

    SetProgress = function(self, percent)
        local DBModule = XToLevel:GetModule("DBModule")
        local PlayerModule = XToLevel:GetModule("PlayerModule")
        local db = DBModule:GetDB()

        if db.profile.averageDisplay.progressAsBars then
            local barsRemaining = PlayerModule:GetProgressAsBars()
            self:WriteToLine("playerProgress", "XP Bars", barsRemaining .. " " .. L["Bars"], self:GetTextColor("player")) 
        else 
            self:WriteToLine("playerProgress", "XP Percent", percent .. "%", self:GetTextColor("player")) 
        end
    end,
    
    SetTimer = function(self, shortValue, longValue)
        self:WriteToLine("playerTimer", "Timer", longValue, self:GetTextColor("player"))
    end,
    
    SetGathering = function(self, value)
        self:WriteToLine("playerGathering", "Gathering", value, self:GetTextColor("player"))
    end,
    
    SetDigs = function(self, value)
        self:WriteToLine("playerDigs", "Digs", value, self:GetTextColor("player"))
    end,
    
    SetGuildProgress = function(self, value)
        return true
    end,
}
