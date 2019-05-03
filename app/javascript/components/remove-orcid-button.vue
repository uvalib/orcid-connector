<template>
  <div >
    <button v-on:click="destroyOrcid()" class="button button-gray">
      Disconnect my ORCID iD
    </button>
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
.button-gray {
  background-color: #EEEEEE;
  color: black;
  border-color: black;
}

</style>
