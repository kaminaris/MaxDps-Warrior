local _, addonTable = ...;
--- @type MaxDps
if not MaxDps then return end

local Warrior = addonTable.Warrior;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local PowerTypeRage = Enum.PowerType.Rage;

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
};

function Warrior:Arms()
	local fd = MaxDps.FrameData;
	local targets = MaxDps:SmartAoe();
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


	print("")
	print("")
	print("------------- single target frame ---------------")

	if talents[AR.Avatar] and cooldown[AR.Avatar].ready and talents[AR.Warbreaker] and (cooldown[AR.Warbreaker].remains < 8 and gcdRemains == 0) then
		print("Avatar:")
		print("talents[AR.Avatar]", talents[AR.Avatar])
		print("cooldown[AR.Avatar].ready", cooldown[AR.Avatar].ready)
		print("(cooldown[AR.Warbreaker].remains", cooldown[AR.Warbreaker].remains)
		print("gcdRemains", gcdRemains)
		return AR.Avatar;
	else
		print("Skipping Avatar this frame")
	end

	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready then
		print("Warbreaker:")
		print("talents[AR.Warbreaker]",talents[AR.Warbreaker])
		return AR.Warbreaker;
	else
		print("Skipping Warbreaker this frame")
	end

	if cooldown[AR.MortalStrike].ready and debuff[AR.DeepWounds].remains < 4 then
		print("Mortal Strike for deep wounds:")
		print("cooldown[AR.MortalStrike].ready", cooldown[AR.MortalStrike].ready)
		print("debuff[AR.DeepWounds].remains", debuff[AR.DeepWounds].remains)
		return AR.MortalStrike;
	else
		print("Skipping MortalStrike (for deep wounds) refresh this frame")
	end

	if cooldown[AR.Overpower].ready then
		print("Overpower:")
		print("cooldown[AR.Overpower].ready", cooldown[AR.Overpower].ready)
		return AR.Overpower;
	else
		print("Skipping Overpower this frame")
	end

	if buff[AR.SuddenDeath].count > 0 then
		print("Free Condemn:")
		print("buff[AR.SuddenDeath].count", buff[AR.SuddenDeath].count)
		return AR.Condemn;
	else
		print("Skipping Free Condemn this frame")
		print("buff[AR.SuddenDeath].count", buff[AR.SuddenDeath].count)
	end

	if (targetHp < 35 and rage >= 20) or (targetHp > 80 and rage >= 20) then
		print("Normal Condemn:")
		print("targetHp", targetHp)
		print("rage", rage)
		return AR.Condemn;
	else
		print("Skipping Condemn this frame")
		print("targetHp", targetHp)
		print("rage", rage)
	end

	if cooldown[AR.MortalStrike].ready and rage >= 30 then
		print("Regular mortal strike")
		print("cooldown[AR.MortalStrike].ready", cooldown[AR.MortalStrike].ready)
		print("rage", rage)
		return AR.MortalStrike;
	else
		print("Skipping MortalStrike (regular) this frame")
	end

	if cooldown[AR.Bladestorm].ready and debuff[AR.ColossusSmash].remains >= 5 then
		print("Bladestorm:")
		print("cooldown[AR.Bladestorm].ready", cooldown[AR.Bladestorm].ready)
		print("debuff[AR.ColossusSmash].remains", debuff[AR.ColossusSmash].remains)
		return AR.Bladestorm;
	else
		print("Skipping Bladestorm this frame")
	end

	if rage >= 20 then
		print("Slam")
		print("rage", rage)
		return AR.Slam;
	else 
		print("Skipping slam this frame -- DOING NOTHING THIS FRAME!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	end
end

function ArmsFourOrMoreTargets()
	print("Running arms 4+ target rotation!")
end

function ArmsTwoOrMoreTargets()
	print("Running arms 2-3 target rotation!")
end

-- function Warrior:ArmsExecute()
-- 	local fd = MaxDps.FrameData;
-- 	local cooldown = fd.cooldown;
-- 	local buff = fd.buff;
-- 	local debuff = fd.debuff;
-- 	local talents = fd.talents;
-- 	local targets = fd.targets;
-- 	local gcd = fd.gcd;
-- 	local gcdRemains = fd.gcdRemains;
-- 	local rage = UnitPower('player', Enum.PowerType.Rage);

-- 	-- deadly_calm;
-- 	if talents[AR.DeadlyCalm] and cooldown[AR.DeadlyCalm].ready then
-- 		return AR.DeadlyCalm;
-- 	end

-- 	-- rend,if=remains<=duration*0.3;
-- 	if talents[AR.Rend] and rage >= 30 and (debuff[AR.Rend].remains <= cooldown[AR.Rend].duration * 0.3) then
-- 		return AR.Rend;
-- 	end

-- 	-- skullsplitter,if=rage<60&(!talent.deadly_calm.enabled|buff.deadly_calm.down);
-- 	if talents[AR.Skullsplitter] and cooldown[AR.Skullsplitter].ready and (rage < 60 and ( not talents[AR.DeadlyCalm] or not buff[AR.DeadlyCalm].up )) then
-- 		return AR.Skullsplitter;
-- 	end

-- 	-- avatar,if=cooldown.colossus_smash.remains<8&gcd.remains=0;
-- 	if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (cooldown[AR.ColossusSmash].remains < 8 and gcdRemains == 0) then
-- 		return AR.Avatar;
-- 	end

-- 	-- ravager,if=buff.avatar.remains<18&!dot.ravager.remains;
-- 	if talents[AR.Ravager] and cooldown[AR.Ravager].ready and (buff[AR.Avatar].remains < 18 and not debuff[AR.Ravager].remains) then
-- 		return AR.Ravager;
-- 	end

-- 	-- cleave,if=spell_targets.whirlwind>1&dot.deep_wounds.remains<gcd;
-- 	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 and (targets > 1 and debuff[AR.DeepWounds].remains < gcd) then
-- 		return AR.Cleave;
-- 	end

-- 	-- warbreaker;
-- 	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready then
-- 		return AR.Warbreaker;
-- 	end

-- 	-- colossus_smash;
-- 	if cooldown[AR.ColossusSmash].ready then
-- 		return AR.ColossusSmash;
-- 	end

-- 	-- condemn,if=debuff.colossus_smash.up|buff.sudden_death.react|rage>65;
-- 	if rage >= 20 and (debuff[AR.ColossusSmash].up or buff[AR.SuddenDeath].count or rage > 65) then
-- 		return AR.Condemn;
-- 	end

-- 	-- overpower,if=charges=2;
-- 	if cooldown[AR.Overpower].ready and (cooldown[AR.Overpower].charges == 2) then
-- 		return AR.Overpower;
-- 	end

-- 	-- bladestorm,if=buff.deadly_calm.down&rage<50;
-- 	if cooldown[AR.Bladestorm].ready and (not buff[AR.DeadlyCalm].up and rage < 50) then
-- 		return AR.Bladestorm;
-- 	end

-- 	-- mortal_strike,if=dot.deep_wounds.remains<=gcd;
-- 	if cooldown[AR.MortalStrike].ready and rage >= 30 and (debuff[AR.DeepWounds].remains <= gcd) then
-- 		return AR.MortalStrike;
-- 	end

-- 	-- skullsplitter,if=rage<40;
-- 	if talents[AR.Skullsplitter] and cooldown[AR.Skullsplitter].ready and (rage < 40) then
-- 		return AR.Skullsplitter;
-- 	end

-- 	-- overpower;
-- 	if cooldown[AR.Overpower].ready then
-- 		return AR.Overpower;
-- 	end

-- 	-- condemn;
-- 	if rage >= 20 then
-- 		return AR.Condemn;
-- 	end

-- 	-- execute;
-- 	return AR.Execute;
-- end

-- function Warrior:ArmsHac()
-- 	local fd = MaxDps.FrameData;
-- 	local cooldown = fd.cooldown;
-- 	local buff = fd.buff;
-- 	local debuff = fd.debuff;
-- 	local talents = fd.talents;
-- 	local gcd = fd.gcd;
-- 	local rage = UnitPower('player', Enum.PowerType.Rage);

-- 	-- skullsplitter,if=rage<60&buff.deadly_calm.down;
-- 	if talents[AR.Skullsplitter] and cooldown[AR.Skullsplitter].ready and (rage < 60 and not buff[AR.DeadlyCalm].up) then
-- 		return AR.Skullsplitter;
-- 	end

-- 	-- avatar,if=cooldown.colossus_smash.remains<1;
-- 	if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (cooldown[AR.ColossusSmash].remains < 1) then
-- 		return AR.Avatar;
-- 	end

-- 	-- cleave,if=dot.deep_wounds.remains<=gcd;
-- 	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 and (debuff[AR.DeepWounds].remains <= gcd) then
-- 		return AR.Cleave;
-- 	end

-- 	-- warbreaker;
-- 	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready then
-- 		return AR.Warbreaker;
-- 	end

-- 	-- bladestorm;
-- 	if cooldown[AR.Bladestorm].ready then
-- 		return AR.Bladestorm;
-- 	end

-- 	-- ravager;
-- 	if talents[AR.Ravager] and cooldown[AR.Ravager].ready then
-- 		return AR.Ravager;
-- 	end

-- 	-- colossus_smash;
-- 	if cooldown[AR.ColossusSmash].ready then
-- 		return AR.ColossusSmash;
-- 	end

-- 	-- rend,if=remains<=duration*0.3&buff.sweeping_strikes.up;
-- 	if talents[AR.Rend] and rage >= 30 and (debuff[AR.Rend].remains <= cooldown[AR.Rend].duration * 0.3 and buff[AR.SweepingStrikes].up) then
-- 		return AR.Rend;
-- 	end

-- 	-- cleave;
-- 	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 then
-- 		return AR.Cleave;
-- 	end

-- 	-- mortal_strike,if=buff.sweeping_strikes.up|dot.deep_wounds.remains<gcd&!talent.cleave.enabled;
-- 	if cooldown[AR.MortalStrike].ready and rage >= 30 and (buff[AR.SweepingStrikes].up or debuff[AR.DeepWounds].remains < gcd and not talents[AR.Cleave]) then
-- 		return AR.MortalStrike;
-- 	end

-- 	-- overpower,if=talent.dreadnaught.enabled;
-- 	if cooldown[AR.Overpower].ready and (talents[AR.Dreadnaught]) then
-- 		return AR.Overpower;
-- 	end

-- 	-- condemn;
-- 	if rage >= 20 then
-- 		return AR.Condemn;
-- 	end

-- 	-- execute,if=buff.sweeping_strikes.up;
-- 	if buff[AR.SweepingStrikes].up then
-- 		return AR.Execute;
-- 	end

-- 	-- overpower;
-- 	if cooldown[AR.Overpower].ready then
-- 		return AR.Overpower;
-- 	end

-- 	-- whirlwind;
-- 	if rage >= 30 then
-- 		return AR.Whirlwind;
-- 	end
-- end

