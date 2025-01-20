ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Category = "Gamemode"
ENT.Author = "LiddulBOFH"
ENT.PrintName = "Resource Node"
ENT.Purpose = "A resource node for a gamemode"

ENT.DisableDuplicator = true
ENT.AdminOnly = true

ENT.Editable = true

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
	self:NetworkVar("Int", 0, "ResourceInt", {KeyName = "resourceint", Edit = {type = "Int", title = "Resource per interval", category = "Basic", order = 1, min = 1, max = 100}})
	self:NetworkVar("Int", 1, "ResourceMax", {KeyName = "resourcemax", Edit = {type = "Int", title = "Maximum held resources", category = "Basic", order = 2, min = 50, max = 1000}})
	self:NetworkVar("Int", 2, "Resource")

	-- Initial values that get set on first spawn, to be overridden by the server if loaded in
	if SERVER then
		self:SetResourceInt(25)
		self:SetResourceMax(250)
		self:SetResource(0)
	end
end