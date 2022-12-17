function set_target_priorities()

    --Set target type priorities, these are not fully understood, but they do seem to work and have some affect
	--I think Lab, Foundry, and Chambers are the only ones that work. Highest sum of values in an area will be targetted, but only if a unit is nearby too
	--Only one foundry counts towards the total value. Other building types don't seem to work, but haven't been fully tested --Bchamp 5/17/22
	SetTargetTypePriority( Creature_EC, 1000 )
	SetTargetTypePriority( SoundBeamTower_EC, 0 )
	SetTargetTypePriority( AntiAirTower_EC, 0 )
	SetTargetTypePriority( ElectricGenerator_EC, 5000 )
	SetTargetTypePriority( RemoteChamber_EC, 1500 )
	SetTargetTypePriority( WaterChamber_EC, 1500 )
	SetTargetTypePriority( Aviary_EC, 1500 )
	SetTargetTypePriority( ResourceRenew_EC, 0 )
	SetTargetTypePriority( Foundry_EC, 0 )--5000 )
	SetTargetTypePriority( VetClinic_EC, 0 )
	SetTargetTypePriority( GeneticAmplifier_EC, 0 )
	SetTargetTypePriority( LandingPad_EC, 0 )
	SetTargetTypePriority( BrambleFence_EC, 0 )
	SetTargetTypePriority( Lab_EC, 0 )
	SetTargetTypePriority( Henchman_EC, 0 )
	SetDefendTypePriority( Lab_EC, 500 )
    SetDefendTypePriority( Foundry_EC, 5000 ) -- add more defend targets?

end


function set_attck_parameters()

    icd_groundgroupminsize = 8;
	icd_groundgroupmaxsize = 40;
	
	icd_watergroupminsize = 8;
	icd_watergroupmaxsize = 40;
	
	icd_airgroupminsize = 8;
	icd_airgroupmaxsize = 40;
	
	icd_groundgroupminvalue = 500;
	icd_groundgroupmaxvalue = 7500;
	
	icd_watergroupminvalue = 400;
	icd_watergroupmaxvalue = 7500;
	
	icd_airgroupminvalue = 500;
	icd_airgroupmaxvalue = 7500;
		
	icd_groundattackpercent = 100;
	icd_waterattackpercent = 100;
	icd_airattackpercent = 100;

    icd_startAtRank = 2
	-- this is how many seconds the AI will wait to build a better creature
	--icd_bestCreatureWaitTime = 10
    --icd_buildDefensively = 1
    -- 4/24/2022 the variable icd_chooseDefendChamber doesn't seem to work
    --icd_chooseDefendChamber = 1

end



function army_analysis()

    --desired_creature = Army_GetUnit( player_index, i )
    --elec_creature_cost = ci_getattribute( desired_creature, "costrenew" )
    --elec_creature_cost = ci_getattribute( desired_creature, "cost" )
    --creature_build_time = ci_getattribute( desired_creature, "constructionticks" )
    -- how to get other attribute?
    --ci_rangedamage( creatureinfo )
    --ci_isartillery( creatureinfo )
    
end