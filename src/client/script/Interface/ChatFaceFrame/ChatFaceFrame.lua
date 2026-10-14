local g_AllAnimate = {};
local g_AllNewAnimate = {};
local g_AllPageTab = {}
local g_curPage = 1
local g_speciallist = {	-- 涉及敏感字号的表情需要特殊处理，换成新ID
	[54] = 801,
	[64] = 802,
	[69] = 803,
	[89] = 804,
	[419] = 437,
}
function ChatFaceFrame_PreLoad()
	this:RegisterEvent("CHAT_FACEMOTION_SELECT", true);
	this:RegisterEvent("CHAT_ADJUST_MOVE_CTL", false);
end

function ChatFaceFrame_OnLoad()
	g_AllAnimate = {
		Face_1 ,Face_2 ,Face_3 ,Face_4 ,Face_5 ,Face_6 ,Face_7 ,Face_8 ,Face_9 ,Face_10,
		Face_11,Face_12,Face_13,Face_14,Face_15,Face_16,Face_17,Face_18,Face_19,Face_20,
		Face_21,Face_22,Face_23,Face_24,Face_25,Face_26,Face_27,Face_28,Face_29,Face_30,
		Face_31,Face_32,Face_33,Face_34,Face_35,Face_36,Face_37,Face_38,Face_39,Face_40,
		Face_41,Face_42,Face_43,Face_44,Face_45,Face_46,Face_47,Face_48,Face_49,Face_50,
		Face_51,Face_52,Face_53,Face_54,Face_55,Face_56,Face_57,Face_58,Face_59,Face_60,
		Face_61,Face_62,Face_63,Face_64,Face_65,Face_66,Face_67,Face_68,Face_69,Face_70,
		Face_71,Face_72,Face_73,Face_74,Face_75,Face_76,Face_77,Face_78,Face_79,Face_80,
		Face_81,Face_82,Face_83,Face_84,Face_85,Face_86,Face_87,Face_88,Face_89,Face_90,
		Face_91,Face_92,Face_93,Face_94,Face_95,Face_96,Face_97,Face_98,Face_99,Face_100
	};

	g_AllNewAnimate = {
		Face_101 ,Face_102 ,Face_103 ,Face_104 ,Face_105 ,Face_106 ,Face_107 ,Face_108 ,Face_109 ,Face_110,
		Face_111 ,Face_112 ,Face_113 ,Face_114 ,Face_115 ,Face_116 ,Face_117 ,Face_118 ,Face_119 ,Face_120,
		Face_121 ,Face_122 ,Face_123 ,Face_124 ,Face_125 ,Face_126 ,Face_127 ,Face_128 ,Face_129 ,Face_130,
		Face_131 ,Face_132 ,Face_133 ,Face_134 ,Face_135 ,Face_136
	};

	g_AllPageTab = {
		Face_Frame_Index1,
		Face_Frame_Index2,
		Face_Frame_Index3,
		Face_Frame_Index4
	}

	for i = 1, table.getn(g_AllAnimate) do
		if g_speciallist[i] ~= nil then
			g_AllAnimate[i]:SetToolTip("##"..tostring(g_speciallist[i]))
		else
			g_AllAnimate[i]:SetToolTip("##"..tostring(i));
		end
	end
end

function ChatFaceFrame_OnEvent( event )
	if( event == "CHAT_FACEMOTION_SELECT" and arg0 == "select") then
		if(this:IsVisible() or this:ClickHide())then
			this:Hide();
		else
			Chat_FaceFrame_Show()
		end
	elseif (event == "CHAT_ADJUST_MOVE_CTL" and this:IsVisible()) then
		Chat_FaceFrame_AdjustMoveCtl();
	end
end

function Chat_FaceFrame_SelectMotion(nIndex)

	if(1 > nIndex) then
		return;
	end

	if g_curPage == 1 then
		local strResult = "#" .. tostring(nIndex);
		Talk:SelectFaceMotion("sucess", strResult);
	else
		local faceID , faceValidDate , faceCount = DataPool:GetRMB_FaceInfo(g_curPage - 2)
		local realFaceID = DataPool:GetRMB_FaceRealID(faceID)
		local realIndex = realFaceID * 100 + (nIndex - 100)
		realIndex = g_speciallist[realIndex] or realIndex
		local strResult = ""
		if realIndex < 1000 then 
			strResult = "#v0"..tostring(realIndex)
		else
			strResult = "#v"..tostring(realIndex)
		end
		Talk:SelectFaceMotion("sucess", strResult);
	end
end

function Chat_FaceFrame_AdjustMoveCtl()
	this:Hide();
end

function Chat_FaceFrame_ChangePosition(pos1,pos2)


	if(tonumber(pos1)~=0) then
		Face_Frame:SetProperty("UnifiedXPosition", "{0.0,"..pos1.."}");
	end;
	if(tonumber(pos2)~=0) then
		Face_Frame:SetProperty("UnifiedYPosition", "{0.0,"..pos2.."}");
	end;
end

function Chat_FaceFrame_Show()
	this:Show();
	Chat_FaceFrame_ChangePosition(arg1,arg2);



	if g_curPage <= 1 or g_curPage > 5  then
		g_curPage = 1
		Face_Frame_Index0:SetCheck(1)

	else
	   	g_AllPageTab[g_curPage - 1]:SetCheck(1)

	end

	Chat_FaceFrame_Page_Switch(g_curPage)

	for i = 0 ,3 do
		local faceID , faceValidDate , faceCount = DataPool:GetRMB_FaceInfo(i)
		local faceName = DataPool:GetRMB_FaceName(faceID)
		if faceID > 0 then
			g_AllPageTab[i + 1]:SetToolTip(tostring(faceName)..tostring(faceValidDate))
		else
			g_AllPageTab[i + 1]:SetToolTip("#{BQB_XML_14}")
		end

	end

end

function Chat_FaceFrame_Page_Switch(pageNum)

	if pageNum == 1 then
		for i = 1, table.getn(g_AllAnimate) do
			g_AllAnimate[i]:Show();
		end

		for i = 1, table.getn(g_AllNewAnimate) do
			g_AllNewAnimate[i]:Hide();
		end
		Face_Frame_Time:Hide()
		Face_Frame_Setdown:Hide();
		Face_DragTitle:SetText("#{BQB_XML_1}")
	else
		local faceID , faceValidDate , faceCount = DataPool:GetRMB_FaceInfo(pageNum - 2)

		for i = 1, table.getn(g_AllAnimate) do
			g_AllAnimate[i]:Hide();
		end

		for i = 1, table.getn(g_AllNewAnimate) do
			g_AllNewAnimate[i]:Hide();
		end
		Face_Frame_TimeText:SetText("")

		local realFaceID = DataPool:GetRMB_FaceRealID(faceID)

		if realFaceID > 0 and faceCount > 0 then
			for i = 1, table.getn(g_AllNewAnimate) do
				if i <= faceCount then
					local realIndex = realFaceID * 100 + i
					realIndex = g_speciallist[realIndex] or realIndex
					local strResult = ""
					if realIndex < 1000 then 
						strResult = "##v0"..tostring(realIndex)
					else
						strResult = "##v"..tostring(realIndex)
					end
					g_AllNewAnimate[i]:SetToolTip(strResult);
					g_AllNewAnimate[i]:Show();
					g_AllNewAnimate[i]:SetAnimateID(realIndex)
				end
			end

			local faceHour = DataPool:GetRMB_FaceValidHour(pageNum - 2)
			if faceHour >=0 and faceHour < 24 then
				Face_Frame_TimeText:SetText("#R#{BQB_XML_3}"..tostring(faceHour).."#{BQB_XML_16}")
			elseif faceHour >= 24 then
				Face_Frame_TimeText:SetText("#G#{BQB_XML_3}"..tostring(math.floor(faceHour/24)).."#{BQB_XML_15}")
			elseif faceHour < 0 then
				Face_Frame_TimeText:SetText("#{BQB_220329_15}")
			end

			local faceName = DataPool:GetRMB_FaceName(faceID)
			Face_DragTitle:SetText("#gFF0FA0"..tostring(faceName))
			Face_Frame_Time:Show()
			Face_Frame_Setdown:Show()


		else
			Face_DragTitle:SetText("#{BQB_XML_2}")
			Face_Frame_Time:Hide()
			Face_Frame_Setdown:Hide()
		end

	end

	g_curPage = pageNum
end

function Face_Frame_Setdown_Click()
	if g_curPage == 1 then
		return
	end

	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{BQB_091026_1}")
		return
	end


	--二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	DataPool:UnInstallRMBFace(g_curPage - 2  , 0)
end

