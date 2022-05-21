
aitrace("Script Component: Army Analyzer")

function minrankForClass( playerindex, classid )
	
	local classsize = Army_ClassSize( playerindex, classid );
	local i=0
	
	local minrank = 100
	
	while (i<classsize) do
		local info = Army_ClassAt( playerindex, classid, i );
		
		-- get creature rank
		local rank = ci_rank( info )
		
		-- is this rank the lowest? if yes than remember it
		if (rank < minrank) then
			minrank = rank
		end
		
		-- next creature
		i=i+1;
		
	end
	
	return minrank

end

function calcMaxRank( playerindex )
		
	local armysize = Army_GetSize(playerindex)
	local maxrank = 0
	local i = 0
	
	while (i<armysize) do
		local info = Army_GetUnit( playerindex, i );
		
		-- get creature rank
		local rank = ci_rank( info )
		
		-- is this rank the lowest? if yes than remember it
		if (rank > maxrank) then
			maxrank = rank
		end
		
		-- next creature
		i=i+1;
		
	end
	
	return maxrank
	
end

-- calculate the average amount of specific variable of all creatures between min and max rank
function calcAvgAttribute( playerindex, attribute, minrank, maxrank )
		
	local armysize = Army_GetSize(playerindex)
	if (armysize == 0) then
		return 0
	end
	
	local total = 0
	local i = 0
	local count = 0
	
	while (i<armysize) do
		local info = Army_GetUnit( playerindex, i );
		local rank = ci_rank( info )
		
		if (rank >= minrank and rank <= maxrank )then
			-- get creature rank
			total = total+ci_getattribute( info,attribute )
			count=count+1
		end
		
		-- next creature
		i=i+1;
		
	end
	
	if (count>0) then
		return total/count
	end
	return 0
end

function calcMeleePowerRating( creatureinfo )
	
	local meleedamage = ci_meleedamage( creatureinfo );
	local armour = ci_getattribute( creatureinfo, "armour" );
	local hitpoints = ci_getattribute( creatureinfo, "hitpoints" );
	
	local val = (hitpoints*meleedamage)/(1-armour)
	
	val = sqrt(val)
	
	return val

end

sg_class_ground = 0
sg_class_flyer = 1
sg_class_swimmer = 2
sg_class_artillery = 3
sg_class_directrange = 4
sg_class_groundrank1rush = 5
sg_class_groundrank2rush = 6
sg_class_groundmelee = 7
sg_class_antiair = 8
sg_class_amphib = 9
sg_class_highdefence = 10
sg_class_antidefence = 11
sg_class_camoflauge = 12
sg_class_stink = 13
sg_class_flyingArtillery = 14
sg_class_deflect = 15
sg_class_loner = 16

-- standard melee to pair with stink
sg_class_standard = 17

sg_class_sonic = 18
sg_class_last = 19


class_check_func = {}

-- this adds a new analyzing function - for use by SP game
function addAnalyzeFunc( checkFunc )
	local nextval = sg_class_last
	class_check_func[nextval+1] = checkFunc
	
	sg_class_last = sg_class_last+1
	
	-- should never ask for more than this
	if (sg_class_last > 30) then --originally 15...Bchamp 4/19/2019
		--lua_error("AI: No More Analyze Func Space Left")
	end
	
	return nextval
end

-- Ground Class
class_check_func[sg_class_ground+1] = function( creatureinfo )
	
	if (ci_getattribute( creatureinfo, "is_land" )==1) then
		return 1
	end
	return 0
	
end

-- Flyer Class
class_check_func[sg_class_flyer+1] = function( creatureinfo )
	
	if (ci_getattribute( creatureinfo, "is_flyer" )==1) then
		return 1
	end
	return 0
	
end

-- Swimmer Class
class_check_func[sg_class_swimmer+1] = function( creatureinfo )
	
	if (ci_getattribute( creatureinfo, "is_swimmer" )==1) then
		return 1
	end
	return 0
	
end

-- Artillery Class
class_check_func[sg_class_artillery+1] = function( creatureinfo )
	
	return ci_isartillery( creatureinfo )==1;
	
end

-- Direct range Class
class_check_func[sg_class_directrange+1] = function( creatureinfo )
	
	if (ci_rangedamage( creatureinfo ) > 0 and ci_isartillery( creatureinfo ) == 0) then
		return 1
	end
	
	return 0
	
end

-- Ground Rank1 rush Class (no elec)
class_check_func[sg_class_groundrank1rush+1] = function( creatureinfo )
	
	if (ci_rank( creatureinfo ) == 1 and ci_getattribute( creatureinfo, "costrenew" ) == 0 ) then
		return 1
	end
	
	return 0
	
end

-- Added by Bchamp on 9/27/2018 to attempt to create lvl 2 rush function
-- Ground Rank2 Rush Class
class_check_func[sg_class_groundrank2rush+1] = function( creatureinfo )
	if (ci_rank( creatureinfo ) == 2 and ci_getattribute( creatureinfo, "costrenew" ) < 55 ) then
		if (ci_getattribute( creatureinfo, "is_land" ) == 1) then
			return 1
		end
	end

	return 0

end


-- Ground Melee
class_check_func[sg_class_groundmelee+1] = function( creatureinfo )
	
	if (ci_getattribute( creatureinfo, "is_land" )==1 and ci_rangedamage( creatureinfo )== 0) then
		return 1
	end
	
	return 0
end

-- Anti Air Unit
class_check_func[sg_class_antiair+1] = function( creatureinfo )
	
	if (ci_getattribute( creatureinfo, "is_flyer" )==1 or class_check_func[sg_class_directrange+1]( creatureinfo )==1) then
		return 1
	end
	
	return 0
end

-- Amphib Unit
class_check_func[sg_class_amphib+1] = function( creatureinfo )
	
	if (ci_getattribute( creatureinfo, "is_swimmer" )==1 and ci_getattribute( creatureinfo, "is_land" )==1) then
		return 1
	end
	
	return 0
end

-- High defence unit
class_check_func[sg_class_highdefence+1] = function( creatureinfo )
	
	-- has armour or has okay armour and herding
	if (ci_getattribute( creatureinfo, "armour" )>0.6 or 
	   (ci_getattribute( creatureinfo, "armour" )>0.4 and ci_getattribute( creatureinfo, "herding" )==1)) then
		return 1
	end
	
	return 0
end

-- Good against high defence units
class_check_func[sg_class_antidefence+1] = function( creatureinfo )
	
	-- has pierce damage or has poison of any type
	if (ci_meleedamagetype( creatureinfo, DT_HornNegateArmour+DT_Poison)==1 or 
	    ci_rangedamagetype( creatureinfo, DT_HornNegateArmour+DT_VenomSpray+DT_Poison)==1 or 
	    ci_getattribute( creatureinfo, "poison_touch" ) == 1) then
		return 1
	end
	
	return 0
end

-- Camo unit
class_check_func[sg_class_camoflauge+1] = function( creatureinfo )
	
	-- is a stealthy unit = camo
	if (ci_getattribute( creatureinfo, "is_stealthy" ) == 1) then
		return 1
	end
	
	-- include digging units as camo for use in SB tower code
	if (ci_getattribute( creatureinfo, "can_dig" ) == 1) then
		return 1
	end
	
	return 0
end

-- added by LBFrank 10/15/18 so AI knows what units have stink and (12/31/18) which do not
-- Stink unit
class_check_func[sg_class_stink+1] = function( creatureinfo )
	
	-- big stinko
	if (ci_getattribute( creatureinfo, "stink_attack" ) == 1) then
		return 1
	end
	
	return 0
end

--standard melee w/o Stink
class_check_func[sg_class_standard+1] = function( creatureinfo )
	-- no stinko
	if ((ci_rangedamage( creatureinfo )== 0) and (ci_getattribute( creatureinfo, "stink_attack" ) == 0)) then
		return 1
	end
	
	return 0
end

-- added by LBFrank 12/30/18 so AI knows it has flying artillery
class_check_func[sg_class_flyingArtillery+1] = function( creatureinfo )
	
	if ((ci_isartillery( creatureinfo ) == 1) and (ci_getattribute( creatureinfo, "is_flyer" ) == 1)) then
		return 1
	end
	
	return 0
end


-- LBFrank 01/01/19 so AI knows what units have deflection
class_check_func[sg_class_deflect+1] = function( creatureinfo )
	

	if (ci_getattribute( creatureinfo, "deflection_armour" ) == 1) then
		return 1
	end
	
	return 0
end

-- LBFrank 01/03/19 so AI knows what units are loners
class_check_func[sg_class_loner+1] = function( creatureinfo )
	

	if (ci_getattribute( creatureinfo, "loner" ) == 1) then
		return 1
	end
	
	return 0
end
-----------------------------------------
-- LBFrank 03/31/19 Sonic Units
class_check_func[sg_class_sonic+1] = function( creatureinfo )
	

	if (ci_rangedamagetype( creatureinfo, DT_Sonic)==1) then
		return 1
	end
	
	return 0
end
-----------------------------------------

function oncreatureanalyze( playerindex, info )
	
	aitrace("oncreatureanalyze()")
	
	local rank = ci_rank( info )
	aitrace("Script: Rank = "..rank)
		
	for i=1, getn(class_check_func) do
		if (class_check_func[i]) then
		
			local res = class_check_func[i](info)
			if (res==1) then
				Army_AddToClass(playerindex, i-1, info)
				aitrace("Script: AddToClass("..(i-1)..")")
			end
			
		end
	end
		
end

function calcAIArmyStats( aiplayer )
	
	-- create global vars for the low ranks of each class
	fact_lowrank_ground = minrankForClass( aiplayer, sg_class_ground )
	fact_lowrank_flyer = minrankForClass( aiplayer, sg_class_flyer )
	fact_lowrank_swimmer = minrankForClass( aiplayer, sg_class_swimmer )
	fact_lowrank_amphib = minrankForClass( aiplayer, sg_class_amphib )
	-- calculate lowest rank creature
	fact_lowrank_all = min(fact_lowrank_ground, fact_lowrank_amphib, fact_lowrank_flyer, fact_lowrank_swimmer)

	-- if (fact_lowrank_swimmer >= 2 and fact_lowrank_swimmer < fact_lowrank_all) then
	-- 	fact_lowrank_all = fact_lowrank_swimmer
	-- end
	-- if (fact_lowrank_flyer >= 3 and fact_lowrank_flyer < fact_lowrank_all) then
	-- 	fact_lowrank_all = fact_lowrank_flyer
	-- end
		
	aitrace("Script: LowRank_Ground = "..fact_lowrank_ground)
	aitrace("Script: LowRank_Flyer = "..fact_lowrank_flyer)
	aitrace("Script: LowRank_Swimmer = "..fact_lowrank_swimmer)
	aitrace("Script: LowRank_Amphib = "..fact_lowrank_amphib)
		
	fact_army_maxrank = calcMaxRank( aiplayer )
	
	aitrace("Script: Army Max Rank = "..fact_army_maxrank)
	
end

function RegisterArmyClassOverride()

end

function onarmyanalyze()

	aitrace("onarmyanalyze()")

	RegisterArmyClassOverride()

-- name all the classes for onscreen debugging

	Army_AddClassName( sg_class_ground, "Ground")
	Army_AddClassName( sg_class_flyer, "Flyer")
	Army_AddClassName( sg_class_swimmer, "Swimmer")
	Army_AddClassName( sg_class_artillery, "Artillery")
	Army_AddClassName( sg_class_directrange, "DirectRange")
	Army_AddClassName( sg_class_groundrank1rush, "GroundRank1Rush")
	Army_AddClassName( sg_class_groundrank2rush, "GroundRank2Rush")
	Army_AddClassName( sg_class_groundmelee, "GroundMelee")
	Army_AddClassName( sg_class_antiair, "AntiAirUnit")
	Army_AddClassName( sg_class_amphib, "AmphibCreature")
	Army_AddClassName( sg_class_highdefence, "HighDefence")
	Army_AddClassName( sg_class_antidefence, "AntiDefence")
	Army_AddClassName( sg_class_camoflauge, "Camo")
	Army_AddClassName( sg_class_stink, "Stink")
	Army_AddClassName( sg_class_standard, "StandardMelee")
	Army_AddClassName( sg_class_flyingArtillery, "FlyingArtillery")
	Army_AddClassName( sg_class_deflect, "Deflect")
	Army_AddClassName( sg_class_loner, "loner")
	Army_AddClassName( sg_class_sonic, "Sonic")

	aitrace("Script: "..getn(class_check_func).." registered classes");

	local numplayers = PlayersTotal()
	aitrace("Script: NumPlayers = "..numplayers);
	
	local playerid=0
	while (playerid < numplayers) do
		aitrace("Script: -- Player "..playerid.." --")
		
		local armysize = Army_GetSize(playerid)
				
		aitrace("Script: ArmySize = "..armysize)
		
		local armypowerrating = 0
		
		local i=0;
		while (i<armysize) do
			
			aitrace("Script: --Unit"..i.."--")
			
			-- get creature to analyze
			local creatureinfo = Army_GetUnit( playerid, i )
			
			-- get power rating for creature (only do once)
			local powerrating = calcMeleePowerRating( creatureinfo )
			aitrace("Script: PowerRating = "..powerrating)
			-- sum up teams powerrating
			armypowerrating = armypowerrating+powerrating
			
			-- analyze creature with class checks
			oncreatureanalyze( playerid, creatureinfo )
			
			-- next unit
			i=i+1
		end	
	
		-- if this is 'this' AI then calculate some info about his army
		if (playerid == Player_Self()) then
			calcAIArmyStats( playerid )
		end
		
		playerid = playerid+1
	end
		
end

-- this is called when a creature is changed in the single player game
function oncreaturechange( playerindex, creatureindex )
	aitrace("Script: --Player"..playerindex.." Change Unit"..creatureindex.."--")
	-- get creature in question
	local creatureinfo = Army_GetUnit( playerindex, creatureindex )
	-- simply just analyze the creature that has been added
	oncreatureanalyze( playerindex, creatureinfo )
	-- if there are some globals that are a summation of this entire army
	-- that has changed than recalc those too
	if (playerindex == Player_Self()) then
		calcAIArmyStats( playerindex )
	end
end



