--index
ePerEach = {}
ePerEachValue = {}
local cells = {}

local function addCells(...)
        for i = 1, #arg do  -- "arg" is a numerically indexed table containing everything passed to the function (wrapped peripherals, in this case).
                cells[#cells + 1] = arg[i]
        end
end

-- http://www.computercraft.info/wiki/Peripheral.find
addCells(peripheral.find("tile_thermalexpansion_cell"))  -- Wrap all available peripherals of type "tile_thermalexpansion_cell", pass the lot to addCells().
addCells(peripheral.find("powered_tile"))
addCells(peripheral.find("capacitor_bank"))

-- "cells" now contains all available peripherals of the above types, wrapped.

local monitors = {peripheral.find("monitor",
        function(name, object)  -- If this function returns false when passed a found monitor, it won't be included in peripheral.find's results.
                local xSize, ySize = object.getSize()
                return xSize > 38 and ySize > 18 and object.isColour()
        end)}
        
-- "monitors" now contains all available colour-capable monitor peripherals that're at least 39x19.
-- So we can do stuff like monitors[1].write("whatever"), monitors[2].setTextColour(colours.whatever), up to however many monitors we have...

-- Leaving just the turbines and reactors:
local turbines = {peripheral.find("BigReactors%-Turbine")}
local reactors = {peripheral.find("BigReactors%-Reactor")}

--Check for storage cells and monitors before continuing
if #cells == 0 then    -- #cells returns the number of entries in the cells table.
    print("No RF storage found. Exiting script!")
    return
end

if #monitors == 0 then
    print("No Monitor found. Exiting script!")
    return
end

--Print connected peripherals
print("Peripherals connected:")
if #monitors == 1 then print("1 Monitor") else print(#monitors.." Monitor") end
if #cells == 1 then print("1 Cell") else print(#cells.." Cells") end
if #turbines == 1 then print ("1 Turbine") else print (#turbines.." Turbines") end
if #reactors == 1 then print ("1 Reactor") else print (#reactors.." Reactors") end
--Main code

--Function for percentage colour
local function colorPerc(num)
		for i = 1,#monitors do
			local num = tonumber(num)
			if num then
				if num > 90 then
					monitors[i].setTextColor(colors.lime)
				elseif num > 60 then
					monitors[i].setTextColor(colors.yellow)
				elseif num > 30 then
					monitors[i].setTextColor(colors.orange)
				else
					monitors[i].setTextColor(colors.red)
				end
				monitors[i].write(num.."%")
				monitors[i].setTextColor(colors.white)
			end
		end
	end
	
--Main loop
while true do

  --Get all dynamic values
    --Get storage values
    local eNow = 0 eMax = 0 ePer = 0 eFlow = 0
    for i = 1, #connectedCells do
        cell = peripheral.wrap(connectedCells[i])
        eNow = eNow + cell.getEnergyStored()
        eMax = eMax + cell.getMaxEnergyStored()
		eFlow = eNow
		ePer = (eNow / eMax) * 100
		ePerEach[i] = (cell.getEnergyStored() / cell.getMaxEnergyStored()) * 100
    end
	
    --Set storage scale
    if eNow >= 1000000000 then eNowScale = "billion"
    elseif eNow >= 1000000 then eNowScale = "million"
    else eNowScale = "none" end
    if eMax >= 1000000000 then eMaxScale = "billion"
    elseif eMax >= 1000000 then eMaxScale = "million"
    else eMaxScale = "none" end

    --Adjust number to scale
    if eNowScale == "billion" then eNowValue = math.ceil(eNow / 1000000)
    elseif eNowScale == "million" then eNowValue = math.ceil(eNow / 1000)
    else eNowValue = math.ceil(eNow) end
    if eMaxScale == "billion" then eMaxValue = math.ceil(eMax / 1000000)
    elseif eMaxScale == "million" then eMaxValue = math.ceil(eMax / 1000)
    else eMaxValue = math.ceil(eMax) end
	
	--numbers to be rounded
	if ePer >= 0 then ePerValue = math.floor(ePer * 10^2 + 0.5) / 10^2 end
	for i = 1,#ePerEach do
		if ePerEach[i] >=0 then ePerEachValue[i] = math.floor(ePerEach[i] * 10^2 + 0.5) / 10^2 end
	end
	
    --Adjust suffix to scales
    if eNowScale == "billion" then eNowSuffixLarge = "m RF" eNowSuffixSmall = "mRF"
    elseif eNowScale == "million" then eNowSuffixLarge = "k RF" eNowSuffixSmall = "kRF"
    else eNowSuffixLarge = " RF" eNowSuffixSmall = " RF" end
    if eMaxScale == "billion" then eMaxSuffixLarge = "m RF" eMaxSuffixSmall = "mRF"
    elseif eMaxScale == "million" then eMaxSuffixLarge = "k RF" eMaxSuffixSmall = "kRF"
    else eMaxSuffixLarge = " RF" eMaxSuffixSmall = " RF" end

    --Get number of digits to write
    local eNowDigitCount = 0 eMaxDigitCount = 0
    for digit in string.gmatch(eNowValue, "%d") do eNowDigitCount = eNowDigitCount + 1 end
    for digit in string.gmatch(eMaxValue, "%d") do eMaxDigitCount = eMaxDigitCount + 1 end

    --Get location to write
    if eNowSuffixLarge ~= " RF" then eNowXLarge = 15 - eNowDigitCount
    else eNowXLarge = 16 - eNowDigitCount end
    eNowXSmall = 16 - eNowDigitCount
    if eMaxSuffixLarge ~= " RF" then eMaxXLarge = 17 - eMaxDigitCount
    else eMaxXLarge = 18 - eMaxDigitCount end
    eMaxXSmall = 16 - eMaxDigitCount
	
    --Loop to write to every monitor
    for i = 1, #monitors do
            --Erase old data
            monitors[i].setCursorPos(10,9)
            monitors[i].write("       ")
            monitors[i].setCursorPos(10,11)
            monitors[i].write("       ")
            --Write constant/new data
            monitors[i].setCursorPos(0,1)
            monitors[i].write("--------------Energy Status-------------")
            monitors[i].setCursorPos(eNowXLarge,3)
            monitors[i].write("Total Energy: "..eNowValue..eNowSuffixLarge)
			monitors[i].setCursorPos(10,4)
			monitors[i].write("Total Capacity: "..ePerValue.."%")
			monitors[i].setCursorPos(1,6)
			for l = 1,3 do
			monitors[i].write("Bay"..l..": ")
			colorPerc(ePerEachValue[l])
			xPos = l * 14
			monitors[i].setCursorPos(xPos,6)
			end
			monitors[i].setCursorPos(1,7)
			for l = 4,6 do
			monitors[i].write("Bay"..l..": ")
			colorPerc(ePerEachValue[l])
			xPos = (l-3) * 14
			monitors[i].setCursorPos(xPos,7)
			end
			monitors[i].setCursorPos(1,8)
			monitors[i].write(eFlow.."RF/t")
			monitors[i].setCursorPos(1,19)
			monitors[i].write("---------- Energy Flow (RF/t)----------")
    end
    sleep(1)
end