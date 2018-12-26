#####  根据不同method 执行不同操作
- 版本
- 权限
- 认证
- 访问频率限制
- 路由
- 视图
- 分页
- 解析器 根据请求头 处理请求参数  
- 渲染器


```cython
from rest_framework import viewsets

class AuthorModelView(viewsets.ModelViewSet):
  queryset = models.Author.objects.all()
  serializer_class = AuthorModelSerializers

```
 ##### 继承关系
 ```cython
class View: 

class APIView(View):
 
class GenericAPIView(views.APIView):

class GenericViewSet(ViewSetMixin, generics.GenericAPIView):

class ModelViewSet(mixins.CreateModelMixin,
                   mixins.RetrieveModelMixin,
                   mixins.UpdateModelMixin,
                   mixins.DestroyModelMixin,
                   mixins.ListModelMixin,
                   GenericViewSet):
```
- 渲染器 页面显示效果
```cython
REST_FRAMEWORK = {
    #渲染
    'DEFAULT_RENDERER_CLASS': ['rest_framework.renderers.JSONRenderer'],
    #版本
    'DEFAULT_VERSIONING_CLASS': 'rest_framework.versioning.QueryParameterVersioning', #版本类 /?version=v1
    'DEFAULT_VERSIONING_CLASS': 'rest_framework.versioning.URLPathVersioning', #版本类 /v1/xxxxx
    'ALLOWED_VERSION': ['v1', 'v2'],  #允许的版本 
    'VERSION_PARAM': 'version',       #版本参数
    'DEFAULT_VERSION': 'v1',          #默认版本
    #path('api/', include('api.urls')),
    #re_path('/(?P<version>[v1|v2]+)/source/', course.CourseView.as_view())
    
    #re_path('api/(?P<version>\w+/)', include('api.urls')),
    #re_path('source/', course.CourseView.as_view())
    #获取版本 request.version
    ###############################################################
    
    






}
```

请求进来 view -> dispatch -> 