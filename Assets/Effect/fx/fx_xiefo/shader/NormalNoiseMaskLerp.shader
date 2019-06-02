// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Simplified Additive Particle shader. Differences from regular Additive Particle one:
// - no Tint color
// - no Smooth particle support
// - no AlphaTest
// - no ColorMask

Shader "Saint/model/normal Noise lerp" {
Properties {
	_MainTex ("Texture", 2D) = "white" {}
		_noiseTex ("Noise Texture", 2D) = "white" {}
    _color("texColor", Color)=(1,1,1,1)

     _lineColor("LineColor", Color)=(1,1,1,1)
    _lineSize("LineSize", Range(0,0.5))=0
    _mask("Mask", Range(-0.2,1.2))=0 
          
}

Category {
	Tags { "Queue"="Geometry+1" "IgnoreProjector"="True" "RenderType"="Geometry" }
	
	 Lighting Off



	BindChannels {
		Bind "Color", color
		Bind "Vertex", vertex
		Bind "TexCoord", texcoord
	}
	
	SubShader {
        
  Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _noiseTex;   
            float4 _MainTex_ST;
           
            struct v2f {
                float4  pos : SV_POSITION;
                float2  uv : TEXCOORD0;
            };
           
           
           struct appdata {
    float4 vertex : POSITION;
    float2 texcoord:TEXCOORD0;
};

            //顶点函数没什么特别的，和常规一样
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }
 
		 float4 _color;
		  float _mask;
		  float _lineSize;	
		  float4 _lineColor;
		  
            float4 frag (v2f i) : COLOR
            {
                    float4 noiseCol= tex2D(_noiseTex,i.uv);
                    float clipValue = max(noiseCol.r-_mask, -0.00001);
                    clip(clipValue);
                    clipValue = max((_lineSize - clipValue), 0.0) / _lineSize;
                float4 col= tex2D(_MainTex,i.uv)* _color + clipValue*_lineColor;
              col.a = 1.0;
                return col;
             
            }
            ENDCG
        }
	}
}


FallBack "Diffuse"
}