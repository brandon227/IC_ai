--This file chooses tactics or strategies for the ai
--begin loading tactic luas, consider moving these to a separate folder
dofilepath("data:ai/rank1rush.lua")
-- 
dofilepath("data:ai/researchrush.lua")
-- 
dofilepath("data:ai/flyerrush.lua")
-- 
dofilepath("data:ai/choosecreature.lua")
--
dofilepath("data:ai/rank2rush.lua")
--
dofilepath("data:ai/economyrush.lua")
--
function init_randomness()
	--Create random variables
	for i=0,Player_Self() do
		doRandom();
	end

	--create a unique delay for each player so that AI do not calculate the same random value on the same tick
	local uniqueDelay = calcAvgAttribute( Player_Self(), "power", 1, 5 )*Player_Self() + Player_Self()*7
	while uniqueDelay > 100 do
		uniqueDelay = uniqueDelay - 100
	end
	RegisterTimerFunc("doRandom", uniqueDelay + 180); --refresh random variables every once in awhile

    sg_aggressiveness = Rand(100); --100 is more aggressive, attacks more often


	return 1
end

--Initialize random variables
function doRandom()
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
	rand100c = Rand(100);
end

function ChooseTactic(forceTactic)

    --only do on hard/expert or if forced.
    if (g_LOD < 2 and forceTactic == 0) then
        return
    end

    local numEnemies = PlayersAlive( player_enemy )
	local numAllies = PlayersAlive( player_ally )
    local totalPlayers = numAllies + numEnemies

    goal_rank2rush = 0

	-- find closest
	local closestenemy = ClosestEnemy(0)
	local closestDist = 100000
	-- non amphib dist
	if (closestenemy > -1) then
		closestDist = Player_Dist(closestenemy, 0)
	end

	aitrace("Rank2Rush: Testing Closest("..closestenemy..") Dist("..closestDist..")")

	local numEnemies = PlayersAlive( player_enemy )
	local numAllies = PlayersAlive( player_ally )
	
	-- don't do this when the number of enemies out numbers the allies
	--if (numEnemies > numAllies) then
	--	return 0
	--end
	
	local randtemp = Rand(100)
	local rushChance = 30
	one_v_one = 0
	if (numEnemies == 1 and numAllies == 1) then
		rushChance = 85
		one_v_one = 1
	end

	-- If there is a rush, determine if it will be at a forward chamber at enemy base or not.
	chamberAtEnemyBase = 0
	local maxEnemyDistance = 500
	if(Rand(100) < 20 and fact_lowrank_amphib ~= 2) then --20% chance of making a proxy chamber. Don't proxy with amphib L2's
		chamberAtEnemyBase = 1
		maxEnemyDistance = 350
	end

	aitrace("Rank2Rush: Rand:"..randtemp)
	-- test for rank2 tactic
	-- if currently lvl 1, enemy is close, and randomness allows, perform rush.
	
	if (GetRank() == 1 and closestDist < maxEnemyDistance and randtemp < rushChance) then
		-- have the units for a rank2 ground rush
		local units = Army_ClassSize( Player_Self(), sg_class_groundrank2rush )
		if (units > 0) then
			goal_rank2rush = 1
		end
	end


	-- only do this in difficult and non-quick start resources
	if (g_LOD ~= 2 or ScrapAmountWithEscrow() > 1000) then
		goal_rank2rush = 0
	end

end

function ChamberLocation()

    if (LabUnderAttackValue() > 200) then
        return PH_Best
    elseif rand100a > 50 then
        return PH_DefendSite
    else
        return PH_OutsideBase
    end

end