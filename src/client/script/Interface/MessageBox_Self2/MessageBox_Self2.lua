-- 一个特殊的MessageBox，目前只用在绑定元宝购买时绑定元宝不足的确认

local g_EnvName = "";
local g_iYesNoType = -1
local g_item = -1
local g_itemNum = -1
local g_pos = -1
--付费商店改造
local g_bFromRecentBooth = 0
--附体还原二次确认
local g_PetPoss_ScriptID = 0
local g_PetPoss_ModelTypeId = 0


--	K世界重建限制
local Changyige_password;
local Changyige_money;
local g_DianCangLiHeParam0=-1
local g_DianCangLiHeParam1=-1
local g_DWChaiJie_BagPos=-1
local g_GemLevelupInfo={-1,-1,-1}

local Guard_Data = {}		--镖行天下数据

local RunHunShiCompound_Data = {0,0,0,0}		--润魂石合成数据
local CaiLiaoCompound_Data = {0,0,0,0}			--三精材料合成数据

local Guard_NeedYuanBao=500

local g_Server_Script_Function = "";
local g_Server_Script_ID = "";
local g_Server_Return_1 = 0;
local g_Server_Return_2 = 0;
local g_RobbagIndex = -1

local g_Brother_Scritp_Function = ""
local g_Brother_Script_ID = ""
local g_Brother_Return_1 = 0
local g_Brother_Return_2 = 0
local g_Brother_Return_3 = 0

local g_PneumaBoxBagpos=-1
local g_PneumaBoxSelectIndex=-1

local g_TServerBuyImpact={-1,-1,-1}

local g_MessageBoxSelf2_Data={0,0,0,0}

--新手欢乐月 英雄百宝囊
local g_HeroBabBagIndex = -1  
local g_HeroBabBag ={ 
	[1] = {  PriCost = 150,  Discount = "6" },				--英雄百宝囊
	[2] = {  PriCost = 656,  Discount = "6" },
	[3] = {  PriCost = 960,  Discount = "6" },
	[4] = {  PriCost = 1600, Discount = "6" },
	[5] = {  PriCost = 1720, Discount = "6" },
	[6] = {  PriCost = 1840, Discount = "6" },		 
}  
 
local g_PrenticeGUID = ""
local g_PrenticeIndex = -1
 
local g_FairShopType = -1;
local g_FairShopindex = -1;
local g_FairShopindex2 = -1;
local g_FairShopshowid = -1;
local g_FairShopitemIdx = -1;

local g_itemidx = -1;
local g_targetId = -1;

function MessageBox_Self2_PreLoad()
	this:RegisterEvent("BINDYUANBAO_NOTENOUGH_YESNO")

	this:RegisterEvent("UPDATE_LW_LEVELUP_CONFIRM")
	this:RegisterEvent("UPDATE_LW_BIND_CONFIRM")
	--战队二次确认的
	--1、解散
	this:RegisterEvent("DISMISS_CORPS")
	--2、踢人
	this:RegisterEvent("CORPS_KICK_MEMBER")
	--3、离开队伍
	this:RegisterEvent("CORPS_MEMBER_LEAVE")
	--4、邀请加入
	this:RegisterEvent("CORPS_INVITE_CONFIRM")

	this:RegisterEvent("PETPOSSHUANYUAN_CONFIRM") --附体还原二次确认
	this:RegisterEvent("COMMON_MSGBOX_NOTICE")	--通用提示框，只有提示的作用
	this:RegisterEvent("EQUIPSTRENGTH_QUICK_CONFIRM") --装备自动强化二次确认
	--this:RegisterEvent("CHANGYIGE_CHECK_CONFIRM") --畅易阁身份验证二次确认
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("RELIVE_SHOW",false);
	this:RegisterEvent("LOSER_SATISFACTION_CONFIRM") --被盗恢复满意度页面二次确认
	this:RegisterEvent("CHANGE_CLIENT_CONFIRM")  --切换客户端
	this:RegisterEvent("MESSSAGEBOX2_SURE")
	this:RegisterEvent("JIANIANHUA_DIANCANGLIHE_SELECTCONFIRM")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("SURE_GEM_LEVELUP")
	this:RegisterEvent("MESSSAGEBOX_PNEUMABOX_SURE")
	this:RegisterEvent("BINDSURE_EQUIPDWLEVELUP")
	this:RegisterEvent("CONSUMESURE_EQUIPDWLEVELUP")
	this:RegisterEvent("OPEN_FIREDUP_CONFIRM")
--	this:RegisterEvent("MAKESURE_COMPEMARRY_ENGAGE")
	this:RegisterEvent("PNEUMA_QUICKONCENY_QR")

	--战队二次确认 2018
	this:RegisterEvent("DISMISS_CORPS_2018")
	this:RegisterEvent("CORPS_KICK_MEMBER_2018")
	this:RegisterEvent("CORPS_MEMBER_LEAVE_2018")
	this:RegisterEvent("CORPS_INVITE_CONFIRM_2018")
	this:RegisterEvent("CORPS_INVITE_CANCLECHOOSEMP_2018")
	this:RegisterEvent("NATIOANALDAY_YUANBAO_CONFIRM")
	this:RegisterEvent("TRADE_CONFIRM")
	
	--T服比武大会 战队二次确认的
	--1、解散
	this:RegisterEvent("TXBW_WTEAM_DISMISS")
	--2、踢人
	this:RegisterEvent("TXBW_WTEAM_KICK_MEMBER")
	--3、离开队伍
	this:RegisterEvent("TXBW_WTEAM_MEMBER_LEAVE")
	this:RegisterEvent("BIEYEFURNITUREREMOVECOMFIRM")
	
	--鉴定绑定状态确认
	this:RegisterEvent("IDENTIFY_BIND_RECONFIRM")
	this:RegisterEvent("PET_CHANGEMODEL_CONFIRM")
	this:RegisterEvent("SKILLCARD_RECYCLE_CONFIRM")
	this:RegisterEvent("GIFTEXCHANGESHOP_CONFIRM")
	
	--巅峰赛 战队二次确认的
	--1、解散
	this:RegisterEvent("DFS_WTEAM_DISMISS")
	--2、踢人
	this:RegisterEvent("DFS_WTEAM_KICK_MEMBER")
	--3、离开队伍
	this:RegisterEvent("DFS_WTEAM_MEMBER_LEAVE")
	this:RegisterEvent("DFS_WTEAM_ASK_INVITE")
	
	--时装衣柜界面关闭二次确认	
	this:RegisterEvent("EXTERIOR_FASHION_CONFIRM")
	this:RegisterEvent("EXTERIOR_INFANT_CONFIRM")
	this:RegisterEvent("CLOSE_EXTERIOR_YIRONGGE")

	this:RegisterEvent("GOUWUCHE_SUBMIT")
	this:RegisterEvent("CONFIRM_FENGMINGSHOP_BUY")
	this:RegisterEvent("WEGAME_FORCEQUIT")
	
	this:RegisterEvent("TRANSFORM_FASHION_CONFIRM")
	this:RegisterEvent("SAVE_SHARESTYLE_CONFIRM")

	this:RegisterEvent("ZONGMEN_SHOPINFO_CONFIRM")

	this:RegisterEvent("QM8X_CLOSE_CHANGEUI")

	this:RegisterEvent("SECT_SAVEPLAN_CONFIRM")
	this:RegisterEvent("SECT_LEAVE_WITHOUT_SAVE")

	this:RegisterEvent("EXCHANGE_OPTIMIZATION")
	this:RegisterEvent("EXCHANGE_OPTIMIZATION_MONEY")
	this:RegisterEvent("FENGYUN_YURE_CLOSE_CONFIRM")
	this:RegisterEvent("GUILD_ZHANTUAN_OP_UPDATE")
	
end

function MessageBox_Self2_OnLoad()
end

function MessageBox_Self2_OnEvent(event)
	
	if (event == "BINDYUANBAO_NOTENOUGH_YESNO" ) then
		g_iYesNoType = tonumber(arg0)
		g_item 		 = tonumber(arg1)
		g_itemNum 	 = tonumber(arg2)
		local nNeedBindYuanbao = tonumber(arg3)
		nNeedBindYuanbao = nNeedBindYuanbao * g_itemNum
		g_pos = tonumber(arg4)
		local name = arg6
		g_bFromRecentBooth = tonumber(arg5)
		local nHaveBindYuanbao = Player : GetData( "BIND_YUANBAO" )
		local nCostYuanbao = nNeedBindYuanbao - nHaveBindYuanbao
		MessageBox_Self2_Text:SetText("#{BDYB_XML_1}#G".."" ..name .."#{BDYB_XML_2}#G"..nNeedBindYuanbao.."#{BDYB_XML_3}#G"..nHaveBindYuanbao.."#{BDYB_XML_4}#G"..nCostYuanbao.."#{BDYB_XML_5}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UPDATE_LW_LEVELUP_CONFIRM" ) then
		g_iYesNoType = 3
		local str = "#{LW_KVK_110704_61}"
		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UPDATE_LW_BIND_CONFIRM" ) then
		g_iYesNoType = 4
		local str = tostring(arg0)
		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif ( event == "DISMISS_CORPS" ) then
		g_iYesNoType = 6
		--您确定要解散您的战队么？
		MessageBox_Self2_Text:SetText("#{ZBS16_160526_133}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "CORPS_KICK_MEMBER") then
		g_iYesNoType = 7
		if tonumber(arg0) == 0 then
			--由于踢出这名队员后，会造成由于战队人数少于5人而被系统强制解散战队。你确定仍要继续将AAA请离战队么？
			local str = ScriptGlobal_Format("#{ZBS16_160511_97}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)--#{ZBS_GZ_120221_93}
		else
			--你确定要将AAA请离战队么？
			local str = ScriptGlobal_Format("#{ZBS16_160511_101}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		end
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "CORPS_MEMBER_LEAVE") then
		g_iYesNoType = 8
		if tonumber(arg0) == 0 then
			--由于您的退出，会造成战队人数少于7人而被系统强制解散战队。你确定仍要离开战队么？
			--注：离开后将会同时解散战队。
			MessageBox_Self2_Text:SetText("#{ZBS16_160511_107}")
		else
			--你确定要退出XXXX战队么？
			local str = ScriptGlobal_Format("#{ZBS16_160511_110}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		end
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();

	elseif (event == "PETPOSSHUANYUAN_CONFIRM") then
		g_iYesNoType = 9
		g_PetPoss_ScriptID = tonumber(arg1)
		g_PetPoss_ModelTypeId = tonumber(arg2)

		local str = ScriptGlobal_Format("#{FTHS_120719_35}",tostring(arg3))
		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "COMMON_MSGBOX_NOTICE" ) then
		g_iYesNoType = 10
		local str = tostring(arg0)
		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Hide();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "EQUIPSTRENGTH_QUICK_CONFIRM" ) then
		g_iYesNoType = 11
		local str = "#{ZDQH_161107_04}"
		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();

	--elseif (event == "CHANGYIGE_CHECK_CONFIRM") then
		--g_iYesNoType = 14
		--Changyige_password = tostring(arg0)
		--local Changyige_charname = tostring(arg1)
		--Changyige_money = tostring(arg2)
		--local strCYG = ScriptGlobal_Format("#{CYG_130527_87}",Changyige_charname,Changyige_money)
		--MessageBox_Self2_Text:SetText(strCYG)
		--MessageBox_Self2_OK_Button:Show()
		--MessageBox_Self2_Cancel_Button:Show()
		--MessageBox_Self2_UpdateRect()
		--this:Show();

	--elseif (event == "UI_COMMAND") and (arg0 == "201306051") then
	--	g_iYesNoType = 13
	--	MessageBox_Self2_Text:SetText("#{CYG_130527_98}")
	--	MessageBox_Self2_OK_Button:Show()
	--	MessageBox_Self2_Cancel_Button:Show()
	--	MessageBox_Self2_UpdateRect()
	--	this:Show()
	elseif (event=="HIDE_ON_SCENE_TRANSED") then
		if g_iYesNoType == 17 then
			this:Hide()
		end
		
		if g_iYesNoType == 70 or g_iYesNoType == 71 then
			this:Hide()
		end
		
		if g_iYesNoType == 129 or g_iYesNoType == 130 then
			this:Hide()
		end
		
		if g_iYesNoType == 137 or g_iYesNoType == 138 or g_iYesNoType == 140 or g_iYesNoType == 141 or 
		   g_iYesNoType == 142 or g_iYesNoType == 145 or g_iYesNoType == 146 or g_iYesNoType == 155 or 
		   g_iYesNoType == 156 or g_iYesNoType == 157 or g_iYesNoType == 171 or g_iYesNoType == 207 or
		   g_iYesNoType == 208 or g_iYesNoType == 244 or g_iYesNoType == 291  or g_iYesNoType == 292 then
			this:Hide()
		end	
		
		if  g_iYesNoType == 275 or g_iYesNoType == 274 or g_iYesNoType == 273 or g_iYesNoType == 272 then
			this:Hide()
		end
		
		if g_iYesNoType == 169 then
			this:Hide()
		end
		
		if g_iYesNoType == 170 or g_iYesNoType == 90 or g_iYesNoType == 88 or g_iYesNoType == 89 then
			-- 西瓜节时装商店兑换 增加切场景关闭二次确认界面
			this:Hide()
		end
		if g_iYesNoType == 171 then
			DataPool:SetCanUseHotKey(1)
		end
		
		if g_iYesNoType == 206 then
			DataPool:SetCanUseHotKey(1)
			this:Hide()
		end
		if g_iYesNoType == 181 or g_iYesNoType == 182 then
			this:Hide()
		end
		if g_iYesNoType == 193 or g_iYesNoType == 194 then
			this:Hide()
		end
		if g_iYesNoType == 195 then
			this:Hide()
		end
		if g_iYesNoType == 216 then
			this:Hide()
		end
		if g_iYesNoType == 217 then
			this:Hide()
		end
		if g_iYesNoType == 227 then
			this:Hide()
		end
		if g_iYesNoType == 257 then
			this:Hide()
		end
		if g_iYesNoType == 258 then
			this:Hide()
		end
		if g_iYesNoType == 290 then
			this:Hide()
		end	
		if g_iYesNoType == 301 then
			this:Hide()
		end
		if g_iYesNoType == 294 then
			this:Hide()
		end
		if g_iYesNoType == 295 then
			this:Hide()
		end
		if g_iYesNoType == 325 then
			this:Hide()
		end
	elseif (event=="RELIVE_SHOW") then
		if g_iYesNoType == 155 or g_iYesNoType == 156 or g_iYesNoType == 157 then
			this:Hide()
	 	end	
	elseif event == "LOSER_SATISFACTION_CONFIRM" then
		g_iYesNoType = 17
		MessageBox_Self2_Text:SetText("#{BDZH_130814_2}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif (event == "CHANGE_CLIENT_CONFIRM") then
		local nRet = tonumber(arg0)
		if nRet == 1 then  --可切换经典
			Lua_TDU_Log("Can change to classic ...")
			g_iYesNoType = 19
			MessageBox_Self2_Text:SetText("#{SDQH_130730_8}")
		elseif nRet == 2 then  --不可切换经典
			Lua_TDU_Log("Can’t change to classic ...")
			g_iYesNoType = 20
			MessageBox_Self2_Text:SetText("#{SDQH_130730_6}")
		elseif nRet == 3 then  --可切换唯美
			Lua_TDU_Log("Can change to wm ...")
			g_iYesNoType = 19
			MessageBox_Self2_Text:SetText("#{SDQH_130730_7}")
		elseif nRet == 4 then  --不可切换唯美
			Lua_TDU_Log("Can't change to wm ...")
			g_iYesNoType = 21
			MessageBox_Self2_Text:SetText("#{SDQH_130730_3}")
		else
			return
		end
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif event == "MESSSAGEBOX2_SURE" then
		if tonumber(arg0)>=1 and tonumber(arg0)<=4 then
			g_iYesNoType = 22
			g_DianCangLiHeParam0=tonumber(arg0)
			g_DianCangLiHeParam1=tonumber(arg1)
			local itemID=tonumber(arg2)
			local itemname = PlayerPackage:GetEquipItemName(itemID);

			local str = ScriptGlobal_Format( "#{MDJH_130507_112}",tostring(itemname) )
			MessageBox_Self2_Text:SetText(str)
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		end
	elseif event == "MESSSAGEBOX_PNEUMABOX_SURE" then
		g_PneumaBoxBagpos=tonumber(arg0)
		g_PneumaBoxSelectIndex=tonumber(arg1)
		
		if g_PneumaBoxSelectIndex>=1 and g_PneumaBoxSelectIndex<=4 then
			g_iYesNoType = 30

			local pneumeID=tonumber(arg2)
			local pneumename = PlayerPackage:GetPneumaItemName(pneumeID);
			local itemID=tonumber(arg3)
			local itemname = PlayerPackage:GetItemName(itemID);

			local str = ScriptGlobal_Format( "#{XFXF_140919_101}",tostring(pneumename),tostring(itemname) )
			MessageBox_Self2_Text:SetText(str)
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		end
	--elseif event == "HIDE_ON_SCENE_TRANSED" then
	--	if g_iYesNoType == 17 then
	--		this:Hide()
	--	end
	elseif (event == "UI_COMMAND") and (arg0 == "8092720") then

		g_iYesNoType = 23
		g_DWChaiJie_BagPos=Get_XParam_INT(0)
		local needYB = Get_XParam_INT(1)
		local getJCS = Get_XParam_INT(2)
		local YBSave = getJCS*35
		local itemName = PlayerPackage:GetBagItemName( g_DWChaiJie_BagPos )
		if itemName==nil then
			return
		end
		local thisMsg=ScriptGlobal_Format( "#{DWCJJ_140606_19}", itemName, needYB, getJCS, YBSave)
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif (event == "SURE_GEM_LEVELUP") then--元宝消费确认
		g_iYesNoType = 24
		local str=arg0
		g_GemLevelupInfo[1]=tonumber(arg1)--装备位置
		g_GemLevelupInfo[2]=tonumber(arg2)--宝石索引
		g_GemLevelupInfo[3]=tonumber(arg3)--双属性与否索引

		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "201407301") then
		g_iYesNoType = 25
		if Get_XParam_INT_Count() > 1 then
			local xx = Get_XParam_INT(2);
			ObjCaredID = DataPool : GetNPCIDByServerID(xx);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MessageBox_Self2");
			end
		end
		Guard_Data[1] = Get_XParam_INT(0)
		Guard_Data[2] = Get_XParam_INT(1)
		Guard_Data[3] = Get_XParam_INT(2)
		local strText=""
		local times=Get_XParam_INT(4)
		if Guard_Data[1] == Guard_NeedYuanBao then
			if Get_XParam_INT(3) == 1 then				
				strText=ScriptGlobal_Format("#{BXJH_140815_128}",times,3-times)
			else
				strText=ScriptGlobal_Format("#{BXJH_140815_129}",times,3-times)
			end			
		elseif Guard_Data[1] == 0 then
			if Get_XParam_INT(3) == 1 then
				strText=ScriptGlobal_Format("#{BXJH_140815_124}",times,3-times)
			else
				strText=ScriptGlobal_Format("#{BXJH_140815_125}",times,3-times)
			end	
		else
			if Get_XParam_INT(3) == 1 then
				strText=ScriptGlobal_Format("#{BXJH_140815_126}",times,3-times)
			else
				strText=ScriptGlobal_Format("#{BXJH_140815_127}",times,3-times)
			end	
		end
		MessageBox_Self2_Text:SetText(strText)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "20140917") then --写一个通用型二次提示框吧
		g_iYesNoType = 26
		if Get_XParam_INT_Count() > 1 then
			local xx = Get_XParam_INT(1);
			ObjCaredID = DataPool : GetNPCIDByServerID(xx);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MessageBox_Self2");
			end
		end
		g_Server_Script_Function = Get_XParam_STR(0)
		g_Server_Script_ID = Get_XParam_INT(0)
		g_Server_Return_1 = Get_XParam_INT(1)
		g_Server_Return_2 = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(Get_XParam_STR(1))
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "2014092201") then
		g_RobbagIndex = Get_XParam_INT(0)
		local RobItem = Get_XParam_INT(1)
		if (38001019 == RobItem) then
			g_iYesNoType = 27
		elseif (38001044 == RobItem) then
			g_iYesNoType = 28
		elseif (38001045 == RobItem) then
			g_iYesNoType = 29
		end
		MessageBox_Self2_Text:SetText("#{BXJH_140815_111}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "201411105") then
		g_iYesNoType = 31
		g_TServerBuyImpact[1]=Get_XParam_INT(0)--类型：传送或者购买士气
		g_TServerBuyImpact[2]=Get_XParam_INT(1)--传送何处或者花费何种货币购买士气
		g_TServerBuyImpact[3]=Get_XParam_INT(2)--需求元宝量或者货币需求
		if g_TServerBuyImpact[1]==1 then--元宝买传送
			local tranName={"青龙","白虎","朱雀","玄武","玄素"}--todo 等待字典号 现有的那套字典不大敢用啊
			local targetIdx=g_TServerBuyImpact[2]
			local tips = ""
			--if IsTBFinalServer() >= 1 then
				--TODO,跨服战总决赛特殊服务器需要使用"战场元宝",需要新配字典
				--tips = ScriptGlobal_Format("#{KFZC_150424_30}",g_TServerBuyImpact[3],tranName[targetIdx])--您确定要消耗XX元宝前往YY处么?
			--else	--普通服务器使用通用"元宝"
				tips = ScriptGlobal_Format("#{KFZC_141013_153}",g_TServerBuyImpact[3],tranName[targetIdx])--您确定要消耗XX元宝前往YY处么?
			--end
			MessageBox_Self2_Text:SetText(tips)
		elseif g_TServerBuyImpact[1]==2 then--购买buff
			if g_TServerBuyImpact[2] == 1 then--金币
				local tips = ScriptGlobal_Format("#{KFZC_141013_160}",g_TServerBuyImpact[3])
				MessageBox_Self2_Text:SetText(tips)
			elseif g_TServerBuyImpact[2] == 2 then--战场元宝
				local tips = ScriptGlobal_Format("#{KFZC_141013_168}",g_TServerBuyImpact[3])
				MessageBox_Self2_Text:SetText(tips)
			--elseif	g_TServerBuyImpact[2] == 3 then	--跨服战总决赛,T服消耗战场元宝购买buff
				--local tips = ScriptGlobal_Format("#{KFZC_150424_27}",g_TServerBuyImpact[3])
				--MessageBox_Self2_Text:SetText(tips)
			end
		end

		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "20141124") then
		g_iYesNoType = 32
		MessageBox_Self2_Text:SetText("#{WGFB_141124_1}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Hide()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event=="BINDSURE_EQUIPDWLEVELUP" and tonumber(arg0)==0) then
		g_iYesNoType = 33
		MessageBox_Self2_Text:SetText("#{DWSJ_141202_28}")

		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event=="CONSUMESURE_EQUIPDWLEVELUP") then
		g_iYesNoType = 34
		--PushEvent( "CONSUMESURE_EQUIPDWLEVELUP",g_DWShengji_Item,iToLevelSel,iToLevelSelEx,requireJCS,UserjcsCnt,UserBYBCnt,UserYBCnt)
		g_MessageBoxSelf2_Data[1]=tonumber(arg0)--背包槽位
		g_MessageBoxSelf2_Data[2]=tonumber(arg1)--雕纹1直接升级到
		g_MessageBoxSelf2_Data[3]=tonumber(arg2)--雕纹2直接升级到
		local requireJCS=tonumber(arg3)
		local UserjcsCnt=tonumber(arg4)
		local UserBYBCnt=tonumber(arg5)
		local UserYBCnt=tonumber(arg6)
		--绑定元宝
		if UserBYBCnt>0 and UserYBCnt==0 then
			--本次雕纹升级需要消耗A个金蚕丝，您背包中现有B个未锁定的金蚕丝。点击确定按钮后，将扣除背包内全部未锁定的金蚕丝和C绑定元宝（用来补足剩余的金蚕丝）。点击取消时，将放弃本次升级。
			local tips = ScriptGlobal_Format("#{DWSJ_141202_37}",requireJCS,UserjcsCnt,UserBYBCnt,UserBYBCnt/35)
			MessageBox_Self2_Text:SetText(tips)
		--元宝
		elseif UserBYBCnt==0 and UserYBCnt>0 then
			--本次雕纹升级共需A个金蚕丝，您背包中有B个未锁定的金蚕丝。点击确定按钮后，将扣除背包内全部未锁定的金蚕丝和C元宝（等同于XX个金蚕丝）完成升级。点击取消时，将放弃本次升级操作。
			local tips = ScriptGlobal_Format("#{DWSJ_141202_60}",requireJCS,UserjcsCnt,UserYBCnt,UserYBCnt/35)
			MessageBox_Self2_Text:SetText(tips)
		--绑定元宝+元宝
		else
			local tips = ScriptGlobal_Format("#{DWSJ_141202_38}",requireJCS,UserjcsCnt,UserBYBCnt,UserYBCnt,(UserBYBCnt+UserYBCnt)/35)
			MessageBox_Self2_Text:SetText(tips)
		end

		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88995802") then
		if Get_XParam_INT(0) == 0 then
			g_iYesNoType = 35
			MessageBox_Self2_Text:SetText("#{HCYL_150304_15}")		
		elseif Get_XParam_INT(0) == 1 then 
			g_iYesNoType = 36
			MessageBox_Self2_Text:SetText("#{HCYL_150304_23}")		
		elseif Get_XParam_INT(0) == 2 then
			g_iYesNoType = 48
			--MessageBox_Self2_Text:SetText("#{HCYL_160307_08}")		
			MessageBox_Self2_Text:SetText("#{HCYL_160606_02}")
		end
		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "2015053003") then
		g_iYesNoType = 40
		g_index = Get_XParam_INT(0) 
		--总量
		g_count = Get_XParam_INT(1) 
		g_yuanbao = Get_XParam_INT(2) 
		g_zengsongYB = Get_XParam_INT(3) 
		--购买量
		g_bugnum = Get_XParam_INT(4)
		--赠送量
		g_zengsongnum = Get_XParam_INT(5)
		
		local str = ScriptGlobal_Format("#{KPGM_150529_41}",g_yuanbao,g_bugnum,g_zengsongnum,g_zengsongYB)
		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "20150309") then
		g_iYesNoType = 37
		local nKckType = Get_XParam_INT(0)
		if (1 == nKckType) then
			MessageBox_Self2_Text:SetText("#{JRPL_150310_2}")		
		elseif (2 == nKckType) then
			MessageBox_Self2_Text:SetText("#{JRPL_150310_3}")		
		elseif (3 == nKckType) then
			MessageBox_Self2_Text:SetText("#{JRPL_150310_4}")		
		elseif (4 == nKckType) then
			MessageBox_Self2_Text:SetText("#{JRPL_160722_6}")		
		elseif (5 == nKckType) then		--打架机
			MessageBox_Self2_Text:SetText("#{TXTX_180620_01}")		
		elseif (6 == nKckType) then
			MessageBox_Self2_Text:SetText( ScriptGlobal_Format("#{DJFB_191101_01}", "04") )			
		else 
			MessageBox_Self2_Text:SetText("#{JRPL_150310_3}")		
		end 
		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Hide()
		MessageBox_Self2_UpdateRect()
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "20150528") then
		if Get_XParam_INT(0) == 3 then
			g_iYesNoType = 38
			local nGUID,
			szCharName,
			nType,
			nSex,
			nLevel,
			szGuildName,
			nQinmi,
			nGongfeng,
			nStartDay,
			nIsOnline	= WenDingUI:GetShiMenInfoByIdx( 0 ,1)
			if szCharName == "" then
				szCharName = " "
			end
			MessageBox_Self2_Text:SetText(ScriptGlobal_Format("#{STGZ_150514_34}",szCharName))		
			MessageBox_Self2_OK_Button:Show()
			MessageBox_Self2_Cancel_Button:Show()
			MessageBox_Self2_UpdateRect()
			this:Show();
		elseif Get_XParam_INT(0) == 4 then
			g_PrenticeIndex = Get_XParam_INT(1)
			g_PrenticeGUID = Get_XParam_STR(0)
			if g_PrenticeIndex >=0 and g_PrenticeIndex <= 8 then
				g_iYesNoType = 39
				local nGUID,
				szCharName,
				nType,
				nSex,
				nLevel,
				szGuildName,
				nQinmi,
				nGongfeng,
				nStartDay,
				nIsOnline	= WenDingUI:GetShiMenInfoByIdx( g_PrenticeIndex ,2)
				if g_PrenticeGUID ~= nGUID then
					return
				end
				if szCharName == "" then
					szCharName = " "
				end
				MessageBox_Self2_Text:SetText(ScriptGlobal_Format("#{STGZ_150514_59}",szCharName))		
				MessageBox_Self2_OK_Button:Show()
				MessageBox_Self2_Cancel_Button:Show()
				MessageBox_Self2_UpdateRect()
				this:Show(); 
			end			
		end
	elseif (event == "UI_COMMAND") and (arg0 == "15052710") then 
		g_iYesNoType = 41 
		local needYB = Get_XParam_INT(0)
		g_HeroBabBagIndex = Get_XParam_INT(1) 
		local thisMsg=ScriptGlobal_Format( "#{XSHLY_150522_84}",needYB,g_HeroBabBag[g_HeroBabBagIndex].PriCost )
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "20150626") then
		g_iYesNoType = 42
		g_Brother_Scritp_Function = Get_XParam_STR(0)
		g_Brother_Script_ID = Get_XParam_INT(0)
		g_Brother_Return_1 = Get_XParam_INT(1)
		g_Brother_Return_2 = Get_XParam_INT(2)
		g_Brother_Return_3 = Get_XParam_INT(3)
		MessageBox_Self2_Text:SetText(Get_XParam_STR(1))
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif event == "OPEN_FIREDUP_CONFIRM" then
		g_iYesNoType = 45
		local thisMsg =  "#{MZBUILD_150817_290}"
		local lightedCount = tonumber(arg0)
		if lightedCount == 3 or lightedCount == 4 then
			local SpeedUpRate = ""
			if lightedCount == 3 then
				SpeedUpRate = "20%"
			else	
				SpeedUpRate = "30%"
			end
			thisMsg = ScriptGlobal_Format("#{MZBUILD_150817_287}",tostring(lightedCount),SpeedUpRate)
		elseif lightedCount == 5 then
			thisMsg = "#{MZBUILD_150817_450}"
		end
		
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "20150914") then
		g_iYesNoType = 46
		if Get_XParam_INT_Count() > 1 then
			local xx = Get_XParam_INT(1);
			local targetId = DataPool : GetNPCIDByServerID(xx);
			if targetId ~= -1 then
				--开始关心NPC
				this:CareObject(targetId, 1, "MessageBox_Self2");
			end
		end
		MessageBox_Self2_Text:SetText(Get_XParam_STR(1))
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
		
	elseif (event == "UI_COMMAND") and (arg0 == "20151030") then
		g_iYesNoType = 47
		g_MessageBoxSelf2_Data[1]=Get_XParam_INT(0)--战盟id
		g_MessageBoxSelf2_Data[2]=Get_XParam_INT(1)--帮会id
		g_MessageBoxSelf2_Data[3]=Get_XParam_INT(2)--组号
		MessageBox_Self2_Text:SetText(Get_XParam_STR(1))
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88889901") then
		g_iYesNoType = 48
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then --显示
			MessageBox_Self2_Text:SetText( "#{LJSJ_160308_13}" )
			MessageBox_Self2_OK_Button:Hide()
			MessageBox_Self2_Cancel_Button:Hide()
			MessageBox_Self2_UpdateRect()
			
			SetTimer("MessageBox_Self2", "MessageBox_Self2_CloseDownTick()", 10000)
			this:Show();
		else
			this:Hide();
		end
--	elseif (event == "MAKESURE_COMPEMARRY_ENGAGE") then
--		g_iYesNoType = 50
--		--你正在进行悔婚操作！说明一下悔婚女生“招亲纳贤”BUFF不清，会3天不能再发起。
--		MessageBox_Self2_Text:SetText("#{BWZQ_160623_203}")
--		MessageBox_Self2_OK_Button:Show()
--		MessageBox_Self2_Cancel_Button:Show()
--		MessageBox_Self2_UpdateRect()
--		this:Show();
	elseif (event == "CORPS_INVITE_CONFIRM") then
		g_iYesNoType = 51
		g_PrenticeGUID = arg2
		--AAA邀请您加入BBB战队一起征战《新天龙八部》全球争霸赛，您是否同意加入此战队？
		local str = ScriptGlobal_Format("#{ZBS16_160603_215}", tostring(arg0), tostring(arg1))
		MessageBox_Self2_Text:SetText(str)
		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "2016110702") then
		g_iYesNoType = 52
		if Get_XParam_INT_Count() > 1 then
			local xx = Get_XParam_INT(0);
			ObjCaredID = DataPool : GetNPCIDByServerID(xx);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MessageBox_Self2");
			end
		end
		local data1=Get_XParam_INT(0)
		local data2=Get_XParam_INT(1)
		local data3=Get_XParam_INT(2)
		local data4=Get_XParam_INT(3)
		local strMsg=Get_XParam_STR(0)
		MessageBox_Self2_RunHunShiCompoundConfirm(data1, data2, data3, data4, strMsg)
	elseif (event == "UI_COMMAND") and (arg0 == "50908701") then
		g_iYesNoType = 53
		local nPerson = Get_XParam_INT(0)--1发起者，2获胜者
		g_MessageBoxSelf2_Data[1]=Get_XParam_INT(1)--去处大理苏州or洛阳
		local str={"#{BWZQ_160623_71}","#{BWZQ_160623_69}"}
		if str[nPerson]==nil then return end;
		MessageBox_Self2_Text:SetText( str[nPerson] )
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()

		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "5090881") then
		g_iYesNoType = 54

		local nYB = Get_XParam_INT(0)
		local sponsor_name=Get_XParam_STR(0)
		g_MessageBoxSelf2_Data[1]=Get_XParam_INT(1)
		local str = ScriptGlobal_Format("#{BWZQ_160623_346}", nYB, sponsor_name)

		MessageBox_Self2_Text:SetText( str )
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()

		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "50908501") then
		g_iYesNoType = 55

		g_MessageBoxSelf2_Data[1]=Get_XParam_INT(0)--targetId
		local moneyReq=Get_XParam_INT(1)
		local scnUse=BWDH:GetCompeMarryCurStatus()
		if scnUse==2 then--赛前
			str = ScriptGlobal_Format("#{BWZQ_160623_362}", moneyReq)
		else--3 赛中
			str = ScriptGlobal_Format("#{BWZQ_160623_365}", moneyReq)
		end

		MessageBox_Self2_Text:SetText( str )
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()

		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "33900801") then	--神鼎快捷凝练
		g_iYesNoType = 56

		local nNeedYaoChenValue = Get_XParam_INT(0);
		local nCurYaoChenValue  = Get_XParam_INT(1);
		local nCostYaoChen  = Get_XParam_INT(2);
		local nCostYuanBao  = Get_XParam_INT(3);
		local nA = Get_XParam_INT(4);
		local nB = Get_XParam_INT(5);
		local nC = Get_XParam_INT(6);
		local nD = Get_XParam_INT(7);
		local strItem = ""
		if tonumber(nA) > 0 then
			strItem = ScriptGlobal_Format("#{SDKJ_170518_06}", tostring(nA), "天悔药魂");
		end
		if tonumber(nB) > 0 then
			if strItem ~= "" then
				strItem = strItem.."#{SDKJ_170518_07}";
			end
			
			local strItem2 = ScriptGlobal_Format("#{SDKJ_170518_06}", tostring(nB), "冰髓药灵");
			strItem = strItem..strItem2;
		end
		if tonumber(nC) > 0 then
			if strItem ~= "" then
				strItem = strItem.."#{SDKJ_170518_07}";
			end
			
			local strItem2 = ScriptGlobal_Format("#{SDKJ_170518_06}", tostring(nC), "苍鹤药魄");
			strItem = strItem..strItem2;
		end
		if tonumber(nD) > 0 then
			if strItem ~= "" then
				strItem = strItem.."#{SDKJ_170518_07}";
			end
			
			local strItem2 = ScriptGlobal_Format("#{SDKJ_170518_06}", tostring(nD), "玄机药尘");
			strItem = strItem..strItem2;
		end
		
		local str = ScriptGlobal_Format("#{SDKJ_170518_05}", tostring(nCurYaoChenValue), tostring(nNeedYaoChenValue), tostring(strItem), tostring(nCostYuanBao), tostring(nCostYuanBao) );

		MessageBox_Self2_Text:SetText( str )

		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()

		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "33901101") then	--神鼎快捷凝练
		g_iYesNoType = 57

		local nNeedYaoChenValue = Get_XParam_INT(0);
		local nCurYaoChenValue  = Get_XParam_INT(1);
		local nCostYaoChen  = Get_XParam_INT(2);
		local nCostYuanBao  = Get_XParam_INT(3);
		local nA = Get_XParam_INT(4);
		local nB = Get_XParam_INT(5);
		local nC = Get_XParam_INT(6);
		local nD = Get_XParam_INT(7);
		local strItem = ""
		if tonumber(nA) > 0 then
			strItem = ScriptGlobal_Format("#{SDKJ_170518_06}", tostring(nA), "天悔药魂");
		end
		if tonumber(nB) > 0 then
			if strItem ~= "" then
				strItem = strItem.."#{SDKJ_170518_07}";
			end
			
			local strItem2 = ScriptGlobal_Format("#{SDKJ_170518_06}", tostring(nB), "冰髓药灵");
			strItem = strItem..strItem2;
		end
		if tonumber(nC) > 0 then
			if strItem ~= "" then
				strItem = strItem.."#{SDKJ_170518_07}";
			end
			
			local strItem2 = ScriptGlobal_Format("#{SDKJ_170518_06}", tostring(nC), "苍鹤药魄");
			strItem = strItem..strItem2;
		end
		if tonumber(nD) > 0 then
			if strItem ~= "" then
				strItem = strItem.."#{SDKJ_170518_07}";
			end
			
			local strItem2 = ScriptGlobal_Format("#{SDKJ_170518_06}", tostring(nD), "玄机药尘");
			strItem = strItem..strItem2;
		end
		
		local str = ScriptGlobal_Format("#{SDKJ_170518_05}", tostring(nCurYaoChenValue), tostring(nNeedYaoChenValue), tostring(strItem), tostring(nCostYuanBao), tostring(nCostYuanBao) );

		MessageBox_Self2_Text:SetText( str )
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()

		this:Show();
	elseif (event == "PNEUMA_QUICKONCENY_QR" and tonumber(arg0)==0) then
		g_iYesNoType = 58
		local thisMsg = ScriptGlobal_Format("#{YJNY_170602_08}", tonumber(arg1)*20,tonumber(arg1))
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "920170826") then
		g_iYesNoType = 63
		if Get_XParam_INT_Count() > 1 then
			local xx = Get_XParam_INT(0);
			ObjCaredID = DataPool : GetNPCIDByServerID(xx);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "MessageBox_Self2");
			end
		end
		local data1=Get_XParam_INT(0)
		local data2=Get_XParam_INT(1)
		local data3=Get_XParam_INT(2)
		local data4=Get_XParam_INT(3)
		local strMsg=Get_XParam_STR(0)
		MessageBox_Self2_CaiLiaoCompoundConfirm(data1, data2, data3, data4, strMsg)
	elseif (event == "UI_COMMAND") and (arg0 == "920170917") then
		g_iYesNoType = 64
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89265302") then
		g_iYesNoType = 65
		local strMsg = Get_XParam_STR(0)
		local nFlag = Get_XParam_INT(0)
		g_nTagertid = Get_XParam_INT(1)
		g_nItemflag = Get_XParam_INT(2)
		if nFlag == 2 then
			g_iYesNoType = 66
		end
		if nFlag == 3 then
			g_iYesNoType = 67
		end
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "88927401") then	
		g_iYesNoType = 68
		local strMsg = Get_XParam_STR(0)
		g_nTagertid = Get_XParam_INT(0)
		g_nselfIndex = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	

	elseif (event == "UI_COMMAND") and (arg0 == "20180125") then 
		g_iYesNoType = 69 
		local needYB = Get_XParam_INT(0)
		g_HeroBabBagIndex = Get_XParam_INT(1) 
		local thisMsg=ScriptGlobal_Format( "#{XSJNH_180111_151}",needYB,g_HeroBabBag[g_HeroBabBagIndex].PriCost )
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "89265601") then 
		g_nTagertid = Get_XParam_INT(0)
		if 1 == Get_XParam_INT(1) then
			g_iYesNoType = 70
		elseif 2 == Get_XParam_INT(1) then
			g_iYesNoType = 71
		end
		ObjCaredID = DataPool : GetNPCIDByServerID(g_nTagertid);
		if ObjCaredID ~= -1 then
			--开始关心NPC
			this:CareObject(ObjCaredID, 1, "MessageBox_Self2");
		end
		local MsgStr = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(MsgStr)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "892707") then		
		local str = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(str)
		
		g_nItemId = Get_XParam_INT(0) 
		g_nTagertid = Get_XParam_INT(1)
		g_nIndex = Get_XParam_INT(2)
		
		--g_nIndex从1开始 到79
		g_iYesNoType = 71 + g_nIndex
		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();

	elseif ( event == "DISMISS_CORPS_2018" ) then
		g_iYesNoType = 80
		--您确定要解散您的战队么？
		MessageBox_Self2_Text:SetText("#{WCBZ_180128_197}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	--2018
	elseif (event == "CORPS_KICK_MEMBER_2018") then
		g_iYesNoType = 81
		if tonumber(arg0) == 0 then
			--你确定要将%s0请离战队吗？请离此名成员后，本战队的成员数量将不足7人，会被系统强制解散。如若确认，点击确定后即可解散战队；点击取消则可放弃本次操作。
			local str = ScriptGlobal_Format("#{WCBZ_180128_161}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		else
			--你确定要将AAA请离战队么？
			local str = ScriptGlobal_Format("#{WCBZ_180128_165}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		end
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "CORPS_MEMBER_LEAVE_2018") then
		g_iYesNoType = 82
		if tonumber(arg0) == 0 then
			--由于您的退出，会造成战队人数少于7人而被系统强制解散战队。你确定仍要离开战队么？
			--注：离开后将会同时解散战队。
			MessageBox_Self2_Text:SetText("#{WCBZ_180128_171}")
		else
			--你确定要退出XXXX战队么？
			local str = ScriptGlobal_Format("#{WCBZ_180128_174}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		end
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "CORPS_INVITE_CONFIRM_2018") then
		g_iYesNoType = 83
		--AAA邀请您加入BBB战队一起征战《新天龙八部》全球争霸赛，您是否同意加入此战队？
		local str = ScriptGlobal_Format("#{WCBZ_180128_123}", tostring(arg0), tostring(arg1))
		MessageBox_Self2_Text:SetText(str)
		g_PrenticeGUID = arg2
		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "CORPS_INVITE_CANCLECHOOSEMP_2018") then
		g_iYesNoType = 84
		g_PrenticeGUID = tostring(arg0) 
		--您尚未为新成员选择目标门派，若现在关闭界面，邀请成员加入战队将不成功。点击确认将关闭选择门派界面，终止邀请成员；点击取消则继续。
		MessageBox_Self2_Text:SetText("#{WCBZ_180128_131}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();	
		
	elseif (event == "UI_COMMAND") and (arg0 == "89281001") then	
		g_iYesNoType = 85
		local strMsg = Get_XParam_STR(0)
		g_nnumText = Get_XParam_INT(0)
		g_nTagertid = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
		
	elseif (event == "UI_COMMAND") and (arg0 == "892851") then	
		g_iYesNoType = 86
		local strMsg 				= Get_XParam_STR(0)
		g_nTagertid 		= Get_XParam_INT(0)
		g_nnumText		= Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89286801") then	
		g_iYesNoType = 87
		local strMsg = Get_XParam_STR(0)
		g_nbagIndex = Get_XParam_INT(0)
		g_nTagertid = Get_XParam_INT(1)
		g_nScriptid = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89286902") then	
		g_iYesNoType = 88
		local strMsg = Get_XParam_STR(0)
		g_nFlag = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89286903") then	
		g_iYesNoType = 89
		local strMsg = Get_XParam_STR(0)
		g_nFlag = Get_XParam_INT(0)
		g_nIdx = Get_XParam_INT(1)
		g_nItemIdx = Get_XParam_INT(2)
		g_nItemId = Get_XParam_INT(3)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89286905") then	
		g_iYesNoType = 90
		local strMsg = Get_XParam_STR(0)
		g_nFlag = Get_XParam_INT(0)
		g_nIsWeaponOrFashion = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89288104") then	
		g_iYesNoType = 91 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		g_MessageBoxSelf2_Data[4] = Get_XParam_INT(3)
		local strMsg = Get_XParam_STR(0)
		
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	
	
	elseif  (event == "UI_COMMAND") and (arg0 == "89292602") then		--绣春刀联动时装返场券
		g_iYesNoType = 92
		local thisMsg 							= Get_XParam_STR(0);  
		g_MessageBoxSelf2_Data[1] 	= Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	
	elseif  (event == "UI_COMMAND") and (arg0 == "89292701") then		--绣春刀联动时装返场券
		g_iYesNoType = 93
		local thisMsg 							= Get_XParam_STR(0);  
		g_MessageBoxSelf2_Data[1] 	= Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89292105") then	
		g_iYesNoType = 94
		local strMsg = Get_XParam_STR(0)
		g_nFlag = Get_XParam_INT(0)
		g_nIdx = Get_XParam_INT(1)
		g_nItemIdx = Get_XParam_INT(2)
		g_nItemId = Get_XParam_INT(3)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89292104") then	
		g_iYesNoType = 95
		local strMsg = Get_XParam_STR(0)
		g_nFlag = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();		 
	elseif (event == "UI_COMMAND") and (arg0 == "89291203") then	
		g_iYesNoType = 96
		local strMsg 				= Get_XParam_STR(0)
		g_Server_Script_Function = Get_XParam_STR(1)
		g_MessageBoxSelf2_Data[1]  		= Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] 		= Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show(); 
	elseif (event == "NATIOANALDAY_YUANBAO_CONFIRM") then
		g_iYesNoType = 97
		local strMsg = tostring(arg0)  
		g_MessageBoxSelf2_Data[1]  = tonumber(arg1)  
		g_MessageBoxSelf2_Data[2]  = tonumber(arg2)  
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();	 
	elseif (event == "UI_COMMAND") and (arg0 == "89291204") then	
		g_iYesNoType = 97
		local strMsg 				= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1]  		= Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] 		= Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "89293902") then	
		g_iYesNoType = 98
		local strMsg 				= Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89293903") then	
		g_iYesNoType = 99
		local strMsg 				= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1]  		= Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89293904") then	
		g_iYesNoType = 100
		local strMsg 				= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1]  		= Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89293905") then	
		g_iYesNoType = 101
		local strMsg 				= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1]  		= Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89293906") then	 
		this:Hide();
	elseif (event == "UI_COMMAND") and (arg0 == "2018111301") then	
		g_iYesNoType = 102
		local strMsg = Get_XParam_STR(0)
		g_nTagertid = Get_XParam_INT(0)
		g_nselfIndex = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();	
	
	elseif ( event == "TXBW_WTEAM_DISMISS" ) then
		g_iYesNoType = 103
		--您确定要解散您的战队么？
		MessageBox_Self2_Text:SetText("#{BWJH_181102_108}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	
	elseif (event == "TXBW_WTEAM_KICK_MEMBER") then
		g_iYesNoType = 104
		if tonumber(arg0) == 0 then
			--您确定要将%s0请离战队吗？请离此成员后，本战队成员数量将不足3人，会被系统强制解散。如果确认，点击确定后即可解散战队；点击取消则可放弃本次操作。
			local str = ScriptGlobal_Format("#{BWJH_181102_97}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		else
			--你确定要将AAA请离战队么？
			local str = ScriptGlobal_Format("#{BWJH_181102_100}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		end
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "TXBW_WTEAM_MEMBER_LEAVE") then
		g_iYesNoType = 105
		if tonumber(arg0) == 0 then
			--由于您的退出，会造成战队人数少于3人而被系统强制解散战队。你确定仍要离开战队么？
			--注：离开后将会同时解散战队。
			local curDay = tonumber(DataPool:GetServerDayTime());
			local nCreateWTeamBegin, nCreateWTeamEnd = BWDH2018:GetTXbwCreateWTeamDate(curDay)
			if nCreateWTeamBegin == nil or nCreateWTeamEnd == nil then
				return
			end
			
			local strCreateWTeamEnd  = BWDH2018:Format_YMD2Str( nCreateWTeamEnd )
			local str = ScriptGlobal_Format("#{BWJH_181102_136}", strCreateWTeamEnd)
			MessageBox_Self2_Text:SetText(str)
		else
			--你确定要退出XXXX战队么？
			local str = ScriptGlobal_Format("#{BWJH_181102_139}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		end
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "20181113") then
		g_iYesNoType = 106
		local szInviteName 	= Get_XParam_STR(0) 
		local szWTeamName 	= Get_XParam_STR(1) 
		--AAA邀请您加入BBB战队一起征战拭剑天下跨服季后赛，您是否同意加入此战队？
		local str = ScriptGlobal_Format("#{BWJH_181102_119}", tostring(szInviteName), tostring(szWTeamName))
		MessageBox_Self2_Text:SetText(str)
		g_PrenticeGUID = Get_XParam_STR(2) 
		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif ( event == "EXCHANGE_OPTIMIZATION" and tonumber(arg0) == 0 ) or ( event == "EXCHANGE_OPTIMIZATION_MONEY" and tonumber(arg0) == 2 ) then
		MessageBox_Self2_Text:SetText("#{JSJY_240306_1}")
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show()
	end
	
	MessageBox_Self2_OnEventEx(event)
	
end

function MessageBox_Self2_OnEventEx(event)
		
	if (event == "UI_COMMAND") and (arg0 == "89071307") then	
		g_iYesNoType = 107
		local strMsg = Get_XParam_STR(0)
		g_FairShopType = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
		
	elseif (event == "UI_COMMAND") and (arg0 == "89071308") then	
		g_iYesNoType = 108
		local strMsg = Get_XParam_STR(0)
		g_FairShopindex = Get_XParam_INT(0)
		g_FairShopshowid = Get_XParam_INT(1)
		g_FairShopitemIdx = Get_XParam_INT(2)
		g_FairShopindex2 = Get_XParam_INT(3)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89298102") then	
		g_iYesNoType 						 = 109
		local strMsg 							= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89302206") then	
		g_iYesNoType  = 110
		local strMsg = Get_XParam_STR(0)
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		local nYuanXiao = 0 
		if g_MessageBoxSelf2_Data[1] >= 3 and g_MessageBoxSelf2_Data[1] <= 9 then 
			nYuanXiao = 1
		elseif g_MessageBoxSelf2_Data[1] >= 10 and g_MessageBoxSelf2_Data[1] <= 19 then 
			nYuanXiao = 2
		elseif g_MessageBoxSelf2_Data[1] >= 20 and g_MessageBoxSelf2_Data[1] <= 39 then 
			nYuanXiao = 4
		elseif g_MessageBoxSelf2_Data[1] >= 40 and g_MessageBoxSelf2_Data[1] <= 62 then 
			nYuanXiao = 6
		end
		MessageBox_Self2_Text:SetText(ScriptGlobal_Format(strMsg,g_MessageBoxSelf2_Data[1],nYuanXiao))		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "89300802") then--2018Q4春节引导任务--龙凤和鸣礼盒
		g_iYesNoType 						 = 111
		MessageBox_Self2_Text:SetText("#{RACL_181206_556}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "BIEYEFURNITUREREMOVECOMFIRM" ) then
		g_iYesNoType = 113
		local nIndex = tonumber(arg0)
		if nIndex == 1 then
			return
		end
		MessageBox_Self2_Text:SetText("#{BYFUR_170410_318}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event=="IDENTIFY_BIND_RECONFIRM") then
		g_iYesNoType = 112
		g_MessageBoxSelf2_Data[1]=tonumber(arg0)
		g_MessageBoxSelf2_Data[2]=tonumber(arg1)
		MessageBox_Self2_Text:SetText("#{JDXZ_190219_1}")

		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89306501")  then
		g_iYesNoType = 114 
		MessageBox_Self2_Text:SetText("#{LJYX_190318_40}")

		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "8930702") then	
		g_iYesNoType = 115
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(0) --operatorID
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		if g_MessageBoxSelf2_Data[2] == 2 then
			MessageBox_Self2_Cancel_Button:Hide()		
		else
			MessageBox_Self2_Cancel_Button:Show()
		end	
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "8930703") then	
		g_iYesNoType = 116
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Hide()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89305801") then	
		g_iYesNoType 						 = 117
		local strMsg 							= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89305802") then	
		g_iYesNoType 						 = 118
		local strMsg 							= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "5001802") then	
		g_iYesNoType 						 = 119
		local strMsg 							= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 

	elseif (event == "UI_COMMAND") and (arg0 == "89308502") then
		g_iYesNoType 						 = 120
		g_zdzyhidx = Get_XParam_INT(0) 
		if g_zdzyhidx == 1 then
			MessageBox_Self2_Text:SetText("#{ZDZYH_180418_62}")		
		elseif g_zdzyhidx == 2 then
			MessageBox_Self2_Text:SetText("#{ZDZYH_180418_66}")		
		end
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "89306508")  then
		g_iYesNoType = 121
		MessageBox_Self2_Text:SetText("#{DJYB_190404_23}")

		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "19042902")  then
		g_iYesNoType = 122
		g_itemidx = Get_XParam_INT(0) 
		g_targetId = Get_XParam_INT(1) 
		local str = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(str)

		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "50508302")  then
		g_iYesNoType = 123
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) 
		local msg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(msg)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "50508303")  then
		g_iYesNoType = 124
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) 
		local msg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(msg)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "50508304")  then
		g_iYesNoType = 125
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		local msg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(msg)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "893126003") then	
		g_iYesNoType  = 126
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "893126005") then	
		g_iYesNoType  = 127
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) 
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "893126006") then	
		g_iYesNoType  = 128
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) 
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89315101") then 
		g_nTagertid = Get_XParam_INT(0)
		if 1 == Get_XParam_INT(1) then
			g_iYesNoType = 129
		elseif 2 == Get_XParam_INT(1) then
			g_iYesNoType = 130
		end
		ObjCaredID = DataPool : GetNPCIDByServerID(g_nTagertid);
		if ObjCaredID ~= -1 then
			--开始关心NPC
			this:CareObject(ObjCaredID, 1, "MessageBox_Self2");
		end
		local MsgStr = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(MsgStr)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();	

	elseif (event == "UI_COMMAND") and (arg0 == "20190722") then	
		g_iYesNoType  = 131
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) 
		local text = {"#{XSZH_190722_9}", "#{XSZH_190722_10}", "#{XSZH_190722_11}", "#{XSZH_190722_12}"}
		local strMsg = ScriptGlobal_Format("#{XSZH_190722_8}", tostring( g_MessageBoxSelf2_Data[1] ), text[ g_MessageBoxSelf2_Data[2] ])
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89316602") then	
		g_iYesNoType 						 = 132
		local strMsg 						 = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89315803") then	
		g_iYesNoType 	= 133
		local strMsg 	= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89316301") then
		g_iYesNoType = 134
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "79002902") then
		-- 天龙战令
		g_iYesNoType = 135
		local strMsg = Get_XParam_STR(0)
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89315804") then	
		g_iYesNoType 	= 136
		local strMsg 	= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89319501") then
		g_iYesNoType = 137
		g_MessageBoxSelf2_Data[1] = Get_XParam_STR(0) 
		local str = ScriptGlobal_Format("#{JBHL_190803_72}", g_MessageBoxSelf2_Data[1])
		MessageBox_Self2_Text:SetText(str)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89319602") then
		g_iYesNoType = 138
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "79002005") then
		-- 中秋锦鲤 好友传递礼盒
		g_iYesNoType = 139
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89326201") then	
		g_iYesNoType = 140
		local strMsg = Get_XParam_STR(0)
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
		
	elseif (event == "UI_COMMAND") and (arg0 == "20191002") then	
		g_iYesNoType = 141
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		local str = ScriptGlobal_Format("#{THD_190613_84}", g_MessageBoxSelf2_Data[1], g_MessageBoxSelf2_Data[1])
		MessageBox_Self2_Text:SetText(str)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();		
		
	elseif (event == "UI_COMMAND") and (arg0 == "20191011") then	
		g_iYesNoType = 142
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText("#{THD_190613_114}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();


	elseif (event == "UI_COMMAND") and (arg0 == "89335401") then	
		g_iYesNoType = 146
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)	--target
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)	--index
		if g_MessageBoxSelf2_Data[2] == 1 then
			MessageBox_Self2_Text:SetText("#{SYYH_191206_160}")	
		elseif g_MessageBoxSelf2_Data[2] == 2 then
			g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)	--key
			MessageBox_Self2_Text:SetText("#{SYYH_191206_231}")	
		elseif g_MessageBoxSelf2_Data[2] == 3 then
			MessageBox_Self2_Text:SetText("#{FWJH_221115_76}")	
		elseif g_MessageBoxSelf2_Data[2] == 4 then
			MessageBox_Self2_Text:SetText("#{FWJH_221115_83}")	
		end
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "20191213") then	
		g_iYesNoType  = 147
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "89337501") then	
		g_iYesNoType  = 148
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "89337502") then	
		g_iYesNoType  = 149
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "89337503") then	
		g_iYesNoType  = 150
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "89071313") then	
		g_iYesNoType  = 151
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText( strMsg )		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "89339701") then	
		g_iYesNoType  = 152
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) -- bagindex
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) -- targetid
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2) -- script 
		MessageBox_Self2_Text:SetText( strMsg )		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
		
	elseif (event == "UI_COMMAND") and (arg0 == "89340108") then
		g_iYesNoType = 153
		local szStr = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(szStr)
		
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
				
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
		
	elseif (event == "UI_COMMAND") and (arg0 == "89340109") then
		g_iYesNoType = 154
		local szStr = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(szStr)
		
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "2020032601") then	
		g_iYesNoType = 155
		local strMsg = Get_XParam_STR(0)
		g_nbagIndex = Get_XParam_INT(0)
		g_nTagertid = Get_XParam_INT(1)
		g_nScriptid = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "2020032602") then	
		g_iYesNoType = 156
		local strMsg = Get_XParam_STR(0)
		g_nbagIndex = Get_XParam_INT(0)
		g_nTagertid = Get_XParam_INT(1)
		g_nScriptid = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "2020032603") then	
		g_iYesNoType 						 = 157
		local strMsg 							= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
		
	elseif (event == "UI_COMMAND") and (arg0 == "80811008") then
		g_iYesNoType = 158
		local szStr = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(szStr)
		
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif event == "PET_CHANGEMODEL_CONFIRM" then
		g_iYesNoType = 159
		MessageBox_Self2_Text:SetText("#{RXZS_090804_50}")
		g_MessageBoxSelf2_Data[1] = tonumber(arg0)
		g_MessageBoxSelf2_Data[2] = tonumber(arg1)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif event == "SKILLCARD_RECYCLE_CONFIRM" then
		g_iYesNoType = 160		
		g_MessageBoxSelf2_Data[1] = tonumber(arg0)
		MessageBox_Self2_SkillCardRecycle_Confirm()		
		MessageBox_Self2_UpdateRect()
		this:Show()	
		
	elseif (event == "UI_COMMAND") and (arg0 == "89340304") then
		g_iYesNoType = 161
		local szStr = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(szStr)
		
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "2020042701") then
		g_iYesNoType = 162
		local isShow = Get_XParam_INT(0)
		if (isShow > 0) then
			local szStr = Get_XParam_STR(0) 
			MessageBox_Self2_Text:SetText(szStr)

			g_MessageBoxSelf2_Data[1] = Get_XParam_INT(1)
			g_MessageBoxSelf2_Data[2] = Get_XParam_INT(2)
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		else
			this:Hide()
		end
	elseif (event == "UI_COMMAND") and (arg0 == "2020042702") then
		g_iYesNoType = 163
		local isShow = Get_XParam_INT(0)
		if (isShow > 0) then
			local szStr = Get_XParam_STR(0) 
			MessageBox_Self2_Text:SetText(szStr)

			g_MessageBoxSelf2_Data[1] = Get_XParam_INT(1)
			g_MessageBoxSelf2_Data[2] = Get_XParam_INT(2)
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		else
			this:Hide()
		end
	elseif (event == "UI_COMMAND") and (arg0 == "2020042703") then
		g_iYesNoType = 164
		local isShow = Get_XParam_INT(0)
		if (isShow > 0) then
			local szStr = Get_XParam_STR(0) 
			MessageBox_Self2_Text:SetText(szStr)

			g_MessageBoxSelf2_Data[1] = Get_XParam_INT(1)
			g_MessageBoxSelf2_Data[2] = Get_XParam_INT(2)
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		else
			this:Hide()
		end
	elseif (event == "UI_COMMAND") and (arg0 == "89341205") then	
		g_iYesNoType = 165
		local strMsg 					= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1]  		= Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] 		= Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show(); 
		
	elseif (event == "UI_COMMAND") and (arg0 == "88805501") then	
		g_iYesNoType = 166
		g_MessageBoxSelf2_Data[1]  		= Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] 		= Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] 		= Get_XParam_INT(2)
		this:CareObject(g_MessageBoxSelf2_Data[1], 1, "MessageBox_Self2"); 
		MessageBox_Self2_Text:SetText(Get_XParam_STR(0))		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show(); 
		
	elseif (event == "UI_COMMAND") and (arg0 == "88807702") then --绣春刀礼盒1
		g_iYesNoType = 167
		MessageBox_Self2_Text:SetText("#{DWPF_200529_13}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
		
	elseif (event == "UI_COMMAND") and (arg0 == "88807801") then	
		g_iYesNoType  = 168
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) -- bagindex
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) -- targetid
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2) -- script 
		MessageBox_Self2_Text:SetText( strMsg )		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
		
	--elseif (event == "UI_COMMAND") and (arg0 == "20160605") then	
		--g_iYesNoType  = 169
		--MessageBox_Self2_Text:SetText( "#{ZXJQ_120516_93}" )		
		--MessageBox_Self2_OK_Button:Show()
		--MessageBox_Self2_Cancel_Button:Show()			
		--MessageBox_Self2_UpdateRect()
		--DataPool:SetCanUseHotKey(0) 
		--this:Show(); 
		
	elseif (event == "UI_COMMAND") and (arg0 == "88808203") then	
		g_iYesNoType  = 170
		local strMsg = Get_XParam_STR(0) 
		--g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		--g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText( strMsg )		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif event == "GIFTEXCHANGESHOP_CONFIRM" then
		g_iYesNoType = 171		
		g_MessageBoxSelf2_Data[1] = tonumber(arg0)
		g_MessageBoxSelf2_Data[2] = tonumber(arg3)
		g_MessageBoxSelf2_Data[3] = tonumber(arg4)
		g_MessageBoxSelf2_Data[4] = tonumber(arg5)
		local str = ScriptGlobal_Format("#{TYLW_200616_26}", tonumber(arg2), DataPool:Lua_GetItemNameByIndex(tonumber(arg1)), g_MessageBoxSelf2_Data[3], 
			DataPool:Lua_GetItemNameByIndex(g_MessageBoxSelf2_Data[2]))
		MessageBox_Self2_Text:SetText( str )		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show()	
	elseif (event == "UI_COMMAND") and (arg0 == "88809001") then
		g_iYesNoType  = 172
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88809501") then
		g_iYesNoType  = 173
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 	
	elseif (event == "UI_COMMAND") and (arg0 == "79002904") then
		g_iYesNoType  = 174
		local strMsg = Get_XParam_STR(0)
		g_MessageBoxSelf2_Data[0] = Get_XParam_INT(0) -- addnum
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "89245802") then	
		g_iYesNoType  = 175
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)	
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "20200703") then	
		g_iYesNoType  = 176
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	
	elseif ( event == "DFS_WTEAM_DISMISS" ) then
		g_iYesNoType = 177
		--您确定要解散您的战队么？
		MessageBox_Self2_Text:SetText("#{DFSZ_190613_214}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	
	elseif (event == "DFS_WTEAM_KICK_MEMBER") then
		g_iYesNoType = 178
		if tonumber(arg0) == 0 then
			--您确定要将%s0请离战队吗？请离此成员后，本战队成员数量将不足3人，会被系统强制解散。如果确认，点击确定后即可解散战队；点击取消则可放弃本次操作。
			local str = ScriptGlobal_Format("#{DFSZ_190613_204}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		else
			--你确定要将AAA请离战队么？
			local str = ScriptGlobal_Format("#{DFSZ_190613_205}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		end
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "DFS_WTEAM_MEMBER_LEAVE") then
		g_iYesNoType = 179
		if tonumber(arg0) == 0 then
			--由于您的退出，会造成战队人数少于3人而被系统强制解散战队。你确定仍要离开战队么？
			--注：离开后将会同时解散战队。
			MessageBox_Self2_Text:SetText("#{DFSZ_190613_242}")
		else
			--你确定要退出XXXX战队么？
			local str = ScriptGlobal_Format("#{BWJH_181102_139}",tostring(arg1))
			MessageBox_Self2_Text:SetText(str)
		end
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "DFS_WTEAM_ASK_INVITE") then
		g_iYesNoType = 180
		--%s0邀请您加入%s1战队一起征战巅峰赛，您是否同意加入此战队？
		local str = ScriptGlobal_Format("#{DFSZ_190613_225}", tostring(arg0), tostring(arg1))
		MessageBox_Self2_Text:SetText(str)
		g_PrenticeGUID = tostring(arg2) 
		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88814302") then
		g_iYesNoType = 181
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88814305") then
		g_iYesNoType = 182
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif  (event == "UI_COMMAND") and (arg0 == "88818702") then		-- 
		g_iYesNoType = 187
		local thisMsg 							= Get_XParam_STR(0);  
		g_MessageBoxSelf2_Data[1] 	= Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif  (event == "UI_COMMAND") and (arg0 == "88818801") then		--绣春刀联动时装返场券
		g_iYesNoType = 188
		local thisMsg 							= Get_XParam_STR(0);  
		g_MessageBoxSelf2_Data[1] 	= Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show(); 
	elseif  (event == "UI_COMMAND") and (arg0 == "88810601") then
		g_iYesNoType = 189
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) -- bagindex
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) -- scriptId
		MessageBox_Self2_Text:SetText( strMsg )		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "88821202") then
		g_iYesNoType = 190
		local strMsg = Get_XParam_STR(0)
		local nFlag = Get_XParam_INT(0)
		g_nTagertid = Get_XParam_INT(1)
		g_nItemflag = Get_XParam_INT(2)
		if nFlag == 2 then
			g_iYesNoType = 191
		end
		if nFlag == 3 then
			g_iYesNoType = 192
		end
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88820502") then
		g_iYesNoType = 193
		local strMsg = Get_XParam_STR(0) 
		--g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		--g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88820504") then
		g_iYesNoType = 194
		local strMsg = Get_XParam_STR(0) 
		--g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		--g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "88830401") then
		g_iYesNoType = 195
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif event == "JIANIANHUA_DIANCANGLIHE_SELECTCONFIRM" then
		if tonumber(arg0)>=1 and tonumber(arg0)<=6 then
			g_iYesNoType = 196
			g_MessageBoxSelf2_Data[1]  		= tonumber(arg0)
			g_MessageBoxSelf2_Data[2] 		= tonumber(arg1)
		
			local itemID=tonumber(arg2)
			local itemname = PlayerPackage:GetEquipItemName(itemID);

			local str = ScriptGlobal_Format( "#{XCCJ_201014_18}",tostring(itemname) )
			MessageBox_Self2_Text:SetText(str)
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		end
	elseif (event == "UI_COMMAND") and (arg0 == "88831401") then
		-- g_iYesNoType = 197
		-- local strMsg = Get_XParam_STR(0) 
		-- g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		-- MessageBox_Self2_Text:SetText(strMsg)		
		-- MessageBox_Self2_OK_Button:Show()
		-- MessageBox_Self2_Cancel_Button:Show()
		-- MessageBox_Self2_UpdateRect()
		-- this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89110604") then
		g_iYesNoType = 198
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		--g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText("#{MYQD_201102_01}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89110605") then
		g_iYesNoType = 199
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		--g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText("#{MYQD_201102_02}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89144703") then
		g_iYesNoType = 200
		g_MessageBoxSelf2_Data[1]  = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2]  = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3]  = Get_XParam_INT(2)
		local nMoney = Get_XParam_INT(3)
		local itemname = Get_XParam_STR(0)
		if g_MessageBoxSelf2_Data[1] == 891447 then
			if g_MessageBoxSelf2_Data[3] == 1 then
				local strText = ScriptGlobal_Format("#{SSHJ_150915_57}", tostring(nMoney),itemname,itemname)
				MessageBox_Self2_Text:SetText(strText)
			else
				local strText = ScriptGlobal_Format("#{SSHJ_150915_48}",itemname,itemname)
				MessageBox_Self2_Text:SetText(strText)
			end
		else
			g_MessageBoxSelf2_Data[4] = Get_XParam_INT(4)
			if g_MessageBoxSelf2_Data[3] == 2 then
				local strText = ScriptGlobal_Format("#{SSHJ_201030_6}", itemname)
				MessageBox_Self2_Text:SetText(strText)
			else
				if itemname ~= "" then
					local strText = ScriptGlobal_Format("#{SSHJ_201030_9}", itemname, nMoney)
					MessageBox_Self2_Text:SetText(strText)
				else
					local strText = ScriptGlobal_Format("#{SSHJ_150915_77}", nMoney)
					MessageBox_Self2_Text:SetText(strText)
				end
			end
		end	
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif event == "EXTERIOR_FASHION_CONFIRM" then
		if tonumber(arg0) == 1 or tonumber(arg0) == 2 then
			-- 全部保存
			g_iYesNoType = 201
			local str = "#{WGJM_210104_34}"
			if tonumber(arg0) == 2 then
				str = "#{WGJM_210104_12}"
			end
			
			MessageBox_Self2_Text:SetText(str)
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		end	
		if tonumber(arg0) == 1000 then
			g_iYesNoType = 203
			g_MessageBoxSelf2_Data[1]  = tonumber(arg1)
			g_MessageBoxSelf2_Data[2]  = tonumber(arg2)
			g_MessageBoxSelf2_Data[3]  = tonumber(arg3)
			g_MessageBoxSelf2_Data[4]  = tonumber(arg4)
			
			MessageBox_Self2_Text:SetText("#{WGJM_210104_26}")
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		end
	elseif event == "EXTERIOR_INFANT_CONFIRM" then
		if tonumber(arg0) == 1 or tonumber(arg0) == 2 then
			-- 保存
			g_iYesNoType = 202
			local str = "#{WGJM_210104_34}"
			if tonumber(arg0) == 2 then
				str = "#{WGJM_210104_12}"
			end
			MessageBox_Self2_Text:SetText(str)
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		elseif tonumber(arg0) == 1000 then 
			g_iYesNoType = 203	-- 点击操作函数是一样的 所以和人物时装点击确认用一个
			g_MessageBoxSelf2_Data[1]  = tonumber(arg1)
			g_MessageBoxSelf2_Data[2]  = tonumber(arg2)
			g_MessageBoxSelf2_Data[3]  = tonumber(arg3)
			g_MessageBoxSelf2_Data[4]  = tonumber(arg4)
			
			MessageBox_Self2_Text:SetText("#{WGJM_210104_28}")
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		end
	elseif  event == "UI_COMMAND" and 88838002 == tonumber(arg0)then
		g_iYesNoType = 204
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) --msgindex
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) --targetid
		local str = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	
	elseif  event == "GOUWUCHE_SUBMIT" then
		g_iYesNoType = 205
		
		local str = ScriptGlobal_Format("#{QKGWC_210311_69}", tostring(arg0))
		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88843502") then
		g_iYesNoType = 206
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "88870701") then	
		g_iYesNoType = 207
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		local str = ScriptGlobal_Format("#{HMSD_210702_132}", g_MessageBoxSelf2_Data[1], g_MessageBoxSelf2_Data[1])
		MessageBox_Self2_Text:SetText(str)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88870702") then	
		g_iYesNoType = 208
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText("#{HMSD_210702_137}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89289003") then	
		g_iYesNoType = 209
		local strMsg 			  = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99944501") then	
		g_iYesNoType = 291
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText("#{SHGZ_240726_66}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99944601") then	
		g_iYesNoType = 292
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText("#{SHGZ_240726_72}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "2021053001") then	
		g_iYesNoType = 210
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)	--FuliType
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)	--nParam
		MessageBox_Self2_Text:SetText( ScriptGlobal_Format("#{BHFLGTMB_210714_50}", Get_XParam_INT(2), Get_XParam_STR(0)) )		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "2021090101") then
		g_iYesNoType = 211
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		if g_MessageBoxSelf2_Data[1] > 0 then
			--有折扣券
			local itemid = Get_XParam_INT(1)
			local itemname = PlayerPackage:GetItemName(itemid)
			local yuanbaoCost = Get_XParam_INT(2)
			MessageBox_Self2_Text:SetText( ScriptGlobal_Format("#{XMPYY_210813_24}", tostring(itemname), tostring(yuanbaoCost)) )	
		else
			--没有折扣券
			MessageBox_Self2_Text:SetText("#{XMPYY_210813_29}")	
		end
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "2021090102") then
		g_iYesNoType = 212
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		if g_MessageBoxSelf2_Data[1] > 0 then
			--有折扣券
			local itemid = Get_XParam_INT(1)
			local itemname = PlayerPackage:GetItemName(itemid)
			local yuanbaoCost = Get_XParam_INT(2)
			MessageBox_Self2_Text:SetText( ScriptGlobal_Format("#{XMPYY_210813_33}", tostring(itemname), tostring(yuanbaoCost)) )	
		else
			--没有折扣券
			MessageBox_Self2_Text:SetText("#{XMPYY_210813_35}")	
		end
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "2021091401") then
		g_iYesNoType = 213
		local isShow = Get_XParam_INT(0)
		if (isShow > 0) then
			local strMsg = Get_XParam_STR(0)
			MessageBox_Self2_Text:SetText(strMsg)
			g_MessageBoxSelf2_Data[1] = Get_XParam_INT(1)
			MessageBox_Self2_OK_Button:Show()
			MessageBox_Self2_Cancel_Button:Show()
			MessageBox_Self2_UpdateRect()
			DataPool:SetCanUseHotKey(0)
			this:Show()
		else
			this:Hide()
		end
	elseif (event == "UI_COMMAND" and arg0 == "2021092901") then
		this:Hide()
	elseif (event == "UI_COMMAND" and arg0 == "2021100901") then
		g_iYesNoType = 214
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)

		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)

		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
	elseif (event == "UI_COMMAND" and arg0 == "2021100902") then
		g_iYesNoType = 215
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)

		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)

		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "79002930") then
		g_iYesNoType = 216
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "88888603") then
		g_iYesNoType = 217
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "88892301") then	
		g_iYesNoType 						 = 218
		local strMsg 						 = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "2022011801") then
		g_iYesNoType = 219
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)

		local kjtype   = KaJi:LuaFnGetKaJiType(58)
		if kjtype == 0 then
			if g_MessageBoxSelf2_Data[1] == 1 then
				MessageBox_Self2_Text:SetText("#{SHH_211221_80}")	
			elseif g_MessageBoxSelf2_Data[1] == 2 then
				MessageBox_Self2_Text:SetText("#{SHH_211221_75}")	
			end
		elseif kjtype == 1 then
			if g_MessageBoxSelf2_Data[1] == 1 then
				MessageBox_Self2_Text:SetText("#{SHH_211221_81}")	
			elseif g_MessageBoxSelf2_Data[1] == 2 then
				MessageBox_Self2_Text:SetText("#{SHH_211221_76}")	
			end
		end
			
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show()	
	elseif (event == "UI_COMMAND") and (arg0 == "88896502") then
		g_iYesNoType = 220
		local szStr = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(szStr)
		
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)

		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "88896503") then
		g_iYesNoType = 221
		local szStr = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(szStr)

		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "80811208") then
		g_iYesNoType = 222
		local szStr = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(szStr)
		
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88892804") then	
		g_iYesNoType 						 = 223
		local strMsg 						 = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "2022031001") then
		g_iYesNoType = 224
		local isShow = Get_XParam_INT(0)
		if (isShow > 0) then
			local strMsg = Get_XParam_STR(0)
			MessageBox_Self2_Text:SetText(strMsg)
			g_MessageBoxSelf2_Data[1] = Get_XParam_INT(1)
			MessageBox_Self2_OK_Button:Show()
			MessageBox_Self2_Cancel_Button:Show()
			MessageBox_Self2_UpdateRect()
			DataPool:SetCanUseHotKey(0)
			this:Show()
		else
			this:Hide()
		end
	elseif (event == "UI_COMMAND") and (arg0 == "80080101") then
		g_iYesNoType = 225
		local szText = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(szText)
		
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99804001") then
		g_iYesNoType = 226
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "99804101") then
		g_iYesNoType = 227
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99801707") then
		g_iYesNoType = 228
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99801708") then
		g_iYesNoType = 229
		local strMsg = tostring(arg1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99810302") then
		g_iYesNoType = 230
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99817202") then
		g_iYesNoType = 231
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif event == "CONFIRM_FENGMINGSHOP_BUY" then
		g_iYesNoType = 232
		g_MessageBoxSelf2_Data[1] = tonumber(arg0)
		g_MessageBoxSelf2_Data[2] = tonumber(arg1)
		g_MessageBoxSelf2_Data[3] = tonumber(arg2)
		g_MessageBoxSelf2_Data[4] = tonumber(arg3)

		MessageBox_Self2_Text:SetText(tostring(arg4))
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif event == "WEGAME_FORCEQUIT" then
		EnterQuitWait(3);
		return
	elseif (event == "UI_COMMAND") and (arg0 == "2022081401") then
		g_iYesNoType = 234
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		itemId = Get_XParam_INT(2)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(3)
		-- PushDebugMessage("itemId:"..tostring(itemId))
		local tips = ScriptGlobal_Format("#{ZJSJ_220708_17}",DataPool:Lua_GetItemNameByIndex(itemId),DataPool:Lua_GetItemNameByIndex(itemId))
		MessageBox_Self2_Text:SetText(tips)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif event == "CLOSE_EXTERIOR_YIRONGGE" then
		if tonumber(arg0) == 1 or tonumber(arg0) == 2 then
			-- 关闭界面
			g_iYesNoType = 235
			local str = "#{CKWG_220509_2}"
			if tonumber(arg0) == 2 then
				str = "#{CKWG_220509_5}"
			end
			g_MessageBoxSelf2_Data[1] = tonumber(arg0)
			MessageBox_Self2_Text:SetText(str)
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 55500110 then
		g_iYesNoType = 236
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) --targetId
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) --BagIndex
		MessageBox_Self2_Text:SetText("#{NJBZ_220816_304}")
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show()
		return
	elseif event == "UI_COMMAND" and tonumber(arg0) == 55500114 then
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) --targetId
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) --BagIndex
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2) --BagIndex
		g_MessageBoxSelf2_Data[4] = Get_XParam_INT(3) --isBind
		MessageBox_Self2_UnderArmourPlateTransferConfirm()
		return
	elseif event == "UI_COMMAND" and tonumber(arg0) == 55500115 then
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) --targetId
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) --BagIndex
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2) --BagIndex
		g_MessageBoxSelf2_Data[4] = Get_XParam_INT(3) --isBind
		MessageBox_Self2_UnderArmourPlateRankTransferConfirm()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 55500118 then
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) --targetId
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) --ua_index
		MessageBox_Self2_UnderArmourSwitchConfirm()
	elseif (event == "UI_COMMAND" and arg0 == "99831501") then
		g_iYesNoType = 240

		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) -- itemid
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) -- bagindex
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2) -- scriptId

		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif (event == "UI_COMMAND" and arg0 == "99831601") then
		g_iYesNoType = 241

		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) -- itemid
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) -- bagindex
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2) -- scriptId

		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show()


	elseif (event == "UI_COMMAND") and (arg0 == "99822502") then
		g_iYesNoType = 242
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) --targetid
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
		
	elseif (event == "UI_COMMAND" and arg0 == "99832301") then
		g_iYesNoType = 243

		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) -- targetId
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1) -- itemID
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2) -- scriptId

		local itemName = Get_XParam_STR(0) 
		local targetName =  Get_XParam_STR(1) 

		MessageBox_Self2_Text:SetText(ScriptGlobal_Format("#{BZTX_220705_295}",itemName,targetName))		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "2022102601") then	
		g_iYesNoType 						 = 244
		local strMsg 							= Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99831401") then
		g_iYesNoType = 255
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText("#{CSGH_220720_69}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99835601") then	
		g_iYesNoType = 256
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "998429003") then
		g_iYesNoType = 257
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99843502") then
		g_iYesNoType = 258
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "88892806") then	
		g_iYesNoType 						 = 259
		local strMsg 						 = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif (event == "UI_COMMAND") and (arg0 == "99847002") then	
		g_iYesNoType  = 260
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)	
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show(); 
	elseif event == "TRANSFORM_FASHION_CONFIRM" then
		g_iYesNoType = 261
		g_MessageBoxSelf2_Data[1]  = tonumber(arg0)
		g_MessageBoxSelf2_Data[2]  = tostring(arg1)
		
		local str = ScriptGlobal_Format("#{QXWG_230427_01}", tostring(arg1))
		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show()
	elseif  (event == "UI_COMMAND") and (arg0 == "99854802") then		--绣春刀联动时装返场券
		g_iYesNoType = 262
		local thisMsg = Get_XParam_STR(0);  
		g_MessageBoxSelf2_Data[1] 	= Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif event == "SAVE_SHARESTYLE_CONFIRM" then
		g_iYesNoType = 263
		g_MessageBoxSelf2_Data[1]  = tonumber(arg0)
		
		MessageBox_Self2_Text:SetText("#{SZDP_230509_13}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "99857403") then	
		g_iYesNoType = 264
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99857404") then	
		g_iYesNoType = 265
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] 	= Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif  (event == "UI_COMMAND") and (arg0 == "99860502") then		--绣春刀联动时装返场券
		g_iYesNoType = 266
		local thisMsg = Get_XParam_STR(0);  
		g_MessageBoxSelf2_Data[1] 	= Get_XParam_INT(0) 
		MessageBox_Self2_Text:SetText(thisMsg)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99860902") then	
		g_iYesNoType  = 267
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)	
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif event == "ZONGMEN_SHOPINFO_CONFIRM" then
		g_iYesNoType = 268
		g_MessageBoxSelf2_Data[1] = tonumber(arg0)
		g_MessageBoxSelf2_Data[2] = tonumber(arg1)
		g_MessageBoxSelf2_Data[3] = tonumber(arg2)
		g_MessageBoxSelf2_Data[4] = tonumber(arg3)

		local tblInfo = GetZongMenShopDataByID(g_MessageBoxSelf2_Data[1])
		if not tblInfo then
			return
		end

		local str = ""
		local itemname = DataPool:Lua_GetItemNameByIndex(tblInfo.itemid)
		local price = g_MessageBoxSelf2_Data[2] * tblInfo.price

		if tblInfo.huobi == 1 then
			str = ScriptGlobal_Format( "#{ZMSD_230625_73}", tostring(price), g_MessageBoxSelf2_Data[2], itemname )
		elseif tblInfo.huobi == 2 then
			str = ScriptGlobal_Format( "#{ZMSD_230625_98}", tostring(price), g_MessageBoxSelf2_Data[2], itemname )
		elseif tblInfo.huobi == 3 then
			str = ScriptGlobal_Format( "#{ZMSD_230625_99}", tostring(price), g_MessageBoxSelf2_Data[2], itemname )
		end
		
		MessageBox_Self2_Text:SetText(str)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "99890101") then
		g_iYesNoType = 270

		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)

		local str = ""
		if g_MessageBoxSelf2_Data[3] == 1 then
			str = ScriptGlobal_Format( "#{ZMDZ_230703_184}", g_MessageBoxSelf2_Data[1] )
		else
			str = ScriptGlobal_Format( "#{ZMDZ_230703_183}", g_MessageBoxSelf2_Data[1] )
		end

		MessageBox_Self2_Text:SetText( str )

		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89293907") then	
		g_iYesNoType = 271 
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)	 
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show(); 
	elseif event == "QM8X_CLOSE_CHANGEUI" then	
		g_iYesNoType = 272
		g_MessageBoxSelf2_Data[1] = tonumber(arg0)

		MessageBox_Self2_Text:SetText( "#{XFXB_230823_63}" )
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "99884702") then
		g_iYesNoType = 273		
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)

		MessageBox_Self2_Text:SetText( "#{XFXB_230823_22}" )
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show()
	elseif ( event == "SECT_SAVEPLAN_CONFIRM" ) then
		g_iYesNoType = 274
		g_MessageBoxSelf2_Data[1] = tonumber(arg0)
		g_MessageBoxSelf2_Data[2] = tonumber(arg1)
		if g_MessageBoxSelf2_Data[2] == 0 then
			MessageBox_Self2_Text:SetText("#{ZMTFBC_230920_28}")
		else
			MessageBox_Self2_Text:SetText("#{ZMTFBC_230920_57}")
		end
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif ( event == "SECT_LEAVE_WITHOUT_SAVE" ) then
		g_iYesNoType = 275
		g_MessageBoxSelf2_Data[1] = tonumber(arg0)
		g_MessageBoxSelf2_Data[2] = tonumber(arg1)
		g_MessageBoxSelf2_Data[3] = tonumber(arg2)
		MessageBox_Self2_Text:SetText("#{ZMTFBC_230920_59}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif ( event == "TRADE_CONFIRM" ) then		
		local isshow = tonumber(arg0)		
		local username = Player:GetName()
		Lua_TDU_Log("receive event user:"..username.." isshow:"..isshow);
		if isshow == 1 then
			g_iYesNoType = 277 
			local str = ScriptGlobal_Format("#{WJJY_231123_20}", Exchange:GetOthersName(), Exchange:GetOthersInfo("level"))
			MessageBox_Self2_Text:SetText(str)
			MessageBox_Self2_OK_Button:Show();
			MessageBox_Self2_Cancel_Button:Show();
			MessageBox_Self2_UpdateRect()
			this:Show();
		else
			this:Hide();
		end
			
	elseif (event == "UI_COMMAND") and (arg0 == "89071310") then	
		g_iYesNoType = 278
		local strMsg = Get_XParam_STR(0)
		g_FairShopindex = Get_XParam_INT(0)
		g_FairShopshowid = Get_XParam_INT(1)
		g_FairShopitemIdx = Get_XParam_INT(2)
		g_FairShopindex2 = Get_XParam_INT(3)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99896802") then
		g_iYesNoType = 279		
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText( strMsg )
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "99896803") then
		g_iYesNoType = 280		
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText( strMsg )
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show()
	--2024春节时装获取
	elseif (event == "UI_COMMAND") and (arg0 == "99889703") then
		g_iYesNoType = 281		
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText( ScriptGlobal_Format("#{CJSZ_231030_15}", g_MessageBoxSelf2_Data[1], g_MessageBoxSelf2_Data[2]) )
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show()		
	elseif (event == "UI_COMMAND") and (arg0 == "99910102") then	
		g_iYesNoType  = 282
		MessageBox_Self2_Text:SetText("#{DWKC_240514_10}")	
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
		
	elseif (event == "UI_COMMAND") and (arg0 == "99929902") then
		g_iYesNoType = 283
		MessageBox_Self2_Text:SetText(Get_XParam_STR(0))
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89292111") then	
		g_iYesNoType = 284
		local strMsg = Get_XParam_STR(0)
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "5112805") then		
		g_iYesNoType = 285
		MessageBox_Self2_Text:SetText("#{QXPVE_240628_32}")	
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99936001") then
		g_iYesNoType = 286
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99944102") then	
		g_iYesNoType = 287
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99944103") then	
		g_iYesNoType = 288
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "99944104") then	
		g_iYesNoType = 289
		local strMsg = Get_XParam_STR(0)
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "33110602") then
		g_iYesNoType = 290
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99932106") then		
		g_iYesNoType = 293
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)	
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "331105009") then		
		g_iYesNoType = 294
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "331105010") then		
		g_iYesNoType = 295
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "80010501") then
		g_iYesNoType = 296
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0) 
		local isLock = Pet : GetExpLock(g_MessageBoxSelf2_Data[1]);
		local strMsg = ""
		if isLock >= 1 then
			strMsg = "#{ZSSJ_20240918_6}"
		else
			strMsg = "#{ZSSJ_20240918_2}"
		end
		MessageBox_Self2_Text:SetText(strMsg)	
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 

		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99944112") then	
		g_iYesNoType = 297
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99950104") then
		g_iYesNoType = 298
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99952401") then	
		g_iYesNoType = 299
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText("#{BXDSJ_240920_16}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99952701") then	
		g_iYesNoType = 300
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		MessageBox_Self2_Text:SetText("#{BXDSJ_240920_86}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "331141005") then
		g_iYesNoType = 301
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99954903") then
		g_iYesNoType = 302
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99954904") then
		g_iYesNoType = 303
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif event == "UI_COMMAND" and arg0 == "88982201" then
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_ActiveJiuWeiConfirm()	
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "99955302") then	
		g_iYesNoType  = 305
		MessageBox_Self2_Text:SetText("#{DWKC_241115_04}")	
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99952801") then	
		g_iYesNoType = 307
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		MessageBox_Self2_Text:SetText("#{BXDSJ_240920_98}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	-- 新6v6 邀请入队
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99955401) then
		g_iYesNoType = 308

		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)

		local strText = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strText)
		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	-- 新6v6 解散战队
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99955402) then
		g_iYesNoType = 309

		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)

		MessageBox_Self2_Text:SetText("#{BWDH_241114_145}")
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	-- 新6v6 退出战队
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99955403) then
		g_iYesNoType = 310

		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)

		local strText = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strText)
		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99963201") then
		g_iYesNoType = 311

		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)

		local strText = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strText)
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "99963301") then
		g_iYesNoType = 312
		MessageBox_Self2_Text:SetText("#{ZXSD_20250117_41}")
		MessageBox_Self2_OK_Button:Show();
		MessageBox_Self2_Cancel_Button:Show();
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99969702") then	
		g_iYesNoType  = 313
		MessageBox_Self2_Text:SetText("#{DWKC_250516_04}")	
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND" and arg0 == "99969301") then
		g_iYesNoType = 314

		local nBagIndex = Get_XParam_INT(0);
		g_MessageBoxSelf2_Data[1]  = nBagIndex
		local nNum = Get_XParam_INT(1);
		local nItemName = Get_XParam_STR(0);
		local nName = Get_XParam_STR(1);

		local itemName = Get_XParam_STR(0) 
		local targetName =  Get_XParam_STR(1) 

		MessageBox_Self2_Text:SetText( ScriptGlobal_Format("#{CZPH_250430_44}", nNum, nItemName, nName ))	
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "9997102") then	
		g_iYesNoType  = 315
		MessageBox_Self2_Text:SetText("#{SCBHPM_20220815_172}")	
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "9997103") then	
		g_iYesNoType  = 316
		local nNum = Get_XParam_INT(0);
		local nItemName = Get_XParam_STR(0);
		MessageBox_Self2_Text:SetText(ScriptGlobal_Format("#{SCBHPM_20220815_184}", nNum, nItemName))
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();	
	elseif (event == "UI_COMMAND") and (arg0 == "9997104") then	
		g_iYesNoType  = 317		

		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		g_MessageBoxSelf2_Data[4] = Get_XParam_INT(3)

		local nItemName = Get_XParam_STR(0);

		MessageBox_Self2_Text:SetText(ScriptGlobal_Format("#{SCBHPM_20220815_190}", g_MessageBoxSelf2_Data[3], nItemName))	
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "88817701") then	
		g_iYesNoType  = 318

		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)--targetId
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)--1：祈福道具确认 2:烟花道具确认
		if g_MessageBoxSelf2_Data[2] == 1 then
			MessageBox_Self2_Text:SetText("#{XFSJ_250527_41}")
		elseif g_MessageBoxSelf2_Data[2] == 2 then
			MessageBox_Self2_Text:SetText("#{XFSJ_250527_54}")
		end
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99973901") then	
		g_iYesNoType  = 319
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)--targetId
		MessageBox_Self2_Text:SetText("#{KDJYD_250814_196}")
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99976702") then
		g_iYesNoType = 320
		local strMsg = Get_XParam_STR(0) 
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)
		g_MessageBoxSelf2_Data[3] = Get_XParam_INT(2)
		g_MessageBoxSelf2_Data[4] = Get_XParam_INT(3)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99978102") then	
		g_iYesNoType  = 321
		MessageBox_Self2_Text:SetText("#{DWKC_251106_03}")	
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99978201") then	
		g_iYesNoType  = 322
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)	
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)	
		if g_MessageBoxSelf2_Data[2] == 1 then
			MessageBox_Self2_Text:SetText("#{JWFT_251105_1}")	
		else
			MessageBox_Self2_Text:SetText("#{JWFT_251105_12}")	
		end
		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99978501") then
		g_iYesNoType = 323
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText("#{BSSCK_251119_24}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "99979103") then	
		g_iYesNoType  = 324
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)	
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)	
		local str = ScriptGlobal_Format("#{DWKC_251201_14}",Get_XParam_INT(3), DataPool:Lua_GetItemNameByIndex(Get_XParam_INT(2)))
		MessageBox_Self2_Text:SetText(str)	
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "331180005") then
		g_iYesNoType = 325
		local strMsg = Get_XParam_STR(0) 
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "99978502") then
		g_iYesNoType = 326
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_Text:SetText("#{BSSCK_251119_28}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "211599") then
		g_iYesNoType  = 327
		MessageBox_Self2_Text:SetText("#{MPZH_251117_01}")	
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)	
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "89071320") then	
		g_iYesNoType = 328
		local strMsg = Get_XParam_STR(0)
		g_FairShopindex = Get_XParam_INT(0)
		g_FairShopshowid = Get_XParam_INT(1)
		g_FairShopitemIdx = Get_XParam_INT(2)
		g_FairShopindex2 = Get_XParam_INT(3)
		MessageBox_Self2_Text:SetText(strMsg)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show();
	elseif  event == "FENGYUN_YURE_CLOSE_CONFIRM" then
		g_iYesNoType = 329
		g_MessageBoxSelf2_Data[1] = tonumber(arg0)
		g_MessageBoxSelf2_Data[2] = tonumber(arg1)
		MessageBox_Self2_Text:SetText("#{FYYR_260108_99}")
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "88555902") then --幻武盒子
		g_iYesNoType = 330
		MessageBox_Self2_Text:SetText("#{FYJD_250113_48}")		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "88556801") then
		g_iYesNoType  = 331
		MessageBox_Self2_Text:SetText("#{JZHD_260325_16}")
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "88556802") then
		g_iYesNoType  = 332
		MessageBox_Self2_Text:SetText("#{JZHD_260325_25}")
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "88556803") then
		g_iYesNoType  = 333
		MessageBox_Self2_Text:SetText("#{JZHD_260325_31}")
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
	elseif (event == "UI_COMMAND") and (arg0 == "99984103") then --购买火麒麟二次确认
		g_iYesNoType = 334
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)		
		g_MessageBoxSelf2_Data[2] = Get_XParam_INT(1)		
		MessageBox_Self2_Text:SetText(ScriptGlobal_Format("#{FYJD_250113_83}",g_MessageBoxSelf2_Data[2],g_MessageBoxSelf2_Data[1]))	
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0)
		this:Show()
	elseif  event == "GUILD_ZHANTUAN_OP_UPDATE" then
		local opType = tonumber(arg0)
		if opType == 1000 then
			g_iYesNoType = 335
			local str = tostring(arg1)
			MessageBox_Self2_Text:SetText(ScriptGlobal_Format("#{ZTXT_260511_50}",str))
			MessageBox_Self2_OK_Button:Show()
			MessageBox_Self2_Cancel_Button:Show()
			MessageBox_Self2_UpdateRect()
			this:Show()
		end
	elseif (event == "UI_COMMAND") and (arg0 == "88557602") then	--2026kaichuan
		g_iYesNoType  = 336
		MessageBox_Self2_Text:SetText("#{DWKC_260515_03}")	
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	elseif (event == "UI_COMMAND") and (arg0 == "89377702") then
		g_iYesNoType  = 337
		local strMsg = Get_XParam_STR(0)
		MessageBox_Self2_Text:SetText(strMsg)	
		g_MessageBoxSelf2_Data[1] = Get_XParam_INT(0)		
		MessageBox_Self2_OK_Button:Show()
		MessageBox_Self2_Cancel_Button:Show()			
		MessageBox_Self2_UpdateRect()
		DataPool:SetCanUseHotKey(0) 
		this:Show();
	end
end

function MessageBox_Self2_CaiLiaoCompoundConfirm(data1, data2, data3, data4, strMsg)

	CaiLiaoCompound_Data[1]=data1
	CaiLiaoCompound_Data[2]=data2
	CaiLiaoCompound_Data[3]=data3
	CaiLiaoCompound_Data[4]=data4
	
	MessageBox_Self2_Text:SetText(strMsg)		
	MessageBox_Self2_OK_Button:Show()
	MessageBox_Self2_Cancel_Button:Show()			
	MessageBox_Self2_UpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show();

end

function MessageBox_Self2_RunHunShiCompoundConfirm(data1, data2, data3, data4, strMsg)

	RunHunShiCompound_Data[1]=data1
	RunHunShiCompound_Data[2]=data2
	RunHunShiCompound_Data[3]=data3
	RunHunShiCompound_Data[4]=data4
	
	MessageBox_Self2_Text:SetText(strMsg)		
	MessageBox_Self2_OK_Button:Show()
	MessageBox_Self2_Cancel_Button:Show()			
	MessageBox_Self2_UpdateRect()
	DataPool:SetCanUseHotKey(0)
	this:Show();

end

function MessageBox_Self2_Ok_Clicked()

	if (18 == g_iYesNoType) then
		--绑定元宝不足时，确定
		NpcShop:BindYuanBaoNotEnough(g_itemNum, g_item,g_pos, g_bFromRecentBooth)
	end

	if  (g_iYesNoType == 3) then
		PushEvent("AFTER_UPDATE_LW_LEVELUP_CONFIRM")
	end
	if  (g_iYesNoType == 4) then
		PushEvent("AFTER_UPDATE_LW_BIND_CONFIRM")
	end



	if (g_iYesNoType == 6) then
		PushEvent("DISMISS_CORPS_CONFIRMED")
	end

	if (g_iYesNoType == 7) then
		PushEvent("CORPS_KICK_MEMBER_CONFIRMED")
	end

	if (g_iYesNoType == 8) then
		PushEvent("CORPS_MEMBER_LEAVE_CONFIRMED")
	end

	if (g_iYesNoType == 9) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnSeHuanYuanConfirm")  --脚本接口
			Set_XSCRIPT_ScriptID(g_PetPoss_ScriptID) --脚本编号
			Set_XSCRIPT_Parameter(0, g_PetPoss_ModelTypeId)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()

	end
	if (g_iYesNoType == 10) then
		--do nothing
	end
	if (g_iYesNoType == 11) then
		PushEvent("EQUIPSTRENGTH_QUICK_CONFIRM_RET")
	end
	--if (g_iYesNoType == 14) then
		--CachedTarget:GetChangyigeCheckMsg(Changyige_password,Changyige_money)
		--PushEvent( "CHANGYIGE_CHECK_WAITE" )
	--end
	this:Hide();
	if 	g_iYesNoType == 17 then
		PushEvent("CLOSE_COMPENSATE")
		GameProduceLogin:OpenURL(GetWeblink("WEB_LOSER_SATISFACTION"))
		this:Hide()
	end

	if (g_iYesNoType == 19) then  --可切换
		RunCmdLine()
		EnterQuitWait(0)
		this:Hide()
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "SendChangeClientLog" )
		Set_XSCRIPT_ScriptID( 888888 )
		Set_XSCRIPT_Parameter(0,3);
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		Lua_TDU_Log("Change Client end ...")
	elseif (g_iYesNoType == 20) then  --不可切换经典
		Lua_TDU_Log("Load classic download web ...")
		GameProduceLogin:OpenURL(GetWeblink("WEB_JD_DOWNLOAD"))
		this:Hide()
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "SendChangeClientLog" )
		Set_XSCRIPT_ScriptID( 888888 )
		Set_XSCRIPT_Parameter(0,4);
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 21) then  --不可切换唯美
		Lua_TDU_Log("Load wm download web ...")
		GameProduceLogin:OpenURL(GetWeblink("WEB_WM_DOWNLOAD"))
		this:Hide()
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "SendChangeClientLog" )
		Set_XSCRIPT_ScriptID( 888888 )
		Set_XSCRIPT_Parameter(0,4);
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 22) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SelectRiderOK");
			Set_XSCRIPT_ScriptID(340023);
			Set_XSCRIPT_Parameter(0, g_DianCangLiHeParam1);--背包位置
			Set_XSCRIPT_Parameter(1, g_DianCangLiHeParam0);--索引1-4
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
		if IsWindowShow("PaySelectReward") then
			CloseWindow("PaySelectReward")
		end
	elseif (g_iYesNoType == 23) then
		PushEvent("SURE_DWCHAIJIE")
	elseif (g_iYesNoType == 24) then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAskGemLevelup")
		Set_XSCRIPT_ScriptID(290207)
		Set_XSCRIPT_Parameter(0, g_GemLevelupInfo[1])
		Set_XSCRIPT_Parameter(1, g_GemLevelupInfo[2])
		Set_XSCRIPT_Parameter(2, g_GemLevelupInfo[3])
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	elseif (g_iYesNoType == 25) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnGuard")
			Set_XSCRIPT_ScriptID(890900)
			Set_XSCRIPT_Parameter(0,Guard_Data[3]);
			Set_XSCRIPT_Parameter(1,Guard_Data[2]);
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
	elseif (g_iYesNoType == 26) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name(g_Server_Script_Function);
			Set_XSCRIPT_ScriptID(g_Server_Script_ID);
			Set_XSCRIPT_Parameter(0,g_Server_Return_1);
			Set_XSCRIPT_Parameter(1,g_Server_Return_2);
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 27) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("UseRobItemCopper");
			Set_XSCRIPT_ScriptID(890920);
			Set_XSCRIPT_Parameter(0,g_RobbagIndex);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 28) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("UseRobItemSilver");
			Set_XSCRIPT_ScriptID(890919);
			Set_XSCRIPT_Parameter(0,g_RobbagIndex);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 29) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("UseRobItemGold");
			Set_XSCRIPT_ScriptID(890918);
			Set_XSCRIPT_Parameter(0,g_RobbagIndex);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 30) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SelectPneumaOK");
			Set_XSCRIPT_ScriptID(891003);
			Set_XSCRIPT_Parameter(0, g_PneumaBoxBagpos);--背包位置
			Set_XSCRIPT_Parameter(1, g_PneumaBoxSelectIndex);--索引1-4
			Set_XSCRIPT_Parameter(2, 1);--索引1-4
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
		if IsWindowShow("Present_Duihuan") then
			CloseWindow("Present_Duihuan")
		end
	elseif (g_iYesNoType == 31) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("BattleTranAndImpact");
			Set_XSCRIPT_ScriptID(506025);
			Set_XSCRIPT_Parameter(0, g_TServerBuyImpact[1]);--类型：传送或者购买士气
			Set_XSCRIPT_Parameter(1, g_TServerBuyImpact[2]);--传送何处或者花费何种货币购买士气
			Set_XSCRIPT_Parameter(2, 1);--购买确认完毕
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 32) then
		this:Hide()
	elseif (g_iYesNoType == 33) then
		PushEvent("BINDSURE_EQUIPDWLEVELUP",1)
	elseif (g_iYesNoType == 34) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DoEquipDWLevelUp")
			Set_XSCRIPT_ScriptID(809272)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 35) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyGift" )
			Set_XSCRIPT_ScriptID( 889958 )
			Set_XSCRIPT_Parameter(0,0)
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 36) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyGift" )
			Set_XSCRIPT_ScriptID( 889958 )
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 48) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyGift" )
			Set_XSCRIPT_ScriptID( 889958 )
			Set_XSCRIPT_Parameter(0,2)
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 37) then
		this:Hide() 
	elseif (g_iYesNoType == 38) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnBetrayMaster")
			Set_XSCRIPT_ScriptID(891116)
			Set_XSCRIPT_Parameter(0, 2)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 39) then
		local delGuid = g_PrenticeGUID
		local delindex = g_PrenticeIndex
		local delGuidH, delGuidL = SplitGUID64( delGuid )
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnExpelPrentice")
			Set_XSCRIPT_ScriptID(891116)
			Set_XSCRIPT_Parameter(0, 2)
			Set_XSCRIPT_Parameter(1, delindex)
			Set_XSCRIPT_Parameter(2, delGuidH)
			Set_XSCRIPT_Parameter(3, delGuidL)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
  elseif (g_iYesNoType == 40) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuybowenji" )
			Set_XSCRIPT_ScriptID( 891151 )
			Set_XSCRIPT_Parameter(0,g_index)
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 41) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyHeroBabBagGift" )
			Set_XSCRIPT_ScriptID( 891110 )
			Set_XSCRIPT_Parameter(0,g_HeroBabBagIndex) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 42) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name(g_Brother_Scritp_Function);
			Set_XSCRIPT_ScriptID(g_Brother_Script_ID);
			Set_XSCRIPT_Parameter(0,g_Brother_Return_1);
			Set_XSCRIPT_Parameter(1,g_Brother_Return_2);
			Set_XSCRIPT_Parameter(2,g_Brother_Return_3);
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
	elseif	g_iYesNoType == 45 then
		KBuildingGroup:FiredUp()
		
	elseif (g_iYesNoType == 46) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnMakeCake");
			Set_XSCRIPT_ScriptID(891655);
			Set_XSCRIPT_Parameter(0, -1);
			Set_XSCRIPT_Parameter(1, 1);
			Set_XSCRIPT_Parameter(2, 1);
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
	
	elseif (g_iYesNoType == 47) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name( "DoDemise" )
			Set_XSCRIPT_ScriptID( 891404 )
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]);
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3]);
			Set_XSCRIPT_Parameter(3, 1);
			Set_XSCRIPT_ParamCount(4);
		Send_XSCRIPT();

--	elseif (g_iYesNoType == 50) then
--		Clear_XSCRIPT();
--			Set_XSCRIPT_Function_Name("ReplyEngage");
--			Set_XSCRIPT_ScriptID(509081);
--			Set_XSCRIPT_Parameter(0, 0)
--			Set_XSCRIPT_ParamCount(1);
--		Send_XSCRIPT();
	elseif (g_iYesNoType == 51) then
		PushEvent("CORPS_INVITE_MEMBER", g_PrenticeGUID, 1)
	elseif (g_iYesNoType == 52) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "RunHunShiCompound_New" )
			Set_XSCRIPT_ScriptID(809270)
			Set_XSCRIPT_Parameter(0,RunHunShiCompound_Data[1])--npcid
			Set_XSCRIPT_Parameter(1,RunHunShiCompound_Data[2])--1快捷2普通
			Set_XSCRIPT_Parameter(2,RunHunShiCompound_Data[3])--类型
			Set_XSCRIPT_Parameter(3,RunHunShiCompound_Data[4])--子类型
			Set_XSCRIPT_Parameter(4,1)--二次确认
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 53) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("AskOut");
			Set_XSCRIPT_ScriptID(509087);
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 54) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnBuyFireWorks");
			Set_XSCRIPT_ScriptID(509088);
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 55) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("AskCompe");
			Set_XSCRIPT_ScriptID(509085);
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 56) then
		--开始凝炼
		if IsTBFinalServer() >= 1 then
		--T服跨服战总决赛服务器,不走这里的逻辑
			PushDebugMessage("#{BHKF_150323_61}")
			return
		end		
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnLianDanLuNingLian");
			Set_XSCRIPT_ScriptID(339008);
			Set_XSCRIPT_Parameter(0, 0 )
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 57) then
		--开始凝炼
		if IsTBFinalServer() >= 1 then
		--T服跨服战总决赛服务器,不走这里的逻辑
			PushDebugMessage("#{BHKF_150323_61}")
			return
		end				
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnLianDanLuNingLian");
			Set_XSCRIPT_ScriptID(339011);
			Set_XSCRIPT_Parameter(0, 0 )
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 58) then
		PushEvent("PNEUMA_QUICKONCENY_QR",1)
	elseif (g_iYesNoType == 63) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "CaiLiaoCompound_New" )
			Set_XSCRIPT_ScriptID(701602)
			Set_XSCRIPT_Parameter(0,CaiLiaoCompound_Data[1])--npcid
			Set_XSCRIPT_Parameter(1,CaiLiaoCompound_Data[2])--1快捷2普通
			Set_XSCRIPT_Parameter(2,CaiLiaoCompound_Data[3])--类型
			Set_XSCRIPT_Parameter(3,CaiLiaoCompound_Data[4])--子类型
			Set_XSCRIPT_Parameter(4,1)--二次确认
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 64) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnFinishUseLight" )
			Set_XSCRIPT_ScriptID(892550)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 65) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnActivateAfterConfirm" )
			Set_XSCRIPT_ScriptID(892652)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 66) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "LingQuGiftNormal" )
			Set_XSCRIPT_ScriptID(892653)
			Set_XSCRIPT_Parameter(0,g_nTagertid)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 67) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangeItem" )
			Set_XSCRIPT_ScriptID(892654)
			Set_XSCRIPT_Parameter(0,g_nTagertid)
			Set_XSCRIPT_Parameter(1,g_nItemflag)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 	
	elseif (g_iYesNoType == 68) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetPrize" )
			Set_XSCRIPT_ScriptID(889274)
			Set_XSCRIPT_Parameter(0,g_nTagertid)
			Set_XSCRIPT_Parameter(1,g_nselfIndex)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 	

	elseif (g_iYesNoType == 69) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyHeroBabBagGift" )
			Set_XSCRIPT_ScriptID( 892685 )
			Set_XSCRIPT_Parameter(0,g_HeroBabBagIndex) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()			
	elseif (g_iYesNoType == 70) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetRiceCake" )
			Set_XSCRIPT_ScriptID( 892656 )
			Set_XSCRIPT_Parameter(0,g_nTagertid) 
			Set_XSCRIPT_Parameter(1,0) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()				
	elseif (g_iYesNoType == 71) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetPrize" )
			Set_XSCRIPT_ScriptID( 892656 )
			Set_XSCRIPT_Parameter(0,g_nTagertid) 
			Set_XSCRIPT_Parameter(1,0) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()				
		
	elseif (g_iYesNoType >= 72 and g_iYesNoType <= 79) then
		local FunctionName = {	"GetXiaYinReally",
								"GetSuperWeaponReally",
								"GetBaoZhuReally",
								"GetAnQiReally",
								"GetWuHunReally",
								"GetDiaoWenReally",
								"GetInfantReally",
								}
		local ScriptId = 892707 + g_nIndex - 1
		if FunctionName[g_nIndex] ~= nil and (ScriptId >=892707 and ScriptId <= 892714) then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( FunctionName[g_nIndex] )
				Set_XSCRIPT_ScriptID(ScriptId)
				Set_XSCRIPT_Parameter(0,g_nTagertid)
				Set_XSCRIPT_Parameter(1,g_nItemId)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT() 	
		end
	elseif (g_iYesNoType == 80) then
		PushEvent("DISMISS_CORPS_CONFIRMED_2018")

	elseif (g_iYesNoType == 81) then
		PushEvent("CORPS_KICK_MEMBER_CONFIRMED_2018")

	elseif (g_iYesNoType == 82) then
		PushEvent("CORPS_MEMBER_LEAVE_CONFIRMED_2018")
	
	elseif (g_iYesNoType == 83) then
		CorpsUI_2018:CorpsOper_InviteAnswer(g_PrenticeGUID, 1)
		
	elseif (g_iYesNoType == 84) then
		local myname = Player:GetName()
		local tips = ScriptGlobal_Format("#{WCBZ_180128_134}", myname, g_PrenticeGUID)
		PushDebugMessage(tips)
		PushEvent("CORPS_INVITE_NPCTALK2_2018", g_PrenticeGUID)
		CorpsUI_2018:CorpsOper_InviteCorps(3)
		CloseWindow("NoDiffMatch_JoinChoseMP", true)
	
	elseif (g_iYesNoType == 85) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnExchangeItem" )
			Set_XSCRIPT_ScriptID(892810)
			Set_XSCRIPT_Parameter(0,g_nTagertid)
			Set_XSCRIPT_Parameter(1,g_nnumText)
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT() 	
		
	elseif (g_iYesNoType == 86) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GiveItemByGoldenFootBall" )
			Set_XSCRIPT_ScriptID(892851)
			Set_XSCRIPT_Parameter(0,g_nTagertid)
			Set_XSCRIPT_Parameter(1,g_nnumText) 
			Set_XSCRIPT_Parameter(2,1) 
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT() 		
	elseif (g_iYesNoType == 87) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnActivateAfterConform" )
			Set_XSCRIPT_ScriptID(g_nScriptid)
			Set_XSCRIPT_Parameter(0,g_nbagIndex)
			Set_XSCRIPT_Parameter(1,g_nTagertid)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 		
	elseif (g_iYesNoType == 88) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ReallyReFreshXiGuaShop" )
			Set_XSCRIPT_ScriptID(892869)
			Set_XSCRIPT_Parameter(0,g_nFlag)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT() 		
	elseif (g_iYesNoType == 89) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ReallyBuyItem" )
			Set_XSCRIPT_ScriptID(892869)
			Set_XSCRIPT_Parameter(0,g_nFlag)
			Set_XSCRIPT_Parameter(1,g_nIdx)
			Set_XSCRIPT_Parameter(2,g_nItemIdx)
			Set_XSCRIPT_Parameter(3,g_nItemId)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT() 		
	elseif (g_iYesNoType == 90) then	
		Clear_XSCRIPT()
			if g_nFlag == 0 then
				if g_nIsWeaponOrFashion == 1 then
					Set_XSCRIPT_Function_Name( "OnWeaponBuy" )
				elseif g_nIsWeaponOrFashion == 2 then
					Set_XSCRIPT_Function_Name( "OnFeiYuBuy" )
				else
					Set_XSCRIPT_Function_Name( "OnFashionBuy" )
				end
			else
				if g_nIsWeaponOrFashion == 1 then
					Set_XSCRIPT_Function_Name( "OnWeaponLiHeBuy" )
				elseif g_nIsWeaponOrFashion == 2 then
					Set_XSCRIPT_Function_Name( "OnFeiYuLiHeBuy" )
				else
					Set_XSCRIPT_Function_Name( "OnFashionLiHeBuy" )
				end
			end
			Set_XSCRIPT_ScriptID(892869)
			Set_XSCRIPT_Parameter(0,0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT() 	
	elseif (g_iYesNoType == 91) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "GetLuckyItem_Begin" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 892881 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, 1 );																		-- 是否确认
     		Set_XSCRIPT_Parameter( 1, tonumber( g_MessageBoxSelf2_Data[1] ) );		-- 参数一 玩法
     		Set_XSCRIPT_Parameter( 2, tonumber( g_MessageBoxSelf2_Data[2] ) );		-- 参数二 删除玩法 选择的位置
     		Set_XSCRIPT_Parameter( 3, tonumber( g_MessageBoxSelf2_Data[3] ) );		-- 参数三 双倍玩法 预留
     		Set_XSCRIPT_Parameter( 4, tonumber( g_MessageBoxSelf2_Data[4] ) );		-- 参数四 替换玩法 预留
     		Set_XSCRIPT_ParamCount( 5 );												-- 参数个数  
     	Send_XSCRIPT()	
	elseif (g_iYesNoType == 92) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ClientActivateOnce" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 892926 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, tonumber( g_MessageBoxSelf2_Data[1] ) );		-- 参数一 玩法 
     		Set_XSCRIPT_Parameter( 1, 1 );																		-- 是否确认
     		Set_XSCRIPT_ParamCount( 2 );												-- 参数个数  
     	Send_XSCRIPT()	
	elseif (g_iYesNoType == 93) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ClientActivateOnce" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 892927 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, tonumber( g_MessageBoxSelf2_Data[1] ) );		-- 参数一 玩法 
     		Set_XSCRIPT_Parameter( 1, 1 );																		-- 是否确认
     		Set_XSCRIPT_ParamCount( 2 );												-- 参数个数  
     	Send_XSCRIPT()
	elseif (g_iYesNoType == 94) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnCommonShopBuy" )
			Set_XSCRIPT_ScriptID(892921)
			Set_XSCRIPT_Parameter(0,g_nFlag)
			Set_XSCRIPT_Parameter(1,g_nIdx)
			Set_XSCRIPT_Parameter(2,g_nItemIdx)
			Set_XSCRIPT_Parameter(3,g_nItemId)
			Set_XSCRIPT_Parameter(4,0)
			Set_XSCRIPT_Parameter(5,0)
			Set_XSCRIPT_ParamCount(6)
		Send_XSCRIPT() 		 
	elseif (g_iYesNoType == 95) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRefreshShopItem" )
			Set_XSCRIPT_ScriptID(892921)
			Set_XSCRIPT_Parameter(0,g_nFlag)
			Set_XSCRIPT_Parameter(1,0)
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT() 
	elseif (g_iYesNoType == 96) then	
		PushEvent("NATIOANALDAY_YUANBAO_CONFIRM", g_Server_Script_Function, tonumber( g_MessageBoxSelf2_Data[1] ),tonumber( g_MessageBoxSelf2_Data[2] ))
	elseif (g_iYesNoType == 97) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetPrize" )
			Set_XSCRIPT_ScriptID(892912)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[2] ) 
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	 
	elseif (g_iYesNoType == 98) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UseYuYe" )
			Set_XSCRIPT_ScriptID(892939)
			Set_XSCRIPT_Parameter(0, 1 )  
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	 
	elseif (g_iYesNoType == 99) then	
	-- 执行脚本
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetPrize" ); 	-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 892939 );				-- 脚本编号
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1] )  				-- 索引 
			Set_XSCRIPT_Parameter(1, 1 )  					-- 是否 
			Set_XSCRIPT_ParamCount(2)					-- 参数个数 
		Send_XSCRIPT() 	 
	elseif (g_iYesNoType == 100) then	
	-- 执行脚本
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "SignContact" ); 	-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 892939 );				-- 脚本编号
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1] )  				-- 索引 
			Set_XSCRIPT_Parameter(1, 1 )  					-- 是否 
			Set_XSCRIPT_ParamCount(2)					-- 参数个数 
		Send_XSCRIPT() 	 
	elseif (g_iYesNoType == 101) then	
	-- 执行脚本
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetQiongJiangBack" ); 	-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 892939 );				-- 脚本编号
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1] )  				-- 索引 
			Set_XSCRIPT_Parameter(1, 1 )  					-- 是否 
			Set_XSCRIPT_ParamCount(2)					-- 参数个数 
		Send_XSCRIPT() 	
	elseif (g_iYesNoType == 102) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExpIsFull" )
			Set_XSCRIPT_ScriptID(889274)
			Set_XSCRIPT_Parameter(0,g_nTagertid)
			Set_XSCRIPT_Parameter(1,g_nselfIndex)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 
		
	elseif (g_iYesNoType == 103) then
		PushEvent("TXBW_WTEAM_DISMISS_CONFIRM")

	elseif (g_iYesNoType == 104) then
		PushEvent("TXBW_WTEAM_KICK_MEMBER_CONFIRMED")

	elseif (g_iYesNoType == 105) then
		PushEvent("TXBW_WTEAM_MEMBER_LEAVE_CONFIRMED")
	
	elseif (g_iYesNoType == 106) then
		BWDH2018:WTeamOper_RetInvite(g_PrenticeGUID, 1)	 
	else
		MessageBox_Self2_Ok_ClickedEx()
	end
end

function MessageBox_Self2_Ok_ClickedEx()
	if (g_iYesNoType == 107) then
		Clear_XSCRIPT()
			if g_FairShopType == 1 then
				Set_XSCRIPT_Function_Name( "ReFreshFairShopByYB" )
			elseif g_FairShopType == 2 then
				Set_XSCRIPT_Function_Name( "ReFreshBigFairShop" )
			else
				Set_XSCRIPT_Function_Name( "ReFreshFairShop" )
			end
			Set_XSCRIPT_ScriptID(890713)
			Set_XSCRIPT_Parameter(0,0)
			Set_XSCRIPT_Parameter(1,0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 108) then
		Clear_XSCRIPT()
			if g_FairShopindex2 < 0 then
				Set_XSCRIPT_Function_Name( "FairBuyItem" )
				Set_XSCRIPT_ScriptID(890713)
				Set_XSCRIPT_Parameter(0, g_FairShopindex)
				Set_XSCRIPT_Parameter(1, g_FairShopshowid)
				Set_XSCRIPT_Parameter(2, g_FairShopitemIdx)
				Set_XSCRIPT_Parameter(3, 0)
				Set_XSCRIPT_Parameter(4, 1)
				Set_XSCRIPT_Parameter(5, 0)
				Set_XSCRIPT_ParamCount(6)
			else
				Set_XSCRIPT_Function_Name( "BigFairShopBuyItem" )
				Set_XSCRIPT_ScriptID(890713)
				Set_XSCRIPT_Parameter(0, g_FairShopindex)
				Set_XSCRIPT_Parameter(1, g_FairShopindex2)
				Set_XSCRIPT_Parameter(2, g_FairShopitemIdx)
				Set_XSCRIPT_Parameter(3, 0)
				Set_XSCRIPT_Parameter(4, 1)
				Set_XSCRIPT_Parameter(5, 0)
				Set_XSCRIPT_ParamCount(6)
			end
		Send_XSCRIPT()
	elseif (g_iYesNoType == 109) then
		-- 执行脚本
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetGiftsForXinChunFanLi_Exch" ); 	-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 892981 );				-- 脚本编号 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])			     -- 第几档
			Set_XSCRIPT_Parameter(1,1)			    		 -- 确认
			Set_XSCRIPT_ParamCount( 2 );					-- 参数个数
		Send_XSCRIPT()
	elseif (g_iYesNoType == 110) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetAward" )
			Set_XSCRIPT_ScriptID(893021)
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(2,g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(3,1)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT() 
	elseif (g_iYesNoType == 111) then--2018Q4春节引导任务--龙凤和鸣礼盒
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyFashionLiHe" )
			Set_XSCRIPT_ScriptID(893008)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 112) then
		PlayerPackage:IdentifyConfirm(g_MessageBoxSelf2_Data[1],g_MessageBoxSelf2_Data[2])
	elseif (g_iYesNoType == 113) then
		PushEvent("BIEYEFURNITUREREMOVECOMFIRM", 1)	
	elseif (g_iYesNoType == 114) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExitFuBen" )
			Set_XSCRIPT_ScriptID(893065) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 115) then
		if g_MessageBoxSelf2_Data[2] == 1 then
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnStartZhiBu" )
			Set_XSCRIPT_ScriptID(893070) 
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif g_MessageBoxSelf2_Data[2] == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnOpenZhiBu" )
				Set_XSCRIPT_ScriptID(893070) 
				Set_XSCRIPT_Parameter(0,-1)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()			
		end
	elseif (g_iYesNoType == 116) then
			PushEvent("MSZJ_CONFIRM")
	elseif (g_iYesNoType == 117) then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "BuyFashionGift" )
				Set_XSCRIPT_ScriptID(893058) 
				--Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
				Set_XSCRIPT_Parameter(0,1)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()		 
	elseif (g_iYesNoType == 118) then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "BuyZhenShouLong" )
				Set_XSCRIPT_ScriptID(893058) 
				--Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
				Set_XSCRIPT_Parameter(0,1)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()		
	elseif (g_iYesNoType == 119) then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnBuyItem" )
				Set_XSCRIPT_ScriptID(893087) 
				Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
				Set_XSCRIPT_Parameter(1,1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()	
	elseif (g_iYesNoType == 120) then
			Clear_XSCRIPT()
				if g_zdzyhidx == 1 then
					Set_XSCRIPT_Function_Name( "OnChooseLeft" )
				else
					Set_XSCRIPT_Function_Name( "OnChooseRight" )
				end
				Set_XSCRIPT_ScriptID(893085) 
				Set_XSCRIPT_Parameter(0,0)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()	
	elseif (g_iYesNoType == 121) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExitFuBen" )
			Set_XSCRIPT_ScriptID(893089) 
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 122) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnExchangeZhenYuan" )
			Set_XSCRIPT_ScriptID(889907)
			Set_XSCRIPT_Parameter(0, g_targetId) 
			Set_XSCRIPT_Parameter(1, g_itemidx) 
			Set_XSCRIPT_Parameter(2, 0) 
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 123) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangeReward" )
			Set_XSCRIPT_ScriptID(505083)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]) 
			Set_XSCRIPT_Parameter(2, 1) 
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 124) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "YuanBaoBuy" )
			Set_XSCRIPT_ScriptID(505083)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]) 
			Set_XSCRIPT_Parameter(2, 1) 
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 125) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangeLiHe" )
			Set_XSCRIPT_ScriptID(505083)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
			Set_XSCRIPT_Parameter(1, 1) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 126) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetDayAward" )
			Set_XSCRIPT_ScriptID(893126)
			Set_XSCRIPT_Parameter(0, 1) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 127) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "HunFuLevelup" )
			Set_XSCRIPT_ScriptID(893126)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]) 
			Set_XSCRIPT_Parameter(2, 1) 
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 128) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "HunFuLevelup" )
			Set_XSCRIPT_ScriptID(893126)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]) 
			Set_XSCRIPT_Parameter(2, 2) 
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()			
	elseif (g_iYesNoType == 129) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetRiceCake" )
			Set_XSCRIPT_ScriptID( 893151 )
			Set_XSCRIPT_Parameter(0, g_nTagertid) 
			Set_XSCRIPT_Parameter(1, 0) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()				
	elseif (g_iYesNoType == 130) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetPrize" )
			Set_XSCRIPT_ScriptID( 893151 )
			Set_XSCRIPT_Parameter(0, g_nTagertid) 
			Set_XSCRIPT_Parameter(1, 0) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()		
		
	elseif (g_iYesNoType == 131) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoExchange" )
			Set_XSCRIPT_ScriptID(893155)
			Set_XSCRIPT_Parameter(0, 1) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()

	elseif (g_iYesNoType == 132) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "JoinMemberShip" )
			Set_XSCRIPT_ScriptID(893166)
			Set_XSCRIPT_Parameter(0, 1) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	

	elseif (g_iYesNoType == 133) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "NatiaonalShopBuy" )
			Set_XSCRIPT_ScriptID(893158)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]) 
			Set_XSCRIPT_Parameter(2, 0) 
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 134) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnDefaultEvent" )
			Set_XSCRIPT_ScriptID(893163)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
			Set_XSCRIPT_Parameter(1, 1) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 135) then	

		local nActType = g_MessageBoxSelf2_Data[1]
		local bComfirmed = g_MessageBoxSelf2_Data[2]
		local bComfirmedQuickBuyUseYB = g_MessageBoxSelf2_Data[3]

		-- 优先处理是否启用快捷元宝激活二次确认逻辑 只有bComfirmedQuickBuyUseYB为0是申请是否启用快捷元宝激活的二次确认
		if 0 == bComfirmedQuickBuyUseYB then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "AskActRMBReward" )
				Set_XSCRIPT_ScriptID(790029)
				Set_XSCRIPT_Parameter(0, nActType) 
				Set_XSCRIPT_Parameter(1, bComfirmed) 
				Set_XSCRIPT_Parameter(2, 1) 
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "AskActRMBReward" )
				Set_XSCRIPT_ScriptID(790029)
				Set_XSCRIPT_Parameter(0, nActType) 
				Set_XSCRIPT_Parameter(1, 1) 
				Set_XSCRIPT_Parameter(2, bComfirmedQuickBuyUseYB) 
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		end	

	elseif (g_iYesNoType == 136) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "NatiaonalShopCutReally" )
			Set_XSCRIPT_ScriptID(893158)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 137) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "JieBanRelieve" )
			Set_XSCRIPT_ScriptID(893195)
			Set_XSCRIPT_Parameter(0, 1) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 138) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangeReward" )
			Set_XSCRIPT_ScriptID(893196)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]) 
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3]) 
			Set_XSCRIPT_Parameter(3, 1) 
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 139) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnMyUseItemLogic" )
			Set_XSCRIPT_ScriptID(790024)
			Set_XSCRIPT_Parameter(0, 1) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 140) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnActivateConform" )
			Set_XSCRIPT_ScriptID(893262)
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 	
	elseif (g_iYesNoType == 141) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnYouChuan" )
			Set_XSCRIPT_ScriptID(000555)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 	
	elseif (g_iYesNoType == 207) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ConfirmGuanjing" )
			Set_XSCRIPT_ScriptID(888707)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 	
	elseif (g_iYesNoType == 208) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ConfirmSingleGuanjing" )
			Set_XSCRIPT_ScriptID(888707)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 	
		
	elseif (g_iYesNoType == 142) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnTangQuan" )
			Set_XSCRIPT_ScriptID(000556)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()

	elseif (g_iYesNoType == 146) then
		if g_MessageBoxSelf2_Data[2] == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnYouChuan")
				Set_XSCRIPT_ScriptID(893354)
				Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
				Set_XSCRIPT_Parameter(1, 1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		elseif g_MessageBoxSelf2_Data[2] == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnYouDeng")
				Set_XSCRIPT_ScriptID(893353)
				Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
				Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[3])
				Set_XSCRIPT_Parameter(2, 1)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		elseif g_MessageBoxSelf2_Data[2] == 3 or g_MessageBoxSelf2_Data[2] == 4 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnDengGao")
				Set_XSCRIPT_ScriptID(998342)
				Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
				Set_XSCRIPT_Parameter(1, 1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		end
	elseif (g_iYesNoType == 147) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyItem" )
			Set_XSCRIPT_ScriptID(893372) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 148) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyItem1" )
			Set_XSCRIPT_ScriptID(893375) 
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 149) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyItem2" )
			Set_XSCRIPT_ScriptID(893375) 
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 150) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyItem3" )
			Set_XSCRIPT_ScriptID(893375) 
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 151) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "FairGetFanLi" )
			Set_XSCRIPT_ScriptID(890713)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, 0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 152) then
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnActivateAfterConform" )
			Set_XSCRIPT_ScriptID(g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
 		
	elseif (g_iYesNoType == 153) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AnniPreExchangeDB" )
			Set_XSCRIPT_ScriptID(893401)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT() 			
	elseif (g_iYesNoType == 154) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AnniPreExchangeItem" )
			Set_XSCRIPT_ScriptID(893401)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT() 			
	elseif (g_iYesNoType == 155) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnActivateAfterConform" )
			Set_XSCRIPT_ScriptID(g_nScriptid)
			Set_XSCRIPT_Parameter(0,g_nbagIndex)
			Set_XSCRIPT_Parameter(1,g_nTagertid)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 	
	elseif (g_iYesNoType == 156) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnActivateAfterConform" )
			Set_XSCRIPT_ScriptID(g_nScriptid)
			Set_XSCRIPT_Parameter(0,g_nbagIndex)
			Set_XSCRIPT_Parameter(1,g_nTagertid)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 	
	elseif (g_iYesNoType == 157) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyFashion" )
			Set_XSCRIPT_ScriptID(892595) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2,g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3,1)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()		 
	elseif (g_iYesNoType == 158) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyFangSongItem" )
			Set_XSCRIPT_ScriptID(808110)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT() 	
	elseif g_iYesNoType == 159 then
		MessageBox_Self2_OK_159()
	elseif g_iYesNoType == 160 then
		MessageBox_Self2_OK_160()
 		
	elseif (g_iYesNoType == 161) then		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoBuyQiFuBi" )
			Set_XSCRIPT_ScriptID( 893403 )
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()

	elseif (g_iYesNoType == 162) then
		Clear_XSCRIPT()
			if (g_MessageBoxSelf2_Data[2] <= 0) then
				Set_XSCRIPT_Function_Name( "CreateBoss" )
				Set_XSCRIPT_ScriptID( 893416 )
			else
				Set_XSCRIPT_Function_Name( "CreateBoss_GaiBang" )
				Set_XSCRIPT_ScriptID( 893430 )
			end
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 163) then
		Clear_XSCRIPT()
			if (g_MessageBoxSelf2_Data[2] <= 0) then
				Set_XSCRIPT_Function_Name( "CreateBoss" )
				Set_XSCRIPT_ScriptID( 893415 )
			else
				Set_XSCRIPT_Function_Name( "CreateBoss_TaoHuaDao" )
				Set_XSCRIPT_ScriptID( 893430 )
			end
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 164) then
		Clear_XSCRIPT()
			if (g_MessageBoxSelf2_Data[2] <= 0) then
				Set_XSCRIPT_Function_Name( "CreateBoss" )
				Set_XSCRIPT_ScriptID( 893413 )
			else
				Set_XSCRIPT_Function_Name( "CreateBoss_RenOu" )
				Set_XSCRIPT_ScriptID( 893430 )
			end
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 165) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetGift" )
			Set_XSCRIPT_ScriptID( 893412 )
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 166) then
		PushEvent("XZ_ONBUY", -1, g_MessageBoxSelf2_Data[2], 0, g_MessageBoxSelf2_Data[3], 0)
		
	elseif (g_iYesNoType == 167) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyLiHe" )
			Set_XSCRIPT_ScriptID(888077)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
		
	elseif (g_iYesNoType == 168) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnActivateAfterConform" )
			Set_XSCRIPT_ScriptID(g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		
	--elseif (g_iYesNoType == 169) then	
		--Clear_XSCRIPT()
		--	Set_XSCRIPT_Function_Name("OnPray")
		--	Set_XSCRIPT_ScriptID(891920)
		--	Set_XSCRIPT_Parameter(0, 1)
		--	Set_XSCRIPT_ParamCount(1)
		--Send_XSCRIPT()
		
	elseif (g_iYesNoType == 170) then	
		Clear_XSCRIPT()
			--Set_XSCRIPT_Function_Name( "OnDuiHuanItem" )
			Set_XSCRIPT_Function_Name( "OnDuiHuanFashion" )
			Set_XSCRIPT_ScriptID(888082)
			Set_XSCRIPT_Parameter(0, 0) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 171) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ExchangeItem")
			Set_XSCRIPT_ScriptID(888089)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[4])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(3, 1)
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 172) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetShanHaiBi")
			Set_XSCRIPT_ScriptID(888090)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	 
	elseif (g_iYesNoType == 173) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetXinJueTongPoint")
			Set_XSCRIPT_ScriptID(888095)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 174) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskAddProgress")
			Set_XSCRIPT_ScriptID(790029)
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[0]) --addnum
			Set_XSCRIPT_Parameter(1,0) 		--needcomfirm
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()		
	elseif (g_iYesNoType == 175) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItemConfirm" )
			Set_XSCRIPT_ScriptID(892458) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 176) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyItem" )
			Set_XSCRIPT_ScriptID(898104) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		
	elseif (g_iYesNoType == 177) then
		PushEvent("DFS_WTEAM_DISMISS_CONFIRM")

	elseif (g_iYesNoType == 178) then
		PushEvent("DFS_WTEAM_KICK_MEMBER_CONFIRM")

	elseif (g_iYesNoType == 179) then
		PushEvent("DFS_WTEAM_MEMBER_LEAVE_CONFIRM")
	
	elseif (g_iYesNoType == 180) then
		DFS:WTeamOper_RetInvite(g_PrenticeGUID, 1)
	elseif (g_iYesNoType == 181) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyLibao")
			Set_XSCRIPT_ScriptID(888143)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 182) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DoExchange")
			Set_XSCRIPT_ScriptID(888143)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3, 1)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 187) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ClientActivateOnce" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 888187 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, tonumber( g_MessageBoxSelf2_Data[1] ) );		-- 参数一 玩法 
     		Set_XSCRIPT_Parameter( 1, 1 );																		-- 是否确认
     		Set_XSCRIPT_ParamCount( 2 );												-- 参数个数  
     	Send_XSCRIPT()	
	elseif (g_iYesNoType == 188) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ClientActivateOnce" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 888188 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, tonumber( g_MessageBoxSelf2_Data[1] ) );		-- 参数一 玩法 
     		Set_XSCRIPT_Parameter( 1, 1 );																		-- 是否确认
     		Set_XSCRIPT_ParamCount( 2 );												-- 参数个数  
     	Send_XSCRIPT()
  elseif (g_iYesNoType == 189) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ClientActivateOnce" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( g_MessageBoxSelf2_Data[2] );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, tonumber( g_MessageBoxSelf2_Data[1] ) );		-- 参数一 玩法 
     		Set_XSCRIPT_Parameter( 1, 1 );																		-- 是否确认
     		Set_XSCRIPT_ParamCount( 2 );												-- 参数个数  
     	Send_XSCRIPT()
	elseif (g_iYesNoType == 190) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnActivateAfterConfirm" )
			Set_XSCRIPT_ScriptID(888211)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 191) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "LingQuGiftNormal" )
			Set_XSCRIPT_ScriptID(888212)
			Set_XSCRIPT_Parameter(0, g_nTagertid)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 192) then

  	elseif (g_iYesNoType == 193) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "DoMakeForFree" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 888205 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一 玩法 
     		Set_XSCRIPT_ParamCount( 1 );												-- 参数个数  
     	Send_XSCRIPT()
  	elseif (g_iYesNoType == 194) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "DoMakeProtect" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 888205 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一 玩法 
     		Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
		Send_XSCRIPT()		
	elseif (g_iYesNoType == 195) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ComposeItem" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 888304 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1] );		-- 参数一  
			Set_XSCRIPT_Parameter( 1, g_MessageBoxSelf2_Data[2] );		-- 参数一  
     		Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
		Send_XSCRIPT()		
	elseif (g_iYesNoType == 196) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SelectMount");
			Set_XSCRIPT_ScriptID(888263);
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);--索引1-6
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]);--背包位置
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
		if IsWindowShow("JnhReward") then
			CloseWindow("JnhReward")
		end	
	elseif (g_iYesNoType == 197) then
     	-- 执行脚本
     	-- Clear_XSCRIPT()
     		-- Set_XSCRIPT_Function_Name( "BuyVipRestroom" ); 					-- 脚本函数名称
     		-- Set_XSCRIPT_ScriptID( 888314 );											-- 脚本编号 
     		-- Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1] );		-- 参数一  
			-- Set_XSCRIPT_Parameter( 1, 1 );		-- 参数一  确认
     		-- Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
		-- Send_XSCRIPT()	
	elseif (g_iYesNoType == 198) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ResignByItem" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 891106 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1] );		-- 参数一   
     		Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
		Send_XSCRIPT()
	elseif (g_iYesNoType == 199) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ResignByYB" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 891106 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1] );		-- 参数一  
			Set_XSCRIPT_Parameter( 1, 1 ); 
     		Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 200) then	
     	-- 执行脚本
     	if g_MessageBoxSelf2_Data[1] == 891447 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ConfirmAcceptKey")
				Set_XSCRIPT_ScriptID(g_MessageBoxSelf2_Data[1])
				Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[2])
				Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[3])
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ConfirmAcceptKey")
				Set_XSCRIPT_ScriptID(g_MessageBoxSelf2_Data[1])
				Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[2])
				Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[3])
				Set_XSCRIPT_Parameter(2,g_MessageBoxSelf2_Data[4])
				Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()		
		end
	elseif (g_iYesNoType == 201) then
		-- 确认全部保存
		Exterior:LuaFnSaveExteriorAllChange(0)
	elseif (g_iYesNoType == 202) then
		-- PushEvent("EXTERIOR_INFANT_CONFIRM", 2)
		Exterior:LuaFnSaveInfantExteriorAllChange(0)
	elseif (g_iYesNoType == 203) then
		Exterior:LuaFnExteriorFashionOperation(g_MessageBoxSelf2_Data[1], g_MessageBoxSelf2_Data[2], g_MessageBoxSelf2_Data[3], g_MessageBoxSelf2_Data[4])
	elseif  (g_iYesNoType == 204) then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGiveMessage")
		Set_XSCRIPT_ScriptID(888380)
		Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
		Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[2])
		Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		
	elseif  (g_iYesNoType == 205) then
		PushEvent("GOUWUCHE_SUBMIT_CONFIRM")
	elseif (g_iYesNoType == 206) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "OnByItem" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 888435 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1] );		-- 参数一  
			Set_XSCRIPT_Parameter( 1, g_MessageBoxSelf2_Data[2] );		-- 参数一  
			Set_XSCRIPT_Parameter( 2, g_MessageBoxSelf2_Data[3] );		-- 参数一  
			Set_XSCRIPT_Parameter( 3, 1 );		-- 参数一  确认
     		Set_XSCRIPT_ParamCount( 4 ); 	-- 参数个数  
		Send_XSCRIPT()			
	elseif (g_iYesNoType == 209) then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "changejinfengye" )
			Set_XSCRIPT_ScriptID(892890)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 	
	elseif (g_iYesNoType == 210) then	
     	-- 执行脚本
    Clear_XSCRIPT()
     	Set_XSCRIPT_Function_Name( "OnOpenFuli" )
			Set_XSCRIPT_ScriptID( 610020 )
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])		--FuliType
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[2])		--nParam
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 211) then	
		-- 执行脚本
   		Clear_XSCRIPT()
		   Set_XSCRIPT_Function_Name( "DoBuyLianYunLiHe" )
		   Set_XSCRIPT_ScriptID( 888777 )
		   Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
		   Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
		   Set_XSCRIPT_ParamCount(2)
	   	Send_XSCRIPT()
	elseif (g_iYesNoType == 212) then	
		-- 执行脚本
   		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoBuyLianBiLiHe" )
		   Set_XSCRIPT_ScriptID( 888777 )
		   Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
		   Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
		   Set_XSCRIPT_ParamCount(2)
	   	Send_XSCRIPT()
	elseif (g_iYesNoType == 213) then
		-- 执行脚本
		Clear_XSCRIPT()
		   Set_XSCRIPT_Function_Name( "Junior_BuyItem" )
		   Set_XSCRIPT_ScriptID( 888765 )
		   Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
		   Set_XSCRIPT_Parameter(1, 1)
		   Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 214) then
		-- 执行脚本
		Clear_XSCRIPT()
		   Set_XSCRIPT_Function_Name( "UseItem" )
		   Set_XSCRIPT_ScriptID( 893450 )
		   Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[2])
		   Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 215) then
		-- 执行脚本
		Clear_XSCRIPT()
		   Set_XSCRIPT_Function_Name( "UseItem" )
		   Set_XSCRIPT_ScriptID( g_MessageBoxSelf2_Data[3] )
		   Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[2])
		   Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 216) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ExChangeNewZhanLing" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 790029 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一  
     		Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
		Send_XSCRIPT()		
	elseif (g_iYesNoType == 217) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "Buy" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 888886 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一  
     		Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 218) then	 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyGift" ); 					-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 888922 );											-- 脚本编号
			Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1]);	   
			Set_XSCRIPT_Parameter( 1, g_MessageBoxSelf2_Data[2]);	   
			Set_XSCRIPT_Parameter( 2, 1);	 
			Set_XSCRIPT_ParamCount( 3 ); 	-- 参数个数  
		Send_XSCRIPT()
	elseif (g_iYesNoType == 219) then	 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoGetHuaHuanReward" ); 					-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 888930 );											-- 脚本编号
			Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1])	   
			Set_XSCRIPT_ParamCount( 1 ) 	-- 参数个数  
		Send_XSCRIPT()
	elseif (g_iYesNoType == 220) then	 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "StartZhumeng" ); 					-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 888965 );											-- 脚本编号
			Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1])	   
			 Set_XSCRIPT_Parameter( 1, 1);
			Set_XSCRIPT_ParamCount( 2 ) 	-- 参数个数  
		Send_XSCRIPT()
	elseif (g_iYesNoType == 221) then	 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetZhumengReward" ); 					-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 888965 );											-- 脚本编号	   
			Set_XSCRIPT_Parameter( 0, 1);
			Set_XSCRIPT_ParamCount( 1 ) 	-- 参数个数  
		Send_XSCRIPT()
	elseif (g_iYesNoType == 222) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyFangSongItem" )
			Set_XSCRIPT_ScriptID(808112)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT() 	
	elseif (g_iYesNoType == 223) then		
		Clear_XSCRIPT()
    		Set_XSCRIPT_Function_Name( "BuyGift" ); 					-- 脚本函数名称
    		Set_XSCRIPT_ScriptID( 888928 );	
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
    		Set_XSCRIPT_Parameter(1, 1);	 
    		Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数 
		Send_XSCRIPT() 
	elseif (g_iYesNoType == 224) then
		-- 执行脚本
		Clear_XSCRIPT()
		   Set_XSCRIPT_Function_Name( "Junior_ManualRefresh" )
		   Set_XSCRIPT_ScriptID( 888765 )
		   Set_XSCRIPT_Parameter(0, 1)
		   Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 225) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnLevelupLock")
			Set_XSCRIPT_ScriptID(800801)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 226) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetAward")
			Set_XSCRIPT_ScriptID(998040)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 227) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("LeaveRestRoom")
			Set_XSCRIPT_ScriptID(998041)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 228) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ChangeReward")
			Set_XSCRIPT_ScriptID(998017)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 229) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ChangeReward")
			Set_XSCRIPT_ScriptID(998017)
			Set_XSCRIPT_Parameter(0, 0)
			Set_XSCRIPT_Parameter(1, 2)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 230) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("CreateNPC")
			Set_XSCRIPT_ScriptID(998103)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif (g_iYesNoType == 231) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DoResign")
			Set_XSCRIPT_ScriptID(998172)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, 0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 232) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItem" ); 					-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 889833 );											-- 脚本编号 
			Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1] );
			Set_XSCRIPT_Parameter( 1, g_MessageBoxSelf2_Data[2] );
			Set_XSCRIPT_Parameter( 2, g_MessageBoxSelf2_Data[3] );
			Set_XSCRIPT_Parameter( 3, 1 );
			Set_XSCRIPT_Parameter( 4, g_MessageBoxSelf2_Data[4] );
			Set_XSCRIPT_ParamCount( 5 ); 	-- 参数个数
		Send_XSCRIPT()
	elseif (g_iYesNoType == 234) then
		if g_MessageBoxSelf2_Data[3] == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "VerifySubmitTeamCondition" ); 				-- 脚本函数名称
				Set_XSCRIPT_ScriptID( 998215 );											-- 脚本编号 
				Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1] )	
				Set_XSCRIPT_Parameter( 1, g_MessageBoxSelf2_Data[2] )		
				Set_XSCRIPT_Parameter( 2, 0 )     	 
				Set_XSCRIPT_ParamCount( 3 ); 	-- 参数个数
			Send_XSCRIPT()
		elseif g_MessageBoxSelf2_Data[3] == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "VerifySubmitTeamCondition" ); 				-- 脚本函数名称
				Set_XSCRIPT_ScriptID( 998254 );											-- 脚本编号 
				Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1] )	
				Set_XSCRIPT_Parameter( 1, g_MessageBoxSelf2_Data[2] )		
				Set_XSCRIPT_Parameter( 2, 0 )     	 
				Set_XSCRIPT_ParamCount( 3 ); 	-- 参数个数
			Send_XSCRIPT()
		end
	elseif (g_iYesNoType == 235) then		
		PushEvent("CLOSE_EXTERIOR_YIRONGGE", 0, g_MessageBoxSelf2_Data[1])	
	elseif g_iYesNoType == 236 then		
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(555001)
			Set_XSCRIPT_Function_Name("UnderArmourJewelCompound")
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif g_iYesNoType == 237 then		
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(555001)
			Set_XSCRIPT_Function_Name("UnderArmourPlateTransfer")
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3, 1)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif g_iYesNoType == 238 then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(555001)
			Set_XSCRIPT_Function_Name("UnderArmourPlateRankTransfer")
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3, 1)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif g_iYesNoType == 239 then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(555001)
			Set_XSCRIPT_Function_Name("UnderArmourSwitch")
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 240) then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Function_Name("ClientActivateOnce")
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 241) then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Function_Name("ClientActivateOnce")
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 242) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetTree")
			Set_XSCRIPT_ScriptID(998225)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 1) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 243) then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Function_Name("UseItem")
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 244) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuySP" )
			Set_XSCRIPT_ScriptID(998199) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 255) then
		local funcName = nil
		if (g_MessageBoxSelf2_Data[1] == 1) then
			funcName = "GetAward_XiaoJingYanDan_Confirmed"
		elseif (g_MessageBoxSelf2_Data[1] == 2) then
			funcName = "GetAward_DaJingYanDan_Confirmed"
		elseif (g_MessageBoxSelf2_Data[1] == 3) then
			funcName = "GetAward_XiaoWuYiDan_Confirmed"
		elseif (g_MessageBoxSelf2_Data[1] == 4) then
			funcName = "GetAward_DaWuYiDan_Confirmed"
		end

		if (funcName ~= nil) then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name(funcName)
				Set_XSCRIPT_ScriptID(998314) 
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()
		end
	elseif (g_iYesNoType == 256) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoBind" )
			Set_XSCRIPT_ScriptID(998356) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[2])
			if g_MessageBoxSelf2_Data[3] == 0 then
				Set_XSCRIPT_Parameter(2,1)
			elseif g_MessageBoxSelf2_Data[3] == 1 then
				Set_XSCRIPT_Parameter(2,2)
			end
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 257) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "PlayerAbandonFlag" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 998429 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一  
     		Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 258) then	
		-- 执行脚本
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "KaiKaSecComfrimed" ); 					-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 998434 );											-- 脚本编号 
			Set_XSCRIPT_Parameter( 0, g_MessageBoxSelf2_Data[1] );		-- 参数一  
			Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
	   Send_XSCRIPT()	
	elseif (g_iYesNoType == 259) then		
		Clear_XSCRIPT()
    		Set_XSCRIPT_Function_Name( "GetMaiDianGift" ); 					-- 脚本函数名称
    		Set_XSCRIPT_ScriptID( 888928 );	
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]) 
    		Set_XSCRIPT_Parameter(1, 1);	 
    		Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数 
		Send_XSCRIPT()  
	elseif (g_iYesNoType == 260) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItemConfirm" )
			Set_XSCRIPT_ScriptID(998470) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 261) then
		Exterior:LuaFnDoDressTransform(g_MessageBoxSelf2_Data[1])

	elseif (g_iYesNoType == 262) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ClientActivateOnce" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 998548 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, tonumber( g_MessageBoxSelf2_Data[1] ) );		-- 参数一 玩法 
     		Set_XSCRIPT_Parameter( 1, 1 );																		-- 是否确认
     		Set_XSCRIPT_ParamCount( 2 );												-- 参数个数  
     	Send_XSCRIPT()
		
	elseif (g_iYesNoType == 263) then
		Exterior:LuaFnSaveExteriorShareInfo(g_MessageBoxSelf2_Data[1]-1)
	elseif (g_iYesNoType == 264) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "DoRefreshOnce" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 998574 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, 0 );																		-- 是否确认
     		Set_XSCRIPT_ParamCount( 1 );												-- 参数个数  
     	Send_XSCRIPT()
	elseif (g_iYesNoType == 265) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "BuyItem" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 998574 );	
			Set_XSCRIPT_Parameter( 0,g_MessageBoxSelf2_Data[1])										-- 脚本编号 
     		Set_XSCRIPT_Parameter( 1, 0 );																		-- 是否确认
     		Set_XSCRIPT_ParamCount( 2 );												-- 参数个数  
		 Send_XSCRIPT()
	elseif (g_iYesNoType == 266) then	
     	-- 执行脚本
     	Clear_XSCRIPT()
     		Set_XSCRIPT_Function_Name( "ClientActivateOnce" ); 					-- 脚本函数名称
     		Set_XSCRIPT_ScriptID( 998605 );											-- 脚本编号 
     		Set_XSCRIPT_Parameter( 0, tonumber( g_MessageBoxSelf2_Data[1] ) );		-- 参数一 玩法 
     		Set_XSCRIPT_Parameter( 1, 1 );																		-- 是否确认
     		Set_XSCRIPT_ParamCount( 2 );												-- 参数个数  
     	Send_XSCRIPT()
	elseif (g_iYesNoType == 267) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItemConfirm" )
			Set_XSCRIPT_ScriptID(998609) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 268) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItem" )
			Set_XSCRIPT_ScriptID(998611) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2,g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3,g_MessageBoxSelf2_Data[4])
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()

		PushEvent("UPDATE_ZONGMEN_SHOPINFO", "on_cancle")
	elseif (g_iYesNoType == 270) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "HighZongMenExpAdd" )
			Set_XSCRIPT_ScriptID(998901) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT() 
	elseif (g_iYesNoType == 271) then
		Clear_XSCRIPT()
    		Set_XSCRIPT_Function_Name("BuLing") -- 脚本函数名称
    		Set_XSCRIPT_ScriptID(892939) 		-- 脚本编号
    		Set_XSCRIPT_Parameter(0, 1) 		-- 是否
    		Set_XSCRIPT_ParamCount(1) 			-- 参数个数
    	Send_XSCRIPT() 
	elseif (g_iYesNoType == 272) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ChongZhuDaZaoCancel");
			Set_XSCRIPT_ScriptID(998847);
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();	
	elseif (g_iYesNoType == 273) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ReceiveDaZaoEquipConfirm");
			Set_XSCRIPT_ScriptID(998847);
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();	
	elseif (g_iYesNoType == 274) then
		if g_MessageBoxSelf2_Data[2] == 0 then
			Player:Lua_AskSectOper(1,g_MessageBoxSelf2_Data[1])
		else
			Player:SaveShareSect(g_MessageBoxSelf2_Data[1])
		end
	elseif (g_iYesNoType == 275) then
		-- if DataPool:GetSectIsBackLevel(g_MessageBoxSelf2_Data[1]) == 1 then
		-- 	PushEvent("SECT_SAVEPLAN_CONFIRM", g_MessageBoxSelf2_Data[1])
		-- else
		-- 	Player:Lua_AskSectOper(1,g_MessageBoxSelf2_Data[1])
		-- end
		PushEvent("SECT_MODIFYTOSAVE", g_MessageBoxSelf2_Data[2], g_MessageBoxSelf2_Data[3])
	elseif (g_iYesNoType == 277) then
		PushEvent("TRADE_CONFIRMED")
		
	elseif (g_iYesNoType == 278) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "FairBuyItemByDBYB" )
			Set_XSCRIPT_ScriptID(890713)
			Set_XSCRIPT_Parameter(0, g_FairShopindex)
			Set_XSCRIPT_Parameter(1, g_FairShopshowid)
			Set_XSCRIPT_Parameter(2, g_FairShopitemIdx)
			Set_XSCRIPT_Parameter(3, g_FairShopindex2)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 279) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("GetHuoyueDaibi");
			Set_XSCRIPT_ScriptID(998968);
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);
			Set_XSCRIPT_Parameter(1, 0);
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();	
	elseif (g_iYesNoType == 280) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("BuyConfirm");
			Set_XSCRIPT_ScriptID(998968);
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]);
			Set_XSCRIPT_Parameter(2, 0);
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();	
	--2024春节时装获取
	elseif (g_iYesNoType == 281) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetPrize" )
			Set_XSCRIPT_ScriptID( 998897 )			
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 282) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItemConfirm" )
			Set_XSCRIPT_ScriptID( 999101 )		
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 283) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyLiHe" )
			Set_XSCRIPT_ScriptID(999299)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 284) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnCommonShopBuyByDBYB" )
			Set_XSCRIPT_ScriptID(892921)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]);	
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3]);	
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 285) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientAskLeave" )
			Set_XSCRIPT_ScriptID(051128)
			Set_XSCRIPT_Parameter(0, 1);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 286) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyDailyShopLiBao" )
			Set_XSCRIPT_ScriptID(999360)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_Parameter(1, 1);	
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 287) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DrawOnce" )
			Set_XSCRIPT_ScriptID(999441)
			Set_XSCRIPT_Parameter(0, 1);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 288) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DrawTenTimes" )
			Set_XSCRIPT_ScriptID(999441)
			Set_XSCRIPT_Parameter(0, 1);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 289) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyCJDaibi" )
			Set_XSCRIPT_ScriptID(999441)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_Parameter(1, 0);
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()			
	elseif (g_iYesNoType == 290) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AskGetAward" )
			Set_XSCRIPT_ScriptID(331106)
			Set_XSCRIPT_Parameter(0, 1);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 291) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ConfirmGuanjing" )
			Set_XSCRIPT_ScriptID(999445)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]);
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 292) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ConfirmGuanjing" )
			Set_XSCRIPT_ScriptID(999446)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]);
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 293) then
		if TLCJ:IsInTLCJScene() > 0 then
			if TLCJ:IsInTLCJScene_Team() > 0 then
					Set_XSCRIPT_Function_Name( "ClientAskLeave" )
					Set_XSCRIPT_ScriptID(999337)
					Set_XSCRIPT_Parameter(0, 1);	
					Set_XSCRIPT_ParamCount(1)
				Send_XSCRIPT()	
			else
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name( "ClientAskLeave" )
					Set_XSCRIPT_ScriptID(999321)
					Set_XSCRIPT_Parameter(0, 1);	
					Set_XSCRIPT_ParamCount(1)
				Send_XSCRIPT()	
			end
		end

	elseif (g_iYesNoType == 294) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "PlayerUseGameItem" )
			Set_XSCRIPT_ScriptID(331105)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_Parameter(1, 1);	
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 295) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "PlayerGo" )
			Set_XSCRIPT_ScriptID(331105)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]);	
			Set_XSCRIPT_Parameter(2, 1);	
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 296) then
		Pet : SetPetExpLock(g_MessageBoxSelf2_Data[1]);
	elseif (g_iYesNoType == 297) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DressExchange" )
			Set_XSCRIPT_ScriptID(999441)
			Set_XSCRIPT_Parameter(0, 1);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 298) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuySnowCJDaibi" )
			Set_XSCRIPT_ScriptID(999501)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0);	
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 299) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ConfirmGiveQKL")
			Set_XSCRIPT_ScriptID(g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 300) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ConfirmGiveShuiPiao")
			Set_XSCRIPT_ScriptID(g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 301) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnGoBackToCityConfirem" )
			Set_XSCRIPT_ScriptID(331141)
			Set_XSCRIPT_Parameter(0, 1);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 302) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientActivateOnceFree" )
			Set_XSCRIPT_ScriptID(999549)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0);	
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif (g_iYesNoType == 303) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientActivateOnceBuy" )
			Set_XSCRIPT_ScriptID(999549)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0);	
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_iYesNoType == 306 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ActiveJiuWei")
			Set_XSCRIPT_ScriptID(889822)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		this:Hide()
	elseif (g_iYesNoType == 305) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItemConfirm" )
			Set_XSCRIPT_ScriptID( 999553 )		
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 307) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ConfirmAttachPlayer" )
			Set_XSCRIPT_ScriptID( g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif (308 == g_iYesNoType) then
		-- 新6v6 邀请玩家入队
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Team_CCallBack_InviteConfirm")
			Set_XSCRIPT_ScriptID(999554)	
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(3, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif (309 == g_iYesNoType) then
		-- 新6v6 解散战队
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Team_CCallBack_DismissConfirm")
			Set_XSCRIPT_ScriptID(999554)	
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (310 == g_iYesNoType) then
		-- 新6v6 退出战队
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Team_CCallBack_QuitConfirm")
			Set_XSCRIPT_ScriptID(999554)	
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif 311 == g_iYesNoType  then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnBuyWeekShopItem")
			Set_XSCRIPT_ScriptID(999632)	
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3, 1)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()	
	elseif 312 == g_iYesNoType  then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenZhenBaoGe")
			Set_XSCRIPT_ScriptID(999633)	
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 313) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItemConfirm" )
			Set_XSCRIPT_ScriptID( 999697 )		
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 314) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientUseItem")
			Set_XSCRIPT_ScriptID(999693)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif 315 == g_iYesNoType then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnUpItem" )
			Set_XSCRIPT_ScriptID( 999710 )		
			Set_XSCRIPT_Parameter(0, 1)	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif 316 == g_iYesNoType then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnReciveItem" )
			Set_XSCRIPT_ScriptID( 999710 )		
			Set_XSCRIPT_Parameter(0, 1)	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	

	elseif 317 == g_iYesNoType then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GuildAuctionUnderItem")
			Set_XSCRIPT_ScriptID(999710)	
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3, g_MessageBoxSelf2_Data[4])
			Set_XSCRIPT_Parameter(4, 1)
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	elseif 318 == g_iYesNoType then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("XinFuSheJiaoConfirm")
			Set_XSCRIPT_ScriptID(888177)	
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif 319 == g_iYesNoType then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("LevelUpTo120")
			Set_XSCRIPT_ScriptID(999739)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif 320 == g_iYesNoType then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("buyitem")
			Set_XSCRIPT_ScriptID(999767)	
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(3, g_MessageBoxSelf2_Data[4])
			Set_XSCRIPT_Parameter(4, 1)
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 321) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItemConfirm" )
			Set_XSCRIPT_ScriptID( 999781 )		
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 322) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ActiveSpecial" )
			Set_XSCRIPT_ScriptID( 999782 )		
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 323) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnGetWorldItemStore" )
			Set_XSCRIPT_ScriptID( 999785 )		
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_Parameter(1, 1);
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 324) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItemConfirm" )
			Set_XSCRIPT_ScriptID( 999791 )		
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]);		
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 325) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnGoBackToCityConfirem" )
			Set_XSCRIPT_ScriptID(331180)
			Set_XSCRIPT_Parameter(0, 1);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 326) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnIncreWorldItemStore" )
			Set_XSCRIPT_ScriptID(999785)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_Parameter(1, 1);
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 327) then
		Clear_XSCRIPT();
	      	Set_XSCRIPT_Function_Name("OnContinueCheck");
		    Set_XSCRIPT_ScriptID(002115);
        	Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);
        	Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2]);
        	Set_XSCRIPT_Parameter(2, 1);
        	Set_XSCRIPT_Parameter(3, 1);
			Set_XSCRIPT_ParamCount(4);
   	 	Send_XSCRIPT();
	elseif (g_iYesNoType == 328) then
		Clear_XSCRIPT();
	      	Set_XSCRIPT_Function_Name("FairBuyItemByJZYB");
		    Set_XSCRIPT_ScriptID(890713);
        	Set_XSCRIPT_Parameter(0, g_FairShopindex);
			Set_XSCRIPT_Parameter(1, g_FairShopshowid)
			Set_XSCRIPT_Parameter(2, g_FairShopitemIdx)
        	Set_XSCRIPT_Parameter(3, g_FairShopindex2);
			Set_XSCRIPT_ParamCount(4);
		Send_XSCRIPT();
	elseif (g_iYesNoType == 329) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GameFailed")
			Set_XSCRIPT_ScriptID(999822)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])		
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 330) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyLiHe" )
			Set_XSCRIPT_ScriptID(885559)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 331) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "TribeCreate" )
			Set_XSCRIPT_ScriptID(885568)
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 332) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "TribeAddMember" )
			Set_XSCRIPT_ScriptID(885568)
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 333) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "TribeDecMember" )
			Set_XSCRIPT_ScriptID(885568)
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 334) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyDaiBi" )
			Set_XSCRIPT_ScriptID(999841)
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_iYesNoType == 335 then
		GuildZhanTuanUI:LuaFnGuildZhanTuanAppointConfirm()
	elseif (g_iYesNoType == 336) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyItemConfirm" )
			Set_XSCRIPT_ScriptID( 885576 )		
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1]);	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (g_iYesNoType == 337) then		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnQiXiShopExchange")
			Set_XSCRIPT_ScriptID(893777)
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		end
end

function MessageBox_Self2_Cancel_Clicked()
	if (g_iYesNoType == 51) then
		PushEvent("CORPS_INVITE_MEMBER", g_PrenticeGUID, 0)
	end
	if (g_iYesNoType == 83) then
		CorpsUI_2018:CorpsOper_InviteAnswer(g_PrenticeGUID, 2) --1是同意 2是拒绝
	end
	
	if (g_iYesNoType == 91) then
		PushEvent("JINFENGMIZANG_CANCEL", 0)
	end
	
	if (g_iYesNoType == 100) then
	-- 执行脚本
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "CancelSignContact" ); 	-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 892939 );				-- 脚本编号
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1] )  				-- 索引  
			Set_XSCRIPT_ParamCount(1)					-- 参数个数 
		Send_XSCRIPT() 	 
	end
	
	if (g_iYesNoType == 106) then
		BWDH2018:WTeamOper_RetInvite(g_PrenticeGUID, 0) --1是同意 0是拒绝
	end
	
	if (g_iYesNoType == 180) then
		DFS:WTeamOper_RetInvite(g_PrenticeGUID, 0)	
	end
	
	if (g_iYesNoType == 256) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "CancelBind" )
			Set_XSCRIPT_ScriptID(998356) 
			Set_XSCRIPT_Parameter(0,g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1,g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	end

	if (g_iYesNoType == 268) then
		PushEvent("UPDATE_ZONGMEN_SHOPINFO", "on_cancle")
	end

	if (g_iYesNoType == 307) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ConfirmAttachPlayer" )
			Set_XSCRIPT_ScriptID( g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(2, 0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end

	-- if (g_iYesNoType == 275) then
	-- 	PushEvent("SECT_MODIFYTOSAVE", g_MessageBoxSelf2_Data[2])
	-- end
	if (308 == g_iYesNoType) then
		-- 新6v6 邀请玩家入队
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Team_CCallBack_InviteConfirm")
			Set_XSCRIPT_ScriptID(999554)	
			Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_Parameter(2, g_MessageBoxSelf2_Data[2])
			Set_XSCRIPT_Parameter(3, g_MessageBoxSelf2_Data[3])
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()	
	end		
	this:Hide()
end

function  MessageBox_Self2_UpdateRect()
	local nWidth, nHeight = MessageBox_Self2_Text:GetWindowSize();
	local nTitleHeight = 23;
	local nBottomHeight = 25;
	local nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	MessageBox_Self2_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end

function MessageBox_Self2_Frame_OnHiden()
	DataPool:SetCanUseHotKey(1)
end



function MessageBox_Self2_CloseDownTick()
	if g_iYesNoType == 48 then
		KillTimer("MessageBox_Self2_CloseDownTick()");
		this:Hide();
	end
end

function MessageBox_Self2_OK_159()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Pet_ChangeModel")
		Set_XSCRIPT_ScriptID(800124)
		Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
		Set_XSCRIPT_Parameter(1, g_MessageBoxSelf2_Data[2])
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function MessageBox_Self2_SkillCardRecycle_Confirm()
	
	local item_table_index = PlayerPackage:GetItemTableIndex(g_MessageBoxSelf2_Data[1])	
	local nSkillCardID, chip_type, chip_count = DataPool:LuaFnGetSkillCardRecycleInfo(item_table_index)
	local nUnLocked = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "UnLocked")
	local nQuality = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Quality")
	local strName = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Name")
	local strNameColor = ""
	
	if nQuality == 1 then
		strNameColor = "#G"
	elseif nQuality == 2 then
		strNameColor = "#B"
	elseif nQuality == 3 then
		strNameColor = "#cbe38ff"
	elseif nQuality == 4 then
		strNameColor = "#cfff965"
	end
	
	local strTemp = ""
	if nUnLocked == 1 then		
		if chip_type == 3 then
			strTemp = ScriptGlobal_Format("#{XZJC_200309_295}", tostring(strNameColor..strName), tostring(chip_count), "#{XZJC_200309_262}")
		elseif chip_type == 4 then
			strTemp = ScriptGlobal_Format("#{XZJC_200309_295}", tostring(strNameColor..strName), tostring(chip_count), "#{XZJC_200309_261}")
		end		
	else
		if chip_type == 3 then
			strTemp = ScriptGlobal_Format("#{XZJC_200309_296}", tostring(strNameColor..strName), tostring(chip_count), "#{XZJC_200309_262}")
		elseif chip_type == 4 then
			strTemp = ScriptGlobal_Format("#{XZJC_200309_296}", tostring(strNameColor..strName), tostring(chip_count), "#{XZJC_200309_261}")
		end	
	end
	MessageBox_Self2_Text:SetText(strTemp)
	MessageBox_Self2_OK_Button:Show()
	MessageBox_Self2_Cancel_Button:Show()
	
end

function MessageBox_Self2_OK_160()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("RecycleCard")
		Set_XSCRIPT_ScriptID(888555)
		Set_XSCRIPT_Parameter(0, g_MessageBoxSelf2_Data[1])
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function MessageBox_Self2_UnderArmourPlateTransferConfirm()
	g_iYesNoType = 237
	
	local bag_index_a = g_MessageBoxSelf2_Data[2]
	local bag_index_b = g_MessageBoxSelf2_Data[3]
	
	local item_table_index_a = PlayerPackage:GetItemTableIndex(bag_index_a)
	local item_table_index_b = PlayerPackage:GetItemTableIndex(bag_index_b)
	
	local name_a = DataPool:Lua_GetItemNameByIndex(item_table_index_a)
	local name_b = DataPool:Lua_GetItemNameByIndex(item_table_index_b)
	
	local strTemp = ""
	if g_MessageBoxSelf2_Data[4] == 1 then
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_278}", name_a, name_b)
	else
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_279}", name_a, name_b)
	end
	
	MessageBox_Self2_Text:SetText(strTemp)
	MessageBox_Self2_OK_Button:Show()
	MessageBox_Self2_Cancel_Button:Show()
	MessageBox_Self2_UpdateRect()
	this:Show()
end

function MessageBox_Self2_UnderArmourPlateRankTransferConfirm()
	g_iYesNoType = 238
	
	local bag_index_a = g_MessageBoxSelf2_Data[2]
	local bag_index_b = g_MessageBoxSelf2_Data[3]
	
	local item_table_index_a = PlayerPackage:GetItemTableIndex(bag_index_a)
	local item_table_index_b = PlayerPackage:GetItemTableIndex(bag_index_b)
	
	local name_a = DataPool:Lua_GetItemNameByIndex(item_table_index_a)
	local name_b = DataPool:Lua_GetItemNameByIndex(item_table_index_b)
	
	local strTemp = ""
	if g_MessageBoxSelf2_Data[4] == 1 then
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_287}", name_a, name_b)
	else
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_288}", name_a, name_b)
	end
	
	MessageBox_Self2_Text:SetText(strTemp)
	MessageBox_Self2_OK_Button:Show()
	MessageBox_Self2_Cancel_Button:Show()
	MessageBox_Self2_UpdateRect()
	this:Show()
end

function MessageBox_Self2_UnderArmourSwitchConfirm()
	g_iYesNoType = 239	
	MessageBox_Self2_Text:SetText("#{NJBZ_220816_123}")
	MessageBox_Self2_OK_Button:Show()
	MessageBox_Self2_Cancel_Button:Show()
	MessageBox_Self2_UpdateRect()
	this:Show()
end

function MessageBox_Self2_ActiveJiuWeiConfirm()
	g_iYesNoType = 306
	MessageBox_Self2_Text:SetText("#{JWFT_231115_1}")
	MessageBox_Self2_OK_Button:Show()
	MessageBox_Self2_Cancel_Button:Show()
	MessageBox_Self2_UpdateRect()
	this:Show()
end
