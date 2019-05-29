Shader "Unlit/Transparent"
{
	Properties
	{
		_Color ("Color", Color) = (0.5,0.5,0.5,0.0)
		_Cutoff ("Shadow alpha cutoff", Range(0,1)) = 0.1
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
		LOD 100

		// ZWrite Off
		Blend One OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 _Color;
			uniform fixed _Cutoff;
			fixed4 frag (v2f i) : SV_Target
			{
				clip(_Color.a - _Cutoff);
				return _Color;
			}
			ENDCG
		}
	}
}
