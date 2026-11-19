-- Ramen Riot client: the whole interface over the 3D world. The server owns all
-- state; this script only draws it. It builds one ScreenGui with a top bar for
-- money, a shop that lists the brainrots on the conveyor, an Index book of all
-- 36 brainrots, stall lock and rebirth buttons, a hazard banner and toasts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyRemote = remotes:WaitForChild("BuyBrainrot")
local lockRemote = remotes:WaitForChild("ToggleLock")
local rebirthRemote = remotes:WaitForChild("Rebirth")
local stateRemote = remotes:WaitForChild("StateUpdate")
local notifyRemote = remotes:WaitForChild("Notify")
local hazardRemote = remotes:WaitForChild("HazardWarning")

-- The latest snapshot the server sent. Every panel redraws from this one table.
local state = {
	money = 0,
	rate = 0,
	rebirths = 0,
	rebirthCost = 0,
	owned = {},
	index = {},
	stallId = nil,
	locked = false,
	lockReadyAt = 0,
	carried = nil,
	belt = {},
}
local ownedSet = {}
local indexSet = {}

local function formatMoney(amount)
	if amount >= 1000000 then
		return "$" .. string.format("%.2fM", amount / 1000000)
	elseif amount >= 1000 then
		return "$" .. string.format("%.1fK", amount / 1000)
	else
		return "$" .. tostring(math.floor(amount))
	end
end

-- Build the interface.
local gui = Instance.new("ScreenGui")
gui.Name = "RamenRiotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function makeLabel(parent, name, text, size, pos, color, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = pos
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, pos, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = pos
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

-- Top bar: money, earnings, rebirths, stall.
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 12)
topBar.Size = UDim2.new(0, 560, 0, 48)
topBar.BackgroundColor3 = Color3.fromRGB(30, 20, 25)
topBar.BackgroundTransparency = 0.25
topBar.BorderSizePixel = 0
topBar.Parent = gui
local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 10)
topCorner.Parent = topBar

local moneyLabel = makeLabel(topBar, "Money", "$0", UDim2.new(0, 150, 1, 0), UDim2.new(0, 16, 0, 0), Color3.fromRGB(120, 255, 140), 24)
local rateLabel = makeLabel(topBar, "Rate", "$0/s", UDim2.new(0, 130, 1, 0), UDim2.new(0, 170, 0, 0), Color3.fromRGB(255, 220, 120), 20)
local rebirthLabel = makeLabel(topBar, "Rebirths", "Rebirth x0", UDim2.new(0, 120, 1, 0), UDim2.new(0, 300, 0, 0), Color3.fromRGB(200, 160, 255), 20)
local stallLabel = makeLabel(topBar, "Stall", "Stall -", UDim2.new(0, 120, 1, 0), UDim2.new(0, 430, 0, 0), Color3.fromRGB(255, 255, 255), 20)

-- Hazard banner, hidden until a storm comes.
local hazardBanner = Instance.new("TextLabel")
hazardBanner.Name = "HazardBanner"
hazardBanner.AnchorPoint = Vector2.new(0.5, 0)
hazardBanner.Position = UDim2.new(0.5, 0, 0, 70)
hazardBanner.Size = UDim2.new(0, 520, 0, 44)
hazardBanner.BackgroundColor3 = Color3.fromRGB(200, 40, 20)
hazardBanner.BackgroundTransparency = 0.15
hazardBanner.BorderSizePixel = 0
hazardBanner.Text = ""
hazardBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
hazardBanner.TextSize = 22
hazardBanner.Font = Enum.Font.GothamBold
hazardBanner.Visible = false
hazardBanner.Parent = gui
local hazardCorner = Instance.new("UICorner")
hazardCorner.CornerRadius = UDim.new(0, 10)
hazardCorner.Parent = hazardBanner

-- Buttons along the bottom right.
local lockButton = makeButton(gui, "LockButton", "Lock Stall", UDim2.new(0, 150, 0, 44), UDim2.new(1, -170, 1, -110), Color3.fromRGB(60, 90, 200))
local rebirthButton = makeButton(gui, "RebirthButton", "Rebirth", UDim2.new(0, 150, 0, 44), UDim2.new(1, -170, 1, -60), Color3.fromRGB(140, 60, 200))
local shopButton = makeButton(gui, "ShopButton", "Shop", UDim2.new(0, 150, 0, 44), UDim2.new(1, -340, 1, -110), Color3.fromRGB(200, 120, 30))
local indexButton = makeButton(gui, "IndexButton", "Index 0/36", UDim2.new(0, 150, 0, 44), UDim2.new(1, -340, 1, -60), Color3.fromRGB(40, 140, 90))

-- Shop panel: the brainrots parading on the conveyor right now.
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
shopPanel.Size = UDim2.new(0, 460, 0, 420)
shopPanel.BackgroundColor3 = Color3.fromRGB(25, 18, 22)
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.Parent = gui
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shopPanel

makeLabel(shopPanel, "Title", "CONVEYOR SHOP - click a brainrot in the world or buy here", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 8), Color3.fromRGB(255, 220, 120), 16)
local shopClose = makeButton(shopPanel, "Close", "X", UDim2.new(0, 32, 0, 32), UDim2.new(1, -42, 0, 8), Color3.fromRGB(180, 40, 40))
local shopList = Instance.new("ScrollingFrame")
shopList.Name = "List"
shopList.Position = UDim2.new(0, 10, 0, 48)
shopList.Size = UDim2.new(1, -20, 1, -58)
shopList.BackgroundTransparency = 1
shopList.BorderSizePixel = 0
shopList.ScrollBarThickness = 6
shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopList.Parent = shopPanel
local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 6)
shopLayout.Parent = shopList

-- Index panel: all 36 brainrots, owned ones lit up.
local indexPanel = Instance.new("Frame")
indexPanel.Name = "IndexPanel"
indexPanel.AnchorPoint = Vector2.new(0.5, 0.5)
indexPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
indexPanel.Size = UDim2.new(0, 520, 0, 440)
indexPanel.BackgroundColor3 = Color3.fromRGB(25, 18, 22)
indexPanel.BorderSizePixel = 0
indexPanel.Visible = false
indexPanel.Parent = gui
local indexCorner = Instance.new("UICorner")
indexCorner.CornerRadius = UDim.new(0, 12)
indexCorner.Parent = indexPanel

makeLabel(indexPanel, "Title", "RAMEN INDEX - collect all 36!", UDim2.new(1, -20, 0, 30), UDim2.new(0, 10, 0, 8), Color3.fromRGB(120, 255, 200), 18)
local indexClose = makeButton(indexPanel, "Close", "X", UDim2.new(0, 32, 0, 32), UDim2.new(1, -42, 0, 8), Color3.fromRGB(180, 40, 40))
local indexList = Instance.new("ScrollingFrame")
indexList.Name = "List"
indexList.Position = UDim2.new(0, 10, 0, 48)
indexList.Size = UDim2.new(1, -20, 1, -58)
indexList.BackgroundTransparency = 1
indexList.BorderSizePixel = 0
indexList.ScrollBarThickness = 6
indexList.AutomaticCanvasSize = Enum.AutomaticSize.Y
indexList.Parent = indexPanel
local indexLayout = Instance.new("UIGridLayout")
indexLayout.CellSize = UDim2.new(0, 150, 0, 64)
indexLayout.CellPadding = UDim2.new(0, 8, 0, 8)
indexLayout.Parent = indexList

-- Toasts stack at the bottom left.
local toastHolder = Instance.new("Frame")
toastHolder.Name = "Toasts"
toastHolder.AnchorPoint = Vector2.new(0, 1)
toastHolder.Position = UDim2.new(0, 12, 1, -12)
toastHolder.Size = UDim2.new(0, 380, 0, 140)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastHolder

local function showToast(text, good)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(1, 0, 0, 36)
	toast.BackgroundColor3 = good and Color3.fromRGB(30, 120, 60) or Color3.fromRGB(120, 50, 30)
	toast.BackgroundTransparency = 0.15
	toast.BorderSizePixel = 0
	toast.Text = text
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.TextSize = 15
	toast.Font = Enum.Font.GothamBold
	toast.TextWrapped = true
	toast.Parent = toastHolder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	task.delay(5, function()
		toast:Destroy()
	end)
end

local function redrawTopBar()
	moneyLabel.Text = formatMoney(state.money)
	rateLabel.Text = formatMoney(state.rate) .. "/s"
	rebirthLabel.Text = "Rebirth x" .. tostring(state.rebirths)
	stallLabel.Text = state.stallId and ("Stall " .. tostring(state.stallId) .. (state.locked and " LOCKED" or "")) or "Stall -"
	rebirthButton.Text = "Rebirth (" .. formatMoney(state.rebirthCost) .. ")"
	local ownedCount = 0
	for _ in pairs(indexSet) do
		ownedCount += 1
	end
	indexButton.Text = "Index " .. tostring(ownedCount) .. "/36"
end

local function redrawShop()
	for _, child in ipairs(shopList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	if #state.belt == 0 then
		local empty = makeLabel(shopList, "Empty", "The conveyor is empty... new brainrots are coming!", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(200, 200, 200), 16)
		empty.TextXAlignment = Enum.TextXAlignment.Center
		return
	end
	for _, item in ipairs(state.belt) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 52)
		row.BackgroundColor3 = Color3.fromRGB(45, 32, 38)
		row.BorderSizePixel = 0
		row.Parent = shopList
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row
		local rarity = BrainrotData.RarityByName[item.rarity]
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 14, 0, 14)
		dot.Position = UDim2.new(0, 10, 0.5, -7)
		dot.BackgroundColor3 = rarity and rarity.Color or Color3.fromRGB(255, 255, 255)
		dot.BorderSizePixel = 0
		dot.Parent = row
		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = dot
		local nameText = item.name .. (item.mutation and (" (" .. item.mutation .. ")") or "")
		makeLabel(row, "Name", nameText, UDim2.new(0, 200, 0, 24), UDim2.new(0, 34, 0, 4), Color3.fromRGB(255, 255, 255), 16)
		makeLabel(row, "Detail", item.rarity .. "  -  " .. formatMoney(item.rate) .. "/s", UDim2.new(0, 200, 0, 20), UDim2.new(0, 34, 0, 26), Color3.fromRGB(180, 180, 180), 14)
		local buy = makeButton(row, "Buy", formatMoney(item.price), UDim2.new(0, 96, 0, 36), UDim2.new(1, -106, 0.5, -18), Color3.fromRGB(40, 160, 70))
		buy.MouseButton1Click:Connect(function()
			buyRemote:FireServer(item.uid)
		end)
	end
end

local function redrawIndex()
	for _, child in ipairs(indexList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, def in ipairs(BrainrotData.Cast) do
		local owned = indexSet[def.Id] == true
		local rarity = BrainrotData.RarityByName[def.Rarity]
		local cell = Instance.new("Frame")
		cell.BackgroundColor3 = owned and Color3.fromRGB(50, 45, 55) or Color3.fromRGB(30, 28, 34)
		cell.BorderSizePixel = 0
		cell.Parent = indexList
		local cellCorner = Instance.new("UICorner")
		cellCorner.CornerRadius = UDim.new(0, 8)
		cellCorner.Parent = cell
		makeLabel(cell, "Name", def.Name, UDim2.new(1, -8, 0, 20), UDim2.new(0, 4, 0, 4), owned and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130), 14)
		makeLabel(cell, "Rarity", def.Rarity, UDim2.new(1, -8, 0, 18), UDim2.new(0, 4, 0, 24), rarity and rarity.Color or Color3.fromRGB(255, 255, 255), 13)
		makeLabel(cell, "Rate", owned and (formatMoney(def.Rate) .. "/s") or "???", UDim2.new(1, -8, 0, 18), UDim2.new(0, 4, 0, 42), Color3.fromRGB(120, 255, 140), 13)
	end
end

local function redrawAll()
	redrawTopBar()
	if shopPanel.Visible then
		redrawShop()
	end
	if indexPanel.Visible then
		redrawIndex()
	end
end

shopButton.MouseButton1Click:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	if shopPanel.Visible then
		indexPanel.Visible = false
		redrawShop()
	end
end)
indexButton.MouseButton1Click:Connect(function()
	indexPanel.Visible = not indexPanel.Visible
	if indexPanel.Visible then
		shopPanel.Visible = false
		redrawIndex()
	end
end)
shopClose.MouseButton1Click:Connect(function()
	shopPanel.Visible = false
end)
indexClose.MouseButton1Click:Connect(function()
	indexPanel.Visible = false
end)
lockButton.MouseButton1Click:Connect(function()
	lockRemote:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthRemote:FireServer()
end)

stateRemote.OnClientEvent:Connect(function(snapshot)
	state = snapshot
	ownedSet = {}
	for _, owned in ipairs(state.owned or {}) do
		ownedSet[owned.uid] = true
	end
	indexSet = {}
	for _, defId in ipairs(state.index or {}) do
		indexSet[defId] = true
	end
	redrawAll()
end)

notifyRemote.OnClientEvent:Connect(function(text, good)
	showToast(text, good)
end)

hazardRemote.OnClientEvent:Connect(function(text)
	hazardBanner.Text = text
	hazardBanner.Visible = true
	task.delay(12, function()
		hazardBanner.Visible = false
	end)
end)

showToast("Welcome to Ramen Riot! Buy brainrots off the conveyor and fill your stall.", true)
