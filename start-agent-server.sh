#!/bin/bash

export VERACODE_API_KEY_ID=879c25fadae45252ebbd1ee06358ca42
export VERACODE_API_KEY_SECRET=8ef83ed92a7366ed58c360c63d21e5396d8ddc903b9c4fadf72f4d9348d12dc24f5238c4dfd8741ada17cde39ec9f23918c58c3848f9c2feb1e51a42511cf6e4
docker run --rm -p 10010:10010 -e VERACODE_API_KEY_ID -e VERACODE_API_KEY_SECRET --name iast-agent-server veracode/iast-agent-server:latest