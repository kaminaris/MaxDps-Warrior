-- Author      : Kaminari
-- Create Date : 13:03 2015-04-20

local _Bloodthirst = 23881;
local _WildStrike = 100130;
local _RagingBlow = 85288;
local _Execute = 5308;
local _BladeStorm = 46924;
local _StormBolt = 107570;
local _DragonRoar = 118000;
local _BerserkerRage = 18499;
local _Ravager = 152277;
local _Recklessness = 1719;

local _Revenge = 6572;
local _ShieldSlam = 23922;
local _Devastate = 20243;
local _HeroicStrike = 78;
local _ThunderClap = 6343;
local _Shockwave = 46968;

-- auras
local _Enrage = 12880;
local _Bloodsurge = 46916;
local _SuddenDeath = 29725;
local _RagingBlowAura = 131116;
local _SwordandBoard = 46953;
local _Ultimatum = 122510;
local _UnyieldingStrikes = 169685;

-- talents
local _isSuddenDeath = false;
local _isUnquenchableThirst = false;
local _isStormBolt = false;
local _isDragonRoar = false;
local _isUnquenchableThirst = false;
local _isRavager = false;
local _isUnyieldingStrikes = false;
local _isShockwave = false;
local _rageMax = 100;

--flags
local _RecklessnessHigh = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Warrior_CheckTalents = function()
	_isSuddenDeath = TD_TalentEnabled('Sudden Death');
	_isUnquenchableThirst = TD_TalentEnabled('Unquenchable Thirst');
	_isRavager = TD_TalentEnabled('Ravager');
	_isStormBolt = TD_TalentEnabled('Storm Bolt');
	_isDragonRoar = TD_TalentEnabled('Dragon Roar');
	_isUnyieldingStrikes = TD_TalentEnabled('Unyielding Strikes');
	_isShockwave = TD_TalentEnabled('Shockwave');

	_rageMax = UnitPowerMax('player', SPELL_POWER_RAGE);
end

----------------------------------------------
-- Enabling Addon
----------------------------------------------
function TDDps_Warrior_EnableAddon(mode)
	mode = mode or 1;
	_TD['DPS_Description'] = 'TD Warrior DPS supports: Fury, Protection';
	_TD['DPS_OnEnable'] = TDDps_Warrior_CheckTalents;
	if mode == 1 then
		_TD['DPS_NextSpell'] = TDDps_Warrior_Arms
	end;
	if mode == 2 then
		_TD['DPS_NextSpell'] = TDDps_Warrior_Fury
	end;
	if mode == 3 then
		_TD['DPS_NextSpell'] = TDDps_Warrior_Protection
	end;
	TDDps_EnableAddon();
end


----------------------------------------------
-- Main rotation: Arms
----------------------------------------------
TDDps_Warrior_Arms = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	return _Bloodthirst;
end

----------------------------------------------
-- Main rotation: Fury
----------------------------------------------
TDDps_Warrior_Fury = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	local berserRage = TD_SpellAvailable(_BerserkerRage, timeShift);
	local ravager = TD_SpellAvailable(_Ravager, timeShift);
	local sb = TD_SpellAvailable(_StormBolt, timeShift);
	local dr = TD_SpellAvailable(_DragonRoar, timeShift);
	local reck = TD_SpellAvailable(_Recklessness, timeShift);
	local enrage = TD_Aura(_Enrage, timeShift);
	local rb, rbCount = TD_Aura(_RagingBlowAura);
	local rage = UnitPower('player', SPELL_POWER_RAGE);
	local bs = TD_Aura(_Bloodsurge, timeShift);
	local sd = TD_Aura(_SuddenDeath, timeShift);

	local ph = TD_TargetPercentHealth();

	TDButton_GlowCooldown(_Recklessness, reck);

	if berserRage and not enrage then
		return _BerserkerRage;
	end

	if (rage / _rageMax) >= 0.9 and ph > 0.2 then
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
	local timeShift, currentSpell, gcd = TD_EndCast();

	local rage = UnitPower('player', SPELL_POWER_RAGE);
	local rageMax = UnitPowerMax('player', SPELL_POWER_RAGE);

	local dr = TD_SpellAvailable(_DragonRoar, timeShift);
	local revenge = TD_SpellAvailable(_Revenge, timeShift);
	local sb = TD_SpellAvailable(_StormBolt, timeShift);
	local ss = TD_SpellAvailable(_ShieldSlam, timeShift);
	local ravager = TD_SpellAvailable(_Ravager, timeShift);
	local tc = TD_SpellAvailable(_ThunderClap, timeShift);
	local bs = TD_SpellAvailable(_BladeStorm, timeShift);
	local sw = TD_SpellAvailable(_Shockwave, timeShift);

	local sab = TD_Aura(_SwordandBoard, timeShift);
	local sd = TD_Aura(_SuddenDeath, timeShift);
	local ulti = TD_Aura(_Ultimatum, timeShift);
	local _, usCharges = TD_Aura(_UnyieldingStrikes, timeShift);

	local ph = TD_TargetPercentHealth();

	TDButton_GlowCooldown(_Ravager, _isRavager and ravager);
	TDButton_GlowCooldown(_ThunderClap, tc);
	TDButton_GlowCooldown(_BladeStorm, bs);

	if _isDragonRoar and dr then
		return _DragonRoar;
	end

	if _isShockwave and sw then
		return _Shockwave;
	end

	if sab then
		return _ShieldSlam;
	end

	if revenge then
		return _Revenge;
	end

	if ss then
		return _ShieldSlam;
	end

	if sd or (rage >= 30 and ph < 0.2) then
		return _Execute;
	end

	if _isStormBolt and sb then
		return _StormBolt;
	end

	if (_isUnyieldingStrikes and usCharges >= 6) or rage >= rageMax - 10 or ulti then
		return _HeroicStrike;
	end

	return _Devastate;
end