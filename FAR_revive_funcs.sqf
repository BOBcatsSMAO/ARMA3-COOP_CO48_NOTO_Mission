////////////////////////////////////////////////
// Player Actions
////////////////////////////////////////////////
FAR_Player_Actions =
{
  private ["_action1","_action2","_action3","_action4","_action5"];

	if (alive player && {player isKindOf "Man"}) then 
	{
		FAR_Player_save = player;
		_action1 = player addAction ["<t size='1' color='#C90000'>医治</t> <img size='1' color='#ffffff' shadow='0' image='a3\ui_f\data\map\MapControl\hospital_ca.paa'/>", {cursorTarget spawn FAR_HandleRevive}, [], 96, true, true, "", "_target call FAR_Check_Revive"];//'#ff8c00'橙黄色
		_action2 = player addAction ["<t color='#C90000'>止血</t>", {cursorTarget spawn FAR_HandleStabilize}, [], 96, true, true, "", "_target call FAR_Check_Stabilize"];
		_action3 = player addAction ["<t color='#C90000'>拖动</t>", {cursorTarget spawn FAR_Drag}, [], 95, false, true, "", "_target call FAR_Check_Dragging"];
		_action4 = player addAction ["<t color='#C90000'>扛起</t>", {cursorTarget spawn FAR_Carry}, [], 95, false, true, "", "_target call FAR_Check_Carry"];
		_action5 = player addAction ["<t color='#C90000'>搬出伤员</t>", {_unit = FAR_Unconscious_veh select 0; FAR_remote_EH = [_unit, nil, "outveh", nil]; publicVariable "FAR_remote_EH"; _unit spawn FAR_out_veh;}, [], 95, false, true, "", "_target call FAR_Check_MoveOut"];
	};
	
	player setVariable ["FAR_action_arr", [_action1,_action2,_action3,_action4,_action5]];
 
};

////////////////////////////////////////////////
// 处理死亡
////////////////////////////////////////////////
FAR_HandleDamage_EH =
{
	private ["_unit", "_killer", "_amountOfDamage", "_isUnconscious"];

	_unit = _this select 0;
	_amountOfDamage = _this select 2;
	_killer = _this select 3;
	_isUnconscious = _unit getVariable "FAR_isUnconscious";
	_amountOfDamage = if(_isUnconscious == 0)then[{(damage _unit)+(_amountOfDamage * 0.17)},{0}];//护甲
	
	if ((_unit getHit "head") > 0.25 || {_amountOfDamage >= 1 && {alive _unit} && {_isUnconscious == 0}}) then  
	{
		_unit setDamage 0;//防止出现'自我医疗'菜单(伤害为0会没有流血效果)
		_unit allowDamage false;
		_amountOfDamage = 0;

		[_unit, _killer] spawn FAR_Player_Unconscious;
	};
	
	_amountOfDamage
};

////////////////////////////////////////////////
// 让玩家无意识
////////////////////////////////////////////////
FAR_fn_deployWeapon = {//禁用架枪,望远镜,换弹夹,切换武器模式按键
	if ( (_this select 1) in (actionKeys "TactToggle" + actionKeys "binocular" + actionKeys "reloadMagazine" + (if(RscSpectator_B_Key_sw)then[{[]},{actionKeys "nextWeapon"}])) ) exitWith {true};
	false
};//C键"launchCM"  装备栏"gear"

FAR_BIS_Spectator = {//观战模式
	_layer = 'BIS_fnc_respawnSpectator' call BIS_fnc_rscLayer;
	RscSpectator_B_Key_sw = !RscSpectator_B_Key_sw;
	if(RscSpectator_B_Key_sw)then[{_layer cutrsc ['RscSpectator','plain']},{_layer cuttext ['','plain'];[]spawn{sleep 0.5;player switchCamera 'External'};}]; 
};

FAR_Player_Unconscious =
{

private["_unit", "_killer"];
_unit = _this select 0;
_killer = _this select 1;

if (_unit getVariable "FAR_Only_one_EH" == 0) then {//防止代码多次执行

	_unit setVariable ["FAR_Only_one_EH", 1, true];
	
	_side = side _unit;//
	
	// Death message
	if (FAR_EnableDeathMessages && {!isNull _killer}) then
	{
		FAR_deathMessage = [_unit, _killer, _side];
		publicVariable "FAR_deathMessage";
		["FAR_deathMessage", [_unit, _killer, _side]] call FAR_public_EH;
	};
	
	if (isPlayer _unit) then
	{
		titleText ["", "BLACK FADED"];
		enableRadio false;
		//openMap false;//bug
		if (isMultiplayer) then 
		{
			inGameUISetEventHandler ["PrevAction", "true"];
			inGameUISetEventHandler ["NextAction", "true"];
		    inGameUISetEventHandler ["Action", "true"];
		}; //showHUD false 隐藏滚轮菜单和准星
	};
	
	_unit stop true;
	_unit disableAI "MOVE";
	_unit disableAI "TARGET";
	_unit disableAI "AUTOTARGET";
	_unit disableAI "ANIM";
	
    _unit allowDamage false;
	
	// 如果单位在载具就弹出
	while {vehicle _unit != _unit && {alive _unit}} do 
	{
		unAssignVehicle _unit;
		_unit action ["eject", vehicle _unit];//"紧急逃生"
		sleep 0.5;//2
		if(animationState _unit=="getoutquadbike_cargo"||{animationState _unit=="getoutquadbike"})then{sleep 1.6};//完成跨出摩托动作
		if(vehicle _unit==_unit)exitWith{};
		_unit action ["getout", vehicle _unit];//"离开"
		sleep 0.5;
		if(vehicle _unit==_unit)exitWith{};
		_unit setPos (_unit modelToWorld [0,0,0]);
	};
	
	_unit setDamage 0;//0.5
    _unit setVelocity [0,0,0];
	_unit setCaptive true;
	
	if(!isNil "FAR_revive_move" || {animationState _unit == "AinvPknlMstpSlayWrflDnon_medic"})then[{[_unit, "switchMove", "AinjPpneMstpSnonWrflDnon"] call FAR_remote_move},{_unit playMove "ainjppnemstpsnonwrfldnon_rolltoback"}];//"AinjPpneMstpSnonWrflDnon_injuredHealed"
	
	_index = _unit addEventHandler ["fired", {deleteVehicle (_this select 6)}];//开火无效
	
	sleep 3;//4
    
	if (isPlayer _unit) then
	{
		[100] call BIS_fnc_bloodEffect;
		titleText ["", "BLACK IN", 1];
		enableRadio true;

		// Mute ACRE
		_unit setVariable ["ace_sys_wounds_uncon", true];
		
		// 按"B"键进入观战模式  "\"键自杀
		RscSpectator_B_Key_t = 0;
		RscSpectator_B_Key_sw = false;
		if (isNil {RscSpectator_B_Key}) then
		{
		    RscSpectator_B_Key = (findDisplay 46) displayAddEventHandler ["KeyDown", "
		    if (player getVariable 'FAR_isUnconscious' == 1) then {
		        if (time - RscSpectator_B_Key_t > 0.5) then {
		            RscSpectator_B_Key_t = time;
		            if ((_this select 1) == 48) then 
		            {
		                call FAR_BIS_Spectator;
		            };
		            if ((_this select 1) == 43 && {alive player}) then 
		            {
			            player setCaptive false;
		                if(vehicle player == player)then{player switchMove 'deadstate'};
			            player setDamage 1;
			        };
		        };
		        _this call FAR_fn_deployWeapon;
		    };"];
		};
		
		//if(FAR_in_Spectator)then {call FAR_BIS_Spectator};//是否自动进入观战模式
	};
	
	if ((getPos _unit select 2)>2) then {
	    waitUntil {if(!alive _unit)exitwith{true};_unit setVelocity [0,0,-9999];sleep 0.1;((velocity _unit) select 2)<8 && {(getPos _unit select 2)<2}};
		_unit setVelocity [0,0,0];
	};/////
	_unit switchMove "ainjppnemstpsnonwrfldnon";
	//_unit enableSimulation false;
	_unit setVariable ["FAR_isUnconscious", 1, true];
	
	_makeName = Format["FAR_%1",_unit];
	["FAR_Damage_make", [_unit,_makeName]] call FAR_public_EH;

	if (isMultiplayer) then {
	   FAR_Damage_make = [_unit,_makeName];
	   publicVariable "FAR_Damage_make";////////
	};
/////////////////////////////////////////////////////

	if (isPlayer _unit) then 
	[{
		_bleedOut = "";
		[_unit, _side] call FAR_hint1;
		_unit setVariable ["FAR_unitbleedOut", "", true];
		
		if (_unit getVariable "FAR_isStabilized" == 1) then 
		{
			//Unit has been stabilized. Disregard bleedout timer and umute player
			_unit setVariable ["ace_sys_wounds_uncon", false];
			
			[_unit, _side] call FAR_hint2;
		};
		
		// Player bled out
		if (FAR_BleedOut > 0 && {time > _bleedOut} && {_unit getVariable "FAR_isStabilized" == 0}) then
		{
			_unit setCaptive false;//
			if(vehicle _unit == _unit)then{_unit switchMove "deadstate"};
			_unit setDamage 1;
		};
			// Player got revived
			if(_unit getVariable "FAR_isStabilized" == 1)then{_unit setVariable ["FAR_isStabilized", 0, true]};
			//_unit setVariable ["FAR_Only_one_EH", 0, false];
			
			//滚轮菜单可用
			if (isMultiplayer) then 
			{
			    inGameUISetEventHandler ["PrevAction", "false"];
			    inGameUISetEventHandler ["NextAction", "false"];
			    inGameUISetEventHandler ["Action", "false"];
			};//showHUD true;
			
			//enableRadio true;
			
			// 退出观战模式
			if (RscSpectator_B_Key_sw) then 
			{
			    //openMap [false, false];//debug
			    _layer = "BIS_fnc_respawnSpectator" call BIS_fnc_rscLayer;
			    _layer cuttext ["","plain"];
			};
			
			if (!isNil {RscSpectator_B_Key}) then
			{
				(findDisplay 46) displayRemoveEventHandler ["KeyDown", RscSpectator_B_Key];
				RscSpectator_B_Key = nil;
			};
			
			if (isPlayer _unit) then
			{
				_unit setVariable ["ace_sys_wounds_uncon", false];// Unmute ACRE
				
				sleep 0.5;
				if(cameraView == "INTERNAL")then{player switchCamera "External"};
				hintSilent "";
			};
			
			if (alive _unit) then
			{
			    _unit stop false;
			    _unit enableAI "MOVE";
			    _unit enableAI "TARGET";
			    _unit enableAI "AUTOTARGET";
			    _unit enableAI "ANIM";
			    //_unit enableSimulation true;
			    _unit allowDamage true;
			    _unit setDamage 0;
			    _unit setCaptive false;
			
			    if (vehicle _unit == _unit) then 
				{
			        _unit playMove "amovppnemstpsraswrfldnon";
			        _unit playMove "";
				};
		    };
			
		if (isMultiplayer) then
		[{
			player removeEventHandler ["fired", _index];//开火有效
		},{
			if(!isNull _unit)then{_unit removeEventHandler ["fired", _index]};
		}];
	
	},{ ///////////AI///////////////////////
		// [Debugging] Bleedout for AI
		_bleedOut = "";
		[_unit, _side] call FAR_hint1;
		_unit setVariable ["FAR_unitbleedOut", "", true];
		
		if (_unit getVariable "FAR_isStabilized" == 1) then
		{			
			[_unit, _side] call FAR_hint2;
		};
		
		// AI bled out
		if (FAR_BleedOut > 0 && {time > _bleedOut} && {_unit getVariable "FAR_isStabilized" == 0}) then
		{
			_unit setCaptive false;//
			if(vehicle _unit == _unit)then{_unit switchMove "deadstate"};
			_unit setDamage 1;
			_unit setVariable ["FAR_isUnconscious", 0, true];//
			_unit setVariable ["FAR_isDragged", 0, true];//
			_unit setVariable ["FAR_isCarry", 0, true];//
		};
		
		if(isPlayer _unit)then{hintSilent ""};
		
		if (!isNull _unit) then
		{
			_unit removeEventHandler ["fired", _index]; //***
		};
	}];
};
};

FAR_hint1 = 
{
	_unit = _this select 0;
	_side = _this select 1;
	_bleedOut = time + FAR_BleedOut;
	_ttt = 0;
	while { !isNull _unit && {alive _unit} && {_unit getVariable "FAR_isUnconscious" == 1} && {_unit getVariable "FAR_isStabilized" == 0} && {FAR_BleedOut <= 0 || {time < _bleedOut}} } do
	{
		_unitbleedOut = round (_bleedOut - time);
		if (player == _unit) then
		{
		    hintSilent format["流血中离死亡还剩%1秒\n%2", _unitbleedOut, _side call FAR_CheckFriendlies];
			if (time - _ttt > 3) then //20
			{
				_ttt = time+10;
				['<t size="0.5" shadow="1">按B键打开或关闭观战模式，\键自杀或者Esc键重生（如果没有重生请等待队友救治！）</t>',-1,0.035 * safezoneH + safezoneY,10,1,0,169] spawn BIS_fnc_dynamicText;
			};
		};
		if(FAR_bleedTime)then {_unit setVariable ["FAR_unitbleedOut", format["%1s ", _unitbleedOut], true]};
		sleep 1;
	};
};

FAR_hint2 = 
{
	_unit = _this select 0;
	_side = _this select 1;
	_ttt = 0;
	while { !isNull _unit && {alive _unit} && {_unit getVariable "FAR_isUnconscious" == 1} } do
	{
		if (player == _unit) then
		{
			hintSilent format["你的伤势已经稳定\n%1", _side call FAR_CheckFriendlies];
			
			if (time - _ttt > 3) then 
			{
				_ttt = time+10;
				['<t size="0.5" shadow="1">按B键打开或关闭观战模式，\键自杀或者Esc键重生（如果没有重生请等待队友救治！）</t>',-1,0.035 * safezoneH + safezoneY,10,1,0,169] spawn BIS_fnc_dynamicText;
			};
		};
		sleep 0.5;
	};
};

////////////////////////////////////////////////
//玩家医治目标单位
////////////////////////////////////////////////
FAR_HandleRevive = 
{
	if (alive _this) then
	{
		FAR_revive_move = 1;
		FAR_CancelRevive = false;
		_time_revive1 = time + 1.5;
		if(currentWeapon player != primaryWeapon player || {currentWeapon player == ""})then{player switchMove "AmovPknlMstpSrasWrflDnon"};
		player playMove "AinvPknlMstpSlayWrflDnon_medic"; //AinvPknlMstpSnonWnonDr_medic1 空手治疗动作
		_this setVariable ["FAR_Revive_actDisable", 1, true];//隐藏其他玩家医治菜单
		inGameUISetEventHandler ["Action", "true"];//玩家禁用滚轮菜单
		waitUntil {animationState player in ["ainvpknlmstpslaywrfldnon_medic","ainjppnemstpsnonwrfldnon"] || {time > _time_revive1}};
		
		TitleText ["按X键可以取消医治", "Plain Down"];
		CancelRevive_X_Key = (findDisplay 46) displayAddEventHandler ["KeyDown", {if((_this select 1) == 45)then {FAR_CancelRevive = true}}];
		
		_time_revive2 = time + 6.3;//6.3 sec time-out
        waitUntil {animationState player != "AinvPknlMstpSlayWrflDnon_medic" || {_this getVariable "FAR_isUnconscious" == 0} || {_this getVariable "FAR_isDragged" == 1} || {_this getVariable "FAR_isCarry" == 1} || {vehicle _this != _this} || {!alive _this} || {!alive player} || {player distance _this > 2} || {FAR_CancelRevive} || {time > _time_revive2}};
		
		_isDownMove = animationState player == "ainjppnemstpsnonwrfldnon";
		if (_isDownMove || {_this getVariable "FAR_isUnconscious" == 0} || {_this getVariable "FAR_isDragged" == 1} || {_this getVariable "FAR_isCarry" == 1} || {vehicle _this != _this} || {!alive _this} || {!alive player} || {player distance _this > 2} || {FAR_CancelRevive} || {animationState player == "unconscious"}) exitWith 
		{
		    _this setVariable ["FAR_Revive_actDisable", 0, true];
			if (!_isDownMove || {!isMultiplayer}) then {inGameUISetEventHandler ["Action", "false"]};
			if (alive player && {animationState player != "unconscious"}) then {[player, "switchMove", "amovpknlmstpsraswrfldnon"] call FAR_remote_move};
			(findDisplay 46) displayRemoveEventHandler ["KeyDown", CancelRevive_X_Key];
			CancelRevive_X_Key = nil;
			FAR_CancelRevive = nil;
			FAR_revive_move = nil;
		};//中断医治
		
		_this setVariable ["FAR_isUnconscious", 0, true];
		_this setVariable ["FAR_isDragged", 0, true];
		_this setVariable ["FAR_isCarry", 0, true];//
		_this setVariable ["FAR_Only_one_EH", 0, true];//
		_this setVariable ["FAR_Revive_actDisable", 0, true];//
		
		//模式3没有医疗包要删除一个急救包
		if ( (FAR_ReviveMode == 3) && {!("Medikit" in (items player))} ) then {
			player removeItem "FirstAidKit";
		};
		
		// 单机救治AI或多人游戏玩家断线后曾经附体过还活着的AI
		if (!isPlayer _this || {!isMultiplayer}) then
		{
		    if (isMultiplayer) then
			[{
				FAR_remote_EH = [_this, nil, "ReviveAI", nil];
				publicVariable "FAR_remote_EH";

			},{
			    [nil, [_this, nil, "ReviveAI", nil]] call FAR_remote_exec;
			}];
		};
		
		inGameUISetEventHandler ["Action", "false"];
		
		//水下或空手救人卡动作 debug
		if (animationState player == "ainvpknlmstpslaywrfldnon_medic" || {time > _time_revive2}) then 
		{
			player switchMove "amovpknlmstpsraswrfldnon";
		};
		
		(findDisplay 46) displayRemoveEventHandler ["KeyDown", CancelRevive_X_Key];
		CancelRevive_X_Key = nil;
		FAR_CancelRevive = nil;
		FAR_revive_move = nil;
	};
};

////////////////////////////////////////////////
// 止血
////////////////////////////////////////////////
FAR_HandleStabilize =
{
	if (alive _this) then
	{
		if(currentWeapon player != primaryWeapon player || {currentWeapon player == ""})then{player switchMove "AmovPknlMstpSrasWrflDnon"};
		player playMove "AinvPknlMstpSlayWrflDnon_medic";
		inGameUISetEventHandler ["Action", "true"];
		
		if (!("Medikit" in (items player)) ) then {
			player removeItem "FirstAidKit";
		};

		_this setVariable ["FAR_isStabilized", 1, true];
		
		sleep 6.3;
		if !(animationState player in ["ainjppnemstpsnonwrfldnon_rolltoback","ainjppnemstpsnonwrfldnon","ainjppnemstpsnonwrfldnon_rolltofront"]) then 
		{
		    inGameUISetEventHandler ["Action", "false"];
		};
		
		if (animationState player == "ainvpknlmstpslaywrfldnon_medic") then 
		{
			player switchMove "amovpknlmstpsraswrfldnon";
		};// surfaceIsWater (getPosATL player) || {currentWeapon player == ""} bug
	};
};

////////////////////////////////////////////////
// 拖动受伤的玩家
////////////////////////////////////////////////
FAR_DragMoves =	//步枪,手枪,空手 拖拉动作
{
    animationState _this in [
	"amovpercmstpslowwrfldnon_acinpknlmwlkslowwrfldb_2","acinpknlmstpsraswrfldnon","acinpknlmwlksraswrfldb",
	"amovpercmstpsraswpstdnon_acinpknlmwlksnonwpstdb_2","acinpknlmstpsnonwpstdnon","acinpknlmwlksnonwpstdb",
	"amovpercmstpsnonwnondnon_acinpknlmwlksnonwnondb_2","acinpknlmstpsnonwnondnon","acinpknlmwlksnonwnondb"]
};
FAR_DragWrongMoves = //错误动作
{
    animationState _this in [
	"helper_switchtocarryrfl","acinpknlmstpsraswrfldnon_acinpercmrunsraswrfldnon","acinpknlmstpsraswrfldnon_amovppnemstpsraswrfldnon","acinpercmrunsraswrfldnon","acinpercmrunsraswrfldf"]
};
FAR_DragProneMoves =
{
    animationState _this in [
	//步枪,手枪,望远镜,空手 翻滚动作
	"amovppnemstpsraswrfldnon_amovppnemevaslowwrfldl","amovppnemstpsraswrfldnon_amovppnemevaslowwrfldr",
	"amovppnemstpsraswpstdnon_amovppnemevaslowwpstdl","amovppnemstpsraswpstdnon_amovppnemevaslowwpstdr",
	"amovppnemstpsoptwbindnon_amovppnemevasoptwbindl","amovppnemstpsoptwbindnon_amovppnemevasoptwbindr",
	"amovppnemstpsnonwnondnon_amovppnemevasnonwnondl","amovppnemstpsnonwnondnon_amovppnemevasnonwnondr",
	//步枪侧躺1
	"amovppnemstpsraswrfldnon_aadjppnemstpsraswrfldleft","aadjppnemstpsraswrfldleft", "aadjppnemwlksraswrfldleft_l","aadjppnemwlksraswrfldleft_r","amovppnemstpsraswrfldnon_aadjppnemstpsraswrfldright","aadjppnemstpsraswrfldright", "aadjppnemwlksraswrfldright_l","aadjppnemwlksraswrfldright_r","aadjppnemwlksraswrfldleft_f","aadjppnemwlksraswrfldleft_b","aadjppnemwlksraswrfldright_f","aadjppnemwlksraswrfldright_b",
	//手枪侧躺1
	"amovppnemstpsraswpstdnon_aadjppnemstpsraswpstdleft","aadjppnemstpsraswpstdleft","aadjppnemwlksraswpstdleft_l","aadjppnemwlksraswpstdleft_r", "amovppnemstpsraswpstdnon_aadjppnemstpsraswpstdright","aadjppnemstpsraswpstdright", "aadjppnemwlksraswpstdright_l","aadjppnemwlksraswpstdright_r","aadjppnemwlksraswpstdleft_f","aadjppnemwlksraswpstdright_f","aadjppnemwlksraswpstdright_b",
	//步枪侧躺2
	"amovppnemstpsraswrfldnon_aadjppnemstpsraswrflddown","aadjppnemstpsraswrflddown", "aadjppnemstpsraswrflddown_turnl","aadjppnemstpsraswrflddown_turnr",
	//手枪侧躺2
	"amovppnemstpsraswpstdnon_aadjppnemstpsraswpstddown","aadjppnemstpsraswpstddown", "aadjppnemstpsraswpstddown_turnl","aadjppnemstpsraswpstddown_turnr"]
};
FAR_fn_MoveDone1 =
{
	private ["_unit", "_Move"];
	_unit = _this select 0;
	_Move = _this select 1;
    switch (_this select 2) do 
	{
	    case 0 :{_unit switchMove _Move};
		case 1 :{_unit playMoveNow _Move};
		case 2 :{_unit playAction _Move};
	};
	waitUntil {_unit call FAR_DragMoves};
	FAR_Drag_MoveDone = true;
};
FAR_fn_MoveDone2 =
{
	private ["_unit", "_Move1", "_Move2"];
	_unit = _this select 0;
	_Move1 = _this select 1;
	_Move2 = _this select 2;
	_unit switchMove _Move1;
	waitUntil {animationState _unit == _Move1};
    switch (_this select 3) do 
	{
		case 0 :{_unit playMoveNow _Move2};
		case 1 :{_unit playAction "grabDrag"};
	};
	waitUntil {animationState _unit == _Move2};
	FAR_Drag_MoveDone = true;
};
FAR_Drag_prone_keydown = {
	if ((_this select 1) in (actionKeys "moveForward" + actionKeys "moveFastForward") && {player == FAR_player}) exitWith {true};
	false
};

FAR_Drag =
{
	if (isNull _this || {!(_this isKindOf "man")}) exitWith {TitleText ["无法拖动！", "Plain Down"]};//
	
	private ["_id1", "_id2", "_id3", "_prone"];
	
	FAR_player = player;
	FAR_isDragging = true;
	FAR_Release_Move = true;

	_this setVariable ["FAR_isDragged", 1, true];
	_this setVariable ["FAR_stance", stance FAR_player, true];
	
	if (stance FAR_player == "PRONE") then 
	[{
	    _prone = true;
	    _this attachTo [FAR_player, [0, 1.6, 0.092]];
		FAR_Drag_keydown_event = (findDisplay 46) displayAddEventHandler ["KeyDown", "_this call FAR_Drag_prone_keydown"];//禁止向前移动
	},{
	    _prone = false;
	    _this attachTo [FAR_player, [0, 1, 0.08]];//[0, 1.1, 0.092]
		[_this, "switchMove", "AinjPpneMrunSnonWnonDb_still"] call FAR_remote_move;
	}];//
	
	// Rotation fix
	[_this, [180, "FAR_isDragged"]] call FAR_setDir;
	
	_id1 = FAR_player addAction ["<t color='#C90000'>放下</t>", {FAR_isDragging = false}, [], 96, true, true, "", "_target == player"];
	_id2 = FAR_player addAction ["<t color='#C90000'>搬进载具</t>", {(FAR_remote_EH select 0) spawn FAR_in_veh}, [], 96, false, true, "", "_target call FAR_Check_MoveIn"];
	_id3 = FAR_player addAction ["<t color='#C90000'>扛起</t>", {(FAR_remote_EH select 0) spawn FAR_Carry}, [], 96, false, true, "", "(_target == player) && (primaryWeapon FAR_player != '') && (getPosASL FAR_player select 2 > -0.4)"];
	
	hint "如果你无法移动请按C键，带有主武器时也可以按X键放下伤员。";
	
	// Wait until release action is used
	FAR_Drag_MoveDone = true;
	waitUntil
	{
		if (FAR_Drag_MoveDone && {!(FAR_player call FAR_DragMoves)} && {!_prone} && {stance FAR_player != "PRONE"} && {getPosASL FAR_player select 2 > -0.4}) then
		{
			FAR_Drag_MoveDone = false;
			FAR_player spawn
			{
			    if (primaryWeapon _this != "") then 
			    [{
				    if (currentWeapon _this == primaryWeapon _this) then 
				    [{
						[_this, "AcinPknlMstpSrasWrflDnon", 1] call FAR_fn_MoveDone1;
				    },{
				        _this selectWeapon (primaryWeapon _this);
						[_this, "amovpknlmstpsraswrfldnon", "AcinPknlMstpSrasWrflDnon", 0] call FAR_fn_MoveDone2;
				    }];
				},{
				    if (handGunWeapon _this != "") then 
				    [{
				        if (currentWeapon _this == handGunWeapon _this) then 
				        [{
							[_this, "grabDrag", 2] call FAR_fn_MoveDone1;
					    },{
					        _this selectWeapon (handGunWeapon _this);
							[_this, "amovpknlmstpsraswpstdnon", "acinpknlmstpsnonwpstdnon", 1] call FAR_fn_MoveDone2;
					    }];
				    },{
				        _this action ["hideWeapon", _this ,_this ,2];
						[_this, "amovpknlmstpsnonwnondnon", "acinpknlmstpsnonwnondnon", 1] call FAR_fn_MoveDone2;
				    }];
				}];
			};
		};

		!alive FAR_player || {FAR_player getVariable "FAR_isUnconscious" == 1} || {!alive _this} || {_this getVariable "FAR_isUnconscious" == 0} || {!FAR_isDragging} || {_this getVariable "FAR_isDragged" == 0} || {_this getVariable "FAR_isCarry" == 1} || {vehicle _this != _this} || {vehicle FAR_player != FAR_player} || {_prone && {stance FAR_player != "PRONE"}} || {FAR_player call FAR_DragWrongMoves} || {FAR_player call FAR_DragProneMoves}
	};
	
	// Handle release action
	FAR_isDragging = false;

	detach _this;
	
	if (vehicle FAR_player == FAR_player && {FAR_player getVariable "FAR_isUnconscious" == 0} && {stance FAR_player != "PRONE"} && {alive FAR_player}) then 
	{
	    _pdownMove = if(primaryWeapon FAR_player != "")then[{if(FAR_Release_Move)then[{"amovpknlmstpsraswrfldnon"},{"amovpercmstpsraswrfldnon"}]},{if(handGunWeapon FAR_player != "")then[{if(FAR_Release_Move)then[{"amovpknlmstpsraswpstdnon"},{"amovpercmstpsraswpstdnon"}]},{FAR_player action ["hideWeapon", FAR_player ,FAR_player ,2];if(FAR_Release_Move)then[{"amovpknlmstpsnonwnondnon"},{"amovpercmstpsnonwnondnon"}]}]}];
		if(FAR_player call FAR_DragWrongMoves || {_this getVariable "FAR_isCarry" == 1})then[{sleep 0.5;FAR_player switchMove _pdownMove},{FAR_player playMove _pdownMove}];
	};
	
	FAR_player removeAction _id1;
	FAR_player removeAction _id2;
	FAR_player removeAction _id3;
	
	if(!isNil {FAR_Drag_keydown_event})then{(findDisplay 46) displayRemoveEventHandler ["KeyDown", FAR_Drag_keydown_event];FAR_Drag_keydown_event = nil;};
	
	if (!isNull _this && {alive _this}) then
	{
		if(_this getVariable "FAR_isCarry" == 0)then{[_this, "switchMove", "ainjppnemstpsnonwrfldnon"] call FAR_remote_move};
		_this setVariable ["FAR_isDragged", 0, true];
	};
};

////////////////////////////////////////////////
// 扛起受伤的玩家
////////////////////////////////////////////////
FAR_carring_moves =
{
    animationState _this in ["acinpercmstpsraswrfldnon","acinpercmrunsraswrfldf","acinpercmrunsraswrfldfr","acinpercmrunsraswrfldfl","acinpercmrunsraswrfldl","acinpercmrunsraswrfldr","acinpercmrunsraswrfldb","acinpercmrunsraswrfldbr","acinpercmrunsraswrfldbl"]
};

FAR_Carry = 
{
	if (isNull _this || {!(_this isKindOf "man")}) exitWith {};
	
	private ["_id1", "_id2"];

	FAR_player = player;
	FAR_isCarry = true;
	FAR_Release_Move = true;
	_this setVariable ["FAR_isCarry", 1, true];
	//[_this, "switchMove", "AinjPpneMstpSnonWrflDnon_injuredHealed"] call FAR_remote_move;
	_t1 = time + 5;
	waitUntil {/*animationState _this == "AinjPpneMstpSnonWrflDnon_injuredHealed" && */_this getVariable "FAR_isDragged" == 0 || {!alive _this} || {time > _t1}};
	if (stance FAR_player == "PRONE") then {FAR_player playMoveNow "amovpknlmstpsraswrfldnon"; waitUntil {animationState FAR_player == "amovpknlmstpsraswrfldnon" || {!alive _this} || {time > _t1}}};
	if(!alive _this)exitWith{FAR_isCarry = false};
	//sleep 0.1;
	//_this switchMove "ainjpfalmstpsnonwnondnon_carried_up";
	[_this, "switchMove", "ainjpfalmstpsnonwnondnon_carried_up"] call FAR_remote_move;
	_this attachTo [FAR_player,[0.05, 1.1, 0]];
	detach _this;
	//_this setPos [getPos _this select 0,getPos _this select 1,0.01];
	[_this, [(getDir FAR_player + 180), "FAR_isCarry"]] call FAR_setDir;
	if(currentWeapon FAR_player != primaryWeapon FAR_player)then{FAR_player selectWeapon (primaryWeapon FAR_player);FAR_player switchMove "amovpercmstpslowwrfldnon"};
	FAR_player playMoveNow "AcinPknlMstpSrasWrflDnon_AcinPercMrunSrasWrflDnon";
	
	//等待伤员完成动作
	_t3 = time + 14;//动作过渡时间 *13
	while {time < _t3 && {alive _this} && {alive FAR_player} && {vehicle FAR_player == FAR_player} && {FAR_player getVariable "FAR_isUnconscious" == 0}} do {sleep 0.01};
	if(!alive _this)exitWith{FAR_player switchMove "amovpercmstpsraswrfldnon"; FAR_isCarry = false};
	//FAR_player playMove "manPosCarrying";
	sleep 0.1;
	[_this, "switchMove", "ainjpfalmstpsnonwnondnon_carried_still"] call FAR_remote_move;
	sleep 0.1;
	_this attachTo [FAR_player,[-0.26, 0.1, 0.1]];//[-0.15, 0.1, 0.1]
	
	//等待玩家完成动作
	_t4 = time + 2;//debug
	waitUntil {animationState FAR_player == "acinpercmstpsraswrfldnon" || {!alive _this} || {!alive FAR_player} || {FAR_player getVariable "FAR_isUnconscious" == 1} || {vehicle FAR_player != FAR_player} || {time > _t4}};
    
	_id1 = FAR_player addAction ["<t color='#C90000'>放下</t>", {FAR_isCarry = false}, [], 96, true, true, "", "_target == player"];
	_id2 = FAR_player addAction ["<t color='#C90000'>搬进载具</t>", {(FAR_remote_EH select 0) spawn FAR_in_veh}, [], 96, false, true, "", "_target call FAR_Check_MoveIn"];
	
    //等待放下
    while {FAR_isCarry && {alive FAR_player} && {FAR_player getVariable "FAR_isUnconscious" == 0} && {alive _this} && {_this getVariable "FAR_isUnconscious" == 1} && {_this getVariable "FAR_isCarry" == 1} && {vehicle _this == _this} && {vehicle FAR_player == FAR_player} && {FAR_player call FAR_carring_moves}} do {sleep 0.5};
	
	FAR_isCarry = false;
	
	if (vehicle FAR_player == FAR_player && {FAR_player getVariable "FAR_isUnconscious" == 0} && {stance FAR_player != "PRONE"} && {alive FAR_player} && {getPosASL FAR_player select 2 > -0.4}) then 
	{
	    FAR_player playMove (if(FAR_Release_Move)then[{"amovpknlmstpsraswrfldnon"},{"amovpercmstpsraswrfldnon"}]);
	};
	
	FAR_player removeAction _id1;
	FAR_player removeAction _id2;
	
	if (!isNull _this) then
	{
		if(!alive _this)exitWith{detach _this};
		_this attachTo [FAR_player,[0.1, 0.1, 0]];//
		detach _this;
		if (alive FAR_player && {FAR_player getVariable "FAR_isUnconscious" == 0} && {FAR_player call FAR_carring_moves}) then
		[{
			[_this, "playMoveNow", "ainjpfalmstpsnonwnondnon_carried_down"] call FAR_remote_move;
			sleep 5;
			if(FAR_Release_Move)then{[_this, "switchMove", "ainjppnemstpsnonwrfldnon"] call FAR_remote_move};
		},{
			[_this, "switchMove", "ainjppnemstpsnonwrfldnon"] call FAR_remote_move;
		}];
		if (alive _this) then {_this setVariable ["FAR_isCarry", 0, true]};
	};
};

////////////////////////////////////////////////
// 把伤员搬进载具
////////////////////////////////////////////////
FAR_in_veh = 
{
	FAR_Release_Move = false;
	FAR_isDragging = false;
	FAR_isCarry = false;
	_veh = FAR_emptyPos_veh select 0;
	sleep 2;
	if (_this getVariable "FAR_isCarry" == 1) then {sleep 3};
	if (FAR_player getVariable "FAR_isUnconscious" == 1 || {isNull _this} || {!alive _this}) exitWith {};
	FAR_inveh_EH = [_this, _veh];
	publicVariable "FAR_inveh_EH";
	["FAR_inveh_EH", [_this, _veh]] call FAR_public_EH;
};

////////////////////////////////////////////////
// PV公布变量事件处理
////////////////////////////////////////////////
FAR_public_EH =
{
	if(count _this < 2) exitWith {};
	
	_EH  = _this select 0;
	_target = _this select 1;
	
	// FAR_deathMessage
	if (_EH == "FAR_deathMessage") then
	{
		_killed = _target select 0;
		_killer = _target select 1;
		_side = _target select 2;

		if (isPlayer _killer && {isPlayer _killed} && {_killed != _killer}) then
		[{
			_emyend = if((_side getFriend side _killer >= 0.6)&&{side _killer getFriend _side >= 0.6}) then[{" (友军误伤)"},{""}];
			systemChat format["%1 被 %2 打倒%3", name _killed, name _killer, _emyend];
		},{
			systemChat format["%1 倒下", name _killed];
		}];
	};
	
	// 单位标记
	if (_EH == "FAR_Damage_make") then
	{
	   _target spawn
	  {
		_unit = _this select 0;
		_makeName = _this select 1;
		_makeExist = false;
		{if(_makeName in _x)then{_makeExist = true}} forEach FAR__units;
		if (_makeExist) exitWith {};
		//deleteMarkerLocal _makeName;
		_make = createMarkerLocal [_makeName, getPosATL _unit];
		_makeName setMarkerTypeLocal "hd_dot";//"mil_dot"
		_makeName setMarkerTextLocal (name _unit) + " 倒下";
		_makeName setMarkerColorLocal "ColorRed";
		FAR__units set [count FAR__units, _this];
	  };
	};
	
	// 无意识单位进入载具
	if (_EH == "FAR_inveh_EH") then
	{
		_unit = _target select 0;
		if (local _unit) then 
		{
		    _veh = _target select 1;
			_unit moveInCargo _veh;
			//_unit moveInTurret [_veh, [0]];//副驾&炮手
		};
		// AI离开组(防止被命令下车)
		if (!isPlayer _unit) then 
		{
			//_unit playMoveNow "AinjPpneMstpSnonWrflDnon_injuredHealed";
			_unit setVariable ["FAR_AI_group", [1, group _unit]];
			[_unit] joinSilent createGroup side _unit;
		};
		// 无意识单位在载具的动作
		if (isMultiplayer) then 
		{
			_unit spawn 
			{
			   _t2 = time+8;
			   waitUntil {vehicle _this != _this || {!alive _this} || {_this getVariable "FAR_isUnconscious" == 0}/* || {_this getVariable "FAR_isDragged" == 1} || {_this getVariable "FAR_isCarry" == 1}*/ || {time > _t2}};
			   
			   if (vehicle _this == _this || {!alive _this} || {_this getVariable "FAR_isUnconscious" == 0}/* || {_this getVariable "FAR_isDragged" == 1} || {_this getVariable "FAR_isCarry" == 1}*/ || {time > _t2}) exitWith {};
			   
			   _this playMoveNow "ainjppnemstpsnonwrfldnon_rolltoback";
			};
		};
	};
};

//远程执行
FAR_remote_exec = 
{
	private ["_array", "_unit",/* "_play",*/ "_command", "_parameter"];
	_array = _this select 1;
	_unit = _array select 0;
	//_play = _array select 1;
	_command = _array select 2;
	_parameter = _array select 3;
	
	if (_command == "switchMove") exitWith {
		_unit switchMove _parameter;
	};
	
	if (local _unit) then 
	{
		switch (_command) do
		{
			case "setDir":
			{
				_unit setDir (_parameter select 0);
				_unit setVariable [(_parameter select 1), 1];//延迟debug
			    _array spawn //拖拽&肩扛者死亡断线debug
			    {
				    _unit = _this select 0;
				    _play = _this select 1;
					_parameter = _this select 3 select 1;
				    waitUntil {_unit getVariable _parameter == 0 || {!alive _play}};
					sleep 2;
				    if (_unit getVariable _parameter == 0 || {alive _play}) exitWith {};
					if (!isNull _unit && {alive _unit}) then
					{
				        _unit switchMove "AinjPpneMstpSnonWrflDnon";
				        _unit setVariable [_parameter, 0, true];
				        detach _unit;
					};
			    };
			};
			
			case "ReviveAI":
			{
				if(_unit getVariable "FAR_isStabilized" == 1)then{_unit setVariable ["FAR_isStabilized", 0, true]};
				//_unit setVariable ["FAR_Only_one_EH", 0, false];
				_unit stop false;
				_unit enableAI "MOVE";
				_unit enableAI "TARGET";
				_unit enableAI "AUTOTARGET";
				_unit enableAI "ANIM";
				//_unit enableSimulation true;
				_unit allowDamage true;
				_unit setDamage 0;
				_unit setCaptive false;
				_unit playMove "amovppnemstpsraswrfldnon";
			};
			
			case "outveh": {_unit spawn FAR_out_veh;};// 搬出伤员
			
			//转换动作
			case "playMove": {_unit playMove _parameter;};
			case "playMoveNow": {_unit playMoveNow _parameter;};
			//case "switchMove": {_unit switchMove _parameter;};
		};
	};
};

// Set dir
FAR_setDir = {
	private ["_unit","_dir_vn"];
	_unit = _this select 0;
	_dir_vn = _this select 1;
	FAR_remote_EH = [_unit, FAR_player, "setDir", _dir_vn];
	publicVariable "FAR_remote_EH";
	[nil, FAR_remote_EH] spawn FAR_remote_exec;
};

// remote exec move
FAR_remote_move = {
	private ["_unit","_type","_move"];
	_unit = _this select 0;
	_type = _this select 1;
	_move = _this select 2;
	FAR_remote_EH = [_unit, nil, _type, _move];
	publicVariable "FAR_remote_EH";
	[nil, FAR_remote_EH] spawn FAR_remote_exec;
};


////////////////////////////////////////////动作菜单条件检查//////////////////////////////////////////////
// 搬进载具动作菜单检查
////////////////////////////////////////////////
FAR_Check_MoveIn = 
{
	_return = false;
	FAR_emptyPos_veh = [];
	
	if (stance player == "PRONE" || {_this != player}) exitWith
	{
		_return
	};
	
	{
	  if (alive _x && {_x emptyPositions "Cargo" > 0}) then
	  {
	    FAR_emptyPos_veh set [count FAR_emptyPos_veh, _x];
	  };
	} forEach nearestObjects[player,["car","Tank","Helicopter","Plane","ship","Motorcycle"],5];

	if (count FAR_emptyPos_veh > 0) then
	{
		_return = true;
	};

	_return
};

////////////////////////////////////////////////
// 搬出载具动作菜单检查
////////////////////////////////////////////////
FAR_Check_MoveOut = 
{
	private ["_target"];
	
	_return = false;
	_target = cursorTarget;
	
	if ( isNull _target || {!alive player} || {vehicle player != player} || {player getVariable "FAR_isUnconscious" == 1} || {FAR_isDragging} || {FAR_isCarry} || {(_target distance player) > 5} || {count crew _target == 0} || {stance player == "PRONE"} || {_this != player} ) exitWith
	{
		_return
	};
	
	if !( _target isKindOf "car" || {_target isKindOf "Tank"} || {_target isKindOf "Helicopter"} || {_target isKindOf "Plane"} || {_target isKindOf "ship"} || {_target isKindOf "Motorcycle"})  exitWith
	{
		_return
	};
	
	FAR_Unconscious_veh = [];
	{
	  if (_x getVariable ["FAR_isUnconscious", 0] == 1 && {alive _x}) then
	  {
	    FAR_Unconscious_veh set [count FAR_Unconscious_veh, _x];
	  };
	} forEach crew _target;
	
	if (count FAR_Unconscious_veh > 0) then
	{
		_return = true;
	};

	_return
};

////////////////////////////////////////////////
// 医治动作菜单检查
////////////////////////////////////////////////
FAR_Check_Revive = 
{
	private ["_target"];

	_return = false;
	_target = cursorTarget;
	_isMedic = getNumber (configfile >> "CfgVehicles" >> typeOf player >> "attendant");

	// Make sure player is alive and target is an injured unit
	if( isNull _target || {!alive player} || {player getVariable "FAR_isUnconscious" == 1} || {FAR_isDragging} || {FAR_isCarry} || {!alive _target} || {!isPlayer _target && {!FAR_Debugging}} || {(_target distance player) > 2} || {_this != player} ) exitWith
	{
		_return
	};
	
	// Make sure target is unconscious and player is a medic 
	if (_target getVariable "FAR_isUnconscious" == 1 && {_target getVariable "FAR_isDragged" == 0} && {_target getVariable "FAR_isCarry" == 0} && {_target getVariable "FAR_Revive_actDisable" == 0} && {_isMedic == 1 || {FAR_ReviveMode > 0}} ) then
	{
		_return = true;

		// [ReviveMode] Check if player has a Medikit
		if ( FAR_ReviveMode == 2 && {!("Medikit" in (items player))} ) then
		{
			_return = false;
		};
		
		// 玩家没有医疗包或急救包
		if ( FAR_ReviveMode == 3 && {!( ("FirstAidKit" in (items player)) || {"Medikit" in (items player)} )} ) then
		{
			_return = false;
		};
		
	};
	
	if( !alive player || {!alive _target} ) then
	{
		_return = false;
	};
	
	_return
};

////////////////////////////////////////////////
// 止血动作菜单检查
////////////////////////////////////////////////
FAR_Check_Stabilize = 
{
	private ["_target"];

	_return = false;
	_target = cursorTarget;
	_isMedic = getNumber (configfile >> "CfgVehicles" >> typeOf player >> "attendant");
	
	// Make sure player is alive and target is an injured unit
	if( isNull _target || {FAR_ReviveMode in [1,3]} || {FAR_BleedOut == 0} || {!alive player} || {player getVariable "FAR_isUnconscious" == 1} || {FAR_isDragging} || {FAR_isCarry} || {!alive _target} || {!isPlayer _target && {!FAR_Debugging}} || {(_target distance player) > 2} || {_isMedic == 1 && {FAR_ReviveMode == 0}} || {"Medikit" in (items player) && {FAR_ReviveMode == 2}} || {_this != player} ) exitWith
	{
		_return
	};
	
	// Make sure target is unconscious and hasn't been stabilized yet, and player has a FAK/Medikit 
	if (_target getVariable "FAR_isUnconscious" == 1 && {_target getVariable "FAR_isStabilized" == 0} && {_target getVariable "FAR_isDragged" == 0} && {_target getVariable "FAR_isCarry" == 0} && {_target getVariable "FAR_Revive_actDisable" == 0} && { ("FirstAidKit" in (items player)) || {"Medikit" in (items player)} } ) then
	{
		_return = true;
	};
	
	if( !alive player || {!alive _target} ) then
	{
		_return = false;
	};
	_return
};

////////////////////////////////////////////////
// 拖拽动作菜单检查
////////////////////////////////////////////////
FAR_Check_Dragging =
{
	private ["_target"];
	
	_return = false;
	_target = cursorTarget;

	if( isNull _target || {!alive player} || {player getVariable "FAR_isUnconscious" == 1} || {FAR_isDragging} || {FAR_isCarry} || {!alive _target} || {!isPlayer _target && {!FAR_Debugging}} || {(_target distance player) > 2} || {player call FAR_DragProneMoves} || {_this != player} ) exitWith
	{
		_return;
	};
	
	if(_target getVariable "FAR_isUnconscious" == 1 && {_target getVariable "FAR_isDragged" == 0} && {_target getVariable "FAR_isCarry" == 0} && {_target getVariable "FAR_Revive_actDisable" == 0}) then
	{
		_return = true;
	};
	
	if( !alive player || {!alive _target} ) then
	{
		_return = false;
	};	
	_return
};

////////////////////////////////////////////////
// 扛起动作菜单检查
////////////////////////////////////////////////
FAR_Check_Carry =
{
	private ["_target"];
	
	_return = false;
	_target = cursorTarget;

	if( isNull _target || {!alive player} || {player getVariable "FAR_isUnconscious" == 1} || {FAR_isDragging} || {FAR_isCarry} || {!alive _target} || {!isPlayer _target && {!FAR_Debugging}} || {(_target distance player) > 2} || {player call FAR_DragProneMoves} || {primaryWeapon player == ""} || {getPosASL player select 2 < -0.4} || {_this != player} ) exitWith
	{
		_return;
	};
	
	if(_target getVariable "FAR_isUnconscious" == 1 && {_target getVariable "FAR_isDragged" == 0} && {_target getVariable "FAR_isCarry" == 0} && {_target getVariable "FAR_Revive_actDisable" == 0}) then
	{
		_return = true;
	};
	
	if( !alive player || {!alive _target} ) then
	{
		_return = false;
	};	
	_return
};


/////////////////////////////////////////////////////////////////////////////////////////////////////
// 显示附近友军医护兵
////////////////////////////////////////////////
FAR_IsFriendlyMedic =
{
	_return = false;
	_unit = _this select 0;
	_side = _this select 1;
	
	if (alive _unit && {if(isMultiplayer)then[{isPlayer _unit},{_unit in (switchableUnits-[player])}]} && {(_side getFriend side _unit >= 0.6) && {side _unit getFriend _side >= 0.6}} && {_unit getVariable ["FAR_isUnconscious", 0] == 0} && {FAR_ReviveMode > 0 || {(getNumber (configfile >> "CfgVehicles" >> typeOf _unit >> "attendant")) == 1}}) then
	{
		_return = true;
	};
	_return
};

FAR_CheckFriendlies =
{
	private ["_unit", "_units", "_medics", "_hintMsg", "_play"];
	
	_play = if(player==vehicle player)then[{[player]},{[]}];
	_units = nearestObjects [player, ["Man", "LandVehicle", "Air", "Ship"], 500] - _play;
	_medics = [];
	_dist = 500;
	_hintMsg = "";
	
	// Find nearby friendly medics
	//if (count _units > 0) then
	//{
		{
			if (_x isKindOf "LandVehicle" || {_x isKindOf "Air"} || {_x isKindOf "Ship"}) then
			[{
				if (alive _x && {count (crew _x) > 0}) then
				{
					{
						if ([_x, _this] call FAR_IsFriendlyMedic) then
						{
							_medics set [count _medics, _x];
						};
					} forEach crew _x;
				};
			},{
				if ([_x, _this] call FAR_IsFriendlyMedic) then
				{
					_medics set [count _medics, _x];
				};
			}];
			
		} forEach _units;
	//};
	
	// Sort medics by distance
	if (count _medics > 0) then
	[{
		{
			if (player distance _x < _dist) then
			{
				_unit = _x;
				_dist = player distance _x;
			};
		
		} forEach _medics;
		
		if (!isNull _unit) then
		{
			_unitName	= name _unit;
			_distance	= floor (player distance _unit);
			
			_hintMsg = format["最近的医护兵:\n%1距离你%2m远.", _unitName, _distance];
		};
	},{
		_hintMsg = "沒有医护兵在附近.";
	}];
	
	_hintMsg
};



