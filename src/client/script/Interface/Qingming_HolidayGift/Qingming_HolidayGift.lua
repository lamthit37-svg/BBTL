--=========================================================
--清明节抽奖活动
--节日礼包界面
--by limengyue 2021-01-11
--=========================================================

local g_Qingming_HolidayGift_Frame_UnifiedPosition;
--关心NPc
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local g_Object = -1

--===============================================
-- OnLoad()
--===============================================
function Qingming_HolidayGift_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function Qingming_HolidayGift_OnLoad()   
	-- 保存界面的默认相对位置
	g_Qingming_HolidayGift_Frame_UnifiedPosition = Qingming_HolidayGift_Frame:GetProperty("UnifiedPosition");

end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Qingming_HolidayGift_Frame_On_ResetPos()
	Qingming_HolidayGift_Frame : SetProperty("UnifiedPosition", g_Qingming_HolidayGift_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function Qingming_HolidayGift_OnEvent(event)

    if(event == "UI_COMMAND" and tonumber(arg0) == 50508006) then
		--打开界面
		if(IsWindowShow("Qingming_HolidayGift")) then
			CloseWindow("Qingming_HolidayGift", true)
		end
		if(IsWindowShow("Qingming")) then
			CloseWindow("Qingming", true)
		end
		--添加NPC关心
		if Get_XParam_INT(0) >= 0 then
			objCared = DataPool : GetNPCIDByServerID(Get_XParam_INT(0));
			Qingming_HolidayGift_BeginCareObject(objCared)
		end
		Qingming_HolidayGift_Open(Get_XParam_INT(1))
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 50508007) then
		Qingming_HolidayGift_Disable()
		Qingming_HolidayGift_Close() -- Add: 领完直接关闭
	end
	if (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			Qingming_HolidayGift_Close()
		end
	end
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Qingming_HolidayGift_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Qingming_HolidayGift_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       Qingming_HolidayGift_Close()
    end
         
end

--===============================================
-- Qingming_HolidayGift_Close()
--===============================================
function Qingming_HolidayGift_Close()
	Qingming_HolidayGift_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function Qingming_HolidayGift_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "Qingming_HolidayGift");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "Qingming_HolidayGift")
end


--=========================================================
--停止对某NPC的关心
--=========================================================
function Qingming_HolidayGift_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "Qingming_HolidayGift");
		g_Object = -1;
	end
end



--===============================================
-- 打开界面
--===============================================
function Qingming_HolidayGift_Open(GiftID)
	local MyName = Player:GetName()
	Qingming_HolidayGift_LetterName:SetText(ScriptGlobal_Format("#{QMCJ_190310_107}", MyName))	
	--按钮
	Qingming_HolidayGift_GiftItem:Enable()
	--礼盒显示
	if GiftID > 0 then
		local theAction = DataPool:CreateActionItemForShow(GiftID, 1)
		if theAction:GetID() ~= 0 then
			Qingming_HolidayGift_GiftItem:SetActionItem(theAction:GetID());
			Qingming_HolidayGift_GiftItem:Show()
		end
	end
	--动画
	Qingming_HolidayGift_GiftItem_Animate:Show();
	Qingming_HolidayGift_GiftItem_Animate:Play(true);
	
	this:Show()
end


--===============================================
-- 确认领取礼包
--===============================================
function Qingming_HolidayGiftBtn_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetGiftOk")
		Set_XSCRIPT_ScriptID(505080) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end


--===============================================
-- 领完礼包按钮置灰
--===============================================
function Qingming_HolidayGift_Disable()
	--按钮
	Qingming_HolidayGift_GiftItem:Disable()
	--动画
	Qingming_HolidayGift_GiftItem_Animate:Hide()
	Qingming_HolidayGift_GiftItem_Animate:Play(false);

end

