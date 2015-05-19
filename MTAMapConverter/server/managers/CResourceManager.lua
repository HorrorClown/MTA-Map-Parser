--
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 14.05.2015 - Time: 16:40
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
CResourceManager = {}

function CResourceManager:constructor()
    addEvent("onClientRefreshResources", true)
    addEventHandler("onClientRefreshResources", resourceRoot, bind(CResourceManager.clientRefreshResources, self))
end


function CResourceManager:destructor()

end

function CResourceManager:clientRefreshResources(bOnlyNew, bRefreshAll)
    if bOnlyNew then
        self.currentResources = getResources()
    end

    refreshResources(bRefreshAll)
    self.sendResources = getResources()

    if bOnlyNew then
        self.available = {}

        for i, R1 in ipairs(self.sendResources) do
            for _, R2 in ipairs(self.currentResources) do
                if R1 == R2 then
                    table.insert(self.available, i)
                end
            end
        end

        table.sort(self.available, function(c1, c2) return (c1 > c2) end)

        for _, rID in ipairs(self.available) do
            table.remove(self.sendResources, rID)
        end
    end

    self.ResourceName = {}
    for _, Resource in ipairs(self.sendResources) do
        if Resource:getInfo("type") == "map" and Resource:getInfo("gamemodes") == "race" then
            table.insert(self.ResourceName, {ResourceName = Resource:getName(), Converted = Resource:getInfo("pewConverted")})
        end
    end

    triggerClientEvent(client, "onServerSendResources", client, self.ResourceName)
end