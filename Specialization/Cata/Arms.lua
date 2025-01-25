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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Rage
local RageMax
local RageDeficit
local RagePerc

local Arms = {}



local function overpower_now()
    if targethealthPerc>20  and buff[classtable.TasteforBlood].up and buff[classtable.TasteforBlood].remains <= 1.5 then
        return true
    end
    return false
end

local function overpower_filler()
    if ( buff[classtable.TasteforBlood].up or buff[68051].up ) and not cooldown[classtable.MortalStrike].ready and not cooldown[classtable.ColossusSmash].ready and Rage>=5 then
        return true
    end
    return false
end


function Arms:precombat()
    if (MaxDps:CheckSpellUsable(classtable.BattleStance, 'BattleStance')) and cooldown[classtable.BattleStance].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BattleStance end
    end
    if (MaxDps:CheckSpellUsable(classtable.CommandingShout, 'CommandingShout')) and (false and not buff[classtable.MyBattleShoutBuff].up and not buff[classtable.MyCommandingShoutBuff].up) and cooldown[classtable.CommandingShout].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.CommandingShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and (false and not buff[classtable.MyBattleShoutBuff].up and not buff[classtable.MyCommandingShoutBuff].up) and cooldown[classtable.BattleShout].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.Charge, 'Charge')) and cooldown[classtable.Charge].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Charge end
    end
end
function Arms:spread_rend()
    if (MaxDps:CheckSpellUsable(classtable.BattleStance, 'BattleStance')) and (not false and not buff[classtable.BattleStanceBuff].up and not debuff[classtable.RendDeBuff].up) and cooldown[classtable.BattleStance].ready then
        if not setSpell then setSpell = classtable.BattleStance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (not buff[classtable.RendBuff].up) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].up) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
end
function Arms:battle_stance()
    if (MaxDps:CheckSpellUsable(classtable.BattleStance, 'BattleStance')) and (not false and not buff[classtable.BattleStanceBuff].up) and cooldown[classtable.BattleStance].ready then
        if not setSpell then setSpell = classtable.BattleStance end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShatteringThrow, 'ShatteringThrow')) and (false) and cooldown[classtable.ShatteringThrow].ready then
        if not setSpell then setSpell = classtable.ShatteringThrow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (not buff[classtable.RendBuff].up) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (overpower_now() or overpower_filler()) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkerStance, 'BerserkerStance')) and (not false and not buff[classtable.BerserkerStanceBuff].up) and cooldown[classtable.BerserkerStance].ready then
        if not setSpell then setSpell = classtable.BerserkerStance end
    end
end
function Arms:berserker_stance()
    if (not debuff[classtable.RendDeBuff].up or overpower_now()) then
        Arms:battle_stance()
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (( targethealthPerc >20 or buff[classtable.SlaughterBuff].remains <= 1.5 or talents[classtable.LambsTotheSlaughter] and debuff[classtable.RendDeBuff].up and debuff[classtable.RendDeBuff].remains <3 or (talents[classtable.WreckingCrew] and true or false) and not buff[classtable.EnrageBuff].up )) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (targets >= 4) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (targethealthPerc <20) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (overpower_filler()) then
        Arms:battle_stance()
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (ttd <= 1.5) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and (targethealthPerc >20 and ( cooldown[classtable.MortalStrike].remains >= 0.5 and cooldown[classtable.ColossusSmash].remains >= 0.5 )) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkerRage, 'BerserkerRage')) and cooldown[classtable.BerserkerRage].ready then
        if not setSpell then setSpell = classtable.BerserkerRage end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and (false and Rage <30) and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.CommandingShout, 'CommandingShout')) and (false and Rage <30) and cooldown[classtable.CommandingShout].ready then
        if not setSpell then setSpell = classtable.CommandingShout end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Pummel, false)
end

function Arms:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SunderArmor, 'SunderArmor')) and (( not MaxDps:HasGlyphEnabled(classtable.ColossusSmashGlyph) or cooldown[classtable.ColossusSmash].remains ) and ( false and ttd >( ( 3 - debuff[classtable.SunderArmorDeBuff].count ) * ( 1.5 + 1 ) ) + 3 and ( not debuff[classtable.MajorArmorReductionDeBuff].up or ( debuff[classtable.SunderArmorDeBuff].up and debuff[classtable.SunderArmorDeBuff].count <3 ) or debuff[classtable.SunderArmorDeBuff].remains <1.5 ) )) and cooldown[classtable.SunderArmor].ready then
        if not setSpell then setSpell = classtable.SunderArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (MaxDps:HasGlyphEnabled(classtable.ColossusSmashGlyph) and ( false and ttd >( ( 3 - debuff[classtable.SunderArmorDeBuff].count ) * ( 1.5 + 1 ) ) + 3 and ( not debuff[classtable.MajorArmorReductionDeBuff].up or ( debuff[classtable.SunderArmorDeBuff].up and debuff[classtable.SunderArmorDeBuff].count <3 ) or debuff[classtable.SunderArmorDeBuff].remains <1.5 ) )) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pummel, 'Pummel')) and cooldown[classtable.Pummel].ready then
        MaxDps:GlowCooldown(classtable.Pummel, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (targets >2 and (talents[classtable.BloodandThunder] and true or false)) then
        Arms:spread_rend()
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and (targets >2) and cooldown[classtable.Bladestorm].ready then
        if not setSpell then setSpell = classtable.Bladestorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes')) and (targets >1) and cooldown[classtable.SweepingStrikes].ready then
        if not setSpell then setSpell = classtable.SweepingStrikes end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (debuff[classtable.RendDeBuff].up) and cooldown[classtable.Recklessness].ready then
        if not setSpell then setSpell = classtable.Recklessness end
    end
    if (MaxDps:CheckSpellUsable(classtable.InnerRage, 'InnerRage')) and (debuff[classtable.RendDeBuff].up) and cooldown[classtable.InnerRage].ready then
        if not setSpell then setSpell = classtable.InnerRage end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeadlyCalm, 'DeadlyCalm')) and (debuff[classtable.RendDeBuff].up and ( timeInCombat <119 or ( timeInCombat >= 119 and ttd >130 ) or ( ttd <130 and targethealthPerc ) )) and cooldown[classtable.DeadlyCalm].ready then
        if not setSpell then setSpell = classtable.DeadlyCalm end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (( targets == 1 or buff[classtable.SweepingStrikesBuff].up ) and ( Rage >= 60 or buff[classtable.DeadlyCalmBuff].up or buff[classtable.BattleTranceBuff].up or ( cooldown[classtable.DeadlyCalm].remains <1 and not cooldown[classtable.Recklessness].remains <1 and Rage >30 and not ttd <130 ) )) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (targets >1 and not buff[classtable.SweepingStrikesBuff].up and ( Rage >= 60 or buff[classtable.DeadlyCalmBuff].up or buff[classtable.BattleTranceBuff].up or ( cooldown[classtable.DeadlyCalm].remains <1 and not cooldown[classtable.Recklessness].remains <1 and Rage >30 and not ttd <130 ) )) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (( buff[classtable.BattleStanceBuff].up or false ) and ( not debuff[classtable.RendDeBuff].up or overpower_now() )) then
        Arms:battle_stance()
    end
    if (( false or buff[classtable.BerserkerStanceBuff].up )) then
        Arms:berserker_stance()
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkerStance, 'BerserkerStance')) and (not false and not buff[classtable.BerserkerStanceBuff].up and buff[classtable.TasteForBloodPredictionBuff].remains >1) and cooldown[classtable.BerserkerStance].ready then
        if not setSpell then setSpell = classtable.BerserkerStance end
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
    classtable.Execute = MaxDps.Spells[5308] and 5308 or MaxDps.Spells[280735] and 280735 or 5308
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.RendDeBuff = 94009
    classtable.ColossusSmashDeBuff = 86346
    classtable.BattleStance = 2457
    classtable.CommandingShout = 469
    classtable.BattleShout = 6673
    classtable.Charge = 100
    classtable.Rend = 772
    classtable.ThunderClap = 6343
    classtable.ShatteringThrow = 64382
    classtable.Overpower = 7384
    classtable.BerserkerStance = 2458
    classtable.MortalStrike = 12294
    classtable.Whirlwind = 1680
    classtable.ColossusSmash = 86346
    classtable.Execute = 5308
    classtable.Slam = 23922
    classtable.BerserkerRage = 18499
    classtable.SunderArmor = 7386
    classtable.Pummel = 6552
    classtable.Bladestorm = 46924
    classtable.SweepingStrikes = 12328
    classtable.Recklessness = 1719
    classtable.InnerRage = 1134
    classtable.DeadlyCalm = 85730
    classtable.HeroicStrike = 78
    classtable.Cleave = 845
    classtable.ColossusSmashGlyph = 89003
    classtable.ColossusSmashGlyph = 89003

    local function debugg()
        talents[classtable.BloodandThunder] = 1
        talents[classtable.LambsTotheSlaughter] = 1
        talents[classtable.WreckingCrew] = 1
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
