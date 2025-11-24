uniform float uTime;

uniform vec3 uColorBg;
uniform vec3 uColorMid;
uniform vec3 uColorTop;
// uniform vec3 uColorLight;
uniform float uTreshold1;
uniform float uTreshold2;

uniform float uDistortionStrength;
uniform vec2 uSpeed;
uniform float uRotationSpeed;

uniform float uLacunarity;
uniform vec2 uIntensity;
uniform float uShadowIntensity;

varying vec2 vUv;

// Source: Ashima Arts / Stefan Gustavson
vec3 permute(vec3 x) {
    return mod(((x * 34.0) + 1.0) * x, 289.0);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod(i, 289.0);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// Fractal Brownian Motion
// NUM_OCTAVES définit combien de couches de détails on veut.
// 4 est un bon compromis qualité/performance.
#define NUM_OCTAVES 3

float fbm(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
	// Rotation matrix to improve quality
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));

    // On boucle 4 fois
    for(int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * snoise(x); // On ajoute le bruit
        x = rot * x * uLacunarity + shift; // On zoome (x2) et on tourne un peu
        a *= 0.5; // On réduit l'intensité (x0.5) pour la prochaine couche
    }
    return v;
}

mat2 rotate2d(float angle) {
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

void main() {
    vec2 center = vec2(0.5);
    vec2 centeredUv = vUv - center;

    vec2 rotatedUv = rotate2d(uTime * uRotationSpeed) * centeredUv;
    rotatedUv += center;

    // Premiere deformation
    vec2 q = vec2(0.0);
    q.x = fbm(rotatedUv + uTime * uSpeed.x);
    q.y = fbm(rotatedUv + vec2(5.2, 1.3) + uTime * uSpeed.y); // Petit décalage pour éviter un effet diagonal

    // Seconde deformation
    vec2 r = vec2(2.0);
    r.x = fbm(rotatedUv + q * uIntensity.x + vec2(1.7, 9.2) + uTime * uSpeed.x);
    r.y = fbm(rotatedUv + q * uIntensity.x + vec2(8.3, 2.8) + uTime * uSpeed.y);

    // Troisième deformation
    vec2 s = vec2(0.0);
    s.x = fbm(rotatedUv + r * uIntensity.y + vec2(10.2, 4.5)+ uTime * uSpeed.x);
    s.y = fbm(rotatedUv + r * uIntensity.y + vec2(7.5, 5.7)+ uTime * uSpeed.y);

    // On rend le resultat entre 0 et 1
    float noiseValue = fbm(rotatedUv + s * uDistortionStrength) * 0.5 + 0.5;

    // Couleur 
    vec3 col = mix(uColorBg, uColorMid, step(uTreshold1, noiseValue));
    col = mix(col, uColorTop, step(uTreshold2, noiseValue));

    // Ombre
    float shadow = length(s) * uShadowIntensity;
    col *= (1.0 - shadow);

    // Lumière
    float whiteMask = step(0.8, noiseValue);
    col = mix(col, vec3(1.0), whiteMask);

    gl_FragColor = vec4(col, 1.0);
}