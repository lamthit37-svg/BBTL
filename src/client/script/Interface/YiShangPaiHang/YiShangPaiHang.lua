-- 外观排行榜（仪赏）

-- 排行榜上榜数据数量
local YiShangPaiHang_RankListNum = 10

-- 保存UI默认位置
local YiShangPaiHang_UnifiedPosition = nil
-- 控件表
local YiShangPaiHang_CtrlTbl = nil

-- 关注NPC
local YiShangPaiHang_CareObjId = -1
local YiShangPaiHang_CareObjSvrId = -1
local YiShangPaiHang_MAX_OBJ_DISTANCE = 5.0

function YiShangPaiHang_PreLoad()
	this:RegisterEvent("ARL_UPDATERANKLIST", true)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS", false)
end -- end func YiShangPaiHang_PreLoad()

function YiShangPaiHang_OnLoad()
	YiShangPaiHang_UnifiedPosition = YiShangPaiHang_Frame_BK:GetProperty("UnifiedPosition")

	YiShangPaiHang_InitCtrlTbl()
end -- end func YiShangPaiHang_OnLoad()

function YiShangPaiHang_OnEvent(event)
	if (event == "ARL_UPDATERANKLIST") then
		YiShangPaiHang_BeginCareObject(arg0, arg1)
		YiShangPaiHang_Show()
		YiShangPaiHang_UpdateRankList()
	elseif event == "OBJECT_CARED_EVENT" then
		if(tonumber(arg0) ~= YiShangPaiHang_CareObjId) then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2)>YiShangPaiHang_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			--取消关心
			YiShangPaiHang_Hide()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		YiShangPaiHang_OnResetPos()
	elseif event == "ADJEST_UI_POS" then
		YiShangPaiHang_OnResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		YiShangPaiHang_Hide()
	end
end -- end func YiShangPaiHang_OnEvent()

function YiShangPaiHang_OnResetPos()
	YiShangPaiHang_Frame_BK:SetProperty("UnifiedPosition", YiShangPaiHang_UnifiedPosition)
end -- end func YiShangPaiHang_OnResetPos()

function YiShangPaiHang_Show()
    if (not this:IsVisible()) then
		this:Show()
	end
end -- end func YiShangPaiHang_Show()

function YiShangPaiHang_Hide()
	this:Hide()
	YiShangPaiHang_StopCareObject(YiShangPaiHang_CareObjId)
end -- end func YiShangPaiHang_Hide()

function YiShangPaiHang_InitCtrlTbl()
	YiShangPaiHang_CtrlTbl = {}

	YiShangPaiHang_CtrlTbl.tiptext = YiShangPaiHang_Text

	YiShangPaiHang_CtrlTbl.ranklist = {}
	YiShangPaiHang_CtrlTbl.ranklist[1] = {}
	YiShangPaiHang_CtrlTbl.ranklist[1].rank = YiShangPaiHang_Page2TopList_Client1_No_text
	YiShangPaiHang_CtrlTbl.ranklist[1].name = YiShangPaiHang_Page2TopList_Client1_L_text
	YiShangPaiHang_CtrlTbl.ranklist[1].score = YiShangPaiHang_Page2TopList_Client1_R_text
	YiShangPaiHang_CtrlTbl.ranklist[2] = {}
	YiShangPaiHang_CtrlTbl.ranklist[2].rank = YiShangPaiHang_Page2TopList_Client2_No_text
	YiShangPaiHang_CtrlTbl.ranklist[2].name = YiShangPaiHang_Page2TopList_Client2_L_text
	YiShangPaiHang_CtrlTbl.ranklist[2].score = YiShangPaiHang_Page2TopList_Client2_R_text
	YiShangPaiHang_CtrlTbl.ranklist[3] = {}
	YiShangPaiHang_CtrlTbl.ranklist[3].rank = YiShangPaiHang_Page2TopList_Client3_No_text
	YiShangPaiHang_CtrlTbl.ranklist[3].name = YiShangPaiHang_Page2TopList_Client3_L_text
	YiShangPaiHang_CtrlTbl.ranklist[3].score = YiShangPaiHang_Page2TopList_Client3_R_text
	YiShangPaiHang_CtrlTbl.ranklist[4] = {}
	YiShangPaiHang_CtrlTbl.ranklist[4].rank = YiShangPaiHang_Page2TopList_Client4_No_text
	YiShangPaiHang_CtrlTbl.ranklist[4].name = YiShangPaiHang_Page2TopList_Client4_L_text
	YiShangPaiHang_CtrlTbl.ranklist[4].score = YiShangPaiHang_Page2TopList_Client4_R_text
	YiShangPaiHang_CtrlTbl.ranklist[5] = {}
	YiShangPaiHang_CtrlTbl.ranklist[5].rank = YiShangPaiHang_Page2TopList_Client5_No_text
	YiShangPaiHang_CtrlTbl.ranklist[5].name = YiShangPaiHang_Page2TopList_Client5_L_text
	YiShangPaiHang_CtrlTbl.ranklist[5].score = YiShangPaiHang_Page2TopList_Client5_R_text
	YiShangPaiHang_CtrlTbl.ranklist[6] = {}
	YiShangPaiHang_CtrlTbl.ranklist[6].rank = YiShangPaiHang_Page2TopList_Client6_No_text
	YiShangPaiHang_CtrlTbl.ranklist[6].name = YiShangPaiHang_Page2TopList_Client6_L_text
	YiShangPaiHang_CtrlTbl.ranklist[6].score = YiShangPaiHang_Page2TopList_Client6_R_text
	YiShangPaiHang_CtrlTbl.ranklist[7] = {}
	YiShangPaiHang_CtrlTbl.ranklist[7].rank = YiShangPaiHang_Page2TopList_Client7_No_text
	YiShangPaiHang_CtrlTbl.ranklist[7].name = YiShangPaiHang_Page2TopList_Client7_L_text
	YiShangPaiHang_CtrlTbl.ranklist[7].score = YiShangPaiHang_Page2TopList_Client7_R_text
	YiShangPaiHang_CtrlTbl.ranklist[8] = {}
	YiShangPaiHang_CtrlTbl.ranklist[8].rank = YiShangPaiHang_Page2TopList_Client8_No_text
	YiShangPaiHang_CtrlTbl.ranklist[8].name = YiShangPaiHang_Page2TopList_Client8_L_text
	YiShangPaiHang_CtrlTbl.ranklist[8].score = YiShangPaiHang_Page2TopList_Client8_R_text
	YiShangPaiHang_CtrlTbl.ranklist[9] = {}
	YiShangPaiHang_CtrlTbl.ranklist[9].rank = YiShangPaiHang_Page2TopList_Client9_No_text
	YiShangPaiHang_CtrlTbl.ranklist[9].name = YiShangPaiHang_Page2TopList_Client9_L_text
	YiShangPaiHang_CtrlTbl.ranklist[9].score = YiShangPaiHang_Page2TopList_Client9_R_text
	YiShangPaiHang_CtrlTbl.ranklist[10] = {}
	YiShangPaiHang_CtrlTbl.ranklist[10].rank = YiShangPaiHang_Page2TopList_Client10_No_text
	YiShangPaiHang_CtrlTbl.ranklist[10].name = YiShangPaiHang_Page2TopList_Client10_L_text
	YiShangPaiHang_CtrlTbl.ranklist[10].score = YiShangPaiHang_Page2TopList_Client10_R_text
end -- end func YiShangPaiHang_InitCtrlTbl()

--*****************************************************************************
-- 关闭按钮事件
--*****************************************************************************
function YiShangPaiHang_OnHide()
    YiShangPaiHang_Hide()
end -- end func YiShangPaiHang_OnHide()

--*****************************************************************************
-- 清空排行榜
--*****************************************************************************
function YiShangPaiHang_ClearRankList()
	if (YiShangPaiHang_CtrlTbl == nil) then
		return -1
	end
	if (YiShangPaiHang_CtrlTbl.ranklist == nil) then
		return -2
	end

	for i=1, YiShangPaiHang_RankListNum, 1 do
		if (YiShangPaiHang_CtrlTbl.ranklist[i] ~= nil) then
			if (YiShangPaiHang_CtrlTbl.ranklist[i].rank ~= nil) then
				YiShangPaiHang_CtrlTbl.ranklist[i].rank:SetText("")
			end

			if (YiShangPaiHang_CtrlTbl.ranklist[i].name ~= nil) then
				YiShangPaiHang_CtrlTbl.ranklist[i].name:SetText("")
			end

			if (YiShangPaiHang_CtrlTbl.ranklist[i].score ~= nil) then
				YiShangPaiHang_CtrlTbl.ranklist[i].score:SetText("")
			end
		end
	end -- end for

	return 1
end -- end func YiShangPaiHang_ClearRankList()

--*****************************************************************************
-- 更新排行榜
--*****************************************************************************
function YiShangPaiHang_UpdateRankList()
	if (YiShangPaiHang_CtrlTbl == nil) then
		return -1
	end
	if (YiShangPaiHang_CtrlTbl.ranklist == nil) then
		return -2
	end

	-- 更新之前先清空原有数据
	YiShangPaiHang_ClearRankList()

	-- 更新排行榜数据
	for i=1, YiShangPaiHang_RankListNum, 1 do
		local ret, playerScore, playerName = AppRankList:GetRankListData(i-1)
		if (ret > 0 and playerScore > 0) then
			if (YiShangPaiHang_CtrlTbl.ranklist[i] ~= nil) then
				if (YiShangPaiHang_CtrlTbl.ranklist[i].rank ~= nil) then
					YiShangPaiHang_CtrlTbl.ranklist[i].rank:SetText(i)
				end

				if (YiShangPaiHang_CtrlTbl.ranklist[i].name ~= nil) then
					YiShangPaiHang_CtrlTbl.ranklist[i].name:SetText(playerName)
				end

				if (YiShangPaiHang_CtrlTbl.ranklist[i].score ~= nil) then
					YiShangPaiHang_CtrlTbl.ranklist[i].score:SetText(tostring(playerScore))
				end
			end
		end
	end -- end for

	return 1
end -- end func YiShangPaiHang_UpdateRankList()



--*************************************************************************************************
-- NPC关注相关
--*************************************************************************************************
-- 开启NPC关注
function YiShangPaiHang_BeginCareObject(objSvrId, objId)
	YiShangPaiHang_CareObjId = tonumber(objId)
	YiShangPaiHang_CareObjSvrId = tonumber(objSvrId)
	if (YiShangPaiHang_CareObjId >= 0) then
		this:CareObject(YiShangPaiHang_CareObjId, 1, "YiShangPaiHang")
	end
end -- end func YiShangPaiHang_BeginCareObject()

-- 取消NPC关注
function YiShangPaiHang_StopCareObject(objId)
	if (tonumber(objId) >= 0) then
		this:CareObject(objId, 0, "YiShangPaiHang")
		YiShangPaiHang_CareObjId = -1
		YiShangPaiHang_CareObjSvrId = -1
	end
end -- end func YiShangPaiHang_StopCareObject()