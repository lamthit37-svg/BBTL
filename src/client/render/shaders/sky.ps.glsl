// Cùng công thức và bố cục với sky.ps.slang. Backend GL là thiết bị màu thô: ảnh và đích đều là số gamma
// nên không đổi gamma.
struct SkyDraw {
    mat4 mvp;
    vec4 world0;
    vec4 world1;
    vec4 world2;
    vec4 a;
    vec4 b;
    vec4 sun;
    vec4 light;
    vec4 rim;
    vec4 fog;
    vec4 control;
    vec4 ambient;
    vec4 misc;
};

layout(std140, binding = 0) uniform SkyBlock {
    SkyDraw draws[32];
} sky;

uniform highp uvec4 tl_push[1];

layout(binding = 0) uniform sampler2D sky_map0;
layout(binding = 1) uniform sampler2D sky_map1;
layout(binding = 2) uniform sampler2D sky_map2;

layout(location = 0) in vec2 varying_uv0;
layout(location = 1) in vec2 varying_uv1;
layout(location = 2) in vec3 varying_normal;

layout(location = 0) out vec4 out_color;

vec4 dome(SkyDraw draw) {
    vec4 ray = texture(sky_map1, varying_uv0);
    vec4 ray_ex = texture(sky_map2, varying_uv0);
    vec4 mie = texture(sky_map0, varying_uv1);
    float weight = draw.misc.y;
    vec3 colour = (ray.rgb * ray.a * weight) + (ray_ex.rgb * ray_ex.a * (1.0 - weight));
    colour = (mie.rgb * colour) + colour;
    colour = colour * (draw.ambient.xyz * draw.ambient.w);
    return vec4(colour, 1.0);
}

vec3 cloud_colour(SkyDraw draw, vec4 map) {
    vec4 fog_map = texture(sky_map1, varying_uv1);
    vec3 fog_amount = clamp(fog_map + vec4(draw.control.x), 0.0, 1.0).xyz;
    float light = clamp(dot(normalize(draw.sun.xyz), varying_normal), 0.0, 1.0);
    float blend = draw.control.z;
    vec3 diffuse = (map.rgb * draw.ambient.xyz * blend) + (map.rgb * (1.0 - blend));
    float scattering = pow(light, draw.light.w + 0.00001);
    float rim_detect = pow(1.0 - clamp(map.a - draw.rim.w, 0.0, 1.0), draw.rim.z + 0.00001);
    float rim_scattering = pow(light, draw.rim.y + 0.00001);
    float lit_rim = rim_detect * rim_scattering;
    vec3 colour = diffuse + (draw.light.xyz * scattering * draw.sun.w) + (draw.light.xyz * lit_rim * draw.rim.x);
    return mix(colour, draw.fog.xyz, fog_amount);
}

vec4 cloud(SkyDraw draw) {
    vec4 map = texture(sky_map0, varying_uv0);
    return vec4(cloud_colour(draw, map), map.a * draw.control.w);
}

vec4 ring(SkyDraw draw) {
    vec4 map = texture(sky_map0, varying_uv0);
    vec3 colour = cloud_colour(draw, map);
    float edge = (-2.0 * abs(varying_uv1.y - 0.5)) + 1.0;
    float fade = min(edge / (draw.control.y + 0.00001), 1.0);
    return vec4(colour, map.a * fade * draw.control.w);
}

vec4 body(SkyDraw draw) {
    vec4 map = texture(sky_map0, varying_uv0);
    return vec4(map.rgb, map.a);
}

void main() {
    SkyDraw draw = sky.draws[tl_push[0].x];
    uint kind = uint(draw.misc.x);
    if (kind == 0u) {
        out_color = dome(draw);
    } else if (kind == 1u) {
        out_color = cloud(draw);
    } else if (kind == 2u) {
        out_color = ring(draw);
    } else {
        out_color = body(draw);
    }
}
