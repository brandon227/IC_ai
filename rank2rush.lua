--Created by Bchamp on 9/27/2018 in an attempt to convince AI to perform a rank 2 chamber rush--
--TO DO LIST --
--Perhaps use the Value/EnemyValue to determine whether or not to expand

aitrace("Script Component: Rank2Rush Tactic")

function Rank2Rush_CanDoTactic()

	-- only do this in difficult and non-quick start resources
	if (g_LOD ~= 2 or ScrapAmountWithEscrow() > 1000) then
		return 0
	end
	
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
	if (numEnemies > numAllies) then
		return 0
	end
	
	local randtemp = Rand(10)
	aitrace("Rank2Rush: Rand:"..randtemp)
	-- test for rank2 tactic
	-- if currently lvl 1, enemy is close, and randomness allows, perform rush.
	
	if (GetRank() == 1 and closestDist < 350 and randtemp > 6) then
		-- have the units for a rank2 ground rush
		local units = Army_ClassSize( Player_Self(), sg_class_groundrank2rush )
		if (units > 0) then
			goal_rank2rush = 1
		end
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
	
		icd_startAtRank = 1
	
		aitrace("Rank2Rush: Running")
		
		return 1
	end
	
	return 0
	
end

function Rank2Rush_rankUp()

	local curRank = GetRank();
	if (NumBuildingQ( RemoteChamber_EC ) > 0) then
		if (CanResearchWithEscrow( RESEARCH_Rank2 + curRank - 1 ) == 1) then
			ReleaseGatherEscrow()
			ReleaseRenewEscrow()
			xResearch( RESEARCH_Rank2 + curRank - 1);
			-- var used to delay AI in easy
			aitrace("Script: rank"..(curRank+1));
		end
	end

	if (curRank > 1 or UnderAttackValue() > 10) then
		rawset(globals(), "rankUp", nil )
		rankUp = save_rankUp
	end

end



function Rank2Rush_Logic_military_setdesiredcreatures()

	sg_creature_desired = 30
	
	-- check enemy ranks
	local maxrank = PlayersRank(player_enemy, player_max)
	
	if (maxrank > 2 or LabUnderAttackValue()>100 or GetRank()>2 or NumCreaturesQ()>10) then
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
	
	--Check for reseraching lvl 2 in queue before building chamber.
	--if (ResearchQ(RESEARCH_Rank2) == 1) then

	local basePlacement = PH_OutsideBase
	local chamberAtEnemyBase = 0
	if(Rand(10) > 3) then
		basePlacement = PH_EnemyBase
		chamberAtEnemyBase = 1
	end

	if (NumBuildingQ( ResourceRenew_EC ) > 1) then

		if (NumBuildingQ( RemoteChamber_EC ) < 1) then
			--local save_maxgatherers = icd_maxgatherers
			--icd_maxgatherers = NumHenchmanActive()-2

			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
		
			xBuild( RemoteChamber_EC, basePlacement );
			aitrace("Script: Build first creature chamber")

			--reset max gatherers
			--icd_maxgatherers = save_maxgatherers
		end
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
			if(Rand(10) > 8 and DamageTotal() < 30) then
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
	
	-- ADD CODE TO BUILD 3RD ROD??? When to increase desired erate?? When NumCreaturesQ() > X???
	-- if ( curRank == 2 and Num

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
	
	if (numQ < sg_lightningrod_cap and CanBuildWithEscrow( ResourceRenew_EC )==1) then
		ReleaseGatherEscrow();
		ReleaseRenewEscrow();
		xBuild( ResourceRenew_EC, 0 );
		aitrace("Script:build rod for rate "..(erate+2).." of "..sg_desired_elecrate);
	end


	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );
	
	-- call old code if these conditions are met
	if ((NumBuildingActive( RemoteChamber_EC ) > 0 and militaryValue > 700) or LabUnderAttackValue()>100 or GameTime() > (4.5*60)) then
		-- add the old code back in
		rawset(globals(), "dolightningrods", nil )
		dolightningrods = save_dolightningrods
	end
	
		
end

function Rank2Rush_dofoundry()

	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );
	
	-- call old code if these conditions are met
	if ((NumBuildingActive( RemoteChamber_EC ) > 0 and militaryValue > 1800) or LabUnderAttackValue()>100 or GameTime() > (5.5*60)) then
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

	icd_groundgroupminsize = 4;
	icd_groundgroupmaxsize = 4;
	
	icd_groundgroupminvalue = 500;
	icd_groundgroupmaxvalue = 1000;
	
	local unitCount = PlayersUnitTypeCount( Player_Self(), player_max, sg_class_ground )

	if (unitCount > 3) then
		icd_groundgroupminsize = 1
		icd_groundgroupminvalue = 1
	end

	if (GetRank() > 2 or LabUnderAttackValue() > 100) then
		rawset(globals(), "Logic_military_setgroupsizes", nil )
		Logic_military_setgroupsizes = save_Logic_military_setgroupsizes
	end
end


function Rank2Rush_Logic_desiredhenchman()
	
	local curRank = GetRank()
	local unitCount = PlayersUnitTypeCount( Player_Self(), player_max, sg_class_ground )

	if (curRank == 1) then
		sg_desired_henchman = 11
	else
		sg_desired_henchman = (13 + unitCount/3)

		if ( NumHenchmenGuarding()>2 or NumHenchmanQ() > 12) then
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
	end
		
	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );
			
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