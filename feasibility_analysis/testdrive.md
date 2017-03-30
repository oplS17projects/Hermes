a simple experiment on communication via tcp ports

a server runs continously servicing clients. Clients connect, send a message, and
server replies with a message. Message should appear in each separate REPL area
prompt

run server.rkt in a REPL
```
,en server.rkt 
(define stop (serve 8080))  ;; starts serve listening at port 8080
(stop) ;; to stop server and free the ports

```

run client.rkt in a separate REPL
```
,en client.rkt
(define stop (client 8080)) ;; starts client talking to server at port 8080

```
