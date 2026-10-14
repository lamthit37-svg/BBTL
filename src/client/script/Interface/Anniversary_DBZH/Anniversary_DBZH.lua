local g_Frame_UnifiedPosition

local nCount = 0
local nRandomLuckyType = 0
local nCouponNum = 0
local nTotalUseCount = 0
local LuckyStr =
{
	[0]="#{ZNDB_230215_37}",
	[1]="#{ZNDB_230215_38}",
	[2]="#{ZNDB_230215_39}",
	[3]="#{ZNDB_230215_40}",
}

local ToolTipsStr =
{
	[0]="#{ZNDB_230215_42}",
	[1]="#{ZNDB_230215_43}",
	[2]="#{ZNDB_230215_44}",
	[3]="#{ZNDB_230215_45}",
}

local Anniversary_DBZH_Reward_Tips = {}

local Anniversary_DBZH_Reward_BtnOK = {}

local Anniversary_DBZH_Reward_Btn = {}

--奖励领取所需次数
local totalAwardLimit={1,2,4,6,9,12}

local totalAwardState={0,0,0,0,0,0}

--=========
-- PreLoad()
--=========
function Anniversary_DBZH_PreLoad()

	this:RegisterEvent("UI_COMMAND")--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	this:RegisterEvent("ADJEST_UI_POS")
	
end

--=========
-- OnLoad()
--=========
function Anniversary_DBZH_OnLoad()
	g_Frame_UnifiedPosition = Anniversary_DBZH_Frame:GetProperty("UnifiedPosition")

	Anniversary_DBZH_ItemNum:SetProperty("Tooltip", "")

	-- Anniversary_DBZH_Reward_Tips[1] = Anniversary_DBZH_Reward1_tips;
	-- Anniversary_DBZH_Reward_Tips[2] = Anniversary_DBZH_Reward2_tips;
	-- Anniversary_DBZH_Reward_Tips[3] = Anniversary_DBZH_Reward3_tips;
	-- Anniversary_DBZH_Reward_Tips[4] = Anniversary_DBZH_Reward4_tips;
	-- Anniversary_DBZH_Reward_Tips[5] = Anniversary_DBZH_Reward5_tips;
	-- Anniversary_DBZH_Reward_Tips[6] = Anniversary_DBZH_Reward6_tips;

	-- Anniversary_DBZH_Reward_BtnOK[1] = Anniversary_DBZH_Reward1BtnOK;
	-- Anniversary_DBZH_Reward_BtnOK[2] = Anniversary_DBZH_Reward2BtnOK;
	-- Anniversary_DBZH_Reward_BtnOK[3] = Anniversary_DBZH_Reward3BtnOK;
	-- Anniversary_DBZH_Reward_BtnOK[4] = Anniversary_DBZH_Reward4BtnOK;
	-- Anniversary_DBZH_Reward_BtnOK[5] = Anniversary_DBZH_Reward5BtnOK;
	-- Anniversary_DBZH_Reward_BtnOK[6] = Anniversary_DBZH_Reward6BtnOK;

	-- Anniversary_DBZH_Reward_Btn[1] = Anniversary_DBZH_Reward1Btn;
	-- Anniversary_DBZH_Reward_Btn[2] = Anniversary_DBZH_Reward2Btn;
	-- Anniversary_DBZH_Reward_Btn[3] = Anniversary_DBZH_Reward3Btn;
	-- Anniversary_DBZH_Reward_Btn[4] = Anniversary_DBZH_Reward4Btn;
	-- Anniversary_DBZH_Reward_Btn[5] = Anniversary_DBZH_Reward5Btn;
	-- Anniversary_DBZH_Reward_Btn[6] = Anniversary_DBZH_Reward6Btn;

end

--=========
-- Event
--=========
function Anniversary_DBZH_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0)== 99844401 ) then

		nCount = Get_XParam_INT( 0 )
        --nRandomLuckyType = Get_XParam_INT( 1 )2024重开最后决定不要运势了
        nCouponNum = Get_XParam_INT( 1 )
		local bShow = Get_XParam_INT( 2 )--1为打开,0为仅更新数据

		-- totalAwardState[1] = Get_XParam_INT( 4 )
		-- totalAwardState[2] = Get_XParam_INT( 5 )
		-- totalAwardState[3] = Get_XParam_INT( 6 )
		-- totalAwardState[4] = Get_XParam_INT( 7 )
		-- totalAwardState[5] = Get_XParam_INT( 8 )
		-- totalAwardState[6] = Get_XParam_INT( 9 )

		--异常处理
		-- if nRandomLuckyType > 3 then
		-- 	nRandomLuckyType = 0
		-- end

        Anniversary_DBZH_SetFrame()

		if bShow == 1 then
			this:Show()
		end

	elseif event == "HIDE_ON_SCENE_TRANSED" then
        this:Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_DBZH_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_DBZH_On_ResetPos()
    end

end


function Anniversary_DBZH_SetFrame()


	--今日活跃值
	local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")
	Anniversary_DBZH_ActiveNum:SetText(ScriptGlobal_Format("#{ZNDB_230215_157}",nTodayActivePoint));

	--今日运势(2024重开最后决定不要)
	-- local text = ScriptGlobal_Format("#{ZNDB_230215_34}",LuckyStr[nRandomLuckyType]);
	-- Anniversary_DBZH_Text01:SetText(text);

	-- if nRandomLuckyType == 0 then
	-- 	Anniversary_DBZH_Text01:SetToolTip(ToolTipsStr[nRandomLuckyType]);
	-- else
	-- 	local text = ScriptGlobal_Format(ToolTipsStr[nRandomLuckyType],nCount);
	-- 	Anniversary_DBZH_Text01:SetToolTip(text);
	-- end


	--兑换券数量
	local text = ScriptGlobal_Format("#{ZNDB_230215_51}",nCouponNum);
	Anniversary_DBZH_ItemNum:SetText(text);

	-- --累计进度
	-- local text = ScriptGlobal_Format("#{ZNDB_230215_129}",nTotalUseCount);
	-- Anniversary_DBZH_RewardText:SetText(text);
	-- Anniversary_DBZH_RewardText:Show();


	if KaJi:LuaFnIsKaJiServer() ~= 1 then
		Anniversary_DBZH_ItemNum:SetToolTip("#{ZNDB_230215_153}");
	else
		--卡级服
		Anniversary_DBZH_ItemNum:SetToolTip("#{ZNDB_230215_155}");
	end

	--2024重开删除
	--未领取Tips显示
	-- for i=1,6 do
	-- 	if totalAwardState[i] == 0 and totalAwardLimit[i] <= nTotalUseCount then
	-- 		Anniversary_DBZH_Reward_Tips[i]:Show();
	-- 	else
	-- 		Anniversary_DBZH_Reward_Tips[i]:Hide();
	-- 	end
	-- end
	--领取对勾显示
	-- for i=1 ,6 do
	-- 	if totalAwardState[i] == 1 then
	-- 		Anniversary_DBZH_Reward_BtnOK[i]:Show();
	-- 		Anniversary_DBZH_Reward_Btn[i]:Disable();
	-- 	else
	-- 		Anniversary_DBZH_Reward_BtnOK[i]:Hide();
	-- 		Anniversary_DBZH_Reward_Btn[i]:Enable();
	-- 	end
	-- end
end


--=========
--重置
--=========
function Anniversary_DBZH_On_ResetPos()
	Anniversary_DBZH_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
--预览按钮点击
--=========
function Anniversary_DBZH_PreviewBtnClicked()
	PushEvent("UI_COMMAND",99844402)
end

--=========
--关闭
--=========
function  Anniversary_DBZH_ClickClose()

	-- for i=1,6 do
	-- 	totalAwardState[i] = 0
	-- 	Anniversary_DBZH_Reward_Tips[i]:Hide();
	-- 	Anniversary_DBZH_Reward_BtnOK[i]:Hide();
	-- 	Anniversary_DBZH_Reward_Btn[i]:Enable();
	-- end


	nCount = 0
	nRandomLuckyType = 0
	nCouponNum = 0
	nTotalUseCount = 0


	this:Hide()
end

--=========
--兑换召唤券按钮点击
--=========
function Anniversary_DBZH_ExchangeBtnClicked(nType)

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ExchangeCheck");
		Set_XSCRIPT_ScriptID(998444);
        Set_XSCRIPT_Parameter(0,nType);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();

end

--=========
--累计奖励兑换按钮点击
--=========
function Anniversary_DBZH_ExchangeAwardBtnClicked(nType)

	-- Clear_XSCRIPT();
	-- 	Set_XSCRIPT_Function_Name("ExchangeAwardCheck");
	-- 	Set_XSCRIPT_ScriptID(998444);
    --     Set_XSCRIPT_Parameter(0,nType);
	-- 	Set_XSCRIPT_ParamCount(1);
	-- Send_XSCRIPT();

end

--=========
--帮助
--=========
function  AnniversaryShow_Help()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("HelpUI");
		Set_XSCRIPT_ScriptID(998444);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end


