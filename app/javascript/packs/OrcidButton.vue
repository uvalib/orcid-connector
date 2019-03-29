<template>
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
</template>
<script>
export default {
  methods: {
    openOrcid: function (){
      console.log('orcid clicked');

    }
  }
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
