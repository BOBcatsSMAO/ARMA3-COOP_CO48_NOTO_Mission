//example objective0Create.sqf
//call line being: [(getMarkerPos _rndLoc)] execVM "objective0Create.sqf";

_centerPos = (_this select 0);

_units = [_centerPos,300,20,3,2,2,1,EAST] call JSHK_fnc_patrols;//<<<<<new call line

_clearTask =
[
    "ClearID",
    true,
    ["Incoming message from Command clear the area by any means necessary.","Primary: Clear Area","Clear Area"],
    _centerPos,
    "AUTOASSIGNED",
    6,
    true,
    true
] call BIS_fnc_setTask;

_tower = createVehicle ["O_MBT_02_arty_F", _centerPos, [], 0, "NONE"];
_towerTask = 
[
   "RadioTowerID",
   true,
   ["Destroy the Artillery by any means necessary Viper Actual out!","Secondary: Destroy Artillery","Destroy Artillery"],
   getPos _tower,
   "AUTOASSIGNED",
   5,
   true,
   true
] call BIS_fnc_setTask; 


_clearTaskLoop = [_units,_clearTask] spawn//<<<<<<new stuff here
{
    waitUntil {{alive _x} count (_this select 0) < 5};
    [(_this select 1),"Succeeded"] call BIS_fnc_taskSetState;
};

 _towerCompleted = [_tower,_towerTask] spawn 
{
    waitUntil {!alive (_this select 0)}; 
    [(_this select 1),"Succeeded"] call BIS_fnc_taskSetState;
};

waitUntil {scriptDone _clearTaskLoop && {scriptDone _towerCompleted}};

[_units] spawn JSHK_fnc_deleteOldAO;

0 = [] execVM "objectiveInit.sqf"; 