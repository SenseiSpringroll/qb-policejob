-- Variables
local currentGarage = 0
local inFingerprint = false
local FingerPrintSessionId = nil
local inStash = false
local inTrash = false
local inArmoury = false
local inHelicopter = false
local inImpound = false
local inGarage = false

local function loadAnimDict(dict) -- interactions, job,
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(10)
    end
end

local function GetClosestPlayer() -- interactions, job, tracker
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())

    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

local function openFingerprintUI()
    SendNUIMessage({
        type = "fingerprintOpen"
    })
    inFingerprint = true
    SetNuiFocus(true, true)
end

local function SetCarItemsInfo()
	local items = {}
	for _, item in pairs(Config.CarItems) do
		local itemInfo = QBCore.Shared.Items[item.name:lower()]
		items[item.slot] = {
			name = itemInfo["name"],
			amount = tonumber(item.amount),
			info = item.info,
			label = itemInfo["label"],
			description = itemInfo["description"] and itemInfo["description"] or "",
			weight = itemInfo["weight"],
			type = itemInfo["type"],
			unique = itemInfo["unique"],
			useable = itemInfo["useable"],
			image = itemInfo["image"],
			slot = item.slot,
		}
	end
	Config.CarItems = items
end

local function doCarDamage(currentVehicle, veh)
	local smash = false
	local damageOutside = false
	local damageOutside2 = false
	local engine = veh.engine + 0.0
	local body = veh.body + 0.0

	if engine < 200.0 then engine = 200.0 end
    if engine  > 1000.0 then engine = 950.0 end
	if body < 150.0 then body = 150.0 end
	if body < 950.0 then smash = true end
	if body < 920.0 then damageOutside = true end
	if body < 920.0 then damageOutside2 = true end

    Wait(100)
    SetVehicleEngineHealth(currentVehicle, engine)

	if smash then
		SmashVehicleWindow(currentVehicle, 0)
		SmashVehicleWindow(currentVehicle, 1)
		SmashVehicleWindow(currentVehicle, 2)
		SmashVehicleWindow(currentVehicle, 3)
		SmashVehicleWindow(currentVehicle, 4)
	end

	if damageOutside then
		SetVehicleDoorBroken(currentVehicle, 1, true)
		SetVehicleDoorBroken(currentVehicle, 6, true)
		SetVehicleDoorBroken(currentVehicle, 4, true)
	end

	if damageOutside2 then
		SetVehicleTyreBurst(currentVehicle, 1, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 2, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 3, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 4, false, 990.0)
	end

	if body < 1000 then
		SetVehicleBodyHealth(currentVehicle, 985.1)
	end
end

--function TakeOutImpound(vehicle)
--    local coords = Config.Locations["impound"][currentGarage]
--    if coords then
--        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
--            local veh = NetToVeh(netId)
--            QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
--                QBCore.Functions.SetVehicleProperties(veh, properties)
--                SetVehicleNumberPlateText(veh, vehicle.plate)
--		SetVehicleDirtLevel(veh, 0.0)
--                SetEntityHeading(veh, coords.w)
--                exports['ps-fuel']:SetFuel(veh, vehicle.fuel)
--                doCarDamage(veh, vehicle)
--                TriggerServerEvent('police:server:TakeOutImpound', vehicle.plate, currentGarage)
--                closeMenuFull()
--                TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
--                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
--                SetVehicleEngineOn(veh, true, true)
--            end, vehicle.plate)
--        end, vehicle.vehicle, coords, true)
--    end
--end

function TakeOutVehicle(vehicleInfo)
    local coords = Config.Locations["vehicle"][currentGarage]
    if coords then
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            SetCarItemsInfo()
            SetVehicleNumberPlateText(veh, Lang:t('info.police_plate')..tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            exports['ps-fuel']:SetFuel(veh, 100.0)
            closeMenuFull()
            if Config.VehicleSettings[vehicleInfo] ~= nil then
                if Config.VehicleSettings[vehicleInfo].extras ~= nil then
			QBCore.Shared.SetDefaultVehicleExtras(veh, Config.VehicleSettings[vehicleInfo].extras)
		end
		if Config.VehicleSettings[vehicleInfo].livery ~= nil then
			SetVehicleLivery(veh, Config.VehicleSettings[vehicleInfo].livery)
		end
            end
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            TriggerServerEvent("inventory:server:addTrunkItems", QBCore.Functions.GetPlate(veh), Config.CarItems)
            SetVehicleEngineOn(veh, true, true)
        end, vehicleInfo, coords, true)
    end
end

local function IsArmoryWhitelist() -- being removed
    local retval = false

    if QBCore.Functions.GetPlayerData().job.type == 'leo' then
        retval = true
    end
    return retval
end

local function SetWeaponSeries()
    for k, _ in pairs(Config.Items.items) do
        if k < 6 then
            Config.Items.items[k].info.serie = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
        end
    end
end

RegisterNetEvent("police:client:PedVehicles", function()
    local Menu = {
        {
            header = Lang:t('menu.garage_title'),
            isMenuHeader = true,
            icon = "fas fa-warehouse",
        }
    }
    local authorizedVehicles = Config.AuthorizedVehicles[QBCore.Functions.GetPlayerData().job.grade.level]
    for veh, label in pairs(authorizedVehicles) do
        Menu[#Menu+1] = {
            header = label,
            icon = "fa-solid fa-car",
            txt = "",
            params = {
                event = "police:client:TakeOutVehicle",
                args = {
                    vehicle = veh,
                    --currentSelection = currentSelection
                }
            }
        }
    end
    exports['qb-menu']:openMenu(Menu)
end)




function MenuGarage(currentSelection)
    print(json.encode(currentSelection))
    local vehicleMenu = {
        {
            header = Lang:t('menu.garage_title'),
            isMenuHeader = true,
            icon = "fas fa-warehouse",
        }
    }

    local authorizedVehicles = Config.AuthorizedVehicles[QBCore.Functions.GetPlayerData().job.grade.level]
    for veh, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu+1] = {
            header = label,
            icon = "fa-solid fa-car",
            txt = "",
            params = {
                event = "police:client:TakeOutVehicle",
                args = {
                    vehicle = veh,
                    currentSelection = currentSelection
                }
            }
        }
    end

    if IsArmoryWhitelist() then
        for veh, label in pairs(Config.WhitelistedVehicles) do
            vehicleMenu[#vehicleMenu+1] = {
                header = label,
                txt = "",
                params = {
                    event = "police:client:TakeOutVehicle",
                    args = {
                        vehicle = veh,
                        currentSelection = currentSelection
                    }
                }
            }
        end
    end

    vehicleMenu[#vehicleMenu+1] = {
        header = Lang:t('menu.close'),
        txt = "",
        params = {
            event = "qb-menu:client:closeMenu"
        }

    }
    exports['qb-menu']:openMenu(vehicleMenu)
end

function MenuImpound(currentSelection)
    local impoundMenu = {
        {
            header = Lang:t('menu.impound'),
            isMenuHeader = true
        }
    }
    QBCore.Functions.TriggerCallback("police:GetImpoundedVehicles", function(result)
        local shouldContinue = false
        if result == nil then
            QBCore.Functions.Notify(Lang:t("error.no_impound"), "error", 5000)
        else
            shouldContinue = true
            for _ , v in pairs(result) do
                local enginePercent = QBCore.Shared.Round(v.engine / 10, 0)
                local currentFuel = v.fuel
                local vname = QBCore.Shared.Vehicles[v.vehicle].name

                impoundMenu[#impoundMenu+1] = {
                    header = vname.." ["..v.plate.."]",
                    txt =  Lang:t('info.vehicle_info', {value = enginePercent, value2 = currentFuel}),
                    params = {
                        event = "police:client:TakeOutImpound",
                        args = {
                            vehicle = v,
                            currentSelection = currentSelection
                        }
                    }
                }
            end
        end


        if shouldContinue then
            impoundMenu[#impoundMenu+1] = {
                header = Lang:t('menu.close'),
                txt = "",
                params = {
                    event = "qb-menu:client:closeMenu"
                }
            }
            exports['qb-menu']:openMenu(impoundMenu)
        end
    end)

end

function closeMenuFull()
    exports['qb-menu']:closeMenu()
end

--NUI Callbacks
RegisterNUICallback('closeFingerprint', function(_, cb)
    SetNuiFocus(false, false)
    inFingerprint = false
    cb('ok')
end)

--Events
RegisterNetEvent('police:client:showFingerprint', function(playerId)
    openFingerprintUI()
    FingerPrintSessionId = playerId
end)

RegisterNetEvent('police:client:showFingerprintId', function(fid)
    SendNUIMessage({
        type = "updateFingerprintId",
        fingerprintId = fid
    })
    PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0, 0, 1)
end)

RegisterNUICallback('doFingerScan', function(_, cb)
    TriggerServerEvent('police:server:showFingerprintId', FingerPrintSessionId)
    cb("ok")
end)

RegisterNetEvent('police:client:SendEmergencyMessage', function(coords, message)
    TriggerServerEvent("police:server:SendEmergencyMessage", coords, message)
    TriggerEvent("police:client:CallAnim")
end)

RegisterNetEvent('police:client:EmergencySound', function()
    PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 0, 0, 1)
end)

RegisterNetEvent('police:client:CallAnim', function()
    local isCalling = true
    local callCount = 5
    loadAnimDict("cellphone@")
    TaskPlayAnim(PlayerPedId(), 'cellphone@', 'cellphone_call_listen_base', 3.0, -1, -1, 49, 0, false, false, false)
    Wait(1000)
    CreateThread(function()
        while isCalling do
            Wait(1000)
            callCount = callCount - 1
            if callCount <= 0 then
                isCalling = false
                StopAnimTask(PlayerPedId(), 'cellphone@', 'cellphone_call_listen_base', 1.0)
            end
        end
    end)
end)

RegisterNetEvent('police:client:ImpoundVehicle', function(fullImpound, price)
    local vehicle = QBCore.Functions.GetClosestVehicle()
    local bodyDamage = math.ceil(GetVehicleBodyHealth(vehicle))
    local engineDamage = math.ceil(GetVehicleEngineHealth(vehicle))
    local totalFuel = exports['ps-fuel']:GetFuel(vehicle)
    if vehicle ~= 0 and vehicle then
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local vehpos = GetEntityCoords(vehicle)
        if #(pos - vehpos) < 5.0 and not IsPedInAnyVehicle(ped) then
           QBCore.Functions.Progressbar('impound', Lang:t('progressbar.impound'), 5000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = 'missheistdockssetup1clipboard@base',
                anim = 'base',
                flags = 1,
            }, {
                model = 'prop_notepad_01',
                bone = 18905,
                coords = { x = 0.1, y = 0.02, z = 0.05 },
                rotation = { x = 10.0, y = 0.0, z = 0.0 },
            },{
                model = 'prop_pencil_01',
                bone = 58866,
                coords = { x = 0.11, y = -0.02, z = 0.001 },
                rotation = { x = -120.0, y = 0.0, z = 0.0 },
            }, function() -- Play When Done
                local plate = QBCore.Functions.GetPlate(vehicle)
                TriggerServerEvent("police:server:Impound", plate, fullImpound, price, bodyDamage, engineDamage, totalFuel)
                while NetworkGetEntityOwner(vehicle) ~= 128 do  -- Ensure we have entity ownership to prevent inconsistent vehicle deletion
                    NetworkRequestControlOfEntity(vehicle)
                    Wait(100)
                end
                QBCore.Functions.DeleteVehicle(vehicle)
                TriggerEvent('QBCore:Notify', Lang:t('success.impounded'), 'success')
                ClearPedTasks(ped)
            end, function() -- Play When Cancel
                ClearPedTasks(ped)
                TriggerEvent('QBCore:Notify', Lang:t('error.canceled'), 'error')
            end)
        end
    end
end)

RegisterNetEvent('police:client:CheckStatus', function()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.job.type == "leo" then
            local player, distance = GetClosestPlayer()
            if player ~= -1 and distance < 5.0 then
                local playerId = GetPlayerServerId(player)
                QBCore.Functions.TriggerCallback('police:GetPlayerStatus', function(result)
                    if result then
                        for _, v in pairs(result) do
                            QBCore.Functions.Notify(''..v..'')
                        end
                    end
                end, playerId)
            else
                QBCore.Functions.Notify(Lang:t("error.none_nearby"), "error")
            end
        end
    end)
end)


-- RegisterNetEvent("police:client:VehicleMenuHeader", function (data)
--     currentSelection = GetClosestVehicleSpawn()
--     MenuGarage()
--     currentGarage = currentSelection
--     print(currentSelection)
-- end)


RegisterNetEvent("police:client:VehicleMenuHeader", function (data)
    print(json.encode(data))
    MenuGarage(data.spawn)
end)


RegisterNetEvent("police:client:ImpoundMenuHeader", function (data)
    MenuImpound(data.currentSelection)
    currentGarage = data.currentSelection
end)

--RegisterNetEvent("police:client:VehicleMenuHeader", function (data)
--    print(json.encode(data))
--    MenuGarage(data.spawn)
--end)

RegisterNetEvent('police:client:TakeOutImpound', function(data)
    if inImpound then
        local vehicle = data.vehicle
        TakeOutImpound(vehicle)
    end
end)

-- RegisterNetEvent('police:client:TakeOutVehicle', function(data)
--         local vehicle = data.vehicle
--         TakeOutVehicle(vehicle)
-- end)

--RegisterNetEvent('police:client:EvidenceStashDrawer', function(data)
--    local currentEvidence = data.currentEvidence
    --local pos = GetEntityCoords(PlayerPedId())
    --local takeLoc = Config.Locations["evidence"][currentEvidence]

--    if not takeLoc then return end

--    if #(pos - takeLoc) <= 1.0 then
--        local drawer = exports['qb-input']:ShowInput({
--            header = Lang:t('info.evidence_stash', {value = currentEvidence}),
--            submitText = "open",
--            inputs = {
--                {
--                    type = 'number',
--                    isRequired = true,
--                    name = 'slot',
--                    text = Lang:t('info.slot')
--                }
--            }
--        })
--        if drawer then
--            if not drawer.slot then return end
--            TriggerServerEvent("inventory:server:OpenInventory", "stash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = drawer.slot}), {
--                maxweight = 4000000,
--                slots = 500,
--            })
--            TriggerEvent("inventory:client:SetCurrentStash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = drawer.slot}))
--        end
--    else
--        exports['qb-menu']:closeMenu()
--    end
--end)

RegisterNetEvent('police:client:EvidenceStashDrawer', function(data)
    local currentEvidence = data.currentEvidence
    --local pos = GetEntityCoords(PlayerPedId())

    local drawer = exports['qb-input']:ShowInput({
        header = Lang:t('info.evidence_stash', {value = currentEvidence}),
        submitText = "open",
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'slot',
                text = Lang:t('info.slot')
            }
        }
    })
    if drawer then
        if not drawer.slot then return end
        TriggerServerEvent("inventory:server:OpenInventory", "stash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = drawer.slot}), {
            maxweight = 4000000,
            slots = 500,
        })
        TriggerEvent("inventory:client:SetCurrentStash", Lang:t('info.current_evidence', {value = currentEvidence, value2 = drawer.slot}))
    end
end)

RegisterNetEvent('qb-policejob:ToggleDuty', function()
    TriggerServerEvent("QBCore:ToggleDuty")
    TriggerServerEvent("police:server:UpdateCurrentCops")
    TriggerServerEvent("police:server:UpdateBlips")
end)

RegisterNetEvent('qb-police:client:scanFingerPrint', function()
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerId = GetPlayerServerId(player)
        TriggerServerEvent("police:server:showFingerprint", playerId)
    else
        QBCore.Functions.Notify(Lang:t("error.none_nearby"), "error")
    end
end)

RegisterNetEvent('qb-police:client:openArmoury', function()
    local authorizedItems = {
        label = Lang:t('menu.pol_armory'),
        slots = 30,
        items = {}
    }
    local index = 1
    for _, armoryItem in pairs(Config.Items.items) do
        for i=1, #armoryItem.authorizedJobGrades do
            if armoryItem.authorizedJobGrades[i] == PlayerJob.grade.level then
                authorizedItems.items[index] = armoryItem
                authorizedItems.items[index].slot = index
                index = index + 1
            end
        end
    end
    SetWeaponSeries()
    TriggerServerEvent("inventory:server:OpenInventory", "shop", "police", authorizedItems)
end)

RegisterNetEvent('qb-police:client:HelicopterSpawn', function(k)
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
    else
        local coords = Config.Locations["helicopter"][k]
        if not coords then coords = GetEntityCoords(PlayerPedId()) end
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            SetVehicleLivery(veh , 0)
            SetVehicleMod(veh, 0, 48)
            SetVehicleNumberPlateText(veh, "ZULU"..tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            exports['ps-fuel']:SetFuel(veh, 100.0)
            closeMenuFull()
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            SetVehicleEngineOn(veh, true, true)
        end, Config.PoliceHelicopter, coords, true)
    end
end)

RegisterNetEvent("qb-police:client:openStash", function()
    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
    TriggerEvent("inventory:client:SetCurrentStash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
end)

RegisterNetEvent('qb-police:client:openTrash', function()
    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policetrash", {
        maxweight = 4000000,
        slots = 300,
    })
    TriggerEvent("inventory:client:SetCurrentStash", "policetrash")
end)

--##### Threads #####--

local dutylisten = false
local function dutylistener()
    dutylisten = true
    CreateThread(function()
        while dutylisten do
            if PlayerJob.type == "leo" then
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent("QBCore:ToggleDuty")
                    TriggerServerEvent("police:server:UpdateCurrentCops")
                    TriggerServerEvent("police:server:UpdateBlips")
                    dutylisten = false
                    break
                end
            else
                break
            end
            Wait(0)
        end
    end)
end

-- Personal Stash Thread
local function stash()
    CreateThread(function()
        while true do
            Wait(0)
            if inStash and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
                    TriggerEvent("inventory:client:SetCurrentStash", "policestash_"..QBCore.Functions.GetPlayerData().citizenid)
                    break
                end
            else
                break
            end
        end
    end)
end

-- Police Trash Thread
local function trash()
    CreateThread(function()
        while true do
            Wait(0)
            if inTrash and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent("inventory:server:OpenInventory", "stash", "policetrash", {
                        maxweight = 4000000,
                        slots = 300,
                    })
                    TriggerEvent("inventory:client:SetCurrentStash", "policetrash")
                    break
                end
            else
                break
            end
        end
    end)
end

-- Fingerprint Thread
local function fingerprint()
    CreateThread(function()
        while true do
            Wait(0)
            if inFingerprint and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    TriggerEvent("qb-police:client:scanFingerPrint")
                    break
                end
            else
                break
            end
        end
    end)
end

-- Armoury Thread
local function armoury()
    CreateThread(function()
        while true do
            Wait(0)
            if inArmoury and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    TriggerEvent("qb-police:client:openArmoury")
                    break
                end
            else
                break
            end
        end
    end)
end

-- Helicopter Thread
local function heli()
    CreateThread(function()
        while true do
            Wait(0)
            if inHelicopter and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    TriggerEvent("qb-police:client:spawnHelicopter")
                    break
                end
            else
                break
            end
        end
    end)
end

-- Police Impound Thread
local function impound()
    CreateThread(function()
        while true do
            Wait(0)
            if inImpound and PlayerJob.type == "leo" then
                if PlayerJob.onduty then sleep = 5 end
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    if IsControlJustReleased(0, 38) then
                        QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
                        break
                    end
                end
            else
                break
            end
        end
    end)
end

-- Police Garage Thread
--local function garage()
--    CreateThread(function()
--        while true do
--            Wait(0)
--            if inGarage and PlayerJob.type == "leo" then
--                if PlayerJob.onduty then sleep = 5 end
--                if IsPedInAnyVehicle(PlayerPedId(), false) then
--                    if IsControlJustReleased(0, 38) then
--                        QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
--                        break
--                    end
--                end
--            else
--                break
--            end
--        end
--    end)
--end





if Config.UseTarget then
    CreateThread(function()
        -- Toggle Duty
        for k, v in pairs(Config.Locations["duty"]) do
            QBCore.Functions.LoadModel('s_m_y_cop_01')
            while not HasModelLoaded('s_m_y_cop_01') do
                Wait(100)
            end
            dutyPed = CreatePed(0, 's_m_y_cop_01', v.ped.x, v.ped.y, v.ped.z-1.0, v.ped.w, false, true)
            TaskStartScenarioInPlace(dutyPed, true)
            FreezeEntityPosition(dutyPed, true)
            SetEntityInvincible(dutyPed, true)
            SetBlockingOfNonTemporaryEvents(dutyPed, true)
            TaskStartScenarioInPlace(dutyPed, "WORLD_HUMAN_GUARD_STAND", 0, true)
            exports['qb-target']:AddBoxZone("PoliceDuty_"..k, vector4(v.ped.x, v.ped.y, v.ped.z, v.ped.w), 1, 1, {
                name = "PoliceDuty_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.ped.z - 1,
                maxZ = v.ped.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "qb-policejob:ToggleDuty",
                        icon = "fas fa-sign-in-alt",
                        label = "Sign In",
                        job = "police",
                    },
                },
                distance = 4.0
            })
        end

        -- Personal Stash
        for k, v in pairs(Config.Locations["stash"]) do
            QBCore.Functions.LoadModel('ig_andreas')
            while not HasModelLoaded('ig_andreas') do
                Wait(100)
            end
            stashPed = CreatePed(0, 'ig_andreas',v.stash.x, v.stash.y, v.stash.z-1.0, v.stash.w, false, true)
            TaskStartScenarioInPlace(stashPed, true)
            FreezeEntityPosition(stashPed, true)
            SetEntityInvincible(stashPed, true)
            SetBlockingOfNonTemporaryEvents(stashPed, true)
            TaskStartScenarioInPlace(stashPed, "WORLD_HUMAN_GUARD_STAND", 0, true)
            exports['qb-target']:AddBoxZone("PoliceStash_"..k, vector4(v.stash.x, v.stash.y, v.stash.z, v.stash.w), 1.1, 1.1, {
                name = "PoliceStash_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.stash.z - 1,
                maxZ = v.stash.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "qb-police:client:openStash",
                        icon = "fas fa-dungeon",
                        label = "Open Personal Stash",
                        job = "police",
                    },
                },
                distance = 2.0
            })
        end
	
	        -- evidence
        for k, v in pairs(Config.Locations["evidence"]) do
            QBCore.Functions.LoadModel('s_m_y_sheriff_01')
            while not HasModelLoaded('s_m_y_sheriff_01') do
                Wait(100)
            end
            evidencePed = CreatePed(0, 's_m_y_sheriff_01', v.evidence.x, v.evidence.y, v.evidence.z-1.0, v.evidence.w, false, true)
            TaskStartScenarioInPlace(evidencePed, true)
            FreezeEntityPosition(evidencePed, true)
            SetEntityInvincible(evidencePed, true)
            SetBlockingOfNonTemporaryEvents(evidencePed, true)
            TaskStartScenarioInPlace(evidencePed, "WORLD_HUMAN_GUARD_STAND", 0, true) 
            exports['qb-target']:AddBoxZone("evidenceCombo_"..k, vector4(v.evidence.x, v.evidence.y, v.evidence.z, v.evidence.w), 1.0, 1.0, {
                name = "evidenceCombo_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.evidence.z - 1,
                maxZ = v.evidence.z + 1,
            }, {
                options = {
                    {  
                        type = "client",
                        event = "police:client:EvidenceStashDrawer",
                        targeticon = "fas fa-dungeon",
                        icon = "fas fa-dungeon",
                        label = "Store Evidence",
                        job = {
                            ["police"] = 0,
                            ["sheriff"] = 0,
                            ["trooper"] = 0,
                        },
                    },
                },
                distance = 4.5
            })
        end

        -- Police Trash
        for k, v in pairs(Config.Locations["trash"]) do
            exports['qb-target']:AddBoxZone("PoliceTrash_"..k, vector3(v.x, v.y, v.z), 1, 1.75, {
                name = "PoliceTrash_"..k,
                heading = 11,
                debugPoly = true,
                minZ = v.z - 1,
                maxZ = v.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "qb-police:client:openTrash",
                        icon = "fas fa-trash",
                        label = "Open Trash",
                        job = "police",
                    },
                },
                distance = 1.5
            })
        end

        -- Fingerprint
        for k, v in pairs(Config.Locations["fingerprint"]) do
            QBCore.Functions.LoadModel('ig_michelle')
            while not HasModelLoaded('ig_michelle') do
                Wait(100)
            end
            fingerPed = CreatePed(0, 'ig_michelle', v.finger.x, v.finger.y, v.finger.z-1.0, v.finger.w, false, true)
            TaskStartScenarioInPlace(fingerPed, true)
            FreezeEntityPosition(fingerPed, true)
            SetEntityInvincible(fingerPed, true)
            SetBlockingOfNonTemporaryEvents(fingerPed, true)
            TaskStartScenarioInPlace(fingerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
            exports['qb-target']:AddBoxZone("PoliceFingerprint_"..k, vector4(v.finger.x, v.finger.y, v.finger.z, v.finger.w), 1, 1, {
                name = "PoliceFingerprint_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.finger.z - 1,
                maxZ = v.finger.z + 1,
            }, {
                options = {
                    {
                        targeticon = "fas fa-fingerprint",
                        type = "client",
                        event = "qb-police:client:scanFingerPrint",
                        icon = "fas fa-fingerprint",
                        label = "Open Fingerprint",
                        job = "police",
                    },
                },
                distance = 3.0
            })
        end

        -- Armoury
        for k, v in pairs(Config.Locations["armory"]) do
            QBCore.Functions.LoadModel('s_m_y_marine_01')
            while not HasModelLoaded('s_m_y_marine_01') do
                Wait(100)
            end
            armoryPed = CreatePed(0, 's_m_y_marine_01', v.armory.x, v.armory.y, v.armory.z-1.0, v.armory.w, false, true)
            TaskStartScenarioInPlace(armoryPed, true)
            FreezeEntityPosition(armoryPed, true)
            SetEntityInvincible(armoryPed, true)
            SetBlockingOfNonTemporaryEvents(armoryPed, true)
            exports['qb-target']:AddBoxZone("PoliceArmory_"..k, vector4(v.armory.x, v.armory.y, v.armory.z, v.armory.w), 1, 1, {
                name = "PoliceArmory_"..k,
                heading = 11,
                debugPoly = false,
                minZ = v.armory.z - 1,
                maxZ = v.armory.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "qb-police:client:openArmoury",
                        icon = "fas fa-swords",
                        label = "Open Armory",
                        job = "police",
                    },
                },
                distance = 4.0
            })
        end
end)

else

    -- Toggle Duty
    local dutyZones = {}
    for _, v in pairs(Config.Locations["duty"]) do
        dutyZones[#dutyZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 1.75, 1, {
            name="box_zone",
            debugPoly = flase,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local dutyCombo = ComboZone:Create(dutyZones, {name = "dutyCombo", debugPoly = false})
    dutyCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            dutylisten = true
            if not PlayerJob.onduty then
                exports['qb-core']:DrawText(Lang:t('info.on_duty'),'left')
                dutylistener()
            else
                exports['qb-core']:DrawText(Lang:t('info.off_duty'),'left')
                dutylistener()
            end
        else
            dutylisten = false
            exports['qb-core']:HideText()
        end
    end)

    -- Personal Stash
    local stashZones = {}
    for _, v in pairs(Config.Locations["stash"]) do
        stashZones[#stashZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 1.5, 1.5, {
            name="box_zone",
            debugPoly = true,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local stashCombo = ComboZone:Create(stashZones, {name = "stashCombo", debugPoly = false})
    stashCombo:onPlayerInOut(function(isPointInside, _, _)
        if isPointInside then
            inStash = true
            if PlayerJob.type == 'leo' and PlayerJob.onduty then
                exports['qb-core']:DrawText(Lang:t('info.stash_enter'), 'left')
                stash()
            end
        else
            inStash = false
            exports['qb-core']:HideText()
        end
    end)

    -- Police Trash
    local trashZones = {}
    for _, v in pairs(Config.Locations["trash"]) do
        trashZones[#trashZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 1, 1.75, {
            name="box_zone",
            debugPoly = true,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local trashCombo = ComboZone:Create(trashZones, {name = "trashCombo", debugPoly = false})
    trashCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inTrash = true
            if PlayerJob.type == 'leo' and PlayerJob.onduty then
                exports['qb-core']:DrawText(Lang:t('info.trash_enter'),'left')
                trash()
            end
        else
            inTrash = false
            exports['qb-core']:HideText()
        end
    end)

    -- Fingerprints
    local fingerprintZones = {}
    for _, v in pairs(Config.Locations["fingerprint"]) do
        fingerprintZones[#fingerprintZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 2, 1, {
            name="box_zone",
            debugPoly = true,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local fingerprintCombo = ComboZone:Create(fingerprintZones, {name = "fingerprintCombo", debugPoly = false})
    fingerprintCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inFingerprint = true
            if PlayerJob.type == 'leo' and PlayerJob.onduty then
                exports['qb-core']:DrawText(Lang:t('info.scan_fingerprint'),'left')
                fingerprint()
            end
        else
            inFingerprint = false
            exports['qb-core']:HideText()
        end
    end)

    -- Armoury
    local armouryZones = {}
    for _, v in pairs(Config.Locations["armory"]) do
        armouryZones[#armouryZones+1] = BoxZone:Create(
            vector3(vector3(v.x, v.y, v.z)), 5, 1, {
            name="box_zone",
            debugPoly = true,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
    end

    local armouryCombo = ComboZone:Create(armouryZones, {name = "armouryCombo", debugPoly = false})
    armouryCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inArmoury = true
            if PlayerJob.type == 'leo' and PlayerJob.onduty then
                exports['qb-core']:DrawText(Lang:t('info.enter_armory'),'left')
                armoury()
            end
        else
            inArmoury = false
            exports['qb-core']:HideText()
        end
    end)

end




CreateThread(function()
    -- Evidence Storage
    --local evidenceZones = {}
    --for _, v in pairs(Config.Locations["evidence"]) do
    --    evidenceZones[#evidenceZones+1] = BoxZone:Create(
    --        vector3(vector3(v.x, v.y, v.z)), 2, 1, {
    --        name="box_zone",
    --        debugPoly = false,
    --       minZ = v.z - 1,
    --        maxZ = v.z + 1,
    --    })
    --end


    --local evidenceCombo = ComboZone:Create(evidenceZones, {name = "evidenceCombo", debugPoly = false})
    --evidenceCombo:onPlayerInOut(function(isPointInside)
    --    if isPointInside then
    --        if PlayerJob.type == "leo" and PlayerJob.onduty then
    --            local currentEvidence = 0
    --            local pos = GetEntityCoords(PlayerPedId())

    --            for k, v in pairs(Config.Locations["evidence"]) do
    --                if #(pos - v) < 2 then
    --                    currentEvidence = k
    --                end
    --            end
    --           exports['qb-menu']:showHeader({
    --                {
    --                    header = Lang:t('info.evidence_stash', {value = currentEvidence}),
    --                    params = {
    --                        event = 'police:client:EvidenceStashDrawer',
    --                        args = {
    --                            currentEvidence = currentEvidence
    --                        }
    --                    }
    --                }
    --            })
    --        end
    --    else
    --        exports['qb-menu']:closeMenu()
    --    end
    --end)

    -- Helicopter
    --local helicopterZones = {}
    --for _, v in pairs(Config.Locations["helicopter"]) do
    --    helicopterZones[#helicopterZones+1] = BoxZone:Create(
    --        vector3(vector3(v.x, v.y, v.z)), 10, 10, {
    --        name="box_zone",
    --        debugPoly = true,
    --        minZ = v.z - 1,
    --        maxZ = v.z + 1,
    --    })
    --end

    --local helicopterCombo = ComboZone:Create(helicopterZones, {name = "helicopterCombo", debugPoly = false})
    --helicopterCombo:onPlayerInOut(function(isPointInside)
    --    if isPointInside then
    --        inHelicopter = true
    --        if PlayerJob.type == 'leo' and PlayerJob.onduty then
    --            if IsPedInAnyVehicle(PlayerPedId(), false) then
    --                exports['qb-core']:HideText()
    --                exports['qb-core']:DrawText(Lang:t('info.store_heli'), 'left')
    --                heli()
    --            else
    --                exports['qb-core']:DrawText(Lang:t('info.take_heli'), 'left')
    --                heli()
    --            end
    --        end
    --    else
    --        inHelicopter = false
    --        exports['qb-core']:HideText()
    --    end
    --end)

    -- Police Impound
--    local impoundZones = {}
--    for _, v in pairs(Config.Locations["impound"]) do
--        impoundZones[#impoundZones+1] = BoxZone:Create(
--            vector4(v.impound.x, v.impound.y, v.impound.z, v.impound.w), 1, 1, {
--            name="box_zone",
--            debugPoly = true,
--            minZ = v.impound.z - 1,
--            maxZ = v.impound.z + 1,
--            heading = 180,
--        })
--    end

--    local impoundCombo = ComboZone:Create(impoundZones, {name = "impoundCombo", debugPoly = false})
--    impoundCombo:onPlayerInOut(function(isPointInside, point)
--        if isPointInside then
--            inImpound = true
--            if PlayerJob.type == 'leo' and PlayerJob.onduty then
--                if IsPedInAnyVehicle(PlayerPedId(), false) then
--                    exports['qb-core']:DrawText(Lang:t('info.impound_veh'), 'left')
--                    impound()
--                else
--                    local currentSelection = 0
--
--                    for k, v in pairs(Config.Locations["impound"]) do
--                        if #(point - vector3(v.x, v.y, v.z)) < 4 then
--                            currentSelection = k
--                        end
--                    end
--                    exports['qb-menu']:showHeader({
--                        {
--                            header = Lang:t('menu.pol_impound'),
--                            params = {
--                                event = 'police:client:ImpoundMenuHeader',
--                                args = {
--                                    currentSelection = currentSelection,
--                                }
--                            }
--                        }
--                    })
--                end
--            end
--        else
--            inImpound = false
--            exports['qb-menu']:closeMenu()
--            exports['qb-core']:HideText()
--        end
--    end)


    -- Police Garage
    CreateThread(function()
        QBCore.Functions.LoadModel('ig_trafficwarden')
        while not HasModelLoaded('ig_trafficwarden') do
            Wait(100)
        end
        for k, v in pairs(Config.Locations["vehicleped"]) do
            customped = CreatePed(0, 'ig_trafficwarden', v.coords.x, v.coords.y, v.coords.z-1.0, v.coords.w, false, true)
            TaskStartScenarioInPlace(customped, true)
            FreezeEntityPosition(customped, true)
            SetEntityInvincible(customped, true)
            SetBlockingOfNonTemporaryEvents(customped, true)
            TaskStartScenarioInPlace(customped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
            exports['qb-target']:AddTargetEntity(customped, {
                options = {
                    {
                        icon = 'fa-solid fa-warehouse',
                        label = 'Open Garage',
                        type = "client",
                        event = "police:client:VehicleMenuHeader",
                        job = {
                            ["police"] = 0,
                            ["bcso"] = 0,
                            ["sasp"] = 0,
                        },
                        spawn = v.spawn
                    },
                    {
                        icon = 'fa-solid fa-car',
                        label = 'Store Vehicle',
                        type = "client",
                        event  = "qb-policejob:returnveh",
                        job = {
                            ["police"] = 0,
                            ["bcso"] = 0,
                            ["sasp"] = 0,
                        }
                    }
                },
                distance = 4.0
            })
        end
    end)
    
    local VehicleTable = {
        ["police"] = {
            "police",
            "police2",
            "police3",
            "police4",
            "policeb",
            "policet",
        },
        ["sherrif"] = {
            "sheriff",
            "sheriff2",
        },
        ["bsco"] = {
            "police2"
        }
    }
    RegisterNetEvent("police:client:VehicleMenuHeader", function(data)
        local Menu = {
            {
                header = Lang:t('menu.garage_title'),
                isMenuHeader = true,
                icon = "fas fa-warehouse",
            }
        }
        for k,v in pairs(VehicleTable) do
            Menu[#Menu+1] = {
                header = k:upper(),
                txt = "Select category for vehicles",
                icon = "fa-solid fa-shield",
                params = {
                    event = "police:client:veh-category-selected",
                    args = {
                        category = k,
                        location = data.spawn,
                    }
                }
            }
        end
        exports['qb-menu']:openMenu(Menu)
    end)
    
    RegisterNetEvent('police:client:veh-category-selected', function(data)
        local newtable = data.category
        local result = VehicleTable[newtable]
        if not result then return end
        local Menu = {
            {
                header = Lang:t('menu.garage_title'),
                isMenuHeader = true,
                icon = "fas fa-warehouse",
            }
        }
        for k,v in pairs(result) do
            Menu[#Menu+1] = {
                header = v:upper(),
                txt = "",
                icon = "fa-solid fa-shield",
                params = {
                    event = "police:client:TakeOutVehicle",
                    args = {
                        currentSelection = data.location,
                        model = v,
                    }
                }
            }
        end
        exports['qb-menu']:openMenu(Menu)
    end)
    
    RegisterNetEvent("police:client:TakeOutVehicle", function(data)
        local VehicleSpawnCoord = data.currentSelection
        QBCore.Functions.SpawnVehicle(data.model, function(veh)
            print("callback")
            local plate = "CAR" .. math.random(1111, 5555)
            SetVehicleNumberPlateText(veh, plate)
            SetEntityHeading(veh, VehicleSpawnCoord.w)
            SetEntityAsMissionEntity(veh, true, true)
            SetCarItemsInfo()
            exports['ps-fuel']:SetFuel(veh, 100.0)
            TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(veh))
            TriggerServerEvent("inventory:server:addTrunkItems", QBCore.Functions.GetPlate(veh), Config.CarItems)
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        end, vector3(VehicleSpawnCoord.x,VehicleSpawnCoord.y,VehicleSpawnCoord.z), true)
    end)
    
-- return vehicle
RegisterNetEvent('qb-policejob:returnveh', function()
    local ped = PlayerPedId()
    local car = GetVehiclePedIsIn(PlayerPedId(),true)
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, car, 1)
       Wait(2000)
        QBCore.Functions.Notify('Vehicle Stored!')
        DeleteVehicle(car)
        DeleteEntity(car)
    else
        QBCore.Functions.Notify("You Are Not In Any Vehicle !", "error")
    end
end)

-- impound
CreateThread(function()
    QBCore.Functions.LoadModel('ig_tomcasino')
    while not HasModelLoaded('ig_tomcasino') do
        Wait(100)
    end
    for k, v in pairs(Config.Locations["impound"]) do
        impoundPed = CreatePed(0, 'ig_tomcasino', v.impound.x, v.impound.y, v.impound.z-1.0, v.impound.w, false, true)
        TaskStartScenarioInPlace(impoundPed, true)
        FreezeEntityPosition(impoundPed, true)
        SetEntityInvincible(impoundPed, true)
        SetBlockingOfNonTemporaryEvents(impoundPed, true)
        TaskStartScenarioInPlace(impoundPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
        exports['qb-target']:AddTargetEntity(impoundPed, {
            options = {
                {
                    icon = 'fa-solid fa-warehouse',
                    label = 'Open Impound',
                    type = "client",
                    event = "police:client:ImpoundMenuHeader",
                    job = {
                        ["police"] = 0,
                        ["bcso"] = 0,
                        ["sasp"] = 0,
                    },
                    vehicle = v.vehicle,
                }
            },
            distance = 2.0
        })
    end
end)

RegisterNetEvent("police:client:ImpoundMenuHeader", function (data)
    MenuImpound(data.currentSelection, data.vehicle)
    currentGarage = data.currentSelection
end)


function MenuImpound(currentSelection, coords)
    local impoundMenu = {
        {
            header = Lang:t('menu.impound'),
            isMenuHeader = true
        }
    }
    QBCore.Functions.TriggerCallback("police:GetImpoundedVehicles", function(result)
        local shouldContinue = false
        if result == nil then
            QBCore.Functions.Notify(Lang:t("error.no_impound"), "error", 5000)
        else
            shouldContinue = true
            for _ , v in pairs(result) do
                local enginePercent = QBCore.Shared.Round(v.engine / 10, 0)
                local currentFuel = v.fuel
                local vname = QBCore.Shared.Vehicles[v.vehicle].name

                impoundMenu[#impoundMenu+1] = {
                    header = vname.." ["..v.plate.."]",
                    txt =  Lang:t('info.vehicle_info', {value = enginePercent, value2 = currentFuel}),
                    params = {
                        event = "police:client:TakeOutImpound",
                        args = {
                            vehicle = v,
                            coords = coords,
                            currentSelection = currentSelection
                        }
                    }
                }
            end
        end


        if shouldContinue then
            impoundMenu[#impoundMenu+1] = {
                header = Lang:t('menu.close'),
                txt = "",
                params = {
                    event = "qb-menu:client:closeMenu"
                }
            }
            exports['qb-menu']:openMenu(impoundMenu)
        end
    end)

end
    -- Impound
    RegisterNetEvent('police:client:TakeOutImpound', function(data)
        local vehicle = data.vehicle
        local coords = data.coords
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                QBCore.Functions.SetVehicleProperties(veh, properties)
                SetVehicleNumberPlateText(veh, vehicle.plate)
                SetVehicleDirtLevel(veh, 0.0)
                SetEntityHeading(veh, coords.w) 
                exports['ps-fuel']:SetFuel(veh, vehicle.fuel)
                doCarDamage(veh, vehicle)
                TriggerServerEvent('police:server:TakeOutImpound', vehicle.plate, currentGarage)
                closeMenuFull()
                TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                SetVehicleEngineOn(veh, true, true)
            end, vehicle.plate)
        end, vehicle.vehicle, coords, true)
    end)
end)

-- Helicopter
    CreateThread(function()
        QBCore.Functions.LoadModel('ig_casey')
    while not HasModelLoaded('ig_casey') do
        Wait(100)
    end
    for k, v in pairs(Config.Locations["helicopter"]) do
        helicopterPed = CreatePed(0, 'ig_casey', v.heliped.x, v.heliped.y, v.heliped.z-1.0, v.heliped.w, false, true)
        TaskStartScenarioInPlace(helicopterPed, true)
        FreezeEntityPosition(helicopterPed, true)
        SetEntityInvincible(helicopterPed, true)
        SetBlockingOfNonTemporaryEvents(helicopterPed, true)
        TaskStartScenarioInPlace(helicopterPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
        exports['qb-target']:AddTargetEntity(helicopterPed, {
            options = {
                {
                    icon = 'fa-solid fa-helicopter',
                    label = 'Open Heli Garage',
                    type = "client",
                    event = "qb-police:client:HelicopterSpawn",
                    job = {
                        ["police"] = 0,
                        ["bcso"] = 0,
                        ["sasp"] = 0,
                    },
                    currentSelection = v,
                }
            },
            distance = 4.0
        })
    end
end)

RegisterNetEvent('police:client:TakeOutVehicle', function(data)
    --local coords = Config.Locations["helicopter"][k]
    local VehicleSpawnCoord = data.currentSelection
    --QBCore.Functions.SpawnVehicle(data.model, function(veh)
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        SetVehicleLivery(veh , 0)
        SetVehicleMod(veh, 0, 48)
        SetVehicleNumberPlateText(veh, "ZULU"..tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, VehicleSpawnCoord.w)
        SetVehicleDirtLevel(veh, 0.0)
        exports['ps-fuel']:SetFuel(veh, 100.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        SetVehicleEngineOn(veh, true, true)
    end, vector3(VehicleSpawnCoord.x,VehicleSpawnCoord.y,VehicleSpawnCoord.z), true)
end)
--    local garageZones = {}
--    for _, v in pairs(Config.Locations["vehicle"]) do
--        garageZones[#garageZones+1] = BoxZone:Create(
--            vector3(v.x, v.y, v.z), 5, 5, {
--            name="box_zone",
--            debugPoly = true,
--            minZ = v.z - 1,
--            maxZ = v.z + 1,
--        })
--    end
--
--    local garageCombo = ComboZone:Create(garageZones, {name = "garageCombo", debugPoly = false})
--    garageCombo:onPlayerInOut(function(isPointInside, point)
--        if isPointInside then
--            inGarage = true
--            if PlayerJob.type == 'leo' then
--                if IsPedInAnyVehicle(PlayerPedId(), false) then
--                    exports['qb-core']:DrawText(Lang:t('info.store_veh'), 'left')
--		            garage()
--                end
--                
--            end
--        else
--            inGarage = false
--            exports['qb-menu']:closeMenu()
--            exports['qb-core']:HideText()
--        end
--    end)
--end)

    -- evidence
--        local coords = vector4(445.41, -988.94, 25.7, 273.0),
--        QBCore.Functions.LoadModel('s_m_y_sheriff_01')
--        while not HasModelLoaded('s_m_y_sheriff_01') do
--            Wait(100)
--        end
--        evidencePed = CreatePed(0, 's_m_y_sheriff_01', coords.x, coords.y, coords.z-1.0, coords.w, false, true)
--        TaskStartScenarioInPlace(evidencePed, true)
--        FreezeEntityPosition(evidencePed, true)
--        SetEntityInvincible(evidencePed, true)
--        SetBlockingOfNonTemporaryEvents(evidencePed, true)
--        TaskStartScenarioInPlace(evidencePed, "WORLD_HUMAN_GUARD_STAND", 0, true)
--        exports['qb-target']:AddBoxZone("PoliceEvidence", vector4(coords.x, coords.y, coords.z, coords.w), 1, 1, {
--            name = "PoliceEvidence",
--            heading = 11,
--            debugPoly = false,
--            minZ = coords.z - 1,
--            maxZ = coords.z + 1,
--        }, {
--            options = {
--                {
--                    
--                    type = "client",
--                    event = "qb-policejob:client:EvidenceStashDrawer",
--                    icon = "fas fa-sign-in-alt",
--                    label = "Open Evidence",
--                    job = "police",
--                },
--            },
--            distance = 4.0
--        })
--    end)




