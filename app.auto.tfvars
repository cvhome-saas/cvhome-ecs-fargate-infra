region          = "eu-central-1"
env             = "dev"
domain          = "best-store.click"
certificate_arn = "arn:aws:acm:eu-central-1:824591438121:certificate/aefc8907-4d50-43c8-af46-d2f92df6d65a"
docker_registry = ""
image_tag       = "multi-region-0.1.5-12016689022-20-1-SNAPSHOT"
pods = {
  "default" : {
    index : "1"
    name : "default",
    size : "large"
  }
  "client-a" : {
    index : "2"
    name : "client-a",
    size : "x-large"
  }
}