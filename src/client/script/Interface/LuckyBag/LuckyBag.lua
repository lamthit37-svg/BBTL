local g_LuckyBag_Frame_UnifiedPosition = nil 



local g_LuckyBag_MyBag_Action = {}
local g_LuckyBag_MyBag_Mask = {}
local g_LuckyBag_Select = -1 --3，金，2银，1铜
local g_LuckyBag_ShowItemInfo = {}
local g_LuckyBag_CurCount = 0
local g_LuckyBag_CurSelect = {}
local g_LuckyBag_MyBag_Count = 0
local g_LuckyBag_SaveFrame = 0
local g_LuckyBag_Fenye = {}
local g_LuckyBag_Mask = {}

local g_LuckyBag_MDInfo = 0
local g_LuckyBag_Tips = {}
local g_LuckyBag_Cost = {}
local g_LuckyBag_SubTitle = {}
local g_LuckyBag_Icon = {}
local g_LuckyBag_tooltipstr = {}


function LuckyBag_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT")
	this:RegisterEvent("UI_COMMAND",false)
	this:RegisterEvent("RECIVE_ZNQ_FUDAIINFO")
	this:RegisterEvent("CONFIRM_ZNQFUDAI_SELECT",false)
	

	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);
	this:RegisterEvent("OPEN_ANNIVERSARY_GUIDE",false);


end 


function LuckyBag_Close_Clicked()
	this:Hide()
end

-- LuckyBag_FrameNULL_Right2 => TLBB_StaticImageNULL
-- LuckyBag_Frame_Client => TLBB_MainFrame16
-- LuckyBag_FrameNULL_Right1 => TLBB_StaticImageNULL
-- LuckyBag_DragTitle => TLBB_DragTitle
-- LuckyBag_FrameNULL_Left => TLBB_StaticImageNULL
-- LuckyBag_DragTitleBK => TLBB_Frame_Lace37
function LuckyBag_OnLoad()

	local LuckyBag_Action = {}
	local LuckyBag_CheckMark = {}
	local LuckyBag_Mask = {}
	local LuckyBag_Image = {}
	for i = 1,3 do
		for j = 1,8 do
			LuckyBag_Action[(i-1)*8+j] = "LuckyBag_Bk"..i.."_Item"..j
			LuckyBag_CheckMark[(i-1)*8+j] = "LuckyBag_Bk"..i.."_Item"..j.."Image"		--LuckyBag_Bk1_Item1Image
			LuckyBag_Mask[(i-1)*8+j] = "LuckyBag_Bk"..i.."_Item"..j.."_Mask"			--LuckyBag_Bk1_Item1_Mask
			LuckyBag_Image[(i-1)*8+j] = "LuckyBag_Bk"..i.."_Item"..j.."BK"
		end	
	end
	
	--居然还有一行6个的
	for i = 1,6 do
			LuckyBag_Action[i+24] = "LuckyBag_Bk4".."_Item"..i
			LuckyBag_CheckMark[i+24] = "LuckyBag_Bk4".."_Item"..i.."Image"		--LuckyBag_Bk1_Item1Image
			LuckyBag_Mask[i+24] = "LuckyBag_Bk4".."_Item"..i.."_Mask"			--LuckyBag_Bk1_Item1_Mask
			LuckyBag_Image[i+24] = "LuckyBag_Bk4".."_Item"..i.."BK"			
	end
	
	for i = 1,30 do
		g_LuckyBag_ShowItemInfo[i] = { ActionButton = _G[LuckyBag_Action[i]], CheckMark = _G[LuckyBag_CheckMark[i]], Mask = _G[LuckyBag_Mask[i]], 
										BKImage = _G[LuckyBag_Image[i]],disable=0,actionid=-1,bonusId=-1}
	end
	
	

	

	

	
	g_LuckyBag_Fenye[1] = LuckyBag_CheckFrame_FenYe3
	g_LuckyBag_Fenye[2] = LuckyBag_CheckFrame_FenYe2
	g_LuckyBag_Fenye[3] = LuckyBag_CheckFrame_FenYe1
	g_LuckyBag_Fenye[4] = LuckyBag_Button
	g_LuckyBag_Frame_UnifiedPosition = LuckyBag_Frame:GetProperty("UnifiedPosition");
	
	g_LuckyBag_Tips[1] = LuckyBag_CheckFrame_FenYe3_Tips
	g_LuckyBag_Tips[2] = LuckyBag_CheckFrame_FenYe2_Tips
	g_LuckyBag_Tips[3] = LuckyBag_CheckFrame_FenYe1_Tips
	g_LuckyBag_Tips[4] = LuckyBag_Button_Tips
	
	g_LuckyBag_Icon[1] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_IconTong"
	g_LuckyBag_Icon[2] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_IconYin"
	g_LuckyBag_Icon[3] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_IconJin"
	
	g_LuckyBag_SubTitle[1] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_TitleTong"
	g_LuckyBag_SubTitle[2] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_TitleYin"
	g_LuckyBag_SubTitle[3] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_TitleJin"
	g_LuckyBag_SubTitle[4] = "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_TitleMyBag"

	
	g_LuckyBag_Cost[1] = 2
	g_LuckyBag_Cost[2] = 3
	g_LuckyBag_Cost[3] = 6
	
	g_LuckyBag_tooltipstr[1] = "#{SWZB_190322_04}"
	g_LuckyBag_tooltipstr[2] = "#{SWZB_190322_03}"
	g_LuckyBag_tooltipstr[3] = "#{SWZB_190322_02}"
	for i = 1, 3 do
		local str = ScriptGlobal_Format("#{SWZB_190322_05}",g_LuckyBag_tooltipstr[i])
		g_LuckyBag_Fenye[i]:SetToolTip(str)
	end
end

function LuckyBag_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		LuckyBag_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		LuckyBag_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		LuckyBag_On_Hide()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		LuckyBag_CareObj()
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 9999 then
		Lua_AskZNQfudaiInfo(0,1)
	elseif (event == "RECIVE_ZNQ_FUDAIINFO") and tonumber(arg0) == 0 then
		LuckyBag_InitFrame(tonumber(arg1))
		this:Show()	
	elseif (event == "CONFIRM_ZNQFUDAI_SELECT") and tonumber(arg0) == 1 then
		LuckyBag_AfterConfirm()
	elseif (event == "CONFIRM_ZNQFUDAI_SELECT") and tonumber(arg0) == 3 then
		LuckyBag_CleanData()
		LuckyBag_ShowFrame(g_LuckyBag_SaveFrame);
	elseif (event == "OPEN_ANNIVERSARY_GUIDE") then
		this:Hide()
	end
end


function LuckyBag_CleanData()
	for i =1, 30 do
		g_LuckyBag_ShowItemInfo[i].ActionButton:SetActionItem(-1)
		g_LuckyBag_ShowItemInfo[i].CheckMark:Hide()
		g_LuckyBag_ShowItemInfo[i].Mask:Hide()
		g_LuckyBag_ShowItemInfo[i].BKImage:SetProperty("Image","")
		g_LuckyBag_ShowItemInfo[i].disable = 0
		g_LuckyBag_ShowItemInfo[i].actionid = -1
		g_LuckyBag_ShowItemInfo[i].bonusId = -1
	end
	g_LuckyBag_MyBag_Count = 0
end
function  LuckyBag_InitFrame(nFrame)

	LuckyBag_CleanData()
	
	LuckyBag_SetTips()
	LuckyBag_ShowFrame(nFrame)
	LuckyBag_GetButtonStatus()
	
	
end

function LuckyBag_SetTips()
	g_LuckyBag_Tips[4]:Hide()
	local countlist = { 0,0,0}
	for i = 1,30 do
		local bonusId = Lua_GetMyZNQItem(i-1)
		if bonusId > 0 then
			local poolId,ShowItemId,ItemCount = Lua_GetZNQfudaiInfoByBonusId(bonusId)
			if poolId >=1 and poolId <=3 then
				countlist[poolId] = countlist[poolId]+1
			end
		end
	end	
	
	for i = 1,3 do
		local myCurrency = Lua_GetMyZNQCurrency(i-1)
		local maxnum = LuckyBag_GetMaxNum(i)
		if myCurrency >= g_LuckyBag_Cost[i] and countlist[i] < maxnum  then
			g_LuckyBag_Tips[i]:Show()
		else
			g_LuckyBag_Tips[i]:Hide()
		end
	end
	
end


function LuckyBag_GetButtonStatus()

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowButtonTips" )
			Set_XSCRIPT_ScriptID(232004)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
end
function LuckyBag_UpDataCurrency()

	local strNum = ScriptGlobal_Format("#{SWZB_190322_15}", g_LuckyBag_CurCount-1,LuckyBag_GetMaxNum(g_LuckyBag_Select))
	LuckyBag_NumText:SetText(strNum)
	
	local strbagname = LuckyBag_GetCurrencyStr()
	local currency = Lua_GetMyZNQCurrency(g_LuckyBag_Select-1)
	local strHave = ScriptGlobal_Format("#{SWZB_190322_42}", strbagname,currency)
	LuckyBag_HaveText:SetText(strHave)
	
	if g_LuckyBag_Select == 1 then
		LuckyBag_HaveText:SetToolTip("#{SWZB_190322_63}")
	elseif g_LuckyBag_Select == 2 then
		LuckyBag_HaveText:SetToolTip("#{SWZB_190322_64}")
	elseif g_LuckyBag_Select == 3 then
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(56) > 0 then  --卡级
			LuckyBag_HaveText:SetToolTip("#{SWZB_220119_02}")
		else
			LuckyBag_HaveText:SetToolTip("#{SWZB_190322_65}")
		end
	end
	
	local cost = LuckyBag_GetCost()
	local strcanselect = "#{SWZB_190322_67}"
	LuckyBag_MoneyText :SetText(strcanselect)
	LuckyBag_MoneyIcon : SetProperty("Image",g_LuckyBag_Icon[g_LuckyBag_Select])
	
	local strcount = ScriptGlobal_Format("#{SWZB_190322_68}", cost)
	LuckyBag_MoneyText1_1:SetText(strcount)
	
	
end

function LuckyBag_Help_Click()
	PushEvent("CCSHOP_HELP", 101)
end

function LuckyBag_ShowFrame(nType)


	--是否当前有已选择的道具
	if nType >=1 and nType <=3 then
		local nSelectNum = 0;		
		for i = 1,30 do
			if g_LuckyBag_ShowItemInfo[i].disable == 1 then
				nSelectNum = nSelectNum + 1
			end
		end
		
		if nSelectNum > 0 then	
			if g_LuckyBag_Select == nType then
				return
			end
			g_LuckyBag_Fenye[g_LuckyBag_Select]:SetCheck(1)
			g_LuckyBag_SaveFrame = nType
			PushEvent("CONFIRM_ZNQFUDAI_SELECT", 2,"#{SWZB_190322_33}")		
			return 
		end

		LuckyBag_CleanData()
		local strImage = LuckyBag_GetImage(nType)
		

		
		local nCount = Lua_GetZNQfudaiCount()
		local ShowIndex = 1
		local myBagIndex = 1
		for i = 1, nCount do
			local bonusId,poolId,ShowItemId,ItemCount = Lua_GetZNQfudaiInfo(i)
			if bonusId > 0 then
				if poolId == nType then
					local theAction = DataPool:CreateActionItemForShow(ShowItemId, ItemCount)
					
					g_LuckyBag_ShowItemInfo[ShowIndex].ActionButton:SetActionItem(theAction:GetID())
					g_LuckyBag_ShowItemInfo[ShowIndex].actionid = theAction:GetID()
					g_LuckyBag_ShowItemInfo[ShowIndex].bonusId = bonusId
					g_LuckyBag_ShowItemInfo[ShowIndex].BKImage:SetProperty("Image",strImage)
					if Lua_HasSelectedZNQfudai(bonusId) == 1 then
						g_LuckyBag_ShowItemInfo[ShowIndex].CheckMark:Show()
						myBagIndex = myBagIndex+1
					end
					ShowIndex = ShowIndex+1
				end
			end
		end
		g_LuckyBag_CurCount = myBagIndex
		g_LuckyBag_Select = nType;
		g_LuckyBag_Fenye[g_LuckyBag_Select]:SetCheck(1)
		LuckyBag_SetTips()
		LuckyBag_TitlePic:SetProperty("Image",g_LuckyBag_SubTitle[nType])
		LuckyBag_HaveIcon:Show()
		LuckyBag_HaveIcon:SetProperty("Image",g_LuckyBag_Icon[nType])
		LuckyBag_Button1:Disable();
		LuckyBag_Button1:Show()
		LuckyBag_NumText:Show()
		LuckyBag_HaveText:Show()
		LuckyBag_MoneyText:Show()
		LuckyBag_MoneyIcon:Show()
		LuckyBag_MoneyText1_1:Show()
		--有可以选择的显示文字
		local maxnum = LuckyBag_GetMaxNum(g_LuckyBag_Select)
		local myCurrency = Lua_GetMyZNQCurrency(g_LuckyBag_Select-1)
		if g_LuckyBag_CurCount > maxnum or myCurrency < g_LuckyBag_Cost[g_LuckyBag_Select] then
			LuckyBag_NextInfoText:Hide()
			LuckyBag_NextInfoTextBK:Hide()
		else
			LuckyBag_NextInfoText:Show()
			LuckyBag_NextInfoText:SetText("#{SWZB_190322_72}")
			LuckyBag_NextInfoTextBK:Show()		
		end
		
		

		LuckyBag_UpDataCurrency()
		
	elseif nType == 4 then
		local nSelectNum = 0;		
		for i = 1,30 do
			if g_LuckyBag_ShowItemInfo[i].disable == 1 then
				nSelectNum = nSelectNum + 1
			end
		end
		
		if nSelectNum > 0 then	
			if g_LuckyBag_Select == nType then
				return
			end
			g_LuckyBag_Fenye[g_LuckyBag_Select]:SetCheck(1)
			g_LuckyBag_SaveFrame = nType
			PushEvent("CONFIRM_ZNQFUDAI_SELECT", 2,"#{SWZB_190322_33}")		
			return 
		end
		
		LuckyBag_CleanData()
		for i = 1,30 do
			local bonusId = Lua_GetMyZNQItem(i-1)
			if bonusId > 0 then
				local poolId,ShowItemId,ItemCount = Lua_GetZNQfudaiInfoByBonusId(bonusId)
				local theAction = DataPool:CreateActionItemForShow(ShowItemId, ItemCount)
				g_LuckyBag_ShowItemInfo[i].ActionButton:SetActionItem(theAction:GetID())	
				local strImage = LuckyBag_GetImage(poolId)
				g_LuckyBag_ShowItemInfo[i].BKImage:SetProperty("Image",strImage)
			end
		end
		g_LuckyBag_Select = nType
		g_LuckyBag_Fenye[g_LuckyBag_Select]:SetCheck(1)
		LuckyBag_TitlePic:SetProperty("Image",g_LuckyBag_SubTitle[nType])
		LuckyBag_Button1:Disable();
		LuckyBag_HaveIcon:Hide()
		LuckyBag_Button1:Hide()
		LuckyBag_NumText:Hide()
		LuckyBag_HaveText:Hide()
		LuckyBag_MoneyText:Hide()
		LuckyBag_MoneyIcon:Hide()
		LuckyBag_MoneyText1_1:Hide()
		LuckyBag_NextInfoText:Show()
		LuckyBag_NextInfoText:SetText("#{SWZB_190322_66}")
		LuckyBag_NextInfoTextBK:Show()
	end
	
end





function LuckyBag_CareObj()
	if(tonumber(arg0) ~= g_objCareID) then
		return;
	end
	--如果和NPC的距离大于一定距离或者被删除，自动关闭
	if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
		--取消关心
		LuckyBag_StopCareObject(g_objCareID)
		LuckyBag_On_Hide()
	end		
end

function LuckyBag_StopCareObject(objCaredId)
	this:CareObject(objCaredId, 0, "LuckyBag");
	g_objCareID = -1;
end

function LuckyBag_BeginCareObject(objid)
	g_Object = objid
	this:CareObject(g_Object, 1, "LuckyBag");
end

function LuckyBag_On_ResetPos()
	LuckyBag_Frame:SetProperty("UnifiedPosition", g_LuckyBag_Frame_UnifiedPosition)
end

function LuckyBag_On_Hide()
	this:Hide()
end


function LuckyBag_InsertCheck(index)
	local nLevel = Player:GetLevel();
	if nLevel < 30 then
		PushDebugMessage("#{SWZB_190322_17}")
		return 0
	end
	--是否在活动时间
	local curday = DataPool:GetServerDayTime()
	if curday < 20220422 or curday > 20220515 then
		PushDebugMessage("#{SWZB_190322_18}")
		return 0	
	end
	if g_LuckyBag_ShowItemInfo[index] == nil then
		return 0
	end

	if g_LuckyBag_ShowItemInfo[index].actionid < 0 then
		return 0
	end
	
	--在已经选好的里面
	local bonusId = g_LuckyBag_ShowItemInfo[index].bonusId
	if(Lua_HasSelectedZNQfudai(bonusId) == 1 ) then
		PushDebugMessage("#{SWZB_190322_19}")
		return 0
	end
	
	--在正在选择的里面
	if g_LuckyBag_ShowItemInfo[index].disable == 1 then
		PushDebugMessage("#{SWZB_190322_19}")
		return 0	
	end
	
	local maxnum = LuckyBag_GetMaxNum(g_LuckyBag_Select);
	local str = g_LuckyBag_tooltipstr[g_LuckyBag_Select];


	if g_LuckyBag_MyBag_Count > maxnum or g_LuckyBag_CurCount > maxnum then
		PushDebugMessage(ScriptGlobal_Format("#{SWZB_190322_20}",str))		
		return 0
	end
	
	local nSelectCount = g_LuckyBag_MyBag_Count-g_LuckyBag_CurCount
	local cost = LuckyBag_GetCost()


	local myCurrency = Lua_GetMyZNQCurrency(g_LuckyBag_Select-1)
	local curStr = LuckyBag_GetCurrencyStr()
	if cost > myCurrency then	
		PushDebugMessage(ScriptGlobal_Format("#{SWZB_190322_24}",curStr))
		return 0
	end
	
	local nSelectNum = 0
	for i = 1,30 do
		if g_LuckyBag_ShowItemInfo[i].disable == 1 then
			nSelectNum = nSelectNum + 1
		end
	end

	if cost*(nSelectNum+1) > myCurrency then
		PushDebugMessage(ScriptGlobal_Format("#{SWZB_190322_24}",curStr))
		return 0
	end	
	
	return 1
	
end

function LuckyBag_GetCost()
	local cost = 0
	if g_LuckyBag_Cost[g_LuckyBag_Select] ~= nil then
		return g_LuckyBag_Cost[g_LuckyBag_Select]
	end
	return cost
end
function LuckyBag_GetMaxNum(nType)
	local maxnum = 0
	if nType == 1 then
		maxnum = 15

	elseif nType == 2 then
		maxnum = 10

	elseif nType == 3 then
		maxnum = 5

	end
	
	return maxnum;
end

function LuckyBag_GetBagstr()
	local str = " "
	if g_LuckyBag_Select == 1 then

		str = "#{SWZB_190322_23}"
	elseif g_LuckyBag_Select == 2 then

		str = "#{SWZB_190322_22}"
	elseif g_LuckyBag_Select == 3 then

		str = "#{SWZB_190322_21}"
	end
	
	return str;
end

function LuckyBag_GetImage(nType)
	local strImage = ""
	if nType == 1 then
		strImage= "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_TongBK"
	elseif nType == 2 then
		strImage= "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_YinBK"
	elseif nType == 3 then
		strImage= "set:Anniversary_LuckyBag1 image:Anniversary_LuckyBag_JinBK"
	end
	return strImage
	
end

function LuckyBag_GetCurrencyStr()
	local str = " "
	if g_LuckyBag_Select == 1 then

		str = "#{SWZB_190322_43}"
	elseif g_LuckyBag_Select == 2 then

		str = "#{SWZB_190322_44}"
	elseif g_LuckyBag_Select == 3 then

		str = "#{SWZB_190322_45}"
	end
	
	return str;
end


function LuckyBag_UpdataMyBag()
		local mystart = g_LuckyBag_CurCount
		
		
		
		for i = 1,30 do
			if g_LuckyBag_ShowItemInfo[i].disable == 1 then
				mystart = mystart + 1			
			end
		end
		
		g_LuckyBag_MyBag_Count = mystart
		
		local nSelectCount = g_LuckyBag_MyBag_Count-g_LuckyBag_CurCount
		if nSelectCount > 0 then
			LuckyBag_Button1:Enable();
		else
			LuckyBag_Button1:Disable();
		end
		
end
function LuckyBag_ShowItem_Clicked(index)

	if g_LuckyBag_Select > 3 then
		return
	end
	--在已经选好的里面
	local bonusId = g_LuckyBag_ShowItemInfo[index].bonusId
	if(Lua_HasSelectedZNQfudai(bonusId) == 1 ) then
		PushDebugMessage("#{SWZB_190322_19}")
		return 0
	end
	
	if g_LuckyBag_ShowItemInfo[index].disable == 1 then
		--蒙红状态，再点击取消蒙红
	else
		if LuckyBag_InsertCheck(index) ~= 1 then
			return
		end

		if g_LuckyBag_MyBag_Count > 30 or  g_LuckyBag_CurCount > 30 then
			--已经选满了
			return
		end
	end
	
	if g_LuckyBag_ShowItemInfo[index].CheckMark:IsVisible() == false then
		if(g_LuckyBag_ShowItemInfo[index].disable == 1) then
			g_LuckyBag_ShowItemInfo[index].Mask:Hide()
			g_LuckyBag_ShowItemInfo[index].disable = 0
		else
			g_LuckyBag_ShowItemInfo[index].Mask:Show()
			g_LuckyBag_ShowItemInfo[index].disable = 1
		end
		
		LuckyBag_UpdataMyBag()
		
	end	

end


function LuckyBag_Button_Clicked()
	LuckyBag_ShowFrame(4)
end


function LuckyBag_AfterConfirm()
	local nSelectNum = 0;
	Lua_ZNQfudaiClean();
		
	for i = 1,30 do
		if g_LuckyBag_ShowItemInfo[i].disable == 1 then
			Lua_ZNQfudaiAddItem(nSelectNum,g_LuckyBag_ShowItemInfo[i].bonusId)
			nSelectNum = nSelectNum + 1
		end
	end
		
	if nSelectNum == 0 then
		PushDebugMessage("#{SWZB_190322_26}")
		return 0		
	end
		
	local cost = LuckyBag_GetCost()
	local myCurrency = Lua_GetMyZNQCurrency(g_LuckyBag_Select-1)	
	local curstr = LuckyBag_GetCurrencyStr()
	if cost*nSelectNum > myCurrency then
		PushDebugMessage(ScriptGlobal_Format("#{SWZB_190322_27}",curstr))
		return 0
	end
	

		
	Lua_ZNQfudaiSendInsert(g_LuckyBag_Select,nSelectNum);
end


function LuckyBag_Button1_Clicked()
	local nSelectNum = 0;
		
	for i = 1,30 do
		if g_LuckyBag_ShowItemInfo[i].disable == 1 then
			nSelectNum = nSelectNum + 1
		end
	end
		
	if nSelectNum == 0 then
		PushDebugMessage("#{SWZB_190322_26}")
		return 0		
	end
		
	local cost = LuckyBag_GetCost()
	local myCurrency = Lua_GetMyZNQCurrency(g_LuckyBag_Select-1)	
	local curstr = LuckyBag_GetCurrencyStr()
	if cost*nSelectNum > myCurrency then
		PushDebugMessage(ScriptGlobal_Format("#{SWZB_190322_27}",curstr))
		return 0
	end
	
	local curstr = LuckyBag_GetBagstr()
	local str = ScriptGlobal_Format("#{SWZB_190322_28}",nSelectNum)
		
	--二次确认
	PushEvent("CONFIRM_ZNQFUDAI_SELECT", 0, str)
	
	-- Lua_ZNQfudaiSendInsert(g_LuckyBag_Select,nSelectNum);

end


