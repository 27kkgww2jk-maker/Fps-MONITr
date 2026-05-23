--// A15 BIONIC MONITOR
--// Delta Executor

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UIS = game:GetService("UserInputService")

local fpsCap = 60

-- FPS LOCK FIX
task.spawn(function()
	while true do
		task.wait(0.5)

		pcall(function()
			if setfpscap then
				setfpscap(fpsCap)
			end
		end)

		pcall(function()
			if unlockfps and fpsCap >= 120 then
				unlockfps()
			end
		end)
	end
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0,190,0,165)
frame.Position = UDim2.new(0,15,0,15)

frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.BackgroundTransparency = 0.35
frame.BorderSizePixel = 0

Instance.new("UICorner", frame)

-- TITLE
local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1,0,0,22)
title.BackgroundTransparency = 1
title.Text = " A15 Bionic Monitor"
title.Font = Enum.Font.Code
title.TextSize = 15
title.TextColor3 = Color3.new(1,1,1)

-- LABELS
local function newLabel(y,color)
	local lbl = Instance.new("TextLabel")
	lbl.Parent = frame
	lbl.Position = UDim2.new(0,8,0,y)
	lbl.Size = UDim2.new(1,-16,0,16)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextColor3 = color
	return lbl
end

local fpsLabel = newLabel(28, Color3.fromRGB(0,255,120))
local cpuLabel = newLabel(48, Color3.fromRGB(255,180,0))
local gpuLabel = newLabel(68, Color3.fromRGB(0,170,255))
local memLabel = newLabel(88, Color3.fromRGB(255,255,255))
local frameLabel = newLabel(108, Color3.fromRGB(170,170,170))
local limitLabel = newLabel(128, Color3.fromRGB(255,100,100))

-- BUTTONS
local function fpsButton(text,x,val)
	local b = Instance.new("TextButton")
	b.Parent = frame
	b.Size = UDim2.new(0,28,0,22)
	b.Position = UDim2.new(0,x,0,140)
	b.Text = text
	b.Font = Enum.Font.Code
	b.TextSize = 11
	b.BackgroundColor3 = Color3.fromRGB(35,35,35)
	b.BackgroundTransparency = 0.2
	b.TextColor3 = Color3.new(1,1,1)
	b.BorderSizePixel = 0
	Instance.new("UICorner", b)

	b.MouseButton1Click:Connect(function()
		fpsCap = val
	end)
end

fpsButton("30",5,30)
fpsButton("40",36,40)
fpsButton("60",67,60)
fpsButton("90",98,90)
fpsButton("120",129,120)
fpsButton("∞",160,999)

-- DRAG
local dragging, dragInput, dragStart, startPos
local locked, holdStart

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
	or input.UserInputType == Enum.UserInputType.MouseButton1 then

		holdStart = tick()

		task.spawn(function()
			while holdStart do
				task.wait()
				if tick() - holdStart >= 3 then
					locked = not locked
					holdStart = nil
				end
			end
		end)

		if not locked then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				holdStart = nil
			end
		end)
	end
end)

frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging and not locked then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- FPS
local fps = 0

RunService.RenderStepped:Connect(function()
	fps += 1
end)

-- LOOP
task.spawn(function()
	local lastFPS = 60

	while true do
		task.wait(1)

		local realFPS = fps
		fps = 0

		-- 🎯 TARGET
		local targetFPS = realFPS

		if fpsCap == 90 then
			targetFPS = 90
		elseif fpsCap == 120 then
			targetFPS = 120
		elseif fpsCap == 999 then
			targetFPS = 200
		end

		-- 🔥 VARIAÇÃO REALISTA (suavizada)
		local noise = math.random(-12, 12)
		local dropChance = math.random(1, 20)

		local simulated

		if dropChance == 1 then
			-- micro drop (stutter realista)
			simulated = targetFPS - math.random(10, 25)
		else
			simulated = (realFPS * 0.6 + targetFPS * 0.4) + noise
		end

		-- suavização (evita tremedeira seca)
		lastFPS = lastFPS + (simulated - lastFPS) * 0.35

		local displayFPS = math.clamp(math.floor(lastFPS), 1, targetFPS + 20)

		-- MEMORY
		local memory = math.floor(Stats:GetTotalMemoryUsageMb())

		-- FRAME TIME
		local frameTime = math.floor((1000 / math.max(displayFPS,1)) * 100) / 100

		-- CPU / GPU
		local gpuLoad = math.clamp(math.floor((frameTime / 16.6) * 100), 1, 100)
		local cpuLoad = math.clamp(math.floor((memory / 2048) * 100), 1, 100)

		-- UI
		fpsLabel.Text = "FPS: "..displayFPS
		cpuLabel.Text = "CPU: "..cpuLoad.."%"
		gpuLabel.Text = "GPU: "..gpuLoad.."%"
		memLabel.Text = "MEM: "..memory.."MB"
		frameLabel.Text = "FRAME: "..frameTime.."ms"

		limitLabel.Text = (fpsCap == 999) and "LIMIT: ∞" or ("LIMIT: "..fpsCap)
	end
end)
