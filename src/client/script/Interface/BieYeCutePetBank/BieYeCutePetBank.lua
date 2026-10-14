local g_BieYeCutePetBank_Frame_UnifiedPosition;

--格子及其编号
local GRID_BUTTONS_NUM = 6;
local GRID_BUTTONS_SP_NUM = 8;
local GRID_BUTTONSLine1 = {};
local GRID_BUTTONSLine2 = {};
local GRID_BUTTONSLine3 = {};
local GRID_BUTTONSLineSP = {};

local ActionButtonLine1 = {};
local ActionButtonLine2 = {};
local ActionButtonLine3 = {};
local ActionButtonSp = {};

local g_JieMian = {}
local g_MengChongCurrentPage = 1


local g_MengChong_LR_Page1 = 1
local g_MengChong_LR_Page2 = 1
local g_MengChong_LR_Page3 = 1
local g_MengChong_LR_PageSP = 1

local g_index1 = -1
local g_index2 = -1
local g_index3 = -1
local g_indexSP = -1
local g_MengChongindexChoose =
{
[1] = {-1,-1,-1,-1,-1,-1},
[2] = {-1,-1,-1,-1,-1,-1},
[3] = {-1,-1,-1,-1,-1,-1},
}
local g_MengChongindexChooseSP =
{
-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,
-1,-1,-1,-1,-1,-1,-1,-1,
}


local g_MengChongImage = {
						["Type1"] = "set:CutePet01 image:CutePet01_CutePetType",
						["Type2"] = "set:CutePet01 image:CutePet01_CutePet",
						["WuZhong1"] = "set:CutePet01 image:CutePet01_CutePetCat",
						["WuZhong2"] = "set:CutePet01 image:CutePet01_CutePetCat",
						["shidai1"] = "set:CutePet01 image:CutePet01_CutePetGeneration01",
						["shidai2"] = "set:CutePet01 image:CutePet01_CutePetGeneration02",
						["PinZhi1"] = "set:CutePet01 image:CutePet01_CutePetPage1",
						["PinZhi2"] = "set:CutePet01 image:CutePet01_CutePetPage2",
						["PinZhi3"] = "set:CutePet01 image:CutePet01_CutePetPage3",
						["DiTu1"] = "set:CutePet01 image:CutePet01_CutePetCardGreen",
						["DiTu2"] = "set:CutePet01 image:CutePet01_CutePetCardBlue",
						["DiTu3"] = "set:CutePet01 image:CutePet01_CutePetCardPurple",
						["jihuo"] = "set:CutePet01 image:CutePet01_CutePetBlank",
						["weijihuo"] = "set:CutePet01 image:CutePet01_CutePetLocked",
}
local g_Stage = {
	["YouNian"] = "幼年",
	["ChengNian"] = "成年",
}

local g_WuZhong = {
	[1] = "宠物猫",
	[2]= "奇珍宠",
}

--===============================================
-- OnLoad()
--===============================================
function BieYeCutePetBank_PreLoad()
	this:RegisterEvent("BIEYE_OPEN_MENGCHONG_BANK")
	this:RegisterEvent("BIEYE_OPEN_MINI")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("BIEYE_UPDATE_MENGCHONG_BANK")
	this:RegisterEvent("CUTEPETNESTHIDE")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	this:RegisterEvent("UI_COMMAND")
end

function BieYeCutePetBank_OnLoad()

	ActionButtonLine1[1] = BieYeCutePetBank_Item_LineOneA;
	ActionButtonLine1[2] = BieYeCutePetBank_Item_LineOneB;
	ActionButtonLine1[3] = BieYeCutePetBank_Item_LineOneC;
	ActionButtonLine1[4] = BieYeCutePetBank_Item_LineOneD;
	ActionButtonLine1[5] = BieYeCutePetBank_Item_LineOneE;
	ActionButtonLine1[6] = BieYeCutePetBank_Item_LineOneF;


	GRID_BUTTONSLine1[1]  = BieYeCutePetBank_Item_LineOneA_Mask;
	GRID_BUTTONSLine1[2]  = BieYeCutePetBank_Item_LineOneB_Mask;
	GRID_BUTTONSLine1[3]  = BieYeCutePetBank_Item_LineOneC_Mask;
	GRID_BUTTONSLine1[4]  = BieYeCutePetBank_Item_LineOneD_Mask;
	GRID_BUTTONSLine1[5]  = BieYeCutePetBank_Item_LineOneE_Mask;
	GRID_BUTTONSLine1[6]  = BieYeCutePetBank_Item_LineOneF_Mask;





	ActionButtonLine2[1] = BieYeCutePetBank_Item_LineTwoA;
	ActionButtonLine2[2] = BieYeCutePetBank_Item_LineTwoB;
	ActionButtonLine2[3] = BieYeCutePetBank_Item_LineTwoC;
	ActionButtonLine2[4] = BieYeCutePetBank_Item_LineTwoD;
	ActionButtonLine2[5] = BieYeCutePetBank_Item_LineTwoE;
	ActionButtonLine2[6] = BieYeCutePetBank_Item_LineTwoF;

	GRID_BUTTONSLine2[1]  = BieYeCutePetBank_Item_LineTwoA_Mask;
	GRID_BUTTONSLine2[2]  = BieYeCutePetBank_Item_LineTwoB_Mask;
	GRID_BUTTONSLine2[3]  = BieYeCutePetBank_Item_LineTwoC_Mask;
	GRID_BUTTONSLine2[4]  = BieYeCutePetBank_Item_LineTwoD_Mask;
	GRID_BUTTONSLine2[5]  = BieYeCutePetBank_Item_LineTwoE_Mask;
	GRID_BUTTONSLine2[6]  = BieYeCutePetBank_Item_LineTwoF_Mask;



	ActionButtonLine3[1] = BieYeCutePetBank_Item_LineThreeA;
	ActionButtonLine3[2] = BieYeCutePetBank_Item_LineThreeB;
	ActionButtonLine3[3] = BieYeCutePetBank_Item_LineThreeC;
	ActionButtonLine3[4] = BieYeCutePetBank_Item_LineThreeD;
	ActionButtonLine3[5] = BieYeCutePetBank_Item_LineThreeE;
	ActionButtonLine3[6] = BieYeCutePetBank_Item_LineThreeF;


	GRID_BUTTONSLine3[1]  = BieYeCutePetBank_Item_LineThreeA_Mask;
	GRID_BUTTONSLine3[2]  = BieYeCutePetBank_Item_LineThreeB_Mask;
	GRID_BUTTONSLine3[3]  = BieYeCutePetBank_Item_LineThreeC_Mask;
	GRID_BUTTONSLine3[4]  = BieYeCutePetBank_Item_LineThreeD_Mask;
	GRID_BUTTONSLine3[5]  = BieYeCutePetBank_Item_LineThreeE_Mask;
	GRID_BUTTONSLine3[6]  = BieYeCutePetBank_Item_LineThreeF_Mask;



	ActionButtonSp[1] = BieYeCutePetBank_Item_SPLineOneA
	ActionButtonSp[2] = BieYeCutePetBank_Item_SPLineOneB
	ActionButtonSp[3] = BieYeCutePetBank_Item_SPLineOneC
	ActionButtonSp[4] = BieYeCutePetBank_Item_SPLineOneD
	ActionButtonSp[5] = BieYeCutePetBank_Item_SPLineOneE
	ActionButtonSp[6] = BieYeCutePetBank_Item_SPLineOneF
	ActionButtonSp[7] = BieYeCutePetBank_Item_SPLineOneG
	ActionButtonSp[8] = BieYeCutePetBank_Item_SPLineOneH
	ActionButtonSp[9] = BieYeCutePetBank_Item_SPLineTwoA
	ActionButtonSp[10] = BieYeCutePetBank_Item_SPLineTwoB
	ActionButtonSp[11] = BieYeCutePetBank_Item_SPLineTwoC
	ActionButtonSp[12] = BieYeCutePetBank_Item_SPLineTwoD
	ActionButtonSp[13] = BieYeCutePetBank_Item_SPLineTwoE
	ActionButtonSp[14] = BieYeCutePetBank_Item_SPLineTwoF
	ActionButtonSp[15] = BieYeCutePetBank_Item_SPLineTwoG
	ActionButtonSp[16] = BieYeCutePetBank_Item_SPLineTwoH
	ActionButtonSp[17] = BieYeCutePetBank_Item_SPLineThreeA
	ActionButtonSp[18] = BieYeCutePetBank_Item_SPLineThreeB
	ActionButtonSp[19] = BieYeCutePetBank_Item_SPLineThreeC
	ActionButtonSp[20] = BieYeCutePetBank_Item_SPLineThreeD
	ActionButtonSp[21] = BieYeCutePetBank_Item_SPLineThreeE
	ActionButtonSp[22] = BieYeCutePetBank_Item_SPLineThreeF
	ActionButtonSp[23] = BieYeCutePetBank_Item_SPLineThreeG
	ActionButtonSp[24] = BieYeCutePetBank_Item_SPLineThreeH

	GRID_BUTTONSLineSP[1]  = BieYeCutePetBank_Item_SPLineOneA_Mask;
	GRID_BUTTONSLineSP[2]  = BieYeCutePetBank_Item_SPLineOneB_Mask;
	GRID_BUTTONSLineSP[3]  = BieYeCutePetBank_Item_SPLineOneC_Mask;
	GRID_BUTTONSLineSP[4]  = BieYeCutePetBank_Item_SPLineOneD_Mask;
	GRID_BUTTONSLineSP[5]  = BieYeCutePetBank_Item_SPLineOneE_Mask;
	GRID_BUTTONSLineSP[6]  = BieYeCutePetBank_Item_SPLineOneF_Mask;
	GRID_BUTTONSLineSP[7]  = BieYeCutePetBank_Item_SPLineOneG_Mask;
	GRID_BUTTONSLineSP[8]  = BieYeCutePetBank_Item_SPLineOneH_Mask;
	GRID_BUTTONSLineSP[9]  = BieYeCutePetBank_Item_SPLineTwoA_Mask;
	GRID_BUTTONSLineSP[10]  = BieYeCutePetBank_Item_SPLineTwoB_Mask;
	GRID_BUTTONSLineSP[11]  = BieYeCutePetBank_Item_SPLineTwoC_Mask;
	GRID_BUTTONSLineSP[12]  = BieYeCutePetBank_Item_SPLineTwoD_Mask;
	GRID_BUTTONSLineSP[13]  = BieYeCutePetBank_Item_SPLineTwoE_Mask;
	GRID_BUTTONSLineSP[14]  = BieYeCutePetBank_Item_SPLineTwoF_Mask;
	GRID_BUTTONSLineSP[15]  = BieYeCutePetBank_Item_SPLineTwoG_Mask;
	GRID_BUTTONSLineSP[16]  = BieYeCutePetBank_Item_SPLineTwoH_Mask;
	GRID_BUTTONSLineSP[17]  = BieYeCutePetBank_Item_SPLineThreeA_Mask;
	GRID_BUTTONSLineSP[18]  = BieYeCutePetBank_Item_SPLineThreeB_Mask;
	GRID_BUTTONSLineSP[19]  = BieYeCutePetBank_Item_SPLineThreeC_Mask;
	GRID_BUTTONSLineSP[20]  = BieYeCutePetBank_Item_SPLineThreeD_Mask;
	GRID_BUTTONSLineSP[21]  = BieYeCutePetBank_Item_SPLineThreeE_Mask;
	GRID_BUTTONSLineSP[22]  = BieYeCutePetBank_Item_SPLineThreeF_Mask;
	GRID_BUTTONSLineSP[23]  = BieYeCutePetBank_Item_SPLineThreeG_Mask;
	GRID_BUTTONSLineSP[24]  = BieYeCutePetBank_Item_SPLineThreeH_Mask;

	g_index1 = -1
	g_index2 = -1
	g_index3 = -1
	g_indexSP = -1
	g_BieYeCutePetBank_Frame_UnifiedPosition=BieYeCutePetBank_Frame:GetProperty("UnifiedPosition");
	BieYeCutePetBank_SaveBank_Animate:Hide()
	BieYeCutePetBank_PutInNest_Animate:Hide()
	BieYeCutePetBank_TakeOutBag_Animate:Hide()
	BieYeCutePetBank_Item_LineZeroB_Animate:Hide()


end


--===============================================
-- OnEvent
--===============================================
function BieYeCutePetBank_OnEvent(event)

	if(event == "BIEYE_OPEN_MENGCHONG_BANK") then


			--------------是否有操作权限
			local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
			local myGuid = Player:GetGUID();
				--婚姻组
			local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()

			local bIsMyBieye = 0
			if isHaveSpouse == 1 then
				if BieYeGuid == myGuid then
					bIsMyBieye = 1
				elseif BieYeGuid == spouseGuid then
					bIsMyBieye = 2
				else
					return
				end
			end
			--------------是否有操作权限


			if(IsWindowShow("YouLongKa2")) then
			  CloseWindow("YouLongKa2", true);
			end
			if(IsWindowShow("Bank")) then
			  CloseWindow("Bank", true);
			end
			if(IsWindowShow("BigBank")) then
			  CloseWindow("BigBank", true);
			end
			if(IsWindowShow("BieYeBank")) then
			  CloseWindow("BieYeBank", true);
			end
			if(IsWindowShow("BieYeFurnitureTransfer"))then
				CloseWindow("BieYeFurnitureTransfer", true);
			end


			BieYeMengChong:AcquireList(1,0);
			g_MengChongCurrentPage = 1
			g_index1 = -1
			g_index2 = -1
			g_index3 = -1
			g_indexSP = -1
			BieYeCutePetBank_FenYe1:SetCheck(1)
			BieYeCutePetBank_FenYe_SP:SetCheck(0)
			BieYeCutePetBank_FenYe_SP:SetProperty("Selected", "False");


			--家园萌宠引导任务浮动tips显示逻辑
			if BieYeGuid == myGuid then
				if DataPool:Lua_IsHaveMission(1871) > 0  then
					local misIndex = DataPool:GetPlayerMissionIndexByID(1871)
					if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 then
						if DataPool:GetPlayerMission_Variable(misIndex, 1) < 1 then
							CloseFreshManGuide()
							local fX, fY = this:GetChildOffset("BieYeCutePetBank_SaveBank")
							OpenFreshManGuide(1, 181, fX+10, fY+10, "BieYeCutePetBank", "northwest")
							BieYeCutePetBank_SaveBank_Animate:Show()
						elseif DataPool:GetPlayerMission_Variable(misIndex, 2) < 1 then
							CloseFreshManGuide()
							local fX, fY = this:GetChildOffset("BieYeCutePetBank_PutInNest")
							OpenFreshManGuide(1, 182, fX+10, fY+10, "BieYeCutePetBank", "northwest")
							BieYeCutePetBank_PutInNest_Animate:Show()
						end
					end

				end

			--	if DataPool:Lua_IsHaveMission(1889) > 0  then
			--		local misIndex = DataPool:GetPlayerMissionIndexByID(1889)
			--		if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 and  DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
			--			CloseFreshManGuide()
			--			local fX, fY = this:GetChildOffset("BieYeCutePetBank_Item_LineZeroB")
			--			OpenFreshManGuide(1, 221, fX+10, fY+10, "BieYeCutePetBank", "northwest")
			--			BieYeCutePetBank_Item_LineZeroB_Animate:Show()
			--		end
			--	end
			end

			BieYeCutePetBank_UpdateFrame(0)
			this:Show()

	elseif (event == "CUTEPETNESTHIDE") then
			BieYeCutePetBank_OnHiden()
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then

		local nType = tonumber(Get_XParam_INT(0))
		if nType == 30 then --打开界面
			BieYeCutePetBank_OnHiden()
		end
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeCutePetBank_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeCutePetBank_Frame_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		g_MengChongCurrentPage = 1
		this:Hide()

	elseif (event == "BIEYE_UPDATE_MENGCHONG_BANK") then
		local bIsOnlyMengChongXiaoWo = tonumber(arg0)
		local bAddMengChongTableIndex = tonumber(arg1)

		if bIsOnlyMengChongXiaoWo ~= 1 then
			BieYeCutePetBank_UpdateFrame(0)
		end
		if bIsOnlyMengChongXiaoWo == 2 then --存放萌宠 需要弹出本界面
			--Lua_TDU_Log("--BIEYE_UPDATE_MENGCHONG_BANK This Show:")
			local bAddMengChongTableIndex = tonumber(arg1)
			local nMengChongStyle =  BieYeMengChong:GetBieYeMengChongInfo(bAddMengChongTableIndex,14)
			BieYeCutePetBank_MengChongAddFreshBefore_CAT(bAddMengChongTableIndex)
			BieYeCutePetBank_UpdateFrame(0)
			BieYeCutePetBank_MengChongAddFreshAfter_CAT(bAddMengChongTableIndex)
			this:Show()
		end
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 892510002 then
		CloseFreshManGuide()
		local fX, fY = this:GetChildOffset("BieYeCutePetBank_PutInNest")
		OpenFreshManGuide(1, 182, fX+10, fY+10, "BieYeCutePetBank", "northwest")
		BieYeCutePetBank_PutInNest_Animate:Show()

	elseif (event == "UI_COMMAND") and tonumber(arg0) == 892512002 then
		CloseFreshManGuide()
		local nType = Get_XParam_INT(0)
		local fX, fY = this:GetChildOffset("BieYeCutePetBank_TakeOutBag")
		OpenFreshManGuide(1, 187, fX+10, fY+10, "BieYeCutePetBank", "northwest")

	elseif (event == "UI_COMMAND") and tonumber(arg0) == 892513002 then
		CloseFreshManGuide()
		local fX, fY = this:GetChildOffset("BieYeCutePetBank_TakeOutBag")
		OpenFreshManGuide(1, 222, fX+10, fY+10, "BieYeCutePetBank", "northwest")
		BieYeCutePetBank_TakeOutBag_Animate:Show()
	end

end
--===============================================
-- BieYeCutePetBank_UpdateFrame
--===============================================
function BieYeCutePetBank_UpdateFrame(bIsOnlyMengChongXiaoWo)

	if g_MengChongCurrentPage == 2 then
		BieYeCutePetBank_SetSPVisible(1)
	else
		BieYeCutePetBank_SetSPVisible(0)
	end

	local nCount = BieYeMengChong:GetBieYeMengChongCurCount()
	local nCountLimit = BieYeMengChong:GetBieYeMengChongLimitByBieYeLevel()
	nCountLimit = nCountLimit


	local nMengChongCount = BieYeMengChong:GetBieYeMengChongTypeSize(g_MengChongCurrentPage)
	local Text = ScriptGlobal_Format("#{MCJC_170727_47}",g_WuZhong[g_MengChongCurrentPage], nMengChongCount,nCountLimit)
	BieYeCutePetBank_Allnumber:SetText(Text)
	BieYeCutePetBank_TakeOutBag:SetToolTip("#{MCJC_170727_53}")
	local Text_wuzhong = ScriptGlobal_Format("#{MCJC_170727_115}",g_WuZhong[g_MengChongCurrentPage], nMengChongCount)
	--local Text_DOG = ScriptGlobal_Format("#{MCJC_170727_115}",g_WuZhong["ChongWuGou"], nMengChongCount_DOG)
	BieYeCutePetBank_TakeOutBag:SetProperty("Disabled","true")
	--BieYeCutePetBank_Allnumber:SetToolTip(Text_wuzhong.."\n"..Text_DOG)
	BieYeCutePetBank_Allnumber:SetToolTip(Text_wuzhong)
	BieYeCutePetBank_TakeOutBag:SetToolTip("#{MCJC_170727_53}")
	BieYeCutePetBank_FreePet:SetToolTip("#{MCJC_170727_66}")

	local MengChongOutNum = BieYeMengChong:GetBieYeXiaoWoCount()
	local Allnumber_XiaoWo_limit = BieYeMengChong:GetBieYePutMengChongLimitByBieYeLevel()
	local text1 = ScriptGlobal_Format("#{MCJC_170727_131}",MengChongOutNum,Allnumber_XiaoWo_limit)
    BieYeCutePetBank_OutNumText:SetText(text1)
	if bIsOnlyMengChongXiaoWo == 0 then
		if g_MengChongCurrentPage ~= 2 then   -- 如果目前的页签 不是特殊页签
			if g_index1 > 0 then
				local index1 = g_MengChongindexChoose[1][g_index1]
				if index1 >= 0 and BieYeMengChong:BieYeMengChong_isHaveItem(index1) <= 0 then
				   g_index1 = -1
				elseif index1 >= 0 and  BieYeMengChong:BieYeMengChong_isHaveItem(index1) > 0 and BieYeMengChong:Lua_CanGetOut(index1) == 1 then
					BieYeCutePetBank_TakeOutBag:SetProperty("Disabled","false")
				end
			end

			if g_index2 > 0 then
				local index2 = g_MengChongindexChoose[2][g_index2]
				if index2 >= 0 and BieYeMengChong:BieYeMengChong_isHaveItem(index2) <= 0 then
				   g_index2 = -1
				elseif index2 >= 0 and  BieYeMengChong:BieYeMengChong_isHaveItem(index2) > 0  and BieYeMengChong:Lua_CanGetOut(index2) == 1 then
					BieYeCutePetBank_TakeOutBag:SetProperty("Disabled","false")
				end
			end

			if g_index3 > 0 then
				local index3 = g_MengChongindexChoose[3][g_index3]
				if index3 >= 0 and BieYeMengChong:BieYeMengChong_isHaveItem(index3) <= 0 then
				   g_index3 = -1
				elseif index3 >= 0 and  BieYeMengChong:BieYeMengChong_isHaveItem(index3) > 0  and BieYeMengChong:Lua_CanGetOut(index3) == 1 then
					BieYeCutePetBank_TakeOutBag:SetProperty("Disabled","false")
				end
			end

			for i=1, GRID_BUTTONS_NUM do
				ActionButtonLine1[i]:SetActionItem(-1);
				ActionButtonLine1[i]:Enable();
				if g_index1 ~= i then			--如果界面不关闭，点选之后可以连续操作
					ActionButtonLine1[i]:SetPushed(0)
				end
			end
			for i=1, GRID_BUTTONS_NUM do
				ActionButtonLine2[i]:SetActionItem(-1);
				ActionButtonLine2[i]:Enable();
				if g_index2 ~= i then			--如果界面不关闭，点选之后可以连续操作
					ActionButtonLine2[i]:SetPushed(0)
				end
			end
			for i=1, GRID_BUTTONS_NUM do
				ActionButtonLine3[i]:SetActionItem(-1);
				ActionButtonLine3[i]:Enable();
				if g_index3 ~= i then			--如果界面不关闭，点选之后可以连续操作
					ActionButtonLine3[i]:SetPushed(0)
				end
			end


			for i=1, GRID_BUTTONS_SP_NUM * 3 do
				ActionButtonSp[i]:SetActionItem(-1);
				ActionButtonSp[i]:Enable();
				ActionButtonSp[i]:SetPushed(0)
			end

		else --如果是特殊页签
			if g_indexSP > 0 then
				local index = g_MengChongindexChooseSP[g_indexSP]
				if index >= 0 and BieYeMengChong:BieYeMengChong_isHaveItem(index) <= 0 then
				   index = -1
				elseif index >= 0 and  BieYeMengChong:BieYeMengChong_isHaveItem(index) > 0 and BieYeMengChong:Lua_CanGetOut(index) == 1 then
					BieYeCutePetBank_TakeOutBag:SetProperty("Disabled","false")
				end
			end

			for i=1, GRID_BUTTONS_NUM do
				ActionButtonLine1[i]:SetActionItem(-1);
				ActionButtonLine1[i]:Enable();
				ActionButtonLine1[i]:SetPushed(0)
			end
			for i=1, GRID_BUTTONS_NUM do
				ActionButtonLine2[i]:SetActionItem(-1);
				ActionButtonLine2[i]:Enable();
				ActionButtonLine2[i]:SetPushed(0)
			end
			for i=1, GRID_BUTTONS_NUM do
				ActionButtonLine3[i]:SetActionItem(-1);
				ActionButtonLine3[i]:Enable();
				ActionButtonLine3[i]:SetPushed(0)
			end


			for i=1, GRID_BUTTONS_SP_NUM* 3 do
				ActionButtonSp[i]:SetActionItem(-1);
				ActionButtonSp[i]:Enable();
				if g_indexSP ~= i then			--如果界面不关闭，点选之后可以连续操作
					ActionButtonSp[i]:SetPushed(0)
				end
			end

		end

		BieYeCutePetBank_RightOrLeftButtonFresh(1,-1)

		BieYeCutePetBank_Fresh_ActionButton()

	end

end

--===============================================
-- 点击关闭
--===============================================
function BieYeCutePetBank_Close_Clicked()
	CloseFreshManGuide()
	this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeCutePetBank_Frame_On_ResetPos()
  BieYeCutePetBank_Frame:SetProperty("UnifiedPosition", g_BieYeCutePetBank_Frame_UnifiedPosition);
end


function BieYeCutePetBank_ItemBtnSubClicked( nLine,nRow )


	local nIndex = nRow;
	if( nIndex < 1 ) then
		return;
	end

	for i=1, GRID_BUTTONS_NUM do

		ActionButtonLine1[i]:SetPushed(0);
		ActionButtonLine2[i]:SetPushed(0);
		ActionButtonLine3[i]:SetPushed(0);

	end

	for i=1, GRID_BUTTONS_SP_NUM do

		ActionButtonSp[i] :SetPushed(0);
		ActionButtonSp[i + 8] :SetPushed(0);
		ActionButtonSp[i + 16] :SetPushed(0);

	end

	local index
	if nLine == 1 then
		g_index1 = nIndex
		g_index2 = -1
		g_index3 = -1
		index = g_MengChongindexChoose[nLine][g_index1]
		ActionButtonLine1[g_index1]:DoSubAction()

		if BieYeMengChong:BieYeMengChong_isHaveItem(index) <= 0 then
			g_index1 = -1
		else
			--ActionButtonLine1[g_index1]:SetPushed(1);
		end
	elseif nLine == 2 then
		g_index2 = nIndex
		g_index1 = -1
		g_index3 = -1
		index = g_MengChongindexChoose[nLine][g_index2]
		ActionButtonLine2[g_index2]:DoSubAction()

		if BieYeMengChong:BieYeMengChong_isHaveItem(index) <= 0 then
			g_index2 = -1
		else
			--ActionButtonLine2[g_index2]:SetPushed(1);
		end
	elseif nLine == 3 then
		g_index3 = nIndex
		g_index1 = -1
		g_index2 = -1
		index = g_MengChongindexChoose[nLine][g_index3]
		ActionButtonLine3[g_index3]:DoSubAction()

		if BieYeMengChong:BieYeMengChong_isHaveItem(index) <= 0 then
			g_index3 = -1
		else
			--ActionButtonLine3[g_index3]:SetPushed(1);
		end
	elseif nLine == 4 then
		g_index3 = -1
		g_index1 = -1
		g_index2 = -1
		g_indexSP = nIndex
		index = g_MengChongindexChooseSP[g_indexSP]
		ActionButtonSp[g_indexSP]:DoSubAction()

		if BieYeMengChong:BieYeMengChong_isHaveItem(index) <= 0 then
			g_indexSP = -1
		else
			--ActionButtonSp[g_indexSP]:SetPushed(1);
		end
	end


	if BieYeMengChong:Lua_CanGetOut(index) == 1 then
		BieYeCutePetBank_TakeOutBag:SetProperty("Disabled","False")
	else
		BieYeCutePetBank_TakeOutBag:SetProperty("Disabled","True")
	end

	if  nLine == 0 and nRow == 2 then
	--	CloseFreshManGuide()
	--	BieYeCutePetBank_Item_LineZeroB_Animate:Hide()
	--	if DataPool:Lua_IsHaveMission(1889) > 0  then
	--		local misIndex = DataPool:GetPlayerMissionIndexByID(1889)
	--		if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 and DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
	--			PushEvent("UI_COMMAND", 892513002)
	--		end
	--	end
	end

end


function BieYeCutePetBank_OnHiden()

	BieYeCutePetBank_Close_Clicked()

end

--//////////////////////////////////////////
-- 页码验证
--//////////////////////////////////////////


function BieYeCutePetBank_Left_Clicked1()

	if g_MengChong_LR_Page1 > 1 then
		g_MengChong_LR_Page1 = g_MengChong_LR_Page1 - 1
		BieYeCutePetBank_Fresh_ActionButton()
	end



	BieYeCutePetBank_RightOrLeftButtonFresh(0,1)

end
function BieYeCutePetBank_Left_Clicked2()

	if g_MengChongCurrentPage > 1 then
		g_MengChongCurrentPage = g_MengChongCurrentPage - 1
		BieYeCutePetBank_Fresh_ActionButton()
	end



	BieYeCutePetBank_RightOrLeftButtonFresh(0,2)

end
function BieYeCutePetBank_Left_Clicked3()

	if g_MengChongCurrentPage > 1 then
		g_MengChongCurrentPage = g_MengChongCurrentPage - 1
		BieYeCutePetBank_Fresh_ActionButton()
	end



	BieYeCutePetBank_RightOrLeftButtonFresh(0,3)

end
function BieYeCutePetBank_Right_Clicked1()


		local nMengChongCount = BieYeMengChong:GetBieYeMengChongTypeCount(g_MengChongCurrentPage,1)

		local nPct = math.ceil(nMengChongCount / GRID_BUTTONS_NUM)

		if g_MengChong_LR_Page1 < nPct then
			g_MengChong_LR_Page1 = g_MengChong_LR_Page1 + 1
			BieYeCutePetBank_Fresh_ActionButton()
		end

		BieYeCutePetBank_RightOrLeftButtonFresh(0,1)

end
function BieYeCutePetBank_Right_Clicked2()


		local nMengChongCount = BieYeMengChong:GetBieYeMengChongTypeCount(g_MengChongCurrentPage,2)

		local nPct = math.ceil(nMengChongCount / GRID_BUTTONS_NUM)

		if g_MengChong_LR_Page2 < nPct then
			g_MengChong_LR_Page2 = g_MengChong_LR_Page2 + 1
			BieYeCutePetBank_Fresh_ActionButton()
		end

		BieYeCutePetBank_RightOrLeftButtonFresh(0,2)

end
function BieYeCutePetBank_Right_Clicked3()


		local nMengChongCount = BieYeMengChong:GetBieYeMengChongTypeCount(g_MengChongCurrentPage,3)

		local nPct = math.ceil(nMengChongCount / GRID_BUTTONS_NUM)

		if g_MengChong_LR_Page3 < nPct then
			g_MengChong_LR_Page3 = g_MengChong_LR_Page3 + 1
			BieYeCutePetBank_Fresh_ActionButton()
		end

		BieYeCutePetBank_RightOrLeftButtonFresh(0,3)

end
function BieYeCutePetBank_Fresh_ActionButton()


		if g_MengChongCurrentPage ~= 2 then   -- 如果目前的页签 不是特殊页签
			for i=1,  GRID_BUTTONS_NUM do
				local nTypeFirstIndex1 =  BieYeMengChong:GetBieYeMengChongFirstIndexByType( g_MengChongCurrentPage , 1)
				local nTypeLastIndex1 =  BieYeMengChong:GetBieYeMengChongLastIndexByType( g_MengChongCurrentPage , 1 )
				local nActVerifyIndex1 = ( g_MengChong_LR_Page1 - 1 ) * GRID_BUTTONS_NUM + nTypeFirstIndex1 + i - 1 --当前类型的起始位置加上偏移量i，加上当前类型的页数,i的起始值为1，所以减去个1
				local nActVerifyLastIndex1 = nTypeLastIndex1

				if nActVerifyIndex1 >= 0 and nActVerifyIndex1 <= nActVerifyLastIndex1 then
					--比最大内存小
					--PushDebugMessage("nActVerifyIndex1="..nActVerifyIndex1.." nActVerifyLastIndex1="..nActVerifyLastIndex1.." nTypeFirstIndex1="..nTypeFirstIndex1.." nTypeLastIndex1="..nTypeLastIndex1)
					--return

					local theAction = BieYeMengChong:EnumItem( nActVerifyIndex1 );

					local nNum  = BieYeMengChong:GetNum( nActVerifyIndex1 );

					if theAction:GetID() ~= 0 then
						g_MengChongindexChoose[1][i] = nActVerifyIndex1
						ActionButtonLine1[i]:SetActionItem(theAction:GetID());
						if nNum > 0 then
							GRID_BUTTONSLine1[i]:SetProperty("Visible","false")
						else
							GRID_BUTTONSLine1[i]:SetProperty("Visible","true")
						end
					else
						ActionButtonLine1[i]:SetActionItem(-1);
						GRID_BUTTONSLine1[i]:SetProperty("Visible","false")
						g_MengChongindexChoose[1][i] = -1
					end
				else
					ActionButtonLine1[i]:SetActionItem(-1);
					GRID_BUTTONSLine1[i]:SetProperty("Visible","false")
					g_MengChongindexChoose[1][i] = -1
				end


				local nTypeFirstIndex2 =  BieYeMengChong:GetBieYeMengChongFirstIndexByType( g_MengChongCurrentPage , 2)
				local nTypeLastIndex2 =  BieYeMengChong:GetBieYeMengChongLastIndexByType( g_MengChongCurrentPage , 2 )
				local nActVerifyIndex2 = ( g_MengChong_LR_Page2 - 1 ) * GRID_BUTTONS_NUM + nTypeFirstIndex2 + i - 1 --当前类型的起始位置加上偏移量i，加上当前类型的页数,i的起始值为1，所以减去个1
				local nActVerifyLastIndex2 = nTypeLastIndex2

				if nActVerifyIndex2 >= 0 and nActVerifyIndex2 <= nActVerifyLastIndex2 then
					--比最大内存小

					--PushDebugMessage("nActVerifyIndex2="..nActVerifyIndex2.." nActVerifyLastIndex2="..nActVerifyLastIndex2.." nTypeLastIndex2="..nTypeLastIndex2)
					--return

					local theAction = BieYeMengChong:EnumItem( nActVerifyIndex2 );

					local nNum2  = BieYeMengChong:GetNum( nActVerifyIndex2 );

					if theAction:GetID() ~= 0 then
						g_MengChongindexChoose[2][i] = nActVerifyIndex2
						ActionButtonLine2[i]:SetActionItem(theAction:GetID());
						if nNum2 > 0 then
							GRID_BUTTONSLine2[i]:SetProperty("Visible","false")
						else
							GRID_BUTTONSLine2[i]:SetProperty("Visible","true")
						end
					else
						ActionButtonLine2[i]:SetActionItem(-1);
						GRID_BUTTONSLine2[i]:SetProperty("Visible","false")
						g_MengChongindexChoose[2][i] = -1
					end
				else
					ActionButtonLine2[i]:SetActionItem(-1);
					GRID_BUTTONSLine2[i]:SetProperty("Visible","false")
					g_MengChongindexChoose[2][i] = -1
				end





				local nTypeFirstIndex3 =  BieYeMengChong:GetBieYeMengChongFirstIndexByType( g_MengChongCurrentPage , 3)
				local nTypeLastIndex3 =  BieYeMengChong:GetBieYeMengChongLastIndexByType( g_MengChongCurrentPage , 3 )
				local nActVerifyIndex3 = ( g_MengChong_LR_Page3 - 1 ) * GRID_BUTTONS_NUM + nTypeFirstIndex3 + i - 1 --当前类型的起始位置加上偏移量i，加上当前类型的页数,i的起始值为1，所以减去个1
				local nActVerifyLastIndex3 = nTypeLastIndex3

				if nActVerifyIndex3 >= 0 and nActVerifyIndex3 <= nActVerifyLastIndex3 then
					--比最大内存小
					--PushDebugMessage("nActVerifyIndex1="..nActVerifyIndex1.." nActVerifyLastIndex3="..nActVerifyLastIndex3.." nTypeFirstIndex_CAT="..nTypeFirstIndex_CAT.." nTypeLastIndex_CAT="..nTypeLastIndex_CAT)
					--return

					local theAction = BieYeMengChong:EnumItem( nActVerifyIndex3 );

					local nNum3  = BieYeMengChong:GetNum( nActVerifyIndex3 );

					if theAction:GetID() ~= 0 then
						g_MengChongindexChoose[3][i] = nActVerifyIndex3
						ActionButtonLine3[i]:SetActionItem(theAction:GetID());
						if nNum3 > 0 then
							GRID_BUTTONSLine3[i]:SetProperty("Visible","false")
						else
							GRID_BUTTONSLine3[i]:SetProperty("Visible","true")
						end
					else
						ActionButtonLine3[i]:SetActionItem(-1);
						GRID_BUTTONSLine3[i]:SetProperty("Visible","false")
						g_MengChongindexChoose[3][i] = -1
					end
				else
					ActionButtonLine3[i]:SetActionItem(-1);
					GRID_BUTTONSLine3[i]:SetProperty("Visible","false")
					g_MengChongindexChoose[3][i] = -1
				end


				if g_index1 == i then
					--ActionButtonLine1[i]:SetPushed(1)
				end

				if g_index2 == i then
					--ActionButtonLine2[i]:SetPushed(1)
				end

				if g_index3 == i then
					--ActionButtonLine3[i]:SetPushed(1)
				end


			end
		else   -- 如果是特殊页签
			for i=1,  GRID_BUTTONS_SP_NUM * 3 do
				local nTypeFirstIndexSP =  BieYeMengChong:GetBieYeMengChongFirstIndexByType( g_MengChongCurrentPage , 3)
				local nTypeLastIndexSP =  BieYeMengChong:GetBieYeMengChongLastIndexByType( g_MengChongCurrentPage , 3 )
				local nActVerifyIndexSP = ( g_MengChong_LR_PageSP - 1 ) * GRID_BUTTONS_SP_NUM + nTypeFirstIndexSP + i - 1 --当前类型的起始位置加上偏移量i，加上当前类型的页数,i的起始值为1，所以减去个1
				local nActVerifyLastIndexSP = nTypeLastIndexSP

				if nActVerifyIndexSP >= 0 and nActVerifyIndexSP <= nActVerifyLastIndexSP then
					--比最大内存小
					--PushDebugMessage("g_MengChongCurrentPage="..g_MengChongCurrentPage.."nActVerifyIndexSP="..nActVerifyIndexSP.." nActVerifyLastIndexSP="..nActVerifyLastIndexSP.." nTypeFirstIndexSP="..nTypeFirstIndexSP.." nTypeLastIndexSP="..nTypeLastIndexSP)
					--return

					local theAction = BieYeMengChong:EnumItem( nActVerifyIndexSP );

					local nNum  = BieYeMengChong:GetNum( nActVerifyIndexSP );

					if theAction:GetID() ~= 0 then
						g_MengChongindexChooseSP[i] = nActVerifyIndexSP
						ActionButtonSp[i]:SetActionItem(theAction:GetID());
						if nNum > 0 then
							GRID_BUTTONSLineSP[i]:SetProperty("Visible","false")
						else
							GRID_BUTTONSLineSP[i]:SetProperty("Visible","true")
						end
					else
						ActionButtonSp[i]:SetActionItem(-1);
						GRID_BUTTONSLineSP[i]:SetProperty("Visible","false")
						g_MengChongindexChooseSP[i] = -1
					end
				else
					ActionButtonSp[i]:SetActionItem(-1);
					GRID_BUTTONSLineSP[i]:SetProperty("Visible","false")
					g_MengChongindexChooseSP[i] = -1
				end

				if g_indexSP == i then
					--ActionButtonSp[i]:SetPushed(1)
				end

			end
		end


end


function BieYeCutePetBank_RightOrLeftButtonFresh(bIsUpdate,Line)


	if g_MengChongCurrentPage ~= 2 then   -- 如果目前的页签 不是特殊页签
		if bIsUpdate == 0 then
			if Line == 1 then
				g_index1 = -1
				for i=1, GRID_BUTTONS_NUM do
					ActionButtonLine1[i]:SetPushed(0);
				end
			elseif Line == 2 then
				g_index2 = -1
				for i=1, GRID_BUTTONS_NUM do
					ActionButtonLine2[i]:SetPushed(0);
				end
			elseif Line == 3 then
				g_index3 = -1
				for i=1, GRID_BUTTONS_NUM do
					ActionButtonLine3[i]:SetPushed(0);
				end
			end

			if g_index1 < 0 and g_index2 < 0 and g_index3 < 0 then
				BieYeCutePetBank_TakeOutBag:SetProperty("Disabled","true")
			end

		end


		local nMengChongCount_1 = BieYeMengChong:GetBieYeMengChongTypeCount(g_MengChongCurrentPage,1)
		local nPct1 = math.ceil(nMengChongCount_1 / GRID_BUTTONS_NUM)

		if  nPct1 <= 1  then
			BieYeCutePetBank_Item_LineOne_LeftPass:SetProperty("Visible","false")
			BieYeCutePetBank_Item_LineOne_RightPass:SetProperty("Visible","false")
		elseif  g_MengChong_LR_Page1 <=1 then
			BieYeCutePetBank_Item_LineOne_LeftPass:SetProperty("Visible","false")
			BieYeCutePetBank_Item_LineOne_RightPass:SetProperty("Visible","true")

		elseif  g_MengChong_LR_Page1 >= nPct1 then
			BieYeCutePetBank_Item_LineOne_LeftPass:SetProperty("Visible","true")
			BieYeCutePetBank_Item_LineOne_RightPass:SetProperty("Visible","false")
		else
			BieYeCutePetBank_Item_LineOne_LeftPass:SetProperty("Visible","true")
			BieYeCutePetBank_Item_LineOne_RightPass:SetProperty("Visible","true")
		end


		local nMengChongCount_2 = BieYeMengChong:GetBieYeMengChongTypeCount(g_MengChongCurrentPage,2)
		local nPct2 = math.ceil(nMengChongCount_2 / GRID_BUTTONS_NUM)

		if  nPct2 <= 1  then
			BieYeCutePetBank_Item_LineTwo_LeftPass:SetProperty("Visible","false")
			BieYeCutePetBank_Item_LineTwo_RightPass:SetProperty("Visible","false")
		elseif  g_MengChong_LR_Page2 <=1 then
			BieYeCutePetBank_Item_LineTwo_LeftPass:SetProperty("Visible","false")
			BieYeCutePetBank_Item_LineTwo_RightPass:SetProperty("Visible","true")
		elseif  g_MengChong_LR_Page2 >= nPct2 then
			BieYeCutePetBank_Item_LineTwo_LeftPass:SetProperty("Visible","true")
			BieYeCutePetBank_Item_LineTwo_RightPass:SetProperty("Visible","false")
		else
			BieYeCutePetBank_Item_LineTwo_LeftPass:SetProperty("Visible","true")
			BieYeCutePetBank_Item_LineTwo_RightPass:SetProperty("Visible","true")
		end


		local nMengChongCount_3 = BieYeMengChong:GetBieYeMengChongTypeCount(g_MengChongCurrentPage,3)
		local nPct3 = math.ceil(nMengChongCount_3 / GRID_BUTTONS_NUM)

		if  nPct3 <= 1  then
			BieYeCutePetBank_Item_LineThree_LeftPass:SetProperty("Visible","false")
			BieYeCutePetBank_Item_LineThree_RightPass:SetProperty("Visible","false")
		elseif  g_MengChong_LR_Page3 <=1 then
			BieYeCutePetBank_Item_LineThree_LeftPass:SetProperty("Visible","false")
			BieYeCutePetBank_Item_LineThree_RightPass:SetProperty("Visible","true")
		elseif  g_MengChong_LR_Page3 >= nPct3 then
			BieYeCutePetBank_Item_LineThree_LeftPass:SetProperty("Visible","true")
			BieYeCutePetBank_Item_LineThree_RightPass:SetProperty("Visible","false")
		else
			BieYeCutePetBank_Item_LineThree_LeftPass:SetProperty("Visible","true")
			BieYeCutePetBank_Item_LineThree_RightPass:SetProperty("Visible","true")
		end
	else -- 特殊页签   现在暂时不做翻页

	end


	return

end


function BieYeCutePetBank_Buy_Clicked()

	CloseFreshManGuide()
	BieYeCutePetBank_SaveBank_Animate:Hide()

	if( IsWindowShow("Packet") == false ) then
		ToggleContainer()
	end



	PushEvent( "MENGCHONG_BUHUO_OPEN",g_MengChongCurrentPage )
end



function BieYeCutePetBank_ItemRemoveClicked( )
	if g_index1 < 0 and g_index2 < 0 and g_index3 < 0 and g_indexSP < 0 then
		PushDebugMessage("#{MCJC_170727_113}")
		return
	end
	local index = -1
	if g_index1 >= 0 then
		index = g_MengChongindexChoose[1][g_index1]
	elseif g_index2 >= 0 then
		index = g_MengChongindexChoose[2][g_index2]
	elseif g_index3 >= 0 then
		index = g_MengChongindexChoose[3][g_index3]
	elseif g_indexSP >= 0 then
		index = g_MengChongindexChooseSP[g_indexSP]
	end
	if BieYeMengChong:BieYeMengChong_isHaveItem(index) <= 0 then
		return
	end
	BieYeMengChong:Lua_RemoveMengChong( index ,0)
end





function BieYeCutePetBank_ItemAddXiaoWoClicked( )
	BieYeCutePetBank_PutInNest_Animate:Hide()
	if g_index1 < 0 and g_index2 < 0 and g_index3 < 0 and g_indexSP < 0 then
		PushDebugMessage("#{MCJC_170727_113}")
		return
	end
	local index = -1
	if g_index1 >= 0 then
		index = g_MengChongindexChoose[1][g_index1]
	elseif g_index2 >= 0 then
		index = g_MengChongindexChoose[2][g_index2]
	elseif g_index3 >= 0 then
		index = g_MengChongindexChoose[3][g_index3]
	elseif g_indexSP >= 0 then
		index = g_MengChongindexChooseSP[g_indexSP]
	end

	BieYeMengChong:Lua_AddXiaoWo( index )

end

function BieYeCutePetBank_CallOut()
	BieYeCutePetBank_PutInNest_Animate:Hide()
	CloseFreshManGuide()
	Lua_CallOut()
end



--打开关于界面
function BieYeCutePetBank_OpenAllHelp(Help)

	if Help == 6 then
		PushEvent("OPEN_BIEYEALLHELP",6)
	elseif Help == 7 then
		PushEvent("OPEN_BIEYEALLHELP",7)
	elseif Help == 8 then
		PushEvent("OPEN_BIEYEALLHELP",8)
	elseif Help == 9 then
		PushEvent("OPEN_BIEYEALLHELP",9)
	end

end

function BieYeCutePetBank_MengChongShow()

	if g_index1 < 0 and g_index2 < 0 and g_index3 < 0 and g_indexSP < 0 then
		PushDebugMessage("#{MCJC_170727_113}")
		return
	end
	local index = -1
	if g_index1 >= 0 then
		index = g_MengChongindexChoose[1][g_index1]
	elseif g_index2 >= 0 then
		index = g_MengChongindexChoose[2][g_index2]
	elseif g_index3 >= 0 then
		index = g_MengChongindexChoose[3][g_index3]
	elseif g_indexSP >= 0 then
		index = g_MengChongindexChooseSP[g_indexSP]
	end
	if index < 0 then
		return
	end
	PushEvent("OPEN_MEGNCHONG_SHOW",	index)


end


function BieYeCutePetBank_ItemTakeOutClicked( )

	CloseFreshManGuide()
	BieYeCutePetBank_TakeOutBag_Animate:Hide()

	if g_index1 < 0 and g_index2 < 0 and g_index3 < 0 and g_indexSP < 0 then
		PushDebugMessage("#{MCJC_170727_113}")
		return
	end
	local index = -1
	if g_index1 >= 0 then
		index = g_MengChongindexChoose[1][g_index1]
	elseif g_index2 >= 0 then
		index = g_MengChongindexChoose[2][g_index2]
	elseif g_index3 >= 0 then
		index = g_MengChongindexChoose[3][g_index3]
	elseif g_indexSP >= 0 then
		index = g_MengChongindexChooseSP[g_indexSP]
	end
	if index < 0 then
		return
	end
	BieYeMengChong:Lua_GetOutChong( index )

end


function BieYeCutePetBank_MengChongAddFreshBefore_CAT( nAddTableIndex)
	local nMengChongType =  BieYeMengChong:GetBieYeMengChongInfo(nAddTableIndex,5)
	g_MengChongCurrentPage  = nMengChongType
	BieYeCutePetBank_ChangeYeQianNotUpdate(g_MengChongCurrentPage)
	if nMengChongType ~= 2 then
		local nMengChongQulity =  BieYeMengChong:GetBieYeMengChongInfo(nAddTableIndex,3)
		local nCurIndexPosCount_ByType = BieYeMengChong:Lua_BieYeMengChong_GetFirstPos2IndexPos(nAddTableIndex)

		if nMengChongQulity == 1 then
			g_MengChong_LR_Page1 = math.ceil(nCurIndexPosCount_ByType / GRID_BUTTONS_NUM)
		elseif nMengChongQulity == 2 then
			g_MengChong_LR_Page2 = math.ceil(nCurIndexPosCount_ByType / GRID_BUTTONS_NUM)
		elseif nMengChongQulity == 3 then
			g_MengChong_LR_Page3 = math.ceil(nCurIndexPosCount_ByType / GRID_BUTTONS_NUM)
		end
	else

		local nCurIndexPosCount_ByType = BieYeMengChong:Lua_BieYeMengChong_GetFirstPos2IndexPos(nAddTableIndex)

		g_MengChong_LR_PageSP = math.ceil(nCurIndexPosCount_ByType / (GRID_BUTTONS_SP_NUM *3))

	end

end


function BieYeCutePetBank_MengChongAddFreshAfter_CAT( nAddTableIndex)
	local nMengChongType =  BieYeMengChong:GetBieYeMengChongInfo(nAddTableIndex,5)

	local nCurIndexPosCount_ByType = BieYeMengChong:Lua_BieYeMengChong_GetFirstPos2IndexPos(nAddTableIndex)

	for i=1, GRID_BUTTONS_NUM do   --如果是萌宠添加,则需要清理掉之前的框框
			ActionButtonLine1[i]:SetPushed(0);
			ActionButtonLine2[i]:SetPushed(0);
			ActionButtonLine3[i]:SetPushed(0);

	end

	for i=1, GRID_BUTTONS_SP_NUM do   --如果是萌宠添加,则需要清理掉之前的框框
			ActionButtonSp[i]:SetPushed(0);
			ActionButtonSp[i+8]:SetPushed(0);
			ActionButtonSp[i+16]:SetPushed(0);
	end

	local nMengChongQulity =  BieYeMengChong:GetBieYeMengChongInfo(nAddTableIndex,3)
	local nMengChongStyle =  BieYeMengChong:GetBieYeMengChongInfo(nAddTableIndex,14)
	local nMod
	if nMengChongType ~= 2 then
		nMod = math.mod(nCurIndexPosCount_ByType , GRID_BUTTONS_NUM)
	else
		nMod = math.mod(nCurIndexPosCount_ByType , GRID_BUTTONS_SP_NUM * 3)
	end

	if nMod == 0 then
		if nMengChongType ~= 2 then
			if nMengChongQulity ==  1 then
				--ActionButtonLine1[GRID_BUTTONS_NUM]:SetPushed(1);
				g_index1 = GRID_BUTTONS_NUM
				g_index2 = -1
				g_index3 = -1
			elseif nMengChongQulity == 2 then

				--ActionButtonLine2[GRID_BUTTONS_NUM]:SetPushed(1);
				g_index2 = GRID_BUTTONS_NUM
				g_index1 = -1
				g_index3 = -1
			elseif nMengChongQulity == 3 then

				--ActionButtonLine3[GRID_BUTTONS_NUM]:SetPushed(1);
				g_index3 = GRID_BUTTONS_NUM
				g_index1 = -1
				g_index2 = -1
			end
		else
				--ActionButtonSp[GRID_BUTTONS_SP_NUM*3]:SetPushed(1);
				g_indexSP = GRID_BUTTONS_SP_NUM * 3
				g_index1 = -1
				g_index2 = -1
				g_index3 = -1
		end
	else
		if nMengChongType ~= 2 then
			if nMengChongQulity ==  1 then
				--ActionButtonLine1[nMod]:SetPushed(1);
				g_index1 = nMod
				g_index2 = -1
				g_index3 = -1
			elseif nMengChongQulity == 2 then
				--ActionButtonLine2[nMod]:SetPushed(1);
				g_index2 = nMod
				g_index1 = -1
				g_index3 = -1
			elseif nMengChongQulity == 3 then
				--ActionButtonLine3[nMod]:SetPushed(1);
				g_index3 = nMod
				g_index1 = -1
				g_index2 = -1
			end
		else --
				--ActionButtonSp[nMod]:SetPushed(1);
				g_indexSP = nMod
				g_index1 = -1
				g_index2 = -1
				g_index3 = -1
		end
	end

	if nMengChongStyle == 2 then
		BieYeCutePetBank_TakeOutBag:SetProperty("Disabled","false")
	else
		BieYeCutePetBank_TakeOutBag:SetProperty("Disabled","true")
	end

end




function BieYeCutePetBank_ChangeYeQian(d)

		g_index1 = -1
		g_index2 = -2
		g_index3 = -3
		g_indexSP = -1

		if d == 2 then
			BieYeCutePetBank_FenYe_SP:SetCheck(1)
			BieYeCutePetBank_FenYe1:SetCheck(0)
		else
			BieYeCutePetBank_FenYe_SP:SetCheck(0)
			BieYeCutePetBank_FenYe1:SetCheck(1)
		end
		g_MengChongCurrentPage = d
		BieYeCutePetBank_UpdateFrame(0)
end
function BieYeCutePetBank_ChangeYeQianNotUpdate(d)

		if d == 2 then
			BieYeCutePetBank_FenYe_SP:SetCheck(1)
			BieYeCutePetBank_FenYe1:SetCheck(0)
		else
			BieYeCutePetBank_FenYe_SP:SetCheck(0)
			BieYeCutePetBank_FenYe1:SetCheck(1)
		end

end
function BieYeCutePetBank_SetSPVisible(visible)

	if visible == 1 then
		BieYeCutePetBank_Item_SPClinet: SetProperty("Visible","true")

		BieYeCutePetBank_Item_LineOneClinet: SetProperty("Visible","False")
		BieYeCutePetBank_Item_LineTwoClinet: SetProperty("Visible","False")
		BieYeCutePetBank_Item_LineThreeClinet: SetProperty("Visible","False")

		BieYeCutePetBank_Item_LineOneImage: SetProperty("Visible","false")
		BieYeCutePetBank_Item_LineTwoImage: SetProperty("Visible","false")
		BieYeCutePetBank_Item_LineThreeImage: SetProperty("Visible","false")


	else
		BieYeCutePetBank_Item_SPClinet: SetProperty("Visible","false")

		BieYeCutePetBank_Item_LineOneClinet: SetProperty("Visible","true")
		BieYeCutePetBank_Item_LineTwoClinet: SetProperty("Visible","true")
		BieYeCutePetBank_Item_LineThreeClinet: SetProperty("Visible","true")

		BieYeCutePetBank_Item_LineOneImage: SetProperty("Visible","true")
		BieYeCutePetBank_Item_LineTwoImage: SetProperty("Visible","true")
		BieYeCutePetBank_Item_LineThreeImage: SetProperty("Visible","true")
	end


end
