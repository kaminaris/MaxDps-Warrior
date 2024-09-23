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

local Fury = {}

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
local on_gcd_racials
function Fury:precombat()
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkerStance, 'BerserkerStance')) and cooldown[classtable.BerserkerStance].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BerserkerStance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (not MaxDps:CheckEquipped('FyralaththeDreamrender')) and cooldown[classtable.Recklessness].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Recklessness end
    end
    --MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and (not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready)
end
function Fury:slayer_st()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (( not talents[classtable.AngerManagement] and cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] ) or talents[classtable.AngerManagement] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        if not setSpell then setSpell = classtable.Recklessness end
    end
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready)
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and (( buff[classtable.EnrageBuff].up and talents[classtable.TitansTorment] and cooldown[classtable.Avatar].remains <gcd ) or ( buff[classtable.EnrageBuff].up and not talents[classtable.TitansTorment] )) and cooldown[classtable.ChampionsSpear].ready)
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and cooldown[classtable.Avatar].remains) and cooldown[classtable.OdynsFury].ready then
        if not setSpell then setSpell = classtable.OdynsFury end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (debuff[classtable.MarkedForExecutionDeBuff].count == 3 or ( talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <= gcd and buff[classtable.EnrageBuff].up )) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and (buff[classtable.EnrageBuff].up and cooldown[classtable.Avatar].remains >= 9) and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize] and buff[classtable.BrutalFinishBuff].up) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.AngerManagement]) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and (Rage <100 or targetHP <35 and talents[classtable.ViciousContempt]) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and (Rage <100 and not buff[classtable.OpportunistBuff].up) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.RecklessAbandon]) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up and debuff[classtable.MarkedForExecutionDeBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (not talents[classtable.RecklessAbandon] and buff[classtable.EnrageBuff].up) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (talents[classtable.MeatCleaver]) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Fury:slayer_mt()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (( not talents[classtable.AngerManagement] and cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] ) or talents[classtable.AngerManagement] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        if not setSpell then setSpell = classtable.Recklessness end
    end
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready)
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and (( buff[classtable.EnrageBuff].up and talents[classtable.TitansTorment] and cooldown[classtable.Avatar].remains <gcd ) or ( buff[classtable.EnrageBuff].up and not talents[classtable.TitansTorment] )) and cooldown[classtable.ChampionsSpear].ready)
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and cooldown[classtable.Avatar].remains) and cooldown[classtable.OdynsFury].ready then
        if not setSpell then setSpell = classtable.OdynsFury end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (buff[classtable.MeatCleaverBuff].count == 0 and talents[classtable.MeatCleaver]) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <= gcd and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and (buff[classtable.EnrageBuff].up and cooldown[classtable.Avatar].remains >= 9) and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize] and buff[classtable.BrutalFinishBuff].up) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.AngerManagement]) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.RecklessAbandon]) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up and debuff[classtable.MarkedForExecutionDeBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and (talents[classtable.SlaughteringStrikes]) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Fury:thane_st()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (( not talents[classtable.AngerManagement] and cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] ) or talents[classtable.AngerManagement] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        if not setSpell then setSpell = classtable.Recklessness end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager') and cooldown[classtable.Ravager].ready)
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and (buff[classtable.EnrageBuff].up and ( cooldown[classtable.Avatar].remains <gcd or not talents[classtable.TitansTorment] )) and cooldown[classtable.ChampionsSpear].ready)
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and cooldown[classtable.Avatar].remains) and cooldown[classtable.OdynsFury].ready then
        if not setSpell then setSpell = classtable.OdynsFury end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <= gcd and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and (buff[classtable.EnrageBuff].up and talents[classtable.Unhinged]) and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.AngerManagement]) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.RecklessAbandon]) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (buff[classtable.EnrageBuff].up and ( not buff[classtable.BurstofPowerBuff].up or not talents[classtable.RecklessAbandon] )) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (talents[classtable.MeatCleaver]) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
end
function Fury:thane_mt()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (( not talents[classtable.AngerManagement] and cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] ) or talents[classtable.AngerManagement] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        if not setSpell then setSpell = classtable.Recklessness end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready)
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (buff[classtable.MeatCleaverBuff].count == 0 and talents[classtable.MeatCleaver]) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager') and cooldown[classtable.Ravager].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ChampionsSpear].ready)
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and cooldown[classtable.Avatar].remains) and cooldown[classtable.OdynsFury].ready then
        if not setSpell then setSpell = classtable.OdynsFury end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <= gcd and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and (buff[classtable.EnrageBuff].up) and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.AngerManagement]) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.RecklessAbandon]) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
end
function Fury:trinkets()
end
function Fury:variables()
    st_planning = targets == 1 and ( math.huge >15 or (targets <2) )
    adds_remain = targets >= 2 and ( (targets <2) or (targets >1) and targets >5 )
    execute_phase = ( talents[classtable.Massacre] and targetHP <35 ) or targetHP <20
    on_gcd_racials = not buff[classtable.RecklessnessBuff].up and not buff[classtable.AvatarBuff].up and Rage <80 and not buff[classtable.BloodbathBuff].up and not buff[classtable.CrushingBlowBuff].up and not buff[classtable.SuddenDeathBuff].up and not cooldown[classtable.Bladestorm].ready and ( not cooldown[classtable.Execute].ready or not execute_phase )
end

function Fury:callaction()
    MaxDps:GlowCooldown(classtable.Pummel,MaxDps:CheckSpellUsable(classtable.Pummel, 'Pummel') and (UnitCastingInfo('target') and select(8,UnitCastingInfo('target')) == false) and ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    if (MaxDps:CheckSpellUsable(classtable.Charge, 'Charge')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >10) and cooldown[classtable.Charge].ready then
        if not setSpell then setSpell = classtable.Charge end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap')) and ( (LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >10 ) and cooldown[classtable.HeroicLeap].ready then
        if not setSpell then setSpell = classtable.HeroicLeap end
    end
    Fury:trinkets()
    Fury:variables()
    if (talents[classtable.SlayersDominance] and targets == 1) then
        Fury:slayer_st()
    end
    if (talents[classtable.SlayersDominance] and targets >1) then
        Fury:slayer_mt()
    end
    if (not talents[classtable.SlayersDominance] and targets == 1) then
        Fury:thane_st()
    end
    if (not talents[classtable.SlayersDominance] and targets >1) then
        Fury:thane_mt()
    end
end
function Warrior:Fury()
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
    classtable.Bloodbath = 335096
    classtable.CrushingBlow = 335097
    classtable.Bladestorm = MaxDps.Spells[227847] and 227847 or MaxDps.Spells[446035] and 446035
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.EnrageBuff = 184362
    classtable.ChampionsMightDeBuff = 376080
    classtable.OdynsFuryTormentMhDeBuff = 0
    classtable.MarkedForExecutionDeBuff = 445584
    classtable.AshenJuggernautBuff = 392537
    classtable.BrutalFinishBuff = 0
    classtable.OpportunistBuff = 456120
    classtable.BladestormBuff = MaxDps.Spells[227847] and 227847 or MaxDps.Spells[446035] and 446035
    classtable.MeatCleaverBuff = 85739
    classtable.BurstofPowerBuff = 0
    classtable.RecklessnessBuff = 1719
    classtable.AvatarBuff = 107574
    classtable.BloodbathBuff = 461288
    classtable.CrushingBlowBuff = 396752
    classtable.SuddenDeathBuff = 280776
    setSpell = nil

    Fury:precombat()

    Fury:callaction()
    if setSpell then return setSpell end
end
