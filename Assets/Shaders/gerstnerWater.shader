// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/gerstnerWater" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Bump Map", 2D) = "bump" {}
		_BumpMap2 ("Bump Map 2", 2D) = "bump" {}
		_BumpDepth ("Bump depth", Range(0, 1.0)) = 1.0
		_Shininess ("Shininess", Range(1, 100.0)) = 3.0
		_Steepness( "Steepness", Range(0.0, 1.0)) = 0.5
	}
	
	SubShader {
		Pass 
		{
		Tags {"LightMode" = "ForwardBase"}
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		#define numWaves 10
		const float PI = 3.14159265f;
		// User defined variables
		uniform float4 _GridSizes;
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		
		uniform sampler2D _BumpMap;
		uniform float4 _BumpMap_ST;
		uniform sampler2D _BumpMap2;
		uniform float4 _BumpMap2_ST;
		uniform float _BumpDepth;
		
		uniform float4 _Color;
		uniform float4 _SpecColor;
		uniform float _Shininess;
		uniform float _Steepness;

		// Unity Defined uniforms
		uniform float4 _LightColor0;
		
		struct Wave {
		  float freq;  // 2*PI / wavelength
		  float amp;   // amplitude
		  float phase; // speed * 2*PI / wavelength
		  float2 dir;
		};
		// hard coded gerstner waves
		uniform Wave waves[10] = 
		{
			{ 0.4, 0.10, 0.5, float2(-5.5, 2.0) },
			{ 0.32, 0.5, 0.3, float2(-0.7, 0.7) },
			{ 1.0, 0.02, 0.5, float2(-1, 0) },
			{ 0.20, 0.15, 1.60, float2(1.0, 0.20) },
			{ 0.020, 0.25, 1.32, float2(1.2, 0.10) },	
			{ 0.020, 0.056, 1.53, float2(1.4, 0.50) },	
			{ 1.20, 0.35, 3.60, float2(0.50, 2.20) },	
			{ 0.20, 0.05, 0.60, float2(2.50, -2.20) },	
			{ 0.50, 1.42, 1.60, float2(-4.0, -1.20) },	
			{ 0.30, 0.01, 2.330, float2(-2.0, -1.60) }	
		};

	
		// calculate the gerstner wave
		float3 getGerstnerHeight(Wave w, float2 pos, float time)
		{
			
			float Q = _Steepness/(w.freq*w.amp*numWaves);
			Q = 0.1f;
			float3 gerstner = float3(0.0, 0.0, 0.0);
			gerstner.x = Q*w.amp*w.dir.x*cos( dot(w.freq*w.dir, pos) + w.phase * time);
			gerstner.z = Q*w.amp*w.dir.y*cos( dot(w.freq*w.dir, pos) + w.phase * time);
			gerstner.y = w.amp*sin( dot( w.freq*w.dir, pos) + w.phase * time);

			return gerstner;
			
		}

		float3 computePartialBinormal(Wave w, float3 P, float time)
		{
			float3 B = float3(0.0, 0.0, 0.0);
			float2 p = float2(P.x, P.z);
			float inner = w.freq * dot(w.dir, p) + w.phase * time;
			float WA = w.freq * w.amp;
			float Q = _Steepness/(w.freq*w.amp*numWaves);
			Q = 0.1f;
			B.x = Q * pow(w.dir.x, 2) * WA * sin(inner);
			B.z = Q * w.dir.x * w.dir.y * WA * sin(inner);
			B.y = w.dir.x * WA * cos(inner);

			return B;
		}

		float3 computePartialTangent(Wave w, float3 P, float time)
		{
			float3 T = float3(0.0, 0.0, 0.0);
			float2 p = float2(P.x, P.z);
			float inner = w.freq * dot(w.dir, p) + w.phase * time;
			float WA = w.freq * w.amp;
			float Q = _Steepness/(w.freq*w.amp*numWaves);
			Q = 0.1f;
			T.x = Q * w.dir.x * w.dir.y * WA * sin(inner);
			T.z = Q * pow(w.dir.y, 2) * WA * sin(inner);
			T.y = w.dir.y * WA * cos(inner);

			return T;
		}

		float3 computePartialGerstnerNormal(Wave w, float3 P, float time)
		{
			float3 N = float3(0.0, 0.0, 0.0);
			float2 p = float2(P.x, P.z);
			float inner = w.freq*dot(w.dir, p) + w.phase * time;
			float WA = w.freq * w.amp;
			float Q = _Steepness/(w.freq*w.amp*numWaves);
			Q = 0.1f;
			N.x = w.dir.x * WA * cos(inner);
			N.z = w.dir.y * WA * cos(inner);
			N.y = Q * WA * sin(inner);
			
			return N;
		}
		
		// Input struct for vertex shader
		struct VertexInput {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float4 texcoord : TEXCOORD0;
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

		VertexOutput vert(VertexInput vIn) 
		{
			VertexOutput vOut;
			float2 p = float2(vIn.vertex.x, vIn.vertex.z);
			float d = 0.0f;
			float3 gerstnerTot = float3(0.0, 0.0, 0.0);
			Wave W[10] = 
			{
				{ 0.050, 0.20, 1.5, float2(-5.5, 2.0) },
				{ 0.120, 0.55, 1.3, float2(-0.7, 0.7) },
				{ 0.2020, 0.01, 0.5, float2(-1, 0) },
				{ 0.120, 1.15, 1.60, float2(1.0, 0.20) }	,
				{ 0.020, 10.25, 1.32, float2(1.2, 0.10) },	
				{ 0.020, 0.056, 1.53, float2(1.4, 0.50) },	
				{ 0.120, -0.35, 3.60, float2(0.50, 2.20) },	
				{ 0.120, -0.05, 0.60, float2(2.50, -2.20) },	
				{ 0.050, -0.42, 1.60, float2(-4.0, -1.20) },	
				{ 0.50, 0.01, 2.330, float2(-2.0, -1.60) }	
			};

			// compute the position
			for(int i = 0; i < numWaves; i++)
			{
				gerstnerTot += getGerstnerHeight(W[i], p, _Time.y); 
			}

			float3 T = vIn.tangent.xyz;
			T = float3(0.0, 0.0, 0.0);
			for(int i = 0; i < numWaves; i++)
			{
				T += computePartialTangent(W[i], gerstnerTot, _Time.y);
			}
			T.x *= -1;
			T.z = 1-T.z;
			
			float3 B = float3(0.0, 0.0, 0.0);
			for(int i = 0; i < numWaves; i++)
			{
				B += computePartialBinormal(W[i], gerstnerTot, _Time.y);
			}
			B.x = 1 - B.x;
			B.z *= -1;
			
			/*
			float3 N = vIn.normal;
			for(int i = 0; i < numWaves; i++)
			{
				N += computePartialGerstnerNormal(waves[i], gerstnerTot, _Time.y);
			}
			N.x *= -1;
			N.z *= -1;
			N.y = 1 - N.y;

			*/
			float3 N = cross(T, B);
			
			//gerstnerTot/=4;
			vIn.vertex.x += gerstnerTot.x;
			vIn.vertex.z += gerstnerTot.z;
			vIn.vertex.y = gerstnerTot.y;
			vOut.pos = UnityObjectToClipPos(vIn.vertex);		// transform from local to screen space
			vOut.posWorld = mul(unity_ObjectToWorld, vIn.vertex);		// transform from local to world space
			vOut.normalDir = normalize( mul(float4(N, 0.0), unity_ObjectToWorld).xyz );
			vOut.tangentWorld = normalize( mul( float4(T, 0.0), unity_ObjectToWorld).xyz );
			vOut.binormalWorld = normalize( mul( float4(B, 0.0), unity_ObjectToWorld).xyz );
			vOut.tex = vIn.texcoord;

			/*vOut.normalDir = N;
			vOut.tangentWorld = T;
			vOut.binormalWorld = B;*/
			return vOut;

		}


		float4 frag(VertexOutput i) : COLOR
		{
			
			float3 vDir = normalize( _WorldSpaceCameraPos.xyz - i.posWorld.xyz); // compute view direction (posWorld -> cameraPos)
			float3 lDir;
			float atten;
			if(_WorldSpaceLightPos0.w == 0.0) //  Directional light
			{
				atten = 1.0;
				lDir = normalize( _WorldSpaceLightPos0.xyz );
			} else {
				float3 fragToLight = _WorldSpaceLightPos0.xyz - i.posWorld ;
				atten = 1.0 / length(fragToLight);
				lDir = normalize ( fragToLight );
			}
			float2 uv = i.posWorld.xz;
			// texture map
			
			float4 tex = tex2D( _MainTex, i.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw );
			float4 texN = tex2D( _BumpMap, i.tex.xy * _BumpMap_ST.xy + _BumpMap_ST.zw );
			float4 texN2 = tex2D( _BumpMap2, i.tex.xy * _BumpMap2_ST.xy + _BumpMap2_ST.zw );
			
			/*
			float4 tex = tex2D( _MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw );
			float4 texN = tex2D( _BumpMap, uv * _BumpMap_ST.xy + _BumpMap_ST.zw );
			float4 texN2 = tex2D( _BumpMap2, uv * _BumpMap2_ST.xy + _BumpMap2_ST.zw );

			slope += tex2D(_Map1, uv/_GridSizes.x).xy;
			*/

			// unpack normal
			float3 localCoords = float3(2.0 * texN.ag - float2(1.0, 1.0), 0.0);
			float3 localCoords2 = float3(2.0 * texN2.ag - float2(1.0, 1.0), 0.0);
			//localCoords.z = 1.0 - 0.5 * dot( localCoords, localCoords)
			localCoords.z = _BumpDepth;
			localCoords2.z = _BumpDepth;

			// normal transpose matrix
			float3x3 local2WorldTranspose = float3x3(i.tangentWorld, i.binormalWorld, i.normalDir);

			float3 nDir = normalize( mul( localCoords, local2WorldTranspose) );

			//float3 nDir2 = normalize( mul( localCoords2, local2WorldTranspose) );
			//nDir = normalize(nDir + nDir2);
			// diffuse lighting
			float3 diffRefl = atten * _LightColor0.xyz * saturate( dot( nDir, lDir) );
			float3 specRefl = diffRefl * _SpecColor.xyz * pow( saturate( dot( reflect( -lDir, nDir), vDir) ), _Shininess);	

			float3 lightFinal = UNITY_LIGHTMODEL_AMBIENT.xyz + diffRefl + specRefl;
			/*lightFinal = UNITY_LIGHTMODEL_AMBIENT.xyz + nDir;
			return float4(lightFinal, 1.0);*/
			return float4(tex.xyz * lightFinal * _Color.xyz, 1.0);
		}
		ENDCG
		}
		
	} 
	FallBack "Diffuse"
}
