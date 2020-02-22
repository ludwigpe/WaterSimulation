// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/proShader" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_ScatterColor ("Scatter Color", Color) = (0.3, 0.7, 0.6, 1.0)
		_WaterDeepColor ("Deep Water Color", Color) = (0.1, 0.4, 0.7, 1.0)
		_WaterSpecularIntensity ("Water Specular Intensity", Float) = 350
		_WaterSpecularPower ("Water Specular Power", Float) = 1000
		_WaterColorIntensityX ("Water Color Intensity X", Range(0.0,1.0)) = 0.1
		_WaterColorIntensityY ("Water Color Intensity Y", Range(0.0,1.0)) = 0.2
		_AtmosBrightColor ("Atmospheric Bright Color", Color) = (1.0, 1.1, 1.4, 1.0)
		_AtmosDarkColor ("Atmospheric Dark Color", Color) = (0.6, 0.6, 0.7, 1.0)
		_Shininess ("Shininess", Range(0.1, 10.0)) = 3.0
		_SunPower ("Sun Power", Float) = 1.0
		_NumWaves ("Number of waves", Range(1,32)) = 4
		_OceanDepth ("Ocean Depth", Range(1,50)) = 20
		_BumpDepth ("Bump depth", Range(0, 1.0)) = 1.0
		_BumpMap ("Bump Map", 2D) = "bump" {}
		_BumpMap2 ("Bump Map 2", 2D) = "bump" {}
		_Reflectivity("Reflectivity", Range(0.0, 1.0)) = 1.0
		_ReflMap("Reflection Map", Cube) = "cube" {}
	}
	SubShader {
		Pass
		{
			Tags { "RenderType"="Opaque" }
			LOD 200
		
			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma vertex vert
			#pragma fragment frag
			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 3.0
			uniform float4 _Color;
			uniform float4 _SpecColor;
			uniform float4 _ScatterColor;
			uniform float4 _WaterDeepColor;
			uniform float _WaterSpecularIntensity;
			uniform float _WaterSpecularPower;
			uniform half _WaterColorIntensityX;
			uniform half _WaterColorIntensityY;
			uniform float4 _AtmosBrightColor;
			uniform float4 _AtmosDarkColor;
			uniform float _Shininess;
			uniform half _SunPower;
			uniform half _NumWaves;
			uniform half _OceanDepth;
			uniform half _BumpDepth;
			uniform sampler2D _BumpMap;
			uniform float4 _BumpMap_ST;
			uniform sampler2D _BumpMap2;
			uniform float4 _BumpMap2_ST;

			uniform half _Reflectivity;
			uniform samplerCUBE _ReflMap;
			
			// private values
			uniform float3 _SunDir;
			uniform float3 _SunColor;
			uniform int _NumCreatedWaves;

					
			// Unity Defined uniforms
			uniform float4 _LightColor0;

			struct Wave {
				float freq;  // 2*PI / wavelength
				float amp;   // amplitude
				float phase; // speed * 2*PI / wavelength
				float2 dir;
			};

			// Input struct for vertex shader
			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;

			};

			// Output struct from vertex shader and input to fragment shader
			struct VertexOutput {
				float4 pos : POSITION;
				float4 tex : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 tangentWorld : TEXCOORD3;
				float3 binormalWorld : TEXCOORD4;
			};

			uniform StructuredBuffer<Wave> waveBuffer;

			// compute the gerstner offset for one wave 
			float3 getGerstnerOffset(float2 x0, Wave w, float time)
			{
				float k = length(w.dir);
				float2 x = (w.dir / k)* w.amp * sin( dot( w.dir, x0) - w.freq * time +w.phase);
				float y = w.amp * cos( dot( w.dir, x0) - w.freq*time + w.phase);
				return float3(x.x, y, x.y);
			}

			// Helper function to compute the binormal of the offset wave point
			// This comes from the taking the derivative of the Gerstner surface in the x-direction
			float3 computeBinormal(float2 x0, Wave w, float time)
			{
				float3 B = float3(0, 0, 0);
				half k = length(w.dir);
				B.x = w.amp * (pow(w.dir.x, 2) / k) * cos( dot(w.dir, x0) - w.freq * time + w.phase);
				B.y = -w.amp * w.dir.x * sin( dot(w.dir, x0) - w.freq * time + w.phase);
				B.z = w.amp * ((w.dir.y * w.dir.x)/ k) * cos( dot(w.dir, x0) - w.freq * time + w.phase);
				return B;
			}

			// Helper function to compute the tangent vector of the offset wave point
			// This comes from the taking the derivative of the Gerstner surface in the z-direction
			float3 computeTangent(float2 x0, Wave w, float time)
			{
				float3 T = float3(0, 0, 0);
				half k = length(w.dir);
				T.x = w.amp * ((w.dir.y * w.dir.x)/ k) * cos( dot(w.dir, x0) - w.freq * time + w.phase);
				T.y = -w.amp * w.dir.x * sin( dot(w.dir, x0) - w.freq * time + w.phase);
				T.z = w.amp * (pow(w.dir.y, 2) / k) * cos( dot(w.dir, x0) - w.freq * time + w.phase);
				return T;		
			}
		
			float fresnel(float3 V, float3 N)
			{	
				
				half NdotL = max( dot(V, N), 0.0);
				half fresnelBias = 0.4;
				half fresnelPow = 5.0;
				fresnelPow = _SunPower;

				half facing  = (1.0 - NdotL);
				return max( fresnelBias + (1-fresnelBias) * pow(facing, fresnelPow), 0.0);
			}	

			float3 computeSunColor(float3 V, float3 N)
			{
				float3 HalfVector = normalize( abs( V + (-_SunDir)));
				return _SunColor * pow( abs( dot(HalfVector, N)), _SunPower);

			}

			// primitive simulation of non-uniform atmospheric fog
			float3 CalculateFogColor(float3 pixel_to_light_vector, float3 pixel_to_eye_vector)
			{
				return lerp(_AtmosDarkColor,_AtmosBrightColor,0.5*dot(pixel_to_light_vector,-pixel_to_eye_vector)+0.5);
			}

			VertexOutput vert(VertexInput vIn) 
			{
				VertexOutput vOut;
				// save the original point on the horizontal plane as x0
				half2 x0 = vIn.vertex.xz;
				float3 newPos = float3(0.0, 0.0, 0.0);
				float3 tangent = float3(0, 0, 0);
				float3 binormal = float3(0, 0, 0);
				int nw = min(_NumWaves, _NumCreatedWaves);
				for(int i = 0; i < nw; i++)
				{
					Wave w = waveBuffer[i];
					newPos += getGerstnerOffset(x0, w, _Time.y);
					binormal += computeBinormal(x0, w, _Time.y);
					tangent += computeTangent(x0, w, _Time.y);
				}
				// fix binormal and tangent
				binormal.x = 1 - binormal.x;
				binormal.z = 0 - binormal.z;

				tangent.x = 0 - tangent.x;
				tangent.z = 1 - tangent.z;
				// displace vertex 
				vIn.vertex.x -= newPos.x;
				vIn.vertex.z -= newPos.z;
				vIn.vertex.y = newPos.y;
				vOut.pos = UnityObjectToClipPos(vIn.vertex);		// transform from local to screen space
				vOut.posWorld = mul(unity_ObjectToWorld, vIn.vertex);		// transform from local to world space
				//vOut.posWorld = mul(_Object2World, vIn.vertex);		// transform from local to world space
				vOut.tangentWorld = normalize( mul( float4(tangent.xyz, 0.0), unity_ObjectToWorld).xyz);
				vOut.binormalWorld = normalize( mul( float4(binormal.xyz, 0.0), unity_ObjectToWorld).xyz);
				vOut.normalDir = normalize( cross( vOut.tangentWorld, vOut.binormalWorld) * vIn.tangent.w);
				vOut.tex = vIn.texcoord;

				return vOut;
			}

			float4 frag(VertexOutput i) : COLOR
			{
				float3 vDir = normalize( _WorldSpaceCameraPos.xyz - i.posWorld.xyz); // compute view direction (posWorld -> cameraPos)
				float3 lDir;
				float3 pixelToLight = normalize(_WorldSpaceLightPos0.xyz - i.posWorld.xyz );
				pixelToLight = _SunDir;
				float3 pixelToEye = normalize( _WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float3 reflectedEyeToPixel;
				float fresnelFactor;
				float diffuseFactor;
				float specularFactor;
				float scatterFactor;
				float shadowFactor = 0.01;
				float4 refractionColor;
				float4 reflectionColor;
				float4 disturbanceEyespace;
				float atten;
				float waterDepth;
				if(_WorldSpaceLightPos0.w == 0.0) //  Directional light
				{
					atten = 1.0;
					lDir = normalize( _WorldSpaceLightPos0.xyz );
					
				} else {
					float3 fragToLight = _WorldSpaceLightPos0.xyz - i.posWorld ;
					atten = 1.0 / length(fragToLight);
					lDir = normalize ( fragToLight );
				}

				// texture map
				//float4 tex = tex2D( _MainTex, i.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw );
				float4 texN = tex2D( _BumpMap, i.tex.xy * _BumpMap_ST.xy + _BumpMap_ST.zw );
				float4 texN2 = tex2D( _BumpMap2, i.tex.xy * _BumpMap2_ST.xy + _BumpMap2_ST.zw );

				// unpack normal
				float3 localCoords = float3(2.0 * texN.ag - float2(1.0, 1.0), 0.0);
				float3 localCoords2 = float3(2.0 * texN2.ag - float2(1.0, 1.0), 0.0);
				//localCoords.z = 1.0 - 0.5 * dot( localCoords, localCoords)
				localCoords.z = _BumpDepth;
				localCoords2.z = _BumpDepth;

				// normal transpose matrix
				float3x3 local2WorldTranspose = float3x3(i.tangentWorld, i.binormalWorld, i.normalDir);

				float3 nDir = normalize( mul( localCoords, local2WorldTranspose) );
				float3 nDir2 = normalize( mul( localCoords2, local2WorldTranspose) );
				nDir = normalize(nDir + nDir2);

				// fake light scatter at crest of water
				scatterFactor =  2.5 *max(0, i.posWorld.y * 0.25 + 0.25);
				scatterFactor *= shadowFactor*pow(saturate( dot(normalize(float3(pixelToLight.x, 0.0, pixelToLight.z)),-pixelToEye )),2);
				// slopes of water that are oriented back to the light gets more double refraction
				scatterFactor *= pow( max(0.0, 1.0 - dot( pixelToLight, nDir)), 8.0);
				scatterFactor += shadowFactor *1.5 * _WaterColorIntensityY* max( 0, i.posWorld.y + 1) * max(0, dot( pixelToEye, nDir)) * max(0, 1 -pixelToEye.y) * (300.0/length(_WorldSpaceCameraPos.xyz - i.posWorld));
				scatterFactor = clamp(scatterFactor, 0, 0.5);
				// Fade scatterFactor near shores TODO!!

				float r = (1.2-1-0)/(1.2+1.0);
				fresnelFactor = max(0.0, min(1.0, r+(1.0-r)*pow(1.0-dot( nDir, pixelToEye), 4)));
				//fresnelFactor =fresnel(pixelToEye, nDir);
				// can use CG reflect(eye, normal)?
				//reflectedEyeToPixel = -pixelToEye + 2*dot(pixelToEye, nDir)*nDir;
				reflectedEyeToPixel = reflect(-pixelToEye, nDir);
				// specular factor
				specularFactor = shadowFactor * fresnelFactor * pow(saturate(dot(pixelToLight, reflectedEyeToPixel)), _WaterSpecularPower);
				
				// diffuse factor
				//diffuseFactor = atten * _LightColor0.xyz * saturate( dot(pixelToLight, nDir));
				diffuseFactor = _WaterColorIntensityX + _WaterColorIntensityY * saturate( dot(pixelToLight, nDir)) * _LightColor0.xyz;
				
				// water depth
				waterDepth = max(0, length(_WorldSpaceCameraPos.xyz - i.posWorld.xyz)*_OceanDepth);

				// relfection color
				//reflectionColor.rgb = _WaterSpecularIntensity*scatterFactor*reflectionColor*fresnelFactor;

				// water color
				float3 waterColor = diffuseFactor * lerp(_Color, _WaterDeepColor, length(_WorldSpaceCameraPos.xyz - i.posWorld)/100.0);
				float fogDensity = 1.0/700.0;
				waterColor.rgb=lerp(CalculateFogColor(pixelToLight,pixelToEye).rgb,waterColor.rgb,min(1,exp(-length(_WorldSpaceCameraPos.xyz-i.posWorld.xyz)*fogDensity)));
				reflectionColor.rgb = texCUBE(_ReflMap, reflectedEyeToPixel).rgb * _Reflectivity;
				//reflectionColor.rgb = lerp(reflectionColor, waterColor, 1.0/length(_WorldSpaceCameraPos.xyz - i.posWorld));
				refractionColor.rgb = lerp(waterColor * 1.5, waterColor* 0.5, min(1, 1.0*exp(-waterDepth/8.0)));
				refractionColor.rgb = diffuseFactor * lerp(_Color, _WaterDeepColor, length(_WorldSpaceCameraPos.xyz - i.posWorld)/100.0);

				fresnelFactor *= min(length(_WorldSpaceCameraPos.xyz - i.posWorld.xyz)/10.0, 1.0);
				//float3 scatterColor = float3(0.3, 0.7, 0.6);
				float4 color;
				float L = length(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				color.rgb = lerp(waterColor, reflectionColor.rgb, clamp(L*fresnelFactor/25, 0, 0.5));
				color.rgb += _WaterSpecularIntensity*specularFactor*_SpecColor*fresnelFactor;
				color.rgb += _ScatterColor * scatterFactor;
				color.rgb += computeSunColor(-pixelToEye, nDir);

				color.a = 1.0;
				return color;	
			}

			ENDCG
		}
		
	} 
	FallBack "Diffuse"
}
