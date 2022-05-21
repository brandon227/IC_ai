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
    Enemy.Index = GetChosenEnemy()
    Enemy.Rank = PlayersRank( Enemy.Index, player_max )

    Enemy.NumRods = NumEnemyBuildings( ResourceRenew_EC )
    Enemy.NumFoundry = NumEnemyBuildings( Foundry_EC )
    Enemy.NumGenerator = NumEnemyBuildings( RemoteChamber_EC )
    Enemy.NumAviary = NumEnemyBuildings( Aviary_EC )
    Enemy.NumWaterChamber = NumEnemyBuildings( WaterChamber_EC )
    Enemy.NumSoundbeam = NumEnemyBuildings( SoundBeamTower_EC )
    Enemy.NumAATower = NumEnemyBuildings( AntiAirTower_EC )
    Enemy.NumVetClinic = NumEnemyBuildings( VetClinic_EC )
    Enemy.NumGenAmp = NumEnemyBuildings( GeneticAmplifier_EC )

    Enemy.NumHenchmen = PlayersUnitCount( Enemy.Index, player_max, Henchman_EC )
    Enemy.MilitaryValue = PlayersMilitaryValue( Enemy.Index, player_max )
    Enemy.MilitaryPop = PlayersMilitaryPopulation( Enemy.Index, player_max )

    if player_enemy == GetChosenEnemy() then
        Scuttle( ResourceRenew_EC )
    end

end