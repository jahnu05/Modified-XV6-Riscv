import matplotlib.pyplot as plt

with open('output.txt', 'r') as file:
    lines = file.readlines()

x = []
y = []

for line in lines:
    coords = line.split()
    # print(coords)
    coords[0] = int(coords[0])
    coords[1] = int(coords[1])
    if coords[0] >= 5:
        x.append(coords[1])
        y.append(coords[0])
y_values = [0,1,2,3,4,5,6,7,8,9]
for i in range(0,len(y)):
    y[i] -= 5
    y[i] %= 10
plt.yticks(y_values)
plt.scatter(x, y)
plt.xlabel('Ticks')
plt.ylabel('Process ID')
plt.title('Process ID vs Ticks')
plt.savefig('graph.jpeg')