--T3BianJingGashapon_Detail
local g_T3BianJingGashapon_Detail_UnifiedPosition;

local T3BianJingGashapon_Detail_ActionButton = {}

local T3BianJingGashapon_Detail_Num = {}
local T3BianJingGashapon_Detail_Cost = {}
local T3BianJingGashapon_Detail_Mark = {}
local T3BianJingGashapon_Detail_Mark2 = {}

local g_curTBIndex = 0
local g_CurItemIndex = 0
local g_RewardItem_MD_List = {}

local g_Daibi1ShowID = 39923751

--美食币数量
local g_RewardDaibi = {
 [0] = 2,
 [1] = 4,
 [2] = 16,
 [3] = 20,
 [4] = 110,
 [5] = 300,
 [6] = 650,
 [7] = 2800,
}

function T3BianJingGashapon_Detail_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function T3BianJingGashapon_Detail_OnLoad()	
	g_T3BianJingGashapon_Detail_UnifiedPosition = T3BianJingGashapon_Detail_Frame:GetProperty("UnifiedPosition")
	
end

function T3BianJingGashapon_Detail_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88820505 ) then
		local operator = Get_XParam_INT(0)
		if operator == 1 then
			for i = 1, 10 do
				g_RewardItem_MD_List[i] = Get_XParam_INT(i)
			end

			T3BianJingGashapon_Detail_Update()

		elseif operator == 2 then
			if this:IsVisible() then
				for i = 1, 10 do
					g_RewardItem_MD_List[i] = Get_XParam_INT(i)
				end

				T3BianJingGashapon_Detail_Update()
			end
		end

	elseif (event == "ADJEST_UI_POS" ) then
		T3BianJingGashapon_Detail_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		T3BianJingGashapon_Detail_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--更新界面
--=========================================================
function T3BianJingGashapon_Detail_Update()
	for i = 1, table.getn(T3BianJingGashapon_Detail_ActionButton) do
		if T3BianJingGashapon_Detail_ActionButton[i] ~= nil then
			T3BianJingGashapon_Detail_ActionButton[i]:SetActionItem(-1)
			T3BianJingGashapon_Detail_ActionButton[i] = nil
		end
	end
		
	T3BianJingGashapon_DetailList:Clear()

	for i = 1, 7 do
		local bar1 = T3BianJingGashapon_DetailList:AddChild("T3BianJingGashapon_DetailList_Content")
		if not bar1 then
    		break
  		end		

		bar1:GetSubItem("T3BianJingGashapon_Detail_RewardText"):SetText(ScriptGlobal_Format("#{PTLS_200902_30}", i))  

		if i < 3 then
			bar1:GetSubItem("T3BianJingGashapon_Detail_RewardBK2Frame1"):Show()
			bar1:GetSubItem("T3BianJingGashapon_Detail_RewardBK2Frame2"):Hide()
			bar1:GetSubItem("T3BianJingGashapon_Detail_RewardBK2Frame3"):Hide()

		else
			bar1:GetSubItem("T3BianJingGashapon_Detail_RewardBK2Frame1"):Hide()
			local nCount = GetNiudanRewardItemCount(i)
			if nCount <= 6 then --一排
				bar1:GetSubItem("T3BianJingGashapon_Detail_RewardBK2Frame2"):Hide()
				bar1:GetSubItem("T3BianJingGashapon_Detail_RewardBK2Frame3"):Show()
				bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame3_Item1Special"):Hide()	
				for j = 1, 6 do
					local oActionBtn = bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame3_Item"..j);
					
					if j <= nCount then
						local nItemId, nNum, nLimit, nLimitIndex = GetNiudanRewardItem(i, j-1)
						if nItemId ~= nil and nItemId > 0 then
							local theAction = DataPool:CreateActionItemForShow(nItemId, nNum)
							oActionBtn:Show()
							oActionBtn:SetActionItem( theAction:GetID() );
							T3BianJingGashapon_Detail_ActionButton[j] = oActionBtn
							if nLimit > 0 then --限量
								local retcnt = T3BianJingGashapon_Detail_GetLimitCount(nLimitIndex)
								if retcnt >= nLimit then					
									bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame3_Item"..j.."_Mask"):Show()
									bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame3_Item"..j.."_BuyLimitNumBK"):Hide()
								else
									bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame3_Item"..j.."_Mask"):Hide()
									bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame3_Item"..j.."_BuyLimitNumBK"):Show()
									bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame3_Item"..j.."_BuyLimitNum"):SetText(nLimit-retcnt)
								end
								
								bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame3_Item"..j.."_BuyLimit"):Show()
							end
						end
					else
						oActionBtn:Hide()
					end 
				end
				if i == 7 then
					bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame3_Item1Special"):Show()
				end
			else --两排
				bar1:GetSubItem("T3BianJingGashapon_Detail_RewardBK2Frame2"):Show()
				bar1:GetSubItem("T3BianJingGashapon_Detail_RewardBK2Frame3"):Hide()		
				for j = 1, 12 do
					local oActionBtn = bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame2_Item"..j);
					if j <= nCount then
						local nItemId, nNum, nLimit, nLimitIndex = GetNiudanRewardItem(i, j-1)
						if nItemId ~= nil and nItemId > 0 then
							local theAction = DataPool:CreateActionItemForShow(nItemId, nNum)
							oActionBtn:Show()
							oActionBtn:SetActionItem( theAction:GetID() );
							T3BianJingGashapon_Detail_ActionButton[j] = oActionBtn
							if nLimit > 0 then --限量
								local retcnt = T3BianJingGashapon_Detail_GetLimitCount(nLimitIndex)
								if retcnt >= nLimit then
									bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame2_Item"..j.."_Mask"):Show()
									bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame2_Item"..j.."_BuyLimitNumBK"):Hide()
								else
									bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame2_Item"..j.."_Mask"):Hide()
									bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame2_Item"..j.."_BuyLimitNumBK"):Show()
									bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame2_Item"..j.."_BuyLimitNum"):SetText(nLimit-retcnt)
								end
								bar1:GetSubItem("T3BianJingGashapon_Detail_RewardFrame2_Item"..j.."_BuyLimit"):Show()
							end
						end
					else
						oActionBtn:Hide()
					end 
				end
			end
		end

		--代币
		local oActionBtn2 = bar1:GetSubItem("T3BianJingGashapon_Detail_JiFenItem");
		local theAction = DataPool:CreateActionItemForShow(g_Daibi1ShowID, 1)
		bar1:GetSubItem("T3BianJingGashapon_Detail_JiFenItem_Num"):SetText(g_RewardDaibi[i])
		oActionBtn2:Show()
		oActionBtn2:SetActionItem( theAction:GetID() );	
	end
		


	this:Show()
	this:Activate()
end	

--=========================================================
--说明
--=========================================================
function T3BianJingGashapon_Detail_Help_Clicked()
	PushEvent("CCSHOP_HELP", 118)
end

--=========================================================
--关闭
--=========================================================
function T3BianJingGashapon_Detail_Close()
	for i = 1, table.getn(T3BianJingGashapon_Detail_ActionButton) do
		if T3BianJingGashapon_Detail_ActionButton[i] ~= nil then
			T3BianJingGashapon_Detail_ActionButton[i]:SetActionItem(-1)
			T3BianJingGashapon_Detail_ActionButton[i] = nil
		end
	end
		
	this:Hide()
end

function T3BianJingGashapon_Detail_OnHiden()
	T3BianJingGashapon_Detail_Close()
end

--=========================================================
--刷新位置
--=========================================================
function T3BianJingGashapon_Detail_On_ResetPos()
	T3BianJingGashapon_Detail_Frame:SetProperty("UnifiedPosition", g_T3BianJingGashapon_Detail_UnifiedPosition);
end


-- 获取已兑换数
function T3BianJingGashapon_Detail_GetLimitCount(nIndex)
	local ret = -1

	local MDData = nil
	for i = 1, 10 do
		if nIndex > 4*(i-1) and nIndex <= 4*i then
			MDData = g_RewardItem_MD_List[i]
			break
		end
	end

	if MDData ~= nil then
		local temp = math.mod(nIndex-1, 4) --0,1,2,3

		if temp == 0 then
			ret = math.mod(MDData, 100)
		elseif temp == 1 then
			ret = math.mod(math.floor(MDData/100), 100)
		elseif temp == 2 then
			ret = math.mod(math.floor(MDData/10000), 100)
		elseif temp == 3 then
			ret = math.mod(math.floor(MDData/1000000), 100)
		end
	end

	return ret
end