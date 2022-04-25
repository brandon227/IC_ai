--Created by Bchamp on 9/27/2018 in an attempt to convince AI to perform a rank 2 chamber rush--
--TO DO LIST --
--Perhaps use the Value/EnemyValue to determine whether or not to expand

aitrace("Script Component: Rank2Rush Tactic")

function Rank2Rush_CanDoTactic(ForceTactic)
	
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


	if (ForceTactic == 3) then
		goal_rank2rush = 1
		chamberAtEnemyBase = 0
	elseif (ForceTactic == 4) then
		goal_rank2rush = 1
		chamberAtEnemyBase = 1
	end
	--------------
	--TEST CODE ONLY!! REMOVE FOR RELEASE
	--------------
	--goal_rank2rush = 1
	--------------

	-- should check to see there is only one enemy?
	-- should check to see if he is reachable?
	-- should check island size?
	
	if (goal_rank2rush == 1) then
	
		-- select this enemy to attack
		icd_chooseEnemyOverride = closestenemy
			
		save_rankUp = rankUp
		rawset(globals(), "rankUp", nil )
		rankUp = Rank2Rush_rankUp

		save_dolightningrods = dolightningrods
		rawset(globals(), "dolightningrods", nil )
		dolightningrods = Rank2Rush_dolightningrods
		
		save_dofoundry = dofoundry
		rawset(globals(), "dofoundry", nil )
		dofoundry = Rank2Rush_dofoundry

		save_docreaturechamber = docreaturechamber
		rawset(globals(), "docreaturechamber", nil )
		docreaturechamber = Rank2Rush_docreaturechamber
		
		save_dosoundbeamtowers = dosoundbeamtowers
		rawset(globals(), "dosoundbeamtowers", nil )
		dosoundbeamtowers = Rank2Rush_dosoundbeamtowers
		
		save_Logic_military_setdesiredcreatures = Logic_military_setdesiredcreatures
		rawset(globals(), "Logic_military_setdesiredcreatures", nil )
		Logic_military_setdesiredcreatures = Rank2Rush_Logic_military_setdesiredcreatures
		
		save_Logic_military_setattacktimer = Logic_military_setattacktimer
		rawset(globals(), "Logic_military_setattacktimer", nil )
		Logic_military_setattacktimer = Rank2Rush_Logic_military_setattacktimer	

		save_Logic_military_setgroupsizes = Logic_military_setgroupsizes
		rawset(globals(), "Logic_military_setgroupsizes", nil )
		Logic_military_setgroupsizes = Rank2Rush_Logic_military_setgroupsizes

		save_Logic_desiredhenchman = Logic_desiredhenchman
		rawset(globals(), "Logic_desiredhenchman", nil )
		Logic_desiredhenchman = Rank2Rush_Logic_desiredhenchman
		
		save_Logic_set_escrow = Logic_set_escrow
		rawset(globals(), "Logic_set_escrow", nil )
		Logic_set_escrow = Rank2Rush_Logic_set_escrow
	
		save_Logic_doadvancedresearch = Logic_doadvancedresearch
		rawset(globals(), "Logic_doadvancedresearch", nil )
		Logic_doadvancedresearch = Rank2Rush_Logic_doadvancedresearch

		icd_startAtRank = 1
	
		aitrace("Rank2Rush: Running")
		
		return 1
	end
	
	return 0
	
end

function Rank2Rush_rankUp()

	local curRank = GetRank();

	if NumHenchmanQ() < sg_desired_henchman then
		return
	end

	--If CC is supposed to be at enemy base, make sure it's queued before going L2.
	if(chamberAtEnemyBase == 1) then
		if (NumBuildingQ( RemoteChamber_EC ) < 1 and Rand(100) < 20) then
			return
		end
	end

	--should AI only rank to L2 if it has enough hench? How would this affect Expert difficulty?

	if (CanResearchWithEscrow( RESEARCH_Rank2 + curRank - 1 ) == 1) then
			ReleaseGatherEscrow()
			ReleaseRenewEscrow()
			xResearch( RESEARCH_Rank2 + curRank - 1);
			-- var used to delay AI in easy
			aitrace("Script: rank"..(curRank+1));
	end


	if (curRank > 1 or UnderAttackValue() > 10) then
		rawset(globals(), "rankUp", nil )
		rankUp = save_rankUp
	end

end

function Rank2Rush_Logic_doadvancedresearch()
	--Don't do advanced research
	--Reset once reaches L3


	if (GetRank() > 2) then
		rawset(globals(), "Logic_doadvancedresearch", nil )
		Logic_doadvancedresearch = save_Logic_doadvancedresearch
	end


end

function Rank2Rush_Logic_military_setdesiredcreatures()

	sg_creature_desired = 30
	
	-- check enemy ranks
	local maxrank = PlayersRank(player_enemy, player_max)
	
	if (maxrank > 2 or LabUnderAttackValue()>100 or GetRank()>2 or NumCreaturesActive()>15) then
		rawset(globals(), "Logic_military_setdesiredcreatures", nil )
		Logic_military_setdesiredcreatures = save_Logic_military_setdesiredcreatures
	end

end

function Rank2Rush_dosoundbeamtowers()



	-- if underattack or past rank1 return back to normal behaviour
	if (NumBuildingActive( SoundBeamTower_EC ) >= 1 or LabUnderAttackValue()>100 or GetRank()>2) then
	
		-- add the old code back in
		rawset(globals(), "dosoundbeamtowers", nil )
		dosoundbeamtowers = save_dosoundbeamtowers
	
	end

end


function Rank2Rush_docreaturechamber()

	--Check for reseraching lvl 2 in queue before building chamber at own base.
	if (chamberAtEnemyBase == 0) then
		if (ResearchQ(RESEARCH_Rank2) == 0) then
			return 0
		end
	end

	-- Build Water Chamber if Amphib L2's
	if (fact_lowrank_amphib == 2 and NumBuildingActive( WaterChamber_EC ) == 0) then
		return 0
	end
	-- Don't build CC if you have a Water Chamber and are not actively queuing units.
	if (NumBuildingActive( WaterChamber_EC) == 1 and (NumCreaturesQ() - NumCreaturesActive()) == 0) then
		return 0
	end

	-- Added by Bchamp 4/7/2019 because AI could not build forward chamber on Cenote for some reason (water?). Hopefully this will cancel failed forward chambers
	if (GetRank() > 1 and NumBuildingQ( RemoteChamber_EC ) == 0) then
		chamberAtEnemyBase = 0
	end

	local basePlacement = PH_OutsideBase
	--local chamberAtEnemyBase = 0
	if(chamberAtEnemyBase == 1) then
		basePlacement = PH_EnemyBase
		--chamberAtEnemyBase = 1
	end

	if (NumBuildingQ( ResourceRenew_EC ) > 1) then

		if (NumBuildingQ( RemoteChamber_EC ) < 1) then
			--local save_maxgatherers = icd_maxgatherers
			--icd_maxgatherers = NumHenchmanActive()-2

			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
		
			xBuild( RemoteChamber_EC, basePlacement );
			aitrace("Script: Build first creature chamber")

			return 1
			--reset max gatherers
			--icd_maxgatherers = save_maxgatherers
		end
		return 0
	end


	
	-- Decide to maybe Build SB tower, then return to normal logic once the chamber is up
	if (NumBuildingActive(RemoteChamber_EC) > 0 or DamageTotal() > 50) then
		
		--if the CC has not been built yet, blow CC, cancel rush and reset all modified functions.
		if (NumBuildingActive(RemoteChamber_EC) == 0 and NumBuildingQ(RemoteChamber_EC) > 0 ) then
			

			if (chamberAtEnemyBase == 1) then
				Scuttle( RemoteChamber_EC )
			end

			rawset(globals(), "docreaturechamber", nil )
			docreaturechamber = save_docreaturechamber

			rawset(globals(), "dosoundbeamtowers", nil )
			dosoundbeamtowers = save_dosoundbeamtowers

			rawset(globals(), "dolightningrods", nil )
			dolightningrods = save_dolightningrods

			rawset(globals(), "dofoundry", nil )
			dofoundry = save_dofoundry

			rawset(globals(), "Logic_military_setattacktimer", nil )
			Logic_military_setattacktimer = save_Logic_military_setattacktimer

			rawset(globals(), "Logic_military_setgroupsizes", nil )
			Logic_military_setgroupsizes = save_Logic_military_setgroupsizes

			rawset(globals(), "Logic_desiredhenchman", nil )
			Logic_desiredhenchman = save_Logic_desiredhenchman

			rawset(globals(), "Logic_set_escrow", nil )
			Logic_set_escrow = save_Logic_set_escrow

			rawset(globals(), "Logic_military_setdesiredcreatures", nil )
			Logic_military_setdesiredcreatures = save_Logic_military_setdesiredcreatures

			rawset(globals(), "rankUp", nil )
			rankUp = save_rankUp
		


		--if chamber has been completed, consider adding SB tower near it and then revert to normal chamber placement function
		else
			if(Rand(10) < 2 and DamageTotal() < 30) then
				if (NumBuildingQ( SoundBeamTower_EC ) < 1 and CanBuildWithEscrow( SoundBeamTower_EC ) == 1) then
					ReleaseGatherEscrow();
					ReleaseRenewEscrow();
					xBuild( SoundBeamTower_EC, basePlacement );
					aitrace("Script: Build SB Tower")
				end
			end
			-- add the old code back in
			rawset(globals(), "docreaturechamber", nil )
			docreaturechamber = save_docreaturechamber
		end
	end

end

function Rank2Rush_dolightningrods()

	-- Build 2 LR before lvl 2. 
	-- If creatures are elec expensive, build 3rd and maybe 4th rod after lvl 2.
	-- return to old code after certain conditions are met.

	local erate = ElectricityPerSecQ()
	local rank2rush_desired_erate = 4
	local curRank = GetRank()
	local numHenchman = NumHenchmanActive()	
	local numRods = 0

	-- and NumHenchmanQ() > numHenchman
	if (numHenchman > 3 + rand1a) then
		numRods = 1
	end

	if (numHenchman > 5 + rand1b) then
		numRods = 2
	end

	-- ADD CODE TO BUILD 3RD ROD. Bchamp 4/5/2019
	if (NumBuildingQ( RemoteChamber_EC ) > 0 or (fact_lowrank_amphib == 2 and ResearchQ( RESEARCH_Rank2 ) == 1)) then
		numRods = 3
	end

	-- No more than 2 rods before rank2
	if (NumBuildingQ( ResourceRenew_EC )>1 and (ResearchQ(RESEARCH_Rank2)==0 and g_LOD>0)) then
		return
	end
		
	-- if lab is under attack by more than 3 times our military value
	if ( not(goal_needelec==2 and ElectricityAmountWithEscrow() < 50 and fact_selfValue < 200) and LabUnderAttackValue() > 100) then
		return
	end
	
	local numActive = NumBuildingActive( ResourceRenew_EC )
	local numQ = NumBuildingQ( ResourceRenew_EC )
	
	-- if these numbers are different, then a rod is being built (only build one at a time)
	if ( (numQ-numActive) > 0) then
		return
	end
	
	--Only build 4th rod if enough creatures
	if (NumCreaturesActive() > 5 + rand1c) then
		numRods = 4
	end

	if (numQ < numRods and CanBuildWithEscrow( ResourceRenew_EC )==1) then
		ReleaseGatherEscrow();
		ReleaseRenewEscrow();
		xBuild( ResourceRenew_EC, 0 );
		aitrace("Script:build rod for rate "..(erate+2).." of "..sg_desired_elecrate);
	end


	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );
	
	-- call old code if these conditions are met
	if ((NumBuildingActive( RemoteChamber_EC ) > 0 and militaryValue > 700) or LabUnderAttackValue()>100 or GameTime() > (5.5*60)) then
		-- add the old code back in
		rawset(globals(), "dolightningrods", nil )
		dolightningrods = save_dolightningrods
	end
	
		
end

function Rank2Rush_dofoundry()
	--Don't build foundry.
	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );

	if (militaryValue < 1.3*(fact_enemyValue + 200) and GameTime() < ((5.5+one_v_one)*60)) then
		return
	end

	-- call old code if these conditions are met
	if ((NumBuildingActive( RemoteChamber_EC ) > 0 and NumBuildingActive( Foundry_EC ) > 0) or LabUnderAttackValue() > fact_selfValue or GameTime() > ((5.5+one_v_one)*60)) then
		-- add the old code back in
		rawset(globals(), "dofoundry", nil )
		dofoundry = save_dofoundry
	end


end

--Send units continuously unless after 5.5 minutes on game time or Lab Under Attack--
function Rank2Rush_Logic_military_setattacktimer()

	local wavedelay = 0
	RegisterTimerFunc("attack_now_timer", wavedelay )

	if (LabUnderAttackValue() > 100 or GameTime() > (5.5*60)) then
		rawset(globals(), "Logic_military_setattacktimer", nil )
		Logic_military_setattacktimer = save_Logic_military_setattacktimer
	end	

end

function Rank2Rush_Logic_military_setgroupsizes()

	local numSBTower = PlayersUnitCount( player_enemy, player_max, SoundBeamTower_EC )
	local numEnemyChamber = PlayersUnitCount( player_enemy, player_max, RemoteChamber_EC )
	local numEnemyWC = PlayersUnitCount( player_enemy, player_max, WaterChamber_EC )
	local totalEnemyChambers = numEnemyChamber + numEnemyWC

	local difficulty = LevelOfDifficulty();

	if (chamberAtEnemyBase == 1) then
		icd_groundgroupminsize = 4 + 2*numSBTower;
		icd_groundgroupmaxsize = 5 + 3*numSBTower;
	
		icd_groundgroupminvalue = 500 + (numSBTower * 200);
		icd_groundgroupmaxvalue = 1200 + (numSBTower * 250);

	elseif (one_v_one == 1 and chamberAtEnemyBase == 0) then
		icd_groundgroupminsize = 5 --fact_enemyPop+(2*totalEnemyChambers + difficulty)+2*numSBTower;
		icd_groundgroupmaxsize = 10 + difficulty + difficulty*numSBTower;
	
		icd_groundgroupminvalue = fact_enemyValue*(1.3*(difficulty-2)) + (2*totalEnemyChambers + difficulty + 2*numSBTower)*120; 
		icd_groundgroupmaxvalue = 2500;

	else
		icd_groundgroupminsize = 5; 
		icd_groundgroupmaxsize = 10 + difficulty + difficulty*numSBTower; 

		icd_groundgroupminvalue = fact_enemyValue*(1.3*(difficulty-2)) + (2*totalEnemyChambers + difficulty + 2*numSBTower)*120;
		icd_groundgroupmaxvalue = 2500;

		--Added by Bchamp 4/17/2019 in order to stop AI from just hording units in FFA or Team games and begin attacking, even if it will lose.
		if (icd_groundgroupminvalue > (9*120)) then
			icd_groundgroupminvalue = 9*120
		end
	end

	local unitCount = PlayersUnitTypeCount( Player_Self(), player_max, sg_class_ground )

	--if (unitCount > (icd_groundgroupminsize - chamberAtEnemyBase)) then --or fact_selfValue > 1.3*(fact_enemyValue + 300) + (numSBTower * 200)) then --(2 + difficulty) -(chamberAtEnemyBase*2)
	if (fact_selfValue > icd_groundgroupminvalue - chamberAtEnemyBase*120) then
		icd_groundgroupminsize = 1
		icd_groundgroupminvalue = 1
	end

	--------------------------------------------------
	icd_fleeEnemyValueModifier = 0.65;
	if (numSBTower > 0) then
		icd_fleeEnemyValueModifier = 0.70;
	end
	--------------------------------------------------



	if (GetRank() > 2 or LabUnderAttackValue() > 200) then
		rawset(globals(), "Logic_military_setgroupsizes", nil )
		Logic_military_setgroupsizes = save_Logic_military_setgroupsizes
	end
end


function Rank2Rush_Logic_desiredhenchman()
	
	sg_desired_henchman = sg_henchmanthreshold
	if (chamberAtEnemyBase == 1) then
		sg_desired_henchman = sg_henchmanthreshold + 1
	end

	local henchman_count = sg_desired_henchman
	local curRank = GetRank()
	local unitCount = NumCreaturesQ() --Formerly: PlayersUnitTypeCount( Player_Self(), player_max, sg_class_ground )
	local gatherSiteOpen = IsGatherSiteOpen()

	if (curRank == 1 and gatherSiteOpen > 0) then
		sg_desired_henchman = sg_henchmanthreshold + rand2a
		if (chamberAtEnemyBase == 1) then
			sg_desired_henchman = sg_henchmanthreshold + 1 + rand2a
		end
		henchman_count = sg_desired_henchman
	elseif (curRank == 2 and chamberAtEnemyBase == 1 and (fact_selfValue < 1.3*(fact_enemyValue + 250) or unitCount < 5)) then
		 --If Chamber Rush, How many units should AI have at L2 before building more hench, before checking if coal is filled?
		henchman_count = sg_desired_henchman
	elseif (curRank == 2 and gatherSiteOpen > 0) then --How hench are built if AI is L2 and coal isnt filled
		henchman_count = sg_desired_henchman + (unitCount-1)
	elseif(gatherSiteOpen == 0 and unitCount < ( rand4a + 1)) then --If coal is filled and less than this amount of units, don't build hench
		henchman_count = sg_henchmanthreshold
		-- if gather sites full and less than threshold number of units, check if ampib rush. If yes, build additional hench to account for WC build time.
		if (fact_lowrank_amphib == 2 and NumBuildingQ(WaterChamber_EC) > 0) then
			henchman_count = sg_henchmanthreshold + 2
		end
	elseif (curRank >= 2) then --Once your coal is filled and you have threshold number of units, build this many hench
		if (NumHenchmenGuarding() >= 3) then
			henchman_count = NumHenchmanActive()
		end
		henchman_count = sg_henchmanthreshold + 1 + (unitCount-(2 + rand2b))/2
		if ( NumHenchmenGuarding()>=2 and (fact_selfValue > 1.3*(fact_enemyValue+300) or (ScrapAmountWithEscrow() > 450 and UnderAttackValue() < 200) 
			or (one_v_one == 0 and NumCreaturesActive() >= 10))) then
			local dist2dropoff = DistToDropOff();
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
		
	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );
	
	sg_desired_henchman = henchman_count

	if ((NumBuildingActive( RemoteChamber_EC ) > 0 and militaryValue > 2000) or LabUnderAttackValue() > 100 or GameTime() > (6.5*60) or NumBuildingActive( Foundry_EC ) > 0) then
		rawset(globals(), "Logic_desiredhenchman", nil )
		Logic_desiredhenchman = save_Logic_desiredhenchman
	end
	
end

function Rank2Rush_Logic_set_escrow()

	-- piggy back this call to make sure its called
	AttackNow()
	
	SetGatherEscrowPercentage(10)
	SetRenewEscrowPercentage(10)
	
	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );
			
	if ((NumBuildingActive( RemoteChamber_EC ) > 0 and militaryValue > 2000) or UnderAttackValue()>100 or GameTime() > (6.5*60)) then
		rawset(globals(), "Logic_set_escrow", nil )
		Logic_set_escrow = save_Logic_set_escrow
	end

end

function CancelRank2Rush()

	--rawset(globals(), "docreaturechamber", nil )
	--docreaturechamber = save_docreaturechamber

	rawset(globals(), "dosoundbeamtowers", nil )
	dosoundbeamtowers = save_dosoundbeamtowers

	rawset(globals(), "dolightningrods", nil )
	dolightningrods = save_dolightningrods

	rawset(globals(), "dofoundry", nil )
	dofoundry = save_dofoundry

	rawset(globals(), "Logic_military_setattacktimer", nil )
	Logic_military_setattacktimer = save_Logic_military_setattacktimer

	rawset(globals(), "Logic_military_setgroupsizes", nil )
	Logic_military_setgroupsizes = save_Logic_military_setgroupsizes

	rawset(globals(), "Logic_desiredhenchman", nil )
	Logic_desiredhenchman = save_Logic_desiredhenchman

	rawset(globals(), "Logic_set_escrow", nil )
	Logic_set_escrow = save_Logic_set_escrow

	rawset(globals(), "Logic_military_setdesiredcreatures", nil )
	Logic_military_setdesiredcreatures = save_Logic_military_setdesiredcreatures

	rawset(globals(), "rankUp", nil )
	rankUp = save_rankUp
	--ReleaseGatherEscrow();
	--ReleaseRenewEscrow();
	--xBuild( GeneticAmplifier_EC );
end