local PLUGIN = PLUGIN;

brokenMat = "models/props_debris/plasterceiling008a"
unBrokenMat = "Models/effects/vol_light001"

function PLUGIN:PlayerLoadedChar(client, character, lastChar)
		timer.Simple(0.25, function()
			character:setData("job_info", 
					character:getData("job_info", {
						addRep = 0,
						rep = 0,
						id = 0,
						price = 0,
						name = "",
						
						taxiID = MakeHashID(15),
						taxi = NULL,
					})
			)
			client:setLocalVar("job_info", 
					character:getData("job_info")
			)
		end);
end;

function PLUGIN:CharacterPreSave(character)
		local client = character:getPlayer()
    if (IsValid(client)) then
				character:setData("job_info", 
					character:getData("job_info", {
						addRep = 0,
						rep = 0,
						id = 0,
						price = 0,
						name = "",

						taxiID = MakeHashID(15),
						taxi = NULL,
					})
			)
			client:setLocalVar("job_info", 
					character:getData("job_info")
			)
		end;
end;

function PLUGIN:PlayerDisconnected(user)
		local char = user:getChar();
		if user:IsValid() && char then
				user:ClearJob()

				local entity = user:GetJobInfo("taxi");

				if entity && entity != NULL then
						entity:Remove()
						user:SetJobInfo("taxi", NULL);
				end

				user:ClearTaxiCall(true)
		end
end;

// Pick the job for the character;
// Adds the timer for the job. When timer expires - the job for the character clears;
// Timer checks each second;
netstream.Hook('jobVendor::pickWork', function(client, name)
		if client:GetJobID() != 0 then return end;
		local job = PLUGIN:GetWork(name);
		
		if job then
				if !client:CanPickJob(name) then
						client:notify("You can't pick this work for now.")
						return;
				end

				client:CreateJob(job)

				local i = 1;
				local players = player.GetAll()
				while i <= #players do
						if players[i]:IsValid() then								
								players[i]:CallThePositionsAmount()
						end
						i = i + 1;
				end
				
				// send character to faction "Labourers Union of Miami"
				local faction = FACTION_LABUNION
				local fac = nut.faction.indices[faction]
				if client:getChar():getFaction() != faction && fac then
						client:getChar():setFaction(faction)
						client:notify("You were transfered to faction " .. fac.name)
				end;
				
				local uniqueID = "WorkTime: " .. client:getChar():getID()
				timer.Create(uniqueID, 1, job.timeForRepair, function()
						if !timer.Exists(uniqueID) || !client:IsValid() then
							timer.Remove(uniqueID) 
							return; 
						end;
						
						if client:IsValid() && timer.RepsLeft(uniqueID) <= 0 && client:GetJobID() != 0 then
								client:ClearJob()
						end;
				end);
		end;
end);

// Hook for add position of job. 
// Adds the default entity to position;
// Adds the position to job list;
// Refreshes the list to all admin players;
netstream.Hook('jobVendor::PosAdd', function(client, uniqueID)
		local vector = client:GetEyeTraceNoCursor().HitPos
		local jobList = PLUGIN.jobsList[uniqueID]

		if !client:IsAdmin() || !client:IsSuperAdmin() then			
			return;
		end
		if !jobList then
			client:notify("This job don't exists")
			return;
		end
		if (!isvector(vector) || !util.IsInWorld(vector)) then
			client:notify("This vector is not valid or not in world")
			return
		end

		// Spawn the entity;
		// This entity is DEACTIVATED until the player picks job;
		// When player picks the job - entity breaks for X seconds;
		// If there's no entities to be broken for new job - the job will be unavailable;
		local ent = ents.Create(jobList.ent)
		ent:SetPos(vector)
		ent:Spawn()

		// Add position;
		local workPos = PLUGIN:AddJobPosition(
			uniqueID, 
			tostring(vector), 
			client:GetName(), 
			ent
		)

		ent:SetWorkPos(workPos)
		
		// Refresh the list for all admin players;
		PLUGIN:ListRefresh();
end);

// Hook to remove the job from list;
// When job removes - the entity removes too;
netstream.Hook('jobVendor::removeJob', function(client, id)
		local jobList = PLUGIN.jobPoses[id]

		if !client:IsAdmin() || !client:IsSuperAdmin() then			
				return;
		end
		if !jobList then
				client:notify("This job don't exists")
				return;
		end

		PLUGIN:RemoveJobPosition(id)
		client:notify("Work successfully removed")
end);


// Идеи:
// Сделать мини-игры
// Сделать доступ через какой-нибудь CAMI;
// Сделать ломающимися инструменты;
// Сделать больше рандомных звуков;
// ПДА работника + Сделать запоминание в ПДА работника последних работ;
// Все эти вещи можно сломать вручную
// Сделать интерактивные действия: гидрант отталкивает, щиток бьет током.

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