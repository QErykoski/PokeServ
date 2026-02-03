local Constants = {}

-- Typy żywiołów
Constants.PetTypes = {
	Fire = "Fire",
	Water = "Water",
	Grass = "Grass",
	Electric = "Electric"
}

-- Jakości i ich mnożniki statystyk
Constants.Qualities = {
	Normal = { Multiplier = 1.0 },
	Giant = { Multiplier = 1.5 },
	Mega = { Multiplier = 2.0 },
	Titan = { Multiplier = 3.0 },
}

-- Domyślne ustawienia
Constants.MAX_SLOTS_DEFAULT = 20
Constants.MAX_POTENTIAL = 2.0 -- Np. max 200% statystyk z potencjału
Constants.MIN_POTENTIAL = 1.0

return Constants