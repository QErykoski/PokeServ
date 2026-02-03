local Constants = require(script.Parent.Constants)
local PetDefinitions = require(script.Parent.PetDefinitions)
local HttpService = game:GetService("HttpService")

local PetInstance = {}
PetInstance.__index = PetInstance

-- Konstruktor nowego zwierzaka (gdy tworzymy go pierwszy raz)
function PetInstance.new(petId: string, quality: string?, potential: number?): any
	local definition = PetDefinitions[petId]
	if not definition then error("Nieznany Pet ID: " .. tostring(petId)) end

	local self = setmetatable({}, PetInstance)
	
	self.UUID = HttpService:GenerateGUID(false)
	self.Id = petId
	self.Quality = quality or "Normal"
	self.Potential = potential or math.random(Constants.MIN_POTENTIAL * 100, Constants.MAX_POTENTIAL * 100) / 100
	
	self:UpdateStats()
	
	return self
end

-- NOWOŚĆ: Odtwarzanie zwierzaka z zapisanych danych
function PetInstance.fromData(data: table): any
	local self = setmetatable({}, PetInstance)
	self.UUID = data.UUID
	self.Id = data.Id
	self.Quality = data.Quality
	self.Potential = data.Potential
	
	self:UpdateStats() -- Przeliczamy HP i Atak na nowo po wczytaniu
	return self
end

-- NOWOŚĆ: Przygotowanie danych do zapisu
function PetInstance:Serialize()
	return {
		UUID = self.UUID,
		Id = self.Id,
		Quality = self.Quality,
		Potential = self.Potential
	}
end

function PetInstance:UpdateStats()
	local definition = PetDefinitions[self.Id]
	local qualityData = Constants.Qualities[self.Quality]
	
	if not definition or not qualityData then return end
	
	local totalMultiplier = qualityData.Multiplier * self.Potential
	self.CurrentAttack = math.floor(definition.BaseAttack * totalMultiplier)
	self.CurrentHealth = math.floor(definition.BaseHealth * totalMultiplier)
end

function PetInstance:SetPotential(newPotential: number)
	self.Potential = math.clamp(newPotential, Constants.MIN_POTENTIAL, Constants.MAX_POTENTIAL)
	self:UpdateStats()
end

function PetInstance:GetInfo()
	local definition = PetDefinitions[self.Id]
	return string.format(
		"[%s] %s (Jakość: %s, Potencjał: %.2fx) | HP: %d | ATK: %d",
		self.Quality, definition.Name, self.Quality, self.Potential, self.CurrentHealth, self.CurrentAttack
	)
end

return PetInstance