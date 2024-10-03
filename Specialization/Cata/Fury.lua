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



local function ClearCDs()
end

function Fury:callaction()
    if (MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap')) and (buff[classtable.ColossusSmashBuff].up) and cooldown[classtable.HeroicLeap].ready then
        if not setSpell then setSpell = classtable.HeroicLeap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and cooldown[classtable.Recklessness].ready then
        if not setSpell then setSpell = classtable.Recklessness end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathWish, 'DeathWish')) and cooldown[classtable.DeathWish].ready then
        if not setSpell then setSpell = classtable.DeathWish end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (target.adds >0) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and (target.adds >0) and cooldown[classtable.Whirlwind].ready then
        if not setSpell then setSpell = classtable.Whirlwind end
    end
    if (MaxDps:CheckSpellUsable(classtable.InnerRage, 'InnerRage')) and (target.adds == 0 and ( ( Rage >= 75 and targetHP >= 20 ) or ( ( buff[classtable.InciteBuff].up or buff[classtable.ColossusSmashBuff].up ) and ( ( Rage >= 40 and targetHP >= 20 ) or ( Rage >= 65 and targetHP <20 ) ) ) )) and cooldown[classtable.InnerRage].ready then
        if not setSpell then setSpell = classtable.InnerRage end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (( Rage >= 85 or ( (MaxDps.tier and MaxDps.tier[13].count >= 2) and buff[classtable.InnerRageBuff].up and Rage >= 75 ) ) and targetHP >= 20) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (buff[classtable.BattleTranceBuff].up) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (( buff[classtable.InciteBuff].up or buff[classtable.ColossusSmashBuff].up ) and ( ( ( Rage >= 50 or ( Rage >= 40 and (MaxDps.tier and MaxDps.tier[13].count >= 2) and buff[classtable.InnerRageBuff].up ) ) and targetHP >= 20 ) or ( ( Rage >= 75 or ( Rage >= 65 and (MaxDps.tier and MaxDps.tier[13].count >= 2) and buff[classtable.InnerRageBuff].up ) ) and targetHP <20 ) )) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.ExecutionerTalentBuff].remains <1.5) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.ExecutionerTalentBuff].count <5) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkerRage, 'BerserkerRage')) and (not ( buff[classtable.DeathWishBuff].up or buff[classtable.EnrageBuff].up or buff[classtable.UnholyFrenzyBuff].up ) and Rage >15 and cooldown[classtable.RagingBlow].remains <1) and cooldown[classtable.BerserkerRage].ready then
        if not setSpell then setSpell = classtable.BerserkerRage end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and (buff[classtable.BloodsurgeBuff].up) and cooldown[classtable.Slam].ready then
        if not setSpell then setSpell = classtable.Slam end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (Rage >= 50) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and (Rage <70) and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.bloodlust = 0
    classtable.ColossusSmashBuff = 0
    classtable.InciteBuff = 0
    classtable.InnerRageBuff = 0
    classtable.BattleTranceBuff = 0
    classtable.ExecutionerTalentBuff = 0
    classtable.DeathWishBuff = 0
    classtable.EnrageBuff = 184362
    classtable.UnholyFrenzyBuff = 0
    classtable.BloodsurgeBuff = 0
    setSpell = nil
    ClearCDs()

    Fury:callaction()
    if setSpell then return setSpell end
end
