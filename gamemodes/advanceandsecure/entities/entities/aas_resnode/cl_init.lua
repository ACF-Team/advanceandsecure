include("shared.lua")
ENT.AutomaticFrameAdvance = true

sound.Add({
	name	= "resnode_loop",
	channel	= CHAN_STATIC,
	volume	= 0.85,
	level	= 70,
	pitch	= 100,
	sound	= "ambient/levels/citadel/extract_loop1.wav"
})

local function InRange(ent, pos)
	local entPos = ent:GetPos()
	return (entPos:Distance2DSqr(pos) < AAS.CapRange) and (pos.z > (entPos.z - 128)) and (pos.z < (entPos.z + 128))
end

function ENT:Initialize()
	local selftbl = self:GetTable()
	selftbl.vm			= Matrix()
	selftbl.vma			= Angle(0, 0, 0)
	selftbl.vmv			= Vector(0, 0, 0)
	selftbl.a			= 0

	selftbl.LastSvThink		= CurTime()
	selftbl.LastResource	= 0

	selftbl.interpFull	= 1

	selftbl.LoopSound	= CreateSound(self, "resnode_loop")

	self:PhysicsInitStatic(SOLID_VPHYSICS)
end

local sndDist	= 1024 ^ 2
function ENT:Think()
	if self:GetResource() ~= self.LastResource then self.LastResource = self:GetResource() self.LastSvThink = CurTime() end

	local sndobj		= self.LoopSound
	local ShouldPlay	= (self:GetPos():DistToSqr(EyePos()) < sndDist) and (self:GetResource() < self:GetResourceMax())

	if sndobj:IsPlaying() ~= ShouldPlay then
		if ShouldPlay then self.LoopSound:Play() else self.LoopSound:Stop() end
	end

	self:SetNextClientThink(CurTime() + 0.5)
	return true
end

local cyan	= Color(0, 127, 255)
local softred	= Color(255, 127, 127)
local red	= Color(255, 65, 65)
function ENT:Draw()
	local selftbl = self:GetTable()

	selftbl.a = selftbl.a + FrameTime() * 24
	if selftbl.a > 360 then selftbl.a = selftbl.a - 360 end
	selftbl.vma.r = selftbl.a
	selftbl.vmv.x = TimedCos(0.2, 0, 2, 0)

	selftbl.vm:SetTranslation(selftbl.vmv)
	selftbl.vm:SetAngles(selftbl.vma)

	self:DrawModel()
	self:EnableMatrix("RenderMultiply", selftbl.vm)

	local Full = self:GetResource() == self:GetResourceMax()
	selftbl.interpFull	= math.max(Lerp(RealFrameTime() * 2, selftbl.interpFull, Full and 0 or 1), Full and 0 or 1)

	render.SetColorMaterial()

	render.OverrideDepthEnable(true, true)
		render.DrawSphere(self:LocalToWorld(Vector(-56, 0, 0)), 8 + TimedCos(2, 0, 1, 1), 6, 8, cyan:Lerp(red, 1 - selftbl.interpFull))

		render.DrawBeam(self:LocalToWorld(Vector(-56, 0, 0)), self:LocalToWorld(Vector(Lerp(selftbl.interpFull, -56, -120), 0, 0)), 6, 0, 1, cyan:Lerp(red, 1 - selftbl.interpFull))
		if not Full then render.DrawSphere(self:LocalToWorld(Vector(-120 + math.abs((CurTime() - self.LastSvThink) % 5 * -64) / 5, 0, 0)), 5, 6, 6, color_white) end
	render.OverrideDepthEnable(false, false)

	local Pos = self:GetPos()
	local EP = EyePos()
	if InRange(self, EP) then
		local LP	= LocalPlayer()
		if (not IsValid(LP)) or (LP == NULL) then return end
		local UseText	= string.upper(input.LookupBinding("+use"))
		local Mag = math.min(1, self:GetResource() / self:GetResourceMax())

		local Dir2Player	= ((EP - Pos) * Vector(1, 1, 0)):GetNormalized()

		cam.Start3D2D((Dir2Player * 30) + Vector(Pos.x, Pos.y, EP.z + TimedCos(0.2, 0, 1, 0)), Dir2Player:Angle() + Angle(0, 90, 90), 0.05)
			draw.NoTexture()
			surface.SetDrawColor(color_black)

			draw.RoundedBox(8, -160, -90, 320, 50, color_black)
			draw.RoundedBox(8, -158, -88, 316 * Mag, 46, cyan)

			draw.SimpleTextOutlined(tostring(self:GetResource()), "BasicFontExtraLarge", 0, -65, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)

			draw.SimpleTextOutlined("Resource Node", "BasicFontExtraLarge", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)

			if IsValid(self:GetNW2Entity("package", nil)) then
				draw.SimpleTextOutlined("A package currently exists, go find it!", "BasicFontExtraLarge", 0, 64, softred, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
			elseif self:GetResource() >= math.ceil(self:GetResourceMax() / 4) then
				draw.SimpleTextOutlined("Press " .. UseText .. " to collect a package", "BasicFontExtraLarge", 0, 64, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, color_black)
			end
		cam.End3D2D()
	end
end