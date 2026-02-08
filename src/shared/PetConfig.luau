local PetConfig = {}


-- Definicje jakości i ich mnożników
PetConfig.Qualities = {
	Normal = 1.0,
	Giant = 1.5,
	Mega = 3.0,
	Titan = 5.0,
}

-- Szanse na wylosowanie danej jakości
PetConfig.QualityChances = {
	Normal = 1000,
	Giant = 100,
	Mega = 10,
	Titan = 1,
}
-- NOWE: Ikony typów (wstaw tutaj swoje ID)
PetConfig.TypeIcons = {
	Fire = "rbxassetid://84872807814415", -- Przykładowe ID dla ognia
	Water = "rbxassetid://987654321", -- Przykładowe ID dla wody
}
PetConfig.QualityIcons = {
	Normal = "rbxassetid://76339327771494", -- Wstaw ID dla Normal
	Giant = "rbxassetid://96400218533770",  -- Wstaw ID dla Giant
	Mega = "rbxassetid://103320907462442",   -- Wstaw ID dla Mega
	Titan = "rbxassetid://92842711625322",  -- Wstaw ID dla Titan
}
-- NOWE: Dane umiejętności (pasywek)
PetConfig.Abilities = {
	["BurnOnTouch"] = {
		Name = "Ognisty Dotyk",
		Description = "Podpala przeciwników przy każdym kontakcie, zadając obrażenia w czasie."
	},
	["RegenInWater"] = {
		Name = "Wodna Regeneracja",
		Description = "Gdy zwierzak znajduje się w wodzie, jego punkty życia regenerują się znacznie szybciej."
	}
}
-- Baza gatunków
PetConfig.Pets = {
	["FireLizard"] = {
		Name = "Fire Lizard",
		Type = "Fire",
		BaseAttack = 2,
		BaseHealth = 8,
		Passive = "BurnOnTouch",
	},
	["WaterTurtle"] = {
		Name = "Water Turtle",
		Type = "Water",
		BaseAttack = 5,
		BaseHealth = 8,
		Passive = "RegenInWater",
	}
}

PetConfig.MaxSlots = 20
PetConfig.MaxEquipped = 4

-- Funkcja do obliczania ostatecznych statystyk
function PetConfig.calculateStats(petData)
	local basePet = PetConfig.Pets[petData.Id]
	if not basePet then return 0, 0 end
	
	local qualityMult = PetConfig.Qualities[petData.Quality] or 1
	local potentialMult = 1 + (petData.Potential or 0)
	
	local finalAttack = basePet.BaseAttack * potentialMult * qualityMult
	local finalHealth = basePet.BaseHealth * potentialMult * qualityMult
	
	return math.floor(finalAttack), math.floor(finalHealth)
end

return PetConfig