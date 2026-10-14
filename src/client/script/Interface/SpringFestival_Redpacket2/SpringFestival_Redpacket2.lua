--SpringFestival_Redpacket2.lua
-- !!!reloadscript =SpringFestival_Redpacket2
local g_SpringFestival_Redpacket2_Frame_UnifiedPosition;

local g_scriptId = 998376
local g_SpringFestival_Redpacket2_Text1 = {};
local g_SpringFestival_Redpacket2_Text2 = {};
local g_SpringFestival_Redpacket2_Text3 = {};
local g_SpringFestival_Redpacket2_Text4 = {};
local g_SpringFestival_Redpacket2_Item = {};
local g_SpringFestival_Redpacket2_Item2 = {};
local g_bagindex
local g_sendPlayerName
local g_isFriend
local g_itemid
local g_itemNum
local g_jinzhuNum
function SpringFestival_Redpacket2_PreLoad()
	this:RegisterEvent("UI_COMMAND")

end

function SpringFestival_Redpacket2_OnLoad()
	g_SpringFestival_Redpacket2_Frame_UnifiedPosition=SpringFestival_Redpacket2_Frame:GetProperty("UnifiedPosition");
	
	--第1页
	g_SpringFestival_Redpacket2_Text1 = SpringFestival_Redpacket2_text1
	g_SpringFestival_Redpacket2_Text2 = SpringFestival_Redpacket2_text2

	--第2页
	g_SpringFestival_Redpacket2_Text3 = SpringFestival_Redpacket2_text3
	g_SpringFestival_Redpacket2_Text4 = SpringFestival_Redpacket2_text4
	g_SpringFestival_Redpacket2_Item = SpringFestival_Redpacket2_Item
	g_SpringFestival_Redpacket2_Item2 = SpringFestival_Redpacket2_Item2

end

function SpringFestival_Redpacket2_OnEvent(event)

	if (event == "UI_COMMAND") and tonumber(arg0) == 99837601 then
		local nType = Get_XParam_INT(0)
		if  nType== 1 then

			SpringFestival_Redpacket2_OnClean()
			
			g_bagindex = Get_XParam_INT(1)
			g_isFriend = Get_XParam_INT(2)
			g_sendPlayerName = Get_XParam_STR(0)
			
			g_SpringFestival_Redpacket2_Text1 : SetText(ScriptGlobal_Format("#{MTNC_221101_67}", g_sendPlayerName))

			
			g_SpringFestival_Redpacket2_Text1 :Show()
			g_SpringFestival_Redpacket2_Text2 :Show()
			SpringFestival_Redpacket2_Client1 :Show()
			SpringFestival_Redpacket2_Client2  :Hide()
			SpringFestival_Redpacket2_Client :Show()
			
			g_SpringFestival_Redpacket2_Text3 :Hide();	
			g_SpringFestival_Redpacket2_Text4 :Hide();
			g_SpringFestival_Redpacket2_Item :Hide();
			g_SpringFestival_Redpacket2_Item2 :Hide();
			
			SpringFestival_Redpacket2_GetBtn :Hide();
			this:Show()
		end
		if nType == 0 then
			this:Hide()
		end
		if nType == 2 then --点击ok 后 翻页
			g_itemid = Get_XParam_INT(1)
			g_itemNum = Get_XParam_INT(2)
			g_jinzhuNum =Get_XParam_INT(3)
			SpringFestival_Redpacket2_ChangePage(g_itemid,g_itemNum,g_jinzhuNum)
		end
	end
end

--点击打开
function SpringFestival_Redpacket2_OpenBtn()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpen")
		Set_XSCRIPT_ScriptID(g_scriptId)
		Set_XSCRIPT_Parameter(0, g_bagindex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

-- 翻页
function SpringFestival_Redpacket2_ChangePage(itemid,g_itemNum,jinzhunum)

	SpringFestival_Redpacket2_Client1  :Hide()

	
	if g_isFriend == 0 then
		g_SpringFestival_Redpacket2_Text3 : SetText(ScriptGlobal_Format("#{MTNC_221101_67}", g_sendPlayerName,"#{MTNC_221101_69}"))
	else
		g_SpringFestival_Redpacket2_Text3 : SetText(ScriptGlobal_Format("#{MTNC_221101_67}", g_sendPlayerName,"#{MTNC_221101_68}"))
	end
	
	local  itemAction = DataPool:CreateBindActionItemForShow(39921636,jinzhunum) 
	if itemAction:GetID() ~= 0 then
		g_SpringFestival_Redpacket2_Item:SetActionItem(itemAction:GetID())
	end

	local  itemAction2 = DataPool:CreateBindActionItemForShow(itemid,g_itemNum) 
	if itemAction2:GetID() ~= 0 then
		g_SpringFestival_Redpacket2_Item2:SetActionItem(itemAction2:GetID())
	end

	
	g_SpringFestival_Redpacket2_Text4 : SetText(ScriptGlobal_Format("#{MTNC_221101_78}",jinzhunum,itemAction2:GetName(),g_itemNum))
	
	g_SpringFestival_Redpacket2_Text1 :Hide()
	g_SpringFestival_Redpacket2_Text2 :Hide()
	
	g_SpringFestival_Redpacket2_Text3 :Show()
	g_SpringFestival_Redpacket2_Text4 :Show()
	g_SpringFestival_Redpacket2_Item :Show()
	g_SpringFestival_Redpacket2_Item2 :Show()
	SpringFestival_Redpacket2_Client2  :Show()
	--this :show();
end

function SpringFestival_Redpacket2_OnHiden()
	SpringFestival_Redpacket2_OnClean()
	this:Hide()
end
function SpringFestival_Redpacket2_OnCloseClicked()
	SpringFestival_Redpacket2_OnClean()
	this:Hide()
end
function SpringFestival_Redpacket2_OnClean()

	 g_SpringFestival_Redpacket2_Text1 :SetText("")

	 g_SpringFestival_Redpacket2_Text3 :SetText("")

	 g_SpringFestival_Redpacket2_Item :SetActionItem(-1)
	g_SpringFestival_Redpacket2_Item2 :SetActionItem(-1)
	 g_bagindex	= -1
	 g_sendPlayerName=""
	 g_isFriend = -1

end

function SpringFestival_Redpacket2_Frame_On_ResetPos()
  SpringFestival_Redpacket2:SetProperty("UnifiedPosition", g_SpringFestival_Redpacket2_Frame_UnifiedPosition);
end