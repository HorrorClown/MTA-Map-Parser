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
    self:createMainGUI()
    self:createConvertGUI()
    self.mapTypeIndex = {["DM"] = 0, ["DD"] = 1, ["Shooter"] = 2, ["Hunter"] = 3}

    addEventHandler("onClientGUIClick", resourceRoot, bind(CClientGUI.onClick, self))

    addEvent("onServerSendResources", true)
    addEvent("onServerAddedMap", true)
    addEvent("onServerRemovedMap", true)
    addEvent("onServerSyncConverting", true)
    addEvent("onServerConvertingDone", true)

    addEventHandler("onServerAddedMap", me, bind(CClientGUI.serverAddedMap, self))
    addEventHandler("onServerRemovedMap", me, bind(CClientGUI.serverRemovedMap, self))
    addEventHandler("onServerSendResources", me, bind(CClientGUI.receiveResources, self))
    addEventHandler("onServerSyncConverting", me, bind(CClientGUI.serverSyncConverting, self))
    addEventHandler("onServerConvertingDone", me, bind(CClientGUI.serverConvertingDone, self))

    bindKey("arrow_d", "down", bind(CClientGUI.arrowKeyPressed, self))
    bindKey("arrow_u", "down", bind(CClientGUI.arrowKeyPressed, self))
end

function CClientGUI:destructor()

end

function CClientGUI:arrowKeyPressed(sKey)
    local selectedRow = guiGridListGetSelectedItem(self.gui_main.convertGridlist)
    local nextSelected = selectedRow + (sKey == "arrow_u" and -1 or 1)
    if nextSelected < 0 then nextSelected = 0 return end
    if nextSelected +1 > guiGridListGetRowCount(self.gui_main.convertGridlist) then nextSelected = nextSelected -1 return end
    guiGridListSetSelectedItem(self.gui_main.convertGridlist, nextSelected, 1)
    self:updateMapSettings()
end

function CClientGUI:serverAddedMap(tbl)
    table.insert(self.maps, tbl)

    local row = guiGridListAddRow(self.gui_main.convertGridlist)
    guiGridListSetItemText(self.gui_main.convertGridlist, row, self.gui_main.convertColumn, tbl.ResourceName, false, false)
    guiGridListSetItemText(self.gui_main.convertGridlist, row, self.gui_main.initColumn, tbl.initialised and "✓" or "✗", false, false)

    local count = guiGridListGetRowCount(self.gui_main.mapGridlist)-1
    for i = 0, count do
        local itemText = guiGridListGetItemText(self.gui_main.mapGridlist, i, self.gui_main.mapColumn)
        if itemText == tbl.ResourceName then
            guiGridListRemoveRow(self.gui_main.mapGridlist, i)
        end
    end
end

function CClientGUI:serverRemovedMap(tbl)
    for i, mapTable in ipairs(self.maps) do
        if mapTable.ResourceName == tbl.ResourceName then
            table.remove(self.maps, i)
        end
    end

    local count = guiGridListGetRowCount(self.gui_main.convertGridlist)-1
    for i = 0, count do
        local itemText = guiGridListGetItemText(self.gui_main.convertGridlist, i, self.gui_main.convertColumn)
        if itemText == tbl.ResourceName then
            guiGridListRemoveRow(self.gui_main.convertGridlist, i)
        end
    end

    local row = guiGridListAddRow(self.gui_main.mapGridlist)
    guiGridListSetItemText(self.gui_main.mapGridlist, row, self.gui_main.mapColumn, tbl.ResourceName, false, false)
    guiGridListSetItemText(self.gui_main.mapGridlist, row, self.gui_main.mapIsConColumn,  tbl.Converted and "✓" or "✗", false, false)
end

function CClientGUI:receiveResources(tResources)
    debugOutput(("Received %s maps in %sms"):format(#tResources, getTickCount()-self.startTick))

    guiGridListClear(self.gui_main.mapGridlist)

    for i, tResource in ipairs(tResources) do
        if not self:isNotInConvertingList(tResource.ResourceName) then
            if (not tResource.Converted) or self.showConvertedMaps then
                local row = guiGridListAddRow(self.gui_main.mapGridlist)
                guiGridListSetItemText(self.gui_main.mapGridlist, row, self.gui_main.mapColumn, tResource.ResourceName, false, false)
                guiGridListSetItemText(self.gui_main.mapGridlist, row, self.gui_main.mapIsConColumn,  tResource.Converted and "✓" or "✗", false, false)
            end
        end
    end

    guiSetProperty(self.gui_main.refreshButton, "Disabled", "false")
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
    self.startTick = getTickCount()
    guiSetProperty(self.gui_main.refreshButton, "Disabled", "true")
    triggerServerEvent("onClientRefreshResources", resourceRoot, guiCheckBoxGetSelected(self.gui_main.showOnlyNew), guiCheckBoxGetSelected(self.gui_main.refreshAll))
end

function CClientGUI:addMap()
    local stbl = guiGridListGetSelectedItems(self.gui_main.mapGridlist)
    for _, sItem in ipairs(stbl) do
        local selectedItem = guiGridListGetItemText(self.gui_main.mapGridlist, sItem.row, self.gui_main.mapColumn)
        triggerServerEvent("onClientAddMap", resourceRoot, selectedItem)
    end
end

function CClientGUI:removeMap()
    local stbl = guiGridListGetSelectedItems(self.gui_main.convertGridlist)
    for _, sItem in ipairs(stbl) do
        local selectedItem = guiGridListGetItemText(self.gui_main.convertGridlist, sItem.row, self.gui_main.convertColumn)
        triggerServerEvent("onClientRemoveMap", resourceRoot, selectedItem)
    end
end

function CClientGUI:applyCustomSettings()
    local map = self.currentSelected
    map.useCustom = true
    map.customMapName = guiGetText(self.gui_main.custom.customMapName)
    map.customMapAuthor = guiGetText(self.gui_main.custom.customMapAuthor)
    map.customMapType = guiComboBoxGetItemText(self.gui_main.custom.customMapType, guiComboBoxGetSelected(self.gui_main.custom.customMapType))
    triggerServerEvent("onClientApplySettings", resourceRoot, map)
end

function CClientGUI:toggleConvertedMaps()
    self.showConvertedMaps = guiCheckBoxGetSelected(self.gui_main.showConvertedMaps)
end

function CClientGUI:toggleCustomSettings()
    local state =  guiCheckBoxGetSelected(self.gui_main.useCustomSettings)
    for _, eGUI in pairs(self.gui_main.custom) do
        guiSetVisible(eGUI, state)
    end
end

function CClientGUI:updateMapSettings()
    local selectedRow = guiGridListGetSelectedItem(self.gui_main.convertGridlist)
    local ResourceName = guiGridListGetItemText(self.gui_main.convertGridlist, selectedRow, 1)

    for _, mapTable in ipairs(self.maps) do
        if mapTable.ResourceName == ResourceName then
            self.currentSelected = mapTable
            guiSetText(self.gui_main.lbl_ResourceName, tostring(mapTable.ResourceName))
            guiSetText(self.gui_main.lbl_MapName, tostring(mapTable.mapName))
            guiSetText(self.gui_main.lbl_MapAuthor, tostring(mapTable.mapAuthor))
            guiSetText(self.gui_main.lbl_MapType, tostring(mapTable.mapType))
            guiSetText(self.gui_main.lbl_NewResourceName, tostring(mapTable.newResourceName))
            if not mapTable.useCustom then
                guiSetText(self.gui_main.custom.customMapName, tostring(mapTable.mapName))
                guiSetText(self.gui_main.custom.customMapAuthor, tostring(mapTable.mapAuthor))
                guiComboBoxSetSelected(self.gui_main.custom.customMapType, self.mapTypeIndex[mapTable.mapType] or -1)
            else
                guiSetText(self.gui_main.custom.customMapName, tostring(mapTable.customMapName))
                guiSetText(self.gui_main.custom.customMapAuthor, tostring(mapTable.customMapAuthor))
                guiComboBoxSetSelected(self.gui_main.custom.customMapType, self.mapTypeIndex[mapTable.customMapType] or -1)
            end
            self:liveEdit()
        end
    end
end

function CClientGUI:startConverting()
    guiSetProperty(self.gui_convert.btn_back, "Disabled", "true")
    guiSetProperty(self.gui_convert.btn_start, "Disabled", "true")
    triggerServerEvent("onClientStartConvert", resourceRoot)
end

function CClientGUI:serverConvertingDone()
    guiSetProperty(self.gui_convert.btn_back, "Disabled", "false")
    self.maps = {}
    guiGridListClear(self.gui_main.convertGridlist)

    self:refreshMaps()
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
    if guiCheckBoxGetSelected(self.gui_main.useCustomSettings) then
        local type = guiComboBoxGetItemText(self.gui_main.custom.customMapType, guiComboBoxGetSelected(self.gui_main.custom.customMapType))
        local text = guiGetText(self.gui_main.custom.customMapName)
        guiSetText(self.gui_main.lbl_NewResourceName, tostring(utils.liveConverting(text, type)))
    end
end

function CClientGUI:createMainGUI()
    self.gui_main = {}
    self.gui_main.window = guiCreateWindow(0, 0, x, y, "PewX' Map Converter", false)

    guiCreateLabel(.008, .03, 1, 1, "Available Map Resources", true, self.gui_main.window)
    self.gui_main.mapGridlist = guiCreateGridList(.008, .05, .3, .865, true, self.gui_main.window)
    guiGridListSetSelectionMode(self.gui_main.mapGridlist, 1)
    self.gui_main.mapColumn = guiGridListAddColumn(self.gui_main.mapGridlist, "Map", .8)
    self.gui_main.mapIsConColumn = guiGridListAddColumn(self.gui_main.mapGridlist, "Converted", .2)

    self.gui_main.addButton = guiCreateButton(.31, .05, .02, .9, ">", true, self.gui_main.window)
    self.gui_main.remButton = guiCreateButton(.34, .05, .02, .9, "<", true, self.gui_main.window)

    self.gui_main.convertGridlist = guiCreateGridList(.363, .05, .3, .9, true, self.gui_main.window)
    guiGridListSetSelectionMode(self.gui_main.convertGridlist, 1)
    self.gui_main.convertColumn = guiGridListAddColumn(self.gui_main.convertGridlist, "Map", .8)
    self.gui_main.initColumn = guiGridListAddColumn(self.gui_main.convertGridlist, "Initialised", .2)

    guiCreateLabel(.363, .03, 1, .025, "Converting list", true, self.gui_main.window)
    guiCreateLabel(.68, .03, 1, .025, "Selected Map Settings", true, self.gui_main.window)

    guiCreateLabel(.69, .06, 1, 1, "Resource Name:", true, self.gui_main.window)
    guiCreateLabel(.69, .075, 1, 1, "Map Name:", true, self.gui_main.window)
    guiCreateLabel(.69, .09, 1, 1, "Map Author:", true, self.gui_main.window)
    guiCreateLabel(.69, .105, 1, 1, "Map Type:", true, self.gui_main.window)
    guiCreateLabel(.689, .111, 1, 1, ("_"):rep(60), true, self.gui_main.window)
    guiCreateLabel(.69, .125, 1, 1, "New Resource Name:", true, self.gui_main.window)

    self.gui_main.lbl_ResourceName = guiCreateLabel(.78, .06, 1, 1, "", true, self.gui_main.window)
    self.gui_main.lbl_MapName = guiCreateLabel(.78, .075, 1, 1, "", true, self.gui_main.window)
    self.gui_main.lbl_MapAuthor = guiCreateLabel(.78, .09, 1, 1, "", true, self.gui_main.window)
    self.gui_main.lbl_MapType = guiCreateLabel(.78, .105, 1, 1, "", true, self.gui_main.window)
    self.gui_main.lbl_NewResourceName = guiCreateLabel(.78, .125, 1, 1, "", true, self.gui_main.window)

    self.gui_main.deleteOldResource = guiCreateCheckBox(.69, .145, .3, .025, "Delete old resource if the map was successfully converted", true, true, self.gui_main.window)
    self.gui_main.useCustomSettings = guiCreateCheckBox(.69, .166, .3, .025, "Edit Settings", false, true, self.gui_main.window)

    --Custom settings guis
    self.gui_main.custom = {}
    self.gui_main.custom[1] = guiCreateLabel(.71, .1925, .3, .025, "Map Name:", true, self.gui_main.window)
    self.gui_main.custom[2] = guiCreateLabel(.71, .2225, .3, .025, "Map Author:", true, self.gui_main.window)
    self.gui_main.custom[3] = guiCreateLabel(.71, .2525, .3, .025, "Map Type:", true, self.gui_main.window)

    self.gui_main.custom.customMapName = guiCreateEdit(.76, .19, .2, .022, "", true, self.gui_main.window)
    self.gui_main.custom.customMapAuthor = guiCreateEdit(.76, .22, .2, .022, "", true, self.gui_main.window)
    self.gui_main.custom.customMapType = guiCreateComboBox(.76, .25, .2, .092, "Select", true, self.gui_main.window) --self.gui_main.custom.customMapType = guiCreateEdit(.78, .22, .2, .022, "", true, self.gui_main.window)
    self.gui_main.custom.apply = guiCreateButton(.86, .28, .1, .022, "Apply", true, self.gui_main.window)
    for _, mapType in ipairs({"DM", "DD", "Shooter", "Hunter"}) do guiComboBoxAddItem(self.gui_main.custom.customMapType, mapType) end
    for _, eGUI in pairs(self.gui_main.custom) do guiSetVisible(eGUI, false) end
    --End custom settings

    self.gui_main.showConvertWindow = guiCreateButton(.667, .92, .38, .03, "Show convert window", true, self.gui_main.window)

    self.gui_main.refreshButton = guiCreateButton(.008, .92, .3, .03, "Refresh", true, self.gui_main.window)
    self.gui_main.showOnlyNew = guiCreateCheckBox(.008, .95, .1, .025, "Show only new", true, true, self.gui_main.window)
    self.gui_main.showConvertedMaps = guiCreateCheckBox(.008, .97, .1, .025, "Show converted maps", false, true, self.gui_main.window)
    self.gui_main.refreshAll = guiCreateCheckBox(.15, .95, .1, .025, "Refresh all", false, true, self.gui_main.window)

    self:attach(self.gui_main.refreshButton, bind(CClientGUI.refreshMaps, self))
    self:attach(self.gui_main.addButton, bind(CClientGUI.addMap, self))
    self:attach(self.gui_main.remButton, bind(CClientGUI.removeMap, self))
    self:attach(self.gui_main.showConvertedMaps, bind(CClientGUI.toggleConvertedMaps, self))
    self:attach(self.gui_main.convertGridlist, bind(CClientGUI.updateMapSettings, self))
    self:attach(self.gui_main.useCustomSettings, bind(CClientGUI.toggleCustomSettings, self))
    self:attach(self.gui_main.custom.customMapType, bind(CClientGUI.liveEdit, self))
    self:attach(self.gui_main.custom.apply, bind(CClientGUI.applyCustomSettings, self))
    self:attach(self.gui_main.showConvertWindow, bind(CClientGUI.toggleWindow, self))

    addEventHandler("onClientGUIChanged", self.gui_main.custom.customMapName, bind(CClientGUI.liveEdit, self))
end

--Converting GUI

function CClientGUI:toggleWindow()
    local mainState = guiGetVisible(self.gui_main.window)

    guiSetVisible(self.gui_main.window, not mainState)
    guiSetVisible(self.gui_convert.window, mainState)

    if mainState then
        self:setUpConvertingList()
        guiSetProperty(self.gui_convert.btn_start, "Disabled", "false")
    end
end

function CClientGUI:createConvertGUI()
    self.gui_convert = {}
    self.gui_convert.window = guiCreateWindow(0, 0, x, y, "PewX' Map Converter", false)
    guiSetVisible(self.gui_convert.window, false)

    self.gui_convert.btn_back = guiCreateButton(.008, .03, .1, .022, "Back", true, self.gui_convert.window)
    self.gui_convert.btn_start = guiCreateButton(.892, .03, .1, .022, "Convert", true, self.gui_convert.window)

    self.gui_convert.gridlist = guiCreateGridList(.008, .06, .985, .98, true, self.gui_convert.window)
    self.gui_convert.column_name = guiGridListAddColumn(self.gui_convert.gridlist, "Map Name", .3)
    self.gui_convert.column_state = guiGridListAddColumn(self.gui_convert.gridlist, "State", .1)
    self.gui_convert.column_current = guiGridListAddColumn(self.gui_convert.gridlist, "Current process", .58)
    guiGridListSetSortingEnabled(self.gui_convert.gridlist, false)

    self:attach(self.gui_convert.btn_back, bind(CClientGUI.toggleWindow, self))
    self:attach(self.gui_convert.btn_start, bind(CClientGUI.startConverting, self))

    addEventHandler("onClientGUIDoubleClick", self.gui_convert.gridlist, bind(CClientGUI.createLogWindow, self))
end

function CClientGUI:setUpConvertingList(tConvertingTable)
    guiGridListClear(self.gui_convert.gridlist)
    for _, conTable in ipairs(self.maps) do
        local row = guiGridListAddRow(self.gui_convert.gridlist)
        guiGridListSetItemText(self.gui_convert.gridlist, row, self.gui_convert.column_name, (conTable.useCustom and conTable.customMapName or conTable.mapName) or "Error", false, false)
        guiGridListSetItemText(self.gui_convert.gridlist, row, self.gui_convert.column_state, conTable.state, false, false)
        guiGridListSetItemText(self.gui_convert.gridlist, row, self.gui_convert.column_current, conTable.log[#conTable.log] , false, false)
        guiGridListSetItemData(self.gui_convert.gridlist, row, self.gui_convert.column_name, conTable)
    end
end

function CClientGUI:serverSyncConverting(tConvertTable)
    local count = guiGridListGetRowCount(self.gui_convert.gridlist)
    for row = 0, count do
        local data = guiGridListGetItemData(self.gui_convert.gridlist, row, self.gui_convert.column_name)
        if data and data.ResourceName == tConvertTable.ResourceName then
            guiGridListSetItemText(self.gui_convert.gridlist, row, self.gui_convert.column_state, tConvertTable.state, false, false)
            guiGridListSetItemText(self.gui_convert.gridlist, row, self.gui_convert.column_current, tConvertTable.log[#tConvertTable.log] , false, false)
            guiGridListSetItemData(self.gui_convert.gridlist, row, self.gui_convert.column_name, tConvertTable)
            return
        end
    end
end

--Log Window

function CClientGUI:createLogWindow()
    if self.gui_log and self.gui_log.window then
        self:updateLog()
        return
    end

    self.gui_log = {}
    self.gui_log.window = guiCreateWindow(.7, .6, .3, .4, "Log", true)

    self.gui_log.button = guiCreateButton(.008, .06, .1, .05, "Close", true, self.gui_log.window)
    self.gui_log.gridlist = guiCreateGridList(.008, .13, .985, .98, true, self.gui_log.window)
    self.gui_log.column = guiGridListAddColumn(self.gui_log.gridlist, "Log", .9)

    self:updateLog()
    self:attach(self.gui_log.button, bind(CClientGUI.closeLogWindow, self))
end

function CClientGUI:updateLog()
    local selRow = guiGridListGetSelectedItem(self.gui_convert.gridlist)
    local data = guiGridListGetItemData(self.gui_convert.gridlist, selRow, self.gui_convert.column_name)

    guiSetText(self.gui_log.window, ("Log '%s'"):format(data.ResourceName))
    guiGridListClear(self.gui_log.gridlist)
    for _, logEntry in ipairs(data.log) do
        if logEntry ~= "" then
            local row = guiGridListAddRow(self.gui_log.gridlist)
            guiGridListSetItemText(self.gui_log.gridlist, row, self.gui_log.column, logEntry, false, false)
        end
    end

    guiBringToFront(self.gui_log.window)
end

function CClientGUI:closeLogWindow()
    if self.gui_log and self.gui_log.window then destroyElement(self.gui_log.window) end
    self.gui_log = nil
end