if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

if typeof(require) ~= "function" then
	Players.LocalPlayer:Kick("Unsupported")
	return
end

local Network = require(game.ReplicatedStorage.Library.Client.Network)
local InstancingCmds = require(game.ReplicatedStorage.Library.Client.InstancingCmds)
local MiscItem = require(game.ReplicatedStorage.Library.Items.MiscItem)
local EggCmds = require(game.ReplicatedStorage.Library.Client.EggCmds)
local CustomEggsCmds = require(game.ReplicatedStorage.Library.Client.CustomEggsCmds)
local PlayerPet = require(game.ReplicatedStorage.Library.Client.PlayerPet)

local oldCalculate = PlayerPet.CalculateSpeedMultiplier
PlayerPet.CalculateSpeedMultiplier = function(self, ...)
	if _G.InfinitePetSpeed then
		return 100000
	end
	return oldCalculate(self, ...)
end

local localPlayer = Players.LocalPlayer
local enterPosition = nil

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "PS99 Backrooms Script",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "by Pirate Games",
	Theme = "Default",
	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false,
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "DeepBackroomsPS99",
		FileName = "Config"
	},
	KeySystem = false
})
local MiniBossTab = Window:CreateTab("Boss Chest", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

_G.ScannedRooms = {}
_G.ScannedRoomsMap = {}
_G.VistedRooms = {}
_G.IsScanning = false
_G.Teleporting = false
_G.AutoHatch = false
_G.AutoTPBestEgg = false
_G.AutoMiniBoss = false
_G.AutoTPLockedEgg = false
_G.InfinitePetSpeed = false

_G.SelectedLockedEggMult = "Any"

local DeepChestRoomTPButton
local BossTPButton
local AutoFarmBoss
local RejoinButton
local ServerHopButton
local InfPetSpeedButton

local function getCharacter()
	return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

-- Removed auto teleport into Backrooms\n
local function createMessage(msg)
	if workspace:FindFirstChildOfClass("Message") then
		return
	end
	local message = Instance.new("Message", workspace)
	message.Text = msg
	return message
end

local function serverHop(reason)
	local message = createMessage(reason)

	local success = pcall(function()
		local api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

		local function list(cursor)
			local Raw = game:HttpGet(api .. ((cursor and "&cursor=" .. cursor) or ""))
			return HttpService:JSONDecode(Raw)
		end

		local servers = list()
		for _, server in ipairs(servers.data) do
			if server.playing < server.maxPlayers and server.id ~= game.JobId then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, localPlayer)
				return true
			end
		end
	end)

	if not success then
		TeleportService:Teleport(game.PlaceId, localPlayer)
	else
		game.Debris:AddItem(message, 10)
	end
end

if _G.ExecutedScript ~= nil then
	createMessage("Script was re-executed rejoining the game...")
	task.delay(2, function()
		TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
	end)
	return
end

_G.ExecutedScript = true

local function getGeneratedBackrooms()
	local container = workspace:FindFirstChild("__THINGS"):FindFirstChild("__INSTANCE_CONTAINER")
	if not container then
		return nil
	end

	local active = container:FindFirstChild("Active")
	if not active then
		return nil
	end

	local backrooms = active:WaitForChild("Backrooms", 3)
	if not backrooms then
		return nil
	end

	return backrooms:FindFirstChild("GeneratedBackrooms")
end

local function findRoomDataByUID(roomUID)
	local roomData = _G.ScannedRoomsMap[roomUID]
	if roomData then
		return roomData
	end
	return nil
end

local function findRoomModelByUID(roomUID)
	local folder = getGeneratedBackrooms()
	if not folder then 
		return nil 
	end

	for _, roomModel in ipairs(folder:GetChildren()) do
		if roomModel:GetAttribute("RoomUID") == roomUID then
			return roomModel
		end
	end

	return nil
end

local function keyCheck()
	local keyItem = MiscItem("Deep Backrooms Crayon Key")
	if keyItem and keyItem:HasAny() then
		return true
	end
	return false
end

local function UnlockRoom(roomUID)
	if _G.IsScanning == true then
		return
	end

	local character = getCharacter()
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local roomModel = findRoomModelByUID(roomUID)
	if not roomModel then 
		return 
	end

	local LockedDoors = roomModel:FindFirstChild("LockedDoors")
	if not LockedDoors then 
		return 
	end

	local isLocked = false
	for _, child in ipairs(LockedDoors:GetChildren()) do
		local Lock = child:FindFirstChild("Lock")
		if Lock and Lock.Transparency < 0.5 then
			rootPart.CFrame = CFrame.new(Lock.Position)
			task.wait(0.25)
			isLocked = true
			break
		end
	end

	if not isLocked then 
		return 
	end

	local ownsKey = keyCheck()
	if ownsKey then
		local activeInstance = InstancingCmds.Get()
		if activeInstance then
			activeInstance:FireCustom("AbstractRoom_FireServer", roomUID, "UnlockDoors")
		end
	end
end

local function TeleportToRoom(roomUID, isScanning)
	if _G.Teleporting then
		return
	end

	_G.Teleporting = true

	local character = getCharacter()
	if not character then
		_G.Teleporting = false
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		_G.Teleporting = false
		return
	end

	local roomData = findRoomDataByUID(roomUID)
	if not roomData then
		warn("NO ROOM DATA")
		_G.Teleporting = false
		return
	end

	local roomModel = roomData.Model
	local roomId = roomData.Id
	local pos = roomData.Position

	local forceField = Instance.new("ForceField")
	forceField.Visible = false
	forceField.Parent = character

	Network.Fire("RequestStreaming", pos)

	rootPart.Anchored = true
	rootPart.CFrame = CFrame.new(pos) + Vector3.new(0, 3, 0)

	task.delay(1.5, function()
		if forceField and forceField.Parent then 
			forceField:Destroy() 
		end

		if (not isScanning) then
			rootPart.Anchored = false
		end
	end)

	if (not isScanning) then
		task.wait(0.5)

		if roomId == "DeepLockedEggRoom" or roomId == "GameMastersStage" then
			UnlockRoom(roomUID)
		end

		local targetObj = roomModel:FindFirstChild("Sign")
			or roomModel.PrimaryPart
			or roomModel:FindFirstChildWhichIsA("BasePart", true)

		rootPart.CFrame = (targetObj and targetObj.CFrame or CFrame.new(pos)) + Vector3.new(0, 15, 0) 

		if roomId == "DeepLockedEggRoom" then
			local activeInstance = InstancingCmds.Get()
			if activeInstance then
				local ok, playerDataList = pcall(function()
					return activeInstance:InvokeCustom("AbstractRoom_GetPlayerData")
				end)

				if not ok then
					warn("FAILED TO GET PLR DATA", playerDataList)
					return
				end

				for _, roomInfo in ipairs(playerDataList) do
					if roomInfo.uid == roomUID then
						local expireTime = roomInfo.data and roomInfo.data.UnlockExpireTimestamp or nil
						if expireTime then
							roomData.ExpireTime = expireTime
						end
						break
					end
				end
			else
				warn("not in instance??")
			end
		end
	end

	_G.Teleporting = false
end

local function CleanupWalls()
	local folder = getGeneratedBackrooms()
	if not folder then
		return
	end

	for _, child in ipairs(folder:GetChildren()) do
		task.spawn(function()
			if child.Name == "Walls" then
				local children = child:GetChildren()
				for i, part in ipairs(children) do
					if i % 25 == 0 then
						RunService.Heartbeat:Wait()
					end
					part:Destroy()
				end
				child:Destroy()
			end
		end)
	end
end

local function TPtoSpawn()
	local character = getCharacter()
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	if typeof(enterPosition) ~= "Vector3" then
		return
	end

	local pos = enterPosition + Vector3.new(0, 4, 0)

	Network.Fire("RequestStreaming", pos)

	task.delay(0.25, function()
		if character.Parent then
			if rootPart.Anchored == true then
				rootPart.Anchored = false
			end

			character:PivotTo(CFrame.new(pos))
		end
	end)
end

local function canDoAction()
	return (not _G.IsScanning) and (not _G.Teleporting)
end

BreakablesRoomTPButton = MiniBossTab:CreateButton({
	Name = "Teleport to nearest Breakable Room!",
	Callback = function()
		if (not canDoAction()) then
			return
		end

		local found = false
		for _, r in ipairs(_G.ScannedRooms) do
			if string.match(r.Id, "DeepCoinRoom") ~= nil then
				found = true
				TeleportToRoom(r.uid)
				task.wait(0.3)
				local roomModel = r.Model
				local breakZone = roomModel:FindFirstChild("BREAK_ZONE")
				if breakZone then
					local character = getCharacter()
					if character then
						local rooPart = character:FindFirstChild("HumanoidRootPart")
						if rooPart then
							character:PivotTo(CFrame.new(breakZone.Position) + Vector3.new(0, 3, 0))
						end
					end
				end
				break
			end
		end

		if not found then
			Rayfield:Notify({
				Title = "No Breakable Room",
				Content = "Could not find any scanned Breakable Room",
				Duration = 4,
				Image = 4483362458
			})
		end
	end,
})

DeepChestRoomTPButton = MiniBossTab:CreateButton({
	Name = "Teleport to nearest MINI Chest Room!",
	Callback = function()
		if (not canDoAction()) then
			return
		end

		local found = false
		for _, r in ipairs(_G.ScannedRooms) do
			if string.match(r.Id, "DeepChestRoom") ~= nil then
				found = true
				TeleportToRoom(r.uid)
				task.wait(0.3)
				local roomModel = r.Model
				local breakZone = roomModel:FindFirstChild("BREAK_ZONE")
				if breakZone then
					local character = getCharacter()
					if character then
						local rooPart = character:FindFirstChild("HumanoidRootPart")
						if rooPart then
							character:PivotTo(CFrame.new(breakZone.Position) + Vector3.new(0, 3, 0))
						end
					end
				end
				break
			end
		end

		if not found then
			Rayfield:Notify({
				Title = "No Breakable Room",
				Content = "Could not find any scanned MINI Chest Room",
				Duration = 4,
				Image = 4483362458
			})
		end
	end,
})

BossTPButton = MiniBossTab:CreateButton({
	Name = "Teleport to Boss Room!",
	Callback = function()
		if (not canDoAction()) then
			return
		end

		local found = false
		for _, r in ipairs(_G.ScannedRooms) do
			if r.Id == "GameMastersStage" then
				found = true
				TeleportToRoom(r.uid)
				task.wait(0.3)
				local roomModel = r.Model
				local breakZone = roomModel:FindFirstChild("BREAK_ZONE")
				if breakZone then
					local character = getCharacter()
					if character then
						local rooPart = character:FindFirstChild("HumanoidRootPart")
						if rooPart then
							character:PivotTo(CFrame.new(breakZone.Position) + Vector3.new(0, 3, 0))
						end
					end
				end
				break
			end
		end

		if not found then
			Rayfield:Notify({
				Title = "No Boss Room",
				Content = "Could not find any scanned Boss Room",
				Duration = 4,
				Image = 4483362458
			})
		end
	end,
})

AutoFarmBoss = MiniBossTab:CreateToggle({
	Name = "Auto Farm Boss Room",
	CurrentValue = false,
	Flag = "AutoFarmBoss",
	Callback = function(value)
		if (not canDoAction()) then
			return
		end
		_G.AutoMiniBoss = value
	end,
})

InfPetSpeedButton = MiscTab:CreateToggle({
	Name = "Infinite Pet Speed",
	CurrentValue = false,
	Flag = "InfinitePetSpeed",
	Callback = function(value)
		_G.InfinitePetSpeed = value
	end,
})

RejoinButton = MiscTab:CreateButton({
	Name = "Rejoin",
	Callback = function()
		TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
	end,
})

ServerHopButton = MiscTab:CreateButton({
	Name = "ServerHop",
	Callback = function()
		serverHop("Server Hopping...")
	end,
})

task.spawn(function()
	while true do
		task.wait(0.5)

		if not _G.AutoMiniBoss then
			continue
		end

		if not canDoAction() then
			continue
		end

		local character = getCharacter()
		if not character then
			continue
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			continue
		end

		local targetRoom = nil
		for _, r in ipairs(_G.ScannedRooms) do
			if r.Id == "GameMastersStage" then
				targetRoom = r
				break
			end
		end

		if targetRoom then
			local uid = targetRoom.uid
			local roomModel = targetRoom.Model
			local pos = targetRoom.Position

			local breakZone = roomModel:FindFirstChild("BREAK_ZONE")
			if breakZone then
				pos = breakZone:GetPivot().Position
			end

			local isInRoom = (rootPart.Position - pos).Magnitude <= 130
			if (not isInRoom) then
				TeleportToRoom(uid)
				task.wait(1)
			else
				local targetBreakable = nil
				local breakables = workspace:FindFirstChild("__THINGS"):FindFirstChild("Breakables"):GetChildren()
				for _, b in ipairs(breakables) do
					local bId = b:GetAttribute("BreakableID")
					if bId == "Daydream Mimic Chest2" then
						local bPos = b:GetPivot().Position
						if (bPos - pos).Magnitude < 130 then
							targetBreakable = b
							break
						end
					end
				end
				if not targetBreakable then
					for _, b in ipairs(breakables) do
						local bId = b:GetAttribute("BreakableID")
						if bId == "Daydream Mimic Boss2" then
							local bPos = b:GetPivot().Position
							if (bPos - pos).Magnitude < 130 then
								targetBreakable = b
								break
							end
						end
					end
				end
				if targetBreakable then
					local bUID = targetBreakable:GetAttribute("BreakableUID")
					local bPos = targetBreakable:GetPivot().Position
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:MoveTo(bPos)
					end
					Network.UnreliableFire("Breakables_PlayerDealDamage", bUID)
					local activePets = PlayerPet.GetByPlayer(localPlayer)
					for _, pet in pairs(activePets) do
						if pet.cpet then
							pet:SetTarget(targetBreakable)
						end
					end
				end
			end
		else
			serverHop("No Boss Room in this server. hopping...")
			task.wait(5)
		end 
	end
end)

task.spawn(function()
	while true do
		if _G.IsScanning then
			task.wait(0)
			continue
		end

		CleanupWalls()
		task.wait(1)
	end
end)

local function SaveBossRoomConfig(roomData)
	pcall(function()
		if writefile then
			writefile("DeepBackroomsPS99_BossRoom.json", HttpService:JSONEncode({
				uid = roomData.uid,
				Position = {
					x = roomData.Position.X,
					y = roomData.Position.Y,
					z = roomData.Position.Z
				}
			}))
		end
	end)
end

local function LoadCurrentBossRoom()
	local folder = getGeneratedBackrooms()
	local character = getCharacter()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not folder or not root then return end

	for _, room in ipairs(folder:GetChildren()) do
		if room:GetAttribute("DeepRoom") then
			local pos = room:GetPivot().Position
			if (pos - root.Position).Magnitude < 200 then
				local roomData = {
					uid = room:GetAttribute("RoomUID"),
					Id = room:GetAttribute("RoomID"),
					Model = room,
					CFrame = room:GetPivot(),
					Position = pos
				}

				table.insert(_G.ScannedRooms, roomData)
				_G.ScannedRoomsMap[roomData.uid] = roomData

				if roomData.Id == "GameMastersStage" then
					SaveBossRoomConfig(roomData)
					warn("Saved Boss Room:", roomData.uid)
				else
					warn("Current Room:", roomData.Id)
				end

				return
			end
		end
	end
end

localPlayer.Idled:Connect(function()
	-- ANTI AFK
	VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

task.wait(2)
LoadCurrentBossRoom()
Rayfield:LoadConfiguration()
