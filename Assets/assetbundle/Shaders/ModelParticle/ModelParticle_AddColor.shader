// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Saint/ModelParticle/Additive" {
Properties {
	_MainTex ("Particle Texture", 2D) = "white" {}
_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
}


	
	SubShader {
        //不写深度缓冲必须+1才能正常Ztest
   Tags { "Queue"="Transparent+1" "IgnoreProjector"="True" "RenderType"="AlphaTest" }
		Blend  SrcAlpha  One, One OneMinusSrcAlpha 
	Cull Off Lighting Off 
	ZWrite Off 
		//ZTest Less   

	 Fog { mode Off}
			       Pass
        {
        Name "ADD_PASS"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
       
            sampler2D _MainTex;
            float4 _MainTex_ST;
           
            struct v2f {
                float4  pos : SV_POSITION;
                float2  uv : TEXCOORD0;
                 float4 color : color;
            };
           
           
           struct appdata {
    float4 vertex : POSITION;
    float2 texcoord:TEXCOORD0;
    float4 color : color;
};

            //顶点函数没什么特别的，和常规一样
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.color=v.color;
                return o;
            }
            
             fixed4 _TintColor;
            float4 frag (v2f i) : COLOR
            {
                return tex2D(_MainTex,i.uv)* _TintColor*i.color;
            }
            ENDCG
        }
	}
	FallBack "Diffuse"
}