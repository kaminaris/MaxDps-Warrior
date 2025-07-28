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

local Arms = {}

function Arms:precombat()
    --if (MaxDps:CheckSpellUsable(classtable.Stance, 'Stance')) and cooldown[classtable.Stance].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.Stance end
    --end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Recklessness, false)
    MaxDps:GlowCooldown(classtable.Shockwave, false)
    MaxDps:GlowCooldown(classtable.Bladestorm, false)
    MaxDps:GlowCooldown(classtable.BerserkerRage, false)
    MaxDps:GlowCooldown(classtable.SkullBanner, false)
end

function Arms:single()
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (( ( debuff[classtable.ColossusSmashDeBuff].remains >= 5 or cooldown[classtable.ColossusSmash].remains <= 4 ) and ( targethealthPerc <20 or ttd >315 ) ) or ttd <= 18) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
        MaxDps:GlowCooldown(classtable.SkullBanner, cooldown[classtable.SkullBanner].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkerRage, 'BerserkerRage')) and (not buff[classtable.EnrageBuff].up) and cooldown[classtable.BerserkerRage].ready then
        --if not setSpell then setSpell = classtable.BerserkerRage end
        MaxDps:GlowCooldown(classtable.BerserkerRage, true)
    end
    --if (MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap')) and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.HeroicLeap].ready then
    --    if not setSpell then setSpell = classtable.HeroicLeap end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.DeadlyCalm, 'DeadlyCalm')) and (Rage >= 40) and cooldown[classtable.DeadlyCalm].ready then
    --    if not setSpell then setSpell = classtable.DeadlyCalm end
    --end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (( ( buff[classtable.TasteForBloodBuff].up and buff[classtable.TasteForBloodBuff].remains <= 2 ) or ( buff[classtable.TasteForBloodBuff].count == 5 and buff[classtable.OverpowerBuff].up ) or ( buff[classtable.TasteForBloodBuff].up and debuff[classtable.ColossusSmashDeBuff].remains <= 2 and not cooldown[classtable.ColossusSmash].ready ) or buff[classtable.DeadlyCalmBuff].up or Rage >110 ) and targethealthPerc >= 20 and debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not talents[classtable.Warbreaker] and debuff[classtable.ColossusSmashDeBuff].remains <= 1.5) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.OverpowerBuff].up) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shockwave, 'Shockwave') and talents[classtable.Shockwave]) and ((talents[classtable.Shockwave] and true or false)) and cooldown[classtable.Shockwave].ready then
        MaxDps:GlowCooldown(classtable.Shockwave, cooldown[classtable.Shockwave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DragonRoar, 'DragonRoar') and talents[classtable.DragonRoar]) and ((talents[classtable.DragonRoar] and true or false)) and cooldown[classtable.DragonRoar].ready then
        if not setSpell then setSpell = classtable.DragonRoar end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and (( Rage >= 70 or debuff[classtable.ColossusSmashDeBuff].up ) and targethealthPerc >= 20) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicThrow, 'HeroicThrow')) and cooldown[classtable.HeroicThrow].ready then
        if not setSpell then setSpell = classtable.HeroicThrow end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and (Rage <70 and not debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and talents[classtable.Bladestorm]) and ((talents[classtable.Bladestorm] and true or false) and cooldown[classtable.ColossusSmash].remains >= 5 and not debuff[classtable.ColossusSmashDeBuff].up and cooldown[classtable.Bloodthirst].remains >= 2 and targethealthPerc >= 20) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and (targethealthPerc >= 20) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.ImpendingVictory, 'ImpendingVictory') and talents[classtable.ImpendingVictory]) and ((talents[classtable.ImpendingVictory] and true or false) and targethealthPerc >= 20) and cooldown[classtable.ImpendingVictory].ready then
        if not setSpell then setSpell = classtable.ImpendingVictory end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and (Rage <70) and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
    end
end

function Arms:aoe()
    -- Maintain Deep Wounds with Thunder Clap
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.DeepWoundsDeBuff].refreshable or MaxDps:DebuffCounter(classtable.DeepWoundsDeBuff) < targets ) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end

    -- Maintain Sweeping Strikes
    if (MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes')) and (not buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.SweepingStrikes].ready then
        if not setSpell then setSpell = classtable.SweepingStrikes end
    end

    -- Cast Bladestorm
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and (talents[classtable.Bladestorm] and cooldown[classtable.Recklessness].ready and cooldown[classtable.SkullBanner].ready and cooldown[classtable.BattleShout].ready) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
        MaxDps:GlowCooldown(classtable.SkullBanner, cooldown[classtable.SkullBanner].ready)
    end

    -- Cast Mortal Strike
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end

    -- Cast Colossus Smash if not up on the target
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end

    -- Cast Slam when Colossus Smash is up on the target
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end

    -- Cast Slam outside Colossus Smash if Rage > 50
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and (Rage > 50 and not debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end

    -- Cast Overpower
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end

    -- Cast Dragon Roar
    if (MaxDps:CheckSpellUsable(classtable.DragonRoar, 'DragonRoar')) and (talents[classtable.DragonRoar]) and cooldown[classtable.DragonRoar].ready then
        if not setSpell then setSpell = classtable.DragonRoar end
    end

    -- Cast Heroic Leap during Colossus Smash if not needed for movement
    --if (MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap')) and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.HeroicLeap].ready then
    --    if not setSpell then setSpell = classtable.HeroicLeap end
    --end

    -- Cast Cleave if Rage will get capped
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (Rage >= RageMax - 10) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
end

function Arms:callaction()
    if targets > 1 then
        Arms:aoe()
    end
    Arms:single()
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

    classtable.SkullBanner = 114207

    classtable.ColossusSmashDeBuff = 86346
    classtable.DeepWoundsDeBuff = 115767
    classtable.OverpowerBuff = 60503
    classtable.TasteForBloodBuff = 60503
    classtable.SweepingStrikesBuff = 12328

    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
        talents[classtable.Shockwave] = 1
        talents[classtable.DragonRoar] = 1
        talents[classtable.Bladestorm] = 1
        talents[classtable.ImpendingVictory] = 1
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
