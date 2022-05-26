-- Edits by LBFrank/Buttious and Bchamp
-- Artillery units are now always accompanied by ranged units
-- AI also now recognizes niche units such as flying artillery and 
-- units with certain abilities, and will use/counter them accordingly

function doMobilityChoice()

	-- should check spawners relationship with target

	sg_groundDist = 0
	sg_amphibDist = 0
	sg_airDist = 0
	
	-- if we are not under attack, we should be going for target
	if (LabUnderAttackValue() == 0) then
		sg_groundDist = GroundDistToTarget()
		if (sg_groundDist == 0) then
			sg_groundDist = fact_closestGroundDist
		end
		sg_amphibDist = AmphibDistToTarget()
		if (sg_amphibDist == 0) then
			sg_amphibDist = fact_closestAmphibDist
		end
		sg_airDist = AirDistToTarget()
	-- otherwise we are protecting our base
	else
		sg_groundDist = GroundDistToBase()
		sg_amphibDist = AmphibDistToBase()
		sg_airDist = AirDistToBase()
	end
		
	if (sg_amphibDist == 0) then      -- cliff map
		sg_goalflyer = sg_goalflyer+10
	elseif (sg_groundDist == 0) then  -- island map
		sg_goalamphib = sg_goalamphib+4
		sg_goalflyer = sg_goalflyer+3
	elseif (sg_amphibDist*2.5 < sg_groundDist) then
		sg_goalamphib = sg_goalamphib+1.5
	elseif (sg_amphibDist*1.5 < sg_groundDist) then
		sg_goalamphib = sg_goalamphib+0.5
	end
	
	-- if flyers are closer then amphibs 
	if (sg_airDist*2 < sg_amphibDist) then
		sg_goalflyer = sg_goalflyer+1
	end
	
end

function checkSelfArmy()
	
	-- make sure we don't have too many flyers or too many of one group
	local playerindex = Player_Self()
	
	local totalValue = PlayersMilitaryValue( playerindex, player_max )
	if (totalValue == 0) then
		return
	end
	
	local flyerValue = PlayersUnitTypeValue( playerindex, player_max, sg_class_flyer )
	local flyerPercent = flyerValue/totalValue*100
	if (flyerValue > 1000 and flyerPercent > 70) then
		-- reduce want for flyer
		sg_goalflyer = sg_goalflyer-1.5
	end

	-- edited by LBFrank 12/30/18 wants more flyers on a water map if there are more flyers than swimmers
	local swimmerValue = PlayersUnitTypeValue( playerindex, player_max, sg_class_swimmer )
	if ((sg_groundDist == 0) and (flyerValue > swimmerValue)) then
		sg_goalflyer = sg_goalflyer+4
	end
	


	local artilleryValue = PlayersUnitTypeValue( playerindex, player_max, sg_class_artillery )
	local artilleryPercent = artilleryValue/totalValue*100
	if (artilleryValue > 1500 and artilleryPercent > 70) then
		sg_goalartillery = sg_goalartillery-1.5
		-- don't match with melee
		sg_goalmelee = sg_goalmelee-1
		-- best to mix with direct range
		sg_goalrange = sg_goalrange+1
		
	end

	--Added to ensure mix of ranged units along with artillery units so that artillery units can't be out-microed by skilled players
	--Bchamp 10/1/2018
	local directRangeValue = PlayersUnitTypeValue( playerindex, player_max, sg_class_directrange )	
	if (directRangeValue == 0) then
		directRangeValue = 1
	end
	local artilleryToDirectRangeRatio = artilleryValue / directRangeValue
	if (artilleryToDirectRangeRatio > 1.5) then
		sg_goalartillery = sg_goalartillery-1.5
		-- increase desire of direct ranged
		sg_goalrange = sg_goalrange+1
	end
	
	-- Bchamp 2/20/2022 removed this since stink no longer prevents range attacks in Tel 2.9.1.6
	-- LBFrank 12/31/18 ensure mixing standard melee with stink when stink is being used
	-- local stinkValue = PlayersUnitTypeValue( playerindex, player_max, sg_class_stink )
	-- local standardValue = PlayersUnitTypeValue( playerindex, player_max, sg_class_standard )
	-- if ((stinkValue == 1) and (standardValue == 0)) then
	-- 	standardValue = 1
	-- end
	-- local standardtostinkRatio = stinkValue / standardValue
	-- if (standardtostinkRatio > 1.5) then
	-- 	sg_goalstink = sg_goalstink-1
	-- 	-- increase desire of standard melee
	-- 	sg_goalstandard = sg_goalstandard+2
	-- end

	if (1) then
		
		debug_SELFflyerValue = flyerValue
		debug_SELFflyerPercent = flyerPercent
	
		debug_SELFartilleryValue = artilleryValue 
		debug_SELFartilleryPercent = artilleryPercent
	end
end

function doRPSchoice_easy(chosenEnemy)

	-- get total number of military units
	local totalValue = PlayersMilitaryValue( chosenEnemy, player_max )
	
	if (totalValue == 0) then
		return 0
	end

	local numAATowers = PlayersUnitCount( chosenEnemy, player_max, AntiAirTower_EC )
	-- for every tower the enemy builds the lower the need for flyers should be
	if (numAATowers > 0) then
		sg_goalflyer = sg_goalflyer - numAATowers*0.25
	end
	
	-- 1. tally up enemy units first (all or the one that has attacked last)

	
	local artilleryValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_artillery )
	local artilleryPercent = artilleryValue/totalValue*100
	
	if (artilleryPercent >= 70) then
		sg_goalmelee = sg_goalmelee-2
		sg_goalartillery = sg_goalartillery-1.5
		sg_goalflyer = sg_goalflyer-1
		sg_goalrange = sg_goalrange+1.5
	elseif (artilleryPercent >= 35) then
		sg_goalmelee = sg_goalmelee-1
		sg_goalartillery = sg_goalartillery-1
		--sg_goalflyer = sg_goalflyer+0
		sg_goalrange = sg_goalrange+1
	end
	
	local directRangeValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_directrange )
	local directRangePercent = directRangeValue/totalValue*100
	
	if (directRangePercent >= 70) then
		sg_goalmelee = sg_goalmelee+1
		sg_goalartillery = sg_goalartillery-1.5
		sg_goalflyer = sg_goalflyer+1.5
		sg_goalrange = sg_goalrange-1
	elseif (directRangePercent >= 35) then
		sg_goalartillery = sg_goalartillery-1
		sg_goalflyer = sg_goalflyer+1
		sg_goalrange = sg_goalrange-1
	end
	
	local groundMeleeValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_groundmelee )
	local groundMeleePercent = groundMeleeValue/totalValue*100
	
	if (groundMeleePercent >= 70) then
		--sg_goalmelee = sg_goalmelee
		sg_goalartillery = sg_goalartillery+1
		sg_goalflyer = sg_goalflyer-1.5
		sg_goalrange = sg_goalrange-1
	elseif (groundMeleePercent >= 35) then
		--sg_goalmelee = sg_goalmelee-1
		sg_goalflyer = sg_goalflyer-0.5
		sg_goalrange = sg_goalrange-0.5
	end
	
	local flyerValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_flyer )
	local flyerPercent = flyerValue/totalValue*100
	
	if (flyerPercent >= 70) then
		--sg_goalmelee = sg_goalmelee-1
		--sg_goalartillery = sg_goalartillery+1
		sg_goalflyer = sg_goalflyer+1
		sg_goalrange = sg_goalrange-1.5
	elseif (flyerPercent >= 35) then
		--sg_goalmelee = sg_goalmelee-1
		--sg_goalartillery = sg_goalartillery+0
		sg_goalflyer = sg_goalflyer+1
		sg_goalrange = sg_goalrange-1
	end
		
	sg_goalmelee = sg_goalmelee*2
	sg_goalartillery = sg_goalartillery*2
	sg_goalflyer = sg_goalflyer*2
	sg_goalrange = sg_goalrange*2
	
	-- debug code
	if (1) then
		debug_totalValue = totalValue
	
		debug_artilleryValue = artilleryValue
		debug_artilleryPercent = artilleryPercent
	
		debug_directRangeValue = directRangeValue 
		debug_directRangePercent = directRangePercent
		
		debug_groundMeleeValue = groundMeleeValue
		debug_groundMeleePercent = groundMeleePercent
		
		debug_flyerValue = flyerValue
		debug_flyerPercent = flyerPercent
	end

	return 1
end


function doRPSchoice(chosenEnemy)

	-- get total number of military units
	local totalValue = PlayersMilitaryValue( chosenEnemy, player_max )
	
	if (totalValue == 0) then
		return 0
	end
	
	local numAATowers = PlayersUnitCount( chosenEnemy, player_max, AntiAirTower_EC )
	-- for every tower the enemy builds the lower the need for flyers should be
	if (numAATowers > 0) then
		sg_goalflyer = sg_goalflyer - numAATowers*0.25
	end
	
	-- if on standard use creature choice when we are losing or when
	-- player has more then 500 val of units (also lab must not be under attack)
	if (g_LOD == 1 and LabUnderAttackValue() == 0 and (totalValue < 500 or fact_selfValue > totalValue*1.1)) then
		return 0
	end

	-- 1. tally up enemy units first (all or the one that has attacked last)
	
	local artilleryValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_artillery )
	local artilleryPercent = artilleryValue/totalValue*100
	
	if (artilleryPercent >= 70) then
		sg_goalmelee = sg_goalmelee+3
		sg_goalartillery = sg_goalartillery+2
		sg_goalflyingArtillery = sg_goalflyingArtillery+3
		sg_goalflyer = sg_goalflyer+3
		sg_goalrange = sg_goalrange-2
	elseif (artilleryPercent >= 35) then
		sg_goalmelee = sg_goalmelee+2
		sg_goalartillery = sg_goalartillery+1
		sg_goalflyer = sg_goalflyer+1
	end
	
	local directRangeValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_directrange )
	local directRangePercent = directRangeValue/totalValue*100
	
	if (directRangePercent >= 70) then
		sg_goalmelee = sg_goalmelee-1
		sg_goalartillery = sg_goalartillery+3
		sg_goalflyingArtillery = sg_goalflyingArtillery+4
		sg_goalflyer = sg_goalflyer-2
		sg_goalrange = sg_goalrange+2 
	elseif (directRangePercent >= 35) then
		sg_goalartillery = sg_goalartillery+2
		sg_goalflyingArtillery = sg_goalflyingArtillery+1
		sg_goalflyer = sg_goalflyer-1
		sg_goalrange = sg_goalrange+2
	end
	
	local groundMeleeValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_groundmelee )
	local groundMeleePercent = groundMeleeValue/totalValue*100
	
	if (groundMeleePercent >= 70) then
		sg_goalmelee = sg_goalmelee+1
		sg_goalartillery = sg_goalartillery-2
		sg_goalflyingArtillery = sg_goalflyingArtillery+2
		sg_goalflyer = sg_goalflyer+3
		sg_goalrange = sg_goalrange+2
	elseif (groundMeleePercent >= 35) then
		sg_goalmelee = sg_goalmelee+1
		sg_goalflyer = sg_goalflyer+2
		sg_goalrange = sg_goalrange+1
	end
	
	local flyerValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_flyer )
	local flyerPercent = flyerValue/totalValue*100

	if (flyerPercent >= 70) then
		sg_goalmelee = sg_goalmelee-3
		--sg_goalartillery = sg_goalartillery-0
		sg_goalflyingArtillery = sg_goalflyingArtillery-1
		sg_goalflyer = sg_goalflyer+2
		sg_goalrange = sg_goalrange+3
	elseif (flyerPercent >= 35) then
		sg_goalmelee = sg_goalmelee-1
		--sg_goalartillery = sg_goalartillery+0
		sg_goalflyer = sg_goalflyer+1
		sg_goalrange = sg_goalrange+2
	end
	
	local highDValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_highdefence )
	local highDPercent = highDValue/totalValue*100
	
	-- if enemy has lots of high defence guys, build antidefence units
	if (highDPercent >= 70) then
		-- increase by 1.5, which is less then the guy one rank ahead
		sg_goalantidefence = sg_goalantidefence + 1.5
	elseif (highDPercent >= 35) then
		sg_goalantidefence = sg_goalantidefence + 0.75
	end

	-- Commented out by Bchamp 2/20/2022 for Tel 2.9.1.6 when Stink no longer stops range attacks
	-- added by LBFrank 10/15/18 so when enemy has stink, AI prioritizes melee and flyers
	-- local highStValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_stink )
	-- local highStPercent = highStValue/totalValue*100
	
	-- -- if enemy has alot of stink, build alot of melee and flyers (avoiding range and art a little)
	-- if (highStPercent >= 60) then
	-- 	sg_goalmelee = sg_goalmelee+3
	-- 	sg_goalflyer = sg_goalflyer+3
	-- 	sg_goalrange = sg_goalrange-1
	-- 	sg_goalartillery = sg_goalartillery-1
	-- 	sg_goalflyingArtillery = sg_goalflyingArtillery-1
	-- elseif (highStPercent >= 25) then
	-- 	sg_goalmelee = sg_goalmelee+1
	-- 	sg_goalflyer = sg_goalflyer+1
	-- end
	
	-- added by LBFrank 01/01/19 so when enemy has deflect, AI also prioritizes melee and flyers
	local highdeflectValue = PlayersUnitTypeValue( chosenEnemy, player_max, sg_class_deflect )
	local highdeflectPercent = highdeflectValue/totalValue*100
	
	-- if enemy has alot of deflect, build alot of melee and flyers (avoiding range a little)
	if (highdeflectPercent >= 60) then
		sg_goalmelee = sg_goalmelee+3
		sg_goalflyer = sg_goalflyer+3
		sg_goalrange = sg_goalrange-1
	elseif (highdeflectPercent >= 25) then
		sg_goalmelee = sg_goalmelee+1
		sg_goalflyer = sg_goalflyer+1
	end

	-- debug code
	if (1) then
		debug_totalValue = totalValue
	
		debug_artilleryValue = artilleryValue
		debug_artilleryPercent = artilleryPercent
	
		debug_directRangeValue = directRangeValue 
		debug_directRangePercent = directRangePercent
		
		debug_groundMeleeValue = groundMeleeValue
		debug_groundMeleePercent = groundMeleePercent
		
		debug_flyerValue = flyerValue
		debug_flyerPercent = flyerPercent
		
		debug_highDValue = highDValue
		debug_highDPercent = highDPercent
	end

	return 1
end

function Logic_OverrideCreatureChoice()
	
	-- count number flyers AI has
	--local numFlyers = PlayersUnitTypeCount( Player_Self(), player_max, sg_goalrange )
	
	--sg_goalamphib = 0
	--sg_goalmelee = 0
	--sg_goalartillery = 0
	--sg_goalflyer = 0
	--sg_goalrange = 0
	--sg_goalantidefence = 0

end

function docreaturechoice()

	-- there is no creature counters for easy
	
	sg_goalamphib = 0
	sg_goalmelee = 0
	sg_goalartillery = 0
	sg_goalflyer = 0
	sg_goalrange = 0
	sg_goalantidefence = 0
	sg_goalpureswimmer = 0
	sg_goalflyingArtillery = 0
	sg_goalstandard = 0
	-- LBFrank 04/19/19 we dont want loners. at all.
	sg_goalloner = -100
		
	-- check to see if we have a particular unit type and see if it should
	-- be built
	sg_goalstink = 0
	--sg_goalhorns = 0
	local chosenEnemy
	
	if (GetAttackerCount() > 0) then
		chosenEnemy = GetAttackerID( 0 )
	else 
		chosenEnemy = GetChosenEnemy()
	end
		
	if (chosenEnemy ~= -1) then
		
		-- if no processing then don't do anything 
		if (g_LOD == 0) then
			doRPSchoice_easy(chosenEnemy)
		else
			doRPSchoice(chosenEnemy)
		end
		
	end
	if (g_LOD ~= 0) then
		checkSelfArmy()
	end
	if (UnderNavalAttack()==1) then
		sg_goalamphib = sg_goalamphib+2.5
		sg_goalflyer = sg_goalflyer+2.5
		sg_goalpureswimmer = sg_goalpureswimmer+2.5
	end

	--if enemy is massing ground units, make ground units to defend, not pure swimmers
	if Enemy.GroundUnitValue > PlayersUnitTypeValue( Player_Self(), player_max, sg_class_ground ) then
		sg_goalpureswimmer = sg_goalpureswimmer - 20
		--Scuttle(ResourceRenew_EC)
	end

	local curRank = GetRank()
	
	-- stay away from melee guys when there are blockades present in world
	-- edited by LBFrank 12/28/18 adding goalflyer and goalartillery strings here. AI should build more artillery and flyers in response to 'blockades'
	if (NumBlockades() > 0 and LabUnderAttackValue()==0) then
		
		sg_goalmelee = sg_goalmelee-1
		sg_goalartillery = sg_goalartillery+1
		if (curRank < 3) then
			sg_goalmelee = sg_goalmelee-2
			sg_goalrange = sg_goalrange+1
			sg_goalartillery = sg_goalartillery+2
			sg_goalflyer = sg_goalflyer+2
		end
		
		-- this means artillery or flyers should be chosen
		
		-- if we have no flyers or artillery - we should turtle and rank up instead
	end
		
	-- check the map to see which creatures should have some benefits
	doMobilityChoice()
	
	-- override creature choice
	Logic_OverrideCreatureChoice()
				
	
	local playerindex = Player_Self()
	local armysize = Army_GetSize(playerindex)
	
	local i = 0
	while (i<armysize) do
		
		local info = Army_GetUnit( playerindex, i )
		local newvalue = 0
		
		--local numCreature = Army_NumCreatureInArmy(playerindex, i)
		
		-- only do the following rules in easy if there are more 2 of these 
		-- creatures
		--if (g_LOD ==0 and numCreature > 2) then
		
		if (Army_IsUnitInClass( playerindex, sg_class_artillery, i )==1) then
			newvalue = newvalue + sg_goalartillery 
		end
		if (Army_IsUnitInClass( playerindex, sg_class_directrange, i )==1) then
			newvalue = newvalue + sg_goalrange
		end
		if (Army_IsUnitInClass( playerindex, sg_class_groundmelee, i )==1) then
			newvalue = newvalue + sg_goalmelee
		end
		if (Army_IsUnitInClass( playerindex, sg_class_antidefence, i )==1) then
			newvalue = newvalue + sg_goalantidefence
		end
		
		--end -- rule for easy, to control unit types
		
		if (Army_IsUnitInClass( playerindex, sg_class_flyer, i )==1) then
			newvalue = newvalue + sg_goalflyer
		end
		if (Army_IsUnitInClass( playerindex, sg_class_amphib, i )==1) then
			newvalue = newvalue + sg_goalamphib
		end
		if (Army_IsUnitInClass( playerindex, sg_class_swimmer, i )==1) then
			if (Army_IsUnitInClass( playerindex, sg_class_ground, i )==0) then
				newvalue = newvalue + sg_goalpureswimmer
			end	
		end
		if (Army_IsUnitInClass( playerindex, sg_class_flyingArtillery, i )==1) then
			newvalue = newvalue + sg_goalflyingArtillery
		end
		if (Army_IsUnitInClass( playerindex, sg_class_stink, i )==1) then
			newvalue = newvalue + sg_goalstink
		end
		if (Army_IsUnitInClass( playerindex, sg_class_loner, i )==1) then
			newvalue = newvalue + sg_goalloner
		end
		if (Logic_CustomCreatureChoiceScore) then
			newvalue = newvalue + Logic_CustomCreatureChoiceScore(playerindex, i)
		end
					
		local unitRank = ci_rank( info )
		
		local rankMod = 2
		if (g_LOD == 0) then
			rankMod = 0.5
		end
		
		-- adjust unit based on rank, attempt to alway build best ranked creature
		newvalue = newvalue - (curRank-unitRank)*rankMod
		
		-- note by bchamp on 10/1/2018
		-- SetCounterValue seems to set the desired creature count for a particular unit.
		SetCounterValue(i, newvalue )
		
		i = i + 1
	end


end

RegisterTimerFunc("docreaturechoice", 6.0 )
