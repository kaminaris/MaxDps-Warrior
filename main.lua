--- @type MaxDps
if not MaxDps then
	return ;
end

local Warrior = MaxDps:NewModule('Warrior');

-- Spells
-- General
local _Charge = 100;

-- Arms
local _MassacreArms = 281001;
local _ExecuteArms = 163201;
local _ExecuteMassacreArms = 281000;
local _Rend = 772;
local _ColossusSmash = 167105;
local _Skullsplitter = 260643;
local _Avatar = 107574;
local _Warbreaker = 262161;
local _MortalStrike = 12294;
local _Ravager = 152277;
local _BladestormArms = 227847;
local _Overpower = 7384;
local _WhirlwindArms = 1680;
local _Slam = 1464;
local _FervorofBattle = 202316;
local _Dreadnaught = 262150;
local _SweepingStrikes = 260708;
local _Cleave = 845;
local _DeadlyCalm = 262228;

-- Fury
local _FuriousSlash = 100130;
local _Recklessness = 1719;
local _Siegebreaker = 280772;
local _Rampage = 184367;
local _ExecuteMassacre = 280735;
local _Execute = 5308;
local _Bloodthirst = 23881;
local _RagingBlow = 85288;
local _DragonRoar = 118000;
local _Bladestorm = 46924;
local _Whirlwind = 190411;
local _Carnage = 202922;
local _VictoryRush = 34428;
local _FrothingBerserker = 215571;
local _Massacre = 206315;

-- Auras
-- Arms
local _ColossusSmashAura = 208086;
local _SuddenDeathAuraArms = 52437;
local _DeepWounds = 262304;

-- Fury
local _Enrage = 184362;
local _FuriousSlashAura = 202539;
local _SuddenDeathAura = 280776;

function Warrior:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Warrior [Arms, Fury, Protection]');

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Warrior.Arms;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Warrior.Fury;
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Warrior.Protection;
	end

	return true;
end

function Warrior:Protection(timeShift, currentSpell, gcd, talents)
	-- NYI
	return nil;
end

function Warrior:Arms(timeShift, currentSpell, gcd, talents)
	local rage = UnitPower('player', Enum.PowerType.Rage);

	local tgtPctHp = MaxDps:TargetPercentHealth();

	local execPct = 0.2;
	local execute = _ExecuteArms;
	if talents[_MassacreArms] then
		execPct = 0.35;
		execute = _ExecuteMassacreArms;
	end

	--CoolDowns

	if talents[_DeadlyCalm] then
		MaxDps:GlowCooldown(_DeadlyCalm, MaxDps:SpellAvailable(_DeadlyCalm, timeShift));
	end

	if talents[_Avatar] then
		MaxDps:GlowCooldown(_Avatar, MaxDps:SpellAvailable(_Avatar, timeShift));
	end

	--Rotation

	local _, _, rendT = MaxDps:TargetAura(_Rend, timeShift);
	if talents[_Rend] and rage >= 30 and rendT < 4 and not MaxDps:TargetAura(_ColossusSmashAura, timeShift) then
		return _Rend;
	end

	if talents[_Skullsplitter] and MaxDps:SpellAvailable(_Skullsplitter, timeShift) and rage < 70 then
		return _Skullsplitter;
	end

	if talents[_Warbreaker] then
		if MaxDps:SpellAvailable(_Warbreaker, timeShift) then
			return _Warbreaker;
		end
	elseif MaxDps:SpellAvailable(_ColossusSmash, timeShift) then
		return _ColossusSmash;
	end

	if MaxDps:Aura(_SuddenDeathAuraArms, timeShift) then
		return execute;
	end

	if MaxDps:SpellAvailable(_MortalStrike, timeShift) and rage >= 30 then
		return _MortalStrike;
	end

	if talents[_Ravager] then
		if MaxDps:SpellAvailable(_Ravager, timeShift) then
			return _Ravager;
		end
	else
		if MaxDps:SpellAvailable(_BladestormArms, timeShift) then
			return _BladestormArms;
		end
	end

	if MaxDps:SpellAvailable(_Overpower, timeShift) then
		return _Overpower;
	end

	if tgtPctHp < execPct then
		if MaxDps:SpellAvailable(execute, timeShift) and rage >= 40 then
			return execute;
		end
	else
		if talents[_FervorofBattle] and rage >= 30 then
			return _WhirlwindArms;
		elseif rage >= 20 then
			return _Slam;
		end
	end
end

function Warrior:Fury(timeShift, currentSpell, gcd, talents)
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local tgtPctHp = MaxDps:TargetPercentHealth();

	local rampCost = 85;
	if talents[_Carnage] then
		rampCost = 75;
	elseif talents[_FrothingBerserker] then
		rampCost = 95;
	end

	local execute = _Execute;
	local execPct = 0.2;
	if talents[_Massacre] or IsEquippedItem(151650) then --soul of the battlelord
		execPct = 0.35;
		execute = _ExecuteMassacre;
	end

	local enrage = MaxDps:Aura(_Enrage, timeShift);

	-- CoolDowns

	MaxDps:GlowCooldown(_Recklessness, MaxDps:SpellAvailable(_Recklessness, timeShift));

	-- Rotation
	if talents[_FuriousSlash] then
		local fs, fsCount, fsTime = MaxDps:Aura(_FuriousSlashAura, timeShift);
		if MaxDps:SpellAvailable(_FuriousSlash, timeShift) and
			(fsTime <= 2 or fsCount < 3) then
			return _FuriousSlash;
		end
	end

	if talents[_Siegebreaker] and MaxDps:SpellAvailable(_Siegebreaker, timeShift) then
		return _Siegebreaker;
	end

	if MaxDps:SpellAvailable(_Rampage, timeShift) and (rage >= 95 or (rage >= rampCost and not enrage)) then
		return _Rampage;
	end

	if enrage and (
		(tgtPctHp < execPct and MaxDps:SpellAvailable(execute, timeShift)) or MaxDps:Aura(_SuddenDeathAura, timeShift)
		)
	then
		return execute;
	end

	if MaxDps:SpellAvailable(_Bloodthirst, timeShift) and not enrage then
		return _Bloodthirst;
	end

	local _, rbCharges = MaxDps:SpellCharges(_RagingBlow, timeShift);
	if MaxDps:SpellAvailable(_RagingBlow, timeShift) and rbCharges >= 2 then
		return _RagingBlow;
	end

	if MaxDps:SpellAvailable(_Bloodthirst, timeShift) then
		return _Bloodthirst;
	end

	if talents[_DragonRoar] and enrage and MaxDps:SpellAvailable(_DragonRoar, timeShift) then
		return _DragonRoar;
	elseif talents[_Bladestorm] and enrage and MaxDps:SpellAvailable(_Bladestorm, timeShift) then
		return _Bladestorm;
	end

	if MaxDps:SpellAvailable(_RagingBlow, timeShift) and rage <= rampCost then
		return _RagingBlow;
	end

	if talents[_FuriousSlash] and MaxDps:SpellAvailable(_FuriousSlash, timeShift) then
		return _FuriousSlash;
	end

	return _Whirlwind;
end