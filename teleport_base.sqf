_unit = _this select 1;
if ( !alive base ) then {
    hint "The MHQ is currently destroyed.";
} else {
//if ( isEngineOn base ) then {
//    hint "You cannot teleport to MHQ when MHQ engine is on.";
//} else {
if ((getPosATL mhq select 2) > 1) then {
    hint "You cannot teleport to MHQ when MHQ is overturned.";
} else {
		_unit setDir direction base;
		_unit setPos [getPos mhq select 0, getPos base select 1, (getPos base select 2)-1];
		_unit setPos (base modelToWorld [+0,-6,((position base) select 2)-5]);
	
};
};
