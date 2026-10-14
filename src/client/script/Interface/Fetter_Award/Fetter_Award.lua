--Fetter_Award.lua
--星阵-羁绊总览界面
local g_Frame_UnifiedPosition
local g_Award_Group_Id = 0

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Fetter_Award_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_FETTER_AWARD")
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Fetter_Award_OnLoad()
	g_Frame_UnifiedPosition = Fetter_Award_Frame:GetProperty("UnifiedPosition")
end

--响应事件的函数，当注册的事件发生时会调用的函数
function Fetter_Award_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		Fetter_Award_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif ( event == "OPEN_FETTER_AWARD" ) then
		g_Award_Group_Id = tonumber(arg0)
		this:Show()
		this:Activate()
		Fetter_Award_FullUpInfo()
	end
end

function Fetter_Award_OnHidden()
	this:Hide()
end
function Fetter_Award_GetYingXiongLevel()
	local nHaogandu = 0
	local nMin, nMax = DataPool:LuaFnGetXingZhen_JiBanAwardRange(g_Award_Group_Id)
	local tabInfo = {}
	tabInfo[1],tabInfo[2],tabInfo[3],tabInfo[4],tabInfo[5],tabInfo[6],tabInfo[7],tabInfo[8],tabInfo[9],tabInfo[10] = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nMin, "YingXiongIds")
	for _, nYingXiongId in pairs(tabInfo) do 
		nHaogandu = nHaogandu + DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
	end
	return nHaogandu
end
function Fetter_Award_FullUpInfo()
	local nMin, nMax = DataPool:LuaFnGetXingZhen_JiBanAwardRange(g_Award_Group_Id)
	local nYingXiongLevel = Fetter_Award_GetYingXiongLevel()

	Fetter_Award_List:Clear()
	local tabAttrIds = { {id=0,num=0},{id=0,num=0},{id=0,num=0},{id=0,num=0}}
	for nAwardId =nMin,nMax do
		local id1,num1,id2,num2,id3,num3 = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nAwardId, "AddAttr") 
		tabAttrIds[1].id = id1
		tabAttrIds[1].num = tabAttrIds[1].num + num1
		tabAttrIds[2].id = id2
		tabAttrIds[2].num = tabAttrIds[2].num + num2
		tabAttrIds[3].id = id3
		tabAttrIds[3].num = tabAttrIds[3].num + num3
		local nAddLevel = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nAwardId, "AddLevel") 
		
		local uiPrefab = Fetter_Award_List:AddChild("Fetter_Award_AwardItem")
		if nYingXiongLevel < nAddLevel then 
			uiPrefab:GetSubItem("Fetter_Award_GetCondition"):SetText( ScriptGlobal_Format("#{XZYX_200309_327}", nAddLevel))
		elseif not DataPool:LuaFnGetXingZhen_JiBanAwardFlag(nAwardId) then 
			uiPrefab:GetSubItem("Fetter_Award_GetCondition"):SetText( ScriptGlobal_Format("#{XZYX_200309_327}", nAddLevel))
		else
			-- 策划：仅在当前已领取的最高档次奖励调用字典：XZYX_200309_329
			if nAwardId ==nMax or not DataPool:LuaFnGetXingZhen_JiBanAwardFlag(nAwardId+1) then 
				uiPrefab:GetSubItem("Fetter_Award_GetCondition"):SetText( ScriptGlobal_Format("#{XZYX_200309_329}", nAddLevel))
			else
				uiPrefab:GetSubItem("Fetter_Award_GetCondition"):SetText( ScriptGlobal_Format("#{XZYX_200309_327}", nAddLevel))
			end
		end
		local tabUIAttr = {
			uiPrefab:GetSubItem("Fetter_Award_Award_Text1"),
			uiPrefab:GetSubItem("Fetter_Award_Award_Text2"),
			uiPrefab:GetSubItem("Fetter_Award_Award_Text3"),
		}
		local nIndex = 1
		for i, v in pairs(tabAttrIds) do 
			if v.num and v.num > 0 then 
				tabUIAttr[nIndex]:Show()
				tabUIAttr[nIndex]:SetText(ScriptGlobal_Format("#{XZYX_200309_330}", "#{"..v.id.."}",v.num))
				nIndex = nIndex + 1
			end
		end
		for i=nIndex,table.getn(tabUIAttr) do 
			tabUIAttr[i]:Hide()
		end
	end
end

