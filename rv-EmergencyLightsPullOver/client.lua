local QBCore = exports['qb-core']:GetCoreObject()
local sirenActive = false
local pulledOverVehicles = {}

-- Function to check if vehicle is an emergency vehicle
local function IsEmergencyVehicle(vehicle)
    local class = GetVehicleClass(vehicle)
    return class == 18 -- 18 is the class for emergency vehicles
--[[
            
            -- Now compare numerical values
            if rightDistNum < leftDistNum then
                return vehicleRight -- Pull to the right
            else
                return -vehicleRight -- Pull to the left
            end
        elseif rightValid then
            return vehicleRight -- Pull to the right if only right side is valid
        else
            return -vehicleRight -- Pull to the left if only left side is valid or default
        end
        -- Normal road handling (original logic)
        if sameDirection then
            return vector3(-vehicleForward.y, vehicleForward.x, 0.0) -- Pull to the right
        else
            -- If on opposite sides, pull over to the left
            return vector3(vehicleForward.y, -vehicleForward.x, 0.0)
    end
end

-- Function to check if a vehicle is in the middle of the road
    local vehiclePos = GetEntityCoords(vehicle)
    local vehicleHeading = GetEntityHeading(vehicle)
    local forwardVector = GetEntityForwardVector(vehicle)
    local rightVector = vector3(-forwardVector.y, forwardVector.x, 0.0)
    
    local rightPos = vehiclePos + rightVector * 10.0
    local leftPos = vehiclePos - rightVector * 10.0
    
    local rightZ = GetGroundZFor_3dCoord(rightPos.x, rightPos.y, rightPos.z + 100.0, 0)
    local leftZ = GetGroundZFor_3dCoord(leftPos.x, leftPos.y, leftPos.z + 100.0, 0)
    
    local _, rightDist = GetClosestRoad(rightPos.x, rightPos.y, rightPos.z, 10.0, 1, false)
    local _, leftDist = GetClosestRoad(leftPos.x, leftPos.y, leftPos.z, 10.0, 1, false)
    
    -- If the vehicle is roughly equal distance from both sides of the road, 
    return math.abs(rightDist - leftDist) < 5.0
end

-- Function to make AI vehicles move to the side
local function MakeVehiclePullOver(vehicle, emergencyVehicle)
    if not DoesEntityExist(vehicle) or not DoesEntityExist(emergencyVehicle) then return end
    if IsPedAPlayer(GetPedInVehicleSeat(vehicle, -1)) then return end -- Skip player vehicles
    
    -- Check if vehicle is already being managed
    for i, v in ipairs(pulledOverVehicles) do
        if v.handle == vehicle then
            return
        end
    end
    
    -- Get positions
    local vehiclePos = GetEntityCoords(vehicle)
    
    -- Get direction to pull over based on road positioning
    local pulloverDirection = DeterminePulloverDirection(vehicle, emergencyVehicle)
    
    -- Set task for the driver
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if DoesEntityExist(driver) then
        -- Check if the vehicle is in the middle of the road
        local inMiddleOfRoad = IsInMiddleOfRoad(vehicle)
        
        -- Make driver more responsive and brake
        TaskVehicleTempAction(driver, vehicle, 6, 2000) -- Brake
        
        -- Check if we should honk the horn when stopping in the middle of the road
        if Config.HonkHorn and inMiddleOfRoad then
            -- First honk when initially braking
            SetTimeout(500, function()
                if DoesEntityExist(vehicle) then
                    StartVehicleHorn(vehicle, 800, "HELDDOWN", false)
                    -- Turn on hazard lights
                    SetVehicleIndicatorLights(vehicle, 0, true) -- Left indicator
                end
            end)
        end
        
        -- After slowing down, pull over
        SetTimeout(1000, function()
            if DoesEntityExist(vehicle) and DoesEntityExist(driver) then
                -- Clear previous tasks and pull over
                
                -- Honk again when starting to pull over if still in the middle of the road
                if Config.HonkHorn and IsInMiddleOfRoad(vehicle) then
                end
                
                TaskVehicleTempAction(driver, vehicle, 27, 10000) -- Move to side of road
                
                -- Add to pulled over vehicles list with additional data for honking behavior
                table.insert(pulledOverVehicles, {
                    handle = vehicle,
                    driver = driver,
                    time = GetGameTimer() + Config.StayPulledOverTime,
                    shouldHonk = inMiddleOfRoad,
                    lastHonkTime = GetGameTimer(),
                    honkInterval = math.random(1000, 2000), -- Random interval between honks
                    hazardLights = inMiddleOfRoad
                })
                
                if Config.Debug then
                    print("Vehicle pulled over: " .. vehicle)
                end
            end
        end)
    end
end

-- Function to manage continuous honking for vehicles in the middle of the road
local function ManageVehicleHonking()
    local currentTime = GetGameTimer()
    
    for i, data in ipairs(pulledOverVehicles) do
        -- If the vehicle should honk and it's time for another honk
        if data.shouldHonk and DoesEntityExist(data.handle) and currentTime > data.lastHonkTime + data.honkInterval then
            -- Check if the vehicle is still in the middle of the road
            if IsInMiddleOfRoad(data.handle) then
                -- Honk the horn
                StartVehicleHorn(data.handle, math.random(300, 600), "HELDDOWN", false)
                -- Update last honk time
                data.lastHonkTime = currentTime
                -- Randomize next honk interval
                data.honkInterval = math.random(1500, 3000)
            else
                -- Vehicle is no longer in the middle of the road, stop honking
                -- Turn off hazard lights when vehicle is clear
                if data.hazardLights then
                    SetVehicleIndicatorLights(data.handle, 0, false) -- Left indicator off
                    SetVehicleIndicatorLights(data.handle, 1, false) -- Right indicator off
                    data.hazardLights = false
                end
            end
        end
    end
end

-- Function to reset vehicles that have been pulled over
local function ResetPulledOverVehicles()
    local currentTime = GetGameTimer()
    local i = 1
    
    while i <= #pulledOverVehicles do
        local data = pulledOverVehicles[i]
        
        if currentTime > data.time then
                ClearPedTasks(data.driver)
                SetVehicleHandbrake(data.handle, false)
                
                -- Turn off hazard lights if they were on
                if data.hazardLights then
                    SetVehicleIndicatorLights(data.handle, 0, false) -- Left indicator off
                    SetVehicleIndicatorLights(data.handle, 1, false) -- Right indicator off
                end
                
                if Config.Debug then
                    print("Vehicle resumed normal driving: " .. data.handle)
                end
            end
            
            table.remove(pulledOverVehicles, i)
        else
            i = i + 1
        end
    end
end

Citizen.CreateThread(function()
        local ped = PlayerPedId()
        local sleep = 1000
        
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if IsEmergencyVehicle(vehicle) then
                sleep = 100
                
                -- Check if siren status has changed
                
                if isSirenOn and not sirenActive then
                    sirenActive = true
                    -- Enhance emergency vehicle behavior for AI recognition
                    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
                    if Config.Debug then
                        print("Siren activated")
                    end
                elseif not isSirenOn and sirenActive then
                    sirenActive = false
                    if Config.Debug then
                        print("Siren deactivated")
                    end
                end
                
                -- If siren is active, make nearby vehicles pull over
                if sirenActive then
                    local playerPos = GetEntityCoords(ped)
                    local vehicles = GetGamePool('CVehicle')
                    
                    for _, nearbyVehicle in ipairs(vehicles) do
                        if nearbyVehicle ~= vehicle then
                            local distance = #(playerPos - GetEntityCoords(nearbyVehicle))
                            if distance < Config.DetectionRadius then
                                MakeVehiclePullOver(nearbyVehicle, vehicle)
                            end
                        end
                    end
                end
            end
        else
            sirenActive = false
        end
        
        -- Manage honking for vehicles in the middle of the road
        ManageVehicleHonking()
-- NUI: Open/close UI
RegisterCommand('rvem_ui', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'status', debug = Config.Debug, vehicles = pulledOverVehicles })
end, false)

RegisterNUICallback('toggleDebug', function(_, cb)
    Config.Debug = not Config.Debug
    Notify('RV-Emergency debug mode: ' .. (Config.Debug and 'ON' or 'OFF'), 'primary', 2000)
    SendNUIMessage({ type = 'status', debug = Config.Debug, vehicles = pulledOverVehicles })
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local sleep = 1000
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if IsEmergencyVehicle(vehicle) then
                sleep = 100
                local isSirenOn = IsVehicleSirenOn(vehicle)
                if isSirenOn and not sirenActive then
                    sirenActive = true
                    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
                    Notify("Siren activated. AI will pull over.", "primary", 1500)
                    if Config.Debug then print("Siren activated") end
                elseif not isSirenOn and sirenActive then
                    sirenActive = false
                    Notify("Siren deactivated.", "primary", 1200)
                    if Config.Debug then print("Siren deactivated") end
                end
                if sirenActive then
                    local playerPos = GetEntityCoords(ped)
                    local vehicles = GetGamePool('CVehicle')
                    for _, nearbyVehicle in ipairs(vehicles) do
                        if nearbyVehicle ~= vehicle then
                            local distance = #(playerPos - GetEntityCoords(nearbyVehicle))
                            if distance < Config.DetectionRadius then
                                MakeVehiclePullOver(nearbyVehicle, vehicle)
                            end
                        end
                    end
                end
            end
        else
            sirenActive = false
        end
        ManageVehicleHonking()
        ResetPulledOverVehicles()
        DrawDebugMarkers()
        -- Update NUI if open
        SendNUIMessage({ type = 'status', debug = Config.Debug, vehicles = pulledOverVehicles })
        Citizen.Wait(sleep)
    end
end)
        
        -- Reset vehicles that have been pulled over for long enough
        ResetPulledOverVehicles()
        
        Citizen.Wait(sleep)
    end

-- Register command for testing if debug mode is enabled
if Config.Debug then
    RegisterCommand('testpullover', function()
        local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            sirenActive = not sirenActive
            SetVehicleSiren(vehicle, sirenActive)
            QBCore.Functions.Notify('Siren ' .. (sirenActive and 'activated' or 'deactivated'), 'primary', 2500)
        else
            QBCore.Functions.Notify('You must be in a vehicle', 'error', 2500)
        end
    end, false)
end
