---
-- Locale module. Manages locale selection and access.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local LocaleModule = XToLevel:NewModule("LocaleModule")

function LocaleModule:OnInitialize()
    -- Locale files are already loaded via locale.xml before modules.
    -- This module just provides access.
end

function LocaleModule:OnEnable()
end

function LocaleModule:SetLocale(name)
    return addonTable.SetLocale(name)
end

function LocaleModule:GetLocale()
    return addonTable.GetLocale()
end

function LocaleModule:GetDisplayLocales()
    return addonTable.GetDisplayLocales()
end

function LocaleModule:WipeLocales()
    addonTable.WipeLocales()
end
