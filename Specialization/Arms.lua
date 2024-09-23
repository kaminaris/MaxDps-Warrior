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

local trinket_one_exclude
local trinket_two_exclude
local trinket_one_sync
local trinket_two_sync
local trinket_one_buffs
local trinket_two_buffs
local trinket_priority
local trinket_one_manual
local trinket_two_manual
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
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and cooldown[classtable.ChampionsSpear].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager') and (cooldown[classtable.ColossusSmash].remains <= gcd) and cooldown[classtable.Ravager].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and (math.huge >15) and cooldown[classtable.Avatar].ready)
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish')) and cooldown[classtable.Demolish].ready then
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
    MaxDps:GlowCooldown(classtable.SweepingStrikes,MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes') and (targets == 2) and cooldown[classtable.SweepingStrikes].ready)
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd and not talents[classtable.Bloodletting]) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and cooldown[classtable.ChampionsSpear].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager') and (cooldown[classtable.ColossusSmash].remains <= gcd) and cooldown[classtable.Ravager].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and cooldown[classtable.Avatar].ready)
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish')) and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2 and not debuff[classtable.RavagerDeBuff].duration and ( buff[classtable.LethalBlowsBuff].count == 2 or not (MaxDps.tier and MaxDps.tier[1].count >= 4) )) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (Rage >= 40) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
end
function Arms:colossus_sweep()
    MaxDps:GlowCooldown(classtable.SweepingStrikes,MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes') and cooldown[classtable.SweepingStrikes].ready)
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd and buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and cooldown[classtable.ChampionsSpear].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager') and (cooldown[classtable.ColossusSmash].ready) and cooldown[classtable.Ravager].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and cooldown[classtable.Avatar].ready)
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (cooldown[classtable.Overpower].charges == 2 and talents[classtable.Dreadnaught] or buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish')) and (buff[classtable.SweepingStrikesBuff].up and debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (not buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish')) and (buff[classtable.AvatarBuff].up or debuff[classtable.ColossusSmashDeBuff].up and cooldown[classtable.Avatar].remains >= 35) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.RecklessnessWarlordsTormentBuff].up or buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (cooldown[classtable.Overpower].charges == 2 or buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= 8 and not buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= 5) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (talents[classtable.FervorofBattle]) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (talents[classtable.FervorofBattle]) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
end
function Arms:colossus_aoe()
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (buff[classtable.CollateralDamageBuff].up and buff[classtable.MercilessBonegrinderBuff].up) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (not debuff[classtable.RendDeBuff].duration) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and cooldown[classtable.Avatar].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager') and cooldown[classtable.Ravager].ready)
    MaxDps:GlowCooldown(classtable.SweepingStrikes,MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes') and cooldown[classtable.SweepingStrikes].ready)
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and (talents[classtable.Unhinged] or talents[classtable.MercilessBonegrinder]) and cooldown[classtable.Bladestorm].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and cooldown[classtable.ChampionsSpear].ready)
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and (talents[classtable.Unhinged]) and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
end
function Arms:slayer_st()
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and cooldown[classtable.ChampionsSpear].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and (cooldown[classtable.ColossusSmash].remains <= 5 or debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Avatar].ready)
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (debuff[classtable.MarkedForExecutionDeBuff].count == 3 or buff[classtable.JuggernautBuff].remains <= gcd * 3 or buff[classtable.SuddenDeathBuff].count == 2) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and (cooldown[classtable.ColossusSmash].remains >= gcd * 4 or buff[classtable.ColossusSmashBuff].remains >= gcd * 4) and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.OpportunistBuff].up) and cooldown[classtable.Overpower].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (not buff[classtable.MartialProwessBuff].up) and cooldown[classtable.Cleave].ready then
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
    MaxDps:GlowCooldown(classtable.SweepingStrikes,MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes') and (targets == 2) and cooldown[classtable.SweepingStrikes].ready)
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd and not talents[classtable.Bloodletting]) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and cooldown[classtable.ChampionsSpear].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and (cooldown[classtable.ColossusSmash].remains <= 5 or debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Avatar].ready)
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.JuggernautBuff].remains <= gcd) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2 and debuff[classtable.ColossusSmashDeBuff].remains >4 or debuff[classtable.ExecutionersPrecisionDeBuff].count == 2 and cooldown[classtable.ColossusSmash].remains >15 or not talents[classtable.ExecutionersPrecision]) and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (Rage <85) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.RendDeBuff].remains <2 or ( debuff[classtable.ExecutionersPrecisionDeBuff].count == 2 and buff[classtable.LethalBlowsBuff].count == 2 )) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.OpportunistBuff].up and Rage <80 and buff[classtable.MartialProwessBuff].count <2) and cooldown[classtable.Overpower].ready then
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
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.SweepingStrikes,MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes') and cooldown[classtable.SweepingStrikes].ready)
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and cooldown[classtable.ChampionsSpear].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and cooldown[classtable.Avatar].ready)
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (debuff[classtable.MarkedForExecutionDeBuff].count == 3) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and cooldown[classtable.Bladestorm].ready)
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
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (not debuff[classtable.RendDeBuff].duration) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    MaxDps:GlowCooldown(classtable.SweepingStrikes,MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes') and cooldown[classtable.SweepingStrikes].ready)
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and cooldown[classtable.Avatar].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and cooldown[classtable.ChampionsSpear].ready)
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        if not setSpell then setSpell = classtable.Warbreaker end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up and buff[classtable.ImminentDemiseBuff].count <3) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        if not setSpell then setSpell = classtable.Skullsplitter end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SweepingStrikesBuff].up and debuff[classtable.ExecutionersPrecisionDeBuff].count <2) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
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
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (talents[classtable.Dreadnaught]) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
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
    st_planning = targets == 1 and ( math.huge >15 or (targets <2) )
    adds_remain = targets >= 2 and ( (targets <2) or (targets >1) and targets >5 )
    execute_phase = ( talents[classtable.Massacre] and targetHP <35 ) or targetHP <20
end

function Arms:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Charge, 'Charge')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >10) and cooldown[classtable.Charge].ready then
        if not setSpell then setSpell = classtable.Charge end
    end
    MaxDps:GlowCooldown(classtable.Pummel,MaxDps:CheckSpellUsable(classtable.Pummel, 'Pummel') and (UnitCastingInfo('target') and select(8,UnitCastingInfo('target')) == false) and ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
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
    classtable.RendDeBuff = 388539
    classtable.ColossusSmashDeBuff = 208086
    classtable.ExecutionersPrecisionDeBuff = 386633
    classtable.RavagerDeBuff = 0
    classtable.LethalBlowsBuff = 0
    classtable.SweepingStrikesBuff = 260708
    classtable.AvatarBuff = 107574
    classtable.RecklessnessWarlordsTormentBuff = 1719
    classtable.CollateralDamageBuff = 334783
    classtable.MercilessBonegrinderBuff = 383316
    classtable.MarkedForExecutionDeBuff = 445584
    classtable.JuggernautBuff = 383290
    classtable.SuddenDeathBuff = 52437
    classtable.ColossusSmashBuff = 208086
    classtable.OpportunistBuff = 456120
    classtable.MartialProwessBuff = 7384
    classtable.BladestormBuff = 227847
    classtable.ImminentDemiseBuff = 445606
    setSpell = nil

    Arms:precombat()

    Arms:callaction()
    if setSpell then return setSpell end
end
