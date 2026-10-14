--!!!reloadscript =Xunzhang_TuJian_Record
local g_Xunzhang_TuJian_Record_UnifiedPosition = ""

local g_CurXunzhangRealId           = 0

local g_CurXunzhangRecordsNum       = 0

local g_objCared = -1;

--=========
--PreLoad==
--=========
function Xunzhang_TuJian_Record_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", false)
	
	this:RegisterEvent("UNIT_LEVEL",false)
	
	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("XUNZHANG_DATA_UPDATE",false)
	
	this:RegisterEvent("XUNZHANG_RECORD_OPEN_OTHER")
	
	this:RegisterEvent("XUNZHANG_RECORD_OPEN")
	
end

--=========
--OnLoad
--=========
function Xunzhang_TuJian_Record_OnLoad()
	
	g_Xunzhang_TuJian_Record_UnifiedPosition = Xunzhang_TuJian_Record_Frame:GetProperty("UnifiedPosition")

end
--=========
--OnEvent
--=========
function Xunzhang_TuJian_Record_OnEvent(event)
	
	if event == "XUNZHANG_RECORD_OPEN_OTHER" then

		g_CurXunzhangRealId = tonumber(arg0)
		g_CurXunzhangRecordsNum = tonumber(arg1)
		--PushDebugMessage("g_CurXunzhangRealId = "..g_CurXunzhangRealId.."  g_CurXunzhangRecordsNum = "..g_CurXunzhangRecordsNum)		
		if g_CurXunzhangRealId > 0 and g_CurXunzhangRecordsNum >= 0 then
			Xunzhang_TuJian_Record_SetWindowPosition()	
			this:Show()
			Xunzhang_TuJian_Record_InitAndShow(0)
		end	
		
			g_objCared = CachedTarget:GetData("NPCID", 1)
			if (type(g_objCared) ~="number") then
				----PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
				return
			end

			-- 开始关心OBJ
			Xunzhang_TuJian_Record_BeginCareObject(g_objCared);		
		
		return
	end
	
	if event == "XUNZHANG_RECORD_OPEN" then
		
		g_CurXunzhangRealId = tonumber(arg0)
		g_CurXunzhangRecordsNum = tonumber(arg1)
	--	PushDebugMessage("g_CurXunzhangRealId = "..g_CurXunzhangRealId.."  g_CurXunzhangRecordsNum = "..g_CurXunzhangRecordsNum)		
		if g_CurXunzhangRealId > 0 and g_CurXunzhangRecordsNum >= 0 then
			Xunzhang_TuJian_Record_SetWindowPosition()	
			this:Show()
			Xunzhang_TuJian_Record_InitAndShow(1)
		end	
		
		return
	end
	
	if (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if( arg1=="destroy") then
			Xunzhang_TuJian_Record_CloseClick();
			return;
		end
	end
	
	if event == "UNIT_LEVEL" and arg0 == "player" then
	
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Xunzhang_TuJian_Record_Frame:SetProperty("UnifiedPosition", g_Xunzhang_TuJian_Record_UnifiedPosition)
	end

end


function Xunzhang_TuJian_Record_InitAndShow(isMe)

	Xunzhang_TuJian_Record_CleanUp()
	Xunzhang_TuJian_Record_SetItem(isMe)
	Xunzhang_TuJian_Record_Update(isMe)

end


function Xunzhang_TuJian_Record_SetItem(isMe)  --index 1开头

	local strIcon 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "IconNormal")
	local strName 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "Name")
	--local strImage	= GetIconFullName(strIcon)
	local strSource 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "Source")
	local nActivateType = XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "ActivateType")
	local nCondition1	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "Condition1")
	local nCondition2	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "Condition2")
	local nFirstActDate	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "FirstActDate")
	local nCurAccTimes	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "CurAccTimes")
	local nIsActivate	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "IsActivate")
	local strRecordDict1	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "RecordDict1")
	local strRecordDict2	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "RecordDict2")

	if isMe ~= 1 then
		strIcon 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "IconNormal")
		strName 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "Name")
		--strImage	= GetIconFullName(strIcon)
		strSource 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "Source")
		nActivateType = XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "ActivateType")
		nCondition1	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "Condition1")
		nCondition2	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "Condition2")
		nFirstActDate	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "FirstActDate")
		nCurAccTimes	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "CurAccTimes")
		nIsActivate	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "IsActivate")
		strRecordDict1	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "RecordDict1")
		strRecordDict2	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(g_CurXunzhangRealId, "RecordDict2")
	end

	Xunzhang_TuJian_Record_Item:SetProperty("Image",strIcon)
	--Xunzhang_TuJian_Record_Item:SetImage("Anniversary2022_Yure","Anniversary2022_Yure_Over")
	Xunzhang_TuJian_Record_ItemName:SetText(strName)
	local accTimeForShow = nCurAccTimes
	if accTimeForShow < 0 then accTimeForShow = 0 end
	if nCondition1 < 0 then nCondition1 = 0 end
	if accTimeForShow > nCondition1 then accTimeForShow = nCondition1 end
	Xunzhang_TuJian_Record_ItemInfo_Text:SetText( ScriptGlobal_Format(strSource,accTimeForShow,nCondition1))
	
	--PushDebugMessage("Source = "..strSource.."  nCurAccTimes = "..nCurAccTimes.."  nCondition1 = "..nCondition1)
	

end


function Xunzhang_TuJian_Record_Update(isMe)
	
	Xunzhang_TuJian_Record_ItemInfo_List:ClearAllElement()
	
	local nMessageNum = g_CurXunzhangRecordsNum
	
	local strRecordDict1	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "RecordDict1")
	local strRecordDict2	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(g_CurXunzhangRealId, "RecordDict2")
	
	---g_AllRecordPage = math.floor((g_CurXunzhangRecordsNum-1)/MESSAGE_EACH_PAGE)+1;
	
	
	
	--  每一页显示最多10个
	local recordDate = 0;
	local paramByte1 = 0;
	local paramByte2 = 0;
	local paramShort = 0;
	local paramInt = 0;
	local i=1;
	for i=0, nMessageNum-1 do
		if isMe == 1 then
			recordDate,paramInt,paramShort,paramByte1,paramByte2 = XunzhangSysScript:LuaFnEnumXunzhangRecord(i)
		else
			recordDate,paramInt,paramShort,paramByte1,paramByte2 =  XunzhangSysScript:LuaFnEnumXunzhangRecord_Other(i)
		end
		
	
		
		if recordDate ~= -1 then
			local yyyy = math.floor(tonumber(recordDate) / 10000)
			local mm = math.floor(math.mod(tonumber(recordDate) , 10000) / 100)
			local dd = math.mod(tonumber(recordDate) , 100)
			local showdate = ScriptGlobal_Format("#{XZXT_240517_73}",yyyy,mm,dd)
			local showstr = string.format(strRecordDict1,showdate,paramInt,paramShort,paramByte1,paramByte2)
			if paramInt == 0 then
				showstr = string.format(strRecordDict2,showdate,paramInt,paramShort,paramByte1,paramByte2)
			end
			
			Xunzhang_TuJian_Record_ItemInfo_List:AddTextElement(showstr)
		end
	end
	
	--Xunzhang_TuJian_Record_UpPage:Enable();
	--Xunzhang_TuJian_Record_DownPage:Enable();
	
	--if( g_CurrentRecordPage == 1 )  then
	--	Xunzhang_TuJian_Record_UpPage:Disable();
	--end
	
	--if( g_CurrentRecordPage == g_AllRecordPage ) then
	--	Xunzhang_TuJian_Record_DownPage:Disable();
	--end
	
	--local strPageNum = string.format( "%d/%d", g_CurrentRecordPage, g_AllRecordPage )
	--Xunzhang_TuJian_Record_ShuzhiPage:SetText(strPageNum)
end

--=========================================================
--开始关心OBJ
--在开始关心之前需要先确定这个界面是不是已经有“关心”的OBJ，
--如果有的话，先取消已经有的“关心”
--=========================================================
function Xunzhang_TuJian_Record_BeginCareObject(objCaredId)

	if (type(objCaredId) == "number") then
		g_objCared = objCaredId;
		this:CareObject(g_objCared, 1, "Xunzhang_TuJian_Record");
	else
		return;
	end

end

--=========================================================
--停止对某OBJ的关心
--=========================================================
function Xunzhang_TuJian_Record_StopCareObject(objCaredId)

	if (type(objCaredId) == "number") then
		this:CareObject(objCaredId, 0, "Xunzhang_TuJian_Record");
		g_objCared = -1;
	else
		return;
	end

end

function Xunzhang_TuJian_Record_CloseClick()
	Xunzhang_TuJian_Record_SaveWindowPosition()
	Xunzhang_TuJian_Record_StopCareObject(g_objCared)
	this:Hide()
end

function Xunzhang_TuJian_Record_OnHidden()
	Xunzhang_TuJian_Record_CleanUp()
end

function Xunzhang_TuJian_Record_CleanUp()
	SetDefaultMouse();
end


function Xunzhang_TuJian_Record_SaveWindowPosition()
	
	Variable:SetVariable("XunzhangBaseUnionPos", Xunzhang_TuJian_Record_Frame:GetProperty("UnifiedPosition"), 1)
	
end

function Xunzhang_TuJian_Record_SetWindowPosition()
	
	local nXunzhangBaseUnionPos = Variable:GetVariable("XunzhangBaseUnionPos")
	if nXunzhangBaseUnionPos ~= nil then
		Xunzhang_TuJian_Record_Frame:SetProperty("UnifiedPosition", nXunzhangBaseUnionPos)
	end

end

--!!!reloadscript =Xunzhang_TuJian_Record