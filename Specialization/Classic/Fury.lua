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

local DPS = {}

function DPS:priorityList()
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and (not MaxDps:FindBuffAuraData ( 11551 ) .up) and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathWish, 'DeathWish')) and (targethealthPerc <= 20) and cooldown[classtable.DeathWish].ready then
        MaxDps:GlowCooldown(classtable.DeathWish, cooldown[classtable.DeathWish].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (targethealthPerc <= 20) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    --if (MaxDps:CheckSpellUsable(classtable.MightyRagePotion, 'MightyRagePotion')) and (targethealthPerc <= 20) and cooldown[classtable.MightyRagePotion].ready then
    --    if not setSpell then setSpell = classtable.MightyRagePotion end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Bloodrage, 'Bloodrage')) and (healthPerc >= 50) and cooldown[classtable.Bloodrage].ready then
        MaxDps:GlowCooldown(classtable.Bloodrage, cooldown[classtable.Bloodrage].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SunderArmor, 'SunderArmor')) and (MaxDps:FindDeBuffAuraData ( 11597 ) .count <5 and MaxDps:boss()) and cooldown[classtable.SunderArmor].ready then
        if not setSpell then setSpell = classtable.SunderArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (targethealthPerc <= 20) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (targets >= 3) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and (MaxDps.swingtimer.melee <= 1.6 and talents[12862]) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.SunderArmor, 'SunderArmor')) and (MaxDps:FindDeBuffAuraData ( 11597 ) .refreshable) and cooldown[classtable.SunderArmor].ready then
        if not setSpell then setSpell = classtable.SunderArmor end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (targets <= 2) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Recklessness, false)
    MaxDps:GlowCooldown(classtable.DeathWish, false)
    MaxDps:GlowCooldown(classtable.Bloodrage, false)
end

function Warrior:DPS()
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

    classtable.BattleShout=11551
    classtable.DeathWish=12328
    classtable.Recklessness=1719
    classtable.MightyRagePotion=13442
    classtable.Bloodrage=2687
    classtable.Execute=20662
    classtable.Whirlwind=1680
    classtable.Bloodthirst=23894
    classtable.Slam=11605
    classtable.SunderArmor=11597
    classtable.Cleave=20569
    classtable.HeroicStrike=11567

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    DPS:priorityList()
    if setSpell then return setSpell end
end
