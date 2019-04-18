aitrace("Script Component: ResearchRush Tactic")

function ResearchRush_CanDo(ForceTactic)

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
	if (ForceTactic == 6 or (g_LOD > 1 and fact_army_maxrank >= 3)) then
		
		local rushChance = 0
		 
		if (fact_closestAmphibDist > 800) then
			rushChance = 30
		elseif (fact_closestAmphibDist > 600) then
			rushChance = 20
		elseif (fact_closestAmphibDist > 400) then
			rushChance = 10
		end
		
		if (Rand(100) < rushChance or ForceTactic == 6) then
			save_rankUp = rankUp
			rawset(globals(), "rankUp", nil )
			rankUp = ResearchRush_rankUp
			
			save_Logic_set_escrow = Logic_set_escrow
			rawset(globals(), "Logic_set_escrow", nil )
			Logic_set_escrow = ResearchRush_Logic_set_escrow

			save_Logic_desiredhenchman = Logic_desiredhenchman
			rawset(globals(), "Logic_desiredhenchman", nil )
			Logic_desiredhenchman = ResearchRush_Logic_desiredhenchman
			
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

function ResearchRush_rankUp( capAt )
	-- whats our current Rank
	local curRank = GetRank();

	-- if we have more ranks to go
	if (curRank < fact_army_maxrank and curRank < capAt) then
		
		if (CanResearchWithEscrow( RESEARCH_Rank2 + curRank - 1 ) == 1) then
			ReleaseGatherEscrow()
			ReleaseRenewEscrow()
			xResearch( RESEARCH_Rank2 + curRank - 1);
			-- var used to delay AI in easy
			aitrace("Script: rank"..(curRank+1));
		end
	end

	if (ResearchQ(RESEARCH_Rank3)==1 or UnderAttackValue() > 0) then
		rawset(globals(), "rankUp", nil )
		rankUp = save_rankUp
	end

end

function ResearchRush_Logic_desiredhenchman()

	local henchman_count = 9

	if (GetRank() == 2 and IsGatherSiteOpen() > 0) then
		henchman_count = (9*NumBuildingActive( Foundry_EC ) + 16)
	else --if there are no gather sites open or L1
		henchman_count = (7*NumBuildingActive( Foundry_EC ) + 11)
	end

			
	local mapsizeoffset = 0
	if (fact_closestAmphibDist>400) then
		mapsizeoffset = 2
	end
	if (fact_closestAmphibDist>650) then
		mapsizeoffset = 4
	end
	if (fact_closestAmphibDist>800) then
		mapsizeoffset = 5
	end
	
	henchman_count = henchman_count + mapsizeoffset

	-- maintain a minimum amount of henchman
	if (henchman_count < sg_henchman_min) then
		henchman_count = sg_henchman_min;
	end

	if (henchman_count > sg_henchman_max) then
		henchman_count = sg_henchman_max;
	end

	sg_desired_henchman = henchman_count

	if (ResearchQ(RESEARCH_Rank3)==1 or UnderAttackValue() > 0) then
		rawset(globals(), "Logic_desiredhenchman", nil )
		Logic_desiredhenchman = save_Logic_desiredhenchman
	end

		
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