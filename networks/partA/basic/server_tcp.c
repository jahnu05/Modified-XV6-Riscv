#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {
// source:https://github.com/nikhilroxtomar/TCP-Client-Server-Implementation-in-C
  char *ip = "127.0.0.1";
  int port = 5000;

  int server_sock, client_sock;
  struct sockaddr_in server_addr, client_addr;
  socklen_t addr_size;
  char buffer[1024];
  int n;

  // Error handling for socket() call
  server_sock = socket(AF_INET, SOCK_STREAM, 0);
  if (server_sock < 0) {
    perror("[-]Socket error");
    exit(1);
  }
  printf("[+]TCP server socket created.\n");

  // Error handling for bind() call
  memset(&server_addr, '\0', sizeof(server_addr));
  server_addr.sin_family = AF_INET;
  server_addr.sin_port = port;
  server_addr.sin_addr.s_addr = inet_addr(ip);

  n = bind(server_sock, (struct sockaddr*)&server_addr, sizeof(server_addr));
  if (n < 0) {
    perror("Bind error");
    exit(1);
  }
  printf("Bind to the port number: %d\n", port);

  // Error handling for listen() call
  listen(server_sock, 5);

  while (1) {
    addr_size = sizeof(client_addr);
    client_sock = accept(server_sock, (struct sockaddr*)&client_addr, &addr_size);
    printf("Client connected.\n");

    // Error handling for recv() call
    bzero(buffer, 1024);
    n = recv(client_sock, buffer, sizeof(buffer), 0);
    if (n < 0) {
      perror("Recv error");
      exit(1);
    }

    // Error handling for send() call
    bzero(buffer, 1024);
    strcpy(buffer, "HI, THIS IS SERVER. HAVE A NICE DAY!!!");
    n = send(client_sock, buffer, strlen(buffer), 0);
    if (n < 0) {
      perror("Send error");
      exit(1);
    }

    close(client_sock);
    printf("[+]Client disconnected.\n\n");

  }

  return 0;
}
