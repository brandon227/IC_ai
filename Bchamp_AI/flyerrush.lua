aitrace("Script Component: FlyerRush Tactic")
--This has not been modified for L2 flyers 2/20/2022 Bchamp
function FlyerRush_CanDo(ForceTactic)

	local closestenemy = ClosestEnemy(1)
	local closestDist = 100000
	-- non amphib dist
	if (closestenemy > -1) then
		closestDist = Player_Dist(closestenemy, 1)
	end
	
	local moreEnemies =PlayersAlive( player_enemy )-PlayersAlive( player_ally )
	
	aitrace("FlyerRush: Testing AmphibDist("..closestDist..")")
	aitrace("FlyerRush: Testing AirDist("..fact_closestAirDist..")")
	aitrace("FlyerRush: MoreEnemies("..moreEnemies..")")
	
	-- just hold on creatures enemy has more than X amount

	if (g_LOD >= 1 and fact_lowrank_flyer <= 3) then
		
		local rushChance = 100
		 
		if (fact_closestAmphibDist > 650) then
			rushChance = 5
		elseif (fact_closestAmphibDist > 550) then
			rushChance = 6
		elseif (fact_closestAmphibDist > 350) then
			rushChance = 7
		end
		
		if (moreEnemies < 0) then
			rushChance = rushChance - 1
		end

		if (Rand(10) > rushChance or ForceTactic == 7) then
			save_Logic_set_escrow = Logic_set_escrow
			rawset(globals(), "Logic_set_escrow", nil )
			Logic_set_escrow = FlyerRush_Logic_set_escrow
			
			save_Logic_creatureTypeDesire = Logic_creatureTypeDesire
			rawset(globals(), "Logic_creatureTypeDesire", nil )
			Logic_creatureTypeDesire = FlyerRush_Logic_creatureTypeDesire

			save_Logic_military_setgroupsizes = Logic_military_setgroupsizes
			rawset(globals(), "Logic_military_setgroupsizes", nil )
			Logic_military_setgroupsizes = FlyerRush_Logic_military_setgroupsizes

			save_docreaturechamber = docreaturechamber
			rawset(globals(), "docreaturechamber", nil )
			docreaturechamber = FlyerRush_docreaturechamber
			
			aitrace("FlyerRush: Running")
		end	
	
		return 1
	end
	
	return 0
end

function FlyerRush_docreaturechamber()
	local numActiveChambers = NumBuildingActive( RemoteChamber_EC )
	local curRank = GetRank()

	if NumBuildingActive( Aviary_EC ) <= 2 then
		return 0
	end

end

function FlyerRush_Logic_military_setgroupsizes()
	local curRank = GetRank()
	local rankMultiplier = rankValue[curRank]

	icd_groundgroupminsize = 6 + rand4b; 
	icd_groundgroupmaxsize = 100;
	
	icd_groundgroupminvalue = icd_groundgroupminsize*rankMultiplier;
	icd_groundgroupmaxvalue = icd_groundgroupmaxsize*rankMultiplier*2;

	local unitCount = PlayersUnitTypeCount( Player_Self(), player_max, sg_class_flyer )
	if (fact_selfValue > fact_enemyValue*1.5 and unitCount > (icd_groundgroupminsize*1.5)) then
		icd_groundgroupminsize = rand2b + 1
		icd_groundgroupminvalue = icd_groundgroupminsize*rankMultiplier
	end

	icd_airgroupminsize = icd_groundgroupminsize
	icd_airgroupminvalue = icd_groundgroupminvalue

	icd_airgroupmaxsize = icd_groundgroupmaxsize
	icd_airgroupmaxvalue = icd_groundgroupmaxvalue

	icd_engageEnemyValueModifier = 0.5
end

function FlyerRush_Logic_creatureTypeDesire()

	local numAATower = PlayersUnitCount( player_enemy, player_max, AntiAirTower_EC )
	local EnemyRangeValue = PlayersUnitTypeValue( player_enemy, player_max, sg_class_directrange)
	
	--local directRangeValue = 0
	--local chosenEnemy = GetChosenEnemy()
	--if (chosenEnemy ~= -1) then
	--	directRangeValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_directrange )
	--end
	
	-- do we want swimmers at this time
	goal_desireSwimmers = 0
	goal_desireFlyers = 5
	goal_desireGround = 0
	
	-- when do we reset this function
	if (UnderAttackValue()>0  or DamageTotal() > 100 or numAATower>1 or EnemyRangeValue > 600) then
		Cancel_FlyerRush()
	end
	
end

function FlyerRush_Logic_set_escrow()

	if (goal_needcoal==2 or NumHenchmanQ() < 6) then
		SetGatherEscrowPercentage(10)
		SetRenewEscrowPercentage(10)
	else
		SetGatherEscrowPercentage(40)
		SetRenewEscrowPercentage(40)
	end
				
	-- have we started researching rank3 or are we underattack
	if (ResearchQ(RESEARCH_Rank3)==1 or UnderAttackValue() > 0 or DamageTotal() > 0) then
		rawset(globals(), "Logic_set_escrow", nil )
		Logic_set_escrow = save_Logic_set_escrow
	end

end

function Cancel_FlyerRush()
	
	rawset(globals(), "Logic_military_setgroupsizes", nil )
	Logic_military_setgroupsizes = save_Logic_military_setgroupsizes

	rawset(globals(), "docreaturechamber", nil )
	docreaturechamber = save_docreaturechamber

	rawset(globals(), "Logic_creatureTypeDesire", nil )
	Logic_creatureTypeDesire = save_Logic_creatureTypeDesire
	
	rawset(globals(), "Logic_set_escrow", nil )
	Logic_set_escrow = save_Logic_set_escrow

	init_military()
end
