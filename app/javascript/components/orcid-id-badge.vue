<template>
  <p class="orcid-panel">ORCID iD:
    <a :href="user.orcid_url">
      <img src='images/orcid-id-logo.svg' alt="orcid logo" class="orcid-circle" />
      {{user.orcid_url}}
    </a>
  </p>

</template>
<script>
export default {
  props: ['user']
}
</script>

<style scoped lang="scss">

.orcid-circle {
  width: 20px;
  margin: 2px 5px -2px 5px;;
}
.orcid-panel {
  a {
    border-radius: .4rem;
    padding: 1rem;
    margin: 1rem;
    background: #f4f5f6;
  }
}
</style>
