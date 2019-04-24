<template>
  <div class="">
    <div class="row">
      <div class="column column-50">
        <p v-if="flash.notice" class="flash notice">{{flash.notice}}</p>
        <p v-if="flash.alert" class='flash alert'>{{flash.alert}}</p>
      </div>
    </div>

    <p> UVA Computing ID: <span class="computing-id">{{user.user_id}}</span></p>
    <ul>
      <li>When you create or connect your ORCID iD, your ORCID iD is validated as belonging to you.</li>
      <li>When you connect your ORCID iD to UVA, your ORCID iD is registered as belonging to a member of the University of Virginia research community.</li>
      <li>Find out more about <a href="https://www.library.virginia.edu/libra/orcid-at-uva/">ORCID at UVA</a>.</li>
  </ul>
    <div v-if="user.orcid_url">
      <p>Your ORCID iD is currently registered with UVA.</p>
      <orcid-id-badge v-bind:user="user" />
      <div class="spacer"></div>
      <remove-orcid-button v-bind:orcid_removal_path="orcid_removal_path" />
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
  </div>
</template>
<script>
import OrcidIdBadge from './orcid-id-badge'
import RemoveOrcidButton from './remove-orcid-button'
import axios from 'axios'
let token = document.getElementsByName('csrf-token')[0].getAttribute('content')
axios.defaults.headers.common['X-CSRF-Token'] = token
axios.defaults.headers.common['Accept'] = 'application/json'

export default {
  data: function(){
    var element = document.getElementById('vue')
    var user = JSON.parse(element.dataset.user)
    var oauth_url = element.dataset.orcidOauthUrl
    var orcid_removal_path = element.dataset.orcidRemovalPath
    var flash_messages = JSON.parse(element.dataset.flash)
    return {
      user: user,
      oauth_url: oauth_url,
      orcid_removal_path: orcid_removal_path,
      flash: flash_messages
    }
  },
  methods: {
    openOrcid: function (){
      window.open(this.oauth_url, '_blank')
    }
  },
  components: {OrcidIdBadge, RemoveOrcidButton}
}

</script>
<style scoped lang="scss">
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

.panel {
  background: #f4f5f6;
}
.spacer {
  height: 10rem;
}
.computing-id {
  padding: .5rem;
  background: #f4f5f6;
  border-radius: .4rem;
}
.main.container {
  margin: 20rem 5rem;;
}
.flash {
  border-radius: .5rem;
  text-align: center;
  &.notice {
    color: white;
    background-color: green;
  }
  &.alert {
    background-color: red;
  }
}

</style>
