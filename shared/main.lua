Televisions = {}

function v3(coord) 
    return vector3(coord.x, coord.y, coord.z), coord.w
end

function DumpArray(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[DumpArray(k, s)] = DumpArray(v, s) end
    return res
end

function GetTelevision(coords)
    for k,v in pairs(Televisions) do 
        if #(v3(v.coords) - v3(coords)) < 0.01 then
            return k, v
        end
    end
end

Channels = DumpArray(Config.Channels)