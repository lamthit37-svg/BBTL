----------------------
-- TournamentList ---
----------------------
local MAX_OBJ_DISTANCE = 3.0;

local ZHENGBA_NPC_ID = -1;
local objCared = -1

local g_NewTournamentList_Frame_UnifiedPosition

local g_zhengBaPic = {
												"set:NewTournamentList image:NewTournamentList_1",
												"set:NewTournamentList image:NewTournamentList_2",
												"set:NewTournamentList image:NewTournamentList_3",
											
											}
											
local g_ZhengBaSaiName = {
										
													"#{ZRGJ_251106_02}",
													"#{ZRGJ_251106_04}",
													"#{ZRGJ_251106_06}",

												}
											
local g_ZhengBaSaiInfo = {
	--2023年争霸赛
	[1] = {
					[1] ={name ="#{ZRGJ_251106_10}",meipai = "#{ZRGJ_251106_17}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_25}",team ="#{ZRGJ_251106_27}"},
					[2] ={name ="#{ZRGJ_251106_11}",meipai = "#{ZRGJ_251106_18}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_25}",team ="#{ZRGJ_251106_27}"},
					[3] ={name ="#{ZRGJ_251106_12}",meipai = "#{ZRGJ_251106_17}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_25}",team ="#{ZRGJ_251106_27}"},
					[4] ={name ="#{ZRGJ_251106_13}",meipai = "#{ZRGJ_251106_19}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_25}",team ="#{ZRGJ_251106_27}"},
					[5] ={name ="#{ZRGJ_251106_14}",meipai = "#{ZRGJ_251106_20}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_25}",team ="#{ZRGJ_251106_27}"},
					[6] ={name ="#{ZRGJ_251106_15}",meipai = "#{ZRGJ_251106_21}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_25}",team ="#{ZRGJ_251106_27}"},
	
				},
	--2024年争霸赛			
	[2] = {
					[1] ={name ="#{ZRGJ_251106_29}",meipai = "#{ZRGJ_251106_18}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_44}",team ="#{ZRGJ_251106_45}"},
					[2] ={name ="#{ZRGJ_251106_40}",meipai = "#{ZRGJ_251106_31}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_44}",team ="#{ZRGJ_251106_45}"},
					[3] ={name ="#{ZRGJ_251106_41}",meipai = "#{ZRGJ_251106_31}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_44}",team ="#{ZRGJ_251106_45}"},
					[4] ={name ="#{ZRGJ_251106_42}",meipai = "#{ZRGJ_251106_19}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_44}",team ="#{ZRGJ_251106_45}"},
					[5] ={name ="#{ZRGJ_251106_43}",meipai = "#{ZRGJ_251106_19}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_44}",team ="#{ZRGJ_251106_45}"},
					[6] ={name ="#{ZRGJ_251106_30}",meipai = "#{ZRGJ_251106_17}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_44}",team ="#{ZRGJ_251106_45}"},
			
				},
				
	--2025年争霸赛				
	[3] = {
					[1] ={name ="#{ZRGJ_251106_32}",meipai = "#{ZRGJ_251106_31}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_38}",team ="#{ZRGJ_251106_39}"},
					[2] ={name ="#{ZRGJ_251106_33}",meipai = "#{ZRGJ_251106_31}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_38}",team ="#{ZRGJ_251106_39}"},
					[3] ={name ="#{ZRGJ_251106_34}",meipai = "#{ZRGJ_251106_19}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_38}",team ="#{ZRGJ_251106_39}"},
					[4] ={name ="#{ZRGJ_251106_35}",meipai = "#{ZRGJ_251106_19}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_38}",team ="#{ZRGJ_251106_39}"},
					[5] ={name ="#{ZRGJ_251106_36}",meipai = "#{ZRGJ_251106_18}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_38}",team ="#{ZRGJ_251106_39}"},
					[6] ={name ="#{ZRGJ_251106_37}",meipai = "#{ZRGJ_251106_17}",level = "#{ZRGJ_251106_23}", zone ="#{ZRGJ_251106_38}",team ="#{ZRGJ_251106_39}"},

				},
}


--===============================================
-- PreLoad()
--===============================================
function NewTournamentList_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	
end

--===============================================
-- OnLoad()
--===============================================
function NewTournamentList_OnLoad()
	
end

--===============================================
-- OnEvent()
--===============================================
function NewTournamentList_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 89002402) then
		ZHENGBA_NPC_ID = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(ZHENGBA_NPC_ID);
		BeginCareObject_NewTournamentList(objCared)
		this:Show()
		NewTournamentList_Frame_Button3:SetCheck(1)
		NewTournamentList_GunJun(3)
		
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
				--取消关心
			NewTournamentList_Cancel_Clicked()
		end
	end
	
end

function BeginCareObject_NewTournamentList(objCaredId)
	this:CareObject(objCaredId, 1, "NewTournamentList");
end


function ActionSkillsStudy_Close_Cilcked()
	this:Hide()
	--取消关心
	this:CareObject(objCared, 0, "ActionSkillsStudy");

end

--===============================================
-- Cancel_Clicked
--===============================================
function NewTournamentList_GunJun( index )
	
	if index > 3 or index < 1 then
		return
	end
	
	NewTournamentList_Frame_Info_Tu : SetProperty("Image", g_zhengBaPic[index])	--选择不同图片
	NewTournamentList_Frame_ContentListName : SetText(g_ZhengBaSaiName[index])
	
	NewTournamentList_Frame_ContentList:RemoveAllItem()
	
	local m_ActInd = 0
	
	 
	for i = 1, table.getn( g_ZhengBaSaiInfo[index] ) do
		
		NewTournamentList_Frame_ContentList:AddNewItem(g_ZhengBaSaiInfo[index][i].name, 0 , m_ActInd)
		NewTournamentList_Frame_ContentList:AddNewItem(g_ZhengBaSaiInfo[index][i].meipai, 1 , m_ActInd)
		NewTournamentList_Frame_ContentList:AddNewItem(g_ZhengBaSaiInfo[index][i].level, 2 , m_ActInd)
		NewTournamentList_Frame_ContentList:AddNewItem(g_ZhengBaSaiInfo[index][i].zone, 3 , m_ActInd)
		NewTournamentList_Frame_ContentList:AddNewItem(g_ZhengBaSaiInfo[index][i].team, 4 , m_ActInd)
		m_ActInd = m_ActInd + 1
	end
	
	return;
end

function NewTournamentList_ResetPos()
	NewTournamentList_Frame:SetProperty("UnifiedPosition",g_NewTournamentList_Frame_UnifiedPosition)
end

--===============================================
-- Close()
--===============================================
function NewTournamentList_Close()

	return this:Hide()
end

function NewTournamentList_OnHiden()
		return this:Hide()
end

--帮助
function NewTournamentList_Help_Clicked()
end