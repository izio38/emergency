--[[
################################################################
- Creator: Jyben
- Date: 01/05/2017
- Url: https://github.com/Jyben/emergency
- Licence: Apache 2.0
################################################################
--]]

local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local isInService = false
local jobId = -1

--[[
################################
            THREADS
################################
--]]

Citizen.CreateThread(
	function()
		local x = 1155.26
		local y = -1520.82
		local z = 34.84

		while true do
			Citizen.Wait(1)

			local playerPos = GetEntityCoords(GetPlayerPed(-1), true)

			if (Vdist(playerPos.x, playerPos.y, playerPos.z, x, y, z) < 100.0) then
				-- Service
				DrawMarker(1, x, y, z - 1, 0, 0, 0, 0, 0, 0, 3.0001, 3.0001, 1.5001, 255, 165, 0,165, 0, 0, 0,0)

				if (Vdist(playerPos.x, playerPos.y, playerPos.z, x, y, z) < 2.0) then
					DisplayHelpText("Press ~INPUT_CONTEXT~ to start your job")

					if (IsControlJustReleased(1, 51)) then
						TriggerServerEvent('es_em:sv_getService')
					end
				end
			end
		end
end)

Citizen.CreateThread(
	function()
		local x = 1140.41
		local y = -1608.15
		local z = 34.6939

		while true do
			Citizen.Wait(1)

			local playerPos = GetEntityCoords(GetPlayerPed(-1), true)

			if (Vdist(playerPos.x, playerPos.y, playerPos.z, x, y, z) < 100.0) and isInService then
				-- Service car
				DrawMarker(1, x, y, z - 1, 0, 0, 0, 0, 0, 0, 3.0001, 3.0001, 1.5001, 255, 165, 0,165, 0, 0, 0,0)

				if (Vdist(playerPos.x, playerPos.y, playerPos.z, x, y, z) < 2.0) then
					DisplayHelpText("Press ~INPUT_CONTEXT~ to get an emergency car")

					if (IsControlJustReleased(1, 51)) then
						SpawnAmbulance()
					end
				end
			end
		end
end)

--[[
################################
            EVENTS
################################
--]]

RegisterNetEvent('es_em:sendEmergencyToDocs')
AddEventHandler('es_em:sendEmergencyToDocs',
	function(reason, playerIDInComa, x, y, z, sourcePlayerInComa)
		local job = 'emergency'
		local callAlreadyTaken = false

		RegisterNetEvent('es_em:callTaken')
		AddEventHandler('es_em:callTaken',
			function(playerName, playerID)
				callAlreadyTaken = true
				SendNotification('L\'appel a été pris par ' .. playerName)
				if PlayerId() == playerID then
					StartEmergency(x, y, z, playerIDInComa, sourcePlayerInComa)
				end
		end)

		Citizen.CreateThread(
			function()
				if isInService then
					local controlPressed = false
					SendNotification('<b>URGENCE | Raison: </b>' .. reason)
					SendNotification('Appuyer sur Y pour prendre l\'appel ou N pour le refuser')
					while not controlPressed and not callAlreadyTaken do
						Citizen.Wait(0)
						if IsControlPressed(1, Keys["Y"]) and not callAlreadyTaken then
							callAlreadyTaken = true
							controlPressed = true
							TriggerServerEvent('es_em:getTheCall', GetPlayerName(PlayerId()), PlayerId())
						elseif IsControlPressed(1, Keys["N"]) then
							callAlreadyTaken = true
							controlPressed = true
							SendNotification('Vous avez rejeté l\'appel')
						end
					end
				end
		end)
	end)

RegisterNetEvent('es_em:cl_resurectPlayer')
AddEventHandler('es_em:cl_resurectPlayer',
	function()
		SendNotification('Vous avez été réanimé')
		local playerPed = GetPlayerPed(-1)
		ResurrectPed(playerPed)
		SetEntityHealth(playerPed, GetPedMaxHealth(playerPed)/2)
		ClearPedTasksImmediately(playerPed)
	end
)

RegisterNetEvent('es_em:cl_setService')
AddEventHandler('es_em:cl_setService',
	function(p_jobId)
		jobId = p_jobId
		GetService()
	end
)

--[[
################################
        BUSINESS METHODS
################################
--]]

function SpawnAmbulance()
	Citizen.Wait(0)
	local myPed = GetPlayerPed(-1)
	local player = PlayerId()
	local vehicle = GetHashKey('ambulance')

	RequestModel(vehicle)

	while not HasModelLoaded(vehicle) do
		Wait(1)
	end

	local plate = math.random(100, 900)
	local coords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0, 5.0, 0)
	local spawned_car = CreateVehicle(vehicle, coords, 431.436, - 996.786, 25.1887, true, false)

	SetVehicleOnGroundProperly(spawned_car)
	SetVehicleNumberPlateText(spawned_car, "MEDIC")
	SetPedIntoVehicle(myPed, spawned_car, - 1)
	SetModelAsNoLongerNeeded(vehicle)
	Citizen.InvokeNative(0xB736A491E64A32CF, Citizen.PointerValueIntInitialized(spawned_car))
end

function StartEmergency(x, y, z, playerID, sourcePlayerInComa)
	BLIP_EMERGENCY = AddBlipForCoord(x, y, z)

	SetBlipSprite(BLIP_EMERGENCY, 2)
	SetNewWaypoint(x, y)

	SendNotification('Un point a été placé sur votre GPS là où se trouve la victime en détresse')

	Citizen.CreateThread(
		function()
			local isRes = false
			local ped = GetPlayerPed(-1);
			while not isRes do
				Citizen.Wait(0)
				--Citizen.Trace(GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), x,y,z, true))
				if (GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), x,y,z, true)<3.0) then
						SendNotification('Appuyez sur E pour réanimer le joueur')
						if (IsControlJustReleased(1, Keys['E'])) then
							TaskStartScenarioInPlace(ped, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
							Citizen.Wait(8000)
							ClearPedTasks(ped);
	            TriggerServerEvent('es_em:sv_resurectPlayer', sourcePlayerInComa)
	            isRes = true
	          end
				end
			end
	end)
end

function GetService()
	-- Get job form server
	local isOk = false
	local playerPed = GetPlayerPed(-1)
	Citizen.Trace(jobId)
	if jobId == 11 then
		isOk = true
	end

	if not isOk then
		SendNotification('Vous n\'êtes pas ambulancier')
		return
	end

	if isInService then
		SendNotification("Vous n\'êtes plus en service")
	else
		SendNotification("Début du service")
	end

	isInService = not isInService

	SetPedComponentVariation(playerPed, 11, 13, 3, 2)
	SetPedComponentVariation(playerPed, 8, 15, 0, 2)
	SetPedComponentVariation(playerPed, 4, 9, 3, 2)
	SetPedComponentVariation(playerPed, 3, 92, 0, 2)
	SetPedComponentVariation(playerPed, 6, 25, 0, 2)
end

--[[
################################
        USEFUL METHODS
################################
--]]

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function SendNotification(message)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(message)
	DrawNotification(false, false)
end
