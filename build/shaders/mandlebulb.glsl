#version 400 compatibility
#extension GL_ARB_gpu_shader_fp64 : enable
#pragma optionNV(fastmath off)
#pragma optionNV(fastprecision off)

uniform vec2 iResolution;
uniform float iTime;

const int MAX_MARCHING_STEPS = 250;
const float MAX_DIST = 200.0;
const float EPSILON = 0.001;

uniform float power;
uniform float darkness;
uniform float blackAndWhite;
uniform vec3 colorAMix;
uniform vec3 colorBMix;

const vec3 LightDirection = vec3(-0.3, -0.8, 0.6);

struct Ray {
  vec3 origin;
  vec3 direction;
};

Ray CreateRay(in vec3 origin, in vec3 direction) {
  Ray ray;
  ray.origin = origin;
  ray.direction = direction;
  return ray;
}

Ray CreateCameraRay(in vec2 uv) {
  mat4 CameraToWorld;
  CameraToWorld[0] = vec4(1.0, 0.0, 0.0, 0.0);
  CameraToWorld[1] = vec4(0.0, 1.0, 0.0, 0.0);
  CameraToWorld[2] = vec4(0.0, 0.0, -1.0, -2.0);
  CameraToWorld[3] = vec4(0.0, 0.0, 0.0, 1.0);

  mat4 CameraInverseProjection;
  CameraInverseProjection[0] = vec4(0.90016, 0.0, 0.0, 0.0);
  CameraInverseProjection[1] = vec4(0.0, 0.57735, 0.0, 0.0);
  CameraInverseProjection[2] = vec4(0.0, 0.0, 0.0, -1.0);
  CameraInverseProjection[3] = vec4(0.0, 0.0, -1.66617, 1.66717);

  vec3 origin = vec3(vec4(0,0,0,1) * CameraToWorld).xyz;
  vec3 direction = vec3(vec4(uv,0,1) * CameraInverseProjection).xyz;
  direction = vec3(vec4(direction, 0) * CameraToWorld).xyz;
  direction = normalize(direction);

  return CreateRay(origin, direction);
}

vec3 boxFold(in vec3 z, in vec3 r) {
  return clamp(z.xyz, -r, r) * 2.0 - z.xyz;
}

void sphereFold(inout vec3 z, inout float dz) {
  float fixedRadius2 = 0.6 + 4.0 * cos(20.0/8.0) + 4.0;
  float minRadius2 = 0.3;
  float r2 = dot(z,z);
  if (r2 < minRadius2) {
    float temp = (fixedRadius2/minRadius2);
    z *= temp;
    dz *= temp;
  } else if (r2 < fixedRadius2) {
    float temp = (fixedRadius2 / r2);
    z *= temp;
    dz *= temp;
  }
}

vec3 mengerFold(in vec3 z) {
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

vec2 DE(in vec3 p) {
  vec3 z = p;
  float dr = 1.0;
  float r = 0.0;
  int iterations = 0;

  for (int i = 0; i < 15; i++) {
    iterations = i;
    r = length(z);

    if (r > 2) {
      break;
    }

    float theta = acos(z.z/r);
    float phi = atan(z.y, z.x);
    dr = pow(r, power-1.0)*power*dr+1.0;

    float zr = pow(r, power);
    theta = theta * power;
    phi = phi * power;

    z = zr * vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
    z += p;
  }

  float dst = 0.5*log(r)*r/dr;
  return vec2(iterations, dst*1);
}

vec3 EstimateNormal(in vec3 p) {
  float x = DE(vec3(p.x + EPSILON, p.y, p.z)).y - DE(vec3(p.x - EPSILON, p.y, p.z)).y;
  float y = DE(vec3(p.x, p.y + EPSILON, p.z)).y - DE(vec3(p.x, p.y - EPSILON, p.z)).y;
  float z = DE(vec3(p.x, p.y, p.z + EPSILON)).y - DE(vec3(p.x, p.y, p.z - EPSILON)).y;

  return normalize(vec3(x,y,z));
}

void main()
{
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec4 result = mix(vec4(51,3,20,1), vec4(16,16,28,1), uv.y) / 255.0;

    Ray ray = CreateCameraRay(uv * 2 - 1);
    float rayDst = 0;
    int marchSteps = 0;

    while (rayDst < MAX_DIST && marchSteps < MAX_MARCHING_STEPS) {
      marchSteps++;
      vec2 sceneInfo = DE(ray.origin);
      float dst = sceneInfo.y;

      if (dst <= EPSILON) {
        float escapeIterations = sceneInfo.x;
        vec3 normal = EstimateNormal(ray.origin - ray.direction * EPSILON * 2);

        float colorA = clamp(dot(normal * 0.5 + 0.5,-LightDirection), 0.0, 1.0);
        float colorB = clamp(escapeIterations / 16.0, 0.0, 1.0);
        vec3 colorMix = clamp(colorA * colorAMix + colorB * colorBMix, 0.0, 1.0);

        result = vec4(colorMix.xyz, 1);
        break;
      }

      ray.origin += ray.direction * dst;
      rayDst += dst;
    }

    // Output to screen
    float rim = marchSteps / darkness;

    gl_FragColor = mix(result, vec4(1,1,1,1), vec4(blackAndWhite,blackAndWhite,blackAndWhite, blackAndWhite)) * rim;
}
