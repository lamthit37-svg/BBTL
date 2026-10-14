local MAX_CHARACTER_INPUTNAME = 12; --最长玩家名字
local MAX_COUNTRY_INPUTNAME   = 12; --最长帮会名字
local g_PortId = -1;
local g_clientNpcId = -1;
local MAX_OBJ_DISTANCE = 3.0;
local g_Type = 0;
local g_ChangeGuildNameType = 0;	--修改帮会名的类型:1.合服帮会免费修改 2.使用道具"风云名录"进行修改
local g_ChangeUserNameType = 0;	--玩家改名的类型:0.手动输入名字改名 1.使用道具"风云名录"进行修改
local g_ConfraternityApplyManor_Frame_UnifiedXPosition;
local g_ConfraternityApplyManor_Frame_UnifiedYPosition;
local g_RandomNumIndex = 0
local g_RandomFirstIndex = 0
local g_RandomLastIndex = 0
local g_RandomFirstName = ""
local g_RandomLastName = ""
local g_RandomNumPool = {0, 1, 2, 3, 5, 6, 8}
local g_RandomNumLen = table.getn(g_RandomNumPool)

function ConfraternityApplyManor_PreLoad()
	this:RegisterEvent("CITY_SHOW_INPUT_NAME",true);
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("UI_COMMAND",true);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function ConfraternityApplyManor_OnLoad()
		-- 保存背包界面的默认相对位置
	g_ConfraternityApplyManor_Frame_UnifiedXPosition	= ConfraternityApplyManor_Frame:GetProperty("UnifiedXPosition");
	g_ConfraternityApplyManor_Frame_UnifiedYPosition	= ConfraternityApplyManor_Frame:GetProperty("UnifiedYPosition");
end

function ConfraternityApplyManor_OnEvent(event)
	if(event == "CITY_SHOW_INPUT_NAME" and arg0 == "open") then
		g_PortId = -1;
		g_PortId = tonumber(arg1);
		g_Type =0;
		ConfraternityApplyManor_OnShow()
		ConfraternityApplyManor_Update(0, tonumber(arg2))
	elseif(event == "CITY_SHOW_INPUT_NAME" and arg0 == "close") then
		if g_ChangeUserNameType == 1 then
			ConfraternityApplyManor_RandomName_Button:Enable()
			ConfraternityApplyManor_Release_Button:Enable()
		else
			this:Hide();
		end
	elseif ( event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		City_InputName_CareEventHandle(arg0,arg1,arg2);
	elseif event == "UI_COMMAND" and
		( tonumber(arg0) == 5423  or tonumber(arg0) == 5424 or tonumber(arg0) == 5425 or tonumber(arg0) == 54266 or tonumber(arg0) == 54267
		or tonumber(arg0) == 54268 or tonumber(arg0) == 54269 ) then
		local xx = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(xx);
		if objCared == -1 then
			PushDebugMessage("server传过来的数据有问题。");
			return;
		end
		if(tonumber(arg0) == 5423)then
			g_ChangeUserNameType = Get_XParam_INT(1)
			g_Type =1;
		elseif (tonumber(arg0) == 5424)then
			g_ChangeGuildNameType = Get_XParam_INT(1)
			g_Type =2;
		elseif (tonumber(arg0) == 54266) then
			g_Type =4;
		elseif (tonumber(arg0) == 54267) then
			g_Type =5;
		elseif (tonumber(arg0) == 54268) then
			g_Type =6;
		elseif (tonumber(arg0) == 54269) then
			g_Type =7;
		else
			g_Type = 3;
		end
		
		ConfraternityApplyManor_OnShow()
		ConfraternityApplyManor_Update(g_Type,objCared);
	elseif event == "UI_COMMAND" and tonumber(arg0) == 80800801 then 
		ConfraternityApplyManor_RandomName_Button:Enable()
		ConfraternityApplyManor_Release_Button:Enable()
		-- 检测成功 名字合法
		if Get_XParam_INT(0) == 1 then 
			this:Hide();
		else
			g_RandomNumIndex = 0
			for i=1,4 do 
				g_RandomNumIndex = g_RandomNumIndex*10+g_RandomNumPool[math.random( 1, g_RandomNumLen ) ]
			end
			local szName = g_RandomFirstName..g_RandomLastName..g_RandomNumIndex
			ConfraternityApplyManor_FeudalName2:SetText( szName );
			ConfraternityApplyManor_FeudalName:SetText( szName );
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		ConfraternityApplyManor_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ConfraternityApplyManor_Frame_On_ResetPos()
	end
end

function ConfraternityApplyManor_OnShow()
	if this:IsVisible() then return end
	GameProduceLogin:ReSetRandomNameIndex()
	ConfraternityApplyManor_RandomName_Button:Enable()
	ConfraternityApplyManor_Release_Button:Enable()
	this:Show();
end
function ConfraternityApplyManor_Update(type,clientNpcId)
		ConfraternityApplyManor_FeudalName:SetProperty("DefaultEditBox", "True");
		ConfraternityApplyManor_FeudalName:SetText("");
		g_clientNpcId = clientNpcId;
		this:CareObject(g_clientNpcId, 1, "CityInputName");
		ConfraternityApplyManor_RandomName_Frame:Hide()
		ConfraternityApplyManor_FeudalName:Show()
		if(type == 0)then
			--新建城市
			ConfraternityApplyManor_FeudalName : SetProperty("MaxTextLength","12");
			ConfraternityApplyManor_Text:SetText("#{INTERFACE_XML_56}");	--#gFF0FA0申请城市领地
			ConfraternityApplyManor_Text1:SetText("#{INTERFACE_XML_627}"); --申请一块领地需要交纳1000两黄金或使用建城令牌
			ConfraternityApplyManor_Text1:Show();
			ConfraternityApplyManor_Text2:SetText("#{INTERFACE_XML_525}"); --请输入领地名
		elseif(type == 1)then
			--人物改名
			ConfraternityApplyManor_FeudalName : SetProperty("MaxTextLength",""..MAX_CHARACTER_INPUTNAME);
			ConfraternityApplyManor_Text:SetText("#{INTERFACE_XML_GAIMING_0}");	--#gFF0FA0角色改名  注：合服
			ConfraternityApplyManor_Text1:Hide();
			ConfraternityApplyManor_Text2:SetText("#{INTERFACE_XML_GAIMING_1}"); --请输入新的角色名称：

			if g_ChangeUserNameType == 1 then
				ConfraternityApplyManor_RandomName_Frame:Show()
				ConfraternityApplyManor_FeudalName2:SetText("");
				ConfraternityApplyManor_FeudalName2:SetProperty("MaxTextLength",""..MAX_CHARACTER_INPUTNAME);
				ConfraternityApplyManor_FeudalName2:Disable()
				ConfraternityApplyManor_FeudalName:Hide()
				ConfraternityApplyManor_RandomName_BtnClicked()
			end
		elseif(type == 2)then
			--帮派改名
			ConfraternityApplyManor_FeudalName : SetProperty("MaxTextLength",""..MAX_COUNTRY_INPUTNAME);
			ConfraternityApplyManor_Text:SetText("#{INTERFACE_XML_GAIMING_2}");	--#gFF0FA0帮派改名
			ConfraternityApplyManor_Text2:SetText("#{INTERFACE_XML_GAIMING_3}"); --请输入新的帮派名称：
			if g_ChangeGuildNameType == 1 then		--合服帮会改名
				ConfraternityApplyManor_Text1:Hide();
			elseif g_ChangeGuildNameType == 2 then		--使用"风云名录"改名
				ConfraternityApplyManor_Text1:SetText("#{BHGM_140915_13}");
				ConfraternityApplyManor_Text1:Show();
			end

		elseif(type == 3)then
			--角色改名 guochenshu 2010-08-09
			ConfraternityApplyManor_FeudalName : SetProperty("MaxTextLength",""..MAX_CHARACTER_INPUTNAME);
			ConfraternityApplyManor_Text:SetText("#{GMT_20100811_3}");	--#gFF0FA0角色改名
			ConfraternityApplyManor_Text1:SetText("#{GMT_20100811_27}"); --#cfff263角色改名，需要消耗#G1个更名帖#cfff263。
			ConfraternityApplyManor_Text1:Show();
			ConfraternityApplyManor_Text2:SetText("#{GMT_20100811_18}"); --请输入新的角色名称：
		elseif ( type == 4 ) then
			ConfraternityApplyManor_FeudalName : SetProperty("MaxTextLength",""..MAX_CHARACTER_INPUTNAME);
			ConfraternityApplyManor_Text:SetText("#{CMCL_210713_53}");	-- 帮会领地改名
			ConfraternityApplyManor_Text1:SetText(""); -- 请输入新的领地名称：
			ConfraternityApplyManor_Text1:Hide();
			ConfraternityApplyManor_Text2:SetText("#{CMCL_210713_55}");
		elseif ( type == 5 ) then
			ConfraternityApplyManor_FeudalName : SetProperty("MaxTextLength",""..MAX_CHARACTER_INPUTNAME);
			ConfraternityApplyManor_Text:SetText("#{CMCL_210713_64}");	-- 同盟改名
			ConfraternityApplyManor_Text1:SetText(""); -- 请输入新的同盟名称：
			ConfraternityApplyManor_Text1:Hide();
			ConfraternityApplyManor_Text2:SetText("#{CMCL_210713_66}");
		elseif ( type == 6 ) then
			ConfraternityApplyManor_FeudalName : SetProperty("MaxTextLength",""..MAX_CHARACTER_INPUTNAME);
			ConfraternityApplyManor_Text:SetText("#{CMCL_210713_53}");	-- 帮会领地改名
			ConfraternityApplyManor_Text1:SetText(""); -- 请输入新的领地名称：
			ConfraternityApplyManor_Text1:Hide();
			ConfraternityApplyManor_Text2:SetText("#{CMCL_210713_55}");
		elseif ( type == 7 ) then
			ConfraternityApplyManor_FeudalName : SetProperty("MaxTextLength",""..MAX_CHARACTER_INPUTNAME);
			ConfraternityApplyManor_Text:SetText("#{CMCL_210713_64}");	-- 同盟改名
			ConfraternityApplyManor_Text1:SetText(""); -- 请输入新的同盟名称：
			ConfraternityApplyManor_Text1:Hide();
			ConfraternityApplyManor_Text2:SetText("#{CMCL_210713_66}");
		end
end

function City_InputName_Clear()
	g_PortId = -1;
	ConfraternityApplyManor_FeudalName:SetText("");
end

function City_InputName_Confirm()
	if(g_PortId >= 0) then
		local txt = ConfraternityApplyManor_FeudalName:GetText();
		City:DoConfirm(1, g_PortId, txt);
	end
end

function City_InputName_CareEventHandle(careId, op, distance)
		if(nil == careId or nil == op or nil == distance) then
			return;
		end
		
		if(tonumber(careId) ~= g_clientNpcId) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(op == "distance" and tonumber(distance)>MAX_OBJ_DISTANCE or op=="destroy") then
			this:Hide();
		end
end

function ConfraternityApplyManor_Release_Button_Clicked()
	if g_Type == 0 then
		City_InputName_Confirm();
	elseif g_Type == 1 then
		local txt = ConfraternityApplyManor_FeudalName:GetText();
		local ret = Target:CharRnameCheck(txt);
		if(ret>0)then
			Target:CharRnameConfirm(txt);
			if g_ChangeUserNameType == 1 then 
				ConfraternityApplyManor_RandomName_Button:Disable()
				ConfraternityApplyManor_Release_Button:Disable()
			else
				this:Hide();
			end
		else
			if g_ChangeUserNameType == 1 then 
				ConfraternityApplyManor_RandomName_BtnClicked()
			else
				City_InputName_Clear();
			end
		end
	elseif g_Type == 2 then
		local txt = ConfraternityApplyManor_FeudalName:GetText();
		local ret = Guild:CityRnameCheck(txt);
		if(ret>0)then
			Guild:CityRnameConfirm(txt,g_ChangeGuildNameType);
			this:Hide();
		else
			City_InputName_Clear();
		end
	elseif g_Type == 3 then
		-- 角色改名
		local txt = ConfraternityApplyManor_FeudalName:GetText();
		local ret = Target:CharRnameCheck(txt);
		if(ret>0)then
			Target:ChangeNameConfirm(txt,g_clientNpcId);
			this:Hide();
		else
			City_InputName_Clear();
		end
	elseif g_Type == 4 then
		local txt = ConfraternityApplyManor_FeudalName:GetText();
		local ret = Guild:CityLeagueRnameCheck(txt);
		if(ret>0)then
			Guild:RealCityRnameConfirm(txt,g_clientNpcId);
			this:Hide();
		else
			City_InputName_Clear();
		end
	elseif g_Type == 5 then
		local txt = ConfraternityApplyManor_FeudalName:GetText();
		local ret = Guild:CityLeagueRnameCheck(txt);
		if(ret>0)then
			Guild:RealLeagueRnameConfirm(txt,g_clientNpcId);
			this:Hide();
		else
			City_InputName_Clear();
		end
	elseif g_Type == 6 then
		local txt = ConfraternityApplyManor_FeudalName:GetText();
		local ret = Guild:CityLeagueRnameCheck(txt);
		if(ret>0)then
			Guild:RealCityRnameConfirmUseItem(txt,g_clientNpcId);
			this:Hide();
		else
			City_InputName_Clear();
		end
	elseif g_Type == 7 then
		local txt = ConfraternityApplyManor_FeudalName:GetText();
		local ret = Guild:CityLeagueRnameCheck(txt);
		if(ret>0)then
			Guild:RealLeagueRnameConfirmUseItem(txt,g_clientNpcId);
			this:Hide();
		else
			City_InputName_Clear();
		end
	end
end

function ConfraternityApplyManor_RandomName_BtnClicked()
	g_RandomFirstName, g_RandomFirstIndex, g_RandomLastName, g_RandomLastIndex = GameProduceLogin:RandomCharName( GetMySelfRaceId() );
	ConfraternityApplyManor_FeudalName2:SetText( g_RandomFirstName..g_RandomLastName );
	ConfraternityApplyManor_FeudalName:SetText( g_RandomFirstName..g_RandomLastName );
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function ConfraternityApplyManor_Frame_On_ResetPos()
  ConfraternityApplyManor_Frame:SetProperty("UnifiedXPosition", g_ConfraternityApplyManor_Frame_UnifiedXPosition);
	ConfraternityApplyManor_Frame:SetProperty("UnifiedYPosition", g_ConfraternityApplyManor_Frame_UnifiedYPosition);
end
