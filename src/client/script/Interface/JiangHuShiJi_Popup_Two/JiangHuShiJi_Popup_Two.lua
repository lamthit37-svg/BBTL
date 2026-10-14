local g_JiangHuShiJi_Popup_Two_UnifiedPosition  
local g_JiangHuShiJi_Popup_Two_checkBox_icons = {}
local g_JiangHuShiJi_Popup_Two_checkBox_text = {}
local g_JiangHuShiJi_Popup_Two_checkBox_Tips = {}
local g_JiangHuShiJi_Popup_Two_checkBox_Tips2 = {}
local g_JiangHuShiJi_Popup_Two_checkBox_mask = {}
local g_JiangHuShiJi_Popup_Two_checkBox_Btn = {}
local g_JiangHuShiJi_Popup_Two_nSelectIndex = 0;
local g_JiangHuShiJi_Popup_Two_red = 0;
local g_JiangHuShiJi_Popup_Two_GiftMD = 0;

--=========
-- PreLoad()
--=========
function JiangHuShiJi_Popup_Two_PreLoad() 
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("OPENJIANGSHUJISHI_POPUP_TWO",true) 
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
end

--=========
-- OnLoad()
--=========
function JiangHuShiJi_Popup_Two_OnLoad() 
	g_JiangHuShiJi_Popup_Two_UnifiedPosition = JiangHuShiJi_Popup_Two_Frame:GetProperty("UnifiedPosition")
	JiangHuShiJi_Popup_Two_LoadControl()
end

--=========
-- Event
--=========
function JiangHuShiJi_Popup_Two_OnEvent(event)

	if event == "OPENJIANGSHUJISHI_POPUP_TWO" then		
		g_JiangHuShiJi_Popup_Two_nSelectIndex = tonumber(arg0) 	
		if this:IsVisible() then
			JiangHuShiJi_Popup_Two_OnHiden() 
        end     
		JiangHuShiJi_Popup_Two_Open()
		this:Show()
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		JiangHuShiJi_Popup_Two_OnHiden()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		JiangHuShiJi_Popup_Two_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		JiangHuShiJi_Popup_Two_On_ResetPos()
		
    elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88892803) then
		g_JiangHuShiJi_Popup_Two_red 		= Get_XParam_INT(0)      
		if this:IsVisible() then
			JiangHuShiJi_Popup_Two_Open() 
        end    
	end

end

function JiangHuShiJi_Popup_Two_OnHiden()   
	this:Hide()
end

--=========
-- 重置
--=========
function JiangHuShiJi_Popup_Two_On_ResetPos()

	JiangHuShiJi_Popup_Two_Frame:SetProperty("UnifiedPosition", g_JiangHuShiJi_Popup_Two_UnifiedPosition)

end

--=========
-- 装载控件
--=========
function JiangHuShiJi_Popup_Two_LoadControl()  
	g_JiangHuShiJi_Popup_Two_checkBox_icons[1] = JiangHuShiJi_Popup_Two_Gift1_Icon
	g_JiangHuShiJi_Popup_Two_checkBox_icons[2] = JiangHuShiJi_Popup_Two_Gift2_Icon 
	g_JiangHuShiJi_Popup_Two_checkBox_icons[3] = JiangHuShiJi_Popup_Two_Gift3_Icon  

	g_JiangHuShiJi_Popup_Two_checkBox_text[1] = JiangHuShiJi_Popup_Two_Gift1_Tips
	g_JiangHuShiJi_Popup_Two_checkBox_text[2] = JiangHuShiJi_Popup_Two_Gift2_Tips 	
	g_JiangHuShiJi_Popup_Two_checkBox_text[3] = JiangHuShiJi_Popup_Two_Gift3_Tips 	 

	g_JiangHuShiJi_Popup_Two_checkBox_Tips[2] = JiangHuShiJi_Popup_Two_Gift2_Btn_Tips
	g_JiangHuShiJi_Popup_Two_checkBox_Tips[3] = JiangHuShiJi_Popup_Two_Gift3_Btn_Tips 

	g_JiangHuShiJi_Popup_Two_checkBox_Tips2[2] = JiangHuShiJi_Popup_Two_Gift2_Btn_Tips2
	g_JiangHuShiJi_Popup_Two_checkBox_Tips2[3] = JiangHuShiJi_Popup_Two_Gift3_Btn_Tips2 
	
	g_JiangHuShiJi_Popup_Two_checkBox_Btn[2] = JiangHuShiJi_Popup_Two_Gift2_Btn
	g_JiangHuShiJi_Popup_Two_checkBox_Btn[3] = JiangHuShiJi_Popup_Two_Gift3_Btn 
	
	g_JiangHuShiJi_Popup_Two_checkBox_mask[1] = JiangHuShiJi_Popup_Two_Gift1_Icon_Mask
	g_JiangHuShiJi_Popup_Two_checkBox_mask[2] = JiangHuShiJi_Popup_Two_Gift2_Icon_Mask 	
	g_JiangHuShiJi_Popup_Two_checkBox_mask[3] = JiangHuShiJi_Popup_Two_Gift3_Icon_Mask 	 
end

--=========
-- 打开
--=========
function JiangHuShiJi_Popup_Two_Open() 
	
	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" then
		return
	end 
	if g_JiangHuShiJi_Popup_Two_nSelectIndex == nil  then
		PushDebugMessage("empty")
		return
	end
	
	if infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex] == nil then
		PushDebugMessage("empty")
		return
	end
	JiangHuShiJi_Popup_Two_DragTitle:SetText(infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex].Title)
	JiangHuShiJi_Popup_TwoPopup_Text:SetText(infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex].DetailDesc) 
	 
	if 1 == DataPool:Lua_GetBinaryData(g_JiangHuShiJi_Popup_Two_red, infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex].FreeIDX) then
		JiangHuShiJi_Popup_Two_Gift1_Icon_Mask:Show()  
	else  
		JiangHuShiJi_Popup_Two_Gift1_Icon_Mask:Hide()	 
	end

	local id      = infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex].FreeID 
	local num     = infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex].FreeNum 
	local theAction = DataPool:CreateBindActionItemForShow(id, num)
	if theAction:GetID() ~= 0 then
		g_JiangHuShiJi_Popup_Two_checkBox_icons[1]:SetActionItem(theAction:GetID());			
		g_JiangHuShiJi_Popup_Two_checkBox_text[1]:SetText("#L"..theAction:GetName()) 
		g_JiangHuShiJi_Popup_Two_checkBox_icons[1]:Show();
	else
		g_JiangHuShiJi_Popup_Two_checkBox_icons[1]:SetActionItem(-1);
		g_JiangHuShiJi_Popup_Two_checkBox_icons[1]:Hide()
	end
	 
	local Costinfotbl = Lua_GetTeSeServerCostData(infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex].FuncID)
	if type(Costinfotbl) ~= "table" then 
		return
	end  

	for i = 2, 3 do
		local CostNum= Costinfotbl[i-1].CostNum
		local itemid = Costinfotbl[i-1].ItemID
		local itemnum= Costinfotbl[i-1].ItemNum
		local MDINDEX= Costinfotbl[i-1].MDINDEX
		local MDPos  = Costinfotbl[i-1].MDPos  
		local nMD = DataPool:GetPlayerMission_DataRound(MDINDEX) 
		if 1 == DataPool:Lua_GetBinaryData(nMD, MDPos) then
			g_JiangHuShiJi_Popup_Two_checkBox_mask[i]:Show()  
		else  
			g_JiangHuShiJi_Popup_Two_checkBox_mask[i]:Hide()	 
		end 
		local theAction = DataPool:CreateBindActionItemForShow(itemid, itemnum)
		if theAction:GetID() ~= 0 then
			g_JiangHuShiJi_Popup_Two_checkBox_icons[i]:SetActionItem(theAction:GetID());			
			g_JiangHuShiJi_Popup_Two_checkBox_text[i]:SetText("#L"..theAction:GetName()) 
			g_JiangHuShiJi_Popup_Two_checkBox_icons[i]:Show();
		else
			g_JiangHuShiJi_Popup_Two_checkBox_icons[i]:SetActionItem(-1);
			g_JiangHuShiJi_Popup_Two_checkBox_icons[i]:Hide()
		end
		local nCostCur = DataPool:GetPlayerMission_DataRound(727)
		if nCostCur >= CostNum then
			nCostCur = CostNum 		
			g_JiangHuShiJi_Popup_Two_checkBox_Tips[i]:SetText(ScriptGlobal_Format("#{TSFCL_230202_4}",nCostCur, CostNum))
		else 
			g_JiangHuShiJi_Popup_Two_checkBox_Tips[i]:SetText(ScriptGlobal_Format("#{TSFCL_230202_29}",nCostCur, CostNum))
		end
		local nExchCur = DataPool:GetPlayerMission_DataRound(726)
		if nExchCur >= CostNum then
			nExchCur = CostNum 			
			g_JiangHuShiJi_Popup_Two_checkBox_Tips2[i]:SetText(ScriptGlobal_Format("#{TSFCL_230202_31}",nExchCur, CostNum))
		else 
			g_JiangHuShiJi_Popup_Two_checkBox_Tips2[i]:SetText(ScriptGlobal_Format("#{TSFCL_230202_30}",nExchCur, CostNum))
		end
		if nCostCur >= CostNum and nExchCur >= CostNum then
			g_JiangHuShiJi_Popup_Two_checkBox_Btn[i]:SetText("#{TSFCL_220210_50}")
			g_JiangHuShiJi_Popup_Two_checkBox_Btn[i]:Enable() 			 
		else
			g_JiangHuShiJi_Popup_Two_checkBox_Btn[i]:SetText("#{TSFCL_230202_5}")
			g_JiangHuShiJi_Popup_Two_checkBox_Btn[i]:Disable()
		end
	end
end  

function JiangHuShiJi_Popup_Two_Buy(idx) 
	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" or infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex] == nil then
		return
	end 
	local curDay 	= tonumber(DataPool:GetServerDayTime()); 
	local opentime  = Lua_GetTeSeServerOpenTime(infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex].FuncID) 
	if opentime > curDay then 
		PushDebugMessage("#{TSFCL_220210_32}")
		return
	end

	Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "ExchGift" ); 					-- 脚本函数名称
    Set_XSCRIPT_ScriptID( 888928 );											-- 脚本编号
    Set_XSCRIPT_Parameter( 0, infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex].FuncID);	    
    Set_XSCRIPT_Parameter( 1, idx);	 
    Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数 
    Send_XSCRIPT() 
end

function JiangHuShiJi_Popup_Two_LingQu()   
	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" or infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex] == nil then
		return
	end 
	local curDay 	= tonumber(DataPool:GetServerDayTime()); 
	local opentime  = Lua_GetTeSeServerOpenTime(infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex].FuncID) 
	if opentime > curDay then 
		PushDebugMessage("#{TSFCL_220210_32}")
		return
	end 
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "GetGift" ); 					-- 脚本函数名称
    Set_XSCRIPT_ScriptID( 888928 );											-- 脚本编号  
    Set_XSCRIPT_Parameter( 0, infotbl[g_JiangHuShiJi_Popup_Two_nSelectIndex].FuncID);	 
    Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
    Send_XSCRIPT()	
end