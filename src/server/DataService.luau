-- DataService owns every number that matters: one table per player, and nothing
-- else in the game writes to it. Every other service reads and changes state
-- through this module, so money, brainrots, locks and rebirths can never disagree.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local DataService = {}

-- player -> { money, rebirths, owned = {uid -> owned}, index = {defId -> true},
--   carried = uid or nil, stallId, lockUntil, lockCooldownUntil }
local profiles = {}
-- stallId -> player (or nil when free)
local stallOwners = {}
local nextUid = 1

function DataService.newUid()
	local uid = "b" .. tostring(nextUid)
	nextUid += 1
	return uid
end

function DataService.earningsMultiplier(profile)
	return 1 + Config.RebirthBonusPerRebirth * profile.rebirths
end

function DataService.rateOfOwned(profile, owned)
	local def = BrainrotData.ById[owned.defId]
	if not def then
		return 0
	end
	return BrainrotData.rateOf(def, owned.mutation) * DataService.earningsMultiplier(profile)
end

function DataService.totalRate(profile)
	local total = 0
	for _, owned in pairs(profile.owned) do
		total += DataService.rateOfOwned(profile, owned)
	end
	return total
end

function DataService.claimStall(player)
	for stallId = 1, Config.StallCount do
		if stallOwners[stallId] == nil then
			stallOwners[stallId] = player
			return stallId
		end
	end
	return nil
end

function DataService.freeStall(player)
	local profile = profiles[player]
	if profile and profile.stallId then
		if stallOwners[profile.stallId] == player then
			stallOwners[profile.stallId] = nil
		end
	end
end

function DataService.getProfile(player)
	return profiles[player]
end

function DataService.getStallOwner(stallId)
	return stallOwners[stallId]
end

function DataService.isStallLocked(stallId)
	local owner = stallOwners[stallId]
	if not owner then
		return false
	end
	local profile = profiles[owner]
	if not profile then
		return false
	end
	return os.time() < profile.lockUntil
end

function DataService.createProfile(player)
	local profile = {
		money = Config.StartMoney,
		rebirths = 0,
		owned = {},
		index = {},
		carried = nil,
		stallId = nil,
		lockUntil = 0,
		lockCooldownUntil = 0,
	}
	profile.stallId = DataService.claimStall(player)
	profiles[player] = profile

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local moneyValue = Instance.new("IntValue")
	moneyValue.Name = "Money"
	moneyValue.Value = profile.money
	moneyValue.Parent = leaderstats

	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats

	profile._moneyValue = moneyValue
	profile._rebirthValue = rebirthValue
	return profile
end

function DataService.setMoney(player, amount)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.money = math.max(0, math.floor(amount))
	if profile._moneyValue then
		profile._moneyValue.Value = profile.money
	end
end

function DataService.addMoney(player, amount)
	local profile = profiles[player]
	if not profile then
		return
	end
	DataService.setMoney(player, profile.money + amount)
end

function DataService.removeProfile(player)
	DataService.freeStall(player)
	profiles[player] = nil
end

function DataService.allProfiles()
	return profiles
end

function DataService.rebirthCost(profile)
	return Config.RebirthBaseCost * (profile.rebirths + 1) * (profile.rebirths + 1)
end

function DataService.snapshotFor(player)
	local profile = profiles[player]
	if not profile then
		return nil
	end
	local ownedList = {}
	for uid, owned in pairs(profile.owned) do
		table.insert(ownedList, {
			uid = uid,
			defId = owned.defId,
			mutation = owned.mutation,
			slot = owned.slot,
		})
	end
	table.sort(ownedList, function(a, b)
		return a.slot < b.slot
	end)
	local indexList = {}
	for defId in pairs(profile.index) do
		table.insert(indexList, defId)
	end
	table.sort(indexList)
	return {
		money = profile.money,
		rate = DataService.totalRate(profile),
		rebirths = profile.rebirths,
		rebirthCost = DataService.rebirthCost(profile),
		owned = ownedList,
		index = indexList,
		stallId = profile.stallId,
		locked = os.time() < profile.lockUntil,
		lockReadyAt = profile.lockCooldownUntil,
		carried = profile.carried,
	}
end

Players.PlayerAdded:Connect(function(player)
	DataService.createProfile(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataService.removeProfile(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if not profiles[player] then
		DataService.createProfile(player)
	end
end

return DataService
