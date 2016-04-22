1 fadeSound 1;
action_ear_plugs = player addAction ["<t color='#ffff33'>Put on ear plugs</t>",{
	_u = _this select 1;
	_i = _this select 2;
	if (soundVolume == 1) then {
		1 fadeSound 0.1;
		_u setUserActionText [_i,"<t color='#ffff33'>Take off ear plugs</t>"];
	} else {
		1 fadeSound 1;
		_u setUserActionText [_i,"<t color='#ffff33'>Put on ear plugs</t>"];
	};
},[],-30,false,false];
