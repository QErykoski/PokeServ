local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. IMPORT KONFIGURACJI I ASSETÓW
local PetConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetConfig"))
local AssetsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Pets")

local PetDataStore = DataStoreService:GetDataStore("PokePets_Data_v2") 
local Sessions = {} -- Cache danych graczy

--------------------------------------------------------------------------------
-- 2. KONFIGURACJA REMOTES I WORKSPACE
--------------------------------------------------------------------------------
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local function createRemote(className, name)
	local remote = Remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = Remotes
	end
	return remote
end

local GetInventoryFunc = createRemote("RemoteFunction", "GetInventory")
local EquipPetEvent = createRemote("RemoteEvent", "EquipPet")
local UnequipAllEvent = createRemote("RemoteEvent", "UnequipAll")
local DeletePetsEvent = createRemote("RemoteEvent", "DeletePets")

local WorkspacePets = workspace:FindFirstChild("Player_Pets")
if not WorkspacePets then
	WorkspacePets = Instance.new("Folder")
	WorkspacePets.Name = "Player_Pets"
	WorkspacePets.Parent = workspace
end

--------------------------------------------------------------------------------
-- 3. HELPERY
--------------------------------------------------------------------------------

local function getRandomQuality()
	local totalWeight = 0
	for _, weight in pairs(PetConfig.QualityChances) do
		totalWeight += weight
	end
	
	local randomValue = math.random() * totalWeight
	local currentWeight = 0
	
	for quality, weight in pairs(PetConfig.QualityChances) do
		currentWeight += weight
		if randomValue <= currentWeight then
			return quality
		end
	end
	return "Normal"
end

local function createPetInstance(speciesId)
	if not PetConfig.Pets[speciesId] then return nil end
	
	local potential = math.random(10, 100) / 100
	local quality = getRandomQuality()
	
	return {
		UUID = HttpService:GenerateGUID(false),
		Id = speciesId,
		Quality = quality,
		Potential = potential,
		Equipped = false
	}
end

local function updatePlayerPetsVisuals(player)
	local playerFolder = WorkspacePets:FindFirstChild(player.Name)
	if not playerFolder then
		playerFolder = Instance.new("Folder")
		playerFolder.Name = player.Name
		playerFolder.Parent = WorkspacePets
	end
	
	playerFolder:ClearAllChildren()
	
	local session = Sessions[player.UserId]
	if not session then return end
	
	for _, petData in ipairs(session.Inventory) do
		if petData.Equipped then
    local modelTemplate = AssetsFolder:FindFirstChild(petData.Id)
    local speciesData = PetConfig.Pets[petData.Id] -- Pobieramy dane gatunku

    if modelTemplate and speciesData then
        local clone = modelTemplate:Clone()
        
        -- Nazwa modelu to czytelna nazwa z konfiguracji
        clone.Name = speciesData.Name 
        
        -- Zabezpieczenie danych w atrybutach
        clone:SetAttribute("UUID", petData.UUID)      -- Unikalny identyfikator
        clone:SetAttribute("SpeciesID", petData.Id)   -- ID gatunku (np. "FireLizard")
        clone:SetAttribute("Potential", petData.Potential)
        clone:SetAttribute("Quality", petData.Quality)
				
				-- Pozycjonowanie i fizyka
				if player.Character and player.Character.PrimaryPart then
					clone:PivotTo(player.Character.PrimaryPart.CFrame)
				end
				
				for _, part in pairs(clone:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						part.Anchored = true
						part.Massless = true
					end
				end
				
				clone.Parent = playerFolder
			end
		end
	end
end

local function addPetToPlayer(player, speciesId)
	local data = Sessions[player.UserId]
	if not data then return false end
	
	local maxSlots = player:GetAttribute("MaxStorage") or PetConfig.MaxSlots or 20
	
	if #data.Inventory >= maxSlots then
		return false
	end
	
	local success, newPet = pcall(function() return createPetInstance(speciesId) end)
	if success and newPet then
		table.insert(data.Inventory, newPet)
		return true, newPet
	end
	return false
end

--------------------------------------------------------------------------------
-- 4. OBSŁUGA REMOTES
--------------------------------------------------------------------------------

GetInventoryFunc.OnServerInvoke = function(player)
	if Sessions[player.UserId] then
		return Sessions[player.UserId].Inventory
	end
	return {}
end

EquipPetEvent.OnServerEvent:Connect(function(player, petUUID, equipState)
	local data = Sessions[player.UserId]
	if not data then return end
	
	local targetPet = nil
	for _, pet in ipairs(data.Inventory) do
		if pet.UUID == petUUID then
			targetPet = pet
			break
		end
	end
	
	if not targetPet then return end
	
	if equipState == true then
		local currentEquipped = 0
		for _, pet in ipairs(data.Inventory) do
			if pet.Equipped then currentEquipped += 1 end
		end
		
		local maxEquipped = player:GetAttribute("MaxEquipped") or PetConfig.MaxEquipped or 4
		
		if currentEquipped >= maxEquipped then
			return
		end
	end
	
	targetPet.Equipped = equipState
	updatePlayerPetsVisuals(player)
end)

UnequipAllEvent.OnServerEvent:Connect(function(player)
	local data = Sessions[player.UserId]
	if not data then return end
	
	for _, pet in ipairs(data.Inventory) do
		pet.Equipped = false
	end
	updatePlayerPetsVisuals(player)
end)

DeletePetsEvent.OnServerEvent:Connect(function(player, uuidsToDelete)
	local data = Sessions[player.UserId]
	if not data or type(uuidsToDelete) ~= "table" then return end
	
	local inventory = data.Inventory
	
	for _, uuid in ipairs(uuidsToDelete) do
		for i = #inventory, 1, -1 do
			if inventory[i].UUID == uuid then
				if not inventory[i].Equipped then
					table.remove(inventory, i)
				end
			end
		end
	end
end)

--------------------------------------------------------------------------------
-- 5. OBSŁUGA DATASTORE
--------------------------------------------------------------------------------

local function loadData(player)
	local success, result = pcall(function()
		return PetDataStore:GetAsync("Player_" .. player.UserId)
	end)
	
	if success and result then
		Sessions[player.UserId] = result
	else
		-- USUNIĘTO: Coins = 0
		Sessions[player.UserId] = {
			Inventory = {}
		}
		addPetToPlayer(player, "FireLizard")
		addPetToPlayer(player, "FireLizard")
		addPetToPlayer(player, "FireLizard")
	end
	
	player:SetAttribute("MaxEquipped", PetConfig.MaxEquipped or 4)
	player:SetAttribute("MaxStorage", PetConfig.MaxSlots or 20)
	
	player.CharacterAdded:Connect(function()
		task.wait(1)
		updatePlayerPetsVisuals(player)
	end)
end

local function saveData(player)
	local data = Sessions[player.UserId]
	if not data then return end
	
	pcall(function()
		PetDataStore:SetAsync("Player_" .. player.UserId, data)
	end)
	
	local folder = WorkspacePets:FindFirstChild(player.Name)
	if folder then folder:Destroy() end
	
	Sessions[player.UserId] = nil
end

Players.PlayerAdded:Connect(loadData)
Players.PlayerRemoving:Connect(saveData)

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		saveData(player)
	end
end)