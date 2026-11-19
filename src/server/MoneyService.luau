-- MoneyService ticks every second: each placed brainrot pays its rate, with its
-- mutation and the owner's rebirth multiplier, into the owner's money. It then
-- pushes a fresh state snapshot to every client so the HUD, the shop and the
-- Index always show the truth.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local BrainrotService = require(script.Parent.BrainrotService)

local MoneyService = {}

local remotes = nil
local function getRemotes()
	if not remotes then
		remotes = ReplicatedStorage:WaitForChild("Remotes")
	end
	return remotes
end

function MoneyService.pushState(player)
	local snapshot = DataService.snapshotFor(player)
	if not snapshot then
		return
	end
	snapshot.belt = BrainrotService.listBelt()
	local remote = getRemotes():FindFirstChild("StateUpdate")
	if remote then
		remote:FireClient(player, snapshot)
	end
end

function MoneyService.pushAll()
	for _, player in ipairs(Players:GetPlayers()) do
		MoneyService.pushState(player)
	end
end

function MoneyService.start()
	local timer = 0
	RunService.Heartbeat:Connect(function(dt)
		timer += dt
		if timer < Config.TickInterval then
			return
		end
		timer = 0
		for player, profile in pairs(DataService.allProfiles()) do
			local earned = DataService.totalRate(profile) * Config.TickInterval
			if earned > 0 then
				DataService.addMoney(player, earned)
			end
		end
		MoneyService.pushAll()
	end)
end

return MoneyService
