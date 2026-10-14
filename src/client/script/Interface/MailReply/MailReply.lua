--******************************************************************************
--
-- 回复邮件箱界面 by 陈永帅
--
--******************************************************************************
-- 邮件物品
local g_MailReply_item = {}
local m_PetIndex = -1
local objCared = -1
local MAX_OBJ_DISTANCE = 3.0
local g_UnifiedPos = {}
local g_UnifiedSzie = {}
local g_MailBindClickList={}
local g_MailBindInfoList={}
local g_ItemSize= 370  -- 默认长度
local g_ZoneWorldID ={31,2015} --龙门世界号&新龙门客栈
--******************************************************************************

function MailReply_PreLoad()

	-- 注册事件
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	-- 回复邮件
	this:RegisterEvent("OPEN_SEND_NEW_MAIL")
		
	-- 更新邮件物品
	this:RegisterEvent("UPDATE_MAILITEM")
	
	-- 玩家从列表选定一只珍兽
	this:RegisterEvent( "REPLY_MISSION_PET" )	
	-- 玩家关闭窗口
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 二次确认后发送
	this:RegisterEvent("OKSENDMAIL_CONFIRM")
end

function MailReply_OnLoad()
	
	g_Frame_UnifiedXPosition	= MailReply_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= MailReply_Frame:GetProperty("UnifiedYPosition")
	
	MailReply_Title:SetText("")
	MailReply_EditInfo:SetText("")
	MailReply_InputMoney_Gold1:SetText("")
	MailReply_InputMoney_Silver1:SetText("")
	MailReply_InputMoney_CopperCoin1:SetText("")
	MailReply_InputMoney_Gold2:SetText("")
	MailReply_InputMoney_Silver2:SetText("")
	MailReply_InputMoney_CopperCoin2:SetText("")
		
	g_MailReply_item[1] = MailReply_Item1
	g_MailReply_item[2] = MailReply_Item2
	g_MailReply_item[3] = MailReply_Item3
	g_MailReply_item[4] = MailReply_Item4
	g_MailReply_item[5] = MailReply_Item5
	
	g_MailBindClickList[1] = MailReply_Bind1
	g_MailBindClickList[2] = MailReply_Bind2
	g_MailBindClickList[3] = MailReply_Bind3
	
	g_MailBindInfoList[1] =MailReply_Bind1_Info
	g_MailBindInfoList[1]:Hide()
	g_MailBindInfoList[2] =MailReply_Bind2_Info
	g_MailBindInfoList[2]:Hide()
	g_MailBindInfoList[3] =MailReply_Bind3_Info
	g_MailBindInfoList[3]:Hide()
		
	-- 金钱/珍兽/道具坐标
	g_UnifiedPos[1] = g_MailBindInfoList[1]:GetProperty("UnifiedYPosition")
	g_UnifiedPos[2] = g_MailBindInfoList[2]:GetProperty("UnifiedYPosition")
	g_UnifiedPos[3] = g_MailBindInfoList[3]:GetProperty("UnifiedYPosition")
		
	-- 隐藏收费界面
	MailReply_InputMoney_Frame2:Hide()
	MailReply_Delete:Hide()
	MailReply_Bind4_Info:Hide()
	MailReply_Info_Frame:Hide()
		
	--金钱/珍兽/道具大小
	g_UnifiedSzie[1] = 20
	g_UnifiedSzie[2] = 20
	g_UnifiedSzie[3] = 35
	MailReply_Frame:SetProperty("AbsoluteHeight", tostring(g_ItemSize))
	
end

function MailReply_OnEvent( event )
	
	if ( event == "UI_COMMAND" and (tonumber(arg0) == 20110519 or tonumber(arg0) == 20110518)  ) then
		objCared = Get_XParam_INT(0)
		objCared = MailSystem:GetNPCServerID(objCared)
		this:CareObject(objCared, 1, "MailReply") --关心界面
	elseif( event == "OPEN_SEND_NEW_MAIL" and tonumber( arg0 ) == 20110602) then
		MailReply_Init()
	elseif( event == "UPDATE_MAILITEM" ) then
		if tonumber(arg0) == 1 then -- 打开附件物品表
			g_MailBindClickList[3]:SetCheck(1)
			MailReply_Bind_Clicked(3)
		end
		MailReply_UpdateFrame()
	elseif ( event == "REPLY_MISSION_PET" ) then
			MailReply_SelectPet(arg0)
	elseif( event == "ADJEST_UI_POS" ) then
		MailReply_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		MailReply_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			MailReply_Close()
		end
	elseif (event == "OKSENDMAIL_CONFIRM") and tonumber(arg0) == 1 then -- 发送邮件
		MailReply_OK_Send()
	end
	
end

--================================================
-- 默认相对位置
--================================================
function MailReply_ResetPos()
	MailReply_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	MailReply_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

-- 选择珍兽
function MailReply_Select_PetList()
	Pet:ShowPetList( 0 )
	Pet:ShowPetList( 1 )
end

--================================================
-- 关闭窗口
--================================================
function MailReply_Close()
	this:CareObject(objCared, 0, "MailReply")
	objCared = -1
	this:Hide()
end

--================================================
-- 更新界面
--================================================
function MailReply_UpdateFrame()
	for i=0, 4 do
		local theAction = EnumAction(i,"mail_item")
		if theAction:GetID() ~= 0 then
			g_MailReply_item[i+1]:SetActionItem(theAction:GetID())
		else
			g_MailReply_item[i+1]:SetActionItem(-1)
		end
	end
end

--================================================
-- 初始化内容
--================================================
function MailReply_Init()

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
		PushDebugMessage("#{FJYX_110426_210}")
		return
	end
	
	-- 类型不对，无法回复
	local MailTyep = MailSystem:ReadSendMail("MailType")
	if MailTyep ~= nil and MailTyep == 2 then
		PushDebugMessage("#{FJYX_110426_32}")
		return
	end
	
	-- 自己的好友删除了
	local UserGUID = MailSystem:ReadSendMail("MailGUID")
	local group, index = DataPool:GetFriendByGUID(UserGUID)
	if index == -1 then
		PushDebugMessage("#{FJYX_110426_206}")
		return
	end
	local playerName = DataPool:GetFriend(group, index, "NAME")
	if playerName == nil or playerName == ""  then
		PushDebugMessage("#{FJYX_110426_206}")
		return
	end

	MailSystem:CloseSendNewMail(1)
	MailSystem:CleanMailAccessory()--清空附件
	Pet:SetPetLocation( m_PetIndex , -1 )
	Pet:UpdatePetList()
	Pet:ShowPetList( 0 )
	MailReply_Pet:SetText("")
	MailReply_Select:Enable()
	MailReply_Title:SetText("")
	MailReply_EditInfo:SetText("")
	MailReply_InputMoney_Gold1:SetText("")
	MailReply_InputMoney_Silver1:SetText("")
	MailReply_InputMoney_CopperCoin1:SetText("")
	MailReply_InputMoney_Gold2:SetText("")
	MailReply_InputMoney_Silver2:SetText("")
	MailReply_InputMoney_CopperCoin2:SetText("")
	MailReply_Bind4:SetCheck(0)
	MailReply_Target:SetText(playerName)
	
	g_MailReply_item[1]:SetActionItem(-1)
	g_MailReply_item[2]:SetActionItem(-1)
	g_MailReply_item[3]:SetActionItem(-1)
	g_MailReply_item[4]:SetActionItem(-1)
	g_MailReply_item[5]:SetActionItem(-1)
	
	g_MailBindClickList[1]:SetCheck(0)
	g_MailBindClickList[2]:SetCheck(0)
	g_MailBindClickList[3]:SetCheck(0)
	
	MailReply_Bind4_Info:Hide()
	MailReply_InputMoney_Frame2:Hide()
	MailReply_Delete:Hide()
	MailReply_Info_Frame:Hide()
		
	g_MailBindInfoList[1]:Hide()
	g_MailBindInfoList[2]:Hide()
	g_MailBindInfoList[3]:Hide()
	g_UnifiedSzie[1] = 20
	g_UnifiedSzie[2] = 20
	g_UnifiedSzie[3] = 35

	MailReply_Frame:SetProperty("AbsoluteHeight", g_ItemSize)
	
	this:Show()
end

--================================================
-- 发送邮件
--================================================
function MailReply_Send()

	--安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	-- 自己的好友删除了
	local UserGUID = MailSystem:ReadSendMail("MailGUID")
	local group, index = DataPool:GetFriendByGUID(UserGUID)
	if index == -1 then
		PushDebugMessage("#{FJYX_110426_206}")
		return
	end
	
	local level = Player:GetData("LEVEL")
	if level < 50 then
		PushDebugMessage("#{FJYX_110426_64}")
		return
	end
	
	local UserName  =  MailReply_Target:GetText()
	if UserName == nil or UserName =="" then
		PushDebugMessage("#{FJYX_110426_65}")
		return
	end
	
	-- 写入标题
	local mailTitle = MailReply_Title:GetText()
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
	local mailContex = MailReply_EditInfo:GetText()
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
		
	--检查手续费
	local selfMoney = Player:GetData("MONEY")
	local selfMoney_JZ = Player:GetData("MONEY_JZ")
	if 2000 > (selfMoney+selfMoney_JZ) then 
		PushDebugMessage("#{FJYX_110426_169}")
		return
	end
		
	-- 发送金钱
	local gold = MailReply_InputMoney_Gold1:GetText()
	local Silver = MailReply_InputMoney_Silver1:GetText()
	local CopperCoin= MailReply_InputMoney_CopperCoin1:GetText()
	local _, mailMoney = Bank:GetInputMoney(gold, Silver, CopperCoin)
	if mailMoney > selfMoney then 
		PushDebugMessage("#{FJYX_110426_169}")
		return
	end
	
	MailSystem:WriteUserMoney(mailMoney)
		
	-- 发送收费邮件
	local nCheck = MailReply_Bind4:GetCheck()
	if nCheck > 0 then
		
		-- 发送金钱
		local gold2 = MailReply_InputMoney_Gold2:GetText()
		local Silver2 = MailReply_InputMoney_Silver2:GetText()
		local CopperCoin2= MailReply_InputMoney_CopperCoin2:GetText()
		local _,mailMoney2 = Bank:GetInputMoney(gold2, Silver2, CopperCoin2)
			
		-- 检查是否有附件
		local IsPet = MailReply_Pet:GetText()
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
function MailReply_OK_Send()

	if (not (this : IsVisible())) then
		return
	end	
	
	MailSystem:SendMailItem()
	MailReply_Close()
end

-- 打开收件箱
function MailReply_SendMailBox()
	PushEvent("UI_COMMAND", 20110519)
	--MailReply_Close()
end

-- 聊天表情
function MailReply_SelectFaceMotion()
	local yPos = MailReply_Frame:GetProperty("AbsoluteYPosition")
	local XPos = MailReply_Frame:GetProperty("AbsoluteXPosition")
	yPos = yPos + MailReply_Face:GetProperty("AbsoluteYPosition")
	Talk:SelectFaceMotion("select", XPos+270 , yPos);
end

-- 颜色文字
function MailReply_SelectTextColor()
	local yPos = MailReply_Frame:GetProperty("AbsoluteYPosition")
	local XPos = MailReply_Frame:GetProperty("AbsoluteXPosition")
	yPos = yPos + MailReply_LetterColor:GetProperty("AbsoluteYPosition")
	Talk:SelectTextColor("select",XPos + 250, yPos);
end

--***************************************************
--珍兽列表
--***************************************************
function MailReply_SelectPet( arg0 )

	--判断单人珍兽繁殖
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
	MailReply_Pet:SetText( petName )
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
	--MailReply_Select:Disable()
	
end

--***************************************************
-- 收费
--***************************************************
function MailReply_ClickBind4()
	local nCheck = MailReply_Bind4:GetCheck()
	if(nCheck > 0) then
		MailReply_Bind4:SetCheck(1)
		MailReply_InputMoney_Frame2:Show()
	else
		MailReply_InputMoney_Gold2:SetText("")
		MailReply_InputMoney_Silver2:SetText("")
		MailReply_InputMoney_CopperCoin2:SetText("")
		MailReply_Bind4:SetCheck(0)
		MailReply_InputMoney_Frame2:Hide()
		MailSystem:WriteUserReqMoney(0)
	end
end

--***************************************************
-- 清除
--***************************************************
function MailReply_ClickClear()
	MailSystem:CleanMailAccessory()--清空附件
	MailSystem:CloseSendNewMail(1)
	Pet:SetPetLocation( m_PetIndex , -1 )
	Pet:UpdatePetList()
	Pet:ShowPetList( 0 )
	MailReply_Pet:SetText("")
	MailReply_Select:Enable()
	MailReply_InputMoney_Gold1:SetText("")
	MailReply_InputMoney_Silver1:SetText("")
	MailReply_InputMoney_CopperCoin1:SetText("")
	MailReply_InputMoney_Gold2:SetText("")
	MailReply_InputMoney_Silver2:SetText("")
	MailReply_InputMoney_CopperCoin2:SetText("")
	for i=1, 5 do
		g_MailReply_item[i]:SetActionItem(-1)
	end
	
	g_MailBindClickList[1]:SetCheck(0)
	g_MailBindClickList[2]:SetCheck(0)
	g_MailBindClickList[3]:SetCheck(0)
	
	g_MailBindInfoList[1]:Hide()
	g_MailBindInfoList[2]:Hide()
	g_MailBindInfoList[3]:Hide()
		
	MailReply_Bind4_Info:Hide()
	MailReply_InputMoney_Frame2:Hide()
	MailReply_Delete:Hide()
	MailReply_Info_Frame:Hide()
	MailReply_Bind4:SetCheck(0)
	
	g_UnifiedSzie[1] = 20
	g_UnifiedSzie[2] = 20
	g_UnifiedSzie[3] = 35

	MailReply_Frame:SetProperty("AbsoluteHeight", g_ItemSize)

end

--================================================
-- 单选框
--================================================
function MailReply_Bind_Clicked(arg)
	
	MailReply_Update_Clicked()
	
	local nCheck1 = g_MailBindClickList[arg]:GetCheck()
	if nCheck1 <= 0 then
		if arg == 3 then
			MailSystem:CloseSendNewMail(1)
			for i=1, 5 do
				g_MailReply_item[i]:SetActionItem(-1)
			end
		elseif arg == 2 then
			Pet:SetPetLocation( m_PetIndex , -1 )
			Pet:UpdatePetList()
			Pet:ShowPetList( 0 )
			MailReply_Pet:SetText("")
			MailReply_Select:Enable()
			MailSystem:WritePetName("")
			MailSystem:WritePetGUID(0,0,0)
		elseif arg == 1 then
			MailReply_InputMoney_Gold1:SetText("")
			MailReply_InputMoney_Silver1:SetText("")
			MailReply_InputMoney_CopperCoin1:SetText("")
			MailSystem:WriteUserMoney(0)
		end
	end

end

--================================================
-- 更新附件栏
--================================================
function MailReply_Update_Clicked()

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
	

	MailReply_Frame:SetProperty("AbsoluteHeight",size)
	-- 检查是否有按钮
	if m_pos == 0 then
		MailReply_Delete:Hide()
		MailReply_Bind4_Info:Hide()
		MailReply_Info_Frame:Hide()
		MailReply_Bind4:SetCheck(0)
		MailReply_InputMoney_Gold2:SetText("")
		MailReply_InputMoney_Silver2:SetText("")
		MailReply_InputMoney_CopperCoin2:SetText("")
		MailReply_InputMoney_Frame2:Hide()
	else
		MailReply_Delete:Show()
		MailReply_Bind4_Info:Show()
		MailReply_Info_Frame:Show()
	end
	
end

function MailReply_OnHide()
	MailSystem:CloseSendNewMail(0)
	Pet:SetPetLocation( m_PetIndex , -1 )
	Pet:UpdatePetList()
	Pet:ShowPetList( 0 )
end