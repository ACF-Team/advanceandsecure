AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

sound.Add({
	name	= "resnode_deploy",
	channel	= CHAN_ITEM,
	volume	= 1.0,
	level	= 80,
	pitch	= 100,
	sound	= "items/suitchargeok1.wav"
})

sound.Add({
	name	= "resnode_extract",
	channel	= CHAN_STATIC,
	volume	= 1,
	level	= 80,
	pitch	= 100,
	sound	= "ambient/levels/citadel/pod_close1.wav"
})

function ENT:Initialize()
	self:SetModel("models/props_combine/headcrabcannister01a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetUseType(SIMPLE_USE)

	self:SetAngles(Angle(-90, 0, 0))

	if self.CPPISetOwnerless then
		self:CPPISetOwnerless(true)
	else
		self.CPPIOwner	= game.GetWorld()
		self.SPPOwner	= game.GetWorld()
	end

	self:NextThink(CurTime() + 5)
end

-- These should -always- exist on the client
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

-- Special function that ACF will check, usually has DmgResult and DmgInfo passed, but we are just flat denying any damage
function ENT:ACF_PreDamage() return false end

function ENT:Use(activator,caller) -- activator and caller are usually the same, except for proxies (wire_user)
	if activator ~= caller then aasMsg({Color(255,0,0),"You aren't allowed to remotely use this!"}, activator) return end

	-- When allowed to (minimum time from the last time a package was spawned? or maybe minimum amount of resource required to spawn) create a package with the resources in it that must be carried back to base

	if IsValid(self:GetNW2Entity("package", nil)) then
		aasMsg({Color(255,0,0),"There is still a package, go find it!"}, activator)

		return
	end

	if self:GetResource() >= math.ceil(self:GetResourceMax() / 4) then
		local Package = ents.Create("aas_respkg")
		Package:SetPos(self:GetPos() + Vector(0, 0, 12))

		Package:SetResource(self:GetResource())
		Package:SetLife(CurTime() + 180)

		Package:Spawn()
		Package:DropToFloor()
		Package:PhysWake()

		self:EmitSound("resnode_deploy")
		self:SetResource(0)
		self:SetNW2Entity("package", Package)

		self:NextThink(CurTime() + 5)
	else
		aasMsg({Color(255,0,0),"This node is not ready yet! A minimum of " .. math.ceil(self:GetResourceMax() / 4) .. " is required to spawn a package."}, activator)
	end
end

function ENT:Think()
	--if AAS.State.Active == false then self:NextThink(CurTime() + 5) return true end

	if self:GetResource() < self:GetResourceMax() then self:EmitSound("resnode_extract") end

	self:SetResource(math.min(self:GetResource() + self:GetResourceInt(), self:GetResourceMax()))

	self:NextThink(CurTime() + 5)
	return true
end

function ENT:OnRemove()
	if self.LoopID then self:StopLoopingSound(self.LoopID) end
end