MsgN("+ Scoreboard loaded")

local PlyColor = Color(0,200,0)
local PlyColorHovered	= PlyColor:Lerp(Color(255, 127, 0), 0.5)

local BaseColor	= Color(65, 65, 65)
local HoverColor	= Color(255, 127, 0)

local Red	= Color(255, 0, 0)
local Green	= Color(0, 255, 0)

local nodeColor	= Color(200, 200, 200)

local SW,SH = ScrW(),ScrH()
local UU = ((SW > SH) and SH or SW) / 12

local function localizeToPanel(Vec3, Panel, Limit, Margin)
	local w, h		= Panel:GetSize()

	local Pos	= {
		x = ((Vec3.x / 16384) * (w / 2)) + (w / 2),
		y = ((-Vec3.y / 16384) * (h / 2)) + (h / 2)
	}

	if not Limit then return Pos end
	if not IsValid(Panel:GetParent()) then return Pos end

	local Parent	= Panel:GetParent()
	local nMargin	= Margin or 0

	local pw, ph	= Panel:GetParent():GetSize()

	local ScreenPos			= {Panel:LocalToScreen(Pos.x, Pos.y)}
	local min,max			= {Parent:LocalToScreen(nMargin, nMargin)}, {Parent:LocalToScreen(pw - nMargin, ph - nMargin)}
	if (ScreenPos[1] < min[1]) or (ScreenPos[1] > max[1]) or (ScreenPos[2] < min[2]) or (ScreenPos[2] > max[2]) then
		local LocPos	= {Panel:ScreenToLocal(
			math.Clamp(ScreenPos[1], min[1], max[1]),
			math.Clamp(ScreenPos[2], min[2], max[2])
		)}

		return {x = LocPos[1], y = LocPos[2]}
	else
		return Pos
	end
end

scoreboard = scoreboard or {}
scoreboard.visible	= false

function scoreboard:show()
	if scoreboard.frame then scoreboard.frame:Remove() end
	local LP = LocalPlayer()
	if (not IsValid(LP)) or (LP == NULL) then return end
	local TN	= LP:Team()
	local TC	= team.GetColor(TN)
	local TC2	= team.GetColor(TN == 1 and 2 or 1)
	scoreboard.visible	= true

	local frame = vgui.Create("Panel")
	scoreboard.frame	= frame
	frame:SetSize(SW, SH)
	frame:CenterVertical(-0.5)
	frame:CenterHorizontal(0.5)
	frame:NoClipping(true)
	frame.Paint	= function(panel, w, h)
		surface.SetDrawColor(Color(0, 0, 0, 96))
		surface.DrawRect(0, 0, w, h)
	end

	frame:MoveTo((SW / 2) - (frame:GetWide() / 2), (SH / 2) - (frame:GetTall() / 2), 0.1, 0, -1, function(_, pnl) pnl:MakePopup() pnl:SetKeyboardInputEnabled(false) end)

	function scoreboard:hide()
		if scoreboard.visible == false then return end

		scoreboard.visible = false
		frame:SetMouseInputEnabled(false)
		frame:MoveTo((SW / 2) - (frame:GetWide() / 2), SH, 0.1, 0, -1, function(_, pnl) pnl:Remove() end)
		CloseDermaMenus()
	end

	local map	= vgui.Create("MapPanel", frame)
	scoreboard.map	= map
	local mapcanvas = map:GetCanvas()
	map:SetSize(UU * 9, UU * 9)
	map:AlignTop(UU * 1)
	map:AlignLeft(UU * 0.5)

	local info	= vgui.Create("DPanel", frame)
	info:SetSize(UU * 9, UU * 0.5)
	info:SetPos(map:GetX(), map:GetY() + (UU * 9.25))

	info.Paint	= function(panel, w, h)
		surface.SetDrawColor(65, 65, 65)
		surface.DrawRect(0, 0, w, h)

		local clip = DisableClipping(true)
			surface.SetDrawColor(TC)
			surface.DrawOutlinedRect(0, 0, w, h, -4)
		DisableClipping(clip)

		if not AAS.State.Mode then return end
		draw.SimpleTextOutlined(AAS.State.Mode.name, "BasicFontLarge", UU * 0.25, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, color_black)
		draw.SimpleTextOutlined(AAS.State.Mode.desc, "BasicFont14", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)

		draw.SimpleTextOutlined(game.GetMap(), "BasicFontLarge", w - UU * 0.25, h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, color_black)
	end

	local teampanel	= vgui.Create("DPanel", frame)
	teampanel:SetSize(UU * 9, UU * 9)
	teampanel:AlignTop(UU * 1)
	teampanel:AlignRight(UU * 0.5)
	teampanel.Paint	= function(panel, w, h)
		draw.RoundedBox(12, 0, 0, w, h, Color(65, 65, 65, 127))
	end

	do	-- Team A
		local teamA	= vgui.Create("DPanel", teampanel)
		teamA:SetSize((UU * 4.5) - 10, UU * 8)
		teamA:DockMargin(4, 4, 4, 4)
		teamA:Dock(LEFT)
		teamA.team	= TN
		teamA.Paint	= function(panel, w, h)
			draw.RoundedBox(12, 0, 0, w, h, team.GetColor(panel.team))
		end

		local teamAInfo	= vgui.Create("DPanel", teamA)
		teamAInfo:SetSize(12, UU * 0.5)
		teamAInfo:DockMargin(4, 4, 4, 4)
		teamAInfo:Dock(TOP)
		teamAInfo.name	= AAS.Funcs.GetTeamInfo(teamA.team).Name
		teamAInfo.Paint	= function(panel, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(65, 65, 65))

			draw.SimpleText(panel.name, "BasicFontLarge", w / 2, h / 4, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			draw.SimpleText("Player", "BasicFont14", 60, h - 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("Ping", "BasicFont14", w - 12, h - 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("Level", "BasicFont14", w - 60, h - 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

			draw.SimpleText("Kills", "BasicFont14", w - 208, h - 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("Deaths", "BasicFont14", w - 192, h - 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		end

		local teamAList	= vgui.Create("DScrollPanel", teamA)
		teamAList:DockMargin(4, 0, 4, 4)
		teamAList:Dock(FILL)
		teamAList.SetupTeam		= function(panel)
			local teamindex	= panel:GetParent().team
			panel:Clear()

			for _, ply in ipairs(team.GetPlayers(teamindex)) do
				local p2 = panel:Add("DButton")
				p2:SetSize(12, 48)
				p2:DockMargin(4, 4, 4, 0)
				p2:Dock(TOP)
				p2:SetText("")
				p2.player	= ply
				p2.h		= 0

				p2.Paint	= function(panel2, w, h)
					if (not IsValid(panel2.player)) or (panel2.player == NULL) then panel2:Remove() return end

					local panelply	= panel2.player

					draw.RoundedBox(8, 0, 0, w, h, Color(96, 96, 96))
					panel2.h	= Lerp(0.1, panel2.h, panel2:IsHovered() and 100 or 0)
					if panel2.h > 4 then draw.RoundedBox(6, 4, 4, (w * (panel2.h / 100)) - 8, h - 8, BaseColor:Lerp(HoverColor, panel2.h / 100)) end

					surface.SetDrawColor(96, 96, 96)

					draw.SimpleText(panelply:Nick(), "BasicFontLarge", 60, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

					local ping = panelply:Ping()
					draw.SimpleText(tostring(ping), "BasicFont14", w - 8, h / 2, Green:Lerp(Red, math.Clamp(ping - 50, 0, 200) / 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

					draw.SimpleText(panelply:GetNW2Int("AAS.Level", 0), "BasicFont14", w - 56, h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

					draw.SimpleText(tostring(panelply:Frags()), "BasicFont14", w - 204, h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
					draw.SimpleText(tostring(panelply:Deaths()), "BasicFont14", w - 188, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				end

				local icon	= vgui.Create("AvatarImage", p2)
				icon:SetSize(48, 48)
				icon:Dock(LEFT)
				icon:SetPlayer(ply, 64)

				if ply:IsPlayer() and not ply:IsBot() then
					local iconbtn	= vgui.Create("DButton", icon)
					iconbtn:Dock(FILL)
					iconbtn.Paint	= function() end
					iconbtn:SetText("")

					iconbtn.player	= ply
					iconbtn.DoClick	= function(panel2)
						if IsValid(panel2.player) and (panel2.player ~= NULL) then
							panel2.player:ShowProfile()
						end
					end
				end

				p2.DoClick	= function(panel2)
					local Menu	= DermaMenu()

					if ply:Team() == TN then
						Menu:AddOption("Find on map", function()
							if IsValid(ply) and (ply ~= NULL) and map.plymarkers[ply] and (map.plymarkers[ply] ~= NULL) then
								mapcanvas:StartTrack(map.plymarkers[ply])
							end
						end)
					end

					if ply:IsPlayer() and not ply:IsBot() then
						Menu:AddOption("Copy SteamID", function() if IsValid(ply) and (ply ~= NULL) then SetClipboardText(ply:SteamID()) end end)
					end

					Menu:Open()
				end

				p2.DoRightClick	= p2.DoClick
			end
		end

		teamAList.Paint	= function(panel, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(65, 65, 65))
		end

		teamAList:SetupTeam()
	end

	do	-- Team B
		local teamB	= vgui.Create("DPanel", teampanel)
		teamB:SetSize((UU * 4.5) - 10, UU * 8)
		teamB:DockMargin(4, 4, 4, 4)
		teamB:Dock(RIGHT)
		teamB.team	= TN == 1 and 2 or 1
		teamB.Paint	= function(panel, w, h)
			draw.RoundedBox(12, 0, 0, w, h, team.GetColor(panel.team))
		end

		local teamBInfo	= vgui.Create("DPanel", teamB)
		teamBInfo:SetSize(12, UU * 0.5)
		teamBInfo:DockMargin(4, 4, 4, 4)
		teamBInfo:Dock(TOP)
		teamBInfo.name	= AAS.Funcs.GetTeamInfo(teamB.team).Name
		teamBInfo.Paint	= function(panel, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(65, 65, 65))

			draw.SimpleText(panel.name, "BasicFontLarge", w / 2, h / 4, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			draw.SimpleText("Player", "BasicFont14", 60, h - 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("Ping", "BasicFont14", w - 12, h - 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("Level", "BasicFont14", w - 60, h - 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

			draw.SimpleText("Kills", "BasicFont14", w - 208, h - 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("Deaths", "BasicFont14", w - 192, h - 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		end

		local teamBList	= vgui.Create("DScrollPanel", teamB)
		teamBList:DockMargin(4, 0, 4, 4)
		teamBList:Dock(FILL)
		teamBList.SetupTeam		= function(panel)
			local teamindex	= panel:GetParent().team
			panel:Clear()

			for _, ply in ipairs(team.GetPlayers(teamindex)) do
				local p2 = panel:Add("DButton")
				p2:SetSize(12, 48)
				p2:DockMargin(4, 4, 4, 0)
				p2:Dock(TOP)
				p2:SetText("")
				p2.player	= ply
				p2.h		= 0

				p2.Paint	= function(panel2, w, h)
					if (not IsValid(panel2.player)) or (panel2.player == NULL) then panel2:Remove() return end

					local panelply	= panel2.player

					draw.RoundedBox(8, 0, 0, w, h, Color(96, 96, 96))
					panel2.h	= Lerp(0.1, panel2.h, panel2:IsHovered() and 100 or 0)
					if panel2.h > 4 then draw.RoundedBox(6, 4, 4, (w * (panel2.h / 100)) - 8, h - 8, BaseColor:Lerp(HoverColor, panel2.h / 100)) end

					surface.SetDrawColor(96, 96, 96)

					draw.SimpleText(panelply:Nick(), "BasicFontLarge", 60, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

					local ping = panelply:Ping()
					draw.SimpleText(tostring(ping), "BasicFont14", w - 8, h / 2, Green:Lerp(Red, math.Clamp(ping - 50, 0, 200) / 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

					draw.SimpleText(panelply:GetNW2Int("AAS.Level", 0), "BasicFont14", w - 56, h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

					draw.SimpleText(tostring(panelply:Frags()), "BasicFont14", w - 204, h / 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
					draw.SimpleText(tostring(panelply:Deaths()), "BasicFont14", w - 188, h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				end

				local icon	= vgui.Create("AvatarImage", p2)
				icon:SetSize(48, 48)
				icon:Dock(LEFT)
				icon:SetPlayer(ply, 64)

				if ply:IsPlayer() and not ply:IsBot() then
					local iconbtn	= vgui.Create("DButton", icon)
					iconbtn:Dock(FILL)
					iconbtn.Paint	= function() end
					iconbtn:SetText("")

					iconbtn.player	= ply
					iconbtn.DoClick	= function(panel2)
						if IsValid(panel2.player) and (panel2.player ~= NULL) then
							panel2.player:ShowProfile()
						end
					end
				end

				p2.DoClick	= function(panel2)
					local Menu	= DermaMenu()

					if ply:Team() == TN then
						Menu:AddOption("Find on map", function()
							if IsValid(ply) and (ply ~= NULL) and map.plymarkers[ply] and (map.plymarkers[ply] ~= NULL) then
								mapcanvas:StartTrack(map.plymarkers[ply])
							end
						end)
					end

					if ply:IsPlayer() and not ply:IsBot() then
						Menu:AddOption("Copy SteamID", function() if IsValid(ply) and (ply ~= NULL) then SetClipboardText(ply:SteamID()) end end)
					end

					Menu:Open()
				end

				p2.DoRightClick	= p2.DoClick
			end
		end

		teamBList.Paint	= function(panel, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(65, 65, 65))
		end

		teamBList:SetupTeam()
	end

	local buttonPanel	= vgui.Create("DPanel", frame)
	buttonPanel:SetSize(UU * 9, UU * 0.5)
	buttonPanel:SetPos(teampanel:GetX(), teampanel:GetY() + (UU * 9.25))
	buttonPanel.Paint	= function(panel, w, h)
		surface.SetDrawColor(65, 65, 65)
		surface.DrawRect(0, 0, w, h)

		local clip	= DisableClipping(true)
			surface.SetDrawColor(TC)
			surface.DrawOutlinedRect(0, 0, w, h, -4)
		DisableClipping(clip)
	end

	do	-- Buttons
		local switchTeam	= vgui.Create("DButton", buttonPanel)
		switchTeam:SetText("")
		switchTeam:SetSize(UU * 3, UU * 0.5)
		switchTeam:DockMargin(4, 4, 4, 4)
		switchTeam.h	= 0
		switchTeam.Paint	= function(panel, w, h)
			draw.RoundedBoxEx(8, 0, 0, w / 2, h, TC, true, false, true, false)
			draw.RoundedBoxEx(8, w / 2, 0, w / 2, h, TC2, false, true, false, true)

			panel.h	= Lerp(0.1, panel.h, panel:IsHovered() and 100 or 0)
			draw.RoundedBox(4, 4, 4, w - 8, h - 8, BaseColor:Lerp(HoverColor, panel.h / 100))

			draw.SimpleTextOutlined("Switch Team", "BasicFontLarge", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		end
		switchTeam.DoClick	= function(panel)
			scoreboard:hide()

			net.Start("AAS.RequestTeamSwap")
			net.SendToServer()
		end

		local requestDupes	= vgui.Create("DButton", buttonPanel)
		requestDupes:SetText("")
		requestDupes:SetSize(UU * 3, UU * 0.5)
		requestDupes:DockMargin(4, 4, 0, 4)
		requestDupes.h	= 0
		requestDupes.Paint	= function(panel, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(127, 255, 255))

			panel.h	= Lerp(0.1, panel.h, panel:IsHovered() and 100 or 0)
			draw.RoundedBox(4, 4, 4, w - 8, h - 8, BaseColor:Lerp(HoverColor, panel.h / 100))

			draw.SimpleTextOutlined("Request Dupe List", "BasicFontLarge", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		end
		requestDupes.DoClick	= function(panel)
			scoreboard:hide()

			if AdvDupe2 then
				net.Start("AAS.RequestDupeList")
				net.SendToServer()
			else
				chat.AddText(Color(255,0,0),"AdvDupe2 is not available!")
			end
		end

		local requestCostScript	= vgui.Create("DButton", buttonPanel)
		requestCostScript:SetText("")
		requestCostScript:SetSize(UU * 3, UU * 0.5)
		requestCostScript:DockMargin(0, 4, 4, 4)
		requestCostScript.h	= 0
		requestCostScript.Paint	= function(panel, w, h)
			draw.RoundedBox(8, 0, 0, w, h, Color(255, 255, 127))

			panel.h	= Lerp(0.1, panel.h, panel:IsHovered() and 100 or 0)
			draw.RoundedBox(4, 4, 4, w - 8, h - 8, BaseColor:Lerp(HoverColor, panel.h / 100))

			draw.SimpleTextOutlined("Request Cost Script", "BasicFontLarge", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		end
		requestCostScript.DoClick	= function(panel)
			scoreboard:hide()

			net.Start("AAS.RequestCostScript")
			net.SendToServer()
		end

		requestDupes:Dock(LEFT)
		requestCostScript:Dock(RIGHT)
		switchTeam:Dock(FILL)
	end

	map.plymarkers	= {}
	for _, ply in ipairs(team.GetPlayers(TN)) do
		if (not IsValid(ply)) or (ply == NULL) then continue end

		local plymarker	= vgui.Create("DButton", mapcanvas)
		plymarker.player	= ply
		if ply == LocalPlayer() then
			mapcanvas:StartTrack(plymarker)
			plymarker:SetMouseInputEnabled(false)
		end

		map.plymarkers[ply]	= plymarker

		plymarker:SetText("")
		plymarker:NoClipping(true)

		plymarker:SetSize(UU * 0.15, UU * 0.15)
		plymarker.Paint	= function(panel, w, h)
			if not plymarker.arrow then return end
			draw.NoTexture()
			render.SetColorMaterial()
			local markply	= plymarker.player

			if panel:IsHovered() and (markply ~= LocalPlayer()) then
				surface.SetDrawColor(PlyColorHovered)
			else
				surface.SetDrawColor(PlyColor)
			end

			local arrow = plymarker.arrow
			surface.DrawPoly(arrow)

			surface.SetDrawColor(color_black)
			surface.DrawLine(arrow[1].x, arrow[1].y, arrow[2].x, arrow[2].y)
			surface.DrawLine(arrow[1].x, arrow[1].y, arrow[4].x, arrow[4].y)

			draw.SimpleTextOutlined(markply:Nick(), "BasicFont14", w / 2, -UU * 0.1, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		end

		plymarker.Think	= function(panel)
			if (not IsValid(panel.player)) or (panel.player == NULL) then panel:Remove() return end
			local markply	= panel.player

			local w, h	= panel:GetSize()
			local pos = localizeToPanel(markply:GetPos(), mapcanvas, true, w / 2)
			panel:SetPos(pos.x - (w / 2), pos.y - (h / 2))

			local yaw	= -markply:EyeAngles().yaw
			local R1	= math.rad(yaw)
			local RC	= math.rad(yaw + 180)
			local R2	= math.rad(yaw + 140)
			local R3	= math.rad(yaw - 140)

			local s		= w * 0.75
			plymarker.arrow = {
				{x = (math.cos(R1) * s) + (w / 2), y = (math.sin(R1) * s) + (h / 2)},
				{x = (math.cos(R2) * s) + (w / 2), y = (math.sin(R2) * s) + (h / 2)},
				{x = (math.cos(RC) * s * 0.5) + (w / 2), y = (math.sin(RC) * s * 0.5) + (h / 2)},
				{x = (math.cos(R3) * s) + (w / 2), y = (math.sin(R3) * s) + (h / 2)}
			}
		end

		if ply ~= LocalPlayer() then
			plymarker.DoClick	= function(panel)
				local markply	= plymarker.player
				if (not IsValid(markply)) or (markply == NULL) then return end

				local plyname	= markply:Nick()
				local Menu		= DermaMenu()

				Menu:AddOption("Track", function() mapcanvas:StartTrack(panel) end)
				Menu:AddOption("Catch a ride!", function() RunConsoleCommand("say_team","Hey " .. plyname .. ", let me come with you!") end)
				Menu:AddOption("Follow me!", function() RunConsoleCommand("say_team","Hey " .. plyname .. ", follow me!") end)

				Menu:Open()
			end
			plymarker.DoRightClick	= plymarker.DoClick

		end
	end

	for _, point in ipairs(ents.FindByClass("aas_point")) do
		if (not IsValid(point)) or (point == NULL) then continue end

		local pointmarker	= vgui.Create("DButton", mapcanvas)
		pointmarker.point	= point
		pointmarker.name	= point:GetPointName()
		pointmarker:SetText("")
		pointmarker:NoClipping(true)

		pointmarker:SetSize(UU * 0.2, UU * 0.2)

		pointmarker.Paint	= function(panel, w, h)
			if (not IsValid(panel.point)) or (panel.point == NULL) then panel:Remove() return end
			local markpoint	= panel.point

			if not panel.inner then return end

			draw.NoTexture()
			render.SetColorMaterial()

			surface.SetDrawColor(color_black)
			surface.DrawPoly(panel.outer)
			surface.SetDrawColor(markpoint:GetCapColor())
			surface.DrawPoly(panel.inner)

			draw.SimpleTextOutlined(panel.name, "BasicFont14", w / 2, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
		end

		pointmarker.Think	= function(panel)
			if (not IsValid(panel.point)) or (panel.point == NULL) then panel:Remove() return end
			local markpoint	= panel.point

			local w, h	= panel:GetSize()
			local pos = localizeToPanel(markpoint:GetPos(), mapcanvas, true, w / 2)
			panel:SetPos(pos.x - (w / 2), pos.y - (h / 2))
		end

		pointmarker.ApplySchemeSettings	= function(panel)
			local InnerPoly, OuterPoly	= {}, {}

			local w,h	= panel:GetSize()

			for I = 1,6 do
				local Ang = math.rad(60 * I)
				InnerPoly[I] = {x = (math.cos(Ang) * 0.8 * (w / 2)) + (w / 2), y = (math.sin(Ang) * 0.8 * (h / 2)) + (h / 2)}
				OuterPoly[I] = {x = (math.cos(Ang) * (w / 2)) + (w / 2), y = (math.sin(Ang) * (h / 2)) + (h / 2)}
			end

			pointmarker.inner	= InnerPoly
			pointmarker.outer	= OuterPoly

			if (not IsValid(pointmarker.point)) or (pointmarker.point == NULL) then return end

			if AAS.LocalAlias[pointmarker.point:GetPointName()] then
				pointmarker.name	= AAS.LocalAlias[pointmarker.point:GetPointName()] .. " Spawn"
			end
		end

		if point:GetIsSpawn() then
			pointmarker:SetMouseInputEnabled(false)
		else
			pointmarker.DoClick	= function(panel)
				if (not IsValid(panel.point)) or (panel.point == NULL) then panel:Remove() return end

				if CapStatus(v) == LP:Team() then
					RunConsoleCommand("say_team","Defend the " .. panel.name .. " point!")
				else
					RunConsoleCommand("say_team","Attack the " .. panel.name .. " point!")
				end
			end
		end
	end

	for _, node in ipairs(ents.FindByClass("aas_resnode")) do
		if (not IsValid(node)) or (node == NULL) then continue end

		local nodemarker	= vgui.Create("DPanel", mapcanvas)
		nodemarker.node	= node
		nodemarker:SetText("")
		nodemarker:NoClipping(true)

		nodemarker:SetSize(UU * 0.2, UU * 0.2)

		nodemarker.Paint	= function(panel, w, h)
			if (not IsValid(panel.node)) or (panel.node == NULL) then panel:Remove() return end

			if not panel.inner then return end

			draw.NoTexture()
			render.SetColorMaterial()

			surface.SetDrawColor(color_black)
			surface.DrawPoly(panel.outer)
			surface.SetDrawColor(nodeColor)
			surface.DrawPoly(panel.inner)
		end

		nodemarker.Think	= function(panel)
			if (not IsValid(panel.node)) or (panel.node == NULL) then panel:Remove() return end
			local markpoint	= panel.node

			local w, h	= panel:GetSize()
			local pos = localizeToPanel(markpoint:GetPos(), mapcanvas, true, w / 2)
			panel:SetPos(pos.x - (w / 2), pos.y - (h / 2))
		end

		nodemarker.ApplySchemeSettings	= function(panel)
			local InnerPoly, OuterPoly	= {}, {}

			local w,h	= panel:GetSize()

			for I = 1,3 do
				local Ang = math.rad((120 * I) + 90)
				InnerPoly[I] = {x = (math.cos(Ang) * 0.7 * (w / 2)) + (w / 2), y = (math.sin(Ang) * 0.7 * (h / 2)) + (h / 2)}
				OuterPoly[I] = {x = (math.cos(Ang) * (w / 2)) + (w / 2), y = (math.sin(Ang) * (h / 2)) + (h / 2)}
			end

			nodemarker.inner	= InnerPoly
			nodemarker.outer	= OuterPoly

			if (not IsValid(nodemarker.node)) or (nodemarker.node == NULL) then return end
		end
	end
end

function GM:ScoreboardShow()
	scoreboard:show()
end

function GM:ScoreboardHide()
	scoreboard:hide()
end