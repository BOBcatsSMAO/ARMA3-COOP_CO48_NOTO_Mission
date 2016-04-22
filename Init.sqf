[] execVM "tags.sqf";															// Tags anzeigen lassen
[] execVM "scripts\monitor.sqf";												// Liste wv mann drauf sind FBS und co
[] execVM "scripts\3rdView Restrictions.sqf";                         //3DW
[] execVM "FAR_revive\FAR_revive_init.sqf";
If (!IsDedicated) Then {														// Gruppen Manager

 _Functions = []ExecVM "joinerUI\GroupMonitor.sqf";
 waitUntil {!IsNull Player && ScriptDone _Functions};
 Player AddEventHandler ["Respawn", {_menu = (_this select 0) addAction ["<t color=""#3399FF"">" +"Groups", "joinerUI\showJoiner.sqf"];}];
 _menu = player addAction ["<t color=""#3399FF"">" +"Groups", "joinerUI\showJoiner.sqf"];
 
};
enableSaving [false,false];

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


execVM "misc\intro.sqf";														// intro musik

call compile preprocessFile "scripts\=BTC=_revive\=BTC=_revive_init.sqf";		// revive

[180,60,60,60,[],[],[],[]] execVM "misc\cly_bodyRemoval.sqf";

execVM "misc\grenadeStop.sqf";
_handle = []execVM "earplugs.sqf"												// ohrstöpsel

[] spawn {
  while {not isnull C1} do { "VAS" setmarkerpos getpos C1; sleep 0.5; };
};





















