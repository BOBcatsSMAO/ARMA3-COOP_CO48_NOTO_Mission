_unit = _this select 1;
if ( !alive mhq2 ) then {
    hint "The MHQ is currently destroyed.";
} else {
if ( isEngineOn mhq2 ) then {
    hint "You cannot teleport to MHQ when MHQ engine is on.";
} else {
if ((getPosATL mhq2 select 2) > 1) then {
    hint "You cannot teleport to MHQ when MHQ is overturned.";
} else {
		_unit setDir direction mhq2;
		_unit setPos [getPos mhq2 select 0, getPos mhq2 select 1, (getPos mhq2 select 2)-1];
		_unit setPos (mhq2 modelToWorld [+0,-6,((position mhq2) select 2)-5]);
	
};
};
};

