#version 400 compatibility
#extension GL_ARB_gpu_shader_fp64 : enable
#pragma optionNV(fastmath off)
#pragma optionNV(fastprecision off)

#define MaxSteps 32.
#define MinDistance 0.0075
#define eps 0.0001

uniform vec2 iResolution;
uniform float iTime;

uniform float power;

// more ideas for different Mandelboxes:
// http://archive.bridgesmathart.org/2018/bridges2018-547.pdf
mat3 rotateX(float angle) {
	float c = cos(angle), s = sin(angle);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

mat3 rotateY(float angle) {
	float c = cos(angle), s = sin(angle);
    return mat3(c, 0, -s, 0, 1, 0, s, 0, c);
}

mat3 rotateZ(float angle) {
	float c = cos(angle), s = sin(angle);
    return mat3(c,-s,0,s,c,0,0,0,1);
}

float sdSphere(vec3 p, float r) {
	return length(p) - r;    
}

// from iq
float sdPlane(in vec3 p, in vec4 n)
{
  return dot(p,n.xyz) + n.w;
}

// from iq
float sdBox(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0));
}

// https://github.com/HackerPoet/MarbleMarcher/blob/master/assets/frag.glsl
vec3 boxFold(vec3 z, vec3 r) {
	return clamp(z.xyz, -r, r) * 2.0 - z.xyz;
}

// http://www.fractalforums.com/fragmentarium/fragmentarium-an-ide-for-exploring-3d-fractals-and-other-systems-on-the-gpu/15/
void sphereFold(inout vec3 z, inout float dz) {
  float fixedRadius2 = .6 + 4.* cos(20./8.) + 4.;
  float minRadius2 = 0.3;
	float r2 = dot(z,z);
	if (r2< minRadius2) {
		float temp = (fixedRadius2/minRadius2);
		z*= temp;
		dz*=temp;
	} 
    else if (r2<fixedRadius2) {
		float temp =(fixedRadius2/r2);
		z*=temp;
		dz*=temp;
	}
}

// https://github.com/HackerPoet/MarbleMarcher/blob/master/assets/frag.glsl
vec3 mengerFold(vec3 z) {
	float a = min(z.x - z.y, 0.0);

	z.x -= a;
	z.y += a;
	a = min(z.x - z.z, 0.0);
	z.x -= a;
	z.z += a;
	a = min(z.y - z.z, 0.0);
	z.y -= a;
	z.z += a;

  return z;
}

// http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox/
vec2 DE(vec3 z)
{
  float Iterations = 20.;
  float Scale = 3.6;
	vec3 offset = z;
	float dr = 1.0;
  float trap = 1e10;

	for (float n = 0.; n < Iterations; n++) {
    z = mengerFold(z);
    z = boxFold(z, vec3(2.));       // Reflect
    sphereFold(z, dr);    // Sphere Inversion
    z.xz = -z.zx;
		z = boxFold(z, vec3(1.));       // Reflect
        
		sphereFold(z, dr);    // Sphere Inversion
    z=Scale*z + offset;  // Scale & Translate
    dr = dr*abs(Scale)+1.0;
    trap = min(trap, length(z));
	}
	float r = length(z);
	return vec2(r/abs(dr), trap);
}

vec2 scene(vec3 p) {  
  vec2 box = DE(p);
	return box;
}

float shadowScene(vec3 p){
	return DE(p).x;
}

// from iq
vec3 calcNormal(vec3 p) {
  float h = 0.001;
  vec2 k = vec2(1,-1);
  vec3 n = normalize( k.xyy*scene( p + k.xyy*h ).x + 
                k.yyx*scene( p + k.yyx*h ).x + 
                k.yxy*scene( p + k.yxy*h ).x + 
                k.xxx*scene( p + k.xxx*h ).x );    
  return n;
}

// ro: ray origin, rd: ray direction
// returns t and the occlusion as a vec2
vec3 march(vec3 ro, vec3 rd) {
  float t = 0., i = 0.;

  for(i=0.; i < MaxSteps; i++) {
    vec3 p = ro + t * rd;
      vec2 hit = scene(p);
      float dt = hit.x;
      t += dt;
      if(dt < MinDistance) {
        return vec3(t-MinDistance, 1.-i/MaxSteps, hit.y);  
      }
  }

  return vec3(0.);
}

float marchShadow(vec3 ro, vec3 rd) {
  float t = 0., i = 0.;

  for(i=0.; i < MaxSteps; i++) {
    vec3 p = ro + t * rd;
      float dt = shadowScene(p);
      t += dt;
      if(dt < MinDistance) {
        return t-MinDistance;    
      }
  }

  return 0.;
}

// https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_shading_model
vec3 shadeBlinnPhong(vec3 p, vec3 viewDir, vec3 normal, vec3 lightPos, float lightPower, vec3 lightColor) {
  vec3 diffuseColor = vec3(0.5);
  vec3 specColor = vec3(1);
  float shininess = 16.;

  vec3 lightDir = lightPos - p;
  float dist = length(lightDir);
  dist = dist*dist;
  lightDir = normalize(lightDir);
  
  float lambertian = max(dot(lightDir, normal), 0.0);
  float specular = .0;
  
  if(lambertian > 0.) {
      viewDir = normalize(-viewDir);
      
      vec3 halfDir = normalize(viewDir + lightDir);
      float specAngle = max(dot(halfDir, normal), .0);
      specular = pow(specAngle, shininess);
  }
  
  vec3 color = /*ambientColor +*/
                diffuseColor * lambertian * lightColor * lightPower / dist +
            specColor * specular * lightColor * lightPower / dist;
  
  return color;
}

// p: point, sn: surface normal, rd: ray direction (view dir/ray from cam)
vec3 light(vec3 p, vec3 sn, vec3 rd) {
  vec3 top = shadeBlinnPhong(p, rd, sn, vec3(0,1,0), 25., vec3(.2,.2,.8));
  
  mat3 rot = rotateZ(iTime / 10.) * rotateY(iTime / 10.) * rotateX(iTime / 10.);
  
  vec3 L1 = shadeBlinnPhong(p, rd, sn, vec3(5,-5,5) * rot, 10., vec3(.4,.1,.1));
  vec3 L2 = shadeBlinnPhong(p, rd, sn, vec3(5,-5,-5) * rot, 10., vec3(.4,.1,.1));
  vec3 L3 = shadeBlinnPhong(p, rd, sn, vec3(-5,-5,5) * rot, 10., vec3(.4,.1,.1));
  vec3 L4 = shadeBlinnPhong(p, rd, sn, vec3(-5,-5,-5) * rot, 10., vec3(.4,.1,.1));
  

  mat3 rot2 = rotateX(0.2) * rotateZ(-3.1415/2. - 0.2) * rotateY(iTime/16.);
  vec3 camPos = (vec3(0,0,-3)- vec3(0,1,15)) * rot2 ;
  vec3 cam = shadeBlinnPhong(p, rd, sn, camPos, 13., vec3(.9));
  
  vec3 ambient = vec3(.25);
  return L1 + L2 + L3 + L4 + ambient + top + cam;
}

// https://iquilezles.org/www/articles/palettes/palettes.htm
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
  return a + b*cos(6.28318 * (c*t + d));
}

void main()
{
    vec2 uv = (2.*gl_FragCoord.xy-iResolution.xy)/iResolution.y;
    vec3 col = vec3(.0);
    vec3 ro = vec3(0,0,-3); // ray origin
    vec3 rd = normalize(vec3(uv.x, uv.y, 0) - ro); // ray direction
    
    mat3 rot = rotateX(0.2) * rotateZ(-3.1415/2. - 0.2) * rotateY(iTime/16.);
    
    ro -= vec3(0,1,15);
    ro *= rot;
    rd *= rot;
    
    vec3 hit = march(ro, rd); // returns t and the occlusion value 
    float t = hit.x;
    
    if(t > eps) {
      vec3 p = ro + t * rd;
    	vec3 n = calcNormal(p);
        
      col += light(p, n, rd);
      col *= hit.y;   // occlusion 
      
      col = mix(col, vec3(0), clamp(1.-10./t, 0., 1.));
    }
    else {
      col = vec3(0);
    }

    gl_FragColor = vec4(col,1.0);
}