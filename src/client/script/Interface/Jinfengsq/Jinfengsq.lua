--******************************************************************************
-- 划拳界面
--******************************************************************************
local g_Jinfengsq_Frame_UnifiedXPosition;
local g_Jinfengsq_Frame_UnifiedYPosition;

--控件
local g_Jinfengsq_PicAnime_1 --大界面：5、4、3、2、1倒计时
local g_Jinfengsq_daojishi --右下角小界面：标题下面的那行控件
local g_Jinfengsq_shuzi_target = {} --右下角小界面：目标数字
local g_Jinfengsq_shuzi_real = {} --右下角小界面：实际数字
local g_Jinfengsq_yishuzi = {} --艺术字控件：0~9

--计数
local g_Jinfengsq_time = -1 --显示的数字：5、60秒倒计时
local g_Jinfengsq_count = 0 --拾取树叶的数量：0~100

--常量
local g_Jinfengsq_Max = 70 --收集树叶上限

--===============================================
-- OnLoad()
--===============================================
function Jinfengsq_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
	this:RegisterEvent("JFSQ_CHANGEUI",true);
end

function Jinfengsq_OnLoad()

	-- 保存界面的默认相对位置
	g_Jinfengsq_Frame_UnifiedXPosition = Jinfengsq_FrameNULL:GetProperty("UnifiedXPosition");
	g_Jinfengsq_Frame_UnifiedYPosition = Jinfengsq_FrameNULL:GetProperty("UnifiedYPosition");

	--大界面倒计时
	-- g_Jinfengsq_PicAnime_1 = Jinfengsq_Times_Begin
	-- g_Jinfengsq_PicAnime_2 = Jinfengsq_Times_Victory
	-- g_Jinfengsq_PicAnime_3 = Jinfengsq_Times_Failure

	--右下角小界面：标题下面的那行控件
	g_Jinfengsq_daojishi = Jinfengsq_CountDownText
	
	--右下角小界面：目标数字
	--g_Jinfengsq_shuzi_target[1] = Jinfengsq_Goal_picture1
	g_Jinfengsq_shuzi_target[1] = Jinfengsq_Goal_picture2
	g_Jinfengsq_shuzi_target[2] = Jinfengsq_Goal_picture3

	--右下角小界面：实际数字
	--g_Jinfengsq_shuzi_real[1] = Jinfengsq_Score_picture1
	g_Jinfengsq_shuzi_real[1] = Jinfengsq_Score_picture2
	g_Jinfengsq_shuzi_real[2] = Jinfengsq_Score_picture3
	
	--艺术字控件
	g_Jinfengsq_yishuzi[0] = "set:Sign image:Signorange_0"
	g_Jinfengsq_yishuzi[1] = "set:Sign image:Signorange_1"
	g_Jinfengsq_yishuzi[2] = "set:Sign image:Signorange_2"
	g_Jinfengsq_yishuzi[3] = "set:Sign image:Signorange_3"
	g_Jinfengsq_yishuzi[4] = "set:Sign image:Signorange_4"
	g_Jinfengsq_yishuzi[5] = "set:Sign image:Signorange_5"
	g_Jinfengsq_yishuzi[6] = "set:Sign image:Signorange_6"
	g_Jinfengsq_yishuzi[7] = "set:Sign image:Signorange_7"
	g_Jinfengsq_yishuzi[8] = "set:Sign image:Signorange_8"
	g_Jinfengsq_yishuzi[9] = "set:Sign image:Signorange_9"
	
	g_Jinfengsq_time = 5
end


--===============================================
-- OnEvent()
--===============================================

function Jinfengsq_OnEvent(event)
	if(event == "UI_COMMAND") then

		local arg = tonumber(arg0)
		
		--打开界面
		if arg == 89288502 then
			local param = Get_XParam_INT(0)
			if param == 1 then
				--播倒计时动画
				-- g_Jinfengsq_PicAnime_1:Play(true)
				-- g_Jinfengsq_PicAnime_2:Play(false)
				-- g_Jinfengsq_PicAnime_3:Play(false)
				-- SetTimer("Jinfengsq","Jinfengsq_Close_1()", 5000)

				KillTimer("Jinfengsq_daojishi()")
				KillTimer("Jinfengsq_Close_daojishi()")
				KillTimer("Jinfengsq_daojishi2()")
				KillTimer("Jinfengsq_Close_daojishi2()")
				KillTimer("Jinfengsq_Close_daojishi3()")

				g_Jinfengsq_count = 0
				
				g_Jinfengsq_UIType = 1
				
				--右下角小界面
				g_Jinfengsq_time = 5
				g_Jinfengsq_daojishi:SetText(ScriptGlobal_Format("#{JFLZ_180806_69}", g_Jinfengsq_time))
				Jinfengsq_Explain:SetText("#{JFLZ_180806_41}")
				SetTimer("Jinfengsq","Jinfengsq_daojishi()", 1000)
				SetTimer("Jinfengsq","Jinfengsq_Close_daojishi()", 5*1000)
				
				--艺术字控件
				Jinfengsq_Set( 1, g_Jinfengsq_Max )
				Jinfengsq_Set( 2, 0 )		

				this:Show()
			elseif param == 0 then
				Jinfengsq_Close()
				return				
			end
		
		--更新拾取树叶数量
		elseif arg == 89288503 then
			 g_Jinfengsq_count = Get_XParam_INT(0)
			 Jinfengsq_Set( 2, g_Jinfengsq_count )
			 
			 --收集满100个后，强制进入倒计时5秒关闭界面流程
			 if g_Jinfengsq_count >= g_Jinfengsq_Max then
				Jinfengsq_Close_daojishi2()
			 end
		end
		return
	end

	if(event == "JFSQ_CHANGEUI") then
		local operate = tonumber(arg0)
		if operate == 1 then
			--g_Jinfengsq_Frame_UnifiedXPosition = tonumber(arg1)
			--g_Jinfengsq_Frame_UnifiedYPosition = tonumber(arg2)
			--Jinfengsq_Mini_Frame_On_ResetPos()
			this:Show()
		else
			this:Hide()
		end
		return
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		Jinfengsq_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		Jinfengsq_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		-- g_Jinfengsq_CurPNCIndex = 0
		-- g_Jinfengsq_CurPNCID = ""
		-- g_Jinfengsq_CurSelect = 0
		-- g_Jinfengsq_IsShowLastResult = false
		-- g_Jinfengsq_Result = 0
		this:Hide();
	end
end

--===============================================
-- 关闭倒计时动画：5、4、3、2、1、开始
--===============================================	
-- function Jinfengsq_Close_1()
	-- --kill timer
	-- KillTimer("Jinfengsq_Close_1()")	
	-- --停止倒计时动画
	-- g_Jinfengsq_PicAnime_1:Play(false)
-- end

--===============================================
-- 刷新5秒倒计时文字显示：X秒后开始掉落枫树树叶
--===============================================	
function Jinfengsq_daojishi()
	g_Jinfengsq_time = g_Jinfengsq_time - 1
	g_Jinfengsq_daojishi:SetText(ScriptGlobal_Format("#{JFLZ_180806_69}", g_Jinfengsq_time))
end

--===============================================
-- 关闭倒计时文字显示：X秒后开始掉落枫树树叶
-- 开启1分钟倒计时
--===============================================	
function Jinfengsq_Close_daojishi()
	--停止倒计时文字显示
	KillTimer("Jinfengsq_daojishi()")
	KillTimer("Jinfengsq_Close_daojishi()")
	
	--开启1分钟倒计时
	g_Jinfengsq_time = 60
	g_Jinfengsq_daojishi:SetText(ScriptGlobal_Format("#{JFLZ_180806_80}", g_Jinfengsq_time))
	SetTimer("Jinfengsq","Jinfengsq_daojishi2()", 1000)	
	SetTimer("Jinfengsq","Jinfengsq_Close_daojishi2()", 60*1000)	
end

--===============================================
-- 刷新60秒倒计时文字显示：X秒后停止掉落枫树树叶
--===============================================	
function Jinfengsq_daojishi2()
	g_Jinfengsq_time = g_Jinfengsq_time - 1
	g_Jinfengsq_daojishi:SetText(ScriptGlobal_Format("#{JFLZ_180806_80}", g_Jinfengsq_time))
end

--===============================================
-- 关闭倒计时文字显示：X秒后停止掉落枫树树叶
-- 60秒计时满后，更新文字
--===============================================	
function Jinfengsq_Close_daojishi2()
	--停止倒计时文字显示
	KillTimer("Jinfengsq_daojishi2()")
	KillTimer("Jinfengsq_Close_daojishi2()")
	
	--更新文字
	g_Jinfengsq_daojishi:SetText("#{JFLZ_180806_70}")
	if g_Jinfengsq_count >= g_Jinfengsq_Max then
		--g_Jinfengsq_daojishi:SetText("#{JFLZ_180806_81}") --替代 策划没配，我自己配的
		Jinfengsq_Explain:SetText("#{JFLZ_180806_81}")
	else
		--g_Jinfengsq_daojishi:SetText("#{JFLZ_180806_82}") --替代 策划没配，我自己配的
		Jinfengsq_Explain:SetText("#{JFLZ_180806_82}")
	end
	
	--开启5秒倒计时
	SetTimer("Jinfengsq","Jinfengsq_Close_daojishi3()", 10*1000)	
end

--===============================================
-- 关闭界面倒计：5秒
--===============================================	
function Jinfengsq_Close_daojishi3()
	--停止倒计时文字显示
	KillTimer("Jinfengsq_Close_daojishi3()")
	
	--关闭界面
	Jinfengsq_Close()
end

--===============================================
-- 设定艺术字数值：000 ，三位数
--type, 指定控件
--value, 设定数值
--===============================================
function Jinfengsq_Set( type, value )	
	if type == 1 then
		g_Jinfengsq_shuzi_target[2]:SetProperty("Image", Jinfengsq_Get( math.mod(value,10)))
		g_Jinfengsq_shuzi_target[1]:SetProperty("Image", Jinfengsq_Get( math.mod(math.floor(value/10),10 )))
		--g_Jinfengsq_shuzi_target[1]:SetProperty("Image", Jinfengsq_Get( math.mod(math.floor(value/100),10)))
	elseif type == 2 then
		g_Jinfengsq_shuzi_real[2]:SetProperty("Image", Jinfengsq_Get( math.mod(value,10)))
		g_Jinfengsq_shuzi_real[1]:SetProperty("Image", Jinfengsq_Get( math.mod(math.floor(value/10),10 )))
		--g_Jinfengsq_shuzi_real[1]:SetProperty("Image", Jinfengsq_Get( math.mod(math.floor(value/100),10)))		
	end
end
function Jinfengsq_Get( value )	
	if value >= 0 and value <= 9 then
		return g_Jinfengsq_yishuzi[value]
	else
		return 0
	end
end

--===============================================
-- OnHiden
--===============================================
function Jinfengsq_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Jinfengsq_Frame_On_ResetPos()
	Jinfengsq_FrameNULL : SetProperty("UnifiedXPosition", g_Jinfengsq_Frame_UnifiedXPosition);
	Jinfengsq_FrameNULL : SetProperty("UnifiedYPosition", g_Jinfengsq_Frame_UnifiedYPosition);
end

function Jinfengsq_Frame_Mini_Clicked()
	PushEvent( "JFSQ_CHANGEUI", 0)--, g_Jinfengsq_Frame_UnifiedXPosition, g_Jinfengsq_Frame_UnifiedYPosition )
end