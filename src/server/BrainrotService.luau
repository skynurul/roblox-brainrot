-- BrainrotService runs the conveyor and the whole buy, carry and place loop.
-- Brainrots parade down the belt; a player buys one, carries it home, and steps
-- on their stall pad to place it, where it starts earning. A brainrot dropped
-- mid-carry becomes loose on the ground and anyone can pick it up.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local DataService = require(script.Parent.DataService)

local BrainrotService = {}

-- uid -> { def, mutation, model, state = "belt" | "carried" | "placed" | "loose",
--   owner = player or nil, stallId, slot, z }
local brainrots = {}
-- The folder that holds every brainrot model in the world.
local brainrotFolder = Instance.new("Folder")
brainrotFolder.Name = "Brainrots"
brainrotFolder.Parent = Workspace

local remotes = nil
local function getRemotes()
	if not remotes then
		remotes = ReplicatedStorage:WaitForChild("Remotes")
	end
	return remotes
end

function BrainrotService.notify(player, text, good)
	local remote = getRemotes():FindFirstChild("Notify")
	if remote then
		remote:FireClient(player, text, good == true)
	end
end

-- Build the little 3D model for one brainrot: a body, a head, a topper, and a
-- label that reads its name, rarity and money per second.
function BrainrotService.buildModel(def, mutationName)
	local rarity = BrainrotData.RarityByName[def.Rarity]
	local bodyColor = def.Body
	if mutationName then
		local mutation = BrainrotData.MutationByName[mutationName]
		if mutation then
			bodyColor = mutation.Color
		end
	end

	local model = Instance.new("Model")
	model.Name = def.Name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(3, 3, 3)
	body.Color = bodyColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Color = Color3.fromRGB(255, 240, 210)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 2.2, 0)
	head.Parent = model

	local topper = Instance.new("Part")
	topper.Name = "Topper"
	topper.Size = Vector3.new(1.4, 0.6, 1.4)
	topper.Color = rarity.Color
	topper.Material = Enum.Material.Neon
	topper.Anchored = true
	topper.CanCollide = false
	topper.Position = Vector3.new(0, 3.6, 0)
	topper.Parent = model

	local label = Instance.new("BillboardGui")
	label.Name = "Label"
	label.Size = UDim2.new(0, 140, 0, 56)
	label.StudsOffset = Vector3.new(0, 5, 0)
	label.AlwaysOnTop = true
	label.Parent = body

	local nameText = Instance.new("TextLabel")
	nameText.Name = "Name"
	nameText.Size = UDim2.new(1, 0, 0.4, 0)
	nameText.BackgroundTransparency = 1
	nameText.Text = def.Name
	nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameText.TextScaled = true
	nameText.Font = Enum.Font.GothamBold
	nameText.Parent = label

	local rarityText = Instance.new("TextLabel")
	rarityText.Name = "Rarity"
	rarityText.Position = UDim2.new(0, 0, 0.4, 0)
	rarityText.Size = UDim2.new(1, 0, 0.3, 0)
	rarityText.BackgroundTransparency = 1
	rarityText.Text = def.Rarity .. (mutationName and (" " .. mutationName) or "")
	rarityText.TextColor3 = rarity.Color
	rarityText.TextScaled = true
	rarityText.Font = Enum.Font.GothamBold
	rarityText.Parent = label

	local rateText = Instance.new("TextLabel")
	rateText.Name = "Rate"
	rateText.Position = UDim2.new(0, 0, 0.7, 0)
	rateText.Size = UDim2.new(1, 0, 0.3, 0)
	rateText.BackgroundTransparency = 1
	rateText.Text = "$" .. tostring(BrainrotData.rateOf(def, mutationName)) .. "/s"
	rateText.TextColor3 = Color3.fromRGB(120, 255, 140)
	rateText.TextScaled = true
	rateText.Font = Enum.Font.GothamBold
	rateText.Parent = label

	model.PrimaryPart = body
	return model
end

-- Where a placed brainrot sits on its stall: slot 1 to 6 across the counter.
local function slotPosition(stallId, slot)
	local stalls = Workspace:FindFirstChild("Stalls")
	if not stalls then
		return Vector3.new(0, 3, 0)
	end
	local stall = stalls:FindFirstChild("Stall" .. tostring(stallId))
	if not stall then
		return Vector3.new(0, 3, 0)
	end
	local counter = stall:FindFirstChild("Counter")
	if not counter then
		return Vector3.new(0, 3, 0)
	end
	local base = counter.Position
	local across = (slot - 1) % 3
	local row = math.floor((slot - 1) / 3)
	return Vector3.new(base.X, base.Y + 2.2, base.Z - 2.4 + across * 2.4 + row * 0)
end

function BrainrotService.spawnOnBelt()
	local count = 0
	for _, entry in pairs(brainrots) do
		if entry.state == "belt" then
			count += 1
		end
	end
	if count >= Config.ConveyorMax then
		return
	end
	local def = BrainrotData.pickOfRarity(BrainrotData.rollRarity())
	local mutation = BrainrotData.rollMutation()
	local uid = DataService.newUid()
	local model = BrainrotService.buildModel(def, mutation)
	model.Parent = brainrotFolder
	model:PivotTo(CFrame.new(0, 2.5, Config.ConveyorStartZ))

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 32
	click.Parent = model.PrimaryPart
	local clickConn = click.MouseClick:Connect(function(player)
		BrainrotService.tryBuy(player, uid)
	end)

	brainrots[uid] = {
		def = def,
		mutation = mutation,
		model = model,
		state = "belt",
		owner = nil,
		stallId = nil,
		slot = nil,
		z = Config.ConveyorStartZ,
		clickConn = clickConn,
	}
end

-- Move every belt brainrot one step down the conveyor, and despawn the ones
-- that roll off the end.
function BrainrotService.stepBelt(dt)
	for uid, entry in pairs(brainrots) do
		if entry.state == "belt" then
			entry.z += Config.ConveyorSpeed * dt
			if entry.z >= Config.ConveyorEndZ then
				entry.model:Destroy()
				brainrots[uid] = nil
			else
				entry.model:PivotTo(CFrame.new(0, 2.5, entry.z))
			end
		end
	end
end

function BrainrotService.tryBuy(player, uid)
	local profile = DataService.getProfile(player)
	if not profile then
		return
	end
	local entry = brainrots[uid]
	if not entry or entry.state ~= "belt" then
		BrainrotService.notify(player, "That brainrot is already gone.")
		return
	end
	if profile.carried then
		BrainrotService.notify(player, "You are already carrying a brainrot. Place it first.")
		return
	end
	if profile.money < entry.def.Price then
		BrainrotService.notify(player, "Not enough money for " .. entry.def.Name .. " ($" .. tostring(entry.def.Price) .. ").")
		return
	end
	DataService.setMoney(player, profile.money - entry.def.Price)
	profile.carried = uid
	entry.state = "carried"
	entry.owner = player
	BrainrotService.attachCarried(player, entry)
	BrainrotService.notify(player, "You bought " .. entry.def.Name .. "! Carry it to your stall.", true)
end

-- Weld the brainrot above the buyer's head while they carry it.
function BrainrotService.attachCarried(player, entry)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local model = entry.model
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
		end
	end
	model:PivotTo(root.CFrame * CFrame.new(0, 4, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	entry.weld = weld
end

function BrainrotService.detachCarried(entry)
	if entry.weld then
		entry.weld:Destroy()
		entry.weld = nil
	end
	for _, part in ipairs(entry.model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
end

-- Put a carried brainrot into the next free slot of the carrier's stall.
function BrainrotService.placeCarried(player)
	local profile = DataService.getProfile(player)
	if not profile or not profile.carried then
		return
	end
	local uid = profile.carried
	local entry = brainrots[uid]
	if not entry or entry.state ~= "carried" then
		profile.carried = nil
		return
	end
	if not profile.stallId then
		BrainrotService.notify(player, "You have no stall yet.")
		return
	end
	local taken = {}
	for _, owned in pairs(profile.owned) do
		taken[owned.slot] = true
	end
	local slot = nil
	for i = 1, Config.StallSlots do
		if not taken[i] then
			slot = i
			break
		end
	end
	if not slot then
		BrainrotService.notify(player, "Your stall is full! Sell or rebirth to make room.")
		return
	end
	BrainrotService.detachCarried(entry)
	entry.state = "placed"
	entry.owner = player
	entry.stallId = profile.stallId
	entry.slot = slot
	profile.owned[uid] = { defId = entry.def.Id, mutation = entry.mutation, slot = slot }
	profile.index[entry.def.Id] = true
	profile.carried = nil
	local spot = slotPosition(profile.stallId, slot)
	entry.model:PivotTo(CFrame.new(spot))
	local click = entry.model.PrimaryPart:FindFirstChildOfClass("ClickDetector")
	if not click then
		click = Instance.new("ClickDetector")
		click.MaxActivationDistance = 32
		click.Parent = entry.model.PrimaryPart
	end
	if entry.clickConn then
		entry.clickConn:Disconnect()
	end
	entry.clickConn = click.MouseClick:Connect(function(clicker)
		local StealService = require(script.Parent.StealService)
		StealService.trySteal(clicker, uid)
	end)
	BrainrotService.notify(player, entry.def.Name .. " is on your stall, earning $" .. tostring(BrainrotData.rateOf(entry.def, entry.mutation)) .. "/s!", true)
end

-- Drop a carried brainrot on the ground where its carrier stands. Anyone can
-- pick a loose one up by clicking it.
function BrainrotService.dropCarried(player)
	local profile = DataService.getProfile(player)
	if not profile or not profile.carried then
		return
	end
	local uid = profile.carried
	local entry = brainrots[uid]
	profile.carried = nil
	if not entry then
		return
	end
	BrainrotService.detachCarried(entry)
	entry.state = "loose"
	entry.owner = nil
	local character = player.Character
	local at = Vector3.new(0, 2.5, 0)
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			at = root.Position + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4))
			at = Vector3.new(at.X, 2.5, at.Z)
		end
	end
	entry.model:PivotTo(CFrame.new(at))
	local click = entry.model.PrimaryPart:FindFirstChildOfClass("ClickDetector")
	if not click then
		click = Instance.new("ClickDetector")
		click.MaxActivationDistance = 32
		click.Parent = entry.model.PrimaryPart
	end
	if entry.clickConn then
		entry.clickConn:Disconnect()
	end
	entry.clickConn = click.MouseClick:Connect(function(clicker)
		BrainrotService.tryPickupLoose(clicker, uid)
	end)
	BrainrotService.notify(player, "You dropped " .. entry.def.Name .. "!")
end

function BrainrotService.tryPickupLoose(player, uid)
	local profile = DataService.getProfile(player)
	if not profile then
		return
	end
	local entry = brainrots[uid]
	if not entry or entry.state ~= "loose" then
		return
	end
	if profile.carried then
		BrainrotService.notify(player, "You are already carrying a brainrot.")
		return
	end
	profile.carried = uid
	entry.state = "carried"
	entry.owner = player
	BrainrotService.attachCarried(player, entry)
	BrainrotService.notify(player, "You picked up " .. entry.def.Name .. "! Take it to your stall.", true)
end

-- StealService calls this when a stolen brainrot reaches the thief's stall.
function BrainrotService.placeStolen(player, uid)
	local profile = DataService.getProfile(player)
	if not profile or not profile.carried or profile.carried ~= uid then
		return
	end
	local entry = brainrots[uid]
	if not entry then
		return
	end
	local victim = entry.stolenFrom
	entry.stolenFrom = nil
	BrainrotService.placeCarried(player)
	if victim and victim ~= player then
		local oldProfile = DataService.getProfile(victim)
		if oldProfile then
			oldProfile.owned[uid] = nil
			BrainrotService.notify(victim, player.DisplayName .. " stole your " .. entry.def.Name .. "!")
		end
	end
end

function BrainrotService.removeOwned(player, uid)
	local entry = brainrots[uid]
	if entry then
		if entry.model then
			entry.model:Destroy()
		end
		brainrots[uid] = nil
	end
	local profile = DataService.getProfile(player)
	if profile then
		profile.owned[uid] = nil
		if profile.carried == uid then
			profile.carried = nil
		end
	end
end

function BrainrotService.getEntry(uid)
	return brainrots[uid]
end

function BrainrotService.listBelt()
	local list = {}
	for uid, entry in pairs(brainrots) do
		if entry.state == "belt" then
			table.insert(list, {
				uid = uid,
				defId = entry.def.Id,
				name = entry.def.Name,
				rarity = entry.def.Rarity,
				mutation = entry.mutation,
				rate = BrainrotData.rateOf(entry.def, entry.mutation),
				price = entry.def.Price,
			})
		end
	end
	table.sort(list, function(a, b)
		return a.price < b.price
	end)
	return list
end

function BrainrotService.start()
	local spawnTimer = 0
	RunService.Heartbeat:Connect(function(dt)
		BrainrotService.stepBelt(dt)
		spawnTimer += dt
		if spawnTimer >= Config.ConveyorSpawnInterval then
			spawnTimer = 0
			BrainrotService.spawnOnBelt()
		end
	end)

	-- Place a carried brainrot the moment its carrier steps on their own pad.
	local pads = Workspace:FindFirstChild("StallPads")
	if pads then
		for _, pad in ipairs(pads:GetChildren()) do
			if pad:IsA("BasePart") then
				pad.Touched:Connect(function(hit)
					local character = hit.Parent
					if not character then
						return
					end
					local player = Players:GetPlayerFromCharacter(character)
					if not player then
						return
					end
					local profile = DataService.getProfile(player)
					if not profile or not profile.carried then
						return
					end
					local padStallId = tonumber(string.sub(pad.Name, 4))
					if padStallId ~= profile.stallId then
						return
					end
					local entry = brainrots[profile.carried]
					if entry and entry.state == "carried" then
						BrainrotService.placeCarried(player)
					end
				end)
			end
		end
	end

	local remote = getRemotes():WaitForChild("BuyBrainrot")
	remote.OnServerEvent:Connect(function(player, uid)
		BrainrotService.tryBuy(player, uid)
	end)
end

return BrainrotService
