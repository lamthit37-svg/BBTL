local g_BieYeCutePetPreview1_Frame_UnifiedPosition;
local g_index = -1
local g_Count = -1
local g_MengChongImage = {
						["WuZhong1"] = "set:CutePet01 image:CutePet01_CutePetCat",
						["WuZhong2"] = "set:CutePet01 image:CutePet01_CutePetCat",
						["shidai1"] = "set:CutePet01 image:CutePet01_CutePetGeneration01",
						["shidai2"] = "set:CutePet01 image:CutePet01_CutePetGeneration02",
						["shidai3"] = "set:CutePet01 image:CutePet01_CutePetGeneration03",
						["PinZhi1"] = "set:CutePet01 image:CutePet01_CutePetPage1",
						["PinZhi2"] = "set:CutePet01 image:CutePet01_CutePetPage2",
						["PinZhi3"] = "set:CutePet01 image:CutePet01_CutePetPage3",
}
local g_ShopPet_Fitting_ActionID={0,17,18,19,20,21}
--===============================================
-- OnLoad()
--===============================================
function BieYeCutePetPreview1_PreLoad()
	this:RegisterEvent("OPEN_MEGNCHONG_SHOW")
	this:RegisterEvent("OPEN_MEGNCHONG_SHOW_PETCREATE")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("BIEYE_UPDATE_MENGCHONG_BANK")
	this:RegisterEvent("CUTEPETNESTHIDE")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	this:RegisterEvent("UI_COMMAND")
end
	
function BieYeCutePetPreview1_OnLoad()
	g_BieYeCutePetPreview1_Frame_UnifiedPosition=BieYeCutePetPreview1_Frame:GetProperty("UnifiedPosition");
	g_index = -1
end										


--===============================================
-- OnEvent
--===============================================
function BieYeCutePetPreview1_OnEvent(event)

	if(event == "OPEN_MEGNCHONG_SHOW") then
		--g_index = tonumber( arg0 );
		--local nTableIndex = BieYeMengChong:Lua_GetMengChongIndexFromAction( g_index )
		local nTableIndex = tonumber( arg0 );
		if nTableIndex <= 0 then
			return
		end
		BieYeCutePetPreview1_UpdateFrame(nTableIndex)

		this:Show()
	elseif(event == "OPEN_MEGNCHONG_SHOW_PETCREATE") then 
		nTableIndex = tonumber( arg0 ); 
		BieYeCutePetPreview1_UpdateFrame(nTableIndex)
		this:Show()
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeCutePetPreview1_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then

		local nType = tonumber(Get_XParam_INT(0))
		if nType == 30 then --打开界面

			BieYeCutePetNest_OnHiden()
		end	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeCutePetPreview1_Frame_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BieYeCutePetPreview1_List:ClearListBox()
		BieYeCutePetPreview1_FakeObject:SetFakeObject("");
		this:Hide()
	end
	
end


--===============================================
-- BieYeCutePetPreview1_UpdateFrame
--===============================================
function BieYeCutePetPreview1_UpdateFrame(ntableIndex)
	BieYeCutePetPreview1_List:ClearListBox()
	local nShiDai = 0
	local nStyle = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,14)
	local nCount = 0
	local nName = ""
	local nMengChongTransferID = 0
	local nMengChongColorFirstID = 0
	local nInit = 0
	local nComfort = 0
	if nStyle >=1 and  nStyle <=2 then
	else 
		--二代
		if nStyle == 4 then
			nShiDai = 3
		else
			nShiDai = 2
		end
		nCount = BieYePetCreateColor:GetCanColorMengChongCountByMCID(ntableIndex)		
		if BieYePetCreateColor:IsCouldFindItSelf(ntableIndex) == 1 then
			nMengChongColorFirstID = BieYePetCreateColor:GetNoColorByMengChongID(ntableIndex)
			nName = BieYeMengChong:GetBieYeMengChongInfo(nMengChongColorFirstID,2)		
			--BieYeCutePetPreview1_List:AddItem(nName, 0);
			--BieYeCutePetPreview1_List:SetItemUserData(0, nMengChongColorFirstID); 	
			nMengChongTransferID =  BieYeMengChong:GetBieYeMengChongInfo(nMengChongColorFirstID,8)
		else
			nName = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,2)		
			BieYeCutePetPreview1_List:AddItem(nName, 0);
			BieYeCutePetPreview1_List:SetItemUserData(0, ntableIndex); 	
			nMengChongTransferID =  BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,8)		
		end
		BieYeCutePetPreview1_Fresh(ntableIndex)	
	end
	
	g_Count = nCount + 1


	for i=1, nCount do

		if nShiDai ==  1 then

			local nID = BieYePetCreateColor:GetCreateInfoMengChongByIndex(ntableIndex,i)	

			local nName = BieYeMengChong:GetBieYeMengChongInfo(nID,2)
								
			BieYeCutePetPreview1_List:AddItem(nName, i -1);

			BieYeCutePetPreview1_List:SetItemUserData(i-1, nID); 		

		else

			local nID,nColorName = BieYePetCreateColor:GetColorInfoMengChongByIndex(ntableIndex,i)		
			if nID == ntableIndex then
				nInit = i -1
			end
			local nName = BieYeMengChong:GetBieYeMengChongInfo(nID,2)
			BieYeCutePetPreview1_List:AddItem(nName.."·"..nColorName, i-1);
			BieYeCutePetPreview1_List:SetItemUserData(i-1, nID); 						
		end
	end
	
	BieYeCutePetPreview1_List : SetItemSelectByItemID(nInit);
	
end
--===============================================
-- 点击关闭
--===============================================
function BieYeCutePetPreview1_Close_Clicked()
	BieYeCutePetPreview1_FakeObject:SetFakeObject("");
	BieYeCutePetPreview1_List:ClearListBox()
	this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeCutePetPreview1_Frame_On_ResetPos()
  BieYeCutePetPreview1_Frame:SetProperty("UnifiedPosition", g_BieYeCutePetPreview1_Frame_UnifiedPosition);
end


function BieYeCutePetPreview1_ItemBtnSubClicked( nLine,nRow )
end


function BieYeCutePetPreview1_OnHiden()
	BieYeCutePetPreview1_List:ClearListBox()
	BieYeCutePetPreview1_FakeObject:SetFakeObject("");
	this:Hide()
end

--//////////////////////////////////////////
-- 页码验证
--//////////////////////////////////////////


function BieYeCutePetPreview1_Left_Clicked()

	
end

function BieYeCutePetPreview1_Right_Clicked()
	


end

function BieYeCutePetPreview1_Fresh_ActionButton()
		
		

		

end


function BieYeCutePetPreview1_RightOrLeftButtonFreshCAT()


end



function BieYeCutePetPreview1_Buy_Clicked()
	

end





--打开关于界面
function BieYeCutePetPreview1_OpenAllHelp(Help)

end




--狗 --刷新左右按钮页签
function BieYeCutePetPreview1_RightOrLeftButtonFresh_DOG()

end
--狗 左点击
function BieYeCutePetPreview1_Left_Clicked_DOG()


end
--狗 右点击
function BieYeCutePetPreview1_Right_Clicked_DOG()
	

end



function BieYeCutePetPreview1_ItemTakeOutClicked( )	


end

function BieYeCutePetPreview1_ItemRemoveClicked( )	

end

function BieYeCutePetPreview1_XiaoWo_ClickFresh(bIsOnlyMengChongXiaoWo )

end


function BieYeCutePetPreview1_XiaoWoFresh(  )


	
end



function BieYeCutePetPreview1_XiaoWo_Click( index )

		
end



function BieYeCutePetPreview1_ItemAddXiaoWoClicked( )	

end



function BieYeCutePetPreview1_Edit_Name(index)


end

function BieYeCutePetPreview1_AskXiaoWoInfo()

end

function BieYeCutePetPreview1_WeiYang()


end

function BieYeCutePetPreview1_TakeBackBank()

end


function BieYeCutePetPreview1_XiaoWo_CallMengChong()

end



function BieYeCutePetPreview1_ChangeBtn_Select()
	local nSelIndex = BieYeCutePetPreview1_List:GetFirstSelectItem();

	if(nSelIndex < 0 or nSelIndex > g_Count) then
		return;
	end

	--当前显示称号
	local ntableIndex = BieYeCutePetPreview1_List:GetItemUserData(nSelIndex);
	BieYeCutePetPreview1_Fresh(ntableIndex)
end

function BieYeCutePetPreview1_TurnRight(nLeft)
	--打开大的UI
		--打开大的UI
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(nLeft == 1) then
			BieYeCutePetPreview1_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			BieYeCutePetPreview1_FakeObject:RotateEnd();
		end
	end

end
function BieYeCutePetPreview1_TurnLeft(nRight)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(nRight == 1) then
			BieYeCutePetPreview1_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			BieYeCutePetPreview1_FakeObject:RotateEnd();
		end
	end
end


function BieYeCutePetPreview1_ChangePetAction( nIndex )
	local Mark = 0
	for i=1,table.getn(g_ShopPet_Fitting_ActionID) do
		if nIndex == g_ShopPet_Fitting_ActionID[i] then
			Mark = 1
			break
		end
	end
	if Mark == 1 then
		DataPool:MengChongView_ChangeAction(nIndex)
	end
end

function BieYeCutePetPreview1_Fresh( ntableIndex )
	
	local nName=""
	local nCount = 1
	BieYeCutePetPreview1_FakeObject:SetFakeObject("");
	local szTypeDesc = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,1)
	local szName = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,2)
	local nLevel = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,3)
	local nStyle = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,4)
	local nClass = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,5)
	local nQuality = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,7)
	local m_Action1ID = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,9)
		local m_Action1IDName = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,15)
	local m_Action2ID = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,10)
		local m_Action2IDName = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,16)
	local m_Action3ID = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,11)
		local m_Action3IDName = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,17)
	local m_Action4ID = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,12)
		local m_Action4IDName = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,18)
	local m_ActionSID = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,13 )
		local m_ActionSPIDName = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,19)
	local nComfort = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,20)
	local nStyle = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,14)
	BieYeCutePetPreview1_List_Text:SetText(szName)	
	local ModelID = BieYeMengChong:Lua_GetModelIDByMengChongIndex(ntableIndex)

	DataPool:ShowMengChong_SetNPCModel(tonumber(ModelID), 1)
	BieYeCutePetPreview1_FakeObject : SetFakeObject("ShowMengChong");
	local textComfort = ScriptGlobal_Format("#{MCJC_170727_146}",nComfort)
	BieYeCutePetPreview1_SSD_text:SetText(textComfort)
	
    if m_ActionSID == -1 then
		--BieYeCutePetPreview1_ButtonSpeacial:SetProperty("Visible","False")
		BieYeCutePetPreview1_Activity_Window:SetProperty("Visible","False")
		BieYeCutePetPreview1_Activity_Window2:SetProperty("Visible","True")
	else
		BieYeCutePetPreview1_Activity_Window:SetProperty("Visible","True")
		BieYeCutePetPreview1_Activity_Window2:SetProperty("Visible","False")
		BieYeCutePetPreview1_ButtonSpeacial:SetProperty("Visible","True")
		--BieYeCutePetPreview1_ButtonSpeacial:SetText(m_ActionSPIDName)
	end
	if m_ActionSID ~= -1 then
		if m_Action1ID == -1 then
			BieYeCutePetPreview1_Button1:SetProperty("Visible","False")
		else
			BieYeCutePetPreview1_Button1:SetProperty("Visible","True")
		--	BieYeCutePetPreview1_Button1:SetText(m_Action1IDName)
		end
		
		
		if m_Action2ID == -1 then
			BieYeCutePetPreview1_Button2:SetProperty("Visible","False")
		else
			BieYeCutePetPreview1_Button2:SetProperty("Visible","True")
			--BieYeCutePetPreview1_Button2:SetText(m_Action2IDName)
		end
		
		if m_Action3ID == -1 then
			BieYeCutePetPreview1_Button3:SetProperty("Visible","False")
		else
			BieYeCutePetPreview1_Button3:SetProperty("Visible","True")
			--BieYeCutePetPreview1_Button3:SetText(m_Action3IDName)
		end
		
		if m_Action4ID == -1 then
			BieYeCutePetPreview1_Button4:SetProperty("Visible","False")
		else
			BieYeCutePetPreview1_Button4:SetProperty("Visible","True")
			--BieYeCutePetPreview1_Button4:SetText(m_Action4IDName)
		end
	else
		if m_Action1ID == -1 then
			BieYeCutePetPreview1_Window2_Button1:SetProperty("Visible","False")
		else
			BieYeCutePetPreview1_Window2_Button1:SetProperty("Visible","True")
			--BieYeCutePetPreview1_Window2_Button1:SetText(m_Action1IDName)
		end
		
		
		if m_Action2ID == -1 then
			BieYeCutePetPreview1_Window2_Button2:SetProperty("Visible","False")
		else
			BieYeCutePetPreview1_Window2_Button2:SetProperty("Visible","True")
			--BieYeCutePetPreview1_Window2_Button2:SetText(m_Action2IDName)
		end
		
		if m_Action3ID == -1 then
			BieYeCutePetPreview1_Window2_Button3:SetProperty("Visible","False")
		else
			BieYeCutePetPreview1_Window2_Button3:SetProperty("Visible","True")
			--BieYeCutePetPreview1_Window2_Button3:SetText(m_Action3IDName)
		end
		
		if m_Action4ID == -1 then
			BieYeCutePetPreview1_Window2_Button4:SetProperty("Visible","False")
		else
			BieYeCutePetPreview1_Window2_Button4:SetProperty("Visible","True")
			--BieYeCutePetPreview1_Window2_Button4:SetText(m_Action4IDName)
		end
	end


	
	local nShiDai = 0
	if nStyle >=1 and  nStyle <=2 then
		--一代 
		nShiDai = 1
		
	else 
		--二代
		if nStyle == 4 then
			nShiDai = 3
		else
			nShiDai = 2	
		end
	end
	


	local RansePinZhi = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,7)
	if RansePinZhi == 1 then
		local szStrName = BieYePetCreateColor:GetColorName(ntableIndex)
		local Text = ScriptGlobal_Format("#{MCJC_170727_106}", szStrName)
		BieYeCutePetPreview1_RanSe:SetText(Text)
	elseif RansePinZhi == 2 then
		local szStrName = BieYePetCreateColor:GetColorName(ntableIndex)
		local Text = ScriptGlobal_Format("#{MCJC_170727_107}", szStrName)
		BieYeCutePetPreview1_RanSe:SetText(Text)
	elseif RansePinZhi == 3 then
		local szStrName = BieYePetCreateColor:GetColorName(ntableIndex)
		local Text = ScriptGlobal_Format("#{MCJC_170727_108}", szStrName)
		BieYeCutePetPreview1_RanSe:SetText(Text)
	elseif RansePinZhi == 0 then
		local szStrName = BieYePetCreateColor:GetColorName(ntableIndex)
		local Text = ScriptGlobal_Format("#{MCJC_170727_106}", szStrName)
		BieYeCutePetPreview1_RanSe:SetText(Text)
	end
	--物种
	
	local Shidai = 1
	local nStyle = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,14)
	if nStyle > 2 then
		if nStyle == 4 then
			Shidai = 3
		else
			Shidai = 2
		end
	end
	BieYeCutePetPreview1_RanSe:SetProperty("Visible","Flase")

	if RansePinZhi >= 0 then
		BieYeCutePetPreview1_RanSe:SetProperty("Visible","True")
	end

	--是否虚弱
	--local nIsWeek =  BieYeMengChong:Lua_isWeek(g_XiaoWoindex)
	--if nIsWeek == 1 then
		--BieYeCutePetPreview2_FakeObject_Week : SetProperty("Visible","True")
		--BieYeCutePetPreview2_FakeObject_WeekBak : SetProperty("Visible","True")
		--BieYeCutePetPreview2_FakeObject_Week : SetText("#{MCJC_170727_105}")	
	--end	
	-- 品质 
	
	local PinZhi = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,3)
	BieYeCutePetPreview1_PinZhi: SetProperty("Image",g_MengChongImage["PinZhi"..PinZhi])
	BieYeCutePetPreview1_ShiDai : SetProperty("Image",g_MengChongImage["shidai"..Shidai])
	--wuzhong
	
	local WuZhong = BieYeMengChong:GetBieYeMengChongInfo(ntableIndex,5)
	BieYeCutePetPreview1_Wuzhong : SetProperty("Visible","True")
	BieYeCutePetPreview1_Wuzhong: SetProperty("Image",g_MengChongImage["WuZhong"..WuZhong])
end






