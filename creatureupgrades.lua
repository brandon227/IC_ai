
aitrace("Script Component: CreatureUpgrade Functions")

function init_creatureupgrades()
	
	aitrace("init_creatureupgrades()")
	
	-- for now
	sg_docreature_upgrades = 1
	
end

function docreatureupgrades()

	
	-- early exit if upgrades are turned off or there is no amplifier
	if (sg_docreature_upgrades == 0 or NumBuildingActive( GeneticAmplifier_EC )==0) then
		return
	end
	
	-- pick a random time to do the next upgrade then keep trying for until
	-- we get one and do this again - the more money/rate the less time
	
	-- pick a creature or creature class based on some 
	-- heuristic
	
	-- pick and upgrade to do or cycle through them
	
	Logic_creatureupgrade()
	Command_creatureupgrade()

end

RegisterTimerFunc("docreatureupgrades", 5.0 ) --changed from 15 to 5 by Bchamp 4/1/2019 with hopes of multiple genamps being used

function Logic_creatureupgrade()
	
	sg_creatureupgradeEbpNetId = 0;
	sg_creatureupgradeType = -1;
	
	local curRank = GetRank()
	
	local AIplayerindex = Player_Self()
	local armysize = Army_GetSize(AIplayerindex)
	
	local carmour = 0
	
	-- go through each creature in the army
	for armyindex=0, (armysize-1) do
		-- get the number of these creatures in the world
		local ccount = Army_NumCreatureInArmy( AIplayerindex, armyindex )
		-- should be a few of them before upgrading them
		if (ccount >= (12-(3*g_LOD))) then --lowered to 6 by Bchamp 4/5/2019 --9/15/2019 adjusted for LOD by Bchamp
			local cinfo = Army_GetUnit( AIplayerindex, armyindex );
			local crank = ci_rank( cinfo );
			local temparmour = ci_getattribute( cinfo, "armour" )
			-- is this creature of a good rank
			if (crank >= (curRank-1)) then
				local ebpnetid = ci_ebpnetid(cinfo);
				local upgradeCount = CreatureUpgradeNumResearched( ebpnetid )
				if (upgradeCount < (g_LOD*4)) then --Added by Bchamp 4/5/2019 to account of LOD
					-- save the creature we will upgrade
					sg_creatureupgradeEbpNetId = ebpnetid;
					-- save the armour for late use
					carmour = temparmour
					aitrace("CreatureUpgrade: netid:"..ebpnetid.." armour:"..carmour.." rank:"..crank)
				end
			end
		end
	end
	
	if (sg_creatureupgradeEbpNetId ~= 0) then
		pickupgrade( sg_creatureupgradeEbpNetId, carmour )
	end
		
end

function pickupgrade( creature, armour )
	
	-- Added by LBFrank 4/22/19 different upgrade orders for different classes of units
	-- the standard upgrade order
	local upgradeOrder = {
			CREATUREUPGRADE_HitPoints, CREATUREUPGRADE_RangedDamage, CREATUREUPGRADE_SplashDamage,
			CREATUREUPGRADE_MeleeDamage, CREATUREUPGRADE_Defense, CREATUREUPGRADE_Speed, 
			CREATUREUPGRADE_SightRadius, CREATUREUPGRADE_AreaAttackRadius };

	-- don't do melee upgrade on 'meat' or very low melee damage units in general
	if ( ci_getattribute( creature, "melee_damage" ) <= 2 + ci_rank( creature ) ) then
		
		upgradeOrder = {
			CREATUREUPGRADE_HitPoints, CREATUREUPGRADE_RangedDamage, CREATUREUPGRADE_SplashDamage,
			CREATUREUPGRADE_Defense, CREATUREUPGRADE_Speed, CREATUREUPGRADE_SightRadius,
			CREATUREUPGRADE_AreaAttackRadius };
	end	

	
	-- upgrade orders for 'glass cannons.' Damage and speed, then other stats should be prioritized over HP.
	-- will need eHP for this
	local eHP = ci_getattribute( creature, "hitpoints" ) / (1 - ci_getattribute( creature, "armour" ))

	-- ranged glass
	if ( ci_rangedamage( creature ) >= (eHP / (5*ci_rank( creature ))) ) then
		-- low melee ranged glass
		if ( ci_getattribute( creature, "melee_damage" ) <= 2 + ci_rank( creature ) ) then
			upgradeOrder = {
				CREATUREUPGRADE_RangedDamage, CREATUREUPGRADE_SplashDamage, CREATUREUPGRADE_Speed,
				CREATUREUPGRADE_SightRadius, CREATUREUPGRADE_HitPoints, CREATUREUPGRADE_Defense,
				CREATUREUPGRADE_AreaAttackRadius };
		else
			upgradeOrder = {
				CREATUREUPGRADE_RangedDamage, CREATUREUPGRADE_SplashDamage, CREATUREUPGRADE_Speed,
				CREATUREUPGRADE_MeleeDamage, CREATUREUPGRADE_SightRadius, CREATUREUPGRADE_HitPoints,
				CREATUREUPGRADE_Defense, CREATUREUPGRADE_AreaAttackRadius };
		end
	end

	-- melee glass cannon
	if (ci_rangedamage( creature ) == 0 and ( ci_meleedamage( creature ) >= (eHP / (5*ci_rank( creature ))) )) then
		upgradeOrder = {
			CREATUREUPGRADE_MeleeDamage, CREATUREUPGRADE_Speed, CREATUREUPGRADE_SightRadius, 
			CREATUREUPGRADE_HitPoints, CREATUREUPGRADE_Defense,
			CREATUREUPGRADE_AreaAttackRadius };
	end
	
	local count = getn( upgradeOrder )
	
	for i=1, count do
		local type = upgradeOrder[i]
		
		aitrace("CreatureUpgrade: index:"..i.." type:"..type)
	
		if (type ~= CREATUREUPGRADE_Defence or armour < 0.7) then
				
			if (IsCreatureUpgradeAvailable(creature, type) == 1) then
				
				 if (CanCreatureUpgradeWithEscrow( creature, type )==1) then
					sg_creatureupgradeType = type;
					aitrace("CreatureUpgrade: buy type:"..type)
				else
					aitrace("CreatureUpgrade: could not afford:"..type)
				end
					
				-- return here so as not to accidentally buy a less useful upgrade - wait instead
				return
			end
		
		end
		
	end	
		
end

function Command_creatureupgrade( )

	if (sg_creatureupgradeEbpNetId~=0 and sg_creatureupgradeType~=-1) then
		ReleaseGatherEscrow();
		ReleaseRenewEscrow();
		CreatureUpgrade(sg_creatureupgradeEbpNetId, sg_creatureupgradeType)
		aitrace("Script: creature upgrade ebpnetid:"..sg_creatureupgradeEbpNetId.." type:"..sg_creatureupgradeType);
	end
	

end





