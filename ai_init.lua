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
	
	if Player_Self() <= PlayersTotal()/2 then
		aiinit()
	else
		nandidd_init()
	end
end

