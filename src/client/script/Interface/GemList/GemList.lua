local Select_Gem_Index = -1

function GemList_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OPEN_WINDOW");
	this:RegisterEvent("UPDATE_BAOSHI_CHANGE_LIST");
end

function GemList_OnLoad()

end


function GemList_OnEvent(event)
	
	if ( event == "OPEN_WINDOW" and arg0 == "GemList" ) then
		if (this:IsVisible()) then
			this:Hide();
		else
			this:Show();
		end
	elseif ( event == "UPDATE_BAOSHI_CHANGE_LIST" ) then
		GemList_List:ClearListBox();
		local num = arg0 - 1
		if arg1 ~= -1 and 1 <= num then
			GemList_List:AddItem(""..tostring(arg1),1);
		end
		if arg2 ~= -1 and 2 <= num then
			GemList_List:AddItem(""..tostring(arg2),2);
		end
		if arg3 ~= -1 and 3 <= num then
			GemList_List:AddItem(""..tostring(arg3),3);
		end
		if arg4 ~= -1 and 4 <= num then
			GemList_List:AddItem(""..tostring(arg4),4);
		end
		if arg5 ~= -1 and 5 <= num then
			GemList_List:AddItem(""..tostring(arg5),5);
		end
		if arg6 ~= -1 and 6 <= num then
			GemList_List:AddItem(""..tostring(arg6),6);
		end
		if arg7 ~= -1 and 7 <= num then
			GemList_List:AddItem(""..tostring(arg7),7);
		end
		if arg8 ~= -1 and 8 <= num then
			GemList_List:AddItem(""..tostring(arg8),8);
		end
		if arg9 ~= -1 and 9 <= num then
			GemList_List:AddItem(""..tostring(arg9),9);
		end
		if arg10 ~= -1 and 10 <= num then
			GemList_List:AddItem(""..tostring(arg10),10);
		end
		if arg11 ~= -1 and 11 <= num then
			GemList_List:AddItem(""..tostring(arg11),11);
		end
		if arg12 ~= -1 and 12 <= num then
			GemList_List:AddItem(""..tostring(arg12),12);
		end
		if arg13 ~= -1 and 13 <= num then
			GemList_List:AddItem(""..tostring(arg13),13);
		end
		if arg14 ~= -1 and 14 <= num then
			GemList_List:AddItem(""..tostring(arg14),14);
		end
		if arg15 ~= -1 and 15 <= num then
			GemList_List:AddItem(""..tostring(arg15),15);
		end
		if arg16 ~= -1 and 16 <= num then
			GemList_List:AddItem(""..tostring(arg16),16);
		end
		if arg17 ~= -1 and 17 <= num then
			GemList_List:AddItem(""..tostring(arg17),17);
		end
		if arg18 ~= -1 and 18 <= num then
			GemList_List:AddItem(""..tostring(arg18),18);
		end
		if arg19 ~= -1 and 19 <= num then
			GemList_List:AddItem(""..tostring(arg19),19);
		end
		if arg20 ~= -1 and 20 <= num then
			GemList_List:AddItem(""..tostring(arg20),20);
		end
		
	end
end

function GemList_Cancle_Clicked()
	this:Hide();
end

function GemList_Choose_Clicked()
	CGemChangeDataPool:ShowSelectItem()
	this:Hide();
end

function GemList_Close()
	this:Hide();
end

function GemList_List_Selected()
	Select_Gem_Index = GemList_List:GetFirstSelectItem();
	if( -1 == Select_Gem_Index ) then
		return;
	end
	CGemChangeDataPool:GetSelectItem(Select_Gem_Index);
end

function GemList_DoubleClickTargetGem()
	CGemChangeDataPool:ShowSelectItem()
	--this:Hide();
end

function GemList_Help_Clicked()
	Helper:GotoHelper("*GemList")
end