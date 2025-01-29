local _, addonTable = ...
local Warrior = addonTable.Warrior
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCount = C_Spell.GetSpellCastCount

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

local fd
local ttd
local timeShift
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Rage
local RageMax
local RageDeficit
local RagePerc

local Arms = {}

local trinket_1_exclude
local trinket_2_exclude
local trinket_1_sync
local trinket_2_sync
local trinket_1_buffs
local trinket_2_buffs
local trinket_priority
local trinket_1_manual
local trinket_2_manual
local st_planning
local adds_remain
local execute_phase
function Arms:precombat()
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleStance, 'BattleStance')) and cooldown[classtable.BattleStance].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BattleStance end
    end
end
function Arms:colossus_st()
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager')) and (cooldown[classtable.ColossusSmash].remains <= gcd) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (targets == 1) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not talents[classtable.Warbreaker]) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and (talents[classtable.Warbreaker]) and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish') and talents[classtable.Demolish]) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (cooldown[classtable.Overpower].charges == 2) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd * 5) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
end
function Arms:colossus_execute()
    if (MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes')) and (targets == 2) and cooldown[classtable.SweepingStrikes].ready then
        MaxDps:GlowCooldown(classtable.SweepingStrikes, cooldown[classtable.SweepingStrikes].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd and not talents[classtable.Bloodletting]) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager')) and (cooldown[classtable.ColossusSmash].remains <= gcd) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not talents[classtable.Warbreaker]) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and (talents[classtable.Warbreaker]) and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (Rage <85) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish') and talents[classtable.Demolish]) and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2 and not debuff[classtable.RavagerDeBuff].up and ( buff[classtable.LethalBlowsBuff].count == 2 or not (MaxDps.tier and MaxDps.tier[32].count >= 4) and not talents[classtable.Battlelord] ) or not talents[classtable.ExecutionersPrecision]) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (talents[classtable.Battlelord] and debuff[classtable.ExecutionersPrecisionDeBuff].count == 2) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (talents[classtable.Battlelord] and cooldown[classtable.Overpower].charges == 2 and Rage <90) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (Rage >= 40 and talents[classtable.ExecutionersPrecision]) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
end
function Arms:colossus_sweep()
    if (MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes')) and cooldown[classtable.SweepingStrikes].ready then
        MaxDps:GlowCooldown(classtable.SweepingStrikes, cooldown[classtable.SweepingStrikes].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd and buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager')) and (cooldown[classtable.ColossusSmash].ready) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not talents[classtable.Warbreaker]) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and (talents[classtable.Warbreaker]) and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish') and talents[classtable.Demolish]) and (buff[classtable.SweepingStrikesBuff].up and debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish') and talents[classtable.Demolish]) and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= 8 and not buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (talents[classtable.FervorofBattle]) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= 5) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (talents[classtable.FervorofBattle]) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
end
function Arms:colossus_aoe()
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (not debuff[classtable.DeepWoundsDeBuff].up) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (not debuff[classtable.RendDeBuff].up) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes')) and cooldown[classtable.SweepingStrikes].ready then
        MaxDps:GlowCooldown(classtable.SweepingStrikes, cooldown[classtable.SweepingStrikes].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and (talents[classtable.Warbreaker]) and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not talents[classtable.Warbreaker]) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and (talents[classtable.Unhinged] or talents[classtable.MercilessBonegrinder]) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish') and talents[classtable.Demolish]) and (buff[classtable.ColossalMightBuff].count >= 6 and talents[classtable.Dreadnaught] or buff[classtable.ColossalMightBuff].count == 10 and talents[classtable.StrengthofArms]) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (talents[classtable.Dreadnaught]) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
end
function Arms:slayer_st()
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (cooldown[classtable.ColossusSmash].remains <= 5 or debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not talents[classtable.Warbreaker]) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and (talents[classtable.Warbreaker]) and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (debuff[classtable.MarkedForExecutionDeBuff].count == 3 or buff[classtable.JuggernautBuff].remains <= gcd * 3 and talents[classtable.Juggernaut] or buff[classtable.SuddenDeathBuff].count == 2 or buff[classtable.SuddenDeathBuff].remains <= gcd * 3) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and (( cooldown[classtable.ColossusSmash].remains >= gcd * 4 or cooldown[classtable.Warbreaker].remains >= gcd * 4 ) or debuff[classtable.ColossusSmashDeBuff].remains >= gcd * 4) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.OpportunistBuff].up or cooldown[classtable.Overpower].charges == 2 and talents[classtable.FierceFollowthrough]) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd * 5) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Arms:slayer_execute()
    if (MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes')) and (targets == 2) and cooldown[classtable.SweepingStrikes].ready then
        MaxDps:GlowCooldown(classtable.SweepingStrikes, cooldown[classtable.SweepingStrikes].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd and not talents[classtable.Bloodletting]) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (cooldown[classtable.ColossusSmash].remains <= 5 or debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and (talents[classtable.Warbreaker]) and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not talents[classtable.Warbreaker]) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.JuggernautBuff].remains <= gcd and talents[classtable.Juggernaut]) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2 and debuff[classtable.ColossusSmashDeBuff].remains >4 or debuff[classtable.ExecutionersPrecisionDeBuff].count == 2 and cooldown[classtable.ColossusSmash].remains >15 or not talents[classtable.ExecutionersPrecision]) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (Rage <85) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.RendDeBuff].remains <2 or ( debuff[classtable.ExecutionersPrecisionDeBuff].count == 2 and buff[classtable.LethalBlowsBuff].count == 2 )) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.OpportunistBuff].up and Rage <80 and buff[classtable.MartialProwessBuff].count <2 or Rage <40 and buff[classtable.MartialProwessBuff].count <2 and talents[classtable.FierceFollowthrough]) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (not talents[classtable.ExecutionersPrecision]) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Arms:slayer_sweep()
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes')) and cooldown[classtable.SweepingStrikes].ready then
        MaxDps:GlowCooldown(classtable.SweepingStrikes, cooldown[classtable.SweepingStrikes].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not talents[classtable.Warbreaker]) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and (talents[classtable.Warbreaker]) and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (debuff[classtable.MarkedForExecutionDeBuff].count == 3) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (talents[classtable.Dreadnaught] or buff[classtable.OpportunistBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (talents[classtable.FervorofBattle]) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= 8 and not buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= 5) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (talents[classtable.FervorofBattle]) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Arms:slayer_aoe()
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (not debuff[classtable.RendDeBuff].up) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes')) and cooldown[classtable.SweepingStrikes].ready then
        MaxDps:GlowCooldown(classtable.SweepingStrikes, cooldown[classtable.SweepingStrikes].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and (talents[classtable.Warbreaker]) and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not talents[classtable.Warbreaker]) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up and buff[classtable.ImminentDemiseBuff].count <3) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (talents[classtable.Dreadnaught] and buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SweepingStrikesBuff].up and debuff[classtable.ExecutionersPrecisionDeBuff].count <2) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (talents[classtable.StrengthofArms] and buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (buff[classtable.SweepingStrikesBuff].up and debuff[classtable.ExecutionersPrecisionDeBuff].count == 2) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (debuff[classtable.MarkedForExecutionDeBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Arms:trinkets()
end
function Arms:variables()
    st_planning = targets == 1
    adds_remain = targets >1
    execute_phase = ( (talents[classtable.Massacre] and true or false) and targethealthPerc <35 ) or targethealthPerc <20
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Pummel, false)
    MaxDps:GlowCooldown(classtable.ThunderousRoar, false)
    MaxDps:GlowCooldown(classtable.ChampionsSpear, false)
    MaxDps:GlowCooldown(classtable.Ravager, false)
    MaxDps:GlowCooldown(classtable.Avatar, false)
    MaxDps:GlowCooldown(classtable.SweepingStrikes, false)
    MaxDps:GlowCooldown(classtable.Bladestorm, false)
end

function Arms:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Charge, 'Charge')) and (( LibRangeCheck and LibRangeCheck:GetRange ( 'target', true ) or 0 ) >10) and cooldown[classtable.Charge].ready then
        if not setSpell then setSpell = classtable.Charge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pummel, 'Pummel')) and (UnitCastingInfo('target') and select(8,UnitCastingInfo('target')) == false) and cooldown[classtable.Pummel].ready then
        MaxDps:GlowCooldown(classtable.Pummel, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    Arms:variables()
    Arms:trinkets()
    if (talents[classtable.Demolish] and targets >2) then
        Arms:colossus_aoe()
    end
    if (talents[classtable.Demolish] and execute_phase) then
        Arms:colossus_execute()
    end
    if (talents[classtable.Demolish] and targets == 2 and not execute_phase) then
        Arms:colossus_sweep()
    end
    if (talents[classtable.Demolish]) then
        Arms:colossus_st()
    end
    if (not talents[classtable.Demolish] and targets >2) then
        Arms:slayer_aoe()
    end
    if (not talents[classtable.Demolish] and execute_phase) then
        Arms:slayer_execute()
    end
    if (not talents[classtable.Demolish] and targets == 2 and not execute_phase) then
        Arms:slayer_sweep()
    end
    if (not talents[classtable.Demolish]) then
        Arms:slayer_st()
    end
end
function Warrior:Arms()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    RagePerc = (Rage / RageMax) * 100
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.AvatarBuff = 107574
    classtable.LethalBlowsBuff = 455485
    classtable.SweepingStrikesBuff = 260708
    classtable.ColossalMightBuff = 440989
    classtable.JuggernautBuff = 383290
    classtable.SuddenDeathBuff = 52437
    classtable.OpportunistBuff = 456120
    classtable.BladestormBuff = 227847
    classtable.MartialProwessBuff = 7384
    classtable.ImminentDemiseBuff = 445606
    classtable.ColossusSmashDeBuff = 208086
    classtable.RendDeBuff = 388539
    classtable.ExecutionersPrecisionDeBuff = 386633
    classtable.RavagerDeBuff = 228920
    classtable.DeepWoundsDeBuff = 262115
    classtable.MarkedForExecutionDeBuff = 445584

    local function debugg()
        talents[classtable.Demolish] = 1
        talents[classtable.Bloodletting] = 1
        talents[classtable.Battlelord] = 1
        talents[classtable.ExecutionersPrecision] = 1
        talents[classtable.FervorofBattle] = 1
        talents[classtable.Unhinged] = 1
        talents[classtable.MercilessBonegrinder] = 1
        talents[classtable.Dreadnaught] = 1
        talents[classtable.StrengthofArms] = 1
        talents[classtable.Juggernaut] = 1
        talents[classtable.FierceFollowthrough] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Arms:precombat()

    Arms:callaction()
    if setSpell then return setSpell end
end
