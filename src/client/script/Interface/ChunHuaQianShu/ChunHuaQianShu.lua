
local g_ChunHuaQianShu_UnifiedPosition
local g_ChunHuaQianShu_State = 0 -- 0代表收集花枝 1代表升级花环

local g_HuaZhiUITalbe = {}
local g_HuaHuanUITalbe = {}
local g_HuaHuanType = 1  --默认为草木花环
local g_LevelLimit = 30
local g_BeginTime = 20260316
local g_EndTime   = 20260401
local g_IsFinish = 0

local g_ChunHuaQianShu_Kaji = 
{
	[0] = {
		[1] = {[1]="#{SHH_211221_07}"},
		[2] = {[1]= "#{SHH_211221_09}", [2]= "#{SHH_211221_10}", [3]="#{SHH_211221_11}"},
	},
	[1] = {
		[1] = {[1]="#{SHH_211221_82}"},
		[2] = {[1]= "#{SHH_211221_84}",[2]= "#{SHH_211221_85}", [3]="#{SHH_211221_11}"},
	}
} 



function ChunHuaQianShu_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function ChunHuaQianShu_OnLoad()
	g_ChunHuaQianShu_UnifiedPosition = ChunHuaQianShu_Frame:GetProperty("UnifiedPosition")
	
	g_HuaZhiUITalbe = 
	{
		[1]=
		{
			HuaZhiImage = ChunHuaQianShu_Client_Main_1,
			NoHuaZhiImage = ChunHuaQianShu_Client_Main_1_BK,
			State = 0,
		},
		[2]=
		{
			HuaZhiImage = ChunHuaQianShu_Client_Main_4,
			NoHuaZhiImage = ChunHuaQianShu_Client_Main_4_BK,
			State = 0,
		},
		[3]=
		{
			HuaZhiImage = ChunHuaQianShu_Client_Main_5,
			NoHuaZhiImage = ChunHuaQianShu_Client_Main_5_BK,
			State = 0,
		},
		-- [4]=
		-- {
		-- 	HuaZhiImage = ChunHuaQianShu_Client_Main_5,
		-- 	NoHuaZhiImage = ChunHuaQianShu_Client_Main_5_BK,
		-- 	State = 0,
		-- },
		-- [5]=
		-- {
		-- 	HuaZhiImage = ChunHuaQianShu_Client_Main_4,
		-- 	NoHuaZhiImage = ChunHuaQianShu_Client_Main_4_BK,
		-- 	State = 0,
		-- },
	}

	g_HuaHuanUITalbe = 
	{
		[1] = 
		{
			HuaHuanImage = ChunHuaQianShu_Frame1_Info,
			-- HuoYueStr = "#{SHH_211221_09}",
		},
		[2] = 
		{
			HuaHuanImage = ChunHuaQianShu_Frame2_Info,
			-- HuoYueStr = "#{SHH_211221_10}",
		},
		[3] = 
		{
			HuaHuanImage = ChunHuaQianShu_Frame3_Info,
			-- HuoYueStr = "#{SHH_211221_11}",
		},
	}

end


function ChunHuaQianShu_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 2022011201) then  --id为临时的 
		if this:IsVisible() then
			ChunHuaQianShu_Close()
		end
		g_ChunHuaQianShu_State = Get_XParam_INT(0)
		if g_ChunHuaQianShu_State == 0 then
			for i=1,3 do
				g_HuaZhiUITalbe[i].State = Get_XParam_INT(i)
			end
		else
			g_HuaHuanType = Get_XParam_INT(1)
			-- g_HuaHuanType = 2
			-- PushDebugMessage("g_HuaHuanType:"..tostring(g_HuaHuanType))
			g_IsFinish = Get_XParam_INT(2)
		end
		ChunHuaQianShu_Open()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ChunHuaQianShu_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ChunHuaQianShu_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ChunHuaQianShu_Close()
	end

end

function ChunHuaQianShu_On_ResetPos()
	ChunHuaQianShu_Frame:SetProperty("UnifiedPosition", g_ChunHuaQianShu_UnifiedPosition)

end

function ChunHuaQianShu_DoCondition()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{SHH_211221_02}")
		return 0
	end
	local curDay = DataPool:GetServerDayTime()
	if curDay > g_EndTime or curDay < g_BeginTime then
		PushDebugMessage("#{SHH_211221_01}")
		return 0
	end   
	
	return 1
end

function ChunHuaQianShu_GoToHuaZhiNpc()
	-- PushDebugMessage("xtc11")
	if ChunHuaQianShu_DoCondition() == 0 then
		return 
	end
	AutoRuntoTargetExWithName(296, 271, 0, "何采薇")
	-- AutoRunToTargetEx(296,271,0)
end

function ChunHuaQianShu_GoToYingFangShu()
	if ChunHuaQianShu_DoCondition() == 0 then
		return 
	end
	AutoRuntoTargetExWithName(309, 201, 0, "盈芳树")
	-- AutoRunToTargetEx(309,201,0)
end

--点击界面上问号
function ChunHuaQianShu_Help()
	-- PushDebugMessage("xtc11")
	if Player:GetData("IsOriginalJD") == 1 then
		PushEvent("CCSHOP_HELP", 243)
	else
		local kjtype   = KaJi:LuaFnGetKaJiType(58)
		if kjtype == 0 then
			PushEvent("CCSHOP_HELP", 152)
		elseif kjtype == 1 then
			PushEvent("CCSHOP_HELP", 155)
		end
	end
end

--界面点击关闭按钮
function ChunHuaQianShu_Close()
	this:Hide()
end

function ChunHuaQianShu_OnHide()
	g_ChunHuaQianShu_State = 0
	g_HuaHuanType = 1
	g_IsFinish = 0
	for i=1,3 do
		g_HuaZhiUITalbe[i].State = 0
	end
end

function ChunHuaQianShu_Open()
	this:Show()

	-- g_HuaZhiUITalbe[i].NoHuaZhiImage:Show()

	local kjtype   = KaJi:LuaFnGetKaJiType(58)
	ChunHuaQianShu_Info:SetText(g_ChunHuaQianShu_Kaji[kjtype][1][1])

	--向服务器发起请求 判断是在什么状态 花枝是否收集齐备
	if g_ChunHuaQianShu_State == 0 then
		ChunHuaQianShu_Client_Main:Show()
		ChunHuaQianShu_Client:Hide()
		local isHaveCount = 0
		for i=1,3 do
			if g_HuaZhiUITalbe[i].State == 0 then
				g_HuaZhiUITalbe[i].NoHuaZhiImage:Show()
				g_HuaZhiUITalbe[i].HuaZhiImage:Hide()
			else
				isHaveCount = isHaveCount + 1
				g_HuaZhiUITalbe[i].NoHuaZhiImage:Hide()
				g_HuaZhiUITalbe[i].HuaZhiImage:Show()
			end
		end
		
		ChunHuaQianShu_Main_Info:SetText(ScriptGlobal_Format("#{SHH_211221_88}",isHaveCount))
	else
		ChunHuaQianShu_Client_Main:Hide()
		ChunHuaQianShu_Client:Show()
		for i=1,3 do
			if i == g_HuaHuanType then
				g_HuaHuanUITalbe[i].HuaHuanImage:Show()
				-- ChunHuaQianShu_Frame2_Text:SetText(g_HuaHuanUITalbe[i].HuoYueStr)
				ChunHuaQianShu_Frame2_Text:SetText(g_ChunHuaQianShu_Kaji[kjtype][2][i])
			else
				g_HuaHuanUITalbe[i].HuaHuanImage:Hide()
			end
		end
		if g_IsFinish == 1 then
		    ChunHuaQianShu_Frame2_Text:SetText("#{SHH_211221_12}")
		end

	end


end
