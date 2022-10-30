Config = {}

Config.Models = { -- Any TV Models used on the map or in locations must be defined here.
    [`prop_tv_flat_01`] = {
        DefaultVolume = 0.5,
        Range = 20.0,
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04),
    }
}

Config.Locations = { -- REMOVE ALL IF NOT USING ONESYNC, OR IT SHALL BREAK.
    {
        Model = `prop_tv_flat_01`,
        Position = vector4(144.3038, -1037.4647, 29.4173, 70.1882)
    },
    {
        Model = `prop_tv_flat_01`,
        Position = vector4(264.0882, -830.7057, 29.4569, 340.7550)
    },
}

Config.Channels = { -- These channels are default channels and cannot be overriden.
    {name = "Pickle Mods", url = "twitch.tv/picklemods"},
}

Config.Events = { -- Events for approving broadcasts / interactions (due to popular demand).
    ScreenInteract = function(source, data, key, value, cb) -- cb() to approve. 
        cb()
    end,    
    Broadcast = function(source, data, cb)  -- cb() to approve. 
        cb()
    end,
}