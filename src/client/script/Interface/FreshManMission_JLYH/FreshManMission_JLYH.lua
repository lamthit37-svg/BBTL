
local g_FreshManMission_JLYH_Frame_UnifiedXPosition
local g_FreshManMission_JLYH_Frame_UnifiedYPosition
local g_FreshManMission_JLYH_Frame_currentpage = 0
local g_FreshManMission_JLYH_Frame_maxpage = 0
--此变量用以确认当前新手指引所到达的环节，2013Q3新手指引添加
local g_CurActFlashType = 0

--===============================================
-- PreLoad()
--===============================================
function FreshManMission_JLYH_PreLoad()

	this:RegisterEvent("PACKAGE_AWARDITEM");
	this:RegisterEvent("OPEN_EQUIPCHANGE_MESSAGEBOX");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	--2013Q3新手坐骑指引
	this:RegisterEvent("UI_COMMAND");

end

--===============================================
-- OnLoad()
--===============================================
function FreshManMission_JLYH_OnLoad()
	-- 保存Frame默认位置
	g_FreshManMission_JLYH_Frame_UnifiedXPosition	= FreshManMission_JLYH_Frame:GetProperty("UnifiedXPosition");
	g_FreshManMission_JLYH_Frame_UnifiedYPosition	= FreshManMission_JLYH_Frame:GetProperty("UnifiedYPosition");
end

--===============================================
-- OnEvent()
--===============================================
function FreshManMission_JLYH_OnEvent( event )


	if ( event == "PACKAGE_AWARDITEM" ) then
		g_CurActFlashType = 0

		if arg0 == nil then
			return;
		end
		local mylevel = Player:GetLevel();
		if mylevel > 30 then
			return;
		end

		local ret_Suggest = SuggestChangeEuip(tonumber(arg0));

		if mylevel <= 15 then
			local theAction = GetAction_ItemID_FromMyPacket( tonumber(arg0) );
			if theAction:GetDefineID() == 10141517 then
				g_CurActFlashType = 20130929
				if g_FreshManMission_JLYH_Frame_currentpage <= 0 then
					g_FreshManMission_JLYH_Frame_currentpage = 1
				end
				SCItemSet_Clear();	--clean一下
				SCItemSet_PushItem(tonumber(arg0));
				FreshManMission_JLYH_Update(g_FreshManMission_JLYH_Frame_currentpage)
				this:Show()
				return
			end
		end

		if ret_Suggest > 0 then
			local ret = SCItemSet_PushItem(tonumber(arg0));
			if ret > 0 then
				PushEvent("OPEN_EQUIPCHANGE_MESSAGEBOX")
			end
		end

	elseif( event == "OPEN_EQUIPCHANGE_MESSAGEBOX" ) then
		--	初始武器发放时，玩家没有经验，只能跟这里来了。上面那个时间根本就控不住。。。。
		--local nCurExp = Player:GetData("EXP");
		--if nCurExp < 1 then
			--return
		--end

		local mylevel = Player:GetLevel();
		if mylevel > 30 then
			return;
		end
		if g_FreshManMission_JLYH_Frame_currentpage <= 0 then
		 g_FreshManMission_JLYH_Frame_currentpage = 1
		end
		FreshManMission_JLYH_Update(g_FreshManMission_JLYH_Frame_currentpage)
		this:Show()

		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("TuijianEquipAuditLog_Show")
			Set_XSCRIPT_ScriptID(889843)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT();

	elseif( event == "ADJEST_UI_POS" ) then
		FreshManMission_JLYH_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		FreshManMission_JLYH_ResetPos()

	--2013Q3新手任务坐骑指引
	elseif( event == "UI_COMMAND" ) then
		if tonumber( arg0 ) == 20130929 and g_CurActFlashType == 20130929  then
			if g_FreshManMission_JLYH_Frame_currentpage <= 0 then
				return
				--g_FreshManMission_JLYH_Frame_currentpage = 1
			end
			FreshManMission_JLYH_Update(g_FreshManMission_JLYH_Frame_currentpage)
			this:Show()
			FreshManMission_JLYH_OK:SetProperty( "Flash", "1" );
			FreshManMission_JLYH_FreshManGuide( 1, -1, 12)
			PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",11)
		end

	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" ) then
		--local mylevel = Player:GetLevel();
		--if mylevel > 30 and this:IsVisible() == false then

		if this:IsVisible() == false then
			return;
		end
		FreshManMission_JLYH_Update(g_FreshManMission_JLYH_Frame_currentpage)
	end

end


--===============================================
-- Other function
--===============================================
function FreshManMission_JLYH_ResetPos()
	FreshManMission_JLYH_Frame:SetProperty("UnifiedXPosition", g_FreshManMission_JLYH_Frame_UnifiedXPosition);
	FreshManMission_JLYH_Frame:SetProperty("UnifiedYPosition", g_FreshManMission_JLYH_Frame_UnifiedYPosition);
end

function FreshManMission_JLYH_Update( currentpage )
	local szText
	local theAction
	local ItemClientID
	local i

	local newindex, ret_suggest = SCItemSet_Update(currentpage-1)
	local newselectedpage = newindex + 1

	local mylevel = Player:GetLevel()

	if g_CurActFlashType == 20130929 then
		for i=0,SCItemSet_Count() do
			ItemClientID = SCItemSet_GetItem(i);
			theAction = GetAction_ItemID_FromMyPacket(tonumber(ItemClientID));
			if theAction:GetDefineID() == 10141517 then
				FreshManMission_JLYH_PageNumber:SetText(tostring(1).."/"..tostring(1));
				FreshManMission_JLYH_Item:SetActionItem(theAction:GetID());
				szText = ScriptGlobal_Format("#{XSJLYH_120206_02}", theAction:GetName() )
				FreshManMission_JLYH_Text:SetText(szText);
				FreshManMission_JLYH_PageDown:Disable();
				FreshManMission_JLYH_PageUp:Disable();
				return 1
			end
		end
	end

	if ret_suggest <= 0 then
		return -1;
	end

	local g_FreshManMission_JLYH_Frame_maxpage = SCItemSet_Count();
	if g_FreshManMission_JLYH_Frame_maxpage <= 0 then
		FreshManMission_JLYH_Close_Clicked()
		return -1;
	end

	if newselectedpage <=0  or newselectedpage > g_FreshManMission_JLYH_Frame_maxpage then
		return -1;
	end

	ItemClientID = SCItemSet_GetItem(newselectedpage-1);

	theAction = GetAction_ItemID_FromMyPacket(ItemClientID);
	if theAction:GetID() == 0 then
		return -1;
	end


	g_FreshManMission_JLYH_Frame_currentpage = newselectedpage;

	if newselectedpage <= 1 then
		FreshManMission_JLYH_PageUp:Disable();
	else
		FreshManMission_JLYH_PageUp:Enable();
	end

	if newselectedpage >= g_FreshManMission_JLYH_Frame_maxpage then
		FreshManMission_JLYH_PageDown:Disable();
	else
		FreshManMission_JLYH_PageDown:Enable();
	end

	FreshManMission_JLYH_PageNumber:SetText(tostring(newselectedpage).."/"..tostring(g_FreshManMission_JLYH_Frame_maxpage));

	FreshManMission_JLYH_Item:SetActionItem(theAction:GetID());

	if ret_suggest == 1 then
		szText = ScriptGlobal_Format("#{XSJLYH_120206_04}", theAction:GetName() )
	else
		szText = ScriptGlobal_Format("#{XSJLYH_120206_02}", theAction:GetName() )
	end

	FreshManMission_JLYH_Text:SetText(szText);

	return 1

end

--更换装备
function FreshManMission_JLYH_OK_Clicked()
	local i
	if g_CurActFlashType == 20130929 then
		for i=0,SCItemSet_Count() do
			ItemClientID = SCItemSet_GetItem(i);
			theAction = GetAction_ItemID_FromMyPacket(tonumber(ItemClientID));
			if theAction:GetDefineID() == 10141517 then
				ChangeSuggestEuip(ItemClientID)
				NotifyPopUITip("MainMenuBar", 1, 8)
				FreshManMission_JLYH_OK:SetProperty( "Flash", "0" );
				g_CurActFlashType = 0
			end
		end
		return
	end

	local ItemClientID = SCItemSet_GetItem(g_FreshManMission_JLYH_Frame_currentpage-1);
	--local ret = SuggestChangeEuip(ItemClientID);
	--if ret > 0 then
		local ret = ChangeSuggestEuip(ItemClientID)
		--FreshManMission_JLYH_Item:DoAction()
	--else
	   --提示
	--end

	if ret > 0 then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("TuijianEquipAuditLog_OK")
			Set_XSCRIPT_ScriptID(889843)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT();
	end

	if "FreshManMission_JLYH_Frame" == GetFreshManGuideOwner() then
		CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
    end

end

--上一页
function FreshManMission_JLYH_PageUp_Click()
	FreshManMission_JLYH_Update(g_FreshManMission_JLYH_Frame_currentpage-1)
end

--下一页
function FreshManMission_JLYH_PageDown_Click()
	FreshManMission_JLYH_Update(g_FreshManMission_JLYH_Frame_currentpage+1)
end

--关闭界面
function FreshManMission_JLYH_Close_Clicked()
	if "FreshManMission_JLYH_Frame" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
		FreshManMission_JLYH_OK:SetProperty( "Flash", "0" );
    end
	this:Hide();
end

function FreshManMission_JLYH_Cancel_Clicked()
	g_FreshManMission_JLYH_Frame_currentpage = 0;
	g_FreshManMission_JLYH_Frame_maxpage = 0;
	FreshManMission_JLYH_OnHidden()
	if "FreshManMission_JLYH_Frame" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
		FreshManMission_JLYH_OK:SetProperty( "Flash", "0" );
		return
    end
	if g_CurActFlashType == 20130929 then
		return
	end
	SCItemSet_Clear();
end

function FreshManMission_JLYH_OnMoved()
	if "FreshManMission_JLYH_Frame" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
		FreshManMission_JLYH_FreshManGuide(2, -1, g_CurActFlashType)
	end
end

function FreshManMission_JLYH_OnHidden()
    if "FreshManMission_JLYH_Frame" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
    end
end

function FreshManMission_JLYH_FreshManGuide( nType, nTextID, nPosID )
	if nType ~= 1 and      --1 is reset and open
        nType ~= 2 then    --2 is modify
        return
    end
	local fX = 0
    local fY = 0
    local fW = 0
    local fH = 0
    local PosX = tonumber(FreshManMission_JLYH_Frame:GetProperty("AbsoluteXPosition"))
    local PosY = tonumber(FreshManMission_JLYH_Frame:GetProperty("AbsoluteYPosition"))
	if nPosID == 12 then	--点击装备道具的指引
		--g_CurActFlashType = 12
		fX, fY = this:GetChildOffset("FreshManMission_JLYH_OK")
		local fH = tonumber(FreshManMission_JLYH_OK:GetProperty("AbsoluteHeight"))
		local fW = tonumber(FreshManMission_JLYH_OK:GetProperty("AbsoluteWidth"))
		fX = math.floor( tonumber( PosX - 40) )
		fY = math.floor( tonumber( fY + PosY + fH + 25 ) )
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 12, 0, "FreshManMission_JLYH_Frame")
	end
end
