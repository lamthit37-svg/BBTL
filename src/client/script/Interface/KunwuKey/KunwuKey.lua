--五盟领取钥匙界面


local g_KunwuKey_Frame_UnifiedXPosition;

local g_KunwuKey_Frame_UnifiedYPosition;

local g_KunwuKey_NPCTargetID = -1;

local g_KunwuKey_GrowthPlanMF = {}

local g_KunwuKey_GradeBtnID = {}
local g_KunwuKey_GradeRedBtnID = {}

local g_KunwuKey_PrizeIcon = {}

local g_KunwuKey_KeyItemID = {
		--[1] = {itemid = 40005078, count = 1,},
		--[2] = {itemid = 40005079, count = 1,},
		[1] = {itemid = 38001514, count = 1, yuanbao =500},
		[2] = {itemid = 38001515, count = 1, yuanbao =200},
}

local g_KunwuKey_objCared = -1;
local g_KunwuKey_Distance = 5.0;

function KunwuKey_PreLoad()
	--开启界面
	this:RegisterEvent("OPEN_KUNWUKEY");

	this:RegisterEvent("UPDATE_AUTHORIZEDSAFEFLAG")

	this:RegisterEvent("ADJEST_UI_POS",false);

	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	
end	

function KunwuKey_OnLoad()

	-- 保存界面的默认相对位置
	g_KunwuKey_Frame_UnifiedXPosition	= KunwuKey_Frame : GetProperty("UnifiedXPosition");
	g_KunwuKey_Frame_UnifiedYPosition	= KunwuKey_Frame : GetProperty("UnifiedYPosition");
	
	g_KunwuKey_PrizeIcon = {
		{KunwuKey_Frame1_Bk_Icon,KunwuKey_Frame1_Bk1_Icon},
		{KunwuKey_Frame2_Bk_Icon,KunwuKey_Frame2_Bk1_Icon},
	}
end

function KunwuKey_OnEvent(event)

	if ( event == "OPEN_KUNWUKEY") then
		KunwuKey_Open()
	
	elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
		this : Hide()			
		this:CareObject(g_KunwuKey_objCared, 0, "KunwuKey")
		
	--请求数据后显示
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89144701) then
		local nLevel = tonumber(Get_XParam_INT(0))
		local nKeyCount = tonumber(Get_XParam_INT(1))
		local zhantuanId = tonumber(Get_XParam_INT(2))
		local isAcceptKey = tonumber(Get_XParam_INT(3))
		--关注NPC
		g_KunwuKey_objCared = Target:GetServerId2ClientId( tonumber(Get_XParam_INT(4)) )
		this:CareObject(g_KunwuKey_objCared, 1, "KunwuKey")
		local isOpenDay = tonumber(Get_XParam_INT(5))
		KunwuKey_Open_Show(nLevel, nKeyCount, zhantuanId, isAcceptKey, isOpenDay)
	--(点击领取之后，刷新状态)
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89144702) then
		
		local nLevel = tonumber(Get_XParam_INT(0))
		local nKeyCount = tonumber(Get_XParam_INT(1))
		local isMoney = tonumber(Get_XParam_INT(2))
		KunwuKey_PrizeUpdate(nLevel, nKeyCount, isMoney)

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		KunwuKey_Frame_On_ResetPos();
	-- 游戏分辨率发生了变化		
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		KunwuKey_Frame_On_ResetPos();

	elseif (event == "OBJECT_CARED_EVENT") then
		--AxTrace(0, 0, "arg0"..arg0.." arg1"..arg1.." arg2"..arg2);
		if(tonumber(arg0) ~= g_KunwuKey_objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>g_KunwuKey_Distance or arg1=="destroy") then
			this:Hide();
			--取消关心
			this:CareObject(g_KunwuKey_objCared, 0, "KunwuKey");
		end
	end

end	

--===============================================
-- 					切换界面
--===============================================
--也就是主界面--
function KunwuKey_Open()

	CloseWindow("KunwuKey", true)
end

--请求数据后显示
function KunwuKey_Open_Show(nLevel, nKeyCount, zhantuanId, isAcceptKey, isOpenDay)
	KunwuKey_InitIcon()
	KunwuKey_Init_Data(nLevel, nKeyCount, zhantuanId, isAcceptKey, isOpenDay)
	this:Show()
end


--初始化基本数据
function KunwuKey_Init_Data(nLevel, nKeyCount, zhantuanId, isAcceptKey, isOpenDay)
	if isOpenDay == 1 or (isOpenDay == 0 and nLevel == 1) then
		KunwuKey_Frame1_Bk_Button:Disable()
		KunwuKey_Frame1_Bk1_Button:Disable()
		KunwuKey_Frame2_Bk_Button:Disable()
		KunwuKey_Frame2_Bk1_Button:Disable()
		
		if nLevel == 2 then
			KunwuKey_Info:SetText("#{SSHJ_150915_95}")
		elseif nLevel == 3 then
			KunwuKey_Info:SetText("#{SSHJ_150915_94}")
		else
			KunwuKey_Info:SetText("#{SSHJ_150915_42}")
		end
		KunwuKey_Frame1_Bk_Text:SetText("#{SSHJ_150915_43}".."0")
		KunwuKey_Frame1_Bk1_Text:SetText("#{SSHJ_150915_44}"..tostring(g_KunwuKey_KeyItemID[1].yuanbao))
		KunwuKey_Frame2_Bk_Text:SetText("#{SSHJ_150915_43}".."0")
		KunwuKey_Frame2_Bk1_Text:SetText("#{SSHJ_150915_44}"..tostring(g_KunwuKey_KeyItemID[2].yuanbao))
		
		KunwuKey_Frame1_Bk_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		KunwuKey_Frame1_Bk1_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		KunwuKey_Frame2_Bk_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		KunwuKey_Frame2_Bk1_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
	elseif isOpenDay == 0 and nLevel == 2 then
		KunwuKey_Frame1_Bk_Button:Disable()
		KunwuKey_Frame1_Bk1_Button:Disable()
		KunwuKey_Frame1_Bk_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		KunwuKey_Frame1_Bk1_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		if isAcceptKey == 0 then
			if zhantuanId >= 1 and zhantuanId <= 7 then
				KunwuKey_Frame2_Bk_Button:Enable()				
				if nKeyCount == 0 then
					KunwuKey_Frame2_Bk1_Button:Disable()
				else
					KunwuKey_Frame2_Bk1_Button:Enable()
				end
				KunwuKey_Frame2_Bk_Icon_Mask:SetProperty("Image", "")
				KunwuKey_Frame2_Bk1_Icon_Mask:SetProperty("Image", "")
			else
				KunwuKey_Frame2_Bk_Button:Disable()
				if nKeyCount == 0 then
					KunwuKey_Frame2_Bk1_Button:Disable()
				else
					KunwuKey_Frame2_Bk1_Button:Enable()
				end
				KunwuKey_Frame2_Bk_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
				KunwuKey_Frame2_Bk1_Icon_Mask:SetProperty("Image", "")
			end
		else
			KunwuKey_Frame2_Bk_Button:Disable()
			KunwuKey_Frame2_Bk1_Button:Disable()
			KunwuKey_Frame2_Bk_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
			KunwuKey_Frame2_Bk1_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		end
		KunwuKey_Info:SetText("#{SSHJ_150915_41}")
		KunwuKey_Frame1_Bk_Text:SetText("#{SSHJ_150915_43}".."0")
		KunwuKey_Frame1_Bk1_Text:SetText("#{SSHJ_150915_44}"..tostring(g_KunwuKey_KeyItemID[1].yuanbao))
		KunwuKey_Frame2_Bk_Text:SetText("#{SSHJ_150915_43}"..tostring(nKeyCount))
		KunwuKey_Frame2_Bk1_Text:SetText("#{SSHJ_150915_44}"..tostring(g_KunwuKey_KeyItemID[2].yuanbao))
	elseif isOpenDay == 0 and nLevel == 3 then
		if isAcceptKey == 0 then
			if zhantuanId >= 1 and zhantuanId <= 7 then
				KunwuKey_Frame1_Bk_Button:Enable()
				if nKeyCount == 0 then
					KunwuKey_Frame1_Bk1_Button:Disable()
				else
					KunwuKey_Frame1_Bk1_Button:Enable()
				end				
				KunwuKey_Frame1_Bk_Icon_Mask:SetProperty("Image", "")
				KunwuKey_Frame1_Bk1_Icon_Mask:SetProperty("Image", "")
			else
				KunwuKey_Frame1_Bk_Button:Disable()
				if nKeyCount == 0 then
					KunwuKey_Frame1_Bk1_Button:Disable()
				else
					KunwuKey_Frame1_Bk1_Button:Enable()
				end	
				KunwuKey_Frame1_Bk_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
				KunwuKey_Frame1_Bk1_Icon_Mask:SetProperty("Image", "")
			end
		else
			KunwuKey_Frame1_Bk_Button:Disable()
			KunwuKey_Frame1_Bk1_Button:Disable()
			KunwuKey_Frame1_Bk_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
			KunwuKey_Frame1_Bk1_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		end
		KunwuKey_Frame2_Bk_Button:Disable()
		KunwuKey_Frame2_Bk1_Button:Disable()
		KunwuKey_Frame2_Bk_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		KunwuKey_Frame2_Bk1_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		
		KunwuKey_Info:SetText("#{SSHJ_150915_40}")
		KunwuKey_Frame1_Bk_Text:SetText("#{SSHJ_150915_43}"..tostring(nKeyCount))
		KunwuKey_Frame1_Bk1_Text:SetText("#{SSHJ_150915_44}"..tostring(g_KunwuKey_KeyItemID[1].yuanbao))
		KunwuKey_Frame2_Bk_Text:SetText("#{SSHJ_150915_43}".."0")
		KunwuKey_Frame2_Bk1_Text:SetText("#{SSHJ_150915_44}"..tostring(g_KunwuKey_KeyItemID[2].yuanbao))
	end
end

--领取钥匙
function KunwuKey_Reward_Flag(nLevel)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AcceptCopySceneKey")  --脚本接口
		Set_XSCRIPT_ScriptID(891447) --脚本编号 g_CurrentSelect
		Set_XSCRIPT_Parameter(0,nLevel);
		Set_XSCRIPT_Parameter(1,0);
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--领取钥匙
function KunwuKey_Reward_Flag_YuanBao(nLevel)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AcceptCopySceneKey")  --脚本接口
		Set_XSCRIPT_ScriptID(891447) --脚本编号 g_CurrentSelect
		Set_XSCRIPT_Parameter(0,nLevel);
		Set_XSCRIPT_Parameter(1,1);
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--领奖之后更新按钮以及缓存数据
function KunwuKey_PrizeUpdate(nLevel, nKeyCount, isMoney)
	if nLevel == 2 then
		KunwuKey_Frame2_Bk1_Button:Disable()
		if isMoney == 0 then
			KunwuKey_Frame2_Bk_Text:SetText("#{SSHJ_150915_43}"..tostring(nKeyCount))
		else
			if nKeyCount == 0 then
				KunwuKey_Frame2_Bk1_Button:Enable()
			end			
		end
		KunwuKey_Frame2_Bk_Button:Disable()		
		KunwuKey_Frame2_Bk_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		KunwuKey_Frame2_Bk1_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
	elseif nLevel == 3 then
		KunwuKey_Frame1_Bk1_Button:Disable()
		if isMoney == 0 then
			KunwuKey_Frame1_Bk_Text:SetText("#{SSHJ_150915_43}"..tostring(nKeyCount))
		else
			if nKeyCount == 0 then
				KunwuKey_Frame1_Bk1_Button:Enable()
			end				
		end
		KunwuKey_Frame1_Bk_Button:Disable()		
		KunwuKey_Frame1_Bk_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		KunwuKey_Frame1_Bk1_Icon_Mask:SetProperty("Image", "set:Face_04 image:Remind_Bak")
	end
end

function KunwuKey_InitIcon()
	DataPool:Lua_ClearSanShenKeyActionItem()
	
	DataPool:Lua_SetSanShenKeyActionItem(0, g_KunwuKey_KeyItemID[1].itemid)
	DataPool:Lua_SetSanShenKeyActionItem(1, g_KunwuKey_KeyItemID[2].itemid)
	DataPool:Lua_UpdateSanShenKeyActionItem()
	
	local theAction = EnumAction( 0, "sanshenkey")
	if theAction:GetID() ~= 0 then
		KunwuKey_Frame1_Bk_Icon:SetActionItem( theAction:GetID())
		KunwuKey_Frame1_Bk1_Icon:SetActionItem( theAction:GetID())
	else
		KunwuKey_Frame1_Bk_Icon:SetActionItem( -1)
		KunwuKey_Frame1_Bk1_Icon:SetActionItem( -1)
	end
	
	theAction = EnumAction( 1, "sanshenkey")
	if theAction:GetID() ~= 0 then
		KunwuKey_Frame2_Bk_Icon:SetActionItem( theAction:GetID())
		KunwuKey_Frame2_Bk1_Icon:SetActionItem( theAction:GetID())
	else
		KunwuKey_Frame2_Bk_Icon:SetActionItem( -1)
		KunwuKey_Frame2_Bk1_Icon:SetActionItem( -1)
	end
end

--更新主界面位置
function KunwuKey_Frame_On_ResetPos()
	KunwuKey_Frame : SetProperty("UnifiedXPosition", g_KunwuKey_Frame_UnifiedXPosition);
	KunwuKey_Frame : SetProperty("UnifiedYPosition", g_KunwuKey_Frame_UnifiedYPosition);

end

-----辅助函数：刷新按钮文字、刷新Frame文字 end
function KunwuKey_Close()
	this:Hide()
	this:CareObject(g_KunwuKey_objCared, 0, "KunwuKey")
end
