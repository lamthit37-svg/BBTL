--猫舍进度

local g_CatProgress_Frame_UnifiedPosition;

local g_CatProgress_Value = 0
local g_CatProgress_ValueGet = {0,0,0,0,0}

local g_CatProgress_ActionList = {}
local g_CatProgress_BtnList = {}
local g_CatProgress_RedDotList = {}
local g_CatProgress_ReceivedList = {}
local g_CatProgress_ImageList = {}
local g_CatProgress_AnimateList = {}
local g_CatProgress_TextList = {}

local g_CatProgress_InfoList = {
[1] = { itemid = 39923435, value = 1000000, },
[2] = { itemid = 39923436, value = 3000000, },
[3] = { itemid = 39923437, value = 6000000, },
[4] = { itemid = 39923438, value = 12000000, },
[5] = { itemid = 39923439, value = 16000000, },
}

--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function CatProgress_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--=========================================================
-- 载入初始化
--=========================================================
function CatProgress_OnLoad()

	g_CatProgress_ActionList[1] = CatProgress_Reward_Item1 
	g_CatProgress_ActionList[2] = CatProgress_Reward_Item2 
	g_CatProgress_ActionList[3] = CatProgress_Reward_Item3 
	g_CatProgress_ActionList[4] = CatProgress_Reward_Item4 
	g_CatProgress_ActionList[5] = CatProgress_Reward_Item5 
	
	g_CatProgress_BtnList[1] = CatProgress_Award_Btn1
	g_CatProgress_BtnList[2] = CatProgress_Award_Btn2
	g_CatProgress_BtnList[3] = CatProgress_Award_Btn3
	g_CatProgress_BtnList[4] = CatProgress_Award_Btn4
	g_CatProgress_BtnList[5] = CatProgress_Award_Btn5
	
	g_CatProgress_RedDotList[1] = CatProgress_Award_RedDot1
	g_CatProgress_RedDotList[2] = CatProgress_Award_RedDot2
	g_CatProgress_RedDotList[3] = CatProgress_Award_RedDot3
	g_CatProgress_RedDotList[4] = CatProgress_Award_RedDot4
	g_CatProgress_RedDotList[5] = CatProgress_Award_RedDot5
	
	g_CatProgress_ReceivedList[1] = CatProgress_Award_Received1
	g_CatProgress_ReceivedList[2] = CatProgress_Award_Received2
	g_CatProgress_ReceivedList[3] = CatProgress_Award_Received3
	g_CatProgress_ReceivedList[4] = CatProgress_Award_Received4
	g_CatProgress_ReceivedList[5] = CatProgress_Award_Received5
	
	g_CatProgress_ImageList[1] = CatProgress_CatImage1
	g_CatProgress_ImageList[2] = CatProgress_CatImage2
	g_CatProgress_ImageList[3] = CatProgress_CatImage3
	g_CatProgress_ImageList[4] = CatProgress_CatImage4
	g_CatProgress_ImageList[5] = CatProgress_CatImage5
	
	g_CatProgress_AnimateList[1] = CatProgress_Running
	g_CatProgress_AnimateList[2] = CatProgress_Running1
	g_CatProgress_AnimateList[3] = CatProgress_Running2
	g_CatProgress_AnimateList[4] = CatProgress_Running3
	g_CatProgress_AnimateList[5] = CatProgress_Running4
	g_CatProgress_AnimateList[6] = CatProgress_Running5
	
	g_CatProgress_TextList[1] = CatProgress_Text1
	g_CatProgress_TextList[2] = CatProgress_Text2
	g_CatProgress_TextList[3] = CatProgress_Text3
	g_CatProgress_TextList[4] = CatProgress_Text4
	g_CatProgress_TextList[5] = CatProgress_Text5
	
	g_CatProgress_Frame_UnifiedPosition = CatProgress:GetProperty("UnifiedPosition");
	    
end

--=========================================================
-- 事件处理
--=========================================================
function CatProgress_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 88843901) then --打开界面
		
		if Get_XParam_INT( 0 ) <= 0 then
			CatProgress_Close()
			return
		end
		
		if Get_XParam_INT( 0 ) > 1 then
			if (true ~= this:IsVisible()) then
				return
			end
		end
		
		g_CatProgress_Value = Get_XParam_INT( 1 )
		
		for i = 1, table.getn(g_CatProgress_ValueGet) do
			g_CatProgress_ValueGet[i] = Get_XParam_INT( i + 1 )
		end
		
		CatProgress_OnShow()
		
	elseif event == "HIDE_ON_SCENE_TRANSED"  then	
		this:Hide()
		
	elseif (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		CatProgress_Frame_On_ResetPos()
		
	end
	
end

--=========================================================
-- 显示信息
--=========================================================
function CatProgress_OnShow()

	for i = 1, table.getn(g_CatProgress_ActionList) do				
		local theAction = DataPool:CreateActionItemForShow(g_CatProgress_InfoList[i].itemid, 1)
		if theAction:GetID() ~= 0 then
			g_CatProgress_ActionList[i]:SetActionItem(theAction:GetID())
		end
	end
	
	for i = 1, table.getn(g_CatProgress_BtnList) do	
		g_CatProgress_BtnList[i]:Hide()
		g_CatProgress_ReceivedList[i]:Hide()
		g_CatProgress_RedDotList[i]:Hide()
		g_CatProgress_TextList[i]:Hide()
		g_CatProgress_ImageList[i]:Hide()
		
		if g_CatProgress_ValueGet[i] ~= nil then
			if g_CatProgress_ValueGet[i] == 1 then
				-- 已领取
				g_CatProgress_ReceivedList[i]:Show()
			else				
				-- 小红点
				if g_CatProgress_Value >= g_CatProgress_InfoList[i].value then
					g_CatProgress_RedDotList[i]:Show()
					-- 未领取 可领取
					g_CatProgress_BtnList[i]:Show()
				else
					-- 未领取 不可领取
					g_CatProgress_ImageList[i]:Show()
					g_CatProgress_TextList[i]:Show()
					local strVal = ScriptGlobal_Format("#{MSJD_210525_22}", tostring(math.floor(g_CatProgress_InfoList[i].value/10000)))
					g_CatProgress_TextList[i]:SetText(strVal)
				end
			end
		else
			g_CatProgress_BtnList[i]:Show()
		end
	end
	
	local nShowIdx = 1
	for i = 1, table.getn(g_CatProgress_AnimateList) do
		g_CatProgress_AnimateList[i]:Hide()
		if i >= 2 and g_CatProgress_InfoList[i-1] ~= nil and g_CatProgress_Value >= g_CatProgress_InfoList[i-1].value then
			nShowIdx = i
		end
	end	
	
	if g_CatProgress_AnimateList[nShowIdx] ~= nil then
		g_CatProgress_AnimateList[nShowIdx]:Show()
	end
	
	local str = ScriptGlobal_Format("#{MSJD_210525_08}", tostring(math.floor(g_CatProgress_Value/10000)))	
	if g_CatProgress_Value <= 0 then
		CatProgress_Totle:SetText("#{MSJD_210525_21}")
	else
		CatProgress_Totle:SetText(str)
	end

	this:Show()

end

--=========================================================
-- 重置界面
--=========================================================
function CatProgress_Clear()

	for i = 1, table.getn(g_CatProgress_ActionList) do
		g_CatProgress_ActionList[i]:SetActionItem(-1)
	end
	
end

--=========================================================
-- 领取奖励
--=========================================================
function CatProgress_Award_Item_Clicked( nIdx )
	if g_CatProgress_BtnList[nIdx] == nil then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetCatProcessGift")
		Set_XSCRIPT_ScriptID(888439)
		Set_XSCRIPT_Parameter( 0, nIdx )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

--=========================================================
-- 查看帮助
--=========================================================
function CatProgress_Description_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowCatProcessHelp")
		Set_XSCRIPT_ScriptID(888439)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

--=========================================================
-- 关闭界面
--=========================================================
function CatProgress_Close()

	CatProgress_Clear()
	
	this:Hide()
	
end

function CatProgress_Frame_On_ResetPos()

  CatProgress:SetProperty("UnifiedPosition", g_CatProgress_Frame_UnifiedPosition);
  
end


