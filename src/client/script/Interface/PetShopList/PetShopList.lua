local g_nSelect_Index = -1;
local g_PreSelect = -1;
local g_PetIndex  = {};
local PET_MAX_NUMBER = 10	--最大珍兽携带上限 --add by xindefeng
local g_PetList_Frame_UnifiedPosition;
--===============================================
-- OnLoad()
--===============================================
function PetShopList_PreLoad()

	this:RegisterEvent("OPEN_PET_SHOP_LIST");
	this:RegisterEvent("REPLY_MISSION");
	this:RegisterEvent("REPLY_MISSION_PET");
	this:RegisterEvent("CLOSE_PET_LIST");
	this:RegisterEvent("CLOSE_PET_FRAME");
	this:RegisterEvent("CLOSE_MISSION_REPLY");
	this:RegisterEvent("OPEN_EXCHANGE_FRAME");
	this:RegisterEvent("TOGGLE_PETLIST");
	this:RegisterEvent("UPDATE_PET_LIST");
	this:RegisterEvent("UPDATE_PET_PAGE", false);
	this : RegisterEvent("DELETE_PET");
			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function PetShopList_OnLoad()

	for i=1 ,20   do
		g_PetIndex[i] = -1;
	end
	 g_PetList_Frame_UnifiedPosition=PetShopList_Frame:GetProperty("UnifiedPosition");
end

--===============================================
-- OnEvent()
--===============================================
function PetShopList_OnEvent(event)
	--PushDebugMessage("PetList : "..event);

	-- 打开珍兽列表界面
	if(event == "OPEN_PET_SHOP_LIST") then
		local typeStr = agr0
		this:Show();
		PetShopList_UpdateFrame();
		PetShopList_Frame:SetProperty("UnifiedXPosition","{1.0,-215}");
		PetShopList_Frame:SetProperty("UnifiedYPosition","{0.0,201}");

	-- 更新珍兽列表界面
	elseif ( event == "UPDATE_PET_LIST" ) then
		PetShopList_UpdateFrame();

	-- 玩家身上的珍兽数据发生变化，包括珍兽出战、休息、增加一只珍兽
	elseif ( event == "UPDATE_PET_PAGE" ) then
		PetShopList_UpdateFrame();

	-- 玩家从列表选定一只珍兽
	elseif(event == "REPLY_MISSION_PET") then
		PetShopList_UpdateFrame();

	-- 玩家身上减少1只珍兽
	elseif (event == "DELETE_PET") then
		PetShopList_UpdateFrame();

	-- 关闭任务提交界面
	elseif ( event == "CLOSE_MISSION_REPLY" ) then
		PetShopList_Refuse_Click();

	-- 关闭珍兽列表界面
	elseif ( event == "CLOSE_PET_LIST" ) then
		PetShopList_Refuse_Click();

	elseif ( event == "CLOSE_PET_FRAME" ) then
		PetShopList_Refuse_Click();

	elseif ( event == "TOGGLE_PETLIST" ) then
--		this:TogleShow();

	end
			-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		PetShopList_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetShopList_Frame_On_ResetPos()
	end
end

--===============================================
-- 更新界面
--===============================================
function PetShopList_UpdateFrame()

	-- 先清空当前列表
	PetShopList_List:ClearListBox();

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
			PetShopList_List:AddItem(szPetName, i);
			PetShopList_List:SetItemTooltip( PetInListIndex, strToolTips );
			PetInListIndex = PetInListIndex + 1 ;
		end
	end

end

--===============================================
-- 选择
--===============================================
function PetShopList_Choose_Click()
	g_nSelect_Index = PetShopList_List:GetFirstSelectItem();
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
	Exchange:AddPet(g_nSelect_Index);
end

--===============================================
-- 放弃
--===============================================
function PetShopList_Refuse_Click()
	--if g_nSelect_Index ~= -1 then
	--	Pet:SetPetLocation(g_nSelect_Index,-1);
	--end
	this:Hide();
end

--===============================================
-- 选中列表中的珍兽
--===============================================
function PetShopList_List_Selected()
	g_nSelect_Index = PetShopList_List:GetFirstSelectItem();
end

--===============================================
--根据选择的珍兽，显示相应的详细信息
--===============================================
function PetShopList_ShowTargetPet()
	g_nSelect_Index = PetShopList_List:GetFirstSelectItem();

	if( -1 == g_nSelect_Index ) then
		return;
	end
	Pet:ShowTargetPet(g_nSelect_Index);

end



--================================================
-- 恢复界面的默认相对位置
--================================================
function PetShopList_Frame_On_ResetPos()
  PetShopList_Frame:SetProperty("UnifiedPosition", g_PetList_Frame_UnifiedPosition);
end
