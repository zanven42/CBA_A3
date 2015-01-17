#include "\x\cba\addons\keybinding\script_component.hpp"

disableSerialization;

_display = uiNamespace getVariable "RscDisplayConfigure";

// Get listnbox
_lnb = _display displayCtrl 202;
// Get currently selected index
_lnbIndex = lnbCurSelRow _lnb;
// Get combobox
_combo = _display displayCtrl 208;
// Get the mod selected in the comobo
_comboMod = _combo lbText (lbCurSel _combo);

// Don't allow multiple keys to be changed at once.
if (GVAR(waitingForInput)) exitWith {};

// Get handler tracker index array for keys stored in listbox data string
_handlerIndexArray = call compile (_lnb lnbData [_lnbIndex, 0]);

// Clear keypress data.
GVAR(input) = [];

GVAR(modifiers) = [];

// Mark that we're waiting so that onKeyDown handler blocks input (Esc key)
GVAR(waitingForInput) = true;

// Update box content to indicate that we're waiting for input.
_lnb lnbSetText [[_lnbIndex, 1], "Press key or Esc to cancel"];
_lnb lnbSetColor [[_lnbIndex, 1], [0,1,0,1]];

// Wait for input, selection, or mod change.
_fnc = {
    _data = _this select 0;
    _handlerIndexArray = _data select 0;
    _lnb = _data select 1;
    _lnbIndex = _data select 2;
    _comboMod = _data select 3;
    _combo = _data select 4;
    _display = _data select 5;

    if(count GVAR(input) > 0 || !GVAR(waitingForInput) || lnbCurSelRow _lnb != _lnbIndex || _comboMod != (_combo lbText (lbCurSel _combo))) then {
        [(_this select 1)] call cba_fnc_removePerFrameHandler;
        if (GVAR(waitingForInput)) then {
            // Tell the onKeyDown handler that we're not waiting anymore, so it stops blocking input.
            GVAR(waitingForInput) = false;

            if (!isNull _display) then { // Make sure user hasn't exited dialog before continuing.
                // Get stored keypress data.
                _keyPressData = GVAR(input);

                // If a valid key other than Escape was pressed,
                if (_keyPressData select 0 != 1) then {
                    {
                        // Get entry from handler tracker array
                        _keyConfig = GVAR(handlers) select _x;

                        _modName = _keyConfig select 0;
                        _actionName = _keyConfig select 1;
                        _oldKeyData = _keyConfig select 2;
                        _functionName = _keyConfig select 3;
                        //_oldEhID = _keyConfig select 4;
                        _keypressType = _keyConfig select 5;

                        // Re-register and overwrite old bind.
                        [_modName, _actionName, _functionName, _keyPressData, true, _keypressType] call cba_fnc_registerKeybind;

                    } forEach _handlerIndexArray;
                };

                // Update the main dialog.
                [] call FUNC(updateGUI);
            };
        };
    };
};
[_fnc, 0, [_handlerIndexArray, _lnb, _lnbIndex, _comboMod, _combo, _display]] call cba_fnc_addPerFrameHandler;