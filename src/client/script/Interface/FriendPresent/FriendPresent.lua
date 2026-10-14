-- FriendPresent.lua
-- 好友升级送好友界面

local g_FriendGUID = ""
local g_FriendName = ""
local g_FriendLevel = 0
local g_BagIndex = -1
local g_InputMoney = 0

local g_FriendPresent_Frame_UnifiedPosition

function FriendPresent_PreLoad()
	this:RegisterEvent("OPEN_FRIEND_PRESENT")		--打开界面
	this:RegisterEvent("UPDATE_FRIEND_PRESENT")		--换道具后更新界面
	this:RegisterEvent("FRIEND_PRESENT_SENDNOW")	--二次确认界面调过来的，立即发送
	this:RegisterEvent("FRIEND_PRESENT_SUCCESS")	--赠礼消息发送成功的后续处理
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
end

function FriendPresent_OnLoad()
	FriendPresent_Clear()
	-- 保存界面的默认相对位置
	g_FriendPresent_Frame_UnifiedPosition = FriendPresent_Frame:GetProperty("UnifiedPosition")
end

function FriendPresent_OnEvent(event)
	if (event == "OPEN_FRIEND_PRESENT") then	-- 打开界面
		if arg0 == nil then
			return
		end
		g_FriendGUID = arg0
		FriendPresent_InitFrame()
	
	elseif (event == "UPDATE_FRIEND_PRESENT") then
		if arg0 ~= nil then
			FriendPresent_UpdateFrame(tonumber(arg0))
		end
	
	elseif (event == "FRIEND_PRESENT_SENDNOW") then
		FriendPresent_SendNow_OK()
	
	elseif (event == "FRIEND_PRESENT_SUCCESS") then
		if arg0 == nil then
			return
		end
		FriendPresent_Success(tonumber(arg0))
	
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	
	elseif (event == "ADJEST_UI_POS") then
		FriendPresent_Frame_On_ResetPos()
	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FriendPresent_Frame_On_ResetPos()
	end
end

function FriendPresent_InitFrame()
	FriendPresent_Clear()
	
	if g_FriendGUID == "" then
		return
	end
	
	local group, index = DataPool:GetFriendByGUID(g_FriendGUID)
	g_FriendName = DataPool:GetFriend(group, index, "NAME")
	g_FriendLevel = DataPool:GetFriend(group, index, "LEVEL_MSGBALL")
	
	local relationType = DataPool:GetFriend(group, index, "RELATION_TYPE")
	local sex = DataPool:GetFriend(group, index, "SEX")
	
	local str = "#{SJSL_110507_14}"
	if relationType == 2 then	--结拜
		if tonumber(sex) == 0 then
			str = str.."#{SJSL_110507_46}"
		else
			str = str.."#{SJSL_110507_47}"
		end
	elseif relationType == 3 then	--结婚
		if tonumber(sex) == 0 then
			str = str.."#{SJSL_110507_42}"
		else
			str = str.."#{SJSL_110507_43}"
		end
	elseif relationType == 7 then	--师傅
		str = str.."#{SJSL_110507_44}"
	elseif relationType == 8 then	--徒弟
		str = str.."#{SJSL_110507_45}"
	else
		str = str.."#{SJSL_110507_41}"
	end
	str = str..g_FriendName.."#{SJSL_110507_34}"..g_FriendLevel.."#{SJSL_110507_35}"
	
	FriendPresent:SetText(str)
	
	if (KVKInterface:IsInKVKServer() == 1) then
		PushDebugMessage("#{SJSL_110507_40}")
		return
	end
	
	if DataPool:GetFriend(group, index, "FRIEND_PRESENT") == 0 then
		PushDebugMessage("#{SJSL_110507_08}")
		return
	end
	
	this:Show()
	
	DataPool:UpdateFriendInfo(g_FriendName)		--必须刷新下好友信息
end

function FriendPresent_UpdateFrame(pos_packet)
	local theAction = EnumAction(pos_packet, "packageitem")
	local itemIndex = PlayerPackage:GetItemTableIndex(pos_packet)
	
	if theAction:GetID() == 0 then
		return
	end
	
	--是否绑定
	if GetItemBindStatus(pos_packet) == 1 then
		PushDebugMessage("#{SJSL_110507_15}")
		return
	end
	
	--是否有效期，在Server判断
	
	--是否贵重
	if PlayerPackage:IsProtectGoods(pos_packet) == 1 then
		PushDebugMessage("#{SJSL_110507_17}")
		return
	end
	
	--是否锁定
	if PlayerPackage:IsLock(pos_packet) == 1 then
		PushDebugMessage("#{SJSL_110507_18}")
		return
	end
	
	FriendPresent_ProductItem:SetActionItem(theAction:GetID())
	
	if g_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_BagIndex, 0)
	end
	g_BagIndex = pos_packet
	LifeAbility:Lock_Packet_Item(g_BagIndex, 1)
end

function FriendPresent_Resume_Item()
	if g_BagIndex ~= -1 then
		FriendPresent_ProductItem:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(g_BagIndex, 0)
		g_BagIndex = -1
	end
end

--点击“立即赠送”按钮，弹出二次确认界面
function FriendPresent_Send_Now()
	if IsInTServer() == 1 then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end

	--是否安全时间
	if DataPool:GetLeftProtectTime() > 0 then
		PushDebugMessage("#{SJSL_110507_20}")
		return
	end
	
	--二级密码是否处于开启状态
	--if Player:IsLocked() == nil or Player:IsLocked() == 0 then
	if CheckPhoneMibaoAndMinorPassword() == 0 then
		--PushDebugMessage("#{SJSL_110507_21}")
		return
	end
	
	--是否互为好友，在Server判断，Server会保证其互为好友关系滴~~
	
	--道具是否具有有效期，在Server判断
	
	local szGold = FriendPresent_Gold:GetText()
	local szSilver = FriendPresent_Silver:GetText()
	local szCopperCoin = FriendPresent_CopperCoin:GetText()
	
	g_InputMoney = 0
	_, g_InputMoney = Bank:GetInputMoney(szGold, szSilver, szCopperCoin)
	
	local nTotalMoney = Player:GetData("MONEY")
	
	--钱够否
	if g_InputMoney > nTotalMoney then
		PushDebugMessage("#{SJSL_110507_23}")
		return
	end
	
	--啥也没有
	if g_InputMoney == 0 and g_BagIndex == -1 then
		PushDebugMessage("#{SJSL_110507_24}")
		return
	end
	
	--弹出二次确认对话框
	local str = string.format("#{SJSL_110507_25}")
	if g_BagIndex ~= -1 then
		str = str..string.format("%d#{SJSL_110507_26}%s", PlayerPackage:GetBagItemNum(g_BagIndex), PlayerPackage:GetBagItemName(g_BagIndex))
	end
	if g_InputMoney ~= 0 then
		if g_BagIndex ~= -1 then
			str = str..string.format("#{SJSL_110507_27}")
		end
		str = str..string.format("#{_MONEY%d}", g_InputMoney)
	end
	str = str..string.format("#{SJSL_110507_28}%s#{SJSL_110507_36}", g_FriendName)
	
	PushEvent("FRIEND_PRESENT_CONFIRM", str)
end

--二次确认了，已经不需要再检查了，直接发送喽~~
function FriendPresent_SendNow_OK()
	if g_FriendGUID == "" then
		return
	end
	
	--local strContex = string.format(ParserString("SJSL_110507_32", "NoColor"), g_FriendName, g_FriendLevel, Player:GetName())
	--建议使用一个接口发送附件邮件
	MailSystem:WriteUserGUID(g_FriendGUID)
	MailSystem:WriteUserName(g_FriendName)
	MailSystem:WriteUserTitle(ParserString("SJSL_110507_31", "NoColor"))
	--MailSystem:WriteUserContex(strContex)
	if g_InputMoney > 0 then
		MailSystem:WriteUserMoney(g_InputMoney)
	end
	MailSystem:SendPresentMail(g_FriendGUID, g_BagIndex)
end

--发送成功的后续处理
function FriendPresent_Success(arg0)
	if arg0 ~= nil and arg0 == 1 then
		--需要重新获取名字和级别
		local group, index = DataPool:GetFriendByGUID(g_FriendGUID)
		g_FriendName = DataPool:GetFriend(group, index, "NAME")
		g_FriendLevel = DataPool:GetFriend(group, index, "LEVEL_MSGBALL")
		
		--清除赠礼消息
		DataPool:SetFriendPresent(g_FriendGUID, 1, 0)
		
		--醒目提示
		local str = string.format(ParserString("SJSL_110507_30", "NoColor"), g_FriendName)
		PushDebugMessage(str)
		
		--系统提示邮件，公告，SNS，Server处理
		--请注意,如果需要在参数中传64位的角色GUID,请按照下面的方式先将GUID拆分为
		--32位的高低两位,再在服务器脚本中通过LuaFnCombine2GUID64接口拼接
		local FriendGuidH,FriendGuidL = SplitGUID64(g_FriendGUID)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnSuccess")
			Set_XSCRIPT_ScriptID(806021)
			Set_XSCRIPT_Parameter(0, FriendGuidH)
			Set_XSCRIPT_Parameter(1, FriendGuidL)
			Set_XSCRIPT_Parameter(2, g_FriendLevel)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
		
		PushEvent("UPDATE_FRIEND")
	end
	
	this:Hide()
end

function FriendPresent_ChangeMoney()
	--Nothing
end

function FriendPresent_Clear()
	FriendPresent:SetText("")
	FriendPresent_ProductItem:SetActionItem(-1)
	FriendPresent_Gold:SetText("")
	FriendPresent_Silver:SetText("")
	FriendPresent_CopperCoin:SetText("")
	
	if g_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_BagIndex, 0)
		g_BagIndex = -1
	end
	
	g_FriendName = ""
	g_FriendLevel = 0
	g_InputMoney = 0
end

function FriendPresent_Close_Clicked()
	FriendPresent_Clear()
	this:Hide()
end

function FriendPresent_Frame_On_ResetPos()
	FriendPresent_Frame:SetProperty("UnifiedPosition", g_FriendPresent_Frame_UnifiedPosition)
end
