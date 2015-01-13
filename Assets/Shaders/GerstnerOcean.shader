Shader "Custom/GerstnerOcean" {
	Properties {
		_Tess ("Tessellation", Range(1,32)) = 4
		_Color ("Main Color", Color) = (1,1,1,1)
		_Shininess ("Shininess", Range (0.03, 1)) = 1
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Bump Map", 2D) = "bump" {}
		_BumpMap2 ("Bump Map 2", 2D) = "bump" {}
		_ReflMap("Reflection Map", Cube) = "cube" {}
		_T ("Repeat Time", Float) = 0.5
		_Steepness("Steepness", Range(0.01, 1.0)) = 0.5
		_ReflecTivity("Reflectivity", Range(0.0, 1.0)) = 1.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:vert tessellate:tessFixed 
		#pragma debug
		#define numWaves 7
		#define PI 3.14159265

		uniform sampler2D _MainTex;
		uniform sampler2D _BumpMap;
		uniform sampler2D _BumpMap2;
		uniform samplerCUBE _ReflMap;
		uniform half _Tess;
		uniform fixed4 _Color;
		uniform float4x4 _Waves;
		uniform half _T;
		uniform half _Steepness;
		uniform half _ReflecTivity;
		uniform half _Shininess;

		// THe struct describing a wave.
		struct Wave {
		  float freq;  // 2*PI / wavelength
		  float amp;   // amplitude
		  float phase; // speed * 2*PI / wavelength
		  float2 dir;
		};

		struct appdata {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 texcoord : TEXCOORD0;
			float4 tangent : TANGENT;
		};


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
		// return a uniform tesselation
		float4 tessFixed()
        {
            return _Tess;
        }

        // vertex Shader will displace the vertex by suming several gerstner waves.
        // the vertex is displaced in all directions and not only vertically.
		void vert(inout appdata vIn)
		{
			// Create some waves. We have to create a wave from: amplitude, frequency, direction and speed.
			// However one cant pick freely since this will result in the waves that bend over and into itself.
			// there are constraints to the value and basicly we can only pick amplitude and direction
			// we will later create the waves from a script on the CPU and then pass it to the shader.
			half w0 = 2*PI / _T;						// base frequency 
			half amp = 3.25;							// amplitude wave 1
			half wl = (2*PI*amp*numWaves)/(_Steepness);	// wavelength
			half s = 10;								// speed that does not do anything
			half k = 2*PI/wl;							// wavenumber. k*amp must be < 1 so that waves dont roll over into intself
			half freq = sqrt(9.81* k)/_T;				// dispersion relation
			half w1 = (freq/w0) * w0;					// frequency for wave 1 around base frequency

			half amp2 = 5.50;
			half wl2 = (2*PI*amp2*numWaves)/(_Steepness);
			half k2 = 2*PI/wl2;
			half freq2 = sqrt(9.81* k2);
			half w2 = (freq2/w0) * w0;

			half amp3 = 4.60;
			half wl3 = (2*PI*amp3*numWaves)/(_Steepness);
			half k3 = 2*PI/wl3;
			half freq3 = sqrt(9.81* k3);
			half w3 = (freq3/w0) * w0;

			half amp4 = 1.750;
			half wl4 = (2*PI*amp4*numWaves)/(_Steepness);
			half k4 = 2*PI/wl4;
			half freq4 = sqrt(9.81* k4);
			half w4 = (freq4/w0) * w0;

			half amp5 = 2.80;
			half wl5 = (2*PI*amp5*numWaves)/(_Steepness);
			half k5 = 2*PI/wl5;
			half freq5 = sqrt(9.81* k5);
			half w5 = (freq5/w0) * w0;

			// array of waves. The last 3 should not be used since they give choppy and weird behavior.
			Wave W[7] = {
			
				{w1, amp, s*k, float2(-1.8, 1.12)*k},
				{w2, amp2, s*k2, float2(2.30, -0.6)*k2},
				{w3, amp3, s*k3, float2(1.60, 1.2)*k3},
				{w4, amp4, s*k4, float2(-2.0, -0.2)*k4},
				{w5, amp5, s*k5, float2(1.32, -0.76)*k5},
				{0.5, 0.2, 1.0, float2(-0.30, 0.7)},
				{0.2, 0.3, 1.0, float2(-0.2, 0.5)}
			};
			// save the original point on the horizontal plane as x0
			float2 x0 = vIn.vertex.xz;
			float3 newPos = float3(0.0, 0.0, 0.0);
			float3 tangent = float3(0, 0, 0);
			float3 binormal = float3(0, 0, 0);

			// iterate and sum together all waves.
			for(int i = 0; i < numWaves; i++)
			{
				Wave w = W[i];
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

			// compute new normal
			vIn.normal = -cross(binormal, tangent);
			// save new tangent
			vIn.tangent = float4(tangent.xyz, 0.0);
		}

		struct Input {
			float3 worldPos;
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_BumpMap2;
			float3 worldRefl;
			INTERNAL_DATA
		};

		// compute final colors of surface
		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb * _Color.rgb;
			o.Alpha = c.a;
			o.Specular = _Shininess;
			o.Normal = normalize(UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap)) + UnpackNormal (tex2D (_BumpMap2, IN.uv_BumpMap2)));
			float3 worldRefl = WorldReflectionVector (IN, o.Normal);
			o.Emission = texCUBE(_ReflMap, worldRefl).rgb * _ReflecTivity;

		}
		ENDCG
	} 
	FallBack "Diffuse"
}
