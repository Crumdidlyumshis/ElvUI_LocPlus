local E, L, V, P, G = unpack(ElvUI)
local LP = E:GetModule('LocationPlus')

local Tourist = LibStub('LibTourist-3.0')

local format, tonumber, pairs = string.format, tonumber, pairs

local GetBindLocation = GetBindLocation
local GetCurrencyListSize = GetCurrencyListSize
local UnitLevel = UnitLevel
local GameTooltip = _G['GameTooltip']

local PLAYER, UNKNOWN, TRADE_SKILLS, TOKENS, BUG_CATEGORY3 = PLAYER, UNKNOWN, TRADE_SKILLS, TOKENS, BUG_CATEGORY3
local LEVEL_RANGE, STATUS, HOME, CONTINENT, PVP, RAID = LEVEL_RANGE, STATUS, HOME, CONTINENT, PVP, RAID

-- GLOBALS: selectioncolor, continent, continentID

-- Icons on Location Panel
local FISH_ICON = "|TInterface\\AddOns\\ElvUI_LocPlus\\media\\fish.tga:24:24|t"
local LEVEL_ICON = "|TInterface\\AddOns\\ElvUI_LocPlus\\media\\levelup.tga:24:24|t"

--------------------
-- Currency Table --
--------------------
local currency = {
	395,	-- Justice Points
	396,	-- Valor Points
	777,	-- Timeless Coins
	697,	-- Elder Charm of Good Fortune
	738,	-- Lesser Charm of Good Fortune
	390,	-- Conquest Points
	392,	-- Honor Points
	515,	-- Darkmoon Prize Ticket
	402,	-- Ironpaw Token
	776,	-- Warforged Seal

	-- WoD
	--824,	-- Garrison Resources
	--823,	-- Apexis Crystal (for gear, like the valors)
	--994,	-- Seal of Tempered Fate (Raid loot roll)
	--980,	-- Dingy Iron Coins (rogue only, from pickpocketing)
	--944,	-- Artifact Fragment (PvP)
	--1101,	-- Oil
	--1129,	-- Seal of Inevitable Fate
	--821,	-- Draenor Clans Archaeology Fragment
	--828,	-- Ogre Archaeology Fragment
	--829,	-- Arakkoa Archaeology Fragment
	--1166, -- Timewarped Badge (6.22)
	--1191,	-- Valor Points (6.23)

	-- Legion
	--1226,	-- Nethershard (Invasion scenarios)
	--1172,	-- Highborne Archaeology Fragment
	--1173,	-- Highmountain Tauren Archaeology Fragment
	--1155,	-- Ancient Mana
	--1220,	-- Order Resources
	--1275,	-- Curious Coin (Buy stuff :P)
	--1226,	-- Nethershard (Invasion scenarios)
	--1273,	-- Seal of Broken Fate (Raid)
	--1154,	-- Shadowy Coins
	--1149,	-- Sightless Eye (PvP)
	--1268,	-- Timeworn Artifact (Honor Points?)
	--1299,	-- Brawler's Gold
	--1314,	-- Lingering Soul Fragment (Good luck with this one :D)
	--1342,	-- Legionfall War Supplies (Construction at the Broken Shore)
	--1355,	-- Felessence (Craft Legentary items)
	--1356,	-- Echoes of Battle (PvP Gear)
	--1357,	-- Echoes of Domination (Elite PvP Gear)
	--1416,	-- Coins of Air
	--1506,	-- Argus Waystone
	--1508,	-- Veiled Argunite
	--1533,	-- Wakening Essence

	-- BfA
	--1560, -- War Resources
	--1580,	-- Seal of Wartorn Fate
	--1587,	-- War Supplies
	--1710,	-- Seafarer's Dubloon
	--1718,	-- Titan Residuum
	--1719,	-- Corrupted Memento
	--1721,	-- Prismatic Manapearl
	--1755,	-- Coalescing Visions
	--1803,	-- Echoes of Ny'alotha

	-- Shadowlands
	--1751,	-- Freed Soul
	--1754,	-- Argent Commendation
	--1767, -- Stygia
	--1810,	-- Willing Soul
	--1813,	-- Reservoir Anima
	--1816, -- Sinstone Fragments
	--1820,	-- Infused Ruby
	--1822,	-- Renown
	--1828, -- Soul Ash
	--1906,	-- Sould Cinders
	--1885, -- Grateful Offering
	--1792,	-- Honor
	--1602,	-- New Conquest Points
	--1191,	-- Valor
	--1977,	-- Stygian Ember
	--1904,	-- Tower Knowledge
	--1931,	-- Cataloged Research
	--1979,	-- Cyphers of the First Ones
	--2009,	-- Cosmic Flux

	-- Dragonflight
	-- 1191,	-- Valor
	-- 1602,	-- New Conquest Points
	-- 1792,	-- Honor
	-- 2123,	-- Bloody Tokens
	-- 2003,	-- Dragon Isles Supplies
	-- 2118,	-- Elemental Overflow
	-- 2122,	-- Storm Sigil
	-- 2245,	-- Flightstones
	-- 2594,	-- Paracasual Flakes
	-- 2650,	-- Emerald Dewdrop
	-- 2706,	-- Whelping's Dreaming Crest
	-- 2707,	-- Drake's Dreaming Crest
	-- 2708,	-- Wyrm's Dreaming Crest
	-- 2709,	-- Aspect's Dreaming Crest
	-- 2657,	-- Mysterious Fragment
}

--[[if E.myfaction == 'Alliance' then
	tinsert(currency, 1717)
elseif E.myfaction == 'Horde' then
	tinsert(currency, 1716)
end]]

-----------------------
-- Tooltip functions --
-----------------------

-- Dungeon coords
local function GetDungeonCoords(zone)
	local z, x, y = "", 0, 0
	local dcoords

	if Tourist:IsInstance(zone) then
		z, x, y = Tourist:GetEntrancePortalLocation(zone)
	end

	if z == nil then
		dcoords = ""
	elseif E.db.locplus.ttcoords then
		x = tonumber(E:Round(x*100, 0))
		y = tonumber(E:Round(y*100, 0))
		dcoords = format(" |cffffffff(%d, %d)|r", x, y)
	else
		dcoords = ""
	end

	return dcoords
end

-- PvP/Raid filter
local function PvPorRaidFilter(zone)
	local isPvP, isRaid

	isPvP = nil
	isRaid = nil

	if(not E.Classic and Tourist:IsArena(zone) or Tourist:IsBattleground(zone)) then
		if E.db.locplus.tthidepvp then
			return
		end
		isPvP = true
	end

	if(not isPvP and Tourist:GetInstanceGroupSize(zone) >= 10) then
		if E.db.locplus.tthideraid then
			return
		end
		isRaid = true
	end

	return (isPvP and "|cffff0000 "..PVP.."|r" or "")..(isRaid and "|cffff4400 "..RAID.."|r" or "")
end

-- Recommended zones
local function GetRecomZones(zone)
	local low, high = Tourist:GetLevel(zone)
	local r, g, b = Tourist:GetLevelColor(zone)
	local zContinent = Tourist:GetContinent(zone)

	if PvPorRaidFilter(zone) == nil then return end

	GameTooltip:AddDoubleLine(
	"|cffffffff"..zone
	..PvPorRaidFilter(zone) or "",
	format("|cff%02xff00%s|r", continent == zContinent and 0 or 255, zContinent)
	..(" |cff%02x%02x%02x%s|r"):format(r *255, g *255, b *255,(low == high and low or ("%d-%d"):format(low, high))))
end

-- Dungeons in the zone
local function GetZoneDungeons(dungeon)
	local low, high = Tourist:GetLevel(dungeon)
	local r, g, b = Tourist:GetLevelColor(dungeon)
	local groupSize = Tourist:GetInstanceGroupSize(dungeon)
	local altGroupSize = Tourist:GetInstanceAltGroupSize(dungeon)
	local groupSizeStyle = (groupSize > 0 and format("|cFFFFFF00|r (%d", groupSize) or "")
	local altGroupSizeStyle = (altGroupSize > 0 and format("|cFFFFFF00|r/%d", altGroupSize) or "")
	local name = dungeon

	if PvPorRaidFilter(dungeon) == nil then return end

	GameTooltip:AddDoubleLine(
	"|cffffffff"..name
	..(groupSizeStyle or "")
	..(altGroupSizeStyle or "").."-"..PLAYER..") "
	..GetDungeonCoords(dungeon)
	..PvPorRaidFilter(dungeon) or "",
	("|cff%02x%02x%02x%s|r"):format(r *255, g *255, b *255,(low == high and low or ("%d-%d"):format(low, high))))
end

-- Recommended Dungeons
local function GetRecomDungeons(dungeon)
	local low, high = Tourist:GetLevel(dungeon)
	local r, g, b = Tourist:GetLevelColor(dungeon)
	local instZone = Tourist:GetInstanceZone(dungeon)
	local name = dungeon

	if PvPorRaidFilter(dungeon) == nil then return end

	if instZone == nil then
		instZone = ""
	else
		instZone = "|cFFFFA500 ("..instZone..")"
	end

	GameTooltip:AddDoubleLine(
	"|cffffffff"..name
	..instZone
	..GetDungeonCoords(dungeon)
	..PvPorRaidFilter(dungeon) or "",
	("|cff%02x%02x%02x%s|r"):format(r *255, g *255, b *255,(low == high and low or ("%d-%d"):format(low, high))))
end

local function GetTokenInfo(id)
	local info = C_CurrencyInfo_GetCurrencyInfo(id)
	if info then
		return info.name, info.quantity, info.iconFileID, info.maxQuantity
	else
		return
	end
end

-- Status
function LP:GetStatus(color)
	local status = ""
	local statusText
	local r, g, b = 1, 1, 0
	local pvpType = GetZonePVPInfo()
	local inInstance, _ = IsInInstance()

	if (pvpType == "sanctuary") then
		status = SANCTUARY_TERRITORY
		r, g, b = 0.41, 0.8, 0.94
	elseif(pvpType == "arena") then
		status = ARENA
		r, g, b = 1, 0.1, 0.1
	elseif(pvpType == "friendly") then
		status = FRIENDLY
		r, g, b = 0.1, 1, 0.1
	elseif(pvpType == "hostile") then
		status = HOSTILE
		r, g, b = 1, 0.1, 0.1
	elseif(pvpType == "contested") then
		status = CONTESTED_TERRITORY
		r, g, b = 1, 0.7, 0.10
	elseif(pvpType == "combat" ) then
		status = COMBAT
		r, g, b = 1, 0.1, 0.1
	elseif inInstance then
		status = AGGRO_WARNING_IN_INSTANCE
		r, g, b = 1, 0.1, 0.1
	else
		status = CONTESTED_TERRITORY
	end

	statusText = format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, status)

	if color then
		return r, g, b
	else
		return statusText
	end
end

-- Get Fishing Level
function LP:GetFishingLvl(ontt)
	local zoneText = GetRealZoneText() or UNKNOWN
	local minFish, maxFish = Tourist:GetFishingLevel(zoneText)
    -- print(minFish, maxFish)

	if minFish and maxFish then
		if ontt then
			return minFish, maxFish
		else
			if E.db.locplus.showicon then
				return format(" (%s-%s) ", minFish, maxFish)..FISH_ICON
			else
				return format(" (%s-%s) ", minFish, maxFish)
			end
		end
	else
		return ""
	end
end

-- Zone level range
function LP:GetLevelRange(zoneText, ontt)
	local zoneText = zoneText or GetRealZoneText() or UNKNOWN
	local low, high = Tourist:GetLevel(zoneText)
	local dlevel
	if low > 0 and high > 0 then
		local r, g, b = Tourist:GetLevelColor(zoneText)
		if low ~= high then
			dlevel = format("|cff%02x%02x%02x%d-%d|r", r*255, g*255, b*255, low, high) or ""
		else
			dlevel = format("|cff%02x%02x%02x%d|r", r*255, g*255, b*255, high) or ""
		end

		if ontt then
			return dlevel
		else
			if E.db.locplus.showicon then
				dlevel = format(" (%s) ", dlevel)..LEVEL_ICON
			else
				dlevel = format(" (%s) ", dlevel)
			end
		end
	end

	return dlevel or ""
end


function LP:UpdateTooltip()
	local zoneText = GetRealZoneText() or UNKNOWN
	local curPos = (zoneText.." ") or ""

	GameTooltip:ClearLines()

	-- Zone
	GameTooltip:AddDoubleLine(L["Zone : "], zoneText, 1, 1, 1, selectioncolor)

	-- Continent
	GameTooltip:AddDoubleLine(CONTINENT.." : ", Tourist:GetContinent(zoneText), 1, 1, 1, selectioncolor)

	-- Home
	GameTooltip:AddDoubleLine(HOME.." :", GetBindLocation(), 1, 1, 1, 0.41, 0.8, 0.94)

	-- Status
	if E.db.locplus.ttst then
		GameTooltip:AddDoubleLine(STATUS.." :", LP:GetStatus(false), 1, 1, 1)
	end

    -- Zone level range
	if E.db.locplus.ttlvl then
		local checklvl = LP:GetLevelRange(zoneText, true)
		if checklvl ~= "" then
			GameTooltip:AddDoubleLine(LEVEL_RANGE.." : ", checklvl, 1, 1, 1)
		end
	end

	-- Recommended zones
	if E.db.locplus.ttreczones then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Recommended Zones :"], selectioncolor)

		for zone in Tourist:IterateRecommendedZones() do
			GetRecomZones(zone)
		end
	end

	-- Instances in the zone
	if E.db.locplus.ttinst and Tourist:DoesZoneHaveInstances(zoneText) and not E.Classic then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(curPos..BUG_CATEGORY3.." :", selectioncolor)

		for dungeon in Tourist:IterateZoneInstances(zoneText) do
			GetZoneDungeons(dungeon)
		end
	end

	-- Recommended Instances
	local level = UnitLevel('player')
	if E.db.locplus.ttrecinst and Tourist:HasRecommendedInstances() and level >= 15 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Recommended Dungeons :"], selectioncolor)

		for dungeon in Tourist:IterateRecommendedInstances() do
			GetRecomDungeons(dungeon)
		end
	end

	-- Currency
	if E.Retail then
		local numEntries = GetCurrencyListSize() -- Check for entries to disable the tooltip title when no currency
		if E.db.locplus.curr and numEntries > 0 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(TOKENS.." :", selectioncolor)

			for _, id in pairs(currency) do
				local name, amount, icon, totalMax = GetTokenInfo(id)

				if(name and amount > 0) then
					icon = ("|T%s:12:12:1:0|t"):format(icon)

					if id == 1822 then -- Renown "cheat"
						amount = amount + 1
						totalMax = totalMax + 1
					end

					if totalMax == 0 then
						GameTooltip:AddDoubleLine(icon..format(" %s : ", name), format("%s", amount ), 1, 1, 1, selectioncolor)
					else
						GameTooltip:AddDoubleLine(icon..format(" %s : ", name), format("%s / %s", amount, totalMax ), 1, 1, 1, selectioncolor)
					end
				end
			end
		end
	end

    if E.db.locplus.prof then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(TRADE_SKILLS.." :", selectioncolor)

        local SecondarySkill = SECONDARY_SKILLS:gsub(":", '')
        local hasSecondary = false
        for skillIndex = 1, GetNumSkillLines() do
            local skillName, isHeader, _, skillRank, _, skillModifier, skillMaxRank, isAbandonable = GetSkillLineInfo(skillIndex)

            if hasSecondary and isHeader then
                hasSecondary = false
            end

            if (skillName and isAbandonable) or hasSecondary then
                if skillName and (skillRank < skillMaxRank or (not E.db.locplus.profcap)) then
                    if (skillModifier and skillModifier > 0) then
                        GameTooltip:AddDoubleLine(format("%s :", skillName), (format("%s |cFF6b8df4+ %s|r / %s", skillRank, skillModifier, skillMaxRank)), 1, 1, 1, selectioncolor)
                    else
                        GameTooltip:AddDoubleLine(format("%s :", skillName), (format("%s / %s", skillRank, skillMaxRank)), 1, 1, 1, selectioncolor)
                    end
                end
            end

            if isHeader then
                if skillName == SecondarySkill then
                    hasSecondary = true
                end
            end
        end
    end

	-- Hints
	if E.db.locplus.tt then
		if E.db.locplus.tthint then
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(L["Click : "], L["Toggle WorldMap"], 0.7, 0.7, 1, 0.7, 0.7, 1)
			GameTooltip:AddDoubleLine(L["RightClick : "], L["Toggle Configuration"],0.7, 0.7, 1, 0.7, 0.7, 1)
			GameTooltip:AddDoubleLine(L["ShiftClick : "], L["Send position to chat"],0.7, 0.7, 1, 0.7, 0.7, 1)
			GameTooltip:AddDoubleLine(L["CtrlClick : "], L["Toggle Datatexts"],0.7, 0.7, 1, 0.7, 0.7, 1)
		end
		GameTooltip:Show()
	else
		GameTooltip:Hide()
	end
end
