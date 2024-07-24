local _, addonTable = ...

--- @type MaxDps
if not MaxDps then
	return
end

local Warrior = addonTable.Warrior
local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local GetSpellDescription = GetSpellDescription
local GetSpellPowerCost = C_Spell.GetSpellPowerCost
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local PowerTypeRage = Enum.PowerType.Rage

local fd
local cooldown
local buff
local debuff
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

function Warrior:Protection()
	fd = MaxDps.FrameData
	cooldown = fd.cooldown
	buff = fd.buff
	debuff = fd.debuff
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
	classtable.SuddenDeathBuff = 52437
	--setmetatable(classtable, Warrior.spellMeta)

	if targets > 1 then
		return Warrior:ProtectionMultiTarget()
	end

	return Warrior:ProtectionSingleTarget()
end



function Warrior:ProtectionSingleTarget()
	--Cast Avatar on cooldown
	if talents[classtable.Avatar] and cooldown[classtable.Avatar].ready then
        return classtable.Avatar
    end
	--Cast Demoralizing Shout on cooldown (only with Booming Voice Icon Booming Voice).
	if talents[classtable.DemoralizingShout] and cooldown[classtable.DemoralizingShout].ready then
        return classtable.DemoralizingShout
    end
	--Cast Ravager
	if talents[classtable.Ravager] and cooldown[classtable.Ravager].ready then
        return classtable.Ravager
    end
	--Cast Thunderous Roar
	if talents[classtable.ThunderousRoar] and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
	--Cast Shield Charge
	if talents[classtable.ShieldCharge] and cooldown[classtable.ShieldCharge].ready then
        return classtable.ShieldCharge
    end
	--Cast Spear of Bastion
	if talents[classtable.SpearofBastion] and cooldown[classtable.SpearofBastion].ready then
        return classtable.SpearofBastion
    end
    if (not talents[classtable.BloodandThunder]) and talents[classtable.Rend] and rage >= 30 and (not debuff[classtable.RendDebuff] or debuff[classtable.RendDebuff].refreshable) and cooldown[classtable.Rend].ready then
        return classtable.Rend
    end
	--Cast Shield Slam on cooldown
	if cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
	--Cast Thunder Clap on cooldown
	if talents[classtable.ThunderClap] and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
	--Cast Execute, if you do not need Rage for survivability
	if (rage >=20 and targethealthPerc < 20) or (talents[classtable.SuddenDeath] and buff[classtable.SuddenDeathBuff].up) and cooldown[classtable.Execute].ready then
		return classtable.Execute
	end
	--Cast Revenge, if you do not need Rage for survivability
	if talents[classtable.Revenge] and rage >= 20 and cooldown[classtable.Revenge].ready then
		return classtable.Revenge
	end
end

function Warrior:ProtectionMultiTarget()
	--Cast Ravager.
	if talents[classtable.Ravager] and cooldown[classtable.Ravager].ready then
        return classtable.Ravager
    end
	--Cast Thunderous Roar
	if talents[classtable.ThunderousRoar] and cooldown[classtable.ThunderousRoar].ready then
        return classtable.ThunderousRoar
    end
	--Cast Shield Charge.
	if talents[classtable.ShieldCharge] and cooldown[classtable.ShieldCharge].ready then
        return classtable.ShieldCharge
    end
	--Cast Spear of Bastion.
	if talents[classtable.SpearofBastion] and cooldown[classtable.SpearofBastion].ready then
        return classtable.SpearofBastion
    end
    if (not talents[classtable.BloodandThunder]) and talents[classtable.Rend] and rage >= 30 and (not debuff[classtable.RendDebuff] or debuff[classtable.RendDebuff].refreshable) and cooldown[classtable.Rend].ready then
        return classtable.Rend
    end
	--Cast Shield Slam on cooldown.
	if cooldown[classtable.ShieldSlam].ready then
        return classtable.ShieldSlam
    end
	--Cast Thunder Clap on cooldown.
	if talents[classtable.ThunderClap] and cooldown[classtable.ThunderClap].ready then
        return classtable.ThunderClap
    end
	--Cast Revenge.
	if talents[classtable.Revenge] and rage >= 20 and cooldown[classtable.Revenge].ready then
        return classtable.Revenge
    end
end