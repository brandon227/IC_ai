

function build_defences()

    if (defence_flag == 1 or dominance_diff < -(100*(num_soundbeamsQ+num_aatowersQ+1))) then -- num_soundbeamsQ and num_aatowersQ don't seem to work atm
        try_build_soundbeam()
        try_build_aatower() 
    end

end


function level_up()
    
    -- level up if we have a dominant army, high income, 2 levels behind the enemy, or cannot produce good creatures at this level
    if (levelling_up_flag == 0) then
        if research_level < fact_army_maxrank then
            if (research_level < creature_rank) then
                try_level_up()
            elseif (dominance_flag == 1) then
                try_level_up()
            elseif (coal_rate >= level_up_coal_rates[research_level] and elec_rate >= level_up_elec_rates[research_level]) then
                try_level_up()
            elseif (enemy_research_level-research_level > 1) then
                try_level_up()
            end
        end
    end  
    
end


function reset_escrow()

    -- stop saving and clear our savings account
	SetGatherEscrowPercentage(0)
	SetRenewEscrowPercentage(0)
	ReleaseGatherEscrow()
	ReleaseRenewEscrow()

end


function save_res()

    -- save up resource for ranking up only if we have a dominant army or high income
	if (research_level >= creature_rank) then -- we should change depending on army analysis
		if (research_level == fact_army_maxrank or research_level == 5) then
			reset_escrow()
		elseif (levelling_up_flag == 1) then
			reset_escrow()
		elseif (dominance_flag == 1) then
			SetGatherEscrowPercentage(min(100*(dominance_ratio-1)/2, 50))
			SetRenewEscrowPercentage(min(100*(dominance_ratio-1)/2, 50))
        elseif (coal_rate >= level_up_coal_rates[research_level] and elec_rate >= level_up_elec_rates[research_level]) then
            SetGatherEscrowPercentage(50)
			SetRenewEscrowPercentage(50)
		else
			reset_escrow()
		end
	end

end


function advanced_structures()

    -- research advanced structures if we are L3+ and have a large proportion of desired number of henchmen
    if (research_level > 2 and num_henchmenQ > desired_henchmen*0.8 and ResearchQ(RESEARCH_AdvancedStructure) == 0) then -- *0.8 doesn't work atm with desired_henchmen logic
        try_research(RESEARCH_AdvancedStructure)
    end

end



function key_upgrades()

    if (research_level > 2 and (yoke_upgrade_worth == 1 or grid_upgrade_worth == 1 or tower_upgrade_worth == 1)) then
        if (num_clinicsQ < 1) then
            try_build_clinic()
        elseif (defence_flag == 1) then
            if (tower_upgrade_worth == 1) then
                try_research(RESEARCH_TowerUpgrade)
            end
        elseif (yoke_upgrade_worth == 1) then
            try_research(RESEARCH_HenchmanYoke)
        elseif (grid_upgrade_worth == 1) then
            try_research(RESEARCH_StrengthenElectricalGrid)
        elseif (tower_upgrade_worth == 1) then
            try_research(RESEARCH_TowerUpgrade)
        end
    end

end



function build_henchmen()

    -- build a henchman if we have less than the desired number
    if (num_henchmenQ < desired_henchmen and henchmen_guarding < 1) then
        if (henchmen_queued < 1) then
            try_build_henchman()
        end
    else
        -- if we have enough hench try to use the lab for research
        --try_level_up()
        try_research(RESEARCH_AdvancedStructure)
    end

end

function build_elec()

    -- build an electrical structure if we have less than the desired income
    if (elec_rateQ < desired_elec_rate) then  
        can_build_rod = try_build_rod()
        if can_build_rod == 0 then
            can_upgrade_gen = try_upgrade_gen()
            if can_upgrade_gen == 0 then
                can_build_gen = try_build_gen()
            end
        end
    end

end



function build_workshop()

    -- build a workshop if our current gather sites are full (and we are not already building a workshop)
    if (is_gather_site_open == 0) then -- or is_gather_site_open == 1
        if (num_workshopsQ == num_workshops) then
            -- maybe also check if there are new safe coal sites available
            try_build_workshop()
        end
    end

end


function choose_creatures()

    for i=0, (army_size-1) do 
        if i==0 then
            creature_priority_weight = 1000
        else
            creature_priority_weight = 0
        end
        -- "SetCounterValue seems to set the desired creature count for a particular unit." - BChamp 2018
        -- may be more of a creature priority weighting (with weighted randomness?) 
        SetCounterValue(i, creature_priority_weight ) -- i = creature index, and newvalue = how many of those creatures we want (or priority?)
    end

end

function build_chamber()

    -- build a new chamber if we have income to support it (and are at least researching towards a level where we can produce good creatures)
    if (coal_rate > creature_coal_per_sec*num_ccsQ and elec_rate > creature_elec_per_sec*num_ccsQ and ResearchQ(research_levels[creature_rank]) == 1) then 
        --try_build_chamber(RemoteChamber_EC) --try_build_chamber(chamber_type_dict[desired_creature_type])
        if (num_ccsQ > 0 and num_wcsQ < 1) then -- should decide based on desired creature
            try_build_chamber(WaterChamber_EC)
        else
            try_build_chamber(RemoteChamber_EC) --try_build_chamber(chamber_type_dict[desired_creature_type])
        end
    end

end



function build_creatures()

    -- top up creature queue to 1 creature per chamber
    local i = 0 
	while (i < (1*num_chambers)-creatures_queued) do 
		try_build_creature()
		i = i+1
	end

end


function upgrade_creatures()
    
    if creaturesQ > (num_geneticamplifiersQ+1)*15 then -- should also depend on the number of different types of creatures
        if num_geneticamplifiersQ < 1 then -- should also depend on how many more creature upgrades we want (seems to only use one genetic amplifier at a time anyway)
            try_build_geneticamplifier()
        end
    end

    if num_geneticamplifiers > 0 then
        -- go through each upgrade type and creature in the army to decide on what to upgrade -- adapted from Bchamps creatureupgrades.lua 16/12/2022
        for i=1, getn(creature_upgrade_order) do
            for cindex=0, (army_size-1) do 
                local ccount = Army_NumCreatureInArmy( player_index, cindex )
                if (ccount >= 10) then 
                    local cinfo = Army_GetUnit( player_index, cindex );
                    local ebpnetid = ci_ebpnetid(cinfo);
                    local creature_id = ebpnetid
                    local type = creature_upgrade_order[i] -- var has to be called 'type' it seems
                    if (IsCreatureUpgradeAvailable(creature_id, type) == 1) then 
                        try_creature_upgrade(creature_id, type)
                        return --return here to avoid worse upgrades? or for efficiency?
                    end
                end
            end
        end
    end

end




function general_upgrades()

    if (research_level > 3 and num_clinics > 0) then 
        try_research(RESEARCH_HenchmanYoke)
        try_research(RESEARCH_StrengthenElectricalGrid)
        try_research(RESEARCH_TowerUpgrade)
        try_research(RESEARCH_HenchmanMotivationalSpeech)
        try_research(RESEARCH_IncBuildingIntegrity)
        --try_research(RESEARCH_HenchmanBinoculars)
        --try_research(RESEARCH_HenchmanTag)
        --try_research(RESEARCH_StrengthenFences)
        try_research(RESEARCH_HenchmanHeal)
        --try_research(RESEARCH_HenchmanImprovedHealing) -- is this different to heal?
    end

end

function spend_floating_res()

    if (ScrapAmount() > max(500*research_level,1000) and ElectricityAmount() > max(50*research_level,100)) then -- make dynamic based on research_level? - probably not
        try_build_soundbeam()
        try_build_aatower() 
        if (ElectricityAmount() > max(500*research_level,1000) and num_ccsQ < 5*research_level and research_level >= creature_rank) then
            if (num_ccsQ > 0 and num_wcsQ < 1) then -- should decide based on desired creature
                try_build_chamber(WaterChamber_EC)
            else
                try_build_chamber(RemoteChamber_EC)
            end
        end
    end

end









function engage_enemy() -- adapted from bchamps military.lua code 14/12/2022

    if (enemy_workshops >= 2) then
        if (dominance_ratio < base_engage_value) then --(fact_selfValue*1.2 < Enemy.MilitaryValue) then --if you normally wouldn't engage the enemy, raid foundries
            SetTargetTypePriority( Foundry_EC , 60000)
            icd_engageEnemyValueModifier = base_engage_value*0.6 --0.8
        else
            SetTargetTypePriority( Foundry_EC , 5000)
            icd_engageEnemyValueModifier = base_engage_value
        end
    end
    --go for lab if enemy is weak
    if (dominance_ratio > 10) then --Enemy.MilitaryValue < fact_selfValue/10 then
        SetTargetTypePriority( Foundry_EC , 100)
        SetTargetTypePriority( Lab_EC , 60000)
    else
        SetTargetTypePriority( Lab_EC, 0 )
    end
    --if you have tons of units, might as well attack
    if PopulationActive() >= PopulationMax()*0.9 then
        icd_engageEnemyValueModifier = base_engage_value*0.6 --0.8
        icd_fleeEnemyValueModifier = base_flee_value*1.5 --1.2
    else
        icd_engageEnemyValueModifier = base_engage_value; --only engage enemy if you have a bigger army
	    icd_fleeEnemyValueModifier = base_flee_value; --flee when you army starts to get small
    end

    AttackNow()

end


