
#####django MySQL Settings 配置
```cpython
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'orm',
        'USER': 'root',
        'PASSWORD': 'abc12345',
        'HOST': '192.168.9.55',
        'PORT': 3306
    }
}

```
pip install pymysql

更改manager.py文件 添加如下
```cython
import pymysql
pymysql.install_as_MySQLdb()
```
```cython
views.PublishView.as_view() 
    PublishView(APIView)
        APIView(View)
        执行as_view()
        执行 view = super(APIView, self).as_view(**initkwargs) 即执行父类View as_view方法
        父类View as_view()方法中执行dispatch()方法 
        dispatch()方法先寻找APIView中是否有此方法 若没有在寻找View中的dispatch方法
        APIView中有dispatch()方法 则执行APIView中dispatch()方法  
        
        APIView => dispatch()
          #构建一个新的request
          request = self.initialize_request(request, *args, **kwargs)
          
          def initialize_request(self, request, *args, **kwargs):
            """
            Returns the initial request object.
            """
            parser_context = self.get_parser_context(request)
            return Request(
                request,
                parsers=self.get_parsers(),
                authenticators=self.get_authenticators(),
                negotiator=self.get_content_negotiator(),
                parser_context=parser_context
            )
            
```
执行到dispatch 重新封装构建request请求
```cython
request = self.initialize_request(request, *args, **kwargs)
self.request = request

```
认证 权限 频率 相关操作执行
```cython
    try:
      self.initial(request, *args, **kwargs)
          
      #认证执行的是self.perform_authentication(request) => request.user
      #真正执行的是 封装request的初始化Request类的 @property字段的user方法
      '''
      def initialize_request(self, request, *args, **kwargs):
        """
        Returns the initial request object.
        """
        parser_context = self.get_parser_context(request)

        return Request(
            request,
            parsers=self.get_parsers(),
            authenticators=self.get_authenticators(),
            negotiator=self.get_content_negotiator(),
            parser_context=parser_context
        )
      '''
            
```
根据 get post put等http请求执行相关处理
```cython
            if request.method.lower() in self.http_method_names:
                handler = getattr(self, request.method.lower(),
                                  self.http_method_not_allowed)
            else:
                handler = self.http_method_not_allowed

            response = handler(request, *args, **kwargs)

        except Exception as exc:
            response = self.handle_exception(exc)

        self.response = self.finalize_response(request, response, *args, **kwargs)
        return self.response
```






        
            
