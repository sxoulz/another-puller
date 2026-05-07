local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("UNIVERSAL_EMOTE_PROBE")
if old then
	old:Destroy()
end

local g = Instance.new("ScreenGui")
g.Name = "UNIVERSAL_EMOTE_PROBE"
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
top.Text = "UNIVERSAL ANIMATION PROBE - DRAG"
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
}

local function normalizeId(id: string): string
	id = tostring(id)

	local numeric = string.match(id, "%d+")
	if numeric then
		return "rbxassetid://" .. numeric
	end

	return string.lower(id)
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

local function getRootLabel(inst: Instance): string
	local model = inst:FindFirstAncestorOfClass("Model")
	if model then
		return model:GetFullName()
	end

	return inst:GetFullName()
end

local function collectAnimators(): {{ label: string, animator: Animator }}
	local found: {{ label: string, animator: Animator }} = {}
	local seen: {[Animator]: boolean} = {}

	local char = plr.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")

		if animator then
			seen[animator] = true

			table.insert(found, {
				label = "PLAYER",
				animator = animator,
			})
		end
	end

	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("Animator") and not seen[inst] then
			seen[inst] = true

			table.insert(found, {
				label = getRootLabel(inst),
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

				if animId ~= "" then
					local row = string.format(
						"[%s]\n%s | %s",
						info.label,
						animId,
						track.Name or "track"
					)

					table.insert(rows, row)
					print("animation probe", row)
				end
			end
		end
	end

	return rows
end

local function refresh()
	local rows = getPlayingRows()

	if #rows == 0 then
		txt.Text = "No non-default animations playing.\n\nPlay an emote/dance/ability now."
	else
		txt.Text = "NON-DEFAULT PLAYING ANIMATIONS:\n\n" .. table.concat(rows, "\n\n")
	end
end

plr.CharacterAdded:Connect(function()
	task.wait(2)
	refresh()
end)

pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Animation Probe",
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
