local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;
local g_uicmd = 0;
local g_cardId = -1;

local g_NewbieCardActivation_Frame_UnifiedXPosition;
local g_NewbieCardActivation_Frame_UnifiedYPosition;

function NewbieCardActivation_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OBJECT_CARED_EVENT",true);
	this:RegisterEvent("NewUserCard_Check_Result",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NewbieCardActivation_OnLoad()
g_NewbieCardActivation_Frame_UnifiedXPosition	= NewbieCardActivation_Frame:GetProperty("UnifiedXPosition");
g_NewbieCardActivation_Frame_UnifiedYPosition	= NewbieCardActivation_Frame:GetProperty("UnifiedYPosition");
end

function NewbieCardActivation_OnEvent(event)
	if(event == "UI_COMMAND" and not this:IsVisible()) then
		if tonumber(arg0) == 2004 or tonumber(arg0) == 20080819 or tonumber(arg0) == 2005 or tonumber(arg0) == 2006
			or tonumber(arg0) == 2007 or tonumber(arg0) == 2008 or tonumber(arg0) == 2007950 or tonumber(arg0) == 20090714
			or tonumber(arg0) == 20090819
			or tonumber(arg0) == 20090828
			or tonumber(arg0) == 20100118	--1888财富卡
			or tonumber(arg0) == 20100301	--技嘉财富卡
			or tonumber(arg0) == 20100707	--17173卡
			or tonumber(arg0) == 20101021	--AMDVIP卡
			or tonumber(arg0) == 20101028   --畅游金卡
			or tonumber(arg0) == 20110215	--多玩VIP卡
			or tonumber(arg0) == 20110303	--至尊公会卡
			or tonumber(arg0) == 20110917	--2888武圣卡	--[YuanPeiLong, 20110917, 激活武圣卡输入卡号的弹窗]	
			or tonumber(arg0) == 20110926	--天龙翔龙卡	--[YuanPeiLong, 20110926, 翔龙卡]
			or tonumber(arg0) == 20111009	--天龙3新17173卡	--[lianhuan， 20111009]
			or tonumber(arg0) == 20111010	--天龙3新至尊工会卡	--[lianhuan,  20111010]
			or tonumber(arg0) == 20111230	--游久武圣卡	-- Add By YPL, 2011-12-30
			or tonumber(arg0) == 20120315	--腾讯专属武圣卡	
			or tonumber(arg0) == 20130725 --微信达人卡
			or tonumber(arg0) == 20130925 --移动天龙推广活动激活码
		then
			objCared = Get_XParam_INT(0);
			g_cardId = Get_XParam_INT(1);
			objCared = Target:GetServerId2ClientId(objCared);
			NewUserCard_SetText(tonumber(arg0));
			this:CareObject(objCared, 1, "NewUserCard");
			NewbieCardActivation_Input:SetProperty("DefaultEditBox", "True");
			this:Show();
			g_uicmd = tonumber(arg0);
		end
	elseif(event == "OBJECT_CARED_EVENT") then
		--AxTrace(0, 0, "arg0:"..arg0.." arg1:"..arg1.." arg2:"..arg2.." objCared:"..objCared);
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			Guild_Create_Close();
		end

	elseif(event == "NewUserCard_Check_Result")then
		local result = tonumber(arg0)
		if(tonumber(arg0)== 0) then
			NewUserCard_Close();
			return;
		end
		if(tonumber(arg0)== 1 or tonumber(arg0)== 2) then
			NewbieCardActivation_Input:SetProperty("DefaultEditBox", "True");
			NewbieCardActivation_Input:SetSelected( 0, -1 );
			return;
		end
	elseif( event == "ADJEST_UI_POS" ) then
		NewbieCardActivation_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		NewbieCardActivation_ResetPos()

	end

end

--移动天龙兑换激活码特殊处理
function NewUserCard_YDPrize_OpenClick(cardNum)
	--判断
	local len = string.len(cardNum)
	if len <= 0 or len > 20 then 
		return
	end
	--兑换
	-- YDNewUserCard(cardNum,g_cardId,g_uicmd)
	--Clear_XSCRIPT();
	--Set_XSCRIPT_Function_Name("OpenCard");
	--Set_XSCRIPT_ScriptID(890615);
	--Set_XSCRIPT_Parameter(0,objCared);
	--Set_XSCRIPT_Parameter(1,g_uicmd);
	--Set_XSCRIPT_Parameter(2,cardNum);
	--Set_XSCRIPT_ParamCount(3);
	--Send_XSCRIPT();
	--关闭界面
	NewUserCard_Close();
end

function NewUserCard_Open_Click()
	local cardNum = NewbieCardActivation_Input:GetText();
	if(0 == string.len(cardNum)) then return; end
	--移动天龙兑换激活码特殊处理
	if g_uicmd == 20130925 then
		-- NewUserCard_YDPrize_OpenClick(cardNum)
		return
	end
--王晔华：以后新加物品卡的时候，请模仿SNS卡那样写，给客户端脚本传来cardId，脚本号：809301
--不可以再模仿天龙千里卡、时尚卡、鸭嘴兽卡的做法，使用龚彩云那里的通用脚本打开卡号输入界面，因为这样的做法无法被物品互斥表CardRule.txt所兼容
--此处是没有办法对这3种卡进行兼容，所以仍然保留了原来的做法。
--以后新加非物品卡的时候，参照1888卡即可。TT68738
	local firstbyte = string.byte(cardNum)
	local secondbyte = string.sub(cardNum, 2, 2)

	-- 天龙千里卡 天龙时尚卡 卡号大写提示
	if (g_uicmd == 2006 and firstbyte == 90 ) then
		PushDebugMessage("#{CFK_081027_1}");
		return;
	end

	-- 天龙鸭嘴兽卡 卡号大写提示
	if (g_uicmd == 2006 and firstbyte == 82 ) then
		PushDebugMessage("#{CFK_081027_1}");
		return;
	end
	
	--在CardRule.txe中检查卡的类型
	--当结果为大于或则等于1
	--流程为CA的协议
	
	if g_cardId ~= -1 then
		if CheckCardType(g_cardId) == 1 then
			-- PassportCard(cardNum,g_cardId)
			return;
		end
	end

	NewUserCard(cardNum,g_cardId,0)	--参数3: 0为物品卡, 1为财富卡

end

function NewUserCard_Close()
	this:Hide();
	this:CareObject(objCared, 0, "NewUserCard");
	g_uicmd = 0;
end

function NewUserCard_SetText(uicmd)
	if uicmd == 2004 then
		NewbieCardActivation_DragTitle:SetText("#{INTERFACE_XML_73}");
		NewbieCardActivation_Text:SetText("#{INTERFACE_XML_536}");
	elseif uicmd == 20080819 then--666财富卡
		NewbieCardActivation_DragTitle:SetText("#{INTERFACE_XML_73}");
		NewbieCardActivation_Text:SetText("#{INTERFACE_XML_536}");
	elseif uicmd == 2005 then
		NewbieCardActivation_DragTitle:SetText("激活");
		NewbieCardActivation_Text:SetText("请在下面的输入框内输入您获得的CD-Key");
	elseif uicmd == 2006 then
		NewbieCardActivation_DragTitle:SetText("#{CJ_20080321_01}");
		NewbieCardActivation_Text:SetText("#{CJ_20080321_02}");
	elseif uicmd == 2007 then
		NewbieCardActivation_DragTitle:SetText("激活");
		NewbieCardActivation_Text:SetText("请在下面的输入框内输入您获得的CD-Key");
	elseif uicmd == 2008 then
		NewbieCardActivation_DragTitle:SetText("激活");
		NewbieCardActivation_Text:SetText("请在下面的输入框内输入您获得的CD-Key");
	elseif uicmd == 2007950 then
		NewbieCardActivation_DragTitle:SetText("#{CB_XUBAO_LINGQU_2}");
		NewbieCardActivation_Text:SetText("#{CB_XUBAO_LINGQU_3}");
	elseif uicmd == 20090714 then--活动已经停止
		NewbieCardActivation_DragTitle:SetText("#{SNS_XML_05}");
		NewbieCardActivation_Text:SetText("#{SNS_XML_06}");
	elseif uicmd == 20090819 then -- 飞信贵宾卡
		NewbieCardActivation_DragTitle:SetText("#{FXHZ_XML_1}");
		NewbieCardActivation_Text:SetText("#{FXHZ_xml_XX(08)}");
	elseif uicmd == 20090828 then--瑞星贵宾卡
		NewbieCardActivation_DragTitle:SetText("#{RXCFK_XML_5}");
		NewbieCardActivation_Text:SetText("#{RXCFK_XML_3}");
	elseif uicmd == 20100118 then--1888卡
		NewbieCardActivation_DragTitle:SetText("#{TLYXT_XML_23}");
		NewbieCardActivation_Text:SetText("#{TLYXT_XML_24}");
	elseif uicmd == 20100301 then--技嘉卡
		NewbieCardActivation_DragTitle:SetText("#{JJTQK_XML_10}");
		NewbieCardActivation_Text:SetText("#{JJTQK_XML_11}");
	elseif uicmd == 20100707 then--17173卡
		NewbieCardActivation_DragTitle:SetText("#{TLYXT_100707_05}");
		NewbieCardActivation_Text:SetText("#{TLYXT_100707_06}");
	elseif uicmd == 20101021 then --AMDVIP卡
		NewbieCardActivation_DragTitle:SetText("#{AMDCFK_101021_13}");
		NewbieCardActivation_Text:SetText("#{AMDCFK_101021_14}");
	elseif uicmd == 20101028 then--畅游金卡
		NewbieCardActivation_DragTitle:SetText("#{CYJK_101027_08}");
		NewbieCardActivation_Text:SetText("#{CYJK_101027_09}");
	elseif uicmd == 20110215 then--多玩VIP卡
		NewbieCardActivation_DragTitle:SetText("#{DWTQK_110216_12}");
		NewbieCardActivation_Text:SetText("#{DWTQK_110216_13}");
	elseif uicmd == 20110303 then--至尊公会卡
		NewbieCardActivation_DragTitle:SetText("#{ZZGHK_110302_08}");
		NewbieCardActivation_Text:SetText("#{ZZGHK_110302_09}");
	--[YuanPeiLong, 20110917, 2888武圣卡输入卡号弹窗显示的文字]
	elseif uicmd == 20110917 then--2888武圣卡
		NewbieCardActivation_DragTitle:SetText("#{WSK_110913_09}");
		NewbieCardActivation_Text:SetText("#{WSK_110913_10}");
	--End		
	--[YuanPeiLong, 20110926, 翔龙卡]
	elseif uicmd == 20110926 then
		NewbieCardActivation_DragTitle:SetText("#{HLK_110926_07}");	
		NewbieCardActivation_Text:SetText("#{HLK_110926_08}");
	--end	
	--[lianhuan,天龙3新17173、至尊工会卡]
	elseif uicmd == 20111009 then
		NewbieCardActivation_DragTitle:SetText("#{XHZK_111010_08}");	
		NewbieCardActivation_Text:SetText("#{XHZK_111010_09}");
	elseif uicmd == 20111010 then
		NewbieCardActivation_DragTitle:SetText("#{XGHK_111010_06}");	
		NewbieCardActivation_Text:SetText("#{XGHK_111010_07}");
	--Start Add By YPL, 2011-12-30  游久专属武圣卡
	elseif uicmd == 20111230 then
		NewbieCardActivation_DragTitle:SetText("#{JYZSWS_111230_07}");	
		NewbieCardActivation_Text:SetText("#{JYZSWS_111230_08}");
	--End	Add By YPL, 2011-12-30  游久专属武圣卡		
	elseif uicmd == 20120315 then	--腾讯专属武圣卡	
		NewbieCardActivation_DragTitle:SetText("#{ZSWSK_210312_07}");	
		NewbieCardActivation_Text:SetText("#{ZSWSK_210312_08}");
	elseif uicmd == 20130925 then	--移动天龙推广活动激活码
		NewbieCardActivation_DragTitle:SetText("#{YDTL_130924_05}");	
		NewbieCardActivation_Text:SetText("#{YDTL_130924_06}");
	end
	
	if uicmd == 20130725 then	--微信达人卡
		NewbieCardActivation_DragTitle:SetText("#{ZSWSK_210729_01}");	
		NewbieCardActivation_Text:SetText("#{ZSWSK_210729_02}");
	end

	NewbieCardActivation_Input:SetText("");
end

function NewbieCardActivation_ResetPos()
	NewbieCardActivation_Frame:SetProperty("UnifiedXPosition", g_NewbieCardActivation_Frame_UnifiedXPosition);
	NewbieCardActivation_Frame:SetProperty("UnifiedYPosition", g_NewbieCardActivation_Frame_UnifiedYPosition);

end
