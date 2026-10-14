--******************************************
--周常肉鸽爬塔副本	休闲界面
--create by  limengyue 
--2023-12-06
--******************************************

local RouGe_Finish_Frame_UnifiedPosition;
local RouGe_Finish_Time = 1 --计时器

local RouGe_Finish_SkillList = {}	--技能列表
local RouGe_Finish_SkillBkList = {}	--空技能列表

--服务器不传字典 直接传编号提示
local g_RouGe_Finish_TipsList = 
{
	[1] = {tips="#{RGPT_231130_545}"},--初次进入副本
	[2] = {tips="#{RGPT_231130_546}"},--第一重挑战后
	[3] = {tips="#{RGPT_231130_547}"},--第二重挑战后
	[4] = {tips="#{RGPT_231130_548}"},--第三重挑战后
	[5] = {tips="#{RGPT_231130_549}"},--第四重挑战后
	[6] = {tips="#{RGPT_231130_550}"},--第五重挑战后
	[7] = {tips="#{RGPT_231130_551}"},--第六重挑战后
	[8] = {tips="#{RGPT_231130_609}"},--通关后
	[9] = {tips="#{RGPT_231130_552}"},--boss1失败
	[10] = {tips="#{RGPT_231130_606}"},--boss2失败
	[11] = {tips="#{RGPT_231130_607}"},--boss3失败
	[12] = {tips="#{RGPT_231130_608}"},--boss4失败
}

--=========================================================
--PreLoad
--=========================================================
function RouGe_Finish_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("ON_SCENE_TRANS",false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--=========================================================
--OnLoad
--=========================================================
function RouGe_Finish_OnLoad()
	RouGe_Finish_Frame_UnifiedPosition = RouGe_Finish_Frame:GetProperty("UnifiedPosition");
	--控件
	RouGe_Finish_SkillList[1] = RouGe_Finish_Action1
	RouGe_Finish_SkillList[2] = RouGe_Finish_Action2
	RouGe_Finish_SkillList[3] = RouGe_Finish_Action3
	--空技能列表
	RouGe_Finish_SkillBkList[1] = RouGe_Finish_Action1_Bak
	RouGe_Finish_SkillBkList[2] = RouGe_Finish_Action2_Bak
	RouGe_Finish_SkillBkList[3] = RouGe_Finish_Action3_Bak
end

--=========================================================
--恢复界面的默认相对位置
--=========================================================
function RouGe_Finish_On_ResetPos()
	
	RouGe_Finish_Frame:SetProperty("UnifiedPosition", RouGe_Finish_Frame_UnifiedPosition);

end

--=========================================================
--OnEvent
--=========================================================
function RouGe_Finish_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99894704 ) then
		--打开界面
		if(IsWindowShow("RouGe_Finish")) then
			CloseWindow("RouGe_Finish", true)
		end
		--if Get_XParam_INT(0) >= 0 then --第几个boss
			RouGe_Finish_Open(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4),Get_XParam_INT(5))
		--end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99894708 ) then
		if( this:IsVisible() ) then
			this:Hide()
		end
	end
	if (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		RouGe_Finish_On_ResetPos();
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then	
		RouGe_Finish_On_ResetPos();
    elseif (event == "ON_SCENE_TRANS" ) then
       RouGe_Finish_Close()
    end	
end

--=========================================================
--打开界面
--=========================================================
function RouGe_Finish_Open(nSkill1,nSkill2,nSkill3,nTime,nPoint,nTipsIdx)
	--nSkill1 = 5206
	--nSkill2 = 5218
	--nSkill3 = 5219
	--PushDebugMessage(" nSkill1="..nSkill1.." nSkill2="..nSkill2.." nSkill3"..nSkill3)
	--默认没技能
	for index=1,table.getn(RouGe_Finish_SkillList)  do
		--空技能
		RouGe_Finish_SkillList[index]:SetActionItem(-1);
		--悬浮tips
		RouGe_Finish_SkillList[index]:SetToolTip("#{RGPT_231130_167}");
		RouGe_Finish_SkillBkList[index]:Show();
	end
	--技能列表
	local nSkillList = {nSkill1,nSkill2,nSkill3}
	local nShowIdx = 1
	for index=1,table.getn(nSkillList)  do
		if nSkillList[index] > 0 then
			local theAction = CreateRougeSkillAction(nSkillList[index]);
			--PushDebugMessage("theAction:GetID()="..theAction:GetID())
			if theAction:GetID() ~= 0 then
				theAction:SetLockStatus(1)
				RouGe_Finish_SkillBkList[nShowIdx]:Hide();
				RouGe_Finish_SkillList[nShowIdx]:SetActionItem(theAction:GetID());
				nShowIdx = nShowIdx + 1
			end
		end
	end
	--当前累计积分
	RouGe_Finish_Client2_Num1:SetText(ScriptGlobal_Format("#{RGPT_231130_165}",tostring(nPoint)));
	--当前累计时间
	RouGe_Finish_Client2_Time:SetToolTip("#{RGPT_231130_544}");
	local  skyTimeString = ""
	local skyMinute = math.floor(nTime / 60)
	local skySecond = math.mod(nTime, 60)
	if skyMinute < 10 then
		skyTimeString = skyTimeString .. "0"
	end
	skyTimeString = skyTimeString .. tostring(skyMinute) .. ":"
	if skySecond < 10 then
		skyTimeString = skyTimeString .. "0"
	end
	skyTimeString = skyTimeString .. tostring(skySecond)
	RouGe_Finish_Client2_Time:SetText(ScriptGlobal_Format("#{RGPT_231130_166}",tostring(skyTimeString)));

	if g_RouGe_Finish_TipsList[nTipsIdx] then
		RouGe_Finish_Client1BK_Text2:SetText(g_RouGe_Finish_TipsList[nTipsIdx].tips)
	end
	
	this:Show()
end
--=========================================================
--关闭界面
--=========================================================
function RouGe_Finish_Close()
	this:Hide()
end


--=========================================================
--使用技能
--=========================================================
function RouGe_Finish_UseSkill(nIndex)
	local  tmpItem = RouGe_Finish_SkillList[nIndex]:GetActionItem();
	--PushDebugMessage("nIndex="..nIndex.." tmpItem="..tmpItem)
	RouGe_Finish_SkillList[nIndex]:DoAction();
end
