<template>
  <div v-if="user.orcid_url">
    <orcid-id-badge v-bind:user="user" />
  </div>

  <div v-else>
    <button id="connect-orcid-button"
      @click="openOrcid()">
      <img id="orcid-id-icon"
        src="https://orcid.org/sites/default/files/images/orcid_24x24.png"
        width="24"
        height="24"
        alt="ORCID iD icon"
      />
          Register or Connect your ORCID iD
    </button>
  </div>
</template>
<script>
import OrcidIdBadge from './orcid-id-badge'
export default {
  data: function(){
    var element = document.getElementById('vue')
    var user = JSON.parse(element.dataset.user)
    var oauth_url = element.dataset.orcidOauthUrl
    return {
      user: user,
      oauth_url: oauth_url
    }
  },
  methods: {
    openOrcid: function (){
      window.open(this.oauth_url, '_blank')
    }
  },
  components: {OrcidIdBadge}
}

</script>
<style scoped>
#connect-orcid-button{
  border: 1px solid #D3D3D3;
  padding: .3em;
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 1px 1px 3px #999;
  cursor: pointer;
  color: #999;
  font-weight: bold;
  font-size: .8em;
  line-height: 24px;
  vertical-align: middle;
}

#connect-orcid-button:hover{
  border: 1px solid #338caf;
  color: #338caf;
}

#orcid-id-icon{
  display: block;
  margin: 0 .5em 0 0;
  padding: 0;
  float: left;
}

</style>
