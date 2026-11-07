local _, addonTable = ...
local Warrior = addonTable.Warrior
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Protection = {}

function Warrior:Protection()
    if MaxDps:SmartAoe() <= 1 then
        if (not MaxDps.IsTrackedAuraActive(6673)) and not MaxDps.IsSpellOnCooldown(6673, true) then return 6673 end --  Battle Shout
        if (GetShapeshiftFormID() ~= 18) and not MaxDps.IsSpellOnCooldown(71, true) then return 71 end --  Defensive Stance
        if not MaxDps.IsSpellOnCooldown(23922, true) then return 23922 end --  Shield Slam
        if not MaxDps.IsSpellOnCooldown(6572, true) then return 6572 end --  Revenge
        if not MaxDps.IsSpellOnCooldown(6343, true) then return 6343 end --  Thunder Clap
        if ((MaxDps.Stacks("target", 7386, "HARMFUL") < 5)) and not MaxDps.IsSpellOnCooldown(7386, true) then return 7386 end --  Sunder Armor
        if ((MaxDps.Power("rage", false) >= 45)) and not MaxDps.IsSpellOnCooldown(78, true) then return 78 end --  Heroic Strike
        if not MaxDps.IsSpellOnCooldown(7386, true) then return 7386 end --  Sunder Armor
    end

    if MaxDps:SmartAoe() >= 2 then
        if (not MaxDps.IsTrackedAuraActive(6673)) and not MaxDps.IsSpellOnCooldown(6673, true) then return 6673 end --  Battle Shout
        if (not MaxDps.IsTrackedAuraActive(1160)) and not MaxDps.IsSpellOnCooldown(1160, true) then return 1160 end --  Demoralizing Shout
        if (GetShapeshiftFormID() ~= 18) and not MaxDps.IsSpellOnCooldown(71, true) then return 71 end --  Defensive Stance
        if not MaxDps.IsSpellOnCooldown(23922, true) then return 23922 end --  Shield Slam
        if not MaxDps.IsSpellOnCooldown(6572, true) then return 6572 end --  Revenge
        if not MaxDps.IsSpellOnCooldown(6343, true) then return 6343 end --  Thunder Clap
        if ((MaxDps.Stacks("target", 7386, "HARMFUL") < 5)) and not MaxDps.IsSpellOnCooldown(7386, true) then return 7386 end --  Sunder Armor
        if ((MaxDps.Power("rage", false) >= 45)) and not MaxDps.IsSpellOnCooldown(78, true) then return 78 end --  Heroic Strike
        if not MaxDps.IsSpellOnCooldown(7386, true) then return 7386 end --  Sunder Armor
    end
end
