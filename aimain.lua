
-- all variables starting in sg_... are script globals and are modifyable throughout these lua files
-- if these are to be overwritten the code that modifies them should be either the oninit function or
-- a function that can be disabled (for special cases)

aitrace("Script: AIScript Loading...")

-- all code/logic for classifying and analysis creatures
dofilepath("data:ai/armyanalysis.lua")
-- contains overloaded functions to hold money for a request
dofilepath("data:ai/holdfunctions.lua");
-- all code/logic for building structures
dofilepath("data:ai/basebuild.lua")
-- all code/logic for ordering and managing creatures
dofilepath("data:ai/military.lua")
-- all code/logic for managing research
dofilepath("data:ai/research.lua")
-- all code/logic for managing henchman
dofilepath("data:ai/henchman.lua")
-- all code/logic for doing creature upgrades
dofilepath("data:ai/creatureupgrades.lua")
-- 
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
dofilepath("data:ai/scout.lua")
--
dofilepath("data:ai/tactics.lua")
--
dofilepath("data:ai/forcetactic.lua")



function oninit()
	-- sg_number =
	-- {

	-- };
	if init_randomness() == 1 then
		if init_scout() == 1 then
			init_basebuild();
			init_military();
			init_research();
			init_henchman();
			init_creatureupgrades();
		end
	end

		
	-----------------------------
	-- init_resourcesystem();
	
	-- do we need more coal, 0=no, 1=sure, 2=absolutely
	goal_needcoal = 1
	-- do we need more elec, 0=no, 1=sure, 2=absolutely
	goal_needelec = 2
	
	sg_desired_elecrate = 4
	-----------------------------
	sg_chamberAttempts = 0
	sg_foundryAttempts = 0
	-----------------------------
    --need to replace all Rand(x) with these in code


	-- run this once in the beginning so henchman will act on this as soon as possible
	dobasebuild();
	
	--Added by Bchamp 3/31/2019 to toggle aggressive behavior
	--aggressionLevel = 2
	

	-- Perform Tactic Functions
	-- Each function is called in order below. If rejected, the CanDo function will return 0 and the next tactic will be called.

	if (dotactic == 1) then
		if (EconomyRush_CanDo(dotactic) == 0) then
			if (Rank2Rush_CanDoTactic(dotactic) == 0) then
				if (Rank1Rush_CanDoTactic() == 0) then
					if (ResearchRush_CanDo(dotactic) == 0) then
						FlyerRush_CanDo()
					end
				end
			end
		end
	end

	--Force Tactic Functions
	if (dotactic == 2) then
		EconomyRush_CanDo(dotactic)
	elseif (dotactic == 3 or dotactic == 4) then
		Rank2Rush_CanDoTactic(dotactic)
	elseif (dotactic == 5) then 
		return
	elseif (dotactic == 6) then
		ResearchRush_CanDo(dotactic)
	elseif (dotactic == 7) then
		return
	end

end

function doweneedmoney()
	-- we have no henchman
	if (NumHenchmanQ() == 0 and ScrapAmount() < 100) then
		 if (ScrapAmountWithEscrow()>=100) then
		 	ReleaseGatherEscrow()
			aitrace("Script: Release gather escrow cuz we have no money and no henchman");
		 else
		 	aitrace("Script: No money, no henchman, starting selling stuff");
			-- we are in trouble we should sell some 'stuff'	
			
			
			-- determine order in which we sell our buildings if we have them
			local scuttleorder = {VetClinic_EC,GeneticAmplifier_EC,ResourceRenew_EC,
							ElectricGenerator_EC,SoundBeamTower_EC,AntiAirTower_EC,WaterChamber_EC,
							Aviary_EC,RemoteChamber_EC,Foundry_EC}
			
			for i=1,getn(scuttleorder) do
				-- if we have the building then scuttle it
				if (NumBuildingQ(scuttleorder[i])>0) then
					Scuttle( scuttleorder[i] )
					return
				end
			end
		 end
	end
	-- if we have no chamber, few henchmen and little coal then start sellin stuff
	--if (fact_selfValue == 0 and NumBuildingQ(RemoteChamber_EC)==0 and NumBuildingQ(Aviary_EC)==0 and NumBuildingQ(WaterChamber_EC)==0) then
	--	if (NumHenchmanQ() < 3 and LabUnderAttackValue() > 100 and ) 
	--end
end

function scuttle_elec()
	
	aitrace("ScuttleElec elec:"..ElectricityAmountWithEscrow().." coal:"..ScrapAmountWithEscrow().." military:"..fact_selfValue);
	
	if (NumBuildingActive(ResourceRenew_EC)>0 and ScrapPerSec() < 8) then --added ScrapPerSec() criteria so that AI doesn't hurt scuttle lightning rods when it has decent coal income. Not worth losing the rod if AI can wait a few seconds to get coal. 
		Scuttle( ResourceRenew_EC )
		return
	end
	if (NumBuildingActive(ElectricGenerator_EC)>0 and ScrapPerSec() < 8) then
		Scuttle( ElectricGenerator_EC )
		return
	end
end

function scuttle_extrachamber()

	-- if we have more than one of any then scuttle
	if (NumBuildingActive(Aviary_EC)>1) then
		Scuttle( Aviary_EC )
		return
	end
	if (NumBuildingActive(RemoteChamber_EC)>1) then
		Scuttle( RemoteChamber_EC )
		return
	end
	
	if (goal_desireSwimmers == 0 and NumBuildingActive(WaterChamber_EC)>0) then
		Scuttle( WaterChamber_EC )
		return
	end
	if (goal_desireFlyers == 0 and NumBuildingActive(Aviary_EC)>0) then
		Scuttle( Aviary_EC )
		return
	end
end

function doscuttle(lowelec)
	if (NumBuildingActive(GeneticAmplifier_EC)>0) then
		aitrace("ScuttleGeneticAmplifier")
		Scuttle(GeneticAmplifier_EC)
		return
	end
	if (NumBuildingActive(VetClinic_EC)>0) then
		aitrace("ScuttleVetClinic")
		Scuttle(VetClinic_EC)
		return
	end
	if (ElectricityAmountWithEscrow() > 1800) then --Changed from 1600 to 1800 4/7/2019 Bchamp
		scuttle_elec()
		return
	end
	-- if we have a foundry that is empty and if this isn't the only drop off on the map
	if (NumEmptyFoundies() > 0 and CoalPileWithDropOffs() > 0) then
		Scuttle(Foundry_EC)
		return
	end
	if (lowelec==1 and ElectricityAmountWithEscrow() > 150) then --Changed from 50 to 150 4/7/2019 Bchamp
		scuttle_elec()
		return
	end
	if (NumChambers()>1) then
		aitrace("Scuttle: get rid of unused chamber");
		scuttle_extrachamber()
		return
	end
end

function needmorecoal()
	
	-- lots of elec but not much coal and not gathering much either
	if (	(NumHenchmanQ() < 4 or ScrapPerSec() == 0) and
		ScrapAmountWithEscrow() < 250) then
	
		goal_needcoal = 2
	else
		goal_needcoal = 1
	end
	
	-- are we fully satified for coal
	if ( (NumHenchmanQ() == sg_desired_henchman and ScrapPerSec() > 25) or ScrapAmountWithEscrow() > 2500) then
		goal_needcoal = 0
	end
	
	-- following rules apply when we have under 250 coal
	if (ScrapAmountWithEscrow() < 250) then

		local klabAttackVal = LabUnderAttackValue();
		-- tests for low amount of hench, low coal and under attack
		if (NumHenchmanActive() < 7 and 
		((fact_selfValue < 500 and UnderAttackValue() > 100) or (klabAttackVal>fact_selfValue*2.0 and klabAttackVal>400)) ) then
			aitrace("Script: Low Coal, Few Hench, Under Attack, Sell Stuff If we can");
			if (klabAttackVal>fact_selfValue*4.0 and klabAttackVal > 800) then
				doscuttle(1)
			else
				doscuttle(0)
			end
			
			return
		end
						
		-- tests to see if we have enough money for tower
		-- Changed LabUnderAttackValue() > 200 from 100. AI scuttled lightning rods too quickly in testing. 3/31/2019 Bchamp
		local numSBTower = NumBuildingQ( SoundBeamTower_EC )
		if (fact_selfValue < 100 and numSBTower == 0 and LabUnderAttackValue() > 200) then
			-- do some scuttling
			aitrace("Script: No military, no towers, lots of elec, scuttle");
			doscuttle(1)
			return
		end
		-- if our lab is under attack by more than 4 times
		if (LabUnderAttackValue() > (fact_selfValue*4+600*numSBTower + 200)) then
			aitrace("Script: Really being attacked hard X4, sell stuff");
			doscuttle(1)
			return
		end
		
		-- low coal and long distance mining - scuttle extra shit
		if (CoalPileWithDropOffs() == 0) then
			doscuttle(0)
		end
		
	end
	
end


-- this function determines how much electricity we should aim for
function needmoreelec()
	
	sg_desired_elecrate = 11 --Baseline elec rate is 8 rods + gen without upgrades

	local curRank = GetRank()

	-- 2 rods - for early game
	if (curRank < 2 and ResearchQ(RESEARCH_Rank2) == 0) then
		sg_desired_elecrate = 4
	end
	
	
	--Added by Bchamp 3/9/19 to customize ai elec rates
	if (ResearchQ(RESEARCH_Rank2) == 1 or curRank == 2) then
		sg_desired_elecrate = 6 	-- Set desired Elec rate to 3 rods after starting L2
		if (NumBuildingActive( Foundry_EC ) > 0) then
			sg_desired_elecrate = 11 + NumBuildingActive( Foundry_EC )*6
		end
	end

	if (curRank == 3) then
		sg_desired_elecrate = 16 + NumBuildingActive( Foundry_EC )*6
	end

	if (curRank >= 4) then
		sg_desired_elecrate = 26 + NumBuildingActive( Foundry_EC )*6
	end

	if (curRank >= 2) then
		-- on island map, desire more electricity
		if (fact_closestGroundDist == 0) then
	 		sg_desired_elecrate = sg_desired_elecrate + 6
	 
		 -- on large map desire more electricity
	 	elseif (fact_closestGroundDist > 700) then

			sg_desired_elecrate = sg_desired_elecrate + 12
	
		elseif (fact_closestGroundDist > 350) then --changed from 350 to 0 for testing. Bchamp 1/4/2019.

			sg_desired_elecrate = sg_desired_elecrate + 6
		
		end

	
		-- increase electricity if we have more scrap then elec and we are below rank4 and have a chamber
		if (curRank < 4 and NumChambers()>0 and ElectricityAmount() < 50 and ScrapAmount() > 500) then
			sg_desired_elecrate = sg_desired_elecrate+2
		end
		-- if have a 2 to 1 ratio of coal to elec, build more elec 
		if (NumChambers()>0 and ElectricityAmount() < 200 and ScrapAmount() > 400) then
			sg_desired_elecrate = sg_desired_elecrate+(ScrapAmount()/400)
		end
	
		-- if our lowest rank guy is high then get more elec to speed the ranking process
		if (fact_lowrank_all > 2 and curRank < fact_lowrank_all) then
			-- increase elec rate by lowest rank, so for rank3,4,5 increase by 2,4,6
			sg_desired_elecrate = sg_desired_elecrate+(fact_lowrank_all-2)*2
		end
	end	

	-- must have 1 chamber and some creatures to desire more elec
	if (NumChambers()>0 and fact_selfValue>1000) then
		sg_desired_elecrate = sg_desired_elecrate+2
		
		-- an even better army
		if (fact_selfValue >= 2500) then
			sg_desired_elecrate = sg_desired_elecrate+(fact_selfValue/2500)*1.5
		end
	
		if (curRank > 2) then
			sg_desired_elecrate = sg_desired_elecrate+2
		end
		
		if (curRank > 4) then
			sg_desired_elecrate = sg_desired_elecrate+2
		end
	end
	
	-- if the current army average is high, increase elec rates
	if (fact_armyAvgElec>60) then
		sg_desired_elecrate = sg_desired_elecrate+(fact_armyAvgElec-40)/20
	end

	-- Adjust desired erate for LOD
	if (g_LOD == 0 and sg_desired_elecrate >= 6) then
		sg_desired_elecrate = sg_desired_elecrate*0.6
	end

	if (g_LOD == 1 and sg_desired_elecrate >= 8) then
		sg_desired_elecrate = sg_desired_elecrate*0.8
	end
	
	-- if have achieved our rate and our coal rate is good and we have a
	-- decent military we can increase our rate by a bit

	if (ElectricityPerSec() == 0 and ElectricityAmountWithEscrow() < 250) then
		goal_needelec = 2
	else
		goal_needelec = 1
	end
	
	if (ElectricityPerSecQ() >= sg_desired_elecrate or ElectricityAmountWithEscrow() > 1800) then
		goal_needelec = 0
	end
	

end

function Logic_set_escrow()

	-------------------------------------
	-- phase determination of the game
	-------------------------------------
	
	-- if we have more than twice the population than continue ranking up
	-- OR whatelse? if we are winning with less creatures or if we have a higher ranking
	-- OR maybe we have more money coming in ??
	
	if (NumBuildingActive( ResourceRenew_EC ) > 0) then
		SetGatherEscrowPercentage(15)
		SetRenewEscrowPercentage(20)
	end
	

	-- if we just got our last rank then set escrow down
	if (GetRank() == fact_army_maxrank) then
		
		SetGatherEscrowPercentage(10)
		SetRenewEscrowPercentage(10)
				
		-- keep releasing escrow, it should be turned off in late game
		if (ScrapAmountWithEscrow() > 1000) then
			ReleaseGatherEscrow()
		end
		if (ElectricityAmountWithEscrow() > 1500) then
			ReleaseRenewEscrow()
		end
		
	end
	
	-- release money for building more creatures
	if (LabUnderAttackValue() > 200 and fact_enemyValue > (fact_selfValue*2)) then
		ReleaseGatherEscrow()
		ReleaseRenewEscrow()
		aitrace("Script: Escrow release: Under attack")
	end
		
end

function doai()

	doweneedmoney();
	needmorecoal();
	needmoreelec();
	doresearch();
	
	Logic_set_escrow();
	
end

RegisterTimerFunc("doai", 2.0 )

