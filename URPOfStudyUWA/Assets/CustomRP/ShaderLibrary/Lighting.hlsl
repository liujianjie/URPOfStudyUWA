﻿//光照计算相关库
#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED
//计算入射光照
float3 IncomingLight (Surface surface, Light light) {
	return saturate(dot(surface.normal, light.direction)* light.attenuation) * light.color;
}
//入射光乘以光照照射到表面的直接照明颜色,得到最终的照明颜色
float3 GetLighting (Surface surface, BRDF brdf, Light light) {
	return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
}

//根据物体的表面信息和灯光属性获取最终光照结果
float3 GetLighting(Surface surfaceWS, BRDF brdf,  GI gi) {
	//得到表面阴影数据
	ShadowData shadowData = GetShadowData(surfaceWS);
    shadowData.shadowMask = gi.shadowMask;
    //return gi.shadowMask.shadows.rgb;
	
	//可见光的光照结果进行累加得到最终光照结果
	// 记住: 因为这里*了brdf.diffuse导致之前的小节不正确。。。
	//float3 color = gi.diffuse * brdf.diffuse;
	// brdf.diffuse是表面的漫反射,gi.diffuse是全局光照的漫反射
    //color = gi.diffuse * brdf.diffuse;
    //color = brdf.diffuse;
    float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, brdf, light);
	}

	#if defined(_LIGHTS_PER_OBJECT)
	
		for (int j = 0; j < min(unity_LightData.y, 8); j++)
		{
			int lightIndex = unity_LightIndices[(uint) j / 4][(uint) j % 4];
			Light light = GetOtherLight(lightIndex, surfaceWS, shadowData);
			color += GetLighting(surfaceWS, brdf, light);
		}
		
	#else
		for (int j = 0; j < GetOtherLightCount(); j++)
		{
			Light light = GetOtherLight(j, surfaceWS, shadowData);
			color += GetLighting(surfaceWS, brdf, light);
			//color = float3(0.5f,0.5f,0.5f);
		}
	#endif
    return color;
}



#endif
