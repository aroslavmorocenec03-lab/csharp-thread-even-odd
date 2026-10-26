using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;

Console.OutputEncoding = Encoding.UTF8;

int[] fullArray = new int[1000];
Random random = new Random();
for (int i = 0; i < fullArray.Length; i++)
    fullArray[i] = random.Next(1, 11); // Від 1 до 10 включно.

List<int> evenList = new List<int>();
List<int> oddList = new List<int>();

int nextIndex = 0;
object arrayLock = new object();
object evenLock = new object();
object oddLock = new object();

Console.WriteLine("Основний масив: " + string.Join(", ", fullArray));

// Усі три потоки виконують одну й ту саму функцію.
void DistributeNumbers()
{
    while (true)
    {
        int number;
        lock (arrayLock)
        {
            if (nextIndex >= fullArray.Length)
                return;

            // Читання елемента та зміна спільного індексу — одна атомарна дія.
            number = fullArray[nextIndex];
            nextIndex++;
        }

        if (number % 2 == 0)
        {
            lock (evenLock)
                evenList.Add(number);
        }
        else
        {
            lock (oddLock)
                oddList.Add(number);
        }
    }
}

Thread[] threads = new Thread[3];
for (int i = 0; i < threads.Length; i++)
    threads[i] = new Thread(DistributeNumbers);

foreach (Thread thread in threads)
    thread.Start();

foreach (Thread thread in threads)
    thread.Join();

// Після Join жоден робочий потік уже не змінює списки.
Console.WriteLine($"Парні елементи ({evenList.Count}):");
Console.WriteLine(string.Join(", ", evenList));
Console.WriteLine($"Непарні елементи ({oddList.Count}):");
Console.WriteLine(string.Join(", ", oddList));
Console.WriteLine($"Усього розподілено: {evenList.Count + oddList.Count}.");
