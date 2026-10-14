--******************************************************************************
--
-- 附件邮件箱界面 by 陈永帅
--
--******************************************************************************
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition
local UI_Command_S = 20110519
local g_PageNum = 1			   -- 每页的索引
local g_maxPage = 1			   -- 最大页
local g_MailNew_page  = 6  -- 每页最多显示的数量
local g_MailNew_count = 0  -- 当前收件箱数量
local g_MailNewList={}		 -- 收件箱列表
local g_MailNewBKList={}
local g_MailNewIcon = {}	 -- 收件箱图标
local g_MailNewInfo = {}	 -- 收件箱内容
local CardImageInfo ={}
local BindButton={}					-- 单选按钮
local g_ClickFlash={}       -- 单选标记
local g_ClickSimple = nil    -- 当前选中索引
local g_RemoveList={}
local g_RemoveSize=0
local objCared = -1
local MAX_OBJ_DISTANCE = 3.0
local	g_tOrderPool	= {}    -- 过滤用的
local FilterType = 0
local g_SelectCount=0               --选择删除个数
local g_ItemTipList={}               --浮动框

local g_MailNew_ISShowNews = 0 --是否显示闪烁
--******************************************************************************

function MailBox_PreLoad()

	-- 注册事件
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 打开邮件相
	this:RegisterEvent("UPDATE_MAILBOX")
	-- 玩家关闭窗口
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 二次确认后删除
	this:RegisterEvent("OKSENDMAIL_CONFIRM")
end

function MailBox_OnLoad()

	g_Frame_UnifiedXPosition	= MailBox_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= MailBox_Frame:GetProperty("UnifiedYPosition")

	-- 每页内容
	g_MailNewList[0] = {MailNewType = MailBox_Info1_Type,MailNewName = MailBox_Info1_Name,MailNewDate = MailBox_Info1_Date,MailNewTitle = MailBox_Info1_Title}
	g_MailNewList[1] = {MailNewType = MailBox_Info2_Type,MailNewName = MailBox_Info2_Name,MailNewDate = MailBox_Info2_Date,MailNewTitle = MailBox_Info2_Title}
	g_MailNewList[2] = {MailNewType = MailBox_Info3_Type,MailNewName = MailBox_Info3_Name,MailNewDate = MailBox_Info3_Date,MailNewTitle = MailBox_Info3_Title}
	g_MailNewList[3] = {MailNewType = MailBox_Info4_Type,MailNewName = MailBox_Info4_Name,MailNewDate = MailBox_Info4_Date,MailNewTitle = MailBox_Info4_Title}
	g_MailNewList[4] = {MailNewType = MailBox_Info5_Type,MailNewName = MailBox_Info5_Name,MailNewDate = MailBox_Info5_Date,MailNewTitle = MailBox_Info5_Title}
	g_MailNewList[5] = {MailNewType = MailBox_Info6_Type,MailNewName = MailBox_Info6_Name,MailNewDate = MailBox_Info6_Date,MailNewTitle = MailBox_Info6_Title}

	for i = 0,5 do
		g_MailNewList[i].MailNewType:SetProperty("MouseMoveHollow", "True")
		g_MailNewList[i].MailNewName:SetProperty("MouseMoveHollow", "True")
		g_MailNewList[i].MailNewDate:SetProperty("MouseMoveHollow", "True")
		g_MailNewList[i].MailNewTitle:SetProperty("MouseMoveHollow", "True")
	end

	g_MailNewBKList[0] = MailBox_BK1
	g_MailNewBKList[0]:Hide()
	g_MailNewBKList[1] = MailBox_BK2
	g_MailNewBKList[1]:Hide()
	g_MailNewBKList[2] = MailBox_BK3
	g_MailNewBKList[2]:Hide()
	g_MailNewBKList[3] = MailBox_BK4
	g_MailNewBKList[3]:Hide()
	g_MailNewBKList[4] = MailBox_BK5
	g_MailNewBKList[4]:Hide()
	g_MailNewBKList[5] = MailBox_BK6
	g_MailNewBKList[5]:Hide()

	g_MailNewIcon[0] = MailBox_Item1
	g_MailNewIcon[1] = MailBox_Item2
	g_MailNewIcon[2] = MailBox_Item3
	g_MailNewIcon[3] = MailBox_Item4
	g_MailNewIcon[4] = MailBox_Item5
	g_MailNewIcon[5] = MailBox_Item6

	g_ItemTipList[0] = MailBox_Info1
	g_ItemTipList[1] = MailBox_ItemInfo2
	g_ItemTipList[2] = MailBox_ItemInfo3
	g_ItemTipList[3] = MailBox_ItemInfo4
	g_ItemTipList[4] = MailBox_ItemInfo5
	g_ItemTipList[5] = MailBox_ItemInfo6



	CardImageInfo[1] ="set:CircularTaskTool23 image:CircularTaskTool23_1"
	CardImageInfo[2] ="set:CircularTaskTool23 image:CircularTaskTool23_2"
	CardImageInfo[3] ="set:CircularTaskTool23 image:CircularTaskTool23_3"
	CardImageInfo[4] ="set:CircularTaskTool23 image:CircularTaskTool23_4"
	CardImageInfo[5] ="set:CircularTaskTool23 image:CircularTaskTool23_5"
	CardImageInfo[6] ="set:CircularTaskTool23 image:CircularTaskTool23_6"
	CardImageInfo[7] ="set:CircularTaskTool23 image:CircularTaskTool23_7"
	CardImageInfo[8] ="set:CircularTaskTool23 image:CircularTaskTool23_8"
	CardImageInfo[9] ="set:CircularTaskTool23 image:CircularTaskTool23_9"
	CardImageInfo[10] ="set:CircularTaskTool23 image:CircularTaskTool23_10"
	CardImageInfo[11] ="set:CircularTaskTool23 image:CircularTaskTool23_11"
	CardImageInfo[12] ="set:CircularTaskTool23 image:CircularTaskTool23_12"
	CardImageInfo[13] ="set:CircularTaskTool23 image:CircularTaskTool23_13"
	CardImageInfo[14] ="set:CircularTaskTool23 image:CircularTaskTool23_14"
	CardImageInfo[15] ="set:CircularTaskTool23 image:CircularTaskTool23_15"

	BindButton={MailBox_Bind1,MailBox_Bind2,MailBox_Bind3,MailBox_Bind4,MailBox_Bind5,MailBox_Bind6}
	g_ClickFlash[0]=MailBox_Flash1
	g_ClickFlash[1]=MailBox_Flash2
	g_ClickFlash[2]=MailBox_Flash3
	g_ClickFlash[3]=MailBox_Flash4
	g_ClickFlash[4]=MailBox_Flash5
	g_ClickFlash[5]=MailBox_Flash6

	MailBox_SearchMode:ComboBoxAddItem("全部",0)
	MailBox_SearchMode:ComboBoxAddItem("系统",1)
	MailBox_SearchMode:ComboBoxAddItem("普通",2)
	MailBox_SearchMode:ComboBoxAddItem("收费",3)
	MailBox_SearchMode:ComboBoxAddItem("回退",4)

	g_MailNew_ISShowNews = 0

end

function MailBox_OnEvent( event )
	g_MailNew_ISShowNews = 0
	if ( event == "UI_COMMAND" and tonumber(arg0) == UI_Command_S ) then
		objCared = Get_XParam_INT(0)
		objCared = MailSystem:GetNPCServerID(objCared)
		this:CareObject(objCared, 1, "MailBox") --关心界面
		MailBox_AskMail()
	elseif( event == "ADJEST_UI_POS" ) then
		MailBox_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		MailBox_ResetPos()
	elseif( event == "UPDATE_MAILBOX" ) then
		g_MailNew_count=0
		g_MailNew_ISShowNews = tonumber(arg0);
		MailBox_UpdataMail(g_PageNum)
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			MailBox_Close()
		end
	elseif (event == "OKSENDMAIL_CONFIRM") and tonumber(arg0) == 4 then -- 发送邮件
		MailBox_OK_ClickDelete()
	end

end

--================================================
-- 默认相对位置
--================================================
function MailBox_ResetPos()
	MailBox_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition)
	MailBox_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition)
end

--================================================
-- 写新邮件
--================================================
function MailBox_NewMail()
	PushEvent("UI_COMMAND", 20110518)
end

-- 窗口关闭
function MailBox_Close()
	this:Hide()
	this:CareObject(objCared, 0, "MailBox")
	objCared = -1

	g_MailNew_ISShowNews = 0
end
--================================================
-- 请求附件内容
--================================================
function MailBox_AskMail()

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

	MailBox_InitMail()
	MailSystem:AskMaiItemInfo()
end
--================================================
-- 更新附件内容
--================================================
function MailBox_UpdataMail(thePage)

	MailBox_UpdataCheck()

	-- 不能是空值
	if thePage == nil then
		return
	end


	if g_MailNew_count == 0 or g_MailNew_count ~= MailSystem:GetMailCount() then
		g_MailNew_count	= MailSystem:GetMailCount()
		MailBox_Order(g_MailNew_count)
	end

	local textColour = "#cffff00"
	if g_MailNew_count > 15 then
		textColour = "#cff0000"
	end

	--当前数量
	MailBox_Text2:SetText(textColour..tostring(g_MailNew_count).."/15")

	-- 计算总页数
	local	nTotalPage = 0
	if( g_MailNew_count < 1 ) then
		nTotalPage	= 1
	else
		nTotalPage	= math.floor((g_MailNew_count-1)/g_MailNew_page)+1
	end

	g_maxPage = nTotalPage
	g_PageNum = thePage

	-- 当前页的限制
	if(thePage < 1 or thePage > nTotalPage) then
		return
	end

	--是否显示闪烁
	if g_MailNew_ISShowNews == 1 then
		MailBox_Mail:Show()
		MailBox_MailAnimate:Play(true)
	else
		MailBox_Mail:Hide()
		MailBox_MailAnimate:Play(false)
	end

	local nStartIndex = (thePage-1)*g_MailNew_page
	local nActIndex   = nStartIndex
	local	i = 0
	while i < g_MailNew_page do
		local	idx	= g_tOrderPool[nActIndex+1]
		if idx == nil then
			idx = -1
		end

		g_MailNewBKList[i]:Hide()

		local MailID= MailSystem:GetAcceptInfo(idx,1)
		local MailType= MailSystem:GetAcceptInfo(idx,2)
		local MailName= MailSystem:GetAcceptInfo(idx,3)
		local MailTitle= MailSystem:GetAcceptInfo(idx,4)
		local ViewFlag= MailSystem:GetAcceptInfo(idx,5)
		local Money= MailSystem:GetAcceptInfo(idx,6)
		local HaveAppend= MailSystem:GetAcceptInfo(idx,7)
		local MailDate= MailSystem:GetAcceptInfo(idx,8)
		local UserGUID = MailSystem:GetAcceptInfo(idx,9)
		if MailID ~= nil and MailID ~= -1 then
			if MailType == 0 then  --普通邮件
				g_MailNewList[i].MailNewType:SetText("#{FJYX_110426_52}")
				g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[1])
				if ViewFlag == 1 then  -- 看过了
					g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[3])
				end
				if HaveAppend == 1 then  --有附件的图标
					g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[4])
					if ViewFlag == 1  then  -- 看过了
						g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[5])
					end
				end
			elseif MailType == 1 then  -- 玩家主动回退
				local group, index = DataPool:GetFriendByGUID(UserGUID)
				MailName = DataPool:GetFriend(group, index, "NAME")
				if(MailName == nil) then
					MailName = UserGUID
				end
				g_MailNewList[i].MailNewType:SetText("#{FJYX_110426_55}")
				g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[10])
				if ViewFlag == 1 then
					g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[11])
				end
				if HaveAppend == 0 then
					g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[12])
				end
			elseif MailType == 2 then  --系统邮件
				g_MailNewList[i].MailNewType:SetText("#{FJYX_110426_54}")
				g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[13])
				MailName = "系统邮件"
				if ViewFlag == 1 then
					g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[14])
				end
				if HaveAppend == 0 then
					g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[15])
				end
			elseif MailType == 3 then  --系统回退
				local group, index = DataPool:GetFriendByGUID(UserGUID)
				MailName = DataPool:GetFriend(group, index, "NAME")
				if(MailName == nil) then
					MailName = UserGUID
				end
				g_MailNewList[i].MailNewType:SetText("#{FJYX_110426_55}")
				g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[10])
				if ViewFlag == 1 then
					g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[11])
				end
				if HaveAppend == 0 then
					g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[12])
				end
			end

			-- 看看是不是收费邮件
			if Money ~= 0 then
				g_MailNewList[i].MailNewType:SetText("#{FJYX_110426_53}")
				g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[7])
				if ViewFlag == 1 then
					g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[8])
				end
				if HaveAppend == 0 then
					g_MailNewIcon[i]:SetProperty("Image",CardImageInfo[9])
				end
			end

			g_MailNewList[i].MailNewTitle:SetText(tostring(MailTitle))
			local MailTime = 0
			MailTime = math.floor(MailDate/86400)
			if MailTime == 0 then
				MailTime = math.floor(MailDate/3600).. "小时"
			else
				MailTime = MailTime.."天"
			end
			g_MailNewList[i].MailNewDate:SetText(tostring(MailTime))
			g_MailNewList[i].MailNewName:SetText(tostring(MailName))
			g_MailNewBKList[i]:Show()
		end
		i = i+1
		nActIndex = nActIndex+1
	end

	if( nTotalPage == 1 ) then
		MailBox_UpPage:Disable()
		MailBox_DownPage:Disable()
	else
		MailBox_UpPage:Show()
		MailBox_DownPage:Show()

		MailBox_UpPage:Enable()
		MailBox_DownPage:Enable()
		if ( g_PageNum == nTotalPage ) then
			MailBox_DownPage:Disable()
		end
		if ( g_PageNum == 1 ) then
			MailBox_UpPage:Disable()
		end
	end

	MailBox_CurrentlyPage:SetText(tostring(thePage) .. "/" .. tostring(nTotalPage))

end

--================================================
-- 下一页附件内容
--================================================
function MailBox_ClickDownPage()
	g_PageNum = g_PageNum + 1
	if( g_PageNum < 0 )  then
		g_PageNum = 0
	end

	MailBox_UpdataMail( g_PageNum )
end

--================================================
-- 上一页附件内容
--================================================
function MailBox_ClickUpPage()

	g_PageNum = g_PageNum - 1
	if ( g_PageNum >= g_maxPage ) then
		g_PageNum = g_maxPage
	end

	MailBox_UpdataMail( g_PageNum )

end

--================================================
-- 回复邮件
--================================================
function MailBox_ClickReply()

	if g_ClickSimple == nil  then
		PushDebugMessage("#{FJYX_110426_31}")
		return
	end

	-- 畅游精灵，无法回复
	local MailType = MailSystem:GetAcceptInfo(g_ClickSimple,2)
	if MailType ~= nil and MailType == 2 then
		PushDebugMessage("#{FJYX_110426_32}")
		return
	end

	-- 不是好友无法回复
	local IsOk = MailSystem:ReplyMail(g_ClickSimple)
	if IsOk == 0 then --发送条件不成功
		PushDebugMessage("#{FJYX_110426_206}")
		return
	end

	PushEvent("OPEN_SEND_NEW_MAIL", 20110602)

end

--================================================
-- 查看邮件
--================================================
function MailBox_ClickInfo(arg)
	if arg < 0 or arg > 5 then
		return
	end

	local nPos = g_tOrderPool[arg+1 + (g_PageNum-1)*g_MailNew_page]
	if nPos == nil then
		return
	end

	MailSystem:AskMailBrowseInfo(nPos)
end

--================================================
-- 单选邮件
--================================================
function MailBox_ClickInfoSimple(arg)

	if arg < 0 or arg > 5 then
		return
	end

	for i = 0,5 do
		if i == arg then
			g_ClickFlash[i]:Show()
			BindButton[i+1]:SetCheck(1)
		else
			g_ClickFlash[i]:Hide()
			BindButton[i+1]:SetCheck(0)
		end
	end

	-- 获取当前选中的页索引
	g_ClickSimple = g_tOrderPool[arg + 1 + (g_PageNum-1)*g_MailNew_page]


end
--================================================
-- 初始化附件内容
--================================================
function MailBox_InitMail()
	this:Show()
	MailBox_SearchMode:SetCurrentSelect(0)
	MailBox_Text2:SetText(0)
	g_ClickFlash[0]:Hide()
	g_ClickFlash[1]:Hide()
	g_ClickFlash[2]:Hide()
	g_ClickFlash[3]:Hide()
	g_ClickFlash[4]:Hide()
	g_ClickFlash[5]:Hide()
	g_ClickSimple = nil
	g_RemoveList={}
	FilterType = 0
	g_MailNew_count = 0
	g_RemoveSize = 0

	for i = 0,5 do
		g_MailNewList[i].MailNewType:SetProperty("MouseMoveHollow", "True")
		g_MailNewList[i].MailNewName:SetProperty("MouseMoveHollow", "True")
		g_MailNewList[i].MailNewDate:SetProperty("MouseMoveHollow", "True")
		g_MailNewList[i].MailNewTitle:SetProperty("MouseMoveHollow", "True")
	end

	MailBox_UpdataMail(1)
end

--================================================
-- 打开附件内容
--================================================
function MailBox_ClickOpen()

	if g_ClickSimple == nil then
		PushDebugMessage("#{FJYX_110426_34}")
		return
	end

	MailSystem:AskMailBrowseInfo(g_ClickSimple)
end

--================================================
-- 选择单选按钮
--================================================
function MailBox_Bind_Clicked(bind)
	MailBox_Bind7:SetCheck(0)
end

-- 删除邮件
function MailBox_ClickDelete()

	g_RemoveSize = 0
	local isHaveAppend = 0
	g_RemoveList={}
	for i = 1,g_MailNew_page do
		local nCheck = BindButton[i]:GetCheck()
		if nCheck > 0 and  g_tOrderPool[i + (g_PageNum-1)*g_MailNew_page] ~= nil then
			g_RemoveSize = g_RemoveSize + 1
			g_RemoveList[g_RemoveSize] = g_tOrderPool[i + (g_PageNum-1)*g_MailNew_page]
			local HaveAppend = MailSystem:GetAcceptInfo(g_RemoveList[g_RemoveSize],7)
			local Money      = MailSystem:GetAcceptInfo(g_RemoveList[g_RemoveSize],6)
			if HaveAppend > 0 or Money > 0 then
				isHaveAppend = 1
			end
		end
	end

	-- 判断在第几页上
	if g_RemoveSize == 0 then
		PushDebugMessage("#{FJYX_110426_42}")
		return
	end


	--有收费附件或者附件
	if isHaveAppend == 1 then
		PushEvent("DEMAIL_PRESENT_CONFIRM",4)
		return
	end

	--直接删除
	MailBox_OK_ClickDelete()

end

--二次群人后删除
function MailBox_OK_ClickDelete()

	if (not (this : IsVisible())) then
		return
	end

	-- 确认是否有邮件要删除
	if g_RemoveSize == nil then
		PushDebugMessage("#{FJYX_110426_42}")
		return
	end

	MailSystem:RemoveMailIndex(g_RemoveSize,g_RemoveList)

	--当前数量
	g_MailNew_count = g_MailNew_count - g_RemoveSize
	if g_MailNew_count < 0 then
		g_MailNew_count = 0
	end
	MailSystem:SetMailCount(g_MailNew_count)
	MailBox_Text2:SetText(tostring(g_MailNew_count))

	-- 刷新页面
	MailBox_InitMail()

end

-- 全选
function MailBox_ClickedBind7()
	local nCheck = MailBox_Bind7:GetCheck()
	for i = 1,g_MailNew_page do
		BindButton[i]:SetCheck(0)
		if nCheck <= 0  then
			BindButton[i]:SetCheck(1)
		end
	end
end

-- 重新刷新
function MailBox_UpdataCheck()
	for i = 1,g_MailNew_page do
		BindButton[i]:SetCheck(0)
		g_ClickFlash[i-1]:Hide()
	end
	MailBox_Bind7:SetCheck(0)
	g_ClickSimple = nil
end

--刷新
function MailBox_ClickRefresh()
	MailBox_AskMail()
end

-- 过滤
function MailBox_ClickSearchMode()
	local szName,nIndex = MailBox_SearchMode:GetCurrentSelect()
	if nIndex == nil or nIndex == -1 or szName =="" then
		return
	end

	FilterType = nIndex

	g_MailNew_count = 0
	MailBox_UpdataMail(1)
end


-- 标准的冒泡排序
function MailBox_PriorShow(num)
	local temp = -1
	local nPos = 0
	for i = 1,tonumber(num) do
		local CreateTime1= MailSystem:GetAcceptInfo(i-1,10)
		if CreateTime1 == nil then
			return
		end
		for j = i,tonumber(num) do
			local CreateTime2= MailSystem:GetAcceptInfo(j-1,10)
			if CreateTime2 == nil then
				return
			end
			if CreateTime1 < CreateTime2 then
				temp = g_tOrderPool[i]
				g_tOrderPool[i] = g_tOrderPool[j]
				g_tOrderPool[j] = temp
			end
		end
	end
end

--过滤
function MailBox_Order(Num)
	g_tOrderPool= {}
	local oldt	= {}
	for i = 1,tonumber(Num) do
	  oldt[i] = i-1
	end

	local count = 0
	if FilterType == 0 then
		g_tOrderPool= oldt
		MailBox_PriorShow(Num)
	else
		for i = 1,tonumber(Num) do
			local MailID= MailSystem:GetAcceptInfo(i-1,1)
			local Type= MailSystem:GetAcceptInfo(i-1,2)
			local MailName= MailSystem:GetAcceptInfo(i-1,3)
			local MailTitle= MailSystem:GetAcceptInfo(i-1,4)
			local ViewFlag= MailSystem:GetAcceptInfo(i-1,5)
			local Money= MailSystem:GetAcceptInfo(i-1,6)
			local HaveAppend= MailSystem:GetAcceptInfo(i-1,7)
			local MailDate = MailSystem:GetAcceptInfo(i-1,8)
			local UserGUID = MailSystem:GetAcceptInfo(i-1,9)
			-- 写的有点繁琐
			if FilterType == 1 and Type == 2 then --系统
			  g_tOrderPool[i]= i-1
				count = count + 1
			elseif FilterType == 2 and Type == 0 and Money <= 0 then --普通
				g_tOrderPool[i]= i-1
				count = count + 1
			elseif FilterType == 3 and Type == 0 and Money > 0 then --收费
				g_tOrderPool[i]= i-1
				count = count + 1
			elseif FilterType == 4 and (Type == 1 or Type == 3)  then --回退
				g_tOrderPool[i]= i-1
				count = count + 1
			else
				g_tOrderPool[i]=nil
			end
		end

		g_MailNew_count = count

		MailBox_PriorShow(Num)
		--在排序
		for i = 1,tonumber(Num) do
		  if g_tOrderPool[i] == nil then
				for j = i,tonumber(Num) do
					if g_tOrderPool[j] ~= nil then
						g_tOrderPool[i] = g_tOrderPool[j]
						g_tOrderPool[j] = nil
						break
					end
				end
			end
		end



	end

end

--================================================
-- 显示浮动框
--================================================
function MailBox_ShowTooltip(arg)

	if arg < 0 or arg > 5 then
		return
	end

	-- 获得当前索引
	local nIndex = nil
	nIndex = g_tOrderPool[arg + 1 + (g_PageNum-1)*g_MailNew_page]
	if nIndex == nil then
		return
	end

	local timeText,HaveAppend = MailSystem:GetMailListCreateTime(nIndex)
	if timeText == nil or HaveAppend == nil then
		return
	end
	if HaveAppend == 1 then
		timeText = timeText .."#r".."#H".."#{FJYX_110426_59}"
	end
	g_ItemTipList[arg]:SetToolTip(timeText)
end
