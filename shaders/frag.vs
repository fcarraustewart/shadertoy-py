#version 330 core
in vec2 uv;
uniform float iTime;
uniform vec2 iResolution;
uniform vec3 iMouse;
out vec4 frag_color;
float neLength(vec2 p, float l) {
    return pow(
        pow(abs(p.x), l) + pow(abs(p.y), l)
    	, 1.0/l);
}

float dSphere(vec3 p, float r) {
    return length(p) - r;
}

float dTorus(vec3 p, vec2 t) {
    vec2 d = vec2(length(p.xz) - t.x, p.y);
    return length(d) - t.y;
}

float dCircleTorus(vec3 p, vec2 t) {
    vec2 d = vec2(length(p.xz) - t.x, p.y);
    return neLength(d, 8.) - t.y;
}

float dBoxTorus(vec3 p, vec2 t) {
    vec2 d = vec2(neLength(p.xz, 8.) - t.x, p.y);
    return neLength(d, 8.) - t.y;
}

float dSegment(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba)/dot(ba, ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}


vec2 opU(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}

void rotate(inout vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);

    p = mat2(c, s, -s, c)*p;
}

vec2 map(vec3 p) {
	vec2 p1 = vec2(p.y + 2.4, 0.0);
    p.y -= .6;
	rotate(p.xz, iTime);
    p.x -= 2.5;
    rotate(p.xy, 0.3*cos(2.0*iTime));

    vec2 w = vec2(dSphere(p, .70 - 0.1*sin(10.0*p.x + 5.0*iTime)*sin(10.0*p.y)*sin(10.0*p.z + 5.0*iTime)), 1.0);
    float radius = .15 - 0.1*smoothstep(2.3, 2.4, p.y > 0. ? p.y : abs(p.y + .4));
    vec2 sp = vec2(dSegment(p, vec3(0, 2.4, 0), vec3(0, -3.0, 0), radius), 7.0);
    rotate(p.zy, 3.14/2.0);
    vec2 bt = vec2(dCircleTorus(p, vec2(1, .08)), 2.0);
    for(int i = 0; i < 4; i++) {
        rotate(p.xy, iTime + float(i));
        p = p/1.2;
        vec2 bts = vec2(dCircleTorus(p, vec2(1, 0.08))*1.2, 3.0 + float(i));
        bt = opU(bt, bts);
    }

    return opU(p1, opU(opU(w, sp), bt));
}

vec2 spheretrace(vec3 ro, vec3 rd, float tmin, float tmax) {
    float td = tmin;
    float mid = -1.0;

    for(int i = 0; i < 256; i++) {
        vec2 s = map(ro + rd*td);

        if(abs(s.x) < 0.001 || td > tmax) break;

        td += s.x*0.5;
        mid = s.y;
    }

    if(td > tmax) mid = -1.0;
    return vec2(td, mid);
}

vec3 normal(vec3 p) {
    vec2 h = vec2(0.01, 0.0);
    vec3 n = vec3(
        map(p + h.xyy).x - map(p - h.xyy).x,
        map(p + h.yxy).x - map(p - h.yxy).x,
        map(p + h.yyx).x - map(p - h.yyx).x
    );

    return normalize(n);
}

float shadow(vec3 p, vec3 l) {
    float res = 1.0;
    float td = 0.02;

    for(int i = 0; i < 256; i++) {
        float h = map(p + l*td).x;
        td += h*0.5;
        res = min(res, 32.0*h/td);
        if(abs(h) < 0.001 || td > 25.0) break;
    }

    return clamp(res, 0.0, 1.0);
}

vec3 lighting(vec3 p, vec3 lp, vec3 rd) {
    vec3 lig = normalize(lp);
    vec3 n = normal(p);
    vec3 ref = reflect(lig, n);

    float amb = clamp(0.7 + 0.3*abs(n.y), 0.0, 1.0);
    float dif = clamp(dot(n, lig), 0.0, 1.0);
    float spe = pow(clamp(dot(rd, ref), 0.0, 1.0), 52.0);

    dif *= shadow(p, lig);

    vec3 lin = vec3(0);

    lin += 0.4*amb*vec3(1);
    lin += dif*vec3(1, .97, .85);
    lin += spe*vec3(1, .97, .54);

    return lin;
}

vec3 material(float mid, vec3 p) {
    vec3 col = vec3(1.);

    if(mid == 0.0) {
        vec2 a = vec2(1)*smoothstep(-0.15, 0.15, mod(p.x, 2.))*smoothstep(-0.15, 0.15, mod(p.z, 2.));
        col = vec3(a, 1);
    }

    if(mid == 1.0) {
        col = vec3(.2, .8, .001);
    }

    if(mid >= 2.0 && mid < 7.0) {
        col = mix(
            vec3(1, .1, .1),
            vec3(.1, .1, 1),
            cos(mid + iTime));
    }

    if(mid == 7.0) col = vec3(.65);

    return col;
}

vec3 render(vec3 ro, vec3 rd, vec3 lp) {
    vec2 i = spheretrace(ro, rd, 0.0, 25.0);
    vec3 p = ro + rd*i.x;
    vec3 m = material(i.y, p);
    if(i.y == -1.0) return m;

    m *= lighting(p, lp, rd);

    return m;
}

mat3 camera(vec3 e, vec3 l) {
    vec3 rl = vec3(0, 1, 0);
    vec3 f = normalize(l - e);
    vec3 r = normalize(cross(rl, f));
    vec3 u = normalize(cross(f, r));

    return mat3(r, u, f);
}

void main(  )
{
    vec2 uv = -1.0+2.0*(uv.xy * 2000.0/iResolution.xy);
    uv.x *= iResolution.x/iResolution.y;

    float s = 0.;
    if(iMouse.z > 0.) {
        s = 0.01*iMouse.x;
    } else {
        s = 3.1;
    }

    vec3 ro = 5.0*vec3(cos(s), 0.8, -sin(s));
    vec3 rd = camera(ro, vec3(0))*normalize(vec3(uv, 2.0));

    vec3 lp = vec3(.75, .75, 0);

    vec3 rend = render(ro, rd, lp);
    rend = pow(rend, vec3(.4545));
    frag_color = vec4(rend, 1.0);
}