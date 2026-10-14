local MAX_OBJ_DISTANCE = 3.0
local g_JieBaiZFSJ_CaredNpc = -1
local g_JieBaiZFSJ_UnifiedPosition = nil
local g_JieBaiZFSJ_Text = {}
local g_JieBaiZFSJ_ActionButton = {}
local g_JieBaiZFSJ_Skill = {}
function JieBaiZFSJ_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
end


function JieBaiZFSJ_OnLoad()
	g_JieBaiZFSJ_UnifiedPosition = JieBaiZFSJ_Frame:GetProperty("UnifiedPosition")
	g_JieBaiZFSJ_Text[1] = JieBaiZFSJ_BK1_Zhen01_Text2
	g_JieBaiZFSJ_Text[2] = JieBaiZFSJ_BK1_Zhen02_Text2
	g_JieBaiZFSJ_Text[3] = JieBaiZFSJ_BK1_Zhen03_Text2
	g_JieBaiZFSJ_Text[4] = JieBaiZFSJ_BK1_Zhen04_Text2
	
	g_JieBaiZFSJ_ActionButton[1] = JieBaiZFSJ_BK1_Zhen01_Skill1
	g_JieBaiZFSJ_ActionButton[2] = JieBaiZFSJ_BK1_Zhen02_Skill1
	g_JieBaiZFSJ_ActionButton[3] = JieBaiZFSJ_BK1_Zhen03_Skill1
	g_JieBaiZFSJ_ActionButton[4] = JieBaiZFSJ_BK1_Zhen04_Skill1
	
	g_JieBaiZFSJ_Skill[1] = 3229
	g_JieBaiZFSJ_Skill[2] = 3250
	g_JieBaiZFSJ_Skill[3] = 3251
	g_JieBaiZFSJ_Skill[4] = 3252
end


function JieBaiZFSJ_OnEvent(event)
	if (event == "UI_COMMAND") then
		if(tonumber(arg0) == 20150526 ) then
			local id = Get_XParam_INT(0)
			g_JieBaiZFSJ_CaredNpc = DataPool:GetNPCIDByServerID(id)
			if g_JieBaiZFSJ_CaredNpc == -1 then
				PushDebugMessage("server传过来的数据有问题。")
				return
			end			
			JieBaiZFSJ_SetData()
			JieBaiZFSJ_BeginCareObject_Update()
			this:Show()
		end
	elseif (event == "ADJEST_UI_POS") or (event == "VIEW_RESOLUTION_CHANGED") then
		JieBaiZFSJ_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if (tonumber(arg0) ~= g_JieBaiZFSJ_CaredNpc) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE) or arg1=="destroy") then
			this:Hide()
		end	
	
	end
end

function JieBaiZFSJ_SetData()
	local temp1,temp2,temp3,temp4 = Player:GetData("ZHENFAINFO")
	local zhenfainfo = {temp1,temp2,temp3,temp4}
	
	for i =1, 4 do
		g_JieBaiZFSJ_Text[i]:SetText(JieBaiZFSJ_DecoZhenFaDesc(zhenfainfo[i]))
	end
	
	JieBaiZFSJ_UpdataSkill()
end

function JieBaiZFSJ_DecoZhenFaInfo(info)
	advance = math.floor(info/1000)
	level = math.mod(info,1000)
	return level, advance
end
function JieBaiZFSJ_UpdataSkill()

	local temp1,temp2,temp3,temp4 = Player:GetData("ZHENFAINFO")
	local zhenfainfo = {temp1,temp2,temp3,temp4}
	for i = 1, 4 do
		local level = JieBaiZFSJ_DecoZhenFaInfo(zhenfainfo[i])
		if level == 0 then
			for i = 1, table.getn(g_JieBaiZFSJ_Skill) do
				local thetempAction = EnumAction(g_JieBaiZFSJ_Skill[i], "zhenfaskill");
				if thetempAction ~= nil then
					g_JieBaiZFSJ_ActionButton[i] : SetActionItem(thetempAction : GetID())
					
				end		
			end
		end
	end

	local nSumSkill = GetActionNum("skill");
	for i = 1, nSumSkill do
		local thetempAction = EnumAction(i, "skill");
		local temp = thetempAction:GetID();
		local nCommonId = LifeAbility : GetLifeAbility_Number(temp);
		if nCommonId ~=nil and nCommonId > 0 then
		
			for i = 1, 4 do
				if g_JieBaiZFSJ_Skill[i] == nCommonId then
					g_JieBaiZFSJ_ActionButton[i] : SetActionItem(thetempAction : GetID())
				end
			end			
		end
	end
	

end

function JieBaiZFSJ_DecoZhenFaDesc(info)
	advance  = math.floor(tonumber(info)/1000)
	level	 = math.mod(tonumber(info),1000)
	if level == 100 then
		return "#{JBGXW_150526_145}"
	else
		return advance.."阶"..(level-advance*10).."级"
	end
end


function JieBaiZFSJ_ResetPos()
	JieBaiZFSJ_Frame:SetProperty("UnifiedPosition",g_JieBaiZFSJ_UnifiedPosition)
end


function JieBaiZFSJ_acceptMis(nIndex)

		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientAcceptMission");
			Set_XSCRIPT_ScriptID(891175);
			Set_XSCRIPT_Parameter(0,tonumber(nIndex));
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();	
end

function JieBaiZFSJ_Close()
	JieBaiZFSJ_StopCareObject_Update()
	this:Hide()
end

function JieBaiZFSJ_BeginCareObject_Update()
	this:CareObject(g_JieBaiZFSJ_CaredNpc,1, "JieBaiZFSJ")
end

function JieBaiZFSJ_StopCareObject_Update()
	this:CareObject(g_JieBaiZFSJ_CaredNpc,0, "JieBaiZFSJ")
	g_JieBaiZFSJ_CaredNpc = -1
end
