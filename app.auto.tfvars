region          = "eu-central-1"
env             = "dev"
domain          = "best-store.click"
certificate_arn = "arn:aws:acm:eu-central-1:824591438121:certificate/aefc8907-4d50-43c8-af46-d2f92df6d65a"
docker_registry = ""
pods = {
  "default" : {
    index : 0
    id : "1"
    name : "default",
    org : ""
    endpoint : ""
    endpointType : "INTERNAL"
    size : "large"
  }
  "org-d1952c95-312e-4bb9-9a2d-b703d031276f" : {
    index : 1
    id : "2"
    name : "org-d1952c95-312e-4bb9-9a2d-b703d031276f",
    org : "d1952c95-312e-4bb9-9a2d-b703d031276f"
    endpoint : ""
    endpointType : "INTERNAL"
    size : "x-large",
  }
}