function callfunc(_, args) -- Editmode
	AAS.Funcs.SetEditMode(tobool(args[1]))

	return true
end

cmdSettings = {
	["Help"] = "<true/false> Enables/Disables editmode for AAS.",
	["MinimumPrivilege"] = 2,
	["RCONCanUse"] = true
}
BAdmin.Utilities.addCommand("aas_editmode", callfunc, cmdSettings)


function callfunc() -- Reload
	AAS.Funcs.FullReload()

	return true
end

cmdSettings = {
	["Help"] = "Loads the current save for the map.",
	["MinimumPrivilege"] = 2,
	["RCONCanUse"] = true
}
BAdmin.Utilities.addCommand("aas_load", callfunc, cmdSettings)


function callfunc() -- Save
	AAS.Funcs.SaveMap()

	return true
end

cmdSettings = {
	["Help"] = "Saves the map in the current state.",
	["MinimumPrivilege"] = 2,
	["RCONCanUse"] = true
}
BAdmin.Utilities.addCommand("aas_save", callfunc, cmdSettings)


function callfunc() -- Vote
	AAS.Funcs.openVotes()

	return true
end

cmdSettings = {
	["Help"] = "Opens the votemap menu.",
	["MinimumPrivilege"] = 2,
	["RCONCanUse"] = true
}
BAdmin.Utilities.addCommand("aas_openvote", callfunc, cmdSettings)


function callfunc(ply) -- RTV Vote
	local voted, reason = AAS.Funcs.serverRTV(ply)

	if not voted then return false, reason end

	return true
end

cmdSettings = {
	["Help"] = "Vote towards opening votemap.",
	["MinimumPrivilege"] = 0,
	["RCONCanUse"] = false
}
BAdmin.Utilities.addCommand("rtv", callfunc, cmdSettings)