AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("entities/aas_spawnpoint.lua")
include("shared.lua")

local ST = SysTime

-- Initialize

local RandomMapStart	= CreateConVar("aas_randommapstart", 0, {FCVAR_ARCHIVE}, "Whether or not the game will pick a random map on first startup.", 0, 1)
local MapChanges		= CreateConVar("aas_mapchanges", 0, {FCVAR_ARCHIVE, FCVAR_UNREGISTERED})

function GM:Initialize()
	RunConsoleCommand("physgun_maxrange", 256)
	RunConsoleCommand("physgun_maxspeed", 400)
	RunConsoleCommand("physgun_maxangular", 400)
	RunConsoleCommand("sv_airaccelerate", 1)

	if game.GetMapChangeCount() < MapChanges:GetInt() then MapChanges:SetInt(0) end -- We likely restarted or crashed, so this should be 0...

	MapChanges:SetInt(MapChanges:GetInt() + 1)

	if not file.Exists("aas", "DATA") then
		MsgN("Missing base directory 'aas', making...")

		file.CreateDir("aas/maps")	-- Stores all of the information relevant to maps
		file.CreateDir("aas/dupes")	-- A place to store dupes that will be distributed to players on request
		file.CreateDir("aas/scans")	-- Stores all of the information regarding map scans, which will be sent to players so they may generate a PNG
	end
end

function GM:InitPostEntity()
	GAMEMODE.FirstLoad	= true

	if RandomMapStart:GetBool() and (MapChanges:GetInt() == 1) then
		print("[AAS] Random map start enabled, picking at random...")

		local MapReturn	= AAS.Funcs.completelyRandomMap()

		if not (MapReturn.map == game.GetMap() and MapReturn.mode == AAS.ModeCV:GetString()) then
			print("[AAS] New map/mode picked, '" .. MapReturn.map .. "' with " .. string.upper(MapReturn.mode) .. " as the mode!")

			timer.Simple(1, function()
				AAS.Funcs.changeMap(MapReturn.map, MapReturn.mode)
			end)

			return
		else
			print("[AAS] Same map and mode rolled, continuing as normal")
		end
	end

	timer.Simple(60 * 15, AAS.Funcs.openRTV)

	AAS.Funcs.LoadGamemode(AAS.ModeCV:GetString())
end

if GAMEMODE and GAMEMODE.FirstLoad then timer.Simple(0, function() AAS.Funcs.ReloadGamemode() AAS.Funcs.Msg({Colors.ErrorCol, "Gamemode reloaded via refresh."}) end) end -- For development purposes

do	-- Organizing stuff :)
	do	-- Net handling
		-- Sends the gamemode info to the client
		net.Receive("AAS.PlayerInit", function(_, ply)
			print("PLAYERINIT: Updating ", ply)

			AAS.Funcs.UpdateState(ply)
		end)

		-- Handles when a player wishes to change teams legitimately, and will block them if they aren't allowed (team misbalance, changing too often)
		net.Receive("AAS.RequestTeamSwap", function(_, ply)
			if ply.NextTeamSwitch and (ply.NextTeamSwitch >= ST()) then
				AAS.Funcs.Msg({Colors.ErrorCol, "You can't switch teams for another " .. math.Round(ply.NextTeamSwitch - ST(), 1) .. " seconds!"}, ply)
				return
			end
			local CurTeam = ply:Team()
			local OppTeam = (CurTeam == 1) and 2 or 1

			local OppTeamData	= AAS.Funcs.GetTeamInfo(CurTeam == 1 and 2 or 1)

			if team.NumPlayers(CurTeam) <= team.NumPlayers(CurTeam == 1 and 2 or 1) then
				local TC = OppTeamData.Color
				AAS.Funcs.Msg({Color(TC.x, TC.y, TC.z), OppTeamData.Name, Colors.BadCol, " has too many players for you to join!"}, ply)
				return
			end

			-- Reset the player's karma if it is over 0 so they have to contribute to get where they were at, otherwise if its low
			if ply:GetNW2Int("Karma", 0) > 0 then AAS.Funcs.SetKarma(ply, 0) end
			ply:SetNW2Int("Requisition", 0)
			ply.NextPay	= ST() + 1

			ply.FirstSpawn = true
			ply:SetTeam(OppTeam)

			local CurTeamData = AAS.Funcs.GetTeamInfo(ply:Team())

			AAS.Funcs.Msg({Colors.BasicCol, ply:Nick() .. " switched to ", CurTeamData.Color, CurTeamData.Name, Colors.BasicCol, "."})

			ply:Spawn()
			ply.NextTeamSwitch = ST() + 60
		end)
	end
end