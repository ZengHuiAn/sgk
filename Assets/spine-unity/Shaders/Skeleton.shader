Shader "Spine/Skeleton" {
	Properties {
		_Cutoff ("Shadow alpha cutoff", Range(0,1)) = 0.1
		[NoScaleOffset] _MainTex ("Texture to blend", 2D) = "black" {}

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255
		_ColorMask("Color Mask", Float) = 15

		_Color("Tiny Color", Color) = (1, 1, 1, 1)
		_Exposure("Exposure", Range(-1,1)) = 0
	}
	// 2 texture stage GPUs
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		LOD 100

		Fog { Mode Off }
		Cull Off
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		Lighting Off

		ColorMask[_ColorMask]
		Stencil {
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#include "UnityCG.cginc"

			// uniforms
			float4 _MainTex_ST;

			// vertex shader input data
			struct appdata {
				float3 pos : POSITION;
				half4 color : COLOR;
				float3 uv0 : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			// vertex-to-fragment interpolators
			struct v2f {
				fixed4 color : COLOR0;
				float2 uv0 : TEXCOORD0;
				float4 pos : SV_POSITION;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			// vertex shader
			v2f vert (appdata IN) {
				v2f o;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				half4 color = IN.color;
				half3 viewDir = 0.0;
				o.color = saturate(color);
				// compute texture coordinates
				o.uv0 = IN.uv0.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				// transform position
				o.pos = UnityObjectToClipPos(IN.pos);
				return o;
			}

			// textures
			sampler2D _MainTex;
			uniform float4 _Color;
			uniform float _Exposure;

			// fragment shader
			fixed4 frag (v2f IN) : SV_Target {
				fixed4 col;
				fixed4 tex;
				float gray = clamp(_Exposure, -1, 0) + 1;

				// SetTexture #0
				tex = tex2D (_MainTex, IN.uv0.xy);
				col = tex * IN.color;

				col.rgb = col.rgb * gray + ( (1-gray) * dot(col.rgb, float3(0.3, 0.59, 0.11))) + clamp(_Exposure, 0, 1);
				// col.rgb = clamp(col.rgb, float3(0,0,0), float3(1,1,1));
				col *= _Color;

				return col;
			}
			ENDCG
 		}

	}
}
