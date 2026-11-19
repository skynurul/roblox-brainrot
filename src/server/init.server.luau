-- Ramen Riot server entry: creates the RemoteEvents every service shares, then
-- starts each service. State lives in DataService alone; the other services only
-- ever touch it through that module.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- The RemoteEvents the client talks to the server with. Created here so they
-- exist before any service starts listening on them.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

for _, name in ipairs({
	"BuyBrainrot",
	"StealBrainrot",
	"ToggleLock",
	"Rebirth",
	"StateUpdate",
	"Notify",
	"HazardWarning",
}) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end

-- DataService wires PlayerAdded and PlayerRemoving itself when required.
require(script.Parent.DataService)
local BrainrotService = require(script.Parent.BrainrotService)
local MoneyService = require(script.Parent.MoneyService)
local StealService = require(script.Parent.StealService)
local HazardService = require(script.Parent.HazardService)
local RebirthService = require(script.Parent.RebirthService)

-- DataService wires PlayerAdded and PlayerRemoving itself when required.
BrainrotService.start()
MoneyService.start()
StealService.start()
HazardService.start()
RebirthService.start()

print("[Ramen Riot] Server started: conveyor, money, stealing, spice storm and rebirth are live.")
