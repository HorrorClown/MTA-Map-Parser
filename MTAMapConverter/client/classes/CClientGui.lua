--
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 14.05.2015 - Time: 16:04
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
CClientGUI = {}

function CClientGUI:constructor()
    self.maps = {}

    self.attachedFunction = {}
    self:createGUI()

    showCursor(true)
    addEventHandler("onClientGUIClick", resourceRoot, bind(CClientGUI.onClick, self))

    addEvent("onServerSendResources", true)
    addEvent("onServerAddedMap", true)
    addEvent("onServerRemovedMap", true)

    addEventHandler("onServerAddedMap", me, bind(CClientGUI.serverAddedMap, self))
    addEventHandler("onServerRemovedMap", me, bind(CClientGUI.serverRemovedMap, self))
    addEventHandler("onServerSendResources", me, bind(CClientGUI.receiveResources, self))

    bindKey("arrow_d", "down", bind(CClientGUI.arrowKeyPressed, self))
    bindKey("arrow_u", "down", bind(CClientGUI.arrowKeyPressed, self))
end

function CClientGUI:destructor()

end

function CClientGUI:arrowKeyPressed(sKey)
    local selectedRow = guiGridListGetSelectedItem(self.gui.convertGridlist)
    local nextSelected = selectedRow + (sKey == "arrow_u" and -1 or 1)
    if nextSelected < 0 then nextSelected = 0 return end
    if nextSelected +1 > guiGridListGetRowCount(self.gui.convertGridlist) then nextSelected = nextSelected -1 return end
    guiGridListSetSelectedItem(self.gui.convertGridlist, nextSelected, 1)
    self:updateMapSettings()
end

function CClientGUI:serverAddedMap(tbl)
    table.insert(self.maps, tbl)

    local row = guiGridListAddRow(self.gui.convertGridlist)
    guiGridListSetItemText(self.gui.convertGridlist, row, self.gui.convertColumn, tbl.ResourceName, false, false)
    guiGridListSetItemText(self.gui.convertGridlist, row, self.gui.initColumn, tbl.initialised and "✓" or "✗", false, false)

    local count = guiGridListGetRowCount(self.gui.mapGridlist)-1
    for i = 0, count do
        local itemText = guiGridListGetItemText(self.gui.mapGridlist, i, self.gui.mapColumn)
        if itemText == tbl.ResourceName then
            guiGridListRemoveRow(self.gui.mapGridlist, i)
        end
    end
end

function CClientGUI:serverRemovedMap(ResourceName)
    --ToDo: Important: Remove Resource from self.maps table!! If not, there will be a bug: Removing a map from converting list, can not be added more..

    local row = guiGridListAddRow(self.gui.mapGridlist)
    guiGridListSetItemText(self.gui.mapGridlist, row, self.gui.mapColumn, ResourceName, false, false)

    local count = guiGridListGetRowCount(self.gui.convertGridlist)-1
    for i = 0, count do
        local itemText = guiGridListGetItemText(self.gui.convertGridlist, i, self.gui.convertColumn)
        if itemText == ResourceName then
            guiGridListRemoveRow(self.gui.convertGridlist, i)
        end
    end
end

function CClientGUI:receiveResources(tResources)
    guiGridListClear(self.gui.mapGridlist)

    for i, tResource in ipairs(tResources) do
        if not self:isNotInConvertingList(tResource.ResourceName) then
            if (not tResource.Converted) or self.showConvertedMaps then
                local row = guiGridListAddRow(self.gui.mapGridlist)
                guiGridListSetItemText(self.gui.mapGridlist, row, self.gui.mapColumn, tResource.ResourceName, false, false)
            end
        end
    end
end

function CClientGUI:isNotInConvertingList(sResourceName)
    for _, tConMap in ipairs(self.maps) do
        if tConMap.ResourceName == sResourceName then
            return true
        end
    end
    return false
end

function CClientGUI:refreshMaps()
    triggerServerEvent("onClientRefreshResources", resourceRoot, guiCheckBoxGetSelected(self.gui.showOnlyNew))
end

function CClientGUI:addMap()
    local stbl = guiGridListGetSelectedItems(self.gui.mapGridlist)
    for _, sItem in ipairs(stbl) do
        local selectedItem = guiGridListGetItemText(self.gui.mapGridlist, sItem.row, self.gui.mapColumn)
        triggerServerEvent("onClientAddMap", resourceRoot, selectedItem)
    end
end

function CClientGUI:removeMap()
    local stbl = guiGridListGetSelectedItems(self.gui.convertGridlist)
    for _, sItem in ipairs(stbl) do
        local selectedItem = guiGridListGetItemText(self.gui.convertGridlist, sItem.row, self.gui.convertColumn)
        triggerServerEvent("onClientRemoveMap", resourceRoot, selectedItem)
    end
end

function CClientGUI:toggleConvertedMaps()
    self.showConvertedMaps = guiCheckBoxGetSelected(self.gui.showConvertedMaps)
end

function CClientGUI:updateMapSettings()
    --ToDo: Update Settings from self.Maps table
end

function CClientGUI:onClick(sButton, sState)
    if sButton ~= "left" or sState ~= "up" then return end

    if self.attachedFunction[source] then
        self.attachedFunction[source]()
    end
end

function CClientGUI:attach(CGUI, fFunction)
    self.attachedFunction[CGUI] = fFunction
end

function CClientGUI:createGUI()
    self.gui = {}
    self.gui.window = guiCreateWindow(0, 0, x, y, "PewX' Map Converter", false)

    guiCreateLabel(0.008, 0.03, 1, 1, "Available Map Resources", true, self.gui.window)
    self.gui.mapGridlist = guiCreateGridList(0.008, 0.05, 0.3, 0.865, true, self.gui.window)
    guiGridListSetSelectionMode(self.gui.mapGridlist, 1)
    self.gui.mapColumn = guiGridListAddColumn(self.gui.mapGridlist, "Map", 1)

    self.gui.addButton = guiCreateButton(0.31, 0.05, 0.02, 0.9, ">", true, self.gui.window)
    self.gui.remButton = guiCreateButton(0.34, 0.05, 0.02, 0.9, "<", true, self.gui.window)

    self.gui.convertGridlist = guiCreateGridList(0.363, 0.05, 0.3, 0.9, true, self.gui.window)
    guiGridListSetSelectionMode(self.gui.convertGridlist, 1)
    self.gui.convertColumn = guiGridListAddColumn(self.gui.convertGridlist, "Map", .8)
    self.gui.initColumn = guiGridListAddColumn(self.gui.convertGridlist, "Initialised", .2)

    guiCreateLabel(0.363, 0.03, 1, .025, "Converting list", true, self.gui.window)
    guiCreateLabel(0.68, 0.03, 1, .025, "Selected Map Settings", true, self.gui.window)

    guiCreateLabel(.69, 0.06, 1, 1, "Resource Name:", true, self.gui.window)
    guiCreateLabel(.69, 0.075, 1, 1, "Map Name:", true, self.gui.window)
    guiCreateLabel(.69, 0.09, 1, 1, "Map Author:", true, self.gui.window)
    guiCreateLabel(.69, 0.105, 1, 1, "Map Type:", true, self.gui.window)
    guiCreateLabel(.69, 0.11, 1, 1, "__________________________________________________________", true, self.gui.window)
    guiCreateLabel(.69, 0.125, 1, 1, "New Resource Name:", true, self.gui.window)

    self.gui.deleteOldResource = guiCreateCheckBox(.69, .145, .3, .025, "Delete old resource if the map was successfully converted", false, true, self.gui.window)
    self.gui.useCustomSettings = guiCreateCheckBox(.69, .166, .3, .025, "Edit Settings", false, true, self.gui.window)

    --self.gui.customSettings = guiCreateEdit(.71, .19, .18, .025, "", true, self.gui.window)

    self.gui.startButton = guiCreateButton(.667, .92, .38, .03, "Start Convert", true, self.gui.window)

    self.gui.refreshButton = guiCreateButton(.008, .92, .3, .03, "Refresh", true, self.gui.window)
    self.gui.showOnlyNew = guiCreateCheckBox(.008, .95, .3, .025, "Show only new", true, true, self.gui.window)
    self.gui.showConvertedMaps = guiCreateCheckBox(.008, .97, .3, .025, "Show converted maps", false, true, self.gui.window)

    self:attach(self.gui.refreshButton, bind(CClientGUI.refreshMaps, self))
    self:attach(self.gui.addButton, bind(CClientGUI.addMap, self))
    self:attach(self.gui.remButton, bind(CClientGUI.removeMap, self))
    self:attach(self.gui.showConvertedMaps, bind(CClientGUI.toggleConvertedMaps, self))
    self:attach(self.gui.convertGridlist, bind(CClientGUI.updateMapSettings, self))
end