return function(Icon)
	
	local GuiService = game:GetService("GuiService")
	local isOldTopbar = Icon.isOldTopbar
	local container = {}
	local guiInset = GuiService:GetGuiInset()
	local startInset = if isOldTopbar then 12 else guiInset.Y - (44 + 2)
	local screenGui = Instance.new("ScreenGui")
	screenGui:SetAttribute("StartInset", startInset)
	screenGui.Name = "TopbarStandard"
	screenGui.Enabled = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 10 -- We make it 10 so items like Captions appear in front of the chat
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
	container[screenGui.Name] = screenGui

	local holders = Instance.new("Frame")
	local yDownOffset = if isOldTopbar then 1 else 0
	holders.Name = "Holders"
	holders.BackgroundTransparency = 1
	holders.Position = UDim2.new(0, 0, 0, yDownOffset)
	holders.Size = UDim2.new(1, 0, 1, -2)
	holders.Visible = true
	holders.ZIndex = 1
	holders.Parent = screenGui
	
	local screenGuiClipped = screenGui:Clone()
	screenGuiClipped.Name = "TopbarClipped"
	screenGuiClipped.DisplayOrder += 1
	container[screenGuiClipped.Name] = screenGuiClipped
	
	local screenGuiCenter = screenGui:Clone()
	local holdersCenter = screenGuiCenter.Holders
	local GuiService = game:GetService("GuiService")
	local function updateCenteredHoldersHeight()
		holdersCenter.Size = UDim2.new(1, 0, 0, GuiService.TopbarInset.Height-2)
	end
	screenGuiCenter.Name = "TopbarCentered"
	screenGuiCenter.ScreenInsets = Enum.ScreenInsets.None
	container[screenGuiCenter.Name] = screenGuiCenter
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(updateCenteredHoldersHeight)
	updateCenteredHoldersHeight()
	
	if isOldTopbar then
		local function decideToHideTopbar()
			screenGui.Enabled = not GuiService.MenuIsOpen
			screenGuiCenter.Enabled = not GuiService.MenuIsOpen
		end
		GuiService:GetPropertyChangedSignal("MenuIsOpen"):Connect(decideToHideTopbar)
		decideToHideTopbar()
	end
	
	local holderReduction = -24
	local left = Instance.new("ScrollingFrame")
	left:SetAttribute("IsAHolder", true)
	left.Name = "Left"
	left.Position = UDim2.fromOffset(startInset, 0)
	left.Size = UDim2.new(1, holderReduction, 1, 0)
	left.BackgroundTransparency = 1
	left.Visible = true
	left.ZIndex = 1
	left.Active = false
	left.ClipsDescendants = true
	left.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	left.CanvasSize = UDim2.new(0, 0, 1, -1) -- This -1 prevents a dropdown scrolling appearance bug
	left.AutomaticCanvasSize = Enum.AutomaticSize.X
	left.ScrollingDirection = Enum.ScrollingDirection.X
	left.ScrollBarThickness = 0
	left.BorderSizePixel = 0
	left.Selectable = false
	left.ScrollingEnabled = false--true
	left.ElasticBehavior = Enum.ElasticBehavior.Never
	left.Parent = holders
	
	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0, startInset)
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	UIListLayout.Parent = left
	
	local center = left:Clone()
	center.ScrollingEnabled = false
	center.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	center.Name = "Center"
	center.Parent = holdersCenter
	
	local right = left:Clone()
	right.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	right.Name = "Right"
	right.AnchorPoint = Vector2.new(1, 0)
	right.Position = UDim2.new(1, -12, 0, 0)
	right.Parent = holders

	return container
end