--	Diesel wars
--[[
	Team deathmatch based gamemode, only ticket loss is from dying

	Resource nodes are around the map that, to be determined how, can spawn a resource package which must be transported back to the team base
	When that happens, the team that receives it, will receive a team-wide payout

	Package should be light enough that a gravity gun can carry it, but not enough to be player carried. Physics gun should be unable to pick it up
	Should also have a maximum lifetime to prevent hoarding

	High limit on requisition per player, but low regular income, so its a good idea to go out and grab these resource packages
]]

local GMT = {}
AAS.Funcs.DefineGamemode("dw", GMT)
GMT.Name	= "Diesel wars"
GMT.Desc	= "Resource-based team deathmatch"

-- Override the default settings for these, to allow much higher limits
AAS.SettingsFuncs.Number(GMT, "Min Requisition", 50, 25, 200, "Minimum amount of requisition", 11) -- Game will try to keep this amount on a player during each payday; incentivizes resource packages
AAS.SettingsFuncs.Number(GMT, "Max Requisition", 500, 50, 1000, "Maximum amount of accruable requisition", -10)
AAS.SettingsFuncs.Number(GMT, "Max Rate", 25, 5, 50, "Rate of requisition per pay cycle", -9)
AAS.SettingsFuncs.Flag(GMT,	"No connection")

GMT.Init	= function(MapData)	-- Setup whatever settings for the map to run here. Should be a clean slate
	AAS.Funcs.UpdateState()
end

local nodeVariables = { -- NWVars specific to nodes that should be saved/loaded
	"ResourceInt",
	"ResourceMax"
}

GMT.Load	= function(MapData) -- Assemble the map here
	for _, node in ipairs(MapData.Nodes) do
		local NewNode = ents.Create("aas_resnode")
		NewNode:SetPos(node.pos)
		NewNode:SetAngles(Angle(-90, 0, 0))
		NewNode:Spawn()

		NewNode:SetResourceInt(node.ResourceInt)
		NewNode:SetResourceMax(node.ResourceMax)
	end
end

GMT.Save	= function(MapData) -- Return false to abort saving for any reason
	MapData.Nodes = {}

	local Nodes = ents.FindByClass("aas_resnode")

	if next(Nodes) ~= nil then
		for _, node in pairs(Nodes) do
			local Pos = node:GetPos()
			local NWVars = node:GetNetworkVars()

			local nodeData	= {
				pos = Vector(math.Round(Pos.x), math.Round(Pos.y), math.Round(Pos.z)),
			}

			for _, val in ipairs(nodeVariables) do
				nodeData[val] = NWVars[val]
			end

			table.insert(MapData.Nodes, nodeData)
		end
	else
		aasMsg({Colors.ErrorCol,"[AAS] No resource nodes detected! Aborting"})
		return false
	end

	return true
end

GMT.TicketThink	= function() -- Called when the server is doing ticket changes

end

GMT.ShortThink	= function() -- Called about every half second, keep it light

end

GMT.LongThink	= function() -- Called every 5 seconds

end

-- We don't use karma for this gamemode, so replace the Payday function
GMT.Payday		= function(ply)
	local MaxGain = AAS.Funcs.GetSetting("Max Rate", 25)
	local MinAmount	= AAS.Funcs.GetSetting("Min Requisition", 100)
	local Time = SysTime()

	if ply == nil then
		for k,v in player.Iterator() do
			if v.NextPay and (v.NextPay > Time) then continue end

			local PlyReq = v:GetRequisition()
			if PlyReq < MinAmount then v:PayRequisition(math.Clamp(MinAmount - PlyReq, 0, MaxGain)) end

			v.NextPay = Time + 60
		end
	else
		if ply.NextPay and (ply.NextPay > Time) then return end

		local PlyReq = ply:GetRequisition()
		if PlyReq < MinAmount then ply:PayRequisition(math.Clamp(MinAmount - PlyReq, 0, MaxGain)) end

		ply.NextPay = Time + 60
	end
end