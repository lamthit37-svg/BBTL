local g_nSelect_Index = -1;
local g_PreSelect = -1;
local g_PetIndex  = {};
local PET_MAX_NUMBER = 10	--最大珍兽携带上限 --add by xindefeng
local g_PetList_Frame_UnifiedPosition;
--===============================================
-- OnLoad()
--===============================================
function PetList_PreLoad()

	this:RegisterEvent("OPEN_PET_LIST",true);
	this:RegisterEvent("REPLY_MISSION",true);
	this:RegisterEvent("REPLY_MISSION_PET",false);
	this:RegisterEvent("CLOSE_PET_LIST",false);
	this:RegisterEvent("CLOSE_PET_FRAME",false);
	this:RegisterEvent("CLOSE_MISSION_REPLY",false);
	this:RegisterEvent("OPEN_EXCHANGE_FRAME",true);
	this:RegisterEvent("TOGGLE_PETLIST",false);
	this:RegisterEvent("UPDATE_PET_LIST",false);
	this:RegisterEvent("UPDATE_PET_PAGE",false);
	this : RegisterEvent("DELETE_PET",false);
			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	

end

function PetList_OnLoad()

	for i=1 ,20   do
		g_PetIndex[i] = -1;
	end
	 g_PetList_Frame_UnifiedPosition=PetList_Frame:GetProperty("UnifiedPosition");
end

--===============================================
-- OnEvent()
--===============================================
function PetList_OnEvent(event)
	--PushDebugMessage("PetList : "..event);

	-- 打开珍兽列表界面	
	if(event == "OPEN_PET_LIST") then
		this:Show();
		PetList_UpdateFrame();
		PetList_Frame:SetProperty("UnifiedXPosition","{1.0,-215}");
		PetList_Frame:SetProperty("UnifiedYPosition","{0.0,201}");

	-- 打开任务提交界面
	elseif(event == "REPLY_MISSION") then
		-- “血浴神兵”任务时，不需要打开珍兽列表界面,modify by chendejia
		local shenBing_ScriptId	= 500503
		if (arg1~=nil and (tonumber(arg1) == shenBing_ScriptId or tonumber(arg1) == 500504 )) then
			return		
		end
		this:Show();
		PetList_Frame:SetProperty("UnifiedXPosition","{0.0,604}");
		PetList_Frame:SetProperty("UnifiedYPosition","{0.0,71}");
		PetList_UpdateFrame();

	-- 打开交易界面
	elseif( event == "OPEN_EXCHANGE_FRAME" )  then
		--KServer不准宠物交易，不打开这个界面
		--local isKvKSever = tonumber(arg1)
		--if isKvKSever ~= nil and isKvKSever == 1 then
			--return
		--end

		this:Show();
		PetList_UpdateFrame();
		PetList_Frame:SetProperty("UnifiedXPosition","{0.0,540}");
		PetList_Frame:SetProperty("UnifiedYPosition","{0.0,206}");

	-- 更新珍兽列表界面
	elseif ( event == "UPDATE_PET_LIST" ) then
		PetList_UpdateFrame();

	-- 玩家身上的珍兽数据发生变化，包括珍兽出战、休息、增加一只珍兽
	elseif ( event == "UPDATE_PET_PAGE" ) then
		PetList_UpdateFrame();
	
	-- 玩家从列表选定一只珍兽
	elseif(event == "REPLY_MISSION_PET") then
		PetList_UpdateFrame();
		
	-- 玩家身上减少1只珍兽
	elseif (event == "DELETE_PET") then
		PetList_UpdateFrame();
	
	-- 关闭任务提交界面
	elseif ( event == "CLOSE_MISSION_REPLY" ) then
		PetList_Refuse_Click();

	-- 关闭珍兽列表界面
	elseif ( event == "CLOSE_PET_LIST" ) then
		PetList_Refuse_Click();
		
	elseif ( event == "CLOSE_PET_FRAME" ) then
		PetList_Refuse_Click();

	elseif ( event == "TOGGLE_PETLIST" ) then
--		this:TogleShow();

	end
			-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		PetList_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetList_Frame_On_ResetPos()
	end
end

--===============================================
-- 更新界面
--===============================================
function PetList_UpdateFrame()

	-- 先清空当前列表
	PetList_List:ClearListBox();
	
	local PetInListIndex = 0;
	for	i=0, PET_MAX_NUMBER-1 do	--modify by xindfeng	不能用当前珍兽的数目，因为中间的某些兽栏可能为空。
		local szPetName,szOn = Pet:GetPetList_Appoint(i);
		local strToolTips = "";

		if(szPetName ~= "")   then
			-- 珍兽不在背包里
			if ( szOn ~= "on_packa" ) then 
				szPetName = "#c808080" .. szPetName;		-- 灰色显示
			end
			
			-- 珍兽在背包里，并且已经提交到某界面
			--local nLocation = Pet:GetPetLocation(i)
			--if ( szOn == "on_packa" ) and ( nLocation ~= -1 ) then
			--	szPetName = "#G" .. szPetName;					-- 绿色显示
			--end

			if(PlayerPackage:IsPetLock(i) == 1)    then
			  local nUnlockElapsedTime = PlayerPackage:GetPUnlockElapsedTime_Pet(i);
				if( nUnlockElapsedTime == 0 ) then
					szPetName = szPetName.. "  #-05";
					strToolTips =  "已加锁" ;
				else
					szPetName = szPetName.. "  #-10";
					local strLeftTime = g_GetUnlockingStr(nUnlockElapsedTime);			
					strToolTips = strLeftTime ;
				end
			end
			PetList_List:AddItem(szPetName, i);
			PetList_List:SetItemTooltip( PetInListIndex, strToolTips );
			PetInListIndex = PetInListIndex + 1 ;
		end
	end

end

--===============================================
-- 选择
--===============================================
function PetList_Choose_Click()
	g_nSelect_Index = PetList_List:GetFirstSelectItem();
	if( g_nSelect_Index == -1 )  then
		return;
	end

	local NeedCheckLock = 1
	if 	IsWindowShow("PetLingXingUp")
		or IsWindowShow("PetSkillStudy")
		or IsWindowShow("PetSavvy")
		or IsWindowShow("PetSavvyGGD")
		or IsWindowShow("PetXingGe")
		or IsWindowShow("PetProcreate")
		or IsWindowShow("PetZhengYou")
		or IsWindowShow("PetFriendSearch")
		or IsWindowShow("PetLevelup")
		or IsWindowShow("PetStudyNewSkill")
		or IsWindowShow("PetPropagateCheck")
		or IsWindowShow("Pethuantong")
		or IsWindowShow("PetRHD")
		or IsWindowShow("PetZhuanXing")
		then
		NeedCheckLock = 0
	end

	if IsWindowShow("PetHuanhua")
		or IsWindowShow("PetChangeModel") then
		NeedCheckLock = 0
	end

	if NeedCheckLock == 1 and PlayerPackage:IsPetLock(g_nSelect_Index) == 1 then
		PushDebugMessage("珍兽已加锁")
		return;
	end

	--授权安全模式下需要安全验证 [7/25/2013 shh][TT]
	if GetAuthorizedSafeFlag() == 1 and CheckPhoneMibaoAndMinorPassword() == 0 then	
		return
	end
	SetGlobalInteger(g_nSelect_Index, "StallSale_SelectPetIndex")
	Exchange:AddPet(g_nSelect_Index);
end

--===============================================
-- 放弃
--===============================================
function PetList_Refuse_Click()
	--if g_nSelect_Index ~= -1 then
	--	Pet:SetPetLocation(g_nSelect_Index,-1);
	--end
	this:Hide();
end

--===============================================
-- 选中列表中的珍兽
--===============================================
function PetList_List_Selected()
	g_nSelect_Index = PetList_List:GetFirstSelectItem();
end

--===============================================
--根据选择的珍兽，显示相应的详细信息
--===============================================
function PetList_ShowTargetPet()
	g_nSelect_Index = PetList_List:GetFirstSelectItem();

	if( -1 == g_nSelect_Index ) then
		return;
	end
	Pet:ShowTargetPet(g_nSelect_Index);

end



--================================================
-- 恢复界面的默认相对位置
--================================================
function PetList_Frame_On_ResetPos()
  PetList_Frame:SetProperty("UnifiedPosition", g_PetList_Frame_UnifiedPosition);
end