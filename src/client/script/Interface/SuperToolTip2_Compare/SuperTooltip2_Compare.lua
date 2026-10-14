local y_offset = 25
local g_Stars;
local g_FitTxt;
local g_FitTitle;
local g_Fit9Txt; 
local g_Fit9Title;
--=========
--PreLoad==
--=========
function SuperTooltip2_Compare_PreLoad()
--	this:RegisterEvent("CLOSE_SP2_CMP")
	this:RegisterEvent("SHOW_SP2_CMP1")
	this:RegisterEvent("MOVE_SP2_CMP1")
	this:RegisterEvent("CLOSE_SP2_CMP1")
end
--=========
--OnLoad
--=========
function SuperTooltip2_Compare_OnLoad()
	g_Stars={
				SuperTooltip2_Compare_StaticPart_Star1,
				SuperTooltip2_Compare_StaticPart_Star2,
				SuperTooltip2_Compare_StaticPart_Star3,
				SuperTooltip2_Compare_StaticPart_Star4,
				SuperTooltip2_Compare_StaticPart_Star5,
				SuperTooltip2_Compare_StaticPart_Star6,
				SuperTooltip2_Compare_StaticPart_Star7,
				SuperTooltip2_Compare_StaticPart_Star8,
				SuperTooltip2_Compare_StaticPart_Star9,
		};
	for i=1,9 do
		g_Stars[i]:Hide();
	end
	
	g_FitTxt = SuperTooltip2_Compare_StaticPart_QH2;
	g_FitTitle = SuperTooltip2_Compare_StaticPart_QH1;
	g_FitTxt:Hide();
	g_FitTitle:Hide();
	g_Fit9Title = SuperTooltip2_Compare_StaticPart_QL1
	g_Fit9Txt = SuperTooltip2_Compare_StaticPart_QL2;
	g_Fit9Title:Hide();
	g_Fit9Txt:Hide();
end
--=========
--OnEvent
--=========
function SuperTooltip2_Compare_OnEvent(event)
--	if ( event == "" ) then
	if ( event == "SHOW_SP2_CMP1" ) then
		SuperTooltip2_Compare_Update();
		_SuperTooltip2_Compare:PositionSelf(0, 0, 1, 1);
		local rH = _SuperTooltip2_Compare:GetProperty("AbsoluteHeight");
		_SuperTooltip2_Compare:SetProperty("AbsoluteXPosition",0)
		_SuperTooltip2_Compare:SetProperty("AbsoluteYPosition",0)
		SuperTooltip2_Compare_Frame:SetProperty("AbsoluteHeight", tostring(rH+5.0));
		
		SuperTooltip2_Compare_Frame:SetProperty("AbsoluteXPosition" , tostring(arg0 + arg2) )
		SuperTooltip2_Compare_Frame:SetProperty("AbsoluteYPosition" , tostring(arg1 - y_offset))
		
		local nWidth = SuperTooltip2_Compare_Frame:GetProperty("AbsoluteWidth")
		SuperTooltips2:ShowCmp2WindowSub( tonumber(arg0) ,tonumber(arg1) ,tonumber(nWidth + arg2) ,tonumber(arg3) )
		
		this:Show()
		return
	elseif event == "MOVE_SP2_CMP1" then
		if this:IsVisible() then
			local posX = tonumber(arg0)
			local posY = tonumber(arg1)
			local nWidth = tonumber(arg2)
			SuperTooltip2_Compare_Frame:SetProperty("AbsoluteXPosition" , tostring(posX + nWidth) )
			SuperTooltip2_Compare_Frame:SetProperty("AbsoluteYPosition" , tostring(posY - y_offset))
			SuperTooltips2:Cmp2WindowSubMove( posX ,posY )
		end
	elseif event == "CLOSE_SP2_CMP1" then
		this:Hide()
	end

end
--=========
--Update UI
--=========
function SuperTooltip2_Compare_Update()
		-- 先清空以前显示的文字
		SuperTooltip2_Compare_ClearText();
		
		local typeDesc = SuperTooltips2_Cmp1:GetTypeDesc();
		local nGemHoleCounts = SuperTooltips2_Cmp1:GetGemHoleCounts();
		local nMoney1, szMoneyDesc1 = SuperTooltips2_Cmp1:GetMoney1();
		local nMoney2, szMoneyDesc2 = SuperTooltips2_Cmp1:GetMoney2();
		local szPropertys = SuperTooltips2_Cmp1:GetPropertys();
		local szAuthor = SuperTooltips2_Cmp1:GetAuthorInfo();
		local szExplain = SuperTooltips2_Cmp1:GetExplain();
		
		local unLockingElapsedTime	=SuperTooltips2_Cmp1:GetPUnlockElapsedTime();
		local IsProtectd	=SuperTooltips2_Cmp1:GetDesc5();
		local nYuanbaotrade = SuperTooltips2_Cmp1:GetYuanbaoTradeFlag();
		local nGoodsProtect = SuperTooltips2_Cmp1:GetGoodsProtect_Goods();
		local nEquipMasterFlag = SuperTooltips2_Cmp1:GetEquipMasterFlag();
		local nEquiMasterText = SuperTooltips2_Cmp1:GetEquipMasterText();
		
		local nZhiZunEquipText = SuperTooltips2_Cmp1:GetZhiZunEquipText();
		local nZhiZunEquipType = SuperTooltips2_Cmp1:GetZhiZunEquipType()
		----------------------------------------------------------------------
		--显示静态头
		local toDisplay = "";
		
		if(SuperTooltips2_Cmp1:GetTitle()~="" and SuperTooltips2_Cmp1:GetIconName()~="")then
			toDisplay = toDisplay .."SuperTooltip2_Compare_PageHeader";
		end
		
		--剩余解锁时间
		if( IsProtectd == "1" and unLockingElapsedTime ~= 0) then
			toDisplay = toDisplay .. ";SuperTooltip2_Compare_UnlockingTimePart";
		end
		
		
		--加上类型描述
		if( typeDesc ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip2_Compare_ShortDesc";
		end
		
		--元宝交易
		if nYuanbaotrade == 0 then
			toDisplay = toDisplay .. ";SuperTooltip2_Compare_StaticPart_Yuanbaojiaoyi"
			SuperTooltip2_Compare_StaticPart_Yuanbaojiaoyi:SetText("#{YBSC_100111_87}")
		elseif nYuanbaotrade == 2 then
			toDisplay = toDisplay .. ";SuperTooltip2_Compare_StaticPart_Yuanbaojiaoyi"
			SuperTooltip2_Compare_StaticPart_Yuanbaojiaoyi:SetText("#{YBSC_100111_88}")
        end
        		
		--世外桃源交易
		-- local nKVKExchangeFlag = SuperTooltips:GeKVKExchangeFlag()
		-- if(nKVKExchangeFlag ~= nil and (nKVKExchangeFlag == 1 or nKVKExchangeFlag == 3)) then
		-- 	toDisplay = toDisplay .. ";SuperTooltip2_Compare_StaticPart_KvkSpecial";
		-- 	SuperTooltip2_Compare_StaticPart_KvkSpecial:SetText("#{KVKGZ_110620_08}");
		-- end
		--T300交易市场标记
		local t300AuctionSubType = SuperTooltips2_Cmp1:GetT300AuctionSubType()
		if t300AuctionSubType > 0 then
			toDisplay = toDisplay .. ";SuperTooltip2_Compare_StaticPart_KvkSpecial";
			SuperTooltip2_Compare_StaticPart_KvkSpecial:SetText("#{FMQZ_221110_13}");
		end
		
		--宝石部分
		if type(nGemHoleCounts) == "number" and nGemHoleCounts>0 then 
			toDisplay = toDisplay .. ";SuperTooltip2_Compare_GemPart";
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
			toDisplay = toDisplay .. ";SuperTooltip2_Compare_Notice";
		end

		--属性
		if(szPropertys ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip2_Compare_Property";
		end

		--作者
		if(szAuthor ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip2_Compare_Manufacturer_Frame";
		end

		--详细解释
		toDisplay = toDisplay .. ";SuperTooltip2_Compare_Explain";

		--显示组件内容
		if(toDisplay=="") then
			this:Hide();
			return 0;
		end;
		_SuperTooltip2_Compare:SetProperty("PageElements",  toDisplay);
		
		----------------------------------------------------------------------
		--显示新的内容
		SuperTooltip2_Compare_EquipNow:SetText("#{ZBBJ_100329_3}");
		SuperTooltip2_Compare_StaticPart_Title:SetText(SuperTooltips2_Cmp1:GetTitle());
		SuperTooltip2_Compare_StaticPart_Item1:SetText(SuperTooltips2_Cmp1:GetDesc1());
		SuperTooltip2_Compare_StaticPart_Item2:SetText(SuperTooltips2_Cmp1:GetDesc2());
		SuperTooltip2_Compare_StaticPart_Item3:SetText(SuperTooltips2_Cmp1:GetDesc3());
		SuperTooltip2_Compare_StaticPart_Item4:SetText(SuperTooltips2_Cmp1:GetDesc4());
		SuperTooltip2_Compare_StaticPart_Item6:SetText(SuperTooltips2_Cmp1:GetDesc6());
		--SuperTooltip_StaticPart_Item5:SetText(SuperTooltips2_Cmp1:GetDesc5());
		SuperTooltip2_Compare_StaticPart_Icon:SetImage(SuperTooltips2_Cmp1:GetIconName());
		SuperTooltip2_Compare_ShortDesc_Text:SetText(typeDesc);
		
		SuperTooltip2_Compare_StaticPart_ZhiZun:SetText(nZhiZunEquipText)

		if nZhiZunEquipType == 1 then
			
			SuperTooltip2_Compare_StaticPart_Title:Hide()
			SuperTooltip2_Compare_StaticPart_Title1:Show()
			SuperTooltip2_Compare_StaticPart_Title2:Hide()
			SuperTooltip2_Compare_StaticPart_Title1:SetText(SuperTooltips2_Cmp1:GetTitle())
			
			SuperTooltip2_Compare_StaticPart_Animate:Show()
			SuperTooltip2_Compare_StaticPart_Animate:SetProperty("Animate" , "ZhiZun_Flash_Small")
			
		elseif nZhiZunEquipType == 2 then
			
			SuperTooltip2_Compare_StaticPart_Title:Hide()
			SuperTooltip2_Compare_StaticPart_Title1:Hide()
			SuperTooltip2_Compare_StaticPart_Title2:Show()
			SuperTooltip2_Compare_StaticPart_Title2:SetText(SuperTooltips2_Cmp1:GetTitle())
			
			SuperTooltip2_Compare_StaticPart_Animate:Show()
			SuperTooltip2_Compare_StaticPart_Animate:SetProperty("Animate" , "SuperEquip_Big")

		else
		
			SuperTooltip2_Compare_StaticPart_Title:Show()
			SuperTooltip2_Compare_StaticPart_Title1:Hide()
			SuperTooltip2_Compare_StaticPart_Title2:Hide()
			SuperTooltip2_Compare_StaticPart_Animate:Hide()
		end

		-- 显示雕纹
		local dwIcon = SuperTooltips2_Cmp1:GetDiaowenIcon()
		if (dwIcon ~= nil and dwIcon ~= "") then
			SuperTooltip2_Compare_StaticPart_DW:Show()
			SuperTooltip2_Compare_StaticPart_DW:SetProperty("Image", dwIcon)
		end

		-- 显示雕纹2
		local dwIconEx = SuperTooltips2_Cmp1:GetDiaowenIconEx()
		if (dwIconEx ~= nil and dwIconEx ~= "") then
			SuperTooltip2_Compare_StaticPart_DW1:Show()
			SuperTooltip2_Compare_StaticPart_DW1:SetProperty("Image", dwIconEx)
		end
		
	--	if (IsProtectd == "1" and unLockingElapsedTime ~= 0) then		
	--		local strLeftTime = SuperTooltip2_Compare_GetUnlockingStr(unLockingElapsedTime);		
	--		SuperTooltip2_Compare_UnlockingTimePart:SetText("#b#cFFFF00"..strLeftTime);
	--		SuperTooltip2_Compare_StaticPart_Icon_Protected : SetProperty("Image","set:CommonFrame6 image:NewLock");
	--	else
	--		SuperTooltip2_Compare_UnlockingTimePart:SetText("");
	--		SuperTooltip2_Compare_StaticPart_Icon_Protected : SetProperty("Image","set:UIIcons image:Icon_Lock");
	--	end
		
		if nGoodsProtect == 1 then
			SuperTooltip2_Compare_Protect_Text:SetText("#{GDWPBH_090507_4}")
		else
			SuperTooltip2_Compare_Protect_Text:SetText("")
		end

		if nEquipMasterFlag == 1 then
			SuperTooltip2_Compare_BaiBingJingTong_Text:SetText(nEquiMasterText);
		else
			SuperTooltip2_Compare_BaiBingJingTong_Text:SetText();
		end
		--tongxi modify 显示星星

		local qual =SuperTooltips2_Cmp1:GetEquipQual();
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
			SuperTooltip2_Compare_StaticPart_Icon_Protected:Show();
		end;
		--modify end
		if( type(nGemHoleCounts) == "number" and nGemHoleCounts>0) then

			if(nGemHoleCounts > 0) then 
				SuperTooltip2_Compare_StaticPart_Gem1:Show();
			end
			
			if(nGemHoleCounts > 1) then 
				SuperTooltip2_Compare_StaticPart_Gem2:Show();
			end
			
			if(nGemHoleCounts > 2) then 
				SuperTooltip2_Compare_StaticPart_Gem3:Show();
			end
			
			if(nGemHoleCounts > 3) then 
				SuperTooltip2_Compare_StaticPart_Gem4:Show();
			end
			
			
			local gemIcon = SuperTooltips2_Cmp1:GetGemIcon1();

			if(gemIcon ~= "") then
				SuperTooltip2_Compare_StaticPart_Gem1:SetProperty("ShortImage", gemIcon);
			end
			
			gemIcon = SuperTooltips2_Cmp1:GetGemIcon2();

			if(gemIcon ~= "") then
				SuperTooltip2_Compare_StaticPart_Gem2:SetProperty("ShortImage", gemIcon);
			end
			
			gemIcon = SuperTooltips2_Cmp1:GetGemIcon3();

			if(gemIcon ~= "") then
				SuperTooltip2_Compare_StaticPart_Gem3:SetProperty("ShortImage", gemIcon);
			end
			
			gemIcon = SuperTooltips2_Cmp1:GetGemIcon4();
			

			if(gemIcon ~= "") then
				SuperTooltip2_Compare_StaticPart_Gem4:SetProperty("ShortImage", gemIcon);
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
			SuperTooltip2_Compare_Property:SetText(szPropertys);
		end
		
		if(szAuthor ~= nil) then
			SuperTooltip2_Compare_Manufacturer:SetText(szAuthor);
		end
		
		SuperTooltip2_Compare_Explain:SetText(szExplain);

		return 1;
		
end

-------------------------------------------------------------------------------------------------------------------------------
--
-- 清空显示文本
--
function SuperTooltip2_Compare_ClearText()
		SuperTooltip2_Compare_EquipNow:SetText("");
		SuperTooltip2_Compare_StaticPart_Title:SetText("");
		SuperTooltip2_Compare_StaticPart_Item1:SetText("");
		SuperTooltip2_Compare_StaticPart_Item2:SetText("");
		SuperTooltip2_Compare_StaticPart_Item3:SetText("");
		SuperTooltip2_Compare_StaticPart_Item4:SetText("");
		SuperTooltip2_Compare_StaticPart_Item6:SetText("");
		SuperTooltip2_Compare_Protect_Text:SetText("");
		SuperTooltip2_Compare_StaticPart_DW:SetImage("")
		SuperTooltip2_Compare_StaticPart_DW:Hide()
		SuperTooltip2_Compare_StaticPart_DW1:SetImage("")
		SuperTooltip2_Compare_StaticPart_DW1:Hide()
		g_FitTitle:Hide();
		g_FitTxt:Hide();
		local starNum=9
		for i=1,starNum do
			g_Stars[i]:Hide();
		end;
		SuperTooltip2_Compare_StaticPart_Gem1:SetImage("");
		SuperTooltip2_Compare_StaticPart_Gem2:SetImage("");
		SuperTooltip2_Compare_StaticPart_Gem3:SetImage("");
		SuperTooltip2_Compare_StaticPart_Gem4:SetImage("");
		SuperTooltip2_Compare_StaticPart_Gem1:Hide();
		SuperTooltip2_Compare_StaticPart_Gem2:Hide()
		SuperTooltip2_Compare_StaticPart_Gem3:Hide()
		SuperTooltip2_Compare_StaticPart_Gem4:Hide()
		SuperTooltip2_Compare_Explain:SetText("");
		SuperTooltip2_Compare_Property:SetText("");
		SuperTooltip2_Compare_Manufacturer:SetText("");
		SuperTooltip2_Compare_StaticPart_Icon_Protected:Hide();
		SuperTooltip2_Compare_BaiBingJingTong_Text:SetText("");
end

