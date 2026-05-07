local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("STRICT_EMOTE_PROBE")
if old then
	old:Destroy()
end

local g = Instance.new("ScreenGui")
g.Name = "STRICT_EMOTE_PROBE"
g.ResetOnSpawn = false
g.Parent = pg

local f = Instance.new("Frame")
f.Parent = g
f.Size = UDim2.new(0, 560, 0, 280)
f.Position = UDim2.new(1, -580, 0, 100)
f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
f.BorderSizePixel = 0

local top = Instance.new("TextButton")
top.Parent = f
top.Size = UDim2.new(1, 0, 0, 28)
top.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
top.BorderSizePixel = 0
top.Text = "STRICT ANIMATION PROBE - DRAG"
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

		f.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + d.X,
			startPos.Y.Scale,
			startPos.Y.Offset + d.Y
		)
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
	animation1 = true,
	animation2 = true,
	animate = true,
}

local DEFAULT_IDS = {
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
	["rbxassetid://0"] = true,
}

local function normalizeId(id: string): string
	local numeric = string.match(tostring(id), "%d+")
	if numeric then
		return "rbxassetid://" .. numeric
	end

	return string.lower(tostring(id))
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

		local animId = normalizeId(anim.AnimationId or "")
		if DEFAULT_IDS[animId] then
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

local function isInsideAnyPlayerCharacter(inst: Instance): boolean
	local node: Instance? = inst

	while node and node ~= workspace do
		if node:IsA("Model") and isPlayerCharacterModel(node) then
			return true
		end

		node = node.Parent
	end

	return false
end

local function getPartFromJointSide(value: any): BasePart?
	if typeof(value) == "Instance" and value:IsA("BasePart") then
		return value
	end

	return nil
end

local function jointLinksModelToCharacter(joint: Instance, model: Model, char: Model): boolean
	if not (joint:IsA("Motor6D") or joint:IsA("Weld") or joint:IsA("WeldConstraint")) then
		return false
	end

	local part0 = getPartFromJointSide((joint :: any).Part0)
	local part1 = getPartFromJointSide((joint :: any).Part1)

	if not part0 or not part1 then
		return false
	end

	local p0InChar = part0:IsDescendantOf(char)
	local p1InChar = part1:IsDescendantOf(char)
	local p0InModel = part0:IsDescendantOf(model)
	local p1InModel = part1:IsDescendantOf(model)

	return (p0InChar and p1InModel) or (p1InChar and p0InModel)
end

local function modelIsJointLinkedToCharacter(model: Model?): boolean
	local char = getCharacter()
	if not char or not model or model == char then
		return false
	end

	for _, inst in ipairs(model:GetDescendants()) do
		if jointLinksModelToCharacter(inst, model, char) then
			return true
		end
	end

	for _, inst in ipairs(char:GetDescendants()) do
		if jointLinksModelToCharacter(inst, model, char) then
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

local function shouldIncludeExtraAnimator(animator: Animator): boolean
	if isInsideAnyPlayerCharacter(animator) then
		return false
	end

	local model = getModel(animator)
	if not model then
		return false
	end

	if modelIsJointLinkedToCharacter(model) then
		return true
	end

	if hasLocalOwnerHint(animator) then
		return true
	end

	return false
end

local function collectAnimators(): {{ label: string, animator: Animator }}
	local found: {{ label: string, animator: Animator }} = {}
	local seen: {[Animator]: boolean} = {}

	local mainAnimator = getMainAnimator()
	if mainAnimator then
		seen[mainAnimator] = true

		table.insert(found, {
			label = "PLAYER",
			animator = mainAnimator,
		})
	end

	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("Animator") and not seen[inst] and shouldIncludeExtraAnimator(inst) then
			seen[inst] = true

			table.insert(found, {
				label = getLabel(inst),
				animator = inst,
			})
		end
	end

	return found
end

local function getPlayingRows(): {string}
	local rows: {string} = {}

	for _, info in ipairs(collectAnimators()) do
		for _, track in ipairs(info.animator:GetPlayingAnimationTracks()) do
			if not isDefaultTrack(track) then
				local anim = track.Animation
				local animId = anim and normalizeId(anim.AnimationId or "") or ""

				if animId ~= "" and animId ~= "rbxassetid://0" then
					table.insert(rows, string.format(
						"[%s]\n%s | %s",
						info.label,
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
		txt.Text = "No owned/joint-linked non-default animations playing.\n\nPlay an emote/dance/ability now."
	else
		txt.Text = "OWNED / LINKED NON-DEFAULT ANIMATIONS:\n\n" .. table.concat(rows, "\n\n")
	end
end

plr.CharacterAdded:Connect(function()
	task.wait(2)
	refresh()
end)

pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Strict Animation Probe",
		Text = "Play an emote now",
		Duration = 4,
	})
end)

task.spawn(function()
	while g.Parent do
		refresh()
		task.wait(0.5)
	end
end)
