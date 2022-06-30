
aitrace("Script Component: Hold functions")

-- internal global that states if we should wait for a purchase to go through
money_on_hold = 0;

function xBuild( val, placement )

	if (money_on_hold==0) then
		Build( val, placement )
	else 
		aitrace("money on hold:"..val)
	end

end

function xBuildWall( val )

	if (money_on_hold==0) then
		BuildWall( val )
	end

end

function xBuildCreature( val1 )

	if (money_on_hold==0) then
		BuildCreature( val1 )
	else 
		aitrace("money on hold:"..val1)
	end

end

function xUpgrade( val )
	
	if (money_on_hold==0) then
		Upgrade( val )
	else 
		aitrace("money on hold:"..val)
	end

end

function xResearch( val )
	
	if (money_on_hold==0) then
		Research( val )
		aitrace("xresearch:"..val)
	else 
		aitrace("money on hold:"..val)
	end

end