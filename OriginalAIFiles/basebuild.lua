
aitrace("Script Component: Base building logic")

function init_basebuild()
	
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
	sg_buildstructure[LandingPad_EC] = 1
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
	
	return NumBuildingActive( RemoteChamber_EC)+NumBuildingActive(Aviary_EC)+NumBuildingActive(WaterChamber_EC)
	
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

function dolandingpad()
	
	if (ResearchCompleted(RESEARCH_Rank5)==1) then
	
		if (NumBuildingQ( LandingPad_EC ) < 1 and CanBuildWithEscrow( LandingPad_EC )==1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( LandingPad_EC, PH_Best );
			aitrace("Script: Build landing pad")
		end
		
		if (NumBuildingQ( Gyrocopter_EC ) < 1 and CanBuildGyroWithEscrow() == 1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			BuildGyro();
			aitrace("Script: Build gyro copter")
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
	
	if (checkToBuildAdvancedStructures(5) == 0) then
		return 0
	end
	
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
	
	-- wait for six active henchmen before building a second rod - add randomness here
	if (NumHenchmanActive() < 5 and NumBuildingQ( ResourceRenew_EC )>0) then
		return
	end
	
	-- more than 6 henchmen and more than 2 rods rank2 to start
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
	
	if (buildTowers == 1) then
	
		local desiredAmount = 1 + CoalPileWithDropOffs()
		
		if (curRank<3 and underAttackVal>400 and fact_selfValue < 400) then
			desiredAmount = desiredAmount+1
		end
				
		local numtowersBeRequested = NumBuildingQ( SoundBeamTower_EC ) - numTowerActive
	
		-- don't build more than one at a time
		if (numtowersBeRequested > 0) then
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
	local numtowers = 1+enemyFlyers/10;
	
	local numActive = NumBuildingActive( AntiAirTower_EC )
	local numQueued = NumBuildingQ( AntiAirTower_EC )
	local numtowersBeRequested =  numQueued - numActive
	
	-- don't build more than one at a time
	if (numtowersBeRequested > 0) then
		return
	end
	
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

	local offset = 0
	-- build clinic earlier if we have a long way to go
	if (fact_lowrank_all > 3) then
		offset = -20
	end

	if (checkToBuildAdvancedStructures(offset) == 0) then
		return 0
	end

	 -- extra check to make sure we have a few creatures
	 if (goal_needcoal ~= 2) then
		-- typical check for building
		if (NumBuildingQ( VetClinic_EC ) < 1 and CanBuildWithEscrow( VetClinic_EC )==1) then
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
	if (gatherSiteOpen == 0 and NumHenchmenGuarding()>2 and UnderAttackValue() > 100) then
		alwaysBuild = 1
	end
		
	-- check for case where there are a bunch of henchmen who could use a better spot to gather
	
	if (alwaysBuild == 0) then
		
		-- need to check to see if we are ready to expand
		-- need to see if we need coal badly and we have no piles
		-- to gather from cuz they are threatened
		
		if (NumChambers() == 0) then
			return
		end
			
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
		--if (NumHenchmanActive() <= sg_henchmanthreshold and CoalPileWithDropOffs()>0) then
		--	return
		--end
	end

	local dist2dropoff = DistToDropOff();
	if (dist2dropoff > icd_maxfoundrydist) then

		aitrace("Script: dist2dropoff="..dist2dropoff);
		if (CanBuildWithEscrow( Foundry_EC ) == 1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( Foundry_EC, PH_Best );
			aitrace("Script: build foundry");
			return
		end
		
		aitrace("Script: failed to build foundry");
	end
end

function docreaturechamber()
	
	local numActiveChambers = NumBuildingActive( RemoteChamber_EC )

	if (numActiveChambers > 0) then
		local underAttackVal = UnderAttackValue()
		-- check to see distance of chamber to base
		if (GroundDistToBase() > 150 and ((LabUnderAttackValue() > 80 and fact_selfValue < 400) or
		 (underAttackVal > fact_selfValue and underAttackVal > 100)) ) then
			Scuttle( RemoteChamber_EC )
		end
	end

	local aim_erate = 4
	-- this could cause a stall if we are aiming for a lower erate 
	if (fact_closestAmphibDist > 400) then
		aim_erate = 6
	end
	
	-- if AI has tons of electricity
	if (ElectricityAmountWithEscrow() > 1600) then
		aim_erate = 0
	end
	
	local metRankRequirement = 1
	-- rank requirement test - this states in standard/hard if we have a unit greater than rank1 and we have 
	-- not started researching rank2 then don't build chamber yet
	-- if AI has more than 600 coal, then also build chamber
	if (g_LOD>0 and fact_army_maxrank > 1 and ResearchQ(RESEARCH_Rank2)==0 and ScrapAmountWithEscrow() < 600) then
		metRankRequirement = 0
	end
		
	-- LOGIC #1 (build chamber when we have reached elec desired rate or already have ranked to 2)
	 if (LabUnderAttackValue()<500 and (ElectricityPerSecQ()<aim_erate or metRankRequirement==0 ) ) then
	 	return 0
	end

	-- if we have no elec don't build chamber - unless we have a low elec army
	if (goal_desireGround == 1 and (goal_needelec ~= 2 or fact_armyAvgElec<10)) then
		
		if (numActiveChambers > 0  and ScrapAmountWithEscrow() > 500) then
			local groundActive = Army_NumCreature( Player_Self(), sg_class_ground );
			local groundQ = Army_NumCreatureQ( Player_Self(), sg_class_ground );
			local queued = groundQ - groundActive
			
			if (queued >= (4*numActiveChambers)) then
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
		
		if (NumBuildingQ( RemoteChamber_EC ) < numActiveChambers and 
			IsChamberBeingBuilt() == 0 and
			CanBuildWithEscrow( RemoteChamber_EC)==1) then
			
			-- randomize the distance from the base 30-45m
			icd_chamberDistFromBase = 25 + Rand(10)
			-- if an amphibian map then stay closer to the base
			if (goal_amphibTarget==1) then
				icd_chamberDistFromBase = 30
			end
			
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( RemoteChamber_EC, PH_OutsideBase );
			aitrace("Script: Build first creature chamber")
			return 1
		end
	end
	
	return 0
end

function doelectricalgenerator()
	 
	-- wait for rank 2 (no exceptions here)
	if (ResearchCompleted(RESEARCH_Rank2)==0) then
		return
	end
	
	if (LabUnderAttackValue() > 0 or UnderAttackValue() > fact_selfValue*0.5) then
		return
	end
	 
	 local erate = ElectricityPerSecQ()
	 
	 -- if we have reached our desired rate then don't build anymore
	 if (erate >= sg_desired_elecrate) then
	 	return
	end
	
	-- this rule states that only build this egen when
	-- we have 4 rods present
	if (NumBuildingQ( ResourceRenew_EC ) < 4 and g_LOD ~= 0) then
		return
	end
	
	-- make sure AI has some military or make sure have met our lowrank requirement
	if (fact_selfValue < (100+sg_randval*5) and GetRank() >= fact_lowrank_all) then
		return
	end
		  
	-- are there egens that need upgrading, if so we should upgrade instead of building more egens
	if (NumBuildingQ( ElectricGenerator_EC ) > 0 and EGenNeedsUpgrading()==1) then
		return
	end
		 
	local beingBuilt = NumBuildingQ( ElectricGenerator_EC ) - NumBuildingActive( ElectricGenerator_EC )
			 
	if (beingBuilt == 0 and CanBuildWithEscrow( ElectricGenerator_EC ) == 1) then
		ReleaseGatherEscrow();
		ReleaseRenewEscrow();
		xBuild( ElectricGenerator_EC, PH_OpenGeyser );
		aitrace("Script: Build egen")
	end
end

function dowaterchamber()
	
	-- if this chamber is desired and we have no other chamber this maybe a good option
	-- this is only if we have swimmers in the current ranks of course
	
	if (goal_desireSwimmers == 0 or (LabUnderAttackValue() > 100 and NumChambers() > 0)) then
		return 0
	end
	
	if (NumBuildingQ( WaterChamber_EC ) < 2 and IsChamberBeingBuilt() == 0 and 
		CanBuildWithEscrow( WaterChamber_EC )==1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( WaterChamber_EC, PH_Best );
			aitrace("Script: Build waterchamber");
			return 1
	end
	return 0
end

function doaviary()
	
	if (goal_desireFlyers == 0) then
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
	-- what about foundrys ?
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
	
	-- landing pad
	if (sg_buildstructure[LandingPad_EC]==1) then
		dolandingpad();
	end
	
	doupgrades();

end