--Cardtip2
local g_CurSelInfantIndex= 0
local g_pos1;
local g_pos2;

local g_Stars;	
local g_FitTxt; 
local g_FitTitle;

local g_nUnlockingTimeNeeded = 259200;
local y_offset = 25
local g_left , g_top , g_right , g_bottom

local g_AbsoluteHeight = 0

local g_HeroType_Icon = {
	[1] = "set:Card_JD1 image:Card_JD1_Feng", 
	[2] = "set:Card_JD1 image:Card_JD1_Yu", 
	[3] = "set:Card_JD1 image:Card_JD1_Zhu", 
	[4] = "set:Card_JD1 image:Card_JD1_Yan", 
}
local g_HeroType_Icon_WM = {
	[1] = "set:WM_Card1 image:WM_Card1_Feng", 
	[2] = "set:WM_Card1 image:WM_Card1_Yu", 
	[3] = "set:WM_Card1 image:WM_Card1_Zhu", 
	[4] = "set:WM_Card1 image:WM_Card1_Yan", 
}
local g_CardType_Icon = {
	[1] = "set:Card_JD2 image:Card_JD2_Shenbing", 
	[2] = "set:Card_JD2 image:Card_JD2_Shenbing", 
	[3] = "set:Card_JD2 image:Card_JD2_Shenbing", 
	[4] = "set:Card_JD2 image:Card_JD2_Shenbing", 
	[5] = "set:Card_JD2 image:Card_JD2_Jinzhuang", 
	[6] = "set:Card_JD2 image:Card_JD2_Qinggong", 
	[7] = "set:Card_JD2 image:Card_JD2_Mingju", 
	[8] = "set:Card_JD2 image:Card_JD2_Wujue", 
	[9] = "set:Card_JD2 image:Card_JD2_Mingshi", 
}
local g_CardType_Icon_WM = {
	[1] = "set:WM_Card1 image:WM_Card1_Shenbing", 
	[2] = "set:WM_Card1 image:WM_Card1_Shenbing", 
	[3] = "set:WM_Card1 image:WM_Card1_Shenbing", 
	[4] = "set:WM_Card1 image:WM_Card1_Shenbing", 
	[5] = "set:WM_Card1 image:WM_Card1_Jinzhuang", 
	[6] = "set:WM_Card1 image:WM_Card1_Qinggong", 
	[7] = "set:WM_Card1 image:WM_Card1_Mingju", 
	[8] = "set:WM_Card1 image:WM_Card1_Wujue", 
	[9] = "set:WM_Card1 image:WM_Card1_Mingshi", 
}
local g_ValueType_String = {
	[0] = "毒攻击", 
	[1] = "玄攻击", 
	[2] = "火攻击", 
	[3] = "冰攻击", 
	[4] = "体力", 
	[5] = "身法", 
	[6] = "闪避", 
	[7] = "会心", 
	[8] = "命中", 
}
function Cardtip2_PreLoad(  )
	-- this:RegisterEvent("SHOW_SUPERTOOLTIP");

	-- this:RegisterEvent("INFANT_SHOW_CARD_TIPS");
	this:RegisterEvent("INFANT_SHOW_CARD_TIPS_2");
end

function Cardtip2_OnLoad(  )

	g_Stars={
			Cardtip2_Star1,
			Cardtip2_Star2,
			Cardtip2_Star3,
			Cardtip2_Star4,
			Cardtip2_Star5,
			Cardtip2_Star6,
			Cardtip2_Star7,
			Cardtip2_Star8,
			Cardtip2_Star9,
	};
	for i=1,9 do
		g_Stars[i]:Hide();
	end;

	g_left = 0;
	g_top  = 0;
	g_right = 0;
	g_bottom = 0;	
	
	if SystemSetup:IsClassic() == 0 then
		g_AbsoluteHeight = Cardtip2_Bk2_Green:GetProperty("AbsoluteHeight");
	end
end

function Cardtip2_OnEvent( event )

	-- if event == "SHOW_SUPERTOOLTIP" then
	-- 	local open = tonumber(arg0)
	-- 	if open == 0 then
	-- 		Cardtip2_OnHide()
	-- 	end
	-- end

	-- if event == "INFANT_SHOW_CARD_TIPS" then
	-- 	local isAsk = SuperTooltips:SendAskItemInfoMsg();
	-- 	g_pos1, g_pos2 = _Cardtip2_:PositionSelf(arg2, arg3, arg4, arg5);
	-- 	g_left = arg2;
	-- 	g_top  = arg3;
	-- 	g_right = arg4;
	-- 	g_bottom = arg5;
	-- 	Cardtip2_Update(0)
	-- end

	if event == "INFANT_SHOW_CARD_TIPS_2" then
		if arg0 == "1" then

			SuperTooltips2:SendAskItemInfoMsg();
			Cardtip2_Update(1);
			_Cardtip2_:PositionSelf(0, 0, 1, 1);
			Cardtip2_Frame:SetProperty("UnifiedPosition","{{0.500000,-144.00000},{0.500000,-235.000000}}")
			local rH = _Cardtip2_:GetProperty("AbsoluteHeight");
			_Cardtip2_:SetProperty("AbsoluteXPosition",0)
			_Cardtip2_:SetProperty("AbsoluteYPosition",0)
			Cardtip2_Frame:SetProperty("AbsoluteHeight", tostring(rH+5.0));


		-- elseif arg0 == "2" and this:IsVisible() then
  --           --- 这种情况是，按下Alt键，要显示聊天频道的装备属性对比
  --           SuperTooltips2:ShowToolTips2WithAlt( 1 )
  --           return		
		-- elseif arg0 == "3" and this:IsVisible() then
		--     --- 这种情况是：抬起Alt键，要关闭聊天频道的装备属性对比
  --           SuperTooltips2:ShowToolTips2WithAlt( 0 )
  --           return
		end
	end

end
--清空文本
function Cardtip2_ClearText( )
	Cardtip2_Frame_Title:SetText("")
	Cardtip2_Frame_Pic1:SetImage("")
	Cardtip2_Frame_Bk1_Pic1:SetImage("")
	Cardtip2_Frame_Bk1_Pic2:SetImage("")
	Cardtip2_Frame_lock:SetImage("")
	Cardtip2_Frame_lock_Text:SetText("")

	Cardtip2_Frame_Bk2_Text1:SetText("")
	--Cardtip2_Frame_Bk2_Text2:SetText("")
	-- Cardtip2_Frame_Bk2_Text3:SetText("")
	Cardtip2_Frame_Bk2_Text4:SetText("")

	Cardtip2_Frame_Bk3_List2_Text1:SetText("")
	Cardtip2_Frame_Bk3_List2_Text2:SetText("")
	Cardtip2_Frame_Bk3_List2_Text3:SetText("")

	Cardtip2_Frame_Bk3_List3_Text:SetText("")
	Cardtip2_Frame_Bk3_List4_Text:SetText("")

	for i=1,9 do
		g_Stars[i]:Hide();
	end;

end

function Cardtip2_Update( index )
	Cardtip2_ClearText()

	local title, icon, herotype, cardtype, qual, enhancelevel, basevalue, enhanceValue, herobless, story, sellprice, isActivate 
	if index == 0 then
		title, icon, herotype, cardtype, qual, enhancelevel, basevalue, enhanceValue, herobless, story, sellprice, isActivate = SuperTooltips:Infant_GetCardData()
	elseif index == 1 then
		title, icon, herotype, cardtype, qual, enhancelevel, basevalue, enhanceValue, herobless, story, sellprice, isActivate = SuperTooltips2:Infant_GetCardData()
	end
	
	local unLockingElapsedTime = SuperTooltips2:GetPUnlockElapsedTime();
	local IsProtectd = SuperTooltips2:GetDesc5();
	local bindinfo = SuperTooltips2:GetPropertys();
	local nMoney1, szMoneyDesc1 = SuperTooltips2:GetMoney1();

	local toDisplay = ""

	if title ~= nil then
		toDisplay = toDisplay.."Cardtip2_Frame_Bk"
		toDisplay = toDisplay..";Cardtip2_Frame_Title"
		toDisplay = toDisplay..";Cardtip2_Frame_del"
	end
	if herotype ~= 0 then
		toDisplay = toDisplay..";Cardtip2_Frame_Pic1"
	end

	toDisplay = toDisplay..";Cardtip2_Frame_Bk1"
	if cardtype >= 0 and cardtype <= 8 then
		toDisplay = toDisplay..";Cardtip2_Frame_Bk1_Pic1"
	end
	if icon ~= nil then
		toDisplay = toDisplay..";Cardtip2_Frame_Bk1_Pic2"
	end
	if IsProtectd == "1" and unLockingElapsedTime ~= 0 then
		toDisplay = toDisplay..";Cardtip2_Frame_lock_Text"
	end
	toDisplay = toDisplay..";Cardtip2_Frame_Bk2"
	if nMoney1 ~= nil then
		toDisplay = toDisplay..";Cardtip2_Frame_Bk2_Text3"
		toDisplay = toDisplay..";Cardtip2_Frame_Bk2_Text4"
	end

	toDisplay = toDisplay..";Cardtip2_Frame_Bk3"
	--显示组件内容
	if(toDisplay=="") then
		this:Hide();
		return;
	end;

	_Cardtip2_:SetProperty("PageElements",  toDisplay);
-----------------------------------------
-----------------------------------------
	--道具名
	Cardtip2_Frame_Title:SetText(title)
	--英雄类型 卡牌类型
	if SystemSetup:IsClassic() == 1 then 
		Cardtip2_Frame_Pic1:SetProperty("Image", g_HeroType_Icon[herotype])
		Cardtip2_Frame_Bk1_Pic1:SetProperty("Image", g_CardType_Icon[cardtype+1])
	elseif SystemSetup:IsClassic() == 0 then
		Cardtip2_Frame_Pic1:SetProperty("Image", g_HeroType_Icon_WM[herotype])
		Cardtip2_Frame_Bk1_Pic1:SetProperty("Image", g_CardType_Icon_WM[cardtype+1])
	end 

	--图标
	Cardtip2_Frame_Bk1_Pic2:SetProperty("Image", icon)
	--品质背景
	Cardtip2_UpdateCardQual( qual )

	--锁定标志及时间
	if IsProtectd == "1" and unLockingElapsedTime ~= 0 then
		Cardtip2_Frame_lock:SetProperty("Image","set:CommonFrame6 image:NewLock");
		Cardtip2_Frame_lock:Show()
		local strLeftTime = g_Cardtip2_GetUnlockingStr(unLockingElapsedTime);
		Cardtip2_Frame_lock_Text:SetText(strLeftTime)
		Cardtip2_Frame_lock_Text:Show()
	elseif IsProtectd == "1" then
		Cardtip2_Frame_lock:SetProperty("Image","set:UIIcons image:Icon_Lock");
		Cardtip2_Frame_lock:Show()
		Cardtip2_Frame_lock_Text:Hide()
	else
		Cardtip2_Frame_lock:Hide()
		Cardtip2_Frame_lock_Text:Hide()
	end
	--绑定
	if bindinfo ~= nil then
		Cardtip2_Frame_Bk2_Text1:SetText(""..bindinfo)
	end
	--贵重
	if enhancelevel >= 5 then
		Cardtip2_Frame_Bk2_Text2:Show()
	else
		Cardtip2_Frame_Bk2_Text2:Hide()
	end

	--卖店价格
	if nMoney1 ~= nil then
		Cardtip2_Frame_Bk2_Text3:Show()
		Cardtip2_Frame_Bk2_Text4:Show()
		Cardtip2_Frame_Bk2_Text4:SetProperty("MoneyNumber", tostring(nMoney1))
		--UI位置调整
		g_CardTip2_ReallocateSize( 1 )

	else
		Cardtip2_Frame_Bk2_Text3:Hide()
		Cardtip2_Frame_Bk2_Text4:Hide()
		--UI位置调整
		g_CardTip2_ReallocateSize( 0 )

	end
	--星星
	for i=1,enhancelevel do
		if enhancelevel <=5 then
			g_Stars[i]:SetProperty("Animate", "Animate_Card_NoFlashStar");
		else
			g_Stars[i]:SetProperty("Animate", "Animate_Card_LightStar");
		end
		g_Stars[i]:Show();
	end
	for i=enhancelevel+1, 9 do
		g_Stars[i]:SetProperty("Animate", "Animate_Card_DarkStar");
		g_Stars[i]:Show();
	end
	--基础属性
	Cardtip2_Frame_Bk3_List2_Text1:SetText(g_ValueType_String[cardtype])
	Cardtip2_Frame_Bk3_List2_Text2:SetText("+"..basevalue)
	--强化属性
	if enhancelevel > 0 then
		Cardtip2_Frame_Bk3_List2_Text3:SetText("#H+"..enhanceValue)
		Cardtip2_Frame_Bk3_List2_Text3:Show()
	else
		Cardtip2_Frame_Bk3_List2_Text3:Hide()
	end
	
	--英雄祝福
	--激活效果是否开启
	local infantHeroType = nil
	local infantHeroType = nil
	if isActivate == 0 then
		infantHeroType = Infant:GetHeroType(g_CurSelInfantIndex)
	elseif isActivate == 1 then
		
	elseif isActivate == 2 then
		infantHeroType = Infant:Other_GetHeroType(g_CurSelInfantIndex)
	elseif isActivate == 3 then
		infantHeroType = Infant:Target_GetHeroType(g_CurSelInfantIndex)
	end

	if infantHeroType == nil then
		Cardtip2_Frame_Bk3_List3_Text:SetText("#c777777"..herobless.."（未激活）")
	elseif infantHeroType == herotype then
		Cardtip2_Frame_Bk3_List3_Text:SetText(herobless)
	else
		Cardtip2_Frame_Bk3_List3_Text:SetText("#c777777"..herobless.."（未激活）")
	end
	--典故
	Cardtip2_Frame_Bk3_List4_Text:SetText(story)

	this:Show()
end

function Cardtip2_UpdateCardQual( index )
	Cardtip2_Green:Hide()
	Cardtip2_Blue:Hide()
	Cardtip2_Purple:Hide()
	Cardtip2_Orange:Hide()
	if index == 0 then
		Cardtip2_Green:Show()
	elseif index == 1 then
		Cardtip2_Blue:Show()
	elseif index == 2 then
		Cardtip2_Purple:Show()
	elseif index == 3 then
		Cardtip2_Orange:Show()
	end
end

function Cardtip2_OnHide()
	g_left = 0;
	g_top  = 0;
	g_right = 0;
	g_bottom = 0;
	for i=1,9 do
		g_Stars[i]:Hide();
	end;
	this:Hide();
end

function Cardtip2_OnMoved()
	--应该是装备比较界面用的，卡牌没有，先留个空的函数吧
end

function g_Cardtip2_GetUnlockingStr ( nUnlockElapsedTime )
	local nLeftTime = g_nUnlockingTimeNeeded - nUnlockElapsedTime;
	local strLeftTime = "";
		
	if( nLeftTime <= 0 ) then
		strLeftTime = "解锁成功！请重新登录或切换场景正式解锁。";
	else
		nLeftTime = math.ceil( nLeftTime/3600 );
		if( nLeftTime >= 24 ) then
			strLeftTime = ""..math.floor(nLeftTime/24).." 天";
			nLeftTime = math.mod(nLeftTime,24);
		end
		if( nLeftTime > 0 ) then 
			strLeftTime = strLeftTime.." "..nLeftTime.." 小时";					
		end
		
		strLeftTime = strLeftTime.."后正式解锁";
	end
	
	return strLeftTime;
end
function Cardtip2_Close_Clicked( )
	Cardtip2_ClearText()
	this:Hide()
end

-- 0表示没有卖店价格，1表示有卖店价格
-- 没有卖店价格时，UI需要向上移动
function g_CardTip2_ReallocateSize( index )
	if index == 0 then
		if SystemSetup:IsClassic() == 1 then
			Cardtip2_Frame_Bk2:SetProperty("UnifiedSize", "{{0.000000,273.000000},{0.000000,20.000000}")
			Cardtip2_Frame_Bk3:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,283.000000}}")
			_Cardtip2_:SetProperty("AbsoluteSize", "w:288 h:451")
		elseif SystemSetup:IsClassic() == 0 then
			Cardtip2_Frame_Bk2:SetProperty("UnifiedSize", "{{0.000000,271.000000},{0.000000,22.000000}}")
			Cardtip2_Frame_Bk3:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,287.000000}}")
			_Cardtip2_:SetProperty("AbsoluteSize", "w:298 h:460")
			Cardtip2_Frame:SetProperty("AbsoluteSize", "w:298 h:460")
			Cardtip2_Bk2_Green:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,287.000000}}")
			Cardtip2_Bk2_Blue:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,287.000000}}")
			Cardtip2_Bk2_Purple:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,287.000000}}")
			Cardtip2_Bk2_Orange:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,287.000000}}")
			local rH = _Cardtip2_:GetProperty("AbsoluteHeight");
			Cardtip2_Bk2_Green:SetProperty("AbsoluteHeight", tostring(g_AbsoluteHeight+5.0));
			Cardtip2_Bk2_Blue:SetProperty("AbsoluteHeight", tostring(g_AbsoluteHeight+5.0));
			Cardtip2_Bk2_Purple:SetProperty("AbsoluteHeight", tostring(g_AbsoluteHeight+5.0));
			Cardtip2_Bk2_Orange:SetProperty("AbsoluteHeight", tostring(g_AbsoluteHeight+5.0));
		end
	elseif index == 1 then
		if SystemSetup:IsClassic() == 1 then
			Cardtip2_Frame_Bk2:SetProperty("UnifiedSize", "{{0.000000,273.000000},{0.000000,40.000000}}")
			Cardtip2_Frame_Bk3:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,303.000000}}")
			_Cardtip2_:SetProperty("AbsoluteSize", "w:288 h:471")
		elseif SystemSetup:IsClassic() == 0 then
			Cardtip2_Frame_Bk2:SetProperty("UnifiedSize", "{{0.000000,271.000000},{0.000000,44.000000}}")
			Cardtip2_Frame_Bk3:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,307.000000}}")
			_Cardtip2_:SetProperty("AbsoluteSize", "w:298 h:480")
			Cardtip2_Frame:SetProperty("AbsoluteSize", "w:298 h:480")
			Cardtip2_Bk2_Green:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,307.000000}}")
			Cardtip2_Bk2_Blue:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,307.000000}}")
			Cardtip2_Bk2_Purple:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,307.000000}}")
			Cardtip2_Bk2_Orange:SetProperty("UnifiedPosition", "{{0.500000,-136.000000},{0.000000,307.000000}}")
		end
	end
end