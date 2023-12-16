local _, addonTable = ...
--- @type MaxDps
if not MaxDps then
    return
end

local Warrior = addonTable.Warrior
local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local PowerTypeRage = Enum.PowerType.Rage

local fd
local cooldown
local buff
local debuff
local talents
local targets
local rage
local rageMax
local rageDeficit
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local inExecutePhase
local bladestormspell

local className, classFilename, classId = UnitClass("player")
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
local classtable

function Warrior:Arms()
	fd = MaxDps.FrameData
	cooldown = fd.cooldown
	buff = fd.buff
    debuff = fd.debuff
	talents = fd.talents
	targets = MaxDps:SmartAoe()
	rage = UnitPower('player', PowerTypeRage)
	rageMax = UnitPowerMax('player', PowerTypeRage)
	rageDeficit = rageMax - rage
	targetHP = UnitHealth('target')
	targetmaxHP = UnitHealthMax('target')
	targethealthPerc = (targetHP / targetmaxHP) * 100
	curentHP = UnitHealth('player')
	maxHP = UnitHealthMax('player')
	healthPerc = (curentHP / maxHP) * 100
	classtable = MaxDps.SpellTable
    classtable.RendDebuff = 388539
    classtable.SuddenDeathBuff = 52437
    classtable.DeepWoundsDebuff = 262115
    classtable.ColossusSmashDebuff = 208086
    classtable.ExecutionersPrecisionBuff = 386634
    classtable.HurricaneBuff = 390581
    classtable.MercilessBonegrinderBuff = 383316
    classtable.InfortheKillBuff = 248622
    classtable.Bladestorm = 227847
    classtable.BladestormHurricane = 389774
    bladestormspell = MaxDps:FindSpell(classtable.Bladestorm) or MaxDps:FindSpell(classtable.BladestormHurricane)

    --setmetatable(classtable, Warrior.spellMeta)

    inExecutePhase = (talents[classtable.Massacre] and targetHP < 35) or targetHP < 20

    if targets >= 3 then
        return Warrior:ArmsMultiTarget()
    end

    return Warrior:ArmsSingleTarget()

end

--optional abilities list
--Avatar
--Thunderous Roar	 
--Spear of Bastion
--Blood and Thunder 
--Skullsplitter
--Storm of Swords
--Warbreaker
--T31 Tier Set
--Bladestorm

function Warrior:ArmsSingleTarget()
    --The two-target rotation is identical to single target, with the addition of using Sweeping Strikes on cooldown
    if targets == 2 and cooldown[classtable.SweepingStrikes].ready then
        return classtable.SweepingStrikes
    end
    --Cast Execute to consume Sudden Death procs.
    if ((rage >=20 and inExecutePhase) or buff[classtable.SuddenDeathBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    --Cast Mortal Strike on cooldown.
    if talents[classtable.MortalStrike] and rage >=30 and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    --Cast Thunder Clap to apply Rend or if less than 3 seconds remain on the debuff.
    if talents[classtable.BloodandThunder] and talents[classtable.ThunderClap] and rage >= 40 and (not debuff[classtable.RendDebuff] or debuff[classtable.RendDebuff].refreshable) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (not talents[classtable.BloodandThunder]) and talents[classtable.Rend] and rage >= 30 and (not debuff[classtable.RendDebuff] or debuff[classtable.RendDebuff].refreshable) and cooldown[classtable.Rend].ready then
        return classtable.Rend
    end
    --Cast Avatar simultaneously with Colossus Smash or Warbreaker.
    if talents[classtable.Avatar] and (cooldown[classtable.ColossusSmash].ready or cooldown[classtable.Warbreaker].ready) and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    --Cast Warbreaker or Colossus Smash.
    if (talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready) or (not talents[classtable.Warbreaker] and talents[classtable.ColossusSmash] and cooldown[classtable.ColossusSmash].ready) then
        return (talents[classtable.Warbreaker] and classtable.Warbreaker) or (not talents[classtable.Warbreaker] and talents[classtable.ColossusSmash] and classtable.ColossusSmash)
    end
    --Cast Spear of Bastion during Colossus Smash.
    if talents[classtable.SpearofBastion] and debuff[classtable.ColossusSmashDebuff].up and cooldown[classtable.SpearofBastion].ready then
        return classtable.SpearofBastion
    end
    --Cast Skullsplitter near the start of Colossus Smash while both Rend and Deep Wounds are active.
    if talents[classtable.Skullsplitter] and (debuff[classtable.RendDebuff].up and debuff[classtable.DeepWoundsDebuff].up) and cooldown[classtable.Skullsplitter].ready then
        return classtable.Skullsplitter
    end
    --Cast Thunderous Roar during Colossus Smash or Test of Might.
    if talents[classtable.ThunderousRoar] and (debuff[classtable.ColossusSmashDebuff].up or buff[classtable.TestOfMight].up) and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
    --Cast Whirlwind as a large rage dump.
    if rage >=60 and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    --Cast Bladestorm during Test of Might.
    if talents[classtable.Bladestorm] and buff[classtable.TestOfMight].up and (MaxDps:FindSpell(classtable.Bladestorm) and cooldown[classtable.Bladestorm].ready or MaxDps:FindSpell(classtable.BladestormHurricane) and cooldown[classtable.BladestormHurricane].ready) then
        return (MaxDps:FindSpell(classtable.Bladestorm) and classtable.Bladestorm) or (MaxDps:FindSpell(classtable.BladestormHurricane) and classtable.BladestormHurricane)
    end
    --Cast Overpower as able.
    if talents[classtable.Overpower] and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    --Cast Slam to spend rage.
    if rage >=20 and cooldown[classtable.Slam].ready then
        return classtable.Slam
    end
end

function Warrior:ArmsMultiTarget()
    --Cast Execute to consume Sudden Death procs.
    if ((rage >=20 and inExecutePhase) or buff[classtable.SuddenDeathBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    --Cast Thunder Clap to apply Rend or if less than 4 seconds remain on the debuff.
    if talents[classtable.BloodandThunder] and talents[classtable.ThunderClap] and rage >= 40 and (not debuff[classtable.RendDebuff].up or debuff[classtable.RendDebuff].duration < 3) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    --Cast Warbreaker to apply Colossus Smash.
    if talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        return classtable.Warbreaker
    end
    --Cast Sweeping Strikes when Bladestorm is not about to be cast, in order to not waste duration.
    if (cooldown[classtable.Bladestorm].duration > 2 or cooldown[classtable.BladestormHurricane].duration > 2) and cooldown[classtable.SweepingStrikes].ready then
        return classtable.SweepingStrikes
    end
    -- Cast Colossus Smash After SweepingStrikes if not talented into Warbreaker
    if not talents[classtable.Warbreaker] and talents[classtable.ColossusSmash] and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    --Cast Spear of Bastion during the Colossus Smash debuff.
    if talents[classtable.SpearofBastion] and debuff[classtable.ColossusSmashDebuff].up and cooldown[classtable.SpearofBastion].ready then
        return classtable.SpearofBastion
    end
    --Cast Avatar during the Colossus Smash debuff.
    if talents[classtable.Avatar] and debuff[classtable.ColossusSmashDebuff].up and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    --Cast Whirlwind during the Hurricane or Merciless Bonegrinder buffs following Bladestorm.
    if (buff[classtable.HurricaneBuff].up or buff[classtable.MercilessBonegrinderBuff].up) and rage >=60 and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    --Cast Thunderous Roar during Test of Might or In for the Kill.
    if talents[classtable.ThunderousRoar] and (buff[classtable.TestOfMight].up or buff[classtable.InfortheKillBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
    --Cast Bladestorm during the Colossus Smash debuff.
    --print(MaxDps:FindSpell(classtable.Bladestorm))
    if talents[classtable.Bladestorm] and debuff[classtable.ColossusSmashDebuff].up and (MaxDps:FindSpell(classtable.Bladestorm) and cooldown[classtable.Bladestorm].ready or MaxDps:FindSpell(classtable.BladestormHurricane) and cooldown[classtable.BladestormHurricane].ready) then
        return (MaxDps:FindSpell(classtable.Bladestorm) and classtable.Bladestorm) or (MaxDps:FindSpell(classtable.BladestormHurricane) and classtable.BladestormHurricane)
    end
    --Cast Skullsplitter during Sweeping Strikes and while both Deep Wounds and Rend are active.
    if talents[classtable.Skullsplitter] and buff[classtable.SweepingStrikes].up and debuff[classtable.DeepWoundsDebuff].up and debuff[classtable.RendDebuff].up and cooldown[classtable.Skullsplitter].ready then
        return classtable.Skullsplitter
    end
    --Cast Cleave as needed to reapply Deep Wounds to multiple targets.
    if rage >=20 and talents[classtable.Cleave] and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
    --Cast Whirlwind as the main rotational ability.
    if rage >=60 and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    --Cast Mortal Strike on with two stacks of Executioner's Precision or to reapply Deep Wounds.
    if talents[classtable.MortalStrike] and rage >=30 and (buff[classtable.ExecutionersPrecisionBuff].count == 2 or not debuff[classtable.DeepWounds].up) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    --Cast Overpower as a multitarget filler.
    if talents[classtable.Overpower] and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    --Cast Whirlwind against multiple targets.
    if rage >=60 and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    --Cast Execute to spend excess Rage.
    if rage >=20 and inExecutePhase and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    --Cast Thunder Clap as a filler.
    if talents[classtable.ThunderClap] and rage >=40 and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
end


