##### Vue
- 安装node
- 安装npm
- 安装webpack: npm install -g webpack
- 安装vue-cli: npm install -g vue-cli
- 创建项目:     vue init webpack my-project
- 安装项目依赖:  npm install
- 运行项目:     npm run dev 

##### 
- main.js 主入口文件 加载Vue
- App.vue 主的组件
- components 存放所有vue的组件
- assets 资源文件夹 img css

##### 组件的三个部分
- template 标签部分 Html
- script 逻辑部分 JS
- style 样式部分  CSS   

```html
<script>
export default {
    name:'ComponentName',
    data(){
        return{
            
        }
    }
}
</script>
```
 
###### App.vue
```html
<template>
    <div id="app">
        <img src="./assets/logo.png" alt="">
        <!--3. 呈现组件-->
        <HelloWorld></HelloWord>
        <IWen></IWen>
    </div>
</template>
<script >
//1. 引入组件 
import HelloWorld from './components/HelloWorld'
import IWen from './components/IWen'

export default{
    name:'app',
    components:{
        //2. 加载组件
        HelloWorld,
        IWen,
    },
}

</script>

<style>

</style>

```
##### 组件 此组件可以引入到APP.vue主组件中
```vue
<template>
    <div>

    </div>
</template>
<script >
export default{
    name:'Components_Name',
    data(){
        return{
            
        }
    }
}
</script>
<style>

</style>
```
##### 安装axios 并引入加载 main.js
- npm install axios --save
- import Axios from "axios"
- Vue.prototype.$axios = Axios

```html
Get请求
this.$axios.('http://xxxxx/',{
    params:{
        type:'params1',
        type:'params2',
    }
}).then(res=>{
    this.newData = res.data;
    console.log(res.data);
}).catch(error=>{
    console.log(error);
})

POST请求
from-data: ?name=google&age=10
x-www-form-urlencoded: {name:'google', age:10}
注意 axios 接受的POST请求参数的格式是 form-data格式
使用qs模块转换
import qs from "qs"
created(){
      this.$axios.post("http://www.wwtliu.com/sxtstu/blueberrypai/login.php", qs.stringify({
        user_id: "iwen@qq.com",
        password: "iwen123",
        verification_code: "crfvw",
      })).then(res=>{
        console.log("23:")
        console.log(res.data);
      }).catch(error=>{
        console.log(error);
      })
    }

```
##### 全局Axios配置 main.js
- Axios.defaults.baseURL = 'http://www.xx.com';
- #Axios.defaults.headers.common['Authorization'] = AUTH_TOKEN;
- Axios.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded';

##### 拦截器
```html
//添加请求拦截器
Axios.interceptors.request.use(function (config) {
  console.log(+config);
  return config
}, function (error) {
  //对请求错误做什么
  return Promise.reject(error);
})

import qs from "qs"

Axios.interceptors.request.user(function(config){
  if(config.method == 'post'){
    config.data = qs.stringify(config.data);
  }
}, function(error){
  return Promise.reject(error);
})


//添加相应拦截器
Axios.interceptors.response.use(function (response) {
  console.log(response);
  return response;
}, function (error) {
  //对响应错误做什么
  return Promise.reject(error);
})

```

##### 跨域
```html
    proxyTable: {
      "/api":{
        target:'http://localhost:3000',
        changeOrigin: true,
        pathRewrite:{
          '^/api':''
        }
      }
    },
```

##### 路由
- 安装
  - npm install --save vue-router
- 引用
  - import Vue-router from 'vue-router'
  - Vue.use(Vue-router)
- 配置路由文件 main.js
```html
import router from './router'
new Vue({
    el:'#app',
    template:'<App/>',
    router,
    components:{
        App
    }
})

App.vue视图加载
<router-view></router-view>
```
- router/index.js
```html
import VueRouter from "vue-router"
import Path1 from 'path1'
import Path2 from 'path2'


Vue.use(VueRouter)

export default new VueRouter({
    routes:[
      {
        path:'/',
        name: 'RouterPath1',
        component: Path1
      },
      {
        path:'/path2',
        name:'Path2',
        componet:Path2
      }    
    ]  
})
```
  

