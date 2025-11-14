AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

sound.Add({
	name	= "respkg_expire",
	channel	= CHAN_STATIC,
	volume	= 1.0,
	level	= 80,
	pitch	= 100,
	sound	= "ambient/levels/citadel/zapper_warmup1.wav"
})

sound.Add({
	name	= "respkg_accepted",
	channel	= CHAN_STATIC,
	volume	= 1.0,
	level	= 80,
	pitch	= 100,
	sound	= "buttons/button5.wav"
})

function ENT:Expire()
	self:AddEFlags(EFL_NO_THINK_FUNCTION)
	self.Dissolving = true
	self:Dissolve(0, 1, self:OBBCenter())
end

function ENT:Initialize()
	local Amt = self:GetResource()
	local Mass	= 75

	if Amt <= 75 then
		self:SetModel("models/props_junk/cardboard_box002b.mdl")
	elseif Amt <= 250 then
		self:SetModel("models/props_junk/wood_crate001a.mdl")
		Mass	= 250
	else
		self:SetModel("models/props_junk/wood_crate002a.mdl")
		Mass	= 500
	end

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	if self.CPPISetOwnerless then
		self:CPPISetOwnerless(true)
	else
		self.CPPIOwner	= game.GetWorld()
		self.SPPOwner	= game.GetWorld()
	end

	local po = self:GetPhysicsObject()

	self.Dissolving = false

	if IsValid(po) then
		po:SetMass(Mass)
	end
end

function ENT:SetTotalLife(Time)
	self:SetMaxLife(Time)
	self:SetLife(CurTime() + Time)
end

-- Special function that ACF will check, usually has DmgResult and DmgInfo passed, but we are just flat denying any damage
function ENT:ACF_PreDamage() return false end

function ENT:Use(activator, caller) -- activator and caller are usually the same, except for proxies (wire_user)
	if self.Dissolving then return end

	if activator ~= caller then aasMsg({Color(255, 0, 0), "You aren't allowed to remotely use this!"}, activator) return end

	if AAS.Funcs.EntInPlayerSafezone(self, activator) then
		for _, ply in ipairs(team.GetPlayers(activator:Team())) do
			ply:PayRequisition(self:GetResource())
		end

		self:EmitSound("respkg_accepted")
		self:Expire()
	end

end

function ENT:Think()
	if AAS.State.Active == false then self:NextThink(CurTime() + 5) return true end

	self:NextThink(CurTime() + 1)

	if self:GetLife() <= CurTime() then self:EmitSound("respkg_expire") self:Expire() end

	return true
end