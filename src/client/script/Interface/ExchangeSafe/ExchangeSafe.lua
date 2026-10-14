
local ExchangeSafe_BoxName = {"第一格", "第二格", "第三格", "第四格", "第五格", "第六格", "第七格", "第八格", "第九格", "第十格", "第十一格", };
local ExchangeSafe_Box_Maxnum = 100;            --最多显示100条
local ExchangeSafe_Box_NowNum = 0;

local g_ExchangeSafe_Frame_UnifiedPosition;

--窗口最初的高度
local g_ExchangeSafe_Frame_UnifedSize_Original;
local g_ExchangeSafe_Frame_Height_Kserver = "{0.0,320}";

local g_ExchangeSafe_Money_Modify = 0
local g_ExchangeSafe_Money_Myself_Modify = 0
local g_ExchangeSafe_Money_Other_Modify = 0

--===============================================
-- OnLoad()
--===============================================
function ExchangeSafe_PreLoad()
	this:RegisterEvent("OPEN_EXCHANGE_FRAME");
	this:RegisterEvent("CLOSE_EXCHAGE_INFO");
	this:RegisterEvent("EXCHANGE_ADDITEM_BYOTHER");
	this:RegisterEvent("EXCHANGE_REMOVEITEM_BYOTHER");
	this:RegisterEvent("EXCHANGE_ADDPET_BYOTHER");
	this:RegisterEvent("EXCHANGE_REMOVEPET_BYOTHER");
	this:RegisterEvent("EXCHANGE_LOCK_BYOTHER");
	this:RegisterEvent("EXCHANGE_UNLOCK_BYOTHER");
	this:RegisterEvent("EXCHANGE_EDITMONEY_BYOTHER");
	this:RegisterEvent("EXCHANGE_CONFIRM_BYOTHER");
	this:RegisterEvent("EXCHANGE_UNLOCK_BYSELF");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("EXCHANGE_OPTIMIZATION_LOCK_MONEY")
end

--===============================================
--OnLoad()
--===============================================
function ExchangeSafe_OnLoad()
 g_ExchangeSafe_Frame_UnifiedPosition=ExchangeSafe_Frame:GetProperty("UnifiedPosition");
 g_ExchangeSafe_Frame_UnifedSize_Original=ExchangeSafe_Frame:GetProperty("UnifiedSize");

end

--===============================================
-- OnEvent()
--===============================================
function ExchangeSafe_OnEvent(event)

	if(event == "OPEN_EXCHANGE_FRAME") then
		ExchangeSafe_List:ClearAllElement();
		ExchangeSafe_Frame:SetProperty("UnifiedPosition", g_ExchangeSafe_Frame_UnifiedPosition);
		this:Show();
		--ExchangeSafe_Time:SetProperty("Text", "#{JYTX_090302_9}:");
		ExchangeSafe_Time:Hide();
		ExchangeSafe_Box_NowNum = 0;

		local isKvKSever = tonumber(arg1)
		ExchangeSafe_TrustFriendNotice(isKvKSever);
		--if isKvKSever ~= nil and isKvKSever == 1 then
			--ExchangeSafe_Frame:SetProperty("UnifiedHeight", g_ExchangeSafe_Frame_Height_Kserver)
		--else
			ExchangeSafe_Frame:SetProperty("UnifiedSize", g_ExchangeSafe_Frame_UnifedSize_Original)
		--end

	elseif (event == "CLOSE_EXCHAGE_INFO") then
		g_ExchangeSafe_Money_Modify = 0;
		g_ExchangeSafe_Money_Myself_Modify = 0;
		g_ExchangeSafe_Money_Other_Modify = 0;
		this:Hide();
	elseif (event == "EXCHANGE_ADDITEM_BYOTHER") then
		ExchangeSafe_AddItem(arg0, arg1, arg2, arg3);
	elseif (event == "EXCHANGE_REMOVEITEM_BYOTHER") then
		ExchangeSafe_RemoveItem(arg0, arg1, arg2, arg3);
	elseif (event == "EXCHANGE_ADDPET_BYOTHER") then
		ExchangeSafe_AddPet(arg0, arg1);
	elseif (event == "EXCHANGE_REMOVEPET_BYOTHER") then
		ExchangeSafe_RemovePet(arg0, arg1);
	elseif (event == "EXCHANGE_LOCK_BYOTHER") then
		ExchangeSafe_Lock(arg0, 1);
	elseif (event == "EXCHANGE_UNLOCK_BYOTHER") then
		ExchangeSafe_Lock(arg0, 0);
	elseif (event == "EXCHANGE_EDITMONEY_BYOTHER") then
		ExchangeSafe_EditMoney(arg0, arg2, arg3);
	elseif (event == "EXCHANGE_CONFIRM_BYOTHER") then
		ExchangeSafe_Confirm(arg0);
	elseif (event == "EXCHANGE_UNLOCK_BYSELF") then
		ExchangeSafe_LockBySelf();
	elseif (event == "ADJEST_UI_POS" ) then
		ExchangeSafe_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ExchangeSafe_Frame_On_ResetPos()
	elseif (event == "EXCHANGE_OPTIMIZATION_LOCK_MONEY") then
		ExchangeSafe_LockBySelf_Money(arg0)
	end

end


function ExchangeSafe_AddItem(strItemName, strTime, nItemNum, nToPos)

	local strOtherName = Exchange:GetOthersName();
	local strBoxName = ExchangeSafe_BoxName[nToPos+1];
	local strItemNameN = strItemName;

	ExchangeSafe_UpdateTopElement();
	--local strTips = "";
	--strTips = string.format("%s %s #G修改金币金额为：#{_MONEY%d}", strTime, strOtherName, nMoneyThis);
	ExchangeSafe_List:AddChatBoardElement(strTime.."#{JSJY_160612_4}".."#Y"..strBoxName.."#W".."#{JSJY_160612_5}".."["..strItemNameN.."]X"..tostring(nItemNum));
	ExchangeSafe_List:PageEnd();

end


function ExchangeSafe_RemoveItem(strItemName, strTime, nItemNum, nFromPos)
	local strOtherName = Exchange:GetOthersName();
	local strBoxName = ExchangeSafe_BoxName[nFromPos+1];
	local strItemNameN = strItemName;

	ExchangeSafe_UpdateTopElement();
	ExchangeSafe_List:AddChatBoardElement(strTime.."#{JSJY_160612_6}".."#Y"..strBoxName.."#W".."#{JSJY_160612_7}".."["..strItemNameN.."]X"..tostring(nItemNum));
	PushDebugMessage("#{JSJY_160612_1}");
	--ExchangeSafe_List:AddChatBoardElement(strTime.."#{JSJY_160612_3}");
	ExchangeSafe_List:PageEnd();
end

function ExchangeSafe_AddPet(strPetName, strTime)
	local strOtherName = Exchange:GetOthersName();
	local strPetNameN = strPetName;

	ExchangeSafe_UpdateTopElement();
	ExchangeSafe_List:AddChatBoardElement(strTime.."#{JYTX_090302_4}".."["..strPetNameN.."]");
	ExchangeSafe_List:PageEnd();
end

function ExchangeSafe_RemovePet(strPetName, strTime)
	local strOtherName = Exchange:GetOthersName();
	local strPetNameN = strPetName;

	ExchangeSafe_UpdateTopElement();
	ExchangeSafe_List:AddChatBoardElement(strTime.."#{JYTX_090302_5}".."["..strPetNameN.."]");
	PushDebugMessage("#{JSJY_160612_1}");
	--ExchangeSafe_List:AddChatBoardElement(strTime.."#{JSJY_160612_3}");
	ExchangeSafe_List:PageEnd();
end

function ExchangeSafe_Lock(strTime, nType)
	local strOtherName = Exchange:GetOthersName();

	ExchangeSafe_UpdateTopElement();

	if (nType == 1) then
		ExchangeSafe_List:AddChatBoardElement(strTime.."#{JYTX_090302_7}");
	elseif (nType == 0) then
		ExchangeSafe_List:AddChatBoardElement(strTime.."#{JYTX_090302_8}");
	end
	ExchangeSafe_List:PageEnd();
end

function ExchangeSafe_EditMoney(strTime, nMoneyGold, nMoneyOther)
	local strOtherName = Exchange:GetOthersName();

	--local strTips = string.format("%s %s #G修改金币金额为：#{_MONEY%d}", strTime, strOtherName, nMoneySet);
	local strTips = "";
	local nGold = tonumber(nMoneyGold);
	local nOther = tonumber(nMoneyOther);
	local nSiller = math.floor(nOther/100);
	local nCopper = nOther - nSiller*100;

	strTips = string.format("%s#{JYTX_090302_6}%d#-02%d#-03%d#-04", strTime, nGold, nSiller, nCopper);
	--if (nMoneyThis > 0) then
	--	strTips = string.format("%s#{JYTX_090302_6}#{_MONEY%d}", strTime, nMoneyThis);
	--else
	--	strTips = string.format("%s#{JYTX_090302_6}%d#-04", strTime, nMoneyThis);
	--end

	ExchangeSafe_UpdateTopElement();

	ExchangeSafe_List:AddChatBoardElement(strTips);

	if g_ExchangeSafe_Money_Modify ~= 0 then
		PushDebugMessage("#{JSJY_160612_1}");
		--ExchangeSafe_List:AddChatBoardElement(strTime.."#{JSJY_160612_3}");
		--ExchangeSafe_Time:Show();
		--ExchangeSafe_Watch:SetProperty("Timer",10);
	end

	g_ExchangeSafe_Money_Modify = g_ExchangeSafe_Money_Modify + 1

	ExchangeSafe_List:PageEnd();
end

function ExchangeSafe_Confirm(strTime)
	local strOtherName = Exchange:GetOthersName();

	ExchangeSafe_UpdateTopElement();
	ExchangeSafe_List:AddChatBoardElement(strTime.."#{JYTX_090303_2}");
	ExchangeSafe_List:PageEnd();
end

function ExchangeSafe_LockBySelf()
	ExchangeSafe_Time:Show();
	ExchangeSafe_Watch:SetProperty("Timer",10);
end

function ExchangeSafe_LockBySelf_Money(isMySelf)
	if isMySelf == "1" and g_ExchangeSafe_Money_Myself_Modify ~= 0 then
		ExchangeSafe_Time:Show();
		ExchangeSafe_Watch:SetProperty("Timer",10);
		return
	end

	if isMySelf == "0" and g_ExchangeSafe_Money_Other_Modify ~= 0 then
		ExchangeSafe_Time:Show();
		ExchangeSafe_Watch:SetProperty("Timer",10);
		return
	end

	if isMySelf == "1" and g_ExchangeSafe_Money_Myself_Modify == 0 and g_ExchangeSafe_Money_Other_Modify == 0 then
		g_ExchangeSafe_Money_Myself_Modify = g_ExchangeSafe_Money_Myself_Modify + 1
		return
	end

	if isMySelf == "0" and g_ExchangeSafe_Money_Myself_Modify == 0 and g_ExchangeSafe_Money_Other_Modify == 0 then
		g_ExchangeSafe_Money_Other_Modify = g_ExchangeSafe_Money_Other_Modify + 1
		return
	end

	if isMySelf == "1" and g_ExchangeSafe_Money_Myself_Modify == 0 and g_ExchangeSafe_Money_Other_Modify == 1 then
		g_ExchangeSafe_Money_Myself_Modify = g_ExchangeSafe_Money_Myself_Modify + 1
		return
	end

	if isMySelf == "0" and g_ExchangeSafe_Money_Myself_Modify == 1 and g_ExchangeSafe_Money_Other_Modify == 0 then
		g_ExchangeSafe_Money_Other_Modify = g_ExchangeSafe_Money_Other_Modify + 1
		return
	end
end

function ExchangeSafe_TimeReach1()
	ExchangeSafe_Time:Hide();
end

function ExchangeSafe_UpdateTopElement()
	if (ExchangeSafe_Box_NowNum >= ExchangeSafe_Box_Maxnum) then
		ExchangeSafe_List:RemoveTopElement();
	end

	ExchangeSafe_Box_NowNum = ExchangeSafe_Box_NowNum + 1;
end

function ExchangeSafe_TrustFriendNotice(isKvkServer)
	--KVK
	local strPre = ""
	
	--授权安全模式特殊显示内容 [7/25/2013 shh][TT]
	if GetAuthorizedSafeFlag() == 1 then
		ExchangeSafe_List:AddChatBoardElement("#{SQAQMS_130806_01}");
		ExchangeSafe_List:PageEnd();
		return
	end

	if isKvkServer ~= nil and isKvkServer == 1 then
		if KVKInterface:GetKVKExchangeMode() ~= 2 then
			strPre = "#{KVKGZ_110620_11}#{KVKGZ_110620_137}"
		else
			strPre = "#{KVKGZ_110620_137}"
		end
	end

	local otherGUID = Exchange:GetOthersGUID();
	local trustFriendStatus = DataPool:IsTrustFriend(otherGUID)

	if ( trustFriendStatus == 0 ) then
		ExchangeSafe_List:AddChatBoardElement(strPre.."#{XRHB_09515_19}");
	elseif ( trustFriendStatus == 1 ) then
		ExchangeSafe_List:AddChatBoardElement(strPre.."#{XRHB_09515_18}");
	elseif ( trustFriendStatus == 2 ) then
		ExchangeSafe_List:AddChatBoardElement(strPre.."#{XRHB_09515_17}");
	end
	ExchangeSafe_List:AddChatBoardElement("#{JJKHD_120808_76}");	--珍兽进阶
	ExchangeSafe_List:PageEnd();
end

function ExchangeSafe_Frame_On_ResetPos()
  ExchangeSafe_Frame:SetProperty("UnifiedPosition", g_ExchangeSafe_Frame_UnifiedPosition);
end
