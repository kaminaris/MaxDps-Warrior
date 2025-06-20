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
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Rage
local RageMax
local RageDeficit
local RagePerc

local Fury = {}

function Fury:precombat()
    if (MaxDps:CheckSpellUsable(classtable.Stance, 'Stance')) and cooldown[classtable.Stance].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Stance end
    end
    if (MaxDps:CheckSpellUsable(classtable.GolembloodPotion, 'GolembloodPotion')) and cooldown[classtable.GolembloodPotion].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.GolembloodPotion end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Recklessness, false)
    MaxDps:GlowCooldown(classtable.Shockwave, false)
    MaxDps:GlowCooldown(classtable.Bladestorm, false)
end

function Fury:callaction()
    if (MaxDps:CheckSpellUsable(classtable.GolembloodPotion, 'GolembloodPotion')) and (( targethealthPerc <20 and buff[classtable.RecklessnessBuff].up ) or MaxDps:Bloodlust(1) or ttd <= 25) and cooldown[classtable.GolembloodPotion].ready then
        if not setSpell then setSpell = classtable.GolembloodPotion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Recklessness, 'Recklessness')) and (( ( debuff[classtable.ColossusSmashDeBuff].remains >= 5 or cooldown[classtable.ColossusSmash].remains <= 4 ) and ( targethealthPerc <20 or ttd >315 ) ) or ttd <= 18) and cooldown[classtable.Recklessness].ready then
        MaxDps:GlowCooldown(classtable.Recklessness, cooldown[classtable.Recklessness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkerRage, 'BerserkerRage')) and (not ( buff[classtable.EnrageBuff].up or ( buff[classtable.RagingBlowBuff].up == 2 and targethealthPerc >= 20 ) )) and cooldown[classtable.BerserkerRage].ready then
        if not setSpell then setSpell = classtable.BerserkerRage end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicLeap, 'HeroicLeap')) and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.HeroicLeap].ready then
        if not setSpell then setSpell = classtable.HeroicLeap end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeadlyCalm, 'DeadlyCalm')) and (Rage >= 40) and cooldown[classtable.DeadlyCalm].ready then
        if not setSpell then setSpell = classtable.DeadlyCalm end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (( ( ( debuff[classtable.ColossusSmashDeBuff].up and Rage >= 40 ) or ( buff[classtable.DeadlyCalmBuff].up and Rage >= 30 ) ) and targethealthPerc >= 20 ) or Rage >= 110) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bloodthirst, 'Bloodthirst')) and (not ( targethealthPerc <20 and debuff[classtable.ColossusSmashDeBuff].up and Rage >= 30 )) and cooldown[classtable.Bloodthirst].ready then
        if not setSpell then setSpell = classtable.Bloodthirst end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildStrike, 'WildStrike')) and (buff[classtable.BloodsurgeBuff].up and targethealthPerc >= 20 and cooldown[classtable.Bloodthirst].remains <= 1) and cooldown[classtable.WildStrike].ready then
        if not setSpell then setSpell = classtable.WildStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and (not talents[classtable.Warbreaker]) and cooldown[classtable.ColossusSmash].ready then
        if not setSpell then setSpell = classtable.ColossusSmash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.RagingBlow, 'RagingBlow')) and (buff[classtable.RagingBlowBuff].up) and cooldown[classtable.RagingBlow].ready then
        if not setSpell then setSpell = classtable.RagingBlow end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildStrike, 'WildStrike')) and (buff[classtable.BloodsurgeBuff].up and targethealthPerc >= 20) and cooldown[classtable.WildStrike].ready then
        if not setSpell then setSpell = classtable.WildStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shockwave, 'Shockwave') and talents[classtable.Shockwave]) and ((talents[classtable.Shockwave] and true or false)) and cooldown[classtable.Shockwave].ready then
        MaxDps:GlowCooldown(classtable.Shockwave, cooldown[classtable.Shockwave].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DragonRoar, 'DragonRoar') and talents[classtable.DragonRoar]) and ((talents[classtable.DragonRoar] and true or false)) and cooldown[classtable.DragonRoar].ready then
        if not setSpell then setSpell = classtable.DragonRoar end
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
    if (MaxDps:CheckSpellUsable(classtable.WildStrike, 'WildStrike')) and (debuff[classtable.ColossusSmashDeBuff].up and targethealthPerc >= 20) and cooldown[classtable.WildStrike].ready then
        if not setSpell then setSpell = classtable.WildStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.ImpendingVictory, 'ImpendingVictory') and talents[classtable.ImpendingVictory]) and ((talents[classtable.ImpendingVictory] and true or false) and targethealthPerc >= 20) and cooldown[classtable.ImpendingVictory].ready then
        if not setSpell then setSpell = classtable.ImpendingVictory end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildStrike, 'WildStrike')) and (cooldown[classtable.ColossusSmash].remains >= 1 and Rage >= 60 and targethealthPerc >= 20) and cooldown[classtable.WildStrike].ready then
        if not setSpell then setSpell = classtable.WildStrike end
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
