--活跃积分商店 
local g_QiXi_Choujiang_Frame_UnifiedXPosition
local g_QiXi_Choujiang_Frame_UnifiedYPosition  
local g_QiXi_Choujiang_Curpage = 1
local g_QiXi_Choujiang_OpenDate ={
    [1] = 2022080622,
    [2] = 2022081022,
    [3] = 2022081322,
}
local g_QiXi_Choujiang_AwardTextStr ={
    [1] = {
            [1] = "#{QXJCJ_20220523_13}",
            [2] = "#{QXJCJ_20220523_13}",
            [3] = "#{QXJCJ_20220523_13}",
        },
    [2] = {
            [1] = "#{QXJCJ_20220523_14}",
            [2] = "#{QXJCJ_20220523_14}",
            [3] = "#{QXJCJ_20220523_14}",
        },
    [3] = {
            [1] = "#{QXJCJ_20220523_15}",
            [2] = "#{QXJCJ_20220523_15}",
            [3] = "#{QXJCJ_20220523_15}",
        },
}
local g_QiXi_Choujiang_XuYuanText ={
    [0] = { --未许愿 开奖前                        
        [1] = "#{QXJCJ_20220523_21}",
        [2] = "#{QXJCJ_20220523_22}",
        [3] = "#{QXJCJ_20220523_23}", 
    },
    [1] = { --许愿  开奖前                          
        [1] = "#{QXJCJ_20220523_24}",
        [2] = "#{QXJCJ_20220523_25}",
        [3] = "#{QXJCJ_20220523_26}", 
    },
    [2] = { --中奖未领奖
        [1] = "#{QXJCJ_20220523_27}",
        [2] = "#{QXJCJ_20220523_27}",
        [3] = "#{QXJCJ_20220523_27}", 
    },
    [3] = { --已领奖
        [1] = "",
        [2] = "",
        [3] = "", 
    },
    [4] = { --未许愿 开奖后 或者未中奖
        [1] = "",
        [2] = "",
        [3] = "", 
    },
}
local g_QiXi_Choujiang_DataImg = {
    [1] = "set:QiXi_Choujiang image:Aug_6",
    [2] = "set:QiXi_Choujiang image:Aug_10",
    [3] = "set:QiXi_Choujiang image:Aug_13",
}
local g_QiXi_Choujiang_BtnImg ={
    [0] = { --未许愿 开奖前            
        [1] = {key="PushedImage",value="set:QiXi_Choujiang image:Wenqing_Pushed"},           
        [2] = {key="NormalImage",value="set:QiXi_Choujiang image:Wenqing_Normal"},           
        [3] = {key="HoverImage", value="set:QiXi_Choujiang image:Wenqing_Hover"},            
    },
    [1] = { --许愿  开奖前  
        [1] = {key="PushedImage",value="set:QiXi_Choujiang image:Wenqing_Disabled",},           
        [2] = {key="NormalImage",value="set:QiXi_Choujiang image:Wenqing_Disabled",},           
        [3] = {key="HoverImage", value="set:QiXi_Choujiang image:Wenqing_Disabled",},      
        [4] = {key="DisabledImage", value="set:QiXi_Choujiang image:Wenqing_Disabled",},     
    },
    [2] = { --中奖未领奖
        [1] = {key="PushedImage",value="set:QiXi_Choujiang image:Award_Pushed",},           
        [2] = {key="NormalImage",value="set:QiXi_Choujiang image:Award_Normal",},           
        [3] = {key="HoverImage", value="set:QiXi_Choujiang image:Award_Hover", },  
    },
    [3] = { --已领奖
        [1] = {key="PushedImage",value="set:QiXi_Choujiang image:Getaward",},           
        [2] = {key="NormalImage",value="set:QiXi_Choujiang image:Getaward",},           
        [3] = {key="HoverImage", value="set:QiXi_Choujiang image:Getaward",},    
        [4] = {key="DisabledImage", value="set:QiXi_Choujiang image:Getaward",}, 
    },
    [4] = { --未许愿 开奖后 或者未中奖
        [1] = {key="PushedImage",value="set:QiXi_Choujiang image:Over",},           
        [2] = {key="NormalImage",value="set:QiXi_Choujiang image:Over",},           
        [3] = {key="HoverImage", value="set:QiXi_Choujiang image:Over",},      
        [4] = {key="DisabledImage", value="set:QiXi_Choujiang image:Over",},      
    },
}
local g_QiXi_Choujiang_XuYuantips ={
    [1] = "#{QXJCJ_20220523_29}",
    [2] = "#{QXJCJ_20220523_30}",
    [3] = "#{QXJCJ_20220523_31}",
}
local g_QiXi_Choujiang_ChouJiangtips ={
    [1] = "#{QXJCJ_20220523_41}",
    [2] = "#{QXJCJ_20220523_41}",
    [3] = "#{QXJCJ_20220523_41}",
}
local g_QiXi_Choujiang_round      = {[1] ={},[2] ={},[3] ={},}
local g_QiXi_Choujiang_bingqishuliang = 0
local g_QiXi_Choujiang_servertime = 0
local g_QiXi_Choujiang_status = {}
local g_QiXi_Icon ={}
local g_QiXi_tab = {} 
local g_QiXi_TabRedTipsStatus = {0,0,0}
local g_QiXi_TabRedTipsctl = {}
local g_QiXi_awardtext ={}
local g_QiXi_awardinfo ={
    [1] = {[1] = 39923917,[2] = 39923278,[3] = 39921363,},
    [2] = {[1] = 39923917,[2] = 39923918,[3] = 39921362,},
    [3] = {[1] = 39923917,[2] = 39921394,[3] = 39923919,},
} 
function QiXi_Choujiang_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("OPEN_QIXICHOUJIANG",true) 
	
end

function QiXi_Choujiang_OnLoad() 
	g_QiXi_Choujiang_Frame_UnifiedXPosition = QiXi_Choujiang_Frame_BK:GetProperty("UnifiedXPosition") 
    g_QiXi_Choujiang_Frame_UnifiedYPosition = QiXi_Choujiang_Frame_BK:GetProperty("UnifiedYPosition")  
    g_QiXi_Icon[1]      = QiXi_Choujiang_RewardIcon1
    g_QiXi_Icon[2]      = QiXi_Choujiang_RewardIcon2
    g_QiXi_Icon[3]      = QiXi_Choujiang_RewardIcon3
    g_QiXi_awardtext[1] = QiXi_Choujiang_Name1
    g_QiXi_awardtext[2] = QiXi_Choujiang_Name2
    g_QiXi_awardtext[3] = QiXi_Choujiang_Name3
    g_QiXi_tab[1]       = QiXi_Choujiang_Button01
    g_QiXi_tab[2]       = QiXi_Choujiang_Button02
    g_QiXi_tab[3]       = QiXi_Choujiang_Button03
    g_QiXi_TabRedTipsctl[1]= QiXi_Choujiang_Button01_Tips
    g_QiXi_TabRedTipsctl[2]= QiXi_Choujiang_Button02_Tips
    g_QiXi_TabRedTipsctl[3]= QiXi_Choujiang_Button03_Tips 
end
 
--=========
-- Event
--=========
function QiXi_Choujiang_OnEvent(event) 
    if event == "OPEN_QIXICHOUJIANG"  then --  
		if this:IsVisible() then
			QiXi_Choujiang_Close()
			return
        end   
        QiXi_Choujiang_AskData()         
        QiXi_Choujiang_SetCurPage()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_Choujiang_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		QiXi_Choujiang_Close()
	elseif event == "ADJEST_UI_POS" then
        QiXi_Choujiang_On_ResetPos() 		
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 88891801 ) then
        g_QiXi_Choujiang_bingqishuliang =  Get_XParam_INT( 0 );  --激活兵器数量
        g_QiXi_Choujiang_servertime     =  Get_XParam_INT( 1 );  --服务器时间
        g_QiXi_Choujiang_status[1]      =  Get_XParam_INT( 2 );  --状态分类显示按钮1 
        g_QiXi_Choujiang_status[2]      =  Get_XParam_INT( 3 );  --状态分类显示按钮2
        g_QiXi_Choujiang_status[3]      =  Get_XParam_INT( 4 );  --状态分类显示按钮3 
        g_QiXi_Choujiang_round[1][1]   =  Get_XParam_STR( 0 );  --名字
        g_QiXi_Choujiang_round[1][2]   =  Get_XParam_STR( 1 );  --名字
        g_QiXi_Choujiang_round[1][3]   =  Get_XParam_STR( 2 );  --名字
        g_QiXi_Choujiang_round[2][1]   =  Get_XParam_STR( 3 );  --名字
        g_QiXi_Choujiang_round[2][2]   =  Get_XParam_STR( 4 );  --名字
        g_QiXi_Choujiang_round[2][3]   =  Get_XParam_STR( 5 );  --名字
        g_QiXi_Choujiang_round[3][1]   =  Get_XParam_STR( 6 );  --名字
        g_QiXi_Choujiang_round[3][2]   =  Get_XParam_STR( 7 );  --名字
        g_QiXi_Choujiang_round[3][3]   =  Get_XParam_STR( 8 );  --名字
        g_QiXi_TabRedTipsStatus[1]           =  Get_XParam_INT( 5 );  --红点 
        g_QiXi_TabRedTipsStatus[2]           =  Get_XParam_INT( 6 );  --红点 
        g_QiXi_TabRedTipsStatus[3]           =  Get_XParam_INT( 7 );  --红点 
        QiXi_Choujiang_Open()         
        this:Show()
	end

end
 
--=========
-- 重置
--=========
function QiXi_Choujiang_On_ResetPos()

	QiXi_Choujiang_Frame_BK:SetProperty("UnifiedXPosition", g_QiXi_Choujiang_Frame_UnifiedXPosition)
	QiXi_Choujiang_Frame_BK:SetProperty("UnifiedYPosition", g_QiXi_Choujiang_Frame_UnifiedYPosition)

end

function QiXi_Choujiang_OnHiden()
    g_QiXi_Choujiang_Curpage = 1
    QiXi_Choujiang_Close()
    
end
--=========
-- 关闭
--=========
function QiXi_Choujiang_Close()  
	this:Hide()
end

function QiXi_Choujiang_AskData() 
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetChouJiangInfo" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 888918 );				        -- 脚本编号
		--Set_XSCRIPT_Parameter( 0, AchieveId );		    -- 参数一
		Set_XSCRIPT_ParamCount( 0 );				        -- 参数个数
	Send_XSCRIPT()
end

function QiXi_Choujiang_ChouJiang() 
    --许愿
    if g_QiXi_Choujiang_status[g_QiXi_Choujiang_Curpage] == 0 or g_QiXi_Choujiang_status[g_QiXi_Choujiang_Curpage] == 1 then        
        Clear_XSCRIPT()
	    	Set_XSCRIPT_Function_Name( "XuYuan" ); 	-- 脚本函数名称
	    	Set_XSCRIPT_ScriptID( 888918 );				        -- 脚本编号
	    	Set_XSCRIPT_Parameter( 0, g_QiXi_Choujiang_Curpage );		    -- 参数一
	    	Set_XSCRIPT_ParamCount( 1 );				        -- 参数个数
	    Send_XSCRIPT()
    --抽奖
    elseif g_QiXi_Choujiang_status[g_QiXi_Choujiang_Curpage] == 2 or g_QiXi_Choujiang_status[g_QiXi_Choujiang_Curpage] == 3 then       
        Clear_XSCRIPT()
	    	Set_XSCRIPT_Function_Name( "GetAward" ); 	-- 脚本函数名称
	    	Set_XSCRIPT_ScriptID( 888918 );				        -- 脚本编号
	    	Set_XSCRIPT_Parameter( 0, g_QiXi_Choujiang_Curpage );		    -- 参数一
	    	Set_XSCRIPT_ParamCount( 1 );				        -- 参数个数
	    Send_XSCRIPT()
    --过期
    else
        
    end
end

--=========
-- 打开
--=========
function QiXi_Choujiang_Open()
    QiXi_Choujiang_ResetUI()
    QiXi_ChouJiang_SetTabTips()
    QiXi_Choujiang_Date:SetProperty("Image" , g_QiXi_Choujiang_DataImg[g_QiXi_Choujiang_Curpage])
    
    for i = 1,table.getn(g_QiXi_Icon) do
        local GiftItemID	=	g_QiXi_awardinfo[g_QiXi_Choujiang_Curpage][i] 
        --Lua_TDU_Log("GiftItemID:"..GiftItemID)
		local theAction     =   DataPool:CreateBindActionItemForShow(GiftItemID, 1)
		if theAction:GetID() ~= 0 then
			g_QiXi_Icon[i]:SetActionItem(theAction:GetID());
			g_QiXi_Icon[i]:Show();
        end
        if g_QiXi_Choujiang_OpenDate[g_QiXi_Choujiang_Curpage] <= g_QiXi_Choujiang_servertime then
            g_QiXi_awardtext[i]:SetText(g_QiXi_Choujiang_round[g_QiXi_Choujiang_Curpage][i])
        else
            g_QiXi_awardtext[i]:SetText(g_QiXi_Choujiang_AwardTextStr[g_QiXi_Choujiang_Curpage][i])
        end 
    end
    local nstate = g_QiXi_Choujiang_status[g_QiXi_Choujiang_Curpage]
    --Lua_TDU_Log("nstate"..nstate)
    QiXi_Choujiang_TipsText:SetText( g_QiXi_Choujiang_XuYuanText[nstate][g_QiXi_Choujiang_Curpage] )
    
    for img = 1, table.getn(g_QiXi_Choujiang_BtnImg[nstate]) do
        QiXi_Choujiang_RewardButton : SetProperty(g_QiXi_Choujiang_BtnImg[nstate][img].key,g_QiXi_Choujiang_BtnImg[nstate][img].value)
    end

    if nstate == 0 then
        QiXi_Choujiang_RewardButton:SetToolTip(g_QiXi_Choujiang_XuYuantips[g_QiXi_Choujiang_Curpage]) 
        QiXi_Choujiang_RewardButton:Enable()
    elseif nstate == 1 then
        QiXi_Choujiang_RewardButton:SetToolTip(g_QiXi_Choujiang_ChouJiangtips[g_QiXi_Choujiang_Curpage]) 
        QiXi_Choujiang_RewardButton:Disable()
    elseif nstate == 2 then
        QiXi_Choujiang_RewardButton:SetToolTip(g_QiXi_Choujiang_ChouJiangtips[g_QiXi_Choujiang_Curpage]) 
        QiXi_Choujiang_RewardButton:Enable()
    elseif nstate == 3 then
        QiXi_Choujiang_RewardButton:SetToolTip(g_QiXi_Choujiang_ChouJiangtips[g_QiXi_Choujiang_Curpage])
        QiXi_Choujiang_RewardButton:Disable() 
    elseif nstate == 4 then 
        QiXi_Choujiang_RewardButton:SetToolTip(g_QiXi_Choujiang_ChouJiangtips[g_QiXi_Choujiang_Curpage]) 
        QiXi_Choujiang_RewardButton:Disable()
    end 
    if g_QiXi_TabRedTipsStatus[g_QiXi_Choujiang_Curpage] == 0 then
        QiXi_Choujiang_RewardButtonTips:Hide()
    else
        QiXi_Choujiang_RewardButtonTips:Show()
        g_QiXi_TabRedTipsctl[g_QiXi_Choujiang_Curpage]:Show()
    end
    QiXi_Choujiang_Text:SetText(ScriptGlobal_Format("#{QXJCJ_20220523_19}", g_QiXi_Choujiang_bingqishuliang))
    g_QiXi_tab[g_QiXi_Choujiang_Curpage]:SetCheck(1)
end

--=========
function QiXi_Choujiang_ResetUI()  
    for i = 1, table.getn(g_QiXi_Icon) do
        g_QiXi_Icon[i]:SetActionItem(-1)
        g_QiXi_awardtext[i]:SetText("")
        g_QiXi_tab[i]:SetCheck(0)
        g_QiXi_TabRedTipsctl[i]:Hide()
    end
end
 
function QiXi_Choujiang_Project_Clicked(tabid, par)
    g_QiXi_Choujiang_Curpage = tabid
    QiXi_Choujiang_Open()
end

function QiXi_Choujiang_ShowHelp()
    PushEvent("QUEST_HELP_MSG","#{QXJCJ_20220523_12}")
end

function QiXi_Choujiang_SetCurPage()    
    local curDay = DataPool:GetServerDayTime()
    --Lua_TDU_Log("curDay"..curDay)
    g_QiXi_Choujiang_Curpage = 3
    for i = 1, table.getn(g_QiXi_Choujiang_OpenDate) do 
        if curDay <= math.floor(g_QiXi_Choujiang_OpenDate[i]/100) then
            g_QiXi_Choujiang_Curpage = i 
            return
        end
    end
    if g_QiXi_Choujiang_Curpage > table.getn(g_QiXi_Choujiang_OpenDate) then
        g_QiXi_Choujiang_Curpage = table.getn(g_QiXi_Choujiang_OpenDate)
    end
end

function QiXi_ChouJiang_SetTabTips()
   for i = 1, table.getn(g_QiXi_TabRedTipsStatus) do
    if g_QiXi_TabRedTipsStatus[i] == 1 then
        g_QiXi_TabRedTipsctl[i]:Show()
    else
        g_QiXi_TabRedTipsctl[i]:Hide()        
    end
   end 
end