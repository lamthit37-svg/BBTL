#ifndef _TexKill_INC_
#define _TexKill_INC_

#include "ShaderLib/ParamNamed.inc"

void Tex_Kill( float alpha_test_value )
{
#if DISSOLVE_EFFECT > 0
	// 如果是溶解会有自己的kill
#else
	#if ALPHATEST_ENABLE
		clip( alpha_test_value - imodel_userdata.z );
	#endif
#endif
}

#if DISSOLVE_EFFECT > 0
	// 计算溶解颜色
	float4 Calc_Dissolve_Color_1(float4 color, float2 uv)
	{
		float4 outColor = color;
		float4 clipMask = tex2D(dissolveMap, uv * dissolveUVRepeat);
		float4 clipAlpha = tex2D(dissolveMap, uv);
		float _clipth = clipMask.r * clipAlpha.a;
		clip( _clipth - dissolveClip );
		float2 edge_area = saturate(1 - saturate((_clipth - dissolveClip - dissolveParams.xy) / dissolveParams.zw));
		outColor.rgb = lerp(outColor.rgb, dissolveColorA.rgb, edge_area.x);
		outColor.rgb = lerp(outColor.rgb, dissolveColorB.rgb, edge_area.y);
		//软边溶解计算，加上一个偏移值防止除以0的情况
		float radio = saturate((_clipth - dissolveClip) / ((dissolveSoftEdgeWidth + 0.001) * dissolveClip));
		outColor.a *= radio;
		return outColor;
	}

	#if DISSOLVE_EFFECT == 4
		// 随着时间进行溶解
		float4 Calc_Dissolve_Color_4(float4 color, float2 uv)
		{
			float dClipThd = saturate(dissolveClip);
			float dClip = (sin(time_0_x) + 1.0) * 0.5;
			dClip = (2.0 - dClipThd) * dClip - dClipThd; // -dClipThd ~ 1.0
			float4 outColor = color;
			float4 clipMask = tex2D(dissolveMap, uv * dissolveUVRepeat);
			float4 clipAlpha = tex2D(dissolveMap, uv);
			float _clipth = clipMask.r * clipAlpha.a;
			clip( _clipth - dClip );
			float2 edge_area = saturate(1 - saturate((_clipth - dClip - dissolveParams.xy) / dissolveParams.zw));
			outColor.rgb = lerp(outColor.rgb, dissolveColorA.rgb, edge_area.x);
			outColor.rgb = lerp(outColor.rgb, dissolveColorB.rgb, edge_area.y);
			return outColor;
		}
	#endif

    #if DISSOLVE_EFFECT == 5
        // 随着时间进行溶解
        float4 Calc_Dissolve_Color_5(float4 color, float2 uv, float3 po, float3 pw)
        {
            // 获取原来的颜色
            float4 outColor = color;

            // 根据 dissolveMaxProj 和 dissolveMinProj 计算投影范围
            // 然后将 世界空间坐标 和 溶解方向 点成得到当前点的投影
            // 根据投影范围将当前投影归一化
            float denom = dissolveMaxProj - dissolveMinProj;
            float proj = dot(pw, dissolveDirection);
            float projNorm = saturate((proj - dissolveMinProj) / denom);

            // 采样纹理坐标，有两个坐标分别对应 low 和 high，对这两个采样值进行差值可以让最后的采样结果显得躁动，不会出现很平滑的情况
            float2 uvFlow = (po.xy - float2(dissolveBox.x, dissolveBox.z)) / float2(dissolveBox.y - dissolveBox.x, dissolveBox.w - dissolveBox.z);
            uvFlow += 0.1415926;
            uvFlow *= 3.1415926;
            float texNoiseLow = tex2D(dissolveMap, uvFlow * dissolveUVRepeat).r;
            float texNoiseHigh = tex2D(dissolveMap, uvFlow * 3.1415926 * dissolveUVRepeat).r;
            float t = (0.1 + frac(time_0_x * dissolveFlowSpeed)) * (1.1 - frac(time_0_x * dissolveFlowSpeed));
            float texNoise = lerp(texNoiseLow, texNoiseHigh, t);

            // 这里的计算结果接近 (2.0 * dissolveClip) / dissolveEdgeContrast - texNoise
            // 因为 dissolveEdgeContrast 的范围是 -1 到 0，所以取值为正
            // 将计算后的值与 0.5 做对比，判断是否进行裁剪
            float cutoffTemp = 2.0 * dissolveClip + dissolveEdgeContrast;
            float rangeMask = (projNorm - cutoffTemp) / (abs(dissolveEdgeContrast) < 1e-6 ? (dissolveEdgeContrast >= 0.0 ? 1e-6 : -1e-6) : dissolveEdgeContrast);
            float cutoffValue = 1.0 - rangeMask - texNoise;
            cutoffValue = (1.0 - dissolveReverse) * cutoffValue + dissolveReverse * (1.0 - cutoffValue);
            float visible = step(0.5, cutoffValue);
            clip(visible - 0.5);

            float edgeRange = clamp(1.0 - distance(cutoffValue, 0.5) / dissolveEdgeRange, 0.0, 1.0);
            float2 rampUV = float2((1.0 - edgeRange), 0.5);

            float3 rampVal = tex2D(dissolveRampMap, rampUV).rgb;
            outColor.rgb = lerp(outColor.rgb, rampVal * dissolveEdgeColor.rgb * dissolveEdgeLighting, edgeRange);

            return outColor;
        }
    #endif
#endif

#endif