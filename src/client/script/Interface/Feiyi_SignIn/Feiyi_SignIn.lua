-- 2023Q2非遗签到活动

local g_Frame_UnifiedPosition = nil
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local targetId = -1

local g_MaxCount = 6--最大参与次数
local g_CurCount = 0--当前参与次数
local g_PointFlag = 0--今日是否点击过
local g_PrizeFlag = 0--是否领取过奖励
local g_MaxPage = 0--最大展示页面
local g_CurPage = 0--当前展示页面

--文字区域
local g_Data = 
{
	[1] = { text = "#{FYHD_230414_24}", text1 = "#{FYHD_230414_40}", text2 = "#{FYHD_230414_41}", image = "set:FeiYi1 image:FeiYi_Img1", },
	[2] = { text = "#{FYHD_230414_27}", text1 = "#{FYHD_230414_42}", text2 = "#{FYHD_230414_41}", image = "set:FeiYi2 image:FeiYi_Img4", },
	[3] = { text = "#{FYHD_230414_26}", text1 = "#{FYHD_230414_43}", text2 = "#{FYHD_230414_41}", image = "set:FeiYi2 image:FeiYi_Img3", },
	[4] = { text = "#{FYHD_230414_25}", text1 = "#{FYHD_230414_44}", text2 = "#{FYHD_230414_41}", image = "set:FeiYi2 image:FeiYi_Img2", },
	[5] = { text = "#{FYHD_230414_28}", text1 = "#{FYHD_230414_45}", text2 = "#{FYHD_230414_41}", image = "set:FeiYi3 image:FeiYi_Img5", },
	[6] = { text = "#{FYHD_230414_29}", text1 = "#{FYHD_230414_46}", text2 = "#{FYHD_230414_41}", image = "set:FeiYi3 image:FeiYi_Img6", },
}

--=========
-- PreLoad()
--=========
function Feiyi_SignIn_PreLoad()
		this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
		this:RegisterEvent("OBJECT_CARED_EVENT",false)
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function Feiyi_SignIn_OnLoad()	
		g_Frame_UnifiedPosition = Feiyi_SignInFrame:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function Feiyi_SignIn_OnEvent(event)
		if event == "UI_COMMAND" and tonumber(arg0) == 99840901 then
				--关注npc
				targetId = Get_XParam_INT(0)
				if targetId == nil or targetId == -1 then
					Feiyi_SignIn_OnClose()
					return
				end
				objCared = DataPool : GetNPCIDByServerID(tonumber(targetId))
				if objCared == nil or objCared == -1 then
					Feiyi_SignIn_OnClose()
					return
				end
				this:CareObject(objCared, 1, "Feiyi_SignIn")
				local bOpen = Get_XParam_INT(1) 
				g_CurCount = Get_XParam_INT(2) 
				g_PointFlag = Get_XParam_INT(3) 
				g_PrizeFlag = Get_XParam_INT(4) 
				if bOpen ~= nil and bOpen == 1 then--开界面
						this:Show()						
						Feiyi_SignIn_UpdateCommon()
						Feiyi_SignIn_GetMaxPage()
						g_CurPage = g_MaxPage
						Feiyi_SignIn_UpdateByPage()
				else
						if( this:IsVisible() ) then--仅刷新
								Feiyi_SignIn_UpdateCommon()
						end
				end
	  elseif ( event == "OBJECT_CARED_EVENT" ) then
				if(tonumber(arg0) ~= objCared) then
						return
				end
				--如果和NPC的距离大于一定距离或者被删除，自动关闭
				if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
						--关闭界面
						Feiyi_SignIn_OnClose()
				end
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				Feiyi_SignIn_OnClose()
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				Feiyi_SignIn_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				Feiyi_SignIn_On_ResetPos()	
		end		
end

--=========
-- 重置
--=========
function Feiyi_SignIn_On_ResetPos()
		Feiyi_SignInFrame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 清数据
--=========
function Feiyi_SignIn_Clear()
	g_CurCount = 0--当前参与次数
	g_PointFlag = 0--今日是否点击过
	g_PrizeFlag = 0--是否领取过奖励
	g_MaxPage = 0--最大展示页面
	g_CurPage = 0--当前展示页面
	--取消关心
	this:CareObject(objCared, 0, "Feiyi_SignIn")
end

--=========
-- 关闭界面
--=========
function Feiyi_SignIn_OnClose()
		Feiyi_SignIn_Clear()
		this:Hide()
end

--=========
-- 计算当前最大展示页面
--=========
function Feiyi_SignIn_GetMaxPage()
		if g_CurCount >= g_MaxCount then
			g_MaxPage = g_MaxCount
		elseif g_PointFlag == 1 then
				g_MaxPage = g_CurCount
		else
				g_MaxPage = g_CurCount + 1
		end
end

--=========
-- 界面刷新
--=========
function Feiyi_SignIn_UpdateCommon()
		
		-- 累计次数足够
		if g_CurCount >= g_MaxCount then
			-- 按钮
			Feiyi_SignIn_Button:Disable()
			-- 累计次数
			Feiyi_SignIn_Text:SetText("#{FYHD_230414_35}")
		-- 累计次数不够
		else
			-- 按钮
			if g_PointFlag == 1 then--已阅读
				Feiyi_SignIn_Button:Disable()
			else--未阅读
				Feiyi_SignIn_Button:Enable()
			end
			-- 累计参与次数
			local szCount = ScriptGlobal_Format("#{FYHD_230414_34}",g_CurCount)
			Feiyi_SignIn_Text:SetText( szCount )
		end

end


--=========
-- 界面刷新
--=========
function Feiyi_SignIn_UpdateByPage()

		local tData = g_Data[g_CurPage]
		if tData == nil then
			return
		end
		
		-- 图片区域
		Feiyi_SignIn_ImageBkB:SetProperty("Image",tData.image)
		-- 文字区域
		Feiyi_SignIn_Info:SetText(tData.text)
		Feiyi_SignIn_Info2:SetText(tData.text1)
		Feiyi_SignIn_Info3:SetText(tData.text2)
			
		-- 翻页按钮
		if g_CurPage > 1 then
			Feiyi_SignIn_LeftArrow:Enable()
		else
			Feiyi_SignIn_LeftArrow:Disable()
		end
		if g_CurPage < g_MaxPage then
			Feiyi_SignIn_RightArrow:Enable()
		else
			Feiyi_SignIn_RightArrow:Disable()
		end

end

--=========
-- 点击上一页按钮
--=========
function Feiyi_SignIn_LeftArrowClicked()
		if g_CurPage <= 1 then
			return
		end
		g_CurPage = g_CurPage - 1
		Feiyi_SignIn_UpdateByPage()
end

--=========
-- 点击下一页按钮
--=========
function Feiyi_SignIn_RightArrowClicked()
		if g_CurPage >= g_MaxPage then
			return
		end
		g_CurPage = g_CurPage + 1
		Feiyi_SignIn_UpdateByPage()
end

--=========
-- 点击按钮
--=========
function Feiyi_SignIn_Clicked()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnPrize")
			Set_XSCRIPT_ScriptID(998409)
			Set_XSCRIPT_Parameter(0,targetId)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
end

--=========
-- 小问号
--=========
function Feiyi_SignIn_Help()
		PushEvent("CCSHOP_HELP", 194)	
end
