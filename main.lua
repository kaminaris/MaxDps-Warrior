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

MaxDps.Warrior = {};

function MaxDps.Warrior.CheckTalents()
	_isSuddenDeath = MaxDps:TalentEnabled('Sudden Death');
	_isUnquenchableThirst = MaxDps:TalentEnabled('Unquenchable Thirst');
	_isRavager = MaxDps:TalentEnabled('Ravager');
	_isStormBolt = MaxDps:TalentEnabled('Storm Bolt');
	_isOverpower = MaxDps:TalentEnabled('Overpower');
	_isFocusedRage = MaxDps:TalentEnabled('Focused Rage');
	_isDragonRoar = MaxDps:TalentEnabled('Dragon Roar');
	_isUnyieldingStrikes = MaxDps:TalentEnabled('Unyielding Strikes');
	_isShockwave = MaxDps:TalentEnabled('Shockwave');

	_rageMax = UnitPowerMax('player', SPELL_POWER_RAGE);
end

function MaxDps:EnableRotationModule(mode)
	mode = mode or 1;
	MaxDps.Description = 'Warrior Module [Fury, Arms, Protection]';
	MaxDps.ModuleOnEnable = MaxDps.Warrior.CheckTalents;
	if mode == 1 then
		MaxDps.NextSpell = MaxDps.Warrior.Arms;
	end;
	if mode == 2 then
		MaxDps.NextSpell = MaxDps.Warrior.Fury;
	end;
	if mode == 3 then
		MaxDps.NextSpell = MaxDps.Warrior.Protection;
	end;
end

function MaxDps.Warrior.Arms()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local rage = UnitPower('player', SPELL_POWER_RAGE);
	local rageMax = UnitPowerMax('player', SPELL_POWER_RAGE);

	local cs = MaxDps:SpellAvailable(_ColossusSmash, timeShift);
	local wb = MaxDps:SpellAvailable(_Warbreaker, timeShift);
	local op = MaxDps:SpellAvailable(_Overpower, timeShift);
	local ms = MaxDps:SpellAvailable(_MortalStrike, timeShift);

	local bc = MaxDps:SpellAvailable(_BattleCry, timeShift);
	local bs = MaxDps:SpellAvailable(_BladestormArms, timeShift);
	local fr = MaxDps:SpellAvailable(_FocusedRageArms, timeShift);

	local csAura = MaxDps:TargetAura(_ColossusSmash, timeShift);
	local sd = MaxDps:Aura(_ShatteredDefenses, timeShift);
	local bcAura = MaxDps:Aura(_BattleCry, timeShift);

	local ph = MaxDps:TargetPercentHealth();

	MaxDps:GlowCooldown(_BattleCry, bc);
	MaxDps:GlowCooldown(_BladestormArms, bs);

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

function MaxDps.Warrior.Fury()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local rage = UnitPower('player', SPELL_POWER_RAGE);
	local rageMax = UnitPowerMax('player', SPELL_POWER_RAGE);

	local bt = MaxDps:SpellAvailable(_Bloodthirst, timeShift);
	local of = MaxDps:SpellAvailable(_OdynsFury, timeShift);
	local rb = MaxDps:SpellAvailable(_RagingBlow, timeShift + 0.3);

	local berserRage = MaxDps:SpellAvailable(_BerserkerRage, timeShift);
	local dr = MaxDps:SpellAvailable(_DragonRoar, timeShift);
	local bc = MaxDps:SpellAvailable(_BattleCry, timeShift);
	local sb = MaxDps:SpellAvailable(_StormBolt, timeShift);
	local ava = MaxDps:SpellAvailable(_Avatar, timeShift);
	local bb = MaxDps:SpellAvailable(_Bloodbath, timeShift);

	local enrage = MaxDps:Aura(_Enrage, timeShift);
	local wb = MaxDps:Aura(_WreckingBall, timeShift);

	local ph = MaxDps:TargetPercentHealth();

	MaxDps:GlowCooldown(_DragonRoar, dr);
	MaxDps:GlowCooldown(_BattleCry, bc);
	MaxDps:GlowCooldown(_Avatar, ava);
	MaxDps:GlowCooldown(_Bloodbath, bb);
	MaxDps:GlowCooldown(_BerserkerRage, berserRage);

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

function MaxDps.Warrior.Protection()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local rage = UnitPower('player', SPELL_POWER_RAGE);
	local rageMax = UnitPowerMax('player', SPELL_POWER_RAGE);

	local revenge = MaxDps:SpellAvailable(_Revenge, timeShift);
	local sb = MaxDps:SpellAvailable(_StormBolt, timeShift);
	local ss = MaxDps:SpellAvailable(_ShieldSlam, timeShift);
	local ravager = MaxDps:SpellAvailable(_Ravager, timeShift);
	local tc = MaxDps:SpellAvailable(_ThunderClap, timeShift);
	local sw = MaxDps:SpellAvailable(_Shockwave, timeShift);

	local ulti = MaxDps:Aura(_Ultimatum, timeShift);

	local ph = MaxDps:TargetPercentHealth();

	MaxDps:GlowCooldown(_Ravager, _isRavager and ravager);
	MaxDps:GlowCooldown(_ThunderClap, tc);

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