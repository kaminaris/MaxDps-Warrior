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

local Protection = {}

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Whirlwind, false)
    MaxDps:GlowCooldown(classtable.ShieldBlock, false)
end

function Protection:AoE()
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    --if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and Rage <= 10 and cooldown[classtable.Whirlwind].ready then
    --    --if not setSpell then setSpell = classtable.Whirlwind end
    --    MaxDps:GlowCooldown(classtable.Whirlwind, true)
    --end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and targets >= 5 and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Disarm, 'Disarm')) and cooldown[classtable.Disarm].ready then
        if not setSpell then setSpell = classtable.Disarm end
    end
end

function Protection:Single()
    if (MaxDps:CheckSpellUsable(classtable.ShieldBlock, 'ShieldBlock')) and cooldown[classtable.ShieldBlock].ready then
        --if not setSpell then setSpell = classtable.ShieldBlock end
        MaxDps:GlowCooldown(classtable.ShieldBlock, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and cooldown[classtable.ShieldSlam].ready then
        if not setSpell then setSpell = classtable.ShieldSlam end
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and MaxDps:FindADAuraData(classtable.ExposeArmor).up and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Devastate, 'Devastate')) and cooldown[classtable.Devastate].ready then
        if not setSpell then setSpell = classtable.Devastate end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
end

function Protection:callaction()
    if targets > 1 then
        Protection:AoE()
    else
        Protection:Single()
    end
end

function Warrior:Protection()
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

    classtable.ShieldBlock = 2565
    classtable.ThunderClap = 6343
    classtable.Whirlwind = 1680
    classtable.Disarm = 676
    classtable.Cleave = 845
    classtable.ShieldSlam = 23922
    classtable.Revenge = 6572
    classtable.HeroicStrike = 11564
    classtable.Devastate = 20243
    classtable.ExposeArmor = 7386

    setSpell = nil
    ClearCDs()

    Protection:callaction()
    if setSpell then return setSpell end
end
