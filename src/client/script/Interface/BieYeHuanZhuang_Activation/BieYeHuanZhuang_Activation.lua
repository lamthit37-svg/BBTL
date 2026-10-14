--家园风格激活续期界面
local MAX_OBJ_DISTANCE = 3.0;
local g_BieYeHuanZhuang_Activation_Type = 0
local g_BieYeHuanZhuang_Activation_StyleId = 0
local g_BieYeHuanZhuang_Activation_Frame_UnifiedPosition;

local objCared = -1
--物品在背包中的位置
local	g_posItem	= -1	
--==================================
-- BieYeHuanZhuang_Activation_PreLoad
--==================================
function BieYeHuanZhuang_Activation_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_BIEYESTYLEITEM");
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("BUY_ITEM",false);
end

--==================================
-- BieYeHuanZhuang_Activation_OnLoad
--==================================
function BieYeHuanZhuang_Activation_OnLoad()
	
	g_BieYeHuanZhuang_Activation_Frame_UnifiedPosition=BieYeHuanZhuang_Activation_Frame:GetProperty("UnifiedPosition");
end

--==================================
-- BieYeHuanZhuang_Activation_OnEvent
--==================================
function BieYeHuanZhuang_Activation_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 201708262) then
		objCared = Get_XParam_INT(0)
		g_BieYeHuanZhuang_Activation_Type = Get_XParam_INT(1)
		g_BieYeHuanZhuang_Activation_StyleId = Get_XParam_INT(2)
		BieYeHuanZhuang_Activation_OnShown(g_BieYeHuanZhuang_Activation_Type, g_BieYeHuanZhuang_Activation_StyleId)
		if objCared ~= -1 then
			BeginCareObject_BieYeHuanZhuang_Activation(objCared)
		end
		OpenWindow("Packet")
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeHuanZhuang_Activation_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeHuanZhuang_Activation_Frame_On_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(not this:IsVisible() ) then
			return;
		end
		if(tonumber(arg0) ~= objCared) then
			Close_BieYeHuanZhuang_Activation()
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then			
			--取消关心
			Close_BieYeHuanZhuang_Activation()
		end
	end

	--更新放入物品
	if( event == "UPDATE_BIEYESTYLEITEM" ) then
		if(not this:IsVisible() ) then
			return
		end
		
		if g_posItem ~= -1 and g_posItem == tonumber(arg0) then
			BieYeHuanZhuang_Activation_ItemClear()
			return
		end
		
		if arg0 ~= nil then
			BieYeHuanZhuang_Activation_ItemClear()
			BieYeHuanZhuang_Activation_ItemUpdate( tonumber(arg0) )
		end
		return
	end
	
	--背包里的物品发生变化
	if( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		if( arg0 ~= nil and -1 == tonumber(arg0) ) then
			return
		end

		if( arg0 ~= nil and g_posItem == tonumber(arg0) ) then
				BieYeHuanZhuang_Activation_ItemClear()
				BieYeHuanZhuang_Activation_ItemUpdate( tonumber(arg0) )
		end
		return
	end
	
	if( event == "BUY_ITEM" and this:IsVisible() ) then
		local item = tonumber(arg1)
			if item > 0 then 
				local itemIdx = PlayerPackage:GetBagPosByItemIndex(item)
				if itemIdx >= 0 then
					if g_posItem ~= -1 and g_posItem == tonumber(arg0) then
						BieYeHuanZhuang_Activation_ItemClear()
						return
					end 
					BieYeHuanZhuang_Activation_ItemClear()
					BieYeHuanZhuang_Activation_ItemUpdate( itemIdx ) 
				end
			end
	end 
	
	
end

--==================================
-- BieYeHuanZhuang_Activation_OnShown
--==================================
function BieYeHuanZhuang_Activation_OnShown(nType, nStyleId)
	local str = {
	[1] = {nTitle = "#{JYHZ_170824_65}", nDescribe = "#{JYHZ_170824_63}", nDate = "#{JYHZ_170824_74}", nItem = "#{JYHZ_170824_23}", nButton = "#{JYHZ_170824_15}", nItem2 = "#{JYHZ_170824_26}"},
	[2] = {nTitle = "#{JYHZ_170824_66}", nDescribe = "#{JYHZ_170824_64}", nDate = "#{JYHZ_170824_76}", nItem = "#{JYHZ_170824_43}", nButton = "#{JYHZ_170824_45}", nItem2 = "#{JYHZ_170824_44}"},
	}
	
	local nId,nName,nDes,nIconPic,nIconPic2,nYardPic,nRoomPic,nYardComfort,nHouseComfort = BieYeUI:GetBieYeStyleInfo(nStyleId)
	
	BieYeHuanZhuang_Activation_Title:SetText(str[nType].nTitle)
	BieYeHuanZhuang_Activation_Info1:SetText(str[nType].nDescribe)
	BieYeHuanZhuang_Activation_Info2_text1:SetText(str[nType].nDate)
	BieYeHuanZhuang_Activation_Info3:SetText(str[nType].nItem)
	BieYeHuanZhuang_Activation_Info4:SetText(str[nType].nItem2)
	BieYeHuanZhuang_Activation_Info5_text:SetText(ScriptGlobal_Format("#{JYHZ_170824_71}",nName))
	BieYeHuanZhuang_Activation_Button:SetText(str[nType].nButton)
	
	local nDisplayItem = BieYeUI:GetBieYeStyle_DisplayItem(nStyleId)
	local theAction = DataPool:CreateActionItemForShow(nDisplayItem, 1)
	if theAction:GetID() ~= 0 then
		BieYeHuanZhuang_Activation_Object1:SetActionItem(theAction:GetID());
	end
	
	BieYeHuanZhuang_Activation_ItemClear()

	this:Show();
end

--==================================
--关闭
--==================================
function Close_BieYeHuanZhuang_Activation()
	g_BieYeHuanZhuang_Activation_Type = 0
	g_BieYeHuanZhuang_Activation_StyleId = 0
	BieYeHuanZhuang_Activation_ItemClear()
	StopCareObject_BieYeHuanZhuang_Activation(objCared)
	this:Hide();	
end

--==================================
--确认
--==================================
function BieYeHuanZhuang_Activation_OK_Clicked()
	if(g_BieYeHuanZhuang_Activation_StyleId == 0 )then
		return
	end
	
	if g_posItem < 0 then
		PushDebugMessage("#{JYHZ_170824_24}")
		return 
	end
	
	if g_BieYeHuanZhuang_Activation_Type == 1 then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ActiveBieYeStyle");
			Set_XSCRIPT_ScriptID(892505);
			Set_XSCRIPT_Parameter(0, g_BieYeHuanZhuang_Activation_StyleId);
			Set_XSCRIPT_Parameter(1, g_posItem);
			Set_XSCRIPT_Parameter(2, 1);
			Set_XSCRIPT_Parameter(3, objCared); 
			Set_XSCRIPT_ParamCount(4);
		Send_XSCRIPT();
	elseif g_BieYeHuanZhuang_Activation_Type == 2 then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ExtendBieYeStyle");
			Set_XSCRIPT_ScriptID(892505);
			Set_XSCRIPT_Parameter(0, g_BieYeHuanZhuang_Activation_StyleId);
			Set_XSCRIPT_Parameter(1, g_posItem);
			Set_XSCRIPT_Parameter(2, 1);
			Set_XSCRIPT_Parameter(3, objCared); 
			Set_XSCRIPT_ParamCount(4);
		Send_XSCRIPT();
	end
	if g_posItem >= 0 then
		Close_BieYeHuanZhuang_Activation() 
	end
end

function BieYeHuanZhuang_Activation_Frame_On_ResetPos()
  BieYeHuanZhuang_Activation_Frame:SetProperty("UnifiedPosition", g_BieYeHuanZhuang_Activation_Frame_UnifiedPosition);
end

--==================================
--计算显示时间
--==================================
function BieYeHuanZhuang_Activation_ComputeLimitTime(IsHave, nCanUseTime, nExpiryDate, nTime)
	local str = ""
	-- 永久 
	if nTime < 1 then 
		str = "#{JYHZ_170824_14}"
		return str
	end
	if nCanUseTime < 1 and nExpiryDate < 1 then 
		str = "#{JYHZ_170824_14}"
		return str
	end
	
	-- 未激活 显示有效期 x天
	if IsHave < 1 and nCanUseTime > 0 then 
		str = ScriptGlobal_Format("#{JYHZ_170824_12}", math.floor(nCanUseTime/24) )
		return str
	end
	
	-- 未激活 显示截至日期
	if IsHave < 1 and nCanUseTime < 1 then
		nTime = (nExpiryDate - 20000000) * 100 + 24
	end

	-- 计算日期
	local nYear = math.floor(nTime/1000000) + 2000
	local nMonth =  math.mod(math.floor(nTime/10000), 100)
	local nDay = math.mod(math.floor(nTime/100), 100)
	local nHour = math.mod(nTime, 100)
	str = ScriptGlobal_Format("#{JYHZ_170824_13}", nYear.."年"..nMonth.."月"..nDay.."日"..nHour.."时")
	
	return str
end

--==================================
--计算显示时间(续期用）
--==================================
function BieYeHuanZhuang_Activation_ComputeLimitTime_Extend( IsHave, nCanUseTime, nExpiryDate, nTime )
	local str = ""
	-- 永久 
	if nTime < 1 then
		str = ScriptGlobal_Format( "#{JYHZ_170824_72}", "#{JYHZ_170824_50}" )
		return str
	end
	if nCanUseTime < 1 and nExpiryDate < 1 then 
		str = ScriptGlobal_Format( "#{JYHZ_170824_72}", "#{JYHZ_170824_50}" )
		return str
	end
	
	-- 未激活 显示有效期 x天
	if IsHave < 1 and nCanUseTime > 0 then 
		str = ScriptGlobal_Format("#{JYHZ_170824_73}", math.floor(nCanUseTime/24) )
		return str
	end
	
	-- 未激活 显示截至日期
	if IsHave < 1 and nCanUseTime < 1 then
		nTime = (nExpiryDate - 20000000) * 100 + 24
	end

	-- 计算日期
	local nYear = math.floor(nTime/1000000) + 2000
	local nMonth =  math.mod(math.floor(nTime/10000), 100)
	local nDay = math.mod(math.floor(nTime/100), 100)
	local nHour = math.mod(nTime, 100)
	str = ScriptGlobal_Format("#{JYHZ_170824_72}", nYear.."年"..nMonth.."月"..nDay.."日"..nHour.."时")
	
	return str
end

--==================================
--清理物品
--==================================
function BieYeHuanZhuang_Activation_ItemClear()
	BieYeHuanZhuang_Activation_Object2 : SetActionItem( -1 );
	LifeAbility : Lock_Packet_Item( g_posItem, 0 )
	g_posItem	= -1
	
	local nstrDate = ""
	if g_BieYeHuanZhuang_Activation_Type == 2 and g_BieYeHuanZhuang_Activation_StyleId > 0 then
		local nTime = BieYeUI:GetBieYeStyleTime(g_BieYeHuanZhuang_Activation_StyleId)
		nstrDate = BieYeHuanZhuang_Activation_ComputeLimitTime(1, 1, 1, nTime)
	end
	BieYeHuanZhuang_Activation_Info2_text2:SetText("")
end

--==================================
--刷新物品
--==================================
function BieYeHuanZhuang_Activation_ItemUpdate(pos_taskitem)
	local	pos	= tonumber( pos_taskitem )
	local	theAction	= EnumAction( pos, "packageitem" )
	
	if theAction:GetID() ~= 0 then
		local ItemId = PlayerPackage : GetItemTableIndex( pos ) 
		local ret, nCanUseTime, nExpiryDate = BieYeUI:GetBieYeStyleItemTime(g_BieYeHuanZhuang_Activation_StyleId, ItemId)
		
		if ret < 1 then 
			PushDebugMessage("#{JYHZ_170824_24}")
			return 
		end
		
		local ItemName = PlayerPackage:GetItemName(ItemId)
		if PlayerPackage : IsLock( pos ) == 1 then
			PushDebugMessage( ScriptGlobal_Format("#{JYHZ_170824_25}", ItemName) )
			return
		end
		
		BieYeHuanZhuang_Activation_Object2 : SetActionItem( theAction:GetID() )
		if g_posItem ~= -1 then
			LifeAbility : Lock_Packet_Item( g_posItem, 0 )
		end

		--在背包中锁住这个物品
		g_posItem	= pos
		LifeAbility : Lock_Packet_Item( g_posItem, 1 )
		
		-- 显示日期
		local nTimeStr = "" 
		if g_BieYeHuanZhuang_Activation_Type == 1 then
			nTimeStr = BieYeHuanZhuang_Activation_ComputeLimitTime(0, nCanUseTime, nExpiryDate, 1)
		elseif g_BieYeHuanZhuang_Activation_Type == 2 then
			nTimeStr = BieYeHuanZhuang_Activation_ComputeLimitTime_Extend( 0, nCanUseTime, nExpiryDate, 1 )
		end
		BieYeHuanZhuang_Activation_Info2_text2:SetText(nTimeStr)
	else
		BieYeHuanZhuang_Activation_ItemClear()
	end
end

--==================================
--开始关心NPC
--==================================
function BeginCareObject_BieYeHuanZhuang_Activation(objCaredId)
	objCared = objCaredId;
	this:CareObject(objCared, 1, "BieYeHuanZhuang_Activation");
end

--==================================
--停止对某NPC的关心
--==================================
function StopCareObject_BieYeHuanZhuang_Activation(objCaredId)
	this:CareObject(objCaredId, 0, "BieYeHuanZhuang_Activation");
	objCared = -1;
end