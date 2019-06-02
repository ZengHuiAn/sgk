// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/***********************************************************************************************************
 * 作者 : GF
 * 着色器 : (模拟虚拟点光源)虚拟点光 + 边缘光 + 线性雾
 * 注解 : 使用于角色或NPC 带Mask Alpha 通道 带溶解效果
 ************************************************************************************************************/
Shader "cyl/VirPointLightRim" {
	Properties {
		_TintColor ("Main Color", Color) = (.5,.5,.5,1)
		_GreyColor ("Grey If Alpha is 0", Color) = (.5,.5,.5,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}

		_PointLightMap ("点光模拟纹理", CUBE) = "" { Texgen CubeNormal }

		_RimColor ("Rim Color", Color) = (0.8,0.8,0.8,0.6)
		_RimMin ("Rim min", Range(0,1)) = 0.4
		_RimMax ("Rim max", Range(0,1)) = 0.6
		_White("White", Float) = .001

		//_OcclusionMask ("Base (RGB) Gloss (A)", 2D) = "white" {}
		_Tile("溶解贴图的平铺大小", Range (0, 1)) = 0.7 // 平铺值
		_Amount ("溶解值", Range (0, 1)) = 0 // 溶解度
		_DissSize("溶解大小", Range (0, 1)) = 0.2 // 溶解范围大小
		_DissColor ("溶解主色", Color) = (1,1,1,1) // 溶解颜色 
		_AddColor ("叠加色", Color) = (1,1,1,1) // 改色与溶解色融合形成开始色
		_GlowColorMult ("Glow Color Multiplier", Color) = (0.5, 0.5, 0.5, 1)
	}

	SubShader {
		//Tags { "RenderType"="Opaque" }
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}//Transparent Glow
		Blend SrcAlpha OneMinusSrcAlpha  
		ZWrite On
		LOD 800

		Pass {
			Name "BASE"
			Cull Back
			
			CGPROGRAM
// Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct appdata members fog)
		  //#pragma exclude_renderers d3d11 xbox360
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest 

			#include "UnityCG.cginc"

			samplerCUBE _PointLightMap;

			sampler2D _MainTex;

			float4 _TintColor;
			float4 _GreyColor;
			float4 _MainTex_ST;

			float4 _RimColor;
			float _RimMin;
			float _RimMax;
			float _White;

			//sampler2D _OcclusionMask;
			half _Tile;
			half _Amount;
			half _DissSize;
			half4 _DissColor;
			half4 _AddColor;

			static half3 finalColor = float3(1,1,1);

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				fixed4 color : COLOR;
			};
			
			struct v2f {
				float4 pos : POSITION;
				fixed4 color : COLOR;
				half2 uv[4] : TEXCOORD0;
			};

			v2f vert (appdata v)
			{
				v2f o;
				float4 vertex = v.vertex;
				
				o.pos = UnityObjectToClipPos (vertex);
				o.uv[0] = TRANSFORM_TEX(v.texcoord, _MainTex);

				// 计算点光
				half3 pointLight = mul (UNITY_MATRIX_MV, float4(v.normal,0));
				o.uv[1].xy = pointLight.xy;
				o.uv[2].x = pointLight.z;

				// 计算边缘光强度
				half3 rim = 1.0f - saturate( dot(normalize(ObjSpaceViewDir(v.vertex)), v.normal));
				o.uv[2].y = rim.z;
				o.uv[3].xy = rim.xy;

				o.color = v.color;

				return o;
			}

			float4 frag (v2f i) : COLOR
			{
				float4 c = _TintColor * tex2D(_MainTex, i.uv[0]) * 2;

				half3 pointLight;
				pointLight.xy = i.uv[1].xy;
				pointLight.z = i.uv[2].x;

				// 取样点光
				float4 light = texCUBE(_PointLightMap, pointLight);

				c.rgb = 3.0f * light.rgb * c.rgb;

				// 计算边缘光
				half3 rim;
				rim.xy = i.uv[3].xy;
				rim.z = i.uv[2].y;

				half3 white;
				white = half3(_White, _White, _White);

				rim = smoothstep(_RimMin, _RimMax, rim);

				//if(i.color.r <= 0.5 && i.color.g <= 0.5 && i.color.b <= 0.5)
				//{
				//	float grey = dot(c.rgb,float3(0.299,0.597,0.114));
				//	c.rgb = float3(grey,grey,grey);
				//}
				//else
				//{
					c.rgb = c + c * rim * 3 * _RimColor + white;
				//}


				c.a = _TintColor.a;

				float ClipTex = tex2D (_MainTex, i.uv[0]/_Tile).r;
				float ClipAmount = ClipTex - _Amount; 
				if(_Amount > 0) 
				{ 
					if(ClipAmount <=0) 
					{ 
						clip(-0.1);
					}
					else 
					{
						if(ClipAmount < _DissSize) 
						{ 
							if(_AddColor.x == 0) 
							finalColor.x = _DissColor.x; 
							else 
							finalColor.x = ClipAmount/_DissSize; 
			
							if (_AddColor.y == 0) 
							finalColor.y = _DissColor.y; 
							else 
							finalColor.y = ClipAmount/_DissSize; 
			
							if (_AddColor.z == 0) 
							finalColor.z = _DissColor.z; 
							else 
							finalColor.z = ClipAmount/_DissSize;

							c.rgb = c.rgb * finalColor * 2;
						}
					}
				}

				if(_GreyColor.a == 0)
				{
					float grey = dot(c.rgb,float3(0.299,0.597,0.114));
					c.rgb = float3(grey,grey,grey);
				}
				

				//if(i.color.r <= 0.5 && i.color.g <= 0.5 && i.color.b <= 0.5)
				//{
				//	float grey = dot(c.rgb,float3(0.299,0.597,0.114));//0.299,0.597,0.114 0.1,0.5,0.4
				//	c.rgb = float3(grey,grey,grey);
				//}

				return  c;
			}
			ENDCG			
		}
	}

	SubShader
	{
		LOD 700

		Material
		{
			Emission(0.7,0.7,0.7,1)
		}

		Lighting On

		Pass
		{
			Name "LOW"
			Cull Off
			SetTexture[_MainTex]
			{
				Combine Texture * Primary DOUBLE
			}
		}
	}
	
	Fallback "VertexLit"
}
