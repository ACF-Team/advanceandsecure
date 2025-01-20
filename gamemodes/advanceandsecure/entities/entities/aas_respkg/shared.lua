ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Category = "Gamemode"
ENT.Author = "LiddulBOFH"
ENT.PrintName = "Resource Package"
ENT.Purpose = "A resource package"

ENT.DisableDuplicator = true
ENT.AdminOnly = true

function ENT:CanTool(ply)
	return GetGlobalBool("EditMode",false)
end

function ENT:CanProperty(ply)
	return GetGlobalBool("EditMode",false)
end

function ENT:PhysgunPickup()
	return GetGlobalBool("EditMode",false)
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Resource")
	self:NetworkVar("Float", 0, "Life")
	self:NetworkVar("Float", 1, "MaxLife")

	-- Initial values that get set on first spawn, to be overridden by the server if loaded in
	if SERVER then
		self:SetResource(0)
		self:SetLife(CurTime() + 180)
		self:SetMaxLife(180)
	end
end