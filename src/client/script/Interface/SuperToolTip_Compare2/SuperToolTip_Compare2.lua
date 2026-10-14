local y_offset = 25
local g_WidthOfAttrWindow = 290
local g_Stars;		
local g_FitTitle;
local g_FitTxt;
local g_Fit9Txt; 
local g_Fit9Title;
--=========
--PreLoad==
--=========
function SuperTooltip_Compare2_PreLoad()
--	this:RegisterEvent("CLOSE_SP2_CMP")
	this:RegisterEvent("SHOW_SP_CMP2")
	this:RegisterEvent("CLOSE_SP_CMP2")
end
--=========
--OnLoad
--=========
function SuperTooltip_Compare2_OnLoad()
	g_Stars={
				SuperTooltip_Compare2_StaticPart_Star1,
				SuperTooltip_Compare2_StaticPart_Star2,
				SuperTooltip_Compare2_StaticPart_Star3,
				SuperTooltip_Compare2_StaticPart_Star4,
				SuperTooltip_Compare2_StaticPart_Star5,
				SuperTooltip_Compare2_StaticPart_Star6,
				SuperTooltip_Compare2_StaticPart_Star7,
				SuperTooltip_Compare2_StaticPart_Star8,
				SuperTooltip_Compare2_StaticPart_Star9,
		};
	for i=1,9 do
		g_Stars[i]:Hide();
	end

	g_FitTitle = SuperTooltip_Compare2_StaticPart_QH1;
	g_FitTxt = SuperTooltip_Compare2_StaticPart_QH2;
	g_FitTitle:Hide();
	g_FitTxt:Hide();
	g_Fit9Title = SuperTooltip_Compare2_StaticPart_QL1
	g_Fit9Txt = SuperTooltip_Compare2_StaticPart_QL2;
	g_Fit9Title:Hide();
	g_Fit9Txt:Hide();
end
--=========
--OnEvent
--=========
function SuperTooltip_Compare2_OnEvent(event)
--	if ( event == "" ) then
	if ( event == "SHOW_SP_CMP2" ) then
		SuperTooltip_Compare2_Update();

		_SuperTooltip_Compare2:PositionSelf(0, 0, 1, 1);
		_SuperTooltip_Compare2:SetProperty("AbsoluteXPosition",0)
		_SuperTooltip_Compare2:SetProperty("AbsoluteYPosition",0)
		
		local nWidthOfAttr = 0 
		if 	tonumber(arg5) == 1 then
			nWidthOfAttr = g_WidthOfAttrWindow
		end
		local posX = SuperTooltip_Compare2_Frame:SetXAttachPos(arg0 ,(arg2 + nWidthOfAttr) ,tonumber(arg3) )
		SuperTooltip_Compare2_Frame:SetProperty("AbsoluteYPosition" , tostring(arg1 - y_offset))
		
		if tonumber(arg0) < tonumber(posX) then
			posX = SuperTooltip_Compare2_Frame:GetProperty("AbsoluteXPosition");	
			SuperTooltip_Compare2_Frame:SetProperty("AbsoluteXPosition" , tostring(posX - nWidthOfAttr));
		end
		this:Show()
		return
	elseif event == "CLOSE_SP_CMP2" then
		this:Hide()
	end

end
--=========
--Update UI
--=========
function SuperTooltip_Compare2_Update()
		-- 先清空以前显示的文字
		SuperTooltip_Compare2_ClearText();
		
		local typeDesc = SuperTooltips_Cmp2:GetTypeDesc();
		local nGemHoleCounts = SuperTooltips_Cmp2:GetGemHoleCounts();
		local nMoney1, szMoneyDesc1 = SuperTooltips_Cmp2:GetMoney1();
		local nMoney2, szMoneyDesc2 = SuperTooltips_Cmp2:GetMoney2();
		local szPropertys = SuperTooltips_Cmp2:GetPropertys();
		local szAuthor = SuperTooltips_Cmp2:GetAuthorInfo();
		local szExplain = SuperTooltips_Cmp2:GetExplain();
		
		local unLockingElapsedTime	=SuperTooltips_Cmp2:GetPUnlockElapsedTime();
		local IsProtectd	=SuperTooltips_Cmp2:GetDesc5();
		local nYuanbaotrade = SuperTooltips_Cmp2:GetYuanbaoTradeFlag();
		local nGoodsProtect = SuperTooltips_Cmp2:GetGoodsProtect_Goods();
		local nEquipMasterFlag = SuperTooltips_Cmp2:GetEquipMasterFlag();
		local nEquiMasterText = SuperTooltips_Cmp2:GetEquipMasterText();
		local nZhiZunEquipText = SuperTooltips_Cmp2:GetZhiZunEquipText();
		local nZhiZunEquipType = SuperTooltips_Cmp2:GetZhiZunEquipType()
		----------------------------------------------------------------------
		--显示静态头
		local toDisplay = "";
		
		if(SuperTooltips_Cmp2:GetTitle()~="" and SuperTooltips_Cmp2:GetIconName()~="")then
			toDisplay = toDisplay .."SuperTooltip_Compare2_PageHeader";
		end
		
		--剩余解锁时间
		if( IsProtectd == "1" and unLockingElapsedTime ~= 0) then
			toDisplay = toDisplay .. ";SuperTooltip_Compare2_UnlockingTimePart";
		end
		
		
		--加上类型描述
		if( typeDesc ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip_Compare2_ShortDesc";
		end
		
		--元宝交易
		if nYuanbaotrade == 0 then
			toDisplay = toDisplay .. ";SuperTooltip_Compare2_StaticPart_Yuanbaojiaoyi"
			SuperTooltip_Compare2_StaticPart_Yuanbaojiaoyi:SetText("#{YBSC_100111_87}")
		elseif nYuanbaotrade == 2 then
			toDisplay = toDisplay .. ";SuperTooltip_Compare2_StaticPart_Yuanbaojiaoyi"
			SuperTooltip_Compare2_StaticPart_Yuanbaojiaoyi:SetText("#{YBSC_100111_88}")
        end
		
		--世外桃源交易
		-- local nKVKExchangeFlag = SuperTooltips:GeKVKExchangeFlag()
		-- if(nKVKExchangeFlag ~= nil and (nKVKExchangeFlag == 1 or nKVKExchangeFlag == 3)) then
		-- 	toDisplay = toDisplay .. ";SuperTooltip_Compare2_StaticPart_KvkSpecial";
		-- 	SuperTooltip_Compare2_StaticPart_KvkSpecial:SetText("#{KVKGZ_110620_08}");
		-- end
		local t300AuctionSubType = SuperTooltips_Cmp2:GetT300AuctionSubType()
		if t300AuctionSubType > 0 then
			toDisplay = toDisplay .. ";SuperTooltip_Compare2_StaticPart_KvkSpecial";
			SuperTooltip_Compare2_StaticPart_KvkSpecial:SetText("#{FMQZ_221110_13}");
		end
		
		--宝石部分
		if type(nGemHoleCounts) == "number" and nGemHoleCounts>0 then 
			toDisplay = toDisplay .. ";SuperTooltip_Compare2_GemPart";
		end
		--金钱1
	--	if( nMoney1 ~= nil) then 
	--		toDisplay = toDisplay .. ";SuperTooltip_MoneyPart";
	--	end

		--金钱2
	--	if(nMoney2 ~= nil) then 
	--		toDisplay = toDisplay .. ";SuperTooltip_MoneyPart_2";
	--	end
		
		--高级保护
		if nGoodsProtect == 1 or nEquipMasterFlag == 1 then
			toDisplay = toDisplay .. ";SuperTooltip_Compare2_Notice";
		end

		--属性
		if(szPropertys ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip_Compare2_Property";
		end

		--作者
		if(szAuthor ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip_Compare2_Manufacturer_Frame";
		end

		--详细解释
		toDisplay = toDisplay .. ";SuperTooltip_Compare2_Explain";

		--显示组件内容
		if(toDisplay=="") then
			this:Hide();
			return 0;
		end;
		_SuperTooltip_Compare2:SetProperty("PageElements",  toDisplay);
		
		----------------------------------------------------------------------
		--显示新的内容
		SuperTooltip_Compare2_EquipNow:SetText("#{ZBBJ_100329_3}");
		SuperTooltip_Compare2_StaticPart_Title:SetText(SuperTooltips_Cmp2:GetTitle());
		SuperTooltip_Compare2_StaticPart_Item1:SetText(SuperTooltips_Cmp2:GetDesc1());
		SuperTooltip_Compare2_StaticPart_Item2:SetText(SuperTooltips_Cmp2:GetDesc2());
		SuperTooltip_Compare2_StaticPart_Item3:SetText(SuperTooltips_Cmp2:GetDesc3());
		SuperTooltip_Compare2_StaticPart_Item4:SetText(SuperTooltips_Cmp2:GetDesc4());
		SuperTooltip_Compare2_StaticPart_Item6:SetText(SuperTooltips_Cmp2:GetDesc6());
		--SuperTooltip_StaticPart_Item5:SetText(SuperTooltips_Cmp2:GetDesc5());
		SuperTooltip_Compare2_StaticPart_Icon:SetImage(SuperTooltips_Cmp2:GetIconName());
		SuperTooltip_Compare2_ShortDesc_Text:SetText(typeDesc);
		
		SuperTooltip_Compare2_StaticPart_ZhiZun:SetText(nZhiZunEquipText)

		if nZhiZunEquipType == 1 then
			
			SuperTooltip_Compare2_StaticPart_Title:Hide()
			SuperTooltip_Compare2_StaticPart_Title1:Show()
			SuperTooltip_Compare2_StaticPart_Title2:Hide()
			SuperTooltip_Compare2_StaticPart_Title1:SetText(SuperTooltips_Cmp2:GetTitle())
			
			SuperTooltip_Compare2_StaticPart_Animate:Show()
			SuperTooltip_Compare2_StaticPart_Animate:SetProperty("Animate" , "ZhiZun_Flash_Small")
			
		elseif nZhiZunEquipType == 2 then
			
			SuperTooltip_Compare2_StaticPart_Title:Hide()
			SuperTooltip_Compare2_StaticPart_Title1:Hide()
			SuperTooltip_Compare2_StaticPart_Title2:Show()
			SuperTooltip_Compare2_StaticPart_Title2:SetText(SuperTooltips_Cmp2:GetTitle())
			
			SuperTooltip_Compare2_StaticPart_Animate:Show()
			SuperTooltip_Compare2_StaticPart_Animate:SetProperty("Animate" , "SuperEquip_Big")

		else
			
			SuperTooltip_Compare2_StaticPart_Title:Show()
			SuperTooltip_Compare2_StaticPart_Title1:Hide()
			SuperTooltip_Compare2_StaticPart_Title2:Hide()
			SuperTooltip_Compare2_StaticPart_Animate:Hide()
		end

		-- 显示雕纹
		local dwIcon = SuperTooltips_Cmp2:GetDiaowenIcon()
		if (dwIcon ~= nil and dwIcon ~= "") then
			SuperTooltip_Compare2_StaticPart_DW:Show()
			SuperTooltip_Compare2_StaticPart_DW:SetProperty("Image", dwIcon)
		end
		
		-- 显示雕纹2
		local dwIconEx = SuperTooltips_Cmp2:GetDiaowenIconEx()
		if (dwIconEx ~= nil and dwIconEx ~= "") then
			SuperTooltip_Compare2_StaticPart_DW1:Show()
			SuperTooltip_Compare2_StaticPart_DW1:SetProperty("Image", dwIconEx)
		end
		
	--	if (IsProtectd == "1" and unLockingElapsedTime ~= 0) then		
	--		local strLeftTime = SuperTooltip_Compare2_GetUnlockingStr(unLockingElapsedTime);		
	--		SuperTooltip_Compare2_UnlockingTimePart:SetText("#b#cFFFF00"..strLeftTime);
	--		SuperTooltip_Compare2_StaticPart_Icon_Protected : SetProperty("Image","set:CommonFrame6 image:NewLock");
	--	else
	--		SuperTooltip_Compare2_UnlockingTimePart:SetText("");
	--		SuperTooltip_Compare2_StaticPart_Icon_Protected : SetProperty("Image","set:UIIcons image:Icon_Lock");
	--	end
		
		if nGoodsProtect == 1 then
			SuperTooltip_Compare2_Protect_Text:SetText("#{GDWPBH_090507_4}")
		else
			SuperTooltip_Compare2_Protect_Text:SetText("")
		end
		
		if nEquipMasterFlag == 1 then
			SuperTooltip_Compare2_BaiBingJingTong_Text:SetText(nEquiMasterText);
		else
			SuperTooltip_Compare2_BaiBingJingTong_Text:SetText();
		end

		--tongxi modify 显示星星

		local qual =SuperTooltips_Cmp2:GetEquipQual();
		if(type(qual) == "number" and tonumber(qual)>0)then
			local nByQual = tonumber(qual)
			local starNum = 0;
			local nFit = 0;
			if nByQual > 100 then
				starNum = 8
				nFit = math.mod(nByQual,100)
				g_Fit9Txt:SetText("" .. nFit .. "/20")
				g_Fit9Title:Show();
				g_Fit9Txt:Show();
				g_FitTitle:Hide()
				g_FitTxt:Hide()
			elseif nByQual > 10 then
				starNum = math.floor(nByQual / 10);
				nFit = math.mod(nByQual, 10)
				if starNum < 8 then
					g_FitTxt:SetText("" .. nFit .. "/9")
					g_FitTitle:Show();
					g_FitTxt:Show();
				else
					g_FitTitle:Hide();
					g_FitTxt:Hide();
				end
				g_Fit9Title:Hide();
				g_Fit9Txt:Hide();
			else
				starNum = nByQual
				g_FitTitle:Hide()
				g_FitTxt:Hide()
				g_Fit9Title:Hide();
				g_Fit9Txt:Hide();
			end

			if(starNum<10) then
				for i=1,starNum do

					if starNum <=4 then
						g_Stars[i]:SetProperty("Animate", "Animate_StarNoFlash");
					else
						g_Stars[i]:SetProperty("Animate", "Animate_Star");
					end
					g_Stars[i]:Show();
				end;
				for i=starNum+1, 9 do
					g_Stars[i]:SetProperty("Animate", "Animate_StarDark");
					g_Stars[i]:Show();
				end
			end;
		end;
		if(IsProtectd=="1") then
			SuperTooltip_Compare2_StaticPart_Icon_Protected:Show();
		end;
		--modify end
		if( type(nGemHoleCounts) == "number" and nGemHoleCounts>0) then

			if(nGemHoleCounts > 0) then 
				SuperTooltip_Compare2_StaticPart_Gem1:Show();
			end
			
			if(nGemHoleCounts > 1) then 
				SuperTooltip_Compare2_StaticPart_Gem2:Show();
			end
			
			if(nGemHoleCounts > 2) then 
				SuperTooltip_Compare2_StaticPart_Gem3:Show();
			end
			
			if(nGemHoleCounts > 3) then 
				SuperTooltip_Compare2_StaticPart_Gem4:Show();
			end
			
			
			local gemIcon = SuperTooltips_Cmp2:GetGemIcon1();

			if(gemIcon ~= "") then
				SuperTooltip_Compare2_StaticPart_Gem1:SetProperty("ShortImage", gemIcon);
			end
			
			gemIcon = SuperTooltips_Cmp2:GetGemIcon2();

			if(gemIcon ~= "") then
				SuperTooltip_Compare2_StaticPart_Gem2:SetProperty("ShortImage", gemIcon);
			end
			
			gemIcon = SuperTooltips_Cmp2:GetGemIcon3();

			if(gemIcon ~= "") then
				SuperTooltip_Compare2_StaticPart_Gem3:SetProperty("ShortImage", gemIcon);
			end
			
			gemIcon = SuperTooltips_Cmp2:GetGemIcon4();
			

			if(gemIcon ~= "") then
				SuperTooltip_Compare2_StaticPart_Gem4:SetProperty("ShortImage", gemIcon);
			end
			
		end

	--	if(nMoney1 ~= nil)  then
	--		SuperTooltip_StaticPart_Money_Text:SetText(szMoneyDesc1);
	--		SetupMoneyPart(1,nMoney1);
	--	end		
	--	if(nMoney2 ~= nil)  then
	--		SuperTooltip_StaticPart_Money_Text_2:SetText(szMoneyDesc2);
	--		SetupMoneyPart(2,nMoney2);
	--	end
		
		if( szPropertys ~= nil) then
			SuperTooltip_Compare2_Property:SetText(szPropertys);
		end
		
		if(szAuthor ~= nil) then
			SuperTooltip_Compare2_Manufacturer:SetText(szAuthor);
		end
		
		SuperTooltip_Compare2_Explain:SetText(szExplain);

		return 1;
		
end

-------------------------------------------------------------------------------------------------------------------------------
--
-- 清空显示文本
--
function SuperTooltip_Compare2_ClearText()
		SuperTooltip_Compare2_EquipNow:SetText("");
		SuperTooltip_Compare2_StaticPart_Title:SetText("");
		SuperTooltip_Compare2_StaticPart_Item1:SetText("");
		SuperTooltip_Compare2_StaticPart_Item2:SetText("");
		SuperTooltip_Compare2_StaticPart_Item3:SetText("");
		SuperTooltip_Compare2_StaticPart_Item4:SetText("");
		SuperTooltip_Compare2_StaticPart_Item6:SetText("");
		SuperTooltip_Compare2_Protect_Text:SetText("");
		SuperTooltip_Compare2_StaticPart_DW:SetImage("")
		SuperTooltip_Compare2_StaticPart_DW:Hide()
		SuperTooltip_Compare2_StaticPart_DW1:SetImage("")
		SuperTooltip_Compare2_StaticPart_DW1:Hide()
		g_FitTitle:Hide();
		g_FitTxt:Hide();
		local starNum=9
		for i=1,starNum do
			g_Stars[i]:Hide();
		end;
		SuperTooltip_Compare2_StaticPart_Gem1:SetImage("");
		SuperTooltip_Compare2_StaticPart_Gem2:SetImage("");
		SuperTooltip_Compare2_StaticPart_Gem3:SetImage("");
		SuperTooltip_Compare2_StaticPart_Gem4:SetImage("");
		SuperTooltip_Compare2_StaticPart_Gem1:Hide();
		SuperTooltip_Compare2_StaticPart_Gem2:Hide()
		SuperTooltip_Compare2_StaticPart_Gem3:Hide()
		SuperTooltip_Compare2_StaticPart_Gem4:Hide()
		SuperTooltip_Compare2_Explain:SetText("");
		SuperTooltip_Compare2_Property:SetText("");
		SuperTooltip_Compare2_Manufacturer:SetText("");
		SuperTooltip_Compare2_StaticPart_Icon_Protected:Hide();
		SuperTooltip_Compare2_BaiBingJingTong_Text:SetText("");
end

