MsgN("+ Requisition system loaded")

local PLAYER = FindMetaTable("Player")

-- Directly get the player's requisition
function PLAYER:GetRequisition()
	return self:GetNW2Int("Requisition", 0)
end

if SERVER then

	-- Directly set the player's requisition
	function PLAYER:SetRequisition(Amount)
		self:SetNW2Int("Requisition", Amount)
	end

	-- Attempt to deduct an amount of the player's requisition
	-- Returns true if it succeeds
	-- Returns false, and optionally Reason will be passed directly to the player if it fails
	-- If any transaction occurs, the player gets a message regardless, unless the difference is 0
	function PLAYER:ChargeRequisition(Amount, Reason)
		local Current	= self:GetRequisition()

		Amount	= math.abs(math.Round(Amount))

		if Amount > Current then return false, "Overdrawn" end

		self:SetRequisition(Current - Amount)

		local Diff = self:GetRequisition() - Current

		if Diff == 0 then return true end

		if Reason then
			aasMsg({Colors.BasicCol, "You were charged ", Colors.BadCol, tostring(math.abs(Diff)), Colors.BasicCol, " points for: " .. Reason .. ". Current amount: ", Colors.GoodCol, tostring(self:GetRequisition())}, self)
		else
			aasMsg({Colors.BasicCol, "You were charged ", Colors.BadCol, tostring(math.abs(Diff)), Colors.BasicCol, " points. Current amount: ", Colors.GoodCol, tostring(self:GetRequisition())}, self)
		end

		return true
	end

	-- Gives the player an amount of requisition
	-- If any change occurs, will notify the player, and optionally pass along Reason
	function PLAYER:PayRequisition(Amount, Reason)
		local Current	= self:GetRequisition()

		Amount	= math.abs(math.Round(Amount))

		self:SetRequisition(math.min(Current + Amount, AAS.Funcs.GetSetting("Max Requisition", 500)))

		local Diff	= self:GetRequisition() - Current

		if Diff == 0 then return true end

		if Reason then
			aasMsg({Colors.BasicCol, "You received ", Colors.GoodCol, tostring(math.abs(Diff)), Colors.BasicCol, " points for: " .. Reason .. ". Current amount: ", Colors.GoodCol, tostring(self:GetRequisition())}, self)
		else
			aasMsg({Colors.BasicCol, "You received ", Colors.GoodCol, tostring(math.abs(Diff)), Colors.BasicCol, " points. Current amount: ", Colors.GoodCol, tostring(self:GetRequisition())}, self)
		end

		return true
	end
end