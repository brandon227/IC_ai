
-- Spam Offset Added!

aitrace("Script Component: Creature Ordering Functions")

function init_military()

	aitrace("init_military()")

	icd_groundgroupminsize = 8;
	icd_groundgroupmaxsize = 40;
	
	icd_watergroupminsize = 8;
	icd_watergroupmaxsize = 40;
	
	icd_airgroupminsize = 8;
	icd_airgroupmaxsize = 40;
	
	icd_groundgroupminvalue = 500;
	icd_groundgroupmaxvalue = 7500;
	
	icd_watergroupminvalue = 400;
	icd_watergroupmaxvalue = 7500;
	
	icd_airgroupminvalue = 500;
	icd_airgroupmaxvalue = 7500;
		
	icd_groundattackpercent = 100;
	icd_waterattackpercent = 100;
	icd_airattackpercent = 100;
	
	rankValue = {80,170,300,450,650};

	-- creature choice desires for each of these creature types
	sg_goalamphib = 0
	sg_goalmelee = 0
	sg_goalartillery = 0
	sg_goalflyer = 0
	sg_goalrange = 0
	sg_goalantidefence = 0
	
	-- number desired - dynamically changing
	sg_creature_desired = PopulationMax();
	
	-- max amount, set by init func overrides and triggers
	sg_creature_unit_cap = sg_creature_desired;

	-- set for hard level ((what does this do??? It just gets reset below...consider removing to declutter? -Bchamp))
	icd_enemyValueModifier = 1.1

	if (g_LOD == 0) then
		sg_creature_desired = 8;
		-- these values are how much bigger your army has to be over
		icd_enemyValueModifier = 0.4; 
		icd_engageEnemyValueModifier = 0.35;
		icd_fleeEnemyValueModifier = 0.20; -- easy never flees, so this isn't even used
		-- when a group is activated it is set to territorial stance instead of aggressive
		icd_setTerritorialStance = 1
	elseif (g_LOD == 1) then
		-- these values are how much bigger your army has to be over
		icd_enemyValueModifier = 0.85; 
		icd_engageEnemyValueModifier = 0.70;
		icd_fleeEnemyValueModifier = 0.55;
	elseif (g_LOD == 2) then
		icd_enemyValueModifier = 1.0;
		icd_engageEnemyValueModifier = 1.0; --0.80
		icd_fleeEnemyValueModifier = 0.65; --the higher this value, the more easily the AI will flee. Raised from 0.60 by Bchamp 4/12/2019
	else --Expert
		icd_enemyValueModifier = 1.0; --multiplier for enemy value. Value = total resources of all active military units, including towers
		icd_engageEnemyValueModifier = 1.2; --only engage enemy if you have a bigger army
		icd_fleeEnemyValueModifier = 0.70; --flee when you army starts to get small
	end
	
	-- is the AIs current target an amphibian one
	goal_amphibTarget = 0
	
	fact_enemyPop = 0
	fact_militaryPop = 0
	fact_enemyValue = 0
	fact_selfValue = 0
	
	icd_startAtRank = 1

	-- this is how many seconds the AI will wait to build a better creature
	icd_bestCreatureWaitTime = 10

	if (g_LOD==0) then
		icd_bestCreatureWaitTime = 4
	end
	
	-- static army decisions that don't change through the duration of a game
		
	-- decide on what creatures we want
	armydecisions()
	
	--Set target type priorities, these are not fully understood, but they do seem to work and have some affect
	--I think Lab, Foundry, and Chambers are the only ones that work. Highest sum of values in an area will be targetted, but only if a unit is nearby too
	--Only one foundry counts towards the total value. Other building types don't seem to work, but haven't been fully tested --Bchamp 5/17/22
	SetTargetTypePriority( Creature_EC, 1000 )
	SetTargetTypePriority( SoundBeamTower_EC, 0 )
	SetTargetTypePriority( AntiAirTower_EC, 0 )
	SetTargetTypePriority( ElectricGenerator_EC, 5000 )
	SetTargetTypePriority( RemoteChamber_EC, 1500 )
	SetTargetTypePriority( WaterChamber_EC, 1500 )
	SetTargetTypePriority( Aviary_EC, 1500 )
	SetTargetTypePriority( ResourceRenew_EC, 0 )
	SetTargetTypePriority( Foundry_EC, 5000 )
	SetTargetTypePriority( VetClinic_EC, 0 )
	SetTargetTypePriority( GeneticAmplifier_EC, 0 )
	SetTargetTypePriority( LandingPad_EC, 0 )
	SetTargetTypePriority( BrambleFence_EC, 0 )
	SetTargetTypePriority( Lab_EC, 0 )
	SetTargetTypePriority( Henchman_EC, 0 )

	SetDefendTypePriority( Lab_EC, 500 )
	SetDefendTypePriority( Foundry_EC, 500 )


	-- set the rank we should start at
	-- if we only have rank1s then leave it but if we have any rank2 ground creatures
	-- then wait for them, if the opponent has more than a couple creatures before we hit
	-- rank2 then set this back to 1
	if (GetRank() == 1) then
		icd_startAtRank = 1
		local groundRank2Count = Army_NumCreaturesInClass( Player_Self(), sg_class_ground, 2, 2 );
		if (groundRank2Count > 0 and fact_enemyPop < 4) then
			icd_startAtRank = 2
		end
	end

	if (g_LOD == 0) then
		RegisterTimerFunc("docreaturebuild", 10 )
	elseif (g_LOD == 1) then
		RegisterTimerFunc("docreaturebuild", 5 )
	else
		RegisterTimerFunc("docreaturebuild", 1 )
	end

end

function Logic_creatureTypeDesire()
	
	-- do we want swimmers at this time
	goal_desireSwimmers = 0
	goal_desireFlyers = 0
	goal_desireGround = 0
	
	-- determine what creatures to build based on current army availability, map size,
	-- map type, currnt money situation, counters,  
	local playerself = Player_Self();
	local curRank = GetRank();
	
	local groundCount = Army_NumCreaturesInClass( playerself, sg_class_ground, curRank-1, curRank );
	local amphibCount = Army_NumCreaturesInClass( playerself, sg_class_amphib, curRank-1, curRank );
	-- what is the pure ground count
	groundCount = groundCount-amphibCount
	
	if (groundCount > 0) then
		goal_desireGround = 1
	end
	-- if can't find place for water chamber and we have ground dudes, then build 
	-- ground chamber anyways
	if (NoPlaceForWaterChamber() == 1) then
		local allGround = Army_NumCreaturesInClass( playerself, sg_class_ground, 1, curRank )
		local allAmphib = Army_NumCreaturesInClass( playerself, sg_class_amphib, 1, curRank )
		if ((allGround - allAmphib) > 0) then
			goal_desireGround = 1
		end
	end
	
	-- don't just use rank 1 as test for average elec, also look to rank2
	local testAvgRank = curRank
	if (testAvgRank < 2) then
		testAvgRank = 2
	end
	fact_armyAvgElec = calcAvgAttribute( playerself, "costrenew", testAvgRank-1, testAvgRank )
	fact_armyAvgCoal = calcAvgAttribute( playerself, "cost", testAvgRank-1, testAvgRank )
	
	-- no need to desire swimmers or flyers until after rank2
	if (curRank < 2) then
		return
	end
		
	local swimmerCount = Army_NumCreaturesInClass( playerself, sg_class_swimmer, curRank-1, curRank );
	local flyerCount = Army_NumCreaturesInClass( playerself, sg_class_flyer, curRank-1, curRank );
	
	if (swimmerCount > 0) then

			if (sg_goalamphib >= 1) then
				goal_desireSwimmers = 1
			end
		
			-- if amphibian map and we have any swimmers then we want some
			if (goal_amphibTarget == 1) then
				goal_desireSwimmers = 1
			end
			
			-- should also check if the top wanted creatures are amphibian ?
			
			-- does building swimmer double our options
			if (goal_amphibTarget == 0 and swimmerCount >= groundCount) then
				goal_desireSwimmers = 1
			end
				
			-- if large map and we have a few swimmers then desire them too since large
			-- map means more time
			if (fact_closestGroundDist > 400 and swimmerCount >= 2) then
				goal_desireSwimmers = 1
			end
			
			-- if we have a far greater military then the enemy and we already have decent military
			if (fact_selfValue > 1500 and fact_selfValue > fact_enemyValue*1.5) then
				goal_desireSwimmers = 1
			end
		

	end
	
	if (flyerCount > 0) then
		
		-- if the AI has lots of swimmers and ground units
		-- then don't ask for flyers unless they are highly needed
		-- or we have lots of flyers available
		goal_desireFlyers = 1
		
		if ((swimmerCount + groundCount) > 0) then
			-- if the creature choose has no flyin desire, unless its our only --....What? Bchamp 3/31/2019
			if (g_LOD > 0 and sg_goalflyer < 0.5) then
				goal_desireFlyers = 0
			end
		end
			
	end
end

function armydecisions() -- static info

	-- get the enemy with the highest military population
	fact_enemyPop = PlayersMilitaryPopulation( player_enemy, player_max )
	-- what is this AIs military population
	fact_militaryPop = PopulationActive() - NumHenchmanActive();

	local playerself = Player_Self();
	fact_enemyValue = PlayersMilitaryValue( player_enemy, player_max )
	fact_selfValue = PlayersMilitaryValue( playerself, player_max )

	-- do this, just in case someone divides by this number
	if (fact_enemyPop == 0) then
		fact_enemyPop = 1;
	end
	
	-- Should we building defensively, if not we will build at the chambers closest
	-- to our target
	icd_buildDefensively = 1
	-- or could check if we haven't been attacked in 30sec
	-- ADJUSTED UnderAttackValue() Threshold to correspond to rank and increased. Fromerly 400. 
	-- Consider upping LabUnderAttackValue? Needs testing. Bchamp
	if (LabUnderAttackValue() == 0 and UnderAttackValue() < fact_selfValue*0.5) then
		icd_buildDefensively = 0
	end

	-- Determine if our target has a good amphibian distance
	if (fact_closestGroundDist == 0 or fact_closestAmphibDist < fact_closestGroundDist*0.6) then
		-- check the difference between these closest paths if its greater then a certain
		-- threshold then try to produce more flyers and amphibs
		goal_amphibTarget = 1
	end
	
	if (g_LOD > 0) then
	
		-- set the timer back to normal every frame
		icd_bestCreatureWaitTime = 10
		-- if lab is under attack, build whatever you can, reduce the wait timer
		if (LabUnderAttackValue() > 0) then
			icd_bestCreatureWaitTime = 5
		end
	
	end
	
	if (g_LOD == 3) then
		if Enemy.NumFoundry >= 2 then
			if (fact_selfValue*1.2 < Enemy.MilitaryValue) then --if you normally wouldn't engage the enemy, raid foundries
				SetTargetTypePriority( Foundry_EC , 60000)
				icd_engageEnemyValueModifier = 0.8
			else
				SetTargetTypePriority( Foundry_EC , 5000)
				icd_engageEnemyValueModifier = 1.2
			end
		end
		--go for lab if enemy is weak
		if Enemy.MilitaryValue < fact_selfValue/10 then
			SetTargetTypePriority( Foundry_EC , 100)
			SetTargetTypePriority( Lab_EC , 60000)
			icd_engageEnemyValueModifier = 0.8
		end
		--if you have tons of units, might as well attack
		if PopulationActive() >= PopulationMax()*0.9 then
			icd_engageEnemyValueModifier = 0.8
		else
			icd_engageEnemyValueModifier = 1.2
		end
	end

	-- determine what creature types we should build
	Logic_creatureTypeDesire()
		
end

function Logic_ChamberChoice()
	-- 4/24/2022 the variable icd_chooseDefendChamber doesn't seem to work

	-- must choose defend chamber or offensive chamber
	-- Noticed problem where AI would queue 9+ units at single chamber at lab, when it could be building units at multiple chambers

	if (LabUnderAttackValue() > 0) then
		if icd_chooseDefendChamber == 0 then
			icd_chooseDefendChamber = 1
		elseif (NumCreaturesQ() - NumCreaturesActive() > 3) then --Build at other chambers if already building from defend chamber with large queue
			icd_chooseDefendChamber = 0
		end
		return
	end

	--if you have a lot of stuff queued at offensive chambers, build at defensive chambers for variety
	if (icd_chooseDefendChamber == 0) and (NumCreaturesQ() - NumCreaturesActive() > numActiveChambers) then
		icd_chooseDefendChamber = 1
		return
	end

	icd_chooseDefendChamber = 0
	
end

function docreaturebuild()
		
	armydecisions();

	-- check game state and change group sizes
	Logic_military_setgroupsizes()
	
	-- check game and set the appropriate offence defence percentages
	Logic_military_setattackpercentages()
	
	Logic_military_setdesiredcreatures()
	
	Logic_military_setattacktimer()
	
	-- check to see if we have any population room left
	local military_cap = PopulationMax() - sg_desired_henchman;
	
	local total_creature_pop = PopulationQ() - NumHenchmanQ()
	
	military_purchase_creatures()

end



function Logic_military_setgroupsizes()
	
	-- group size should be related to mapsize
	-- and economic situation
	
	local groupoffset = 0
	local valueoffset = 0
	local curRank = GetRank()
	local rankMultiplier = rankValue[curRank]

				
	-- increase my troop counts if the enemy has more units than I do
	if (g_LOD > 0) then
		
		-- the closer we are the smaller the earlier groups can be
		if (fact_closestGroundDist < 300) then
			groupoffset = 3
			valueoffset = groupoffset*rankMultiplier
		elseif (fact_closestGroundDist < 600) then
			groupoffset = 4
			valueoffset = groupoffset*rankMultiplier
		elseif (fact_closestGroundDist < 900) then
			groupoffset = 5
			valueoffset = groupoffset*rankMultiplier
		else
			groupoffset = 6
			valueoffset = groupoffset*rankMultiplier
		end
		
		local moreEnemies = PlayersAlive( player_enemy )-PlayersAlive( player_ally )
		
		-- in FFA games, create bigger groups
		if (moreEnemies > 0) then
			groupoffset = groupoffset + 1 + moreEnemies/2
			valueoffset = groupoffset*rankMultiplier
		end
		
		groupoffset = groupoffset + 1;
		
		if (fact_enemyValue > fact_selfValue) then
			groupoffset = groupoffset + g_LOD;
			valueoffset = groupoffset*rankMultiplier
		end
	else
		-- for easy
		groupoffset = 1 -- this sets a 3-7 group size
		valueoffset = 0 -- this is 200-1400 group value
	end
	

	-- initial group sizes for all LODs
	icd_groundgroupminsize = groupoffset;
	icd_groundgroupmaxsize = max(groupoffset*2+6, NumCreaturesActive()*0.65);
	
	icd_groundgroupminvalue = icd_groundgroupminsize * rankMultiplier;
	icd_groundgroupmaxvalue = icd_groundgroupmaxsize * rankMultiplier;
		
	-- increase group sizes over time - or based on income the more money we have coming in
	-- the bigger the groups should be - if we start with tons of money, group sizes
	-- should be accounted for
	
	-- modified rules for easy and max group sizes
	if (g_LOD==0) then
		icd_groundgroupmaxsize = 5
		if (fact_enemyValue == 0) then
			icd_groundgroupmaxsize = 4
		elseif (fact_enemyValue > 1200 or GameTime() > (11*60)) then
			icd_groundgroupmaxsize = 6
		elseif (fact_enemyValue > 3000 or GameTime() > (22*60)) then
			icd_groundgroupmaxsize = 8
		end
		
	end
	

	
	----------------------------------------------------------------------------------
	-- Added by Bchamp 4/22/2019 to ensure that groupminvalue is used to account for spam or low power units. Also adjusted for rank
	if (g_LOD >= 2) then

		icd_groundgroupminsize = groupoffset + 1 + rand3b; 
		icd_groundgroupmaxsize = (groupoffset+3+curRank)*2+6;
		
		icd_groundgroupminvalue = icd_groundgroupminsize*rankMultiplier;
		icd_groundgroupmaxvalue = icd_groundgroupmaxsize*rankMultiplier*2;

		-- Added by Bchamp 4/1/2019 to keep high pressure on opponent when winning
		local unitCount = PlayersUnitTypeCount( Player_Self(), player_max, sg_class_ground )
		if (fact_selfValue > fact_enemyValue*1.5 and unitCount > (icd_groundgroupminsize*1.5)) then
			icd_groundgroupminsize = rand4a + 1
			icd_groundgroupminvalue = icd_groundgroupminsize*rankMultiplier
		end
	end
	----------------------------------------------------------------------------------

	--air groups should be larger
	icd_airgroupminsize = icd_groundgroupminsize*1.5
	icd_airgroupminvalue = icd_groundgroupminvalue*1.5

	icd_airgroupmaxsize = icd_groundgroupmaxsize*1.5

end

function removeExtraGroundCreatures()

	if (sg_groundDist == 0 and sg_amphibDist > 0 and LabUnderAttackValue() == 0) then
		local playerindex = Player_Self()
		local gcount = PlayersUnitTypeCount( playerindex, player_max, sg_class_ground )
		local acount = PlayersUnitTypeCount( playerindex, player_max, sg_class_amphib )
		gcount = gcount - acount
		-- if num creatures is a good portion of our desired army - increase limit for more amphib/flyers
		if (gcount > sg_creature_desired*0.5) then
			
			local diffA = PopulationMax() - PopulationActive() 
			local diffB = PopulationMax() - fact_militaryPop
			if ( diffA < 5 or diffB <= 12) then
				KillGroundUnits( 5 )
			end
		end
	end

end

function Logic_islandmaplogic()

	-- do we do island map logic ( if lab under attack stop this )
	if (sg_groundDist == 0 and sg_amphibDist > 0 and LabUnderAttackValue() == 0) then
		
		local curRank = GetRank()
		-- do we have a swimmer of flyer available yet
		if (curRank < fact_lowrank_amphib and curRank < fact_lowrank_flyer and curRank < fact_lowrank_swimmer) then
		
			-- we should not build more then 8 guys, only for defence
			if (g_LOD == 0 and sg_creature_desired > 4) then
				sg_creature_desired = 2;
			end
			
			if (g_LOD  > 0 and sg_creature_desired > 8) then
				sg_creature_desired = 2;
			end
		
			return 1
		else
			
			local playerindex = Player_Self()
			local gcount = PlayersUnitTypeCount( playerindex, player_max, sg_class_ground )
			local acount = PlayersUnitTypeCount( playerindex, player_max, sg_class_amphib )
			gcount = gcount - acount
			-- if num creatures is a good portion of our desired army - increase limit for more amphib/flyers
			if (gcount > sg_creature_desired*0.6) then
				sg_creature_desired = sg_creature_desired + sg_creature_desired*0.5
				
				
			end
			
			-- no return - we want the capping logic
		end
		
	end
	
	return 0

end


function Logic_military_setdesiredcreatures()

	local popmax = PopulationMax();
	local gametime = GameTime()
	local numCreatures = NumCreaturesActive()
	
	if (g_LOD == 0) then
	
		local numSBTower = PlayersUnitCount( player_enemy, player_max, SoundBeamTower_EC )
		
		sg_creature_desired = 7 + numSBTower/2
		
		if (gametime > (15*60)) then
			-- for every 4 minutes after 15 minutes increase desire by 1
			sg_creature_desired = sg_creature_desired+((gametime-(15*60))/(4*60))
		end
				
		-- unit cap, grow at same rate as enemy (should do this per type)
		if (fact_militaryPop >= sg_creature_desired and (fact_enemyValue >= fact_selfValue*1.3 or fact_enemyPop >= fact_militaryPop*1.5)) then
			-- desire for more than what ya got
			sg_creature_desired = numCreatures + 1;
		end
		
		-- if AI has passed its desired rate and has more value then opponent
		-- it should slow down production
		
	elseif (g_LOD == 1) then
	
		local numSBTower = PlayersUnitCount( player_enemy, player_max, SoundBeamTower_EC )
		
		sg_creature_desired = 10 + numSBTower/2
		
		if (gametime > (11*60)) then
			sg_creature_desired = sg_creature_desired+((gametime-(8*60))/(2*60))
		end
				
		-- unit cap, grow at same rate as enemy (should do this per type)
		if (fact_militaryPop >= sg_creature_desired and (fact_enemyValue >= fact_selfValue*1.1 or fact_enemyPop >= fact_militaryPop*1.2)) then
			-- desire for more than what ya got
			sg_creature_desired = numCreatures + 2;
		end

	else
		
		sg_creature_desired = popmax;
	end

	-- make sure to leave enough room for 10 henchmen..should we leave room for sg_desiredhenchman insetad? --bchamp 3/31/2019
	if (sg_creature_desired >= (popmax-10)) then
		sg_creature_desired = popmax-10
	end
	
	removeExtraGroundCreatures() --This kills own ground creatures if we have enough in order to make room for amphib and air. Should AI be killing own units? Bchamp 3/31/2019
	

	------------------------------------------------------------------------------
	-- RULES BELOW - these all put caps on creatures to give money to other areas
	-- ORDER MATTERS -------------------------------------------------------------
	------------------------------------------------------------------------------

	--this pauses creature production when resources are low and no hench queued to make sure we are building hench
	if Self.MilitaryValue > 1.5*Enemy.MilitaryValue + 500 and Self.Coal < Self.Rank*100 and NumHenchmenGuarding() <= 3 and Self.QdHenchmen == 0 then
		if Self.MilitaryValue > 1.5*LabUnderAttackValue() then
			sg_creature_desired = 0
		end
	end

	-- run some island map logic. If no amphib or fliers available, only builds a few creatures for defense then returns 1. 
	if (Logic_islandmaplogic()==1) then
		return
	end
	
	-- determine rank and standing to see if we should cap our units 
	-- so that we try to rank up
	local curRank = GetRank()

	-- if we have lots of coal and elec, build more units. 
	-- consider setting escrow percentages here
	-- moved up by Bchamp
	if (g_LOD >= 2 and ScrapAmount() > 1000 and ElectricityAmount() > 1000) then
		-- make creatures, until this money drops down
		sg_creature_desired = popmax-10
		-- for standard, don't go too crazy
		if (g_LOD == 1) then
			sg_creature_desired = popmax-20
		end
		return
	end

	-- don't build more then 2 rank1s if you are not underattack - only used on standard
	if (g_LOD == 1 and curRank == 1 and UnderAttackValue() < 150 and ScrapAmountWithEscrow() < 1000) then
		sg_creature_desired = rand100a*0.06 - 3
		if sg_creature_desired < 0 then
			sg_creature_desired = 0
		end
		return
	end
	
	-- if we are under attack and we are the underdogs, set no limit, build more units
	if (UnderAttackValue() > 100 and fact_enemyValue*1.5 > fact_selfValue ) then
		return
	end

	-- if we are at least L3 and comfortable but do not have Henchmen Yoke, slow down creature production. 
	-- Added by Bchamp 4/1/2019. Tested and this does help AI research Yoke about a minute faster.
	if (g_LOD >= 2 and curRank >= 3 and ResearchCompleted(RESEARCH_HenchmanYoke) == 0) then
		if (UnderAttackValue() < 100 and NumCreaturesActive() > 5 and NumHenchmanActive() > 18 and fact_selfValue > fact_enemyValue) then
			sg_creature_desired = numCreatures + 1
			return
		end
	end

	-- if we are at max rank - don't put any limits on creature count
	if (fact_army_maxrank == curRank) then
		return
	end
	
	-- how many ranks behind are you from chosen enemy
	local chosenEnemy = GetChosenEnemy()
	local maxEnemyRank = PlayersRank( chosenEnemy, player_max )
		
	-- am I 2 ranks below, don't build more military, try to rank up
	if (g_LOD > 0 and maxEnemyRank - curRank > 1) then
		sg_creature_desired = 6;
		return
	end
	
	-- I'm within 1 rank of highest rank - if enemy has more than 20% better units, try to build as many as them
	if (fact_enemyValue > fact_selfValue*1.2) then
		return
	end
			
	-- not underattack or we have a better army, so cap unit production for the time being so
	-- we can leave money for ranking up
	-- if (ResearchQ(RESEARCH_Rank5)==0 and fact_selfValue > fact_enemyValue*2) then
	-- 	-- if have a low desire, keep it there otherwise cap it
	-- 	if (sg_creature_desired > 13) then
	-- 		sg_creature_desired = 13;
	-- 	end
	-- end
	
end

-- when the next wave attack will happen (global var)

-- function that gets called on a timer
function attack_now_timer()

		if PopulationActive() >= PopulationMax()*0.8 then
			save_icd_engageEnemyValueModifier = icd_engageEnemyValueModifier
			icd_engageEnemyValueModifier = 0.6
		elseif save_icd_engageEnemyValueModifier ~= nil then
			icd_engageEnemyValueModifier = save_icd_engageEnemyValueModifier
		end
			

		AttackNow();
		aitrace("Script: Attack Now")

end

function Logic_military_setattacktimer()
	
	-- when does the AI start attacking
	local timedelay = 30
	-- how often does it send another wave
	local wavedelay = 4 + rand100a*0.3
	
	-- check level of difficult and modify when the AI first attacks if not
	-- attacked by the player
	if (g_LOD == 0) then
		timedelay = 60*6.5 + rand100a*2.4
		wavedelay = 60*2.5 + rand100a*0.8
		local chosenEnemy = GetChosenEnemy()
		if (chosenEnemy ~= -1) then
			-- if the enemy has no-one or the time is greater then 12 minutes
			if (PlayersMilitaryPopulation( chosenEnemy, player_max ) == 0) then
				timedelay = 60*11
			end
		end
	elseif (g_LOD == 1) then
		timedelay = 60*4.5 + rand100a*1.2
		wavedelay = 60*2 + rand100a*0.6
	end
	
	if (g_LOD >= 2) then
		local moreEnemies = PlayersAlive( player_enemy )-PlayersAlive( player_ally )
		if (moreEnemies > 0) then
			-- delay initial attack
			timedelay = timedelay + rand100a*moreEnemies/2
		else --Added 4/1/19 by Bchamp to shorten wave delay if winning to keep pressure on opponent...
			--This causes AI to "jitter" when attack now timer is too short. If no issues, delete later Bchamp 5/19/22
			local unitCount = PlayersUnitTypeCount( Player_Self(), player_max, sg_class_ground )
			if (fact_selfValue > fact_enemyValue*1.5 and unitCount > (icd_groundgroupminsize*1.5)) then
				wavedelay = wavedelay --10 + rand100a*0.10
			end
		end
	end
	
	local gametime = GameTime()
	wavedelay = 200
	-- has the start time gone by or have we received a certain level of damage
	if (gametime >= timedelay or (g_LOD > 0 and DamageTotal() > 300)) then
			
		if (IsTimerFuncRegistered("attack_now_timer") == 0) then
			aitrace("Script: Attacktimer added")
			-- this will also call attacknow instantly
			RegisterTimerFunc("attack_now_timer", wavedelay )
		end
		
	end
	
end

function Logic_military_setattackpercentages()
	
	icd_groundattackpercent = 100
	icd_waterattackpercent = 100
	icd_airattackpercent = 100
	
	-- how many times more military do we have
		
	if (g_LOD==0 and GameTime() < 20*60) then
		icd_groundattackpercent = 30
		icd_waterattackpercent = 30
		icd_airattackpercent = 30
	end
		
	-- look to number of enemies and allies to help determine percentages
	local numEnemies = PlayersAlive( player_enemy )
	local numAllies = PlayersAlive( player_ally )
	
	-- if the AI has more than 1.5 times more creatures than enemy then all out attack. Modified by Bchamp 4/1/2019
	if (g_LOD>1 and fact_selfValue > ((fact_enemyValue+300)*1.5) and numAllies >= numEnemies) then
		AttackNow()
		icd_groundattackpercent = 100
		icd_waterattackpercent = 100
		icd_airattackpercent = 100
	end
	
	-- ...its underattack give some creatures to defence
	if (UnderAttackValue() > fact_selfValue*0.5) then
		-- if we are weaker than place more on defence
		if (fact_selfValue < fact_enemyValue) then
			icd_groundattackpercent = 40
			icd_waterattackpercent = 40
			icd_airattackpercent = 40
		else
			icd_groundattackpercent = 60
			icd_waterattackpercent = 60
			icd_airattackpercent = 60
		end
	end
	
	-- if lab is underattack don't send any more attackers until its
	-- dealt with
	if (LabUnderAttackValue() > 200) then
		icd_groundattackpercent = 0
		icd_waterattackpercent = 0
		icd_airattackpercent = 0
	end
			

	-- If there is nothing to defend....just all out attack. Good for Destory Enemy Base or special gameplay modes
	if (NumBuildingActive( Lab_EC ) == 0) then
		
		icd_groundattackpercent = 100
		icd_waterattackpercent = 100
		icd_airattackpercent = 100
	end
	
end

function military_purchase_creatures()

	-- do this in a cascading way
	
	local playerindex = Player_Self()
	local curRank = GetRank()

	if ScrapAmount() < Self.Rank*250 then
		dobuildcreatures()
	else --do this twice if you have a lot of resources
		dobuildcreatures()
		dobuildcreatures()
	end

end

rawset(globals(), "dobuildcreatures", nil )

function dobuildcreatures()
	
	if Self.TotalChambers == 0 then
		return
	end
	
	-- Army_CreatureCostQ( Player_Self(), sg_class_ground )
	local creaturesQ = NumCreaturesQ();
	local totalChambers = Self.TotalChambers
	local curRank = GetRank()

	-- Do not queue more units than you have chambers (incorporating rank). Saves resources for other activities. Bchamp 4/5/2019
	if (g_LOD >= 2 and (Self.QdCreatures) >= max((totalChambers + curRank - 1),5) ) then
		--if you have a ton of resources, don't limit queued creatures
		if Self.Rank < fact_army_maxrank and ScrapAmount() < curRank*400 then
			return
		end
	end

	if (Self.NumCreatures < sg_creature_desired) then
		--alternate chambers when a lot of creatures queued...not sure which icd works, but it seems to be working well 5/20/22
		if (NumCreaturesQ() - NumCreaturesActive() >= 5) then
			if icd_buildDefensively == 0 then
				icd_buildDefensively = 1
				icd_chooseDefendChamber = 1
			else 
				icd_buildDefensively = 0
				icd_chooseDefendChamber = 0
			end
		end
		xBuildCreature( sg_class_ground ) --doesn't matter if this is ground or swimmer or anything, it will still work
		--aitrace("Script: build creature "..(creaturesQ+1).." of "..sg_creature_desired);

	end
end

-- this function should try to determine who we should target as an enemy
-- this assumes we are not defending ourselves
-- Chooses enemy with the highest military population
-- This function is used nowhere in the AI luas.....
function chooseenemy() -- return the enemies index

	local currentMax = -1
	local currentEnemy = -1
	
	local i = 0
	local t = PlayersTotal()
	
	while ( i < t ) do
	
		-- test to see if this enemy is the enemy we want to attack
		if (Player_IsEnemy( i )	== 1) then
			local pop = PlayersMilitaryPopulation( i, player_max )
			if ( pop > currentMax ) then
				currentMax = pop
				currentEnemy = i
			end
		end
	
		i=i+1
	end
	
	return currentEnemy

end

