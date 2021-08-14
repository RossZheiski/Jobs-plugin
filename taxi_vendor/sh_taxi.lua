local PLUGIN = PLUGIN;

TAXI = {
	taxiRules = [[
	1. You'll receive a taxi car that's shouldn't be stolen or destroyed.
	2. After you receive a request from customer - you'll see a marker on customer's position.
	3. Customer pay fee for calling a taxi. If customer don't agree to drive with you - this fee will return to customer. If customer decided to walk away or call taxi without a reason - this fee returns to you.
	4. Be polite and don't take other's taxi customers.
	5. If you've been called and you didn't arrive - this may result in a fine or dismissal.
	]], // Taxi rules. It will draw when someone will access the taxi worker first time;
	taxiBase = 2.25, // Base taxi reward; Default: 2.25;
	taxiBonus = 0.15, // Taxi workers amount bonus; Multiplicates this number to taxists amount; Default: 0.15;
	maxTaxi = 2, // Maximum in taxi faction; Default: 2;
	taxiSpawn = {
		position = Vector(527.916260, -344.597351, -83.968933),
		angle = Angle(2.692024, 99.941452, 0.000000)
	}, // Position for taxi spawn.
	taxiFee = 1, // A fee which is paid when order is taken. Default: 1;
}
// TODO: Taxi price formula: taxiBase + (taxi amount * taxiBonus);

function PLUGIN:GetTaxistsAmount()
		local faction = FACTION_TAXI_WORKER // taxi faction;
		local users = player.GetAll()
		local i = #users
		local taxists = 0;

		while (i > 0) do
				local user = users[i]
				if user:IsValid() && user:getChar() && user:getChar():getFaction() == faction then
						taxists = taxists + 1;
				end
				i = i - 1;
		end

		return taxists;
end;

function PLUGIN:CanSpawnTaxi(vector)
		if !simfphys || (simfphys && !simfphys.IsCar) then return false end;

		local someEnts = ents.FindInSphere(vector, 60)
		local i = #someEnts;

		while (i > 0) do
				local entity = someEnts[i]
				if entity:IsPlayer() || simfphys.IsCar(entity) then
						return false;
				end
				i = i - 1;
		end

		return true;
end;