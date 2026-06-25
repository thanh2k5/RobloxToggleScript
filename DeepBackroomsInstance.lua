-- DeepBackrooms Boss Only
-- Start: save current room
-- Scan button: clear and find Boss room

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

local Network = require(game.ReplicatedStorage.Library.Client.Network)
local PlayerPet = require(game.ReplicatedStorage.Library.Client.PlayerPet)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Backrooms Boss Only",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "Boss",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "DeepBackroomsPS99",
		FileName = "BossConfig"
	},
	KeySystem = false
})

local Main = Window:CreateTab("Main",4483362458)

_G.ScannedRooms = {}
_G.AutoMiniBoss = false
_G.Teleporting = false

local Status = Main:CreateLabel("Status: Loading")

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getFolder()
	return workspace.__THINGS.__INSTANCE_CONTAINER.Active.Backrooms.GeneratedBackrooms
end

local function saveBoss(room)
	pcall(function()
		if writefile then
			writefile("DeepBackroomsPS99_BossRoom.json",HttpService:JSONEncode({
				uid = room.uid,
				x = room.Position.X,
				y = room.Position.Y,
				z = room.Position.Z
			}))
		end
	end)
end

local function loadCurrentRoom()
	local root = getCharacter():FindFirstChild("HumanoidRootPart")
	if not root then return end

	for _,room in pairs(getFolder():GetChildren()) do
		if room:GetAttribute("DeepRoom") then
			local pos = room:GetPivot().Position

			if (pos-root.Position).Magnitude < 200 then
				local data = {
					uid = room:GetAttribute("RoomUID"),
					Id = room:GetAttribute("RoomID"),
					Model = room,
					Position = pos
				}

				_G.ScannedRooms = {data}
				saveBoss(data)

				Status:Set("Status: Saved Current Room")
				return
			end
		end
	end
end

local function teleportRoom(room)
	local char = getCharacter()
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	Network.Fire("RequestStreaming",room.Position)

	task.wait(.5)
	root.CFrame = CFrame.new(room.Position + Vector3.new(0,3,0))
end

local function scanBoss()
	_G.ScannedRooms = {}

	for _,room in pairs(getFolder():GetChildren()) do
		if room:GetAttribute("DeepRoom") 
		and room:GetAttribute("RoomID") == "GameMastersStage" then

			local data = {
				uid = room:GetAttribute("RoomUID"),
				Id = "GameMastersStage",
				Model = room,
				Position = room:GetPivot().Position
			}

			_G.ScannedRooms = {data}
			saveBoss(data)

			Status:Set("Status: Boss Found")
			teleportRoom(data)

			return
		end
	end

	Status:Set("Status: No Boss")
end

Main:CreateButton({
	Name="Scan Boss Room",
	Callback=function()
		scanBoss()
	end
})

Main:CreateToggle({
	Name="Auto Farm Boss",
	CurrentValue=false,
	Callback=function(v)
		_G.AutoMiniBoss=v
	end
})

Main:CreateToggle({
	Name="Infinite Pet Speed",
	CurrentValue=false,
	Callback=function(v)
		_G.InfinitePetSpeed=v
	end
})

task.spawn(function()
	task.wait(2)
	loadCurrentRoom()
end)

task.spawn(function()
	while task.wait(.5) do
		if not _G.AutoMiniBoss then continue end

		local room = _G.ScannedRooms[1]
		if not room or room.Id ~= "GameMastersStage" then continue end

		for _,b in pairs(workspace.__THINGS.Breakables:GetChildren()) do
			local id=b:GetAttribute("BreakableID")

			if id=="Daydream Mimic Chest2" or id=="Daydream Mimic Boss2" then
				if (b:GetPivot().Position-room.Position).Magnitude < 150 then

					Network.UnreliableFire(
						"Breakables_PlayerDealDamage",
						b:GetAttribute("BreakableUID")
					)

					for _,pet in pairs(PlayerPet.GetByPlayer(player)) do
						if pet.cpet then
							pet:SetTarget(b)
						end
					end
				end
			end
		end
	end
end)

player.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

Rayfield:LoadConfiguration()
