-- 界面的默认位置
local g_UnifiedXPosition;
local g_UnifiedYPosition;

local Titles = {};-- {"基本设置","分组设置"};
local TagButtons = {};--{Friend_IMSetting_TagButton1,Friend_IMSetting_TagButton2}
local TagContents = {};
local TagNum = 2;
local MaxGroupingName = 4; --最多四个分组
local g_CurTagIndex = 0;

--===============================================
-- OnLoad()
--===============================================
function Friend_IMSetting_PreLoad()
	this:RegisterEvent("OPEN_IM_SETTING");
	this:RegisterEvent("UPDATE_GROUPINGNAME");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Friend_IMSetting_OnLoad()

	-- 保存界面的默认相对位置
	g_UnifiedXPosition	= Friend_IMSetting_Frame:GetProperty("UnifiedXPosition");
	g_UnifiedYPosition	= Friend_IMSetting_Frame:GetProperty("UnifiedYPosition");
	
	Titles[1] = "#{LTQH_XML_69}";	--基本设置
	Titles[2] = "#{LTQH_XML_70}";	--分组设置

	TagButtons[1] = Friend_IMSetting_BasicSetting;
	TagButtons[2] = Friend_IMSetting_GroupSetting;

	TagContents[1] = Friend_IMSetting_BasicContent;
	TagContents[2] = Friend_IMSetting_GroupContent;


end

--===============================================
-- OnEvent()
--===============================================
function Friend_IMSetting_OnEvent( event )

	if ( event == "OPEN_IM_SETTING" ) then
		Friend_IMSetting_UpdateFrame();
		Friend_IMSetting_Tag_Clicked(1);
		Friend_IMSetting_SetButton(1);
		this:Show();
	end
	if ( event == "UPDATE_GROUPINGNAME") then
		if(tonumber(arg0) == 1) then
			PushDebugMessage("#{LTQH_XML_92}");
			Friend_IMSetting_UpdateFrame();
		end
	elseif( event == "ADJEST_UI_POS" ) then
		Friend_IMSetting_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Friend_IMSetting_ResetPos()
	end

end

function Friend_IMSetting_UpdateFrame()
	local n1,n2,n3,n4,n5,n6 = SystemSetup:GetChatSetting();

	Friend_IMSetting_Basic1				:SetCheck(n1);					-- 拒绝所有信件
	Friend_IMSetting_Basic2				:SetCheck(n2);					-- 拒绝加我好友
	Friend_IMSetting_Basic3				:SetCheck(n3);					-- 拒绝默认生信件
	Friend_IMSetting_Basic4				:SetCheck(n4);					-- 拒绝所有聊天信息
	Friend_IMSetting_Basic5				:SetCheck(n5);					-- 拒绝任何人邀请我加入聊天群
	Friend_IMSetting_Basic6				:SetCheck(n6);

	--clear
	Friend_IMSetting_GroupNameNew:SetText("");
	Friend_IMSetting_GroupName:SetText("");
	Friend_IMSetting_GroupName:ResetList();
	Friend_IMSetting_Select:SetText("");
	Friend_IMSetting_Select:ResetList();
	local GroupName;
	for i = 1, MaxGroupingName do
		GroupName = DataPool:GetGroupingNameByIndex(i-1);
		Friend_IMSetting_GroupName:AddTextItem( GroupName, i);
	end
	
	for j = 1 , MaxGroupingName do
		local nGroupID , nGroupName ,nCount , nChiefGuid = DataPool:GetChatGroupInfoByIndex(j-1)
		if nGroupID ~= nil and nGroupID ~= -1 then
			local ownerid = DataPool:GetChatGroupChiefIDByGroupID(nGroupID)
			local myGuid = Player:GetGUID();
			if myGuid == ownerid then
				Friend_IMSetting_Select:AddTextItem(nGroupName,nGroupID)  
			end
		end
	end

end

--确定
function Friend_IMSetting_Accept_Clicked()
	if(g_CurTagIndex == 1) then
		local n1,n2,n3,n4,n5,n6 = SystemSetup:GetChatSetting();

		n1 = Friend_IMSetting_Basic1:GetCheck();				  -- 拒绝所有信件
		n2 = Friend_IMSetting_Basic2:GetCheck();                  -- 拒绝加我好友
		n3 = Friend_IMSetting_Basic3:GetCheck();                  -- 拒绝默认生信件
		n4 = Friend_IMSetting_Basic4:GetCheck();                  -- 拒绝所有聊天信息
		n5 = Friend_IMSetting_Basic5:GetCheck();                  -- 拒绝任何人邀请我加入聊天群
		local new_n6 = Friend_IMSetting_Basic6:GetCheck();                  -- 聊天界面微缩模式


		SystemSetup:SaveChatSetting ( n1,n2,n3,n4,n5,n6 );

		if new_n6 ~= n6 then
			PushEvent("CHANGE_IMWINDOWMODE", new_n6);
		end
		this:Hide();
--	elseif(g_CurTagIndex == 2) then
	--	if(Friend_IMSetting_Modify_Clicked() == 1) then
		--	this:Hide();
	--	end
	end

end
--取消
function Friend_IMSetting_Cancel_Clicked()
	this:Hide();
end

--修改分组名字
function Friend_IMSetting_Modify_Clicked()
	local oldName , nIndex = Friend_IMSetting_GroupName:GetCurrentSelect();
	local newName = Friend_IMSetting_GroupNameNew:GetText();
	if(nIndex<1 or nIndex>MaxGroupingName) then
		PushDebugMessage("#{LTQH_XML_71}");
		return -1;
	end
	if( newName == "" or newName == nil) then
		PushDebugMessage("#{LTQH_XML_72}");
		return -1;
	end

	local Ret = DataPool:ModifyGroupingName(nIndex-1,newName);
	if(Ret == nil or tonumber(Ret) < 0) then
		PushDebugMessage("#{LTQH_XML_86}");
		return -1;
	end
	return 1;
end

function Friend_IMSetting_OnHidden()
	Friend_IMSetting_SetButton(-1);
end

function Friend_IMSetting_Tag_Clicked(Index)
	g_CurTagIndex = Index;
	Friend_IMSetting_CloseTag(-1);
	Friend_IMSetting_OpenTag(Index);
	Friend_IMSetting_SetTitle(Index);
end

--关闭Tag界面
function Friend_IMSetting_CloseTag(Index)
	local i;
	if(Index == -1) then	--全部关闭
		for i=1,TagNum do
			TagContents[i]:Hide();
		end
		return;
	end
	if(Index>0 and Index <= TagNum) then
		TagContents[Index]:Hide();
	end
end

--打开Tag界面
function Friend_IMSetting_OpenTag(Index)
	if(Index>0 and Index <= TagNum) then
		TagContents[Index]:Show();
		if Index == 2 then
			Friend_IMSetting_OK_Button:Hide()
			Friend_IMSetting_Cancel_Button:Hide()			
		else
			Friend_IMSetting_OK_Button:Show()
			Friend_IMSetting_Cancel_Button:Show()
		end
	end
end

--设置标题
function Friend_IMSetting_SetTitle(Index)
	if(Index>0 and Index <= TagNum) then
		Friend_IMSetting_Explain:SetText(Titles[Index]);
	end
end

--设置按钮状态
function Friend_IMSetting_SetButton(Index)
	local i;
	if(Index == -1) then	--全部取消选定状态
		for i=1,TagNum do
			TagButtons[i]:SetCheck(0);
		end
		return;
	end
	if(Index>0 and Index <= TagNum) then
		TagButtons[Index]:SetCheck(1);
	end
end

function Friend_IMSetting_ResetPos()
	Friend_IMSetting_Frame:SetProperty("UnifiedXPosition", g_UnifiedXPosition);
	Friend_IMSetting_Frame:SetProperty("UnifiedYPosition", g_UnifiedYPosition);
end

function Friend_IMSetting_SelectChanged()
	local nName , nID = Friend_IMSetting_Select:GetCurrentSelect();
	if nID ~= nil then
		local ret = DataPool:IsChatGroupAllowMemberInvite(nID)
		if ret == 1 then
			Friend_IMSetting_Select1:SetCheck(1)
		else
			Friend_IMSetting_Select2:SetCheck(1)
		end
	end
end

function Friend_IMSetting_Modify2_Clicked()
	local nName , nID = Friend_IMSetting_Select:GetCurrentSelect();
	if nID == -1 then
		PushDebugMessage("#{JLQH_101026_20}")
		return
	end
	
	if nID ~= nil then
		local ret = DataPool:IsChatGroupAllowMemberInvite(nID)
		if Friend_IMSetting_Select2:GetCheck() == 1 then
			DataPool:ChangeAllowMemberInvite(nID , 1)
		else
			DataPool:ChangeAllowMemberInvite(nID , 0)
		end
	end

end
