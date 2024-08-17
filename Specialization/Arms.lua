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

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) or (classtable.HuntersPreyBuff and not buff[classtable.HuntersPreyBuff].up) and targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and not buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and not buff[classtable.FinalVerdictBuff].up) ) and targethealthPerc > 20 then
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and not buff[classtable.SuddenDeathBuff].up) and targethealthPerc > 35 then
            return false
        end
    end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and C_Item.GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
end




local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = C_Item.GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
    end
end




local function CheckPrevSpell(spell)
    if MaxDps and MaxDps.spellHistory then
        if MaxDps.spellHistory[1] then
            if MaxDps.spellHistory[1] == spell then
                return true
            end
            if MaxDps.spellHistory[1] ~= spell then
                return false
            end
        end
    end
    return true
end


local function boss()
    if UnitExists('boss1')
    or UnitExists('boss2')
    or UnitExists('boss3')
    or UnitExists('boss4')
    or UnitExists('boss5')
    or UnitExists('boss6')
    or UnitExists('boss7')
    or UnitExists('boss8')
    or UnitExists('boss9')
    or UnitExists('boss10') then
        return true
    end
    return false
end


function Arms:precombat()
    --if (MaxDps:FindSpell(classtable.BattleShout) and CheckSpellCosts(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready then
    --    return classtable.BattleShout
    --end
    if (MaxDps:FindSpell(classtable.BattleStance) and CheckSpellCosts(classtable.BattleStance, 'BattleStance')) and cooldown[classtable.BattleStance].ready then
        return classtable.BattleStance
    end
end
function Arms:execute()
    if (MaxDps:FindSpell(classtable.SweepingStrikes) and CheckSpellCosts(classtable.SweepingStrikes, 'SweepingStrikes')) and (targets >1) and cooldown[classtable.SweepingStrikes].ready then
        MaxDps:GlowCooldown(classtable.SweepingStrikes, cooldown[classtable.SweepingStrikes].ready)
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:FindSpell(classtable.Skullsplitter) and CheckSpellCosts(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        return classtable.Skullsplitter
    end
    if (MaxDps:FindSpell(classtable.Ravager) and CheckSpellCosts(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:FindSpell(classtable.ColossusSmash) and CheckSpellCosts(classtable.ColossusSmash, 'ColossusSmash')) and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    if (MaxDps:FindSpell(classtable.Warbreaker) and CheckSpellCosts(classtable.Warbreaker, 'Warbreaker')) and cooldown[classtable.Warbreaker].ready then
        return classtable.Warbreaker
    end
    if (MaxDps:FindSpell(classtable.MortalStrike) and CheckSpellCosts(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and (Rage <60) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
end
function Arms:aoe()
    if (MaxDps:FindSpell(classtable.Cleave) and CheckSpellCosts(classtable.Cleave, 'Cleave')) and (not buff[classtable.StrikeVulnerabilitiesBuff].up or buff[classtable.CollateralDamageBuff].up and buff[classtable.MercilessBonegrinderBuff].up) and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].duration <3 and targets >= 3) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:FindSpell(classtable.Ravager) and CheckSpellCosts(classtable.Ravager, 'Ravager')) and (cooldown[classtable.SweepingStrikes].remains <= 1 or buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:FindSpell(classtable.SweepingStrikes) and CheckSpellCosts(classtable.SweepingStrikes, 'SweepingStrikes')) and cooldown[classtable.SweepingStrikes].ready then
        MaxDps:GlowCooldown(classtable.SweepingStrikes, cooldown[classtable.SweepingStrikes].ready)
    end
    if (MaxDps:FindSpell(classtable.Skullsplitter) and CheckSpellCosts(classtable.Skullsplitter, 'Skullsplitter')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Skullsplitter].ready then
        return classtable.Skullsplitter
    end
    if (MaxDps:FindSpell(classtable.Warbreaker) and CheckSpellCosts(classtable.Warbreaker, 'Warbreaker')) and cooldown[classtable.Warbreaker].ready then
        return classtable.Warbreaker
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and (talents[classtable.Unhinged] or talents[classtable.MercilessBonegrinder]) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:FindSpell(classtable.ColossusSmash) and CheckSpellCosts(classtable.ColossusSmash, 'ColossusSmash')) and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and (buff[classtable.SweepingStrikesBuff].up and cooldown[classtable.Overpower].charges == 2) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.Cleave) and CheckSpellCosts(classtable.Cleave, 'Cleave')) and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
    if (MaxDps:FindSpell(classtable.MortalStrike) and CheckSpellCosts(classtable.MortalStrike, 'MortalStrike')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.MortalStrike) and CheckSpellCosts(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
end
function Arms:single_target()
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= gcd and targets >= 2 and not buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.SweepingStrikes) and CheckSpellCosts(classtable.SweepingStrikes, 'SweepingStrikes')) and (targets >1) and cooldown[classtable.SweepingStrikes].ready then
        MaxDps:GlowCooldown(classtable.SweepingStrikes, cooldown[classtable.SweepingStrikes].ready)
    end
    if (MaxDps:FindSpell(classtable.Rend) and CheckSpellCosts(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd) and cooldown[classtable.Rend].ready then
        return classtable.Rend
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:FindSpell(classtable.Ravager) and CheckSpellCosts(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:FindSpell(classtable.ColossusSmash) and CheckSpellCosts(classtable.ColossusSmash, 'ColossusSmash')) and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    if (MaxDps:FindSpell(classtable.Warbreaker) and CheckSpellCosts(classtable.Warbreaker, 'Warbreaker')) and cooldown[classtable.Warbreaker].ready then
        return classtable.Warbreaker
    end
    if (MaxDps:FindSpell(classtable.Cleave) and CheckSpellCosts(classtable.Cleave, 'Cleave')) and (targets >= 3) and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and (targets >1 and ( buff[classtable.SweepingStrikesBuff].up or talents[classtable.Dreadnaught] ) and cooldown[classtable.Overpower].charges == 2) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.MortalStrike) and CheckSpellCosts(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:FindSpell(classtable.Skullsplitter) and CheckSpellCosts(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        return classtable.Skullsplitter
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.Rend) and CheckSpellCosts(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= 8) and cooldown[classtable.Rend].ready then
        return classtable.Rend
    end
    if (MaxDps:FindSpell(classtable.Cleave) and CheckSpellCosts(classtable.Cleave, 'Cleave')) and (targets >= 2 and talents[classtable.FervorofBattle]) and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
    if (MaxDps:FindSpell(classtable.Slam) and CheckSpellCosts(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
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
    if (MaxDps:FindSpell(classtable.Charge) and CheckSpellCosts(classtable.Charge, 'Charge')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >8) and cooldown[classtable.Charge].ready then
        return classtable.Charge
    end
    if (MaxDps:FindSpell(classtable.Pummel) and CheckSpellCosts(classtable.Pummel, 'Pummel')) and (UnitCastingInfo('target') and select(8,UnitCastingInfo('target')) == false) and cooldown[classtable.Pummel].ready then
        MaxDps:GlowCooldown(classtable.Pummel, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
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
    classtable.ExecutionersPrecisionDeBuff = 386633
    classtable.StrikeVulnerabilitiesBuff = 0
    classtable.CollateralDamageBuff = 334783
    classtable.MercilessBonegrinderBuff = 383316
    classtable.RendDeBuff = 388539
    classtable.SweepingStrikesBuff = 260708

    local precombatCheck = Arms:precombat()
    if precombatCheck then
        return Arms:precombat()
    end

    local callactionCheck = Arms:callaction()
    if callactionCheck then
        return Arms:callaction()
    end
end
