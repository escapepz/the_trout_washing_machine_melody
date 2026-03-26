local trackedMachines = {}
local pendingMelody = {} -- { obj = { time = timestamp, isCombo = bool } }

local FINISHED_SOUND_DURATION = 15
local FINISHED_SOUND_DURATION_COMBO = 5

local origWasherComplete = ISToggleClothingWasher.complete
function ISToggleClothingWasher:complete()
	local result = origWasherComplete(self)
	if self.object and self.object:isActivated() then
		trackedMachines[self.object] = "washer"
	elseif self.object then
		trackedMachines[self.object] = nil
		pendingMelody[self.object] = nil
	end
	return result
end

local origComboComplete = ISToggleComboWasherDryer.complete
function ISToggleComboWasherDryer:complete()
	local result = origComboComplete(self)
	if self.object and self.object:isActivated() then
		trackedMachines[self.object] = "combo"
	elseif self.object then
		trackedMachines[self.object] = nil
		pendingMelody[self.object] = nil
	end
	return result
end

local getTimestamp = getTimestamp

Events.OnTick.Add(function()
	for obj, machineType in pairs(trackedMachines) do
		if not obj:getObjectIndex() or obj:getObjectIndex() == -1 then
			trackedMachines[obj] = nil
			pendingMelody[obj] = nil
		elseif not obj:isActivated() then
			pendingMelody[obj] = { time = getTimestamp(), combo = (machineType == "combo") }
			trackedMachines[obj] = nil
		end
	end

	for obj, data in pairs(pendingMelody) do
		local duration = data.combo and FINISHED_SOUND_DURATION_COMBO or FINISHED_SOUND_DURATION
		if getTimestamp() - data.time >= duration then
			local sq = obj:getSquare()
			if sq then
				local result = nil
				if data.combo then
					result = sq:playSound("ClothingWasherFinishedMelodyRemix")
				else
					result = sq:playSound("ClothingWasherFinishedMelody")
				end
				--print("[WasherMelody] sq:playSound returned: " .. tostring(result) .. " type: " .. type(result))
				--print(sq:getX(), sq:getY(), sq:getZ())
			end
			pendingMelody[obj] = nil
		end
	end
end)
