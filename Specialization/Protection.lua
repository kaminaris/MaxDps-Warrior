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

local Protection = {}


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


function Protection:precombat()
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
    --if (MaxDps:FindSpell(classtable.BattleStance) and CheckSpellCosts(classtable.BattleStance, 'BattleStance')) and cooldown[classtable.BattleStance].ready then
    --    return classtable.BattleStance
    --end
end
function Protection:aoe()
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= 1) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.ShieldSlam) and CheckSpellCosts(classtable.ShieldSlam, 'ShieldSlam')) and (( (MaxDps.tier and MaxDps.tier[30].count >= 2) or (MaxDps.tier and MaxDps.tier[30].count >= 4) ) and targets <= 7 or buff[classtable.EarthenTenacityBuff].up) and cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (buff[classtable.ViolentOutburstBuff].up and targets >6 and buff[classtable.AvatarBuff].up and talents[classtable.UnstoppableForce]) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Revenge) and CheckSpellCosts(classtable.Revenge, 'Revenge')) and (Rage >= 70 and talents[classtable.SeismicReverberation] and targets >= 3) and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
    if (MaxDps:FindSpell(classtable.ShieldSlam) and CheckSpellCosts(classtable.ShieldSlam, 'ShieldSlam')) and (Rage <= 60 or buff[classtable.ViolentOutburstBuff].up and targets <= 7) and cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Revenge) and CheckSpellCosts(classtable.Revenge, 'Revenge')) and (Rage >= 30 or Rage >= 40 and talents[classtable.BarbaricTraining]) and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
end
function Protection:generic()
    if (MaxDps:FindSpell(classtable.ShieldSlam) and CheckSpellCosts(classtable.ShieldSlam, 'ShieldSlam')) and cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= 2 and not buff[classtable.ViolentOutburstBuff].up) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (buff[classtable.SuddenDeathBuff].up and talents[classtable.SuddenDeath]) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (( targets >1 or cooldown[classtable.ShieldSlam].remains and not buff[classtable.ViolentOutburstBuff].up )) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Revenge) and CheckSpellCosts(classtable.Revenge, 'Revenge')) and (( Rage >= 80 and targetHP >20 or buff[classtable.RevengeBuff].up and targetHP <= 20 and Rage <= 18 and cooldown[classtable.ShieldSlam].remains or buff[classtable.RevengeBuff].up and targetHP >20 ) or ( Rage >= 80 and targetHP >35 or buff[classtable.RevengeBuff].up and targetHP <= 35 and Rage <= 18 and cooldown[classtable.ShieldSlam].remains or buff[classtable.RevengeBuff].up and targetHP >35 ) and talents[classtable.Massacre]) and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (targets == 1) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Revenge) and CheckSpellCosts(classtable.Revenge, 'Revenge')) and (targetHP >20) and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (( targets >= 1 or cooldown[classtable.ShieldSlam].remains and buff[classtable.ViolentOutburstBuff].up )) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Devastate) and CheckSpellCosts(classtable.Devastate, 'Devastate')) and cooldown[classtable.Devastate].ready then
        return classtable.Devastate
    end
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
    classtable.RendDeBuff = 0
    classtable.EarthenTenacityBuff = 0
    classtable.ViolentOutburstBuff = 0
    classtable.AvatarBuff = 0
    classtable.SuddenDeathBuff = 0
    classtable.RevengeBuff = 0

    --if (MaxDps:FindSpell(classtable.AutoAttack) and CheckSpellCosts(classtable.AutoAttack, 'AutoAttack')) and cooldown[classtable.AutoAttack].ready then
    --    return classtable.AutoAttack
    --end
    --if (MaxDps:FindSpell(classtable.Charge) and CheckSpellCosts(classtable.Charge, 'Charge')) and (timeInCombat == 0) and cooldown[classtable.Charge].ready then
    --    return classtable.Charge
    --end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    if (MaxDps:FindSpell(classtable.ShieldWall) and CheckSpellCosts(classtable.ShieldWall, 'ShieldWall')) and (talents[classtable.ImmovableObject] and not buff[classtable.AvatarBuff].up) and cooldown[classtable.ShieldWall].ready then
        --return classtable.ShieldWall
		MaxDps:GlowCooldown(classtable.ShieldWall, cooldown[classtable.ShieldWall].ready)
    end
    --if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (buff[classtable.AvatarBuff].up or buff[classtable.AvatarBuff].up and targetHP <= 20) and cooldown[classtable.Potion].ready then
    --    return classtable.Potion
    --end
    if (MaxDps:FindSpell(classtable.IgnorePain) and CheckSpellCosts(classtable.IgnorePain, 'IgnorePain')) and (targetHP >= 20 and ( RageDeficit <= 15 and cooldown[classtable.ShieldSlam].ready or RageDeficit <= 40 and cooldown[classtable.ShieldCharge].ready and talents[classtable.ChampionsBulwark] or RageDeficit <= 20 and cooldown[classtable.ShieldCharge].ready or RageDeficit <= 30 and cooldown[classtable.DemoralizingShout].ready and talents[classtable.BoomingVoice] or RageDeficit <= 20 and cooldown[classtable.Avatar].ready or RageDeficit <= 45 and cooldown[classtable.DemoralizingShout].ready and talents[classtable.BoomingVoice] and buff[classtable.LastStandBuff].up and talents[classtable.UnnervingFocus] or RageDeficit <= 30 and cooldown[classtable.Avatar].ready and buff[classtable.LastStandBuff].up and talents[classtable.UnnervingFocus] or RageDeficit <= 20 or RageDeficit <= 40 and cooldown[classtable.ShieldSlam].ready and buff[classtable.ViolentOutburstBuff].up and talents[classtable.HeavyRepercussions] and talents[classtable.ImpenetrableWall] or RageDeficit <= 55 and cooldown[classtable.ShieldSlam].ready and buff[classtable.ViolentOutburstBuff].up and buff[classtable.LastStandBuff].up and talents[classtable.UnnervingFocus] and talents[classtable.HeavyRepercussions] and talents[classtable.ImpenetrableWall] or RageDeficit <= 17 and cooldown[classtable.ShieldSlam].ready and talents[classtable.HeavyRepercussions] or RageDeficit <= 18 and cooldown[classtable.ShieldSlam].ready and talents[classtable.ImpenetrableWall] ) or ( Rage >= 70 or buff[classtable.SeeingRedBuff].count == 7 and Rage >= 35 ) and cooldown[classtable.ShieldSlam].remains <= 1 and buff[classtable.ShieldBlockBuff].remains >= 4 and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.IgnorePain].ready then
        --return classtable.IgnorePain
		MaxDps:GlowCooldown(classtable.IgnorePain, cooldown[classtable.IgnorePain].ready)
    end
    if (MaxDps:FindSpell(classtable.LastStand) and CheckSpellCosts(classtable.LastStand, 'LastStand')) and (( targetHP >= 90 and talents[classtable.UnnervingFocus] or targetHP <= 20 and talents[classtable.UnnervingFocus] ) or talents[classtable.Bolster] or (MaxDps.tier and MaxDps.tier[30].count >= 2) or (MaxDps.tier and MaxDps.tier[30].count >= 4)) and cooldown[classtable.LastStand].ready then
        --return classtable.LastStand
		MaxDps:GlowCooldown(classtable.LastStand, cooldown[classtable.LastStand].ready)
    end
    if (MaxDps:FindSpell(classtable.Ravager) and CheckSpellCosts(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        return classtable.Ravager
    end
    if (MaxDps:FindSpell(classtable.DemoralizingShout) and CheckSpellCosts(classtable.DemoralizingShout, 'DemoralizingShout')) and (talents[classtable.BoomingVoice]) and cooldown[classtable.DemoralizingShout].ready then
        --return classtable.DemoralizingShout
		MaxDps:GlowCooldown(classtable.DemoralizingShout, cooldown[classtable.DemoralizingShout].ready)
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        return classtable.ChampionsSpear
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
    if (MaxDps:FindSpell(classtable.ShieldSlam) and CheckSpellCosts(classtable.ShieldSlam, 'ShieldSlam')) and (buff[classtable.FervidBuff].up) and cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
    if (MaxDps:FindSpell(classtable.Shockwave) and CheckSpellCosts(classtable.Shockwave, 'Shockwave')) and (talents[classtable.SonicBoom] and buff[classtable.AvatarBuff].up and talents[classtable.UnstoppableForce] and not talents[classtable.RumblingEarth] or talents[classtable.SonicBoom] and talents[classtable.RumblingEarth] and targets >= 3) and cooldown[classtable.Shockwave].ready then
        return classtable.Shockwave
    end
    if (MaxDps:FindSpell(classtable.ShieldCharge) and CheckSpellCosts(classtable.ShieldCharge, 'ShieldCharge')) and cooldown[classtable.ShieldCharge].ready then
        return classtable.ShieldCharge
    end
    if (MaxDps:FindSpell(classtable.ShieldBlock) and CheckSpellCosts(classtable.ShieldBlock, 'ShieldBlock')) and (buff[classtable.ShieldBlockBuff].duration <= 10) and cooldown[classtable.ShieldBlock].ready then
        return classtable.ShieldBlock
		--MaxDps:GlowCooldown(classtable.ShieldBlock, cooldown[classtable.ShieldBlock].ready)
    end
    if (targets >= 3) then
        local aoeCheck = Protection:aoe()
        if aoeCheck then
            return Protection:aoe()
        end
    end
    local genericCheck = Protection:generic()
    if genericCheck then
        return genericCheck
    end

end
