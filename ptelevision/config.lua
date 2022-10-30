Config = {}
Config.Models = {
    [`prop_tv_flat_01`] = {
        Range = 20.0,
        Scale = 0.085, 
        Offset = vector3(-1.02, -0.055, 1.04),
    }
}

Config.Locations = {
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