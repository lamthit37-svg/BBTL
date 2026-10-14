--徒弟供奉界面
local g_NewFriend_GFSF_Frame_UnifiedXPosition

local g_NewFriend_GFSF_Frame_UnifiedYPosition

local g_NewFriend_GFSF_PrizeItemID = {
	38001274,
	38001275,
}

local g_NewFriend_GFSF_PrizeIcon = {}
local g_NewFriend_GFSF_ActivePoint = 50

function NewFriend_GFSF_PreLoad()
	--开启界面
	this:RegisterEvent("OPEN_NEWFRIEND_GFSF")
	
	this:RegisterEvent("ADJEST_UI_POS",false);

	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
end	

function NewFriend_GFSF_OnLoad()

	-- 保存界面的默认相对位置
	g_NewFriend_GFSF_Frame_UnifiedXPosition	= NewFriend_GFSF_Frame : GetProperty("UnifiedXPosition");
	g_NewFriend_GFSF_Frame_UnifiedYPosition	= NewFriend_GFSF_Frame : GetProperty("UnifiedYPosition");
	
	g_NewFriend_GFSF_PrizeIcon[1] = NewFriend_GFSF_GetIcon1
	g_NewFriend_GFSF_PrizeIcon[2] = NewFriend_GFSF_GetIcon2
end

function NewFriend_GFSF_OnEvent(event)

	if ( event == "OPEN_NEWFRIEND_GFSF") then
		
		if (IsInTServer() == 1) then
			PushDebugMessage("#{BHKF_140909_327}")
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskGongfengFlag")
			Set_XSCRIPT_ScriptID(891121)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89112101) then
		local nFlag = tonumber(Get_XParam_INT(0))
		local nHaveMaster = tonumber(Get_XParam_INT(1))
		NewFriend_GFSF_Open(nFlag, nHaveMaster)
	
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89112102) then
		local nSucess = tonumber(Get_XParam_INT(0))
		if nSucess == 1 then
			NewFriend_GFSF_HuoyuePanduan:SetText("#{STGZ_150514_436}")
		end

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		NewFriend_GFSF_Frame_On_ResetPos();
	-- 游戏分辨率发生了变化		
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		NewFriend_GFSF_Frame_On_ResetPos();
	end

end	

--也就是主界面--
function NewFriend_GFSF_Open(nFlag, nHaveMaster)

	CloseWindow("NewFriend_GFSF", true)
	--加载数据客户端
	NewFriend_GFSF_InitText(nFlag, nHaveMaster)
	NewFriend_GFSF_ItemIcon()
	NewFriend_GFSF_Show()
end


function NewFriend_GFSF_GongfengSF()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GongfengMaster")
		Set_XSCRIPT_ScriptID(891121)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--更新主界面位置
function NewFriend_GFSF_Frame_On_ResetPos()
	NewFriend_GFSF_Frame : SetProperty("UnifiedXPosition", g_NewFriend_GFSF_Frame_UnifiedXPosition);
	NewFriend_GFSF_Frame : SetProperty("UnifiedYPosition", g_NewFriend_GFSF_Frame_UnifiedYPosition);

end

--显示控件，默认不显示
function NewFriend_GFSF_Show()
	this:Show()
end

function NewFriend_GFSF_InitText(nFlag, nHaveMaster)
	local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
	local strTextInfo = ""
	strTextInfo = ScriptGlobal_Format("#{STGZ_150514_433}", tostring(nToadyActivePoint))
	NewFriend_GFSF_Huoyue:SetText(strTextInfo)
	
	if nFlag == 1 then
		NewFriend_GFSF_HuoyuePanduan:SetText("#{STGZ_150514_436}")
	else
		if nHaveMaster ~= 1 then
			NewFriend_GFSF_HuoyuePanduan:SetText("#{STGZ_150514_449}")
		else
			if nToadyActivePoint < g_NewFriend_GFSF_ActivePoint then
				NewFriend_GFSF_HuoyuePanduan:SetText("#{STGZ_150514_434}")
			else
				NewFriend_GFSF_HuoyuePanduan:SetText("#{STGZ_150514_435}")
			end
		end
	end
end

function NewFriend_GFSF_ItemIcon()

	DataPool:Lua_ClearShituGongfengActionItem()
	
	DataPool:Lua_SetShituGongfengActionItem(0, g_NewFriend_GFSF_PrizeItemID[1])
	DataPool:Lua_SetShituGongfengActionItem(1, g_NewFriend_GFSF_PrizeItemID[2])
	DataPool:Lua_UpdateShituGongfengActionItem()
	
	local theAction = EnumAction( 0, "shitugongfeng")
	if theAction:GetID() ~= 0 then
		g_NewFriend_GFSF_PrizeIcon[1]:SetActionItem( theAction:GetID())
	else
		g_NewFriend_GFSF_PrizeIcon[1]:SetActionItem( -1 )
	end
	
	theAction = EnumAction( 1, "shitugongfeng")
	if theAction:GetID() ~= 0 then
		g_NewFriend_GFSF_PrizeIcon[2]:SetActionItem( theAction:GetID())
	else
		g_NewFriend_GFSF_PrizeIcon[2]:SetActionItem( -1 )
	end
	
end
function NewFriend_GFSF_Close()
	this:Hide()
end
