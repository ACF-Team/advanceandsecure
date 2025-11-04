MsgN("+ Command control loaded")

do	-- BAdmin Command disabling
	local BlockedCmds	= {
		["god"] = true,
		["obs"] = true,
		["spec"]	= true,
	}

	hook.Add("BAdmin.AddCommand", "BAdminCommandBlock", function(cmdString)
		return BlockedCmds[cmdString] or false
	end)
end

do	-- ConCommands
	concommand.Add("aas_editmode",function(ply,cmd,arg)
		if not ((ply == NULL) or (ply:IsSuperAdmin())) then aasMsg({Colors.ErrorCol,"You aren't allowed to run that command!"},ply) return end

		local Arg = tobool(arg[1]) or false
		AAS.Funcs.SetEditMode(Arg)
	end)

	concommand.Add("aas_save",function(ply)
		if not ((ply == NULL) or (ply:IsSuperAdmin())) then aasMsg({Colors.ErrorCol,"You aren't allowed to run that command!"},ply) return else AAS.Funcs.SaveMap() end
	end)

	concommand.Add("aas_load",function(ply)
		if not ((ply == NULL) or (ply:IsSuperAdmin())) then aasMsg({Colors.ErrorCol,"You aren't allowed to run that command!"},ply) return else AAS.Funcs.FullReload() end
	end)

	concommand.Add("aas_opensettings",function(ply)
		if ply == NULL then print("You can't run this from rcon!") return end
		if not ply:IsSuperAdmin() then aasMsg({Colors.ErrorCol,"You aren't allowed to run that command!"},ply) return end
		if GetGlobalBool("EditMode",false) == false then ply:PrintMessage(HUD_PRINTTALK,"The server is not in edit mode!") return end

		AAS.Funcs.UpdateState(ply)

		timer.Simple(0,function()
			net.Start("AAS.OpenSettings")
			net.WriteTable(AAS.GM.Settings)
			net.Send(ply)
		end)

	end)

	concommand.Add("aas_scan",function(ply)
		if not ((ply == NULL) or (ply:IsSuperAdmin())) then aasMsg({Colors.ErrorCol, "You aren't allowed to run that command!"},ply) return else AAS.Funcs.StartScan() end
	end)

	concommand.Add("aas_openvote",function(ply)
		if not ((ply == NULL) or (ply:IsSuperAdmin())) then aasMsg({Colors.ErrorCol, "You aren't allowed to run that command!"},ply) return else AAS.Funcs.openVotes() end
	end)

	concommand.Add("aas_status", function(ply)
		if not ((ply == NULL) or (ply:IsSuperAdmin())) then aasMsg({Colors.ErrorCol, "You aren't allowed to run that command!"},ply) return else
			MsgN("===== [AAS STATUS] =====")

			MsgN("Editmode is currently: " .. (GetGlobalBool("EditMode",false) and "ACTIVE" or "INACTIVE"))

			MsgN("=== GAME ===")

			MsgN("Game is currently: " .. (AAS.State.Active and "RUNNING" or "HALTED"))
			MsgN("Gamemode is: " .. AAS.State.Mode)
			MsgN("Ticket balance is: " .. ("BLUFOR: " .. AAS.State.Team.BLUFOR.Tickets) .. " | " .. ("OPFOR: " .. AAS.State.Team.OPFOR.Tickets))
			MsgN("BLUFOR Score: " .. team.GetScore(1) .. " | OPFOR Score: " .. team.GetScore(2))

			MsgN("===== [END STATUS] =====")
		end
	end)

	concommand.Add("aas_rebuilddupelist", function(ply)
		if not ((ply == NULL) or (ply:IsSuperAdmin())) then aasMsg({Colors.ErrorCol, "You aren't allowed to run that command!"},ply) return else AAS.Funcs.BuildDupeList() end
	end)
end