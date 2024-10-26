#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int next;
    int sock;
    int result;
    while (result)
    {
        char *ip = "127.0.0.1";
        int port = 5000;
        struct sockaddr_in addr;
        socklen_t addr_size;
        char buffer[1024];
        int n;

        sock = socket(AF_INET, SOCK_STREAM, 0);
        if (sock < 0)
        {
            perror("[-]Socket error");
            exit(1);
        }

        memset(&addr, '\0', sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        addr.sin_addr.s_addr = inet_addr(ip);

        int choice;

        connect(sock, (struct sockaddr *)&addr, sizeof(addr));

        printf("Enter your choice (0 for Rock, 1 for Paper, 2 for Scissors): ");
        scanf("%d", &choice);

        int bytes_sent = send(sock, &choice, sizeof(choice), 0);
        bzero(buffer, 1024);
        recv(sock, buffer, sizeof(buffer), 0);
        printf("%s\n", buffer);

        printf("Do you want to play again? (1 for Yes, 0 for No): ");
        scanf("%d", &next);
        int bytes = send(sock, &next, sizeof(next), 0);
        if (next == 0)
        {
            close(sock);
            break;
        }
        int bytes_received = recv(sock, &result, sizeof(int), 0);
    }

    return 0;
}
