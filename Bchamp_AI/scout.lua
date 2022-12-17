--the goal is to help the AI see what enemy is up to

function init_scout()
    --probably should differentiate between active and queued
    Self = {
        Index = 1,
        Rank = 1,
        Coal = 0,
        Elec = 0,

        NumRods = 0,
        NumFoundry = 0,
        NumGenerator = 0,
        NumChamber = 0,
        NumAviary = 0,
        NumWaterChamber = 0,
        TotalChambers = 0,
        NumSoundbeam = 0,
        NumAATower = 0,
        NumVetClinic = 0,
        NumGenAmp = 0,

        NumHenchmen = 0,
        NumHenchmenQ = 0,
        QdHenchmen = 0,
        NumHenchmenGuarding = 0,
        NumCreatures = 0,
        QdCreatures = 0,
        MilitaryValue = 0,
        MilitaryPop = 0,
        GroundUnitValue = 0,
        NumGroundUnit = 0,
    }

    Enemy = {
        Index = 1,
        Rank = 1,

        NumRods = 0,
        NumFoundry = 0,
        NumGenerator = 0,
        NumChamber = 0,
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

    mapsizefactor = max((fact_closestAmphibDist-150)/100,0)

    RegisterTimerFunc("doscout", 2)
    return 1
end

function NumEnemyBuildings( entity )
    return PlayersUnitCount( Enemy.Index, player_max, entity )
end

function doscout()
    Self = {
        Index = Player_Self(),
        Rank = GetRank(),
        Coal = ScrapAmount(),
        Elec = ElectricityAmount(),

        NumRods = NumBuildingActive( ResourceRenew_EC ),
        NumFoundry = NumBuildingActive( Foundry_EC ),
        NumGenerator = NumBuildingActive( ElectricGenerator_EC ),
        NumChamber = NumBuildingActive( RemoteChamber_EC ),
        NumAviary = NumBuildingActive( Aviary_EC ),
        NumWaterChamber = NumBuildingActive( WaterChamber_EC ),
        TotalChambers = (Self.NumChamber + Self.NumAviary + Self.NumWaterChamber),
        NumSoundbeam = NumBuildingActive( SoundBeamTower_EC ),
        NumAATower = NumBuildingActive( AntiAirTower_EC ),
        NumVetClinic = NumBuildingActive( VetClinic_EC ),
        NumGenAmp = NumBuildingActive( GeneticAmplifier_EC ),

        NumHenchmen = NumHenchmanActive(),
        NumHenchmenQ = NumHenchmanQ(),
        QdHenchmen = NumHenchmanQ() - NumHenchmanActive(),
        NumHenchmenGuarding = NumHenchmenGuarding(),
        NumCreatures = NumCreaturesActive(),
        QdCreatures = NumCreaturesQ() - NumCreaturesActive(),
        MilitaryValue = PlayersMilitaryValue( Self.Index, player_max ),
        MilitaryPop = PlayersMilitaryPopulation( Self.Index, player_max ),
        GroundUnitValue = PlayersUnitTypeValue( Self.Index, player_max, sg_class_ground ),
        NumGroundUnit = PlayersUnitTypeCount( Self.Index, player_max, sg_class_ground ),

    }

    Enemy = {
        Index = GetChosenEnemy(),
        Rank = PlayersRank( Enemy.Index, player_max ),

        NumRods = NumEnemyBuildings( ResourceRenew_EC ),
        NumFoundry = NumEnemyBuildings( Foundry_EC ),
        NumGenerator = NumEnemyBuildings( ElectricGenerator_EC ),
        NumChamber = NumBuildingActive( RemoteChamber_EC ),
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

function ClosestEnemyAmphibDist()
    local i = 0
	local t = PlayersTotal()
	local closest_distance = 1000

	while ( i < t ) do
	
		-- test to see if this enemy is the enemy we want to attack
        
		if (Player_IsEnemy( i )	== 1) then
            if Player_Dist(i, 0) < closest_distance then
                closest_distance = Player_Dist(i,0)
            end
		end
	
		i=i+1
	end
    return closest_distance
end