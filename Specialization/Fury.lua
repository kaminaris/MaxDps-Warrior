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

local Fury = {}

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
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and buff[classtable.FinalVerdictBuff].up) ) then
            return true
        end
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


function Fury:precombat()
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
    --if trinket.1.has_use_buff and ( trinket.1.cooldown.duration % % cooldown[classtable.Avatar].duration == 0 or trinket.1.cooldown.duration % % cooldown[classtable.OdynsFury].duration == 0 ) then
    --    trinket_1_sync = 1
    --else
    --    trinket_1_sync = 0.5
    --end
    --if trinket.2.has_use_buff and ( trinket.2.cooldown.duration % % cooldown[classtable.Avatar].duration == 0 or trinket.2.cooldown.duration % % cooldown[classtable.OdynsFury].duration == 0 ) then
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
    if (MaxDps:FindSpell(classtable.BerserkerStance) and CheckSpellCosts(classtable.BerserkerStance, 'BerserkerStance')) and cooldown[classtable.BerserkerStance].ready then
        return classtable.BerserkerStance
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and (not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    if (MaxDps:FindSpell(classtable.Recklessness) and CheckSpellCosts(classtable.Recklessness, 'Recklessness')) and (not talents[classtable.RecklessAbandon]) and cooldown[classtable.Recklessness].ready then
        return classtable.Recklessness
    end
end
function Fury:multi_target()
    if (MaxDps:FindSpell(classtable.Recklessness) and CheckSpellCosts(classtable.Recklessness, 'Recklessness')) and (targets >1 or ttd <12) and cooldown[classtable.Recklessness].ready then
        return classtable.Recklessness
    end
    if (MaxDps:FindSpell(classtable.OdynsFury) and CheckSpellCosts(classtable.OdynsFury, 'OdynsFury')) and (targets >1 and talents[classtable.TitanicRage] and ( not buff[classtable.MeatCleaverBuff].up or buff[classtable.AvatarBuff].up or buff[classtable.RecklessnessBuff].up )) and cooldown[classtable.OdynsFury].ready then
        return classtable.OdynsFury
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (targets >1 and talents[classtable.ImprovedWhirlwind] and not buff[classtable.MeatCleaverBuff].up and talents[classtable.ImprovedWhirlwind] and not buff[classtable.MeatCleaverBuff].up) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.AshenJuggernautBuff].up and buff[classtable.AshenJuggernautBuff].remains <gcd) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (talents[classtable.AngerManagement] and ( buff[classtable.RecklessnessBuff].up or buff[classtable.EnrageBuff].remains <gcd or RagePerc >85 )) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up and ( targets >1 )) and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
    if (MaxDps:FindSpell(classtable.OdynsFury) and CheckSpellCosts(classtable.OdynsFury, 'OdynsFury')) and (targets >1 and buff[classtable.EnrageBuff].up) and cooldown[classtable.OdynsFury].ready then
        return classtable.OdynsFury
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (buff[classtable.MeatCleaverBuff].count == 1 and buff[classtable.HurricaneBuff].up and Rage <80 and Rage >60) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and ((MaxDps.tier and MaxDps.tier[30].count >= 4) and buff[classtable.MercilessAssault].count == 6 or (MaxDps.tier and MaxDps.tier[31].count >= 4)) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and (( (MaxDps.tier and MaxDps.tier[30].count >= 4) and buff[classtable.MercilessAssault].count == 6 ) or ( not talents[classtable.RecklessAbandon] and buff[classtable.FuriousBloodthirstBuff].up and buff[classtable.EnrageBuff].up )) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and (talents[classtable.WrathandFury] and buff[classtable.EnrageBuff].up) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.OdynsFury) and CheckSpellCosts(classtable.OdynsFury, 'OdynsFury')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.OdynsFury].ready then
        return classtable.OdynsFury
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (buff[classtable.RecklessnessBuff].up or buff[classtable.EnrageBuff].remains <gcd or ( Rage >110 and talents[classtable.OverwhelmingRage] ) or ( Rage >80 and not talents[classtable.OverwhelmingRage] )) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and (buff[classtable.EnrageBuff].up and talents[classtable.RecklessAbandon] and not talents[classtable.WrathandFury]) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up and talents[classtable.AshenJuggernaut]) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and (not buff[classtable.EnrageBuff].up or ( talents[classtable.Annihilator] and not buff[classtable.RecklessnessBuff].up )) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.Onslaught) and CheckSpellCosts(classtable.Onslaught, 'Onslaught')) and (not talents[classtable.Annihilator] and buff[classtable.EnrageBuff].up or talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        return classtable.Onslaught
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.RagingBlow) and CheckSpellCosts(classtable.RagingBlow, 'RagingBlow')) and (cooldown[classtable.RagingBlow].charges >1 and talents[classtable.WrathandFury]) and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and (cooldown[classtable.CrushingBlow].charges >1 and talents[classtable.WrathandFury]) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and (not buff[classtable.EnrageBuff].up or not talents[classtable.WrathandFury]) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and (buff[classtable.EnrageBuff].up and talents[classtable.RecklessAbandon]) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and (not talents[classtable.WrathandFury]) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.RagingBlow) and CheckSpellCosts(classtable.RagingBlow, 'RagingBlow')) and (cooldown[classtable.RagingBlow].charges >= 1) and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Slam) and CheckSpellCosts(classtable.Slam, 'Slam')) and (talents[classtable.Annihilator]) and cooldown[classtable.Slam].ready then
        return classtable.Slam
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.RagingBlow) and CheckSpellCosts(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
end
function Fury:single_target()
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (targets >1 and talents[classtable.ImprovedWhirlwind] and not buff[classtable.MeatCleaverBuff].count <2 and talents[classtable.ImprovedWhirlwind] and not buff[classtable.MeatCleaverBuff].up) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.AshenJuggernautBuff].up and buff[classtable.AshenJuggernautBuff].remains <gcd) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.OdynsFury) and CheckSpellCosts(classtable.OdynsFury, 'OdynsFury')) and (( buff[classtable.EnrageBuff].up and ( targets >1 ) and ( talents[classtable.DancingBlades] and buff[classtable.DancingBladesBuff].remains <5 or not talents[classtable.DancingBlades] ) )) and cooldown[classtable.OdynsFury].ready then
        return classtable.OdynsFury
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (talents[classtable.AngerManagement] and ( buff[classtable.RecklessnessBuff].up or buff[classtable.EnrageBuff].remains <gcd or RagePerc >85 )) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and ((MaxDps.tier and MaxDps.tier[30].count >= 4) and buff[classtable.MercilessAssault].count == 6) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and (( (MaxDps.tier and MaxDps.tier[30].count >= 4) and buff[classtable.MercilessAssault].count == 6 ) or ( not talents[classtable.RecklessAbandon] and buff[classtable.FuriousBloodthirstBuff].up and buff[classtable.EnrageBuff].up and ( not debuff[classtable.GushingWoundDeBuff].duration or buff[classtable.ChampionsMightBuff].up ) )) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and ((MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up and ( targets >1)) and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
    if (MaxDps:FindSpell(classtable.Onslaught) and CheckSpellCosts(classtable.Onslaught, 'Onslaught')) and (buff[classtable.EnrageBuff].up or talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        return classtable.Onslaught
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and (talents[classtable.WrathandFury] and buff[classtable.EnrageBuff].up and not buff[classtable.FuriousBloodthirstBuff].up) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up and not buff[classtable.FuriousBloodthirstBuff].up and buff[classtable.AshenJuggernautBuff].up or buff[classtable.SuddenDeathBuff].remains <= gcd and ( targetHP >35 and talents[classtable.Massacre] or targetHP >20 )) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (talents[classtable.RecklessAbandon] and ( buff[classtable.RecklessnessBuff].up or buff[classtable.EnrageBuff].remains <gcd or RagePerc >85 )) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (talents[classtable.AngerManagement]) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and (buff[classtable.EnrageBuff].up and talents[classtable.RecklessAbandon] and not talents[classtable.WrathandFury]) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (targetHP <35 and talents[classtable.Massacre]) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and (( not buff[classtable.EnrageBuff].up or ( talents[classtable.Annihilator] and not buff[classtable.RecklessnessBuff].up ) ) and not buff[classtable.FuriousBloodthirstBuff].up) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.RagingBlow) and CheckSpellCosts(classtable.RagingBlow, 'RagingBlow')) and (cooldown[classtable.RagingBlow].charges >1 and talents[classtable.WrathandFury]) and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and (cooldown[classtable.CrushingBlow].charges >1 and talents[classtable.WrathandFury] and not buff[classtable.FuriousBloodthirstBuff].up) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and (not buff[classtable.EnrageBuff].up or not talents[classtable.WrathandFury]) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and (buff[classtable.EnrageBuff].up and talents[classtable.RecklessAbandon] and not buff[classtable.FuriousBloodthirstBuff].up) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and (not talents[classtable.WrathandFury] and not buff[classtable.FuriousBloodthirstBuff].up) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.RagingBlow) and CheckSpellCosts(classtable.RagingBlow, 'RagingBlow')) and (cooldown[classtable.RagingBlow].charges >1) and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Slam) and CheckSpellCosts(classtable.Slam, 'Slam')) and (talents[classtable.Annihilator]) and cooldown[classtable.Slam].ready then
        return classtable.Slam
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.RagingBlow) and CheckSpellCosts(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and (not buff[classtable.FuriousBloodthirstBuff].up) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.WreckingThrow) and CheckSpellCosts(classtable.WreckingThrow, 'WreckingThrow')) and cooldown[classtable.WreckingThrow].ready then
        return classtable.WreckingThrow
    end
    --if (MaxDps:FindSpell(classtable.StormBolt) and CheckSpellCosts(classtable.StormBolt, 'StormBolt')) and cooldown[classtable.StormBolt].ready then
    --    return classtable.StormBolt
    --end
end

function Fury:variables()
    st_planning = targets == 1 and (targets <2)
    adds_remain = targets >= 2
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
    RagePerc = (Rage / RageMax) * 100
    classtable.MeatCleaverBuff = 85739
    classtable.AvatarBuff = 107574
    classtable.RecklessnessBuff = 1719
    classtable.AshenJuggernautBuff = 392537
    classtable.EnrageBuff = 184362
    classtable.HurricaneBuff = 390581
    classtable.FuriousBloodthirstBuff = 423211
    classtable.DancingBladesBuff = 391688
    classtable.GushingWoundDeBuff = 385042
    classtable.ChampionsMightBuff = 386284
    classtable.SuddenDeathBuff = 280776
    classtable.MercilessAssault = 409983

    Fury:variables()

    --if (MaxDps:FindSpell(classtable.AutoAttack) and CheckSpellCosts(classtable.AutoAttack, 'AutoAttack')) and cooldown[classtable.AutoAttack].ready then
    --    return classtable.AutoAttack
    --end
    --if (MaxDps:FindSpell(classtable.Charge) and CheckSpellCosts(classtable.Charge, 'Charge')) and (timeInCombat <= 0.5 or (LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >5) and cooldown[classtable.Charge].ready then
    --    return classtable.Charge
    --end
    --if (MaxDps:FindSpell(classtable.HeroicLeap) and CheckSpellCosts(classtable.HeroicLeap, 'HeroicLeap')) and (( raid_event.movement.distance >25 and raid_event.movement.in >45 )) and cooldown[classtable.HeroicLeap].ready then
    --    return classtable.HeroicLeap
    --end
    --if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and cooldown[classtable.Potion].ready then
    --    return classtable.Potion
    --end
    --if (MaxDps:FindSpell(classtable.Pummel) and CheckSpellCosts(classtable.Pummel, 'Pummel')) and (target.debuff.casting.up) and cooldown[classtable.Pummel].ready then
    --    return classtable.Pummel
    --end

    --local precombatCheck = Fury:precombat()
    --if precombatCheck then
    --    return precombatCheck
    --end

    if (MaxDps:FindSpell(classtable.Ravager) and CheckSpellCosts(classtable.Ravager, 'Ravager')) and (cooldown[classtable.Recklessness].remains <3 or buff[classtable.RecklessnessBuff].up) and cooldown[classtable.Ravager].ready then
        return classtable.Ravager
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and (talents[classtable.TitansTorment] and buff[classtable.EnrageBuff].up and not buff[classtable.AvatarBuff].up and cooldown[classtable.OdynsFury].remains or talents[classtable.BerserkersTorment] and buff[classtable.EnrageBuff].up and not buff[classtable.AvatarBuff].up or not talents[classtable.TitansTorment] and not talents[classtable.BerserkersTorment] and ( buff[classtable.RecklessnessBuff].up or ttd <20 )) and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    if (MaxDps:FindSpell(classtable.Recklessness) and CheckSpellCosts(classtable.Recklessness, 'Recklessness')) and ((targets <2) and ( talents[classtable.Annihilator] and cooldown[classtable.ChampionsSpear].remains <1 or cooldown[classtable.Avatar].remains >40 or not talents[classtable.Avatar] or ttd <12 )) and cooldown[classtable.Recklessness].ready then
        return classtable.Recklessness
    end
    if (MaxDps:FindSpell(classtable.Recklessness) and CheckSpellCosts(classtable.Recklessness, 'Recklessness')) and ((targets <2) and not talents[classtable.Annihilator] or ttd <12) and cooldown[classtable.Recklessness].ready then
        return classtable.Recklessness
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and (buff[classtable.EnrageBuff].up and ( ( buff[classtable.FuriousBloodthirstBuff].up and talents[classtable.TitansTorment] ) or not talents[classtable.TitansTorment] or ttd <20 or targets >1 or not (MaxDps.tier and MaxDps.tier[31].count >= 2) ) ) and cooldown[classtable.ChampionsSpear].ready then
        return classtable.ChampionsSpear
    end
    if (targets >= 2) then
        local multi_targetCheck = Fury:multi_target()
        if multi_targetCheck then
            return Fury:multi_target()
        end
    end
    if (targets == 1) then
        local single_targetCheck = Fury:single_target()
        if single_targetCheck then
            return Fury:single_target()
        end
    end

end
