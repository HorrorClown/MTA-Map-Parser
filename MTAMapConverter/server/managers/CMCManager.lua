--
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 10.05.2015 - Time: 06:36
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
CMCManager = inherit(CMapConverter)

function CMCManager:constructor()
    self.mapTypes = {"DM", "DD", "Hunter", "Shooter"}
    self.states = {}
    addCommandHandler("cm", bind(CMCManager.initialiseMap, self))
end

function CMCManager:destructor()

end

function CMCManager:reset()
    --reset values to default; but i think tht is not rly needed :P
end

function CMCManager:initialiseMap(_, _, sMapResource)
    self:setState("Initialse map")
    self.mapResource = Resource.getFromName(sMapResource)

    if not self.mapResource then
        self:setState("Error: Can't find Resource!")
        --self:reset()
        return
    end

    self:setState("Checking Resource Infos")
    if self.mapResource:getInfo("type") ~= "map" then
        self:setState("Error: Resource type is not a map!")
        return
    end

    if self.mapResource:getInfo("gamemodes") ~= "race" then
        self:setState("Error: Resource is not a Race Map!")
        return
    end

    self.ResourceName = sMapResource
    self.mapName = self.mapResource:getInfo("name")
    self.mapType = self:getMapType()
    self.mapAuthor = self.mapResource:getInfo("author")

    if not self.mapName then
        self.setState("Error: Can't get Mapname!")
        return
    end

    if not self.mapType then
        self:setState(("Error: Invalid or no race Map type set (Available: %s)"):format(table.concat(self.mapTypes, ", ")))
        return
    end

    if not self.mapAuthor then
        self.setState("Warning: No map author set!")
    end

    self:setState("Extract meta.xml")
    if not self:extractMeta() then return end

    self:setState("Validating files")
    if not self:validateFiles() then return end

    self:setState("Convert map")
    if not self:convertMap() then return end

    self:setState("Map successfully converted")
    refreshResources()
end

function CMCManager:setState(sText)
    debugOutput(tostring(sText))
    table.insert(self.states, sText)
    --ToDo: Sync with client, if a gui is available
end