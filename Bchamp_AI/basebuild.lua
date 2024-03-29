--TO DO--
--If attacking and selfValue >>> enemyValue, build CC near enemy base???--


aitrace("Script Component: Base building logic")

function init_basebuild()

	--dofilepath("data:ai/rank2rush.lua")
	aitrace("init_basebuild()")
	
	-- flags for turning on and off certain features of the AI
	sg_buildstructure = {}
	sg_buildstructure[Foundry_EC] = 1
	sg_buildstructure[RemoteChamber_EC] = 1
	sg_buildstructure[SoundBeamTower_EC] = 1
	sg_buildstructure[AntiAirTower_EC] = 1
	sg_buildstructure[VetClinic_EC] = 1
	sg_buildstructure[WaterChamber_EC] = 1
	sg_buildstructure[ElectricGenerator_EC] = 1
	sg_buildstructure[Aviary_EC] = 1
	sg_buildstructure[ResourceRenew_EC]=1
	sg_buildstructure[GeneticAmplifier_EC]=1
	sg_buildstructure[LandingPad_EC] = 0
	sg_buildstructure[BrambleFence_EC] = 1
	
	sg_lightningrod_cap = 4
	
	-- the distance from the base the AI will build its chamber (using PH_OutsideBase flag)
	icd_chamberDistFromBase = 35
	
	if (g_LOD == 0 ) then
		RegisterTimerFunc("dobasebuild", 8.0 )
	else
		RegisterTimerFunc("dobasebuild", 3.0 )
	end

end



function NumChambers()
	
	return NumBuildingActive( RemoteChamber_EC )+NumBuildingActive(Aviary_EC)+NumBuildingActive(WaterChamber_EC)
	
end

function IsChamberBeingBuilt()

	if (NumBuildingQ( RemoteChamber_EC) - NumBuildingActive( RemoteChamber_EC)) > 1 then
		return 1
	end
	if (NumBuildingQ( WaterChamber_EC) - NumBuildingActive( WaterChamber_EC)) > 1 then
		return 1
	end
	if (NumBuildingQ( Aviary_EC) - NumBuildingActive( Aviary_EC)) > 1 then
		return 1
	end
	return 0
end

function doupgrades()

	local erate = ElectricityPerSecQ()
	
	if (erate >= sg_desired_elecrate) then
	 	return
	end
	
	-------------------------------------------------------------------------------
	-- Added by Bchamp 4/1/2019 to speed up getting Henchmen Yoke -----------------
	-- 17 is the erate for 4 rods + fully upgraded generator without grid upgrade -
	local curRank = GetRank()
	if (g_LOD >= 2) then
		if (ResearchQ(RESEARCH_HenchmanYoke) == 0 and curRank >= 3 and erate > 17) then
			return
		end
	end
	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------


	-- LOGIC ? 
	-- try for rank2 first, but if for some reason we can't get there than I guess
	-- we should upgrade the egen ? on bigger maps maybe i'd get the upgrades first?
	-- if our army is elec heavy i'd also get more elec too, even more than 14 per sec
	-- this 14 needs to be worked out based on number of geysers and army type
		
	-- determine if we should build another egen or upgrade
	if (NumBuildingActive( ElectricGenerator_EC ) > 0 and curRank >= 2) then
		
		 if (CanUpgradeWithEscrow( UPGRADE_EGen ) == 1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xUpgrade( UPGRADE_EGen );
			aitrace("Script: upgrade egen");
		end
	end
end

-- check to see if we should build a vetclinic or genamp
function checkToBuildAdvancedStructures( extraoffset )
	
	-- check for rank3 unless we are going for an upgraded early rank tactic?
	if (g_LOD>0 and ResearchCompleted(RESEARCH_Rank2)==0) then
		return 0
	end
	
	local offset = extraoffset
	
	local moreEnemies =PlayersAlive( player_enemy )-PlayersAlive( player_ally )
	
	-- faster game - faster attack - less frills
	if (g_LOD > 0 and fact_closestGroundDist < 370 and moreEnemies <= 0) then
		-- only build on small 1on1 map if we have tons of military
		offset = offset + 5
	end
	
	-- make this more available in the lower levels
	if (g_LOD == 0) then
		offset = offset - rand100a/8
	elseif (g_LOD == 1) then
		offset = offset - rand100a/20
	elseif (g_LOD >= 2) then
		offset = offset + rand100a/20
	end
	
	-- if AI has tons of money - no need to check military counts - AI should be building creatures
	if (ScrapAmountWithEscrow() > 1000 and NumChambers() > 0) then
		offset = offset - 8
	end
	
	-- if we don't have much of military then don't build a genamp
	if (fact_militaryPop < (9+offset) or fact_selfValue < (1500+offset*200) or fact_selfValue < fact_enemyValue*0.6) then
		return 0
	end

	-- if we are underattack do not purchase
	if (UnderAttackValue() > 0) then
		return 0
	end
	
	return 1
end

function dogeneticamplifier()
	
	--don't build before a foundry
	if (g_LOD > 0 and NumBuildingActive( Foundry_EC ) == 0) then
		return
	end

	local numCreaturesNeeded = 7 + rand4c;
	
	-- extra check - should check for HaveElectricityPreqrequisite instead of just having an egen - no ElecNeed
	 if (NumChambers() > 0 and NumCreaturesActive() >= numCreaturesNeeded) then
		-- typical check for building
		if (NumBuildingQ( GeneticAmplifier_EC ) < 1 and CanBuildWithEscrow( GeneticAmplifier_EC )==1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( GeneticAmplifier_EC, PH_Best );
			aitrace("Script: Build genetic amplifier")
			return 1
		end
	end
	
	return 0
end


function dolightningrods()

	local erate = ElectricityPerSecQ()
	local rank2rush_desired_erate = 4
	local curRank = GetRank()
	local numHenchman = NumHenchmanActive()	
	local numActive = NumBuildingActive( ResourceRenew_EC )
	local numQ = NumBuildingQ( ResourceRenew_EC )
	local numRods = 0

	-- and NumHenchmanQ() > numHenchman
	if (numHenchman >= 3 + rand2b) then
		numRods = 1
	end

	if ((numHenchman > sg_henchmanthreshold + rand1c) or (numActive == 1 and ScrapAmount() > 250 and ElectricityAmount() < 275 and NumHenchmanQ()-numHenchman > 0)) then
		numRods = 2
	end

	if (ResearchQ(RESEARCH_Rank2) == 1) then
		numRods = 3
		if ScrapAmount() > 400 then
			numRods = 4
		end
	end
		
	-- if lab is under attack by more than 3 times our military value
	if ( not(goal_needelec==2 and ElectricityAmountWithEscrow() < 50 and fact_selfValue < 200) and LabUnderAttackValue() > 0) then
		return
	end
	
	-- if these numbers are different, then a rod is being built (only build one at a time)
	if ( (numQ-numActive) > 0) then
		return
	end
	
	-- should only really build 2 rods before level 2
	if (NumBuildingActive( ResourceRenew_EC ) >= 2 and  ResearchQ(RESEARCH_Rank2)==0) then
		return
	end
	
	-- LOGIC - only build one unless we can't build an egen and we need more elec
	
	if (numQ < numRods and CanBuildWithEscrow( ResourceRenew_EC )==1) then
		ReleaseGatherEscrow();
		ReleaseRenewEscrow();
		xBuild( ResourceRenew_EC, 0 );
		aitrace("Script:build rod for rate "..(erate+2).." of "..sg_desired_elecrate);
	end
end



function dosoundbeamtowers()

	sg_needSBTower = 0

	-- constants
	local buildTowers = 0;
	local curRank = GetRank()
	local underAttackVal = UnderAttackValue()
	local flyerAttackPercentage = 0

	if (underAttackVal > 0) then
		flyerAttackPercentage = UnderFlyerAttackValue() / underAttackVal
	end

	
	-- early game (not research first rank yet)
	if (curRank == 1 and fact_selfValue < 400) then
		local randval = 300 + rand100b * 3
		if (fact_enemyValue > randval or underAttackVal>90) then
			buildTowers = 1
		end
	end
	
	-- added by LBFrank 01/02/19 Possibly stops AI from making pointless towers at L1
	if (curRank == 1 and underAttackVal == 0) then
		buildTowers = 0
	end
	
	-- NOTE: could easily add code to detect if attacking enemy has lots of artillery and/or flyers
	-- which would lower the desire for soundbeam towers
	
	if (flyerAttackPercentage < 0.6) then
		-- if we have no creatures and we are underattack and we have no spawners then build 
		-- sound beam towers - this is check at every rank
		if (curRank < 3 and underAttackVal > 150 and fact_selfValue < underAttackVal) then
			buildTowers = 1
		end
		
		if (underAttackVal > curRank*200 and NumHenchmenGuarding() >= 4) then
			buildTowers = 1
		end

		if (underAttackVal > 120 and NumChambers() == 0) then
			buildTowers = 1
		end

		-- if we are being attacked by more than 1.5 times the AIs military worth
		if (g_LOD < 2 and ResearchCompleted( RESEARCH_TowerUpgrade ) == 1 and underAttackVal > fact_selfValue*1.3 ) then
			buildTowers = 1
		end
	end
	
	local numTowerActive = NumBuildingActive( SoundBeamTower_EC )
	if (fact_closestGroundDist ~= 0) then
		if (NumHenchmanActive() > 5 and fact_closestGroundDist < 150 and numTowerActive<1 and curRank==1) then
			buildTowers = 1
		end
	end
	
	local numEnemyCamo = PlayersUnitTypeCount( player_enemy, player_max, sg_class_camoflauge )
	local numEnemySonic = PlayersUnitTypeCount( player_enemy, player_max, sg_class_sonic )
	
	if g_LOD >= 2 then
		-- check for camo and digger units
		if (curRank < 3 and numEnemyCamo > (1+ rand3a)) then
			buildTowers = 1
		elseif (numEnemyCamo > 7) then
			buildTowers = 1
		end

		-- added by LBFrank 3/31/19 to check for sonic units (useful in the wake of L2/L3 sonic)
		if (curRank < 4 and numEnemySonic > (3 + rand2c)) then
			buildTowers = 1
		elseif (numEnemySonic > 7) then
			buildTowers = 1
		end

		if underAttackVal > fact_selfValue*0.8 then
			buildTowers = 1
		end
	end

	if (buildTowers == 1) then
	
		local desiredAmount = 1
		if curRank >= 2 and rand100b > 50 then
			desiredAmount = desiredAmount + NumBuildingActive( Foundry_EC )
		elseif curRank >= 2 and rand100c > 30 then
			desiredAmount = desiredAmount + CoalPileWithDropOffs()
		end

		if curRank >= 4 then
			desiredAmount = desiredAmount + curRank - 2
		end

		if (curRank<3 and underAttackVal>400 and fact_selfValue < 400) then
			desiredAmount = desiredAmount+1
		elseif (curRank >= 3 and underAttackVal > 1200) then
			desiredAmount = 0 --don't build when under a large attack, AI are not smart enough to micro these situations and end up wasting resources.
		end
		
		if g_LOD >= 2 then
			if numEnemySonic > 25 then
				numEnemySonic = 25
			end
			desiredAmount = desiredAmount + numEnemySonic/5

			if (ScrapAmount() > curRank*500) and (NumCreaturesQ()-NumCreaturesActive() > curRank+2) then
				desiredAmount = desiredAmount + 3
			end
		end

		--don't build if there is a lot of enemy artillery
		local enemyArtilleryValue = PlayersUnitTypeValue( player_enemy, player_max, sg_class_artillery )
		local enemyArtilleryPercent = enemyArtilleryValue/fact_enemyValue
		if (enemyArtilleryPercent > 0.5) and (enemyArtilleryValue > curRank*250) then
			return 0
		elseif (enemyArtilleryValue > curRank*250) then
			desiredAmount = desiredAmount - 2
		end
			
		--don't build more than desired amount
		if NumBuildingQ( SoundBeamTower_EC ) >= desiredAmount then
			return 0
		end

		-- don't build more than one at a time, if so, build a second creature chamber on hard difficulty
		-- modified by bchamp 10/1/2018 to stop AI from building a ton of SB towers when they really need to build units
		local numtowersInProgress = NumBuildingQ( SoundBeamTower_EC ) - numTowerActive
		if (numtowersInProgress > 0) then
			if (g_LOD >= 2 and NumBuildingQ( RemoteChamber_EC ) < 2 and CanBuild( RemoteChamber_EC ) == 1 ) then
				xBuild( RemoteChamber_EC, ChamberLocation() );
				aitrace("Script: Build second defense creature chamber")
				return 1
			end
		end
		

		if (CanBuildWithEscrow( SoundBeamTower_EC )==1) then
			-- ReleaseGatherEscrow();
			-- ReleaseRenewEscrow();
			xBuild( SoundBeamTower_EC, PH_DefendSite );
			aitrace("Script:build sound beam tower "..(numTowerActive+1).."of "..desiredAmount);
			return 1
		else
			aitrace("Script:could not afford tower");
			sg_needSBTower = 1
			return 0
		end
		
	end

end

function doantiairtowers()

	-- specify how many sound beam towers should be built at each expansion point	
	local dmgFromFlyer = DamageFromFlyer()
	local enemyFlyers = PlayersUnitTypeCount( player_enemy, player_max, sg_class_flyer );
	local enemyFlyerValue = PlayersUnitTypeValue( player_enemy, player_max, sg_class_flyer );
	local enemyFlyerPercent = enemyFlyerValue/Enemy.MilitaryValue

	-- if AI has not been attacked by flyers yet or they just have lots hidden away
	if (dmgFromFlyer == 0 and enemyFlyers < (5+( rand100a*0.06))) then
		return
	end
	
	-- if the enemies have no flyers, no need to build AA for now
	if (enemyFlyers == 0) then
		return
	end
	


	-- constants
	local numtowers = 2+enemyFlyerValue/1000; --Updated by Bchamp 2/15/2020
	local numActive = NumBuildingActive( AntiAirTower_EC )
	local numQueued = NumBuildingQ( AntiAirTower_EC )
	local numtowersBeRequested =  numQueued - numActive
	

	--added for Rank 2 Flyers 2/20/2022
	if (GetRank() == 2) then
		numtowers = 1 --build at least one AA if there are enemy flyers
		if (enemyFlyers > 5) then
			numtowers = 1 + enemyFlyerValue/1000 - (NumBuildingActive( SoundBeamTower_EC )/3) --SB towers will count as 1/3 an AA at L2
		end
	end


	-- make sure one more is being built if we are underattack by flyers
	if ((NumUnprotectedAASite() > 0 or NumSitesWithZeroAA() > 0) and numQueued == numtowers) then
		numtowers = numActive+1
	end
	
	if enemyFlyerPercent < 0.4 and numActive > 10 then
		numtowers = numtowers*0.7
	end

	if (numQueued < numtowers and CanBuildWithEscrow( AntiAirTower_EC )==1) then
		
		-- ReleaseGatherEscrow();
		-- ReleaseRenewEscrow();
		xBuild( AntiAirTower_EC, PH_DefendSite );
		aitrace("Script:build antiair tower");
		return
	end

end

function dovetclinic()


	 -- extra check to make sure we have a few creatures, lab isn't under attack, and we have henchmen. Bchamp 3/31/2019
	if (LabUnderAttackValue() > fact_selfValue/2 or NumCreaturesActive() < ( rand4a + rand2b + 1) or (ScrapPerSec() < 15 and ElectricityPerSecQ() < 8)) then
		return
	end

	-- Do not build more than 1 Research Clinic at a time -- Bchamp 4/1/2019
	if (NumBuildingQ( VetClinic_EC ) > NumBuildingActive( VetClinic_EC )) then
		return
	end

	local curRank = GetRank()
	

	local maxVetClinic = 0
	--Don't make clinic too early Bchamp 12/16/2022
	if (Self.Rank <= 2 and Self.NumChamber >= 1 and Self.NumCreatures >= 7 + rand3c and Self.MilitaryValue > Enemy.MilitaryValue*0.85) then
		maxVetClinic = 1
	end
	
	--Add randomization to number of vet clinics built. Bchamp 3/31/2019
	if (curRank > 2 and g_LOD >= 2) then
		-- 30% chance of building a single vet clinic. Also will only build a single clinic if doing a 1v1 on a small map.
		if ( rand100c < 30 or ((PlayersAlive( player_ally ) == 1 and PlayersAlive( player_enemy ) == 1) and fact_closestAmphibDist < 450)) then
			maxVetClinic = 1
		else
			maxVetClinic = 2
		end
	end
	
	-- If already completed all of these researches at the clinic, don't build more. This way AI doesnt keep building if you destroy clinics
	-- in the late game. Added by Bchamp 3/31/2019
	-- LBFrank 4/01/19 they may want one clinic to research tower upgrade if they have the towers for it. if not then yeah we don't need em
	if (ResearchCompleted(RESEARCH_HenchmanYoke) == 1 and ResearchCompleted(RESEARCH_HenchmanMotivationalSpeech) == 1 and ResearchCompleted(RESEARCH_StrengthenElectricalGrid) == 1 and ResearchCompleted(RESEARCH_IncBuildingIntegrity) == 1) then
		if (ResearchCompleted(RESEARCH_TowerUpgrade) == 0 and (NumBuildingActive( SoundBeamTower_EC ) + NumBuildingActive( AntiAirTower_EC )) >= 2) then
			maxVetClinic = 1
		else
			maxVetClinic = 0
		end
	end

	-- typical check for building
	if (NumBuildingQ( VetClinic_EC ) < maxVetClinic and CanBuildWithEscrow( VetClinic_EC )==1) then
		ReleaseGatherEscrow();
		ReleaseRenewEscrow();
		xBuild( VetClinic_EC, PH_Best );
		aitrace("Script: Build vetclinic")
		return 1
	end
	
	return 0
end



function dofoundry()
	
	money_on_hold = 0;

	local alwaysBuild = 0
	-- always build when we have no drop off unless when? if have tons of money and we are under attack?
	if (CoalPileWithDropOffs()==0 and (LabUnderAttackValue() <= fact_selfValue or ScrapAmountWithEscrow() < 500) ) then
		alwaysBuild = 1
	end
	
	local gatherSiteOpen = IsGatherSiteOpen()
	local numFoundries = NumBuildingQ( Foundry_EC )

	--When henchmen are under attack and can no longer mine coal at this gather site, they will build a foundry. 
	--This function can be bad because AI can waste resources on a foundry when it really needs units more than anything.
	--Changed to NumHenchmenGuarding() > 4 instead of 2. And increased UnderAttackValue() > 200 from 100..--Bchamp 3/31/2019
	if (gatherSiteOpen == 0 and NumHenchmenGuarding()>4 and UnderAttackValue() > 200) then
		alwaysBuild = 1
	end

	--Build Foundry if you are going to be able to beat attack, otherwise don't and save for units. Added 3/31/2019 by Bchamp
	if (gatherSiteOpen == 0 and NumHenchmenGuarding()>=3 and UnderAttackValue() <= 0.7*fact_selfValue) then
		alwaysBuild = 1
	end
	
	local curRank = GetRank()
	local minFoundries_LOD = g_LOD --Use Level of difficulty determining minimum number of foundries at each level. Assumes g_LOD is never more than 2
	if (minFoundries_LOD > 2) then
		minFoundries_LOD = 2
	end

	-- Have a minimum of 2 foundries if AI is at least lvl 2 
	if (curRank >= 2 and numFoundries < minFoundries_LOD) then
		if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
			alwaysBuild = 0
		else
			--Minimum of 16 henchmen before building second foundry. Also make sure foundry's are full. 3/30/2019 Bchamp
			if (numFoundries == 1 and (NumHenchmanQ() < 16 or gatherSiteOpen > 0 or NumCreaturesQ() < ( rand100a*0.05 + 1))) then
				alwaysBuild = 0
			else
				alwaysBuild = 1
			end
		end
	elseif (curRank == 1) then --if Rank is 1 and you have idle henchmen and are not under attack, build a foundry
		if (NumHenchmenGuarding() >= rand2a and gatherSiteOpen == 0 and UnderAttackValue() <= 0.5*fact_selfValue) then
			alwaysBuild = 1
		end
	end
	
	-- On larger maps, have a minimum of 3 foundries if AI is at least lvl 3. 
	-- Also need minimum number of units.
	if (fact_closestGroundDist > 500 and curRank >= 3) then
		if (numFoundries < (minFoundries_LOD + 1) and gatherSiteOpen == 0 and NumCreaturesQ() > ( rand100b*0.07 + 2)) then
			if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
				alwaysBuild = 0
			else
				alwaysBuild = 1
			end
		end
	end

	-- Have minimum 3 foundries once AI reaches Rank 4
	if (curRank >= 4) then
		if (numFoundries < (minFoundries_LOD + 1) and gatherSiteOpen == 0) then
			if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
				alwaysBuild = 0
			else
				alwaysBuild = 1
			end
		end
	end

	-- On small maps, have a minimum of 5 foundries if AI is at lvl 5
	-- is this too many on small maps?? Vacation? Ring?
	if (curRank == 5 and numFoundries < (minFoundries_LOD + 3) and gatherSiteOpen == 0) then
		if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
			alwaysBuild = 0
		else
			alwaysBuild = 1
		end
	end


	-- On large maps, have a minimum of 6 foundries if AI is at lvl 5
	if (fact_closestGroundDist > 500 and curRank == 5 and numFoundries < (minFoundries_LOD + 4)) then
		if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
			alwaysBuild = 0
		else
			alwaysBuild = 1
		end
	end
	
	----------------------------------------------------------------------------------------------
	-- Added by Bchamp 4/1/2019 to speed up henchmen yoke. Would rather get 1.5x resources from
	----- yoke rather than spend money on foundry and henchmen to fill it ------------------------
	if (curRank >= 3 and ResearchQ(RESEARCH_HenchmanYoke) == 0 and numFoundries > 1 and g_LOD >= 2) then
		alwaysBuild = 0
		if (ScrapPerSec() > 22) then --10 henchmen mining at 5 coal piles ~12 ScrapPerSec
			return
		end
	end
	----------------------------------------------------------------------------------------------


	-- check for case where there are a bunch of henchmen who could use a better spot to gather
	
	if (alwaysBuild == 0) then
		
		-- need to check to see if we are ready to expand
		-- need to see if we need coal badly and we have no piles
		-- to gather from cuz they are threatened
		
		if (NumChambers() == 0) then
			return
		end
			
		--Work In Progress Code
		--Trying to figure out how to stop AI from continually trying to build Foundry when its unsafe due to enemy units.
		--This code here was to test if global counter variables worked. They appear to.
		--if (sg_foundryAttempts > NumBuildingQ( Foundry_EC ) and UnderAttackValue() > 100) then
		--	return
		--end

		-- build foundry more on smaller maps
		-- build foundry when we have a military advantage
		-- build foundry when need more money
		-- build foundry even if we are underattack (as henchmen escape) maybe
		--   we can check for a low scrap per sec and if underattack
		
		-- if lab is under attack and we have guys gathering
		if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
			return
		end
		
		-- if we are a small map, then we need a few extra creatures to expand
		if (fact_closestAmphibDist < 350 and fact_selfValue < 1200 ) then
			return
		end
		
		-- this should take rank into consideration OR hench building should
		if (fact_closestAmphibDist < 600 and fact_selfValue < 1000) then
			return
		end
		
		-- if there still is a gathersite with space left then hold off on the foundry
		if (gatherSiteOpen == 1) then
			return
		end
		
		if (NumHenchmenGuarding() < 1) then
		 	return
		end
		
		-- if have less henchmen then our threshold, no need to expand
		if (NumHenchmanActive() <= sg_henchmanthreshold and CoalPileWithDropOffs()>0) then
			return
		end
	end

	--Only build one foundry at a time 1/4/2019 Bchamp
	if (NumBuildingQ( Foundry_EC ) - NumBuildingActive( Foundry_EC ) > 0) then
		return
	end

		if (CanBuildWithEscrow( Foundry_EC ) == 1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( Foundry_EC, PH_Best );
			aitrace("Script: build foundry");
			sg_foundryAttempts = sg_foundryAttempts + 1
			sg_desired_henchman = sg_desired_henchman + 2
			return
		end
		

end


function docreaturechamber()

	local numActiveChambers = NumBuildingActive( RemoteChamber_EC )
	local curRank = GetRank()

	--don't build CC until level before ground units are available at the earliest.
	if curRank < fact_lowrank_ground-1 then
		return 0 
	end

	-- Don't make more than one Creature Chamber on Easy Difficulty --Added by Bchamp 4/5/2019
	if (g_LOD == 0) then
		if (numActiveChambers > 0) then
			return 0
		end
	end


	if (numActiveChambers > 0) then
		local underAttackVal = UnderAttackValue()
		-- check to see distance of chamber to base and blow chamber if under attack, Bchamp 10/2018
		if (GroundDistToBase() > 150 and (UnderAttackValue() > (2*fact_selfValue + 150) and fact_selfValue < 400) and DamageTotal() > 50) then
			Scuttle( RemoteChamber_EC )
			if (goal_rank2rush == 1) then
				CancelRank2Rush();
				return 0
			end
		end
	end

	local aim_erate = 4
	-- this could cause a stall if we are aiming for a lower erate 
	if (fact_closestAmphibDist > 400) then
		aim_erate = 6
	end
	
	-- if AI has tons of electricity (edited from 1600 to 2600 on 9/27/2018 by Bchamp)
	if (ElectricityAmountWithEscrow() > 2600) then
		aim_erate = 0
	end
	

	local metRankRequirement = 1

	--rank requirement test - this states in standard/hard if we have a unit greater than rank1 and we have 
	--not started researching rank2 then don't build chamber yet
	if (g_LOD>0 and fact_army_maxrank > 1 and ResearchQ(RESEARCH_Rank2)==0) then
		metRankRequirement = 0
	end
		
	-- LOGIC #1 (build chamber when we have reached elec desired rate)
	if (LabUnderAttackValue()<500 and ElectricityPerSecQ()<aim_erate) then
	 	return 0
	end

	-------------------------------------------------------------
	--added 10/1/2018 by bchamp----------------------------------
	--sets desireCC. Won't build a CC before rank 2 if rank2 units are swimmers/amphib
	local desireCC = 0
	local curRank = GetRank()
	if (goal_desireGround == 1 or curRank < 2) then
		if (curRank < 2) then
			local swimmerCount = Army_NumCreaturesInClass( Player_Self(), sg_class_swimmer, curRank-1, curRank+1 );
			if (swimmerCount > 0) then 
				return 0
			end
		end
		desireCC = 1
	end
	-------------------------------------------------------------
	-------------------------------------------------------------
	-- Added by Bchamp so all amphib armies will still make regular CC's, assuming they have a WC 4/19/2019
	if (NumBuildingActive(WaterChamber_EC) > 0 and curRank >= fact_lowrank_amphib) then
		desireCC = 1
	end
	-------------------------------------------------------------


	if (desireCC == 1 and (goal_needelec ~= 2 or fact_armyAvgElec<10)) then
		local numDesiredChambers = numActiveChambers

		if (numActiveChambers > 0  and ScrapAmountWithEscrow() > 360) then
			local groundActive = Army_NumCreature( Player_Self(), sg_class_ground );
			local groundQ = Army_NumCreatureQ( Player_Self(), sg_class_ground );
			local queued = groundQ - groundActive
			
			if (queued >= (3*numActiveChambers) or numActiveChambers < (NumBuildingActive( Foundry_EC ) + 1)
				or numActiveChambers < curRank) then
				-- store number of desired chambers
				numDesiredChambers = numActiveChambers + 1
			elseif ScrapAmount() > curRank*400 and numActiveChambers < (CoalPileWithDropOffs() + curRank) then
				numDesiredChambers = numActiveChambers + 1
			end

			--Added so that computer could build a second CC at L2 if it's doing well. --Added by Bchamp 4/1/2019
			if (g_LOD >= 2 and numActiveChambers < 2 and curRank == 2 and ScrapPerSec() > 15 
				and (ElectricityPerSecQ() >= 10 or (ElectricityPerSecQ() >= 8 and goal_rank2rush == 1)) and queued >= (numActiveChambers)) then

					numDesiredChambers = 1 + rand2a
				if (ScrapAmountWithEscrow() > 500) then
					numDesiredChambers = 2
				end
			end

			
		else
			-- store number of desired chambers
			numDesiredChambers = 1
		end


		if (NumBuildingQ( RemoteChamber_EC ) < numDesiredChambers and 
			IsChamberBeingBuilt() == 0 and metRankRequirement == 1
			and CanBuildWithEscrow( RemoteChamber_EC ) == 1) then 
			
			-- ReleaseGatherEscrow();
			-- ReleaseRenewEscrow();
			xBuild( RemoteChamber_EC, ChamberLocation() );
			aitrace("Script: Build creature chamber")
			return 1
		end
	end
	
	return 0
end

function ChamberLocation()

    if (LabUnderAttackValue() > 200) then
        return PH_Best
    elseif rand100c > 50 and NumBuildingActive( RemoteChamber_EC ) >= 2 then
        return PH_DefendSite
    else --build chambers further from base but not necessarily near workshop
		-- this will hopefully increase distance chambers are spread out
		-- have it based on # foundrys if there are more than 2 chambers present
		local mapsizeoffset = 1
		local jump = 0
		
		if (fact_closestAmphibDist < 400) then
			mapsizeoffset = 1.2
		elseif (fact_closestAmphibDist < 650) then
			mapsizeoffset = 1.5
		elseif (fact_closestAmphibDist < 800) then
			mapsizeoffset = 1.7
		end
	
		if (NumBuildingQ( RemoteChamber_EC ) >= 2) then
			jump = 60*((NumBuildingQ( Foundry_EC ))^0.75)*mapsizeoffset
		elseif (NumBuildingQ( RemoteChamber_EC ) < 2) then
			jump = 0
		end
		-- randomize the distance from the base with spread.
		icd_chamberDistFromBase = (jump + 25 + (2*Rand(10)))
		-- if an amphibian map then stay closer to the base
		if (goal_amphibTarget==1) then
			icd_chamberDistFromBase = 30
		end

        return PH_OutsideBase
    end
    
end

function doelectricalgenerator()
	
	--this determines if we want to build a gen
	local buildGen = 1

	if (LabUnderAttackValue() > 0 or UnderAttackValue() > fact_selfValue*0.5) then
		buildGen = 0
	end
	 
	local erate = ElectricityPerSecQ()
	 
	 -- if we have reached our desired rate then don't build anymore
	if (erate >= sg_desired_elecrate) then
	 	buildGen = 0
	end
	
	-- this rule states that only build this egen when
	-- we have 2 or more rods present
	if (NumBuildingQ( ResourceRenew_EC ) < 2 and g_LOD ~= 0) then
		buildGen = 0
	end
	
	-- make sure AI has some military or make sure have met our lowrank requirement
	if (fact_selfValue < (100+ rand100b*5) and GetRank() >= fact_lowrank_all) then
		buildGen = 0
	end
	
	-- only build generator if foundry exists
	if (NumBuildingQ( Foundry_EC ) < 1) then
		buildGen = 0
	end
	  
	-- are there egens that need upgrading, if so we should upgrade instead of building more egens
	if (NumBuildingQ( ElectricGenerator_EC ) > 0 and EGenNeedsUpgrading()==1) then
		buildGen = 0
	end
		 
	local beingBuilt = NumBuildingQ( ElectricGenerator_EC ) - NumBuildingActive( ElectricGenerator_EC )
	
	if (buildGen == 1) then		 
		if (beingBuilt == 0 and CanBuildWithEscrow( ElectricGenerator_EC ) == 1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( ElectricGenerator_EC, PH_OpenGeyser );
			aitrace("Script: Build egen")
		end
	end
	return 0
end

function dowaterchamber()

	local curRank = GetRank()
	if NumBuildingQ( WaterChamber_EC ) >= (curRank-1) then --Don't make more than this many water chambers
		return 0
	end

	-- Build Water Chamber when starting to research level that water units are available.
	-- Added by Bchamp 4/5/2019
	
	local prepWC = 0
	if (g_LOD >= 2 and ((fact_lowrank_amphib - curRank) == 1 or (fact_lowrank_swimmer - curRank) == 1) and NumBuildingQ( WaterChamber_EC ) == 0) then
		if (curRank == 1 and ResearchQ(RESEARCH_Rank2) == 1) then
			prepWC = 0 --Water Chambers not available to build until L2 as of current update 4/5/2019
		elseif (curRank == 2 and ResearchQ(RESEARCH_Rank3) == 1) then
			prepWC = 1
		elseif (curRank == 3 and ResearchQ(RESEARCH_Rank4) == 1) then
			prepWC = 1
		elseif (curRank == 4 and ResearchQ(RESEARCH_Rank5) == 1) then
			prepWC = 1
		else
			prepWC = 0
		end

		if (prepWC == 1 and CanBuildWithEscrow( WaterChamber_EC )==1 and IsChamberBeingBuilt() == 0) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( WaterChamber_EC, PH_Best );
			aitrace("Script: Build waterchamber");
			return 1
		end
		return 0
	end

	-- Build Water chamber if you have water units available
	if (fact_lowrank_amphib <= curRank) then

		if IsChamberBeingBuilt() == 1 then
			return 0
		end

		--if you have a water chamber and are in danger, and already have at least 2 chambers, don't worry about more
		if (NumBuildingQ( WaterChamber_EC ) >= 2 and UnderAttackValue() > 0.7*fact_selfValue) then
			return 0
		end

		if CanBuildWithEscrow( WaterChamber_EC )==1 then
			-- ReleaseGatherEscrow();
			-- ReleaseRenewEscrow();
			xBuild( WaterChamber_EC, PH_Best );
			aitrace("Script: Build waterchamber");
			return 1
		end
	end
	return 0
end

function doaviary()
	
	if (goal_desireFlyers == 0) then
		return 0
	end


	-- Added so that Air Chambers are never built until flyers are available 4/29/2022 Bchamp
	local curRank = GetRank()
	if (fact_lowrank_flyer > curRank) then
		return 0
	end
	
	local numActiveChambers = NumBuildingActive( Aviary_EC )
	if (numActiveChambers > 0 and  ScrapAmountWithEscrow() > 500) then
		local flyerActive = Army_NumCreature( Player_Self(), sg_class_flyer );
		local flyerQ = Army_NumCreatureQ( Player_Self(), sg_class_flyer );
		local queued = flyerQ - flyerActive
			
		if (queued >= (4*numActiveChambers)) then
			-- store number of desired chambers
			numActiveChambers = numActiveChambers+1
		end

	else
		numActiveChambers = 1
	end
	
	if (NumBuildingQ( Aviary_EC ) < numActiveChambers and 
		IsChamberBeingBuilt() == 0 and
		CanBuildWithEscrow( Aviary_EC)==1) then
	
		-- ReleaseGatherEscrow();
		-- ReleaseRenewEscrow();
		xBuild( Aviary_EC, PH_Best );
		aitrace("Script: Build aviary");
		return 1
	end
	return 0
end

function dobuildwall()
	
	if (NumHenchmanActive() < 6) then
		return
	end
	
	if (UnderAttackValue()>0) then
		return
	end
	
	if (ScrapAmountWithEscrow() > 60 and CanBuild( BrambleFence_EC ) == 1) then
		xBuildWall( 0 )
	end

end

function dobasebuild()

	-- if we need coal badly don't ask for any buildings since
	-- we cannot afford them we should build only henchman
	if (goal_needcoal == 2 or NumHenchmanActive()==0) then
		return
	end

	-- foundry
	if (sg_buildstructure[Foundry_EC]==1) then
		dofoundry();
	end
	
	-- soundbeam towers
	if (sg_buildstructure[SoundBeamTower_EC]==1) then
		dosoundbeamtowers();
	end
	
	-- lightning rods
	if (sg_buildstructure[ResourceRenew_EC]==1) then
		dolightningrods();
	end
	
	-- electrical generator
	if (sg_buildstructure[ElectricGenerator_EC]==1) then
		doelectricalgenerator();
	end
		
	-- bramble fences
	if (sg_buildstructure[BrambleFence_EC]==1) then
		dobuildwall();
	end
	
	-- antiair towers
	if (sg_buildstructure[AntiAirTower_EC]==1) then
		doantiairtowers();
	end
		
	-- add this flag, so that two buildings are not build on the same frame
	local isBeingBuild = 0

	if (sg_buildstructure[VetClinic_EC]==1 and isBeingBuild==0) then
		isBeingBuild = dovetclinic()
	end

	if (sg_buildstructure[GeneticAmplifier_EC]==1 and isBeingBuild==0) then
		isBeingBuild = dogeneticamplifier()
	end

	-- creature chamber
	if (sg_buildstructure[RemoteChamber_EC]==1) then
		isBeingBuild = docreaturechamber();
	end
	
	-- Waterchamber
	
	if (sg_buildstructure[WaterChamber_EC]==1 and isBeingBuild==0) then
		isBeingBuild = dowaterchamber()
	end

	-- Aviary

	if (sg_buildstructure[Aviary_EC]==1 and isBeingBuild==0) then
		isBeingBuild = doaviary()
	end	
	
	
	
	doupgrades();

end
	
	
