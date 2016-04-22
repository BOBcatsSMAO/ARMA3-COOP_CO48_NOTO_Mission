_unit = _this select 1;
if ( !alive mhq ) then {
    hint "The MHQ is currently destroyed.";
} else {
if ( isEngineOn mhq ) then {
    hint "You cannot teleport to MHQ when MHQ engine is on.";
} else {
if ((getPosATL mhq select 2) > 1) then {
    hint "You cannot teleport to MHQ when MHQ is overturned.";
} else {
		_unit setDir direction mhq;
		_unit setPos [getPos mhq select 0, getPos mhq select 1, (getPos mhq select 2)-1];
		_unit setPos (mhq modelToWorld [+0,-6,((position mhq) select 2)-5]);
	
};
};
};

