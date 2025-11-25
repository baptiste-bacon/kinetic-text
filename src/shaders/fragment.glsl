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

uniform vec3 uLightDirection; // Direction du soleil (X, Y, Z)
uniform float uBumpStrength;  // Profondeur du relief (0.1 = plat, 2.0 = très creusé)
uniform float uSpecularPower; // Brillance (10.0 = gomme, 64.0 = verre mouillé)

uniform float uScale; 

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

float map(vec2 uv, float time) {
    vec2 center = vec2(0.5);
    vec2 centeredUv = uv - center;

    vec2 rotatedUv = rotate2d(time * uRotationSpeed) * centeredUv;
    rotatedUv += center;

    vec2 p = rotatedUv * uScale;

    // Premiere deformation
    vec2 q = vec2(0.0);
    q.x = fbm(p  + time * uSpeed.x);
    q.y = fbm(p  + vec2(5.2, 1.3) + time * uSpeed.y); // Petit décalage pour éviter un effet diagonal

    // Seconde deformation
    vec2 r = vec2(2.0);
    r.x = fbm(p  + q * uIntensity.x + vec2(1.7, 9.2) + time * uSpeed.x);
    r.y = fbm(p  + q * uIntensity.x + vec2(8.3, 2.8) + time * uSpeed.y);

    // Troisième deformation
    // vec2 s = vec2(0.0);
    // s.x = fbm(rotatedUv + r * uIntensity.y + vec2(10.2, 4.5) + time * uSpeed.x);
    // s.y = fbm(rotatedUv + r * uIntensity.y + vec2(7.5, 5.7) + time * uSpeed.y);

    // On rend le resultat entre 0 et 1
    float noiseValue = fbm(p  + r * uDistortionStrength) * 0.5 + 0.5;

    return noiseValue;
}

void main() {
    float h = map(vUv, uTime);

    vec2 e = vec2(0.01, 0.0);

    vec3 normal = normalize(vec3((map(vUv - e.xy, uTime) - map(vUv + e.xy, uTime)) * uBumpStrength, (map(vUv - e.yx, uTime) - map(vUv + e.yx, uTime)) * uBumpStrength, 1.0 // Le Z reste fixe, c'est le ratio avec X et Y qui compte
    ));

    // --- LUMIÈRE ---
    vec3 lightDir = normalize(uLightDirection);

    float rawDiff = max(dot(normal, lightDir), 0.0);
    float diffToon = smoothstep(0.3, 0.35, rawDiff); 

    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 reflectDir = reflect(-lightDir, normal);
    float rawSpec = pow(max(dot(viewDir, reflectDir), 0.0), uSpecularPower);

    float specToon = smoothstep(0.42, 0.41, rawSpec);

    float aa = 0.001; // Épaisseur de l'anti-aliasing
    vec3 col = mix(uColorBg, uColorMid, smoothstep(uTreshold1, uTreshold1 + aa, h));
    col = mix(col, uColorTop, smoothstep(uTreshold2, uTreshold2 + aa, h));

    col *= (diffToon * 0.5 + 1.0); 
    col += specToon;

    // float rim = 1.0 - max(dot(normal, viewDir), 0.0);
    // float rimToon = smoothstep(0.6, 0.65, rim);
    // col += rimToon * 0.1;

    gl_FragColor = vec4(col, 1.0);
}