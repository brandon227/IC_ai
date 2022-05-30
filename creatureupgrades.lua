--extensive testing has shown that only one genetic amplifier will be used at a time, regardless of what is done here

aitrace("Script Component: CreatureUpgrade Functions")

function init_creatureupgrades()
	
	aitrace("init_creatureupgrades()")
	
	-- for now
	sg_docreature_upgrades = 1
	upgradeOrder = {}
	Choose_UpgradeOrder()
end

function docreatureupgrades()

	
	-- early exit if upgrades are turned off or there is no amplifier
	if (sg_docreature_upgrades == 0 or NumBuildingActive( GeneticAmplifier_EC )==0) then
		return
	end
	
	Logic_creatureupgrade()
	Command_creatureupgrade()

end

RegisterTimerFunc("docreatureupgrades", 5.0 ) --changed from 15 to 5 by Bchamp 4/1/2019 with hopes of multiple genamps being used

function Logic_creatureupgrade()
	
	sg_creatureupgradeEbpNetId = 0;
	sg_creatureupgradeArmyIndex = 0;
	sg_creatureupgradeType = -1;
	
	local curRank = GetRank()
	
	local AIplayerindex = Player_Self()
	local armysize = Army_GetSize(AIplayerindex)
	local mostUnitInArmy = 0
	local upgradesAvailable = {}

	for armyindex=0, (armysize-1) do
		local cinfo = Army_GetUnit( AIplayerindex, armyindex );
		local ebpnetid = ci_ebpnetid(cinfo);
		Choose_UpgradeOrder( ebpnetid, ci_getattribute( cinfo, "armour" ))

	end
	local carmour = 0
	
	-- go through each creature in the army
	for armyindex=0, (armysize-1) do
		-- get the number of these creatures in the world
		local ccount = Army_NumCreatureInArmy( AIplayerindex, armyindex )
		local mostUnitInArmy = 0
		local cinfo = Army_GetUnit( AIplayerindex, armyindex );
		local ebpnetid = ci_ebpnetid(cinfo);
		local crank = ci_rank( cinfo );
		-- should be a few of them before upgrading them
		if (ccount >= (12-(2*g_LOD))) then --lowered to 6 by Bchamp 4/5/2019 --9/15/2019 adjusted for LOD by Bchamp
			-- is this creature of a good rank
			if (crank >= (curRank-1)) then
				local temparmour = ci_getattribute( cinfo, "armour" )
				--upgradeOrder = Choose_UpgradeOrder( ebpnetid, ci_getattribute( cinfo, "armour" ))
				local remainingUpgradeCount = 0;
	
				for i=1, getn(upgradeOrder[armyindex]) do
					local type = upgradeOrder[armyindex][i]
					if (IsCreatureUpgradeAvailable(ebpnetid, type) == 1) then
						remainingUpgradeCount = remainingUpgradeCount + 1
					end
				end
				local upgradeCount = CreatureUpgradeNumResearched( ebpnetid )
				if (3 - g_LOD < remainingUpgradeCount) then --Added by Bchamp 4/5/2019 to account of LOD
					-- save the creature we will upgrade
					sg_creatureupgradeEbpNetId = ebpnetid;
					sg_creatureupgradeArmyIndex = armyindex;
					-- save the armour for late use
					carmour = temparmour
					aitrace("CreatureUpgrade: netid:"..ebpnetid.." armour:"..carmour.." rank:"..crank)

					if (sg_creatureupgradeEbpNetId ~= 0) then
						pickupgrade( sg_creatureupgradeEbpNetId, sg_creatureupgradeArmyIndex, carmour )
						return --return here for efficiency
					end
				end
			end
		end
	end
	

		
end

function Choose_UpgradeOrder()
	local armysize = Army_GetSize(Player_Self())
	for armyindex=0, (armysize-1) do
		local cinfo = Army_GetUnit( Player_Self(), armyindex );
		local creature = ci_ebpnetid(cinfo);
		local armour = ci_getattribute(creature,"armour")

		upgradeOrder[armyindex] = {
			CREATUREUPGRADE_HitPoints, CREATUREUPGRADE_RangedDamage, CREATUREUPGRADE_SplashDamage,
			CREATUREUPGRADE_MeleeDamage, CREATUREUPGRADE_Defense, CREATUREUPGRADE_Speed, 
			CREATUREUPGRADE_SightRadius, CREATUREUPGRADE_AreaAttackRadius };

		-- don't do melee upgrade on 'meat' or very low melee damage units in general
		if ( ci_getattribute( creature, "melee_damage" ) <= 2 + ci_rank( creature ) ) then
			
			upgradeOrder[armyindex] = {
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
				upgradeOrder[armyindex] = {
					CREATUREUPGRADE_RangedDamage, CREATUREUPGRADE_SplashDamage, CREATUREUPGRADE_Speed,
					CREATUREUPGRADE_SightRadius, CREATUREUPGRADE_HitPoints, CREATUREUPGRADE_Defense,
					CREATUREUPGRADE_AreaAttackRadius };
			else
				upgradeOrder[armyindex] = {
					CREATUREUPGRADE_RangedDamage, CREATUREUPGRADE_SplashDamage, CREATUREUPGRADE_Speed,
					CREATUREUPGRADE_MeleeDamage, CREATUREUPGRADE_SightRadius, CREATUREUPGRADE_HitPoints,
					CREATUREUPGRADE_Defense, CREATUREUPGRADE_AreaAttackRadius };
			end
		end

		-- melee glass cannon
		if (ci_rangedamage( creature ) == 0 and ( ci_meleedamage( creature ) >= (eHP / (5*ci_rank( creature ))) )) then
			upgradeOrder[armyindex] = {
				CREATUREUPGRADE_MeleeDamage, CREATUREUPGRADE_Speed, CREATUREUPGRADE_SightRadius, 
				CREATUREUPGRADE_HitPoints, CREATUREUPGRADE_Defense,
				CREATUREUPGRADE_AreaAttackRadius };
		end

	end
end

function pickupgrade( creature, armyindex, armour )
	
	local count = getn( upgradeOrder[armyindex] )
	
	for i=1, count do
		local type = upgradeOrder[armyindex][i]
		
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
				return 0 
			end
		
		end
		
	end	
	return 1 --completed all upgrades
end

function Command_creatureupgrade()

	if (sg_creatureupgradeEbpNetId~=0 and sg_creatureupgradeType~=-1) then
		CreatureUpgrade(sg_creatureupgradeEbpNetId, sg_creatureupgradeType)
		aitrace("Script: creature upgrade ebpnetid:"..sg_creatureupgradeEbpNetId.." type:"..sg_creatureupgradeType);
	end
	

end





