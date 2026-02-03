--[[
Master Horror Game Script (Single Paste)
Drop this Script into ServerScriptService. It will auto-build the game world,
spawn puzzle pieces, enemies, and manage lives/tries/ending.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- ======= GLOBAL CONFIG =======
local TOTAL_PIECES = 5
local PLAYER_LIVES = 5
local DEMON_TRIES = 3

local WORLD = Instance.new("Folder")
WORLD.Name = "HorrorWorld"
WORLD.Parent = workspace

local function createPart(props)
	local part = Instance.new("Part")
	for k, v in pairs(props) do
		part[k] = v
	end
	return part
end

local function createModel(name, parent)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

local function createRegion(name, pos, size, color)
	local base = createPart({
		Name = name .. "Base",
		Size = size,
		Position = pos,
		Anchored = true,
		Color = color,
		Material = Enum.Material.Slate,
		Parent = WORLD,
	})
	return base
end

local function createPuzzlePiece(name, pos)
	local piece = createPart({
		Name = name,
		Size = Vector3.new(2, 2, 0.5),
		Position = pos,
		Anchored = true,
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(255, 215, 0),
		Parent = WORLD,
	})
	local glow = Instance.new("PointLight")
	glow.Range = 12
	glow.Brightness = 2
	glow.Color = Color3.fromRGB(255, 210, 90)
	glow.Parent = piece
	return piece
end

local function setLightingMood()
	Lighting.Ambient = Color3.fromRGB(50, 50, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 25)
	Lighting.Brightness = 2
	Lighting.FogColor = Color3.fromRGB(20, 20, 30)
	Lighting.FogEnd = 350
	Lighting.FogStart = 50
	Lighting.ClockTime = 1
end

setLightingMood()

-- ======= UI & DATA =======
local function setupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local pieces = Instance.new("IntValue")
	pieces.Name = "PuzzlePieces"
	pieces.Value = 0
	pieces.Parent = leaderstats

	local lives = Instance.new("IntValue")
	lives.Name = "Lives"
	lives.Value = PLAYER_LIVES
	lives.Parent = leaderstats

	local demonTries = Instance.new("IntValue")
	demonTries.Name = "DemonTries"
	demonTries.Value = DEMON_TRIES
	demonTries.Parent = leaderstats

	return leaderstats
end

local function buildStatusGui(player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "HorrorHUD"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local label = Instance.new("TextLabel")
	label.Name = "Status"
	label.Size = UDim2.new(0, 420, 0, 60)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Text = "Collect 5 puzzle pieces. Lives: 5"
	label.Parent = gui

	return label
end

local function updateHud(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	local gui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("HorrorHUD")
	if not gui then return end
	local label = gui:FindFirstChild("Status")
	if not label then return end

	label.Text = string.format(
		"Pieces: %d/%d | Lives: %d | Demon Tries: %d",
		stats.PuzzlePieces.Value,
		TOTAL_PIECES,
		stats.Lives.Value,
		stats.DemonTries.Value
	)
end

local function damagePlayer(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	stats.Lives.Value = math.max(0, stats.Lives.Value - 1)
	updateHud(player)

	local character = player.Character
	if character and character:FindFirstChild("Humanoid") then
		character.Humanoid:TakeDamage(amount)
	end

	if stats.Lives.Value <= 0 then
		if character and character:FindFirstChild("Humanoid") then
			character.Humanoid.Health = 0
		end
	end
end

-- ======= AREAS =======
local forest = createRegion(
	"HauntedForest",
	Vector3.new(0, -5, 0),
	Vector3.new(300, 10, 300),
	Color3.fromRGB(15, 30, 20)
)
local swamp = createRegion(
	"LostSwamp",
	Vector3.new(400, -5, 0),
	Vector3.new(260, 10, 260),
	Color3.fromRGB(30, 45, 20)
)
local volcano = createRegion(
	"VolcanoIsland",
	Vector3.new(900, -5, 0),
	Vector3.new(300, 10, 300),
	Color3.fromRGB(40, 25, 25)
)
local house = createRegion(
	"TrapHouse",
	Vector3.new(0, -5, 400),
	Vector3.new(200, 10, 200),
	Color3.fromRGB(60, 60, 60)
)
local battlefield = createRegion(
	"Battlefield",
	Vector3.new(400, -5, 400),
	Vector3.new(220, 10, 220),
	Color3.fromRGB(40, 40, 50)
)

-- ======= BRIDGE TO VOLCANO =======
local bridge = createModel("BridgePath", WORLD)
for i = 1, 12 do
	local plank = createPart({
		Name = "BridgePlank" .. i,
		Size = Vector3.new(20, 1, 8),
		Position = Vector3.new(600 + i * 20, 5, 0),
		Anchored = true,
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(90, 70, 50),
		Parent = bridge,
	})
end

-- ======= PUZZLE PIECES =======
local forestPiece = createPuzzlePiece("ForestPiece", Vector3.new(-80, 8, -60))
local swampPiece = createPuzzlePiece("SwampPiece", Vector3.new(420, 8, -80))
local volcanoPiece = createPuzzlePiece("VolcanoPiece", Vector3.new(980, 20, 60))
local housePiece = createPuzzlePiece("HousePiece", Vector3.new(-40, 8, 440))
local battlePiece = createPuzzlePiece("BattlePiece", Vector3.new(430, 8, 460))

local puzzlePieces = { forestPiece, swampPiece, volcanoPiece, housePiece, battlePiece }

-- ======= FOREST HUNTERS =======
local forestHunter = createPart({
	Name = "ForestHunter",
	Size = Vector3.new(4, 6, 4),
	Position = Vector3.new(-40, 5, 40),
	Anchored = false,
	Color = Color3.fromRGB(80, 30, 30),
	Material = Enum.Material.Slate,
	Parent = WORLD,
})
local hunterHumanoid = Instance.new("Humanoid")
hunterHumanoid.WalkSpeed = 12
hunterHumanoid.Parent = forestHunter

-- ======= SWAMP SLOW ZONES & MONSTER =======
local slowDebounce = {}
local function createSwampSlowZone(position)
	local zone = createPart({
		Name = "SwampSlow",
		Size = Vector3.new(40, 1, 40),
		Position = position,
		Anchored = true,
		Color = Color3.fromRGB(20, 50, 25),
		Material = Enum.Material.Mud,
		Transparency = 0.2,
		Parent = WORLD,
	})
	zone.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid and not slowDebounce[humanoid] then
			slowDebounce[humanoid] = true
			local originalSpeed = humanoid.WalkSpeed
			humanoid.WalkSpeed = 6
			task.delay(3, function()
				if humanoid then
					humanoid.WalkSpeed = originalSpeed
				end
				slowDebounce[humanoid] = nil
			end)
		end
	end)
end

createSwampSlowZone(Vector3.new(420, 2, 40))
createSwampSlowZone(Vector3.new(460, 2, -20))

local swampMonster = createPart({
	Name = "SwampMonster",
	Size = Vector3.new(6, 8, 6),
	Position = Vector3.new(420, 6, 60),
	Anchored = false,
	Color = Color3.fromRGB(30, 80, 40),
	Material = Enum.Material.Slate,
	Parent = WORLD,
})
local swampHumanoid = Instance.new("Humanoid")
swampHumanoid.WalkSpeed = 10
swampHumanoid.Parent = swampMonster

-- ======= VOLCANO LAVA & OBBY =======
local lava = createPart({
	Name = "Lava",
	Size = Vector3.new(300, 4, 300),
	Position = Vector3.new(900, 1, 0),
	Anchored = true,
	Color = Color3.fromRGB(255, 100, 0),
	Material = Enum.Material.Neon,
	Parent = WORLD,
})

lava.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		damagePlayer(player, 50)
	end
end)

for i = 1, 8 do
	createPart({
		Name = "VolcanoRock" .. i,
		Size = Vector3.new(10, 3, 10),
		Position = Vector3.new(820 + i * 15, 6 + (i % 2) * 3, -40 + i * 8),
		Anchored = true,
		Material = Enum.Material.Rock,
		Color = Color3.fromRGB(70, 70, 70),
		Parent = WORLD,
	})
end

-- ======= TRAP HOUSE =======
local trapHouse = createModel("TrapHouse", WORLD)
for i = 1, 6 do
	createPart({
		Name = "HouseWall" .. i,
		Size = Vector3.new(40, 16, 2),
		Position = Vector3.new(-80 + i * 20, 8, 450),
		Anchored = true,
		Color = Color3.fromRGB(80, 80, 80),
		Material = Enum.Material.Brick,
		Parent = trapHouse,
	})
end

for i = 1, 4 do
	local trap = createPart({
		Name = "HouseTrap" .. i,
		Size = Vector3.new(10, 1, 10),
		Position = Vector3.new(-40 + i * 20, 2, 420 + i * 5),
		Anchored = true,
		Color = Color3.fromRGB(150, 0, 0),
		Material = Enum.Material.Metal,
		Parent = trapHouse,
	})

	trap.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			damagePlayer(player, 25)
		end
	end)
end

-- ======= BATTLEFIELD & DEMON =======
local function createSwordTool()
	local tool = Instance.new("Tool")
	tool.Name = "GhostSlayer"
	tool.RequiresHandle = false
	return tool
end

local demon = createPart({
	Name = "GhostDemon",
	Size = Vector3.new(8, 12, 8),
	Position = Vector3.new(420, 6, 420),
	Anchored = false,
	Color = Color3.fromRGB(120, 0, 140),
	Material = Enum.Material.Neon,
	Parent = WORLD,
})
local demonHumanoid = Instance.new("Humanoid")
demonHumanoid.MaxHealth = 200
demonHumanoid.Health = 200
demonHumanoid.WalkSpeed = 14
demonHumanoid.Parent = demon

local function teleportDemon()
	local positions = {
		Vector3.new(420, 6, 420),
		Vector3.new(460, 6, 470),
		Vector3.new(390, 6, 430),
		Vector3.new(440, 6, 390),
	}
	demon.Position = positions[math.random(1, #positions)]
end

local function demonAttack(player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid:TakeDamage(15)
	end
end

local function demonLoop()
	while demonHumanoid.Health > 0 do
		teleportDemon()
		local closestPlayer
		local closestDist = math.huge
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - demon.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPlayer = player
				end
			end
		end
		if closestPlayer then
			demonAttack(closestPlayer)
		end
		task.wait(4)
	end
end

-- ======= COLLECTING PIECES =======
local function onPieceTouched(piece, player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	if piece:GetAttribute("Collected") then return end

	piece:SetAttribute("Collected", true)
	piece.Transparency = 1
	piece.CanCollide = false
	stats.PuzzlePieces.Value += 1
	updateHud(player)

	if stats.PuzzlePieces.Value >= TOTAL_PIECES then
		local gui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("HorrorHUD")
		if gui then
			gui.Status.Text = "You assembled the puzzle and mastered the horror. Game complete!"
		end
	end
end

for _, piece in ipairs(puzzlePieces) do
	piece.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			onPieceTouched(piece, player)
		end
	end)
end

-- ======= PLAYER SETUP =======
Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)
	local label = buildStatusGui(player)

	player.CharacterAdded:Connect(function(character)
		updateHud(player)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			damagePlayer(player, 0)
		end)
	end)

	label.Text = "Welcome to the Horror Hunt. Collect 5 pieces."
end)

-- ======= SIMPLE AI FOLLOW =======
local function pursueClosest(hunter, speed)
	while true do
		local closestPlayer
		local closestDist = math.huge
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - hunter.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPlayer = player
				end
			end
		end
		if closestPlayer and closestPlayer.Character then
			local hrp = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dir = (hrp.Position - hunter.Position).Unit
				hunter.CFrame = CFrame.new(hunter.Position, hrp.Position)
				hunter.Velocity = dir * speed
				if closestDist < 6 then
					damagePlayer(closestPlayer, 10)
				end
			end
		end
		task.wait(1)
	end
end

-- start AI
spawn(function() pursueClosest(forestHunter, 18) end)
spawn(function() pursueClosest(swampMonster, 14) end)
spawn(demonLoop)

-- give sword in battlefield
battlefield.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		local backpack = player:FindFirstChild("Backpack")
		if backpack and not backpack:FindFirstChild("GhostSlayer") then
			local swordClone = createSwordTool()
			swordClone.Parent = backpack
			swordClone.Activated:Connect(function()
				local character = swordClone.Parent
				local swordPlayer = Players:GetPlayerFromCharacter(character)
				if not swordPlayer or not character:FindFirstChild("HumanoidRootPart") then return end
				if (demon.Position - character.HumanoidRootPart.Position).Magnitude < 12 then
					demonHumanoid:TakeDamage(50)
					if demonHumanoid.Health <= 0 then
						local stats = swordPlayer:FindFirstChild("leaderstats")
						if stats then
							stats.DemonTries.Value = 0
							updateHud(swordPlayer)
						end
					end
				end
			end)
		end
	end
end)

-- demon tries
local function handleDemonTries(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end
	if demonHumanoid.Health > 0 then
		stats.DemonTries.Value = math.max(0, stats.DemonTries.Value - 1)
		updateHud(player)
		if stats.DemonTries.Value <= 0 then
			damagePlayer(player, 100)
		end
	end
end

-- fail a demon try if player dies in battlefield
battlefield.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	local humanoid = hit.Parent:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			handleDemonTries(player)
		end)
	end
end)

print("Master Horror Game loaded.")
