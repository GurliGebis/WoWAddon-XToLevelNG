---
-- Locale module. Provides access to the AceLocale-3.0 locale table.
---

local addonName, addonTable = ...
local XToLevel = LibStub("AceAddon-3.0"):GetAddon(addonName)
local LocaleModule = XToLevel:NewModule("LocaleModule")

function LocaleModule:OnInitialize()
end

function LocaleModule:OnEnable()
end

function LocaleModule:GetLocale()
    return LibStub("AceLocale-3.0"):GetLocale(addonName)
end
