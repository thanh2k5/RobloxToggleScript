local TARGET_PLACE = 12900046592
local dest = Vector3.new(596, 24, 260)
getgenv().script_key = "yZBAbVHtxUiuNvxTnHgFBHkmRBNrTrUs";
loadstring(game:HttpGet("https://raw.githubusercontent.com/JustLevel/goombahub/main/goombahub.lua"))()
if game.PlaceId ~= TARGET_PLACE then return end
local p = game.Players.LocalPlayer
local function tp(char)
    task.wait(10)
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(dest)
end
if p.Character then tp(p.Character) end
p.CharacterAdded:Connect(tp)
