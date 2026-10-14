--【2021Q2】御猫探宝玩法
-- 御猫派遣界面

local g_Frame_UnifiedPosition

--时间+等级
local g_StartDay = 20210715
local g_EndDay = 20210801
local g_LevelLimit = 30

-- 上方奖励图标
local g_PrizeNum = 5
local g_PrizeListCtrl = {}

-- 下方御猫图标
local g_CatNum = 3
local g_CatId = {0,0,0,}
local g_CatIndex = {0,0,0,}
local g_CatListCtrl = {}
local g_CatBkListCtrl = {}
local g_CatBtnCtrl = {}

-- 右侧列表
local g_BarList = {}
local g_RealCount = 0

-- 当前任务
local g_MissionIndex = 0
-- 任务上限
local g_MissionCount = 5
-- 任务名字
local g_MissionName = 
{
	"set:CatGift2 image:CatGift_Team_1",
	"set:CatGift1 image:CatGift_Team_5",
	"set:CatGift2 image:CatGift_Team_3",
	"set:CatGift1 image:CatGift_Team_4",
	"set:CatGift2 image:CatGift_Team_2",
}

--条件列表
local g_ConditionList = 
{
	[1] = { catlevel = 1, catnum = 1, catid = -1, tips1="#{YMTB_210520_40}", strnum1="#{YMTB_210520_58}", tips2="#{YMTB_210520_49}", strnum2="#{YMTB_210520_67}", },--需要1只橙色品质猫猫
	[2] = { catlevel = 2, catnum = 1, catid = -1, tips1="#{YMTB_210520_41}", strnum1="#{YMTB_210520_59}", tips2="#{YMTB_210520_50}", strnum2="#{YMTB_210520_68}", },--需要1只紫色品质猫猫
	[3] = { catlevel = 2, catnum = 2, catid = -1, tips1="#{YMTB_210520_42}", strnum1="#{YMTB_210520_60}", tips2="#{YMTB_210520_51}", strnum2="#{YMTB_210520_69}", },--需要2只紫色品质猫猫
	[4] = { catlevel = 3, catnum = 1, catid = -1, tips1="#{YMTB_210520_43}", strnum1="#{YMTB_210520_61}", tips2="#{YMTB_210520_52}", strnum2="#{YMTB_210520_70}", },--需要1只普通品质猫猫
	[5] = { catlevel = 3, catnum = 3, catid = -1, tips1="#{YMTB_210520_44}", strnum1="#{YMTB_210520_62}", tips2="#{YMTB_210520_53}", strnum2="#{YMTB_210520_71}", },--需要3只普通品质猫猫
	[6] = { catlevel = 2, catnum = 1, catid = 5, tips1="#{YMTB_210520_45}", strnum1="#{YMTB_210520_63}", tips2="#{YMTB_210520_54}", strnum2="#{YMTB_210520_72}", },--需要1只紫色猫1
	[7] = { catlevel = 2, catnum = 1, catid = 6, tips1="#{YMTB_210520_46}", strnum1="#{YMTB_210520_64}", tips2="#{YMTB_210520_55}", strnum2="#{YMTB_210520_73}", },--需要1只紫色猫2
	[8] = { catlevel = 2, catnum = 1, catid = 7, tips1="#{YMTB_210520_47}", strnum1="#{YMTB_210520_65}", tips2="#{YMTB_210520_56}", strnum2="#{YMTB_210520_74}", },--需要1只紫色猫3
	[9] = { catlevel = 2, catnum = 1, catid = 8, tips1="#{YMTB_210520_48}", strnum1="#{YMTB_210520_66}", tips2="#{YMTB_210520_57}", strnum2="#{YMTB_210520_75}", },--需要1只紫色猫4
}

--任务奖励
local g_PrizeList = 
{-- 1极品 2稀有 3-普通
	[1] = { {id=39923449,num=200,},{id=39923445,num=5,},{id=38005355,num=1,},{id=39923434,num=1,},{id=39923452,num=1,}, },
	[2] = { {id=39923449,num=80,},{id=39923445,num=3,},{id=38005355,num=1,}, },
	[3] = { {id=39923449,num=50,},{id=39923445,num=1,},{id=38005355,num=1,}, },
}

--=========
-- PreLoad()
--=========
function CatGift_Team_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function CatGift_Team_OnLoad()
	
	g_Frame_UnifiedPosition = CatGift_Team_Frame:GetProperty("UnifiedPosition")
		
	g_PrizeListCtrl = { CatGift_Team_Item1, CatGift_Team_Item2, CatGift_Team_Item3, CatGift_Team_Item4, CatGift_Team_Item5, }	
	g_CatListCtrl = { CatGift_Team_Cat1, CatGift_Team_Cat2, CatGift_Team_Cat3, }
	g_CatBkListCtrl = {	CatGift_Team_CatBK1, CatGift_Team_CatBK2, CatGift_Team_CatBK3, }
	g_CatBtnCtrl = {	CatGift_Team_Cat1_SZ, CatGift_Team_Cat2_SZ, CatGift_Team_Cat3_SZ, }

end

--=========
-- Event
--=========
function CatGift_Team_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88843802) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			if (this:IsVisible()) then
				CatGift_Team_Close()
			end
			g_MissionIndex = Get_XParam_INT(1)
			CatGift_Team_Open()
		elseif bShow == 2 then		
			CatGift_Team_Close()
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		CatGift_Team_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		CatGift_Team_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		CatGift_Team_On_ResetPos()

	end
end


function CatGift_Team_Close()
	g_BarList = {}	
	g_RealCount = 0
	CatGift_Team_Free_Lace:Clear()
	this:Hide()
end

--=========
-- 重置
--=========
function CatGift_Team_On_ResetPos()

	CatGift_Team_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function CatGift_Team_Open()

	if g_MissionIndex <= 0 or g_MissionIndex > g_MissionCount then
		return
	end
	local bRet,missionId,missionState,_,_,_,_ = DataPool:Lua_GetCatMissionDataByIndex(g_MissionIndex-1)
	if bRet == nil or bRet ~= 1 or missionId <= 0 or missionState > 0 then
		return
	end		
	local bRet1, szName, nLevel = DataPool:Lua_GetCatMissionInfoByMissionId(missionId)
	if bRet1 == nil or bRet1 ~= 1 or nLevel <= 0 then
		return
	end
	local bRet2, nCon1, nCon2, nCon3, nCon4 = DataPool:Lua_GetCatMissionConditionByMissionId(missionId)
	if bRet2 == nil or bRet2 ~= 1 or nCon1 <= 0 then
		return
	end
		
	-- 任务名
	CatGift_Team_leftbk:SetProperty("Image", g_MissionName[g_MissionIndex])
	
	-- 右侧列表
	CatGift_Team_ShowCatList()
	
	-- 任务奖励
	CatGift_Team_InitPrize(nLevel)
	
	-- 上阵御猫
	g_CatId = {0,0,0}
	g_CatIndex = {0,0,0}
	CatGift_Team_InitPaiQianCat()
	CatGift_Team_UpdateCondition(nCon1,nCon2,nCon3,nCon4)

	-- 显示界面	
	this:Show()
	
end	

--=========
-- 列表排序
--=========
function CatGift_Team_SortFunc(a,b)
	if a.catlevel ~= b.catlevel then
		return (a.catlevel < b.catlevel)
	end
	return (a.catid < b.catid)
end

--=========
-- 显示御猫列表
--=========
function CatGift_Team_ShowCatList()

	-- 获得排序列表
	local sortList = {}
	local nCount = DataPool:LuaFnGetFindCatTableCount(2)
	for idx = 1, nCount do
		local catCount, _, catName, catIcon, catLevel, catLihui, catLihui1, catLihui2 = DataPool:LuaFnGetFindCatTableInfo(2, idx)
		if catCount > 0 then
			table.insert(sortList, {catid=idx,catlevel=catLevel,catcount=catCount,catname=catName,catlihui1=catLihui1,catlihui2=catLihui2})
		end
	end
	table.sort(sortList,CatGift_Team_SortFunc)

	-- 加入数据
	g_BarList = {}
	g_RealCount = 0
	CatGift_Team_Free_Lace:Clear()
	--CatGift_Team_Free_Lace:SetProperty("VScrollMode", "Hide")
	for i = 1, table.getn(sortList) do
		local tData = sortList[i]
		if tData ~= nil then
			for j=1, tData.catcount do
				g_RealCount = g_RealCount + 1
				local bar = CatGift_Team_Free_Lace:AddChild("CatGift_Team_Free_Cat1")			
				bar:GetSubItem("CatGift_Team_Free_Cat1_Head"):SetProperty("Image", tData.catlihui1)
				bar:GetSubItem("CatGift_Team_Free_Cat1_Btn"):Show()
				bar:GetSubItem("CatGift_Team_Free_Cat1_Return_Btn"):Hide()					
				bar:SetSubItemEvent("CatGift_Team_Free_Cat1_Btn", "Clicked", "CatGift_Team_Clicked("..g_RealCount..")")	
				bar:SetSubItemEvent("CatGift_Team_Free_Cat1_Return_Btn", "Clicked", "CatGift_Team_Clicked("..g_RealCount..")")	
				table.insert(g_BarList, {ctrl=bar,index=g_RealCount,catid=tData.catid,catlevel=tData.catlevel,catname=tData.catname,catlihui1=tData.catlihui1,catlihui2=tData.catlihui2,state=0})
			end
		end
	end
	
end

--=========
-- 显示奖励
--=========
function CatGift_Team_InitPrize(nLevel)
	-- 图标特写
	CatGift_Team_ItemPlus3:Show()
	CatGift_Team_ItemPlus4:Hide()
	CatGift_Team_ItemPlus5:Hide()
	-- 显示奖励图标
	local tPrize = g_PrizeList[nLevel]
	if tPrize ~= nil then
		for i=1, g_PrizeNum do
			local tItem = tPrize[i]
			if tItem ~= nil then
				-- 奖励图标
				local theAction = DataPool:CreateActionItemForShow(tItem.id, tItem.num)
				if theAction:GetID() ~= 0 then
					-- 奖励
					g_PrizeListCtrl[i]:SetActionItem(theAction:GetID())
					-- 概率图标特写
					if i == 4 then
						CatGift_Team_ItemPlus4:Show()
					elseif i == 5 then
						CatGift_Team_ItemPlus5:Show()
					end
				end
			else
				g_PrizeListCtrl[i]:SetActionItem(-1)
			end
		end
	end
end

--=========
-- 初始化上阵猫猫
--=========
function CatGift_Team_InitPaiQianCat()
	for i=1, g_CatNum do
		g_CatBkListCtrl[i]:Show()
		g_CatListCtrl[i]:Hide()
		g_CatBtnCtrl[i]:Hide()
	end
end

--=========
-- 获得上阵空位
--=========
function CatGift_Team_GetCatNullPos()
	for i=1, g_CatNum do
		if g_CatId[i] <= 0 then
			return i
		end
	end
	return 0
end

--=========
-- 获得上阵猫猫
--=========
function CatGift_Team_GetCatPos(catIndex)
	if catIndex == nil or catIndex <= 0 then
		return 0
	end
	for i=1, g_CatNum do
		if g_CatIndex[i] == catIndex then
			return i
		end
	end
	return 0
end

--=========
-- 获得指定id的上阵猫猫数量
--=========
function CatGift_Team_GetCatNumById(nCatId)
	if nCatId == nil or nCatId <= 0 then
		return 0
	end
	local nCount = 0
	for i=1, g_CatNum do
		if g_CatId[i] == nCatId then
			nCount = nCount + 1
		end
	end
	return nCount
end

--=========
-- 获得指定等级的上阵猫猫数量
--=========
function CatGift_Team_GetCatNumByLevel(nCatLevel)
	if nCatLevel == nil or nCatLevel <= 0 then
		return 0
	end
	local nCount = 0
	for i=1, g_CatNum do
		if g_CatId[i] > 0 then
			local catCount, _, catName, catIcon, catLevel, catLihui, catLihui1, catLihui2 = DataPool:LuaFnGetFindCatTableInfo(2, g_CatId[i])
			if catCount > 0 and catLevel == nCatLevel then
				nCount = nCount + 1
			end
		end
	end
	return nCount
end

--=========
-- 计算任务条件
--=========
function CatGift_Team_GetConditionStr(nConIndex)
	if nConIndex == nil or nConIndex <= 0 then
		return -1,"",""
	end
	
	local tCondition = g_ConditionList[nConIndex]
	if tCondition == nil then
		return -1,"",""
	end
	
	-- 指定猫猫
	if tCondition.catid > 0 then
		local nCount = CatGift_Team_GetCatNumById(tCondition.catid)
		if nCount >= tCondition.catnum then
			return 1, tCondition.tips2, ScriptGlobal_Format(tCondition.strnum2, tCondition.catnum)
		else
			return 0, tCondition.tips1, ScriptGlobal_Format(tCondition.strnum1, nCount)
		end
	-- 指定等级
	elseif tCondition.catlevel > 0 then
		local nCount = CatGift_Team_GetCatNumByLevel(tCondition.catlevel)
		if nCount >= tCondition.catnum then
			return 1, tCondition.tips2, ScriptGlobal_Format(tCondition.strnum2, tCondition.catnum)
		else
			return 0, tCondition.tips1, ScriptGlobal_Format(tCondition.strnum1, nCount)
		end
	end
	
	return -1,"",""	
end

--=========
-- 显示条件
--=========
function CatGift_Team_UpdateCondition(nCon1,nCon2,nCon3,nCon4)
	--必要条件
	local textCtrl1 = nil
	local numberCtrl1 = nil
	if nCon1 > 0 and nCon2 > 0 then
		CatGift_Team_TextBK1_1:Show()
		CatGift_Team_TextBK1_2:Hide()
		textCtrl1 = CatGift_Team_Text1
		numberCtrl1 = CatGift_Team_Text1_Number
	else
		CatGift_Team_TextBK1_1:Hide()
		CatGift_Team_TextBK1_2:Show()
		textCtrl1 = CatGift_Team_Text5
		numberCtrl1 = CatGift_Team_Text5_Number
	end
	local flag1 = 0
	local strCon1 = ""
	local strCon11 = ""
	if nCon1 > 0 then
		flag1,strCon1,strCon11 = CatGift_Team_GetConditionStr(nCon1)
		if flag1 >= 0 and strCon1 ~= nil and strCon11 ~= nil then
			textCtrl1:SetText(strCon1)
			numberCtrl1:SetText(strCon11)
		end
	end
	local flag2 = 0
	local strCon2 = ""
	local strCon22 = ""
	if nCon2 > 0 then
		flag2,strCon2,strCon22 = CatGift_Team_GetConditionStr(nCon2)
		if flag2 >= 0 and strCon2 ~= nil and strCon22 ~= nil then
			CatGift_Team_Text2:SetText(strCon2)
			CatGift_Team_Text2_Number:SetText(strCon22)
		end
	end
	--加分条件
	local textCtrl3 = nil
	local numberCtrl3 = nil
	if nCon3 > 0 and nCon4 > 0 then
		CatGift_Team_TextBK2_1:Show()
		CatGift_Team_TextBK2_2:Hide()
		textCtrl3 = CatGift_Team_Text3
		numberCtrl3 = CatGift_Team_Text3_Number
	elseif nCon3 > 0 then
		CatGift_Team_TextBK2_1:Hide()
		CatGift_Team_TextBK2_2:Show()
		textCtrl3 = CatGift_Team_Text6
		numberCtrl3 = CatGift_Team_Text6_Number
	else
		CatGift_Team_TextBK2_1:Hide()
		CatGift_Team_TextBK2_2:Hide()
	end
	local flag3 = 0
	local strCon3 = ""
	local strCon33 = ""
	if nCon3 > 0 then
		flag3,strCon3,strCon33 = CatGift_Team_GetConditionStr(nCon3)
		if flag3 >= 0 and strCon3 ~= nil and strCon33 ~= nil then
			textCtrl3:SetText(strCon3)
			numberCtrl3:SetText(strCon33)
		end
	end
	local flag4 = 0
	local strCon4 = ""
	local strCon44 = ""
	if nCon4 > 0 then
		flag4,strCon4,strCon44 = CatGift_Team_GetConditionStr(nCon4)
		if flag4 >= 0 and strCon4 ~= nil and strCon44 ~= nil then
			CatGift_Team_Text4:SetText(strCon4)
			CatGift_Team_Text4_Number:SetText(strCon44)
		end
	end

	-- 满足基本条件
	if ( nCon1 > 0 and flag1 == 1) and ( nCon2 <= 0 or ( nCon2 > 0 and flag2 == 1) ) then
		CatGift_Team_OK:Enable()
	else
		CatGift_Team_OK:Disable()
	end
		
	-- 满足加分条件
	--if ( nCon3 > 0 and flag3 == 1 ) and ( nCon4 <= 0 or ( nCon4 > 0 and flag4 == 1) ) then
	--	CatGift_Team_ItemPlus3:Show()
	--else
	--	CatGift_Team_ItemPlus3:Hide()
	--end
	if nCon3 > 0 then
		CatGift_Team_ItemPlus3:Show()
	else
		CatGift_Team_ItemPlus3:Hide()
	end
end

--=========
-- 计算任务条件
--=========
function CatGift_Team_GetConditionValid(nConIndex, nCatId, nCatLevel)
	if nConIndex == nil or nConIndex <= 0 then
		return 0
	end
	
	local tCondition = g_ConditionList[nConIndex]
	if tCondition == nil then
		return 0
	end
	
	if nCatId == nil or nCatId <= 0 or nCatLevel == nil or nCatLevel <= 0 then
		return 0
	end
	
	-- 指定猫猫
	if tCondition.catid > 0 then
		if nCatId == tCondition.catid then--匹配到id
			local nCount = CatGift_Team_GetCatNumById(tCondition.catid)
			if nCount < tCondition.catnum then
				return 1
			end
		end
	-- 指定等级
	elseif tCondition.catlevel > 0 then
		if nCatLevel == tCondition.catlevel then--匹配到level
			local nCount = CatGift_Team_GetCatNumByLevel(tCondition.catlevel)
			if nCount < tCondition.catnum then
				return 1
			end
		end
	end
	
	return 0
	
end

--=========
-- 检测条件
--=========
function CatGift_Team_CheckCondition(nCon1,nCon2,nCon3,nCon4,nCatId,nCatLevel)
	if nCatId == nil or nCatId <= 0 or nCatLevel == nil or nCatLevel <= 0 then
		return 0
	end
	if nCon1 <= 0 then
		return 0
	end
	
	-- 先判断必要条件1
	local bValid1 = CatGift_Team_GetConditionValid(nCon1, nCatId, nCatLevel)
	if bValid1 == 1 then
		return 1
	end
	
	-- 再判断必要条件2
	if nCon2 > 0 then
		local bValid2 = CatGift_Team_GetConditionValid(nCon2, nCatId, nCatLevel)
		if bValid2 == 1 then
			return 1
		end	
	end
	
	-- 再判断加分条件3
	if nCon3 > 0 then
		-- 存在加分条件4--特写
		if nCon4 > 0 then
			local bValid4 = CatGift_Team_GetConditionValid(nCon4, nCatId, nCatLevel)
			if bValid4 == 1 then--先满足条件4
				local tCondition = g_ConditionList[nCon3]
				if tCondition ~= nil and tCondition.catid > 0 then
					local nCount = CatGift_Team_GetCatNumById(tCondition.catid)
					if nCount > 0 or tCondition.catid == nCatId then--已满足条件3或新满足条件3
						return 1
					end
				end
			end
		-- 不存在加分条件4
		else
			local bValid3 = CatGift_Team_GetConditionValid(nCon3, nCatId, nCatLevel)
			if bValid3 == 1 then
				return 1
			end
		end
	end	
	
	return 0	
end

--=========
-- 点击上阵/取消按钮
--=========
function CatGift_Team_Clicked( nIndex )
	if nIndex == nil or nIndex <= 0 or nIndex > g_RealCount or g_RealCount <= 0 then
		return
	end
	
	local ctrlBar = g_BarList[nIndex]
	if ctrlBar == nil then
		return
	end
	if ctrlBar.catid <= 0 or ctrlBar.catlevel <= 0 then
		return
	end
			
	if g_MissionIndex <= 0 or g_MissionIndex > g_MissionCount then
		return
	end
	local bRet,missionId,missionState,_,_,_,_ = DataPool:Lua_GetCatMissionDataByIndex(g_MissionIndex-1)
	if bRet == nil or bRet ~= 1 or missionId <= 0 or missionState > 0 then
		return
	end		
	local bRet1, szName, nLevel = DataPool:Lua_GetCatMissionInfoByMissionId(missionId)
	if bRet1 == nil or bRet1 ~= 1 or nLevel <= 0 then
		return
	end
	local bRet2, nCon1, nCon2, nCon3, nCon4 = DataPool:Lua_GetCatMissionConditionByMissionId(missionId)
	if bRet2 == nil or bRet2 ~= 1 or nCon1 <= 0 then
		return
	end
	
	-- 检测时间和等级
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLevel = Player:GetLevel();
	local rightTime = 0
	if curDay >= g_StartDay and curDay <= g_EndDay then
		rightTime = 1
	end
	local rightLevel = 0
	if nLevel >= g_LevelLimit then
		rightLevel = 1
	end
		
	-- 上阵处理
	if ctrlBar.state == 0 then
		if rightTime ~= 1 then
			PushDebugMessage("#{YMTB_210520_115}")
			CatGift_Team_Close()
			return
		end
		if rightLevel ~= 1 then
			PushDebugMessage("#{YMTB_210520_116}")
			CatGift_Team_Close()
			return
		end
		-- 需要判断上阵位置
		local nPos = CatGift_Team_GetCatNullPos()
		if nPos <= 0 or nPos > g_CatNum then
			PushDebugMessage("#{YMTB_210520_118}")
			return
		end
		-- 不满足上阵条件的猫猫
		if CatGift_Team_CheckCondition(nCon1,nCon2,nCon3,nCon4,ctrlBar.catid,ctrlBar.catlevel) <= 0 then
			PushDebugMessage("#{YMTB_210520_175}")
			return
		end
		-- 修改右侧列表
		ctrlBar.state = 1
		ctrlBar.ctrl:GetSubItem("CatGift_Team_Free_Cat1_Btn"):Hide()
		ctrlBar.ctrl:GetSubItem("CatGift_Team_Free_Cat1_Return_Btn"):Show()
		-- 修改上阵御猫
		g_CatId[nPos] = ctrlBar.catid
		g_CatIndex[nPos] = nIndex
		g_CatListCtrl[nPos]:SetProperty("Image", ctrlBar.catlihui2)
		g_CatListCtrl[nPos]:Show()
		g_CatBkListCtrl[nPos]:Hide()
		g_CatBtnCtrl[nPos]:Show()
		-- 修改任务条件+双倍图标
		CatGift_Team_UpdateCondition(nCon1,nCon2,nCon3,nCon4)
		-- 醒目提示
		local tip = ScriptGlobal_Format("#{YMTB_210520_119}", ctrlBar.catname)
		PushDebugMessage(tip)
	-- 下阵处理
	elseif ctrlBar.state == 1 then
		if rightTime ~= 1 then
			PushDebugMessage("#{YMTB_210520_120}")
			CatGift_Team_Close()
			return
		end
		if rightLevel ~= 1 then
			PushDebugMessage("#{YMTB_210520_121}")
			CatGift_Team_Close()
			return
		end
		-- 需要判断下阵位置
		local nPos = CatGift_Team_GetCatPos(nIndex)
		if nPos <= 0 or nPos > g_CatNum then
			return
		end
		-- 修改右侧列表
		ctrlBar.state = 0
		ctrlBar.ctrl:GetSubItem("CatGift_Team_Free_Cat1_Btn"):Show()
		ctrlBar.ctrl:GetSubItem("CatGift_Team_Free_Cat1_Return_Btn"):Hide()
		-- 修改上阵御猫
		g_CatId[nPos] = 0
		g_CatIndex[nPos] = 0
		g_CatListCtrl[nPos]:Hide()
		g_CatBkListCtrl[nPos]:Show()
		g_CatBtnCtrl[nPos]:Hide()
		-- 修改任务条件+双倍图标
		CatGift_Team_UpdateCondition(nCon1,nCon2,nCon3,nCon4)
		-- 醒目提示
		local tip = ScriptGlobal_Format("#{YMTB_210520_123}", ctrlBar.catname)
		PushDebugMessage(tip)
	end
	
end

--=========
-- 点击下阵按钮
--=========
function CatGift_Team_OnClicked( nPos )
	if nPos == nil or nPos <= 0 or nPos > g_CatNum then
		return
	end
	local nCatId = g_CatId[nPos]
	if nCatId == nil or nCatId <= 0 then
		return
	end
	local nIndex = g_CatIndex[nPos]
	if nIndex == nil or nIndex <= 0 then
		return
	end
	local ctrlBar = g_BarList[nIndex]
	if ctrlBar == nil then
		return
	end
	if ctrlBar.catid <= 0 or ctrlBar.catlevel <= 0 or nCatId ~= ctrlBar.catid then
		return
	end
	if g_MissionIndex <= 0 or g_MissionIndex > g_MissionCount then
		return
	end
	local bRet,missionId,missionState,_,_,_,_ = DataPool:Lua_GetCatMissionDataByIndex(g_MissionIndex-1)
	if bRet == nil or bRet ~= 1 or missionId <= 0 or missionState > 0 then
		return
	end		
	local bRet1, szName, nLevel = DataPool:Lua_GetCatMissionInfoByMissionId(missionId)
	if bRet1 == nil or bRet1 ~= 1 or nLevel <= 0 then
		return
	end
	local bRet2, nCon1, nCon2, nCon3, nCon4 = DataPool:Lua_GetCatMissionConditionByMissionId(missionId)
	if bRet2 == nil or bRet2 ~= 1 or nCon1 <= 0 then
		return
	end
		
	-- 时间
	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay < g_StartDay or curDay > g_EndDay then
		PushDebugMessage("#{YMTB_210520_120}")
		CatGift_Team_Close()
		return
	end
	-- 等级
	local nLevel = Player:GetLevel();
	if nLevel < g_LevelLimit then
		PushDebugMessage("#{YMTB_210520_121}")
		CatGift_Team_Close()
		return
	end

	-- 修改右侧列表
	ctrlBar.state = 0
	ctrlBar.ctrl:GetSubItem("CatGift_Team_Free_Cat1_Btn"):Show()
	ctrlBar.ctrl:GetSubItem("CatGift_Team_Free_Cat1_Return_Btn"):Hide()
	-- 修改上阵御猫
	g_CatId[nPos] = 0
	g_CatIndex[nPos] = 0
	g_CatListCtrl[nPos]:Hide()
	g_CatBkListCtrl[nPos]:Show()
	g_CatBtnCtrl[nPos]:Hide()
	-- 修改任务条件+双倍图标
	CatGift_Team_UpdateCondition(nCon1,nCon2,nCon3,nCon4)
	-- 醒目提示
	local tip = ScriptGlobal_Format("#{YMTB_210520_123}", ctrlBar.catname)
	PushDebugMessage(tip)
			
end

--=========
-- 点击派遣
--=========
function CatGift_Team_OnOK(  )
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnPaiQianConfirm" )
		Set_XSCRIPT_ScriptID( 888438 )
		Set_XSCRIPT_Parameter(0,g_MissionIndex)
		Set_XSCRIPT_Parameter(1,g_CatId[1])
		Set_XSCRIPT_Parameter(2,g_CatId[2])
		Set_XSCRIPT_Parameter(3,g_CatId[3])
		Set_XSCRIPT_Parameter(4,0)
		Set_XSCRIPT_ParamCount( 5 )
	Send_XSCRIPT()	

end
