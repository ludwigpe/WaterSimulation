Shader "Custom/sineWave" {
	Properties {
		_Tess ("Tessellation", Range(1,32)) = 4
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.03, 1)) = 1
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Bump Map", 2D) = "bump" {}
		_BumpMap2 ("Bump Map 2", 2D) = "bump" {}
		_ReflMap("Reflection Map", Cube) = "cube" {}
		_WaveLength ("Wave Length", Range(0.1, 10.0)) = 0.5
		_Amp ( "Wave Amplitude", Float) = 0.5
		_Speed( "Wave Speed", Float) = 0.2
		_Dir ( "Wave Direction", Vector) = (1.0, 0.0, 0.0, 0.0)
		_Sharpness ("Sharpness", Range(1,3)) = 1.0
		_ReflecTivity("Reflectivity", Range(0.0, 1.0)) = 1.0
	}
	SubShader {

		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

        
		LOD 200
	
		CGPROGRAM
		#pragma surface surf BlinnPhong alpha addshadow fullforwardshadows vertex:vert tessellate:tessFixed
		#pragma debug
		#define numWaves 5
		#define PI 3.14159265
		#define sharp 1
		
		struct Wave {
		  float freq;  // 2*PI / wavelength
		  float amp;   // amplitude
		  float phase; // speed * 2*PI / wavelength
		  float2 dir;
		};
		sampler2D _MyGrabTexture;

		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _BumpMap2;
		fixed4 _Color;
		half _Shininess;
		uniform samplerCUBE _ReflMap;
		uniform float _WaveLength;
		uniform float _Amp;
		uniform float _Speed;
		uniform float4 _Dir;
		uniform float _Sharpness;
		uniform half _ReflecTivity;
		// Tesselation function
		uniform float _Tess;
		float4 tessFixed()
        {
            return _Tess;
        }
		struct appdata {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 tangent : TANGENT;
		};
		
		float getHeightFromWave(float2 P, Wave W, float t)
		{
			float inner = sin( dot(W.dir, P) * W.freq + W.phase*t);
			/*
			if(sharp)
			{
				return 2* W.amp * pow(((inner + 1) / 2), _Sharpness);
			}
			else
			{
				return W.amp * inner;
			}
			*/
			return W.amp * sin( dot(W.dir, P) * W.freq + W.phase*t);
		}
		
		float getGradientX(float2 P, Wave W, float t)
		{
			float inner = (( dot(W.dir, P) * W.freq )+ (W.phase * t));
			if(sharp)
			{
				float extra = pow(((sin(inner) + 1) / 2), _Sharpness - 1); // the extra part
				return _Sharpness * W.freq * W.dir.x * W.amp * extra *  cos(inner); // Eq. 8b
			}
			else
			{
				return W.freq * W.dir.x * W.amp * cos(inner);
			}
			
		}

		float getGradientY(float2 P, Wave W, float t)
		{
			float inner = (( dot(W.dir, P) * W.freq )+ (W.phase * t));
			if(sharp)
			{
				float extra = pow(((sin(inner) + 1) / 2), _Sharpness - 1); // the extra part
				return _Sharpness * W.freq * W.dir.x * W.amp * extra *  cos(inner); // Eq. 8b
			}
			else
			{
				return W.freq * W.dir.y * W.amp * cos(inner);	
			}
			
		}

		float3 getReflectVector(float3 N, float3 ViewDir) 
		{
			N = normalize(N);
			float3 reflVec = float3(0.0, 0.0, 0.0);
			reflVec = ViewDir - (2* dot(ViewDir, N)* N);
			return reflVec;
		}
		
		// Vertex shader function. Should do displacement here.
		//void vert (inout appdata_full vIn, out Input o) 
		void vert(inout appdata vIn)
		{
		
			float2 p = float2(vIn.vertex.x, vIn.vertex.z);
			Wave waves[5] = {
				{(2*PI)/_WaveLength, _Amp, (_Speed * 2 * PI) / _WaveLength, _Dir.xy},
				{1.5 * (2*PI)/_WaveLength, _Amp*1.5, (_Speed *0.5 * 2 * PI) / _WaveLength, _Dir.yx},
				{0.5* (2*PI)/_WaveLength, _Amp*5, (_Speed *0.1 * 2 * PI) / _WaveLength, float2(0.5, 0.5)},
				{2.5* (2*PI)/_WaveLength, _Amp*0.5, (_Speed *1.5 * 2 * PI) / _WaveLength, float2(-0.4, -0.6)},
				{0.75* (2*PI)/_WaveLength, _Amp*0.2, (_Speed *5 * 2 * PI) / _WaveLength, float2(-0.2, 0.8)}
			};
			//float h = getSineHeight(p, _Time.y);
			float time = _Time.y;
			float h = 0.0f;
			float dx = 0.0f;
			float dz = 0.0f;
			for(int i = 0; i < numWaves; i++)
			{
				Wave w = waves[i];
				h += getHeightFromWave(p, w, time);
				dx += getGradientX(p, w, time);
				dz += getGradientY(p, w, time);	
			}
			
			vIn.vertex.y += h;
			vIn.normal = normalize(float3(-dx, 1.0, -dz));
			vIn.tangent = float4(0.0, dz, 1.0, 0.0);
			float3 T = float3(0.0, dz, 1.0);
			float3 B = float3(1.0, dx, 0.0);
			//vIn.normal = normalize( cross( B, T));

		}


		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_BumpMap2;
			float3 worldPos;
			float3 worldNormal;
			float3 viewDir;
			float3 worldRefl;
			INTERNAL_DATA

		};

		
		void surf (Input IN, inout SurfaceOutput o) {

			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = tex.rgb * _Color.rgb;
			o.Gloss = _Shininess;
			o.Alpha = _Color.a;
			o.Specular = _Shininess;
			o.Normal = normalize(UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)) + UnpackNormal(tex2D(_BumpMap2, IN.uv_BumpMap2)) );
			float3 worldRefl = WorldReflectionVector (IN, o.Normal);
			o.Emission = texCUBE(_ReflMap, worldRefl).rgb * _ReflecTivity;
		
		}
		ENDCG
        

	} 
	FallBack "Diffuse"
}
