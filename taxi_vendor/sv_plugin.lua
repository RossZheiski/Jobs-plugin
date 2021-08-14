local PLUGIN = PLUGIN;

function PLUGIN:PlayerLoadedChar(client, character, lastChar)
		timer.Simple(0.25, function()
			character:setData("taxi", 
					character:getData("taxi", {
						taxiID = MakeHashID(15),
						taxi = NULL,
					})
			)
			client:setLocalVar("taxi", 
					character:getData("taxi")
			)
		end);
end;

function PLUGIN:CharacterPreSave(character)
		local client = character:getPlayer()
    if (IsValid(client)) then
				character:setData("taxi", 
					character:getData("taxi", {
						taxiID = MakeHashID(15),
						taxi = NULL,
					})
			)
			client:setLocalVar("taxi", 
					character:getData("taxi")
			)
		end;
end;

function PLUGIN:PlayerDisconnected(user)
		local char = user:getChar();
		if user:IsValid() && char then
				local entity = user:GetTaxiData("taxi");

				if entity && entity != NULL then
						entity:Remove()
						user:SetJobInfo("taxi", NULL);
				end
				user:ClearTaxiCall(true)
		end
end;

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

		local entity = client:GetTaxiData("taxi");

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

// TAXI:
// Нельзя уволиться, пока кто-то есть в машине
// Когда игрок заказывает такси - у него снимается 1$
// Если игрок ушел с места, то таксист может отменить заказ.
// Если таксист отменил заказ и не был в радиусе точки, то ему не даются деньги за подачу
// Если игрок отменил заказ, то деньги за подачу возвращаются в размере 50%
// Таксист не должен иметь возможности брать более одного заказа за раз.
// Если таксист не приехал через (Количество метров * 30 секунд), то заказ считается не выполненным
// Таксист должен иметь возможность отменить заказ, но тогда игроку возвращается его предоплата
// 