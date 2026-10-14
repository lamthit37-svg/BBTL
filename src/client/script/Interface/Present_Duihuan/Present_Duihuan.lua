-- 典藏坐骑礼盒
-- 界面的默认位置

local g_Present_Duihuan_Frame_UnifiedPosition

local g_bagId = -1;
local g_itemtype = 0;

g_ItemID1 = 38001063 --橙
g_ItemID2 = 38001064 --紫

g_loaditemicon = 0;


g_PneumaItemID=
{
416001, --	真元·沉冰（紫）
417001, --	真元·炽火（紫）
418001, --	真元·印玄（紫）
419001, --	真元·蛊毒（紫）
516001, --	真元·沉冰（橙）
517001, --	真元·炽火（橙）
518001, --	真元·印玄（橙）
519001, --	真元·蛊毒（橙）
}

function Present_Duihuan_PreLoad()

	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Present_Duihuan_OnLoad()
	-- 保存界面的默认相对位置
	g_Present_Duihuan_Frame_UnifiedPosition=Present_Duihuan_Frame:GetProperty("UnifiedPosition");
	--初始化
	Present_Duihuan_InitUIData();
end

--初始化控件数据
function Present_Duihuan_InitUIData()

end


function Present_Duihuan_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Present_Duihuan_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Present_Duihuan_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "Present_Duihuan") then
			Present_Duihuan_OnHiden()
		end
	elseif(event == "UI_COMMAND") then
	  if tonumber(arg0) == 891003 then
	  	local type = Get_XParam_INT(0);
	
			if type == 1 then
				--关闭窗口
				Present_Duihuan_OnHiden()
				return
			end
			
			if type == 2 then
				--显示确认框
				local selpos = Get_XParam_INT(2)
				local itemindex = Get_XParam_INT(3)
				local pos = 0
				if itemindex == g_ItemID1 then
					pos = 4
				end
				PushEvent("MESSSAGEBOX_PNEUMABOX_SURE",Get_XParam_INT(1),selpos,g_PneumaItemID[pos+selpos],itemindex)
				return
			end
	  	Present_Duihuan_OnShown()
		end
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		Present_Duihuan_OnHiden()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Present_Duihuan_ResetPos()
	Present_Duihuan_Frame:SetProperty("UnifiedPosition", g_Present_Duihuan_Frame_UnifiedPosition)
end


function Present_Duihuan_OnShown()

	if g_bagId >=0 then
		LifeAbility : Lock_Packet_Item(g_bagId,0);
	end

	g_bagId = Get_XParam_INT(1);
		
	if g_loaditemicon == 0 then
		g_loaditemicon = 1
		local index = 0
		for index=1,8 do
			DataPool:Lua_Haoqing_Prize_SetItem(11+index-1,g_PneumaItemID[index])
		end
	end

	local itemtype = Get_XParam_INT(2);
	if g_itemtype ~= itemtype then
		g_itemtype = itemtype
		local pos = 0
		if g_itemtype == g_ItemID2 then
			Present_Duihuan_Title:SetText("#{XFXF_140919_104}")
			Present_Duihuan_Info:SetText("#{XFXF_140919_105}")
		else
			Present_Duihuan_Title:SetText("#{XFXF_140919_93}")
			Present_Duihuan_Info:SetText("#{XFXF_140919_94}")
			pos = 4
		end
		
		
		local index = 0
		for index=1,8 do
			DataPool:Lua_Haoqing_Prize_SetItem(11+index-1,g_PneumaItemID[index])
		end
		
		
		local theAction = EnumAction(11+pos, "haoqingprize");
		if theAction:GetID() ~= 0 then
			Present_Duihuan_Icon1:SetActionItem(theAction:GetID());
		end
		local theAction = EnumAction(12+pos, "haoqingprize");
		if theAction:GetID() ~= 0 then
			Present_Duihuan_Icon2:SetActionItem(theAction:GetID());
		end
		local theAction = EnumAction(13+pos, "haoqingprize");
		if theAction:GetID() ~= 0 then
			Present_Duihuan_Icon3:SetActionItem(theAction:GetID());
		end
		local theAction = EnumAction(14+pos, "haoqingprize");
		if theAction:GetID() ~= 0 then
			Present_Duihuan_Icon4:SetActionItem(theAction:GetID());
		end
	end
	
	LifeAbility : Lock_Packet_Item(g_bagId,1);
	this:Show();
end

function Present_Duihuan_Buttons_Clicked(index)

	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	-- 安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{MDJH_130507_14}")
		return
	end
	-- 物品加锁与否，服务器判断
	-- 判断角色背包道具栏剩余空间是否大于等于1，服务器判断
	--PushEvent("MESSSAGEBOX2_SURE",index,g_bagId,g_ItemID[index])

--	this:Hide();

		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SelectPneumaOK");
			Set_XSCRIPT_ScriptID(891003);
			Set_XSCRIPT_Parameter(0, g_bagId);--背包位置
			Set_XSCRIPT_Parameter(1, index);--索引1-4
			Set_XSCRIPT_Parameter(2, 0);--索引1-4
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
end

function Present_Duihuan_OnHiden()
	LifeAbility : Lock_Packet_Item(g_bagId,0)
	g_bagId = -1
	this:Hide();
end
