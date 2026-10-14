local g_Frame_UnifiedXPosition_AnniversaryZhenYuan;
local g_Frame_UnifiedYPosition_AnniversaryZhenYuan;

local objid = -1;
local g_AnniversaryZhenYuan_objCared = -1;

local g_AnniversaryZhenYuan_Item = {}

local g_AnniversaryZhenYuan_CurChoose = -1
local g_AnniversaryZhenYuan_tianjian1 = 0
local g_AnniversaryZhenYuan_tianjian2 = 0
local g_AnniversaryZhenYuan_tianjian3 = 0
local g_AnniversaryZhenYuan_cost = 0
local g_AnniversaryZhenYuan_Have = 0
local g_AnniversaryZhenYuan_HaveGet = 0

local g_ZhenYuanLi_ID = {
39921709,	--	真元.橙冰符
39921710,	--	真元.橙火符
39921711,	--	真元.橙玄符
39921712,	--	真元.橙毒符
39921708,	--	真元.橙血符
39921713,	--	真元.橙体符
}

function AnniversaryZhenYuan_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	
end

function AnniversaryZhenYuan_OnLoad()
	g_Frame_UnifiedXPosition_AnniversaryZhenYuan	= AnniversaryZhenYuan_Frame_BK:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition_AnniversaryZhenYuan	= AnniversaryZhenYuan_Frame_BK:GetProperty("UnifiedYPosition");	
	
	g_AnniversaryZhenYuan_Item[1] = {AnniversaryZhenYuan_Icon1, AnniversaryZhenYuan_Icon1Mark, AnniversaryZhenYuan_Icon1Have}
	g_AnniversaryZhenYuan_Item[2] = {AnniversaryZhenYuan_Icon2, AnniversaryZhenYuan_Icon2Mark, AnniversaryZhenYuan_Icon2Have}
	g_AnniversaryZhenYuan_Item[3] = {AnniversaryZhenYuan_Icon3, AnniversaryZhenYuan_Icon3Mark, AnniversaryZhenYuan_Icon3Have}
	g_AnniversaryZhenYuan_Item[4] = {AnniversaryZhenYuan_Icon4, AnniversaryZhenYuan_Icon4Mark, AnniversaryZhenYuan_Icon4Have}
	g_AnniversaryZhenYuan_Item[5] = {AnniversaryZhenYuan_Icon5, AnniversaryZhenYuan_Icon5Mark, AnniversaryZhenYuan_Icon5Have}
	g_AnniversaryZhenYuan_Item[6] = {AnniversaryZhenYuan_Icon6, AnniversaryZhenYuan_Icon6Mark, AnniversaryZhenYuan_Icon6Have}
end

function AnniversaryZhenYuan_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 19042901) then
		local IsShow = Get_XParam_INT(0)
		if IsShow == 1 then
		
			if this:IsVisible() then
				return
			end

			--关心NPC
			g_AnniversaryZhenYuan_objCared = Get_XParam_INT(1)
			objCared = DataPool : GetNPCIDByServerID(g_AnniversaryZhenYuan_objCared)
			this:CareObject(objCared, 1, "AnniversaryZhenYuan");	

			g_AnniversaryZhenYuan_tianjian1 = Get_XParam_INT(2)
			g_AnniversaryZhenYuan_tianjian2 = Get_XParam_INT(3)
			g_AnniversaryZhenYuan_tianjian3 = Get_XParam_INT(4)	
			g_AnniversaryZhenYuan_cost = Get_XParam_INT(5)	
			g_AnniversaryZhenYuan_Have = Get_XParam_INT(6)	
			g_AnniversaryZhenYuan_HaveGet = Get_XParam_INT(7)					
		
			AnniversaryZhenYuan_OnShow( )
		else
			AnniversaryZhenYuan_OnHide()
		end
	
	elseif (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		AnniversaryZhenYuan_ResetPos()	
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		AnniversaryZhenYuan_Clear()
		
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			--取消关心
			this:CareObject(objCared, 0, "AnniversaryZhenYuan");
		end
	end
	
end

function AnniversaryZhenYuan_OnShow()
	--打开界面默认无选中
	g_AnniversaryZhenYuan_CurChoose = -1
	
	--打开界面把选中去掉
	for i=1, table.getn(g_AnniversaryZhenYuan_Item) do
		g_AnniversaryZhenYuan_Item[i][2]:Hide()
		g_AnniversaryZhenYuan_Item[i][3]:Hide()
	end
	
	--已兑换
	if g_AnniversaryZhenYuan_HaveGet >= 1 and g_AnniversaryZhenYuan_HaveGet <= 6 then
		if g_AnniversaryZhenYuan_Item[g_AnniversaryZhenYuan_HaveGet] ~= nil then
			g_AnniversaryZhenYuan_Item[g_AnniversaryZhenYuan_HaveGet][3]:Show()
		end
		AnniversaryZhenYuan_Btn:Disable();
		AnniversaryZhenYuan_Btn:SetText("#{RHZY_190429_38}")
	else
		AnniversaryZhenYuan_Btn:Enable();
		AnniversaryZhenYuan_Btn:SetText("#{RHZY_190429_37}")
	end
	
	local str = ""
	--在真意满江湖活动中兑换了3个橙色真元符。
	if g_AnniversaryZhenYuan_tianjian1 == 1 then
		AnniversaryZhenYuan_Text1Mark:Show()
		str = "#M".."#{RHZY_190429_14}"
	else
		AnniversaryZhenYuan_Text1Mark:Hide()	
		str = "#cff0000".."#{RHZY_190429_14}"
	end
	AnniversaryZhenYuan_Text1:SetText(str)	
	
	--使用画意灵犀兑换了1个橙元铸金符。
	if g_AnniversaryZhenYuan_tianjian2 == 1 then
		AnniversaryZhenYuan_Text2Mark:Show()
		str = "#M".."#{RHZY_190429_15}"
	else
		AnniversaryZhenYuan_Text2Mark:Hide()	
		str = "#cff0000".."#{RHZY_190429_15}"		
	end
	AnniversaryZhenYuan_Text2:SetText(str)	
	
	--使用画意灵犀兑换了2个橙元铸金符。
	if g_AnniversaryZhenYuan_tianjian3 == 1 then
		AnniversaryZhenYuan_Text3Mark:Show()
		str = "#M".."#{RHZY_190429_16}"
	else
		AnniversaryZhenYuan_Text3Mark:Hide()	
		str = "#cff0000".."#{RHZY_190429_16}"			
	end
	AnniversaryZhenYuan_Text3:SetText(str)	
	
	--所需真义值
	if g_AnniversaryZhenYuan_tianjian1 == 1 or g_AnniversaryZhenYuan_tianjian2 ==1 or g_AnniversaryZhenYuan_tianjian3 == 1 then
		AnniversaryZhenYuan_NeedNum1_2:Hide()
		AnniversaryZhenYuan_NeedNum1:Show()
		AnniversaryZhenYuan_NeedNum1Line:Show()
		AnniversaryZhenYuan_NeedNum2:Show()
		str = ScriptGlobal_Format("#{RHZY_190429_19}", g_AnniversaryZhenYuan_cost)
		AnniversaryZhenYuan_NeedNum2:SetText(str)
	else
		AnniversaryZhenYuan_NeedNum1_2:Show()
		AnniversaryZhenYuan_NeedNum1:Hide()
		AnniversaryZhenYuan_NeedNum1Line:Hide()
		AnniversaryZhenYuan_NeedNum2:Hide()
	end
	
	--tips
	str = ScriptGlobal_Format("#{RHZY_190429_22}", g_AnniversaryZhenYuan_cost)
	AnniversaryZhenYuan_Btn:SetToolTip(str)	
	
	--拥有真义值
	str = ScriptGlobal_Format("#{RHZY_190429_20}", g_AnniversaryZhenYuan_Have)
	AnniversaryZhenYuan_HaveNum:SetText(str)
	
	--真元展示
	DataPool:Lua_ClearZhenYuanLiActionItem();
	for i=1, 6 do
		DataPool:Lua_SetZhenYuanLiActionItem( i-1, g_ZhenYuanLi_ID[i] );
	end
	
	DataPool:Lua_UpdateZhenYuanLiActionItem();
	for i=1, 6 do
		local theAction = EnumAction( i-1, "ruihezhenyuanli");
		if theAction:GetID() ~= 0 then
			g_AnniversaryZhenYuan_Item[i][1]:SetActionItem( theAction:GetID() );
		else
			g_AnniversaryZhenYuan_Item[i][1]:SetActionItem( -1 );
		end
	end
	
	this:Show()
end

function AnniversaryZhenYuan_ResetPos()
	AnniversaryZhenYuan_Frame_BK:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition_AnniversaryZhenYuan);
	AnniversaryZhenYuan_Frame_BK:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition_AnniversaryZhenYuan);
end

function AnniversaryZhenYuan_OnHide()
	AnniversaryZhenYuan_Clear()
end

function AnniversaryZhenYuan_Clear()
	--取消关心
	this:CareObject(objCared, 0, "AnniversaryZhenYuan");	
	g_AnniversaryZhenYuan_CurChoose = -1
	this:Hide()
end

function AnniversaryZhenYuan_OnClickItem(idx)
	if idx < 1 or idx > 6 then
		return
	end
	
	if g_AnniversaryZhenYuan_CurChoose ~= -1 and g_AnniversaryZhenYuan_Item[g_AnniversaryZhenYuan_CurChoose] ~= nil then
		g_AnniversaryZhenYuan_Item[g_AnniversaryZhenYuan_CurChoose][2]:Hide()		
	end
	
	if g_AnniversaryZhenYuan_HaveGet >= 1 and g_AnniversaryZhenYuan_HaveGet <= 6 then	
		g_AnniversaryZhenYuan_CurChoose = -1
		return
	end
	
	g_AnniversaryZhenYuan_CurChoose = idx
	
	if g_AnniversaryZhenYuan_Item[idx] ~= nil then
		g_AnniversaryZhenYuan_Item[idx][2]:Show()
	end
end

function AnniversaryZhenYuan_OnClickExchange()
	if g_AnniversaryZhenYuan_CurChoose < 1 or g_AnniversaryZhenYuan_CurChoose > 6 then
		PushDebugMessage( "#{RHZY_190429_28}" )
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnExchangeZhenYuan" )
		Set_XSCRIPT_ScriptID(889907)
		Set_XSCRIPT_Parameter(0, g_AnniversaryZhenYuan_objCared) 
		Set_XSCRIPT_Parameter(1, g_AnniversaryZhenYuan_CurChoose) 
		Set_XSCRIPT_Parameter(2, 1) 
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end
