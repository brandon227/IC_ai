
function init_henchman()

	aitrace("init_henchman()")
	
	-- henchman gathering variables
	
	sg_henchman_min = 8 --Bchamp 4/2/2019. Don't worry, this gets reset later when choosing desired henchmen. Need to keep it low for Pre-L1
	sg_henchman_max = 55 + (Rand(2) * 10) --Changed from 90 on 3/31/2019 by Bchamp to limit too many henchmen and focus on building units. 
	sg_desired_henchman = 50
	
	-- on easy reduce the number of henchmen built
	if (g_LOD == 0) then
		sg_henchman_min = 10
		sg_henchman_max = 18
		sg_desired_henchman = 15
	end
	
	
	if (fact_closestAmphibDist > 400) then
		sg_henchman_max = sg_henchman_max + 6
	end
	if (fact_closestAmphibDist > 600) then
		sg_henchman_max = sg_henchman_max + 10
	end
	
	--Commented out 3/31/2019 by Bchamp since PopulationMax has changed in Tellurian.
	-- increase max a bit more in high pop cap games
	--if (PopulationMax()>50) then
	--	sg_henchman_max = sg_henchman_max + 20
	--end
	
	if (g_LOD == 0 and sg_henchman_max > 28) then
		sg_henchman_max = 28
	end

	-- added by LBFrank 12/30/18 increase desired hench every 6 minutes until max is reached
	--local sixMinuteStamp = 0;
	--if ((GameTime() == (sixMinuteStamp + (6*60))) and (sg_desired_henchman < sg_henchman_max)) then
	--	sg_desired_henchman = (sg_desired_henchman + 6);
	--	sixMinuteStamp = GameTime();
	--end
		
	goal_dohenchmanexpand = 1
	
	icd_maxgatherers = 90
	icd_maxgathersites = 25
	
	-- standard and difficult
	icd_henchman_per_scrapyard_near = 2.0; --2.0, 2.3, 2.6
	icd_henchman_per_scrapyard_med = 2.3;
	icd_henchman_per_scrapyard_far = 2.6;
		
	if (g_LOD == 0) then
		icd_henchman_per_scrapyard_near = 1.2;
		icd_henchman_per_scrapyard_med = 1.5;
		icd_henchman_per_scrapyard_far = 1.7;
	end
	
	icd_gatherDist_near = 35; --35 ....these are the numbers that worked on Highland Economy Rush
	icd_gatherDist_med = 45; --45
	icd_gatherDist_far = 50; --50
	icd_maxfoundrydist = 50; --50 or 40
			
	-- cache data every X seconds
	timer_henchmandata = -1
	Cache_henchmandata()
		
	-- choose which high level logic/rules to use
	Logic_buildhenchman = Logic_desiredhenchman
	
	if (g_LOD == 0) then
		RegisterTimerFunc("dohenchman", 10 )
	elseif (g_LOD == 1) then
		RegisterTimerFunc("dohenchman", 3.5 )
	else
		RegisterTimerFunc("dohenchman", 2.0 ) --Added by Bchamp 4/7/2019 to reduce AI build henchman delay when only 1 hench is allowed to be queued at a time.
	end
	
end

function Cache_henchmandata()
	
	local gtime = GameTime();
	
	if (timer_henchmandata > gtime) then
		return
	end
	
	-- call this in another 20 seconds
	timer_henchmandata = gtime + 15
	
	-- checks to see how far the first scrap yard is, to determine what to initially do
		
	-- how many scrap yards are within 50m of the lab
	sg_numscrapyardsWithinDist_near = CoalPileWithinDist( icd_gatherDist_near );
	sg_numscrapyardsWithinDist_med = CoalPileWithinDist( icd_gatherDist_med )-sg_numscrapyardsWithinDist_near;
	sg_numscrapyardsWithinDist_far = CoalPileWithinDist( icd_maxfoundrydist )-(sg_numscrapyardsWithinDist_med+sg_numscrapyardsWithinDist_near);
	--sg_numscrapyardsWithinDist_total = sg_numscrapyardsWithinDist_near+sg_numscrapyardsWithinDist_med+sg_numscrapyardsWithinDist_far

	-- based on these distances how many henchman max can we handle
	local startinghenchman = sg_numscrapyardsWithinDist_near*icd_henchman_per_scrapyard_near;
	startinghenchman = startinghenchman + sg_numscrapyardsWithinDist_med*icd_henchman_per_scrapyard_med;
	startinghenchman = startinghenchman + sg_numscrapyardsWithinDist_far*icd_henchman_per_scrapyard_far;
	
	sg_henchmanthreshold = startinghenchman
	
	aitrace("Script: Henchman threshold:"..sg_henchmanthreshold)
end

sg_randHenchmanVal = Rand(100)

-- modifies and controls the variable sg_desired_henchman
function Logic_desiredhenchman()
	
	-- if our base is being bombarded try to do whatever we have to fight back
	if (LabUnderAttackValue() > 1500) then
		sg_desired_henchman = 2
		return
	end
	
	-- if our base is under attack and we have 5 henchmen, don't request for more
	-- we want to save money for towers and chambers and creatures
	if (LabUnderAttackValue() > 50 and NumHenchmanQ() >= 6 ) then
		sg_desired_henchman = 0
		return
	end


	Cache_henchmandata()
	
	-- dependant on level of diff, map size, if we are underattack, coal rate, current coal amount
	-- how many we currently have, if we are trying to expand,
	-- this may rely on higher level variables or cached data to determine its outcome
	
	-- must take population caps into consideration at sometime (or does this matter?)
	
	-- INSERT LOGIC TO DETERMINE THE DESIRED NUMBER OF HENCHMAN
	local mapsizeoffset = 0
	if (fact_closestAmphibDist>400) then
		mapsizeoffset = 1
	end
	if (fact_closestAmphibDist>650) then
		mapsizeoffset = 2
	end
	if (fact_closestAmphibDist>800) then
		mapsizeoffset = 3
	end

	local henchman_count = 12
	local curRank = GetRank()
	local gatherSiteOpen = IsGatherSiteOpen()
	local numFoundries = NumBuildingActive( Foundry_EC )
	
	-----------------------------------------------------------------------------------
	--Added by Bchamp 4/12/2019 after observation of AI building a ton of hench because it had unsafe foundries
	-----that it wasn't mining at. 
	--Don't build henchmen if you are mining coal inefficiently (less than expected gather rate)
	--This may backfire for when you start running out of coal piles on map and henchmen overcrowd coal? Unsure.
	if (curRank >= 3 and NumHenchmanActive() >= 10 and numFoundries > 0 and gatherSiteOpen > 0) then
		local expectedGatherRate = 1.3 --Note that 10 henchmen mining 5 coal piles on Vacation is > 13 ScrapPerSec()
		if (ResearchCompleted(RESEARCH_HenchmanYoke) == 1) then
			expectedGatherRate = 2.0
		end
		if (ResearchCompleted(RESEARCH_HenchmanMotivationalSpeech) == 1) then
			expectedGatherRate = expectedGatherRate*1.4
		end
		if ((ScrapPerSec() / (NumHenchmanActive() - 4)) < expectedGatherRate) then --Have 4 henchmen wiggle room for building stuff
			return
		end
	end
	----------------------------------------------------------------------------------

	----------------------------------------------------------------------------------
	-- Level 1 Build here ------------------------------------------------------------
	if (curRank < 2 and g_LOD >= 1) then
		if (g_LOD >= 2 and numFoundries == 0) then --constant supply of henchmen before foundry, must make sure foundry is built or go L2
			henchman_count = NumHenchmanActive() + 1;
		elseif (ScrapAmountWithEscrow() > 200 and ElectricityAmountWithEscrow() < 275) then
			--if still waiting on enough elec for L2 and we have plenty of coal, keep building hench
			henchman_count = NumHenchmanQ() + 2;
		elseif (gatherSiteOpen > 0) then
			henchman_count = sg_henchmanthreshold + 2 + rand3a --maximum number of henchmen AI will build to try and fill local coal piles.
		elseif (NumHenchmenGuarding() < (1+ rand3b) and NumHenchmanQ() < (sg_henchmanthreshold + 1 + mapsizeoffset)) then
			henchman_count = sg_henchmanthreshold + 1 + mapsizeoffset --Will make a maximum of this many henchmen unless too many henchmen are on Guard Mode (idle)
		else
			henchman_count = NumHenchmanQ() --Don't make henchmen if gather sites are full and too many henchman guarding.
		end
	end

	--ADDED BY BCHAMP 3/30/2019--
	--Makes it so that the desired henchmen is higher if there are gather sites open. Balances unit building with henchmen. 
	--This helps fill in expansions on maps with a ton of coal when henchman_min, defined later, doesn't make enough.
	local unitModifier = NumCreaturesQ() --variable helps to balance units with henchmen
	local unitMultiplier = ( rand40a + 60)/100 --helps add randomness to make AI more aggressive and prioritize units, Bchamp 3/31/2019

	--added by Bchamp 4/22/2019 in order to account for island maps
	if ( fact_closestGroundDist == 0 and curRank < fact_lowrank_amphib and curRank < fact_lowrank_flyer and unitModifier == 0) then
		unitModifier = 10
	end
	-- Don't count to many units
	if (unitModifier > 16) then
		unitModifier = 16
	end
	if (curRank >= 2) then
		if (curRank == 2 and gatherSiteOpen > 0) then
			henchman_count = (9*numFoundries + (unitModifier * 1.5 * unitMultiplier))
		elseif (curRank == 3) then
			if (gatherSiteOpen > 0 and numFoundries <= 1) then
				henchman_count = (9*numFoundries + (unitModifier * 1.5 * unitMultiplier))
			-- if L3 and foundries are stocked with hench and yoke hasn't been researched, set desired hench to zero, which will later reset to henchman minimum
			-- this will focus priority on getting henchman yoke. -------
			elseif (ResearchQ( RESEARCH_AdvancedStructure ) == 0 and numFoundries > 1 and g_LOD >= 2 and NumHenchmanActive() >= 20 + rand4b) then
				henchman_count = 0;
			else
				henchman_count = sg_henchmanthreshold + numFoundries*8 + (unitModifier * 1.5 * unitMultiplier);
			end
		elseif (curRank >= 4 and gatherSiteOpen > 0) then
			henchman_count = (9*numFoundries + (unitModifier * 2 * unitMultiplier))
		else --if there are no gather sites open and past L2
			if (unitModifier > 10) then
				unitModifier = 10
			end
			henchman_count = CoalPileWithDropOffs()*8 + unitModifier/2;
		end
	end

			

	
	--Taking out map size offset 
	--henchman_count = henchman_count + mapsizeoffset
	
	-- rules to expand --

	local militaryValueThreshold = 400 + sg_randHenchmanVal*8 + curRank*300
	local doexpand = 0
	
	if (curRank >= 1 and goal_dohenchmanexpand == 1 and
		fact_selfValue > militaryValueThreshold) then
		doexpand = 1
	end
	
	if (g_LOD == 1 and ScrapAmountWithEscrow() > 3500) then
		doexpand = 0
	end

	if (doexpand==1 and NumHenchmenGuarding() < (1+ rand3c)) then
		-- build more henchman for next gathersite if we don't have idle hench
		henchman_count = henchman_count+((2+mapsizeoffset)*(curRank-1))
	end
	
	if (g_LOD > 0 and fact_closestAmphibDist > 400 and sg_randHenchmanVal > 70) then
		henchman_count = henchman_count+1
		if (sg_randHenchmanVal > 80) then
			henchman_count = henchman_count+2
		end
	end
	
	-- never request for more then we can support
	-- if (henchman_count > (sg_henchmanthreshold+1)) then
	-- 	henchman_count = sg_henchmanthreshold + 1 + mapsizeoffset --mapsizeoffset added by Bchamp 4/12/2019
	-- end

	--adjust henchman minimum after reaching rank 2 to ensure creatures get built promptly 1/4/2019 bchamp
	if (NumBuildingQ( Foundry_EC ) == 0 and curRank == 2) then
		local unitCount = NumCreaturesQ()
		sg_henchman_min = (13 + unitCount)
	elseif (curRank >= 2) then
		sg_henchman_min = (7*numFoundries + 9) 
	end

	-- maintain a minimum amount of henchman
	if (henchman_count < sg_henchman_min) then
		henchman_count = sg_henchman_min;
	end

	if (henchman_count > sg_henchman_max) then
		henchman_count = sg_henchman_max;
	end

	--Adjust for easy difficulty
	if (g_LOD == 0) then
		henchman_count = henchman_count*0.65
	end
	--Adjust for normal difficulty
	if (g_LOD == 1) then
		henchman_count = henchman_count*0.85 --changed from 0.9 by Bchamp 9/15/2019
	end

	sg_desired_henchman = henchman_count
		
end

function Command_buildhenchman()

	--Don't build too many hench
	if (NumHenchmenGuarding() > 6 + rand2a) then
		return
	end

	--added by Bchamp 10/1/2018 to prevent overqueuing of henchman at lab
	if ((NumHenchmanQ() - NumHenchmanActive()) >= (4 - g_LOD)) then
		return
	end
	

	-- issue command for more henchman if we can afford one
	if (NumHenchmanQ() < sg_desired_henchman and CanBuild( Henchman_EC )==1 ) then
		aitrace("Script: build henchman "..(NumHenchmanQ()+1).." of "..sg_desired_henchman);
		xBuild( Henchman_EC, 0 );
	end

end

function dohenchman()

	Logic_desiredhenchman()
	Command_buildhenchman()

end




