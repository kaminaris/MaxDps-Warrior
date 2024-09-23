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

local Protection = {}

function Protection:precombat()
    if (MaxDps:CheckSpellUsable(classtable.DefensiveStance, 'DefensiveStance')) and not buff[classtable.DefensiveStance].up and cooldown[classtable.DefensiveStance].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.DefensiveStance end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready and not UnitAffectingCombat('player') then
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
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (buff[classtable.ViolentOutburstBuff].up and targets >= 2 and buff[classtable.AvatarBuff].up and talents[classtable.UnstoppableForce]) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (buff[classtable.ViolentOutburstBuff].up and targets >= 4 and buff[classtable.AvatarBuff].up and talents[classtable.UnstoppableForce] and talents[classtable.CrashingThunder] or buff[classtable.ViolentOutburstBuff].up and targets >6 and buff[classtable.AvatarBuff].up and talents[classtable.UnstoppableForce]) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and (Rage >= 70 and talents[classtable.SeismicReverberation] and targets >= 3) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and (Rage <= 60 or buff[classtable.ViolentOutburstBuff].up and targets <= 4 and talents[classtable.CrashingThunder]) and cooldown[classtable.ShieldSlam].ready then
        if not setSpell then setSpell = classtable.ShieldSlam end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and (Rage >= 30 or Rage >= 40 and talents[classtable.BarbaricTraining]) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
end
function Protection:generic()
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (( buff[classtable.ThunderBlastBuff].count == 2 and buff[classtable.BurstofPowerBuff].count <= 1 and buff[classtable.AvatarBuff].up and talents[classtable.UnstoppableForce] )) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and (( buff[classtable.BurstofPowerBuff].count == 2 and buff[classtable.ThunderBlastBuff].count <= 1 or buff[classtable.ViolentOutburstBuff].up ) or Rage <= 70 and talents[classtable.Demolish]) and cooldown[classtable.ShieldSlam].ready then
        if not setSpell then setSpell = classtable.ShieldSlam end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (Rage >= 70 or ( Rage >= 40 and cooldown[classtable.ShieldSlam].ready==false and talents[classtable.Demolish] or Rage >= 50 and cooldown[classtable.ShieldSlam].ready==false ) or buff[classtable.SuddenDeathBuff].up and talents[classtable.SuddenDeath]) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and cooldown[classtable.ShieldSlam].ready then
        if not setSpell then setSpell = classtable.ShieldSlam end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (debuff[classtable.RendDeBuff].remains <= 2 and not buff[classtable.ViolentOutburstBuff].up) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= 2 and not buff[classtable.ViolentOutburstBuff].up) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (( targets >1 or cooldown[classtable.ShieldSlam].ready==false and not buff[classtable.ViolentOutburstBuff].up )) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (( targets >1 or cooldown[classtable.ShieldSlam].ready==false and not buff[classtable.ViolentOutburstBuff].up )) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and (( Rage >= 80 and targetHP >20 or buff[classtable.RevengeBuff].up and targetHP <= 20 and Rage <= 18 and cooldown[classtable.ShieldSlam].ready==false or buff[classtable.RevengeBuff].up and targetHP >20 ) or ( Rage >= 80 and targetHP >35 or buff[classtable.RevengeBuff].up and targetHP <= 35 and Rage <= 18 and cooldown[classtable.ShieldSlam].ready==false or buff[classtable.RevengeBuff].up and targetHP >35 ) and talents[classtable.Massacre]) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (( targets >= 1 or cooldown[classtable.ShieldSlam].ready==false and buff[classtable.ViolentOutburstBuff].up )) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and (( targets >= 1 or cooldown[classtable.ShieldSlam].ready==false and buff[classtable.ViolentOutburstBuff].up )) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.Devastate, 'Devastate')) and not talents[classtable.Devastator] and cooldown[classtable.Devastate].ready then
        if not setSpell then setSpell = classtable.Devastate end
    end
end

function Protection:callaction()
    MaxDps:GlowCooldown(classtable.Pummel,MaxDps:CheckSpellUsable(classtable.Pummel, 'Pummel') and ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    if (MaxDps:CheckSpellUsable(classtable.Charge, 'Charge')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >10) and cooldown[classtable.Charge].ready then
        if not setSpell then setSpell = classtable.Charge end
    end
    MaxDps:GlowCooldown(classtable.Avatar,MaxDps:CheckSpellUsable(classtable.Avatar, 'Avatar') and (not buff[classtable.ThunderBlastBuff].up or buff[classtable.ThunderBlastBuff].count <= 2) and cooldown[classtable.Avatar].ready)
    MaxDps:GlowCooldown(classtable.ShieldWall,MaxDps:CheckSpellUsable(classtable.ShieldWall, 'ShieldWall') and (talents[classtable.ImmovableObject] and not buff[classtable.AvatarBuff].up) and cooldown[classtable.ShieldWall].ready)
    MaxDps:GlowCooldown(classtable.IgnorePain,MaxDps:CheckSpellUsable(classtable.IgnorePain, 'IgnorePain') and (targetHP >= 20 and ( RageDeficit <= 15 and cooldown[classtable.ShieldSlam].ready or RageDeficit <= 40 and cooldown[classtable.ShieldCharge].ready and talents[classtable.ChampionsBulwark] or RageDeficit <= 20 and cooldown[classtable.ShieldCharge].ready or RageDeficit <= 30 and cooldown[classtable.DemoralizingShout].ready and talents[classtable.BoomingVoice] or RageDeficit <= 20 and cooldown[classtable.Avatar].ready or RageDeficit <= 45 and cooldown[classtable.DemoralizingShout].ready and talents[classtable.BoomingVoice] and buff[classtable.LastStandBuff].up and talents[classtable.UnnervingFocus] or RageDeficit <= 30 and cooldown[classtable.Avatar].ready and buff[classtable.LastStandBuff].up and talents[classtable.UnnervingFocus] or RageDeficit <= 20 or RageDeficit <= 40 and cooldown[classtable.ShieldSlam].ready and buff[classtable.ViolentOutburstBuff].up and talents[classtable.HeavyRepercussions] and talents[classtable.ImpenetrableWall] or RageDeficit <= 55 and cooldown[classtable.ShieldSlam].ready and buff[classtable.ViolentOutburstBuff].up and buff[classtable.LastStandBuff].up and talents[classtable.UnnervingFocus] and talents[classtable.HeavyRepercussions] and talents[classtable.ImpenetrableWall] or RageDeficit <= 17 and cooldown[classtable.ShieldSlam].ready and talents[classtable.HeavyRepercussions] or RageDeficit <= 18 and cooldown[classtable.ShieldSlam].ready and talents[classtable.ImpenetrableWall] ) or ( Rage >= 70 or buff[classtable.SeeingRedBuff].count == 7 and Rage >= 35 ) and cooldown[classtable.ShieldSlam].remains <= 1 and buff[classtable.ShieldBlockBuff].remains >= 4 and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.IgnorePain].ready)
    MaxDps:GlowCooldown(classtable.LastStand,MaxDps:CheckSpellUsable(classtable.LastStand, 'LastStand') and (( targetHP >= 90 and talents[classtable.UnnervingFocus] or targetHP <= 20 and talents[classtable.UnnervingFocus] ) or talents[classtable.Bolster] or (MaxDps.tier and MaxDps.tier[30].count >= 2) or (MaxDps.tier and MaxDps.tier[30].count >= 4)) and cooldown[classtable.LastStand].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.Ravager, 'Ravager') and cooldown[classtable.Ravager].ready)
    MaxDps:GlowCooldown(classtable.Ravager,MaxDps:CheckSpellUsable(classtable.DemoralizingShout, 'DemoralizingShout') and talents[classtable.BoomingVoice] and cooldown[classtable.DemoralizingShout].ready)
    MaxDps:GlowCooldown(classtable.ChampionsSpear,MaxDps:CheckSpellUsable(classtable.ChampionsSpear, 'ChampionsSpear') and cooldown[classtable.ChampionsSpear].ready)
    if (MaxDps:CheckSpellUsable(classtable.ThunderBlast, 'ThunderBlast')) and (targets >= 2 and buff[classtable.ThunderBlastBuff].count == 2) and cooldown[classtable.ThunderBlast].ready then
        if not setSpell then setSpell = classtable.ThunderBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Demolish, 'Demolish')) and (buff[classtable.ColossalMightBuff].count >= 3) and cooldown[classtable.Demolish].ready then
        if not setSpell then setSpell = classtable.Demolish end
    end
    MaxDps:GlowCooldown(classtable.ThunderousRoar,MaxDps:CheckSpellUsable(classtable.ThunderousRoar, 'ThunderousRoar') and cooldown[classtable.ThunderousRoar].ready)
    if (MaxDps:CheckSpellUsable(classtable.ShieldCharge, 'ShieldCharge')) and cooldown[classtable.ShieldCharge].ready then
        if not setSpell then setSpell = classtable.ShieldCharge end
    end
    MaxDps:GlowCooldown(classtable.ShieldBlock,MaxDps:CheckSpellUsable(classtable.ShieldBlock, 'ShieldBlock') and (buff[classtable.ShieldBlockBuff].remains <= 10) and cooldown[classtable.ShieldBlock].ready)
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.RendDeBuff = 388539
    classtable.ViolentOutburstBuff = 386478
    classtable.AvatarBuff = 401150
    classtable.ThunderBlastBuff = 0
    classtable.BurstofPowerBuff = 0
    classtable.SuddenDeathBuff = 52437
    classtable.RevengeBuff = 5302
    classtable.LastStandBuff = 12975
    classtable.SeeingRedBuff = 0
    classtable.ShieldBlockBuff = 132404
    classtable.ColossalMightBuff = 0
    setSpell = nil

    Protection:precombat()

    Protection:callaction()
    if setSpell then return setSpell end
end
