-- 界面的默认位置
local g_UnifiedXPosition;
local g_UnifiedYPosition;

local g_UIType = 0;   --0 : 创建群  1 : 修改群信息
local g_GroupID = -1;
function Friend_IMCreateGroup_PreLoad()
	this:RegisterEvent("TOGGLE_CREATE_GROUP")
	this:RegisterEvent("SHOW_MODIFY_GROUPNOTICE")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


function Friend_IMCreateGroup_OnLoad()
	-- 保存界面的默认相对位置
	g_UnifiedXPosition	= Friend_IMCreateGroup_Frame:GetProperty("UnifiedXPosition");
	g_UnifiedYPosition	= Friend_IMCreateGroup_Frame:GetProperty("UnifiedYPosition");
end


function Friend_IMCreateGroup_OnEvent( event )
	if ( event == "TOGGLE_CREATE_GROUP" ) then
		if( this:IsVisible() and g_UIType == 0) then
			Friend_IMCreateGroup_Hide();
		else
			g_UIType = 0
			Friend_IMCreateGroup_Show();
		end
	elseif (event == "SHOW_MODIFY_GROUPNOTICE")  then
		g_GroupID = tonumber(arg0);
		g_UIType = 1
		Friend_IMCreateGroup_ShowNotice();
	elseif( event == "ADJEST_UI_POS" ) then
		Friend_IMCreateGroup_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Friend_IMCreateGroup_ResetPos()
	end
end

function Friend_IMCreateGroup_ShowNotice()
	Friend_IMCreateGroup_DragTitle:SetText("#{JLQH_101026_18}")
	Friend_IMCreateGroup_Name:Hide()
	local nName = DataPool:GetChatGroupName(g_GroupID)
	local nNotice = DataPool:GetChatGroupNotice(g_GroupID)
	Friend_IMCreateGroup_Name2:Show()
	Friend_IMCreateGroup_Name2:SetText(tostring(nName))
	Friend_IMCreateGroup_Notice:SetText(tostring(nNotice))
	Friend_IMCreateGroup_Notice:SetProperty("DefaultEditBox", "True");
	Friend_IMCreateGroup_Notice:SetSelected( 0, -1 );
	this:Show()
end
function Friend_IMCreateGroup_Show()
	Friend_IMCreateGroup_DragTitle:SetText("#{LTQH_XML_19}")
	Friend_IMCreateGroup_Name2:Hide()
	Friend_IMCreateGroup_Name:Show()
	Friend_IMCreateGroup_Name:SetText("")
	Friend_IMCreateGroup_Notice:SetText("")
	Friend_IMCreateGroup_Name:SetProperty("DefaultEditBox", "True");
	this:Show()
end

function Friend_IMCreateGroup_Hide()
	this:Hide()
end

function Friend_IMCreateGroup_Accept()
	if g_UIType == 0 then
		local txtName = Friend_IMCreateGroup_Name:GetText()
		local txtNotice = Friend_IMCreateGroup_Notice:GetText();
		if txtName == "" then
			PushDebugMessage("#{LTQH_100602_40}")
			return
		end
		local ret = DataPool:CreateGroup(txtName , txtNotice)
		if ret == 1 then
			this:Hide()	
		end	
	elseif g_UIType == 1 then
		local txtNotice = Friend_IMCreateGroup_Notice:GetText();
		local ret = DataPool:ModifyGroupNotice(g_GroupID , txtNotice)
		if ret == 1 then
			this:Hide()	
		end	
	end


end

function Friend_IMCreateGroup_ResetPos()
	Friend_IMCreateGroup_Frame:SetProperty("UnifiedXPosition", g_UnifiedXPosition);
	Friend_IMCreateGroup_Frame:SetProperty("UnifiedYPosition", g_UnifiedYPosition);
end