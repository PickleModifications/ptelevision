DEFAULT_URL = "https://cfx-nui-ptelevision/html/index.html"
duiUrl = DEFAULT_URL
duiObj = nil
tvObj = nil

function getDuiURL()
	return duiUrl
end

function GetVolume(dist, range) 
    local rem = (dist / range)
    rem = rem > 1 and 1 or rem
    return (100 - math.floor(rem * 100))
end

function setDuiURL(url)
	duiUrl = url
	SetDuiUrl(duiObj, duiUrl)
end

local scale = 0.13
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
        local tvObj = NetToObj(data.net_id)
        local status = Entity(tvObj).state['ptv_status']
        local lstatus = Entity(tvObj).state['ptv_status_local']
        if status then 
            Citizen.Wait(1000)
            if status.type == "play" and lstatus then
                if (status.channel and GlobalState.Channels[status.channel]) then 
                    PlayVideo({url = GlobalState.Channels[status.channel].url, channel = status.channel})
                elseif (status.url) then
                    PlayVideo({url = status.url, time = math.floor((GetGameTimer() - lstatus.start_time) / 1000)})
                end
            elseif (status.type == "browser") then 
                PlayBrowser({ url = status.url })
            end
        end
        while duiObj do
            if (tvObj and sfHandle ~= nil and HasScaleformMovieLoaded(sfHandle)) then
                local pos = GetEntityCoords(tvObj)
                local min, max = GetModelDimensions(GetEntityModel(tvObj))
                local scale = 0.085
                local offset = GetOffsetFromEntityInWorldCoords(tvObj, -1.02, -0.055, 1.04)
                local hz = GetEntityHeading(tvObj)
                DrawScaleformMovie_3dNonAdditive(sfHandle, offset.x, offset.y, offset.z, 0.0, -hz, 0.0, 2.0, 2.0, 2.0, scale * 1, scale * (9/16), 1, 2)
            end
            Citizen.Wait(0)
        end
    end)
    Citizen.CreateThread(function()
        local screen = GetClosestScreen()
        local modelData = Config.Models[screen.model]
        local coords = screen.coords
        local range = modelData.Range
        while duiObj do 
            local pcoords = GetEntityCoords(PlayerPedId())
            local dist = #(coords - pcoords)
            SendDuiMessage(duiObj, json.encode({
                setVolume = true,
                data = GetVolume(dist, range)
            }))
            Citizen.Wait(100)
        end
    end)
end

function HideScreen()
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
                closest = {dist = dist, coords = coords, model = model, entity = entity, net_id = ObjToNet(entity)}
            end
        end
    end
    return (closest.entity and closest or nil)
end

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    while true do 
        local wait = 2500
        local data = GetClosestScreen()
        if (data and not duiObj) then 
            ShowScreen(data)
        elseif (not data and duiObj) then
            HideScreen()
        end
        Citizen.Wait(wait)
    end
end)

RegisterNUICallback("pageLoaded", function()
    waitForLoad = false
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        HideScreen()
    end
end)