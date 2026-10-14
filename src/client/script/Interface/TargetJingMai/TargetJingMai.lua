--TargetJingMai.lua
local OTHER_XUEWEI_LIST = {}
local OTHER_XUEWEI_LIST_NAN = {}

local OTHER_XUEWEI_SELECT = -1; --默认没有选中

local OTHER_XUEWEI_TAB_TEXT = {};

--设置经典版使用的图片资源

--穴位没有秘法时的图标(但激活)
local g_XueWei_Image_NoMifa =  "set:JingMaiUI image:JingMai_Anniu_Jihuo"
--穴位没有秘法时的图标(没激活)
local g_XueWei_Image_NoActive = "set:Button image:JingMai_Anniu_Weijihuo"
--穴位有秘法对应的图标
local g_XueWei_Image_Set = {
                              [0] = "set:JingMaiUI image:JingMai_Anniu_Huang",--天井
							  [1] = "set:JingMaiUI image:JingMai_Anniu_Huang",--阳池
							  [2] = "set:JingMaiUI image:JingMai_Anniu_Lan",--血海
							  [3] = "set:JingMaiUI image:JingMai_Anniu_Lan",--箕门
							  [4] = "set:JingMaiUI image:JingMai_Anniu_Hong",--气海
							  [5] = "set:JingMaiUI image:JingMai_Anniu_Lv",--神庭
							  [6] = "set:JingMaiUI image:JingMai_Anniu_Lv",--至阳
}

-- 界面的默认相对位置
local g_Ohter_XueWei_Frame_UnifiedXPosition;
local g_Other_XueWei_Frame_UnifiedYPosition;

local g_TargetJingMai_selectFY = 0--当前第几页经脉分页 0 1 2
local g_TargetJingMai_activeFY = 0--当前使用第几页分页 0 1 2
local g_TargetJingMai_FenyeBtn ={}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_TargetJingMai_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = ""},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = ""},
	[6] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = ""},
	[7] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = ""},
	[8] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = ""},
	[9] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = ""},
	[10] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = ""},
	[11] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = ""},
	[12] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = ""},
	[13] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = ""},
	[14] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = ""},
	[15] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = ""},
}

local g_TargetPageButton = {}
local g_TargetPageCount = 0
local g_TargetPageOrder = {}

function TargetJingMai_PreLoad()

	-- 打开界面
	this:RegisterEvent("OPEN_OTHERPLAYER_JINGMAI");

	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function TargetJingMai_OnLoad()
	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图片资源为唯美版资源
		--穴位有秘法对应的图标
		g_XueWei_Image_Set = {
                              [0] = "set:WM_Jingmai1 image:JingMai_Anniu_Huang",--天井
							  [1] = "set:WM_Jingmai1 image:JingMai_Anniu_Huang",--阳池
							  [2] = "set:WM_Jingmai1 image:JingMai_Anniu_Lan",--血海
							  [3] = "set:WM_Jingmai1 image:JingMai_Anniu_Lan",--箕门
							  [4] = "set:WM_Jingmai1 image:JingMai_Anniu_Hong",--气海
							  [5] = "set:WM_Jingmai1 image:JingMai_Anniu_Lv",--神庭
							  [6] = "set:WM_Jingmai1 image:JingMai_Anniu_Lv",--至阳
							}
		--穴位没有秘法时的图标(但激活)
		g_XueWei_Image_NoMifa =  "set:WM_Jingmai1 image:JingMai_Anniu_Jihuo"
		--穴位没有秘法时的图标(没激活)
		g_XueWei_Image_NoActive = "set:WM_Jingmai1 image:JingMai_Anniu_Weijihuo"
	end

	OTHER_XUEWEI_TAB_TEXT = {
		[0] = "装备",
		"资料",
		"秘籍",
		"珍兽",
		"骑乘",
		"经脉",
	};

	OTHER_XUEWEI_LIST[0] = TargetJingMai_TianJing --天井
	OTHER_XUEWEI_LIST[1] = TargetJingMai_YangChi --阳池
	OTHER_XUEWEI_LIST[2] = TargetJingMai_XueHai --血海
	OTHER_XUEWEI_LIST[3] = TargetJingMai_QiMen --箕门
	OTHER_XUEWEI_LIST[4] = TargetJingMai_TanZhong --檀中
	OTHER_XUEWEI_LIST[5] = TargetJingMai_ShenTing --神庭
	OTHER_XUEWEI_LIST[6] = TargetJingMai_RenZhong --人中

	-- 保存界面的默认相对位置
	g_Ohter_XueWei_Frame_UnifiedXPosition	= TargetJingMai_Frame : GetProperty("UnifiedXPosition");
	g_Other_XueWei_Frame_UnifiedYPosition	= TargetJingMai_Frame : GetProperty("UnifiedYPosition");

	--g_TargetJingMai_FenyeBtn = 
	--{
	--	[0] = TargetJingMai_FenYe1,
	--	[1] = TargetJingMai_FenYe2,
	--	[2] = TargetJingMai_FenYe3,
	--}
	--屏蔽
	TargetJingMai_Btn:Hide()
	
	g_TargetPageButton[1] = TargetJingMai_Equip
	g_TargetPageButton[2] = TargetJingMai_SelfData
	g_TargetPageButton[3] = TargetJingMai_Pet
	g_TargetPageButton[4] = TargetJingMai_Infant
	g_TargetPageButton[5] = TargetJingMai_Wuhun
	g_TargetPageButton[6] = TargetJingMai_Miji
	g_TargetPageButton[7] = TargetJingMai_ZhenYuan
	g_TargetPageButton[8] = TargetJingMai_JingMaiInfo
	g_TargetPageButton[9] = TargetJingMai_ShenDing
	g_TargetPageButton[10] = TargetJingMai_JueWei
	g_TargetPageButton[11] = TargetJingMai_BaoJian
	g_TargetPageButton[12] = TargetJingMai_WuYi
	g_TargetPageButton[13] = TargetJingMai_ShenQi
	g_TargetPageButton[14] = TargetJingMai_Armor
	g_TargetPageButton[15] = TargetJingMai_CangPin
	
end

-- OnEvent
function TargetJingMai_OnEvent(event)

	if ( event == "OPEN_OTHERPLAYER_JINGMAI" ) then

	    if(this:IsVisible()) then
			this:Hide();
			return;
		end

		if OTHER_XUEWEI_LIST_NAN[0] == nil then
			OTHER_XUEWEI_LIST_NAN[0] = TargetJingMai_NAN_TianJing --天井
			OTHER_XUEWEI_LIST_NAN[1] = TargetJingMai_NAN_YangChi --阳池
			OTHER_XUEWEI_LIST_NAN[2] = TargetJingMai_NAN_XueHai --血海
			OTHER_XUEWEI_LIST_NAN[3] = TargetJingMai_NAN_QiMen --箕门
			OTHER_XUEWEI_LIST_NAN[4] = TargetJingMai_NAN_TanZhong --檀中(现在是气海了)
			OTHER_XUEWEI_LIST_NAN[5] = TargetJingMai_NAN_ShenTing --神庭
			OTHER_XUEWEI_LIST_NAN[6] = TargetJingMai_NAN_RenZhong --人中(现在是至阳了)
		end
		if OTHER_XUEWEI_LIST[0] == nil then
			OTHER_XUEWEI_LIST[0] = TargetJingMai_TianJing --天井
			OTHER_XUEWEI_LIST[1] = TargetJingMai_YangChi --阳池
			OTHER_XUEWEI_LIST[2] = TargetJingMai_XueHai --血海
			OTHER_XUEWEI_LIST[3] = TargetJingMai_QiMen --箕门
			OTHER_XUEWEI_LIST[4] = TargetJingMai_TanZhong --檀中(现在是气海了)
			OTHER_XUEWEI_LIST[5] = TargetJingMai_ShenTing --神庭
			OTHER_XUEWEI_LIST[6] = TargetJingMai_RenZhong --人中(现在是至阳了)
		end

		local iSexy = Player:GeTargetSex()
		if iSexy == 1 then
			TargetJingMai_NAN_BEIJING1:Show();
			--TargetJingMai_NAN_BEIJING2:Show();

			TargetJingMai_BEIJING1:Hide()
			-- TargetJingMai_BEIJING2:Hide()

			TargetJingMai_NV_Head:Hide()
			TargetJingMai_Head:Show()

			for i=0,6 do
				OTHER_XUEWEI_LIST[i]:Hide()
				OTHER_XUEWEI_LIST_NAN[i]:Show()
			end
		else
			TargetJingMai_NAN_BEIJING1:Hide();
			--TargetJingMai_NAN_BEIJING2:Hide();

			TargetJingMai_BEIJING1:Show()
			-- TargetJingMai_BEIJING2:Show()

			TargetJingMai_NV_Head:Show()
			TargetJingMai_Head:Hide()

			for i=0,6 do
				OTHER_XUEWEI_LIST[i]:Show()
				OTHER_XUEWEI_LIST_NAN[i]:Hide()
			end
		end

		local obj_id = CachedTarget:GetData("NPCID", 1)
		if (type(obj_id) ~="number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		this:CareObject(obj_id , 1, "TargetJingMai")

	    local OtherUnionPos = Variable:GetVariable("OtherUnionPos");
	    if(OtherUnionPos ~= nil) then
		    TargetJingMai_Frame:SetProperty("UnifiedPosition", OtherUnionPos);
    	end

	    OTHER_XUEWEI_SELECT = -1;
		_,_,g_TargetJingMai_activeFY =Player:LuaFnGetOtherJMFYinfo()
		g_TargetJingMai_selectFY =g_TargetJingMai_activeFY

		TargetJingMai_UpdateJMFYBtnStat()
		Other_XueWei_SetSelectState()
		Other_XueWei_SetTabState()
		Other_XueWei_Update()
		TargetJingMai_ShowPage()
		this:Show();
	end

	if( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return;
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新经脉界面位置
		OtherJingMai_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新经脉界面位置
		OtherJingMai_Frame_On_ResetPos()
	end

end

function TargetJingMai_SelfEquip_Page_Switch()

	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame("other");
	this:Hide();
end

function TargetJingMai_Pet_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	SystemSetup:OpenPetFrame("other");
	this:Hide();
end

--神木王鼎
function TargetJingMai_TargetShenDing_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	local nLevel = CachedTarget:GetData("LEVEL",1);
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" );
	else
		local bRet = SystemSetup:OpenOtherShenDing();
		if bRet == 1 then
			this:Hide()
		end
	end	
end

function OtherJingMai_Ride_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	SystemSetup:OpenRidePage("other");
	this:Hide();
end

function TargetJingMai_SelfData_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1);

	SystemSetup:OpenPrivatePage("other")
	this:Hide();
end


function OtherJingMai_TargetJingMai_Page_Switch()
	TargetJingMai_JingMaiInfo:SetCheck(1)
end


function TargetJingMai_Wuhun_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
	this:Hide();
end

function TargetJingMai_ZhenYuan_Down()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetJingMai_TargetMiji_Down()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	this:Hide()
end

function Other_XueWei_SetTabState()
	TargetJingMai_Equip:SetCheck(0)
	TargetJingMai_SelfData:SetCheck(0)
	TargetJingMai_Miji:SetCheck(0)
	TargetJingMai_Pet:SetCheck(0)
	TargetJingMai_Wuhun:SetCheck(0)
	TargetJingMai_Ride:SetCheck(0)
	TargetJingMai_JingMaiInfo:SetCheck(1)
end


function OtherJingMai_XueWei_Clicked(nIndex)
	if(nIndex < 7 and nIndex >= 0) then
		local theAction = EnumAction(nIndex, "otherxueweiinfo")
		if(theAction:GetID() ~= 0) then
			OTHER_XUEWEI_SELECT = nIndex
			OTHER_XUEWEI_SELECTed_Update()
			Other_XueWei_SetSelectState()
		end
	end
end


function OtherJingMai_SetTabColor(idx)
	-- if(idx == nil or idx < 0 or idx > 5) then
		-- return;
	-- end

	-- --AxTrace(0,0,tostring(idx));
	-- local i = 0;
	-- local selColor = "#e010101#Y";
	-- local noselColor = "#e010101";
	-- local tab = {
								-- [0] = TargetJingMai_Equip,
								-- TargetJingMai_SelfData,
								-- TargetJingMai_Miji,
								-- TargetJingMai_Pet,
								-- TargetJingMai_Ride,
								-- TargetJingMai_JingMaiInfo,
							-- };

	-- while i < 6 do
		-- if(i == idx) then
			-- tab[i]:SetText(selColor..OTHER_XUEWEI_TAB_TEXT[i]);
		-- else
			-- tab[i]:SetText(noselColor..OTHER_XUEWEI_TAB_TEXT[i]);
		-- end
		-- i = i + 1;
	-- end
end
--===============================================
-- 更新
--===============================================
function Other_XueWei_Update()
	OtherJingMai_SetTabColor(5)
	local iSexy = Player:GeTargetSex()

	for i = 0, 6 do
		local theAction = EnumAction((g_TargetJingMai_selectFY*7)+i, "otherxueweiinfo")
		if(theAction:GetID() ~= 0) then
			if iSexy == 1 then
				OTHER_XUEWEI_LIST_NAN[i] : SetActionItem(theAction:GetID())
			else
				OTHER_XUEWEI_LIST[i] : SetActionItem(theAction:GetID())
			end
		end

		local MifaName = Player:GetOtherMifaInfo((g_TargetJingMai_selectFY*7)+i, "MifaName")
		if MifaName ~= nil then
			--说明该穴位有秘法
			if iSexy == 1 then
				OTHER_XUEWEI_LIST_NAN[i]:SetProperty("NormalImage", g_XueWei_Image_Set[i])
				OTHER_XUEWEI_LIST_NAN[i]:SetProperty("HoverImage", g_XueWei_Image_Set[i])
				OTHER_XUEWEI_LIST_NAN[i]:SetProperty("PushedImage", g_XueWei_Image_Set[i])
			else
				OTHER_XUEWEI_LIST[i]:SetProperty("NormalImage", g_XueWei_Image_Set[i])
				OTHER_XUEWEI_LIST[i]:SetProperty("HoverImage", g_XueWei_Image_Set[i])
				OTHER_XUEWEI_LIST[i]:SetProperty("PushedImage", g_XueWei_Image_Set[i])
			end
		else
			if iSexy == 1 then
				OTHER_XUEWEI_LIST_NAN[i]:SetProperty("NormalImage", g_XueWei_Image_NoMifa)
				OTHER_XUEWEI_LIST_NAN[i]:SetProperty("HoverImage", g_XueWei_Image_NoMifa)
				OTHER_XUEWEI_LIST_NAN[i]:SetProperty("PushedImage", g_XueWei_Image_NoMifa)
			else
				OTHER_XUEWEI_LIST[i]:SetProperty("NormalImage", g_XueWei_Image_NoMifa)
				OTHER_XUEWEI_LIST[i]:SetProperty("HoverImage", g_XueWei_Image_NoMifa)
				OTHER_XUEWEI_LIST[i]:SetProperty("PushedImage", g_XueWei_Image_NoMifa)
			end
		end
	end
    OTHER_XUEWEI_SELECTed_Update()
end

--===============================================
-- 选择穴位后刷新
--===============================================
function  OTHER_XUEWEI_SELECTed_Update()

	if OTHER_XUEWEI_SELECT < 0 or OTHER_XUEWEI_SELECT > 6 then
		TargetJingMai_MifaName:SetText("")
		TargetJingMai_Jinjiexiaoguo:SetText("#{MPJJ_XT_110705_05}")
		TargetJingMai_dis:SetText("#{MPJJ_XT_XML_02}")
		TargetJingMai_Item:SetProperty("Image", "")
		return
	end

	--根据选择获得秘法信息
	local MifaName = Player:GetOtherMifaInfo((g_TargetJingMai_selectFY*7)+OTHER_XUEWEI_SELECT, "MifaName")
	if MifaName == nil then
		--说明该穴位没有秘法
		TargetJingMai_MifaName:SetText("")
	else
		--设置秘法名字
		TargetJingMai_MifaName:SetText(MifaName)
	end

	--设置效果描述
	local MifaXiaoGuo = Player:GetOtherMifaInfo((g_TargetJingMai_selectFY*7)+OTHER_XUEWEI_SELECT, "MifaXiaoGuo")
	if MifaXiaoGuo ~= nil then
		TargetJingMai_Jinjiexiaoguo:SetText(MifaXiaoGuo)
	else
		TargetJingMai_Jinjiexiaoguo:SetText("#{MPJJ_XT_110705_05}")
	end

	local ZhengtiMiaosu = Player:GetOtherMifaInfo((g_TargetJingMai_selectFY*7)+OTHER_XUEWEI_SELECT, "XueWeiShuoMing")
	if ZhengtiMiaosu ~= nil then
		TargetJingMai_dis:SetText(ZhengtiMiaosu)
	else
		TargetJingMai_dis:SetText("#{MPJJ_XT_XML_02}")
	end

	--设置图标
	local IconName = Player:GetOtherMifaInfo((g_TargetJingMai_selectFY*7)+OTHER_XUEWEI_SELECT, "IconName")
	if IconName == nil then
		--说明该穴位没有秘法
		TargetJingMai_Item:SetProperty("Image", "")
	else
		--设置秘法技能图标
		local sPos, ePos = string.find(IconName, "_")
		if sPos ~= nil then
			local filename = string.sub(IconName, 0, sPos-1)
			local value = string.format("set:%s image:%s", filename, IconName)
			TargetJingMai_Item:SetProperty("Image", value)
		else
			TargetJingMai_Item:SetProperty("Image", "")
		end
	end

end
--===============================================
-- 设置穴位选中状态
--===============================================
function Other_XueWei_SetSelectState()
	local iSexy = Player:GeTargetSex()
  	for i=0, 6 do
  	  if(i == OTHER_XUEWEI_SELECT) then
		  if iSexy == 1 then
			OTHER_XUEWEI_LIST_NAN[i]:SetPushed(1)
		  else
			OTHER_XUEWEI_LIST[i]:SetPushed(1)
		  end
  	  else
		  if iSexy == 1 then
			OTHER_XUEWEI_LIST_NAN[i]:SetPushed(0)
		  else
			OTHER_XUEWEI_LIST[i]:SetPushed(0)
		  end
  	  end
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function OtherJingMai_Frame_On_ResetPos()


	TargetJingMai_Frame : SetProperty("UnifiedXPosition", g_Ohter_XueWei_Frame_UnifiedXPosition);
	TargetJingMai_Frame : SetProperty("UnifiedYPosition", g_Other_XueWei_Frame_UnifiedYPosition);

end

--===============================================
-- 关闭
--===============================================
function TargetJingMai_CloseUI()
		this:Hide()
end

function TargetJingMai_Infant_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetJingMai_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetJingMai_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

function TargetJingMai_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function TargetJingMai_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function TargetJingMai_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function TargetJingMai_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetJingMai_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end

function TargetJingMai_FenYe1_function()
	--g_TargetJingMai_selectFY = 0;
	--OTHER_XUEWEI_SELECT = -1;
	--TargetJingMai_UpdateJMFYBtnStat()
	--Other_XueWei_SetSelectState()
	--Other_XueWei_Update()
end

function TargetJingMai_FenYe2_function()
	--g_TargetJingMai_selectFY = 1;
	--OTHER_XUEWEI_SELECT = -1;
	--TargetJingMai_UpdateJMFYBtnStat()
	--Other_XueWei_SetSelectState()
	--Other_XueWei_Update()
end

function TargetJingMai_FenYe3_function()
	--g_TargetJingMai_selectFY = 2;
	--OTHER_XUEWEI_SELECT = -1;
	--TargetJingMai_UpdateJMFYBtnStat()
	--Other_XueWei_SetSelectState()
	--Other_XueWei_Update()
end

function TargetJingMai_UpdateJMFYBtnStat()--刷新一下三个经脉分页按钮 和 已使用按钮的状态
	--判断是否解锁
	local tJMFY2,tJMFY3,_ = Player:LuaFnGetOtherJMFYinfo()
	if tJMFY2 == 0 then--第二页没解锁
		--g_TargetJingMai_FenyeBtn[1]:Disable()
		if g_TargetJingMai_selectFY == 1 then--如果选中第二页，重新选中第一页
			g_TargetJingMai_selectFY = 0
		end
	else
		--g_TargetJingMai_FenyeBtn[1]:Enable()
	end
	if tJMFY3 == 0 then--第三页没解锁
		--g_TargetJingMai_FenyeBtn[2]:Disable()--如果选中第三页，重新选中第一页
		if g_TargetJingMai_selectFY == 2 then
			g_TargetJingMai_selectFY = 0
		end
	else
		--g_TargetJingMai_FenyeBtn[2]:Enable()
	end
	--g_TargetJingMai_FenyeBtn[0]:SetProperty("Selected", "False")
	--g_TargetJingMai_FenyeBtn[1]:SetProperty("Selected", "False")
	--g_TargetJingMai_FenyeBtn[2]:SetProperty("Selected", "False")
	--g_TargetJingMai_FenyeBtn[g_TargetJingMai_selectFY]:SetProperty("Selected", "True")
	if g_TargetJingMai_selectFY == g_TargetJingMai_activeFY then
		--TargetJingMai_Btn:Show()
		--TargetJingMai_Btn:SetText("#{JMQH_230829_36}")
		--TargetJingMai_Btn:Disable()
	else
		--TargetJingMai_Btn:Hide()
	end
	--要是第二页第三页都没解锁，默认使用第一页，那已使用的按钮就不显示了，跟原本功能保持一致
	if tJMFY2 == 0 and tJMFY3 == 0 then
		--TargetJingMai_Btn:Hide()
	end
end


function TargetJingMai_ShowPage()

	for i = 1, table.getn(g_TargetJingMai_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetJingMai_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetJingMai_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetJingMai_Page) do
		if TargetJingMai_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetJingMai_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetJingMai_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		TargetJingMai_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		TargetJingMai_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		TargetJingMai_Pet_Page_Switch()
	elseif idx == 4 then--子女
		TargetJingMai_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		TargetJingMai_Wuhun_Page_Switch()
	elseif idx == 6 then--秘籍
		TargetJingMai_TargetMiji_Down()
	elseif idx == 7 then--真元
		TargetJingMai_ZhenYuan_Down()
	elseif idx == 8 then--经脉
		--TargetWuhun_OtherJingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		TargetJingMai_TargetShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		TargetJingMai_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		TargetJingMai_OpenBaoJian()
	elseif idx == 12 then--武意
		TargetJingMai_OpenWuYi()
	elseif idx == 13 then--神器
		TargetJingMai_OpenShenQi()
	elseif idx == 14 then--星盘
		TargetJingMai_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetJingMai_CangPin_Page_Switch()
	end
end

function TargetJingMai_CheckPage(idx)
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 7 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 8 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 9 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	end
	return 0
end

function TargetJingMai_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


