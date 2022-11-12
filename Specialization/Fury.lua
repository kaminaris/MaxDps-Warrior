local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end 

local Warrior = addonTable.Warrior
---@type MaxDps
local MaxDps = MaxDps

local FR = {
    Annihilator = 383916,
    Avatar = 107574,
    BerserkerStance = 386196,
    Bloodbath = 335096,
    Bloodthirst = 23881,
    Charge = 100,
    CrushingBlow = 335097,
    ElysianMight = 386285,
    Enrage = 184362,
    Execute = 5308,
    Execute2 = 280735,
    Frenzy = 335082,
    HeroicLeap = 6544,
    ImprovedWhirlwind = 12950,
    Massacre = 206315,
    MeatCleaver = 280392,
    OdynsFury = 385059,
    Onslaught = 315720,
    OverwhelmingRage = 382767,
    Pummel = 6552,
    RagingBlow = 85288,
    Rampage = 184367,
    Ravager = 228920,
    Recklessness = 1719,
    RecklessAbadon = 202751,
    Slam = 1464,
    SpearOfBastion = 376079,
    SuddenDeathAura = 280776,
    Tenderize = 388933,
    ThunderousRoar = 384318,
    TitansTorment = 390135,
    Whirlwind = 190411,
    WhirlwindBuff = 85739,
    WreckingThrow = 384110
}

setmetatable(FR, Warrior.spellMeta)

local function inRange(spellId)
    local slotId = FindSpellBookSlotBySpellID(spellId)
    if not slotId then
        return false
    end

    return UnitExists("target")
            and UnitCanAttack("player", "target")
            and IsSpellInRange(slotId, "spell", "target") == 1
end

function Warrior:Fury()
    local fd = MaxDps.FrameData
    local cooldown = fd.cooldown
    local buff = fd.buff
    local talents = fd.talents
    local targets = MaxDps:SmartAoe()
    local timeToDie = fd.timeToDie

    -- charge,if=time<=0.5|movement.distance>5
    if cooldown[FR.Charge].ready and inRange(FR.Charge) then
        return FR.Charge
    end

    -- ravager,if=cooldown.avatar.remains<3
    if talents[FR.Ravager] and cooldown[FR.Ravager].ready and (cooldown[FR.Avatar].remains < 3) then
        return FR.Ravager
    end

    -- avatar,if=talent.titans_torment&buff.enrage.up&(buff.elysian_might.up|!covenant.kyrian)
    if talents[FR.Avatar] and cooldown[FR.Avatar].ready and (talents[FR.TitansTorment] and buff[FR.Enrage].up and buff[FR.ElysianMight].up) then
        return FR.Avatar
    end

    -- avatar,if=!talent.titans_torment&(buff.recklessness.up|target.time_to_die<20)
    if talents[FR.Avatar] and cooldown[FR.Avatar].ready and (not talents[FR.TitansTorment] and (buff[FR.Recklessness].up or timeToDie < 20)) then
        return FR.Avatar
    end

    -- recklessness,if=talent.annihilator&cooldown.avatar.remains<1|cooldown.avatar.remains>40|!talent.avatar|target.time_to_die<20
    if talents[FR.Recklessness] and cooldown[FR.Recklessness].ready and (talents[FR.Annihilator] and cooldown[FR.Avatar].remains < 1 or cooldown[FR.Avatar].remains > 40 or not talents[FR.Avatar] or timeToDie < 20) then
        return FR.Recklessness
    end

    -- recklessness,if=!talent.annihilator
    if talents[FR.Recklessness] and cooldown[FR.Recklessness].ready and (not talents[FR.Annihilator]) then
        return FR.Recklessness
    end

    -- spear_of_bastion,if=buff.enrage.up&(buff.recklessness.up|buff.avatar.up|target.time_to_die<20)
    if talents[FR.SpearOfBastion] and cooldown[FR.SpearOfBastion].ready and (buff[FR.Enrage].up and (buff[FR.Recklessness].up or buff[FR.Avatar].up or timeToDie < 20)) then
        return FR.SpearOfBastion
    end

    -- whirlwind,if=spell_targets.whirlwind>1&!buff.meat_cleaver.up|raid_event.adds.in<2&!buff.meat_cleaver.up
    if targets > 1 and (not talents[FR.ImprovedWhirlwind] or not buff[FR.WhirlwindBuff].up) then
        return FR.Whirlwind
    end

    -- call_action_list,name=single_target
    return Warrior:FurySingleTarget()
end

local function isSpellAvailable(spellId)
    local slotId = FindSpellBookSlotBySpellID(spellId)
    if not slotId then
        return false
    end

    return select(3, GetSpellBookItemName(slotId, "spell")) == spellId
end

function Warrior:FurySingleTarget()
    local fd = MaxDps.FrameData
    local cooldown = fd.cooldown
    local buff = fd.buff
    local talents = fd.talents
    local targets = MaxDps:SmartAoe()
    local gcd = fd.gcd
    local rage = UnitPower('player', Enum.PowerType.Rage)

    -- rampage,if=buff.recklessness.up|buff.enrage.remains<gcd|(rage>110&talent.overwhelming_rage)|(rage>80&!talent.overwhelming_rage)|buff.frenzy.remains<1.5
    if talents[FR.Rampage] and rage >= 80 and (buff[FR.Recklessness].up or buff[FR.Enrage].remains < gcd or (rage > 110 and talents[FR.OverwhelmingRage]) or (rage > 80 and not talents[FR.OverwhelmingRage]) or buff[FR.Frenzy].remains < 1.5) then
        return FR.Rampage
    end

    local targetHp = MaxDps:TargetPercentHealth() * 100
    local canExecute = ((talents[FR.Massacre] and targetHp < 35) or
            targetHp < 20) or
            buff[FR.SuddenDeathAura].up
    

    local executeSpellId = isSpellAvailable(FR.Execute2) and FR.Execute2 or FR.Execute

    -- execute
    if cooldown[executeSpellId].ready and canExecute then
        return executeSpellId
    end

    local recklessnessEmpowered = buff[FR.Recklessness].up and talents[FR.RecklessAbadon]

    -- bloodthirst,if=buff.enrage.down|(talent.annihilator&!buff.recklessness.up)
    if not recklessnessEmpowered and talents[FR.Bloodthirst] and cooldown[FR.Bloodthirst].ready and (not buff[FR.Enrage].up or (talents[FR.Annihilator] and not buff[FR.Recklessness].up)) then
        return FR.Bloodthirst
    end

    -- thunderous_roar,if=buff.enrage.up&(spell_targets.whirlwind>1|raid_event.adds.in>15)
    if talents[FR.ThunderousRoar] and cooldown[FR.ThunderousRoar].ready and (buff[FR.Enrage].up and targets > 1) then
        return FR.ThunderousRoar
    end

    -- odyns_fury,if=buff.enrage.up&(spell_targets.whirlwind>1|raid_event.adds.in>15)
    if talents[FR.OdynsFury] and cooldown[FR.OdynsFury].ready and (buff[FR.Enrage].up and targets > 1) then
        return FR.OdynsFury
    end

    -- onslaught,if=!talent.annihilator&buff.enrage.up|talent.tenderize
    if talents[FR.Onslaught] and cooldown[FR.Onslaught].ready and (not talents[FR.Annihilator] and buff[FR.Enrage].up or talents[FR.Tenderize]) then
        return FR.Onslaught
    end

    -- raging_blow,if=charges>1
    if not recklessnessEmpowered and talents[FR.RagingBlow] and cooldown[FR.RagingBlow].ready and (cooldown[FR.RagingBlow].charges > 1) then
        return FR.RagingBlow
    end

    -- crushing_blow,if=charges>1
    if recklessnessEmpowered and talents[FR.RagingBlow] and cooldown[FR.CrushingBlow].ready and (cooldown[FR.CrushingBlow].charges > 1) then
        return FR.CrushingBlow
    end

    -- bloodbath,if=buff.enrage.down|talent.annihilator
    if recklessnessEmpowered and talents[FR.Bloodthirst] and cooldown[FR.Bloodbath].ready and (not buff[FR.Enrage].up or talents[FR.Annihilator]) then
        return FR.Bloodbath
    end

    -- bloodthirst,if=talent.annihilator
    if not recklessnessEmpowered and talents[FR.Bloodthirst] and cooldown[FR.Bloodthirst].ready and (talents[FR.Annihilator]) then
        return FR.Bloodthirst
    end

    -- rampage
    if talents[FR.Rampage] and rage >= 80 then
        return FR.Rampage
    end

    -- slam,if=talent.annihilator
    if rage >= 20 and (talents[FR.Annihilator]) then
        return FR.Slam
    end

    -- bloodthirst,if=!talent.annihilator
    if not recklessnessEmpowered and talents[FR.Bloodthirst] and cooldown[FR.Bloodthirst].ready and (not talents[FR.Annihilator]) then
        return FR.Bloodthirst
    end

    -- bloodbath
    if recklessnessEmpowered and talents[FR.Bloodthirst] and cooldown[FR.Bloodbath].ready then
        return FR.Bloodbath
    end

    -- raging_blow
    if not recklessnessEmpowered and talents[FR.RagingBlow] and cooldown[FR.RagingBlow].ready then
        return FR.RagingBlow
    end

    -- crushing_blow
    if recklessnessEmpowered and talents[FR.RagingBlow] and cooldown[FR.CrushingBlow].ready then
        return FR.CrushingBlow
    end

    -- whirlwind
    return FR.Whirlwind
end

