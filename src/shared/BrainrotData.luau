-- Ramen Riot cast: 36 original noodle brainrots across 7 rarities, plus 6 mutations.
-- Every name, description and number here is invented for this game. The rarities
-- climb from Common to Divine; a brainrot's price is roughly 12 times its money
-- per second, so rarer ones pay for themselves in about twelve seconds of work.

local BrainrotData = {}

BrainrotData.Rarities = {
	{ Name = "Common", Color = Color3.fromRGB(180, 180, 180), Weight = 40, Chance = 0.40 },
	{ Name = "Rare", Color = Color3.fromRGB(80, 180, 255), Weight = 28, Chance = 0.28 },
	{ Name = "Epic", Color = Color3.fromRGB(170, 90, 255), Weight = 16, Chance = 0.16 },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 190, 40), Weight = 9, Chance = 0.09 },
	{ Name = "Mythic", Color = Color3.fromRGB(255, 80, 200), Weight = 4.5, Chance = 0.045 },
	{ Name = "Secret", Color = Color3.fromRGB(120, 255, 200), Weight = 1.8, Chance = 0.018 },
	{ Name = "Divine", Color = Color3.fromRGB(255, 240, 120), Weight = 0.7, Chance = 0.007 },
}

BrainrotData.RarityByName = {}
for _, rarity in ipairs(BrainrotData.Rarities) do
	BrainrotData.RarityByName[rarity.Name] = rarity
end

-- Mutations multiply a brainrot's earnings. Golden is common; Giant is the rarest.
BrainrotData.Mutations = {
	{ Name = "Golden", Multiplier = 2, Color = Color3.fromRGB(255, 215, 0), Weight = 40 },
	{ Name = "Spicy", Multiplier = 3, Color = Color3.fromRGB(255, 60, 30), Weight = 25 },
	{ Name = "Frozen", Multiplier = 4, Color = Color3.fromRGB(150, 220, 255), Weight = 15 },
	{ Name = "Rainbow", Multiplier = 6, Color = Color3.fromRGB(255, 120, 220), Weight = 10 },
	{ Name = "Shadow", Multiplier = 8, Color = Color3.fromRGB(90, 60, 140), Weight = 6 },
	{ Name = "Giant", Multiplier = 10, Color = Color3.fromRGB(255, 140, 40), Weight = 4 },
}

BrainrotData.MutationByName = {}
for _, mutation in ipairs(BrainrotData.Mutations) do
	BrainrotData.MutationByName[mutation.Name] = mutation
end

-- The cast. Id is the stable key, Rarity is one of the seven names above, Rate is
-- money per second, Price is what the conveyor asks, Body is the model's main
-- colour, and Blurb is the absurd one-liner the Index shows.
BrainrotData.Cast = {
	-- Common
	{ Id = "slurp-cat", Name = "Slurp Cat", Rarity = "Common", Rate = 8, Price = 100, Body = Color3.fromRGB(255, 170, 90), Blurb = "A cat that has slurped noodles nonstop since Tuesday." },
	{ Id = "noodle-pup", Name = "Noodle Pup", Rarity = "Common", Rate = 6, Price = 75, Body = Color3.fromRGB(200, 140, 90), Blurb = "A puppy tangled in spaghetti. It has given up struggling." },
	{ Id = "dumpling-dot", Name = "Dumpling Dot", Rarity = "Common", Rate = 5, Price = 50, Body = Color3.fromRGB(240, 220, 180), Blurb = "A round dumpling that wobbles when you look at it." },
	{ Id = "broth-blob", Name = "Broth Blob", Rarity = "Common", Rate = 7, Price = 90, Body = Color3.fromRGB(190, 130, 60), Blurb = "A blob of broth with eyes. It judges your chopstick skills." },
	{ Id = "chopstick-chick", Name = "Chopstick Chick", Rarity = "Common", Rate = 9, Price = 110, Body = Color3.fromRGB(255, 230, 120), Blurb = "A chick holding chopsticks bigger than itself." },
	{ Id = "egg-sprout", Name = "Egg Sprout", Rarity = "Common", Rate = 12, Price = 150, Body = Color3.fromRGB(255, 245, 200), Blurb = "A soft egg with a sprout. It is growing into a legend." },
	-- Rare
	{ Id = "ramen-ronin", Name = "Ramen Ronin", Rarity = "Rare", Rate = 35, Price = 400, Body = Color3.fromRGB(120, 120, 160), Blurb = "A wandering noodle swordsman with no master and no leftovers." },
	{ Id = "wasabi-whale", Name = "Wasabi Whale", Rarity = "Rare", Rate = 45, Price = 500, Body = Color3.fromRGB(120, 220, 120), Blurb = "A whale that breathes wasabi. The whole market is crying." },
	{ Id = "gyoza-sumo", Name = "Gyoza Sumo", Rarity = "Rare", Rate = 55, Price = 650, Body = Color3.fromRGB(230, 200, 150), Blurb = "A sumo wrestler made of gyoza. Undefeated. Unsteamed." },
	{ Id = "miso-moose", Name = "Miso Moose", Rarity = "Rare", Rate = 40, Price = 450, Body = Color3.fromRGB(150, 100, 60), Blurb = "A moose swimming in miso. It pays rent in antlers." },
	{ Id = "tempura-tiger", Name = "Tempura Tiger", Rarity = "Rare", Rate = 70, Price = 800, Body = Color3.fromRGB(255, 150, 60), Blurb = "A tiger in crispy batter. It crunches when it purrs." },
	{ Id = "boba-bear", Name = "Boba Bear", Rarity = "Rare", Rate = 85, Price = 900, Body = Color3.fromRGB(90, 60, 40), Blurb = "A bear full of boba pearls. It rattles when it walks." },
	-- Epic
	{ Id = "chili-samurai", Name = "Chili Samurai", Rarity = "Epic", Rate = 140, Price = 1500, Body = Color3.fromRGB(220, 40, 40), Blurb = "A samurai in chili armor. One touch and your tongue retires." },
	{ Id = "soba-sensei", Name = "Soba Sensei", Rarity = "Epic", Rate = 180, Price = 2000, Body = Color3.fromRGB(160, 140, 100), Blurb = "A wise old soba master. His advice costs extra." },
	{ Id = "udon-unicorn", Name = "Udon Unicorn", Rarity = "Epic", Rate = 220, Price = 2400, Body = Color3.fromRGB(240, 240, 255), Blurb = "A unicorn with an udon mane. Its horn is a chopstick." },
	{ Id = "kimchi-knight", Name = "Kimchi Knight", Rarity = "Epic", Rate = 160, Price = 1800, Body = Color3.fromRGB(220, 60, 80), Blurb = "A knight in fermented armor. He smells victorious." },
	{ Id = "tofu-titan", Name = "Tofu Titan", Rarity = "Epic", Rate = 260, Price = 2800, Body = Color3.fromRGB(250, 250, 240), Blurb = "A giant block of tofu. It has never been seasoned. It does not care." },
	{ Id = "sake-snake", Name = "Sake Snake", Rarity = "Epic", Rate = 320, Price = 3400, Body = Color3.fromRGB(140, 220, 180), Blurb = "A snake that pours sake. Do not let it near the broth." },
	-- Legendary
	{ Id = "golden-gyoza", Name = "Golden Gyoza", Rarity = "Legendary", Rate = 500, Price = 6000, Body = Color3.fromRGB(255, 215, 0), Blurb = "A gyoza made of solid gold. It folds itself." },
	{ Id = "dragon-noodle", Name = "Dragon Noodle", Rarity = "Legendary", Rate = 800, Price = 10000, Body = Color3.fromRGB(200, 40, 40), Blurb = "A dragon made of noodles. It breathes steam." },
	{ Id = "phoenix-ramen", Name = "Phoenix Ramen", Rarity = "Legendary", Rate = 1000, Price = 12000, Body = Color3.fromRGB(255, 120, 40), Blurb = "A phoenix that rises from the broth, every single morning." },
	{ Id = "samurai-soba", Name = "Samurai Soba", Rarity = "Legendary", Rate = 650, Price = 8000, Body = Color3.fromRGB(90, 90, 130), Blurb = "The greatest soba warrior. He has never dropped a noodle." },
	{ Id = "emperor-egg", Name = "Emperor Egg", Rarity = "Legendary", Rate = 1200, Price = 15000, Body = Color3.fromRGB(255, 240, 160), Blurb = "An egg wearing a crown. It rules the breakfast table." },
	-- Mythic
	{ Id = "void-miso", Name = "Void Miso", Rarity = "Mythic", Rate = 1800, Price = 22000, Body = Color3.fromRGB(60, 40, 90), Blurb = "Miso from the void. It stares back." },
	{ Id = "celestial-chopstick", Name = "Celestial Chopstick", Rarity = "Mythic", Rate = 2500, Price = 30000, Body = Color3.fromRGB(180, 200, 255), Blurb = "A chopstick that fell from the stars. It picks up everything." },
	{ Id = "moonlight-miso", Name = "Moonlight Miso", Rarity = "Mythic", Rate = 2000, Price = 25000, Body = Color3.fromRGB(200, 200, 240), Blurb = "Miso that only glows at night. It hums lullabies." },
	{ Id = "star-broth", Name = "Star Broth", Rarity = "Mythic", Rate = 3500, Price = 42000, Body = Color3.fromRGB(255, 220, 120), Blurb = "Broth made of stars. One sip and you see tomorrow." },
	{ Id = "nebula-noodle", Name = "Nebula Noodle", Rarity = "Mythic", Rate = 5000, Price = 60000, Body = Color3.fromRGB(140, 80, 200), Blurb = "A noodle nebula. It contains three galaxies and a meatball." },
	-- Secret
	{ Id = "ghost-ramen", Name = "Ghost Ramen", Rarity = "Secret", Rate = 7000, Price = 85000, Body = Color3.fromRGB(220, 240, 255), Blurb = "A ramen that haunts the market. It slurps itself." },
	{ Id = "shadow-soba", Name = "Shadow Soba", Rarity = "Secret", Rate = 9000, Price = 110000, Body = Color3.fromRGB(50, 50, 70), Blurb = "Soba that moves only in shadows. Nobody has seen it eat." },
	{ Id = "phantom-pho", Name = "Phantom Pho", Rarity = "Secret", Rate = 12000, Price = 150000, Body = Color3.fromRGB(200, 255, 230), Blurb = "A pho that appears and vanishes. The bowl is always empty." },
	{ Id = "invisible-udon", Name = "Invisible Udon", Rarity = "Secret", Rate = 15000, Price = 180000, Body = Color3.fromRGB(240, 240, 240), Blurb = "Udon you can barely see. You can definitely hear it." },
	-- Divine
	{ Id = "god-of-broth", Name = "God of Broth", Rarity = "Divine", Rate = 25000, Price = 300000, Body = Color3.fromRGB(255, 230, 100), Blurb = "The god of all broth. Every soup answers to it." },
	{ Id = "ramen-deity", Name = "Ramen Deity", Rarity = "Divine", Rate = 35000, Price = 420000, Body = Color3.fromRGB(255, 200, 60), Blurb = "The deity of ramen. It invented the slurp." },
	{ Id = "noodle-nirvana", Name = "Noodle Nirvana", Rarity = "Divine", Rate = 45000, Price = 550000, Body = Color3.fromRGB(255, 255, 220), Blurb = "Enlightenment in noodle form. It has no price, but here we are." },
	{ Id = "the-last-slurp", Name = "The Last Slurp", Rarity = "Divine", Rate = 50000, Price = 600000, Body = Color3.fromRGB(255, 255, 255), Blurb = "The final slurp of the universe. After it, only silence." },
}

BrainrotData.ById = {}
for _, def in ipairs(BrainrotData.Cast) do
	BrainrotData.ById[def.Id] = def
end

-- Roll one rarity name by its weight.
function BrainrotData.rollRarity()
	local total = 0
	for _, rarity in ipairs(BrainrotData.Rarities) do
		total += rarity.Weight
	end
	local roll = math.random() * total
	for _, rarity in ipairs(BrainrotData.Rarities) do
		roll -= rarity.Weight
		if roll <= 0 then
			return rarity.Name
		end
	end
	return "Common"
end

-- Pick one brainrot definition of the given rarity.
function BrainrotData.pickOfRarity(rarityName)
	local pool = {}
	for _, def in ipairs(BrainrotData.Cast) do
		if def.Rarity == rarityName then
			table.insert(pool, def)
		end
	end
	return pool[math.random(1, #pool)]
end

-- Roll a mutation name, or nil when the roll misses.
function BrainrotData.rollMutation()
	if math.random() > 0.12 then
		return nil
	end
	local total = 0
	for _, mutation in ipairs(BrainrotData.Mutations) do
		total += mutation.Weight
	end
	local roll = math.random() * total
	for _, mutation in ipairs(BrainrotData.Mutations) do
		roll -= mutation.Weight
		if roll <= 0 then
			return mutation.Name
		end
	end
	return nil
end

-- The money a brainrot earns per second, with its mutation applied.
function BrainrotData.rateOf(def, mutationName)
	local rate = def.Rate
	if mutationName then
		local mutation = BrainrotData.MutationByName[mutationName]
		if mutation then
			rate *= mutation.Multiplier
		end
	end
	return rate
end

return BrainrotData
