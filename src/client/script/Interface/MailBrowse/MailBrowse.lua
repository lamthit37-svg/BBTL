--******************************************************************************
--
-- 查看邮件箱界面 by 陈永帅
--
--******************************************************************************
-- 邮件物品
local g_MailBrowse_item = {}
local g_MailBrowseRemoveList = {}
local objCared = -1
local MAX_OBJ_DISTANCE = 3.0
local g_MailBrowseSize= 340  -- 默认长度
local g_MailBrowseClickListInfo={}
local g_MailBrowseBase={} -- 基础控件名字
local g_MailBrowseAppendInfo={} --附件控件
local g_MailBrowseUnifiedPos={} --附件控件坐标
local g_MailBrowseUnifiedSize={} --附件控件大小
local g_MailBrowse_Info_FrameSize={} --附件控件大小
local g_MailBrowse_Pos=0
--******************************************************************************

function MailBrowse_PreLoad()

	-- 注册事件
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	-- 查看邮件
	this:RegisterEvent("UPDATE_MAILBROWSE")

	-- 玩家关闭窗口
	this:RegisterEvent("OBJECT_CARED_EVENT",false)

	-- 收取
	this:RegisterEvent("OKSENDMAIL_CONFIRM")
	-- 关闭界面事件
	this:RegisterEvent("CLOSE_MAIL_BROWSE")
	-- 成功领取附件
	this:RegisterEvent("RECEIVE_MAILIITEM")

end

function MailBrowse_OnLoad()

	g_Frame_UnifiedXPosition	= MailBrowse_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= MailBrowse_Frame:GetProperty("UnifiedYPosition")

	g_MailBrowse_item[1] = MailBrowse_Item1
	g_MailBrowse_item[2] = MailBrowse_Item2
	g_MailBrowse_item[3] = MailBrowse_Item3
	g_MailBrowse_item[4] = MailBrowse_Item4
	g_MailBrowse_item[5] = MailBrowse_Item5

	MailBrowse_Info_Frame:Hide()
	MailBrowse_Info_Text:Hide()


	g_MailBrowseClickListInfo[1] = MailBrowse_Bind1_Info
	g_MailBrowseClickListInfo[2] = MailBrowse_Bind2_Info
	g_MailBrowseClickListInfo[3] = MailBrowse_Bind3_Info
	g_MailBrowseClickListInfo[1]:Hide()
	g_MailBrowseClickListInfo[2]:Hide()
	g_MailBrowseClickListInfo[3]:Hide()

	g_MailBrowseUnifiedPos[1] = g_MailBrowseClickListInfo[1]:GetProperty("UnifiedYPosition")
	g_MailBrowseUnifiedPos[2] = g_MailBrowseClickListInfo[2]:GetProperty("UnifiedYPosition")
	g_MailBrowseUnifiedPos[3] = g_MailBrowseClickListInfo[3]:GetProperty("UnifiedYPosition")

	g_MailBrowseUnifiedSize[1] = 20
	g_MailBrowseUnifiedSize[2] = 20

	if 1 == SystemSetup:IsClassic() then
		g_MailBrowseUnifiedSize[3] = 35

		g_MailBrowse_Info_FrameSize[1] = 29
		g_MailBrowse_Info_FrameSize[2] = 29
		g_MailBrowse_Info_FrameSize[3] = 44
	else
		g_MailBrowseUnifiedSize[3] = 40

		g_MailBrowse_Info_FrameSize[1] = 30
		g_MailBrowse_Info_FrameSize[2] = 30
		g_MailBrowse_Info_FrameSize[3] = 50
	end

	g_MailBrowseBase[1] = MailBrowse_Target
	g_MailBrowseBase[2] = MailBrowse_Title
	g_MailBrowseBase[3] = MailBrowse_EditInfo
	g_MailBrowseBase[4] = MailBrowse_Time_Text

	g_MailBrowseAppendInfo[1] = MailBrowse_Money1
	g_MailBrowseAppendInfo[2] = MailBrowse_Pet
	g_MailBrowseAppendInfo[3] = MailBrowse_Money2


	-- 收费内容
	MailBrowse_Bind4_Info:Hide()
	MailBrowse_Receive:Hide()
	MailBrowse_Delete:SetText("#{FJYX_110426_40}")

	-- 空间初始高度
	MailBrowse_Frame:SetProperty("AbsoluteHeight", tostring(g_MailBrowseSize))
end

function MailBrowse_OnEvent( event )

	if ( event == "UI_COMMAND" and (tonumber(arg0) == 20110519 or tonumber(arg0) == 20110518)  ) then
		objCared = Get_XParam_INT(0)
		objCared = MailSystem:GetNPCServerID(objCared)
		this:CareObject(objCared, 1, "MailBrowse") --关心界面
	elseif( event == "UPDATE_MAILBROWSE" ) then
		MailBrowse_Updata()
	elseif( event == "ADJEST_UI_POS" ) then
		MailBrowse_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		MailBrowse_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			MailBrowse_Close()
		end
	elseif (event == "OKSENDMAIL_CONFIRM") and tonumber(arg0) == 2 then -- 收取邮件
		MailSystem:ReceiveItem()
	elseif (event == "OKSENDMAIL_CONFIRM") and tonumber(arg0) == 3 then -- 删除邮件
		MailBrowse_OK_ClickDelete()
	elseif (event == "CLOSE_MAIL_BROWSE") then
		MailBrowse_Close()
	elseif (event == "RECEIVE_MAILIITEM")then
		MailBrowse_OKReceive()
	end

end

--================================================
-- 默认相对位置
--================================================
function MailBrowse_ResetPos()
	MailBrowse_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	MailBrowse_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 默认相对位置
--================================================
function MailBrowse_Close()
	this:CareObject(objCared, 0, "MailBrowse")
	objCared = -1
	this:Hide()
end

--================================================
-- 更新窗口内容
--================================================
function MailBrowse_Updata()

	--特殊处理下类型
	local MailType = MailSystem:ReadSendMail("MailType")
	if MailType == nil then
		return
	end

	-- 用户名字为空有可能是回退邮件，普通邮件名字是不能为空的
	if MailType == 1 or MailType == 3 then
		local UserGUID = MailSystem:ReadSendMail("MailGUID")
		local group, index = DataPool:GetFriendByGUID(UserGUID)
		local userName = DataPool:GetFriend(group, index, "NAME")
		if userName == nil or userName == "" then --如果还是空的，靠，够了！！！
			userName = UserGUID
		end
		MailSystem:WriteUserName(userName)
	elseif MailType == 2 then
		MailSystem:WriteUserName("系统邮件")
	end

	-- 检查非法内容
	local playerName = MailSystem:ReadSendMail("MailName")
	if playerName == nil then
		return
	end


	local playerTitle = MailSystem:ReadSendMail("MailTitle")
	if playerTitle == nil then
		return
	end

	local playerContex = MailSystem:ReadSendMail("MailContex")
	if playerContex == nil then
		return
	end

	local createtime =MailSystem:ReadSendMail("MailCreateTime")
	if createtime == nil then
		return
	end

	-- 基本信息
	g_MailBrowseBase[1]:SetText(tostring(playerName))
	g_MailBrowseBase[2]:SetText(tostring(playerTitle))
	g_MailBrowseBase[3]:SetText(tostring(playerContex))
	g_MailBrowseBase[4]:SetText(tostring(createtime))

	-- 记录3个标记
	local indexTable = {0,0,0}

	-- 附件金钱
	local playerMoney = MailSystem:ReadSendMail("MailMoney")
	if playerMoney == nil then
		return
	end

	if playerMoney > 0 then
		g_MailBrowseAppendInfo[1]:SetProperty("MoneyNumber", tostring(playerMoney))
		indexTable[1] = 1
	end

	-- 珍兽名字
	local PetName = MailSystem:ReadSendMail("MailPetName")
	if PetName == nil then
		return
	end

	if PetName ~= "" then
		g_MailBrowseAppendInfo[2]:SetText(PetName)
		indexTable[2] = 1
	end

	for i=0, 4 do
		local theAction = EnumAction(i,"mail_item")
		if theAction:GetID() ~= 0 then
			indexTable[3] = 1
			g_MailBrowse_item[i+1]:SetActionItem(theAction:GetID())
		else
			g_MailBrowse_item[i+1]:SetActionItem(-1)
		end
	end

	MailBrowse_Item_Text:SetText("#{FJYX_110426_72}")

	MailBrowse_Update_Clicked(indexTable)

	this:Show()

end

--================================================
-- 回复邮件
--================================================
function MailBrowse_ClickedReply()
	local Type = MailSystem:ReadSendMail("MailType")
	if Type == nil then
		return
	end
	if Type == 2 then
		PushDebugMessage("#{FJYX_110426_32}")
		return
	end
	PushEvent("OPEN_SEND_NEW_MAIL", 20110602)
end

--================================================
-- 查看珍兽界面
--================================================
function MailBrowse_ClickPet()
	MailSystem:ShowMailPetInfo(0)
end

--================================================
-- 领取附件物品
--================================================
function MailBrowse_ClickReceive()
	-- 检查背包空间
	-- 检查珍兽空间
	local ReqMoney = MailSystem:ReadSendMail("ReqMoney")
	if ReqMoney <= 0  then
		MailSystem:ReceiveItem()
		return
	end
	PushEvent("DEMAIL_PRESENT_CONFIRM",2)
end

--================================================
-- 领取附件成功
--================================================
function MailBrowse_OKReceive()

	for i=1, 5 do
		 g_MailBrowse_item[i]:SetActionItem(-1)
	end

	-- 记录3个标记
	local indexTable = {0,0,0}
	MailBrowse_Update_Clicked(indexTable)

end

--================================================
-- 删除附件物品
--================================================
function MailBrowse_ClickDelete()
	if g_MailBrowse_Pos == 0 then --可以确认是没有附件的普通邮件
		MailBrowse_OK_ClickDelete()
		return
	end
	PushEvent("DEMAIL_PRESENT_CONFIRM",3)
end

--================================================
-- 二次确认删除附件物品
--================================================
function MailBrowse_OK_ClickDelete()

	-- 确认当前窗口是开着的
	if (not (this : IsVisible())) then
		return
	end

	MailSystem:RemoveMail()
	--this:Hide()
end

--================================================
-- 更新附件栏
--================================================
function MailBrowse_Update_Clicked(nFlag)

	g_MailBrowse_Pos = 0
	local isCheck = 0
	local tems = 0
	local size = g_MailBrowseSize
	for i = 1,3 do
		if nFlag[i] > 0 then
			g_MailBrowse_Pos = g_MailBrowse_Pos + 1
			g_MailBrowseClickListInfo[i]:SetProperty("UnifiedYPosition",g_MailBrowseUnifiedPos[g_MailBrowse_Pos])
			g_MailBrowseClickListInfo[i]:Show()
			isCheck =1
			if g_MailBrowse_Pos > 1 then
				if 1 == SystemSetup:IsClassic() then
					size = size + g_MailBrowseUnifiedSize[i]+5
					tems = tems + g_MailBrowse_Info_FrameSize[i]-4
				else
					size = size + g_MailBrowseUnifiedSize[i]
					tems = tems + g_MailBrowse_Info_FrameSize[i]-10
				end
			else
				size = size + g_MailBrowseUnifiedSize[i]
				tems = tems + g_MailBrowse_Info_FrameSize[i]
			end
		else
			g_MailBrowseClickListInfo[i]:Hide()
		end
	end

	if isCheck == 1 then
		size = size + 43
	end

	-- 检查是否有按钮
	if g_MailBrowse_Pos == 0 then
		MailBrowse_Info_Frame:Hide()
		MailBrowse_Receive:Hide()
		MailBrowse_Info_Text:Hide()
	else
		MailBrowse_Info_Frame:Show()
		MailBrowse_Receive:Show()
		MailBrowse_Info_Text:Show()
	end

	--特殊处理收费
	local ReqMoney = MailSystem:ReadSendMail("ReqMoney")
	if ReqMoney >0  then
		MailBrowse_Bind4_Info:Show()
		g_MailBrowseAppendInfo[3]:SetProperty("MoneyNumber", tostring(ReqMoney))
		MailBrowse_Bind4_Info:Show()
		MailBrowse_Money2_Frame:Show()
		size = size + 28
	else
		MailBrowse_Bind4_Info:Hide()
		MailBrowse_Money2_Frame:Hide()
	end

	-- 这样的算是收费邮件
	if g_MailBrowse_Pos > 0 and  ReqMoney >0 then
		MailBrowse_Delete:SetText("#{FJYX_110426_21}")
	else
		MailBrowse_Delete:SetText("#{FJYX_110426_40}")
	end

	MailBrowse_Info_Frame:SetProperty("AbsoluteHeight",tems)
	MailBrowse_Frame:SetProperty("AbsoluteHeight",size)

end
