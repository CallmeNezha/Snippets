import socket
import time

Code = {
    b"4509": "transfer_done_continue",
    b"4510": "transfer_done_switch",
}

class EnvServer:
    def __init__(self, host=None, port=None):
        self.host = "127.0.0.1" if host is None else host
        self.port = 12345 if port is None else port
        self.state = "closed"
    
    def __enter__(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        print("[*] Listening on: {0}: {1}".format(self.host, self.port))
        self.sock.bind((self.host, self.port))
        self.sock.listen(1) # Only accept one connection
        print("[*] Waiting for connection...")
        self.conn, addr = self.sock.accept()
        print('[*] Got connection from', str(addr))
        self.state = "connected"
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.sock.close()
        print("[*] Connection closed.")

    def recv_data(self):
        if self.state != "connected": return None
        while True:
            data, code = self._recv_data(self.conn)
            if b'2' == code:
                break
            if b'1' == code:
                break
            if b"4509" == code:
                return data.decode('ascii')
            if b"4510" == code:
                return data.decode('ascii')

        print("[*] Ready to close connection.")
        self.conn.close()
        self.state = "closed"
        return None

    def send_data(self, data_string):
        if self.state != "connected": return
        self.conn.sendall(data_string.encode('ascii'))
        

    def _recv_data(self, conn):
        data = []
        code = b'0'
        while True:
            try:
                data_chunk = conn.recv(1024)
            except socket.error as error:
                print("[!!!] Socket error", str(error))
                code = b'1'
                break
            if not data_chunk:
                code = b'2'
                break
            if data_chunk in Code:
                code = data_chunk
                break
            data.append(data_chunk)
        return b''.join(data), code


if "__main__" == __name__:
    with EnvServer() as env_server:
        while True:
            # data = env_server.recv_data()
            # if data is not None:
            #     print(data.decode('ascii'))
            env_server.send_data("COMMAND=RESET")
            print("[*] Send msg:", "COMMAND=RESET")
            time.sleep(2)
            data = env_server.recv_data()
            print("[*] Recv msg:", data)
            time.sleep(2)
            env_server.send_data("COMMAND=STEP ACTION=[1.0,23.0,2.0]")
            print("[*] Send msg:", "COMMAND=STEP ACTION=[1.0,23.0,2.0]")
            time.sleep(2)
            print("[*] Recv msg:", data)
            time.sleep(2)
            
    print("[*] Program done.")