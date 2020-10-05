# 1.0.3

## 1. Enhancements
  * Improve logging for Action API

## 1. Bug fix
  * Fix stopping ws connection on missing pongs.

# 1.0.2

## 1. Enhancements
  * Default authentication to 60sec
  * Allow `timeout` in graph_con config for default execution timeout (defaults to 5 sec).
  * Allow `timeout` in graph_coni[:auth] config for default authentication timeout (defaults to 60 sec).

# 1.0.1

## 1. Enhancements
  * Stop GraphConn process if authentication returns 401
  * Exponentially increase delay between two unsuccessful authentications
  * Require cowlib ~> 2.9.1

# 1.0.0

## 1. Enhancements
  * Handle GOAWAY message sent by server.
