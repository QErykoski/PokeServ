local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players") -- Pobieramy usługę graczy

local PetConfig = require(ReplicatedStorage.Shared.PetConfig)
local SpawnerConfig = require(ReplicatedStorage.Shared.SpawnerConfig)
local AssetsFolder = ReplicatedStorage.Assets.Pets

local SpawnersFolder = workspace:WaitForChild("Spawners") 
local WildPetsFolder = workspace:FindFirstChild("Wild_Pets") or Instance.new("Folder", workspace)
WildPetsFolder.Name = "Wild_Pets"

-- Funkcja pomocnicza sprawdzająca, czy jakikolwiek gracz jest w pobliżu strefy
local function isAnyPlayerNearby(zonePosition, range)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character.PrimaryPart then
			local distance = (player.Character.PrimaryPart.Position - zonePosition).Magnitude
			if distance <= range then
				return true
			end
		end
	end
	return false
end

local function getRandomSpawn(spawnList)
	local totalWeight = 0
	for _, entry in ipairs(spawnList) do totalWeight += entry.Weight end
	local rnd = math.random() * totalWeight
	local current = 0
	for _, entry in ipairs(spawnList) do
		current += entry.Weight
		if rnd <= current then return entry end
	end
	return spawnList[1]
end

local function initZone(zonePart)
	local zoneName = zonePart.Name
	local settings = SpawnerConfig.Zones[zoneName]

	if not settings then
		warn("Brak konfiguracji dla strefy: " .. zoneName)
		return
	end

	print("Inicjalizacja strefy (zoptymalizowana): " .. zoneName)

	task.spawn(function()
		while true do
			task.wait(settings.SpawnInterval)

			-- OPTYMALIZACJA: Sprawdź, czy ktoś jest blisko przed wykonaniem reszty logiki
			local activationRange = settings.ActivationRange or 150 -- Domyślnie 150 studów
			if not isAnyPlayerNearby(zonePart.Position, activationRange) then
				continue -- Pomiń spawn, jeśli nikogo nie ma w pobliżu
			end

			-- 1. Policz ile zwierzaków z tej strefy już istnieje
			local currentPets = 0
			for _, pet in ipairs(WildPetsFolder:GetChildren()) do
				if pet:GetAttribute("HomeZone") == zoneName then
					currentPets += 1
				end
			end

			if currentPets < settings.MaxPets then
    local config = getRandomSpawn(settings.SpawnList)
    local species = PetConfig.Pets[config.Id]
    
   if species and AssetsFolder:FindFirstChild(config.Id) then
    local uuid = HttpService:GenerateGUID(false)
    local pet = AssetsFolder[config.Id]:Clone()
        
        -- Zmiana nazwy modelu na unikalne UUID
    pet.Name = species.Name
        
        local quality = config.AllowedQualities[math.random(1, #config.AllowedQualities)]
        local potential = math.random(config.PotentialRange[1]*100, config.PotentialRange[2]*100)/100

        -- Logika BillboardGui (aktualizacja nazwy i jakości w UI)
        local billboardTemplate = AssetsFolder:FindFirstChild("BillboardGui")
        if billboardTemplate then
            local newGui = billboardTemplate:Clone()
            local frame = newGui:FindFirstChild("Frame")
            if frame then
                local nameLabel = frame:FindFirstChild("NameLabel")
                if nameLabel then nameLabel.Text = species.Name end
                local qualityIconLabel = frame:FindFirstChild("ImageLabel")
                if qualityIconLabel then
                    local qualityIconId = PetConfig.QualityIcons[quality]
                    if qualityIconId then qualityIconLabel.Image = qualityIconId end
                end
            end
            newGui.Adornee = pet.PrimaryPart or pet:FindFirstChildWhichIsA("BasePart")
            newGui.Parent = pet
        end

        -- Ustawianie atrybutów zgodnie z wymaganiami
        pet:SetAttribute("SpeciesID", config.Id) -- ID gatunku z PetConfig
        pet:SetAttribute("Quality", quality)     -- Jakość wylosowana ze strefy
        pet:SetAttribute("Potential", potential) -- Potencjał wylosowany z zakresu strefy
        
        -- Pozostałe atrybuty systemowe
        pet:SetAttribute("UUID", uuid) 
        pet:SetAttribute("IsWild", true)
        pet:SetAttribute("HomeZone", zoneName) 
        pet:SetAttribute("HomeX", zonePart.Position.X)
        pet:SetAttribute("HomeY", zonePart.Position.Y)
        pet:SetAttribute("HomeZ", zonePart.Position.Z)
        pet:SetAttribute("WanderRadius", settings.SpawnRadius)

					local angle = math.rad(math.random(0, 360))
					local dist = math.random(0, settings.SpawnRadius)
					local spawnPos = zonePart.Position + Vector3.new(math.cos(angle)*dist, 2, math.sin(angle)*dist)
					
					pet:PivotTo(CFrame.new(spawnPos))
					
					for _, p in pairs(pet:GetDescendants()) do
						if p:IsA("BasePart") then
							p.CanCollide = false
							p.Anchored = true
							p.Massless = true
						end
					end
					
					pet.Parent = WildPetsFolder
					
				end
			end
		end
	end)
end

for _, part in ipairs(SpawnersFolder:GetChildren()) do
	initZone(part)
end