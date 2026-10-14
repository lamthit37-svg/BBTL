--LianXuQiRi
local g_LianXuQiRi_UnifiedPosition;

local LianXuQiRi_ButtonLeftBK = {}
local LianXuQiRi_ButtonLeft = {}
local LianXuQiRi_Tips = {}
local LianXuQiRi_Mask = {}
local LianXuQiRi_TimeText = {}
local LianXuQiRi_ActionBtn = {}
local LianXuQiRi_ButtonTip= {}
local LianXuQiRi_Resign= {}
local LianXuQiRi_Button= {}
local LianXuQiRi_MarkNo = {}

local g_CurDayTime= 0;
local g_Data = 0;
local g_CurPage = 0;
local g_CurPageIsOpen = 0;
local g_PageIsOpenIndex = 0;
local  g_CurPageDayTime = {0,0,0,0,0,0,0};
local g_ShowRedPointIndex = 0;
local g_HuoyuePrizeDate = 0

local g_HuoyuePrizeItem = 38006291 --活跃奖励1

local g_HuoyuePrizeItem_Kaji = 38003047 --活跃奖励1

--累计活跃奖励
local g_HuoyueLijiCount = 0
local g_HuoyueLijiPrizeGet = 0
local g_HuoyueLijiPrizeItem = 38003001

function LianXuQiRi_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("TODAY_ACTIVE_POINT",false)

end

function LianXuQiRi_OnLoad()

	LianXuQiRi_ButtonLeftBK[1] = LianXuQiRi_Buttontab01BK
	LianXuQiRi_ButtonLeftBK[2] = LianXuQiRi_Buttontab02BK
	LianXuQiRi_ButtonLeftBK[3] = LianXuQiRi_Buttontab03BK
	LianXuQiRi_ButtonLeftBK[4] = LianXuQiRi_Buttontab04BK

	LianXuQiRi_ButtonLeft[1] = LianXuQiRi_Buttontab01
	LianXuQiRi_ButtonLeft[2] = LianXuQiRi_Buttontab02
	LianXuQiRi_ButtonLeft[3] = LianXuQiRi_Buttontab03
	LianXuQiRi_ButtonLeft[4] = LianXuQiRi_Buttontab04
	
	LianXuQiRi_Tips[1] = LianXuQiRi_Buttontab01_Tips
	LianXuQiRi_Tips[2] = LianXuQiRi_Buttontab02_Tips
	LianXuQiRi_Tips[3] = LianXuQiRi_Buttontab03_Tips
	LianXuQiRi_Tips[4] = LianXuQiRi_Buttontab04_Tips

	LianXuQiRi_TimeText[1] = LianXuQiRi_oneText
	LianXuQiRi_TimeText[2] = LianXuQiRi_twoText
	LianXuQiRi_TimeText[3] = LianXuQiRi_threeText
	LianXuQiRi_TimeText[4] = LianXuQiRi_fourText
	LianXuQiRi_TimeText[5] = LianXuQiRi_fiveText
	LianXuQiRi_TimeText[6] = LianXuQiRi_sixText
	LianXuQiRi_TimeText[7] = LianXuQiRi_sevenText
		
	LianXuQiRi_ActionBtn[1] = LianXuQiRi_Page1_one
	LianXuQiRi_ActionBtn[2] = LianXuQiRi_Page1_two
	LianXuQiRi_ActionBtn[3] = LianXuQiRi_Page1_three
	LianXuQiRi_ActionBtn[4] = LianXuQiRi_Page1_four
	LianXuQiRi_ActionBtn[5] = LianXuQiRi_Page1_five
	LianXuQiRi_ActionBtn[6] = LianXuQiRi_Page1_six
	LianXuQiRi_ActionBtn[7] = LianXuQiRi_Page1_seven

	LianXuQiRi_Mask[1] = LianXuQiRi_Page1_oneMark
	LianXuQiRi_Mask[2] = LianXuQiRi_Page1_twoMark
	LianXuQiRi_Mask[3] = LianXuQiRi_Page1_threeMark
	LianXuQiRi_Mask[4] = LianXuQiRi_Page1_fourMark
	LianXuQiRi_Mask[5] = LianXuQiRi_Page1_fiveMark
	LianXuQiRi_Mask[6] = LianXuQiRi_Page1_sixMark
	LianXuQiRi_Mask[7] = LianXuQiRi_Page1_sevenMark

	LianXuQiRi_ButtonTip[1] = LianXuQiRi_Page1_one_Animate
	LianXuQiRi_ButtonTip[2] = LianXuQiRi_Page1_two_Animate
	LianXuQiRi_ButtonTip[3] = LianXuQiRi_Page1_three_Animate
	LianXuQiRi_ButtonTip[4] = LianXuQiRi_Page1_four_Animate
	LianXuQiRi_ButtonTip[5] = LianXuQiRi_Page1_five_Animate
	LianXuQiRi_ButtonTip[6] = LianXuQiRi_Page1_six_Animate
	LianXuQiRi_ButtonTip[7] = LianXuQiRi_Page1_seven_Animate

	LianXuQiRi_Resign[1] = LianXuQiRi_one_Button
	LianXuQiRi_Resign[2] = LianXuQiRi_two_Button
	LianXuQiRi_Resign[3] = LianXuQiRi_three_Button
	LianXuQiRi_Resign[4] = LianXuQiRi_four_Button
	LianXuQiRi_Resign[5] = LianXuQiRi_five_Button
	LianXuQiRi_Resign[6] = LianXuQiRi_six_Button
	LianXuQiRi_Resign[7] = LianXuQiRi_seven_Button

	LianXuQiRi_Button[1] = LianXuQiRi_one_Button
	LianXuQiRi_Button[2] = LianXuQiRi_two_Button
	LianXuQiRi_Button[3] = LianXuQiRi_three_Button
	LianXuQiRi_Button[4] = LianXuQiRi_four_Button
	LianXuQiRi_Button[5] = LianXuQiRi_five_Button
	LianXuQiRi_Button[6] = LianXuQiRi_six_Button
	LianXuQiRi_Button[7] = LianXuQiRi_seven_Button
				
	LianXuQiRi_MarkNo[1] = LianXuQiRi_Page1_oneMark_no
	LianXuQiRi_MarkNo[2] = LianXuQiRi_Page1_twoMark_no
	LianXuQiRi_MarkNo[3] = LianXuQiRi_Page1_threeMark_no
	LianXuQiRi_MarkNo[4] = LianXuQiRi_Page1_fourMark_no
	LianXuQiRi_MarkNo[5] = LianXuQiRi_Page1_fiveMark_no
	LianXuQiRi_MarkNo[6] = LianXuQiRi_Page1_sixMark_no
	LianXuQiRi_MarkNo[7] = LianXuQiRi_Page1_sevenMark_no
	
	g_LianXuQiRi_UnifiedPosition = LianXuQiRi_Frame:GetProperty("UnifiedPosition")
	
end

function LianXuQiRi_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99817201 ) then
		
		LianXuQiRi_Reset()
		local operator = Get_XParam_INT(0)
			
		g_CurDayTime = Get_XParam_INT(1)
		g_Data = Get_XParam_INT(2)
		g_CurPage = Get_XParam_INT(3)
		g_PageIsOpenIndex = Get_XParam_INT(4) --1~4
		g_ShowRedPointIndex = Get_XParam_INT(5)
		g_HuoyuePrizeDate = Get_XParam_INT(6)
		
		if g_CurPage <= g_PageIsOpenIndex then
			for i = 1, 7 do
				g_CurPageDayTime[i] = Get_XParam_INT(6+i)
			end
		end
		
		if operator == 1 then
			LianXuQiRi_Update()
		elseif operator == 2 and this:IsVisible() then
			LianXuQiRi_Update()		
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99817204 and this:IsVisible()) then
		g_HuoyueLijiCount = Get_XParam_INT(0)
		g_HuoyueLijiPrizeGet = Get_XParam_INT(1)
		
		LianXuQiRi_Update_Liji()
	elseif (event == "ADJEST_UI_POS" ) then
		LianXuQiRi_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		LianXuQiRi_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif ( event == "TODAY_ACTIVE_POINT" ) then
		LianXuQiRi_Update() 
	end

end
--=========================================================
--reset
--=========================================================
function LianXuQiRi_Reset()
	g_CurDayTime= 0
	g_Data = 0
	g_CurPage = 0
	g_CurPageIsOpen = 0
	g_PageIsOpenIndex = 0
	for i = 1, 7 do
		g_CurPageDayTime[i] = 0
	end
	g_ShowRedPointIndex = 0;	
	g_HuoyuePrizeDate = 0
end
--=========================================================
--更新界面
--=========================================================
function LianXuQiRi_Update()
	for i = 1, 4 do
		--local isOpen,nDayTime,nBonusId,nBonusNum = DataPool:LuaFnGetDaysSignInfo(i,0)
		if i <= g_PageIsOpenIndex then
			LianXuQiRi_ButtonLeftBK[i]:Show()
		else
			LianXuQiRi_ButtonLeftBK[i]:Hide()
		end
		if g_CurPage == i then
			LianXuQiRi_ButtonLeft[i]:SetCheck(1)
		else
		    LianXuQiRi_ButtonLeft[i]:SetCheck(0)
		end
		--红点
		LianXuQiRi_Tips[i]:Hide()
		if g_ShowRedPointIndex == i then
			LianXuQiRi_Tips[i]:Show()
		end
		--for j = 1, 7 do
			--local isOpen,nDayTime,nBonusId,nBonusNum = DataPool:LuaFnGetDaysSignInfo(i,j-1)
		--	if nDayTime == g_CurDayTime then
		--		local signflag =  DataPool:Lua_GetBinaryData(g_Data, (i-1)*7+j-1 );
		--		if signflag == 0 then
		--			LianXuQiRi_Tips[i]:Show() 
		--		end
		--	end
		--end
	end
	
	----------拼字典---------------
	local _, nStartDayTime, _, _ = DataPool:LuaFnGetDaysSignInfo(1, 0)
	local smonth,sday = LianXuQiRi_GetDayTime(nStartDayTime)
		
	local nFinalTime = 0
	for i = 1, 4 do
		local IsOpen, nEndDayTime, _, _ = DataPool:LuaFnGetDaysSignInfo(i, 6)
		if IsOpen == 1 then
			nFinalTime = nEndDayTime
		end
	end
	local emonth,eday = LianXuQiRi_GetDayTime(nFinalTime)
	--LianXuQiRi_Text:SetText(ScriptGlobal_Format("#{LXQD_220719_1}", smonth,sday,emonth,eday))
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(99) > 0 then  --卡级
		LianXuQiRi_Text:SetText("#{LXQD_230220_25}")
	else
		LianXuQiRi_Text:SetText("#{LXQD_220719_1}")
	end
	--------------------------------
	if g_CurPage >= 1 and g_CurPage <= 4 then
		for i = 1, 7 do
			--LianXuQiRi_Resign[i]:Hide()
			LianXuQiRi_Mask[i]:Hide()
			LianXuQiRi_ButtonTip[i]:Play(false)
			
			local isOpen,nDayTime,nBonusId,nBonusNum = DataPool:LuaFnGetDaysSignInfo(g_CurPage,i-1)
			nDayTime = g_CurPageDayTime[i]
			
			if g_CurPage <= g_PageIsOpenIndex then
				LianXuQiRi_TimeText[i]:SetText((g_CurPage-1)*7+i)
				
				local theAction = DataPool:CreateBindActionItemForShow( nBonusId, nBonusNum )
				if theAction ~= nil then
					LianXuQiRi_ActionBtn[i]:SetActionItem(theAction:GetID())
				end
				
				LianXuQiRi_MarkNo[i]:Hide()
				local signflag =  DataPool:Lua_GetBinaryData(g_Data, (g_CurPage-1)*7+i-1 );
				
				if signflag == 1 then --已签到
					LianXuQiRi_Mask[i]:Show()
					LianXuQiRi_ActionBtn[i]:Disable()
					LianXuQiRi_TimeText[i]:SetToolTip("#{LXQD_220719_21}")
					--LianXuQiRi_Button[i]:SetToolTip("#{LXQD_220719_21}")
				else
					if nDayTime < g_CurDayTime then --过期
						LianXuQiRi_MarkNo[i]:Show()
						--LianXuQiRi_Resign[i]:Show()
						--local day = math.mod(g_CurDayTime,100)
						--local month = math.mod(math.floor(g_CurDayTime/100),100)
						LianXuQiRi_TimeText[i]:SetToolTip("#{LXQD_230220_11}")
						--LianXuQiRi_Button[i]:SetToolTip(ScriptGlobal_Format("#{LXQD_220719_26}", month,day))
					elseif nDayTime == g_CurDayTime then --今日可领取
						LianXuQiRi_ButtonTip[i]:Play(true)
						LianXuQiRi_TimeText[i]:SetToolTip("#{LXQD_220719_23}")
						--LianXuQiRi_Button[i]:SetToolTip("#{LXQD_220719_23}")
						LianXuQiRi_Tips[g_CurPage]:Show()
					else
						local day = math.mod(nDayTime,100)
						local month = math.mod(math.floor(nDayTime/100),100)
						
						LianXuQiRi_TimeText[i]:SetToolTip(ScriptGlobal_Format("#{LXQD_220719_24}", month,day))
						--LianXuQiRi_Button[i]:SetToolTip(ScriptGlobal_Format("#{LXQD_220719_24}", month,day))
					end
					LianXuQiRi_ActionBtn[i]:Enable()
				end
			end
		end
	end
	
	--活跃奖励
	local nHuoYuePrizeItem = g_HuoyuePrizeItem
	local nTodayPoint = Player:GetData("TODAYACTIVEPOINT")
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(99) > 0 then  --卡级
		LianXuQiRi_Client2_Time:SetText(ScriptGlobal_Format( "#{LXQD_230220_23}", nTodayPoint))
		LianXuQiRi_Client2_Time:SetToolTip("#{LXQD_230220_26}")
		nHuoYuePrizeItem = g_HuoyuePrizeItem_Kaji
	else
		LianXuQiRi_Client2_Time:SetText(ScriptGlobal_Format( "#{LXQD_230220_1}", nTodayPoint))
		LianXuQiRi_Client2_Time:SetToolTip("#{LXQD_230220_2}")
	end
	local theAction = DataPool:CreateBindActionItemForShow( nHuoYuePrizeItem, 1 )
	if theAction ~= nil then
		LianXuQiRi_Client2_Btn1:SetActionItem(theAction:GetID())
	end
	
	LianXuQiRi_Client2_Btn1_Mask:Hide()
	LianXuQiRi_Client2_Btn1_Animate:Hide()
	if g_HuoyuePrizeDate >= g_CurDayTime then --已领取
		LianXuQiRi_Client2_Btn1_Mask:Show()
	else
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(99) > 0 then  --卡级
			if nTodayPoint >= 150 then
				LianXuQiRi_Client2_Btn1_Animate:Show() --可领取
			end
		else
			if nTodayPoint >= 450 then
				LianXuQiRi_Client2_Btn1_Animate:Show() --可领取
			end
		end

	end
	
	LianXuQiRi_Update_Liji()
	
	this:Show()
end

function LianXuQiRi_Update_Liji()

	local theAction = DataPool:CreateBindActionItemForShow( g_HuoyueLijiPrizeItem, 1 )
	if theAction ~= nil then
		LianXuQiRi_Client2_Btn:SetActionItem(theAction:GetID())
	end
	
	if g_HuoyueLijiPrizeGet == 1 then
		LianXuQiRi_Client2_Btn_Mask:Show() --已领取
		LianXuQiRi_Client2_Btn_Animate:Hide()
	else
		if g_HuoyueLijiCount >= 7 then
			LianXuQiRi_Client2_Btn_Animate:Show() --可领取
		else
			LianXuQiRi_Client2_Btn_Animate:Hide()
		end
		LianXuQiRi_Client2_Btn_Mask:Hide()
	end
	
	LianXuQiRi_Client2_Btn_Text:SetText(ScriptGlobal_Format( "#{SXJL_230719_08}", g_HuoyueLijiCount))
end
--========================================================
--关闭
--=========================================================
function LianXuQiRi_Close()
	LianXuQiRi_Reset()
	this:Hide()
end

function LianXuQiRi_OnHiden()
	LianXuQiRi_Close()
end
--=========================================================
--刷新位置
--=========================================================
function LianXuQiRi_On_ResetPos()
	LianXuQiRi_Frame:SetProperty("UnifiedPosition", g_LianXuQiRi_UnifiedPosition);
end


function LianXuQiRi_Help()
	if g_PageIsOpenIndex > 1 then
		PushEvent("CCSHOP_HELP", 190) --延长
	else
		PushEvent("CCSHOP_HELP", 167)
	end
end

function LianXuQiRi_GetDayTime(nDayTime)
	local day = math.mod(nDayTime, 100)
	local month = math.mod(math.floor(nDayTime/100), 100)
	return month, day
end

function LianXuQiRi_PageOnClick(nIndex)
	if nIndex < 1 or nIndex > 4 then
		return
	end
	
	g_CurPage = nIndex
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenWindowRequest" )
		Set_XSCRIPT_ScriptID( 998172 )
		Set_XSCRIPT_Parameter(0,g_CurPage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end
--领奖
function LianXuQiRi_OnClick(nIndex)
	if nIndex < 1 or nIndex > 7 then
		return
	end
	
	--local isOpen,nDayTime,nBonusId,nBonusNum = DataPool:LuaFnGetDaysSignInfo(g_CurPage,nIndex-1)
	--if isOpen < 1 then
	--	PushDebugMessage("尚未开放")
	--	return
	--end

	--if nDayTime < g_CurDayTime then
	--	Clear_XSCRIPT()
	--		Set_XSCRIPT_Function_Name( "DoResign" )
	--		Set_XSCRIPT_ScriptID( 998172 )
	--		Set_XSCRIPT_Parameter(0,g_CurPage)
	--		Set_XSCRIPT_Parameter(1,nIndex-1)
	--		Set_XSCRIPT_Parameter(2,1)
	--		Set_XSCRIPT_ParamCount(3)
	--	Send_XSCRIPT()	
	--else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoTodaySign" )
			Set_XSCRIPT_ScriptID( 998172 )
			Set_XSCRIPT_Parameter(0,g_CurPage)
			Set_XSCRIPT_Parameter(1,nIndex-1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()		
	--end
end

function LianXuQiRi_PageHuoyueClick()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetHuoyuePrize" )
		Set_XSCRIPT_ScriptID( 998172 )
		Set_XSCRIPT_Parameter(0,g_CurPage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

function LianXuQiRi_PageLijiHuoyueClick()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetLijiHuoyuePrize" )
		Set_XSCRIPT_ScriptID( 998172 )
		Set_XSCRIPT_Parameter(0,g_CurPage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end