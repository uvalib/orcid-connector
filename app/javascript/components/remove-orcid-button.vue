<template>
  <div >
    <p>No longer want to have your ORCID iD linked?</p>
    <a v-on:click="destroyOrcid()" class="button button-red">
      Remove my ORCID iD
    </a>
  </div>

</template>
<script>
import axios from 'axios'
export default {
  props: ['orcid_removal_path'],
  methods: {
    destroyOrcid() {
      var token = document.getElementsByName('csrf-token')[0].content
      axios.
        delete(this.orcid_removal_path).
        then(response =>
             window.location.replace('/')
            )
    }
  }

}
</script>

<style scoped>
.button-red {
  background-color: #E00000;
  color: white;
  border-color: black;
}

</style>
