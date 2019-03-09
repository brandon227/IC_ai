aitrace("Script Component: ResearchRush Tactic")

function ResearchRush_CanDo()

	--local numEnemies = PlayersAlive( player_enemy )
	
	local closestenemy = ClosestEnemy(1)
	local closestDist = 100000
	-- non amphib dist
	if (closestenemy > -1) then
		closestDist = Player_Dist(closestenemy, 1)
	end
	
	aitrace("ResearchRush: Testing AmphibDist("..closestDist..")")
	
	-- just hold on creatures enemy has more than X amount

	-- could randomly decide to hold off on building any creature and rush to rank3
	if (g_LOD > 1 and fact_army_maxrank >= 3) then
		
		local rushChance = 100
		 
		if (fact_closestAmphibDist > 800) then
			rushChance = 6
		elseif (fact_closestAmphibDist > 600) then
			rushChance = 7
		elseif (fact_closestAmphibDist > 400) then
			rushChance = 8
		end
		
		if (Rand(10) > rushChance) then
			save_Logic_set_escrow = Logic_set_escrow
			rawset(globals(), "Logic_set_escrow", nil )
			Logic_set_escrow = ResearchRush_Logic_set_escrow
			
			save_Logic_military_setdesiredcreatures = Logic_military_setdesiredcreatures
			rawset(globals(), "Logic_military_setdesiredcreatures", nil )
			Logic_military_setdesiredcreatures = ResearchRush_Logic_military_setdesiredcreatures
			
			-- turn off henchman expansion - only build to threshold
			goal_dohenchmanexpand = 0
			
			aitrace("ResearchRush: Running")
			return 1
		end	
			
	end
	
	return 0
end

function ResearchRush_Logic_set_escrow()

	if (goal_needcoal==2 or NumHenchmanQ() < 6) then
		SetGatherEscrowPercentage(10)
		SetRenewEscrowPercentage(10)
	else
		SetGatherEscrowPercentage(40)
		SetRenewEscrowPercentage(40)
	end
				
	-- have we started researching rank3 or are we underattack
	if (ResearchQ(RESEARCH_Rank3)==1 or UnderAttackValue() > 0) then
		rawset(globals(), "Logic_set_escrow", nil )
		Logic_set_escrow = save_Logic_set_escrow
	end

end

function ResearchRush_Logic_military_setdesiredcreatures()

	sg_creature_desired = 0;

	if (ResearchCompleted(RESEARCH_Rank3)==1 or UnderAttackValue() > 0) then
		rawset(globals(), "Logic_military_setdesiredcreatures", nil )
		Logic_military_setdesiredcreatures = save_Logic_military_setdesiredcreatures
		
		goal_dohenchmanexpand = 1
	end

end