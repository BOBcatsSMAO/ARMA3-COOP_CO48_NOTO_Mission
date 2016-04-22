//objectiveInit.sqf

_objType = floor(random(10));

if (count glb_objectiveLocations > 0) then
{
    _rndLoc = glb_objectiveLocations call BIS_fnc_selectRandom;
    switch (_objType) do
    {
        case 0: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective0Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
        case 1: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective1Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
        case 2: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective2Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
        case 3: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective3Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
        case 4: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective4Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
        case 5: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective5Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
		case 6: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective6Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
		case 7: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective7Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
		case 8: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective8Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
		case 9: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective9Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
		case 10: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective9Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
		case 11: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective9Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
		case 12: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective9Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
		case 13: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective9Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
		case 14: {[(getMarkerPos _rndLoc)] execVM "Objectives\objective9Create.sqf"; glb_objectiveLocations = glb_objectiveLocations - [_rndLoc];};
        default {diag_log "Objective not defined"};
    };
}
else
{
    ["Won"] call BIS_fnc_endMissionServer;
}; 