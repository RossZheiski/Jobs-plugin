local PLUGIN = PLUGIN;

PLUGIN.taxiPoses = PLUGIN.taxiPoses or {}

function PLUGIN:AddJobPosition(uniqueID, vector, clientName, ent)
		local id = #self.jobPoses + 1;

		self.jobPoses[id] = {
			uniqueID = uniqueID,
			position = vector, 
			ply = clientName, 
			entity = ent, 
			state = false,
			name = self.jobsList[uniqueID].title
		};

		return id;
end;

function PLUGIN:RemoveJobPosition(id)
		if !self.jobPoses[id] then
				return;
		end
		local entity = self.jobPoses[id].entity
		if entity && entity != NULL then
				entity:Remove();
		end;

		self.jobPoses[id] = nil;

		// refresh;
		self:ListRefresh()
end;

function PLUGIN:ListRefresh()
	local players = player.GetAll();
	local i, max = 1, #players

	// Sorting ids;
	self:SortJobsPositions()

	// Synchronization;
	while (i <= max) do
			local user = players[i];
			if user:IsValid() && (user:IsAdmin() || user:IsSuperAdmin()) then
					netstream.Start(user, 'jobVendor::updateRemoveList', self.jobPoses)
			end;
			i = i + 1
	end
end;

// Id sorting;
function PLUGIN:SortJobsPositions()
		local poses = table.Copy(self.jobPoses);
		local buffer = {}

		for k, v in pairs(poses) do
			if v.entity && v.entity != NULL then
				v.position = v.entity:GetPos()
				buffer[#buffer + 1] = v;
			end;
		end

		self.jobPoses = buffer
end;

function PLUGIN:GetWork(name)
		return self.jobsList[name]
end;

function PLUGIN:SortTaxiPoses()
		local calls = table.Copy(self.taxiPoses);
		local buffer = {}

		for k, v in pairs(calls) do
				buffer[#buffer + 1] = v;
		end

		self.taxiPoses = buffer;
end;

function PLUGIN:SyncTaxiPoses()
		local plys = player.GetAll();
		local i = #plys;

		while (i > 0) do
			local client = plys[i];
			if client:WorkingInTaxi() then
					client:SyncTaxi()
			end
			i = i - 1;
		end
end;

// Utility check;
function PLUGIN:CheckJobs(firstID, secondID)
		local jobs = self.jobPoses;
		if !jobs then return false end;
		if !jobs[firstID] || !jobs[secondID] then return false end;

		local leftJob = util.TableToJSON(jobs[firstID]);
		local rightJob = util.TableToJSON(jobs[secondID]);

		return leftJob == rightJob
end;