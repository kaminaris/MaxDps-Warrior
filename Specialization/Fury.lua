local _, addonTable = ...
local Warrior = addonTable.Warrior
local MaxDps = _G.MaxDps
if not MaxDps then return end
local LibStub = LibStub
local setSpell

local ceil = ceil
local floor = floor
local fmod = fmod
local format = format
local max = max
local min = min
local pairs = pairs
local select = select
local strsplit = strsplit
local GetTime = GetTime

local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitSpellHaste = UnitSpellHaste
local UnitThreatSituation = UnitThreatSituation
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
local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetUnitSpeed = GetUnitSpeed
local GetCritChance = GetCritChance
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = C_Item.GetItemInfo
local GetItemSpell = C_Item.GetItemSpell
local GetNamePlates = C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates or GetNamePlates
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellInfo
local GetTotemInfo = GetTotemInfo
local IsStealthed = IsStealthed
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local DemonicFuryPT = Enum.PowerType.DemonicFury
local BurningEmbersPT = Enum.PowerType.BurningEmbers
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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Rage
local RageMax
local RageDeficit
local RagePerc
local RageRegen
local RageRegenCombined
local RageTimeToMax

local Fury = {}

local trinket_1_exclude = false
local trinket_2_exclude = false
local trinket_1_sync = false
local trinket_2_sync = false
local trinket_1_buffs = false
local trinket_2_buffs = false
local trinket_priority = 2
local trinket_1_manual = false
local trinket_2_manual = false
local treacherous_transmitter_precombat_cast = 2
local st_planning = false
local adds_remain = false
local execute_phase = false
local on_gcd_racials = false
function Fury:precombat()
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and not buff[classtable.BattleShout].up and cooldown[classtable.BattleShout].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkerStance, 'BerserkerStance')) and not buff[classtable.BerserkerStance].up and cooldown[classtable.BerserkerStance].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BerserkerStance end
    end
    trinket_1_exclude = MaxDps:CheckTrinketNames('TreacherousTransmitter')
    trinket_2_exclude = MaxDps:CheckTrinketNames('TreacherousTransmitter')
    if MaxDps:HasOnUseEffect('13') and (math.fmod(MaxDps:CheckTrinketCooldownDuration('13') , cooldown[classtable.Avatar].duration) == 0 or math.fmod(MaxDps:CheckTrinketCooldownDuration('13') , cooldown[classtable.OdynsFury].duration) == 0) then
        trinket_1_sync = 1
    else
        trinket_1_sync = 0.5
    end
    if MaxDps:HasOnUseEffect('14') and (math.fmod(MaxDps:CheckTrinketCooldownDuration('14') , cooldown[classtable.Avatar].duration) == 0 or math.fmod(MaxDps:CheckTrinketCooldownDuration('14') , cooldown[classtable.OdynsFury].duration) == 0) then
        trinket_2_sync = 1
    else
        trinket_2_sync = 0.5
    end
    trinket_1_buffs = MaxDps:HasOnUseEffect('13') or (true and not trinket_1_exclude)
    trinket_2_buffs = MaxDps:HasOnUseEffect('14') or (true and not trinket_2_exclude)
    if not trinket_1_buffs and trinket_2_buffs or trinket_2_buffs and ((MaxDps:CheckTrinketCooldownDuration('14')%MaxDps:CheckTrinketBuffDuration('14', 'any'))*(1.5 + (MaxDps:HasBuffEffect('14', 'strength') and 1 or 0))*(trinket_2_sync))>((MaxDps:CheckTrinketCooldownDuration('13')%MaxDps:CheckTrinketBuffDuration('13', 'any'))*(1.5 + (MaxDps:HasBuffEffect('13', 'strength') and 1 or 0))*(trinket_1_sync)) then
        trinket_priority = 2
    else
        trinket_priority = 1
    end
    trinket_1_manual = MaxDps:CheckTrinketNames('AlgetharPuzzleBox')
    trinket_2_manual = MaxDps:CheckTrinketNames('AlgetharPuzzleBox')
    treacherous_transmitter_precombat_cast = 2
    if (MaxDps:CheckSpellUsable(classtable.treacherous_transmitter, 'treacherous_transmitter')) and cooldown[classtable.treacherous_transmitter].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.treacherous_transmitter, cooldown[classtable.treacherous_transmitter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (not MaxDps:CheckEquipped('FyralaththeDreamrender')) and cooldown[classtable.Recklessness].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
end
function Fury:slayer()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.AshenJuggernautBuff].up and buff[classtable.AshenJuggernautBuff].remains <= gcd) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].remains <2 and not execute_phase) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and (targets >1) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (cooldown[classtable.Bladestorm].ready and (cooldown[classtable.Avatar].ready or cooldown[classtable.Recklessness].ready or buff[classtable.AvatarBuff].up or buff[classtable.RecklessnessBuff].up) and buff[classtable.EnrageBuff].up) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and (buff[classtable.EnrageBuff].up and (talents[classtable.RecklessAbandon] and cooldown[classtable.Avatar].remains >= 24 or talents[classtable.AngerManagement] and cooldown[classtable.Recklessness].remains >= 15 and (buff[classtable.AvatarBuff].up or cooldown[classtable.Avatar].remains >= 8))) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (targets >= 2 and talents[classtable.MeatCleaver] and buff[classtable.MeatCleaverBuff].count == 0) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize] and buff[classtable.BrutalFinishBuff].up) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (buff[classtable.EnrageBuff].remains <gcd) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].count == 2 and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (debuff[classtable.MarkedForExecutionDeBuff].count >1 and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (targets >1 and (buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage])) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and (cooldown[classtable.RagingBlow].charges == 2 or buff[classtable.BrutalFinishBuff].up and (not debuff[classtable.ChampionsMightDeBuff].up or debuff[classtable.ChampionsMightDeBuff].up and debuff[classtable.ChampionsMightDeBuff].remains >gcd)) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and (buff[classtable.BloodcrazeBuff].count >= 1 or (talents[classtable.Uproar] and debuff[classtable.BloodbathDeBuff].remains <40 and talents[classtable.Bloodborne]) or buff[classtable.EnrageBuff].up and buff[classtable.EnrageBuff].remains <gcd) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and (buff[classtable.BrutalFinishBuff].up and buff[classtable.SlaughteringStrikesBuff].count <5 and (not debuff[classtable.ChampionsMightDeBuff].up or debuff[classtable.ChampionsMightDeBuff].up and debuff[classtable.ChampionsMightDeBuff].remains >gcd)) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (Rage >115) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (execute_phase and debuff[classtable.MarkedForExecutionDeBuff].up and buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (targethealthPerc <35 and talents[classtable.ViciousContempt] and buff[classtable.BrutalFinishBuff].up and buff[classtable.EnrageBuff].up and SpellCrit >= 85 or targets >= 6) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and (buff[classtable.OpportunistBuff].up) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (targethealthPerc <35 and talents[classtable.ViciousContempt] and SpellCrit >= 70) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and (cooldown[classtable.RagingBlow].charges == 2) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage]) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.WreckingThrow, 'WreckingThrow')) and cooldown[classtable.WreckingThrow].ready then
        if not setSpell then setSpell = classtable.WreckingThrow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and (buff[classtable.BladestormBuff].up) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
end
function Fury:thane()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and (targets >1 and buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (buff[classtable.EnrageBuff].up and talents[classtable.ChampionsMight]) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (buff[classtable.MeatCleaverBuff].count == 0 and talents[classtable.MeatCleaver] and targets >= 2) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (buff[classtable.EnrageBuff].up and talents[classtable.MeatCleaver]) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (not buff[classtable.EnrageBuff].up or (talents[classtable.Bladestorm] and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up)) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (talents[classtable.AshenJuggernaut] and buff[classtable.AshenJuggernautBuff].remains <= gcd) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and (buff[classtable.EnrageBuff].up and talents[classtable.Unhinged]) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        if not setSpell then setSpell = classtable.Bloodbath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (Rage >= 115 and talents[classtable.RecklessAbandon] and buff[classtable.RecklessnessBuff].up and buff[classtable.SlaughteringStrikesBuff].count >= 3) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        if not setSpell then setSpell = classtable.CrushingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        if not setSpell then setSpell = classtable.Onslaught end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (talents[classtable.ViciousContempt] and targethealthPerc <35) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and (Rage >= 100) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (targets >1 and (buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage])) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        if not setSpell then setSpell = classtable.Rampage end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (not talents[classtable.MeatCleaver]) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.OdynsFury, 'OdynsFury')) and (buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage]) and cooldown[classtable.OdynsFury].ready then
        MaxDps:GlowCooldown(classtable.OdynsFury, cooldown[classtable.OdynsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and (not talents[classtable.ChampionsMight]) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.WreckingThrow, 'WreckingThrow')) and cooldown[classtable.WreckingThrow].ready then
        if not setSpell then setSpell = classtable.WreckingThrow end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.treacherous_transmitter, false)
    MaxDps:GlowCooldown(classtable.Recklessness, false)
    MaxDps:GlowCooldown(classtable.Avatar, false)
    MaxDps:GlowCooldown(classtable.Pummel, false)
    MaxDps:GlowCooldown(classtable.unyielding_netherprism, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
    MaxDps:GlowCooldown(classtable.bestinslots, false)
    MaxDps:GlowCooldown(classtable.ThunderousRoar, false)
    MaxDps:GlowCooldown(classtable.ChampionsSpear, false)
    MaxDps:GlowCooldown(classtable.Bladestorm, false)
    MaxDps:GlowCooldown(classtable.OdynsFury, false)
    MaxDps:GlowCooldown(classtable.Ravager, false)
end

function Fury:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Charge, 'Charge')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >10) and cooldown[classtable.Charge].ready then
        if not setSpell then setSpell = classtable.Charge end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >25) and cooldown[classtable.HeroicLeap].ready then
        if not setSpell then setSpell = classtable.HeroicLeap end
    end
    if (MaxDps:CheckSpellUsable(classtable.treacherous_transmitter, 'treacherous_transmitter')) and cooldown[classtable.treacherous_transmitter].ready then
        MaxDps:GlowCooldown(classtable.treacherous_transmitter, cooldown[classtable.treacherous_transmitter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Pummel, 'Pummel')) and cooldown[classtable.Pummel].ready then
        MaxDps:GlowCooldown(classtable.Pummel, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.cursed_stone_idol, 'cursed_stone_idol')) and (cooldown[classtable.Avatar].remains <1) and cooldown[classtable.cursed_stone_idol].ready then
    --    if not setSpell then setSpell = classtable.cursed_stone_idol end
    --end
    if (MaxDps:CheckSpellUsable(classtable.unyielding_netherprism, 'unyielding_netherprism')) and (cooldown[classtable.Avatar].remains <= 85) and cooldown[classtable.unyielding_netherprism].ready then
        MaxDps:GlowCooldown(classtable.unyielding_netherprism, cooldown[classtable.unyielding_netherprism].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (trinket_1_buffs and not trinket_1_manual and (not buff[classtable.AvatarBuff].up and MaxDps:CheckTrinketCastTime('13') >0 or not (MaxDps:CheckTrinketCastTime('13') >0)) and buff[classtable.AvatarBuff].up and (trinket_2_exclude or not MaxDps:HasOnUseEffect('14') or MaxDps:CheckTrinketCooldown('14') or trinket_priority == 1) or MaxDps:CheckTrinketBuffDuration('13', 'any') >= ttd) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (trinket_2_buffs and not trinket_2_manual and (not buff[classtable.AvatarBuff].up and MaxDps:CheckTrinketCastTime('14') >0 or not (MaxDps:CheckTrinketCastTime('14') >0)) and buff[classtable.AvatarBuff].up and (trinket_1_exclude or not MaxDps:HasOnUseEffect('13') or MaxDps:CheckTrinketCooldown('13') or trinket_priority == 2) or MaxDps:CheckTrinketBuffDuration('14', 'any') >= ttd) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not trinket_1_buffs and (MaxDps:CheckTrinketCastTime('13') >0 and not buff[classtable.AvatarBuff].up or not (MaxDps:CheckTrinketCastTime('13') >0)) and not trinket_1_manual and (not trinket_1_buffs and (MaxDps:CheckTrinketCooldown('14') or not trinket_2_buffs) or (MaxDps:CheckTrinketCastTime('13') >0 and not buff[classtable.AvatarBuff].up or not (MaxDps:CheckTrinketCastTime('13') >0)) or cooldown[classtable.Avatar].remains >20)) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not trinket_2_buffs and (MaxDps:CheckTrinketCastTime('14') >0 and not buff[classtable.AvatarBuff].up or not (MaxDps:CheckTrinketCastTime('14') >0)) and not trinket_2_manual and (not trinket_2_buffs and (MaxDps:CheckTrinketCooldown('13') or not trinket_1_buffs) or (MaxDps:CheckTrinketCastTime('14') >0 and not buff[classtable.AvatarBuff].up or not (MaxDps:CheckTrinketCastTime('14') >0)) or cooldown[classtable.Avatar].remains >20)) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.main_hand, 'main_hand')) and (not MaxDps:CheckEquipped('FyralaththeDreamrender') and not MaxDps:CheckEquipped('Bestinslots') and (not trinket_1_buffs or MaxDps:CheckTrinketCooldown('13')) and (not trinket_2_buffs or MaxDps:CheckTrinketCooldown('14'))) and cooldown[classtable.main_hand].ready then
        if not setSpell then setSpell = classtable.main_hand end
    end
    if (MaxDps:CheckSpellUsable(classtable.bestinslots, 'bestinslots')) and (ttd >120 and (cooldown[classtable.Avatar].remains >20 and (MaxDps:CheckTrinketCooldown('13') or MaxDps:CheckTrinketCooldown('14')) or cooldown[classtable.Avatar].remains >20 and (not MaxDps:HasOnUseEffect('13') or not MaxDps:HasOnUseEffect('14'))) or ttd <= 120 and targethealthPerc <35 and cooldown[classtable.Avatar].remains >85 or ttd <15) and cooldown[classtable.bestinslots].ready then
        MaxDps:GlowCooldown(classtable.bestinslots, cooldown[classtable.bestinslots].ready)
    end
    st_planning = targets == 1 and (math.huge >15 or not (targets >1))
    adds_remain = targets >= 2 and (not (targets >1) or (targets >1) and targets >5)
    execute_phase = ((talents[classtable.Massacre] and true or false) and targethealthPerc <35) or targethealthPerc <20
    on_gcd_racials = not buff[classtable.RecklessnessBuff].up and not buff[classtable.AvatarBuff].up and Rage <80 and not buff[classtable.SuddenDeathBuff].up and not cooldown[classtable.Bladestorm].ready and (not cooldown[classtable.Execute].ready or not execute_phase)
    if (not talents[classtable.LightningStrikes]) then
        Fury:slayer()
    end
    if (talents[classtable.LightningStrikes]) then
        Fury:thane()
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    local trinket1ID = GetInventoryItemID('player', 13)
    local trinket2ID = GetInventoryItemID('player', 14)
    local MHID = GetInventoryItemID('player', 16)
    classtable.trinket1 = (trinket1ID and select(2,GetItemSpell(trinket1ID)) ) or 0
    classtable.trinket2 = (trinket2ID and select(2,GetItemSpell(trinket2ID)) ) or 0
    classtable.main_hand = (MHID and select(2,GetItemSpell(MHID)) ) or 0
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    RagePerc = (Rage / RageMax) * 100
    RageRegen = GetPowerRegenForPowerType(RagePT)
    RageTimeToMax = RageDeficit / RageRegen
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    classtable.Bloodbath = 335096
    classtable.CrushingBlow = 335097
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.RecklessnessBuff = 1719
    classtable.AvatarBuff = 107574
    classtable.SuddenDeathBuff = 52437
    classtable.AshenJuggernautBuff = 392537
    classtable.EnrageBuff = 184362
    classtable.MeatCleaverBuff = 85739
    classtable.BrutalFinishBuff = 446918
    classtable.BloodcrazeBuff = 393951
    classtable.SlaughteringStrikesBuff = 393931
    classtable.OpportunistBuff = 456120
    classtable.BladestormBuff = 227847
    classtable.MarkedForExecutionDeBuff = 445584
    classtable.ChampionsMightDeBuff = 376080
    classtable.BloodbathDotDeBuff = 113344
    classtable.CrushingBlow = 335097
    classtable.Bloodbath = 335096

    local function debugg()
        talents[classtable.LightningStrikes] = 1
        talents[classtable.RecklessAbandon] = 1
        talents[classtable.AngerManagement] = 1
        talents[classtable.MeatCleaver] = 1
        talents[classtable.Tenderize] = 1
        talents[classtable.TitanicRage] = 1
        talents[classtable.Uproar] = 1
        talents[classtable.Bloodborne] = 1
        talents[classtable.ViciousContempt] = 1
        talents[classtable.ChampionsMight] = 1
        talents[classtable.Bladestorm] = 1
        talents[classtable.AshenJuggernaut] = 1
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
