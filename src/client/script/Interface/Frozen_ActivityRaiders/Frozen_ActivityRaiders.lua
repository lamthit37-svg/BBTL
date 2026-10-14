--Frozen 整合界面
local g_Frozen_ActivityRaiders_Frame_UnifiedPosition   
local g_Frozen_ActivityRaiders_UICOM_Open       = 50101201 
local g_Frozen_ActivityRaiders_Ctl    = {} 
local g_Frozen_ActivityRaiders_listitem ={}
local g_Frozen_ActivityRaiders_ptfunc = 0
local g_Frozen_ActivityRaiders_jd = 0
local g_Frozen_ActivityRaiders_lj = 0
local g_Frozen_ActivityRaiders_info = {
	[1] = {needlevel=60,image="set:Huodong_20 image:Huodong_20_1",name="#{BXJD_241118_12}",level="#{BXJD_241118_13}",ds=1,btntip="#{BXJD_241118_38}"}, --冰雪大作战
	[2] = {needlevel=30,image="set:Huodong_21 image:Huodong_21_4",name="#{BXJD_241118_18}",level="#{BXJD_241118_19}",ds=1,btntip="#{BXJD_241118_39}"}, --假面舞会 
	[3] = {needlevel=30,image="set:Huodong_20 image:Huodong_20_6",name="#{BXJD_241118_21}",level="#{BXJD_241118_22}",ds=1,btntip="#{BXJD_241118_40}"}, --苞米地往事
	[4] = {needlevel=30,image="set:Huodong_20 image:Huodong_20_4",name="#{BXJD_241118_24}",level="#{BXJD_241118_25}",ds=1,btntip="#{BXJD_241118_41}"}, --月下瑶台 
	[5] = {needlevel=30,image="set:Huodong_20 image:Huodong_20_3",name="#{BXJD_241118_27}",level="#{BXJD_241118_28}",ds=1,btntip="#{BXJD_241118_42}"}, --猛兽战车 
	[6] = {needlevel=30,image="set:Huodong_20 image:Huodong_20_7",name="#{BXJD_241118_30}",level="#{BXJD_241118_31}",ds=1,btntip="#{BXJD_241118_43}"}, --冻冻脑瓜 
	[7] = {needlevel=30,image="set:Huodong_20 image:Huodong_20_8",name="#{BXJD_241118_33}",level="#{BXJD_241118_34}",ds=1,btntip="#{BXJD_241118_44}"}, --雪人梦工厂
} 
local g_Frozen_ActivityRaiders_jdinfo = {
	[0] ={
		[1] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},	
		[2] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},	
		[3] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},	
		[4] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},	
		[5] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},	
		[6] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},	
		[7] = {tooltips="#{BXJD_241118_39}",showid=39924871,num=1,},	
	},
	[1] ={
		[1] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},
		[2] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},
		[3] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},
		[4] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},
		[5] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},
		[6] = {tooltips="#{BXJD_241118_38}",showid=39924870,num=1,},
		[7] = {tooltips="#{BXJD_241118_40}",showid=39924870,num=2,},
	},
} 
local g_Frozen_ActivityRaiders_Point_Max = 2
local g_Frozen_ActivityRaiders_PerGroupnum  = 7
local g_Frozen_ActivityRaiders_Funcnum  = 7
local g_Frozen_ActivityRaiders_GroupTotalnum = 28
local g_Frozen_ActivityRaiders_Groupinfo = {7,14,21,28}
local g_Frozen_ActivityRaiders_funcstate = {}
local g_Frozen_ActivityRaiders_Giftstate = {}
local g_Frozen_ActivityRaiders_JDstate = {}
local g_Frozen_ActivityRaiders_Point = 0
local g_Frozen_ActivityRaiders_Step  = 0
local g_Frozen_ActivityRaiders_Ctl = {}
local g_Frozen_ActivityRaiders_funcOpenstate = {0,0,0,0,0,0,0,} 
local g_Frozen_ActivityRaiders_YXYTOpenState = 0
local g_Frozen_ActivityRaiders_CurPage = 0

function Frozen_ActivityRaiders_PreLoad()
	--第二个参数代表界面隐藏时事件是否有效,默认为true
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) --进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS", false)

end

function Frozen_ActivityRaiders_OnLoad()
	Frozen_ActivityRaiders_LoadControl()
	g_Frozen_ActivityRaiders_Frame_UnifiedPosition = Frozen_ActivityRaiders_Frame:GetProperty("UnifiedPosition")
end

-- 装载控件
function Frozen_ActivityRaiders_LoadControl() 
	g_Frozen_ActivityRaiders_Ctl.Point = Frozen_ActivityRaiders_Huoyue_Text0
	g_Frozen_ActivityRaiders_Ctl.JinDu = {}
	g_Frozen_ActivityRaiders_Ctl.JinDu[1] = {}
	g_Frozen_ActivityRaiders_Ctl.JinDu[2] = {}
	g_Frozen_ActivityRaiders_Ctl.JinDu[3] = {}
	g_Frozen_ActivityRaiders_Ctl.JinDu[4] = {}
	g_Frozen_ActivityRaiders_Ctl.JinDu[5] = {}
	g_Frozen_ActivityRaiders_Ctl.JinDu[6] = {}
	g_Frozen_ActivityRaiders_Ctl.JinDu[7] = {}
	g_Frozen_ActivityRaiders_Ctl.JinDu[1].BT = Frozen_ActivityRaiders_Icon1	
	g_Frozen_ActivityRaiders_Ctl.JinDu[1].RP = Frozen_ActivityRaiders_Icon1_Tips
	g_Frozen_ActivityRaiders_Ctl.JinDu[1].YL = Frozen_ActivityRaiders_Icon1_Mark
	g_Frozen_ActivityRaiders_Ctl.JinDu[2].BT = Frozen_ActivityRaiders_Icon2	
	g_Frozen_ActivityRaiders_Ctl.JinDu[2].RP = Frozen_ActivityRaiders_Icon2_Tips
	g_Frozen_ActivityRaiders_Ctl.JinDu[2].YL = Frozen_ActivityRaiders_Icon2_Mark
	g_Frozen_ActivityRaiders_Ctl.JinDu[3].BT = Frozen_ActivityRaiders_Icon3	
	g_Frozen_ActivityRaiders_Ctl.JinDu[3].RP = Frozen_ActivityRaiders_Icon3_Tips
	g_Frozen_ActivityRaiders_Ctl.JinDu[3].YL = Frozen_ActivityRaiders_Icon3_Mark
	g_Frozen_ActivityRaiders_Ctl.JinDu[4].BT = Frozen_ActivityRaiders_Icon4	
	g_Frozen_ActivityRaiders_Ctl.JinDu[4].RP = Frozen_ActivityRaiders_Icon4_Tips
	g_Frozen_ActivityRaiders_Ctl.JinDu[4].YL = Frozen_ActivityRaiders_Icon4_Mark
	g_Frozen_ActivityRaiders_Ctl.JinDu[5].BT = Frozen_ActivityRaiders_Icon5	
	g_Frozen_ActivityRaiders_Ctl.JinDu[5].RP = Frozen_ActivityRaiders_Icon5_Tips
	g_Frozen_ActivityRaiders_Ctl.JinDu[5].YL = Frozen_ActivityRaiders_Icon5_Mark
	g_Frozen_ActivityRaiders_Ctl.JinDu[6].BT = Frozen_ActivityRaiders_Icon6	
	g_Frozen_ActivityRaiders_Ctl.JinDu[6].RP = Frozen_ActivityRaiders_Icon6_Tips
	g_Frozen_ActivityRaiders_Ctl.JinDu[6].YL = Frozen_ActivityRaiders_Icon6_Mark
	g_Frozen_ActivityRaiders_Ctl.JinDu[7].BT = Frozen_ActivityRaiders_Icon7	
	g_Frozen_ActivityRaiders_Ctl.JinDu[7].RP = Frozen_ActivityRaiders_Icon7_Tips
	g_Frozen_ActivityRaiders_Ctl.JinDu[7].YL = Frozen_ActivityRaiders_Icon7_Mark
end

-- Event
function Frozen_ActivityRaiders_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_Frozen_ActivityRaiders_UICOM_Open then
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then 
			this:Show() 
		end
		g_Frozen_ActivityRaiders_jd 	= Get_XParam_INT(1) 
		g_Frozen_ActivityRaiders_lj 	= Get_XParam_INT(2) 
		g_Frozen_ActivityRaiders_ptfunc = Get_XParam_INT(3)  
		g_Frozen_ActivityRaiders_YXYTOpenState = Get_XParam_INT(4)  
		for i = 5, 5 + table.getn(g_Frozen_ActivityRaiders_funcOpenstate) do
			g_Frozen_ActivityRaiders_funcOpenstate[i-4] = Get_XParam_INT(i)  
		end 
		Frozen_ActivityRaiders_Update(1,bShow) 
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_ActivityRaiders_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_ActivityRaiders_Close()
	elseif event == "ADJEST_UI_POS" then
		Frozen_ActivityRaiders_On_ResetPos()
	end

end

-- 重置界面位置
function Frozen_ActivityRaiders_On_ResetPos()
	Frozen_ActivityRaiders_Frame:SetProperty("UnifiedPosition", g_Frozen_ActivityRaiders_Frame_UnifiedPosition)
end

function Frozen_ActivityRaiders_OnHidden()
	Frozen_ActivityRaiders_Close()
end

-- 关闭
function Frozen_ActivityRaiders_Close() 
	g_Frozen_ActivityRaiders_CurPage = 1
	this:Hide()
end

function Frozen_ActivityRaiders_Update(isresetpos,isrefreshlist)
	for i = 1, table.getn(g_Frozen_ActivityRaiders_listitem) do
		if g_Frozen_ActivityRaiders_listitem[i] ~= nil then
			g_Frozen_ActivityRaiders_listitem[i] = nil
		end
	end
	--各个功能完成情况
    for i = 1, g_Frozen_ActivityRaiders_Funcnum do
		_,g_Frozen_ActivityRaiders_funcstate[i] = GetBitValueInUINT(g_Frozen_ActivityRaiders_ptfunc, i-1, 1)  
		--Lua_TDU_Log("g_Frozen_ActivityRaiders_funcstate[i]:"..i..":"..g_Frozen_ActivityRaiders_funcstate[i]); 
	end
	--进度情况	
	for i = 1, g_Frozen_ActivityRaiders_GroupTotalnum do
		_,g_Frozen_ActivityRaiders_JDstate[i] = GetBitValueInUINT(g_Frozen_ActivityRaiders_jd, i-1, 1)  
	end
	--领奖情况
	for i = 1, g_Frozen_ActivityRaiders_GroupTotalnum do
		_,g_Frozen_ActivityRaiders_Giftstate[i] = GetBitValueInUINT(g_Frozen_ActivityRaiders_lj, i-1, 1)  
	end
	--点数
	_,g_Frozen_ActivityRaiders_Point = GetBitValueInUINT(g_Frozen_ActivityRaiders_ptfunc, g_Frozen_ActivityRaiders_Funcnum, 4)   
	if isrefreshlist == 1 then
		Frozen_ActivityRaiders_PageList:Clear() 
		--活动情况区域
		local sorttable = Frozen_ActivityRaiders_GetSortTbl()
		for i = 1, table.getn(sorttable) do
			local tblidx = sorttable[i]
			--第一列
			local bar1 = Frozen_ActivityRaiders_PageList:AddChild("Frozen_ActivityRaiders_CoinAItem1")
			if not bar1 then
			   break
			end    
			bar1:GetSubItem("Frozen_ActivityRaiders_CoinAItem1_Act"):SetProperty("Image",g_Frozen_ActivityRaiders_info[tblidx].image)
			bar1:GetSubItem("Frozen_ActivityRaiders_CoinAItem1_Name"):SetText(g_Frozen_ActivityRaiders_info[tblidx].name)
			bar1:GetSubItem("Frozen_ActivityRaiders_CoinAItem1_Art"):SetText(g_Frozen_ActivityRaiders_info[tblidx].level)
			--假面特写 
			if tblidx == 2 and g_Frozen_ActivityRaiders_funcOpenstate[tblidx] == 0 then
				bar1:GetSubItem("Frozen_ActivityRaiders_CoinAItem1_Art"):SetText("#{BXJD_241118_20}")
			end
			bar1:GetSubItem("Frozen_ActivityRaiders_CoinAItem1_Icon"):SetText(ScriptGlobal_Format("#{BXJD_241118_52}", g_Frozen_ActivityRaiders_info[tblidx].ds) ) 
			if g_Frozen_ActivityRaiders_funcstate[tblidx] == 1 then
				bar1:GetSubItem("Frozen_ActivityRaiders_FButton1"):Hide()
				bar1:GetSubItem("Frozen_ActivityRaiders_ListFinish"):Show()
			else
				bar1:GetSubItem("Frozen_ActivityRaiders_FButton1"):Show()
				bar1:GetSubItem("Frozen_ActivityRaiders_ListFinish"):Hide()
			end
			bar1:GetSubItem("Frozen_ActivityRaiders_ListLocked"):Hide()
			bar1:GetSubItem("Frozen_ActivityRaiders_FButton1"):SetEvent("MouseLClick", string.format("Frozen_ActivityRaiders_GOTO(%d)", tblidx))  
			bar1:GetSubItem("Frozen_ActivityRaiders_FButton1"):SetToolTip("#{BXJD_241118_36}") 
			if g_Frozen_ActivityRaiders_funcOpenstate[tblidx] == 0 then
				bar1:GetSubItem("Frozen_ActivityRaiders_FButton1"):Hide()
				bar1:GetSubItem("Frozen_ActivityRaiders_ListFinish"):Hide()
				bar1:GetSubItem("Frozen_ActivityRaiders_ListLocked"):Show() 
			end
			g_Frozen_ActivityRaiders_listitem[tblidx] = bar1
		end
	end

	--领奖展示区域
	g_Frozen_ActivityRaiders_Ctl.Point:SetText(ScriptGlobal_Format("#{BXJD_241118_6}",g_Frozen_ActivityRaiders_Point)) 
	if isresetpos == 1 then
		g_Frozen_ActivityRaiders_CurPage = Frozen_ActivityRaiders_GetCurPageNum() 
		--Lua_TDU_Log("Frozen_ActivityRaiders_GetCurPageNum:"..g_Frozen_ActivityRaiders_CurPage);  
	end 
	for i = 1, table.getn(g_Frozen_ActivityRaiders_Ctl.JinDu) do 
		local strtooltips = g_Frozen_ActivityRaiders_jdinfo[KaJi:LuaFnGetKaJiType(163)][i].tooltips
		local itemid = g_Frozen_ActivityRaiders_jdinfo[KaJi:LuaFnGetKaJiType(163)][i].showid
		local num 	 = g_Frozen_ActivityRaiders_jdinfo[KaJi:LuaFnGetKaJiType(163)][i].num 
		local itemid = g_Frozen_ActivityRaiders_jdinfo[KaJi:LuaFnGetKaJiType(163)][i].showid
		local num 	 = g_Frozen_ActivityRaiders_jdinfo[KaJi:LuaFnGetKaJiType(163)][i].num
		local theAction = DataPool:CreateActionItemForShow(itemid, num)
		if theAction:GetID() ~= 0 then
			g_Frozen_ActivityRaiders_Ctl.JinDu[i].BT:SetActionItem(theAction:GetID()); 
		end 
		g_Frozen_ActivityRaiders_Ctl.JinDu[i].BT:SetToolTip(strtooltips) 
		g_Frozen_ActivityRaiders_Ctl.JinDu[i].RP:Hide()
		g_Frozen_ActivityRaiders_Ctl.JinDu[i].YL:Hide() 
		if g_Frozen_ActivityRaiders_Giftstate[(g_Frozen_ActivityRaiders_CurPage-1)*g_Frozen_ActivityRaiders_PerGroupnum+i] == 0 and g_Frozen_ActivityRaiders_JDstate[(g_Frozen_ActivityRaiders_CurPage-1)*g_Frozen_ActivityRaiders_PerGroupnum+i] == 1 then
			g_Frozen_ActivityRaiders_Ctl.JinDu[i].RP:Show()
		end
		if g_Frozen_ActivityRaiders_Giftstate[(g_Frozen_ActivityRaiders_CurPage-1)*g_Frozen_ActivityRaiders_PerGroupnum+i] == 1 then 
			g_Frozen_ActivityRaiders_Ctl.JinDu[i].YL:Show()		
		end
	end
	if g_Frozen_ActivityRaiders_CurPage == 1 then
		Frozen_ActivityRaiders_Huoyue_LeftArrow:Disable()
	else
		Frozen_ActivityRaiders_Huoyue_LeftArrow:Enable()
	end
	local totalpage = math.floor(g_Frozen_ActivityRaiders_GroupTotalnum / g_Frozen_ActivityRaiders_PerGroupnum)
	if g_Frozen_ActivityRaiders_CurPage == totalpage then
		Frozen_ActivityRaiders_Huoyue_RightArrow:Disable()
	else
		Frozen_ActivityRaiders_Huoyue_RightArrow:Enable()
	end
	
	Frozen_ActivityRaiders_HuoyuePageNum:SetText(ScriptGlobal_Format("#{BXJD_241118_60}",g_Frozen_ActivityRaiders_CurPage,totalpage))

end

function Frozen_ActivityRaiders_GOTO(idx)
	local nLevel = Player:GetLevel();

	if nLevel < g_Frozen_ActivityRaiders_info[idx].needlevel then
		PushDebugMessage("#{BXJD_241118_51}")
		return
	end

	if idx == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenGotoUI")
			Set_XSCRIPT_ScriptID(800302)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif idx == 2 then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI")
			Set_XSCRIPT_ScriptID(820094)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	 
	elseif idx == 3 then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenActivityUI")
			Set_XSCRIPT_ScriptID(999463)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif idx == 4 then  
		if g_Frozen_ActivityRaiders_YXYTOpenState == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OpenWindowRequest")
				Set_XSCRIPT_ScriptID(999512)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()	 
		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OpenWindowRequest")
				Set_XSCRIPT_ScriptID(999513)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()	
		end 	
	elseif idx == 5 then 
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskOpenMainUI")
			Set_XSCRIPT_ScriptID(999496)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif idx == 6 then  
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenUI")
			Set_XSCRIPT_ScriptID(999482)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif idx == 7 then  
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenGotoUI")
		Set_XSCRIPT_ScriptID(999473)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	end
end

function Frozen_ActivityRaiders_PrizeClicked(idx)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetGift")
		Set_XSCRIPT_ScriptID( 501012 )
		Set_XSCRIPT_Parameter( 0, (idx-1)+(g_Frozen_ActivityRaiders_CurPage-1)*g_Frozen_ActivityRaiders_PerGroupnum ); 
		Set_XSCRIPT_ParamCount( 1 ); 
	Send_XSCRIPT() 
end

function Frozen_ActivityRaiders_Help_Clicked()
	local svrtype =KaJi:LuaFnGetKaJiType(163)
	if svrtype == 0 then
		PushEvent("CCSHOP_HELP", 230) 
	else
		PushEvent("CCSHOP_HELP", 231) 
	end
end

function Frozen_ActivityRaiders_GetSortTbl()
	local sorttbl = {}
	local idx = 1 
 
	for i = 1, g_Frozen_ActivityRaiders_Funcnum do
		if g_Frozen_ActivityRaiders_funcstate[i] == 0 and g_Frozen_ActivityRaiders_funcOpenstate[i] == 1 then  
			sorttbl[idx] = i
			Lua_TDU_Log(string.format("1sorttbl[%d] = %d", idx,i));
			idx = idx + 1 
		end 
	end
	Lua_TDU_Log(string.format("1Frozen_ActivityRaiders_GetSortTbl= %d", idx));
	for i = 1, g_Frozen_ActivityRaiders_Funcnum do
		if g_Frozen_ActivityRaiders_funcstate[i] == 1 then
			sorttbl[idx] = i
			idx = idx + 1
			Lua_TDU_Log(string.format("2sorttbl[%d] = %d", idx,i));
		end 
	end
	
	Lua_TDU_Log(string.format("2Frozen_ActivityRaiders_GetSortTbl= %d", idx));
	for i = 1, g_Frozen_ActivityRaiders_Funcnum do
		if g_Frozen_ActivityRaiders_funcOpenstate[i] == 0 then
			sorttbl[idx] = i
			Lua_TDU_Log(string.format("3sorttbl[%d] = %d", idx,i));
			idx = idx + 1
		end 
	end  
	Lua_TDU_Log(string.format("3Frozen_ActivityRaiders_GetSortTbl= %d", idx));
	return sorttbl
end

function Frozen_ActivityRaiders_GetCurPageNum()
	local pos = 1
	local curpage = 1
	for i = 1, g_Frozen_ActivityRaiders_GroupTotalnum do
		if g_Frozen_ActivityRaiders_Giftstate[i] == 0 and g_Frozen_ActivityRaiders_JDstate[i] == 1 then
			pos = i 
		elseif g_Frozen_ActivityRaiders_Giftstate[i] == 1 and g_Frozen_ActivityRaiders_JDstate[i] == 1 then
			pos = i 
		end
	end
	local totalpage = math.floor(g_Frozen_ActivityRaiders_GroupTotalnum / g_Frozen_ActivityRaiders_PerGroupnum)
	for i = 1, totalpage do
		if pos > (i-1) * g_Frozen_ActivityRaiders_PerGroupnum then
			curpage = i
		end
	end
	return curpage
end

function Frozen_ActivityRaiders_Huoyue_Page_Left()
	if g_Frozen_ActivityRaiders_CurPage > 1 then  
		g_Frozen_ActivityRaiders_CurPage = g_Frozen_ActivityRaiders_CurPage - 1
	end
	Frozen_ActivityRaiders_Update(0,0) 
end

function Frozen_ActivityRaiders_Huoyue_Page_Right()
	local totalpage = math.floor(g_Frozen_ActivityRaiders_GroupTotalnum / g_Frozen_ActivityRaiders_PerGroupnum)
	if g_Frozen_ActivityRaiders_CurPage < totalpage then  
		g_Frozen_ActivityRaiders_CurPage = g_Frozen_ActivityRaiders_CurPage + 1
	end
	Frozen_ActivityRaiders_Update(0,0) 
end