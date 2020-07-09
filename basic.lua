ESX = nil
local PlayerData = {}
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0) 
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
    end
    
	PlayerData = ESX.GetPlayerData()
end)


RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

RMenu.Add('rGarage', 'main', RageUI.CreateMenu("Garage", ""))
RMenu:Get('rGarage', 'main'):SetSubtitle("~b~Garage de service")
RMenu:Get('rGarage', 'main').EnableMouse = false
RMenu:Get('rGarage', 'main').Closed = function()
    -- TODO Perform action
end;




local garage = {
    {
        job = "ambulance",
        pos = vector3(333.9856, -561.8801, 28.74377),
        sortieDeVeh = {
            {pos = vector3(317.1914, -553.4578, 28.51229),heading = 270.52117919922,},
            {pos = vector3(317.6855, -550.6038, 28.51195),heading = 268.94079589844,},
            {pos = vector3(317.7473, -547.7618, 28.51319),heading = 270.07995605469,},
            {pos = vector3(317.0062, -545.0537, 28.51136),heading = 269.66311645508,},
            {pos = vector3(320.8414, -542.4967, 28.51235),heading = 180.45452880859,},
            {pos = vector3(323.8896, -542.9167, 28.51234),heading = 178.57322692871,},
            {pos = vector3(326.8361, -542.9973, 28.51259),heading = 178.55476379395,},
            {pos = vector3(329.4638, -543.2396, 28.51212),heading = 180.05319213867,},
            {pos = vector3(332.445, -542.9022, 28.51195),heading = 179.62738037109,},
            {pos = vector3(335.0175, -543.2535, 28.51184),heading = 180.27465820313,},
        },
        vehs = {
            {
                nom = "Ford Explorer",
                spawn = "ems1",
            },
            {
                nom = "Ambulance 1",
                spawn = "ambulance22",
            },
            {
                nom = "Ambulance 2",
                spawn = "lsambulance",
            },
        },
    },

}


local GarageActuelData = {}
Citizen.CreateThread(function()
    while ESX == nil do Wait(100) end
    while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
    end
    local attente = 150
    while true do
        Wait(attente)
        local pPed = GetPlayerPed(-1)
        local pCoords = GetEntityCoords(pPed)
        for k,v in pairs(garage) do
            local dst = GetDistanceBetweenCoords(v.pos, pCoords, true)
            if PlayerData.job.name == v.job then
                if dst <= 3.0 then
                    attente = 1
                    ShowHelpNotification("Appuie sur ~INPUT_PICKUP~ pour ouvrir le garage")
                    if IsControlJustReleased(1, 38) then
                        GarageActuelData = v
                        RageUI.Visible(RMenu:Get('rGarage', 'main'), not RageUI.Visible(RMenu:Get('rGarage', 'main')))
                    end
                    break
                else
                    attente = 150
                end
            end
        end
    end
end)


RageUI.CreateWhile(1.0, true, function()
    if RageUI.Visible(RMenu:Get('rGarage', 'main')) then
        RageUI.DrawContent({ header = true, glare = true, instructionalButton = true }, function()
            RageUI.Button("Ranger ce véhicule", nil, { RightLabel = "→→→" }, true, function(_, _, Selected)
                if (Selected) then
                    RangerVeh()
                    RageUI.CloseAll()
                end
            end)
            for k,v in pairs(GarageActuelData.vehs) do
                RageUI.Button(v.nom, nil, {}, true, function(_, _, Selected)
                    if (Selected) then
                        local found, zone, heading = CheckSpawnData(GarageActuelData.sortieDeVeh)
                        if found then
                            spawnVeh(v.spawn, zone, heading)
                            RageUI.CloseAll()
                        end
                    end
                end)
            end
        end, function()
            ---Panels
        end)
    end
end, 1)



function CheckSpawnData(data)
    local found = false
    local essaiMax = #data * 2
    local essai = 0
    local pos = vector3(10.0, 10.10, 10.10)
    local heading = 100.0
    while not found do
        Wait(100)
        local r = math.random(1, #data)
        local _pos = data[r]
        if ESX.Game.IsSpawnPointClear(_pos.pos, 2.0) then
            pos = _pos.pos
            heading = _pos.heading
            found = true
        end
        essai = essai + 1
        if essai > essaiMax then
            break
        end
    end
    return found, pos, heading
end

function spawnVeh(model, zone, heading)
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do Wait(10) end
    local veh = CreateVehicle(GetHashKey(model), zone, heading, 1, 0)
    for i = 0,14 do
        SetVehicleExtra(veh, i, 0)
    end
    SetVehicleDirtLevel(veh, 0.1)
    TriggerEvent("RS_KEY:GiveKey", GetVehicleNumberPlateText(veh))
    --TaskWarpPedIntoVehicle(GetPlayerPed(-1), veh, -1)
end

function RangerVeh()
    local vehicule = nil
    if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
        vehicule = GetVehiclePedIsIn(GetPlayerPed(-1), 0)
    else
        vehicule = GetVehiclePedIsIn(GetPlayerPed(-1), 1)
    end

    TriggerServerEvent("DeleteEntity", NetworkGetNetworkIdFromEntity(vehicule))
end
