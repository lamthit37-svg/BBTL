
local g_LongwenDuiHuan_Frame_UnifiedPosition

local g_bagId = -1;
local g_itemtype = 0;
local m_YuLin_Item = -1

g_loaditemicon = 0;

local m_LongwenDuiHuan_YuLinStuff = {
	[1] = {item = 38002106, num = 1},	--绑定
	[2] = {item = 38002107, num = 1},	--不绑定
}

function LongwenDuiHuan_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("EXCHANGE_LW");
	this:RegisterEvent("EXCHANGE_LW_REMOVE");
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("CLOSE_WINDOW",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
end

function LongwenDuiHuan_OnLoad()
	-- 保存界面的默认相对位置
	g_LongwenDuiHuan_Frame_UnifiedPosition=LongwenDuiHuan_Frame:GetProperty("UnifiedPosition");
	--初始化
	LongwenDuiHuan_InitUIData();
end

--初始化控件数据
function LongwenDuiHuan_InitUIData()
	
end


function LongwenDuiHuan_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		LongwenDuiHuan_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		LongwenDuiHuan_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "LongwenDuiHuan") then
			LongwenDuiHuan_OnHiden()
		end
	elseif(event == "EXCHANGE_LW_REMOVE") and this:IsVisible() then
		LongwenDuiHuan_Update_Sub(-1)
	
	elseif(event == "PACKAGE_ITEM_CHANGED_EX") then	
		if arg0 ~= nil and tonumber(arg0) == m_YuLin_Item then
		--	LongwenDuiHuan_Item_Change(m_YuLin_Item)
		end
	elseif(event == "UI_COMMAND") then
		if tonumber(arg0) == 20171003 then	
			LongwenDuiHuan_BeginCareObj( Get_XParam_INT(0) );
			LongwenDuiHuan_OnShown()
			LongwenDuiHuan_UICheck()
		elseif tonumber(arg0) == 20171008 then
			local ZwbagIndex = PlayerPackage:GetValidZwForLevelUp(m_LongwenDuiHuan_YuLinStuff[1].item,1)
			if ZwbagIndex == -1 then
				ZwbagIndex =PlayerPackage:GetValidZwForLevelUp(m_LongwenDuiHuan_YuLinStuff[2].item,0)
			end
			if Get_XParam_INT(0) ~= -1 then
				ZwbagIndex = Get_XParam_INT(0)
			end

			if ZwbagIndex == -1 then
				LongwenDuiHuan_Object1:SetActionItem(-1);
				LifeAbility : Lock_Packet_Item(m_YuLin_Item,0);
				m_YuLin_Item = -1
			elseif ZwbagIndex >= 0 then
				if m_YuLin_Item ~= -1 then
					LifeAbility : Lock_Packet_Item(m_YuLin_Item,0);
				end
				local theAction = EnumAction(ZwbagIndex, "packageitem");
				LongwenDuiHuan_Object1:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(ZwbagIndex,1);
				m_YuLin_Item = ZwbagIndex
			end
			LongwenDuiHuan_UICheck()
		end
	elseif (event == "EXCHANGE_LW" and this:IsVisible() ) then

		if GetAuthorizedSafeFlag() == 0 and CheckPhoneMibaoAndMinorPassword() ~= 1 then --非授权安全模式下需要验证
			return
		end
		if arg1 ~= nil and tonumber(arg1) ~= -1 then
			LongwenDuiHuan_Update_Sub( tonumber(arg1) )	
		elseif 	arg0 ~= nil and tonumber(arg0) ~= -1 then
			LongwenDuiHuan_Update_Sub( tonumber(arg0) )
		end
		LongwenDuiHuan_UICheck()
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		LongwenDuiHuan_OnHiden()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function LongwenDuiHuan_ResetPos()
	LongwenDuiHuan_Frame:SetProperty("UnifiedPosition", g_LongwenDuiHuan_Frame_UnifiedPosition)
end

--Care Obj
function LongwenDuiHuan_BeginCareObj(obj_id)

	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

function LongwenDuiHuan_UICheck()
	if m_YuLin_Item == -1 then
		LongwenDuiHuan_OK:Disable()
	else
		LongwenDuiHuan_OK:Enable()
	end
end

function LongwenDuiHuan_OnShown()
	this:Show();	
end

function LongwenDuiHuan_Buttons_Clicked()

	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	-- 安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{MDJH_130507_14}")
		return
	end
	
	if m_YuLin_Item == -1 then
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ExchangeLongWen");
		Set_XSCRIPT_ScriptID(809273);
		Set_XSCRIPT_Parameter(0, m_YuLin_Item);--背包位置
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

function LongwenDuiHuan_Item_Change(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		local nFlag = 0
		local nItemIndex = PlayerPackage:GetItemTableIndex( itemIdx )
		for nindex=1, table.getn(m_LongwenDuiHuan_YuLinStuff) do
			if m_LongwenDuiHuan_YuLinStuff[nindex].item == nItemIndex then
				nFlag = 1
				break
			end
		end
		if nFlag == 0 then
			PushDebugMessage("#{LWDJ_170921_05}") -- 此处只能放入龙纹玉灵！
			return
		end

		if m_YuLin_Item ~= -1 then
			LifeAbility : Lock_Packet_Item(m_YuLin_Item,0);
		end

		LongwenDuiHuan_Object1:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_YuLin_Item = itemIdx

	else
		LongwenDuiHuan_Object1:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_YuLin_Item,0);
		m_YuLin_Item = -1;
	end
	LongwenDuiHuan_UICheck()
end

function LongwenDuiHuan_Update_Sub(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		local nFlag = 0
		local nItemIndex = PlayerPackage:GetItemTableIndex( itemIdx )
		for nindex=1, table.getn(m_LongwenDuiHuan_YuLinStuff) do
			if m_LongwenDuiHuan_YuLinStuff[nindex].item == nItemIndex then
				nFlag = 1
				break
			end
		end
		
		if nFlag == 0 then
			PushDebugMessage("#{LWDJ_170921_05}")	--此处只能放入龙纹玉灵！
			return
		end

		if PlayerPackage:IsLock( itemIdx ) == 1 then
			PushDebugMessage("#{LWDJ_170921_33}")	--该物品已上锁
			return
		end

		if m_YuLin_Item ~= -1 then
			LifeAbility : Lock_Packet_Item(m_YuLin_Item,0);
		end
		
		LongwenDuiHuan_Object1:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_YuLin_Item = itemIdx
	else
		LongwenDuiHuan_Object1:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_YuLin_Item,0);
		m_YuLin_Item = -1;
	end
	LongwenDuiHuan_UICheck()
end

function LongwenDuiHuan_Resume_stuff()
	LongwenDuiHuan_Update_Sub(-1)
end

function LongwenDuiHuan_OnHiden()
	if m_YuLin_Item ~= -1 then
		LongwenDuiHuan_Object1:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_YuLin_Item,0);
		m_YuLin_Item = -1;
	end
	this:Hide();
end
