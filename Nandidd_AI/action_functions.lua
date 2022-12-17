

function try_level_up()
   
    if (CanResearchWithEscrow( RESEARCH_Rank2 + research_level - 1 ) == 1) then
        ReleaseGatherEscrow()
        ReleaseRenewEscrow()
        xResearch( RESEARCH_Rank2 + research_level - 1);
    end

end


function try_build_henchman()
	
	if ( CanBuild( Henchman_EC )==1 ) then
		xBuild( Henchman_EC, PH_Best );
	end

end


function try_build_rod()

    if (CanBuild( ResourceRenew_EC )==1) then
		xBuild( ResourceRenew_EC, 0 )
		return 1
	else
		return 0
	end	

end


function try_build_gen()

    if (CanBuild( ElectricGenerator_EC )==1) then
		xBuild( ElectricGenerator_EC, PH_OpenGeyser )
		return 1
	else
		return 0
	end

end


function try_upgrade_gen()

	if (CanUpgrade( UPGRADE_EGen ) == 1) then
		xUpgrade( UPGRADE_EGen )
		return 1
	else
		return 0
	end

end


function try_build_chamber(type)

    if (CanBuild( type ) == 1) then 
		xBuild( type, PH_Best )
	end

end


function try_build_creature()

    if ( creaturesQ < pop_max and CanBuildCreature( sg_class_ground )==1) then
		--alternate chambers when a lot of creatures queued...not sure which icd works, but it seems to be working well 5/20/22
		if (creatures_queued >= 5) then
			if icd_buildDefensively == 0 then
				icd_buildDefensively = 1
				icd_chooseDefendChamber = 1
			else 
				icd_buildDefensively = 0
				icd_chooseDefendChamber = 0
			end
		end
		xBuildCreature( sg_class_ground ) --doesn't matter if this is ground or swimmer or anything, it will still work

	end

end


function try_build_workshop()

	if (CanBuild( Foundry_EC ) == 1) then
		xBuild( Foundry_EC, PH_Best )
	end
	
end


function try_build_clinic()

	if ( CanBuild( VetClinic_EC )==1) then
		xBuild( VetClinic_EC, PH_Best )
	end

end


function try_build_soundbeam()

	if ( CanBuild( SoundBeamTower_EC )==1) then
		xBuild( SoundBeamTower_EC, PH_Best)--PH_DefendSite )
	end

end

function try_build_aatower()

	if ( CanBuild( AntiAirTower_EC )==1) then
		xBuild( AntiAirTower_EC, PH_Best)--PH_DefendSite )
	end

end


function try_build_geneticamplifier()

	if (CanBuild( GeneticAmplifier_EC ) == 1) then
		xBuild( GeneticAmplifier_EC, PH_Best )
	end
	
end




-- 'xResearch' or 'Reseach'
-- xResearch( RESEARCH_HenchmanYoke );
-- Research( RESEARCH_HenchmanMotivationalSpeech );
-- Research( RESEARCH_StrengthenElectricalGrid );
-- xResearch( RESEARCH_HenchmanHeal );
-- Research( RESEARCH_HenchmanBinoculars );
-- Research( RESEARCH_IncBuildingIntegrity );
-- Research( RESEARCH_StrengthenFences );
-- Research( RESEARCH_HenchmanImprovedHealing );
-- Research( RESEARCH_TowerUpgrade );
function try_research(type)

	if (CanResearch(type)==1) then
		if (2==1) then
			xResearch( type )
		else
			Research( type )
		end
	end

end						
				
					


function try_creature_upgrade(cid, cuid)

	if (CanCreatureUpgrade( cid, cuid )==1) then
		CreatureUpgrade(cid, cuid)
	end

end

