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
    if targethealthPerc <20 then
        -- Colossus Smash if debuff is not up already
        if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.ColossusSmash].ready then
            if not setSpell then setSpell = classtable.ColossusSmash end
        end
        --Mortal Strike
        if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
            if not setSpell then setSpell = classtable.MortalStrike end
        end
        --Execute
        if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
            if not setSpell then setSpell = classtable.Execute end
        end
        -- Overpower costs 0 Rage thanks to Sudden Death
        if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.SuddenExecuteBuff].up) and cooldown[classtable.Overpower].ready then
            if not setSpell then setSpell = classtable.Overpower end
        end
        --Dragon Roar if you took this
        if (MaxDps:CheckSpellUsable(classtable.DragonRoar, 'DragonRoar')) and (talents[classtable.DragonRoar]) and cooldown[classtable.DragonRoar].ready then
            --if not setSpell then setSpell = classtable.DragonRoar end
            MaxDps:GlowCooldown(classtable.DragonRoar, cooldown[classtable.DragonRoar].ready)
            MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
            MaxDps:GlowCooldown(classtable.SkullBanner, cooldown[classtable.SkullBanner].ready)
        end
        --Battle Shout or Commanding Shout
        if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready then
            if not setSpell then setSpell = classtable.BattleShout end
        end
        if (MaxDps:CheckSpellUsable(classtable.CommandingShout, 'CommandingShout')) and cooldown[classtable.CommandingShout].ready then
            if not setSpell then setSpell = classtable.CommandingShout end
        end
    else
        if (not debuff[classtable.ColossusSmashDeBuff].up) then
            -- Colossus Smash use as soon as its available
            if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and cooldown[classtable.ColossusSmash].ready then
                if not setSpell then setSpell = classtable.ColossusSmash end
            end
            --Bladestorm / Dragon Roar
            if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and cooldown[classtable.Bladestorm].ready then
                --if not setSpell then setSpell = classtable.Bladestorm end
                MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
                MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
                MaxDps:GlowCooldown(classtable.SkullBanner, cooldown[classtable.SkullBanner].ready)
            end
            if (MaxDps:CheckSpellUsable(classtable.DragonRoar, 'DragonRoar')) and (talents[classtable.DragonRoar]) and cooldown[classtable.DragonRoar].ready then
                --if not setSpell then setSpell = classtable.DragonRoar end
                MaxDps:GlowCooldown(classtable.DragonRoar, cooldown[classtable.DragonRoar].ready)
                MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
                MaxDps:GlowCooldown(classtable.SkullBanner, cooldown[classtable.SkullBanner].ready)
            end
            --Mortal Strike
            if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
                if not setSpell then setSpell = classtable.MortalStrike end
            end
            -- Overpower
            if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
                if not setSpell then setSpell = classtable.Overpower end
            end
            -- Slam if you have over 80 Rage
            if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and (Rage > 80) and cooldown[classtable.Slam].ready then
                if not setSpell then setSpell = classtable.Slam end
            end
            --Battle Shout or Commanding Shout
            if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready then
                if not setSpell then setSpell = classtable.BattleShout end
            end
            if (MaxDps:CheckSpellUsable(classtable.CommandingShout, 'CommandingShout')) and cooldown[classtable.CommandingShout].ready then
                if not setSpell then setSpell = classtable.CommandingShout end
            end
            --Heroic Strike if you are Rage capped
            if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (Rage >= 100) and cooldown[classtable.HeroicStrike].ready then
                if not setSpell then setSpell = classtable.HeroicStrike end
            end
        end
        if (debuff[classtable.ColossusSmashDeBuff].up) then
            --Mortal Strike
            if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
                if not setSpell then setSpell = classtable.MortalStrike end
            end
            -- Slam
            if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
                if not setSpell then setSpell = classtable.Slam end
            end
            -- Overpower
            if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
                if not setSpell then setSpell = classtable.Overpower end
            end
            --Heroic Throw
            if (MaxDps:CheckSpellUsable(classtable.HeroicThrow, 'HeroicThrow')) and cooldown[classtable.HeroicThrow].ready then
                if not setSpell then setSpell = classtable.HeroicThrow end
            end
            --Heroic Leap
            if (MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap')) and cooldown[classtable.HeroicLeap].ready then
                --if not setSpell then setSpell = classtable.HeroicLeap end
                MaxDps:GlowCooldown(classtable.HeroicLeap, true)
            end
        end
    end
end

function Arms:aoe()
    -- Sweeping Strikes
    if (MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes')) and (not buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.SweepingStrikes].ready then
        if not setSpell then setSpell = classtable.SweepingStrikes end
    end
    -- Thunder Clap use to refresh Deep Wounds on all targets
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.DeepWoundsDeBuff].refreshable or MaxDps:DebuffCounter(classtable.DeepWoundsDeBuff) < targets ) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    -- Bladestorm if you took this talent
    if (MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm')) and (talents[classtable.Bladestorm]) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
        MaxDps:GlowCooldown(classtable.SkullBanner, cooldown[classtable.SkullBanner].ready)
    end
    -- Colossus Smash if debuff is not up already on high health target
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    -- Mortal Strike
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        if not setSpell then setSpell = classtable.MortalStrike end
    end
    -- Slam
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    -- Dragon Roar if you took this talent
    if (MaxDps:CheckSpellUsable(classtable.DragonRoar, 'DragonRoar')) and (talents[classtable.DragonRoar]) and cooldown[classtable.DragonRoar].ready then
        if not setSpell then setSpell = classtable.DragonRoar end
    end
    --Heroic Leap
    if (MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap')) and cooldown[classtable.HeroicLeap].ready then
        --if not setSpell then setSpell = classtable.HeroicLeap end
        MaxDps:GlowCooldown(classtable.HeroicLeap, true)
    end
    --Battle Shout or Commanding Shout
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.CommandingShout, 'CommandingShout')) and cooldown[classtable.CommandingShout].ready then
        if not setSpell then setSpell = classtable.CommandingShout end
    end
    -- Overpower
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        if not setSpell then setSpell = classtable.Overpower end
    end
end

function Arms:callaction()
    if targets >= 3 then
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
    classtable.EnrageBuff = 12880
    classtable.TasteForBloodBuff = 60503
    classtable.SweepingStrikesBuff = 12328
    classtable.SuddenExecuteBuff = 139958

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
