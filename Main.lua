local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type MaxDps
if not MaxDps then return end

local MaxDps = MaxDps;

local Warrior = MaxDps:NewModule('Warrior');
addonTable.Warrior = Warrior;

Warrior.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function Warrior:Enable()
	if not MaxDps:IsClassicWow() then
	    if MaxDps.Spec == 1 then
	    	MaxDps:Print(MaxDps.Colors.Info .. 'Warrior Arms', "info");
	    	MaxDps.NextSpell = Warrior.Arms;
	    elseif MaxDps.Spec == 2 then
	    	MaxDps:Print(MaxDps.Colors.Info .. 'Warrior Fury', "info");
	    	MaxDps.NextSpell = Warrior.Fury;
	    elseif MaxDps.Spec == 3 then
	    	MaxDps:Print(MaxDps.Colors.Info .. 'Warrior Protection', "info");
	    	MaxDps.NextSpell = Warrior.Protection;
	    end
	end
	if MaxDps:IsClassicWow() then
	    if MaxDps.Spec == 1 then
	    	MaxDps:Print(MaxDps.Colors.Info .. 'Warrior Arms', "info");
	    	MaxDps.NextSpell = Warrior.Arms;
	    elseif MaxDps.Spec == 2 then
	    	MaxDps:Print(MaxDps.Colors.Info .. 'Warrior Fury', "info");
	    	MaxDps.NextSpell = Warrior.Fury;
	    end
		MaxDps:Print(MaxDps.Colors.Info .. 'Warrior DPS', "info");
		MaxDps.NextSpell = Warrior.DPS;
	end
	if MaxDps:IsCataWow() then
	    if MaxDps.Spec == 1 then
	    	MaxDps:Print(MaxDps.Colors.Info .. 'Warrior Arms', "info");
	    	MaxDps.NextSpell = Warrior.Arms;
	    elseif MaxDps.Spec == 2 then
	    	MaxDps:Print(MaxDps.Colors.Info .. 'Warrior Fury', "info");
	    	MaxDps.NextSpell = Warrior.Fury;
	    end
	end

	return true;
end