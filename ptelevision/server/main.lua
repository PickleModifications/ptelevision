local Locations = {}

GlobalState.Channels = {}
GlobalState.Channels = DumpArray(Config.Channels)

RegisterNetEvent("ptelevision:event", function(net_id, key, value) 
    local ent = NetworkGetEntityFromNetworkId(net_id)
    
    if (DoesEntityExist(ent)) then 
        Entity(ent).state:set(key, value, true)
    else
        Entity(ent).state:set(key, value, true)
    end
end)

RegisterNetEvent("ptelevision:broadcast", function(data)
    local _source = source
    local broadcasts = GlobalState.Channels
    if data then 
        for k,v in pairs(broadcasts) do 
            if (broadcasts[k].source == _source) then 
                return
            end
        end
        local index = 1
        while true do 
            if not (broadcasts[index]) then 
                broadcasts[index] = data
                broadcasts[index].source = _source
                TriggerClientEvent("ptelevision:broadcast", -1, index, broadcasts[index])
                break
            end
            index = index + 1
            Citizen.Wait(0)
        end
    else
        for k,v in pairs(broadcasts) do 
            if (broadcasts[k].source == _source) then 
                broadcasts[k] = nil
                TriggerClientEvent("ptelevision:broadcast", -1, k, broadcasts[k])
                break
            end
        end
    end
    GlobalState.Channels = broadcasts
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

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        for i=1, #Locations do 
            local data = Locations[i]
            DeleteEntity(Locations[i].obj)
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    local source = _source
    local broadcasts = GlobalState.Channels
    for k,v in pairs(broadcasts) do 
        if (broadcasts[k].source == _source) then 
            broadcasts[k] = nil
            TriggerClientEvent("ptelevision:broadcast", -1, k, broadcasts[k])
            break
        end
    end
    GlobalState.Channels = broadcasts
end)