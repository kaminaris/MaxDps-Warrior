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

local Fury = {}

function Fury:precombat()
    --if (MaxDps:CheckSpellUsable(classtable.Stance, 'Stance')) and cooldown[classtable.Stance].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.Stance end
    --end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Recklessness, false)
    MaxDps:GlowCooldown(classtable.Shockwave, false)
    MaxDps:GlowCooldown(classtable.Bladestorm, false)
    MaxDps:GlowCooldown(classtable.BerserkerRage, false)
end

function Fury:single()
    -- Bloodthirst if Raging Blow charges < 2
    if MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst') and buff[classtable.RagingBlowBuff].count < 2 and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end

    -- Colossus Smash if not up
    if MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash') and not debuff[classtable.ColossusSmashDeBuff].up and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end

    -- Berserker Rage during Colossus Smash if < 2 Raging Blow charges
    if MaxDps:CheckSpellUsable(classtable.BerserkerRage, 'BerserkerRage') and debuff[classtable.ColossusSmashDeBuff].up and buff[classtable.RagingBlowBuff].count < 2 and cooldown[classtable.BerserkerRage].ready then
        MaxDps:GlowCooldown(classtable.BerserkerRage, true)
    end

    -- Raging Blow during Colossus Smash
    if MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow') and debuff[classtable.ColossusSmashDeBuff].up and buff[classtable.RagingBlowBuff].count > 0 and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end

    -- Heroic Strike during Colossus Smash if Rage > 50
    if MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike') and debuff[classtable.ColossusSmashDeBuff].up and Rage > 50 and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end

    -- Raging Blow outside of Colossus Smash if 2 charges
    if MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow') and not debuff[classtable.ColossusSmashDeBuff].up and buff[classtable.RagingBlowBuff].count == 2 and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end

    -- Berserker Rage outside Colossus Smash if not Enraged
    if MaxDps:CheckSpellUsable(classtable.BerserkerRage, 'BerserkerRage') and not debuff[classtable.ColossusSmashDeBuff].up and not buff[classtable.EnrageBuff].up and cooldown[classtable.BerserkerRage].ready then
        MaxDps:GlowCooldown(classtable.BerserkerRage, true)
    end

    -- Wild Strike with Bloodsurge
    if MaxDps:CheckSpellUsable(classtable.WildStrike, 'WildStrike') and buff[classtable.BloodsurgeBuff].up and cooldown[classtable.WildStrike].ready then
        if not setSpell then setSpell = classtable.WildStrike end
    end

    -- Wild Strike without Bloodsurge
    if MaxDps:CheckSpellUsable(classtable.WildStrike, 'WildStrike') and not buff[classtable.BloodsurgeBuff].up and cooldown[classtable.WildStrike].ready then
        if not setSpell then setSpell = classtable.WildStrike end
    end

    -- Battle Shout (rage generator fallback)
    if MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout') and Rage < 70 and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
    end

    -- Heroic Strike if Rage would cap
    if MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike') and Rage >= 110 and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end

    ---- Heroic Leap during Colossus Smash (not for movement)
    --if MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap') and debuff[classtable.ColossusSmashDeBuff].up and cooldown[classtable.HeroicLeap].ready then
    --    if not setSpell then setSpell = classtable.HeroicLeap end
    --end
end

function Fury:aoe()
    -- Cast Berserker Rage if Enrage is missing
    if (MaxDps:CheckSpellUsable(classtable.BerserkerRage, 'BerserkerRage')) and (not buff[classtable.EnrageBuff].up) and cooldown[classtable.BerserkerRage].ready then
        MaxDps:GlowCooldown(classtable.BerserkerRage, true)
    end

    -- Cast Bloodthirst unless you have 2 charges of Raging Blow
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (buff[classtable.RagingBlowBuff].count < 2) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end

    -- Cast Whirlwind until you have an adequate amount of Meat Cleaver stacks
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (buff[classtable.MeatCleaverBuff].count < 3) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end

    -- Cast Colossus Smash
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end

    -- Cast Raging Blow
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and (buff[classtable.RagingBlowBuff].up) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end

    -- Cast Wild Strike with Bloodsurge
    if (MaxDps:CheckSpellUsable(classtable.WildStrike, 'WildStrike')) and (buff[classtable.BloodsurgeBuff].up) and cooldown[classtable.WildStrike].ready then
        if not setSpell then setSpell = classtable.WildStrike end
    end

    -- Cast Whirlwind on 3+ targets for damage if you already have an adequate amount of Meat Cleaver stacks
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (targets >= 3 and buff[classtable.MeatCleaverBuff].count >= 3) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end

    -- Cast Cleave if Rage will get capped
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (Rage >= RageMax - 10) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
end

function Fury:callaction()
    if targets > 1 then
        Fury:aoe()
    end
    Fury:single()
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    classtable.BloodsurgeBuff = 46916
    classtable.ColossusSmashDeBuff = 86346
    classtable.EnrageBuff = 12880
    classtable.RagingBlowBuff = 131116
    classtable.BloodsurgeBuff = 46916
    classtable.MeatCleaverBuff = 12950

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

    Fury:precombat()

    Fury:callaction()
    if setSpell then return setSpell end
end
