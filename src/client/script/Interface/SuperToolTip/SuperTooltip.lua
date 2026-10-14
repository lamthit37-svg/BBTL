local CU_MONEY			= 1	-- 钱
local CU_GOODBAD		= 2	-- 善恶值
local CU_MORALPOINT		= 3	-- 师德点
local CU_TICKET			= 4 -- 官票钱
local CU_YUANBAO		= 5	-- 元宝
local CU_ZENGDIAN		= 6 -- 赠点
local CU_MENPAI_POINT	= 7 -- 师门贡献度
local CU_MONEYJZ		= 8 -- 交子
local CU_BIND_YUANBAO	= 9 -- 绑定元宝
local CU_GIFTTOKEN		= 10 -- 返券
local CU_LIJIN			= 11 --礼金
local CU_BWHONOURVALUE = 12 --比武大会荣誉值

local g_pos1;
local g_pos2;
local g_PurpleColor = "#c9107e1";
local g_BlueColor   = "#c00ccff";
local g_YellowColor = "#cfeff95";
local g_GreenColor	= "#c5bc257";
local g_Stars;	
local g_FitTxt; 
local g_FitTitle;
local g_Fit9Txt; 
local g_Fit9Title;


local g_nUnlockingTimeNeeded = 259200;
local y_offset = 25
local g_left , g_top , g_right , g_bottom

--- 蜜语金丝对应蜜语
local g_supertooltip_sweet_words = {
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

local g_supertooltip_space_num = {
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


function g_GetUnlockingStr ( nUnlockElapsedTime )
	local nLeftTime = g_nUnlockingTimeNeeded - nUnlockElapsedTime;
	local strLeftTime = "";
		
	if( nLeftTime <= 0 ) then
		strLeftTime = "解锁成功！放入背包中切换场景正式解锁。";
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

function SuperTooltip_PreLoad()
	this:RegisterEvent("SHOW_SUPERTOOLTIP",true);
	this:RegisterEvent("UPDATE_SUPERTOOLTIP",false);
end

function SuperTooltip_OnLoad()
	SuperTooltip_StaticPart_Money:SetClippedByParent(0);
	SuperTooltip_StaticPart_Money_JiaoZi:SetClippedByParent(0);
	g_Stars={
				SuperTooltip_StaticPart_Star1,
				SuperTooltip_StaticPart_Star2,
				SuperTooltip_StaticPart_Star3,
				SuperTooltip_StaticPart_Star4,
				SuperTooltip_StaticPart_Star5,
				SuperTooltip_StaticPart_Star6,
				SuperTooltip_StaticPart_Star7,
				SuperTooltip_StaticPart_Star8,
				SuperTooltip_StaticPart_Star9,
		};
	for i=1,9 do
		g_Stars[i]:Hide();
	end;
	
	g_left = 0;
	g_top  = 0;
	g_right = 0;
	g_bottom = 0;
	g_mCmpWndCount = 0;
	g_FitTxt = SuperTooltip_StaticPart_QH2;
	g_FitTitle = SuperTooltip_StaticPart_QH1
	g_FitTxt:Hide();
	g_FitTitle:Hide();
	g_Fit9Title = SuperTooltip_StaticPart_QL1
	g_Fit9Txt = SuperTooltip_StaticPart_QL2;
	g_Fit9Title:Hide();
	g_Fit9Txt:Hide();
end										

function SuperTooltip_OnEvent(event)

--	SuperTooltip_StaticPart_Money:Hide();
	if(event == "SHOW_SUPERTOOLTIP") then
		--针对子女卡牌的特写，子女卡牌拥有独立的tip--Cardtip，因此在此将事件屏蔽
		if( arg0 == "1" and SuperTooltips:IsPresent() and true ~= SuperTooltips:Infant_IsInfantCard()) then
				local isAsk = SuperTooltips:SendAskItemInfoMsg();
				-- PushDebugMessage( "xtc:SHOW_SUPERTOOLTIP")
			if(SuperTooltip_Update(isAsk)==1) then
				g_pos1, g_pos2 = _SuperTooltip_:PositionSelf(arg2, arg3, arg4, arg5);	
				g_left = arg2;
				g_top  = arg3;
				g_right = arg4;
				g_bottom = arg5;
				g_mCmpWndCount = tonumber(arg6)
				if isAsk == 0 then
					--------显示装备比较窗口---------Start
					local isRight = 1
					if tonumber(g_pos1) < tonumber(arg2) then
						isRight = 0
					end
					local nCmpWndCount = tonumber(arg6)
					if nCmpWndCount > 0 and g_pos2 < y_offset then
						 g_pos2 = y_offset
						_SuperTooltip_:SetProperty("AbsoluteYPosition",g_pos2)
					end
					local nWidth = _SuperTooltip_:GetProperty("AbsoluteWidth")
					SuperTooltips:ShowCmpWindowMain( tonumber(g_pos1) ,tonumber(g_pos2) ,tonumber(nWidth) ,nCmpWndCount ,isRight)
					--------显示装备比较窗口---------End				
				end
				this:Show();
			end;
			return;
		else
			this:Hide();
			return;

		end
	end
	
	if(event == "UPDATE_SUPERTOOLTIP") then
		if(this:IsVisible() and SuperTooltips:IsPresent()) then
			-- PushDebugMessage( "xtc:UPDATE_SUPERTOOLTIP")
            if arg0 == "1" then
                 --- 鼠标滑动到道具上方，按下Alt键，此处回调NotifyTooltipsShow函数，显示装备属性对比
                 --- 这个是装备属性对比优化的功能
                 SuperTooltips:ShowToolTipsWithAlt( tonumber(g_left), tonumber(g_top), tonumber(g_right), tonumber(g_bottom) )
                 return
            else
    			SuperTooltip_Update(0);
	    		g_pos1, g_pos2 = _SuperTooltip_:PositionSelf(g_left, g_top, g_right, g_bottom);
		    	--------显示装备比较窗口---------Start
			    if tonumber(arg0) == 0 then
				   	g_mCmpWndCount = 0
				end
				local isRight = 1
				if tonumber(g_pos1) < tonumber(g_left) then
					isRight = 0
				end
				local nCmpWndCount = g_mCmpWndCount
				if nCmpWndCount > 0 and g_pos2 < y_offset then
					 g_pos2 = y_offset
					_SuperTooltip_:SetProperty("AbsoluteYPosition",g_pos2)
				end
				local nWidth = _SuperTooltip_:GetProperty("AbsoluteWidth")
                --- 注意：如果参数为2的话，就是抬起了Alt键，这时要关闭装备属性对比
                if arg0 == "2" then
                    nCmpWndCount = 0
                end
				SuperTooltips:ShowCmpWindowMain( tonumber(g_pos1) ,tonumber(g_pos2) ,tonumber(nWidth) ,nCmpWndCount ,isRight)
			    --------显示装备比较窗口---------End
			    return;
            end
		end;
	end
	
end

function SuperTooltip_Update(isAskExtraInfo)
		-- 先清空以前显示的文字
		SuperTooltip_ClearText();
		
		local typeDesc = SuperTooltips:GetTypeDesc();
		local nGemHoleCounts = SuperTooltips:GetGemHoleCounts();
		local nMoney1, szMoneyDesc1 = SuperTooltips:GetMoney1();
		local nMoney2, szMoneyDesc2 = SuperTooltips:GetMoney2();
		local szPropertys = SuperTooltips:GetPropertys();
		local szAuthor = SuperTooltips:GetAuthorInfo();
		local szExplain = SuperTooltips:GetExplain();
		
		local unLockingElapsedTime	=SuperTooltips:GetPUnlockElapsedTime();
		local IsProtectd	=SuperTooltips:GetDesc5();
		local nYuanbaotrade = SuperTooltips:GetYuanbaoTradeFlag();
		local nGoodsProtect = SuperTooltips:GetGoodsProtect_Goods();
		local nEquipMasterFlag = SuperTooltips:GetEquipMasterFlag();
		local nEquiMasterText = SuperTooltips:GetEquipMasterText();
		local nBaiShouLevelText = SuperTooltips:GetBaiShouLevelText();
		local nZhiZunEquipText = SuperTooltips:GetZhiZunEquipText();
		local nZhiZunEquipType = SuperTooltips:GetZhiZunEquipType();
		
		
		local nBieYeFurniture1 = SuperTooltips:GetBieYeFurniture1();
		local nBieYeFurniture2 = SuperTooltips:GetBieYeFurniture2();
		local nBieYeFurniture3 = SuperTooltips:GetBieYeFurniture3();
		
		local bShowExplainExtra = SuperTooltips:LuaFnIsShowExplainExtra()
		local szExplainExtra = SuperTooltips:LuaFnGetExplainExtra()
		
		----------------------------------------------------------------------
		
		--移民家具
		if(nBieYeFurniture1 ~= nil and nBieYeFurniture1 ~= '') then
			SuperTooltip_BieYeFurniture_Text1:SetText(nBieYeFurniture1);
		end
		if(nBieYeFurniture2 ~= nil and nBieYeFurniture2 ~= '') then
			--SuperTooltip_BieYeFurniture_Text2:SetText(nBieYeFurniture2);
		end
		if(nBieYeFurniture3 ~= nil and nBieYeFurniture3 ~= '') then
			--SuperTooltip_BieYeFurniture_Text3:SetText(nBieYeFurniture3);
		end
		--显示静态头
		local toDisplay = "";
		
		if(SuperTooltips:GetTitle()~="" and SuperTooltips:GetIconName()~="")then
			toDisplay = toDisplay .."SuperTooltip_PageHeader";
		end
		
		--剩余解锁时间
		if( IsProtectd == "1" and unLockingElapsedTime ~= 0) then
			toDisplay = toDisplay .. ";SuperTooltip_UnlockingTimePart";
		end
		
		
		--加上类型描述
		if(nBieYeFurniture1 == nil or nBieYeFurniture1 == '') then
			if( typeDesc ~= nil) then 
				toDisplay = toDisplay .. ";SuperTooltip_ShortDesc";
			end
		end
		--元宝交易
		if nYuanbaotrade == 0 then
			toDisplay = toDisplay .. ";SuperTooltip_StaticPart_Yuanbaojiaoyi"
			SuperTooltip_StaticPart_Yuanbaojiaoyi:SetText("#{YBSC_100111_87}")
		elseif nYuanbaotrade == 2 then
			toDisplay = toDisplay .. ";SuperTooltip_StaticPart_Yuanbaojiaoyi"
			SuperTooltip_StaticPart_Yuanbaojiaoyi:SetText("#{YBSC_100111_88}")
        end
			
		--世外桃源交易
		-- local nKVKExchangeFlag = SuperTooltips:GeKVKExchangeFlag()
		-- if(nKVKExchangeFlag ~= nil and (nKVKExchangeFlag == 1 or nKVKExchangeFlag == 3)) then
		-- 	toDisplay = toDisplay .. ";SuperTooltip_StaticPart_KvkSpecial";
		-- 	SuperTooltip_StaticPart_KvkSpecial:SetText("#{KVKGZ_110620_08}");
		-- end
		--T300交易市场标记
		if isAskExtraInfo == 0 then
			local t300AuctionSubType = SuperTooltips:GetT300AuctionSubType()
			if t300AuctionSubType > 0 then
				toDisplay = toDisplay .. ";SuperTooltip_StaticPart_KvkSpecial";
				SuperTooltip_StaticPart_KvkSpecial:SetText("#{FMQZ_221110_13}");
			end
		end

		--鬼市道具标记
		local guiShiItemFlag = SuperTooltips:GetGuiShiItemFlag()
		--鬼市交易标记
		local guiShiJiaoYiFlag = SuperTooltips:GetGuiShiJiaoYiFlag()
		if guiShiJiaoYiFlag == 1 then
			toDisplay = toDisplay .. ";SuperTooltip_StaticPart_GuiShiSpecial";
			SuperTooltip_StaticPart_GuiShiSpecial:SetText("#{GSJC_190801_85}");
		elseif guiShiJiaoYiFlag == 2 then
			toDisplay = toDisplay .. ";SuperTooltip_StaticPart_GuiShiSpecial";
			SuperTooltip_StaticPart_GuiShiSpecial:SetText("#{GSJC_190801_81}");
		end
		
		--宝石部分
		if type(nGemHoleCounts) == "number" and nGemHoleCounts>0 then 
			toDisplay = toDisplay .. ";SuperTooltip_GemPart";
		end
		--金钱1
		if( nMoney1 ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip_MoneyPart";
		end

		--金钱2
		if(nMoney2 ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip_MoneyPart_2";
		end
		


		if nGoodsProtect == 1 or nEquipMasterFlag == 1 then
			if(nBieYeFurniture1 == nil or nBieYeFurniture1 == '') then	
				toDisplay = toDisplay .. ";SuperTooltip_Notice";
			else
				toDisplay = toDisplay .. ";SuperTooltip_BieYeFurniture_Protect_Text";
			end
		end

		--属性
		if(szPropertys ~= nil) then 
			toDisplay = toDisplay .. ";SuperTooltip_Property";
		end

		--作者
        --- 下面的判定条件表示是时装, 这里为蜜语金丝活动特写
        local sweetWordsID = SuperTooltips : GetSweetWordsID()
		if(szAuthor ~= nil and sweetWordsID <= 0 ) then 
			toDisplay = toDisplay .. ";SuperTooltip_Manufacturer_Frame";
		end

		--别墅家具
		--移民家具
		if (nBieYeFurniture1 ~= nil and nBieYeFurniture1 ~= '') then 
			toDisplay = toDisplay .. ";SuperTooltip_BieYeFurniture_Frame";
		end

		--详细解释
		toDisplay = toDisplay .. ";SuperTooltip_Explain";

		if bShowExplainExtra == 1 then
			toDisplay = toDisplay .. ";SuperTooltip_Armor"
		end

		--显示组件内容
		if(toDisplay=="") then
			this:Hide();
			return 0;
		end;

		_SuperTooltip_:SetProperty("PageElements",  toDisplay);
		
		----------------------------------------------------------------------
	
		--显示新的内容
		SuperTooltip_StaticPart_Title:SetText(SuperTooltips:GetTitle());
		SuperTooltip_StaticPart_Item1:SetText(SuperTooltips:GetDesc1());
		SuperTooltip_StaticPart_Item2:SetText(SuperTooltips:GetDesc2());
		SuperTooltip_StaticPart_Item3:SetText(SuperTooltips:GetDesc3());
		SuperTooltip_StaticPart_Item4:SetText(SuperTooltips:GetDesc4());
		--SuperTooltip_StaticPart_Item5:SetText(SuperTooltips:GetDesc5());
		SuperTooltip_StaticPart_Item6:SetText(SuperTooltips:GetDesc6());
		SuperTooltip_StaticPart_Icon:SetImage(SuperTooltips:GetIconName());
		SuperTooltip_ShortDesc_Text:SetText(typeDesc);
		
		SuperTooltip_StaticPart_ZhiZun:SetText(nZhiZunEquipText)
		
		local nTalentType = SuperTooltips:GetZongMenTalentTpye()
		if nTalentType>0 then
			SuperTooltip_ZongMenSkill_TalentAttrFrame:Show()
			for j = 1,6 do 
				if nTalentType == j then
					_G["SuperTooltip_ZongMenSkill_TalentAttr"..j]:Show()
				else
					_G["SuperTooltip_ZongMenSkill_TalentAttr"..j]:Hide()
				end
			end

		else
			SuperTooltip_ZongMenSkill_TalentAttrFrame:Hide()
		end



		if nZhiZunEquipType == 1 then
			
			SuperTooltip_StaticPart_Title:Hide()
			SuperTooltip_StaticPart_Title1:Show()
			SuperTooltip_StaticPart_Title2:Hide()
			SuperTooltip_StaticPart_Title1:SetText(SuperTooltips:GetTitle())
			
			SuperTooltip_StaticPart_Animate:Show()
			SuperTooltip_StaticPart_Animate:SetProperty("Animate" , "ZhiZun_Flash_Small")
			
		elseif nZhiZunEquipType == 2 then
		
			SuperTooltip_StaticPart_Title:Hide()
			SuperTooltip_StaticPart_Title1:Hide()
			SuperTooltip_StaticPart_Title2:Show()
			SuperTooltip_StaticPart_Title2:SetText(SuperTooltips:GetTitle())
			
			SuperTooltip_StaticPart_Animate:Show()
			SuperTooltip_StaticPart_Animate:SetProperty("Animate" , "SuperEquip_Big")

		else
			
			SuperTooltip_StaticPart_Title:Show()
			SuperTooltip_StaticPart_Title1:Hide()
			SuperTooltip_StaticPart_Title2:Hide()
			SuperTooltip_StaticPart_Animate:Hide()
			
		end

		-- 显示雕纹
		local dwIcon = SuperTooltips:GetDiaowenIcon()
		if (dwIcon ~= nil and dwIcon ~= "") then
			SuperTooltip_StaticPart_DW:Show()
			SuperTooltip_StaticPart_DW:SetProperty("Image", dwIcon)
		end
		
		-- 显示雕纹2
		local dwIconEx = SuperTooltips:GetDiaowenIconEx()
		if (dwIconEx ~= nil and dwIconEx ~= "") then
			SuperTooltip_StaticPart_DW1:Show()
			SuperTooltip_StaticPart_DW1:SetProperty("Image", dwIconEx)
		end
		
		if (IsProtectd == "1" and unLockingElapsedTime ~= 0) then		
			local strLeftTime = g_GetUnlockingStr(unLockingElapsedTime);		
			SuperTooltip_UnlockingTimePart:SetText("#b#cFFFF00"..strLeftTime);
			SuperTooltip_StaticPart_Icon_Protected : SetProperty("Image","set:CommonFrame6 image:NewLock");
		else
			SuperTooltip_UnlockingTimePart:SetText("");
			SuperTooltip_StaticPart_Icon_Protected : SetProperty("Image","set:UIIcons image:Icon_Lock");
		end
		
		if nGoodsProtect == 1 then
			if(nBieYeFurniture1 == nil or nBieYeFurniture1 == '') then	
				SuperTooltip_Protect_Text:SetText("#{GDWPBH_090507_4}")
			else
				SuperTooltip_BieYeFurniture_Protect_Text:SetText("#{GDWPBH_090507_4}")
			end
		else
			SuperTooltip_Protect_Text:SetText("")
			SuperTooltip_BieYeFurniture_Protect_Text:SetText("")
		end
		
		if nEquipMasterFlag == 1 then
			SuperTooltip_BaiBingJingTong_Text:SetText(nEquiMasterText)
		else
			SuperTooltip_BaiBingJingTong_Text:SetText("")
		end
		
		--百兽精通
		local nIsBaiShou = Pet:GetIsBaiShou()
		if nIsBaiShou == 1 then
			SuperTooltip_BaishouJingTong_Text : SetText(nBaiShouLevelText)
		else
			SuperTooltip_BaishouJingTong_Text : SetText("")
		end

		--tongxi modify 显示星星

		local qual =SuperTooltips:GetEquipQual();
		if(type(qual) == "number" and tonumber(qual)>0)then

			local nByQual = tonumber(qual);
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
			SuperTooltip_StaticPart_Icon_Protected:Show();
		end;
		--modify end
		if( type(nGemHoleCounts) == "number" and nGemHoleCounts>0) then

			if(nGemHoleCounts > 0) then 
				SuperTooltip_StaticPart_Gem1:Show();
			end
			
			if(nGemHoleCounts > 1) then 
				SuperTooltip_StaticPart_Gem2:Show();
			end
			
			if(nGemHoleCounts > 2) then 
				SuperTooltip_StaticPart_Gem3:Show();
			end
			
			if(nGemHoleCounts > 3) then 
				SuperTooltip_StaticPart_Gem4:Show();
			end
			
			
			local gemIcon = SuperTooltips:GetGemIcon1();

			if(gemIcon ~= "") then
				SuperTooltip_StaticPart_Gem1:SetProperty("ShortImage", gemIcon);
			end
			
			gemIcon = SuperTooltips:GetGemIcon2();

			if(gemIcon ~= "") then
				SuperTooltip_StaticPart_Gem2:SetProperty("ShortImage", gemIcon);
			end
			
			gemIcon = SuperTooltips:GetGemIcon3();

			if(gemIcon ~= "") then
				SuperTooltip_StaticPart_Gem3:SetProperty("ShortImage", gemIcon);
			end
			
			gemIcon = SuperTooltips:GetGemIcon4();
			

			if(gemIcon ~= "") then
				SuperTooltip_StaticPart_Gem4:SetProperty("ShortImage", gemIcon);
			end
			
		end

		if(nMoney1 ~= nil)  then
			if(szMoneyDesc1 ~= nil)  then
				SuperTooltip_StaticPart_Money_Text:SetText(szMoneyDesc1);
			end
			SetupMoneyPart(1,nMoney1);			
		end		
		if(nMoney2 ~= nil)  then
			if(szMoneyDesc2 ~= nil)  then
				SuperTooltip_StaticPart_Money_Text_2:SetText(szMoneyDesc2);
			end
			SetupMoneyPart(2,nMoney2);
		end
		
		if( szPropertys ~= nil) then
			SuperTooltip_Property:SetText(szPropertys);
		end
		
		if(szAuthor ~= nil) then
            if sweetWordsID > 0 then
                local len = string.len( szAuthor ) - 8
                if len == nil or len > 14 or len <= 0 then
                    len = 14
                end
                local spaceStr = g_supertooltip_space_num[len].spaceStr
                local sweetWords = g_supertooltip_sweet_words[ tonumber( sweetWordsID ) ].sweetWords
                if sweetWords ~= nil and sweetWords ~= "" then
                    if szPropertys ~= nil then
                        SuperTooltip_Property:SetText(szPropertys.."#{MYJS_120723_25}\n"..sweetWords..spaceStr..szAuthor );
                    else
                        SuperTooltip_Property:SetText(             "#{MYJS_120723_25}\n"..sweetWords..spaceStr..szAuthor );
                    end
                end                
            else
    			SuperTooltip_Manufacturer:SetText(szAuthor);
            end
		end
		--百兽精通
		local nIsZhenShouDan = SuperTooltips:GetTypeIsZhenShouDan()
		local nIsBaiShou = Pet:GetIsBaiShou()
		if nIsZhenShouDan == 1 and nIsBaiShou == 1 then
			szExplain = szExplain.."\n".."#{BSJT_130114_07}"
		end
		SuperTooltip_Explain:SetText(szExplain);
		
		SuperTooltip_Armor:SetText(szExplainExtra)

		return 1;
		
end

-------------------------------------------------------------------------------------------------------------------------------
--
-- 清空显示文本
--
function SuperTooltip_ClearText()
		SuperTooltip_StaticPart_Title:SetText("");
		SuperTooltip_StaticPart_Item1:SetText("");
		SuperTooltip_StaticPart_Item2:SetText("");
		SuperTooltip_StaticPart_Item3:SetText("");
		SuperTooltip_StaticPart_Item4:SetText("");
		SuperTooltip_StaticPart_Item6:SetText("");
		SuperTooltip_Protect_Text:SetText("");
		SuperTooltip_BieYeFurniture_Protect_Text:SetText("");
		SuperTooltip_StaticPart_DW:SetImage("")
		SuperTooltip_StaticPart_DW:Hide()
		SuperTooltip_StaticPart_DW1:SetImage("")
		SuperTooltip_StaticPart_DW1:Hide()
		g_FitTitle:Hide()	--	契合度
		g_FitTxt:Hide()		--	契合度
		g_Fit9Title:Hide()	--	契合度
		g_Fit9Txt:Hide()		--	契合度
		local starNum=9
		for i=1,starNum do
			g_Stars[i]:Hide();
		end;
		SuperTooltip_StaticPart_Gem1:SetImage("");
		SuperTooltip_StaticPart_Gem2:SetImage("");
		SuperTooltip_StaticPart_Gem3:SetImage("");
		SuperTooltip_StaticPart_Gem4:SetImage("");
		SuperTooltip_StaticPart_Gem1:Hide();
		SuperTooltip_StaticPart_Gem2:Hide()
		SuperTooltip_StaticPart_Gem3:Hide()
		SuperTooltip_StaticPart_Gem4:Hide()
		SuperTooltip_Explain:SetText("");
		SuperTooltip_Property:SetText("");
		SuperTooltip_Manufacturer:SetText("");
		SuperTooltip_StaticPart_Icon_Protected:Hide();
		SuperTooltip_BaiBingJingTong_Text:SetText("");
		
		SuperTooltip_BieYeFurniture_Text1:SetText("");
		--SuperTooltip_BieYeFurniture_Text2:SetText("");
		--SuperTooltip_BieYeFurniture_Text3:SetText("");
end

function SetupMoneyPart(type,nPrice)
	local StaticPart_GB_Ctl;
	local StaticPart_Money_Ctl;
		--使用什么作为货币
	local nUnit =  SuperTooltips:GetMoney1Type();
	if(type==1)then
		StaticPart_GB_Ctl = SuperTooltip_StaticPart_GB;
		local isShowJiaoZi = SuperTooltips:GetIsShowJiaoZi();
		if ( CU_MONEYJZ == nUnit ) then
			isShowJiaoZi = 1;
		end
		if (isShowJiaoZi == 1) then
			SuperTooltip_StaticPart_Money:Hide();
			StaticPart_Money_Ctl = SuperTooltip_StaticPart_Money_JiaoZi;
		else
			SuperTooltip_StaticPart_Money_JiaoZi:Hide()
			StaticPart_Money_Ctl = SuperTooltip_StaticPart_Money;
		end
	else
		StaticPart_GB_Ctl = SuperTooltip_StaticPart_GB_2;
		StaticPart_Money_Ctl = SuperTooltip_StaticPart_Money_2;
	end

	if(nUnit==nil)then
		nUnit = CU_MONEY;
	end;

	if(CU_MONEY	== nUnit or CU_TICKET == nUnit or CU_MONEYJZ == nUnit)       then      --钱，官票钱, 交子
			StaticPart_GB_Ctl:Hide()
			StaticPart_Money_Ctl:Show();
			StaticPart_Money_Ctl:SetProperty("MoneyNumber", tostring(nPrice));

	elseif(CU_GOODBAD == nUnit) then			--善恶值
			
			StaticPart_GB_Ctl:Show()
			StaticPart_Money_Ctl:Hide();
			StaticPart_GB_Ctl:SetText("善恶值:" .. tostring(nPrice) .. " 点")


	elseif(CU_MORALPOINT == nUnit)  then	--师德点

			StaticPart_GB_Ctl:Show()
			SuperTooltip_StaticPart_Money:Hide();
			StaticPart_GB_Ctl:SetText("师德点:" .. tostring(nPrice) .. " 点")

	elseif(CU_BIND_YUANBAO == nUnit) then	--绑定元宝

			StaticPart_GB_Ctl:Show()
			StaticPart_Money_Ctl:Hide();
			StaticPart_GB_Ctl:SetText("#{BDYB_090714_01}" .. tostring(nPrice))
			
	elseif(CU_GIFTTOKEN == nUnit) then	--返券

			StaticPart_GB_Ctl:Show()
			StaticPart_Money_Ctl:Hide();
			StaticPart_GB_Ctl:SetText("#{YBFQ_XML_1}" .. tostring(nPrice))

	elseif(CU_YUANBAO == nUnit) then	--元宝

			StaticPart_GB_Ctl:Show()
			StaticPart_Money_Ctl:Hide();
			StaticPart_GB_Ctl:SetText("元宝：" .. tostring(nPrice))

	elseif(CU_ZENGDIAN == nUnit) then	--赠点

			StaticPart_GB_Ctl:Show()
			StaticPart_Money_Ctl:Hide();
			StaticPart_GB_Ctl:SetText("赠点:" .. tostring(nPrice))

	elseif(CU_MENPAI_POINT == nUnit) then	--师门贡献度

			StaticPart_GB_Ctl:Show()
			StaticPart_Money_Ctl:Hide();
			StaticPart_GB_Ctl:SetText("门派贡献度:" .. tostring(nPrice))

	elseif(CU_LIJIN == nUnit) then	--礼金

			StaticPart_GB_Ctl:Show()
			StaticPart_Money_Ctl:Hide();
			StaticPart_GB_Ctl:SetText("#{LJSD_120508_38}" .. tostring(nPrice))

	elseif (CU_BWHONOURVALUE == nUnit) then
		StaticPart_GB_Ctl:Show()
		StaticPart_Money_Ctl:Hide();
		local HonourValueTips=ScriptGlobal_Format("#{XBWDH_130521_27}",nPrice)
		StaticPart_GB_Ctl:SetText(HonourValueTips)
	end	
	
end;

function SuperTooltip_OnHide()
	g_left = 0;
	g_top  = 0;
	g_right = 0;
	g_bottom = 0;
	g_mCmpWndCount = 0;
	SuperTooltips:CloseCmpWindowMain()
	SuperTooltips:CloseCmpWindowSub()
end
