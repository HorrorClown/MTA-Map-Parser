--
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 10.05.2015 - Time: 06:36
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
CMCManager = {}

function CMCManager:constructor()
    addEvent("onClientAddMap", true)
    addEvent("onClientRemoveMap", true)
    addEvent("onClientStartConvert", true)
    addEvent("onClientApplySettings", true)

    addEventHandler("onClientAddMap", resourceRoot, bind(CMCManager.clientAddMap, self))
    addEventHandler("onClientRemoveMap", resourceRoot, bind(CMCManager.clientRemoveMap, self))
    addEventHandler("onClientStartConvert", resourceRoot, bind(CMCManager.clientStartConvert, self))
    addEventHandler("onClientApplySettings", resourceRoot, bind(CMCManager.clientApplySettings, self))
end

function CMCManager:destructor()

end

function CMCManager:clientAddMap(sMapResourceName)
    if not self[client] then self[client] = {} end

    if not self:isAlreadyAdded(sMapResourceName) then
        table.insert(self[client], new(CMapConverter, sMapResourceName, client))
        triggerClientEvent(client, "onServerAddedMap", client, self[client][#self[client]])
    end
end

function CMCManager:clientRemoveMap(sMapResourceName)
    if not self[client] then return true end

    for i, conInstance in ipairs(self[client]) do
        if conInstance.ResourceName == sMapResourceName then
            triggerClientEvent(client, "onServerRemovedMap", client, conInstance)
            delete(conInstance)
            table.remove(self[client], i)
        end
    end
    return false
end

function CMCManager:isAlreadyAdded(sMapResourceName)
    for _, conInstance in ipairs(self[client]) do
       if conInstance.ResourceName == sMapResourceName then
           return true
       end
    end
    return false
end

function CMCManager:clientStartConvert()
    if not self[client] then triggerClientEvent(client, "onServerConvertingDone", client) return end

    --At first update states
    for i, conInstance in ipairs(self[client]) do
        if conInstance.initialised then
            conInstance:setState("Queued")
        end
    end

    --Start converting now
    for i, conInstance in ipairs(self[client]) do
        conInstance:startConvert()
        delete(conInstance)
    end

    --Converting ended
    self[client] = {}
    triggerClientEvent(client, "onServerConvertingDone", client)
end

function CMCManager:clientApplySettings(tMapSettings)
    for _, conInstance in ipairs(self[client]) do
       if conInstance.ResourceName == tMapSettings.ResourceName then
            conInstance.useCustom = true
            conInstance.customMapName = tMapSettings.customMapName
            conInstance.customMapAuthor = tMapSettings.customMapAuthor
            conInstance.customMapType = tMapSettings.customMapType
       end
    end
end

function CMCManager:sync(CInstance)
    local toSync = {ResourceName = CInstance.ResourceName, state = CInstance.state, log = CInstance.log }
    triggerClientEvent(CInstance.ConvertedBy, "onServerSyncConverting", CInstance.ConvertedBy, toSync)
end

--[[function CMCManager:initialiseMap(_, _, sMapResource)
    self:setState("Extract meta.xml")
    if not self:extractMeta() then return end

    self:setState("Validating files")
    if not self:validateFiles() then return end

    self:setState("Convert map")
    if not self:convertMap() then return end

    self:setState("Map successfully converted")
    refreshResources()
end]]