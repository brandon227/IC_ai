--NOTE------------------------------------------------------------------------------------
--THIS CODE IS A WORK IN PROGRESS---------------------------------------------------------
------------------------------------------------------------------------------------------
---Last Modified 3/9/19 by Bchamp----------------------------------------------------------
------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------

aitrace("Script Component: EconomyRush Tactic")

function EconomyRush_CanDo(ForceTactic)

	local totalPlayers = PlayersAlive( player_enemy ) + PlayersAlive( player_ally )
	local canDo = 1
	local rushChance = 25 --for a 25% chance of doing this tactic

	if (totalPlayers == 2 and fact_closestAmphibDist < 300) then
		canDo = 0
	elseif (fact_closestAmphibDist < 175) then --200 works so AI can perform tactic on Grove. 225 does not.
		canDo = 0
	elseif (totalPlayers > 2 and PlayersAlive( player_ally ) == 1) then
		--probably a free for all, but could also be on an outnumbered team.
		canDo = 1
		ruchChance = 35
	elseif (PlayersAlive( player_ally ) > PlayersAlive( player_enemy )) then
		canDo = 1
		rushChance = 40
	end

	if (fact_closestAmphibDist > 200) then
		rushChance = rushChance + 5
	end
	if (fact_closestAmphibDist > 350) then
		rushChance = rushChance + 5
	end
	if (fact_closestAmphibDist > 400) then
		rushChance = rushChance + 5
	end
	if (fact_closestAmphibDist > 450) then
		rushChance = rushChance + 5
	end
	if (fact_closestAmphibDist > 500) then
		rushChance = rushChance + 5
	end

	if (g_LOD == 0) then
		canDo = 0
	end

	--------------------------------------
	--TEST CODE SET FORCETACTIC TO 0 BEFORE RELEASE
	--local ForceTactic = 0

	if (ForceTactic == 2) then
		canDo = 1
	end
	--------------------------------------
	--------------------------------------

	-- could randomly decide to go for a late lvl 2 and focus on economy first.
	if (fact_army_maxrank >= 3 and canDo == 1) then
		
		if (Rand(100) < rushChance or ForceTactic == 2) then

			if (Rand(100) < 20) then
				foundryFirst = 1;
			elseif (sg_numscrapyardsWithinDist_near < 5 and Rand(100) < 75) then
				foundryFirst = 1;
			else
				foundryFirst = 0;
			end

			foundryrush = 0; --initialize

			--save_Logic_set_escrow = Logic_set_escrow
			--rawset(globals(), "Logic_set_escrow", nil )
			--Logic_set_escrow = EconomyRush_Logic_set_escrow
			
			--save_Logic_military_setdesiredcreatures = Logic_military_setdesiredcreatures
			--rawset(globals(), "Logic_military_setdesiredcreatures", nil )
			--Logic_military_setdesiredcreatures = EconomyRush_Logic_military_setdesiredcreatures
			
			save_rankUp = rankUp
			rawset(globals(), "rankUp", nil )
			rankUp = EconomyRush_rankUp

			save_Logic_desiredhenchman = Logic_desiredhenchman
			rawset(globals(), "Logic_desiredhenchman", nil )
			Logic_desiredhenchman = EconomyRush_Logic_desiredhenchman
	
			save_dolightningrods = dolightningrods
			rawset(globals(), "dolightningrods", nil )
			dolightningrods = EconomyRush_dolightningrods
		
			save_dofoundry = dofoundry
			rawset(globals(), "dofoundry", nil )
			dofoundry = EconomyRush_dofoundry

			save_doelectricalgenerator = doelectricalgenerator
			rawset(globals(), "doelectricalgenerator", nil )
			doelectricalgenerator = EconomyRush_doelectricalgenerator
			
			aitrace("EconomyRush: Running")
			
			return 1
		end	
			
	end
	
	return 0
end
------------------------------------------------
------------------------------------------------
------------------------------------------------
function EconomyRush_Logic_desiredhenchman()
	local curRank = GetRank();
	local henchman_count = sg_henchmanthreshold
	local NumFoundry = Self.NumFoundry

	if henchman_count > 16 then
		henchman_count = 16
	end

	--always build hench until you have enough electricity to go L2
	if curRank < 2 and ElectricityAmountWithEscrow() < 280 then
		henchman_count = 1000
	else
		--If there is open lab coal then set goal hench. 
		if (NumFoundry == 0) then
			henchman_count = 16 + rand4a --max henchmen to build at lab if gather sites still open.
		else --if you do have a foundry
			henchman_count = henchman_count + 4*NumFoundry + rand4b + foundryFirst;
		end
	end

	sg_desired_henchman = henchman_count


	if (curRank > 1 or UnderAttackValue() > 200) then
		rawset(globals(), "Logic_desiredhenchman", nil )
		Logic_desiredhenchman = save_Logic_desiredhenchman
	end

end

function EconomyRush_dolightningrods()
	
	local erate = ElectricityPerSecQ()
	local curRank = GetRank()

	 -- if we have reached our desired rate then don't build anymore
	if (erate >= sg_desired_elecrate) then
	 	return
	end
	
	local numHenchForRod = 5 + rand2c

	-- wait for 4-6 active henchmen before building first rod
	if (NumHenchmanActive() < numHenchForRod and NumBuildingQ( ResourceRenew_EC )==0) then
		return
	end
	-- require 9 active hench before building second rod
	if ((Self.NumHenchmen < (numHenchForRod + 3) or ScrapAmount() < 250 or Self.QdHenchmen == 0) and Self.NumRods >= 1) then
		return
	end

	--if 
	if (NumBuildingQ(ResourceRenew_EC) >= 1 and foundryrush == 1) then
		return
	end

	-- more than 8 henchmen and more than 2 rods rank2 to start
	if (NumBuildingQ( ResourceRenew_EC )>1 and (ResearchQ(RESEARCH_Rank2)==0 and g_LOD>0)) then
		if (ScrapAmount() < 320 and g_LOD >= 2) then --don't build more than 2 rods unless excess coal before L2
			return
		end
	end
		
	--if doing a foundry first build order, wait to build rods
	if (foundryFirst == 1 and NumBuildingActive( Foundry_EC ) == 0) then
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

	
	--Bchamp 3/30/2019--
	if (curRank > 1 or UnderAttackValue() > 150) then
		rawset(globals(), "dolightningrods", nil )
		dolightningrods = save_dolightningrods
	end

end





function EconomyRush_rankUp()

	local curRank = GetRank();
	local totalPlayers = PlayersAlive( player_enemy ) + PlayersAlive( player_ally )
	local numHenchForRank = sg_desired_henchman

	if totalPlayers == 2 and Enemy.Rank == 2 then
		Cancel_EconomyRush()
	end

	--Level 1 build order
	if Self.Rank == 1 then
		if 	Self.NumHenchmenQ >= numHenchForRank then
			pauseLab = 2
		else
			return
		end
	end
	--Added by Bchamp 3/30/19 for maps with a ton of starting coal. AI won't build foundry so, to compensate, AI will build additional hench.
	--if (NumHenchmanActive() >= (numHenchForRank - 1) and (NumBuildingQ( Foundry_EC ) == 0)) then
	--	numHenchForRank = numHenchForRank + 1
	--end


	if (CanResearchWithEscrow( RESEARCH_Rank2 + curRank - 1 ) == 1 and requestedRank <= Self.Rank) then
		ReleaseGatherEscrow()
		ReleaseRenewEscrow()
		xResearch( RESEARCH_Rank2 + curRank - 1);
		-- var used to delay AI in easy
		aitrace("Script: rank"..(curRank+1));
		requestedRank = Self.Rank + 1
	end


	if (curRank > 1 or UnderAttackValue() > 150) then
		Cancel_EconomyRush()
	end

end

function EconomyRush_dofoundry()

	if foundryFirst == 1 and NumBuildingQ( Foundry_EC ) == 0 and (NumHenchmanActive() >= 6 + rand2b) then
		if (CanBuildWithEscrow( Foundry_EC ) == 1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( Foundry_EC, PH_Best );
			aitrace("Script: build foundry");
			return 1
		end
		aitrace("Script: failed to build foundry");

	elseif (Self.NumFoundry < 1 and ScrapAmount() > 250 and Self.QdHenchmen > 0 and NumBuildingQ( ResourceRenew_EC ) >= 1) then

		if (CanBuildWithEscrow( Foundry_EC ) == 1) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( Foundry_EC, PH_Best );
			aitrace("Script: build foundry");
			sg_desired_henchman = sg_desired_henchman + 1
			return 1
		end
		
		aitrace("Script: failed to build foundry");

	--on big maps with smaller coal start, look into expanding fast, no need to fill gather sites before building next workshop
	elseif fact_closestAmphibDist > 350 and NumHenchmanActive() >= 5 + rand3a then
		local chance_foundryrush = 20
		if sg_henchmanthreshold < 10 then
			chance_foundryrush = chance_foundryrush + 20
		end
		if sg_henchmanthreshold > 12 then
			chance_foundryrush = chance_foundryrush - 15
		end
		if fact_closestAmphibDist > 450 then
			chance_foundryrush = chance_foundryrush + 10
		end
		if fact_closestAmphibDist > 500 then
			chance_foundryrush = chance_foundryrush + 10
		end
		if PlayersAlive(player_ally) ~= PlayersAlive(player_enemy) then
			chance_foundryrush = chance_foundryrush + 5
		end

		if (rand100a < chance_foundryrush) then
			foundryrush = 1
			if NumBuildingQ(Foundry_EC) < 2 and ScrapAmount() > 350 then
				if (CanBuildWithEscrow( Foundry_EC ) == 1) then
					ReleaseGatherEscrow();
					ReleaseRenewEscrow();
					xBuild( Foundry_EC, PH_Best );
					aitrace("Script: build foundry");
					sg_desired_henchman = sg_desired_henchman + 1
					foundryrush = 0;
					return 1
				end
			end
		end
	end

	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );
	
	-- call old code if these conditions are met
	if ( GetRank() > 1 or LabUnderAttackValue() > 150 or GameTime() > (5.5*60)) then
		-- add the old code back in
		rawset(globals(), "dofoundry", nil )
		dofoundry = save_dofoundry
	end


end

function EconomyRush_doelectricalgenerator()
	
	--this determines if we want to build a gen
	local buildGen = 1

	if (LabUnderAttackValue() > 100 or UnderAttackValue() > fact_selfValue*0.5) then
		buildGen = 0
	end
	
	-- this rule states that only build this egen when
	-- we have 2 or more rods present
	if (NumBuildingQ( ResourceRenew_EC ) < 2 and g_LOD ~= 0) then
		buildGen = 0
	end
	
	-- only build generator if foundry exists
	if (NumBuildingActive( Foundry_EC ) < 1) then
		buildGen = 0
	end
	  
	-- are there egens that need upgrading, if so we should upgrade instead of building more egens
	if (NumBuildingQ( ElectricGenerator_EC ) > 0 and EGenNeedsUpgrading()==1) then
		buildGen = 0
	end
		 
	local beingBuilt = NumBuildingQ( ElectricGenerator_EC ) - NumBuildingActive( ElectricGenerator_EC )
	
	if (buildGen == 1) then		 
		if (beingBuilt == 0 and CanBuildWithEscrow( ElectricGenerator_EC ) == 1 and ScrapAmount() > 300) then
			ReleaseGatherEscrow();
			ReleaseRenewEscrow();
			xBuild( ElectricGenerator_EC, PH_OpenGeyser );
			aitrace("Script: Build egen")
		end
	end

	
	-- call old code if these conditions are met
	if ( GetRank() > 1 or LabUnderAttackValue() > 150 or ResearchQ(RESEARCH_Rank2)==1) then
		-- add the old code back in
		rawset(globals(), "doelectricalgenerator", nil )
		doelectricalgenerator = save_doelectricalgenerator
	end
end

function Cancel_EconomyRush()

	rawset(globals(), "rankUp", nil )
	rankUp = save_rankUp

	rawset(globals(), "Logic_desiredhenchman", nil )
	Logic_desiredhenchman = save_Logic_desiredhenchman

	rawset(globals(), "dolightningrods", nil )
	dolightningrods = save_dolightningrods

	rawset(globals(), "dofoundry", nil )
	dofoundry = save_dofoundry

	rawset(globals(), "doelectricalgenerator", nil )
	doelectricalgenerator = save_doelectricalgenerator
end