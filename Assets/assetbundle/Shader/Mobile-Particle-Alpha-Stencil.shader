// Simplified Alpha Blended Particle shader. Differences from regular Alpha Blended Particle one:
// - no Tint color
// - no Smooth particle support
// - no AlphaTest
// - no ColorMask

Shader "Mobile/Particles/Alpha Blended Stencil" {
Properties {
	_MainTex ("Particle Texture", 2D) = "white" {}

	[HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
	[HideInInspector] _Stencil("Stencil ID", Float) = 0
	[HideInInspector] _StencilOp("Stencil Operation", Float) = 0
	[HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
	[HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255
	[HideInInspector] _ColorMask("Color Mask", Float) = 15
}

Category {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
	Blend SrcAlpha OneMinusSrcAlpha
	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
	
	BindChannels {
		Bind "Color", color
		Bind "Vertex", vertex
		Bind "TexCoord", texcoord
	}
	
	SubShader {
		ColorMask[_ColorMask]
			Stencil{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Pass {
			SetTexture [_MainTex] {
				combine texture * primary
			}
		}
	}
}
}
