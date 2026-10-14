local g_BieYeHuanZhuang_KJGM_Frame_UnifiedPosition;
local g_BieYeHuanZhuang_KJGM_Type;
local g_BieYeHuanZhuang_KJGM_Style;
local g_BieYeHuanZhuang_KJGM_Info =
{
	[1] = "#{ZYFG_171116_02}",
	[2] = "#{ZYFG_171116_03}",
}
local g_BieYeHuanZhuang_KJGM_Title =
{
	[1] = "#{ZYFG_171116_01}",
	[2] = "#{ZYFG_171116_13}",
}

local g_BieYeHuanZhuang_KJGM_Button =
{
	[1] = "#{JYHZ_170824_15}",
	[2] = "#{JYHZ_170824_45}",
}
local g_BieYeStyle30 			="30天"
local g_BieYeStyleForever	="永久"
local g_BieYeStyleIndex= {}					-- 拥有风格ID
local g_BieYeStyleTime = {}						-- 拥有风格ID对应有效期
local g_nMyBieYeStyle  = -1;
local	g_BieYeHuanZhuang_KJGM_ItemID30;
local	g_BieYeHuanZhuang_KJGM_Price30;
local	g_BieYeHuanZhuang_KJGM_ItemID_Forever;
local	g_BieYeHuanZhuang_KJGM_Price_Forever;
local g_BieYeHuanZhuang_KJGM_objCared =-1;
local MAX_OBJ_DISTANCE = 3.0
local g_BieYeHuanZhuang_KJGM_ItemType =-1;
--===============================================
-- PreLoad()
--===============================================
function BieYeHuanZhuang_KJGM_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD",false)		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
	this:RegisterEvent("BUY_ITEM",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)			-- 关心 NPC 的存在和范围
end

--===============================================
-- OnLoad()
--===============================================
function BieYeHuanZhuang_KJGM_OnLoad()
	g_BieYeHuanZhuang_KJGM_Frame_UnifiedPosition = BieYeHuanZhuang_KJGM_Frame:GetProperty("UnifiedPosition")
end

function BieYeHuanZhuang_KJGM_On_ResetPos()
	BieYeHuanZhuang_KJGM_Frame:SetProperty("UnifiedPosition", g_BieYeHuanZhuang_KJGM_Frame_UnifiedPosition)
end

--===============================================
-- OnEvent()
--===============================================
function BieYeHuanZhuang_KJGM_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 2017112001) then
		g_BieYeHuanZhuang_KJGM_Type = Get_XParam_INT(0);
		g_BieYeHuanZhuang_KJGM_Style= Get_XParam_INT(1);
		g_BieYeHuanZhuang_KJGM_ItemID30= Get_XParam_INT(2);
		g_BieYeHuanZhuang_KJGM_Price30= Get_XParam_INT(3);
		g_BieYeHuanZhuang_KJGM_ItemID_Forever= Get_XParam_INT(4);
		g_BieYeHuanZhuang_KJGM_Price_Forever= Get_XParam_INT(5);
		local serverNpcId = Get_XParam_INT(6);
		BieYeHuanZhuang_KJGM_Open()
		BieYeHuanZhuang_KJGM_SetObj(serverNpcId)
	elseif (event == "PLAYER_LEAVE_WORLD") then
		BieYeHuanZhuang_KJGM_Close()
	elseif (event == "ADJEST_UI_POS") then
		BieYeHuanZhuang_KJGM_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeHuanZhuang_KJGM_On_ResetPos()
	elseif (event == "BUY_ITEM") then
		local item = tonumber(arg1)
		local g_posItem =-1;
		if item > 0 then
			g_posItem = PlayerPackage:GetBagPosByItemIndex(item)
		end

		if g_BieYeHuanZhuang_KJGM_Type == 1 then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ActiveBieYeStyle");
			Set_XSCRIPT_ScriptID(892505);
			Set_XSCRIPT_Parameter(0, g_BieYeHuanZhuang_KJGM_Style);
			Set_XSCRIPT_Parameter(1, g_posItem);
			Set_XSCRIPT_Parameter(2, 1);
			Set_XSCRIPT_Parameter(3, g_BieYeHuanZhuang_KJGM_objCared);
			Set_XSCRIPT_ParamCount(4);
		Send_XSCRIPT();
		elseif g_BieYeHuanZhuang_KJGM_Type == 2 then
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("ExtendBieYeStyle");
				Set_XSCRIPT_ScriptID(892505);
				Set_XSCRIPT_Parameter(0, g_BieYeHuanZhuang_KJGM_Style);
				Set_XSCRIPT_Parameter(1, g_posItem);
				Set_XSCRIPT_Parameter(2, 1);
				Set_XSCRIPT_Parameter(3, g_BieYeHuanZhuang_KJGM_objCared);
				Set_XSCRIPT_ParamCount(4);
			Send_XSCRIPT();
		end
		BieYeHuanZhuang_KJGM_Close()
	elseif (event == "OBJECT_CARED_EVENT") then
		BieYeHuanZhuang_KJGM_CareObj(arg0,arg1,arg2)
	end
end

--===============================================
-- 打开界面
--===============================================
function BieYeHuanZhuang_KJGM_Open()
	if g_BieYeHuanZhuang_KJGM_Type == 1 or g_BieYeHuanZhuang_KJGM_Type == 2 then
		--目标风格
		local nId,nName,nDes,nIconPic,nIconPic2,nYardPic,nRoomPic,nYardComfort,nHouseComfort = BieYeUI:GetBieYeStyleInfo(g_BieYeHuanZhuang_KJGM_Style)
		BieYeHuanZhuang_KJGM_Info1:SetText( ScriptGlobal_Format(g_BieYeHuanZhuang_KJGM_Info[g_BieYeHuanZhuang_KJGM_Type], nName) )

		--底下这一堆  只是为了取一下 g_nMyBieYeStyle...
		g_nMyBieYeStyle, g_BieYeStyleIndex[1], g_BieYeStyleTime[1], g_BieYeStyleIndex[2], g_BieYeStyleTime[2], g_BieYeStyleIndex[3], g_BieYeStyleTime[3],
	 									 g_BieYeStyleIndex[4], g_BieYeStyleTime[4], g_BieYeStyleIndex[5], g_BieYeStyleTime[5], g_BieYeStyleIndex[6], g_BieYeStyleTime[6],
	  								 g_BieYeStyleIndex[7], g_BieYeStyleTime[7], g_BieYeStyleIndex[8], g_BieYeStyleTime[8], g_BieYeStyleIndex[9], g_BieYeStyleTime[9],
	   								 g_BieYeStyleIndex[10],g_BieYeStyleTime[10] = BieYeUI:GetBieYeStyleData()
	  -- 设置当前风格
	  --nId,nName,nDes,nIconPic,nIconPic2,nYardPic,nRoomPic,nYardComfort,nHouseComfort = BieYeUI:GetBieYeStyleInfo(g_nMyBieYeStyle)
	  BieYeHuanZhuang_KJGM_Info2_text:SetText( ScriptGlobal_Format("#{ZYFG_171116_04}", nName) )

	  --图标
	  local theAction = DataPool:CreateActionItemForShow(g_BieYeHuanZhuang_KJGM_ItemID30, 1)
		if theAction:GetID() ~= 0 then
			BieYeHuanZhuang_KJGM_Item1:SetActionItem(theAction:GetID())
		end
		
		theAction = DataPool:CreateActionItemForShow(g_BieYeHuanZhuang_KJGM_ItemID_Forever, 1)
		if theAction:GetID() ~= 0 then
			BieYeHuanZhuang_KJGM_Item2:SetActionItem(theAction:GetID())
		end
		
		BieYeHuanZhuang_KJGM_Title:SetText(g_BieYeHuanZhuang_KJGM_Title[g_BieYeHuanZhuang_KJGM_Type])
		BieYeHuanZhuang_KJGM_Button:SetText(g_BieYeHuanZhuang_KJGM_Button[g_BieYeHuanZhuang_KJGM_Type])
		--有效期 金钱
	  BieYeHuanZhuang_KJGM_Item1_info1:SetText(ScriptGlobal_Format("#{ZYFG_171116_05}", g_BieYeStyle30))
	  BieYeHuanZhuang_KJGM_Item1_info2:SetText(ScriptGlobal_Format("#{ZYFG_171116_06}", g_BieYeHuanZhuang_KJGM_Price30))
	  BieYeHuanZhuang_KJGM_Item2_info1:SetText(ScriptGlobal_Format("#{ZYFG_171116_05}", g_BieYeStyleForever))
	  BieYeHuanZhuang_KJGM_Item2_info2:SetText(ScriptGlobal_Format("#{ZYFG_171116_06}", g_BieYeHuanZhuang_KJGM_Price_Forever))
	  this:Show();
	else
		return
	end
end

--===============================================
-- 关闭界面
--===============================================
function BieYeHuanZhuang_KJGM_Close()
	this:CareObject(g_BieYeHuanZhuang_KJGM_objCared, 0,"BieYeHuanZhuang_KJGM");
	g_BieYeHuanZhuang_KJGM_ItemType = -1;
	this:Hide();
end

--===============================================
-- 购买30天
--===============================================
function BieYeHuanZhuang_KJGM_30()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyItem_30" )
		Set_XSCRIPT_ScriptID( 892505 )
		Set_XSCRIPT_Parameter(0,g_BieYeHuanZhuang_KJGM_Style)
		Set_XSCRIPT_Parameter(1,g_BieYeHuanZhuang_KJGM_Type)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--===============================================
-- 购买永久
--===============================================
function BieYeHuanZhuang_KJGM_Forever()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyItem_Forever" )
		Set_XSCRIPT_ScriptID( 892505 )
		Set_XSCRIPT_Parameter(0,g_BieYeHuanZhuang_KJGM_Style)
		Set_XSCRIPT_Parameter(1,g_BieYeHuanZhuang_KJGM_Type)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
--*************************************************
--关心NPC
--*************************************************
function BieYeHuanZhuang_KJGM_CareObj(careId, op, distance)
	if(nil == careId or nil == op or nil == distance) then
		return;
	end
	if(tonumber(careId) ~= g_BieYeHuanZhuang_KJGM_objCared) then
		return;
	end

	if(op == "distance" and tonumber(distance)>MAX_OBJ_DISTANCE or op=="destroy") then
		BieYeHuanZhuang_KJGM_Close()
	end
end


--*************************************************
--设置关心NPC
--*************************************************
function BieYeHuanZhuang_KJGM_SetObj( objCared )
	if (objCared == -1) then
		return
	end

	g_BieYeHuanZhuang_KJGM_objCared = objCared;
	this:CareObject(g_BieYeHuanZhuang_KJGM_objCared, 1,"BieYeHuanZhuang_KJGM");
end

function BieYeHuanZhuang_KJGM_SelectItemID( ItemType )
	if g_BieYeHuanZhuang_KJGM_ItemType == ItemType then		
		BieYeHuanZhuang_KJGM_Item1:SetPushed(0);
		BieYeHuanZhuang_KJGM_Item2:SetPushed(0);
		g_BieYeHuanZhuang_KJGM_ItemType = -1;
		return
	end
	g_BieYeHuanZhuang_KJGM_ItemType = ItemType
	if g_BieYeHuanZhuang_KJGM_ItemType == 1 then		
		BieYeHuanZhuang_KJGM_Item1:SetPushed(1);
		BieYeHuanZhuang_KJGM_Item2:SetPushed(0);
	end
	if g_BieYeHuanZhuang_KJGM_ItemType == 2 then		
		BieYeHuanZhuang_KJGM_Item1:SetPushed(0);
		BieYeHuanZhuang_KJGM_Item2:SetPushed(1);
	end
end

function BieYeHuanZhuang_KJGM_ClickOK()
	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end

	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	
	if g_BieYeHuanZhuang_KJGM_ItemType == 1 then
		BieYeHuanZhuang_KJGM_30()
	elseif g_BieYeHuanZhuang_KJGM_ItemType == 2 then
		BieYeHuanZhuang_KJGM_Forever()
	else
		PushDebugMessage("#{ZYFG_171116_15}")
		return
	end
end
