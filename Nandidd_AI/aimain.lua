
dofilepath("data:ai/Nandidd_AI/variable_functions.lua")
dofilepath("data:ai/Nandidd_AI/decision_functions.lua")
dofilepath("data:ai/Nandidd_AI/action_functions.lua")
dofilepath("data:ai/Nandidd_AI/holdfunctions.lua") -- existing script, do we need 'money_on_hold'?
--dofilepath("data:ai/military.lua") -- existing script
--dofilepath("data:ai/scout.lua") -- existing script


function nandidd_init()
    
    -- DEFINE STRATEGIC METRICS --
    lowest_good_rank = 2 -- choose lowes level that we want to build creatures (before army considerations)
    max_henchmen = 20 -- choose ultimate henchman limit (based on pop cap and map?)
    scuttleorder = {VetClinic_EC,GeneticAmplifier_EC,ResourceRenew_EC,
                            ElectricGenerator_EC,SoundBeamTower_EC,AntiAirTower_EC,WaterChamber_EC,
                            Aviary_EC,RemoteChamber_EC,Foundry_EC}
    pressure_level = 50 -- choose 0<->100 for economy<->army focus (maybe determines desired_elec and build_workshop())

    -- DEFINE ARMY METRICS --
    -- army_vars = army_analysis()
    fact_army_maxrank = 5 -- make dynamic
    fact_army_minrank = 2 -- make dynamic
    creature_rank = max(lowest_good_rank, fact_army_minrank)

    -- DEFINE GAME METRICS --
    pop_max = 300 -- make dynamic
	max_rods = 4 -- maximumn number of lightning rods allowed
    max_clinics = 2 -- maximumn number of research clinics allowed
	research_levels = {RESEARCH_Rank1, RESEARCH_Rank2, RESEARCH_Rank3, RESEARCH_Rank4, RESEARCH_Rank5}
	--chamber_type_dict = {ground: ground, water: water, air: air}
	sg_class_ground = 0
    level_up_coal_rates = {15, 45, 90, 150}
    level_up_elec_rates = {5, 15, 30, 50}

	--init_scout()
	--init_military()
    --define icd variables (army and henchman)
    RegisterTimerFunc("do_ai", 1.0 )

end



function do_ai()
	

	-- DEFINE GAME STATE VARIABLES --
	-- can crash if function and variable have the same name
    -- current_army_vars = current_army_analysis()
	icd_buildDefensively = 0 -- do we need the code that defines this?
    --desired_creature_type = desired_creature_type()
    num_chambersQ = NumBuildingQ( RemoteChamber_EC )-- NumChambers()--NumChambers(chamber_type_dict[desired_creature_type])
    num_chambers = NumBuildingActive( RemoteChamber_EC ) --NumChambers()--NumChambers(chamber_type_dict[desired_creature_type])
    num_rodsQ = NumBuildingQ( ResourceRenew_EC )
    num_workshopsQ = NumBuildingQ( Foundry_EC )
    num_workshops = NumBuildingActive( Foundry_EC )
    num_clinicsQ = NumBuildingQ( VetClinic_EC )
    num_soundbeamsQ = NumBuildingQ( SoundBeamTower_EC )
    num_aatowersQ = NumBuildingQ( AntiAirTower_EC )
    creaturesQ = NumCreaturesQ()
    creatures_queued = NumCreaturesQ()-NumCreaturesActive()
	num_henchmenQ = NumHenchmanQ()
    num_henchmen = NumHenchmanActive()
    henchmen_queued = NumHenchmanQ()-NumHenchmanActive()
    coal_rate = ScrapPerSec()
	elec_rate = ElectricityPerSec()
    elec_rateQ = ElectricityPerSecQ()
    is_gather_site_open = IsGatherSiteOpen()
    curRank = GetRank()


    -- CALCULATE GAME STATE VARIABLES --
    levelling_up_flag = var_levelling_up_flag()
    fact_selfValue = 0 -- where does this change?
    fact_enemyValue = 0 -- where does this change?
    dominance_ratio, dominance_diff, dominance_flag, defence_flag = var_dominance()
    desired_henchmen = var_desired_henchmen() -- how to define coal_piles near drop off point? 
    desired_elec_rate = var_desired_elec_rate() -- define based on rank and pressure_level
    creature_coal_per_sec = var_creature_coal_per_sec() -- define based on creature we want to produce
    creature_elec_per_sec = var_creature_elec_per_sec() -- define based on creature we want to produce
    yoke_upgrade_worth, grid_upgrade_worth, tower_upgrade_worth = var_upgrades_worth()


	-- PERFORM MACRO ACTION DECISIONS --
    --destroy_buildings()
    build_defences()
    level_up()
    save_res()
    advanced_structures()
    key_upgrades()
	build_henchmen()
	build_elec()
    build_workshop()
    --upgrade_creatures()
	build_chamber()
	build_creatures()   
    general_upgrades()


    -- PERFORM ARMY ACTION DECISIONS --
    --??
    
end





--additional things to consider:
--account for different types of chambers
--change attack priorities
--stop henchmen standing around (is IsGatherSiteOpen() different to hench per coal pile limit?)
--include army analysis
--gyrocoptors



