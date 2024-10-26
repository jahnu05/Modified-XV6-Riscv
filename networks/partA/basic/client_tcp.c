#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main() {
  // source: https://github.com/nikhilroxtomar/TCP-Client-Server-Implementation-in-C

  char *ip = "127.0.0.1";
  int port = 5000;

  int sock;
  struct sockaddr_in addr;
  socklen_t addr_size;
  char buffer[1024];
  int n;

  // Error handling for socket() call
  sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock < 0) {
    perror("[-]Socket error");
    exit(1);
  }
  printf("[+]TCP server socket created.\n");

  // Error handling for connect() call
  memset(&addr, '\0', sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = port;
  addr.sin_addr.s_addr = inet_addr(ip);

  n = connect(sock, (struct sockaddr*)&addr, sizeof(addr));
  if (n < 0) {
    perror("Connect error");
    exit(1);
  }
  printf("Connected to the server.\n");

  // Error handling for send() call
  bzero(buffer, 1024);
  strcpy(buffer, "HELLO, THIS IS CLIENT.");
  printf("Client: %s\n", buffer);
  n = send(sock, buffer, strlen(buffer), 0);
  if (n < 0) {
    perror("Send error");
    exit(1);
  }

  // Error handling for recv() call
  bzero(buffer, 1024);
  n = recv(sock, buffer, sizeof(buffer), 0);
  if (n < 0) {
    perror("Recv error");
    exit(1);
  }
  printf("Server: %s\n", buffer);

  // Error handling for close() call
  close(sock);
  printf("Disconnected from the server.\n");

  return 0;
}
