#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
int no_of_customers = 0;
int no_of_baristas = 0;
int no_of_coffees = 0;
sem_t curr_sem;
pthread_mutex_t mutex;

int dis_stu = 0;
int w_time = 0;
int wasted_coffee = 0;
time_t start_time;
double total_waiting_time = 0.0;

typedef struct cust ct;
struct cust
{
    int arrival_time;
    int order_time;
    char order[100];
    int patience_time;
    int index;
    int wait;
    int wash;
    int barista_id;
    int left;
    int assigned_time;
};

typedef struct coffees cf;
struct coffees
{
    int prep_time;
    char name[100];
};

typedef struct barista b;
struct barista
{
    int id;
    int free;
};
b baristas[100];
typedef struct Node
{
    ct customer;
    struct Node *next;
} Node;

// Structure for the queue
typedef struct
{
    Node *front;
    Node *rear;
} Queue;
Queue *customerQueue;
ct customers[100];
cf coffees[50];

// Function to initialize an empty queue
Queue *initializeQueue()
{
    Queue *queue = (Queue *)malloc(sizeof(Queue));
    if (queue == NULL)
    {
        fprintf(stderr, "Error: Unable to allocate memory for the queue\n");
        exit(EXIT_FAILURE);
    }
    queue->front = NULL;
    queue->rear = NULL;
    return queue;
}

// Function to check if the queue is empty
int isEmpty(Queue *queue)
{
    return (queue->front == NULL);
}

// Function to enqueue a customer
void enqueue(Queue *queue, ct customer)
{
    Node *newNode = (Node *)malloc(sizeof(Node));
    if (newNode == NULL)
    {
        fprintf(stderr, "Error: Unable to allocate memory for the new node\n");
        exit(EXIT_FAILURE);
    }
    newNode->customer = customer;
    newNode->next = NULL;

    if (isEmpty(queue))
    {
        queue->front = newNode;
        queue->rear = newNode;
    }
    else
    {
        queue->rear->next = newNode;
        queue->rear = newNode;
    }
}

// Function to dequeue a customer
ct dequeue(Queue *queue)
{
    if (isEmpty(queue))
    {
        fprintf(stderr, "Error: Queue is empty\n");
        exit(EXIT_FAILURE);
    }

    Node *frontNode = queue->front;
    ct customer = frontNode->customer;

    queue->front = frontNode->next;

    // If the last element is dequeued, update the rear pointer
    if (queue->front == NULL)
    {
        queue->rear = NULL;
    }

    free(frontNode);
    return customer;
}

// Function to free the memory used by the queue
void freeQueue(Queue *queue)
{
    while (!isEmpty(queue))
    {
        dequeue(queue);
    }
    free(queue);
}
int compare(const void *a, const void *b)
{
    ct *data_1 = (ct *)a;
    ct *data_2 = (ct *)b;
    if (data_1->arrival_time - data_2->arrival_time == 0)
    {
        return (data_1->index - data_2->index);
    }
    else
    {
        return (data_1->arrival_time - data_2->arrival_time);
    }
}
pthread_t p_thread;
int exit_patience_thread = 0;

void barista_handler(ct *s, b bar)
{
    pthread_mutex_lock(&mutex);
    time_t curr_time = time(NULL) - start_time;
    long int x = curr_time - s->arrival_time;
    w_time = w_time + x;
     if (s->barista_id != -1 || (curr_time - s->arrival_time > s->patience_time))
    {
        if(s->barista_id == -1){
            fprintf(stderr, "\033[31mCustomer %d leaves without their order at %ld second(s)\n\033[0m", s->index, curr_time);
            dis_stu++;
            s->left = 1;
            pthread_mutex_unlock(&mutex);
            return;
        }
        fprintf(stderr, "\033[32mBarista %d begins preparing the order of customer %d at %ld second(s)\n\033[0m", s->barista_id, s->index, curr_time);
        pthread_mutex_unlock(&mutex);
        if (curr_time - s->arrival_time + s->order_time - 1 > s->patience_time)
        {
            int x = curr_time;
            sleep(curr_time - s->arrival_time + s->order_time - 2 - s->patience_time);
            curr_time = time(NULL) - start_time;
            fprintf(stderr, "\033[31mCustomer %d leaves without their order at %d second(s)\n\033[0m", s->index, s->arrival_time+s->patience_time+1);
            s->left=1;
            dis_stu++;
            sleep(s->arrival_time + 2 + s->patience_time - x);
            curr_time = time(NULL) - start_time;
            fprintf(stderr, "\033[34mBarista %d completes the order of customer %d at %ld second(s)\n\033[0m", s->barista_id, s->index, curr_time);
        }
        else
        {
            sleep(s->order_time);
            curr_time = time(NULL) - start_time;
            fprintf(stderr, "\033[34mBarista %d completes the order of customer %d at %ld second(s)\n\033[0m", s->barista_id, s->index, curr_time);
            if (!s->left)
                fprintf(stderr, "\033[32mCustomer %d leaves with their order at %ld second(s).\n\033[0m", s->index, curr_time);
        }
        s->left = 1;
        sleep(1);
        sem_post(&curr_sem);
        bar.free = 1;
        // pthread_mutex_lock(&mutex);
    }
    pthread_mutex_unlock(&mutex);
        // sem_post(&curr_sem);

    if (!isEmpty(customerQueue))
    {
        ct currentCustomer = dequeue(customerQueue);
        currentCustomer.barista_id = bar.id;
        barista_handler(&currentCustomer, bar);
    }
    
    return;
}
void *thread(void *arg)
{
    ct *s = (ct *)(arg);
    time_t curr_time = time(NULL) - start_time;
    fprintf(stderr, "\033[37mCustomer %d arrives at %ld second(s).\n\033[0m", s->index, curr_time);
    fprintf(stderr, "\033[33mCustomer %d orders a %s\n\033[0m", s->index, s->order);
    sleep(1);
    int i;
    // int flag = 0;
    pthread_mutex_lock(&mutex); 
    for (i = 0; i < no_of_baristas; i++)
    {
        // printf("entered loop %d times\n",count+1);
        if (baristas[i].free == 1)
        {
            sem_wait(&curr_sem);
            s->barista_id = i + 1;
            baristas[i].free = 0;
            // flag = 1;
            ct currentCustomer = dequeue(customerQueue);
            s->assigned_time = time(NULL) - start_time;
            break;
        }
        else if(no_of_baristas==1){
            s->wait = 1;
            // i = 0;
            pthread_exit(NULL);
        }
        else
        {
            // printf("no available barista\n");
            s->wait = 1;
            i = 0;
        }
    }
    pthread_mutex_unlock(&mutex); // Unlock after modifying shared data

    s->wash = 1;
    barista_handler(s, baristas[i]);
    if (s->left)
    {
        total_waiting_time += s->wait;
    }
    // for (int i = 0; i < no_of_customers; i++)
    // {
    //     if (customers[i].left==0)
    //     {
    //         break;
    //     }
    //     else
    //         exit(0);
    // }
    
    // exit(0);
    // pthread_exit(NULL);
    // return;
}
int main()
{
    scanf("%d%d%d", &no_of_baristas, &no_of_coffees, &no_of_customers);

    total_waiting_time = 0.0;
    for (int i = 0; i < no_of_coffees; i++)
    {
        scanf("%s%d", coffees[i].name, &coffees[i].prep_time);
    }
    for (int i = 0; i < no_of_customers; i++)
    {
        scanf("%d%s%d%d", &customers[i].index, customers[i].order, &customers[i].arrival_time, &customers[i].patience_time);
        for (int j = 0; j < no_of_coffees; j++)
        {
            if (strcmp(customers[i].order, coffees[j].name) == 0)
            {
                customers[i].order_time = coffees[j].prep_time;
                break;
            }
        }
        customers[i].wait = 0;
        customers[i].wash = 0;
        customers[i].barista_id = -1;
        customers[i].left = 0;
    }
    for (int i = 0; i < no_of_baristas; i++)
    {
        baristas[i].id = i + 1;
        baristas[i].free = 1;
    }
    customerQueue = initializeQueue();
    sem_init(&curr_sem, 0, no_of_baristas);
    pthread_mutex_init(&mutex, NULL);
    pthread_t cthread[no_of_customers];
    qsort(customers, no_of_customers, sizeof(ct), compare);
    start_time = time(NULL);
    time_t curr_time = time(NULL);
    for (int i = 0; i < no_of_customers; i++)
    {
        curr_time = time(NULL) - start_time;
        long int sleep_time = customers[i].arrival_time - curr_time;
        sleep(sleep_time);
        enqueue(customerQueue, customers[i]);
        pthread_create(&cthread[i], NULL, thread, (void *)(&customers[i]));
    }

    for (int i = 0; i < no_of_baristas; i++)
    {
        pthread_join(cthread[i], NULL);
    }
    sem_destroy(&curr_sem);
    pthread_mutex_destroy(&mutex);
    printf("coffees wasted:%d\n", dis_stu);
    float avg_wait_time=(float)w_time/no_of_customers;
    printf("Average Waiting Time: %.2f seconds\n", avg_wait_time);
    return 0;
}
