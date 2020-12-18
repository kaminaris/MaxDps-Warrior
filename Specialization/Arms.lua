local _, addonTable = ...;
--- @type MaxDps
if not MaxDps then return end

local Warrior = addonTable.Warrior;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local PowerTypeRage = Enum.PowerType.Rage;
local debug = false;

local AR = {
	Charge = 100,
	SweepingStrikes = 260708,
	Bladestorm = 227847,
	Ravager = 152277,
	Massacre = 281001,
	DeadlyCalm = 262228,
	Rend = 772,
	Skullsplitter = 260643,
	Avatar = 107574,
	ColossusSmash = 167105,
	Cleave = 845,
	DeepWounds = 262115,
	Warbreaker = 262161,
	Condemn = 330334,
	SuddenDeath = 52437,
	Overpower = 7384,
	MortalStrike = 12294,
	Dreadnaught = 262150,
	Whirlwind = 1680,
	FervorOfBattle = 202316,
	Slam = 1464,
	BloodFury = 20572,
};

function debugPrint(message)
	if (debug) then
		print(message)
	end
end

function Warrior:Arms()
	local fd = MaxDps.FrameData;
	-- local targets = MaxDps:SmartAoe();
	local targets = 2;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local rage = UnitPower('player', PowerTypeRage);

	fd.rage, fd.targetHp, fd.targets = rage, targetHp, targets;

	if targets >= 4 then
		return Warrior:ArmsFourOrMoreTargets();
	end

	if targets >= 2 then
		return Warrior:ArmsTwoOrMoreTargets();
	end

	return Warrior:ArmsSingleTarget();
end


-- SINGLE TARGET --
function Warrior:ArmsSingleTarget()
	local fd = MaxDps.FrameData;
	local talents = fd.talents;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local covenantId = fd.covenant.covenantId;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local gcd = fd.gcd;
	local gcdRemains = fd.gcdRemains;
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local targetCondemnable = targetHp > 80 or (talents[AR.Massacre] and targetHp <= 35 or targetHp <= 20); 

	-- We want to increase rage for execution so cast skullsplitter here if you have it and are less than60 rage
	if talents[AR.Skullsplitter] and targetCondemnable and cooldown[AR.Skullsplitter].ready and (rage < 60 and (not talents[AR.DeadlyCalm] or not buff[AR.DeadlyCalm].up)) then
		return AR.Skullsplitter;
	end

	-- We only want to queue these things up if the target can benefit from the huge rage generation.
	if (targetCondemnable) then 
		-- If ravager and avatar are ready when we are < 30 rage, we want to queue them up together.
		if rage < 30 and talents[AR.Ravager] and cooldown[AR.Ravager].ready and talents[AR.Avatar] and cooldown[AR.Avatar].ready then
			return AR.Avatar;
		end

		-- Once we cast avatar, we want to cast ravager
		if talents[AR.Ravager] and talents[AR.Avatar] and buff[AR.Avatar].remains < 18 and buff[AR.Avatar].remains > 0 and cooldown[AR.Ravager].ready then
			return AR.Ravager;
		end

		-- If we don't have avatar, we still want to cast ravager because it is a huge rage generator for execute
		if rage < 30 and talents[AR.Ravager] and cooldown[AR.Ravager].ready then
			return AR.Ravager;
		end

		if UnitRace("player") == 'Orc' and cooldown[AR.BloodFury].ready then
			return AR.BloodFury;
		end
	end

	local warbreakerUp = talents[AR.Warbreaker] and (cooldown[AR.Warbreaker].remains < 8 and gcdRemains == 0);
	local colossusSmashUp = cooldown[AR.ColossusSmash].remains < 8 and gcdRemains == 0
	if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (warbreakerUp or colossusSmashUp) then
		debugPrint("Avatar:")
		debugPrint("talents[AR.Avatar]", talents[AR.Avatar])
		debugPrint("cooldown[AR.Avatar].ready", cooldown[AR.Avatar].ready)
		debugPrint("(cooldown[AR.Warbreaker].remains", cooldown[AR.Warbreaker].remains)
		debugPrint("gcdRemains", gcdRemains)
		return AR.Avatar;
	else
		debugPrint("Skipping Avatar this frame")
	end

	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready then
		debugPrint("Warbreaker:")
		debugPrint("talents[AR.Warbreaker]",talents[AR.Warbreaker])
		return AR.Warbreaker;
	else
		debugPrint("Skipping Warbreaker this frame")
	end

	if rage >= 30 and cooldown[AR.MortalStrike].ready and debuff[AR.DeepWounds].remains < 4 then
		debugPrint("Mortal Strike for deep wounds:")
		debugPrint("cooldown[AR.MortalStrike].ready", cooldown[AR.MortalStrike].ready)
		debugPrint("debuff[AR.DeepWounds].remains", debuff[AR.DeepWounds].remains)
		return AR.MortalStrike;
	else
		debugPrint("Skipping MortalStrike (for deep wounds) refresh this frame")
	end

	if cooldown[AR.Overpower].ready then
		debugPrint("Overpower:")
		debugPrint("cooldown[AR.Overpower].ready", cooldown[AR.Overpower].ready)
		return AR.Overpower;
	else
		debugPrint("Skipping Overpower this frame")
	end

	if buff[AR.SuddenDeath].count > 0 then
		debugPrint("Free Condemn:")
		debugPrint("buff[AR.SuddenDeath].count", buff[AR.SuddenDeath].count)
		return AR.Condemn;
	else
		debugPrint("Skipping Free Condemn this frame")
		debugPrint("buff[AR.SuddenDeath].count", buff[AR.SuddenDeath].count)
	end

	if (targetHp < 35 and rage >= 20) or (targetHp > 80 and rage >= 20) then
		debugPrint("Normal Condemn:")
		debugPrint("targetHp", targetHp)
		debugPrint("rage", rage)
		return AR.Condemn;
	else
		debugPrint("Skipping Condemn this frame")
		debugPrint("targetHp", targetHp)
		debugPrint("rage", rage)
	end

	if cooldown[AR.MortalStrike].ready and rage >= 30 then
		debugPrint("Regular mortal strike")
		debugPrint("cooldown[AR.MortalStrike].ready", cooldown[AR.MortalStrike].ready)
		debugPrint("rage", rage)
		return AR.MortalStrike;
	else
		debugPrint("Skipping MortalStrike (regular) this frame")
	end

	if cooldown[AR.Bladestorm].ready and debuff[AR.ColossusSmash].remains >= 5 then
		debugPrint("Bladestorm:")
		debugPrint("cooldown[AR.Bladestorm].ready", cooldown[AR.Bladestorm].ready)
		debugPrint("debuff[AR.ColossusSmash].remains", debuff[AR.ColossusSmash].remains)
		return AR.Bladestorm;
	else
		debugPrint("Skipping Bladestorm this frame")
	end

	if rage >= 20 then
		debugPrint("Slam")
		debugPrint("rage", rage)
		return AR.Slam;
	else 
		debugPrint("Skipping slam this frame -- DOING NOTHING THIS FRAME!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	end
end

function Warrior:ArmsTwoOrMoreTargets()
	local fd = MaxDps.FrameData;
	local talents = fd.talents;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local covenantId = fd.covenant.covenantId;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local gcd = fd.gcd;
	local gcdRemains = fd.gcdRemains;
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local targetCondemnable = targetHp > 80 or (talents[AR.Massacre] and targetHp <= 35 or targetHp <= 20); 
	print("Running arms 2-3 target rotation!")

	if cooldown[AR.SweepingStrikes].ready then
		return AR.SweepingStrikes;
	end

	if buff[AR.SuddenDeath].count > 0 then
		return AR.Condemn;
	end

	if cooldown[AR.Skullsplitter].ready and rage <= 60 and not(cooldown[AR.ColossusSmash].ready and cooldown[AR.Ravager].ready) then
		return AR.Skullsplitter;
	end

	if cooldown[AR.ColossusSmash].ready then
		return AR.ColossusSmash;
	end

	-- TODO: Abstract talents that overlap, like condemn/execute and Ravager/bladestorm
	if debuff[AR.ColossusSmash].up and cooldown[AR.Ravager].ready then
		return AR.Ravager;
	end

	if talents[AR.Cleave] and cooldown[AR.Cleave].ready then
		return AR.Cleave;
	end

	if (targetHp < 35 and rage >= 20) or (targetHp > 80 and rage >= 20) then
		return AR.Condemn;
	end

	if cooldown[AR.Overpower].ready then
		return AR.Overpower;
	end

	if cooldown[AR.MortalStrike].ready and rage >= 30 then
		return AR.MortalStrike;
	end

	if cooldown[AR.Whirlwind].ready  and rage >= 30 then
		return AR.Whirlwind;
	end
end

function Warrior:ArmsFourOrMoreTargets()
	local fd = MaxDps.FrameData;
	local talents = fd.talents;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local covenantId = fd.covenant.covenantId;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local gcd = fd.gcd;
	local gcdRemains = fd.gcdRemains;
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local targetCondemnable = targetHp > 80 or (talents[AR.Massacre] and targetHp <= 35 or targetHp <= 20); 
	print("Running arms 4+ target rotation!")

	if cooldown[AR.SweepingStrikes].ready then
		return AR.SweepingStrikes;
	end

	if buff[AR.SuddenDeath].count > 0 then
		return AR.Condemn;
	end

	if cooldown[AR.Skullsplitter].ready and rage <= 60 and not(cooldown[AR.ColossusSmash].ready and cooldown[AR.Ravager].ready) then
		return AR.Skullsplitter;
	end

	if cooldown[AR.ColossusSmash].ready then
		return AR.ColossusSmash;
	end

	-- TODO: Abstract talents that overlap, like condemn/execute and Ravager/bladestorm
	if debuff[AR.ColossusSmash].up and cooldown[AR.Ravager].ready then
		return AR.Ravager;
	end

	if talents[AR.Cleave] and cooldown[AR.Cleave].ready then
		return AR.Cleave;
	end

	if (targetHp < 35 and rage >= 20) or (targetHp > 80 and rage >= 20) then
		return AR.Condemn;
	end

	if cooldown[AR.Overpower].ready then
		return AR.Overpower;
	end

	if cooldown[AR.Whirlwind].ready  and rage >= 30 then
		return AR.Whirlwind;
	end
end