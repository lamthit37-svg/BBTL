local g_JiangHuShiJi_Popup_UnifiedPosition  
local g_JiangHuShiJi_Popup_checkBox_icons = {}
local g_JiangHuShiJi_Popup_checkBox_text = {}
local g_JiangHuShiJi_Popup_nSelectIndex = 0;
local g_JiangHuShiJi_Popup_red = 0;
local g_JiangHuShiJi_Popup_GiftMD = 0;
--=========
-- PreLoad()
--=========
function JiangHuShiJi_Popup_PreLoad() 
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("OPENJIANGSHUJISHI_POPUP",true) 
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
end

--=========
-- OnLoad()
--=========
function JiangHuShiJi_Popup_OnLoad() 
	g_JiangHuShiJi_Popup_UnifiedPosition = JiangHuShiJi_PopupFrame:GetProperty("UnifiedPosition")
	JiangHuShiJi_Popup_LoadControl()
end

--=========
-- Event
--=========
function JiangHuShiJi_Popup_OnEvent(event)

	if event == "OPENJIANGSHUJISHI_POPUP" then		
		g_JiangHuShiJi_Popup_nSelectIndex = tonumber(arg0) 	
		if this:IsVisible() then
			JiangHuShiJi_PopupOnHiden() 
        end     
		JiangHuShiJi_Popup_Open()
		this:Show()
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		JiangHuShiJi_PopupOnHiden()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		JiangHuShiJi_Popup_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		JiangHuShiJi_Popup_On_ResetPos()
		
    elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88892801) then
		g_JiangHuShiJi_Popup_red 		= Get_XParam_INT(0)     
		g_JiangHuShiJi_Popup_GiftMD  	= Get_XParam_INT(1)     
		if this:IsVisible() then
			JiangHuShiJi_Popup_Open() 
        end    
	end

end

function JiangHuShiJi_PopupOnHiden()   
	this:Hide()
end

--=========
-- 重置
--=========
function JiangHuShiJi_Popup_On_ResetPos()

	JiangHuShiJi_PopupFrame:SetProperty("UnifiedPosition", g_JiangHuShiJi_Popup_UnifiedPosition)

end

--=========
-- 装载控件
--=========
function JiangHuShiJi_Popup_LoadControl()  
	g_JiangHuShiJi_Popup_checkBox_icons[1] = JiangHuShiJi_Popup_Gift1_Icon
	g_JiangHuShiJi_Popup_checkBox_icons[2] = JiangHuShiJi_Popup_Gift2_Icon 

	g_JiangHuShiJi_Popup_checkBox_text[1] = JiangHuShiJi_Popup_Gift1_Tips
	g_JiangHuShiJi_Popup_checkBox_text[2] = JiangHuShiJi_Popup_Gift2_Tips 	
end

--=========
-- 打开
--=========
function JiangHuShiJi_Popup_Open() 
	
	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" then
		return
	end 
	if g_JiangHuShiJi_Popup_nSelectIndex == nil  then
		PushDebugMessage("empty")
		return
	end
	
	if infotbl[g_JiangHuShiJi_Popup_nSelectIndex] == nil then
		PushDebugMessage("empty")
		return
	end
	JiangHuShiJi_PopupDragTitle:SetText(infotbl[g_JiangHuShiJi_Popup_nSelectIndex].Title)
	JiangHuShiJi_PopupPopup_Text:SetText(infotbl[g_JiangHuShiJi_Popup_nSelectIndex].DetailDesc) 
	
	if 1 == DataPool:Lua_GetBinaryData(g_JiangHuShiJi_Popup_red, infotbl[g_JiangHuShiJi_Popup_nSelectIndex].FreeIDX) then
		JiangHuShiJi_Popup_Gift1_Icon_Mask:Show()  
	else  
		JiangHuShiJi_Popup_Gift1_Icon_Mask:Hide()	 
	end

	local id      = infotbl[g_JiangHuShiJi_Popup_nSelectIndex].FreeID 
	local num     = infotbl[g_JiangHuShiJi_Popup_nSelectIndex].FreeNum 
	local theAction = DataPool:CreateBindActionItemForShow(id, num)
	if theAction:GetID() ~= 0 then
		g_JiangHuShiJi_Popup_checkBox_icons[1]:SetActionItem(theAction:GetID());			
		g_JiangHuShiJi_Popup_checkBox_text[1]:SetText("#L"..theAction:GetName()) 
		g_JiangHuShiJi_Popup_checkBox_icons[1]:Show();
	else
		g_JiangHuShiJi_Popup_checkBox_icons[1]:SetActionItem(-1);
		g_JiangHuShiJi_Popup_checkBox_icons[1]:Hide()
	end
	 
	id        		= infotbl[g_JiangHuShiJi_Popup_nSelectIndex].YBID 
	num     = infotbl[g_JiangHuShiJi_Popup_nSelectIndex].YBItemNum 
	local  ybcount  = infotbl[g_JiangHuShiJi_Popup_nSelectIndex].YBCount 
	local  yblimnum = infotbl[g_JiangHuShiJi_Popup_nSelectIndex].YBLimitNum 
	local  ybmd  	= infotbl[g_JiangHuShiJi_Popup_nSelectIndex].YBMD 
	local  ybidx  	= infotbl[g_JiangHuShiJi_Popup_nSelectIndex].YBIDX 
	theAction = DataPool:CreateBindActionItemForShow(id, num)
	if theAction:GetID() ~= 0 then
		g_JiangHuShiJi_Popup_checkBox_icons[2]:SetActionItem(theAction:GetID());			
		g_JiangHuShiJi_Popup_checkBox_text[2]:SetText("#L"..theAction:GetName()) 
		g_JiangHuShiJi_Popup_checkBox_icons[2]:Show();
	else
		g_JiangHuShiJi_Popup_checkBox_icons[2]:SetActionItem(-1);
		g_JiangHuShiJi_Popup_checkBox_icons[2]:Hide()
	end

	local mdData  = g_JiangHuShiJi_Popup_GiftMD
	if ybidx >10 or ybidx < 0 then
		return
	end
	local buycount= math.floor(math.mod(mdData, math.pow(10,ybidx+1))/math.pow(10,ybidx))	
	if yblimnum > 1 then
		JiangHuShiJi_Popup_Gift2_Btn_Tips:SetText(ScriptGlobal_Format("#{TSFCL_220210_46}", yblimnum-buycount))  
	end 

	if yblimnum-buycount == 0 then
		JiangHuShiJi_Popup_Gift2_Icon_Mask:Show()
	else
		JiangHuShiJi_Popup_Gift2_Icon_Mask:Hide()
	end
	JiangHuShiJi_Popup_Gift1_Btn:SetText("#{TSFCL_220210_50}")
	JiangHuShiJi_Popup_Gift2_Btn:SetText(ScriptGlobal_Format("#{TSFCL_220210_51}", ybcount))
end  

function JiangHuShiJi_Popup_Buy() 
	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" or infotbl[g_JiangHuShiJi_Popup_nSelectIndex] == nil then
		return
	end 
	local curDay 	= tonumber(DataPool:GetServerDayTime()); 
	local opentime  = Lua_GetTeSeServerOpenTime(infotbl[g_JiangHuShiJi_Popup_nSelectIndex].FuncID) 
	if opentime > curDay then 
		PushDebugMessage("#{TSFCL_220210_32}")
		return
	end

	Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "BuyGift" ); 					-- 脚本函数名称
    Set_XSCRIPT_ScriptID( 888928 );											-- 脚本编号
    Set_XSCRIPT_Parameter( 0, infotbl[g_JiangHuShiJi_Popup_nSelectIndex].FuncID);	    
    Set_XSCRIPT_Parameter( 1, 0);	 
    Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数 
    Send_XSCRIPT() 
end

function JiangHuShiJi_Popup_LingQu()   
	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" or infotbl[g_JiangHuShiJi_Popup_nSelectIndex] == nil then
		return
	end 
	local curDay 	= tonumber(DataPool:GetServerDayTime()); 
	local opentime  = Lua_GetTeSeServerOpenTime(infotbl[g_JiangHuShiJi_Popup_nSelectIndex].FuncID) 
	if opentime > curDay then 
		PushDebugMessage("#{TSFCL_220210_32}")
		return
	end 
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "GetGift" ); 					-- 脚本函数名称
    Set_XSCRIPT_ScriptID( 888928 );											-- 脚本编号  
    Set_XSCRIPT_Parameter( 0, infotbl[g_JiangHuShiJi_Popup_nSelectIndex].FuncID);	 
    Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
    Send_XSCRIPT()	
end