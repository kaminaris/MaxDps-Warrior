local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local Warrior = addonTable.Warrior
local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local PowerTypeRage = Enum.PowerType.Rage

local fd
local cooldown
local buff
local talents
local targets
local rage
local rageMax
local rageDeficit
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc

local className, classFilename, classId = UnitClass("player")
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
local classtable

--setmetatable(classtable, Warrior.spellMeta)

function Warrior:Fury()
	fd = MaxDps.FrameData
	cooldown = fd.cooldown
	buff = fd.buff
	talents = fd.talents
	targets = MaxDps:SmartAoe()
	rage = UnitPower('player', PowerTypeRage)
	rageMax = UnitPowerMax('player', PowerTypeRage)
	rageDeficit = rageMax - rage
	targetHP = UnitHealth('target')
	targetmaxHP = UnitHealthMax('target')
	targethealthPerc = (targetHP / targetmaxHP) * 100
	curentHP = UnitHealth('player')
	maxHP = UnitHealthMax('player')
	healthPerc = (curentHP / maxHP) * 100
	classtable = MaxDps.SpellTable
    classtable.MeatCleaver = 85739
    classtable.MercilessAssault = 409983
    classtable.Enrage = 184362

    if targets > 1  then
        return Warrior:FuryMultiTarget()
    end

    return Warrior:FurySingleTarget()
end

function Warrior:FurySingleTarget()
    --Cast Ravager on the pull, or as soon as the target is well positioned and not expected to move.
    if talents[classtable.Ravager] and cooldown[classtable.Ravager].ready then
        return classtable.Ravager
    end
    --Cast Recklessness on cooldown or whenever burst damage is needed.
    if talents[classtable.Recklessness] and cooldown[classtable.Recklessness].ready then
        return classtable.Recklessness
    end

    -- OdynsFury before avatar
    if MaxDps.tier[31] and MaxDps.tier[31].count >= 4 and talents[classtable.OdynsFury] and talents[classtable.Avatar] and cooldown[classtable.Avatar].ready and cooldown[classtable.OdynsFury].ready then
        return classtable.OdynsFury
    end

    --Cast Avatar alongside Recklessness.
    if talents[classtable.Avatar] and buff[classtable.Recklessness].up and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    --Cast Spear of Bastion during Recklessness and while Enraged.
    if talents[classtable.SpearofBastion] and buff[classtable.Recklessness].up and buff[classtable.Enrage].up and cooldown[classtable.SpearofBastion].ready then
        return classtable.SpearofBastion
    end
    --Cast Odyn's Fury while Enraged. With the T31 set bonus, it should always be used before Avatar.
    if talents[classtable.OdynsFury] and buff[classtable.Enrage].up and cooldown[classtable.OdynsFury].ready then
        return classtable.OdynsFury
    end
    --Cast Avatar as the initial 4-second Avatar buff triggered by Odyn's Fury is falling off in order to maximize DoT and Dancing Blades uptime.
    if talents[classtable.Avatar] and (buff[classtable.Avatar].duration <= 1 and not cooldown[classtable.OdynsFury].ready) and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    --Cast Bloodthirst when it has a 100% chance to crit through the Merciless Assault buff (generally 6 stacks with Recklessness).
    if talents[classtable.Bloodthirst] and buff[classtable.MercilessAssault].count == 6 and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    --Cast Bloodbath to consume the Reckless Abandon buff.
    if buff[classtable.RecklessAbandon].up and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    --Cast Thunderous Roar while Enraged.
    if talents[classtable.ThunderousRoar] and buff[classtable.Enrage].up and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
    --Cast Onslaught while Enraged or with Tenderize talented.
    if talents[classtable.Onslaught] and (buff[classtable.Enrage].up or talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        return classtable.Onslaught
    end
    --Cast Execute only while the Furious Bloodthirst buff is not active.
    if (not buff[classtable.FuriousBloodthirst].up) and targethealthPerc < 20 and rage >= 30 and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    --Cast Rampage to spend Rage and maintain Enrage.
    if talents[classtable.Rampage] and rage >= 80 and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    --Cast Execute as able.
    if rage >= 30 and targethealthPerc < 20 and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    --Cast Raging Blow as the main rotational attack.
    if talents[classtable.RagingBlow] and not talents[classtable.Annihilator] and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    --Cast Bloodthirst on cooldown to reduce gaps in the rotation.
    if talents[classtable.Bloodthirst] and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    --Cast Slam as a filler between Bloodthirst casts.
    if not talents[classtable.Annihilator] and rage >= 20 and cooldown[classtable.Slam].ready then
        return classtable.Slam
    end
    --Cast Whirlwind as a filler between Bloodthirst casts.
    if cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
end

function Warrior:FuryMultiTarget()
    --Cast Ravager on the pull, or as soon as the target is well positioned and not expected to move.
    if talents[classtable.Ravager] and cooldown[classtable.Ravager].ready then
        return classtable.Ravager
    end
    --Cast Recklessness.
    if talents[classtable.Recklessness] and cooldown[classtable.Recklessness].ready then
        return classtable.Recklessness
    end
    --Cast Avatar with Recklessness.
    if talents[classtable.Avatar] and buff[classtable.Recklessness].up and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
    --Cast Charge whenever out of range.

    --Cast Whirlwind when the buff is not active.
    if not buff[classtable.MeatCleaver].up and cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
    --Cast Odyn's Fury while Enraged or with Titanic Rage.
    if talents[classtable.OdynsFury] and (buff[classtable.Enrage].up or talents[classtable.TitanicRage]) and cooldown[classtable.OdynsFury].ready then
        return classtable.OdynsFury
    end
    --Cast Spear of Bastion while Enraged.
    if talents[classtable.SpearofBastion] and buff[classtable.Enrage].up and cooldown[classtable.SpearofBastion].ready then
        return classtable.SpearofBastion
    end
    --Cast Thunderous Roar while Enraged.
    if talents[classtable.ThunderousRoar] and buff[classtable.Enrage].up and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
    --Cast Avatar to trigger Odyn's Fury via Titan's Torment. When Titanic Rage is talented, delay until the initial Whirlwind buff stacks have fallen.
    if talents[classtable.Avatar] and (talents[classtable.TitansTorment] and cooldown[classtable.Avatar].ready) or ((talents[classtable.TitansTorment] and not buff[classtable.MeatCleaver].up) and cooldown[classtable.Avatar].ready) then
        return classtable.Avatar
    end
    --Cast Bloodthirst when it has a 100% chance to crit through the Merciless Assault buff (generally 6 stacks with Recklessness).
    if buff[classtable.MercilessAssault].count == 6 and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    --Cast Bloodbath to consume the Reckless Abandon buff.
    if buff[classtable.RecklessAbandon].up and cooldown[classtable.Bloodbath].ready then
        return classtable.Bloodbath
    end
    --Cast Onslaught while Enraged or with Tenderize talented.
    if talents[classtable.Onslaught] and (buff[classtable.Enrage].up or talents[classtable.Tenderize]) and cooldown[classtable.Onslaught].ready then
        return classtable.Onslaught
    end
    --Cast Execute only while the Furious Bloodthirst buff is not active.
    if rage >= 30 and targethealthPerc < 20 and not buff[classtable.FuriousBloodthirst].up and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    --Cast Rampage to spend Rage and maintain Enrage.
    if talents[classtable.Rampage] and rage >= 80 and cooldown[classtable.Rampage].ready then
        return classtable.Rampage
    end
    --Cast Execute as able.
    if rage >= 30 and targethealthPerc < 20 and cooldown[classtable.Execute].ready then
        return classtable.Execute
    end
    --Cast Raging Blow as the main rotational attack.
    if talents[classtable.RagingBlow] and not talents[classtable.Annihilator] and cooldown[classtable.RagingBlow].ready then
        return classtable.RagingBlow
    end
    --Cast Bloodthirst on cooldown to reduce gaps in the rotation.
    if talents[classtable.Bloodthirst] and cooldown[classtable.Bloodthirst].ready then
        return classtable.Bloodthirst
    end
    --Cast Slam as a filler between Bloodthirst casts.
    if not talents[classtable.Annihilator] and rage >= 20 and cooldown[classtable.Slam].ready then
        return classtable.Slam
    end
    --Cast Whirlwind as a filler between Bloodthirst casts.
    if cooldown[classtable.Whirlwind].ready then
        return classtable.Whirlwind
    end
end

