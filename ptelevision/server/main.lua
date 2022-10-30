local Locations = {}

function SetTelevision(coords, key, value, update)
    local index, data = GetTelevision(coords)
    if (index ~= nil) then 
        if (Televisions[index] == nil) then 
            Televisions[index] = {}
        end
        Televisions[index][key] = value
    else
        index = os.time()
        while Televisions[index] do 
            index = index + 1
            Citizen.Wait(0)
        end
        if (Televisions[index] == nil) then 
            Televisions[index] = {}
        end
        Televisions[index][key] = value
    end
    Televisions[index].coords = coords
    if (update) then
        TriggerClientEvent("ptelevision:event", -1, Televisions, index, key, value)
    end
    return index
end

function SetChannel(source, data)
    if data then 
        for k,v in pairs(Channels) do 
            if (Channels[k].source == source) then 
                return
            end
        end
        local index = 1
        while Channels[index] do 
            index = index + 1
            Citizen.Wait(0)
        end
        Channels[index] = data
        Channels[index].source = source
        TriggerClientEvent("ptelevision:broadcast", -1, Channels, index)
        return
    else
        for k,v in pairs(Channels) do 
            if (Channels[k].source == source) then 
                Channels[k] = nil
                TriggerClientEvent("ptelevision:broadcast", -1, Channels, k)
                return
            end
        end
    end
end

RegisterNetEvent("ptelevision:event", function(data, key, value) 
    local _source = source
    Config.Events.ScreenInteract(_source, data, key, value, function()
        SetTelevision(data.coords, key, value, true)
    end)
end)

RegisterNetEvent("ptelevision:broadcast", function(data)
    local _source = source
    Config.Events.Broadcast(_source, data, function()
        SetChannel(_source, data)
    end)
end)

RegisterNetEvent("ptelevision:requestUpdate", function()
    local _source = source
    TriggerClientEvent("ptelevision:requestUpdate", _source, {
        Televisions = Televisions,
        Channels = Channels
    })
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        for i=1, #Locations do 
            local data = Locations[i]
            if (DoesEntityExist(Locations[i].obj)) then 
                DeleteEntity(Locations[i].obj)
            end
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    local _source = source
    SetChannel(_source, nil)
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    local locations = Config.Locations
    for i=1, #locations do 
        local data = locations[i]
        local obj = CreateObject(data.Model, data.Position.x, data.Position.y, data.Position.z, true)
        SetEntityHeading(obj, data.Position.w)
        table.insert(Locations, {data = data, obj = obj})
    end
end)