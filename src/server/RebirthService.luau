-- RebirthService trades everything for a permanent boost. A rebirth wipes the
-- player's money and clears their stall, and in return every brainrot they ever
-- own earns more, forever. The cost climbs with each rebirth, so the decision
-- stays interesting all game.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local BrainrotService = require(script.Parent.BrainrotService)

local RebirthService = {}

function RebirthService.tryRebirth(player)
	local profile = DataService.getProfile(player)
	if not profile then
		return
	end
	local cost = DataService.rebirthCost(profile)
	if profile.money < cost then
		BrainrotService.notify(player, "Rebirth costs $" .. tostring(cost) .. ". You have $" .. tostring(profile.money) .. ".")
		return
	end
	-- Clear the stall first, then the money, then grant the rebirth.
	local ownedUids = {}
	for uid in pairs(profile.owned) do
		table.insert(ownedUids, uid)
	end
	for _, uid in ipairs(ownedUids) do
		BrainrotService.removeOwned(player, uid)
	end
	if profile.carried then
		local carried = BrainrotService.getEntry(profile.carried)
		if carried then
			BrainrotService.removeOwned(player, profile.carried)
		end
		profile.carried = nil
	end
	DataService.setMoney(player, 0)
	profile.rebirths += 1
	if profile._rebirthValue then
		profile._rebirthValue.Value = profile.rebirths
	end
	local bonus = math.floor(DataService.earningsMultiplier(profile) * 100 - 100)
	BrainrotService.notify(
		player,
		"REBIRTH " .. tostring(profile.rebirths) .. "! All earnings are now +" .. tostring(bonus) .. "%.",
		true
	)
end

function RebirthService.start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local remote = remotes:WaitForChild("Rebirth")
	remote.OnServerEvent:Connect(function(player)
		RebirthService.tryRebirth(player)
	end)
end

return RebirthService
