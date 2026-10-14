local g_Xinfu_Tequan_Frame_UnifiedPosition = nil


local g_UI_Items = {}
local MAX_TeQuanKaItem = 8

local g_UICOMMAND = 99843501

local g_TeQuanKaDataIndexInfo = {
    [1] = {dataIndexLow=1,dataIndexHigh=2,imgActive="set:Xinfu_Tequan image:DJ_JT",imgNegative="set:Xinfu_Tequan image:WJH_JT",toolTips="#{XFTQ_230203_45}"},--精通
    [2] = {dataIndexLow=3,dataIndexHigh=4,imgActive="set:Xinfu_Tequan image:DJ_XY",imgNegative="set:Xinfu_Tequan image:WJH_JT",toolTips="#{XFTQ_230203_46}"},--侠印
    [3] = {dataIndexLow=5,dataIndexHigh=6,imgActive="set:Xinfu_Tequan image:DJ_BJ",imgNegative="set:Xinfu_Tequan image:WJH_JT",toolTips="#{XFTQ_230203_47}"},--宝鉴
    [4] = {dataIndexLow=7,dataIndexHigh=8,imgActive="set:Xinfu_Tequan image:DJ_YS",imgNegative="set:Xinfu_Tequan image:WJH_JT",toolTips="#{XFTQ_230203_49}"},--御兽
    [5] = {dataIndexLow=9,dataIndexHigh=10,imgActive="set:Xinfu_Tequan image:DJ_SQ",imgNegative="set:Xinfu_Tequan image:WJH_JT",toolTips="#{XFTQ_230203_50}"},--神器
    [6] = {dataIndexLow=11,dataIndexHigh=12,imgActive="set:Xinfu_Tequan image:DJ_WQ",imgNegative="set:Xinfu_Tequan image:WJH_JT",toolTips="#{XFTQ_230203_51}"},--王权
    [7] = {dataIndexLow=13,dataIndexHigh=14,imgActive="set:Xinfu_Tequan image:DJ_LW",imgNegative="set:Xinfu_Tequan image:WJH_JT",toolTips="#{XFTQ_230203_52}"},--龙纹
}

local g_IMG_BK = {
    nega = "set:Xinfu_Tequan image:DJ_BK",
    low = "set:Xinfu_Tequan image:GJ_BK",
    high = "set:Xinfu_Tequan image:WJH",
}
--===============================================
-- OnLoad()
--===============================================
function Xinfu_Tequan_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

    this:RegisterEvent("UI_COMMAND",true)

end

function Xinfu_Tequan_OnLoad()
    g_Xinfu_Tequan_Frame_UnifiedPosition	=	Xinfu_Tequan_Frame:GetProperty("UnifiedPosition")
    for i = 1, MAX_TeQuanKaItem do
        g_UI_Items[i] = {
            bk=_G["Xinfu_Tequan_Clinet"..i],
            img =_G[string.format( "Xinfu_Tequan_Clinet%d_InfoNull",i )],
            name =_G[string.format( "Xinfu_Tequan_Clinet%d_InfoName",i )],
            state =_G[string.format( "Xinfu_Tequan_Clinet%d_InfoType",i )],
            time =_G[string.format( "Xinfu_Tequan_Clinet%d_InfoTime",i )],
        }
    end
end

--===============================================
-- OnEvent()
--===============================================
function Xinfu_Tequan_OnEvent( event )
    if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
        local opt = Get_XParam_INT(0)
        if opt == 1 then
            Xinfu_Tequan_Open()
        elseif opt == 2 and this:IsVisible()  then
            Xinfu_Tequan_Open()
        end

       
   
    end
    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
			event == "VIEW_RESOLUTION_CHANGED" then
				Xinfu_Tequan_Frame_On_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end


--===============================================
--刷新界面信息
--===============================================
function Xinfu_Tequan_Open()

    local g_Info = Lua_GetTeQuanKaData()
    assert(type(g_Info) == "table")
    local tqNum = table.getn(g_TeQuanKaDataIndexInfo)
    local activeItems = {}
    local negaItems = {}
    for i = 1, tqNum do
        local tl = g_Info[ g_TeQuanKaDataIndexInfo[i].dataIndexLow ]
        local th = g_Info[ g_TeQuanKaDataIndexInfo[i].dataIndexHigh ]
        if tl == nil or th == nil  then
            break
        end
        if th > 0 then
            table.insert(activeItems,i)
            table.insert(activeItems,2)
        elseif tl > 0 then
            table.insert(activeItems,i)
            table.insert(activeItems,1)
        else
            table.insert(negaItems,i)
        end
    end

    local activeIndex = 1
    local negaIndex = 1
    for i = 1, MAX_TeQuanKaItem do
        if i > tqNum then
            g_UI_Items[i].bk:Hide()
        else
            g_UI_Items[i].bk:Show()
            if activeItems[activeIndex] then
                local typeIndex = activeItems[activeIndex]
                local level = activeItems[activeIndex+1]
                activeIndex = activeIndex + 2
                --展示已激活
                g_UI_Items[i].name:SetProperty("Image",g_TeQuanKaDataIndexInfo[typeIndex].imgActive)
                g_UI_Items[i].img:SetToolTip(g_TeQuanKaDataIndexInfo[typeIndex].toolTips)
                g_UI_Items[i].time:Show()
                local leftMin = 0
                if level == 1 then
                    g_UI_Items[i].img:SetProperty("Image",g_IMG_BK.low)
                    leftMin =  g_Info[g_TeQuanKaDataIndexInfo[typeIndex].dataIndexLow]
                    g_UI_Items[i].state:SetText("#{XFTQ_230203_61}")   
                elseif level == 2 then
                    g_UI_Items[i].img:SetProperty("Image",g_IMG_BK.high)
                    leftMin =  g_Info[g_TeQuanKaDataIndexInfo[typeIndex].dataIndexHigh]
                    g_UI_Items[i].state:SetText("#{XFTQ_230203_62}")
                else
                    g_UI_Items[i].img:SetProperty("Image",g_IMG_BK.nega)
                    g_UI_Items[i].state:SetText("#{XFTQ_230203_63}")
                end
                local leftDays = math.floor(leftMin/(1440))
                if leftDays < 1 then
                    g_UI_Items[i].time:SetText("#{XFTQ_230203_65}")
                else
                    g_UI_Items[i].time:SetText( ScriptGlobal_Format("#{XFTQ_230203_64}",leftDays))
                end
               

            elseif negaItems[negaIndex] then
                local typeIndex = negaItems[negaIndex] 
                negaIndex = negaIndex + 1
                --展示未激活
                g_UI_Items[i].name:SetProperty("Image",g_TeQuanKaDataIndexInfo[typeIndex].imgNegative)
                g_UI_Items[i].state:SetText("#{XFTQ_230203_63}")
                g_UI_Items[i].img:SetProperty("Image",g_IMG_BK.nega)
                g_UI_Items[i].img:SetToolTip(g_TeQuanKaDataIndexInfo[typeIndex].toolTips)
                g_UI_Items[i].time:Hide()
            end
            
        end
    end

    this:Show()


end

--===============================================
--关闭界面
--===============================================
function Xinfu_Tequan_OnClose()

    this:Hide()

end

function Xinfu_Tequan_Frame_On_ResetPos()
	 Xinfu_Tequan_Frame:SetProperty("UnifiedPosition", g_Xinfu_Tequan_Frame_UnifiedPosition)
end
