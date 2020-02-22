// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/tesselatedWater" {
	Properties {
		_Tess ("Tessellation", Range(1,32)) = 4
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.03, 1)) = 0.078125
		_Steepness( "Steepness", Range(0.0, 1.0)) = 0.5
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Bump Map", 2D) = "bump" {}
		_BumpMap ("Bumpt Map2", 2D) = "bump" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Lambert addshadow fullforwardshadows vertex:vert tessellate:tessFixed
		#define numWaves 3
		const float PI = 3.14159265f;
		
		struct Wave {
		  float freq;  // 2*PI / wavelength
		  float amp;   // amplitude
		  float phase; // speed * 2*PI / wavelength
		  float2 dir;
		};

		// hard coded gerstner waves
		uniform Wave waves[10] = 
		{
			{ 10.0, 10.10, 0.5, float2(-5.5, 2.0) },
			{ 2.0, 0.5, 1.3, float2(-0.7, 0.7) },
			{ 1.0, 1.0, 0.5, float2(-1, 0) },
			{ 4.20, 0.15, 1.60, float2(1.0, 0.20) }	,
			{ 4.20, 0.25, 1.32, float2(1.2, 0.10) },	
			{ 0.20, 0.056, 1.53, float2(1.4, 0.50) },	
			{ 1.20, 0.35, 3.60, float2(0.50, 2.20) },	
			{ 2.20, 0.05, 0.60, float2(2.50, -2.20) },	
			{ 0.50, 1.42, 1.60, float2(-4.0, -1.20) },	
			{ 0.30, 0.01, 2.330, float2(-2.0, -1.60) }	
		};

		struct appdata {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 tangent : TANGENT;
		};

		uniform float _Steepness;
		// helper functions
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
		
		
		// Tesselation function
		uniform float _Tess;
		float4 tessFixed()
        {
            return _Tess;
        }
		
		// Vertex shader function. Should do displacement here.
		void vert(inout appdata vIn)
		{
			float2 p = float2(vIn.vertex.x, vIn.vertex.z);
			float d = 0.0f;
			float3 gerstnerTot = float3(0.0, 0.0, 0.0);
			/*
			Wave waves[10] = 
			{
				{ 1.010, 0.10, 0.5, float2(-5.5, 2.0) },
				{ 1.020, 0.5, 1.3, float2(-0.7, 0.7) },
				{ 1.0020, 0.01, 0.5, float2(-1, 0) },
				{ 0.120, 0.15, 1.60, float2(1.0, 0.20) }	,
				{ 1.020, 0.25, 1.32, float2(1.2, 0.10) },	
				{ 1.020, 0.056, 1.53, float2(1.4, 0.50) },	
				{ 0.120, -0.35, 3.60, float2(0.50, 2.20) },	
				{ 0.120, -0.05, 0.60, float2(2.50, -2.20) },	
				{ 1.050, -0.42, 1.60, float2(-4.0, -1.20) },	
				{ 0.50, 0.01, 2.330, float2(-2.0, -1.60) }	
			};
			
			Wave waves[10] = {
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
			*/

			Wave waves[3] = {
				{4, 0.5, 1.0, float2(1.0, 0.0)},
				{2, 0.2, 1.0, float2(1.0, -0.5)},
				{2, 0.3, 1.0, float2(-1.0, -1.5)}
			};

			for(int i = 0; i < numWaves; i++)
			{
				gerstnerTot += getGerstnerHeight(waves[i], p, _Time.y); 
			}
			

			// Compute binormal
			// Compute Tangent
			// Compute Normal
			float3 N = float3(0.0, 0.0, 0.0);
			for(int i = 0; i < numWaves; i++)
			{
				N += computePartialGerstnerNormal(waves[i], gerstnerTot, _Time.y);
			}
			N.x *= -1;
			N.z *= -1;
			N.y = 1 - N.y;
			//N.x *=-1;
			//N.z = 1 - N.z;
			//N.y *= -1;
			//gerstnerTot/=numWaves;
			vIn.vertex.x += gerstnerTot.x;
			vIn.vertex.z += gerstnerTot.z;
			vIn.vertex.y = gerstnerTot.y;

			vIn.normal = normalize( mul(float4(N, 0.0), unity_WorldToObject).xyz );
		}
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			//float3 worldNormal;
		};

		sampler2D _MainTex;
		sampler2D _BumpMap;
		fixed4 _Color;
		half _Shininess;

		void surf (Input IN, inout SurfaceOutput o) {
			o.Albedo = dot(o.Normal.xyz, _Color.rgb);
			/*
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Gloss = tex.a;
			o.Alpha = tex.a * _Color.a;
			o.Specular = _Shininess;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			*/
			//o.Normal = IN.worldNormal;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
