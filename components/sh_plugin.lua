local PLUGIN = PLUGIN
PLUGIN.name = "Compontents plugin"
PLUGIN.author = "Ross Cattero"
PLUGIN.desc = "Some components needed for Ross's plugins."

nut.util.include("cl_fonts.lua")
nut.util.include("sv_plugin.lua")
nut.util.include("sv_meta.lua")

function RFormatTime(time)
		local formatTime = "";
		if time >= 60 then
				if math.floor(time / 60) > 9 then
					formatTime = math.floor(time / 60) .. ":"
				else
					formatTime = "0" .. math.floor(time / 60) .. ":"
				end;
				if time % 60 < 10 then
					formatTime = formatTime .. "0" .. time % 60
				else
					formatTime = formatTime .. time % 60
				end
		else
				if time % 60 < 10 then
						formatTime = "00:" .. "0" .. time
				else
						formatTime = "00:" .. time
				end;
		end

		return formatTime
end;

function MakeHashID(length)
		if !length then length = 10 end;
		local str = ""
		math.randomseed(os.time())

		local buffer = {
			[1] = {65, 90},
			[2] = {97, 122},
			[3] = {48, 57}
		}

		local i = length;
		while (i > 0) do
				local fromBuffer = buffer[math.random(1, 3)]
				str = str .. string.char(math.random(fromBuffer[1], fromBuffer[2]));
				i = i - 1;
		end
				

		return str;
end;