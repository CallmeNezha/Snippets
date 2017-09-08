using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Net.Sockets;

namespace CSharpTCP
{

    class Program
    {
        static NetworkStream stream = null;
        static TcpClient client = null;

        static void Send(string message)
        {
            try
            {
                byte[] data = Encoding.ASCII.GetBytes(message);
                stream.Write(data, 0, data.Length);
                Console.WriteLine("[*]Sent: {0}", message);
            }
            catch (ArgumentNullException e)
            {
                Console.WriteLine("[!]ArgumentNullException: {0}", e);
            }
            catch (SocketException e)
            {
                Console.WriteLine("[!]SocketException: {0}", e);
            }
        }

        static string Recv()
        {
            string responseData = string.Empty;
            try
            { 
                byte[] data = new Byte[1024];
                int bytes = stream.Read(data, 0, data.Length);
                responseData = Encoding.ASCII.GetString(data, 0, bytes);
                return responseData;
            }
            catch (ArgumentNullException e)
            {
                Console.WriteLine("[!]ArgumentNullException: {0}", e);
            }
            catch (SocketException e)
            {
                Console.WriteLine("[!]SocketException: {0}", e);
            }
            return responseData;
        }

        static void Shutdown()
        {
            try
            {
                // Close everything.
                stream.Close();
                client.Close();
            }
            catch (ArgumentNullException e)
            {
                Console.WriteLine("[!]ArgumentNullException: {0}", e);
            }
            catch (SocketException e)
            {
                Console.WriteLine("[!]SocketException: {0}", e);
            }

        }
        static void Connect(string server, int port)
        {
            try
            {
                client = new TcpClient(server, port);
                stream = client.GetStream();
            }
            catch (ArgumentNullException e)
            {
                Console.WriteLine("[!]ArgumentNullException: {0}", e);
            }
            catch (SocketException e)
            {
                Console.WriteLine("[!]SocketException: {0}", e);
            }

            
        }
        //static void Main(string[] args)
        //{
        //    Connect("localhost", 9999);
        //    // Ping Pong
        //    for (int i = 0; i < 3; ++i)
        //    {
        //        Send(string.Format("hi zjj x{0}", i));
        //        Console.WriteLine("[*]Receive from server: {0}", Recv());
        //        Thread.Sleep(1000);
        //    }

        //    Shutdown();
        //    Console.WriteLine("\n Press Enter to continue...");
        //    Console.Read();
        //}
    }
}
