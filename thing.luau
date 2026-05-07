local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("ARMED_DEEP_EMOTE_PROBE")
if old then
	old:Destroy()
end

local g = Instance.new("ScreenGui")
g.Name = "ARMED_DEEP_EMOTE_PROBE"
g.ResetOnSpawn = false
g.Parent = pg

local f = Instance.new("Frame")
f.Parent = g
f.Size = UDim2.new(0, 620, 0, 340)
f.Position = UDim2.new(1, -640, 0, 90)
f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
f.BorderSizePixel = 0

local top = Instance.new("TextButton")
top.Parent = f
top.Size = UDim2.new(1, -72, 0, 28)
top.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
top.BorderSizePixel = 0
top.Text = "ARMED DEEP EMOTE PROBE - DRAG"
top.Font = Enum.Font.Code
top.TextSize = 16
top.TextColor3 = Color3.new(1, 1, 1)
top.AutoButtonColor = false

local arm = Instance.new("TextButton")
arm.Parent = f
arm.Position = UDim2.new(1, -68, 0, 0)
arm.Size = UDim2.new(0, 68, 0, 28)
arm.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
arm.BorderSizePixel = 0
arm.Text = "ARM"
arm.Font = Enum.Font.Code
arm.TextSize = 16
arm.TextColor3 = Color3.new(1, 1, 1)

local txt = Instance.new("TextBox")
txt.Parent = f
txt.Position = UDim2.new(0, 6, 0, 34)
txt.Size = UDim2.new(1, -12, 1, -40)
txt.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
txt.BorderSizePixel = 0
txt.ClearTextOnFocus = false
txt.MultiLine = true
txt.TextEditable = false
txt.TextWrapped = true
txt.Font = Enum.Font.Code
txt.TextSize = 14
txt.TextColor3 = Color3.new(1, 1, 1)
txt.TextXAlignment = Enum.TextXAlignment.Left
txt.TextYAlignment = Enum.TextYAlignment.Top
txt.Text = "Press ARM, then play the emote."

local dragging = false
local dragStart: Vector3? = nil
local startPos: UDim2? = nil

top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = f.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and dragStart and startPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		f.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)

local DEFAULT_NAMES = {
	idle = true,
	walk = true,
	run = true,
	jump = true,
	fall = true,
	climb = true,
	swim = true,
	swimidle = true,
	sit = true,
	toolnone = true,
	toolslash = true,
	toollunge = true,
	animation1 = true,
	animation2 = true,
	animate = true,
}

local DEFAULT_IDS = {
	["rbxassetid://0"] = true,
	["rbxassetid://507766666"] = true,
	["rbxassetid://507766951"] = true,
	["rbxassetid://507766388"] = true,
	["rbxassetid://507777826"] = true,
	["rbxassetid://507767714"] = true,
	["rbxassetid://507765000"] = true,
	["rbxassetid://507765644"] = true,
	["rbxassetid://507767968"] = true,
	["rbxassetid://507768375"] = true,
	["rbxassetid://507770239"] = true,
	["rbxassetid://507770453"] = true,
	["rbxassetid://507771019"] = true,
	["rbxassetid://507771955"] = true,
	["rbxassetid://507772104"] = true,
	["rbxassetid://507776043"] = true,
}

local ARM_SECONDS = 10
local NEAR_DISTANCE = 80

local armedAt = 0
local baseline: {[string]: boolean} = {}
local firstSeen: {[string]: number} = {}
local captured: {[string]: string} = {}

local function normalizeId(id: string): string
	local numeric = string.match(tostring(id), "%d+")
	if numeric then
		return "rbxassetid://" .. numeric
	end

	return string.lower(tostring(id))
end

local function getCharacter(): Model?
	return plr.Character
end

local function getMainAnimator(): Animator?
	local char = getCharacter()
	if not char then
		return nil
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid:FindFirstChildOfClass("Animator") or nil
end

local function getModel(inst: Instance): Model?
	return inst:FindFirstAncestorOfClass("Model")
end

local function getLabel(inst: Instance): string
	local model = getModel(inst)
	return model and model:GetFullName() or inst:GetFullName()
end

local function trackKey(animator: Animator, track: AnimationTrack): string
	local anim = track.Animation
	local id = anim and normalizeId(anim.AnimationId or "") or "noid"
	return animator:GetDebugId(0) .. "|" .. id .. "|" .. tostring(track.Name)
end

local function isDefaultTrack(track: AnimationTrack): boolean
	local n = string.lower(track.Name or "")
	if DEFAULT_NAMES[n] then
		return true
	end

	local anim = track.Animation
	if anim then
		local animName = string.lower(anim.Name or "")
		if DEFAULT_NAMES[animName] then
			return true
		end

		if DEFAULT_IDS[normalizeId(anim.AnimationId or "")] then
			return true
		end
	end

	return false
end

local function isPlayerCharacterModel(model: Model?): boolean
	if not model then
		return false
	end

	if Players:GetPlayerFromCharacter(model) then
		return true
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if model.Name == p.Name or model.Name == p.DisplayName then
			return true
		end
	end

	return false
end

local function isInsideOtherPlayer(inst: Instance): boolean
	local char = getCharacter()
	local node: Instance? = inst

	while node and node ~= game do
		if node:IsA("Model") and isPlayerCharacterModel(node) then
			return node ~= char
		end

		node = node.Parent
	end

	return false
end

local function isLocalContainer(inst: Instance): boolean
	local char = getCharacter()
	if char and inst:IsDescendantOf(char) then
		return true
	end

	if inst:IsDescendantOf(pg) then
		return true
	end

	local camera = Workspace.CurrentCamera
	if camera and inst:IsDescendantOf(camera) then
		return true
	end

	return false
end

local function getPart(value: any): BasePart?
	if typeof(value) == "Instance" and value:IsA("BasePart") then
		return value
	end

	return nil
end

local function linksToCharacter(inst: Instance, model: Model?): boolean
	local char = getCharacter()
	if not char or not model or model == char then
		return false
	end

	if inst:IsA("Motor6D") or inst:IsA("Weld") or inst:IsA("WeldConstraint") then
		local p0 = getPart((inst :: any).Part0)
		local p1 = getPart((inst :: any).Part1)

		if p0 and p1 then
			return (p0:IsDescendantOf(char) and p1:IsDescendantOf(model)) or (p1:IsDescendantOf(char) and p0:IsDescendantOf(model))
		end
	end

	if inst:IsA("Constraint") then
		local a0 = (inst :: Constraint).Attachment0
		local a1 = (inst :: Constraint).Attachment1

		if a0 and a1 and a0.Parent and a1.Parent and a0.Parent:IsA("BasePart") and a1.Parent:IsA("BasePart") then
			local p0 = a0.Parent
			local p1 = a1.Parent

			return (p0:IsDescendantOf(char) and p1:IsDescendantOf(model)) or (p1:IsDescendantOf(char) and p0:IsDescendantOf(model))
		end
	end

	return false
end

local function modelLinkedToCharacter(model: Model?): boolean
	local char = getCharacter()
	if not char or not model then
		return false
	end

	if model:IsDescendantOf(char) then
		return true
	end

	for _, inst in ipairs(model:GetDescendants()) do
		if linksToCharacter(inst, model) then
			return true
		end
	end

	for _, inst in ipairs(char:GetDescendants()) do
		if linksToCharacter(inst, model) then
			return true
		end
	end

	return false
end

local function modelNearCharacter(model: Model?): boolean
	local char = getCharacter()
	if not char or not model then
		return false
	end

	local charRoot = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local propRoot = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)

	if not charRoot or not propRoot then
		return false
	end

	return (charRoot.Position - propRoot.Position).Magnitude <= NEAR_DISTANCE
end

local function hasOwnerHint(inst: Instance): boolean
	local localName = string.lower(plr.Name)
	local displayName = string.lower(plr.DisplayName)
	local userId = tostring(plr.UserId)

	local node: Instance? = inst
	while node and node ~= game do
		local n = string.lower(node.Name)

		if string.find(n, localName, 1, true) or string.find(n, displayName, 1, true) then
			return true
		end

		local owner = node:GetAttribute("Owner") or node:GetAttribute("OwnerName") or node:GetAttribute("PlayerName")
		if typeof(owner) == "string" and string.lower(owner) == localName then
			return true
		end

		local ownerId = node:GetAttribute("OwnerId") or node:GetAttribute("UserId") or node:GetAttribute("PlayerUserId")
		if ownerId ~= nil and tostring(ownerId) == userId then
			return true
		end

		node = node.Parent
	end

	return false
end

local function scanAnimators(): {Animator}
	local out: {Animator} = {}

	for _, inst in ipairs(game:GetDescendants()) do
		if inst:IsA("Animator") and not isInsideOtherPlayer(inst) then
			table.insert(out, inst)
		end
	end

	return out
end

local function shouldCapture(animator: Animator, key: string): (boolean, string)
	local main = getMainAnimator()
	if animator == main then
		return true, "player"
	end

	local model = getModel(animator)

	if isLocalContainer(animator) then
		return true, "local-container"
	end

	if modelLinkedToCharacter(model) then
		return true, "linked"
	end

	if hasOwnerHint(animator) then
		return true, "owner-hint"
	end

	if armedAt > 0 and os.clock() - armedAt <= ARM_SECONDS and not baseline[key] then
		if modelNearCharacter(model) then
			return true, "armed-near-new"
		end

		local camera = Workspace.CurrentCamera
		if camera and animator:IsDescendantOf(camera) then
			return true, "armed-camera-new"
		end

		if animator:IsDescendantOf(pg) then
			return true, "armed-gui-new"
		end
	end

	return false, "filtered"
end

local function scan()
	for _, animator in ipairs(scanAnimators()) do
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			if not isDefaultTrack(track) then
				local anim = track.Animation
				local id = anim and normalizeId(anim.AnimationId or "") or ""

				if id ~= "" and id ~= "rbxassetid://0" then
					local key = trackKey(animator, track)
					firstSeen[key] = firstSeen[key] or os.clock()

					local ok, reason = shouldCapture(animator, key)
					if ok then
						captured[key] = string.format(
							"[%s] (%s)\n%s | %s",
							getLabel(animator),
							reason,
							id,
							track.Name or "track"
						)
					end
				end
			end
		end
	end
end

local function takeBaseline()
	table.clear(baseline)
	table.clear(firstSeen)
	table.clear(captured)

	for _, animator in ipairs(scanAnimators()) do
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			if not isDefaultTrack(track) then
				baseline[trackKey(animator, track)] = true
			end
		end
	end
end

arm.MouseButton1Click:Connect(function()
	armedAt = os.clock()
	takeBaseline()
	arm.Text = "ARMED"
	arm.BackgroundColor3 = Color3.fromRGB(40, 110, 60)

	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Probe armed",
			Text = "Play the emote now",
			Duration = 3,
		})
	end)
end)

local function refresh()
	scan()

	if armedAt > 0 and os.clock() - armedAt > ARM_SECONDS then
		arm.Text = "ARM"
		arm.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	end

	local rows = {}
	for _, row in pairs(captured) do
		table.insert(rows, row)
	end

	table.sort(rows)

	if #rows == 0 then
		txt.Text = "Press ARM, then play the emote.\n\nThis version scans Workspace, PlayerGui, CurrentCamera, WorldModels, local character props, and linked props."
	else
		txt.Text = "CAPTURED LOCAL / PROP ANIMATIONS:\n\n" .. table.concat(rows, "\n\n")
	end
end

plr.CharacterAdded:Connect(function()
	armedAt = 0
	task.wait(1)
	takeBaseline()
	refresh()
end)

takeBaseline()

pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Armed Deep Probe",
		Text = "Press ARM before playing the emote",
		Duration = 4,
	})
end)

task.spawn(function()
	while g.Parent do
		refresh()
		task.wait(0.2)
	end
end)
