local PLUGIN = PLUGIN

PLUGIN.name = "Taxi job plugin"
PLUGIN.author = "Ross Cattero"
PLUGIN.desc = "Adds vendor and taxi systems."

PLUGIN.debug = true;

nut.util.include("cl_plugin.lua")
nut.util.include("sh_taxi.lua")
nut.util.include("sv_plugin.lua") 
nut.util.include("sv_taxi.lua") 

nut.command.add("taxi", {
	onRun = function(client)
			local workingTaxi = client:WorkingInTaxi();
			if workingTaxi then
					client:SyncTaxi()
			end

			netstream.Start(client, 'taxi::taxiCallerIs', workingTaxi)
	end
})