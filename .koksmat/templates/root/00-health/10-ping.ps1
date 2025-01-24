<#---
title: Ping
description: Simple ping endpoint
tag: ping
api: post
---#>
param(
    [string]$pong = "pong"
)

#
# Ping

write-host $pong


