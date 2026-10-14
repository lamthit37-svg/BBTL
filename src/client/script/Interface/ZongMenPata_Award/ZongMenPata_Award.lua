--ZongMenPata_Award.lua
--Prize用到的常量
local g_MAX_LEVEL = 100 --最da阶位
local g_MaxBossNum = 20
local g_PerLevel = 5
local g_MyLevel = 0


--Prize用的全局变量
local g_ZongMenPata_Award_Frame_UnifiedPosition;

local g_ZongMenPata_Award_ActionBtn = {}
local g_PrizeState = {}

local g_IsShowRedPoint = 0

local nFullLevel = 0 --是否满分了

local g_LevelPrizeinfo = {}


--滚动条的位置
local g_Position_Scroll = 0;

local g_TitleShowItemId = {
	[40] = 39924488,
	[50] = 39924502,
	[60] = 39924503,
	[70] = 39924504,
	[80] = 39924489,
	[90] = 39924490,
	[100] = 39924491,
}


local g_ShengMingShowItemId = {

	[80] = 39924492,
	[100] = 39924493,
}

--===============================================
-- PreLoad()
--===============================================
function ZongMenPata_Award_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	this:RegisterEvent("OPEN_ZHANLING")
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")
end

--===============================================
-- OnEvent()
--===============================================
function ZongMenPata_Award_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		ZongMenPata_Award_OnClose()
	elseif event == "ADJEST_UI_POS" then
		ZongMenPata_Award_OnResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZongMenPata_Award_OnResetPos()	
		
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633005) then	--服务端传数据
	
		local prize1_MD = Get_XParam_INT(0) --
		local prize2_MD = Get_XParam_INT(1) --
		g_MyLevel = Get_XParam_INT(2) --
		local prize3_MD = Get_XParam_INT(3) --
		local prize4_MD = Get_XParam_INT(4) --
		g_Position_Scroll = 0
		g_PrizeState = ZongMenPata_Award_GetBitTable(prize1_MD, prize2_MD, prize3_MD, prize4_MD)
		--红点
		if 1 == g_IsShowRedPoint then
		
		end
		
		-- 只有打开页面时刷新页面才记录上一次的滚动条
		g_Position_Scroll = ZongMenPata_Award_List:GetScrollPosition()	--保存上一次滚动条位置
		ZongMenPata_Award_PrizePageOpen()	
		
	end
end



function ZongMenPata_Award_OnLoad()
	g_ZongMenPata_Award_Frame_UnifiedPosition = ZongMenPata_Award_Frame:GetProperty("UnifiedPosition")
end


function ZongMenPata_Award_GetPrizeInfo()
		--获取奖励信息 计算阶位 获取领奖MD
		for i = 1,g_MAX_LEVEL do
			local szBossImage,szSceneImage,szChallengeInfo,
				nShow1,nShow2,nShow3,nShow4,nShow5,
				nItemNum1,nItemNum2,nItemNum3,nItemNum4,nItemNum5
				=Player:GetZMPTUiInfo(i)
			local nZMPTTitleLevel, nZMPTTitleShowItemId =  Player:GetZMPTTitleInfo(i)
			if nil == szBossImage or "" == szBossImage then
				return 0 
			end
			g_LevelPrizeinfo[i] = {}
			g_LevelPrizeinfo[i].nShow1 = nShow1
			g_LevelPrizeinfo[i].nItemNum1 = nItemNum1
			g_LevelPrizeinfo[i].nShow2 = nShow2
			g_LevelPrizeinfo[i].nItemNum2 = nItemNum2
			g_LevelPrizeinfo[i].nShow3 = nShow3
			g_LevelPrizeinfo[i].nItemNum3 = nItemNum3
			g_LevelPrizeinfo[i].nShow4 = nShow4
			g_LevelPrizeinfo[i].nItemNum4 = nItemNum4
			g_LevelPrizeinfo[i].nShow5 = nShow5
			g_LevelPrizeinfo[i].nItemNum5 = nItemNum5
			-- g_LevelPrizeinfo[i].nShow6 = -1
			-- g_LevelPrizeinfo[i].nItemNum6 = -1
			-- g_LevelPrizeinfo[i].nShow7 = -1
			-- g_LevelPrizeinfo[i].nItemNum7 = -1
			g_LevelPrizeinfo[i].szChallengeInfo = "#cfff263"..szChallengeInfo
			if g_LevelPrizeinfo[i].nShow1 == -1 and nZMPTTitleShowItemId ~= -1 then
				g_LevelPrizeinfo[i].nShow1 = nZMPTTitleShowItemId
				g_LevelPrizeinfo[i].nItemNum1 = 1
			elseif g_LevelPrizeinfo[i].nShow2 == -1 and nZMPTTitleShowItemId ~= -1 then
				g_LevelPrizeinfo[i].nShow2 = nZMPTTitleShowItemId
				g_LevelPrizeinfo[i].nItemNum2 = 1
			elseif g_LevelPrizeinfo[i].nShow3 == -1 and nZMPTTitleShowItemId ~= -1 then
				g_LevelPrizeinfo[i].nShow3 = nZMPTTitleShowItemId
				g_LevelPrizeinfo[i].nItemNum3 = 1
			elseif g_LevelPrizeinfo[i].nShow4 == -1 and nZMPTTitleShowItemId ~= -1 then
				g_LevelPrizeinfo[i].nShow4 = nZMPTTitleShowItemId
				g_LevelPrizeinfo[i].nItemNum4 = 1
			elseif g_LevelPrizeinfo[i].nShow5 == -1 and nZMPTTitleShowItemId ~= -1 then
				g_LevelPrizeinfo[i].nShow5 = nZMPTTitleShowItemId
				g_LevelPrizeinfo[i].nItemNum5 = 1
			-- elseif g_LevelPrizeinfo[i].nShow6 == -1 and nZMPTTitleShowItemId ~= -1 then
				-- g_LevelPrizeinfo[i].nShow6 = nZMPTTitleShowItemId
				-- g_LevelPrizeinfo[i].nItemNum6 = 1
			-- elseif g_LevelPrizeinfo[i].nShow7 == -1 and nZMPTTitleShowItemId ~= -1 then
				-- g_LevelPrizeinfo[i].nShow7 = nZMPTTitleShowItemId
				-- g_LevelPrizeinfo[i].nItemNum7 = 1
			end
			if g_TitleShowItemId[i] ~= nil then
				if g_LevelPrizeinfo[i].nShow1 == -1 and g_TitleShowItemId[i] ~= -1 then
					g_LevelPrizeinfo[i].nShow1 = g_TitleShowItemId[i]
					g_LevelPrizeinfo[i].nItemNum1 = 1
				elseif g_LevelPrizeinfo[i].nShow2 == -1 and g_TitleShowItemId[i] ~= -1 then
					g_LevelPrizeinfo[i].nShow2 = g_TitleShowItemId[i]
					g_LevelPrizeinfo[i].nItemNum2 = 1
				elseif g_LevelPrizeinfo[i].nShow3 == -1 and g_TitleShowItemId[i] ~= -1 then
					g_LevelPrizeinfo[i].nShow3 = g_TitleShowItemId[i]
					g_LevelPrizeinfo[i].nItemNum3 = 1
				elseif g_LevelPrizeinfo[i].nShow4 == -1 and g_TitleShowItemId[i] ~= -1 then
					g_LevelPrizeinfo[i].nShow4 = g_TitleShowItemId[i]
					g_LevelPrizeinfo[i].nItemNum4 = 1
				elseif g_LevelPrizeinfo[i].nShow5 == -1 and g_TitleShowItemId[i] ~= -1 then
					g_LevelPrizeinfo[i].nShow5 = g_TitleShowItemId[i]
					g_LevelPrizeinfo[i].nItemNum5 = 1
				-- elseif g_LevelPrizeinfo[i].nShow6 == -1 and g_TitleShowItemId[i] ~= -1 then
					-- g_LevelPrizeinfo[i].nShow6 = g_TitleShowItemId[i]
					-- g_LevelPrizeinfo[i].nItemNum6 = 1
				-- elseif g_LevelPrizeinfo[i].nShow7 == -1 and g_TitleShowItemId[i] ~= -1 then
					-- g_LevelPrizeinfo[i].nShow7 = g_TitleShowItemId[i]
					-- g_LevelPrizeinfo[i].nItemNum7 = 1
				end
			end
			if g_ShengMingShowItemId[i] ~= nil then
				if g_LevelPrizeinfo[i].nShow1 == -1 and g_ShengMingShowItemId[i] ~= -1 then
					g_LevelPrizeinfo[i].nShow1 = g_ShengMingShowItemId[i]
					g_LevelPrizeinfo[i].nItemNum1 = 1
				elseif g_LevelPrizeinfo[i].nShow2 == -1 and g_ShengMingShowItemId[i] ~= -1 then
					g_LevelPrizeinfo[i].nShow2 = g_ShengMingShowItemId[i]
					g_LevelPrizeinfo[i].nItemNum2 = 1
				elseif g_LevelPrizeinfo[i].nShow3 == -1 and g_ShengMingShowItemId[i] ~= -1 then
					g_LevelPrizeinfo[i].nShow3 = g_ShengMingShowItemId[i]
					g_LevelPrizeinfo[i].nItemNum3 = 1
				elseif g_LevelPrizeinfo[i].nShow4 == -1 and g_ShengMingShowItemId[i] ~= -1 then
					g_LevelPrizeinfo[i].nShow4 = g_ShengMingShowItemId[i]
					g_LevelPrizeinfo[i].nItemNum4 = 1
				elseif g_LevelPrizeinfo[i].nShow5 == -1 and g_ShengMingShowItemId[i] ~= -1 then
					g_LevelPrizeinfo[i].nShow5 = g_ShengMingShowItemId[i]
					g_LevelPrizeinfo[i].nItemNum5 = 1
				-- elseif g_LevelPrizeinfo[i].nShow6 == -1 and g_ShengMingShowItemId[i] ~= -1 then
					-- g_LevelPrizeinfo[i].nShow6 = g_ShengMingShowItemId[i]
					-- g_LevelPrizeinfo[i].nItemNum6 = 1
				-- elseif g_LevelPrizeinfo[i].nShow7 == -1 and g_ShengMingShowItemId[i] ~= -1 then
					-- g_LevelPrizeinfo[i].nShow7 = g_ShengMingShowItemId[i]
					-- g_LevelPrizeinfo[i].nItemNum7 = 1
				end
			end
		end
		--end for
		return 1
end

--
function ZongMenPata_Award_PrizePageOpen()	
	if 1 ~= ZongMenPata_Award_GetPrizeInfo() then  --加载奖励表信息
		PushDebugMessage("页面数据加载失败1，请重新打开页面。")
		return
	end
	
	--界面数据
	--阶位赛季信息
	local strTemp = nil
	
	

	--List
	ZongMenPata_Award_ClearRewardList()
	this:Show()
	for j = 1, g_MaxBossNum do
		local bar = ZongMenPata_Award_List:AddChild("ZongMenPata_AwardItem")
		if not bar then 
			break
		end
		local imagebarItem= bar:GetSubItem("ZongMenPata_AwardItem_BK")
		if imagebarItem ~= nil then
			local szBossImage=Player:GetZMPTAwardBossImage(j*g_PerLevel)
			imagebarItem:SetProperty("Image", szBossImage)
		end
		local index = 1
		for i = g_PerLevel*(j-1)+1 , g_PerLevel*j do

			if nil == g_LevelPrizeinfo[i] or nil == g_PrizeState[i] then
				PushDebugMessage("页面数据加载失败2，请重新打开页面。")
				return 
			end 

			
			--ActionItem
			local barItem = nil
			local theAction = nil
			
			barItem= bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Text1")
			if barItem ~= nil then
				barItem:SetText(ScriptGlobal_Format("#{ZMPT_230629_145}", i))
			end
			
			barItem= bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Text2")
			if barItem ~= nil then
				barItem:SetText(g_LevelPrizeinfo[i].szChallengeInfo)
			end
			
			
			
			barItem= bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Item1")
			if g_LevelPrizeinfo[i].nShow1 ~= -1 then
				theAction = DataPool:CreateBindActionItemForShow(g_LevelPrizeinfo[i].nShow1,g_LevelPrizeinfo[i].nItemNum1)
				if theAction:GetID() ~= 0 and barItem ~= nil then
					barItem:SetActionItem(theAction:GetID())
					table.insert( g_ZongMenPata_Award_ActionBtn,barItem)
				else
					barItem:Hide()
				end
			else
				barItem:Hide()
			end
			
			barItem= bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Item2")
			if g_LevelPrizeinfo[i].nShow2 ~= -1 then
				theAction = DataPool:CreateBindActionItemForShow(g_LevelPrizeinfo[i].nShow2,g_LevelPrizeinfo[i].nItemNum2)
				if theAction:GetID() ~= 0 and barItem ~= nil then
					barItem:SetActionItem(theAction:GetID())
					table.insert( g_ZongMenPata_Award_ActionBtn,barItem)
				else
					barItem:Hide()
				end
			else
				barItem:Hide()
			end
			
			barItem= bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Item3")
			if g_LevelPrizeinfo[i].nShow3 ~= -1 then
				theAction = DataPool:CreateBindActionItemForShow(g_LevelPrizeinfo[i].nShow3,g_LevelPrizeinfo[i].nItemNum3)
				if theAction:GetID() ~= 0 and barItem ~= nil then
					barItem:SetActionItem(theAction:GetID())
					table.insert( g_ZongMenPata_Award_ActionBtn,barItem)
				else
					barItem:Hide()
				end
			else
				barItem:Hide()
			end
			
			barItem= bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Item4")
			if g_LevelPrizeinfo[i].nShow4 ~= -1 then
				theAction = DataPool:CreateBindActionItemForShow(g_LevelPrizeinfo[i].nShow4,g_LevelPrizeinfo[i].nItemNum4)
				if theAction:GetID() ~= 0 and barItem ~= nil and  g_LevelPrizeinfo[i].nShow4 ~= -1 then
					barItem:SetActionItem(theAction:GetID())
					table.insert( g_ZongMenPata_Award_ActionBtn,barItem)
				else
					barItem:Hide()
				end
			else
				barItem:Hide()
			end
			
			barItem= bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Item5")
			if g_LevelPrizeinfo[i].nShow5 ~= -1 then
				theAction = DataPool:CreateBindActionItemForShow(g_LevelPrizeinfo[i].nShow5,g_LevelPrizeinfo[i].nItemNum5)
				if theAction:GetID() ~= 0 and barItem ~= nil then
					barItem:SetActionItem(theAction:GetID())
					table.insert( g_ZongMenPata_Award_ActionBtn,barItem)
				else
					barItem:Hide()
				end
			else
				barItem:Hide()
			end
			
			-- barItem= bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Item6")
			-- if g_LevelPrizeinfo[i].nShow6 ~= -1 then
				-- theAction = DataPool:CreateBindActionItemForShow(g_LevelPrizeinfo[i].nShow6,g_LevelPrizeinfo[i].nItemNum6)
				-- if theAction:GetID() ~= 0 and barItem ~= nil then
					-- barItem:SetActionItem(theAction:GetID())
					-- table.insert( g_ZongMenPata_Award_ActionBtn,barItem)
				-- else
					-- barItem:Hide()
				-- end
			-- else
				-- barItem:Hide()
			-- end
			
			-- barItem= bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Item7")
			-- if g_LevelPrizeinfo[i].nShow7 ~= -1 then
				-- theAction = DataPool:CreateBindActionItemForShow(g_LevelPrizeinfo[i].nShow7,g_LevelPrizeinfo[i].nItemNum7)
				-- if theAction:GetID() ~= 0 and barItem ~= nil then
					-- barItem:SetActionItem(theAction:GetID())
					-- table.insert( g_ZongMenPata_Award_ActionBtn,barItem)
				-- else
					-- barItem:Hide()
				-- end
			-- else
				-- barItem:Hide()
			-- end
	
		
			

			--按钮
			local basicButton = bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_GetBtn")
			local basicHaveGetImg = bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_GetMark")
			local basicHotPoint = bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_BtnTips")
			--local basicPassIamge = bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Mark")
			local basicNotRecIamge = bar:GetSubItem("ZongMenPata_AwardItem_BK"..index.."_Lock")
			
			if basicButton and basicHaveGetImg  and basicHotPoint and basicNotRecIamge then
				--button绑定事件
				basicButton:SetEvent("Clicked",string.format( "ZongMenPata_Award_GetPrize(%d)",i))
				if i > g_MyLevel then
					--未达到的阶级
					--basic
					basicButton:Disable()
					basicButton:Hide()
					basicHaveGetImg:Hide()
					basicHotPoint:Hide()
					--basicPassIamge:Hide()
					basicNotRecIamge:Show()

				else
					--已达到的阶级
					if 0 == g_PrizeState[i] then
						basicButton:Enable()
						basicButton:Show()
						basicHaveGetImg:Hide()
						basicHotPoint:Show()
						--basicPassIamge:Show()
						basicNotRecIamge:Hide()
					else
						basicButton:Hide()
						basicHaveGetImg:Show()
						basicHotPoint:Hide()
						--basicPassIamge:Show()
						basicNotRecIamge:Hide()
					end

				end
			end
			index = index + 1
		end
	end
	ZongMenPata_Award_List:SetScrollPosition(g_Position_Scroll)
	this:Show()
end


--领取 
function ZongMenPata_Award_GetPrize(nIndex)
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskGetReward")  --脚本接口
			Set_XSCRIPT_ScriptID(998633) --脚本编号 
			Set_XSCRIPT_Parameter(0,nIndex)
			Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function ZongMenPata_Award_Help_Clicked()
	
end

--小红点
function ZongMenPata_Award_UpdateRedPointUI()

end

function ZongMenPata_Award_ClearRewardList()
	for i = 1, table.getn(g_ZongMenPata_Award_ActionBtn) do 
		if g_ZongMenPata_Award_ActionBtn[i] ~= nil then
			g_ZongMenPata_Award_ActionBtn[i]:SetActionItem(-1)
			g_ZongMenPata_Award_ActionBtn[i] = nil
		end
	end
	ZongMenPata_Award_List:Clear()	
end


function ZongMenPata_Award_OnHide()
	ZongMenPata_Award_ClearRewardList()
end

function ZongMenPata_Award_OnClose()
	this:Hide()
end


function ZongMenPata_Award_CloseClicked()
	ZongMenPata_Award_OnClose()
	
end

function ZongMenPata_Award_OnResetPos()
	ZongMenPata_Award_Frame:SetProperty("UnifiedPosition", g_ZongMenPata_Award_Frame_UnifiedPosition)
end

function ZongMenPata_Award_OnSetLastPos()

end

function ZongMenPata_Award_GetBitTable(nOct1, nOct2, nOct3, nOct4)
	local BitTable = {}
	local oct = nOct1
	for i = 1 , 32 do
		BitTable[i] = math.mod(oct , 2)
		oct = math.floor(oct / 2)
	end
	
	oct = nOct2
	for i = 33 , 64 do
		BitTable[i] = math.mod(oct , 2)
		oct = math.floor(oct / 2)
	end
	
	oct = nOct3
	for i = 65 , 96 do
		BitTable[i] = math.mod(oct , 2)
		oct = math.floor(oct / 2)
	end
	
	oct = nOct4
	for i = 97 , g_MAX_LEVEL do
		BitTable[i] = math.mod(oct , 2)
		oct = math.floor(oct / 2)
	end
	return BitTable
end

