local _, addonTable = ...;
--- @type MaxDps
if not MaxDps then
    return
end

local Warrior = addonTable.Warrior;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local PowerTypeRage = Enum.PowerType.Rage;
local fd;
local cooldown;
local talents;
local buff;
local targets;
local targetHp;
local rage;
local debuff;
local inExecutePhase;

local AR = {
    AshenJuggernaut = 392536,
    Avatar = 107574,
    BattleStance = 386164,
    Battlelord = 386630,
    Bladestorm = 227847,
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
    Massacre = 281001,
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
};

setmetatable(AR, Warrior.spellMeta);

function Warrior:Arms()
    fd = MaxDps.FrameData;
    cooldown = fd.cooldown;
    debuff = fd.debuff;
    talents = fd.talents;
    buff = fd.buff;
    targets = MaxDps:SmartAoe();
    targetHp = MaxDps:TargetPercentHealth() * 100;
    rage = UnitPower('player', PowerTypeRage);

    inExecutePhase = (talents[AR.Massacre] and targetHp < 35) or
            targetHp < 20;

    -- TODO need to check warbreaker with all instances of colossus smash.

    if targets > 1 and targets < 4 then
        return Warrior:ArmsMultiLessThanFour();
    end

    if targets > 1 and targets < 4 then
        return Warrior:ArmsMultiMoreThanThree();
    end

    if inExecutePhase then
        return Warrior:ArmsSingleTargetExecute();
    end

    return Warrior:ArmsSingleTarget();

end

function Warrior:ArmsSingleTarget()
    if talents[AR.Rend] and
            rage >= 30 and
            debuff[AR.RendDebuff].refreshable
    then
        return AR.Rend;
    end

    if talents[AR.Avatar] then
        if talents[AR.ColossusSmash] then
            MaxDps:GlowCooldown(AR.Avatar, cooldown[AR.Avatar].ready and cooldown[AR.ColossusSmash].remains < 4);
        else
            MaxDps:GlowCooldown(
                    AR.Avatar, cooldown[AR.Avatar].ready);
        end
    end

    if talents[AR.Warbreaker] then
        if cooldown[AR.Warbreaker].ready then
            return AR.Warbreaker;
        end
    else
        if cooldown[AR.ColossusSmash].ready then
            return AR.ColossusSmash;
        end
    end

    if talents[AR.ThunderousRoar] and buff[AR.InForTheKill].up or buff[AR.TestOfMight].up then
        return AR.ThunderousRoar;
    end

    if talents[AR.TideOfBlood] and (cooldown[AR.ColossusSmash].remains > 40 or cooldown[AR.Warbreaker].remains > 40) then
        return AR.Skullsplitter;
    end

    if buff[AR.SuddenDeathAura].up then
        return AR.Execute;
    end

    if talents[AR.Bladestorm] and cooldown[AR.Bladestorm].ready then
        return AR.Bladestorm;
    end

    if cooldown[AR.MortalStrike].ready and rage > 29 and cooldown[AR.Overpower].ready then
        return AR.Overpower;
    end

    if cooldown[AR.MortalStrike].ready and rage > 29 then
        return AR.MortalStrike;
    end


    if talents[AR.FervorOfBattle] and rage > 29 then
        return AR.Whirlwind;
    elseif rage > 19 then
        return AR.Slam;
    end

end

function Warrior:ArmsSingleTargetExecute()

    if talents[AR.Avatar] then
        if talents[AR.ColossusSmash] then
            MaxDps:GlowCooldown(AR.Avatar, cooldown[AR.Avatar].ready and cooldown[AR.ColossusSmash].remains < 4);
        else
            MaxDps:GlowCooldown(
                    AR.Avatar, cooldown[AR.Avatar].ready);
        end
    end

    if talents[AR.Warbreaker] then
        if cooldown[AR.Warbreaker].ready then
            return AR.Warbreaker;
        end
    else
        -- colossus_smash;
        if cooldown[AR.ColossusSmash].ready then
            return AR.ColossusSmash;
        end
    end

    if talents[AR.ThunderousRoar] and buff[AR.InForTheKill].up or buff[AR.TestOfMight].up then
        return AR.ThunderousRoar;
    end

    if talents[AR.Bladestorm] and cooldown[AR.Bladestorm].ready then
        return AR.Bladestorm;
    end

    if cooldown[AR.MortalStrike].ready and rage > 29 and cooldown[AR.Overpower].ready then
        return AR.Overpower;
    end

    if cooldown[AR.MortalStrike].ready and rage > 29 and debuff[AR.DeepWoundsAura].refreshable then
        return AR.MortalStrike
    end

    if talents[AR.Rend] and
            rage >= 30 and
            debuff[AR.RendDebuff].refreshable
    then
        return AR.Rend;
    end

    if talents[AR.Bladestorm] and cooldown[AR.Bladestorm].ready then
        return AR.Bladestorm
    end

    if buff[AR.SuddenDeathAura].up or rage > 19 then
        return AR.Execute;
    end
end

function Warrior:ArmsMultiLessThanFour()

    if talents[AR.ThunderClap] and debuff[AR.RendDebuff].refreshable then
        return AR.ThunderClap;
    end

    if talents[AR.SweepingStrikes] and cooldown[AR.SweepingStrikes].ready and cooldown[AR.ColossusSmash].remains < 4 then
        return AR.SweepingStrikes;
    end

    if talents[AR.Avatar] then
        if talents[AR.ColossusSmash] then
            MaxDps:GlowCooldown(AR.Avatar, cooldown[AR.Avatar].ready and cooldown[AR.ColossusSmash].remains < 4);
        else
            MaxDps:GlowCooldown(
                    AR.Avatar, cooldown[AR.Avatar].ready);
        end
    end

    if talents[AR.Warbreaker] then
        if cooldown[AR.Warbreaker].ready then
            return AR.Warbreaker;
        end
    else
        -- colossus_smash;
        if cooldown[AR.ColossusSmash].ready then
            return AR.ColossusSmash;
        end
    end

    if talents[AR.ThunderousRoar] and buff[AR.InForTheKill].up or buff[AR.TestOfMight].up then
        return AR.ThunderousRoar;
    end

    if talents[AR.TideOfBlood] and (cooldown[AR.ColossusSmash].remains > 40 or cooldown[AR.Warbreaker].remains > 40) then
        return AR.Skullsplitter;
    end

    if buff[AR.SuddenDeathAura].up or inExecutePhase then
        return AR.Execute;
    end

    if talents[AR.Cleave] and rage > 19 then
        return AR.Cleave;
    end

    if talents[AR.Bladestorm] and cooldown[AR.Bladestorm].ready then
        return AR.Bladestorm;
    end

    if cooldown[AR.MortalStrike].ready and rage > 29 and cooldown[AR.Overpower].ready then
        return AR.Overpower;
    end

    if talents[AR.MortalStrike] and cooldown[AR.MortalStrike].ready and rage > 29 then
        return AR.MortalStrike
    end

    if talents[AR.FervorOfBattle] and rage > 29 then
        return AR.Whirlwind;
    elseif rage > 19 then
        return AR.Slam;
    end
end

function Warrior:ArmsMultiMoreThanThree()

    if talents[AR.ThunderClap] and debuff[AR.RendDebuff].refreshable then
        return AR.ThunderClap;
    end

    if talents[AR.Avatar] then
        if talents[AR.ColossusSmash] then
            MaxDps:GlowCooldown(AR.Avatar, cooldown[AR.Avatar].ready and cooldown[AR.ColossusSmash].remains < 4);
        else
            MaxDps:GlowCooldown(
                    AR.Avatar, cooldown[AR.Avatar].ready);
        end
    end

    if talents[AR.Warbreaker] then
        if cooldown[AR.Warbreaker].ready then
            return AR.Warbreaker;
        end
    else
        -- colossus_smash;
        if cooldown[AR.ColossusSmash].ready then
            return AR.ColossusSmash;
        end
    end

    if talents[AR.Bladestorm] and cooldown[AR.Bladestorm].ready then
        return AR.Bladestorm;
    end

    if talents[AR.ThunderousRoar] and buff[AR.InForTheKill].up or buff[AR.TestOfMight].up then
        return AR.ThunderousRoar;
    end

    -- sweeping_strikes
    if (buff[AR.SuddenDeathAura].up or inExecutePhase) and buff[AR.SweepingStrikes].up then
        return AR.Execute;
    end

    if talents[AR.Cleave] and rage > 19 then
        return AR.Cleave;
    end

    if rage > 29 then
        return AR.Whirlwind;
    end

    if cooldown[AR.Overpower].ready then
        return AR.Overpower;
    end

    if buff[AR.SuddenDeathAura].up then
        return AR.Execute;
    end
end
