-- HazardService runs the Spice Storm, the wave that keeps the market honest.
-- Every hundred seconds it warns the whole server, then a hot wave sweeps the
-- plaza: anyone caught outside their own stall is flung away and drops whatever
-- they are carrying, so a thief mid-dash has to choose between the prize and
-- the run home.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local BrainrotService = require(script.Parent.BrainrotService)

local HazardService = {}

local stormActive = false

local remotes = nil
local function getRemotes()
	if not remotes then
		remotes = ReplicatedStorage:WaitForChild("Remotes")
	end
	return remotes
end

-- Is this player standing on their own stall pad right now?
local function isOnOwnPad(player)
	local profile = DataService.getProfile(player)
	if not profile or not profile.stallId then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local pads = Workspace:FindFirstChild("StallPads")
	if not pads then
		return false
	end
	local pad = pads:FindFirstChild("Pad" .. tostring(profile.stallId))
	if not pad then
		return false
	end
	local pos = root.Position
	local padPos = pad.Position
	local padSize = pad.Size
	return math.abs(pos.X - padPos.X) <= padSize.X / 2
		and math.abs(pos.Z - padPos.Z) <= padSize.Z / 2
end

-- One fling: throw the player up and sideways, and make them drop their catch.
local function flingPlayer(player)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	root.AssemblyLinearVelocity = Vector3.new(math.random(-40, 40), 55, math.random(-40, 40))
	BrainrotService.dropCarried(player)
	BrainrotService.notify(player, "The Spice Storm threw you! Your brainrot scattered!")
end

function HazardService.startStorm()
	if stormActive then
		return
	end
	stormActive = true
	local warning = getRemotes():FindFirstChild("HazardWarning")
	if warning then
		warning:FireAllClients("SPICE STORM INCOMING! Get to your stall!")
	end

	-- A visible wall of spice that sweeps the plaza from one end to the other.
	local wave = Instance.new("Part")
	wave.Name = "SpiceWave"
	wave.Size = Vector3.new(220, 30, 6)
	wave.Color = Color3.fromRGB(255, 90, 30)
	wave.Material = Enum.Material.Neon
	wave.Transparency = 0.45
	wave.Anchored = true
	wave.CanCollide = false
	wave.CFrame = CFrame.new(0, 12, -80)
	wave.Parent = Workspace

	local startTime = os.clock()
	local flung = {}
	local waveConn
	waveConn = RunService.Heartbeat:Connect(function(dt)
		local elapsed = os.clock() - startTime
		if elapsed >= Config.StormDuration then
			waveConn:Disconnect()
			wave:Destroy()
			stormActive = false
			return
		end
		local progress = elapsed / Config.StormDuration
		local z = -80 + progress * 160
		wave.CFrame = CFrame.new(0, 12, z)
		for _, player in ipairs(Players:GetPlayers()) do
			if not flung[player] and not isOnOwnPad(player) then
				flung[player] = true
				flingPlayer(player)
			end
		end
	end)
end

function HazardService.start()
	local timer = Config.StormInterval
	RunService.Heartbeat:Connect(function(dt)
		if stormActive then
			return
		end
		timer -= dt
		if timer <= Config.StormWarning and timer > 0 then
			-- The warning fires once, ten seconds before the storm.
			if not HazardService._warned then
				HazardService._warned = true
				local warning = getRemotes():FindFirstChild("HazardWarning")
				if warning then
					warning:FireAllClients("SPICE STORM IN " .. tostring(Config.StormWarning) .. " SECONDS! Dash home!")
				end
			end
		end
		if timer <= 0 then
			timer = Config.StormInterval
			HazardService._warned = false
			HazardService.startStorm()
		end
	end)
end

return HazardService
