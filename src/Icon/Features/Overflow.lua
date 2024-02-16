-- When designing your game for many devices and screen sizes, icons may occasionally
-- particularly for smaller devices like phones, overlap with other icons or the bounds
-- of the screen. The overflow handler solves this challenge by moving the out-of-bounds
-- icon into an overflow menu (with a limited scrolling canvas) preventing overlaps occuring

--!!! TO DO STILL:
-- 1. Replace test loop with events that are listened for
-- 2. The boundaries (or the holder sizing) aren't 100% accurate. Double check values and make sure there is comfortable spacing
-- 3. Hang on Ben, maybe reconsider this appraoach entirely because 
-- 3. Update the description above as might not reflect new behaviour (frames not overflow icons)
-- 4. Ensure :clipOutside items acccount for this such as notices and captions



-- LOCAL
local SUBMISSIVE_ALIGNMENT = "Right" -- This boundary shrinks if the other alignments boundary gets too close 
local Overflow = {}
local holders = {}
local orderedAvailableIcons = {}
local boundaries = {}
local iconsDict
local currentCamera = workspace.CurrentCamera
local overflowIcons = {}
local Icon



-- FUNCTIONS
-- This is called upon the Icon initializing
function Overflow.start(incomingIcon)
	Icon = incomingIcon
	iconsDict = Icon.iconsDictionary
	for _, screenGui in pairs(Icon.container) do
		for _, holder in pairs(screenGui.Holders:GetChildren()) do
			if holder:GetAttribute("IsAHolder") then
				holders[holder.Name] = holder
			end
		end
	end

	-- !!! The completed overflow will not use a loop, it will listen
	-- for various icon events such as size changed, alignment changed, etc
	-- This is just something quick and easy to help me test
	while false do
		task.wait(2)
		Overflow.updateAvailableIcons("Center")
		Overflow.updateBoundary("Left")
	end
end

function Overflow.getAvailableIcons(alignment)
	local ourOrderedIcons = orderedAvailableIcons[alignment]
	if not ourOrderedIcons then
		ourOrderedIcons = Overflow.updateAvailableIcons(alignment)
	end
	return ourOrderedIcons
end

function Overflow.updateAvailableIcons(alignment)

	-- We only track items that are directly on the topbar (i.e. not within a parent icon)
	local ourTotal = 0
	local holder = holders[alignment]
	local holderUIList = holder.UIListLayout
	local ourOrderedIcons = {}
	for _, icon in pairs(iconsDict) do
		local isDirectlyOnTopbar = not icon.parentIconUID
		if isDirectlyOnTopbar and icon.alignment == alignment then
			table.insert(ourOrderedIcons, icon)
			ourTotal += 1
		end
	end

	-- Ignore if no icons are available
	if ourTotal <= 0 then
		return {}
	end

	-- This sorts these icons by smallest order, or if equal, left-most position
	-- (even for the right alignment because all icons are sorted left-to-right)
	table.sort(ourOrderedIcons, function(iconA, iconB)
		local orderA = iconA.widget.LayoutOrder
		local orderB = iconB.widget.LayoutOrder
		if orderA < orderB then
			return true
		end
		if orderA > orderB then
			return false
		end
		return iconA.widget.AbsolutePosition.X < iconB.widget.AbsolutePosition.X
	end)

	-- Finish up
	orderedAvailableIcons[alignment] = ourOrderedIcons
	return ourOrderedIcons

end

function Overflow.updateBoundary(alignment)
	
	-- These are the icons with menus which icons will be moved into
	-- when overflowing
	local isCentral = alignment == "Central"
	local overflowIcon = overflowIcons[alignment]
	if not overflowIcon and not isCentral then
		overflowIcon = Icon.new():setLabel(`{alignment}`)
		overflowIcon:setAlignment(alignment)
		overflowIcons[alignment] = overflowIcon
	end

	-- We only track items that are directly on the topbar (i.e. not within a parent icon)
	local holder = holders[alignment]
	local holderUIList = holder.UIListLayout
	local topbarInset = holderUIList.Padding.Offset
	local BOUNDARY_GAP = topbarInset
	local ourOrderedIcons = Overflow.updateAvailableIcons(alignment)
	local boundWidth = 0
	local ourTotal = 0
	for _, icon in pairs(ourOrderedIcons) do
		boundWidth += icon.widget.AbsoluteSize.X + holderUIList.Padding.Offset
		ourTotal += 1
	end
	if ourTotal <= 0 then
		return
	end
	
	-- Calculate the start bounds and total bound
	local isLeft = alignment == "Left"
	local isRight = not isLeft
	local lastIcon = (isLeft and ourOrderedIcons[1]) or ourOrderedIcons[ourTotal]
	local lastXPos = lastIcon.widget.AbsolutePosition.X
	local startBound = (isLeft and lastXPos) or lastXPos + lastIcon.widget.AbsoluteSize.X
	local boundary = (isLeft and startBound + boundWidth) or startBound - boundWidth
	print("boundary (1) =", alignment, boundary)
	
	-- Now we get the left-most icon (if left alignment) or right-most-icon (if
	-- right alignment) of the central icons group to see if we need to change
	-- the boundary (if the central icon boundary is smaller than the alignment
	-- boundary then we use the central)
	local centerOrderedIcons = Overflow.getAvailableIcons("Center")
	local centerPos = (isLeft and 1) or #centerOrderedIcons
	local nearestCenterIcon = centerOrderedIcons[centerPos]
	if nearestCenterIcon then
		local nearestXPos = nearestCenterIcon.widget.AbsolutePosition.X
		local centerBoundary = (isLeft and nearestXPos) or nearestXPos + nearestCenterIcon.widget.AbsoluteSize.X + topbarInset
		if isLeft and centerBoundary - BOUNDARY_GAP < boundary then
			boundary = centerBoundary
		elseif isRight and centerBoundary + BOUNDARY_GAP > boundary then
			boundary = centerBoundary
		end
		print("boundary (2) =", alignment, boundary)
	end

	-- If the boundary exceeds the sides of the screen minus the
	-- size of 3 default icons and 2 boundary gaps IF > 1 icons on
	-- opposite side of screen (because the overflow
	-- could be an open menu) we clamp it (forcing the dominant boundary
	-- to also shrink in addition to the submissive boundary)
	local hasExceededSide = false
	if not isCentral then
		local Themes = require(script.Parent.Themes)
		local stateGroup = overflowIcon:getStateGroup()
		local defaultIconWidth = Themes.getThemeValue(stateGroup, "Widget", "MinimumWidth") or 0
		local requiredSideGap = (defaultIconWidth*3) + (BOUNDARY_GAP*2)
		local viewportWidth = currentCamera.ViewportSize.X
		if isLeft and boundary < requiredSideGap then
			boundary = requiredSideGap
			hasExceededSide = true
		elseif isRight and boundary > viewportWidth - requiredSideGap then
			boundary = viewportWidth - requiredSideGap
			hasExceededSide = true
		end
		print("boundary (4) =", alignment, boundary)
	end
	
	-- If the dominant boundary exceeds the submissive boundary, its
	-- important we shrink the submissive one to account
	local isSubmissive = alignment == SUBMISSIVE_ALIGNMENT 
	local isDominant = not isSubmissive
	local oppositeAlignment = (alignment == "Left" and "Right") or "Left"
	local oppositeBoundary = boundaries[oppositeAlignment]
	if ((isSubmissive and not hasExceededSide) or (isDominant and hasExceededSide)) then
		if oppositeBoundary and not hasExceededSide then
			if isLeft and oppositeBoundary - BOUNDARY_GAP < boundary then
				boundary = oppositeBoundary
			elseif isRight and oppositeBoundary + BOUNDARY_GAP > boundary then
				boundary = oppositeBoundary
			end
			print("boundary (3) =", alignment, boundary)
		end
	end

	-- Record the boundary so the opposite alignment can use it
	boundaries[alignment] = boundary

	-- Now update the size of the holder
	local viewportWidth = currentCamera.ViewportSize.X
	local holderXPos = holder.AbsolutePosition.X
	local holderWidth = (isLeft and boundary - holderXPos) or (viewportWidth - boundary)
	holderWidth -= BOUNDARY_GAP
	holder.Size = UDim2.new(0, holderWidth, 1, 0)
	
	-- If we're the dominant boundary it's important we recalculate the
	-- submissive boundary as they depend on our boundary information
	if isDominant then
		Overflow.updateBoundary(oppositeAlignment)
	end

end



return Overflow