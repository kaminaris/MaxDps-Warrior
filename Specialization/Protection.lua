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


function Protection:precombat()
    if (MaxDps:FindSpell(classtable.BattleStance) and CheckSpellCosts(classtable.BattleStance, 'BattleStance')) and cooldown[classtable.BattleStance].ready then
        return classtable.BattleStance
    end
    --if (MaxDps:FindSpell(classtable.BattleShout) and CheckSpellCosts(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready then
    --    return classtable.BattleShout
    --end
end
function Protection:aoe()
    if (MaxDps:FindSpell(classtable.ThunderBlast) and CheckSpellCosts(classtable.ThunderBlast, 'ThunderBlast')) and (debuff[classtable.RendDeBuff].remains <= 1) and cooldown[classtable.ThunderBlast].ready then
        return classtable.ThunderBlast
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= 1) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.ThunderBlast) and CheckSpellCosts(classtable.ThunderBlast, 'ThunderBlast')) and (buff[classtable.ViolentOutburstBuff].up and targets >= 2 and buff[classtable.AvatarBuff].up and talents[classtable.UnstoppableForce]) and cooldown[classtable.ThunderBlast].ready then
        return classtable.ThunderBlast
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (buff[classtable.ViolentOutburstBuff].up and targets >= 4 and buff[classtable.AvatarBuff].up and talents[classtable.UnstoppableForce] and talents[classtable.CrashingThunder] or buff[classtable.ViolentOutburstBuff].up and targets >6 and buff[classtable.AvatarBuff].up and talents[classtable.UnstoppableForce]) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Revenge) and CheckSpellCosts(classtable.Revenge, 'Revenge')) and (Rage >= 70 and talents[classtable.SeismicReverberation] and targets >= 3) and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
    if (MaxDps:FindSpell(classtable.ShieldSlam) and CheckSpellCosts(classtable.ShieldSlam, 'ShieldSlam')) and (Rage <= 60 or buff[classtable.ViolentOutburstBuff].up and targets <= 4 and talents[classtable.CrashingThunder]) and cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
    if (MaxDps:FindSpell(classtable.ThunderBlast) and CheckSpellCosts(classtable.ThunderBlast, 'ThunderBlast')) and cooldown[classtable.ThunderBlast].ready then
        return classtable.ThunderBlast
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Revenge) and CheckSpellCosts(classtable.Revenge, 'Revenge')) and (Rage >= 30 or Rage >= 40 and talents[classtable.BarbaricTraining]) and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
end
function Protection:generic()
    if (MaxDps:FindSpell(classtable.ThunderBlast) and CheckSpellCosts(classtable.ThunderBlast, 'ThunderBlast')) and (( buff[classtable.ThunderBlastBuff].count == 2 and buff[classtable.BurstofPowerBuff].count <= 1 and buff[classtable.AvatarBuff].up and talents[classtable.UnstoppableForce] ) or Rage <= 70 and talents[classtable.Demolish]) and cooldown[classtable.ThunderBlast].ready then
        return classtable.ThunderBlast
    end
    if (MaxDps:FindSpell(classtable.ShieldSlam) and CheckSpellCosts(classtable.ShieldSlam, 'ShieldSlam')) and (( buff[classtable.BurstofPowerBuff].count == 2 and buff[classtable.ThunderBlastBuff].count <= 1 or buff[classtable.ViolentOutburstBuff].up ) or Rage <= 70 and talents[classtable.Demolish]) and cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and (Rage >= 70 or ( Rage >= 40 and cooldown[classtable.ShieldSlam].ready==false and talents[classtable.Demolish] or Rage >= 50 and cooldown[classtable.ShieldSlam].ready==false ) or buff[classtable.SuddenDeathBuff].up and talents[classtable.SuddenDeath]) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.ShieldSlam) and CheckSpellCosts(classtable.ShieldSlam, 'ShieldSlam')) and cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
    if (MaxDps:FindSpell(classtable.ThunderBlast) and CheckSpellCosts(classtable.ThunderBlast, 'ThunderBlast')) and (debuff[classtable.RendDeBuff].remains <= 2 and not buff[classtable.ViolentOutburstBuff].up) and cooldown[classtable.ThunderBlast].ready then
        return classtable.ThunderBlast
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (debuff[classtable.RendDeBuff].remains <= 2 and not buff[classtable.ViolentOutburstBuff].up) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.ThunderBlast) and CheckSpellCosts(classtable.ThunderBlast, 'ThunderBlast')) and (( targets >1 or cooldown[classtable.ShieldSlam].ready==false and not buff[classtable.ViolentOutburstBuff].up )) and cooldown[classtable.ThunderBlast].ready then
        return classtable.ThunderBlast
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (( targets >1 or cooldown[classtable.ShieldSlam].ready==false and not buff[classtable.ViolentOutburstBuff].up )) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Revenge) and CheckSpellCosts(classtable.Revenge, 'Revenge')) and (( Rage >= 80 and targetHP >20 or buff[classtable.RevengeBuff].up and targetHP <= 20 and Rage <= 18 and cooldown[classtable.ShieldSlam].ready==false or buff[classtable.RevengeBuff].up and targetHP >20 ) or ( Rage >= 80 and targetHP >35 or buff[classtable.RevengeBuff].up and targetHP <= 35 and Rage <= 18 and cooldown[classtable.ShieldSlam].ready==false or buff[classtable.RevengeBuff].up and targetHP >35 ) and talents[classtable.Massacre]) and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
    if (MaxDps:FindSpell(classtable.Execute) and CheckSpellCosts(classtable.Execute, 'Execute')) and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    if (MaxDps:FindSpell(classtable.Revenge) and CheckSpellCosts(classtable.Revenge, 'Revenge')) and (targetHP >20) and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
    if (MaxDps:FindSpell(classtable.ThunderBlast) and CheckSpellCosts(classtable.ThunderBlast, 'ThunderBlast')) and (( targets >= 1 or cooldown[classtable.ShieldSlam].ready==false and buff[classtable.ViolentOutburstBuff].up )) and cooldown[classtable.ThunderBlast].ready then
        return classtable.ThunderBlast
    end
    if (MaxDps:FindSpell(classtable.ThunderClap) and CheckSpellCosts(classtable.ThunderClap, 'ThunderClap')) and (( targets >= 1 or cooldown[classtable.ShieldSlam].ready==false and buff[classtable.ViolentOutburstBuff].up )) and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
    if (MaxDps:FindSpell(classtable.Devastate) and CheckSpellCosts(classtable.Devastate, 'Devastate')) and cooldown[classtable.Devastate].ready then
        return classtable.Devastate
    end
end

function Protection:callaction()
    if (MaxDps:FindSpell(classtable.Pummel) and CheckSpellCosts(classtable.Pummel, 'Pummel')) and cooldown[classtable.Pummel].ready then
        MaxDps:GlowCooldown(classtable.Pummel, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:FindSpell(classtable.Charge) and CheckSpellCosts(classtable.Charge, 'Charge')) and (timeInCombat == 0 or (LibRangeCheck and LibRangeCheck:GetRange('target', true) or 0) >8) and cooldown[classtable.Charge].ready then
        return classtable.Charge
    end
    if (MaxDps:FindSpell(classtable.Avatar) and CheckSpellCosts(classtable.Avatar, 'Avatar')) and cooldown[classtable.Avatar].ready then
        MaxDps:GlowCooldown(classtable.Avatar, cooldown[classtable.Avatar].ready)
    end
    if (MaxDps:FindSpell(classtable.ShieldWall) and CheckSpellCosts(classtable.ShieldWall, 'ShieldWall')) and (talents[classtable.ImmovableObject] and not buff[classtable.AvatarBuff].up) and cooldown[classtable.ShieldWall].ready then
        MaxDps:GlowCooldown(classtable.ShieldWall, cooldown[classtable.ShieldWall].ready)
    end
    if (MaxDps:FindSpell(classtable.IgnorePain) and CheckSpellCosts(classtable.IgnorePain, 'IgnorePain')) and (targetHP >= 20 and ( RageDeficit <= 15 and cooldown[classtable.ShieldSlam].ready or RageDeficit <= 40 and cooldown[classtable.ShieldCharge].ready and talents[classtable.ChampionsBulwark] or RageDeficit <= 20 and cooldown[classtable.ShieldCharge].ready or RageDeficit <= 30 and cooldown[classtable.DemoralizingShout].ready and talents[classtable.BoomingVoice] or RageDeficit <= 20 and cooldown[classtable.Avatar].ready or RageDeficit <= 45 and cooldown[classtable.DemoralizingShout].ready and talents[classtable.BoomingVoice] and buff[classtable.LastStandBuff].up and talents[classtable.UnnervingFocus] or RageDeficit <= 30 and cooldown[classtable.Avatar].ready and buff[classtable.LastStandBuff].up and talents[classtable.UnnervingFocus] or RageDeficit <= 20 or RageDeficit <= 40 and cooldown[classtable.ShieldSlam].ready and buff[classtable.ViolentOutburstBuff].up and talents[classtable.HeavyRepercussions] and talents[classtable.ImpenetrableWall] or RageDeficit <= 55 and cooldown[classtable.ShieldSlam].ready and buff[classtable.ViolentOutburstBuff].up and buff[classtable.LastStandBuff].up and talents[classtable.UnnervingFocus] and talents[classtable.HeavyRepercussions] and talents[classtable.ImpenetrableWall] or RageDeficit <= 17 and cooldown[classtable.ShieldSlam].ready and talents[classtable.HeavyRepercussions] or RageDeficit <= 18 and cooldown[classtable.ShieldSlam].ready and talents[classtable.ImpenetrableWall] ) or ( Rage >= 70 or buff[classtable.SeeingRedBuff].count == 7 and Rage >= 35 ) and cooldown[classtable.ShieldSlam].remains <= 1 and buff[classtable.ShieldBlockBuff].remains >= 4 and (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.IgnorePain].ready then
        MaxDps:GlowCooldown(classtable.IgnorePain, cooldown[classtable.IgnorePain].ready)
    end
    if (MaxDps:FindSpell(classtable.LastStand) and CheckSpellCosts(classtable.LastStand, 'LastStand')) and (( targetHP >= 90 and talents[classtable.UnnervingFocus] or targetHP <= 20 and talents[classtable.UnnervingFocus] ) or talents[classtable.Bolster] or (MaxDps.tier and MaxDps.tier[30].count >= 2) or (MaxDps.tier and MaxDps.tier[30].count >= 4)) and cooldown[classtable.LastStand].ready then
        MaxDps:GlowCooldown(classtable.LastStand, cooldown[classtable.LastStand].ready)
    end
    if (MaxDps:FindSpell(classtable.Ravager) and CheckSpellCosts(classtable.Ravager, 'Ravager')) and cooldown[classtable.Ravager].ready then
        MaxDps:GlowCooldown(classtable.Ravager, cooldown[classtable.Ravager].ready)
    end
    if (MaxDps:FindSpell(classtable.DemoralizingShout) and CheckSpellCosts(classtable.DemoralizingShout, 'DemoralizingShout')) and (talents[classtable.BoomingVoice]) and cooldown[classtable.DemoralizingShout].ready then
        return classtable.DemoralizingShout
    end
    if (MaxDps:FindSpell(classtable.ChampionsSpear) and CheckSpellCosts(classtable.ChampionsSpear, 'ChampionsSpear')) and cooldown[classtable.ChampionsSpear].ready then
        MaxDps:GlowCooldown(classtable.ChampionsSpear, cooldown[classtable.ChampionsSpear].ready)
    end
    if (MaxDps:FindSpell(classtable.Demolish) and CheckSpellCosts(classtable.Demolish, 'Demolish')) and (buff[classtable.ColossalMightBuff].count >= 3) and cooldown[classtable.Demolish].ready then
        return classtable.Demolish
    end
    if (MaxDps:FindSpell(classtable.ThunderousRoar) and CheckSpellCosts(classtable.ThunderousRoar, 'ThunderousRoar')) and cooldown[classtable.ThunderousRoar].ready then
        MaxDps:GlowCooldown(classtable.ThunderousRoar, cooldown[classtable.ThunderousRoar].ready)
    end
    if (MaxDps:FindSpell(classtable.Shockwave) and CheckSpellCosts(classtable.Shockwave, 'Shockwave')) and (talents[classtable.RumblingEarth] and targets >= 3) and cooldown[classtable.Shockwave].ready then
        MaxDps:GlowCooldown(classtable.Shockwave, cooldown[classtable.Shockwave].ready)
    end
    if (MaxDps:FindSpell(classtable.ShieldCharge) and CheckSpellCosts(classtable.ShieldCharge, 'ShieldCharge')) and cooldown[classtable.ShieldCharge].ready then
        return classtable.ShieldCharge
    end
    if (MaxDps:FindSpell(classtable.ShieldBlock) and CheckSpellCosts(classtable.ShieldBlock, 'ShieldBlock')) and (buff[classtable.ShieldBlockBuff].duration <= 10) and cooldown[classtable.ShieldBlock].ready then
        MaxDps:GlowCooldown(classtable.ShieldBlock, cooldown[classtable.ShieldBlock].ready)
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
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
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

    local precombatCheck = Protection:precombat()
    if precombatCheck then
        return Protection:precombat()
    end

    local callactionCheck = Protection:callaction()
    if callactionCheck then
        return Protection:callaction()
    end
end
