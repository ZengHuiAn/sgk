// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Shader created with Shader Forge v1.26 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.26;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,lico:1,lgpr:1,limd:0,spmd:1,trmd:1,grmd:0,uamb:False,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,rpth:0,vtps:0,hqsc:True,nrmq:0,nrsp:0,vomd:1,spxs:False,tesm:0,olmd:1,culm:2,bsrc:0,bdst:7,dpts:2,wrdp:False,dith:0,rfrpo:True,rfrpn:Refraction,coma:15,ufog:False,aust:True,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:False,fgod:False,fgor:False,fgmd:0,fgcr:0.5,fgcg:0.5,fgcb:0.5,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:False,fnfb:False;n:type:ShaderForge.SFN_Final,id:0,x:35135,y:32442,varname:node_0,prsc:2|emission-8282-OUT,alpha-2453-OUT,refract-14-OUT;n:type:ShaderForge.SFN_Multiply,id:14,x:34895,y:32726,varname:node_14,prsc:2|A-16-OUT,B-6401-A,C-4651-OUT;n:type:ShaderForge.SFN_ComponentMask,id:16,x:34702,y:32651,varname:node_16,prsc:2,cc1:0,cc2:1,cc3:-1,cc4:-1|IN-25-RGB;n:type:ShaderForge.SFN_Tex2d,id:25,x:34459,y:32582,ptovrint:False,ptlb:Refraction,ptin:_Refraction,varname:_Refraction,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,tex:f5eb8786579c3454fbcedbbd3ec2f86b,ntxv:0,isnm:False;n:type:ShaderForge.SFN_Vector1,id:478,x:34885,y:32634,varname:node_478,prsc:2,v1:0;n:type:ShaderForge.SFN_VertexColor,id:6401,x:34458,y:32829,varname:node_6401,prsc:2;n:type:ShaderForge.SFN_Slider,id:4651,x:34397,y:33053,ptovrint:True,ptlb:Refraction Intensity,ptin:_RefractionIntensity,varname:_RefractionIntensity,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:1,max:1;n:type:ShaderForge.SFN_Clamp,id:5272,x:32650,y:33603,varname:node_5272,prsc:2|MIN-8142-OUT,MAX-4797-OUT;n:type:ShaderForge.SFN_ValueProperty,id:4797,x:32213,y:33674,ptovrint:False,ptlb:node_7492_copy,ptin:_node_7492_copy,varname:_node_7492_copy,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:1;n:type:ShaderForge.SFN_ValueProperty,id:8142,x:32213,y:33590,ptovrint:False,ptlb:node_547_copy,ptin:_node_547_copy,varname:_node_547_copy,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:0;n:type:ShaderForge.SFN_Multiply,id:2453,x:34925,y:32860,varname:node_2453,prsc:2|A-25-RGB,B-6401-A;n:type:ShaderForge.SFN_Multiply,id:8282,x:34699,y:32449,varname:node_8282,prsc:2|A-25-RGB,B-6401-RGB;proporder:25-4651;pass:END;sub:END;*/

Shader "Rhino/A3_SimpleDistortion" {
    Properties {
        _Refraction ("Refraction", 2D) = "white" {}
        _RefractionIntensity ("Refraction Intensity", Range(0, 1)) = 1
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        LOD 200
        GrabPass{ }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend One OneMinusSrcAlpha
            Cull Off
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            #pragma exclude_renderers xbox360 ps3 
            #pragma target 3.0
            uniform sampler2D _GrabTexture;
            uniform sampler2D _Refraction; uniform float4 _Refraction_ST;
            uniform float _RefractionIntensity;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float4 vertexColor : COLOR;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.pos = UnityObjectToClipPos(v.vertex );
                o.screenPos = o.pos;
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                #if UNITY_UV_STARTS_AT_TOP
                    float grabSign = -_ProjectionParams.x;
                #else
                    float grabSign = _ProjectionParams.x;
                #endif
                i.screenPos = float4( i.screenPos.xy / i.screenPos.w, 0, 0 );
                i.screenPos.y *= _ProjectionParams.x;
                float4 _Refraction_var = tex2D(_Refraction,TRANSFORM_TEX(i.uv0, _Refraction));
                float2 sceneUVs = float2(1,grabSign)*i.screenPos.xy*0.5+0.5 + (_Refraction_var.rgb.rg*i.vertexColor.a*_RefractionIntensity);
                float4 sceneColor = tex2D(_GrabTexture, sceneUVs);
////// Lighting:
////// Emissive:
                float3 emissive = (_Refraction_var.rgb*i.vertexColor.rgb);
                float3 finalColor = emissive;
                return fixed4(lerp(sceneColor.rgb, finalColor,(_Refraction_var.rgb*i.vertexColor.a)),1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
    CustomEditor "ShaderForgeMaterialInspector"
}
