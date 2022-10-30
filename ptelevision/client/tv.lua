function SetChannel(index)
    TriggerServerEvent("ptelevision:event", GetClosestScreen().net_id, "ptv_status", {
        type = "play",
        channel = index,
    })
end

function GetChannelList()
    local channel_list = {}
    local menu_list = {}
    local current = 1
    local screen = GetClosestScreen()
    local ent = NetToObj(screen.net_id)
    local status = Entity(ent).state['ptv_status']
    local channel = nil
    if (status) then 
        channel = status.channel
    end
    for index,value in pairs(GlobalState.Channels) do 
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
    for k,v in pairs(GlobalState.Channels) do 
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
    local input = lib.inputDialog('Web Browser', {'URL:'})

    if not input then OpenTVMenu() end
    TriggerServerEvent("ptelevision:event", GetClosestScreen().net_id, "ptv_status", {
        type = "browser",
        url = input[1]
    })
    OpenTVMenu()
end

function VideoMenu()
    local input = lib.inputDialog('Video Player', {'URL:'})

    if not input then OpenTVMenu() end
    TriggerServerEvent("ptelevision:event", GetClosestScreen().net_id, "ptv_status", {
        type = "play",
        url = input[1]
    })
    OpenTVMenu()
end

function OpenTVMenu() 
    local screen = GetClosestScreen()
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

AddStateBagChangeHandler("ptv_status", nil, function(bagName, key, value, reserved, replicated) 
    local net_id = tonumber(bagName:gsub('entity:', ''), 10)
    local ent = NetToObj(net_id)
    local screen = GetClosestScreen()
    if (screen and screen.net_id == net_id and DoesEntityExist(ent)) then 
        local event = value
        if (event.type == "play") then 
            local data = { url = event.url }
            if (event.channel) then
                data = GlobalState.Channels[event.channel]
                data.channel = event.channel
            end
            PlayVideo(data)
        elseif (event.type == "browser") then 
            PlayBrowser({ url = event.url })
        end
    end
    Entity(ent).state:set('ptv_status_local', {
        start_time = GetGameTimer()
    }, false)
end)

RegisterNetEvent("ptelevision:broadcast", function(index, data)
    if getDuiURL() == DEFAULT_URL then 
        local screen = GetClosestScreen()
        local tvObj = NetToObj(screen.net_id)
        local status = Entity(tvObj).state['ptv_status']
        if (status and status.channel == index and data == nil) then 
            ResetDisplay()
            Citizen.Wait(10)
        end
        SendDuiMessage(duiObj, json.encode({
            showNotification = true,
            channel = index,
            data = data
        }))
    end
end)

RegisterCommand('tv', function()
    OpenTVMenu() 
end)

RegisterCommand("broadcast", function(source, args, raw)
    BroadcastMenu()
end)