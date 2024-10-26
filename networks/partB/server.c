#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/time.h>


#define MAX_CHUNK_SIZE 4
#define MAX_CHUNKS 10
#define PORT 12345
#define MAX_INPUT_SIZE 2560000
typedef struct
{
    int sequence_number;
    char data[MAX_CHUNK_SIZE];
} Chunk;

typedef struct
{
    int ack_number;
} Ack;

// Function to set a timer for retransmissions
void set_timer(struct timeval *timer, int timeout_ms)
{
    gettimeofday(timer, NULL);
    timer->tv_usec += timeout_ms * 1000;
    if (timer->tv_usec >= 1000000)
    {
        timer->tv_sec += timer->tv_usec / 1000000;
        timer->tv_usec %= 1000000;
    }
}

// Function to check if a timer has expired
int is_timer_expired(struct timeval *timer)
{
    struct timeval current_time;
    gettimeofday(&current_time, NULL);
    return (current_time.tv_sec > timer->tv_sec ||
            (current_time.tv_sec == timer->tv_sec && current_time.tv_usec >= timer->tv_usec));
}

int main()
{
    int sockfd;
    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_len = sizeof(client_addr);

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd == -1)
    {
        perror("Error in socket creation");
        exit(1);
    }

    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Error in binding");
        exit(1);
    }

    Chunk received_chunks[MAX_CHUNKS];
    Ack ack;
    int total_chunks;
    int received_count = 0;

    printf("Server is listening...\n");

    if (recvfrom(sockfd, &total_chunks, sizeof(total_chunks), 0, (struct sockaddr *)&client_addr, &addr_len) == -1)
    {
        perror("Error in receiving total_chunks");
        exit(1);
    }

    printf("Total chunks to receive: %d\n", total_chunks);

    while (received_count < total_chunks)
    {
        Chunk chunk;
        int recv_size = recvfrom(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&client_addr, &addr_len);
        if (recv_size == -1)
        {
            perror("Error in receiving chunk");
            exit(1);
        }

        received_chunks[chunk.sequence_number] = chunk;
        // printf("%s\n",chunk.data);
        strcpy(received_chunks[chunk.sequence_number].data, chunk.data);
        received_count++;

        // Send an acknowledgment for the received chunk
        ack.ack_number = chunk.sequence_number;
        sendto(sockfd, &ack, sizeof(ack), 0, (struct sockaddr *)&client_addr, addr_len);
    }

    printf("Received and sequenced data:\n");
    // printf("%d\n",total_chunks);

    for (int i = 0; i < total_chunks; i++)
    {
        printf("%s", received_chunks[i].data);
    }
    printf("--------------------------------------------------------------------------------------------\n");
    Chunk chunks[MAX_CHUNKS];
     char data[MAX_INPUT_SIZE];
    printf("Enter the text to send (or type 'exit' to quit): ");
    fgets(data, MAX_INPUT_SIZE, stdin);

    total_chunks = strlen(data) / MAX_CHUNK_SIZE + 1;

    // Send the total number of chunks
    for (int i = 0; i < total_chunks; i++)
    {
        chunks[i].sequence_number = i;
        strncpy(chunks[i].data, data + i * MAX_CHUNK_SIZE, MAX_CHUNK_SIZE);
        chunks[i].data[MAX_CHUNK_SIZE] = '\0';
    }
    printf("Sending %d chunks to server...\n", total_chunks);
    if (sendto(sockfd, &total_chunks, sizeof(total_chunks), 0, (struct sockaddr *)&client_addr, addr_len) == -1)
    {
        perror("Error in sending total_chunks");
        exit(1);
    }

    // Initialize timer for retransmissions
    struct timeval timer;
    set_timer(&timer, 100); // Set the initial timeout to 100 ms

    // Divide the text into fixed-size chunks and send them with sequence numbers
    for (int i = 0; i < total_chunks; i++)
    {
        chunks[i].sequence_number = i;
        if (sendto(sockfd, &chunks[i], sizeof(chunks[i]), 0, (struct sockaddr *)&client_addr, addr_len) == -1)
        {
            perror("Error in sending chunk");
            exit(1);
        }

        // Wait for an acknowledgment or timeout
        while (1)
        {
            // Check if the timer has expired
            if (is_timer_expired(&timer))
            {
                printf("Timeout for chunk %d. Retransmitting...\n", i);
                if (sendto(sockfd, &chunks[i], sizeof(chunks[i]), 0, (struct sockaddr *)&client_addr, addr_len) == -1)
                {
                    perror("Error in retransmitting chunk");
                    exit(1);
                }
                // Reset the timer for retransmission
                set_timer(&timer, 100); // Reset the timeout to 100 ms
            }

            // Receive an acknowledgment
            int recv_size = recvfrom(sockfd, &ack, sizeof(ack), 0, (struct sockaddr *)&client_addr, &addr_len);
            if (recv_size > 0 && ack.ack_number == i)
            {
                printf("Received acknowledgment for chunk %d\n", i);
                break;
            }
        }
    }

    printf("Data sent successfully!\n");

    close(sockfd);
    return 0;
    //resource:https://chat.openai.com/c/bc5e14b0-71ad-4c08-86e6-e84070250dbf
}
