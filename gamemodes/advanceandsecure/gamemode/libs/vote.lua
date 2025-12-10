MsgN("+ Vote system loaded")

local CT = CurTime

if SERVER then
	AAS.Voting			= false
	AAS.RoundCounter	= 1
	team.SetScore(1, 0)
	team.SetScore(2, 0)

	local MapLookup		= {}
	local VoteData		= {}
	local QueueUpdate	= false
	local Counts		= {}

	local function UpdateVotes()
		Counts = {}
		for _, v in pairs(VoteData) do
			Counts[tostring(v)] = (Counts[tostring(v)] or 0) + 1
		end

		if not QueueUpdate then
			timer.Simple(0.2, function()
				net.Start("AAS.ReceiveVote")
					net.WriteTable(Counts)
				net.Broadcast()

				QueueUpdate = false
			end)

			QueueUpdate = true
		end
	end

	local Maps = {}
	local function OpenVotes()
		if table.IsEmpty(Maps) then
			local _, MapDirs = file.Find("aas/maps/*", "DATA")

			for _, map in pairs(MapDirs) do
				local files = file.Find("aas/maps/" .. map .. "/*.txt", "DATA")

				for _, f in pairs(files) do
					local fin = string.StripExtension(f)
					if (map == game.GetMap()) and (fin == AAS.ModeCV:GetString()) then continue end

					local index = map .. "/" .. fin
					table.insert(Maps, index)
					MapLookup[index]	= {map = map, mode = fin}
				end
			end

			if #Maps == 0 then AAS.Funcs.finishVote(-1) return end
		end

		AAS.Voting	= true
		QueueUpdate	= false
		SetGlobalBool("AAS.Voting", AAS.Voting)

		net.Start("AAS.OpenVotes")
			net.WriteFloat(CT() + 30)
			net.WriteTable(Maps)
		net.Broadcast()

		VoteData = {}

		UpdateVotes()

		timer.Simple(30, AAS.Funcs.countVotes)
	end
	AAS.Funcs.openVotes = OpenVotes

	local function FinishVote(Choice)
		if #Maps == 0 then Choice = -1 end

		if Choice == -1 then	-- Restart the map
			aasMsg({Colors.BasicCol, "Refreshing the map!"})

			AAS.Funcs.ScrambleTeams()

			AAS.Funcs.FullReload()

			return
		elseif Choice == -2 then	-- Pick a random since no votes were received
			Choice	= Maps[math.random(1, #Maps)]
		end

		local MapReturn = MapLookup[Choice]
		AAS.FirstLoad	= true
		AAS.ModeCV:SetString(MapReturn.mode)
		RunConsoleCommand("changelevel", MapReturn.map)
	end
	AAS.Funcs.finishVote = FinishVote

	local function CountVotes()
		AAS.Voting = false
		SetGlobalBool("AAS.Voting", AAS.Voting)

		aasMsg({Colors.BasicCol, "Counting votes!"})
		local FinalCount = {}

		if table.Count(VoteData) == 0 then
			AAS.Funcs.finishVote(-2)

			aasMsg({Colors.BasicCol, "No votes received, picking randomly!"})
			return
		end

		for _, v in pairs(VoteData) do
			FinalCount[v] = (FinalCount[v] or 0) + 1
		end

		local Highest = FinalCount[table.GetWinningKey(FinalCount)]
		local Ties = table.KeysFromValue(FinalCount, Highest)

		AAS.Funcs.finishVote(Ties[math.random(1, #Ties)])
	end
	AAS.Funcs.countVotes = CountVotes

	do
		do	-- Network

			-- Receives vote info and updates clients about that, otherwise will send a rude message to anyone thats trying to circumvent it
			net.Receive("AAS.ReceiveVote", function(_, ply)
				if not AAS.Voting then aasMsg({Colors.ErrorCol, "Bugger off"}, ply) return end
				local Choice = net.ReadString()

				VoteData[ply] = Choice

				UpdateVotes()
			end)
		end
	end

else	-- Cient
	local Choices		= {}
	local Time			= 0
	local VotePanel

	local function SendVote(choice)
		net.Start("AAS.ReceiveVote")
			net.WriteString(choice)
		net.SendToServer()
	end

	if VotePanel then VotePanel:Remove() end
	local function VoteMenu()
		if VotePanel then VotePanel:Remove() end

		timer.Simple(Time - CT(), function()
			if VotePanel then VotePanel:Remove() end
		end)

		VotePanel			= vgui.Create("DFrame")
		VotePanel.btnindex	= {}
		local sizew	= math.floor((ScrW() * 0.5) / 312)
		VotePanel:SetSize(312 * sizew, ScrH() * 0.75)
		VotePanel:Center()
		VotePanel:SetDraggable()
		VotePanel:ShowCloseButton(false)
		VotePanel:MakePopup()
		VotePanel:SetKeyboardInputEnabled(false)
		VotePanel:SetTitle("")

		VotePanel.Paint = function(_, w, h)
			surface.SetDrawColor(75, 75, 75)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(25, 25, 25)
			surface.DrawRect(0, 0, w, 24)

			local TimeLeft = math.Clamp(math.Round(Time - CT(), 1), 0, 30)

			if TimeLeft < 10 then surface.SetDrawColor(200, 0, 0) else surface.SetDrawColor(0, 200, 0) end

			surface.DrawRect(0, 0, w * (TimeLeft / 30), 24)

			draw.SimpleTextOutlined("MAP VOTING", "BasicFontLarge", w / 2, 12, Colors.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)

			draw.SimpleTextOutlined("TIME REMAINING: " .. tostring(TimeLeft), "BasicFontLarge", 4, 12, Colors.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 1, color_black)
		end

		VotePanel.SetVote	= function(_, panel)
			if VotePanel.selected then VotePanel.selected:SetSelected(false) end
			panel:SetSelected(true)

			VotePanel.selected = panel
		end

		VotePanel.UpdateVotes	= function(self, Votes)
			for _, btn in pairs(self.btnindex) do
				btn:SetCount(Votes[btn.map_index] or 0)
			end
		end

		local scrollpanel	= vgui.Create("DScrollPanel", VotePanel)
		scrollpanel:Dock(FILL)

		local btnlist	= vgui.Create("DIconLayout", scrollpanel)
		btnlist:Dock(FILL)
		btnlist:SetSpaceX(12)
		btnlist:SetSpaceY(12)

		for _, map in ipairs(Choices) do
			local btn = btnlist:Add("VoteButton")
			btn:SetSize(300, 320)
			btn.map_index	= map
			VotePanel.btnindex[map] = btn
			local breakdown	= string.Explode("/", map)

			btn:SetMap(breakdown[1], breakdown[2])

			btn.DoClick	= function(self)
				if math.Clamp(math.Round(Time - CT(), 1), 0, 30) == 0 then VotePanel:Remove() return end
				if not GetGlobalBool("AAS.Voting", false) then return end

				VotePanel:SetVote(self)

				SendVote(self.map_index)
			end
		end
	end

	-- Opens the vote menu, with a timer as well as if "rock the vote" can occur
	net.Receive("AAS.OpenVotes", function()
		Time	= net.ReadFloat()
		Choices	= net.ReadTable()

		VoteMenu()
	end)

	net.Receive("AAS.ReceiveVote", function()
		if VotePanel then VotePanel:UpdateVotes(net.ReadTable(false)) end
	end)
end