local PLUGIN = PLUGIN;

PLUGIN.taxi = PLUGIN.taxi or {}

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

// Player meta
local user = FindMetaTable("Player")
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
		local price = math.Round(TAXI.taxiBase + (PLUGIN:GetTaxistsAmount() * TAXI.taxiBonus), 2)

		if money < price then return false end;

		local taxiID = self:GetJobInfo("taxiID")
		if !taxiID then
				self:SetJobInfo("taxiID", MakeHashID(15));
		end

		PLUGIN.taxi[#PLUGIN.taxi + 1] = {
				["position"] = self:GetPos(),
				["price"] = price,
				["take"] = false,
				["id"] = self:GetJobInfo("taxiID")
		}

		PLUGIN:SyncTaxiPoses();
		
		return true
end;

function user:ClearTaxiCall(evenTaken)
		local calls = PLUGIN.taxi
		local i = #calls;

		while (i > 0) do
				local who = PLUGIN.taxi[i].id;
				local taken = PLUGIN.taxi[i].take
				
				if who && who == self:GetJobInfo("taxiID") && (evenTaken || !evenTaken && !taken) then
						PLUGIN.taxi[i] = nil;
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
		netstream.Start(self, 'taxi::syncTaxiCalls', copy)
end;