﻿//灯光数据相关库
#ifndef CUSTOM_LIGHT_INCLUDED
#define CUSTOM_LIGHT_INCLUDED

#define MAX_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_OTHER_LIGHT_COUNT 64
CBUFFER_START(_CustomLight)
	int _DirectionalLightCount;
	//定向光源颜色、方向、阴影等数据
    float4 _DirectionalLightColors[MAX_DIRECTIONAL_LIGHT_COUNT];
    float4 _DirectionalLightDirections[MAX_DIRECTIONAL_LIGHT_COUNT];
	//阴影数据
	float4 _DirectionalLightShadowData[MAX_DIRECTIONAL_LIGHT_COUNT];
	// 非定向光的属性
	int _OtherLightCount;
	float4 _OtherLightColors[MAX_OTHER_LIGHT_COUNT];
	float4 _OtherLightPositions[MAX_OTHER_LIGHT_COUNT];
	float4 _OtherLightDirections[MAX_OTHER_LIGHT_COUNT];
	float4 _OtherLightSpotAngles[MAX_OTHER_LIGHT_COUNT];
	float4 _OtherLightShadowData[MAX_OTHER_LIGHT_COUNT];
CBUFFER_END

//灯光的属性
struct Light {
	//颜色
	float3 color;
	//方向
	float3 direction;
	//衰减
	float attenuation;
};
//获取方向光源的数量
int GetDirectionalLightCount() {
	return _DirectionalLightCount;
}
//获取非定向光源的数量
int GetOtherLightCount()
{
    return _OtherLightCount;
}
//获取方向光的阴影数据
DirectionalShadowData GetDirectionalShadowData(int lightIndex, ShadowData shadowData) {
	DirectionalShadowData data;
    //data.strength = _DirectionalLightShadowData[lightIndex].x * shadowData.strength;
    data.strength = _DirectionalLightShadowData[lightIndex].x ;
	data.tileIndex = _DirectionalLightShadowData[lightIndex].y + shadowData.cascadeIndex;
	//法线偏差
	data.normalBias = _DirectionalLightShadowData[lightIndex].z;
	data.shadowMaskChannel = _DirectionalLightShadowData[lightIndex].w;
	return data;
}
//获取其它类型光的阴影数据
OtherShadowData GetOtherShadowData(int lightIndex)
{
    OtherShadowData data;;
    data.strength = _OtherLightShadowData[lightIndex].x;
    data.tileIndex = _OtherLightShadowData[lightIndex].y;
    data.shadowMaskChannel = _OtherLightShadowData[lightIndex].w;
    data.lightPositionWS = 0.0;
    data.spotDirectionWS = 0.0;
    data.isPoint = _OtherLightShadowData[lightIndex].z == 1.0;
    data.lightDirectionWS = 0.0;
    return data;
}

//获取目标索引定向光的属性
Light GetDirectionalLight (int index,Surface surfaceWS, ShadowData shadowData) {
	Light light;
	light.color = _DirectionalLightColors[index].rgb;
	light.direction = _DirectionalLightDirections[index].xyz;
	//得到阴影数据
	DirectionalShadowData dirShadowData = GetDirectionalShadowData(index,shadowData);
	//得到阴影衰减
	light.attenuation = GetDirectionalShadowAttenuation(dirShadowData,shadowData, surfaceWS);

	return light;
}
// 获取非定向光源的属性
Light GetOtherLight(int index, Surface surfaceWS, ShadowData shadowData)
{
    Light light;
    light.color = _OtherLightColors[index].rgb;
    float3 position = _OtherLightPositions[index].xyz;
	// float3写错成float，导致无法获取到正确的光源位置，从而错误
    float3 ray = position - surfaceWS.position;
    light.direction = normalize(ray);
	// 光照强度随着距离衰减
    float distanceSqr = max(dot(ray, ray), 0.00001);
	// 套用公式计算随光照范围衰减曲线
    float rangeAttenuation = Square(saturate(1.0 - Square(distanceSqr * _OtherLightPositions[index].w)));
    light.attenuation = rangeAttenuation / distanceSqr;
	// 得到聚光灯衰减
    float spotAttenuation = saturate(dot(position, light.direction));
	// 光照强度随范围和距离衰减	
    light.attenuation = spotAttenuation * rangeAttenuation / distanceSqr;
	
    float4 spotAngles = _OtherLightSpotAngles[index];
    float3 spotDirection = _OtherLightDirections[index].xyz;
	// 计算聚光灯的衰减
    spotAttenuation = Square(saturate(dot(spotDirection, light.direction) * spotAngles.x + spotAngles.y));
	// 光照强度随范围和距离衰减
	light.attenuation = spotAttenuation * rangeAttenuation / distanceSqr;
	
    OtherShadowData otherShadowData = GetOtherShadowData(index);
    otherShadowData.lightPositionWS = position;
    otherShadowData.lightDirectionWS = light.direction;
    otherShadowData.spotDirectionWS = spotDirection;
	// 光照强度随范围和距离衰减,加上了阴影
	light.attenuation = GetOtherShadowAttenuation(otherShadowData, shadowData, surfaceWS) * spotAttenuation * rangeAttenuation / distanceSqr;
	
    //light.attenuation = 1.0f;
    return light;
}


#endif