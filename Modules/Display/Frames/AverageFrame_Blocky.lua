local addonName, addonTable = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local Helpers = _XToLevel.Helpers

if XToLevel.AverageFrameAPI == nil then
    XToLevel.AverageFrameAPI = { }
end

--- 
-- Control methods and members for the XToLevel_AvergeFrame_Blocky window.
-- @class table
-- 
XToLevel.AverageFrameAPI["Blocky"] = 
{
    isMoving = false,
    lastTooltip = nil,
    playerBoxes = {},

    --- Called when the frame first loads
    Initialize = function(self)
        local DBModule = XToLevel:GetModule("DBModule")
        local db = DBModule:GetDB()

	    local iconName = (UnitFactionGroup("player") == "Alliance") and "battle_ally_icon.tga" or "battle_horde_icon.tga"
	    XToLevel_AverageFrame_Blocky_PlayerFrameCounterBattlesIcon:SetTexture("Interface\\AddOns\\XToLevel\\Textures\\" .. iconName)
        
        -- Fetch boxes
        self.playerBoxes = {
	        {   
	            name =  'XToLevel_AverageFrame_Blocky_PlayerFrameCounterKills',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterKills,
	            visible = db.profile.averageDisplay.playerKills
	        },
	        {   
	            name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterQuests',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterQuests,
	            visible = db.profile.averageDisplay.playerQuests
	        },
	        {   
	            name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterDungeons',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterDungeons,
	            visible = db.profile.averageDisplay.playerDungeons
	        },
	        {   name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterBattles',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterBattles,
	            visible = db.profile.averageDisplay.playerBGs
	        },
	        {   name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterObjectives',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterObjectives,
	            visible = db.profile.averageDisplay.playerBGOs
	        },
            {   name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterPetBattles',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterPetBattles,
	            visible = db.profile.averageDisplay.playerPetBattles
	        },
	        {   name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterGathering',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterGathering,
	            visible = db.profile.averageDisplay.playerGathering
	        },
            {   name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterDigs',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterDigs,
	            visible = db.profile.averageDisplay.playerDigs
	        },
	        {   
	            name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgress',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgress,
	            visible = db.profile.averageDisplay.playerProgress
	        },
	        {   
	            name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterTimer',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterTimer,
	            visible = db.profile.averageDisplay.playerTimer
	        },
	        {   
	            name = 'XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgress',
	            ref =   XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgress,
	            visible = db.profile.averageDisplay.guildProgress
	        }
	    }
        
        -- Stack frames
        self:Update()
    end,
    
    Hide = function(self)
        XToLevel_AverageFrame_Blocky_PlayerFrame:Hide()
    end,
    
    GetPoint = function(self)
        return XToLevel_AverageFrame_Blocky_PlayerFrame:GetPoint()
    end,
    
    SetAnchor = function(self, point, relativeTo, relativePoint, xOfs, yOfs)
        XToLevel_AverageFrame_Blocky_PlayerFrame:ClearAllPoints()
        XToLevel_AverageFrame_Blocky_PlayerFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
        self:Update()
    end,
    
    AlignTo = function(self, anchorFrame)
        local point, relativeTo, relativePoint, xOfs, yOfs = anchorFrame:GetPoint()
        XToLevel_AverageFrame_Blocky_PlayerFrame:ClearAllPoints()
        XToLevel_AverageFrame_Blocky_PlayerFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
        self:Update()
    end,
        
    ShowTooltip = function(self, mode)
        local DBModule = XToLevel:GetModule("DBModule")
        local DisplayModule = XToLevel:GetModule("DisplayModule")
        local db = DBModule:GetDB()

        if not self.isMoving and db.profile.averageDisplay.tooltip then
	        local footer = (db.profile.general.allowSettingsClick and L['Right Click To Configure']) or nil
	        local a1, f1, a2 = Helpers:FindAnchor(XToLevel_AverageFrame_Blocky_PlayerFrame)
	        if db.profile.averageDisplay.orientation == "v" then
	           if a2 == "TOPRIGHT" or a2 == "TOPLEFT" or a2 == "BOTTOMLEFT" or a2 == "BOTTOMRIGHT" then
	               a2 = Helpers:ReverseAnchor(a2)
               end
            end
            
            if db.profile.averageDisplay.combineTooltip then
                mode = nil
            end
            
            self.lastTooltip = mode
	        DisplayModule:TooltipShow(XToLevel_AverageFrame_Blocky_PlayerFrame, a1, f1, a2, footer, mode)
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
        local DisplayModule = XToLevel:GetModule("DisplayModule")
        local db = DBModule:GetDB()

        if not self.isMoving and db.profile.general.allowDrag then
            XToLevel_AverageFrame_Blocky_PlayerFrame:StartMoving()
            self.isMoving = true
            DisplayModule:TooltipHide()
        end
    end,
    
    StopDrag = function(self)
        if self.isMoving then
            XToLevel_AverageFrame_Blocky_PlayerFrame:StopMovingOrSizing()
            self.isMoving = false
            if self.lastTooltip ~= nil then
                self:ShowTooltip(self.lastTooltip)
            end
        end
    end,
    
    Update = function(self)
        local DBModule = XToLevel:GetModule("DBModule")
        local PlayerModule = XToLevel:GetModule("PlayerModule")
        local db = DBModule:GetDB()

        if db.profile.averageDisplay.mode == 1 then
            local level = PlayerModule.level
            local maxLevel = PlayerModule:GetMaxLevel()
	        if type(level) == "number" and type(maxLevel) == "number" and level < maxLevel then
	            XToLevel_AverageFrame_Blocky_PlayerFrame:Show()
                XToLevel_AverageFrame_Blocky_PlayerFrame:SetScale(db.profile.averageDisplay.scale)
		        self:StackPlayer()
	        else
                XToLevel_AverageFrame_Blocky_PlayerFrame:Hide()
	        end
        else
            XToLevel_AverageFrame_Blocky_PlayerFrame:Hide()
        end
    end,
    
    StackPlayer = function(self)
        local DBModule = XToLevel:GetModule("DBModule")
        local PlayerModule = XToLevel:GetModule("PlayerModule")
        local db = DBModule:GetDB()

        self.playerBoxes[1]["visible"] = db.profile.averageDisplay.playerKills
        self.playerBoxes[2]["visible"] = db.profile.averageDisplay.playerQuests
        self.playerBoxes[3]["visible"] = db.profile.averageDisplay.playerDungeons and PlayerModule.level >= 10
        self.playerBoxes[4]["visible"] = db.profile.averageDisplay.playerBGs and PlayerModule.level >= 15
        self.playerBoxes[5]["visible"] = db.profile.averageDisplay.playerBGOs and PlayerModule.level >= 15
        self.playerBoxes[6]["visible"] = db.profile.averageDisplay.playerPetBattles and PlayerModule:HasPetBattleInfo()
        self.playerBoxes[7]["visible"] = db.profile.averageDisplay.playerGathering and not Helpers:IsClassic()
        self.playerBoxes[8]["visible"] = db.profile.averageDisplay.playerDigs and PlayerModule:HasDigInfo()
        self.playerBoxes[9]["visible"] = db.profile.averageDisplay.playerProgress
		self.playerBoxes[10]["visible"] = db.profile.averageDisplay.playerTimer
        self.playerBoxes[11]["visible"] = db.profile.averageDisplay.guildProgress and type(PlayerModule.guildXP) == 'number'
    
        local orientation = db.profile.averageDisplay.orientation or 'v'
        self:StackBoxes(orientation, self.playerBoxes, XToLevel_AverageFrame_Blocky_PlayerFrame, 'XToLevel_AverageFrame_Blocky_PlayerFrame')
    end,
    
    StackBoxes = function(self, direction, boxes, container, parent)
        local xcurr = 1
        local ycurr = 1
        local xmax = xcurr
        local ymax = ycurr
        local padding = 5
        
        for index, values in ipairs(boxes) do
            if values.visible and values.ref ~= nil then
                values.ref:ClearAllPoints()
                values.ref:SetPoint('TOPLEFT', parent, 'TOPLEFT', xcurr, ycurr)
                values.ref:Show()
                
                if direction == 'h' then
                    xcurr = xcurr + values.ref:GetWidth() + padding
                    ymax = (ymax < values.ref:GetHeight() and values.ref:GetHeight()) or ymax
                else
                    ycurr = ycurr - (values.ref:GetHeight() + padding)
                    xmax = (xmax < values.ref:GetWidth() and values.ref:GetWidth()) or xmax
                end
            elseif values.ref ~= nil then
                values.ref:Hide()
            end
        end
        
        if direction == 'h' then
            container:SetWidth(xcurr)
            container:SetHeight(ymax)
        else
            container:SetWidth(xmax)
            container:SetHeight(-ycurr)
        end
    end,
    
    OnEvent = function(self)
        return true
    end,

    SetKills = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterKillsValueText:SetText(tonumber(value))
    end,
    
    SetQuests = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterQuestsValueText:SetText(tonumber(value))
    end,
    
    SetPetBattles = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterPetBattlesValueText:SetText(tonumber(value))
    end,
    
    SetDungeons = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterDungeonsValueText:SetText(tonumber(value))
    end,
    
    SetBattles = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterBattlesValueText:SetText(tonumber(value))
    end,
    
    SetObjectives = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterObjectivesValueText:SetText(tonumber(value))
    end,
    
    SetGathering = function(self, value)
        if value ~= nil then
			XToLevel_AverageFrame_Blocky_PlayerFrameCounterGatheringValueText:SetText(tonumber(value))
		else
			XToLevel_AverageFrame_Blocky_PlayerFrameCounterGatheringValueText:SetText("N/A")
		end
    end,
    
    SetDigs = function(self, value)
        XToLevel_AverageFrame_Blocky_PlayerFrameCounterDigsValueText:SetText(value)
    end,

    SetProgress = function(self, percent)
        local DBModule = XToLevel:GetModule("DBModule")
        local db = DBModule:GetDB()

        if percent ~= nil and (percent >= 0 and percent <= 100) then
            local progressFrame = XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgress
            local progressBar = XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgressBar
            local progressText = XToLevel_AverageFrame_Blocky_PlayerFrameCounterProgressValueText
            
            local totalWidth = progressFrame:GetWidth() - 5
            local barWidth = totalWidth * (percent / 100)
            local bars = ceil((100 - percent) / 5)
            
            if barWidth == 0 then
                barWidth = 1
            end
            
            local hex, rgb = Helpers:GetProgressColor(percent)
            rgb = { r= (rgb.r / 256), g= (rgb.g) / 256, b= (rgb.b / 256) }
            
            progressBar:SetWidth(barWidth)
            if db.profile.averageDisplay.progressAsBars then
                progressText:SetText(tostring(bars) .. " " .. L['Bars'])
            else
                progressText:SetText(tostring(floor(percent)) .. "%")
            end
            progressText:SetTextColor(rgb.r, rgb.g, rgb.b, 1.0)
        end
    end,
    
    SetGuildProgress = function(self, percent)
        local DBModule = XToLevel:GetModule("DBModule")
        local db = DBModule:GetDB()

        if percent ~= nil and (percent >= 0 and percent <= 100) then
            local progressFrame = XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgress
            local progressBar = XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgressBar
            local progressText = XToLevel_AverageFrame_Blocky_PlayerFrameCounterGuildProgressValueText
            
            local totalWidth = progressFrame:GetWidth() - 5
            local barWidth = totalWidth * (percent / 100)
            local bars = ceil((100 - percent) / 5)
            
            if barWidth == 0 then
                barWidth = 1
            end
            
            local hex, rgb = Helpers:GetProgressColor(percent)
            rgb = { r= (rgb.r / 256), g= (rgb.g) / 256, b= (rgb.b / 256) }
            
            progressBar:SetWidth(barWidth)
            if db.profile.averageDisplay.progressAsBars then
                progressText:SetText(tostring(bars) .. " " .. L['Bars'])
            else
                progressText:SetText(tostring(floor(percent)) .. "%")
            end
            progressText:SetTextColor(rgb.r, rgb.g, rgb.b, 1.0)
        end
    end,
	
	SetTimer = function(self, shortTimeString, longTimeString)
		if type(shortTimeString) == "string" then
			XToLevel_AverageFrame_Blocky_PlayerFrameCounterTimerValueText:SetText(shortTimeString)
		end
	end,
    
    HeaderVisible = function(self, value)
        if value ~= nil then
            if value == true then
                XToLevel_AverageFrame_Blocky_PlayerFrameLabel:Show()
                XToLevel_AverageFrame_Blocky_PlayerFrame:SetHeight(56)
                XToLevel_AverageFrame_Blocky_PlayerFrameCounter:ClearAllPoints()
                XToLevel_AverageFrame_Blocky_PlayerFrameCounter:SetPoint("TOPLEFT", XToLevel_AverageFrame_Blocky_PlayerFrame, "TOPLEFT", 0, -14)
                XToLevel_AverageFrame_Blocky_PlayerFrameProgress:ClearAllPoints()
                XToLevel_AverageFrame_Blocky_PlayerFrameProgress:SetPoint("TOPLEFT", XToLevel_AverageFrame_Blocky_PlayerFrame, "TOPLEFT", 15, -37)
            else
                XToLevel_AverageFrame_Blocky_PlayerFrameLabel:Hide()
                XToLevel_AverageFrame_Blocky_PlayerFrame:SetHeight(39)
                XToLevel_AverageFrame_Blocky_PlayerFrameCounter:ClearAllPoints()
                XToLevel_AverageFrame_Blocky_PlayerFrameCounter:SetPoint("TOPLEFT", XToLevel_AverageFrame_Blocky_PlayerFrame, "TOPLEFT", 0, 0)
                XToLevel_AverageFrame_Blocky_PlayerFrameProgress:ClearAllPoints()
                XToLevel_AverageFrame_Blocky_PlayerFrameProgress:SetPoint("TOPLEFT", XToLevel_AverageFrame_Blocky_PlayerFrame, "TOPLEFT", 15, -20)
            end
        else
            return XToLevel_AverageFrame_Blocky_PlayerFrameLabel:IsVisible()
        end
    end
}
