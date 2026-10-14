--Anniversary_Weaving

local g_Anniversary_Weaving_Frame_UnifiedPosition;

local g_Anniversary_Weaving_curlevel = 0;
local g_Anniversary_Weaving_curkeylist = 0;
local g_Anniversary_Weaving_curpress = 0;
local g_Anniversary_Weaving_tick = 0;

local g_Anniversary_Weaving_keywindow = {}

local g_Anniversary_Weaving_level_iamge = {
	"set:Anniversary_Guide3 image:Pass1",
	"set:Anniversary_Guide3 image:Pass2",
	"set:Anniversary_Guide3 image:Pass3",
	"set:Anniversary_Guide3 image:Pass4",
	"set:Anniversary_Guide3 image:Pass5",
	"set:Anniversary_Guide3 image:Pass6",
	"set:Anniversary_Guide3 image:Pass7",
	"set:Anniversary_Guide3 image:Pass8",
	"set:Anniversary_Guide3 image:Pass9",
	"set:Anniversary_Guide3 image:Pass10",
}

local g_Anniversary_Weaving_3Key_Name ={}
local g_Anniversary_Weaving_3Key_Wrong ={}
local g_Anniversary_Weaving_3Key_Image ={}
local g_Anniversary_Weaving_4Key_Name ={}
local g_Anniversary_Weaving_4Key_Wrong ={}
local g_Anniversary_Weaving_4Key_Image ={}
local g_Anniversary_Weaving_5Key_Name ={}
local g_Anniversary_Weaving_5Key_Wrong ={}
local g_Anniversary_Weaving_5Key_Image ={}
local g_Anniversary_Weaving_6Key_Name ={}
local g_Anniversary_Weaving_6Key_Wrong ={}
local g_Anniversary_Weaving_6Key_Image ={}
local g_Anniversary_Weaving_7Key_Name ={}
local g_Anniversary_Weaving_7Key_Wrong ={}
local g_Anniversary_Weaving_7Key_Image ={}

local Anniversary_Weaving_KeyList_Name = {}
local Anniversary_Weaving_KeyList_Wrong = {}
local Anniversary_Weaving_KeyList_Image = {}

local Anniversary_Weaving_Award_Dis = {}
local Anniversary_Weaving_Award_Normal = {}

local g_Anniversary_Award_Flag = {0,0,0,0}
local g_Anniversary_IsGetAward = 0

local g_Anniversary_Weaving_keytext = {"F1", "F2", "F3", "F4", "F5", "F6", "F7"}

local g_Anniversary_Weaving_NpcId = -1

local g_Anniversary_Time = 10   --5s一次

local g_Anniversary_CurClient = 1

--关卡列表
local g_Anniversary_Weaving_LevelTbl = {
	[1] = {keycount=3, loop=1},
	[2] = {keycount=3, loop=2},
	[3] = {keycount=4, loop=2},
	[4] = {keycount=4, loop=3},
	[5] = {keycount=5, loop=3},
	[6] = {keycount=5, loop=4},
	[7] = {keycount=6, loop=4},
	[8] = {keycount=6, loop=5},
	[9] = {keycount=7, loop=5},
	[10] = {keycount=7, loop=6},
}
local g_Anniversary_Weaving_MoveLineUI = {}
local g_Anniversary_Weaving_SuoIndex = 0
local g_Anniversary_Weaving_IsChangeLevel = false
local g_Anniversary_Weaving_HandStart = false
local g_Anniversary_Weaving_ThirdConfirm = false
local g_Anniversary_Weaving_HistoryLineUp = {}

local Anniversary_Weaving_ShanTips = {"甲", "乙", "丙", "丁"}

function Anniversary_Weaving_PreLoad()
	this:RegisterEvent( "UI_COMMAND",true )
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("MSZJ_CONFIRM",false)
end

function Anniversary_Weaving_OnLoad()
	g_Anniversary_Weaving_keywindow[1] = Anniversary_Weaving_3Key
	g_Anniversary_Weaving_keywindow[2] = Anniversary_Weaving_4Key
	g_Anniversary_Weaving_keywindow[3] = Anniversary_Weaving_5Key
	g_Anniversary_Weaving_keywindow[4] = Anniversary_Weaving_6Key
	g_Anniversary_Weaving_keywindow[5] = Anniversary_Weaving_7Key
	
	g_Anniversary_Weaving_3Key_Name[1] = Anniversary_Weaving_3Key_Key1Name
	g_Anniversary_Weaving_3Key_Name[2] = Anniversary_Weaving_3Key_Key2Name
	g_Anniversary_Weaving_3Key_Name[3] = Anniversary_Weaving_3Key_Key3Name
	
	g_Anniversary_Weaving_3Key_Wrong[1] = Anniversary_Weaving_3Key_Key1_Wrong
	g_Anniversary_Weaving_3Key_Wrong[2] = Anniversary_Weaving_3Key_Key2_Wrong
	g_Anniversary_Weaving_3Key_Wrong[3] = Anniversary_Weaving_3Key_Key3_Wrong

	g_Anniversary_Weaving_3Key_Image[1] = Anniversary_Weaving_3Key_Key1
	g_Anniversary_Weaving_3Key_Image[2] = Anniversary_Weaving_3Key_Key2
	g_Anniversary_Weaving_3Key_Image[3] = Anniversary_Weaving_3Key_Key3
		
	g_Anniversary_Weaving_4Key_Name[1] = Anniversary_Weaving_4Key_Key1Name
	g_Anniversary_Weaving_4Key_Name[2] = Anniversary_Weaving_4Key_Key2Name
	g_Anniversary_Weaving_4Key_Name[3] = Anniversary_Weaving_4Key_Key3Name
	g_Anniversary_Weaving_4Key_Name[4] = Anniversary_Weaving_4Key_Key4Name
	
	g_Anniversary_Weaving_4Key_Wrong[1] = Anniversary_Weaving_4Key_Key1_Wrong
	g_Anniversary_Weaving_4Key_Wrong[2] = Anniversary_Weaving_4Key_Key2_Wrong
	g_Anniversary_Weaving_4Key_Wrong[3] = Anniversary_Weaving_4Key_Key3_Wrong
	g_Anniversary_Weaving_4Key_Wrong[4] = Anniversary_Weaving_4Key_Key4_Wrong

	g_Anniversary_Weaving_4Key_Image[1] = Anniversary_Weaving_4Key_Key1
	g_Anniversary_Weaving_4Key_Image[2] = Anniversary_Weaving_4Key_Key2
	g_Anniversary_Weaving_4Key_Image[3] = Anniversary_Weaving_4Key_Key3
	g_Anniversary_Weaving_4Key_Image[4] = Anniversary_Weaving_4Key_Key4

	g_Anniversary_Weaving_5Key_Name[1] = Anniversary_Weaving_5Key_Key1Name
	g_Anniversary_Weaving_5Key_Name[2] = Anniversary_Weaving_5Key_Key2Name
	g_Anniversary_Weaving_5Key_Name[3] = Anniversary_Weaving_5Key_Key3Name
	g_Anniversary_Weaving_5Key_Name[4] = Anniversary_Weaving_5Key_Key4Name
	g_Anniversary_Weaving_5Key_Name[5] = Anniversary_Weaving_5Key_Key5Name
	
	g_Anniversary_Weaving_5Key_Wrong[1] = Anniversary_Weaving_5Key_Key1_Wrong
	g_Anniversary_Weaving_5Key_Wrong[2] = Anniversary_Weaving_5Key_Key2_Wrong
	g_Anniversary_Weaving_5Key_Wrong[3] = Anniversary_Weaving_5Key_Key3_Wrong
	g_Anniversary_Weaving_5Key_Wrong[4] = Anniversary_Weaving_5Key_Key4_Wrong
	g_Anniversary_Weaving_5Key_Wrong[5] = Anniversary_Weaving_5Key_Key5_Wrong

	g_Anniversary_Weaving_5Key_Image[1] = Anniversary_Weaving_5Key_Key1
	g_Anniversary_Weaving_5Key_Image[2] = Anniversary_Weaving_5Key_Key2
	g_Anniversary_Weaving_5Key_Image[3] = Anniversary_Weaving_5Key_Key3
	g_Anniversary_Weaving_5Key_Image[4] = Anniversary_Weaving_5Key_Key4
	g_Anniversary_Weaving_5Key_Image[5] = Anniversary_Weaving_5Key_Key5
	
	g_Anniversary_Weaving_6Key_Name[1] = Anniversary_Weaving_6Key_Key1Name
	g_Anniversary_Weaving_6Key_Name[2] = Anniversary_Weaving_6Key_Key2Name
	g_Anniversary_Weaving_6Key_Name[3] = Anniversary_Weaving_6Key_Key3Name
	g_Anniversary_Weaving_6Key_Name[4] = Anniversary_Weaving_6Key_Key4Name
	g_Anniversary_Weaving_6Key_Name[5] = Anniversary_Weaving_6Key_Key5Name
	g_Anniversary_Weaving_6Key_Name[6] = Anniversary_Weaving_6Key_Key6Name
	
	g_Anniversary_Weaving_6Key_Wrong[1] = Anniversary_Weaving_6Key_Key1_Wrong
	g_Anniversary_Weaving_6Key_Wrong[2] = Anniversary_Weaving_6Key_Key2_Wrong
	g_Anniversary_Weaving_6Key_Wrong[3] = Anniversary_Weaving_6Key_Key3_Wrong
	g_Anniversary_Weaving_6Key_Wrong[4] = Anniversary_Weaving_6Key_Key4_Wrong
	g_Anniversary_Weaving_6Key_Wrong[5] = Anniversary_Weaving_6Key_Key5_Wrong
	g_Anniversary_Weaving_6Key_Wrong[6] = Anniversary_Weaving_6Key_Key6_Wrong

	g_Anniversary_Weaving_6Key_Image[1] = Anniversary_Weaving_6Key_Key1
	g_Anniversary_Weaving_6Key_Image[2] = Anniversary_Weaving_6Key_Key2
	g_Anniversary_Weaving_6Key_Image[3] = Anniversary_Weaving_6Key_Key3
	g_Anniversary_Weaving_6Key_Image[4] = Anniversary_Weaving_6Key_Key4
	g_Anniversary_Weaving_6Key_Image[5] = Anniversary_Weaving_6Key_Key5
	g_Anniversary_Weaving_6Key_Image[6] = Anniversary_Weaving_6Key_Key6
		
	g_Anniversary_Weaving_7Key_Name[1] = Anniversary_Weaving_7Key_Key1Name
	g_Anniversary_Weaving_7Key_Name[2] = Anniversary_Weaving_7Key_Key2Name
	g_Anniversary_Weaving_7Key_Name[3] = Anniversary_Weaving_7Key_Key3Name
	g_Anniversary_Weaving_7Key_Name[4] = Anniversary_Weaving_7Key_Key4Name
	g_Anniversary_Weaving_7Key_Name[5] = Anniversary_Weaving_7Key_Key5Name
	g_Anniversary_Weaving_7Key_Name[6] = Anniversary_Weaving_7Key_Key6Name
	g_Anniversary_Weaving_7Key_Name[7] = Anniversary_Weaving_7Key_Key7Name
	
	g_Anniversary_Weaving_7Key_Wrong[1] = Anniversary_Weaving_7Key_Key1_Wrong
	g_Anniversary_Weaving_7Key_Wrong[2] = Anniversary_Weaving_7Key_Key2_Wrong
	g_Anniversary_Weaving_7Key_Wrong[3] = Anniversary_Weaving_7Key_Key3_Wrong
	g_Anniversary_Weaving_7Key_Wrong[4] = Anniversary_Weaving_7Key_Key4_Wrong
	g_Anniversary_Weaving_7Key_Wrong[5] = Anniversary_Weaving_7Key_Key5_Wrong
	g_Anniversary_Weaving_7Key_Wrong[6] = Anniversary_Weaving_7Key_Key6_Wrong
	g_Anniversary_Weaving_7Key_Wrong[7] = Anniversary_Weaving_7Key_Key7_Wrong
	
	g_Anniversary_Weaving_7Key_Image[1] = Anniversary_Weaving_7Key_Key1
	g_Anniversary_Weaving_7Key_Image[2] = Anniversary_Weaving_7Key_Key2
	g_Anniversary_Weaving_7Key_Image[3] = Anniversary_Weaving_7Key_Key3
	g_Anniversary_Weaving_7Key_Image[4] = Anniversary_Weaving_7Key_Key4
	g_Anniversary_Weaving_7Key_Image[5] = Anniversary_Weaving_7Key_Key5
	g_Anniversary_Weaving_7Key_Image[6] = Anniversary_Weaving_7Key_Key6
	g_Anniversary_Weaving_7Key_Image[7] = Anniversary_Weaving_7Key_Key7
		
	Anniversary_Weaving_Award_Dis[1] = Anniversary_Weaving_Award1_Dis
	Anniversary_Weaving_Award_Dis[2] = Anniversary_Weaving_Award2_Dis
	Anniversary_Weaving_Award_Dis[3] = Anniversary_Weaving_Award3_Dis
	Anniversary_Weaving_Award_Dis[4] = Anniversary_Weaving_Award4_Dis
	
	Anniversary_Weaving_Award_Normal[1] = Anniversary_Weaving_Award1_Normal
	Anniversary_Weaving_Award_Normal[2] = Anniversary_Weaving_Award2_Normal
	Anniversary_Weaving_Award_Normal[3] = Anniversary_Weaving_Award3_Normal
	Anniversary_Weaving_Award_Normal[4] = Anniversary_Weaving_Award4_Normal

	g_Anniversary_Weaving_MoveLineUI = {
		Anniversary_Weaving_Xian1,
		Anniversary_Weaving_Xian2,
		Anniversary_Weaving_Xian3,
		Anniversary_Weaving_Xian4,
		Anniversary_Weaving_Xian5,
		Anniversary_Weaving_Xian6,
		Anniversary_Weaving_Xian7,
	}
	local from_to_info = string.format("curve:Liner mode:Once duration:0.1 startx:0 starty:0 endx:0 endy:-56")
	for i, v in pairs(g_Anniversary_Weaving_MoveLineUI) do 
		v:Tween_SetInfo("Position", from_to_info)
	end
	Anniversary_Weaving_Suo2:Tween_SetInfo("Position", "curve:Liner mode:Once duration:0.3 startx:0 starty:0 endx:-416 endy:0")
	Anniversary_Weaving_Suo3:Tween_SetInfo("Position", "curve:Liner mode:Once duration:0.3 startx:0 starty:0 endx:416 endy:0")

	Anniversary_Weaving_Times_Begin:Play(false)

	g_Anniversary_Weaving_Frame_UnifiedPosition = Anniversary_Weaving_FrameNULL:GetProperty("UnifiedPosition");

end

function Anniversary_Weaving_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 8930701 then
		local nFlag = Get_XParam_INT( 0 );
		local nOperator = Get_XParam_INT( 1 );
		if nFlag == 0 then
			Anniversary_Weaving_Close()
			return
		end
		
		if nFlag == 1 then
			if nOperator == 1 then
				g_Anniversary_Weaving_NpcId = Get_XParam_INT( 2 )
				g_Anniversary_Award_Flag[1] = Get_XParam_INT( 3 )
				g_Anniversary_Award_Flag[2] = Get_XParam_INT( 4 )
				g_Anniversary_Award_Flag[3] = Get_XParam_INT( 5 )
				g_Anniversary_Award_Flag[4] = Get_XParam_INT( 6 )
				g_Anniversary_IsGetAward = Get_XParam_INT( 7 )
				Anniversary_Weaving_Init()				
				Anniversary_Weaving_MoveLineIndex(-1)
				Anniversary_Weaving_ResetSuoIndex()
			elseif nOperator == 2 then --关卡更新
				if this : IsVisible()  then		
					local curLevel = Get_XParam_INT( 2 );
					g_Anniversary_Weaving_IsChangeLevel = false
					if g_Anniversary_Weaving_curlevel ~= curLevel then
						g_Anniversary_Weaving_curlevel = curLevel
						g_Anniversary_Weaving_IsChangeLevel = true
						Anniversary_Weaving_PassNum:Hide()
						KillTimer("Anniversary_Weaving_TimerThirdProc()")
						SetTimer("Anniversary_Weaving","Anniversary_Weaving_TimerThirdProc()", 3000)
					end
					g_Anniversary_Weaving_curkeylist = Get_XParam_INT( 3 );
					g_Anniversary_Weaving_curpress = Get_XParam_INT( 4 );
					Anniversary_Weaving_PreStart();
					if g_Anniversary_Weaving_HandStart == true then --第一关
						g_Anniversary_Weaving_HandStart = false
						Anniversary_Weaving_Times_Begin:Play(true)
						Anniversary_Weaving_KeyClient:Hide();
						Anniversary_Weaving_MoveLineIndex(-1)
					else
						Anniversary_Weaving_Key_Right:Play(true)
						Anniversary_Weaving_MoveSuoIndex()
					end
				end
			elseif nOperator == 3 then --按键更新
				-- 这个处理不使用8930701这个UICommand了, 使用8930708这个处理
				-- 原因：服务器同时下发了两个8930701的UICommand,导致第一个被顶掉了，只处理了一个UICommand消息
				-- if this : IsVisible()  then
				-- 	local level = Get_XParam_INT( 2 )
				-- 	local curKeyPress = Get_XParam_INT( 3 )
				-- 	local isSuccess = Get_XParam_INT( 4 )
				-- 	local keyIndex = Get_XParam_INT( 5 )
				-- 	Anniversary_Weaving_MoveLineIndex( isSuccess, keyIndex)
				-- 	Anniversary_Weaving_RefreshKey(level, curKeyPress)
				-- end		
			elseif nOperator == 4 then --暂停标记
				if this : IsVisible()  then					
					KillTimer("Anniversary_Weaving_TimerProc()")
				end									
			elseif nOperator == 5 then --继续标记
				if this : IsVisible()  then
					KillTimer("Anniversary_Weaving_TimerProc()")
					g_Anniversary_Weaving_ThirdConfirm = true
					Anniversary_Weaving_Key_Right:Play(true)
					Anniversary_Weaving_MoveSuoIndex()
				end	
			elseif nOperator == 7 then --继续标记
				if this : IsVisible()  then
					KillTimer("Anniversary_Weaving_TimerProc()")
					Anniversary_Weaving_PassClient:Show()
					Anniversary_Weaving_PassText:SetProperty("Image", "set:Anniversary2 image:PassPic2")
				end		
			elseif nOperator == 6 then
				if this : IsVisible() and g_Anniversary_CurClient == 1 then
					g_Anniversary_Award_Flag[1] = Get_XParam_INT( 2 )
					g_Anniversary_Award_Flag[2] = Get_XParam_INT( 3 )
					g_Anniversary_Award_Flag[3] = Get_XParam_INT( 4 )
					g_Anniversary_Award_Flag[4] = Get_XParam_INT( 5 )
					g_Anniversary_IsGetAward = Get_XParam_INT( 6 )
					Anniversary_Weaving_RefreshAward() 
				end						
			end
		end		
	elseif event == "UI_COMMAND" and tonumber( arg0 ) == 8930708 then
		local nFlag = Get_XParam_INT( 0 );
		local nOperator = Get_XParam_INT( 1 );
		local level = Get_XParam_INT( 2 )
		local curKeyPress = Get_XParam_INT( 3 )
		local isSuccess = Get_XParam_INT( 4 )
		local keyIndex = Get_XParam_INT( 5 )
		local lastKeyPress = Get_XParam_INT( 6 )
		Anniversary_Weaving_MoveLineIndex( isSuccess, keyIndex)
		Anniversary_Weaving_WrongKey(level, isSuccess, lastKeyPress)
		Anniversary_Weaving_RefreshKey(level, curKeyPress)
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Anniversary_Weaving_Close()	
	elseif event == "MSZJ_CONFIRM" then --3关二次确认回调
		if this : IsVisible() then
			Anniversary_Weaving_PassNum:SetProperty("Image",g_Anniversary_Weaving_level_iamge[4])
			Anniversary_Weaving_KeyClient:Hide()
			Anniversary_Weaving_GoOnButton:Show()
			g_Anniversary_Weaving_ThirdConfirm = false
		end		
	end
end


function Anniversary_Weaving_Init()
	g_Anniversary_CurClient = 1
	g_Anniversary_Weaving_ThirdConfirm = false
	Anniversary_Weaving_Client1:Show()
	Anniversary_Weaving_Client2:Hide()
	
	g_Anniversary_Weaving_curlevel = 0
	g_Anniversary_Weaving_curkeylist = 0
	g_Anniversary_Weaving_curpress = 0
	
	Anniversary_Weaving_RefreshAward() 
	
	this:Show()
end

function Anniversary_Weaving_PreStart()
	Anniversary_Weaving_Client1:Hide()
	Anniversary_Weaving_Client2:Show()
	Anniversary_Weaving_KeyClient:Show()
	Anniversary_Weaving_GoOnButton:Hide()
	Anniversary_Weaving_Key_Right:Play(false)

	Anniversary_Weaving_PassClient:Hide()

	Anniversary_Weaving_Progress:SetProgress(0,1)
	KillTimer("Anniversary_Weaving_TimerProc()")
end

function Anniversary_Weaving_Start()
	g_Anniversary_CurClient = 2
	Anniversary_Weaving_PreStart()
	Anniversary_Weaving_KeyClient:Show();
	Anniversary_Weaving_PassNum:Show()
	if g_Anniversary_Weaving_curlevel > 0 and g_Anniversary_Weaving_curlevel <= 10 then
		Anniversary_Weaving_PassNum:SetProperty("Image",g_Anniversary_Weaving_level_iamge[g_Anniversary_Weaving_curlevel])
	end
	
	--获取当前按键值
	local keylist = {}
	local nData = g_Anniversary_Weaving_curkeylist
	local Index = 0
	for i = 1, 7 do
		local keynum = math.floor(math.mod(nData, math.pow(10,i))/math.pow(10,i-1))		
		if keynum == 0 then
			break
		else
			Index = Index + 1
			keylist[Index] = keynum
		end
	end

	--按键显示
	Anniversary_Weaving_KeyList_Name[1] = g_Anniversary_Weaving_3Key_Name;
	Anniversary_Weaving_KeyList_Name[2] = g_Anniversary_Weaving_4Key_Name;
	Anniversary_Weaving_KeyList_Name[3] = g_Anniversary_Weaving_5Key_Name;
	Anniversary_Weaving_KeyList_Name[4] = g_Anniversary_Weaving_6Key_Name;
	Anniversary_Weaving_KeyList_Name[5] = g_Anniversary_Weaving_7Key_Name;
	
	Anniversary_Weaving_KeyList_Wrong[1] = g_Anniversary_Weaving_3Key_Wrong;
	Anniversary_Weaving_KeyList_Wrong[2] = g_Anniversary_Weaving_4Key_Wrong;
	Anniversary_Weaving_KeyList_Wrong[3] = g_Anniversary_Weaving_5Key_Wrong;
	Anniversary_Weaving_KeyList_Wrong[4] = g_Anniversary_Weaving_6Key_Wrong;
	Anniversary_Weaving_KeyList_Wrong[5] = g_Anniversary_Weaving_7Key_Wrong;
	
	Anniversary_Weaving_KeyList_Image[1] = g_Anniversary_Weaving_3Key_Image;
	Anniversary_Weaving_KeyList_Image[2] = g_Anniversary_Weaving_4Key_Image;
	Anniversary_Weaving_KeyList_Image[3] = g_Anniversary_Weaving_5Key_Image;
	Anniversary_Weaving_KeyList_Image[4] = g_Anniversary_Weaving_6Key_Image;
	Anniversary_Weaving_KeyList_Image[5] = g_Anniversary_Weaving_7Key_Image;
	
	if Index >= 3 and Index <= 7 then
		for i=1, 5 do 
			if i == Index-2 then
				g_Anniversary_Weaving_keywindow[i]:Show()
				local tbl_name = Anniversary_Weaving_KeyList_Name[i];
				local tbl_wrong = Anniversary_Weaving_KeyList_Wrong[i];
				local tbl_Image = Anniversary_Weaving_KeyList_Image[i];
				for j = 1, table.getn(tbl_name) do
					local num = keylist[j]					
					local AcceArryEx = 10   --自定义快捷键数组中前11个元素不允许玩家自定义
					local keystr = SystemSetup:GetAcceTip(num + AcceArryEx);
					tbl_name[j]:SetText(keystr)
					tbl_wrong[j]:Hide()
					if j == 1 then
						tbl_Image[j]:SetProperty("Image","set:Anniversary_Guide6 image:Key_Hover") --高亮
					else
						tbl_Image[j]:SetProperty("Image","set:Anniversary_Guide6 image:Key_Normal") --正常
					end
				end
			else
				g_Anniversary_Weaving_keywindow[i]:Hide()
			end
		end
	end
		
	--开启计时器
	SetTimer("Anniversary_Weaving","Anniversary_Weaving_TimerProc()", 100) --0.1s	
	Anniversary_Weaving_ProgressNum:SetText("#G"..tostring(0))
	g_Anniversary_Weaving_tick = 0
	
	this:Show()
end

--更新按键
function Anniversary_Weaving_RefreshKey(nlevel, curKeyPress)
	if nlevel < 1 or nlevel > 10 then
		return
	end
	
	local keycnt = g_Anniversary_Weaving_LevelTbl[nlevel].keycount
	if curKeyPress > keycnt then
		return
	end
	
	local index = keycnt-2
	local tbl = Anniversary_Weaving_KeyList_Image[index];
	
	for i = 1, keycnt do
		if i >= 1 and i <= curKeyPress then
			tbl[i]:SetProperty("Image","set:Anniversary_Guide6 image:Key_Push") --按下
		elseif i == curKeyPress+1 then
			tbl[i]:SetProperty("Image","set:Anniversary_Guide6 image:Key_Hover") --高亮
		else
			tbl[i]:SetProperty("Image","set:Anniversary_Guide6 image:Key_Normal") --普通
		end
	end
		
end
function Anniversary_Weaving_WrongKey(nlevel, isSuccess, lastKeyPress)
	if isSuccess ~= 1 then
		local keycnt = g_Anniversary_Weaving_LevelTbl[nlevel].keycount
		local tbl_wrong = Anniversary_Weaving_KeyList_Wrong[keycnt-2];
		tbl_wrong[lastKeyPress]:Show()
		tbl_wrong[lastKeyPress]:Play(true)
	end
end
--更新拼图
function Anniversary_Weaving_RefreshAward() 
	
	local isCanGetFlag = 0
	local tips = "#{MSZJ_190325_62}"
	for i=1, 4 do
		if g_Anniversary_Award_Flag[i] == 1 then
			Anniversary_Weaving_Award_Dis[i]:Hide()
			Anniversary_Weaving_Award_Normal[i]:Show()
			isCanGetFlag = isCanGetFlag + 1
			tips = tips .. "#G" .. ScriptGlobal_Format("#{MSZJ_190325_134}", Anniversary_Weaving_ShanTips[i], "已")
		else
			Anniversary_Weaving_Award_Dis[i]:Show()
			Anniversary_Weaving_Award_Normal[i]:Hide()
			tips = tips .. "#Y" .. ScriptGlobal_Format("#{MSZJ_190325_134}", Anniversary_Weaving_ShanTips[i], "未")
		end
	end
	
	--可领取
	if isCanGetFlag == 4 and g_Anniversary_IsGetAward == 0 then
		Anniversary_Weaving_AwardButton:Enable()
	else
		Anniversary_Weaving_AwardButton:Disable()
	end
	
	Anniversary_Weaving_AwardButtonTips2:SetToolTip(tips)
end

function Anniversary_Weaving_TimerProc()
	--计时器每秒一次，更新状态
	g_Anniversary_Weaving_tick = g_Anniversary_Weaving_tick+1
	
	if math.mod(g_Anniversary_Weaving_tick, 10) == 0 then 
		local sec = math.floor(g_Anniversary_Weaving_tick/10)
		Anniversary_Weaving_ProgressNum:SetText("#G"..tostring(g_Anniversary_Time-sec))
		if sec == g_Anniversary_Time then --5s倒计时结束	
			KillTimer("Anniversary_Weaving_TimerProc()")
			g_Anniversary_Weaving_tick = 0
		
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnOverTime" )
				Set_XSCRIPT_ScriptID( 893070 )
				Set_XSCRIPT_ParamCount( 0 )
			Send_XSCRIPT()
			return
		end
	end
	--进度条
	Anniversary_Weaving_Progress:SetProgress( g_Anniversary_Weaving_tick , g_Anniversary_Time*10 );
	
end

function Anniversary_Weaving_StartButton_Click()
	g_Anniversary_Weaving_HandStart = true;
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnStartZhiBu" )
		Set_XSCRIPT_ScriptID( 893070 )
		Set_XSCRIPT_Parameter( 0, 0 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
	
end

function Anniversary_Weaving_GoOnButton_Click()
	g_Anniversary_Weaving_HandStart = true;
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnStartZhiBu" )
		Set_XSCRIPT_ScriptID( 893070 )
		Set_XSCRIPT_Parameter( 0, 2 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
end

function Anniversary_Weaving_AwardButton_Click()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetShanMianReward" )
			Set_XSCRIPT_ScriptID( 893070 )
			Set_XSCRIPT_ParamCount( 0 )
		Send_XSCRIPT()
end

function Anniversary_Weaving_Close()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnHide" )
		Set_XSCRIPT_ScriptID( 893070 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	KillTimer("Anniversary_Weaving_TimerProc()")
	KillTimer("Anniversary_Weaving_TimerThirdProc()")
	this:Hide()
end

function Anniversary_Weaving_MoveLineIndex( isSuccess, keyIndex)
	if isSuccess == 1 then 
		if not g_Anniversary_Weaving_MoveLineUI[keyIndex] then 
			PushDebugMessage("Anniversary_Weaving_MoveLineIndex:第["..(keyIndex or "nil").."]条线UI控件不存在")
			return
		end
		g_Anniversary_Weaving_HistoryLineUp[keyIndex] = true
		g_Anniversary_Weaving_MoveLineUI[keyIndex]:Tween_Play("Position", true, true)
	elseif isSuccess == 0 then 
		-- 缓动落下
		for i, v in pairs(g_Anniversary_Weaving_HistoryLineUp) do 
			if g_Anniversary_Weaving_MoveLineUI[i] then 
				g_Anniversary_Weaving_MoveLineUI[i]:Tween_Play("Position", false, true)
			end
		end
		g_Anniversary_Weaving_HistoryLineUp = {}
	else
		-- 直接落下
		for i, v in pairs(g_Anniversary_Weaving_MoveLineUI) do 
			v:Tween_Reset("Position",true)
		end
		g_Anniversary_Weaving_HistoryLineUp = {}
		return
	end

end

function Anniversary_Weaving_ResetSuoIndex()
	g_Anniversary_Weaving_SuoIndex = 0
	Anniversary_Weaving_Suo:Show()
	Anniversary_Weaving_Suo4:Hide()
	Anniversary_Weaving_Suo2:Hide()
	Anniversary_Weaving_Suo3:Hide()
end
function Anniversary_Weaving_TweenLeft2Right()
	Anniversary_Weaving_MoveLineIndex(0)
	Anniversary_Weaving_Suo2:Hide()
	Anniversary_Weaving_Suo:Show()
end
function Anniversary_Weaving_TweenRight2Left()
	Anniversary_Weaving_MoveLineIndex(0)
	Anniversary_Weaving_Suo3:Hide()
	Anniversary_Weaving_Suo4:Show()
end
function Anniversary_Weaving_MoveSuoIndex()
	g_Anniversary_Weaving_SuoIndex = g_Anniversary_Weaving_SuoIndex + 1
	if math.mod(g_Anniversary_Weaving_SuoIndex, 2) == 1 then 
		Anniversary_Weaving_Suo:Hide()
		Anniversary_Weaving_Suo3:Hide()
		Anniversary_Weaving_Suo4:Hide()
		Anniversary_Weaving_Suo2:Show()
		Anniversary_Weaving_Suo2:Tween_Play("Position", true, true)
	else
		Anniversary_Weaving_Suo:Hide()
		Anniversary_Weaving_Suo2:Hide()
		Anniversary_Weaving_Suo4:Hide()
		Anniversary_Weaving_Suo3:Show()
		Anniversary_Weaving_Suo3:Tween_Play("Position", true, true)
	end
end

function Anniversary_Weaving_HelpClick()
	PushEvent("CCSHOP_HELP", 100)
end

function Anniversary_Weaving_TimerThirdProc()
	KillTimer("Anniversary_Weaving_TimerThirdProc()")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ResetState" )
		Set_XSCRIPT_ScriptID( 893070 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	Anniversary_Weaving_Start()
end

function Anniversary_Weaving_AnimateEnd_OneSecond()
	-- 特写第三关二级确认播放特效，但不做其他显示
	if g_Anniversary_Weaving_ThirdConfirm == true then 
		g_Anniversary_Weaving_ThirdConfirm = false
		return 
	end
	-- 成功特效正常回调
	if g_Anniversary_Weaving_IsChangeLevel == true then 
		Anniversary_Weaving_KeyClient:Hide();
		Anniversary_Weaving_PassClient:Show()
		Anniversary_Weaving_PassText:SetProperty("Image", "set:Anniversary2 image:PassPic1")
		return 
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ResetState" )
		Set_XSCRIPT_ScriptID( 893070 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	Anniversary_Weaving_Start()
end
