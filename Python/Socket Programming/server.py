import socket_server

if "__main__" == __name__:
    with socket_server.EnvServer() as env_server:
        data = env_server.recv_data()
        if data is not None:
            print(data.decode('ascii'))
    print("[*] Program done.")
