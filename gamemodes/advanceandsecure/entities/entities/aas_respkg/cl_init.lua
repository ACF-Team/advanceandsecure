include("shared.lua")

local Fidelity		= 16
local CircleScale	= 72
local RadSections	= 360 / Fidelity
local BaseColor		= Color(65, 65, 65)
local red			= Color(255, 65, 65)
local green			= Color(65, 255, 65)
local overlayDist	= 256 ^ 2
function ENT:Draw()
	self:DrawModel()
	self:DrawShadow()

	local Pos	= self:LocalToWorld(self:OBBCenter())
	local EP	= EyePos()

	if Pos:DistToSqr(EP) > overlayDist then return end

	if LocalPlayer():GetEyeTrace().Entity ~= self then return end

	local TimeLeft	= math.max(0, self:GetLife() - CurTime())
	local TimePerc	= TimeLeft / self:GetMaxLife()
	local WedgeFidelity	= math.ceil(Fidelity * TimePerc)

	draw.NoTexture()
	cam.Start2D()
		local Pos2D = Pos:ToScreen()

		local Poly	= {}
		for I = 1, Fidelity do
			local Ang = math.rad(RadSections * I)
			Poly[I] = {x = Pos2D.x + (math.cos(Ang) * CircleScale), y = Pos2D.y + (math.sin(Ang) * CircleScale)}
		end

		local Poly2	= {{x = Pos2D.x, y = Pos2D.y}}
		for I = 0, WedgeFidelity do
			local Ang = (math.rad((360 * TimePerc) * I) / WedgeFidelity) + math.rad(-90)
			table.insert(Poly2, {x = Pos2D.x + (math.cos(Ang) * CircleScale * 1.25), y = Pos2D.y + (math.sin(Ang) * CircleScale * 1.25)})
		end

		--draw.SimpleTextOutlined("fuck", "BasicFontExtraLarge", Pos2D.x, Pos2D.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		surface.SetDrawColor(red:Lerp(green, TimePerc ^ 1.2))
		if TimeLeft > 0 then surface.DrawPoly(Poly2) end

		surface.SetDrawColor(BaseColor)
		surface.DrawPoly(Poly)

		draw.SimpleTextOutlined(string.FormattedTime(TimeLeft, "%0i:%02i"), "BasicFontExtraLarge", Pos2D.x, Pos2D.y - 24, TimeLeft <= 30 and red or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		draw.SimpleTextOutlined(tostring(self:GetResource()), "BasicFontExtraLarge", Pos2D.x, Pos2D.y + 24, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	cam.End2D()
end