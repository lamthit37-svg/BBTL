-------------------------------------------------------
--家园珍兽觉醒新界面 by lishilong 2016-9-1
-----------------------------------------------------------

local g_bDebug 					= 0
local MAX_OBJ_DISTANCE	 		= 3.0
local g_nObjCaredID 			= -1
local g_MAX_PETBANK_NUMBER  	= 10 		-- 珍兽银行容器的大小
local g_MAX_PET_NUMBER 			= 10		-- 最大珍兽携带上限
local g_MAX_JYSL_LEVEL			= 5			-- 最大家园兽栏等级
local g_bOpenOutside			= 0			-- 是否在家园外打开该界面
local g_nExpOpenOutSide			= 33980		-- 家园外面打开该界面的觉醒经验
local g_nCostMoneyOpenOutSide	= 13800		-- 家园外面打开该界面的觉醒消耗金钱
local g_tabAwakeInfo 			= 			-- 觉醒经验
								{
									[1] = {nExp = 33980, nCostFood = 80, nCostMoney = 13800},
									[2] = {nExp = 37840, nCostFood = 160, nCostMoney = 15400},
									[3] = {nExp = 41700, nCostFood = 240, nCostMoney = 16900},
									[4] = {nExp = 45560, nCostFood = 320, nCostMoney = 18500},
									[5] = {nExp = 49420, nCostFood = 400, nCostMoney = 20000},
								}
local g_tabLevelMsg 			= 			-- 字典提示：第x档
								{
									[1] = "#{JYSL_160518_117}",
									[2] = "#{JYSL_160518_118}",
									[3] = "#{JYSL_160518_119}",
									[4] = "#{JYSL_160518_120}",
									[5] = "#{JYSL_160518_121}",
								}
local g_tabPetHeadControl 		= {}		-- 显示珍兽头像的控件
local g_tabPetHeadFlashControl 	= {}		-- 显示珍兽头像闪光的控件
local g_tabPetHeadFlashTimer 	= {}		-- 显示珍兽头像闪光的timer
local g_tabPetUpInfoControl 	= {}		-- 显示珍兽升级信息的控件
local g_tabPetNameControl 		= {}		-- 显示珍兽名字信息的控件
local g_tabPetExpControl 		= {}		-- 显示珍兽经验信息的控件
local g_tabPetCloseControl 		= {}		-- 取消该珍兽的控件

-- 全局变量
--local g_nCurSelectType			= 0			-- 0是随身携带的珍兽；1是珍兽银行
--local g_nCurSelectIndex			= -1		-- 当前选择的珍兽index
local g_nCurSelectIndex0		= -1		-- 当前选择的珍兽index 随身珍兽
local g_nCurSelectIndex1		= -1		-- 当前选择的珍兽index 银行珍兽
local g_nJYSLLevel				= -1		-- 家园兽栏等级
local g_nOwnJYFood				= 0			-- 拥有家园食材数量
local g_nCurSLSelectedLevel		= -1		-- 选择的升级level
local g_bIsAwaked				= 0			-- 玩家今天是否觉醒过
local g_tabInputedPetInfo 		= 			-- 放入珍兽的信息
			{
			[1] = {bPut = 0 , bFlash = 0, nHigh = 0, nLow = 0, strIconName = "", strPetName = ""},
			[2] = {bPut = 0 , bFlash = 0, nHigh = 0, nLow = 0, strIconName = "", strPetName = ""},
			[3] = {bPut = 0 , bFlash = 0, nHigh = 0, nLow = 0, strIconName = "", strPetName = ""},
			[4] = {bPut = 0 , bFlash = 0, nHigh = 0, nLow = 0, strIconName = "", strPetName = ""},
			[5] = {bPut = 0 , bFlash = 0, nHigh = 0, nLow = 0, strIconName = "", strPetName = ""},
			}
			
function BieYePetBar_Awake_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false) 
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	-- 互斥界面
	this:RegisterEvent("TOGLE_PETBANK") 				-- 打开珍兽银行界面事件
	this:RegisterEvent("TOGLE_PET_PAGE") 				-- 打开角色pet界面
	
	-- 金钱刷新
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	
	-- 需要刷新数据的消息
	this:RegisterEvent("TOGLE_PETLIST_PETNUM_CHNAGE")	-- 珍兽数量变化
	this:RegisterEvent("DELETE_PET")					-- 珍兽删除
	this:RegisterEvent("UPDATE_PET_PAGE")				-- 珍兽信息刷新
	this:RegisterEvent("TOGLE_PETLIST_SELECT_CHNAGE")	-- 珍兽银行操作
	
end

function BieYePetBar_Awake_OnLoad()
	g_tabPetHeadControl[1] 			= BieYePetBar_Awake_Pet_Tu1
	g_tabPetHeadControl[2] 			= BieYePetBar_Awake_Pet_Tu2
	g_tabPetHeadControl[3] 			= BieYePetBar_Awake_Pet_Tu3
	g_tabPetHeadControl[4] 			= BieYePetBar_Awake_Pet_Tu4
	g_tabPetHeadControl[5] 			= BieYePetBar_Awake_Pet_Tu5
	
	g_tabPetHeadFlashControl[1] 	= BieYePetBar_Awake_Pet_Tu1_Animate
	g_tabPetHeadFlashControl[2] 	= BieYePetBar_Awake_Pet_Tu2_Animate
	g_tabPetHeadFlashControl[3] 	= BieYePetBar_Awake_Pet_Tu3_Animate
	g_tabPetHeadFlashControl[4] 	= BieYePetBar_Awake_Pet_Tu4_Animate
	g_tabPetHeadFlashControl[5] 	= BieYePetBar_Awake_Pet_Tu5_Animate
	
	g_tabPetHeadFlashTimer[1] 		= BieYePetBar_Awake_Pet_Tu1_StopWatch
	g_tabPetHeadFlashTimer[2] 		= BieYePetBar_Awake_Pet_Tu2_StopWatch
	g_tabPetHeadFlashTimer[3] 		= BieYePetBar_Awake_Pet_Tu3_StopWatch
	g_tabPetHeadFlashTimer[4] 		= BieYePetBar_Awake_Pet_Tu4_StopWatch
	g_tabPetHeadFlashTimer[5] 		= BieYePetBar_Awake_Pet_Tu5_StopWatch
	
	g_tabPetNameControl[1]			= BieYePetBar_Awake_Pet_Tu1_text
	g_tabPetNameControl[2]			= BieYePetBar_Awake_Pet_Tu2_text
	g_tabPetNameControl[3]			= BieYePetBar_Awake_Pet_Tu3_text
	g_tabPetNameControl[4]			= BieYePetBar_Awake_Pet_Tu4_text
	g_tabPetNameControl[5]			= BieYePetBar_Awake_Pet_Tu5_text
	
	g_tabPetUpInfoControl[1]		= BieYePetBar_Awake_Pet_Tu1_textID
	g_tabPetUpInfoControl[2]		= BieYePetBar_Awake_Pet_Tu2_textID
	g_tabPetUpInfoControl[3]		= BieYePetBar_Awake_Pet_Tu3_textID
	g_tabPetUpInfoControl[4]		= BieYePetBar_Awake_Pet_Tu4_textID
	g_tabPetUpInfoControl[5]		= BieYePetBar_Awake_Pet_Tu5_textID
	
	g_tabPetExpControl[1]			= BieYePetBar_Awake_Pet_Tu1_EXPLace
	g_tabPetExpControl[2]			= BieYePetBar_Awake_Pet_Tu2_EXPLace
	g_tabPetExpControl[3]			= BieYePetBar_Awake_Pet_Tu3_EXPLace
	g_tabPetExpControl[4]			= BieYePetBar_Awake_Pet_Tu4_EXPLace
	g_tabPetExpControl[5]			= BieYePetBar_Awake_Pet_Tu5_EXPLace
	
	g_tabPetCloseControl[1]			= BieYePetBar_Awake_Pet_Tu1_Close
	g_tabPetCloseControl[2]			= BieYePetBar_Awake_Pet_Tu2_Close
	g_tabPetCloseControl[3]			= BieYePetBar_Awake_Pet_Tu3_Close
	g_tabPetCloseControl[4]			= BieYePetBar_Awake_Pet_Tu4_Close
	g_tabPetCloseControl[5]			= BieYePetBar_Awake_Pet_Tu5_Close
	
end

function BieYePetBar_Awake_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 920160901 ) then
		
		-- 操作类型，0关闭界面，1打开界面，2放入珍兽检测返回, 3为特殊刷新
		local bOpType = Get_XParam_INT(0)
		if nil == bOpType then
			return
		end
		
		-- 关闭界面
		if 0 == bOpType then
			BieYePetBar_Awake_Close()
			return
		end
		
		-- 放入一个珍兽
		if 2 == bOpType and this:IsVisible() then
			local bRet			= Get_XParam_INT(1)
			local nInputPos 	= Get_XParam_INT(2)
			
			if nil == nInputPos or nil == bRet then
				return
			end
			
			-- 检测不通过，取消放入
			if 0 == bRet then
				BieYePetBar_Awake_Pet_Tu_RClick(nInputPos)
			end
			
			-- 刷新界面
			BieYePetBar_Awake_Update()
			return
		end
		
		-- 特殊刷新，成功觉醒以后，只更新食物数量、觉醒状态
		if 3 == bOpType and this:IsVisible() then
			--local nOwnJYFood	= Get_XParam_INT(1)
			
			--if nil == nOwnJYFood then
			--	return
			--end		
			--if nOwnJYFood < 0 then
			--	return
			--end
			--g_nOwnJYFood = nOwnJYFood
			g_bIsAwaked = 1
			-- 觉醒成功后刷新界面
			BieYePetBar_Awake_Update_Inside(1)
			return
		end
		
		-- 等级限制
		if Player:GetLevel() < 75 then
			PushDebugMessage("#{JYSL_160518_284}");
			return 
		end
		
		-- 打开界面
		local targetId = Get_XParam_INT(1)
		local ObjCaredID = DataPool : GetNPCIDByServerID( targetId )
		
		--关注npc
		if nil == ObjCaredID or -1 == ObjCaredID then
			--PushDebugMessage("server传过来的数据有问题。")
			return
		end
		
		g_nObjCaredID = ObjCaredID
		BeginCareObject_BieYePetBar_Awake()
		
		-- 家园兽栏等级
		g_nJYSLLevel = Get_XParam_INT(2)
		if nil == g_nJYSLLevel then
			return
		end
		-- 兽栏等级0表示在家园外面打开兽栏，1-5为正常兽栏等级
		if g_nJYSLLevel < 0 or g_nJYSLLevel > g_MAX_JYSL_LEVEL then
			return
		end
		
		-- 是否是在家园外面打开觉醒界面
		if 0 == g_nJYSLLevel then
			g_bOpenOutside = 1
		else
			g_bOpenOutside = 0
		end
		
		-- 拥有家园食材数量 废弃
		--g_nOwnJYFood = Get_XParam_INT(3)
		--if nil == g_nOwnJYFood then
		--	return
		--end
		--if g_nOwnJYFood < 0 then
		--	return
		--end
		
		-- 是否觉醒过
		g_bIsAwaked = Get_XParam_INT(4)
		if nil == g_bIsAwaked then
			return
		end
		if 0 ~= g_bIsAwaked and 1 ~=  g_bIsAwaked then
			return
		end
		
		-- 增加界面互斥关闭逻辑
		if(IsWindowShow("TargetPet")) then
			CloseWindow("TargetPet", true)
		end
		
		if(IsWindowShow("TargetPet2")) then
			CloseWindow("TargetPet2", true)
		end
		
		if(IsWindowShow("Pet")) then
			CloseWindow("Pet", true)
		end
		
		if(IsWindowShow("PetBankMain")) then
			CloseWindow("PetBankMain", true)
		end
		
		if(IsWindowShow("BieYePetBar")) then
			CloseWindow("BieYePetBar", true)
		end
	
		if(IsWindowShow("PetXuelizi")) then
			CloseWindow("PetXuelizi", true)
		end
	
		--更新数据
		BieYePetBar_Awake_Reset()
		BieYePetBar_Awake_Update()
		--显示界面
		this:Show()

	elseif ( event == "OBJECT_CARED_EVENT" ) then
		if(tonumber(arg0) ~= g_nObjCaredID) then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy") then
			--关闭界面
			BieYePetBar_Awake_Close()
		end	
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		--关闭界面
		BieYePetBar_Awake_Close()
	
	-- 互斥界面
	elseif ( event == "TOGLE_PETBANK" or event == "TOGLE_PET_PAGE") then
		--关闭界面
		BieYePetBar_Awake_Close()
	
	-- 金钱变更
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		BieYePetBar_Awake_MoneyUpdate()
		
	-- 刷新数据消息
	elseif ( event == "TOGLE_PETLIST_PETNUM_CHNAGE" or event == "DELETE_PET" 
			or event == "UPDATE_PET_PAGE" or event == "TOGLE_PETLIST_SELECT_CHNAGE") then
		if this:IsVisible() then
			--更新数据
			BieYePetBar_Awake_Update()			
		end
	end

end

--=========================================================
-- 更新界面
--=========================================================
function BieYePetBar_Awake_Update()
	BieYePetBar_Awake_Update_Inside(0)
end

--=========================================================
-- 更新界面(带刷新参数)
--=========================================================
function BieYePetBar_Awake_Update_Inside(bSucess)
	MyDebug("BieYePetBar_Awake_Update")
	-- 珍兽选择列表清空
	--BieYePetBar_Awake_List : ClearListBox()
	BieYePetBar_Awake_List01 : ClearListBox()
	BieYePetBar_Awake_List02 : ClearListBox()
	
	-- 刷新金钱
	BieYePetBar_Awake_MoneyUpdate()
	
	-- 当前服务器天数
	-- 感觉用处不大，还是调一下吧
	AskServerTimeAgain()
	local nServerDayTime = tonumber(DataPool:GetServerDayTime())
	local nRealPos = 0
	
	-- 获取每个珍兽可获得的经验和消耗的金钱
	local nPerExp = 0
	local nPerCostMoney = 0
	if 1 == g_bOpenOutside then
		nPerExp = g_nExpOpenOutSide
		nPerCostMoney = g_nCostMoneyOpenOutSide
	else
		if nil == g_nCurSLSelectedLevel then
			return
		end
		if g_nCurSLSelectedLevel < 1 or g_nCurSLSelectedLevel > g_MAX_JYSL_LEVEL then
			return
		end
		nPerExp = g_tabAwakeInfo[g_nCurSLSelectedLevel].nExp
		nPerCostMoney = g_tabAwakeInfo[g_nCurSLSelectedLevel].nCostMoney
	end
	
	-- 珍兽列表，这里列表出来的是存在珍兽的索引计数，并非存储的索引计数
	-- 遍历珍兽银行
	for i=0, g_MAX_PETBANK_NUMBER-1 do
		if 1 == Pet:IsPresent_PetBank(i) then
			local szPetName, nXiedaiLevl, nCurrentLevel, szOn = Pet:GetPetList_Appoint_PetBank(i)
			local nHigh, nLow = Pet:GetPetGUIDByIndex_PetBank(i)
			if nil ~= szPetName and "" ~= szPetName then
				local nTakeLevel = Pet:GetAllPetTakeLevelByGUID(nHigh, nLow)
				local strToolTips = ""
				if nil ~= nTakeLevel and nTakeLevel < 55 then
					-- 灰色无法觉醒
					szPetName = "#c808080" .. szPetName .. "#{JYSL_160518_50}"
				else
					local bPuted = IsHaveGUID(nHigh, nLow)
					if 1 == bPuted then
						-- 灰色显示
						--szPetName = "#c808080" .. szPetName
						-- 绿色显示
						szPetName = "#G" .. szPetName
					end
					local nToBeGrade, nToBeLevel, nCurNeedExp, nPetTradeTime, 
						nCurExp, nJinJieGrade, nJinJieLevel = Pet:GetCanBeJinJieInfo(
						nHigh, nLow, nPerExp)
									
					-- 显示疲劳状态
					if nil ~= nPetTradeTime then
						if nPetTradeTime == nServerDayTime then
							szPetName = "#c808080"..szPetName.."#{JYSL_160518_195}"
						else
							-- 增加显示阶级				
							if nil ~= nJinJieGrade and nil ~= nJinJieLevel then
								local strEx = ""
								if nJinJieGrade >= 10 then
									strEx = "#{JYSL_160518_179}"
								else
									strEx = ScriptGlobal_Format("#{JYSL_160518_178}", nJinJieGrade, nJinJieLevel)
								end
								szPetName = szPetName..strEx
							end
						end
					end
				end
					
				-- 显示加锁状态
				if (1 == PlayerPackage:IsPetLock(i, 1))  then
					local nUnlockElapsedTime = PlayerPackage:GetPUnlockElapsedTime_Pet(i, 1)
					if( nUnlockElapsedTime == 0 ) then
						szPetName = szPetName.. "#-05"
						strToolTips =  "已加锁"
					else
						szPetName = szPetName.. "#-10"
						local strLeftTime = g_GetUnlockingStr(nUnlockElapsedTime)
						strToolTips =  strLeftTime
					end	
				end
					
				BieYePetBar_Awake_List02 : AddItem(szPetName, nRealPos)
				BieYePetBar_Awake_List02 : SetItemTooltip( nRealPos, strToolTips )
				nRealPos = nRealPos + 1
			end
		end
	end
		
	nRealPos = 0
	-- 遍历随身珍兽
	for i=0, g_MAX_PET_NUMBER-1 do
		if true == Pet:IsPresent(i) then
			local szPetName,szOn = Pet:GetPetList_Appoint(i)
			local nHigh, nLow = Pet:GetGUID(i)
			if nil ~= szPetName and "" ~= szPetName then
				local nTakeLevel = Pet:GetAllPetTakeLevelByGUID(nHigh, nLow)
				if nil ~= nTakeLevel and nTakeLevel < 55 then
					-- 灰色无法觉醒
					szPetName = "#c808080" .. szPetName .. "#{JYSL_160518_50}"
				else
					local bPuted = IsHaveGUID(nHigh, nLow)
					if 1 == bPuted then
						-- 灰色显示
						--szPetName = "#c808080" .. szPetName
						-- 绿色显示
						szPetName = "#G" .. szPetName
					end
					local nToBeGrade, nToBeLevel, nCurNeedExp, nPetTradeTime, 
						nCurExp, nJinJieGrade, nJinJieLevel = Pet:GetCanBeJinJieInfo(
						nHigh, nLow, nPerExp)
									
					-- 显示疲劳状态
					if nil ~= nPetTradeTime then
						if nPetTradeTime == nServerDayTime then
							szPetName = "#c808080"..szPetName.."#{JYSL_160518_195}"
						else
							-- 增加显示阶级				
							if nil ~= nJinJieGrade and nil ~= nJinJieLevel then
								local strEx = ""
								if nJinJieGrade >= 10 then
									strEx = "#{JYSL_160518_179}"
								else
									strEx = ScriptGlobal_Format("#{JYSL_160518_178}", nJinJieGrade, nJinJieLevel)
								end
								szPetName = szPetName..strEx
							end
						end
					end		
				end
				
				-- 显示加锁状态
				if (1 == PlayerPackage:IsPetLock(i, 0))  then
					local nUnlockElapsedTime = PlayerPackage:GetPUnlockElapsedTime_Pet(i, 0)
					if( nUnlockElapsedTime == 0 ) then
						szPetName = szPetName.. "#-05"
						strToolTips =  "已加锁"
					else
						szPetName = szPetName.. "#-10"
						local strLeftTime = g_GetUnlockingStr(nUnlockElapsedTime)
						strToolTips =  strLeftTime
					end	
				end
				
				BieYePetBar_Awake_List01 : AddItem(szPetName, nRealPos)
				BieYePetBar_Awake_List01 : SetItemTooltip( nRealPos, strToolTips )
				nRealPos = nRealPos + 1
			end
		end
	end
	
	-- 设置列表选择
	BieYePetBar_Awake_List01 : SetItemSelectByItemID(g_nCurSelectIndex0)
	BieYePetBar_Awake_List02 : SetItemSelectByItemID(g_nCurSelectIndex1)
	
	-- 刷新觉醒经验
	--local strMsg = ScriptGlobal_Format("#{JYSL_160518_123}", g_tabAwakeInfo[g_nCurSLSelectedLevel].nExp)
	BieYePetBar_Awake_PetLevel_Get:SetText("#{JYSL_160518_196}")
	local strMsg = ScriptGlobal_Format("#{JYSL_160518_123}", nPerExp)
	BieYePetBar_Awake_PetLevel_Gettext:SetText(strMsg)
	
	-- 放入珍兽数量
	local nInputPetNum = 0
	
	-- 刷新已放入珍兽信息
	for i = 1, table.getn( g_tabInputedPetInfo ) do
		if 1 == g_tabInputedPetInfo[i].bPut then
			-- 显示珍兽头像的控件
			g_tabPetHeadControl[i]:SetProperty("Empty", "False")
			g_tabPetHeadControl[i]:SetProperty("NormalImage", tostring(g_tabInputedPetInfo[i].strIconName) )
			
			-- 显示珍兽升级信息的控件
			local nToBeGrade, nToBeLevel, nCurNeedExp, nPetTradeTime, 
				nCurExp, nJinJieGrade, nJinJieLevel  = Pet:GetCanBeJinJieInfo(
				g_tabInputedPetInfo[i].nHigh, 
				g_tabInputedPetInfo[i].nLow, 
				nPerExp)
			local strMsg = ""
			--if nil == nToBeGrade or nil == nToBeLevel then
			--	strMsg = "Error"
			--else
			--	strMsg = "#{JYSL_160518_124}"..tostring(nToBeGrade).."#{JYSL_160518_125}"..tostring(nToBeLevel).."#{JYSL_160518_126}"
			--end
			-- 改为显示当前阶级
			if nil == nJinJieGrade or nil == nJinJieLevel then
				strMsg = "Error"
			else
				strMsg = ScriptGlobal_Format("#{JYSL_160518_124}", nJinJieGrade, nJinJieLevel)
			end
			g_tabPetUpInfoControl[i]:SetText(strMsg)
			
			-- 显示珍兽名字信息的控件
			g_tabPetNameControl[i]:SetText(tostring(g_tabInputedPetInfo[i].strPetName))
			
			-- 显示珍兽经验信息的控件
			if nil == nCurExp or nil == nCurNeedExp then
				strMsg = "Error"
			else
				strMsg = ScriptGlobal_Format("#{JYSL_160518_171}", nCurExp, nCurNeedExp)
				g_tabPetExpControl[i]:SetProgress(nCurExp / nCurNeedExp, 1.0)
			end
			g_tabPetExpControl[i]:SetToolTip(strMsg)
			
			-- 取消该珍兽的控件 设置为可用
			g_tabPetCloseControl[i]:Enable()
			
			-- 播放升级特效，增加升级提示
			if 1 == bSucess and 1 == g_tabInputedPetInfo[i].bFlash then
				g_tabPetHeadFlashControl[i] :Play(true)
				g_tabPetHeadFlashTimer[i] : SetProperty("Timer", "1.8")
				g_tabInputedPetInfo[i].bFlash = 0
				
				-- 升级提示
				--local strMsg = ScriptGlobal_Format("#{JYSL_160518_281}", 
				--	g_tabInputedPetInfo[i].strPetName, nJinJieGrade, nJinJieLevel)
				--PushDebugMessage(strMsg)
			end
			
			nInputPetNum = nInputPetNum + 1
		end
	end
	
	-- 刷新消耗材料、金钱
	--local nCostFood = g_tabAwakeInfo[g_nCurSLSelectedLevel].nCostFood * nInputPetNum
	local nCostMoney = nPerCostMoney * nInputPetNum
	
	BieYePetBar_Awake_CostJiaozi_Money : SetProperty( "MoneyNumber", tostring(nCostMoney))
	
	-- 刷新拥有食材数量
	--if nil == g_nOwnJYFood then
	--	return
	--end
	--if g_nOwnJYFood < 0 then
	--	return
	--end
	
	--local strCostFood = ScriptGlobal_Format("#{JYSL_160518_128}", nCostFood)
	--BieYePetBar_Awake_Consumefood_Text : SetText(strCostFood)
	--local strOwnJYFood = ""
	--if g_nOwnJYFood >= nCostFood then 
	--	strOwnJYFood = ScriptGlobal_Format("#{JYSL_160518_129}", g_nOwnJYFood)
	--else
	--	strOwnJYFood = ScriptGlobal_Format("#{JYSL_160518_176}", g_nOwnJYFood)
	--end
	--BieYePetBar_Awake_Ownfood_Text : SetText(strOwnJYFood)	
	
	-- 设置觉醒按钮是否可用，介绍tips
	if 0 == g_bIsAwaked then
		BieYePetBar_Awake_Pet_Button1 : Enable()
		--BieYePetBar_Awake_Pet_Button1 : PlayWarning( 0 )
		--BieYePetBar_Awake_Pet_Button1 : PlayWarning( 1 )
		BieYePetBar_Awake_Pet_Button1 : SetToolTip("#{JYSL_160518_174}")
		if 1 == g_bOpenOutside then
			BieYePetBar_Awake_Frame_Infotips : SetText("#{JYSL_160518_291}")
		else
			BieYePetBar_Awake_Frame_Infotips : SetText("#{JYSL_160518_173}")
		end	
	elseif 1 == g_bIsAwaked then
		BieYePetBar_Awake_Pet_Button1 : Disable()
		--BieYePetBar_Awake_Pet_Button1 : PlayWarning( 0 )
		BieYePetBar_Awake_Pet_Button1tips : SetToolTip("#{JYSL_160518_175}")
		if 1 == g_bOpenOutside then
			BieYePetBar_Awake_Frame_Infotips : SetText("#{JYSL_160518_290}")
		else
			BieYePetBar_Awake_Frame_Infotips : SetText("#{JYSL_160518_172}")
		end
	end
end

--=========================================================
-- 觉醒
--=========================================================
function BieYePetBar_Awake_Promote_Click()
	MyDebug("BieYePetBar_Awake_Promote_Click")
	-- 调用服务器脚本
	
	-- 获取觉醒经验和觉醒等级
	local nPerExp = 0
	local nAwakeLevel = 0
	if 1 == g_bOpenOutside then
		nPerExp = g_nExpOpenOutSide
		nAwakeLevel = 0
	else
		if nil == g_nCurSLSelectedLevel then
			return
		end
		if g_nCurSLSelectedLevel < 1 or g_nCurSLSelectedLevel > g_MAX_JYSL_LEVEL then
			return
		end
		nPerExp = g_tabAwakeInfo[g_nCurSLSelectedLevel].nExp
		nAwakeLevel = g_nCurSLSelectedLevel
	end
	
	-- 可升级珍兽闪光
	for i = 1, table.getn( g_tabInputedPetInfo ) do
		-- 重置珍兽flash信息
		g_tabInputedPetInfo[i].bFlash = 0
		if 1 == g_tabInputedPetInfo[i].bPut then
				
			-- 显示珍兽升级信息的控件
			local nToBeGrade, nToBeLevel, nCurNeedExp, nPetTradeTime, 
				nCurExp, nJinJieGrade, nJinJieLevel  = Pet:GetCanBeJinJieInfo(
				g_tabInputedPetInfo[i].nHigh, 
				g_tabInputedPetInfo[i].nLow, 
				nPerExp)
			if nToBeGrade ~= nJinJieGrade or nToBeLevel ~= nJinJieLevel then
				g_tabInputedPetInfo[i].bFlash = 1
				--g_tabPetHeadFlashControl[i] :Play(true)
				--g_tabPetHeadFlashTimer[i] : SetProperty("Timer", "1.8")
			end
		end
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnPetAwake" )
		Set_XSCRIPT_ScriptID( 892305 )
		Set_XSCRIPT_Parameter( 0, nAwakeLevel )
		Set_XSCRIPT_Parameter( 1, g_tabInputedPetInfo[1].nHigh )
		Set_XSCRIPT_Parameter( 2, g_tabInputedPetInfo[1].nLow )
		Set_XSCRIPT_Parameter( 3, g_tabInputedPetInfo[2].nHigh )
		Set_XSCRIPT_Parameter( 4, g_tabInputedPetInfo[2].nLow )
		Set_XSCRIPT_Parameter( 5, g_tabInputedPetInfo[3].nHigh )
		Set_XSCRIPT_Parameter( 6, g_tabInputedPetInfo[3].nLow )
		Set_XSCRIPT_Parameter( 7, g_tabInputedPetInfo[4].nHigh )
		Set_XSCRIPT_Parameter( 8, g_tabInputedPetInfo[4].nLow )
		Set_XSCRIPT_Parameter( 9, g_tabInputedPetInfo[5].nHigh )
		Set_XSCRIPT_Parameter( 10, g_tabInputedPetInfo[5].nLow )
		Set_XSCRIPT_ParamCount( 11 )
	Send_XSCRIPT()
end

--=========================================================
-- 选择觉醒等级鼠标按下的事件，做提示用
--=========================================================
function BieYePetBar_Awake_PetLevel_PreClick()
	-- 外部打开无法选择等级
	if 1 == g_bOpenOutside then
		PushDebugMessage("#{JYSL_160518_286}")
		PushDebugMessage("#{JYSL_160518_293}")
		return
	end
end

--=========================================================
-- 选择觉醒等级
--=========================================================
function BieYePetBar_Awake_PetLevel_Select_Click()
	MyDebug("BieYePetBar_Awake_PetLevel_Select_Click")
	
	-- 外部打开无法选择等级
	if 1 == g_bOpenOutside then
		return
	end
	
	-- 获得选中的等级
	local strContext, nSelected = BieYePetBar_Awake_PetLevel_Select:GetCurrentSelect()
	if nil == nSelected then
		return
	end
	g_nCurSLSelectedLevel = nSelected + 1
	if g_nCurSLSelectedLevel < 1 or g_nCurSLSelectedLevel > g_MAX_JYSL_LEVEL then
		return
	end
	
	-- 选择觉醒等级大于兽栏等级
	if g_nCurSLSelectedLevel > g_nJYSLLevel then
		g_nCurSLSelectedLevel = g_nJYSLLevel
		local strMsg = ScriptGlobal_Format("#{JYSL_160518_122}", 
			g_tabLevelMsg[g_nJYSLLevel], g_tabLevelMsg[g_nJYSLLevel])
		PushDebugMessage(strMsg)
	end
	
	BieYePetBar_Awake_PetLevel_Select:SetCurrentSelect(g_nCurSLSelectedLevel-1)
	BieYePetBar_Awake_Update()
end

--=========================================================
-- 珍兽列表选择 左键
--=========================================================
function BieYePetBar_Awake_List_Selected(bIsPetBank)
	MyDebug("BieYePetBar_Awake_List_Selected")
	if 1 == bIsPetBank then
		g_nCurSelectIndex1 = BieYePetBar_Awake_List02:GetFirstSelectItem()
	else
		g_nCurSelectIndex0 = BieYePetBar_Awake_List01:GetFirstSelectItem()
	end
	
end

--=========================================================
-- 珍兽列表 右键点击珍兽
--=========================================================
function BieYePetBar_Awake_List_RClick(bIsPetBank)	
	MyDebug("BieYePetBar_Awake_List_RClick")
	if 1 == bIsPetBank then
		-- 珍兽银行
		local nRealPos = BieYePetBar_GetRealIndexPetBank(g_nCurSelectIndex1)
		if nRealPos < 0 or nRealPos >= g_MAX_PETBANK_NUMBER then
			return
		end
		if(IsWindowShow("TargetPet")) then
			CloseWindow("TargetPet", true)
		end
		if(IsWindowShow("TargetPet2")) then
		   CloseWindow("TargetPet2", true)
		end
		Pet:ShowTargetPet_PetBank(nRealPos)
	else
		-- 随身珍兽
		local nRealPos = BieYePetBar_GetRealIndexPet(g_nCurSelectIndex0)
		if nRealPos < 0 or nRealPos >= g_MAX_PET_NUMBER then
			return
		end
		if(IsWindowShow("TargetPet")) then
			CloseWindow("TargetPet", true)
		end
		if(IsWindowShow("TargetPet2")) then
		   CloseWindow("TargetPet2", true)
		end
		Pet:ShowBagSelectPet_PetBank(nRealPos)
	end
end

--=========================================================
-- 珍兽列表 双击点击珍兽
--=========================================================
function BieYePetBar_Awake_List_DoubleClick(bIsPetBank)
	MyDebug("BieYePetBar_Awake_List_DoubleClick")
	local nHigh = 0
	local nLow = 0
	local strIconName = ""
	local strPetName = ""
	-- 得到被选择珍兽的GUID
	if 1 == bIsPetBank then
		if g_nCurSelectIndex1 < 0 then 
			PushDebugMessage("请从珍兽仓库列表中选择一个珍兽")
			return 
		end
		-- 珍兽银行
		local nRealPos = BieYePetBar_GetRealIndexPetBank(g_nCurSelectIndex1)
		if nRealPos < 0 or nRealPos >= g_MAX_PETBANK_NUMBER then
			return
		end
		
		if 1 == Pet:IsPresent_PetBank(nRealPos) then
			strPetName = Pet:GetPetList_Appoint_PetBank(nRealPos)
			nHigh, nLow = Pet:GetPetGUIDByIndex_PetBank(nRealPos)
			strIconName = Pet:GetPetBankPortraitByIndex(nRealPos)
		end
		
	else
		if g_nCurSelectIndex0 < 0 then 
			PushDebugMessage("请从携带的珍兽列表中选择一个珍兽")
			return 
		end
		-- 随身珍兽
		local nRealPos = BieYePetBar_GetRealIndexPet(g_nCurSelectIndex0)
		if nRealPos < 0 or nRealPos >= g_MAX_PET_NUMBER then
			return
		end
		
		if true == Pet:IsPresent(nRealPos) then
			strPetName = Pet:GetPetList_Appoint(nRealPos)
			nHigh, nLow = Pet:GetGUID(nRealPos)
			strIconName = Pet:GetPetPortraitByIndex(nRealPos)
		end		
		
	end
	
	if nil == nHigh or nil == nLow or nil == strIconName or nil == strPetName then
		return
	end
	if 0 == nHigh and 0 == nLow then
		return
	end
	if "" == strIconName then
		return
	end
	if "" == strPetName then
		return
	end
	
	if 1 == IsHaveGUID(nHigh, nLow) then
		-- 已经放入过了 则取消
		BieYePetBar_Awake_PetList_Cancel_Click(bIsPetBank)
	else
		-- 未放入过 则放入
		BieYePetBar_Awake_PetList_Input_Click(bIsPetBank)
	end
end

--=========================================================
-- 放入珍兽
--=========================================================
function BieYePetBar_Awake_PetList_Input_Click(bIsPetBank)
	MyDebug("BieYePetBar_Awake_PetList_Input_Click")
	local nHigh = 0
	local nLow = 0
	local strIconName = ""
	local strPetName = ""
	-- 得到被选择珍兽的GUID
	if 1 == bIsPetBank then
		if g_nCurSelectIndex1 < 0 then 
			PushDebugMessage("请从珍兽仓库列表中选择一个珍兽")
			return 
		end
		-- 珍兽银行
		local nRealPos = BieYePetBar_GetRealIndexPetBank(g_nCurSelectIndex1)
		if nRealPos < 0 or nRealPos >= g_MAX_PETBANK_NUMBER then
			return
		end
		
		if 1 == Pet:IsPresent_PetBank(nRealPos) then
			strPetName = Pet:GetPetList_Appoint_PetBank(nRealPos)
			nHigh, nLow = Pet:GetPetGUIDByIndex_PetBank(nRealPos)
			strIconName = Pet:GetPetBankPortraitByIndex(nRealPos)
		end
		
	else
		if g_nCurSelectIndex0 < 0 then 
			PushDebugMessage("请从携带的珍兽列表中选择一个珍兽")
			return 
		end
		-- 随身珍兽
		local nRealPos = BieYePetBar_GetRealIndexPet(g_nCurSelectIndex0)
		if nRealPos < 0 or nRealPos >= g_MAX_PET_NUMBER then
			return
		end
		
		if true == Pet:IsPresent(nRealPos) then
			strPetName = Pet:GetPetList_Appoint(nRealPos)
			nHigh, nLow = Pet:GetGUID(nRealPos)
			strIconName = Pet:GetPetPortraitByIndex(nRealPos)
		end		
		
	end
	
	if nil == nHigh or nil == nLow or nil == strIconName or nil == strPetName then
		return
	end
	if 0 == nHigh and 0 == nLow then
		return
	end
	if "" == strIconName then
		return
	end
	if "" == strPetName then
		return
	end
	
	-- 已经放入过了
	if 1 == IsHaveGUID(nHigh, nLow) then
		return
	end
	
	-- 获取觉醒经验
	local nPerExp = 0
	if 1 == g_bOpenOutside then
		nPerExp = g_nExpOpenOutSide
	else
		if nil == g_nCurSLSelectedLevel then
			return
		end
		if g_nCurSLSelectedLevel < 1 or g_nCurSLSelectedLevel > g_MAX_JYSL_LEVEL then
			return
		end
		nPerExp = g_tabAwakeInfo[g_nCurSLSelectedLevel].nExp
	end
	
	-- 客户端检测珍兽可携带等级、是否满阶、是否疲劳
	AskServerTimeAgain()
	local nServerDayTime = tonumber(DataPool:GetServerDayTime())
	local nTakeLevel = Pet:GetAllPetTakeLevelByGUID(nHigh, nLow)
	local nToBeGrade, nToBeLevel, nCurNeedExp, nPetTradeTime, 
			nCurExp, nJinJieGrade, nJinJieLevel = Pet:GetCanBeJinJieInfo(
			nHigh, nLow, nPerExp)
	
	-- 可携带等级检测
	if nil == nTakeLevel then
		return
	end
	
	if nTakeLevel < 55 then
		PushDebugMessage("#{JYSL_160518_133}")
		return
	end
	
	-- 满阶检测
	if nil == nJinJieGrade then
		return
	end
	
	if nJinJieGrade >= 10 then
		PushDebugMessage("#{JYSL_160518_134}")
		return
	end
	
	-- 疲劳检测
	if nil == nPetTradeTime then
		PushDebugMessage("#{JYSL_160518_277}")
		return
	end
	
	if nPetTradeTime == nServerDayTime then
		PushDebugMessage("#{JYSL_160518_147}")
		return
	end
			
	-- 插入
	for i = 1, table.getn( g_tabInputedPetInfo ) do
		if 0 == g_tabInputedPetInfo[i].bPut then
			g_tabInputedPetInfo[i].bPut = 1
			g_tabInputedPetInfo[i].nHigh = nHigh
			g_tabInputedPetInfo[i].nLow = nLow
			g_tabInputedPetInfo[i].strIconName = strIconName
			g_tabInputedPetInfo[i].strPetName = strPetName
			
			-- 客户端自己检测才用刷新，服务器检测的话服务器负责刷新
			BieYePetBar_Awake_Update()
			
			-- 请求服务器检测该珍兽是否合法
			--Clear_XSCRIPT()
			--Set_XSCRIPT_Function_Name( "OnPetInput" )
			--Set_XSCRIPT_ScriptID( 892305 )
			--Set_XSCRIPT_Parameter( 0, nHigh )
			--Set_XSCRIPT_Parameter( 1, nLow )
			--Set_XSCRIPT_Parameter( 2, i )
			--Set_XSCRIPT_ParamCount( 3 )
			--Send_XSCRIPT()
			
			return
		end
	end
	
	-- 没有可以插入的位置，提示：珍兽已放满，无法放入
	PushDebugMessage("#{JYSL_160518_135}")
	
end

--=========================================================
-- 取消放入珍兽
--=========================================================
function BieYePetBar_Awake_PetList_Cancel_Click(bIsPetBank)
	MyDebug("BieYePetBar_Awake_PetList_Cancel_Click")
	local nHigh = 0
	local nLow = 0
	
	-- 得到被选择珍兽的GUID
	if 1 == bIsPetBank then
		-- 珍兽银行
		local nRealPos = BieYePetBar_GetRealIndexPetBank(g_nCurSelectIndex1)
		if nRealPos < 0 or nRealPos >= g_MAX_PETBANK_NUMBER then
			return
		end
		
		if 1 == Pet:IsPresent_PetBank(nRealPos) then
			nHigh, nLow = Pet:GetPetGUIDByIndex_PetBank(nRealPos)
		end
	else
		-- 随身珍兽
		local nRealPos = BieYePetBar_GetRealIndexPet(g_nCurSelectIndex0)
		if nRealPos < 0 or nRealPos >= g_MAX_PET_NUMBER then
			return
		end
		
		if true == Pet:IsPresent(nRealPos) then
			nHigh, nLow = Pet:GetGUID(nRealPos)
		end		
	end
	
	if nil == nHigh or nil == nLow then
		return
	end
	if 0 == nHigh and 0 == nLow then
		return
	end
	
	for i = 1, table.getn( g_tabInputedPetInfo ) do
		if 1 == g_tabInputedPetInfo[i].bPut then
			if g_tabInputedPetInfo[i].nHigh == nHigh and g_tabInputedPetInfo[i].nLow == nLow then
				g_tabInputedPetInfo[i].bPut = 0
				g_tabInputedPetInfo[i].bFlash = 0
				g_tabInputedPetInfo[i].nHigh = 0
				g_tabInputedPetInfo[i].nLow = 0
				g_tabInputedPetInfo[i].strIconName = ""
				g_tabInputedPetInfo[i].strPetName = ""
				g_tabPetHeadControl[i]:SetActionItem(-1)
				g_tabPetUpInfoControl[i]:SetText("")
				g_tabPetNameControl[i]:SetText("")
				g_tabPetExpControl[i]:SetProgress(0, 1.0)
				g_tabPetExpControl[i]:SetToolTip("")
				g_tabPetCloseControl[i]:Disable()
				BieYePetBar_Awake_Update()
				return
			end
		end 
	end
end

--=========================================================
-- 左键珍兽头像
--=========================================================
function BieYePetBar_Awake_Pet_Tu_Click(nIndex)
	MyDebug("BieYePetBar_Awake_Pet_Tu_Click")
	return
end

--=========================================================
-- 右键珍兽头像
--=========================================================
function BieYePetBar_Awake_Pet_Tu_RClick(nIndex)
	MyDebug("BieYePetBar_Awake_Pet_Tu_RClick")
	if nIndex < 1 or nIndex > table.getn( g_tabInputedPetInfo ) then
		return
	end
	g_tabInputedPetInfo[nIndex].bPut = 0
	g_tabInputedPetInfo[nIndex].bFlash = 0
	g_tabInputedPetInfo[nIndex].nHigh = 0
	g_tabInputedPetInfo[nIndex].nLow = 0
	g_tabInputedPetInfo[nIndex].strIconName = ""
	g_tabInputedPetInfo[nIndex].strPetName = ""
	g_tabPetHeadControl[nIndex]:SetActionItem(-1)
	g_tabPetUpInfoControl[nIndex]:SetText("")
	g_tabPetNameControl[nIndex]:SetText("")
	g_tabPetExpControl[nIndex]:SetProgress(0, 1.0)
	g_tabPetExpControl[nIndex]:SetToolTip("")
	g_tabPetCloseControl[nIndex]:Disable()
	BieYePetBar_Awake_Update()
end

--=========================================================
-- 已存放珍兽是否存在该GUID
--=========================================================
function IsHaveGUID(nHigh, nLow)
	if nil == nHigh or nil == nLow then
		return
	end
	if 0 == nHigh and 0 == nLow then
		return
	end
	
	for i = 1, table.getn( g_tabInputedPetInfo ) do
		if 1 == g_tabInputedPetInfo[i].bPut then
			if g_tabInputedPetInfo[i].nHigh == nHigh and g_tabInputedPetInfo[i].nLow == nLow then
				return 1
			end
		end 
	end
	return 0
end

function BieYePetBar_Awake_OnTimer(nIndex)
	g_tabPetHeadFlashControl[nIndex] : Play(false)
	g_tabPetHeadFlashTimer[nIndex] : SetProperty("Timer", "-1")
end	

--=========================================================
-- 重置数据
--=========================================================
function BieYePetBar_Awake_Reset()
	MyDebug("BieYePetBar_Awake_Reset")
	-- 珍兽列表类型、选择行数
	--g_nCurSelectType		= 0	
	g_nCurSelectIndex0		= -1
	g_nCurSelectIndex1		= -1
	
	-- 珍兽选择列表清空
	BieYePetBar_Awake_List01 : ClearListBox()
	BieYePetBar_Awake_List02 : ClearListBox()
	
	-- 清空放入珍兽数据信息
	for i = 1, table.getn( g_tabInputedPetInfo ) do 
		g_tabInputedPetInfo[i].bPut = 0
		g_tabInputedPetInfo[i].bFlash = 0
		g_tabInputedPetInfo[i].nHigh = 0
		g_tabInputedPetInfo[i].nLow = 0
		g_tabInputedPetInfo[i].strIconName = ""
		g_tabInputedPetInfo[i].strPetName = ""	
	end
	
	-- 清空放入珍兽头像
	for i = 1, table.getn( g_tabPetHeadControl ) do
		g_tabPetHeadControl[i]:SetActionItem(-1)
	end
	
	-- 清空放入珍兽头像动画
	for i = 1, table.getn( g_tabPetHeadControl ) do
		g_tabPetHeadFlashControl[i]:Play(false)
	end
	
	-- 清空放入珍兽头像动画timer
	for i = 1, table.getn( g_tabPetHeadControl ) do
		g_tabPetHeadFlashTimer[i] : SetProperty("Timer", "-1")
	end
	
	
	-- 清空珍兽升级信息
	for i = 1, table.getn( g_tabPetUpInfoControl ) do
		g_tabPetUpInfoControl[i]:SetText("")
	end
	
	-- 清空珍兽名字信息
	for i = 1, table.getn( g_tabPetNameControl ) do
		g_tabPetNameControl[i]:SetText("")
	end
	
	-- 清空珍兽经验信息
	for i = 1, table.getn( g_tabPetNameControl ) do
		g_tabPetExpControl[i]:SetProgress(0, 1.0)
		g_tabPetExpControl[i]:SetToolTip("")
	end
	
	-- 清空珍兽关闭信息
	for i = 1, table.getn( g_tabPetNameControl ) do
		g_tabPetCloseControl[i]:Disable()
	end
	
	-- 设置觉醒等级1-5；兽栏等级1-5；item0-4
	BieYePetBar_Awake_PetLevel_Select:ResetList()
	if 1 == g_bOpenOutside then
		-- 家园外打开界面只有一个等级
		BieYePetBar_Awake_PetLevel_Select:AddTextItem("#{JYSL_160518_292}", 0)
		g_nCurSLSelectedLevel = -1
		BieYePetBar_Awake_PetLevel_Select:SetCurrentSelect(0)
		-- 等级选择不可用
		--BieYePetBar_Awake_PetLevel_Select:Disable()
		-- 等级选择悬停tips
	else
		BieYePetBar_Awake_PetLevel_Select:AddTextItem("#{JYSL_160518_112}", 0)
		BieYePetBar_Awake_PetLevel_Select:AddTextItem("#{JYSL_160518_113}", 1)
		BieYePetBar_Awake_PetLevel_Select:AddTextItem("#{JYSL_160518_114}", 2)
		BieYePetBar_Awake_PetLevel_Select:AddTextItem("#{JYSL_160518_115}", 3)
		BieYePetBar_Awake_PetLevel_Select:AddTextItem("#{JYSL_160518_116}", 4)
		g_nCurSLSelectedLevel = g_nJYSLLevel
		BieYePetBar_Awake_PetLevel_Select:SetCurrentSelect(g_nCurSLSelectedLevel-1)
		-- 等级选择可用
		--BieYePetBar_Awake_PetLevel_Select:Enable()
		-- 等级选择悬停tips
	end

	-- 觉醒经验
	BieYePetBar_Awake_PetLevel_Get : SetText("")
	BieYePetBar_Awake_PetLevel_Gettext : SetText("")
	-- 消耗材料、金钱
	--BieYePetBar_Awake_Consumefood_Text : SetText("")
	--BieYePetBar_Awake_Ownfood_Text : SetText("")
	BieYePetBar_Awake_CostJiaozi_Money : SetProperty( "MoneyNumber", 0 )
	
	-- 界面介绍提示
	BieYePetBar_Awake_Frame_Infotips : SetText("")
	
	-- 主界面文字根据打开地方不同
	if 1 == g_bOpenOutside then
		BieYePetBar_Awake_Frame_Info : SetText("#{JYSL_160518_289}")
	else
		BieYePetBar_Awake_Frame_Info : SetText("#{JYSL_160518_110}")
	end
	
	-- 觉醒按钮
	BieYePetBar_Awake_Pet_Button1 : Enable()
	--BieYePetBar_Awake_Pet_Button1 : PlayWarning( 0 )
	--BieYePetBar_Awake_Pet_Button1 : PlayWarning( 1 )
	BieYePetBar_Awake_Pet_Button1tips : SetToolTip("")
end

--=========================================================
-- 获得存储位置 随身珍兽 无非法数据，两个index一致
--=========================================================
function BieYePetBar_GetRealIndexPet(nSelected)
	MyDebug("BieYePetBar_GetRealIndexPet")
	local nCount = 0
	for i=0, g_MAX_PET_NUMBER-1 do
		if true == Pet:IsPresent(i) then
			if nSelected == nCount then
				return i
			end
			nCount = nCount + 1
		end		
	end
	return -1
end

--=========================================================
-- 获得存储位置 珍兽银行 无非法数据，两个index一致
--=========================================================
function BieYePetBar_GetRealIndexPetBank(nSelected)
	MyDebug("BieYePetBar_GetRealIndexPetBank")
	local nCount = 0
	for i=0, g_MAX_PETBANK_NUMBER-1 do
		if 1 == Pet:IsPresent_PetBank(i) then
			if nSelected == nCount then
				return i
			end
			nCount = nCount + 1
		end		
	end
	return -1	
end	

--=========================================================
-- 点击关闭界面
--=========================================================
function BieYePetBar_Awake_Close_Click()
	MyDebug("BieYePetBar_Awake_Close_Click")
	BieYePetBar_Awake_Close()
end

--=========================================================
--关闭
--=========================================================
function BieYePetBar_Awake_Close()
	MyDebug("BieYePetBar_Awake_Close")
	this : Hide()
	StopCareObject_BieYePetBar_Awake()
	BieYePetBar_Awake_Reset()
end

--=========================================================
--界面隐藏
--=========================================================
function BieYePetBar_Awake_OnHiden()
	MyDebug("BieYePetBar_Awake_OnHiden")
	StopCareObject_BieYePetBar_Awake()
	BieYePetBar_Awake_Reset()
end

--=========================================================
--金钱刷新
--=========================================================
function BieYePetBar_Awake_MoneyUpdate()
	MyDebug("BieYePetBar_Awake_MoneyUpdate")
	BieYePetBar_Awake_OwnJiaozi_Money : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	BieYePetBar_Awake_OwnJin_Money : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_BieYePetBar_Awake()
	MyDebug("BeginCareObject_BieYePetBar_Awake")
	this : CareObject( g_nObjCaredID, 1, "BieYePetBar_Awake" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_BieYePetBar_Awake()
	MyDebug("StopCareObject_BieYePetBar_Awake")
	this : CareObject( g_nObjCaredID, 0, "BieYePetBar_Awake" )
end

--=========================================================
-- 调试信息
--=========================================================
function MyDebug(strMsg)
	if 1 == g_bDebug then
		PushDebugMessage(strMsg)
	end
end


