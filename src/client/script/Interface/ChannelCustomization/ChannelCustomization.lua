local CUSTOM_BUTTONS = {};
local CUSTOM_BUTTONS_NUM = 25;
local g_Action = "";

--系统、私聊、队伍、帮会、同盟
local g_ipRegionConfig = {4,5,2,7,13};
local g_paidWorldConfig = {2,4,5,7,13};

function isInIpRegionConfig(idx)
	for i = 1,5 do
		if (tonumber(g_ipRegionConfig[i]) == tonumber(idx)) then
			return 1;
		end
	end
	return 0;
end

function isPaidWorldConfig(idx)
	for i = 1,5 do
		if (tonumber(g_paidWorldConfig[i]) == tonumber(idx)) then
			return 1;
		end
	end
	return 0;
end

function ChannelCustomization_PreLoad()
	this:RegisterEvent("CHAT_TAB_CREATE", true);
	this:RegisterEvent("CHAT_TAB_CONFIG", true);
	this:RegisterEvent("CHAT_TAB_CHANGED", false);
	this:RegisterEvent("CHAT_ADJUST_MOVE_CTL", false);
end
	
function ChannelCustomization_OnLoad()
	CUSTOM_BUTTONS[3] = ChannelCustomization_WorldInfo;--世界频道
	CUSTOM_BUTTONS[1] = ChannelCustomization_VicinityInfo;--附近频道
	CUSTOM_BUTTONS[4] = ChannelCustomization_PersonalInfo;--个人频道
	CUSTOM_BUTTONS[8] = ChannelCustomization_MenpaiInfo;--门派
	CUSTOM_BUTTONS[7] = ChannelCustomization_CorporateInfo;--团队
	CUSTOM_BUTTONS[2] = ChannelCustomization_TeamInfo;--队伍
	CUSTOM_BUTTONS[9] = ChannelCustomization_SelfInfo;--私聊
	CUSTOM_BUTTONS[5] = ChannelCustomization_SystemInfo;			--系统频道
	CUSTOM_BUTTONS[6] = ChannelCustomization_SelfInfo;				--自建频道（现在没有功能）
	CUSTOM_BUTTONS[10] = ChannelCustomization_HelpInfo;				--帮助频道
	CUSTOM_BUTTONS[11] = nil;
	CUSTOM_BUTTONS[12] = ChannelCustomization_City;				--同城聊天
	CUSTOM_BUTTONS[13] = ChannelCustomization_GuildLeagueInfo;				--同盟聊天
	CUSTOM_BUTTONS[14] = ChannelCustomization_UnionInfo			--团队频道
	CUSTOM_BUTTONS[15] = nil						--小队频道
	CUSTOM_BUTTONS[16] = nil						--千里传音
	CUSTOM_BUTTONS[17] = ChannelCustomization_ShiWaiInfo		--世外频道
	CUSTOM_BUTTONS[18] = nil			--势力频道
	CUSTOM_BUTTONS[19] = nil			--征召频道
	CUSTOM_BUTTONS[20] = nil			--传音入密
	CUSTOM_BUTTONS[21] = nil			--T服信息
	CUSTOM_BUTTONS[22] = ChannelCustomization_Lianzhan			--连斩频道
	CUSTOM_BUTTONS[23] = nil
	CUSTOM_BUTTONS[24] = ChannelCustomization_WarzoneInfo
	CUSTOM_BUTTONS[25] = ChannelCustomization_PaidWorld
    --- 2014Q1大世界改造，世族功能去除。-- By Godwit. 2014.02.08
	--- CUSTOM_BUTTONS[18] = ChannelCustomization_ShiLi     		--势力频道

	--填充城市信息
	ChannelCustomization_ProvinceCity : ResetList();
	local num = DataPool : GetProvincesNum();
	if (num > 0) then
		for i = 0, num-1 do
			local _id,_name =DataPool : EnumProvinces(i);
			ChannelCustomization_Province:ComboBoxAddItem(_name,_id);
		end
	end
end

function ChannelCustomization_ComboListProvinceChanged(cIdx)
	local szName, nIndex = ChannelCustomization_Province:GetCurrentSelect();
	if(nIndex and nIndex ~= -1 ) then
		ChannelCustomization_ProvinceCity : ResetList();
		local num = DataPool : GetCityNumFromOneProvinceId(nIndex);
		if (num > 0) then
			for i = 0, num-1 do
				local _id,_name = DataPool : NumCityFromOneProvince(nIndex,i)
				ChannelCustomization_ProvinceCity:ComboBoxAddItem(_name,_id);
			end
		end
		if(tonumber(cIdx) and tonumber(cIdx) > 0 and tonumber(cIdx) < num ) then	
			ChannelCustomization_ProvinceCity:SetCurrentSelect(tonumber(cIdx));
		else
			ChannelCustomization_ProvinceCity:SetCurrentSelect(0);
		end
	end
end

function ChannelCustomization_OnEvent( event )
	if (event == "CHAT_TAB_CREATE") then
		ChatTabAction("create", "11111111110011101000010101", "", arg0);
	elseif (event == "CHAT_TAB_CONFIG") then
		ChatTabAction("config", arg1, arg0, arg2);
	elseif (event == "CHAT_ADJUST_MOVE_CTL" and this:IsVisible()) then
		Chat_ChannelTab_AdjustMoveCtl();
	elseif (event == "CHAT_TAB_CHANGED" and this:IsVisible()) then
		ChannelCustomization_Close_Clicked();
	end
end


function ChatTabAction( act , strCfg , strName , pos)
	if(g_Action == act) then
		if(this:IsVisible() or this:ClickHide()) then
			ChannelCustomization_Close_Clicked();
			return;
		end
	end
	CC_BUTTON_Enable(12);
	CC_BUTTON_Enable(25)
	g_Action = act;
	--AxTrace(0, 0, "ChannelCustomization " .. act .. " " .. strCfg .. " " .. strName);	
	-- 设置窗体名称
	if ( g_Action == "create" ) then
		ChannelCustomization_PageHeader_Text:SetText("#gFF0FA0自定义");
		ChannelCustomization_Text1:SetText("自定义名字");
		ChannelCustomization_Cancel:SetText("创建");
		ChannelCustomization_Destory:SetText("取消");
		ChannelCustomization_EditName:Show();
		ChannelCustomization_EditName:SetProperty("DefaultEditBox", "True");
		ChannelCustomization_Accept:Hide();
		ChannelCustomization_TxtName:Hide();
		ChannelCustomization_EditName:SetText(strName);
	elseif ( g_Action == "config" ) then
		ChannelCustomization_PageHeader_Text:SetText("#gFF0FA0频道配置");
		ChannelCustomization_Text1:SetText("频道名称");
		ChannelCustomization_Accept:SetText("确定");
		ChannelCustomization_Cancel:SetText("取消");
		ChannelCustomization_Destory:SetText("删除");
		ChannelCustomization_EditName:Hide();
		ChannelCustomization_TxtName:Show();
		ChannelCustomization_Accept:Show();
		ChannelCustomization_TxtName:SetText(strName);
		
		if(strName == "自己") then
			ChannelCustomization_Destory:Hide();
		else
			ChannelCustomization_Destory:Show();
		end
	end
	Chat_ChannelTab_ChangePosition(pos);
	
	local ipRegion = Player:GetData("IPREGION");
	local pIdx = -1;
	local cIdx =  -1;
	local yes = 0 ;
	if(ipRegion and ipRegion > 0) then
		pIdx,cIdx = DataPool:getUINumbersFromIpRegion(ipRegion);
		local count =  DataPool : GetProvincesNum();
		count = tonumber(count);
		if(pIdx < count and count) then
			local num = DataPool : GetCityNumFromOneProvinceId(pIdx);
			num = tonumber(num);
			if(cIdx < num and num) then
				--到这里，确定是有效的ipRegion
				yes = 1;
			end
		end
	end
	
	--同城频道做特殊处理,如果同城频道选中
	if(string.byte(strCfg,12) == 49 ) then
		for i=1, CUSTOM_BUTTONS_NUM do
			if i==12 then
				continue
			end
			
			if(isInIpRegionConfig(i) == 0) then
				CC_BUTTON_SetCheck(i,0);
				CC_BUTTON_Disable(i);
			else
				if(string.byte(strCfg, i) == 49) then
					CC_BUTTON_SetCheck(i,1);
				else
					CC_BUTTON_SetCheck(i,0);
				end
				CC_BUTTON_Enable(i);
			end
		end
		CC_BUTTON_SetCheck(12,1);
		ChannelCustomization_ProvinceCity : Enable();
		ChannelCustomization_Province	  : Enable();
		if(tonumber(yes) == 1)then
			ChannelCustomization_Province	  : SetCurrentSelect(pIdx);
			ChannelCustomization_ComboListProvinceChanged(cIdx);
		else
			ChannelCustomization_Province : SetCurrentSelect(0);
			ChannelCustomization_ComboListProvinceChanged(-1);
		end
	elseif (string.byte(strCfg,25) == 49 ) then
		for i=1, CUSTOM_BUTTONS_NUM do
			if i==25 then
				continue
			end
			
			if(isPaidWorldConfig(i) == 0) then
				CC_BUTTON_SetCheck(i,0);
				CC_BUTTON_Disable(i);
			else
				if(string.byte(strCfg, i) == 49) then
					CC_BUTTON_SetCheck(i,1);
				else
					CC_BUTTON_SetCheck(i,0);
				end
				CC_BUTTON_Enable(i);
			end
		end
		CC_BUTTON_SetCheck(25,1);
		ChannelCustomization_Province : Disable()
		ChannelCustomization_ProvinceCity : Disable();
	else
		for i=1, CUSTOM_BUTTONS_NUM do
			if i==12 then
				continue
			end
			
			if(string.byte(strCfg, i) == 48) then -- 0
				CC_BUTTON_SetCheck(i,0);
			elseif(string.byte(strCfg, i) == 49) then -- 1
				CC_BUTTON_SetCheck(i,1);
			end
			CC_BUTTON_Enable(i);
		end
		CC_BUTTON_SetCheck(12,0);
		if(tonumber(yes) == 1)then
			ChannelCustomization_Province	  : SetCurrentSelect(pIdx);
			ChannelCustomization_ComboListProvinceChanged(cIdx);
		else
			ChannelCustomization_Province : SetCurrentSelect(0);
			ChannelCustomization_ComboListProvinceChanged(-1);
		end
		ChannelCustomization_ProvinceCity : Disable();
		ChannelCustomization_Province	  : Disable();

	end
	local curTab = Talk : GetCurTab();
	if(g_Action == "config" and curTab == 3) then
		CC_BUTTON_Disable(12);
	end
	if(g_Action == "config" and curTab == 5) then
		CC_BUTTON_Disable(25);
	end
	-- 配置checkbox
--	local i;
--	for i=1, CUSTOM_BUTTONS_NUM do
--		if(string.byte(strCfg, i) == 48) then -- 0
--			CC_BUTTON_SetCheck(i,0);
--		elseif(string.byte(strCfg, i) == 49) then -- 1
--			CC_BUTTON_SetCheck(i,1);
--		end
--	end
	
--	if("False" == CC_BUTTON_GetSelected(12))then
--		ChannelCustomization_ProvinceCity : Disable();
--		ChannelCustomization_Province	  : Disable();
--	else
--		ChannelCustomization_ProvinceCity : Enable();
--		ChannelCustomization_Province	  : Enable();
--	end
	-- 显示窗体
	this:Show();
end

function CC_BUTTON_SetCheck(idx,val)
	if not idx then return; end
	if not val then return; end
	
	if CUSTOM_BUTTONS[idx] then
		CUSTOM_BUTTONS[idx]:SetCheck(val);
	end
end

function CC_BUTTON_GetSelected(idx)
	if not idx then return "False"; end
	if CUSTOM_BUTTONS[idx] then
		return CUSTOM_BUTTONS[idx]:GetProperty("Selected");
	end
	return "False";
end

function CC_BUTTON_Disable(idx)
	if not idx then return "False"; end
	if CUSTOM_BUTTONS[idx] then
		CUSTOM_BUTTONS[idx]:Disable();
	end
end

function CC_BUTTON_Enable(idx)
	if not idx then return "False"; end
	if CUSTOM_BUTTONS[idx] then
		CUSTOM_BUTTONS[idx]:Enable();
	end
end

function ChannelCustomization_Accept_Clicked()
	local strName = "";
	local strConfig = "";

	-- config
	local i;
	for i=1, CUSTOM_BUTTONS_NUM do
		if("False" == CC_BUTTON_GetSelected(i)) then
			if i == 15 then
				--小队频道和团队频道公用一个check按钮
				if "True" == CC_BUTTON_GetSelected(14) then
					strConfig = strConfig .. "1"
				else
					strConfig = strConfig .. "0";
				end
			else
				strConfig = strConfig .. "0";
			end
		elseif("True" == CC_BUTTON_GetSelected(i)) then
			strConfig = strConfig .. "1";
		end
	end
	
	--AxTrace(0, 0, "ChannelCustomization Config: " .. strConfig .. " " .. g_Action);
	-- call Talk Interface
	if(g_Action == "config") then
		strName = ChannelCustomization_TxtName:GetText();
		if("True" == CC_BUTTON_GetSelected(12)) then
			local _name,_id = ChannelCustomization_ProvinceCity:GetCurrentSelect();
			if(_id == nil or tonumber(_id) == nil)then
				_id = -1;
			end
			if(_id < 0)then
				PushDebugMessage("请您选好一个城市再确定使用同城频道！")
				this : Hide()
				return;
			end
			Player:SetIPRegion(tonumber(_id));
		end
		Talk:ConfigTabFinish(strName, strConfig, "sucess");
	end
	
	--AxTrace(0, 0, "ChannelCustomization Name: " .. strName .. " " .. g_Action);
	this:Hide();
end

function ChannelCustomization_Cancel_Clicked()
	local strName = "";
	local strConfig = "";
	
	-- config
	local i;
	for i=1, CUSTOM_BUTTONS_NUM do
		if("False" == CC_BUTTON_GetSelected(i)) then
			if i == 15 then
				--小队频道和团队频道公用一个check按钮
				if "True" == CC_BUTTON_GetSelected(14) then
					strConfig = strConfig .. "1"
				else
					strConfig = strConfig .. "0";
				end
			else
				strConfig = strConfig .. "0";
			end
		elseif("True" == CC_BUTTON_GetSelected(i)) then
			strConfig = strConfig .. "1";
		end
	end
	
	if(g_Action == "create") then
		strName = ChannelCustomization_EditName:GetText();
		if("True" == CC_BUTTON_GetSelected(12)) then
			local _name,_id = ChannelCustomization_ProvinceCity:GetCurrentSelect();
			if(_id == nil or tonumber(_id) == nil)then
				_id = -1;
			end
			if(_id < 0)then
				PushDebugMessage("请您选好一个城市再确定使用同城频道！")
				this : Hide()
				return;
			end
			Player:SetIPRegion(tonumber(_id));
		end
		Talk:CreateTabFinish(strName, strConfig, "sucess");

	elseif(g_Action == "config") then
		strName = ChannelCustomization_TxtName:GetText();
		Talk:ConfigTabFinish(strName, strConfig, "cancel");
	end
	
	this:Hide();
end

function ChannelCustomization_Destory_Clicked()
	local strName = "";
	local strConfig = "";
	
	if(g_Action == "create") then
		strName = ChannelCustomization_EditName:GetText();
		Talk:CreateTabFinish(strName, strConfig, "cancel");
		this:Hide();
	elseif(g_Action == "config") then
		Talk:ConfigTabFinish(strName,strConfig,"delete");
		this:Hide();
	end
end

function Chat_ChannelTab_Frame_OnHiden()
	ChannelCustomization_EditName:SetProperty("DefaultEditBox", "False");
end

function Chat_ChannelTab_AdjustMoveCtl()
	ChannelCustomization_Close_Clicked();
end

function Chat_ChannelTab_ChangePosition(pos)
	ChannelCustomization_Frame:SetProperty("UnifiedXPosition", "{0.0,"..pos.."}");
end

function ChannelCustomization_Close_Clicked()
	if(g_Action == "create") then
		ChannelCustomization_Destory_Clicked();
	elseif(g_Action == "config") then
		ChannelCustomization_Cancel_Clicked();
	end
end

function ChannelCustomization_ComboListProvinceCityChanged()
end

function ChannelCustomization_City_Click()
	if("False" == ChannelCustomization_City:GetProperty("Selected"))then
		ChannelCustomization_Province : Disable()
		ChannelCustomization_ProvinceCity : Disable();
		--
		for i=1, CUSTOM_BUTTONS_NUM do
			if i==12 then
				continue
			end
			CC_BUTTON_Enable(i);
		end

	else

		ChannelCustomization_Province : Enable()
		ChannelCustomization_ProvinceCity : Enable();
		--
		for i=1, CUSTOM_BUTTONS_NUM do
			if i==12 then
				continue
			end
			
			if(isInIpRegionConfig(i) == 0) then
				CC_BUTTON_SetCheck(i,0);
				CC_BUTTON_Disable(i);
			else
				CC_BUTTON_Enable(i);
			end
		end

		--默认选中“火星”
		--ChannelCustomization_Province : SetCurrentSelect(0);
	end
end

function ChannelCustomization_PaidWorld_Click()
	if("False" == ChannelCustomization_PaidWorld:GetProperty("Selected"))then
		--ChannelCustomization_PaidWorld : Disable()

		for i=1, CUSTOM_BUTTONS_NUM do
			CC_BUTTON_Enable(i);
		end

	else

		ChannelCustomization_PaidWorld : Enable()
		for i=1, CUSTOM_BUTTONS_NUM do
			if i==25 then
				continue
			end
			
			if(isPaidWorldConfig(i) == 0) then
				CC_BUTTON_SetCheck(i,0);
				CC_BUTTON_Disable(i);
			else
				CC_BUTTON_Enable(i);
			end
		end
	end
end
