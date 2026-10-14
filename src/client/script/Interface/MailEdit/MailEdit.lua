--******************************************************************************
--
-- 发送邮件箱界面 by 陈永帅
--
--******************************************************************************
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition
local UI_Command_U = 20110518
local m_PetIndex = -1
local objCared = -1
local MAX_OBJ_DISTANCE = 3.0
local g_MailBindClickList={}
local g_MailEdit_item = {}
local g_UnifiedPos = {}
local g_UnifiedSzie = {}
local g_MailBindInfoList={}
local g_ItemSize= 370  -- 默认长度
local g_ZoneWorldID ={31,2015} --龙门世界号&新龙门客栈

--******************************************************************************

function MailEdit_PreLoad()

	-- 注册事件
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	-- 新邮件
	this:RegisterEvent("OPEN_SEND_NEW_MAIL")
	
	-- 更新邮件物品
	this:RegisterEvent("UPDATE_MAILITEM")
	
	-- 玩家从列表选定一只珍兽
	this:RegisterEvent( "REPLY_MISSION_PET" )	
	
	-- 玩家从列表中选择名字
	this:RegisterEvent( "UPDATE_MAILINAME" )
	
	-- 玩家关闭窗口
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 二次确认后发送
	this:RegisterEvent("OKSENDMAIL_CONFIRM")
end

function MailEdit_OnLoad()


	MailEdit_Target:SetText("")
	MailEdit_EditInfo:SetText("")
	MailEdit_Title:SetText("")
	MailEdit_InputMoney_Gold1:SetText("")
	MailEdit_InputMoney_Silver1:SetText("")
	MailEdit_InputMoney_CopperCoin1:SetText("")
	MailEdit_InputMoney_Gold2:SetText("")
	MailEdit_InputMoney_Silver2:SetText("")
	MailEdit_InputMoney_CopperCoin2:SetText("")
	
	g_Frame_UnifiedXPosition	= MailEdit_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= MailEdit_Frame:GetProperty("UnifiedYPosition")
	

	g_MailEdit_item[1] = MailEdit_Item1
	g_MailEdit_item[2] = MailEdit_Item2
	g_MailEdit_item[3] = MailEdit_Item3
	g_MailEdit_item[4] = MailEdit_Item4
	g_MailEdit_item[5] = MailEdit_Item5
	
	g_MailBindClickList[1] = MailEdit_Bind1
	g_MailBindClickList[2] = MailEdit_Bind2
	g_MailBindClickList[3] = MailEdit_Bind3
	
	g_MailBindInfoList[1] =MailEdit_Bind1_Info
	g_MailBindInfoList[1]:Hide()
	g_MailBindInfoList[2] =MailEdit_Bind2_Info
	g_MailBindInfoList[2]:Hide()
	g_MailBindInfoList[3] =MailEdit_Bind3_Info
	g_MailBindInfoList[3]:Hide()
		
	-- 金钱/珍兽/道具坐标
	g_UnifiedPos[1] = g_MailBindInfoList[1]:GetProperty("UnifiedYPosition")
	g_UnifiedPos[2] = g_MailBindInfoList[2]:GetProperty("UnifiedYPosition")
	g_UnifiedPos[3] = g_MailBindInfoList[3]:GetProperty("UnifiedYPosition")
		
	--金钱/珍兽/道具大小[干死..]
	g_UnifiedSzie[1] = 20
	g_UnifiedSzie[2] = 20
	g_UnifiedSzie[3] = 35
	
	-- 隐藏收费界面
	MailEdit_InputMoney_Frame2:Hide()
	MailEdit_Delete:Hide()
	MailEdit_Bind4_Info:Hide()
	MailEdit_Info_Frame:Hide()
		
	MailEdit_Frame:SetProperty("AbsoluteHeight", tostring(g_ItemSize))

end

function MailEdit_OnEvent( event )
	if ( event == "UI_COMMAND" and tonumber(arg0) == UI_Command_U ) then
		objCared = Get_XParam_INT(0)
		objCared = MailSystem:GetNPCServerID(objCared)
		this:CareObject(objCared, 1, "MailEdit") --关心界面
		MailEdit_Init()
	elseif( event == "UPDATE_MAILINAME") then
		local playerName = MailSystem:ReadSendMail("MailName")
		if playerName == nil then
			return
		end
		MailEdit_Target:SetText(playerName)
	elseif ( event == "REPLY_MISSION_PET" ) then
		MailEdit_SelectPet(arg0)
	elseif( event == "UPDATE_MAILITEM" ) then
		if tonumber(arg0) == 1 then -- 打开附件物品表
			g_MailBindClickList[3]:SetCheck(1)
			MailEdit_Bind_Clicked(3)
		end
		MailEdit_UpdateFrame()
	elseif( event == "ADJEST_UI_POS" ) then
		MailEdit_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		MailEdit_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			MailEdit_Close()
		end
	elseif (event == "OKSENDMAIL_CONFIRM") and tonumber(arg0) == 1 then -- 发送邮件
		MailEdit_OK_Send()
	end
	
end

--================================================
-- 默认相对位置
--================================================
function MailEdit_ResetPos()
	MailEdit_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition)
	MailEdit_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition)
end

--================================================
-- 更新界面
--================================================
function MailEdit_UpdateFrame()
	for i=0, 4 do
		local theAction = EnumAction(i,"mail_item");
		if theAction:GetID() ~= 0 then
			g_MailEdit_item[i+1]:SetActionItem(theAction:GetID())
		else
			g_MailEdit_item[i+1]:SetActionItem(-1)
		end
	end
end

--================================================
-- 单选框
--================================================
function MailEdit_Bind_Clicked(arg)
	MailEdit_Update_Clicked()
	
	local nCheck1 = g_MailBindClickList[arg]:GetCheck()
	if nCheck1 <= 0 then
		if arg == 3 then
			MailSystem:CloseSendNewMail(1)
			for i=1, 5 do
				g_MailEdit_item[i]:SetActionItem(-1)
			end
		elseif arg == 2 then
			Pet:SetPetLocation( m_PetIndex , -1 )
			Pet:UpdatePetList()
			Pet:ShowPetList( 0 )
			MailEdit_Pet:SetText("")
			MailEdit_Select:Enable()
			MailSystem:WritePetName("")
			MailSystem:WritePetGUID(0,0,0)
		elseif arg == 1 then
			MailEdit_InputMoney_Gold1:SetText("")
			MailEdit_InputMoney_Silver1:SetText("")
			MailEdit_InputMoney_CopperCoin1:SetText("")
			MailSystem:WriteUserMoney(0)
		end
	end
end

--================================================
-- 更新附件栏
--================================================
function MailEdit_Update_Clicked()

	local m_pos = 0
	local isCheck = 0
	local size = g_ItemSize
	for i = 1,3 do
		local nCheck = g_MailBindClickList[i]:GetCheck()
		if nCheck > 0 then
			m_pos = m_pos + 1
			g_MailBindInfoList[i]:SetProperty("UnifiedYPosition",g_UnifiedPos[m_pos])
			g_MailBindInfoList[i]:Show()
			isCheck =1
			if m_pos > 1 then
				size = size + g_UnifiedSzie[i]+5
			else
				size = size + g_UnifiedSzie[i]
			end
		else
			g_MailBindInfoList[i]:Hide()
		end
	end
	
	if isCheck == 1 then
		size = size + 42
	end
	

	MailEdit_Frame:SetProperty("AbsoluteHeight",size)
	-- 检查是否有按钮
	if m_pos == 0 then
		MailEdit_Delete:Hide()
		MailEdit_Bind4_Info:Hide()
		MailEdit_Info_Frame:Hide()
		MailEdit_InputMoney_Gold2:SetText("")
		MailEdit_InputMoney_Silver2:SetText("")
		MailEdit_InputMoney_CopperCoin2:SetText("")
		MailEdit_Bind4:SetCheck(0)
		MailEdit_InputMoney_Frame2:Hide()
	else
		MailEdit_Delete:Show()
		MailEdit_Bind4_Info:Show()
		MailEdit_Info_Frame:Show()
	end
	
end


-- 窗口关闭
function MailEdit_Close()
	this:Hide()
	this:CareObject(objCared, 0, "MailEdit")
	objCared = -1
end

--查找好友
function MailEdit_FindFriendClicked()
	PushEvent("OPEN_SEND_NEW_MAIL", 20110603)
end

function MailEdit_Update( event )
end

-- 选择珍兽
function MailEdit_Select_PetList()
	Pet:ShowPetList( 0 )
	Pet:ShowPetList( 1 )
end

--***************************************************
--
--***************************************************
function MailEdit_SelectPet( arg0 )
	
	--界面必须是开着
	if (not (this : IsVisible())) then
		return
	end

	--珍兽索引
	local petIdx = tonumber(arg0)
	if (-1 == petIdx) then
		return
	end
	
	--珍兽已被其它界面选中且排除单人珍兽繁殖界面，由后面判断
	if (Pet:GetPetLocation(petIdx) ~= -1 and Pet:GetPetLocation(petIdx) ~= 19) then
		return;
	end

	--判断是否珍兽加锁
	if (PlayerPackage:IsPetLock(petIdx) == 1) then
		PushDebugMessage("#{DRFZZC_091013_09}")
		return
	end

	--判断是否珍兽出战
	if (Pet : GetIsFighting(petIdx) == 1) then
		PushDebugMessage("#{DRFZZC_091013_10}")
		return
	end

	--判断珍兽是否穿了装备
	if (Pet : IsPetHaveEquip(petIdx) == 1) then
		PushDebugMessage("#{DRFZZC_091013_14}")
		return
	end
	
	--有内丹限制操作 Vega
	if Pet:LuaFnIsPetEquipNeiDan(petIdx) == 1 then
		PushDebugMessage("#{ZSND_230428_131}")
		return
	end

	local petName = Pet:GetPetList_Appoint( petIdx )
	if petName == nil then
		return
	end
	
	--填写珍兽名字
	MailEdit_Pet:SetText( petName )
	
	MailSystem:WritePetName(petName)
		
	--填写GUID
	local guidH,guidL = Pet:GetGUID( petIdx )
	MailSystem:WritePetGUID(guidH,guidL,1)
	
	if(m_PetIndex ~= -1) then
		Pet:SetPetLocation(m_PetIndex,-1);
	end
	m_PetIndex = petIdx
	

	Pet:SetPetLocation( petIdx , 19 )
	Pet:UpdatePetList()
	--MailEdit_Select:Disable()
	
end

--***************************************************
--发送邮件
--***************************************************
function MailEdit_SendMailItem()
	
	--安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	local level = Player:GetData("LEVEL")
	if level < 50 then
		PushDebugMessage("#{FJYX_110426_64}")
		return
	end
	
	local UserName  =  MailEdit_Target:GetText()
	if UserName == nil or UserName =="" then
		PushDebugMessage("#{FJYX_110426_65}")
		return
	end
	
	-- 检查是不是自己的好友
	if Friend:IsPlayerIsFriend( UserName )== 0 then
		PushDebugMessage("#{FJYX_110426_85}")
		MailSystem:WriteUserName("")
		MailSystem:WriteUserGUID("")
		MailEdit_Target:SetText("")
		return
	end
	
	
	-- 写入标题
	local mailTitle = MailEdit_Title:GetText()
	if mailTitle == nil or mailTitle =="" then
		PushDebugMessage("#{FJYX_110426_86}")
		return
	end
	
	-- 判断标题
	local pos = MailSystem:FilterSpecialChar(tostring(mailTitle))
	if pos == 0 then
		PushDebugMessage("#{FJYX_110426_88}")
		return
	end
	
	-- 标题没弄对
	local nOK = MailSystem:WriteUserTitle(mailTitle)
	if nOK == 0 then
		PushDebugMessage("#{FJYX_110426_168}")
		return
	end
	
	-- 写入内容
	local mailContex = MailEdit_EditInfo:GetText()
	if mailContex == nil then
		return
	end
	
	-- 判断内容
	local Contexpos = MailSystem:FilterSpecialChar(tostring(mailContex))
	if Contexpos == 0 then
		PushDebugMessage("#{FJYX_110426_88}")
		return
	end
	
	-- 表情包检查
	local strTemp = DataPool:CheckRMBFace(mailContex)
	if strTemp ~= mailContex then
		PushDebugMessage("#{BQB_091026_10}")
		return
	end
	
	MailSystem:WriteUserContex(mailContex)
		
	-- 发送金钱
	local gold = MailEdit_InputMoney_Gold1:GetText()
	local Silver = MailEdit_InputMoney_Silver1:GetText()
	local CopperCoin= MailEdit_InputMoney_CopperCoin1:GetText()
	
	local selfMoney = Player:GetData("MONEY")
	local selfMoney_JZ = Player:GetData("MONEY_JZ")
	if 2000 > (selfMoney+selfMoney_JZ) then --检查手续费
		PushDebugMessage("#{FJYX_110426_169}")
		return
	end
	local _, mailMoney = Bank:GetInputMoney(gold, Silver, CopperCoin)
	if mailMoney > selfMoney then 
		PushDebugMessage("#{FJYX_110426_169}")
		return
	end
	
	MailSystem:WriteUserMoney(mailMoney)
		
	-- 发送收费邮件
	local nCheck = MailEdit_Bind4:GetCheck()
	if nCheck > 0 then

		-- 发送金钱
		local gold2 = MailEdit_InputMoney_Gold2:GetText()
		local Silver2 = MailEdit_InputMoney_Silver2:GetText()
		local CopperCoin2= MailEdit_InputMoney_CopperCoin2:GetText()
		local _,mailMoney2 = Bank:GetInputMoney(gold2, Silver2, CopperCoin2)
			
		-- 检查是否有附件
		local IsPet = MailEdit_Pet:GetText()
		local IsItem = 0
		for i=0, 4 do
			local theAction = EnumAction(i,"mail_item");
			if theAction:GetID() ~= 0 then
				IsItem = IsItem + 1
			end
		end
		if IsPet == "" and IsItem == 0 and mailMoney2 > 0 then
			PushDebugMessage("#{FJYX_110426_212}")
			return
		end
		
		MailSystem:WriteUserReqMoney(mailMoney2)
		
	end
	
	PushEvent("DEMAIL_PRESENT_CONFIRM",1)
	
end

-- 二次确认后发邮件
function MailEdit_OK_Send()

	if (not (this : IsVisible())) then
		return
	end	
	
	MailSystem:SendMailItem()
	MailEdit_Close()
	
end

--***************************************************
--初始化邮件
--***************************************************
function MailEdit_Init()

	--检查是否在同一个World下
	local zoneWorldID = MailSystem:CheckZoneWordID(0)
	local flag = 0
	for i = 1,table.getn(g_ZoneWorldID) do
		if zoneWorldID == g_ZoneWorldID[i] then
			flag = 1
			break
		end
	end
	
	if flag == 0 then
		PushDebugMessage("#{FJYX_110426_209}")
		return
	end
	
	--安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	--二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	
	local level = Player:GetData("LEVEL")
	if level < 50 then
		PushDebugMessage("#{FJYX_110426_64}")
		return
	end
	
	this:Show()
	MailSystem:CleanMailAccessory()--清空附件
	MailSystem:CloseSendNewMail(1)
	Pet:SetPetLocation( m_PetIndex , -1 )
	Pet:UpdatePetList()
	Pet:ShowPetList( 0 )
	MailEdit_Pet:SetText("")
	MailEdit_Select:Enable()
	MailEdit_Target:SetText("")
	MailEdit_Title:SetText("")
	MailEdit_EditInfo:SetText("")
	MailEdit_InputMoney_Gold1:SetText("")
	MailEdit_InputMoney_Silver1:SetText("")
	MailEdit_InputMoney_CopperCoin1:SetText("")
	MailEdit_InputMoney_Gold2:SetText("")
	MailEdit_InputMoney_Silver2:SetText("")
	MailEdit_InputMoney_CopperCoin2:SetText("")
	MailEdit_Bind4:SetCheck(0)
	for i=1, 5 do
		g_MailEdit_item[i]:SetActionItem(-1)
	end
	
	g_MailBindClickList[1]:SetCheck(0)
	g_MailBindClickList[2]:SetCheck(0)
	g_MailBindClickList[3]:SetCheck(0)
	
	g_MailBindInfoList[1]:Hide()
	g_MailBindInfoList[2]:Hide()
	g_MailBindInfoList[3]:Hide()
	g_UnifiedSzie[1] = 20
	g_UnifiedSzie[2] = 20
	g_UnifiedSzie[3] = 35
	
	MailEdit_Bind4_Info:Hide()
	MailEdit_InputMoney_Frame2:Hide()
	MailEdit_Delete:Hide()
	MailEdit_Info_Frame:Hide()

	MailEdit_Frame:SetProperty("AbsoluteHeight", g_ItemSize)
end

--***************************************************
--打开收件箱
--***************************************************
function MailEdit_SendMailInfo()
	PushEvent("UI_COMMAND", 20110519)
	--MailEdit_Close()
end


function MailEdit_SelectFaceMotion()
	local yPos = MailEdit_Frame:GetProperty("AbsoluteYPosition")
	local XPos = MailEdit_Frame:GetProperty("AbsoluteXPosition")
	yPos = yPos + MailEdit_Face:GetProperty("AbsoluteYPosition")
	Talk:SelectFaceMotion("select", XPos+270 , yPos);
end

function MailEdit_SelectTextColor()
	local yPos = MailEdit_Frame:GetProperty("AbsoluteYPosition")
	local XPos = MailEdit_Frame:GetProperty("AbsoluteXPosition")
	yPos = yPos + MailEdit_LetterColor:GetProperty("AbsoluteYPosition")
	Talk:SelectTextColor("select",XPos + 250, yPos);
end

--***************************************************
-- 收费
--***************************************************
function MailEdit_ClickBind4()
	local nCheck = MailEdit_Bind4:GetCheck()
	if(nCheck > 0) then
		MailEdit_Bind4:SetCheck(1)
		MailEdit_InputMoney_Frame2:Show()
	else
		MailEdit_InputMoney_Gold2:SetText("")
		MailEdit_InputMoney_Silver2:SetText("")
		MailEdit_InputMoney_CopperCoin2:SetText("")
		MailEdit_Bind4:SetCheck(0)
		MailEdit_InputMoney_Frame2:Hide()
		MailSystem:WriteUserReqMoney(0)
	end
end

--***************************************************
-- 清空编辑
--***************************************************
function MailEdit_ClickClear()
	MailSystem:CleanMailAccessory()--清空附件
	MailSystem:CloseSendNewMail(1)
	Pet:SetPetLocation( m_PetIndex , -1 )
	Pet:UpdatePetList()
	Pet:ShowPetList( 0 )
	MailEdit_Pet:SetText("")
	MailEdit_Select:Enable()
	for i=1, 5 do
		g_MailEdit_item[i]:SetActionItem(-1)
	end
	MailEdit_InputMoney_Gold1:SetText("")
	MailEdit_InputMoney_Silver1:SetText("")
	MailEdit_InputMoney_CopperCoin1:SetText("")
	MailEdit_InputMoney_Gold2:SetText("")
	MailEdit_InputMoney_Silver2:SetText("")
	MailEdit_InputMoney_CopperCoin2:SetText("")
	
	g_MailBindClickList[1]:SetCheck(0)
	g_MailBindClickList[2]:SetCheck(0)
	g_MailBindClickList[3]:SetCheck(0)
	
	g_MailBindInfoList[1]:Hide()
	g_MailBindInfoList[2]:Hide()
	g_MailBindInfoList[3]:Hide()
	
	MailEdit_Bind4_Info:Hide()
	MailEdit_InputMoney_Frame2:Hide()
	MailEdit_Delete:Hide()
	MailEdit_Info_Frame:Hide()
	MailEdit_Bind4:SetCheck(0)
		
	g_UnifiedSzie[1] = 20
	g_UnifiedSzie[2] = 20
	g_UnifiedSzie[3] = 35
	MailEdit_Frame:SetProperty("AbsoluteHeight", g_ItemSize)
end

function MailEdit_OnHide()
	MailSystem:CloseSendNewMail(0)
	Pet:SetPetLocation( m_PetIndex , -1 )
	Pet:UpdatePetList()
	Pet:ShowPetList( 0 )
	PushEvent("CLOSE_MAIL_TARGET")
end
