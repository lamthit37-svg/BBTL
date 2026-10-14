--江湖关系结义界面显示(客户端)

--//
--控件列表
local m_Controls = {} 				--控件列表
local sMenPaiName={"少林","明教","丐帮","武当","峨嵋","星宿","天龙","天山","逍遥","无门派","慕容","唐门","鬼谷", "#{XQ_MP_15}","#{XMPHM_210604_01}","#{GMGameInterface_Script_DataPool_Info_ERenGu}"}--桃花岛 menpai15 mptodo
local sPaiHangName={"#{JBLC_150528_193}","#{JBLC_150528_194}","#{JBLC_150528_195}","#{JBLC_150528_196}","#{JBLC_150528_197}","#{JBLC_150528_198}"}

local m_PosName = {
	"#{JBYH_161011_1}",
	"#{JBYH_161011_2}",
	"#{JBYH_161011_3}",
	"#{JBYH_161011_4}",
	"#{JBYH_161011_5}",
	"#{JBYH_161011_10}"
	
}

local m_OldName = {"#{JBYH_161011_7}","#{JBYH_161011_6}"} -- 姐、哥
local m_YoungName = {"#{JBYH_161011_9}","#{JBYH_161011_8}"} -- 妹、弟

local g_Frame_UnifiedPosition
local g_selectIndex = -1

function NewFriend_Jiebai_PreLoad()
	this:RegisterEvent("NEWFRIEND_JIEBAI_OPEN")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("NEWFRIEND_JIEBAI_UPDATE")
	this:RegisterEvent("UI_COMMAND")
end

function NewFriend_Jiebai_OnLoad()
	m_Controls = {
		m_Frame = NewFriend_Jiebai_Frame,
		m_List = NewFriend_Jiebai_List,
		m_ManageButton = NewFriend_Jiebai_Manage,
		m_QuitButton = NewFriend_Jiebai_Quit,
		m_YQJiebai = NewFriend_Jiebai_YQ1,
		m_YQFuQi = NewFriend_Jiebai_YQ2,
		m_YQShiTu = NewFriend_Jiebai_YQ3
	}
	
	g_Frame_UnifiedPosition=m_Controls.m_Frame:GetProperty("UnifiedPosition")
		
end

function NewFriend_Jiebai_OnEvent(event)
	if ( event == "NEWFRIEND_JIEBAI_OPEN" ) then
		NewFriend_Jiebai_Open()	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewFriend_Jiebai_Frame_On_ResetPos()
	elseif( event == "ADJEST_UI_POS" ) then
		NewFriend_Jiebai_Frame_On_ResetPos()
	elseif (event == "NEWFRIEND_JIEBAI_UPDATE") then
		NewFriend_Jiebai_Update()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 891126 ) then
		local nOperate = Get_XParam_INT(0)
		if nOperate == 0 then
			PushEvent("NEWFRIEND_JIEBAIMANAGER_OPEN", g_selectIndex)
		end
	end
end

function NewFriend_Jiebai_Open()

	if Lua_IsChangeBroship() > 0 then
		if Player:GetData("Is2606S") == 1 then
			NewFriend_Jiebai_Explain_Text:SetText("#{QXF_260623_25}")
		else
			NewFriend_Jiebai_Explain_Text:SetText("#{XDJB_0401_04}")
		end
		NewFriend_Jiebai_GetQYZ:Show()
	else
		if Player:GetData("Is2606S") == 1 then
			NewFriend_Jiebai_Explain_Text:SetText("#{QXF_260623_26}")
		else
			NewFriend_Jiebai_Explain_Text:SetText("#{JBLC_150528_319}")
		end
		NewFriend_Jiebai_GetQYZ:Hide()
	end
	
	NewFriend_Jiebai_Update()
	NewFriend_Jiebai_SetDynamic_Pos()
	--设置结拜页签选中
	m_Controls.m_YQJiebai:SetProperty("Selected", "True");
	m_Controls.m_YQFuQi:SetProperty("Selected", "False");
	m_Controls.m_YQShiTu:SetProperty("Selected", "False");

	this:Show()
			
	--结拜引导任务显示 有任务未完成的时候 显示旋转按钮
	CloseFreshManGuide()
	if DataPool:Lua_IsHaveMission(1361) > 0 and DataPool:Lua_IsMissionHaveDone(1361) <= 0 then
		local fX, fY = this:GetChildOffset("NewFriend_Jiebai_Zhenfa_Enter")
		OpenFreshManGuide(1, 77, fX, fY, "NewFriend_Jiebai", "northwest")
		SetTimer("NewFriend_Jiebai", "CloseFreshManGuide()", 10000)
		NewFriend_Zhenfa_Enter_Animate:Play(true)
		NewFriend_Jiebai_Zhenfa_Enter:SetText("#{JBZY_150629_126}") ;
	else
		CloseFreshManGuide()
		NewFriend_Zhenfa_Enter_Animate:Play(false)
		NewFriend_Jiebai_Zhenfa_Enter:SetText("#{JBLC_150528_280}") ;
	end	
	
	local n2606S = Player:GetData("Is2606S")  
	if n2606S == 1 then
		NewFriend_Jiebai_Zhenfa_Enter:Hide()
	else
		NewFriend_Jiebai_Zhenfa_Enter:Show()
	end
	
	--请求结拜数据
	DataPool:AskBrotherInfo()
end

function NewFriend_Jiebai_SetDynamic_Pos()
	if (IsWindowShow( "Friend_MaritalRelations")) then
		CloseWindow( "Friend_MaritalRelations", true );
	end
	if ( IsWindowShow( "NewFriend_ST" ) ) then
		CloseWindow( "NewFriend_ST", true );
	end
	if ( IsWindowShow( "Friend_Recall" ) ) then
		CloseWindow( "Friend_Recall", true );
	end	
    local selfFriendClanUnionPos = Variable:GetVariable("SelfFriendClanUnionPos")
	if( selfFriendClanUnionPos ~= nil) then
	    m_Controls.m_Frame:SetProperty("UnifiedPosition", selfFriendClanUnionPos )
	end
end

function NewFriend_Jiebai_Close()
	this:Hide()
end

function NewFriend_Jiebai_Frame_On_ResetPos()
	m_Controls.m_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function NewFriend_Jiebai_Update()
	--更新结拜数据
	m_Controls.m_List:RemoveAllItem()
	--获取排行榜数据数量
	local m_DataCount = DataPool:GetBrotherCount()
	local selfPos = DataPool:GetSelfBrotherInfo("CharPos")
	NewFriend_Jiebai_GetQYZ:Disable()
	if m_DataCount > 1 then
		NewFriend_Jiebai_GetQYZ:Enable()
		for ind = 1, m_DataCount do
			local charName = DataPool:GetBrotherInfoByInd(ind - 1, "CharName")
			local charPos = DataPool:GetBrotherInfoByInd(ind - 1, "CharPos")
			local charLevel = DataPool:GetBrotherInfoByInd(ind - 1, "CharLevel")
			local charMPID = DataPool:GetBrotherInfoByInd(ind - 1, "CharMPID")
			local charTitle = DataPool:GetBrotherInfoByInd(ind - 1, "CharTitle")
			local isOnline = DataPool:GetBrotherInfoByInd(ind - 1, "IsOnline")
			local charSex = DataPool:GetBrotherInfoByInd(ind - 1, "CharSex")
			if charPos == nil then
				return
			end
			if charPos < 0 or charPos > 5 then
				return
			end
			if charMPID == nil then
				return
			end
			if charMPID < 0 or charMPID > 15 then--menpai15 mptodo
				return
			end
			local color = "#W"
			if isOnline ~= 1 then
				color = "#c808080"
			end
			
			local sexName = sPaiHangName[charPos + 1]
			
			if (charSex == 1 or charSex == 0) and selfPos ~= nil then
				
				if  charPos < selfPos then
					sexName = m_PosName[charPos + 1]..m_OldName[charSex + 1]
				elseif charPos > selfPos then
					sexName = m_PosName[charPos + 1]..m_YoungName[charSex + 1]
				else
					if selfPos == 0 then
						sexName = m_PosName[1]..m_OldName[charSex + 1]
					else
						sexName = m_PosName[charPos + 1]..m_YoungName[charSex + 1]
					end
				end
			
			end
			
			m_Controls.m_List:AddNewItem(color .. charName, 0 , ind - 1)
			m_Controls.m_List:AddNewItem(color .. sexName, 1 , ind - 1)
			m_Controls.m_List:AddNewItem(color .. tostring(charLevel), 2 , ind - 1)
			m_Controls.m_List:AddNewItem(color .. sMenPaiName[charMPID + 1], 3 , ind - 1)
			if charTitle == nil or charTitle == "" then
				m_Controls.m_List:AddNewItem(color .. "--", 5 , ind - 1)
			else
				m_Controls.m_List:AddNewItem(color .. charTitle, 5 , ind - 1)
			end
		end	
	end
	--判断自己是不是老大
	if tonumber(selfPos) == 0 and selfPos ~= nil then
		m_Controls.m_ManageButton:SetProperty("Disabled", "False");
		m_Controls.m_QuitButton:SetProperty("Disabled", "False");
	else
		m_Controls.m_ManageButton:SetProperty("Disabled", "True");
		m_Controls.m_QuitButton:SetProperty("Disabled", "True");
	end
	
	--显示界面
	--this:Show()
end

--关闭按钮回调
function NewFriend_Jiebai_Close_Clicked()
	NewFriend_Jiebai_Close()
end

--标签回调
function NewFriend_Jiebai_Switch(pageNum)
	if pageNum == 1 then
		Variable:SetVariable("SelfFriendClanUnionPos", m_Controls.m_Frame:GetProperty("UnifiedPosition"), 1);
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnAskShiMenInfo")
			Set_XSCRIPT_ScriptID(891116)
			Set_XSCRIPT_Parameter(0,2);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif pageNum == 2 then
		
	elseif pageNum == 3 then
		Variable:SetVariable("SelfFriendClanUnionPos", m_Controls.m_Frame:GetProperty("UnifiedPosition"), 1);
		ZhanTuanInterface:FriendMaritalRelations()
	end
end

--管理按钮回调(修改排位)
function NewFriend_Jiebai_Manage_Clicked()
	if (IsInTServer() == 1) then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	g_selectIndex = m_Controls.m_List:GetSelectItem()
	local m_DataCount = DataPool:GetBrotherCount()
	if g_selectIndex < 0 or g_selectIndex >= m_DataCount then
		PushDebugMessage( "#{JBLC_150528_217}" )
		--请先选中一个玩家
		return
	end
	
	--检测是否可以退出结拜
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskCheckBrotherManager" )
		Set_XSCRIPT_ScriptID( 891126 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function NewFriend_Jiebai_GetQYZ_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientAddBrotherShip")
		Set_XSCRIPT_ScriptID(891126)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--逐出结拜按钮回调
function NewFriend_Jiebai_Quit_Clicked()
	
	local isInHell = IsInHell()
	if isInHell == 1 then
		return
	end
	
	if (IsInTServer() == 1) then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	
	local listIndex = m_Controls.m_List:GetSelectItem()
	local m_DataCount = DataPool:GetBrotherCount()
	if listIndex < 0 or listIndex >= m_DataCount then
		PushDebugMessage( "#{JBLC_150528_217}" )
		--请先选中一个玩家
		return
	end
	local charGuidH = DataPool:GetBrotherInfoByInd(listIndex, "CharGuidH")
	local charGuidL = DataPool:GetBrotherInfoByInd(listIndex, "CharGuidL")
	--逐出结拜关系
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskQuitswear" )
		Set_XSCRIPT_ScriptID( 891126 )
		Set_XSCRIPT_Parameter( 0, charGuidH)
		Set_XSCRIPT_Parameter( 1, charGuidL)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--退出结拜
function NewFriend_Jiebai_Out_Clicked()
	local isInHell = IsInHell()
	if isInHell == 1 then
		return
	end
	
	if (IsInTServer() == 1) then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
  
	--检测是否可以退出结拜
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskCheckUnswear" )
		Set_XSCRIPT_ScriptID( 891126 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
	
--进入阵法界面
function NewFriend_Jiebai_ZhenfaEnter_Clicked()
	PushEvent("UI_COMMAND",20150608)
		
	CloseFreshManGuide()
	NewFriend_Zhenfa_Enter_Animate:Play(false)
	NewFriend_Jiebai_Zhenfa_Enter:SetText("#{JBLC_150528_280}") ;
	--NewFriend_Jiebai_Close()
end