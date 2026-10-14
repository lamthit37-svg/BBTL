--限时活动提醒界面2

g_XianShiHuoDongTiShi2_CurIndex = -1
g_XianShiHuoDongTiShi2_TableIndex = -1
g_XianShiHuoDongTiShi2_XinFan_Num = 6
g_XianShiHuoDongTiShi2_Msg={}
local g_XianShiHuoDongTiShi2_Frame_UnifiedXPosition
local g_XianShiHuoDongTiShi2_Frame_UnifiedYPosition
local g_XianShiHuoDongTiShi2_NewCamPaignID = -1;
function XianShiHuoDongTiShi2_PreLoad()

	this:RegisterEvent("OPEN_NOWHOLEDAY_CAMPAIGN")
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function XianShiHuoDongTiShi2_OnLoad()
	g_XianShiHuoDongTiShi2_Msg[1] = XianShiHuoDongTiShi2_Text1_2  --活动名称
    g_XianShiHuoDongTiShi2_Msg[2] = XianShiHuoDongTiShi2_Text2_2  --活动要求
    g_XianShiHuoDongTiShi2_Msg[3] = XianShiHuoDongTiShi2_Text3_2  --活动状态
    g_XianShiHuoDongTiShi2_Msg[4] = XianShiHuoDongTiShi2_Text4_2  --参加时间
    g_XianShiHuoDongTiShi2_Msg[5] = XianShiHuoDongTiShi2_Text5_2  --参加地点

	g_XianShiHuoDongTiShi2_Frame_UnifiedXPosition	= XianShiHuoDongTiShi2_Frame : GetProperty("UnifiedXPosition");
	g_XianShiHuoDongTiShi2_Frame_UnifiedYPosition	= XianShiHuoDongTiShi2_Frame : GetProperty("UnifiedYPosition");
end

-- OnEvent
function XianShiHuoDongTiShi2_OnEvent(event)
    if event == "OPEN_NOWHOLEDAY_CAMPAIGN" then

		local nCampaignIndex = tonumber(arg0)
		if nCampaignIndex == nil then
			return
		end

	    local nTempID = EnumNoWholedayCampaign( nCampaignIndex , "id")
		if this:IsVisible() and g_XianShiHuoDongTiShi2_TableIndex == tonumber(nTempID) then
			this:Hide()
			return
		end

		XianShiHuoDongTiShi2_Update(nCampaignIndex)
		this:Show()
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
  end
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		XianShiHuoDongTiShi2_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		XianShiHuoDongTiShi2_ResetPos()
	end

	return
end

function XianShiHuoDongTiShi2_OnShow()

end

function XianShiHuoDongTiShi2_Clear()
	XianShiHuoDongTiShi2_Text1_1:SetText("")
	XianShiHuoDongTiShi2_Text2_1:SetText("")
	XianShiHuoDongTiShi2_Text3_1:SetText("")
	XianShiHuoDongTiShi2_Text4_1:SetText("")
	XianShiHuoDongTiShi2_Text5_1:SetText("")

	XianShiHuoDongTiShi2_Text1_2:SetText("")
	XianShiHuoDongTiShi2_Text2_2:SetText("")
	XianShiHuoDongTiShi2_Text3_2:SetText("")
	XianShiHuoDongTiShi2_Text4_2:SetText("")
    XianShiHuoDongTiShi2_Text5_2:SetText("")

	XianShiHuoDongTiShi2_Icon:SetImage("")
end

function XianShiHuoDongTiShi2_Update( nIndex)
	XianShiHuoDongTiShi2_Clear()

	local Name = EnumNoWholedayCampaign( tonumber(nIndex) , "name")
	local SkillLevel = EnumNoWholedayCampaign( tonumber(nIndex) ,"skilllevel")
	local Status = "即将开放"
	local StartTime = EnumNoWholedayCampaign(tonumber(nIndex),"starttime").."--"..EnumNoWholedayCampaign(tonumber(nIndex),"endtime")
	local Site = EnumNoWholedayCampaign( tonumber(nIndex), "descNew")
	local Icon = EnumNoWholedayCampaign( tonumber(nIndex), "icon")
	local minlevel = "达到#G"..tostring(EnumNoWholedayCampaign(tonumber(nIndex), "minlevel")).."级"
	local IsCanDoActivty = 0

    ---心法判断
    for i = 1, g_XianShiHuoDongTiShi2_XinFan_Num do
        local  theAction = EnumAction( i - 1, "xinfa" )
        if theAction:GetID() ~= 0 then
            local nXinfaId = LifeAbility:GetLifeAbility_Number( theAction:GetID() )
			local nXinfa_level = Player:GetXinfaInfo(nXinfaId,"level")
            if nXinfa_level >= SkillLevel then
				IsCanDoActivty = IsCanDoActivty + 1
            end
        end
    end

	local SkillLevelStr = "前六本心法等级达到"
	if IsCanDoActivty == 6 then
		SkillLevelStr = SkillLevelStr.."#G"..tostring(SkillLevel)
	else
		SkillLevelStr = SkillLevelStr.."#cff0000"..tostring(SkillLevel)
	end

	g_XianShiHuoDongTiShi2_CurIndex = nIndex
	local nTempID = EnumNoWholedayCampaign( tonumber(nIndex) , "id")
	g_XianShiHuoDongTiShi2_NewCamPaignID = EnumNoWholedayCampaign( tonumber(nIndex) , "NewID")
	g_XianShiHuoDongTiShi2_TableIndex = tonumber(nTempID)

    XianShiHuoDongTiShi2_Icon:SetProperty("Image",tostring(Icon))
	XianShiHuoDongTiShi2_Text1_1:SetText("#cfff263活动名称：#G")
	XianShiHuoDongTiShi2_Text1_2:SetText("#G"..Name)
	XianShiHuoDongTiShi2_Text7_1:SetText("#cfff263等级要求：#W")
    XianShiHuoDongTiShi2_Text7_2:SetText(minlevel)
	XianShiHuoDongTiShi2_Text3_1:SetText("#cfff263活动状态：#W")
	XianShiHuoDongTiShi2_Text3_2:SetText(Status)
	XianShiHuoDongTiShi2_Text4_1:SetText("#cfff263参加时间：#W")
	XianShiHuoDongTiShi2_Text4_2:SetText(StartTime)
	XianShiHuoDongTiShi2_Text5_1:SetText("#cfff263参加地点：#W")
	XianShiHuoDongTiShi2_Text5_2:SetText(Site)


	if tonumber(SkillLevel) == 0 then
		XianShiHuoDongTiShi2_Text3_1:SetProperty("AbsoluteYPosition",26)  --66
		XianShiHuoDongTiShi2_Text3_2:SetProperty("AbsoluteYPosition",26)

		XianShiHuoDongTiShi2_Text4_1:SetProperty("AbsoluteYPosition",46 )
		XianShiHuoDongTiShi2_Text4_2:SetProperty("AbsoluteYPosition",46)


        XianShiHuoDongTiShi2_Text5_1:SetProperty("AbsoluteYPosition",66 )
        XianShiHuoDongTiShi2_Text5_2:SetProperty("AbsoluteYPosition",68 )
		return
	elseif IsCanDoActivty == 6 then
		XianShiHuoDongTiShi2_Text2_1:SetText("#cfff263心法要求：#W")
		XianShiHuoDongTiShi2_Text2_2:SetText(SkillLevelStr)

		XianShiHuoDongTiShi2_Text3_1:SetProperty("AbsoluteYPosition",46)  --66
		XianShiHuoDongTiShi2_Text3_2:SetProperty("AbsoluteYPosition",46)

		XianShiHuoDongTiShi2_Text4_1:SetProperty("AbsoluteYPosition",66 )
		XianShiHuoDongTiShi2_Text4_2:SetProperty("AbsoluteYPosition",66 )

        XianShiHuoDongTiShi2_Text5_1:SetProperty("AbsoluteYPosition",86 )
        XianShiHuoDongTiShi2_Text5_2:SetProperty("AbsoluteYPosition",88 )
		return
	elseif IsCanDoActivty < 6 then
		XianShiHuoDongTiShi2_Text2_1:SetText("#cfff263心法要求：#W")
		SkillLevelStr = SkillLevelStr.."#r#G".."#{XSHD_130116_08}"
		XianShiHuoDongTiShi2_Text2_2:SetText(SkillLevelStr)

		XianShiHuoDongTiShi2_Text3_1:SetProperty("AbsoluteYPosition",66)  --66
		XianShiHuoDongTiShi2_Text3_2:SetProperty("AbsoluteYPosition",66)

		XianShiHuoDongTiShi2_Text4_1:SetProperty("AbsoluteYPosition",86 )
		XianShiHuoDongTiShi2_Text4_2:SetProperty("AbsoluteYPosition",86 )

        XianShiHuoDongTiShi2_Text5_1:SetProperty("AbsoluteYPosition",106 )
        XianShiHuoDongTiShi2_Text5_2:SetProperty("AbsoluteYPosition",108 )
		return
	end
end

function XianShiHuoDongTiShi2_OnClickHide()
	this:Hide()
	if g_XianShiHuoDongTiShi2_CurIndex ~= -1 then
		PushEvent("HIDE_CAMPAIGN_BTN",g_XianShiHuoDongTiShi2_CurIndex)
	end
end

function XianShiHuoDongTiShi2_OnCheckCampaignBtn()
    if g_XianShiHuoDongTiShi2_TableIndex ~= nil and g_XianShiHuoDongTiShi2_TableIndex ~= -1 and g_XianShiHuoDongTiShi2_NewCamPaignID ~= -1 then
			--OnOpenCampaign(tonumber(g_XianShiHuoDongTiShi2_NewCamPaignID))
			PushEvent("OPEN_CAMPAINLISTNEW",g_XianShiHuoDongTiShi2_NewCamPaignID )
	    this:Hide()
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function XianShiHuoDongTiShi2_ResetPos()
	XianShiHuoDongTiShi2_Frame : SetProperty("UnifiedXPosition", g_XianShiHuoDongTiShi2_Frame_UnifiedXPosition)
	XianShiHuoDongTiShi2_Frame : SetProperty("UnifiedYPosition", g_XianShiHuoDongTiShi2_Frame_UnifiedYPosition)
end



