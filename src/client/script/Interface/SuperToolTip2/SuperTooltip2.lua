
local g_PurpleColor = "#c9107e1";
local g_BlueColor   = "#c00ccff";
local g_YellowColor = "#cfeff95";
local g_GreenColor	= "#c5bc257";

local g_NeedClickHide = 0;
local g_FirstShow = 1;
local g_FitTitle;
local g_FitTxt;
local g_Fit9Title;
local g_Fit9Txt;
--- 蜜语金丝对应蜜语
local g_supertooltip2_sweet_words = {
    [1] = { sweetWords = "#{MYJS_120723_27}\n                     " }, 
    [2] = { sweetWords = "#{MYJS_120723_28}\n                     " }, 
    [3] = { sweetWords = "#{MYJS_120723_29}\n                     " }, 
    [4] = { sweetWords = "#{MYJS_120723_30}\n                     " }, 
    [5] = { sweetWords = "#{MYJS_120723_31}\n                     " }, 
    [6] = { sweetWords = "#{MGZL_121012_11}\n                     " }, 
    [7] = { sweetWords = "#{MGZL_121012_12}\n                     " }, 
    [8] = { sweetWords = "#{MGZL_121012_13}\n                     " }, 
    [9] = { sweetWords = "#{MGZL_121012_14}\n                     " }, 
    [10] = { sweetWords = "#{MGZL_121012_15}\n                     " }, 
    [11] = { sweetWords = "#{QRPHB_150113_172}\n                     " }, 
    [12] = { sweetWords = "#{QRPHB_150113_173}\n                     " },
	[13] = { sweetWords = "#{QXLS_150724_144}\n                     " }, 
    [14] = { sweetWords = "#{QXLS_150724_145}\n                     " }, 
	[15] = { sweetWords = "#{QRJJN_221118_201}\n                     " }, 
    [16] = { sweetWords = "#{QRJJN_221118_202}\n                     " }, 
}

local g_supertooltip2_space_num = {
    [1]  = { spaceStr = "             - "},
    [2]  = { spaceStr = "            - "},
    [3]  = { spaceStr = "           - "},
    [4]  = { spaceStr = "          - "},
    [5]  = { spaceStr = "         - "},
    [6]  = { spaceStr = "        - "},
    [7]  = { spaceStr = "       - "},
    [8]  = { spaceStr = "      - "},
    [9]  = { spaceStr = "     - "},
    [10] = { spaceStr = "    - "},
    [11] = { spaceStr = "   - "},
    [12] = { spaceStr = "  - "},
    [13] = { spaceStr = " - "},
    [14] = { spaceStr = "- "},
	[15] = { spaceStr = "- "},
	[16] = { spaceStr = "- "},
}


function SuperTooltip2_PreLoad()
	this:RegisterEvent("SHOW_SUPERTOOLTIP2", true);
	
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function SuperTooltip2_OnLoad()
	SuperTooltip2_StaticPart_Money:SetClippedByParent(0);
		g_Stars={
				SuperTooltip2_StaticPart_Star1,
				SuperTooltip2_StaticPart_Star2,
				SuperTooltip2_StaticPart_Star3,
				SuperTooltip2_StaticPart_Star4,
				SuperTooltip2_StaticPart_Star5,
				SuperTooltip2_StaticPart_Star6,
				SuperTooltip2_StaticPart_Star7,
				SuperTooltip2_StaticPart_Star8,
				SuperTooltip2_StaticPart_Star9,
		};
	for i=1,9 do
		g_Stars[i]:Hide();
	end;
	g_FitTitle = SuperTooltip2_StaticPart_QH1;
	g_FitTxt = SuperTooltip2_StaticPart_QH2;
	g_FitTitle:Hide();
	g_FitTxt:Hide();
	g_Fit9Title = SuperTooltip2_StaticPart_QL1;
	g_Fit9Txt = SuperTooltip2_StaticPart_QL2;
	g_Fit9Title:Hide();
	g_Fit9Txt:Hide();
	--AxTrace(0, 2, "LoadSuperTooltips");
end										

function SuperTooltip2_OnEvent(event)

--	SuperTooltip2_StaticPart_Money:Hide();
	if(event == "SHOW_SUPERTOOLTIP2") then
		if( arg0 == "1" and SuperTooltips2:IsPresent()) then
			
			SuperTooltips2:SendAskItemInfoMsg();
			SuperTooltip2_Update();
			_SuperTooltip2_:PositionSelf(0, 0, 1, 1);
			local rH = _SuperTooltip2_:GetProperty("AbsoluteHeight");
			_SuperTooltip2_:SetProperty("AbsoluteXPosition",0)
			_SuperTooltip2_:SetProperty("AbsoluteYPosition",0)
			SuperTooltip2_Frame:SetProperty("AbsoluteHeight", tostring(rH+5.0));

			if(g_FirstShow == 1) then 
				SuperTooltip2_Frame:CenterWindow();
				g_FirstShow = 0;
			end
			--------显示装备比较窗口---------Start
			local nCmpWndCount = tonumber(arg4)
			local posX = SuperTooltip2_Frame:GetProperty("AbsoluteXPosition")
			local posY = SuperTooltip2_Frame:GetProperty("AbsoluteYPosition")
			local nWidth = SuperTooltip2_Frame:GetProperty("AbsoluteWidth")
			SuperTooltips2:ShowCmp2WindowMain( tonumber(posX) ,tonumber(posY) ,tonumber(nWidth) ,nCmpWndCount )
			--------显示装备比较窗口---------End
			
			if IsWindowShow("DressSuperToolTip2") then
				CloseWindow("DressSuperToolTip2", true)
			end
			
			this:Show();			
			return;
        elseif arg0 == "2" and SuperTooltips2:IsPresent() and this:IsVisible() then
            --- 这种情况是，按下Alt键，要显示聊天频道的装备属性对比
            SuperTooltips2:ShowToolTips2WithAlt( 1 )
            return
        elseif arg0 == "3" and SuperTooltips2:IsPresent() and this:IsVisible() then
            --- 这种情况是：抬起Alt键，要关闭聊天频道的装备属性对比
            SuperTooltips2:ShowToolTips2WithAlt( 0 )
            return
		else
			this:Hide();
			return;
		end
	elseif( event == "ADJEST_UI_POS" ) then
		-- 更新界面位置
		SuperTooltip2_Frame:CenterWindow();
		return ;
	-- 游戏分辨率发生了变化
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 更新界面位置	
		SuperTooltip2_Frame:CenterWindow();
		return ;
	end
	
	this:Hide();	
end

function SuperTooltip2_Update()
		g_NeedClickHide = 0;
		-- 先清空以前显示的文字
		SuperTooltip2_ClearText();
		
		if(SuperTooltips2:IsTransferItem()) then
			g_NeedClickHide = 1;
		end
		if(SuperTooltips2:IsTransferPneuma()) then
			g_NeedClickHide = 1;
		end
		
		if SuperTooltips2:IsTransferPND() then
			g_NeedClickHide = 1
		end
		
		local typeDesc = SuperTooltips2:GetTypeDesc();
		local nGemHoleCounts = SuperTooltips2:GetGemHoleCounts();
		local nMoney1, szMoneyDesc1 = SuperTooltips2:GetMoney1();
		local nMoney2, szMoneyDesc2 = SuperTooltips2:GetMoney2();
		local szPropertys = SuperTooltips2:GetPropertys();
		local szAuthor = SuperTooltips2:GetAuthorInfo();
		local szExplain = SuperTooltips2:GetExplain();
		local nYuanbaotrade = SuperTooltips2:GetYuanbaoTradeFlag();
		local nGoodsProtect = SuperTooltips2:GetGoodsProtect_Goods();
		local nEquipMasterFlag = SuperTooltips2:GetEquipMasterFlag();
		local nEquiMasterText = SuperTooltips2:GetEquipMasterText();
		local nBaiShouLevelText = SuperTooltips2:GetBaiShouLevelText();
		local nZhiZunEquipText = SuperTooltips2:GetZhiZunEquipText();
		local nZhiZunEquipType = SuperTooltips2:GetZhiZunEquipType();
		
		
				
		local nBieYeFurniture1 = SuperTooltips2:GetBieYeFurniture1();
		--local nBieYeFurniture2 = SuperTooltips2:GetBieYeFurniture2();
		--local nBieYeFurniture3 = SuperTooltips2:GetBieYeFurniture3();

		local bShowExplainExtra = SuperTooltips2:LuaFnIsShowExplainExtra()
		local szExplainExtra = SuperTooltips2:LuaFnGetExplainExtra()

		----------------------------------------------------------------------
		--移民家具
		if(nBieYeFurniture1 ~= nil and nBieYeFurniture1 ~= '') then
			SuperTooltip2_BieYeFurniture_Text1:SetText(nBieYeFurniture1);
		end
		if(nBieYeFurniture2 ~= nil and nBieYeFurniture2 ~= '') then
			--SuperTooltip2_BieYeFurniture_Text2:SetText(nBieYeFurniture2);
		end
		if(nBieYeFurniture3 ~= nil and nBieYeFurniture3 ~= '') then
			--SuperTooltip2_BieYeFurniture_Text3:SetText(nBieYeFurniture3);
		end

		--显示静态头
		local toDisplay = "SuperTooltip2_PageHeader";
		
		--加上类型描述
		if(nBieYeFurniture1 == nil or nBieYeFurniture1 == '') then
			if( typeDesc ~= nil) then 
				toDisplay = toDisplay .. ";SuperTooltip2_ShortDesc";
			end
		end
		
		--宝石部分
		if type(nGemHoleCounts) == "number" and nGemHoleCounts>0 then 
			toDisplay = toDisplay .. ";SuperTooltip2_GemPart";
		end

		--元宝交易
		if nYuanbaotrade == 0 then
			toDisplay = toDisplay .. ";SuperTooltip2_StaticPart_Yuanbaojiaoyi"
			SuperTooltip2_StaticPart_Yuanbaojiaoyi:SetText("#{YBSC_100111_87}")
		elseif nYuanbaotrade == 2 then
			toDisplay = toDisplay .. ";SuperTooltip2_StaticPart_Yuanbaojiaoyi"
			SuperTooltip2_StaticPart_Yuanbaojiaoyi:SetText("#{YBSC_100111_88}")
        end
        
		--世外桃源交易
		-- local nKVKExchangeFlag = SuperTooltips2:GeKVKExchangeFlag()
		-- if(nKVKExchangeFlag ~= nil and (nKVKExchangeFlag == 1 or nKVKExchangeFlag == 3)) then
		-- 	toDisplay = toDisplay .. ";SuperTooltip2_StaticPart_KvkSpecial";
		-- 	SuperTooltip2_StaticPart_KvkSpecial:SetText("#{KVKGZ_110620_08}");
		-- end
		--T300交易市场标记
		local t300AuctionSubType = SuperTooltips2:GetT300AuctionSubType()
		if t300AuctionSubType > 0 then
			toDisplay = toDisplay .. ";SuperTooltip2_StaticPart_KvkSpecial";
			SuperTooltip2_StaticPart_KvkSpecial:SetText("#{FMQZ_221110_13}");
		end

		--鬼市道具标记
		local guiShiItemFlag = SuperTooltips2:GetGuiShiItemFlag()
		--鬼市交易标记
		local guiShiJiaoYiFlag = SuperTooltips2:GetGuiShiJiaoYiFlag()
		if guiShiJiaoYiFlag == 1 then
			toDisplay = toDisplay .. ";SuperTooltip2_StaticPart_GuiShiSpecial";
			SuperTooltip2_StaticPart_GuiShiSpecial:SetText("#{GSJC_190801_85}");
		elseif guiShiJiaoYiFlag == 2 then
			toDisplay = toDisplay .. ";SuperTooltip_StaticPart_GuiShiSpecial";
			SuperTooltip2_StaticPart_GuiShiSpecial:SetText("#{GSJC_190801_81}");
		end
		

		--金钱1
		if( nMoney1 ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip2_MoneyPart";
		end

		--金钱2
		if(nMoney2 ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip2_MoneyPart2";
		end
		


		if nGoodsProtect == 1 or nEquipMasterFlag == 1 then
			if(nBieYeFurniture1 == nil or nBieYeFurniture1 == '') then	
				toDisplay = toDisplay .. ";SuperTooltip2_Notice";
			end
		end

		--属性
		if(szPropertys ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip2_Property";
		end

		--作者
        --- 下面的判定条件表示是时装, 这里为蜜语金丝活动特写
        local sweetWordsID = SuperTooltips2 : GetSweetWordsID()
		if(szAuthor ~= nil and sweetWordsID <= 0 ) then 
			toDisplay = toDisplay .. ";SuperTooltip2_Manufacturer_Frame";
		end

		--别墅家具
		--移民家具
		if (nBieYeFurniture1 ~= nil and nBieYeFurniture1 ~= '') then
			toDisplay = toDisplay .. ";SuperTooltip2_BieYeFurniture_Frame";
		end


		--详细解释
		toDisplay = toDisplay .. ";SuperTooltip2_Explain";

		if bShowExplainExtra == 1 then
			toDisplay = toDisplay .. ";SuperTooltip2_Armor"
		end

		--显示组件内容
		_SuperTooltip2_:SetProperty("PageElements", toDisplay);
		
		----------------------------------------------------------------------
		--显示新的内容
		SuperTooltip2_StaticPart_Title:SetText(SuperTooltips2:GetTitle());
		SuperTooltip2_StaticPart_Item1:SetText(SuperTooltips2:GetDesc1());
		SuperTooltip2_StaticPart_Item2:SetText(SuperTooltips2:GetDesc2());
		SuperTooltip2_StaticPart_Item3:SetText(SuperTooltips2:GetDesc3());
		--SuperTooltip2_StaticPart_Item4:SetText(SuperTooltips2:GetDesc4());
		SuperTooltip2_StaticPart_Item4:SetText(SuperTooltips2:GetDesc4());
		SuperTooltip2_StaticPart_Item6:SetText(SuperTooltips2:GetDesc6());
		local IsProtectd	=SuperTooltips2:GetDesc5();
		
		--SuperTooltip_StaticPart_Item5:SetText(SuperTooltips:GetDesc5());
		SuperTooltip2_StaticPart_Icon:SetImage(SuperTooltips2:GetIconName());
		SuperTooltip2_ShortDesc_Text:SetText(typeDesc);
		
		SuperTooltip2_StaticPart_ZhiZun:SetText(nZhiZunEquipText)
		
		if nZhiZunEquipType == 1 then
			
			SuperTooltip2_StaticPart_Title:Hide()
			SuperTooltip2_StaticPart_Title1:Show()
			SuperTooltip2_StaticPart_Title2:Hide()
			SuperTooltip2_StaticPart_Title1:SetText(SuperTooltips2:GetTitle())
			
			SuperTooltip2_StaticPart_Animate:Show()
			SuperTooltip2_StaticPart_Animate:SetProperty("Animate" , "ZhiZun_Flash_Small")
			
		elseif nZhiZunEquipType == 2 then
		
			SuperTooltip2_StaticPart_Title:Hide()
			SuperTooltip2_StaticPart_Title1:Hide()
			SuperTooltip2_StaticPart_Title2:Show()
			SuperTooltip2_StaticPart_Title2:SetText(SuperTooltips2:GetTitle())
			
			SuperTooltip2_StaticPart_Animate:Show()
			SuperTooltip2_StaticPart_Animate:SetProperty("Animate" , "SuperEquip_Big")

		else
			
			SuperTooltip2_StaticPart_Title:Show()
			SuperTooltip2_StaticPart_Title1:Hide()
			SuperTooltip2_StaticPart_Title2:Hide()
			SuperTooltip2_StaticPart_Animate:Hide()
		end

		-- 显示雕纹
		local dwIcon = SuperTooltips2:GetDiaowenIcon()
		if (dwIcon ~= nil and dwIcon ~= "") then
			SuperTooltip2_StaticPart_DW:Show()
			SuperTooltip2_StaticPart_DW:SetProperty("Image", dwIcon)
		end
		
		-- 显示雕纹2
		local dwIconEx = SuperTooltips2:GetDiaowenIconEx()
		if (dwIconEx ~= nil and dwIconEx ~= "") then
			SuperTooltip2_StaticPart_DW1:Show()
			SuperTooltip2_StaticPart_DW1:SetProperty("Image", dwIconEx)
		end
		
		if nGoodsProtect == 1 then
			if(nBieYeFurniture1 == nil or nBieYeFurniture1 == '') then	
				SuperTooltip2_Protect_Text:SetText("#{GDWPBH_090507_4}")
			else
				SuperTooltip2_BieYeFurniture_Protect_Text:SetText("#{GDWPBH_090507_4}")
			end
		else
			SuperTooltip2_Protect_Text:SetText("")
			SuperTooltip2_BieYeFurniture_Protect_Text:SetText("")
		end
		
		if nEquipMasterFlag == 1 then
			SuperTooltip2_BaiBingJingTong_Text:SetText(nEquiMasterText)
		else
			SuperTooltip2_BaiBingJingTong_Text:SetText("")
		end
		
		--百兽精通
		local nIsBaiShou = Pet:GetIsBaiShou()
		if nIsBaiShou == 1 then
			SuperTooltip2_baishouJingTong_Text : SetText(nBaiShouLevelText)
		else
			SuperTooltip2_baishouJingTong_Text : SetText("")
		end
		
		--tongxi modify 显示星星		
		local qual =SuperTooltips2:GetEquipQual();
		if(type(qual) == "number" and tonumber(qual)>0)then
			local nByQual = tonumber(qual)
			local starNum = 0;
			local nFit = 0;
			if nByQual> 100 then
				starNum = 8
				nFit = math.mod(nByQual,100)
				g_Fit9Txt:SetText("" .. nFit .. "/20")
				g_Fit9Title:Show();
				g_Fit9Txt:Show();
				g_FitTitle:Hide();
				g_FitTxt:Hide();
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
				starNum	= nByQual
				g_FitTitle:Hide();
				g_FitTxt:Hide();
				g_Fit9Title:Hide();
				g_Fit9Txt:Hide();
			end

			if(starNum<10) then
				for i=1,starNum do
					--AxTrace( 5,0,StrongLevel.."hehe" );
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
			SuperTooltip2_StaticPart_Icon_Protected:Show();
		end;
		--modify end
		
		if( type(nGemHoleCounts) == "number" and nGemHoleCounts>0) then
			if(nGemHoleCounts > 0) then 
				SuperTooltip2_StaticPart_Gem1:Show();
			end
			
			if(nGemHoleCounts > 1) then 
				SuperTooltip2_StaticPart_Gem2:Show();
			end
			
			if(nGemHoleCounts > 2) then 
				SuperTooltip2_StaticPart_Gem3:Show();
			end
		
			if(nGemHoleCounts > 3) then 
				SuperTooltip2_StaticPart_Gem4:Show();
			end
			
			local gemIcon = SuperTooltips2:GetGemIcon1();
			if(gemIcon ~= "") then
				SuperTooltip2_StaticPart_Gem1:SetImage(gemIcon);
			end
			
			gemIcon = SuperTooltips2:GetGemIcon2();
			if(gemIcon ~= "") then
				SuperTooltip2_StaticPart_Gem2:SetImage(gemIcon);
			end
			
			gemIcon = SuperTooltips2:GetGemIcon3();
			if(gemIcon ~= "") then
				SuperTooltip2_StaticPart_Gem3:SetImage(gemIcon);
			end
			
			gemIcon = SuperTooltips2:GetGemIcon4();
			if(gemIcon ~= "") then
				SuperTooltip2_StaticPart_Gem4:SetImage(gemIcon);
			end
			
		end

		if(nMoney1 ~= nil)  then
			SuperTooltip2_StaticPart_Money_Text:SetText(szMoneyDesc1);
			SuperTooltip2_StaticPart_Money:SetProperty("MoneyNumber", tostring(nMoney1));
		end
		
		if(nMoney2 ~= nil)  then
			SuperTooltip2_StaticPart_Money_Text_2:SetText(szMoneyDesc2);
			SuperTooltip2_StaticPart_Money_2:SetProperty("MoneyNumber", tostring(nMoney2));
		end
		
		if( szPropertys ~= nil) then
			if string.sub(szPropertys,-1,-1) == '\n' then
				szPropertys = string.sub(szPropertys,1,-2)
			end
			SuperTooltip2_Property:SetText(szPropertys)
		end
		
		if(szAuthor ~= nil) then
            if sweetWordsID > 0 then
                local len = string.len( szAuthor ) - 8
                if len == nil or len > 14 or len <= 0 then
                    len = 14
                end
                local spaceStr = g_supertooltip2_space_num[len].spaceStr
                local sweetWords = g_supertooltip2_sweet_words[ tonumber( sweetWordsID ) ].sweetWords
                if sweetWords ~= nil and sweetWords ~= "" then
                    if szPropertys ~= nil then
                        SuperTooltip2_Property:SetText(szPropertys.."\n#{MYJS_120723_25}\n"..sweetWords..spaceStr..szAuthor );
                    else
                        SuperTooltip2_Property:SetText(             "\n#{MYJS_120723_25}\n"..sweetWords..spaceStr..szAuthor );
                    end
                end
            else
    			SuperTooltip2_Manufacturer:SetText(szAuthor);
            end
		end

		--百兽精通
		local nIsZhenShouDan = SuperTooltips:GetTypeIsZhenShouDan()
		local nIsBaiShou = Pet:GetIsBaiShou()
		if nIsZhenShouDan == 1 and nIsBaiShou == 1 then
			szExplain = szExplain.."\n".."#{BSJT_130114_07}"
		end
		
		SuperTooltip2_Explain:SetText(szExplain);
		
		SuperTooltip2_Armor:SetText(szExplainExtra)
		
end

-------------------------------------------------------------------------------------------------------------------------------
--
-- 清空显示文本
--
function SuperTooltip2_ClearText()
		SuperTooltip2_StaticPart_Title:SetText("");
		SuperTooltip2_StaticPart_Item1:SetText("");
		SuperTooltip2_StaticPart_Item2:SetText("");
		SuperTooltip2_StaticPart_Item3:SetText("");
		SuperTooltip2_StaticPart_Item4:SetText("");
		SuperTooltip2_StaticPart_Item6:SetText("");
		SuperTooltip2_StaticPart_DW:SetImage("")
		SuperTooltip2_StaticPart_DW:Hide()
		SuperTooltip2_StaticPart_DW1:SetImage("")
		SuperTooltip2_StaticPart_DW1:Hide()
		SuperTooltip2_Protect_Text:SetText("");
		SuperTooltip2_BieYeFurniture_Protect_Text:SetText("");
		SuperTooltip2_StaticPart_Gem1:SetImage("");
		SuperTooltip2_StaticPart_Gem2:SetImage("");
		SuperTooltip2_StaticPart_Gem3:SetImage("");
		SuperTooltip2_StaticPart_Gem4:SetImage("");
		SuperTooltip2_StaticPart_Gem1:Hide()
		SuperTooltip2_StaticPart_Gem2:Hide();
		SuperTooltip2_StaticPart_Gem3:Hide();
		SuperTooltip2_StaticPart_Gem4:Hide();
		
		SuperTooltip2_Explain:SetText("");
		SuperTooltip2_Property:SetText("");
		SuperTooltip2_Manufacturer:SetText("");
		SuperTooltip2_StaticPart_Icon_Protected:Hide();
		
		SuperTooltip2_BieYeFurniture_Text1:SetText("");
		--SuperTooltip2_BieYeFurniture_Text2:SetText("");
		--SuperTooltip2_BieYeFurniture_Text3:SetText("");

		g_FitTitle:Hide();
		g_FitTxt:Hide();
		g_Fit9Title:Hide();
		g_Fit9Txt:Hide();
		local starNum=9
		for i=1,starNum do
			g_Stars[i]:Hide();
		end;
		SuperTooltip2_BaiBingJingTong_Text:SetText("");
		
		
end

function SuperTooltip2_LClick()
	if( 1 == g_NeedClickHide and this:IsVisible()) then
		g_NeedClickHide = 0;
		this:Hide();
	end
end


function SuperTooltip2_OnMoved()
	
	local posX = SuperTooltip2_Frame:GetProperty("AbsoluteXPosition")
	local posY = SuperTooltip2_Frame:GetProperty("AbsoluteYPosition")
	local nWidth = SuperTooltip2_Frame:GetProperty("AbsoluteWidth")
	SuperTooltips2:Cmp2WindowMainMove(tonumber(posX) , tonumber(posY) , tonumber(nWidth))
	
end

function SuperTooltip2_OnHide()
	SuperTooltips2:CloseCmp2WindowMain()
	SuperTooltips2:CloseCmp2WindowSub()
end
