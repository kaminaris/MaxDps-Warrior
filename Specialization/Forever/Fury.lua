local _, addonTable = ...
local Warrior = addonTable.Warrior
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Fury = {}

function Warrior:Fury()
    if MaxDps:SmartAoe() <= 1 then
        if (not MaxDps.IsTrackedAuraActive(6673)) and not MaxDps.IsSpellOnCooldown(6673, true) then return 6673 end --  Battle Shout
        if ((MaxDps.Stacks("target", 7386, "HARMFUL") < 1)) and not MaxDps.IsSpellOnCooldown(7386, true) then return 7386 end --  Sunder Armor
        if not MaxDps.IsSpellOnCooldown(12328, true) then return 12328 end --  Death Wish
        MaxDps:GlowCooldownMidnight(5308, true)
        if not MaxDps.IsSpellOnCooldown(12294, true) then return 12294 end --  Mortal Strike
        if not MaxDps.IsSpellOnCooldown(1310222, true) then return 1310222 end --  Spearing Strike
        if not MaxDps.IsSpellOnCooldown(23881, true) then return 23881 end --  Bloodthirst
        if not MaxDps.IsSpellOnCooldown(23881, true) then return 1680 end --  Whirlwind
        if not MaxDps.IsSpellOnCooldown(1240193, true) then return 1240193 end --  Slam
        if ((MaxDps.Power("rage", false) >= 40)) and not MaxDps.IsSpellOnCooldown(78, true) then return 78 end --  Heroic Strike
        if not MaxDps.IsSpellOnCooldown(23881, true) and not MaxDps.IsSpellOnCooldown(1680, true) and (MaxDps.Power("rage", false) > 80) then return 1715 end --  Hamstring
        if (MaxDps.Power("rage", false) < 90) then MaxDps:GlowDefensiveHPMidnight(2687, true) end --  Bloodrage
        if (not MaxDps.IsTrackedAuraActive(2458)) and not MaxDps.IsSpellOnCooldown(2458, true) then return 2458 end --  Berserker Stance
    end

    if MaxDps:SmartAoe() >= 2 then
        if (not MaxDps.IsTrackedAuraActive(6673)) and not MaxDps.IsSpellOnCooldown(6673, true) then return 6673 end --  Battle Shout
        if not MaxDps.IsSpellOnCooldown(6343, true) then return 6343 end --  Thunder Clap
        if (not MaxDps.IsTrackedAuraActive(1160)) and not MaxDps.IsSpellOnCooldown(1160, true) then return 1160 end --  Demoralizing Shout
        if ((MaxDps.Stacks("target", 7386, "HARMFUL") < 1)) and not MaxDps.IsSpellOnCooldown(7386, true) then return 7386 end --  Sunder Armor
        if not MaxDps.IsSpellOnCooldown(12328, true) then return 12328 end --  Death Wish
        if not MaxDps.IsSpellOnCooldown(1680, true) then return 1680 end --  Whirlwind
        MaxDps:GlowCooldownMidnight(5308, true)
        if not MaxDps.IsSpellOnCooldown(12294, true) then return 12294 end --  Mortal Strike
        if not MaxDps.IsSpellOnCooldown(1310222, true) then return 1310222 end --  Spearing Strike
        if not MaxDps.IsSpellOnCooldown(23881, true) then return 23881 end --  Bloodthirst
        if not MaxDps.IsSpellOnCooldown(23881, true) then return 1680 end --  Whirlwind
        if not MaxDps.IsSpellOnCooldown(1240193, true) then return 1240193 end --  Slam
        if ((MaxDps.Power("rage", false) >= 40)) and not MaxDps.IsSpellOnCooldown(845, true) then return 845 end --  Cleave
        if not MaxDps.IsSpellOnCooldown(23881, true) and not MaxDps.IsSpellOnCooldown(1680, true) and (MaxDps.Power("rage", false) > 80) then return 1715 end --  Hamstring
        if (MaxDps.Power("rage", false) < 90) then MaxDps:GlowDefensiveHPMidnight(2687, true) end --  Bloodrage
        if (not MaxDps.IsTrackedAuraActive(2458)) and not MaxDps.IsSpellOnCooldown(2458, true) then return 2458 end --  Berserker Stance
    end
end
