local IMSHOWGIFT_GIFTS_BUTTONS_NUM	= 10;
local IMSHOWGIFT_GIFTS_BUTTONS		= {};
local IMSHOWGIFT_GIFTS_NAME		= {};
local IMSHOWGIFT_GIFTS_GIVER		= {};
local IMSHOWGIFT_ISSELECT_MAILS		= {};

local IMShowGift_nPageNum = 1;
local IMShowGift_maxPage = 1;

local g_IMShowGift_Frame_UnifiedXPosition;
local g_IMShowGift_Frame_UnifiedYPosition;

local g_IMShowGift_objCared = -1;

function IMShowGift_PreLoad()
	this:RegisterEvent("OPEN_PREIMDRESSMAIL");
	this:RegisterEvent("UPDATE_PREIMDRESSMAIL");
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("LOCKGET_PREIMDRESSMAIL")
	this:RegisterEvent("UNLOCKGET_PREIMDRESSMAIL")
	this:RegisterEvent("UI_COMMAND")
end

function IMShowGift_OnLoad()

	IMSHOWGIFT_GIFTS_BUTTONS[1] = IMShowGift_ItemBox1;
	IMSHOWGIFT_GIFTS_BUTTONS[2] = IMShowGift_ItemBox2;
	IMSHOWGIFT_GIFTS_BUTTONS[3] = IMShowGift_ItemBox3;
	IMSHOWGIFT_GIFTS_BUTTONS[4] = IMShowGift_ItemBox4;
	IMSHOWGIFT_GIFTS_BUTTONS[5] = IMShowGift_ItemBox5;
	IMSHOWGIFT_GIFTS_BUTTONS[6] = IMShowGift_ItemBox6;
	IMSHOWGIFT_GIFTS_BUTTONS[7] = IMShowGift_ItemBox7;
	IMSHOWGIFT_GIFTS_BUTTONS[8] = IMShowGift_ItemBox8;
	IMSHOWGIFT_GIFTS_BUTTONS[9] = IMShowGift_ItemBox9;
	IMSHOWGIFT_GIFTS_BUTTONS[10]= IMShowGift_ItemBox10;

	IMSHOWGIFT_GIFTS_NAME[1]  =     IMShowGift_Gift1;
	IMSHOWGIFT_GIFTS_NAME[2]  =     IMShowGift_Gift2;
	IMSHOWGIFT_GIFTS_NAME[3]  =     IMShowGift_Gift3;
	IMSHOWGIFT_GIFTS_NAME[4]  =     IMShowGift_Gift4;
	IMSHOWGIFT_GIFTS_NAME[5]  =     IMShowGift_Gift5;
	IMSHOWGIFT_GIFTS_NAME[6]  =     IMShowGift_Gift6;
	IMSHOWGIFT_GIFTS_NAME[7]  =     IMShowGift_Gift7;
	IMSHOWGIFT_GIFTS_NAME[8]  =     IMShowGift_Gift8;
	IMSHOWGIFT_GIFTS_NAME[9]  =     IMShowGift_Gift9;
	IMSHOWGIFT_GIFTS_NAME[10] =     IMShowGift_Gift10;
	
	IMSHOWGIFT_GIFTS_GIVER[1] = IMShowGift_Giver1;
	IMSHOWGIFT_GIFTS_GIVER[2] = IMShowGift_Giver2;
	IMSHOWGIFT_GIFTS_GIVER[3] = IMShowGift_Giver3;
	IMSHOWGIFT_GIFTS_GIVER[4] = IMShowGift_Giver4;
	IMSHOWGIFT_GIFTS_GIVER[5] = IMShowGift_Giver5;
	IMSHOWGIFT_GIFTS_GIVER[6] = IMShowGift_Giver6;
	IMSHOWGIFT_GIFTS_GIVER[7] = IMShowGift_Giver7;
	IMSHOWGIFT_GIFTS_GIVER[8] = IMShowGift_Giver8;
	IMSHOWGIFT_GIFTS_GIVER[9] = IMShowGift_Giver9;
	IMSHOWGIFT_GIFTS_GIVER[10]= IMShowGift_Giver10;
	
	IMSHOWGIFT_ISSELECT_MAILS[1] = false;
	IMSHOWGIFT_ISSELECT_MAILS[2] = false;
	IMSHOWGIFT_ISSELECT_MAILS[3] = false;
	IMSHOWGIFT_ISSELECT_MAILS[4] = false;
	IMSHOWGIFT_ISSELECT_MAILS[5] = false;
	IMSHOWGIFT_ISSELECT_MAILS[6] = false;
	IMSHOWGIFT_ISSELECT_MAILS[7] = false;
	IMSHOWGIFT_ISSELECT_MAILS[8] = false;
	IMSHOWGIFT_ISSELECT_MAILS[9] = false;
	IMSHOWGIFT_ISSELECT_MAILS[10] = false;
	

	g_IMShowGift_Frame_UnifiedXPosition	= IMShowGift_Frame:GetProperty("UnifiedXPosition");
	g_IMShowGift_Frame_UnifiedYPosition	= IMShowGift_Frame:GetProperty("UnifiedYPosition");
end


function IMShowGift_OnEvent(event)

	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		IMShowGift_CloseClicked()
	end

	if event == "OPEN_PREIMDRESSMAIL" then			

	elseif event == "UPDATE_PREIMDRESSMAIL" then
		if arg0 == nil or arg1 == nil then
			return
		end
		if( this:IsVisible() == true ) then
			IMShowGift_UpdatePage(tonumber(arg0), tonumber(arg1))	
		end
	elseif( event == "ADJEST_UI_POS" ) then
		IMShowGift_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		IMShowGift_ResetPos()
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 110526) then
		local XParam0 = Get_XParam_INT(0);
		g_IMShowGift_objCared = DataPool : GetNPCIDByServerID(XParam0);
		
		IMShowGift_Show()
		
		--发送请求邮件的消息
		AskPreIMDressMailInfo(1)
		
	--elseif (event == "OBJECT_CARED_EVENT") then
		--if(tonumber(arg0) ~= g_IMShowGift_objCared) then
		--	return;
		--end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		--if( arg1=="destroy") then
		--	IMShowGift_CloseClicked();
		--	return;
		--end	
	elseif (event == "LOCKGET_PREIMDRESSMAIL") then 
		IMShowGift_GetSelected:Disable();
		IMShowGift_GetAll:Disable();
		for i = 1, table.getn(IMSHOWGIFT_GIFTS_BUTTONS) do
			if IMSHOWGIFT_ISSELECT_MAILS[i] == true then
				IMSHOWGIFT_GIFTS_BUTTONS[i]:Disable();
			end	
		end
	elseif (event == "UNLOCKGET_PREIMDRESSMAIL") then 
		IMShowGift_GetSelected:Enable();
		IMShowGift_GetAll:Enable();
		for i = 1, table.getn(IMSHOWGIFT_GIFTS_BUTTONS) do
			IMSHOWGIFT_GIFTS_BUTTONS[i]:Enable();
		end
	end
end

--==================
--打开空的邮件界面
function IMShowGift_Show()
	-- 关心OBJ
	IMShowGift_BeginCareObject(g_IMShowGift_objCared);
	
	CleanUpPreIMDressMailBox()
		
	for i = 1, table.getn(IMSHOWGIFT_GIFTS_BUTTONS) do
		IMSHOWGIFT_GIFTS_BUTTONS[i]:SetActionItem(-1);
		IMSHOWGIFT_GIFTS_BUTTONS[i]:SetPushed(0);
		IMSHOWGIFT_GIFTS_GIVER[i]:SetText("");
		IMSHOWGIFT_GIFTS_NAME[i]:SetText("");
		IMSHOWGIFT_ISSELECT_MAILS[i] = false;
	end
	
	if( this:IsVisible() == true ) then
		this:Hide();
	end
	
	IMShowGift_ItemNumber:SetText("#{ZSGN_XML_07}".."0".."#{ZSGN_XML_10}");
	IMShowGift_CurrentlyPage:SetText("1/1");
	IMShowGift_UpPage:Disable();
	IMShowGift_DownPage:Disable();
	
	this:Show();
	
	--正在等待server返回的消息中，先锁住
	PushEvent("LOCKGET_PREIMDRESSMAIL")

end

--=========================================================
--关心OBJ
--在开始关心之前需要先确定这个界面是不是已经有“关心”的OBJ，
--如果有的话，先取消已经有的“关心”
--=========================================================
function IMShowGift_BeginCareObject(objCaredId)

	if (type(g_IMShowGift_objCared) == "number") then
		g_IMShowGift_objCared = objCaredId;
		this:CareObject(g_IMShowGift_objCared, 1, "IMShowGift");
	else
		return;
	end

end


--===============================
--刷新一页
function IMShowGift_UpdatePage(PageNum, Allmailcount)

	if PageNum == nil or Allmailcount == nil then
	  return
	end
	
  if PageNum < 1 or Allmailcount < 0 then
  	return
  end
  
  local tempmaxPage = 0 
  if Allmailcount <= 0 then
		tempmaxPage = 1;
	else
		tempmaxPage = math.floor((Allmailcount - 1)/IMSHOWGIFT_GIFTS_BUTTONS_NUM + 1)
	end 
	
	--特殊情况:如果玩家在最后一页点击全部领取之后，会出现 tempmaxPage = PageNum - 1 的情况
	--比如 一共2页，当前第2页，点击全不领取，经过上面的计算领取完毕后总页数是1，当前页是2
	--正确应该显示为2/2，同时当前页面清空
	if tempmaxPage + 1 == PageNum then
		tempmaxPage = PageNum
	end
	
  if PageNum > tempmaxPage then
  	return
  end
  
	--设置当前页
	IMShowGift_nPageNum = PageNum
	
	--设置总页数
	IMShowGift_maxPage = tempmaxPage

	--local mailcount = PreIMDressMailBoxGetCount();
	IMShowGift_ItemNumber:SetText("#{ZSGN_XML_07}"..tostring(Allmailcount).."#{ZSGN_XML_10}");
	
	IMShowGift_CurrentlyPage:SetText(tostring(IMShowGift_nPageNum).."/"..tostring(IMShowGift_maxPage));
	
	for i = 1, table.getn(IMSHOWGIFT_GIFTS_BUTTONS) do
		IMSHOWGIFT_GIFTS_BUTTONS[i]:SetActionItem(-1);
		IMSHOWGIFT_GIFTS_BUTTONS[i]:SetPushed(0);
		IMSHOWGIFT_GIFTS_GIVER[i]:SetText("");
		IMSHOWGIFT_GIFTS_NAME[i]:SetText("");
		IMSHOWGIFT_ISSELECT_MAILS[i] = false;
	end
	
	if PageNum <= 1 then
		IMShowGift_UpPage:Disable();
	else
		IMShowGift_UpPage:Enable();
	end
	
	if PageNum >= IMShowGift_maxPage then
		IMShowGift_DownPage:Disable();
	else
		IMShowGift_DownPage:Enable();
	end
	
	for i = 1, table.getn(IMSHOWGIFT_GIFTS_BUTTONS) do
		local theAction = EnumAction(i-1, "preimdressmailbox");
		if theAction:GetID() ~= 0 then
			IMSHOWGIFT_GIFTS_BUTTONS[i]:SetActionItem(theAction:GetID());
			IMSHOWGIFT_GIFTS_NAME[i]:SetText("#c00ff00"..theAction:GetName());
			local GiverName = PreIMDressMailBoxGetGiverName(i-1);
			if GiverName == "" then
				IMSHOWGIFT_GIFTS_GIVER[i]:SetText("#{ZSGN_XML_09}")
			else
				IMSHOWGIFT_GIFTS_GIVER[i]:SetText("#{ZSGN_XML_08}"..GiverName);
			end
		end
	end

end

function IMShowGift_MailButton_Clicked(nIndex)
	if(nIndex < 1 or nIndex > IMSHOWGIFT_GIFTS_BUTTONS_NUM) then
		return;
	end
	
	if IMSHOWGIFT_GIFTS_BUTTONS[nIndex]:GetActionItem() == -1 then
		return
	end
	
	if (IMSHOWGIFT_ISSELECT_MAILS[nIndex] == true) then
		IMSHOWGIFT_ISSELECT_MAILS[nIndex] = false;
		IMSHOWGIFT_GIFTS_BUTTONS[nIndex]:SetPushed(0);
		PreIMDressMailBoxSetSelect(nIndex -1, false);
	else
		IMSHOWGIFT_ISSELECT_MAILS[nIndex] = true;
		IMSHOWGIFT_GIFTS_BUTTONS[nIndex]:SetPushed(1);
		PreIMDressMailBoxSetSelect(nIndex - 1, true);
	end
	
end
--===============================================
-- PageUp
--===============================================
function IMShowGift_UpPageClicked()
	local page = IMShowGift_nPageNum - 1 
	if page < 1 then
		return
	end	
	AskPreIMDressMailInfo(page)
end

--===============================================
-- PageDown
--===============================================
function IMShowGift_DownPageClicked()
	local page = IMShowGift_nPageNum + 1 
	if page > IMShowGift_maxPage then
		return
	end
	AskPreIMDressMailInfo(page)
end

--===============================================
-- Close
--===============================================
function IMShowGift_CloseClicked()

	this:Hide();
	CleanUpPreIMDressMailBox();

end


function IMShowGift_Selected_Clicked()
	if IMShowGift_nPageNum < 1 or IMShowGift_nPageNum > IMShowGift_maxPage then
	  return
	end

	local ret = AskPreIMDressMail();		
 	if ret == true then
		AskPreIMDressMailInfo(IMShowGift_nPageNum)
	end
end


function IMShowGift_ALLSelected_Clicked()
	if IMShowGift_nPageNum < 1 or IMShowGift_nPageNum > IMShowGift_maxPage then
	  return
	end
	  
	local ret = AskPreIMDressALLMail();
	if ret == true then
		AskPreIMDressMailInfo(IMShowGift_nPageNum)
	end
end

function IMShowGift_Cancel_Clicked()
	IMShowGift_CloseClicked();
end


function IMShowGift_ResetPos()
	IMShowGift_Frame:SetProperty("UnifiedXPosition", g_IMShowGift_Frame_UnifiedXPosition);
	IMShowGift_Frame:SetProperty("UnifiedYPosition", g_IMShowGift_Frame_UnifiedYPosition);
end
