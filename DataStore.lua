local players = game:GetService("Players")
local dataStoreService = game:GetService("DataStoreService")
local dataStore = dataStoreService:GetDataStore("test-085")

local RS = game:GetService("ReplicatedStorage").MainFolder_RS

local playerData = script.PlayerData

local function SaveData(player)
	local PData = {}
	local PetData = {}
	for _, folder in pairs(player:GetChildren()) do
		if folder.Name ~= "Pets" then
			if playerData:FindFirstChild(folder.Name) then
				if playerData[folder.Name]:GetAttribute("SaveChildren") == true then
					PData[folder.Name] = {}
					if playerData[folder.Name]:GetAttribute("SaveChildrenValues") == true then
						for _, child in pairs(folder:GetChildren()) do
							if not child:GetAttribute("DoNotSaveValue") then
								table.insert(PData[folder.Name], {child.Name, child.Value, child.ClassName})
							end
						end
					else
						for _, child in pairs(folder:GetChildren()) do
							if not child:GetAttribute("DoNotSaveValue") then
								table.insert(PData[folder.Name], {child.Name, child.ClassName})
							end
						end
					end
				end
			end
		end
	end

	for _, PetObject in pairs(player.Pets:GetChildren()) do
		PetData[#PetData + 1] = {
			Name = PetObject.Name,
			Equipped = PetObject.Equipped.Value,
			Locked = PetObject.Locked.Value,
			Strength = PetObject.Strength.Value,
			Multiplier = PetObject.Multiplier.Value,
			PetID = PetObject.PetID.Value,
			Type = PetObject.Type.Value
		}
	end

	local success, errorMsg = pcall(function()
		dataStore:SetAsync(player.UserId.."_Key", {["PlayerData"] = PData, ["PetData"] = PetData})
	end)

	if success then
		print("Saved Data")
	else
		warn(errorMsg)
	end
end

local function LoadData(player)
	for _, v in pairs(playerData:GetChildren()) do
		v:Clone().Parent = player
	end
	local folder = Instance.new("Folder", workspace.MainFolder_Workspace.PlayerPets)
	folder.Name = player.Name

	local data
	local success, errorMsg = pcall(function()
		data = dataStore:GetAsync(player.UserId.."_Key")
	end)
	if errorMsg then
		wait(errorMsg)
		player:Kick("Could not save data")
	end
	if data then
		local PData = data.PlayerData
		local PetData = data.PetData
		for i, v in pairs(PData) do
			if #v > 0 then
				for x, c in pairs(v) do
					local value
					if playerData:FindFirstChild(tostring(i)):FindFirstChild(c[1]) then
						value = player:FindFirstChild(tostring(i)):FindFirstChild(c[1])
					else
						if c[3] == nil then
							value = Instance.new(tostring(c[2]))
						else
							value = Instance.new(tostring(c[3]))
						end
					end
					value.Name = c[1]
					value.Value = c[2]
					value.Parent = player[tostring(i)]
				end
			end
		end

		for _, v in pairs(PetData) do
			local PetObject = game.ReplicatedStorage.MainFolder_RS.Pets:WaitForChild("PetFolderTemplate"):Clone()
			local PetData = require(game.ReplicatedStorage.MainFolder_RS.Pets.Models:FindFirstChild(v.Name).PetData)
			local TypeNumber = game.ReplicatedStorage.MainFolder_RS.Pets.Tiers:FindFirstChild(v.Type).Value
			PetObject.Name = v.Name
			PetObject.Strength.Value = PetData.Strength * TypeNumber
			PetObject.Multiplier.Value = PetData.Multiplier * TypeNumber
			PetObject.Equipped.Value = v.Equipped
			PetObject.Locked.Value = v.Locked
			PetObject.PetID.Value = v.PetID
			PetObject.Type.Value = v.Type
			PetObject.Parent = player.Pets
		end
	end
end

local function PlayerRemoving(player)
	SaveData(player)
end

local function PlayerAdded(player)
	LoadData(player)
end

players.PlayerAdded:Connect(PlayerAdded)
players.PlayerRemoving:Connect(PlayerRemoving)
game:BindToClose(function()
	for _, player in pairs(players:GetPlayers()) do
		coroutine.wrap(SaveData)(player)
	end
end)