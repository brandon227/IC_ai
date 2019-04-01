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
	
	--local randFactor = 1000
	--if (g_LOD == 0) then
	--	randFactor = 0
	--elseif (g_LOD == 1) then
	--	randFactor = 6
	--end
	
--	 randomly decide if we will ever build fences
--	if (Rand(10) > 5) then
--		sg_buildstructure[BrambleFence_EC] = 1
--	end
	
	sg_lightningrod_cap = 4
	
	-- the distance from the base the AI will build its chamber (using PH_OutsideBase flag)
	icd_chamberDistFromBase = 25
	
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
	
	-- LOGIC ? 
	-- try for rank2 first, but if for some reason we can't get there than I guess
	-- we should upgrade the egen ? on bigger maps maybe i'd get the upgrades first?
	-- if our army is elec heavy i'd also get more elec too, even more than 14 per sec
	-- this 14 needs to be worked out based on number of geysers and army type
		
	-- determine if we should build another egen or upgrade
	if (NumBuildingActive( ElectricGenerator_EC ) > 0 and ResearchCompleted(RESEARCH_Rank2)==1) then
		
		 if (CanUpgradeWithEscrow( UPGRADE_EGen ) == 1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xUpgrade( UPGRADE_EGen );
			aitrace("Script: upgrade egen");
		end
	end
end



sg_randval = Rand(100)

-- check to see if we should build a vetclinic or genamp
function checkToBuildAdvancedStructures( extraoffset )
	
	-- check for rank3 unless we are going for an upgraded early rank tactic?
	if (g_LOD>0 and ResearchCompleted(RESEARCH_Rank3)==0) then
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
		offset = offset - sg_randval/8
	elseif (g_LOD == 1) then
		offset = offset - sg_randval/20
	elseif (g_LOD == 2) then
		offset = offset + sg_randval/20
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
	
	--if (checkToBuildAdvancedStructures(5) == 0) then
	--	return 0
	--end
	

	local numCreaturesNeeded = 9
	-- make easy mode much more random in regards to building this
	if (g_LOD == 0) then
		numCreaturesNeeded = 6+sg_randval*0.05
	end
	
	-- extra check - should check for HaveElectricityPreqrequisite instead of just having an egen - no ElecNeed
	 if (NumChambers() > 0 and NumCreaturesActive()>=numCreaturesNeeded) then
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
	 
	 -- if we have reached our desired rate then don't build anymore
	 if (erate >= sg_desired_elecrate) then
	 	return
	end
	
	-- wait for 8 active henchmen before building a second rod - add randomness here
	if (NumHenchmanActive() < 8 and NumBuildingQ( ResourceRenew_EC )>0) then
		return
	end
	
	-- more than 8 henchmen and more than 2 rods rank2 to start
	if (NumBuildingQ( ResourceRenew_EC )>1 and (ResearchQ(RESEARCH_Rank2)==0 and g_LOD>0)) then
		return
	end
		
	-- if lab is under attack by more than 3 times our military value
	if ( not(goal_needelec==2 and ElectricityAmountWithEscrow() < 50 and fact_selfValue < 200) and LabUnderAttackValue() > 0) then
		return
	end
	
	local numActive = NumBuildingActive( ResourceRenew_EC )
	local numQ = NumBuildingQ( ResourceRenew_EC )
	
	-- if these numbers are different, then a rod is being built (only build one at a time)
	if ( (numQ-numActive) > 0) then
		return
	end
	
	-- should only really build 2 rods before level 2
	if (NumBuildingActive( ResourceRenew_EC ) >= 2 and  ResearchQ(RESEARCH_Rank2)==0) then
		return
	end
	
	-- LOGIC - only build one unless we can't build an egen and we need more elec
	
	if (numQ < sg_lightningrod_cap and CanBuildWithEscrow( ResourceRenew_EC )==1) then
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
		local randval = 300 + sg_randval*3
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
		if (curRank < 3 and underAttackVal > 150 and fact_selfValue*1.2 < underAttackVal) then
			buildTowers = 1
		end
		
		-- if we are being attacked by more than 1.5 times the AIs military worth
		if (g_LOD < 2 and ResearchCompleted( RESEARCH_TowerUpgrade ) == 1 and underAttackVal > fact_selfValue*1.3 ) then
			buildTowers = 1
		end
	end
	
	local numTowerActive = NumBuildingActive( SoundBeamTower_EC )
	if (NumHenchmanActive() > 5 and fact_closestGroundDist < 150 and numTowerActive<1 and curRank==1) then
		buildTowers = 1
	end
	
	-- check for camo digger units
	if (buildTowers==0 and numTowerActive==0) then
		local numCamo = PlayersUnitTypeCount( player_enemy, player_max, sg_class_camoflauge )
		if (curRank < 3 and numCamo > (3+sg_randval/40)) then
			buildTowers = 1
		elseif (numCamo > 10) then
			buildTowers = 1
		end
	end
	
	-- added by LBFrank 3/31/19 to check for sonic units (useful in the wake of L2/L3 sonic)
	if (buildTowers==0 and numTowerActive==0) then
		local numSonic = PlayersUnitTypeCount( player_enemy, player_max, sg_class_sonic )
		if (curRank < 4 and numSonic > (3+sg_randval/60)) then
			buildTowers = 1
		elseif (numSonic > 7) then
			buildTowers = 1
		end
	end

	if (buildTowers == 1) then
	
		local desiredAmount = 1 + CoalPileWithDropOffs()
		
		if (curRank<3 and underAttackVal>400 and fact_selfValue < 400) then
			desiredAmount = desiredAmount+1
		end
				
		local numtowersBeRequested = NumBuildingQ( SoundBeamTower_EC ) - numTowerActive
	
		-- don't build more than one at a time, if so, build a second creature chamber on hard difficulty
		-- modified by bchamp 10/1/2018 to stop AI from building a ton of SB towers when they really need to build units
		if (numtowersBeRequested > 0) then
			if (g_LOD == 2 and NumBuildingQ( RemoteChamber_EC ) < 2 and CanBuildWithEscrow( RemoteChamber_EC ) == 1 ) then
				
				ReleaseGatherEscrow();
				ReleaseRenewEscrow();
				xBuild( RemoteChamber_EC, PH_Best );
				aitrace("Script: Build second defense creature chamber")
			end

			return
		end
		



		if (NumBuildingQ( SoundBeamTower_EC ) < desiredAmount and CanBuildWithEscrow( SoundBeamTower_EC )==1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( SoundBeamTower_EC, PH_DefendSite );
			aitrace("Script:build sound beam tower "..(numTowerActive+1).."of "..desiredAmount);
		else
			aitrace("Script:could not afford tower");
			sg_needSBTower = 1
		end
		
	end

end

function doantiairtowers()

	-- specify how many sound beam towers should be built at each expansion point	
	local dmgFromFlyer = DamageFromFlyer()
	local enemyFlyers = PlayersUnitTypeCount( player_enemy, player_max, sg_class_flyer );
	-- if AI has not been attacked by flyers yet or they just have lots hidden away
	if (dmgFromFlyer == 0 and enemyFlyers < (5+(sg_randval*0.06))) then
		return
	end
	
	-- if the enemies have no flyers, no need to build AA for now
	if (enemyFlyers == 0) then
		return
	end
	
	-- constants
	local numtowers = 1+enemyFlyers/5;
	
	local numActive = NumBuildingActive( AntiAirTower_EC )
	local numQueued = NumBuildingQ( AntiAirTower_EC )
	local numtowersBeRequested =  numQueued - numActive
	
	-- don't build more than one at a time
	--if (numtowersBeRequested > 0) then
		--return
	--end
	
	-- make sure one more is being built if we are underattack by flyers
	if ((NumUnprotectedAASite() > 0 or NumSitesWithZeroAA() > 0) and numQueued == numtowers) then
		numtowers = numActive+1
	end
	
	if (numQueued < numtowers and CanBuildWithEscrow( AntiAirTower_EC )==1) then
		
		ReleaseGatherEscrow();
		ReleaseRenewEscrow();
		xBuild( AntiAirTower_EC, PH_DefendSite );
		aitrace("Script:build antiair tower");
		return
	end

end

function dovetclinic()


	 -- extra check to make sure we have a few creatures, lab isn't under attack, and we have henchmen. Bchamp 3/31/2019
	if (LabUnderAttackValue() > 200 or NumCreaturesQ() < (sg_randval*0.06 + 1) or NumHenchmanActive() < 12 ) then
		return
	end

	--Add randomization to number of vet clinics built. Bchamp 3/31/2019
	local maxVetClinic = 2
	if (sg_randval > 70) then
		maxVetClinic = 1
	end
	
	-- If already completed all of these researches at the clinic, don't build more. This way AI doesnt keep building if you destroy clinics
	-- in the late game. Added by Bchamp 3/31/2019
	-- LBFrank 4/01/19 they may want one clinic to research tower upgrade if they have the towers for it. if not then yeah we don't need em
	-- Actually I think they just take up space after a while. AI doesn't place them strategically so we could probably just get rid of them
	if (ResearchCompleted(RESEARCH_HenchmanYoke) == 1 and ResearchCompleted(RESEARCH_HenchmanMotivationalSpeech) == 1 and ResearchCompleted(RESEARCH_StrengthenElectricalGrid) == 1 and ResearchCompleted(RESEARCH_IncBuildingIntegrity) == 1) then
		if (ResearchCompleted(RESEARCH_TowerUpgrade) == 0 and (NumBuildingActive( SoundBeamTower_EC ) + NumBuildingActive( AntiAirTower_EC )) <= 2) then
			maxVetClinic = 1
		else
			return
			if (NumBuildingActive( VetClinic_EC ) > 0) then
				Scuttle ( VetClinic_EC )
			end
		end
	end

	 if (goal_needcoal ~= 2) then
		-- typical check for building
		if (NumBuildingQ( VetClinic_EC ) < maxVetClinic and CanBuildWithEscrow( VetClinic_EC )==1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( VetClinic_EC, PH_Best );
			aitrace("Script: Build vetclinic")
			return 1
		end
	end
	
	return 0
end



function dofoundry()
	
	money_on_hold = 0;

	local alwaysBuild = 0
	-- always build when we have no drop off unless when? if have tons of money and we are under attack?
	if (CoalPileWithDropOffs()==0 and (LabUnderAttackValue() < fact_selfValue or ScrapAmountWithEscrow() < 500) ) then
		alwaysBuild = 1
	end
	
	local gatherSiteOpen = IsGatherSiteOpen()

	--When henchmen are under attack and can no longer mine coal at this gather site, they will build a foundry. 
	--This function can be bad because AI can waste resources on a foundry when it really needs units more than anything.
	--Changed to NumHenchmenGuarding() > 4 instead of 2. And increased UnderAttackValue() > 200 from 100..--Bchamp 3/31/2019
	if (gatherSiteOpen == 0 and NumHenchmenGuarding()>4 and UnderAttackValue() > 200) then
		alwaysBuild = 1
	end

	--Build Foundry if you are going to be able to beat attack, otherwise don't and save for units. Added 3/31/2019 by Bchamp
	if (gatherSiteOpen == 0 and NumHenchmenGuarding()>3 and UnderAttackValue() < 0.7*fact_selfValue) then
		alwaysBuild = 1
	end
	
	local curRank = GetRank()	

	-- Have a minimum of 2 foundries if AI is at least lvl 2 
	if (curRank >= 2 and NumBuildingQ( Foundry_EC ) < 2) then
		if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
			alwaysBuild = 0
		else
			--Minimum of 16 henchmen before building second foundry. Also make sure foundry's are full. 3/30/2019 Bchamp
			if (NumBuildingQ( Foundry_EC ) == 1 and (NumHenchmanQ() < 16 or gatherSiteOpen > 0 or NumCreaturesQ() < (sg_randval*0.05 + 1))) then
				alwaysBuild = 0
			else
				alwaysBuild = 1
			end
		end
	end
	
	-- On larger maps, have a minimum of 3 foundries if AI is at least lvl 3. 
	-- Also need minimum number of units.
	if (fact_closestGroundDist > 500 and curRank >= 3) then
		if (NumBuildingQ( Foundry_EC ) < 3 and gatherSiteOpen == 0 and NumCreaturesQ() > (sg_randval*0.07 + 2)) then
			if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
				alwaysBuild = 0
			else
				alwaysBuild = 1
			end
		end
	end

	-- Have minimum 3 foundries once AI reaches Rank 4
	if (curRank >= 4) then
		if (NumBuildingQ( Foundry_EC ) < 3 and gatherSiteOpen == 0) then
			if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
				alwaysBuild = 0
			else
				alwaysBuild = 1
			end
		end
	end

	-- On small maps, have a minimum of 5 foundries if AI is at lvl 5
	-- is this too many on small maps?? Vacation? Ring?
	if (curRank == 5 and NumBuildingQ( Foundry_EC ) < 5 and gatherSiteOpen == 0) then
		if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
			alwaysBuild = 0
		else
			alwaysBuild = 1
		end
	end


	-- On large maps, have a minimum of 6 foundries if AI is at lvl 5
	if (fact_closestGroundDist > 500 and curRank == 5 and NumBuildingQ( Foundry_EC ) < 6) then
		if (LabUnderAttackValue() > 100 and ScrapPerSec() > 8) then
			alwaysBuild = 0
		else
			alwaysBuild = 1
		end
	end
		
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
	--Only build foundry if other foundries are full....doesn't work. Stops all foundries from being built.
	--if (CoalPileWithDropOffs() > 0) then
	--	 return
	--end

	local dist2dropoff = DistToDropOff();
	--Commenting this if statement out because it causes AI on some maps to not build foundries at all in specific positions. 1/4/2019 Bchamp
	--if (dist2dropoff > icd_maxfoundrydist) then

		--aitrace("Script: dist2dropoff="..dist2dropoff);
		if (CanBuildWithEscrow( Foundry_EC ) == 1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( Foundry_EC, PH_Best );
			aitrace("Script: build foundry");
			sg_foundryAttempts = sg_foundryAttempts + 1
			return
		end
		
		--aitrace("Script: failed to build foundry");
	--end
end


function docreaturechamber()
	
	local numActiveChambers = NumBuildingActive( RemoteChamber_EC )

	if (numActiveChambers > 0) then
		local underAttackVal = UnderAttackValue()
		-- check to see distance of chamber to base and blow chamber if under attack, Bchamp 10/2018
		if (GroundDistToBase() > 150 and (UnderAttackValue() > (2*fact_selfValue + 150) and fact_selfValue < 400)) then
			Scuttle( RemoteChamber_EC )
			if (goal_rank2rush == 1) then
				CancelRank2Rush();

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
				return
			end
		end
		desireCC = 1
	end
	-------------------------------------------------------------
	-------------------------------------------------------------

	if (desireCC == 1 and (goal_needelec ~= 2 or fact_armyAvgElec<10)) then


		if (numActiveChambers > 0  and ScrapAmountWithEscrow() > 500) then
			local groundActive = Army_NumCreature( Player_Self(), sg_class_ground );
			local groundQ = Army_NumCreatureQ( Player_Self(), sg_class_ground );
			local queued = groundQ - groundActive
			
			if (queued >= (4*numActiveChambers) or numActiveChambers < (NumBuildingActive( Foundry_EC ) + 1)) then
				-- store number of desired chambers
				numActiveChambers = numActiveChambers+1
			end
			-- cap for now
			--if (numActiveChambers>2) then
			--	numActiveChambers = 2
			--end
			
		else
			-- store number of desired chambers
			numActiveChambers = 1
		end

		-- build chamber when we have more than X number of henchman and a foundry
		
		-- function that will hopefully increase distance chambers are spread out
		-- have it based on # foundrys if there are more than 2 chambers present
		
		-- mapsizeoffset so jump distance is also map dependent
		local mapsizeoffset = 1
		if (fact_closestAmphibDist>400) then
			mapsizeoffset = 1.2
		end
		if (fact_closestAmphibDist>650) then
			mapsizeoffset = 1.5
		end
		if (fact_closestAmphibDist>800) then
			mapsizeoffset = 1.7
		end
		local jump = 0
		if (NumBuildingQ( RemoteChamber_EC ) >= 2) then
			jump = 60*((NumBuildingQ( Foundry_EC ))^0.75)*mapsizeoffset
		elseif (NumBuildingQ( RemoteChamber_EC ) < 2) then
			jump = 0
		end

		-- if lab under attack, change chamber location to PH_Best, which will be near lab if possible, or remote if unsafe
		chamberLocation = PH_OutsideBase
		if (LabUnderAttackValue() > 200) then
			chamberLocation = PH_Best
		end

		if (NumBuildingQ( RemoteChamber_EC ) < numActiveChambers and 
			IsChamberBeingBuilt() == 0 and metRankRequirement == 1
			and CanBuildWithEscrow( RemoteChamber_EC ) == 1) then 

			-- randomize the distance from the base with spread.
			icd_chamberDistFromBase = (jump + 25 + (2*Rand(10)))
			-- if an amphibian map then stay closer to the base
			if (goal_amphibTarget==1) then
				icd_chamberDistFromBase = 30
			end
			
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( RemoteChamber_EC, chamberLocation );
			aitrace("Script: Build creature chamber")
			return 1
		end
	end
	
	return 0
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
	if (fact_selfValue < (100+sg_randval*5) and GetRank() >= fact_lowrank_all) then
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
end

function dowaterchamber()
	
	
	-- if this chamber is desired and we have no other chamber this maybe a good option
	-- this is only if we have swimmers in the current ranks of course
	
	if (goal_desireSwimmers == 0 or (LabUnderAttackValue() > 100 and NumChambers() > 0)) then
		return 0
	end

	-- MORE WCs on water maps
	if ((goal_amphibTarget==1) or (Army_NumCreature( Player_Self(), sg_class_amphib ) == Army_NumCreature( Player_Self(), sg_class_ground ))) then
		if (NumBuildingQ( WaterChamber_EC ) < (GetRank()-1) and IsChamberBeingBuilt() == 0 and 
			CanBuildWithEscrow( WaterChamber_EC )==1) then
				ReleaseGatherEscrow();
				ReleaseRenewEscrow();
				xBuild( WaterChamber_EC, PH_Best );
				aitrace("Script: Build waterchamber");
				return 1
		end
		return 0
	else
		if (NumBuildingQ( WaterChamber_EC ) < 2 and NumBuildingQ( WaterChamber_EC ) < (GetRank()-1) and
			IsChamberBeingBuilt() == 0 and CanBuildWithEscrow( WaterChamber_EC )==1) then
				ReleaseGatherEscrow();
				ReleaseRenewEscrow();
				xBuild( WaterChamber_EC, PH_Best );
				aitrace("Script: Build waterchamber");
				return 1
		end
		return 0
	end
end

function doaviary()
	
	if (goal_desireFlyers == 0) then
		return 0
	end

	-- Added so that Air Chambers are never built before lvl 3 on 9/6/2018 by Bchamp
	local curRank = GetRank()
	if (curRank < 3) then
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
	
		ReleaseGatherEscrow();
		ReleaseRenewEscrow();
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
	
	if (sg_buildstructure[VetClinic_EC]==1 and isBeingBuild==0) then
		isBeingBuild = dovetclinic()
	end
	
	
	if (sg_buildstructure[GeneticAmplifier_EC]==1 and isBeingBuild==0) then
		dogeneticamplifier()
	end
	
	
	doupgrades();

end
