
local MAX_OBJ_DISTANCE = 3.0
local g_CaredNpc = -1
local g_EquipAttributeTransfer_Item = -1  


local g_EquipAttributeTransfer_Frame_UnifiedPosition;
local g_EquipAttributeTransfer_binditem = 20700055
local g_EUAttrBefore_Textlist = {};
local g_EUAttrBefore_Check 		= {};
local g_EUAttrAfter_Textlist 	= {};
local g_EUAttrAfter_Check 		= {};
local g_EUAttr_Property 	= {-1,-1,-1}; 
 
local g_EquipAttributeTransfer_Confirm = -1; 
local g_ItemX = 20700055;
local g_ItemA = 20700057;
local g_ItemB = 20700059;
local g_ItemC = 20700061;

local g_ItemUnBindA = 20700056;
local g_ItemUnBindB = 20700058;
local g_ItemUnBindC = 20700060;

local g_BeforCheckIndex = -1;
local g_AfterCheckIndex = {-1,-1};
local g_AfterCkeckNum 	= 0;
local g_TotalCkeckNum 	= 2;
local g_TheSameProperty = -1;
local g_CurNeedItem = -1;
 
local g_ItemInfo = {
	[1] = {text="#{JTFK_1117_10}",BindItemID=38001521,UnBindItemID=38001522, num=1,IsSpecial= 0,Msg="#{JTFK_1117_29}", },	--无相石
	[2] = {text="#{JTFK_1117_11}",BindItemID=38001523,UnBindItemID=38001524, num=1,IsSpecial= 0,Msg="#{JTFK_1117_30}", },	--无相灵石
	[3] = {text="#{JTFK_1117_12}",BindItemID=38001521,UnBindItemID=38001522, num=1,IsSpecial= 1,Msg="#{JTFK_1117_30}", },	--无相石和无相灵石 
};
local g_ItemInfoSpecial = { 
	[1] = {text="#{JTFK_1117_12}",BindItemID=38001523,UnBindItemID=38001524, num=1,Msg="#{JTFK_1117_30}",},	--无相石和无相灵石 
};
---------------------------------------------------------------
--非要加个二次确认倒计时
local g_ProName = {}

--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function EquipAttributeTransfer_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("SHOUGONG_FUKE")			--拖动物品发包
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("EQUIP_ATTRFUKE_SENDMSG")			--二次确认发包
end

--=========================================================
-- 载入初始化
--=========================================================
function EquipAttributeTransfer_OnLoad()
	g_EquipAttributeTransfer_Item = -1 
	-- 始终可以点击 OK 按钮, 为了方便提示玩家信息
	EquipAttributeTransfer_OK:Enable()
	
	g_EquipAttributeTransfer_Frame_UnifiedPosition=EquipAttributeTransfer_Frame:GetProperty("UnifiedPosition");
	
	g_EUAttrBefore_Check[1] 	 = EquipAttributeTransfer_BeforeCheck1
	g_EUAttrBefore_Check[2] 	 = EquipAttributeTransfer_BeforeCheck2
	g_EUAttrBefore_Check[3] 	 = EquipAttributeTransfer_BeforeCheck3
	
	g_EUAttrBefore_Textlist[1] = EquipAttributeTransfer_BeforeText1
	g_EUAttrBefore_Textlist[2] = EquipAttributeTransfer_BeforeText2
	g_EUAttrBefore_Textlist[3] = EquipAttributeTransfer_BeforeText3
	
	g_EUAttrAfter_Check[1]		 = EquipAttributeTransfer_AfterCheck1
	g_EUAttrAfter_Check[2]		 = EquipAttributeTransfer_AfterCheck2
	g_EUAttrAfter_Check[3]		 = EquipAttributeTransfer_AfterCheck3
	
	g_EUAttrAfter_Textlist[1]  = EquipAttributeTransfer_AfterText1
	g_EUAttrAfter_Textlist[2]  = EquipAttributeTransfer_AfterText2
	g_EUAttrAfter_Textlist[3]  = EquipAttributeTransfer_AfterText3 
end

--=========================================================
-- 事件处理
--=========================================================
function EquipAttributeTransfer_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 20151119) then
		local xx = Get_XParam_INT(0)
		g_CaredNpc = DataPool:GetNPCIDByServerID(xx)
		if g_CaredNpc == -1 then
			PushDebugMessage("server传过来的数据有问题。")
			return
		end
		BeginCareObject_EquipAttributeTransfer()
		EquipAttributeTransfer_Clear() 
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20151123 and this:IsVisible() ) then
		local bagIndex = Get_XParam_INT(0) 
		EquipAttributeTransfer_Update(bagIndex)  
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if (tonumber(arg0) ~= g_CaredNpc) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE) or arg1=="destroy") then
			EquipAttributeTransfer_Close()
		end
	elseif (event == "SHOUGONG_FUKE") then
		local solt  =  tonumber(arg1);
		if(solt == 172) then
			EquipAttributeTransfer_Update(tonumber(arg0)) 
		end
	elseif (event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible()) then 
			EquipAttributeTransfer_Clear()  
	elseif (event == "ADJEST_UI_POS" ) then
		EquipAttributeTransfer_Frame_On_ResetPos() 
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipAttributeTransfer_Frame_On_ResetPos()
	elseif (event == "EQUIP_ATTRFUKE_SENDMSG") then	 
	  g_EquipAttributeTransfer_Confirm = 1 
	  EquipAttributeTransfer_OK_Clicked();
	end
end
  
--=========================================================
-- 重置界面
--=========================================================
function EquipAttributeTransfer_Clear() 
	if g_EquipAttributeTransfer_Item ~= -1 then
		EquipAttributeTransfer_ItemIcon:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(g_EquipAttributeTransfer_Item, 0)
		g_EquipAttributeTransfer_Item = -1
	end
  
	for i = 0, 2 do
		g_EUAttrBefore_Textlist[i+1]:SetText("");
		g_EUAttrBefore_Textlist[i+1]:Hide();
		g_EUAttrBefore_Check[i+1]:SetCheck(0);
		g_EUAttrBefore_Check[i+1]:SetProperty("Disabled", "True");
		g_EUAttrBefore_Check[i+1]: Hide();
		
		
		g_EUAttrAfter_Textlist[i+1]:SetText("");
		g_EUAttrAfter_Textlist[i+1]:Hide();
		g_EUAttrAfter_Check[i+1]:SetCheck(0);
		g_EUAttrAfter_Check[i+1]:SetProperty("Disabled", "True"); 
		g_EUAttrAfter_Check[i+1]: Hide();
		g_EUAttr_Property[i+1] = -1;
	end
	EquipAttributeTransfer_OK:SetProperty("Disabled", "True");
	EquipAttributeTransfer_Cost:SetText("")   
	g_EquipAttributeTransfer_Confirm = -1;
	g_AfterCkeckNum 	= 0;
	g_TheSameProperty = -1;
	g_BeforCheckIndex = -1;
	g_CurNeedItem 		= -1;
end

--=========================================================
-- 更新界面
--=========================================================
function EquipAttributeTransfer_Update(itemIndex)
	local index = tonumber(itemIndex)
	local theAction = EnumAction(index, "packageitem")

	if theAction:GetID() ~= 0 then
		-- 如果空格内已经有对应物品了, 替换之
		if g_EquipAttributeTransfer_Item ~= -1 then  --and index ~= g_EquipAttributeTransfer_Item  
			EquipAttributeTransfer_Clear()
		end
		
		if theAction:Lua_IsCanFuke(itemIndex) == 0 then
			return;
		end
		EquipAttributeTransfer_ItemIcon:SetActionItem(theAction:GetID())
		LifeAbility:Lock_Packet_Item(index, 1)
		g_EquipAttributeTransfer_Item = index
		EquipAttributeTransfer_OK:SetProperty("Disabled", "False");
		for i = 0, 2 do
			--g_EUAttr_list[i+1]:SetProperty("Disabled", "False");
			local pName,pLevel,pBValue,pPercent,pRValue = theAction:GetEquipAttaProperty(i); 
			local pproperty = theAction:GetEquipAttaPropertyOnly(i); 
			g_EUAttr_Property[i+1] = pproperty;
			local perStr = ScriptGlobal_Format("#{ZBSX_130625_127}", pLevel, pRValue,pBValue,pPercent) 
			local szStr = ""
			if(SystemSetup:IsClassic() == 1) then
				szStr = "#cfff263#{"..pName.."}"..perStr;
			else
				szStr = "#cfff264#{"..pName.."}"..perStr;
			end
			g_EUAttrBefore_Textlist[i+1]:SetText(szStr)
			g_EUAttrBefore_Textlist[i+1]:Show();
			g_EUAttrAfter_Textlist[i+1]:SetText(szStr)
			g_EUAttrBefore_Check[i+1]:SetProperty("Disabled", "False");
			g_EUAttrBefore_Check[i+1]: Show();
			g_EUAttrAfter_Check[i+1]:SetProperty("Disabled", "False"); 
			szStr = "#G#{"..pName.."}"..perStr;
			g_ProName[i+1] = szStr
		end 
		--记录相同属性
		GetTheSameProperty();
	else
		EquipAttributeTransfer_Clear()
	end
end
 

 
--=========================================================
-- 取出窗口内放入的物品
--=========================================================
function EquipAttributeTransfer_Resume_Equip()
	if this:IsVisible() then
		if g_EquipAttributeTransfer_Item ~= -1 then
			LifeAbility:Lock_Packet_Item(g_EquipAttributeTransfer_Item, 0)
			EquipAttributeTransfer_ItemIcon:SetActionItem(-1)
			g_EquipAttributeTransfer_Item = -1
		end
	end 
end



local EB_FREE_BIND 	= 0;		-- 无绑定限制
local EB_BINDED 		= 1;		-- 已经绑定
local EB_GETUP_BIND =2			-- 拾取绑定
local EB_EQUIP_BIND =3			-- 装备绑定
--=========================================================
-- 确定执行功能
--=========================================================
function EquipAttributeTransfer_OK_Clicked() 
  if g_BeforCheckIndex <= -1 or g_AfterCkeckNum <= 0 and g_CurNeedItem <= 0 then
  	PushDebugMessage("#{JTFK_1117_27}");
		return;
  end 
  if g_CurNeedItem >= 1 then 
  	--判断是否有足够的道具
  	if PlayerPackage:CountAvailableItemByIDTable(g_ItemInfo[g_CurNeedItem].UnBindItemID) + PlayerPackage:CountAvailableItemByIDTable(g_ItemInfo[g_CurNeedItem].BindItemID) < g_ItemInfo[g_CurNeedItem].num then
			PushDebugMessage(g_ItemInfo[g_CurNeedItem].Msg); 
			return;
		end
		--如果需要两个道具 则检查另一组道具
		if g_ItemInfo[g_CurNeedItem].IsSpecial == 1 then
			if PlayerPackage:CountAvailableItemByIDTable(g_ItemInfoSpecial[1].UnBindItemID) + PlayerPackage:CountAvailableItemByIDTable(g_ItemInfoSpecial[1].BindItemID) < g_ItemInfoSpecial[1].num then
				PushDebugMessage(g_ItemInfoSpecial[1].Msg); 
				return;
			end
		end 
  end 
 	local idx = 1; 
	for i = 1, 3 do  
		if g_EUAttrAfter_Check[i]:GetCheck() == 1 then  
			g_AfterCheckIndex[idx] = i-1;
			idx = idx + 1;  
		elseif i ~= g_BeforCheckIndex then 
			g_AfterCheckIndex[idx] = -1;
			idx = idx + 1;  
		end 
	end  
	if PlayerPackage:CountAvailableItemByIDTable(g_ItemInfo[g_CurNeedItem].BindItemID) > 0 or 
	   ( g_ItemInfo[g_CurNeedItem].IsSpecial == 1 and PlayerPackage:CountAvailableItemByIDTable(g_ItemInfoSpecial[1].BindItemID) > 0 ) then  --绑定的道具自己就够了
		if(PlayerPackage:GetItemBindStatusByIndex(g_EquipAttributeTransfer_Item) == 1 ) or PlayerPackage:IsChongLouItem(g_EquipAttributeTransfer_Item) == 1 then	--如果装备也是绑定的就不用提示了 
			if g_EquipAttributeTransfer_Confirm == 1 then
				Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("EquipAttaFuke");
				Set_XSCRIPT_ScriptID(890088);
				Set_XSCRIPT_Parameter(0,g_EquipAttributeTransfer_Item);
				Set_XSCRIPT_Parameter(1,g_BeforCheckIndex-1);
				Set_XSCRIPT_Parameter(2,g_AfterCkeckNum); 
				Set_XSCRIPT_Parameter(3,g_AfterCheckIndex[1]);
				Set_XSCRIPT_Parameter(4,g_AfterCheckIndex[2]); 
				Set_XSCRIPT_ParamCount(5); 
				Send_XSCRIPT();	  
			else
				PushEvent("EQUIP_ATTRFUKE_CONFIRM", 2, g_ProName[1], g_ProName[2], g_ProName[3])
			end
		elseif g_EquipAttributeTransfer_Confirm == 1 then
			Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("EquipAttaFuke");
			Set_XSCRIPT_ScriptID(890088);
			Set_XSCRIPT_Parameter(0,g_EquipAttributeTransfer_Item);
			Set_XSCRIPT_Parameter(1,g_BeforCheckIndex-1);
			Set_XSCRIPT_Parameter(2,g_AfterCkeckNum); 
			Set_XSCRIPT_Parameter(3,g_AfterCheckIndex[1]);
			Set_XSCRIPT_Parameter(4,g_AfterCheckIndex[2]); 
			Set_XSCRIPT_ParamCount(5); 
			Send_XSCRIPT();	 
		else
			--悲剧开始，弹出提示
			--不仅悲剧，还要加到计时和参数
			PushEvent("EQUIP_ATTRFUKE_CONFIRM", 1, g_ProName[1], g_ProName[2], g_ProName[3])
		end
	else			--全部是非绑定的材料直接用
		if g_EquipAttributeTransfer_Confirm == 1 then
			Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("EquipAttaFuke");
			Set_XSCRIPT_ScriptID(890088);
			Set_XSCRIPT_Parameter(0,g_EquipAttributeTransfer_Item);
			Set_XSCRIPT_Parameter(1,g_BeforCheckIndex-1);
			Set_XSCRIPT_Parameter(2,g_AfterCkeckNum); 
			Set_XSCRIPT_Parameter(3,g_AfterCheckIndex[1]);
			Set_XSCRIPT_Parameter(4,g_AfterCheckIndex[2]); 
			Set_XSCRIPT_ParamCount(5); 
			Send_XSCRIPT();	
		else
			PushEvent("EQUIP_ATTRFUKE_CONFIRM", 2, g_ProName[1], g_ProName[2], g_ProName[3])
		end  
	end
	  
end

--=========================================================
-- 关闭界面
--=========================================================
function EquipAttributeTransfer_Closed()
	StopCareObject_EquipAttributeTransfer()
	EquipAttributeTransfer_Clear()
	this:Hide()
	return
end

--=========================================================
-- 界面隐藏
--=========================================================
function EquipAttributeTransfer_OnHiden()
	StopCareObject_EquipAttributeTransfer()
	EquipAttributeTransfer_Clear()
	return
end

--=========================================================
-- 开始关心NPC，
-- 在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
-- 如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_EquipAttributeTransfer()

	this:CareObject(g_CaredNpc, 1, "EquipAttributeTransfer")
	return
end

--=========================================================
-- 停止对某NPC的关心
--=========================================================
function StopCareObject_EquipAttributeTransfer()
	this:CareObject(g_CaredNpc, 0, "EquipAttributeTransfer")
	g_CaredNpc = -1
	return
end
 

function EquipAttributeTransfer_Frame_On_ResetPos()
  EquipAttributeTransfer_Frame:SetProperty("UnifiedPosition", g_EquipAttributeTransfer_Frame_UnifiedPosition);
end

--=========================================================
--选中复制的精通属性类型
--========================================================= 
function EquipAttributeTransfer_Before_Clicked(num)  
	--先重置所有的check 因为互斥的
	for i = 1, 3 do   
		g_EUAttrBefore_Check[i]:SetCheck(0);
	end 
	g_EUAttrBefore_Check[num]:SetCheck(1);
	--设置选中项
	g_BeforCheckIndex = num;
	--选中之后才能显示替换的类型列表
	local beforePro = g_EUAttr_Property[num];
	local theAction = EnumAction(g_EquipAttributeTransfer_Item, "packageitem") 
	--重置一下界面及临时变量
	g_AfterCkeckNum	 = 0;
	g_CurNeedItem    = -1;
	EquipAttributeTransfer_Cost:SetText("");
	
	for j = 0, 2 do 
			local pName,pLevel,pBValue,pPercent,pRValue = theAction:GetEquipAttaProperty(j);  
			local perStr = ScriptGlobal_Format("#{ZBSX_130625_127}", pLevel, pRValue,pBValue,pPercent) 
			local szStr = ""
			if(SystemSetup:IsClassic() == 1) then
				szStr = "#cfff263#{"..pName.."}"..perStr;
			else
				szStr = "#cfff264#{"..pName.."}"..perStr;
			end
			g_EUAttrAfter_Textlist[j+1]:SetText(szStr)
			szStr = "#G#{"..pName.."}"..perStr;
			g_ProName[j+1] = szStr
	end 
	
	for i = 1, 3 do   
		if beforePro == g_EUAttr_Property[i] then
			g_EUAttrAfter_Check[i]:SetCheck(0);
			g_EUAttrAfter_Check[i]:SetProperty("Disabled", "True");  
		else
			g_EUAttrAfter_Check[i]:SetProperty("Disabled", "False"); 
			g_EUAttrAfter_Check[i]:SetCheck(0);
		end  
		g_EUAttrAfter_Check[i]: Show();
		g_EUAttrAfter_Textlist[i]:Show();
	end 
 
end
 
 
--========================================================= 
----选中替换的精通属性类型 
--========================================================= 
function EquipAttributeTransfer_After_Clicked(num) 
	 --判断一下 是否跟复制的属性类型一样 如果一样不可以选了 
	 local bBeforeStatus = g_EUAttrBefore_Check[num]:GetCheck();
	 if bBeforeStatus == 1 then
	 		PushDebugMessage("不应该可以set的 因为至灰了")
	 		return 
	 end
	 -- 如果已经勾选两个了 就不准再勾选了
	 local bAfterStatus = g_EUAttrAfter_Check[num]:GetCheck();
	 if bAfterStatus == 1 and g_AfterCkeckNum == g_TotalCkeckNum then
	 		PushDebugMessage("#{JTFK_1117_28}")
	 		g_EUAttrAfter_Check[num]:SetCheck(0);
	 		return;
	 end
	 local theAction = EnumAction(g_EquipAttributeTransfer_Item, "packageitem") 
	 --如果当前是选中状态  再点击 这改为不是选中状态
	 if bAfterStatus == 1 then 
	  	
	  	local nQual,nLevel = theAction:GetEquipAttaBaseValue(num-1);
			local pName,pLevel,pBValue,pPercent,pRValue = theAction:Lua_GetEquipAttaFuKeInfo(num-1,nQual, nLevel,g_BeforCheckIndex-1);  
			local perStr = ScriptGlobal_Format("#{ZBSX_130625_127}", pLevel, pRValue,pBValue,pPercent) 
			local szStr = ""
			if(SystemSetup:IsClassic() == 1) then
				szStr = "#cfff263#{"..pName.."}"..perStr;
			else
				szStr = "#cfff264#{"..pName.."}"..perStr;
			end 
			g_EUAttrAfter_Textlist[num]:SetText(szStr)
			szStr = "#G#{"..pName.."}"..perStr;
			g_ProName[num] = szStr
	 		g_AfterCkeckNum = g_AfterCkeckNum + 1;
	 		g_AfterCheckIndex[g_AfterCkeckNum] = num;
	 		CalcNeedItemType();
	 else 
	 
	 		local pName,pLevel,pBValue,pPercent,pRValue = theAction:GetEquipAttaProperty(num-1);  
			local perStr = ScriptGlobal_Format("#{ZBSX_130625_127}", pLevel, pRValue,pBValue,pPercent) 
			local szStr = ""
			if(SystemSetup:IsClassic() == 1) then
				szStr = "#cfff263#{"..pName.."}"..perStr;
			else
				szStr = "#cfff264#{"..pName.."}"..perStr;
			end
			g_EUAttrAfter_Textlist[num]:SetText(szStr)
			szStr = "#G#{"..pName.."}"..perStr;
			g_ProName[num] = szStr
	 		g_AfterCkeckNum = g_AfterCkeckNum -1;
	 		CalcNeedItemType();
	 end  
	 
end

--========================================================= 
----选中替换的精通属性类型 
--========================================================= 
function GetTheSameProperty() 
	 for i = 1, 3 do   
		 local iProperty = g_EUAttr_Property[i];
		 for j = 1, 3 do
		 	local jProperty = g_EUAttr_Property[j];
		 	if i ~= j and iProperty == jProperty then
		 		g_TheSameProperty = iProperty;
		 	end
		 end
	end   
end
 
--========================================================= 
----选中替换的精通属性类型 
--========================================================= 
function CalcNeedItemType() 
	--先判断所需要复刻的装备是否有三种不同属性 这里重新计算一下
	GetTheSameProperty();
	 
	--如果有三种不同属性
	if g_TheSameProperty == -1 then 
		if g_AfterCkeckNum == 0 then		-- 置空
			EquipAttributeTransfer_Cost:SetText("");
			g_CurNeedItem = -1;
			return;
		end
		if g_AfterCkeckNum == 1 then		-- 1个无相石
			EquipAttributeTransfer_Cost:SetText("#{JTFK_1117_09}".."#{JTFK_1117_10}");
			g_CurNeedItem = 1;
		end
		if g_AfterCkeckNum == 2 then	  -- 1个无相灵石-- 1个无相石
			EquipAttributeTransfer_Cost:SetText("#{JTFK_1117_09}".."#{JTFK_1117_12}");
			g_CurNeedItem = 3;
		end
	end
	--如果有两种相同属性
	if g_TheSameProperty > -1 then 
		if g_AfterCkeckNum == 0 then		-- 置空
			EquipAttributeTransfer_Cost:SetText("");
			g_CurNeedItem = -1;
			return;
		end  
		--选中两条相同的精通属性 将另外一条精通属性刻成三个一样的  需要一个无相灵石
		if g_EUAttr_Property[g_BeforCheckIndex] == g_TheSameProperty then 
			EquipAttributeTransfer_Cost:SetText("#{JTFK_1117_09}".."#{JTFK_1117_11}");
			g_CurNeedItem = 2;
		end
		--选择不同于其他两条精通属性的类型  
		if g_EUAttr_Property[g_BeforCheckIndex] ~= g_TheSameProperty then
			--将另外一条精通属性类型复刻成为所选中类型时  
			if g_AfterCkeckNum == 1 then		-- 1个无相石
				EquipAttributeTransfer_Cost:SetText("#{JTFK_1117_09}".."#{JTFK_1117_10}");
				g_CurNeedItem = 1;
			end
			if g_AfterCkeckNum == 2 then	  -- 1个无相灵石 1个无相石
				EquipAttributeTransfer_Cost:SetText("#{JTFK_1117_09}".."#{JTFK_1117_12}");
				g_CurNeedItem = 3;
			end	 
		end 
	end
	
	
end 
 
 
