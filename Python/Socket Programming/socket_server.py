import socketserver
import time

class MyTCPHandler(socketserver.BaseRequestHandler):
    """
    The request handler class for our server.

    It is instantiated once per connection to the server, and must
    override the handle() method to implement communication to the
    client.
    """

    def handle(self):
        for i in range(3):
            # self.request is the TCP socket connected to the client
            self.data = self.request.recv(1024).strip()
            print("[*]{0} wrote: {1}".format(self.client_address[0], self.data))

            time.sleep(10) #wait for 10 seconds as like tensorflow computing time
            # just send back the same data, but upper-cased
            self.request.sendall(self.data.upper())
            print("[*]Send: {0}".format(self.data.upper()))

if __name__ == "__main__":
    HOST, PORT = "localhost", 9999

    # Create the server, binding to localhost on port 9999
    server = socketserver.TCPServer((HOST, PORT), MyTCPHandler)

    # Activate the server; this will keep running until you
    # interrupt the program with Ctrl-C
    server.serve_forever()
    server.server_close()