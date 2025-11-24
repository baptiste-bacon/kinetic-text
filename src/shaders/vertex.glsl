varying vec2 vUv;

void main() {
    vUv = uv; // On transmet les coordonnées de texture au fragment shader
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}