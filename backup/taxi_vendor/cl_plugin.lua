local PLUGIN = PLUGIN;

TAXI_DATA = {
	jobs = {},
	taken = 0,
	reward = 0
}

netstream.Hook('taxi::openInterface', function()
		if TINT && TINT:IsValid() then TINT:Close() end

		TINT = vgui.Create("BecameTaxi")
		TINT:Populate()
end);
netstream.Hook('taxi:dismiss', function()
		local HaveOrder = LocalPlayer():TaxiTakenOrder() && "If you'll dismiss - you will be fined because you have an active order." || ""
		Derma_Query("Do you really want to dismiss?" .. " " .. HaveOrder, "Dismiss", "Yes", function()
				netstream.Start('taxi::dissmissal')
		end,
		"No", function() end)
end);

netstream.Hook('taxi::taxiCallerIs', function(caller)
		if TINT && TINT:IsValid() then TINT:Close() end

		TINT = vgui.Create(!caller && "TaxiCustomer" || "TaxiInfo")
		TINT:Populate()
end);

netstream.Hook('taxi::syncTaxiCalls', function(data)
		TAXI_DATA.jobs = data

		if TINT && TINT:IsValid() then TINT:ReloadCalls() end
end);