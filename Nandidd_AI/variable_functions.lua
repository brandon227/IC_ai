
function var_levelling_up_flag()

    -- work out if we are currently levelling up    
	if (research_level == 1 and ResearchQ(RESEARCH_Rank2) == 1) then
		return 1
	elseif (research_level == 2 and ResearchQ(RESEARCH_Rank3) == 1) then
		return 1
	elseif (research_level == 3 and ResearchQ(RESEARCH_Rank4) == 1) then
		return 1
	elseif (research_level == 4 and ResearchQ(RESEARCH_Rank5) == 1) then
		return 1
	else
		return 0
	end

end


function var_dominance()

    -- determine how far ahead/behind we are in military
    local dominance_diff = fact_selfValue-fact_enemyValue
    local dominance_ratio = fact_selfValue/max(fact_enemyValue,1) -- adjusted so no no Div0

    if (dominance_ratio >= base_engage_value and dominance_diff >= 100) then -- change this threshold depending on income (or maybe absolute fact_selfValue)
        dominance_flag = 1
    else 
        dominance_flag = 0
    end

    if (dominance_ratio <= base_flee_value and dominance_diff <= -100) then -- change this threshold depending on income (or maybe absolute fact_selfValue)
        defence_flag = 1
    else 
        defence_flag = 0
    end

    return dominance_ratio, dominance_diff, dominance_flag, defence_flag 

end


function var_desired_henchmen()

    -- set how many henchmen we should aim for
    if (is_gather_site_open == 1) then
        return min(num_henchmenQ + 1, max_henchmen)
    else
        return min(max_henchmen, 10*research_level) -- make more detailed logic
    end

end


function var_desired_elec_rate()

    -- set how much elec income we should aim for
    if (research_level < 2) then
        if (ScrapAmount() > 500) then
            return 8  -- change depending on army?
        elseif (num_henchmen < 6) then
            return 2
        elseif (levelling_up_flag == 1) then
            return 6
        else
            return 4
        end
    else
        return coal_rate/3  -- change depending on army?
        -- floor division (//) seems to crash - maybe wrong data type
    end

end



function var_creature_coal_per_sec()

    -- estimate how much coal it costs to create one creature per second
    return 30 -- make dynamic based on creatures
    -- FYI 8 ticks = 1 second

end


function var_creature_elec_per_sec()

    -- estimate how much elec it costs to create one creature per second
    return 10 -- make dynamic based on creatures

end



function var_upgrades_worth()

    -- determine if key upgrades are worth it
    if coal_rate >= 20 then -- make more detailed thresholds
        yoke_upgrade_worth = 1 
    else
        yoke_upgrade_worth = 0
    end
    
    if elec_rate >= 10 then
        grid_upgrade_worth = 1
    else
        grid_upgrade_worth = 0
    end

    if num_soundbeamsQ + num_aatowersQ >= 5 then -- doesn't seem to work
        tower_upgrade_worth = 1
    else
        tower_upgrade_worth = 0
    end

    return yoke_upgrade_worth, grid_upgrade_worth, tower_upgrade_worth

end



