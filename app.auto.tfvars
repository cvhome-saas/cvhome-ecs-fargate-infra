region          = "eu-central-1"
env             = "dev"
domain          = "best-store.click"
certificate_arn = "arn:aws:acm:eu-central-1:824591438121:certificate/aefc8907-4d50-43c8-af46-d2f92df6d65a"
docker_registry = ""
image_tag       = "main-0.2.0-12070230160-25-1-SNAPSHOT"
pods = {
  "default" : {
    index : "1"
    name : "default",
    size : "large"
    type : "PUBLIC",
    org : ""
  }
  "org-d1952c95-312e-4bb9-9a2d-b703d031276f" : {
    index : "2"
    name : "org-d1952c95-312e-4bb9-9a2d-b703d031276f",
    size : "x-large",
    type : "PRIVATE",
    org : "d1952c95-312e-4bb9-9a2d-b703d031276f"
  }
}