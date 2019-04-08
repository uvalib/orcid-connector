<template>
  <div class="panel">
    <a :href="user.orcid_url">
      <img src='images/orcid-id-logo.svg' alt="orcid logo" class="orcid-circle" />
      {{user.orcid_url}}
    </a>
  </div>

</template>
<script>
export default {
  props: ['user']
}
</script>

<style scoped>
.panel {
  border: 1px solid black;
  padding: 5px;
}

.orcid-circle {
  width: 20px;
  margin: 2px 5px -2px 5px;;
}
</style>
