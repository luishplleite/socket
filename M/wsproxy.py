#!/usr/bin/env python
# encoding: utf-8
# CRAZY By @Crazy_vpn
#!/usr/bin/env python
# encoding: utf-8

import socket
import threading
import select
import sys

MSG = 'WebSocket'
COR = '<font color="null">'
FTAG = '</font>'
PASS = ''
LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = 80
BUFLEN = 8196 * 8
TIMEOUT = 60
DEFAULT_HOST = "127.0.0.1:22"
RESPONSE = f'HTTP/1.1 101 {COR}{MSG}{FTAG}\r\n\r\n'


class ProxyServer:
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.connections = []

    def start(self):
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(5)

        print(f"Proxy server listening on {self.host}:{self.port}")

        try:
            while True:
                client_socket, client_address = self.server_socket.accept()
                connection_handler = ConnectionHandler(client_socket, client_address)
                self.connections.append(connection_handler)
                connection_handler.start()

        except KeyboardInterrupt:
            self.close()

    def close(self):
        print("Closing proxy server")
        for connection in self.connections:
            connection.close()
        self.server_socket.close()


class ConnectionHandler(threading.Thread):
    def __init__(self, client_socket, client_address):
        super().__init__()
        self.client_socket = client_socket
        self.client_address = client_address
        self.target_socket = None

    def run(self):
        try:
            self.handle_request()
        except Exception as e:
            print(f"Error in connection from {self.client_address}: {e}")
        finally:
            self.close()

    def handle_request(self):
        request_data = self.client_socket.recv(BUFLEN)
        host_port = self.find_header(request_data, 'X-Real-Host')

        if not host_port:
            self.client_socket.send(b'HTTP/1.1 400 NoXRealHost!\r\n\r\n')
            return

        self.connect_target(host_port)
        self.client_socket.sendall(RESPONSE)

        self.forward_data()

    def find_header(self, data, header):
        header_line = data[data.find(header.encode()):]
        header_value = header_line.split(b'\r\n', 1)[0].split(b':', 1)[1].strip()
        return header_value.decode()

    def connect_target(self, host_port):
        self.target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        target_host, target_port = host_port.split(':')
        self.target_socket.connect((target_host, int(target_port)))

    def forward_data(self):
        sockets = [self.client_socket, self.target_socket]

        while True:
            readable, _, _ = select.select(sockets, [], [])

            for sock in readable:
                data = sock.recv(BUFLEN)
                if sock is self.client_socket:
                    self.target_socket.sendall(data)
                else:
                    self.client_socket.sendall(data)

    def close(self):
        if self.client_socket:
            self.client_socket.close()
        if self.target_socket:
            self.target_socket.close()


def main():
    proxy_server = ProxyServer(LISTENING_ADDR, LISTENING_PORT)
    try:
        proxy_server.start()
    except KeyboardInterrupt:
        proxy_server.close()


if __name__ == '__main__':
    main()
