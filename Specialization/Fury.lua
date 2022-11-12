local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then
    return
end

local Warrior = addonTable.Warrior;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local PowerTypeRage = Enum.PowerType.Rage;
local fd = MaxDps.FrameData;
local cooldown;
local buff;
local talents;
local targets;
local rage;
local level;
local gcd;
local targetHp;
local timeToDie;
local canExecute;
local enraged;

local FR = {
    AncientAftershock = 325886,
    AngerManagement = 152278,
    Annihilator = 383916,
    Avatar = 107574,
    BloodBath = 335096,
    Bloodthirst = 23881,
    Charge = 100,
    Condemn = 317485,
    CondemnMassacre = 330325,
    ConquerorsBanner = 324143,
    Cruelty = 335070,
    CrushingBlow = 335097,
    DragonRoar = 118000,
    Enrage1 = 184361,
    Enrage2 = 184362,
    Execute = 5308,
    ExecuteMassacre = 280735,
    Frenzy = 335077,
    HeroicLeap = 6544,
    ImprovedWhirlwind = 12950,
    ImprovedWhirlwindBuff = 85739,
    Massacre = 206315,
    MeatCleaver = 280392,
    MeatCleaverAura = 85739,
    OdynsFury = 385059,
    Onslaught = 315720,
    RagingBlow = 85288,
	RagingBlowEmpowered = 335097,
    Rampage = 184367,
    Ravager = 228920,
    RecklessAbandon = 202751,
    Recklessness = 1719,
    Siegebreaker = 280772,
    Slam = 1464,
    SpearOfBastion = 376079,
    SuddenDeathAura = 280776,
    ThunderousRoar = 384318,
	TitanicRage = 394329,
    ViciousContempt = 337302,
    Whirlwind = 190411,
};

setmetatable(FR, Warrior.spellMeta);

function Warrior:Fury()
    fd = MaxDps.FrameData;
    cooldown = fd.cooldown;
    buff = fd.buff;
    talents = fd.talents;
    covenantId = fd.covenant.covenantId;
    targets = MaxDps:SmartAoe();
    rage = UnitPower('player', PowerTypeRage);
    level = UnitLevel("player");
    gcd = fd.gcd;
    targetHp = MaxDps:TargetPercentHealth() * 100;
    timeToDie = fd.timeToDie;

    enraged = buff[FR.Enrage1].up or buff[FR.Enrage2].up;
    fd.rage = rage;
    fd.targets = targets;

    canExecute = ((talents[FR.Massacre] and targetHp < 35) or
            targetHp < 20) or
            buff[FR.SuddenDeathAura].up
    ;

    MaxDps:GlowCooldown(FR.Recklessness, cooldown[FR.Recklessness].ready);
    MaxDps:GlowCooldown(FR.Avatar, cooldown[FR.Avatar].ready);
    MaxDps:GlowCooldown(FR.SpearOfBastion, cooldown[FR.SpearOfBastion].ready);

    -- run_action_list,name=single_target;
    return Warrior:FurySingleTarget();
end

function Warrior:FurySingleTarget()

    if targets > 1 and talents[FR.ImprovedWhirlwind] and not buff[FR.ImprovedWhirlwindBuff].up then
        return FR.Whirlwind;
    end

    --if talents[FR.Recklessness] and cooldown[FR.Recklessness].ready then
    --    return FR.Recklessness;
    --end
    --
    --if talents[FR.Avatar] and cooldown[FR.Avatar].ready then
    --    return FR.Avatar;
    --end

    if talents[FR.Rampage] and rage > 79 then
        return FR.Rampage
    end

    if canExecute then
        if talents[FR.Massacre] and cooldown[FR.ExecuteMassacre].ready then
            return FR.ExecuteMassacre;
        end
        if not talents[FR.Massacre] and cooldown[FR.Execute].ready then
            return FR.Execute;
        end
    end

    if enraged then
        --if talents[FR.SpearOfBastion] and cooldown[FR.SpearOfBastion].ready then
        --    return FR.SpearOfBastion;
        --end
        if talents[FR.Ravager] and cooldown[FR.Ravager].ready then
            return FR.Ravager;
        end
        if talents[FR.ThunderousRoar] and cooldown[FR.ThunderousRoar].ready then
            return FR.ThunderousRoar;
        end
        if talents[FR.OdynsFury] and cooldown[FR.OdynsFury].ready then
            return FR.OdynsFury;
        end
        if talents[FR.Onslaught] and cooldown[FR.Onslaught].ready then
            return FR.Onslaught;
        end
    end

    if not talents[FR.Annihilator] and cooldown[FR.RagingBlow].charges >= 1 then
        return FR.RagingBlow;
    end
	
	if not talents[FR.TitanicRage] and cooldown[FR.RagingBlowEmpowered].charges >= 1 then
        return FR.RagingBlowEmpowered;
    end

    if cooldown[FR.Bloodthirst].ready then
        return FR.Bloodthirst;
    end

    if targets > 1 then
        return FR.Whirlwind
    end

    return FR.Slam;

end

