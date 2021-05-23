local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local Warrior = addonTable.Warrior;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local PowerTypeRage = Enum.PowerType.Rage;

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local FR = {
	AncientAftershock = 325886,
	ConquerorsBanner  = 324143,
	SpearOfBastion    = 307865,
	Charge            = 100,
	HeroicLeap        = 6544,
	Rampage           = 184367,
	Recklessness      = 1719,
	RecklessAbandon   = 202751,
	AngerManagement   = 152278,
	Massacre          = 206315,
	MeatCleaver       = 280392,
	MeatCleaverAura   = 85739,
	Whirlwind         = 190411,
	RagingBlow        = 85288,
	CrushingBlow	  = 335097,
	Siegebreaker      = 280772,
	Enrage1           = 184361,
	Enrage2           = 184362,
	Frenzy            = 335077,
	CondemnMassacre	  = 330325,
	Condemn           = 317485,
	Execute           = 5308,
	ExecuteMassacre   = 280735,
	Bladestorm        = 46924,
	Bloodthirst       = 23881,
	BloodBath	 	  = 335096,
	ViciousContempt   = 337302,
	Cruelty           = 335070,
	DragonRoar        = 118000,
	Onslaught         = 315720,
	SuddenDeathAura   = 280776,
	Slam			  = 1464,
	CancelBladestorm  = 57755,

	-- leggo
	WillOfTheBerserkerBonusId = 6966,
	WillOfTheBerserker = 335597
};

setmetatable(FR, Warrior.spellMeta);

function Warrior:Fury()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local covenantId = fd.covenant.covenantId;
	local targets = MaxDps:SmartAoe();
	local rage = UnitPower('player', PowerTypeRage);
	local level = UnitLevel("player");
	local gcd = fd.gcd;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local timeToDie = fd.timeToDie;
	--local Bloodlust = MaxDps:Bloodlust();
	
	local _, _, _, BladestormCastttime = GetSpellInfo(46924);
	local BsCt = BladestormCastttime - gcd;
	
	fd.rage = rage;
	fd.targets = targets;
	
	local canExecute =  ((talents[FR.Massacre] and targetHp < 35) or
			targetHp < 20 or
			(targetHp > 80 and covenantId == Venthyr)) or
			buff[FR.SuddenDeathAura].up
	;

	-- recklessness;
	MaxDps:GlowCooldown(FR.Recklessness, cooldown[FR.Recklessness].ready);

	if talents[FR.Bladestorm] then
		MaxDps:GlowCooldown(FR.Bladestorm, cooldown[FR.Bladestorm].ready);
	end

	if covenantId == NightFae then
		MaxDps:GlowCooldown(FR.AncientAftershock, cooldown[FR.AncientAftershock].ready);
	elseif covenantId == Necrolord then
		MaxDps:GlowCooldown(FR.ConquerorsBanner, cooldown[FR.ConquerorsBanner].ready);
	elseif covenantId == Kyrian then
		MaxDps:GlowCooldown(FR.SpearOfBastion, cooldown[FR.SpearOfBastion].ready);
	end

	-- rampage,if=cooldown.recklessness.remains<3&talent.reckless_abandon.enabled;
	if rage >= 80 and cooldown[FR.Recklessness].remains < 3 and talents[FR.RecklessAbandon] then
		return FR.Rampage;
	end

	-- recklessness,if=gcd.remains=0&((buff.bloodlust.up|talent.anger_management.enabled|raid_event.adds.in>10)|target.time_to_die>100|(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20|target.time_to_die<15&raid_event.adds.in>10)&(spell_targets.whirlwind=1|buff.meat_cleaver.up);
	--if cooldown[FR.Recklessness].ready and
	--	(((Bloodlust or talents[FR.AngerManagement]) or timeToDie > 100 or canExecute or timeToDie < 15) and (targets == 1 or buff[FR.MeatCleaver].up)) then
	--	return FR.Recklessness;
	--end

	-- whirlwind,if=spell_targets.whirlwind>1&!buff.meat_cleaver.up|raid_event.adds.in<gcd&!buff.meat_cleaver.up;
	if targets > 1 and not buff[FR.MeatCleaverAura].up then
		return FR.Whirlwind;
	end

	-- run_action_list,name=single_target;
	return Warrior:FurySingleTarget();
end

function Warrior:FurySingleTarget()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
	local runeforge = fd.runeforge;
	local gcd = fd.gcd;
	local rage = fd.rage;
	local covenantId = fd.covenant.covenantId;
	local conduit = fd.covenant.soulbindConduits;
	local gcdRemains = gcd / 10;

	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local canExecute =  ((talents[FR.Massacre] and targetHp < 35) or
			targetHp < 20 or
			(targetHp > 80 and covenantId == Venthyr)) or
			buff[FR.SuddenDeathAura].up
	;
	
	local Enrage = buff[FR.Enrage1].up or buff[FR.Enrage2].up;
	local EnrageRemains = buff[Enrage1].remains < gcd or buff[Enrage2].remains < gcd;
	local EnrageBladestorm = buff[Enrage1].remains < 2.5 or buff[Enrage2].remains < 2.5;
	local Recklessness = buff[FR.Recklessness].up;

	local Execute = (talents[FR.Massacre] and FR.ExecuteMassacre or FR.Execute);
	local Condemn = (talents[FR.Massacre] and FR.CondemnMassacre or FR.Condemn);

	-- raging_blow,if=runeforge.will_of_the_berserker.equipped&buff.will_of_the_berserker.remains<gcd;
	
	if cooldown[FR.RagingBlow].ready and
		runeforge[FR.WillOfTheBerserkerBonusId] and
		buff[FR.WillOfTheBerserker].remains < gcd and
		not (Recklessness and talents[FR.RecklessAbandon])
	then
		return FR.RagingBlow;
	end
	
	if cooldown[FR.CrushingBlow].ready and
		runeforge[FR.WillOfTheBerserkerBonusId] and
		buff[FR.WillOfTheBerserker].remains < gcd and
		(Recklessness and talents[FR.RecklessAbandon])
	then
		return FR.CrushingBlow;
	end
	
	--if talents[FR.Bladestorm] and cooldown[FR.Bladestorm].ready and EnrageBladestorm and targets > 1 then
	--	return FR.Bladestorm;
	--end
	
	if canExecute and cooldown[Condemn].ready and covenantId == Venthyr and Enrage then
		return Condemn;
	end

	-- siegebreaker,if=spell_targets.whirlwind>1|raid_event.adds.in>15;
	if talents[FR.Siegebreaker] and cooldown[FR.Siegebreaker].ready then
		return FR.Siegebreaker;
	end

	-- rampage,if=buff.recklessness.up|(buff.enrage.remains<gcd|rage>90)|buff.frenzy.remains<1.5;
	if	rage >= 80 and 
		(
			buff[FR.Recklessness].up or
			(EnrageRemains or rage > 90) or
			buff[FR.Frenzy].remains < 1.5
		)
	then
		return FR.Rampage;
	end

	-- condemn;
	if canExecute and cooldown[Condemn].ready and covenantId == Venthyr then
		return Condemn;
	end
	
	-- execute;
	if canExecute and cooldown[Execute].ready and covenantId ~= Venthyr then
		return Execute;
	end

	-- bladestorm,if=buff.enrage.up&(spell_targets.whirlwind>1|raid_event.adds.in>45);
	--if talents[FR.Bladestorm] and cooldown[FR.Bladestorm].ready and Enrage then
	--	return FR.Bladestorm;
	--end

	-- bloodthirst,if=buff.enrage.down|conduit.vicious_contempt.rank>5&target.health.pct<35&!talent.cruelty.enabled;
	if cooldown[FR.Bloodthirst].ready and
		(
			not Enrage
			--or conduit[FR.ViciousContempt] > 5 
			and targetHp < 35 and not talents[FR.Cruelty]
		) and
		not (Recklessness and talents[FR.RecklessAbandon])
	then
		return FR.Bloodthirst;
	end
	
	if cooldown[FR.BloodBath].ready and
		(
			not Enrage
			--or conduit[FR.ViciousContempt] > 5 
			and targetHp < 35 and not talents[FR.Cruelty]
		) and
		(Recklessness and talents[FR.RecklessAbandon])
	then
		return FR.BloodBath;
	end

	-- dragon_roar,if=buff.enrage.up&(spell_targets.whirlwind>1|raid_event.adds.in>15);
	if talents[FR.DragonRoar] and cooldown[FR.DragonRoar].ready and Enrage then
		return FR.DragonRoar;
	end

	-- onslaught;
	if talents[FR.Onslaught] and cooldown[FR.Onslaught].ready then
		return FR.Onslaught;
	end

	-- raging_blow,if=charges=2;
	if cooldown[FR.RagingBlow].charges >= 2 and
		not (Recklessness and talents[FR.RecklessAbandon]) then
		return FR.RagingBlow;
	end
	
	if cooldown[FR.CrushingBlow].charges >= 2 and
		(Recklessness and talents[FR.RecklessAbandon]) then
		return FR.CrushingBlow;
	end

	-- bloodthirst;
	if cooldown[FR.Bloodthirst].ready and
		not (Recklessness and talents[FR.RecklessAbandon]) then
		return FR.Bloodthirst;
	end
	
	if cooldown[FR.BloodBath].ready and
		(Recklessness and talents[FR.RecklessAbandon]) then
		return FR.BloodBath;
	end

	-- raging_blow;
	if cooldown[FR.RagingBlow].ready and
		not (Recklessness and talents[FR.RecklessAbandon]) then
		return FR.RagingBlow;
	end
	
	if cooldown[FR.CrushingBlow].ready and
		(Recklessness and talents[FR.RecklessAbandon]) then
		return FR.CrushingBlow;
	end

	-- whirlwind;
	return FR.Whirlwind;
end
