

function build_defences()

    -- check army composition for better decisions
    if (defence_flag == 1 and -dominance_diff > ((200*num_soundbeamsQ)+(200*num_aatowersQ))) then
        try_build_soundbeam()
        try_build_aatower() 
    end

end


function level_up()
    
    -- level up if we have a dominant army, high income, or cannot produce good creatures at this level
    if (levelling_up_flag == 0) then
        if (curRank < creature_rank) then
            try_level_up()
        elseif (dominance_flag == 1) then
            try_level_up()
        elseif (coal_rate >= level_up_coal_rates[curRank] and elec_rate >= level_up_elec_rates[curRank]) then
            try_level_up()
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
	if (curRank > 1) then -- we should change depending on army analysis
		if (curRank == fact_army_maxrank or curRank == 5) then
			reset_escrow()
		elseif (levelling_up_flag == 1) then
			reset_escrow()
		elseif (dominance_flag == 1) then
			SetGatherEscrowPercentage(min(100*(dominance_ratio-1)/2, 50))
			SetRenewEscrowPercentage(min(100*(dominance_ratio-1)/2, 50))
        elseif (coal_rate >= level_up_coal_rates[curRank] and elec_rate >= level_up_elec_rates[curRank]) then
            SetGatherEscrowPercentage(50)
			SetRenewEscrowPercentage(50)
		else
			reset_escrow()
		end
	end

end


function advanced_structures()

    -- research advanced structures if we are L3+ and have a large proportion of desired number of henchmen
    if (curRank > 2 and num_henchmenQ > desired_henchmen*0.8 and ResearchQ(RESEARCH_AdvancedStructure) == 0) then -- *0.8 doesn't work atm with desired_henchmen logic
        try_research(RESEARCH_AdvancedStructure)
    end

end


function key_upgrades()

    if (curRank > 2 and (yoke_upgrade_worth == 1 or grid_upgrade_worth == 1 or tower_upgrade_worth == 1)) then
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
    if (num_henchmenQ < desired_henchmen) then
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

-- ElectricityPerSecQ() does not seem to update fast enough to build multiple elec at a time
--function build_elec()
--
--    if (elec_rateQ < desired_elec_rate) then  
--        can_build_rod = 1
--        can_build_gen = 1
--        can_upgrade_gen = 1
--        while (elec_rateQ < desired_elec_rate and can_build_rod == 1) do
--            can_build_rod = try_build_rod()
--            elec_rateQ = ElectricityPerSecQ()
--        end
--        --while (elec_rateQ < desired_elec_rate and can_upgrade_gen == 1) do
--        --    can_upgrade_gen = try_upgrade_gen()
--        --    elec_rateQ = ElectricityPerSecQ()
--        while (elec_rateQ < desired_elec_rate and can_build_gen == 1) do
--            can_build_gen = try_build_gen()
--            elec_rateQ = ElectricityPerSecQ()
--        end
--    end
--
--end


function build_workshop()

    -- build a workshop if our current gather sites are full (and we are not already building a workshop)
    if (is_gather_site_open == 0) then -- or is_gather_site_open == 1
        if (num_workshopsQ == num_workshops) then
            -- maybe also check if there are new safe coal sites available
            try_build_workshop()
        end
    end

end


--function creature_upgrades()
    
    --if (num_creatures() > 10) then
    --    if (GeneticAmplifier_EC == 0) then
    --        try_build_genamp()
    --    else
    --        for (i in creatures) do 
    --          if num_creatures(i) > 10 then
        --        upgrade()
        --      end
    --
--end



function build_chamber()

    -- build a new chamber if we have income to support it (and are at least researching towards a level where we can produce good creatures)
    if (coal_rate > creature_coal_per_sec*num_chambersQ and elec_rate > creature_elec_per_sec*num_chambersQ and ResearchQ(research_levels[creature_rank]) == 1) then 
        try_build_chamber(RemoteChamber_EC) --try_build_chamber(chamber_type_dict[desired_creature_type])
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


function general_upgrades()

    if (curRank > 3) then 
        try_research(RESEARCH_HenchmanMotivationalSpeech)
        try_research(RESEARCH_IncBuildingIntegrity)
        --try_research(RESEARCH_HenchmanBinoculars)
        --try_research(RESEARCH_HenchmanTag)
        --try_research(RESEARCH_StrengthenFences)
        --try_research(RESEARCH_TowerUpgrade)
        --try_research(RESEARCH_HenchmanHeal)
        --try_research(RESEARCH_HenchmanImprovedHealing) -- is this different to heal?
    end

end




