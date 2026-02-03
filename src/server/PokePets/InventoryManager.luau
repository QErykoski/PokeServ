local DataStoreService = game:GetService("DataStoreService")
local InventoryManager = {}
local PetInstance = require(game.ReplicatedStorage.Shared.PokePets.PetInstance)
local Constants = require(game.ReplicatedStorage.Shared.PokePets.Constants)

local DATA_KEY = "PokePets_Data_v2" -- Zmiana wersji klucza (nowa struktura danych)
local PetDataStore = DataStoreService:GetDataStore(DATA_KEY)

-- Pamięć podręczna serwera
local PlayerInventories = {} 
local PlayerEquipped = {} -- Nowa tabela: [UserId] = { [1] = UUID, [2] = nil ... }
local PlayerMaxSlots = {}

-- --- WCZYTYWANIE ---
function InventoryManager.LoadPlayer(player: Player)
	local success, data = pcall(function()
		return PetDataStore:GetAsync(tostring(player.UserId))
	end)

	PlayerInventories[player.UserId] = {}
	PlayerEquipped[player.UserId] = {nil, nil, nil, nil} -- 4 puste sloty
	
	if success and data then
		PlayerMaxSlots[player.UserId] = data.MaxSlots or Constants.MAX_SLOTS_DEFAULT
		
		-- Wczytaj zwierzaki
		if data.Pets then
			for _, petData in ipairs(data.Pets) do
				local newPet = PetInstance.fromData(petData)
				table.insert(PlayerInventories[player.UserId], newPet)
			end
		end
		
		-- Wczytaj wyposażone (tylko UUID)
		if data.Equipped then
			PlayerEquipped[player.UserId] = data.Equipped
		end
		return true
	else
		PlayerMaxSlots[player.UserId] = Constants.MAX_SLOTS_DEFAULT
		return false
	end
end

-- --- ZAPISYWANIE ---
function InventoryManager.SavePlayer(player: Player)
	local inventory = PlayerInventories[player.UserId]
	if not inventory then return end

	local serializedPets = {}
	for _, pet in ipairs(inventory) do
		table.insert(serializedPets, pet:Serialize())
	end

	local dataToSave = {
		MaxSlots = PlayerMaxSlots[player.UserId],
		Pets = serializedPets,
		Equipped = PlayerEquipped[player.UserId] -- Zapisujemy tabelę slotów
	}

	pcall(function()
		PetDataStore:SetAsync(tostring(player.UserId), dataToSave)
	end)
	
	-- Czyść pamięć
	PlayerInventories[player.UserId] = nil
	PlayerEquipped[player.UserId] = nil
	PlayerMaxSlots[player.UserId] = nil
end

-- --- LOGIKA WYPOSAŻANIA ---

function InventoryManager.EquipPet(player: Player, petUUID: string, slotIndex: number)
	local equipped = PlayerEquipped[player.UserId]
	local inventory = PlayerInventories[player.UserId]
	
	if not equipped or not inventory then return end
	if slotIndex < 1 or slotIndex > 4 then return end -- Mamy tylko 4 sloty
	
	-- 1. Sprawdź czy gracz w ogóle posiada tego zwierzaka
	local petExists = false
	for _, pet in ipairs(inventory) do
		if pet.UUID == petUUID then
			petExists = true
			break
		end
	end
	if not petExists then return end

	-- 2. Sprawdź czy ten zwierzak nie jest już założony w INNYM slocie
	-- Jeśli jest, zdejmij go ze starego miejsca
	for i, uuid in ipairs(equipped) do
		if uuid == petUUID then
			equipped[i] = nil 
		end
	end
	
	-- 3. Załóż na nowy slot
	equipped[slotIndex] = petUUID
	print(player.Name .. " wyposażył zwierzaka " .. petUUID .. " w slot " .. slotIndex)
	return true
end

function InventoryManager.UnequipPet(player: Player, slotIndex: number)
	local equipped = PlayerEquipped[player.UserId]
	if equipped and equipped[slotIndex] then
		equipped[slotIndex] = nil
	end
end

-- --- POMOCNICZE ---

function InventoryManager.AddPet(player: Player, petInstance)
	local inventory = PlayerInventories[player.UserId]
	if not inventory then return false end
	table.insert(inventory, petInstance)
	return true
end

-- Funkcja zwracająca pełny stan dla klienta (Ekwipunek + Info o założonych)
function InventoryManager.GetFullState(player: Player)
	local inventory = PlayerInventories[player.UserId] or {}
	local equippedUUIDs = PlayerEquipped[player.UserId] or {nil, nil, nil, nil}
	
	-- Serializujemy obiekty, żeby wysłać je przez RemoteFunction
	local serializedInv = {}
	for _, pet in ipairs(inventory) do
		table.insert(serializedInv, pet:Serialize())
	end
	
	return {
		Inventory = serializedInv,
		Equipped = equippedUUIDs
	}
end

return InventoryManager