region          = "eu-central-1"
env             = "dev"
domain          = "best-store.click"
certificate_arn = "arn:aws:acm:eu-central-1:824591438121:certificate/aefc8907-4d50-43c8-af46-d2f92df6d65a"
docker_registry = ""
image_tag       = "0.2.0"
pods = {
  "default" : {
    index : "1"
    name : "default",
    size : "large"
    type : "PUBLIC",
    org : ""
  }
  "globale" : {
    index : "2"
    name : "globale",
    size : "x-large",
    type : "PUBLIC"
    org : ""
  }
  "org-352023632b046970c104b76f" : {
    index : "3"
    name : "org-352023632b046970c104b76f",
    size : "x-large",
    type : "PRIVATE",
    org : "352023632b046970c104b76f"
  }
}