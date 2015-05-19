--
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 10.05.2015 - Time: 06:27
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
CCore = {}

function CCore:constructor()
    self.managers = {}

    --Manager Table: {"ManagerName", {arguments}}
    table.insert(self.managers, {"CMCManager", {}})
    table.insert(self.managers, {"CResourceManager", {}})
end

function CCore:destructor()

end

function CCore:loadManagers()
    for _, v in ipairs(self.managers) do
        if (type(_G[v[1]]) == "table") then
            debugOutput(("[CCore] Loading manager '%s'"):format(tostring(v[1])))
            self[tostring(v[1])] = new(_G[v[1]], unpack(v[2]))
        else
            debugOutput(("[CCore] Couldn't find manager '%s'"):format(tostring(v[1])))
        end
    end
end

function CCore:initFileSystem()
    --ToDo: Check if a NTFS Hard link set for mapmusic (:MTAMapConverter/mapmusic/)
end

function CCore:getManager(sName)
    return self[sName]
end

addEventHandler("onResourceStart", resourceRoot,
    function()
        local sT = getTickCount()
        debugOutput("[CCore] Starting Core")
        Core = new(CCore)
        Core:loadManagers()
        Core:initFileSystem()
        debugOutput(("[CCore] Starting finished (%sms)"):format(math.floor(getTickCount()-sT)))
    end
)