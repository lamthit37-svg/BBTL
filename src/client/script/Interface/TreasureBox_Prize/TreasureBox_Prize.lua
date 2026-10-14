--TreasureBox_Prize
local g_TreasureBox_Prize_UnifiedPosition;

local TreasureBox_Prize_ActionButton = {}
local g_TreasureBox_Prize_pagebuttonleft = {}

local g_UseCount = 0
local g_RewardFlag = 0
local g_RedPointIsShow = 0
local g_RedPointIsShow2 = 0

local g_ExItemNumForLicheng = {
	[1] = {usecount = 10, itemid= 39923665, num = 2, itemcount = 0},
	[2] = {usecount = 25, itemid= 39923665, num = 4, itemcount = 0},
	[3] = {usecount = 50, itemid= 39923665, num = 8, itemcount = 0},
	[4] = {usecount = 100, itemid= 39923665, num = 15, itemcount = 0},
	[5] = {usecount = 250, itemid= 39923665, num = 30, itemcount = 0},
	[6] = {usecount = 400, itemid= 39923665, num = 60, itemcount = 0},
}

function TreasureBox_Prize_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面

end

function TreasureBox_Prize_OnLoad()	
	--g_TreasureBox_Prize_pagebuttonleft[1] = TreasureBox_Prize_Buttontab01
	--g_TreasureBox_Prize_pagebuttonleft[2] = TreasureBox_Prize_Buttontab02
	--g_TreasureBox_Prize_pagebuttonleft[3] = TreasureBox_Prize_Buttontab03
	--g_TreasureBox_Prize_pagebuttonleft[4] = TreasureBox_Prize_Buttontab04
	
	g_TreasureBox_Prize_UnifiedPosition = TreasureBox_Prize_FrameNULL:GetProperty("UnifiedPosition")
	
end

function TreasureBox_Prize_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88814307 ) then
		local operator = Get_XParam_INT(0)
		g_UseCount = Get_XParam_INT(1)
		g_RewardFlag = Get_XParam_INT(2)
		g_RedPointIsShow = Get_XParam_INT(3)
		g_RedPointIsShow2 = Get_XParam_INT(4)
		if operator == 1 then
			TreasureBox_Prize_On_SetLastPos()
			TreasureBox_Prize_Update()
		elseif operator == 2 then
			if this:IsVisible() then
				TreasureBox_Prize_Update()
			end
		end

	elseif (event == "ADJEST_UI_POS" ) then
		TreasureBox_Prize_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TreasureBox_Prize_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--更新界面
--=========================================================
function TreasureBox_Prize_Update()
	--TreasureBox_Prize_ButtonPage(4)
	
	for i = 1, table.getn(TreasureBox_Prize_ActionButton) do
		if TreasureBox_Prize_ActionButton[i] ~= nil then
			TreasureBox_Prize_ActionButton[i]:SetActionItem(-1)
			TreasureBox_Prize_ActionButton[i] = nil
		end
	end
		
	TreasureBox_Prize_List:Clear()

	local j = 0
	for i = 1, table.getn(g_ExItemNumForLicheng) do
		local bar1 = TreasureBox_Prize_List:AddChild("TreasureBox_Prize_Item")
		if not bar1 then
    		break
  		end		
		 
		local textstr = ""
		if g_UseCount >= g_ExItemNumForLicheng[i].usecount then
			textstr = "#{RCLS_200731_191}"
		else
			textstr = ScriptGlobal_Format( "#{RCLS_201222_04}", g_UseCount, g_ExItemNumForLicheng[i].usecount )
		end
		bar1:GetSubItem("TreasureBox_Prize_GetCondition"):SetText(textstr)
		
		local oActionBtn = nil
		local oActionBtn2 = nil
		
		if g_ExItemNumForLicheng[i].itemcount > 0 then
		--	bar1:GetSubItem("TreasureBox_Prize_GetCondition_Icon1"):Show()
		  -- bar1:GetSubItem("TreasureBox_Prize_GetCondition_Icon2"):Show()
		--	bar1:GetSubItem("TreasureBox_Prize_GetCondition_Icon3"):Hide()
		--	oActionBtn = bar1:GetSubItem("TreasureBox_Prize_GetCondition_Icon1");
		--	oActionBtn2 = bar1:GetSubItem("TreasureBox_Prize_GetCondition_Icon2");
		else
			bar1:GetSubItem("TreasureBox_Prize_GetCondition_Icon1"):Show()
			oActionBtn = bar1:GetSubItem("TreasureBox_Prize_GetCondition_Icon1");	
			--bar1:GetSubItem("TreasureBox_Prize_GetCondition_Icon2"):Hide()
			--bar1:GetSubItem("TreasureBox_Prize_GetCondition_Icon3"):Show()	
			--oActionBtn = bar1:GetSubItem("TreasureBox_Prize_GetCondition_Icon3");	
		end
		
		if oActionBtn ~= nil then
			local theAction = DataPool:CreateActionItemForShow(g_ExItemNumForLicheng[i].itemid, g_ExItemNumForLicheng[i].num)
			oActionBtn:Show()
			oActionBtn:SetActionItem( theAction:GetID() );
			TreasureBox_Prize_ActionButton[j] = oActionBtn
			j = j+1
		end

		if oActionBtn2 ~= nil then
			local theAction = DataPool:CreateActionItemForShow(39922026, g_ExItemNumForLicheng[i].itemcount)
			oActionBtn2:Show()
			oActionBtn2:SetActionItem( theAction:GetID() );
			TreasureBox_Prize_ActionButton[j] = oActionBtn
			j = j+1
		end
		
		--领取按钮
		local isGetReward = Lua_GetDataByBinary( g_RewardFlag, i-1 )
		local oButton = bar1:GetSubItem("TreasureBox_Prize_GetCondition_Btn")
		if oButton ~= nil then
			oButton:SetEvent( "Clicked", string.format("TreasureBox_Prize_Clicked(%d)",i) )
		end
		
		if isGetReward == 1 then
			oButton:Hide()
			bar1:GetSubItem("TreasureBox_Prize_GetCondition_BtnImage"):Show()
			bar1:GetSubItem("TreasureBox_Prize_GetCondition_BtnImage2"):Hide()
			--bar1:GetSubItem("TreasureBox_Prize_Award_GetCondition_BtnTips"):Hide()
		else
			--if g_UseCount >= g_ExItemNumForLicheng[i].usecount then
			--	local curDay = tonumber(DataPool:GetServerDayTime())
				--if curDay >= 20220117 and curDay <= 20220202 then
				--	bar1:GetSubItem("TreasureBox_Prize_Award_GetCondition_BtnTips"):Show()
				--else
				--	bar1:GetSubItem("TreasureBox_Prize_Award_GetCondition_BtnTips"):Hide()
				--end
			--else
			--	bar1:GetSubItem("TreasureBox_Prize_Award_GetCondition_BtnTips"):Hide()
			--end
			oButton:Show()
			oButton:Enable()
			bar1:GetSubItem("TreasureBox_Prize_GetCondition_BtnImage"):Hide()
			bar1:GetSubItem("TreasureBox_Prize_GetCondition_BtnImage2"):Hide()
		end
	end
	--if g_RedPointIsShow == 0 then
	--	TreasureBox_Prize_Buttontab01_Tips:Hide()
	--else
	--	TreasureBox_Prize_Buttontab01_Tips:Show()
	--end

	--if g_RedPointIsShow2 == 0 then
	--	TreasureBox_Prize_Buttontab04_Tips:Hide()
	--else
	--	TreasureBox_Prize_Buttontab04_Tips:Show()
	--end
	this:Show()
	this:Activate()
end	
function TreasureBox_Prize_Page_Clicked(index)
	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenLibaoShop" )
			Set_XSCRIPT_ScriptID( 888143 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif index == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 888143 )
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif index == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 888143 )
			Set_XSCRIPT_Parameter(0,2)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif index == 4 then
		return
	end
	Variable:SetVariable("TreasureBoxUIPos", TreasureBox_Prize_FrameNULL:GetProperty("UnifiedPosition"), 1)
end
--=========================================================
--商店说明
--=========================================================
function TreasureBox_Prize_Help_Clicked()
	PushEvent("CCSHOP_HELP", 118)
end

--=========================================================
--关闭
--=========================================================
function TreasureBox_Prize_Close()
	for i = 1, table.getn(TreasureBox_Prize_ActionButton) do
		if TreasureBox_Prize_ActionButton[i] ~= nil then
			TreasureBox_Prize_ActionButton[i]:SetActionItem(-1)
			TreasureBox_Prize_ActionButton[i] = nil
		end
	end
	
	TreasureBox_Prize_List:Clear()
	
	this:Hide()
end

function TreasureBox_Prize_OnHiden()
	TreasureBox_Prize_Close()
end

--=========================================================
--刷新位置
--=========================================================
function TreasureBox_Prize_On_ResetPos()
	TreasureBox_Prize_FrameNULL:SetProperty("UnifiedPosition", g_TreasureBox_Prize_UnifiedPosition);
end
--===============================================
-- 设置共享位置信息
--===============================================
function TreasureBox_Prize_On_SetLastPos()
	local CurUIPos = Variable:GetVariable("TreasureBoxUIPos")
	if( CurUIPos ~= nil) then
	    TreasureBox_Prize_FrameNULL:SetProperty("UnifiedPosition", CurUIPos )
	end
end

function TreasureBox_Prize_Clicked(nIndex)
	local nCount = table.getn(g_ExItemNumForLicheng)
	if nIndex < 1 or nIndex > nCount then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetLichengReward" )
		Set_XSCRIPT_ScriptID(888143)
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

-- 选中页签
function TreasureBox_Prize_ButtonPage(index)
	for i = 1, 4 do
		if index == i then
			g_TreasureBox_Prize_pagebuttonleft[i]:SetProperty("Selected", "True")
		else
			g_TreasureBox_Prize_pagebuttonleft[i]:SetProperty("Selected", "False")
		end
	end
end

