--限时活动提醒界面1

local g_XianShiHuoDongTiShi_Msg ={}
g_XianShiHuoDongTiShi_Msg[1] = { index=-1 }
g_XianShiHuoDongTiShi_Msg[2] = { index=-1 }
g_XianShiHuoDongTiShi_Msg[3] = { index=-1 }
g_XianShiHuoDongTiShi_Msg[4] = { index=-1 }
g_XianShiHuoDongTiShi_Msg[5] = { index=-1 }

local g_XianShiHuoDongTiShi_Btn={}
local g_XianShiHuoDongTiShi_BtnBK={}
local g_XianShiHuoDongTiShi_Ani={}

--记录已经隐藏掉的活动
local g_XianSHiHuoDongTiShi1_Hide_Index={}

local g_XianShiHuoDongTiShi1_Frame_UnifiedXPosition = 0
local g_XianShiHuoDongTiShi1_Frame_UnifiedYPosition = 0

function XianShiHuoDongTiShi1_PreLoad()
	-- 打开界面
	this:RegisterEvent("ADD_CAMPAIGN_NOTICE")
	this:RegisterEvent("UPDATE_NOWHOLEDAY_CAMPAIGN")
	this:RegisterEvent("HIDE_CAMPAIGN_BTN")
	this:RegisterEvent("GAMELOGIN_OPEN_SELECT_CHARACTOR");
	this:RegisterEvent("SWITCH_MENU_BUTTON");
	--this:RegisterEvent("UPDATE_FRESHMAN_POSITION");
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function XianShiHuoDongTiShi1_OnLoad()
	-- 保存界面的默认相对位置
	g_XianShiHuoDongTiShi1_Frame_UnifiedXPosition	= XianShiHuoDongTiShi1_Frame : GetProperty("UnifiedXPosition");
	g_XianShiHuoDongTiShi1_Frame_UnifiedXPosition	= XianShiHuoDongTiShi1_Frame : GetProperty("UnifiedYPosition");

	g_XianShiHuoDongTiShi_Btn[1] = XianShiHuoDongTiShi1_Icon1
	g_XianShiHuoDongTiShi_Btn[2] = XianShiHuoDongTiShi1_Icon2
	g_XianShiHuoDongTiShi_Btn[3] = XianShiHuoDongTiShi1_Icon3
	g_XianShiHuoDongTiShi_Btn[4] = XianShiHuoDongTiShi1_Icon4
	g_XianShiHuoDongTiShi_Btn[5] = XianShiHuoDongTiShi1_Icon5
	
	if SystemSetup:IsClassic() == 0 then
		g_XianShiHuoDongTiShi_BtnBK[1] = XianShiHuoDongTiShi1_Icon1BK
		g_XianShiHuoDongTiShi_BtnBK[2] = XianShiHuoDongTiShi1_Icon2BK
		g_XianShiHuoDongTiShi_BtnBK[3] = XianShiHuoDongTiShi1_Icon3BK
		g_XianShiHuoDongTiShi_BtnBK[4] = XianShiHuoDongTiShi1_Icon4BK
		g_XianShiHuoDongTiShi_BtnBK[5] = XianShiHuoDongTiShi1_Icon5BK
	end

	g_XianShiHuoDongTiShi_Ani[1] = XianShiHuoDongTiShi1_Animate1
	g_XianShiHuoDongTiShi_Ani[2] = XianShiHuoDongTiShi1_Animate2
	g_XianShiHuoDongTiShi_Ani[3] = XianShiHuoDongTiShi1_Animate3
	g_XianShiHuoDongTiShi_Ani[4] = XianShiHuoDongTiShi1_Animate4
	g_XianShiHuoDongTiShi_Ani[5] = XianShiHuoDongTiShi1_Animate5
end

-- OnEvent
function XianShiHuoDongTiShi1_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		this:Hide()
		return
	end
	
	if ( event == "PLAYER_ENTERING_WORLD") then
		if this:IsVisible() then
			return
	    end
		this:Show()
		XianShiHuoDongTiShi1_OnShow()
	end

	if ( event == "ADD_CAMPAIGN_NOTICE" ) then
	    if XianShiHuoDongTiShi1_IsInHideList(arg0) == 1 then
			return
		end
		XianShiHuoDongTiShi1_AddMsg(arg0)
		XianShiHuoDongTiShi1_OnShow()
	end

	if ( event == "UPDATE_NOWHOLEDAY_CAMPAIGN" ) then
	    if arg0==nil or arg1==nil or arg2==nil then
			return
		end

		if tonumber(arg2) == 0 then
			XianShiHuoDongTiShi1_ClearHideList()
		end

		XianShiHuoDongTiShi1_HideAllBtn()
        XianShiHuoDongTiShi1_OnShow()
	end

	if (event == "HIDE_CAMPAIGN_BTN") then
		if arg0==nil or tonumber(arg0)<0 then
			return
		end
		if tonumber(arg0) == -2 then
			XianShiHuoDongTiShi1_HideAllBtn()
		    XianShiHuoDongTiShi1_OnShow()
			return
		end
		XianShiHuoDongTiShi1_DeleteMsg(arg0)
		XianShiHuoDongTiShi1_Order()
		XianShiHuoDongTiShi1_OnShow()
		XianShiHuoDongTiShi1_AddToHideList(arg0)
	end

	if (event == "GAMELOGIN_OPEN_SELECT_CHARACTOR") then
		XianShiHuoDongTiShi1_HideAllBtn()
        XianShiHuoDongTiShi1_OnShow()
		XianShiHuoDongTiShi1_ClearHideList()
		this:Hide()
	end

	if (event == "SWITCH_MENU_BUTTON") then
		XianShiHuoDongTiShi1_UpdatePos()
	end

	--if (event == "UPDATE_FRESHMAN_POSITION") then
		--XianShiHuoDongTiShi1_UpdatePos()
	--end


	return;
end


function XianShiHuoDongTiShi1_OnShow()
    local IsHaveIcon = 0
	for i=1,5 do
	    local CampaignIndex = g_XianShiHuoDongTiShi_Msg[i].index
		g_XianShiHuoDongTiShi_Btn[i]:SetImage("")
		g_XianShiHuoDongTiShi_Btn[i]:SetToolTip("")
		g_XianShiHuoDongTiShi_Ani[i]:Play(false)

		if CampaignIndex ~= -1 then
			local CampaignIcon = EnumNoWholedayCampaign(tonumber(CampaignIndex),"icon")
			local CampaignName = EnumNoWholedayCampaign(tonumber(CampaignIndex),"name")
			local Tooltip = ScriptGlobal_Format("#{XSHD_130116_01}",CampaignName)
            g_XianShiHuoDongTiShi_Ani[i]:Show()
			g_XianShiHuoDongTiShi_Btn[i]:Show()
			if SystemSetup:IsClassic() == 0 then
				g_XianShiHuoDongTiShi_BtnBK[i]:Show()
			end
			g_XianShiHuoDongTiShi_Btn[i]:SetProperty("Image",tostring(CampaignIcon))
			g_XianShiHuoDongTiShi_Btn[i]:SetToolTip(Tooltip)
			g_XianShiHuoDongTiShi_Ani[i]:Play(true)
			IsHaveIcon = IsHaveIcon+1
		else
			g_XianShiHuoDongTiShi_Btn[i]:Hide()
			if SystemSetup:IsClassic() == 0 then
				g_XianShiHuoDongTiShi_BtnBK[i]:Hide()
			end
			g_XianShiHuoDongTiShi_Ani[i]:Hide()
			g_XianShiHuoDongTiShi_Ani[i]:Play(false)
		end
	end

	if IsHaveIcon == 0 then
        --this:Hide()
		SetCampaignShow(0)
    else
	    --this:Show()
	    SetCampaignShow(1)
    end

	--PushEvent("UPDATE_FRESHMAN_POSITION",tonumber(IsHaveIcon))
end

function XianShiHuoDongTiShi1_AddMsg( nIndex )
	for i=1,5 do
		if g_XianShiHuoDongTiShi_Msg[i].index ~= -1 and g_XianShiHuoDongTiShi_Msg[i].index ~= nil then
			local CamName1 = EnumNoWholedayCampaign( tonumber(g_XianShiHuoDongTiShi_Msg[i].index) , "name")
			local CamName2 = EnumNoWholedayCampaign( tonumber(nIndex) , "name")
			local startTime1 = EnumNoWholedayCampaign(tonumber(g_XianShiHuoDongTiShi_Msg[i].index),"starttime")
			local startTime2 = EnumNoWholedayCampaign(tonumber(nIndex),"starttime")
			if CamName1 == CamName2 and startTime1 == startTime2 then
				return
			end
		end
	end
    g_XianShiHuoDongTiShi_Msg[5].index = g_XianShiHuoDongTiShi_Msg[4].index
    g_XianShiHuoDongTiShi_Msg[4].index = g_XianShiHuoDongTiShi_Msg[3].index
	g_XianShiHuoDongTiShi_Msg[3].index = g_XianShiHuoDongTiShi_Msg[2].index
	g_XianShiHuoDongTiShi_Msg[2].index = g_XianShiHuoDongTiShi_Msg[1].index
	g_XianShiHuoDongTiShi_Msg[1].index = nIndex
end

function XianShiHuoDongTiShi1_DeleteMsg( nIndex )
	for i=1,5 do
		if g_XianShiHuoDongTiShi_Msg[i].index == nIndex then
			g_XianShiHuoDongTiShi_Msg[i].index = -1
			return
		end
	end
end

function XianShiHuoDongTiShi1_Update(arg0, arg1, arg2)
	local MonAndDay = tonumber(arg0)  --月/日
	local WDay = tonumber(arg1)       --/星期
	local HouAndMin = tonumber(arg2)
	local nHou = math.floor(HouAndMin/100)      --时
	local nMin = math.mod(HouAndMin,100)        --分

	for i=1,5 do
	    local nCampaignIndex = g_XianShiHuoDongTiShi_Msg[i].index
		if nCampaignIndex ~= -1 then
			local nType = EnumNoWholedayCampaign( tonumber(nCampaignIndex) , "type")
			local nTimeFront = EnumNoWholedayCampaign( tonumber(nCampaignIndex) , "starttimefront")
			if nType == 0 then
				if nTimeFront ~= MonAndDay then
				    g_XianShiHuoDongTiShi_Msg[i].index = -1
				end
			elseif nType == 2 then
				if nTimeFront ~= WDay then
				    g_XianShiHuoDongTiShi_Msg[i].index = -1
				end
			elseif nType == 4 then
				if nTimeFront ~= MonAndDay then
				    g_XianShiHuoDongTiShi_Msg[i].index = -1
				end
			end

			local nTimeBehind = EnumNoWholedayCampaign( tonumber(nCampaignIndex) , "starttimebehind")
			if XianShiHuoDongTiShi1_IsNoValidTime(nHou,nMin,nTimeBehind)==1 then
				g_XianShiHuoDongTiShi_Msg[i].index = -1
			end
		end
	end
end

function XianShiHuoDongTiShi1_Order()
	for i=1,5 do
		if i==5 then
		    g_XianShiHuoDongTiShi_Msg[i].index = -1
		    return
		end
		if g_XianShiHuoDongTiShi_Msg[i].index == -1 then
			g_XianShiHuoDongTiShi_Msg[i].index = g_XianShiHuoDongTiShi_Msg[i+1].index
			g_XianShiHuoDongTiShi_Msg[i+1].index = -1
		end
	end
end


function XianShiHuoDongTiShi1_HideAllBtn()
	for i=1,5 do
		g_XianShiHuoDongTiShi_Msg[i].index = -1
	end
end


--是否在提醒的时间范围内 0:有效  1：无效
function  XianShiHuoDongTiShi1_IsNoValidTime( nHou, nMin, CampaignTime )
    local CampaignHou = math.floor(CampaignTime/100)
    local CampaignMin = math.mod(CampaignTime,100)

	if CampaignHou==nHou and CampaignMin==nMin then
		return 1
    end

	if (CampaignHou==nHou and CampaignMin-nMin>5) or (CampaignHou==nHou and CampaignMin<nMin) then
		return 1
	end

	if CampaignHou-nHou==1 and (60-nMin)+CampaignMin>5 then
		return 1
	end

	return 0
end

function XianShiHuoDongTiShi1_OnClickCampaignBtn( nBtnId )
    if nBtnId<=0 or nBtnId>6 then
		return
	end

	local nCampaignIndex = g_XianShiHuoDongTiShi_Msg[nBtnId].index

	if nCampaignIndex == -1 or nCampaignIndex == nil then
	    return
	end

	PushEvent("OPEN_NOWHOLEDAY_CAMPAIGN",tonumber(nCampaignIndex))
end


function XianShiHuoDongTiShi1_IsInHideList( nIndex)
    local nCount = table.getn(g_XianSHiHuoDongTiShi1_Hide_Index)
    if nCount <= 0 then
		return 0
	end
	for i=1,nCount do
		if g_XianSHiHuoDongTiShi1_Hide_Index[i] ~= nil then
			local nID1 = EnumNoWholedayCampaign( tonumber(nIndex) , "id")
			local nID2 = g_XianSHiHuoDongTiShi1_Hide_Index[i]
			if nID1 == nID2 then
				return 1
			end
		end
	end
	return 0
end

function XianShiHuoDongTiShi1_AddToHideList( nIndex)
    local nCount = table.getn(g_XianSHiHuoDongTiShi1_Hide_Index)+1
	local nID = tonumber(EnumNoWholedayCampaign( tonumber(nIndex) , "id"))
	g_XianSHiHuoDongTiShi1_Hide_Index[tonumber(nCount)] = nID
end

function XianShiHuoDongTiShi1_ClearHideList()
    local nCount = table.getn(g_XianSHiHuoDongTiShi1_Hide_Index)
    if nCount <= 0 then
		return
	end
	for i=1,nCount do
		if g_XianSHiHuoDongTiShi1_Hide_Index[i] ~= nil then
			g_XianSHiHuoDongTiShi1_Hide_Index[i] = nil
		end
	end
	return
end

function XianShiHuoDongTiShi1_UpdatePos()
	if IsWindowShow("MainMenuBar_4") == true then			--主快捷栏上有两排快捷栏
		XianShiHuoDongTiShi1_Frame:SetProperty("UnifiedPosition","{{0.500000,-84.000000},{1.000000,-172.000000}}")
	elseif IsWindowShow("MainMenuBar_2") == true then	--主快捷栏上有一排快捷栏
		XianShiHuoDongTiShi1_Frame:SetProperty("UnifiedPosition","{{0.500000,-84.000000},{1.000000,-136.000000}}")
	else																							--主快捷栏上不存在快捷栏
		XianShiHuoDongTiShi1_Frame:SetProperty("UnifiedPosition","{{0.500000,-84.000000},{1.000000,-100.000000}}")
	end
end



