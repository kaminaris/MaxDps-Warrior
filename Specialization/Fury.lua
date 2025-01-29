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

local treacherous_transmitter_precombat_cast
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
function Fury:precombat()
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkerStance, 'BerserkerStance')) and cooldown[classtable.BerserkerStance].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BerserkerStance end
    end
    treacherous_transmitter_precombat_cast = 2
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (not MaxDps:CheckEquipped('FyralaththeDreamrender')) and cooldown[classtable.Recklessness].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
end
function Fury:slayer_am_st()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (( not talents[classtable.AngerManagement] and cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] ) or talents[classtable.AngerManagement] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (( buff[classtable.EnrageBuff].up and talents[classtable.TitansTorment] and cooldown[classtable.Avatar].remains <gcd ) or ( buff[classtable.EnrageBuff].up and not talents[classtable.TitansTorment] )) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and not cooldown[classtable.Avatar].ready) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (debuff[classtable.MarkedForExecutionDeBuff].count == 3 or talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <2 or buff[classtable.SuddenDeathBuff].count == 2 and buff[classtable.SuddenDeathBuff].remains <7 or buff[classtable.SuddenDeathBuff].up and buff[classtable.SuddenDeathBuff].remains <2) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and talents[classtable.Bladestorm]) and (buff[classtable.EnrageBuff].up and ( cooldown[classtable.Recklessness].remains >= 9 or cooldown[classtable.Avatar].remains >= 9 )) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize] and buff[classtable.BrutalFinishBuff].up) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (not buff[classtable.EnrageBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and (buff[classtable.OpportunistBuff].up) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (targethealthPerc <35 and talents[classtable.ViciousContempt] and buff[classtable.BloodcrazeBuff].count >= 2) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (cooldown[classtable.RagingBlow].charges <= 1 and Rage >= 115) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (buff[classtable.BloodcrazeBuff].count >3 or SpellCrit >= 85) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
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
function Fury:slayer_ra_st()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (not buff[classtable.EnrageBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (( buff[classtable.EnrageBuff].up and talents[classtable.TitansTorment] and cooldown[classtable.Avatar].remains <gcd ) or ( buff[classtable.EnrageBuff].up and not talents[classtable.TitansTorment] )) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and not cooldown[classtable.Avatar].ready) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and talents[classtable.Bladestorm]) and (buff[classtable.EnrageBuff].up and cooldown[classtable.Avatar].remains >= 9) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (debuff[classtable.MarkedForExecutionDeBuff].count == 3 or talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <2 or buff[classtable.SuddenDeathBuff].count == 2 and buff[classtable.SuddenDeathBuff].remains <7 or buff[classtable.SuddenDeathBuff].up and buff[classtable.SuddenDeathBuff].remains <2) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize] and buff[classtable.BrutalFinishBuff].up) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and (SpellCrit >= 85 or buff[classtable.BloodcrazeBuff].count >= 3) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and (targethealthPerc <35 and talents[classtable.ViciousContempt]) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (Rage >= 115) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
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
function Fury:slayer_am_mt()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (( buff[classtable.EnrageBuff].up and talents[classtable.TitansTorment] and cooldown[classtable.Avatar].remains <gcd ) or ( buff[classtable.EnrageBuff].up and not talents[classtable.TitansTorment] )) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and not cooldown[classtable.Avatar].ready) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
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
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and talents[classtable.Bladestorm]) and (buff[classtable.EnrageBuff].up and cooldown[classtable.Avatar].remains >= 5) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up and debuff[classtable.MarkedForExecutionDeBuff].count == 3) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (not buff[classtable.EnrageBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (buff[classtable.SlaughteringStrikesBuff].count >= 2) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Fury:slayer_ra_mt()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (( not talents[classtable.AngerManagement] and cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment] and buff[classtable.EnrageBuff].up) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (not buff[classtable.EnrageBuff].up and not talents[classtable.TitansTorment]) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (( buff[classtable.EnrageBuff].up and talents[classtable.TitansTorment] and cooldown[classtable.Avatar].remains <gcd ) or ( buff[classtable.EnrageBuff].up and not talents[classtable.TitansTorment] )) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and not cooldown[classtable.Avatar].ready) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and talents[classtable.Bladestorm]) and (buff[classtable.EnrageBuff].up and cooldown[classtable.Avatar].remains >= 9 and buff[classtable.EnrageBuff].remains >3) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (buff[classtable.MeatCleaverBuff].count == 0 and talents[classtable.MeatCleaver]) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <= gcd and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize] and buff[classtable.BrutalFinishBuff].up) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (not buff[classtable.EnrageBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and (targets >= 6) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (targets >= 6) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up and debuff[classtable.MarkedForExecutionDeBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (Rage >115) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and (talents[classtable.SlaughteringStrikes]) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
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
function Fury:thane_am_st()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (talents[classtable.AngerManagement] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (buff[classtable.EnrageBuff].up and ( cooldown[classtable.Avatar].remains <gcd or not talents[classtable.TitansTorment] )) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and not cooldown[classtable.Avatar].ready) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <= gcd and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and talents[classtable.Bladestorm]) and (buff[classtable.EnrageBuff].up and talents[classtable.Unhinged]) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (talents[classtable.ViciousContempt] and targethealthPerc <35 and buff[classtable.BloodcrazeBuff].count >= 2 or not debuff[classtable.RavagerDeBuff].up and buff[classtable.BloodcrazeBuff].count >= 3) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (talents[classtable.AshenJuggernaut]) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Fury:thane_ra_st()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (( not talents[classtable.AngerManagement] and cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] ) or talents[classtable.AngerManagement] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment] and buff[classtable.EnrageBuff].up) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (buff[classtable.EnrageBuff].up and ( cooldown[classtable.Avatar].remains <gcd or not talents[classtable.TitansTorment] )) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and not cooldown[classtable.Avatar].ready) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <= gcd and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and talents[classtable.Bladestorm]) and (buff[classtable.EnrageBuff].up and talents[classtable.Unhinged]) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (not buff[classtable.EnrageBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and (talents[classtable.ViciousContempt] and targethealthPerc <35 or buff[classtable.BloodcrazeBuff].count >= 3) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (Rage >= 115) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (buff[classtable.EnrageBuff].up and not buff[classtable.BurstofPowerBuff].up) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
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
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Fury:thane_am_mt()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (( not talents[classtable.AngerManagement] and cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] ) or talents[classtable.AngerManagement] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (buff[classtable.MeatCleaverBuff].count == 0 and talents[classtable.MeatCleaver]) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and not cooldown[classtable.Avatar].ready) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <= gcd and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and talents[classtable.Bladestorm]) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (targets >= 3) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
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
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Fury:thane_ra_mt()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and ( debuff[classtable.ChampionsMightDeBuff].up or not talents[classtable.ChampionsMight] ) ) or not talents[classtable.TitansTorment] and buff[classtable.EnrageBuff].up) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (buff[classtable.MeatCleaverBuff].count == 0 and talents[classtable.MeatCleaver]) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and not cooldown[classtable.Avatar].ready) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <= gcd and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and talents[classtable.Bladestorm]) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (not buff[classtable.EnrageBuff].up) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (buff[classtable.RecklessnessBuff].up or Rage >115) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Recklessness, false)
    MaxDps:GlowCooldown(classtable.Avatar, false)
    MaxDps:GlowCooldown(classtable.Pummel, false)
    MaxDps:GlowCooldown(classtable.ThunderousRoar, false)
    MaxDps:GlowCooldown(classtable.ChampionsSpear, false)
    MaxDps:GlowCooldown(classtable.OdynsFury, false)
    MaxDps:GlowCooldown(classtable.Bladestorm, false)
    MaxDps:GlowCooldown(classtable.Ravager, false)
end

function Fury:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Pummel, 'Pummel')) and (UnitCastingInfo('target') and select(8,UnitCastingInfo('target')) == false) and cooldown[classtable.Pummel].ready then
        MaxDps:GlowCooldown(classtable.Pummel, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.Charge, 'Charge')) and (( LibRangeCheck and LibRangeCheck:GetRange ( 'target', true ) or 0 ) >10) and cooldown[classtable.Charge].ready then
        if not setSpell then setSpell = classtable.Charge end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >25) and cooldown[classtable.HeroicLeap].ready then
        if not setSpell then setSpell = classtable.HeroicLeap end
    end
    st_planning = targets == 1
    adds_remain = targets >= 5
    execute_phase = ( (talents[classtable.Massacre] and true or false) and targethealthPerc <35 ) or targethealthPerc <20
    if (talents[classtable.SlayersDominance] and talents[classtable.RecklessAbandon] and targets == 1) then
        Fury:slayer_ra_st()
    end
    if (talents[classtable.SlayersDominance] and ( talents[classtable.AngerManagement] or not talents[classtable.RecklessAbandon] ) and targets == 1) then
        Fury:slayer_am_st()
    end
    if (talents[classtable.SlayersDominance] and talents[classtable.RecklessAbandon] and targets >1) then
        Fury:slayer_ra_mt()
    end
    if (talents[classtable.SlayersDominance] and ( talents[classtable.AngerManagement] or not talents[classtable.RecklessAbandon] ) and targets >1) then
        Fury:slayer_am_mt()
    end
    if (not talents[classtable.SlayersDominance] and talents[classtable.RecklessAbandon] and targets == 1) then
        Fury:thane_ra_st()
    end
    if (not talents[classtable.SlayersDominance] and ( talents[classtable.AngerManagement] or not talents[classtable.RecklessAbandon] ) and targets == 1) then
        Fury:thane_am_st()
    end
    if (not talents[classtable.SlayersDominance] and talents[classtable.RecklessAbandon] and targets >1) then
        Fury:thane_ra_mt()
    end
    if (not talents[classtable.SlayersDominance] and ( talents[classtable.AngerManagement] or not talents[classtable.RecklessAbandon] ) and targets >1) then
        Fury:thane_am_mt()
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
    classtable.Bloodbath = 335096
    classtable.CrushingBlow = 335097
    classtable.Bladestorm = MaxDps.Spells[227847] and 227847 or MaxDps.Spells[446035] and 446035 or 227847
    classtable.Execute = MaxDps.Spells[5308] and 5308 or MaxDps.Spells[280735] and 280735 or 5308
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.AvatarBuff = 107574
    classtable.RecklessnessBuff = 1719
    classtable.BloodbathBuff = 461288
    classtable.CrushingBlowBuff = 396752
    classtable.SuddenDeathBuff = 52437
    classtable.EnrageBuff = 184362
    classtable.AshenJuggernautBuff = 392537
    classtable.BladestormBuff = 227847
    classtable.BrutalFinishBuff = 446918
    classtable.OpportunistBuff = 456120
    classtable.BloodcrazeBuff = 393951
    classtable.MeatCleaverBuff = 85739
    classtable.SlaughteringStrikesBuff = 393931
    classtable.BurstofPowerBuff = 437121
    classtable.ChampionsMightDeBuff = 376080
    classtable.OdynsFuryTormentMhDeBuff = 385060
    classtable.MarkedForExecutionDeBuff = 445584
    classtable.RavagerDeBuff = 228920
    classtable.Bloodbath = 335096
    classtable.CrushingBlow = 335097

    local function debugg()
        talents[classtable.TitansTorment] = 1
        talents[classtable.SlayersDominance] = 1
        talents[classtable.RecklessAbandon] = 1
        talents[classtable.AngerManagement] = 1
        talents[classtable.TitanicRage] = 1
        talents[classtable.ChampionsMight] = 1
        talents[classtable.AshenJuggernaut] = 1
        talents[classtable.Bladestorm] = 1
        talents[classtable.Tenderize] = 1
        talents[classtable.ViciousContempt] = 1
        talents[classtable.MeatCleaver] = 1
        talents[classtable.SlaughteringStrikes] = 1
        talents[classtable.Unhinged] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Fury:precombat()

    Fury:callaction()
    if setSpell then return setSpell end
end
