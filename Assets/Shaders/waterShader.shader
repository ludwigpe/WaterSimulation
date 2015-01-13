Shader "Custom/WaterShader" {
	Properties {
		_Tess ("Tessellation", Range(1,32)) = 4
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Bump Map", 2D) = "bump" {}
		_BumpMap2 ("Bump Map 2", 2D) = "bump" {}
		_BumpDepth ("Bump depth", Range(0, 1.0)) = 1.0
		_DispTex ("Displacement Texture", 2D) = "gray" {}
		_Displacement ("Displacement", Range(0.0, 1.0)) = 0.3
		_SpecColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_Shininess ("Shininess", Range(0.1, 10.0)) = 3.0
	}
	SubShader {
		Pass{
			Tags {"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag


			// User defined variables
			uniform float _Tess;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			
			uniform sampler2D _BumpMap;
			uniform float4 _BumpMap_ST;
			uniform sampler2D _BumpMap2;
			uniform float4 _BumpMap2_ST;
			uniform float _BumpDepth;

			uniform sampler2D _DispTex;
			uniform float _Displacement;
			
			uniform float4 _Color;
			uniform float4 _SpecColor;
			uniform float _Shininess;

			// Unity Defined uniforms
			uniform float4 _LightColor0;


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

			VertexOutput vert(VertexInput vIn) 
			{
				VertexOutput vOut;
				float d = tex2Dlod(_DispTex, float4(vIn.texcoord.xy,0,0)).r * _Displacement;
				vIn.vertex.xyz += vIn.normal * d;
				vOut.pos = mul(UNITY_MATRIX_MVP, vIn.vertex);		// transform from local to screen space
				
				vOut.posWorld = mul(_Object2World, vIn.vertex);		// transform from local to world space
				vOut.normalDir = normalize( mul(float4(vIn.normal, 0.0), _Object2World).xyz );
				vOut.tangentWorld = normalize( mul( _Object2World, vIn.tangent).xyz);
				vOut.binormalWorld = normalize( cross(vOut.normalDir, vOut.tangentWorld) * vIn.tangent.w);
				vOut.tex = vIn.texcoord;


				return vOut;
			}

			float4 tessFixed()
            {
                return _Tess;
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

				// texture map
				float4 tex = tex2D( _MainTex, i.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw );
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
				// diffuse lighting
				float3 diffRefl = atten * _LightColor0.xyz * saturate( dot( nDir, lDir) );
				float3 specRefl = diffRefl * _SpecColor.xyz * pow( saturate( dot( reflect( -lDir, nDir), vDir) ), _Shininess);	

				float3 lightFinal = UNITY_LIGHTMODEL_AMBIENT.xyz + diffRefl + specRefl;

				return float4(tex.xyz * lightFinal * _Color.xyz, 1.0);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
