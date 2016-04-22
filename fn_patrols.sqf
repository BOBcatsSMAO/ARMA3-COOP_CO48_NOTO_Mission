/* ////////////////////////////////////////////// 
Author: J.Shock 

File: fn_patrols.sqf 

Description: Creates randomly positioned and sized patrols throughout a defined radius of an AO 
             using a marker as the center position. 

Parameters:  
        1- Center position: (array) (default: empty array) 
        2- Radius to spawn units: (integer) (default: 300) 
        3- Number of foot patrol groups: (integer) (default: 5) 
        4- Number of vehicle patrol groups: (integer) (default: 3) 
        5- Number of mechanized patrol groups: (integer) (default: 2) 
        6- Number of armor patrol groups: (integer) (default: 2) 
        7- Number of air patrol groups: (integer) (default: 1) 
        8- Side: (side) (default: EAST) 
         
Return: Spawned units. 

Example Call line: _units = ["mrkName",200,5,3,2,2,1,EAST] call JSHK_fnc_patrols; 

*/////////////////////////////////////////////// 
private [ 
            "_AOmarker","_radius","_numFootPatrols","_numVehPatrols","_center", 
            "_numArmorPatrols","_numMechPatrols","_numAirPatrols","_side","_footUnits", 
            "_vehUnits","_armorUnits","_mechUnits","_airUnits","_units" 
        ]; 

_AOmarker = [_this, 0, [], [[]]] call BIS_fnc_param; 
_radius = [_this, 1, 300, [0]] call BIS_fnc_param; 
_numFootPatrols = [_this, 2, 20, [0]] call BIS_fnc_param; 
_numVehPatrols = [_this, 3, 3, [0]] call BIS_fnc_param; 
_numArmorPatrols = [_this, 4, 2, [0]] call BIS_fnc_param; 
_numMechPatrols = [_this, 5, 2, [0]] call BIS_fnc_param; 
_numAirPatrols = [_this, 6, 1, [0]] call BIS_fnc_param; 
_side = [_this, 7, EAST, [WEST]] call BIS_fnc_param; 

_footUnits = ["OIA_InfSentry", "OIA_InfTeam", "OIA_InfTeam_AT", "OIA_InfTeam_AA"]; 
_vehUnits = ["O_MRAP_02_hmg_F","O_MRAP_02_gmg_F"]; 
_armorUnits = ["O_MBT_02_cannon_F"]; 
_mechUnits = ["O_APC_Wheeled_02_rcws_F","O_APC_Tracked_02_cannon_F"]; 
_airUnits = ["O_Heli_Attack_02_black_F","O_Plane_CAS_02_F"]; 

_center = createCenter _side; 

_units = []; 

if (_numFootPatrols > 0) then 
{ 
    for "_i" from 1 to (_numFootPatrols) step 1 do  
    { 
        _configGrp = _footUnits call BIS_fnc_selectRandom; 
        _rndPos = [[[_AOmarker, _radius], []], ["water", "out"]] call BIS_fnc_randomPos; 
        _grp = [_rndPos, _center, (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> (_configGrp))] call BIS_fnc_spawnGroup; 
        [_grp, (_AOmarker), (random(50)+75)] call BIS_fnc_taskPatrol; 
        {_units pushBack _x} forEach units _grp; 
        sleep 0.05; 
    }; 
};     

if (_numVehPatrols > 0) then 
{ 
    for "_i" from 1 to (_numVehPatrols) step 1 do  
    { 
        _rndVeh = _vehUnits call BIS_fnc_selectRandom; 
        _rndPos = [_AOmarker,50,_radius,5,0,0.5,0,[],[]] call BIS_fnc_findSafePos; 
        _veh = [_rndPos,random(359),_rndVeh,_center] call BIS_fnc_spawnVehicle; 
        [(_veh select 2),(_AOmarker),(random(50)+100)] call BIS_fnc_taskPatrol; 
        {_units pushBack _x} forEach (_veh select 1); 
        _units pushBack (_veh select 0); 
        sleep 0.05; 
    }; 
}; 

if (_numArmorPatrols > 0) then 
{ 
    for "_i" from 1 to (_numArmorPatrols) step 1 do  
    { 
        _rndVeh = _armorUnits call BIS_fnc_selectRandom; 
        _rndPos = [_AOmarker,50,_radius,5,0,0.5,0,[],[]] call BIS_fnc_findSafePos; 
        _veh = [_rndPos,random(359),_rndVeh,_center] call BIS_fnc_spawnVehicle; 
        [(_veh select 2),(_AOmarker),(random(50)+100)] call BIS_fnc_taskPatrol; 
        {_units pushBack _x} forEach (_veh select 1); 
        _units pushBack (_veh select 0); 
        sleep 0.05; 
    }; 
}; 

if (_numMechPatrols > 0) then 
{ 
    for "_i" from 1 to (_numMechPatrols) step 1 do  
    { 
        _rndVeh = _mechUnits call BIS_fnc_selectRandom; 
        _rndPos = [_AOmarker,50,_radius,5,0,0.5,0,[],[]] call BIS_fnc_findSafePos; 
        _veh = [_rndPos,random(359),_rndVeh,_center] call BIS_fnc_spawnVehicle; 
        [(_veh select 2),(_AOmarker),(random(50)+100)] call BIS_fnc_taskPatrol; 
        {_units pushBack _x} forEach (_veh select 1); 
        _units pushBack (_veh select 0); 
        sleep 0.05; 
    }; 
}; 

if (_numAirPatrols > 0) then 
{ 
    for "_i" from 1 to (_numAirPatrols) step 1 do  
    { 
        _rndVeh = _airUnits call BIS_fnc_selectRandom; 
        _rndPos = [[[_AOmarker, _radius],[]],["water","out"],[],{}] call BIS_fnc_randomPos; 
        _veh = createVehicle [_rndVeh,_rndPos,[],0,"FLY"]; 
        createVehicleCrew _veh; 
        [(group _veh),(_AOmarker),350] call BIS_fnc_taskPatrol; 
        {_units pushBack _x} forEach (crew _veh); 
        _units pushBack _veh; 
        sleep 0.05; 
    }; 
};   

_units;  