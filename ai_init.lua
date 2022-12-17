--Initialize AI
aitrace("Script: AIScript Loading...")
------------------------
--Load AI scripts here--
------------------------

--This allows for mutliple different AI scripts to play against each other

--Scripts should not have any functions with the same names
--Loading files should not run anything, scripts should only define functions. 
dofilepath("data:ai/Bchamp_AI/aimain.lua")
dofilepath("data:ai/Nandidd_AI/aimain.lua")

--oninit function is called by engine at the beginning of the game
function oninit()
	
	--Top vs Bottom with fixed locations
	-- if Player_Self() <= (PlayersTotal()/2) - 1 then
	-- 	aiinit() --Top is Bchamp_AI
	-- else
	-- 	nandidd_init() --Bottom is Nandidd_AI
	-- end

	-- This runs Bchamp AI only. Comment this out if you use the above functions to do Bchamp vs Nandidd AI
	aiinit()
end


