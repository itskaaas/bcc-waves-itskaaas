local Core = exports.vorp_core:GetCore()
local BccUtils = exports['bcc-utils'].initiate()

local RobberyEnabled, Inmission = true, false
local DoReset, Countdown = false, false
local Timer = 0
local enemyPeds = {}
local enemyBlips = {}
local LootDone = false
local areaBlip = nil

-- Start marker drawing thread since robberies are enabled by default
Citizen.CreateThread(function()
    while RobberyEnabled do
        Citizen.Wait(0)
        for _, coords in ipairs(Markers) do
            Citizen.InvokeNative(0x2A32FAA57B937173, 0x07DCE236, coords.x, coords.y, coords.z - 0.9, 0, 0, 0, --you can change the marker @ (https://github.com/femga/rdr3_discoveries/blob/master/graphics/markers/marker_types.lua)
                0, 0, 0, 1.0, 1.0, 1.0, 0, 255, 0, 250, 0, 0, 2, 0, 0, 0, 0)
        end
        if not RobberyEnabled then
            break
        end
    end
end)

-- Command to Enable/Disable Robberies
RegisterCommand(Config.RobberyCommand, function()
    if not RobberyEnabled then
        local result = Core.Callback.TriggerAwait('bcc-waves-itskaaas:RobberyCheck')
        if result then
            RobberyEnabled = true
            Core.NotifyRightTip(_U('RobberyEnable'), 4000)
            Citizen.CreateThread(function()
                while RobberyEnabled do
                    Citizen.Wait(0)
                    for _, coords in ipairs(Markers) do
                        Citizen.InvokeNative(0x2A32FAA57B937173, 0x07DCE236, coords.x, coords.y, coords.z - 0.9, 0, 0, 0, --you can change the marker @ (https://github.com/femga/rdr3_discoveries/blob/master/graphics/markers/marker_types.lua)
                            0, 0, 0, 1.0, 1.0, 1.0, 0, 255, 0, 250, 0, 0, 2, 0, 0, 0, 0)
                    end
                    if not RobberyEnabled then
                        break
                    end
                end
            end)
        else
            RobberyEnabled = false
        end
    else
        RobberyEnabled = false
        Core.NotifyRightTip(_U('RobberyDisable'), 4000)
    end
end, false)

CreateThread(function()
    local playerCoords
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()

        if not RobberyEnabled or Inmission or IsEntityDead(playerPed) then goto END end

        playerCoords = GetEntityCoords(playerPed)

        for i, coords in ipairs(Markers) do
            local locationCfg = Locations[i]
            local distance = #(playerCoords - coords)
            if distance <= locationCfg.Distance then
                sleep = 0
                BccUtils.Misc.DrawText3D(coords.x, coords.y, coords.z + 0.5, "aperte E pra começar a invasão")
                if IsControlPressed(0, 0xCEFD9220) then -- Hold E to start robbery
                    local result = Core.Callback.TriggerAwait('bcc-waves-itskaaas:CheckCooldown', locationCfg)
                    if result then
                        Inmission = true
                        TriggerEvent('bcc-waves-itskaaas:RobberyHandler', locationCfg)
                    else
                        Core.NotifyRightTip(_U('OnCooldown'), 4000)
                        Wait(5000)
                    end
                end
            end
        end
        ::END::
        Wait(sleep)
    end
end)

local function ResetRobbery()
    Inmission = false
    Countdown = false
    RequestStreamedTextureDict("menu_textures")
    while not HasStreamedTextureDictLoaded("menu_textures") do
        Wait(0)
    end
    Core.NotifyLeft(_U('RobberyFail'), "", "menu_textures", "cross", 4000, "COLOR_RED")
    SetStreamedTextureDictAsNoLongerNeeded("menu_textures")
    Wait(5000)
    DoReset = false
end

AddEventHandler('bcc-waves-itskaaas:RobberyHandler', function(locationCfg)
    RequestStreamedTextureDict("menu_textures")
    while not HasStreamedTextureDictLoaded("menu_textures") do
        Wait(0)
    end
    Core.NotifyLeft(_U('RobberyStart'), "", "menu_textures", "menu_icon_alert", 4000, "COLOR_RED")
    SetStreamedTextureDictAsNoLongerNeeded("menu_textures")
    LootDone = false

    -- Create area blip on the map
    areaBlip = Citizen.InvokeNative(0x45f13b7e0a15c880, -1282792512, locationCfg.StartingCoords.x, locationCfg.StartingCoords.y, locationCfg.StartingCoords.z, Config.AreaRadius) -- AddBlipForRadius
    Citizen.InvokeNative(0x03D7FB09E75D6B7E, areaBlip, 1) -- SetBlipAsShortRange
    Citizen.InvokeNative(0x662D364ABF16DE2F, areaBlip, joaat('BLIP_STYLE_ENEMY')) -- SetBlipSprite
    Citizen.InvokeNative(0x9CB1A1623062F402, areaBlip, 'Invasão de acampamento') -- SetBlipName

    if locationCfg.EnemyNpcs then
        TriggerEvent('bcc-waves-itskaaas:EnemyPeds', locationCfg)
    end

    -- Monitor player death to reset robbery
    Citizen.CreateThread(function()
        while Countdown do
            Wait(1000)
            if IsEntityDead(PlayerPedId()) then
                DoReset = true
                if DoesBlipExist(areaBlip) then RemoveBlip(areaBlip) end
                break
            end
        end
    end)

    Countdown = true
    TriggerEvent('bcc-waves-itskaaas:Countdown', locationCfg)
    local startingCoords = locationCfg.StartingCoords

    while Countdown do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - startingCoords)

        if (distance > Config.AreaRadius) or (IsEntityDead(playerPed)) then
            DoReset = true
            break
        end

        -- Check if player is near any loot location and find the nearest
        local nearLoot = false
        local nearestLootCoords = nil
        local minDistance = 10
        for _, lootCfg in pairs(locationCfg.LootLocations) do
            local lootDistance = #(playerCoords - lootCfg.LootCoordinates)
            if lootDistance < minDistance then
                minDistance = lootDistance
                nearestLootCoords = lootCfg.LootCoordinates
                nearLoot = true
            end
        end

        if nearLoot then
            BccUtils.Misc.DrawText3D(nearestLootCoords.x, nearestLootCoords.y, nearestLootCoords.z + 0.5,
                _U('HoldOutBeforeLooting') .. ' ' .. tostring(Timer) .. ' ' .. _U('HoldOutBeforeLooting2'))
        end
        if Timer <= 0 then
            Core.NotifyRightTip(_U('LootMarked'), 4000)
            break
        end
    end

    if DoReset then
        ResetRobbery()
        return
    end

    for _, lootCfg in pairs(locationCfg.LootLocations) do
        TriggerEvent('bcc-waves-itskaaas:LootHandler', lootCfg, startingCoords)
    end
end)

AddEventHandler('bcc-waves-itskaaas:Countdown', function(locationCfg)
    Timer = locationCfg.WaitBeforeLoot
    while Countdown do
        Wait(1000)
        Timer = Timer - 1
        if Timer <= 0 then
            Countdown = false
        end
    end
end)

AddEventHandler('bcc-waves-itskaaas:LootHandler', function(lootCfg, startingCoords)
    math.randomseed(GetGameTimer()) --Create a new seed for math.random

    local soundPlayed = false

    local lootGroup = BccUtils.Prompts:SetupPromptGroup()
    local lootPrompt = lootGroup:RegisterPrompt(_U('Rob'), Config.Keys.Loot, 1, 1, true, 'hold',
        { timedeventhash = "MEDIUM_TIMED_EVENT" })

    while true do
        Wait(0)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - lootCfg.LootCoordinates)
        local areaDistance = #(playerCoords - startingCoords)

        if (areaDistance > Config.AreaRadius) or (IsEntityDead(playerPed)) then
            DoReset = true
            break
        end

        if distance < 6 then
            BccUtils.Misc.DrawText3D(lootCfg.LootCoordinates.x, lootCfg.LootCoordinates.y, lootCfg.LootCoordinates.z,
                _U('Robbery'))
        end

        if distance < 2 then
            lootGroup:ShowGroup(_U('Robbery'))
            if lootPrompt:HasCompleted() then
                RequestStreamedTextureDict("generic_textures")
                while not HasStreamedTextureDictLoaded("generic_textures") do
                    Wait(0)
                end
                Core.NotifyLeft("Cofre aberto com sucesso", "", "generic_textures", "tick", 4000, "COLOR_GREEN")
                SetStreamedTextureDictAsNoLongerNeeded("generic_textures")
                TriggerServerEvent('bcc-waves-itskaaas:RewardPayout', lootCfg)
                Inmission = false
                break
            end
        end
    end
    LootDone = true
    if DoReset then
        ResetRobbery()
        return
    end
end)

local function LoadModel(hash, model)
    if not IsModelValid(hash) then
        return print('Invalid model:', model)
    end

    RequestModel(hash, false)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
end

local function GetClosestPlayer()
    local players = {}
    for i = 0, 31 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end
    local closestPlayer = nil
    local closestDist = 1000
    local myCoords = GetEntityCoords(PlayerPedId())
    for _, player in ipairs(players) do
        local ped = GetPlayerPed(player)
        if ped ~= PlayerPedId() and not IsEntityDead(ped) then
            local coords = GetEntityCoords(ped)
            local dist = Vdist(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z)
            if dist < closestDist then
                closestDist = dist
                closestPlayer = ped
            end
        end
    end
    return closestPlayer or PlayerPedId()
end

AddEventHandler('bcc-waves-itskaaas:EnemyPeds', function(location)
    if DoReset or IsEntityDead(PlayerPedId()) then
        if DoesBlipExist(areaBlip) then RemoveBlip(areaBlip) end
        return
    end
    local startingCoords = location.StartingCoords
    local waves = Config.EnemyWaves -- Enemy waves from config
    local totalEnemiesNeeded = 0
    for _, waveSize in ipairs(waves) do
        totalEnemiesNeeded = totalEnemiesNeeded + waveSize
    end
    local numCoords = totalEnemiesNeeded
    local NpcCoords = {}

    -- Spawn enemies around the marker location, avoiding player position
    local markerCoords = startingCoords
    local playerCoords = GetEntityCoords(PlayerPedId())

    local minDist = 70
    local maxDist = 70

    for i = 1, numCoords do
        local angle = math.random() * 2 * math.pi  -- Random angle around the marker
        local dist = math.random(minDist, maxDist)
        local x = markerCoords.x + dist * math.cos(angle)
        local y = markerCoords.y + dist * math.sin(angle)
        local z = markerCoords.z + 50  -- Start higher to ensure raycast from above ground
        -- Get ground Z to ensure proper spawning on terrain
        local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
        if foundGround then
            z = groundZ
        end
        -- Ensure spawn is not too close to player
        local spawnCoords = vector3(x, y, z)
        local playerDist = #(spawnCoords - playerCoords)
        if playerDist < 30 then
            -- Adjust angle to move away from player
            local dirToPlayer = playerCoords - markerCoords
            local angleToPlayer = math.atan2(dirToPlayer.y, dirToPlayer.x)
            angle = angle + math.pi  -- Opposite direction
            x = markerCoords.x + dist * math.cos(angle)
            y = markerCoords.y + dist * math.sin(angle)
            local foundGround2, groundZ2 = GetGroundZFor_3dCoord(x, y, z + 10, false)
            if foundGround2 then
                z = groundZ2
            end
        end
        table.insert(NpcCoords, {x = x, y = y, z = z})
    end
    local model = location.NpcModel
    local hash = joaat(model)
    local currentWave = 1
    local totalEnemies = 0
    local wavePeds = {} -- Track peds per wave

    LoadModel(hash, model)

    local function SpawnWave(waveIndex)
        if DoReset or IsEntityDead(PlayerPedId()) then
            if DoesBlipExist(areaBlip) then RemoveBlip(areaBlip) end
            return
        end
        local waveSize = waves[waveIndex]
        local spawned = 0
        wavePeds[waveIndex] = {}
        for i = totalEnemies + 1, #NpcCoords do
            if spawned >= waveSize then break end
            local coords = NpcCoords[i]
            local pedIndex = totalEnemies + spawned + 1
            enemyPeds[pedIndex] = Citizen.InvokeNative(0xD49F9B0955C367DE, hash, coords.x, coords.y, coords.z, 0.0, true, false,
                false, false)                                                           -- CreatePed
            Citizen.InvokeNative(0x283978A15512B2FE, enemyPeds[pedIndex], true)                -- SetRandomOutfitVariation
            PlaceObjectOnGroundProperly(enemyPeds[pedIndex], false)
            local target = GetClosestPlayer()
            Citizen.InvokeNative(0xF166E48407BAC484, enemyPeds[pedIndex], target, 0, 16) -- TaskCombatPed with CRF_PreferMelee
            -- Set difficulty-based attributes
            local difficulty = location.EnemyDifficulty or 'easy'
            if difficulty == 'easy' then
                Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], true)                -- SetPedCombatAttributes
                Citizen.InvokeNative(0xBD75500141E4725C, enemyPeds[pedIndex], 1)                  -- SetPedCombatMovement Offensive
                Citizen.InvokeNative(0x7C076FF3165DF066, enemyPeds[pedIndex], 50)                 -- SetPedAccuracy to 50
                Citizen.InvokeNative(0x3C606747B23E497B, enemyPeds[pedIndex], 1)                  -- SetPedCombatRange Medium
                Citizen.InvokeNative(0xF29CF591C4BF6CEE, enemyPeds[pedIndex], 100.0)              -- SetPedSeeingRange
                Citizen.InvokeNative(0x33A8F7F7D5F7F33C, enemyPeds[pedIndex], 100.0)              -- SetPedHearingRange
            elseif difficulty == 'medium' then
                Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], true)                -- SetPedCombatAttributes
                Citizen.InvokeNative(0xBD75500141E4725C, enemyPeds[pedIndex], 1)                  -- SetPedCombatMovement Offensive
                Citizen.InvokeNative(0x7C076FF3165DF066, enemyPeds[pedIndex], 75)                 -- SetPedAccuracy to 75
                Citizen.InvokeNative(0x3C606747B23E497B, enemyPeds[pedIndex], 1)                  -- SetPedCombatRange Medium
                Citizen.InvokeNative(0xF29CF591C4BF6CEE, enemyPeds[pedIndex], 125.0)              -- SetPedSeeingRange
                Citizen.InvokeNative(0x33A8F7F7D5F7F33C, enemyPeds[pedIndex], 125.0)              -- SetPedHearingRange
            elseif difficulty == 'hard' then
                Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], true)                -- SetPedCombatAttributes
                Citizen.InvokeNative(0xBD75500141E4725C, enemyPeds[pedIndex], 1)                  -- SetPedCombatMovement Offensive
                Citizen.InvokeNative(0x7C076FF3165DF066, enemyPeds[pedIndex], 100)                -- SetPedAccuracy to 100
                Citizen.InvokeNative(0x3C606747B23E497B, enemyPeds[pedIndex], 1)                  -- SetPedCombatRange Medium
                Citizen.InvokeNative(0xF29CF591C4BF6CEE, enemyPeds[pedIndex], 150.0)              -- SetPedSeeingRange increased
                Citizen.InvokeNative(0x33A8F7F7D5F7F33C, enemyPeds[pedIndex], 150.0)              -- SetPedHearingRange increased
            end
            Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], 0, true)            -- SetPedFleeAttributes to prevent fleeing
            Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], 0, true)            -- Aggressive combat attributes
            Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], 1, true)            -- Can fight armed peds
            Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], 2, true)            -- Can charge
            Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], 5, true)            -- Can investigate
            Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], 17, false)          -- Disable cover usage
            Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], 46, true)           -- Always fight
            Citizen.InvokeNative(0x9F8AA94D6D97DBF4, enemyPeds[pedIndex], 52, true)           -- Always advance
            enemyBlips[pedIndex] = Citizen.InvokeNative(0x23f74c2fda6e7c61, 953018525, enemyPeds[pedIndex]) -- BlipAddForEntity
            Citizen.InvokeNative(0x03D7FB09E75D6B7E, enemyBlips[pedIndex], 1) -- SetBlipAsShortRange

            -- Reapply combat task after a short delay to ensure it sticks
            Citizen.CreateThread(function()
                Citizen.Wait(500)
                if DoesEntityExist(enemyPeds[pedIndex]) and not IsEntityDead(enemyPeds[pedIndex]) then
                    local target = GetClosestPlayer()
                    Citizen.InvokeNative(0xF166E48407BAC484, enemyPeds[pedIndex], target, 0, 16) -- Reapply TaskCombatPed with CRF_PreferMelee
                end
            end)
            -- Continuous check to ensure ped is always in combat and chasing the player
            Citizen.CreateThread(function()
                while DoesEntityExist(enemyPeds[pedIndex]) and not IsEntityDead(enemyPeds[pedIndex]) do
                    Citizen.Wait(1000) -- Check every 1 second
                    local target = GetClosestPlayer()
                    Citizen.InvokeNative(0xF166E48407BAC484, enemyPeds[pedIndex], target, 0, 16) -- Force combat task
                    -- Force the ped to chase the player if not moving towards them
                    local pedCoords = GetEntityCoords(enemyPeds[pedIndex])
                    local targetCoords = GetEntityCoords(target)
                    local distance = Vdist(pedCoords.x, pedCoords.y, pedCoords.z, targetCoords.x, targetCoords.y, targetCoords.z)
                    if distance > 2.0 and not IsPedWalking(enemyPeds[pedIndex]) and not IsPedRunning(enemyPeds[pedIndex]) and not IsPedSprinting(enemyPeds[pedIndex]) then
                        Citizen.InvokeNative(0x6A071245EB0D1882, enemyPeds[pedIndex], target, -1, 4.0, 4.0, 0, 0) -- TaskGoToEntity to chase running
                    end
                end
            end)
            table.insert(wavePeds[waveIndex], pedIndex)
            spawned = spawned + 1
        end
        totalEnemies = totalEnemies + spawned
        RequestStreamedTextureDict("menu_textures")
        while not HasStreamedTextureDictLoaded("menu_textures") do
            Wait(0)
        end
        Core.NotifyLeft(_U('EnemiesComing'), "", "menu_textures", "menu_icon_alert", 4000, "COLOR_WHITE")
        SetStreamedTextureDictAsNoLongerNeeded("menu_textures")
    end

    local function IsWaveDead(waveIndex)
        for _, pedIndex in pairs(wavePeds[waveIndex]) do
            local ped = enemyPeds[pedIndex]
            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                return false
            end
        end
        return true
    end

    -- Spawn first wave after configured delay
    local delay = Config.FirstWaveDelay * 1000
    while delay > 0 do
        Wait(1000)
        delay = delay - 1000
        if DoReset or IsEntityDead(PlayerPedId()) then
            if DoesBlipExist(areaBlip) then RemoveBlip(areaBlip) end
            return
        end
    end
    if DoReset or IsEntityDead(PlayerPedId()) then
        if DoesBlipExist(areaBlip) then RemoveBlip(areaBlip) end
        return
    end
    SpawnWave(currentWave)
    currentWave = currentWave + 1

    -- Spawn subsequent waves when previous wave is dead
    Citizen.CreateThread(function()
        while currentWave <= #waves do
            -- Wait until current wave is dead
            while not IsWaveDead(currentWave - 1) do
                Wait(1000)
                if DoReset or LootDone or IsEntityDead(PlayerPedId()) then
                    if DoesBlipExist(areaBlip) then RemoveBlip(areaBlip) end
                    return
                end
            end
            if DoReset or LootDone or IsEntityDead(PlayerPedId()) then
                if DoesBlipExist(areaBlip) then RemoveBlip(areaBlip) end
                break
            end
            -- Add delay before spawning next wave
            local waveDelay = Config.EnemyWaveDelay * 1000
            while waveDelay > 0 do
                Wait(1000)
                waveDelay = waveDelay - 1000
                if DoReset or LootDone or IsEntityDead(PlayerPedId()) then
                    if DoesBlipExist(areaBlip) then RemoveBlip(areaBlip) end
                    return
                end
            end
            if DoReset or LootDone or IsEntityDead(PlayerPedId()) then
                if DoesBlipExist(areaBlip) then RemoveBlip(areaBlip) end
                break
            end
            SpawnWave(currentWave)
            currentWave = currentWave + 1
        end
    end)



    -- Thread to remove blips from dead enemies
    Citizen.CreateThread(function()
        while true do
            Wait(1000) -- Check every second
            if DoReset or LootDone then break end
            for pedIndex, ped in pairs(enemyPeds) do
                if DoesEntityExist(ped) and IsEntityDead(ped) then
                    if enemyBlips[pedIndex] and DoesBlipExist(enemyBlips[pedIndex]) then
                        RemoveBlip(enemyBlips[pedIndex])
                        enemyBlips[pedIndex] = nil
                    end
                end
            end
        end
    end)

    while true do
        Wait(0)
        if DoReset or LootDone then
            -- Delete all enemy peds
            for _, ped in pairs(enemyPeds) do
                if DoesEntityExist(ped) then
                    local netId = NetworkGetNetworkIdFromEntity(ped)
                    TriggerServerEvent('bcc-waves-itskaaas:DeletePed', netId)
                end
            end
            -- Remove blips
            for _, blip in pairs(enemyBlips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
            if DoesBlipExist(areaBlip) then
                RemoveBlip(areaBlip)
            end
            enemyPeds = {}
            enemyBlips = {}
            areaBlip = nil
            break
        end
    end
end)
