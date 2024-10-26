#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <time.h>

char *determineGameResult(int choiceA, int choiceB)
{
    if (choiceA == choiceB)
    {
        return "It's a Draw";
    }
    else if ((choiceA == 0 && choiceB == 2) || (choiceA == 1 && choiceB == 0) || (choiceA == 2 && choiceB == 1))
    {
        return "Client 1 won";
    }
    else
    {
        return "Client 2 won";
    }
}

int main()
{
    char *ip = "127.0.0.1";
    int port_1 = 5000;
    int port_2 = 5020;

    int server_sock_1, server_sock_2;
    struct sockaddr_in server_addr1, server_addr2, client_addr1, client_addr2;
    socklen_t addr_size1, addr_size2;
    char buffer[1024];
    char buffer2[1024];
    int n;

    server_sock_1 = socket(AF_INET, SOCK_DGRAM, 0); // Use SOCK_DGRAM for UDP
    if (server_sock_1 < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }
    printf("[+]UDP server socket created.\n");

    memset(&server_addr1, 0, sizeof(server_addr1));
    server_addr1.sin_family = AF_INET;
    server_addr1.sin_port = htons(port_1); // Convert port to network byte order
    server_addr1.sin_addr.s_addr = inet_addr(ip);

    n = bind(server_sock_1, (struct sockaddr *)&server_addr1, sizeof(server_addr1));
    if (n < 0)
    {
        perror("Bind error");
        exit(1);
    }
    printf("Bind to the port number: %d\n", port_1);
    srand(time(NULL));

    server_sock_2 = socket(AF_INET, SOCK_DGRAM, 0); // Use SOCK_DGRAM for UDP
    if (server_sock_2 < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }
    printf("[+]UDP server socket created.\n");

    memset(&server_addr2, 0, sizeof(server_addr2));
    server_addr2.sin_family = AF_INET;
    server_addr2.sin_port = htons(port_2); // Convert port to network byte order
    server_addr2.sin_addr.s_addr = inet_addr(ip);

    int m = bind(server_sock_2, (struct sockaddr *)&server_addr2, sizeof(server_addr2));
    if (m < 0)
    {
        perror("Bind error");
        exit(1);
    }
    printf("Bind to the port number: %d\n", port_2);

    srand(time(NULL));

    while (1)
    {
        int next;
        addr_size1 = sizeof(client_addr1);
        addr_size2 = sizeof(client_addr2);
        bzero(buffer, 1024);
        recvfrom(server_sock_1, buffer, sizeof(buffer), 0, (struct sockaddr *)&client_addr1, &addr_size1);
        printf("Client connected.\n");

        int received_integer1;
        memcpy(&received_integer1, buffer, sizeof(received_integer1));
        printf("Received integer: %d\n", received_integer1);

        bzero(buffer2, 1024);
        recvfrom(server_sock_2, buffer2, sizeof(buffer2), 0, (struct sockaddr *)&client_addr2, &addr_size2);
        printf("Client connected.\n");

        int received_integer2;
        memcpy(&received_integer2, buffer2, sizeof(received_integer2));
        printf("Received integer: %d\n", received_integer2);

        char *result = determineGameResult(received_integer1, received_integer2);
        strcpy(buffer, result);
        sendto(server_sock_1, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addr1, addr_size1);
        sendto(server_sock_2, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addr2, addr_size2);
        int next_A, next_B;
        int bytes_received = recvfrom(server_sock_1, &next_A, sizeof(result), 0, (struct sockaddr *)&client_addr1, &addr_size1);
        int bytes_received1 = recvfrom(server_sock_2, &next_B, sizeof(result), 0, (struct sockaddr *)&client_addr2, &addr_size2);
        if (next_A == 1 && next_B == 1)
        {
            next = 1;
            sendto(server_sock_1, &next, sizeof(next), 0, (struct sockaddr *)&client_addr1, addr_size1);
            sendto(server_sock_2, &next, sizeof(next), 0, (struct sockaddr *)&client_addr2, addr_size2);
        }
        else
        {
            next = 0;
            sendto(server_sock_1, &next, sizeof(next), 0, (struct sockaddr *)&client_addr1, addr_size1);
            sendto(server_sock_2, &next, sizeof(next), 0, (struct sockaddr *)&client_addr2, addr_size2);
            break;
        }
        
    }
    close(server_sock_1);
    close(server_sock_2);
    return 0;
}
