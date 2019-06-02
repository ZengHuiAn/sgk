// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Shader created with Shader Forge v1.30 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.30;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,lico:1,lgpr:1,limd:1,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:2,bsrc:3,bdst:7,dpts:2,wrdp:True,dith:0,rfrpo:True,rfrpn:Refraction,coma:15,ufog:True,aust:False,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:False,fgod:False,fgor:False,fgmd:0,fgcr:0.5,fgcg:0.5,fgcb:0.5,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:False,fnfb:False;n:type:ShaderForge.SFN_Final,id:4013,x:33803,y:32511,varname:node_4013,prsc:2|emission-9764-OUT,clip-7954-OUT,olwid-8711-OUT,olcol-8166-RGB;n:type:ShaderForge.SFN_Color,id:1304,x:33064,y:32314,ptovrint:False,ptlb:Color,ptin:_Color,varname:node_1304,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:1,c2:1,c3:1,c4:1;n:type:ShaderForge.SFN_Color,id:169,x:32981,y:32508,ptovrint:False,ptlb:Color_copy,ptin:_Color_copy,varname:_Color_copy,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:1,c2:0.9576065,c3:0.7205882,c4:0.853;n:type:ShaderForge.SFN_Tex2d,id:5740,x:32474,y:32191,ptovrint:False,ptlb:node_7404,ptin:_node_7404,varname:node_7404,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,tex:3d580c895c5f44e4c861a57187fae132,ntxv:2,isnm:False;n:type:ShaderForge.SFN_Panner,id:1506,x:32629,y:32419,varname:node_1506,prsc:2,spu:0.05,spv:-0.03|UVIN-1118-UVOUT;n:type:ShaderForge.SFN_TexCoord,id:1118,x:32435,y:32419,varname:node_1118,prsc:2,uv:0;n:type:ShaderForge.SFN_Tex2d,id:7930,x:32811,y:32419,ptovrint:False,ptlb:MARK,ptin:_MARK,varname:node_7865,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,tex:b60a590f2f0b19647906be3e12d2d089,ntxv:0,isnm:False|UVIN-1506-UVOUT;n:type:ShaderForge.SFN_Multiply,id:3412,x:33564,y:32446,varname:node_3412,prsc:2|A-5069-OUT,B-2171-OUT;n:type:ShaderForge.SFN_Step,id:7954,x:33556,y:32749,varname:node_7954,prsc:2|A-3638-OUT,B-9781-OUT;n:type:ShaderForge.SFN_Multiply,id:394,x:32945,y:32760,varname:node_394,prsc:2|A-3843-R,B-5496-OUT;n:type:ShaderForge.SFN_Desaturate,id:3638,x:33137,y:32917,varname:node_3638,prsc:2|COL-3843-RGB;n:type:ShaderForge.SFN_Slider,id:9781,x:32429,y:32910,ptovrint:False,ptlb:xxxxxxxx,ptin:_xxxxxxxx,varname:node_8805,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:-1,cur:0.1183935,max:1.5;n:type:ShaderForge.SFN_Slider,id:4012,x:32824,y:32679,ptovrint:False,ptlb:node_2506,ptin:_node_2506,varname:node_2506,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:8.691275,max:12;n:type:ShaderForge.SFN_Multiply,id:2171,x:33330,y:32497,varname:node_2171,prsc:2|A-7930-RGB,B-169-RGB,C-4012-OUT;n:type:ShaderForge.SFN_Tex2d,id:3843,x:32698,y:33045,ptovrint:False,ptlb:node_2254,ptin:_node_2254,varname:node_2254,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,tex:6926213f3ed322c449c676da32ba4278,ntxv:2,isnm:False;n:type:ShaderForge.SFN_Lerp,id:6031,x:33421,y:32649,varname:node_6031,prsc:2|A-2171-OUT,B-5069-OUT,T-6802-OUT;n:type:ShaderForge.SFN_Step,id:6802,x:33211,y:32765,varname:node_6802,prsc:2|A-394-OUT,B-9781-OUT;n:type:ShaderForge.SFN_Lerp,id:9764,x:33624,y:32611,varname:node_9764,prsc:2|A-3412-OUT,B-6031-OUT,T-7954-OUT;n:type:ShaderForge.SFN_Slider,id:5496,x:32585,y:32780,ptovrint:False,ptlb:node_5496,ptin:_node_5496,varname:node_5496,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:1.152358,max:3;n:type:ShaderForge.SFN_Multiply,id:5069,x:33564,y:32289,varname:node_5069,prsc:2|A-9441-OUT,B-1304-RGB,C-8363-OUT;n:type:ShaderForge.SFN_Slider,id:8363,x:33190,y:32421,ptovrint:False,ptlb:node_8363,ptin:_node_8363,varname:node_8363,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:2.264613,max:3;n:type:ShaderForge.SFN_Desaturate,id:6265,x:33878,y:31820,varname:node_6265,prsc:2|COL-4873-OUT;n:type:ShaderForge.SFN_Slider,id:4218,x:32654,y:32266,ptovrint:False,ptlb:node_4218,ptin:_node_4218,varname:node_4218,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:256,max:256;n:type:ShaderForge.SFN_Posterize,id:9441,x:33387,y:32196,varname:node_9441,prsc:2|IN-5740-RGB,STPS-4218-OUT;n:type:ShaderForge.SFN_Multiply,id:4873,x:33723,y:31633,varname:node_4873,prsc:2;n:type:ShaderForge.SFN_Slider,id:409,x:33849,y:31952,ptovrint:False,ptlb:node_409,ptin:_node_409,varname:node_409,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:1,max:1;n:type:ShaderForge.SFN_Slider,id:6848,x:33231,y:33130,ptovrint:False,ptlb:node_6848,ptin:_node_6848,varname:node_6848,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0.9316385,max:2;n:type:ShaderForge.SFN_Tex2d,id:5955,x:32990,y:33044,ptovrint:False,ptlb:node_5955,ptin:_node_5955,varname:node_5955,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,tex:10a3c36cbb0c2a24fb1625357fb92b0d,ntxv:0,isnm:False;n:type:ShaderForge.SFN_Multiply,id:8711,x:33455,y:32872,varname:node_8711,prsc:2|A-5955-A,B-6848-OUT,C-8166-RGB;n:type:ShaderForge.SFN_Color,id:8166,x:33577,y:33103,ptovrint:False,ptlb:node_8166,ptin:_node_8166,varname:node_8166,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.6838235,c2:0.3469399,c3:0.3469399,c4:1;n:type:ShaderForge.SFN_Panner,id:8153,x:33522,y:31841,varname:node_8153,prsc:2,spu:12,spv:12|UVIN-3528-UVOUT;n:type:ShaderForge.SFN_TexCoord,id:3528,x:33452,y:31698,varname:node_3528,prsc:2,uv:0;proporder:1304-169-5740-7930-9781-4012-3843-5496-8363-4218-409-6848-5955-8166;pass:END;sub:END;*/

Shader "Shader Forge/rongjie_baofengxue_test02" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _Color_copy ("Color_copy", Color) = (1,0.9576065,0.7205882,0.853)
        _node_7404 ("node_7404", 2D) = "black" {}
        _MARK ("MARK", 2D) = "white" {}
        _xxxxxxxx ("xxxxxxxx", Range(-1, 1.5)) = 0.1183935
        _node_2506 ("node_2506", Range(0, 12)) = 8.691275
        _node_2254 ("node_2254", 2D) = "black" {}
        _node_5496 ("node_5496", Range(0, 3)) = 1.152358
        _node_8363 ("node_8363", Range(0, 3)) = 2.264613
        _node_4218 ("node_4218", Range(0, 256)) = 256
        _node_409 ("node_409", Range(0, 1)) = 1
        _node_6848 ("node_6848", Range(0, 2)) = 0.9316385
        _node_5955 ("node_5955", 2D) = "white" {}
        _node_8166 ("node_8166", Color) = (0.6838235,0.3469399,0.3469399,1)
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Pass {
            Name "Outline"
            Tags {
            }
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_fog
            #pragma exclude_renderers psp2 
            #pragma target 3.0
            #pragma glsl
            uniform float _xxxxxxxx;
            uniform sampler2D _node_2254; uniform float4 _node_2254_ST;
            uniform float _node_6848;
            uniform sampler2D _node_5955; uniform float4 _node_5955_ST;
            uniform float4 _node_8166;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                UNITY_FOG_COORDS(1)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                float4 _node_5955_var = tex2Dlod(_node_5955,float4(TRANSFORM_TEX(o.uv0, _node_5955),0.0,0));
                o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal*(_node_5955_var.a*_node_6848*_node_8166.rgb),1) );
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                float4 _node_2254_var = tex2D(_node_2254,TRANSFORM_TEX(i.uv0, _node_2254));
                float node_7954 = step(dot(_node_2254_var.rgb,float3(0.3,0.59,0.11)),_xxxxxxxx);
                clip(node_7954 - 0.5);
                return fixed4(_node_8166.rgb,0);
            }
            ENDCG
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma exclude_renderers psp2 
            #pragma target 3.0
            #pragma glsl
            uniform float4 _TimeEditor;
            uniform float4 _Color;
            uniform float4 _Color_copy;
            uniform sampler2D _node_7404; uniform float4 _node_7404_ST;
            uniform sampler2D _MARK; uniform float4 _MARK_ST;
            uniform float _xxxxxxxx;
            uniform float _node_2506;
            uniform sampler2D _node_2254; uniform float4 _node_2254_ST;
            uniform float _node_5496;
            uniform float _node_8363;
            uniform float _node_4218;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                UNITY_FOG_COORDS(1)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                float4 _node_2254_var = tex2D(_node_2254,TRANSFORM_TEX(i.uv0, _node_2254));
                float node_7954 = step(dot(_node_2254_var.rgb,float3(0.3,0.59,0.11)),_xxxxxxxx);
                clip(node_7954 - 0.5);
////// Lighting:
////// Emissive:
                float4 _node_7404_var = tex2D(_node_7404,TRANSFORM_TEX(i.uv0, _node_7404));
                float3 node_5069 = (floor(_node_7404_var.rgb * _node_4218) / (_node_4218 - 1)*_Color.rgb*_node_8363);
                float4 node_1622 = _Time + _TimeEditor;
                float2 node_1506 = (i.uv0+node_1622.g*float2(0.05,-0.03));
                float4 _MARK_var = tex2D(_MARK,TRANSFORM_TEX(node_1506, _MARK));
                float3 node_2171 = (_MARK_var.rgb*_Color_copy.rgb*_node_2506);
                float3 emissive = lerp((node_5069*node_2171),lerp(node_2171,node_5069,step((_node_2254_var.r*_node_5496),_xxxxxxxx)),node_7954);
                float3 finalColor = emissive;
                fixed4 finalRGBA = fixed4(finalColor,1);
                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return finalRGBA;
            }
            ENDCG
        }
        Pass {
            Name "ShadowCaster"
            Tags {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_SHADOWCASTER
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_fog
            #pragma exclude_renderers psp2 
            #pragma target 3.0
            #pragma glsl
            uniform float _xxxxxxxx;
            uniform sampler2D _node_2254; uniform float4 _node_2254_ST;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                V2F_SHADOW_CASTER;
                float2 uv0 : TEXCOORD1;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(v.vertex );
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                float4 _node_2254_var = tex2D(_node_2254,TRANSFORM_TEX(i.uv0, _node_2254));
                float node_7954 = step(dot(_node_2254_var.rgb,float3(0.3,0.59,0.11)),_xxxxxxxx);
                clip(node_7954 - 0.5);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
    CustomEditor "ShaderForgeMaterialInspector"
}
