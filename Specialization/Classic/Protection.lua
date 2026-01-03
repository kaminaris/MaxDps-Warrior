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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Rage
local RageMax
local RageDeficit
local RagePerc

local Protection = {}

function Protection:priorityList()
    -- Shield Block whenever off cooldown, if wearing a shield
    if (MaxDps:CheckSpellUsable(classtable.ShieldBlock, 'ShieldBlock')) and cooldown[classtable.ShieldBlock].ready then
        --if not setSpell then setSpell = classtable.ShieldBlock end
        MaxDps:GlowCooldown(classtable.ShieldBlock, cooldown[classtable.ShieldBlock].ready)
    end
    -- Bloodrage if healthy
    if (MaxDps:CheckSpellUsable(classtable.Bloodrage, 'Bloodrage')) and (healthPerc >= 50) and cooldown[classtable.Bloodrage].ready then
        MaxDps:GlowCooldown(classtable.Bloodrage, cooldown[classtable.Bloodrage].ready)
    end
    -- Battle Shout if missing buff
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and (not MaxDps:FindBuffAuraData(classtable.BattleShout).up) and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    -- Demoralizing Shout if enemies missing debuff
    if (MaxDps:CheckSpellUsable(classtable.DemoralizingShout, 'DemoralizingShout')) and (not MaxDps:FindDeBuffAuraData(classtable.DemoralizingShout).up) and cooldown[classtable.DemoralizingShout].ready then
        if not setSpell then setSpell = classtable.DemoralizingShout end
    end
    -- Thunder Clap on hard hitting enemies
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (targets >= 2) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    -- Revenge on block/dodge/parry
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
    -- Shield Slam or Bloodthirst as main attack
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and talents[classtable.Bloodthirst] and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and not talents[classtable.Bloodthirst] and cooldown[classtable.ShieldSlam].ready then
        if not setSpell then setSpell = classtable.ShieldSlam end
    end
    -- Sunder Armor for threat
    if (MaxDps:CheckSpellUsable(classtable.SunderArmor, 'SunderArmor')) and (MaxDps:FindDeBuffAuraData(classtable.SunderArmor).count < 5) and cooldown[classtable.SunderArmor].ready then
        if not setSpell then setSpell = classtable.SunderArmor end
    end
    -- Spam Battle Shout for threat
    --if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready then
    --    if not setSpell then setSpell = classtable.BattleShout end
    --end
    -- Heroic Strike with excess Rage
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (Rage >= 50) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
end

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Bloodrage, false)
    MaxDps:GlowCooldown(classtable.ShieldBlock, false)
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
    classtable.Bloodrage = 2687
    classtable.BattleShout = 11551
    classtable.DemoralizingShout = 11556
    classtable.ThunderClap = 11581
    classtable.Revenge = 6572
    classtable.ShieldSlam = 23922
    classtable.Bloodthirst = 23894
    classtable.SunderArmor = 11597
    classtable.HeroicStrike = 11567

    local function debugg()
    end

    setSpell = nil
    ClearCDs()

    Protection:priorityList()
    if setSpell then return setSpell end
end