----------------------
-- TournamentList ---
----------------------
local MAX_OBJ_DISTANCE = 3.0;

local ZHENGBA_NPC_ID = -1;
local objCared = -1


local g_zhengBaPic = {
												"set:TournamentList01 image:TournamentList_BK1",
												"set:TournamentList01 image:TournamentList_BK2",
												"set:TournamentList02 image:TournamentList_BK3",
												"set:TournamentList02 image:TournamentList_BK4",
												"set:TournamentList03 image:TournamentList_BK5",
												"set:TournamentList04 image:TournamentList_BK6",
												"set:TournamentList04 image:TournamentList_BK7",
												"set:TournamentList03 image:TournamentList_BK6",
											
											}
											
local g_ZhengBaSaiName = {
										
													"#{ZBSZRB_160816_12}",
													"#{ZBSZRB_160816_33}",
													"#{ZBSZRB_160816_34}",
													"#{ZBSZRB_160816_48}",
													"#{ZBSZRB_160816_55}",
													"#{ZBSZRB_160816_73}",
													"#{ZBSZRB_170930_95}",
													"#{ZBSZRB_171002_110}",
												}
											
local g_ZhengBaSaiInfo = {
	--2011年争霸赛
	[1] = {
					[1] ={name ="#{ZBSZRB_160816_13}",meipai = "#{ZBSZRB_160816_14}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_16}",team =""},
	
				},
	--2012年争霸赛			
	[2] = {
					[1] ={name ="#{ZBSZRB_160816_17}",meipai = "#{ZBSZRB_160816_18}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_19}",team ="#{ZBSZRB_160816_20}"},
					[2] ={name ="#{ZBSZRB_160816_21}",meipai = "#{ZBSZRB_160816_22}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_19}",team ="#{ZBSZRB_160816_20}"},
					[3] ={name ="#{ZBSZRB_160816_23}",meipai = "#{ZBSZRB_160816_24}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_19}",team ="#{ZBSZRB_160816_20}"},
					[4] ={name ="#{ZBSZRB_160816_25}",meipai = "#{ZBSZRB_160816_26}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_19}",team ="#{ZBSZRB_160816_20}"},
					[5] ={name ="#{ZBSZRB_160816_27}",meipai = "#{ZBSZRB_160816_28}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_19}",team ="#{ZBSZRB_160816_20}"},
					[6] ={name ="#{ZBSZRB_160816_29}",meipai = "#{ZBSZRB_160816_30}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_19}",team ="#{ZBSZRB_160816_20}"},
					[7] ={name ="#{ZBSZRB_160816_31}",meipai = "#{ZBSZRB_160816_30}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_19}",team ="#{ZBSZRB_160816_20}"},
					[8] ={name ="#{ZBSZRB_160816_32}",meipai = "#{ZBSZRB_160816_28}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_19}",team ="#{ZBSZRB_160816_20}"},
			
				},
				
	--2013年争霸赛				
	[3] = {
					[1] ={name ="#{ZBSZRB_160816_35}",meipai = "#{ZBSZRB_160816_30}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[2] ={name ="#{ZBSZRB_160816_38}",meipai = "#{ZBSZRB_160816_39}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[3] ={name ="#{ZBSZRB_160816_40}",meipai = "#{ZBSZRB_160816_22}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[4] ={name ="#{ZBSZRB_160816_41}",meipai = "#{ZBSZRB_160816_42}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[5] ={name ="#{ZBSZRB_160816_43}",meipai = "#{ZBSZRB_160816_26}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[6] ={name ="#{ZBSZRB_160816_44}",meipai = "#{ZBSZRB_160816_28}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[7] ={name ="#{ZBSZRB_160816_45}",meipai = "#{ZBSZRB_160816_47}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[8] ={name ="#{ZBSZRB_160816_46}",meipai = "#{ZBSZRB_160816_24}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
				}
				,
				
	--2014年争霸赛	
	[4] = {
					[1] ={name ="#{ZBSZRB_160816_43}",meipai = "#{ZBSZRB_160816_26}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[2] ={name ="#{ZBSZRB_160816_49}",meipai = "#{ZBSZRB_160816_22}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[3] ={name ="#{ZBSZRB_160816_35}",meipai = "#{ZBSZRB_160816_30}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[4] ={name ="#{ZBSZRB_160816_50}",meipai = "#{ZBSZRB_160816_39}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[5] ={name ="#{ZBSZRB_160816_51}",meipai = "#{ZBSZRB_160816_30}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[6] ={name ="#{ZBSZRB_160816_52}",meipai = "#{ZBSZRB_160816_24}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[7] ={name ="#{ZBSZRB_160816_53}",meipai = "#{ZBSZRB_160816_47}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},
					[8] ={name ="#{ZBSZRB_160816_54}",meipai = "#{ZBSZRB_160816_42}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_36}",team ="#{ZBSZRB_160816_37}"},	
				},
	--2015年争霸赛				
	[5] = {
					[1] ={name ="#{ZBSZRB_160816_56}",meipai = "#{ZBSZRB_160816_42}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_64}",team ="#{ZBSZRB_160816_65}"},
					[2] ={name ="#{ZBSZRB_160816_57}",meipai = "#{ZBSZRB_160816_24}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_64}",team ="#{ZBSZRB_160816_65}"},
					[3] ={name ="#{ZBSZRB_160816_58}",meipai = "#{ZBSZRB_160816_47}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_64}",team ="#{ZBSZRB_160816_65}"},
					[4] ={name ="#{ZBSZRB_160816_59}",meipai = "#{ZBSZRB_160816_30}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_64}",team ="#{ZBSZRB_160816_65}"},
					[5] ={name ="#{ZBSZRB_160816_60}",meipai = "#{ZBSZRB_160816_24}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_64}",team ="#{ZBSZRB_160816_65}"},
					[6] ={name ="#{ZBSZRB_160816_61}",meipai = "#{ZBSZRB_160816_28}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_64}",team ="#{ZBSZRB_160816_65}"},
					[7] ={name ="#{ZBSZRB_160816_62}",meipai = "#{ZBSZRB_160816_39}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_64}",team ="#{ZBSZRB_160816_65}"},
					[8] ={name ="#{ZBSZRB_160816_63}",meipai = "#{ZBSZRB_160816_22}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_64}",team ="#{ZBSZRB_160816_65}"},
				},
	--2016年争霸赛				
	[6] = {
					[1] ={name ="#{ZBSZRB_160816_74}",meipai = "#{ZBSZRB_160816_84}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_91}",team ="#{ZBSZRB_160816_92}"},
					[2] ={name ="#{ZBSZRB_160816_75}",meipai = "#{ZBSZRB_160816_85}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_91}",team ="#{ZBSZRB_160816_92}"},
					[3] ={name ="#{ZBSZRB_160816_76}",meipai = "#{ZBSZRB_160816_47}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_91}",team ="#{ZBSZRB_160816_92}"},
					[4] ={name ="#{ZBSZRB_160816_77}",meipai = "#{ZBSZRB_160816_88}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_91}",team ="#{ZBSZRB_160816_92}"},
					[5] ={name ="#{ZBSZRB_160816_78}",meipai = "#{ZBSZRB_160816_86}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_91}",team ="#{ZBSZRB_160816_92}"},
					[6] ={name ="#{ZBSZRB_160816_79}",meipai = "#{ZBSZRB_160816_88}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_91}",team ="#{ZBSZRB_160816_92}"},
					[7] ={name ="#{ZBSZRB_160816_80}",meipai = "#{ZBSZRB_160816_84}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_91}",team ="#{ZBSZRB_160816_92}"},
					[8] ={name ="#{ZBSZRB_160816_81}",meipai = "#{ZBSZRB_160816_86}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_91}",team ="#{ZBSZRB_160816_92}"},
					[9] ={name ="#{ZBSZRB_160816_82}",meipai = "#{ZBSZRB_160816_89}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_91}",team ="#{ZBSZRB_160816_92}"},
					[10] ={name ="#{ZBSZRB_160816_83}",meipai = "#{ZBSZRB_160816_89}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_160816_91}",team ="#{ZBSZRB_160816_92}"},
				},
	--2017年争霸赛				
	[7] = {
					[1] ={name ="#{ZBSZRB_170930_96}",meipai = "#{ZBSZRB_160816_90}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_107}"},
					[2] ={name ="#{ZBSZRB_170930_97}",meipai = "#{ZBSZRB_160816_88}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_107}"},
					[3] ={name ="#{ZBSZRB_170930_98}",meipai = "#{ZBSZRB_160816_88}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_107}"},
					[4] ={name ="#{ZBSZRB_170930_99}",meipai = "#{ZBSZRB_160816_86}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_107}"},
					[5] ={name ="#{ZBSZRB_170930_100}",meipai = "#{ZBSZRB_160816_89}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_107}"},
					[6] ={name ="#{ZBSZRB_170930_101}",meipai = "#{ZBSZRB_160816_85}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_107}"},
					[7] ={name ="#{ZBSZRB_170930_102}",meipai = "#{ZBSZRB_160816_86}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_107}"},
					[8] ={name ="#{ZBSZRB_170930_103}",meipai = "#{ZBSZRB_160816_89}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_107}"},
					[9] ={name ="#{ZBSZRB_170930_104}",meipai = "#{ZBSZRB_160816_84}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_107}"},
					[10] ={name ="#{ZBSZRB_170930_105}",meipai = "#{ZBSZRB_160816_26}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_107}"},
				},
	--2018年争霸赛				
	[8] = {
					[1] ={name ="#{ZBSZRB_171002_111}",meipai = "#{ZBSZRB_160816_90}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_121}"},
					[2] ={name ="#{ZBSZRB_171002_112}",meipai = "#{ZBSZRB_160816_88}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_121}"},
					[3] ={name ="#{ZBSZRB_171002_113}",meipai = "#{ZBSZRB_160816_89}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_121}"},
					[4] ={name ="#{ZBSZRB_171002_114}",meipai = "#{ZBSZRB_160816_88}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_121}"},
					[5] ={name ="#{ZBSZRB_171002_115}",meipai = "#{MPZH_180719_13}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_121}"},
					[6] ={name ="#{ZBSZRB_171002_116}",meipai = "#{ZBSZRB_160816_86}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_121}"},
					[7] ={name ="#{ZBSZRB_171002_117}",meipai = "#{ZBSZRB_160816_84}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_121}"},
					[8] ={name ="#{ZBSZRB_171002_118}",meipai = "#{ZBSZRB_160816_84}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_121}"},
					[9] ={name ="#{ZBSZRB_171002_119}",meipai = "#{ZBSZRB_160816_86}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_121}"},
					[10] ={name ="#{ZBSZRB_171002_120}",meipai = "#{ZBSZRB_160816_89}",level = "#{ZBSZRB_160816_15}", zone ="#{ZBSZRB_171002_106}",team ="#{ZBSZRB_171002_121}"},
				},
}


--===============================================
-- PreLoad()
--===============================================
function TournamentList_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	
end

--===============================================
-- OnLoad()
--===============================================
function TournamentList_OnLoad()
	
end

--===============================================
-- OnEvent()
--===============================================
function TournamentList_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 20160816) then
		ZHENGBA_NPC_ID = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(ZHENGBA_NPC_ID);
		BeginCareObject_TournamentList(objCared)
		this:Show()
		TournamentList_Frame_Button8:SetCheck(1)
		TournamentList_GunJun(8)
		
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
				--取消关心
			TournamentList_Cancel_Clicked()
		end
	end
	
end

function BeginCareObject_TournamentList(objCaredId)
	this:CareObject(objCaredId, 1, "TournamentList");
end

--===============================================
-- Cancel_Clicked
--===============================================
function TournamentList_GunJun( index )
	
	if index > 8 or index < 1 then
		return
	end
	
	TournamentList_Frame_Info_Tu : SetProperty("Image", g_zhengBaPic[index])	--选择不同图片
	TournamentList_Frame_ContentListName : SetText(g_ZhengBaSaiName[index])
	
	TournamentList_Frame_ContentList:RemoveAllItem()
	
	local m_ActInd = 0
	
	 
	for i = 1, table.getn( g_ZhengBaSaiInfo[index] ) do
		
		TournamentList_Frame_ContentList:AddNewItem(g_ZhengBaSaiInfo[index][i].name, 0 , m_ActInd)
		TournamentList_Frame_ContentList:AddNewItem(g_ZhengBaSaiInfo[index][i].meipai, 1 , m_ActInd)
		TournamentList_Frame_ContentList:AddNewItem(g_ZhengBaSaiInfo[index][i].level, 2 , m_ActInd)
		TournamentList_Frame_ContentList:AddNewItem(g_ZhengBaSaiInfo[index][i].zone, 3 , m_ActInd)
		TournamentList_Frame_ContentList:AddNewItem(g_ZhengBaSaiInfo[index][i].team, 4 , m_ActInd)
		m_ActInd = m_ActInd + 1
	end
	
	return;
end

function TournamentList_ResetPos()
	TournamentList_Frame:SetProperty("UnifiedPosition",g_TournamentList_Frame_UnifiedPosition)
end

--===============================================
-- Close()
--===============================================
function TournamentList_Close()

	return this:Hide()
end

function TournamentList_OnHiden()
		return this:Hide()
end



--帮助
function TournamentList_Help_Clicked()
end