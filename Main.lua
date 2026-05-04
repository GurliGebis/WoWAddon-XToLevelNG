local addonName, addonTable = ...

XToLevel = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0", "AceTimer-3.0")

XToLevel.Name = C_AddOns.GetAddOnMetadata(addonName, "Title")
XToLevel.Version = "@project-version@"
XToLevel.ReleaseDate = "@project-date-iso@"
XToLevel.AddonTable = addonTable
