--
-- HorrorClown (PewX)
-- Using: IntelliJ IDEA 13 Ultimate
-- Date: 24.12.2014 - Time: 04:34
-- iGaming-mta.de // iRace-mta.de // iSurvival.de // mtasa.de
--
if CLIENT then x, y = guiGetScreenSize() me = getLocalPlayer() end
iDEBUG = true

utils = {}

function utils.isHover(startX, startY, width, height)
    if isCursorShowing() then
        local pos = {getCursorPosition()}
        return (x*pos[1] >= startX) and (x*pos[1] <= startX + width) and (y*pos[2] >= startY) and (y*pos[2] <= startY + height)
    end
    return false
end

function utils.clearText(sText)
    return sText:gsub("#%x%x%x%x%x%x", ""):gsub("#%x%x%x%x%x%x", "")
end

function utils.isSoundFile(sFile)
    return (sFile:find(".mp3", 1) or sFile:find(".ogg", 1))
end

function utils.convert(sText)
    if not sText then return false end
    local newString = ""
    local chars = #sText
    for i = 1, chars do
        local a = sText:byte(i)
        if a == 32 then a = 95 end
        if (a >= 48 and a <= 57) or (a >= 65 and a <= 90) or (a >= 97 and a <= 122) or  a == 95 then
            newString = ("%s%s"):format(newString, string.char(a))
        end
    end
    return newString
end

function utils.getFileExtansion(sFilePath)
    local s = sFilePath:find("/") and sFilePath:find("/") + 1 or 1
    local e = sFilePath:find(".", s, true) + 1
    return sFilePath:sub(e, #sFilePath)
end

function utils.reverseTable(t)
    local reversedTable = {}
    local itemCount = #t
    for k, v in ipairs(t) do
        reversedTable[itemCount + 1 - k] = v
    end
    return reversedTable
end

function utils.liveConverting(sMapName, sMapType)
    if not sMapType then return "Error" end
    if not sMapName then return "Error" end

    local temp = utils.convert(sMapName):gsub("__", "_") --Convert and replace __ with _
    local count = #sMapType + 1

    if temp:byte(count) == 95 then count = count + 1 end

    local split = temp:sub(count, #temp)

    return ("%s_%s"):format(sMapType:upper(), split:lower())
end

function debugOutput(sText, nType, cr, cg, cb)
    if iDEBUG then
        outputDebugString(("[%s] %s"):format(SERVER and "Server" or "Client", tostring(sText)), nType or 3, cr, cg, cb)
    end
end