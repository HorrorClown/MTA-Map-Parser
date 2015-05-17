--
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 10.05.2015 - Time: 06:27
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--

CMapConverter = {}

function CMapConverter:constructor(sResourceName, client)
    self.ResourceName = sResourceName
    self.ConvertedBy = client

    self.mapTypes = {"DM", "DD", "Hunter", "Shooter" }
    self.log = {}           --ToDo: Split log and State

    self.initialised = false
    self:initialiseMap()
end

function CMapConverter:destructor()
    for _, v in pairs(self) do
        v = nil
    end
end

function CMapConverter:initialiseMap()
    self:setState("Initalising map")

    self.mapResource = Resource.getFromName(self.ResourceName)

    if not self.mapResource then
        self:setState("Can't find resource")
        return false
    end

    if self.mapResource:getInfo("type") ~= "map" then
        self:setState("Error", "Resource type is not a map")
        return false
    end

    if self.mapResource:getInfo("gamemodes") ~= "race" then
        self:setState("Error", "Resource is not a race map!")
        return false
    end

    self.mapName = self.mapResource:getInfo("name")
    self.mapType = self:getMapType()
    self.mapAuthor = self.mapResource:getInfo("author")

    if not self.mapName then
        self:setState("Error", "Can't get map name")
        return false
    end

    if not self.mapAuthor then
        self:setState("Error", "Can't get map author")
        return false
    end

    if not self.mapType then
        self:setState("Error", "Invalid or no race map type is available in map name")
        return false
    end

    --Set initialised to true, if the map was successfully initialised (available to extract meta)
    self:setState("Initialised", "Successfully initialised!")
    self.initialised = true
end

function CMapConverter:startConvert()
    if self.initialised then

        if not self:extractMeta() then return end

        if not self:validateFiles() then return end

        if not self:convertMap() then return end

        self:setState("Map successfully converted")
        refreshResources()
    end
end

function CMapConverter:getMapType()
    if not self.mapName then return false end

    for _, mapType in ipairs(self.mapTypes) do
        if self.mapName:find(("\[%s\]"):format(mapType), 1, true) then
            return mapType
        end
    end
    return false
end

function CMapConverter:extractMeta()
    local meta = XML.load((":%s/meta.xml"):format(self.ResourceName))
    if not meta then
        self:setState("Error: Can't load meta.xml!")
        return false
    end

    self.meta = {
        map = {},
        script = {},
        file = {},
        settings = {}
    }

    --Add the security file at first to meta.xml!
    self:addSecurityFile()

    for _, mNode in ipairs(meta:getChildren()) do
        if mNode:getName() == "settings" then
            for _, sNode in ipairs(mNode:getChildren()) do
                table.insert(self.meta.settings, sNode:getAttributes())
            end
        elseif self.meta[mNode:getName()] then
            table.insert(self.meta[mNode:getName()], mNode:getAttributes())
        end
    end

    meta:unload()
    self:setState("Successfully extracted map meta!")
    return true
end

function CMapConverter:validateFiles()
    for _, file in ipairs(self.meta.file) do
       if not fileExists((":%s/%s"):format(self.ResourceName, file.src)) then
           self:setState(("Error: Can't find file %s"):format(file.src))
           return false
       end
    end

    for _, script in ipairs(self.meta.script) do
        if script.src ~= "iSecurity.lua" then
            if not fileExists((":%s/%s"):format(self.ResourceName, script.src)) then
                self:setState(("Error: Can't find script %s"):format(script.src))
                return false
            end
        end
    end

    for _, map in ipairs(self.meta.map) do
        if not fileExists((":%s/%s"):format(self.ResourceName, map.src)) then
            self:setState(("Error: Can't find map %s"):format(map.src))
            return false
        end
    end

    self:setState("All files valid!")
    return true
end

function CMapConverter:convertMap()
    --at first get map content
    for _, map in ipairs(self.meta.map) do
        local file = File((":%s/%s"):format(self.ResourceName, map.src))
        if file then
            map.content = file:read(file:getSize())
            file:close()
        end
    end

    --get sound files and load other file content
    self.soundFiles = {}
    for i, file in ipairs(self.meta.file) do
       if utils.isSoundFile(file.src) then
           self:setState(("Sound: %s"):format(file.src))
           table.insert(self.soundFiles, {ID = i, src = file.src})
           --table.remove(self.meta.file, i) --Delete from meta table in next step
       else
           local _file = File((":%s/%s"):format(self.ResourceName, file.src))
           if _file then
               file.content = _file:read(_file:getSize())
               _file:close()
           end
       end
    end

    self:setState(("Copying %s sound file%s"):format(#self.soundFiles, (#self.soundFiles > 1) and "s" or ""))

    --Copy sound files to destination directory
    for i, file in ipairs(self.soundFiles) do
        file.newName = ("%s-(MusicID+%s).%s"):format(utils.convert(self.mapName), i, utils.getFileExtansion(file.src))

        --ToDo: Use MTA internal functions (filyCopy | file:copy Methode)
        if Core.fs.copy(("mods/deathmatch/resources/%s/%s"):format(self.ResourceName, file.src), ("mapmusic/%s/%s"):format(self.mapType, file.newName)) then
            --Core.fs.delete(("mods/deathmatch/resources/%s/%s"):format(self.ResourceName, file.src)) --Will deleted with the source resource
            --table.remove(self.meta.file, file.ID)
        else
            self:setState(("Error while copying file '%s'"):format(file.src))
        end
    end

    self:setState("Replace sound paths")

    --get script content and if necessary, replace sound paths
    for _, script in ipairs(self.meta.script) do
       if script.src ~= "iSecurity.lua" then
            local file = File((":%s/%s"):format(self.ResourceName, script.src))
            if file then
               script.content = file:read(file:getSize())
               for _, sFile in ipairs(self.soundFiles) do
                   script.content = script.content:gsub(sFile.src, ("http://irace-mta.de/servermusic/mapmusic/%s/%s"):format(self.mapType, sFile.newName))
               end
               file:close()
                --File.delete((":%s/%s"):format(self.ResourceName, script.src)) --Will deleted with the source resource
            end
        end
    end

    self:setState("Creating new resource")
    --create new resource
    self.newResourceName = ("%s_%s"):format(self.mapType, utils.convert(self.mapName))
    self.newResource = Resource(self.newResourceName)

    self:setState("Create new meta.xml")
    --Create/Override new meta
    local newRMeta = XML.load((":%s/meta.xml"):format(self.newResourceName))
    if newRMeta then
        --Write at first info node
        local infoChild = newRMeta:createChild("info")
        infoChild:setAttribute("gamemodes", "race")
        infoChild:setAttribute("type", "map")
        infoChild:setAttribute("name", self.mapName)
        infoChild:setAttribute("author", self.mapAuthor)

        for k, v in pairs(self.meta) do
            if k == "script" then
                for _, script in ipairs(v) do
                    local scriptNode = newRMeta:createChild(k)
                    scriptNode:setAttribute("src", script.src)
                    scriptNode:setAttribute("type", script.type or "server")
                    scriptNode:setAttribute("cache", script.cache or "true")
                    scriptNode:setAttribute("validate", script.validate or "true")
                end
            elseif k == "file" then
                for _, file in ipairs(v) do
                    if not utils.isSoundFile(file.src) then
                        local fileNode = newRMeta:createChild(k)
                        fileNode:setAttribute("src", file.src)
                        fileNode:setAttribute("download", file.download or "true")
                    end
                end
            elseif k == "settings" then
                local settingsNode = newRMeta:createChild(k)
                for _, sv in ipairs(v) do
                    local setting = settingsNode:createChild("setting")
                    setting:setAttribute("name", sv.name)
                    setting:setAttribute("value", sv.value)
                end
            elseif k == "map" then
                for _, map in ipairs(v) do
                    local child = newRMeta:createChild(k)
                    child:setAttribute("src", map.src)
                    child:setAttribute("dimension", map.dimension)
                end
            end
        end
        newRMeta:saveFile()
        newRMeta:unload()
    end

    self:setState("Creating scripts")
    --Create new scripts
    for _, script in ipairs(self.meta.script) do
        if script.content then
            local file = File.new((":%s/%s"):format(self.newResourceName, script.src))
            if file then
                file:write(script.content)
                file:close()
            end
        end
    end

    self:setState("Creating files")
    --Create new files
    for _, file in ipairs(self.meta.file) do
        if not utils.isSoundFile(file.src) then
      -- if file.content then
            local _file = File.new((":%s/%s"):format(self.newResourceName, file.src))
            if _file then
                _file:write(file.content)
                _file:close()
            end
       -- end
        end
    end

    self:setState("Creating map file")
    --Create map file
    for _, map in ipairs(self.meta.map) do
        if map.content then
            local file = File.new((":%s/%s"):format(self.newResourceName, map.src))
            if file then
                file:write(map.content)
                file:close()
            end
        end
    end

    self:setState("Delete old resource")
    self.mapResource:delete()
    return true
end

function CMapConverter:setState(sState, sInfo)
    outputServerLog(("%s: %s"):format(tostring(sState), tostring(sInfo)))
    --table.insert(self.log, {state = sState, info = sInfo})
end

function CMapConverter:addSecurityFile()
    self.securityFile = [[--
-- iRace: Automatic created security file
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 10.05.2015 - Time: 06:27
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
SERVER = triggerServerEvent == nil
CLIENT = not SERVER

--Override functions
if SERVER then
    function setAccountData() return false end
    function getAccountData() return false end
end
function setElementData() return false end
--function getElementData() return false end
function outputChatBox() return false end

--Disable 'm' bind
_bindKey = bindKey
if SERVER then
    function bindKey(ePlayer, sKey, sKeyState, fHandlerFunction, ...)
        if sKey ~= "m" then
            return _bindKey(ePlayer, sKey, sKeyState, fHandlerFunction, ...)
        end
        return false
    end
else
    function bindKey(sKey, sKeyState, fHandlerFunction, ...)
        if sKey ~= "m" then
            return _bindKey(sKey, sKeyState, fHandlerFunction, ...)
        end
        return false
    end
end]]
    table.insert(self.meta.script, {src = "iSecurity.lua", content = self.securityFile, type = "shared"})
end