local g_Frame_UnifiedPosition = nil
local g_Index = -1
local g_CheckRoom = -1
local g_Timer = -1
local g_Step = 0
local g_NowBossX = -1
local g_NowBossZ = -1

local g_GameItemImage = {
	[1] = "set:ZhouchangPVE1 image:ZhouchangPVE_ZBF",
	[2] = "set:ZhouchangPVE1 image:ZhouchangPVE_ZBS",
	[3] = "set:ZhouchangPVE1 image:ZhouchangPVE_SSL",
}
local g_GameItemText = {
	[1] = "#{FHCL_240708_202}",
	[2] = "#{FHCL_240708_203}",
	[3] = "#{FHCL_240708_204}",
}

local g_EventImage = {
	[0] = "set:ZhouchangPVE2 image:ZhouchangPVE_Start",
	[1] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Glgz",
	[2] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Fhqz",
	[3] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Dlgh",
	[4] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Yzzj",
	[5] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Amwj",
	[6] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Yrfd",
	[7] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Dsd",
	[8] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Dpfhz",
	[9] = "set:ZhouchangPVE1 image:ZhouchangPVE_Boss",
	[10] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Sydb",
	
}

local g_EventFinshImage = {
	
	
	[1] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Glgz_Select",
	[2] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Fhqz_Select",
	[3] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Dlgh_Select",
	[4] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Yzzj_Select",
	[5] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Amwj_Select",
	[6] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Yrfd_Select",
	[7] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Dsd_Select",
	[8] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Dpfhz_Select",
	[9] = "set:ZhouchangPVE1 image:ZhouchangPVE_Boss_Select",
	[10] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Sydb_Select",
	
}

local g_EventHighLightImage = {
	
	
	[1] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Glgz_Hover",
	[2] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Fhqz_Hover",
	[3] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Dlgh_Hover",
	[4] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Yzzj_Hover",
	[5] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Amwj_Hover",
	[6] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Yrfd_Hover",
	[7] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Dsd_Hover",
	[8] = "set:ZhouchangPVE2 image:ZhouchangPVE_Active_Dpfhz_Hover",
	[9] = "set:ZhouchangPVE1 image:ZhouchangPVE_Boss_Hover",
	[10] = "set:ZhouchangPVE1 image:ZhouchangPVE_Active_Sydb_Hover",
	
}
local g_BossImage = {
	
	[1] = "set:ZhouchangPVE1 image:ZhouchangPVE_Boss",
	[2] = "set:ZhouchangPVE1 image:ZhouchangPVE_Boss_Lock",
	[3] = "set:ZhouchangPVE1 image:ZhouchangPVE_Boss_Select",
	[4] = "set:ZhouchangPVE1 image:ZhouchangPVE_Boss_Zhibu", --滞步的图
	[5] = "set:ZhouchangPVE1 image:ZhouchangPVE_Boss_Zhixing", --止行的图
	
}
local g_FuBenType = {	
	[1] = 0, --金币
	[2] = 0, --五行
	[3] = 1, --boos1
	[4] = 1, --boos2
	[5] = 1, --boos3
	[6] = 0, --金币
	[7] = 0, --金币
	[8] = 0, --金币
	[9] = 1, --最终boss
	[10] = 1, --霜影
}

local g_PosIndex = {
	[1] = {x=1,z=1},
	[2] = {x=1,z=2},
	[3] = {x=1,z=3},
	[4] = {x=1,z=4},
	[5] = {x=1,z=5},
	[6] = {x=1,z=6},
	
	[7] = {x=2,z=1},
	[8] = {x=2,z=2},
	[9] = {x=2,z=3},
	[10] = {x=2,z=4},
	[11] = {x=2,z=5},
	[12] = {x=2,z=6},
	
	[13] = {x=3,z=1},
	[14] = {x=3,z=2},
	[15] = {x=3,z=3},
	[16] = {x=3,z=4},
	[17] = {x=3,z=5},
	[18] = {x=3,z=6},
	
	[19] = {x=4,z=1},
	[20] = {x=4,z=2},
	[21] = {x=4,z=3},
	[22] = {x=4,z=4},
	[23] = {x=4,z=5},
	[24] = {x=4,z=6},
	
	[25] = {x=5,z=1},
	[26] = {x=5,z=2},
	[27] = {x=5,z=3},
	[28] = {x=5,z=4},
	[29] = {x=5,z=5},
	[30] = {x=5,z=6},
}

local g_BossUIPos = {
	[1] = {[1] = {x=87, z=8}, [2] = {x=219, z=8}, [3] = {x=350, z=8}, [4] = {x=482, z=8}, [5] = {x=615, z=8}, [6] = {x=747, z=8}},
	[2] = {[1] = {x=87, z=120}, [2] = {x=219, z=120}, [3] = {x=350, z=120}, [4] = {x=482, z=120}, [5] = {x=615, z=120}, [6] = {x=747, z=120}},
	[3] = {[1] = {x=87, z=232}, [2] = {x=219, z=232}, [3] = {x=350, z=232}, [4] = {x=482, z=232}, [5] = {x=615, z=232}, [6] = {x=747, z=232}},
	[4] = {[1] = {x=87, z=343}, [2] = {x=219, z=343}, [3] = {x=350, z=343}, [4] = {x=482, z=343}, [5] = {x=615, z=343}, [6] = {x=747, z=343}},
	[5] = {[1] = {x=87, z=457}, [2] = {x=219, z=457}, [3] = {x=350, z=457}, [4] = {x=482, z=457}, [5] = {x=615, z=457}, [6] = {x=747, z=457}},	
}


local g_EventTips = {
	[1] = "#{FHCL_240708_194}",
	[2] = "#{FHCL_240708_195}",
	[3] = "#{FHCL_240708_199}",
	[4] = "#{FHCL_240708_200}",
	[5] = "#{FHCL_240708_201}",
	[6] = "#{FHCL_240708_196}",
	[7] = "#{FHCL_240708_197}",
	[8] = "#{FHCL_240708_198}",
}
local g_StartArea = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
}
-- local g_Boss = {
	-- [1] = {},
	-- [2] = {},
	-- [3] = {},
	-- [4] = {},
	-- [5] = {},
-- }
local g_UnActive = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	}
local g_Active = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	}
local g_FinshRoom = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	}
local g_CanEnterRoom = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	}
local g_Team = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	}
local g_Self = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	}
local g_GameItem = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	}
	
local g_RoomItem = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	}
	
local g_CheckItem = {
	[1] = {},
	[2] = {},
	[3] = {},
	[4] = {},
	[5] = {},
	}
local g_Row = 5
local g_Col = 6
local g_BossMoveStep = 2
--=========
-- PreLoad()
--=========
function ZhouchangPVE_SceneFb_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--	
	this:RegisterEvent("OPEN_WEEKPVEMAP", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function ZhouchangPVE_SceneFb_OnLoad()
	g_Timer = 10
	g_Step = 0
	g_NowBossX = -1
	g_NowBossZ = -1
	g_Frame_UnifiedPosition = ZhouchangPVE_SceneFb_Frame:GetProperty("UnifiedPosition")
	g_StartArea[1][1] = ZhouchangPVE_SceneFb_Room1_Start
	g_StartArea[1][2] = ZhouchangPVE_SceneFb_Room2_Start
	g_StartArea[1][3] = ZhouchangPVE_SceneFb_Room3_Start
	g_StartArea[1][4] = ZhouchangPVE_SceneFb_Room4_Start
	g_StartArea[1][5] = ZhouchangPVE_SceneFb_Room5_Start
	g_StartArea[1][6] = ZhouchangPVE_SceneFb_Room6_Start
	g_StartArea[2][1] = ZhouchangPVE_SceneFb_Room7_Start
	g_StartArea[2][2] = ZhouchangPVE_SceneFb_Room8_Start
	g_StartArea[2][3] = ZhouchangPVE_SceneFb_Room9_Start
	g_StartArea[2][4] = ZhouchangPVE_SceneFb_Room10_Start
	g_StartArea[2][5] = ZhouchangPVE_SceneFb_Room11_Start
	g_StartArea[2][6] = ZhouchangPVE_SceneFb_Room12_Start
	g_StartArea[3][1] = ZhouchangPVE_SceneFb_Room13_Start
	g_StartArea[3][2] = ZhouchangPVE_SceneFb_Room14_Start
	g_StartArea[3][3] = ZhouchangPVE_SceneFb_Room15_Start
	g_StartArea[3][4] = ZhouchangPVE_SceneFb_Room16_Start
	g_StartArea[3][5] = ZhouchangPVE_SceneFb_Room17_Start
	g_StartArea[3][6] = ZhouchangPVE_SceneFb_Room18_Start
	g_StartArea[4][1] = ZhouchangPVE_SceneFb_Room19_Start
	g_StartArea[4][2] = ZhouchangPVE_SceneFb_Room20_Start
	g_StartArea[4][3] = ZhouchangPVE_SceneFb_Room21_Start
	g_StartArea[4][4] = ZhouchangPVE_SceneFb_Room22_Start
	g_StartArea[4][5] = ZhouchangPVE_SceneFb_Room23_Start
	g_StartArea[4][6] = ZhouchangPVE_SceneFb_Room24_Start
	g_StartArea[5][1] = ZhouchangPVE_SceneFb_Room25_Start
	g_StartArea[5][2] = ZhouchangPVE_SceneFb_Room26_Start
	g_StartArea[5][3] = ZhouchangPVE_SceneFb_Room27_Start
	g_StartArea[5][4] = ZhouchangPVE_SceneFb_Room28_Start
	g_StartArea[5][5] = ZhouchangPVE_SceneFb_Room29_Start
	g_StartArea[5][6] = ZhouchangPVE_SceneFb_Room30_Start

	
	g_UnActive[1][1] = ZhouchangPVE_SceneFb_Room1_UnActive
	g_UnActive[1][2] = ZhouchangPVE_SceneFb_Room2_UnActive
	g_UnActive[1][3] = ZhouchangPVE_SceneFb_Room3_UnActive
	g_UnActive[1][4] = ZhouchangPVE_SceneFb_Room4_UnActive
	g_UnActive[1][5] = ZhouchangPVE_SceneFb_Room5_UnActive
	g_UnActive[1][6] = ZhouchangPVE_SceneFb_Room6_UnActive
	g_UnActive[2][1] = ZhouchangPVE_SceneFb_Room7_UnActive
	g_UnActive[2][2] = ZhouchangPVE_SceneFb_Room8_UnActive
	g_UnActive[2][3] = ZhouchangPVE_SceneFb_Room9_UnActive
	g_UnActive[2][4] = ZhouchangPVE_SceneFb_Room10_UnActive
	g_UnActive[2][5] = ZhouchangPVE_SceneFb_Room11_UnActive
	g_UnActive[2][6] = ZhouchangPVE_SceneFb_Room12_UnActive
	g_UnActive[3][1] = ZhouchangPVE_SceneFb_Room13_UnActive
	g_UnActive[3][2] = ZhouchangPVE_SceneFb_Room14_UnActive
	g_UnActive[3][3] = ZhouchangPVE_SceneFb_Room15_UnActive
	g_UnActive[3][4] = ZhouchangPVE_SceneFb_Room16_UnActive
	g_UnActive[3][5] = ZhouchangPVE_SceneFb_Room17_UnActive
	g_UnActive[3][6] = ZhouchangPVE_SceneFb_Room18_UnActive
	g_UnActive[4][1] = ZhouchangPVE_SceneFb_Room19_UnActive
	g_UnActive[4][2] = ZhouchangPVE_SceneFb_Room20_UnActive
	g_UnActive[4][3] = ZhouchangPVE_SceneFb_Room21_UnActive
	g_UnActive[4][4] = ZhouchangPVE_SceneFb_Room22_UnActive
	g_UnActive[4][5] = ZhouchangPVE_SceneFb_Room23_UnActive
	g_UnActive[4][6] = ZhouchangPVE_SceneFb_Room24_UnActive
	g_UnActive[5][1] = ZhouchangPVE_SceneFb_Room25_UnActive
	g_UnActive[5][2] = ZhouchangPVE_SceneFb_Room26_UnActive
	g_UnActive[5][3] = ZhouchangPVE_SceneFb_Room27_UnActive
	g_UnActive[5][4] = ZhouchangPVE_SceneFb_Room28_UnActive
	g_UnActive[5][5] = ZhouchangPVE_SceneFb_Room29_UnActive
	g_UnActive[5][6] = ZhouchangPVE_SceneFb_Room30_UnActive
	
	g_Active[1][1] = ZhouchangPVE_SceneFb_Room1_Active
	g_Active[1][2] = ZhouchangPVE_SceneFb_Room2_Active
	g_Active[1][3] = ZhouchangPVE_SceneFb_Room3_Active
	g_Active[1][4] = ZhouchangPVE_SceneFb_Room4_Active
	g_Active[1][5] = ZhouchangPVE_SceneFb_Room5_Active
	g_Active[1][6] = ZhouchangPVE_SceneFb_Room6_Active
	g_Active[2][1] = ZhouchangPVE_SceneFb_Room7_Active
	g_Active[2][2] = ZhouchangPVE_SceneFb_Room8_Active
	g_Active[2][3] = ZhouchangPVE_SceneFb_Room9_Active
	g_Active[2][4] = ZhouchangPVE_SceneFb_Room10_Active
	g_Active[2][5] = ZhouchangPVE_SceneFb_Room11_Active
	g_Active[2][6] = ZhouchangPVE_SceneFb_Room12_Active
	g_Active[3][1] = ZhouchangPVE_SceneFb_Room13_Active
	g_Active[3][2] = ZhouchangPVE_SceneFb_Room14_Active
	g_Active[3][3] = ZhouchangPVE_SceneFb_Room15_Active
	g_Active[3][4] = ZhouchangPVE_SceneFb_Room16_Active
	g_Active[3][5] = ZhouchangPVE_SceneFb_Room17_Active
	g_Active[3][6] = ZhouchangPVE_SceneFb_Room18_Active
	g_Active[4][1] = ZhouchangPVE_SceneFb_Room19_Active
	g_Active[4][2] = ZhouchangPVE_SceneFb_Room20_Active
	g_Active[4][3] = ZhouchangPVE_SceneFb_Room21_Active
	g_Active[4][4] = ZhouchangPVE_SceneFb_Room22_Active
	g_Active[4][5] = ZhouchangPVE_SceneFb_Room23_Active
	g_Active[4][6] = ZhouchangPVE_SceneFb_Room24_Active
	g_Active[5][1] = ZhouchangPVE_SceneFb_Room25_Active
	g_Active[5][2] = ZhouchangPVE_SceneFb_Room26_Active
	g_Active[5][3] = ZhouchangPVE_SceneFb_Room27_Active
	g_Active[5][4] = ZhouchangPVE_SceneFb_Room28_Active
	g_Active[5][5] = ZhouchangPVE_SceneFb_Room29_Active
	g_Active[5][6] = ZhouchangPVE_SceneFb_Room30_Active
	
	g_FinshRoom[1][1] = ZhouchangPVE_SceneFb_Room1_Select
	g_FinshRoom[1][2] = ZhouchangPVE_SceneFb_Room2_Select
	g_FinshRoom[1][3] = ZhouchangPVE_SceneFb_Room3_Select
	g_FinshRoom[1][4] = ZhouchangPVE_SceneFb_Room4_Select
	g_FinshRoom[1][5] = ZhouchangPVE_SceneFb_Room5_Select
	g_FinshRoom[1][6] = ZhouchangPVE_SceneFb_Room6_Select
	g_FinshRoom[2][1] = ZhouchangPVE_SceneFb_Room7_Select
	g_FinshRoom[2][2] = ZhouchangPVE_SceneFb_Room8_Select
	g_FinshRoom[2][3] = ZhouchangPVE_SceneFb_Room9_Select
	g_FinshRoom[2][4] = ZhouchangPVE_SceneFb_Room10_Select
	g_FinshRoom[2][5] = ZhouchangPVE_SceneFb_Room11_Select
	g_FinshRoom[2][6] = ZhouchangPVE_SceneFb_Room12_Select
	g_FinshRoom[3][1] = ZhouchangPVE_SceneFb_Room13_Select
	g_FinshRoom[3][2] = ZhouchangPVE_SceneFb_Room14_Select
	g_FinshRoom[3][3] = ZhouchangPVE_SceneFb_Room15_Select
	g_FinshRoom[3][4] = ZhouchangPVE_SceneFb_Room16_Select
	g_FinshRoom[3][5] = ZhouchangPVE_SceneFb_Room17_Select
	g_FinshRoom[3][6] = ZhouchangPVE_SceneFb_Room18_Select
	g_FinshRoom[4][1] = ZhouchangPVE_SceneFb_Room19_Select
	g_FinshRoom[4][2] = ZhouchangPVE_SceneFb_Room20_Select
	g_FinshRoom[4][3] = ZhouchangPVE_SceneFb_Room21_Select
	g_FinshRoom[4][4] = ZhouchangPVE_SceneFb_Room22_Select
	g_FinshRoom[4][5] = ZhouchangPVE_SceneFb_Room23_Select
	g_FinshRoom[4][6] = ZhouchangPVE_SceneFb_Room24_Select
	g_FinshRoom[5][1] = ZhouchangPVE_SceneFb_Room25_Select
	g_FinshRoom[5][2] = ZhouchangPVE_SceneFb_Room26_Select
	g_FinshRoom[5][3] = ZhouchangPVE_SceneFb_Room27_Select
	g_FinshRoom[5][4] = ZhouchangPVE_SceneFb_Room28_Select
	g_FinshRoom[5][5] = ZhouchangPVE_SceneFb_Room29_Select
	g_FinshRoom[5][6] = ZhouchangPVE_SceneFb_Room30_Select
	
	g_CanEnterRoom[1][1] = ZhouchangPVE_SceneFb_Room1_Hover
	g_CanEnterRoom[1][2] = ZhouchangPVE_SceneFb_Room2_Hover
	g_CanEnterRoom[1][3] = ZhouchangPVE_SceneFb_Room3_Hover
	g_CanEnterRoom[1][4] = ZhouchangPVE_SceneFb_Room4_Hover
	g_CanEnterRoom[1][5] = ZhouchangPVE_SceneFb_Room5_Hover
	g_CanEnterRoom[1][6] = ZhouchangPVE_SceneFb_Room6_Hover
	g_CanEnterRoom[2][1] = ZhouchangPVE_SceneFb_Room7_Hover
	g_CanEnterRoom[2][2] = ZhouchangPVE_SceneFb_Room8_Hover
	g_CanEnterRoom[2][3] = ZhouchangPVE_SceneFb_Room9_Hover
	g_CanEnterRoom[2][4] = ZhouchangPVE_SceneFb_Room10_Hover
	g_CanEnterRoom[2][5] = ZhouchangPVE_SceneFb_Room11_Hover
	g_CanEnterRoom[2][6] = ZhouchangPVE_SceneFb_Room12_Hover
	g_CanEnterRoom[3][1] = ZhouchangPVE_SceneFb_Room13_Hover
	g_CanEnterRoom[3][2] = ZhouchangPVE_SceneFb_Room14_Hover
	g_CanEnterRoom[3][3] = ZhouchangPVE_SceneFb_Room15_Hover
	g_CanEnterRoom[3][4] = ZhouchangPVE_SceneFb_Room16_Hover
	g_CanEnterRoom[3][5] = ZhouchangPVE_SceneFb_Room17_Hover
	g_CanEnterRoom[3][6] = ZhouchangPVE_SceneFb_Room18_Hover
	g_CanEnterRoom[4][1] = ZhouchangPVE_SceneFb_Room19_Hover
	g_CanEnterRoom[4][2] = ZhouchangPVE_SceneFb_Room20_Hover
	g_CanEnterRoom[4][3] = ZhouchangPVE_SceneFb_Room21_Hover
	g_CanEnterRoom[4][4] = ZhouchangPVE_SceneFb_Room22_Hover
	g_CanEnterRoom[4][5] = ZhouchangPVE_SceneFb_Room23_Hover
	g_CanEnterRoom[4][6] = ZhouchangPVE_SceneFb_Room24_Hover
	g_CanEnterRoom[5][1] = ZhouchangPVE_SceneFb_Room25_Hover
	g_CanEnterRoom[5][2] = ZhouchangPVE_SceneFb_Room26_Hover
	g_CanEnterRoom[5][3] = ZhouchangPVE_SceneFb_Room27_Hover
	g_CanEnterRoom[5][4] = ZhouchangPVE_SceneFb_Room28_Hover
	g_CanEnterRoom[5][5] = ZhouchangPVE_SceneFb_Room29_Hover
	g_CanEnterRoom[5][6] = ZhouchangPVE_SceneFb_Room30_Hover
	
	g_Team[1][1] = ZhouchangPVE_SceneFb_Room1_Team
	g_Team[1][2] = ZhouchangPVE_SceneFb_Room2_Team
	g_Team[1][3] = ZhouchangPVE_SceneFb_Room3_Team
	g_Team[1][4] = ZhouchangPVE_SceneFb_Room4_Team
	g_Team[1][5] = ZhouchangPVE_SceneFb_Room5_Team
	g_Team[1][6] = ZhouchangPVE_SceneFb_Room6_Team
	g_Team[2][1] = ZhouchangPVE_SceneFb_Room7_Team
	g_Team[2][2] = ZhouchangPVE_SceneFb_Room8_Team
	g_Team[2][3] = ZhouchangPVE_SceneFb_Room9_Team
	g_Team[2][4] = ZhouchangPVE_SceneFb_Room10_Team
	g_Team[2][5] = ZhouchangPVE_SceneFb_Room11_Team
	g_Team[2][6] = ZhouchangPVE_SceneFb_Room12_Team
	g_Team[3][1] = ZhouchangPVE_SceneFb_Room13_Team
	g_Team[3][2] = ZhouchangPVE_SceneFb_Room14_Team
	g_Team[3][3] = ZhouchangPVE_SceneFb_Room15_Team
	g_Team[3][4] = ZhouchangPVE_SceneFb_Room16_Team
	g_Team[3][5] = ZhouchangPVE_SceneFb_Room17_Team
	g_Team[3][6] = ZhouchangPVE_SceneFb_Room18_Team
	g_Team[4][1] = ZhouchangPVE_SceneFb_Room19_Team
	g_Team[4][2] = ZhouchangPVE_SceneFb_Room20_Team
	g_Team[4][3] = ZhouchangPVE_SceneFb_Room21_Team
	g_Team[4][4] = ZhouchangPVE_SceneFb_Room22_Team
	g_Team[4][5] = ZhouchangPVE_SceneFb_Room23_Team
	g_Team[4][6] = ZhouchangPVE_SceneFb_Room24_Team
	g_Team[5][1] = ZhouchangPVE_SceneFb_Room25_Team
	g_Team[5][2] = ZhouchangPVE_SceneFb_Room26_Team
	g_Team[5][3] = ZhouchangPVE_SceneFb_Room27_Team
	g_Team[5][4] = ZhouchangPVE_SceneFb_Room28_Team
	g_Team[5][5] = ZhouchangPVE_SceneFb_Room29_Team
	g_Team[5][6] = ZhouchangPVE_SceneFb_Room30_Team
	
	g_Self[1][1] = ZhouchangPVE_SceneFb_Room1_Self
	g_Self[1][2] = ZhouchangPVE_SceneFb_Room2_Self
	g_Self[1][3] = ZhouchangPVE_SceneFb_Room3_Self
	g_Self[1][4] = ZhouchangPVE_SceneFb_Room4_Self
	g_Self[1][5] = ZhouchangPVE_SceneFb_Room5_Self
	g_Self[1][6] = ZhouchangPVE_SceneFb_Room6_Self
	g_Self[2][1] = ZhouchangPVE_SceneFb_Room7_Self
	g_Self[2][2] = ZhouchangPVE_SceneFb_Room8_Self
	g_Self[2][3] = ZhouchangPVE_SceneFb_Room9_Self
	g_Self[2][4] = ZhouchangPVE_SceneFb_Room10_Self
	g_Self[2][5] = ZhouchangPVE_SceneFb_Room11_Self
	g_Self[2][6] = ZhouchangPVE_SceneFb_Room12_Self
	g_Self[3][1] = ZhouchangPVE_SceneFb_Room13_Self
	g_Self[3][2] = ZhouchangPVE_SceneFb_Room14_Self
	g_Self[3][3] = ZhouchangPVE_SceneFb_Room15_Self
	g_Self[3][4] = ZhouchangPVE_SceneFb_Room16_Self
	g_Self[3][5] = ZhouchangPVE_SceneFb_Room17_Self
	g_Self[3][6] = ZhouchangPVE_SceneFb_Room18_Self
	g_Self[4][1] = ZhouchangPVE_SceneFb_Room19_Self
	g_Self[4][2] = ZhouchangPVE_SceneFb_Room20_Self
	g_Self[4][3] = ZhouchangPVE_SceneFb_Room21_Self
	g_Self[4][4] = ZhouchangPVE_SceneFb_Room22_Self
	g_Self[4][5] = ZhouchangPVE_SceneFb_Room23_Self
	g_Self[4][6] = ZhouchangPVE_SceneFb_Room24_Self
	g_Self[5][1] = ZhouchangPVE_SceneFb_Room25_Self
	g_Self[5][2] = ZhouchangPVE_SceneFb_Room26_Self
	g_Self[5][3] = ZhouchangPVE_SceneFb_Room27_Self
	g_Self[5][4] = ZhouchangPVE_SceneFb_Room28_Self
	g_Self[5][5] = ZhouchangPVE_SceneFb_Room29_Self
	g_Self[5][6] = ZhouchangPVE_SceneFb_Room30_Self
	
	g_GameItem[1][1] = ZhouchangPVE_SceneFb_Room1_Icon
	g_GameItem[1][2] = ZhouchangPVE_SceneFb_Room2_Icon
	g_GameItem[1][3] = ZhouchangPVE_SceneFb_Room3_Icon
	g_GameItem[1][4] = ZhouchangPVE_SceneFb_Room4_Icon
	g_GameItem[1][5] = ZhouchangPVE_SceneFb_Room5_Icon
	g_GameItem[1][6] = ZhouchangPVE_SceneFb_Room6_Icon
	g_GameItem[2][1] = ZhouchangPVE_SceneFb_Room7_Icon
	g_GameItem[2][2] = ZhouchangPVE_SceneFb_Room8_Icon
	g_GameItem[2][3] = ZhouchangPVE_SceneFb_Room9_Icon
	g_GameItem[2][4] = ZhouchangPVE_SceneFb_Room10_Icon
	g_GameItem[2][5] = ZhouchangPVE_SceneFb_Room11_Icon
	g_GameItem[2][6] = ZhouchangPVE_SceneFb_Room12_Icon
	g_GameItem[3][1] = ZhouchangPVE_SceneFb_Room13_Icon
	g_GameItem[3][2] = ZhouchangPVE_SceneFb_Room14_Icon
	g_GameItem[3][3] = ZhouchangPVE_SceneFb_Room15_Icon
	g_GameItem[3][4] = ZhouchangPVE_SceneFb_Room16_Icon
	g_GameItem[3][5] = ZhouchangPVE_SceneFb_Room17_Icon
	g_GameItem[3][6] = ZhouchangPVE_SceneFb_Room18_Icon
	g_GameItem[4][1] = ZhouchangPVE_SceneFb_Room19_Icon
	g_GameItem[4][2] = ZhouchangPVE_SceneFb_Room20_Icon
	g_GameItem[4][3] = ZhouchangPVE_SceneFb_Room21_Icon
	g_GameItem[4][4] = ZhouchangPVE_SceneFb_Room22_Icon
	g_GameItem[4][5] = ZhouchangPVE_SceneFb_Room23_Icon
	g_GameItem[4][6] = ZhouchangPVE_SceneFb_Room24_Icon
	g_GameItem[5][1] = ZhouchangPVE_SceneFb_Room25_Icon
	g_GameItem[5][2] = ZhouchangPVE_SceneFb_Room26_Icon
	g_GameItem[5][3] = ZhouchangPVE_SceneFb_Room27_Icon
	g_GameItem[5][4] = ZhouchangPVE_SceneFb_Room28_Icon
	g_GameItem[5][5] = ZhouchangPVE_SceneFb_Room29_Icon
	g_GameItem[5][6] = ZhouchangPVE_SceneFb_Room30_Icon
	
	g_RoomItem[1][1] = ZhouchangPVE_SceneFb_Room1Tips
	g_RoomItem[1][2] = ZhouchangPVE_SceneFb_Room2Tips
	g_RoomItem[1][3] = ZhouchangPVE_SceneFb_Room3Tips
	g_RoomItem[1][4] = ZhouchangPVE_SceneFb_Room4Tips
	g_RoomItem[1][5] = ZhouchangPVE_SceneFb_Room5Tips
	g_RoomItem[1][6] = ZhouchangPVE_SceneFb_Room6Tips
	g_RoomItem[2][1] = ZhouchangPVE_SceneFb_Room7Tips
	g_RoomItem[2][2] = ZhouchangPVE_SceneFb_Room8Tips
	g_RoomItem[2][3] = ZhouchangPVE_SceneFb_Room9Tips
	g_RoomItem[2][4] = ZhouchangPVE_SceneFb_Room10Tips
	g_RoomItem[2][5] = ZhouchangPVE_SceneFb_Room11Tips
	g_RoomItem[2][6] = ZhouchangPVE_SceneFb_Room12Tips
	g_RoomItem[3][1] = ZhouchangPVE_SceneFb_Room13Tips
	g_RoomItem[3][2] = ZhouchangPVE_SceneFb_Room14Tips
	g_RoomItem[3][3] = ZhouchangPVE_SceneFb_Room15Tips
	g_RoomItem[3][4] = ZhouchangPVE_SceneFb_Room16Tips
	g_RoomItem[3][5] = ZhouchangPVE_SceneFb_Room17Tips
	g_RoomItem[3][6] = ZhouchangPVE_SceneFb_Room18Tips
	g_RoomItem[4][1] = ZhouchangPVE_SceneFb_Room19Tips
	g_RoomItem[4][2] = ZhouchangPVE_SceneFb_Room20Tips
	g_RoomItem[4][3] = ZhouchangPVE_SceneFb_Room21Tips
	g_RoomItem[4][4] = ZhouchangPVE_SceneFb_Room22Tips
	g_RoomItem[4][5] = ZhouchangPVE_SceneFb_Room23Tips
	g_RoomItem[4][6] = ZhouchangPVE_SceneFb_Room24Tips
	g_RoomItem[5][1] = ZhouchangPVE_SceneFb_Room25Tips
	g_RoomItem[5][2] = ZhouchangPVE_SceneFb_Room26Tips
	g_RoomItem[5][3] = ZhouchangPVE_SceneFb_Room27Tips
	g_RoomItem[5][4] = ZhouchangPVE_SceneFb_Room28Tips
	g_RoomItem[5][5] = ZhouchangPVE_SceneFb_Room29Tips
	g_RoomItem[5][6] = ZhouchangPVE_SceneFb_Room30Tips
	
	g_CheckItem[1][1] = ZhouchangPVE_SceneFb_Room1_Pushed
	g_CheckItem[1][2] = ZhouchangPVE_SceneFb_Room2_Pushed
	g_CheckItem[1][3] = ZhouchangPVE_SceneFb_Room3_Pushed
	g_CheckItem[1][4] = ZhouchangPVE_SceneFb_Room4_Pushed
	g_CheckItem[1][5] = ZhouchangPVE_SceneFb_Room5_Pushed
	g_CheckItem[1][6] = ZhouchangPVE_SceneFb_Room6_Pushed
	g_CheckItem[2][1] = ZhouchangPVE_SceneFb_Room7_Pushed
	g_CheckItem[2][2] = ZhouchangPVE_SceneFb_Room8_Pushed
	g_CheckItem[2][3] = ZhouchangPVE_SceneFb_Room9_Pushed
	g_CheckItem[2][4] = ZhouchangPVE_SceneFb_Room10_Pushed
	g_CheckItem[2][5] = ZhouchangPVE_SceneFb_Room11_Pushed
	g_CheckItem[2][6] = ZhouchangPVE_SceneFb_Room12_Pushed
	g_CheckItem[3][1] = ZhouchangPVE_SceneFb_Room13_Pushed
	g_CheckItem[3][2] = ZhouchangPVE_SceneFb_Room14_Pushed
	g_CheckItem[3][3] = ZhouchangPVE_SceneFb_Room15_Pushed
	g_CheckItem[3][4] = ZhouchangPVE_SceneFb_Room16_Pushed
	g_CheckItem[3][5] = ZhouchangPVE_SceneFb_Room17_Pushed
	g_CheckItem[3][6] = ZhouchangPVE_SceneFb_Room18_Pushed
	g_CheckItem[4][1] = ZhouchangPVE_SceneFb_Room19_Pushed
	g_CheckItem[4][2] = ZhouchangPVE_SceneFb_Room20_Pushed
	g_CheckItem[4][3] = ZhouchangPVE_SceneFb_Room21_Pushed
	g_CheckItem[4][4] = ZhouchangPVE_SceneFb_Room22_Pushed
	g_CheckItem[4][5] = ZhouchangPVE_SceneFb_Room23_Pushed
	g_CheckItem[4][6] = ZhouchangPVE_SceneFb_Room24_Pushed
	g_CheckItem[5][1] = ZhouchangPVE_SceneFb_Room25_Pushed
	g_CheckItem[5][2] = ZhouchangPVE_SceneFb_Room26_Pushed
	g_CheckItem[5][3] = ZhouchangPVE_SceneFb_Room27_Pushed
	g_CheckItem[5][4] = ZhouchangPVE_SceneFb_Room28_Pushed
	g_CheckItem[5][5] = ZhouchangPVE_SceneFb_Room29_Pushed
	g_CheckItem[5][6] = ZhouchangPVE_SceneFb_Room30_Pushed
	

end

--=========
-- Event
--=========
function ZhouchangPVE_SceneFb_OnEvent(event)

	if(event == "OPEN_WEEKPVEMAP")  then
		if g_Timer > 0 then
			KillTimer("ZhouchangPVE_SceneFb_Timer()")
		end
		g_CheckRoom = -1
		ZhouchangPVE_SceneFb_Open()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ZhouchangPVE_SceneFb_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		ZhouchangPVE_SceneFb_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		ZhouchangPVE_SceneFb_On_ResetPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331105005) then	--服务端传数据
		ZhouchangPVE_SceneFb_Close()
	end
	
	
end


function ZhouchangPVE_SceneFb_Close()
	
	this:Hide()
end

--=========
-- 重置
--=========
function ZhouchangPVE_SceneFb_On_ResetPos()

	ZhouchangPVE_SceneFb_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function ZhouchangPVE_SceneFb_Open()

	for i = 1, g_Row do
		for j = 1, g_Col do
			g_StartArea[i][j]:Hide()
			g_UnActive[i][j]:Hide()
			g_Active[i][j]:Hide()
			g_FinshRoom[i][j]:Hide()
			g_CanEnterRoom[i][j]:Hide()
			g_Team[i][j]:Hide()
			g_Self[i][j]:Hide()
			g_GameItem[i][j]:Hide()
			g_CheckItem[i][j]:Hide()
		end
	end
	ZhouchangPVE_SceneFb_Boss_Start:Hide()
	ZhouchangPVE_SceneFb_Boss_Boss:Hide()
	ZhouchangPVE_SceneFb_Boss_UnActive:Hide()
	ZhouchangPVE_SceneFb_Boss_Active:Hide()
	ZhouchangPVE_SceneFb_Boss_Select:Hide()
	ZhouchangPVE_SceneFb_Boss_Hover:Hide()
	ZhouchangPVE_SceneFb_Boss_Icon:Hide()
	ZhouchangPVE_SceneFb_Boss_Pushed:Hide()
	ZhouchangPVE_SceneFb_BossTips:Show()
	ZhouchangPVE_SceneFb_Boss_Team:Hide()
	ZhouchangPVE_SceneFb_Boss_Self:Hide()

	local nCurRoomEvent = -1
	local bIsInStartArea, nStartPosX, nStartPosZ, nPlayerPosX, nPlayerPosZ, nBossPosX, nBossPosZ, nGameItem1Num, nGameItem2Num, nGameItem3Num, nCurRoomState, nCurRound, nBossDis, nNextMoveStep, bIsNoWay, nBossWay, bIsShowBossWay, nOldBossPosX, nOldBossPosZ, nCurRoundUsedItem = AskWeekPveMapBaseInfo()
	if bIsNoWay == 1 then
		ZhouchangPVE_SceneFb_Btn:Hide()
		ZhouchangPVE_SceneFb_Btn2:Show()
	else
		ZhouchangPVE_SceneFb_Btn:Show()
		ZhouchangPVE_SceneFb_Btn2:Hide()
	end
	for i = 1, g_Row do
		for j = 1, g_Col do
			local nRet, nCopySceneParam =  AskWeekPveMapInfo(i-1,j-1)
			if nRet == 1 then
				--个位存事件类型，十位存该格子状态0，未解锁，1，解锁未探索，2解锁探索中，3解锁已探索，4，坍塌了，百位存当前房间可以获得游戏道具
				local nEventId = ZhouchangPVE_GetMapRoomEventId(nCopySceneParam )
				local nRoomState = ZhouchangPVE_GetMapRoomState(nCopySceneParam )
				local nGameItem = ZhouchangPVE_GetMapRoomGameItem(nCopySceneParam )
							
				if nRoomState == 0 then
					g_UnActive[i][j]:Show()
				elseif nRoomState == 1 then
					g_Active[i][j]:Show()
					g_Active[i][j]:SetProperty("Image", g_EventImage[nEventId])
				elseif nRoomState == 2 then
					g_Active[i][j]:Show()
					g_Active[i][j]:SetProperty("Image", g_EventImage[nEventId])
				elseif nRoomState == 3 then
					g_FinshRoom[i][j]:Show()
					g_FinshRoom[i][j]:SetProperty("Image", g_EventFinshImage[nEventId])
				end
				if g_GameItemImage[nGameItem] ~= nil then
					g_GameItem[i][j]:Show()
					g_GameItem[i][j]:SetProperty("Image", g_GameItemImage[nGameItem])
					
				end
				
				if i == nStartPosX and j == nStartPosZ then
					g_UnActive[i][j]:Hide()
					g_StartArea[i][j]:Show()
					g_Active[i][j]:Hide()
					g_FinshRoom[i][j]:Hide()
					if bIsInStartArea == 1 then
						if i == nBossPosX and j == nBossPosZ then
							ZhouchangPVE_SceneFb_Boss_Self:Show()
						else
							g_Self[i][j]:Show()
						end
					end
					--g_Active[i][j]:SetProperty("Image", g_EventImage[0])
				end
				if i == nPlayerPosX and j == nPlayerPosZ then
					g_Team[i][j]:Show()
					if bIsInStartArea ~= 1 then
						if i == nBossPosX and j == nBossPosZ then
							ZhouchangPVE_SceneFb_Boss_Self:Show()
						else
							g_Self[i][j]:Show()
						end
					end
					nCurRoomEvent = nEventId
				end	
				
				if ZhouchangPVE_IsInCanEnter(nPlayerPosX, nPlayerPosZ, i, j) == 1 and nRoomState == 1 and nCurRoomState == 2 then
					g_Active[i][j]:Hide()
					g_CanEnterRoom[i][j]:Show()
					g_CanEnterRoom[i][j]:SetProperty("Image", g_EventHighLightImage[nEventId])
				end
				
				if i == nBossPosX and j == nBossPosZ then
					if bIsShowBossWay == 0 then
						ZhouchangPVE_SceneFb_BossTips:SetProperty("UnifiedPosition","{{0,"..tostring(g_BossUIPos[i][j].x).."},{0,"..tostring(g_BossUIPos[i][j].z).."}}")
						if nCurRound < g_BossMoveStep then
							ZhouchangPVE_SceneFb_Boss_Boss:SetProperty("Image", g_BossImage[2])
						elseif nPlayerPosX == nBossPosX and nPlayerPosZ == nBossPosZ and nCurRoomState == 2 then
							ZhouchangPVE_SceneFb_Boss_Boss:SetProperty("Image", g_BossImage[3])
						elseif nCurRoundUsedItem == 1 then
							ZhouchangPVE_SceneFb_Boss_Boss:SetProperty("Image", g_BossImage[4])
						elseif nCurRoundUsedItem == 2 then
							ZhouchangPVE_SceneFb_Boss_Boss:SetProperty("Image", g_BossImage[5])
						else
							ZhouchangPVE_SceneFb_Boss_Boss:SetProperty("Image", g_BossImage[1])
						end
						ZhouchangPVE_SceneFb_Boss_Boss:Show()
					end
					
					
					
					g_UnActive[i][j]:Hide()
					g_Active[i][j]:Hide()
					g_GameItem[i][j]:Hide()
					g_FinshRoom[i][j]:Hide()
					g_StartArea[i][j]:Hide()
					g_CanEnterRoom[i][j]:Hide()
					
					if nPlayerPosX == nBossPosX and nPlayerPosZ == nBossPosZ then
						--g_Team[i][j]:Show()
						if bIsInStartArea ~= 1 then
							ZhouchangPVE_SceneFb_Boss_Team:Show()
							g_Team[i][j]:Hide()
						end
						
						
					end
					if bIsShowBossWay == 1 and nRoomState ~= 0 then
						g_Active[i][j]:Show()
					end
					
					if bIsNoWay == 1 then
						ZhouchangPVE_SceneFb_Boss_Pushed:Show()
						ZhouchangPVE_SceneFb_Btn:Hide()
						ZhouchangPVE_SceneFb_Btn2:Show()
						g_CheckRoom = g_Col*(i-1)+j
					end
				end	
				
				local mark1 = 0
				local mark2 = 0
				local str = ""
				if g_EventTips[nEventId] ~= nil then
					str = ScriptGlobal_Format("#{FHCL_240708_192}",g_EventTips[nEventId])
				elseif nEventId == 10 then
					str = "#{FHCL_240708_207}"
				elseif i == nStartPosX and j == nStartPosZ then
					str = "#{FHCL_240708_208}"
					mark1 = 1
				end
				if g_GameItemText[nGameItem] ~= nil then
					if g_FuBenType[nEventId] == 0 then
						str = str..ScriptGlobal_Format("#{FHCL_240708_193}",g_GameItemText[nGameItem])
					else
						str = str..ScriptGlobal_Format("#{FHCL_240708_406}",g_GameItemText[nGameItem])
					end
				end
				
				if i == nPlayerPosX and j == nPlayerPosZ then
					str = str.."#{FHCL_240708_209}"
				end	
				
				if i == nPlayerPosX and j == nPlayerPosZ and bIsInStartArea ~= 1 then
					str = str.."#{FHCL_240708_210}"
				elseif i == nStartPosX and j == nStartPosZ and bIsInStartArea == 1 then
					str = str.."#{FHCL_240708_210}"
				end	
				
				if nRoomState == 0 and mark1 == 0 then
					str = "#{FHCL_240708_191}"
				end
				
				if nRoomState == 3 and mark1 == 0 then
					str = "#{FHCL_240708_206}"
				end
				
				if i == nBossPosX and j == nBossPosZ then
					str = "#{FHCL_240708_211}"
				end
				
				-- if i == nBossPosX and j == nBossPosZ then
					-- ZhouchangPVE_SceneFb_BossTips:SetToolTip(str)
				-- else
				g_RoomItem[i][j]:SetToolTip(str)
				--end
			end
		end
	end
	
	if bIsShowBossWay == 1 then
		if g_Timer > 0 then
			KillTimer("ZhouchangPVE_SceneFb_Timer()")
		end
		g_Timer = 10
		g_Step = 0
		g_NowBossX = nOldBossPosX
		g_NowBossZ = nOldBossPosZ
		ZhouchangPVE_SceneFb_BossTips:SetProperty("UnifiedPosition","{{0,"..tostring(g_BossUIPos[nOldBossPosX][nOldBossPosZ].x).."},{0,"..tostring(g_BossUIPos[nOldBossPosX][nOldBossPosZ].z).."}}")
		if nCurRound < g_BossMoveStep   then
			ZhouchangPVE_SceneFb_Boss_Boss:SetProperty("Image", g_BossImage[2])
		elseif nPlayerPosX == nBossPosX and nPlayerPosZ == nBossPosZ and nCurRoomState == 2 then
			ZhouchangPVE_SceneFb_Boss_Boss:SetProperty("Image", g_BossImage[3])
		elseif nCurRoundUsedItem == 1 then
			ZhouchangPVE_SceneFb_Boss_Boss:SetProperty("Image", g_BossImage[4])
		elseif nCurRoundUsedItem == 2 then
			ZhouchangPVE_SceneFb_Boss_Boss:SetProperty("Image", g_BossImage[5])
		else
			ZhouchangPVE_SceneFb_Boss_Boss:SetProperty("Image", g_BossImage[1])
		end
		ZhouchangPVE_SceneFb_Boss_Boss:Show()
		SetTimer("ZhouchangPVE_SceneFb","ZhouchangPVE_SceneFb_Timer()", 1*100)
	end
	
	ZhouchangPVE_SceneFb_Skill_Icon1LimitNum:SetText(ScriptGlobal_Format("#{FHCL_240708_407}",nGameItem1Num))
	
	

	ZhouchangPVE_SceneFb_Skill_Icon2LimitNum:SetText(ScriptGlobal_Format("#{FHCL_240708_408}",nGameItem2Num))
	
	
	
	ZhouchangPVE_SceneFb_Skill_Icon3LimitNum:SetText(ScriptGlobal_Format("#{FHCL_240708_409}",nGameItem3Num))
	
	
	ZhouchangPVE_SceneFb_BossText2:SetText(ScriptGlobal_Format("#{FHCL_240708_219}",nBossDis))
	ZhouchangPVE_SceneFb_BossText2:Show()
	if nCurRound < g_BossMoveStep then
		ZhouchangPVE_SceneFb_BossText3:SetText("#{FHCL_240708_487}")
	else
		ZhouchangPVE_SceneFb_BossText3:SetText(ScriptGlobal_Format("#{FHCL_240708_220}",nNextMoveStep))
	end
	ZhouchangPVE_SceneFb_BossText3:Show()
	ZhouchangPVE_SceneFb_BossText4:Hide()

	
	if nCurRoomState == 2 and nCurRoomEvent == 9 then

		ZhouchangPVE_SceneFb_BossText4:SetText("#{FHCL_240708_369}")
		ZhouchangPVE_SceneFb_BossText3:Hide()
		ZhouchangPVE_SceneFb_BossText2:Hide()
		ZhouchangPVE_SceneFb_BossText4:Show()
	elseif nCurRoomEvent == 9 and nCurRoomState ~= 2 then
		ZhouchangPVE_SceneFb_BossText4:SetText("#{FHCL_240708_375}")
		ZhouchangPVE_SceneFb_BossText3:Hide()
		ZhouchangPVE_SceneFb_BossText2:Hide()
		ZhouchangPVE_SceneFb_BossText4:Show()
	end
	
	this:Show()
end	

function ZhouchangPVE_SceneFb_Timer()
	g_Timer = g_Timer - 1 
	local bIsInStartArea, nStartPosX, nStartPosZ, nPlayerPosX, nPlayerPosZ, nBossPosX, nBossPosZ, nGameItem1Num, nGameItem2Num, nGameItem3Num, nCurRoomState, nCurRound, nBossDis, nNextMoveStep, bIsNoWay, nBossWay, bIsShowBossWay, nOldBossPosX, nOldBossPosZ, nCurRoundUsedItem = AskWeekPveMapBaseInfo()
	local n = 1
	for i = 1, g_Step do
		n = n*10
	end
	local nMoveDir = math.mod(math.floor(nBossWay/n),10)
	
	if g_Timer == 0 then
		KillTimer("ZhouchangPVE_SceneFb_Timer()")
		
		
		
		if nMoveDir == 1 then
			
			local tx = g_BossUIPos[g_NowBossX-1][g_NowBossZ].x
			local tz = g_BossUIPos[g_NowBossX-1][g_NowBossZ].z
			g_NowBossX = g_NowBossX -1
			ZhouchangPVE_SceneFb_BossTips:SetProperty("UnifiedPosition","{{0,"..tostring(tx).."},{0,"..tostring(tz).."}}")
		elseif  nMoveDir == 2 then
			
			local tx = g_BossUIPos[g_NowBossX+1][g_NowBossZ].x
			local tz = g_BossUIPos[g_NowBossX+1][g_NowBossZ].z		
			g_NowBossX = g_NowBossX + 1	
			ZhouchangPVE_SceneFb_BossTips:SetProperty("UnifiedPosition","{{0,"..tostring(tx).."},{0,"..tostring(tz).."}}")
		elseif nMoveDir == 3 then
			
			local tx = g_BossUIPos[g_NowBossX][g_NowBossZ-1].x
			local tz = g_BossUIPos[g_NowBossX][g_NowBossZ-1].z		
			g_NowBossZ = g_NowBossZ -1
			ZhouchangPVE_SceneFb_BossTips:SetProperty("UnifiedPosition","{{0,"..tostring(tx).."},{0,"..tostring(tz).."}}")
		elseif  nMoveDir == 4 then
			
			local tx = g_BossUIPos[g_NowBossX][g_NowBossZ+1].x
			local tz = g_BossUIPos[g_NowBossX][g_NowBossZ+1].z	
			g_NowBossZ = g_NowBossZ + 1
			ZhouchangPVE_SceneFb_BossTips:SetProperty("UnifiedPosition","{{0,"..tostring(tx).."},{0,"..tostring(tz).."}}")
		end
		g_Step = g_Step + 1
		local n1 = 1
		for i = 1, g_Step do
			n1 = n1*10
		end
		local nNewMoveDir =  math.mod(math.floor(nBossWay/n1),10)
		if nNewMoveDir ~= 0 then
			g_Timer = 10
			SetTimer("ZhouchangPVE_SceneFb","ZhouchangPVE_SceneFb_Timer()", 1*100)
		else
			
			g_UnActive[nBossPosX][nBossPosZ]:Hide()
			g_Active[nBossPosX][nBossPosZ]:Hide()
			g_GameItem[nBossPosX][nBossPosZ]:Hide()
			g_FinshRoom[nBossPosX][nBossPosZ]:Hide()
			g_StartArea[nBossPosX][nBossPosZ]:Hide()
			g_CanEnterRoom[nBossPosX][nBossPosZ]:Hide()
			
		end
		return 0
	end
	
	if nMoveDir == 1 then
		local x = g_BossUIPos[g_NowBossX][g_NowBossZ].x
		local z = g_BossUIPos[g_NowBossX][g_NowBossZ].z
		local tx = g_BossUIPos[g_NowBossX-1][g_NowBossZ].x
		local tz = g_BossUIPos[g_NowBossX-1][g_NowBossZ].z
		local newx = x
		local newz = tz + math.floor((z-tz)/10*g_Timer)
		ZhouchangPVE_SceneFb_BossTips:SetProperty("UnifiedPosition","{{0,"..tostring(newx).."},{0,"..tostring(newz).."}}")
	elseif  nMoveDir == 2 then
		local x = g_BossUIPos[g_NowBossX][g_NowBossZ].x
		local z = g_BossUIPos[g_NowBossX][g_NowBossZ].z
		local tx = g_BossUIPos[g_NowBossX+1][g_NowBossZ].x
		local tz = g_BossUIPos[g_NowBossX+1][g_NowBossZ].z
		local newx = x
		local newz = z + math.floor((tz-z)/10*(10-g_Timer))
		ZhouchangPVE_SceneFb_BossTips:SetProperty("UnifiedPosition","{{0,"..tostring(newx).."},{0,"..tostring(newz).."}}")
	elseif nMoveDir == 3 then
		local x = g_BossUIPos[g_NowBossX][g_NowBossZ].x
		local z = g_BossUIPos[g_NowBossX][g_NowBossZ].z
		local tx = g_BossUIPos[g_NowBossX][g_NowBossZ-1].x
		local tz = g_BossUIPos[g_NowBossX][g_NowBossZ-1].z
		local newx = tx + math.floor((x-tx)/10*g_Timer)
		local newz = z
		ZhouchangPVE_SceneFb_BossTips:SetProperty("UnifiedPosition","{{0,"..tostring(newx).."},{0,"..tostring(newz).."}}")
	elseif  nMoveDir == 4 then
		local x = g_BossUIPos[g_NowBossX][g_NowBossZ].x
		local z = g_BossUIPos[g_NowBossX][g_NowBossZ].z
		local tx = g_BossUIPos[g_NowBossX][g_NowBossZ+1].x
		local tz = g_BossUIPos[g_NowBossX][g_NowBossZ+1].z
		local newx = x + math.floor((tx-x)/10*(10-g_Timer))
		local newz = z 
		ZhouchangPVE_SceneFb_BossTips:SetProperty("UnifiedPosition","{{0,"..tostring(newx).."},{0,"..tostring(newz).."}}")
	end
end


-- 获取当前格子内的事件id
function ZhouchangPVE_GetMapRoomEventId(sceneParam )
	local nParam = sceneParam
	local nEventId = math.mod(nParam,100)
	return nEventId
end

-- 获取当前格子内的状态
function ZhouchangPVE_GetMapRoomState(sceneParam )
	local nParam = sceneParam
	local nState = math.mod(math.floor(nParam/100),10)
	return nState
end

-- 获取当前格子内的道具
function ZhouchangPVE_GetMapRoomGameItem(sceneParam )
	local nParam = sceneParam
	local nGameItem = math.floor(nParam/1000)
	return nGameItem
end


function ZhouchangPVE_IsInCanEnter(nStartPosX, nStartPosZ, nNewPosX, nNewPosZ)
	if math.abs(nStartPosX - nNewPosX) +  math.abs(nStartPosZ - nNewPosZ) == 1 then
		return 1
	end
	return 0
end

function ZhouchangPVE_SceneFb_Skill_Icon_Btn(index)
	if index < 1 or index > 3 then
		return 0
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PlayerUseGameItem" )
		Set_XSCRIPT_ScriptID(331105)
		Set_XSCRIPT_Parameter(0, index);	
		Set_XSCRIPT_Parameter(1, 0);	
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	
	
end

function ZhouchangPVE_SceneFb_Room_Clicked(index)
	
	if index < 1 or index > 30 then
		return 0
	end	
	
	local bIsInStartArea, nStartPosX, nStartPosZ, nPlayerPosX, nPlayerPosZ, nBossPosX, nBossPosZ, nGameItem1Num, nGameItem2Num, nGameItem3Num, nCurRoomState, nCurRound, nBossDis, nNextMoveStep, bIsNoWay, nBossWay, bIsShowBossWay, nOldBossPosX, nOldBossPosZ, nCurRoundUsedItem = AskWeekPveMapBaseInfo()
	if nPlayerPosX == nBossPosX and nPlayerPosZ == nBossPosZ and nCurRoomState == 2 then
		PushDebugMessage("#{FHCL_240708_168}")
		return 0
	end
	
	if nCurRoomState ~= 2 then
		PushDebugMessage("#{FHCL_240708_174}")
		return 0
	end
	
	
	local nRet, nCopySceneParam =  AskWeekPveMapInfo(g_PosIndex[index].x-1,g_PosIndex[index].z-1)
	if nRet == 1 and bIsNoWay == 0 then
		--个位存事件类型，十位存该格子状态0，未解锁，1，解锁未探索，2解锁探索中，3解锁已探索，4，坍塌了，百位存当前房间可以获得游戏道具
		local nEventId = ZhouchangPVE_GetMapRoomEventId(nCopySceneParam )
		local nRoomState = ZhouchangPVE_GetMapRoomState(nCopySceneParam )
		local nGameItem = ZhouchangPVE_GetMapRoomGameItem(nCopySceneParam )
		
		if ZhouchangPVE_IsInCanEnter(nPlayerPosX, nPlayerPosZ, g_PosIndex[index].x, g_PosIndex[index].z) == 1 and nRoomState == 1 and nCurRoomState == 2 then
			for i = 1, g_Row do
				for j = 1, g_Col do
					g_CheckItem[i][j]:Hide()
				end
			end
			g_CheckItem[g_PosIndex[index].x][g_PosIndex[index].z]:Show()
			g_CheckRoom = index
		else
			if bIsNoWay == 1 then
				PushDebugMessage("#{FHCL_240708_480}")
			else
				PushDebugMessage("#{FHCL_240708_451}")
			end
			return 0
		end
	end
	
end

function ZhouchangPVE_SceneFb_GO()
	local bIsInStartArea, nStartPosX, nStartPosZ, nPlayerPosX, nPlayerPosZ, nBossPosX, nBossPosZ, nGameItem1Num, nGameItem2Num, nGameItem3Num, nCurRoomState, nCurRound, nBossDis, nNextMoveStep, bIsNoWay, nBossWay, bIsShowBossWay, nOldBossPosX, nOldBossPosZ, nCurRoundUsedItem = AskWeekPveMapBaseInfo()
	if nPlayerPosX == nBossPosX and nPlayerPosZ == nBossPosZ and nCurRoomState == 2 then
		PushDebugMessage("#{FHCL_240708_168}")
		return 0
	end
	if g_CheckRoom == -1 then
		PushDebugMessage("#{FHCL_240708_450}")
		return 0
	end
	
	if g_PosIndex[g_CheckRoom] == nil then
		PushDebugMessage("#{FHCL_240708_450}")
		return 0
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PlayerGo" )
		Set_XSCRIPT_ScriptID(331105)
		Set_XSCRIPT_Parameter(0, g_PosIndex[g_CheckRoom].x);	
		Set_XSCRIPT_Parameter(1, g_PosIndex[g_CheckRoom].z);	
		Set_XSCRIPT_Parameter(2, 0);	
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	

end