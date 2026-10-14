local g_T3ZhanGongGet_UnifiedPosition = nil 
local g_T3ZhanGongGet_gold = {}
local g_T3ZhanGongGet_silver = {}
function T3ZhanGongGet_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT")
	this:RegisterEvent("OPEN_T3_ZHANGONG")

end 

-- T3ZhanGongGet_Close => TLBB_ButtonClose
-- T3ZhanGongGet_Client => DefaultWindow
-- T3ZhanGongGet_Citychoice_DragTitle => TLBB_DragTitle
function T3ZhanGongGet_OnLoad()
	g_T3ZhanGongGet_UnifiedPosition = T3ZhanGongGet:GetProperty("UnifiedPosition");
	
	g_T3ZhanGongGet_gold[1] = T3ZhanGongGet_Gold1
	g_T3ZhanGongGet_gold[2] = T3ZhanGongGet_Gold2
	g_T3ZhanGongGet_gold[3] = T3ZhanGongGet_Gold3
	g_T3ZhanGongGet_silver[1] = T3ZhanGongGet_Silver1
	g_T3ZhanGongGet_silver[2] = T3ZhanGongGet_Silver2
	g_T3ZhanGongGet_silver[3] = T3ZhanGongGet_Silver3
	
end

function T3ZhanGongGet_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		T3ZhanGongGet_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		T3ZhanGongGet_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		T3ZhanGongGet_On_Hide()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		T3ZhanGongGet_CareObj()
	elseif event == "OPEN_T3_ZHANGONG" then
		local ntype = tonumber(arg0)
		local b7days = tonumber(arg1)
		local blianjin = tonumber(arg2)
		local bfenghuang = tonumber(arg3)
		local beasyyanmen = tonumber(arg4)
		local bHardyanmen = tonumber(arg5)
		local guildtarget = tonumber(arg6)
		local targetId = tonumber(arg7)
		
		-- local curNpcLevel = tonumber(arg8)
		-- local curTotleNum = tonumber(arg9)
		-- local lastWeekNpcLevel = tonumber(arg10)
		-- local lastWeekTotleNum = tonumber(arg11)
		-- local ntype = tonumber(arg0)

		T3ZhanGongGet_InitFrame(ntype,b7days,blianjin,bfenghuang,beasyyanmen,bHardyanmen,guildtarget)
		this:Show()
		T3ZhanGongGet_BeginCareObject(Target:GetServerId2ClientId(targetId))

	end
end

function T3ZhanGongGet_InitZWNpcFrame(ntype,curNpcLevel,curTotleNum,lastWeekNpcLevel,lastWeekTotleNum,curZhanGong,lastWeekZhanGong)
	local add = 0
	T3ZhanGongGet_Text3:Show()
	T3ZhanGongGet_Info3:Show()
	T3ZhanGongGet_Info4:Show()
	if ntype == 1 then
		--上周情况
		T3ZhanGongGet_Text3:SetText(ScriptGlobal_Format("#{ZGMW_20220706_02}", lastWeekNpcLevel))
		T3ZhanGongGet_Info3:SetText(ScriptGlobal_Format("#{ZGMW_20220706_03}", lastWeekTotleNum))
		if lastWeekTotleNum<10 then
			add = 0
			T3ZhanGongGet_Info4:SetText("#{ZGMW_20220706_05}")
		else
			add = lastWeekZhanGong
			T3ZhanGongGet_Info4:SetText(ScriptGlobal_Format("#{ZGMW_20220706_04}", lastWeekZhanGong))
		end
	else
		-- 当前情况
		T3ZhanGongGet_Text3:SetText(ScriptGlobal_Format("#{ZGMW_20220706_09}", curNpcLevel))
		T3ZhanGongGet_Info3:SetText(ScriptGlobal_Format("#{ZGMW_20220706_10}", curTotleNum))
		if curTotleNum<10 then
			add = 0
			T3ZhanGongGet_Info4:SetText("#{ZGMW_20220706_12}")
		else
			add = curZhanGong
			T3ZhanGongGet_Info4:SetText(ScriptGlobal_Format("#{ZGMW_20220706_11}", curZhanGong))
		end
				
	end
	if Player:GetData("Is2606S") == 1 then
		T3ZhanGongGet_Text3:SetText("#{QXF_260623_154}")
		T3ZhanGongGet_Info3:Hide()
		T3ZhanGongGet_Info4:Hide()
	end
	return add
end

function T3ZhanGongGet_InitFrame(ntype,b7days,blianjin,bfenghuang,beasyyanmen,bHardyanmen,guildtarget)
	-- PushDebugMessage("xtccc")
	for i = 1, 3 do
		g_T3ZhanGongGet_silver[i]:Show()
	end
	T3ZhanGongGet_InitMainFrame(ntype)
	local add1 = T3ZhanGongGet_InitLianjinFrame(ntype,blianjin)
	local add2 = T3ZhanGongGet_InitShangWuFrame(ntype,bfenghuang,beasyyanmen,bHardyanmen)

	local curNpcLevel,curTotleNum,lastWeekNpcLevel,lastWeekTotleNum,curZhanGong,lastWeekZhanGong = City:GetZWNpcInfo()


	local add3 = T3ZhanGongGet_InitZWNpcFrame(ntype,curNpcLevel,curTotleNum,lastWeekNpcLevel,lastWeekTotleNum,curZhanGong,lastWeekZhanGong)
	-- local add3 = T3ZhanGongGet_InitT3battleFrame(ntype,guildtarget)
	
	local addtable = {add1,add2,add3}
	
	local finadd = 0
	local index = 1
	for i =1,3 do
		if finadd < addtable[i] then
			finadd = addtable[i]
			index = i
		end		
	end
	

	if ntype == 1 then
		
		if finadd > 0 then
			T3ZhanGongGet_FinalInfo:SetText(ScriptGlobal_Format( "#{ZGMW_201009_26}", finadd))
			T3ZhanGongGet_Shine(index)
		else
			T3ZhanGongGet_FinalInfo:SetText("#{ZGMW_201009_27}")
		end
	
		if b7days ~= 1 then
			T3ZhanGongGet_FinalInfo:SetText("#{ZGMW_201009_28}")
		end
	else
		if finadd > 0 then
			T3ZhanGongGet_FinalInfo:SetText(ScriptGlobal_Format( "#{ZGMW_201009_55}", finadd))
			T3ZhanGongGet_Shine(index)
		else
			T3ZhanGongGet_FinalInfo:SetText("#{ZGMW_201009_56}")
		end	
	end
	
	--T3ZhanGongGet_FinalInfo:SetText("hahahahaha")
end

function T3ZhanGongGet_Shine(num)
	
	for i=1,3 do
		if i == num then
			g_T3ZhanGongGet_gold[i]:Show()
			g_T3ZhanGongGet_silver[i]:Hide()
		else
			g_T3ZhanGongGet_gold[i]:Hide()
			g_T3ZhanGongGet_silver[i]:Show()		
		end
	
	end

end


function T3ZhanGongGet_InitShangWuFrame(ntype,bfenghuang,beasyyanmen,bHardyanmen)

	local info =""
	local add = 0
	
	
	
	if bfenghuang == 1 or bHardyanmen == 1 then
		add = 800
	elseif beasyyanmen == 1 then
		add = 700
	end
	
	if ntype == 1 then
		if bfenghuang == 1 then
			if beasyyanmen == 1 or bHardyanmen == 1 then
				if bHardyanmen == 1 then
					info = info.."#{ZGMW_201009_17}#{ZGMW_201009_18}"
				else
					info = info.."#{ZGMW_201009_16}#{ZGMW_201009_18}"
				end
			
			else
				
				info = info.."#{ZGMW_201009_15}"
			end
		else
			if beasyyanmen == 1 or bHardyanmen == 1 then
				if bHardyanmen == 1 then
					info = info.."#{ZGMW_201009_17}"
				else
					info = info.."#{ZGMW_201009_16}"
				end
			
			else
				
				info = info.."#{ZGMW_201009_20}"
			end		
		
		end
		if add > 0 then
			info = info .. ScriptGlobal_Format( "#{ZGMW_201009_19}", add,add)
		end
		T3ZhanGongGet_Info2:SetText(info)
	
	else
		if bfenghuang == 1 then
			if beasyyanmen == 1 or bHardyanmen == 1 then
				if bHardyanmen == 1 then
					info = info.."#{ZGMW_201009_45}#{ZGMW_201009_46}"
				else
					info = info.."#{ZGMW_201009_44}#{ZGMW_201009_46}"
				end
			
			else
				
				info = info.."#{ZGMW_201009_43}"
			end
		else
			if beasyyanmen == 1 or bHardyanmen == 1 then
				if bHardyanmen == 1 then
					info = info.."#{ZGMW_201009_45}"
				else
					info = info.."#{ZGMW_201009_44}"
				end
			
			else
				
				info = info.."#{ZGMW_201009_48}"
			end		
		
		end
		if add > 0 then
			info = info .. ScriptGlobal_Format( "#{ZGMW_201009_47}", add)
		end
		T3ZhanGongGet_Info2:SetText(info)	
	end
	
	return add
end

function T3ZhanGongGet_InitT3battleFrame(ntype,guildtarget)

	
	local data = math.mod(guildtarget,10000)
	local result = math.floor(data/1000)
	local tableid = math.mod(data,1000)
	local name = Guild:GetT300CityName(tableid)
	local region = Guild:GetT300CityRegion(tableid)

	local add = 0
	
	if result == 3 then
		add = 1000
	elseif result == 4 then
		add = 900
	elseif result == 1 then
		local wintable = { [0] = 1000, [1] = 1100, [2] =1300, [3] = 1500}
		if wintable[region] ~= nil then
			add = wintable[region]
		end
	elseif result == 2 then
		local losetable = {[0]=900,[1]=1000,[2] = 1100, [3] = 1300}
		if losetable[region] ~= nil then
			add = losetable[region]
		end
	end
	local info = ""
	if ntype == 1 then
		if result == 0 then	--未参加
			info = "#{ZGMW_201009_25}"
		elseif result == 1 then	--正赛胜利
			info = ScriptGlobal_Format( "#{ZGMW_201009_22}", name)
		elseif result == 2 then	--正赛失败
			info = ScriptGlobal_Format( "#{ZGMW_201009_23}", name)
		elseif result == 3 then --演习赛胜利
			info = ScriptGlobal_Format( "#{ZGMW_201009_63}", name)
		elseif result == 4 then --演习赛失败
			info = ScriptGlobal_Format( "#{ZGMW_201009_64}", name)
		end
	else
		if result == 0 then	--未参加
			info = "#{ZGMW_201009_54}"
		elseif result == 1 then	--正赛胜利
			info = ScriptGlobal_Format( "#{ZGMW_201009_49}", name)
		elseif result == 2 then	--正赛失败
			info = ScriptGlobal_Format( "#{ZGMW_201009_50}", name)
		elseif result == 3 then --演习赛胜利
			info = ScriptGlobal_Format( "#{ZGMW_201009_51}", name)
		elseif result == 4 then --演习赛失败
			info = ScriptGlobal_Format( "#{ZGMW_201009_52}", name)
		end	
	
	end
	if add > 0 then
		if ntype == 1 then
			info = info .. ScriptGlobal_Format( "#{ZGMW_201009_24}", add)
		else
			info = info .. ScriptGlobal_Format( "#{ZGMW_201009_53}", add)
		end		
	end
	T3ZhanGongGet_Info3:SetText(info)
	return add
end

function T3ZhanGongGet_InitLianjinFrame(ntype,blianjin)
	local add = 0;
	if blianjin == 1 then
		add = 800
	end
	if ntype == 1 then
		if blianjin == 1 then
			T3ZhanGongGet_Info1:SetText("#{ZGMW_201009_12}")
		else
			T3ZhanGongGet_Info1:SetText("#{ZGMW_201009_13}")
		end
	else
		if blianjin == 1 then
			T3ZhanGongGet_Info1:SetText("#{ZGMW_201009_41}")
		else
			T3ZhanGongGet_Info1:SetText("#{ZGMW_201009_42}")
		end		
	end

	return add
end
function T3ZhanGongGet_InitMainFrame(ntype)
	if ntype == 1 then
		T3ZhanGongGet_Citychoice_DragTitle:SetText("#{ZGMW_201009_09}")
		T3ZhanGongGet_ExplainText:SetText("#{ZGMW_201009_10}")
		T3ZhanGongGet_Text1:Hide()
		T3ZhanGongGet_Text2:Hide()
		T3ZhanGongGet_Text3:Hide()
		T3ZhanGongGet_Help2:Hide()
		T3ZhanGongGet_Help3:Hide()
		T3ZhanGongGet_OK:Show()
	else
		T3ZhanGongGet_Citychoice_DragTitle:SetText("#{ZGMW_201009_39}")
		T3ZhanGongGet_ExplainText:SetText("#{ZGMW_201009_40}")

		
		T3ZhanGongGet_Help2:Show()
		T3ZhanGongGet_Help3:Show()
		
		T3ZhanGongGet_Text1:Show()
		T3ZhanGongGet_Text1:SetText("#{ZGMW_201009_68}")
		T3ZhanGongGet_Text2:Show()
		T3ZhanGongGet_Text2:SetText("#{ZGMW_201009_69}")
		T3ZhanGongGet_Text3:Show()
		T3ZhanGongGet_Text3:SetText("#{ZGMW_201009_70}")
		
		T3ZhanGongGet_OK:Hide()
	end
end

function T3ZhanGongGet_CareObj()
	if(tonumber(arg0) ~= g_objCareID) then
		return;
	end
	--如果和NPC的距离大于一定距离或者被删除，自动关闭
	if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
		--取消关心
		T3ZhanGongGet_StopCareObject(g_objCareID)
		T3ZhanGongGet_On_Hide()
	end		
end

function T3ZhanGongGet_StopCareObject(objCaredId)
	this:CareObject(objCaredId, 0, "T3ZhanGongGet");
	g_objCareID = -1;
end

function T3ZhanGongGet_BeginCareObject(objid)
	g_objCareID = objid
	this:CareObject(g_objCareID, 1, "T3ZhanGongGet");
end

function T3ZhanGongGet_On_ResetPos()
	T3ZhanGongGet:SetProperty("UnifiedPosition", g_T3ZhanGongGet_UnifiedPosition)
end

function T3ZhanGongGet_On_Hide()
	this:Hide()
end

function T3ZhanGongGet_Close_Click()
end


function T3ZhanGongGet_CloseFrame()
	this:Hide()
end

function T3ZhanGongGet_Help2_Clicked()
	PushEvent("CCSHOP_HELP","124")
end

function T3ZhanGongGet_Help3_Clicked()
	if Player:GetData("Is2606S") == 1 then
		PushDebugMessage("#{QXF_260623_155}")
	else		
		PushEvent("CCSHOP_HELP","125")
	end
end



function T3ZhanGongGet_OnOKClicked()


	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("GetAward");
		Set_XSCRIPT_ScriptID(888300);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();

end
