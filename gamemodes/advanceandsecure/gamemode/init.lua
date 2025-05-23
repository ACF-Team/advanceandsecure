AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("entities/aas_spawnpoint.lua")
include("shared.lua")

local ST = SysTime

-- Initialize

function GM:Initialize()
	RunConsoleCommand("physgun_maxrange", 256)
	RunConsoleCommand("physgun_maxspeed", 400)
	RunConsoleCommand("physgun_maxangular", 400)
	RunConsoleCommand("sv_airaccelerate", 1)

	if not file.Exists("aas","DATA") then
		MsgN("Missing base directory 'aas', making...")

		file.CreateDir("aas/maps")	-- Stores all of the information relevant to maps
		file.CreateDir("aas/dupes")	-- A place to store dupes that will be distributed to players on request
		file.CreateDir("aas/scans")	-- Stores all of the information regarding map scans, which will be sent to players so they may generate a PNG
	end
end

function GM:InitPostEntity()
	GAMEMODE.FirstLoad	= true
	AAS.Funcs.LoadGamemode(AAS.ModeCV:GetString())
end

if GAMEMODE and GAMEMODE.FirstLoad then timer.Simple(0, function() AAS.Funcs.ReloadGamemode() aasMsg({Colors.ErrorCol, "Gamemode reloaded via refresh."}) end) end -- For development purposes

do	-- Organizing stuff :)
	do	-- Net handling
		-- Sends the gamemode info to the client
		net.Receive("AAS.PlayerInit",function(_,ply)
			print("PLAYERINIT: Updating ", ply)

			AAS.Funcs.UpdateState(ply)
		end)

		-- Handles when a player wishes to change teams legitimately, and will block them if they aren't allowed (team misbalance, changing too often)
		net.Receive("AAS.RequestTeamSwap",function(_,ply)
			if ply.NextTeamSwitch and (ply.NextTeamSwitch >= ST()) then
				aasMsg({Colors.ErrorCol, "You can't switch teams for another " .. math.Round(ply.NextTeamSwitch - ST(), 1) .. " seconds!"}, ply)
				return
			end
			local CurTeam = ply:Team()
			local OppTeam = (CurTeam == 1) and 2 or 1

			local OppTeamData	= AAS.Funcs.GetTeamInfo(CurTeam == 1 and 2 or 1)

			if team.NumPlayers(CurTeam) <= team.NumPlayers(CurTeam == 1 and 2 or 1) then
				local TC = OppTeamData.Color
				aasMsg({Color(TC.x, TC.y, TC.z), OppTeamData.Name, Colors.BadCol, " has too many players for you to join!"},ply)
				return
			end

			-- Reset the player's karma if it is over 0 so they have to contribute to get where they were at, otherwise if its low
			if ply:GetNW2Int("Karma", 0) > 0 then AAS.Funcs.SetKarma(ply, 0) end
			ply:SetNW2Int("Requisition", 0)
			ply.NextPay	= ST() + 1

			ply.FirstSpawn = true
			ply:SetTeam(OppTeam)

			local CurTeamData = AAS.Funcs.GetTeamInfo(ply:Team())

			aasMsg({Colors.BasicCol, ply:Nick() .. " switched to ", CurTeamData.Color, CurTeamData.Name, Colors.BasicCol, "."})

			ply:Spawn()
			ply.NextTeamSwitch = ST() + 60
		end)
	end
end