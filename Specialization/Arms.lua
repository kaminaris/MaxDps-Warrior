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
	DeepWounds = 262304,
	Warbreaker = 262161,
	Condemn = 330334,
	SuddenDeath = 29725,
	Overpower = 7384,
	MortalStrike = 12294,
	Dreadnaught = 262150,
	Whirlwind = 1680,
	FervorOfBattle = 202316,
	Slam = 1464,
};
local A = {
};
function Warrior:Arms()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local azerite = fd.azerite;
	local talents = fd.talents;
	local buff = fd.buff;
	local targets = MaxDps:SmartAoe();
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local covenantId = fd.covenant.covenantId;
	local rage = UnitPower('player', PowerTypeRage);

	fd.rage, fd.targetHp, fd.targets = rage, targetHp, targets;

	MaxDps:GlowEssences();

	-- sweeping_strikes,if=spell_targets.whirlwind>1&(cooldown.bladestorm.remains>15|talent.ravager.enabled);
	if cooldown[AR.SweepingStrikes].ready and (targets > 1 and ( cooldown[AR.Bladestorm].remains > 15 or talents[AR.Ravager] )) then
		return AR.SweepingStrikes;
	end

	-- run_action_list,name=hac,if=raid_event.adds.exists;
	-- return Warrior:ArmsHac();

	-- run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20|(target.health.pct>80&covenant.venthyr);
	if ( talents[AR.Massacre] and targetHp < 35 ) or targetHp < 20 or ( targetHp > 80 and covenantId == Enum.CovenantType.Venthyr ) then
		return Warrior:ArmsExecute();
	end

	-- run_action_list,name=single_target;
	return Warrior:ArmsSingleTarget();
end

function Warrior:ArmsExecute()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local gcd = fd.gcd;
	local gcdRemains = fd.gcdRemains;
	local rage = UnitPower('player', Enum.PowerType.Rage);

	-- deadly_calm;
	if talents[AR.DeadlyCalm] and cooldown[AR.DeadlyCalm].ready then
		return AR.DeadlyCalm;
	end

	-- rend,if=remains<=duration*0.3;
	if talents[AR.Rend] and rage >= 30 and (debuff[AR.Rend].remains <= cooldown[AR.Rend].duration * 0.3) then
		return AR.Rend;
	end

	-- skullsplitter,if=rage<60&(!talent.deadly_calm.enabled|buff.deadly_calm.down);
	if cooldown[AR.Skullsplitter].ready and (rage < 60 and ( not talents[AR.DeadlyCalm] or not buff[AR.DeadlyCalm].up )) then
		return AR.Skullsplitter;
	end

	-- avatar,if=cooldown.colossus_smash.remains<8&gcd.remains=0;
	if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (cooldown[AR.ColossusSmash].remains < 8 and gcdRemains == 0) then
		return AR.Avatar;
	end

	-- ravager,if=buff.avatar.remains<18&!dot.ravager.remains;
	if talents[AR.Ravager] and cooldown[AR.Ravager].ready and (buff[AR.Avatar].remains < 18 and not debuff[AR.Ravager].remains) then
		return AR.Ravager;
	end

	-- cleave,if=spell_targets.whirlwind>1&dot.deep_wounds.remains<gcd;
	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 and (targets > 1 and debuff[AR.DeepWounds].remains < gcd) then
		return AR.Cleave;
	end

	-- warbreaker;
	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready then
		return AR.Warbreaker;
	end

	-- colossus_smash;
	if cooldown[AR.ColossusSmash].ready then
		return AR.ColossusSmash;
	end

	-- condemn,if=debuff.colossus_smash.up|buff.sudden_death.react|rage>65;
	if rage >= 20 and (debuff[AR.ColossusSmash].up or buff[AR.SuddenDeath].count or rage > 65) then
		return AR.Condemn;
	end

	-- overpower,if=charges=2;
	if cooldown[AR.Overpower].ready and (cooldown[AR.Overpower].charges == 2) then
		return AR.Overpower;
	end

	-- bladestorm,if=buff.deadly_calm.down&rage<50;
	if cooldown[AR.Bladestorm].ready and (not buff[AR.DeadlyCalm].up and rage < 50) then
		return AR.Bladestorm;
	end

	-- mortal_strike,if=dot.deep_wounds.remains<=gcd;
	if cooldown[AR.MortalStrike].ready and rage >= 30 and (debuff[AR.DeepWounds].remains <= gcd) then
		return AR.MortalStrike;
	end

	-- skullsplitter,if=rage<40;
	if cooldown[AR.Skullsplitter].ready and (rage < 40) then
		return AR.Skullsplitter;
	end

	-- overpower;
	if cooldown[AR.Overpower].ready then
		return AR.Overpower;
	end

	-- condemn;
	if rage >= 20 then
		return AR.Condemn;
	end

	-- execute;
	return AR.Execute;
end

function Warrior:ArmsHac()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local rage = UnitPower('player', Enum.PowerType.Rage);

	-- skullsplitter,if=rage<60&buff.deadly_calm.down;
	if cooldown[AR.Skullsplitter].ready and (rage < 60 and not buff[AR.DeadlyCalm].up) then
		return AR.Skullsplitter;
	end

	-- avatar,if=cooldown.colossus_smash.remains<1;
	if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (cooldown[AR.ColossusSmash].remains < 1) then
		return AR.Avatar;
	end

	-- cleave,if=dot.deep_wounds.remains<=gcd;
	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 and (debuff[AR.DeepWounds].remains <= gcd) then
		return AR.Cleave;
	end

	-- warbreaker;
	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready then
		return AR.Warbreaker;
	end

	-- bladestorm;
	if cooldown[AR.Bladestorm].ready then
		return AR.Bladestorm;
	end

	-- ravager;
	if talents[AR.Ravager] and cooldown[AR.Ravager].ready then
		return AR.Ravager;
	end

	-- colossus_smash;
	if cooldown[AR.ColossusSmash].ready then
		return AR.ColossusSmash;
	end

	-- rend,if=remains<=duration*0.3&buff.sweeping_strikes.up;
	if talents[AR.Rend] and rage >= 30 and (debuff[AR.Rend].remains <= cooldown[AR.Rend].duration * 0.3 and buff[AR.SweepingStrikes].up) then
		return AR.Rend;
	end

	-- cleave;
	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 then
		return AR.Cleave;
	end

	-- mortal_strike,if=buff.sweeping_strikes.up|dot.deep_wounds.remains<gcd&!talent.cleave.enabled;
	if cooldown[AR.MortalStrike].ready and rage >= 30 and (buff[AR.SweepingStrikes].up or debuff[AR.DeepWounds].remains < gcd and not talents[AR.Cleave]) then
		return AR.MortalStrike;
	end

	-- overpower,if=talent.dreadnaught.enabled;
	if cooldown[AR.Overpower].ready and (talents[AR.Dreadnaught]) then
		return AR.Overpower;
	end

	-- condemn;
	if rage >= 20 then
		return AR.Condemn;
	end

	-- execute,if=buff.sweeping_strikes.up;
	if buff[AR.SweepingStrikes].up then
		return AR.Execute;
	end

	-- overpower;
	if cooldown[AR.Overpower].ready then
		return AR.Overpower;
	end

	-- whirlwind;
	if rage >= 30 then
		return AR.Whirlwind;
	end
end

function Warrior:ArmsSingleTarget()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local gcd = fd.gcd;
	local gcdRemains = fd.gcdRemains;
	local rage = UnitPower('player', Enum.PowerType.Rage);

	-- avatar,if=cooldown.colossus_smash.remains<8&gcd.remains=0;
	if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (cooldown[AR.ColossusSmash].remains < 8 and gcdRemains == 0) then
		return AR.Avatar;
	end

	-- rend,if=remains<=duration*0.3;
	if talents[AR.Rend] and rage >= 30 and (debuff[AR.Rend].remains <= cooldown[AR.Rend].duration * 0.3) then
		return AR.Rend;
	end

	-- cleave,if=spell_targets.whirlwind>1&dot.deep_wounds.remains<gcd;
	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 and (targets > 1 and debuff[AR.DeepWounds].remains < gcd) then
		return AR.Cleave;
	end

	-- warbreaker;
	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready then
		return AR.Warbreaker;
	end

	-- colossus_smash;
	if cooldown[AR.ColossusSmash].ready then
		return AR.ColossusSmash;
	end

	-- ravager,if=buff.avatar.remains<18&!dot.ravager.remains;
	if talents[AR.Ravager] and cooldown[AR.Ravager].ready and (buff[AR.Avatar].remains < 18 and not debuff[AR.Ravager].remains) then
		return AR.Ravager;
	end

	-- overpower,if=charges=2;
	if cooldown[AR.Overpower].ready and (cooldown[AR.Overpower].charges == 2) then
		return AR.Overpower;
	end

	-- bladestorm,if=buff.deadly_calm.down&(debuff.colossus_smash.up&rage<30|rage<70);
	if cooldown[AR.Bladestorm].ready and (not buff[AR.DeadlyCalm].up and ( debuff[AR.ColossusSmash].up and rage < 30 or rage < 70 )) then
		return AR.Bladestorm;
	end

	-- mortal_strike,if=buff.overpower.stack>=2&buff.deadly_calm.down|(dot.deep_wounds.remains<=gcd&cooldown.colossus_smash.remains>gcd);
	if cooldown[AR.MortalStrike].ready and rage >= 30 and (buff[AR.Overpower].count >= 2 and not buff[AR.DeadlyCalm].up or ( debuff[AR.DeepWounds].remains <= gcd and cooldown[AR.ColossusSmash].remains > gcd )) then
		return AR.MortalStrike;
	end

	-- deadly_calm;
	if talents[AR.DeadlyCalm] and cooldown[AR.DeadlyCalm].ready then
		return AR.DeadlyCalm;
	end

	-- skullsplitter,if=rage<60&buff.deadly_calm.down;
	if cooldown[AR.Skullsplitter].ready and (rage < 60 and not buff[AR.DeadlyCalm].up) then
		return AR.Skullsplitter;
	end

	-- overpower;
	if cooldown[AR.Overpower].ready then
		return AR.Overpower;
	end

	-- condemn,if=buff.sudden_death.react;
	if rage >= 20 and (buff[AR.SuddenDeath].count) then
		return AR.Condemn;
	end

	-- execute,if=buff.sudden_death.react;
	if buff[AR.SuddenDeath].count then
		return AR.Execute;
	end

	-- mortal_strike;
	if cooldown[AR.MortalStrike].ready and rage >= 30 then
		return AR.MortalStrike;
	end

	-- whirlwind,if=talent.fervor_of_battle.enabled&rage>60;
	if rage >= 30 and (talents[AR.FervorOfBattle] and rage > 60) then
		return AR.Whirlwind;
	end

	-- slam;
	if rage >= 20 then
		return AR.Slam;
	end
end

