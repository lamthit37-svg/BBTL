
local g_Frame_UnifiedPosition = nil

local g_ItemImg = 
{
    ["1"] = {set ="" ,image="",itemID =38006113},
	-- ["2"] = {set ="Calendar3" ,image="Level_2",itemID =38006114},
	-- ["3"] = {set ="Calendar4" ,image="Level_3",itemID =38006115},
}


function Valentine_interactionWatch_PreLoad()
    this:RegisterEvent("QRJWORDSOPERATE", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Valentine_interactionWatch_OnLoad()
    g_Frame_UnifiedPosition = Valentine_interactionWatch_FrameNULL:GetProperty("UnifiedPosition")


end

function Valentine_interactionWatch_OnEvent(event)
    if event == "QRJWORDSOPERATE" then
        local opt =  tonumber(arg0)
        if opt == 3 then
            Valentine_interactionWatch_Open()
        end

	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
        Valentine_interactionWatch_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
		Valentine_interactionWatch_OnHide()
	end

end

local function SplitString(str,sep)
    local sep = sep or " "
    local result = {}
    local pattern = string.format( "([^%s]+)",sep )
    string.gsub( str,pattern,function(c)  table.insert(result,c) end )
    return result
end

function Valentine_interactionWatch_Init()
    Valentine_interactionWatch_Client1_Text:SetText("")
    Valentine_interactionWatch_Girlname:SetText("")
    Valentine_interactionWatch1:SetText("")
    Valentine_interactionWatch_Boyname:SetText("")
    Valentine_interactionWatch2:SetText("")
end

function Valentine_interactionWatch_Open()
    Valentine_interactionWatch_Init()
    local strData = arg1
    local strTable = SplitString(strData,'\t')
    if table.getn(strTable) == 5 then
        local strImgIndex = strTable[1] --花灯图片index
        local itemName = ""
        if g_ItemImg[strImgIndex] then
            --Valentine_interactionWatch_Client1_Huadeng:SetImage(g_ItemImg[strImgIndex].set,g_ItemImg[strImgIndex].image)
            itemName = DataPool:Lua_GetItemNameByIndex(g_ItemImg[strImgIndex].itemID)
        end
        Valentine_interactionWatch_Girlname:SetText(ScriptGlobal_Format("#{QRJH_20221109_103}",strTable[2]))
        Valentine_interactionWatch2:SetText(ScriptGlobal_Format("#{QRJH_20221109_101}",strTable[3]))
        Valentine_interactionWatch_Boyname:SetText(ScriptGlobal_Format("#{QRJH_20221109_102}",strTable[4]))
        Valentine_interactionWatch1:SetText(ScriptGlobal_Format("#{QRJH_20221109_100}",strTable[5]))
        Valentine_interactionWatch_Client1_Text:SetText(ScriptGlobal_Format("#{QRJH_20221109_99}",strTable[2],strTable[4],itemName)) -- 日期
    end
    this:Show()
end


function Valentine_interactionWatch_On_ResetPos()
    if (this:IsVisible()) then
        if (g_Frame_UnifiedPosition ~= nil) then
            Valentine_interactionWatch_FrameNULL:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
        end
    end
end



function Valentine_interactionWatch_OnHide()
    this:Hide()
end



function Valentine_interactionWatch_Close()
    Valentine_interactionWatch_OnHide()
end 