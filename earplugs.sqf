// put earplugs on all players in applicable vehicles
// by |TG189| Unkl for TacticalGamer.com
_run = true;
_listOfVehicleTypes = ["air","support","armoured","ship","submarine","car","autonomous"];
_earplugs = false;
_playerInVehicle = false;

while {_run} do
{
	if !(_earplugs) then
	{
		{
			if ((typeOf (vehicle player)) isKindOf _x) then
			{
				_playerInVehicle = true;
			};
		} forEach _listOfVehicleTypes;
		if (_playerInVehicle) then
		{
			1 fadeSound .35;
			hintSilent "Ohrenstöpsel Rein...";
			_earplugs = true;
		};
	} else {
		_playerInVehicle = false;
		{
			if ((typeOf (vehicle player)) isKindOf _x) then
			{
				_playerInVehicle = true;
			}
		} forEach _listOfVehicleTypes;
		if !(_playerInVehicle) then
		{
			1 fadeSound 1;
			hintSilent "Ohrenstöpsel Raus...";
			_earplugs = false;
		};
	};
	
	
	sleep 2;
	if (stopEarplugs != "false") then {_run = false;};
};