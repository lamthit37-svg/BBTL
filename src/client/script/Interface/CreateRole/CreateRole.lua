----------------------------------------------------------------------------------------------------------------
--
-- 全局变量定义
--

-- 每一页中头像的个数.
local g_iFaceCountInPage = 9;

local g_iFaceIndexInPage = -1;         --by chengy TT52805

-- 当前选择的性别
local iCurSelSex = 0;			-- 0 : 女
													-- 1 : 男
													
local g_CreateRoleFistName="";
local g_CreateRoleLastName="";
local g_CreateRoleFirstNameIdx=-1;
local g_CreateRoleLastNameIdx=-1;

--脸形控件
local g_FaceSel = {};
--边框
local g_FaceBorder = {};
--当前选择的页数
local g_FacePageCount = 0;

-- 当前得到脸形的个数
local g_iCurFaceCount = 0;

-- 当前选择的头像的索引
local g_iCurSelFaceIndex = 0;

-- 当前选择的脸形
--local g_iCurSelFaceIndex    = 0;
local g_iCurSelFaceIndexOld = 0;

-- 当前选择的发型
local g_iCurSelHairIndex    = 0;
local g_iCurSelHairIndexOld = 0;

-- 当前选择的套装2006-6-2
local g_iCurSelEquipSetIndex    = 0;
local g_iCurSelEquipSetIndexOld = 0;

local MaxEquipIndex = 2

local g_FaceModel = {}
local g_iCurSelectFace = 0

--门派控件
local g_MenpaiButtonNum = 15--menpai15 
local g_MenpaiControl = {}
local g_MenpaiBgImageControl = {}
local g_MenpaiNormalImageList = {}
local g_MenpaiDisableImageList = {}

local g_MenpaiIntroduction = {}
local g_Ex_MenpaiIntroduction = {}

local g_DescriptionNum = 24--menpai15 
local g_Description = {}

local g_TempCurSel_MenPai = -1
 
-----------------------------------------------------------------------------------------------------------------
--
-- 函数定义
--

function LoginCreateRole_PreLoad()
	-- 打开界面
	this:RegisterEvent("GAMELOGIN_OPEN_CREATE_CHARACTOR",true);

	-- 关闭界面
	this:RegisterEvent("GAMELOGIN_CLOSE_CREATE_CHARACTOR",false);

	-- 清空创建角色名字。
	this:RegisterEvent("GAMELOGIN_CREATE_CLEAR_NAME",false);

	-- 取消预览
	this:RegisterEvent("GAMELOGIN_CANCEL_PREVIEW",false);
	
	this:RegisterEvent("RESHOW_CREATE_PLAYERNAME",false);

end

-- 注册onLoad事件
function LoginCreateRole_OnLoad()

	if SystemSetup:IsClassic() == 1 then
		CreateRole_SelectSex_Girl:SetText("女");
		CreateRole_SelectSex_Boy:SetText("男");
	end

	CreateRole_SelectSex_Girl:SetProperty("CheckMode", "1");
	CreateRole_SelectSex_Boy:SetProperty("CheckMode", "1");

	-- 头像选择按钮
	g_FaceSel[0] = CreateRole_Select_HeadImage1;
	g_FaceSel[1] = CreateRole_Select_HeadImage2;
	g_FaceSel[2] = CreateRole_Select_HeadImage3;
	g_FaceSel[3] = CreateRole_Select_HeadImage4;
	g_FaceSel[4] = CreateRole_Select_HeadImage5;
	g_FaceSel[5] = CreateRole_Select_HeadImage6;
	g_FaceSel[6] = CreateRole_Select_HeadImage7;
	g_FaceSel[7] = CreateRole_Select_HeadImage8;
	g_FaceSel[8] = CreateRole_Select_HeadImage9;

	-- 头像边框图片按钮
	g_FaceBorder[0] = CreateRole_Select_Head1;
	g_FaceBorder[1] = CreateRole_Select_Head2;
	g_FaceBorder[2] = CreateRole_Select_Head3;
	g_FaceBorder[3] = CreateRole_Select_Head4;
	g_FaceBorder[4] = CreateRole_Select_Head5;
	g_FaceBorder[5] = CreateRole_Select_Head6;
	g_FaceBorder[6] = CreateRole_Select_Head7;
	g_FaceBorder[7] = CreateRole_Select_Head8;
	g_FaceBorder[8] = CreateRole_Select_Head9;



	g_MenpaiControl[0] = CreateRole_MenpaiModel00;
	g_MenpaiControl[1] = CreateRole_MenpaiModel01;
	g_MenpaiControl[2] = CreateRole_MenpaiModel02;
	g_MenpaiControl[3] = CreateRole_MenpaiModel03;
	g_MenpaiControl[4] = CreateRole_MenpaiModel04;
	g_MenpaiControl[5] = CreateRole_MenpaiModel05;
	g_MenpaiControl[6] = CreateRole_MenpaiModel06;
	g_MenpaiControl[7] = CreateRole_MenpaiModel07;
	g_MenpaiControl[8] = CreateRole_MenpaiModel08;
	g_MenpaiControl[9] = CreateRole_MenpaiModel09;
	g_MenpaiControl[10] = CreateRole_MenpaiModel10;
	g_MenpaiControl[11] = CreateRole_MenpaiModel11;
	g_MenpaiControl[12] = CreateRole_MenpaiModel12;
	g_MenpaiControl[13] = CreateRole_MenpaiModel13; --桃花岛
	g_MenpaiControl[14] = CreateRole_MenpaiModel14;
	g_MenpaiControl[15] = CreateRole_MenpaiModel15;--menpai15 

	if SystemSetup:IsClassic() == 0 then	--唯美版的图片素材
		g_MenpaiDisableImageList[0] = "set:WM_Logon03 image:CreateRole_Button_Quxiaoyulan_Disable";
		g_MenpaiDisableImageList[1] = "set:WM_Logon12 image:Button_Shaolin_Pushed";
		g_MenpaiDisableImageList[2] = "set:WM_Logon12 image:Button_Mingjiao_Pushed";
		g_MenpaiDisableImageList[3] = "set:WM_Logon12 image:Button_Gaibang_Pushed";
		g_MenpaiDisableImageList[4] = "set:WM_Logon12 image:Button_Wudang_Pushed";
		g_MenpaiDisableImageList[5] = "set:WM_Logon12 image:Button_Emei_Pushed";
		g_MenpaiDisableImageList[6] = "set:WM_Logon12 image:Button_Xingxiu_Pushed";
		g_MenpaiDisableImageList[7] = "set:WM_Logon12 image:Button_Tianlong_Pushed";
		g_MenpaiDisableImageList[8] = "set:WM_Logon12 image:Button_Tianshan_Pushed";
		g_MenpaiDisableImageList[9] = "set:WM_Logon12 image:Button_Xiaoyao_Pushed" ;
		g_MenpaiDisableImageList[10] ="set:WM_Logon12 image:Button_Murong_Pushed";
		g_MenpaiDisableImageList[11] ="set:WM_Logon12 image:Button_Tangmen_Pushed";
		g_MenpaiDisableImageList[12] ="set:WM_Logon12 image:Button_Guigu_Pushed";
		g_MenpaiDisableImageList[13] ="set:WM_Logon12 image:Button_Guigu_Pushed";--桃花岛
		g_MenpaiDisableImageList[14] ="set:WM_Logon12 image:Button_Guigu_Pushed";
		g_MenpaiDisableImageList[15] ="set:WM_Logon12 image:Button_Guigu_Pushed";--menpai15

		g_MenpaiNormalImageList[0] = "set:WM_Logon03 image:CreateRole_Button_Quxiaoyulan_Normal";
		g_MenpaiNormalImageList[1] = "set:WM_Logon12 image:Button_Shaolin_Normal";
		g_MenpaiNormalImageList[2] = "set:WM_Logon12 image:Button_Mingjiao_Normal";
		g_MenpaiNormalImageList[3] = "set:WM_Logon12 image:Button_Gaibang_Normal";
		g_MenpaiNormalImageList[4] = "set:WM_Logon12 image:Button_Wudang_Normal";
		g_MenpaiNormalImageList[5] = "set:WM_Logon12 image:Button_Emei_Normal";
		g_MenpaiNormalImageList[6] = "set:WM_Logon12 image:Button_Xingxiu_Normal";
		g_MenpaiNormalImageList[7] = "set:WM_Logon12 image:Button_Tianlong_Normal";
		g_MenpaiNormalImageList[8] = "set:WM_Logon12 image:Button_Tianshan_Normal";
		g_MenpaiNormalImageList[9] = "set:WM_Logon12 image:Button_Xiaoyao_Normal" ;
		g_MenpaiNormalImageList[10] ="set:WM_Logon12 image:Button_Murong_Normal";
		g_MenpaiNormalImageList[11] ="set:WM_Logon12 image:Button_Tangmen_Normal";
		g_MenpaiNormalImageList[12] ="set:WM_Logon12 image:Button_Guigu_Normal";
		g_MenpaiNormalImageList[13] ="set:WM_Logon12 image:Button_Guigu_Normal";--桃花岛
		g_MenpaiNormalImageList[14] ="set:WM_Logon12 image:Button_Guigu_Normal";
		g_MenpaiNormalImageList[15] ="set:WM_Logon12 image:Button_Guigu_Normal";--menpai15

	else	--经典版的图片素材
		g_MenpaiDisableImageList[0] = "set:CreateRole2 image:BtnCancel_Disable";
		g_MenpaiDisableImageList[1] = "set:MainFrameLuo03 image:Cs_Shaolin_Pushed";
		g_MenpaiDisableImageList[2] = "set:MainFrameLuo03 image:Cs_Mingjiao_Pushed";
		g_MenpaiDisableImageList[3] = "set:MainFrameLuo03 image:Cs_Gaibang_Pushed";
		g_MenpaiDisableImageList[4] = "set:MainFrameLuo05 image:Cs_Wudang_Pushed";
		g_MenpaiDisableImageList[5] = "set:MainFrameLuo03 image:Cs_Emei_Pushed";
		g_MenpaiDisableImageList[6] = "set:MainFrameLuo05 image:Cs_Xingxiu_Pushed";
		g_MenpaiDisableImageList[7] = "set:MainFrameLuo04 image:Cs_Tianlong_Pushed";
		g_MenpaiDisableImageList[8] = "set:MainFrameLuo04 image:Cs_Tianshan_Pushed";
		g_MenpaiDisableImageList[9] = "set:MainFrameLuo05 image:Cs_Xiaoyao_Pushed" ;
		g_MenpaiDisableImageList[10] ="set:MainFrameLuo03 image:Cs_Murong_Pushed";
		g_MenpaiDisableImageList[11] ="set:MainFrameLuo05 image:Cs_Tangmen_Pushed";
		g_MenpaiDisableImageList[12] ="set:MainFrameLuo05 image:Cs_Guigu_Pushed";
		g_MenpaiDisableImageList[13] ="set:MainFrameLuo05 image:Cs_Kunlun_Pushed";--桃花岛
		g_MenpaiDisableImageList[14] ="set:MainFrameLuo06 image:Cs_Congren_Pushed";
		g_MenpaiDisableImageList[15] ="set:MainFrameLuo06 image:Cs_ERenGu_Pushed";--menpai15

		g_MenpaiNormalImageList[0] = "set:CreateRole2 image:BtnCancel_Normal";
		g_MenpaiNormalImageList[1] = "set:MainFrameLuo03 image:Cs_Shaolin_Normal";
		g_MenpaiNormalImageList[2] = "set:MainFrameLuo03 image:Cs_Mingjiao_Normal";
		g_MenpaiNormalImageList[3] = "set:MainFrameLuo03 image:Cs_Gaibang_Normal";
		g_MenpaiNormalImageList[4] = "set:MainFrameLuo05 image:Cs_Wudang_Normal";
		g_MenpaiNormalImageList[5] = "set:MainFrameLuo03 image:Cs_Emei_Normal";
		g_MenpaiNormalImageList[6] = "set:MainFrameLuo05 image:Cs_Xingxiu_Normal";
		g_MenpaiNormalImageList[7] = "set:MainFrameLuo03 image:Cs_Tianlong_Normal";
		g_MenpaiNormalImageList[8] = "set:MainFrameLuo04 image:Cs_Tianshan_Normal";
		g_MenpaiNormalImageList[9] = "set:MainFrameLuo05 image:Cs_Xiaoyao_Normal" ;
		g_MenpaiNormalImageList[10] ="set:MainFrameLuo03 image:Cs_Murong_Normal";
		g_MenpaiNormalImageList[11] ="set:MainFrameLuo05 image:Cs_Tangmen_Normal";
		g_MenpaiNormalImageList[12] ="set:MainFrameLuo05 image:Cs_Guigu_Normal";
		g_MenpaiNormalImageList[13] ="set:MainFrameLuo05 image:Cs_Kunlun_Normal";--桃花岛
		g_MenpaiNormalImageList[14] ="set:MainFrameLuo06 image:Cs_Congren_Normal";
		g_MenpaiNormalImageList[15] ="set:MainFrameLuo06 image:Cs_ERenGu_Normal";--menpai15
	end


	for i=0, 20  do
		g_FaceModel[i] = -1
	end

	-- 得到脸形信息
	CreateRole_GetFaceModel();

	-- 得到发型信息
	CreateRole_GetHairModel();

	-- 得到套装信息
	CreateRole_GetNewRoleEquipSet();

	-- 随机选择一个新手装
	local RandVal = math.random( 0, MaxEquipIndex )
	g_iCurSelEquipSetIndex = RandVal
	--下面一行注释掉，会引起Crash
	--当前修改之后的接口CreateRole_SelEquipSet跟最初的意义不一样了
	--完全没有必要在OnLoad的时候调用一下该接口
	--CreateRole_SelEquipSet(g_iCurSelEquipSetIndex);

	for i = 0, g_MenpaiButtonNum do
		g_MenpaiIntroduction[i] = "#{JSCJYH_121224_15}"--"#{XZRW_XML_" .. tostring(i) .. "}"
		if i == 11 then
			g_MenpaiIntroduction[i] = "#{XMPTM_130823_4}"	--XZRW_XML_11被占用了，唐门只能走特例了
		elseif i == 12 then
			g_MenpaiIntroduction[i] = "#{XMPGG_160615_34}"	--鬼谷只能走特例了
		elseif i == 13 then
			g_MenpaiIntroduction[i] = "#{THDBQ_190809_08}"	--桃花岛只能走特例了
		elseif i == 14 then
			g_MenpaiIntroduction[i] = "#{XMPHM_210604_06}"	--只能走特例了
		elseif i == 15 then--menpai15
			g_MenpaiIntroduction[i] = "#{XMPHM_210604_29}"	--只能走特例了
		else
			g_MenpaiIntroduction[i] = "#{XZRW_XML_" .. tostring(i) .. "}"
		end
	end

	g_Ex_MenpaiIntroduction[0] = "#{JSCJYH_121224_04}"; --少林
	g_Ex_MenpaiIntroduction[1] = "#{JSCJYH_121224_06}"; --明教
	g_Ex_MenpaiIntroduction[2] = "#{JSCJYH_121224_05}"; --丐帮
	g_Ex_MenpaiIntroduction[3] = "#{JSCJYH_121224_07}"; --武当
	g_Ex_MenpaiIntroduction[4] = "#{JSCJYH_121224_09}"; --峨眉
	g_Ex_MenpaiIntroduction[5] = "#{JSCJYH_121224_11}"; --星宿
	g_Ex_MenpaiIntroduction[6] = "#{JSCJYH_121224_08}"; --天龙
	g_Ex_MenpaiIntroduction[7] = "#{JSCJYH_121224_12}"; --天山
	g_Ex_MenpaiIntroduction[8] = "#{JSCJYH_121224_10}"; --逍遥
	g_Ex_MenpaiIntroduction[9] = "#{JSCJYH_121224_13}";  --慕容
	g_Ex_MenpaiIntroduction[10] = "#{XMPTM_130123_06}"; --唐门
	g_Ex_MenpaiIntroduction[11] = "#{XMPGG_160615_35}"; --鬼谷
	g_Ex_MenpaiIntroduction[12] = "#{THDBQ_190809_07}"; --桃花岛
	g_Ex_MenpaiIntroduction[13] = "#{XMPHM_210604_05}"; --
	g_Ex_MenpaiIntroduction[14] = "#{XMPHM_210604_28}"; --menpai15 

	if SystemSetup:IsClassic() == 0 then	--唯美版的图片素材
		g_MenpaiBgImageControl[0] = "set:WM_Logon12 image:Shiju4"; --少林
		g_MenpaiBgImageControl[1] = "set:WM_Logon12 image:Shiju7";--明教
		g_MenpaiBgImageControl[2] = "set:WM_Logon12 image:Shiju5"; --丐帮
		g_MenpaiBgImageControl[3] = "set:WM_Logon12 image:Shiju8";  --武当
		g_MenpaiBgImageControl[4] = "set:WM_Logon12 image:Shiju10"; 	  --峨眉
		g_MenpaiBgImageControl[5] = "set:WM_Logon12 image:Shiju3"; --星宿
		g_MenpaiBgImageControl[6] = "set:WM_Logon12 image:Shiju9";--天龙
		g_MenpaiBgImageControl[7] = "set:WM_Logon12 image:Shiju1";--天山
		g_MenpaiBgImageControl[8] = "set:WM_Logon12 image:Shiju11"; --逍遥
		g_MenpaiBgImageControl[9] = "set:WM_Logon12 image:Shiju2";  --慕容
		g_MenpaiBgImageControl[10] = "set:WM_Logon12 image:Shiju6";  ----唐门
		g_MenpaiBgImageControl[11] = "set:WM_Logon01 image:Shiju12";  ----鬼谷
		g_MenpaiBgImageControl[12] = "set:WM_Logon01 image:Shiju12";  ----桃花岛
		g_MenpaiBgImageControl[13] = "set:WM_Logon01 image:Shiju12";
		g_MenpaiBgImageControl[14] = "set:WM_Logon01 image:Shiju12";--menpai15 
	else	--经典版的图片素材
		g_MenpaiBgImageControl[0] = "set:CreateRole3 image:Icon_Shaolin"; --少林
		g_MenpaiBgImageControl[1] = "set:CreateRole4 image:Icon_Mingjiao";--明教
		g_MenpaiBgImageControl[2] = "set:CreateRole3 image:Icon_Gaibang"; --丐帮
		g_MenpaiBgImageControl[3] = "set:CreateRole4 image:Icon_Wudang";  --武当
		g_MenpaiBgImageControl[4] = "set:CreateRole4 image:Icon_Emei"; 	  --峨眉
		g_MenpaiBgImageControl[5] = "set:CreateRole3 image:Icon_Xingxiu"; --星宿
		g_MenpaiBgImageControl[6] = "set:CreateRole4 image:Icon_Tianlong";--天龙
		g_MenpaiBgImageControl[7] = "set:CreateRole3 image:Icon_Tianshan";--天山
		g_MenpaiBgImageControl[8] = "set:CreateRole4 image:Icon_Xiaoyao"; --逍遥
		g_MenpaiBgImageControl[9] = "set:CreateRole3 image:Icon_Murong";  --慕容
		g_MenpaiBgImageControl[10] = "set:CreateRole5 image:Icon_Tangmen";  ----唐门
		g_MenpaiBgImageControl[11] = "set:CreateRole5 image:Icon_Guigu";  ----鬼谷
		g_MenpaiBgImageControl[12] = "set:CreateRole5 image:Icon_Kunlun";  ----桃花岛
		g_MenpaiBgImageControl[13] = "set:CreateRole5 image:Icon_Hongming";
		g_MenpaiBgImageControl[14] = "set:CreateRole5 image:Icon_ERenGu";--menpai15
		
	end

	for i = 1, g_DescriptionNum do
		if i == 20 then
			g_Description[i] = "#{XMPTM_130823_3}"
		elseif i == 21 then
			g_Description[i] = "#{XMPGG_160615_33}"
		elseif i == 22 then --桃花岛
			g_Description[i] = "#{THDBQ_190809_09}"
		elseif i == 23 then
			g_Description[i] = "#{XMPHM_210604_04}"
		elseif i == 24 then--menpai15 
			g_Description[i] = "#{XMPHM_210604_27}"
		else
			g_Description[i] = "#{DLJM_XML_" .. tostring(i + 15) .. "}"	--无奈，字典从DLJM_XML_16开始的
		end
	end
end

-- OnEvent
function LoginCreateRole_OnEvent(event)

	if( event == "GAMELOGIN_OPEN_CREATE_CHARACTOR" ) then
	
		local bIsForbidName = GameProduceLogin:GetIsForbidName();
		if bIsForbidName > 0 then
			CreateRole_Name:SetProperty("DefaultEditBox", "False");
			CreateRole_Name:Disable();
			CreateRole_RandomName:Show();
		else
			CreateRole_Name:SetProperty("DefaultEditBox", "True");
			CreateRole_RandomName:Hide();
		end
		this:Show();
		CreateRole_Name:SetText("") --在此处清空一下
		
		
		--CreateRole_Info_Frame:Show()
		--CreateRole_Info2_Frame:Hide()
		CreateRole_RestoreCharacter()
		--再次打开，还是默认为女的
		iCurSelSex = 0
		g_CreateRoleFirstNameIdx=-1;
		g_CreateRoleLastNameIdx=-1;

		if(0 == iCurSelSex) then
			-- 选择女主角.
			CreateRole_SelectGirl();
		elseif(1 == iCurSelSex) then
			-- 选择男主角.
			CreateRole_SelectBoy();
		end

		-- 显示头像.
		CreateRole_ShowRoleFace(iCurSelSex);
		-- 默认选中第一个按钮；SetCheck我去~~
		g_FaceBorder[0]:SetCheck(1)
		LoginCreateRole_DingZhiMenPai()
		return;
	end
	
	if ( event == "RESHOW_CREATE_PLAYERNAME" ) then

		if g_CreateRoleFirstNameIdx >= 0 and g_CreateRoleLastNameIdx >= 0 and g_CreateRoleFistName ~= "" and g_CreateRoleLastName ~= "" then
			CreateRole_Name:SetText( g_CreateRoleFistName..g_CreateRoleLastName..tostring(arg0) );
			CreateRole_Name:SetProperty("CaratIndex", 1024);						
		end	
		return
	end

	if( event == "GAMELOGIN_CLOSE_CREATE_CHARACTOR") then

		CreateRole_Name:SetProperty("DefaultEditBox", "False");
		this:Hide();
		return;
	end

	if( event == "GAMELOGIN_CREATE_CLEAR_NAME") then

		--CreateRole_Name:SetText(""); --现在流程变了，名称要求不消失
		return;
	end

	if (event == "GAMELOGIN_CANCEL_PREVIEW") then
		CreateRole_RestoreCharacter();
		return;
	end

end

function LoginCreateRole_DingZhiMenPai()
	local zwid = GameProduceLogin:GetSelectLoginServerZWID()
	if DataPool:Lua_IsNewServerPlayerByZWID(zwid) == 0 then
		return
	end
	local MenPaiInfo = Lua_GetDingZhiMenPaiSvrInfo(zwid)
	if type(MenPaiInfo) ~= "table" then
		return
	end 
	for index=1, table.getn(MenPaiInfo) do 
		if MenPaiInfo[index] == 0 then
			g_MenpaiControl[index]:Disable()
		end
	end 
end
--更换门派模型
function CreateRole_BnClickMenpaiModel(menpai)
	 
	--CreateRole_BnClickMenpaiModelEx(-1)
	GameProduceLogin:ShowModel(-1)
	--控制相应的按钮、面板状态和门派介绍
	for i = 0, g_MenpaiButtonNum do
		g_MenpaiControl[i]:Enable()
		g_MenpaiControl[i]:SetProperty("NormalImage", g_MenpaiNormalImageList[i])
	end
	if menpai < 0 then
		--g_MenpaiControl[0]:Disable()
		g_MenpaiControl[0]:SetProperty("NormalImage", g_MenpaiDisableImageList[0])
		CreateRole_Info_Frame:Enable()
		g_MenpaiControl[0]:Hide()
		CreateRole_Name:Show()
		Createshow_Info:SetText(g_MenpaiIntroduction[0])
		CreateRole_Info3_Frame:Show()
		--CreateRole_Info_Frame:Show()
		Createshow_Info2:SetText("")
		CreateRole_Info2_Frame:Hide()
		g_TempCurSel_MenPai = -1
		CreateRole_Info_Frame:Show()
	elseif menpai < g_MenpaiButtonNum then
		g_MenpaiControl[0]:Enable()
		g_MenpaiControl[0]:Show()
		--g_MenpaiControl[menpai + 1]:Disable()
		g_MenpaiControl[menpai + 1]:SetProperty("NormalImage", g_MenpaiDisableImageList[menpai + 1])
		CreateRole_Info_Frame:Disable()
		CreateRole_Name:Hide()
		Createshow_Info:SetText(g_MenpaiIntroduction[menpai + 1])
		Createshow_Info2:SetText(g_Ex_MenpaiIntroduction[menpai])
		CreateRole_Info2_Frame_Back2:SetProperty("Image", g_MenpaiBgImageControl[menpai])
		CreateRole_Info3_Frame:Hide()
		--CreateRole_Info_Frame:Show()
		CreateRole_Info2_Frame:Show()
		g_TempCurSel_MenPai = menpai
		if iCurSelSex == 0 then
			CreateRole_Info2_Frame_Back4:SetCheck(0)
			CreateRole_Info2_Frame_Back5:SetCheck(1)
		else
			CreateRole_Info2_Frame_Back4:SetCheck(1)
			CreateRole_Info2_Frame_Back5:SetCheck(0)
		end
	end

	--显示相应的模型
	GameProduceLogin:ShowModel(menpai)

	--进行面板淡入淡出
	local speed = 0.5	--多久淡入淡出完毕，单位：秒
	local alphaPanel = CreateRole_Info_Frame:GetAlpha()
	if menpai < 0 and alphaPanel < 1 then
		CreateRole_Info_Frame:StartFade(alphaPanel, 1, (1 - alphaPanel) * speed)
	elseif menpai >= 0 and alphaPanel > 0 then
		CreateRole_Info_Frame:StartFade(alphaPanel, 0, alphaPanel * speed)
	end
	
	LoginCreateRole_DingZhiMenPai()
end
function CreateRole_RestoreCharacter()
	CreateRole_BnClickMenpaiModel(-1)
	CreateRole_Info3_Frame:Show()
end


---------------------------------------------------------------------------------------------------------
--
-- 更多脸形
--
function CreateRole_BnClickMoreFace()

end

---------------------------------------------------------------------------------------------------------
--
-- 创建角色
--
function CreateRole_BnClickCreateRole()

	if g_iFaceIndexInPage < 0 then          --by chengy TT52805
		GameProduceLogin:GameLoginShowSystemInfo("请选择头像!");
		return;
	end
	g_iCurSelFaceIndex = g_FacePageCount * g_iFaceCountInPage + g_iFaceIndexInPage;

	if(g_iCurSelFaceIndex >= g_iCurFaceCount) then

		g_iCurSelFaceIndex = -1;
		--return;
	end;
	GameProduceLogin:SetFaceId(iCurSelSex, g_iCurSelFaceIndex);

	local strImageName = "";
	strImageName = GameProduceLogin:GetFaceName(iCurSelSex, g_iCurSelFaceIndex);
	if strImageName == "" then
		GameProduceLogin:GameLoginShowSystemInfo("#{DLXZ_090711_1}");
		return;
	end

	local szName = CreateRole_Name:GetText();
	GameProduceLogin:CreateRole(szName, iCurSelSex, g_CreateRoleFirstNameIdx, g_CreateRoleLastNameIdx );
end


---------------------------------------------------------------------------------------------------------
--
-- 回到人物选择界面
--
function CreateRole_BnClickReturnSelectRole()

	-- 从人物创建界面返回到人物选择界面.
	GameProduceLogin:ChangeToSelectRoleDlgFromCreateRole();
end


---------------------------------------------------------------------------------------------------------
--
-- 选择女
--
function CreateRole_SelectGirl()

	CreateRole_Model:SetFakeObject("");
	CreateRole_Model:SetFakeObject("CreateRole_Woman");
	CreateRole_SelectSex_Girl:SetCheck(1);

	-- 选择女
	iCurSelSex = 0;

	-- 显示第一页
	g_FacePageCount = 0;

	-- 显示头像.
	CreateRole_ShowRoleFace(iCurSelSex);

	-- 选择第一个脸形
	CreateRole_BnSelFace1();   --by chengy TT52805

	-- check一下 Added by Lichengjie
	CreateRole_RefreshCurShowFacePage()

	-- 设置头像按钮状态
	CreateRole_SetFacePageStatus();

	-- 显示脸形模型
	CreateRole_GetFaceModel();

	-- 得到发型信息
	CreateRole_GetHairModel();

	-- 当前选择的脸形
	g_iCurSelFaceIndex = 0;

	-- 当前选择的发型
	g_iCurSelHairIndex = 0;

	-- 选择第一个发型
	CreateRole_SelHairModel(g_iCurSelHairIndex);

	-- 界面选择一个下拉列表
	--CreateRole_SelectFace:SetCurrentSelect(0);
	-- 选择第一个脸形
	CreateRole_SelFaceModel(g_FaceModel[0]);

	-- 改变新手装

	-- 随机选择一个新手装。
	local RandVal = math.random( 0, MaxEquipIndex )
  g_iCurSelEquipSetIndex = RandVal

	CreateRole_SelEquipSet(g_iCurSelEquipSetIndex);
	
	--初始随机名字
	CreateRole_RandomName_Clicked();

	--GameProduceLogin:ChangeNewRoleEquipSet(iCurSelSex, g_iCurSelEquipSetIndex);

end


---------------------------------------------------------------------------------------------------------
--
-- 选择男
--
function CreateRole_SelectBoy()

	CreateRole_Model:SetFakeObject("");
	CreateRole_Model:SetFakeObject("CreateRole_Man");
	CreateRole_SelectSex_Boy:SetCheck(1);

	-- 选择男
	iCurSelSex = 1;

	-- 显示第一页
	g_FacePageCount = 0;

	-- 显示头像.
	CreateRole_ShowRoleFace(iCurSelSex);

	-- 选择第一个脸形
	CreateRole_BnSelFace1();   --by chengy TT52805

	-- 设置头像按钮状态
	CreateRole_SetFacePageStatus();

	-- 显示脸形模型
	CreateRole_GetFaceModel();

	-- 得到发型信息
	CreateRole_GetHairModel();

	-- 当前选择的脸形
	g_iCurSelFaceIndex = 0;

	-- 当前选择的发型
	g_iCurSelHairIndex = 0;

	-- 选择第一个发型
	CreateRole_SelHairModel(g_iCurSelHairIndex);

	--CreateRole_SelectFace:SetCurrentSelect(0);
	-- 选择第一个脸形
	CreateRole_SelFaceModel(g_FaceModel[0]);

	-- 改变新手装
	-- 随机选择一个新手装。
	local RandVal = math.random( 0, MaxEquipIndex )
  g_iCurSelEquipSetIndex = RandVal

	CreateRole_SelEquipSet(g_iCurSelEquipSetIndex);
	
	--初始随机名字
	CreateRole_RandomName_Clicked();

	--GameProduceLogin:ChangeNewRoleEquipSet(iCurSelSex, g_iCurSelEquipSetIndex);

end

---------------------------------------------------------------------------------------------------------
--
-- 显示主角头像
--
function CreateRole_ShowRoleFace(iType)

	-- 清空头像数据.
	CreateRole_ClearImageData();
	if(0 == iType) then

		g_iCurFaceCount = GameProduceLogin:GetWomanFaceCountForCreate();
	elseif(1 == iType) then

		g_iCurFaceCount = GameProduceLogin:GetManFaceCountForCreate();
	end

	-- 刷新当前页
	CreateRole_RefreshCurShowFacePage();

	CreateRole_SetFacePageStatus();

	-- 当前开始显示头像的位置
	--local iCurStart = g_FacePageCount * g_iFaceCountInPage;

	-- 当前显示头像结束的位置
	--local iCurEnd   = iCurStart + g_iFaceCountInPage;
	--if(iCurEnd > g_iCurFaceCount) then

	--	iCurEnd = g_iCurFaceCount);
	--end;

	--local strImageName = "";
	--for index = iCurStart, iCurEnd - 1 do

	--	strImageName = GameProduceLogin:GetFaceName(iType, index);
	--	g_FaceSel[index]:SetProperty("Image", strImageName);
	--end

end

---------------------------------------------------------------------------------------------------------
--
-- 显示主角头像
--
function CreateRole_ClearImageData()

	CreateRole_PageUp:Disable();
	CreateRole_PageDown:Disable();

	local strImageName = "";
	for index = 0, 8 do

		g_FaceSel[index]:SetProperty("Image", strImageName);
	end

end


---------------------------------------------------------------------------------------------------------
--
-- 刷新当前显示的头像页
--
function CreateRole_RefreshCurShowFacePage()

	-- 清空图像数据
	CreateRole_ClearImageData();

	-- 当前开始显示头像的位置
	local iCurStart = g_FacePageCount * g_iFaceCountInPage;

	-- 当前显示头像结束的位置
	local iCurEnd   = iCurStart + g_iFaceCountInPage;
	if(iCurEnd > g_iCurFaceCount) then

		iCurEnd = g_iCurFaceCount;
	end;


	local strImageName = "";
	for index = iCurStart, iCurEnd - 1 do
		strImageName = GameProduceLogin:GetFaceName(iCurSelSex, index);
		g_FaceSel[index - iCurStart]:SetProperty("Image", strImageName);
	end
end

---------------------------------------------------------------------------------------------------------
--
-- 主角头像上翻一页
--
function CreateRole_BnClickFacePageUp()



	g_FacePageCount = g_FacePageCount - 1;

	if(g_FacePageCount < 0) then

		g_FacePageCount = 0;
		return;
	end

	-- 刷新当前显示的face页
	CreateRole_RefreshCurShowFacePage();

	-- 设置头像按钮状态
	CreateRole_SetFacePageStatus();

end


---------------------------------------------------------------------------------------------------------
--
-- 主角头像下翻一页
--
function CreateRole_BnClickFacePageDown()



	g_FacePageCount = g_FacePageCount + 1;

	if(g_FacePageCount * g_iFaceCountInPage >= g_iCurFaceCount) then

		g_FacePageCount = g_FacePageCount - 1;
		return;
	end;

	-- 刷新当前显示的face页
	CreateRole_RefreshCurShowFacePage();

	-- 设置头像按钮状态
	CreateRole_SetFacePageStatus();

end


---------------------------------------------------------------------------------------------------------
--
-- 选择头像1
--
function CreateRole_BnSelFace1()

	g_iFaceIndexInPage = 0;
end

---------------------------------------------------------------------------------------------------------
--
-- 选择头像2
--
function CreateRole_BnSelFace2()

	g_iFaceIndexInPage = 1;
end


---------------------------------------------------------------------------------------------------------
--
-- 选择头像3
--
function CreateRole_BnSelFace3()

	g_iFaceIndexInPage = 2;
end

---------------------------------------------------------------------------------------------------------
--
-- 选择头像4
--
function CreateRole_BnSelFace4()

	g_iFaceIndexInPage = 3;
end

---------------------------------------------------------------------------------------------------------
--
-- 选择头像5
--
function CreateRole_BnSelFace5()

	g_iFaceIndexInPage = 4;
end

---------------------------------------------------------------------------------------------------------
--
-- 选择头像6
--
function CreateRole_BnSelFace6()

	g_iFaceIndexInPage = 5;
end

---------------------------------------------------------------------------------------------------------
--
-- 选择头像7
--
function CreateRole_BnSelFace7()

	g_iFaceIndexInPage = 6;
end

---------------------------------------------------------------------------------------------------------
--
-- 选择头像8
--
function CreateRole_BnSelFace8()

	g_iFaceIndexInPage = 7;
end

---------------------------------------------------------------------------------------------------------
--
-- 选择头像9
--
function CreateRole_BnSelFace9()

	g_iFaceIndexInPage = 8;


end


---------------------------------------------------------------------------------------------------------
--
-- 设置头像按钮的状态
--
function CreateRole_SetFacePageStatus()

	-- 头像向上翻页按钮
	local PageCount = g_FacePageCount;
	PageCount = PageCount - 1;
	if(PageCount < 0) then

		CreateRole_PageUp:Disable();
	else

		CreateRole_PageUp:Enable();
	end


	PageCount = g_FacePageCount;
	-- 头像向下翻页按钮
	PageCount = PageCount + 1;
	if(PageCount * g_iFaceCountInPage >= g_iCurFaceCount) then

		CreateRole_PageDown:Disable();
	else
		CreateRole_PageDown:Enable();
	end;

end


-----------------------------------------------------------------------------------------------------------
--
-- 选择新的发型
--
function CreateRole_ComboListSelectHairChanged()
	CreateRole_RestoreCharacter()
  local strMeshName = "";
  strMeshName
	,g_iCurSelHairIndex = CreateRole_SelectHair:GetCurrentSelect();

	--AxTrace( 0,0, "==选择发型索引"..tostring(g_iCurSelHairIndex));
	--if(g_iCurSelHairIndexOld == g_iCurSelHairIndex) then

	--	return;
	--end
	g_iCurSelHairIndexOld = g_iCurSelHairIndex;

	CreateRole_SelHairModel(g_iCurSelHairIndex);

end

-----------------------------------------------------------------------------------------------------------
--
-- 选择新的脸型
--
function CreateRole_ComboListSelectFaceChanged()
	CreateRole_RestoreCharacter()
	local strMeshName = "";

	strMeshName
	,g_iCurSelectFace = CreateRole_SelectFace:GetCurrentSelect();
	--AxTrace( 0,0, "==选择脸型索引"..tostring(g_iCurSelFaceIndex));

	--if(g_iCurSelFaceIndexOld == g_iCurSelFaceIndex) then

	--	return;
	--end
	--g_iCurSelFaceIndexOld = g_iCurSelFaceIndex;

	CreateRole_SelFaceModel(g_FaceModel[g_iCurSelectFace]);

end


-----------------------------------------------------------------------------------------------------------
--
-- 得到脸形数据
--
function CreateRole_GetFaceModel()

	-- 清空数据
	--CreateRole_SelectFace:ResetList();

	local iFaceCount = GameProduceLogin:GetFaceModelCount(iCurSelSex);
	local strFaceModelName = "";

	local j=0
	for index = 0, iFaceCount - 1 do
		if GameProduceLogin:GetFaceModelInfo(iCurSelSex, index) == 3  or
		   GameProduceLogin:GetFaceModelInfo(iCurSelSex, index) == 1  then
			strFaceModelName = GameProduceLogin:GetFaceModelName(iCurSelSex, index);
			--CreateRole_SelectFace:ComboBoxAddItem(strFaceModelName, j);
			g_FaceModel[j] = index
			j = j+1
		end
	end;

end


-----------------------------------------------------------------------------------------------------------
--
-- 得到发形数据
--
function CreateRole_GetHairModel()

	-- 清空数据
	--CreateRole_SelectHair:ResetList();

	local iHairCount = GameProduceLogin:GetHairModelCount(iCurSelSex);
	local strHairModelName = "";

	for index = 0, iHairCount - 1 do

		strHairModelName = GameProduceLogin:GetHairModelName(iCurSelSex, index);
		--CreateRole_SelectHair:ComboBoxAddItem(strHairModelName, index);
	end;

end


-----------------------------------------------------------------------------------------------------------
--
-- 选择发型
--
function CreateRole_SelHairModel(index)

	local strHairModelName = GameProduceLogin:GetHairModelName(iCurSelSex, index);
	if strHairModelName == nil then
		strHairModelName = ""
	end
	--AxTrace( 0,0, "==选择发型"..tostring(index));
	--CreateRole_SelectHair:SetCurrentSelect(index);
	CreateRole_SelectHair_Text2:SetText(strHairModelName);
	GameProduceLogin:SetHairModelId(iCurSelSex, index);

end


-----------------------------------------------------------------------------------------------------------
--
-- 选择脸形
--
function CreateRole_SelFaceModel(index)

	local strFaceModelName = GameProduceLogin:GetFaceModelName(iCurSelSex, index);
	if strFaceModelName == nil then
		strFaceModelName = ""
	end
	CreateRole_SelectFace_Text2:SetText( strFaceModelName )
	--AxTrace( 0,0, "==选择脸形"..tostring(index));
	--CreateRole_SelectFace:SetCurrentSelect(index);
	GameProduceLogin:SetFaceModelId(iCurSelSex, index);

end

function CreateRole_MouseEnter(index)
	if index > 0 and index <= g_DescriptionNum then
		CreateRole_Info:SetText(g_Description[index])
	else
		CreateRole_Info:SetText("");
	end
end

function CreateRole_MouseLeave()
	CreateRole_MouseEnter(0)
end

----------------------------------------------------------------------------------
--
-- 旋转人物模型（向左)
--
function CreateRole_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1) then
		--CreateRole_Model:RotateBegin(-0.3);
                GameProduceLogin:ModelRotBegin(-1.0)
	--向左旋转结束
	else
		--CreateRole_Model:ModelRotEnd( 0 );
                GameProduceLogin:ModelRotEnd( 0.0 )
	end
end

----------------------------------------------------------------------------------
--
--旋转人物模型（向右)
--
function CreateRole_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1) then
		--CreateRole_Model:RotateBegin(0.3);
                GameProduceLogin:ModelRotBegin(1.0)
	--向右旋转结束
	else
		--CreateRole_Model:RotateEnd();
                GameProduceLogin:ModelRotEnd( 0.0 )
	end
end



-----------------------------------------------------------------------------------------------------------
--
-- 得到套装数据
--
function CreateRole_GetNewRoleEquipSet()

	-- 清空数据
	--CreateRole_SelectClothin:ResetList();

	local iCount = GameProduceLogin:GetEquipSetCount();
	--AxTrace( 0,0, "得到套装个数 ＝ "..tostring(iCount));

	local strShowName = "";
	for index = 0, iCount - 1 do

		strShowName = GameProduceLogin:GetEquipSetName(index);
		--AxTrace( 0,0, "得到套装名字 ＝ "..tostring(strShowName));
		--CreateRole_SelectClothin:ComboBoxAddItem(strShowName, index);
	end;

end


-----------------------------------------------------------------------------------------------------------
--
-- 选择发型
--
function CreateRole_SelEquipSet(index)

	--CreateRole_SelectClothin:SetCurrentSelect(index);
	local strShowName = GameProduceLogin:GetEquipSetName(index);
	if strShowName == nil then
		strShowName = ""
	end
	CreateRole_SelectClothing_Text2:SetText(strShowName);
	GameProduceLogin:ChangeNewRoleEquipSet(iCurSelSex, index)
end


function CreateRole_ComboListSelectClothin()
	CreateRole_RestoreCharacter()
	local strMeshName = "";

	strMeshName
	,g_iCurSelEquipSetIndex = CreateRole_SelectClothin:GetCurrentSelect();

	g_iCurSelEquipSetIndexOld = g_iCurSelEquipSetIndex;

	--AxTrace( 0,0, "选择套装 ＝ "..tostring(g_iCurSelEquipSetIndex));
	CreateRole_SelEquipSet(g_iCurSelEquipSetIndex);

	-- 改变新手装
	--GameProduceLogin:ChangeNewRoleEquipSet(iCurSelSex, g_iCurSelEquipSetIndex);

end;

function CreateRole_Modle_ZoomOut( start )
	if(start == 1) then
	    GameProduceLogin:ModelZoom( -1.0 )
	else
	    GameProduceLogin:ModelZoom( 0.0 )
	end

end

function CreateRole_Modle_ZoomIn( start )
    if(start == 1) then
         GameProduceLogin:ModelZoom( 1.0 )
	else
	     GameProduceLogin:ModelZoom( 0.0 )
	end

end

--==============================================
-- 获取最大有效的索引，因为数目虽然为Count，但并不是所有的都是有效的。
--==============================================
function CreateRole_SelectHair_GetMaxValidHairIndex()
	local iHairCount = GameProduceLogin:GetHairModelCount(iCurSelSex);
	--for 貌似不能从大到小，用while不符合传统，反正没有几个索引，直接从小到大了。
	for i=0, iHairCount-1 do
		local strHairModelName = GameProduceLogin:GetHairModelName(iCurSelSex, i);
		if strHairModelName == nil or strHairModelName == "" then
			return i
		end
	end
	return iHairCount - 1
end

function CreateRole_SelectHair_TurnLeft1_Clicked()

	local nMaxValidIndex = CreateRole_SelectHair_GetMaxValidHairIndex()

	local nCheckSelIndex = 0
	if g_iCurSelHairIndex <= 0 then
		nCheckSelIndex = nMaxValidIndex
	else
		nCheckSelIndex = g_iCurSelHairIndex - 1
	end
	local strHairModelName = GameProduceLogin:GetHairModelName(iCurSelSex, nCheckSelIndex);
	if strHairModelName == nil or strHairModelName == "" then
		return
	end

	CreateRole_RestoreCharacter()

	g_iCurSelHairIndexOld = g_iCurSelHairIndex;

	g_iCurSelHairIndex = nCheckSelIndex -- g_iCurSelHairIndex - 1

	--这个里面需要注释掉一行
	CreateRole_SelHairModel(g_iCurSelHairIndex);

	--local strHairModelName = GameProduceLogin:GetHairModelName(iCurSelSex, g_iCurSelHairIndex);
	--CreateRole_SelectHair_Text2:SetText(strHairModelName);

end

function CreateRole_SelectHair_TurnRight1_Clicked()

	local nMaxValidIndex = CreateRole_SelectHair_GetMaxValidHairIndex()

	local nCheckSelIndex = 0
	if g_iCurSelHairIndex >= nMaxValidIndex then
		nCheckSelIndex = 0
	else
		nCheckSelIndex = g_iCurSelHairIndex + 1
	end

	local strHairModelName = GameProduceLogin:GetHairModelName(iCurSelSex, nCheckSelIndex);
	if strHairModelName == nil or strHairModelName == "" then
		return
	end

	CreateRole_RestoreCharacter()

	g_iCurSelHairIndexOld = g_iCurSelHairIndex;

	g_iCurSelHairIndex = nCheckSelIndex -- g_iCurSelHairIndex + 1

	--这个里面需要注释掉一行
	CreateRole_SelHairModel(g_iCurSelHairIndex);

	--local strHairModelName = GameProduceLogin:GetHairModelName(iCurSelSex, g_iCurSelHairIndex);
	--CreateRole_SelectHair_Text2:SetText(strHairModelName);

end

function CreateRole_SelectFace_GetMaxValidFaceIndex()
	local iFaceCount = GameProduceLogin:GetHairModelCount(iCurSelSex);
	--for 貌似不能从大到小，用while不符合传统，反正没有几个索引，直接从小到大了。
	for i=0, iFaceCount-1 do
		local strFaceModelName = GameProduceLogin:GetFaceModelName(iCurSelSex, g_FaceModel[i]);
		if strFaceModelName == nil or strFaceModelName == "" then
			return i
		end
	end
	return iFaceCount - 1
end

function CreateRole_SelectFace_TurnLeft1_Clicked()
	local nMaxValidIndex = CreateRole_SelectFace_GetMaxValidFaceIndex()
	local nCheckSelIndex = 0
	if g_iCurSelectFace <= 0 then
		nCheckSelIndex = nMaxValidIndex
	else
		nCheckSelIndex = g_iCurSelectFace - 1
	end

	local strFaceModelName = GameProduceLogin:GetFaceModelName(iCurSelSex, g_FaceModel[nCheckSelIndex]);
	if strFaceModelName == nil or strFaceModelName == "" then
		return
	end

	g_iCurSelectFace = nCheckSelIndex -- g_iCurSelectFace - 1
	CreateRole_RestoreCharacter()
	CreateRole_SelFaceModel(g_FaceModel[g_iCurSelectFace]);

	--local strFaceModelName = GameProduceLogin:GetFaceModelName(iCurSelSex, g_FaceModel[g_iCurSelectFace]);
	--CreateRole_SelectFace_Text2:SetText( strFaceModelName )
end

function CreateRole_SelectFace_TurnRight1_Clicked()

	local nMaxValidIndex = CreateRole_SelectFace_GetMaxValidFaceIndex()
	local nCheckSelIndex = 0
	if g_iCurSelectFace >= nMaxValidIndex then
		nCheckSelIndex = 0
	else
		nCheckSelIndex = g_iCurSelectFace + 1
	end

	local strFaceModelName = GameProduceLogin:GetFaceModelName(iCurSelSex, g_FaceModel[nCheckSelIndex]);
	if strFaceModelName == nil or strFaceModelName == "" then
		return
	end

	g_iCurSelectFace =  nCheckSelIndex --g_iCurSelectFace + 1
	CreateRole_RestoreCharacter()
	CreateRole_SelFaceModel(g_FaceModel[g_iCurSelectFace]);

	--local strFaceModelName = GameProduceLogin:GetFaceModelName(iCurSelSex, g_FaceModel[g_iCurSelectFace]);
	--CreateRole_SelectFace_Text2:SetText( strFaceModelName )
end

function CreateRole_SelectClothin_GetMaxValidClothinIndex()

	local iEquipSetCount = GameProduceLogin:GetEquipSetCount()
	--for 貌似不能从大到小，用while不符合传统，反正没有几个索引，直接从小到大了。
	for i=0, iEquipSetCount-1 do
		local strShowName = GameProduceLogin:GetEquipSetName( i );
		if strShowName == nil or strShowName == "" then
			return i
		end
	end
	return iEquipSetCount - 1
end

function CreateRole_SelectClothin_TurnLeft1_Clicked()

	local nMaxValidIndex = CreateRole_SelectClothin_GetMaxValidClothinIndex()
	local nCheckSelIndex = 0;
	if g_iCurSelEquipSetIndex <= 0 then
		nCheckSelIndex = nMaxValidIndex;
	else
		nCheckSelIndex = g_iCurSelEquipSetIndex - 1;
	end

	local strShowName = GameProduceLogin:GetEquipSetName( nCheckSelIndex );
	if strShowName == nil or strShowName == "" then
		return
	end

	g_iCurSelEquipSetIndexOld = g_iCurSelEquipSetIndex;
	g_iCurSelEquipSetIndex  = nCheckSelIndex --g_iCurSelEquipSetIndex - 1;

	CreateRole_RestoreCharacter()
	--local strShowName = GameProduceLogin:GetEquipSetName(g_iCurSelEquipSetIndex);
	CreateRole_SelectClothing_Text2:SetText(strShowName);
	GameProduceLogin:ChangeNewRoleEquipSet(iCurSelSex, g_iCurSelEquipSetIndex)

end

function CreateRole_SelectClothin_TurnRight1_Clicked()

	local nMaxValidIndex = CreateRole_SelectClothin_GetMaxValidClothinIndex()
	local nCheckSelIndex = 0;
	if g_iCurSelEquipSetIndex >= nMaxValidIndex then
		nCheckSelIndex = 0;
	else
		nCheckSelIndex = g_iCurSelEquipSetIndex + 1;
	end

	local strShowName = GameProduceLogin:GetEquipSetName( nCheckSelIndex );
	if strShowName == nil or strShowName == "" then
		return
	end

	g_iCurSelEquipSetIndexOld = g_iCurSelEquipSetIndex;
	g_iCurSelEquipSetIndex  =  nCheckSelIndex -- g_iCurSelEquipSetIndex + 1;
	CreateRole_RestoreCharacter()

	--local strShowName = GameProduceLogin:GetEquipSetName(g_iCurSelEquipSetIndex);
	CreateRole_SelectClothing_Text2:SetText(strShowName);
	GameProduceLogin:ChangeNewRoleEquipSet(iCurSelSex, g_iCurSelEquipSetIndex)

end

function CreateRole_Random_Clicked()
	local nMaxValidIndex_Hair 		= CreateRole_SelectHair_GetMaxValidHairIndex()
	local nMaxValidIndex_Face 		= CreateRole_SelectFace_GetMaxValidFaceIndex()
	local nMaxValidIndex_Clothin 	= CreateRole_SelectClothin_GetMaxValidClothinIndex()

	local nRand_Hair = math.random(0, nMaxValidIndex_Hair)
	local nRand_Face = math.random(0, nMaxValidIndex_Face)
	local nRand_Clot = math.random(0, MaxEquipIndex)

	CreateRole_RestoreCharacter()
	--选衣服
	g_iCurSelEquipSetIndexOld = g_iCurSelEquipSetIndex;
	g_iCurSelEquipSetIndex  =  nRand_Clot;

	local strShowName = GameProduceLogin:GetEquipSetName(g_iCurSelEquipSetIndex);
	CreateRole_SelectClothing_Text2:SetText(strShowName);
	GameProduceLogin:ChangeNewRoleEquipSet(iCurSelSex, g_iCurSelEquipSetIndex)
	--选脸
	g_iCurSelectFace =  nRand_Face
	CreateRole_SelFaceModel(g_FaceModel[g_iCurSelectFace]);
	--选头发
	g_iCurSelHairIndexOld = g_iCurSelHairIndex;
	g_iCurSelHairIndex = nRand_Hair
	--这个里面需要注释掉一行
	CreateRole_SelHairModel(g_iCurSelHairIndex);
	
	LoginCreateRole_DingZhiMenPai()
end

function CreateRole_Random_MouseEnter()
	CreateRole_Info:SetText("#{JSCJYH_121224_02}")
end

function CreateRole_Random_MouseLeave()
	CreateRole_Info:SetText("")
end

function CreateRole_RandomName_Clicked()
	local bIsForbidName = GameProduceLogin:GetIsForbidName();
	if bIsForbidName > 0 then
		g_CreateRoleFistName, g_CreateRoleFirstNameIdx, g_CreateRoleLastName, g_CreateRoleLastNameIdx = GameProduceLogin:RandomCharName( iCurSelSex );
		CreateRole_Name:SetText( g_CreateRoleFistName..g_CreateRoleLastName );
		CreateRole_Name:SetProperty("CaratIndex", 1024);
	end
end

function CreateRole_RandomName_MouseEnter()
	CreateRole_Info:SetText("#{TCMZ_211027_2}")
end

function CreateRole_RandomName_MouseLeave()
	CreateRole_Info:SetText("")
end

function CreateRole_Preview_Man_Clicked()
	--if iCurSelSex == 1 then
	--	return
	--end
	iCurSelSex = 1;
	local nTempMenpai = g_TempCurSel_MenPai
	GameProduceLogin:ShowModel(-1)
	CreateRole_SelectBoy()
	if nTempMenpai >= 0 then
		CreateRole_BnClickMenpaiModelEx(nTempMenpai)
	end

end

function CreateRole_Preview_Woman_Clicked()
	--if iCurSelSex == 0 then
	--	return
	--end

	iCurSelSex = 0;
	local nTempMenpai = g_TempCurSel_MenPai
	GameProduceLogin:ShowModel(-1)
	CreateRole_SelectGirl()
	if nTempMenpai >= 0 then
		CreateRole_BnClickMenpaiModelEx(nTempMenpai)
	end
end

--更换门派模型
function CreateRole_BnClickMenpaiModelEx(menpai)
	--控制相应的按钮、面板状态和门派介绍
	for i = 0, g_MenpaiButtonNum do
		g_MenpaiControl[i]:Enable()
		g_MenpaiControl[i]:SetProperty("NormalImage", g_MenpaiNormalImageList[i])
	end
	if menpai < 0 then
		--g_MenpaiControl[0]:Disable()
		g_MenpaiControl[0]:SetProperty("NormalImage", g_MenpaiDisableImageList[0])

		CreateRole_Info_Frame:Enable()
		g_MenpaiControl[0]:Hide()
		CreateRole_Name:Show()
		Createshow_Info:SetText(g_MenpaiIntroduction[0])
		Createshow_Info2:SetText("")
		g_TempCurSel_MenPai = -1
	elseif menpai < g_MenpaiButtonNum then
		g_MenpaiControl[0]:Enable()
		g_MenpaiControl[0]:Show()
		--g_MenpaiControl[menpai + 1]:Disable()
		g_MenpaiControl[menpai + 1]:SetProperty("NormalImage", g_MenpaiDisableImageList[menpai + 1])

		CreateRole_Info_Frame:Disable()
		CreateRole_Name:Hide()
		Createshow_Info:SetText(g_MenpaiIntroduction[menpai + 1])
		Createshow_Info2:SetText(g_Ex_MenpaiIntroduction[menpai])
		CreateRole_Info2_Frame_Back2:SetProperty("Image", g_MenpaiBgImageControl[menpai])
		g_TempCurSel_MenPai = menpai
	end
	CreateRole_Info_Frame:Hide()
	--显示相应的模型
	GameProduceLogin:ShowModel(menpai)

	--进行面板淡入淡出
	local speed = 0.5	--多久淡入淡出完毕，单位：秒
	local alphaPanel = CreateRole_Info_Frame:GetAlpha()
	if menpai < 0 and alphaPanel < 1 then
		CreateRole_Info_Frame:StartFade(alphaPanel, 1, (1 - alphaPanel) * speed)
	elseif menpai >= 0 and alphaPanel > 0 then
		CreateRole_Info_Frame:StartFade(alphaPanel, 0, alphaPanel * speed)
	end
	LoginCreateRole_DingZhiMenPai()
end
