TelevisionsLocal = {}

function SetChannel(index)
    TriggerServerEvent("ptelevision:event", CURRENT_SCREEN, "ptv_status", {
        type = "play",
        channel = index,
    })
end

function GetChannelList()
    if not Channels then return {} end
    local channel_list = {}
    local menu_list = {}
    local current = 1
    local screen = CURRENT_SCREEN
    local ent = screen.entity
    local _, status = GetTelevision(screen.coords)
    local channel = nil
    if (status) then 
        channel = status.channel
    end
    for index,value in pairs(Channels) do 
        table.insert(channel_list, {index = index, url = value.url})
        table.insert(menu_list, "Channel #" .. index .. " (".. value.name ..")")
        if channel ~= nil and channel == index then 
            current = #channel_list
        end
    end
    return {list = channel_list, display = menu_list, current = current}
end

function BroadcastMenu() 
    local _source = GetPlayerServerId(PlayerId())
    for k,v in pairs(Channels) do 
        if (v.source == _source) then 
            TriggerServerEvent("ptelevision:broadcast", nil)
            return
        end
    end 
    local input = lib.inputDialog('Live Broadcast', {'Channel Name:', 'Broadcast URL:'})
    if (input[1] and input[2]) then 
        TriggerServerEvent("ptelevision:broadcast", {name = input[1], url = input[2]})
    end
end 

function WebBrowserMenu()
    lib.hideMenu()
    local input = lib.inputDialog('Web Browser', {'URL:'})

    if input then 
        TriggerServerEvent("ptelevision:event", CURRENT_SCREEN, "ptv_status", {
            type = "browser",
            url = input[1]
        })
    end
    Citizen.Wait(300) 
    OpenTVMenu() 
end

function VideoMenu()
    lib.hideMenu()
    local input = lib.inputDialog('Video Player', {'URL:'})
    if input then 
        TriggerServerEvent("ptelevision:event", CURRENT_SCREEN, "ptv_status", {
            type = "play",
            url = input[1]
        })
    end
    Citizen.Wait(300) 
    OpenTVMenu()
end

function VolumeMenu()
    lib.hideMenu()
    local input = lib.inputDialog('Volume', {'Set Volume (0-100):'})
    if (tonumber(input[1])) then 
        local coords = CURRENT_SCREEN.coords
        SetVolume(coords, tonumber(input[1])/100)
    end
    Citizen.Wait(300) 
    OpenTVMenu()
end

function OpenTVMenu() 
    local screen = CURRENT_SCREEN
    if not screen then return end
    lib.hideMenu()
    local ChannelList = GetChannelList()
    lib.registerMenu({
        id = 'ptelevision-menu',
        title = 'Television',
        position = 'top-right',
        onSideScroll = function(selected, scrollIndex, args)
            if (selected == 3) then 
                SetChannel(ChannelList.list[scrollIndex].index)
            end
        end,
        onSelected = function(selected, scrollIndex, args) 
        end,
        onClose = function(keyPressed)
        end,
        options = {
            {label = 'Videos', description = 'Play a video or stream on the screen.'},
            {label = 'Web Browser', description = 'Access the web via your TV.'},
            {label = 'TV Channels', values = ChannelList.display, description = 'Live TV Channels in San Andreas!', defaultIndex = ChannelList.current},
            {label = 'Interact With Screen', description = 'Allows you to control on-screen elements.'},
            {label = 'Set Volume', description = 'Sets your TV\'s volume (For yourself).'},
            {label = 'Close Menu', close = true},
        }
    }, function(selected, scrollIndex, args)
        if (selected == 1) then
            VideoMenu()
        elseif (selected == 2) then
            WebBrowserMenu()
        elseif (selected == 3) then 
            SetChannel(ChannelList.list[scrollIndex].index)
            OpenTVMenu()
        elseif selected == 4 then 
            SetInteractScreen(true)
        elseif selected == 5 then 
            VolumeMenu()
        end
    end)
    lib.showMenu('ptelevision-menu')
end

function PlayBrowser(data)
    while not IsDuiAvailable(duiObj) do Wait(10) end
    setDuiURL(data.url)
end

function PlayVideo(data)
    while not IsDuiAvailable(duiObj) do Wait(10) end
    if (getDuiURL() ~= DEFAULT_URL) then 
        waitForLoad = true
        setDuiURL(DEFAULT_URL)
        while waitForLoad do Wait(10) end
    end
    SendDuiMessage(duiObj, json.encode({
        setVideo = true,
        data = data
    }))
end

function ResetDisplay()
    setDuiURL(DEFAULT_URL)
end

function GetTelevisionLocal(coords)
    for k,v in pairs(TelevisionsLocal) do 
        if #(v3(v.coords) - v3(coords)) < 0.01 then
            return k, v
        end
    end
end

function SetTelevisionLocal(coords, key, value)
    local index, data = GetTelevisionLocal(coords)
    if (index ~= nil) then 
        if (TelevisionsLocal[index] == nil) then 
            TelevisionsLocal[index] = {}
        end
        TelevisionsLocal[index][key] = value
    else
        index = GetGameTimer()
        while TelevisionsLocal[index] do 
            index = index + 1
            Citizen.Wait(0)
        end
        if (TelevisionsLocal[index] == nil) then 
            TelevisionsLocal[index] = {}
        end
        TelevisionsLocal[index][key] = value
    end
    TelevisionsLocal[index].coords = coords
    return index
end

RegisterNetEvent("ptelevision:event", function(data, index, key, value) 
    Televisions = data
    local data = Televisions[index]
    local screen = CURRENT_SCREEN
    if (screen and #(v3(screen.coords) - v3(data.coords)) < 0.001) then 
        local index, data = GetTelevision(screen.coords)
        if (index) then 
            local event = value
            if (event.type == "play") then 
                local data = { url = event.url }
                if (event.channel) then
                    data = Channels[event.channel]
                    data.channel = event.channel
                end
                PlayVideo(data)
            elseif (event.type == "browser") then 
                PlayBrowser({ url = event.url })
            end 
        end
    end
    SetTelevisionLocal(Televisions[index].coords, "start_time", GetGameTimer())
end)

RegisterNetEvent("ptelevision:broadcast", function(data, index)
    Channels = data
    if getDuiURL() == DEFAULT_URL then 
        local screen = CURRENT_SCREEN
        local tvObj = screen.entity
        local _, status = GetTelevision(screen.coords)
        if (status and status.channel == index and data[index] == nil) then 
            ResetDisplay()
            Citizen.Wait(10)
        end
        SendDuiMessage(duiObj, json.encode({
            showNotification = true,
            channel = index,
            data = data[index]
        }))
    end
end)

RegisterCommand('tv', function()
    OpenTVMenu() 
end)

RegisterCommand("broadcast", function(source, args, raw)
    BroadcastMenu()
end)