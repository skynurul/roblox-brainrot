-- Ramen Riot shared tuning: every number the game balances on lives here, in one
-- place, so a single edit retunes the whole game.

local Config = {}

-- Money the player starts with.
Config.StartMoney = 100

-- How often a new brainrot rolls onto the conveyor, in seconds.
Config.ConveyorSpawnInterval = 4
-- How many brainrots parade on the conveyor at once.
Config.ConveyorMax = 8
-- How fast a brainrot travels down the belt, in studs per second.
Config.ConveyorSpeed = 4
-- Where the belt starts and ends on the Z axis.
Config.ConveyorStartZ = -50
Config.ConveyorEndZ = 50

-- How many brainrots one stall can hold.
Config.StallSlots = 6
-- How many stalls the market has.
Config.StallCount = 8

-- Stall lock: how long a lock lasts, and the cooldown after it ends, in seconds.
Config.LockDuration = 60
Config.LockCooldown = 120

-- Spice Storm: seconds between storms, warning seconds before one hits, storm length.
Config.StormInterval = 100
Config.StormWarning = 10
Config.StormDuration = 8

-- Rebirth: base cost, multiplied by (rebirths + 1) squared. Each rebirth adds this
-- fraction to every brainrot's earnings, forever.
Config.RebirthBaseCost = 50000
Config.RebirthBonusPerRebirth = 0.25

-- Chance a spawned brainrot carries a mutation, and the weights of each mutation.
Config.MutationChance = 0.12

-- How often the server ticks earnings and pushes state to clients, in seconds.
Config.TickInterval = 1

return Config
