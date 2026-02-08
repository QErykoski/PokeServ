local SpawnerConfig = {}

SpawnerConfig.Zones = {
	-- STREFA 1: LAS
	["Forest"] = {
		MaxPets = 3,
		SpawnInterval = 4,
		SpawnRadius = 30,
		ActivationRange = 50, -- Nowy parametr: dystans aktywacji strefy
		SpawnList = {
			{ Id = "FireLizard", Weight = 100, PotentialRange = {0.1, 0.5}, AllowedQualities = {"Normal"} },
		}
	},

	-- STREFA 2: WULKAN
	["Volcano"] = {
		MaxPets = 3,
		SpawnInterval = 10,
		SpawnRadius = 20,
		ActivationRange = 50, -- Indywidualny dystans dla strefy
		SpawnList = {
			{ Id = "FireLizard", Weight = 100, PotentialRange = {0.1, 0.5}, AllowedQualities = {"Normal"} },
		}
	}
}

return SpawnerConfig