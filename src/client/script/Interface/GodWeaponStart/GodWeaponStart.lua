local MISSION_BUTTONS_NUM =3;
local Pet_Index = -1;
local objCared = -1;
local MISSION_ITEM_BUTTONS = {};
local MISSION_ITEM_TEXT ={};
local MAX_OBJ_DISTANCE = 3.0;
local	Accept_Clicked_Num = 0;				-- 是否已按过一次“确定”
local	scriptId = -1;								-- “血浴神兵”任务时，调用该界面的脚本ID
local g_GodWeaponStart_Frame_UnifiedPosition;
--任务提交界面
local g_GodWeaponStart_Frame_AbsoluteSize
local g_GodWeaponStart_NeedItem1_AbsoluteSize
local g_GodWeaponStart_NeedItem1_Info_AbsoluteSize

local g_WeaponID = -1;
local g_WeaponIndex = -1;
local g_CurPage = -1; --0提交 1重铸

--界面调整及恢复，某些任务的界面需要在布局上动态做一些调整，比如“血浴神兵”有这个需求
local function ChangeUIForScript_500503(bChange)
end

--===============================================
-- OnLoad
--===============================================
function GodWeaponStart_Frame_PreLoad()

	this:RegisterEvent("REPLY_MISSION",true);						-- 提交任务界面
	this:RegisterEvent("UPDATE_WEAPONMISSION",false);						-- 提交任务界面	
	
	this:RegisterEvent("QUEST_AFTER_CONTINUE",false);			-- 点击“继续”之后，奖品选择界面
	this:RegisterEvent("UPDATE_REPLY_MISSION",false);			-- 刷新提交任务界面
	this:RegisterEvent("OBJECT_CARED_EVENT",false);				-- 某逻辑对象的某些发生改变


		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	
end

function GodWeaponStart_Frame_OnLoad()

	MISSION_ITEM_BUTTONS[1] = GodWeaponStart_NeedItem1;
	
	MISSION_ITEM_TEXT[1] = GodWeaponStart_NeedItem1_Info;

	g_GodWeaponStart_Frame_UnifiedPosition=GodWeaponStart_Frame:GetProperty("UnifiedPosition");

	g_GodWeaponStart_Frame_AbsoluteSize = GodWeaponStart_Frame:GetProperty("AbsoluteSize");
	g_GodWeaponStart_NeedItem1_AbsolutePosition = GodWeaponStart_NeedItem1:GetProperty("AbsolutePosition");
	g_GodWeaponStart_NeedItem1_Info_AbsolutePosition = GodWeaponStart_NeedItem1_Info:GetProperty("AbsolutePosition");
end

--===============================================
-- OnEvent
--===============================================
function GodWeaponStart_Frame_OnEvent(event)
	
	-- 提交任务界面
	if ( event == "REPLY_MISSION" ) then		
		-- “血浴神兵”任务时，得到调用该界面的 scriptId
		if (arg1~=nil) then
			scriptId = tonumber(arg1);
			if ( scriptId == 500503 ) or ( scriptId == 500504 ) then
			
				if (arg0~=nil) then
					objCared = tonumber(arg0);
					BeginCareObject_MissionReply(tonumber(arg0));
				end
		
				--“血浴神兵”
				g_CurPage = scriptId - 500503
				GodWeaponStart_Frame_Update();
				if scriptId == 500503 then
					Variable:SetVariable("XYWeaponType", '0', 1)
				elseif scriptId == 500504 then
					Variable:SetVariable("XYWeaponType", '1', 1)
				end
				
				this:Show();				
			end
		end
			
	-- 刷新提交任务界面
	elseif( event == "UPDATE_WEAPONMISSION"  and this:IsVisible())  then
		GodWeaponStart_Frame_Update();	
	elseif( event == "UPDATE_REPLY_MISSION"  and this:IsVisible())  then
		GodWeaponStart_Frame_Update();
	
	-- 点击“继续”之后，奖品选择界面
	elseif ( event == "QUEST_AFTER_CONTINUE" and this:IsVisible() ) then
		StopCareObject_MissionReply(objCared)
		this:Hide();

	-- 某逻辑对象的某些发生改变
	elseif (event == "OBJECT_CARED_EVENT"  and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			
			--取消关心
			StopCareObject_MissionReply(objCared);
		end
	
	end
		-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		GodWeaponStart_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED"  and this:IsVisible()) then
		GodWeaponStart_Frame_On_ResetPos()
	end
end

--===============================================
-- 更新显示界面数据
--===============================================
function GodWeaponStart_Frame_Update()
	
	if g_CurPage == 0 then
		GodWeaponStart_PageHeader_Name : SetText("#{XYSB_20170620_012}")
		GodWeaponStart_NeedItem_Text : SetText("#{XYSB_20170620_013}")
		GodWeaponStart_Desc : ClearAllElement();
		GodWeaponStart_Desc : AddTextElement("#{XYSB_20170703_039}")
	elseif g_CurPage == 1 then
		GodWeaponStart_PageHeader_Name : SetText("#{XYSB_20170620_025}")
		GodWeaponStart_NeedItem_Text : SetText("#{XYSB_20170620_026}")
		GodWeaponStart_Desc : ClearAllElement();
		GodWeaponStart_Desc : AddTextElement("#{XYSB_20070928_005}")		
	end
	
	local ItemPos = tonumber(arg1)

	local theAction = EnumAction(ItemPos, "packageitem")
	if theAction:GetID() == 0 then
		GodWeaponStart_NeedItem1:SetActionItem(-1)
		g_WeaponID = -1
		g_WeaponIndex = -1
		GodWeaponStart_NeedItem1_Info : SetText("")
	else
		--释放前一个
		LifeAbility : Lock_Packet_Item(g_WeaponID,0)
			
		GodWeaponStart_NeedItem1:SetActionItem(theAction:GetID())
		LifeAbility : Lock_Packet_Item(ItemPos,1)
		g_WeaponID = ItemPos
		g_WeaponIndex = tonumber(arg2)
		local szItemName = DataPool:Lua_GetItemNameByIndex(g_WeaponIndex)
		GodWeaponStart_NeedItem1_Info : SetText(szItemName)
	end			

end



--===============================================
-- 确定
--===============================================
function GodWeaponStart_Accept_Clicked()
	
	if 	g_WeaponID <0 then
		if g_CurPage == 0 then
			PushDebugMessage("#{XYSB_20170620_023}")
		elseif g_CurPage == 1 then
			PushDebugMessage("#{XYSB_20170620_035}")
		end
		return
	end
	
	if (Accept_Clicked_Num == 0) then
		MissionReply:OpenSecondConfirmFrame(scriptId);		-- 根据调用该界面的scriptId，打开对应的二次确认页面
		Accept_Clicked_Num = 1;
	else 	 
		MissionReply:OnContinue(Pet_Index);
		StopCareObject_MissionReply(objCared)
		Pet_Index = -1;
		Accept_Clicked_Num = 0; 													-- 第2次点击“确定”后，恢复 Accept_Clicked_Num 为未按过“确定”按钮。
		this:Hide();
	end
			
end

--===============================================
-- 取消
--===============================================
function GodWeaponStart_Frame_Cancel_Clicked()

	GodWeaponStart_NeedItem1:SetActionItem(-1)
	LifeAbility : Lock_Packet_Item(g_WeaponID,0)
	g_WeaponID = -1	
	GodWeaponStart_NeedItem1_Info : SetText("")
	Accept_Clicked_Num = 0; 	
	
	this:Hide();

end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_MissionReply(objCaredId)


	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "MissionReply");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_MissionReply(objCaredId)
	this:CareObject(objCaredId, 0, "MissionReply");
	g_Object = -1;
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function GodWeaponStart_Frame_OnClose()
	DataPool:CloseMissionFrame();
	GodWeaponStart_Frame_Cancel_Clicked();
	Pet_Index = -1
end


--=========================================================
-- 点击图标
--=========================================================
function GodWeaponStart_NeedItem_Click(nIndex)
	if nIndex == 0 then
		GodWeaponStart_NeedItem1:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_WeaponID,0)
		g_WeaponID = -1			
		GodWeaponStart_NeedItem1_Info : SetText("")
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function GodWeaponStart_Frame_On_ResetPos()
  GodWeaponStart_Frame:SetProperty("UnifiedPosition", g_GodWeaponStart_Frame_UnifiedPosition);
end