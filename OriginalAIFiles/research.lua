
function init_research()
	
	aitrace("init_research()")
	
	-- flags for what research is available determined by the script
	sg_research = {}
	sg_research[RESEARCH_AdvancedStructure] = 1
	sg_research[RESEARCH_HenchmanYoke] = 1
	sg_research[RESEARCH_HenchmanHeal] = 0
	sg_research[RESEARCH_HenchmanBinoculars] = 0
	sg_research[RESEARCH_HenchmanTag] = 0
	sg_research[RESEARCH_HenchmanMotivationalSpeech] = 1
	sg_research[RESEARCH_StrengthenFences] = 0
	sg_research[RESEARCH_StrengthenElectricalGrid] = 1
	sg_research[RESEARCH_IncBuildingIntegrity] = 1
	sg_research[RESEARCH_HenchmanImprovedHealing] = 0
	sg_research[RESEARCH_TowerUpgrade] = 1
	
	if (g_LOD==0) then
		sg_research[RESEARCH_HenchmanHeal] = 1
		sg_research[RESEARCH_HenchmanBinoculars] = 1
		sg_research[RESEARCH_StrengthenFences] = 1
		sg_research[RESEARCH_HenchmanImprovedHealing] = 1
	end
	
	-- what rank do we want to stop at
	sg_maxrank = 5
	
	-- set the ranking logic
	if (g_LOD == 0) then
		Logic_setmaxrank = Logic_setmaxrank_easy
	elseif (g_LOD == 1) then
		Logic_setmaxrank = Logic_setmaxrank_standard
	else
		Logic_setmaxrank = Logic_setmaxrank_hard
	end
end

-- rank helper function
function rankUp( capAt )

	-- whats our current Rank
	local curRank = GetRank();
	
	-- if we have more ranks to go
	if (curRank < fact_army_maxrank and curRank < capAt) then
		
		-- find next rank:
		-- if curRank is 1 then next rank is Rank2+0 or curRank-1
		-- if curRank is 4 then next rank is Rank2+3 or curRank-1
		if (CanResearchWithEscrow( RESEARCH_Rank2 + curRank - 1 ) == 1) then
			ReleaseGatherEscrow()
			ReleaseRenewEscrow()
			xResearch( RESEARCH_Rank2 + curRank - 1);
			-- var used to delay AI in easy
			aitrace("Script: rank"..(curRank+1));
		end
	end
end

sg_followToRank = 1

function rank_delay_func()
	
	-- get AI to NOW do its research
	local bestplayer_rank = PlayersRank( player_enemy, player_max )
	aitrace("Script: RankUp:"..bestplayer_rank.." Delay")
	sg_followToRank = bestplayer_rank
	-- remove this timer
	RemoveTimerFunc("rank_delay_func")
end

sg_researchRand = Rand(120)

function Logic_setmaxrank_easy()

	sg_maxrank = 1

	local curRank = GetRank()
	
	-- this makes sure the AI does not rank up when attacked, unless it has no available creatures at the current
	-- rank
	if (curRank >= fact_lowrank_all and (LabUnderAttackValue() > 100 or UnderAttackValue() > fact_selfValue*1.5) and ScrapAmountWithEscrow()<1000) then
		sg_maxrank = 1
		return
	end
			
	local gametime = GameTime()
	
	if (gametime > (6*60+sg_researchRand) or ScrapAmountWithEscrow() > 1800) then
		sg_maxrank = 2
	end
	
	if (gametime > (16*60+sg_researchRand)) then
		sg_maxrank = 3
	end
	
	if (gametime > (25*60+sg_researchRand*3)) then
		sg_maxrank = 4
	end
		
	-- play follow the leader with the ranks
	local bestplayer_rank = PlayersRank( player_enemy, player_max )
	
	--
	if (sg_maxrank < bestplayer_rank and sg_followToRank < bestplayer_rank) then
		if (IsTimerFuncRegistered("rank_delay_func") == 0) then
			local delayBy = (sg_researchRand/8)*bestplayer_rank
			RegisterTimerFuncDelay("rank_delay_func", delayBy)
			aitrace("Script: Delay rank by "..delayBy)
		end
	end
	if (sg_followToRank > sg_maxrank) then
		sg_maxrank = sg_followToRank
	end
	
	-- if this rank is lower than our lowest rank then continue to our lowest rank
	if (UnderAttackValue() > 0 and sg_maxrank < fact_lowrank_all) then
		sg_maxrank = fact_lowrank_all
	end
		
end

function Logic_setmaxrank_standard()

	sg_maxrank = 1

	local curRank = GetRank()
	
	-- this makes sure the AI does not rank up when attacked, unless it has no available creatures at the current
	-- rank
	local numSBTower = NumBuildingActive(SoundBeamTower_EC)
	if (curRank >= fact_lowrank_all and (LabUnderAttackValue() > (100+numSBTower*200) or UnderAttackValue() > fact_selfValue*1.5) and ScrapAmountWithEscrow()<700) then
		sg_maxrank = 1
		return
	end
			
	local gametime = GameTime()
	
	if (gametime > (2*60+sg_researchRand/2) or fact_enemyValue > 300 or ScrapAmountWithEscrow() > 1500) then
		sg_maxrank = 2
	end
	
	if (gametime > (7*60+sg_researchRand)) then
		sg_maxrank = 3
	end
	
	if (gametime > (14*60+sg_researchRand)) then
		sg_maxrank = 4
	end
	
	if (gametime > (18*60+sg_researchRand*2)) then
		sg_maxrank = 5
	end
		
	-- play follow the leader with the ranks
	local bestplayer_rank = PlayersRank( player_enemy, player_max )
	
	if (sg_maxrank < bestplayer_rank and sg_followToRank < bestplayer_rank) then
		if (IsTimerFuncRegistered("rank_delay_func") == 0) then
			local delayBy = (sg_researchRand/15)*bestplayer_rank
			RegisterTimerFuncDelay("rank_delay_func", delayBy)
			aitrace("Script: Delay rank by "..delayBy)
		end
	end
	if (sg_followToRank > sg_maxrank) then
		sg_maxrank = sg_followToRank
	end
	
	-- if this rank is lower than our lowest rank then continue to our lowest rank
	if (UnderAttackValue() > 0 and sg_maxrank < fact_lowrank_all) then
		sg_maxrank = fact_lowrank_all
	end
	
end

function Logic_setmaxrank_hard()

	-- this makes sure the AI does not rank up when attacked, unless it has no available creatures at the current
	-- rank
	if (GetRank() >= fact_lowrank_all and (LabUnderAttackValue() > 100 or UnderAttackValue() > fact_selfValue*1.5) and ScrapAmountWithEscrow() < 750) then
		sg_maxrank = 1
		return
	end
	
	sg_maxrank = 5
		
end

function Logic_doadvancedresearch()
	
	-- don't research this if we are not in rank2 or we don't have some army
	-- unless our army isn't available until r4
	if (g_LOD == 2 and (ResearchCompleted(RESEARCH_Rank2)==0 or (fact_selfValue < 700 and fact_lowrank_all<4))) then
		return
	end
	
	-- if in standard randomly do this research before rank2 research (so most of the time the AI will wait for r2)
	if (g_LOD == 1 and (ResearchCompleted(RESEARCH_Rank2)==0 and sg_researchRand > 20)) then
		return
	end
	
	-- in easy, research this when its available
	
	if (CanResearchWithEscrow(RESEARCH_AdvancedStructure)==1) then
		ReleaseGatherEscrow()
		ReleaseRenewEscrow()
		xResearch( RESEARCH_AdvancedStructure );
		aitrace("Script: Advanced structure research")
	end
end

function TowerCount()
	
	return NumBuildingActive(SoundBeamTower_EC) + NumBuildingActive(AntiAirTower_EC)
	
end

function dovetclinicresearch()
	
	-- how many creatures do I have
	local militaryPop = PopulationActive() - NumHenchmanActive();

	-- wait for egen unit to be built first before any other research is done (saves money for later)
	if (ResearchCompleted(RESEARCH_Rank2)==1 and (militaryPop > 6 or (fact_lowrank_all>3 and GetRank() < fact_lowrank_all))) then
	
		-- only do these two in standard and hard
		if (g_LOD > 0) then
		
			-- should try to get this as soon as possible
			if (sg_research[RESEARCH_HenchmanYoke] == 1 and CanResearchWithEscrow(RESEARCH_HenchmanYoke)==1) then
				ReleaseGatherEscrow()
				ReleaseRenewEscrow()
				xResearch( RESEARCH_HenchmanYoke );
				aitrace("Script: Henchman Yoke Research")
			end
			
			-- RESEARCH_HenchmanMotivationalSpeech
			if (sg_research[RESEARCH_HenchmanMotivationalSpeech] == 1 and CanResearchWithEscrow(RESEARCH_HenchmanMotivationalSpeech) == 1) then
				ReleaseGatherEscrow()
				ReleaseRenewEscrow()
				Research( RESEARCH_HenchmanMotivationalSpeech );
				aitrace("Script: Research henchman motivational speech")
			end
			
		end
		
		-- do these research items after rank3
		if (ResearchCompleted(RESEARCH_Rank3)==1) then

			-- henchman heal
			if (sg_research[RESEARCH_HenchmanHeal] == 1 and CanResearchWithEscrow(RESEARCH_HenchmanHeal) == 1) then
				ReleaseGatherEscrow()
				ReleaseRenewEscrow()
				xResearch( RESEARCH_HenchmanHeal );
				aitrace("Script: Research henchman heal")
			end
		
			-- henchman binoculars
			if (sg_research[RESEARCH_HenchmanBinoculars] == 1 and CanResearchWithEscrow(RESEARCH_HenchmanBinoculars) == 1) then
				ReleaseGatherEscrow()
				ReleaseRenewEscrow()
				Research( RESEARCH_HenchmanBinoculars );
				aitrace("Script: Research henchman binoculars")
			end
			
			-- RESEARCH_IncBuildingIntegrity
			if (sg_research[RESEARCH_IncBuildingIntegrity] == 1 and CanResearchWithEscrow(RESEARCH_IncBuildingIntegrity) == 1) then
				ReleaseGatherEscrow()
				ReleaseRenewEscrow()
				Research( RESEARCH_IncBuildingIntegrity );
				aitrace("Script: Research building integrity")
			end
		end
		
		-- delay these researches
		if (ResearchCompleted(RESEARCH_Rank4)==1) then
			
			-- RESEARCH_StrengthenFences
			if (sg_research[RESEARCH_StrengthenFences] == 1 and CanResearchWithEscrow(RESEARCH_StrengthenFences) == 1) then
				ReleaseGatherEscrow()
				ReleaseRenewEscrow()
				Research( RESEARCH_StrengthenFences );
				aitrace("Script: Research stronger fences")
			end
	
			-- RESEARCH_StrengthenElectricalGrid
			if (sg_research[RESEARCH_StrengthenElectricalGrid] == 1 and goal_needelec == 1 and 
				CanResearchWithEscrow(RESEARCH_StrengthenElectricalGrid) == 1) then
				ReleaseGatherEscrow()
				ReleaseRenewEscrow()
				Research( RESEARCH_StrengthenElectricalGrid );
				aitrace("Script: Research electrical grid")
			end
	
			-- RESEARCH_HenchmanImprovedHealing
			if (sg_research[RESEARCH_HenchmanImprovedHealing] == 1 and CanResearchWithEscrow(RESEARCH_HenchmanImprovedHealing) == 1) then
				ReleaseGatherEscrow()
				ReleaseRenewEscrow()
				Research( RESEARCH_HenchmanImprovedHealing );
				aitrace("Script: Research henchman improved healing")
			end
	
			-- RESEARCH_TowerUpgrade
			if (sg_research[RESEARCH_TowerUpgrade] == 1 and TowerCount() > 2 and CanResearchWithEscrow(RESEARCH_TowerUpgrade) == 1) then
				ReleaseGatherEscrow()
				ReleaseRenewEscrow()
				Research( RESEARCH_TowerUpgrade );
				aitrace("Script: Research building integrity")
			end
		end
	
	end -- end of check for egen research
end

function doresearch()

	-- determine if we should rank up
	Logic_setmaxrank()
	
	-- make sure we are not hurtin for either type of funds and we have a few dudes
	if (goal_needcoal == 2 or goal_needelec ==2 and NumHenchmanActive() < 4) then
		return
	end
	
	-- cap the rank to 3 if we don't have any chambers up
	-- this means we will stop ranking when at rank3 and instead try 
	-- to set up chambers (unless we only have units above r
	if (NumChambers()==0 and sg_maxrank > 3 and fact_lowrank_all < 4 and ScrapAmountWithEscrow()<1000) then
	   	sg_maxrank = 3
	end
	
	-- this says rank up to sg_maxrank given the funds
	rankUp( sg_maxrank );
	
	-- do not do anyresearch when base is under attack or we are being attack by 1.5 times our force value
	if (LabUnderAttackValue() > 100 or UnderAttackValue() > fact_selfValue*1.5 ) then
		return
	end

	-- do this when enemy is in rank3 or we are in rank3
	
	if (sg_research[RESEARCH_AdvancedStructure] == 1) then
		Logic_doadvancedresearch()
	end

	if (NumBuildingActive(VetClinic_EC)>0) then
		dovetclinicresearch()
	end
end