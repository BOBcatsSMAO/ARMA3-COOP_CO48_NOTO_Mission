//
// Farooq's Revive 1.5 (原版本)
//

//------------------------------------------//
// Parameters - Feel free to edit these
//------------------------------------------//

// Enable teamkill notifications
FAR_EnableDeathMessages = true;

// If enabled, unconscious units will not be able to use ACRE radio, hear other people or use proximity chat
FAR_MuteACRE = false;

if (isNil "FAR_BleedOut") then 
{
    FAR_BleedOut = 600;	//流血死亡超时 0值禁用显示负数读秒,无止血菜单
	
/*
	0 = 只有医疗兵才能治疗无需医疗包和急救包
	1 = 任何人都能救治无需医疗包和急救包
	2 = 必须有医疗包有黄包的只能止血
	3 = 玩家只要有医疗包(不消耗)或急救包就可以治疗
*/
    FAR_ReviveMode = 1; //1,3模式无止血菜单, 0,2模式满足医治条件时隐藏止血菜单
};
//------------------------------------------//

if(isNil "FAR_bleedTime")then {FAR_bleedTime = true}; //true 全局3d显示流血读秒

//if(isNil "FAR_in_Spectator")then {FAR_in_Spectator = true}; //true 玩家倒下后进入观战模式
//RscSpectator_allowedGroups = [BIS_grpBlue,BIS_grpGreen]; //所有小组成员可供观众预览,默认使用所有组。
//RscSpectator_allowFreeCam = false; //禁用观战模式自由视角,默认true开启

call compile preprocessFileLineNumbers "FAR_revive\FAR_revive_funcs.sqf";

#define SCRIPT_VERSION "1.517 plus"

FAR_isDragging = false;
FAR_isCarry = false;//
FAR_deathMessage = [];
FAR_Damage_make = [];//
FAR_inveh_EH = [];//
FAR_remote_EH = [];//
FAR__units = [];//
FAR_Debugging = true;
FAR_Player_save = player;//
FAR_emptyPos_veh = [];//
FAR_Unconscious_veh = [];//

if (isDedicated) exitWith {};

////////////////////////////////////////////////
// Player Initialization
////////////////////////////////////////////////
[] spawn
{
    waitUntil {!isNull player};

	// Public event handlers
	"FAR_deathMessage" addPublicVariableEventHandler FAR_public_EH;
	"FAR_Damage_make" addPublicVariableEventHandler FAR_public_EH;
	"FAR_inveh_EH" addPublicVariableEventHandler FAR_public_EH;
	"FAR_remote_EH" addPublicVariableEventHandler FAR_remote_exec;//
	
	//[] spawn FAR_Player_Init;//*

 if (isNil "FAR_hint_sw") then {
	if (FAR_MuteACRE) then
	{
		[] spawn FAR_Mute_ACRE;

		hintSilent format["Farooq's Revive %1 is initialized.%2", SCRIPT_VERSION, "\n\n 注意:无意识的单位将无法使用电台,听到别人或使用近距离聊天"];
	}
	else
	{
		hintSilent format["Farooq's Revive %1 is initialized.", SCRIPT_VERSION];
	};
	
	switch (FAR_ReviveMode) do 
	{
		case 0 :{TitleText ["医疗模式0: 只有医疗兵才能治疗无需医疗包和急救包", "Plain Down"]};
		case 1 :{TitleText ["医疗模式1: 任何人都能救治无需医疗包和急救包", "Plain Down"]};
		case 2 :{TitleText ["医疗模式2: 必须有医疗包有黄包的只能止血", "Plain Down"]};
		case 3 :{TitleText ["医疗模式3: 玩家只要有医疗包(不消耗)或急救包就可以治疗", "Plain Down"]};
	};
 };
 
	// Event Handlers
	player addEventHandler 
	[
		"Respawn", 
		{ 
		 if (!alive FAR_Player_save) then {
		 
		    FAR_Player_save setVariable ["FAR_isUnconscious", 2, true];
			player setVariable ["FAR_action_arr", []];
			
		    if (player getVariable ["FAR_isUnconscious", 2] == 2) then
			{
			   [] spawn FAR_Player_Init;
			};
		 };
		}
	];
};

FAR_Player_Init =
{
	
	// Cache player's side
	//FAR_PlayerSide = side player;

	// Clear event handler before adding it
	player removeAllEventHandlers "HandleDamage";

	player addEventHandler ["HandleDamage", FAR_HandleDamage_EH];
	/*{_x removeAllEventHandlers "HandleDamage"}forEach units group player;
	{_x addEventHandler ["HandleDamage", FAR_HandleDamage_EH]} forEach units group player;
	player addEventHandler 
	[
		"Killed",
		{
			// Remove dead body of player (for missions with respawn enabled)
			_body = _this select 0;
			
			[_body] spawn 
			{
			
				waitUntil { alive player };
				_body = _this select 0;
				deleteVehicle _body;
			}
		}
	];*/
	
	player setVariable ["FAR_isUnconscious", 0, true];
	player setVariable ["FAR_isStabilized", 0, true];
	player setVariable ["FAR_isDragged", 0, true];
	player setVariable ["FAR_isCarry", 0, true];//
	player setVariable ["ace_sys_wounds_uncon", false];
	player setVariable ["FAR_Only_one_EH", 0, true];//
	player setVariable ["FAR_Revive_actDisable", 0, true];//
	player setCaptive false;

	FAR_isDragging = false;
	
	if (count (player getVariable ["FAR_action_arr", []]) == 0) then
	{
	   [] spawn FAR_Player_Actions;
	};
};
/*
FAR_marker_Dead = {
	_this setMarkerColorLocal "ColorGrey";
	sleep 10;
	deleteMarkerLocal _this;
};*/

//从载具弹出伤员
FAR_out_veh = {
	while {vehicle _this != _this && {alive _this}} do 
	{
		_this action ["eject", vehicle _this];
		sleep 0.5;
		if(animationState _this=="getoutquadbike_cargo"||{animationState _this=="getoutquadbike"})then{sleep 1.6};//debug
		if(vehicle _this==_this)exitWith{};
		_this action ["getout", vehicle _this];
		sleep 0.5;
		if(vehicle _this==_this)exitWith{};
		_this setPos (_this modelToWorld [0,0,0]);
	};
	if ((getPos _this select 2)>2) then {
        waitUntil {if(!alive _this)exitwith{true};_this setVelocity [0,0,-9999];sleep 0.1;((velocity _this) select 2)<8 && {(getPos _this select 2)<2}};
		_this setVelocity [0,0,0];
	};
    _this switchMove "ainjppnemstpsnonwrfldnon";
};

/*
FAR_Check_coerce_Move = {
    if (_this getVariable "FAR_isDragged" == 0 && {_this getVariable "FAR_isCarry" == 0}) exitWith {
		animationState _this in ["amovppnemstpsraswrfldnon_injured","ainjppnemstpsnonwrfldnon_rolltoback","ainjppnemstpsnonwrfldnon_injuredhealed"]
	};
    if (_this getVariable "FAR_isDragged" == 1) exitWith {
		animationState _this in ["ainjppnemrunsnonwnondb_still"]
	};
    if (_this getVariable "FAR_isCarry" == 1) exitWith {
		animationState _this in ["ainjpfalmstpsnonwnondnon_carried_up","ainjpfalmstpsnonwnondnon_carried_down","ainjpfalmstpsnonwnondnon_carried_still"]
	}; 
};{!(_this call FAR_Check_coerce_Move)}*/

//无意识时强制动作
FAR_coerce_Move = {
	if (_this getVariable ["FAR_isUnconscious", 8] == 1 && {alive _this} && {!(animationState _this in ["ainjppnemstpsnonwrfldnon_rolltoback",/*"ainjppnemstpsnonwrfldnon_injuredhealed",*/"ainjppnemstpsnonwrfldnon","ainjppnemstpsnonwrfldnon_rolltofront"/*,"amovppnemsprslowwrfldf_injured"爬动*/,"ainjppnemrunsnonwnondb_still","ainjpfalmstpsnonwnondnon_carried_up","ainjpfalmstpsnonwnondnon_carried_down","ainjpfalmstpsnonwnondnon_carried_still"])}) then 
	{
		if (vehicle _this == _this) then 
		[{
		    if (_this getVariable "FAR_isCarry" == 0) then
			[{
			    if (_this getVariable "FAR_isDragged" == 0) then
				[{
					if (animationState _this in ["acrgpknlmstpsnonwnondnon_amovpercmstpsraswrfldnon_getoutmedium","acrgpknlmstpsnonwnondnon_amovpercmstpsraswrfldnon_getouthighhemtt"]) then
					[{
					    _this switchMove "ainjppnemstpsnonwrfldnon";
					},{
					    _this playMoveNow "ainjppnemstpsnonwrfldnon_rolltoback";
					}];
				},{
				    _this playMoveNow (if(_this getVariable ["FAR_stance", ""] != "PRONE")then[{"ainjppnemrunsnonwnondb_still"},{"ainjppnemstpsnonwrfldnon_rolltoback"}]);
				}];
			},{
			    //_this switchMove "ainjpfalmstpsnonwnondnon_carried_still";
				[_this, "switchMove", "ainjpfalmstpsnonwnondnon_carried_still"] call FAR_remote_move;
			}];
		},{
			//载具内强制动作
			if (animationState _this != "getoutquadbike_cargo" && {animationState _this != "getoutquadbike"}) then 
			{
			    _this playMoveNow "ainjppnemstpsnonwrfldnon_rolltoback";
			    if (driver vehicle _this == _this && {isEngineOn vehicle _this} && {local vehicle _this}) then 
			    {
			        vehicle _this engineOn false;//强制关闭引擎
				    vehicle _this setVelocity [0,0,0];
			    };
				
				_type = "";
				{if(_x select 0 == _this)then{_type = _x select 1}} forEach fullCrew vehicle _this;
			    if (_type in ["driver", "commander", "gunner", "Turret"]) then 
			    {
					_this spawn FAR_out_veh;
					//resetCamShake; 
					//addCamShake [5,10,1];//抖动镜头
			    };
			};
		}];
	};
};

//刚加入游戏时为无意识的玩家创建标记
if (isMultiplayer) then
{
    {
		if (_x getVariable ["FAR_isUnconscious", 8] == 1 && {alive _x}) then
		{
		    _makeName = Format["FAR_%1",_x];
			_makeExist = false;
			{if(_makeName in _x)then{_makeExist = true}} forEach FAR__units;
			if (_makeExist) exitWith {};
		    _make = createMarkerLocal [_makeName, getPosATL _x];
			_makeName setMarkerTypeLocal "hd_dot";
			_makeName setMarkerTextLocal (name _x) + " 倒下";
			_makeName setMarkerColorLocal "ColorRed";
			FAR__units set [count FAR__units, [_x, _makeName]];
			//无意识单位在载具的动作
			if(vehicle _x != _x)then{_x playMoveNow "ainjppnemstpsnonwrfldnon_rolltoback"};
		};
	} forEach playableUnits;
};

[] spawn
{
	while {true} do
	{
		
		//单位标记删除
			{
			    _unit = _x select 0;
			    _makeName = _x select 1;
			    if (_unit getVariable ["FAR_isUnconscious", 0] == 1 && {alive _unit}) then
			    [{
				    _makeName setMarkerPosLocal (getPosATL _unit);
			    },{
				    deleteMarkerLocal _makeName;
				    FAR__units set [_forEachIndex, 0];
				    FAR__units = FAR__units - [0];
				    //if(alive _unit)then[{deleteMarkerLocal _makeName},{_makeName spawn FAR_marker_Dead}];
			    }];
			} forEach FAR__units;

		//载具损毁移出无意识单位
			{
			 _unit = if(isMultiplayer)then[{_x},{_x select 0}];
			 if (_unit getVariable "FAR_isUnconscious" == 1 && {vehicle _unit != _unit} && {!alive (vehicle _unit)} && {alive _unit}) then
			 {
				_unit spawn FAR_out_veh;
			 };
			}forEach (if(isMultiplayer)then[{[player]},{FAR__units}]);//
		
		//玩家与AI无意识时强制动作&加入原来小队
		if (isMultiplayer) then
		[{
			player call FAR_coerce_Move;
		},{
			{
			   _unit = _x select 0;
			   _unit call FAR_coerce_Move;
				//加入原组
			   if ((_unit getVariable ["FAR_AI_group", [0, ""]] select 0) == 1 && {vehicle _unit == _unit} && {_unit getVariable "FAR_isUnconscious" == 1} && {alive _unit}) then
			    {
			       [_unit] joinSilent ((_unit getVariable "FAR_AI_group") select 1);
				   _unit setVariable ["FAR_AI_group", [0, ""]];
				};
			} forEach FAR__units;
		}];//
		
		
		if (!isNull player) then
		{
		   if (!alive FAR_Player_save) then
		   {
			  FAR_Player_save setVariable ["FAR_isUnconscious", 2, true];
			  player setVariable ["FAR_action_arr", []];
		   };
		
		   if (player getVariable ["FAR_isUnconscious", 2] == 2) then
		   { 
		      if (alive player && {player isKindOf "Man"}) then
			  {
		        [] spawn FAR_Player_Init;//
		      };
		   };
		};////

		sleep 1;
		
		if (FAR_Player_save != player) then 
		{
		   if (count (FAR_Player_save getVariable ["FAR_action_arr", []]) == 5) then 
		   {
		      _action_arr = FAR_Player_save getVariable "FAR_action_arr";
		      FAR_Player_save removeAction (_action_arr select 0);
		      FAR_Player_save removeAction (_action_arr select 1);
		      FAR_Player_save removeAction (_action_arr select 2);
		      FAR_Player_save removeAction (_action_arr select 3);
			  FAR_Player_save removeAction (_action_arr select 4);
		      FAR_Player_save setVariable ["FAR_action_arr", []];
		   };
		   if (count (player getVariable ["FAR_action_arr", []]) == 0) then
		   {
		      [] spawn FAR_Player_Actions;
		   };
		};////
	};
};

///////////////////////////////////////////////3D标记/////////////////////////////////////
_3d = addMissionEventHandler ["Draw3D",
{
	{
		_unit = if(isMultiplayer)then[{_x},{_x select 0}];
		if (_unit getVariable ["FAR_isUnconscious", 8] == 1 && {(_unit distance player) < 80} && {(vehicle _unit != vehicle player) || {cameraView == "External"}}) then
		{
			drawIcon3D["a3\ui_f\data\map\MapControl\hospital_ca.paa",[1,0,0,1],_unit,0.5,0.5,0,format["%1 (%2%3m)", name _unit, _unit getVariable ["FAR_unitbleedOut", ""], ceil (player distance _unit)],0,0.025];//0.02
		};
	} forEach (if(isMultiplayer)then[{playableUnits},{FAR__units}]);
}];
//////////////////////////////////////////////////////////////////////////////////////////////////////////


FAR_Mute_ACRE =
{
	waitUntil { time > 0 };

	waitUntil 
	{
		if (alive player) then 
		[{
			// player getVariable ["ace_sys_wounds_uncon", true/false];
			if ((player getVariable["ace_sys_wounds_uncon", false])) then 
			{
				private["_saveVolume"];

				_saveVolume = acre_sys_core_globalVolume;

				player setVariable ["acre_sys_core_isDisabled", true, true];
				
				waitUntil 
				{
					acre_sys_core_globalVolume = 0;

					if (!(player getVariable["acre_sys_core_isDisabled", false])) then 
					{
						player setVariable ["acre_sys_core_isDisabled", true, true];
						[true] call acre_api_fnc_setSpectator;
					};

					!(player getVariable["ace_sys_wounds_uncon", false]);
				};

				if ((player getVariable["acre_sys_core_isDisabled", false])) then 
				{
					player setVariable ["acre_sys_core_isDisabled", false, true];
					[false] call acre_api_fnc_setSpectator;
				};

				acre_sys_core_globalVolume = _saveVolume;
			};
		},{
			waitUntil { alive player };
		}];

		sleep 0.25;

		false
	};
};

////////////////////////////////////////////////
// [Debugging] Add revive to playable AI units
////////////////////////////////////////////////
if (!FAR_Debugging or isMultiplayer) exitWith {};

{
	if (!isPlayer _x && {alive _x}) then 
	{
		_x addEventHandler ["HandleDamage", FAR_HandleDamage_EH];
		_x setVariable ["FAR_isUnconscious", 0, true];
		_x setVariable ["FAR_isStabilized", 0, true];
		_x setVariable ["FAR_isDragged", 0, true];
		_x setVariable ["FAR_isCarry", 0, true];//
		_x setVariable ["FAR_Only_one_EH", 0, true];//
		_x setVariable ["FAR_Revive_actDisable", 0, true];//
	};
} forEach units group player;
