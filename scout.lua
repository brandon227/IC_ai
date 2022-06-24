--the goal is to help the AI see what enemy is up to

function init_scout()
    --probably should differentiate between active and queued
    Self = {
        NumRods = 0,
        NumFoundry = 0,
        NumGenerator = 0,
        NumRemoteChamber = 0,
        NumAviary = 0,
        NumWaterChamber = 0,
        NumSoundbeam = 0,
        NumAATower = 0,
        NumVetClinic = 0,
        NumGenAmp = 0,

        NumHenchmen = 0,
        NumCreatures = 0,
        MilitaryValue = 0,
    }

    Enemy = {
        Index = 1,
        Rank = 1,

        NumRods = 0,
        NumFoundry = 0,
        NumGenerator = 0,
        NumRemoteChamber = 0,
        NumAviary = 0,
        NumWaterChamber = 0,
        NumSoundbeam = 0,
        NumAATower = 0,
        NumVetClinic = 0,
        NumGenAmp = 0,

        NumHenchmen = 0,
        NumCreatures = 0,
        MilitaryValue = 0,
        MilitaryPop = 0,
        GroundUnitValue = 0,
        NumGroundUnit = 0,
    }

    RegisterTimerFunc("doscout", 2)
    return 1
end

function NumEnemyBuildings( entity )
    return PlayersUnitCount( Enemy.Index, player_max, entity )
end

function doscout()
    Enemy = {
        Index = GetChosenEnemy(),
        Rank = PlayersRank( Enemy.Index, player_max ),

        NumRods = NumEnemyBuildings( ResourceRenew_EC ),
        NumFoundry = NumEnemyBuildings( Foundry_EC ),
        NumGenerator = NumEnemyBuildings( RemoteChamber_EC ),
        NumAviary = NumEnemyBuildings( Aviary_EC ),
        NumWaterChamber = NumEnemyBuildings( WaterChamber_EC ),
        NumSoundbeam = NumEnemyBuildings( SoundBeamTower_EC ),
        NumAATower = NumEnemyBuildings( AntiAirTower_EC ),
        NumVetClinic = NumEnemyBuildings( VetClinic_EC ),
        NumGenAmp = NumEnemyBuildings( GeneticAmplifier_EC ),

        NumHenchmen = PlayersUnitCount( Enemy.Index, player_max, Henchman_EC ),
        MilitaryValue = PlayersMilitaryValue( Enemy.Index, player_max ),
        MilitaryPop = PlayersMilitaryPopulation( Enemy.Index, player_max ),
        GroundUnitValue = PlayersUnitTypeValue( Enemy.Index, player_max, sg_class_ground ),
        NumGroundUnit = PlayersUnitTypeCount( Enemy.Index, player_max, sg_class_ground ),
    }

    if player_enemy == GetChosenEnemy() then
        Scuttle( ResourceRenew_EC )
    end

end

function IsAllyClose(distance)
	
	local i = 0
	local t = PlayersTotal()
	local Ally_distance = 1000

	while ( i < t ) do
	
		-- test to see if this enemy is the enemy we want to attack
        
		if (Player_IsEnemy( i )	~= 1 and i ~= Player_Self()) then
            Ally_distance = Player_Dist(i, 0)
            if Ally_distance < distance and Ally_distance ~= 0 then
                return 1
            end
		end
	
		i=i+1
	end
    return 0

end