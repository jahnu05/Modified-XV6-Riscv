#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <time.h>

int determineGameResult(int choiceA, int choiceB)
{
  if (choiceA == choiceB)
  {
    return 0;
  }
  else if ((choiceA == 0 && choiceB == 2) || (choiceA == 1 && choiceB == 0) || (choiceA == 2 && choiceB == 1))
  {
    return 1;
  }
  else
  {
    return 2;
  }
}

int main()
{
  char *ip = "127.0.0.1";
  int port_1 = 5000;
  int port_2 = 5020;

  int server_sock_1, server_sock_2, client_sock_A, client_sock_B;
  struct sockaddr_in server_addr_1, client_addr_1, server_addr_2, client_addr_2;
  socklen_t addr_size;
  char buffer[1024];
  int n;

  server_sock_1 = socket(AF_INET, SOCK_STREAM, 0);
  if (server_sock_1 < 0)
  {
    perror("[-]Socket error");
    exit(1);
  }
  printf("[+]TCP server socket created.\n");

  memset(&server_addr_1, '\0', sizeof(server_addr_1));
  server_addr_1.sin_family = AF_INET;
  server_addr_1.sin_port = htons(port_1);
  server_addr_1.sin_addr.s_addr = inet_addr(ip);

  n = bind(server_sock_1, (struct sockaddr *)&server_addr_1, sizeof(server_addr_1));
  if (n < 0)
  {
    perror("Bind error");
    exit(1);
  }
  printf("Bind to the port number: %d\n", port_1);
  server_sock_2 = socket(AF_INET, SOCK_STREAM, 0);
  if (server_sock_2 < 0)
  {
    perror("[-]Socket error");
    exit(1);
  }
  printf("[+]TCP server socket created.\n");

  memset(&server_addr_2, '\0', sizeof(server_addr_2));
  server_addr_2.sin_family = AF_INET;
  server_addr_2.sin_port = htons(port_2);
  server_addr_2.sin_addr.s_addr = inet_addr(ip);

  int m = bind(server_sock_2, (struct sockaddr *)&server_addr_2, sizeof(server_addr_2));
  if (m < 0)
  {
    perror("Bind error");
    exit(1);
  }
  printf("Bind to the port number: %d\n", port_2);

  listen(server_sock_1, 5);

  listen(server_sock_2, 5);

  // srand(time(NULL));
  while (1)
  {
    addr_size = sizeof(client_addr_1);
    client_sock_A = accept(server_sock_1, (struct sockaddr *)&client_addr_1, &addr_size);
    printf("Client A connected.\n");
    int client_choice_A;
    int bytes_received_A = recv(client_sock_A, &client_choice_A, sizeof(int), 0);

    if (bytes_received_A == -1)
    {
      perror("recv");
    }
    else
    {
      printf("Received integer from Client A: %d\n", client_choice_A);
    }

    addr_size = sizeof(client_addr_2);
    client_sock_B = accept(server_sock_2, (struct sockaddr *)&client_addr_2, &addr_size);
    printf("Client B connected.\n");
    int client_choice_B;
    int bytes_received_B = recv(client_sock_B, &client_choice_B, sizeof(int), 0);

    if (bytes_received_B == -1)
    {
      perror("recv");
    }
    else
    {
      printf("Received integer from Client B: %d\n", client_choice_B);
    }

    int result = determineGameResult(client_choice_A, client_choice_B);
    printf("%d\n", result);
    bzero(buffer, 1024);
    char buffer1[1024], buffer2[1024];
    bzero(buffer1, 1024);
    bzero(buffer2, 1024);
    strcpy(buffer, "It's a draw");
    strcpy(buffer1, "You won");
    strcpy(buffer2, "You lost");

    if (result == 0)
    {
      send(client_sock_A, buffer, strlen(buffer), 0);
      send(client_sock_B, buffer, strlen(buffer), 0);
    }
    else if (result == 1)
    {
      send(client_sock_A, buffer1, strlen(buffer1), 0);
      send(client_sock_B, buffer2, strlen(buffer2), 0);
    }
    else if (result == 2)
    {
      send(client_sock_A, buffer2, strlen(buffer2), 0);
      send(client_sock_B, buffer1, strlen(buffer1), 0);
    }

    int next_A, next_B;
    recv(client_sock_A, &next_A, sizeof(int), 0);
    recv(client_sock_B, &next_B, sizeof(int), 0);

    if (next_A == 1 && next_B == 1)
    {
      int next = 1;
      send(client_sock_A, &next, sizeof(int), 0);
      send(client_sock_B, &next, sizeof(int), 0);
    }
    else
    {
      int next = 0;
      send(client_sock_A, &next, sizeof(int), 0);
      send(client_sock_B, &next, sizeof(int), 0);
      break;
    }

    close(client_sock_A);
    close(client_sock_B);

  }
    close(server_sock_1);
    close(server_sock_2);
  return 0;
}
