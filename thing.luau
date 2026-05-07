local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("DEEP_EMOTE_PROP_PROBE")
if old then
	old:Destroy()
end

local g = Instance.new("ScreenGui")
g.Name = "DEEP_EMOTE_PROP_PROBE"
g.ResetOnSpawn = false
g.Parent = pg

local f = Instance.new("Frame")
f.Parent = g
f.Size = UDim2.new(0, 600, 0, 320)
f.Position = UDim2.new(1, -620, 0, 100)
f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
f.BorderSizePixel = 0

local top = Instance.new("TextButton")
top.Parent = f
top.Size = UDim2.new(1, 0, 0, 28)
top.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
top.BorderSizePixel = 0
top.Text = "DEEP EMOTE PROP PROBE - DRAG"
top.Font = Enum.Font.Code
top.TextSize = 16
top.TextColor3 = Color3.new(1, 1, 1)
top.AutoButtonColor = false

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
txt.Text = "loaded"

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
	sit = true,
	toolnone = true,
	toolslash = true,
	toollunge = true,
	animation1 = true,
	animation2 = true,
	animate = true,
	swimidle = true,
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

local MAX_LOOSE_PROP_DISTANCE = 45
local EMOTE_WINDOW_SECONDS = 2.25

local firstSeenPlaying: {[string]: number} = {}
local currentPlayerEmoteStart = 0

local function normalizeId(id: string): string
	local numeric = string.match(tostring(id), "%d+")
	if numeric then
		return "rbxassetid://" .. numeric
	end

	return string.lower(tostring(id))
end

local function getTrackKey(animator: Animator, track: AnimationTrack): string
	local anim = track.Animation
	local animId = anim and normalizeId(anim.AnimationId or "") or "noid"
	return animator:GetDebugId(0) .. "|" .. animId .. "|" .. tostring(track.Name)
end

local function isDefaultTrack(track: AnimationTrack): boolean
	local trackName = string.lower(track.Name or "")
	if DEFAULT_NAMES[trackName] then
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

local function getCharacter(): Model?
	return plr.Character
end

local function getMainAnimator(): Animator?
	local char = getCharacter()
	if not char then
		return nil
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	return humanoid:FindFirstChildOfClass("Animator")
end

local function getModel(inst: Instance): Model?
	return inst:FindFirstAncestorOfClass("Model")
end

local function getLabel(inst: Instance): string
	local model = getModel(inst)
	if model then
		return model:GetFullName()
	end

	return inst:GetFullName()
end

local function isPlayerCharacterModel(model: Model?): boolean
	if not model then
		return false
	end

	if Players:GetPlayerFromCharacter(model) then
		return true
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if model.Name == player.Name or model.Name == player.DisplayName then
			return true
		end
	end

	return false
end

local function isInsideOtherPlayerCharacter(inst: Instance): boolean
	local char = getCharacter()
	local node: Instance? = inst

	while node and node ~= workspace do
		if node:IsA("Model") and isPlayerCharacterModel(node) then
			return node ~= char
		end

		node = node.Parent
	end

	return false
end

local function isInsideLocalCharacter(inst: Instance): boolean
	local char = getCharacter()
	return char ~= nil and inst:IsDescendantOf(char)
end

local function getPart(value: any): BasePart?
	if typeof(value) == "Instance" and value:IsA("BasePart") then
		return value
	end

	return nil
end

local function jointLinksModelToCharacter(joint: Instance, model: Model, char: Model): boolean
	if not (joint:IsA("Motor6D") or joint:IsA("Weld") or joint:IsA("WeldConstraint")) then
		return false
	end

	local part0 = getPart((joint :: any).Part0)
	local part1 = getPart((joint :: any).Part1)
	if not part0 or not part1 then
		return false
	end

	local p0InChar = part0:IsDescendantOf(char)
	local p1InChar = part1:IsDescendantOf(char)
	local p0InModel = part0:IsDescendantOf(model)
	local p1InModel = part1:IsDescendantOf(model)

	return (p0InChar and p1InModel) or (p1InChar and p0InModel)
end

local function constraintLinksModelToCharacter(constraint: Instance, model: Model, char: Model): boolean
	if not constraint:IsA("Constraint") then
		return false
	end

	local attachment0 = (constraint :: Constraint).Attachment0
	local attachment1 = (constraint :: Constraint).Attachment1
	if not attachment0 or not attachment1 then
		return false
	end

	local part0 = attachment0.Parent
	local part1 = attachment1.Parent
	if not (part0 and part0:IsA("BasePart") and part1 and part1:IsA("BasePart")) then
		return false
	end

	local p0InChar = part0:IsDescendantOf(char)
	local p1InChar = part1:IsDescendantOf(char)
	local p0InModel = part0:IsDescendantOf(model)
	local p1InModel = part1:IsDescendantOf(model)

	return (p0InChar and p1InModel) or (p1InChar and p0InModel)
end

local function modelIsLinkedToCharacter(model: Model?): boolean
	local char = getCharacter()
	if not char or not model or model == char then
		return false
	end

	if model:IsDescendantOf(char) then
		return true
	end

	for _, inst in ipairs(model:GetDescendants()) do
		if jointLinksModelToCharacter(inst, model, char) or constraintLinksModelToCharacter(inst, model, char) then
			return true
		end
	end

	for _, inst in ipairs(char:GetDescendants()) do
		if jointLinksModelToCharacter(inst, model, char) or constraintLinksModelToCharacter(inst, model, char) then
			return true
		end
	end

	return false
end

local function hasLocalOwnerHint(inst: Instance): boolean
	local localName = string.lower(plr.Name)
	local displayName = string.lower(plr.DisplayName)
	local userId = tostring(plr.UserId)

	local node: Instance? = inst
	while node and node ~= workspace do
		local name = string.lower(node.Name)

		if string.find(name, localName, 1, true) or string.find(name, displayName, 1, true) then
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

local function getRootPart(model: Model?): BasePart?
	if not model then
		return nil
	end

	return model.PrimaryPart
		or model:FindFirstChild("HumanoidRootPart") :: BasePart?
		or model:FindFirstChild("RootPart") :: BasePart?
		or model:FindFirstChildWhichIsA("BasePart", true)
end

local function loosePropIsNearCharacter(model: Model?): boolean
	local char = getCharacter()
	if not char or not model then
		return false
	end

	local charRoot = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local propRoot = getRootPart(model)
	if not charRoot or not propRoot then
		return false
	end

	return (charRoot.Position - propRoot.Position).Magnitude <= MAX_LOOSE_PROP_DISTANCE
end

local function hasRecentlyStartedTrack(animator: Animator): boolean
	if currentPlayerEmoteStart <= 0 then
		return false
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if not isDefaultTrack(track) then
			local key = getTrackKey(animator, track)
			local started = firstSeenPlaying[key]

			if started and math.abs(started - currentPlayerEmoteStart) <= EMOTE_WINDOW_SECONDS then
				return true
			end
		end
	end

	return false
end

local function shouldIncludeAnimator(animator: Animator): (boolean, string)
	if isInsideOtherPlayerCharacter(animator) then
		return false, "other-player"
	end

	local mainAnimator = getMainAnimator()
	if animator == mainAnimator then
		return true, "player"
	end

	if isInsideLocalCharacter(animator) then
		return true, "inside-local-character"
	end

	local model = getModel(animator)
	if modelIsLinkedToCharacter(model) then
		return true, "linked"
	end

	if hasLocalOwnerHint(animator) then
		return true, "owner-hint"
	end

	if loosePropIsNearCharacter(model) and hasRecentlyStartedTrack(animator) then
		return true, "near-recent"
	end

	return false, "filtered"
end

local function updateTrackStartTimes()
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("Animator") and not isInsideOtherPlayerCharacter(inst) then
			for _, track in ipairs(inst:GetPlayingAnimationTracks()) do
				if not isDefaultTrack(track) then
					local key = getTrackKey(inst, track)
					if not firstSeenPlaying[key] then
						firstSeenPlaying[key] = os.clock()
					end
				end
			end
		end
	end
end

local function updatePlayerEmoteStart()
	local mainAnimator = getMainAnimator()
	if not mainAnimator then
		return
	end

	for _, track in ipairs(mainAnimator:GetPlayingAnimationTracks()) do
		if not isDefaultTrack(track) then
			local key = getTrackKey(mainAnimator, track)
			local started = firstSeenPlaying[key]
			if started and started > currentPlayerEmoteStart then
				currentPlayerEmoteStart = started
			end
		end
	end
end

local function collectAnimators(): {{ label: string, reason: string, animator: Animator }}
	local found: {{ label: string, reason: string, animator: Animator }} = {}
	local seen: {[Animator]: boolean} = {}

	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("Animator") and not seen[inst] then
			local include, reason = shouldIncludeAnimator(inst)
			if include then
				seen[inst] = true

				table.insert(found, {
					label = getLabel(inst),
					reason = reason,
					animator = inst,
				})
			end
		end
	end

	return found
end

local function getPlayingRows(): {string}
	updateTrackStartTimes()
	updatePlayerEmoteStart()

	local rows: {string} = {}

	for _, info in ipairs(collectAnimators()) do
		for _, track in ipairs(info.animator:GetPlayingAnimationTracks()) do
			if not isDefaultTrack(track) then
				local anim = track.Animation
				local animId = anim and normalizeId(anim.AnimationId or "") or ""

				if animId ~= "" and animId ~= "rbxassetid://0" then
					table.insert(rows, string.format(
						"[%s] (%s)\n%s | %s",
						info.label,
						info.reason,
						animId,
						track.Name or "track"
					))
				end
			end
		end
	end

	return rows
end

local function refresh()
	local rows = getPlayingRows()

	if #rows == 0 then
		txt.Text = "No local/prop non-default animations playing.\n\nStart the probe, then play the emote."
	else
		txt.Text = "LOCAL + PROP NON-DEFAULT ANIMATIONS:\n\n" .. table.concat(rows, "\n\n")
	end
end

plr.CharacterAdded:Connect(function()
	currentPlayerEmoteStart = 0
	table.clear(firstSeenPlaying)

	task.wait(2)
	refresh()
end)

pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Deep Emote Prop Probe",
		Text = "Start this before playing the emote",
		Duration = 4,
	})
end)

task.spawn(function()
	while g.Parent do
		refresh()
		task.wait(0.35)
	end
end)
