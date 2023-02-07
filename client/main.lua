DEFAULT_URL = "https://cfx-nui-ptelevision/html/index.html"
duiUrl = DEFAULT_URL
duiObj = nil
tvObj = nil
volume = 0.5
CURRENT_SCREEN = nil

local Locations = Config.Locations

function getDuiURL()
	return duiUrl
end

function SetVolume(coords, num)
    volume = num 
    SetTelevisionLocal(coords, "volume", num)
end

function GetVolume(dist, range) 
    if not volume then return 0 end
    local rem = (dist / range)
    rem = rem > volume and volume or rem
    local _vol = math.floor((volume - rem) * 100)
    return _vol
end

function setDuiURL(url)
	duiUrl = url
	SetDuiUrl(duiObj, duiUrl)
end

local sfName = 'generic_texture_renderer'

local width = 1280
local height = 720

local sfHandle = nil
local txdHasBeenSet = false


function loadScaleform(scaleform)
    local scaleformHandle = RequestScaleformMovie(scaleform)

    while not HasScaleformMovieLoaded(scaleformHandle) do 
        scaleformHandle = RequestScaleformMovie(scaleform)
        Citizen.Wait(0) 
    end
    return scaleformHandle
end

function ShowScreen(data)
    CURRENT_SCREEN = data
    sfHandle = loadScaleform(sfName)
    runtimeTxd = 'ptelevision_b_dict'

    local txd = CreateRuntimeTxd('ptelevision_b_dict')
    duiObj = CreateDui(duiUrl, width, height)
    local dui = GetDuiHandle(duiObj)
    local tx = CreateRuntimeTextureFromDuiHandle(txd, 'ptelevision_b_txd', dui)
    
    Citizen.Wait(10)

    PushScaleformMovieFunction(sfHandle, 'SET_TEXTURE')

    PushScaleformMovieMethodParameterString('ptelevision_b_dict')
    PushScaleformMovieMethodParameterString('ptelevision_b_txd')

    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(width)
    PushScaleformMovieFunctionParameterInt(height)

    PopScaleformMovieFunctionVoid()
    Citizen.CreateThread(function()
        TriggerServerEvent("ptelevision:requestSync", data.coords)
        local tvObj = data.entity
        local screenModel = Config.Models[data.model]
        while duiObj do
            if (tvObj and sfHandle ~= nil and HasScaleformMovieLoaded(sfHandle)) then
                local pos = GetEntityCoords(tvObj)
                local scale = screenModel.Scale
                local offset = GetOffsetFromEntityInWorldCoords(tvObj, screenModel.Offset.x, screenModel.Offset.y, screenModel.Offset.z)
                if (screenModel.Target) then 
                    local id = CreateNamedRenderTargetForModel(screenModel.Target, data.model)
                    if (id ~= -1) then
                        RenderScaleformTV(id, sfHandle, tvObj)
                    end
                else
                    local hz = GetEntityHeading(tvObj)
                    DrawScaleformMovie_3dSolid(sfHandle, offset, 0.0, 0.0, -hz, 2.0, 2.0, 2.0, scale * 1, scale * (9/16), 2)
                end
            end
            Citizen.Wait(0)
        end
    end)
    Citizen.CreateThread(function()
        local screen = CURRENT_SCREEN
        local modelData = Config.Models[screen.model]
        local coords = screen.coords
        local range = modelData.Range
        local _, lstatus = GetTelevisionLocal(coords)
        if (lstatus and lstatus.volume) then 
            SetVolume(coords, lstatus.volume)
        else
            SetVolume(coords, modelData.DefaultVolume)
        end
        while duiObj do 
            local pcoords = GetEntityCoords(PlayerPedId())
            local dist = #(coords - pcoords)
            SendDuiMessage(duiObj, json.encode({
                setVolume = true,
                data = GetVolume(dist, range, volume)
            }))
            Citizen.Wait(100)
        end
    end)
end

function HideScreen()
    CURRENT_SCREEN = nil
    if (duiObj) then 
        DestroyDui(duiObj)
        SetScaleformMovieAsNoLongerNeeded(sfHandle)
        duiObj = nil
        sfHandle = nil 
    end
end

function GetClosestScreen()
    local objPool = GetGamePool('CObject')
    local closest = {dist = -1}
    local pcoords = GetEntityCoords(PlayerPedId())
    for i=1, #objPool do
        local entity = objPool[i]
        local model = GetEntityModel(entity)
        local data = Config.Models[model]
        if (data) then 
            local coords = GetEntityCoords(entity)
            local dist = #(pcoords-coords)
            if (dist < closest.dist or closest.dist < 0) and dist < data.Range then 
                closest = {dist = dist, coords = coords, model = model, entity = entity}
            end
        end
    end
    return (closest.entity and closest or nil)
end

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    TriggerServerEvent("ptelevision:requestUpdate")
    while true do 
        local wait = 2500
        local data = GetClosestScreen()
        if (data and not duiObj) then 
            ShowScreen(data)
        elseif ((not data or #(v3(CURRENT_SCREEN.coords) - v3(data.coords)) > 0.01 ) and duiObj) then
            HideScreen()
        end
        Citizen.Wait(wait)
    end
end)

Citizen.CreateThread(function()
    while true do 
        local wait = 2500
        for i=1, #Locations do 
            local data = Locations[i]
            local dist = #(GetEntityCoords(PlayerPedId()) - v3(data.Position)) 
            if not Locations[i].obj and dist < 20.0 then 
                LoadModel(data.Model)
                Locations[i].obj = CreateObject(data.Model, data.Position.x, data.Position.y, data.Position.z)
                SetEntityHeading(Locations[i].obj, data.Position.w)
                FreezeEntityPosition(Locations[i].obj, true)
            elseif Locations[i].obj and dist > 20.0 then
                DeleteEntity(Locations[i].obj)
                Locations[i].obj = nil
            end
        end
        Citizen.Wait(wait)
    end
end)

RegisterNetEvent("ptelevision:requestUpdate", function(data)
    Televisions = data.Televisions
    Channels = data.Channels
end)

RegisterNetEvent("ptelevision:requestSync", function(coords, data)
    local tvObj = data.entity
        
    local _, status = GetTelevision(coords)
    local screenModel = Config.Models[data.model]
    if status and status["ptv_status"] then
        local update_time = status.update_time 
        local status = status["ptv_status"]
        Citizen.Wait(1000)
        if status.type == "play" then
            if (status.channel and Channels[status.channel]) then 
                PlayVideo({url = Channels[status.channel].url, channel = status.channel})
            elseif (status.url) then
                local time = math.floor(data.current_time - update_time)
                PlayVideo({url = status.url, time = time})
            end
        elseif (status.type == "browser") then 
            PlayBrowser({ url = status.url })
        end
    end
end)



RegisterNUICallback("pageLoaded", function(cb)
    waitForLoad = false
    if cb then cb() end
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        HideScreen()
        for i=1, #Locations do 
            DeleteEntity(Locations[i].obj)
        end
    end
end)
