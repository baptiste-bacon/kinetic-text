<script setup lang="ts">
import { TresCanvas } from '@tresjs/core'

import TheExperience from './components/TheExperience.vue'
</script>

<template>
  <!-- <h1 class="test">GAMBERGE</h1> -->
  <TresCanvas
    clear-color="#000000"
    window-size
  >
    <TheExperience />
  </TresCanvas>
</template>

<style>
.test{
  z-index: 99;
  position: relative;
  font-size: 64px;
  text-align: center;
}
</style>