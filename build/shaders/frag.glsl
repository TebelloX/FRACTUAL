#version 400 compatibility
#extension GL_ARB_gpu_shader_fp64 : enable
#pragma optionNV(fastmath off)
#pragma optionNV(fastprecision off)

uniform vec2 iResolution;
uniform float iTime;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

const float power = 10.0;

vec2 DE(in vec3 p) {
  // p = p + 1. * vec3(0, -0.5*iTime, iTime);
  // float d1 = distance(mod(p, 2.), vec3(1,1,1))-.54321;

  // return d1;

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

  // vec3 offset = p;
  // float dr = 1.0;
  // for (int n = 0; n < 500; n++) {
  //   Fold(p, dr);
  //   p = 0.01 * p + offset;
  //   dr = dr * abs(0.01) + 1.0;
  // }

  // float r = length(p);
  // return r / abs(dr);
}

vec2 sceneDE(in vec3 p)
{
  return DE(p);
}

vec3 calculate_normal(in vec3 p)
{
    return normalize(vec3(
      sceneDE(vec3(p.x + EPSILON, p.y, p.z)).y - sceneDE(vec3(p.x - EPSILON, p.y, p.z)).y,
      sceneDE(vec3(p.x, p.y + EPSILON, p.z)).y - sceneDE(vec3(p.x, p.y - EPSILON, p.z)).y,
      sceneDE(vec3(p.x, p.y, p.z  + EPSILON)).y - sceneDE(vec3(p.x, p.y, p.z - EPSILON)).y
    ));
}

vec3 raymarch(in vec3 ro, in vec3 rd, in vec2 uv) {
    float total_distance_traveled = 0.0;
    const int NUMBER_OF_STEPS = 32;
    const float MINIMUM_HIT_DISTANCE = 0.001;
    const float MAXIMUM_TRACE_DISTANCE = 1000.0;

    vec4 result = mix(vec4(51, 3, 20, 1), vec4(16, 6, 28, 1), uv.y) / 255.0;

    for (int i = 0; i < NUMBER_OF_STEPS; ++i)
    {
        vec3 current_position = ro + total_distance_traveled * rd;

        float distance_to_closest = sceneDE(current_position).y;

        vec2 sceneInfo = DE(ro);
        float dst = sceneInfo.y;

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {
            // vec3 normal = calculate_normal(current_position);
            vec3 light_position = vec3(2.0, -5.0, 3.0);
            // vec3 direction_to_light = normalize(current_position - light_position);

            // float diffuse_intensity = max(0.0, dot(normal, direction_to_light));

            // return vec3(0.8, 0.0, 0.8) * diffuse_intensity;

            float escapeIterations = sceneInfo.x;
            vec3 normal = calculate_normal(ro - rd * EPSILON * 2);
            float colorA = clamp(dot(normal * 0.5 + 0.5, -light_position), 0.0, 1.0);
            float colorB = clamp(escapeIterations/16.0, 0.0, 1.0);
            float colorMix = clamp(colorA + colorB, 0.0, 1.0);
            // result = vec3(colorMix.xyz);
            return vec3(colorMix, colorMix, colorMix);
        }

        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {
            break;
        }
        total_distance_traveled += distance_to_closest;
    }
    return vec3(0);
}

void main()
{
    vec2 uv = (gl_FragCoord.xy - 0.5*iResolution.xy) / iResolution.y;
    // vec2 uv = gl_FragCoord.xy / iResolution.xy * 2 - 1;
    vec3 camPos = vec3(0, 2, 0);
    vec3 camViewDir = normalize(vec3(uv.xy, 1));

    vec3 shaded_color = raymarch(camPos, camViewDir, uv);

    // Output to screen
    gl_FragColor = vec4(shaded_color, 1.0);
}
