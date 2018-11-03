--- @type MaxDps
if not MaxDps then
	return ;
end

local MaxDps = MaxDps;
local UnitPower = UnitPower;

local Warrior = MaxDps:NewModule('Warrior');

-- Spells
-- General
local _Charge = 100;

-- Arms
local WA = {
	MassacreArms        = 281001,
	ExecuteArms         = 163201,
	ExecuteMassacreArms = 281000,
	Rend                = 772,
	ColossusSmash       = 167105,
	Skullsplitter       = 260643,
	Avatar              = 107574,
	Warbreaker          = 262161,
	MortalStrike        = 12294,
	Ravager             = 152277,
	BladestormArms      = 227847,
	Overpower           = 7384,
	WhirlwindArms       = 1680,
	Slam                = 1464,
	FervorOfBattle      = 202316,
	Dreadnaught         = 262150,
	SweepingStrikes     = 260708,
	Cleave              = 845,
	DeadlyCalm          = 262228,
	ColossusSmashAura   = 208086,
	SuddenDeathAuraArms = 52437
};


-- Fury
local WF = {
	FuriousSlash      = 100130,
	Recklessness      = 1719,
	Siegebreaker      = 280772,
	Rampage           = 184367,
	ExecuteMassacre   = 280735,
	Execute           = 5308,
	Bloodthirst       = 23881,
	RagingBlow        = 85288,
	DragonRoar        = 118000,
	Bladestorm        = 46924,
	Whirlwind         = 190411,
	Carnage           = 202922,
	VictoryRush       = 34428,
	FrothingBerserker = 215571,
	Massacre          = 206315,
	SuddenDeathAura   = 280776,
	Enrage            = 184362,
	FuriousSlashAura  = 202539,
};



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

function Warrior:Arms()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

	local rage = UnitPower('player', Enum.PowerType.Rage);
	local tgtPctHp = MaxDps:TargetPercentHealth();

	local execPct = 0.2;
	local execute = WA.ExecuteArms;
	if talents[WA.MassacreArms] then
		execPct = 0.35;
		execute = WA.ExecuteMassacreArms;
	end

	--CoolDowns

	if talents[WA.DeadlyCalm] then
		MaxDps:GlowCooldown(WA.DeadlyCalm, cooldown[WA.DeadlyCalm].ready);
	end

	if talents[WA.Avatar] then
		MaxDps:GlowCooldown(WA.Avatar, cooldown[WA.Avatar].ready);
	end

	--Rotation

	if talents[WA.Rend] and rage >= 30 and debuff[WA.Rend].remains < 4 and not debuff[WA.ColossusSmashAura].up then
		return WA.Rend;
	end

	if talents[WA.Skullsplitter] and cooldown[WA.Skullsplitter].ready and rage < 70 then
		return WA.Skullsplitter;
	end

	if talents[WA.Warbreaker] then
		if cooldown[WA.Warbreaker].ready then
			return WA.Warbreaker;
		end
	elseif cooldown[WA.ColossusSmash].ready then
		return WA.ColossusSmash;
	end

	if buff[WA.SuddenDeathAuraArms].up then
		return execute;
	end

	if cooldown[WA.MortalStrike].ready and rage >= 30 then
		return WA.MortalStrike;
	end

	if talents[WA.Ravager] then
		if cooldown[WA.Ravager].ready then
			return WA.Ravager;
		end
	else
		if cooldown[WA.BladestormArms].ready then
			return WA.BladestormArms;
		end
	end

	if cooldown[WA.Overpower].ready then
		return WA.Overpower;
	end

	if tgtPctHp < execPct then
		if cooldown[execute].ready and rage >= 40 then
			return execute;
		end
	else
		if talents[WA.FervorOfBattle] and rage >= 30 then
			return WA.WhirlwindArms;
		elseif rage >= 20 then
			return WA.Slam;
		end
	end
end

function Warrior:Fury()
	local fd = MaxDps.FrameData;
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
		fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell;

	local rage = UnitPower('player', Enum.PowerType.Rage);
	local tgtPctHp = MaxDps:TargetPercentHealth();

	local rampCost = 85;
	if talents[WF.Carnage] then
		rampCost = 75;
	elseif talents[WF.FrothingBerserker] then
		rampCost = 95;
	end

	local execute = WF.Execute;
	local execPct = 0.2;
	if talents[WF.Massacre] then --soul of the battlelord
		execPct = 0.35;
		execute = WF.ExecuteMassacre;
	end

	local enrage = buff[WF.Enrage].up;
	--local targets = MaxDps:SmartAoe();
	----print(targets);

	-- CoolDowns

	MaxDps:GlowCooldown(WF.Recklessness, cooldown[WF.Recklessness].ready);

	-- Rotation
	if talents[WF.FuriousSlash] then
		if cooldown[WF.FuriousSlash].ready and
			(buff[WF.FuriousSlashAura].remains <= 2 or buff[WF.FuriousSlashAura].count < 3) then
			return WF.FuriousSlash;
		end
	end

	if talents[WF.Siegebreaker] and cooldown[WF.Siegebreaker].ready then
		return WF.Siegebreaker;
	end

	if cooldown[WF.Rampage].ready and (rage >= 95 or (rage >= rampCost and not enrage)) then
		return WF.Rampage;
	end

	if enrage and ((tgtPctHp < execPct and cooldown[execute].ready) or buff[WF.SuddenDeathAura].up) then
		return execute;
	end

	if cooldown[WF.Bloodthirst].ready and not enrage then
		return WF.Bloodthirst;
	end

	if cooldown[WF.RagingBlow].charges >= 1.8 then
		return WF.RagingBlow;
	end

	if cooldown[WF.Bloodthirst].ready then
		return WF.Bloodthirst;
	end

	if talents[WF.DragonRoar] and enrage and cooldown[WF.DragonRoar].ready then
		return WF.DragonRoar;
	elseif talents[WF.Bladestorm] and enrage and cooldown[WF.Bladestorm].ready then
		return WF.Bladestorm;
	end

	if cooldown[WF.RagingBlow].ready and rage <= rampCost then
		return WF.RagingBlow;
	end

	if talents[WF.FuriousSlash] and cooldown[WF.FuriousSlash].ready then
		return WF.FuriousSlash;
	end

	return WF.Whirlwind;
end