
aitrace("Script Component: Rank1Rush Tactic")

function Rank1Rush_CanDoTactic(ForceTactic)

	-- don't do this if quickstart
	if (ScrapAmountWithEscrow() > 1000) then
		return 0
	end
	
	local goal_rank1rush = 0

	-- find closest
	local closestenemy = ClosestEnemy(0)
	local closestDist = 100000
	-- non amphib dist
	if (closestenemy > -1) then
		closestDist = Player_Dist(closestenemy, 0)
	end

	aitrace("Rank1Rush: Testing Closest("..closestenemy..") Dist("..closestDist..")")

	local numEnemies = PlayersAlive( player_enemy )
	local numAllies = PlayersAlive( player_ally )
	
	-- don't do this when the number of enemies out numbers the allies
	if (numEnemies > numAllies) then
		return 0
	end
	
	local randtemp = Rand(10)
	aitrace("Rank1Rush: Rand:"..randtemp)
	-- test for rank1 tactic
	if (GetRank() == 1 and ((closestDist < 350 and randtemp < 4) or ForceTactic == 5)) then
		-- have the units for a rank1 rush
		local units = Army_ClassSize( Player_Self(), sg_class_groundrank1rush )
		if (units > 0) then
			goal_rank1rush = 1
		end
	end
	
	-- should check to see there is only one enemy?
	-- should check to see if he is reachable?
	-- should check island size?
	
	if (goal_rank1rush==1) then
	
		-- select this enemy to attack
		icd_chooseEnemyOverride = closestenemy
			
		save_dolightningrods = dolightningrods
		rawset(globals(), "dolightningrods", nil )
		dolightningrods = Rank1Rush_dolightningrods
		
		save_docreaturechamber = docreaturechamber
		rawset(globals(), "docreaturechamber", nil )
		docreaturechamber = Rank1Rush_docreaturechamber
		
		save_dosoundbeamtowers = dosoundbeamtowers
		rawset(globals(), "dosoundbeamtowers", nil )
		dosoundbeamtowers = Rank1Rush_dosoundbeamtowers
		
		save_Logic_military_setdesiredcreatures = Logic_military_setdesiredcreatures
		rawset(globals(), "Logic_military_setdesiredcreatures", nil )
		Logic_military_setdesiredcreatures = Rank1Rush_Logic_military_setdesiredcreatures
		
		
		--save_Logic_buildhenchman = Logic_buildhenchman
		--rawset(globals(), "Logic_buildhenchman", nil )
		--Logic_buildhenchman = Rank1Rush_Logic_buildhenchman
		
		save_Logic_set_escrow = Logic_set_escrow
		rawset(globals(), "Logic_set_escrow", nil )
		Logic_set_escrow = Rank1Rush_Logic_set_escrow
	
		icd_startAtRank = 1
	
		aitrace("Rank1Rush: Running")
		
		return 1
	end
	
	return 0
	
end

function Rank1Rush_Logic_military_setdesiredcreatures()

	sg_creature_desired = 20
	
	-- check enemy ranks
	local maxrank = PlayersRank(player_enemy, player_max)
	
	if (maxrank > 1 or UnderAttackValue()>0 or GetRank()>1 or NumCreaturesQ()>10) then
		rawset(globals(), "Logic_military_setdesiredcreatures", nil )
		Logic_military_setdesiredcreatures = save_Logic_military_setdesiredcreatures
	end

end

function Rank1Rush_dosoundbeamtowers()

	-- if underattack or past rank1 return back to normal behaviour
	if (UnderAttackValue()>150 or GetRank()>1) then
	
		-- add the old code back in
		rawset(globals(), "dosoundbeamtowers", nil )
		dosoundbeamtowers = save_dosoundbeamtowers
	
	end

end

function Rank1Rush_docreaturechamber()
	
	if (NumBuildingQ( RemoteChamber_EC ) < 1 and CanBuildWithEscrow( RemoteChamber_EC)==1) then
		
		ReleaseGatherEscrow();
		ReleaseRenewEscrow();
		
		local basePlacement = PH_OutsideBase
		if(rand10a > 4) then
			basePlacement = PH_EnemyBase
		end
		
		xBuild( RemoteChamber_EC, basePlacement );
		aitrace("Script: Build first creature chamber")
	end
	
	-- return to normal logic once the chamber is up
	if (NumBuildingActive(RemoteChamber_EC) > 0) then
	
		-- add the old code back in
		rawset(globals(), "docreaturechamber", nil )
		docreaturechamber = save_docreaturechamber
		
	end

end

function Rank1Rush_dolightningrods()

	local rank1avgelec = calcAvgAttribute( Player_Self(), "costRenew", 1, 1)
	if rank1avgelec == 0 and  GameTime() < (3.5*60) then
		return
	end

	-- don't build any of these until we have a chamber
	-- and a couple creatures or until the enemy has more creatures
	-- then we do until we are under attack
	
	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );
	
	-- call old code if these conditions are met
	if ((NumBuildingActive( RemoteChamber_EC ) > 0 and NumCreaturesQ() > 0) or UnderAttackValue()>0 or GameTime() > (3.5*60)) then
		-- add the old code back in
		rawset(globals(), "dolightningrods", nil )
		dolightningrods = save_dolightningrods
	end
	
		
end

function Rank1Rush_Logic_buildhenchman()
	
	sg_desired_henchman = sg_henchmanthreshold;
	
	if (sg_desired_henchman > 7) then
		sg_desired_henchman = 7
	end
		
	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );
			
	if ((NumBuildingActive( RemoteChamber_EC ) > 0 and militaryValue > 600) or UnderAttackValue()>0 or GameTime() > (4*60)) then
		rawset(globals(), "Logic_buildhenchman", nil )
		Logic_buildhenchman = save_Logic_buildhenchman
	end
	
end

function Rank1Rush_Logic_set_escrow()

	-- piggy back this call to make sure its called
	AttackNow()
	
	SetGatherEscrowPercentage(10)
	SetRenewEscrowPercentage(10)
	
	local militaryValue = PlayersMilitaryValue( Player_Self(), player_max );
			
	if ((NumBuildingActive( RemoteChamber_EC ) > 0 and militaryValue > 600) or UnderAttackValue()>0 or GameTime() > (4*60)) then
		rawset(globals(), "Logic_set_escrow", nil )
		Logic_set_escrow = save_Logic_set_escrow
	end

end