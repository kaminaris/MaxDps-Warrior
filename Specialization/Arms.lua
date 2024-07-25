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

local Arms = {}

local trinket_1_exclude
local trinket_2_exclude
local trinket_1_sync
local trinket_2_sync
local trinket_1_buffs
local trinket_2_buffs
local trinket_priority
local trinket_1_manual
local trinket_2_manual
local st_planning
local adds_remain

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' or spellstring == 'KillShot' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    if spellstring == 'HammerofWrath' and ( (classtable.AvengingWrathBuff and buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and buff[classtable.FinalVerdictBuff].up) ) then
        if targethealthPerc < 20 then
            return true
        else
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and buff[classtable.SuddenDeathBuff].up) then
            return true
        end
        if targethealthPerc < 35 then
            return true
        else
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


function Arms:precombat()
    --if (MaxDps:FindSpell(classtable.Flask) and CheckSpellCosts(classtable.Flask, 'Flask')) and cooldown[classtable.Flask].ready then
    --    return classtable.Flask
    --end
    --if (MaxDps:FindSpell(classtable.Food) and CheckSpellCosts(classtable.Food, 'Food')) and cooldown[classtable.Food].ready then
    --    return classtable.Food
    --end
    --if (MaxDps:FindSpell(classtable.Augmentation) and CheckSpellCosts(classtable.Augmentation, 'Augmentation')) and cooldown[classtable.Augmentation].ready then
    --    return classtable.Augmentation
    --end
    --if (MaxDps:FindSpell(classtable.SnapshotStats) and CheckSpellCosts(classtable.SnapshotStats, 'SnapshotStats')) and cooldown[classtable.SnapshotStats].ready then
    --    return classtable.SnapshotStats
    --end
    --trinket_1_exclude = CheckTrinketNames('RubyWhelpShell') or CheckTrinketNames('WhisperingIncarnateIcon')
    --trinket_2_exclude = CheckTrinketNames('RubyWhelpShell') or CheckTrinketNames('WhisperingIncarnateIcon')
    --if trinket.1.has_use_buff and ( trinket.1.cooldown.duration % % cooldown[classtable.Avatar].duration == 0 ) then
    --    trinket_1_sync = 1
    --else
    --    trinket_1_sync = 0.5
    --end
    --if trinket.2.has_use_buff and ( trinket.2.cooldown.duration % % cooldown[classtable.Avatar].duration == 0 ) then
    --    trinket_2_sync = 1
    --else
    --    trinket_2_sync = 0.5
    --end
    --trinket_1_buffs = trinket.1.has_use_buff or ( trinket.1.has_buff.strength or trinket.1.has_buff.mastery or trinket.1.has_buff.versatility or trinket.1.has_buff.haste or trinket.1.has_buff.crit and not trinket_1_exclude )
    --trinket_2_buffs = trinket.2.has_use_buff or ( trinket.2.has_buff.strength or trinket.2.has_buff.mastery or trinket.2.has_buff.versatility or trinket.2.has_buff.haste or trinket.2.has_buff.crit and not trinket_2_exclude )
    --if not trinket_1_buffs and trinket_2_buffs or trinket_2_buffs and ( ( trinket.2.cooldown.duration % trinket.2.proc.any_dps.duration ) * ( 1.5 + trinket.2.has_buff.strength ) * ( trinket_2_sync ) ) >( ( trinket.1.cooldown.duration % trinket.1.proc.any_dps.duration ) * ( 1.5 + trinket.1.has_buff.strength ) * ( trinket_1_sync ) ) then
    --    trinket_priority = 2
    --else
    --    trinket_priority = 1
    --end
    --trinket_1_manual = CheckTrinketNames('AlgetharPuzzleBox')
    --trinket_2_manual = CheckTrinketNames('AlgetharPuzzleBox')
    if (MaxDps:FindSpell(classtable.BattleStance) and CheckSpellCosts(classtable.BattleStance, 'BattleStance')) and cooldown[classtable.BattleStance].ready then
        return classtable.BattleStance
    end
end
function Arms:aoe()
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.JuggernautBuff].up and buff[classtable.JuggernautBuff].remains <gcd and (MaxDps.tier and MaxDps.tier[31].count >= 4)) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (buff[classtable.CollateralDamageBuff].up and debuff[classtable.ColossusSmashDeBuff].remains and not buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (talents[classtable.ThunderClap] and talents[classtable.BloodandThunder] and talents[classtable.Rend] and debuff[classtable.RendDeBuff].remains <= debuff[classtable.RendDeBuff].duration * 0.3) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
    if (MaxDps:FindSpell(classtable.SweepingStrikes) and CheckSpellCosts(classtable.SweepingStrikes, 'SweepingStrikes')) and (cooldown[classtable.Bladestorm].remains >15 or talents[classtable.ImprovedSweepingStrikes] and cooldown[classtable.Bladestorm].remains >21 or not talents[classtable.Bladestorm] or not talents[classtable.Bladestorm] and talents[classtable.BlademastersTorment] and cooldown[classtable.Avatar].remains >15 or not talents[classtable.Bladestorm] and talents[classtable.BlademastersTorment] and talents[classtable.ImprovedSweepingStrikes] and cooldown[classtable.Avatar].remains >21) and cooldown[classtable.SweepingStrikes].ready then
        return classtable.SweepingStrikes
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and (talents[classtable.BlademastersTorment] or ttd <20 or buff[classtable.HurricaneBuff].remains <3) and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    if (MaxDps:FindSpell(classtable.Warbreaker) and CheckSpellCosts(classtable.Warbreaker, 'Warbreaker')) and (targets >1) and cooldown[classtable.Warbreaker].ready then
        return classtable.Warbreaker
    end
    if (MaxDps:FindSpell(classtable.ColossusSmash) and CheckSpellCosts(classtable.ColossusSmash, 'ColossusSmash')) and (( targetHP <20 or talents[classtable.Massacre] and targetHP <35 )) and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    if (MaxDps:FindSpell(classtable.ColossusSmash) and CheckSpellCosts(classtable.ColossusSmash, 'ColossusSmash')) and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (talents[classtable.StormofSwords]) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and (talents[classtable.Unhinged] and buff[classtable.SweepingStrikesBuff].up) and cooldown[classtable.Bladestorm].ready then
        return classtable.Bladestorm
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up and (MaxDps.tier and MaxDps.tier[31].count >= 4)) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Cleave) and CheckSpellCosts(classtable.Cleave, 'Cleave')) and (buff[classtable.MartialProwessBuff].count == 2 and ( buff[classtable.SweepingStrikesBuff].up and targets >4 or not buff[classtable.SweepingStrikesBuff].up ) or buff[classtable.MercilessBonegrinderBuff].up) and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
    if (MaxDps:FindSpell(classtable.MortalStrike) and CheckSpellCosts(classtable.MortalStrike, 'MortalStrike')) and (buff[classtable.SweepingStrikesBuff].up and buff[classtable.MartialProwessBuff].count == 2 and ( targets <= 4 or not talents[classtable.Cleave] )) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and (buff[classtable.TestofMightBuff].up or debuff[classtable.ColossusSmashDeBuff].up or debuff[classtable.DeepWoundsDeBuff].remains) and cooldown[classtable.ChampionsSpear].ready then
        return classtable.ChampionsSpear
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and (buff[classtable.SweepingStrikesBuff].up and talents[classtable.Dreadnaught]) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and (not buff[classtable.SweepingStrikesBuff].up and ( buff[classtable.HurricaneBuff].remains <3 or not talents[classtable.Hurricane] )) and cooldown[classtable.Bladestorm].ready then
        return classtable.Bladestorm
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (talents[classtable.FervorofBattle] and Rage >70 or buff[classtable.MercilessBonegrinderBuff].up) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and (talents[classtable.Dreadnaught]) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.MortalStrike) and CheckSpellCosts(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2 or debuff[classtable.DeepWoundsDeBuff].remains <= gcd or targets <3) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up or ( targetHP <20 or talents[classtable.Massacre] and targetHP <35 ) or buff[classtable.SweepingStrikesBuff].up or targets <= 2) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (targets >3) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.MortalStrike) and CheckSpellCosts(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (not talents[classtable.CrushingForce]) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Slam) and CheckSpellCosts(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        return classtable.Slam
    end
    if (MaxDps:FindSpell(classtable.Shockwave) and CheckSpellCosts(classtable.Shockwave, 'Shockwave')) and cooldown[classtable.Shockwave].ready then
        return classtable.Shockwave
    end
    if (MaxDps:FindSpell(classtable.WreckingThrow) and CheckSpellCosts(classtable.WreckingThrow, 'WreckingThrow')) and cooldown[classtable.WreckingThrow].ready then
        return classtable.WreckingThrow
    end
end
function Arms:execute()
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (buff[classtable.CollateralDamageBuff].up and cooldown[classtable.SweepingStrikes].remains <3) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.SweepingStrikes) and CheckSpellCosts(classtable.SweepingStrikes, 'SweepingStrikes')) and (targets >1) and cooldown[classtable.SweepingStrikes].ready then
        return classtable.SweepingStrikes
    end
    if (MaxDps:FindSpell(classtable.MortalStrike) and CheckSpellCosts(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.RendDeBuff].remains <= gcd and talents[classtable.Bloodletting]) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:FindSpell(classtable.Rend) and CheckSpellCosts(classtable.Rend, 'Rend')) and (debuff[classtable.Rend].remains <= gcd and not talents[classtable.Bloodletting] and ( not talents[classtable.Warbreaker] and cooldown[classtable.ColossusSmash].remains <4 or talents[classtable.Warbreaker] and cooldown[classtable.Warbreaker].remains <4 ) and ttd >12) and cooldown[classtable.Rend].ready then
        return classtable.Rend
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and (cooldown[classtable.ColossusSmash].ready or debuff[classtable.ColossusSmashDeBuff].up or ttd <20) and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and (cooldown[classtable.ColossusSmash].remains <= gcd) and cooldown[classtable.ChampionsSpear].ready then
        return classtable.ChampionsSpear
    end
    if (MaxDps:FindSpell(classtable.Warbreaker) and CheckSpellCosts(classtable.Warbreaker, 'Warbreaker')) and cooldown[classtable.Warbreaker].ready then
        return classtable.Warbreaker
    end
    if (MaxDps:FindSpell(classtable.ColossusSmash) and CheckSpellCosts(classtable.ColossusSmash, 'ColossusSmash')) and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and (( talents[classtable.TestofMight] and Rage <40 ) or ( not talents[classtable.TestofMight] and ( buff[classtable.AvatarBuff].up or debuff[classtable.ColossusSmashDeBuff].up ) and Rage <70 )) and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
    if (MaxDps:FindSpell(classtable.Cleave) and CheckSpellCosts(classtable.Cleave, 'Cleave')) and (targets >2 and debuff[classtable.DeepWoundsDeBuff].remains <= gcd) and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and (talents[classtable.Hurricane] and Rage <40) and cooldown[classtable.Bladestorm].ready then
        return classtable.Bladestorm
    end
    if (MaxDps:FindSpell(classtable.MortalStrike) and CheckSpellCosts(classtable.MortalStrike, 'MortalStrike')) and (debuff[classtable.ExecutionersPrecisionDeBuff].count == 2) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up and debuff[classtable.DeepWoundsDeBuff].remains) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and (Rage <40 and buff[classtable.MartialProwessBuff].count <2) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.Skullsplitter) and CheckSpellCosts(classtable.Skullsplitter, 'Skullsplitter')) and (Rage <40) and cooldown[classtable.Skullsplitter].ready then
        return classtable.Skullsplitter
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (Rage >= 40) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Shockwave) and CheckSpellCosts(classtable.Shockwave, 'Shockwave')) and (talents[classtable.SonicBoom]) and cooldown[classtable.Shockwave].ready then
        return classtable.Shockwave
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and cooldown[classtable.Bladestorm].ready then
        return classtable.Bladestorm
    end
    if (MaxDps:FindSpell(classtable.WreckingThrow) and CheckSpellCosts(classtable.WreckingThrow, 'WreckingThrow')) and cooldown[classtable.WreckingThrow].ready then
        return classtable.WreckingThrow
    end
end
function Arms:single_target()
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (buff[classtable.CollateralDamageBuff].up and cooldown[classtable.SweepingStrikes].remains <3) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.SweepingStrikes) and CheckSpellCosts(classtable.SweepingStrikes, 'SweepingStrikes')) and (targets >1) and cooldown[classtable.SweepingStrikes].ready then
        return classtable.SweepingStrikes
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= gcd and talents[classtable.BloodandThunder] and talents[classtable.BlademastersTorment]) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and (talents[classtable.Hurricane] and talents[classtable.WarlordsTorment]) and cooldown[classtable.Bladestorm].ready then
        return classtable.Bladestorm
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and (ttd <20) and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    if (MaxDps:FindSpell(classtable.ColossusSmash) and CheckSpellCosts(classtable.ColossusSmash, 'ColossusSmash')) and cooldown[classtable.ColossusSmash].ready then
        return classtable.ColossusSmash
    end
    if (MaxDps:FindSpell(classtable.Warbreaker) and CheckSpellCosts(classtable.Warbreaker, 'Warbreaker')) and cooldown[classtable.Warbreaker].ready then
        return classtable.Warbreaker
    end
    if (MaxDps:FindSpell(classtable.MortalStrike) and CheckSpellCosts(classtable.MortalStrike, 'MortalStrike')) and cooldown[classtable.MortalStrike].ready then
        return classtable.MortalStrike
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (( buff[classtable.JuggernautBuff].up and buff[classtable.JuggernautBuff].remains <gcd ) or ( buff[classtable.SuddenDeathBuff].up and debuff[classtable.DeepWoundsDeBuff].remains and (MaxDps.tier and MaxDps.tier[31].count >= 2) or buff[classtable.SuddenDeathBuff].up and not debuff[classtable.RendDeBuff].duration and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= gcd and talents[classtable.BloodandThunder]) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Rend) and CheckSpellCosts(classtable.Rend, 'Rend')) and (debuff[classtable.RendDeBuff].remains <= gcd and not talents[classtable.BloodandThunder]) and cooldown[classtable.Rend].ready then
        return classtable.Rend
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (talents[classtable.StormofSwords] and debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and (talents[classtable.Hurricane] and ( buff[classtable.TestofMightBuff].up or not talents[classtable.TestofMight] and debuff[classtable.ColossusSmashDeBuff].up ) and buff[classtable.HurricaneBuff].remains <2 or talents[classtable.Unhinged] and ( buff[classtable.TestofMightBuff].up or not talents[classtable.TestofMight] and debuff[classtable.ColossusSmashDeBuff].up )) and cooldown[classtable.Bladestorm].ready then
        return classtable.Bladestorm
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and (buff[classtable.TestofMightBuff].up or debuff[classtable.ColossusSmashDeBuff].up) and cooldown[classtable.ChampionsSpear].ready then
        return classtable.ChampionsSpear
    end
    if (MaxDps:FindSpell(classtable.Skullsplitter) and CheckSpellCosts(classtable.Skullsplitter, 'Skullsplitter')) and cooldown[classtable.Skullsplitter].ready then
        return classtable.Skullsplitter
    end
    if (MaxDps:FindSpell(classtable.Shockwave) and CheckSpellCosts(classtable.Shockwave, 'Shockwave')) and (talents[classtable.SonicBoom]) and cooldown[classtable.Shockwave].ready then
        return classtable.Shockwave
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (talents[classtable.StormofSwords] and talents[classtable.TestofMight] and cooldown[classtable.ColossusSmash].remains >cooldown[classtable.Whirlwind].duration) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Overpower) and CheckSpellCosts(classtable.Overpower, 'Overpower')) and (cooldown[classtable.Overpower].charges == 2 and not talents[classtable.Battlelord] or talents[classtable.Battlelord]) and cooldown[classtable.Overpower].ready then
        return classtable.Overpower
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (talents[classtable.StormofSwords] and not talents[classtable.TestofMight]) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Slam) and CheckSpellCosts(classtable.Slam, 'Slam')) and (talents[classtable.CrushingForce] and debuff[classtable.RendDeBuff].remains >12) and cooldown[classtable.Slam].ready then
        return classtable.Slam
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (buff[classtable.MercilessBonegrinderBuff].up) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Slam) and CheckSpellCosts(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        return classtable.Slam
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and cooldown[classtable.Bladestorm].ready then
        return classtable.Bladestorm
    end
    if (MaxDps:FindSpell(classtable.Cleave) and CheckSpellCosts(classtable.Cleave, 'Cleave')) and cooldown[classtable.Cleave].ready then
        return classtable.Cleave
    end
    if (MaxDps:FindSpell(classtable.WreckingThrow) and CheckSpellCosts(classtable.WreckingThrow, 'WreckingThrow')) and cooldown[classtable.WreckingThrow].ready then
        return classtable.WreckingThrow
    end
end

function Arms:variables()
    st_planning = targets == 1 and (targets <2)
    adds_remain = targets >= 2
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
    SpellHaste = UnitSpellHaste('target')
    SpellCrit = GetCritChance()
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    classtable.JuggernautBuff = 383290
    classtable.CollateralDamageBuff = 334783
    classtable.ColossusSmashDeBuff = 208086
    classtable.SweepingStrikesBuff = 260708
    classtable.RendDeBuff = 388539
    classtable.HurricaneBuff = 390581
    classtable.SuddenDeathBuff = 52437
    classtable.MartialProwessBuff = 7384
    classtable.MercilessBonegrinderBuff = 383316
    classtable.TestofMightBuff = 385013
    classtable.DeepWoundsDeBuff = 262115
    classtable.ExecutionersPrecisionDeBuff = 386633
    classtable.AvatarBuff = 107574

    Arms:variables()

    --if (MaxDps:FindSpell(classtable.Charge) and CheckSpellCosts(classtable.Charge, 'Charge')) and (timeInCombat <= 0.5 or (LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >5) and cooldown[classtable.Charge].ready then
    --    return classtable.Charge
    --end
    --if (MaxDps:FindSpell(classtable.AutoAttack) and CheckSpellCosts(classtable.AutoAttack, 'AutoAttack')) and cooldown[classtable.AutoAttack].ready then
    --    return classtable.AutoAttack
    --end
    --if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (gcd == 0 and debuff[classtable.ColossusSmashDeBuff].remains >8 or ttd <25) and cooldown[classtable.Potion].ready then
    --    return classtable.Potion
    --end
    --if (MaxDps:FindSpell(classtable.Pummel) and CheckSpellCosts(classtable.Pummel, 'Pummel')) and (target.debuff.casting.up) and cooldown[classtable.Pummel].ready then
    --    return classtable.Pummel
    --end
    --local trinketsCheck = Arms:trinkets()
    --if trinketsCheck then
    --    return trinketsCheck
    --end
    --local precombatCheck = Arms:precombat()
    --if precombatCheck then
    --    return precombatCheck
    --end
    if ((targets >1) and targets >2 or talents[classtable.FervorofBattle] and ( talents[classtable.Massacre] and targetHP >35 or targetHP >20 ) ) then
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
