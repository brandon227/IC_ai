
function init_henchman()

	aitrace("init_henchman()")
	
	-- henchman gathering variables
	
	sg_henchman_min = 5
	sg_henchman_max = 15
	sg_desired_henchman = 12
	
	if (g_LOD == 0) then
		sg_henchman_max = 9
	end
	
	-- on easy reduce the number of henchmen built
	
	if (fact_closestAmphibDist > 400) then
		sg_henchman_max = sg_henchman_max + 3
	end
	if (fact_closestAmphibDist > 600) then
		sg_henchman_max = sg_henchman_max + 5
	end
		
	-- increase max a bit more in high pop cap games
	if (PopulationMax()=100) then
		sg_henchman_max = sg_henchman_max + 15
	end
	if (PopulationMax()=250) then
		sg_henchman_max = sg_henchman_max + 35
	end
	
	if (g_LOD == 0 and sg_henchman_max > 14) then
		sg_henchman_max = 14
	end
		
	goal_dohenchmanexpand = 1
	
	icd_maxgatherers = 50
	icd_maxgathersites = 25
	
	-- standard and difficult
	icd_henchman_per_scrapyard_near = 2.0;
	icd_henchman_per_scrapyard_med = 2.3;
	icd_henchman_per_scrapyard_far = 2.6;
		
	if (g_LOD == 0) then
		icd_henchman_per_scrapyard_near = 1.2;
		icd_henchman_per_scrapyard_med = 1.5;
		icd_henchman_per_scrapyard_far = 1.7;
	end
	
	icd_gatherDist_near = 35;
	icd_gatherDist_med = 45;
	icd_gatherDist_far = 65;
	icd_maxfoundrydist = 50;
			
	-- cache data every X seconds
	timer_henchmandata = -1
	Cache_henchmandata()
		
	-- choose which high level logic/rules to use
	Logic_buildhenchman = Logic_desiredhenchman
	
	if (g_LOD == 0) then
		RegisterTimerFunc("dohenchman", 10 )
	else
		RegisterTimerFunc("dohenchman", 3.5 )
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
	if (LabUnderAttackValue() > 50 and NumHenchmanQ() >= 6) then
		sg_desired_henchman = 0
		return
	end
	
	Cache_henchmandata()
	
	-- dependant on level of diff, map size, if we are underattack, coal rate, current coal amount
	-- how many we currently have, if we are trying to expand,
	-- this may rely on higher level variables or cached data to determine its outcome
	
	-- must take population caps into consideration at sometime (or does this matter?)
	
	-- INSERT LOGIC TO DETERMINE THE DESIRED NUMBER OF HENCHMAN
		
	local henchman_count = 9
			
	local mapsizeoffset = 0
	if (fact_closestAmphibDist>400) then
		mapsizeoffset = 1
	end
	if (fact_closestAmphibDist>650) then
		mapsizeoffset = 2
	end
	if (fact_closestAmphibDist>800) then
		mapsizeoffset = 2.5
	end
	
	henchman_count = henchman_count + mapsizeoffset
	
	-- rules to expand --
	
	local curRank = GetRank()
	local militaryValueThreshold = 400 + sg_randHenchmanVal*8 + curRank*300
	local doexpand = 0
	
	if (curRank >= 2 and goal_dohenchmanexpand == 1 and
		fact_selfValue > militaryValueThreshold) then
		doexpand = 1
	end
	
	if (g_LOD == 1 and ScrapAmountWithEscrow() > 1100) then
		doexpand = 0
	end
	
	if (doexpand==1) then
		-- build more henchman for next gathersite
		henchman_count = henchman_count+((2+mapsizeoffset)*(curRank-1))
	end
	
	if (g_LOD == 0) then
		henchman_count = henchman_count*0.65
	end
	if (g_LOD == 1) then
		henchman_count = henchman_count*0.9
	end
	
	if (g_LOD > 0 and fact_closestAmphibDist > 400 and sg_randHenchmanVal > 70) then
		henchman_count = henchman_count+1
		if (sg_randHenchmanVal > 80) then
			henchman_count = henchman_count+2
		end
	end
	
	-- never request for more then we can support
	if (henchman_count > (sg_henchmanthreshold+1)) then
		henchman_count = sg_henchmanthreshold+1
	end

	-- maintain a minimum amount of henchman
	if (henchman_count < sg_henchman_min) then
		henchman_count = sg_henchman_min;
	end

	if (henchman_count > sg_henchman_max) then
		henchman_count = sg_henchman_max;
	end

	sg_desired_henchman = henchman_count
		
end

function Command_buildhenchman()

	if (NumHenchmenGuarding() > 1) then
		return
	end
	
	-- issue command for more henchman if we can afford one
	if (NumHenchmanQ() < sg_desired_henchman and CanBuild( Henchman_EC )==1 ) then
		aitrace("Script: build henchman "..(NumHenchmanQ()+1).." of "..sg_desired_henchman);
		xBuild( Henchman_EC, 0 );
	end

end

function dohenchman()

	Logic_buildhenchman()
	Command_buildhenchman()

end




