import sys

version = sys.version_info[:2]

PORT = 8000

if version <= (2, 7):
    import SimpleHTTPServer
    import SocketServer
    Handler = SimpleHTTPServer.SimpleHTTPRequestHandler
    httpd = SocketServer.TCPServer(("127.0.0.1", PORT), Handler)
    print("serving at %s port %d" % httpd.server_address[:2])
    httpd.serve_forever()
else:
    import http.server
    import socketserver
    Handler = http.server.SimpleHTTPRequestHandler
    with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
        print("serving at %s port %d" % httpd.server_address[:2])
        httpd.serve_forever()