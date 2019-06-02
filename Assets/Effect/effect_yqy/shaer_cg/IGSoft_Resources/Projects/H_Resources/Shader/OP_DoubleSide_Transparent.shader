// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "cgwell/DoubleSideTransparent" {
    Properties {
        _Emission1("Outside", Color) = (0, 0, 0, 0)
        _Emission2("Inside", Color) = (0, 0, 0, 0)
		_MainTex ("Main Texture", 2D) = "white" {  }
    }
    SubShader {
        Tags {
            "RenderType"="Transparent" "Queue"="Transparent-10"
        }
        Pass {
            
            Cull Front
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            uniform float4 _Emission2;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };
            VertexOutput vert (appdata_base v) {
                VertexOutput o = (VertexOutput)0;
                o.pos = UnityObjectToClipPos(v.vertex );
                o.uv0 = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                float4 color = tex2D(_MainTex, i.uv0);
                float3 emissive = _Emission2.rgb * color.rgb;
                return fixed4(emissive, color.a);
            }
            ENDCG
        }
        Pass {
            
            Cull Back
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            uniform float4 _Emission1;
			sampler2D _MainTex;
			float4 _MainTex_ST;

            struct VertexOutput {
                float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
            };
            VertexOutput vert (appdata_base v) {
                VertexOutput o = (VertexOutput)0;
                o.pos = UnityObjectToClipPos(v.vertex );
				o.uv0 = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
				float4 color = tex2D(_MainTex, i.uv0);
                float3 emissive = _Emission1.rgb * color.rgb;
                return fixed4(emissive, color.a);
            }
            ENDCG
        }


    }
    FallBack "Diffuse"
}
