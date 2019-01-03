css形式 分析网页
  response.css(".question-summary h3 a::attr(href)")
url合并 带域名完整url
  response.urljoin(href.extract())

创建 scrapy项目
定义提取的item
编写爬取网站的spider 并提取item
编写item pipeline 来存储体提取到的item 数据

CrawlSpider 使用 parse 方法来实现其逻辑

start_requests()
  该方法必须返回一个可迭代对象(iterable)。该对象包含了spider用于爬取的第一个Request
  当spider启动爬取并且未指定URL时，该方法被调用
  当指定了URL时，make_requests_from_url() 将被调用来创建Request对象
  该方法仅仅会被Scrapy调用一次，因此您可以将其实现为生成器


Crawing Rules
  scrapy.spiders.Rule

  class scrapy.spiders.Rule(link_extractor,
    callback=None, cb_kwargs=None, follow=None,
    process_links=None, process_request=None)

  link_extractor 是一个 Link Extractor 对象。 其定义了如何从爬取到的页面提取链接
  follow 是一个布尔(boolean)值，指定了根据该规则从response提取的链接是否需要跟进。
  如果 callback 为None， follow 默认设置为 True ，否则默认为 False

response.xpath("//a[contains(@href, 'image2')]/img/@src")
href="image2" 的文本



Item Pipeline
  process_item(self, item, spider)
open_spider(self, spider)
  当spider被开启时，这个方法被调用
close_spider(self, spider)
  当spider被关闭时，这个方法被调用

启用一个Item Pipeline组件
  为了启用一个Item Pipeline组件，你必须将它的类添加到 ITEM_PIPELINES 配置
  ITEM_PIPELINES = {
    'myproject.pipelines.PricePipeline': 300,
    'myproject.pipelines.JsonWriterPipeline': 800,
  }
  分配给每个类的整型值，确定了他们运行的顺序，item按数字从低到高的顺序，通过pipeline，
  通常将这些数字定义在0-1000范围内


```python
import pymongo
class MongoPipeline(object):
  collection_name = "scrapy_items"

  def __init__(self, mongo_uri, mongo_db):
    self.mongo_uri = mongo_uri
    self.mongo_db = mongo_db

  @classmethod
  def from_crawler(cls, crawler):
    return cls(
      mongo_uri=crawler.settings.get("MONGO_URI"),
      mongo_db = crawler.settings.get("MONGO_DATABASE", "item")
    )

  def open_spider(self, spider):
    self.client = pymongo.MongoClient(self.mongo_uri)
    self.db = self.client[self.mongo_db]

  def close_spider(self, spider):
    self.client.close()

  def process_item(self, item, spider):
    self.db[self.collection_name].insert(dict(item))
    return item
```





