import { createApp } from 'vue'
import App from './App.vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import { VueDapp } from 'vue-dapp'

const app = createApp(App)

app.use(VueDapp)
app.use(ElementPlus)
app.mount('#app')
