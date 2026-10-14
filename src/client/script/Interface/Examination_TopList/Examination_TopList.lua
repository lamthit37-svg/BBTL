
-- 金榜

local g_Examination_TopList_targetId = -1;
local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;
local g_Object = -1;

local g_Examination_TopList_Count = 10

local g_Examination_TopList_MyInfo = 0

local g_Examination_TopList_HaveGet = 0

local g_Examination_TopList_UnifiedPosition;

local g_Examination_TopList_RankImage = {
	[1] = "set:Keju image:Keju_No1",
	[2] = "set:Keju image:Keju_No2",
	[3] = "set:Keju image:Keju_No3",
}

local g_Examination_TopList_RankImage2 = {
	[4] = "set:Keju image:Keju_4",
	[5] = "set:Keju image:Keju_5",
	[6] = "set:Keju image:Keju_6",
	[7] = "set:Keju image:Keju_7",
	[8] = "set:Keju image:Keju_8",
	[9] = "set:Keju image:Keju_9",
	[10] = "set:Keju image:Keju_10",
}

local g_Examination_TopList_RankStr = {
	[1] = "#{KJYH_221116_38}", 
	[2] = "#{KJYH_221116_39}", 
	[3] = "#{KJYH_221116_40}",
	[4] = "#{KJYH_221116_83}",
	[5] = "#{KJYH_221116_83}",
	[6] = "#{KJYH_221116_83}",
	[7] = "#{KJYH_221116_83}",
	[8] = "#{KJYH_221116_83}",
	[9] = "#{KJYH_221116_83}",
	[10] = "#{KJYH_221116_83}",
}

function Examination_TopList_PreLoad()
	this:RegisterEvent("OPEN_EXAM_RANKINGLIST")	
	
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Examination_TopList_OnLoad()

	g_Examination_TopList_UnifiedPosition = Examination_TopList_Frame:GetProperty("UnifiedPosition");
	
end

function Examination_TopList_OnEvent(event)

	if ( event == "OPEN_EXAM_RANKINGLIST" ) then

		g_Examination_TopList_HaveGet = tonumber(arg0)
		
		g_Examination_TopList_targetId = tonumber(arg1)
		objCared = DataPool:GetNPCIDByServerID(g_Examination_TopList_targetId);
		if objCared == -1 then
			return;
		end
		BeginCareObject_Exam_TopList(objCared)
					
		Examination_TopList_OnShown()
			
	elseif ( event == "OBJECT_CARED_EVENT" ) then
		
		if(tonumber(arg0) ~= objCared) then
			return
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then			
			--取消关心
			Examination_TopList_OnClose()
		end
		
	elseif (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		Examination_TopList_Frame_On_ResetPos()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Examination_TopList_OnClose()
		
	end
end

function Examination_TopList_OnShown()

	Examination_TopList:Clear()
	
	g_Examination_TopList_MyInfo = 0
	--显示榜单
	for i = 1, g_Examination_TopList_Count do
		local bar = Examination_TopList:AddChild("Examination_TopList_Item")
		
		-- 名次
		bar:GetSubItem("Examination_TopList_RankingImage"):Hide()	-- 图片 1-3
		bar:GetSubItem("Examination_TopList_RankingImage2"):Hide()	-- 数字 4-10
		if g_Examination_TopList_RankImage[i] ~= nil then
			bar:GetSubItem("Examination_TopList_RankingImage"):Show()			
			bar:GetSubItem("Examination_TopList_RankingImage"):SetProperty("Image", g_Examination_TopList_RankImage[i])
		else
			bar:GetSubItem("Examination_TopList_RankingImage2"):Show()
			if g_Examination_TopList_RankImage2[i] ~= nil then
				bar:GetSubItem("Examination_TopList_RankingImageNum"):SetProperty("Image", g_Examination_TopList_RankImage2[i])
			else
				bar:GetSubItem("Examination_TopList_RankingImageNum"):SetText(tostring(i))
			end
		end
		
		-- 姓名
		bar:GetSubItem("Examination_TopList_Name"):SetText("#{KJYH_221116_50}")	-- 虚位以待
		-- 答对数量
		bar:GetSubItem("Examination_TopList_Num"):SetText("#{KJYH_221116_53}")	-- 无		
		-- 答题时间
		bar:GetSubItem("Examination_TopList_Time"):SetText("#{KJYH_221116_53}")	-- 无
		
		-- 从排行榜取数据
		local bValid, nGuid, name, nRank, rightnum, usetime = DataPool:lua_GetExamRankingListInfo(i-1);
		if bValid == 1 then
			local str = ScriptGlobal_Format("#{KJYH_221116_49}", name)
			bar:GetSubItem("Examination_TopList_Name"):SetText(str)
			
			str = ScriptGlobal_Format("#{KJYH_221116_52}", rightnum)
			bar:GetSubItem("Examination_TopList_Num"):SetText(str)
			
			local timeShow = Examination_TopList_FormatTime(usetime)
			str = ScriptGlobal_Format("#{KJYH_221116_55}", timeShow)
			bar:GetSubItem("Examination_TopList_Time"):SetText(str)
			
			if Player:GetGUID() == nGuid then
				g_Examination_TopList_MyInfo = nRank
			end
		end		
	end	
	
	Examination_TopList_My:Hide()
	if g_Examination_TopList_MyInfo > 0 and g_Examination_TopList_RankStr[g_Examination_TopList_MyInfo] ~= nil then
		Examination_TopList_My:Show()
		local str = ScriptGlobal_Format("#{KJYH_221116_56}", g_Examination_TopList_RankStr[g_Examination_TopList_MyInfo])
		Examination_TopList_MyRanking:SetText(str)
		
		if g_Examination_TopList_HaveGet == 0 then
			Examination_TopList_MyGet:Show()
			Examination_TopList_Get_img:Hide()
		else
			Examination_TopList_MyGet:Hide()
			Examination_TopList_Get_img:Show()
		end
	end
		
	this:Show()
	
end

function Examination_TopList_FormatTime(nSec)
	local showmin = math.floor(nSec/60)
	local showsec = math.mod(nSec,60)
	
	if showmin < 10 then
		return string.format("%02d:%02d", showmin, showsec)
	else
		return string.format("%d:%02d", showmin, showsec)
	end	
end

function Examination_TopList_OnMyGet()

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnGetExamTopGift");
		Set_XSCRIPT_ScriptID(998372);
		Set_XSCRIPT_Parameter(0, g_Examination_TopList_targetId);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();

end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_Exam_TopList(objCaredId)

	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "Examination_TopList");
	
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_Exam_TopList(objCaredId)

	this:CareObject(objCaredId, 0, "Examination_TopList");
	g_Object = -1;

end

function Examination_TopList_OnHidden()

	Examination_TopList_OnClose()
	
end

function Examination_TopList_OnClose()
	
	StopCareObject_Exam_TopList(objCared)
	this:Hide();
	
end

function Examination_TopList_OnHelp()

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnClickExamHelp");
		Set_XSCRIPT_ScriptID(998372);
		Set_XSCRIPT_Parameter(0, 1);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	
end

function Examination_TopList_Frame_On_ResetPos()

  Examination_TopList_Frame:SetProperty("UnifiedPosition", g_Examination_TopList_UnifiedPosition)
  
end

