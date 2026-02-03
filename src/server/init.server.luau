local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(script.PokePets.InventoryManager)
local PetInstance = require(ReplicatedStorage.Shared.PokePets.PetInstance)

-- Tworzenie folderu Remotes (jeśli nie istnieje)
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
remotesFolder.Name = "Remotes"

-- Tworzenie zdarzeń komunikacji
local getInventoryFunc = remotesFolder:FindFirstChild("GetInventory") or Instance.new("RemoteFunction", remotesFolder)
getInventoryFunc.Name = "GetInventory"

local equipEvent = remotesFolder:FindFirstChild("EquipPet") or Instance.new("RemoteEvent", remotesFolder)
equipEvent.Name = "EquipPet"

-- Obsługa graczy
Players.PlayerAdded:Connect(function(player)
	local hasData = InventoryManager.LoadPlayer(player)
	if not hasData then
		-- Startery dla nowych
		InventoryManager.AddPet(player, PetInstance.new("Ignis", "Normal"))
		InventoryManager.AddPet(player, PetInstance.new("Aqua", "Normal"))
	end
end)

Players.PlayerRemoving:Connect(function(player)
	InventoryManager.SavePlayer(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function() InventoryManager.SavePlayer(player) end)
	end
	task.wait(2)
end)

-- --- OBSŁUGA REMOTES ---

-- Klient prosi o dane do GUI
getInventoryFunc.OnServerInvoke = function(player)
	return InventoryManager.GetFullState(player)
end

-- Klient chce wyposażyć/zdjąć
equipEvent.OnServerEvent:Connect(function(player, action, arg1, arg2)
	if action == "Equip" then
		-- arg1: UUID, arg2: SlotIndex
		InventoryManager.EquipPet(player, arg1, arg2)
	elseif action == "Unequip" then
		-- arg1: SlotIndex
		InventoryManager.UnequipPet(player, arg1)
	end
end)