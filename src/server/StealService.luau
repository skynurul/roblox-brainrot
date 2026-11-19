-- StealService is the risk in the game: a player can grab a brainrot off a rival's
-- stall and carry it home, unless that stall is locked. A lock lasts a minute and
-- then needs two minutes to cool down, so nobody can hide behind it forever.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local BrainrotService = require(script.Parent.BrainrotService)

local StealService = {}

function StealService.trySteal(player, uid)
	local profile = DataService.getProfile(player)
	if not profile then
		return
	end
	if profile.carried then
		BrainrotService.notify(player, "You are already carrying a brainrot.")
		return
	end
	-- The brainrot table lives in BrainrotService; ask it for the entry.
	local entry = BrainrotService.getEntry(uid)
	if not entry or entry.state ~= "placed" then
		return
	end
	if entry.owner == player then
		BrainrotService.notify(player, "That brainrot is already yours.")
		return
	end
	if not entry.stallId then
		return
	end
	if DataService.isStallLocked(entry.stallId) then
		BrainrotService.notify(player, "That stall is locked! Come back when the lock ends.")
		return
	end
	local victim = entry.owner
	entry.stolenFrom = victim
	entry.state = "carried"
	entry.owner = player
	profile.carried = uid
	BrainrotService.attachCarried(player, entry)
	BrainrotService.notify(player, "You stole " .. entry.def.Name .. "! Run it home before the storm!", true)
	if victim then
		BrainrotService.notify(victim, player.DisplayName .. " is stealing your " .. entry.def.Name .. "!")
	end
end

function StealService.toggleLock(player)
	local profile = DataService.getProfile(player)
	if not profile or not profile.stallId then
		return
	end
	local now = os.time()
	if now < profile.lockUntil then
		BrainrotService.notify(player, "Your stall is already locked.")
		return
	end
	if now < profile.lockCooldownUntil then
		local wait = profile.lockCooldownUntil - now
		BrainrotService.notify(player, "Lock is cooling down. Ready in " .. tostring(wait) .. "s.")
		return
	end
	profile.lockUntil = now + Config.LockDuration
	profile.lockCooldownUntil = profile.lockUntil + Config.LockCooldown
	BrainrotService.notify(player, "Stall locked for " .. tostring(Config.LockDuration) .. " seconds!", true)
end

function StealService.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local stealRemote = remotes:WaitForChild("StealBrainrot")
	stealRemote.OnServerEvent:Connect(function(player, uid)
		StealService.trySteal(player, uid)
	end)
	local lockRemote = remotes:WaitForChild("ToggleLock")
	lockRemote.OnServerEvent:Connect(function(player)
		StealService.toggleLock(player)
	end)
end

return StealService
