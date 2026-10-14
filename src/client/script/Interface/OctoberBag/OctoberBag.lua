-- 2019国庆稳活跃抽奖

local g_OctoberBag_Frame_UnifiedPosition = nil
local g_OctoberBag_MyBag_Action = {}
local g_OctoberBag_MyBag_Mask = {}
local g_OctoberBag_Select = -1 --3，金，2银，1铜
local g_OctoberBag_ShowItemInfo = {}
local g_OctoberBag_CurCount = 0
local g_OctoberBag_CurSelect = {}
local g_OctoberBag_MyBag_Count = 0
local g_OctoberBag_SaveFrame = 0
local g_OctoberBag_Fenye = {}
local g_OctoberBag_Mask = {}

local g_OctoberBag_MDInfo = 0
local g_OctoberBag_Tips = {}
local g_OctoberBag_Cost = {}
--local g_OctoberBag_SubTitle = {}
local g_OctoberBag_Icon = {}
local g_OctoberBag_tooltipstr = {}

local g_OctoberBag_BeginDay = 20250925
local g_OctoberBag_EndDay =   20251010
local g_OctoberBag_LimitLevel = 30

-- PreLoad
function OctoberBag_PreLoad()

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT")
	this:RegisterEvent("UI_COMMAND",false)
	this:RegisterEvent("GQHYCHOUJIANG_RECIVE",true)
	this:RegisterEvent("GQHYCHOUJIANG_CONFIRM",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);
	--this:RegisterEvent("OPEN_ANNIVERSARY_GUIDE",false);

end 

-- 关闭
function OctoberBag_Close_Clicked()
	this:Hide()
end

-- OctoberBag_FrameNULL_Right2 => TLBB_StaticImageNULL
-- OctoberBag_Frame_Client => TLBB_MainFrame16
-- OctoberBag_FrameNULL_Right1 => TLBB_StaticImageNULL
-- OctoberBag_DragTitle => TLBB_DragTitle
-- OctoberBag_FrameNULL_Left => TLBB_StaticImageNULL
-- OctoberBag_DragTitleBK => TLBB_Frame_Lace37
-- OnLoad
function OctoberBag_OnLoad()

	local OctoberBag_Action = {}
	local OctoberBag_CheckMark = {}
	local OctoberBag_Mask = {}
	local OctoberBag_Image = {}
	for i = 1,3 do
		for j = 1,8 do
			OctoberBag_Action[(i-1)*8+j] = "OctoberBag_Bk"..i.."_Item"..j
			OctoberBag_CheckMark[(i-1)*8+j] = "OctoberBag_Bk"..i.."_Item"..j.."Image"		--OctoberBag_Bk1_Item1Image
			OctoberBag_Mask[(i-1)*8+j] = "OctoberBag_Bk"..i.."_Item"..j.."_Mask"			--OctoberBag_Bk1_Item1_Mask
			OctoberBag_Image[(i-1)*8+j] = "OctoberBag_Bk"..i.."_Item"..j.."BK"
		end	
	end
	
	--居然还有一行6个的
	for i = 1,6 do
			OctoberBag_Action[i+24] = "OctoberBag_Bk4".."_Item"..i
			OctoberBag_CheckMark[i+24] = "OctoberBag_Bk4".."_Item"..i.."Image"		--OctoberBag_Bk1_Item1Image
			OctoberBag_Mask[i+24] = "OctoberBag_Bk4".."_Item"..i.."_Mask"			--OctoberBag_Bk1_Item1_Mask
			OctoberBag_Image[i+24] = "OctoberBag_Bk4".."_Item"..i.."BK"			
	end
	
	for i = 1,30 do
		g_OctoberBag_ShowItemInfo[i] = { ActionButton = _G[OctoberBag_Action[i]], CheckMark = _G[OctoberBag_CheckMark[i]], Mask = _G[OctoberBag_Mask[i]], 
										BKImage = _G[OctoberBag_Image[i]],disable=0,actionid=-1,bonusId=-1}
	end
	
	g_OctoberBag_Fenye[1] = OctoberBag_CheckFrame_FenYe3
	g_OctoberBag_Fenye[2] = OctoberBag_CheckFrame_FenYe2
	g_OctoberBag_Fenye[3] = OctoberBag_CheckFrame_FenYe1
	g_OctoberBag_Fenye[4] = OctoberBag_Button
	g_OctoberBag_Frame_UnifiedPosition = OctoberBag_Frame:GetProperty("UnifiedPosition");
	
	g_OctoberBag_Tips[1] = OctoberBag_CheckFrame_FenYe3_Tips
	g_OctoberBag_Tips[2] = OctoberBag_CheckFrame_FenYe2_Tips
	g_OctoberBag_Tips[3] = OctoberBag_CheckFrame_FenYe1_Tips
	g_OctoberBag_Tips[4] = OctoberBag_Button_Tips
	
	g_OctoberBag_Icon[1] = "set:NationalDay2 image:OctoberBagIcon1"
	g_OctoberBag_Icon[2] = "set:NationalDay2 image:OctoberBagIcon2"
	g_OctoberBag_Icon[3] = "set:NationalDay2 image:OctoberBagIcon3"
	
	--g_OctoberBag_SubTitle[1] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_TitleTong"
	--g_OctoberBag_SubTitle[2] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_TitleYin"
	--g_OctoberBag_SubTitle[3] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_TitleJin"
	--g_OctoberBag_SubTitle[4] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_TitleMyBag"
	
	g_OctoberBag_Cost[1] = 2
	g_OctoberBag_Cost[2] = 3
	g_OctoberBag_Cost[3] = 6
	
	g_OctoberBag_tooltipstr[1] = "#{GQHY_190723_10}"
	g_OctoberBag_tooltipstr[2] = "#{GQHY_190723_11}"
	g_OctoberBag_tooltipstr[3] = "#{GQHY_190723_12}"

end

-- OnEvent
function OctoberBag_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		OctoberBag_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		OctoberBag_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		OctoberBag_On_Hide()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		OctoberBag_CareObj()
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 89316705 then
		Lua_AskGQHYChouJiangInfo(0,g_OctoberBag_Select)
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 89316706 then-- 我的花池小红点
		if g_OctoberBag_Select >= 1 and g_OctoberBag_Select <= 3 then
			g_OctoberBag_Tips[4]:Show()
		else
			g_OctoberBag_Tips[4]:Hide()
		end
	elseif (event == "GQHYCHOUJIANG_RECIVE") and tonumber(arg0) == 0 then
		OctoberBag_InitFrame(tonumber(arg1))
		this:Show()	
	elseif (event == "GQHYCHOUJIANG_CONFIRM") and tonumber(arg0) == 1 then
		OctoberBag_AfterConfirm()
	elseif (event == "GQHYCHOUJIANG_CONFIRM") and tonumber(arg0) == 3 then
		OctoberBag_CleanData()
		OctoberBag_ShowFrame(g_OctoberBag_SaveFrame);
	--elseif (event == "OPEN_ANNIVERSARY_GUIDE") then
	--	this:Hide()
	end
end

-- 道具数据清除
function OctoberBag_CleanData()
	for i =1, 30 do
		g_OctoberBag_ShowItemInfo[i].ActionButton:SetActionItem(-1)
		g_OctoberBag_ShowItemInfo[i].CheckMark:Hide()
		g_OctoberBag_ShowItemInfo[i].Mask:Hide()
		g_OctoberBag_ShowItemInfo[i].BKImage:SetProperty("Image","")
		g_OctoberBag_ShowItemInfo[i].disable = 0
		g_OctoberBag_ShowItemInfo[i].actionid = -1
		g_OctoberBag_ShowItemInfo[i].bonusId = -1
	end
	g_OctoberBag_MyBag_Count = 0
end

-- 初始化界面
function  OctoberBag_InitFrame(nFrame)

	-- 清空数据
	OctoberBag_CleanData()
	
	-- 左侧页签小红点
	OctoberBag_SetTips()
	
	-- 显示宝袋数据
	OctoberBag_ShowFrame(nFrame)
	
	-- 国庆节主界面小红点
	OctoberBag_GetButtonStatus()	
	
end

-- 左侧页签小红点
function OctoberBag_SetTips()

	g_OctoberBag_Tips[4]:Hide()
	local countlist = {0,0,0}
	for i = 1,30 do
		local bonusId = Lua_GetMyGQHYChouJiangItem(i-1)
		if bonusId > 0 then
			local poolId,ShowItemId,ItemCount = Lua_GetGQHYChouJiangInfoByBonusId(bonusId)
			if poolId >=1 and poolId <=3 then
				countlist[poolId] = countlist[poolId]+1
			end
		end
	end
	
	for i = 1,3 do
		local myCurrency = Lua_GetMyGQHYChouJiangCurrency(i-1)
		local maxnum = OctoberBag_GetMaxNum(i)
		if myCurrency >= g_OctoberBag_Cost[i] and countlist[i] < maxnum  then
			g_OctoberBag_Tips[i]:Show()
		else
			g_OctoberBag_Tips[i]:Hide()
		end
	end
	
end

-- 国庆主界面小红点
function OctoberBag_GetButtonStatus()
	--if (IsInTServer() == 1) then
	--	PushDebugMessage("#{BHKF_140909_327}")
	--	return
	--end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowButtonTips" )
			Set_XSCRIPT_ScriptID(232004)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
end

-- 更新代币数据
function OctoberBag_UpDataCurrency()

	-- 已选择数量
	local strNum = ScriptGlobal_Format("#{GQHY_190723_20}", g_OctoberBag_CurCount-1,OctoberBag_GetMaxNum(g_OctoberBag_Select))
	OctoberBag_NumText:SetText(strNum)
	
	-- 剩余代币数量
	local curStr = OctoberBag_GetCurrencyStr()
	local currency = Lua_GetMyGQHYChouJiangCurrency(g_OctoberBag_Select-1)
	local strHave = ScriptGlobal_Format("#{GQHY_190723_21}", curStr,currency)
	OctoberBag_HaveText:SetText(strHave)
	
	-- 代币tips
	if g_OctoberBag_Select == 1 then
		OctoberBag_HaveText:SetToolTip("#{GQHY_190723_22}")
		OctoberBag_CoinText:SetText("#{GQHY_190723_89}")
		OctoberBag_CoinText:Hide()-- 策划亲说先隐藏
	elseif g_OctoberBag_Select == 2 then
		OctoberBag_HaveText:SetToolTip("#{GQHY_190723_23}")
		OctoberBag_CoinText:SetText("#{GQHY_190723_90}")
		OctoberBag_CoinText:Hide()-- 策划亲说先隐藏
	elseif g_OctoberBag_Select == 3 then
		OctoberBag_HaveText:SetToolTip("#{GQHY_190723_24}")
		OctoberBag_CoinText:SetText("#{GQHY_190723_91}")
		OctoberBag_CoinText:Hide()-- 策划亲说先隐藏
	end
	
	-- 代币消耗
	OctoberBag_MoneyText : SetText("#{GQHY_190723_82}")
	OctoberBag_MoneyIcon : SetProperty("Image",g_OctoberBag_Icon[g_OctoberBag_Select])	
	local cost = OctoberBag_GetCost()
	local strcount = ScriptGlobal_Format("#{GQHY_190723_83}", cost)
	OctoberBag_MoneyText1_1:SetText(strcount)	
	
end

-- 帮助按钮
function OctoberBag_Help_Click()
	PushEvent("CCSHOP_HELP", 103)
end

-- 显示宝袋数据
function OctoberBag_ShowFrame(nType)

	--是否当前有已选择的道具
	if nType >=1 and nType <=3 then
	
		-- 上次还有未保存道具
		local nSelectNum = 0;		
		for i = 1,30 do
			if g_OctoberBag_ShowItemInfo[i].disable == 1 then
				nSelectNum = nSelectNum + 1
			end
		end		
		if nSelectNum > 0 then	
			if g_OctoberBag_Select == nType then
				return
			end
			g_OctoberBag_Fenye[g_OctoberBag_Select]:SetCheck(1)
			g_OctoberBag_SaveFrame = nType
			PushEvent("GQHYCHOUJIANG_CONFIRM", 2,"#{GQHY_190723_84}")		
			return 
		end
	
		-- 填充数据
		OctoberBag_CleanData()
		local ShowIndex = 1
		local myBagIndex = 1
		local strImage = OctoberBag_GetImage(nType)		
		local nCount = Lua_GetGQHYChouJiangCount()
		for i = 1, nCount do
			local bonusId,poolId,ShowItemId,ItemCount = Lua_GetGQHYChouJiangInfo(i)
			if bonusId > 0 then
				if poolId == nType then
					local theAction = DataPool:CreateActionItemForShow(ShowItemId, ItemCount)					
					g_OctoberBag_ShowItemInfo[ShowIndex].ActionButton:SetActionItem(theAction:GetID())
					g_OctoberBag_ShowItemInfo[ShowIndex].actionid = theAction:GetID()
					g_OctoberBag_ShowItemInfo[ShowIndex].bonusId = bonusId
					g_OctoberBag_ShowItemInfo[ShowIndex].BKImage:SetProperty("Image",strImage)
					if Lua_HasSelectedGQHYChouJiang(bonusId) == 1 then
						g_OctoberBag_ShowItemInfo[ShowIndex].CheckMark:Show()
						myBagIndex = myBagIndex+1
					end
					ShowIndex = ShowIndex+1
				end
			end
		end
		g_OctoberBag_CurCount = myBagIndex
		g_OctoberBag_Select = nType;
		g_OctoberBag_Fenye[g_OctoberBag_Select]:SetCheck(1)
		--g_OctoberBag_Tips[g_OctoberBag_Select]:Hide()
		--OctoberBag_TitlePic:SetProperty("Image",g_OctoberBag_SubTitle[nType])
		OctoberBag_HaveIcon:Show()
		OctoberBag_HaveIcon:SetProperty("Image",g_OctoberBag_Icon[nType])
		OctoberBag_Button1:Disable();
		OctoberBag_Button1:Show()
		OctoberBag_NumText:Show()
		OctoberBag_HaveText:Show()
		OctoberBag_MoneyText:Show()
		OctoberBag_MoneyIcon:Show()
		OctoberBag_MoneyText1_1:Show()
		--有可以选择的显示文字
		--local maxnum = OctoberBag_GetMaxNum(g_OctoberBag_Select)
		--local myCurrency = Lua_GetMyGQHYChouJiangCurrency(g_OctoberBag_Select-1)
		--if g_OctoberBag_CurCount > maxnum or myCurrency < g_OctoberBag_Cost[g_OctoberBag_Select] then
		--	OctoberBag_NextInfoText:Hide()
		--	OctoberBag_NextInfoTextBK:Hide()		
		--else
			OctoberBag_NextInfoText:Show()
			OctoberBag_NextInfoText:SetText("#{GQHY_190723_80}")
			OctoberBag_NextInfoTextBK:Show()		
		--end		
		-- 更新代币数据
		OctoberBag_UpDataCurrency()
		
	elseif nType == 4 then

		-- 上次还有未保存道具
		local nSelectNum = 0;		
		for i = 1,30 do
			if g_OctoberBag_ShowItemInfo[i].disable == 1 then
				nSelectNum = nSelectNum + 1
			end
		end		
		if nSelectNum > 0 then	
			if g_OctoberBag_Select == nType then
				return
			end
			g_OctoberBag_Fenye[g_OctoberBag_Select]:SetCheck(1)
			g_OctoberBag_SaveFrame = nType
			PushEvent("GQHYCHOUJIANG_CONFIRM", 2,"#{GQHY_190723_84}")		
			return 
		end
		
		-- 填充数据
		OctoberBag_CleanData()
		for i = 1,30 do
			local bonusId = Lua_GetMyGQHYChouJiangItem(i-1)
			if bonusId > 0 then
				local poolId,ShowItemId,ItemCount = Lua_GetGQHYChouJiangInfoByBonusId(bonusId)
				local theAction = DataPool:CreateActionItemForShow(ShowItemId, ItemCount)
				g_OctoberBag_ShowItemInfo[i].ActionButton:SetActionItem(theAction:GetID())	
				local strImage = OctoberBag_GetImage(poolId)
				g_OctoberBag_ShowItemInfo[i].BKImage:SetProperty("Image",strImage)
			end
		end
		g_OctoberBag_Select = nType
		g_OctoberBag_Fenye[g_OctoberBag_Select]:SetCheck(1)
		g_OctoberBag_Tips[g_OctoberBag_Select]:Hide()
		--OctoberBag_TitlePic:SetProperty("Image",g_OctoberBag_SubTitle[nType])
		OctoberBag_Button1:Disable();
		OctoberBag_Button1:Hide()
		OctoberBag_HaveIcon:Hide()
		OctoberBag_NumText:Hide()
		OctoberBag_HaveText:Hide()
		OctoberBag_MoneyText:Hide()
		OctoberBag_MoneyIcon:Hide()
		OctoberBag_MoneyText1_1:Hide()
		OctoberBag_CoinText:Hide()
		OctoberBag_NextInfoText:Show()
		OctoberBag_NextInfoText:SetText("#{GQHY_190723_81}")
		OctoberBag_NextInfoTextBK:Show()
	end
	
end

-- 关注npc
function OctoberBag_CareObj()
	if(tonumber(arg0) ~= g_objCareID) then
		return;
	end
	--如果和NPC的距离大于一定距离或者被删除，自动关闭
	if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
		--取消关心
		OctoberBag_StopCareObject(g_objCareID)
		OctoberBag_On_Hide()
	end		
end

-- 关注npc
function OctoberBag_StopCareObject(objCaredId)
	this:CareObject(objCaredId, 0, "OctoberBag");
	g_objCareID = -1;
end

-- 关注npc
function OctoberBag_BeginCareObject(objid)
	g_Object = objid
	this:CareObject(g_Object, 1, "OctoberBag");
end

-- 重置
function OctoberBag_On_ResetPos()
	OctoberBag_Frame:SetProperty("UnifiedPosition", g_OctoberBag_Frame_UnifiedPosition)
end

-- 隐藏
function OctoberBag_On_Hide()
	this:Hide()
end

-- 选中道具检测
function OctoberBag_InsertCheck(index)

	-- 等级
	local nLevel = Player:GetLevel();
	if nLevel < g_OctoberBag_LimitLevel then
		PushDebugMessage("#{GQHY_190723_53}")
		return 0
	end
	
	-- 活动时间
	local curday = DataPool:GetServerDayTime()
	if curday < g_OctoberBag_BeginDay or curday > g_OctoberBag_EndDay then
		PushDebugMessage("#{GQHY_190723_54}")
		return 0	
	end
	
	if g_OctoberBag_ShowItemInfo[index] == nil then
		return 0
	end

	if g_OctoberBag_ShowItemInfo[index].actionid < 0 then
		return 0
	end
	
	-- 已选择
	local bonusId = g_OctoberBag_ShowItemInfo[index].bonusId
	if(Lua_HasSelectedGQHYChouJiang(bonusId) == 1 ) then
		PushDebugMessage("#{GQHY_190723_50}")
		return 0
	end
	
	-- 正选择中
	if g_OctoberBag_ShowItemInfo[index].disable == 1 then
		PushDebugMessage("#{GQHY_190723_50}")
		return 0	
	end
	
	-- 已达宝袋道具上限
	local maxnum = OctoberBag_GetMaxNum(g_OctoberBag_Select);
	local str = OctoberBag_GetBagstr()
	if g_OctoberBag_MyBag_Count > maxnum or g_OctoberBag_CurCount > maxnum then
		PushDebugMessage(ScriptGlobal_Format("#{GQHY_190723_51}",str))		
		return 0
	end
	
	-- 代币不足
	local nSelectCount = g_OctoberBag_MyBag_Count-g_OctoberBag_CurCount
	local cost = OctoberBag_GetCost()
	local myCurrency = Lua_GetMyGQHYChouJiangCurrency(g_OctoberBag_Select-1)
	local curStr = OctoberBag_GetCurrencyStr()
	if cost > myCurrency then	
		PushDebugMessage(ScriptGlobal_Format("#{GQHY_190723_52}",curStr))
		return 0
	end	
	local nSelectNum = 0
	for i = 1,30 do
		if g_OctoberBag_ShowItemInfo[i].disable == 1 then
			nSelectNum = nSelectNum + 1
		end
	end
	if cost*(nSelectNum+1) > myCurrency then
		PushDebugMessage(ScriptGlobal_Format("#{GQHY_190723_52}",curStr))
		return 0
	end	
	
	return 1
	
end

-- 消耗代币
function OctoberBag_GetCost()
	local cost = 0
	if g_OctoberBag_Cost[g_OctoberBag_Select] ~= nil then
		return g_OctoberBag_Cost[g_OctoberBag_Select]
	end
	return cost
end

-- 每种宝藏可选数量上限
function OctoberBag_GetMaxNum(nType)
	local maxnum = 0
	if nType == 1 then
		maxnum = 15
	elseif nType == 2 then
		maxnum = 10
	elseif nType == 3 then
		maxnum = 5
	end	
	return maxnum;
end

-- 获得宝袋名称
function OctoberBag_GetBagstr()
	local str = " "
	if g_OctoberBag_Select == 1 then
		str = "#{GQHY_190723_87}"
	elseif g_OctoberBag_Select == 2 then
		str = "#{GQHY_190723_86}"
	elseif g_OctoberBag_Select == 3 then
		str = "#{GQHY_190723_85}"
	end	
	return str;
end

-- 获得宝藏背景图
function OctoberBag_GetImage(nType)
	local strImage = ""
	if nType == 1 then
		strImage= "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_TongBK"
	elseif nType == 2 then
		strImage= "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_YinBK"
	elseif nType == 3 then
		strImage= "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_JinBK"
	end
	return strImage	
end

-- 获得代币名称
function OctoberBag_GetCurrencyStr()
	local str = " "
	if g_OctoberBag_Select == 1 then
		str = "#{GQHY_190723_94}"
	elseif g_OctoberBag_Select == 2 then
		str = "#{GQHY_190723_93}"
	elseif g_OctoberBag_Select == 3 then
		str = "#{GQHY_190723_92}"
	end	
	return str;
end

-- 更新确认选择按钮状态
function OctoberBag_UpdataMyBag()
		
	local mystart = g_OctoberBag_CurCount		
	
	for i = 1,30 do
		if g_OctoberBag_ShowItemInfo[i].disable == 1 then
			mystart = mystart + 1			
		end
	end
	
	g_OctoberBag_MyBag_Count = mystart
	
	local nSelectCount = g_OctoberBag_MyBag_Count-g_OctoberBag_CurCount
	if nSelectCount > 0 then
		OctoberBag_Button1:Enable();
	else
		OctoberBag_Button1:Disable();
	end
		
end

-- 选中第四个页签--我的包袋
function OctoberBag_Button_Clicked()
	OctoberBag_ShowFrame(4)
end

-- 选中道具
function OctoberBag_ShowItem_Clicked(index)

	-- 三种选择池
	if g_OctoberBag_Select > 3 then
		return
	end
	
	-- 在已经选好的里面
	local bonusId = g_OctoberBag_ShowItemInfo[index].bonusId
	if(Lua_HasSelectedGQHYChouJiang(bonusId) == 1 ) then
		PushDebugMessage("#{GQHY_190723_50}")
		return 0
	end
	
	-- 选择检测
	if g_OctoberBag_ShowItemInfo[index].disable == 1 then
		--蒙红状态，再点击取消蒙红
	else
		if OctoberBag_InsertCheck(index) ~= 1 then
			return
		end
		if g_OctoberBag_MyBag_Count > 30 or  g_OctoberBag_CurCount > 30 then
			--已经选满了
			return
		end
	end
	
	-- 更新当次道具选中标记及确认选择按钮状态
	if g_OctoberBag_ShowItemInfo[index].CheckMark:IsVisible() == false then
		if(g_OctoberBag_ShowItemInfo[index].disable == 1) then
			g_OctoberBag_ShowItemInfo[index].Mask:Hide()
			g_OctoberBag_ShowItemInfo[index].disable = 0
		else
			g_OctoberBag_ShowItemInfo[index].Mask:Show()
			g_OctoberBag_ShowItemInfo[index].disable = 1
		end		
		OctoberBag_UpdataMyBag()		
	end	

end

-- 确认选择按钮逻辑
function OctoberBag_Button1_Clicked()

	-- 统计选中道具
	local nSelectNum = 0;		
	for i = 1,30 do
		if g_OctoberBag_ShowItemInfo[i].disable == 1 then
			nSelectNum = nSelectNum + 1
		end
	end
		
	-- 未选中任何道具
	if nSelectNum == 0 then
		PushDebugMessage("#{GQHY_190723_56}")
		return 0		
	end
		
	-- 代币不足
	local cost = OctoberBag_GetCost()
	local myCurrency = Lua_GetMyGQHYChouJiangCurrency(g_OctoberBag_Select-1)	
	local curstr = OctoberBag_GetCurrencyStr()
	if cost*nSelectNum > myCurrency then
		--PushDebugMessage(ScriptGlobal_Format("#{GQHY_190723_57}",curstr))
		PushDebugMessage("#{GQHY_190723_57}")
		return 0
	end
	
	--二次确认
	local curstr = OctoberBag_GetBagstr()
	local str = ScriptGlobal_Format("#{GQHY_190723_58}",curstr,nSelectNum)		
	PushEvent("GQHYCHOUJIANG_CONFIRM", 0, str)

end

-- 确认选择的二次确认
function OctoberBag_AfterConfirm()
	
	-- 清空选中数据
	Lua_GQHYChouJiangClean();
		
	-- 统计选中道具
	local nSelectNum = 0;
	for i = 1,30 do
		if g_OctoberBag_ShowItemInfo[i].disable == 1 then
			Lua_GQHYChouJiangAddItem(nSelectNum,g_OctoberBag_ShowItemInfo[i].bonusId)
			nSelectNum = nSelectNum + 1
		end
	end
		
	-- 未选中任何道具
	if nSelectNum == 0 then
		PushDebugMessage("#{GQHY_190723_56}")
		return 0		
	end
	
	-- 代币不足
	local cost = OctoberBag_GetCost()
	local myCurrency = Lua_GetMyGQHYChouJiangCurrency(g_OctoberBag_Select-1)	
	local curstr = OctoberBag_GetCurrencyStr()
	if cost*nSelectNum > myCurrency then
		--PushDebugMessage(ScriptGlobal_Format("#{GQHY_190723_57}",curstr))
		PushDebugMessage("#{GQHY_190723_57}")
		return 0
	end
		
	-- 通知到服务器
	Lua_GQHYChouJiangSendInsert(g_OctoberBag_Select,nSelectNum);
	
end

