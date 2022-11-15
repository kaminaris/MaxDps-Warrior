local _, addonTable = ...
--- @type MaxDps
if not MaxDps then
    return
end

local Warrior = addonTable.Warrior
local MaxDps = MaxDps
local UnitPower = UnitPower
local PowerTypeRage = Enum.PowerType.Rage
local fd
local cooldown
local talents
local buff
local targets
local targetHp
local rage
local debuff
local inExecutePhase
local avatarInRotation = true
local bladeStormInRotation = true
local spearOfBastionInRotation = true
local executeAbility

local AR = {
    AshenJuggernaut = 392536,
    Avatar = 107574,
    BattleStance = 386164,
    Battlelord = 386630,
    Bladestorm = 227847,
    BloodAndThunder = 384277,
    Charge = 100,
    Cleave = 845,
    ColossusSmash = 167105,
    DeepWounds = 262304,
    DeepWoundsAura = 262115,
    Execute = 163201,
    --ExecutionersPrecision = 386634,
    FervorOfBattle = 202316,
    Hurricane = 390563,
    ImpendingVictory = 202168,
    InForTheKill = 248621,
    Juggernaut = 383292,
    MartialProwess = 316440,
	MassacreAbility = 281000,
    MassacreTalent = 281001,
    MercilessBonegrinderTalent = 383317,
    MercilessBonegrinderBuff = 383316,
    MortalStrike = 12294,
    Overpower = 7384,
    Pummel = 6552,
    Ravager = 152277,
    Rend = 772,
    RendDebuff = 388539,
    Shockwave = 46968,
    Skullsplitter = 260643,
    Slam = 1464,
    SpearOfBastion = 376079,
    SuddenDeath = 29725,
    SuddenDeathAura = 52437,
    SweepingStrikes = 260708,
    TestOfMight = 385008,
    ThunderClap = 6343,
    ThunderousRoar = 384318,
    TideOfBlood = 386357,
    Unhinged = 386628,
    Warbreaker = 262161,
    Whirlwind = 1680,
    WreckingThrow = 384110,
}

setmetatable(AR, Warrior.spellMeta)

function Warrior:Arms()
    fd = MaxDps.FrameData
    cooldown = fd.cooldown
    debuff = fd.debuff
    talents = fd.talents
    buff = fd.buff
    targets = MaxDps:SmartAoe()
    targetHp = MaxDps:TargetPercentHealth() * 100
    rage = UnitPower('player', PowerTypeRage)

    inExecutePhase = (talents[AR.MassacreTalent] and targetHp < 35) or
            targetHp < 20
	if talents[AR.MassacreTalent] then
		executeAbility = AR.MassacreAbility
	else
		executeAbility = AR.Execute
	end

    -- TODO need to check warbreaker with all instances of colossus smash.

    MaxDps:GlowCooldown(AR.Avatar, not avatarInRotation and cooldown[AR.Avatar].ready)
    MaxDps:GlowCooldown(AR.Bladestorm, not bladeStormInRotation and cooldown[AR.Bladestorm].ready)
    MaxDps:GlowCooldown(AR.SpearOfBastion, not spearOfBastionInRotation and cooldown[AR.SpearOfBastion].ready)

    if targets > 3 then
        return Warrior:ArmsMultiTarget()
    end

    if inExecutePhase then
        return Warrior:ArmsSingleTargetExecute()
    end

    return Warrior:ArmsSingleTarget()

end
function Warrior:ArmsAvatar()
    local avatarReady = false
    if talents[AR.Avatar] then
        if talents[AR.ColossusSmash] then
            avatarReady = cooldown[AR.Avatar].ready and (cooldown[AR.ColossusSmash].remains < 4 or cooldown[AR.Warbreaker].remains < 4 )
        else
            avatarReady = cooldown[AR.Avatar].ready
        end
    end

    if avatarReady and avatarInRotation then
        return AR.Avatar
    end
end
function Warrior:ArmsSingleTarget()
    if targets > 1 and cooldown[AR.SweepingStrikes].ready then
        return AR.SweepingStrikes
    end

    if talents[AR.Rend] and
            rage >= 30 and
            debuff[AR.RendDebuff].refreshable
    then
        return AR.Rend
    end

    local avatarNow = Warrior:ArmsAvatar()
    if avatarNow then
        return avatarNow
    end

    if talents[AR.Warbreaker] then
        if cooldown[AR.Warbreaker].ready then
            return AR.Warbreaker
        end
    else
        if cooldown[AR.ColossusSmash].ready then
            return AR.ColossusSmash
        end
    end

    if spearOfBastionInRotation and talents[AR.SpearOfBastion] and cooldown[AR.SpearOfBastion].ready then
        return AR.SpearOfBastion
    end

    if talents[AR.ThunderousRoar] and buff[AR.InForTheKill].up or buff[AR.TestOfMight].up then
        return AR.ThunderousRoar
    end

    if talents[AR.TideOfBlood] and (cooldown[AR.ColossusSmash].remains > 40 or cooldown[AR.Warbreaker].remains > 40) then
        return AR.Skullsplitter
    end

    if cooldown[AR.MortalStrike].ready and rage >= 30 and debuff[AR.DeepWoundsAura].remains <= 2 then
        return AR.MortalStrike
    end

    if buff[AR.SuddenDeathAura].up then
        return executeAbility
    end

    if talents[AR.Bladestorm] and cooldown[AR.Bladestorm].ready and rage < 30 and bladeStormInRotation then
        return AR.Bladestorm
    end

    if cooldown[AR.MortalStrike].ready and rage >= 30 then
        return AR.MortalStrike
    end

    if cooldown[AR.Overpower].ready then
        return AR.Overpower
    end

    if talents[AR.FervorOfBattle] and rage >= 30 then
        return AR.Whirlwind
    elseif rage >= 30 then
        return AR.Slam
    end

end
function Warrior:ArmsSingleTargetExecute()
    if targets > 1 and cooldown[AR.SweepingStrikes].ready then
        return AR.SweepingStrikes
    end
    if talents[AR.Rend] and
            rage >= 30 and
            debuff[AR.RendDebuff].refreshable
    then
        return AR.Rend
    end

    if cooldown[AR.MortalStrike].ready and rage >= 30 and debuff[AR.DeepWoundsAura].remains <= 2 then
        return AR.MortalStrike
    end

    local avatarNow = Warrior:ArmsAvatar()
    if avatarNow then
        return avatarNow
    end

    if talents[AR.Warbreaker] then
        if cooldown[AR.Warbreaker].ready then
            return AR.Warbreaker
        end
    else
        if cooldown[AR.ColossusSmash].ready then
            return AR.ColossusSmash
        end
    end

    if spearOfBastionInRotation and talents[AR.SpearOfBastion] and cooldown[AR.SpearOfBastion].ready then
        return AR.SpearOfBastion
    end

    if buff[AR.SuddenDeathAura].up or rage >= 20 then
        return executeAbility
    end

    if talents[AR.ThunderousRoar] and buff[AR.InForTheKill].up or buff[AR.TestOfMight].up then
        return AR.ThunderousRoar
    end

    if talents[AR.TideOfBlood] and (cooldown[AR.ColossusSmash].remains > 40 or cooldown[AR.Warbreaker].remains > 40) then
        return AR.Skullsplitter
    end

    if cooldown[AR.Overpower].ready then
        return AR.Overpower
    end
end
function Warrior:ArmsMultiTarget()

    if talents[AR.MercilessBonegrinderTalent] and buff[AR.MercilessBonegrinderBuff].up and rage >= 70 then
        return AR.Whirlwind
    end

    if talents[AR.BloodAndThunder] and debuff[AR.RendDebuff].refreshable then
        return AR.ThunderClap
    end

    if talents[AR.Warbreaker] then
        if cooldown[AR.Warbreaker].ready then
            return AR.Warbreaker
        end
    else
        -- colossus_smash
        if cooldown[AR.ColossusSmash].ready then
            return AR.ColossusSmash
        end
    end

    local avatarNow = Warrior:ArmsAvatar()
    if avatarNow then
        return avatarNow
    end

    if talents[AR.Bladestorm] and cooldown[AR.Bladestorm].ready then
        return AR.Bladestorm
    end

    if talents[AR.ThunderousRoar] and buff[AR.InForTheKill].up or buff[AR.TestOfMight].up then
        return AR.ThunderousRoar
    end

    if talents[AR.Cleave] and rage >= 20 and cooldown[AR.Cleave].ready then
        return AR.Cleave
    end

    if rage >= 70 then
        return AR.Whirlwind
    end

    if cooldown[AR.Overpower].ready then
        return AR.Overpower
    end

    if buff[AR.SuddenDeathAura].up then
        return executeAbility
    end
end


