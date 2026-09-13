if (getgenv().UC_LOADED) then
	return;
end;
getgenv().UC_LOADED = true;

if (identifyexecutor() == "Wave") then
	getgenv().gethui = function()
		return game:GetService("CoreGui");
	end;	
end;

if (game.GameId == 6035872082) then
	loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/2f956196b25b2caa970255b3d08949b6.lua"))()
elseif (game.GameId == 1008451066) then
	loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/2f956196b25b2caa970255b3d08949b6.lua"))()
elseif (game.PlaceId == 2317712696) then
	loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/2f956196b25b2caa970255b3d08949b6.lua"))()
end;
