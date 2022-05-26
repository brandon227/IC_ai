aitrace("Script: Starting AI");

-- table of all variables that need to be saved
	AIG = {}

-- cache gameinfo options that AI will need
	g_LOD = LevelOfDifficulty(); --easy is 0, normal is 1, hard is 2, expert is 3
	g_GameType = GetGameType();
	g_GameMode = GetGameMode();


-- Add any scripts specific to each level of AI (apparently none)
if (g_LOD == 0) then
	aitrace("Script: EasyAI Loading");
elseif (g_LOD == 1) then
	aitrace("Script: StandardAI Loading");
else
	aitrace("Script: HardAI Loading");
end

-- this is the AI file used in all levels
dofilepath("data:ai/aimain.lua");
