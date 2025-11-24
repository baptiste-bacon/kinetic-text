<script setup lang="ts">
import type { TresObject } from '@tresjs/core'
import { Color, Vector2 } from 'three'
import { useLoop } from '@tresjs/core'
import { onMounted, onUnmounted, shallowRef } from 'vue'
import { Pane } from 'tweakpane';

import vertexShader from '../shaders/vertex.glsl'
import fragmentShader from '../shaders/fragment.glsl'

const { onBeforeRender } = useLoop()

const boxRef = shallowRef<TresObject | null>(null)

const uniforms = shallowRef({
  uTime: { value: 0.0 },
  uDistortionStrength: { value: 0.5 },
  uColorBg: { value: new Color('#ff007f') },
  uColorMid: { value: new Color('#ff9900') },
  uColorTop: { value: new Color('#ffdd00') },
  uTreshold1: { value: 0.4 },
  uTreshold2: { value: 0.7 },
  uSpeed: { value: new Vector2(0.10) },
  uRotationSpeed: { value: 0.0 },
  uLacunarity: { value: 2.0 },
  uIntensity: { value: new Vector2(1.2) },
  uShadowIntensity: { value: 0.5 }
})

onBeforeRender(({ elapsed }) => {
  if (boxRef.value) {
    // boxRef.value.rotation.y = elapsed
    // boxRef.value.rotation.z = elapsed
  }
  uniforms.value.uTime.value = elapsed;
})

onMounted(() => {
  const pane = new Pane({ title: "Shader Controls" })

  const params = {
    distortion: 1.0,
    colorBg: '#ff007f',
    colorMid: '#ff9900',
    colorTop: '#ffdd00',
    treshold1: 0.4,
    treshold2: 0.7,
    speedX: 0.1,
    speedY: 0.1,
    rotationSpeed: 0.0,
    lacunarity: 2.0,
    intensityX: 1.0,
    intensityY: 1.2,
    shadowIntensity: 0.5
  }

  pane.addBinding(params, 'distortion', { min: 0.0, max: 50.0 }).on('change', ev => {
    uniforms.value.uDistortionStrength.value = ev.value;
  })

  // Gestion des couleurs
  pane.addBinding(params, 'colorBg').on('change', ev => {
    uniforms.value.uColorBg.value.set(ev.value)
  })
  pane.addBinding(params, 'colorMid').on('change', ev => {
    uniforms.value.uColorMid.value.set(ev.value)
  })
  pane.addBinding(params, 'colorTop').on('change', ev => {
    uniforms.value.uColorTop.value.set(ev.value)
  })

  pane.addBinding(params, 'treshold1', { min: 0.0, max: 1.0 }).on('change', ev => {
    uniforms.value.uTreshold1.value = ev.value
  })
  pane.addBinding(params, 'treshold2', { min: 0.0, max: 1.0 }).on('change', ev => {
    uniforms.value.uTreshold2.value = ev.value
  })

  // Vitesse
  pane.addBinding(params, 'speedX', { min: -1.0, max: 1.0 }).on('change', ev => {
    uniforms.value.uSpeed.value.x = ev.value
  })
  pane.addBinding(params, 'speedY', { min: -1.0, max: 1.0 }).on('change', ev => {
    uniforms.value.uSpeed.value.y = ev.value
  })
  // Rotation
  pane.addBinding(params, 'rotationSpeed', { min: -5.0, max: 5.0 }).on('change', ev => {
    uniforms.value.uRotationSpeed.value = ev.value
  })
  // Lacunarité
  pane.addBinding(params, 'lacunarity', { min: -5.0, max: 20.0 }).on('change', ev => {
    uniforms.value.uLacunarity.value = ev.value
  })
  // Intensité
  pane.addBinding(params, 'intensityX', { min: 0, max: 10.0 }).on('change', ev => {
    uniforms.value.uIntensity.value.x = ev.value
  })
  pane.addBinding(params, 'intensityY', { min: 0, max: 10.0 }).on('change', ev => {
    uniforms.value.uIntensity.value.y = ev.value
  })
  // Ombre
  pane.addBinding(params, 'shadowIntensity', { min: 0, max: 1.0 }).on('change', ev => {
    uniforms.value.uShadowIntensity.value = ev.value
  })
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