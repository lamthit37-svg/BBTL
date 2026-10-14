local g_AchievementGet_IDArray = {-1,-1,-1}	--三个成就的ID
--显示成就的控件
local g_AchievementGetClient = {}
--窗口边框
local g_AchievementGetFrame
local g_AchievementGet_Time = { -1, -1, -1 }
local g_AchievePointIconImages = {
																	[1] = {set="Ach_Fen", image="Ach_Fen_10"},
																	[2] = {set="Ach_Fen", image="Ach_Fen_20"},
																	[3] = {set="Ach_Fen", image="Ach_Fen_30"},
																	[4] = {set="Ach_Fen", image="Ach_Fen_40"},
																	[5] = {set="Ach_Fen", image="Ach_Fen_50"},
																	[10] = {set="Ach_Fen", image="Ach_Fen_100"},
																}


function AchievementGet_PreLoad()
	this:RegisterEvent("UPDATE_ACHIEVEMENT_GET")
end

function AchievementGet_OnLoad()
	g_AchievementGetClient = {
		[1] = AchievementGetClient1,
		[2] = AchievementGetClient2,
		[3] = AchievementGetClient3,
	}
	g_AchievementGetFrame = AchievementGet
end

function AchievementGet_OnEvent( event )
	if( event == "UPDATE_ACHIEVEMENT_GET") then
		if arg0 ~= nil then
			local nParam = tonumber(arg0)
			if nParam == 70 or nParam == 500 then
				return
			end

			AchievementGet_SetID(tonumber(nParam))
			if this:IsVisible() then
				AchievementGet_Update()
			else
				this:Show()
				SetTimer("AchievementGet","AchievementGet_TimerProc()", 200)
				AchievementGet_Update()
			end
		end
	end
end

function AchievementGet_Update( )
	if true == AchievementGet_HideWindow() then 	
		return 
	end
	
	local nShowCount = 0
	for nIndex = 1,table.getn(g_AchievementGetClient) do
		if nil == g_AchievementGetClient[nIndex] then 
			return 
		end

		g_AchievementGetClient[nIndex]:SetVertScrollbarHide()
		g_AchievementGetClient[nIndex]:CleanAllElement("AchievementGet")
		if g_AchievementGet_IDArray[nIndex] <= -1 then
			g_AchievementGetClient[nIndex]:Hide()
		else
			local BtnWin = g_AchievementGetClient[nIndex]:AddItemElement( "AchievementBar", "LEFT", "AchievementGet" ,"" ,"")
			local ID,strTitle,_,nType,_,_,nScore,_ = Achievement:GetAchvInfoByID(g_AchievementGet_IDArray[nIndex])
			if nil ~= ID and -1 ~= ID then
				local _, TypeImage, _ = Achievement:GetAchvTypeInfoByID(nType)
				BtnWin:AddBarText("#{CJXT_100317_09}")
				BtnWin:AddBarDateText("#e010101#c80CF8D"..strTitle)
				BtnWin:SetProgressHide()

				--成就图标
				if nil ~= TypeImage and "" ~= TypeImage then				
					local sPos,_ = string.find(TypeImage," ");
					local IconImageSet = string.sub(TypeImage,5,sPos-1)
					local IconIamge = string.sub(TypeImage,sPos+7)
					if nil ~= IconImageSet and nil ~= IconIamge then
						BtnWin:AddBarIconImage(IconImageSet,IconIamge)
					end
				end

				if nil == g_AchievePointIconImages[(nScore/10)].set or nil == g_AchievePointIconImages[(nScore/10)].image then
					BtnWin:SetBarPointImageHide()
				else
					BtnWin:AddBarPointImage(g_AchievePointIconImages[(nScore/10)].set, g_AchievePointIconImages[(nScore/10)].image)
				end
				BtnWin:SetPointDisImageHide()		--隐藏成就图标的灰化

				if g_AchievementGet_Time[nIndex] >=0 and g_AchievementGet_Time[nIndex] <= 40 then
					g_AchievementGetClient[nIndex]:SetProperty("Alpha", 1)
				elseif g_AchievementGet_Time[nIndex] > 40 and g_AchievementGet_Time[nIndex] < 50 then
					g_AchievementGetClient[nIndex]:SetProperty("Alpha",(50 - g_AchievementGet_Time[nIndex]) / 10)
				end

				g_AchievementGetClient[nIndex]:Show()
				g_AchievementGetClient[nIndex]:Flash()
				nShowCount = nShowCount + 1
			end
		end
	end

	if nShowCount > 0 then
		AchievementGet_SetWnSize(nShowCount)
		this:Show()
	end
end

function AchievementGet_OnHide()
	AchievementGet_Clear()
end

function AchievementGet_OnShow()

end

--设置三个成就ID
function AchievementGet_SetID(nAchieveID)
	for nAIndex = 1, table.getn(g_AchievementGet_IDArray) do
		if g_AchievementGet_IDArray[nAIndex] < 0 then
			g_AchievementGet_IDArray[nAIndex] = nAchieveID
			g_AchievementGet_Time[nAIndex] = 0
			for nAIndex2 = nAIndex + 1, table.getn(g_AchievementGet_IDArray) do
				g_AchievementGet_IDArray[nAIndex2] = -1
				g_AchievementGet_Time[nAIndex2] = -1
			end
			return
		end
	end
	
	AchievementGet_UpdateID(1)
	g_AchievementGet_IDArray[3] = nAchieveID
	g_AchievementGet_Time[3] = 0
end


--更新成就ID
function AchievementGet_UpdateID(nIndex)
	if nIndex < 1 or nIndex > 2 then 
		return 
	end
	for nIDIndex = nIndex,table.getn(g_AchievementGet_IDArray) -1 do
		g_AchievementGet_IDArray[nIDIndex] = g_AchievementGet_IDArray[nIDIndex + 1]
		g_AchievementGet_Time[nIDIndex] = g_AchievementGet_Time[nIDIndex + 1]
	end
	g_AchievementGet_IDArray[3] = -1
	g_AchievementGet_Time[3] = -1
end


--计时
function AchievementGet_TimerProc()
	for i = 1, table.getn(g_AchievementGet_IDArray) do
		if g_AchievementGet_IDArray[i] > -1 then
			g_AchievementGet_Time[i] = g_AchievementGet_Time[i] + 1
			if g_AchievementGet_Time[i] > 40 and g_AchievementGet_Time[i] < 50 then
				if g_AchievementGetClient[i]:IsVisible() then
					g_AchievementGetClient[i]:SetProperty("Alpha",(50 - g_AchievementGet_Time[i]) / 10)
				end
			elseif g_AchievementGet_Time[i] >= 50 then
				g_AchievementGetClient[i]:Hide()
				g_AchievementGet_IDArray[i] = -1
				AchievementGet_Time[i] = -1
				AchievementGet_UpdateID(i)
				AchievementGet_Update()
			end
		end	
	end
end


--第一个成就控件被点击
function AchievementGet_Client1Click(nType)
	if 1 == nType then	--左键
		Achievement:OpenAchvWindow("AchievementGet", g_AchievementGet_IDArray[1])
		g_AchievementGet_IDArray[1] = -1
		g_AchievementGet_Time[1] = -1
		AchievementGet_UpdateID(1)
		AchievementGet_Update()
	end
end


--第二个成就控件被点击
function AchievementGet_Client2Click(nType)
	if 1 == nType then	--左键
		Achievement:OpenAchvWindow("AchievementGet", g_AchievementGet_IDArray[2])
		g_AchievementGet_IDArray[2] = -1
		g_AchievementGet_Time[2] = -1
		AchievementGet_UpdateID(2)
		AchievementGet_Update()
	end
end


--第三个成就控件被点击
function AchievementGet_Client3Click(nType)
	if 1 == nType then	--左键
		Achievement:OpenAchvWindow("AchievementGet", g_AchievementGet_IDArray[3])
		g_AchievementGet_IDArray[3] = -1
		g_AchievementGet_Time[3] = -1
		AchievementGet_Update()
	end
end


--设置成就获得窗口的大小
function AchievementGet_SetWnSize(Count)
	if Count <= 0 then 
		this:Hide() 
		return 
	end
	local height = Count * 70 + 2 * (Count - 1)
	local YPos = (Count - 3) * (70 + 2) + 318
	YPos = -YPos
	g_AchievementGetFrame:SetProperty("UnifiedSize","{{0.000000,410.000000},{0.000000,"..tostring(height).."}}")
	g_AchievementGetFrame:SetProperty("UnifiedPosition","{{0.500000,-205.000000},{1.000000,"..tostring(YPos).."}}")
end


--关闭时清除控件
function AchievementGet_Clear()
	for i = 1,table.getn(g_AchievementGetClient)do
		g_AchievementGetClient[i]:CleanAllElement("AchievementGet")
	end
	for nIndex = 1,table.getn(g_AchievementGet_IDArray) do
		g_AchievementGet_IDArray[nIndex] = -1
	end
	KillTimer("AchievementGet_TimerProc()")
	g_AchievementGet_Time = {-1, -1, -1}
end


--如果没有可以显示的成就，则关闭
function AchievementGet_HideWindow()
	if g_AchievementGet_IDArray[1] == -1 and g_AchievementGet_IDArray[2] == -1 and g_AchievementGet_IDArray [3] == -1 then
		this:Hide()
		return true
	end
	return false
end