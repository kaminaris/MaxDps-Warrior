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

local Prot = {}

function Prot:precombat()
    -- Precombat logic can be added here if needed
end

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Revenge, false)
    MaxDps:GlowCooldown(classtable.ShieldSlam, false)
    MaxDps:GlowCooldown(classtable.DragonRoar, false)
    MaxDps:GlowCooldown(classtable.StormBolt, false)
end

function Prot:single()
    -- Single Target Priority
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and cooldown[classtable.ShieldSlam].ready then
        if not setSpell then setSpell = classtable.ShieldSlam end
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldBlock, 'ShieldBlock')) and cooldown[classtable.ShieldBlock].ready then
        MaxDps:GlowCooldown(classtable.ShieldBlock, cooldown[classtable.ShieldBlock].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldBarrier, 'ShieldBarrier')) and cooldown[classtable.ShieldBarrier].ready then
        MaxDps:GlowCooldown(classtable.ShieldBarrier, cooldown[classtable.ShieldBarrier].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StormBolt, 'StormBolt')) and cooldown[classtable.StormBolt].ready then
        if not setSpell then setSpell = classtable.StormBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.DragonRoar, 'DragonRoar')) and cooldown[classtable.DragonRoar].ready then
        MaxDps:GlowCooldown(classtable.DragonRoar, cooldown[classtable.DragonRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (targethealthPerc < 20) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.Devastate, 'Devastate')) and cooldown[classtable.Devastate].ready then
        if not setSpell then setSpell = classtable.Devastate end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeroicStrike, 'HeroicStrike')) and (buff[classtable.UltimatumBuff].up or talents[classtable.GlyphOfIncite]) and cooldown[classtable.HeroicStrike].ready then
        if not setSpell then setSpell = classtable.HeroicStrike end
    end
end

function Prot:Aoe()
    if (MaxDps:CheckSpellUsable(classtable.ThunderClap, 'ThunderClap')) and cooldown[classtable.ThunderClap].ready then
        if not setSpell then setSpell = classtable.ThunderClap end
    end
    if (MaxDps:CheckSpellUsable(classtable.DragonRoar, 'DragonRoar')) and cooldown[classtable.DragonRoar].ready then
        MaxDps:GlowCooldown(classtable.DragonRoar, cooldown[classtable.DragonRoar].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Revenge, 'Revenge')) and cooldown[classtable.Revenge].ready then
        if not setSpell then setSpell = classtable.Revenge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldSlam, 'ShieldSlam')) and cooldown[classtable.ShieldSlam].ready then
        if not setSpell then setSpell = classtable.ShieldSlam end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldBlock, 'ShieldBlock')) and cooldown[classtable.ShieldBlock].ready then
        MaxDps:GlowCooldown(classtable.ShieldBlock, cooldown[classtable.ShieldBlock].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShieldBarrier, 'ShieldBarrier')) and cooldown[classtable.ShieldBarrier].ready then
        MaxDps:GlowCooldown(classtable.ShieldBarrier, cooldown[classtable.ShieldBarrier].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Execute, 'Execute')) and (targethealthPerc < 20) and cooldown[classtable.Execute].ready then
        if not setSpell then setSpell = classtable.Execute end
    end
    if (MaxDps:CheckSpellUsable(classtable.BattleShout, 'BattleShout')) and cooldown[classtable.BattleShout].ready then
        if not setSpell then setSpell = classtable.BattleShout end
    end
    if (MaxDps:CheckSpellUsable(classtable.Cleave, 'Cleave')) and (buff[classtable.UltimatumBuff].up or talents[classtable.GlyphOfIncite]) and cooldown[classtable.Cleave].ready then
        if not setSpell then setSpell = classtable.Cleave end
    end
end

function Prot:callaction()
    if targets > 1 then
        Prot:Aoe()
    end
    Prot:single()
end

function Warrior:Prot()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    RagePerc = (Rage / RageMax) * 100

    --classtable.ShieldSlam = 23922
    --classtable.Revenge = 6572
    --classtable.ShieldBlock = 2565
    --classtable.ShieldBarrier = 112048
    --classtable.StormBolt = 107570
    --classtable.DragonRoar = 118000
    --classtable.Execute = 5308
    --classtable.Devastate = 20243
    --classtable.ThunderClap = 6343
    --classtable.BattleShout = 6673
    --classtable.HeroicStrike = 78
    --classtable.Cleave = 845
    classtable.UltimatumBuff = 122510
    classtable.GlyphOfIncite = 146974

    setSpell = nil
    ClearCDs()

    Prot:precombat()
    Prot:callaction()
    if setSpell then return setSpell end
end