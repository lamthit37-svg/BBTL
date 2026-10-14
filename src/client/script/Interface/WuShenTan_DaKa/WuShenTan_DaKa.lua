--2026Q2武神坛打卡

local g_Frame_UnifiedPosition

--数据
local g_npcid = -1
local g_objCared = -1
local g_npcPosX = -1
local g_npcPosZ = -1
local g_round = 0 --第几轮
local g_state = 0 --是否处于可答题状态：0、否；1、是
local g_select1 = 0 --玩家作答第1格 与否：0，否；1，是
local g_select2 = 0 --玩家作答第2格 与否：0，否；1，是
local g_select3 = 0 --玩家作答第3格 与否：0，否；1，是
local g_select4 = 0 --玩家作答第4格 与否：0，否；1，是
local g_answer1 = -1 --客户端选择的答案1
local g_answer2 = -1 --客户端选择的答案2
local g_answer3 = -1 --客户端选择的答案3
local g_answer4 = -1 --客户端选择的答案4
local g_Serveranswer1 = -1 --服务器下发的正确答案1
local g_Serveranswer2 = -1 --服务器下发的正确答案2
local g_Serveranswer3 = -1 --服务器下发的正确答案3
local g_Serveranswer4 = -1 --服务器下发的正确答案4

-- 定时器 单位ms
local g_nDingShiQi_Max		= 1*1000
--玩家与npc最大距离
local g_Max_Distance =15

--控件
local g_SelectAnswer = {} --4个记录答案的控件
local g_Text_Round = WuShenTan_DaKa_Round_Text --文本控件：第几轮
--local g_Text_DaoJiShi = WuShenTan_DaKa_Round_Time --倒计时控件 

--资源
local g_Image_Color = {
	[1] = "set:WuShenTan_DaKa image:WuShenTan_DaKa_Color_Red",   	--红
	[2] = "set:WuShenTan_DaKa image:WuShenTan_DaKa_Color_Yellow",   --黄
	[3] = "set:WuShenTan_DaKa image:WuShenTan_DaKa_Color_Blue",	  	--蓝
}
local g_Image_State = {
	[1] = "set:WuShenTan_DaKa image:WuShenTan_DaKa_Color_WaitToSelect",  --等待输入
	[2] = "set:WuShenTan_DaKa image:WuShenTan_DaKa_Color_Disable",  --不可输入
}

--=========
-- PreLoad()
--=========
function WuShenTan_DaKa_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)

end

--=========
-- OnLoad()
--=========
function WuShenTan_DaKa_OnLoad()

	g_Frame_UnifiedPosition = WuShenTan_DaKa_Frame:GetProperty("UnifiedPosition")
	g_npcid = -1
	g_objCared = -1
	g_npcPosX = -1
	g_npcPosZ = -1
	g_round = 0
	g_state = 0
	g_select1 = 0
	g_select2 = 0
	g_select3 = 0
	g_select4 = 0
	g_answer1 = -1
	g_answer2 = -1
	g_answer3 = -1
	g_answer4 = -1
	g_Serveranswer1 = -1
	g_Serveranswer2 = -1
	g_Serveranswer3 = -1
	g_Serveranswer4 = -1
	
	g_SelectAnswer[1] = {Image=WuShenTan_DaKa_SelectColor_Round_1, success=WuShenTan_DaKa_SelectColor_Round_1_Success, fail=WuShenTan_DaKa_SelectColor_Round_1_Fail}
	g_SelectAnswer[2] = {Image=WuShenTan_DaKa_SelectColor_Round_2, success=WuShenTan_DaKa_SelectColor_Round_2_Success, fail=WuShenTan_DaKa_SelectColor_Round_2_Fail}
	g_SelectAnswer[3] = {Image=WuShenTan_DaKa_SelectColor_Round_3, success=WuShenTan_DaKa_SelectColor_Round_3_Success, fail=WuShenTan_DaKa_SelectColor_Round_3_Fail}
	g_SelectAnswer[4] = {Image=WuShenTan_DaKa_SelectColor_Round_4, success=WuShenTan_DaKa_SelectColor_Round_4_Success, fail=WuShenTan_DaKa_SelectColor_Round_4_Fail}
	
end

--=========================================================
-- 初始化定时器
--=========================================================
function WuShenTan_DaKa_InitTimer()
	if this:IsVisible() then
		KillTimer( "WuShenTan_DaKa_OnTimer()" )
		SetTimer("WuShenTan_DaKa", "WuShenTan_DaKa_OnTimer()", g_nDingShiQi_Max)
	end
end

--=========================================================
-- 定时器逻辑
--=========================================================
function WuShenTan_DaKa_OnTimer()
	if this:IsVisible() then
		if g_npcPosX == -1 or g_npcPosZ == -1 then
			return
		end
		local selfX,selfZ = Player:GetPos()
		local nDistance = math.sqrt( (g_npcPosX-selfX)*(g_npcPosX-selfX) + (g_npcPosZ-selfZ)*(g_npcPosZ-selfZ) )
		if nDistance > g_Max_Distance then
			WuShenTan_DaKa_OnHide()
		end
	else
		KillTimer( "WuShenTan_DaKa_OnTimer()" )
	end
end

--=========
-- Event
--=========
function WuShenTan_DaKa_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89362701 then
			
		local nType = Get_XParam_INT(0)
		if nType == 0 then --关闭界面
			WuShenTan_DaKa_OnHide()
			return
		elseif nType == 1 then --打开界面
			g_objCared = DataPool:GetNPCIDByServerID(Get_XParam_INT(1))
			g_round = Get_XParam_INT(2)
			g_state = Get_XParam_INT(3)
			--this:CareObject(g_objCared, 1, "WuShenTan_DaKa")
			WuShenTan_DaKa_OpenUI()	 --此时要重置客户端数据（比如要初始化答题选项、结算对错）		
			--定时器：用于检查玩家距离npc的距离，超过15米则关闭界面
			g_npcPosX = Get_XParam_INT(4)
			g_npcPosZ = Get_XParam_INT(5)
			WuShenTan_DaKa_InitTimer()	
		elseif nType == 4 then --特殊打开界面
			if(IsWindowShow("WuShenTan_DaKa")) then
				g_round = Get_XParam_INT(2)
				g_state = Get_XParam_INT(3)				
				return
			end
			g_objCared = DataPool:GetNPCIDByServerID(Get_XParam_INT(1))
			g_round = Get_XParam_INT(2)
			g_state = Get_XParam_INT(3)
			--this:CareObject(g_objCared, 1, "WuShenTan_DaKa")
			WuShenTan_DaKa_OpenUI()	 --此时要重置客户端数据（比如要初始化答题选项、结算对错）		
			--定时器：用于检查玩家距离npc的距离，超过15米则关闭界面
			g_npcPosX = Get_XParam_INT(4)
			g_npcPosZ = Get_XParam_INT(5)
			WuShenTan_DaKa_InitTimer()			
		elseif nType == 2 then --刷新：更新答题状态，不需要更新界面
			if(IsWindowShow("WuShenTan_DaKa")) then
				g_round = Get_XParam_INT(2)
				g_state = Get_XParam_INT(3)
				--WuShenTan_DaKa_UpdateUI() --此时要根据g_state状态，判断各控件是否可以点击，比如答题按钮
			-- else
				-- g_objCared = DataPool:GetNPCIDByServerID(Get_XParam_INT(1))
				-- g_round = Get_XParam_INT(2)
				-- g_state = Get_XParam_INT(3)
				-- this:CareObject(g_objCared, 1, "WuShenTan_DaKa")
				-- WuShenTan_DaKa_OpenUI()	 --此时要重置客户端数据（比如要初始化答题选项、结算对错）			
			end
		elseif nType == 3 then --刷新界面：接收服务器传来的答案，根据答案展示结算界面；将客户端的答案上传给sever，记录答题是否正确，用于统计
			if(IsWindowShow("WuShenTan_DaKa")) then
				g_npcid = Get_XParam_INT(1)
				g_round = Get_XParam_INT(2)
				g_state = Get_XParam_INT(3)
				g_Serveranswer1 = Get_XParam_INT(4)
				g_Serveranswer2 = Get_XParam_INT(5)
				g_Serveranswer3 = Get_XParam_INT(6)
				g_Serveranswer4 = Get_XParam_INT(7)				
				WuShenTan_DaKa_UpdateUI() --此时要根据g_state状态，判断各控件是否可以点击，比如答题按钮
				--返回答案
				Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name("RetClientAnswer");
					Set_XSCRIPT_ScriptID(893627);
					Set_XSCRIPT_Parameter(0,g_npcid);
					Set_XSCRIPT_Parameter(1,g_round);
					Set_XSCRIPT_Parameter(2,g_answer1);
					Set_XSCRIPT_Parameter(3,g_answer2);
					Set_XSCRIPT_Parameter(4,g_answer3);
					Set_XSCRIPT_Parameter(5,g_answer4);
					Set_XSCRIPT_ParamCount(6);
				Send_XSCRIPT();				
			end
		elseif nType == 5 then --刷新界面：接收服务器传来的答案，根据答案展示结算界面；将客户端的答案上传给sever，记录答题是否正确，用于统计
			if(IsWindowShow("WuShenTan_DaKa")) then
			else
				this:Show()
				WuShenTan_DaKa_Round_Text:SetText(ScriptGlobal_Format("#{WSDK_260327_65}", g_round))
				g_npcid = Get_XParam_INT(1)
				g_round = Get_XParam_INT(2)
				g_state = Get_XParam_INT(3)
				g_Serveranswer1 = Get_XParam_INT(4)
				g_Serveranswer2 = Get_XParam_INT(5)
				g_Serveranswer3 = Get_XParam_INT(6)
				g_Serveranswer4 = Get_XParam_INT(7)				
				WuShenTan_DaKa_UpdateUI() --此时要根据g_state状态，判断各控件是否可以点击，比如答题按钮
				--返回答案
				Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name("RetClientAnswer");
					Set_XSCRIPT_ScriptID(893627);
					Set_XSCRIPT_Parameter(0,g_npcid);
					Set_XSCRIPT_Parameter(1,g_round);
					Set_XSCRIPT_Parameter(2,g_answer1);
					Set_XSCRIPT_Parameter(3,g_answer2);
					Set_XSCRIPT_Parameter(4,g_answer3);
					Set_XSCRIPT_Parameter(5,g_answer4);
					Set_XSCRIPT_ParamCount(6);
				Send_XSCRIPT();				
			end			
		else
			return
		end	
		

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		WuShenTan_DaKa_OnHide()

	elseif event == "VIEW_RESOLUTION_CHANGED" then

		WuShenTan_DaKa_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		WuShenTan_DaKa_ResetPos()
		
    elseif ( event == "OBJECT_CARED_EVENT" and this:IsVisible() ) then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
       -- if(arg1 == "distance" and tonumber(arg2)>15 or arg1=="destroy") then
            --WuShenTan_DaKa_OnHide()			
        --end
		--取消关心
		--this:CareObject(g_objCared, 0, "WuShenTan_DaKa");		
	end

end

--*********************************
--打开界面：每次打开，都要重置数据
--*********************************
function WuShenTan_DaKa_OpenUI()
	--隐藏倒计时（暂时不要了）
	--g_Text_DaoJiShi:Hide()
	
	--第1轮
	if g_round==1 then
		--可答题
		--if g_state==1 then
			--显示第几轮
			WuShenTan_DaKa_Round_Text:SetText(ScriptGlobal_Format("#{WSDK_260327_65}", g_round))--g_Text_Round:SetProperty("Text", ScriptGlobal_Format("#{WSDK_260327_65}", g_round))
			--开放第1个答题区域
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[1].Image:Show()
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Hide()
			--关闭第2~4个答题区域
			g_SelectAnswer[2].Image:SetProperty("Image", g_Image_State[2])
			g_SelectAnswer[2].Image:Show()
			g_SelectAnswer[2].success:Hide()
			g_SelectAnswer[2].fail:Hide()			
			g_SelectAnswer[3].Image:SetProperty("Image", g_Image_State[2])
			g_SelectAnswer[3].Image:Show()
			g_SelectAnswer[3].success:Hide()
			g_SelectAnswer[3].fail:Hide()			
			g_SelectAnswer[4].Image:SetProperty("Image", g_Image_State[2])
			g_SelectAnswer[4].Image:Show()
			g_SelectAnswer[4].success:Hide()
			g_SelectAnswer[4].fail:Hide()
			--答题数据
			g_select1 = 0
			g_select2 = 0
			g_select3 = 0
			g_select4 = 0
			g_answer1 = -1
			g_answer2 = -1
			g_answer3 = -1
			g_answer4 = -1
			g_Serveranswer1 = -1
			g_Serveranswer2 = -1
			g_Serveranswer3 = -1
			g_Serveranswer4 = -1
		--不可答题
		--else
		
		--end
	--第2轮
	elseif g_round==2 then
		--可答题
		--if g_state==1 then
			--显示第几轮
			WuShenTan_DaKa_Round_Text:SetText(ScriptGlobal_Format("#{WSDK_260327_65}", g_round))--g_Text_Round:SetProperty("Text", ScriptGlobal_Format("#{WSDK_260327_65}", g_round))
			--开放第1~2个答题区域
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[1].Image:Show()
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Hide()
			g_SelectAnswer[2].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[2].Image:Show()
			g_SelectAnswer[2].success:Hide()
			g_SelectAnswer[2].fail:Hide()				
			--关闭第3~4个答题区域		
			g_SelectAnswer[3].Image:SetProperty("Image", g_Image_State[2])
			g_SelectAnswer[3].Image:Show()
			g_SelectAnswer[3].success:Hide()
			g_SelectAnswer[3].fail:Hide()			
			g_SelectAnswer[4].Image:SetProperty("Image", g_Image_State[2])
			g_SelectAnswer[4].Image:Show()
			g_SelectAnswer[4].success:Hide()
			g_SelectAnswer[4].fail:Hide()
			--答题数据
			g_select1 = 0
			g_select2 = 0
			g_select3 = 0
			g_select4 = 0
			g_answer1 = -1
			g_answer2 = -1
			g_answer3 = -1
			g_answer4 = -1	
			g_Serveranswer1 = -1
			g_Serveranswer2 = -1
			g_Serveranswer3 = -1
			g_Serveranswer4 = -1			
		--不可答题
		--else
		
		--end	
	--第3轮
	elseif g_round==3 then
		--可答题
		--if g_state==1 then
			--显示第几轮
			WuShenTan_DaKa_Round_Text:SetText(ScriptGlobal_Format("#{WSDK_260327_65}", g_round))--g_Text_Round:SetProperty("Text", ScriptGlobal_Format("#{WSDK_260327_65}", g_round))
			--开放第1~3个答题区域
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[1].Image:Show()
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Hide()
			g_SelectAnswer[2].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[2].Image:Show()
			g_SelectAnswer[2].success:Hide()
			g_SelectAnswer[2].fail:Hide()				
			g_SelectAnswer[3].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[3].Image:Show()
			g_SelectAnswer[3].success:Hide()
			g_SelectAnswer[3].fail:Hide()				
			--关闭第4个答题区域				
			g_SelectAnswer[4].Image:SetProperty("Image", g_Image_State[2])
			g_SelectAnswer[4].Image:Show()
			g_SelectAnswer[4].success:Hide()
			g_SelectAnswer[4].fail:Hide()
			--答题数据
			g_select1 = 0
			g_select2 = 0
			g_select3 = 0
			g_select4 = 0
			g_answer1 = -1
			g_answer2 = -1
			g_answer3 = -1
			g_answer4 = -1
			g_Serveranswer1 = -1
			g_Serveranswer2 = -1
			g_Serveranswer3 = -1
			g_Serveranswer4 = -1			
		--不可答题
		--else
		
		--end		
	--第4轮
	elseif g_round==4 then
		--可答题
		--if g_state==1 then
			--显示第几轮
			WuShenTan_DaKa_Round_Text:SetText(ScriptGlobal_Format("#{WSDK_260327_65}", g_round))--g_Text_Round:SetProperty("Text", ScriptGlobal_Format("#{WSDK_260327_65}", g_round))
			--开放第1~4个答题区域
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[1].Image:Show()
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Hide()
			g_SelectAnswer[2].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[2].Image:Show()
			g_SelectAnswer[2].success:Hide()
			g_SelectAnswer[2].fail:Hide()				
			g_SelectAnswer[3].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[3].Image:Show()
			g_SelectAnswer[3].success:Hide()
			g_SelectAnswer[3].fail:Hide()								
			g_SelectAnswer[4].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[4].Image:Show()
			g_SelectAnswer[4].success:Hide()
			g_SelectAnswer[4].fail:Hide()
			--答题数据
			g_select1 = 0
			g_select2 = 0
			g_select3 = 0
			g_select4 = 0
			g_answer1 = -1
			g_answer2 = -1
			g_answer3 = -1
			g_answer4 = -1
			g_Serveranswer1 = -1
			g_Serveranswer2 = -1
			g_Serveranswer3 = -1
			g_Serveranswer4 = -1			
		--不可答题
		--else
		
		--end	
	--其他
	else
	
	end
	
	this:Show()
end

--*****************************************
--根据server下发的答案，判断对错，更新界面
--*****************************************
function WuShenTan_DaKa_UpdateUI()
	if g_round==1 then
		--PushDebugMessage("g_select1="..g_select1)
		--PushDebugMessage("g_answer1="..g_answer1)
		if g_Serveranswer1==g_answer1 then
			g_SelectAnswer[1].success:Show()
			g_SelectAnswer[1].fail:Hide()		
		else
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Show()		
		end
	elseif g_round==2 then
		if g_Serveranswer1==g_answer1 then
			g_SelectAnswer[1].success:Show()
			g_SelectAnswer[1].fail:Hide()		
		else
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Show()		
		end	
		if g_Serveranswer2==g_answer2 then
			g_SelectAnswer[2].success:Show()
			g_SelectAnswer[2].fail:Hide()		
		else
			g_SelectAnswer[2].success:Hide()
			g_SelectAnswer[2].fail:Show()		
		end		
	elseif g_round==3 then
		if g_Serveranswer1==g_answer1 then
			g_SelectAnswer[1].success:Show()
			g_SelectAnswer[1].fail:Hide()		
		else
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Show()		
		end	
		if g_Serveranswer2==g_answer2 then
			g_SelectAnswer[2].success:Show()
			g_SelectAnswer[2].fail:Hide()		
		else
			g_SelectAnswer[2].success:Hide()
			g_SelectAnswer[2].fail:Show()		
		end	
		if g_Serveranswer3==g_answer3 then
			g_SelectAnswer[3].success:Show()
			g_SelectAnswer[3].fail:Hide()		
		else
			g_SelectAnswer[3].success:Hide()
			g_SelectAnswer[3].fail:Show()		
		end			
	elseif g_round==4 then
		if g_Serveranswer1==g_answer1 then
			g_SelectAnswer[1].success:Show()
			g_SelectAnswer[1].fail:Hide()		
		else
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Show()		
		end	
		if g_Serveranswer2==g_answer2 then
			g_SelectAnswer[2].success:Show()
			g_SelectAnswer[2].fail:Hide()		
		else
			g_SelectAnswer[2].success:Hide()
			g_SelectAnswer[2].fail:Show()		
		end	
		if g_Serveranswer3==g_answer3 then
			g_SelectAnswer[3].success:Show()
			g_SelectAnswer[3].fail:Hide()		
		else
			g_SelectAnswer[3].success:Hide()
			g_SelectAnswer[3].fail:Show()		
		end	
		if g_Serveranswer4==g_answer4 then
			g_SelectAnswer[4].success:Show()
			g_SelectAnswer[4].fail:Hide()		
		else
			g_SelectAnswer[4].success:Hide()
			g_SelectAnswer[4].fail:Show()		
		end	
	end
end

function WuShenTan_DaKa_SelectColorBtn_OnClick(index)

	if index==1 or index==2 or index==3 then
	else
		return
	end
	
	--不在可答题阶段
	if g_state~=1 then
		PushDebugMessage("#{WSDK_260327_63}")
		return	
	end
	
	--可以答题的上限
	local num_max = g_round --第x轮，最多可以答x个格子
	
	--已经答题的次数
	local num_done = g_select1 + g_select2 + g_select3 + g_select4
	
	--是否已无空余格子，可以答题
	if num_done>=num_max then
		PushDebugMessage("#{WSDK_260327_64}")
		return
	end
	
	--当前可以答题的格子序号
	if num_max==1 then
		if num_done==0 then
			g_select1 = 1
			g_answer1 = index
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_Color[index])
			g_SelectAnswer[1].Image:Show()			
		end
	elseif num_max==2 then
		if num_done==0 then
			g_select1 = 1
			g_answer1 = index
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_Color[index])
			g_SelectAnswer[1].Image:Show()			
		elseif num_done==1 then
			g_select2 = 1
			g_answer2 = index
			g_SelectAnswer[2].Image:SetProperty("Image", g_Image_Color[index])
			g_SelectAnswer[2].Image:Show()			
		end		
	elseif num_max==3 then
		if num_done==0 then
			g_select1 = 1
			g_answer1 = index
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_Color[index])
			g_SelectAnswer[1].Image:Show()			
		elseif num_done==1 then
			g_select2 = 1
			g_answer2 = index
			g_SelectAnswer[2].Image:SetProperty("Image", g_Image_Color[index])
			g_SelectAnswer[2].Image:Show()				
		elseif num_done==2 then
			g_select3 = 1
			g_answer3 = index
			g_SelectAnswer[3].Image:SetProperty("Image", g_Image_Color[index])
			g_SelectAnswer[3].Image:Show()				
		end			
	elseif num_max==4 then
		if num_done==0 then
			g_select1 = 1
			g_answer1 = index
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_Color[index])
			g_SelectAnswer[1].Image:Show()			
		elseif num_done==1 then
			g_select2 = 1
			g_answer2 = index
			g_SelectAnswer[2].Image:SetProperty("Image", g_Image_Color[index])
			g_SelectAnswer[2].Image:Show()			
		elseif num_done==2 then
			g_select3 = 1
			g_answer3 = index
			g_SelectAnswer[3].Image:SetProperty("Image", g_Image_Color[index])
			g_SelectAnswer[3].Image:Show()			
		elseif num_done==3 then
			g_select4 = 1
			g_answer4 = index
			g_SelectAnswer[4].Image:SetProperty("Image", g_Image_Color[index])
			g_SelectAnswer[4].Image:Show()			
		end			
	end
end

function WuShenTan_DaKa_CheXiao_Button_OnClick()
	if g_state~=1 then
		PushDebugMessage("#{WSDK_260327_85}")
		return
	end
	
	if g_round==1 then
		if g_select1~=0 then
			g_select1=0
			g_answer1=-1
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[1].Image:Show()
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Hide()	
		elseif g_select1==0 then
			PushDebugMessage("#{WSDK_260327_84}")
		end
	elseif g_round==2 then
		if g_select2~=0 then
			g_select2=0
			g_answer2=-1
			g_SelectAnswer[2].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[2].Image:Show()
			g_SelectAnswer[2].success:Hide()
			g_SelectAnswer[2].fail:Hide()			
		elseif g_select1~=0 then
			g_select1=0
			g_answer1=-1
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[1].Image:Show()
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Hide()
		elseif g_select1==0 then
			PushDebugMessage("#{WSDK_260327_84}")			
		end		
	elseif g_round==3 then
		if g_select3~=0 then
			g_select3=0
			g_answer3=-1
			g_SelectAnswer[3].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[3].Image:Show()
			g_SelectAnswer[3].success:Hide()
			g_SelectAnswer[3].fail:Hide()	
		elseif g_select2~=0 then
			g_select2=0
			g_answer2=-1
			g_SelectAnswer[2].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[2].Image:Show()
			g_SelectAnswer[2].success:Hide()
			g_SelectAnswer[2].fail:Hide()			
		elseif g_select1~=0 then
			g_select1=0
			g_answer1=-1
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[1].Image:Show()
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Hide()	
		elseif g_select1==0 then
			PushDebugMessage("#{WSDK_260327_84}")			
		end		
	elseif g_round==4 then
		if g_select4~=0 then
			g_select4=0
			g_answer4=-1
			g_SelectAnswer[4].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[4].Image:Show()
			g_SelectAnswer[4].success:Hide()
			g_SelectAnswer[4].fail:Hide()
		elseif g_select3~=0 then
			g_select3=0
			g_answer3=-1
			g_SelectAnswer[3].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[3].Image:Show()
			g_SelectAnswer[3].success:Hide()
			g_SelectAnswer[3].fail:Hide()			
		elseif g_select2~=0 then
			g_select2=0
			g_answer2=-1
			g_SelectAnswer[2].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[2].Image:Show()
			g_SelectAnswer[2].success:Hide()
			g_SelectAnswer[2].fail:Hide()			
		elseif g_select1~=0 then
			g_select1=0
			g_answer1=-1
			g_SelectAnswer[1].Image:SetProperty("Image", g_Image_State[1])
			g_SelectAnswer[1].Image:Show()
			g_SelectAnswer[1].success:Hide()
			g_SelectAnswer[1].fail:Hide()
		elseif g_select1==0 then
			PushDebugMessage("#{WSDK_260327_84}")			
		end		
	end
end

function WuShenTan_DaKa_ResetPos()

	WuShenTan_DaKa_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

function WuShenTan_DaKa_OnHide()
	--取消关心
	-- this:CareObject(g_objCared, 0, "WuShenTan_DaKa");
	-- g_objCared = -1
	-- CloseWindow("MessageBox_Self",true);
	KillTimer( "ZNQ_ChouJiang_OnTimer()" )
	this:Hide()
end


