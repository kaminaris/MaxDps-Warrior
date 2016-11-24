-- Author      : Kaminari
-- Create Date : 13:03 2015-04-20

-- Multispec
local _Charge = 100;
local _BattleCry = 1719;
local _Ravager = 152277;

-- Prot

local _ShieldSlam = 23922;
local _Devastate = 20243;
local _Revenge = 6572;
local _FocusedRage = 204488;
local _Vengeance = 202572;
local _IgnorePain = 190456;
local _Intercept = 198304;
local _ThunderClap = 6343;
local _ShieldBlock = 2565;
local _ShieldWall = 871;
local _LastStand = 12975;
local _DemoralizingShout = 1160;
local _SpellReflection = 23920;
local _NeltharionsFury = 203524;
local _Taunt = 355;
local _HeroicLeap = 6544;
local _BestServedCold = 202560;
local _BoomingVoice = 202743;
local _MasteryCriticalBlock = 76857;
local _Ultimatum = 122509;
local _Indomitable = 202095;
local _NeverSurrender = 202561;
local _Safeguard = 223657;
local _Avatar = 107574;
local _HeavyRepercussions = 203177;
local _RenewedFury = 202288;
local _IntotheFray = 202603;
local _AngerManagement = 152278;
local _ImpendingVictory = 202168;
local _MightoftheVrykul = 188778;
local _ReflectivePlating = 188672;
local _BerserkerRage = 18499;
local _Shockwave = 46968;
local _StormBolt = 107570;
local _Warbringer = 103828;
local _Bloodlust = 2825;

-- Fury
local _Rampage = 184367;
local _Enrage = 184361;
local _Bloodthirst = 23881;
local _OdynsFury = 205545;
local _Execute = 5308;
local _Whirlwind = 190411;
local _WreckingBall = 215569;
local _RagingBlow = 85288;
local _FuriousSlash = 100130;
local _DragonRoar = 118000;
local _Frenzy = 206313;
local _Massacre = 206315;
local _InnerRage = 215573;
local _Avatar = 107574;
local _Bloodbath = 12292;
local _MeatCleaver = 12950;
local _Bladestorm = 46924;
local _WarMachine = 215556;
local _EndlessRage = 202296;
local _BerserkerRage = 18499;
local _Outburst = 206320;
local _MasteryUnshackledFury = 76856;
local _HeroicLeap = 6544;
local _DoubleTime = 103827;
local _BoundingStride = 202163;
local _EnragedRegeneration = 184364;
local _CommandingShout = 97462;

-- Arms
local _ColossusSmash = 167105;
local _Warbreaker = 209577;
local _Overpower = 7384;
local _ExecuteArms = 163201;
local _ShatteredDefenses = 209574;
local _MortalStrike = 12294;
local _Slam = 1464;
local _Rend = 772;
local _FocusedRageArms = 207982;
local _FervorofBattle = 202316;
local _WhirlwindArms = 1680;
local _DeadlyCalm = 227266;
local _Avatar = 107574;
local _SweepingStrikes = 202161;
local _Cleave = 845;
local _BladestormArms = 227847;
local _BoundingStride = 202163;
local _HeroicLeap = 6544;
local _DefensiveStance = 197690;
local _Tactician = 184783;
local _MasteryColossalMight = 76838;
local _DoubleTime = 103827;
local _DiebytheSword = 118038;
local _CommandingShout = 97462;

-- talents
local _isSuddenDeath = false;
local _isFocusedRage = false;
local _isUnquenchableThirst = false;
local _isStormBolt = false;
local _isDragonRoar = false;
local _isUnquenchableThirst = false;
local _isRavager = false;
local _isUnyieldingStrikes = false;
local _isShockwave = false;
local _isOverpower = false;
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
	_isOverpower = TD_TalentEnabled('Overpower');
	_isFocusedRage = TD_TalentEnabled('Focused Rage');
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
	TDDps.Description = 'TD Warrior DPS supports: Fury, Arms, Protection';
	TDDps.ModuleOnEnable = TDDps_Warrior_CheckTalents;
	if mode == 1 then
		TDDps.NextSpell = TDDps_Warrior_Arms;
	end;
	if mode == 2 then
		TDDps.NextSpell = TDDps_Warrior_Fury;
	end;
	if mode == 3 then
		TDDps.NextSpell = TDDps_Warrior_Protection;
	end;
end


----------------------------------------------
-- Main rotation: Arms
----------------------------------------------
TDDps_Warrior_Arms = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	local rage = UnitPower('player', SPELL_POWER_RAGE);
	local rageMax = UnitPowerMax('player', SPELL_POWER_RAGE);

	local cs = TD_SpellAvailable(_ColossusSmash, timeShift);
	local wb = TD_SpellAvailable(_Warbreaker, timeShift);
	local op = TD_SpellAvailable(_Overpower, timeShift);
	local ms = TD_SpellAvailable(_MortalStrike, timeShift);

	local bc = TD_SpellAvailable(_BattleCry, timeShift);
	local bs = TD_SpellAvailable(_BladestormArms, timeShift);
	local fr = TD_SpellAvailable(_FocusedRageArms, timeShift);

	local csAura = TD_TargetAura(_ColossusSmash, timeShift);
	local sd = TD_Aura(_ShatteredDefenses, timeShift);
	local bcAura = TD_Aura(_BattleCry, timeShift);

	local ph = TD_TargetPercentHealth();

	TDButton_GlowCooldown(_BattleCry, bc);
	TDButton_GlowCooldown(_BladestormArms, bs);

	if cs and (not _isFocusedRage or not sd) then
		return _ColossusSmash;
	end

	if wb and not csAura and (not _isFocusedRage or not sd) then
		return _Warbreaker;
	end

	if not _isFocusedRage and _isOverpower and op and rage >= 10 then
		return _Overpower;
	end

	if ph < 0.2 and ((sd and not _isFocusedRage) or _isFocusedRage) then
		return _ExecuteArms;
	end

	if _isFocusedRage and fr and (csAura or bcAura) then
		return _FocusedRage;
	end

	if ms then
		return _MortalStrike;
	end

	if _isFocusedRage then
		if rage > 32 and not ms and not cs then
			return _Slam;
		end

		if rage > rageMax - 25 then
			return _FocusedRageArms;
		end

		return nil;
	else
		return _Slam;
	end
end

----------------------------------------------
-- Main rotation: Fury
----------------------------------------------
TDDps_Warrior_Fury = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	local rage = UnitPower('player', SPELL_POWER_RAGE);
	local rageMax = UnitPowerMax('player', SPELL_POWER_RAGE);

	local bt = TD_SpellAvailable(_Bloodthirst, timeShift);
	local of = TD_SpellAvailable(_OdynsFury, timeShift);
	local rb = TD_SpellAvailable(_RagingBlow, timeShift + 0.3);

	local berserRage = TD_SpellAvailable(_BerserkerRage, timeShift);
	local dr = TD_SpellAvailable(_DragonRoar, timeShift);
	local bc = TD_SpellAvailable(_BattleCry, timeShift);
	local sb = TD_SpellAvailable(_StormBolt, timeShift);
	local ava = TD_SpellAvailable(_Avatar, timeShift);
	local bb = TD_SpellAvailable(_Bloodbath, timeShift);

	local enrage = TD_Aura(_Enrage, timeShift);
	local wb = TD_Aura(_WreckingBall, timeShift);


	local ph = TD_TargetPercentHealth();

	TDButton_GlowCooldown(_DragonRoar, dr);
	TDButton_GlowCooldown(_BattleCry, bc);
	TDButton_GlowCooldown(_Avatar, ava);
	TDButton_GlowCooldown(_Bloodbath, bb);
	TDButton_GlowCooldown(_BerserkerRage, berserRage);

	if rage == rageMax and not enrage then
		return _Rampage;
	end

	if bt and not enrage then
		return _Bloodthirst;
	end

	if of then
		return _OdynsFury;
	end

	if _isStormBolt and sb then
		return _StormBolt;
	end

	if rage >= 25 and ph < 0.2 and enrage then
		return _Execute;
	end

	if wb then
		return _Whirlwind;
	end

	if rb then
		return _RagingBlow;
	end

	if bt then
		return _Bloodthirst;
	end

	return _FuriousSlash;
end


----------------------------------------------
-- Main rotation: Protection
----------------------------------------------
TDDps_Warrior_Protection = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	local rage = UnitPower('player', SPELL_POWER_RAGE);
	local rageMax = UnitPowerMax('player', SPELL_POWER_RAGE);

	local revenge = TD_SpellAvailable(_Revenge, timeShift);
	local sb = TD_SpellAvailable(_StormBolt, timeShift);
	local ss = TD_SpellAvailable(_ShieldSlam, timeShift);
	local ravager = TD_SpellAvailable(_Ravager, timeShift);
	local tc = TD_SpellAvailable(_ThunderClap, timeShift);
	local sw = TD_SpellAvailable(_Shockwave, timeShift);

	local ulti = TD_Aura(_Ultimatum, timeShift);

	local ph = TD_TargetPercentHealth();

	TDButton_GlowCooldown(_Ravager, _isRavager and ravager);
	TDButton_GlowCooldown(_ThunderClap, tc);

	if ss then
		return _ShieldSlam;
	end

	if revenge then
		return _Revenge;
	end

	if _isStormBolt and sb then
		return _StormBolt;
	end

	return _Devastate;
end