import socket

s = socket.socket()
host = "127.0.0.1"
port = 12345
s.connect((host, port))
s.sendall(b"This is a test...")
s.sendall(b"4510")

s.close()