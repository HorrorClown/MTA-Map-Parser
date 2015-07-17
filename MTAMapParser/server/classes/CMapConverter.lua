--
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 10.05.2015 - Time: 06:27
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
CMapParser = {}

function CMapParser:constructor(sResourceName, client)
    self.parserVersion = 1  --[[
    ToDo: Check this with map meta info if the map is already converted. If the parserVersion in the map lower than this version, the map may require an upgrade
    If an upgrade required, the map does not need to get completely parsed. Special functions to upgrade for specific versions still needed. Too lazy to do that now :O
]]
    self.ResourceName = sResourceName
    self.ConvertedBy = client

    self.mapTypes = {"DM", "DD", "Hunter", "Shooter" }
    self.log = {""}
    self.state = nil

    --self.deleteOldResource = true
    self.initialised = false
    self:initialiseMap()
end

function CMapParser:destructor()
    for _, v in pairs(self) do
        v = nil
    end
end

function CMapParser:initialiseMap()
    self:setState("Initalising")

    self.mapResource = Resource.getFromName(self.ResourceName)

    if not self.mapResource then
        self:setState("Init. Failed", "Can't find resource")
        return false
    end

    if self.mapResource:getInfo("type") ~= "map" then
        self:setState("Init. Failed", "Resource type is not a map")
        return false
    end

    if self.mapResource:getInfo("gamemodes") ~= "race" then
        self:setState("Init. Failed", "Resource is not a race map")
        return false
    end

    self.Converted = self.mapResource:getInfo("pewParsed")
    self.parserdVersion = self.mapResource:getInfo("parsedVersion")

    self.mapName = self.mapResource:getInfo("name")
    self.mapType = self:getMapType()
    self.mapAuthor = self.mapResource:getInfo("author")
    self.newResourceName = self:getNewResourceName()

    if not self.mapName then
        self:setState("Init. Failed", "Can't get map name")
        return false
    end

    if not self.mapAuthor then
        self:setState("Init. Failed", "Can't get map author")
        return false
    end

    if not self.mapType then
        self:setState("Init. Failed", "Invalid or nor race map type is available in map name")
        return false
    end

    self:setState("Initialised")
    self.initialised = true
end

function CMapParser:getNewResourceName()
    if not self.mapType then return "Error" end
    if not self.mapName then return "Error" end

    local temp = utils.convert(self.mapName):gsub("__", "_") --Convert and replace __ with _
    local count = #self.mapType + 1

    if temp:byte(count) == 95 then count = count + 1 end

    local split = temp:sub(count, #temp)

    return ("%s_%s"):format(self.mapType:upper(), split:lower())
end

function CMapParser:startParsing()
    if self.initialised then
        self.startTick = getTickCount()
        self:setState("Parsing")

        if self.Converted then
            self:setState("Failed to parse", "Map is already parsed")
            return
        end

        self:setState(false, "Start extracting meta.xml")
        if not self:extractMeta() then return end

        self:setState(false, "Validating files")
        if not self:validateFiles() then return end

        self:setState(false, "Start parsing")
        if not self:parseMap() then return end

        self:setState("Success" , ("[%sms]"):format(math.floor(getTickCount()-self.startTick)))
    end
end

function CMapParser:getMapType()
    if not self.mapName then return false end

    for _, mapType in ipairs(self.mapTypes) do
        if self.mapName:find(("\[%s\]"):format(mapType), 1, true) then
            return mapType
        end
    end
    return false
end

function CMapParser:extractMeta()
    local meta = XML.load((":%s/meta.xml"):format(self.ResourceName))
    if not meta then
        self:setState("Failed to parse", "Can't load meta.xml")
        return false
    end

    self.meta = {
        map = {},
        script = {},
        file = {},
        settings = {}
    }

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
    self:setState(false, "Successfully extracted meta.xml")
    return true
end

function CMapParser:validateFiles()
    for _, file in ipairs(self.meta.file) do
       if not fileExists((":%s/%s"):format(self.ResourceName, file.src)) then
           self:setState("Failed to parse", ("Can't find file %s"):format(file.src))
           return false
       end
    end
    self:setState(false, ("Validating of %s map additional file%s: OK"):format(#self.meta.file, (#self.meta.file == 0 or #self.meta.file > 1) and "s" or ""))

    for _, script in ipairs(self.meta.script) do
        if not fileExists((":%s/%s"):format(self.ResourceName, script.src)) then
            self:setState("Failed to parse", ("Can't find script %s"):format(script.src))
            return false
        end
    end
    self:setState(false, ("Validating of %s map script%s: OK"):format(#self.meta.script, (#self.meta.script == 0 or #self.meta.script > 1) and "s" or ""))

    for _, map in ipairs(self.meta.map) do
        if not fileExists((":%s/%s"):format(self.ResourceName, map.src)) then
            self:setState("Failed to parse", ("Can't find map %s"):format(map.src))
            return false
        end
    end
    self:setState(false, ("Validating of %s map%s: OK"):format(#self.meta.map, (#self.meta.map == 0 or #self.meta.map > 1) and "s" or ""))

    return true
end

function CMapParser:parseMap()
    --at first get map content
    self:setState(false, "Loading map content")
    for _, map in ipairs(self.meta.map) do
        local file = File((":%s/%s"):format(self.ResourceName, map.src))
        if file then
            map.content = file:read(file:getSize())
            file:close()
        else
            self:setState("Failed to parse", ("Unable to load map file %s"):format(map.src))
            return false
        end
    end

    --get sound files and load other file content
    self:setState(false, "Loading file content and search for sound files")
    self.soundFiles = {}
    for i, file in ipairs(self.meta.file) do
       if utils.isSoundFile(file.src) then
           table.insert(self.soundFiles, {ID = i, src = file.src})
       else
           local _file = File((":%s/%s"):format(self.ResourceName, file.src))
           if _file then
               file.content = _file:read(_file:getSize())
               _file:close()
           else
               self:setState("Failed to parse", ("Unable to load file %s"):format(file.src))
               return false
           end
       end
    end

    self:setState(false, ("Found %s sound file%s"):format(#self.soundFiles, (#self.soundFiles == 0 or #self.soundFiles > 1) and "s" or ""))

    --Copy sound files to destination directory
    for i, file in ipairs(self.soundFiles) do
        file.newName = ("%s-(MusicID+%s).%s"):format(utils.convert(self.mapName), i, utils.getFileExtansion(file.src))
        file.streamURL =  ("http://pewx.de/res/irace/mapmusic/%s/%s"):format(self.mapType, file.newName)
        self:setState(false, ("Copy and rename '%s' to '%s'"):format(file.src, file.newName))
        if not File.copy((":%s/%s"):format(self.ResourceName, file.src), (":MTAMapParser/mapmusic/%s/%s"):format(self.mapType, file.newName), true) then
            self:setState("Failed to parse", ("Error while copying file '%s'"):format(file.src))
            return false
        end
    end

    --get script content
    self:setState(false, "Loading script content")
    for _, script in ipairs(self.meta.script) do
        local file = File((":%s/%s"):format(self.ResourceName, script.src))
        if file then
           script.content = file:read(file:getSize())
           file:close()
        else
            self:setState("Failed to parse", ("Unable to load script file %s"):format(script.src))
            return false
        end
    end

    --create new resource
    self:setState(false, "Create new resource")
    if Resource.getFromName(self.newResourceName) then
        self:setState("Failed to parse", "Resource for new generated resource name is already exists")
        return false
    end
    --[[self.count = 0
    while Resource.getFromName(self.newResourceName) do
        self.newResourceName = ("%s-%s"):format(self.newResourceName, self.count)
        self:setState(false, ("Resource already exists, continue if '%s' is available"):format(self.newResourceName))
        self.count = self.count + 1
    end]]
    self.newResource = Resource(self.newResourceName, "[Parsed]")
    self:setState(false, ("Resource '%s' successfully created"):format(self.newResourceName))

    --Create/Override new meta
    self:setState(false, "Create meta.xml for new resource")
    local newRMeta = XML.load((":%s/meta.xml"):format(self.newResourceName))
    if newRMeta then
        --Write at first info node
        local infoChild = newRMeta:createChild("info")
        infoChild:setAttribute("gamemodes", "race")
        infoChild:setAttribute("type", "map")
        infoChild:setAttribute("name", self.mapName)
        infoChild:setAttribute("author", self.mapAuthor)
        infoChild:setAttribute("pewParsed", "true")
        infoChild:setAttribute("parsedVersion", self.parserVersion)

        --Create pew script at first
        local pewNode = newRMeta:createChild("script")
        pewNode:setAttribute("src", "pew.lua")
        pewNode:setAttribute("type", "shared")

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

    --Create new scripts
    self:setState(false, "Create scripts for new resource")
    for _, script in ipairs(self.meta.script) do
        if script.content then
            local file = File.new((":%s/%s"):format(self.newResourceName, script.src))
            if file then
                file:write(script.content)
                file:close()
            end
        end
    end

    --Create new files
    self:setState(false, "Create files for new resource")
    for _, file in ipairs(self.meta.file) do
        if not utils.isSoundFile(file.src) then
            if file.content then
                local _file = File.new((":%s/%s"):format(self.newResourceName, file.src))
                if _file then
                    _file:write(file.content)
                    _file:close()
                end
            end
        end
    end

    --Create pew script, that override the playSound function to replace stream URL's and some other stuff
    self:setState(false, "Generate pew script for sound replacement")
    self:generatePewScript()
    local file = File.new((":%s/pew.lua"):format(self.newResourceName))
    if file then
        file:write(self.pewScript)
        file:close()
    end

    --Create map file
    self:setState(false, "Create map files for new resource")
    for _, map in ipairs(self.meta.map) do
        if map.content then
            local file = File.new((":%s/%s"):format(self.newResourceName, map.src))
            if file then
                file:write(map.content)
                file:close()
            end
        end
    end

    --Delete old resource, if desired
    if self.deleteOldResource then
        self:setState(false, ("Delete old resource '%s'"):format(self.ResourceName))
        self.mapResource:delete()
    end
    return true
end

function CMapParser:setState(sState, sLogInput)
    if sState then
        self.state = sState
    end

    if sLogInput then
        table.insert(self.log, sLogInput)
    end

    Core:getManager("CMCManager"):sync(self)
end

function CMapParser:generatePewScript()
    self.pewScript = ([[--
-- This file was automatically generated by PewX' Map Parser Resource: https://github.com/HorrorClown/PewX-Map-Parser
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 10.05.2015 - Time: 06:27
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
SERVER = triggerServerEvent == nil
CLIENT = not SERVER

--Override playSound and playSound3D functions
if CLIENT then
    local streamTable = fromJSON('%s')
    local _setElementData = setElementData
    local _playSound = playSound
    local _playSound3D = playSound3D

    function playSound(sSoundPath, bLooped, bThrottled)
        if streamTable then
            for _, stream in ipairs(streamTable) do
                if stream.src == sSoundPath then
                    local sound = _playSound(stream.streamURL, bLooped, bThrottled)
                    if sound then _setElementData(sound, "mapmusic", true) end
                    return sound
                end
            end
        end
        return _playSound(sSoundPath, bLooped, bThrottled)
    end

    function playSound3D(sSoundPath, x, y, z, bLooped, bThrottled)
        if streamTable then
            for _, stream in ipairs(streamTable) do
                if stream.src == sSoundPath then
                    local sound = _playSound3D(stream.streamURL, x, y, z, bLooped, bThrottled)
                    if sound then _setElementData(sound, "mapmusic", true) end
                    return sound
                end
            end
        end
        return _playSound3D(sSoundPath, x, y, z, bLooped, bThrottled)
    end
end

--Override some other functions
if SERVER then
    function setAccountData() return false end
    function getAccountData() return false end
else
    function dxDrawText() return false end
    function guiCreateWindow() return false end
    function guiCreateLabel() return false end
end

function setElementData() return false end
--function getElementData() return false end
function outputChatBox() return false end
function addCommandHandler() return false end

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
end]]):format(toJSON(self.soundFiles))
end
