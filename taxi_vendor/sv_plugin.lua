local PLUGIN = PLUGIN;

netstream.Hook('taxi::Accept', function(client)
		local taxi = TAXI.taxiSpawn;
		local postion, angles = taxi.position, taxi.angle

		if !client:CanAskTaxi() then return end;

		if PLUGIN:CanSpawnTaxi(postion) then
				local vehicle = simfphys.SpawnVehicleSimple( "simfphys_mafia2_quicksilver_windsor_taxi_pha", postion, angles )
				client:SetJobInfo("taxi", vehicle);

				// send character to faction "TAXI workers"
				local faction = FACTION_TAXI_WORKER
				local fac = nut.faction.indices[faction]
				if client:getChar():getFaction() != faction && fac then
						client:getChar():setFaction(faction)
						client:notify("You were transfered to faction " .. fac.name)
				end;
		else
				client:notify("Something is blocking vehicle spawn point.")
		end;
end);

netstream.Hook('taxi::dissmissal', function(client)
		if client:CanAskTaxi() then return end;

		local entity = client:GetJobInfo("taxi");

		if entity && entity != NULL then
				entity:Remove()
				client:SetJobInfo("taxi", NULL);
		end
end);

netstream.Hook('taxi::sendTaxiRequest', function(client)
		local uniqueID = "taxiCall: " .. client:EntIndex()
		if timer.Exists(uniqueID) then return end;

		if !client:CallTaxi() then return end;
		
		timer.Create(uniqueID, 60, 1, function()
				client:ClearTaxiCall()
		end);

		client:notify("You have called a taxi. Wait where you have called it, please.")
end);

netstream.Hook('taxi::TakeJob', function(client, id)
		if !client:WorkingInTaxi() then
				return;
		end
		local job = PLUGIN.taxiPoses[id];

		if job && (job.who && job.who:IsValid()) && !job.take then
				job.who:notify("Your taxi request is taken. Stay near position and wait, please.")
				job.take = true;
				PLUGIN:SyncTaxiPoses()
				client:notify("You've taken this order!")
		end
end);