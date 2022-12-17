dofilepath("data:ai/Nandidd_AI/parameter_functions.lua")
dofilepath("data:ai/Nandidd_AI/variable_functions.lua")
dofilepath("data:ai/Nandidd_AI/decision_functions.lua")
dofilepath("data:ai/Nandidd_AI/action_functions.lua")
dofilepath("data:ai/Nandidd_AI/holdfunctions.lua") -- existing script, do we need 'money_on_hold'?
--dofilepath("data:ai/military.lua") -- existing script
--dofilepath("data:ai/scout.lua") -- existing script

--- sets initial parameters at the start of a game and runs do_ai on a loop 
function nandidd_init()
    
    -- DEFINE STRATEGIC METRICS --
    lowest_good_rank = 2 -- choose lowes level that we want to build creatures (before army considerations)
    max_henchmen = 100 -- choose ultimate henchman limit (based on pop cap and map?)
    scuttleorder = {VetClinic_EC,GeneticAmplifier_EC,ResourceRenew_EC,
                            ElectricGenerator_EC,SoundBeamTower_EC,AntiAirTower_EC,WaterChamber_EC,
                            Aviary_EC,RemoteChamber_EC,Foundry_EC}
    pressure_level = 50 -- choose 0<->100 for economy<->army focus (maybe determines desired_elec and build_workshop())

    -- DEFINE ARMY METRICS --
    -- army_vars = army_analysis()
    fact_army_maxrank = 5 -- make dynamic
    fact_army_minrank = 2 -- make dynamic
    creature_rank = max(lowest_good_rank, fact_army_minrank)
    -- test order -- go through each creature in the army to decide on upgrade order
    creature_upgrade_order = {CREATUREUPGRADE_RangedDamage, CREATUREUPGRADE_HitPoints, CREATUREUPGRADE_MeleeDamage, CREATUREUPGRADE_Defense, 
                                    CREATUREUPGRADE_Speed, CREATUREUPGRADE_AreaAttackRadius, CREATUREUPGRADE_SightRadius}
    player_index = Player_Self()
    enemy_index = GetChosenEnemy()
    army_size = Army_GetSize(player_index)

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

    --define eco icd variables
    -- gathering variables needed for c++ code to stop idle hench -- some of these parameters seem to over-ride reasearch levels so it can build hench indefinitely
    icd_maxgatherers = 90 
    icd_maxgathersites = 25
    icd_henchman_per_scrapyard_near = 2.0
    icd_henchman_per_scrapyard_med = 2.3
    icd_henchman_per_scrapyard_far = 2.6
    icd_gatherDist_near = 35
    icd_gatherDist_med = 45
    icd_gatherDist_far = 50
    icd_maxfoundrydist = 50

    --define army icd variables
    base_engage_value = 1.4
    base_flee_value = 0.7
    --icd_engageEnemyValueModifier
    icd_engageEnemyValueModifier = base_engage_value; --only engage enemy if you have a bigger army
	icd_fleeEnemyValueModifier = base_flee_value; --flee when you army starts to get small
    set_target_priorities()
    set_attck_parameters()

    RegisterTimerFunc("do_ai", 1.0 )

end


--- ai decision making process that is run on a loop by nandidd_init
function do_ai()
	

	-- DEFINE GAME STATE VARIABLES --
	-- can crash if function have the same name as variable 
	icd_buildDefensively = 0 -- do we need the code that defines this?
    num_ccsQ = NumBuildingQ( RemoteChamber_EC ) --Creature_EC )
    num_ccs = NumBuildingActive( RemoteChamber_EC ) 
    num_wcsQ = NumBuildingQ( WaterChamber_EC )
    num_wcs = NumBuildingActive( WaterChamber_EC )
    num_chambersQ = NumBuildingQ( RemoteChamber_EC )-- NumChambers()--NumChambers(chamber_type_dict[desired_creature_type])
    num_chambers = NumBuildingActive( RemoteChamber_EC ) --NumChambers()--NumChambers(chamber_type_dict[desired_creature_type])
    num_rodsQ = NumBuildingQ( ResourceRenew_EC )
    num_workshopsQ = NumBuildingQ( Foundry_EC )
    num_workshops = NumBuildingActive( Foundry_EC )
    num_geneticamplifiersQ = NumBuildingQ( GeneticAmplifier_EC )
    num_geneticamplifiers = NumBuildingActive( GeneticAmplifier_EC )
    enemy_workshops = 1 -- how do we get this value? 
    num_clinics = NumBuildingActive( VetClinic_EC )
    num_clinicsQ = NumBuildingQ( VetClinic_EC )
    num_soundbeamsQ = NumBuildingActive( SoundBeamTower_EC ) -- should be NumBuildingQ, but doesn't work fro tower upgrad or for defending
    num_aatowersQ = NumBuildingActive( AntiAirTower_EC ) -- should be NumBuildingQ, but doesn't work
    creaturesQ = NumCreaturesQ()
    creatures_queued = NumCreaturesQ()-NumCreaturesActive() -- does this include creatures guarding?
	num_henchmenQ = NumHenchmanQ()
    num_henchmen = NumHenchmanActive() 
    henchmen_queued = NumHenchmanQ()-NumHenchmanActive() -- does this include henchmen guarding? It seems so as calculation works in game. NumHenchmenGuarding()
    henchmen_guarding = NumHenchmenGuarding()
    coal_rate = ScrapPerSec()
	elec_rate = ElectricityPerSec()
    elec_rateQ = ElectricityPerSecQ()
    is_gather_site_open = IsGatherSiteOpen()
    research_level = GetRank() -- previously curRank (same as BChamps code)
	enemy_research_level = PlayersRank( enemy_index, player_max )


    -- CALCULATE GAME STATE VARIABLES --
    --choose_creatures()
    levelling_up_flag = var_levelling_up_flag()
    fact_selfValue = 0 -- where does this change?
    fact_enemyValue = 0 -- where does this change?
    dominance_ratio, dominance_diff, dominance_flag, defence_flag = var_dominance()
    desired_henchmen = var_desired_henchmen() -- how to define coal_piles near drop off point? 
    desired_elec_rate = var_desired_elec_rate() -- define based on rank and pressure_level
    creature_coal_per_sec = var_creature_coal_per_sec() -- should define based on creature we want to produce
    creature_elec_per_sec = var_creature_elec_per_sec() -- should define based on creature we want to produce
    yoke_upgrade_worth, grid_upgrade_worth, tower_upgrade_worth = var_upgrades_worth()


	-- PERFORM ACTION DECISIONS --
    --destroy_buildings()
    build_defences()
    level_up()
    save_res()
    advanced_structures()
    key_upgrades()
	build_henchmen()
	build_elec()
    build_workshop()
	build_chamber()
	build_creatures()   
    upgrade_creatures()
    general_upgrades()
    spend_floating_res()
    engage_enemy()

    
end


--additional things to consider:

--include army analysis when defining parameters (max level, min level, best creature, creature coal/elec cost, chamber types)
--prioritise building highest level creatures
--stop henchmen standing around
--spend massively floating res
--fix tower building/upgrading logic
--decide creature based on enemy creatures
--decide chamber types based on desired creature
--prioritise creatures upgrades better
--include map analysis when defining parameters
--build additional CCs forward if needed
--change attack priorities more effectively
--use towers to secure key areas better
--different types of defense tower based on enemy creatures
--gyrocopters for cliff geysers



