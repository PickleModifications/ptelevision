function CreateNamedRenderTargetForModel(name, model)
	local handle = 0
	if not IsNamedRendertargetRegistered(name) then
		RegisterNamedRendertarget(name, 0)
	end
	if not IsNamedRendertargetLinked(model) then
		LinkNamedRendertarget(model)
	end
	if IsNamedRendertargetRegistered(name) then
		handle = GetNamedRendertargetRenderId(name)
	end
	return handle
end

function RequestTextureDictionary(dict)
	RequestStreamedTextureDict(dict)
	while not HasStreamedTextureDictLoaded(dict) do Wait(0) end
	return dict
end

function LoadModel(model)
	if not IsModelInCdimage(model) then return end
	RequestModel(model)
	while not HasModelLoaded(model) do Wait(0) end
	return model
end

function RenderScaleformTV(renderTarget, scaleform, entity)
    SetTextRenderId(renderTarget) -- set render target
    Set_2dLayer(4)
    SetScriptGfxDrawBehindPausemenu(1)
    --DrawRect(0.5, 0.5, 1.0, 0.5, 255, 0, 0, 255); -- WOAH!
    local coords = GetEntityCoords(entity)
    local rot = GetEntityRotation(entity)
    DrawSprite("ptelevision_b_dict", "ptelevision_b_txd", 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
    SetTextRenderId(GetDefaultScriptRendertargetRenderId()) -- reset
    SetScriptGfxDrawBehindPausemenu(0)
end

