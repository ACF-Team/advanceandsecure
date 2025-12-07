MsgN("+ Cost list loaded")

local ST = SysTime

local NextReqCheck = ST()

AAS.PlyReq = {}
AAS.RequisitionCosts = {}

-- When adding to this list, keep in mind if it does not have a special function below, it will use this cost. This is perfect for static costs.
AAS.RequisitionCosts.CalcSingleFilter = {
	gmod_wire_expression2	= 0.75,
	starfall_processor		= 0.75,
	acf_piledriver			= 5,
	acf_rack				= 10,
	acf_engine				= 1,
	acf_gearbox				= 0,
	acf_fueltank			= 0,
	prop_physics			= 1,
	acf_armor				= 1,
	acf_gun					= 1,
	acf_ammo				= 1,
	acf_radar				= 10,
	gmod_wire_gate			= 1,
	primitive_shape			= 1,
	acf_turret				= 0,
	acf_turret_motor		= 1,
	acf_turret_gyro			= 1,
	acf_turret_computer		= 5,
	acf_baseplate			= 1,
	acf_controller			= 0.75,
	acf_crew				= 1,
	acf_groundloader		= 20,
}

AAS.RequisitionCosts.ACFGunCost = { -- anything not on here costs 1
	SB	= 1, -- old smoothbores, leaving
	C	= 0.4,
	SC	= 0.275,
	AC	= 1.1,
	LAC	= 1,
	HW	= 0.5,
	MO	= 0.35,
	RAC	= 1.75,
	SA	= 0.55,
	AL	= 0.6,
	GL	= 0.5,
	MG	= 0.25,
	SL	= 0.02,
	FGL	= 0.125
}

AAS.RequisitionCosts.ACFAmmoModifier = { -- Anything not in here is 0.2
	AP		= 0.3,
	APCR	= 0.5,
	APDS	= 0.9,
	APFSDS	= 1.2,
	APHE	= 0.4,
	HE		= 0.35,
	HEAT	= 0.5,
	HEATFS	= 1.1,
	FL		= 0.2,
	HP		= 0.1,
	SM		= 0.1,
	GLATGM	= 1.5,
	FLR		= 0.05,
}

AAS.RequisitionCosts.ACFMissileModifier = { -- Default 5
	ATGM	= 8,
	AAM		= 5,
	ARM		= 2.5,
	ARTY	= 6,
	BOMB	= 4, -- Dumb bomb
	FFAR	= 1,
	GBOMB	= 5, -- Glide bomb
	GBU		= 6, -- Guided bomb
	SAM		= 2,
	UAR		= 3,
}

AAS.RequisitionCosts.ACFRadars = { -- Should be prohibitively expensive, defaults to 50
	-- Missile detecting radars
	["LargeDIR-AM"]		= 30,
	["MediumDIR-AM"]	= 15,
	["SmallDIR-AM"]		= 5,

	["LargeOMNI-AM"]	= 50,
	["MediumOMNI-AM"]	= 30,
	["SmallOMNI-AM"]	= 15,

	-- Contraption detecting radars
	["LargeDIR-TGT"]	= 60,
	["MediumDIR-TGT"]	= 35,
	["SmallDIR-TGT"]	= 15,

	["LargeOMNI-TGT"]	= 80,
	["MediumOMNI-TGT"]	= 50,
	["SmallOMNI-TGT"]	= 30,
}

AAS.RequisitionCosts.SpecialModelFilter = { -- any missile rack not in here costs 10 points
	-- These small racks Im just going to compare against 70mm and scale cost, per missile slot

	["models/missiles/launcher7_40mm.mdl"]	= 4,
	["models/failz/ub_16.mdl"]		= 13,
	["models/failz/ub_32.mdl"]		= 26,
	["models/missiles/launcher7_70mm.mdl"]	= 7,
	["models/failz/lau_61.mdl"]		= 19,
	["models/failz/b8.mdl"]			= 22.8,

	["models/ghosteh/lau10.mdl"]	= 15,

	["models/missiles/rk3uar.mdl"]	= 9,

	["models/spg9/spg9.mdl"]		= 5,

	["models/kali/weapons/kornet/parts/9m133 kornet tube.mdl"] = 12.5,
	["models/missiles/9m120_rk1.mdl"]	= 15,
	["models/missiles/at3rs.mdl"]		= 4,
	["models/missiles/at3rk.mdl"]		= 4,

	-- BIG rack, can hold lots of boom
	["models/missiles/6pod_rk.mdl"]		= 20,

	-- YUGE fuckin tube, launches a 380mm rocket
	["models/launcher/rw61.mdl"]		= 30,

	["models/missiles/agm_114_2xrk.mdl"]	= 10,
	["models/missiles/agm_114_4xrk.mdl"]	= 20,

	["models/missiles/bgm_71e_round.mdl"]	= 5,
	["models/missiles/bgm_71e_2xrk.mdl"]	= 10,
	["models/missiles/bgm_71e_4xrk.mdl"]	= 20,

	["models/missiles/fim_92_1xrk.mdl"]		= 2.5,
	["models/missiles/fim_92_2xrk.mdl"]		= 5,
	["models/missiles/fim_92_4xrk.mdl"]		= 10,

	["models/missiles/9m31_rk1.mdl"]	= 7.5,
	["models/missiles/9m31_rk2.mdl"]	= 15,
	["models/missiles/9m31_rk4.mdl"]	= 30,

	["models/missiles/bomb_3xrk.mdl"]	= 9,

	["models/missiles/rkx1_sml.mdl"]	= 3,
	["models/missiles/rkx1.mdl"]		= 3,
	["models/missiles/rack_double.mdl"]	= 6,
	["models/missiles/rack_quad.mdl"]	= 12
}

local CostFilter = {}
CostFilter["acf_gun"] = function(E) return (AAS.RequisitionCosts.ACFGunCost[E.Class] or 1) * E.Caliber end
CostFilter["acf_engine"] = function(E) return math.max(5, (E.PeakTorque / 160) + (E.PeakPower / 80)) end
CostFilter["acf_rack"] = function(E)
	if AAS.RequisitionCosts.SpecialModelFilter[E:GetModel()] then
		return AAS.RequisitionCosts.SpecialModelFilter[E:GetModel()]
	else
		return 10
	end
end
CostFilter["acf_radar"] = function(E)
	local ID = E.ShortName

	if AAS.RequisitionCosts.ACFRadars[ID] then
		return AAS.RequisitionCosts.ACFRadars[ID]
	else
		return 50
	end
end
CostFilter["acf_ammo"] = function(E)
	if E.AmmoType == "Refill" then
		return E.Capacity * 0.05
	elseif E.IsMissileAmmo then -- Only present on crates that actually hold ACF-3 Missiles ammo, courtesy of a hook intercept in ACF-3 Missiles
		return E.Capacity * (AAS.RequisitionCosts.ACFAmmoModifier[E.AmmoType] or 0.2) * (AAS.RequisitionCosts.ACFMissileModifier[E.Class] or 10) * math.max(1, (E.Caliber / 100) ^ 1.5)
	else
		return E.Capacity * (AAS.RequisitionCosts.ACFAmmoModifier[E.AmmoType] or 0.2) * ((E.Caliber / 100) ^ 2) * (AAS.RequisitionCosts.ACFGunCost[E.Class] or 1)
	end
end

CostFilter["acf_turret_motor"] = function(E)
	return E.CompSize * 2
end
CostFilter["acf_turret_gyro"] = function(E)
	return E.IsDual and 8 or 4
end

local ArmorCalc = function(E)
	local phys = E:GetPhysicsObject()

	if IsValid(phys) then
		return 0.1 + math.max(0.01, phys:GetMass() / 500)
	else
		return 1
	end
end

CostFilter["acf_armor"] = ArmorCalc
CostFilter["prop_physics"] = ArmorCalc
CostFilter["primitive_shape"] = ArmorCalc
CostFilter["gmod_wire_gate"] = ArmorCalc
CostFilter["acf_baseplate"] = ArmorCalc

local FilterList = {}
for k in pairs(AAS.RequisitionCosts.CalcSingleFilter) do
	table.insert(FilterList, k)
end

do
	do	-- Functions

		-- Calculates cost of a single entity
		function AAS.Funcs.CalcCost(E)
			local Class = E:GetClass()
			if not AAS.RequisitionCosts.CalcSingleFilter[Class] then return 0 end
			local Cost = AAS.RequisitionCosts.CalcSingleFilter[Class] or 1

			if CostFilter[Class] then
				Cost = CostFilter[Class](E)
			end

			return Cost
		end

		-- Iterates across all entities owned by players and puts the current cost against them (not charged, just limiting)
		function AAS.Funcs.CalcRequisition()
			if ST() < NextReqCheck then return end
			local Ents = {}
			local EntLookup = {}
			local PlyEnts = {}

			local PreFilterEnts = {}
			for _, class in ipairs(FilterList) do
				local TempEnts = ents.FindByClass(class)
				table.Add(PreFilterEnts, TempEnts)
			end

			local World = game.GetWorld()
			for _, ent in ipairs(PreFilterEnts) do
				if ent:IsPlayerHolding() then continue end
				if (ent:GetCreationTime() + 10.1) > CurTime() then continue end
				local Owner = ent:CPPIGetOwner()
				if Owner == nil then continue end
				if (Owner ~= World) or false then
					table.insert(Ents, ent)
					EntLookup[ent] = Owner

					if not PlyEnts[Owner] then PlyEnts[Owner] = {} end

					table.insert(PlyEnts[Owner], ent)
				end
			end

			AAS.PlyReq = {}

			for _, ent in ipairs(Ents) do
				local Class = ent:GetClass()
				if not AAS.RequisitionCosts.CalcSingleFilter[Class] then continue end

				local Owner = ent:CPPIGetOwner()
				local Cost = AAS.Funcs.CalcCost(ent)

				AAS.PlyReq[Owner] = (AAS.PlyReq[Owner] or 0) + Cost
			end

			for _, v in player.Iterator() do
				AAS.PlyReq[v] = math.ceil(AAS.PlyReq[v] or 0)
				v:SetNW2Int("UsedRequisition", AAS.PlyReq[v] or 0)
			end

			NextReqCheck = ST() + 1
		end

		-- Calculates cost of a group of entities
		function AAS.Funcs.CalcContraptionRequisition(Ents)
			local TotalCost = 0
			local CostBreakdown = {}
			local DupeCenter = nil
			local Highest = 0
			local EntCount = 0

			for _, ent in pairs(Ents) do
				local Class = ent:GetClass()
				--if not AAS.RequisitionCosts.CalcSingleFilter[Class] then continue end
				local Cost = AAS.Funcs.CalcCost(ent)

				if not CostBreakdown[Class] then CostBreakdown[Class] = 0 end

				CostBreakdown[Class] = CostBreakdown[Class] + Cost

				if not DupeCenter then
					DupeCenter = ent:GetPos()
					Highest = DupeCenter.z
				else
					DupeCenter = DupeCenter + ent:GetPos()
					if ent:GetPos().z > Highest then Highest = ent:GetPos().z end
				end

				EntCount = EntCount + 1
				TotalCost = TotalCost + Cost
			end

			TotalCost		= math.ceil(TotalCost)
			DupeCenter		= (DupeCenter and DupeCenter / EntCount) or vector_origin
			DupeCenter.z	= Highest

			return TotalCost, CostBreakdown, DupeCenter
		end
	end

	do	-- Hooks
		-- This captures when a player spawns a dupe with Advanced Duplicator 2
		-- This will check the cost of the vehicle and notify the player of that cost, and have a 10 second timer before that cost is deducted from the player
		-- The player can remove it within those 10 seconds so the cost isn't deducted
		-- There are two random entities picked from the dupe that get checked for existing before cost is applied
		hook.Add("AdvDupe_FinishPasting", "CheckDupe", function(Dupe) -- force the requisition calculator to run when a dupe is done pasting
			local DupeEnts = Dupe[1].CreatedEntities
			local Ply = Dupe[1].Player
			if not IsValid(Ply) then return end

			local Cost, Breakdown, DupeCenter = AAS.Funcs.CalcContraptionRequisition(DupeEnts)

			net.Start("AAS.CostPanel")
				net.WriteVector(DupeCenter)
				net.WriteTable(Breakdown)
				net.WriteUInt(Cost, 16)
			net.Send(Ply)

			AAS.Funcs.CalcRequisition()
			if Cost > (AAS.Funcs.GetSetting("Max Requisition", 300) - Ply:GetNW2Int("UsedRequisition")) then
				aasMsg({Colors.ErrorCol, "Not enough total requisition to spawn!"}, Ply)
				if not GetGlobalBool("EditMode", false) then error("Not enough requisition!") end -- Doing this will instantly remove the pasted duplication
			else
				local CheckEnt = table.Random(DupeEnts)
				while not IsValid(CheckEnt) do
					CheckEnt = table.Random(DupeEnts)
				end
				local SecondCheckEnt = table.Random(DupeEnts)
				while (not IsValid(SecondCheckEnt)) and (SecondCheckEnt ~= CheckEnt) do
					SecondCheckEnt = table.Random(DupeEnts)
				end

				if GetGlobalBool("EditMode", false) == false then
					aasMsg({Colors.BasicCol, "After 10 seconds this will cost you ", Color(255, 127, 127), tostring(Cost), Colors.BasicCol, " of your ", Colors.GoodCol, tostring(Ply:GetRequisition()), Colors.BasicCol, " requisition."}, Ply)

					timer.Simple(10, function()
						if not (IsValid(CheckEnt) or IsValid(SecondCheckEnt)) then return end

						print("Charging " .. Ply:Nick() .. " for " .. Cost)

						local CanAfford = Dupe[1].Player:ChargeRequisition(Cost, "Cost of dupe")

						if not CanAfford then
							aasMsg({Colors.ErrorCol, "You can't afford this dupe!"}, Ply)
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