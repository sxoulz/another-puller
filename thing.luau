local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
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
f.Size = UDim2.new(0, 660, 0, 380)
f.Position = UDim2.new(1, -680, 0, 80)
f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
f.BorderSizePixel = 0

local top = Instance.new("TextButton")
top.Parent = f
top.Size = UDim2.new(1, -164, 0, 28)
top.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
top.BorderSizePixel = 0
top.Text = "ORGANISED ARMED EMOTE PROBE - DRAG"
top.Font = Enum.Font.Code
top.TextSize = 16
top.TextColor3 = Color3.new(1, 1, 1)
top.AutoButtonColor = false

local liveToggle = Instance.new("TextButton")
liveToggle.Parent = f
liveToggle.Position = UDim2.new(1, -160, 0, 0)
liveToggle.Size = UDim2.new(0, 78, 0, 28)
liveToggle.BackgroundColor3 = Color3.fromRGB(35, 95, 55)
liveToggle.BorderSizePixel = 0
liveToggle.Text = "LIVE"
liveToggle.Font = Enum.Font.Code
liveToggle.TextSize = 16
liveToggle.TextColor3 = Color3.new(1, 1, 1)

local arm = Instance.new("TextButton")
arm.Parent = f
arm.Position = UDim2.new(1, -78, 0, 0)
arm.Size = UDim2.new(0, 78, 0, 28)
arm.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
arm.BorderSizePixel = 0
arm.Text = "ARM"
arm.Font = Enum.Font.Code
arm.TextSize = 16
arm.TextColor3 = Color3.new(1, 1, 1)

local scroller = Instance.new("ScrollingFrame")
scroller.Parent = f
scroller.Position = UDim2.new(0, 6, 0, 34)
scroller.Size = UDim2.new(1, -12, 1, -40)
scroller.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
scroller.BorderSizePixel = 0
scroller.ScrollBarThickness = 10
scroller.ScrollingDirection = Enum.ScrollingDirection.Y
scroller.CanvasSize = UDim2.fromOffset(0, 0)
scroller.AutomaticCanvasSize = Enum.AutomaticSize.None
scroller.Active = true

local txt = Instance.new("TextBox")
txt.Parent = scroller
txt.Position = UDim2.fromOffset(8, 8)
txt.Size = UDim2.new(1, -26, 0, 0)
txt.AutomaticSize = Enum.AutomaticSize.Y
txt.BackgroundTransparency = 1
txt.BorderSizePixel = 0
txt.ClearTextOnFocus = false
txt.MultiLine = true
txt.TextEditable = true
txt.TextWrapped = true
txt.Font = Enum.Font.Code
txt.TextSize = 14
txt.TextColor3 = Color3.new(1, 1, 1)
txt.TextXAlignment = Enum.TextXAlignment.Left
txt.TextYAlignment = Enum.TextYAlignment.Top
txt.Text = "Press ARM, then play the emote."

local resizeGrip = Instance.new("TextButton")
resizeGrip.Parent = f
resizeGrip.AnchorPoint = Vector2.new(1, 1)
resizeGrip.Position = UDim2.new(1, 0, 1, 0)
resizeGrip.Size = UDim2.fromOffset(18, 18)
resizeGrip.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
resizeGrip.BorderSizePixel = 0
resizeGrip.Text = "+"
resizeGrip.Font = Enum.Font.Code
resizeGrip.TextSize = 14
resizeGrip.TextColor3 = Color3.fromRGB(220, 220, 220)

local function updateOutputCanvas()
	local width = math.max(1, txt.AbsoluteSize.X)
	local measured = TextService:GetTextSize(txt.Text, txt.TextSize, txt.Font, Vector2.new(width, math.huge))
	local height = math.max(scroller.AbsoluteSize.Y, measured.Y + 20)

	txt.Size = UDim2.new(1, -26, 0, height)
	scroller.CanvasSize = UDim2.fromOffset(0, height + 16)
end

local outputFocused = false
local outputLocked = false
local pendingOutputText: string? = nil
local renderedOutputText = txt.Text

local function updateLiveToggle()
	if outputLocked then
		liveToggle.Text = "PAUSED"
		liveToggle.BackgroundColor3 = Color3.fromRGB(115, 75, 35)
	else
		liveToggle.Text = "LIVE"
		liveToggle.BackgroundColor3 = Color3.fromRGB(35, 95, 55)
	end
end

local function isOutputInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isPointInside(gui: GuiObject, point: Vector2): boolean
	local position = gui.AbsolutePosition
	local size = gui.AbsoluteSize

	return point.X >= position.X
		and point.X <= position.X + size.X
		and point.Y >= position.Y
		and point.Y <= position.Y + size.Y
end

local function scrollOutputBy(deltaY: number)
	local maxY = math.max(0, scroller.CanvasSize.Y.Offset - scroller.AbsoluteSize.Y)
	local y = math.clamp(scroller.CanvasPosition.Y + deltaY, 0, maxY)

	scroller.CanvasPosition = Vector2.new(0, y)
end

local function outputUpdatesPaused(): boolean
	return outputFocused or outputLocked
end

local setOutputText: (string) -> ()

local function setOutputLocked(locked: boolean)
	if outputLocked == locked then
		return
	end

	outputLocked = locked
	updateLiveToggle()
end

local function flushPendingOutput()
	if pendingOutputText then
		local text = pendingOutputText
		pendingOutputText = nil
		setOutputText(text)
	elseif txt.Text ~= renderedOutputText then
		setOutputText(renderedOutputText)
	end
end

setOutputText = function(text: string)
	if outputUpdatesPaused() then
		pendingOutputText = text
		return
	end

	if txt.Text == text then
		updateOutputCanvas()
		return
	end

	txt.Text = text
	renderedOutputText = text
	updateOutputCanvas()
end

txt.Focused:Connect(function()
	outputFocused = true
	setOutputLocked(true)
	pendingOutputText = nil
end)

txt.FocusLost:Connect(function()
	outputFocused = false

	if not outputLocked then
		flushPendingOutput()
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if isOutputInput(input) then
		local inputPosition = Vector2.new(input.Position.X, input.Position.Y)

		if isPointInside(scroller, inputPosition) then
			setOutputLocked(true)
		elseif outputLocked and not isPointInside(f, inputPosition) then
			setOutputLocked(false)

			if not outputFocused then
				flushPendingOutput()
			end
		end
	end
end)

liveToggle.MouseButton1Click:Connect(function()
	if outputLocked then
		outputFocused = false
		setOutputLocked(false)
		flushPendingOutput()
	else
		setOutputLocked(true)
	end
end)

updateLiveToggle()

txt:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateOutputCanvas)
scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateOutputCanvas)
task.defer(updateOutputCanvas)

local dragging = false
local dragStart: Vector3? = nil
local startPos: UDim2? = nil
local resizing = false
local resizeStart: Vector3? = nil
local startSize: UDim2? = nil

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
	elseif resizing and resizeStart and startSize and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - resizeStart
		f.Size = UDim2.new(
			startSize.X.Scale,
			math.max(420, startSize.X.Offset + d.X),
			startSize.Y.Scale,
			math.max(220, startSize.Y.Offset + d.Y)
		)
		updateOutputCanvas()
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		local inputPosition = UserInputService:GetMouseLocation()

		if isPointInside(scroller, inputPosition) then
			scrollOutputBy(-input.Position.Z * 56)
		end
	end
end)

resizeGrip.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true
		resizeStart = input.Position
		startSize = f.Size

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				resizing = false
			end
		end)
	end
end)

local DEFAULT_NAMES = {
	idle = true,
	idleanim = true,
	walk = true,
	walkanim = true,
	run = true,
	runanim = true,
	jump = true,
	jumpanim = true,
	fall = true,
	fallanim = true,
	climb = true,
	climbanim = true,
	swim = true,
	swimanim = true,
	swimidle = true,
	sit = true,
	sitanim = true,
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
local armRound = 0
local baseline: {[string]: boolean} = {}
local captured: {[string]: {
	row: string,
	id: string,
	label: string,
	reason: string,
	trackName: string,
	firstSeen: number,
	lastSeen: number,
	round: number,
}} = {}
local earlyTrackIds: {[AnimationTrack]: string} = {}
local earlyTrackTimes: {[AnimationTrack]: number} = {}
local animatorConnections: {[Animator]: RBXScriptConnection} = {}
local cameraFindings: {[string]: {
	row: string,
	firstSeen: number,
	lastSeen: number,
	round: number,
}} = {}

local function normalizeId(id: string): string
	local numeric = string.match(tostring(id), "%d+")
	if numeric then
		return "rbxassetid://" .. numeric
	end

	return string.lower(tostring(id))
end

local function compactName(name: string): string
	return string.gsub(string.lower(name), "[%s_%-%./]", "")
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
	local visibleId = anim and normalizeId(anim.AnimationId or "") or "noid"
	local attrId = anim and anim:GetAttribute("OriginalAnimationId")
	local id = earlyTrackIds[track] or (typeof(attrId) == "string" and normalizeId(attrId)) or visibleId

	return animator:GetDebugId(0) .. "|" .. id .. "|" .. tostring(track.Name)
end

local function isDefaultName(name: string): boolean
	local n = compactName(name)

	if DEFAULT_NAMES[n] then
		return true
	end

	return n == "walkanimation"
		or n == "runanimation"
		or n == "walking"
		or n == "running"
end

local function isDefaultTrack(track: AnimationTrack): boolean
	if isDefaultName(track.Name or "") then
		return true
	end

	local anim = track.Animation
	if anim then
		if isDefaultName(anim.Name or "") then
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

local function addCameraFinding(key: string, row: string)
	local now = os.clock()
	local existing = cameraFindings[key]

	if existing then
		existing.lastSeen = now
		existing.row = row
	else
		cameraFindings[key] = {
			row = row,
			firstSeen = now,
			lastSeen = now,
			round = armRound,
		}
	end
end

local function getCameraPartFrom(inst: Instance): BasePart?
	local node: Instance? = inst

	while node and node ~= game do
		if node:IsA("BasePart") and node.Name == "Camera" then
			return node
		end

		if node:IsA("Model") then
			local cameraPart = node:FindFirstChild("Camera", true)
			if cameraPart and cameraPart:IsA("BasePart") then
				return cameraPart
			end
		end

		node = node.Parent
	end

	return nil
end

local function describePart(part: BasePart?): string
	return part and part:GetFullName() or "nil"
end

local function addCameraAnimationFinding(animation: Animation, source: string)
	if isInsideOtherPlayer(animation) then
		return
	end

	local id = normalizeId(animation.AnimationId or "")
	if id == "" or id == "rbxassetid://0" or string.find(id, "warning", 1, true) then
		return
	end

	local cameraPart = getCameraPartFrom(animation)
	if not cameraPart and (source ~= "DescendantAdded" or armedAt <= 0 or os.clock() - armedAt > ARM_SECONDS) then
		return
	end

	local cameraInfo = cameraPart and ("CameraPart=" .. cameraPart:GetFullName()) or "transient while armed; not under rig when observed"
	local key = "animation-instance|" .. animation:GetDebugId(0) .. "|" .. id

	addCameraFinding(key, string.format(
		"[%s] Animation instance saw %s\n%s | %s",
		source,
		id,
		animation:GetFullName(),
		cameraInfo
	))
end

local function captureTrackEarly(track: AnimationTrack)
	local anim = track.Animation
	if not anim then
		return
	end

	local id = normalizeId(anim.AnimationId or "")
	if id ~= "" and id ~= "rbxassetid://0" and not string.find(id, "warning", 1, true) then
		earlyTrackIds[track] = id
		earlyTrackTimes[track] = os.clock()

		local cameraPart = getCameraPartFrom(anim)
		if cameraPart then
			addCameraFinding(
				"camera-track|" .. track:GetDebugId(0),
				string.format(
					"[AnimationPlayed] Camera rig track captured\n%s | %s\nCameraPart=%s",
					id,
					track.Name or "track",
					cameraPart:GetFullName()
				)
			)
		end
	end
end

local function watchAnimator(animator: Animator)
	if animatorConnections[animator] then
		return
	end

	animatorConnections[animator] = animator.AnimationPlayed:Connect(function(track)
		captureTrackEarly(track)
	end)

	animator.AncestryChanged:Connect(function(_, parent)
		if not parent and animatorConnections[animator] then
			animatorConnections[animator]:Disconnect()
			animatorConnections[animator] = nil
		end
	end)

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		captureTrackEarly(track)
	end
end

local function watchAllAnimators()
	for _, inst in ipairs(game:GetDescendants()) do
		if inst:IsA("Animator") and not isInsideOtherPlayer(inst) then
			watchAnimator(inst)
		end
	end
end

game.DescendantAdded:Connect(function(inst)
	if inst:IsA("Animator") then
		task.defer(function()
			if inst.Parent and not isInsideOtherPlayer(inst) then
				watchAnimator(inst)
			end
		end)
	elseif inst:IsA("Animation") then
		addCameraAnimationFinding(inst, "DescendantAdded")
	end
end)

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

local function scanCameraRig()
	local currentCamera = Workspace.CurrentCamera

	for _, inst in ipairs(game:GetDescendants()) do
		if not isInsideOtherPlayer(inst) then
			if inst:IsA("Animation") then
				addCameraAnimationFinding(inst, "scan")
			elseif inst:IsA("BasePart") and inst.Name == "Camera" then
				local key = "camera-part|" .. inst:GetDebugId(0)
				local bindInfo = "not matched to CurrentCamera"

				if currentCamera and currentCamera.CameraType == Enum.CameraType.Scriptable then
					local distance = (currentCamera.CFrame.Position - inst.CFrame.Position).Magnitude
					if distance <= 3 then
						bindInfo = "CurrentCamera Scriptable, near this part"
					end
				end

				addCameraFinding(key, string.format(
					"[Camera Part] %s\n%s",
					inst:GetFullName(),
					bindInfo
				))
			elseif inst:IsA("Motor6D") then
				local part0 = inst.Part0
				local part1 = inst.Part1

				if (part0 and part0.Name == "Camera") or (part1 and part1.Name == "Camera") then
					addCameraFinding(
						"camera-joint|" .. inst:GetDebugId(0),
						string.format(
							"[Camera Motor6D] %s\nPart0=%s\nPart1=%s",
							inst:GetFullName(),
							describePart(part0),
							describePart(part1)
						)
					)
				end
			elseif inst:IsA("Weld") or inst:IsA("WeldConstraint") then
				local part0 = getPart((inst :: any).Part0)
				local part1 = getPart((inst :: any).Part1)

				if (part0 and part0.Name == "Camera") or (part1 and part1.Name == "Camera") then
					addCameraFinding(
						"camera-weld|" .. inst:GetDebugId(0),
						string.format(
							"[Camera %s] %s\nPart0=%s\nPart1=%s",
							inst.ClassName,
							inst:GetFullName(),
							describePart(part0),
							describePart(part1)
						)
					)
				end
			elseif inst:IsA("Constraint") then
				local ok0, attachment0 = pcall(function()
					return (inst :: any).Attachment0
				end)
				local ok1, attachment1 = pcall(function()
					return (inst :: any).Attachment1
				end)

				if not ok0 then
					attachment0 = nil
				end

				if not ok1 then
					attachment1 = nil
				end

				local part0 = getPart(attachment0 and attachment0.Parent)
				local part1 = getPart(attachment1 and attachment1.Parent)

				if (part0 and part0.Name == "Camera") or (part1 and part1.Name == "Camera") then
					addCameraFinding(
						"camera-constraint|" .. inst:GetDebugId(0),
						string.format(
							"[Camera %s] %s\nAttachment0=%s\nAttachment1=%s",
							inst.ClassName,
							inst:GetFullName(),
							attachment0 and attachment0:GetFullName() or "nil",
							attachment1 and attachment1:GetFullName() or "nil"
						)
					)
				end
			elseif inst:IsA("Animator") and getCameraPartFrom(inst) then
				for _, track in ipairs(inst:GetPlayingAnimationTracks()) do
					captureTrackEarly(track)
				end
			end
		end
	end
end

local function scan()
	local now = os.clock()

	for _, animator in ipairs(scanAnimators()) do
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			if not isDefaultTrack(track) then
				local anim = track.Animation
				local visibleId = anim and normalizeId(anim.AnimationId or "") or ""
				local attrId = anim and anim:GetAttribute("OriginalAnimationId")
				local id = earlyTrackIds[track] or (typeof(attrId) == "string" and normalizeId(attrId)) or visibleId

				if id ~= "" and id ~= "rbxassetid://0" then
					local key = trackKey(animator, track)
					local ok, reason = shouldCapture(animator, key)

					if ok then
						local label = getLabel(animator)
						local trackName = track.Name or "track"

						if captured[key] then
							captured[key].lastSeen = now
						else
							captured[key] = {
								row = "",
								id = id,
								label = label,
								reason = reason,
								trackName = trackName,
								firstSeen = now,
								lastSeen = now,
								round = armRound,
							}
						end

						captured[key].row = string.format(
							"[%s] (%s)\n%s | %s",
							label,
							reason,
							id,
							trackName
						)
					end
				end
			end
		end
	end
end

local function takeBaseline()
	table.clear(baseline)
	watchAllAnimators()

	for _, animator in ipairs(scanAnimators()) do
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			if not isDefaultTrack(track) then
				baseline[trackKey(animator, track)] = true
			end
		end
	end
end

arm.MouseButton1Click:Connect(function()
	setOutputLocked(false)
	outputFocused = false
	flushPendingOutput()

	armedAt = os.clock()
	armRound += 1
	table.clear(captured)
	table.clear(cameraFindings)
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

local function sortNewestFirst(a, b)
	return a.firstSeen > b.firstSeen
end

local function buildRows()
	local newRows = {}
	local oldRows = {}
	local now = os.clock()

	for _, item in pairs(captured) do
		if item.round == armRound and item.firstSeen >= armedAt then
			table.insert(newRows, item)
		else
			table.insert(oldRows, item)
		end
	end

	table.sort(newRows, sortNewestFirst)
	table.sort(oldRows, sortNewestFirst)

	local lines = {}

	if #newRows > 0 then
		table.insert(lines, "=== NEW THIS ARM ===")
		for _, item in ipairs(newRows) do
			table.insert(lines, string.format("+ %.1fs ago\n%s", now - item.firstSeen, item.row))
		end
	end

	if #oldRows > 0 then
		if #lines > 0 then
			table.insert(lines, "")
		end

		table.insert(lines, "=== STILL PLAYING / PREVIOUSLY CAPTURED ===")
		for _, item in ipairs(oldRows) do
			table.insert(lines, string.format("~ last seen %.1fs ago\n%s", now - item.lastSeen, item.row))
		end
	end

	local rigRows = {}
	for _, item in pairs(cameraFindings) do
		table.insert(rigRows, item)
	end

	table.sort(rigRows, sortNewestFirst)

	if #rigRows > 0 then
		if #lines > 0 then
			table.insert(lines, "")
		end

		table.insert(lines, "=== CAMERA RIG EVIDENCE ===")
		for _, item in ipairs(rigRows) do
			table.insert(lines, string.format("* seen %.1fs ago\n%s", now - item.lastSeen, item.row))
		end
	end

	return lines
end

local function refresh()
	scanCameraRig()
	scan()

	if armedAt > 0 and os.clock() - armedAt > ARM_SECONDS then
		arm.Text = "ARM"
		arm.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	end

	local lines = buildRows()

	if #lines == 0 then
		setOutputText("Press ARM, then play the emote.\n\nNew captures and camera rig evidence will appear separately.")
	else
		setOutputText("CAPTURED LOCAL / PROP ANIMATIONS + CAMERA RIG\n\n" .. table.concat(lines, "\n\n"))
	end
end

plr.CharacterAdded:Connect(function()
	armedAt = 0
	armRound += 1
	table.clear(captured)
	table.clear(cameraFindings)

	task.wait(1)
	takeBaseline()
	refresh()
end)

watchAllAnimators()
takeBaseline()

pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Organised Probe",
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
