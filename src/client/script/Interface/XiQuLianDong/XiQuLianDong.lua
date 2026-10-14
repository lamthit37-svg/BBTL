--戏曲联动界面


local g_Frame_UnifiedPosition

local g_nActiveCount = 0
local g_XQLD_MF = {5629, 5630, 5631, 5632, 5633, 5634}

local g_XQLD_CurPage = -1

local g_XQLD_Images = {
	[1] = "set:BWBJSQN2 image:BWBJSQN_Img_1",
	[2] = "set:BWBJSQN2 image:BWBJSQN_Img_2",
	[3] = "set:BWBJSQN3 image:BWBJSQN_Img_3",
	[4] = "set:BWBJSQN3 image:BWBJSQN_Img_4",
	[5] = "set:BWBJSQN4 image:BWBJSQN_Img_5",
	[6] = "set:BWBJSQN4 image:BWBJSQN_Img_6",
}
local g_XQLD_PageCtrl = {}

local g_XQLD_Item = {
	[1]={id=39925425, count=100},--代币
	[2]={id=20502003, count=1},
	[3]={id=39925425, count=100},--代币
	[4]={id=20501003, count=1},
	[5]={id=39925425, count=100},--代币
	[6]={id=38008841, count=1, bShowBtn=1},
}
--=========
-- PreLoad()
--=========
function XiQuLianDong_PreLoad()

	this:RegisterEvent("UI_COMMAND")--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	this:RegisterEvent("ADJEST_UI_POS")

end

--=========
-- OnLoad()
--=========
function XiQuLianDong_OnLoad()
	g_Frame_UnifiedPosition = XiQuLianDong_Frame:GetProperty("UnifiedPosition")

	g_XQLD_PageCtrl = {
		XiQuLianDong_Img1, XiQuLianDong_Img2, XiQuLianDong_Img3, XiQuLianDong_Img4, XiQuLianDong_Img5, XiQuLianDong_Img6
	}
end

--=========
-- Event
--=========
function XiQuLianDong_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0)== 51002501 ) then
		local bOpen = Get_XParam_INT(0)
		if bOpen == 1 then
			g_nActiveCount = Get_XParam_INT(1);
			g_XQLD_CurPage = -1
			if KaJi:LuaFnIsKaJiServer() == 1 then
				XiQuLianDong_Client_Text:SetText("#{XQLD_260803_1}")
			else
				XiQuLianDong_Client_Text:SetText("#{XQLD_260611_5}")
			end
			XiQuLianDong_Update()
			this:Show()
		elseif bOpen == 2 and this:IsVisible() then
			g_nActiveCount = Get_XParam_INT(1);
			XiQuLianDong_Update()
		end

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		XiQuLianDong_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		XiQuLianDong_On_ResetPos()
	end
end

function XiQuLianDong_On_ResetPos()
	XiQuLianDong_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function XiQuLianDong_Page_Left()
	g_XQLD_CurPage = g_XQLD_CurPage - 1
	XiQuLianDong_Update()
end

function XiQuLianDong_Page_Right()
	g_XQLD_CurPage = g_XQLD_CurPage + 1
	XiQuLianDong_Update()
end

function XiQuLianDong_Update()

	--今日活跃值
	local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
	if KaJi:LuaFnIsKaJiServer() == 1 then
		XiQuLianDong_GetGift_HuoYue:SetText( ScriptGlobal_Format("#{XQLD_260803_3}", nToadyActivePoint) )
	else
		XiQuLianDong_GetGift_HuoYue:SetText( ScriptGlobal_Format("#{XQLD_260803_2}", nToadyActivePoint) )
	end
	--激活数
	--g_nActiveCount
	--已经领取数
	local nPrizeCount = 0
	local nPrizeFlag = {0,0,0,0,0,0}
	for i=1,table.getn(g_XQLD_MF) do
		nPrizeFlag[i] = Pneuma:GetMF(g_XQLD_MF[i])
		nPrizeCount = nPrizeCount + nPrizeFlag[i]
	end
--	PushDebugMessage(nPrizeFlag[1].." "..nPrizeFlag[2].." "..nPrizeFlag[3].." "..nPrizeFlag[4])
--	PushDebugMessage("nPrizeCount="..nPrizeCount.." g_nActiveCount="..g_nActiveCount)
	if g_XQLD_CurPage == -1 then
		--默认打开页面
		if g_nActiveCount > 0 then
			--第一个可领取但是未领取的页面
			for i=1,g_nActiveCount do
				if nPrizeFlag[i] == 0 then
					g_XQLD_CurPage = i
					break;
				end
			end
			--前面都领完了，显示下一个不可领取的页面
			if g_XQLD_CurPage == -1 and g_nActiveCount == nPrizeCount and g_nActiveCount <= 5 then
				g_XQLD_CurPage = g_nActiveCount + 1
			end
		end
		if g_XQLD_CurPage == -1 then
			g_XQLD_CurPage = 1
		end
		--都领完打开第一页
		--没领过打开第一页
	end
	if g_XQLD_Images[g_XQLD_CurPage] ~= nil then
		XiQuLianDong_ImageBk_01:SetProperty("Image", g_XQLD_Images[g_XQLD_CurPage])
	end
	--页码
	for i=1,6 do
		if i == g_XQLD_CurPage then
			g_XQLD_PageCtrl[i]:Show()
		else
			g_XQLD_PageCtrl[i]:Hide()
		end
	end

	local theAction = DataPool:CreateBindActionItemForShow(g_XQLD_Item[g_XQLD_CurPage].id, g_XQLD_Item[g_XQLD_CurPage].count) 
	if theAction:GetID() ~= 0 then
		XiQuLianDong_GetItem:SetActionItem(theAction:GetID());
	end

	if nPrizeFlag[g_XQLD_CurPage] == 1 then
		XiQuLianDong_GetGift:Hide()
		XiQuLianDong_GetGift_Tips:Hide()
		XiQuLianDong_GetItemOK:Show()--已领取图片

	elseif g_nActiveCount >= g_XQLD_CurPage and nPrizeFlag[g_XQLD_CurPage] == 0 then
		XiQuLianDong_GetGift:Show()
		XiQuLianDong_GetGift:Enable()
		XiQuLianDong_GetGift_Tips:Show()
		XiQuLianDong_GetItemOK:Hide()--已领取图片

	else
		XiQuLianDong_GetGift:Show()
		XiQuLianDong_GetGift:Disable()
		XiQuLianDong_GetGift_Tips:Hide()
		XiQuLianDong_GetItemOK:Hide()--已领取图片
	end
	if g_XQLD_Item[g_XQLD_CurPage].bShowBtn ~= nil and g_XQLD_Item[g_XQLD_CurPage].bShowBtn == 1 then
		XiQuLianDong_GetGift_YL:Show()
	else
		XiQuLianDong_GetGift_YL:Hide()
	end

	--翻页部分
	if g_XQLD_CurPage <= 1 then
		XiQuLianDong_LeftArrow:Disable()
		XiQuLianDong_RightArrow:Enable()
	elseif g_XQLD_CurPage >= 6 then
		XiQuLianDong_LeftArrow:Enable()
		XiQuLianDong_RightArrow:Disable()
	else
		XiQuLianDong_LeftArrow:Enable()
		XiQuLianDong_RightArrow:Enable()
	end
	--小红点
	XiQuLianDong_GetGift_Tips_L:Hide()
	XiQuLianDong_GetGift_Tips_R:Hide()

	if g_XQLD_CurPage > 1 then
		--左侧红点
		for i=1, g_XQLD_CurPage-1 do
			if nPrizeFlag[i] == 0 and g_nActiveCount >= i then
				XiQuLianDong_GetGift_Tips_L:Show()
				break;
			end
		end
	end
	if g_XQLD_CurPage < 6 then
		--右侧红点
		for i=g_XQLD_CurPage+1, 6 do
			if nPrizeFlag[i] == 0 and g_nActiveCount >= i then
				XiQuLianDong_GetGift_Tips_R:Show()
				break;
			end
		end
	end

end

function XiQuLianDong_GetGiftClicked()
	if g_XQLD_CurPage < 1 or g_XQLD_CurPage > 6 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PlayerClickPrize")
		Set_XSCRIPT_ScriptID(510025)
		Set_XSCRIPT_Parameter(0, g_XQLD_CurPage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function XiQuLianDong_OnClose()
	this:Hide()
end

function  XiQuLianDong_OnHide()
	this:Hide()
end

function XiQuLianDong_GetGift_YLClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Parameter(0, 10128855)
		Set_XSCRIPT_Parameter(1, 304)--hairId
		Set_XSCRIPT_Parameter(2, 217)--faceid
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end
