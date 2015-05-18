--
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 10.05.2015 - Time: 06:36
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
CMCManager = {}

function CMCManager:constructor()
    --self.mapTypes = {"DM", "DD", "Hunter", "Shooter"}
    --self.states = {}
    --addCommandHandler("cm", bind(CMCManager.initialiseMap, self))
    addEvent("onClientAddMap", true)
    addEvent("onClientRemoveMap", true)
    addEvent("onClientStartConvert", true)

    addEventHandler("onClientRemoveMap", resourceRoot, bind(CMCManager.clientRemoveMap, self))
    addEventHandler("onClientAddMap", resourceRoot, bind(CMCManager.clientAddMap, self))
    addEventHandler("onClientStartConvert", resourceRoot, bind(CMCManager.clientStartConvert, self))
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
    for _, conInstance in ipairs(self[client]) do
       conInstance:startConvert()
    end
end

--function CMCManager:syncToClient()
--   triggerClientEvent(client, "onServerAddedMap", client, self[client][#self[client]])  --Send the last instance "table".. hope that works o:
--end

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