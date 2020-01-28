/*
.Synopsis
   Terraform Variable File
.DESCRIPTION
   This file holds the variables to be used with the application.
*/

name                       = "fullstack"
location                   = "centralus"
randomization_level        = 4
lock                       = false
docker_registry_server_url = "docker.io"
service_plan_size          = "P1v2"
service_plan_tier          = "PremiumV2"
web_apps = [{
  app_name                 = "web"
  image_name               = "danielscholl/spring-user-api",
  image_release_tag_prefix = "latest"
}]

function_apps = {
  func1 = {
    image = "danielscholl/spring-function-app:latest"
  }
}
