MsgN("+ Cost list loaded")

local ST			= SysTime
local NextReqCheck	= ST()
local CostSystem	= ACF.Contraption.CostSystem

AAS.PlyReq = {}
AAS.RequisitionCosts = {}

do
	do	-- Functions

		-- Iterates across all entities owned by players and puts the current cost against them (not charged, just limiting)
		function AAS.Funcs.CalcRequisition()
			if ST() < NextReqCheck then return end
			local PlyEnts = {}

			local World = game.GetWorld()
			for _, ent in ents.Iterator() do
				if ent:IsPlayerHolding() then continue end
				if (ent:GetCreationTime() + 5.1) > CurTime() then continue end

				local Owner = ent:CPPIGetOwner()
				if Owner == nil then continue end

				if (Owner ~= World) or false then
					if not PlyEnts[Owner] then PlyEnts[Owner] = {} end

					table.insert(PlyEnts[Owner], ent)
				end
			end

			AAS.PlyReq = {}

			for Owner, EntList in pairs(PlyEnts) do
				local Cost = CostSystem.CalcCostsFromEnts(EntList)

				AAS.PlyReq[Owner] = (AAS.PlyReq[Owner] or 0) + Cost
			end

			for _, v in player.Iterator() do
				AAS.PlyReq[v] = math.ceil(AAS.PlyReq[v] or 0)
				v:SetNW2Int("UsedRequisition", AAS.PlyReq[v] or 0)
			end

			NextReqCheck = ST() + 5
		end
	end

	do	-- Hooks
		-- This captures when a player spawns a dupe with Advanced Duplicator 2
		-- This will check the cost of the vehicle and notify the player of that cost, and have a 5 second timer before that cost is deducted from the player
		-- The player can remove it within those 5 seconds so the cost isn't deducted
		-- There are two random entities picked from the dupe that get checked for existing before cost is applied
		hook.Add("AdvDupe_FinishPasting", "CheckDupe", function(Dupe) -- force the requisition calculator to run when a dupe is done pasting
			local DupeEnts = Dupe[1].CreatedEntities
			local Ply = Dupe[1].Player
			if not IsValid(Ply) then return end

			local Cost, Breakdown = CostSystem.CalcCostsFromEnts(DupeEnts)

			Cost = math.ceil(Cost)

			net.Start("AAS.CostPanel")
				net.WriteVector(Dupe[1].HitPos + Vector(0, 0, 32))
				net.WriteTable(Breakdown)
				net.WriteUInt(Cost, 16)
			net.Send(Ply)

			AAS.Funcs.CalcRequisition()
			if Cost > (AAS.Funcs.GetSetting("Max Requisition", 300) - Ply:GetNW2Int("UsedRequisition")) then
				AAS.Funcs.Msg({Colors.ErrorCol, "Not enough total requisition to spawn!"}, Ply)
				if not GetGlobalBool("EditMode", false) then error("Not enough requisition!") end -- Doing this will instantly remove the pasted duplication
			else
				local CheckList	= {}

				local NumEnts	= table.Count(DupeEnts)

				for _ = 1 , math.ceil(NumEnts / 20) do
					local Ent = table.Random(DupeEnts)
					table.insert(CheckList, Ent)
				end

				if GetGlobalBool("EditMode", false) == false then
					AAS.Funcs.Msg({
						Colors.BasicCol, "After 5 seconds this will cost you ",
						Color(255, 127, 127), tostring(Cost),
						Colors.BasicCol, " of your ",
						Colors.GoodCol, tostring(Ply:GetRequisition()),
						Colors.BasicCol, " requisition."},
					Ply)

					timer.Simple(5, function()
						for _, ent in ipairs(CheckList) do
							if not IsValid(ent) then return end
						end

						print("Charging " .. Ply:Nick() .. " for " .. Cost)

						local CanAfford = Dupe[1].Player:ChargeRequisition(Cost, "Cost of dupe")

						if not CanAfford then
							AAS.Funcs.Msg({Colors.ErrorCol, "You can't afford this dupe!"}, Ply)

							for _, v in pairs(Dupe[1].CreatedEntities) do
								v:Remove()
							end
						end
					end)
				end
			end
		end)
	end
end