local g_Frame_UnifiedPosition = nil
local g_AwardItemNum = 2

local g_nAwardLevelInfo = {
	[1] = {
		[1] = {id = 20101001, num = 1, rate = 1000},
		[2] = {id = 20101002, num = 1, rate = 2000},
		[3] = {id = 20101003, num = 1, rate = 3000},
		[4] = {id = 20101004, num = 1, rate = 4000},
		[5] = {id = 20101005, num = 1, rate = 5000},
		[6] = {id = 20101006, num = 1, rate = 6000},
		[7] = {id = 20101007, num = 1, rate = 7000},
		[8] = {id = 20101008, num = 1, rate = 8000},
		[9] = {id = 20101007, num = 1, rate = 9000},
		[10] = {id = 20101008, num = 1, rate = 10000},
	},
	[2] = {
		[1] = {id = 20101001, num = 1, rate = 1000},
		[2] = {id = 20101002, num = 1, rate = 2000},
		[3] = {id = 20101003, num = 1, rate = 3000},
		[4] = {id = 20101004, num = 1, rate = 4000},
		[5] = {id = 20101005, num = 1, rate = 5000},
		[6] = {id = 20101006, num = 1, rate = 6000},
		[7] = {id = 20101007, num = 1, rate = 7000},
		[8] = {id = 20101008, num = 1, rate = 8000},
		[9] = {id = 20101007, num = 1, rate = 9000},
		[10] = {id = 20101008, num = 1, rate = 10000},
	},
	[3] = {
		[1] = {id = 20101001, num = 1, rate = 1000},
		[2] = {id = 20101002, num = 1, rate = 2000},
		[3] = {id = 20101003, num = 1, rate = 3000},
		[4] = {id = 20101004, num = 1, rate = 4000},
		[5] = {id = 20101005, num = 1, rate = 5000},
		[6] = {id = 20101006, num = 1, rate = 6000},
		[7] = {id = 20101007, num = 1, rate = 7000},
		[8] = {id = 20101008, num = 1, rate = 8000},
		[9] = {id = 20101007, num = 1, rate = 9000},
		[10] = {id = 20101008, num = 1, rate = 10000},
	},
	
}
local g_Round = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 5,
	[6] = 6,
	[7] = 7,
	[8] = 8,
	[9] = 9,
	[10] = 10,
	[11] = 11,
	[12] = 12,
	[13] = 13,
	[14] = 14,
	[15] = 15,
	[16] = 16,
	[17] = 17,
	[18] = 18,
	[19] = 19,
	[20] = 20,
	[21] = 21,
	[22] = 22,
	[23] = 23,
	[24] = 24,
	[25] = 25,
	[26] = 26,
	[27] = 27,
	[28] = 28,
	[29] = 29,
	[30] = 30,
}
--=========
-- PreLoad()
--=========
function ZhouchangPVE_Award_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function ZhouchangPVE_Award_OnLoad()
	
	g_Frame_UnifiedPosition = ZhouchangPVE_Award_Frame_BK:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function ZhouchangPVE_Award_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 33110601) then
	
		local nRefreshTime = Get_XParam_INT(0)
		local nAwardLevel = Get_XParam_INT(1)
		local nPoint = Get_XParam_INT(2)
		local nRound = Get_XParam_INT(3)
		local nItemList = {}
		for i = 1, g_AwardItemNum do
			nItemList[i] = Get_XParam_INT(3+i)
		end
		
		ZhouchangPVE_Award_Open(nRefreshTime, nAwardLevel, nItemList[1], nItemList[2], nPoint, nRound)
		
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 33110604) then
		this:Hide()
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ZhouchangPVE_Award_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		ZhouchangPVE_Award_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		ZhouchangPVE_Award_On_ResetPos()
	
	end
end


function ZhouchangPVE_Award_Close()
	ZhouchangPVE_Award_Icon1:SetActionItem(-1)
	ZhouchangPVE_Award_Icon2:SetActionItem(-1)
	--ZhouchangPVE_Award_Icon3:SetActionItem(-1)
	ZhouchangPVE_Award_Icon1Text:SetText("")
	ZhouchangPVE_Award_Icon2Text:SetText("")
	--ZhouchangPVE_Award_Icon3Text:SetText("")
	ZhouchangPVE_Award_Icon1Have:Hide()
	ZhouchangPVE_Award_Icon2Have:Hide()
	--ZhouchangPVE_Award_Icon3Have:Hide()
	this:Hide()
end

--=========
-- 重置
--=========
function ZhouchangPVE_Award_On_ResetPos()

	ZhouchangPVE_Award_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function ZhouchangPVE_Award_Open(nRefreshTime, nAwardLevel, nItemList1, nItemList2, nPoint, nRound)

	ZhouchangPVE_Award_Icon1Have:Hide()
	ZhouchangPVE_Award_Icon2Have:Hide()
	--ZhouchangPVE_Award_Icon3Have:Hide()
	ZhouchangPVE_Award_Icon1:SetActionItem(-1)
	ZhouchangPVE_Award_Icon2:SetActionItem(-1)
	--ZhouchangPVE_Award_Icon3:SetActionItem(-1)
	ZhouchangPVE_Award_Icon1Text:SetText("")
	ZhouchangPVE_Award_Icon2Text:SetText("")
	--ZhouchangPVE_Award_Icon3Text:SetText("")
	if g_nAwardLevelInfo[nAwardLevel] == nil then
		return 0
	end

	local theAction1 = DataPool:CreateActionItemForShow(g_nAwardLevelInfo[nAwardLevel][nItemList1].id, g_nAwardLevelInfo[nAwardLevel][nItemList1].num)
	if theAction1:GetID() ~= 0 then
		ZhouchangPVE_Award_Icon1:SetActionItem(theAction1:GetID());
		ZhouchangPVE_Award_Icon1:Show();
		local str = DataPool:Lua_GetItemNameByIndex(g_nAwardLevelInfo[nAwardLevel][nItemList1].id)
		ZhouchangPVE_Award_Icon1Text:SetText(ScriptGlobal_Format("#{FHCL_240708_300}",str))
	end
	
	local theAction2 = DataPool:CreateActionItemForShow(g_nAwardLevelInfo[nAwardLevel][nItemList2].id, g_nAwardLevelInfo[nAwardLevel][nItemList2].num)
	if theAction2:GetID() ~= 0 then
		ZhouchangPVE_Award_Icon2:SetActionItem(theAction2:GetID());
		ZhouchangPVE_Award_Icon2:Show();
		local str = DataPool:Lua_GetItemNameByIndex(g_nAwardLevelInfo[nAwardLevel][nItemList2].id)
		ZhouchangPVE_Award_Icon2Text:SetText(ScriptGlobal_Format("#{FHCL_240708_300}",str))
	end
	
	-- local theAction3 = DataPool:CreateActionItemForShow(g_nAwardLevelInfo[nAwardLevel][nItemList3].id, g_nAwardLevelInfo[nAwardLevel][nItemList3].num)
	-- if theAction3:GetID() ~= 0 then
		-- ZhouchangPVE_Award_Icon3:SetActionItem(theAction3:GetID());
		-- ZhouchangPVE_Award_Icon3:Show();
		-- local str = DataPool:Lua_GetItemNameByIndex(g_nAwardLevelInfo[nAwardLevel][nItemList3].id)
		-- ZhouchangPVE_Award_Icon3Text:SetText(ScriptGlobal_Format("#{FHCL_240708_300}",str))
	-- end
	
	ZhouchangPVE_Award_HaveNum:SetText(ScriptGlobal_Format("#{FHCL_240708_365}",nRefreshTime))
	ZhouchangPVE_Award_Description_Text:SetText(ScriptGlobal_Format("#{FHCL_240708_299}",nPoint, nRound, nRound))
	if(IsWindowShow("ZhouchangPVE_Award")) then
		
	else
		this:Show()
	end 

end	

--=========
-- 点击领奖
--=========
function ZhouchangPVE_Award_GetClick(  )

	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AskGetAward" )
			Set_XSCRIPT_ScriptID(331106)
			Set_XSCRIPT_Parameter(0, 0);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	
end

function ZhouchangPVE_Award_Help()
    PushEvent("CCSHOP_HELP", 216)
end -- end func ZhouchangPVE_Info_Frame_Help()

function ZhouchangPVE_Award_RefreshClick( index )
	
	if index <= 0 or index > g_AwardItemNum then
		return 0
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ReFreshAward" )
		Set_XSCRIPT_ScriptID(331106)
		Set_XSCRIPT_Parameter(0, index);	
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
	
end

function ZhouchangPVE_Award_OnHide( )

	ZhouchangPVE_Award_Close()
	
end


