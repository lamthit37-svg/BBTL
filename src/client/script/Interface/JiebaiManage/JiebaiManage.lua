--江湖关系结义管理界面显示(客户端)

--//
--控件列表
local m_Controls = {} 				--控件列表
local sMenPaiName={"少林","明教","丐帮","武当","峨嵋","星宿","天龙","天山","逍遥","无门派","慕容","唐门","鬼谷","#{XQ_MP_15}", "#{XMPHM_210604_01}","#{GMGameInterface_Script_DataPool_Info_ERenGu}"}--桃花岛 menpai15 mptodo
local sPaiHangName={"#{JBLC_150528_193}","#{JBLC_150528_194}","#{JBLC_150528_195}","#{JBLC_150528_196}","#{JBLC_150528_197}","#{JBLC_150528_198}"}

local g_selectIndex = -1

local g_Frame_UnifiedPosition

function JiebaiManage_PreLoad()
	this:RegisterEvent("NEWFRIEND_JIEBAIMANAGER_OPEN")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--this:RegisterEvent("UI_COMMAND")
end

function JiebaiManage_OnLoad()
	m_Controls = {
		m_Frame = JiebaiManage_Frame,
		m_List = JiebaiManage_PositionList,
		--m_Turn = {JiebaiManage_turn1,JiebaiManage_turn2,JiebaiManage_turn3,JiebaiManage_turn4,JiebaiManage_turn5,JiebaiManage_turn6}
	}
	
	g_Frame_UnifiedPosition=m_Controls.m_Frame:GetProperty("UnifiedPosition")
	
end

function JiebaiManage_OnEvent(event)
	if ( event == "NEWFRIEND_JIEBAIMANAGER_OPEN" ) then
		--修改的是哪条数据
		g_selectIndex = tonumber(arg0)
		JiebaiManage_Open()	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JiebaiManage_Frame_On_ResetPos()
	elseif (event == "NEWFRIEND_JIEBAI_UPDATE") then
		JiebaiManage_Update()
	end
end

function JiebaiManage_Open()
	JiebaiManage_Update()
end

function JiebaiManage_Close()
	this:Hide()
end

function JiebaiManage_Frame_On_ResetPos()
	m_Controls.m_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function JiebaiManage_Update()
	--更新结拜数据
	--获取排行榜数据数量
	m_Controls.m_List:ClearListBox()
	local m_DataCount = DataPool:GetBrotherCount()
	if m_DataCount > 6 then
		m_DataCount = 6
	end
	if m_DataCount < 0 then
		m_DataCount = 0
	end
	for ind = 1, m_DataCount do
		m_Controls.m_List:AddItem(sPaiHangName[ind], ind - 1)
	end
	if this:IsVisible() then
	else
		this:Show()
	end		
end

--关闭按钮回调
function JiebaiManage_Close_Clicked()
	JiebaiManage_Close()
end

--管理按钮回调
function JiebaiManage_OK_Clicked()
	local m_DataCount = DataPool:GetBrotherCount()
	
	local idx = m_Controls.m_List:GetFirstSelectItem()
	if idx < 0 or idx >= m_DataCount then
		PushDebugMessage( "#{JBLC_150528_296}" )
		return
	end
	
	
	if g_selectIndex < 0 or g_selectIndex >= m_DataCount then
		PushDebugMessage( "#{JBLC_150528_217}" )
		--请先选中一个玩家
		return
	end
	
	local hguid = DataPool:GetBrotherInfoByInd(g_selectIndex, "CharGuidH")
	local lguid = DataPool:GetBrotherInfoByInd(g_selectIndex, "CharGuidL")
	
	--更换排行
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskModifyBrotherPos" )
		Set_XSCRIPT_ScriptID( 891126 )
		Set_XSCRIPT_Parameter( 0, hguid )
		Set_XSCRIPT_Parameter( 1, lguid )
		Set_XSCRIPT_Parameter( 2, idx )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	JiebaiManage_Close()
end
