local bnList = {}
local imageList = {
	--金
	{
		order = "set:CommonLiveSkill4 image:CommonLiveSkill4_12", 
		right = "set:CommonLiveSkill4 image:CommonLiveSkill4_3" ,
		wrong = "set:CommonLiveSkill4 image:CommonLiveSkill4_4"
	},
	--木
	{
		order = "set:CommonLiveSkill4 image:CommonLiveSkill4_13", 
		right = "set:CommonLiveSkill4 image:CommonLiveSkill4_5" ,
		wrong = "set:CommonLiveSkill4 image:CommonLiveSkill4_6"
	},
	--水
	{
		order = "set:CommonLiveSkill4 image:CommonLiveSkill4_14" ,
		right = "set:CommonLiveSkill4 image:CommonLiveSkill4_7" ,
		wrong = "set:CommonLiveSkill4 image:CommonLiveSkill4_8"
	},
	--火
	{
		order = "set:CommonLiveSkill4 image:CommonLiveSkill4_11" ,
		right = "set:CommonLiveSkill4 image:CommonLiveSkill4_1" ,
		wrong = "set:CommonLiveSkill4 image:CommonLiveSkill4_2"
	},
	--土
	{
		order = "set:CommonLiveSkill4 image:CommonLiveSkill4_15" ,
		right = "set:CommonLiveSkill4 image:CommonLiveSkill4_9" ,
		wrong = "set:CommonLiveSkill4 image:CommonLiveSkill4_10"
	},	
}

local strList = {
	"#{BHXH_YSJC_XML_02}",
	"#{BHXH_YSJC_XML_07}",
	"#{BHXH_YSJC_XML_08}"
}

local skillName = {	"金" ,"木" ,"水" ,"火" ,"土" }
local Bhsc_yj_UnifiedPosition

function Bhsc_yj_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("CLOSE_AGNAME");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


function Bhsc_yj_OnLoad()
	bnList[1] = Bhsc_Yj1_ProductItem
	bnList[2] = Bhsc_Yj2_ProductItem
	bnList[3] = Bhsc_Yj3_ProductItem
	bnList[4] = Bhsc_Yj4_ProductItem
	bnList[5] = Bhsc_Yj5_ProductItem
	bnList[6] = Bhsc_Yj6_ProductItem
	Bhsc_yj_UnifiedPosition = Bhsc_yj_Frame:GetProperty("UnifiedPosition");
end

function Bhsc_yj_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 20110608 then
		if Get_XParam_INT(0) == 0 then
			this:Hide()
		elseif Get_XParam_INT(0) == 1 then
			this:Show()
			local intSkillOrder = Get_XParam_INT(1)
			local intDoneSkill = Get_XParam_INT(2)
			local skillnum = Get_XParam_INT(3)
			
			local skillOrder = {0,0,0,0,0}
			skillOrder[1],skillOrder[2],skillOrder[3],skillOrder[4],skillOrder[5] = Bhsc_yj_IntToFive(intSkillOrder)
			for i = 1 ,5 do
				bnList[i]:SetProperty("NormalImage" ,imageList[skillOrder[i]].order )
			end
			
			bnList[6]:SetProperty("NormalImage" , "")
			
			local str = strList[1]..skillName[skillOrder[1]]..strList[2]..skillName[skillOrder[1]]..strList[3]
			Bhsc_yj_Frame_Client:SetText(str)
			Bhsc_yj_Jishi1_Client:SetProperty("Timer","30")
			Bhsc_yj_Jishi_Client:Show()
		elseif Get_XParam_INT(0) == 2 then
			this:Show()
			local intSkillOrder = Get_XParam_INT(1)
			local intDoneSkill = Get_XParam_INT(2)
			local skillnum = Get_XParam_INT(3)
			Bhsc_yj_UpdateFrame( intSkillOrder , intDoneSkill , skillnum , 2)
		elseif Get_XParam_INT(0) == 3 then
			this:Show()
			local intSkillOrder = Get_XParam_INT(1)
			local intDoneSkill = Get_XParam_INT(2)
			local skillnum = Get_XParam_INT(3)
			Bhsc_yj_UpdateFrame( intSkillOrder , intDoneSkill , skillnum , 3)
		end
	end
	if (event == "ADJEST_UI_POS" ) then
		Bhsc_yj_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Bhsc_yj_On_ResetPos()
	end	
end

function Bhsc_yj_UpdateFrame( intOrder , intDone , numDone , nOK)
	local skillOrder = {0,0,0,0,0}
	skillOrder[1],skillOrder[2],skillOrder[3],skillOrder[4],skillOrder[5] = Bhsc_yj_IntToFive(intOrder)

	local doneResult =  {0,0,0,0,0}
	doneResult[1],doneResult[2],doneResult[3],doneResult[4],doneResult[5] = Bhsc_yj_IntToFive(intDone)
	
	if nOK == 2 then
		for i = 1 ,5 do
			if i > numDone then
				bnList[i]:SetProperty("NormalImage" ,imageList[skillOrder[i]].order )
			else
				if doneResult[i] == 1 then
					bnList[i]:SetProperty("NormalImage" ,imageList[skillOrder[i]].right )
				else
					bnList[i]:SetProperty("NormalImage" ,imageList[skillOrder[i]].wrong )
				end
			end
		end
		if numDone > 0 and numDone < 5 then
			local str = strList[1]..skillName[skillOrder[numDone+1]]..strList[2]..skillName[skillOrder[numDone+1]]..strList[3]
			Bhsc_yj_Frame_Client:SetText(str)
		else
			Bhsc_yj_Frame_Client:SetText("#{BHXH_YSJC_XML_03}")
		end
	elseif nOK == 3 then
		for i = 1 ,5 do
			bnList[i]:SetProperty("NormalImage" ,imageList[skillOrder[i]].right )
		end	
		bnList[6]:SetProperty("NormalImage" ,"set:CommonLiveSkill3 image:CommonLiveSkill3_16" )
		Bhsc_yj_Frame_Client:SetText("#{BHXH_YSJC_XML_06}")
		Bhsc_yj_Jishi1_Client:SetProperty("Timer","5")
	end
end


function Bhsc_yj_OnCloseClicked()
	this:Hide()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "StopOperation" )
		Set_XSCRIPT_ScriptID( 600071 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end

function Bhsc_yj_TimeReach() 
	Bhsc_yj_Jishi1_Client:SetProperty("Timer","0")
	this:Hide()
end


function Bhsc_yj_IntToFive(iNum)
	local x1 ,x2 ,x3 ,x4 ,x5 
	x1 = math.floor(iNum / 10000)
	x2 = math.mod(math.floor(iNum / 1000) ,10 )
	x3 = math.mod(math.floor(iNum / 100) ,10 )
	x4 = math.mod(math.floor(iNum / 10) ,10 )
	x5 = math.mod(iNum  ,10 )
	return x1 ,x2 ,x3 ,x4 ,x5
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Bhsc_yj_On_ResetPos()
  Bhsc_yj_Frame:SetProperty("UnifiedPosition", Bhsc_yj_UnifiedPosition);
end