//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec3 v_vNormal;

uniform vec3 u_LightForward;

void main()
{
	float illumination    = -dot(v_vNormal, u_LightForward);
    gl_FragColor = v_vColour * texture2D( gm_BaseTexture, v_vTexcoord );
	gl_FragColor.rgb *= illumination * .5 + .5;
}
