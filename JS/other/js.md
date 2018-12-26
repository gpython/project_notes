```html
var name = 'Google'

<!--函数首字母大写 一般标识为类-->
function Foo(name, age){
    this.name = name;
    this.age = age;
    this.getName = function(){
        <!--当前类的this对象-->
        console.log(this.name);
        var _this = this;
        (function(){
            <!--this为window对象-->
            console.log(this.name);
                
            console.log(_this.name);
        })()
    }
}

obj = new Foo('yahoo', 19)
obj.getName()

function foo(){
    <!--this为window对象-->
    console.log(this.name);
}
foo()

```