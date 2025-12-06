local PANEL	= {}

AccessorFunc(PANEL, "selected", "Selected", FORCE_BOOL)
AccessorFunc(PANEL, "count", "Count", FORCE_NUMBER)

local NoMap	= Material("materials/gui/noicon.png", "")

local baseColor	= Color(65, 65, 65)
local selectColor	= Color(65, 255, 65)
local white		= Color(255, 255, 255)
local transparentgray	= Color(65, 65, 65, 127)

--[[

	At the core this is still a button, but we need to convey a fair bit of information through it

	At the top of the button should be the map name
	At the bottom of the button should be the mode for that particular map (AAS, RAAS, DW, etc)

	At the center should be an icon for the map, and when the button is hovered over, slide transition up to show a stored PNG of a map scan, usually only available if the player has been there before on AAS

]]

function PANEL:Init()
	self.map		= "NIL"
	self.mode		= "NIL"
	self.selected	= false	-- Whether or not the local player has selected this map
	self.count		= 0		-- Number to display current votes for the map
	self.iconMat	= NoMap	-- Materials for icon/map scan
	self.mapMat		= NoMap

	self.lerp		= 0	-- Lerp value for slide transition

	self:SetText("")
end

function PANEL:SetMap(map, mode)
	self.map	= map
	self.mode	= mode

	self:InvalidateLayout()
end

function PANEL:Paint(w, h)
	self.lerp	= Lerp(0.1, self.lerp, self:IsHovered() and 100 or 0)

	draw.NoTexture()
	render.SetColorMaterial()
	surface.SetDrawColor(baseColor)
	surface.DrawRect(0, 0, w, h)

	render.SetColorMaterial()
	surface.SetDrawColor(white)
	surface.SetMaterial(self.iconMat)
	surface.DrawTexturedRect(0, (h / 2) - (w / 2) + (-w * (self.lerp / 100)), w, w)

	surface.SetMaterial(self.mapMat)
	surface.DrawTexturedRect(0, (h / 2) - (-w / 2) + (-w * (self.lerp / 100)), w, w)

	render.SetColorMaterial()

	if self:GetSelected() then
		local clip	= DisableClipping(true)

		surface.SetDrawColor(selectColor)
		surface.DrawOutlinedRect(0, 0, w, h, -2)

		DisableClipping(clip)
	end

	surface.SetDrawColor(transparentgray)
	surface.DrawRect(0, 0, w, 16)
	draw.SimpleTextOutlined(self.map, "BasicFontLarge", w / 2, 8, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	surface.DrawRect(0, h - 16, w, 16)
	draw.SimpleTextOutlined(self.mode, "BasicFontLarge", w / 2, h - 8, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)

end

function PANEL:PerformLayout()
	local gamepath = file.Exists("maps/thumb/" .. self.map .. ".png", "GAME")
	local workshoppath = file.Exists("maps/thumb/" .. self.map .. ".png", "WORKSHOP")
	-- The icon of the map, as seen in the browser
	if gamepath or workshoppath then
		self.iconMat	= Material("maps/thumb/" .. self.map .. ".png", "")
	else
		self.iconMat	= NoMap
	end

	local pngPath	= file.Exists("data/aas/pngs/" .. self.map .. ".png", "GAME")
	-- The scan of the map turned into a .png, as obtained from an AAS server if a player has been on that map before
	if pngPath then
		self.mapMat	= Material("data/aas/pngs/" .. self.map .. ".png", "")
	else
		self.mapMat	= NoMap
	end


end

derma.DefineControl("VoteButton", "AAS Vote Button", PANEL, "DButton")