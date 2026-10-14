-- [代币商店] 

---------------------------------------------------------------------------
local g_Controls = {};									-- 控件
local g_TableSel = 1;									-- 标签页(默认选中1)
local g_BuyConfirm = 1;									-- 购买确认
local g_NpcObjId = 0;									-- NpcId
local g_MaxDuanWei = 6;								    -- 10个段位
local g_MaxGoodsNum = 10;                               -- 单页最大商品个数
local g_DuanWeiName = {
	"#{DWSD_180817_5}",
	"#{DWSD_180817_6}",
	"#{DWSD_180817_7}",
	"#{DWSD_180817_8}",
	"#{DWSD_180817_9}",
	"#{DWSD_180817_10}",
};
local g_DengJiDuanName = {
	"#{DWSD_210908_01}",
	"#{DWSD_180817_12}",
	"#{DWSD_180817_13}",
	"#{DWSD_180817_14}",
};
local g_SaveIndex = {}

local g_Position = "{{0.500000,-330.000000},{0.500000,-226.000000}}";

local g_Q3Flag = 1
local g_Daibi = 0
---------------------------------------------------------------------------


--*********************************
-- PreLoad
--*********************************
function BW_DaibiShop_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND
	this : RegisterEvent( "OPEN_BWDAIBISHOP" );
	this : RegisterEvent( "UPDATE_BWDAIBISHOPINFO" );
	this : RegisterEvent( "UPDATE_YUANBAO" , false);				-- 元宝		
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" , false);		-- 游戏分辨率发生了变化
	this : RegisterEvent( "GAMELOGIN_SELECTCHARACTER" );	-- 选择人物
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED" , false);		-- 离开场景
	this : RegisterEvent("OBJECT_CARED_EVENT",false);
end


--*********************************
-- OnLoad
--*********************************
function BW_DaibiShop_OnLoad()
	g_Controls = {
		-- 框架
		Framework = BW_DaibiShop_Frame;
		-- 标签页
		Table = {
			[1] = BW_DaibiShop_Qingtong;
			[2] = BW_DaibiShop_Baiyin;
			[3] = BW_DaibiShop_Huangjin;
			[4] = BW_DaibiShop_Bojin;
			[5] = BW_DaibiShop_Zuanshi;
			[6] = BW_DaibiShop_Wangzhe;
		};
		TableTips = {
			[1] = BW_DaibiShop_QingtongTips;
			[2] = BW_DaibiShop_BaiyinTips;
			[3] = BW_DaibiShop_HuangjinTips;
			[4] = BW_DaibiShop_BojinTips;
			[5] = BW_DaibiShop_ZuanshiTips;
			[6] = BW_DaibiShop_WangzheTips;
		};
		-- 介绍
		Introduce = BW_DaibiShop_Bk_Explain1;
		-- 购买确认
		BuyConfirm = {
			BackGround = BW_DaibiShop_Goumaiqueren;
			CheckButton = BW_DaibiShop_querengoumaiBind;
		};
		-- 拥有的代币元宝
		Daibi = BW_DaibiShop_Text1;
		Yuanbao = BW_DaibiShop_Text2;

		-- 物品
		ItemInfo = {
			-- 图标
			ActiveButton = {
				[1] = BW_DaibiShop_Item1,
				[2] = BW_DaibiShop_Item2,
				[3] = BW_DaibiShop_Item3,
				[4] = BW_DaibiShop_Item4,
				[5] = BW_DaibiShop_Item5,
				[6] = BW_DaibiShop_Item6,
				[7] = BW_DaibiShop_Item7,
				[8] = BW_DaibiShop_Item8,
				[9] = BW_DaibiShop_Item9,
				[10] = BW_DaibiShop_Item10,
			};
			-- 数量
			Num = {
				[1] = BW_DaibiShop_Item1_text,
				[2] = BW_DaibiShop_Item2_text,
				[3] = BW_DaibiShop_Item3_text,
				[4] = BW_DaibiShop_Item4_text,
				[5] = BW_DaibiShop_Item5_text,
				[6] = BW_DaibiShop_Item6_text,
				[7] = BW_DaibiShop_Item7_text,
				[8] = BW_DaibiShop_Item8_text,
				[9] = BW_DaibiShop_Item9_text,
				[10] = BW_DaibiShop_Item10_text,
			};

			Duidie = {
				[1] = BW_DaibiShop_Item1_text1,
				[2] = BW_DaibiShop_Item2_text1,
				[3] = BW_DaibiShop_Item3_text1,
				[4] = BW_DaibiShop_Item4_text1,
				[5] = BW_DaibiShop_Item5_text1,
				[6] = BW_DaibiShop_Item6_text1,
				[7] = BW_DaibiShop_Item7_text1,
				[8] = BW_DaibiShop_Item8_text1,
				[9] = BW_DaibiShop_Item9_text1,
				[10] = BW_DaibiShop_Item10_text1,
			};
			-- 蒙红
			Mask = {
				[1] = BW_DaibiShop_Item1_Mask,
				[2] = BW_DaibiShop_Item2_Mask,
				[3] = BW_DaibiShop_Item3_Mask,
				[4] = BW_DaibiShop_Item4_Mask,
				[5] = BW_DaibiShop_Item5_Mask,
				[6] = BW_DaibiShop_Item6_Mask,
				[7] = BW_DaibiShop_Item7_Mask,
				[8] = BW_DaibiShop_Item8_Mask,
				[9] = BW_DaibiShop_Item9_Mask,
				[10] = BW_DaibiShop_Item10_Mask,
			};
			--折扣
			Discount = {
				[1] = BW_DaibiShop_ItemInfo1_DiscountBK,
				[2] = BW_DaibiShop_ItemInfo2_DiscountBK,
				[3] = BW_DaibiShop_ItemInfo3_DiscountBK,
				[4] = BW_DaibiShop_ItemInfo4_DiscountBK,
				[5] = BW_DaibiShop_ItemInfo5_DiscountBK,
				[6] = BW_DaibiShop_ItemInfo6_DiscountBK,
				[7] = BW_DaibiShop_ItemInfo7_DiscountBK,
				[8] = BW_DaibiShop_ItemInfo8_DiscountBK,
				[9] = BW_DaibiShop_ItemInfo9_DiscountBK,
				[10] = BW_DaibiShop_ItemInfo10_DiscountBK,
			};
			-- 
			DiscountText = {
				[1] = BW_DaibiShop_text1,
				[2] = BW_DaibiShop_text2,
				[3] = BW_DaibiShop_text3,
				[4] = BW_DaibiShop_text4,
				[5] = BW_DaibiShop_text5,
				[6] = BW_DaibiShop_text6,
				[7] = BW_DaibiShop_text7,
				[8] = BW_DaibiShop_text8,
				[9] = BW_DaibiShop_text9,
				[10] = BW_DaibiShop_text10,
			};
			-- 物品名称
			ItemName = {
				[1] = BW_DaibiShop_ItemInfo1_Name,
				[2] = BW_DaibiShop_ItemInfo2_Name,
				[3] = BW_DaibiShop_ItemInfo3_Name,
				[4] = BW_DaibiShop_ItemInfo4_Name,
				[5] = BW_DaibiShop_ItemInfo5_Name,
				[6] = BW_DaibiShop_ItemInfo6_Name,
				[7] = BW_DaibiShop_ItemInfo7_Name,
				[8] = BW_DaibiShop_ItemInfo8_Name,
				[9] = BW_DaibiShop_ItemInfo9_Name,
				[10] = BW_DaibiShop_ItemInfo10_Name,
			};
			-- 代币价格
			DaiBiPrice = {
				[1] = BW_DaibiShop_ItemInfo1_Text,
				[2] = BW_DaibiShop_ItemInfo2_Text,
				[3] = BW_DaibiShop_ItemInfo3_Text,
				[4] = BW_DaibiShop_ItemInfo4_Text,
				[5] = BW_DaibiShop_ItemInfo5_Text,
				[6] = BW_DaibiShop_ItemInfo6_Text,
				[7] = BW_DaibiShop_ItemInfo7_Text,
				[8] = BW_DaibiShop_ItemInfo8_Text,
				[9] = BW_DaibiShop_ItemInfo9_Text,
				[10] = BW_DaibiShop_ItemInfo10_Text,
			};
			-- 元宝价格
			YuanBaoPrice = {
				[1] = BW_DaibiShop_ItemInfo1_Text1,
				[2] = BW_DaibiShop_ItemInfo2_Text1,
				[3] = BW_DaibiShop_ItemInfo3_Text1,
				[4] = BW_DaibiShop_ItemInfo4_Text1,
				[5] = BW_DaibiShop_ItemInfo5_Text1,
				[6] = BW_DaibiShop_ItemInfo6_Text1,
				[7] = BW_DaibiShop_ItemInfo7_Text1,
				[8] = BW_DaibiShop_ItemInfo8_Text1,
				[9] = BW_DaibiShop_ItemInfo9_Text1,
				[10] = BW_DaibiShop_ItemInfo10_Text1,
			};
			--全服限购当前剩余
			AllServerLeft = {
				[1] = BW_DaibiShop_ItemInfo1_Text2,
				[2] = BW_DaibiShop_ItemInfo2_Text2,
				[3] = BW_DaibiShop_ItemInfo3_Text2,
				[4] = BW_DaibiShop_ItemInfo4_Text2,
				[5] = BW_DaibiShop_ItemInfo5_Text2,
				[6] = BW_DaibiShop_ItemInfo6_Text2,
				[7] = BW_DaibiShop_ItemInfo7_Text2,
				[8] = BW_DaibiShop_ItemInfo8_Text2,
				[9] = BW_DaibiShop_ItemInfo9_Text2,
				[10] = BW_DaibiShop_ItemInfo10_Text2,
			};
			ItemTips = {
				[1] = BW_DaibiShop_Item1_Tips,
				[2] = BW_DaibiShop_Item2_Tips,
				[3] = BW_DaibiShop_Item3_Tips,
				[4] = BW_DaibiShop_Item4_Tips,
				[5] = BW_DaibiShop_Item5_Tips,
				[6] = BW_DaibiShop_Item6_Tips,
				[7] = BW_DaibiShop_Item7_Tips,
				[8] = BW_DaibiShop_Item8_Tips,
				[9] = BW_DaibiShop_Item9_Tips,
				[10] = BW_DaibiShop_Item10_Tips,
			};
			EyeSign = {
                [1] = BW_DaibiShop_Item1_EyeSign,
				[2] = BW_DaibiShop_Item2_EyeSign,
				[3] = BW_DaibiShop_Item3_EyeSign,
				[4] = BW_DaibiShop_Item4_EyeSign,
				[5] = BW_DaibiShop_Item5_EyeSign,
				[6] = BW_DaibiShop_Item6_EyeSign,
				[7] = BW_DaibiShop_Item7_EyeSign,
				[8] = BW_DaibiShop_Item8_EyeSign,
				[9] = BW_DaibiShop_Item9_EyeSign,
				[10] = BW_DaibiShop_Item10_EyeSign,
			};
		};
	};
end


--*********************************
-- OnEvent
--*********************************
function BW_DaibiShop_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 892899) then
		-- 打开UI
		local opt = tonumber(Get_XParam_INT(0));
		if (opt == 1) then
			-- 关心NPC
		    --g_TableSel = tonumber( Get_XParam_INT(2)) --当前玩家段位
			g_TableSel = 6
			g_Daibi = tonumber( Get_XParam_INT(3))
			g_NpcObjId = Target:GetServerId2ClientId(tonumber(Get_XParam_INT(1)));
			this:CareObject(g_NpcObjId, 1, "BW_DaibiShop");
		elseif (opt == 3) then
			if (not this:IsVisible()) then
				return
			end
			g_Daibi = tonumber( Get_XParam_INT(1))
		else
			BW_DaibiShop_OnHide()
		end

	elseif (event == "OPEN_BWDAIBISHOP") then
		--g_TableSel = Player:Lua_GetXbwData_2018("CuruanWei1")
		g_TableSel = 6
		BW_DaibiShop_OnUpdateDaiBiShop();
		this:Show();
	elseif (event == "UPDATE_BWDAIBISHOPINFO") then
		if (this:IsVisible()) then
			BW_DaibiShop_OnUpdateDaiBiShop();
		end
	elseif ( event == "UPDATE_YUANBAO" ) then
		if ( this:IsVisible() ) then
			BW_DaibiShop_OnUpdateDaiBiShop();
		end
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 恢复默认位置
		g_Controls.Framework:SetProperty( "UnifiedPosition", g_Position );
	elseif ( event == "GAMELOGIN_SELECTCHARACTER" ) then
		-- 恢复默认值
		g_BuyConfirm = 1;
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		BW_DaibiShop_OnHide()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_NpcObjId) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			BW_DaibiShop_OnHide()
			
		end			
	end
end


--*********************************
-- 清空控件
--*********************************
function BW_DaibiShop_CleanupUIControls()
	SetDefaultMouse()

	-- 标签页
	for i = 1, g_MaxDuanWei do
		g_Controls.Table[i]:Show()
		g_Controls.TableTips[i]:SetToolTip("")
		g_Controls.Table[i]:Enable()
		g_Controls.TableTips[i]:Enable();
		if g_TableSel == i then
			g_Controls.Table[i]:SetCheck(1)
		else
			g_Controls.Table[i]:SetCheck(0)
		end
	end
	-- 介绍
	g_Controls.Introduce:SetText("")
	-- 购买确认
	g_Controls.BuyConfirm.BackGround:Show()
	g_Controls.BuyConfirm.CheckButton:SetCheck(g_BuyConfirm)
	-- 物品
	for	i = 1, table.getn(g_Controls.ItemInfo.ActiveButton) do
		g_Controls.ItemInfo.ActiveButton[i]:Enable()
		g_Controls.ItemInfo.ActiveButton[i]:SetActionItem(-1)
		g_Controls.ItemInfo.Num[i]:SetText("")
		g_Controls.ItemInfo.Discount[i]:Hide()
		g_Controls.ItemInfo.Mask[i]:Hide()
		g_Controls.ItemInfo.ItemName[i]:SetText("")
		g_Controls.ItemInfo.DaiBiPrice[i]:SetText("")
		g_Controls.ItemInfo.YuanBaoPrice[i]:SetText("")
		g_Controls.ItemInfo.DiscountText[i]:SetText("")
		g_Controls.ItemInfo.Duidie[i]:SetText("")
		g_Controls.ItemInfo.AllServerLeft[i]:SetText("")
		g_Controls.ItemInfo.ItemTips[i]:Hide()
		g_Controls.ItemInfo.ItemTips[i]:SetToolTip("")
		g_Controls.ItemInfo.EyeSign[i]:Hide()
	end
	--介绍
	g_Controls.Introduce:SetText("")
	--持有元宝 和代币
	g_Controls.Yuanbao:SetText("")
	g_Controls.Daibi:SetText("")
	--清空索引
	g_SaveIndex = nil

	BW_DaibiShop_Goumaiqueren:Hide()
end


--*********************************
-- 显示[代币商店]
--*********************************
function BW_DaibiShop_OnUpdateDaiBiShop()
	-- 清空控件
	BW_DaibiShop_CleanupUIControls()
	-- 段位数据
	--local nDuanwei2 = Player:Lua_GetXbwData_2018( "LevelIndex" ) + 1 --所在等级段
	--local nDuanwei = Player:Lua_GetXbwSeasonHighDuanWei_2018(1, nDuanwei2 - 1, 0) --段位
	
	--local nYuanbao = Player:GetData("YUANBAO")
	local nDaibi = g_Daibi
	-- 标签页
	--if g_TableSel > nDuanwei then
		--g_TableSel = nDuanwei
		--return
	--end
	if g_Q3Flag == 1 then
		g_TableSel = 6
	end
	--介绍
	--local maxLevelIndex = BWDH2018:GetMaxLevelIndex()
	--if nDuanwei2 < 1 or nDuanwei2 > maxLevelIndex then
		--PushDebugMessage("11111")
		--return
	--end
	--local nDuanweiName = g_DengJiDuanName[nDuanwei2]
	local nIntroduce = "#{DWSD_180817_16}"
	g_Controls.Introduce:SetText(nIntroduce)
	--设置分页可用不可用
	--for i = 1, g_MaxDuanWei do
		--if i > nDuanwei then
			--g_Controls.Table[i]:Disable()
			--if i == 1 then
			--	local tips = ScriptGlobal_Format("#{DWSD_180817_11}", nDuanweiName, g_DuanWeiName[i])
			--	g_Controls.TableTips[i]:SetToolTip(tips)
			--elseif i == 2 then
			--	local tips = ScriptGlobal_Format("#{DWSD_180817_11}", nDuanweiName, g_DuanWeiName[i])
			--	g_Controls.TableTips[i]:SetToolTip(tips)
			--elseif i == 3 then
			--	local tips = ScriptGlobal_Format("#{DWSD_180817_11}", nDuanweiName, g_DuanWeiName[i])
			--	g_Controls.TableTips[i]:SetToolTip(tips)
			--elseif i == 4 then
			--	local tips = ScriptGlobal_Format("#{DWSD_180817_11}", nDuanweiName, g_DuanWeiName[i])
			--	g_Controls.TableTips[i]:SetToolTip(tips)
			--elseif i == 5 then
			--	local tips = ScriptGlobal_Format("#{DWSD_180817_11}", nDuanweiName, g_DuanWeiName[i])
			--	g_Controls.TableTips[i]:SetToolTip(tips)
			--elseif i == 6 then
			--	local tips = ScriptGlobal_Format("#{DWSD_180817_11}", nDuanweiName, g_DuanWeiName[i])
			--	g_Controls.TableTips[i]:SetToolTip(tips)
			--end
		--else
			--g_Controls.Table[i]:Enable()
			--g_Controls.TableTips[i]:Disable();
		--end
	--end
	--持有元宝 和代币
	--g_Controls.Yuanbao:SetText(ScriptGlobal_Format("#{DWSD_180817_21}", nYuanbao))
	g_Controls.Daibi:SetText(ScriptGlobal_Format("#{DWSD_180817_22}", nDaibi))
	--设置物品
	--获得此分页物品数量

	--设置只开放制定分页
	if g_Q3Flag == 1 then
		BW_DaibiShop_SpecialOpenLimit(6)
	end
	
	local nGoodsNum = BWDH2018:GetShopItemCount(g_TableSel)
	for i = 1, g_MaxGoodsNum do
		local nSpecialNum = BWDH2018:GetBWDaiBiShopInfo(i, g_TableSel, "special")
		if nSpecialNum > -1 then
			--全服限购 -1表示不是特殊商品 
			--BW_DaibiShop_ShowSpecialItem(i,nDuanwei2)
		else
			--local theAction = BWDH2018:EnumBWDaiBiShop(i, g_TableSel);
			local nItemid= BWDH2018:GetBWDaiBiShopInfo(i, g_TableSel, "itemid")
			local theAction = DataPool:CreateBindActionItemForShow(nItemid, 1)
			if (theAction:GetID() ~= 0) then

				local nRemainNum = BWDH2018:GetBWDaiBiShopInfo(i, g_TableSel, "remainnum")
				local nPrice = BWDH2018:GetBWDaiBiShopInfo(i, g_TableSel, "price")
				local nYuanbaoPrice = BWDH2018:GetBWDaiBiShopInfo(i, g_TableSel, "yuanbao")
				local nDaibiPrice = BWDH2018:GetBWDaiBiShopInfo(i, g_TableSel, "daibi")
				local nNeedDuanwei2 = BWDH2018:GetBWDaiBiShopInfo(i, g_TableSel, "needlevel")
				local nDuidie = BWDH2018:GetBWDaiBiShopInfo(i, g_TableSel, "duidie")
				g_Controls.ItemInfo.ItemTips[i]:SetToolTip("")
				--道具图标
				g_Controls.ItemInfo.ActiveButton[i]:SetActionItem(theAction:GetID())
				--道具名称
				g_Controls.ItemInfo.ItemName[i]:SetText("#cfff263"..theAction:GetName())
				
				if nRemainNum > 1 then
					--g_Controls.ItemInfo.Duidie[i]:SetText(nRemainNum)
					g_Controls.ItemInfo.Num[i]:SetText("#e000001"..nRemainNum)
				end
				--蒙红 等级不够
				--if nDuanwei2 < nNeedDuanwei2 then
				--	g_Controls.ItemInfo.Mask[i]:Show()
				--	g_Controls.ItemInfo.ActiveButton[i]:Disable()
				--	local text = ScriptGlobal_Format("#{DWSD_180817_43}", g_DengJiDuanName[nNeedDuanwei2])
				--	g_Controls.ItemInfo.ItemTips[i]:Show()
				--	g_Controls.ItemInfo.ItemTips[i]:SetToolTip(text)
				--else
				--	g_Controls.ItemInfo.Mask[i]:Hide()
				--end

				--蒙红 等级够了 段位不够
				--if nDuanwei < g_TableSel then
				--	g_Controls.ItemInfo.Mask[i]:Show()
				--	g_Controls.ItemInfo.ActiveButton[i]:Disable()
				--	local text = ScriptGlobal_Format("#{DWSD_180817_43}", g_DengJiDuanName[nNeedDuanwei2])
				--	g_Controls.ItemInfo.ItemTips[i]:Show()
				--	g_Controls.ItemInfo.ItemTips[i]:SetToolTip(text)
				--else
					g_Controls.ItemInfo.Mask[i]:Hide()
				--end

				if nRemainNum <= 0 then
					g_Controls.ItemInfo.Mask[i]:Show()
					g_Controls.ItemInfo.Discount[i]:Hide()
					g_Controls.ItemInfo.DaiBiPrice[i]:SetText("")
					g_Controls.ItemInfo.YuanBaoPrice[i]:SetText("")
					g_Controls.ItemInfo.Duidie[i]:SetText("")
					g_Controls.ItemInfo.DaiBiPrice[i]:SetText(ScriptGlobal_Format("#{DWSD_180817_18}", nDaibiPrice))
				else
					if nDaibiPrice == 0 then
						g_Controls.ItemInfo.Discount[i]:Hide()
					else
						if nYuanbaoPrice <= 0 then --不消耗元宝的时候不显示折扣
							g_Controls.ItemInfo.Discount[i]:Hide()
							g_Controls.ItemInfo.DaiBiPrice[i]:SetText(ScriptGlobal_Format("#{DWSD_180817_18}", nDaibiPrice))
							g_Controls.ItemInfo.YuanBaoPrice[i]:SetText("")
						else
							local nDis = (nYuanbaoPrice/nPrice) * 10   --for example nDis = 9.82134
							local strDis = string.format("%.1f", tostring(nDis)) --strDis = 9.8
							nDis = tonumber(strDis)-- nDis = 9.8
							local nMod = math.mod(nDis*10, 10) -- 98mod10
							if nMod == 0 and nDis < 10 then
								g_Controls.ItemInfo.Discount[i]:Show()
								g_Controls.ItemInfo.DiscountText[i]:SetText(ScriptGlobal_Format("#{DWSD_180817_17}", math.ceil(nDis)))
							elseif nMod ~= 0 and nDis < 10 then
								g_Controls.ItemInfo.Discount[i]:Show()
								g_Controls.ItemInfo.DiscountText[i]:SetText(ScriptGlobal_Format("#{DWSD_180817_17}", nDis))
							end
							g_Controls.ItemInfo.DaiBiPrice[i]:SetText("")
							local price = ScriptGlobal_Format("#{DWSD_180817_19}", nYuanbaoPrice, nDaibiPrice)
							g_Controls.ItemInfo.YuanBaoPrice[i]:SetText(price)
						end
					end
				end
				if i == 2 then
					g_Controls.ItemInfo.EyeSign[i]:Show()
				end
				g_SaveIndex[i] = BWDH2018:GetBWDaiBiShopInfo(i, g_TableSel, "tableIndex")
			else
				g_Controls.ItemInfo.ActiveButton[i]:SetActionItem(-1)
				g_Controls.ItemInfo.Num[i]:SetText("")
				g_Controls.ItemInfo.Discount[i]:Hide()
				g_Controls.ItemInfo.Mask[i]:Hide()
				g_Controls.ItemInfo.ItemName[i]:SetText("")
				g_Controls.ItemInfo.DaiBiPrice[i]:SetText("")
				g_Controls.ItemInfo.YuanBaoPrice[i]:SetText("")
				g_Controls.ItemInfo.DiscountText[i]:SetText("")
				g_Controls.ItemInfo.Duidie[i]:SetText("")
				g_Controls.ItemInfo.ItemTips[i]:SetToolTip("")
			end
		end
	end
	
end

--*********************************
-- 购买
--*********************************
function BW_DaibiShop_BuyItem(uiPos)
	--
	if ( uiPos <= 0 or uiPos > g_MaxGoodsNum ) then
		return
	end
	local theAction = BWDH2018:EnumBWDaiBiShop(uiPos, g_TableSel);
	if (theAction:GetID() ~= 0) then
		g_BuyConfirm = 1
		-- 购买确认
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("BuyInBWShop")
			Set_XSCRIPT_ScriptID(892899)
			Set_XSCRIPT_Parameter(0, g_SaveIndex[uiPos]);  --物品在表里的id（从1开始）		
			Set_XSCRIPT_Parameter(1, g_BuyConfirm); --是否需要弹二次确认（0-不要 1-要）					
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
	end

end


--*********************************
-- 标签页
--*********************************
function BW_DaibiShop_ButtonFenYe_Click(nIndex)
	--
	if (g_TableSel == nIndex) then
		return
	end
	--
	local nDuanwei = Player:Lua_GetXbwData_2018("CuruanWei1")
	
	if (nIndex < 1 or nIndex > nDuanwei) then
		local nDuanweiName  = g_DengJiDuanName[nIndex]
		local text = ScriptGlobal_Format("#{DWSD_180817_15}", nDuanweiName, g_DuanWeiName[nIndex])
		SetNotifyTip(text)
		return
	end
	g_TableSel = nIndex
	BW_DaibiShop_OnUpdateDaiBiShop()
end

--*********************************
-- 购买确认
--*********************************
function BW_DaibiShopBuyConfirm_Clicked()
	-- 购买确认
	local bConfirm = g_Controls.BuyConfirm.CheckButton:GetCheck()
	if (bConfirm == 1) then
		g_BuyConfirm = 0
	elseif (bConfirm == 0) then
		g_BuyConfirm = 1
	end
end

--用于只开放某个页签
function BW_DaibiShop_SpecialOpenLimit(duanwei)

	if duanwei > g_MaxDuanWei then
		return
	end

	for i = 1 , g_MaxDuanWei do
		g_Controls.Table[i]:Hide()
		g_Controls.TableTips[i]:SetText("")
	end
end

function BW_DaibiShop_ShowSpecialItem(index, nDuanwei2)
	local nDuanwei = Player:Lua_GetXbwSeasonHighDuanWei_2018(1, nDuanwei2 - 1, 0)
	
	local theAction = BWDH2018:EnumBWDaiBiShop(index, g_TableSel);
	if (theAction:GetID() ~= 0) then
		local nRemainNum = BWDH2018:GetBWDaiBiShopInfo(index, g_TableSel, "remainnum")
		local nPrice = BWDH2018:GetBWDaiBiShopInfo(index, g_TableSel, "price")
		local nYuanbaoPrice = BWDH2018:GetBWDaiBiShopInfo(index, g_TableSel, "yuanbao")
		local nDaibiPrice = BWDH2018:GetBWDaiBiShopInfo(index, g_TableSel, "daibi")
		local nNeedDuanwei2 = BWDH2018:GetBWDaiBiShopInfo(index, g_TableSel, "needlevel")
		local nDuidie = BWDH2018:GetBWDaiBiShopInfo(index, g_TableSel, "duidie")
		local nSpecialNum = BWDH2018:GetBWDaiBiShopInfo(index, g_TableSel, "special")
		g_Controls.ItemInfo.ItemTips[index]:SetToolTip("")
		--道具图标
		g_Controls.ItemInfo.ActiveButton[index]:SetActionItem(theAction:GetID())
		--道具名称
		g_Controls.ItemInfo.ItemName[index]:SetText("#cfff263"..theAction:GetName())
				
		if nDuidie > 1 then
			g_Controls.ItemInfo.Duidie[index]:SetText(nDuidie)
		end
		--打折标签和蒙红
		if nDuanwei2 < nNeedDuanwei2 then
			g_Controls.ItemInfo.Mask[index]:Show()
			g_Controls.ItemInfo.ActiveButton[index]:Disable()
			local text = ScriptGlobal_Format("#{DWSD_180817_43}", g_DengJiDuanName[nNeedDuanwei2])
			g_Controls.ItemInfo.ItemTips[index]:Show()
			g_Controls.ItemInfo.ItemTips[index]:SetToolTip(text)
		else
			g_Controls.ItemInfo.Mask[index]:Hide()
		end
		--打折标签和蒙红
		if nDuanwei < g_TableSel then
			g_Controls.ItemInfo.Mask[index]:Show()
			g_Controls.ItemInfo.ActiveButton[index]:Disable()
			local text = ScriptGlobal_Format("#{DWSD_180817_43}", g_DengJiDuanName[nNeedDuanwei2])
			g_Controls.ItemInfo.ItemTips[index]:Show()
			g_Controls.ItemInfo.ItemTips[index]:SetToolTip(text)
		else
			g_Controls.ItemInfo.Mask[index]:Hide()
		end

		if nRemainNum <= 0 or nSpecialNum <= 0 then
			g_Controls.ItemInfo.Mask[index]:Show()
			g_Controls.ItemInfo.Discount[index]:Hide()
			g_Controls.ItemInfo.DaiBiPrice[index]:SetText("")
			g_Controls.ItemInfo.YuanBaoPrice[index]:SetText("")
			g_Controls.ItemInfo.Duidie[index]:SetText("")
			local text
			if nSpecialNum <= 0 then
				text = ScriptGlobal_Format("#{DWSD_180817_42}", "#cFF0000"..tostring(0))
			else
				text = ScriptGlobal_Format("#{DWSD_180817_42}", nSpecialNum)
			end
			g_Controls.ItemInfo.AllServerLeft[index]:SetText(text)
		else
			g_Controls.ItemInfo.Discount[index]:Hide()
			if nYuanbaoPrice == 0 then --不消耗元宝的时候不显示折扣
				g_Controls.ItemInfo.DaiBiPrice[index]:SetText(ScriptGlobal_Format("#{DWSD_180817_18}", nDaibiPrice))
				g_Controls.ItemInfo.YuanBaoPrice[index]:SetText("")
			else
				local nDis = (nYuanbaoPrice/nPrice) * 10   --for example nDis = 9.82134
				local strDis = string.format("%.1f", tostring(nDis)) --strDis = 9.8
				nDis = tonumber(strDis)-- nDis = 9.8
				local nMod = math.mod(nDis*10, 10) -- 98mod10
				if nMod == 0 and nDis < 10 then
					g_Controls.ItemInfo.Discount[index]:Show()
					g_Controls.ItemInfo.DiscountText[index]:SetText(ScriptGlobal_Format("#{DWSD_180817_17}", math.ceil(nDis)))
				elseif nMod ~= 0 and nDis < 10 then
					g_Controls.ItemInfo.Discount[index]:Show()
					g_Controls.ItemInfo.DiscountText[index]:SetText(ScriptGlobal_Format("#{DWSD_180817_17}", nDis))
				end
				g_Controls.ItemInfo.DaiBiPrice[index]:SetText("")
				local price = ScriptGlobal_Format("#{DWSD_180817_19}", nYuanbaoPrice, nDaibiPrice)
				g_Controls.ItemInfo.YuanBaoPrice[index]:SetText(price)
			end
			local text = ScriptGlobal_Format("#{DWSD_180817_42}", nSpecialNum)
			g_Controls.ItemInfo.AllServerLeft[index]:SetText(text)
		end

		g_SaveIndex[index] = BWDH2018:GetBWDaiBiShopInfo(index, g_TableSel, "tableIndex")
	else
		g_Controls.ItemInfo.ActiveButton[index]:SetActionItem(-1)
		g_Controls.ItemInfo.Num[index]:SetText("")
		g_Controls.ItemInfo.Discount[index]:Hide()
		g_Controls.ItemInfo.Mask[index]:Hide()
		g_Controls.ItemInfo.ItemName[index]:SetText("")
		g_Controls.ItemInfo.DaiBiPrice[index]:SetText("")
		g_Controls.ItemInfo.YuanBaoPrice[index]:SetText("")
		g_Controls.ItemInfo.DiscountText[index]:SetText("")
		g_Controls.ItemInfo.Duidie[index]:SetText("")
		g_Controls.ItemInfo.ItemTips[index]:SetToolTip("")
	end
end

function BW_DaibiShop_OnView()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		--Set_XSCRIPT_Parameter(0, 10126466) 
		--Set_XSCRIPT_Parameter(1, 123)
		--Set_XSCRIPT_Parameter(2, 91)
		Set_XSCRIPT_Parameter(0, 10127775)
		Set_XSCRIPT_Parameter(1, -1)--hair
		Set_XSCRIPT_Parameter(2, -1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function BW_DaibiShop_OnHide()
	this:CareObject(g_NpcObjId, 0, "BW_DaibiShop");
	this:Hide();
	g_NpcObjId = -1
end