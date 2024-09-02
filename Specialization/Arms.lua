local _, addonTable = ...
local Warrior = addonTable.Warrior
local MaxDps = _G.MaxDps
if not MaxDps then return end

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

local Arms = {}

local trinket_one_exclude
local trinket_two_exclude
local trinket_one_sync
local trinket_two_sync
local trinket_one_buffs
local trinket_two_buffs
local trinket_priority
local trinket_one_manual
local trinket_two_manual
local st_planning
local adds_remain
local execute_phase
function Arms:precombat()
    --if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready then
    --    return classtable.BattleShout
    --end
    --if (MaxDps:CheckSpellUsable(classtable.BattleStance, 'BattleStance')) and cooldown[classtable.BattleStance].ready then
    --    return classtable.BattleStance
    --end
end
function Arms:execute()
    MaxDps:GlowCooldown(classtable.SweepingStrikes,MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes') and (targets >1) and cooldown[classtable.SweepingStrikes].ready)
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager') and cooldown[classtable.Ravager].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and cooldown[classtable.Avatar].ready)
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        return classtable.Skullsplitter
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        return classtable.Warbreaker
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.ChampionsSpear].ready)
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish')) and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Demolish].ready then
        return classtable.Demolish
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2 and not buff[classtable.RavagerBuff].up) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2) and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up or Rage >40) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
end
function Arms:aoe()
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (not buff[classtable.StrikeVulnerabilitiesBuff].up or buff[classtable.CollateralDamageBuff].up and buff[classtable.MercilessBonegrinderBuff].up) and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].duration <3 and targets >= 3) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    MaxDps:GlowCooldown(classtable.SweepingStrikes,MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes') and cooldown[classtable.SweepingStrikes].ready)
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and cooldown[classtable.Avatar].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager') and (cooldown[classtable.SweepingStrikes].remains <= 1 or buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Ravager].ready)
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        return classtable.Skullsplitter
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        return classtable.Warbreaker
    end
    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.ChampionsSpear].ready)
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Demolish].ready then
        return classtable.Demolish
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up or Rage >40 or debuff[classtable.MarkedForExecutionDeBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
end
function Arms:single_target()
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= gcd and targets >= 2 and not buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    MaxDps:GlowCooldown(classtable.SweepingStrikes,MaxDps:CheckSpellUsable(classtable.SweepingStrikes, 'SweepingStrikes') and (targets >1) and cooldown[classtable.SweepingStrikes].ready)
    if (MaxDps:CheckSpellUsable(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd) and cooldown[classtable.Rend].ready then
        return classtable.Rend
    end
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager') and cooldown[classtable.Ravager].ready)
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and cooldown[classtable.Avatar].ready)

    if (MaxDps:CheckSpellUsable(classtable.ColossusSmash, 'ColossusSmash')) and not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    if (MaxDps:CheckSpellUsable(classtable.Warbreaker, 'Warbreaker')) and talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].ready then
        return classtable.Warbreaker
    end
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and (debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.ChampionsSpear].ready)
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish')) and cooldown[classtable.Demolish].ready then
        return classtable.Demolish
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (debuff[classtable.MarkedForExecutionDeBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and (targets >1 and ( buff[classtable.SweepingStrikesBuff].up or talents[classtable.Dreadnaught] ) and cooldown[classtable.Overpower].charges == 2) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:CheckSpellUsable(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        return classtable.Skullsplitter
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    MaxDps:GlowCooldown(classtable.Bladestorm,MaxDps:CheckSpellUsable(classtable.Bladestorm, 'Bladestorm') and cooldown[classtable.Bladestorm].ready)
    if (MaxDps:CheckSpellUsable(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:CheckSpellUsable(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        return classtable.Slam
    end
end
function Arms:trinkets()
end
function Arms:variables()
    st_planning = targets == 1 and ( math.huge >15 or (targets <2) )
    adds_remain = targets >= 2 and ( (targets <2) or (targets >1) and targets >5 )
    execute_phase = ( talents[classtable.Massacre] and targetHP <35 ) or targetHP <20
end

function Arms:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Charge, 'Charge')) and (timeInCombat <= 0.5 or (LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >8) and cooldown[classtable.Charge].ready then
        return classtable.Charge
    end
    MaxDps:GlowCooldown(classtable.Pummel,MaxDps:CheckSpellUsable(classtable.Pummel, 'Pummel') and (UnitCastingInfo('target') and select(8,UnitCastingInfo('target')) == false) and ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    local variablesCheck = Arms:variables()
    if variablesCheck then
        return variablesCheck
    end
    local trinketsCheck = Arms:trinkets()
    if trinketsCheck then
        return trinketsCheck
    end
    if (targets >2 or talents[classtable.FervorofBattle] and execute_phase and not (targets >1) and targets >1) then
        local aoeCheck = Arms:aoe()
        if aoeCheck then
            return Arms:aoe()
        end
    end
    local executeCheck = Arms:execute()
    if executeCheck then
        return executeCheck
    end
    local single_targetCheck = Arms:single_target()
    if single_targetCheck then
        return single_targetCheck
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
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
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.ColossusSmashDeBuff = 208086
    classtable.ExecutionersPrecisionDeBuff = 386633
    classtable.RavagerBuff = 0
    classtable.SuddenDeathBuff = 52437
    classtable.StrikeVulnerabilitiesBuff = 0
    classtable.CollateralDamageBuff = 334783
    classtable.MercilessBonegrinderBuff = 383316
    classtable.RendDeBuff = 388539
    classtable.SweepingStrikesBuff = 260708
    classtable.MarkedForExecutionDeBuff = 0

    local precombatCheck = Arms:precombat()
    if precombatCheck then
        return Arms:precombat()
    end

    local callactionCheck = Arms:callaction()
    if callactionCheck then
        return Arms:callaction()
    end
end
