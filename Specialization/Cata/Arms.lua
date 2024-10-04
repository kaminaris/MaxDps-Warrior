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



local function ClearCDs()
    MaxDps:GlowCooldown(classtable.SweepingStrikes, false)
    MaxDps:GlowCooldown(classtable.Bladestorm, false)
end

function Arms:callaction()
    if (MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap')) and (buff[classtable.ColossusSmashBuff].up) and cooldown[classtable.HeroicLeap].ready then
        if not setSpell then setSpell = classtable.HeroicLeap end
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkerRage, 'BerserkerRage')) and (not buff[classtable.DeadlyCalmBuff].up and cooldown[classtable.DeadlyCalm].remains >1.5 and Rage <= 95) and cooldown[classtable.BerserkerRage].ready then
        if not setSpell then setSpell = classtable.BerserkerRage end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeadlyCalm, 'DeadlyCalm')) and cooldown[classtable.DeadlyCalm].ready then
        if not setSpell then setSpell = classtable.DeadlyCalm end
    end
    if (MaxDps:CheckSpellUsable(classtable.InnerRage, 'InnerRage')) and (not buff[classtable.DeadlyCalmBuff].up and cooldown[classtable.DeadlyCalm].remains >15) and cooldown[classtable.InnerRage].ready then
        if not setSpell then setSpell = classtable.InnerRage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (targetHP >90 or targetHP <= 20) and cooldown[classtable.Recklessness].ready then
        if not setSpell then setSpell = classtable.Recklessness end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stance, 'Stance')) and (not buff[classtable.TasteForBloodBuff].up and debuff[classtable.RendDeBuff].remains >0 and Rage <= 75) and cooldown[classtable.Stance].ready then
        if not setSpell then setSpell = classtable.Stance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stance, 'Stance')) and (not debuff[classtable.RendDeBuff].up) and cooldown[classtable.Stance].ready then
        if not setSpell then setSpell = classtable.Stance end
    end
    if (MaxDps:CheckSpellUsable(classtable.Stance, 'Stance')) and (( buff[classtable.TasteForBloodBuff].up or buff[classtable.OverpowerBuff].up ) and Rage <= 75 and cooldown[classtable.MortalStrike].remains >= 1.5) and cooldown[classtable.Stance].ready then
        if not setSpell then setSpell = classtable.Stance end
    end
    if (MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes')) and (targets >0) and cooldown[classtable.SweepingStrikes].ready then
        MaxDps:GlowCooldown(classtable.SweepingStrikes, cooldown[classtable.SweepingStrikes].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (targets >0) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (not debuff[classtable.RendDeBuff].up) and cooldown[classtable.Rend].ready then
        if not setSpell then setSpell = classtable.Rend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and (targets >0 and not buff[classtable.DeadlyCalmBuff].up and not buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (targetHP >20) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not buff[classtable.ColossusSmashBuff].up) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.ExecutionerTalentBuff].remains <1.5) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (targetHP <= 20 and ( debuff[classtable.RendDeBuff].remains <3 or not buff[classtable.WreckingCrewBuff].up or Rage <= 25 or Rage >= 35 )) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (Rage >90) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.TasteForBloodBuff].up or buff[classtable.OverpowerBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (buff[classtable.ColossusSmashBuff].remains <= 1.5) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and (( Rage >= 35 or buff[classtable.BattleTranceBuff].up or buff[classtable.DeadlyCalmBuff].up )) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (buff[classtable.DeadlyCalmBuff].up) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (Rage >85) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (buff[classtable.InnerRageBuff].up and targetHP >20 and ( Rage >= 60 or ( (MaxDps.tier and MaxDps.tier[13].count >= 2) and Rage >= 50 ) )) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (buff[classtable.InnerRageBuff].up and targetHP <= 20 and ( ( Rage >= 60 or ( (MaxDps.tier and MaxDps.tier[13].count >= 2) and Rage >= 50 ) ) or buff[classtable.BattleTranceBuff].up )) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and (Rage <60) and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
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
    classtable.RecklessnessBuff = 0
    classtable.ColossusSmashBuff = 208086
    classtable.DeadlyCalmBuff = 0
    classtable.TasteForBloodBuff = 0
    classtable.RendDeBuff = 388539
    classtable.OverpowerBuff = 0
    classtable.SweepingStrikesBuff = 260708
    classtable.ExecutionerTalentBuff = 0
    classtable.WreckingCrewBuff = 0
    classtable.BattleTranceBuff = 0
    classtable.InnerRageBuff = 0
    setSpell = nil
    ClearCDs()

    Arms:callaction()
    if setSpell then return setSpell end
end
