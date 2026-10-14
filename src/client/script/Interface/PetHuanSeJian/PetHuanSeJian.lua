local g_PetHuanSeJNameList = {}
local g_HuanSeJian_ModelType = 2
local g_HuanSeJian_CurFitValue = -1
local g_HuanSeJian_Frame_UnifiedPosition
function PetHuanSeJian_PreLoad()
	this:RegisterEvent("OPEN_PETPOSSHUANSE_JIAN")
	this:RegisterEvent("CLOSE_PETPOSSHUANSE_JIAN")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_FAKE_OBJECT",false)
end
function PetHuanSeJian_OnLoad()
	g_PetHuanSeJNameList[2001] = "#{FTHS_120719_45}"
	g_PetHuanSeJNameList[2002] = "#{FTHS_120719_46}"
	g_PetHuanSeJNameList[2003] = "#{FTHS_120719_47}"
	g_PetHuanSeJNameList[2004] = "#{FTHS_120719_48}"
	g_PetHuanSeJNameList[2005] = "#{FTHS_120719_49}"
	g_PetHuanSeJNameList[2006] = "#{FTHS_120719_50}"
	g_PetHuanSeJNameList[2007] = "#{FTHS_120719_51}"
	g_PetHuanSeJNameList[2008] = "#{FTHS_120719_52}"
	g_PetHuanSeJNameList[2009] = "#{FTHS_120719_53}"
	g_PetHuanSeJNameList[3001] = "#{FTHS_120719_45}"
	g_PetHuanSeJNameList[3002] = "#{FTHS_120719_54}"
	g_PetHuanSeJNameList[3003] = "#{FTHS_120719_55}"
	g_PetHuanSeJNameList[3004] = "#{FTHS_120719_56}"
	g_PetHuanSeJNameList[3005] = "#{FTHS_120719_57}"
	g_PetHuanSeJNameList[3006] = "#{FTHS_120719_58}"
	g_PetHuanSeJNameList[3007] = "#{FTHS_120719_59}"
	g_PetHuanSeJNameList[3008] = "#{FTHS_120719_60}"
	g_PetHuanSeJNameList[3009] = "#{FTHS_120719_61}"
	g_PetHuanSeJNameList[4001] = "#{FTHS_120719_45}"
	g_PetHuanSeJNameList[4002] = "#{FTHS_120719_62}"
	g_PetHuanSeJNameList[4003] = "#{FTHS_120719_63}"
	g_PetHuanSeJNameList[4004] = "#{FTHS_120719_64}"
	g_PetHuanSeJNameList[4005] = "#{FTHS_120719_65}"
	g_PetHuanSeJNameList[4006] = "#{FTHS_120719_66}"
	g_PetHuanSeJNameList[4007] = "#{FTHS_120719_67}"
	g_PetHuanSeJNameList[4008] = "#{FTHS_120719_68}"
	g_PetHuanSeJNameList[4009] = "#{FTHS_120719_69}"
	g_PetHuanSeJNameList[5001] = "#{FTHS_120719_45}"
	g_PetHuanSeJNameList[5002] = "#{FTHS_120719_70}"
	g_PetHuanSeJNameList[5003] = "#{FTHS_120719_71}"
	g_PetHuanSeJNameList[5004] = "#{FTHS_120719_72}"
	g_PetHuanSeJNameList[5005] = "#{FTHS_120719_73}"
	g_PetHuanSeJNameList[5006] = "#{FTHS_120719_74}"
	g_PetHuanSeJNameList[5007] = "#{FTHS_120719_75}"
	g_PetHuanSeJNameList[5008] = "#{FTHS_120719_76}"
	g_PetHuanSeJNameList[5009] = "#{FTHS_120719_77}"
	g_PetHuanSeJNameList[6001] = "#{FTHS_120719_45}"
	g_PetHuanSeJNameList[6002] = "#{FTHS_140417_04}"
	g_PetHuanSeJNameList[6003] = "#{FTHS_140417_02}"
	g_PetHuanSeJNameList[6004] = "#{FTHS_140417_03}"
	g_PetHuanSeJNameList[6005] = "#{FTHS_140417_05}"
	g_PetHuanSeJNameList[6006] = "#{FTHS_140417_06}"
	g_PetHuanSeJNameList[6007] = "#{FTHS_140417_08}"
	g_PetHuanSeJNameList[6008] = "#{FTHS_140417_09}"
	g_PetHuanSeJNameList[6009] = "#{FTHS_140417_07}"
	g_PetHuanSeJNameList[7001] = "#{FTHS_120719_45}"
	g_PetHuanSeJNameList[7002] = "#{FTHS_150113_02}"
	g_PetHuanSeJNameList[7003] = "#{FTHS_150113_03}"
	g_PetHuanSeJNameList[7004] = "#{FTHS_150113_04}"
	g_PetHuanSeJNameList[7005] = "#{FTHS_150113_05}"
	g_PetHuanSeJNameList[7006] = "#{FTHS_150113_06}"
	g_PetHuanSeJNameList[7007] = "#{FTHS_150113_07}"
	g_PetHuanSeJNameList[7008] = "#{FTHS_150113_08}"
	g_PetHuanSeJNameList[7009] = "#{FTHS_150113_09}"
	g_PetHuanSeJNameList[8001] = "#{FTHS_120719_45}"
	g_PetHuanSeJNameList[8002] = "#{FTHS_150805_02}"
	g_PetHuanSeJNameList[8003] = "#{FTHS_150805_03}"
	g_PetHuanSeJNameList[8004] = "#{FTHS_150805_04}"
	g_PetHuanSeJNameList[8005] = "#{FTHS_150805_05}"
	g_PetHuanSeJNameList[8006] = "#{FTHS_150805_06}"
	g_PetHuanSeJNameList[8007] = "#{FTHS_150805_07}"
	g_PetHuanSeJNameList[8008] = "#{FTHS_150805_08}"
	g_PetHuanSeJNameList[8009] = "#{FTHS_150805_09}"
	g_PetHuanSeJNameList[9001] = "#{FTHS_120719_45}"
	g_PetHuanSeJNameList[9002] = "#{FTSH_190415_02}"
	g_PetHuanSeJNameList[9003] = "#{FTSH_190415_03}"
	g_PetHuanSeJNameList[9004] = "#{FTSH_190415_04}"
	g_PetHuanSeJNameList[9005] = "#{FTSH_190415_05}"
	g_PetHuanSeJNameList[9006] = "#{FTSH_190415_06}"
	g_PetHuanSeJNameList[9007] = "#{FTSH_190415_07}"
	g_PetHuanSeJNameList[9008] = "#{FTSH_190415_08}"
	g_PetHuanSeJNameList[9009] = "#{FTSH_190415_09}"
	
	g_HuanSeJian_Frame_UnifiedPosition = PetHuanSeJian_Frame:GetProperty("UnifiedPosition")
end
function PetHuanSeJian_OnEvent(event)
	if (event == "OPEN_PETPOSSHUANSE_JIAN") then	-- 打开界面
		g_HuanSeJian_ModelType = tonumber(arg0)
		g_HuanSeJian_CurFitValue = tonumber(arg1)
		
		PetHuanSeJian_Init()
		this:Show()
	
	elseif (event == "CLOSE_PETPOSSHUANSE_JIAN") then
		this:Hide()
	
	elseif (event == "ADJEST_UI_POS") then
		PetHuanSeJian_Frame_On_ResetPos()
	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetHuanSeJian_Frame_On_ResetPos()
	elseif( event == "UPDATE_FAKE_OBJECT") then
		if (arg0 == "My_PetPossColorJian" and this:IsVisible() ) then
			PetHuanSeJian_SetFakeCamera()
		end
	end
	
end

function PetHuanSeJian_OnHiden()
	PetHuanSeJian_List:ClearListBox()
	Pet:ClearUpPetJianColorRate()
	PetHuanSeJian_FakeObject:SetFakeObject("")
	
	
	this:Hide()
end

function PetHuanSeJian_Modle_TurnLeft(Index)
	if (Index == 1 and CEArg:GetValue("MouseButton") == "LeftButton") then
		PetHuanSeJian_FakeObject:RotateBegin(-0.3)
	else
		PetHuanSeJian_FakeObject:RotateEnd()
	end
end

function PetHuanSeJian_Modle_TurnRight(Index)
	if (Index == 1 and CEArg:GetValue("MouseButton") == "LeftButton") then
		PetHuanSeJian_FakeObject:RotateBegin(0.3)
	else
		PetHuanSeJian_FakeObject:RotateEnd()
	end
end

function PetHuanSeJian_List_Click()
	local CurSelectIndexId =PetHuanSeJian_List:GetFirstSelectItem()
	PetHuanSeJian_FakeObject:SetFakeObject("")
	Pet:SetPetJianColorRateByFitValue(CurSelectIndexId, g_HuanSeJian_CurFitValue)
	PetHuanSeJian_FakeObject:SetFakeObject("My_PetPossColorJian")
	PetHuanSeJian_SetFakeCamera()
end

function PetHuanSeJian_Init()
	PetHuanSeJian_List:ClearListBox()
	local CurSelectId
	if g_HuanSeJian_ModelType == 2 then
		for i=2001,2009 do
			PetHuanSeJian_List:AddItem(g_PetHuanSeJNameList[i], i)
	    end
		CurSelectId = 2009
	elseif g_HuanSeJian_ModelType == 3 then
		for i=3001,3009 do
			PetHuanSeJian_List:AddItem(g_PetHuanSeJNameList[i], i)
	    end
		CurSelectId = 3009
	elseif g_HuanSeJian_ModelType == 4 then
		for i=4001,4009 do
			PetHuanSeJian_List:AddItem(g_PetHuanSeJNameList[i], i)
	    end
		CurSelectId = 4009
	elseif g_HuanSeJian_ModelType == 5 then
		for i=5001,5009 do
			PetHuanSeJian_List:AddItem(g_PetHuanSeJNameList[i], i)
	    end
		CurSelectId = 5009
	elseif g_HuanSeJian_ModelType == 6 then
		for i=6001,6009 do
			PetHuanSeJian_List:AddItem(g_PetHuanSeJNameList[i], i)
	    end
		CurSelectId = 6009
	elseif g_HuanSeJian_ModelType == 7 then
		for i=7001,7009 do
			PetHuanSeJian_List:AddItem(g_PetHuanSeJNameList[i], i)
	    end
		CurSelectId = 7009
	elseif g_HuanSeJian_ModelType == 8 then
		for i=8001,8009 do
			PetHuanSeJian_List:AddItem(g_PetHuanSeJNameList[i], i)
	    end
		CurSelectId = 8009
	elseif g_HuanSeJian_ModelType == 9 then
		for i=9001,9009 do
			PetHuanSeJian_List:AddItem(g_PetHuanSeJNameList[i], i)
	    end
		CurSelectId = 9009
	end
	PetHuanSeJian_List:SetItemSelectByItemID(CurSelectId)	--默认选中最后一项
	
	PetHuanSeJian_FakeObject:SetFakeObject("")
	Pet:SetPetJianColorRateByFitValue(CurSelectId, g_HuanSeJian_CurFitValue)
	PetHuanSeJian_FakeObject:SetFakeObject("My_PetPossColorJian")
	PetHuanSeJian_SetFakeCamera()
	
end

function PetHuanSeJian_Frame_On_ResetPos()
	PetHuanSeJian_Frame:SetProperty("UnifiedPosition", g_HuanSeJian_Frame_UnifiedPosition)
end

function PetHuanSeJian_SetFakeCamera()
	FakeObj_SetCamera( "My_PetPossColorJian", 2,9)
end
