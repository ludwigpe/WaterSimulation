Shader "Custom/surfaceWater" {
	Properties {
		_Tess ("Tessellation", Range(1,32)) = 4
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Bump Map", 2D) = "bump" {}
		_BumpMap2 ("Bump Map 2", 2D) = "bump" {}
		_BumpDepth ("Bump depth", Range(0, 1.0)) = 1.0
		_DispTex ("Displacement Texture", 2D) = "gray" {}
		_Displacement ("Displacement", Range(0.0, 1.0)) = 0.3
		_Shininess ("Shininess", Range(1, 1000.0)) = 3.0
		_Steepness( "Steepness", Range(0.0, 1.0)) = 0.5
	}
	
	SubShader {
		
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:vert tessellate:tessFixed
        #pragma target 5.0
		#define numWaves 4
		const float PI = 3.14159265f;
		
		struct Wave {
		  float freq;  // 2*PI / wavelength
		  float amp;   // amplitude
		  float phase; // speed * 2*PI / wavelength
		  float2 dir;
		};

		Wave waves[2] = {
			{ 1.0, 10.10, 0.5, float2(-5.5, 2.0) },
			{ 5.0, 0.5, 1.3, float2(-0.7, 0.7) }	
		};
		
		struct appdata {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 tangent : TANGENT;

		};

		uniform float _Steepness;
		// helper functions
		float getWaveHeight(Wave w, float2 pos, float time)
		{
			return w.amp * sin( dot(w.dir, pos)*w.freq + time*w.phase);
		}
		// calculate the gerstner wave
		float3 getGerstnerHeight(Wave w, float2 pos, float time)
		{
			
			float Q = _Steepness/(w.freq*w.amp*numWaves);
			float3 gerstner = float3(0.0, 0.0, 0.0);
			gerstner.x = Q*w.amp*w.dir.x*cos( dot(w.freq*w.dir, pos) + w.phase * time);
			gerstner.z = Q*w.amp*w.dir.y*cos( dot(w.freq*w.dir, pos) + w.phase * time);
			gerstner.y = w.amp*sin( dot( w.freq*w.dir, pos) + w.phase * time);

			return gerstner;
			
		}


		uniform float _Tess;

        float4 tessFixed()
        {
            return _Tess;
        }

		// User defined variables

		uniform float4 _Color;
		uniform float _Shininess;

		half4 LightingSimpleSpecular (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {
			half3 h = normalize (lightDir + viewDir);

			half diff = max (0, dot (s.Normal, lightDir));

			float nh = max (0, dot (s.Normal, h));
			float spec = pow (nh, _Shininess);

			half4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * (atten * 2);
			c.a = s.Alpha;
			return c;
		}

		// variables for vertex shader
		uniform sampler2D _DispTex;
		uniform float _Displacement;

		void vert(inout appdata vIn) 
		{
			float2 p = float2(vIn.vertex.x, vIn.vertex.z);
			//float d = tex2Dlod(_DispTex, float4(vIn.texcoord.xy,0,0)).r * _Displacement;
			float d = 0.0f;
			float3 gerstnerTot = float3(0.0, 0.0, 0.0);
			Wave W[4] = {
				{ 1.0, 0.10, 0.5, float2(-5.5, 2.0) },
				{ 2.0, 0.5, 1.3, float2(-0.7, 0.7) },
				{ 1.0, 1.0, 0.5, float2(-1, 0) },
				{ 4.20, 0.050, 1.60, float2(1.0, 0.20) }	
			};
			for(int i = 0; i < 0; i++)
			{
				gerstnerTot += getGerstnerHeight(W[i], p, _Time.y); 
			}
			gerstnerTot/=2;
			//Wave w = waves[0];
			//Wave w = { 1.0, 1.0, 0.5, float2(-1, 0) };
			//Wave w = { 4.20, 0.050, 1.60, float2(1.0, 0.20) };
			//d = getWaveHeight(w, p, _Time.y);
			//vIn.vertex.xyz += vIn.normal * d ;
			//gerstnerTot = getGerstnerHeight(w, p , _Time.y);
			vIn.vertex.x += gerstnerTot.x;
			vIn.vertex.z += gerstnerTot.z;
			vIn.vertex.y = gerstnerTot.y;
			//vIn.vertex.xyz += gerstnerTot ;
		}

		uniform sampler2D _MainTex;
		uniform sampler2D _BumpMap;
		uniform sampler2D _BumpMap2;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_BumpMap2;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)) +  UnpackNormal(tex2D(_BumpMap2, IN.uv_BumpMap2));
			o.Specular = _Shininess;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
