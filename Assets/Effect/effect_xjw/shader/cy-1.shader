// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Shader created with Shader Forge v1.27 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.27;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,lico:1,lgpr:1,limd:0,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,rpth:0,vtps:0,hqsc:True,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:2,bsrc:0,bdst:1,dpts:2,wrdp:True,dith:0,rfrpo:True,rfrpn:Refraction,coma:15,ufog:False,aust:True,igpj:False,qofs:0,qpre:2,rntp:3,fgom:False,fgoc:False,fgod:False,fgor:False,fgmd:0,fgcr:0.5,fgcg:0.5,fgcb:0.5,fgca:1,fgde:0.01,fgrn:0,fgrf:300,stcl:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:False,fnfb:False;n:type:ShaderForge.SFN_Final,id:9361,x:33940,y:32727,varname:node_9361,prsc:2|emission-5128-OUT,clip-3419-OUT;n:type:ShaderForge.SFN_Tex2d,id:2052,x:32520,y:32970,ptovrint:False,ptlb:node_2052,ptin:_node_2052,varname:_node_2052,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,tex:f781c1490a9c1a147be5d51c26cd6b93,ntxv:0,isnm:False|UVIN-1261-OUT;n:type:ShaderForge.SFN_Color,id:1635,x:32567,y:32382,ptovrint:False,ptlb:nei,ptin:_nei,varname:_nei,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:1,c2:0.6827586,c3:0,c4:1;n:type:ShaderForge.SFN_FaceSign,id:7580,x:32593,y:32745,varname:node_7580,prsc:2,fstp:0;n:type:ShaderForge.SFN_Lerp,id:6243,x:32948,y:32717,varname:node_6243,prsc:2|A-6438-OUT,B-2630-OUT,T-7580-VFACE;n:type:ShaderForge.SFN_Color,id:6942,x:32548,y:32149,ptovrint:False,ptlb:wai,ptin:_wai,varname:_wai,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:1,c2:0.2689655,c3:0,c4:1;n:type:ShaderForge.SFN_Append,id:3081,x:32152,y:33179,varname:node_3081,prsc:2|A-98-OUT,B-5677-OUT;n:type:ShaderForge.SFN_ValueProperty,id:98,x:31810,y:33160,ptovrint:False,ptlb:node_98,ptin:_node_98,varname:_node_98,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:0;n:type:ShaderForge.SFN_ValueProperty,id:5677,x:31810,y:33283,ptovrint:False,ptlb:node_5677,ptin:_node_5677,varname:_node_5677,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,v1:-1;n:type:ShaderForge.SFN_Multiply,id:832,x:32246,y:33056,varname:node_832,prsc:2|A-2752-T,B-3081-OUT;n:type:ShaderForge.SFN_Time,id:2752,x:31780,y:32967,varname:node_2752,prsc:2;n:type:ShaderForge.SFN_Add,id:1261,x:32292,y:32883,varname:node_1261,prsc:2|A-5853-UVOUT,B-2178-OUT,C-832-OUT;n:type:ShaderForge.SFN_TexCoord,id:5853,x:31793,y:32814,varname:node_5853,prsc:2,uv:0;n:type:ShaderForge.SFN_TexCoord,id:4139,x:32481,y:33233,varname:node_4139,prsc:2,uv:0;n:type:ShaderForge.SFN_RemapRange,id:7553,x:32657,y:33244,varname:node_7553,prsc:2,frmn:0,frmx:1,tomn:-1,tomx:1|IN-4139-V;n:type:ShaderForge.SFN_OneMinus,id:5977,x:32948,y:33176,varname:node_5977,prsc:2|IN-7553-OUT;n:type:ShaderForge.SFN_Subtract,id:8837,x:33148,y:33268,varname:node_8837,prsc:2|A-5977-OUT,B-1096-OUT;n:type:ShaderForge.SFN_Multiply,id:3419,x:33445,y:33143,varname:node_3419,prsc:2|A-2052-A,B-8837-OUT;n:type:ShaderForge.SFN_Vector2,id:9979,x:31766,y:32700,varname:node_9979,prsc:2,v1:1,v2:1;n:type:ShaderForge.SFN_Add,id:2178,x:32111,y:32735,varname:node_2178,prsc:2|A-9979-OUT,B-5853-UVOUT;n:type:ShaderForge.SFN_Slider,id:1096,x:32813,y:33393,ptovrint:False,ptlb:node_1096,ptin:_node_1096,varname:_node_1096,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0.2483281,max:1;n:type:ShaderForge.SFN_If,id:2999,x:33308,y:32935,varname:node_2999,prsc:2|A-3419-OUT,B-465-OUT,GT-1549-OUT,EQ-1549-OUT,LT-396-OUT;n:type:ShaderForge.SFN_Slider,id:465,x:32914,y:32918,ptovrint:False,ptlb:node_465,ptin:_node_465,varname:_node_465,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0.5576756,max:1;n:type:ShaderForge.SFN_Vector1,id:1549,x:33144,y:32982,varname:node_1549,prsc:2,v1:0;n:type:ShaderForge.SFN_Vector1,id:396,x:33533,y:33299,varname:node_396,prsc:2,v1:1;n:type:ShaderForge.SFN_Add,id:5128,x:33250,y:32650,varname:node_5128,prsc:2|A-6243-OUT,B-6094-OUT;n:type:ShaderForge.SFN_Multiply,id:6094,x:33614,y:32850,varname:node_6094,prsc:2|A-4196-RGB,B-9714-OUT,C-2999-OUT;n:type:ShaderForge.SFN_Multiply,id:6438,x:32783,y:32132,varname:node_6438,prsc:2|A-6942-RGB,B-8689-OUT;n:type:ShaderForge.SFN_Vector1,id:8689,x:32745,y:32292,varname:node_8689,prsc:2,v1:2;n:type:ShaderForge.SFN_Multiply,id:2630,x:32783,y:32486,varname:node_2630,prsc:2|A-1635-RGB,B-5846-OUT;n:type:ShaderForge.SFN_Vector1,id:5846,x:32567,y:32603,varname:node_5846,prsc:2,v1:2;n:type:ShaderForge.SFN_Color,id:4196,x:33433,y:32566,ptovrint:False,ptlb:node_4196,ptin:_node_4196,varname:_node_4196,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.2413793,c2:0,c3:1,c4:1;n:type:ShaderForge.SFN_Vector1,id:9714,x:33519,y:33016,varname:node_9714,prsc:2,v1:2;proporder:6942-1635-2052-98-5677-1096-465-4196;pass:END;sub:END;*/

Shader "Shader Forge/cy-1" {
    Properties {
        _wai ("wai", Color) = (1,0.2689655,0,1)
        _nei ("nei", Color) = (1,0.6827586,0,1)
        _node_2052 ("node_2052", 2D) = "white" {}
        _node_98 ("node_98", Float ) = 0
        _node_5677 ("node_5677", Float ) = -1
        _node_1096 ("node_1096", Range(0, 1)) = 0.2483281
        _node_465 ("node_465", Range(0, 1)) = 0.5576756
        _node_4196 ("node_4196", Color) = (0.2413793,0,1,1)
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
    SubShader {
        Tags {
            "Queue"="AlphaTest"
            "RenderType"="TransparentCutout"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Cull Off
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma exclude_renderers gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2 
            #pragma target 3.0
            uniform float4 _TimeEditor;
            uniform sampler2D _node_2052; uniform float4 _node_2052_ST;
            uniform float4 _nei;
            uniform float4 _wai;
            uniform float _node_98;
            uniform float _node_5677;
            uniform float _node_1096;
            uniform float _node_465;
            uniform float4 _node_4196;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.pos = UnityObjectToClipPos(v.vertex );
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                float4 node_2752 = _Time + _TimeEditor;
                float2 node_1261 = (i.uv0+(float2(1,1)+i.uv0)+(node_2752.g*float2(_node_98,_node_5677)));
                float4 _node_2052_var = tex2D(_node_2052,TRANSFORM_TEX(node_1261, _node_2052));
                float node_3419 = (_node_2052_var.a*((1.0 - (i.uv0.g*2.0+-1.0))-_node_1096));
                clip(node_3419 - 0.5);
////// Lighting:
////// Emissive:
                float node_2999_if_leA = step(node_3419,_node_465);
                float node_2999_if_leB = step(_node_465,node_3419);
                float node_1549 = 0.0;
                float3 emissive = (lerp((_wai.rgb*2.0),(_nei.rgb*2.0),isFrontFace)+(_node_4196.rgb*2.0*lerp((node_2999_if_leA*1.0)+(node_2999_if_leB*node_1549),node_1549,node_2999_if_leA*node_2999_if_leB)));
                float3 finalColor = emissive;
                return fixed4(finalColor,1);
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
            #pragma exclude_renderers gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2 
            #pragma target 3.0
            uniform float4 _TimeEditor;
            uniform sampler2D _node_2052; uniform float4 _node_2052_ST;
            uniform float _node_98;
            uniform float _node_5677;
            uniform float _node_1096;
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
                float4 node_2752 = _Time + _TimeEditor;
                float2 node_1261 = (i.uv0+(float2(1,1)+i.uv0)+(node_2752.g*float2(_node_98,_node_5677)));
                float4 _node_2052_var = tex2D(_node_2052,TRANSFORM_TEX(node_1261, _node_2052));
                float node_3419 = (_node_2052_var.a*((1.0 - (i.uv0.g*2.0+-1.0))-_node_1096));
                clip(node_3419 - 0.5);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
    CustomEditor "ShaderForgeMaterialInspector"
}
