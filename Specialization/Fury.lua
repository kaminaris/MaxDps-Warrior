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


function Fury:precombat()
    --if (MaxDps:FindSpell(classtable.BattleShout) and CheckSpellCosts(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready then
    --    return classtable.BattleShout
    --end
    if (MaxDps:FindSpell(classtable.BerserkerStance) and CheckSpellCosts(classtable.BerserkerStance, 'BerserkerStance')) and cooldown[classtable.BerserkerStance].ready then
        return classtable.BerserkerStance
    end
    --if (MaxDps:FindSpell(classtable.Recklessness) and CheckSpellCosts(classtable.Recklessness, 'Recklessness')) and (not CheckEquipped('FyralaththeDreamrender')) and cooldown[classtable.Recklessness].ready then
    --    return classtable.Recklessness
    --end
    --if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and (not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready then
    --    MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    --end
end
function Fury:multi_target()
    if (MaxDps:FindSpell(classtable.Recklessness) and CheckSpellCosts(classtable.Recklessness, 'Recklessness')) and (( not talents[classtable.AngerManagement] and cooldown[classtable.Avatar].remains <1 and talents[classtable.TitansTorment] ) or talents[classtable.AngerManagement] or not talents[classtable.TitansTorment]) and cooldown[classtable.Recklessness].ready then
        return classtable.Recklessness
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and (talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) or not talents[classtable.TitansTorment]) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:FindSpell(classtable.OdynsFury) and CheckSpellCosts(classtable.OdynsFury, 'OdynsFury')) and (debuff[classtable.OdynsFuryTormentMhDeBuff].remains <1 and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) and cooldown[classtable.Avatar].remains) and cooldown[classtable.OdynsFury].ready then
        return classtable.OdynsFury
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (buff[classtable.MeatCleaverBuff].count == 0 and talents[classtable.ImprovedWhirlwind]) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up and buff[classtable.AshenJuggernautBuff].remains <= gcd and talents[classtable.AshenJuggernaut]) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (RagePerc >85 and cooldown[classtable.Bladestorm].remains <= gcd and not debuff[classtable.ChampionsMightDeBuff].up) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and (buff[classtable.EnrageBuff].up and cooldown[classtable.Avatar].remains >= 9) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:FindSpell(classtable.Ravager) and CheckSpellCosts(classtable.Ravager, 'Ravager')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (talents[classtable.AngerManagement]) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and (buff[classtable.FuriousBloodthirstBuff].up) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Onslaught) and CheckSpellCosts(classtable.Onslaught, 'Onslaught')) and (talents[classtable.Tenderize] or buff[classtable.EnrageBuff].up) and cooldown[classtable.Onslaught].ready then
        return classtable.Onslaught
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and (not debuff[classtable.GushingWoundDeBuff].duration) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (talents[classtable.RecklessAbandon]) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up and ( ( targetHP >35 and talents[classtable.Massacre] or targetHP >20 ) and buff[classtable.SuddenDeathBuff].remains <= gcd )) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.RagingBlow) and CheckSpellCosts(classtable.RagingBlow, 'RagingBlow')) and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
end
function Fury:single_target()
    if (MaxDps:FindSpell(classtable.Ravager) and CheckSpellCosts(classtable.Ravager, 'Ravager')) and (cooldown[classtable.Recklessness].remains <gcd or buff[classtable.RecklessnessBuff].up) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:FindSpell(classtable.Recklessness) and CheckSpellCosts(classtable.Recklessness, 'Recklessness')) and (not talents[classtable.AngerManagement] or ( talents[classtable.AngerManagement] and cooldown[classtable.Avatar].ready or cooldown[classtable.Avatar].remains <gcd or cooldown[classtable.Avatar].remains >30 )) and cooldown[classtable.Recklessness].ready then
        return classtable.Recklessness
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and (not talents[classtable.TitansTorment] or ( talents[classtable.TitansTorment] and ( buff[classtable.EnrageBuff].up or talents[classtable.TitanicRage] ) )) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and (buff[classtable.EnrageBuff].up and ( ( buff[classtable.FuriousBloodthirstBuff].up and talents[classtable.TitansTorment] ) or not talents[classtable.TitansTorment] or boss and ttd <20 or targets >1 or not (MaxDps.tier and MaxDps.tier[31].count >= 2) ) and math.huge >15) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:FindSpell(classtable.Whirlwind) and CheckSpellCosts(classtable.Whirlwind, 'Whirlwind')) and (targets >1 and talents[classtable.ImprovedWhirlwind] and not buff[classtable.MeatCleaverBuff].up or math.huge <2 and talents[classtable.ImprovedWhirlwind] and not buff[classtable.MeatCleaverBuff].up) and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.AshenJuggernautBuff].up and buff[classtable.AshenJuggernautBuff].remains <gcd) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Bladestorm) and CheckSpellCosts(classtable.Bladestorm, 'Bladestorm')) and (buff[classtable.EnrageBuff].up and ( buff[classtable.AvatarBuff].up or buff[classtable.RecklessnessBuff].up and talents[classtable.AngerManagement] )) and cooldown[classtable.Bladestorm].ready then
        MaxDps:GlowCooldown(classtable.Bladestorm, cooldown[classtable.Bladestorm].ready)
    end
    if (MaxDps:FindSpell(classtable.OdynsFury) and CheckSpellCosts(classtable.OdynsFury, 'OdynsFury')) and (buff[classtable.EnrageBuff].up and ( targets >1 or math.huge >15 ) and ( talents[classtable.DancingBlades] and buff[classtable.DancingBladesBuff].remains <5 or not talents[classtable.DancingBlades] )) and cooldown[classtable.OdynsFury].ready then
        return classtable.OdynsFury
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (talents[classtable.AngerManagement] and ( buff[classtable.RecklessnessBuff].up or buff[classtable.EnrageBuff].remains <gcd or RagePerc >85 )) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and ((MaxDps.tier and MaxDps.tier[30].count >= 4) and buff[classtable.Bloodthirst].count == 6 ) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and (( (MaxDps.tier and MaxDps.tier[30].count >= 4) and buff[classtable.Bloodthirst].count == 6 ) or ( not talents[classtable.RecklessAbandon] and buff[classtable.FuriousBloodthirstBuff].up and buff[classtable.EnrageBuff].up and ( not debuff[classtable.GushingWoundDeBuff].duration or buff[classtable.ChampionsMightBuff].up ) )) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and (buff[classtable.FuriousBloodthirstBuff].up) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and (buff[classtable.EnrageBuff].up and ( targets >1 or math.huge >15 )) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:FindSpell(classtable.Onslaught) and CheckSpellCosts(classtable.Onslaught, 'Onslaught')) and (buff[classtable.EnrageBuff].up or talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        return classtable.Onslaught
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (talents[classtable.RecklessAbandon] and ( buff[classtable.RecklessnessBuff].up or buff[classtable.EnrageBuff].remains <gcd or RagePerc >85 )) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up and not buff[classtable.FuriousBloodthirstBuff].up and buff[classtable.AshenJuggernautBuff].up or buff[classtable.SuddenDeathBuff].remains <= gcd and ( targetHP >35 and talents[classtable.Massacre] or targetHP >20 )) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.EnrageBuff].up) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (talents[classtable.AngerManagement]) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and (buff[classtable.EnrageBuff].up and talents[classtable.RecklessAbandon]) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and (targetHP <35 and talents[classtable.Massacre]) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and (not buff[classtable.EnrageBuff].up or not buff[classtable.FuriousBloodthirstBuff].up) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.RagingBlow) and CheckSpellCosts(classtable.RagingBlow, 'RagingBlow')) and (cooldown[classtable.RagingBlow].charges >1) and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and (cooldown[classtable.CrushingBlow].charges >1) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Bloodbath) and CheckSpellCosts(classtable.Bloodbath, 'Bloodbath')) and (not buff[classtable.EnrageBuff].up) and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    if (MaxDps:FindSpell(classtable.CrushingBlow) and CheckSpellCosts(classtable.CrushingBlow, 'CrushingBlow')) and (buff[classtable.EnrageBuff].up and talents[classtable.RecklessAbandon]) and cooldown[classtable.CrushingBlow].ready then
        return classtable.CrushingBlow
    end
    if (MaxDps:FindSpell(classtable.Bloodthirst) and CheckSpellCosts(classtable.Bloodthirst, 'Bloodthirst')) and (not buff[classtable.FuriousBloodthirstBuff].up) and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    if (MaxDps:FindSpell(classtable.RagingBlow) and CheckSpellCosts(classtable.RagingBlow, 'RagingBlow')) and (cooldown[classtable.RagingBlow].charges >1) and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    if (MaxDps:FindSpell(classtable.Rampage) and CheckSpellCosts(classtable.Rampage, 'Rampage')) and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
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
    if (MaxDps:FindSpell(classtable.Slam) and CheckSpellCosts(classtable.Slam, 'Slam')) and cooldown[classtable.Slam].ready then
        return classtable.Slam
    end
end
function Fury:trinkets()
end
function Fury:variables()
    st_planning = targets == 1 and ( math.huge >15 or (targets <2) )
    adds_remain = targets >= 2 and ( (targets <2) or (targets >1) and targets >5 )
    execute_phase = ( talents[classtable.Massacre] and targetHP <35 ) or targetHP <20
end

function Fury:callaction()
    if (MaxDps:FindSpell(classtable.Charge) and CheckSpellCosts(classtable.Charge, 'Charge')) and (timeInCombat <= 0.5 or (LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >8) and cooldown[classtable.Charge].ready then
        return classtable.Charge
    end
    if (MaxDps:FindSpell(classtable.HeroicLeap) and CheckSpellCosts(classtable.HeroicLeap, 'HeroicLeap')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >25) and cooldown[classtable.HeroicLeap].ready then
        return classtable.HeroicLeap
    end
    if (MaxDps:FindSpell(classtable.Pummel) and CheckSpellCosts(classtable.Pummel, 'Pummel')) and (UnitCastingInfo('target') and select(8,UnitCastingInfo('target')) == false) and cooldown[classtable.Pummel].ready then
        MaxDps:GlowCooldown(classtable.Pummel, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    local trinketsCheck = Fury:trinkets()
    if trinketsCheck then
        return trinketsCheck
    end
    local variablesCheck = Fury:variables()
    if variablesCheck then
        return variablesCheck
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
    classtable.EnrageBuff = 184362
    classtable.OdynsFuryTormentMhDeBuff = 0
    classtable.MeatCleaverBuff = 85739
    classtable.AshenJuggernautBuff = 392537
    classtable.ChampionsMightDeBuff = 376080
    classtable.FuriousBloodthirstBuff = 423211
    classtable.GushingWoundDeBuff = 385042
    classtable.SuddenDeathBuff = 280776
    classtable.RecklessnessBuff = 1719
    classtable.AvatarBuff = 107574
    classtable.DancingBladesBuff = 391688
    classtable.ChampionsMightBuff = 386284

    local precombatCheck = Fury:precombat()
    if precombatCheck then
        return Fury:precombat()
    end

    local callactionCheck = Fury:callaction()
    if callactionCheck then
        return Fury:callaction()
    end
end
