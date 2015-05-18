--
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 14 Ultimate
-- Date: 14.05.2015 - Time: 16:04
-- pewx.de // iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
CClientGUI = {}

function CClientGUI:constructor()
    showCursor(true)
    self.maps = {}

    self.attachedFunction = {}
    self:createGUI()
    self.mapTypeIndex = {["DM"] = 0, ["DD"] = 1, ["Shooter"] = 2, ["Hunter"] = 3}

    addEventHandler("onClientGUIClick", resourceRoot, bind(CClientGUI.onClick, self))

    addEvent("onServerSendResources", true)
    addEvent("onServerAddedMap", true)
    addEvent("onServerRemovedMap", true)

    addEventHandler("onServerAddedMap", me, bind(CClientGUI.serverAddedMap, self))
    addEventHandler("onServerRemovedMap", me, bind(CClientGUI.serverRemovedMap, self))
    addEventHandler("onServerSendResources", me, bind(CClientGUI.receiveResources, self))

    bindKey("arrow_d", "down", bind(CClientGUI.arrowKeyPressed, self))
    bindKey("arrow_u", "down", bind(CClientGUI.arrowKeyPressed, self))

    addEventHandler("onClientGUIChanged", self.gui.custom.customMapName, bind(CClientGUI.liveEdit, self))
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

function CClientGUI:serverRemovedMap(tbl)
    for i, mapTable in ipairs(self.maps) do
        if mapTable.ResourceName == tbl.ResourceName then
            table.remove(self.maps, i)
        end
    end

    local count = guiGridListGetRowCount(self.gui.convertGridlist)-1
    for i = 0, count do
        local itemText = guiGridListGetItemText(self.gui.convertGridlist, i, self.gui.convertColumn)
        if itemText == tbl.ResourceName then
            guiGridListRemoveRow(self.gui.convertGridlist, i)
        end
    end

    local row = guiGridListAddRow(self.gui.mapGridlist)
    guiGridListSetItemText(self.gui.mapGridlist, row, self.gui.mapColumn, tbl.ResourceName, false, false)
    guiGridListSetItemText(self.gui.mapGridlist, row, self.gui.mapIsConColumn,  tbl.Converted and "✓" or "✗", false, false)
end

function CClientGUI:receiveResources(tResources)
    guiGridListClear(self.gui.mapGridlist)

    for i, tResource in ipairs(tResources) do
        if not self:isNotInConvertingList(tResource.ResourceName) then
            if (not tResource.Converted) or self.showConvertedMaps then
                local row = guiGridListAddRow(self.gui.mapGridlist)
                guiGridListSetItemText(self.gui.mapGridlist, row, self.gui.mapColumn, tResource.ResourceName, false, false)
                guiGridListSetItemText(self.gui.mapGridlist, row, self.gui.mapIsConColumn,  tResource.Converted and "✓" or "✗", false, false)
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

function CClientGUI:applyCustomSettings()
    local map = self.currentSelected
    map.useCustom = true
    map.customMapName = guiGetText(self.gui.custom.customMapName)
    map.customMapAuthor = guiGetText(self.gui.custom.customMapAuthor)
    map.customMapType = guiComboBoxGetItemText(self.gui.custom.customMapType, guiComboBoxGetSelected(self.gui.custom.customMapType))
end

function CClientGUI:toggleConvertedMaps()
    self.showConvertedMaps = guiCheckBoxGetSelected(self.gui.showConvertedMaps)
end

function CClientGUI:toggleCustomSettings()
    local state =  guiCheckBoxGetSelected(self.gui.useCustomSettings)
    for _, eGUI in pairs(self.gui.custom) do
        guiSetVisible(eGUI, state)
    end
end

function CClientGUI:updateMapSettings()
    local selectedRow = guiGridListGetSelectedItem(self.gui.convertGridlist)
    local ResourceName = guiGridListGetItemText(self.gui.convertGridlist, selectedRow, 1)

    for _, mapTable in ipairs(self.maps) do
        if mapTable.ResourceName == ResourceName then
            self.currentSelected = mapTable
            guiSetText(self.gui.lbl_ResourceName, tostring(mapTable.ResourceName))
            guiSetText(self.gui.lbl_MapName, tostring(mapTable.mapName))
            guiSetText(self.gui.lbl_MapAuthor, tostring(mapTable.mapAuthor))
            guiSetText(self.gui.lbl_MapType, tostring(mapTable.mapType))
            guiSetText(self.gui.lbl_NewResourceName, tostring(mapTable.newResourceName))
            if not mapTable.useCustom then
                guiSetText(self.gui.custom.customMapName, tostring(mapTable.mapName))
                guiSetText(self.gui.custom.customMapAuthor, tostring(mapTable.mapAuthor))
                guiComboBoxSetSelected(self.gui.custom.customMapType, self.mapTypeIndex[mapTable.mapType] or -1)
            else
                guiSetText(self.gui.custom.customMapName, tostring(mapTable.customMapName))
                guiSetText(self.gui.custom.customMapAuthor, tostring(mapTable.customMapAuthor))
                guiComboBoxSetSelected(self.gui.custom.customMapType, self.mapTypeIndex[mapTable.customMapType] or -1)
            end
            self:liveEdit() --Update new resource name
        end
    end
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

function CClientGUI:liveEdit()
    if guiCheckBoxGetSelected(self.gui.useCustomSettings) then
        local type = guiComboBoxGetItemText(self.gui.custom.customMapType, guiComboBoxGetSelected(self.gui.custom.customMapType))
        local text = guiGetText(self.gui.custom.customMapName)
        guiSetText(self.gui.lbl_NewResourceName, tostring(utils.liveConverting(text, type)))
    end
end

function CClientGUI:createGUI()
    self.gui = {}
    self.gui.window = guiCreateWindow(0, 0, x, y, "PewX' Map Converter", false)

    guiCreateLabel(0.008, 0.03, 1, 1, "Available Map Resources", true, self.gui.window)
    self.gui.mapGridlist = guiCreateGridList(0.008, 0.05, 0.3, 0.865, true, self.gui.window)
    guiGridListSetSelectionMode(self.gui.mapGridlist, 1)
    self.gui.mapColumn = guiGridListAddColumn(self.gui.mapGridlist, "Map", .8)
    self.gui.mapIsConColumn = guiGridListAddColumn(self.gui.mapGridlist, "Converted", .2)

    self.gui.addButton = guiCreateButton(0.31, 0.05, 0.02, 0.9, ">", true, self.gui.window)
    self.gui.remButton = guiCreateButton(0.34, 0.05, 0.02, 0.9, "<", true, self.gui.window)

    self.gui.convertGridlist = guiCreateGridList(0.363, 0.05, 0.3, 0.9, true, self.gui.window)
    guiGridListSetSelectionMode(self.gui.convertGridlist, 1)
    self.gui.convertColumn = guiGridListAddColumn(self.gui.convertGridlist, "Map", .8)
    self.gui.initColumn = guiGridListAddColumn(self.gui.convertGridlist, "Initialised", .2)

    guiCreateLabel(.363, .03, 1, .025, "Converting list", true, self.gui.window)
    guiCreateLabel(.68, .03, 1, .025, "Selected Map Settings", true, self.gui.window)

    guiCreateLabel(.69, .06, 1, 1, "Resource Name:", true, self.gui.window)
    guiCreateLabel(.69, .075, 1, 1, "Map Name:", true, self.gui.window)
    guiCreateLabel(.69, .09, 1, 1, "Map Author:", true, self.gui.window)
    guiCreateLabel(.69, .105, 1, 1, "Map Type:", true, self.gui.window)
    guiCreateLabel(.689, .111, 1, 1, ("_"):rep(60), true, self.gui.window)
    guiCreateLabel(.69, .125, 1, 1, "New Resource Name:", true, self.gui.window)

    self.gui.lbl_ResourceName = guiCreateLabel(.78, .06, 1, 1, "", true, self.gui.window)
    self.gui.lbl_MapName = guiCreateLabel(.78, .075, 1, 1, "", true, self.gui.window)
    self.gui.lbl_MapAuthor = guiCreateLabel(.78, .09, 1, 1, "", true, self.gui.window)
    self.gui.lbl_MapType = guiCreateLabel(.78, .105, 1, 1, "", true, self.gui.window)
    self.gui.lbl_NewResourceName = guiCreateLabel(.78, .125, 1, 1, "", true, self.gui.window)

    self.gui.deleteOldResource = guiCreateCheckBox(.69, .145, .3, .025, "Delete old resource if the map was successfully converted", false, true, self.gui.window)
    self.gui.useCustomSettings = guiCreateCheckBox(.69, .166, .3, .025, "Edit Settings", false, true, self.gui.window)

    --Custom settings guis
    self.gui.custom = {}
    self.gui.custom[1] = guiCreateLabel(.71, .1925, .3, .025, "Map Name:", true, self.gui.window)
    self.gui.custom[2] = guiCreateLabel(.71, .2225, .3, .025, "Map Author:", true, self.gui.window)
    self.gui.custom[3] = guiCreateLabel(.71, .2525, .3, .025, "Map Type:", true, self.gui.window)

    self.gui.custom.customMapName = guiCreateEdit(.76, .19, .2, .022, "", true, self.gui.window)
    self.gui.custom.customMapAuthor = guiCreateEdit(.76, .22, .2, .022, "", true, self.gui.window)
    self.gui.custom.customMapType = guiCreateComboBox(.76, .25, .2, .092, "Select", true, self.gui.window) --self.gui.custom.customMapType = guiCreateEdit(.78, .22, .2, .022, "", true, self.gui.window)
    self.gui.custom.apply = guiCreateButton(.86, .28, .1, .022, "Apply", true, self.gui.window)
    for _, mapType in ipairs({"DM", "DD", "Shooter", "Hunter"}) do guiComboBoxAddItem(self.gui.custom.customMapType, mapType) end
    for _, eGUI in pairs(self.gui.custom) do guiSetVisible(eGUI, false) end
    --End custom settings

    self.gui.startButton = guiCreateButton(.667, .92, .38, .03, "Start Convert", true, self.gui.window)

    self.gui.refreshButton = guiCreateButton(.008, .92, .3, .03, "Refresh", true, self.gui.window)
    self.gui.showOnlyNew = guiCreateCheckBox(.008, .95, .3, .025, "Show only new", true, true, self.gui.window)
    self.gui.showConvertedMaps = guiCreateCheckBox(.008, .97, .3, .025, "Show converted maps", false, true, self.gui.window)

    self:attach(self.gui.refreshButton, bind(CClientGUI.refreshMaps, self))
    self:attach(self.gui.addButton, bind(CClientGUI.addMap, self))
    self:attach(self.gui.remButton, bind(CClientGUI.removeMap, self))
    self:attach(self.gui.showConvertedMaps, bind(CClientGUI.toggleConvertedMaps, self))
    self:attach(self.gui.convertGridlist, bind(CClientGUI.updateMapSettings, self))
    self:attach(self.gui.useCustomSettings, bind(CClientGUI.toggleCustomSettings, self))
    self:attach(self.gui.custom.customMapType, bind(CClientGUI.liveEdit, self))
    self:attach(self.gui.custom.apply, bind(CClientGUI.applyCustomSettings, self))
end