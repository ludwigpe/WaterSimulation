Shader "Custom/basic_scrolling_textures"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _NormalMap_1 ("Texture", 2D) = "white" {}
		_NormalMap_2 ("Texture", 2D) = "white" {}       
		_WaterSpeed ("Water Speed", Range(0, 5)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
		
        struct Input
        {
			float2 uv_MainTex;
            float2 uv_NormalMap_1;
			float2 uv_NormalMap_2;
			float3 viewDir;
        };

       
        fixed4 _Color;
		sampler2D _NormalMap_1;
		sampler2D _NormalMap_2;
		float _WaterSpeed;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			// Update the sample offset to create scrolling normal maps (Animating the water)
			fixed offset = _WaterSpeed * _Time;

			// sample normal data from the scrolled values
			// Offset Normal map 1 in the x-direction
			fixed2 uvScrollNormal1 = IN.uv_NormalMap_1 + fixed2(offset, 0);
			// Offset the normal map 2 in the z-direction
			fixed2 uvScrollNormal2 = IN.uv_NormalMap_2 + fixed2(0, offset);
			
			// Add the 2 normals form the different normal maps the normalize the final direction
			o.Normal = normalize(UnpackNormal(tex2D(_NormalMap_1, uvScrollNormal1)) + UnpackNormal(tex2D(_NormalMap_2, uvScrollNormal2)));
            
			// Add the color of the water chosen
            o.Albedo = _Color;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
