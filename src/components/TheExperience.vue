<script setup lang="ts">
import type { TresObject } from '@tresjs/core'
import { Color, Vector2, Vector3 } from 'three'
import { useLoop } from '@tresjs/core'
import { onMounted, onUnmounted, shallowRef } from 'vue'
import { Pane } from 'tweakpane';

import vertexShader from '../shaders/vertex.glsl'
import fragmentShader from '../shaders/fragment.glsl'

const { onBeforeRender } = useLoop()

const boxRef = shallowRef<TresObject | null>(null)
let pane = null;

const uniforms = shallowRef({
  uTime: { value: 0.0 },

  uColorBg: { value: new Color('#ff007f') },
  uColorMid: { value: new Color('#ff9900') },
  uColorTop: { value: new Color('#ffdd00') },

  uTreshold1: { value: 0.5 },
  uTreshold2: { value: 0.65 },

  uScale: { value: 1.0 },
  uDistortionStrength: { value: 1.0 },
  uLacunarity: { value: 1.5 },
  uIntensity: { value: new Vector2(0.5) },

  uSpeed: { value: new Vector2(0.05) },
  uRotationSpeed: { value: 0.0 },

  uLightDirection: { value: new Vector3(1.0, 1.0, 1.0) }, // Lumière diagonale
  uBumpStrength: { value: 0.6 },
  uSpecularPower: { value: 1.0 },
})

onBeforeRender(({ elapsed }) => {
  if (boxRef.value) {
    // boxRef.value.rotation.y = elapsed
    // boxRef.value.rotation.z = elapsed
  }
  uniforms.value.uTime.value = elapsed;
})

onMounted(() => {
  pane = new Pane({ title: "Shader Controls" })

  const params = {
    colorBg: '#ff007f',
    colorMid: '#ff9900',
    colorTop: '#ffdd00',
    treshold1: 0.5,
    treshold2: 0.65,

    scale: 1.0,
    strength: 1.0,
    lacunarity: 1.5,
    intensityX: 0.5,
    intensityY: 0.5,

    speedX: 0.05,
    speedY: 0.05,
    rotationSpeed: 0.0,

    bumpStrength: 1.0,
    specularPower: 1.0,
    lightX: -0.5,
    lightY: 0.5,
  }

  // Gestion des couleurs
  const fColors = pane.addFolder({ title: 'Couleurs' });
  fColors.addBinding(params, 'colorBg').on('change', ev => {
    uniforms.value.uColorBg.value.set(ev.value)
  })
  fColors.addBinding(params, 'colorMid').on('change', ev => {
    uniforms.value.uColorMid.value.set(ev.value)
  })
  fColors.addBinding(params, 'colorTop').on('change', ev => {
    uniforms.value.uColorTop.value.set(ev.value)
  })
  fColors.addBinding(params, 'treshold1', { min: 0.0, max: 1.0 }).on('change', ev => {
    uniforms.value.uTreshold1.value = ev.value
  })
  fColors.addBinding(params, 'treshold2', { min: 0.0, max: 1.0 }).on('change', ev => {
    uniforms.value.uTreshold2.value = ev.value
  })

  // Distortion
  const fParameters = pane.addFolder({ title: 'Paramètres' })
  fParameters.addBinding(params, 'scale', { min: 0.0, max: 20.0 }).on('change', ev => {
    uniforms.value.uScale.value = ev.value;
  })
  fParameters.addBinding(params, 'strength', { min: 0.1, max: 20.0 }).on('change', ev => {
    uniforms.value.uDistortionStrength.value = ev.value;
  })
  // Lacunarité
  fParameters.addBinding(params, 'lacunarity', { min: 0.0, max: 10.0 }).on('change', ev => {
    uniforms.value.uLacunarity.value = ev.value
  })
  // Intensité
  pane.addBinding(params, 'intensityX', { min: 0, max: 10.0 }).on('change', ev => {
    uniforms.value.uIntensity.value.x = ev.value
  })
  // pane.addBinding(params, 'intensityY', { min: 0, max: 10.0 }).on('change', ev => {
  //   uniforms.value.uIntensity.value.y = ev.value
  // })

  // Vitesse
  const fSpeed = pane.addFolder({ title: 'Vitesse' });
  fSpeed.addBinding(params, 'speedX', { min: -1.0, max: 1.0 }).on('change', ev => {
    uniforms.value.uSpeed.value.x = ev.value
  })
  fSpeed.addBinding(params, 'speedY', { min: -1.0, max: 1.0 }).on('change', ev => {
    uniforms.value.uSpeed.value.y = ev.value
  })
  // Rotation
  fSpeed.addBinding(params, 'rotationSpeed', { min: -1.0, max: 1.0 }).on('change', ev => {
    uniforms.value.uRotationSpeed.value = ev.value
  })

  // Lumiere
  const fLight = pane.addFolder({ title: 'Lumière & Relief' });

  fLight.addBinding(params, 'bumpStrength', { min: 0.1, max: 5.0 }).on('change', (ev) => {
    uniforms.value.uBumpStrength.value = ev.value;
  });

  fLight.addBinding(params, 'specularPower', { min: 0.0, max: 128.0 }).on('change', (ev) => {
    uniforms.value.uSpecularPower.value = ev.value;
  });

  // fLight.addBinding(params, 'specularIntensity', { min: 0.0, max: 128.0 }).on('change', (ev) => {
  //   uniforms.value.uSpecularIntensity.value = ev.value;
  // });

  // Direction de la lumière
  fLight.addBinding(params, 'lightX', { min: -1, max: 1 }).on('change', (ev) => {
    uniforms.value.uLightDirection.value.x = ev.value;
  });
  fLight.addBinding(params, 'lightY', { min: -1, max: 1 }).on('change', (ev) => {
    uniforms.value.uLightDirection.value.y = ev.value;
  });

})

onUnmounted(() => {
  if (pane) pane.dispose()
})

</script>

<template>
  <TresPerspectiveCamera :position="[0, 0, 5]" :look-at="[0, 0, 0]" />
  <TresAmbientLight :intensity="0.5" color="white" />
  <TresMesh ref="boxRef" :position="[0, 0, 0]">
    <!-- <TresSphereGeometry :args="[1]" /> -->
    <TresPlaneGeometry :args="[4, 4]" />
    <TresShaderMaterial :args="[{ vertexShader: vertexShader, fragmentShader: fragmentShader, uniforms: uniforms }]" />
  </TresMesh>
  <!-- <TresDirectionalLight
    :position="[0, 2, 4]"
    :intensity="1"
    cast-shadow
  /> -->
  <!-- <TresAxesHelper /> -->
  <!-- <TresGridHelper :args="[10, 10]" /> -->
</template>