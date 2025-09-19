local _, addonTable = ...
local Warrior = addonTable.Warrior
local MaxDps = _G.MaxDps
if not MaxDps then return end
local LibStub = LibStub
local setSpell

local ceil = ceil
local floor = floor
local fmod = fmod
local format = format
local max = max
local min = min
local pairs = pairs
local select = select
local strsplit = strsplit
local GetTime = GetTime

local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitSpellHaste = UnitSpellHaste
local UnitThreatSituation = UnitThreatSituation
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
local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetUnitSpeed = GetUnitSpeed
local GetCritChance = GetCritChance
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = C_Item.GetItemInfo
local GetItemSpell = C_Item.GetItemSpell
local GetNamePlates = C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates or GetNamePlates
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellInfo
local GetTotemInfo = GetTotemInfo
local IsStealthed = IsStealthed
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Rage
local RageMax
local RageDeficit
local RagePerc
local RageRegen
local RageRegenCombined
local RageTimeToMax
local victory_rush_health_pct
local victory_rush_health
local last_stand_damage_taken
local last_stand_health_pct
local rallying_cry_damage_taken
local rallying_cry_health_pct
local shield_wall_damage_taken
local shield_wall_health_pct
local spell_block_damage_taken
local spell_block_health_pct

local Protection = {}

function Protection:precombat()
    if (MaxDps:CheckSpellUsable(classtable.DefensiveStance, 'DefensiveStance')) and not buff[classtable.DefensiveStance].up and cooldown[classtable.DefensiveStance].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DefensiveStance end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and not buff[classtable.BattleShout].up and cooldown[classtable.BattleShout].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BattleShout end
    end
end
function Protection:aoe()
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (debuff[classtable.RendDeBuff].remains <= 1) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= 1) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (buff[classtable.ViolentOutburstBuff].up and targets >= 2 and buff[classtable.AvatarBuff].up and (talents[classtable.UnstoppableForce] and true or false)) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (targets >= 2 and (Rage >= 50 or buff[classtable.SuddenDeathBuff].up) and (talents[classtable.HeavyHanded] and true or false)) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (buff[classtable.ViolentOutburstBuff].up and targets >= 4 and buff[classtable.AvatarBuff].up and (talents[classtable.UnstoppableForce] and true or false) and (talents[classtable.CrashingThunder] and true or false) or buff[classtable.ViolentOutburstBuff].up and targets >6 and buff[classtable.AvatarBuff].up and (talents[classtable.UnstoppableForce] and true or false)) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and (Rage >= 70 and (talents[classtable.SeismicReverberation] and true or false) and targets >= 3) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and (Rage <= 60 or buff[classtable.ViolentOutburstBuff].up and targets <= 4 and (talents[classtable.CrashingThunder] and true or false)) and cooldown[classtable.ShieldSlam].ready then
        if not setSpell then setSpell = classtable.ShieldSlam end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and (Rage >= 30 or Rage >= 40 and (talents[classtable.BarbaricTraining] and true or false)) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
end
function Protection:generic()
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and ((buff[classtable.ThunderBlastBuff].count == 2 and buff[classtable.BurstofPowerBuff].count <= 1 and buff[classtable.AvatarBuff].up and (talents[classtable.UnstoppableForce] and true or false))) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and ((buff[classtable.BurstofPowerBuff].count == 2 and buff[classtable.ThunderBlastBuff].count <= 1 or buff[classtable.ViolentOutburstBuff].up) or Rage <= 70 and (talents[classtable.Demolish] and true or false)) and cooldown[classtable.ShieldSlam].ready then
        if not setSpell then setSpell = classtable.ShieldSlam end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (Rage >= 70 or (Rage >= 40 and not cooldown[classtable.ShieldSlam].ready and (talents[classtable.Demolish] and true or false) or Rage >= 50 and not cooldown[classtable.ShieldSlam].ready) or buff[classtable.SuddenDeathBuff].up and (talents[classtable.SuddenDeath] and true or false)) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and cooldown[classtable.ShieldSlam].ready then
        if not setSpell then setSpell = classtable.ShieldSlam end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (debuff[classtable.RendDeBuff].remains <= 2 and not buff[classtable.ViolentOutburstBuff].up) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= 2 and not buff[classtable.ViolentOutburstBuff].up) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and ((targets >1 or not cooldown[classtable.ShieldSlam].ready and not buff[classtable.ViolentOutburstBuff].up)) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and ((targets >1 or not cooldown[classtable.ShieldSlam].ready and not buff[classtable.ViolentOutburstBuff].up)) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and ((Rage >= 80 and targethealthPerc >20 or buff[classtable.RevengeBuff].up and targethealthPerc <= 20 and Rage <= 18 and not cooldown[classtable.ShieldSlam].ready or buff[classtable.RevengeBuff].up and targethealthPerc >20) or (Rage >= 80 and targethealthPerc >35 or buff[classtable.RevengeBuff].up and targethealthPerc <= 35 and Rage <= 18 and not cooldown[classtable.ShieldSlam].ready or buff[classtable.RevengeBuff].up and targethealthPerc >35) and (talents[classtable.Massacre] and true or false)) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and ((targets >= 1 or not cooldown[classtable.ShieldSlam].ready and buff[classtable.ViolentOutburstBuff].up)) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and ((targets >= 1 or not cooldown[classtable.ShieldSlam].ready and buff[classtable.ViolentOutburstBuff].up)) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Devastate, 'Devastate')) and not talents[classtable.Devastator] and cooldown[classtable.Devastate].ready then
        if not setSpell then setSpell = classtable.Devastate end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Pummel, false)
    MaxDps:GlowCooldown(classtable.tome_of_lights_devotion, false)
    MaxDps:GlowCooldown(classtable.Avatar, false)
    MaxDps:GlowCooldown(classtable.ShieldWall, false)
    MaxDps:GlowCooldown(classtable.IgnorePain, false)
    MaxDps:GlowCooldown(classtable.LastStand, false)
    MaxDps:GlowCooldown(classtable.RallyingCry, false)
    MaxDps:GlowCooldown(classtable.VictoryRush, false)
    MaxDps:GlowCooldown(classtable.ImpendingVictory, false)
    MaxDps:GlowCooldown(classtable.Ravager, false)
    MaxDps:GlowCooldown(classtable.DemoralizingShout, false)
    MaxDps:GlowCooldown(classtable.ChampionsSpear, false)
    MaxDps:GlowCooldown(classtable.ThunderousRoar, false)
    MaxDps:GlowCooldown(classtable.ShieldBlock, false)
    MaxDps:GlowCooldown(classtable.Charge, false)
end

function Protection:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Pummel, 'Pummel')) and cooldown[classtable.Pummel].ready then
        MaxDps:GlowCooldown(classtable.Pummel, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.Charge, 'Charge')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >10) and cooldown[classtable.Charge].ready then
        MaxDps:GlowCooldown(classtable.Charge, true)
    end
    if (MaxDps:CheckSpellUsable(classtable.tome_of_lights_devotion, 'tome_of_lights_devotion')) and (buff[classtable.InnerResilienceBuff].up) and cooldown[classtable.tome_of_lights_devotion].ready then
        MaxDps:GlowCooldown(classtable.tome_of_lights_devotion, cooldown[classtable.tome_of_lights_devotion].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar')) and (not buff[classtable.ThunderBlastBuff].up or buff[classtable.ThunderBlastBuff].count <= 2) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldWall, 'ShieldWall')) and ((talents[classtable.ImmovableObject] and true or false) and not buff[classtable.AvatarBuff].up) and cooldown[classtable.ShieldWall].ready then
        MaxDps:GlowCooldown(classtable.ShieldWall, cooldown[classtable.ShieldWall].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.IgnorePain, 'IgnorePain')) and (targethealthPerc >= 20 and (RageDeficit <= 15 and cooldown[classtable.ShieldSlam].ready or RageDeficit <= 40 and cooldown[classtable.ShieldCharge].ready and (talents[classtable.ChampionsBulwark] and true or false) or RageDeficit <= 20 and cooldown[classtable.ShieldCharge].ready or RageDeficit <= 30 and cooldown[classtable.DemoralizingShout].ready and (talents[classtable.BoomingVoice] and true or false) or RageDeficit <= 20 and cooldown[classtable.Avatar].ready or RageDeficit <= 45 and cooldown[classtable.DemoralizingShout].ready and (talents[classtable.BoomingVoice] and true or false) and buff[classtable.LastStandBuff].up and (talents[classtable.UnnervingFocus] and true or false) or RageDeficit <= 30 and cooldown[classtable.Avatar].ready and buff[classtable.LastStandBuff].up and (talents[classtable.UnnervingFocus] and true or false) or RageDeficit <= 20 or RageDeficit <= 40 and cooldown[classtable.ShieldSlam].ready and buff[classtable.ViolentOutburstBuff].up and (talents[classtable.HeavyRepercussions] and true or false) and (talents[classtable.ImpenetrableWall] and true or false) or RageDeficit <= 55 and cooldown[classtable.ShieldSlam].ready and buff[classtable.ViolentOutburstBuff].up and buff[classtable.LastStandBuff].up and (talents[classtable.UnnervingFocus] and true or false) and (talents[classtable.HeavyRepercussions] and true or false) and (talents[classtable.ImpenetrableWall] and true or false) or RageDeficit <= 17 and cooldown[classtable.ShieldSlam].ready and (talents[classtable.HeavyRepercussions] and true or false) or RageDeficit <= 18 and cooldown[classtable.ShieldSlam].ready and (talents[classtable.ImpenetrableWall] and true or false)) or (Rage >= 70 or buff[classtable.SeeingRedBuff].count == 7 and Rage >= 35) and cooldown[classtable.ShieldSlam].remains <= 1 and buff[classtable.ShieldBlockBuff].remains >= 4 and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.IgnorePain].ready then
        MaxDps:GlowCooldown(classtable.IgnorePain, cooldown[classtable.IgnorePain].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LastStand, 'LastStand')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and MaxDps.incoming_damage_5 >last_stand_damage_taken and healthPerc <= last_stand_health_pct and not (buff[classtable.ShieldWallBuff].up or buff[classtable.LastStandBuff].up or buff[classtable.RallyingCryBuff].up or buff[classtable.PotionBuff].up)) and cooldown[classtable.LastStand].ready then
        MaxDps:GlowCooldown(classtable.LastStand, cooldown[classtable.LastStand].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RallyingCry, 'RallyingCry')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and MaxDps.incoming_damage_5 >rallying_cry_damage_taken and healthPerc <= rallying_cry_health_pct and not (buff[classtable.ShieldWallBuff].up or buff[classtable.LastStandBuff].up or buff[classtable.RallyingCryBuff].up or buff[classtable.PotionBuff].up)) and cooldown[classtable.RallyingCry].ready then
        MaxDps:GlowCooldown(classtable.RallyingCry, cooldown[classtable.RallyingCry].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.VictoryRush, 'VictoryRush')) and (healthPerc <victory_rush_health_pct and (talents[classtable.ImpendingVictory] and true or false)) and cooldown[classtable.VictoryRush].ready then
        MaxDps:GlowCooldown(classtable.VictoryRush, cooldown[classtable.VictoryRush].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ImpendingVictory, 'ImpendingVictory') and talents[classtable.ImpendingVictory]) and (healthPerc <victory_rush_health_pct and (talents[classtable.ImpendingVictory] and true or false)) and cooldown[classtable.ImpendingVictory].ready then
        MaxDps:GlowCooldown(classtable.ImpendingVictory, cooldown[classtable.ImpendingVictory].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DemoralizingShout, 'DemoralizingShout')) and ((talents[classtable.BoomingVoice] and true or false)) and cooldown[classtable.DemoralizingShout].ready then
        MaxDps:GlowCooldown(classtable.DemoralizingShout, cooldown[classtable.DemoralizingShout].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (targets >= 2 and buff[classtable.ThunderBlastBuff].count == 2) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish') and talents[classtable.Demolish]) and (buff[classtable.ColossalMightBuff].count >= 3) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldCharge, 'ShieldCharge')) and cooldown[classtable.ShieldCharge].ready then
        if not setSpell then setSpell = classtable.ShieldCharge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldBlock, 'ShieldBlock')) and (buff[classtable.ShieldBlockBuff].remains <= 10) and cooldown[classtable.ShieldBlock].ready then
        MaxDps:GlowCooldown(classtable.ShieldBlock, cooldown[classtable.ShieldBlock].ready)
    end
    if (targets >= 3) then
        Protection:aoe()
    end
    Protection:generic()
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    local trinket1ID = GetInventoryItemID('player', 13)
    local trinket2ID = GetInventoryItemID('player', 14)
    local MHID = GetInventoryItemID('player', 16)
    classtable.trinket1 = (trinket1ID and select(2,GetItemSpell(trinket1ID)) ) or 0
    classtable.trinket2 = (trinket2ID and select(2,GetItemSpell(trinket2ID)) ) or 0
    classtable.main_hand = (MHID and select(2,GetItemSpell(MHID)) ) or 0
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    RagePerc = (Rage / RageMax) * 100
    RageRegen = GetPowerRegenForPowerType(RagePT)
    RageTimeToMax = RageDeficit / RageRegen
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    victory_rush_health_pct = 75
    victory_rush_health = 75
    last_stand_damage_taken = 25 * (maxHP or 0) * 0.01
    last_stand_health_pct = 70
    rallying_cry_damage_taken = 25 * (maxHP or 0) * 0.01
    rallying_cry_health_pct = 80
    shield_wall_damage_taken = 20 * (maxHP or 0) * 0.01
    shield_wall_health_pct = 75
    spell_block_damage_taken = 25 * (maxHP or 0) * 0.01
    spell_block_health_pct = 75
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.InnerResilienceBuff = 0
    classtable.ThunderBlastBuff = 435615
    classtable.AvatarBuff = 107574
    classtable.LastStandBuff = 12975
    classtable.ViolentOutburstBuff = 386478
    classtable.SeeingRedBuff = 386486
    classtable.ShieldBlockBuff = 132404
    classtable.ShieldWallBuff = 871
    classtable.RallyingCryBuff = 97463
    classtable.PotionBuff = 0
    classtable.ColossalMightBuff = 440989
    classtable.SuddenDeathBuff = 52437
    classtable.BurstofPowerBuff = 437121
    classtable.RevengeBuff = 5302
    classtable.RendDeBuff = 388539

    local function debugg()
        talents[classtable.ImmovableObject] = 1
        talents[classtable.ChampionsBulwark] = 1
        talents[classtable.BoomingVoice] = 1
        talents[classtable.UnnervingFocus] = 1
        talents[classtable.HeavyRepercussions] = 1
        talents[classtable.ImpenetrableWall] = 1
        talents[classtable.ImpendingVictory] = 1
        talents[classtable.UnstoppableForce] = 1
        talents[classtable.HeavyHanded] = 1
        talents[classtable.CrashingThunder] = 1
        talents[classtable.SeismicReverberation] = 1
        talents[classtable.BarbaricTraining] = 1
        talents[classtable.Demolish] = 1
        talents[classtable.SuddenDeath] = 1
        talents[classtable.Massacre] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Protection:precombat()

    Protection:callaction()
    if setSpell then return setSpell end
end
