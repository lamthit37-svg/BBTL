--******************************************************************************
-- 入口界面
--******************************************************************************
local g_XiQu_Mini_Frame_UnifiedXPosition;
local g_XiQu_Mini_Frame_UnifiedYPosition;

--UI
local g_XiQu_Mini_Info = {}
local g_XiQu_Mini_Result = {}


local g_XiQu_Mini_Dict = 
{
	[0] = {"#{XQYJ_220527_73}", "#{XQYJ_220527_74}", "#{XQYJ_220527_76}"},
	[1] = {"#{XQYJ_220527_73}", "#{XQYJ_220527_75}", "#{XQYJ_220527_76}"},
}
local g_XiQu_Mini_DoneDict = 
{
	[0] = "#{XQYJ_220527_78}",
	[1] = "#{XQYJ_220527_77}",
}

--===============================================
-- OnLoad()
--===============================================
function XiQu_Mini_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function XiQu_Mini_OnLoad()

	-- 保存界面的默认相对位置
	g_XiQu_Mini_Frame_UnifiedXPosition = XiQu_Mini_Frame:GetProperty("UnifiedXPosition");
	g_XiQu_Mini_Frame_UnifiedYPosition = XiQu_Mini_Frame:GetProperty("UnifiedYPosition");
	
	--UI
	g_XiQu_Mini_Info[1] = XiQu_Mini_Title1
	g_XiQu_Mini_Info[2] = XiQu_Mini_Title2
	g_XiQu_Mini_Info[3] = XiQu_Mini_Title3
	g_XiQu_Mini_Result[1] = XiQu_Mini_Result1
	g_XiQu_Mini_Result[2] = XiQu_Mini_Result2
	g_XiQu_Mini_Result[3] = XiQu_Mini_Result3
	
end


--===============================================Shuangdan_Huoguo_Guide

-- OnEvent()
--===============================================

function XiQu_Mini_OnEvent(event)
	if(event == "UI_COMMAND") then
		
		local arg = tonumber(arg0)
		
		--打开界面
		if arg == 99812002 then
			local param1 = Get_XParam_INT(0)  --开关
			local param2 = Get_XParam_INT(1)  --性别
			local param3 = Get_XParam_INT(2)  --动作1
			local param4 = Get_XParam_INT(3)  --动作2
			local param5 = Get_XParam_INT(4)  --动作3
			if param1 == 1 then   --打开
				XiQu_Mini_Update(param2,param3,param4,param5)
				this:Show()		
			elseif param1 == 2 then   --刷新
				XiQu_Mini_Update(param2,param3,param4,param5)
			else
				XiQu_Mini_Close()
				return				
			end
		end
		return
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		XiQu_Mini_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		XiQu_Mini_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		XiQu_Mini_Close()
	end
end


function XiQu_Mini_Update(sex,a1,a2,a3)
	if sex ~= 0 and sex~= 1 then sex = 0 end
	--PushDebugMessage(a1..a2..a3)
	g_XiQu_Mini_Info[1]:SetText(g_XiQu_Mini_Dict[sex][1])
	g_XiQu_Mini_Info[2]:SetText(g_XiQu_Mini_Dict[sex][2])
	g_XiQu_Mini_Info[3]:SetText(g_XiQu_Mini_Dict[sex][3])
	g_XiQu_Mini_Result[1]:SetText(g_XiQu_Mini_DoneDict[a1])
	g_XiQu_Mini_Result[2]:SetText(g_XiQu_Mini_DoneDict[a2])
	g_XiQu_Mini_Result[3]:SetText(g_XiQu_Mini_DoneDict[a3])
end

function XiQu_Mini_Close()
	XiQu_Mini_OnHide()
end


--===============================================
-- OnHiden
--===============================================
function XiQu_Mini_OnHide()

	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function XiQu_Mini_Frame_On_ResetPos()
	XiQu_Mini_Frame : SetProperty("UnifiedXPosition", g_XiQu_Mini_Frame_UnifiedXPosition);
	XiQu_Mini_Frame : SetProperty("UnifiedYPosition", g_XiQu_Mini_Frame_UnifiedYPosition);
end
