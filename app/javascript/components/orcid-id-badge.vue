<template>
  <div class="orcid-panel">
    <p>
      <span>ORCID iD:</span>
      <a :href="user.orcid_url" class="nowrap">
        <img src='images/orcid-id-logo.svg' alt="orcid logo" class="orcid-circle" />
        {{user.orcid_url}}
      </a>
    </p>
    <p>
      Your ORCID iD is currently registered with UVA. There are no further actions you need to take.
    </p>
  </div>

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
    margin-bottom: 2rem;
  }
  .nowrap {
    white-space:nowrap;
  }
}
</style>
