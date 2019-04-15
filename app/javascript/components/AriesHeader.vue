<template>
   <div class="header">
      <router-link :to="{ name: 'home'}"><span><img class="aries" src="../assets/aries.png"/><span class="app-name">Aries</span></span></router-link>
      <a target="_blank" href="https://library.virginia.edu"><img class="uva-library" src="../assets/uvalogo.png"/></a>
   </div>
</template>

<script>
export default {
}
</script>

<style scoped>
div.header {
   background-color: #002F6C;
   color: white;
   padding:15px;
   border-bottom: 1px solid #d2e5f7;
   text-align: left;
}
a {
  color: white;
  text-decoration: none;
}
div.header span.app-name {
   margin: 0 15px;
   font-family: 'Fahkwang', sans-serif;
   font-size: 50px;
   position: relative;
}
div.header img.aries {
  position: relative;
  top: 8px;
}
img.uva-library {
  position: absolute;
  top: 15px;
  right: 15px;
  max-height: 75px;
}
.subtitle {
   display: inline-block;
   margin: 5px 0 0 15px;
}
</style>
