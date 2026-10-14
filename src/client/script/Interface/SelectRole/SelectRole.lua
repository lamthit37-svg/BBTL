
-----------------------------------------------------------------------------------------------------------------
--
-- 全局变量区
--

-- 名字
local g_RoleName = {};

-- 门派
local g_iMenPai = {};

-- 等级
local g_iLevel = {};
-- 等级
local g_SelectRole_iPKLevel = {};

-- 剩余删除时间
local g_iDelTime = {};

-- 头像资源名称
local g_FaceImg = {};

-- 角色出售状态
local g_iCYGSate = {};

-- 在界面上显示的ui模型
local g_UIModel = {};

-- 选择按钮
local g_BnSelCheck = {};

-- 当前选择的角色
local g_iCurSelRole = 0;

-- 当前角色的个数
local g_iCurRoleCount = 0;

-- 如果是创建成功后刷新界面， 要选中最后创建的这个角色.
--
-- 0 -- 创建角色失败。
-- 1 -- 创建角色成功。
local g_bCreateSuccess = 0;

-- UI界面资源
local g_RolName_Text	= {};
local g_MenPai_Text	= {};
local g_Level_Text	= {};
local g_Delete_Text	= {};
local g_RolFace_Icon	= {};
local g_CYGState_Text = {};
local g_HighLightBack	= {};
local g_CreateInfo_Text = {};
------------------------------------------------------------------------------------------------------------------
--
-- 函数区
--

-- 注册onLoad事件
function LoginSelectRole_PreLoad()
	-- 打开界面
	this:RegisterEvent("GAMELOGIN_OPEN_SELECT_CHARACTOR",true);

	-- 关闭界面
	this:RegisterEvent("GAMELOGIN_CLOSE_SELECT_CHARACTOR",false);

	-- 刷新角色信息
	this:RegisterEvent("GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR",true);

	-- 创建角色成功。
	this:RegisterEvent("GAMELOGIN_CREATE_ROLE_OK",true);

	this:RegisterEvent("ENTER_GAME",true);

	this:RegisterEvent("GAMELOGIN_SELECTCHARACTER",true);

	this:RegisterEvent("GAMELOGIN_BACKTO_SELECTCHAR_FROM_CREATECHAR",true)

end

-- 注册onLoad事件
function LoginSelectRole_OnLoad()

	-- 角色名字
	--g_RoleName[1] = SelectRole_Role1_Name;
	--g_RoleName[2] = SelectRole_Role2_Name;
	--g_RoleName[3] = SelectRole_Role3_Name;

	g_RoleName[1] = ""
	g_RoleName[2] = ""
	g_RoleName[3] = ""

	-- 角色门派
	g_iMenPai[1] = 0;
	g_iMenPai[2] = 0;
	g_iMenPai[3] = 0;

	-- 角色等级
	g_iLevel[1] = 0;
	g_iLevel[2] = 0;
	g_iLevel[3] = 0;
	g_SelectRole_iPKLevel[1] = 0;
	g_SelectRole_iPKLevel[2] = 0;
	g_SelectRole_iPKLevel[3] = 0;

	g_iDelTime[1] = 0;
	g_iDelTime[2] = 0;
	g_iDelTime[3] = 0;

	-- 角色头像信息
	g_FaceImg[1] = ""
	g_FaceImg[2] = ""
	g_FaceImg[3] = ""
	
	g_iCYGSate[1] = 0;
	g_iCYGSate[2] = 0;
	g_iCYGSate[3] = 0;

	-- 角色选择按钮
	--g_BnSelCheck[1] = SelectRole_Role1;
	--g_BnSelCheck[2] = SelectRole_Role2;
	--g_BnSelCheck[3] = SelectRole_Role3;

	-- 选择按钮
	--g_BnSelCheck[1]:SetProperty("CheckMode", "1");
	--g_BnSelCheck[2]:SetProperty("CheckMode", "1");
	--g_BnSelCheck[3]:SetProperty("CheckMode", "1");

	--g_BnSelCheck[1]:SetCheck( 0 );
	--g_BnSelCheck[2]:SetCheck( 0 );
	--g_BnSelCheck[3]:SetCheck( 0 );
	-- ui模型名字
	--g_UIModel[1] = SelectRole_Role1_Model;
	--g_UIModel[2] = SelectRole_Role2_Model;
	--g_UIModel[3] = SelectRole_Role3_Model;

	--SelectRole_Role1_Model:SetProperty("MouseHollow", "True");
	--SelectRole_Role2_Model:SetProperty("MouseHollow", "True");
	--SelectRole_Role3_Model:SetProperty("MouseHollow", "True");

	g_RolName_Text[1] = SelectRole_TargetInfo_Name_Text;
	g_RolName_Text[2] = SelectRole_TargetInfo_Name_Text2;
	g_RolName_Text[3] = SelectRole_TargetInfo_Name_Text3;

	g_MenPai_Text[1] = SelectRole_TargetInfo_Menpai_Text;
	g_MenPai_Text[2] = SelectRole_TargetInfo_Menpai_Text2;
	g_MenPai_Text[3] = SelectRole_TargetInfo_Menpai_Text3;

	g_Level_Text[1] = SelectRole_TargetInfo_Level_Text;
	g_Level_Text[2] = SelectRole_TargetInfo_Level_Text2;
	g_Level_Text[3] = SelectRole_TargetInfo_Level_Text3;

	g_Delete_Text[1] = SelectRole_TargetInfo_Delete;
	g_Delete_Text[2] = SelectRole_TargetInfo_Delete2;
	g_Delete_Text[3] = SelectRole_TargetInfo_Delete3;

	g_RolFace_Icon[1] = SelectRole_Icon;
	g_RolFace_Icon[2] = SelectRole_Icon2;
	g_RolFace_Icon[3] = SelectRole_Icon3;
	
	g_CYGState_Text[1] = SelectRole_TargetInfo_Sell;
	g_CYGState_Text[2] = SelectRole_TargetInfo_Sell2;
	g_CYGState_Text[3] = SelectRole_TargetInfo_Sell3;

	g_HighLightBack[1] = SelectRole_TargetInfo_Gaoliang1;
	g_HighLightBack[2] = SelectRole_TargetInfo_Gaoliang2;
	g_HighLightBack[3] = SelectRole_TargetInfo_Gaoliang3;

	g_CreateInfo_Text[1] = SelectRole_TargetInfo_Create;
	g_CreateInfo_Text[2] = SelectRole_TargetInfo_Create2;
	g_CreateInfo_Text[3] = SelectRole_TargetInfo_Create3;

	for i = 1, 3 do
		g_RolName_Text[i]:SetText("");
		g_MenPai_Text[i]:SetText("");
		g_Level_Text[i]:SetText("");
		g_Delete_Text[i]:SetText("");
		g_RolFace_Icon[i]:SetProperty("Image", "");
		g_CYGState_Text[i]:SetText("");
		g_CYGState_Text[i]:Hide();
		g_HighLightBack[i]:Hide();
		g_CreateInfo_Text[i]:Show();
	end
end

-- OnEvent
function LoginSelectRole_OnEvent(event)

	if( event == "GAMELOGIN_OPEN_SELECT_CHARACTOR" ) then

	    local CurSelIndex = GameProduceLogin:GetCurSelectRole();

		-- 默认选择第一个人物。
		g_iCurSelRole = CurSelIndex + 1  --1;



		SelectRole_ClearInfo();
		SelectRole_RefreshRoleInfo();
		SelectRole_ThisUIShow()
		return;
	end


	if( event == "GAMELOGIN_CLOSE_SELECT_CHARACTOR" ) then

		-- 清空数据
		SelectRole_ClearInfo();
		this:Hide();
		return;
	end


	-- 刷新角色
	if( event == "GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR") then

		SelectRole_RefreshRoleInfo();
		return;
	end


	-- 创建角色成功。
	if( event == "GAMELOGIN_CREATE_ROLE_OK") then

		g_bCreateSuccess = 1;
		return;
	end

	if( event == "ENTER_GAME" ) then
		local saleState = DataPool:GetCharSaletimeCyg(g_iCurSelRole - 1)
		if (saleState == 1) or (saleState == 2) then
			if g_iCurSelRole > 0 then
				PushEvent( "CHANGYIGE_LOGIN_CONFIRM" )
			end
			return
		end
		GameProduceLogin:SendEnterGameMsg(g_iCurSelRole - 1);
		return;
	end

	if( event == "GAMELOGIN_SELECTCHARACTER" ) then
	   local CurSel = tonumber( arg0 )

	   if( 0 == CurSel ) then
	     SelectRole_SelectRole1()
	   end

	   if( 1 == CurSel ) then
	     SelectRole_SelectRole2()
	   end

	   if( 2 == CurSel ) then
	     SelectRole_SelectRole3()
	   end

	end

	if( event == "GAMELOGIN_BACKTO_SELECTCHAR_FROM_CREATECHAR" ) then
	    local CurSelIndex = GameProduceLogin:GetCurSelectRole();

		-- 默认选择第一个人物。
		g_iCurSelRole = CurSelIndex + 1  --1;



		SelectRole_ClearInfo();
		SelectRole_RefreshRoleInfo();
		--this:Show();

		SelectRole_EnterGame_New()
		return;
	end

end



---------------------------------------------------------------------------------------------
--
-- 进入游戏
--
function SelectRole_EnterGame()
	local saleState = DataPool:GetCharSaletimeCyg(g_iCurSelRole - 1)
	if (saleState == 1) or (saleState == 2) then
		if g_iCurSelRole > 0 then
			PushEvent( "CHANGYIGE_LOGIN_CONFIRM" )
		end
		return
	end
	-- 发送进入游戏消息
	GameProduceLogin:SendEnterGameMsg(g_iCurSelRole - 1);
end

--
-- 进入游戏
--
function SelectRole_EnterGame_New()

	-- 发送进入游戏消息
	GameProduceLogin:SendEnterGameMsg_New(g_iCurSelRole - 1);
end
---------------------------------------------------------------------------------------------
--
-- 创建角色
--
function SelectRole_CreateRole()

	--创建角色
	DataPool:AskCreateChar();
		
	--此处不直接从人物选择界面切换到人物创建界面....
	--向Login请求创建人物的图形验证信息....验证信息到来后会开启验证界面....验证通过后验证界面会切换到人物创建流程....
	--DataPool:AskCreateCharCode();

end



---------------------------------------------------------------------------------------------
--
-- 删除角色
--
function SelectRole_DelRole()
	--删除角色或者取消删除处理
	local saleState = DataPool:GetCharSaletimeCyg(g_iCurSelRole - 1)
	if (saleState == 1) or (saleState == 2) then
		PushEvent( "CHANGYIGE_LOGIN_DEL_CONFIRM" )
		return
	end

	GameProduceLogin:SetCurSelect( g_iCurSelRole - 1 );
	-- 从人物选择界面切换到人物创建界面.
		local strName;
	local iMenPai;
	local iLevel;
	local iDelTime;
	local strInfo;
	local strImgName;
	strName
	,iMenPai
	,iLevel
	,iDelTime
	,strImgName
	,_
	= GameProduceLogin:GetRoleInfo(g_iCurSelRole-1);
	if( iLevel == 0 ) then --说明没有角色
		strInfo="没有选择角色";
			GameProduceLogin:ShowMessageBox( strInfo, "OK", "6" );
		return;
	end
	if iDelTime > 0 then	
		--取消删除操作
		SelectRole_CancelDelChar()
	elseif( iLevel >= 1 ) then --如果大于10级
		--if (iLevel >= 80) and (iDelTime >= 4) then
		--	strInfo="#{SCJS_110613_2}"..tostring( 14 - iDelTime ).."#{SCJS_110613_3}";
		--	GameProduceLogin:ShowMessageBox( strInfo, "OK", "6" );
		--elseif (iLevel < 80) and ( iDelTime >= 11 ) then--说明还不能删除呢，出提示对话框
		--	strInfo="删除申请已经提交"..tostring( 14 - iDelTime ).."天了,请在删除角色3天后，14天以内登录游戏，到洛阳（268，46）找到关汉寿或者到大理（80，136）找到周仓确认。";
		--	GameProduceLogin:ShowMessageBox( strInfo, "OK", "6" );
		--elseif( iDelTime > 0 ) then		--说明可以删除呢，出提示对话框
		--	strInfo="请登录游戏，到洛阳（268，46）找到关汉寿或者到大理（80，136）找到周仓确认，即可永久删除。你必须没有帮会、结婚、开店、结拜、师徒关系才能删除。";
		--	GameProduceLogin:ShowMessageBox( strInfo, "OK", "5" );
		--else --说明要删除了，出现提示对话框
			strInfo = "你确定要将"..tostring( iLevel ).."级的角色#c00ff00"..strName.."#cffffff删除吗?";
			if iLevel >= 80 then
				GameProduceLogin:ShowMessageBox( strInfo, "YesNo", "27" );
			else
				GameProduceLogin:ShowMessageBox( strInfo, "YesNo", "4" );
			end
		--end
	else --直接出现提示，是否删除
		strInfo = "你确定要将"..tostring( iLevel ).."级的角色#c00ff00"..strName.."#cffffff删除吗?";
		GameProduceLogin:ShowMessageBox( strInfo, "YesNo", "7" );
	end

end


---------------------------------------------------------------------------------------------
--
-- 返回到上一步
--
function SelectRole_Return()

	GameProduceLogin:ExitToAccountInput_YesNo();
	--GameProduceLogin:ChangeToAccountInputDlgFromSelectRole();
end


---------------------------------------------------------------------------------------------------------------
--
--   刷新角色信息
--
function SelectRole_RefreshRoleInfo()

	-- 清空界面.
	SelectRole_ClearInfo();

	g_iCurRoleCount = GameProduceLogin:GetRoleCount();
	-- 得到人物的个数


	if(0 == g_iCurRoleCount) then

		return;
	end;

	for index =0 , g_iCurRoleCount-1 do


			SelectRole_GetRoleInfo(index);
	end

	-- 选择角色
	if(1 == g_bCreateSuccess) then

			-- 创建成功后
			g_iCurSelRole = g_iCurRoleCount;
			g_bCreateSuccess = 0;
	end

	for index =1 , g_iCurRoleCount do
		SelectRole_ShowSelRoleInfo(index);
	end

	SelectRole_HighLight();
end


---------------------------------------------------------------------------------------------------------------
--
--   刷新角色信息
--
function SelectRole_GetRoleInfo(index)

	local strName;
	local iMenPai;
	local iLevel;
	local iDelTime;
	local strFaceImgName;
	local iCYGSate;
	local iPKLevel;

	strName
	,iMenPai
	,iLevel
	,iDelTime
	,strFaceImgName
	,iCYGSate
	,iPKLevel
	= GameProduceLogin:GetRoleInfo(index);

	-- 设置名字
	--g_RoleName[index+1]:SetText(strName);
	g_RoleName[index+1] = strName;
	g_iMenPai[index+1] = iMenPai;
	g_iLevel[index+1]  = iLevel;
	g_iDelTime[index+1] = iDelTime;
	g_FaceImg[index+1] = strFaceImgName;
	g_iCYGSate[index+1] = iCYGSate;
	g_SelectRole_iPKLevel[index+1]  = iPKLevel;
end

---------------------------------------------------------------------------------------------------------------
--
--   清空角色信息.
--
function SelectRole_ClearInfo()
	for i = 1, 3 do
		g_RolName_Text[i]:SetText("");
		g_MenPai_Text[i]:SetText("");
		g_Level_Text[i]:SetText("");
		g_Delete_Text[i]:Hide();
		g_RolFace_Icon[i]:SetProperty("Image", "");
		g_CYGState_Text[i]:SetText("");
		g_CYGState_Text[i]:Hide();
		g_HighLightBack[i]:Hide();
		g_CreateInfo_Text[i]:Show();
	end
end


---------------------------------------------------------------------------------------------------------------
--
--   选择角色1.
--
function SelectRole_SelectRole1()


	g_iCurSelRole = 1;
	if(g_iCurRoleCount < g_iCurSelRole) then


		SelectRole_TargetInfo_Name_Text:SetText("");
		SelectRole_TargetInfo_Menpai_Text:SetText("");
		SelectRole_TargetInfo_Level_Text:SetText("");
		return;
	end

	--SelectRole_ShowSelRoleInfo(g_iCurSelRole);

end

---------------------------------------------------------------------------------------------------------------
--
--   选择角色2.
--
function SelectRole_SelectRole2()


	g_iCurSelRole = 2;
	if(g_iCurRoleCount < g_iCurSelRole) then

		SelectRole_TargetInfo_Name_Text:SetText("");
		SelectRole_TargetInfo_Menpai_Text:SetText("");
		SelectRole_TargetInfo_Level_Text:SetText("");
		return;
	end

	--SelectRole_ShowSelRoleInfo(g_iCurSelRole);

end


---------------------------------------------------------------------------------------------------------------
--
--   选择角色3.
--
function SelectRole_SelectRole3()


	g_iCurSelRole = 3;
	if(g_iCurRoleCount < g_iCurSelRole) then

		SelectRole_TargetInfo_Name_Text:SetText("");
		SelectRole_TargetInfo_Menpai_Text:SetText("");
		SelectRole_TargetInfo_Level_Text:SetText("");
		return;
	end

	--SelectRole_ShowSelRoleInfo(g_iCurSelRole);

end


---------------------------------------------------------------------------------------------------------------
--
--   通过索引, 选择角色
--
function SelectRole_ShowSelRoleInfo(index)

	if(g_iCurRoleCount < index or 0 >= index ) then
		return;
	end

	if(index < 1)	then
		return;
	end;

	-- 显示名字

	--SelectRole_TargetInfo_Name_Text:SetText(g_RoleName[index]:GetText());
	--added by dun.liu 2008-04-18
	g_RolName_Text[index]:SetText( ""..g_RoleName[index] );


	-- 显示门派
	local strName = "无门派";
	local Family  = g_iMenPai[index];

	-- 得到门派名称.
	if(0 == Family) then
		strName = "少林";

	elseif(1 == Family) then
		strName = "明教";

	elseif(2 == Family) then
		strName = "丐帮";

	elseif(3 == Family) then
		strName = "武当";

	elseif(4 == Family) then
		strName = "峨嵋";

	elseif(5 == Family) then
		strName = "星宿";

	elseif(6 == Family) then
		strName = "天龙";

	elseif(7 == Family) then
		strName = "天山";

	elseif(8 == Family) then
		strName = "逍遥";

	elseif(9 == Family) then
		strName = "无门派";

	elseif(10== Family) then
		strName = "#{GMGameInterface_Script_DataPool_Info_GuSu}";
	--唐门
	elseif(11== Family) then
		strName = "#{XMPTM_130123_02}";
	
	--鬼谷
	elseif(12== Family) then
		strName = "#{XMPGG_160524_02}";
		
	elseif(13== Family) then
		strName = "#{THDXG_190705_05}";--桃花岛
		
	elseif(14== Family) then
		strName = "#{XMPHM_210604_03}";
	
	elseif(15== Family) then--menpai15 mptodo
		strName = "#{XMPHM_210604_26}";
	end
	g_MenPai_Text[index]:SetText("#c00ff00门派:#cffffff"..strName);

	-- 显示等级
	g_Level_Text[index]:SetText("#c00ff00等级:#cffffff"..tostring(g_iLevel[index]));
	-- pklevel
	local isPKServer = GameProduceLogin:GetSelectedServerIsPKServer()
	if isPKServer == 1 and g_SelectRole_iPKLevel[index] > 0 and g_SelectRole_iPKLevel[index] < g_iLevel[index] then
		g_Level_Text[index]:SetText("#c00ff00等级:#cffffff"..tostring(g_SelectRole_iPKLevel[index]));
	end

	if(tonumber(g_iDelTime[index])>0)then
		if (g_iLevel[index] >= 80) and (g_iDelTime[index] >= 4) then
			g_Delete_Text[index]:SetText("#c00ff00"..(10-(14-g_iDelTime[index])).."#{SCJS_110613_4}");
		elseif (g_iLevel[index] < 80) and (g_iDelTime[index] >= 11) then
			g_Delete_Text[index]:SetText("#c00ff00"..(3-(14-g_iDelTime[index])).."#{SCJS_110613_4}");
		else
			g_Delete_Text[index]:SetText("#c00ff00已可删除角色");
		end

		g_Delete_Text[index]:Show();
	else
		g_Delete_Text[index]:SetText("#{JSCJYH_121224_01}");
		g_Delete_Text[index]:Show();
	end
	-- 设为选择状态
	--g_BnSelCheck[index]:SetCheck(1);

	g_RolFace_Icon[index]:SetProperty("Image", g_FaceImg[index]);
	
	if g_iCYGSate[index] == 0 then
		g_CYGState_Text[index]:SetText("");
		g_CYGState_Text[index]:Hide();
	elseif g_iCYGSate[index] == 1 then
		g_CYGState_Text[index]:SetText("#{CYG_130527_99}");
		g_CYGState_Text[index]:Show();
	elseif g_iCYGSate[index] == 2 then
		g_CYGState_Text[index]:SetText("#{CYG_130527_100}");
		g_CYGState_Text[index]:Show();
	end

	g_CreateInfo_Text[index]:Hide();

end


function SelectRole_SelRole_MouseEnter(index)

	SelectRole_Info:SetText("选择当前登录角色");
end

function SelectRole_MouseLeave()

	SelectRole_Info:SetText("");
end

function SelectRole_Play_MouseEnter()

	SelectRole_Info:SetText("进入游戏");
end

function SelectRole_Create_MouseEnter()

	SelectRole_Info:SetText("创建一个新角色");
end

function SelectRole_Delete_MouseEnter()

	SelectRole_Info:SetText("删除一个已有角色");
end

function SelectRole_Last_MouseEnter()

	SelectRole_Info:SetText("返回到账号登录界面");	--帐号  to  账号
end;


function SelectRole_Role_Modle_TurnRightBegin(index)

	if(1 == index) then

		SelectRole_Role1_Model:RotateBegin(0.3);

	elseif(2 == index) then

		SelectRole_Role2_Model:RotateBegin(0.3);

	elseif(3 == index) then

		SelectRole_Role3_Model:RotateBegin(0.3);

	end;

end;


function SelectRole_Role_Modle_TurnRightEnd(index)

	if(1 == index) then

		SelectRole_Role1_Model:RotateEnd();

	elseif(2 == index) then

		SelectRole_Role2_Model:RotateEnd();

	elseif(3 == index) then

		SelectRole_Role3_Model:RotateEnd();

	end;

end;

function SelectRole_Role_Modle_TurnLeftBegin(index)

	if(1 == index) then

		SelectRole_Role1_Model:RotateBegin(-0.3);

	elseif(2 == index) then

		SelectRole_Role2_Model:RotateBegin(-0.3);

	elseif(3 == index) then

		SelectRole_Role3_Model:RotateBegin(-0.3);

	end;

end;


function SelectRole_Role_Modle_TurnLeftEnd(index)

	if(1 == index) then

		SelectRole_Role1_Model:RotateEnd();

	elseif(2 == index) then

		SelectRole_Role2_Model:RotateEnd();

	elseif(3 == index) then

		SelectRole_Role3_Model:RotateEnd();

	end;

end;





function SelectRole_Role_Modle_TurnRight( start )
	--向右旋转开始
	if(start == 1) then
        --GameProduceLogin:ModelRotBegin(0.3)
            GameProduceLogin:ModelRotBegin(1.0)   --每秒一圈
	--向右旋转结束
	else
        GameProduceLogin:ModelRotEnd( 0.0 )
	end

end

function SelectRole_Role_Modle_TurnLeft( start )
	if(start == 1) then
            --GameProduceLogin:ModelRotBegin(-0.3)
            GameProduceLogin:ModelRotBegin(-1.0)   --每秒-1圈
	else
        GameProduceLogin:ModelRotEnd( 0.0 )
	end

end

function SelectRole_Modle_ZoomOut( start )
	if(start == 1) then
	    GameProduceLogin:ModelZoom( -1.0 )
	else
	    GameProduceLogin:ModelZoom( 0.0 )
	end

end

function SelectRole_Modle_ZoomIn( start )
    if(start == 1) then
         GameProduceLogin:ModelZoom( 1.0 )
	else
	     GameProduceLogin:ModelZoom( 0.0 )
	end

end

function SelectRole_Clicked( index )
	if(g_iCurRoleCount <= index or 0 > index ) then
		return;
	end

	GameProduceLogin:MoveToCharacter( index );
	g_iCurSelRole = index + 1;
	SelectRole_HighLight();

end

function SelectRole_HighLight()
	if(g_iCurRoleCount < g_iCurSelRole or 0 >= g_iCurSelRole ) then
		return;
	end

	for i = 1, 3 do
		g_HighLightBack[i]:Hide();
	end
	g_HighLightBack[g_iCurSelRole]:Show();
	
	--刷新按钮文字
	if g_iDelTime[g_iCurSelRole] > 0 then
		SelectRole_Delete:SetProperty("NormalImage","set:MainFrameLuo06 image:CancelDelete_Normal");
		SelectRole_Delete:SetProperty("PushedImage","set:MainFrameLuo06 image:CancelDelete_Pushed");
		SelectRole_Delete:SetProperty("HoverImage","set:MainFrameLuo06 image:CancelDelete_Hover");
	else
		if SystemSetup:IsClassic() ~= 0 then
			SelectRole_Delete:SetProperty("NormalImage","set:MainFrameLuo03 image:DelRole_Normal");
			SelectRole_Delete:SetProperty("PushedImage","set:MainFrameLuo03 image:DelRole_Pushed");
			SelectRole_Delete:SetProperty("HoverImage","set:MainFrameLuo03 image:DelRole_Hover");
		else
			SelectRole_Delete:SetProperty("NormalImage","set:WM_Logon03 image:SelectRole_Button_Shanchujuese_Normal");
			SelectRole_Delete:SetProperty("PushedImage","set:WM_Logon03 image:SelectRole_Button_Shanchujuese_Pushed");
			SelectRole_Delete:SetProperty("HoverImage","set:WM_Logon03 image:SelectRole_Button_Shanchujuese_Hover");
		end
	end
end

function SelectRole_DoubleClicked( index )
	local strName;
	local iMenPai;
	local iLevel;
	local iDelTime;
	local strInfo;
	local strImgName;
	strName
	,iMenPai
	,iLevel
	,iDelTime
	,strImgName
	,_
	,_
	= GameProduceLogin:GetRoleInfo(index);
	if( iLevel == 0 ) then --说明没有角色
		SelectRole_CreateRole();
	else
		if(g_iCurRoleCount <= index or 0 > index) then
			return;
		end

		if (g_iCurSelRole ~= index + 1) then
			g_iCurSelRole = index + 1;
			GameProduceLogin:MoveToCharacter(index);
			SelectRole_HighLight();
		end

		SelectRole_EnterGame();
	end
end

function SelectRole_MouseEnterCharArea(index)
	local strName;
	local iMenPai;
	local iLevel;
	local iDelTime;
	local strInfo;
	local strImgName;
	strName
	,iMenPai
	,iLevel
	,iDelTime
	,strImgName
	,_
	,_
	= GameProduceLogin:GetRoleInfo(index);
	if( iLevel == 0 ) then --说明没有角色
		SelectRole_Info:SetText("#{DLJM_XML_5}");
	else
		if iDelTime > 0 then
			local nDelayTime = 3
			if iLevel >= 80 and iDelTime < 4 or iDelTime < 11 then 
				SelectRole_Info:SetText("#{SCTZ_160111_3}")	
			else
				if iLevel >= 80 then
					nDelayTime = 10
				end
				SelectRole_Info:SetText(ScriptGlobal_Format("#{SCTZ_160111_2}",14 - iDelTime, nDelayTime))
			end
		else
			SelectRole_Info:SetText("#{DLJM_XML_6}");
		end
	end
end

function SelectRole_CancelDelChar(index)
	--取消删除角色
	GameProduceLogin:ShowMessageBox( "#{SCTZ_160111_7}", "YesNo", "61" );
end

function SelectRole_ThisUIShow()
	this:Show();
	if Lua_IsPrintMemMode() == 1 then
		Lua_PrintMem()
	end
end