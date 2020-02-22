// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "custom/ShockWave" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.01, 1)) = 0.078125
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_EmissionLM ("Emission (Lightmapper)", Float) = 0
		_AnimFreqX ("Animation Freq X", Float) = 1.0
		_AnimFreqZ ("Animation Freq Z", Float) = 1.0
		_AnimPowerX ("Animation Power X", Float) = 0.0
		_AnimPowerY ("Animation Power Y", Float) = 0.1
		_AnimPowerZ ("Animation Power Z", Float) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 400
		CGPROGRAM
		#pragma surface surf BlinnPhong vertex:vert

		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _Illum;
		fixed4 _Color;
		half _Shininess;
		half _SelfIllum;
		half _PowerOffset;
		// animation 
		half _Speed;
		half _AnimFreq;
		half _AnimFreqX;
		half _AnimFreqZ;
		half _AnimPowerX;
		half _AnimPowerY;
		half _AnimPowerZ;
		half _Radius;
		

		struct Input {
			float2 uv_MainTex;
			float illumReflection;
			fixed4 vColor;
		};

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			half4 worldPos = mul(unity_ObjectToWorld, v.vertex);
		
			// diff between shockwave radial position and vertex position
			half pi = 3.14159;
			half angX = 2*pi*_AnimFreqX*_Time.x;
			half angZ = 2*pi*_AnimFreqZ*_Time.x;
//			half x = 2*pi*_AnimFreq*_Time.x;
			half phaseX = worldPos.x;
			half phaseZ = worldPos.z;
//			half phase = worldPos.x;
			half offY = _AnimPowerX*sin(angX + phaseX) + _AnimPowerZ*sin(angZ + phaseZ);
			//animation
//			half3 animPower = half3(_AnimPowerX, _AnimPowerY, _AnimPowerZ);
			half3 offset = v.normal.xyz * offY;
			v.vertex.xyz += offset;
		}

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
			fixed4 c = tex;
			o.Albedo = c.rgb;
			fixed3 illumReflection = fixed3(IN.illumReflection,IN.illumReflection,IN.illumReflection);
			o.Gloss = tex.a;
			o.Alpha = c.a;
			o.Specular = _Shininess;
		}
		ENDCG
	}
	FallBack "Self-Illumin/Specular"
}
