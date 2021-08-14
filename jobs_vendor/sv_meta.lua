local PLUGIN = PLUGIN;

local user = FindMetaTable("Player")
function user:CreateJob(data)
		if self:GetJobID() != 0 then return end;
		local i = self:CanPickJob(data.uniqueID)
		if !i then return end;
		local job = PLUGIN.jobPoses[i]
		if !job then return end;

		local ent = job.entity

		if ent:IsValid() && IsEntity(ent) then
				ent:Broke(true)
				netstream.Start(self, 'jobVendor::sendTheEntity', ent)
				job.state = true;
		end;

		self:SetJobInfo("name", data.title)
		local REPUTATION = self:GetVendorRep()
		local bonus = 
			(REPUTATION * (JOBREP.repMutli / 100)) 
			+ 
			(data.price * (JOBREP.priceMulti / 100));
		bonus = math.Round(bonus, 2)
		self:SetJobInfo("price", data.price + bonus)
		self:SetJobInfo("addRep", data.reputation + (data.reputation * (JOBREP.repMutli / 100)));
		
		self:SetJobInfo("id", i);
end;

function user:CanPickJob(uID)
		if self:GetJobID() != 0 then return false end;
		local jobs = PLUGIN.jobPoses;

		local i = 1;
		while (i <= #jobs) do
				local entity = jobs[i]["entity"];
				local canPick = jobs[i]["state"];
				local uniqueID = jobs[i].uniqueID

				if entity && entity != NULL && !canPick && uniqueID == uID then
						return i;
				end
				i = i + 1;
		end

		return false;
end;

function user:ClearJob(notFinished)
		local job = self:GetJobID();
		if job == 0 then return end;

		local ent = PLUGIN.jobPoses[job].entity;

		if ent && ent != NULL then
				ent:Broke(false);
				netstream.Start(self, 'jobVendor::sendTheEntity', nil)
		end

		PLUGIN.jobPoses[job].state = false;
		
		self:SetJobInfo("price", 0);
		self:SetJobInfo("id", 0);
		self:SetJobInfo("addRep", 0);

		if !notFinished && self:IsValid() then
				self:notify("You've not finished the work that was belonged to you! This will unsatisfy your employer.")
				self:SetJobInfo("rep", math.Clamp(self:GetJobInfo("rep") - JOBREP.takeRep or 0, JOBREP.repMin, JOBREP.repMax));
		end
end;

function user:SetJobInfo(index, value)
		local data = self:getChar():getData("job_info");
		data[index] = value;
		self:getChar():setData("job_info", data);
		self:setLocalVar("job_info", data);
end;

function user:GetJobInfo(index)
		local data = self:getChar():getData("job_info");
		return data[index];
end;

function user:CallThePositionsAmount()
		local jobPoses = PLUGIN.jobPoses
		local positions = {}

		local i = 1;
		while i <= #jobPoses do
				local id = jobPoses[i].uniqueID;
				if !id then continue; end;
				
				if !positions[id] then
						positions[id] = 0;
				end
				if jobPoses[i] && !jobPoses[i]["state"] then
						positions[id] = positions[id] + 1;
				end
				i = i + 1;
		end

		netstream.Start(self, 'jobVendor::callPosAmount', positions)
end;

function user:FinishJob(id)
		local jobList = PLUGIN.jobPoses;
		local job = self:GetJobID();

		if id != job || !jobList || (jobList && !jobList[id]) then
				return;
		end

		if PLUGIN:CheckJobs(job, id) then
				local character = self:getChar();
				if character then
						local repAmount = self:GetJobInfo("rep") + self:GetJobInfo("addRep");
						local price = self:GetJobInfo("price");
						character:giveMoney( price )
						self:SetJobInfo("rep", math.Clamp(repAmount, JOBREP.repMin, JOBREP.repMax));
						if repAmount >= JOBREP.repMax then
								repText = "You already have a maximum reputation in number of " .. JOBREP.repMax .. ".";
						else
								repText = "You've gained a " .. repAmount .. " reputation for your work."
						end
						self:notify(repText .. " You've gained " .. nut.currency.get(price) .. " for done work.")
				end
				self:ClearJob(true)
				
				netstream.Start(self, 'jobVendor::stopJobTimer')
		end
end;

function user:CanAskTaxi()
		local entity = self:GetJobInfo("taxi");

		return !entity || entity == NULL;
end;

function user:WorkingInTaxi()
		local char = self:getChar();
		local faction = char:getFaction()
		return faction == FACTION_TAXI_WORKER
end;

function user:CallTaxi()
		local char = self:getChar();
		local money = char:getMoney()
		local price = math.Round(JOBREP.taxiBase + (PLUGIN:GetTaxistsAmount() * JOBREP.taxiBonus), 2)

		if money < price then return false end;

		PLUGIN.taxiPoses[#PLUGIN.taxiPoses + 1] = {
				["position"] = self:GetPos(),
				["price"] = price,
				["take"] = false,
				["who"] = self
		}

		PLUGIN:SyncTaxiPoses();
		
		return true
end;

function user:ClearTaxiCall(evenTaken)
		local calls = PLUGIN.taxiPoses
		local i = #calls;

		while (i > 0) do
				local who = PLUGIN.taxiPoses[i].who;
				local taken = PLUGIN.taxiPoses[i].take
				if who && who == self && (evenTaken || !evenTaken && !taken) then
						PLUGIN.taxiPoses[i] = nil;
						PLUGIN:SortTaxiPoses()
						PLUGIN:SyncTaxiPoses()
						if self:IsValid() then
								self:notify("You can call a taxi again.")
						end
						return;
				end
				i = i - 1;
		end
end;

function user:SyncTaxi()
		local copy = table.Copy(PLUGIN.taxiPoses)

		local i = #copy;
		while (i > 0) do
			copy[i].who = nil;
			i = i - 1;
		end
		netstream.Start(self, 'taxi::syncTaxiCalls', copy)
end;