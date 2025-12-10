if engine.ActiveGamemode() ~= "Advance and Secure" then return end

timer.Simple(0, function()
	if ulx and ulx.uteamEnabled then
		function ulx.uteamEnabled()
			return ULib.isSandbox() and GAMEMODE.Name ~= "DarkRP" and GAMEMODE.Name ~= "Advance and Secure"
		end
	end
end)