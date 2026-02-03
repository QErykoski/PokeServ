local Constants = require(script.Parent.Constants)

local PetDefinitions = {
	["Ignis"] = {
		Name = "Ignis",
		Type = Constants.PetTypes.Fire,
		BaseAttack = 100,
		BaseHealth = 500,
		PassiveAbility = "FlameTouch", -- Pasywka zadająca obrażenia przy dotyku
	},
	["Aqua"] = {
		Name = "Aqua",
		Type = Constants.PetTypes.Water,
		BaseAttack = 60,
		BaseHealth = 900,
		PassiveAbility = "Regeneration", -- Pasywka lecząca co sekundę
	}
}

return PetDefinitions