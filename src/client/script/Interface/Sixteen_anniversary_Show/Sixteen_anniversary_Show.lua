--周年情怀任务 情怀册界面
--!!!reloadscript =Sixteen_anniversary_Show

local g_Frame_Pos = nil
local g_Image_List = {}
local g_Text_List = {}

local g_Info_Complete = {
	[1] = {text="#{QHRW_230317_10}"},
	[2] = {text="#{QHRW_230317_12}"},
	[3] = {text="#{QHRW_230317_14}"},
	[4] = {text="#{QHRW_230317_16}"},
}

local g_Info_UnComplete = {
	[1] = {text="#{QHRW_230317_09}"},
	[2] = {text="#{QHRW_230317_11}"},
	[3] = {text="#{QHRW_230317_13}"},
	[4] = {text="#{QHRW_230317_15}"},
}

local MenPaiList = {
		[0] = "#{QHRW_230317_104}",    --少林
		[1] = "#{QHRW_230317_109}",    --明教
		[2] = "#{QHRW_230317_106}",    --丐帮
		[3] = "#{QHRW_230317_102}",    --武当
		[4] = "#{QHRW_230317_108}",    --峨眉
		[5] = "#{QHRW_230317_105}",    --星宿
		[6] = "#{QHRW_230317_103}",    --天龙
		[7] = "#{QHRW_230317_107}",    --天山
		[8] = "#{QHRW_230317_101}",    --逍遥
		[9] = "#{GMGameInterface_Script_DataPool_Info_WuMenPai}",         --无门派
		[10] = "#{QHRW_230317_110}",  --慕容
		[11] = "#{QHRW_230317_111}",  --唐门
		[12] = "#{QHRW_230317_112}",  --鬼谷
        [13] = "#{QHRW_230317_113}",  --桃花岛
		[14] = "#{QHRW_230317_114}",	--绝情谷
		[15] = "#{XMPHM_210604_31}",	--menpai15 mptodo
}

function Sixteen_anniversary_Show_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
end


function Sixteen_anniversary_Show_OnLoad()
	g_Frame_Pos = Sixteen_anniversary_Show_Frame:GetProperty("UnifiedPosition")
	
	g_Image_List[1] = Sixteen_anniversary_Show_PicBK1
	g_Image_List[2] = Sixteen_anniversary_Show_PicBK2
	g_Image_List[3] = Sixteen_anniversary_Show_PicBK3
	g_Image_List[4] = Sixteen_anniversary_Show_PicBK4
	
	g_Text_List[1] = Sixteen_anniversary_Show_PicText1
	g_Text_List[2] = Sixteen_anniversary_Show_PicText2
	g_Text_List[3] = Sixteen_anniversary_Show_PicText3
	g_Text_List[4] = Sixteen_anniversary_Show_PicText4
end

function Sixteen_anniversary_Show_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 99847301 )  then 
		Sixteen_anniversary_Show_Open()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Sixteen_anniversary_Show_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Sixteen_anniversary_Show_Closed()

	end
end


--=========
-- 重置
--=========
function Sixteen_anniversary_Show_On_ResetPos()
	Sixteen_anniversary_Show_Frame:SetProperty("UnifiedPosition", g_Frame_Pos)
end



--=========
-- 关闭
--=========
function Sixteen_anniversary_Show_Closed()
	this:Hide()
end

--=========
-- 打开
--=========
function Sixteen_anniversary_Show_Open()
	local finish = {}
	finish[1] = Get_XParam_INT(0)
	finish[2] = Get_XParam_INT(1)
	finish[3] = Get_XParam_INT(2)
	finish[4] = Get_XParam_INT(3)
	
	for index = 1,table.getn(finish) do
		if finish[index] == 1 then
			g_Image_List[index]:Hide()
			g_Text_List[index]:SetText(g_Info_Complete[index].text)
			
		else
			local strText = g_Info_UnComplete[index].text
			if index == 3 then
				local menpaiID = Player : GetData("MEMPAI")
				strText = ScriptGlobal_Format(g_Info_UnComplete[index].text, MenPaiList[menpaiID])
			end

			g_Image_List[index]:Show()
			g_Text_List[index]:SetText(strText)
			
		end
	end
	
	this:Show()
end

