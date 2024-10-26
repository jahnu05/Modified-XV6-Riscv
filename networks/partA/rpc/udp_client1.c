#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int next, result;
    int sock;

    char *ip = "127.0.0.1";
    int port = 5020;
    struct sockaddr_in addr;
    socklen_t addr_size;
    char buffer[1024];
    int n;

    sock = socket(AF_INET, SOCK_DGRAM, 0); // Use SOCK_DGRAM for UDP
    if (sock < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port); // Convert port to network byte order
    addr.sin_addr.s_addr = inet_addr(ip);

    int choice;
    while (1)
    {

        printf("Enter your choice (0 for Rock, 1 for Paper, 2 for Scissors): ");
        scanf("%d", &choice);

        sendto(sock, &choice, sizeof(choice), 0, (struct sockaddr *)&addr, sizeof(addr));
        bzero(buffer, 1024);
        recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr *)&addr, &addr_size);
        printf("%s\n", buffer);

        printf("Do you want to play again? (1 for Yes, 0 for No): ");
        scanf("%d", &next);
        sendto(sock, &next, sizeof(next), 0, (struct sockaddr *)&addr, sizeof(addr));
        int bytes_received = recvfrom(sock, &result, sizeof(result), 0, (struct sockaddr *)&addr, &addr_size);
        if (result != 1)
        {
            break;
        }
    }
    close(sock);

    return 0;
}
