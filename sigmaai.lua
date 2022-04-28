aitrace("Script: Starting AI");

-- table of all variables that need to be saved
	AIG = {}

-- cache gameinfo options that AI will need
	g_LOD = LevelOfDifficulty(); --easy is 0, normal is 1, hard is 2, expert is 3
	g_GameType = GetGameType();
	g_GameMode = GetGameMode();

--Initialize random variables
	rand1a = Rand(1);
	rand1b = Rand(1);
	rand1c = Rand(1);
	rand2a = Rand(2);
	rand2b = Rand(2);
	rand2c = Rand(2);
	rand3a = Rand(3);
	rand3b = Rand(3);
	rand3c = Rand(3);
	rand4a = Rand(4);
	rand4b = Rand(4);
	rand4c = Rand(4);
	rand10a = Rand(10);
	rand10b = Rand(10);
	rand10c = Rand(10);
	rand40a = Rand(40);
	rand40b = Rand(40);
	rand100a = Rand(100);
	rand100b = Rand(100);
	rand100c = Rand(100)


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

------------------------------------------------------------------
--Doesn't work as far as I can tell -- Tested by Bchamp 4/2/2019--
------------------------------------------------------------------
--SetTargetTypePriority( Creature_EC, 5 )
--SetTargetTypePriority( SoundBeamTower_EC, 80 )
--SetTargetTypePriority( AntiAirTower_EC, 80 )
--SetTargetTypePriority( ElectricGenerator_EC, 100 )
--SetTargetTypePriority( RemoteChamber_EC, 80 )
--SetTargetTypePriority( WaterChamber_EC, 80 )
--SetTargetTypePriority( Aviary_EC, 80 )
--SetTargetTypePriority( ResourceRenew_EC, 75000 )
--SetTargetTypePriority( Foundry_EC, 75 )
--SetTargetTypePriority( VetClinic_EC, 20 )
--SetTargetTypePriority( GeneticAmplifier_EC, 20 )
--SetTargetTypePriority( LandingPad_EC, 10 )
--SetTargetTypePriority( BrambleFence_EC, 65 )
--SetTargetTypePriority( Lab_EC, 0 )
--SetTargetTypePriority( Henchman_EC, 5 )




-- EXTRA GAME MODES NOT SUPPORTED
--if (g_GameMode == GM_KillRex) then

	--SetTargetTypePriority( Rex_EC, 100 )
	--SetTargetTypePriority( Lab_EC, 80 )
--else
	
	-- SetTargetTypePriority( Lab_EC, 100 )
	-- SetTargetTypePriority( Creature_EC, 95 )
	
--end