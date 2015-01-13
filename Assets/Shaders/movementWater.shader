Shader "Custom/movementWater" {
	Properties {
		_Tess ("Tessellation", Range(1,32)) = 4
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_DispMap( "Displacement Map", 2D) = "gray" {}
		_BumpDepth ("Bump depth", Range(0, 1.0)) = 1.0
		_Displacement ("Displacement", Range(0.0, 1.0)) = 0.3
		_Shininess ("Shininess", Range(1, 100.0)) = 3.0
		_Steepness( "Steepness", Range(0.0, 1.0)) = 0.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Lambert

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
