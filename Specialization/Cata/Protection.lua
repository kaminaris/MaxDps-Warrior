--Credit to Kaidd, Discord(revolve_1) for collecting data

local _, addonTable = ...
local Warrior = addonTable.Warrior
local MaxDps = _G.MaxDps
if not MaxDps then return end

-- WoW API locals
local UnitPower           = UnitPower
local UnitHealth          = UnitHealth
local UnitHealthMax       = UnitHealthMax
local UnitAffectingCombat = UnitAffectingCombat
local UnitThreatSituation = UnitThreatSituation
local GetShapeshiftFormID = GetShapeshiftFormID
local UnitSpellHaste      = UnitSpellHaste
local GetCritChance       = GetCritChance

-- Power Types
local RagePT = Enum.PowerType.Rage

-- Cached FrameData
local fd, ttd, gcd, cooldown, buff, debuff, talents, targets
local healthPerc, targethealthPerc, timeInCombat, stance
local classtable, SpellHaste, SpellCrit
local Rage

-- Protection namespace
local Prot = {}

-- Precombat: apply shout and stance
function Prot:precombat()
    if not UnitAffectingCombat('player') then
        if stance ~= 18 and cooldown[classtable.DefensiveStance].ready then
            return classtable.DefensiveStance
        end
        if buff[classtable.CommandingShoutBuff].refreshable and cooldown[classtable.CommandingShout].ready then
            return classtable.CommandingShout
        end
        if buff[classtable.BattleShoutBuff].refreshable and cooldown[classtable.BattleShout].ready then
            return classtable.BattleShout
        end
    end
end

-- Single-target rotation
function Prot:single()
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and talents[classtable.BloodAndThunder] and debuff[classtable.RendDeBuff].remains > gcd and debuff[classtable.RendDeBuff].refreshable then
        return classtable.ThunderClap
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and not debuff[classtable.RendDeBuff].up and cooldown[classtable.Rend].ready then
        return classtable.Rend
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and debuff[classtable.ThunderClapDeBuff].refreshable then
        return classtable.ThunderClap
    end
    if buff[classtable.BattleShoutBuff].refreshable or Rage < 15 and cooldown[classtable.BattleShout].ready then
        return classtable.BattleShout
    end
    if buff[classtable.CommandingShoutBuff].refreshable or Rage < 15 and cooldown[classtable.CommandingShout].ready then
        return classtable.CommandingShout
    end
    if (MaxDps:CheckSpellUsable(classtable.Devastate, 'Devastate')) and cooldown[classtable.Devastate].ready then
        return classtable.Devastate
    end
    MaxDps:GlowCooldown(classtable.InnerRage, Rage >= 50 and cooldown[classtable.HeroicStrike].ready and cooldown[classtable.InnerRage].ready)
    if Rage >= 50 and cooldown[classtable.HeroicStrike].ready then
        return classtable.HeroicStrike
    end
end

-- AoE rotation
function Prot:aoe()
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and ( (talents[classtable.BloodAndThunder] and debuff[classtable.RendDeBuff].remains > gcd and debuff[classtable.RendDeBuff].refreshable) or cooldown[classtable.ThunderClap].ready) then
        return classtable.ThunderClap
    end
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and not debuff[classtable.RendDeBuff].up and cooldown[classtable.Rend].ready then
        return classtable.Rend
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
    MaxDps:GlowCooldown(classtable.Shockwave, cooldown[classtable.Shockwave].ready)
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
    if (MaxDps:CheckSpellUsable(classtable.Devastate, 'Devastate')) and cooldown[classtable.Devastate].ready then
        return classtable.Devastate
    end
    MaxDps:GlowCooldown(classtable.InnerRage, Rage >= 50 and cooldown[classtable.Cleave].ready and cooldown[classtable.InnerRage].ready)
    if Rage >= 50 and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
end

-- Main action call
function Prot:callaction()
    fd = MaxDps.FrameData
    ttd = fd.timeToDie or 500
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    timeInCombat = MaxDps.combatTime or 0

    local hp = UnitHealth('player')
    local hpMax = UnitHealthMax('player')
    healthPerc = hp / hpMax

    local thp = UnitHealth('target')
    local thpMax = UnitHealthMax('target')
    targethealthPerc = thp > 0 and (thp / thpMax) or 1

    Rage = UnitPower('player', RagePT)
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    stance = GetShapeshiftFormID()

    local threatStatus = UnitThreatSituation("player", "target") or 0

    classtable = MaxDps.SpellTable

    -- Precombat
    local pre = Prot:precombat()
    if pre then return pre end

    --MaxDps:GlowCooldown(classtable.CommandingShout, cooldown[classtable.CommandingShout].ready)
    MaxDps:GlowCooldown(classtable.Taunt, threatStatus <=2 and cooldown[classtable.Taunt].ready)
    MaxDps:GlowCooldown(classtable.ChallengingShout, Rage >= 5 and targets > 2 and cooldown[classtable.ChallengingShout].ready)

    -- Defensive utilities
    MaxDps:GlowCooldown(classtable.ShieldWall, healthPerc < 0.25 and cooldown[classtable.ShieldWall].ready)
    MaxDps:GlowCooldown(classtable.LastStand, healthPerc < 20 and cooldown[classtable.LastStand].ready)
    MaxDps:GlowCooldown(classtable.ShieldBlock, threatStatus > 1 and cooldown[classtable.ShieldBlock].ready)
    MaxDps:GlowCooldown(classtable.DemoralizingShout, not debuff[classtable.DemoralizingShoutDeBuff].up and cooldown[classtable.DemoralizingShout].ready)

    -- Rotation
    if targets > 1 then
        return Prot:aoe()
    else
        return Prot:single()
    end
end

-- Register specialization
function Warrior:Protection()
    return Prot:callaction()
end

-- Spell IDs
MaxDps.SpellTable.BattleStance            = 2457
MaxDps.SpellTable.DefensiveStance         = 71
MaxDps.SpellTable.ShieldWall              = 871
MaxDps.SpellTable.LastStand               = 12975
MaxDps.SpellTable.ShieldBlock             = 2565
MaxDps.SpellTable.RallyingCry             = 97462
MaxDps.SpellTable.ShieldSlam              = 23922
MaxDps.SpellTable.Devastate               = 20243
MaxDps.SpellTable.SunderArmorDeBuff       = 58567
MaxDps.SpellTable.Revenge                 = 6572
MaxDps.SpellTable.ThunderClap             = 6343
MaxDps.SpellTable.ThunderClapDeBuff       = 6343
MaxDps.SpellTable.DemoralizingShout       = 1160
MaxDps.SpellTable.DemoralizingShoutDeBuff = 12323
MaxDps.SpellTable.Shockwave               = 46968
MaxDps.SpellTable.HeroicStrike            = 78
MaxDps.SpellTable.Cleave                  = 845
MaxDps.SpellTable.Rend                    = 772
MaxDps.SpellTable.DeepWoundsDeBuff        = 115767
MaxDps.SpellTable.RendDeBuff              = 94009
MaxDps.SpellTable.BloodAndThunder         = 84615
MaxDps.SpellTable.ChallengingShout        = 1161
MaxDps.SpellTable.CommandingShout         = 469
MaxDps.SpellTable.CommandingShoutBuff     = 469
MaxDps.SpellTable.BattleShout             = 6673
MaxDps.SpellTable.BattleShoutBuff         = 6673
MaxDps.SpellTable.Taunt                   = 355
MaxDps.SpellTable.InnerRage               = 1134
