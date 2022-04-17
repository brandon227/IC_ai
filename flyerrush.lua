aitrace("Script Component: FlyerRush Tactic")
--This has not been modified for L2 flyers 2/20/2022 Bchamp
function FlyerRush_CanDo()

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

	-- could randomly decide to hold off on building any creature and rush to rank3
	if (g_LOD > 1 and fact_lowrank_flyer <= 3 and moreEnemies<=0) then
		
		local rushChance = 100
		 
		if (fact_closestAmphibDist > 800) then
			rushChance = 5
		elseif (fact_closestAmphibDist > 650) then
			rushChance = 6
		elseif (fact_closestAmphibDist > 450) then
			rushChance = 7
		end
		
		if (moreEnemies < 0) then
			rushChance = rushChance - 1
		end
		
		if (Rand(10) > rushChance) then
			save_Logic_set_escrow = Logic_set_escrow
			rawset(globals(), "Logic_set_escrow", nil )
			Logic_set_escrow = FlyerRush_Logic_set_escrow
			
			save_Logic_creatureTypeDesire = Logic_creatureTypeDesire
			rawset(globals(), "Logic_creatureTypeDesire", nil )
			Logic_creatureTypeDesire = FlyerRush_Logic_creatureTypeDesire
			
			-- this code originally turned off hench expansion when doing flyer rush --
			-- it was commented out on 9/26/2018 by Bchamp so that AI could be more balanced --
			-- when performing a flyer rush and maintain economy. --
			-- goal_dohenchmanexpand = 0 --
			
			aitrace("FlyerRush: Running")
		end	
	
		return 1
	end
	
	return 0
end

function FlyerRush_Logic_creatureTypeDesire()

	local numAATower = PlayersUnitCount( player_enemy, player_max, AntiAirTower_EC )
	
	--local directRangeValue = 0
	--local chosenEnemy = GetChosenEnemy()
	--if (chosenEnemy ~= -1) then
	--	directRangeValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_directrange )
	--end
	
	-- do we want swimmers at this time
	goal_desireSwimmers = 0
	goal_desireFlyers = 1
	goal_desireGround = 0
	
	-- when do we reset this function
	if (NumBuildingActive(Aviary_EC) > 0 or UnderAttackValue()>0  or DamageTotal() > 0 or numAATower>1) then
		rawset(globals(), "Logic_creatureTypeDesire", nil )
		Logic_creatureTypeDesire = save_Logic_creatureTypeDesire
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