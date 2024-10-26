Performance Comparison of Scheduling Policies
We conducted performance tests for two scheduling policies: the default policy and the FCFS (First-Come-First-Served) policy. The tests were performed with processes running on a single CPU. Below are the results:
```
Default Scheduling Policy (Round Robin)
Output:
        init: starting sh
        $ schedulertest
        Process 6 finished
        Process 8 finished
        Process 5 finished
        Process 7 finished
        Process 9 finished
        Process 0 finished
        Process 1 finished
        Process 2 finished
        Process 3 finished
        Process 4 finished
        Average rtime 15,  wtime 162
Average Running Time: 15

Average Waiting Time: 162
```
FCFS (First-Come-First-Served) Scheduling Policy
    ```
    Output:
    	init: starting sh
        $ schedulertest
        Process 5 finished
        Process 6 finished
        Process 7 finished
        Process 8 finished
        Process 9 finished
        Process 0 finished
        Process 1 finished
        Process 2 finished
        Process 3 finished
        Process 4 finished
        Average rtime 15,  wtime 131
	```

Average Running Time: 15

Average Waiting Time: 131
	

Analysis
Average Running Time: In both scheduling policies, the average running time of processes is the same, which is 15 time units. This indicates that the policies do not affect the actual execution time of processes.

Average Waiting Time: The average waiting time under the FCFS policy (131 time units) is significantly lower than that under the default policy (162 time units). This suggests that FCFS provides better responsiveness to processes, as they tend to spend less time waiting for execution.

These results demonstrate the impact of the scheduling policy on the waiting times of processes. FCFS, being a simple policy, can lead to lower waiting times compared to the default policy, which may have other factors affecting waiting times.



### NETWORKS PART B:

#### How is your implementation of data sequencing and retransmission different from traditional TCP? 

- Traditional TCP implementation performs three-way handshake, Reteansmission, Data sequencing, Flow control and Mechanisms for closing connections.

- In my implementation of TCP, It doesn’t perform Three way handshake i.e, initiates communication directly and divides data into chunks of fixed size and and sends each chunk to the reciever. 
- For each chunk sent by the sendor if it doesn’t recieve acknowledgement within 0.1 seconds, it sends the next chunk and  then stores it a queue.
- It keeps sending chunks till queue is empty and ensures that all chunks are sent.

- Reliability::
	My implementation includes some reliability features, such as sequence numbers, acknowledgments, and retransmissions of lost data chunks. However, it does not provide the same level of reliability and robustness as TCP.

- Connection Setup and Teardown:
	My implementation does not include a formal connection setup and teardown process. It relies on a simple send-and-receive loop without establishing a connection. Whereas, TCP has a three-way handshake for connection establishment and a four-way handshake for connection termination. This ensures that both parties agree to the communication before data transfer begins and cleanly terminates the connection when done.
Flow Control and Congestion Control::
	My implementation does not include explicit flow control or congestion control mechanisms. It relies on the underlying network's best-effort delivery. Whereas,TCP includes flow control mechanisms to prevent sender from overwhelming the receiver with data and congestion control mechanisms to adapt to network conditions and prevent congestion.


- Error Handling::
	My implementation handles errors through retransmissions of lost data chunks. It may not handle complex scenarios like out-of-order delivery or duplicate data.Whereas, TCP provides comprehensive error handling, including out-of-order packet reordering, duplicate detection, and error recovery.

2) How can you extend your implementation to account for flow control? You may ignore deadlocks. 
Define Flow Control Parameters:
    -  Define two parameters to represent flow control:
        -  sender_window_size: The maximum number of unacknowledged chunks the sender can have in transit.
        -  receiver_window_size: The maximum number of expected chunks the receiver can receive and process.
    -  Sender's Perspective:
    -  Maintain a sender window that keeps track of sent but unacknowledged chunks.
    -  Initialize next_sequence_number to 0 (or any initial value).
    -  When sending a chunk:
        -  Check if the sender window is full (< sender_window_size).
        -  If the window is not full, send the chunk and increment next_sequence_number.
        -  If the window is full, wait for acknowledgments and slide the window as acknowledgments arrive.
    -  Receiver's Perspective:
    -  Maintain a receiver window that keeps track of expected sequence numbers.
    -  Initialize expected_sequence_number to 0 (or any initial value).
    -  When receiving a chunk:
        - Check if the received chunk's sequence number is within the receiver's window (>= expected_sequence_number and < expected_sequence_number + receiver_window_size).
        -  If the chunk is within the window, process it and increment expected_sequence_number.
        -  Send acknowledgments indicating the expected sequence number.
    -  Sender's Behavior:
    -  The sender should not send chunks beyond its sender window. Ensure that the sequence number of the chunk being sent falls within the sender's window range.
    -  The sender should wait for acknowledgments to slide the sender's window.
    -  Receiver's Behavior:
    -  The receiver should ignore out-of-order chunks.
    -  The receiver should send acknowledgments indicating the next expected sequence number.



