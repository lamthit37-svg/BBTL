-- 2021周年预热活动
-- 对话阶段界面 & 对话结束界面

local g_Frame_UnifiedPosition

local g_Step = 0--默认阶段

-- 对话阶段界面--阶段指引
local g_StepDesc = 
{
	[1] = "#{ZNYR_20210318_15}", 
	[2] = "#{ZNYR_20210318_16}", 
	[3] = "#{ZNYR_20210324_04}", 
	[4] = "#{ZNYR_20210324_05}", 
	[5] = "#{ZNYR_20210324_06}", 
	[6] = "#{ZNYR_20210318_18}", 
	[7] = "#{ZNYR_20210318_19}", 
	[8] = "#{ZNYR_20210319_16}", 
}
-- 对话阶段界面--阶段指引
local g_StepNpcPos = 
{
	[1] = { x = 249, z = 302, sceneId = 0, name = "阿萝", }, 
	[2] = { x = 270, z = 255, sceneId = 1, name = "江晓", }, 
	[3] = { x = 337, z = 322, sceneId = 1, name = "", }, 
	[4] = { x = 375, z = 342, sceneId = 1, name = "", }, 
	[5] = { x = 208, z = 190, sceneId = 1, name = "", }, 
	[6] = { x = 270, z = 255, sceneId = 1, name = "江晓", }, 
	[7] = { x = 249, z = 302, sceneId = 0, name = "阿萝", }, 
	[8] = { x = 249, z = 302, sceneId = 0, name = "阿萝", }, 
}

-- 对话结束界面--奖励数据
local g_Prize = 
{
	[1] = { pic = "set:Jincheng03 image:Zunguinvwang", picname = "set:Jincheng01 image:Tag_Zunguinvwang", str1 = "#{ZNYR_20210322_02}", str3 = "#{ZNYR_20210322_05}", }, 
	[2] = { pic = "set:Jincheng02 image:Taohuaxianzi", picname = "set:Jincheng01 image:Tag_Taohuaxianzi", str1 = "#{ZNYR_20210322_09}", str3 = "#{ZNYR_20210322_11}", }, 
	[3] = { pic = "set:Jincheng03 image:Yumiangongzi", picname = "set:Jincheng01 image:Tag_Yumiangongzi", str1 = "#{ZNYR_20210322_06}", str3 = "#{ZNYR_20210322_08}", }, 
	[4] = { pic = "set:Jincheng02 image:Yulanxianzi", picname = "set:Jincheng01 image:Tag_Yulanxianzi", str1 = "#{ZNYR_20210322_12}", str3 = "#{ZNYR_20210322_14}", }, 
	[5] = { pic = "set:Jincheng02 image:Mudanxianzi", picname = "set:Jincheng01 image:Tag_Mudanxianzi", str1 = "#{ZNYR_20210322_15}", str3 = "#{ZNYR_20210322_17}", }, 
}

--=========
-- PreLoad()
--=========
function AnniversaryPreheat_PreLoad()
		this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function AnniversaryPreheat_OnLoad()	
		g_Frame_UnifiedPosition = AnniversaryPreheat_Frame_BK:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function AnniversaryPreheat_OnEvent(event)
		if (event == "UI_COMMAND" and tonumber(arg0) == 88839701) then--对话阶段界面		
				g_Step = Get_XParam_INT(0)
				local bUpdate = Get_XParam_INT(1)
				if bUpdate ~= nil and bUpdate == 1 then
						if this:IsVisible() then-- 界面打开时更新
								AnniversaryPreheat_Update1()
						end
				else
						AnniversaryPreheat_Update1()
				end
		elseif (event == "UI_COMMAND" and tonumber(arg0) == 88839702) then--对话结束界面
				local nIndex = Get_XParam_INT(0)
				local nValue = Get_XParam_INT(1)
				local bReset = Get_XParam_INT(2)
				AnniversaryPreheat_Update2(nIndex, nValue, bReset)
		elseif (event == "UI_COMMAND" and tonumber(arg0) == 88839705) then--关闭界面		
				AnniversaryPreheat_Close()	
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				AnniversaryPreheat_Close()	
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				AnniversaryPreheat_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				AnniversaryPreheat_On_ResetPos()	
		end		
end

--=========
-- 重置
--=========
function AnniversaryPreheat_On_ResetPos()
		AnniversaryPreheat_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 关闭界面
--=========
function AnniversaryPreheat_Close()
		this:Hide()
end

--=========
-- 对话阶段界面
--=========
function AnniversaryPreheat_Update1()

		if g_Step < 0 or g_Step >= table.getn(g_StepDesc) then
				return
		end
		
		-- 显示界面
		this:Show()
		AnniversaryPreheat_Client1:Hide()
		AnniversaryPreheat_Client:Show()
			
		-- 阶段指引
		AnniversaryPreheat_Text1:SetText(g_StepDesc[g_Step+1])

end

--=========
-- 对话结束界面
--=========
function AnniversaryPreheat_Update2(nIndex, nValue, bReset)

		if nIndex == nil or nIndex < 0 then
				return
		end
		local tData = g_Prize[nIndex]
		if tData == nil then
				return
		end
		if nValue == nil or nValue < 0 then
				return
		end
		if bReset == nil or bReset < 0 or bReset > 1 then
				return
		end
		
		-- 显示界面
		this:Show()
		AnniversaryPreheat_Client:Hide()
		AnniversaryPreheat_Client1:Show()
		
		-- 图标
		AnniversaryPreheat_Pic5:SetProperty( "Image", tData.pic )
			
		-- 名字
		AnniversaryPreheat_BKP_Rw:SetProperty( "Image", tData.picname )		
			
		-- 文字
		AnniversaryPreheat_XingGe_Text1:SetText(""..tData.str1)
		AnniversaryPreheat_XingGe_Text3:SetText(""..tData.str3)
		
		-- 按钮
		if bReset == 1 then
				AnniversaryPreheat_RewardButton:Hide()
				AnniversaryPreheat_RewardButton2:Hide()
				AnniversaryPreheat_RewardButton3:Show()
		else
				AnniversaryPreheat_RewardButton:Show()
				AnniversaryPreheat_RewardButton2:Show()
				AnniversaryPreheat_RewardButton3:Hide()
		end
		
end	

--=========
-- 重来一次
--=========
function AnniversaryPreheat_ResetClicked()
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnReset")
				Set_XSCRIPT_ScriptID(888397)
				Set_XSCRIPT_Parameter( 0, 0 )
				Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
end

--=========
-- 点击领取
--=========
function AnniversaryPreheat_PrizeClicked()
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnPrize")
				Set_XSCRIPT_ScriptID(888397)
				Set_XSCRIPT_Parameter( 0, 0 )
				Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
end

--=========
-- 点击前往
--=========
function AnniversaryPreheat_GotoClicked()

		if g_Step < 0 or g_Step >= table.getn(g_StepNpcPos) then
				return
		end
		
		local tNpc = g_StepNpcPos[g_Step+1]
		if tNpc == nil then
				return
		end
		
		if tNpc.name ~= "" then
				AutoRuntoTargetExWithName(tNpc.x, tNpc.z, tNpc.sceneId, tNpc.name)
		else
				AutoRunToTargetEx(tNpc.x, tNpc.z, tNpc.sceneId)
		end
		
end
	
--=========
-- 小问号
--=========
function AnniversaryPreheat_Help()
		PushEvent("CCSHOP_HELP", 132)	
end