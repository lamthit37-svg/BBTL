local g_BieYeCutePetPreview2_Frame_UnifiedPosition;
local g_XiaoWoindex = -2
local g_XiaoWoindex1 = -1
local opList = {
	[1]  = "#{MCJC_170727_15}" ,
	[2]  = "#{MCJC_170727_16}" ,
}
local g_MengChongImage = {
						["Type1"] = "set:CutePet01 image:CutePet01_CutePetType",
						["WuZhong1"] = "set:CutePet01 image:CutePet01_CutePetCat",
						["WuZhong2"] = "set:CutePet01 image:CutePet01_CutePetCat",
						["shidai1"] = "set:CutePet01 image:CutePet01_CutePetGeneration01",
						["shidai2"] = "set:CutePet01 image:CutePet01_CutePetGeneration02",
						["shidai3"] = "set:CutePet01 image:CutePet01_CutePetGeneration03",
						["PinZhi1"] = "set:CutePet01 image:CutePet01_CutePetPage1",
						["PinZhi2"] = "set:CutePet01 image:CutePet01_CutePetPage2",
						["PinZhi3"] = "set:CutePet01 image:CutePet01_CutePetPage3",
						["DiTu1"] = "set:CutePet01 image:CutePet01_CutePetCardGreen",
						["DiTu2"] = "set:CutePet01 image:CutePet01_CutePetCardBlue",
						["DiTu3"] = "set:CutePet01 image:CutePet01_CutePetCardPurple",
						["jihuo"] = "set:CutePet01 image:CutePet01_CutePetBlank",
						["weijihuo"] = "set:CutePet01 image:CutePet01_CutePetLocked",
}

function BieYeCutePetPreview2_PreLoad()

	this:RegisterEvent("SHOW_MENGCHONG");
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("BIEYE_UPDATE_MENGCHONG_BANK")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
end
function BieYeCutePetPreview2_OnLoad()
	g_BieYeCutePetPreview2_Frame_UnifiedPosition=BieYeCutePetPreview2_Frame:GetProperty("UnifiedPosition");
end


function BieYeCutePetPreview2_OnEvent(event)

	if (event == "SHOW_MENGCHONG")  then
	-- PushDebugMessage("11111")
		--if(IsWindowShow("OtherPet")) then
			--CloseWindow("OtherPet", true);
		--end
		--if IsWindowShow("TargetPet") then
			--CloseWindow("TargetPet", true);
		--end
		g_XiaoWoindex1 = BieYeMengChong:GetMengChongXiaoWoIndex();
        if g_XiaoWoindex1 == nil then
			return
        end
		BieYeCutePetPreview2_FakeObject : SetFakeObject( "" );
		BieYeMengChong : SetModelMengChong();
		BieYeCutePetPreview2_FakeObject : SetFakeObject( "My_TargetMengChong" );
		-- g_XiaoWoindex1 = BieYeMengChong:GetMengChongXiaoWoIndex();
        -- if g_XiaoWoindex1 == nil then
	    -- return
        -- end
		-- g_XiaoWoindex =g_XiaoWoindex1+1;
		--BieYeCutePetPreview2_Update();
		BieYeCutePetPreview2_Update(0);
		--BieYeCutePetPreview2_SetStateTooltip();
		--BieYeCutePetPreview2_Info2_food_Animate:Hide()

		local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
		local myGuid = Player:GetGUID()
		if myGuid == BieYeGuid then
			if DataPool:Lua_IsHaveMission(1872) > 0  then
				local misIndex = DataPool:GetPlayerMissionIndexByID(1872)
				if DataPool:GetPlayerMission_Variable(misIndex, 0) == 0 then
			--		CloseFreshManGuide()
			--		local fX, fY = this:GetChildOffset("BieYeCutePetPreview2_Info2_food")
			--		OpenFreshManGuide(1, 184, fX+10, fY+10, "BieYeCutePetPreview2", "northwest")
					--BieYeCutePetPreview2_Info2_food_Animate:Show()
				end
			end
		end

		this:Show();
	elseif (event == "BIEYE_UPDATE_MENGCHONG_BANK") then
		local bIsOnlyMengChongXiaoWo = tonumber(arg0)
		-- g_XiaoWoindex1 = BieYeMengChong:GetMengChongXiaoWoIndex();
       --  if g_XiaoWoindex1 == nil then
	  --   return
      --   end
		-- g_XiaoWoindex =g_XiaoWoindex1+1;
		local bIsOnlyMengChongXiaoWo = tonumber(arg0)
		if bIsOnlyMengChongXiaoWo == 1 then
			BieYeCutePetPreview2_Update(1);
		else
			BieYeCutePetPreview2_Update(0);
		end
		
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then

		local nType = tonumber(Get_XParam_INT(0))
		if nType == 30 then --打开界面

			BieYeCutePetNest_OnHiden()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BieYeCutePetPreview2_FakeObject:SetFakeObject("");
		this:Hide()
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeCutePetPreview2_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeCutePetPreview2_Frame_On_ResetPos()
	end

end
function BieYeCutePetPreview2_Close__Clicked()
	CloseFreshManGuide()
	this:Hide();
end
--
--旋转珍兽模型（向左)
--
function BieYeCutePetPreview2_Modle_TurnLeft(start)
	--向左旋转开始
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			BieYeCutePetPreview2_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			BieYeCutePetPreview2_FakeObject:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function BieYeCutePetPreview2_Modle_TurnRight(start)
	--向右旋转开始
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			BieYeCutePetPreview2_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			BieYeCutePetPreview2_FakeObject:RotateEnd();
		end
	end
end


function BieYeCutePetPreview2_Update(bIsOnlyMengChongXiaoWo)
    local g_XiaoWoindexFZ =g_XiaoWoindex
	--PushDebugMessage(g_XiaoWoindexFZ)
    g_XiaoWoindex = BieYeMengChong:GetMengChongXiaoWoIndex();
	if g_XiaoWoindex == nil and g_XiaoWoindexFZ ~= -2 or g_XiaoWoindex == -1 then
		g_XiaoWoindex =g_XiaoWoindexFZ
	elseif g_XiaoWoindex ==nil  or g_XiaoWoindex == -1 then
	    g_XiaoWoindex = g_XiaoWoindexFZ
		return
	else
		g_XiaoWoindex =g_XiaoWoindex+1
	end
    BieYeCutePetPreview2_FakeObject_WeekBak : SetProperty("Visible","False")
	BieYeCutePetPreview2_RanSe: SetProperty("Visible","False")
	BieYeCutePetPreview2_RanSe:SetText("")
	local nName = ''
	nName = BieYeMengChong:GetBieYeXiaoWoInfo("Name",g_XiaoWoindex)
	if nName == -1 then
		return
	end
	--BieYeCutePetPreview2_NickName:SetProperty("Visible","True")
	--BieYeCutePetPreview2_NickName:SetText(nName);
	if bIsOnlyMengChongXiaoWo == 0 then
	BieYeCutePetPreview2_Info3_EditNickName : SetText(nName)
	end
	--PushDebugMessage("nName"..nName)
	local Exp = 0
	--PushDebugMessage("step1")
	local BaoShiDu = 0
	-- g_XiaoWoindex =-1

	--PushDebugMessage(g_XiaoWoindex)
	local nMaxExp = BieYeMengChong:GetBieYeXiaoWoInfo("MaxExp",g_XiaoWoindex)
	 Exp =BieYeMengChong : GetBieYeXiaoWoInfo("Exp",g_XiaoWoindex)
	--PushDebugMessage(nMaxExp)
	local BaoShiDuLimit = BieYeMengChong:GetBieYeXiaoWoInfo("MaxBaoShiDu",g_XiaoWoindex)
	local nSelectIndex = BieYeMengChong:GetBieYeXiaoWoInfo("ItemIndex",g_XiaoWoindex)
	local nChengNianFlag = BieYeMengChong:GetBieYeXiaoWoChengNianState(g_XiaoWoindex)	
	if nSelectIndex > 0 then
		local nMengChongTransferID =  BieYeMengChong:GetBieYeMengChongInfo(nSelectIndex,8)
		if nMengChongTransferID > 0 then
			--BieYeCutePetPreview2_Info1_Text1:SetText("#{MCJC_170727_15}")
			local tex1 = ScriptGlobal_Format("#{MCJC_170727_89}",Exp,nMaxExp,"#{MCJC_170727_15}")
			BieYeCutePetPreview2_Info1_Text2:SetText(tex1)
			--PushDebugMessage(g_Stage["YouNian"])
		else
			--BieYeCutePetPreview2_Info1_Text1:SetText("#{MCJC_170727_16}")
			local tex1 = ScriptGlobal_Format("#{MCJC_170727_89}",nMaxExp,nMaxExp,"#{MCJC_170727_16}")
			--BieYeCutePetPreview2_Info1_Text2:SetText("#{MCJC_170727_89}"..Exp.."/"..nMaxExp)
			BieYeCutePetPreview2_Info1_Text2:SetText(tex1)
		end
	end
	--PushDebugMessage("step2")
	--染色风格
	local nIndex = BieYeMengChong:GetBieYeXiaoWoInfo("ItemIndex",g_XiaoWoindex)
	local RansePinZhi = BieYeMengChong:GetBieYeMengChongInfo(nIndex,7)
	local nComfort = BieYeMengChong:GetBieYeMengChongInfo(nIndex,20)
	if nComfort == nil then
		return
	end
	local TextComfort = ScriptGlobal_Format("#{MCJC_170727_146}", nComfort)
	BieYeCutePetPreview2_Info4_Text:SetText(TextComfort)
	if RansePinZhi == 1 then
		local szStrName = BieYePetCreateColor:GetColorName(nIndex)
		local Text = ScriptGlobal_Format("#{MCJC_170727_106}", szStrName)
		BieYeCutePetPreview2_RanSe:SetText(Text)
	elseif RansePinZhi == 2 then
		local szStrName = BieYePetCreateColor:GetColorName(nIndex)
		local Text = ScriptGlobal_Format("#{MCJC_170727_107}", szStrName)
		BieYeCutePetPreview2_RanSe:SetText(Text)
	elseif RansePinZhi == 3 then
		local szStrName = BieYePetCreateColor:GetColorName(nIndex)
		local Text = ScriptGlobal_Format("#{MCJC_170727_108}", szStrName)
		BieYeCutePetPreview2_RanSe:SetText(Text)
	elseif RansePinZhi == 0 then
		local szStrName = BieYePetCreateColor:GetColorName(nIndex)
		local Text = ScriptGlobal_Format("#{MCJC_170727_106}", szStrName)
		BieYeCutePetPreview2_RanSe:SetText(Text)
	end
	--物种
	--PushDebugMessage("step3")
	local Shidai = 1
	local nStyle = BieYeMengChong:GetBieYeMengChongInfo(nIndex,14)
	--PushDebugMessage("style"..nStyle)
	if nStyle == nil then
	return
	end
	if nStyle > 2 then
		if nStyle == 4 then
			Shidai = 3
		else
			Shidai = 2
		end
	end


	if nStyle ~= 0 then
	  BieYeCutePetPreview2_RanSe: SetProperty("Visible","True")
	end
	--是否虚弱
	local nIsWeek =  BieYeMengChong:Lua_isWeek(g_XiaoWoindex)
	if nIsWeek == 1 then
		BieYeCutePetPreview2_FakeObject_Week : SetProperty("Visible","True")
		BieYeCutePetPreview2_FakeObject_WeekBak : SetProperty("Visible","True")
		BieYeCutePetPreview2_FakeObject_Week : SetText("#{MCJC_170727_105}")
	end
	-- 品质
	local PinZhi = BieYeMengChong:GetBieYeMengChongInfo(nIndex,3)
	--g_JieMian["BieYeCutePetNest_Show"..i] : SetProperty("Image",g_MengChongImage["DiTu"..PinZhi])
	BieYeCutePetPreview2_PinZhi: SetProperty("Image",g_MengChongImage["PinZhi"..PinZhi])

	--PushDebugMessage("step4")
	--g_JieMian["BieYeCutePetNest_Show"..i.."_ShiDai"] : SetProperty("Visible","True")
	BieYeCutePetPreview2_ShiDai : SetProperty("Image",g_MengChongImage["shidai"..Shidai])

	--物种
	local WuZhong = BieYeMengChong:GetBieYeMengChongInfo(nIndex,5)
	BieYeCutePetPreview2_Wuzhong : SetProperty("Visible","True")
	BieYeCutePetPreview2_Wuzhong: SetProperty("Image",g_MengChongImage["WuZhong"..WuZhong])




	Exp = BieYeMengChong:GetBieYeXiaoWoInfo("Exp",g_XiaoWoindex)
	BaoShiDu = BieYeMengChong:GetBieYeXiaoWoInfo("BaoShiDu",g_XiaoWoindex)
	--PushDebugMessage("Exp="..Exp.." nMaxExp="..nMaxExp)
--	local tex1 = ScriptGlobal_Format("#{MCJC_170727_89}",Exp,nMaxExp)
	--BieYeCutePetPreview2_Info1_Text2:SetText("#{MCJC_170727_89}"..Exp.."/"..nMaxExp)
	--BieYeCutePetPreview2_Info1_Text2:SetText(tex1)

	--local tex2 = ScriptGlobal_Format("#{MCJC_170727_94}",BaoShiDu,BaoShiDuLimit,"#{MCJC_170727_93}")
	--PushDebugMessage("BaoShiDu="..BaoShiDu.."BaoShiDuLimit="..BaoShiDuLimit)
	--BieYeCutePetPreview2_Info2_Text2:SetText("#{MCJC_170727_94}"..BaoShiDu.."/"..BaoShiDuLimit)
	--BieYeCutePetPreview2_Info2_Text:SetText(tex2)
	local BaoShiDuText =""
	local BaoShiDuPD = BaoShiDu / BaoShiDuLimit
	if BaoShiDuPD >=0.95 then
		--BieYeCutePetPreview2_Info2_Text1:SetText("#{MCJC_170727_93}")
		BaoShiDuText = "#{MCJC_170727_93}"
	elseif BaoShiDuPD >0 and BaoShiDuPD<0.95 then
		--BieYeCutePetPreview2_Info2_Text1:SetText("#{MCJC_170727_92}")
		BaoShiDuText = "#{MCJC_170727_92}"
	else
		--BieYeCutePetPreview2_Info2_Text1:SetText("#{MCJC_170727_91}")
		BaoShiDuText = "#{MCJC_170727_91}"
	end
	local tex2 = ScriptGlobal_Format("#{MCJC_170727_94}",BaoShiDu,BaoShiDuLimit,BaoShiDuText)
	--PushDebugMessage("BaoShiDu="..BaoShiDu.."BaoShiDuLimit="..BaoShiDuLimit)
	--BieYeCutePetPreview2_Info2_Text2:SetText("#{MCJC_170727_94}"..BaoShiDu.."/"..BaoShiDuLimit)
	BieYeCutePetPreview2_Info2_Text:SetText(tex2)
	--PushDebugMessage("step5")
	local isMaster = BieYeMengChong:IsMaster()
	--PushDebugMessage(isMaster)
	if isMaster == 1 then
	BieYeCutePetPreview2_Info2_food:SetProperty("Visible","True")
	BieYeCutePetPreview2_Info3_EditNickName_Config:SetProperty("Visible","True")
	BieYeCutePetPreview2_Info4_call:SetProperty("Visible","True")
	else
	BieYeCutePetPreview2_Info2_food:SetProperty("Visible","False")
	BieYeCutePetPreview2_Info3_EditNickName_Config:SetProperty("Visible","False")
	BieYeCutePetPreview2_Info4_call:SetProperty("Visible","False")
	end

end
function BieYeCutePetPreview2_WeiYang()
	local isHave =BieYeMengChong:GetMengChongIsHave(g_XiaoWoindex);
    if isHave == nil then
		PushDebugMessage("#{MCJC_170727_28}")
		this:Hide();
		return 
	end
	-- g_XiaoWoindex = BieYeMengChong:GetMengChongXiaoWoIndex()+1;
	--PushDebugMessage(g_XiaoWoindex)
	CloseFreshManGuide()
	--BieYeCutePetPreview2_Info2_food_Animate:Hide()
	if g_XiaoWoindex >0 and g_XiaoWoindex <= 6 then
		BieYeMengChong:Lua_WeiYang(g_XiaoWoindex)
	else
		PushDebugMessage("#{MCJC_170727_24}")
	end
	
	local isHave =BieYeMengChong:GetMengChongIsHave(g_XiaoWoindex);

end
function BieYeCutePetPreview2_Edit_Name()

	local isHave =BieYeMengChong:GetMengChongIsHave(g_XiaoWoindex);
    if isHave == nil then
		PushDebugMessage("#{MCJC_170727_28}")
		this:Hide();
		return 
	end
	local Changed_Name = BieYeCutePetPreview2_Info3_EditNickName:GetText();
	local strName = BieYeMengChong:GetBieYeXiaoWoInfo("Name",g_XiaoWoindex)

	if Changed_Name == strName and Changed_Name ~= "" then
		--输入的名字为空 或者名字跟以前名字一样
		BieYeCutePetPreview2_Info3_EditNickName : SetText( strName );
		BieYeCutePetPreview2_Info3_EditNickName : SetProperty("ClearOffset" ,"True" )
		return
	end


	if(string.len(Changed_Name) < 2  or string.len(Changed_Name) > 12 ) then
		BieYeCutePetPreview2_Info3_EditNickName : SetText( strName );
		BieYeCutePetPreview2_Info3_EditNickName: SetProperty("ClearOffset" ,"True" )
		return;
	end

	BieYeMengChong:Change_Name(g_XiaoWoindex,Changed_Name);
end
function BieYeCutePetPreview2_OpenAllHelp(Help)

	if Help == 6 then
		PushEvent("OPEN_BIEYEALLHELP",6)
	elseif Help == 7 then
		PushEvent("OPEN_BIEYEALLHELP",7)
	elseif Help == 8 then
		PushEvent("OPEN_BIEYEALLHELP",8)
	end

end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeCutePetPreview2_Frame_On_ResetPos()
  BieYeCutePetPreview2_Frame:SetProperty("UnifiedPosition", g_BieYeCutePetPreview2_Frame_UnifiedPosition);
end

function BieYeCutePetPreview2_Bag()

	local isHave =BieYeMengChong:GetMengChongIsHave(g_XiaoWoindex);
    if isHave == nil then
		PushDebugMessage("#{MCJC_170727_28}")
		this:Hide();
		return 
	end
	local isok = BieYeMengChong:Lua_MinuXiaoWo(g_XiaoWoindex,0)
	if isok == 1 then
		this:Hide();
	end
	
end