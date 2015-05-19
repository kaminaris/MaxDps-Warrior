-- Author      : Kaminari
-- Create Date : 13:03 2015-04-20

local _Bloodthirst		= 23881;
local _WildStrike		= 100130;
local _RagingBlow		= 85288;
local _Execute			= 5308;
local _BladeStorm		= 46924;
local _StormBolt		= 107570;
local _DragonRoar		= 118000;
local _BerserkerRage	= 18499;
local _Ravager			= 152277;
local _Recklessness		= 1719;

-- auras
local _Enrage			= 12880;
local _Bloodsurge		= 46916
local _SuddenDeath		= 29725
local _RagingBlowAura	= 131116

-- talents
local _isSuddenDeath = false;
local _isUnquenchableThirst = false;
local _isStormBolt = false;
local _isDragonRoar = false;
local _isUnquenchableThirst = false;
local _isRavager = false;
local _rageMax = 100;

--flags
local _RecklessnessHigh = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Warrior_CheckTalents = function()
	_isSuddenDeath = TD_TalentEnabled("Sudden Death");
	_isUnquenchableThirst = TD_TalentEnabled("Unquenchable Thirst");
	_isRavager = TD_TalentEnabled("Ravager");
	_isStormBolt = TD_TalentEnabled("Storm Bolt");
	_isDragonRoar = TD_TalentEnabled("Dragon Roar");

	_rageMax = UnitPowerMax('player', SPELL_POWER_RAGE);
end

----------------------------------------------
-- Enabling Addon
----------------------------------------------
function TDDps_Warrior_EnableAddon(mode)
	mode = mode or 1;
	_TD["DPS_Description"] = "TD Warrior DPS supports: Fury";
	_TD["DPS_OnEnable"] = TDDps_Warrior_CheckTalents;
	if mode == 1 then
		_TD["DPS_NextSpell"] = TDDps_Warrior_Arms
	end;
	if mode == 2 then
		_TD["DPS_NextSpell"] = TDDps_Warrior_Fury
	end;
	if mode == 3 then
		_TD["DPS_NextSpell"] = TDDps_Warrior_Protection
	end;
	TDDps_EnableAddon();
end


----------------------------------------------
-- Main rotation: Arms
----------------------------------------------
TDDps_Warrior_Arms = function()

	local lcd, currentSpell, gcd = TDEndCast();
	local timeShift = lcd + gcd;

	return _Bloodthirst;
end

----------------------------------------------
-- Main rotation: Fury
----------------------------------------------
TDDps_Warrior_Fury = function()

	local lcd, currentSpell, gcd = TD_EndCast();
	local timeShift = lcd + gcd;

	local berserRage = TD_SpellAvailable(_BerserkerRage, timeShift);
	local ravager = TD_SpellAvailable(_Ravager, timeShift);
	local sb = TD_SpellAvailable(_StormBolt, timeShift);
	local dr = TD_SpellAvailable(_DragonRoar, timeShift);
	local reck = TD_SpellAvailable(_Recklessness, timeShift);
	local enrage = TD_Aura(_Enrage);
	local rb, rbCount = TD_Aura(_RagingBlowAura);
	local rage = UnitPower('player', SPELL_POWER_RAGE);
	local bs = TD_Aura(_Bloodsurge);
	local sd = TD_Aura(_SuddenDeath);

	local ph = TD_TargetPercentHealth();

	if reck and not _RecklessnessHigh then
		TDButton_GlowIndependent(_Recklessness, 'reck', 0, 1, 0);
		_RecklessnessHigh = true;
	end
	if _RecklessnessHigh and not reck then
		TDButton_ClearGlowIndependent(_Recklessness, 'reck');
		_RecklessnessHigh = false;
	end

	if berserRage and not enrage then
		return _BerserkerRage;
	end

	if (rage/_rageMax) >= 0.9 and ph > 0.2 then
		return _WildStrike;
	end

	if sd then
		return _Execute;
	end

	if rbCount >= 2 and ph > 0.2 then
		return _RagingBlow;
	end

	if not enrage and (_isUnquenchableThirst or rage < 80) then
		return _Bloodthirst;
	end

	if _isRavager and ravager then
		return _Ravager;
	end

	if _isStormBolt and sb then
		return _StormBolt;
	end

	if _isDragonRoar and dr then
		return _DragonRoar;
	end

	if rage >= 30 and ph < 0.2 and enrage then
		return _Execute;
	end

	if bs then
		return _WildStrike;
	end

	if rbCount > 0 then
		return _RagingBlow;
	end

	if rage >= 45 and ph > 0.2 and enrage then
		return _WildStrike;
	end

	return _Bloodthirst;
end


----------------------------------------------
-- Main rotation: Protection
----------------------------------------------
TDDps_Warrior_Protection = function()

	local lcd, currentSpell, gcd = TDEndCast();
	local timeShift = lcd + gcd;

	return _Bloodthirst;
end