local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
}


--- esx
ESX                           = nil
local PlayerData              = {}

Citizen.CreateThread(function ()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    if ESX.IsPlayerLoaded() then
        PlayerData = ESX.GetPlayerData()
    end
end) 

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        local coords = GetEntityCoords(PlayerPedId())
        local dist = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, 1196.98, -3253.52, 7.10, true)
  
        if dist < 5 then 
          DrawMarker(-1, 1196.98, -3253.52, 7.10 , 0, 0, 0, 0, 0, 0, 1.501, 1.5001, 0.5001, 0, 255, 0, 200, 0, 0, 0, 0)
        end
        if dist < 5 then
          show3dtext(1196.98, -3253.52, 7.10, tostring("Tryck ~g~E~w~ för att öppna meny"))
        end
        if dist < 1.3 and IsControlPressed(0, Keys['E']) then
            StartJobMenu()
        end
    end
end)

Citizen.CreateThread(function()
    local blip = AddBlipForCoord(Config.Start.x, Config.Start.y, Config.Start.z)

    SetBlipSprite (blip, 318)
    SetBlipDisplay(blip, 4)
    SetBlipScale  (blip, 0.8)
    SetBlipColour (blip, 38)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Post OP')
    EndTextCommandSetBlipName(blip)
end)

local drugPackage = nil
local deliverCar = nil
local carblip = nil

local IsDoneWorking = false
local canceled = false
local hasClothes = false

--Startmenu, cloakroom etc.
function StartJobMenu()
    ESX.UI.Menu.CloseAll()

    local elements = {}

    if not hasClothes then
        table.insert(elements, {label = 'Arbetskläder', value = 'startwork'})
        table.insert(elements, {label = '--- Öppna igen ---', value = ''})
    else
    	table.insert(elements, {label = 'Starta din körning', value = 'car'})
    	table.insert(elements, {label = 'Civil klädsel', value = 'citizen'})
    end


    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'postnord_slow',
        {
            title    = 'Postnord',
            align    = 'top-right',
            elements = elements,
        },
    function (data, menu)
        local action = data.current.value
        if not IsPedInAnyVehicle(PlayerPedId(), false) then

            if action == 'car' then
                if not DoesEntityExist(deliverCar) then
                    menu.close()

                    StartDrugDeliver()
                else
                    ESX.ShowNotification('Du har redan en bil ute!')
                end
        	end

            if action == 'startwork' then
		        TriggerEvent('skinchanger:getSkin', function(skin)
		        
		            if skin.sex == 0 then

		                local clothesSkin = {
		                    ['tshirt_1'] = 15, ['tshirt_2'] = 0,
		                    ['torso_1'] = 123, ['torso_2'] = 2,
		                    ['arms'] = 41,
		                    ['pants_1'] = 25, ['pants_2'] = 1,
                            ['shoes_1'] = 51, ['shoes_2'] = 0,
                            ['helmet_1'] = 6, ['helmet_2'] = 7,
		                }
		                TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)

		            else

		                local clothesSkin = {
		                    ['tshirt_1'] = 15, ['tshirt_2'] = 0,
		                    ['torso_1'] = 119, ['torso_2'] = 2,
		                    ['arms'] = 57,
		                    ['pants_1'] = 37, ['pants_2'] = 1,
		                    ['shoes_1'] = 52, ['shoes_2'] = 0,
		                }
		                TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)

		            end
	            end)
		        hasClothes = true
                menu.close()
            end

            if action == 'citizen' then
    	        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
		          	TriggerEvent('skinchanger:loadSkin', skin)
		        end)
                menu.close()
		        hasClothes = false
    	    end

        else
            ESX.ShowNotification('Du kan ej göra det i ett fordon')
        end

    end,
    function (data, menu)
        menu.close()
    end
    )
end

function StartDrugDeliver()
    local canceled = false
    local model = GetHashKey('boxville4')
    RequestModel(model)

    while not HasModelLoaded(model) do
        Citizen.Wait(1)
    end

    deliverCar = CreateVehicle(model, Config.DrugVan.x, Config.DrugVan.y, Config.DrugVan.z, Config.DrugVan.h, true, false)

    local props = ESX.Game.GetVehicleProperties(deliverCar)

    props.plate = 'Postnord'

    ESX.Game.SetVehicleProperties(deliverCar, props)

    local reg = GetVehicleNumberPlateText(vehicle)
    TriggerServerEvent("LegacyFuel:UpdateServerFuelTable", reg, 100)	
    SetModelAsNoLongerNeeded(model)

    Wait(500)

    TaskWarpPedIntoVehicle(PlayerPedId(), deliverCar, -1)
    TriggerServerEvent("LegacyFuel:UpdateServerFuelTable", reg, 100)

    GetPackages()
end

function GetPackages()

        DeleteEntity(drugPackage)

        SetEntityAsNoLongerNeeded(drugPackage)

    	drugPackage = nil

    	local CarPackage = false
    	local handsFull = false
        local drugModel = GetHashKey('prop_cs_cardbox_01')

        RequestModel(drugModel)

        while not HasModelLoaded(drugModel) do
            Citizen.Wait(1)
        end

        if DoesEntityExist(drugPackage) then
            DeleteEntity(drugPackage)
            SetEntityAsNoLongerNeeded(drugPackage)
            Citizen.Wait(4200)
            drugPackage = CreateObject(drugModel, 1182.72, -3309.16, 7.03  - 0.50, true, false, true)
        else
            drugPackage = CreateObject(drugModel, 1182.72, -3309.16, 7.03  - 0.50, true, false, true)
        end

        local drugCoords = GetEntityCoords(drugPackage)
        
        SetNewWaypoint(1182.64, -3310.42)

        while not CarPackage do
        	Citizen.Wait(1)

        	local distance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), drugCoords)

            drawTxt(0.87, 0.504, 1.0,1.0,0.4, 'Tryck ~r~[F10]~w~ för att avbryta din körning', 255, 255, 255, 255)

            if IsControlJustReleased(0, Keys['F10']) then
                canceled = true
                CarPackage = true
                DeleteEntity(drugPackage)
                SetEntityAsNoLongerNeeded(drugPackage)
                ESX.Game.DeleteVehicle(deliverCar)
                Citizen.Wait(10)
                canceled = false
            end

        	if not handsFull then
        		drawTxt(0.87, 0.554, 1.0,1.0,0.4, 'Plocka upp paketet i ~g~hamnförrådet', 255, 255, 255, 255)
        	end

        	if distance < 10 and not handsFull then 
                show3dtext(drugCoords.x, drugCoords.y, drugCoords.z, tostring("Tryck ~r~E~w~ för att plocka upp"))
       			if distance < 2.5 then
                    if IsControlJustReleased(0, Keys['E']) then
                        if not DoesEntityExist(drugPackage) then
                            drugPackage = CreateObject(drugModel, 1182.47, -33100.9, 7,7 - 275.05, true, false, true)
                        end

                        Wait(100)

                        loadAnimDict('anim@heists@box_carry@')

                        TaskPlayAnim(PlayerPedId(), 'anim@heists@box_carry@', "idle", 8.0, 8.0, -1, 50, 0, false, false, false)

                        Wait(100)

                        AttachEntityToEntity(drugPackage, PlayerPedId(), GetPedBoneIndex(PlayerPedId(),  28422), 0.0, -0.03, 0.0, 5.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
                        --AttachEntityToEntity(drugPackage, PlayerPedId(), boneIndex, 0.10, 0.08, 0.07, 155.0, 180.0, 0.0, true, true, false, true, 1, true)
                        handsFull = true

                    end
                end
            end

            if handsFull then
                local coords    = GetEntityCoords(deliverCar)
                local forward   = GetEntityForwardVector(deliverCar)
                local x, y, z   = table.unpack(coords + forward * -2.7)
                local carDistance = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), x,y,z)

            	drawTxt(0.87, 0.554, 1.0,1.0,0.4, 'Lägg ~g~paketet~w~ i fordonet', 255, 255, 255, 255)

            	if carDistance < 10 then
            		show3dtext(x, y, z, tostring("Tryck ~r~E~w~ för att lägga ner paketet"))
            		if carDistance < 2.5 then
            			local doorState = GetVehicleDoorAngleRatio(deliverCar,2) and GetVehicleDoorAngleRatio(deliverCar,3)
            			if IsControlJustReleased(0, Keys['E']) then
            				if doorState ~= 0 then
    	        				DetachEntity(drugPackage)
                                AttachEntityToEntity(drugPackage, deliverCar, 0, 0.0, -2.0, 0.15--[[Z]], 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                CarPackage = true
    	        				Citizen.Wait(500)
    	        				ClearPedTasksImmediately(PlayerPedId())
    	        				OnWay()
    	        			else
    	        				ESX.ShowNotification('Du måste öppna <span style="color:red;"> bakdörren</span>')
    	        			end
            			end
            		end
            	end
            end

        end
end


function OnWay()
    if not canceled then

        local locations = {
            { name = 'Polisstation', x = 437.29, y = -978.61, z = 30.69 },
            { name = 'Bilcenter', x = -38.9, y = -1090.39, z = 26.42 },
            { name = 'Mekonomen', x = -322.76, y = -140.86, z = 39.01 },
            { name = 'Bennys', x = -213.86, y = -1334.02, z = 30.69 },
            { name = 'Taxi', x = 900.07, y = -171.54, z = 74.07 },
            { name = 'Tequi-La-La', x = -562.37, y = 285.12, z = 82.17 },
            { name = 'Sjukhuset', x = 304.68, y = -600.40, z = 43.29 },
        }

        local DropOff = false
        local IsDoneWorking = false
        local hasObject = false
        local random = math.random(1, 5)

        SetNewWaypoint(locations[random].x, locations[random].y)

        while not IsDoneWorking do
            Citizen.Wait(1)

            local PlayerCoords = GetEntityCoords(PlayerPedId())

            drawTxt(0.82, 0.504, 1.0,1.0,0.4, 'Tryck ~r~[G]~w~ för att avbryta din körning', 255, 255, 255, 255)

            if IsControlJustReleased(0, Keys['G']) then
                canceled = true
                IsDoneWorking = true
                SetNewWaypoint(PlayerCoords.x, PlayerCoords.y)
                DeleteEntity(drugPackage)
                SetEntityAsNoLongerNeeded(drugPackage)
                ESX.Game.DeleteVehicle(deliverCar)
                Citizen.Wait(10)
                canceled = false
            end

            if not DropOff then
                drawTxt(0.82, 0.604, 1.0,1.0,0.4, 'Åk och lämna paketet vid ' .. locations[random].name, 255, 255, 255, 255)
            end

            if not IsPedInVehicle(PlayerPedId(), deliverCar, true) and not DropOff then
                drawTxt(0.82, 0.554, 1.0,1.0,0.4, 'Hoppa in i ~b~bilen', 255, 255, 255, 255)
            end

            if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), locations[random].x, locations[random].y, locations[random].z) < 45.0 then
                local coords    = GetEntityCoords(deliverCar)
                local forward   = GetEntityForwardVector(deliverCar)
                local x, y, z   = table.unpack(coords + forward * -2.7)
                DropOff = true

                drawTxt(0.82, 0.604, 1.0,1.0,0.4, 'Lämna av paketet', 255, 255, 255, 255)

                show3dtext(locations[random].x, locations[random].y, locations[random].z, tostring("Lämna paketet ~r~här"))

                ESX.Game.Utils.DrawText3D({x = x, y = y, z = z}, 'Tryck ~r~[E]~w~ för att ta lådan', 0.4)

                if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), x, y, z) < 2.5 then

                    if IsControlJustReleased(0, Keys['E']) then
                        
                        local doorState = GetVehicleDoorAngleRatio(deliverCar,2) and GetVehicleDoorAngleRatio(deliverCar,3)

                        if doorState ~= 0 then

                            DetachEntity(drugPackage)
                            ActivatePhysics(drugPackage)

                            loadAnimDict('anim@heists@box_carry@')

                            TaskPlayAnim(PlayerPedId(), 'anim@heists@box_carry@', "idle", 8.0, 8.0, -1, 50, 0, false, false, false)

                            Wait(100)

                            AttachEntityToEntity(drugPackage, PlayerPedId(), GetPedBoneIndex(PlayerPedId(),  28422), 0.0, -0.03, 0.0, 5.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)

                            hasObject = true
                        else
                            ESX.ShowNotification('Du måste öppna <span style="color:red;"> bakdörren</span>')
                        end

                    end

                end

                if hasObject and not IsEntityPlayingAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 3) then
                	Wait(10)
                	TaskPlayAnim(PlayerPedId(), 'anim@heists@box_carry@', "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
                end


                if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), locations[random].x, locations[random].y, locations[random].z) < 1.0 and hasObject then

                    DetachEntity(drugPackage)
                    ClearPedTasksImmediately(PlayerPedId())
                    leavePlace(locations[random].x, locations[random].y, locations[random].z)
                    IsDoneWorking = true

                end

                --fail safe
                --[[if IsControlJustReleased(0, Keys['X']) then

                    DetachEntity(drugPackage)

                end]]

            end

        end

    end


end

function leavePlace(x1, y1, z1)

    local LeftPlace = false

    while not LeftPlace do
        Citizen.Wait(1)

        local pedcoords = GetEntityCoords(PlayerPedId())

        local dis = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), x1, y1, z1)

        ESX.Game.Utils.DrawText3D({x = pedcoords.x, y = pedcoords.y, z = pedcoords.z + 1}, 'Åk från platsen ' ..math.floor(dis / 3).. '%' , 0.4)

        if dis >= 300 then

            LeftPlace = true

            TriggerServerEvent('esx-kocken-postnord:receiveMoney')

            Citizen.Wait(100)

            SetEntityAsMissionEntity(drugPackage, false, true)
            DeleteObject(drugPackage)
            SetEntityAsNoLongerNeeded(drugPackage)

            GetPackages()

        end

    end
    SetNewWaypoint(928.4, -2533.16)
end

Citizen.CreateThread(function()
    Citizen.Wait(2500)
    while true do
        local sleep = 500
        local coords = GetEntityCoords(PlayerPedId())

        if(GetDistanceBetweenCoords(coords, Config.Start.x, Config.Start.y, Config.Start.z, true) < Config.DrawDistance) then
            sleep = 5
        	if PlayerData ~= nil and PlayerData.job ~= nil and PlayerData.job.name == 'mailman' then
	            DrawMarker(Config.Type, Config.Start.x, Config.Start.y, Config.Start.z - 0.96, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.Size.x, Config.Size.y, Config.Size.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, false, false)
	            if(GetDistanceBetweenCoords(coords, Config.Start.x, Config.Start.y, Config.Start.z, true) < 2.5) then
	                hintToDisplay('Tryck på ~INPUT_CONTEXT~ för att öppna arbetsmenyn')

	                if IsControlJustReleased(0, Keys['E']) then
	                    StartJobMenu()
	                end
	            end

            end
        else
            sleep = 500
        end
        
        Citizen.Wait(sleep)

    end
end)

--notification
function sendNotification(message, messageType, messageTimeout)
	TriggerEvent("pNotify:SendNotification", {
		text = message,
		type = messageType,
		queue = "kocken",
		timeout = messageTimeout,
		layout = "bottomCenter"
	})
end

function DrawText3D(x, y, z, text, scale)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
 
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(1)
    SetTextColour(255, 255, 255, 215)
 
    AddTextComponentString(text)
    DrawText(_x, _y)
 
    local factor = (string.len(text)) / 370
 
    DrawRect(_x, _y + 0.0150, 0.030 + factor, 0.025, 41, 11, 41, 100)
end

function show3dtext(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    if onScreen then
        SetTextScale(0.4*scale, 0.4*scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150) 
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

function drawTxt(x,y ,width,height,scale, text, r,g,b,a, outline)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    if(outline)then
      SetTextOutline()
  end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        
        Citizen.Wait(1)
    end
end

--display
function hintToDisplay(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end