local g_BieYeCutePetNest_Frame_UnifiedPosition;

--格子及其编号
local GRID_BUTTONS_NUM = 12;


local g_JieMian = {}
local g_BieYe_XiaoWo_Button = {}


local objCared = -1
local g_Object = -1



local g_XiaoWoindex = -1

local XIAOWOTAG = 6

local g_MengChongImage = {
						["WuZhong1"] = "set:CutePet01 image:CutePet01_CutePetCat",
						["WuZhong2"] = "set:CutePet01 image:CutePet01_CutePet",
						["shidai1"] = "set:CutePet01 image:CutePet01_CutePetGeneration01",
						["shidai2"] = "set:CutePet01 image:CutePet01_CutePetGeneration02",
						["PinZhi1"] = "set:CutePet01 image:CutePet01_CutePetQualityGreen",
						["PinZhi2"] = "set:CutePet01 image:CutePet01_CutePetQualityBlue",
						["PinZhi3"] = "set:CutePet01 image:CutePet01_CutePetQualityPurple",
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
	["ChongWuMao"] = "宠物猫",
	["ChongWuGou"] = "宠物狗",
}

--===============================================
-- OnLoad()
--===============================================
function BieYeCutePetNest_PreLoad()
	--this:RegisterEvent("BIEYE_OPEN_MINI")

	-- 游戏窗口尺寸发生了变化
	--this:RegisterEvent("ADJEST_UI_POS",false)
	--this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--this:RegisterEvent("BIEYE_UPDATE_MENGCHONG_BANK")
	--this:RegisterEvent("CUTEPETNESTHIDE")
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	--this:RegisterEvent("UI_COMMAND")
end

function BieYeCutePetNest_OnLoad()



	g_JieMian["BieYeCutePetNest_Show1_ShiDai"] = BieYeCutePetNest_Show1_ShiDai;
	g_JieMian["BieYeCutePetNest_Show2_ShiDai"] = BieYeCutePetNest_Show2_ShiDai;
	g_JieMian["BieYeCutePetNest_Show3_ShiDai"] = BieYeCutePetNest_Show3_ShiDai;
	g_JieMian["BieYeCutePetNest_Show4_ShiDai"] = BieYeCutePetNest_Show4_ShiDai;
	g_JieMian["BieYeCutePetNest_Show5_ShiDai"] = BieYeCutePetNest_Show5_ShiDai;
	g_JieMian["BieYeCutePetNest_Show6_ShiDai"] = BieYeCutePetNest_Show6_ShiDai;

	g_JieMian["BieYeCutePetNest_Show1_PinZhi"] = BieYeCutePetNest_Show1_PinZhi;
	g_JieMian["BieYeCutePetNest_Show2_PinZhi"] = BieYeCutePetNest_Show2_PinZhi;
	g_JieMian["BieYeCutePetNest_Show3_PinZhi"] = BieYeCutePetNest_Show3_PinZhi;
	g_JieMian["BieYeCutePetNest_Show4_PinZhi"] = BieYeCutePetNest_Show4_PinZhi;
	g_JieMian["BieYeCutePetNest_Show5_PinZhi"] = BieYeCutePetNest_Show5_PinZhi;
	g_JieMian["BieYeCutePetNest_Show6_PinZhi"] = BieYeCutePetNest_Show6_PinZhi;


	g_JieMian["BieYeCutePetNest_Show1"] = BieYeCutePetNest_Show1;
	g_JieMian["BieYeCutePetNest_Show2"] = BieYeCutePetNest_Show2;
	g_JieMian["BieYeCutePetNest_Show3"] = BieYeCutePetNest_Show3;
	g_JieMian["BieYeCutePetNest_Show4"] = BieYeCutePetNest_Show4;
	g_JieMian["BieYeCutePetNest_Show5"] = BieYeCutePetNest_Show5;
	g_JieMian["BieYeCutePetNest_Show6"] = BieYeCutePetNest_Show6;

	g_JieMian["BieYeCutePetNest_Show1_Name"] = BieYeCutePetNest_Show1_Name;
	g_JieMian["BieYeCutePetNest_Show2_Name"] = BieYeCutePetNest_Show2_Name;
	g_JieMian["BieYeCutePetNest_Show3_Name"] = BieYeCutePetNest_Show3_Name;
	g_JieMian["BieYeCutePetNest_Show4_Name"] = BieYeCutePetNest_Show4_Name;
	g_JieMian["BieYeCutePetNest_Show5_Name"] = BieYeCutePetNest_Show5_Name;
	g_JieMian["BieYeCutePetNest_Show6_Name"] = BieYeCutePetNest_Show6_Name;


	g_JieMian["BieYeCutePetNest_Show1_RanSe"] = BieYeCutePetNest_Show1_RanSe;
	g_JieMian["BieYeCutePetNest_Show2_RanSe"] = BieYeCutePetNest_Show2_RanSe;
	g_JieMian["BieYeCutePetNest_Show3_RanSe"] = BieYeCutePetNest_Show3_RanSe;
	g_JieMian["BieYeCutePetNest_Show4_RanSe"] = BieYeCutePetNest_Show4_RanSe;
	g_JieMian["BieYeCutePetNest_Show5_RanSe"] = BieYeCutePetNest_Show5_RanSe;
	g_JieMian["BieYeCutePetNest_Show6_RanSe"] = BieYeCutePetNest_Show6_RanSe;


	g_JieMian["BieYeCutePetNest_Show1_WeekBak"] = BieYeCutePetNest_Show1_WeekBak;
	g_JieMian["BieYeCutePetNest_Show2_WeekBak"] = BieYeCutePetNest_Show2_WeekBak;
	g_JieMian["BieYeCutePetNest_Show3_WeekBak"] = BieYeCutePetNest_Show3_WeekBak;
	g_JieMian["BieYeCutePetNest_Show4_WeekBak"] = BieYeCutePetNest_Show4_WeekBak;
	g_JieMian["BieYeCutePetNest_Show5_WeekBak"] = BieYeCutePetNest_Show5_WeekBak;
	g_JieMian["BieYeCutePetNest_Show6_WeekBak"] = BieYeCutePetNest_Show6_WeekBak;


	g_JieMian["BieYeCutePetNest_Show1_Week"] = BieYeCutePetNest_Show1_Week;
	g_JieMian["BieYeCutePetNest_Show2_Week"] = BieYeCutePetNest_Show2_Week;
	g_JieMian["BieYeCutePetNest_Show3_Week"] = BieYeCutePetNest_Show3_Week;
	g_JieMian["BieYeCutePetNest_Show4_Week"] = BieYeCutePetNest_Show4_Week;
	g_JieMian["BieYeCutePetNest_Show5_Week"] = BieYeCutePetNest_Show5_Week;
	g_JieMian["BieYeCutePetNest_Show6_Week"] = BieYeCutePetNest_Show6_Week;


	g_JieMian["BieYeCutePetNest_Show1_Wuzhong"] = BieYeCutePetNest_Show1_Wuzhong;
	g_JieMian["BieYeCutePetNest_Show2_Wuzhong"] = BieYeCutePetNest_Show2_Wuzhong;
	g_JieMian["BieYeCutePetNest_Show3_Wuzhong"] = BieYeCutePetNest_Show3_Wuzhong;
	g_JieMian["BieYeCutePetNest_Show4_Wuzhong"] = BieYeCutePetNest_Show4_Wuzhong;
	g_JieMian["BieYeCutePetNest_Show5_Wuzhong"] = BieYeCutePetNest_Show5_Wuzhong;
	g_JieMian["BieYeCutePetNest_Show6_Wuzhong"] = BieYeCutePetNest_Show6_Wuzhong;


	g_JieMian["BieYeCutePetNest_Show1_EmptyInfo"] = BieYeCutePetNest_Show1_EmptyInfo;
	g_JieMian["BieYeCutePetNest_Show2_EmptyInfo"] = BieYeCutePetNest_Show2_EmptyInfo;
	g_JieMian["BieYeCutePetNest_Show3_EmptyInfo"] = BieYeCutePetNest_Show3_EmptyInfo;
	g_JieMian["BieYeCutePetNest_Show4_EmptyInfo"] = BieYeCutePetNest_Show4_EmptyInfo;
	g_JieMian["BieYeCutePetNest_Show5_EmptyInfo"] = BieYeCutePetNest_Show5_EmptyInfo;
	g_JieMian["BieYeCutePetNest_Show6_EmptyInfo"] = BieYeCutePetNest_Show6_EmptyInfo;



	g_BieYe_XiaoWo_Button[1] = BieYeCutePetNest_Show1_Button
	g_BieYe_XiaoWo_Button[2] = BieYeCutePetNest_Show2_Button
	g_BieYe_XiaoWo_Button[3] = BieYeCutePetNest_Show3_Button
	g_BieYe_XiaoWo_Button[4] = BieYeCutePetNest_Show4_Button
	g_BieYe_XiaoWo_Button[5] = BieYeCutePetNest_Show5_Button
	g_BieYe_XiaoWo_Button[6] = BieYeCutePetNest_Show6_Button


	g_JieMian["BieYeCutePetNest_Show1_Info"] = BieYeCutePetNest_Show1_Info;
	g_JieMian["BieYeCutePetNest_Show2_Info"] = BieYeCutePetNest_Show2_Info;
	g_JieMian["BieYeCutePetNest_Show3_Info"] = BieYeCutePetNest_Show3_Info;
	g_JieMian["BieYeCutePetNest_Show4_Info"] = BieYeCutePetNest_Show4_Info;
	g_JieMian["BieYeCutePetNest_Show5_Info"] = BieYeCutePetNest_Show5_Info;
	g_JieMian["BieYeCutePetNest_Show6_Info"] = BieYeCutePetNest_Show6_Info;


	g_JieMian["BieYeCutePetNest_Show1_EditNickName"] = BieYeCutePetNest_Show1_EditNickName;
	g_JieMian["BieYeCutePetNest_Show2_EditNickName"] = BieYeCutePetNest_Show2_EditNickName;
	g_JieMian["BieYeCutePetNest_Show3_EditNickName"] = BieYeCutePetNest_Show3_EditNickName;
	g_JieMian["BieYeCutePetNest_Show4_EditNickName"] = BieYeCutePetNest_Show4_EditNickName;
	g_JieMian["BieYeCutePetNest_Show5_EditNickName"] = BieYeCutePetNest_Show5_EditNickName;
	g_JieMian["BieYeCutePetNest_Show6_EditNickName"] = BieYeCutePetNest_Show6_EditNickName;


	g_JieMian["BieYeCutePetNest_Show1_Model"] = BieYeCutePetNest_Show1_Model;
	g_JieMian["BieYeCutePetNest_Show2_Model"] = BieYeCutePetNest_Show2_Model;
	g_JieMian["BieYeCutePetNest_Show3_Model"] = BieYeCutePetNest_Show3_Model;
	g_JieMian["BieYeCutePetNest_Show4_Model"] = BieYeCutePetNest_Show4_Model;
	g_JieMian["BieYeCutePetNest_Show5_Model"] = BieYeCutePetNest_Show5_Model;
	g_JieMian["BieYeCutePetNest_Show6_Model"] = BieYeCutePetNest_Show6_Model;

	g_JieMian["BieYeCutePetNest_Show1_EditNickName_Config"] = BieYeCutePetNest_Show1_EditNickName_Config;
	g_JieMian["BieYeCutePetNest_Show2_EditNickName_Config"] = BieYeCutePetNest_Show2_EditNickName_Config;
	g_JieMian["BieYeCutePetNest_Show3_EditNickName_Config"] = BieYeCutePetNest_Show3_EditNickName_Config;
	g_JieMian["BieYeCutePetNest_Show4_EditNickName_Config"] = BieYeCutePetNest_Show4_EditNickName_Config;
	g_JieMian["BieYeCutePetNest_Show5_EditNickName_Config"] = BieYeCutePetNest_Show5_EditNickName_Config;
	g_JieMian["BieYeCutePetNest_Show6_EditNickName_Config"] = BieYeCutePetNest_Show6_EditNickName_Config;



	g_BieYeCutePetNest_Frame_UnifiedPosition=BieYeCutePetNest_Frame:GetProperty("UnifiedPosition");

end


--===============================================
-- OnEvent
--===============================================
function BieYeCutePetNest_OnEvent(event)

	if (event == "CUTEPETNESTHIDE") then
			BieYeCutePetNest_OnHiden()
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then

		local nType = tonumber(Get_XParam_INT(0))
		if nType == 30 then --打开界面
			BieYeCutePetNest_OnHiden()
		end
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20170918 then



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

			BieYeCutePetNest_UpdateFrame(0)

			this:Show()




		objCared = -1;
		local tempID = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(tempID);

		if objCared == -1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end

		BieYeCutePetNest_BeginCareObject(objCared)
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeCutePetNest_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeCutePetNest_Frame_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then

		BieYeCutePetNest_StopCareObject()
		this:Hide()

	elseif (event == "BIEYE_UPDATE_MENGCHONG_BANK") then
		local bIsOnlyMengChongXiaoWo = tonumber(arg0)
		if bIsOnlyMengChongXiaoWo == 1 then
			BieYeCutePetNest_UpdateFrame(1)
		else
			BieYeCutePetNest_UpdateFrame(0)
		end


	elseif (event == "UI_COMMAND") and tonumber(arg0) == 892510002 then


	elseif (event == "UI_COMMAND") and tonumber(arg0) == 892512002 then


	end

end
--===============================================
-- BieYeCutePetNest_UpdateFrame
--===============================================
function BieYeCutePetNest_UpdateFrame(bIsOnlyMengChongXiaoWo)

	BieYeCutePetNest_TakeBackBank:SetToolTip("#{MCJC_170727_31}")



	BieYeCutePetNest_Call:SetToolTip("#{MCJC_170727_33}")


	if bIsOnlyMengChongXiaoWo == 0 then
		BieYeCutePetNest_Show1_Button:SetCheck(1)
		BieYeCutePetNest_XiaoWo_Click(1)
	else

		BieYeCutePetNest_XiaoWo_ClickFresh(bIsOnlyMengChongXiaoWo)
	end
end
--===============================================
-- 点击关闭
--===============================================
function BieYeCutePetNest_Close_Clicked()
	--PushEvent( "BIEYE_OPEN_MINI" )
	BieYeCutePetNest_StopCareObject()
	this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeCutePetNest_Frame_On_ResetPos()
  BieYeCutePetNest_Frame:SetProperty("UnifiedPosition", g_BieYeCutePetNest_Frame_UnifiedPosition);
end



function BieYeCutePetNest_OnHiden()

	BieYeCutePetNest_Close_Clicked()

end


function BieYeCutePetNest_XiaoWo_ClickFresh(bIsOnlyMengChongXiaoWo )
	if bIsOnlyMengChongXiaoWo == 0 then
		for i = 1, XIAOWOTAG do
			g_BieYe_XiaoWo_Button[i]:SetCheck(0);
		end
	end

	BieYeCutePetNest_XiaoWoFresh(bIsOnlyMengChongXiaoWo)
end


function BieYeCutePetNest_XiaoWoFresh( bIsOnlyMengChongXiaoWo )

	local nIndex = 0
	local nName = ''
	local Exp = 0
	local BaoShiDu = 0
	local BaoShiDuTime = 0
	local ExpTime = 0

	local nXiaoWoCount = BieYeMengChong:GetBieYePutMengChongLimitByBieYeLevel()

	--BieYeCutePetNest_InfoClient1_Exp : SetProperty("Visible","False")
	BieYeCutePetNest_InfoClient2_Satiation:SetToolTip("")
	BieYeCutePetNest_InfoClient2_Satiation:SetProgress(0,100000)
	BieYeCutePetNest_InfoClient1_Exp:SetText("#{MCJC_170727_120}")
	BieYeCutePetNest_InfoClient1_Stage:SetProperty("Visible","False")
	for i=1,XIAOWOTAG do
		nIndex = BieYeMengChong:GetBieYeXiaoWoInfo("ItemIndex",i)
		nName = BieYeMengChong:GetBieYeXiaoWoInfo("Name",i)
		Exp = BieYeMengChong:GetBieYeXiaoWoInfo("Exp",i)

		BaoShiDu = BieYeMengChong:GetBieYeXiaoWoInfo("BaoShiDu",i)


		g_JieMian["BieYeCutePetNest_Show"..i.."_Week"] : SetProperty("Visible","False")
		g_JieMian["BieYeCutePetNest_Show"..i.."_WeekBak"] : SetProperty("Visible","False")
		g_JieMian["BieYeCutePetNest_Show"..i.."_Wuzhong"] : SetProperty("Visible","False")
		g_JieMian["BieYeCutePetNest_Show"..i.."_ShiDai"] : SetProperty("Visible","False")
		g_JieMian["BieYeCutePetNest_Show"..i.."_PinZhi"]: SetProperty("Visible","False")
		g_JieMian["BieYeCutePetNest_Show"..i.."_EmptyInfo"]:SetText("")
		g_JieMian["BieYeCutePetNest_Show"..i.."_Info"]: SetProperty("Visible","False")
		g_JieMian["BieYeCutePetNest_Show"..i.."_Info"]:SetText("")
		g_JieMian["BieYeCutePetNest_Show"..i.."_Model"] :SetFakeObject("");


		g_JieMian["BieYeCutePetNest_Show"..i.."_Name"]:SetProperty("Visible","False")
		g_JieMian["BieYeCutePetNest_Show"..i.."_RanSe"]:SetProperty("Visible","False")
		if bIsOnlyMengChongXiaoWo == 0 then
			g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName"] : SetProperty("Visible","False")
			g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName"] : Disable()
			g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName"] : SetText("")
		end
		g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName_Config"]:SetProperty("Visible","False")
		g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName_Config"]:Disable()
		if i <= nXiaoWoCount then
		--激活
			if nIndex <= 0 then
				--激活 但没东西
					g_JieMian["BieYeCutePetNest_Show"..i] : SetProperty("Image",g_MengChongImage["jihuo"])
					g_JieMian["BieYeCutePetNest_Show"..i.."_EmptyInfo"]:SetText("#{MCJC_170727_04}")

					g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName"] : SetProperty("Visible","False")

					g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName_Config"]:SetProperty("Visible","False")
					g_JieMian["BieYeCutePetNest_Show"..i.."_Info"]: SetProperty("Visible","True")
					g_JieMian["BieYeCutePetNest_Show"..i.."_Info"]:SetText("#{MCJC_170727_11}")
			else
			--激活 有东西
				local WuZhong = BieYeMengChong:GetBieYeMengChongInfo(nIndex,5)
				g_JieMian["BieYeCutePetNest_Show"..i.."_Wuzhong"] : SetProperty("Visible","True")
				g_JieMian["BieYeCutePetNest_Show"..i.."_Wuzhong"]: SetProperty("Image",g_MengChongImage["WuZhong"..WuZhong])


				local PinZhi = BieYeMengChong:GetBieYeMengChongInfo(nIndex,3)
				g_JieMian["BieYeCutePetNest_Show"..i] : SetProperty("Image",g_MengChongImage["DiTu"..PinZhi])
				g_JieMian["BieYeCutePetNest_Show"..i.."_PinZhi"]: SetProperty("Image",g_MengChongImage["PinZhi"..PinZhi])




				local Shidai = 1
				local nStyle = BieYeMengChong:GetBieYeMengChongInfo(nIndex,14)
				if nStyle > 2 then
					Shidai = 2
				end

				local RansePinZhi = BieYeMengChong:GetBieYeMengChongInfo(nIndex,7)


				if RansePinZhi == 1 then
					local szStrName = BieYePetCreateColor:GetColorName(nIndex)
					local Text = ScriptGlobal_Format("#{MCJC_170727_106}", szStrName)
					g_JieMian["BieYeCutePetNest_Show"..i.."_RanSe"]:SetText(Text)
				elseif RansePinZhi == 2 then
					local szStrName = BieYePetCreateColor:GetColorName(nIndex)
					local Text = ScriptGlobal_Format("#{MCJC_170727_107}", szStrName)
					g_JieMian["BieYeCutePetNest_Show"..i.."_RanSe"]:SetText(Text)
				elseif RansePinZhi == 3 then
					local szStrName = BieYePetCreateColor:GetColorName(nIndex)
					local Text = ScriptGlobal_Format("#{MCJC_170727_108}", szStrName)
					g_JieMian["BieYeCutePetNest_Show"..i.."_RanSe"]:SetText(Text)
				end

				if RansePinZhi ~= 0 then
					g_JieMian["BieYeCutePetNest_Show"..i.."_RanSe"]:SetProperty("Visible","True")
				end

				g_JieMian["BieYeCutePetNest_Show"..i.."_ShiDai"] : SetProperty("Visible","True")
				g_JieMian["BieYeCutePetNest_Show"..i.."_ShiDai"] : SetProperty("Image",g_MengChongImage["shidai"..Shidai])


				if nStyle ~= 0 then
					g_JieMian["BieYeCutePetNest_Show"..i.."_PinZhi"]: SetProperty("Visible","True")
				end



				g_JieMian["BieYeCutePetNest_Show"..i.."_PinZhi"]: SetProperty("Visible","True")


				g_JieMian["BieYeCutePetNest_Show"..i.."_PinZhi"]: SetProperty("Visible","True")
				g_JieMian["BieYeCutePetNest_Show"..i.."_Name"]:SetProperty("Visible","True")
				local szWuzhongName = BieYeMengChong:GetBieYeMengChongInfo(nIndex,2)
				g_JieMian["BieYeCutePetNest_Show"..i.."_Name"]:SetText(szWuzhongName)



				local nIsWeek =  BieYeMengChong:Lua_isWeek(i)
				if nIsWeek == 1 then
					g_JieMian["BieYeCutePetNest_Show"..i.."_Week"] : SetProperty("Visible","True")
					g_JieMian["BieYeCutePetNest_Show"..i.."_WeekBak"] : SetProperty("Visible","True")
					g_JieMian["BieYeCutePetNest_Show"..i.."_Week"] : SetText("#{MCJC_170727_105}")
				end

				local ModelID = BieYeMengChong:Lua_GetModelIDByMengChongIndex(nIndex)
				local FakeObj = i - 1
				DataPool:MengChong_SetNPCModel(tonumber(ModelID), 1,FakeObj)
				g_JieMian["BieYeCutePetNest_Show"..i.."_Model"] : SetFakeObject( "MengChongFakeObj_PlayerNew"..FakeObj );
				if bIsOnlyMengChongXiaoWo == 0 then
					g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName"] : Enable()
					g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName"] : SetText(nName)
					g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName"] : SetProperty("Visible","True")
				end

				g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName_Config"]: Enable()

				g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName_Config"]:SetProperty("Visible","True")
			end


		else
		--未激活


			g_JieMian["BieYeCutePetNest_Show"..i] : SetProperty("Image",g_MengChongImage["weijihuo"])
			local nXiaoWoJieSuoLevel = BieYeMengChong:GetXiaoWoJieSuoLevelByIndex(i)
			local Allnumber1 = ScriptGlobal_Format("#{MCJC_170727_10}", nXiaoWoJieSuoLevel)
			g_JieMian["BieYeCutePetNest_Show"..i.."_Info"]: SetProperty("Visible","True")
			g_JieMian["BieYeCutePetNest_Show"..i.."_Info"]:SetText(Allnumber1)
			if bIsOnlyMengChongXiaoWo == 0 then
				g_JieMian["BieYeCutePetNest_Show"..i.."_EditNickName"] : SetProperty("Visible","False")
			end
		end

	end




	if g_XiaoWoindex >=1 and g_XiaoWoindex <=XIAOWOTAG then
		local nSelectIndex = BieYeMengChong:GetBieYeXiaoWoInfo("ItemIndex",g_XiaoWoindex)
		if nSelectIndex > 0 then
			local nSelectName = BieYeMengChong:GetBieYeXiaoWoInfo("Name",g_XiaoWoindex)
			local nSelectExp = BieYeMengChong:GetBieYeXiaoWoInfo("Exp",g_XiaoWoindex)
			local nSelectBaoShiDu = BieYeMengChong:GetBieYeXiaoWoInfo("BaoShiDu",g_XiaoWoindex)
			local nSelectExpTime = BieYeMengChong:GetBieYeXiaoWoInfo("Expz",g_XiaoWoindex)
			local nMaxExp  =  BieYeMengChong:GetBieYeXiaoWoInfo("MaxExp",g_XiaoWoindex)
			local nMengChongTransferID =  BieYeMengChong:GetBieYeMengChongInfo(nSelectIndex,8)
			BieYeCutePetNest_InfoClient1_Exp : SetProperty("Visible","True")
			BieYeCutePetNest_InfoClient1_Stage:SetProperty("Visible","True")
			if nMengChongTransferID > 0 then
				BieYeCutePetNest_InfoClient1_Stage:SetText(g_Stage["YouNian"])
				local Allnumber1 = ScriptGlobal_Format("#{MCJC_170727_17}", nSelectExp,nMaxExp)

				BieYeCutePetNest_InfoClient1_Exp:SetText(Allnumber1)
			else
				BieYeCutePetNest_InfoClient1_Stage:SetText(g_Stage["ChengNian"])
				local Allnumber1 = ScriptGlobal_Format("#{MCJC_170727_17}", nMaxExp,nMaxExp)
				BieYeCutePetNest_InfoClient1_Exp:SetText(Allnumber1)

			end


			--饱食度条
			local baoshidu =  BieYeMengChong:GetBieYeXiaoWoInfo("BaoShiDu",g_XiaoWoindex)
			local BaoShiDuLimit =  BieYeMengChong:GetBieYeXiaoWoInfo("MaxBaoShiDu",g_XiaoWoindex)
			BieYeCutePetNest_InfoClient2_Satiation:SetProgress(baoshidu,BaoShiDuLimit)
			local nIsWeek =  BieYeMengChong:Lua_isWeek(g_XiaoWoindex)
			local nIsBaoShi =  BieYeMengChong:Lua_isBaoShi(g_XiaoWoindex)
			if nIsWeek == 1 then
				local strBaoShiDuttooltips = ScriptGlobal_Format("#{MCJC_170727_20}", baoshidu)
				BieYeCutePetNest_InfoClient2_Satiation:SetToolTip(strBaoShiDuttooltips)
			elseif nIsBaoShi == 1 then
				local strBaoShiDuttooltips = ScriptGlobal_Format("#{MCJC_170727_22}", baoshidu)
				BieYeCutePetNest_InfoClient2_Satiation:SetToolTip(strBaoShiDuttooltips)
			else
				local strBaoShiDuttooltips = ScriptGlobal_Format("#{MCJC_170727_21}", baoshidu)
				BieYeCutePetNest_InfoClient2_Satiation:SetToolTip(strBaoShiDuttooltips)
			end
		end

	end

end



function BieYeCutePetNest_XiaoWo_Click( index )

	local nXiaoWoCount = BieYeMengChong:GetBieYePutMengChongLimitByBieYeLevel()
	if index < 1 or index > nXiaoWoCount or BieYeMengChong:Lua_HaveXiaoWoChong(index) < 0 then
		for i = 1, XIAOWOTAG do
			g_BieYe_XiaoWo_Button[i]:SetCheck(0);
		end
		g_XiaoWoindex = -1
		BieYeCutePetNest_XiaoWoFresh( 0 )
		return
	end

	g_XiaoWoindex = index;


	for i = 1, XIAOWOTAG do
		g_BieYe_XiaoWo_Button[i]:SetCheck(0);
	end
	g_BieYe_XiaoWo_Button[index]:SetCheck(1);
	BieYeCutePetNest_XiaoWoFresh( 0 )


end



function BieYeCutePetNest_Edit_Name(index)


	local Changed_Name = g_JieMian["BieYeCutePetNest_Show"..index.."_EditNickName"]:GetText();
	local strName = BieYeMengChong:GetBieYeXiaoWoInfo("Name",index)

	if Changed_Name == strName and Changed_Name ~= "" then
		--输入的名字为空 或者名字跟以前名字一样
		g_JieMian["BieYeCutePetNest_Show"..index.."_EditNickName"] : SetText( strName );
		g_JieMian["BieYeCutePetNest_Show"..index.."_EditNickName"]: SetProperty("ClearOffset" ,"True" )
		return
	end


	if(string.len(Changed_Name) < 2  or string.len(Changed_Name) > 12 ) then
		g_JieMian["BieYeCutePetNest_Show"..index.."_EditNickName"] : SetText( strName );
		g_JieMian["BieYeCutePetNest_Show"..index.."_EditNickName"]: SetProperty("ClearOffset" ,"True" )
		return;
	end

	BieYeMengChong:Change_Name(index,Changed_Name);
end



function BieYeCutePetNest_WeiYang()
	if g_XiaoWoindex >0 and g_XiaoWoindex <= XIAOWOTAG then
		BieYeMengChong:Lua_WeiYang(g_XiaoWoindex)
	else
		PushDebugMessage("#{MCJC_170727_114}")
	end

end

function BieYeCutePetNest_TakeBackBank1()
	if g_XiaoWoindex >0 and g_XiaoWoindex <= XIAOWOTAG then
		BieYeMengChong:Lua_MinuXiaoWo(g_XiaoWoindex,0)
	else
		PushDebugMessage("#{MCJC_170727_114}")
	end

end


function BieYeCutePetNest_XiaoWo_CallMengChong()


	if  BieYeMengChong:Lua_isOutter() == 0 then
		PushDebugMessage("#{MCJC_170727_119}")
		return
	end

	local bHaveChong = 0
	for i=1, XIAOWOTAG do
		if BieYeMengChong:Lua_HaveXiaoWoChong(i) > 0 then
			bHaveChong = 1
		end
	end
	if bHaveChong == 0 then
		PushDebugMessage("#{MCJC_170727_45}")
		return
	end

	if  BieYeMengChong:Lua_isOutter() == 0 then
		PushDebugMessage("#{MCJC_170727_119}")
		return
	end
	Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("CallMengChong");
			Set_XSCRIPT_ScriptID(891900);
			--Set_XSCRIPT_Parameter(0,g_NPC_ID);
			--Set_XSCRIPT_Parameter(1,g_ValidEquipPos[actionidx]);
			--Set_XSCRIPT_Parameter(2,g_Enchange_Item2);
			Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end



--打开关于界面
function BieYeCutePetNest_OpenAllHelp(Help)

	if Help == 6 then
		PushEvent("OPEN_BIEYEALLHELP",6)
	elseif Help == 7 then
		PushEvent("OPEN_BIEYEALLHELP",7)
	elseif Help == 8 then
		PushEvent("OPEN_BIEYEALLHELP",8)
	end

end

--=========================================================
--开始关心NPC
--=========================================================
function BieYeCutePetNest_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "BieYeCutePetNest");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "BieYeCutePetNest")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function BieYeCutePetNest_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "BieYeCutePetNest");
		g_Object = -1;
	end
end
