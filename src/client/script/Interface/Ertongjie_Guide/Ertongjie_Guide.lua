--儿童节整合

--time代表的是活动时间 各个功能自己填写 如果有多个时间阶段 不同的时间显示不同的tips 那么就都填写上
--tips 根据time配置的时间 根据 各个时间间隔显示不同的tips
--举例说明 最普通的就是两个时间A-B tips 就有三个  时间处于A之前显示tips1 处于A-B之间显示tips2 处于B之后显示Tips3
local g_Ertongjie_Guide_Event = {
	[1] = {time={20260528,20260614,}, btntips={"before","doing","after",},},			--鬼抓人活动
	[2] = {time={20260528,20260614,}, btntips={"#{ETJHD_220421_11}","#{ETJHD_220421_02}","#{ETJHD_220421_03}",},},			--吹气球活动
	[3] = {time={20260528,20260614,}, btntips={"#{ETDDS_220406_03}","#{ETDDS_220406_04}","#{ETDDS_220406_05}",},},			--打地鼠活动
	[4] = {time={20260528,20260614,}, btntips={"#{DBZH_220419_10}","#{DBZH_220419_10}","#{DBZH_220419_10}",},},			--代币结算玩法
	[5] = {time={20260528,20260614,}, btntips={"#{DWKC_260515_21}","#{QHNF_190429_98}","#{DWKC_190502_88}",},},			--儿童节开船活动
	[6] = {time={20260528,20260614,}, btntips={"#{CJPM_191126_24}","#{CJPM_191126_24}","#{CJPM_191126_24}",},},			--儿童节拍卖玩法
	[7] = {time={20260528,20260614,}, btntips={"#{ETJZH_220414_5}","#{ETJZH_220414_5}","#{ETJZH_220414_5}",},},			--节日礼包
};

local g_Ertongjie_Guide_Frame_UnifiedPosition_Load
local g_Button_Guide_StateTemp = {1,1,1,1,1,1,1}--
local g_Tips_Guide_StateTemp =   {0,0,0,0,0,0,0}--
local g_Ertongjie_Guide_Button ={
}

local g_Ertongjie_Guide_Tip = {
}

local g_Ertongjie_Guide_TextBK 		= {}

local g_Ertongjie_Guide_UIGroup 		= {}
	

local g_BtnLocations = {}
local g_BtnLocationsSJ = {}

local g_BtnImg = {
	[4] = {
		Pushed = "set:Ertongjie_Guide image:Guide_Lianhuawu_Pushed",
		Normal = "set:Ertongjie_Guide image:Guide_Lianhuawu_Normal",
		Hover = "set:Ertongjie_Guide image:Guide_Lianhuawu_Hover",
	},
	[5] = {
		Pushed = "set:Ertongjie_Guide image:Guide_BaoZhou_Pushed",
		Normal = "set:Ertongjie_Guide image:Guide_BaoZhou_Normal",
		Hover = "set:Ertongjie_Guide image:Guide_BaoZhou_Hover",
	},
}
local g_BtnImgSJ = {
	[4] = {
		Pushed = "set:Ertongjie_Guide2 image:Guide2_Lianhuawu_Pushed2",
		Normal = "set:Ertongjie_Guide2 image:Guide2_Lianhuawu_Normal2",
		Hover = "set:Ertongjie_Guide2 image:Guide2_Lianhuawu_Hover2",
	},
	[5] = {
		Pushed = "set:Ertongjie_Guide2 image:Guide2_BaoZhou_Pushed2",
		Normal = "set:Ertongjie_Guide2 image:Guide2_BaoZhou_Normal2",
		Hover = "set:Ertongjie_Guide2 image:Guide2_BaoZhou_Hover2",
	},
}


local g_Ertongjie_GiftBtnTips = 0

function Ertongjie_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	--this:RegisterEvent("ADJEST_UI_POS",false)

end

function Ertongjie_Guide_OnLoad()
	Ertongjie_Guide_LoadControl()
	g_Ertongjie_Guide_Frame_UnifiedPosition_Load = Ertongjie_Guide_Frame_BK:GetProperty("UnifiedPosition")
end
--=========
-- 装载控件
--=========
function Ertongjie_Guide_LoadControl()

	g_Ertongjie_Guide_Button[1] 	= Ertongjie_Guide_Activity1_Button;
	g_Ertongjie_Guide_Button[2] 	= Ertongjie_Guide_Activity2_Button; --
	g_Ertongjie_Guide_Button[3] 	= Ertongjie_Guide_Activity3_Button; --
	g_Ertongjie_Guide_Button[4] 	= Ertongjie_Guide_Activity4_Button;
	g_Ertongjie_Guide_Button[5] 	= Ertongjie_Guide_Activity5_Button;
	g_Ertongjie_Guide_Button[6] 	= Ertongjie_Guide_Activity6_Button;
	g_Ertongjie_Guide_Button[7]		= Ertongjie_Guide_BtnGift;

	g_Ertongjie_Guide_Tip[1] 		= Ertongjie_Guide_Activity1_ButtonTips;
	g_Ertongjie_Guide_Tip[2] 		= Ertongjie_Guide_Activity2_ButtonTips;
	g_Ertongjie_Guide_Tip[3] 		= Ertongjie_Guide_Activity3_ButtonTips;
	g_Ertongjie_Guide_Tip[4] 		= Ertongjie_Guide_Activity4_ButtonTips;
	g_Ertongjie_Guide_Tip[5] 		= Ertongjie_Guide_Activity5_ButtonTips;
	g_Ertongjie_Guide_Tip[6] 		= Ertongjie_Guide_Activity6_ButtonTips;
	g_Ertongjie_Guide_Tip[7]		= Ertongjie_Guide_BtnGift_Tips;


	g_Ertongjie_Guide_TextBK[2] = Ertongjie_Guide_Activity2_TextBK
	g_Ertongjie_Guide_TextBK[3] = Ertongjie_Guide_Activity3_TextBK
	g_Ertongjie_Guide_TextBK[4] = Ertongjie_Guide_Activity4_TextBK
	g_Ertongjie_Guide_TextBK[5] = Ertongjie_Guide_Activity5_TextBK
	g_Ertongjie_Guide_TextBK[6] = Ertongjie_Guide_Activity6_TextBK

	g_Ertongjie_Guide_UIGroup[1] = Ertongjie_Guide_Activity1_BK
	g_Ertongjie_Guide_UIGroup[2] = Ertongjie_Guide_Activity2_BK
	g_Ertongjie_Guide_UIGroup[3] = Ertongjie_Guide_Activity3_BK
	g_Ertongjie_Guide_UIGroup[4] = Ertongjie_Guide_Activity4_BK
	g_Ertongjie_Guide_UIGroup[5] = Ertongjie_Guide_Activity5_BK
	g_Ertongjie_Guide_UIGroup[6] = Ertongjie_Guide_Activity6_BK


	g_BtnLocationsSJ[2] = Ertongjie_Guide_location2:GetProperty("UnifiedPosition")
	g_BtnLocationsSJ[3] = Ertongjie_Guide_location3:GetProperty("UnifiedPosition")
	g_BtnLocationsSJ[4] = Ertongjie_Guide_location4:GetProperty("UnifiedPosition")
	g_BtnLocationsSJ[5] = Ertongjie_Guide_location5:GetProperty("UnifiedPosition")

	g_BtnLocations[2] = Ertongjie_Guide_location2_Normal:GetProperty("UnifiedPosition")
	g_BtnLocations[3] = Ertongjie_Guide_location3_Normal:GetProperty("UnifiedPosition")
	g_BtnLocations[4] = Ertongjie_Guide_location4_Normal:GetProperty("UnifiedPosition")
	g_BtnLocations[5] = Ertongjie_Guide_location5_Normal:GetProperty("UnifiedPosition")

end

function Ertongjie_Guide_UpdateLayout()
	local useNewLayout =   KaJi:LuaFnIsKaJiServer() == 1  or  Player:GetData("IsOriginalJD") == 1
	if g_Button_Guide_StateTemp[6] == 1 then
		useNewLayout = false
	end
	if useNewLayout then
		for index=1,table.getn(g_Ertongjie_Guide_UIGroup)  do
			if g_BtnLocationsSJ[index] then
				g_Ertongjie_Guide_UIGroup[index]:SetProperty("UnifiedPosition", g_BtnLocationsSJ[index])
			end
			if g_BtnImgSJ[index] then
				--活动4和5的按钮样式也修改一下
				g_Ertongjie_Guide_Button[index]: SetProperty("NormalImage", g_BtnImgSJ[index].Normal)
				g_Ertongjie_Guide_Button[index]: SetProperty("HoverImage", g_BtnImgSJ[index].Hover)
				g_Ertongjie_Guide_Button[index]: SetProperty("PushedImage", g_BtnImgSJ[index].Pushed)
			end
		end

	else
		for index=1,table.getn(g_Ertongjie_Guide_UIGroup)  do
			if g_BtnLocations[index] then
				g_Ertongjie_Guide_UIGroup[index]:SetProperty("UnifiedPosition", g_BtnLocations[index])
			end
			if g_BtnImg[index] then
				--活动4和5的按钮样式也修改一下
				g_Ertongjie_Guide_Button[index]: SetProperty("NormalImage", g_BtnImg[index].Normal)
				g_Ertongjie_Guide_Button[index]: SetProperty("HoverImage", g_BtnImg[index].Hover)
				g_Ertongjie_Guide_Button[index]: SetProperty("PushedImage", g_BtnImg[index].Pushed)
			end
		end
	end
end

--=========
-- Event
--=========
function Ertongjie_Guide_OnEvent(event)

	-- if(event == "UI_COMMAND"  )  then --关闭

	-- 	if this:IsVisible() then
	-- 		Ertongjie_Guide_OnHide()
	-- 		return
	-- 	end
	-- else
	if (event == "UI_COMMAND" and tonumber(arg0) == 23200701 )  then --打开
		Ertongjie_Guide_Open()
		this:Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Ertongjie_Guide_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Ertongjie_Guide_OnHide()

	-- elseif event == "ADJEST_UI_POS" then

	-- 	Ertongjie_Guide_On_AdjustPos()

	elseif(event == "UI_COMMAND" and tonumber(arg0) == 23200702) then --显示小红点
		local actnum = table.getn(g_Ertongjie_Guide_Button)
		for index=1,actnum  do
			 local TipsState = Get_XParam_INT(index-1)
			 g_Tips_Guide_StateTemp[index]  = TipsState
		end
		Ertongjie_Guide_ShowButtonTips()
	end

end


--=========
-- 重置
--=========
function Ertongjie_Guide_On_ResetPos()

	Ertongjie_Guide_Frame_BK:SetProperty("UnifiedPosition", g_Ertongjie_Guide_Frame_UnifiedPosition_Load)

end



--=========
-- 关闭
--=========
function Ertongjie_Guide_OnHide()
	this:Hide()
end

--=========
-- 打开
--=========
function Ertongjie_Guide_Open()
	for index=1,table.getn(g_Ertongjie_Guide_Button) do
		g_Ertongjie_Guide_Button[index]:Hide()
		g_Ertongjie_Guide_Tip[index]:Hide()
		--按钮Group
		if g_Ertongjie_Guide_UIGroup[index] then
			g_Ertongjie_Guide_UIGroup[index]:Hide()
		end
	end

	for index=1,table.getn(g_Ertongjie_Guide_Button)  do
		local DataState = Get_XParam_INT(index-1)
		local TipsState = math.mod(DataState, 10)
		local ButtonState = math.floor(DataState / 10)

		g_Button_Guide_StateTemp[index] 	= ButtonState
		g_Tips_Guide_StateTemp[index] 	    = TipsState

   end

	local curDay = DataPool:GetServerDayTime()
	for index=1,table.getn(g_Ertongjie_Guide_Event) do
		local isButtonShow = g_Button_Guide_StateTemp[index]
		local isTipsShow   = g_Tips_Guide_StateTemp[index]
		local event  	   = g_Ertongjie_Guide_Event[index]
		if isButtonShow == 1 then
			g_Ertongjie_Guide_Button[index]:Show()
			if g_Ertongjie_Guide_UIGroup[index] then
				g_Ertongjie_Guide_UIGroup[index]:Show()
			end
			if curDay < event.time[1] then
				g_Ertongjie_Guide_Button[index]:SetToolTip(event.btntips[1])
			elseif curDay > event.time[table.getn(event.time)] and event.btntips[table.getn(event.time)+1] ~= nil  then
				g_Ertongjie_Guide_Button[index]:SetToolTip(event.btntips[table.getn(event.time)+1])
			end
			for i = 1, table.getn(event.time)-1 do
				if curDay >= event.time[i] and curDay <= event.time[i+1] and event.btntips[i+1] ~= nil then
					g_Ertongjie_Guide_Button[index]:SetToolTip(event.btntips[i+1])
				end
			end
			if isTipsShow == 1 then
				g_Ertongjie_Guide_Tip[index]:Show()
			end
		end
	end

	--设置小红点
	Ertongjie_Guide_ShowButtonTips()
	--

	--更新界面布局
	Ertongjie_Guide_UpdateLayout()
end

--===============================================
-- 设置Button 小红点
--===============================================
function Ertongjie_Guide_ShowButtonTips()
	local IsShowMiniMapPoint = 0
	for index=1,table.getn(g_Tips_Guide_StateTemp) do
		if g_Tips_Guide_StateTemp[index] == 1 and g_Button_Guide_StateTemp[index] == 1 then
			IsShowMiniMapPoint = 1
			if this:IsVisible() then
				g_Ertongjie_Guide_Tip[index]:Show()
			end
		else
			g_Ertongjie_Guide_Tip[index]:Hide()
		end
	end

	--PushEvent("CHILDRENSDAYZHENGHETIPS",  IsShowMiniMapPoint)
	Lua_ShowQuickEnterPointTip(35, IsShowMiniMapPoint)

end

--===============================================
-- 打开老的儿童节整合界面 索引到各个功能
--===============================================
function Ertongjie_Guide_Clicked( clickId )
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then --鬼抓人活动

	elseif clickId == 2 then	--吹气球活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenChildrenDayBallonUI")
			Set_XSCRIPT_ScriptID(892800)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 3 then --打地鼠活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenEnterUI")
			Set_XSCRIPT_ScriptID(998023)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 4 then --代币结算玩法
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenDaiBiUI")
			Set_XSCRIPT_ScriptID(998025)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 5 then --儿童节开船活动
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowClientUI")
			Set_XSCRIPT_ScriptID(505087)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 6 then --儿童节拍卖玩法
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowClientUI")
			Set_XSCRIPT_ScriptID(440003)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, 0)
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end
end


function Ertongjie_Guide_BtnGift_Click()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("Click_Gift")
	Set_XSCRIPT_ScriptID(232007)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
