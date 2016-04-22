//fn_deleteOldAO.sqf 
//example call: [_units] spawn JSHK_fnc_deleteOldAO; 

private "_units"; 

_units = (_this select 0); 

{ 
    if (!isNull _x) then 
    { 
        deleteVehicle _x; 
    }; 
    sleep 0.02;  
} forEach _units; 
{ 
    deleteVehicle _x; 
    sleep 0.02; 
} forEach (allDead + allDeadMen); 