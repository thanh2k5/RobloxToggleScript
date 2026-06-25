if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local Network = require(game.ReplicatedStorage.Library.Client.Network)
local PlayerPet = require(game.ReplicatedStorage.Library.Client.PlayerPet)

local player = Players.LocalPlayer
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "PS99 Boss Script",
	LoadingTitle = "Loading...",
	KeySystem = false
})

local BossTab = Window:CreateTab("Boss", 4483362458)
local Status = BossTab:CreateLabel("Boss: Loading...")

_G.BossRoom = nil
_G.AutoBoss = false
_G.Teleporting = false

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getRooms()
	local container = workspace:FindFirstChild("__THINGS")
		and workspace.__THINGS:FindFirstChild("__INSTANCE_CONTAINER")
	if not container then return nil end

	local active = container:FindFirstChild("Active")
	local backrooms = active and active:FindFirstChild("Backrooms")
	return backrooms and backrooms:FindFirstChild("GeneratedBackrooms")
end

local function loadCurrentBossRoom()
	local folder = getRooms()
	local char = getCharacter()
	local root = char:FindFirstChild("HumanoidRootPart")
	if not folder or not root then return end

	for _, room in ipairs(folder:GetChildren()) do
		if room:GetAttribute("DeepRoom") then
			local pos = room:GetPivot().Position
			if (pos - root.Position).Magnitude < 200 then
				_G.BossRoom = {
					uid = room:GetAttribute("RoomUID"),
					Model = room,
					Position = pos
				}
				Status:Set("Boss Loaded")
				return
			end
		end
	end
end

local function teleportBoss()
	local boss = _G.BossRoom
	if not boss or _G.Teleporting then return end

	_G.Teleporting = true
	local char = getCharacter()
	local root = char:FindFirstChild("HumanoidRootPart")

	if root then
		Network.Fire("RequestStreaming", boss.Position)
		root.CFrame = CFrame.new(boss.Position + Vector3.new(0,5,0))
	end

	_G.Teleporting = false
end

BossTab:CreateButton({
	Name = "Teleport Boss",
	Callback = teleportBoss
})

BossTab:CreateToggle({
	Name = "Auto Farm Boss",
	CurrentValue = false,
	Callback = function(v)
		_G.AutoBoss = v
	end
})

RunService.Heartbeat:Connect(function()
	if not _G.AutoBoss then return end

	if not _G.BossRoom then
		loadCurrentBossRoom()
		return
	end

	local char = getCharacter()
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local bossPos = _G.BossRoom.Position

	if (root.Position - bossPos).Magnitude > 130 then
		teleportBoss()
		return
	end

	local folder = workspace:FindFirstChild("__THINGS")
		and workspace.__THINGS:FindFirstChild("Breakables")

	if not folder then return end

	for _, b in ipairs(folder:GetChildren()) do
		local id = b:GetAttribute("BreakableID")

		if id == "Daydream Mimic Chest2"
		or id == "Daydream Mimic Boss2" then

			if (b:GetPivot().Position - bossPos).Magnitude < 130 then
				Network.UnreliableFire(
					"Breakables_PlayerDealDamage",
					b:GetAttribute("BreakableUID")
				)

				for _, pet in pairs(PlayerPet.GetByPlayer(player)) do
					if pet.cpet then
						pet:SetTarget(b)
					end
				end

				break
			end
		end
	end
end)

player.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

task.wait(2)
loadCurrentBossRoom()
Rayfield:LoadConfiguration()
